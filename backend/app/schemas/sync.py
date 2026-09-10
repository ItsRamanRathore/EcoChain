from pydantic import BaseModel
from typing import List, Dict, Any
from datetime import datetime
from app.schemas.lot import LotCreate
from app.schemas.price import PriceResponse
from app.schemas.recycler import RecyclerResponse

class SyncLotCreate(LotCreate):
    local_id: str

class SyncPushRequest(BaseModel):
    lots: List[SyncLotCreate]

class SyncPushResponse(BaseModel):
    results: List[Dict[str, Any]]

class SyncPullResponse(BaseModel):
    prices: List[PriceResponse]
    recyclers: List[RecyclerResponse]
    timestamp: datetime
