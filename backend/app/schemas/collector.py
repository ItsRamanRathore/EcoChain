from pydantic import BaseModel
from typing import Optional
from datetime import date
from uuid import UUID

class CollectorBase(BaseModel):
    preferred_language: str
    operating_district: str
    operating_state: str
    display_name: str

class CollectorCreate(CollectorBase):
    phone_number: str
    pin: str

class CollectorResponse(CollectorBase):
    collector_id: UUID
    registration_date: date
    total_transactions: int
    total_earnings: float
    
    model_config = {"from_attributes": True}
