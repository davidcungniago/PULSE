from typing import Annotated

from fastapi import Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import get_db
from app.models.user import User

DbSession = Annotated[Session, Depends(get_db)]


def get_current_user(db: DbSession) -> User:
    demo_email = get_settings().demo_email
    user = db.scalar(select(User).where(User.email == demo_email))
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Data awal belum dibuat. Jalankan seed terlebih dahulu.",
        )
    return user


CurrentUser = Annotated[User, Depends(get_current_user)]
