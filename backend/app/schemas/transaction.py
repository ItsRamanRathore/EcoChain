from pydantic import BaseModel
from typing import Optional, Dict, Any
from datetime import datetime
from uuid import UUID

class TransactionCreate(BaseModel):
    lot_id: UUID
    recycler_id: UUID
    material_category: Optional[str] = None
    quantity_weight: Optional[float] = None
    quoted_price: float
    collection_location: Optional[Dict[str, Any]] = None

class TransactionConfirm(BaseModel):
    recycler_id: UUID
    actual_weight: float
    final_price: float
    handover_gps: Dict[str, Any]

class TransactionResponse(BaseModel):
    transaction_id: UUID
    lot_id: UUID
    collector_id: UUID
    recycler_id: UUID
    material_category: str
    quantity_weight: float
    quoted_price: float
    final_price: Optional[float] = None
    transaction_status: str
    payment_status: str
    collection_datetime: Optional[datetime] = None
    handover_datetime: Optional[datetime] = None
    
    model_config = {"from_attributes": True}
