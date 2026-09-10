from pydantic import BaseModel
from typing import Optional
from datetime import date
from uuid import UUID

class PriceResponse(BaseModel):
    price_id: UUID
    material_category: str
    material_sub_cat: str
    location_district: str
    date_recorded: date
    buying_price: float
    market_price_low: float
    market_price_high: float
    unit: str
    
    model_config = {"from_attributes": True}
