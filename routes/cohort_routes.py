"""
Cohort Routes
Handles cohort management, student assignments, and cohort-related operations.
"""

from flask import Blueprint, request, jsonify, session, g
from middlewares.auth_middleware import AuthMiddleware
from middlewares.cohort_middleware import CohortMiddleware
from services.cohort_service import CohortService
from utils.database_supabase import DatabaseManager
from utils.email_service import EmailService

# Initialize blueprint
cohort_bp = Blueprint('cohort', __name__)

# Initialize services
db = DatabaseManager()
email_service = EmailService()
cohort_service = CohortService(db, email_service)

# Initialize middleware
auth_middleware = AuthMiddleware(None, db)
cohort_middleware = CohortMiddleware(None, db)

@cohort_bp.route('/api/cohorts', methods=['GET'])
@auth_middleware.api_login_required
def get_cohorts():
    """Get all cohorts for the current user"""
    try:
        user_type = session.get('user_type')
        user_id = session.get('user_id')
        
        if user_type == 'student':
            cohorts = cohort_service.get_student_cohorts(user_id)
        elif user_type == 'teacher':
            cohorts = cohort_service.get_teacher_cohorts(user_id)
        elif user_type == 'admin':
            cohorts = cohort_service.get_all_cohorts()
        else:
            return jsonify({'error': 'Invalid user type'}), 400
        
        return jsonify({
            'success': True,
            'cohorts': cohorts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@cohort_bp.route('/api/cohorts', methods=['POST'])
@auth_middleware.api_admin_required
def create_cohort():
    """Create a new cohort (admin only)"""
    try:
        data = request.get_json()
        
        if not all(key in data for key in ['name', 'description', 'subject', 'teacher_id', 'institution_id']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        cohort_id, response = cohort_service.create_cohort(
            data['name'], 
            data['description'], 
            data['subject'], 
            data['teacher_id'],
            data['institution_id']
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
        return jsonify({'error': str(e)}), 500

@cohort_bp.route('/api/cohorts/<cohort_id>', methods=['GET'])
@auth_middleware.api_login_required
def get_cohort(cohort_id):
    """Get cohort details by ID"""
    try:
        # Verify user has access to this cohort
        if not cohort_middleware.validate_cohort_access(cohort_id):
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        cohort = cohort_service.get_cohort_by_id(cohort_id)
        
        if not cohort:
            return jsonify({'error': 'Cohort not found'}), 404
        
        return jsonify({
            'success': True,
            'cohort': cohort
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@cohort_bp.route('/api/cohorts/<cohort_id>', methods=['DELETE'])
@auth_middleware.api_admin_required
def delete_cohort(cohort_id):
    """Delete a cohort (admin only)"""
    try:
        success, response = cohort_service.delete_cohort(cohort_id)
        
        if success:
            return jsonify({
                'success': True,
                'message': 'Cohort deleted successfully'
            }), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@cohort_bp.route('/api/cohorts/<cohort_id>/students', methods=['GET'])
@auth_middleware.api_login_required
def get_cohort_students(cohort_id):
    """Get students in a cohort"""
    try:
        # Verify user has access to this cohort
        if not cohort_middleware.validate_cohort_access(cohort_id):
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        students = cohort_service.get_cohort_students(cohort_id)
        
        return jsonify({
            'success': True,
            'students': students
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@cohort_bp.route('/api/cohorts/<cohort_id>/students', methods=['POST'])
@auth_middleware.api_admin_required
def add_student_to_cohort(cohort_id):
    """Add a student to a cohort (admin only)"""
    try:
        data = request.get_json()
        student_id = data.get('student_id')
        student_email = data.get('student_email')
        
        if not student_id and not student_email:
            return jsonify({'error': 'student_id or student_email is required'}), 400
        
        if not student_id and student_email:
            student = db.get_student_by_email(student_email)
            if not student:
                return jsonify({'error': 'Student not found'}), 404
            student_id = student['id']
        
        success, msg = cohort_service.add_student_to_cohort(cohort_id, student_id)
        
        if success:
            return jsonify({
                'success': True,
                'message': msg
            }), 200
        else:
            return jsonify({'error': msg}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@cohort_bp.route('/api/cohorts/<cohort_id>/students/<student_id>', methods=['DELETE'])
@auth_middleware.api_admin_required
def remove_student_from_cohort(cohort_id, student_id):
    """Remove a student from a cohort (admin only)"""
    try:
        success, msg = cohort_service.remove_student_from_cohort(cohort_id, student_id)
        
        if success:
            return jsonify({
                'success': True,
                'message': msg
            }), 200
        else:
            return jsonify({'error': msg}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@cohort_bp.route('/api/cohorts/join', methods=['POST'])
@auth_middleware.api_student_required
def join_cohort_by_code():
    """Student joins a cohort using cohort code"""
    try:
        data = request.get_json()
        cohort_code = data.get('cohort_code')
        
        if not cohort_code:
            return jsonify({'error': 'Cohort code is required'}), 400
        
        student_id = session.get('user_id')
        success, response = cohort_service.join_cohort_by_code(student_id, cohort_code)
        
        if success:
            return jsonify({
                'success': True,
                'message': response
            }), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@cohort_bp.route('/api/cohorts/<cohort_id>/analytics', methods=['GET'])
@auth_middleware.api_login_required
def get_cohort_analytics(cohort_id):
    """Get analytics for a cohort"""
    try:
        # Verify user has access to this cohort
        if not cohort_middleware.validate_cohort_access(cohort_id):
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        analytics = cohort_service.get_cohort_analytics(cohort_id)
        
        return jsonify({
            'success': True,
            'analytics': analytics
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@cohort_bp.route('/api/institutions', methods=['GET'])
@auth_middleware.api_admin_required
def get_institutions():
    """Get all institutions (admin only)"""
    try:
        institutions = cohort_service.get_all_institutions()
        
        return jsonify({
            'success': True,
            'institutions': institutions
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@cohort_bp.route('/api/institutions', methods=['POST'])
@auth_middleware.api_admin_required
def create_institution():
    """Create a new institution (admin only)"""
    try:
        data = request.get_json()
        
        if not all(key in data for key in ['name']):
            return jsonify({'error': 'Institution name is required'}), 400
        
        institution_id, response = cohort_service.create_institution(
            data['name'],
            data.get('domain'),
            data.get('description')
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
        return jsonify({'error': str(e)}), 500

@cohort_bp.route('/api/institutions/<institution_id>', methods=['GET'])
@auth_middleware.api_admin_required
def get_institution(institution_id):
    """Get institution details by ID (admin only)"""
    try:
        institution = cohort_service.get_institution_by_id(institution_id)
        
        if not institution:
            return jsonify({'error': 'Institution not found'}), 404
        
        return jsonify({
            'success': True,
            'institution': institution
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@cohort_bp.route('/api/institutions/<institution_id>/cohorts', methods=['GET'])
@auth_middleware.api_admin_required
def get_institution_cohorts(institution_id):
    """Get all cohorts for an institution (admin only)"""
    try:
        cohorts = cohort_service.get_cohorts_by_institution(institution_id)
        
        return jsonify({
            'success': True,
            'cohorts': cohorts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@cohort_bp.route('/api/cohorts/<cohort_id>/assign-teacher', methods=['POST'])
@auth_middleware.api_admin_required
def assign_teacher_to_cohort(cohort_id):
    """Assign a teacher to a cohort (admin only)"""
    try:
        data = request.get_json()
        teacher_id = data.get('teacher_id')
        
        if not teacher_id:
            return jsonify({'error': 'Teacher ID is required'}), 400
        
        success, response = cohort_service.assign_teacher_to_cohort(cohort_id, teacher_id)
        
        if success:
            return jsonify({
                'success': True,
                'message': response
            }), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@cohort_bp.route('/api/cohorts/<cohort_id>/lectures', methods=['GET'])
@auth_middleware.api_login_required
def get_cohort_lectures(cohort_id):
    """Get lectures for a cohort"""
    try:
        # Verify user has access to this cohort
        if not cohort_middleware.validate_cohort_access(cohort_id):
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        from services.lecture_service import LectureService
        lecture_service = LectureService(db, email_service)
        lectures = lecture_service.get_cohort_lectures(cohort_id)
        
        return jsonify({
            'success': True,
            'lectures': lectures
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

