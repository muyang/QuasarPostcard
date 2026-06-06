import hashlib
import secrets
import time
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, HTTPException, Depends
from sqlalchemy.orm import Session
from jose import jwt

from database import get_db
from models import AppUser
from schemas import WechatLoginRequest, WechatLoginResponse, MiniProgramLoginRequest
from wechat_config import WECHAT_APPID, WECHAT_APPSECRET, WECHAT_REDIRECT_URI, is_configured
from wechat_config import WECHAT_MINI_APPID, WECHAT_MINI_APPSECRET, is_mini_configured
from wechat_client import exchange_code, get_userinfo, get_jsapi_ticket, jscode2session
from api.auth import SECRET_KEY, ALGORITHM, TOKEN_EXPIRE_DAYS

router = APIRouter(prefix="/api", tags=["wechat"])


@router.get("/auth/wechat/config")
def wechat_config():
    return {
        "appid": WECHAT_APPID,
        "redirect_uri": WECHAT_REDIRECT_URI,
        "configured": is_configured(),
    }


@router.post("/auth/wechat/login")
def wechat_login(data: WechatLoginRequest, db: Session = Depends(get_db)):
    code = data.code
    if not code:
        raise HTTPException(400, "缺少授权码")
    if not is_configured():
        raise HTTPException(400, "微信登录未配置")

    token_data = exchange_code(WECHAT_APPID, WECHAT_APPSECRET, code)
    if "errcode" in token_data and token_data.get("errcode") != 0:
        raise HTTPException(400, f"微信授权失败: {token_data.get('errmsg', '')}")

    openid = token_data.get("openid", "")
    if not openid:
        raise HTTPException(400, "获取微信openid失败")

    oauth_token = token_data.get("access_token", "")

    # Get or create user
    user = db.query(AppUser).filter(AppUser.openid == openid).first()
    userinfo = get_userinfo(oauth_token, openid) if oauth_token else {}

    if not user:
        user = AppUser(
            openid=openid,
            unionid=token_data.get("unionid"),
            nickname=userinfo.get("nickname", ""),
            avatar_url=userinfo.get("headimgurl", ""),
        )
        db.add(user)
    else:
        if userinfo:
            user.nickname = userinfo.get("nickname", user.nickname)
            user.avatar_url = userinfo.get("headimgurl", user.avatar_url)
        user.last_login_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(user)

    expire = datetime.now(timezone.utc) + timedelta(days=TOKEN_EXPIRE_DAYS)
    token = jwt.encode(
        {"sub": openid, "type": "wechat", "user_id": user.id, "exp": expire},
        SECRET_KEY, algorithm=ALGORITHM,
    )
    return {
        "success": True,
        "token": token,
        "nickname": user.nickname,
        "avatar_url": user.avatar_url,
    }


@router.post("/wechat/jsapi-signature")
def jsapi_signature(data: dict):
    """Return signed config for WeChat JS-SDK initialization."""
    url = data.get("url", "")
    if not url:
        raise HTTPException(400, "缺少URL参数")
    if not is_configured():
        raise HTTPException(400, "微信未配置")

    ticket = get_jsapi_ticket(WECHAT_APPID, WECHAT_APPSECRET)
    noncestr = secrets.token_hex(16)
    timestamp = int(time.time())

    raw = f"jsapi_ticket={ticket}&noncestr={noncestr}&timestamp={timestamp}&url={url}"
    signature = hashlib.sha1(raw.encode()).hexdigest()

    return {
        "appId": WECHAT_APPID,
        "timestamp": timestamp,
        "nonceStr": noncestr,
        "signature": signature,
    }


# ======== Mini Program Endpoints ========

@router.get("/auth/wechat/miniprogram/config")
def miniprogram_config():
    return {
        "appid": WECHAT_MINI_APPID,
        "configured": is_mini_configured(),
    }


@router.post("/auth/wechat/miniprogram/login")
def miniprogram_login(data: MiniProgramLoginRequest, db: Session = Depends(get_db)):
    code = data.code
    if not code:
        raise HTTPException(400, "缺少授权码")
    if not is_mini_configured():
        raise HTTPException(400, "小程序登录未配置")

    token_data = jscode2session(WECHAT_MINI_APPID, WECHAT_MINI_APPSECRET, code)
    if "errcode" in token_data and token_data.get("errcode") != 0:
        raise HTTPException(400, f"小程序登录失败: {token_data.get('errmsg', '')}")

    openid = token_data.get("openid", "")
    if not openid:
        raise HTTPException(400, "获取微信openid失败")

    user = db.query(AppUser).filter(AppUser.openid == openid).first()
    if not user:
        user = AppUser(
            openid=openid,
            unionid=token_data.get("unionid"),
            nickname=data.nickname or "",
            avatar_url=data.avatar_url or "",
        )
        db.add(user)
    else:
        if data.nickname:
            user.nickname = data.nickname
        if data.avatar_url:
            user.avatar_url = data.avatar_url
        user.last_login_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(user)

    expire = datetime.now(timezone.utc) + timedelta(days=TOKEN_EXPIRE_DAYS)
    token = jwt.encode(
        {"sub": openid, "type": "wechat", "user_id": user.id, "exp": expire},
        SECRET_KEY, algorithm=ALGORITHM,
    )
    return {
        "success": True,
        "token": token,
        "nickname": user.nickname,
        "avatar_url": user.avatar_url,
    }
