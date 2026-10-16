import json
import re
from dataclasses import dataclass, field

from app.services.scan_rules import normalize_pypi_name

REQUIREMENTS_FILENAME = "requirements.txt"
PACKAGE_JSON_FILENAME = "package.json"
LICENSE_UNKNOWN = "Tidak diketahui"

_PINNED = re.compile(r"^([A-Za-z0-9._-]+)(?:\[[^\]]*\])?\s*==\s*([^\s;#]+)")
_NPM_PREFIX = re.compile(r"^[\^~>=<\s]*")
_NPM_VERSION = re.compile(r"\d+(?:\.\d+)*[A-Za-z0-9._+-]*")


@dataclass(frozen=True)
class ParsedComponent:
    name: str
    version: str
    ecosystem: str


@dataclass
class ParsedManifest:
    components: list[ParsedComponent] = field(default_factory=list)
    skipped_unpinned: int = 0

    def extend(self, other: "ParsedManifest") -> None:
        self.components.extend(other.components)
        self.skipped_unpinned += other.skipped_unpinned


def parse_requirements_txt(text: str) -> ParsedManifest:
    result = ParsedManifest()
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("-"):
            continue
        match = _PINNED.match(line)
        if match is None:
            result.skipped_unpinned += 1
            continue
        name, version = match.group(1), match.group(2)
        result.components.append(ParsedComponent(normalize_pypi_name(name), version, "PyPI"))
    return result


def _baseline_npm_version(spec: object) -> str | None:
    if not isinstance(spec, str):
        return None
    candidate = spec.strip()
    if not candidate or candidate.startswith(("http", "git", "file:")):
        return None
    stripped = _NPM_PREFIX.sub("", candidate)
    match = _NPM_VERSION.search(stripped)
    return match.group(0) if match else None


def parse_package_json(text: str) -> ParsedManifest:
    result = ParsedManifest()
    data = json.loads(text)
    if not isinstance(data, dict):
        return result
    for section in ("dependencies", "devDependencies"):
        dependencies = data.get(section)
        if not isinstance(dependencies, dict):
            continue
        for name, spec in dependencies.items():
            version = _baseline_npm_version(spec)
            if version is None:
                result.skipped_unpinned += 1
                continue
            result.components.append(ParsedComponent(name, version, "npm"))
    return result


def parse_manifests(manifests: dict[str, str]) -> ParsedManifest:
    result = ParsedManifest()
    if REQUIREMENTS_FILENAME in manifests:
        result.extend(parse_requirements_txt(manifests[REQUIREMENTS_FILENAME]))
    if PACKAGE_JSON_FILENAME in manifests:
        try:
            result.extend(parse_package_json(manifests[PACKAGE_JSON_FILENAME]))
        except json.JSONDecodeError:
            pass
    return result
