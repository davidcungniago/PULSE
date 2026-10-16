import json

import pytest

from app.services.http_client import HttpResponse, HttpTransportError
from app.services.osv_client import OSV_BATCH_LIMIT, OsvClient, PackageQuery
from app.services.scan_errors import OsvUnreachable


class EmptyBatchHttp:
    def __init__(self):
        self.bodies = []

    def post_json(self, url, payload):
        self.bodies.append(payload)
        results = [{"vulns": []} for _ in payload["queries"]]
        return HttpResponse(200, json.dumps({"results": results}))

    def get(self, url, *, max_bytes=None):
        raise AssertionError("GET not expected")


class PagedHttp:
    def __init__(self):
        self.bodies = []

    def post_json(self, url, payload):
        self.bodies.append(payload)
        if len(self.bodies) == 1:
            return HttpResponse(
                200,
                json.dumps({"results": [{"vulns": [{"id": "OSV-1"}], "next_page_token": "TOKEN"}]}),
            )
        return HttpResponse(200, json.dumps({"results": [{"vulns": [{"id": "OSV-2"}]}]}))

    def get(self, url, *, max_bytes=None):
        raise AssertionError("GET not expected")


class VulnHttp:
    def __init__(self, response):
        self.response = response
        self.get_urls = []

    def post_json(self, url, payload):
        raise AssertionError("POST not expected")

    def get(self, url, *, max_bytes=None):
        self.get_urls.append(url)
        if isinstance(self.response, Exception):
            raise self.response
        return self.response


def test_batches_queries_above_limit():
    http = EmptyBatchHttp()
    client = OsvClient(http, base_url="https://api.osv.dev")
    queries = [PackageQuery(f"pkg-{index}", "npm", "1.0.0") for index in range(OSV_BATCH_LIMIT + 1)]

    result = client.find_vulnerability_ids(queries)

    assert len(result) == OSV_BATCH_LIMIT + 1
    assert [len(body["queries"]) for body in http.bodies] == [OSV_BATCH_LIMIT, 1]


def test_follows_next_page_token():
    http = PagedHttp()
    client = OsvClient(http, base_url="https://api.osv.dev")

    result = client.find_vulnerability_ids([PackageQuery("lodash", "npm", "4.17.20")])

    assert result == [["OSV-1", "OSV-2"]]
    assert http.bodies[0]["queries"][0].get("page_token") is None
    assert http.bodies[1]["queries"][0]["page_token"] == "TOKEN"


def test_caches_vulnerability_details_per_scan():
    payload = {"id": "GHSA-1", "summary": "x"}
    http = VulnHttp(HttpResponse(200, json.dumps(payload)))
    client = OsvClient(http, base_url="https://api.osv.dev")

    first = client.get_vulnerability("GHSA-1")
    second = client.get_vulnerability("GHSA-1")

    assert first == payload
    assert second == payload
    assert http.get_urls == ["https://api.osv.dev/v1/vulns/GHSA-1"]


def test_transport_error_maps_to_osv_unreachable():
    http = VulnHttp(HttpTransportError("timeout"))
    client = OsvClient(http, base_url="https://api.osv.dev")

    with pytest.raises(OsvUnreachable):
        client.get_vulnerability("GHSA-1")


def test_non_200_maps_to_osv_unreachable():
    http = VulnHttp(HttpResponse(500, "boom"))
    client = OsvClient(http, base_url="https://api.osv.dev")

    with pytest.raises(OsvUnreachable):
        client.get_vulnerability("GHSA-1")
