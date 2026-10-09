from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from slowapi.middleware import SlowAPIMiddleware
from .config import settings
from .db import Base, engine
from .routers import auth, learning, tutor, sync, management

settings.validate_for_startup()
app = FastAPI(title="Lumina API", version="1.0.0",
              docs_url=None if settings.app_env == "production" else "/docs",
              redoc_url=None if settings.app_env == "production" else "/redoc")
limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_middleware(SlowAPIMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[x.strip() for x in settings.cors_origins.split(",") if x.strip()],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "X-Request-ID"],
)

@app.middleware("http")
async def security_headers(request: Request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Cache-Control"] = "no-store" if request.url.path.startswith("/api/") else "no-cache"
    if settings.app_env == "production":
        response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response

@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request: Request, exc: RateLimitExceeded):
    return JSONResponse(status_code=429, content={"detail": "Too many requests. Please try again later."})

# Kept for initial schema creation. Production schema changes require reviewed migrations.
Base.metadata.create_all(bind=engine)
app.include_router(auth.router)
app.include_router(learning.router)
app.include_router(tutor.router)
app.include_router(sync.router)
app.include_router(management.router)

@app.get("/health", tags=["operations"])
def health():
    return {"status": "ok", "service": "lumina-api", "environment": settings.app_env}

@app.get("/", include_in_schema=False)
def root():
    return {"name": "Lumina", "message": "Your learning, without the signal."}
