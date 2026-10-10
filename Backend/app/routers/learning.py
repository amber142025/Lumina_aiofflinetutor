from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import and_, desc
from datetime import datetime
import json
from ..db import get_db
from ..models.models import *
from ..schemas import ProgressIn,QuizSubmitIn,AssignmentSubmissionIn
from ..deps import current_user,require_roles

router=APIRouter(prefix="/api/v1/learning",tags=["learning"])

@router.get("/subjects")
def subjects(db=Depends(get_db),user=Depends(current_user)):
    return [{"id":x.id,"name":x.name,"code":x.code} for x in db.query(Subject).all()]

@router.get("/courses")
def courses(db=Depends(get_db),user=Depends(current_user)):
    return [{"id":x.id,"subject_id":x.subject_id,"title":x.title,"level":x.level,"description":x.description,"published":x.published} for x in db.query(Course).filter(Course.published==True).all()]

@router.post("/courses/{course_id}/enroll",status_code=201)
def enroll(course_id:int,db=Depends(get_db),user=Depends(require_roles("student"))):
    course=db.query(Course).filter_by(id=course_id,published=True).first()
    if not course: raise HTTPException(404,"Published course not found")
    row=db.query(CourseEnrollment).filter_by(user_id=user.id,course_id=course.id).first()
    if not row:
        row=CourseEnrollment(user_id=user.id,course_id=course.id)
        db.add(row)
        db.commit()
    return {"course_id":course.id,"enrolled":True,"enrolled_at":row.enrolled_at.isoformat()}

@router.get("/enrollments")
def enrollments(db=Depends(get_db),user=Depends(current_user)):
    return [{"course_id":c.id,"title":c.title} for c in db.query(Course).join(
        CourseEnrollment,CourseEnrollment.course_id==Course.id
    ).filter(CourseEnrollment.user_id==user.id).order_by(Course.title).all()]

@router.get("/assignments")
def student_assignments(db=Depends(get_db),user=Depends(require_roles("student"))):
    rows=db.query(Assignment,Course,AssignmentSubmission).join(
        AssignmentCourse,AssignmentCourse.assignment_id==Assignment.id
    ).join(Course,Course.id==AssignmentCourse.course_id).join(
        CourseEnrollment,CourseEnrollment.course_id==Course.id
    ).outerjoin(AssignmentSubmission,and_(
        AssignmentSubmission.assignment_id==Assignment.id,
        AssignmentSubmission.user_id==user.id
    )).filter(CourseEnrollment.user_id==user.id).order_by(Assignment.due_at,Assignment.id).all()
    return [{
        "id":a.id,"course_id":c.id,"course_title":c.title,"title":a.title,
        "description":a.description,"due_at":a.due_at.isoformat() if a.due_at else None,
        "submission":None if s is None else {
            "id":s.id,"response":s.response,"submitted_at":s.submitted_at.isoformat(),
            "grade":s.grade,"feedback":s.feedback
        }
    } for a,c,s in rows]

@router.post("/assignments/{assignment_id}/submit")
def submit_assignment(assignment_id:int,x:AssignmentSubmissionIn,db=Depends(get_db),user=Depends(require_roles("student"))):
    assignment=db.query(Assignment).join(
        AssignmentCourse,AssignmentCourse.assignment_id==Assignment.id
    ).join(CourseEnrollment,CourseEnrollment.course_id==AssignmentCourse.course_id).filter(
        Assignment.id==assignment_id,CourseEnrollment.user_id==user.id
    ).first()
    if not assignment: raise HTTPException(404,"Assignment not found for an enrolled course")
    row=db.query(AssignmentSubmission).filter_by(assignment_id=assignment.id,user_id=user.id).first()
    if row:
        row.response=x.response.strip()
        row.submitted_at=datetime.utcnow()
        row.grade=None
        row.feedback=""
    else:
        row=AssignmentSubmission(assignment_id=assignment.id,user_id=user.id,response=x.response.strip())
        db.add(row)
    db.commit()
    return {"id":row.id,"submitted_at":row.submitted_at.isoformat(),"grade":row.grade,"feedback":row.feedback}

