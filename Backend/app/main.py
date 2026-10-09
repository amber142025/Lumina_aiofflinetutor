from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.middleware import SlowAPIMiddleware

from .config import settings
from .db import Base, engine
from .routers import auth, learning, tutor, sync, management
from .models import models as _models  # Ensure models are registered before metadata use.

settings.validate_for_startup()

app = FastAPI(title="Lumina API", version="1.1.0")
limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_middleware(SlowAPIMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type"],
)
# This creates tables for the current schema. A versioned migration system is required
# before production schema changes; see PRODUCTION_RUNBOOK.md.
Base.metadata.create_all(bind=engine)

app.include_router(auth.router)
app.include_router(learning.router)
app.include_router(tutor.router)
app.include_router(sync.router)
app.include_router(management.router)


@app.get("/health", tags=["operations"])
def health():
    return {"status": "ok", "service": "lumina-api"}


@app.get("/ready", tags=["operations"])
def ready():
    # Verify the database connection, not just that the web process is alive.
    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))
    return {"status": "ready", "database": "reachable"}


@app.get("/")
def root():
    return {"name": "Lumina", "message": "Your learning, without the signal."}
