import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

import app.models  # noqa: F401
from app.core.config import get_settings
from app.db.base import Base
from app.db.session import get_db
from app.main import app
from app.models.user import User
from app.services.auth_service import issue_token


@pytest.fixture(autouse=True)
def test_settings(monkeypatch):
    monkeypatch.setenv("JWT_SECRET", "test-only-key-with-at-least-thirty-two-characters")
    monkeypatch.setenv("SMTP_HOST", "")
    get_settings.cache_clear()
    yield
    get_settings.cache_clear()


@pytest.fixture()
def db_session():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(bind=engine)
    testing_session = sessionmaker(bind=engine, autoflush=False, autocommit=False)
    session = testing_session()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(bind=engine)


@pytest.fixture()
def demo_user(db_session):
    user = User(email=get_settings().demo_email, password_hash="hash")
    db_session.add(user)
    db_session.commit()
    db_session.refresh(user)
    return user


@pytest.fixture()
def client(db_session):
    def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        from sqlalchemy import select

        def inject_auth(request):
            user = db_session.scalar(select(User).where(User.email == get_settings().demo_email))
            if user and "authorization" not in request.headers:
                request.headers["Authorization"] = "Bearer " + issue_token(
                    user.id, get_settings().jwt_secret, 60
                )

        test_client.event_hooks["request"].append(inject_auth)
        yield test_client
    app.dependency_overrides.clear()
