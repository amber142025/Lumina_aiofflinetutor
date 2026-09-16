# Lumina — Offline AI Learning Tutor

A complete offline-first education platform prototype with Flutter mobile, FastAPI, PostgreSQL and SQLite.

## Core workflow

Authentication → Role workspace → Courses → Lessons → Video/Activities → Quiz → Progress → Mastery/Weak Areas → Revision → Proactive Tutor → Offline sync.

## Roles

Student, Teacher, Parent, Manager, Content Manager, Admin.

## Offline-first behavior

Learning state, lessons, quizzes, tutor recommendations and progress are cached locally in SQLite. Changes are placed in a sync queue and sent to the backend when connectivity is available. Downloaded media is stored on-device and listed in My Downloads.

## Security

Argon2 password hashing, JWT access tokens, refresh token rotation/revocation, RBAC, granular permissions, request validation, rate limiting, audit logging, secure configuration, and object-level authorization.

## AI

The local tutor is deterministic and context-aware. The backend exposes `/api/v1/ai/chat` as an integration point for a production LLM. A production LLM is not claimed without provider credentials.

## Content

The seed database contains original representative learning content and curriculum structures. It does not include copyrighted Cambridge/Edexcel textbook/video content.
