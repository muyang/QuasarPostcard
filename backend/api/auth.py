import os
import hashlib
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from jose import jwt, JWTError

from database import get_db
from models import AdminUser, AppUser
from schemas import LoginRequest, LoginResponse

router = APIRouter(prefix="/api/auth", tags=["auth"])
security = HTTPBearer()

SECRET_KEY = os.environ.get("JWT_SECRET", "postcard-designer-secret-2024")
ALGORITHM = "HS256"
TOKEN_EXPIRE_DAYS = 30

ADMIN_USERNAME = "admin"
ADMIN_PASSWORD = "postcard2024"


def _hash_password(password: str) -> str:
    salt = "postcard-salt-2024"
    return hashlib.sha256(f"{salt}:{password}".encode()).hexdigest()


def create_default_admin(db: Session):
    admin = db.query(AdminUser).filter(AdminUser.username == ADMIN_USERNAME).first()
    if not admin:
        admin = AdminUser(
            username=ADMIN_USERNAME,
            password_hash=_hash_password(ADMIN_PASSWORD),
        )
        db.add(admin)
        db.commit()


def verify_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Accept any valid token (admin or wechat user)."""
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        sub = payload.get("sub")
        if sub is None:
            raise HTTPException(status_code=401, detail="无效的认证令牌")
        return {
            "sub": sub,
            "type": payload.get("type", "admin"),
            "user_id": payload.get("user_id"),
        }
    except JWTError:
        raise HTTPException(status_code=401, detail="无效的认证令牌")


def verify_admin(credentials: HTTPAuthorizationCredentials = Depends(security), db: Session = Depends(get_db)):
    """Require admin-type token."""
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        user_type = payload.get("type", "admin")
        if username is None or user_type != "admin":
            raise HTTPException(status_code=401, detail="需要管理员权限")
    except JWTError:
        raise HTTPException(status_code=401, detail="无效的认证令牌")
    return username


@router.post("/login", response_model=LoginResponse)
def login(request: LoginRequest, db: Session = Depends(get_db)):
    create_default_admin(db)

    admin = db.query(AdminUser).filter(AdminUser.username == request.username).first()
    if not admin or admin.password_hash != _hash_password(request.password):
        return LoginResponse(success=False, message="用户名或密码错误")

    expire = datetime.now(timezone.utc) + timedelta(days=TOKEN_EXPIRE_DAYS)
    token = jwt.encode(
        {"sub": admin.username, "type": "admin", "exp": expire},
        SECRET_KEY,
        algorithm=ALGORITHM,
    )
    return LoginResponse(success=True, token=token, message="登录成功")


@router.get("/me")
def get_current_user(user=Depends(verify_user), db: Session = Depends(get_db)):
    """Validate token and return current user info."""
    if user["type"] == "wechat":
        app_user = db.query(AppUser).filter(AppUser.id == user.get("user_id")).first()
        return {
            "authenticated": True,
            "type": "wechat",
            "nickname": app_user.nickname if app_user else None,
            "avatar_url": app_user.avatar_url if app_user else None,
        }
    return {
        "authenticated": True,
        "type": "admin",
        "username": user["sub"],
    }
