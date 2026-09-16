from fastapi import APIRouter,Depends
from sqlalchemy.orm import Session
from ..db import get_db
from ..deps import require_roles,current_user
from ..models.models import User,Role,Course,Lesson,Assignment,ScheduleEvent,Notification

router=APIRouter(prefix="/api/v1/management",tags=["management"])

@router.get("/users")
def users(db=Depends(get_db),user=Depends(require_roles("admin","manager"))):
    return [{"id":u.id,"username":u.username,"email":u.email,"display_name":u.display_name,"active":u.is_active} for u in db.query(User).all()]

@router.get("/courses")
def manage_courses(db=Depends(get_db),user=Depends(require_roles("admin","content_manager"))):
    return [{"id":c.id,"title":c.title} for c in db.query(Course).all()]

@router.get("/teacher/assignments")
def assignments(db=Depends(get_db),user=Depends(require_roles("teacher"))):
    return [{"id":a.id,"title":a.title,"description":a.description,"due_at":a.due_at} for a in db.query(Assignment).filter_by(teacher_id=user.id).all()]

@router.get("/schedule")
def schedule(db=Depends(get_db),user=Depends(current_user)):
    return [{"id":s.id,"title":s.title,"start_at":s.start_at.isoformat(),"end_at":None if not s.end_at else s.end_at.isoformat(),"event_type":s.event_type} for s in db.query(ScheduleEvent).filter_by(user_id=user.id).all()]

@router.get("/notifications")
def notifications(db=Depends(get_db),user=Depends(current_user)):
    return [{"id":n.id,"title":n.title,"body":n.body,"read":n.read} for n in db.query(Notification).filter_by(user_id=user.id).all()]
