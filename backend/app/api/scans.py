from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.api.deps import (
    CurrentUser,
    DbSession,
    ManifestFetcherDep,
    OsvClientDep,
)
from app.models.asset import Asset
from app.models.project import Project
from app.schemas.scan import ScanResultDetailOut, ScanSummaryOut
from app.services import scan_service
from app.services.scan_errors import (
    GitHubUnreachable,
    ManifestTooLarge,
    NoSupportedManifest,
    OsvUnreachable,
    RepositoryNotFound,
    UnsupportedRepositoryHost,
)

router = APIRouter(prefix="/api/assets", tags=["scan"])

_SCAN_ERROR_STATUS: dict[type, int] = {
    UnsupportedRepositoryHost: status.HTTP_422_UNPROCESSABLE_CONTENT,
    RepositoryNotFound: status.HTTP_422_UNPROCESSABLE_CONTENT,
    NoSupportedManifest: status.HTTP_422_UNPROCESSABLE_CONTENT,
    ManifestTooLarge: status.HTTP_422_UNPROCESSABLE_CONTENT,
    GitHubUnreachable: status.HTTP_502_BAD_GATEWAY,
    OsvUnreachable: status.HTTP_502_BAD_GATEWAY,
}


def _owned_asset(db: DbSession, asset_id: str, current_user: CurrentUser) -> Asset:
    asset = db.scalar(
        select(Asset)
        .join(Project, Asset.project_id == Project.id)
        .where(Asset.id == asset_id, Project.user_id == current_user.id)
    )
    if asset is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Aset tidak ditemukan.",
        )
    return asset


@router.post("/{assetId}/scan", response_model=ScanSummaryOut)
def scan_asset(
    assetId: str,
    db: DbSession,
    current_user: CurrentUser,
    manifest_fetcher: ManifestFetcherDep,
    osv_client: OsvClientDep,
):
    asset = _owned_asset(db, assetId, current_user)
    try:
        outcome = scan_service.run_scan(db, asset, manifest_fetcher, osv_client)
    except tuple(_SCAN_ERROR_STATUS) as exc:
        raise HTTPException(status_code=_SCAN_ERROR_STATUS[type(exc)], detail=str(exc)) from exc

    return {
        "asset_id": outcome.asset_id,
        "component_count": outcome.component_count,
        "critical_vulnerability_count": outcome.critical_vulnerability_count,
        "skipped_entry_count": outcome.skipped_entry_count,
        "started_at": outcome.started_at,
        "finished_at": outcome.finished_at,
        "message": scan_service.SCAN_MESSAGE_SUCCESS,
    }


@router.get("/{assetId}/scan-results/latest", response_model=ScanResultDetailOut | None)
def latest_scan_result(assetId: str, db: DbSession, current_user: CurrentUser):
    asset = _owned_asset(db, assetId, current_user)
    scan = scan_service.get_latest_scan(db, asset)
    if scan is None:
        return None
    return scan_service.build_detail(scan)
