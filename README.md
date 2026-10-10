# Lumina — Offline AI Learning Tutor

A complete offline-first education platform prototype with Flutter mobile, FastAPI, PostgreSQL and SQLite.

## Core workflow

Authentication → Role workspace → Courses → Lessons → Video/Activities → Quiz → Progress → Mastery/Weak Areas → Revision → Proactive Tutor → Offline sync.

## Roles

Student, Teacher, Parent, Manager, Content Manager, Admin.

## Courses, assignments, and role workspaces

Content Managers (and Admins) can publish a course with its first unit, lesson, and auto-graded quick-check quiz. Students can enroll in published courses; teachers can post assignments to the enrolled course community, review submissions, and return a grade and feedback. Students see and submit work from the Tasks tab. Enrollments, assignments, submissions, grades, and account preferences are stored by the FastAPI service in the configured database.

Each signed-in role has a live dashboard and settings. Student summaries show course, lesson, and assignment activity; teacher summaries show assignment and review counts; family, content, manager, and admin workspaces show their available role-scoped data. Managers and Admins can link a parent account to a student account so the Parent workspace shows that learner's enrolled courses and completed lessons. Role-specific notification and weekly-summary preferences save to the account via the settings API.

Existing installations must apply the reviewed additions in `Database/schema.sql` (or an equivalent reviewed database migration) before deploying code that uses these new tables. Development databases created at application startup receive the models through SQLAlchemy `create_all`; production should use a versioned migration process.

## Offline-first behavior

Learning state, lessons, quizzes, tutor recommendations and progress are cached locally in SQLite. Changes are placed in a sync queue and sent to the backend when connectivity is available. Downloaded media is stored on-device and listed in My Downloads.

## Security

Argon2 password hashing, JWT access tokens, refresh token rotation/revocation, RBAC, granular permissions, request validation, rate limiting, audit logging, secure configuration, and object-level authorization.

## AI

The local tutor is deterministic and context-aware. The backend exposes `/api/v1/ai/chat` as an integration point for a production LLM. A production LLM is not claimed without provider credentials.

## Content

The seed database contains original representative learning content and curriculum structures. It does not include copyrighted Cambridge/Edexcel textbook/video content.
