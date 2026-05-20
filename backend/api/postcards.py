from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from database import get_db
from models import Postcard
from schemas import PostcardCreate, PostcardUpdate, PostcardResponse, PostcardListResponse
from api.auth import verify_admin

router = APIRouter(prefix="/api/postcards", tags=["postcards"])


def _build_response(card: Postcard) -> dict:
    return {
        "id": card.id,
        "template_id": card.template_id,
        "theme_color": card.theme_color,
        "to_name": card.to_name or "",
        "from_name": card.from_name or "",
        "message": card.message or "",
        "stamp_id": card.stamp_id,
        "postmark_id": card.postmark_id,
        "image_url": card.image_url,
        "status": card.status,
        "created_at": card.created_at,
        "updated_at": card.updated_at,
    }


@router.get("")
def list_postcards(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    status: str = Query("", description="Filter by status"),
    db: Session = Depends(get_db),
    _: str = Depends(verify_admin),
):
    query = db.query(Postcard)
    if status:
        query = query.filter(Postcard.status == status)
    total = query.count()
    cards = query.order_by(Postcard.updated_at.desc()).offset(skip).limit(limit).all()

    return PostcardListResponse(
        cards=[PostcardResponse(**_build_response(c)) for c in cards],
        total=total,
    )


@router.post("", response_model=PostcardResponse)
def create_postcard(
    request: PostcardCreate,
    db: Session = Depends(get_db),
    _: str = Depends(verify_admin),
):
    card = Postcard(
        template_id=request.template_id,
        theme_color=request.theme_color,
        to_name=request.to_name,
        from_name=request.from_name,
        message=request.message,
        stamp_id=request.stamp_id,
        postmark_id=request.postmark_id,
        image_url=request.image_url,
        status=request.status,
    )
    db.add(card)
    db.commit()
    db.refresh(card)
    return PostcardResponse(**_build_response(card))


@router.put("/{card_id}", response_model=PostcardResponse)
def update_postcard(
    card_id: int,
    request: PostcardUpdate,
    db: Session = Depends(get_db),
    _: str = Depends(verify_admin),
):
    card = db.query(Postcard).filter(Postcard.id == card_id).first()
    if not card:
        raise HTTPException(status_code=404, detail="明信片不存在")

    updates = request.model_dump(exclude_unset=True)
    for key, value in updates.items():
        setattr(card, key, value)
    db.commit()
    db.refresh(card)
    return PostcardResponse(**_build_response(card))


@router.delete("/{card_id}")
def delete_postcard(
    card_id: int,
    db: Session = Depends(get_db),
    _: str = Depends(verify_admin),
):
    card = db.query(Postcard).filter(Postcard.id == card_id).first()
    if not card:
        raise HTTPException(status_code=404, detail="明信片不存在")
    db.delete(card)
    db.commit()
    return {"success": True, "message": "已删除"}


@router.post("/batch-delete")
def batch_delete_postcards(data: dict, db: Session = Depends(get_db), _: str = Depends(verify_admin)):
    ids = data.get("ids", [])
    if not ids:
        return {"success": False, "message": "未提供ID"}
    deleted = db.query(Postcard).filter(Postcard.id.in_(ids)).delete(synchronize_session=False)
    db.commit()
    return {"success": True, "deleted": deleted}
