from dataclasses import dataclass
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.base import utcnow
from app.models.asset import Asset
from app.models.component import Component
from app.models.scan_result import ScanResult
from app.models.vulnerability import Vulnerability
from app.services import scan_rules
from app.services.manifest_fetcher import GitHubManifestFetcher
from app.services.manifest_parser import LICENSE_UNKNOWN, parse_manifests
from app.services.osv_client import OsvClient, PackageQuery
from app.services.severity import highest_severity

SCAN_STATUS_SUCCESS = "SUCCESS"
SCAN_MESSAGE_SUCCESS = "Pemindaian selesai."


@dataclass(frozen=True)
class ScanOutcome:
    asset_id: str
    component_count: int
    critical_vulnerability_count: int
    skipped_entry_count: int
    started_at: datetime
    finished_at: datetime


def run_scan(
    db: Session,
    asset: Asset,
    fetcher: GitHubManifestFetcher,
    osv_client: OsvClient,
) -> ScanOutcome:
    started_at = utcnow()
    fetched = fetcher.fetch(asset)
    parsed = parse_manifests(fetched.manifests)
    queries = [
        PackageQuery(component.name, component.ecosystem, component.version)
        for component in parsed.components
    ]
    ids_per_query = osv_client.find_vulnerability_ids(queries) if queries else []

    component_records: list[tuple] = []
    for component, osv_ids in zip(parsed.components, ids_per_query):
        records = [osv_client.get_vulnerability(osv_id) for osv_id in osv_ids]
        component_records.append((component, scan_rules.build_vulnerabilities(records)))

    finished_at = utcnow()
    critical_count = sum(
        1
        for _, vulnerabilities in component_records
        for vulnerability in vulnerabilities
        if vulnerability.severity == "CRITICAL"
    )

    try:
        scan_result = ScanResult(
            asset_id=asset.id,
            component_count=len(component_records),
            critical_vulnerability_count=critical_count,
            started_at=started_at,
            finished_at=finished_at,
            status=SCAN_STATUS_SUCCESS,
        )
        db.add(scan_result)
        db.flush()

        for component, vulnerabilities in component_records:
            model = Component(
                scan_result_id=scan_result.id,
                name=component.name,
                version=component.version,
                ecosystem=component.ecosystem,
                purl=scan_rules.build_purl(component.ecosystem, component.name, component.version),
                license=LICENSE_UNKNOWN,
            )
            db.add(model)
            db.flush()
            for vulnerability in vulnerabilities:
                db.add(
                    Vulnerability(
                        component_id=model.id,
                        cve_id=vulnerability.cve_id,
                        severity=vulnerability.severity,
                        description=vulnerability.description,
                    )
                )

        asset.last_scanned_at = finished_at
        db.commit()
    except Exception:
        db.rollback()
        raise

    db.refresh(scan_result)
    return ScanOutcome(
        asset_id=asset.id,
        component_count=scan_result.component_count,
        critical_vulnerability_count=scan_result.critical_vulnerability_count,
        skipped_entry_count=parsed.skipped_unpinned,
        started_at=scan_result.started_at,
        finished_at=scan_result.finished_at,
    )


def get_latest_scan(db: Session, asset: Asset) -> ScanResult | None:
    statement = (
        select(ScanResult)
        .where(ScanResult.asset_id == asset.id)
        .order_by(ScanResult.started_at.desc(), ScanResult.id.desc())
    )
    return db.scalars(statement).first()


def build_detail(scan: ScanResult) -> dict:
    components = []
    for component in scan.components:
        components.append(
            {
                "id": component.id,
                "name": component.name,
                "version": component.version,
                "ecosystem": component.ecosystem,
                "purl": component.purl,
                "license": component.license,
                "highest_severity": highest_severity(
                    [vulnerability.severity for vulnerability in component.vulnerabilities]
                ),
                "vulnerabilities": [
                    {
                        "id": vulnerability.id,
                        "cve_id": vulnerability.cve_id,
                        "severity": vulnerability.severity,
                        "description": vulnerability.description,
                    }
                    for vulnerability in component.vulnerabilities
                ],
            }
        )
    return {
        "id": scan.id,
        "asset_id": scan.asset_id,
        "component_count": scan.component_count,
        "critical_vulnerability_count": scan.critical_vulnerability_count,
        "started_at": scan.started_at,
        "finished_at": scan.finished_at,
        "status": scan.status,
        "components": scan_rules.sort_components(components),
    }
