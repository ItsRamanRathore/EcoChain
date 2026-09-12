from fastapi import APIRouter
from app.api.v1.endpoints import auth, collectors, lots, prices, recyclers, transactions, handover, sync, admin, inference

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(collectors.router, prefix="/collectors", tags=["collectors"])
api_router.include_router(lots.router, prefix="/lots", tags=["lots"])
api_router.include_router(prices.router, prefix="/prices", tags=["prices"])
api_router.include_router(recyclers.router, prefix="/recyclers", tags=["recyclers"])
api_router.include_router(transactions.router, prefix="/transactions", tags=["transactions"])
api_router.include_router(handover.router, prefix="/handover", tags=["handover"])
api_router.include_router(sync.router, prefix="/sync", tags=["sync"])
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
api_router.include_router(inference.router, prefix="/inference", tags=["inference"])
