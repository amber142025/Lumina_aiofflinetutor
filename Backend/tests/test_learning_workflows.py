import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db import Base, get_db
from app.deps import current_user
from app.main import app
from app.models.models import Role, Subject, User, UserRole


@pytest.fixture
def client():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    TestingSession = sessionmaker(
        bind=engine, autoflush=False, autocommit=False, expire_on_commit=False
    )
    Base.metadata.create_all(bind=engine)
    db = TestingSession()
    roles = {}
    for role_name in (
        "student",
        "teacher",
        "parent",
        "manager",
        "content_manager",
        "admin",
    ):
        role = Role(name=role_name)
        db.add(role)
        roles[role_name] = role
    db.flush()
    users = {}
    for role_name in roles:
        user = User(
            username=role_name,
            email=f"{role_name}@example.test",
            display_name=role_name.title(),
            password_hash="unused",
        )
        db.add(user)
        db.flush()
        db.add(UserRole(user_id=user.id, role_id=roles[role_name].id))
        users[role_name] = user
    subject = Subject(name="Science", code="SCI")
    db.add(subject)
    db.commit()
    selected_user = {"value": users["content_manager"]}

    def override_db():
        session = TestingSession()
        try:
            yield session
        finally:
            session.close()

    def override_user():
        return selected_user["value"]

    app.dependency_overrides[get_db] = override_db
    app.dependency_overrides[current_user] = override_user
    try:
        with TestClient(app) as test_client:
            test_client.test_users = users
            test_client.test_subject_id = subject.id
            test_client.selected_test_user = selected_user
            yield test_client
    finally:
        app.dependency_overrides.clear()
        db.close()
        Base.metadata.drop_all(bind=engine)
        engine.dispose()


def create_course(client):
    response = client.post(
        "/api/v1/management/courses",
        json={
            "subject_id": client.test_subject_id,
            "title": "Foundations of Science",
            "level": "Beginner",
            "description": "A course for the workflow test.",
            "units": [
                {
                    "title": "First steps",
                    "lessons": [
                        {
                            "title": "Matter",
                            "summary": "Explore matter and its properties.",
                            "quiz": {
                                "title": "Matter check",
                                "questions": [
                                    {
                                        "prompt": "What is matter?",
                                        "answer": "anything with mass",
                                        "explanation": "Matter has mass and occupies space.",
                                    }
                                ],
                            },
                        }
                    ],
                }
            ],
        },
    )
    assert response.status_code == 201, response.text
    return response.json()["id"]


def test_course_enrollment_assignment_submission_and_grading(client):
    course_id = create_course(client)

    client.selected_test_user["value"] = client.test_users["student"]
    enrolled = client.post(f"/api/v1/learning/courses/{course_id}/enroll")
    assert enrolled.status_code == 201, enrolled.text
    assert enrolled.json()["enrolled"] is True
    assert client.post(f"/api/v1/learning/courses/{course_id}/enroll").status_code == 201

    client.selected_test_user["value"] = client.test_users["teacher"]
    created = client.post(
        "/api/v1/management/teacher/assignments",
        json={
            "course_id": course_id,
            "title": "Explain matter",
            "description": "Describe matter in your own words.",
        },
    )
    assert created.status_code == 201, created.text
    assignment_id = created.json()["id"]

    client.selected_test_user["value"] = client.test_users["student"]
    assignments = client.get("/api/v1/learning/assignments")
    assert assignments.status_code == 200
    assert assignments.json()[0]["id"] == assignment_id
    submitted = client.post(
        f"/api/v1/learning/assignments/{assignment_id}/submit",
        json={"response": "Matter has mass and occupies space."},
    )
    assert submitted.status_code == 200, submitted.text

    client.selected_test_user["value"] = client.test_users["teacher"]
    submissions = client.get(
        f"/api/v1/management/teacher/assignments/{assignment_id}/submissions"
    )
    assert submissions.status_code == 200
    submission_id = submissions.json()[0]["id"]
    graded = client.patch(
        f"/api/v1/management/teacher/assignments/{assignment_id}/submissions/{submission_id}",
        json={"grade": 95, "feedback": "Clear explanation."},
    )
    assert graded.status_code == 200
    assert graded.json()["grade"] == 95

    client.selected_test_user["value"] = client.test_users["student"]
    learner_view = client.get("/api/v1/learning/assignments").json()[0]
    assert learner_view["submission"]["grade"] == 95
    assert learner_view["submission"]["feedback"] == "Clear explanation."


