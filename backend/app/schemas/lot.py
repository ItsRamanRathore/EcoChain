from pydantic import BaseModel
from typing import Optional, Dict, Any, List
from datetime import datetime
from uuid import UUID

class LotBase(BaseModel):
    material_category: str
    approximate_weight: float
    condition: str
    collection_location: Optional[Dict[str, Any]] = None
    sub_category: Optional[str] = "Mixed"
    source_type: Optional[str] = "Household"
    estimated_value: Optional[float] = None
    description: Optional[str] = None

class LotCreate(LotBase):
    pass

class LotResponse(LotBase):
    material_id: UUID
    lot_id: Optional[UUID] = None
    image_path: Optional[str] = None
    created_at: datetime
    category: Optional[str] = None
    
    model_config = {"from_attributes": True}
