from sqlalchemy import select

from app.models.asset import Asset
from app.models.monitoring import AlertLog
from app.models.project import Project
from app.models.user import User
from app.services.scan_service import run_scan
from tests.support import FakeManifestFetcher, FakeOsvClient


def test_new_critical_alert_sent_once_and_drift_sends_again(db_session):
    user = User(email="notify@example.com")
    project = Project(name="Monitor", user=user)
    asset = Asset(
        project=project,
        name="API",
        repository_url="https://github.com/pulse/api",
        owner="pulse",
        repository_name="api",
    )
    db_session.add(asset)
    db_session.commit()
    fetcher = FakeManifestFetcher({"requirements.txt": "requests==2.31.0"})
    osv = FakeOsvClient(
        ids_by_name={"requests": ["GHSA-demo"]},
        vulns={
            "GHSA-demo": {
                "id": "GHSA-demo",
                "aliases": ["CVE-DEMO"],
                "database_specific": {"severity": "CRITICAL"},
            }
        },
    )

    class Mail:
        def __init__(self):
            self.messages = []

        def send(self, recipient, message):
            self.messages.append((recipient, message))
            return True

    mail = Mail()
    run_scan(db_session, asset, fetcher, osv, mail)
    run_scan(db_session, asset, fetcher, osv, mail)
    assert len(mail.messages) == 1
    fetcher.manifests = {"requirements.txt": "requests==2.32.0"}
    run_scan(db_session, asset, fetcher, osv, mail)
    assert len(mail.messages) == 2
    alerts = list(db_session.scalars(select(AlertLog)))
    assert len(alerts) == 2
    assert all(alert.delivery_status == "SENT" for alert in alerts)
