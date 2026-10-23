from fastapi import APIRouter, HTTPException
from pydantic import field_validator
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from app.api.deps import DbSession
from app.core.config import get_settings
from app.models.user import User
from app.schemas.base import PascalModel
from app.services.auth_service import (
    hash_password,
    issue_token,
    validate_email,
    validate_password,
    verify_password,
)

router = APIRouter(prefix="/api/auth", tags=["auth"])


class Credentials(PascalModel):
    email: str
    password: str

    _email = field_validator("email")(validate_email)
    _password = field_validator("password")(validate_password)


def session_response(user: User) -> dict:
    settings = get_settings()
    if len(settings.jwt_secret) < 32:
        raise HTTPException(503, "Konfigurasi autentikasi belum tersedia.")
    return {
        "AccessToken": issue_token(user.id, settings.jwt_secret, settings.jwt_expiry_minutes),
        "User": {"Id": user.id, "Email": user.email},
    }


@router.post("/register", status_code=201)
def register(payload: Credentials, db: DbSession):
    if len(get_settings().jwt_secret) < 32:
        raise HTTPException(503, "Konfigurasi autentikasi belum tersedia.")
    user = User(email=payload.email, password_hash=hash_password(payload.password))
    db.add(user)
    try:
        db.commit()
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(409, "Email sudah terdaftar.") from exc
    db.refresh(user)
    return session_response(user)


@router.post("/login")
def login(payload: Credentials, db: DbSession):
    user = db.scalar(select(User).where(User.email == payload.email))
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(401, "Email atau kata sandi salah.")
    return session_response(user)
