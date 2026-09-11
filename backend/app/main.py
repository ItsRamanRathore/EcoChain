from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings

from app.api.v1 import api_router

from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Run Alembic migrations instead of create_all.
    # This is safe for existing data — Alembic only applies new changes.
    try:
        from alembic.config import Config
        from alembic import command
        import os
        
        alembic_cfg = Config()
        alembic_cfg.set_main_option(
            "script_location",
            os.path.join(os.path.dirname(__file__), "..", "alembic")
        )
        from app.core.config import settings as _settings
        alembic_cfg.set_main_option("sqlalchemy.url", _settings.SQLALCHEMY_DATABASE_URI)
        command.upgrade(alembic_cfg, "head")
        print("Alembic migrations applied successfully.")
    except Exception as e:
        print(f"Alembic migration failed: {e}")
    
    # Seed reference data (idempotent — skips existing rows)
    try:
        from app.db.seed import seed
        seed()
    except Exception as e:
        print(f"Seed failed: {e}")
    
    yield

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json",
    lifespan=lifespan
)

# Set all CORS enabled origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Update this in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/")
def root():
    return {"message": "Welcome to EcoChain API"}
