"""
Admin Routes
Handles admin-only operations like user management, system analytics, and global settings.
"""

from flask import Blueprint, request, jsonify, session
from middlewares.auth_middleware import AuthMiddleware
from middlewares.cohort_middleware import CohortMiddleware
from services.admin_service import AdminService
from utils.database_supabase import SupabaseDatabaseManager as DatabaseManager
from utils.email_service import EmailService
import logging

# Initialize blueprint
admin_bp = Blueprint('admin', __name__)

# Initialize services
db = DatabaseManager()
email_service = EmailService()
admin_service = AdminService(db, email_service)

# Initialize middleware
auth_middleware = AuthMiddleware(None, db)
cohort_middleware = CohortMiddleware(None, db)

logger = logging.getLogger(__name__)

# ==================== USER MANAGEMENT ====================

@admin_bp.route('/api/users/teachers', methods=['GET'])
@auth_middleware.api_admin_required
def get_all_teachers():
    """Get all teachers with their details"""
    try:
        teachers = admin_service.get_all_teachers()
        
        return jsonify({
            'success': True,
            'teachers': teachers
        }), 200
        
    except Exception as e:
        logger.error(f"Error fetching teachers: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/users/students', methods=['GET'])
@auth_middleware.api_admin_required
def get_all_students():
    """Get all students with their details"""
    try:
        students = admin_service.get_all_students()
        
        return jsonify({
            'success': True,
            'students': students
        }), 200
        
    except Exception as e:
        logger.error(f"Error fetching students: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/users/teachers', methods=['POST'])
@auth_middleware.api_admin_required
def create_teacher():
    """Create a new teacher"""
    try:
        data = request.get_json()
        
        if not all(key in data for key in ['name', 'email', 'institution_id', 'subject', 'password']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        teacher_id, response = admin_service.create_teacher(
            name=data['name'],
            email=data['email'],
            institution_id=data['institution_id'],
            subject=data['subject'],
            password=data['password']
        )
        
        if teacher_id:
            return jsonify({
                'success': True,
                'message': 'Teacher created successfully',
                'teacher_id': teacher_id
            }), 201
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        logger.error(f"Error creating teacher: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/users/students', methods=['POST'])
@auth_middleware.api_admin_required
def create_student():
    """Create a new student"""
    try:
        data = request.get_json()
        
        if not all(key in data for key in ['name', 'email', 'institution_id', 'password', 'cohort_ids']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        student_id, response = admin_service.create_student(
            name=data['name'],
            email=data['email'],
            institution_id=data['institution_id'],
            password=data['password'],
            cohort_ids=data['cohort_ids']
        )
        
        if student_id:
            return jsonify({
                'success': True,
                'message': 'Student created successfully',
                'student_id': student_id
            }), 201
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        logger.error(f"Error creating student: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/users/teachers/<teacher_id>', methods=['PUT'])
@auth_middleware.api_admin_required
def update_teacher(teacher_id):
    """Update teacher details"""
    try:
        data = request.get_json()
        
        success, response = admin_service.update_teacher(
            teacher_id=teacher_id,
            name=data.get('name'),
            email=data.get('email'),
            institution_id=data.get('institution_id'),
            subject=data.get('subject'),
            is_active=data.get('is_active')
        )
        
        if success:
            return jsonify({'success': True, 'message': response}), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        logger.error(f"Error updating teacher: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/users/students/<student_id>', methods=['PUT'])
@auth_middleware.api_admin_required
def update_student(student_id):
    """Update student details"""
    try:
        data = request.get_json()
        
        success, response = admin_service.update_student(
            student_id=student_id,
            name=data.get('name'),
            email=data.get('email'),
            institution_id=data.get('institution_id'),
            is_active=data.get('is_active')
        )
        
        if success:
            return jsonify({'success': True, 'message': response}), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        logger.error(f"Error updating student: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/users/teachers/<teacher_id>', methods=['DELETE'])
@auth_middleware.api_admin_required
def delete_teacher(teacher_id):
    """Delete a teacher (soft delete)"""
    try:
        success, response = admin_service.delete_teacher(teacher_id)
        
        if success:
            return jsonify({'success': True, 'message': response}), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        logger.error(f"Error deleting teacher: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/users/students/<student_id>', methods=['DELETE'])
@auth_middleware.api_admin_required
def delete_student(student_id):
    """Delete a student (soft delete)"""
    try:
        success, response = admin_service.delete_student(student_id)
        
        if success:
            return jsonify({'success': True, 'message': response}), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        logger.error(f"Error deleting student: {e}")
        return jsonify({'error': str(e)}), 500

# ==================== INSTITUTION MANAGEMENT ====================

@admin_bp.route('/api/institutions', methods=['GET'])
@auth_middleware.api_admin_required
def get_all_institutions():
    """Get all institutions"""
    try:
        institutions = admin_service.get_all_institutions()
        
        return jsonify({
            'success': True,
            'institutions': institutions
        }), 200
        
    except Exception as e:
        logger.error(f"Error fetching institutions: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/institutions', methods=['POST'])
@auth_middleware.api_admin_required
def create_institution():
    """Create a new institution"""
    try:
        data = request.get_json()
        
        if not data.get('name'):
            return jsonify({'error': 'Institution name is required'}), 400
        
        institution_id, response = admin_service.create_institution(
            name=data['name'],
            domain=data.get('domain'),
            description=data.get('description')
        )
        
        if institution_id:
            return jsonify({
                'success': True,
                'message': 'Institution created successfully',
                'institution_id': institution_id
            }), 201
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        logger.error(f"Error creating institution: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/institutions/<institution_id>', methods=['PUT'])
@auth_middleware.api_admin_required
def update_institution(institution_id):
    """Update institution details"""
    try:
        data = request.get_json()
        
        success, response = admin_service.update_institution(
            institution_id=institution_id,
            name=data.get('name'),
            domain=data.get('domain'),
            description=data.get('description'),
            is_active=data.get('is_active')
        )
        
        if success:
            return jsonify({'success': True, 'message': response}), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        logger.error(f"Error updating institution: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/institutions/<institution_id>', methods=['DELETE'])
@auth_middleware.api_admin_required
def delete_institution(institution_id):
    """Delete an institution (soft delete)"""
    try:
        success, response = admin_service.delete_institution(institution_id)
        
        if success:
            return jsonify({'success': True, 'message': response}), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        logger.error(f"Error deleting institution: {e}")
        return jsonify({'error': str(e)}), 500

# ==================== COHORT MANAGEMENT ====================

@admin_bp.route('/api/cohorts', methods=['GET'])
@auth_middleware.api_admin_required
def get_all_cohorts():
    """Get all cohorts with their details"""
    try:
        cohorts = admin_service.get_all_cohorts()
        
        return jsonify({
            'success': True,
            'cohorts': cohorts
        }), 200
        
    except Exception as e:
        logger.error(f"Error fetching cohorts: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/cohorts', methods=['POST'])
@auth_middleware.api_admin_required
def create_cohort():
    """Create a new cohort"""
    try:
        data = request.get_json()
        
        if not all(key in data for key in ['name', 'subject', 'institution_id', 'teacher_id']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        cohort_id, response = admin_service.create_cohort(
            name=data['name'],
            description=data.get('description'),
            subject=data['subject'],
            institution_id=data['institution_id'],
            teacher_id=data['teacher_id']
        )
        
        if cohort_id:
            return jsonify({
                'success': True,
                'message': 'Cohort created successfully',
                'cohort_id': cohort_id
            }), 201
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        logger.error(f"Error creating cohort: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/cohorts/<cohort_id>/students', methods=['POST'])
@auth_middleware.api_admin_required
def add_student_to_cohort(cohort_id):
    """Add a student to a cohort"""
    try:
        data = request.get_json()
        student_id = data.get('student_id')
        
        if not student_id:
            return jsonify({'error': 'Student ID is required'}), 400
        
        success, response = admin_service.add_student_to_cohort(cohort_id, student_id)
        
        if success:
            return jsonify({'success': True, 'message': response}), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        logger.error(f"Error adding student to cohort: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/cohorts/<cohort_id>/students/<student_id>', methods=['DELETE'])
@auth_middleware.api_admin_required
def remove_student_from_cohort(cohort_id, student_id):
    """Remove a student from a cohort"""
    try:
        success, response = admin_service.remove_student_from_cohort(cohort_id, student_id)
        
        if success:
            return jsonify({'success': True, 'message': response}), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        logger.error(f"Error removing student from cohort: {e}")
        return jsonify({'error': str(e)}), 500

# ==================== SYSTEM ANALYTICS ====================

@admin_bp.route('/api/analytics/overview', methods=['GET'])
@auth_middleware.api_admin_required
def get_system_overview():
    """Get system overview analytics"""
    try:
        overview = admin_service.get_system_overview()
        
        return jsonify({
            'success': True,
            'overview': overview
        }), 200
        
    except Exception as e:
        logger.error(f"Error fetching system overview: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/analytics/institutions/<institution_id>', methods=['GET'])
@auth_middleware.api_admin_required
def get_institution_analytics(institution_id):
    """Get analytics for a specific institution"""
    try:
        analytics = admin_service.get_institution_analytics(institution_id)
        
        return jsonify({
            'success': True,
            'analytics': analytics
        }), 200
        
    except Exception as e:
        logger.error(f"Error fetching institution analytics: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/analytics/cohorts/<cohort_id>', methods=['GET'])
@auth_middleware.api_admin_required
def get_cohort_analytics(cohort_id):
    """Get analytics for a specific cohort"""
    try:
        analytics = admin_service.get_cohort_analytics(cohort_id)
        
        return jsonify({
            'success': True,
            'analytics': analytics
        }), 200
        
    except Exception as e:
        logger.error(f"Error fetching cohort analytics: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/analytics/teachers/<teacher_id>', methods=['GET'])
@auth_middleware.api_admin_required
def get_teacher_analytics(teacher_id):
    """Get analytics for a specific teacher"""
    try:
        analytics = admin_service.get_teacher_analytics(teacher_id)
        
        return jsonify({
            'success': True,
            'analytics': analytics
        }), 200
        
    except Exception as e:
        logger.error(f"Error fetching teacher analytics: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/analytics/students/<student_id>', methods=['GET'])
@auth_middleware.api_admin_required
def get_student_analytics(student_id):
    """Get analytics for a specific student"""
    try:
        analytics = admin_service.get_student_analytics(student_id)
        
        return jsonify({
            'success': True,
            'analytics': analytics
        }), 200
        
    except Exception as e:
        logger.error(f"Error fetching student analytics: {e}")
        return jsonify({'error': str(e)}), 500

# ==================== SYSTEM MANAGEMENT ====================

@admin_bp.route('/api/system/health', methods=['GET'])
@auth_middleware.api_admin_required
def get_system_health():
    """Get system health status"""
    try:
        health = admin_service.get_system_health()
        
        return jsonify({
            'success': True,
            'health': health
        }), 200
        
    except Exception as e:
        logger.error(f"Error fetching system health: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/system/cleanup', methods=['POST'])
@auth_middleware.api_admin_required
def cleanup_system():
    """Perform system cleanup tasks"""
    try:
        data = request.get_json()
        cleanup_type = data.get('type', 'all')
        
        result = admin_service.perform_cleanup(cleanup_type)
        
        return jsonify({
            'success': True,
            'message': 'Cleanup completed successfully',
            'result': result
        }), 200
        
    except Exception as e:
        logger.error(f"Error performing cleanup: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/system/backup', methods=['POST'])
@auth_middleware.api_admin_required
def backup_system():
    """Create system backup"""
    try:
        backup_info = admin_service.create_backup()
        
        return jsonify({
            'success': True,
            'message': 'Backup created successfully',
            'backup_info': backup_info
        }), 200
        
    except Exception as e:
        logger.error(f"Error creating backup: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/system/logs', methods=['GET'])
@auth_middleware.api_admin_required
def get_system_logs():
    """Get system logs"""
    try:
        level = request.args.get('level', 'INFO')
        limit = int(request.args.get('limit', 100))
        
        logs = admin_service.get_system_logs(level, limit)
        
        return jsonify({
            'success': True,
            'logs': logs
        }), 200
        
    except Exception as e:
        logger.error(f"Error fetching system logs: {e}")
        return jsonify({'error': str(e)}), 500

# ==================== EMAIL MANAGEMENT ====================

@admin_bp.route('/api/email/test', methods=['POST'])
@auth_middleware.api_admin_required
def test_email():
    """Test email configuration"""
    try:
        data = request.get_json()
        test_email = data.get('email', session.get('user_email'))
        
        success, response = admin_service.test_email_configuration(test_email)
        
        if success:
            return jsonify({'success': True, 'message': response}), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        logger.error(f"Error testing email: {e}")
        return jsonify({'error': str(e)}), 500

@admin_bp.route('/api/email/send-bulk', methods=['POST'])
@auth_middleware.api_admin_required
def send_bulk_email():
    """Send bulk email to users"""
    try:
        data = request.get_json()
        
        if not all(key in data for key in ['subject', 'message', 'recipients']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        result = admin_service.send_bulk_email(
            subject=data['subject'],
            message=data['message'],
            recipients=data['recipients'],
            html_message=data.get('html_message')
        )
        
        return jsonify({
            'success': True,
            'message': 'Bulk email sent successfully',
            'result': result
        }), 200
        
    except Exception as e:
        logger.error(f"Error sending bulk email: {e}")
        return jsonify({'error': str(e)}), 500

