import pytest

from app.services.repository_url import InvalidRepositoryUrl, parse_repository_url

VALID_URLS = [
    (
        "https://github.com/expressjs/express",
        "https://github.com/expressjs/express",
        "expressjs",
        "express",
    ),
    (
        "https://github.com/expressjs/express.git",
        "https://github.com/expressjs/express",
        "expressjs",
        "express",
    ),
    (
        "https://github.com/expressjs/express/",
        "https://github.com/expressjs/express",
        "expressjs",
        "express",
    ),
    (
        "https://github.com/expressjs/express.git/",
        "https://github.com/expressjs/express",
        "expressjs",
        "express",
    ),
    ("https://gitlab.com/group/project", "https://gitlab.com/group/project", "group", "project"),
    ("https://GitHub.com/Owner/Repo", "https://github.com/Owner/Repo", "Owner", "Repo"),
    ("   https://github.com/owner/repo   ", "https://github.com/owner/repo", "owner", "repo"),
]

INVALID_URLS = [
    ("", "URL repositori wajib diisi."),
    ("    ", "URL repositori wajib diisi."),
    ("https://evilgithub.com/a/b", "Hanya URL github.com atau gitlab.com yang didukung."),
    ("https://github.com.evil.io/a/b", "Hanya URL github.com atau gitlab.com yang didukung."),
    ("https://bitbucket.org/a/b", "Hanya URL github.com atau gitlab.com yang didukung."),
    ("https://user:pass@github.com/a/b", "URL tidak boleh berisi kredensial pengguna."),
    ("https://github.com:8443/a/b", "URL tidak boleh menyertakan port."),
    ("http://github.com/a/b", "URL harus menggunakan https."),
    ("https://github.com/owner", "URL harus berformat owner/nama-repositori."),
    ("https://github.com/", "URL harus berformat owner/nama-repositori."),
    ("https://github.com/owner/repo/tree/main", "URL harus berformat owner/nama-repositori."),
    ("https://github.com/owner/repo?tab=readme", "URL tidak boleh berisi query string."),
    ("https://github.com/owner/repo#readme", "URL tidak boleh berisi fragment."),
    (
        "https://github.com/owner/re po",
        "Nama owner atau repositori berisi karakter yang tidak valid.",
    ),
    (
        "https://github.com/owner/re~po",
        "Nama owner atau repositori berisi karakter yang tidak valid.",
    ),
]


@pytest.mark.parametrize(("raw", "canonical", "owner", "repository_name"), VALID_URLS)
def test_parse_repository_url_accepts(raw, canonical, owner, repository_name):
    parsed = parse_repository_url(raw)
    assert parsed.repository_url == canonical
    assert parsed.owner == owner
    assert parsed.repository_name == repository_name


@pytest.mark.parametrize(("raw", "message"), INVALID_URLS)
def test_parse_repository_url_rejects(raw, message):
    with pytest.raises(InvalidRepositoryUrl) as error:
        parse_repository_url(raw)
    assert str(error.value) == message
