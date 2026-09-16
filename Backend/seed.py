from app.db import Base,engine,SessionLocal
from app.models.models import *
from app.security import hash_password
from datetime import datetime,timedelta

Base.metadata.create_all(bind=engine)
db=SessionLocal()

roles=["student","teacher","parent","manager","content_manager","admin"]
perms=["learning.read","learning.write","progress.read","progress.write","class.manage","students.read",
       "assignments.manage","analytics.read","children.read","content.manage","users.manage","roles.manage",
       "system.manage","audit.read","schedule.read","schedule.write","notifications.read"]
for r in roles:
    if not db.query(Role).filter_by(name=r).first(): db.add(Role(name=r))
for p in perms:
    if not db.query(Permission).filter_by(name=p).first(): db.add(Permission(name=p))
db.commit()
allroles={r.name:r for r in db.query(Role).all()}
allperms={p.name:p for p in db.query(Permission).all()}
role_perm={
"student":["learning.read","progress.read","progress.write","schedule.read","notifications.read"],
"teacher":["learning.read","progress.read","progress.write","class.manage","students.read","assignments.manage","analytics.read","schedule.read","schedule.write","notifications.read"],
"parent":["learning.read","progress.read","children.read","schedule.read","notifications.read"],
"manager":["learning.read","progress.read","students.read","analytics.read","schedule.read","notifications.read"],
"content_manager":["learning.read","content.manage","schedule.read","notifications.read"],
"admin":list(allperms.keys())
}
for rn,names in role_perm.items():
    for pn in names:
        if not db.query(RolePermission).filter_by(role_id=allroles[rn].id,permission_id=allperms[pn].id).first():
            db.add(RolePermission(role_id=allroles[rn].id,permission_id=allperms[pn].id))
for code,role in [("TEACH-LUMINA","teacher"),("PARENT-LUMINA","parent"),("MANAGE-LUMINA","manager"),("CONTENT-LUMINA","content_manager")]:
    if not db.query(Invitation).filter_by(code=code).first(): db.add(Invitation(code=code,role_name=role))
db.commit()

def user(username,email,name,password,role):
    u=db.query(User).filter_by(username=username).first()
    if not u:
        u=User(username=username,email=email,display_name=name,password_hash=hash_password(password));db.add(u);db.flush()
        db.add(UserRole(user_id=u.id,role_id=allroles[role].id))
    return u
student=user("student","student@lumina.app","Lumina Student","Lumina@123","student")
teacher=user("teacher","teacher@lumina.app","Lumina Teacher","Lumina@123","teacher")
parent=user("parent","parent@lumina.app","Lumina Parent","Lumina@123","parent")
manager=user("manager","manager@lumina.app","Lumina Manager","Lumina@123","manager")
content=user("content","content@lumina.app","Lumina Content Manager","Lumina@123","content_manager")
admin=user("admin","admin@lumina.app","Lumina Admin","Lumina@123","admin")

if not db.query(Subject).count():
    subjects=[("English","ENG"),("Chinese","CHN"),("Japanese","JPN"),("IGCSE Mathematics","IG-MATH"),("IGCSE Physics","IG-PHY")]
    for n,c in subjects: db.add(Subject(name=n,code=c))
    db.commit()
    eng=db.query(Subject).filter_by(code="ENG").first()
    course=Course(subject_id=eng.id,title="English Foundations",level="Basic → Intermediate",
                  description="Original representative course covering vocabulary, grammar and communication.",published=True)
    db.add(course);db.flush()
    u=Unit(course_id=course.id,title="Unit 1 — Everyday Communication",order_index=1);db.add(u);db.flush()
    lessons=[
        Lesson(unit_id=u.id,title="Introducing Yourself",summary="Practice basic introductions and useful expressions.",order_index=1,offline_available=True),
        Lesson(unit_id=u.id,title="Daily Routines",summary="Learn vocabulary and sentence patterns for daily activities.",order_index=2,offline_available=True),
        Lesson(unit_id=u.id,title="Listening for Key Details",summary="Practice identifying important information in short conversations.",order_index=3,offline_available=True)
    ]
    for l in lessons: db.add(l)
    db.flush()
    for i,l in enumerate(lessons):
        db.add(Media(lesson_id=l.id,title=f"{l.title} video",media_type="video",
                     url="https://storage.googleapis.com/coverr-main/mp4/Mt_Baker.mp4",
                     duration_seconds=120,downloadable=True))
        q=Quiz(lesson_id=l.id,title=f"{l.title} Quick Check",difficulty="adaptive");db.add(q);db.flush()
        if i==0:
            db.add(Question(quiz_id=q.id,prompt="What is a natural greeting?",answer="hello",explanation="Hello is a common greeting."))
            db.add(Question(quiz_id=q.id,prompt="Complete: My name ___ Anna.",answer="is",explanation="Use 'is' with 'my name'."))
        elif i==1:
            db.add(Question(quiz_id=q.id,prompt="Which word describes something done every day?",answer="daily",explanation="Daily means happening every day."))
            db.add(Question(quiz_id=q.id,prompt="Complete: I ___ breakfast at 7.",answer="eat",explanation="Eat is the verb used here."))
        else:
            db.add(Question(quiz_id=q.id,prompt="What should you identify first in listening?",answer="key details",explanation="Focus on the key details."))
            db.add(Question(quiz_id=q.id,prompt="Listening for key details is a useful ___ skill.",answer="study",explanation="It is a study skill."))
    db.commit()

if not db.query(ScheduleEvent).filter_by(user_id=student.id).count():
    now=datetime.utcnow()
    db.add(ScheduleEvent(user_id=student.id,title="7-minute English practice",start_at=now+timedelta(hours=2),event_type="study"))
    db.add(Notification(user_id=student.id,title="Welcome to Lumina",body="Your offline-first learning journey is ready."))
    db.commit()
db.close()
print("Lumina database seeded.")
