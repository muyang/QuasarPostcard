from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from database import get_db
from models import PostcardTemplate, PostcardStamp, PostcardPostmark
from api.auth import verify_admin, verify_user

router = APIRouter(prefix="/api/materials", tags=["materials"])

NO_CACHE = {"Cache-Control": "no-store, no-cache, must-revalidate, max-age=0"}


def _template_dict(r):
    return {
        "id": r.id, "name": r.name, "template_group": getattr(r, 'template_group', '默认') or '默认',
        "gradient_from": r.gradient_from, "gradient_to": r.gradient_to, "gradient_mid": r.gradient_mid,
        "corner_radius": r.corner_radius, "pattern": r.pattern, "image_url": r.image_url, "status": r.status,
        "from_font": r.from_font, "to_font": r.to_font, "message_font": r.message_font,
        "from_color": r.from_color, "to_color": r.to_color, "message_color": r.message_color,
        "from_size": r.from_size, "to_size": r.to_size, "message_size": r.message_size,
        "from_x": r.from_x, "from_y": r.from_y, "to_x": r.to_x, "to_y": r.to_y,
        "message_x": r.message_x, "message_y": r.message_y, "message_w": r.message_w, "message_h": r.message_h,
        "stamp_x": r.stamp_x, "stamp_y": r.stamp_y, "stamp_rotation": r.stamp_rotation, "stamp_scale": r.stamp_scale,
        "postmark_x": r.postmark_x, "postmark_y": r.postmark_y, "postmark_rotation": r.postmark_rotation, "postmark_scale": r.postmark_scale,
        "from_w": r.from_w, "from_h": r.from_h, "to_w": r.to_w, "to_h": r.to_h,
        "from_border_color": r.from_border_color, "to_border_color": r.to_border_color,
        "from_border_width": r.from_border_width, "to_border_width": r.to_border_width,
        "from_bg_color": r.from_bg_color, "to_bg_color": r.to_bg_color,
        "from_bg_opacity": r.from_bg_opacity, "to_bg_opacity": r.to_bg_opacity,
    }

def _stamp_dict(r):
    return {"id": r.id, "emoji": r.emoji, "label": r.label, "accent_color": r.accent_color, "image_url": r.image_url, "status": r.status}

def _postmark_dict(r):
    return {"id": r.id, "label": r.label, "date_text": r.date_text, "color": r.color, "image_url": r.image_url, "status": r.status}


# ======== Templates ========

TEMPLATE_FIELDS = [
    "name", "template_group", "gradient_from", "gradient_to", "gradient_mid", "corner_radius", "pattern",
    "image_url", "status",
    "from_font", "to_font", "message_font", "from_color", "to_color", "message_color",
    "from_size", "to_size", "message_size", "from_x", "from_y", "to_x", "to_y",
    "message_x", "message_y", "message_w", "message_h",
    "stamp_x", "stamp_y", "stamp_rotation", "stamp_scale",
    "postmark_x", "postmark_y", "postmark_rotation", "postmark_scale",
    "from_w", "from_h", "to_w", "to_h",
    "from_border_color", "to_border_color", "from_border_width", "to_border_width",
    "from_bg_color", "to_bg_color", "from_bg_opacity", "to_bg_opacity",
]

@router.get("/templates")
def list_templates(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=2000),
    status: str = Query(""),
    search: str = Query(""),
    group: str = Query(""),
    db: Session = Depends(get_db),
    _: dict = Depends(verify_user),
):
    q = db.query(PostcardTemplate)
    if status:
        statuses = [s.strip() for s in status.split(",") if s.strip()]
        if statuses:
            q = q.filter(PostcardTemplate.status.in_(statuses))
    if search:
        q = q.filter(PostcardTemplate.name.ilike(f"%{search}%"))
    if group:
        q = q.filter(PostcardTemplate.template_group == group)
    total = q.count()
    rows = q.offset(skip).limit(limit).all()
    return JSONResponse(content={"items": [_template_dict(r) for r in rows], "total": total}, headers=NO_CACHE)


