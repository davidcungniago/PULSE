import pytest
from sqlalchemy import select

from app.api.deps import get_http_client, get_manifest_fetcher, get_osv_client
from app.main import app
from app.models.asset import Asset
from app.models.component import Component
from app.models.project import Project
from app.models.scan_result import ScanResult
from app.models.user import User
from app.models.vulnerability import Vulnerability
from app.services.http_client import HttpResponse, HttpTransportError
from app.services.scan_errors import RepositoryNotFound
from tests.support import (
    FakeManifestFetcher,
    FakeOsvClient,
    RoutingHttpClient,
    fixture_json,
    fixture_text,
)

LODASH_MANIFEST = '{"dependencies": {"lodash": "^4.17.20"}}'


@pytest.fixture()
def project(db_session, demo_user):
    project = Project(user_id=demo_user.id, name="Platform Pembayaran", description="x")
    db_session.add(project)
    db_session.commit()
    db_session.refresh(project)
    return project


def _make_asset(db_session, project, repository_url, owner, repository_name, name="express"):
    asset = Asset(
        project_id=project.id,
        name=name,
        repository_url=repository_url,
        owner=owner,
        repository_name=repository_name,
        is_active=True,
    )
    db_session.add(asset)
    db_session.commit()
    db_session.refresh(asset)
    return asset


@pytest.fixture()
def asset(db_session, project):
    return _make_asset(
        db_session,
        project,
        "https://github.com/expressjs/express",
        "expressjs",
        "express",
    )


def _override(fetcher=None, osv_client=None, http_client=None):
    if fetcher is not None:
        app.dependency_overrides[get_manifest_fetcher] = lambda: fetcher
    if osv_client is not None:
        app.dependency_overrides[get_osv_client] = lambda: osv_client
    if http_client is not None:
        app.dependency_overrides[get_http_client] = lambda: http_client


def _dedup_fetcher_and_osv():
    fetcher = FakeManifestFetcher(manifests={"package.json": LODASH_MANIFEST})
    osv = FakeOsvClient(
        ids_by_name={"lodash": ["GHSA-35jh-r3h4-6jhm", "GHSA-r5fr-rjxr-66jc"]},
        vulns={
            "GHSA-35jh-r3h4-6jhm": fixture_json("osv_vuln_dedup_a.json"),
            "GHSA-r5fr-rjxr-66jc": fixture_json("osv_vuln_dedup_b.json"),
        },
    )
    return fetcher, osv


def test_scan_creates_result_and_updates_last_scanned(client, db_session, asset):
    fetcher, osv = _dedup_fetcher_and_osv()
    _override(fetcher=fetcher, osv_client=osv)

    resp = client.post(f"/api/assets/{asset.id}/scan")

    assert resp.status_code == 200
    body = resp.json()
    assert set(body) == {
        "AssetId",
        "ComponentCount",
        "CriticalVulnerabilityCount",
        "SkippedEntryCount",
        "StartedAt",
        "FinishedAt",
        "Message",
    }
    assert body["AssetId"] == asset.id
    assert body["ComponentCount"] == 1
    assert body["CriticalVulnerabilityCount"] == 0
    assert body["SkippedEntryCount"] == 0
    assert body["Message"] == "Pemindaian selesai."

    assert db_session.scalar(select(ScanResult).where(ScanResult.asset_id == asset.id))
    component = db_session.scalars(select(Component)).one()
    assert component.name == "lodash"
    assert component.license == "Tidak diketahui"
    assert component.purl == "pkg:npm/lodash@4.17.20"

    vulnerabilities = db_session.scalars(select(Vulnerability)).all()
    assert len(vulnerabilities) == 1
    assert vulnerabilities[0].cve_id == "CVE-2021-23337"
    assert vulnerabilities[0].severity == "HIGH"

    db_session.refresh(asset)
    assert asset.last_scanned_at is not None


def test_scan_skipped_entry_count_counts_unpinned_entries(client, asset):
    fetcher = FakeManifestFetcher(
        manifests={
            "requirements.txt": "numpy==1.2.3\nrequests>=2.0\nflask\n",
        }
    )
    osv = FakeOsvClient(ids_by_name={"numpy": []})
    _override(fetcher=fetcher, osv_client=osv)

    resp = client.post(f"/api/assets/{asset.id}/scan")

    assert resp.status_code == 200
    assert resp.json()["ComponentCount"] == 1
    assert resp.json()["SkippedEntryCount"] == 2


