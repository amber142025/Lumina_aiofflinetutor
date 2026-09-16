from fastapi import APIRouter, Depends
from ..deps import current_user
from ..db import get_db
from ..models.models import LessonProgress,Mastery,ScheduleEvent
from ..schemas import TutorIn
from datetime import datetime

router=APIRouter(prefix="/api/v1/ai",tags=["ai"])

def local_reply(message,context,db,user):
    m=message.lower()
    if "why" in m or "explain" in m:
        return "Let's break it into a smaller idea. First identify the key concept, then connect it to one example, and finally try a short practice question."
    if "quiz" in m or "practice" in m:
        return "Try a focused practice session on your weakest topic. After three attempts, review the questions you missed before moving on."
    if "offline" in m:
        return "You're using Lumina's local tutor mode. Your learning context can still be used for deterministic guidance without a cloud AI request."
    return "I can help you plan the next step. Review one recent mistake, complete a short practice activity, and then check your mastery progress."

@router.post("/chat")
def chat(x:TutorIn,db=Depends(get_db),user=Depends(current_user)):
    # Production cloud LLM integration can be connected here through an approved provider.
    return {"mode":"local","reply":local_reply(x.message,x.context,db,user)}

@router.get("/recommendations")
def recommendations(db=Depends(get_db),user=Depends(current_user)):
    cards=[]
    weak=[m for m in db.query(Mastery).filter_by(user_id=user.id).all() if m.score<.7]
    for m in weak[:3]:
        cards.append({"type":"weak_area","title":"Lumina noticed a pattern","body":f"Review {m.topic}; your current mastery is {round(m.score*100)}%."})
    incomplete=db.query(LessonProgress).filter_by(user_id=user.id,completed=False).order_by(LessonProgress.updated_at).first()
    if incomplete: cards.append({"type":"lesson","title":"A lesson is waiting","body":"Continue your unfinished lesson and keep your streak moving."})
    upcoming=db.query(ScheduleEvent).filter(ScheduleEvent.user_id==user.id,ScheduleEvent.start_at>=datetime.utcnow()).order_by(ScheduleEvent.start_at).first()
    if upcoming: cards.append({"type":"schedule","title":"Upcoming study session","body":upcoming.title})
    if not cards: cards.append({"type":"welcome","title":"Nice work!","body":"Choose a lesson and Lumina will help you build your next study step."})
    return cards
