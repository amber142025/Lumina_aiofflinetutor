from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter
from slowapi.util import get_remote_address
from slowapi.middleware import SlowAPIMiddleware
from .config import settings
from .db import Base,engine
from .routers import auth,learning,tutor,sync,management

app=FastAPI(title="Lumina API",version="1.0.0")
limiter=Limiter(key_func=get_remote_address)
app.state.limiter=limiter
app.add_middleware(SlowAPIMiddleware)
app.add_middleware(CORSMiddleware,allow_origins=[x.strip() for x in settings.cors_origins.split(",")],
                   allow_credentials=True,allow_methods=["GET","POST","PUT","PATCH","DELETE"],allow_headers=["*"])
Base.metadata.create_all(bind=engine)
app.include_router(auth.router);app.include_router(learning.router);app.include_router(tutor.router)
app.include_router(sync.router);app.include_router(management.router)

@app.get("/health")
def health(): return {"status":"ok","service":"lumina-api"}

@app.get("/")
def root(): return {"name":"Lumina","message":"Your learning, without the signal."}
