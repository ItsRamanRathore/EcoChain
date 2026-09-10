from pydantic import BaseModel
from typing import List, Dict, Any, Optional
from uuid import UUID

class RecyclerResponse(BaseModel):
    recycler_id: UUID
    name: str
    facility_address: str
    latitude: float
    longitude: float
    materials_accepted: List[str]
    auth_status: str
    offered_rates: Dict[str, Any]
    pickup_available: bool
    service_radius_km: int
    verified_by_admin: bool
    
    # Matching specific
    match_score: Optional[float] = None
    distance_km: Optional[float] = None

    model_config = {"from_attributes": True}

class RecyclerDashboardMetrics(BaseModel):
    total_transactions: int
    total_weight_processed: float
    recent_transactions: List[Any]
    pending_transactions: List[Any]

class RecyclerPriceUpdate(BaseModel):
    category: str
    new_price: float
