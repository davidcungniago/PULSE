SEVERITY_LEVELS = ("CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN")
NO_SEVERITY_RANK = len(SEVERITY_LEVELS)

_SEVERITY_RANK = {level: index for index, level in enumerate(SEVERITY_LEVELS)}
_ALIASES = {"MODERATE": "MEDIUM"}


def normalize_severity(vulnerability: dict) -> str:
    database_specific = vulnerability.get("database_specific")
    if not isinstance(database_specific, dict):
        return "UNKNOWN"
    raw = database_specific.get("severity")
    if not isinstance(raw, str):
        return "UNKNOWN"
    value = raw.strip().upper()
    value = _ALIASES.get(value, value)
    return value if value in _SEVERITY_RANK else "UNKNOWN"


def severity_rank(severity: str) -> int:
    return _SEVERITY_RANK[severity]


def sort_rank(severity: str | None) -> int:
    if severity is None:
        return NO_SEVERITY_RANK
    return severity_rank(severity)


def highest_severity(severities: list[str]) -> str | None:
    best: str | None = None
    for severity in severities:
        if best is None or severity_rank(severity) < severity_rank(best):
            best = severity
    return best
