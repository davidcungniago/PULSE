from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, new_uuid, utcnow

if TYPE_CHECKING:
    from app.models.asset import Asset
    from app.models.component import Component


class ScanResult(Base):
    __tablename__ = "scan_results"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    asset_id: Mapped[str] = mapped_column(
        ForeignKey("assets.id", ondelete="CASCADE"), nullable=False, index=True
    )
    component_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    critical_vulnerability_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    started_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=utcnow, nullable=False
    )
    finished_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    status: Mapped[str] = mapped_column(String(32), nullable=False)

    asset: Mapped["Asset"] = relationship(back_populates="scan_results")
    components: Mapped[list["Component"]] = relationship(
        back_populates="scan_result", cascade="all, delete-orphan"
    )
