import os
import re
import sys
import time
from urllib.parse import urlencode
from urllib.request import urlopen

UPDATE_ENDPOINT = "https://www.duckdns.org/update"
UPDATE_INTERVAL_SECONDS = 300


def update_dns(domain: str, token: str, opener=urlopen) -> bool:
    if not re.fullmatch(r"[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.duckdns\.org", domain):
        raise ValueError("PULSE_DOMAIN harus berupa subdomain DuckDNS.")
    if not token:
        raise ValueError("DUCKDNS_TOKEN belum tersedia.")

    subdomain = domain.removesuffix(".duckdns.org")
    url = f"{UPDATE_ENDPOINT}?{urlencode({'domains': subdomain, 'token': token})}"
    with opener(url, timeout=10) as response:
        return response.read(16).strip() == b"OK"


def main() -> int:
    domain = os.environ.get("PULSE_DOMAIN", "")
    token = os.environ.get("DUCKDNS_TOKEN", "")
    once = "--once" in sys.argv[1:]

    while True:
        try:
            if update_dns(domain, token):
                print("Pembaruan DuckDNS berhasil.", flush=True)
            else:
                print("Pembaruan DuckDNS ditolak.", flush=True)
                if once:
                    return 1
        except (OSError, ValueError):
            print(
                "Pembaruan DuckDNS gagal. Periksa konfigurasi dan koneksi.", flush=True
            )
            if once:
                return 1

        if once:
            return 0
        time.sleep(UPDATE_INTERVAL_SECONDS)


if __name__ == "__main__":
    raise SystemExit(main())
