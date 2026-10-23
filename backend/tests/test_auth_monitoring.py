from fastapi.testclient import TestClient
from sqlalchemy import select

from app.api.deps import get_mail_client, get_manifest_fetcher, get_osv_client
from app.db.session import get_db
from app.main import app
from app.models.user import User
from app.services.monitoring_rules import calculate_drift
from tests.support import FakeManifestFetcher, FakeOsvClient


def test_drift_first_scan_and_unchanged():
    assert calculate_drift(None, {"npm/a": "1"}) == []
    assert calculate_drift({"npm/a": "1"}, {"npm/a": "1"}) == []


def test_drift_added_removed_changed():
    result = calculate_drift({"a": "1", "b": "1"}, {"a": "2", "c": "1"})
    assert [event["type"] for event in result] == ["changed", "removed", "added"]


def test_authenticated_vertical_slice_and_notification_failure(db_session):
    app.dependency_overrides[get_db] = lambda: db_session
    fetcher = FakeManifestFetcher({"requirements.txt": "requests==2.31.0"})
    app.dependency_overrides[get_manifest_fetcher] = lambda: fetcher
    app.dependency_overrides[get_osv_client] = lambda: FakeOsvClient()

    class FailingMail:
        def send(self, recipient, message):
            raise OSError("offline")

    app.dependency_overrides[get_mail_client] = lambda: FailingMail()
    try:
        with TestClient(app) as client:
            assert client.get("/api/projects").status_code == 401
            credentials = {"Email": "tester@example.com", "Password": "test12345"}
            registered = client.post("/api/auth/register", json=credentials)
            assert registered.status_code == 201
            assert client.post("/api/auth/register", json=credentials).status_code == 409
            user = db_session.scalar(select(User).where(User.email == credentials["Email"]))
            assert user.password_hash != credentials["Password"]
            assert (
                client.post(
                    "/api/auth/login", json={**credentials, "Password": "wrong123"}
                ).status_code
                == 401
            )
            session = client.post("/api/auth/login", json=credentials).json()
            client.headers["Authorization"] = "Bearer " + session["AccessToken"]
            project = client.post("/api/projects", json={"Name": "P6"}).json()
            asset = client.post(
                f"/api/projects/{project['Id']}/assets",
                json={"RepositoryUrl": "https://github.com/pulse/api"},
            ).json()
            assert client.post(f"/api/assets/{asset['Id']}/scan").status_code == 200
            assert client.get(f"/api/assets/{asset['Id']}/drift-events").json() == []
            fetcher.manifests = {"requirements.txt": "requests==2.32.0"}
            assert client.post(f"/api/assets/{asset['Id']}/scan").status_code == 200
            assert len(client.get(f"/api/assets/{asset['Id']}/scan-results").json()) == 2
            assert (
                client.get(f"/api/assets/{asset['Id']}/drift-events").json()[0]["Type"] == "changed"
            )
            dashboard = client.get(f"/api/projects/{project['Id']}/dashboard").json()
            assert dashboard["AssetsWithDrift"] == 1
            assert dashboard["Assets"][0]["RiskStatus"] == "WARNING"
            assert (
                client.put(f"/api/projects/{project['Id']}", json={"Name": "P7"}).json()["Name"]
                == "P7"
            )
            assert client.delete(f"/api/projects/{project['Id']}").status_code == 409
            assert (
                client.put(
                    f"/api/assets/{asset['Id']}",
                    json={
                        "Name": "API",
                        "RepositoryUrl": "https://github.com/pulse/different",
                        "IsActive": True,
                    },
                ).status_code
                == 409
            )
            assert client.delete(f"/api/assets/{asset['Id']}").status_code == 204
            assert len(client.get(f"/api/assets/{asset['Id']}/scan-results").json()) == 2
            assert client.post(f"/api/assets/{asset['Id']}/scan").status_code == 409
            assert (
                client.get(f"/api/projects/{project['Id']}/alerts").json()[0]["DeliveryStatus"]
                == "FAILED"
            )
            other = client.post(
                "/api/auth/register", json={"Email": "other@example.com", "Password": "test12345"}
            ).json()
            client.headers["Authorization"] = "Bearer " + other["AccessToken"]
            assert client.get(f"/api/projects/{project['Id']}/assets").status_code == 404
            client.headers["Authorization"] = "Bearer invalid"
            assert client.get("/api/projects").status_code == 401
    finally:
        app.dependency_overrides.clear()
