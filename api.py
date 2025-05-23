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


def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = flask.request.headers.get('Authorization')
        logger.info(f'token: {token}')

        if not token:
            return flask.jsonify({
                'status': StatusCodes['unauthorized'],
                'errors': 'Token is missing!',
                'results': None
            }), 401

        try:
            token = token.replace("Bearer ", "")
            data = jwt.decode(token, app.config['JWT_SECRET_KEY'], algorithms=['HS256'])
            
            # Guardar user_id e role no contexto da request
            g.user_id = data.get('user_id')
            g.role = data.get('role')

            if not g.user_id:
                raise jwt.InvalidTokenError("Missing user_id in token")

        except jwt.ExpiredSignatureError:
            return flask.jsonify({
                'status': StatusCodes['unauthorized'],
                'errors': 'Token expired',
                'results': None
            }), 401
        except jwt.InvalidTokenError as e:
            return flask.jsonify({
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
            role = getattr(g, 'role', None)
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

@app.route('/dbproj/enroll_activity/<activity_id>', methods=['POST'])
@token_required
@role_required(['student'])
def enroll_activity(activity_id):
    response = {'status': StatusCodes['success'], 'errors': None}
    return flask.jsonify(response)

    # TODO falta atuazlizar a tabela de atividades, atualizar tambem a tabela de pagamentos

@app.route('/dbproj/enroll_course_edition/<course_edition_id>', methods=['POST'])
@token_required
def enroll_course_edition(course_edition_id):
    data = flask.request.get_json()
    classes = data.get('classes', [])

    if not classes:
        return flask.jsonify({'status': StatusCodes['api_error'], 'errors': 'At least one class ID is required', 'results': None})
    
    response = {'status': StatusCodes['success'], 'errors': None}
    return flask.jsonify(response)

@app.route('/dbproj/submit_grades/<course_edition_id>', methods=['POST'])
@token_required
def submit_grades(course_edition_id):
    data = flask.request.get_json()
    period = data.get('period')
    grades = data.get('grades', [])

    if not period or not grades:
        return flask.jsonify({'status': StatusCodes['api_error'], 'errors': 'Evaluation period and grades are required', 'results': None})
    
    response = {'status': StatusCodes['success'], 'errors': None}
    return flask.jsonify(response)

@app.route('/dbproj/student_details/<student_id>', methods=['GET'])
@token_required
def student_details(student_id):

    resultStudentDetails = [ # TODO
        {
            'course_edition_id': random.randint(1, 200),
            'course_name': "some course",
            'course_edition_year': 2024,
            'grade': 12
        },
        {
            'course_edition_id': random.randint(1, 200),
            'course_name': "another course",
            'course_edition_year': 2025,
            'grade': 17
        }
    ]

    response = {'status': StatusCodes['success'], 'errors': None, 'results': resultStudentDetails}
    return flask.jsonify(response)

@app.route('/dbproj/degree_details/<degree_id>', methods=['GET'])
@token_required
def degree_details(degree_id):

    resultDegreeDetails = [ # TODO
        {
            'course_id': random.randint(1, 200),
            'course_name': "some coure",
            'course_edition_id': random.randint(1, 200),
            'course_edition_year': 2023,
            'capacity': 30,
            'enrolled_count': 27,
            'approved_count': 20,
            'coordinator_id': random.randint(1, 200),
            'instructors': [random.randint(1, 200), random.randint(1, 200)]
        }
    ]

    response = {'status': StatusCodes['success'], 'errors': None, 'results': resultDegreeDetails}
    return flask.jsonify(response)

@app.route('/dbproj/top3', methods=['GET'])
@token_required
def top3_students():

    resultTop3 = [ # TODO
        {
            'student_name': "John Doe",
            'average_grade': 15.1,
            'grades': [
                {
                    'course_edition_id': random.randint(1, 200),
                    'course_edition_name': "some course",
                    'grade': 15.1,
                    'date': datetime.datetime(2024, 5, 12)
                }
            ],
            'activities': [random.randint(1, 200), random.randint(1, 200)]
        },
        {
            'student_name': "Jane Doe",
            'average_grade': 16.3,
            'grades': [
                {
                    'course_edition_id': random.randint(1, 200),
                    'course_edition_name': "another course",
                    'grade': 15.1,
                    'date': datetime.datetime(2023, 5, 11)
                }
            ],
            'activities': [random.randint(1, 200)]
        }
    ]

    response = {'status': StatusCodes['success'], 'errors': None, 'results': resultTop3}
    return flask.jsonify(response)

@app.route('/dbproj/top_by_district', methods=['GET'])
@token_required
def top_by_district():

    resultTopByDistrict = [ # TODO
        {
            'student_id': random.randint(1, 200),
            'district': "Coimbra",
            'average_grade': 15.2
        },
        {
            'student_id': random.randint(1, 200),
            'district': "Coimbra",
            'average_grade': 13.6
        }
    ]

    response = {'status': StatusCodes['success'], 'errors': None, 'results': resultTopByDistrict}
    return flask.jsonify(response)

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

