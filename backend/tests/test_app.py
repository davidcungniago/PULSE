from fastapi.testclient import TestClient

from app.db.session import get_db
from app.main import app


def test_cors_preflight_allows_flutter_web(client):
    resp = client.options(
        "/api/projects",
        headers={
            "Origin": "http://localhost:4200",
            "Access-Control-Request-Method": "GET",
        },
    )
    assert resp.status_code == 200
    assert resp.headers.get("access-control-allow-origin") == "*"


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
