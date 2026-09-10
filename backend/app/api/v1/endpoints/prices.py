from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime, timedelta
from app.api.deps import get_current_collector, get_db
from app.models.price import Price
from app.schemas.price import PriceResponse

router = APIRouter()

@router.get("/current", response_model=List[PriceResponse])
def get_current_prices(
    district: Optional[str] = None,
    category: Optional[str] = None,
    db: Session = Depends(get_db),
    current_collector = Depends(get_current_collector)
):
    query = db.query(Price)
    if district:
        query = query.filter(Price.location_district == district)
    if category:
        query = query.filter(Price.material_category == category)
    
    return query.all()

@router.get("/history", response_model=List[PriceResponse])
def get_price_history(
    category: str,
    days: int = 7,
    db: Session = Depends(get_db),
    current_collector = Depends(get_current_collector)
):
    date_threshold = datetime.utcnow() - timedelta(days=days)
    prices = db.query(Price).filter(
        Price.material_category == category,
        Price.date_recorded >= date_threshold.date()
    ).all()
    return prices
