from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from datetime import datetime
import uuid
from ..db import get_db
from ..models.models import User,Role,UserRole,Invitation,RefreshToken,AuditLog
from ..schemas import RegisterIn,LoginIn,RefreshIn
from ..security import *
from ..deps import roles_for, permissions_for, current_user

router=APIRouter(prefix="/api/v1/auth",tags=["auth"])
PUBLIC_ROLES={"student"}
INVITE_ROLES={"teacher","parent","manager","content_manager"}

@router.post("/register")
def register(x:RegisterIn,db:Session=Depends(get_db)):
    role=x.role.lower()
    if x.password!=x.confirm_password: raise HTTPException(400,"Passwords do not match")
    if not validate_password(x.password): raise HTTPException(400,"Password must contain uppercase, lowercase, number and special character")
    if role=="admin": raise HTTPException(403,"Admin cannot be publicly registered")
    if role in INVITE_ROLES:
        inv=db.query(Invitation).filter(Invitation.code==x.invitation_code,Invitation.role_name==role,Invitation.active==True).first()
        if not inv: raise HTTPException(403,"Valid role invitation code required")
    if db.query(User).filter((User.username==x.username)|(User.email==x.email)).first(): raise HTTPException(409,"Username or email already exists")
    u=User(username=x.username,email=x.email,display_name=x.display_name,password_hash=hash_password(x.password))
    db.add(u); db.flush()
    r=db.query(Role).filter(Role.name==role).first()
    if not r: raise HTTPException(400,"Unsupported role")
    db.add(UserRole(user_id=u.id,role_id=r.id)); db.add(AuditLog(user_id=u.id,action="register",detail=role)); db.commit()
    return {"message":"Registration successful","user_id":u.id}

@router.post("/login")
def login(x:LoginIn,db:Session=Depends(get_db)):
    u=db.query(User).filter((User.username==x.identifier)|(User.email==x.identifier.lower())).first()
    if not u or not verify_password(u.password_hash,x.password): raise HTTPException(401,"Invalid username/email or password")
    roles=roles_for(u,db); perms=permissions_for(u,db)
    family=uuid.uuid4().hex
    refresh,exp,h=make_refresh(u.id,family)
    db.add(RefreshToken(user_id=u.id,token_hash=h,family_id=family,expires_at=exp))
    db.add(AuditLog(user_id=u.id,action="login",detail="success")); db.commit()
    return {"access_token":make_access(u.id,roles,perms),"refresh_token":refresh,"token_type":"bearer",
            "user":{"id":u.id,"username":u.username,"email":u.email,"display_name":u.display_name,"roles":roles,"permissions":perms}}

@router.post("/refresh")
def refresh(x:RefreshIn,db:Session=Depends(get_db)):
    try: data=decode(x.refresh_token)
    except Exception: raise HTTPException(401,"Invalid refresh token")
    if data.get("type")!="refresh": raise HTTPException(401,"Invalid token type")
    h=sha256(x.refresh_token.encode()).hexdigest()
    row=db.query(RefreshToken).filter(RefreshToken.token_hash==h).first()
    if not row or row.revoked or row.expires_at<datetime.utcnow(): raise HTTPException(401,"Refresh token expired or revoked")
    row.revoked=True
    u=db.get(User,row.user_id); roles=roles_for(u,db); perms=permissions_for(u,db)
    new,exp,nh=make_refresh(u.id,row.family_id)
    db.add(RefreshToken(user_id=u.id,token_hash=nh,family_id=row.family_id,expires_at=exp)); db.commit()
    return {"access_token":make_access(u.id,roles,perms),"refresh_token":new,"token_type":"bearer"}

@router.post("/logout")
def logout(x:RefreshIn,db:Session=Depends(get_db)):
    h=sha256(x.refresh_token.encode()).hexdigest()
    row=db.query(RefreshToken).filter(RefreshToken.token_hash==h).first()
    if row: row.revoked=True; db.commit()
    return {"message":"Logged out"}

@router.get("/me")
def me(user=Depends(current_user),db:Session=Depends(get_db)):
    return {"id":user.id,"username":user.username,"email":user.email,"display_name":user.display_name,
            "roles":roles_for(user,db),"permissions":permissions_for(user,db)}
