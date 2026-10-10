from datetime import datetime
from pydantic import BaseModel, EmailStr, Field
from typing import Optional, Any

class RegisterIn(BaseModel):
    username: str = Field(min_length=3,max_length=80)
    email: EmailStr
    display_name: str = Field(min_length=2,max_length=120)
    password: str = Field(min_length=8,max_length=128)
    confirm_password: str
    role: str = "student"
    invitation_code: Optional[str]=None

class LoginIn(BaseModel):
    identifier: str
    password: str

class RefreshIn(BaseModel):
    refresh_token: str

class ProgressIn(BaseModel):
    lesson_id: int
    progress: float = Field(ge=0,le=1)
    completed: bool=False
    last_position: int=Field(default=0,ge=0)

class QuizSubmitIn(BaseModel):
    quiz_id: int
    answers: dict[str,str]

class QuizQuestionCreateIn(BaseModel):
    prompt: str = Field(min_length=3, max_length=2000)
    answer: str = Field(min_length=1, max_length=255)
    explanation: str = Field(default="", max_length=4000)

class QuizCreateIn(BaseModel):
    title: str = Field(min_length=2, max_length=200)
    difficulty: str = Field(default="adaptive", max_length=30)
    questions: list[QuizQuestionCreateIn] = Field(min_length=1, max_length=50)

class LessonCreateIn(BaseModel):
    title: str = Field(min_length=2, max_length=200)
    summary: str = Field(min_length=1, max_length=4000)
    quiz: QuizCreateIn

class UnitCreateIn(BaseModel):
    title: str = Field(min_length=2, max_length=200)
    lessons: list[LessonCreateIn] = Field(min_length=1, max_length=50)

class CourseCreateIn(BaseModel):
    subject_id: int = Field(gt=0)
    title: str = Field(min_length=2, max_length=200)
    level: str = Field(min_length=1, max_length=80)
    description: str = Field(min_length=1, max_length=4000)
    units: list[UnitCreateIn] = Field(min_length=1, max_length=50)

class AssignmentCreateIn(BaseModel):
    course_id: int = Field(gt=0)
    title: str = Field(min_length=2, max_length=200)
    description: str = Field(min_length=1, max_length=4000)
    due_at: datetime | None = None

class AssignmentSubmissionIn(BaseModel):
    response: str = Field(min_length=1, max_length=10000)

class AssignmentGradeIn(BaseModel):
    grade: float = Field(ge=0, le=100)
    feedback: str = Field(default="", max_length=4000)

class ParentChildLinkIn(BaseModel):
    parent_id: int = Field(gt=0)
    child_id: int = Field(gt=0)

class SettingsUpdateIn(BaseModel):
    weekly_summary: bool | None = None
    study_reminders: bool | None = None
    role_notifications: dict[str, bool] | None = None

class SyncItem(BaseModel):
    type: str
    payload: dict[str,Any]

class SyncIn(BaseModel):
    items: list[SyncItem]

class TutorIn(BaseModel):
    message: str
    context: dict[str,Any]={}
