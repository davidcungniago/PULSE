import json

from app.services.manifest_parser import (
    parse_manifests,
    parse_package_json,
    parse_requirements_txt,
)
from tests.support import fixture_json, fixture_text


def _components(parsed):
    return {(c.name, c.version, c.ecosystem) for c in parsed.components}


def test_requirements_real_fixture_parses_pinned_entries():
    parsed = parse_requirements_txt(fixture_text("requirements_sample.txt"))

    assert parsed.skipped_unpinned == 0
    assert _components(parsed) == {
        ("chardet", "5.2.0", "PyPI"),
        ("mkdocs", "1.6.1", "PyPI"),
        ("mkautodoc", "0.2.0", "PyPI"),
        ("mkdocs-material", "9.6.18", "PyPI"),
        ("build", "1.3.0", "PyPI"),
        ("twine", "6.1.0", "PyPI"),
    }


def test_requirements_skips_comments_options_and_unpinned():
    text = (
        "# comment\n"
        "-r other.txt\n"
        "-e .\n"
        "\n"
        "requests>=2.0\n"
        "flask\n"
        "numpy==1.2.3  # inline comment\n"
        'django==4.0 ; python_version >= "3.8"\n'
        "foo[bar]==9.9\n"
    )

    parsed = parse_requirements_txt(text)

    assert parsed.skipped_unpinned == 2
    assert _components(parsed) == {
        ("numpy", "1.2.3", "PyPI"),
        ("django", "4.0", "PyPI"),
        ("foo", "9.9", "PyPI"),
    }


def test_requirements_normalizes_package_names():
    parsed = parse_requirements_txt("Foo_Bar.Baz==1.0\nZope.Interface==6.0\n")

    assert _components(parsed) == {
        ("foo-bar-baz", "1.0", "PyPI"),
        ("zope-interface", "6.0", "PyPI"),
    }


def test_package_json_real_fixture_includes_dependencies_and_dev():
    parsed = parse_package_json(fixture_text("package_json_express.json"))

    components = {c.name: c.version for c in parsed.components}
    assert components["accepts"] == "2.0.0"
    assert components["after"] == "0.8.2"
    assert components["body-parser"] == "2.3.0"
    assert parsed.skipped_unpinned == 0
    assert all(c.ecosystem == "npm" for c in parsed.components)


def test_package_json_strips_version_prefixes():
    payload = fixture_json("package_json_express.json")
    payload["dependencies"] = {
        "caret": "^1.2.3",
        "tilde": "~2.0.1",
        "range": ">=3.0.0 <4.0.0",
        "exact": "4.5.6",
        "prerelease": "1.2.3-beta.1",
        "wildcard": "*",
        "tag": "latest",
    }
    payload["devDependencies"] = {}

    parsed = parse_package_json(json.dumps(payload))

    components = {c.name: c.version for c in parsed.components}
    assert components == {
        "caret": "1.2.3",
        "tilde": "2.0.1",
        "range": "3.0.0",
        "exact": "4.5.6",
        "prerelease": "1.2.3-beta.1",
    }
    assert parsed.skipped_unpinned == 2


def test_package_json_invalid_json_returns_nothing_via_parse_manifests():
    parsed = parse_manifests({"package.json": "{ not json"})

    assert parsed.components == []
    assert parsed.skipped_unpinned == 0


def test_parse_manifests_merges_both_files():
    manifests = {
        "requirements.txt": "numpy==1.2.3\n",
        "package.json": '{"dependencies": {"lodash": "^4.17.20"}}',
    }

    parsed = parse_manifests(manifests)

    assert _components(parsed) == {
        ("numpy", "1.2.3", "PyPI"),
        ("lodash", "4.17.20", "npm"),
    }