@router.get("/courses/{course_id}/units")
def units(course_id:int,db=Depends(get_db),user=Depends(current_user)):
    return [{"id":x.id,"course_id":x.course_id,"title":x.title,"order":x.order_index} for x in db.query(Unit).filter(Unit.course_id==course_id).order_by(Unit.order_index).all()]

@router.get("/units/{unit_id}/lessons")
def lessons(unit_id:int,db=Depends(get_db),user=Depends(current_user)):
    return [{"id":x.id,"unit_id":x.unit_id,"title":x.title,"summary":x.summary,"offline_available":x.offline_available} for x in db.query(Lesson).filter(Lesson.unit_id==unit_id).order_by(Lesson.order_index).all()]

@router.get("/lessons/{lesson_id}")
def lesson(lesson_id:int,db=Depends(get_db),user=Depends(current_user)):
    l=db.get(Lesson,lesson_id)
    if not l: raise HTTPException(404,"Lesson not found")
    media=db.query(Media).filter(Media.lesson_id==l.id).all()
    quiz=db.query(Quiz).filter(Quiz.lesson_id==l.id).first()
    qs=db.query(Question).filter(Question.quiz_id==quiz.id).all() if quiz else []
    prog=db.query(LessonProgress).filter_by(user_id=user.id,lesson_id=l.id).first()
    return {"lesson":{"id":l.id,"title":l.title,"summary":l.summary,"offline_available":l.offline_available},
            "media":[{"id":m.id,"title":m.title,"media_type":m.media_type,"url":m.url,"duration_seconds":m.duration_seconds,"downloadable":m.downloadable} for m in media],
            "quiz":None if not quiz else {"id":quiz.id,"title":quiz.title,"difficulty":quiz.difficulty,
              "questions":[{"id":q.id,"prompt":q.prompt} for q in qs]},
            "progress":None if not prog else {"progress":prog.progress,"completed":prog.completed,"last_position":prog.last_position}}

@router.post("/progress")
def progress(x:ProgressIn,db=Depends(get_db),user=Depends(current_user)):
    row=db.query(LessonProgress).filter_by(user_id=user.id,lesson_id=x.lesson_id).first()
    if not row: row=LessonProgress(user_id=user.id,lesson_id=x.lesson_id); db.add(row)
    row.progress=x.progress; row.completed=x.completed or x.progress>=1; row.last_position=x.last_position; row.updated_at=datetime.utcnow()
    db.commit()
    return {"ok":True,"progress":row.progress,"completed":row.completed}

@router.get("/progress")
def all_progress(db=Depends(get_db),user=Depends(current_user)):
    rows=db.query(LessonProgress).filter_by(user_id=user.id).all()
    return [{"lesson_id":r.lesson_id,"progress":r.progress,"completed":r.completed,"last_position":r.last_position,"updated_at":r.updated_at.isoformat()} for r in rows]

@router.post("/quiz/submit")
def quiz_submit(x:QuizSubmitIn,db=Depends(get_db),user=Depends(current_user)):
    qs=db.query(Question).filter(Question.quiz_id==x.quiz_id).all()
    if not qs: raise HTTPException(404,"Quiz not found")
    correct=sum(1 for q in qs if x.answers.get(str(q.id),"").strip().lower()==q.answer.strip().lower())
    score=correct/len(qs)
    db.add(QuizAttempt(user_id=user.id,quiz_id=x.quiz_id,score=score,answers_json=json.dumps(x.answers)))
    topic=f"quiz:{x.quiz_id}"
    m=db.query(Mastery).filter_by(user_id=user.id,topic=topic).first()
    if not m: m=Mastery(user_id=user.id,topic=topic); db.add(m)
    m.score=score;m.attempts+=1;m.updated_at=datetime.utcnow()
    db.commit()
    return {"score":score,"correct":correct,"total":len(qs)}

@router.get("/mastery")
def mastery(db=Depends(get_db),user=Depends(current_user)):
    return [{"topic":m.topic,"score":m.score,"attempts":m.attempts} for m in db.query(Mastery).filter_by(user_id=user.id).all()]