def test_two_scans_keep_previous_result_intact(client, db_session, asset):
    fetcher, osv = _dedup_fetcher_and_osv()
    _override(fetcher=fetcher, osv_client=osv)

    first = client.post(f"/api/assets/{asset.id}/scan")
    assert first.status_code == 200
    first_scan = db_session.scalars(select(ScanResult).order_by(ScanResult.started_at)).first()
    first_scan_id = first_scan.id
    first_component_ids = {
        component.id for component in db_session.scalars(select(Component)).all()
    }

    second = client.post(f"/api/assets/{asset.id}/scan")
    assert second.status_code == 200

    scans = db_session.scalars(select(ScanResult).order_by(ScanResult.started_at)).all()
    assert len(scans) == 2
    assert scans[0].id == first_scan_id
    assert scans[0].component_count == 1
    assert first_component_ids.issubset(
        {component.id for component in db_session.scalars(select(Component)).all()}
    )


def test_failed_scan_inserts_nothing_and_keeps_last_scanned(client, db_session, asset):
    fetcher, osv = _dedup_fetcher_and_osv()
    _override(fetcher=fetcher, osv_client=osv)
    assert client.post(f"/api/assets/{asset.id}/scan").status_code == 200
    db_session.refresh(asset)
    scanned_at = asset.last_scanned_at

    _override(fetcher=FakeManifestFetcher(error=RepositoryNotFound()))

    resp = client.post(f"/api/assets/{asset.id}/scan")

    assert resp.status_code == 422
    assert resp.json() == {"Message": "Repositori tidak ditemukan atau bersifat privat."}
    assert len(db_session.scalars(select(ScanResult)).all()) == 1
    db_session.refresh(asset)
    assert asset.last_scanned_at == scanned_at


def test_failed_scan_on_fresh_asset_leaves_everything_empty(client, db_session, asset):
    _override(fetcher=FakeManifestFetcher(error=RepositoryNotFound()))

    resp = client.post(f"/api/assets/{asset.id}/scan")

    assert resp.status_code == 422
    assert db_session.scalars(select(ScanResult)).all() == []
    db_session.refresh(asset)
    assert asset.last_scanned_at is None


def test_get_endpoints_never_trigger_a_scan(client, asset):
    fetcher, osv = _dedup_fetcher_and_osv()
    _override(fetcher=fetcher, osv_client=osv)

    assert client.get(f"/api/assets/{asset.id}/scan-results/latest").status_code == 200
    assert client.get(f"/api/projects/{asset.project_id}/assets").status_code == 200

    assert fetcher.calls == 0
    assert osv.batch_calls == 0


def test_latest_returns_null_when_never_scanned(client, asset):
    resp = client.get(f"/api/assets/{asset.id}/scan-results/latest")

    assert resp.status_code == 200
    assert resp.json() is None


def test_latest_returns_components_sorted_by_severity(client, asset):
    fetcher = FakeManifestFetcher(
        manifests={"package.json": '{"dependencies": {"lodash": "^4.17.20", "express": "^4.17.1"}}'}
    )
    low_vuln = {
        "id": "GHSA-low",
        "aliases": ["CVE-2024-43796"],
        "summary": "Low severity issue",
        "database_specific": {"severity": "LOW"},
    }
    high_a = fixture_json("osv_vuln_dedup_a.json")
    high_b = fixture_json("osv_vuln_dedup_b.json")
    osv = FakeOsvClient(
        ids_by_name={
            "lodash": ["GHSA-35jh-r3h4-6jhm", "GHSA-r5fr-rjxr-66jc"],
            "express": ["GHSA-low"],
        },
        vulns={
            "GHSA-35jh-r3h4-6jhm": high_a,
            "GHSA-r5fr-rjxr-66jc": high_b,
            "GHSA-low": low_vuln,
        },
    )
    _override(fetcher=fetcher, osv_client=osv)

    assert client.post(f"/api/assets/{asset.id}/scan").status_code == 200
    body = client.get(f"/api/assets/{asset.id}/scan-results/latest").json()

    assert [component["Name"] for component in body["Components"]] == ["lodash", "express"]
    lodash, express = body["Components"]
    assert lodash["HighestSeverity"] == "HIGH"
    assert lodash["License"] == "Tidak diketahui"
    assert set(lodash) == {
        "Id",
        "Name",
        "Version",
        "Ecosystem",
        "Purl",
        "License",
        "HighestSeverity",
        "Vulnerabilities",
    }
    assert set(lodash["Vulnerabilities"][0]) == {"Id", "CveId", "Severity", "Description"}
    assert lodash["Vulnerabilities"][0]["CveId"] == "CVE-2021-23337"
    assert express["HighestSeverity"] == "LOW"


def test_latest_highest_severity_is_null_without_cve(client, asset):
    fetcher = FakeManifestFetcher(
        manifests={"package.json": '{"dependencies": {"express": "^4.17.1"}}'}
    )
    osv = FakeOsvClient(ids_by_name={"express": []})
    _override(fetcher=fetcher, osv_client=osv)

    assert client.post(f"/api/assets/{asset.id}/scan").status_code == 200
    body = client.get(f"/api/assets/{asset.id}/scan-results/latest").json()

    assert body["Components"][0]["HighestSeverity"] is None
    assert body["Components"][0]["Vulnerabilities"] == []


