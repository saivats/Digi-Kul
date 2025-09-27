"""
Student Routes
Handles student-specific functionality including enrollment, materials, quizzes, and profile management.
"""

from flask import Blueprint, request, jsonify, session, redirect, url_for, render_template
from werkzeug.security import check_password_hash, generate_password_hash
from datetime import datetime
from utils.database_supabase import SupabaseDatabaseManager as DatabaseManager
from middlewares.auth_middleware import AuthMiddleware
from utils.email_service import EmailService

# Initialize blueprint
student_bp = Blueprint('student', __name__)

# Initialize services
db = DatabaseManager()
auth_middleware = AuthMiddleware(None, db)
email_service = EmailService()

@student_bp.route('/login', methods=['GET', 'POST'])
def login():
    """Student login"""
    if request.method == 'GET':
        return render_template('student_login.html')
    
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({'error': 'Email and password required'}), 400
        
        # Get student by email
        student = db.get_student_by_email(email)
        if not student:
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Verify password
        if not check_password_hash(student['password_hash'], password):
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Create session
        session.permanent = True
        session['user_id'] = student['id']
        session['user_type'] = 'student'
        session['user_name'] = student['name']
        session['user_email'] = student['email']
        session['institution_id'] = student['institution_id']
        
        # Track online users
        auth_middleware.online_users[student['id']] = {
            'name': student['name'],
            'email': student['email'],
            'type': 'student',
            'login_time': datetime.now().isoformat()
        }
        
        # Update last login
        db.update_student_last_login(student['id'])
        
        return jsonify({
            'success': True,
            'message': 'Login successful',
            'redirect_url': '/student/dashboard'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/dashboard')
@auth_middleware.student_required
def dashboard():
    """Student dashboard"""
    return render_template('student_dashboard.html')

@student_bp.route('/enroll', methods=['POST'])
@auth_middleware.student_required
def enroll_in_cohort():
    """Enroll in a cohort using enrollment code"""
    try:
        data = request.get_json()
        enrollment_code = data.get('enrollment_code')
        
        if not enrollment_code:
            return jsonify({'error': 'Enrollment code required'}), 400
        
        student_id = session.get('user_id')
        
        # Get cohort by enrollment code
        cohort = db.get_cohort_by_enrollment_code(enrollment_code)
        if not cohort:
            return jsonify({'error': 'Invalid enrollment code'}), 404
        
        # Check if student is already enrolled
        student_cohorts = db.get_student_cohorts(student_id)
        if any(c['id'] == cohort['id'] for c in student_cohorts):
            return jsonify({'error': 'Already enrolled in this cohort'}), 409
        
        # Enroll student in cohort
        success = db.enroll_student_in_cohort(student_id, cohort['id'])
        
        if success:
            return jsonify({
                'success': True,
                'message': 'Successfully enrolled in cohort',
                'cohort': {
                    'id': cohort['id'],
                    'name': cohort['name'],
                    'subject': cohort['subject']
                }
            }), 200
        else:
            return jsonify({'error': 'Failed to enroll in cohort'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/cohorts', methods=['GET'])
@auth_middleware.student_required
def get_cohorts():
    """Get student's enrolled cohorts"""
    try:
        student_id = session.get('user_id')
        cohorts = db.get_student_cohorts(student_id)
        
        return jsonify({
            'success': True,
            'cohorts': cohorts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/lectures', methods=['GET'])
@auth_middleware.student_required
def get_lectures():
    """Get lectures for student's cohorts"""
    try:
        student_id = session.get('user_id')
        
        # Get student's cohorts
        cohorts = db.get_student_cohorts(student_id)
        cohort_ids = [c['id'] for c in cohorts]
        
        if not cohort_ids:
            return jsonify({
                'success': True,
                'lectures': []
            }), 200
        
        # Get lectures for these cohorts
        lectures = []
        for cohort_id in cohort_ids:
            cohort_lectures = db.get_lectures_by_cohort(cohort_id)
            lectures.extend(cohort_lectures)
        
        # Sort by scheduled time
        lectures.sort(key=lambda x: x.get('scheduled_time', ''))
        
        return jsonify({
            'success': True,
            'lectures': lectures
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/materials', methods=['GET'])
@auth_middleware.student_required
def get_materials():
    """Get materials for student's cohorts"""
    try:
        student_id = session.get('user_id')
        
        # Get student's cohorts
        cohorts = db.get_student_cohorts(student_id)
        cohort_ids = [c['id'] for c in cohorts]
        
        if not cohort_ids:
            return jsonify({
                'success': True,
                'materials': []
            }), 200
        
        # Get materials for these cohorts
        materials = db.get_materials_by_cohorts(cohort_ids)
        
        return jsonify({
            'success': True,
            'materials': materials
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/quizzes', methods=['GET'])
@auth_middleware.student_required
def get_quizzes():
    """Get available quizzes for student's cohorts"""
    try:
        student_id = session.get('user_id')
        
        # Get student's cohorts
        cohorts = db.get_student_cohorts(student_id)
        cohort_ids = [c['id'] for c in cohorts]
        
        if not cohort_ids:
            return jsonify({
                'success': True,
                'quiz_sets': []
            }), 200
        
        # Get quiz sets for these cohorts
        quiz_sets = db.get_quiz_sets_by_cohorts(cohort_ids)
        
        return jsonify({
            'success': True,
            'quiz_sets': quiz_sets
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/quiz-attempts', methods=['POST'])
@auth_middleware.student_required
def start_quiz_attempt():
    """Start a quiz attempt"""
    try:
        data = request.get_json()
        quiz_set_id = data.get('quiz_set_id')
        
        if not quiz_set_id:
            return jsonify({'error': 'Quiz set ID required'}), 400
        
        student_id = session.get('user_id')
        
        # Check if student has access to this quiz
        student_cohorts = db.get_student_cohorts(student_id)
        cohort_ids = [c['id'] for c in student_cohorts]
        
        quiz_set = db.get_quiz_set_by_id(quiz_set_id)
        if not quiz_set or quiz_set['cohort_id'] not in cohort_ids:
            return jsonify({'error': 'Access denied to this quiz'}), 403
        
        # Start quiz attempt
        attempt_id = db.start_quiz_attempt(
            student_id=student_id,
            quiz_set_id=quiz_set_id
        )
        
        if attempt_id:
            return jsonify({
                'success': True,
                'attempt_id': attempt_id,
                'message': 'Quiz attempt started'
            }), 200
        else:
            return jsonify({'error': 'Failed to start quiz attempt'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/quiz-responses', methods=['POST'])
@auth_middleware.student_required
def submit_quiz_response():
    """Submit a quiz response"""
    try:
        data = request.get_json()
        attempt_id = data.get('attempt_id')
        question_id = data.get('question_id')
        response = data.get('response')
        
        if not all([attempt_id, question_id, response is not None]):
            return jsonify({'error': 'Missing required fields'}), 400
        
        student_id = session.get('user_id')
        
        # Verify attempt belongs to student
        attempt = db.get_quiz_attempt_by_id(attempt_id)
        if not attempt or attempt['student_id'] != student_id:
            return jsonify({'error': 'Access denied'}), 403
        
        # Submit response
        success = db.submit_quiz_response(
            attempt_id=attempt_id,
            question_id=question_id,
            response=response
        )
        
        if success:
            return jsonify({
                'success': True,
                'message': 'Response submitted successfully'
            }), 200
        else:
            return jsonify({'error': 'Failed to submit response'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/quiz-attempts/<attempt_id>/finish', methods=['POST'])
@auth_middleware.student_required
def finish_quiz_attempt(attempt_id):
    """Finish a quiz attempt"""
    try:
        student_id = session.get('user_id')
        
        # Verify attempt belongs to student
        attempt = db.get_quiz_attempt_by_id(attempt_id)
        if not attempt or attempt['student_id'] != student_id:
            return jsonify({'error': 'Access denied'}), 403
        
        # Finish attempt
        result = db.finish_quiz_attempt(attempt_id)
        
        if result:
            return jsonify({
                'success': True,
                'result': result,
                'message': 'Quiz completed successfully'
            }), 200
        else:
            return jsonify({'error': 'Failed to finish quiz attempt'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/profile', methods=['GET'])
@auth_middleware.student_required
def get_profile():
    """Get student profile"""
    try:
        student_id = session.get('user_id')
        student = db.get_student_by_id(student_id)
        
        if not student:
            return jsonify({'error': 'Student not found'}), 404
        
        # Remove sensitive data
        student.pop('password_hash', None)
        
        return jsonify({
            'success': True,
            'student': student
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/profile', methods=['PUT'])
@auth_middleware.student_required
def update_profile():
    """Update student profile"""
    try:
        student_id = session.get('user_id')
        data = request.get_json()
        
        # Remove fields that shouldn't be updated directly
        data.pop('id', None)
        data.pop('institution_id', None)
        data.pop('created_at', None)
        
        # Update student
        updated = db.update_student(student_id, **data)
        
        if updated:
            return jsonify({
                'success': True,
                'message': 'Profile updated successfully'
            }), 200
        else:
            return jsonify({'error': 'Failed to update profile'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/logout', methods=['POST'])
@auth_middleware.student_required
def logout():
    """Student logout"""
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