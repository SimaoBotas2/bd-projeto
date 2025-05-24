##
## =============================================
## ============== Bases de Dados ===============
## ============== LEI  2024/2025 ===============
## =============================================
## =================== Demo ====================
## =============================================
## =============================================
## === Department of Informatics Engineering ===
## =========== University of Coimbra ===========
## =============================================
##
## Authors:
##   João R. Campos <jrcampos@dei.uc.pt>
##   Nuno Antunes <nmsa@dei.uc.pt>
##   University of Coimbra


import flask
from flask import g
import logging
import psycopg2
import time
import random
from datetime import datetime,timedelta,UTC
import jwt
from functools import wraps

app = flask.Flask(__name__)
app.config['JWT_SECRET_KEY'] = 'some_jwt_secret_key'

StatusCodes = {
    'success': 200,
    'api_error': 400,
    'internal_error': 500,
    'unauthorized': 401
}


##########################################################
## DATABASE ACCESS
##########################################################

def db_connection():



    db = psycopg2.connect(

        #Falta mudar isto para um ficheiro
        user='aulaspl',
        password='aulaspl',
        host='127.0.0.1',
        port='5432',
        database='dbproject'
    )

    return db

##########################################################
## AUTHENTICATION HELPERS
##########################################################


from flask import g, request, jsonify
from functools import wraps
import jwt

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({
                'status': StatusCodes['unauthorized'],
                'errors': 'Token is missing!',
                'results': None
            }), 401
        
        token = auth_header.replace("Bearer ", "").strip()
        try:
            data = jwt.decode(token, app.config['JWT_SECRET_KEY'], algorithms=['HS256'])
            
            # Store the whole token payload in g.user
            g.user = data
            
            if not g.user.get('user_id'):
                raise jwt.InvalidTokenError("Missing user_id in token")

        except jwt.ExpiredSignatureError:
            return jsonify({
                'status': StatusCodes['unauthorized'],
                'errors': 'Token expired',
                'results': None
            }), 401
        except jwt.InvalidTokenError as e:
            return jsonify({
                'status': StatusCodes['unauthorized'],
                'errors': f'Invalid token: {str(e)}',
                'results': None
            }), 401

        return f(*args, **kwargs)
    return decorated


def role_required(allowed_roles):
    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            user = getattr(g, 'user', {})
            role = user.get('role')
            if role not in allowed_roles:
                return flask.jsonify({
                    'status': 403,
                    'errors': 'Permission denied',
                    'results': None
                }), 403
            return f(*args, **kwargs)
        return wrapper
    return decorator


##########################################################
## ENDPOINTS
##########################################################

@app.route('/dbproj/user', methods=['PUT'])
def login_user():
    data = flask.request.get_json()
    username = data.get('email')
    password = data.get('password')

    if not username or not password:
        return flask.jsonify({
            'status': StatusCodes['api_error'],
            'errors': 'Email and password are required',
            'results': None
        })

    try:
        conn = db_connection()
        cur = conn.cursor()

        query = """
            SELECT id, name, email, password,  
        CASE
        WHEN EXISTS (SELECT 1 FROM instructor i WHERE i.person_id = p.id) THEN 'instructor'
        WHEN EXISTS (SELECT 1 FROM staff s WHERE s.person_id = p.id) THEN 'staff'
        WHEN EXISTS (SELECT 1 FROM student st WHERE st.person_id = p.id) THEN 'student'
        ELSE 'unknown'
        END AS role
        FROM person p
        WHERE email = %s;
        """
        cur.execute(query, (username,))
        user = cur.fetchone()

        if not user:
            return flask.jsonify({
                'status': StatusCodes['unauthorized'],
                'errors': 'User not found',
                'results': None
            })

        db_password = user[3]
        if db_password != password:
            return flask.jsonify({
                'status': StatusCodes['unauthorized'],
                'errors': 'Invalid password',
                'results': None
            })

        role = user[4]

        token_payload = {
            'user_id': user[0],  
            'role': role,
            'exp': datetime.now(UTC) + timedelta(hours=1)
        }

        token = jwt.encode(token_payload, app.config['JWT_SECRET_KEY'], algorithm='HS256')
        response = {
            'status': StatusCodes['success'],
            'errors': None,
            'results': token
        }

    except (Exception, psycopg2.DatabaseError) as error:
        response = {
            'status': StatusCodes['internal_error'],
            'errors': str(error),
            'results': None
        }
    finally:
        if conn:
            conn.close()

    return flask.jsonify(response)


