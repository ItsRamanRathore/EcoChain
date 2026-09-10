from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.models.collector import Collector
from app.schemas.collector import CollectorCreate, CollectorResponse
from app.schemas.token import Token
from app.core.security import hash_pin, verify_pin, create_access_token, create_role_access_token, hash_phone
from app.api.deps import get_db
from app.models.recycler import Recycler
from app.schemas.auth import LoginRequest, TokenResponse
import uuid

router = APIRouter()

@router.post("/register", response_model=Token)
def register_collector(collector_in: CollectorCreate, db: Session = Depends(get_db)):
    existing = db.query(Collector).filter(Collector.phone_hash == hash_phone(collector_in.phone_number)).first()
    if existing:
        raise HTTPException(status_code=400, detail="Collector with this phone already registered")
        
    db_collector = Collector(
        preferred_language=collector_in.preferred_language,
        operating_district=collector_in.operating_district,
        operating_state=collector_in.operating_state,
        display_name=collector_in.display_name,
        phone_hash=hash_phone(collector_in.phone_number),
        total_transactions=0,
        total_earnings=0.0
    )
    db.add(db_collector)
    db.commit()
    db.refresh(db_collector)
    
    access_token = create_access_token(collector_id=str(db_collector.collector_id))
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/login", response_model=TokenResponse)
def login_collector(phone_number: str, pin: str, db: Session = Depends(get_db)):
    collector = db.query(Collector).filter(Collector.phone_hash == hash_phone(phone_number)).first()
    if not collector:
        raise HTTPException(status_code=401, detail="Invalid credentials")
        
    access_token = create_role_access_token(user_id=str(collector.collector_id), role="collector")
    return {
        "access_token": access_token,
        "role": "collector",
        "user_id": str(collector.collector_id),
        "display_name": collector.display_name
    }

@router.post("/login/google", response_model=TokenResponse)
def login_google(request: LoginRequest, db: Session = Depends(get_db)):
    if request.mock_role == "collector":
        user = db.query(Collector).first()
        if not user:
            raise HTTPException(status_code=404, detail="No collector found")
        token = create_role_access_token(user_id=str(user.collector_id), role="collector")
        return {
            "access_token": token,
            "role": "collector",
            "user_id": str(user.collector_id),
            "display_name": user.display_name
        }
    elif request.mock_role == "recycler":
        user = db.query(Recycler).first()
        if not user:
            raise HTTPException(status_code=404, detail="No recycler found")
        token = create_role_access_token(user_id=str(user.recycler_id), role="recycler")
        return {
            "access_token": token,
            "role": "recycler",
            "user_id": str(user.recycler_id),
            "display_name": user.name
        }
    elif request.mock_role == "admin":
        token = create_role_access_token(user_id="admin-user-id", role="admin")
        return {
            "access_token": token,
            "role": "admin",
            "user_id": "admin-user-id",
            "display_name": "System Admin"
        }
    
    raise HTTPException(status_code=400, detail="Invalid request")
