from jose import jwt
from passlib.context import CryptContext
from datetime import datetime, timedelta, timezone
from app.core.config import settings
import hashlib

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_phone(phone: str) -> str:
    return hashlib.sha256(phone.encode()).hexdigest()

def hash_pin(pin: str) -> str:
    return pwd_context.hash(pin)

def verify_pin(pin: str, hashed: str) -> bool:
    return pwd_context.verify(pin, hashed)

def hash_password(password: str) -> str:
    """Hash a plain-text password (for admin and recycler accounts)."""
    return pwd_context.hash(password)

def verify_password(password: str, hashed: str) -> bool:
    """Verify a plain-text password against its bcrypt hash."""
    return pwd_context.verify(password, hashed)

def create_access_token(collector_id: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=7)
    return jwt.encode(
        {"sub": str(collector_id), "exp": expire},
        settings.SECRET_KEY,
        algorithm="HS256"
    )

def create_role_access_token(user_id: str, role: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(days=7)
    return jwt.encode(
        {"sub": str(user_id), "role": role, "exp": expire},
        settings.SECRET_KEY,
        algorithm="HS256"
    )