@app.route('/dbproj/register/student', methods=['POST'])
@token_required
@role_required(['staff'])
def register_student():
    data = flask.request.get_json()
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')
    district = data.get('district')

    if not username or not email or not password or not district:
        return flask.jsonify({'status': StatusCodes['api_error'], 'errors': 'Username, email, password, and district are required', 'results': None})

    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute(
        """
        INSERT INTO person (name, email, password)
        VALUES (%s, %s, %s)
        RETURNING id
        """,
        (username, email, password)
        )
        person_id = cur.fetchone()[0]

        cur.execute(
        """
        INSERT INTO student (person_id, district)
        VALUES (%s, %s)
        """,
        (person_id, district)
    )

        conn.commit()

        return flask.jsonify({'status': StatusCodes['success'], 'errors': None, 'results': person_id})

    except Exception as error:
        conn.rollback()
        return flask.jsonify({'status': StatusCodes['internal_error'], 'errors': str(error), 'results': None})

    finally:
        if conn:
            conn.close()

@app.route('/dbproj/register/staff', methods=['POST'])
@token_required
@role_required(['staff'])
def register_staff():
    data = flask.request.get_json()
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')

    if not username or not email or not password:
        return flask.jsonify({
            'status': StatusCodes['api_error'],
            'errors': 'Username, email, and password are required',
            'results': None
        })

    try:
        conn = db_connection()
        cur = conn.cursor()

        # Inserção em person
        cur.execute(
            """
            INSERT INTO person (name, email, password)
            VALUES (%s, %s, %s)
            RETURNING id
            """,
            (username, email, password)
        )
        person_id = cur.fetchone()[0]

        # Inserção em staff referenciando person
        cur.execute(
            """
            INSERT INTO staff (person_id)
            VALUES (%s)
            """,
            (person_id,)
        )

        conn.commit()
        return flask.jsonify({'status': StatusCodes['success'], 'errors': None, 'results': person_id})

    except Exception as error:
        conn.rollback()
        return flask.jsonify({
            'status': StatusCodes['internal_error'],
            'errors': str(error),
            'results': None
        })

    finally:
        if conn:
            conn.close()



@app.route('/dbproj/register/instructor', methods=['POST'])
@role_required(['staff'])
@token_required
def register_instructor():
    data = flask.request.get_json()
    username = data.get('username')
    email = data.get('email')
    password = data.get('password')

    if not username or not email or not password:
        return flask.jsonify({
            'status': StatusCodes['api_error'],
            'errors': 'Username, email, and password are required',
            'results': None
        })
    
    try:
        conn = db_connection()
        cur = conn.cursor()

        # 1. Inserir na tabela person
        cur.execute(
            """
            INSERT INTO person (name, email, password)
            VALUES (%s, %s, %s)
            RETURNING id
            """,
            (username, email, password)
        )
        person_id = cur.fetchone()[0]

        # 2. Inserir na tabela instructor
        cur.execute(
            """
            INSERT INTO instructor (person_id)
            VALUES (%s)
            """,
            (person_id,)
        )

        conn.commit()

        return flask.jsonify({
            'status': StatusCodes['success'],
            'errors': None,
            'results': person_id
        })

    except Exception as error:
        conn.rollback()
        return flask.jsonify({
            'status': StatusCodes['internal_error'],
            'errors': str(error),
            'results': None
        })

    finally:
        if conn:
            conn.close()


@app.route('/dbproj/enroll_degree/<degree_id>', methods=['POST'])
@token_required
@role_required(['staff'])
def enroll_degree(degree_id):
    data = flask.request.get_json()
    student_id = data.get('student_id')
    date = data.get('date')

    if not student_id or not date:
        return flask.jsonify({'status': StatusCodes['api_error'], 'errors': 'Student ID and date are required', 'results': None})
    
    try:
        conn = db_connection()
        cur = conn.cursor()

        # Inserção na tabela de associação
        cur.execute("""
            INSERT INTO student_degree (student_id, degree_ndegree, start_date)
            VALUES (%s, %s, %s)
        """, (student_id, degree_id, date))

        conn.commit()

        return flask.jsonify({
            'status': StatusCodes['success'],
            'errors': None,
            'results': f"Student {student_id} enrolled in degree {degree_id} on {date}"
        })

    except Exception as e:
        conn.rollback()
        return flask.jsonify({
            'status': StatusCodes['internal_error'],
            'errors': str(e),
            'results': None
        })

    finally:
        if conn:
            conn.close()

