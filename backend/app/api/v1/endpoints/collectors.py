from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api.deps import get_current_collector, get_db
from app.models.collector import Collector
from app.schemas.collector import CollectorResponse

router = APIRouter()

@router.get("/me", response_model=CollectorResponse)
def get_collector_me(
    current_collector: Collector = Depends(get_current_collector),
):
    return current_collector

@router.get("/{collector_id}", response_model=CollectorResponse)
def get_collector(
    collector_id: str,
    db: Session = Depends(get_db),
    current_collector: Collector = Depends(get_current_collector)
):
    collector = db.query(Collector).filter(Collector.collector_id == collector_id).first()
    if not collector:
        raise HTTPException(status_code=404, detail="Collector not found")
    return collector
