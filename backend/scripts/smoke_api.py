import uuid

import httpx


def main():
    with httpx.Client(base_url="http://127.0.0.1:8765", timeout=30) as client:
        email = f"p7-{uuid.uuid4().hex}@example.com"
        response = client.post(
            "/api/auth/register", json={"Email": email, "Password": uuid.uuid4().hex}
        )
        response.raise_for_status()
        client.headers["Authorization"] = "Bearer " + response.json()["AccessToken"]
        response = client.post(
            "/api/projects", json={"Name": "Demo P6/P7", "Description": "Verifikasi API lokal"}
        )
        response.raise_for_status()
        project = response.json()
        response = client.post(
            f"/api/projects/{project['Id']}/assets",
            json={"RepositoryUrl": "https://github.com/expressjs/express"},
        )
        response.raise_for_status()
        asset = response.json()
        response = client.get(f"/api/projects/{project['Id']}/assets")
        response.raise_for_status()
        assert any(item["Id"] == asset["Id"] for item in response.json())
        response = client.get(f"/api/projects/{project['Id']}/dashboard")
        response.raise_for_status()
        assert response.json()["TotalAssets"] == 1
        from app.db.session import SessionLocal
        from app.models.asset import Asset

        with SessionLocal() as db:
            assert db.get(Asset, asset["Id"]) is not None
        print(
            "PASS: register -> POST project -> POST asset -> GET asset "
            "-> dashboard -> database session baru"
        )
        print("Database demo tersimpan; tidak ada token atau kata sandi yang dicetak.")


if __name__ == "__main__":
    main()
