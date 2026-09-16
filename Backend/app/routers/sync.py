from fastapi import APIRouter,Depends
from sqlalchemy.orm import Session
from ..db import get_db
from ..deps import current_user
from ..schemas import SyncIn,ProgressIn
from ..models.models import LessonProgress
from datetime import datetime

router=APIRouter(prefix="/api/v1/sync",tags=["sync"])

@router.post("")
def sync(x:SyncIn,db:Session=Depends(get_db),user=Depends(current_user)):
    results=[]
    for item in x.items:
        if item.type=="lesson_progress":
            p=item.payload
            row=db.query(LessonProgress).filter_by(user_id=user.id,lesson_id=int(p["lesson_id"])).first()
            if not row: row=LessonProgress(user_id=user.id,lesson_id=int(p["lesson_id"])); db.add(row)
            row.progress=float(p.get("progress",0));row.completed=bool(p.get("completed",False));row.last_position=int(p.get("last_position",0));row.updated_at=datetime.utcnow()
            results.append({"type":item.type,"status":"synced","lesson_id":p["lesson_id"]})
        else: results.append({"type":item.type,"status":"ignored"})
    db.commit()
    return {"synced":results}
