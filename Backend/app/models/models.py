from datetime import datetime
from sqlalchemy import String, Integer, Boolean, DateTime, ForeignKey, Text, Float, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column
from ..db import Base

class User(Base):
    __tablename__="users"
    id: Mapped[int]=mapped_column(primary_key=True)
    username: Mapped[str]=mapped_column(String(80), unique=True, index=True)
    email: Mapped[str]=mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str]=mapped_column(String(512))
    display_name: Mapped[str]=mapped_column(String(120))
    is_active: Mapped[bool]=mapped_column(Boolean, default=True)
    created_at: Mapped[datetime]=mapped_column(DateTime, default=datetime.utcnow)

class Role(Base):
    __tablename__="roles"
    id: Mapped[int]=mapped_column(primary_key=True)
    name: Mapped[str]=mapped_column(String(50), unique=True)

class Permission(Base):
    __tablename__="permissions"
    id: Mapped[int]=mapped_column(primary_key=True)
    name: Mapped[str]=mapped_column(String(100), unique=True)

class UserRole(Base):
    __tablename__="user_roles"
    id: Mapped[int]=mapped_column(primary_key=True)
    user_id: Mapped[int]=mapped_column(ForeignKey("users.id"), index=True)
    role_id: Mapped[int]=mapped_column(ForeignKey("roles.id"), index=True)

class RolePermission(Base):
    __tablename__="role_permissions"
    id: Mapped[int]=mapped_column(primary_key=True)
    role_id: Mapped[int]=mapped_column(ForeignKey("roles.id"))
    permission_id: Mapped[int]=mapped_column(ForeignKey("permissions.id"))

class RefreshToken(Base):
    __tablename__="refresh_tokens"
    id: Mapped[int]=mapped_column(primary_key=True)
    user_id: Mapped[int]=mapped_column(ForeignKey("users.id"), index=True)
    token_hash: Mapped[str]=mapped_column(String(128), unique=True)
    family_id: Mapped[str]=mapped_column(String(64), index=True)
    expires_at: Mapped[datetime]=mapped_column(DateTime)
    revoked: Mapped[bool]=mapped_column(Boolean, default=False)
    created_at: Mapped[datetime]=mapped_column(DateTime, default=datetime.utcnow)

class AuditLog(Base):
    __tablename__="audit_logs"
    id: Mapped[int]=mapped_column(primary_key=True)
    user_id: Mapped[int|None]=mapped_column(ForeignKey("users.id"), nullable=True)
    action: Mapped[str]=mapped_column(String(120))
    detail: Mapped[str]=mapped_column(Text, default="")
    created_at: Mapped[datetime]=mapped_column(DateTime, default=datetime.utcnow)

class Invitation(Base):
    __tablename__="invitations"
    id: Mapped[int]=mapped_column(primary_key=True)
    code: Mapped[str]=mapped_column(String(80), unique=True)
    role_name: Mapped[str]=mapped_column(String(50))
    active: Mapped[bool]=mapped_column(Boolean, default=True)

class Subject(Base):
    __tablename__="subjects"
    id: Mapped[int]=mapped_column(primary_key=True)
    name: Mapped[str]=mapped_column(String(120))
    code: Mapped[str]=mapped_column(String(50), unique=True)

class Course(Base):
    __tablename__="courses"
    id: Mapped[int]=mapped_column(primary_key=True)
    subject_id: Mapped[int]=mapped_column(ForeignKey("subjects.id"))
    title: Mapped[str]=mapped_column(String(200))
    level: Mapped[str]=mapped_column(String(80))
    description: Mapped[str]=mapped_column(Text)
    published: Mapped[bool]=mapped_column(Boolean, default=True)

class Unit(Base):
    __tablename__="units"
    id: Mapped[int]=mapped_column(primary_key=True)
    course_id: Mapped[int]=mapped_column(ForeignKey("courses.id"))
    title: Mapped[str]=mapped_column(String(200))
    order_index: Mapped[int]=mapped_column(Integer, default=1)

class Lesson(Base):
    __tablename__="lessons"
    id: Mapped[int]=mapped_column(primary_key=True)
    unit_id: Mapped[int]=mapped_column(ForeignKey("units.id"))
    title: Mapped[str]=mapped_column(String(200))
    summary: Mapped[str]=mapped_column(Text)
    order_index: Mapped[int]=mapped_column(Integer, default=1)
    offline_available: Mapped[bool]=mapped_column(Boolean, default=True)

class Media(Base):
    __tablename__="media"
    id: Mapped[int]=mapped_column(primary_key=True)
    lesson_id: Mapped[int]=mapped_column(ForeignKey("lessons.id"))
    title: Mapped[str]=mapped_column(String(200))
    media_type: Mapped[str]=mapped_column(String(30), default="video")
    url: Mapped[str]=mapped_column(Text)
    duration_seconds: Mapped[int]=mapped_column(Integer, default=0)
    downloadable: Mapped[bool]=mapped_column(Boolean, default=True)