@router.get("/templates/{tid}")
def get_template(tid: str, db: Session = Depends(get_db), _: dict = Depends(verify_user)):
    t = db.query(PostcardTemplate).filter(PostcardTemplate.id == tid).first()
    if not t: raise HTTPException(404)
    return JSONResponse(content=_template_dict(t), headers=NO_CACHE)


@router.post("/templates")
def create_template(data: dict, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    t = PostcardTemplate(
        id=data["id"], name=data["name"],
        template_group=data.get("template_group", "默认"),
        gradient_from=data.get("gradient_from", "FFF0F5"),
        gradient_to=data.get("gradient_to", "FFC0CB"),
        gradient_mid=data.get("gradient_mid"),
        corner_radius=data.get("corner_radius", 8),
        pattern=data.get("pattern"),
        image_url=data.get("image_url"),
        status=data.get("status", "published_free"),
    )
    for f in TEMPLATE_FIELDS:
        if f in data:
            setattr(t, f, data[f])
    db.merge(t); db.commit()
    return JSONResponse(content={"success": True}, headers=NO_CACHE)


@router.put("/templates/{tid}")
def update_template(tid: str, data: dict, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    t = db.query(PostcardTemplate).filter(PostcardTemplate.id == tid).first()
    if not t: raise HTTPException(404)
    for k, v in data.items():
        if k != "id":
            setattr(t, k, v)
    db.commit()
    return JSONResponse(content={"success": True}, headers=NO_CACHE)


@router.delete("/templates/{tid}")
def delete_template(tid: str, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    db.query(PostcardTemplate).filter(PostcardTemplate.id == tid).delete()
    db.commit()
    return JSONResponse(content={"success": True}, headers=NO_CACHE)


@router.post("/templates/batch-delete")
def batch_delete_templates(data: dict, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    ids = data.get("ids", [])
    if not ids:
        return JSONResponse(content={"success": False, "message": "未提供ID"}, headers=NO_CACHE)
    deleted = db.query(PostcardTemplate).filter(PostcardTemplate.id.in_(ids)).delete(synchronize_session=False)
    db.commit()
    return JSONResponse(content={"success": True, "deleted": deleted}, headers=NO_CACHE)


# ======== Stamps ========

@router.get("/stamps")
def list_stamps(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=2000),
    status: str = Query(""),
    search: str = Query(""),
    db: Session = Depends(get_db),
    _: dict = Depends(verify_user),
):
    q = db.query(PostcardStamp)
    if status:
        statuses = [s.strip() for s in status.split(",") if s.strip()]
        if statuses:
            q = q.filter(PostcardStamp.status.in_(statuses))
    if search:
        q = q.filter(PostcardStamp.label.ilike(f"%{search}%"))
    total = q.count()
    rows = q.offset(skip).limit(limit).all()
    return JSONResponse(content={"items": [_stamp_dict(r) for r in rows], "total": total}, headers=NO_CACHE)


@router.post("/stamps")
def create_stamp(data: dict, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    s = PostcardStamp(
        id=data["id"], emoji=data["emoji"], label=data["label"],
        accent_color=data.get("accent_color", "FFB7C5"),
        image_url=data.get("image_url"),
        status=data.get("status", "published_free"),
    )
    db.merge(s); db.commit()
    return JSONResponse(content={"success": True}, headers=NO_CACHE)


@router.put("/stamps/{sid}")
def update_stamp(sid: str, data: dict, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    s = db.query(PostcardStamp).filter(PostcardStamp.id == sid).first()
    if not s: raise HTTPException(404)
    for k, v in data.items():
        if k != "id":
            setattr(s, k, v)
    db.commit()
    return JSONResponse(content={"success": True}, headers=NO_CACHE)


@router.delete("/stamps/{sid}")
def delete_stamp(sid: str, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    db.query(PostcardStamp).filter(PostcardStamp.id == sid).delete()
    db.commit()
    return JSONResponse(content={"success": True}, headers=NO_CACHE)


@router.post("/stamps/batch-delete")
def batch_delete_stamps(data: dict, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    ids = data.get("ids", [])
    if not ids:
        return JSONResponse(content={"success": False, "message": "未提供ID"}, headers=NO_CACHE)
    deleted = db.query(PostcardStamp).filter(PostcardStamp.id.in_(ids)).delete(synchronize_session=False)
    db.commit()
    return JSONResponse(content={"success": True, "deleted": deleted}, headers=NO_CACHE)


# ======== Postmarks ========

@router.get("/postmarks")
def list_postmarks(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=2000),
    status: str = Query(""),
    search: str = Query(""),
    db: Session = Depends(get_db),
    _: dict = Depends(verify_user),
):
    q = db.query(PostcardPostmark)
    if status:
        statuses = [s.strip() for s in status.split(",") if s.strip()]
        if statuses:
            q = q.filter(PostcardPostmark.status.in_(statuses))
    if search:
        q = q.filter(PostcardPostmark.label.ilike(f"%{search}%"))
    total = q.count()
    rows = q.offset(skip).limit(limit).all()
    return JSONResponse(content={"items": [_postmark_dict(r) for r in rows], "total": total}, headers=NO_CACHE)


@router.post("/postmarks")
def create_postmark(data: dict, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    p = PostcardPostmark(
        id=data["id"], label=data["label"],
        date_text=data.get("date_text", "2026.05.13"),
        color=data.get("color", "333333"),
        image_url=data.get("image_url"),
        status=data.get("status", "published_free"),
    )
    db.merge(p); db.commit()
    return JSONResponse(content={"success": True}, headers=NO_CACHE)


@router.put("/postmarks/{pid}")
def update_postmark(pid: str, data: dict, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    p = db.query(PostcardPostmark).filter(PostcardPostmark.id == pid).first()
    if not p: raise HTTPException(404)
    for k, v in data.items():
        if k != "id":
            setattr(p, k, v)
    db.commit()
    return JSONResponse(content={"success": True}, headers=NO_CACHE)


@router.delete("/postmarks/{pid}")
def delete_postmark(pid: str, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    db.query(PostcardPostmark).filter(PostcardPostmark.id == pid).delete()
    db.commit()
    return JSONResponse(content={"success": True}, headers=NO_CACHE)


@router.post("/postmarks/batch-delete")
def batch_delete_postmarks(data: dict, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    ids = data.get("ids", [])
    if not ids:
        return JSONResponse(content={"success": False, "message": "未提供ID"}, headers=NO_CACHE)
    deleted = db.query(PostcardPostmark).filter(PostcardPostmark.id.in_(ids)).delete(synchronize_session=False)
    db.commit()
    return JSONResponse(content={"success": True, "deleted": deleted}, headers=NO_CACHE)


# ======== Seed ========

@router.post("/seed")
def seed_defaults(db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    defaults = {
        "templates": [
            {"id": "floral", "name": "花卉", "gradient_from": "FFF0F5", "gradient_to": "FFC0CB", "gradient_mid": "FFE4E1", "corner_radius": 8, "pattern": "floral", "status": "published_free", "from_color": "7B4B6A", "to_color": "7B4B6A", "message_color": "9B6B8A"},
            {"id": "geometric", "name": "几何", "gradient_from": "F0F4FF", "gradient_to": "B8C8E8", "gradient_mid": "E8ECF4", "corner_radius": 8, "pattern": "geometric", "status": "published_free", "from_color": "3A5070", "to_color": "3A5070", "message_color": "4A6080"},
            {"id": "minimalist", "name": "极简", "gradient_from": "FAFAFA", "gradient_to": "EEEEEE", "gradient_mid": "F5F5F5", "corner_radius": 4, "pattern": "minimalist", "status": "published_free", "from_color": "444444", "to_color": "444444", "message_color": "666666"},
            {"id": "vintage", "name": "复古", "gradient_from": "FFF8F0", "gradient_to": "E8D5B7", "gradient_mid": "F5E6D3", "corner_radius": 8, "pattern": "vintage", "status": "published_free", "from_color": "5D4037", "to_color": "5D4037", "message_color": "795548"},
            {"id": "nature", "name": "自然", "gradient_from": "F0FFF0", "gradient_to": "C8E6C9", "gradient_mid": "E8F5E9", "corner_radius": 8, "pattern": "nature", "status": "published_free", "from_color": "2E5D3A", "to_color": "2E5D3A", "message_color": "3E6D4A"},
            {"id": "ocean", "name": "海洋", "gradient_from": "F0F8FF", "gradient_to": "BBDEFB", "gradient_mid": "E3F2FD", "corner_radius": 8, "pattern": "ocean", "status": "published_free", "from_color": "1A3A5C", "to_color": "1A3A5C", "message_color": "2A4A6C"},
        ],
        "stamps": [
            {"id": "flower", "emoji": "🌸", "label": "樱花", "accent_color": "FFB7C5", "status": "published_free"},
            {"id": "rose", "emoji": "🌹", "label": "玫瑰", "accent_color": "E91E63", "status": "published_free"},
            {"id": "sunflower", "emoji": "🌻", "label": "向日葵", "accent_color": "FFD700", "status": "published_free"},
            {"id": "tulip", "emoji": "🌷", "label": "郁金香", "accent_color": "FF6B6B", "status": "published_free"},
            {"id": "maple", "emoji": "🍁", "label": "枫叶", "accent_color": "D2691E", "status": "published_free"},
            {"id": "bird", "emoji": "🕊️", "label": "白鸽", "accent_color": "B0C4DE", "status": "published_free"},
            {"id": "butterfly", "emoji": "🦋", "label": "蝴蝶", "accent_color": "87CEEB", "status": "published_free"},
            {"id": "heart", "emoji": "💝", "label": "爱心", "accent_color": "FF69B4", "status": "published_free"},
            {"id": "star", "emoji": "⭐", "label": "星辰", "accent_color": "FFD700", "status": "published_free"},
            {"id": "clover", "emoji": "🍀", "label": "四叶草", "accent_color": "90EE90", "status": "published_free"},
            {"id": "snow", "emoji": "❄️", "label": "雪花", "accent_color": "B0E0E6", "status": "published_free"},
            {"id": "moon", "emoji": "🌙", "label": "月亮", "accent_color": "C0C0FF", "status": "published_free"},
        ],
        "postmarks": [
            {"id": "classic", "label": "经典圆形", "date_text": "2026.05.13", "color": "333333", "status": "published_free"},
            {"id": "red", "label": "红色邮戳", "date_text": "2026.05.13", "color": "C62828", "status": "published_free"},
            {"id": "blue", "label": "蓝色邮戳", "date_text": "2026.05.13", "color": "1565C0", "status": "published_free"},
            {"id": "gold", "label": "金色纪念", "date_text": "2026.05.13", "color": "FF8F00", "status": "published_free"},
            {"id": "vintage_sepia", "label": "复古棕", "date_text": "2026.05.13", "color": "795548", "status": "published_free"},
        ],
    }
    for t in defaults["templates"]:
        db.merge(PostcardTemplate(**t))
    for s in defaults["stamps"]:
        db.merge(PostcardStamp(**s))
    for p in defaults["postmarks"]:
        db.merge(PostcardPostmark(**p))
    db.commit()
    return JSONResponse(content={"success": True, "message": f"已初始化 {len(defaults['templates'])} 模版, {len(defaults['stamps'])} 邮票, {len(defaults['postmarks'])} 邮戳"}, headers=NO_CACHE)
