import json
from dataclasses import dataclass
from typing import Any

from app.services.http_client import HttpClient, HttpTransportError
from app.services.scan_errors import OsvUnreachable

OSV_BATCH_LIMIT = 1000


@dataclass(frozen=True)
class PackageQuery:
    name: str
    ecosystem: str
    version: str


class OsvClient:
    def __init__(self, http: HttpClient, base_url: str) -> None:
        self._http = http
        self._base_url = base_url.rstrip("/")
        self._cache: dict[str, dict] = {}

    def find_vulnerability_ids(self, queries: list[PackageQuery]) -> list[list[str]]:
        ids_per_query: list[list[str]] = []
        for start in range(0, len(queries), OSV_BATCH_LIMIT):
            chunk = queries[start : start + OSV_BATCH_LIMIT]
            ids_per_query.extend(self._query_chunk(chunk))
        return ids_per_query

    def get_vulnerability(self, osv_id: str) -> dict:
        cached = self._cache.get(osv_id)
        if cached is not None:
            return cached
        payload = self._get_json(f"/v1/vulns/{osv_id}")
        self._cache[osv_id] = payload
        return payload

    def _query_chunk(self, chunk: list[PackageQuery]) -> list[list[str]]:
        ids_per_query: list[list[str]] = [[] for _ in chunk]
        pending_tokens: dict[int, str | None] = {index: None for index in range(len(chunk))}

        while pending_tokens:
            active = list(pending_tokens)
            body_queries: list[dict[str, Any]] = []
            for index in active:
                query = chunk[index]
                item: dict[str, Any] = {
                    "package": {"name": query.name, "ecosystem": query.ecosystem},
                    "version": query.version,
                }
                token = pending_tokens[index]
                if token:
                    item["page_token"] = token
                body_queries.append(item)

            payload = self._post_json("/v1/querybatch", {"queries": body_queries})
            results = payload.get("results")
            if not isinstance(results, list):
                raise OsvUnreachable()

            next_tokens: dict[int, str | None] = {}
            for position, index in enumerate(active):
                if position >= len(results):
                    break
                result = results[position]
                if not isinstance(result, dict):
                    continue
                vulns = result.get("vulns")
                if isinstance(vulns, list):
                    for vuln in vulns:
                        if isinstance(vuln, dict) and isinstance(vuln.get("id"), str):
                            ids_per_query[index].append(vuln["id"])
                token = result.get("next_page_token")
                if isinstance(token, str) and token:
                    next_tokens[index] = token
            pending_tokens = next_tokens

        return ids_per_query

    def _post_json(self, path: str, body: dict[str, Any]) -> dict:
        try:
            response = self._http.post_json(f"{self._base_url}{path}", body)
        except HttpTransportError as exc:
            raise OsvUnreachable() from exc
        if response.status_code != 200:
            raise OsvUnreachable()
        return _parse(response.text)

    def _get_json(self, path: str) -> dict:
        try:
            response = self._http.get(f"{self._base_url}{path}")
        except HttpTransportError as exc:
            raise OsvUnreachable() from exc
        if response.status_code != 200:
            raise OsvUnreachable()
        return _parse(response.text)


def _parse(text: str) -> dict:
    try:
        payload = json.loads(text)
    except json.JSONDecodeError as exc:
        raise OsvUnreachable() from exc
    if not isinstance(payload, dict):
        raise OsvUnreachable()
    return payload