def test_withdrawn_records_are_skipped(client, db_session, asset):
    fetcher = FakeManifestFetcher(
        manifests={"package.json": '{"dependencies": {"lodash": "^4.17.20"}}'}
    )
    osv = FakeOsvClient(
        ids_by_name={"lodash": ["GHSA-withdrawn-example", "GHSA-35jh-r3h4-6jhm"]},
        vulns={
            "GHSA-withdrawn-example": fixture_json("osv_vuln_withdrawn.json"),
            "GHSA-35jh-r3h4-6jhm": fixture_json("osv_vuln_dedup_a.json"),
        },
    )
    _override(fetcher=fetcher, osv_client=osv)

    assert client.post(f"/api/assets/{asset.id}/scan").status_code == 200

    vulnerabilities = db_session.scalars(select(Vulnerability)).all()
    assert len(vulnerabilities) == 1
    assert vulnerabilities[0].cve_id == "CVE-2021-23337"


def test_serialized_dedup_keeps_one_row_per_cve(client, db_session, asset):
    fetcher, osv = _dedup_fetcher_and_osv()
    _override(fetcher=fetcher, osv_client=osv)

    client.post(f"/api/assets/{asset.id}/scan")

    assert len(osv.detail_calls) == 2
    assert len(db_session.scalars(select(Vulnerability)).all()) == 1


def test_other_user_asset_returns_404(client, db_session, demo_user):
    other = User(email="other@example.com", password_hash="x")
    db_session.add(other)
    db_session.commit()
    db_session.refresh(other)
    project = Project(user_id=other.id, name="Rahasia", description=None)
    db_session.add(project)
    db_session.commit()
    db_session.refresh(project)
    foreign_asset = _make_asset(
        db_session, project, "https://github.com/secret/repo", "secret", "repo"
    )

    assert client.get(f"/api/assets/{foreign_asset.id}/scan-results/latest").status_code == 404
    resp = client.post(f"/api/assets/{foreign_asset.id}/scan")
    assert resp.status_code == 404
    assert resp.json() == {"Message": "Aset tidak ditemukan."}


def test_unknown_asset_returns_404(client, demo_user):
    resp = client.post("/api/assets/tidak-ada/scan")
    assert resp.status_code == 404
    assert resp.json() == {"Message": "Aset tidak ditemukan."}


def test_gitlab_asset_returns_422(client, db_session, project):
    gitlab_asset = _make_asset(
        db_session, project, "https://gitlab.com/pulse/api", "pulse", "api", name="api"
    )

    resp = client.post(f"/api/assets/{gitlab_asset.id}/scan")

    assert resp.status_code == 422
    assert resp.json() == {"Message": "Pemindaian untuk repositori GitLab belum didukung."}


def test_manifest_size_cap_returns_422(client, asset):
    router = RoutingHttpClient().add_get(
        "requirements.txt", HttpResponse(200, "x" * (1024 * 1024 + 10))
    )
    _override(http_client=router)

    resp = client.post(f"/api/assets/{asset.id}/scan")

    assert resp.status_code == 422
    assert resp.json() == {"Message": "Berkas manifest terlalu besar (maksimum 1 MB)."}


def test_github_unreachable_returns_502(client, asset):
    router = RoutingHttpClient().add_get("raw.githubusercontent.com", HttpTransportError("boom"))
    _override(http_client=router)

    resp = client.post(f"/api/assets/{asset.id}/scan")

    assert resp.status_code == 502
    assert resp.json() == {"Message": "Layanan GitHub tidak dapat dihubungi. Coba lagi nanti."}


def test_repository_not_found_returns_422(client, asset):
    router = RoutingHttpClient()
    _override(http_client=router)

    resp = client.post(f"/api/assets/{asset.id}/scan")

    assert resp.status_code == 422
    assert resp.json() == {"Message": "Repositori tidak ditemukan atau bersifat privat."}


def test_no_supported_manifest_returns_422(client, asset):
    router = RoutingHttpClient().add_get("api.github.com/repos", {"full_name": "expressjs/express"})
    _override(http_client=router)

    resp = client.post(f"/api/assets/{asset.id}/scan")

    assert resp.status_code == 422
    assert resp.json() == {
        "Message": "Tidak ada manifest yang didukung (requirements.txt / package.json)."
    }


def test_osv_unreachable_returns_502(client, asset):
    router = (
        RoutingHttpClient()
        .add_get("package.json", HttpResponse(200, fixture_text("package_json_express.json")))
        .add_post("api.osv.dev", HttpTransportError("boom"))
    )
    _override(http_client=router)

    resp = client.post(f"/api/assets/{asset.id}/scan")

    assert resp.status_code == 502
    assert resp.json() == {
        "Message": "Layanan CVE (OSV.dev) tidak dapat dihubungi. Coba lagi nanti."
    }