@app.route('/dbproj/enroll_activity/<int:activity_id>', methods=['POST'])
@token_required
@role_required(['student'])
def enroll_activity(activity_id):
    user_id = flask.g.user.get('user_id')  

    try:
        conn = db_connection()
        cur = conn.cursor()

        insert_query = """
            INSERT INTO student_activity (student_id, activity_id, enrollment_date)
            VALUES (%s, %s, CURRENT_TIMESTAMP)
            RETURNING id;
        """
        cur.execute(insert_query, (user_id, activity_id))
        enrollment_id = cur.fetchone()[0]
        conn.commit()

        response = {
            'status': StatusCodes['success'],
            'errors': None,
            'results': {'enrollment_id': enrollment_id}
        }
  
    except psycopg2.IntegrityError:
        conn.rollback()
        response = {
            'status': StatusCodes['api_error'],
            'errors': 'Enrollment already exists or invalid activity_id',
            'results': None
        }
    except Exception as e:
        response = {
            'status': StatusCodes['internal_error'],
            'errors': str(e),
            'results': None
        }
    finally:
        if conn:
            conn.close()    

    return flask.jsonify(response)


@app.route('/dbproj/enroll_course_edition/<int:course_edition_id>', methods=['POST'])
@token_required
@role_required(['student'])
def enroll_course_edition(course_edition_id):

    #falta confirmar se o estudante ja está inscrito na edição do curso
    #falta confirmar se as classes existem
    student_id = flask.g.user.get('user_id')
    data = flask.request.get_json()
    classes = data.get('classes', [])

    if not classes or not isinstance(classes, list):
        return flask.jsonify({
            'status': StatusCodes['api_error'],
            'errors': 'Classes list is required and must be a list',
            'results': None
        }), 400

    try:
        conn = db_connection()
        cur = conn.cursor()

        # Check student degree
        cur.execute("""
            SELECT DISTINCT sd.degree_ndegree
            FROM student_degree sd
            WHERE sd.student_id = %s
        """, (student_id,))
        student_degrees = {row[0] for row in cur.fetchall()}
        if not student_degrees:
            return flask.jsonify({
                'status': StatusCodes['forbidden'],
                'errors': 'Student is not enrolled in any degree',
                'results': None
            }), 403

        # Get course and its degree for this course_edition
        cur.execute("""
            SELECT c.ndegree
            FROM course_edition ce
            JOIN course c ON ce.course_ncourse = c.ncourse
            WHERE ce.id = %s
        """, (course_edition_id,))
        course_row = cur.fetchone()
        if not course_row:
            return flask.jsonify({
                'status': StatusCodes['api_error'],
                'errors': 'Course edition not found',
                'results': None
            }), 404

        course_degree = course_row[0]

        # Verify student is enrolled in course degree
        if course_degree not in student_degrees:
            return flask.jsonify({
                'status': StatusCodes['forbidden'],
                'errors': 'Student not enrolled in the degree of this course',
                'results': None
            }), 403

        # Enroll student in each class for this course edition
        # fazer verificação se a turma existe
        for class_id in classes:
            try:
                cur.execute("""
                    INSERT INTO student_course (student_id, course_edition_id, class_id)
                    VALUES (%s, %s, %s)
                    ON CONFLICT (student_id, course_edition_id, class_id) DO NOTHING
                """, (student_id, course_edition_id, class_id))
            except Exception as e:
                conn.rollback()
                return flask.jsonify({
                    'status': StatusCodes['internal_error'],
                    'errors': f'Failed to enroll in class {class_id}: {str(e)}',
                    'results': None
                }), 500

        conn.commit()
        return flask.jsonify({
            'status': StatusCodes['success'],
            'errors': None,
            'results': 'Enrollment successful'
        })

    except Exception as e:
        return flask.jsonify({
            'status': StatusCodes['internal_error'],
            'errors': str(e),
            'results': None
        }), 500
    finally:
        if conn:
            conn.close()

