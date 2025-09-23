"""
Authentication Routes
Handles user login, logout, registration, and session management.
"""

from flask import Blueprint, request, jsonify, session, redirect, url_for, flash, render_template
from werkzeug.security import check_password_hash
from datetime import datetime
from utils.database_supabase import DatabaseManager
from services.cohort_service import CohortService
from utils.email_service import EmailService

# Initialize blueprint
auth_bp = Blueprint('auth', __name__)

# Initialize services
db = DatabaseManager()
email_service = EmailService()
cohort_service = CohortService(db, email_service)

# Global online users tracking
online_users = {}

@auth_bp.route('/')
def index():
    """Landing page"""
    return render_template('index.html')

@auth_bp.route('/login')
def login_page():
    """Login page"""
    return render_template('login.html')

@auth_bp.route('/admin_login')
def admin_login_page():
    """Admin-only login page"""
    return render_template('login.html', admin_mode=True)

@auth_bp.route('/register')
def register_page():
    """Registration page"""
    return render_template('register.html')

@auth_bp.route('/api/register/teacher', methods=['POST'])
def register_teacher():
    """Register a new teacher (admin only)"""
    try:
        # Check if user is admin
        if session.get('user_type') != 'admin':
            return jsonify({'error': 'Admin access required'}), 403
        
        data = request.get_json()
        
        if not all(key in data for key in ['name', 'email', 'institution_id', 'subject', 'password']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Hash password
        from werkzeug.security import generate_password_hash
        password_hash = generate_password_hash(data['password'])
        
        # Create teacher
        teacher_id, response = db.create_teacher(
            data['name'], data['email'], data['institution_id'], 
            data['subject'], password_hash
        )
        
        if teacher_id:
            # Send welcome email
            email_service.send_welcome_email(
                user_email=data['email'],
                user_name=data['name'],
                user_type='teacher'
            )
            
            return jsonify({
                'success': True,
                'message': 'Teacher registered successfully',
                'teacher_id': teacher_id
            }), 201
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/api/register/student', methods=['POST'])
def register_student():
    """Register a new student (admin only)"""
    try:
        # Check if user is admin
        if session.get('user_type') != 'admin':
            return jsonify({'error': 'Admin access required'}), 403
        
        data = request.get_json()
        
        if not all(key in data for key in ['name', 'email', 'institution_id', 'password']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Hash password
        from werkzeug.security import generate_password_hash
        password_hash = generate_password_hash(data['password'])
        
        # Create student
        student_id, response = db.create_student(
            data['name'], data['email'], data['institution_id'], password_hash
        )
        
        if student_id:
            # If cohort_id is provided, add student to cohort
            if 'cohort_id' in data:
                cohort_service.add_student_to_cohort(data['cohort_id'], student_id)
            
            return jsonify({
                'success': True,
                'message': 'Student registered successfully',
                'student_id': student_id
            }), 201
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/api/register/admin', methods=['POST'])
def register_admin():
    """Admin registration disabled: only one hardcoded admin is allowed"""
    return jsonify({'error': 'Admin registration is disabled'}), 403

@auth_bp.route('/api/login', methods=['POST'])
def login():
    """Login for teachers and students"""
    try:
        data = request.get_json()
        
        if not all(key in data for key in ['email', 'password', 'user_type']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        email = data['email']
        password = data['password']
        user_type = data['user_type']  # 'teacher', 'student', or 'admin'
        
        if user_type == 'admin':
            # Enforce single hardcoded admin
            if email != 'Admin@gmail.com' or password != 'Admin@#1234':
                return jsonify({'error': 'Invalid admin credentials'}), 401
            
            # Success: set session without DB
            session.permanent = True
            session['user_id'] = 'admin'
            session['user_type'] = 'admin'
            session['user_name'] = 'Admin'
            session['user_email'] = 'admin@local'
            
            online_users['admin'] = {
                'name': 'Admin',
                'email': 'admin@local',
                'type': 'admin',
                'login_time': datetime.now().isoformat()
            }
            
            return jsonify({
                'success': True,
                'message': 'Login successful',
                'user_type': 'admin',
                'redirect_url': '/admin_dashboard'
            }), 200
        
        elif user_type == 'teacher':
            user = db.get_teacher_by_email(email)
        elif user_type == 'student':
            user = db.get_student_by_email(email)
        else:
            return jsonify({'error': 'Invalid user type'}), 400
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        if not check_password_hash(user['password_hash'], password):
            return jsonify({'error': 'Invalid password'}), 401
        
        # Create session for teacher/student
        session.permanent = True
        session['user_id'] = user['id']
        session['user_type'] = user_type
        session['user_name'] = user['name']
        session['user_email'] = user['email']
        
        # Track online users
        online_users[user['id']] = {
            'name': user['name'],
            'email': user['email'],
            'type': user_type,
            'login_time': datetime.now().isoformat()
        }
        
        # Update last login
        if user_type == 'teacher':
            db.update_teacher_last_login(user['id'])
        
        return jsonify({
            'success': True,
            'message': 'Login successful',
            'user_type': user_type,
            'redirect_url': f'/{user_type}_dashboard'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/api/logout', methods=['POST'])
def logout():
    """Secure logout with complete session destruction"""
    try:
        user_id = session.get('user_id')
        user_type = session.get('user_type')
        
        # Remove from online users tracking
        if user_id and user_id in online_users:
            del online_users[user_id]
        
        # Clear all session data
        session.clear()
        session.permanent = False
        
        # Create response with security headers
        response = jsonify({
            'success': True,
            'message': 'Logged out successfully',
            'redirect_url': '/',
            'logout_timestamp': datetime.now().isoformat()
        })
        
        # Set session cookie to expire immediately
        from flask import current_app
        response.set_cookie(
            current_app.config['SESSION_COOKIE_NAME'], 
            '', 
            expires=0,
            secure=current_app.config['SESSION_COOKIE_SECURE'],
            httponly=current_app.config['SESSION_COOKIE_HTTPONLY'],
            samesite=current_app.config['SESSION_COOKIE_SAMESITE']
        )
        
        # Additional security headers for logout
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate, private'
        response.headers['Pragma'] = 'no-cache'
        response.headers['Expires'] = '0'
        
        return response, 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/logout', methods=['GET', 'POST'])
def logout_page():
    """Logout page with additional security measures"""
    try:
        user_id = session.get('user_id')
        user_type = session.get('user_type')
        
        # Remove from online users tracking
        if user_id and user_id in online_users:
            del online_users[user_id]
        
        # Clear all session data
        session.clear()
        session.permanent = False
        
        # Create response
        from flask import make_response
        response = make_response(render_template('logout.html'))
        
        # Set session cookie to expire immediately
        from flask import current_app
        response.set_cookie(
            current_app.config['SESSION_COOKIE_NAME'], 
            '', 
            expires=0,
            secure=current_app.config['SESSION_COOKIE_SECURE'],
            httponly=current_app.config['SESSION_COOKIE_HTTPONLY'],
            samesite=current_app.config['SESSION_COOKIE_SAMESITE']
        )
        
        # Security headers
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate, private'
        response.headers['Pragma'] = 'no-cache'
        response.headers['Expires'] = '0'
        
        return response
        
    except Exception as e:
        return redirect(url_for('auth.login_page'))

@auth_bp.route('/api/validate-session', methods=['GET'])
def validate_session():
    """Validate current session and return user info"""
    try:
        if 'user_id' not in session or not session.get('user_id'):
            return jsonify({'valid': False, 'error': 'No active session'}), 401
        
        user_id = session.get('user_id')
        
        # Check if user is still in online_users
        if user_id not in online_users:
            session.clear()
            return jsonify({'valid': False, 'error': 'Session expired'}), 401
        
        return jsonify({
            'valid': True,
            'user_id': user_id,
            'user_type': session.get('user_type'),
            'user_name': session.get('user_name'),
            'user_email': session.get('user_email')
        }), 200
        
    except Exception as e:
        return jsonify({'valid': False, 'error': str(e)}), 500

@auth_bp.route('/api/force-logout', methods=['POST'])
def force_logout():
    """Force logout all sessions for a user (admin function)"""
    try:
        if session.get('user_type') != 'admin':
            return jsonify({'error': 'Admin access required'}), 403
        
        data = request.get_json()
        target_user_id = data.get('user_id')
        
        if not target_user_id:
            return jsonify({'error': 'User ID required'}), 400
        
        # Remove from online users
        if target_user_id in online_users:
            del online_users[target_user_id]
        
        return jsonify({
            'success': True,
            'message': f'User {target_user_id} logged out successfully'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/api/cohort-selection', methods=['POST'])
def select_cohort():
    """Select a cohort for teachers/admins with multiple cohorts"""
    try:
        data = request.get_json()
        cohort_id = data.get('cohort_id')
        
        if not cohort_id:
            return jsonify({'error': 'Cohort ID required'}), 400
        
        user_type = session.get('user_type')
        user_id = session.get('user_id')
        
        if user_type not in ['teacher', 'admin']:
            return jsonify({'error': 'Only teachers and admins can select cohorts'}), 403
        
        # Verify user has access to this cohort
        if user_type == 'teacher':
            teacher_cohorts = db.get_teacher_cohorts(user_id)
            cohort_ids = [c['id'] for c in teacher_cohorts]
            if cohort_id not in cohort_ids:
                return jsonify({'error': 'Access denied to selected cohort'}), 403
        
        # Get cohort details
        cohort = cohort_service.get_cohort_by_id(cohort_id)
        if not cohort:
            return jsonify({'error': 'Cohort not found'}), 404
        
        # Set session data
        session['selected_cohort_id'] = cohort_id
        session['selected_cohort_name'] = cohort['name']
        
        return jsonify({
            'success': True,
            'message': 'Cohort selected successfully',
            'cohort': {
                'id': cohort_id,
                'name': cohort['name'],
                'subject': cohort['subject']
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/api/available-cohorts', methods=['GET'])
def get_available_cohorts():
    """Get available cohorts for the current user"""
    try:
        user_type = session.get('user_type')
        user_id = session.get('user_id')
        
        if not user_type or not user_id:
            return jsonify({'error': 'Authentication required'}), 401
        
        if user_type == 'student':
            cohorts = db.get_student_cohorts(user_id)
        elif user_type == 'teacher':
            cohorts = db.get_teacher_cohorts(user_id)
        elif user_type == 'admin':
            cohorts = db.get_all_cohorts()
        else:
            return jsonify({'error': 'Invalid user type'}), 400
        
        return jsonify({
            'success': True,
            'cohorts': cohorts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

