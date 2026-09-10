from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime
from uuid import UUID

class HandoverGenerate(BaseModel):
    recycler_id: UUID
    actual_weight: float
    final_price: float
    handover_gps: Dict[str, float]
    material_category: Optional[str] = "Unknown"

class HandoverResponse(BaseModel):
    trace_id: str
    lot_id: str
    ref_number: str
    qr_code_data: str
    material_category: str
    weight_at_collection: float
    recycler_name: str
    recycler_auth_number: str
    collector_display_name: str
    status: str
    collection_timestamp: str

class HandoverConfirm(BaseModel):
    recycler_id: UUID
    handover_gps: str
    actual_weight: float

class HandoverVerifyResponse(BaseModel):
    ref_number: str
    material_category: str
    weight_at_collection: float
    weight_at_handover: Optional[float] = None
    recycler_name: str
    recycler_auth_number: str
    collector_display_name: str
    status: str
    collection_timestamp: datetime
    handover_timestamp: Optional[datetime] = None
    handover_gps: Optional[str] = None
