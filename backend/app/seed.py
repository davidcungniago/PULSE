import bcrypt
from sqlalchemy import select

from app.core.config import get_settings
from app.db.session import SessionLocal
from app.models.project import Project
from app.models.user import User
from app.services.asset_service import DuplicateAssetError, create_asset

DEMO_PASSWORD = "demo123"
DEMO_PROJECT_NAME = "Platform Pembayaran"
DEMO_PROJECT_DESCRIPTION = "Layanan backend utama."
DEMO_REPOSITORIES = [
    "https://github.com/expressjs/express",
    "https://github.com/lodash/lodash",
]


def _hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def seed() -> None:
    demo_email = get_settings().demo_email
    db = SessionLocal()
    try:
        user = db.scalar(select(User).where(User.email == demo_email))
        if user is None:
            user = User(email=demo_email, password_hash=_hash_password(DEMO_PASSWORD))
            db.add(user)
            db.flush()

        project = db.scalar(
            select(Project).where(
                Project.user_id == user.id,
                Project.name == DEMO_PROJECT_NAME,
            )
        )
        if project is None:
            project = Project(
                user_id=user.id,
                name=DEMO_PROJECT_NAME,
                description=DEMO_PROJECT_DESCRIPTION,
            )
            db.add(project)
            db.flush()

        for repository_url in DEMO_REPOSITORIES:
            try:
                create_asset(db, project, repository_url)
            except DuplicateAssetError:
                pass

        db.commit()
    finally:
        db.close()


if __name__ == "__main__":
    seed()
