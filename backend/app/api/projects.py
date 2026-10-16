from fastapi import APIRouter, status

from app.api.deps import CurrentUser, DbSession
from app.schemas.project import ProjectCreate, ProjectOut
from app.services import project_service

router = APIRouter(prefix="/api/projects", tags=["projects"])


@router.get("", response_model=list[ProjectOut])
def list_projects(db: DbSession, current_user: CurrentUser):
    return project_service.list_projects(db, current_user)


@router.post("", response_model=ProjectOut, status_code=status.HTTP_201_CREATED)
def create_project(payload: ProjectCreate, db: DbSession, current_user: CurrentUser):
    project = project_service.create_project(db, current_user, payload.name, payload.description)
    db.commit()
    db.refresh(project)
    return project
