from fastapi.testclient import TestClient

from app.db.session import get_db
from app.main import app


def test_cors_preflight_allows_localhost_any_port(client):
    origin = "http://localhost:54321"
    resp = client.options(
        "/api/projects",
        headers={
            "Origin": origin,
            "Access-Control-Request-Method": "GET",
        },
    )
    assert resp.status_code == 200
    assert resp.headers.get("access-control-allow-origin") == origin


def test_cors_preflight_allows_loopback_ip(client):
    origin = "http://127.0.0.1:61234"
    resp = client.options(
        "/api/projects",
        headers={
            "Origin": origin,
            "Access-Control-Request-Method": "GET",
        },
    )
    assert resp.status_code == 200
    assert resp.headers.get("access-control-allow-origin") == origin


def test_cors_preflight_rejects_unknown_origin(client):
    resp = client.options(
        "/api/projects",
        headers={
            "Origin": "http://evil.example.com",
            "Access-Control-Request-Method": "GET",
        },
    )
    assert resp.headers.get("access-control-allow-origin") is None


def test_unhandled_exception_returns_generic_500():
    def boom():
        raise RuntimeError("boom")

    app.dependency_overrides[get_db] = boom
    try:
        with TestClient(app, raise_server_exceptions=False) as test_client:
            resp = test_client.get("/api/projects")
    finally:
        app.dependency_overrides.clear()

    assert resp.status_code == 500
    assert resp.json() == {"Message": "Terjadi kesalahan pada server."}
