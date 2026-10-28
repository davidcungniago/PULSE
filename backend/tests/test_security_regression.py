import json
import logging

import httpx
import pytest
from fastapi.testclient import TestClient

from app.core.config import get_settings
from app.db.session import get_db
from app.main import create_app
from app.services.http_client import HttpxClient
from app.services.repository_url import InvalidRepositoryUrl, parse_repository_url


@pytest.fixture
def secured_app(db_session):
    app = create_app()
    app.dependency_overrides[get_db] = lambda: db_session
    return app


@pytest.mark.parametrize(
    "url",
    [
        "https://github.com/../repo",
        "https://github.com/owner/..",
        "https://github.com/./repo",
        "https://github.com/owner/%2e%2e",
        "https://127.0.0.1/a/b",
        "https://169.254.169.254/a/b",
        "https://github.com@localhost/a/b",
        "https://github.com.evil.test/a/b",
    ],
)
def test_url_rejects_traversal_and_unapproved_hosts(url):
    with pytest.raises(InvalidRepositoryUrl):
        parse_repository_url(url)


def test_http_client_does_not_follow_redirects(monkeypatch):
    visited = []

    def respond(request):
        visited.append(str(request.url))
        return httpx.Response(302, headers={"Location": "http://127.0.0.1/private"})

    original_client = httpx.Client
    monkeypatch.setattr(
        httpx,
        "Client",
        lambda **kwargs: original_client(
            transport=httpx.MockTransport(respond),
            **kwargs,
        ),
    )
    client = HttpxClient(timeout=1)
    try:
        assert (
            client.get("https://raw.githubusercontent.com/a/b/HEAD/package.json").status_code == 302
        )
        assert len(visited) == 1
    finally:
        client.close()


def test_cors_only_allows_configured_origin(monkeypatch, db_session):
    monkeypatch.setenv("CORS_ORIGINS", "https://pulse.example.com")
    monkeypatch.setenv("CORS_ORIGIN_REGEX", "")
    get_settings.cache_clear()
    app = create_app()
    app.dependency_overrides[get_db] = lambda: db_session
    with TestClient(app) as client:
        allowed = client.options(
            "/api/projects",
            headers={
                "Origin": "https://pulse.example.com",
                "Access-Control-Request-Method": "GET",
            },
        )
        denied = client.options(
            "/api/projects",
            headers={
                "Origin": "https://evil.example.com",
                "Access-Control-Request-Method": "GET",
            },
        )
    assert allowed.headers["access-control-allow-origin"] == "https://pulse.example.com"
    assert denied.status_code == 400
    assert "access-control-allow-origin" not in denied.headers


def test_safe_log_omits_payload_headers_query_and_exception(secured_app, caplog):
    @secured_app.get("/security-test/{item_id}")
    def fail(item_id: str):
        raise RuntimeError("synthetic-private-exception")

    caplog.set_level(logging.INFO, logger="uvicorn.error")
    with TestClient(secured_app) as client:
        response = client.get(
            "/security-test/private-id?token=synthetic-private-query",
            headers={
                "Authorization": "Bearer synthetic-private-token",
                "X-Request-ID": "untrusted-id",
            },
        )
        invalid = client.post(
            "/api/auth/register",
            json={
                "Email": "synthetic-private-email",
                "Password": "synthetic-private-password",
            },
        )
    assert response.status_code == 500
    assert response.json() == {"Message": "Terjadi kesalahan pada server."}
    assert invalid.status_code == 422
    assert "synthetic-private" not in response.text + invalid.text + caplog.text
    assert "private-id" not in caplog.text
    assert "untrusted-id" not in caplog.text
    records = [json.loads(r.message) for r in caplog.records if r.name == "uvicorn.error"]
    assert records[0]["Route"] == "/security-test/{item_id}"
    assert records[0]["RequestId"] == response.headers["X-Request-ID"]


@pytest.mark.parametrize(
    "method,path,body",
    [
        ("GET", "/api/projects/{project}", None),
        ("PUT", "/api/projects/{project}", {"Name": "Changed"}),
        ("DELETE", "/api/projects/{project}", None),
        ("GET", "/api/projects/{project}/assets", None),
        ("POST", "/api/projects/{project}/assets", {"RepositoryUrl": "https://github.com/a/b"}),
        ("GET", "/api/projects/{project}/dashboard", None),
        ("GET", "/api/projects/{project}/alerts", None),
        (
            "PUT",
            "/api/assets/{asset}",
            {"Name": "Changed", "RepositoryUrl": "https://github.com/a/b"},
        ),
        ("DELETE", "/api/assets/{asset}", None),
        ("POST", "/api/assets/{asset}/scan", None),
        ("GET", "/api/assets/{asset}/scan-results", None),
        ("GET", "/api/assets/{asset}/scan-results/latest", None),
        ("GET", "/api/assets/{asset}/drift-events", None),
    ],
)
def test_every_resource_route_requires_owner(secured_app, method, path, body):
    with TestClient(secured_app) as client:
        owner = client.post(
            "/api/auth/register", json={"Email": "owner@example.com", "Password": "test-password"}
        ).json()
        client.headers["Authorization"] = "Bearer " + owner["AccessToken"]
        project = client.post("/api/projects", json={"Name": "Private"}).json()["Id"]
        asset = client.post(
            f"/api/projects/{project}/assets", json={"RepositoryUrl": "https://github.com/a/b"}
        ).json()["Id"]
        other = client.post(
            "/api/auth/register", json={"Email": "other@example.com", "Password": "test-password"}
        ).json()
        target = path.format(project=project, asset=asset)
        client.headers["Authorization"] = "Bearer " + other["AccessToken"]
        assert client.request(method, target, json=body).status_code == 404
        del client.headers["Authorization"]
        assert client.request(method, target, json=body).status_code == 401


def test_missing_jwt_secret_fails_closed(secured_app, monkeypatch):
    monkeypatch.setenv("JWT_SECRET", "")
    get_settings.cache_clear()
    with TestClient(secured_app) as client:
        response = client.post(
            "/api/auth/register", json={"Email": "test@example.com", "Password": "test-password"}
        )
    assert response.status_code == 503
    assert set(response.json()) == {"Message"}
