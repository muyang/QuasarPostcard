from datetime import datetime
from typing import Optional
from pydantic import BaseModel


# ======== Auth ========

class LoginRequest(BaseModel):
    username: str = "admin"
    password: str = "postcard2024"

class LoginResponse(BaseModel):
    success: bool
    token: Optional[str] = None
    message: str = ""


# ======== Postcard ========

class PostcardCreate(BaseModel):
    template_id: str = "floral"
    theme_color: str = "FFE91E63"
    to_name: str = ""
    from_name: str = ""
    message: str = ""
    stamp_id: Optional[str] = None
    postmark_id: Optional[str] = None
    image_url: Optional[str] = None
    status: str = "PENDING"


class PostcardUpdate(BaseModel):
    template_id: Optional[str] = None
    theme_color: Optional[str] = None
    to_name: Optional[str] = None
    from_name: Optional[str] = None
    message: Optional[str] = None
    stamp_id: Optional[str] = None
    postmark_id: Optional[str] = None
    image_url: Optional[str] = None
    status: Optional[str] = None


class PostcardResponse(BaseModel):
    id: int
    template_id: str
    theme_color: str
    to_name: str
    from_name: str
    message: str
    stamp_id: Optional[str] = None
    postmark_id: Optional[str] = None
    image_url: Optional[str] = None
    status: str
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PostcardListResponse(BaseModel):
    cards: list[PostcardResponse]
    total: int


# ======== Upload ========

class UploadResponse(BaseModel):
    success: bool
    url: Optional[str] = None
    detail: Optional[str] = None
