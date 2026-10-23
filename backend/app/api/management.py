from fastapi import APIRouter, HTTPException, Response

from app.api.assets import _owned_project
from app.api.deps import CurrentUser, DbSession
from app.api.scans import _owned_asset
from app.schemas.asset import AssetOut
from app.schemas.project import ProjectCreate, ProjectOut
from app.services import management_service

router = APIRouter(tags=["management"])


class AssetUpdate(ProjectCreate):
    repository_url: str
    is_active: bool = True


@router.get("/api/projects/{project_id}", response_model=ProjectOut)
def detail(project_id: str, db: DbSession, user: CurrentUser):
    return _owned_project(db, project_id, user)


@router.put("/api/projects/{project_id}", response_model=ProjectOut)
def edit_project(project_id: str, payload: ProjectCreate, db: DbSession, user: CurrentUser):
    project = _owned_project(db, project_id, user)
    management_service.update_project(project, payload.name, payload.description)
    db.commit()
    db.refresh(project)
    return project


@router.delete("/api/projects/{project_id}", status_code=204)
def remove_project(project_id: str, db: DbSession, user: CurrentUser):
    project = _owned_project(db, project_id, user)
    try:
        management_service.delete_project(db, project)
    except ValueError as exc:
        raise HTTPException(409, str(exc)) from exc
    db.commit()
    return Response(status_code=204)


@router.put("/api/assets/{asset_id}", response_model=AssetOut)
def edit_asset(asset_id: str, payload: AssetUpdate, db: DbSession, user: CurrentUser):
    asset = _owned_asset(db, asset_id, user)
    try:
        management_service.update_asset(
            db, asset, payload.name, payload.repository_url, payload.is_active
        )
    except ValueError as exc:
        raise HTTPException(409, str(exc)) from exc
    db.commit()
    db.refresh(asset)
    return asset


@router.delete("/api/assets/{asset_id}", status_code=204)
def deactivate_asset(asset_id: str, db: DbSession, user: CurrentUser):
    asset = _owned_asset(db, asset_id, user)
    asset.is_active = False
    db.commit()
    return Response(status_code=204)
