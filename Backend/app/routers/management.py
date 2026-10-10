from fastapi import APIRouter,Depends,HTTPException
from sqlalchemy import and_
from sqlalchemy.orm import Session
from ..db import get_db
from ..deps import require_roles,current_user,roles_for
from ..models.models import (
    Assignment,AssignmentCourse,AssignmentSubmission,Course,CourseEnrollment,
    Lesson,LessonProgress,Notification,ParentChild,Question,Quiz,Role,
    ScheduleEvent,Subject,Unit,User,UserRole,
)
from ..schemas import (
    AssignmentCreateIn,AssignmentGradeIn,CourseCreateIn,ParentChildLinkIn,
)

router=APIRouter(prefix="/api/v1/management",tags=["management"])

@router.get("/users")
def users(db=Depends(get_db),user=Depends(require_roles("admin","manager"))):
    return [{
        "id":u.id,"username":u.username,"email":u.email,
        "display_name":u.display_name,"active":u.is_active,
        "roles":roles_for(u,db),
    } for u in db.query(User).order_by(User.display_name).all()]

@router.get("/courses")
def manage_courses(db=Depends(get_db),user=Depends(require_roles("admin","content_manager"))):
    return [{"id":c.id,"title":c.title,"level":c.level,"description":c.description,
             "published":c.published,"subject_id":c.subject_id} for c in db.query(Course).order_by(Course.id.desc()).all()]

@router.post("/courses",status_code=201)
def create_course(x:CourseCreateIn,db=Depends(get_db),user=Depends(require_roles("admin","content_manager"))):
    if not db.get(Subject,x.subject_id):
        raise HTTPException(404,"Subject not found")
    course=Course(subject_id=x.subject_id,title=x.title.strip(),level=x.level.strip(),
                  description=x.description.strip(),published=True)
    db.add(course)
    db.flush()
    for unit_index,unit_in in enumerate(x.units,1):
        unit=Unit(course_id=course.id,title=unit_in.title.strip(),order_index=unit_index)
        db.add(unit)
        db.flush()
        for lesson_index,lesson_in in enumerate(unit_in.lessons,1):
            lesson=Lesson(unit_id=unit.id,title=lesson_in.title.strip(),
                          summary=lesson_in.summary.strip(),order_index=lesson_index,
                          offline_available=True)
            db.add(lesson)
            db.flush()
            quiz=Quiz(lesson_id=lesson.id,title=lesson_in.quiz.title.strip(),
                      difficulty=lesson_in.quiz.difficulty.strip())
            db.add(quiz)
            db.flush()
            for question_in in lesson_in.quiz.questions:
                db.add(Question(quiz_id=quiz.id,prompt=question_in.prompt.strip(),
                                answer=question_in.answer.strip(),
                                explanation=question_in.explanation.strip()))
    db.commit()
    return {"id":course.id,"title":course.title,"published":course.published}

@router.get("/teacher/assignments")
def assignments(db=Depends(get_db),user=Depends(require_roles("teacher"))):
    rows=db.query(Assignment,AssignmentCourse.course_id,Course.title).outerjoin(
        AssignmentCourse,AssignmentCourse.assignment_id==Assignment.id
    ).outerjoin(Course,Course.id==AssignmentCourse.course_id).filter(
        Assignment.teacher_id==user.id
    ).order_by(Assignment.id.desc()).all()
    return [{
        "id":a.id,"title":a.title,"description":a.description,
        "due_at":a.due_at.isoformat() if a.due_at else None,
        "course_id":course_id,"course_title":course_title,
        "submission_count":db.query(AssignmentSubmission).filter_by(assignment_id=a.id).count()
    } for a,course_id,course_title in rows]

@router.post("/teacher/assignments",status_code=201)
def create_assignment(x:AssignmentCreateIn,db=Depends(get_db),user=Depends(require_roles("teacher"))):
    course=db.query(Course).filter_by(id=x.course_id,published=True).first()
    if not course:
        raise HTTPException(404,"Published course not found")
    assignment=Assignment(teacher_id=user.id,title=x.title.strip(),
                          description=x.description.strip(),due_at=x.due_at)
    db.add(assignment)
    db.flush()
    db.add(AssignmentCourse(assignment_id=assignment.id,course_id=course.id))
    db.commit()
    return {"id":assignment.id,"course_id":course.id,"title":assignment.title}

@router.get("/teacher/assignments/{assignment_id}/submissions")
def assignment_submissions(assignment_id:int,db=Depends(get_db),user=Depends(require_roles("teacher"))):
    assignment=db.query(Assignment).filter_by(id=assignment_id,teacher_id=user.id).first()
    if not assignment:
        raise HTTPException(404,"Assignment not found")
    rows=db.query(AssignmentSubmission,User).join(
        User,User.id==AssignmentSubmission.user_id
    ).filter(AssignmentSubmission.assignment_id==assignment.id).order_by(
        AssignmentSubmission.submitted_at.desc()
    ).all()
    return [{
        "id":s.id,"student_id":student.id,"student_name":student.display_name,
        "response":s.response,"submitted_at":s.submitted_at.isoformat(),
        "grade":s.grade,"feedback":s.feedback
    } for s,student in rows]

@router.patch("/teacher/assignments/{assignment_id}/submissions/{submission_id}")
def grade_submission(assignment_id:int,submission_id:int,x:AssignmentGradeIn,
                     db=Depends(get_db),user=Depends(require_roles("teacher"))):
    assignment=db.query(Assignment).filter_by(id=assignment_id,teacher_id=user.id).first()
    if not assignment:
        raise HTTPException(404,"Assignment not found")
    submission=db.query(AssignmentSubmission).filter_by(
        id=submission_id,assignment_id=assignment.id
    ).first()
    if not submission:
        raise HTTPException(404,"Submission not found")
    submission.grade=x.grade
    submission.feedback=x.feedback.strip()
    db.commit()
    return {"id":submission.id,"grade":submission.grade,"feedback":submission.feedback}

