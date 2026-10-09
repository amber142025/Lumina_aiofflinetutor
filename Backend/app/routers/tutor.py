from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..config import settings
from ..db import get_db
from ..deps import current_user
from ..models.models import LessonProgress, Mastery, ScheduleEvent
from ..schemas import TutorIn

router = APIRouter(prefix="/api/v1/ai", tags=["ai"])


def local_reply(message: str) -> str:
    """Deterministic fallback; clearly labelled as local guidance, not generative AI."""
    m = message.lower()
    if "why" in m or "explain" in m:
        return "Let's break it into a smaller idea. Identify the key concept, connect it to an example, then try a short practice question."
    if "quiz" in m or "practice" in m:
        return "Choose one focused practice activity, review every mistake, and retry the questions you missed."
    if "offline" in m:
        return "You're using Lumina's offline tutor guidance. Cloud AI is unavailable without an internet connection."
    return "Start with one learning goal. Review a recent mistake, complete a short practice activity, and then check your progress."


@router.post("/chat")
def chat(x: TutorIn, db: Session = Depends(get_db), user=Depends(current_user)):
    message = x.message.strip()
    if not message:
        raise HTTPException(status_code=422, detail="Message cannot be empty.")
    if len(message) > 8000:
        raise HTTPException(status_code=413, detail="Message is too long (maximum 8000 characters).")

    if settings.ai_provider.lower() != "openai":
        return {"mode": "local", "reply": local_reply(message)}

    try:
        from openai import OpenAI

        client = OpenAI(api_key=settings.ai_api_key, timeout=settings.ai_timeout_seconds, max_retries=1)
        # Do not send credentials or unrelated personal data to the provider.
        context = x.context if isinstance(x.context, dict) else {}
        safe_context = {str(k)[:80]: str(v)[:500] for k, v in list(context.items())[:12]}
        response = client.responses.create(
            model=settings.openai_model,
            instructions=(
                "You are Lumina, a supportive educational tutor. Explain concepts clearly, "
                "adapt to the learner's level, encourage independent reasoning, and do not "
                "claim to know facts not present in the conversation. Keep answers focused."
            ),
            input=f"Learner context (untrusted): {safe_context}\n\nLearner message: {message}",
            max_output_tokens=700,
        )
        answer = (response.output_text or "").strip()
        if not answer:
            raise RuntimeError("AI provider returned an empty response.")
        return {"mode": "online_ai", "reply": answer}
    except Exception:
        # Do not leak provider details, keys, prompts, or internal exceptions to customers.
        raise HTTPException(status_code=503, detail="Online AI tutoring is temporarily unavailable. Please retry or use offline learning.")


@router.get("/recommendations")
def recommendations(db: Session = Depends(get_db), user=Depends(current_user)):
    cards = []
    weak = [m for m in db.query(Mastery).filter_by(user_id=user.id).all() if m.score < .7]
    for m in weak[:3]:
        cards.append({"type": "weak_area", "title": "Review a topic", "body": f"Review {m.topic}; current mastery is {round(m.score * 100)}%."})
    incomplete = db.query(LessonProgress).filter_by(user_id=user.id, completed=False).order_by(LessonProgress.updated_at).first()
    if incomplete:
        cards.append({"type": "lesson", "title": "Continue learning", "body": "Continue your unfinished lesson."})
    upcoming = db.query(ScheduleEvent).filter(ScheduleEvent.user_id == user.id, ScheduleEvent.start_at >= datetime.utcnow()).order_by(ScheduleEvent.start_at).first()
    if upcoming:
        cards.append({"type": "schedule", "title": "Upcoming study session", "body": upcoming.title})
    if not cards:
        cards.append({"type": "welcome", "title": "Choose your next lesson", "body": "Start a lesson to build your learning history and recommendations."})
    return cards
