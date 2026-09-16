from datetime import datetime, timedelta
from hashlib import sha256
from jose import jwt, JWTError
from argon2 import PasswordHasher
from argon2.exceptions import VerifyMismatchError
from .config import settings
import secrets

ph=PasswordHasher()
ALGO="HS256"

def validate_password(p):
    import re
    return (len(p)>=8 and re.search(r"[A-Z]",p) and re.search(r"[a-z]",p)
            and re.search(r"\d",p) and re.search(r"[^A-Za-z0-9]",p))

def hash_password(p): return ph.hash(p)
def verify_password(h,p):
    try: return ph.verify(h,p)
    except VerifyMismatchError: return False

def make_access(user_id,roles,permissions):
    exp=datetime.utcnow()+timedelta(minutes=settings.access_token_minutes)
    return jwt.encode({"sub":str(user_id),"roles":roles,"permissions":permissions,"type":"access","exp":exp},settings.jwt_secret,algorithm=ALGO)

def make_refresh(user_id,family):
    raw=secrets.token_urlsafe(48)
    exp=datetime.utcnow()+timedelta(days=settings.refresh_token_days)
    token=jwt.encode({"sub":str(user_id),"family":family,"type":"refresh","exp":exp,"jti":secrets.token_hex(16)},settings.jwt_secret,algorithm=ALGO)
    return token, exp, sha256(token.encode()).hexdigest()

def decode(token):
    return jwt.decode(token,settings.jwt_secret,algorithms=[ALGO])
