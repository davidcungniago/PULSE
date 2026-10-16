from app.services.severity import highest_severity, normalize_severity, severity_rank


def _vuln(severity):
    return {"database_specific": {"severity": severity}}


def test_normalize_maps_moderate_to_medium():
    assert normalize_severity(_vuln("MODERATE")) == "MEDIUM"


def test_normalize_keeps_known_levels():
    assert normalize_severity(_vuln("CRITICAL")) == "CRITICAL"
    assert normalize_severity(_vuln("HIGH")) == "HIGH"
    assert normalize_severity(_vuln("LOW")) == "LOW"


def test_normalize_is_case_insensitive():
    assert normalize_severity(_vuln("high")) == "HIGH"
    assert normalize_severity(_vuln(" moderate ")) == "MEDIUM"


def test_normalize_unknown_value_and_missing_field():
    assert normalize_severity(_vuln("SEVERE")) == "UNKNOWN"
    assert normalize_severity({"database_specific": {}}) == "UNKNOWN"
    assert normalize_severity({}) == "UNKNOWN"
    assert normalize_severity({"database_specific": "CRITICAL"}) == "UNKNOWN"


def test_severity_rank_order():
    ordered = ["CRITICAL", "HIGH", "MEDIUM", "LOW", "UNKNOWN"]
    assert [severity_rank(level) for level in ordered] == [0, 1, 2, 3, 4]


def test_highest_severity():
    assert highest_severity([]) is None
    assert highest_severity(["LOW", "CRITICAL", "UNKNOWN"]) == "CRITICAL"
    assert highest_severity(["UNKNOWN", "UNKNOWN"]) == "UNKNOWN"
