from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from datetime import date

from app.db.session import SessionLocal
from app.models.collector import Collector
from app.models.recycler import Recycler
from app.models.admin import Admin
from app.schemas.token import Token
from app.core.security import (
    hash_pin, verify_pin,
    hash_password, verify_password,
    create_role_access_token,
    hash_phone
)
from app.api.deps import get_db

router = APIRouter()

# ─── Request Schemas ─────────────────────────────────────────────────────────

class CollectorRegisterRequest(BaseModel):
    display_name: str
    phone_number: str
    pin: str
    preferred_language: str = "English"
    operating_district: str
    operating_state: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class CollectorLoginRequest(BaseModel):
    phone_number: str
    pin: str

class RecyclerRegisterRequest(BaseModel):
    name: str
    email: str
    password: str
    facility_address: str
    latitude: float
    longitude: float
    materials_accepted: list[str]
    auth_number: str
    pickup_available: bool = False
    service_radius_km: int = 20
    contact_phone: Optional[str] = None
    shop_image_url: Optional[str] = None
    shop_latitude: Optional[float] = None
    shop_longitude: Optional[float] = None

class RecyclerLoginRequest(BaseModel):
    email: str
    password: str

class AdminLoginRequest(BaseModel):
    email: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    role: str
    user_id: str
    display_name: str

# ─── Collector ────────────────────────────────────────────────────────────────

@router.post("/register/collector", response_model=TokenResponse)
def register_collector(req: CollectorRegisterRequest, db: Session = Depends(get_db)):
    phone_hash = hash_phone(req.phone_number)
    if db.query(Collector).filter_by(phone_hash=phone_hash).first():
        raise HTTPException(status_code=400, detail="Phone number already registered")

    collector = Collector(
        display_name=req.display_name,
        phone_hash=phone_hash,
        pin_hash=hash_pin(req.pin),
        preferred_language=req.preferred_language,
        operating_district=req.operating_district,
        operating_state=req.operating_state,
        latitude=req.latitude,
        longitude=req.longitude,
        registration_date=date.today(),
        total_transactions=0,
        total_earnings=0.0,
    )
    db.add(collector)
    db.commit()
    db.refresh(collector)

    token = create_role_access_token(str(collector.collector_id), "collector")
    return {
        "access_token": token,
        "role": "collector",
        "user_id": str(collector.collector_id),
        "display_name": collector.display_name,
    }

@router.post("/login/collector", response_model=TokenResponse)
def login_collector(req: CollectorLoginRequest, db: Session = Depends(get_db)):
    phone_hash = hash_phone(req.phone_number)
    collector = db.query(Collector).filter_by(phone_hash=phone_hash).first()
    if not collector:
        raise HTTPException(status_code=401, detail="Invalid phone number or PIN")

    # Support both old (phone-based) and new (PIN-based) auth
    if collector.pin_hash:
        if not verify_pin(req.pin, collector.pin_hash):
            raise HTTPException(status_code=401, detail="Invalid phone number or PIN")

    token = create_role_access_token(str(collector.collector_id), "collector")
    return {
        "access_token": token,
        "role": "collector",
        "user_id": str(collector.collector_id),
        "display_name": collector.display_name,
    }

# ─── Recycler ─────────────────────────────────────────────────────────────────

@router.post("/register/recycler")
def register_recycler(req: RecyclerRegisterRequest, db: Session = Depends(get_db)):
    if db.query(Recycler).filter_by(email=req.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    recycler = Recycler(
        name=req.name,
        email=req.email,
        password_hash=hash_password(req.password),
        facility_address=req.facility_address,
        latitude=req.latitude,
        longitude=req.longitude,
        materials_accepted=req.materials_accepted,
        auth_number=req.auth_number,
        auth_status="Active",
        offered_rates={mat: 0 for mat in req.materials_accepted},
        pickup_available=req.pickup_available,
        service_radius_km=req.service_radius_km,
        contact_phone=req.contact_phone,
        contact_email=req.email,
        shop_image_url=req.shop_image_url,
        shop_latitude=req.shop_latitude,
        shop_longitude=req.shop_longitude,
        verified_by_admin=False,
        approval_status="pending",
    )
    db.add(recycler)
    db.commit()
    return {
        "message": "Registration submitted. Your account is pending admin approval.",
        "status": "pending"
    }

@router.post("/login/recycler", response_model=TokenResponse)
def login_recycler(req: RecyclerLoginRequest, db: Session = Depends(get_db)):
    recycler = db.query(Recycler).filter_by(email=req.email).first()
    if not recycler or not recycler.password_hash:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if not verify_password(req.password, recycler.password_hash):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if recycler.approval_status == "pending":
        raise HTTPException(
            status_code=403,
            detail="Your account is pending admin approval. You will be notified once approved."
        )
    if recycler.approval_status == "rejected":
        reason = recycler.rejection_reason or "Contact admin for details."
        raise HTTPException(status_code=403, detail=f"Account rejected: {reason}")

    token = create_role_access_token(str(recycler.recycler_id), "recycler")
    return {
        "access_token": token,
        "role": "recycler",
        "user_id": str(recycler.recycler_id),
        "display_name": recycler.name,
    }

# ─── Admin ────────────────────────────────────────────────────────────────────

@router.post("/login/admin", response_model=TokenResponse)
def login_admin(req: AdminLoginRequest, db: Session = Depends(get_db)):
    admin = db.query(Admin).filter_by(email=req.email).first()
    if not admin or not verify_password(req.password, admin.password_hash):
        raise HTTPException(status_code=401, detail="Invalid admin credentials")

    token = create_role_access_token(str(admin.admin_id), "admin")
    return {
        "access_token": token,
        "role": "admin",
        "user_id": str(admin.admin_id),
        "display_name": admin.display_name,
    }
