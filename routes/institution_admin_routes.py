"""
Institution Admin Routes
Handles institution admin functionality for managing teachers, students, cohorts, and institution-specific operations.
"""

from flask import Blueprint, request, jsonify, session, redirect, url_for, render_template
from werkzeug.security import check_password_hash, generate_password_hash
from datetime import datetime
from utils.database_supabase import SupabaseDatabaseManager as DatabaseManager
from middlewares.auth_middleware import AuthMiddleware
from utils.email_service import EmailService
from services.institution_admin_service import InstitutionAdminService

# Initialize blueprint
institution_admin_bp = Blueprint('institution_admin', __name__)

# Initialize services
db = DatabaseManager()
auth_middleware = AuthMiddleware(None, db)
email_service = EmailService()
institution_admin_service = InstitutionAdminService(db, email_service)

@institution_admin_bp.route('/dashboard')
def dashboard():
    """Institution admin dashboard"""
    try:
        # Get institution information
        institution_id = session.get('institution_id')
        if not institution_id:
            return redirect('/institution-admin/login')
        
        institution = db.get_institution_by_id(institution_id)
        if not institution:
            return redirect('/institution-admin/login')
        
        return render_template('institution_admin_dashboard.html', institution=institution)
    except Exception as e:
        return render_template('error.html', error="Error loading dashboard", message=str(e)), 500

