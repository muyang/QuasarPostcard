from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Text, DateTime
from database import Base


class AdminUser(Base):
    __tablename__ = "admin_users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    username = Column(String(64), unique=True, nullable=False)
    password_hash = Column(String(256), nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class Postcard(Base):
    __tablename__ = "postcards"

    id = Column(Integer, primary_key=True, autoincrement=True)
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
    gradient_from = Column(String(16), nullable=False, default="FFF0F5")
    gradient_to = Column(String(16), nullable=False, default="FFC0CB")
    gradient_mid = Column(String(16), nullable=True)
    corner_radius = Column(Integer, default=8)
    pattern = Column(String(32), nullable=True)
    image_url = Column(String(512), nullable=True)
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
    from_x = Column(Integer, default=10)
    from_y = Column(Integer, default=82)
    to_x = Column(Integer, default=55)
    to_y = Column(Integer, default=82)
    message_x = Column(Integer, default=10)
    message_y = Column(Integer, default=60)
    message_w = Column(Integer, default=80)
    # Stamp position & transform
    stamp_x = Column(Integer, default=78)
    stamp_y = Column(Integer, default=5)
    stamp_rotation = Column(Integer, default=0)
    stamp_scale = Column(Integer, default=100)
    # Postmark position & transform
    postmark_x = Column(Integer, default=45)
    postmark_y = Column(Integer, default=45)
    postmark_rotation = Column(Integer, default=0)
    postmark_scale = Column(Integer, default=100)


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
