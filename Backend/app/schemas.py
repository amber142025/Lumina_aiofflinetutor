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

class SyncItem(BaseModel):
    type: str
    payload: dict[str,Any]

class SyncIn(BaseModel):
    items: list[SyncItem]

class TutorIn(BaseModel):
    message: str
    context: dict[str,Any]={}
