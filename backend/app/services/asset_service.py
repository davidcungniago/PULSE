from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.models.asset import Asset
from app.models.project import Project
from app.services.repository_url import parse_repository_url


class DuplicateAssetError(Exception):
    pass


def list_assets(db: Session, project: Project) -> list[Asset]:
    statement = select(Asset).where(Asset.project_id == project.id).order_by(Asset.created_at)
    return list(db.scalars(statement).all())


def create_asset(db: Session, project: Project, repository_url: str) -> Asset:
    parsed = parse_repository_url(repository_url)

    existing = db.scalar(
        select(Asset).where(
            Asset.project_id == project.id,
            func.lower(Asset.repository_url) == parsed.repository_url.lower(),
        )
    )
    if existing is not None:
        raise DuplicateAssetError("URL repositori ini sudah ada di project ini.")

    asset = Asset(
        project_id=project.id,
        name=parsed.repository_name,
        repository_url=parsed.repository_url,
        owner=parsed.owner,
        repository_name=parsed.repository_name,
        is_active=True,
    )
    db.add(asset)
    try:
        db.flush()
    except IntegrityError as exc:
        db.rollback()
        raise DuplicateAssetError("URL repositori ini sudah ada di project ini.") from exc
    return asset
