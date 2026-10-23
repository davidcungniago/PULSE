from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base, new_uuid, utcnow


class DriftEvent(Base):
    __tablename__ = "drift_events"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    asset_id: Mapped[str] = mapped_column(ForeignKey("assets.id"), index=True)
    scan_result_id: Mapped[str] = mapped_column(ForeignKey("scan_results.id"), index=True)
    type: Mapped[str] = mapped_column(String(16))
    component_name: Mapped[str] = mapped_column(String(255))
    details: Mapped[str] = mapped_column(Text)
    detected_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)


class AlertLog(Base):
    __tablename__ = "alert_logs"
    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    project_id: Mapped[str] = mapped_column(ForeignKey("projects.id"), index=True)
    type: Mapped[str] = mapped_column(String(64))
    message: Mapped[str] = mapped_column(Text)
    delivery_status: Mapped[str] = mapped_column(String(32), default="PENDING")
    sent_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
