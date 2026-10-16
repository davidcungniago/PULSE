class ScanError(Exception):
    """Base class for scan domain errors."""


class UnsupportedRepositoryHost(ScanError):
    def __init__(self) -> None:
        super().__init__("Pemindaian untuk repositori GitLab belum didukung.")


class RepositoryNotFound(ScanError):
    def __init__(self) -> None:
        super().__init__("Repositori tidak ditemukan atau bersifat privat.")


class NoSupportedManifest(ScanError):
    def __init__(self) -> None:
        super().__init__("Tidak ada manifest yang didukung (requirements.txt / package.json).")


class ManifestTooLarge(ScanError):
    def __init__(self) -> None:
        super().__init__("Berkas manifest terlalu besar (maksimum 1 MB).")


class GitHubUnreachable(ScanError):
    def __init__(self) -> None:
        super().__init__("Layanan GitHub tidak dapat dihubungi. Coba lagi nanti.")


class OsvUnreachable(ScanError):
    def __init__(self) -> None:
        super().__init__("Layanan CVE (OSV.dev) tidak dapat dihubungi. Coba lagi nanti.")
