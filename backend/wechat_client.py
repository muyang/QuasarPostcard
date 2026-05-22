import time
import requests

_jsapi_ticket = None
_jsapi_ticket_expires_at = 0


def exchange_code(appid: str, secret: str, code: str) -> dict:
    """Exchange OAuth authorization code for access_token + openid."""
    resp = requests.get(
        "https://api.weixin.qq.com/sns/oauth2/access_token",
        params={
            "appid": appid, "secret": secret,
            "code": code, "grant_type": "authorization_code"
        },
        timeout=10
    )
    return resp.json()


def get_userinfo(oauth_access_token: str, openid: str) -> dict:
    """Get WeChat user info (nickname, headimgurl)."""
    resp = requests.get(
        "https://api.weixin.qq.com/sns/userinfo",
        params={"access_token": oauth_access_token, "openid": openid, "lang": "zh_CN"},
        timeout=10
    )
    return resp.json()


def jscode2session(appid: str, secret: str, code: str) -> dict:
    """Exchange mini program wx.login() code for openid + session_key."""
    resp = requests.get(
        "https://api.weixin.qq.com/sns/jscode2session",
        params={
            "appid": appid, "secret": secret,
            "js_code": code, "grant_type": "authorization_code"
        },
        timeout=10
    )
    return resp.json()


def get_jsapi_ticket(appid: str, secret: str) -> str:
    """Get jsapi_ticket for JS-SDK signature. Cached for 7000s."""
    global _jsapi_ticket, _jsapi_ticket_expires_at
    now = time.time()
    if _jsapi_ticket and now < _jsapi_ticket_expires_at:
        return _jsapi_ticket

    # Get global access_token first
    resp = requests.get(
        "https://api.weixin.qq.com/cgi-bin/token",
        params={"grant_type": "client_credential", "appid": appid, "secret": secret},
        timeout=10
    )
    data = resp.json()
    access_token = data["access_token"]

    resp = requests.get(
        "https://api.weixin.qq.com/cgi-bin/ticket/getticket",
        params={"access_token": access_token, "type": "jsapi"},
        timeout=10
    )
    data = resp.json()
    _jsapi_ticket = data["ticket"]
    _jsapi_ticket_expires_at = now + data.get("expires_in", 7200) - 300
    return _jsapi_ticket
