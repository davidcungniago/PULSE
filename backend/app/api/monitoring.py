from datetime import datetime

from fastapi import APIRouter
from sqlalchemy import select

from app.api.assets import _owned_project
from app.api.deps import CurrentUser, DbSession
from app.api.scans import _owned_asset
from app.models.monitoring import AlertLog, DriftEvent
from app.models.scan_result import ScanResult
from app.schemas.base import PascalModel
from app.schemas.scan import ScanResultDetailOut
from app.services.dashboard_service import dashboard
from app.services.scan_service import build_detail, get_latest_scan

router = APIRouter(tags=["monitoring"])


class DriftOut(PascalModel):
    id: str
    asset_id: str
    type: str
    component_name: str
    details: str
    detected_at: datetime


class AlertOut(PascalModel):
    id: str
    project_id: str
    type: str
    message: str
    delivery_status: str
    sent_at: datetime


@router.get("/api/projects/{project_id}/dashboard")
def get_dashboard(project_id: str, db: DbSession, user: CurrentUser):
    _owned_project(db, project_id, user)
    return dashboard(db, project_id)


@router.get("/api/projects/{project_id}/alerts", response_model=list[AlertOut])
def get_alerts(project_id: str, db: DbSession, user: CurrentUser):
    _owned_project(db, project_id, user)
    return list(
        db.scalars(
            select(AlertLog)
            .where(AlertLog.project_id == project_id)
            .order_by(AlertLog.sent_at.desc())
        )
    )


@router.get("/api/assets/{asset_id}/drift-events", response_model=list[DriftOut])
def get_drift(asset_id: str, db: DbSession, user: CurrentUser):
    asset = _owned_asset(db, asset_id, user)
    scan = get_latest_scan(db, asset)
    if scan is None:
        return []
    return list(
        db.scalars(
            select(DriftEvent)
            .where(DriftEvent.scan_result_id == scan.id)
            .order_by(DriftEvent.component_name)
        )
    )


@router.get("/api/assets/{asset_id}/scan-results", response_model=list[ScanResultDetailOut])
def get_history(asset_id: str, db: DbSession, user: CurrentUser):
    _owned_asset(db, asset_id, user)
    scans = db.scalars(
        select(ScanResult)
        .where(ScanResult.asset_id == asset_id)
        .order_by(ScanResult.started_at.desc())
    )
    return [build_detail(scan) for scan in scans]
