import json


def request_log(request_id: str, method: str, route: str, status: int, duration_ms: int) -> str:
    return json.dumps(
        {
            "Event": "http_request",
            "RequestId": request_id,
            "Method": method,
            "Route": route,
            "Status": status,
            "DurationMs": duration_ms,
        },
        separators=(",", ":"),
    )
