from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.api.deps import get_current_collector, get_current_recycler, get_db
from app.models.recycler import Recycler
from app.models.price import Price
from app.models.transaction import Transaction
from app.schemas.recycler import RecyclerResponse, RecyclerDashboardMetrics, RecyclerPriceUpdate
import math

router = APIRouter()

def haversine(lat1, lon1, lat2, lon2):
    R = 6371.0  # Earth radius km
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return R * c

def compute_match_score(recycler, category: str, distance_km: float, market_price_high: float) -> float:
    """
    Weighted match score for ranking recyclers:
      45% — rate quality  (offered rate vs market high; closer to market = better value)
      40% — proximity     (closer = higher score, capped at 100 km)
      15% — pickup bonus  (pickup_available = 1.0, else 0.0)
    Returns a score in [0, 1]. Higher is better.
    """
    rate = (recycler.offered_rates or {}).get(category, 0)

    # Normalize rate quality (0-1)
    rate_score = min(rate / market_price_high, 1.0) if market_price_high > 0 else 0.0

    # Normalize distance (closer = higher score, cap at 100 km)
    distance_score = max(0.0, 1.0 - (distance_km / 100.0))

    # Pickup bonus
    pickup_score = 1.0 if recycler.pickup_available else 0.0

    return (0.45 * rate_score) + (0.40 * distance_score) + (0.15 * pickup_score)

@router.get("/match", response_model=List[RecyclerResponse])
def match_recyclers(
    lat: float,
    lng: float,
    category: str,
    radius_km: int = 50,
    db: Session = Depends(get_db),
    current_collector = Depends(get_current_collector)
):
    # Fetch market price for score normalization
    latest_price = db.query(Price).filter(
        Price.material_category == category
    ).order_by(Price.date_recorded.desc()).first()
    market_price_high = float(latest_price.market_price_high) if latest_price and latest_price.market_price_high else 1.0

    recyclers = db.query(Recycler).filter(Recycler.auth_status == 'Active').all()
    matches = []

    for r in recyclers:
        if category not in (r.materials_accepted or []):
            continue

        distance = haversine(lat, lng, float(r.latitude), float(r.longitude))
        if distance > r.service_radius_km:
            continue
        if distance > radius_km:
            continue

        score = compute_match_score(r, category, distance, market_price_high)
        setattr(r, 'distance_km', round(distance, 2))
        setattr(r, 'match_score', round(score, 4))
        matches.append(r)

    # Sort: highest score first (better value + closer wins)
    matches.sort(key=lambda x: x.match_score, reverse=True)
    return matches[:3]

@router.get("/", response_model=List[RecyclerResponse])
def get_recyclers(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get all available recyclers"""
    recyclers = db.query(Recycler).offset(skip).limit(limit).all()
    return recyclers

@router.get("/me", response_model=RecyclerResponse)
def get_current_recycler_profile(
    db: Session = Depends(get_db),
    current_recycler = Depends(get_current_recycler)
):
    """Get current logged in recycler profile"""
    return current_recycler

@router.get("/{recycler_id}", response_model=RecyclerResponse)
def get_recycler(
    recycler_id: str,
    db: Session = Depends(get_db),
    current_collector = Depends(get_current_collector)
):
    recycler = db.query(Recycler).filter(Recycler.recycler_id == recycler_id).first()
    if not recycler:
        raise HTTPException(status_code=404, detail="Recycler not found")
    return recycler

@router.get("/dashboard/metrics", response_model=RecyclerDashboardMetrics)
def get_dashboard_metrics(
    db: Session = Depends(get_db),
    current_recycler = Depends(get_current_recycler)
):
    history = db.query(Transaction).filter(
        Transaction.recycler_id == current_recycler.recycler_id,
        Transaction.transaction_status == 'Completed'
    ).order_by(Transaction.handover_datetime.desc()).all()
    
    pending_db = db.query(Transaction).filter(
        Transaction.recycler_id == current_recycler.recycler_id,
        Transaction.transaction_status == 'Created'
    ).order_by(Transaction.collection_datetime.desc()).all()
    
    total_weight = sum(float(tx.quantity_weight) for tx in history if tx.quantity_weight)
    
    # Simple serialization for recent 10 transactions
    recent = []
    for tx in history[:10]:
        recent.append({
            "transaction_id": str(tx.transaction_id),
            "lot_id": tx.lot_id,
            "quantity_weight": float(tx.quantity_weight) if tx.quantity_weight else 0,
            "final_price": float(tx.final_price) if tx.final_price else 0,
            "handover_datetime": tx.handover_datetime
        })
        
    pending = []
    for tx in pending_db:
        pending.append({
            "transaction_id": str(tx.transaction_id),
            "lot_id": tx.lot_id,
            "quantity_weight": float(tx.quantity_weight) if tx.quantity_weight else 0,
            "final_price": float(tx.final_price) if tx.final_price else 0,
            "created_at": tx.collection_datetime
        })
        
    return {
        "total_transactions": len(history),
        "total_weight_processed": total_weight,
        "recent_transactions": recent,
        "pending_transactions": pending
    }

@router.patch("/prices", response_model=RecyclerResponse)
def update_price(
    update: RecyclerPriceUpdate,
    db: Session = Depends(get_db),
    current_recycler = Depends(get_current_recycler)
):
    # Retrieve current rates or default to empty dict
    rates = current_recycler.offered_rates or {}
    # SQLAlchemy requires assigning a new dict to JSON columns to detect changes
    rates_copy = rates.copy()
    rates_copy[update.category] = update.new_price
    
    current_recycler.offered_rates = rates_copy
    db.commit()
    db.refresh(current_recycler)
    return current_recycler
