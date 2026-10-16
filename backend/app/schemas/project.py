from datetime import datetime

from pydantic import field_validator

from app.schemas.base import PascalModel


class ProjectCreate(PascalModel):
    name: str
    description: str | None = None

    @field_validator("name")
    @classmethod
    def validate_name(cls, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError("Nama proyek wajib diisi.")
        return stripped


class ProjectOut(PascalModel):
    id: str
    user_id: str
    name: str
    description: str | None
    created_at: datetime
