from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import Boolean, DateTime, ForeignKey, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, new_uuid, utcnow

if TYPE_CHECKING:
    from app.models.project import Project
    from app.models.scan_result import ScanResult


class Asset(Base):
    __tablename__ = "assets"
    __table_args__ = (
        UniqueConstraint("project_id", "repository_url", name="uq_asset_project_repository_url"),
    )

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    project_id: Mapped[str] = mapped_column(
        ForeignKey("projects.id", ondelete="CASCADE"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    repository_url: Mapped[str] = mapped_column(String(512), nullable=False)
    owner: Mapped[str] = mapped_column(String(255), nullable=False)
    repository_name: Mapped[str] = mapped_column(String(255), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    last_scanned_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, nullable=False
    )

    project: Mapped["Project"] = relationship(back_populates="assets")
    scan_results: Mapped[list["ScanResult"]] = relationship(
        back_populates="asset", cascade="all, delete-orphan"
    )
