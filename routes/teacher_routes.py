"""
Teacher Routes
Handles teacher-specific functionality including lecture management, materials, and student interaction.
"""

from flask import Blueprint, request, jsonify, session, redirect, url_for, render_template
from werkzeug.security import check_password_hash, generate_password_hash
from datetime import datetime
from utils.database_supabase import SupabaseDatabaseManager as DatabaseManager
from middlewares.auth_middleware import AuthMiddleware
from utils.email_service import EmailService

# Initialize blueprint
teacher_bp = Blueprint('teacher', __name__)

# Initialize services
db = DatabaseManager()
email_service = EmailService()

# Global variable to store auth_middleware reference
auth_middleware = None

def set_auth_middleware(middleware):
    """Set the auth middleware reference from main.py"""
    global auth_middleware
    auth_middleware = middleware

def teacher_required(f):
    """Decorator to require teacher role - gets middleware at runtime"""
    from functools import wraps
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if auth_middleware is None:
            from flask import jsonify
            return jsonify({'error': 'Authentication service not available'}), 500
        return auth_middleware.teacher_required(f)(*args, **kwargs)
    return decorated_function

@teacher_bp.route('/login', methods=['GET', 'POST'])
def login():
    """Teacher login"""
    if request.method == 'GET':
        return render_template('teacher_login.html')
    
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({'error': 'Email and password required'}), 400
        
        # Get teacher by email
        teacher = db.get_teacher_by_email(email)
        if not teacher:
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Verify password
        if not check_password_hash(teacher['password_hash'], password):
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Create session
        session.permanent = True
        session['user_id'] = teacher['id']
        session['user_type'] = 'teacher'
        session['user_name'] = teacher['name']
        session['user_email'] = teacher['email']
        session['institution_id'] = teacher['institution_id']
        
        # Track online users
        auth_middleware.online_users[teacher['id']] = {
            'name': teacher['name'],
            'email': teacher['email'],
            'type': 'teacher',
            'login_time': datetime.now().isoformat()
        }
        
        # Update last login
        db.update_teacher_last_login(teacher['id'])
        
        return jsonify({
            'success': True,
            'message': 'Login successful',
            'redirect_url': '/teacher/dashboard'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/dashboard')
@teacher_required
def dashboard():
    """Teacher dashboard"""
    return render_template('teacher_dashboard.html')

@teacher_bp.route('/lectures', methods=['GET'])
@teacher_required
def get_lectures():
    """Get teacher's lectures"""
    try:
        teacher_id = session.get('user_id')
        lectures = db.get_lectures_by_teacher(teacher_id)
        
        return jsonify({
            'success': True,
            'lectures': lectures
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/lectures', methods=['POST'])
@teacher_required
def create_lecture():
    """Create a new lecture"""
    try:
        data = request.get_json()
        teacher_id = session.get('user_id')
        
        required_fields = ['title', 'cohort_id', 'scheduled_time']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Verify teacher has access to this cohort
        teacher_cohorts = db.get_teacher_cohorts(teacher_id)
        cohort_ids = [c['id'] for c in teacher_cohorts]
        
        if data['cohort_id'] not in cohort_ids:
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        # Create lecture
        lecture_id = db.create_lecture(
            title=data['title'],
            description=data.get('description'),
            teacher_id=teacher_id,
            cohort_id=data['cohort_id'],
            scheduled_time=data['scheduled_time'],
            duration=data.get('duration', 60),
            meeting_url=data.get('meeting_url'),
            is_live=data.get('is_live', False)
        )
        
        if lecture_id:
            return jsonify({
                'success': True,
                'lecture_id': lecture_id,
                'message': 'Lecture created successfully'
            }), 201
        else:
            return jsonify({'error': 'Failed to create lecture'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/lectures/<lecture_id>', methods=['PUT'])
@teacher_required
def update_lecture(lecture_id):
    """Update a lecture"""
    try:
        teacher_id = session.get('user_id')
        data = request.get_json()
        
        # Verify teacher owns this lecture
        lecture = db.get_lecture_by_id(lecture_id)
        if not lecture or lecture['teacher_id'] != teacher_id:
            return jsonify({'error': 'Access denied'}), 403
        
        # Update lecture
        updated = db.update_lecture(lecture_id, **data)
        
        if updated:
            return jsonify({
                'success': True,
                'message': 'Lecture updated successfully'
            }), 200
        else:
            return jsonify({'error': 'Failed to update lecture'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/lectures/<lecture_id>', methods=['DELETE'])
@teacher_required
def delete_lecture(lecture_id):
    """Delete a lecture"""
    try:
        teacher_id = session.get('user_id')
        
        # Verify teacher owns this lecture
        lecture = db.get_lecture_by_id(lecture_id)
        if not lecture or lecture['teacher_id'] != teacher_id:
            return jsonify({'error': 'Access denied'}), 403
        
        # Delete lecture
        deleted = db.delete_lecture(lecture_id)
        
        if deleted:
            return jsonify({
                'success': True,
                'message': 'Lecture deleted successfully'
            }), 200
        else:
            return jsonify({'error': 'Failed to delete lecture'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/cohorts', methods=['GET'])
@teacher_required
def get_cohorts():
    """Get teacher's cohorts"""
    try:
        teacher_id = session.get('user_id')
        cohorts = db.get_teacher_cohorts(teacher_id)
        
        return jsonify({
            'success': True,
            'cohorts': cohorts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/materials', methods=['GET'])
@teacher_required
def get_materials():
    """Get teacher's materials"""
    try:
        teacher_id = session.get('user_id')
        materials = db.get_teacher_materials(teacher_id)
        
        return jsonify({
            'success': True,
            'materials': materials
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/materials', methods=['POST'])
@teacher_required
def create_material():
    """Create a new material"""
    try:
        data = request.get_json()
        teacher_id = session.get('user_id')
        
        required_fields = ['title', 'cohort_id', 'file_name', 'file_path']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Verify teacher has access to this cohort
        teacher_cohorts = db.get_teacher_cohorts(teacher_id)
        cohort_ids = [c['id'] for c in teacher_cohorts]
        
        if data['cohort_id'] not in cohort_ids:
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        # Create material
        material_id = db.create_material(
            title=data['title'],
            description=data.get('description'),
            teacher_id=teacher_id,
            cohort_id=data['cohort_id'],
            file_name=data['file_name'],
            file_path=data['file_path'],
            file_size=data.get('file_size'),
            file_type=data.get('file_type')
        )
        
        if material_id:
            return jsonify({
                'success': True,
                'material_id': material_id,
                'message': 'Material created successfully'
            }), 201
        else:
            return jsonify({'error': 'Failed to create material'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/profile', methods=['GET'])
@teacher_required
def get_profile():
    """Get teacher profile"""
    try:
        teacher_id = session.get('user_id')
        teacher = db.get_teacher_by_id(teacher_id)
        
        if not teacher:
            return jsonify({'error': 'Teacher not found'}), 404
        
        # Remove sensitive data
        teacher.pop('password_hash', None)
        
        return jsonify({
            'success': True,
            'teacher': teacher
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/profile', methods=['PUT'])
@teacher_required
def update_profile():
    """Update teacher profile"""
    try:
        teacher_id = session.get('user_id')
        data = request.get_json()
        
        # Remove fields that shouldn't be updated directly
        data.pop('id', None)
        data.pop('institution_id', None)
        data.pop('created_at', None)
        
        # Update teacher
        updated = db.update_teacher(teacher_id, **data)
        
        if updated:
            return jsonify({
                'success': True,
                'message': 'Profile updated successfully'
            }), 200
        else:
            return jsonify({'error': 'Failed to update profile'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/logout', methods=['POST'])
@teacher_required
def logout():
    """Teacher logout"""
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