import importlib.util
from pathlib import Path
from unittest import TestCase
from unittest.mock import Mock
from urllib.parse import parse_qs, urlparse

spec = importlib.util.spec_from_file_location(
    "duckdns_updater",
    Path(__file__).resolve().parents[2] / "deploy" / "duckdns_updater.py",
)
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)


class DuckDnsUpdaterTest(TestCase):
    def test_update_uses_https_and_subdomain_without_explicit_ip(self):
        response = Mock()
        response.read.return_value = b"OK\n"
        context = Mock()
        context.__enter__ = Mock(return_value=response)
        context.__exit__ = Mock(return_value=None)
        opener = Mock(return_value=context)

        self.assertTrue(
            updater.update_dns("pulse-demo.duckdns.org", "private-token", opener)
        )

        url = urlparse(opener.call_args.args[0])
        self.assertEqual(url.scheme, "https")
        self.assertEqual(url.netloc, "www.duckdns.org")
        self.assertEqual(
            parse_qs(url.query), {"domains": ["pulse-demo"], "token": ["private-token"]}
        )
        self.assertEqual(opener.call_args.kwargs["timeout"], 10)

    def test_rejected_update_is_reported(self):
        response = Mock()
        response.read.return_value = b"KO"
        context = Mock()
        context.__enter__ = Mock(return_value=response)
        context.__exit__ = Mock(return_value=None)

        self.assertFalse(
            updater.update_dns(
                "pulse-demo.duckdns.org", "private-token", Mock(return_value=context)
            )
        )

    def test_invalid_domain_is_rejected_before_request(self):
        opener = Mock()

        for domain in (
            "example.com",
            ".duckdns.org",
            "BAD.duckdns.org",
            "-bad.duckdns.org",
        ):
            with self.subTest(domain=domain), self.assertRaises(ValueError):
                updater.update_dns(domain, "private-token", opener)

        opener.assert_not_called()

    def test_missing_token_is_rejected_before_request(self):
        opener = Mock()

        with self.assertRaises(ValueError):
            updater.update_dns("pulse-demo.duckdns.org", "", opener)

        opener.assert_not_called()
