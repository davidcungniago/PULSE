import re
from dataclasses import dataclass
from urllib.parse import urlsplit

ALLOWED_HOSTS = {"github.com", "gitlab.com"}
_NAME_PATTERN = re.compile(r"^[A-Za-z0-9._-]+$")


class InvalidRepositoryUrl(ValueError):
    pass


@dataclass(frozen=True)
class ParsedRepositoryUrl:
    repository_url: str
    owner: str
    repository_name: str


def parse_repository_url(raw: str) -> ParsedRepositoryUrl:
    value = (raw or "").strip()
    if not value:
        raise InvalidRepositoryUrl("URL repositori wajib diisi.")

    parts = urlsplit(value)

    if parts.scheme.lower() != "https":
        raise InvalidRepositoryUrl("URL harus menggunakan https.")

    if parts.username or parts.password:
        raise InvalidRepositoryUrl("URL tidak boleh berisi kredensial pengguna.")

    try:
        port = parts.port
    except ValueError as exc:
        raise InvalidRepositoryUrl("Port pada URL tidak valid.") from exc
    if port is not None:
        raise InvalidRepositoryUrl("URL tidak boleh menyertakan port.")

    host = (parts.hostname or "").lower()
    if host not in ALLOWED_HOSTS:
        raise InvalidRepositoryUrl("Hanya URL github.com atau gitlab.com yang didukung.")

    if parts.query:
        raise InvalidRepositoryUrl("URL tidak boleh berisi query string.")
    if parts.fragment:
        raise InvalidRepositoryUrl("URL tidak boleh berisi fragment.")

    path = parts.path.strip("/")
    if path.endswith(".git"):
        path = path[: -len(".git")]

    segments = [segment for segment in path.split("/") if segment]
    if len(segments) != 2:
        raise InvalidRepositoryUrl("URL harus berformat owner/nama-repositori.")

    owner, repository_name = segments
    if not _NAME_PATTERN.match(owner) or not _NAME_PATTERN.match(repository_name):
        raise InvalidRepositoryUrl("Nama owner atau repositori berisi karakter yang tidak valid.")

    return ParsedRepositoryUrl(
        repository_url=f"https://{host}/{owner}/{repository_name}",
        owner=owner,
        repository_name=repository_name,
    )
