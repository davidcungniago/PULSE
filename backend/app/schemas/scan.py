from datetime import datetime

from app.schemas.base import PascalModel


class ScanSummaryOut(PascalModel):
    asset_id: str
    component_count: int
    critical_vulnerability_count: int
    skipped_entry_count: int
    started_at: datetime
    finished_at: datetime | None
    message: str


class VulnerabilityOut(PascalModel):
    id: str
    cve_id: str
    severity: str
    description: str


class ComponentOut(PascalModel):
    id: str
    name: str
    version: str
    ecosystem: str
    purl: str
    license: str
    highest_severity: str | None
    vulnerabilities: list[VulnerabilityOut]


class ScanResultDetailOut(PascalModel):
    id: str
    asset_id: str
    component_count: int
    critical_vulnerability_count: int
    started_at: datetime
    finished_at: datetime | None
    status: str
    components: list[ComponentOut]
