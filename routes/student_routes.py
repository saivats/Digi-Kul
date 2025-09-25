"""
Student Routes
Handles student authentication, enrollment, and learning operations.
"""

from flask import Blueprint, request, jsonify, session, redirect, url_for, flash, render_template
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
        data = request.get_json() if request.is_json else request.form
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({'error': 'Email and password are required'}), 400
        
        # Get student
        student = db.get_student_by_email(email)
        if not student:
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Check password
        if not check_password_hash(student['password_hash'], password):
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Check if student is active
        if not student.get('is_active', True):
            return jsonify({'error': 'Account is deactivated'}), 401
        
        # Update last login
        db.update_student_last_login(student['id'])
        
        # Set session
        session['user_id'] = student['id']
        session['user_type'] = 'student'
        session['institution_id'] = student['institution_id']
        
        return jsonify({
            'success': True,
            'message': 'Login successful',
            'redirect_url': '/student_dashboard'
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
        student_id = session.get('user_id')
        institution_id = session.get('institution_id')
        
        data = request.get_json()
        enrollment_code = data.get('enrollment_code')
        
        if not enrollment_code:
            return jsonify({'error': 'Enrollment code is required'}), 400
        
        # Find cohort by enrollment code
        cohort = db.get_cohort_by_enrollment_code(enrollment_code)
        if not cohort:
            return jsonify({'error': 'Invalid enrollment code'}), 400
        
        # Check if cohort belongs to the same institution
        if cohort['institution_id'] != institution_id:
            return jsonify({'error': 'Enrollment code is not valid for your institution'}), 400
        
        # Check if student is already enrolled
        if db.is_student_enrolled(student_id, cohort['id']):
            return jsonify({'error': 'You are already enrolled in this cohort'}), 400
        
        # Enroll student
        enrollment_id, message = db.enroll_student(student_id, cohort['id'])
        if not enrollment_id:
            return jsonify({'error': message}), 400
        
        return jsonify({
            'success': True,
            'message': 'Successfully enrolled in cohort',
            'enrollment_id': enrollment_id,
            'cohort': cohort
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/cohorts', methods=['GET'])
@auth_middleware.student_required
def get_my_cohorts():
    """Get cohorts the student is enrolled in"""
    try:
        student_id = session.get('user_id')
        cohorts = db.get_student_enrolled_lectures(student_id)  # This method gets enrolled cohorts
        
        return jsonify({
            'success': True,
            'cohorts': cohorts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/lectures', methods=['GET'])
@auth_middleware.student_required
def get_my_lectures():
    """Get lectures for enrolled cohorts"""
    try:
        student_id = session.get('user_id')
        institution_id = session.get('institution_id')
        
        # Get all lectures for the institution (student can see lectures for their enrolled cohorts)
        lectures = db.get_lectures_by_institution(institution_id)
        
        # Filter lectures for enrolled cohorts
        enrolled_cohorts = db.get_student_enrolled_lectures(student_id)
        enrolled_cohort_ids = [cohort['cohort_id'] for cohort in enrolled_cohorts]
        
        filtered_lectures = [lecture for lecture in lectures if lecture['cohort_id'] in enrolled_cohort_ids]
        
        return jsonify({
            'success': True,
            'lectures': filtered_lectures
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/materials', methods=['GET'])
@auth_middleware.student_required
def get_available_materials():
    """Get materials available to the student"""
    try:
        student_id = session.get('user_id')
        institution_id = session.get('institution_id')
        
        # Get enrolled cohorts
        enrolled_cohorts = db.get_student_enrolled_lectures(student_id)
        enrolled_cohort_ids = [cohort['cohort_id'] for cohort in enrolled_cohorts]
        
        # Get materials for enrolled cohorts
        materials = db.get_materials_by_cohorts(enrolled_cohort_ids)
        
        return jsonify({
            'success': True,
            'materials': materials
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/quizzes', methods=['GET'])
@auth_middleware.student_required
def get_available_quizzes():
    """Get quizzes available to the student"""
    try:
        student_id = session.get('user_id')
        institution_id = session.get('institution_id')
        
        # Get enrolled cohorts
        enrolled_cohorts = db.get_student_enrolled_lectures(student_id)
        enrolled_cohort_ids = [cohort['cohort_id'] for cohort in enrolled_cohorts]
        
        # Get quiz sets for enrolled cohorts
        quiz_sets = db.get_quiz_sets_by_cohorts(enrolled_cohort_ids)
        
        return jsonify({
            'success': True,
            'quiz_sets': quiz_sets
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/quiz-attempts', methods=['POST'])
@auth_middleware.student_required
def start_quiz_attempt():
    """Start a new quiz attempt"""
    try:
        student_id = session.get('user_id')
        
        data = request.get_json()
        quiz_set_id = data.get('quiz_set_id')
        
        if not quiz_set_id:
            return jsonify({'error': 'Quiz set ID is required'}), 400
        
        # Check if student is enrolled in the cohort for this quiz
        quiz_set = db.get_quiz_set_by_id(quiz_set_id)
        if not quiz_set:
            return jsonify({'error': 'Quiz set not found'}), 404
        
        # Check enrollment
        if not db.is_student_enrolled(student_id, quiz_set['cohort_id']):
            return jsonify({'error': 'You are not enrolled in this cohort'}), 403
        
        # Start quiz attempt
        attempt_id, message = db.start_quiz_attempt(student_id, quiz_set_id)
        if not attempt_id:
            return jsonify({'error': message}), 400
        
        # Get quiz questions
        questions = db.get_quiz_questions(quiz_set_id)
        
        return jsonify({
            'success': True,
            'attempt_id': attempt_id,
            'questions': questions,
            'time_limit': quiz_set.get('time_limit'),
            'max_attempts': quiz_set.get('max_attempts', 1)
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/quiz-responses', methods=['POST'])
@auth_middleware.student_required
def submit_quiz_response():
    """Submit a quiz response"""
    try:
        student_id = session.get('user_id')
        
        data = request.get_json()
        attempt_id = data.get('attempt_id')
        quiz_id = data.get('quiz_id')
        selected_answer = data.get('selected_answer')
        
        if not all([attempt_id, quiz_id, selected_answer is not None]):
            return jsonify({'error': 'Attempt ID, quiz ID, and answer are required'}), 400
        
        # Submit response
        response_id, message = db.submit_quiz_response(attempt_id, quiz_id, student_id, selected_answer)
        if not response_id:
            return jsonify({'error': message}), 400
        
        return jsonify({
            'success': True,
            'message': 'Response submitted successfully',
            'response_id': response_id
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/quiz-attempts/<attempt_id>/finish', methods=['POST'])
@auth_middleware.student_required
def finish_quiz_attempt(attempt_id):
    """Finish a quiz attempt"""
    try:
        student_id = session.get('user_id')
        
        # Finish attempt
        success, message = db.finish_quiz_attempt(attempt_id, student_id)
        if not success:
            return jsonify({'error': message}), 400
        
        # Get results
        attempt = db.get_quiz_attempt_by_id(attempt_id)
        
        return jsonify({
            'success': True,
            'message': 'Quiz completed successfully',
            'results': {
                'score': attempt.get('score'),
                'total_questions': attempt.get('total_questions'),
                'correct_answers': attempt.get('correct_answers'),
                'percentage': attempt.get('percentage')
            }
        }), 200
        
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
        
        # Update profile
        success = db.update_student(student_id, **data)
        if not success:
            return jsonify({'error': 'Failed to update profile'}), 400
        
        return jsonify({
            'success': True,
            'message': 'Profile updated successfully'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/logout', methods=['POST'])
def logout():
    """Student logout"""
    try:
        session.clear()
        return jsonify({
            'success': True,
            'message': 'Logged out successfully',
            'redirect_url': '/student/login'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