def test_enrollment_and_assignment_are_scoped_to_enrolled_students(client):
    course_id = create_course(client)
    client.selected_test_user["value"] = client.test_users["teacher"]
    assignment = client.post(
        "/api/v1/management/teacher/assignments",
        json={"course_id": course_id, "title": "Work", "description": "Do the work."},
    )
    assert assignment.status_code == 201

    client.selected_test_user["value"] = client.test_users["student"]
    response = client.post(
        f"/api/v1/learning/assignments/{assignment.json()['id']}/submit",
        json={"response": "I did the work."},
    )
    assert response.status_code == 404
    assert client.get("/api/v1/learning/assignments").json() == []


def test_role_settings_persist_and_reject_other_role_preferences(client):
    client.selected_test_user["value"] = client.test_users["teacher"]
    saved = client.put(
        "/api/v1/auth/settings",
        json={
            "weekly_summary": False,
            "role_notifications": {"assignment_updates": False},
        },
    )
    assert saved.status_code == 200, saved.text
    assert saved.json()["weekly_summary"] is False
    assert saved.json()["role_notifications"]["assignment_updates"] is False
    assert client.get("/api/v1/auth/settings").json() == saved.json()

    denied = client.put(
        "/api/v1/auth/settings",
        json={"role_notifications": {"security_updates": False}},
    )
    assert denied.status_code == 422


def test_course_creation_requires_content_manager_role(client):
    client.selected_test_user["value"] = client.test_users["student"]
    response = client.post(
        "/api/v1/management/courses",
        json={
            "subject_id": client.test_subject_id,
            "title": "Unauthorized",
            "level": "Beginner",
            "description": "Must not be created.",
            "units": [{"title": "Unit", "lessons": [{
                "title": "Lesson",
                "summary": "Lesson text",
                "quiz": {"title": "Quiz", "questions": [
                    {"prompt": "Question?", "answer": "Answer"}
                ]},
            }]}],
        },
    )
    assert response.status_code == 403


def test_dashboard_and_settings_are_available_for_every_supported_role(client):
    for role_name in (
        "student",
        "teacher",
        "parent",
        "manager",
        "content_manager",
        "admin",
    ):
        client.selected_test_user["value"] = client.test_users[role_name]
        dashboard = client.get("/api/v1/management/dashboard")
        assert dashboard.status_code == 200, dashboard.text
        assert role_name in dashboard.json()["roles"]
        assert dashboard.json()["metrics"]

        preferences = client.get("/api/v1/auth/settings")
        assert preferences.status_code == 200, preferences.text
        assert preferences.json()["role_notifications"]


def test_manager_can_provision_parent_learner_link(client):
    client.selected_test_user["value"] = client.test_users["manager"]
    link = {
        "parent_id": client.test_users["parent"].id,
        "child_id": client.test_users["student"].id,
    }
    response = client.post("/api/v1/management/parent/children", json=link)
    assert response.status_code == 201, response.text
    assert client.post("/api/v1/management/parent/children", json=link).status_code == 201

    client.selected_test_user["value"] = client.test_users["parent"]
    children = client.get("/api/v1/management/parent/children")
    assert children.status_code == 200
    assert len(children.json()) == 1
    assert children.json()[0]["id"] == link["child_id"]

    client.selected_test_user["value"] = client.test_users["student"]
    denied = client.post("/api/v1/management/parent/children", json=link)
    assert denied.status_code == 403
