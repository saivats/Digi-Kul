"""
Teacher Routes
Handles teacher authentication, lecture management, and teaching operations.
"""

from flask import Blueprint, request, jsonify, session, redirect, url_for, flash, render_template
from werkzeug.security import check_password_hash, generate_password_hash
from datetime import datetime
from utils.database_supabase import SupabaseDatabaseManager as DatabaseManager
from middlewares.auth_middleware import AuthMiddleware
from utils.email_service import EmailService

# Initialize blueprint
teacher_bp = Blueprint('teacher', __name__)

# Initialize services
db = DatabaseManager()
auth_middleware = AuthMiddleware(None, db)
email_service = EmailService()

@teacher_bp.route('/login', methods=['GET', 'POST'])
def login():
    """Teacher login"""
    if request.method == 'GET':
        return render_template('teacher_login.html')
    
    try:
        data = request.get_json() if request.is_json else request.form
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({'error': 'Email and password are required'}), 400
        
        # Get teacher
        teacher = db.get_teacher_by_email(email)
        if not teacher:
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Check password
        if not check_password_hash(teacher['password_hash'], password):
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Check if teacher is active
        if not teacher.get('is_active', True):
            return jsonify({'error': 'Account is deactivated'}), 401
        
        # Update last login
        db.update_teacher_last_login(teacher['id'])
        
        # Set session
        session['user_id'] = teacher['id']
        session['user_type'] = 'teacher'
        session['institution_id'] = teacher['institution_id']
        session['subject'] = teacher['subject']
        
        return jsonify({
            'success': True,
            'message': 'Login successful',
            'redirect_url': '/teacher_dashboard'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/dashboard')
@auth_middleware.teacher_required
def dashboard():
    """Teacher dashboard"""
    return render_template('teacher_dashboard.html')

@teacher_bp.route('/lectures', methods=['GET'])
@auth_middleware.teacher_required
def get_my_lectures():
    """Get all lectures for the teacher"""
    try:
        teacher_id = session.get('user_id')
        lectures = db.get_teacher_lectures(teacher_id)
        
        return jsonify({
            'success': True,
            'lectures': lectures
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/lectures', methods=['POST'])
@auth_middleware.teacher_required
def create_lecture():
    """Create a new lecture"""
    try:
        teacher_id = session.get('user_id')
        institution_id = session.get('institution_id')
        
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['title', 'cohort_id']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400
        
        # Create lecture
        lecture_id, message = db.create_lecture(
            institution_id=institution_id,
            cohort_id=data['cohort_id'],
            teacher_id=teacher_id,
            title=data['title'],
            description=data.get('description'),
            scheduled_time=data.get('scheduled_time'),
            duration=data.get('duration', 60),
            meeting_link=data.get('meeting_link'),
            meeting_id=data.get('meeting_id'),
            meeting_password=data.get('meeting_password'),
            recording_enabled=data.get('recording_enabled', True),
            chat_enabled=data.get('chat_enabled', True),
            max_participants=data.get('max_participants', 100)
        )
        
        if not lecture_id:
            return jsonify({'error': message}), 400
        
        return jsonify({
            'success': True,
            'message': 'Lecture created successfully',
            'lecture_id': lecture_id
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/lectures/<lecture_id>', methods=['PUT'])
@auth_middleware.teacher_required
def update_lecture(lecture_id):
    """Update a lecture"""
    try:
        teacher_id = session.get('user_id')
        
        # Verify teacher owns this lecture
        lecture = db.get_lecture_by_id(lecture_id)
        if not lecture or lecture['teacher_id'] != teacher_id:
            return jsonify({'error': 'Lecture not found or access denied'}), 404
        
        data = request.get_json()
        
        # Update lecture
        success = db.update_lecture(lecture_id, **data)
        if not success:
            return jsonify({'error': 'Failed to update lecture'}), 400
        
        return jsonify({
            'success': True,
            'message': 'Lecture updated successfully'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/lectures/<lecture_id>', methods=['DELETE'])
@auth_middleware.teacher_required
def delete_lecture(lecture_id):
    """Delete a lecture"""
    try:
        teacher_id = session.get('user_id')
        
        # Verify teacher owns this lecture
        lecture = db.get_lecture_by_id(lecture_id)
        if not lecture or lecture['teacher_id'] != teacher_id:
            return jsonify({'error': 'Lecture not found or access denied'}), 404
        
        # Delete lecture
        success = db.delete_lecture(lecture_id)
        if not success:
            return jsonify({'error': 'Failed to delete lecture'}), 400
        
        return jsonify({
            'success': True,
            'message': 'Lecture deleted successfully'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/cohorts', methods=['GET'])
@auth_middleware.teacher_required
def get_my_cohorts():
    """Get cohorts assigned to the teacher"""
    try:
        teacher_id = session.get('user_id')
        institution_id = session.get('institution_id')
        
        # Get all cohorts for the institution (teacher can see all)
        cohorts = db.get_cohorts_by_institution(institution_id)
        
        return jsonify({
            'success': True,
            'cohorts': cohorts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/materials', methods=['GET'])
@auth_middleware.teacher_required
def get_my_materials():
    """Get materials uploaded by the teacher"""
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
@auth_middleware.teacher_required
def upload_material():
    """Upload a new material"""
    try:
        teacher_id = session.get('user_id')
        institution_id = session.get('institution_id')
        
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['title', 'file_path', 'file_name', 'file_type']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'{field} is required'}), 400
        
        # Create material
        material_id, message = db.create_material(
            institution_id=institution_id,
            lecture_id=data.get('lecture_id'),
            cohort_id=data.get('cohort_id'),
            teacher_id=teacher_id,
            title=data['title'],
            description=data.get('description'),
            file_path=data['file_path'],
            file_name=data['file_name'],
            file_type=data['file_type'],
            file_size=data.get('file_size'),
            is_public=data.get('is_public', False)
        )
        
        if not material_id:
            return jsonify({'error': message}), 400
        
        return jsonify({
            'success': True,
            'message': 'Material uploaded successfully',
            'material_id': material_id
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/profile', methods=['GET'])
@auth_middleware.teacher_required
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
@auth_middleware.teacher_required
def update_profile():
    """Update teacher profile"""
    try:
        teacher_id = session.get('user_id')
        data = request.get_json()
        
        # Remove fields that shouldn't be updated directly
        data.pop('id', None)
        data.pop('institution_id', None)
        data.pop('created_at', None)
        
        # Update profile
        success = db.update_teacher(teacher_id, **data)
        if not success:
            return jsonify({'error': 'Failed to update profile'}), 400
        
        return jsonify({
            'success': True,
            'message': 'Profile updated successfully'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/logout', methods=['POST'])
def logout():
    """Teacher logout"""
    try:
        session.clear()
        return jsonify({
            'success': True,
            'message': 'Logged out successfully',
            'redirect_url': '/teacher/login'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

