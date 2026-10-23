import re
from datetime import datetime, timedelta, timezone

import bcrypt
import jwt


def validate_email(value: str) -> str:
    email = value.strip().lower()
    if not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", email):
        raise ValueError("Masukkan email yang valid.")
    return email


def validate_password(value: str) -> str:
    if len(value) < 6 or len(value.encode()) > 72:
        raise ValueError("Kata sandi minimal 6 karakter dan maksimal 72 byte.")
    return value


def hash_password(value: str) -> str:
    return bcrypt.hashpw(validate_password(value).encode(), bcrypt.gensalt()).decode()


def verify_password(value: str, hashed: str | None) -> bool:
    try:
        return bool(hashed) and bcrypt.checkpw(value.encode(), hashed.encode())
    except (ValueError, TypeError):
        return False


def issue_token(user_id: str, secret: str, minutes: int) -> str:
    now = datetime.now(timezone.utc)
    return jwt.encode(
        {"sub": user_id, "iat": now, "exp": now + timedelta(minutes=minutes)},
        secret,
        algorithm="HS256",
    )


def decode_token(token: str, secret: str) -> str:
    return jwt.decode(
        token, secret, algorithms=["HS256"], options={"require": ["exp", "sub", "iat"]}
    )["sub"]
