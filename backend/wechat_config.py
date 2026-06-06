import os

WECHAT_APPID = os.environ.get("WECHAT_APPID", "")
WECHAT_APPSECRET = os.environ.get("WECHAT_APPSECRET", "")
WECHAT_REDIRECT_URI = os.environ.get("WECHAT_REDIRECT_URI", "")
BASE_URL = os.environ.get("BASE_URL", "")


WECHAT_MINI_APPID = os.environ.get("WECHAT_MINI_APPID", "")
WECHAT_MINI_APPSECRET = os.environ.get("WECHAT_MINI_APPSECRET", "")


def is_configured() -> bool:
    return bool(WECHAT_APPID and WECHAT_APPSECRET)


def is_mini_configured() -> bool:
    return bool(WECHAT_MINI_APPID and WECHAT_MINI_APPSECRET)