@app.route('/dbproj/submit_grades/<int:course_edition_id>', methods=['POST'])
@token_required
@role_required(['instructor'])
def submit_grades(course_edition_id):
    data = flask.request.get_json()
    period = data.get('period')
    grades = data.get('grades')

    if not period or not grades:
        return flask.jsonify({
            'status': StatusCodes['api_error'],
            'errors': 'Missing evaluation period or grades list',
            'results': None
        }), 400

    instructor_id = flask.g.user.get('user_id')

    try:
        conn = db_connection()
        cur = conn.cursor()

        # Pegar info do curso e coordenador
        cur.execute("""
            SELECT c.ncourse, c.ncoordinator
            FROM course_edition ce
            JOIN course c ON ce.course_ncourse = c.ncourse
            WHERE ce.id = %s
        """, (course_edition_id,))
        row = cur.fetchone()

        if not row:
            return flask.jsonify({
                'status': StatusCodes['api_error'],
                'errors': 'Course edition not found',
                'results': None
            }), 404

        course_ncourse, coordinator_id = row

        if coordinator_id != instructor_id:
            return flask.jsonify({
                'status': StatusCodes['forbidden'],
                'errors': 'Only the coordinator of this course can submit grades',
                'results': None
            }), 403

        # Loop para inserir/atualizar cada grade
        for student_id, grade in grades:
            # Buscar classe do estudante nessa edição do curso
            cur.execute("""
                SELECT class_id FROM student_course 
                WHERE student_id = %s AND course_edition_id = %s
            """, (student_id, course_edition_id))
            class_row = cur.fetchone()

            if not class_row:
                return flask.jsonify({
                    'status': StatusCodes['api_error'],
                    'errors': f'Missing class info for student {student_id}',
                    'results': None
                }), 400

            class_nclass = class_row[0]

            # Verificar se já existe nota para esse estudante, período e classe
            cur.execute("""
                SELECT 1 FROM student_grade 
                WHERE person_id = %s AND grade_season = %s AND class_nclass = %s
            """, (student_id, period, class_nclass))
            exists = cur.fetchone()

            if not exists:
                # Inserir nova nota, incluindo course_ncourse
                cur.execute("""
                    INSERT INTO student_grade (course_ncourse, grade_season, grade, class_nclass, person_id)
                    VALUES (%s, %s, %s, %s, %s)
                """, (course_ncourse, period, grade, class_nclass, student_id))
            else:
                # Atualizar nota existente
                cur.execute("""
                    UPDATE student_grade 
                    SET grade = %s, course_ncourse = %s
                    WHERE person_id = %s AND grade_season = %s AND class_nclass = %s
                """, (grade, course_ncourse, student_id, period, class_nclass))

            # Verificar/inserir na tabela course_student_grade para linkar curso e nota
            cur.execute("""
                SELECT 1 FROM course_student_grade
                WHERE course_ncourse = %s AND student_grade_person_id = %s AND course_edition_id = %s
            """, (course_ncourse, student_id, course_edition_id))
            link_exists = cur.fetchone()

            if not link_exists:
                cur.execute("""
                    INSERT INTO course_student_grade (course_ncourse, student_grade_person_id, course_edition_id)
                    VALUES (%s, %s, %s)
                """, (course_ncourse, student_id, course_edition_id))

        conn.commit()
        return flask.jsonify({
            'status': StatusCodes['success'],
            'errors': None,
            'results': 'Grades submitted successfully'
        })

    except Exception as e:
        conn.rollback()
        return flask.jsonify({
            'status': StatusCodes['internal_error'],
            'errors': str(e),
            'results': None
        }), 500
    finally:
        if conn:
            conn.close()



