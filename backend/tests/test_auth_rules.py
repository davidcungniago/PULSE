from datetime import datetime, timedelta, timezone

import jwt
import pytest

from app.services.auth_service import decode_token, hash_password, issue_token, verify_password

SECRET = "isolated-test-secret-with-at-least-forty-eight-bytes-long"


def test_password_hash_and_wrong_password():
    hashed = hash_password("secure-test")
    assert hashed != "secure-test"
    assert verify_password("secure-test", hashed)
    assert not verify_password("wrong-test", hashed)


def test_jwt_expired_and_tampered():
    assert decode_token(issue_token("user", SECRET, 60), SECRET) == "user"
    with pytest.raises(jwt.ExpiredSignatureError):
        decode_token(issue_token("user", SECRET, -1), SECRET)
    with pytest.raises(jwt.InvalidTokenError):
        decode_token(
            issue_token("user", SECRET, 60), "different-test-secret-with-at-least-32-bytes"
        )
    forged = jwt.encode(
        {
            "sub": "user",
            "iat": datetime.now(timezone.utc),
            "exp": datetime.now(timezone.utc) + timedelta(minutes=1),
        },
        SECRET,
        algorithm="HS384",
    )
    with pytest.raises(jwt.InvalidAlgorithmError):
        decode_token(forged, SECRET)