@router.get("/parent/children")
def parent_children(db=Depends(get_db),user=Depends(require_roles("parent"))):
    rows=db.query(User).join(ParentChild,ParentChild.child_id==User.id).filter(
        ParentChild.parent_id==user.id
    ).order_by(User.display_name).all()
    return [{
        "id":child.id,"display_name":child.display_name,
        "completed_lessons":db.query(LessonProgress).filter_by(
            user_id=child.id,completed=True
        ).count(),
        "course_count":db.query(CourseEnrollment).filter_by(user_id=child.id).count()
    } for child in rows]

@router.post("/parent/children",status_code=201)
def link_parent_child(x:ParentChildLinkIn,db=Depends(get_db),user=Depends(require_roles("admin","manager"))):
    parent=db.get(User,x.parent_id)
    child=db.get(User,x.child_id)
    if not parent or not child:
        raise HTTPException(404,"Parent or learner account not found")
    parent_has_role=db.query(UserRole).join(Role,Role.id==UserRole.role_id).filter(
        UserRole.user_id==parent.id,Role.name=="parent"
    ).first()
    child_has_role=db.query(UserRole).join(Role,Role.id==UserRole.role_id).filter(
        UserRole.user_id==child.id,Role.name=="student"
    ).first()
    if not parent_has_role or not child_has_role:
        raise HTTPException(400,"Link a parent account to a student account")
    if parent.id==child.id:
        raise HTTPException(400,"An account cannot be linked to itself")
    link=db.query(ParentChild).filter_by(parent_id=parent.id,child_id=child.id).first()
    if not link:
        link=ParentChild(parent_id=parent.id,child_id=child.id)
        db.add(link)
        db.commit()
    return {"parent_id":parent.id,"child_id":child.id,"linked":True}

@router.delete("/parent/children/{parent_id}/{child_id}")
def unlink_parent_child(parent_id:int,child_id:int,db=Depends(get_db),user=Depends(require_roles("admin","manager"))):
    link=db.query(ParentChild).filter_by(parent_id=parent_id,child_id=child_id).first()
    if not link:
        raise HTTPException(404,"Parent-learner link not found")
    db.delete(link)
    db.commit()
    return {"child_id":child_id,"unlinked":True}

@router.get("/dashboard")
def dashboard(db=Depends(get_db),user=Depends(current_user)):
    role_names={r.name for r in db.query(Role).join(UserRole,Role.id==UserRole.role_id).filter(UserRole.user_id==user.id).all()}
    if "teacher" in role_names:
        assignment_count=db.query(Assignment).filter_by(teacher_id=user.id).count()
        pending=db.query(AssignmentSubmission).join(
            Assignment,Assignment.id==AssignmentSubmission.assignment_id
        ).filter(Assignment.teacher_id==user.id,AssignmentSubmission.grade.is_(None)).count()
        metrics=[{"label":"Assignments","value":assignment_count},{"label":"To review","value":pending}]
    elif "parent" in role_names:
        child_count=db.query(ParentChild).filter_by(parent_id=user.id).count()
        metrics=[{"label":"Linked learners","value":child_count}]
    elif "student" in role_names:
        enrolled=db.query(CourseEnrollment).filter_by(user_id=user.id).count()
        completed=db.query(LessonProgress).filter_by(user_id=user.id,completed=True).count()
        assignments=db.query(AssignmentCourse).join(
            CourseEnrollment,CourseEnrollment.course_id==AssignmentCourse.course_id
        ).outerjoin(AssignmentSubmission,and_(
            AssignmentSubmission.assignment_id==AssignmentCourse.assignment_id,
            AssignmentSubmission.user_id==user.id
        )).filter(CourseEnrollment.user_id==user.id,AssignmentSubmission.id.is_(None)).count()
        metrics=[{"label":"Enrolled courses","value":enrolled},
                 {"label":"Lessons completed","value":completed},
                 {"label":"Open assignments","value":assignments}]
    elif "content_manager" in role_names:
        metrics=[{"label":"Courses","value":db.query(Course).count()},
                 {"label":"Published","value":db.query(Course).filter_by(published=True).count()},
                 {"label":"Drafts","value":db.query(Course).filter_by(published=False).count()}]
    elif "manager" in role_names or "admin" in role_names:
        metrics=[{"label":"Active users","value":db.query(User).filter_by(is_active=True).count()},
                 {"label":"Students", "value":db.query(User.id).join(UserRole).join(Role).filter(Role.name=="student").distinct().count()},
                 {"label":"Courses","value":db.query(Course).count()}]
    else:
        metrics=[]
    return {"roles":sorted(role_names),"metrics":metrics}

@router.get("/schedule")
def schedule(db=Depends(get_db),user=Depends(current_user)):
    return [{"id":s.id,"title":s.title,"start_at":s.start_at.isoformat(),"end_at":None if not s.end_at else s.end_at.isoformat(),"event_type":s.event_type} for s in db.query(ScheduleEvent).filter_by(user_id=user.id).all()]

@router.get("/notifications")
def notifications(db=Depends(get_db),user=Depends(current_user)):
    return [{"id":n.id,"title":n.title,"body":n.body,"read":n.read} for n in db.query(Notification).filter_by(user_id=user.id).all()]
