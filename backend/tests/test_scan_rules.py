from app.services.scan_rules import (
    build_purl,
    build_vulnerabilities,
    normalize_pypi_name,
    prefer_cve_id,
    sort_components,
)
from tests.support import fixture_json


def test_normalize_pypi_name():
    assert normalize_pypi_name("Foo_Bar.Baz") == "foo-bar-baz"
    assert normalize_pypi_name("Zope.Interface") == "zope-interface"
    assert normalize_pypi_name("  Flask  ") == "flask"


def test_build_purl():
    assert build_purl("PyPI", "Django", "4.0") == "pkg:pypi/django@4.0"
    assert build_purl("npm", "lodash", "4.17.20") == "pkg:npm/lodash@4.17.20"
    assert build_purl("other", "x", "1") == "pkg:generic/x@1"


def test_prefer_cve_id_prefers_cve_alias():
    assert prefer_cve_id({"aliases": ["GHSA-x", "CVE-2021-1"], "id": "GHSA-y"}) == "CVE-2021-1"
    assert prefer_cve_id({"id": "PYSEC-2020-1"}) == "PYSEC-2020-1"
    assert prefer_cve_id({"aliases": [], "id": "OSV-1"}) == "OSV-1"


def test_build_vulnerabilities_deduplicates_same_cve_keeping_highest():
    record_a = fixture_json("osv_vuln_dedup_a.json")
    record_b = fixture_json("osv_vuln_dedup_b.json")
    lower = {
        "id": "GHSA-lower",
        "aliases": ["CVE-2021-23337"],
        "summary": "Lower severity view",
        "database_specific": {"severity": "LOW"},
    }

    result = build_vulnerabilities([record_a, record_b, lower])

    assert len(result) == 1
    assert result[0].cve_id == "CVE-2021-23337"
    assert result[0].severity == "HIGH"
    assert result[0].description == record_a["summary"]


def test_build_vulnerabilities_skips_withdrawn_records():
    withdrawn = fixture_json("osv_vuln_withdrawn.json")
    record_a = fixture_json("osv_vuln_dedup_a.json")

    result = build_vulnerabilities([withdrawn, record_a])

    assert len(result) == 1
    assert result[0].cve_id == "CVE-2021-23337"


def test_build_vulnerabilities_orders_by_severity():
    records = [
        {"id": "A", "aliases": ["CVE-3"], "database_specific": {"severity": "LOW"}},
        {"id": "B", "aliases": ["CVE-1"], "database_specific": {"severity": "CRITICAL"}},
        {"id": "C", "aliases": ["CVE-2"], "database_specific": {"severity": "HIGH"}},
    ]

    result = build_vulnerabilities(records)

    assert [item.cve_id for item in result] == ["CVE-1", "CVE-2", "CVE-3"]


def test_sort_components_by_severity_then_name():
    components = [
        {"name": "beta", "highest_severity": None},
        {"name": "alpha", "highest_severity": None},
        {"name": "low", "highest_severity": "LOW"},
        {"name": "unknown", "highest_severity": "UNKNOWN"},
        {"name": "critical", "highest_severity": "CRITICAL"},
        {"name": "high", "highest_severity": "HIGH"},
        {"name": "medium", "highest_severity": "MEDIUM"},
    ]

    ordered = [item["name"] for item in sort_components(components)]

    assert ordered == [
        "critical",
        "high",
        "medium",
        "low",
        "unknown",
        "alpha",
        "beta",
    ]
