from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Text, DateTime
from database import Base


class AdminUser(Base):
    __tablename__ = "admin_users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(64), unique=True, nullable=False)
    password_hash = Column(String(256), nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class AppUser(Base):
    __tablename__ = "app_users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    openid = Column(String(128), unique=True, nullable=False, index=True)
    unionid = Column(String(128), nullable=True)
    nickname = Column(String(128), nullable=True)
    avatar_url = Column(String(512), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    last_login_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class Postcard(Base):
    __tablename__ = "postcards"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, nullable=True, index=True)
    template_id = Column(String(32), nullable=False, default="floral")
    theme_color = Column(String(16), nullable=False, default="FFE91E63")
    to_name = Column(String(128), default="")
    from_name = Column(String(128), default="")
    message = Column(Text, default="")
    stamp_id = Column(String(32), nullable=True)
    postmark_id = Column(String(32), nullable=True)
    image_url = Column(String(512), nullable=True)
    status = Column(String(32), default="PENDING")
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class PostcardTemplate(Base):
    __tablename__ = "templates"
    id = Column(String(32), primary_key=True)
    name = Column(String(64), nullable=False)
    template_group = Column(String(64), default="默认")
    gradient_from = Column(String(16), nullable=False, default="FFF0F5")
    gradient_to = Column(String(16), nullable=False, default="FFC0CB")
    gradient_mid = Column(String(16), nullable=True)
    corner_radius = Column(Integer, default=8)
    pattern = Column(String(32), nullable=True)
    image_url = Column(String(512), nullable=True)
    image_fit = Column(String(16), default="cover")
    status = Column(String(32), nullable=False, default="draft")
    # Text styling
    from_font = Column(String(64), default="sans-serif")
    to_font = Column(String(64), default="sans-serif")
    message_font = Column(String(64), default="sans-serif")
    from_color = Column(String(16), default="333333")
    to_color = Column(String(16), default="333333")
    message_color = Column(String(16), default="555555")
    from_size = Column(Integer, default=14)
    to_size = Column(Integer, default=14)
    message_size = Column(Integer, default=13)
    # Text position (percentage 0-100)
    from_x = Column(Integer, default=18)
    from_y = Column(Integer, default=88)
    to_x = Column(Integer, default=60)
    to_y = Column(Integer, default=88)
    message_x = Column(Integer, default=8)
    message_y = Column(Integer, default=40)
    message_w = Column(Integer, default=82)
    message_h = Column(Integer, default=70)
    # Stamp position & transform
    stamp_x = Column(Integer, default=85)
    stamp_y = Column(Integer, default=14)
    stamp_rotation = Column(Integer, default=0)
    stamp_scale = Column(Integer, default=100)
    # Postmark position & transform
    postmark_x = Column(Integer, default=50)
    postmark_y = Column(Integer, default=50)
    postmark_rotation = Column(Integer, default=0)
    postmark_scale = Column(Integer, default=100)
    # From/To box styling
    from_w = Column(Integer, default=120)
    from_h = Column(Integer, default=28)
    to_w = Column(Integer, default=120)
    to_h = Column(Integer, default=28)
    from_border_color = Column(String(16), default="CCCCCC")
    to_border_color = Column(String(16), default="CCCCCC")
    from_border_width = Column(Integer, default=0)
    to_border_width = Column(Integer, default=0)
    from_bg_color = Column(String(16), default="FFFFFF")
    to_bg_color = Column(String(16), default="FFFFFF")
    from_bg_opacity = Column(Integer, default=0)
    to_bg_opacity = Column(Integer, default=0)


class PostcardStamp(Base):
    __tablename__ = "stamps"
    id = Column(String(32), primary_key=True)
    emoji = Column(String(8), nullable=False)
    label = Column(String(64), nullable=False)
    accent_color = Column(String(16), nullable=False, default="FFB7C5")
    image_url = Column(String(512), nullable=True)
    status = Column(String(32), nullable=False, default="draft")


class PostcardPostmark(Base):
    __tablename__ = "postmarks"
    id = Column(String(32), primary_key=True)
    label = Column(String(64), nullable=False)
    date_text = Column(String(32), nullable=False, default="2026.05.13")
    color = Column(String(16), nullable=False, default="333333")
    image_url = Column(String(512), nullable=True)
    status = Column(String(32), nullable=False, default="draft")
