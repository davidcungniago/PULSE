from datetime import datetime

from app.schemas.base import PascalModel


class AssetCreate(PascalModel):
    repository_url: str


class AssetOut(PascalModel):
    id: str
    project_id: str
    name: str
    repository_url: str
    owner: str
    repository_name: str
    is_active: bool
    last_scanned_at: datetime | None
    created_at: datetime
