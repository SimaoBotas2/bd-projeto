# Academic Management API

REST API for managing an academic institution, built with Flask and PostgreSQL. It uses JWT authentication and three roles: **staff**, **instructor** and **student**.

University project for the *Bases de Dados* (Databases) course, Computer Engineering (LEI), University of Coimbra.

## Features

- Login with JWT (1 hour expiry) and role-based access control
- Registration of students, staff and instructors (staff only); passwords stored hashed with bcrypt
- Enrollment in degrees, course editions (with classes) and extracurricular activities
- Grade submission by the course coordinator
- Student academic record, degree statistics, top 3 students, best student per district, monthly approvals report
- Deletion of a student's details

## Architecture

- `api.py`: Flask app with all endpoints, the JWT/role decorators and the PostgreSQL access (psycopg2)
- `struct/schema.sql`: database schema
- `grant_all.sql`: privileges for the application's database user
- `config.txt`: database credentials (not tracked; copy from `config.example.txt`)

### Data model

Simplified overview, built from the table names in `schema.sql`.

```mermaid
erDiagram
    PERSON ||--o| STUDENT : is
    PERSON ||--o| STAFF : is
    PERSON ||--o| INSTRUCTOR : is
    STUDENT }o--o{ DEGREE : student_degree
    DEGREE }o--o{ COURSE : course_degree
    COURSE ||--o{ COURSE_EDITION : has
    STUDENT }o--o{ COURSE_EDITION : student_course
    COURSE_EDITION ||--o{ CLASS : has
    STUDENT }o--o{ ACTIVITY : student_activity
```

## Tech Stack

Python · Flask · PostgreSQL (psycopg2) · PyJWT · bcrypt

## API

All endpoints except login require `Authorization: Bearer <token>`.

| Method | Endpoint | Role | Description |
|---|---|---|---|
| PUT | `/dbproj/user` | any | Login, returns a JWT |
| POST | `/dbproj/register/student` | staff | Register a student |
| POST | `/dbproj/register/staff` | staff | Register a staff member |
| POST | `/dbproj/register/instructor` | staff | Register an instructor |
| POST | `/dbproj/enroll_degree/<id>` | staff | Enroll a student in a degree |
| POST | `/dbproj/enroll_activity/<id>` | student | Enroll in an activity |
| POST | `/dbproj/enroll_course_edition/<id>` | student | Enroll in a course edition and its classes |
| POST | `/dbproj/submit_grades/<id>` | instructor | Submit grades (course coordinator only) |
| GET | `/dbproj/student_details/<id>` | staff, student | Student academic record |
| GET | `/dbproj/degree_details/<id>` | staff | Degree statistics |
| GET | `/dbproj/top3` | staff | Top 3 students of the year |
| GET | `/dbproj/top_by_district/` | staff | Best student per district |
| GET | `/dbproj/report` | staff | Monthly approvals report |
| DELETE | `/dbproj/delete_details/<id>` | staff | Delete a student's details |

## Getting Started

### Prerequisites

- Python 3.11+ (the code uses `datetime.UTC`)
- PostgreSQL

### Installation

```bash
pip install -r requirements.txt
createdb dbproj
psql -d dbproj -f struct/schema.sql
psql -d dbproj -f grant_all.sql
cp config.example.txt config.txt   # then edit with your credentials
```

### Usage

```bash
export JWT_SECRET_KEY="a-long-random-string"
python api.py
```

The server runs on `http://127.0.0.1:8080`.

## Technical highlights

The reporting endpoints use more advanced SQL: CTEs, `JSON_AGG` and `generate_series` (monthly report).

## Authors

Simão Carvalho · University of Coimbra · Computer Engineering