@institution_admin_bp.route('/login', methods=['GET', 'POST'])
def login():
    """Institution admin login"""
    if request.method == 'GET':
        return render_template('institution_login.html')
    
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({'error': 'Email and password required'}), 400
        
        # Get institution admin by email
        admin = db.get_institution_admin_by_email(email)
        if not admin:
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Verify password
        if not check_password_hash(admin['password_hash'], password):
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Create session
        session.permanent = True
        session['user_id'] = admin['id']
        session['user_type'] = 'institution_admin'
        session['user_name'] = admin['name']
        session['user_email'] = admin['email']
        session['institution_id'] = admin['institution_id']
        
        # Track online users
        auth_middleware.online_users[admin['id']] = {
            'name': admin['name'],
            'email': admin['email'],
            'type': 'institution_admin',
            'login_time': datetime.now().isoformat()
        }
        
        return jsonify({
            'success': True,
            'message': 'Login successful',
            'redirect_url': '/institution-admin/dashboard'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@institution_admin_bp.route('/teachers', methods=['GET'])
@auth_middleware.institution_admin_required
def get_teachers():
    """Get all teachers in the institution"""
    try:
        institution_id = session.get('institution_id')
        teachers = db.get_teachers_by_institution(institution_id)
        
        return jsonify({
            'success': True,
            'teachers': teachers
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@institution_admin_bp.route('/students', methods=['GET'])
@auth_middleware.institution_admin_required
def get_students():
    """Get all students in the institution"""
    try:
        institution_id = session.get('institution_id')
        students = db.get_students_by_institution(institution_id)
        
        return jsonify({
            'success': True,
            'students': students
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@institution_admin_bp.route('/cohorts', methods=['GET'])
@auth_middleware.institution_admin_required
def get_cohorts():
    """Get all cohorts in the institution"""
    try:
        institution_id = session.get('institution_id')
        cohorts = db.get_cohorts_by_institution(institution_id)
        
        return jsonify({
            'success': True,
            'cohorts': cohorts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@institution_admin_bp.route('/lectures', methods=['GET'])
@auth_middleware.institution_admin_required
def get_lectures():
    """Get all lectures in the institution"""
    try:
        institution_id = session.get('institution_id')
        lectures = db.get_lectures_by_institution(institution_id)
        
        return jsonify({
            'success': True,
            'lectures': lectures
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/stats', methods=['GET'])
@auth_middleware.institution_admin_required
def get_institution_stats():
    """Get institution statistics"""
    try:
        institution_id = session.get('institution_id')
        stats = db.get_institution_stats(institution_id)
        
        return jsonify({
            'success': True,
            'stats': stats
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/logout', methods=['POST'])
@auth_middleware.institution_admin_required
def logout():
    """Institution admin logout"""
    try:
        user_id = session.get('user_id')
        
        # Remove from online users tracking
        if user_id and user_id in auth_middleware.online_users:
            del auth_middleware.online_users[user_id]
        
        # Clear all session data
        session.clear()
        session.permanent = False
        
        return jsonify({
            'success': True,
            'message': 'Logged out successfully',
            'redirect_url': '/'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Dashboard API endpoints
@institution_admin_bp.route('/api/stats')
@auth_middleware.institution_admin_required
def get_dashboard_stats():
    """Get institution statistics for dashboard"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        stats = db.get_institution_stats(institution_id)
        return jsonify({
            'success': True,
            'stats': stats
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/api/teachers')
@auth_middleware.institution_admin_required
def get_dashboard_teachers():
    """Get all teachers for the institution"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        teachers = db.get_teachers_by_institution(institution_id)
        return jsonify({
            'success': True,
            'teachers': teachers
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/api/students')
@auth_middleware.institution_admin_required
def get_dashboard_students():
    """Get all students for the institution"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        students = db.get_students_by_institution(institution_id)
        return jsonify({
            'success': True,
            'students': students
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/api/cohorts')
@auth_middleware.institution_admin_required
def get_dashboard_cohorts():
    """Get all cohorts for the institution"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        cohorts = db.get_cohorts_by_institution(institution_id)
        return jsonify({
            'success': True,
            'cohorts': cohorts
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/api/lectures')
@auth_middleware.institution_admin_required
def get_dashboard_lectures():
    """Get all lectures for the institution"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        lectures = db.get_lectures_by_institution(institution_id)
        return jsonify({
            'success': True,
            'lectures': lectures
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Management API endpoints
@institution_admin_bp.route('/teachers', methods=['POST'])
@auth_middleware.institution_admin_required
def create_teacher():
    """Create a new teacher"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        data = request.get_json()
        
        # Check if email already exists
        existing_teacher = db.get_teacher_by_email(data['email'])
        if existing_teacher:
            return jsonify({'error': 'Email already exists'}), 400
        
        # Create teacher
        teacher_id, message = db.create_teacher(
            institution_id=institution_id,
            name=data['name'],
            email=data['email'],
            subject=data['subject'],
            password_hash=generate_password_hash(data['password'], method='scrypt'),
            employee_id=data.get('employee_id'),
            department=data.get('department'),
            phone=data.get('phone'),
            bio=data.get('bio'),
            created_by=session.get('user_id')
        )
        
        if teacher_id:
            # Send welcome email
            try:
                email_service.send_welcome_email(
                    user_email=data['email'],
                    user_name=data['name'],
                    user_type='teacher'
                )
            except Exception as email_error:
                print(f"Failed to send welcome email: {str(email_error)}")
            
            return jsonify({
                'success': True,
                'message': 'Teacher created successfully',
                'teacher_id': teacher_id
            }), 201
        else:
            return jsonify({'error': message}), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/students', methods=['POST'])
@auth_middleware.institution_admin_required
def create_student():
    """Create a new student"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        data = request.get_json()
        
        # Check if email already exists
        existing_student = db.get_student_by_email(data['email'])
        if existing_student:
            return jsonify({'error': 'Email already exists'}), 400
        
        # Create student
        student_id, message = db.create_student(
            institution_id=institution_id,
            name=data['name'],
            email=data['email'],
            password_hash=generate_password_hash(data['password'], method='scrypt'),
            student_id=data.get('student_id'),
            roll_number=data.get('roll_number'),
            class_name=data.get('class'),
            section=data.get('section'),
            phone=data.get('phone'),
            parent_phone=data.get('parent_phone'),
            date_of_birth=data.get('date_of_birth'),
            created_by=session.get('user_id')
        )
        
        if student_id:
            # Send welcome email
            try:
                email_service.send_welcome_email(
                    user_email=data['email'],
                    user_name=data['name'],
                    user_type='student'
                )
            except Exception as email_error:
                print(f"Failed to send welcome email: {str(email_error)}")
            
            return jsonify({
                'success': True,
                'message': 'Student created successfully',
                'student_id': student_id
            }), 201
        else:
            return jsonify({'error': message}), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/cohorts', methods=['POST'])
@auth_middleware.institution_admin_required
def create_cohort():
    """Create a new cohort"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        data = request.get_json()
        
        # Create cohort
        cohort_id, message = db.create_cohort(
            institution_id=institution_id,
            name=data['name'],
            description=data.get('description'),
            enrollment_code=data.get('enrollment_code'),
            max_students=data.get('max_students', 50),
            academic_year=data.get('academic_year'),
            semester=data.get('semester'),
            session=data.get('session'),  # Add session field
            start_date=data.get('start_date'),
            end_date=data.get('end_date'),
            created_by=session.get('user_id')
        )
        
        if cohort_id:
            return jsonify({
                'success': True,
                'message': 'Cohort created successfully',
                'cohort_id': cohort_id,
                'enrollment_code': data.get('enrollment_code', 'AUTO_GENERATED')
            }), 201
        else:
            return jsonify({'error': message}), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500# Edit/Delete endpoints
@institution_admin_bp.route('/teachers/<teacher_id>', methods=['PUT', 'DELETE'])
@auth_middleware.institution_admin_required
def manage_teacher(teacher_id):
    """Update or delete a teacher"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        if request.method == 'PUT':
            # Update teacher
            data = request.get_json()
            
            # Remove password from update data if not provided
            update_data = {k: v for k, v in data.items() if k != 'password'}
            
            # Hash password if provided
            if 'password' in data and data['password']:
                update_data['password_hash'] = generate_password_hash(data['password'], method='scrypt')
            
            success = db.update_teacher(teacher_id, **update_data)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Teacher updated successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to update teacher'}), 400
                
        elif request.method == 'DELETE':
            # Delete teacher (soft delete by setting is_active to False)
            success = db.update_teacher(teacher_id, is_active=False)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Teacher deleted successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to delete teacher'}), 400
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/students/<student_id>', methods=['PUT', 'DELETE'])
@auth_middleware.institution_admin_required
def manage_student(student_id):
    """Update or delete a student"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        if request.method == 'PUT':
            # Update student
            data = request.get_json()
            
            # Remove password from update data if not provided
            update_data = {k: v for k, v in data.items() if k != 'password'}
            
            # Hash password if provided
            if 'password' in data and data['password']:
                update_data['password_hash'] = generate_password_hash(data['password'], method='scrypt')
            
            success = db.update_student(student_id, **update_data)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Student updated successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to update student'}), 400
                
        elif request.method == 'DELETE':
            # Delete student (soft delete by setting is_active to False)
            success = db.update_student(student_id, is_active=False)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Student deleted successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to delete student'}), 400
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/cohorts/<cohort_id>', methods=['PUT', 'DELETE'])
@auth_middleware.institution_admin_required
def manage_cohort(cohort_id):
    """Update or delete a cohort"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        if request.method == 'PUT':
            # Update cohort
            data = request.get_json()
            
            success = db.update_cohort(cohort_id, **data)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Cohort updated successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to update cohort'}), 400
                
        elif request.method == 'DELETE':
            # Delete cohort (soft delete by setting is_active to False)
            success = db.update_cohort(cohort_id, is_active=False)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Cohort deleted successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to delete cohort'}), 400
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500
# Assignment endpoints
@institution_admin_bp.route('/cohorts/<cohort_id>/teachers', methods=['GET', 'POST', 'DELETE'])
@auth_middleware.institution_admin_required
def manage_cohort_teachers(cohort_id):
    """Manage teacher assignments to cohorts"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        if request.method == 'GET':
            # Get teachers assigned to cohort
            teachers = db.get_cohort_teachers(cohort_id)
            return jsonify({
                'success': True,
                'teachers': teachers
            }), 200
            
        elif request.method == 'POST':
            # Assign teacher to cohort
            data = request.get_json()
            teacher_id = data.get('teacher_id')
            role = data.get('role', 'teacher')
            
            if not teacher_id:
                return jsonify({'error': 'Teacher ID is required'}), 400
            
            success = db.assign_teacher_to_cohort(
                teacher_id=teacher_id, 
                cohort_id=cohort_id, 
                role=role, 
                assigned_by=session.get('user_id')
            )
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Teacher assigned to cohort successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to assign teacher to cohort'}), 400
                
        elif request.method == 'DELETE':
            # Remove teacher from cohort
            data = request.get_json()
            teacher_id = data.get('teacher_id')
            
            if not teacher_id:
                return jsonify({'error': 'Teacher ID is required'}), 400
            
            success = db.remove_teacher_from_cohort(teacher_id, cohort_id)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Teacher removed from cohort successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to remove teacher from cohort'}), 400
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/cohorts/<cohort_id>/students', methods=['GET', 'POST', 'DELETE'])
@auth_middleware.institution_admin_required
def manage_cohort_students(cohort_id):
    """Manage student enrollments in cohorts"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        if request.method == 'GET':
            # Get students enrolled in cohort
            students = db.get_cohort_students(cohort_id)
            return jsonify({
                'success': True,
                'students': students
            }), 200
            
        elif request.method == 'POST':
            # Enroll student in cohort
            data = request.get_json()
            student_id = data.get('student_id')
            
            if not student_id:
                return jsonify({'error': 'Student ID is required'}), 400
            
            success = db.enroll_student_in_cohort(
                institution_id=institution_id,
                student_id=student_id, 
                cohort_id=cohort_id, 
                enrolled_by=session.get('user_id')
            )
            
            if success:
                # Send enrollment notification to student
                try:
                    student = db.get_student_by_id(student_id)
                    cohort = db.get_cohort_by_id(cohort_id)
                    if student and cohort:
                        email_service.send_welcome_email(
                            user_email=student['email'],
                            user_name=student['name'],
                            user_type='student',
                            cohort_name=cohort['name'],
                            cohort_code=cohort.get('enrollment_code')
                        )
                except Exception as email_error:
                    print(f"Failed to send enrollment notification: {str(email_error)}")
                
                return jsonify({
                    'success': True,
                    'message': 'Student enrolled in cohort successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to enroll student in cohort'}), 400
                
        elif request.method == 'DELETE':
            # Remove student from cohort
            data = request.get_json()
            student_id = data.get('student_id')
            
            if not student_id:
                return jsonify({'error': 'Student ID is required'}), 400
            
            success = db.remove_student_from_cohort(student_id, cohort_id)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Student removed from cohort successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to remove student from cohort'}), 400
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/cohorts/<cohort_id>/enroll', methods=['POST'])
@auth_middleware.institution_admin_required
def enroll_student_by_code(cohort_id):
    """Enroll student in cohort using enrollment code"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        data = request.get_json()
        enrollment_code = data.get('enrollment_code')
        student_id = data.get('student_id')
        
        if not enrollment_code or not student_id:
            return jsonify({'error': 'Enrollment code and student ID are required'}), 400
        
        # Verify enrollment code matches cohort
        cohort = db.get_cohort_by_id(cohort_id)
        if not cohort or cohort.get('enrollment_code') != enrollment_code:
            return jsonify({'error': 'Invalid enrollment code'}), 400
        
        success = db.enroll_student_in_cohort(student_id, cohort_id)
        
        if success:
            return jsonify({
                'success': True,
                'message': 'Student enrolled successfully'
            }), 200
        else:
            return jsonify({'error': 'Failed to enroll student'}), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/teachers/<teacher_id>/cohorts', methods=['GET'])
@auth_middleware.institution_admin_required
def get_teacher_cohorts(teacher_id):
    """Get cohorts assigned to a teacher"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        cohorts = db.get_teacher_cohorts(teacher_id)
        return jsonify({
            'success': True,
            'cohorts': cohorts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/students/<student_id>/cohorts', methods=['GET'])
@auth_middleware.institution_admin_required
def get_student_cohorts(student_id):
    """Get cohorts enrolled by a student"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        cohorts = db.get_student_cohorts(student_id)
        return jsonify({
            'success': True,
            'cohorts': cohorts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
@institution_admin_bp.route('/lectures', methods=['POST'])
@auth_middleware.institution_admin_required
def create_lecture():
    """Create a new lecture"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        data = request.get_json()
        
        # Create lecture
        lecture_id, message = db.create_lecture(
            institution_id=institution_id,
            cohort_id=data['cohort_id'],
            teacher_id=data['teacher_id'],
            title=data['title'],
            description=data.get('description'),
            scheduled_time=data['scheduled_time'],
            duration=data.get('duration', 60),
            lecture_type=data.get('lecture_type', 'live'),
            created_by=session.get('user_id')
        )
        
        if lecture_id:
            # Send lecture notification to teacher
            try:
                teacher = db.get_teacher_by_id(data['teacher_id'])
                if teacher:
                    email_service.send_lecture_notification(
                        user_email=teacher['email'],
                        user_name=teacher['name'],
                        lecture_title=data['title'],
                        teacher_name=teacher['name'],
                        scheduled_time=data['scheduled_time']
                    )
            except Exception as email_error:
                print(f"Failed to send lecture notification: {str(email_error)}")
            
            return jsonify({
                'success': True,
                'message': 'Lecture scheduled successfully',
                'lecture_id': lecture_id
            }), 201
        else:
            return jsonify({'error': message}), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500
