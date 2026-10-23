from app.models.project import Project
from app.models.user import User


def test_health(client):
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}


def test_list_projects_without_session_returns_401(client):
    resp = client.get("/api/projects")
    assert resp.status_code == 401
    assert resp.json() == {"Message": "Masuk untuk melanjutkan."}


def test_list_projects_scoped_to_user(client, db_session, demo_user):
    db_session.add(Project(user_id=demo_user.id, name="Milik Demo", description=""))
    other = User(email="other@example.com", password_hash="x")
    db_session.add(other)
    db_session.commit()
    db_session.refresh(other)
    db_session.add(Project(user_id=other.id, name="Milik Orang Lain", description=""))
    db_session.commit()

    resp = client.get("/api/projects")
    assert resp.status_code == 200
    body = resp.json()
    assert [project["Name"] for project in body] == ["Milik Demo"]
    assert set(body[0]) == {"Id", "UserId", "Name", "Description", "CreatedAt"}


def test_create_project(client, demo_user):
    resp = client.post("/api/projects", json={"Name": "Proyek Baru", "Description": "Deskripsi"})
    assert resp.status_code == 201
    body = resp.json()
    assert body["Name"] == "Proyek Baru"
    assert body["Description"] == "Deskripsi"
    assert body["UserId"] == demo_user.id
    assert body["Id"]
    assert body["CreatedAt"]


def test_create_project_empty_name(client, demo_user):
    resp = client.post("/api/projects", json={"Name": "   "})
    assert resp.status_code == 422
    assert resp.json() == {"Message": "Nama proyek wajib diisi."}
