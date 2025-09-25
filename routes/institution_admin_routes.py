"""
Institution Admin Routes
Handles institution admin authentication, management, and operations.
"""

from flask import Blueprint, request, jsonify, session, redirect, url_for, flash, render_template
from werkzeug.security import check_password_hash, generate_password_hash
from datetime import datetime
from utils.database_supabase import SupabaseDatabaseManager as DatabaseManager
from middlewares.auth_middleware import AuthMiddleware
from utils.email_service import EmailService

# Initialize blueprint
institution_admin_bp = Blueprint('institution_admin', __name__)

# Initialize services
db = DatabaseManager()
auth_middleware = AuthMiddleware(None, db)
email_service = EmailService()

@institution_admin_bp.route('/login', methods=['GET', 'POST'])
def login():
    """Institution admin login"""
    if request.method == 'GET':
        return render_template('institution_admin_login.html')
    
    try:
        data = request.get_json() if request.is_json else request.form
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({'error': 'Email and password are required'}), 400
        
        # Get institution admin
        admin = db.get_institution_admin_by_email(email)
        if not admin:
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Check password
        if not check_password_hash(admin['password_hash'], password):
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Check if admin is active
        if not admin.get('is_active', True):
            return jsonify({'error': 'Account is deactivated'}), 401
        
        # Update last login
        db.update_teacher_last_login(admin['id'])  # Reusing this method for now
        
        # Set session
        session['user_id'] = admin['id']
        session['user_type'] = 'institution_admin'
        session['institution_id'] = admin['institution_id']
        session['permissions'] = admin.get('permissions', {})
        
        return jsonify({
            'success': True,
            'message': 'Login successful',
            'redirect_url': '/institution_admin_dashboard'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/dashboard')
@auth_middleware.institution_admin_required
def dashboard():
    """Institution admin dashboard"""
    return render_template('institution_admin_dashboard.html')

@institution_admin_bp.route('/teachers', methods=['GET'])
@auth_middleware.institution_admin_required
def get_teachers():
    """Get all teachers for the institution"""
    try:
        institution_id = session.get('institution_id')
        teachers = db.get_teachers_by_institution(institution_id)
        
        return jsonify({
            'success': True,
            'teachers': teachers
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/teachers', methods=['POST'])
@auth_middleware.institution_admin_required
def create_teacher():
    """Create a new teacher"""
    try:
        institution_id = session.get('institution_id')
        created_by = session.get('user_id')
        
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['name', 'email', 'password', 'subject']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400
        
        # Hash password
        password_hash = generate_password_hash(data['password'])
        
        # Create teacher
        teacher_id, message = db.create_teacher(
            institution_id=institution_id,
            name=data['name'],
            email=data['email'],
            subject=data['subject'],
            password_hash=password_hash,
            employee_id=data.get('employee_id'),
            department=data.get('department'),
            phone=data.get('phone'),
            bio=data.get('bio'),
            created_by=created_by
        )
        
        if not teacher_id:
            return jsonify({'error': message}), 400
        
        # Send welcome email
        try:
            email_service.send_teacher_welcome_email(
                data['email'], 
                data['name'], 
                data['password']
            )
        except Exception as e:
            print(f"Failed to send welcome email: {e}")
        
        return jsonify({
            'success': True,
            'message': 'Teacher created successfully',
            'teacher_id': teacher_id
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/students', methods=['GET'])
@auth_middleware.institution_admin_required
def get_students():
    """Get all students for the institution"""
    try:
        institution_id = session.get('institution_id')
        students = db.get_students_by_institution(institution_id)
        
        return jsonify({
            'success': True,
            'students': students
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/students', methods=['POST'])
@auth_middleware.institution_admin_required
def create_student():
    """Create a new student"""
    try:
        institution_id = session.get('institution_id')
        created_by = session.get('user_id')
        
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['name', 'email', 'password']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400
        
        # Hash password
        password_hash = generate_password_hash(data['password'])
        
        # Create student
        student_id, message = db.create_student(
            institution_id=institution_id,
            name=data['name'],
            email=data['email'],
            password_hash=password_hash,
            student_id=data.get('student_id'),
            roll_number=data.get('roll_number'),
            class_name=data.get('class'),
            section=data.get('section'),
            phone=data.get('phone'),
            parent_phone=data.get('parent_phone'),
            date_of_birth=data.get('date_of_birth'),
            created_by=created_by
        )
        
        if not student_id:
            return jsonify({'error': message}), 400
        
        # Send welcome email
        try:
            email_service.send_student_welcome_email(
                data['email'], 
                data['name'], 
                data['password']
            )
        except Exception as e:
            print(f"Failed to send welcome email: {e}")
        
        return jsonify({
            'success': True,
            'message': 'Student created successfully',
            'student_id': student_id
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/cohorts', methods=['GET'])
@auth_middleware.institution_admin_required
def get_cohorts():
    """Get all cohorts for the institution"""
    try:
        institution_id = session.get('institution_id')
        cohorts = db.get_cohorts_by_institution(institution_id)
        
        return jsonify({
            'success': True,
            'cohorts': cohorts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/cohorts', methods=['POST'])
@auth_middleware.institution_admin_required
def create_cohort():
    """Create a new cohort"""
    try:
        institution_id = session.get('institution_id')
        created_by = session.get('user_id')
        
        data = request.get_json()
        
        # Validate required fields
        if not data.get('name'):
            return jsonify({'error': 'Cohort name is required'}), 400
        
        # Create cohort
        cohort_id, message = db.create_cohort(
            institution_id=institution_id,
            name=data['name'],
            description=data.get('description'),
            enrollment_code=data.get('enrollment_code'),
            max_students=data.get('max_students', 50),
            academic_year=data.get('academic_year'),
            semester=data.get('semester'),
            start_date=data.get('start_date'),
            end_date=data.get('end_date'),
            created_by=created_by
        )
        
        if not cohort_id:
            return jsonify({'error': message}), 400
        
        return jsonify({
            'success': True,
            'message': 'Cohort created successfully',
            'cohort_id': cohort_id
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/lectures', methods=['GET'])
@auth_middleware.institution_admin_required
def get_lectures():
    """Get all lectures for the institution"""
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
def logout():
    """Institution admin logout"""
    try:
        session.clear()
        return jsonify({
            'success': True,
            'message': 'Logged out successfully',
            'redirect_url': '/institution_admin/login'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

