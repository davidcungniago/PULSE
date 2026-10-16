from typing import TYPE_CHECKING

from sqlalchemy import ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base, new_uuid

if TYPE_CHECKING:
    from app.models.scan_result import ScanResult
    from app.models.vulnerability import Vulnerability


class Component(Base):
    __tablename__ = "components"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=new_uuid)
    scan_result_id: Mapped[str] = mapped_column(
        ForeignKey("scan_results.id", ondelete="CASCADE"), nullable=False, index=True
    )
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    version: Mapped[str] = mapped_column(String(255), nullable=False)
    ecosystem: Mapped[str] = mapped_column(String(64), nullable=False)
    purl: Mapped[str] = mapped_column(String(512), nullable=False)
    license: Mapped[str] = mapped_column(String(255), nullable=False)

    scan_result: Mapped["ScanResult"] = relationship(back_populates="components")
    vulnerabilities: Mapped[list["Vulnerability"]] = relationship(
        back_populates="component", cascade="all, delete-orphan"
    )