@app.route('/dbproj/student_details/<int:student_id>', methods=['GET'])
@token_required
@role_required(['staff', 'student'])
def student_details(student_id):
    user_id = flask.g.user.get('user_id')
    user_role = flask.g.user.get('role')

    if user_role != 'staff' and user_id != student_id:
        return flask.jsonify({
            'status': StatusCodes['forbidden'],
            'errors': 'Access denied',
            'results': None
        }), 403

    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute("""
            SELECT DISTINCT
                ce.id AS course_edition_id,
                c.name AS course_name,
                ce.year AS course_edition_year,
                sg.grade,
                ce.start_date
            FROM student_course sc
            JOIN course_edition ce ON sc.course_edition_id = ce.id
            JOIN course c ON ce.course_ncourse = c.ncourse
            LEFT JOIN student_grade sg ON sg.person_id = sc.student_id
                AND sg.course_ncourse = ce.course_ncourse
            WHERE sc.student_id = %s
            ORDER BY ce.start_date DESC
        """, (student_id,))

        rows = cur.fetchall()

        results = []
        for row in rows:
            course_edition_id, course_name, course_edition_year, grade, _start_date = row
            results.append({
                'course_edition_id': course_edition_id,
                'course_name': course_name,
                'course_edition_year': course_edition_year,
                'grade': grade
            })

        return flask.jsonify({
            'status': StatusCodes['success'],
            'errors': None,
            'results': results
        })

    except Exception as e:
        return flask.jsonify({
            'status': StatusCodes['internal_error'],
            'errors': str(e),
            'results': None
        }), 500
    finally:
        if conn:
            conn.close()


@app.route('/dbproj/degree_details/<int:degree_id>', methods=['GET'])
@token_required
@role_required(['staff'])
def degree_details(degree_id):
    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute("""
            SELECT 
                c.ncourse AS course_id,
                c.name AS course_name,
                ce.id AS course_edition_id,
                ce.year AS course_edition_year,
                ce.capacity,
                COUNT(DISTINCT sc.student_id) AS enrolled_count,
                COUNT(DISTINCT CASE 
                    WHEN sg.grade IS NOT NULL AND sg.grade >= 10 THEN sc.student_id 
                    END) AS approved_count,
                MIN(ic.instructor_person_id) AS coordinator_id, -- Placeholder for one coordinator
                ARRAY_AGG(DISTINCT ic.instructor_person_id) AS instructors
            FROM course c
            JOIN course_edition ce ON ce.course_ncourse = c.ncourse
            LEFT JOIN student_course sc ON sc.course_edition_id = ce.id
            LEFT JOIN student_grade sg ON sg.person_id = sc.student_id AND sg.course_ncourse = c.ncourse
            LEFT JOIN instructor_course ic ON ic.course_edition_id = ce.id
            WHERE c.ndegree = %s
            GROUP BY c.ncourse, c.name, ce.id, ce.year, ce.capacity
            ORDER BY ce.year DESC, ce.start_date DESC
        """, (degree_id,))

        rows = cur.fetchall()

        results = []
        for row in rows:
            (course_id, course_name, course_edition_id, course_edition_year, capacity,
             enrolled_count, approved_count, coordinator_id, instructors) = row
            results.append({
                'course_id': course_id,
                'course_name': course_name,
                'course_edition_id': course_edition_id,
                'course_edition_year': course_edition_year,
                'capacity': capacity,
                'enrolled_count': enrolled_count,
                'approved_count': approved_count,
                'coordinator_id': coordinator_id,
                'instructors': instructors
            })

        return flask.jsonify({
            'status': StatusCodes['success'],
            'errors': None,
            'results': results
        })

    except Exception as e:
        return flask.jsonify({
            'status': StatusCodes['internal_error'],
            'errors': str(e),
            'results': None
        }), 500
    finally:
        if conn:
            conn.close()



