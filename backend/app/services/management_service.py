from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.asset import Asset
from app.models.project import Project
from app.models.scan_result import ScanResult
from app.services.repository_url import parse_repository_url


def update_project(project: Project, name: str, description: str | None):
    project.name = name
    project.description = description


def delete_project(db: Session, project: Project):
    if db.scalar(select(Asset.id).where(Asset.project_id == project.id).limit(1)):
        raise ValueError("Proyek berisi aset tidak dapat dihapus agar riwayat tetap tersimpan.")
    db.delete(project)


def update_asset(db: Session, asset: Asset, name: str, repository_url: str, active: bool):
    parsed = parse_repository_url(repository_url)
    if parsed.repository_url != asset.repository_url and db.scalar(
        select(ScanResult.id).where(ScanResult.asset_id == asset.id).limit(1)
    ):
        raise ValueError("URL aset yang sudah dipindai tidak dapat diubah. Tambahkan aset baru.")
    duplicate = db.scalar(
        select(Asset.id).where(
            Asset.project_id == asset.project_id,
            Asset.repository_url == parsed.repository_url,
            Asset.id != asset.id,
        )
    )
    if duplicate:
        raise ValueError("URL repositori ini sudah ada di project ini.")
    asset.name = name
    asset.repository_url = parsed.repository_url
    asset.owner = parsed.owner
    asset.repository_name = parsed.repository_name
    asset.is_active = active
