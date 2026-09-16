from fastapi import Depends, HTTPException, Header
from sqlalchemy.orm import Session
from .db import get_db
from .security import decode
from .models.models import User, UserRole, Role, RolePermission, Permission

def current_user(authorization: str=Header(default=""), db:Session=Depends(get_db)):
    if not authorization.startswith("Bearer "): raise HTTPException(401,"Authentication required")
    try: data=decode(authorization[7:])
    except Exception: raise HTTPException(401,"Invalid or expired token")
    if data.get("type")!="access": raise HTTPException(401,"Invalid token type")
    user=db.get(User,int(data["sub"]))
    if not user or not user.is_active: raise HTTPException(401,"User unavailable")
    return user

def roles_for(user,db):
    return [r.name for r in db.query(Role).join(UserRole,Role.id==UserRole.role_id).filter(UserRole.user_id==user.id).all()]

def permissions_for(user,db):
    return [p.name for p in db.query(Permission).join(RolePermission,Permission.id==RolePermission.permission_id).join(UserRole,RolePermission.role_id==UserRole.role_id).filter(UserRole.user_id==user.id).distinct().all()]

def require_roles(*allowed):
    def dep(user=Depends(current_user),db:Session=Depends(get_db)):
        roles=roles_for(user,db)
        if not set(roles)&set(allowed): raise HTTPException(403,"Insufficient role")
        return user
    return dep

def require_permission(permission):
    def dep(user=Depends(current_user),db:Session=Depends(get_db)):
        if permission not in permissions_for(user,db): raise HTTPException(403,"Permission denied")
        return user
    return dep
