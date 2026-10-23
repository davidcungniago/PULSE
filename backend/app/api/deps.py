from collections.abc import Iterator
from typing import Annotated

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import get_db
from app.models.user import User
from app.services.auth_service import decode_token
from app.services.http_client import HttpClient, HttpxClient
from app.services.manifest_fetcher import GitHubManifestFetcher
from app.services.osv_client import OsvClient

DbSession = Annotated[Session, Depends(get_db)]


bearer = HTTPBearer(auto_error=False)


def get_current_user(
    db: DbSession, credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)]
) -> User:
    if credentials is None or len(get_settings().jwt_secret) < 32:
        raise HTTPException(401, "Masuk untuk melanjutkan.")
    try:
        user_id = decode_token(credentials.credentials, get_settings().jwt_secret)
    except jwt.InvalidTokenError as exc:
        raise HTTPException(401, "Sesi berakhir. Masuk kembali.") from exc
    user = db.scalar(select(User).where(User.id == user_id))
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesi tidak valid. Masuk kembali.",
        )
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]


def get_http_client() -> Iterator[HttpClient]:
    settings = get_settings()
    client = HttpxClient(timeout=settings.scan_http_timeout_seconds)
    try:
        yield client
    finally:
        client.close()


HttpClientDep = Annotated[HttpClient, Depends(get_http_client)]


def get_manifest_fetcher(http: HttpClientDep) -> GitHubManifestFetcher:
    settings = get_settings()
    return GitHubManifestFetcher(
        http,
        raw_base_url=settings.github_raw_base_url,
        api_base_url=settings.github_api_base_url,
        max_bytes=settings.manifest_max_bytes,
    )


def get_osv_client(http: HttpClientDep) -> OsvClient:
    return OsvClient(http, base_url=get_settings().osv_base_url)


ManifestFetcherDep = Annotated[GitHubManifestFetcher, Depends(get_manifest_fetcher)]
OsvClientDep = Annotated[OsvClient, Depends(get_osv_client)]


def get_mail_client():
    from app.services.notification_service import SmtpMailClient

    return SmtpMailClient(get_settings())
