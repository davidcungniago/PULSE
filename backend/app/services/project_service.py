from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.project import Project
from app.models.user import User


def list_projects(db: Session, user: User) -> list[Project]:
    statement = select(Project).where(Project.user_id == user.id).order_by(Project.created_at)
    return list(db.scalars(statement).all())


def create_project(db: Session, user: User, name: str, description: str | None) -> Project:
    project = Project(user_id=user.id, name=name, description=description)
    db.add(project)
    db.flush()
    return project