@app.route('/dbproj/top3', methods=['GET'])
@token_required
@role_required(['staff'])
def top3_students():
    try:
        conn = db_connection()
        cur = conn.cursor()

        cur.execute("""WITH valid_grades AS (
    SELECT 
        p.id AS student_id,
        p.name AS student_name,
        sg.grade,
        ce.id AS course_edition_id,
        c.name AS course_edition_name,
        ce.start_date::DATE,
        EXTRACT(YEAR FROM ce.start_date)::INT AS year
    FROM student_grade sg
    JOIN person p ON p.id = sg.person_id
    JOIN course c ON c.ncourse = sg.course_ncourse
    JOIN course_edition ce ON ce.course_ncourse = c.ncourse
    WHERE EXTRACT(YEAR FROM ce.start_date) = EXTRACT(YEAR FROM CURRENT_DATE)
      AND sg.grade IS NOT NULL
),
student_avg AS (
    SELECT 
        student_id,
        student_name,
        ROUND(AVG(sg.grade)::numeric, 2) AS average_grade
    FROM valid_grades sg
    GROUP BY student_id, student_name
    ORDER BY average_grade DESC
    LIMIT 3
)
SELECT 
    sa.student_name,
    sa.average_grade,
    JSON_AGG(
        JSON_BUILD_OBJECT(
            'course_edition_id', vg.course_edition_id,
            'course_edition_name', vg.course_edition_name,
            'grade', vg.grade,
            'date', vg.start_date
        )
        ORDER BY vg.start_date DESC
    ) AS grades,
    (
        SELECT ARRAY_AGG(DISTINCT a.name)
        FROM student_activity sa2
        JOIN activity a ON sa2.activity_id = a.id
        WHERE sa2.student_id = sa.student_id
    ) AS activities
FROM student_avg sa
JOIN valid_grades vg ON vg.student_id = sa.student_id
GROUP BY sa.student_id, sa.student_name, sa.average_grade
ORDER BY sa.average_grade DESC;


    """)

        rows = cur.fetchall()
        results = []
        for row in rows:
            student_name, average_grade, grades, activities = row
            results.append({
                'student_name': student_name,
                'average_grade': average_grade,
                'grades': grades,
                'activities': activities
            })

        return flask.jsonify({
            'status': StatusCodes['success'],
            'errors': None,
            'results': results
        })

    except Exception as e:
        return flask.jsonify({
            'status': StatusCodes['internal_error'],
            'errors': str(e),
            'results': None
        }), 500
    finally:
        if conn:
            conn.close()


@app.route('/dbproj/top_by_district/', methods=['GET'])
@token_required
@role_required(['staff'])
def top_by_district():
    try:
        conn = db_connection()
        cur = conn.cursor()

        query = """
            WITH student_avg AS (
                SELECT 
                    p.id AS student_id,
                    s.district,
                    AVG(sg.grade) AS average_grade
                FROM student_grade sg
                JOIN person p ON p.id = sg.person_id
                JOIN student s ON s.person_id = p.id
                WHERE sg.grade IS NOT NULL
                GROUP BY p.id, s.district
            ),
            max_avg AS (
                SELECT district, MAX(average_grade) AS max_average
                FROM student_avg
                GROUP BY district
            )
            SELECT sa.student_id, sa.district, sa.average_grade
            FROM student_avg sa
            JOIN max_avg ma ON sa.district = ma.district AND sa.average_grade = ma.max_average
            ORDER BY sa.district;
        """

        cur.execute(query)
        rows = cur.fetchall()

        results = []
        for row in rows:
            student_id, district, average_grade = row
            results.append({
                "student_id": student_id,
                "district": district,
                "average_grade": float(average_grade)
            })

        return flask.jsonify({
            "status": StatusCodes['success'],
            "errors": None,
            "results": results
        })

    except Exception as e:
        return flask.jsonify({
            "status": StatusCodes['internal_error'],
            "errors": str(e),
            "results": None
        }), 500

    finally:
        if conn:
            conn.close()


@app.route('/dbproj/report', methods=['GET'])
@token_required
def monthly_report():

    resultReport = [ # TODO
        {
            'month': "month_0",
            'course_edition_id': random.randint(1, 200),
            'course_edition_name': "Some course",
            'approved': 20,
            'evaluated': 23
        },
        {
            'month': "month_1",
            'course_edition_id': random.randint(1, 200),
            'course_edition_name': "Another course",
            'approved': 200,
            'evaluated': 123
        }
    ]

    response = {'status': StatusCodes['success'], 'errors': None, 'results': resultReport}
    return flask.jsonify(response)

@app.route('/dbproj/delete_details/<student_id>', methods=['DELETE'])
@token_required
def delete_student(student_id):
    response = {'status': StatusCodes['success'], 'errors': None}
    return flask.jsonify(response)

if __name__ == '__main__':
    # set up logging
    logging.basicConfig(filename='log_file.log')
    logger = logging.getLogger('logger')
    logger.setLevel(logging.DEBUG)
    ch = logging.StreamHandler()
    ch.setLevel(logging.DEBUG)

    # create formatter
    formatter = logging.Formatter('%(asctime)s [%(levelname)s]:  %(message)s', '%H:%M:%S')
    ch.setFormatter(formatter)
    logger.addHandler(ch)

    host = '127.0.0.1'
    port = 8080
    logger.info(f'API stubs online: http://{host}:{port}')
    app.run(host=host, debug=True, threaded=True, port=port)

