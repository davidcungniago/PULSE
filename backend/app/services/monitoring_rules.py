def calculate_drift(previous: dict[str, str] | None, current: dict[str, str]) -> list[dict]:
    if previous is None:
        return []
    events = []
    for name in sorted(previous.keys() | current.keys()):
        if name not in previous:
            kind, details = "added", f"Komponen ditambahkan: {current[name]}."
        elif name not in current:
            kind, details = "removed", f"Komponen dihapus: {previous[name]}."
        elif previous[name] != current[name]:
            kind, details = "changed", f"Versi berubah: {previous[name]} → {current[name]}."
        else:
            continue
        events.append({"type": kind, "component_name": name, "details": details})
    return events


def risk_status(scanned: bool, critical: int, vulnerabilities: int, drift: bool) -> str:
    if not scanned:
        return "NOT_SCANNED"
    if critical:
        return "CRITICAL"
    if vulnerabilities or drift:
        return "WARNING"
    return "HEALTHY"
