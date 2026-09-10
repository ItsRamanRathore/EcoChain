from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from datetime import datetime, timezone
from app.api.deps import get_current_collector, get_current_recycler, get_db
from app.models.transaction import Transaction
from app.schemas.transaction import TransactionCreate, TransactionConfirm, TransactionResponse

router = APIRouter()

@router.post("/create", response_model=TransactionResponse)
def create_transaction(
    tx_in: TransactionCreate,
    db: Session = Depends(get_db),
    current_collector = Depends(get_current_collector)
):
    db_tx = Transaction(
        **tx_in.model_dump(),
        collector_id=current_collector.collector_id,
        transaction_status='Created',
        payment_status='Pending'
    )
    db.add(db_tx)
    db.commit()
    db.refresh(db_tx)
    return db_tx

@router.patch("/{id}/confirm", response_model=TransactionResponse)
def confirm_transaction(
    id: str,
    tx_confirm: TransactionConfirm,
    db: Session = Depends(get_db),
    current_recycler = Depends(get_current_recycler)
):
    tx = db.query(Transaction).filter(Transaction.transaction_id == id).first()
    if not tx:
        raise HTTPException(status_code=404, detail="Transaction not found")
        
    if str(tx.recycler_id) != str(tx_confirm.recycler_id):
        raise HTTPException(status_code=403, detail="Not authorized to confirm this transaction")
        
    tx.final_price = tx_confirm.final_price
    tx.quantity_weight = tx_confirm.actual_weight
    tx.handover_location = tx_confirm.handover_gps
    tx.transaction_status = 'Completed'
    tx.handover_datetime = datetime.now(timezone.utc)
    
    db.commit()
    db.refresh(tx)
    return tx

@router.get("/history/me", response_model=List[TransactionResponse])
def get_transaction_history(
    db: Session = Depends(get_db),
    current_collector = Depends(get_current_collector)
):
    history = db.query(Transaction).filter(
        Transaction.collector_id == current_collector.collector_id,
        Transaction.transaction_status == 'Completed'
    ).order_by(Transaction.handover_datetime.desc()).all()
    return history

@router.get("/recycler/{recycler_id}/pending", response_model=List[TransactionResponse])
def get_recycler_pending_transactions(
    recycler_id: str,
    db: Session = Depends(get_db),
    current_recycler = Depends(get_current_recycler)
):
    if str(current_recycler.recycler_id) != recycler_id:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    pending = db.query(Transaction).filter(
        Transaction.recycler_id == recycler_id,
        Transaction.transaction_status == 'Created'
    ).order_by(Transaction.handover_datetime.desc()).all()
    return pending

@router.get("/recycler/{recycler_id}/history", response_model=List[TransactionResponse])
def get_recycler_transaction_history(
    recycler_id: str,
    db: Session = Depends(get_db),
    current_recycler = Depends(get_current_recycler)
):
    if str(current_recycler.recycler_id) != recycler_id:
        raise HTTPException(status_code=403, detail="Not authorized")
        
    history = db.query(Transaction).filter(
        Transaction.recycler_id == recycler_id,
        Transaction.transaction_status == 'Completed'
    ).order_by(Transaction.handover_datetime.desc()).all()
    return history
