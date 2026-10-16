import pytest

from app.models.project import Project
from app.models.user import User


@pytest.fixture()
def project(db_session, demo_user):
    project = Project(
        user_id=demo_user.id, name="Platform Pembayaran", description="Layanan backend utama."
    )
    db_session.add(project)
    db_session.commit()
    db_session.refresh(project)
    return project


def test_list_assets_empty(client, project):
    resp = client.get(f"/api/projects/{project.id}/assets")
    assert resp.status_code == 200
    assert resp.json() == []


def test_create_asset_parses_repository(client, project):
    resp = client.post(
        f"/api/projects/{project.id}/assets",
        json={"RepositoryUrl": "https://github.com/expressjs/express.git/"},
    )
    assert resp.status_code == 201
    body = resp.json()
    assert body["ProjectId"] == project.id
    assert body["RepositoryUrl"] == "https://github.com/expressjs/express"
    assert body["Owner"] == "expressjs"
    assert body["RepositoryName"] == "express"
    assert body["Name"] == "express"
    assert body["IsActive"] is True
    assert body["LastScannedAt"] is None
    assert set(body) == {
        "Id",
        "ProjectId",
        "Name",
        "RepositoryUrl",
        "Owner",
        "RepositoryName",
        "IsActive",
        "LastScannedAt",
        "CreatedAt",
    }


def test_create_asset_appears_in_list(client, project):
    client.post(
        f"/api/projects/{project.id}/assets",
        json={"RepositoryUrl": "https://github.com/expressjs/express"},
    )
    resp = client.get(f"/api/projects/{project.id}/assets")
    assert resp.status_code == 200
    body = resp.json()
    assert len(body) == 1
    assert body[0]["Owner"] == "expressjs"


def test_duplicate_asset_returns_409(client, project):
    url = f"/api/projects/{project.id}/assets"
    assert (
        client.post(url, json={"RepositoryUrl": "https://github.com/expressjs/express"}).status_code
        == 201
    )
    resp = client.post(url, json={"RepositoryUrl": "https://github.com/expressjs/express.git"})
    assert resp.status_code == 409
    assert resp.json() == {"Message": "URL repositori ini sudah ada di project ini."}


def test_duplicate_asset_is_case_insensitive(client, project):
    url = f"/api/projects/{project.id}/assets"
    assert (
        client.post(url, json={"RepositoryUrl": "https://github.com/ExpressJS/Express"}).status_code
        == 201
    )
    resp = client.post(url, json={"RepositoryUrl": "https://github.com/expressjs/express"})
    assert resp.status_code == 409


def test_create_asset_invalid_url(client, project):
    resp = client.post(
        f"/api/projects/{project.id}/assets",
        json={"RepositoryUrl": "https://evilgithub.com/a/b"},
    )
    assert resp.status_code == 400
    assert resp.json() == {"Message": "Hanya URL github.com atau gitlab.com yang didukung."}


def test_create_asset_empty_url(client, project):
    resp = client.post(f"/api/projects/{project.id}/assets", json={"RepositoryUrl": ""})
    assert resp.status_code == 400
    assert resp.json() == {"Message": "URL repositori wajib diisi."}


def test_create_asset_missing_field(client, project):
    resp = client.post(f"/api/projects/{project.id}/assets", json={})
    assert resp.status_code == 422
    assert "Message" in resp.json()


def test_assets_unknown_project(client, demo_user):
    resp = client.get("/api/projects/tidak-ada/assets")
    assert resp.status_code == 404
    assert resp.json() == {"Message": "Proyek tidak ditemukan."}


def test_assets_other_user_project_returns_404(client, db_session, demo_user):
    other = User(email="other@example.com", password_hash="x")
    db_session.add(other)
    db_session.commit()
    db_session.refresh(other)
    project = Project(user_id=other.id, name="Rahasia", description=None)
    db_session.add(project)
    db_session.commit()
    db_session.refresh(project)

    resp = client.get(f"/api/projects/{project.id}/assets")
    assert resp.status_code == 404
