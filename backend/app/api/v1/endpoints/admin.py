from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Optional
from app.db.session import SessionLocal
from app.api.deps import get_db, get_current_admin
from app.models.collector import Collector
from app.models.recycler import Recycler
from app.models.transaction import Transaction
from app.models.admin import Admin
from app.core.security import verify_password, hash_password
from pydantic import BaseModel

router = APIRouter()

@router.get("/run_seed")
def run_seed():
    from app.db.seed import seed
    try:
        seed()
        return {"status": "success"}
    except Exception as e:
        import traceback
        return {"status": "error", "message": str(e), "traceback": traceback.format_exc()}


class RecyclerStatusUpdate(BaseModel):
    auth_status: str

class ApprovalAction(BaseModel):
    rejection_reason: Optional[str] = None

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

@router.get("/metrics")
def get_platform_metrics(db: Session = Depends(get_db), admin_payload=Depends(get_current_admin)):
    total_transactions = db.query(func.count(Transaction.transaction_id)).scalar() or 0
    active_recyclers = db.query(func.count(Recycler.recycler_id)).filter(Recycler.auth_status == "Active").scalar() or 0
    collector_count = db.query(func.count(Collector.collector_id)).scalar() or 0
    total_weight = db.query(func.sum(Transaction.quantity_weight)).scalar() or 0.0
    pending_recyclers = db.query(func.count(Recycler.recycler_id)).filter(Recycler.approval_status == "pending").scalar() or 0

    return {
        "total_transactions": total_transactions,
        "active_recyclers": active_recyclers,
        "collector_count": collector_count,
        "total_weight_processed": float(total_weight),
        "pending_recyclers": pending_recyclers,
    }

@router.get("/recyclers")
def get_recyclers(db: Session = Depends(get_db), admin_payload=Depends(get_current_admin)):
    recyclers = db.query(Recycler).filter(Recycler.approval_status == "approved").all()
    return [
        {
            "recycler_id": str(r.recycler_id),
            "name": r.name,
            "email": r.email,
            "facility_address": r.facility_address,
            "district": r.facility_address,
            "auth_status": r.auth_status,
        }
        for r in recyclers
    ]

@router.get("/recyclers/pending")
def get_pending_recyclers(db: Session = Depends(get_db), admin_payload=Depends(get_current_admin)):
    """List all recyclers awaiting admin approval."""
    pending = db.query(Recycler).filter(Recycler.approval_status == "pending").all()
    return [
        {
            "recycler_id": str(r.recycler_id),
            "name": r.name,
            "email": r.email,
            "facility_address": r.facility_address,
            "materials_accepted": r.materials_accepted,
            "auth_number": r.auth_number,
            "contact_phone": r.contact_phone,
            "shop_image_url": r.shop_image_url,
            "shop_latitude": float(r.shop_latitude) if r.shop_latitude else None,
            "shop_longitude": float(r.shop_longitude) if r.shop_longitude else None,
            "pickup_available": r.pickup_available,
            "service_radius_km": r.service_radius_km,
        }
        for r in pending
    ]

@router.patch("/recyclers/{recycler_id}/approve")
def approve_recycler(
    recycler_id: str,
    db: Session = Depends(get_db),
    admin_payload=Depends(get_current_admin)
):
    recycler = db.query(Recycler).filter(Recycler.recycler_id == recycler_id).first()
    if not recycler:
        raise HTTPException(status_code=404, detail="Recycler not found")
    recycler.approval_status = "approved"
    recycler.verified_by_admin = True
    recycler.rejection_reason = None
    db.commit()
    return {"message": f"{recycler.name} approved successfully"}

@router.patch("/recyclers/{recycler_id}/reject")
def reject_recycler(
    recycler_id: str,
    action: ApprovalAction,
    db: Session = Depends(get_db),
    admin_payload=Depends(get_current_admin)
):
    recycler = db.query(Recycler).filter(Recycler.recycler_id == recycler_id).first()
    if not recycler:
        raise HTTPException(status_code=404, detail="Recycler not found")
    recycler.approval_status = "rejected"
    recycler.rejection_reason = action.rejection_reason
    db.commit()
    return {"message": f"{recycler.name} rejected"}

@router.patch("/recyclers/{recycler_id}/status")
def update_recycler_status(
    recycler_id: str,
    status_update: RecyclerStatusUpdate,
    db: Session = Depends(get_db),
    admin_payload=Depends(get_current_admin)
):
    recycler = db.query(Recycler).filter(Recycler.recycler_id == recycler_id).first()
    if not recycler:
        raise HTTPException(status_code=404, detail="Recycler not found")
    if status_update.auth_status not in ["Active", "Suspended"]:
        raise HTTPException(status_code=400, detail="Invalid status")
    recycler.auth_status = status_update.auth_status
    db.commit()
    db.refresh(recycler)
    return {"message": "Status updated successfully", "auth_status": recycler.auth_status}

@router.get("/transactions")
def get_recent_transactions(limit: int = 50, db: Session = Depends(get_db), admin_payload=Depends(get_current_admin)):
    transactions = db.query(Transaction).order_by(Transaction.collection_datetime.desc()).limit(limit).all()
    return transactions

@router.patch("/change-password")
def change_admin_password(
    req: ChangePasswordRequest,
    db: Session = Depends(get_db),
    admin_payload=Depends(get_current_admin)
):
    admin = db.query(Admin).filter(Admin.admin_id == admin_payload["sub"]).first()
    if not admin:
        raise HTTPException(status_code=404, detail="Admin not found")
    if not verify_password(req.current_password, admin.password_hash):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    admin.password_hash = hash_password(req.new_password)
    db.commit()
    return {"message": "Password changed successfully"}

@router.get("/collectors")
def get_collectors(db: Session = Depends(get_db), admin_payload=Depends(get_current_admin)):
    collectors = db.query(Collector).all()
    return [
        {
            "collector_id": str(c.collector_id),
            "display_name": c.display_name,
            "operating_district": c.operating_district,
            "operating_state": c.operating_state,
            "registration_date": str(c.registration_date) if c.registration_date else None,
            "total_transactions": c.total_transactions,
            "total_earnings": float(c.total_earnings) if c.total_earnings else 0.0,
        }
        for c in collectors
    ]
