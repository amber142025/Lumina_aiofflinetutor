-- PostgreSQL-compatible conceptual schema.
-- The FastAPI application creates the same schema through SQLAlchemy.
CREATE TABLE users (id SERIAL PRIMARY KEY, username VARCHAR(80) UNIQUE NOT NULL, email VARCHAR(255) UNIQUE NOT NULL,
password_hash VARCHAR(512) NOT NULL, display_name VARCHAR(120) NOT NULL, is_active BOOLEAN DEFAULT TRUE, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE roles (id SERIAL PRIMARY KEY, name VARCHAR(50) UNIQUE NOT NULL);
CREATE TABLE permissions (id SERIAL PRIMARY KEY, name VARCHAR(100) UNIQUE NOT NULL);
CREATE TABLE user_roles (id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id), role_id INT REFERENCES roles(id));
CREATE TABLE role_permissions (id SERIAL PRIMARY KEY, role_id INT REFERENCES roles(id), permission_id INT REFERENCES permissions(id));
CREATE TABLE refresh_tokens (id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id), token_hash VARCHAR(128) UNIQUE NOT NULL,
family_id VARCHAR(64) NOT NULL, expires_at TIMESTAMP NOT NULL, revoked BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE audit_logs (id SERIAL PRIMARY KEY, user_id INT NULL REFERENCES users(id), action VARCHAR(120), detail TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);
CREATE TABLE subjects (id SERIAL PRIMARY KEY, name VARCHAR(120), code VARCHAR(50) UNIQUE);
CREATE TABLE courses (id SERIAL PRIMARY KEY, subject_id INT REFERENCES subjects(id), title VARCHAR(200), level VARCHAR(80), description TEXT, published BOOLEAN DEFAULT TRUE);
CREATE TABLE units (id SERIAL PRIMARY KEY, course_id INT REFERENCES courses(id), title VARCHAR(200), order_index INT);
CREATE TABLE lessons (id SERIAL PRIMARY KEY, unit_id INT REFERENCES units(id), title VARCHAR(200), summary TEXT, order_index INT, offline_available BOOLEAN DEFAULT TRUE);
CREATE TABLE media (id SERIAL PRIMARY KEY, lesson_id INT REFERENCES lessons(id), title VARCHAR(200), media_type VARCHAR(30), url TEXT, duration_seconds INT, downloadable BOOLEAN DEFAULT TRUE);
CREATE TABLE quizzes (id SERIAL PRIMARY KEY, lesson_id INT REFERENCES lessons(id), title VARCHAR(200), difficulty VARCHAR(30));
CREATE TABLE questions (id SERIAL PRIMARY KEY, quiz_id INT REFERENCES quizzes(id), prompt TEXT, answer VARCHAR(255), explanation TEXT);
CREATE TABLE lesson_progress (id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id), lesson_id INT REFERENCES lessons(id), progress DOUBLE PRECISION,
completed BOOLEAN DEFAULT FALSE, last_position INT DEFAULT 0, updated_at TIMESTAMP, UNIQUE(user_id,lesson_id));
CREATE TABLE mastery (id SERIAL PRIMARY KEY, user_id INT REFERENCES users(id), topic VARCHAR(160), score DOUBLE PRECISION, attempts INT, updated_at TIMESTAMP);
CREATE TABLE course_enrollments (id SERIAL PRIMARY KEY, user_id INT NOT NULL REFERENCES users(id),
course_id INT NOT NULL REFERENCES courses(id), enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
UNIQUE(user_id, course_id));
CREATE TABLE assignments (id SERIAL PRIMARY KEY, teacher_id INT NOT NULL REFERENCES users(id),
title VARCHAR(200) NOT NULL, description TEXT NOT NULL, due_at TIMESTAMP NULL);
CREATE TABLE assignment_courses (id SERIAL PRIMARY KEY, assignment_id INT UNIQUE NOT NULL REFERENCES assignments(id),
course_id INT NOT NULL REFERENCES courses(id));
CREATE TABLE assignment_submissions (id SERIAL PRIMARY KEY, assignment_id INT NOT NULL REFERENCES assignments(id),
user_id INT NOT NULL REFERENCES users(id), response TEXT NOT NULL, submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
grade DOUBLE PRECISION NULL, feedback TEXT NOT NULL DEFAULT '', UNIQUE(assignment_id, user_id));
CREATE TABLE user_settings (id SERIAL PRIMARY KEY, user_id INT UNIQUE NOT NULL REFERENCES users(id),
weekly_summary BOOLEAN NOT NULL DEFAULT TRUE, study_reminders BOOLEAN NOT NULL DEFAULT TRUE,
role_notifications_json TEXT NOT NULL DEFAULT '{}');
CREATE TABLE parent_child (id SERIAL PRIMARY KEY, parent_id INT NOT NULL REFERENCES users(id),
child_id INT NOT NULL REFERENCES users(id), UNIQUE(parent_id, child_id));
