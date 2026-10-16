from fastapi import APIRouter, HTTPException, status
from sqlalchemy import select

from app.api.deps import CurrentUser, DbSession
from app.models.project import Project
from app.schemas.asset import AssetCreate, AssetOut
from app.services import asset_service
from app.services.asset_service import DuplicateAssetError
from app.services.repository_url import InvalidRepositoryUrl

router = APIRouter(prefix="/api/projects", tags=["assets"])


def _owned_project(db: DbSession, project_id: str, current_user: CurrentUser) -> Project:
    project = db.scalar(
        select(Project).where(
            Project.id == project_id,
            Project.user_id == current_user.id,
        )
    )
    if project is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Proyek tidak ditemukan.",
        )
    return project


@router.get("/{projectId}/assets", response_model=list[AssetOut])
def list_assets(projectId: str, db: DbSession, current_user: CurrentUser):
    project = _owned_project(db, projectId, current_user)
    return asset_service.list_assets(db, project)


@router.post(
    "/{projectId}/assets",
    response_model=AssetOut,
    status_code=status.HTTP_201_CREATED,
)
def create_asset(
    projectId: str,
    payload: AssetCreate,
    db: DbSession,
    current_user: CurrentUser,
):
    project = _owned_project(db, projectId, current_user)
    try:
        asset = asset_service.create_asset(db, project, payload.repository_url)
    except InvalidRepositoryUrl as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc
    except DuplicateAssetError as exc:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc)) from exc
    db.commit()
    db.refresh(asset)
    return asset
