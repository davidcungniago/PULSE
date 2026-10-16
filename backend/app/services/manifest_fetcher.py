from dataclasses import dataclass
from urllib.parse import urlsplit

from app.models.asset import Asset
from app.services.http_client import HttpClient, HttpTransportError, ResponseTooLarge
from app.services.manifest_parser import PACKAGE_JSON_FILENAME, REQUIREMENTS_FILENAME
from app.services.scan_errors import (
    GitHubUnreachable,
    ManifestTooLarge,
    NoSupportedManifest,
    RepositoryNotFound,
    UnsupportedRepositoryHost,
)

MANIFEST_FILENAMES = (REQUIREMENTS_FILENAME, PACKAGE_JSON_FILENAME)


@dataclass(frozen=True)
class FetchedManifest:
    manifests: dict[str, str]


class GitHubManifestFetcher:
    def __init__(
        self,
        http: HttpClient,
        raw_base_url: str,
        api_base_url: str,
        max_bytes: int,
    ) -> None:
        self._http = http
        self._raw_base_url = raw_base_url.rstrip("/")
        self._api_base_url = api_base_url.rstrip("/")
        self._max_bytes = max_bytes

    def fetch(self, asset: Asset) -> FetchedManifest:
        host = (urlsplit(asset.repository_url).hostname or "").lower()
        if host != "github.com":
            raise UnsupportedRepositoryHost()

        manifests: dict[str, str] = {}
        for filename in MANIFEST_FILENAMES:
            text = self._fetch_manifest(asset, filename)
            if text is not None:
                manifests[filename] = text

        if not manifests:
            if not self._repository_exists(asset):
                raise RepositoryNotFound()
            raise NoSupportedManifest()
        return FetchedManifest(manifests)

    def _fetch_manifest(self, asset: Asset, filename: str) -> str | None:
        url = f"{self._raw_base_url}/{asset.owner}/{asset.repository_name}/HEAD/{filename}"
        try:
            response = self._http.get(url, max_bytes=self._max_bytes)
        except HttpTransportError as exc:
            raise GitHubUnreachable() from exc
        except ResponseTooLarge as exc:
            raise ManifestTooLarge() from exc

        if response.status_code == 200:
            if len(response.text.encode("utf-8")) > self._max_bytes:
                raise ManifestTooLarge()
            return response.text
        if response.status_code == 404:
            return None
        raise GitHubUnreachable()

    def _repository_exists(self, asset: Asset) -> bool:
        url = f"{self._api_base_url}/repos/{asset.owner}/{asset.repository_name}"
        try:
            response = self._http.get(url)
        except HttpTransportError as exc:
            raise GitHubUnreachable() from exc

        if response.status_code == 200:
            return True
        if response.status_code == 404:
            return False
        raise GitHubUnreachable()
