from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from database import get_db
from models import PostcardTemplate, PostcardStamp, PostcardPostmark
from api.auth import verify_admin

router = APIRouter(prefix="/api/materials", tags=["materials"])


def _template_dict(r):
    return {"id": r.id, "name": r.name, "gradient_from": r.gradient_from, "gradient_to": r.gradient_to, "gradient_mid": r.gradient_mid, "corner_radius": r.corner_radius, "pattern": r.pattern, "image_url": r.image_url, "status": r.status}

def _stamp_dict(r):
    return {"id": r.id, "emoji": r.emoji, "label": r.label, "accent_color": r.accent_color, "image_url": r.image_url, "status": r.status}

def _postmark_dict(r):
    return {"id": r.id, "label": r.label, "date_text": r.date_text, "color": r.color, "image_url": r.image_url, "status": r.status}


# ======== Templates ========

@router.get("/templates")
def list_templates(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=2000),
    status: str = Query(""),
    search: str = Query(""),
    db: Session = Depends(get_db),
    _: str = Depends(verify_admin),
):
    q = db.query(PostcardTemplate)
    if status:
        statuses = [s.strip() for s in status.split(",") if s.strip()]
        if statuses:
            q = q.filter(PostcardTemplate.status.in_(statuses))
    if search:
        q = q.filter(PostcardTemplate.name.ilike(f"%{search}%"))
    total = q.count()
    rows = q.offset(skip).limit(limit).all()
    return {"items": [_template_dict(r) for r in rows], "total": total}


@router.post("/templates")
def create_template(data: dict, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    t = PostcardTemplate(
        id=data["id"], name=data["name"],
        gradient_from=data.get("gradient_from", "FFF0F5"),
        gradient_to=data.get("gradient_to", "FFC0CB"),
        gradient_mid=data.get("gradient_mid"),
        corner_radius=data.get("corner_radius", 8),
        pattern=data.get("pattern"),
        image_url=data.get("image_url"),
        status=data.get("status", "published_free"),
    )
    db.add(t); db.commit()
    return {"success": True}


@router.put("/templates/{tid}")
def update_template(tid: str, data: dict, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    t = db.query(PostcardTemplate).filter(PostcardTemplate.id == tid).first()
    if not t: raise HTTPException(404)
    for k, v in data.items(): setattr(t, k, v)
    db.commit()
    return {"success": True}


@router.delete("/templates/{tid}")
def delete_template(tid: str, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    db.query(PostcardTemplate).filter(PostcardTemplate.id == tid).delete()
    db.commit()
    return {"success": True}


# ======== Stamps ========

@router.get("/stamps")
def list_stamps(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=2000),
    status: str = Query(""),
    search: str = Query(""),
    db: Session = Depends(get_db),
    _: str = Depends(verify_admin),
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
    return {"items": [_stamp_dict(r) for r in rows], "total": total}


@router.post("/stamps")
def create_stamp(data: dict, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    s = PostcardStamp(
        id=data["id"], emoji=data["emoji"], label=data["label"],
        accent_color=data.get("accent_color", "FFB7C5"),
        image_url=data.get("image_url"),
        status=data.get("status", "published_free"),
    )
    db.add(s); db.commit()
    return {"success": True}


@router.put("/stamps/{sid}")
def update_stamp(sid: str, data: dict, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    s = db.query(PostcardStamp).filter(PostcardStamp.id == sid).first()
    if not s: raise HTTPException(404)
    for k, v in data.items(): setattr(s, k, v)
    db.commit()
    return {"success": True}


@router.delete("/stamps/{sid}")
def delete_stamp(sid: str, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    db.query(PostcardStamp).filter(PostcardStamp.id == sid).delete()
    db.commit()
    return {"success": True}


# ======== Postmarks ========

@router.get("/postmarks")
def list_postmarks(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=2000),
    status: str = Query(""),
    search: str = Query(""),
    db: Session = Depends(get_db),
    _: str = Depends(verify_admin),
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
    return {"items": [_postmark_dict(r) for r in rows], "total": total}


@router.post("/postmarks")
def create_postmark(data: dict, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    p = PostcardPostmark(
        id=data["id"], label=data["label"],
        date_text=data.get("date_text", "2026.05.13"),
        color=data.get("color", "333333"),
        image_url=data.get("image_url"),
        status=data.get("status", "published_free"),
    )
    db.add(p); db.commit()
    return {"success": True}


@router.put("/postmarks/{pid}")
def update_postmark(pid: str, data: dict, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    p = db.query(PostcardPostmark).filter(PostcardPostmark.id == pid).first()
    if not p: raise HTTPException(404)
    for k, v in data.items(): setattr(p, k, v)
    db.commit()
    return {"success": True}


@router.delete("/postmarks/{pid}")
def delete_postmark(pid: str, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    db.query(PostcardPostmark).filter(PostcardPostmark.id == pid).delete()
    db.commit()
    return {"success": True}


# ======== Seed ========

@router.post("/seed")
def seed_defaults(db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    defaults = {
        "templates": [
            {"id": "floral", "name": "花卉", "gradient_from": "FFF0F5", "gradient_to": "FFC0CB", "gradient_mid": "FFE4E1", "corner_radius": 8, "pattern": "floral", "status": "published_free"},
            {"id": "geometric", "name": "几何", "gradient_from": "F0F4FF", "gradient_to": "B8C8E8", "gradient_mid": "E8ECF4", "corner_radius": 8, "pattern": "geometric", "status": "published_free"},
            {"id": "minimalist", "name": "极简", "gradient_from": "FAFAFA", "gradient_to": "EEEEEE", "gradient_mid": "F5F5F5", "corner_radius": 4, "pattern": "minimalist", "status": "published_free"},
            {"id": "vintage", "name": "复古", "gradient_from": "FFF8F0", "gradient_to": "E8D5B7", "gradient_mid": "F5E6D3", "corner_radius": 8, "pattern": "vintage", "status": "published_free"},
            {"id": "nature", "name": "自然", "gradient_from": "F0FFF0", "gradient_to": "C8E6C9", "gradient_mid": "E8F5E9", "corner_radius": 8, "pattern": "nature", "status": "published_free"},
            {"id": "ocean", "name": "海洋", "gradient_from": "F0F8FF", "gradient_to": "BBDEFB", "gradient_mid": "E3F2FD", "corner_radius": 8, "pattern": "ocean", "status": "published_free"},
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
    return {"success": True, "message": f"已初始化 {len(defaults['templates'])} 模版, {len(defaults['stamps'])} 邮票, {len(defaults['postmarks'])} 邮戳"}
