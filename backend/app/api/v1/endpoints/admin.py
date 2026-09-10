from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.db.session import SessionLocal
from app.api.deps import get_db, get_current_admin
from app.models.collector import Collector
from app.models.recycler import Recycler
from app.models.transaction import Transaction
from pydantic import BaseModel

router = APIRouter()

class RecyclerStatusUpdate(BaseModel):
    auth_status: str

@router.get("/metrics")
def get_platform_metrics(db: Session = Depends(get_db), admin_payload=Depends(get_current_admin)):
    total_transactions = db.query(func.count(Transaction.transaction_id)).scalar() or 0
    active_recyclers = db.query(func.count(Recycler.recycler_id)).filter(Recycler.auth_status == "Active").scalar() or 0
    collector_count = db.query(func.count(Collector.collector_id)).scalar() or 0
    total_weight = db.query(func.sum(Transaction.quantity_weight)).scalar() or 0.0

    return {
        "total_transactions": total_transactions,
        "active_recyclers": active_recyclers,
        "collector_count": collector_count,
        "total_weight_processed": total_weight
    }

@router.get("/recyclers")
def get_recyclers(db: Session = Depends(get_db), admin_payload=Depends(get_current_admin)):
    recyclers = db.query(Recycler).all()
    return recyclers

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
