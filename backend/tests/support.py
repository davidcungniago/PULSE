import json
from pathlib import Path
from typing import Any

from app.services.http_client import HttpResponse
from app.services.manifest_fetcher import FetchedManifest
from app.services.osv_client import PackageQuery

FIXTURES_DIR = Path(__file__).parent / "fixtures"


def fixture_json(name: str) -> Any:
    return json.loads((FIXTURES_DIR / name).read_text(encoding="utf-8"))


def fixture_text(name: str) -> str:
    return (FIXTURES_DIR / name).read_text(encoding="utf-8")


class RoutingHttpClient:
    """Deterministic HttpClient that never touches the network."""

    def __init__(self) -> None:
        self._get_handlers: list[tuple[str, Any]] = []
        self._post_handlers: list[tuple[str, Any]] = []
        self.get_urls: list[str] = []
        self.post_urls: list[str] = []
        self.post_bodies: list[dict] = []

    def add_get(self, fragment: str, response: Any) -> "RoutingHttpClient":
        self._get_handlers.append((fragment, response))
        return self

    def add_post(self, fragment: str, response: Any) -> "RoutingHttpClient":
        self._post_handlers.append((fragment, response))
        return self

    def get(self, url: str, *, max_bytes: int | None = None) -> HttpResponse:
        self.get_urls.append(url)
        for fragment, response in self._get_handlers:
            if fragment in url:
                if isinstance(response, Exception):
                    raise response
                return _as_response(response)
        return HttpResponse(404, "")

    def post_json(self, url: str, payload: dict) -> HttpResponse:
        self.post_urls.append(url)
        self.post_bodies.append(payload)
        for fragment, response in self._post_handlers:
            if fragment in url:
                if isinstance(response, Exception):
                    raise response
                return _as_response(response)
        return HttpResponse(404, "{}")


class FakeManifestFetcher:
    def __init__(self, manifests: dict[str, str] | None = None, error: Exception | None = None):
        self.manifests = manifests or {}
        self.error = error
        self.calls = 0

    def fetch(self, asset) -> FetchedManifest:
        self.calls += 1
        if self.error is not None:
            raise self.error
        return FetchedManifest(dict(self.manifests))


class FakeOsvClient:
    def __init__(
        self,
        ids_by_name: dict[str, list[str]] | None = None,
        vulns: dict[str, dict] | None = None,
        error: Exception | None = None,
    ):
        self.ids_by_name = ids_by_name or {}
        self.vulns = vulns or {}
        self.error = error
        self.batch_calls = 0
        self.detail_calls: list[str] = []
        self.queries: list[list[PackageQuery]] = []

    def find_vulnerability_ids(self, queries: list[PackageQuery]) -> list[list[str]]:
        self.batch_calls += 1
        self.queries.append(list(queries))
        if self.error is not None:
            raise self.error
        return [list(self.ids_by_name.get(query.name, [])) for query in queries]

    def get_vulnerability(self, osv_id: str) -> dict:
        self.detail_calls.append(osv_id)
        if self.error is not None:
            raise self.error
        return self.vulns[osv_id]


def _as_response(response: Any) -> HttpResponse:
    if isinstance(response, HttpResponse):
        return response
    if isinstance(response, str):
        return HttpResponse(200, response)
    return HttpResponse(200, json.dumps(response))