class Quiz(Base):
    __tablename__="quizzes"
    id: Mapped[int]=mapped_column(primary_key=True)
    lesson_id: Mapped[int]=mapped_column(ForeignKey("lessons.id"))
    title: Mapped[str]=mapped_column(String(200))
    difficulty: Mapped[str]=mapped_column(String(30), default="adaptive")

class Question(Base):
    __tablename__="questions"
    id: Mapped[int]=mapped_column(primary_key=True)
    quiz_id: Mapped[int]=mapped_column(ForeignKey("quizzes.id"))
    prompt: Mapped[str]=mapped_column(Text)
    answer: Mapped[str]=mapped_column(String(255))
    explanation: Mapped[str]=mapped_column(Text, default="")

class QuizAttempt(Base):
    __tablename__="quiz_attempts"
    id: Mapped[int]=mapped_column(primary_key=True)
    user_id: Mapped[int]=mapped_column(ForeignKey("users.id"))
    quiz_id: Mapped[int]=mapped_column(ForeignKey("quizzes.id"))
    score: Mapped[float]=mapped_column(Float)
    answers_json: Mapped[str]=mapped_column(Text)
    created_at: Mapped[datetime]=mapped_column(DateTime, default=datetime.utcnow)

class LessonProgress(Base):
    __tablename__="lesson_progress"
    id: Mapped[int]=mapped_column(primary_key=True)
    user_id: Mapped[int]=mapped_column(ForeignKey("users.id"))
    lesson_id: Mapped[int]=mapped_column(ForeignKey("lessons.id"))
    progress: Mapped[float]=mapped_column(Float, default=0)
    completed: Mapped[bool]=mapped_column(Boolean, default=False)
    last_position: Mapped[int]=mapped_column(Integer, default=0)
    updated_at: Mapped[datetime]=mapped_column(DateTime, default=datetime.utcnow)
    __table_args__=(UniqueConstraint("user_id","lesson_id",name="uq_user_lesson"),)

class Mastery(Base):
    __tablename__="mastery"
    id: Mapped[int]=mapped_column(primary_key=True)
    user_id: Mapped[int]=mapped_column(ForeignKey("users.id"))
    topic: Mapped[str]=mapped_column(String(160))
    score: Mapped[float]=mapped_column(Float, default=0)
    attempts: Mapped[int]=mapped_column(Integer, default=0)
    updated_at: Mapped[datetime]=mapped_column(DateTime, default=datetime.utcnow)

class Assignment(Base):
    __tablename__="assignments"
    id: Mapped[int]=mapped_column(primary_key=True)
    teacher_id: Mapped[int]=mapped_column(ForeignKey("users.id"))
    title: Mapped[str]=mapped_column(String(200))
    description: Mapped[str]=mapped_column(Text)
    due_at: Mapped[datetime|None]=mapped_column(DateTime, nullable=True)

class ScheduleEvent(Base):
    __tablename__="schedule_events"
    id: Mapped[int]=mapped_column(primary_key=True)
    user_id: Mapped[int]=mapped_column(ForeignKey("users.id"))
    title: Mapped[str]=mapped_column(String(200))
    start_at: Mapped[datetime]=mapped_column(DateTime)
    end_at: Mapped[datetime|None]=mapped_column(DateTime, nullable=True)
    event_type: Mapped[str]=mapped_column(String(40), default="study")

class Notification(Base):
    __tablename__="notifications"
    id: Mapped[int]=mapped_column(primary_key=True)
    user_id: Mapped[int]=mapped_column(ForeignKey("users.id"))
    title: Mapped[str]=mapped_column(String(200))
    body: Mapped[str]=mapped_column(Text)
    read: Mapped[bool]=mapped_column(Boolean, default=False)
    created_at: Mapped[datetime]=mapped_column(DateTime, default=datetime.utcnow)

class ParentChild(Base):
    __tablename__="parent_child"
    id: Mapped[int]=mapped_column(primary_key=True)
    parent_id: Mapped[int]=mapped_column(ForeignKey("users.id"))
    child_id: Mapped[int]=mapped_column(ForeignKey("users.id"))

class Message(Base):
    __tablename__="messages"
    id: Mapped[int]=mapped_column(primary_key=True)
    sender_id: Mapped[int]=mapped_column(ForeignKey("users.id"))
    recipient_id: Mapped[int]=mapped_column(ForeignKey("users.id"))
    body: Mapped[str]=mapped_column(Text)
    created_at: Mapped[datetime]=mapped_column(DateTime, default=datetime.utcnow)
    read: Mapped[bool]=mapped_column(Boolean, default=False)
