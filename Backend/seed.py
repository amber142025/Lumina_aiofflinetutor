"""Local development seed only. Never run against a production environment."""
import os

from app.config import settings

if settings.app_env.lower() == "production":
    raise RuntimeError("Refusing to seed production. Create the first administrator through a one-time secure bootstrap process.")

# Seed data intentionally exists only for local development and automated tests.
# Do not expose the predictable development accounts or invitation codes publicly.
from app.db import Base, engine, SessionLocal
from app.models.models import *
from app.security import hash_password
from datetime import datetime, timedelta

if os.getenv("ALLOW_DEMO_SEED", "false").lower() != "true":
    raise RuntimeError("Development seed is disabled. Set ALLOW_DEMO_SEED=true only for a disposable local database.")

Base.metadata.create_all(bind=engine)
db = SessionLocal()

roles = ["student", "teacher", "parent", "manager", "content_manager", "admin"]
perms = ["learning.read", "learning.write", "progress.read", "progress.write", "class.manage", "students.read",
         "assignments.manage", "analytics.read", "children.read", "content.manage", "users.manage", "roles.manage",
         "system.manage", "audit.read", "schedule.read", "schedule.write", "notifications.read"]
for r in roles:
    if not db.query(Role).filter_by(name=r).first():
        db.add(Role(name=r))
for p in perms:
    if not db.query(Permission).filter_by(name=p).first():
        db.add(Permission(name=p))
db.commit()

allroles = {r.name: r for r in db.query(Role).all()}
allperms = {p.name: p for p in db.query(Permission).all()}
role_perm = {
    "student": ["learning.read", "progress.read", "progress.write", "schedule.read", "notifications.read"],
    "teacher": ["learning.read", "progress.read", "progress.write", "class.manage", "students.read", "assignments.manage", "analytics.read", "schedule.read", "schedule.write", "notifications.read"],
    "parent": ["learning.read", "progress.read", "children.read", "schedule.read", "notifications.read"],
    "manager": ["learning.read", "progress.read", "students.read", "analytics.read", "schedule.read", "notifications.read"],
    "content_manager": ["learning.read", "content.manage", "schedule.read", "notifications.read"],
    "admin": list(allperms.keys()),
}
for rn, names in role_perm.items():
    for pn in names:
        if not db.query(RolePermission).filter_by(role_id=allroles[rn].id, permission_id=allperms[pn].id).first():
            db.add(RolePermission(role_id=allroles[rn].id, permission_id=allperms[pn].id))
db.commit()

# Development-only role invitations are random per run and are never printed or committed.
import secrets
for role in ["teacher", "parent", "manager", "content_manager"]:
    code = os.getenv(f"DEV_INVITE_{role.upper()}", "")
    if code and not db.query(Invitation).filter_by(code=code).first():
        db.add(Invitation(code=code, role_name=role, active=True))
db.commit()

def user(username, email, name, password, role):
    existing = db.query(User).filter_by(username=username).first()
    if existing:
        return existing
    u = User(username=username, email=email, display_name=name, password_hash=hash_password(password))
    db.add(u)
    db.flush()
    db.add(UserRole(user_id=u.id, role_id=allroles[role].id))
    return u

# Optional local accounts must be explicitly configured; no hardcoded demo passwords.
seed_password = os.getenv("DEV_SEED_PASSWORD", "")
if seed_password:
    student = user("student", "student@localhost.invalid", "Local Student", seed_password, "student")
    db.commit()
else:
    student = None

if not db.query(Subject).count():
    subjects = [("English", "ENG"), ("Chinese", "CHN"), ("Japanese", "JPN"), ("IGCSE Mathematics", "IG-MATH"), ("IGCSE Physics", "IG-PHY")]
    for n, c in subjects:
        db.add(Subject(name=n, code=c))
    db.commit()
    eng = db.query(Subject).filter_by(code="ENG").first()
    course = Course(subject_id=eng.id, title="English Foundations", level="Basic → Intermediate",
                    description="Original representative course covering vocabulary, grammar and communication.", published=True)
    db.add(course)
    db.flush()
    unit = Unit(course_id=course.id, title="Unit 1 — Everyday Communication", order_index=1)
    db.add(unit)
    db.flush()
    lessons = [
        Lesson(unit_id=unit.id, title="Introducing Yourself", summary="Practice basic introductions and useful expressions.", order_index=1, offline_available=True),
        Lesson(unit_id=unit.id, title="Daily Routines", summary="Learn vocabulary and sentence patterns for daily activities.", order_index=2, offline_available=True),
        Lesson(unit_id=unit.id, title="Listening for Key Details", summary="Practice identifying important information in short conversations.", order_index=3, offline_available=True),
    ]
    for lesson in lessons:
        db.add(lesson)
    db.flush()
    for index, lesson in enumerate(lessons):
        db.add(Media(lesson_id=lesson.id, title=f"{lesson.title} video", media_type="video",
                     url="https://storage.googleapis.com/coverr-main/mp4/Mt_Baker.mp4", duration_seconds=120, downloadable=True))
        quiz = Quiz(lesson_id=lesson.id, title=f"{lesson.title} Quick Check", difficulty="adaptive")
        db.add(quiz)
        db.flush()
        pairs = [
            [("What is a natural greeting?", "hello", "Hello is a common greeting."), ("Complete: My name ___ Anna.", "is", "Use 'is' with 'my name'.")],
            [("Which word describes something done every day?", "daily", "Daily means happening every day."), ("Complete: I ___ breakfast at 7.", "eat", "Eat is the verb used here.")],
            [("What should you identify first in listening?", "key details", "Focus on the key details."), ("Listening for key details is a useful ___ skill.", "study", "It is a study skill.")],
        ][index]
        for prompt, answer, explanation in pairs:
            db.add(Question(quiz_id=quiz.id, prompt=prompt, answer=answer, explanation=explanation))
    db.commit()

if student and not db.query(ScheduleEvent).filter_by(user_id=student.id).count():
    now = datetime.utcnow()
    db.add(ScheduleEvent(user_id=student.id, title="7-minute English practice", start_at=now + timedelta(hours=2), event_type="study"))
    db.add(Notification(user_id=student.id, title="Welcome to Lumina", body="Your offline-first learning journey is ready."))
    db.commit()
db.close()
print("Local development seed completed.")
