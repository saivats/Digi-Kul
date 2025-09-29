"""
Lecture Routes
Handles lecture management, scheduling, materials, and notifications.
"""

from flask import Blueprint, request, jsonify, session, send_file
from werkzeug.utils import secure_filename
from middlewares.auth_middleware import AuthMiddleware
from middlewares.cohort_middleware import CohortMiddleware
from services.lecture_service import LectureService
from utils.database_supabase import DatabaseManager
from utils.email_service import EmailService
from utils.compression import compress_audio, compress_image, compress_pdf, get_file_type
import os
import uuid

# Initialize blueprint
lecture_bp = Blueprint('lecture', __name__)

# Initialize services
db = DatabaseManager()
email_service = EmailService()
lecture_service = LectureService(db, email_service)

# Initialize middleware
auth_middleware = AuthMiddleware(None, db)
cohort_middleware = CohortMiddleware(None, db)

@lecture_bp.route('/api/lectures', methods=['POST'])
@auth_middleware.api_teacher_required
def create_lecture():
    """Create a new lecture"""
    try:
        data = request.get_json()
        
        if not all(key in data for key in ['title', 'description', 'scheduled_time', 'duration']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        teacher_id = session.get('user_id')
        cohort_id = data.get('cohort_id')
        
        # If cohort_id provided, verify teacher has access
        if cohort_id and not cohort_middleware.validate_cohort_access(cohort_id):
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        lecture_id, response = lecture_service.create_lecture(
            teacher_id=teacher_id,
            title=data['title'],
            description=data['description'],
            scheduled_time=data['scheduled_time'],
            duration=data['duration'],
            cohort_id=cohort_id
        )
        
        if lecture_id:
            return jsonify({
                'success': True,
                'message': 'Lecture created successfully',
                'lecture_id': lecture_id
            }), 201
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@lecture_bp.route('/api/lectures/instant', methods=['POST'])
@auth_middleware.api_teacher_required
def create_instant_lecture():
    """Create an instant lecture starting now"""
    try:
        data = request.get_json()
        
        if not all(key in data for key in ['title', 'description', 'duration']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        teacher_id = session.get('user_id')
        cohort_id = data.get('cohort_id')
        
        # If cohort_id provided, verify teacher has access
        if cohort_id and not cohort_middleware.validate_cohort_access(cohort_id):
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        lecture_id, response = lecture_service.create_instant_lecture(
            teacher_id=teacher_id,
            title=data['title'],
            description=data['description'],
            duration=data['duration'],
            cohort_id=cohort_id
        )
        
        if lecture_id:
            return jsonify({
                'success': True,
                'message': 'Instant lecture created successfully',
                'lecture_id': lecture_id
            }), 201
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@lecture_bp.route('/api/lectures', methods=['GET'])
@auth_middleware.api_login_required
def get_lectures():
    """Get lectures for the current user"""
    try:
        user_type = session.get('user_type')
        user_id = session.get('user_id')
        
        if user_type == 'student':
            lectures = lecture_service.get_student_lectures(user_id)
        elif user_type == 'teacher':
            lectures = lecture_service.get_teacher_lectures(user_id)
        elif user_type == 'admin':
            # Admins can see all lectures
            lectures = []  # Would need to implement get_all_lectures
        else:
            return jsonify({'error': 'Invalid user type'}), 400
        
        return jsonify({
            'success': True,
            'lectures': lectures
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@lecture_bp.route('/api/lectures/<lecture_id>', methods=['GET', 'DELETE'])
@auth_middleware.api_login_required
def get_or_delete_lecture(lecture_id):
    """Get lecture details by ID or delete lecture"""
    try:
        if request.method == 'GET':
            lecture = lecture_service.get_lecture_by_id(lecture_id)
            
            if not lecture:
                return jsonify({'error': 'Lecture not found'}), 404
            
            # Check if user has access to this lecture
            user_type = session.get('user_type')
            user_id = session.get('user_id')
            
            if user_type == 'teacher':
                if lecture['teacher_id'] != user_id:
                    return jsonify({'error': 'Access denied to this lecture'}), 403
            elif user_type == 'student':
                # Check if student is enrolled in a cohort that has this lecture
                student_lectures = lecture_service.get_student_lectures(user_id)
                if not any(l['id'] == lecture_id for l in student_lectures):
                    return jsonify({'error': 'Access denied to this lecture'}), 403
            
            return jsonify({
                'success': True,
                'lecture': lecture
            }), 200
            
        elif request.method == 'DELETE':
            # Only teachers can delete lectures
            if session.get('user_type') != 'teacher':
                return jsonify({'error': 'Only teachers can delete lectures'}), 403
            
            lecture = lecture_service.get_lecture_by_id(lecture_id)
            if not lecture:
                return jsonify({'error': 'Lecture not found'}), 404
            
            # Verify teacher owns this lecture
            if lecture['teacher_id'] != session.get('user_id'):
                return jsonify({'error': 'Access denied to this lecture'}), 403
            
            success = lecture_service.delete_lecture(lecture_id)
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Lecture deleted successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to delete lecture'}), 500
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@lecture_bp.route('/api/lectures/active', methods=['GET'])
@auth_middleware.api_login_required
def get_active_lectures():
    """Get all currently active lectures"""
    try:
        lectures = lecture_service.get_active_lectures()
        
        return jsonify({
            'success': True,
            'lectures': lectures
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@lecture_bp.route('/api/lectures/<lecture_id>/materials', methods=['POST'])
@auth_middleware.api_teacher_required
def upload_material(lecture_id):
    """Upload teaching material with automatic compression"""
    try:
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        title = request.form.get('title', 'Untitled')
        description = request.form.get('description', '')
        
        # Verify teacher owns this lecture
        lecture = lecture_service.get_lecture_by_id(lecture_id)
        if not lecture or lecture['teacher_id'] != session['user_id']:
            return jsonify({'error': 'Unauthorized'}), 403
        
        # Process file upload
        filename = secure_filename(file.filename)
        file_type = get_file_type(filename)
        
        # Create upload directories
        upload_subdir = os.path.join('uploads', file_type + 's')
        compressed_subdir = os.path.join('compressed', file_type + 's')
        os.makedirs(upload_subdir, exist_ok=True)
        os.makedirs(compressed_subdir, exist_ok=True)
        
        # Save original file
        original_filename = f"{uuid.uuid4()}_{filename}"
        original_path = os.path.join(upload_subdir, original_filename)
        file.save(original_path)
        
        # Create compressed version
        compressed_filename = f"compressed_{original_filename}"
        compressed_path = os.path.join(compressed_subdir, compressed_filename)
        
        original_size = os.path.getsize(original_path)
        
        # Compress based on file type
        if file_type == 'audio':
            compressed_size = compress_audio(original_path, compressed_path)
        elif file_type == 'image':
            compressed_size = compress_image(original_path, compressed_path)
        elif file_type == 'document':
            if filename.lower().endswith('.pdf'):
                compressed_size = compress_pdf(original_path, compressed_path)
            else:
                # Copy as-is for non-PDF documents
                with open(original_path, 'rb') as f_in:
                    with open(compressed_path, 'wb') as f_out:
                        f_out.write(f_in.read())
                compressed_size = original_size
        else:
            # Copy as-is for other file types
            with open(original_path, 'rb') as f_in:
                with open(compressed_path, 'wb') as f_out:
                    f_out.write(f_in.read())
            compressed_size = original_size
        
        # Add material to database
        material_id, response = lecture_service.add_material(
            lecture_id=lecture_id,
            title=title,
            description=description,
            file_path=original_path,
            compressed_path=compressed_path,
            file_size=compressed_size,
            file_type=file_type
        )
        
        if material_id:
            return jsonify({
                'success': True,
                'message': 'File uploaded and compressed successfully',
                'material_id': material_id,
                'original_size': original_size,
                'compressed_size': compressed_size,
                'compression_ratio': f"{((original_size - compressed_size) / original_size * 100):.2f}%" if original_size > 0 else "0%"
            }), 201
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@lecture_bp.route('/api/lectures/<lecture_id>/materials', methods=['GET'])
@auth_middleware.api_login_required
def get_lecture_materials(lecture_id):
    """Get materials for a lecture"""
    try:
        # Verify user has access to this lecture
        lecture = lecture_service.get_lecture_by_id(lecture_id)
        if not lecture:
            return jsonify({'error': 'Lecture not found'}), 404
        
        user_type = session.get('user_type')
        user_id = session.get('user_id')
        
        if user_type == 'teacher':
            if lecture['teacher_id'] != user_id:
                return jsonify({'error': 'Unauthorized'}), 403
        elif user_type == 'student':
            # Check if student has access to this lecture
            student_lectures = lecture_service.get_student_lectures(user_id)
            if not any(l['id'] == lecture_id for l in student_lectures):
                return jsonify({'error': 'Unauthorized'}), 403
        
        materials = lecture_service.get_lecture_materials(lecture_id)
        
        # Add download URLs and file info
        for material in materials:
            material['download_url'] = f"/api/download/{material['id']}"
            material['file_size_mb'] = round(material['file_size'] / (1024 * 1024), 2)
        
        return jsonify({
            'success': True,
            'materials': materials
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@lecture_bp.route('/api/download/<material_id>')
@auth_middleware.login_required
def download_material(material_id):
    """Download teaching material"""
    try:
        material = db.get_material_details(material_id)
        
        if not material:
            return jsonify({'error': 'Material not found'}), 404
        
        # Check if user has access to this material
        lecture = lecture_service.get_lecture_by_id(material['lecture_id'])
        if not lecture:
            return jsonify({'error': 'Lecture not found'}), 404
        
        user_type = session.get('user_type')
        user_id = session.get('user_id')
        
        if user_type == 'teacher':
            if lecture['teacher_id'] != user_id:
                return jsonify({'error': 'Unauthorized'}), 403
        elif user_type == 'student':
            # Check if student has access to this lecture
            student_lectures = lecture_service.get_student_lectures(user_id)
            if not any(l['id'] == material['lecture_id'] for l in student_lectures):
                return jsonify({'error': 'Unauthorized'}), 403
        
        if not os.path.exists(material['compressed_path']):
            return jsonify({'error': 'File not found'}), 404
        
        return send_file(material['compressed_path'], as_attachment=True)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@lecture_bp.route('/api/materials/<material_id>', methods=['DELETE'])
@auth_middleware.api_teacher_required
def delete_material(material_id):
    """Delete a material (teacher only)"""
    try:
        # Get material details to verify ownership
        material = db.get_material_by_id(material_id)
        if not material:
            return jsonify({'error': 'Material not found'}), 404
        
        # Verify teacher owns the lecture this material belongs to
        lecture = lecture_service.get_lecture_by_id(material['lecture_id'])
        if not lecture or lecture['teacher_id'] != session['user_id']:
            return jsonify({'error': 'Unauthorized'}), 403
        
        success = lecture_service.delete_material(material_id)
        
        if success:
            return jsonify({'success': True, 'message': 'Material deleted successfully'}), 200
        else:
            return jsonify({'error': 'Failed to delete material'}), 500
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@lecture_bp.route('/api/lectures/<lecture_id>/analytics', methods=['GET'])
@auth_middleware.api_teacher_required
def get_lecture_analytics(lecture_id):
    """Get analytics for a lecture"""
    try:
        lecture = lecture_service.get_lecture_by_id(lecture_id)
        
        if not lecture:
            return jsonify({'error': 'Lecture not found'}), 404
        
        # Verify teacher owns this lecture
        if lecture['teacher_id'] != session['user_id']:
            return jsonify({'error': 'Unauthorized'}), 403
        
        analytics = lecture_service.get_lecture_analytics(lecture_id)
        
        return jsonify({
            'success': True,
            'analytics': analytics
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@lecture_bp.route('/api/lectures/expire', methods=['POST'])
@auth_middleware.api_teacher_required
def expire_lectures():
    """Expire all lectures that have ended (teacher only)"""
    try:
        # This could be called by a cron job or manually
        count = lecture_service.expire_all_lectures()
        
        return jsonify({
            'success': True,
            'message': f'{count} lectures expired successfully'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@lecture_bp.route('/api/teachers/<teacher_id>/lecture-analytics', methods=['GET'])
@auth_middleware.api_teacher_required
def get_teacher_lecture_analytics(teacher_id):
    """Get comprehensive analytics for all teacher's lectures"""
    try:
        # Verify teacher is accessing their own analytics
        if session['user_id'] != teacher_id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        analytics = lecture_service.get_teacher_lecture_analytics(teacher_id)
        
        return jsonify({
            'success': True,
            'analytics': analytics
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

