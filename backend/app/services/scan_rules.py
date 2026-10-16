import re
from dataclasses import dataclass

from app.services.severity import normalize_severity, severity_rank, sort_rank

_PYPI_SEPARATORS = re.compile(r"[-_.]+")


@dataclass(frozen=True)
class VulnerabilityValue:
    cve_id: str
    severity: str
    description: str


def normalize_pypi_name(name: str) -> str:
    return _PYPI_SEPARATORS.sub("-", name.strip().lower())


def build_purl(ecosystem: str, name: str, version: str) -> str:
    if ecosystem == "PyPI":
        return f"pkg:pypi/{normalize_pypi_name(name)}@{version}"
    if ecosystem == "npm":
        return f"pkg:npm/{name}@{version}"
    return f"pkg:generic/{name}@{version}"


def prefer_cve_id(vulnerability: dict) -> str:
    aliases = vulnerability.get("aliases")
    if isinstance(aliases, list):
        for alias in aliases:
            if isinstance(alias, str) and alias.upper().startswith("CVE-"):
                return alias
    identifier = vulnerability.get("id")
    return identifier if isinstance(identifier, str) else ""


def description_of(vulnerability: dict) -> str:
    summary = vulnerability.get("summary")
    if isinstance(summary, str) and summary.strip():
        return summary.strip()[:2000]
    details = vulnerability.get("details")
    if isinstance(details, str):
        return details.strip()[:2000]
    return ""


def build_vulnerabilities(records: list[dict]) -> list[VulnerabilityValue]:
    by_cve: dict[str, VulnerabilityValue] = {}
    for record in records:
        if record.get("withdrawn"):
            continue
        cve_id = prefer_cve_id(record)
        if not cve_id:
            continue
        severity = normalize_severity(record)
        candidate = VulnerabilityValue(cve_id, severity, description_of(record))
        existing = by_cve.get(cve_id)
        if existing is None or severity_rank(severity) < severity_rank(existing.severity):
            by_cve[cve_id] = candidate
    return sorted(
        by_cve.values(),
        key=lambda item: (severity_rank(item.severity), item.cve_id),
    )


def sort_components(components: list[dict]) -> list[dict]:
    return sorted(
        components,
        key=lambda item: (
            sort_rank(item.get("highest_severity")),
            str(item.get("name", "")).lower(),
        ),
    )
