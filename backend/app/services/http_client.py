from dataclasses import dataclass
from typing import Any, Protocol

import httpx


class HttpTransportError(Exception):
    """Raised when an HTTP request cannot be completed."""


class ResponseTooLarge(Exception):
    """Raised when a response body exceeds the configured limit."""


@dataclass(frozen=True)
class HttpResponse:
    status_code: int
    text: str


class HttpClient(Protocol):
    def get(self, url: str, *, max_bytes: int | None = None) -> HttpResponse: ...

    def post_json(self, url: str, payload: dict[str, Any]) -> HttpResponse: ...


class HttpxClient:
    def __init__(self, timeout: float) -> None:
        self._client = httpx.Client(timeout=timeout, follow_redirects=True)

    def get(self, url: str, *, max_bytes: int | None = None) -> HttpResponse:
        try:
            with self._client.stream("GET", url) as response:
                if response.status_code != 200:
                    return HttpResponse(response.status_code, "")
                body = bytearray()
                for chunk in response.iter_bytes():
                    body.extend(chunk)
                    if max_bytes is not None and len(body) > max_bytes:
                        raise ResponseTooLarge()
                return HttpResponse(response.status_code, _decode(bytes(body)))
        except httpx.HTTPError as exc:
            raise HttpTransportError(str(exc)) from exc

    def post_json(self, url: str, payload: dict[str, Any]) -> HttpResponse:
        try:
            response = self._client.post(url, json=payload)
        except httpx.HTTPError as exc:
            raise HttpTransportError(str(exc)) from exc
        return HttpResponse(response.status_code, response.text)

    def close(self) -> None:
        self._client.close()


def _decode(data: bytes) -> str:
    return data.decode("utf-8", errors="replace").lstrip("\ufeff")
