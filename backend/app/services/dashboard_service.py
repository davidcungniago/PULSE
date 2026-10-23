from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.asset import Asset
from app.models.monitoring import DriftEvent
from app.services.monitoring_rules import risk_status
from app.services.scan_service import get_latest_scan


def dashboard(db: Session, project_id: str) -> dict:
    assets = list(
        db.scalars(select(Asset).where(Asset.project_id == project_id, Asset.is_active.is_(True)))
    )
    rows = []
    components = critical = drift_count = 0
    for asset in assets:
        scan = get_latest_scan(db, asset)
        drift = (
            scan is not None
            and db.scalar(
                select(DriftEvent.id).where(DriftEvent.scan_result_id == scan.id).limit(1)
            )
            is not None
        )
        count = scan.component_count if scan else 0
        critical_count = scan.critical_vulnerability_count if scan else 0
        vulnerability_count = sum(len(c.vulnerabilities) for c in scan.components) if scan else 0
        components += count
        critical += critical_count
        drift_count += int(drift)
        rows.append(
            {
                "AssetId": asset.id,
                "AssetName": asset.name,
                "ComponentCount": count,
                "CriticalVulnerabilityCount": critical_count,
                "LastScannedAt": asset.last_scanned_at,
                "RiskStatus": risk_status(
                    scan is not None, critical_count, vulnerability_count, drift
                ),
            }
        )
    return {
        "TotalAssets": len(assets),
        "TotalComponents": components,
        "CriticalVulnerabilities": critical,
        "AssetsWithDrift": drift_count,
        "AssetsNeverScanned": sum(a.last_scanned_at is None for a in assets),
        "Assets": rows,
    }
