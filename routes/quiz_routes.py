"""
Quiz Routes
Handles quiz creation, management, taking, and analytics.
"""

from flask import Blueprint, request, jsonify, session
from middlewares.auth_middleware import AuthMiddleware
from middlewares.cohort_middleware import CohortMiddleware
from services.quiz_service import QuizService
from utils.database_supabase import DatabaseManager
from utils.email_service import EmailService
import uuid

# Initialize blueprint
quiz_bp = Blueprint('quiz', __name__)

# Initialize services
db = DatabaseManager()
email_service = EmailService()
quiz_service = QuizService(db, email_service)

# Initialize middleware
auth_middleware = AuthMiddleware(None, db)
cohort_middleware = CohortMiddleware(None, db)

@quiz_bp.route('/api/quiz-sets', methods=['POST'])
@auth_middleware.api_teacher_required
def create_quiz_set():
    """Create a new quiz set"""
    try:
        data = request.get_json()
        
        if not all(key in data for key in ['title', 'description', 'cohort_id']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Verify teacher has access to this cohort
        if not cohort_middleware.validate_cohort_access(data['cohort_id']):
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        teacher_id = session.get('user_id')
        
        quiz_set_id, response = quiz_service.create_quiz_set(
            title=data['title'],
            description=data['description'],
            cohort_id=data['cohort_id'],
            teacher_id=teacher_id,
            time_limit=data.get('time_limit'),
            max_attempts=data.get('max_attempts', 1),
            starts_at=data.get('starts_at'),
            ends_at=data.get('ends_at')
        )
        
        if quiz_set_id:
            return jsonify({
                'success': True,
                'message': 'Quiz set created successfully',
                'quiz_set_id': quiz_set_id
            }), 201
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@quiz_bp.route('/api/quiz-sets/<quiz_set_id>/questions', methods=['POST'])
@auth_middleware.api_teacher_required
def add_quiz_question(quiz_set_id):
    """Add a question to a quiz set"""
    try:
        data = request.get_json()
        
        if not all(key in data for key in ['question', 'options', 'correct_answer']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Verify teacher owns this quiz set
        quiz_set = db.get_quiz_set_by_id(quiz_set_id)
        if not quiz_set or quiz_set['teacher_id'] != session['user_id']:
            return jsonify({'error': 'Unauthorized'}), 403
        
        question_id, response = quiz_service.add_quiz_question(
            quiz_set_id=quiz_set_id,
            question=data['question'],
            options=data['options'],
            correct_answer=data['correct_answer'],
            points=data.get('points', 1),
            question_order=data.get('question_order', 1)
        )
        
        if question_id:
            return jsonify({
                'success': True,
                'message': 'Question added successfully',
                'question_id': question_id
            }), 201
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@quiz_bp.route('/api/quiz-sets/<quiz_set_id>', methods=['GET'])
@auth_middleware.api_login_required
def get_quiz_set(quiz_set_id):
    """Get quiz set details"""
    try:
        quiz_set = quiz_service.get_quiz_set_by_id(quiz_set_id)
        
        if not quiz_set:
            return jsonify({'error': 'Quiz set not found'}), 404
        
        # Check if user has access to this quiz set
        user_type = session.get('user_type')
        user_id = session.get('user_id')
        
        if user_type == 'teacher':
            if quiz_set['teacher_id'] != user_id:
                return jsonify({'error': 'Access denied'}), 403
        elif user_type == 'student':
            # Check if student is in the cohort
            if not cohort_middleware.validate_cohort_access(quiz_set['cohort_id']):
                return jsonify({'error': 'Access denied'}), 403
        
        return jsonify({
            'success': True,
            'quiz_set': quiz_set
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@quiz_bp.route('/api/cohorts/<cohort_id>/quiz-sets', methods=['GET'])
@auth_middleware.api_login_required
def get_cohort_quiz_sets(cohort_id):
    """Get all quiz sets for a cohort"""
    try:
        # Verify user has access to this cohort
        if not cohort_middleware.validate_cohort_access(cohort_id):
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        quiz_sets = quiz_service.get_quiz_sets_for_cohort(cohort_id)
        
        return jsonify({
            'success': True,
            'quiz_sets': quiz_sets
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@quiz_bp.route('/api/quiz-sets/<quiz_set_id>/start', methods=['POST'])
@auth_middleware.api_student_required
def start_quiz_attempt(quiz_set_id):
    """Start a quiz attempt"""
    try:
        student_id = session.get('user_id')
        
        # Verify quiz set exists and student has access
        quiz_set = db.get_quiz_set_by_id(quiz_set_id)
        if not quiz_set:
            return jsonify({'error': 'Quiz set not found'}), 404
        
        if not cohort_middleware.validate_cohort_access(quiz_set['cohort_id']):
            return jsonify({'error': 'Access denied to this quiz'}), 403
        
        attempt_id, response = quiz_service.start_quiz_attempt(student_id, quiz_set_id)
        
        if attempt_id:
            return jsonify({
                'success': True,
                'message': 'Quiz attempt started',
                'attempt_id': attempt_id,
                'quiz_set': quiz_set
            }), 201
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@quiz_bp.route('/api/quiz-attempts/<attempt_id>/submit', methods=['POST'])
@auth_middleware.api_student_required
def submit_quiz_response(attempt_id):
    """Submit a quiz response"""
    try:
        data = request.get_json()
        
        if not all(key in data for key in ['question_id', 'response']):
            return jsonify({'error': 'Missing required fields'}), 400
        
        student_id = session.get('user_id')
        
        # Verify attempt belongs to student
        attempt = db.get_quiz_attempt_by_id(attempt_id)
        if not attempt or attempt['student_id'] != student_id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        success, response = quiz_service.submit_quiz_response(
            attempt_id=attempt_id,
            question_id=data['question_id'],
            student_id=student_id,
            response=data['response']
        )
        
        if success:
            return jsonify({'success': True, 'message': response}), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@quiz_bp.route('/api/quiz-attempts/<attempt_id>/complete', methods=['POST'])
@auth_middleware.api_student_required
def complete_quiz_attempt(attempt_id):
    """Complete a quiz attempt"""
    try:
        student_id = session.get('user_id')
        
        # Verify attempt belongs to student
        attempt = db.get_quiz_attempt_by_id(attempt_id)
        if not attempt or attempt['student_id'] != student_id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        success, response = quiz_service.complete_quiz_attempt(attempt_id)
        
        if success:
            return jsonify({'success': True, 'message': response}), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@quiz_bp.route('/api/quiz-attempts/<attempt_id>', methods=['GET'])
@auth_middleware.api_login_required
def get_quiz_attempt(attempt_id):
    """Get quiz attempt details"""
    try:
        attempt = db.get_quiz_attempt_by_id(attempt_id)
        
        if not attempt:
            return jsonify({'error': 'Quiz attempt not found'}), 404
        
        user_type = session.get('user_type')
        user_id = session.get('user_id')
        
        # Check access permissions
        if user_type == 'student':
            if attempt['student_id'] != user_id:
                return jsonify({'error': 'Access denied'}), 403
        elif user_type == 'teacher':
            quiz_set = db.get_quiz_set_by_id(attempt['quiz_set_id'])
            if not quiz_set or quiz_set['teacher_id'] != user_id:
                return jsonify({'error': 'Access denied'}), 403
        
        return jsonify({
            'success': True,
            'attempt': attempt
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@quiz_bp.route('/api/quiz-sets/<quiz_set_id>/analytics', methods=['GET'])
@auth_middleware.api_teacher_required
def get_quiz_analytics(quiz_set_id):
    """Get comprehensive quiz analytics"""
    try:
        # Verify teacher owns this quiz set
        quiz_set = db.get_quiz_set_by_id(quiz_set_id)
        if not quiz_set or quiz_set['teacher_id'] != session['user_id']:
            return jsonify({'error': 'Unauthorized'}), 403
        
        analytics = quiz_service.get_quiz_analytics(quiz_set_id)
        
        return jsonify({
            'success': True,
            'analytics': analytics
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@quiz_bp.route('/api/quiz-sets/<quiz_set_id>/question-analytics', methods=['GET'])
@auth_middleware.api_teacher_required
def get_question_analytics(quiz_set_id):
    """Get analytics for individual questions in a quiz set"""
    try:
        # Verify teacher owns this quiz set
        quiz_set = db.get_quiz_set_by_id(quiz_set_id)
        if not quiz_set or quiz_set['teacher_id'] != session['user_id']:
            return jsonify({'error': 'Unauthorized'}), 403
        
        analytics = quiz_service.get_question_analytics(quiz_set_id)
        
        return jsonify({
            'success': True,
            'analytics': analytics
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@quiz_bp.route('/api/quiz-sets/<quiz_set_id>/student-results', methods=['GET'])
@auth_middleware.api_teacher_required
def get_student_results(quiz_set_id):
    """Get all student results for a quiz set"""
    try:
        # Verify teacher owns this quiz set
        quiz_set = db.get_quiz_set_by_id(quiz_set_id)
        if not quiz_set or quiz_set['teacher_id'] != session['user_id']:
            return jsonify({'error': 'Unauthorized'}), 403
        
        results = quiz_service.get_student_results(quiz_set_id)
        
        return jsonify({
            'success': True,
            'results': results
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@quiz_bp.route('/api/students/<student_id>/quiz-history', methods=['GET'])
@auth_middleware.api_student_required
def get_student_quiz_history(student_id):
    """Get quiz history for a student"""
    try:
        # Verify student is accessing their own history
        if session['user_id'] != student_id:
            return jsonify({'error': 'Unauthorized'}), 403
        
        history = quiz_service.get_student_quiz_history(student_id)
        
        return jsonify({
            'success': True,
            'history': history
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@quiz_bp.route('/api/quiz-sets/<quiz_set_id>/attempts', methods=['GET'])
@auth_middleware.api_teacher_required
def get_quiz_attempts(quiz_set_id):
    """Get all attempts for a quiz set"""
    try:
        # Verify teacher owns this quiz set
        quiz_set = db.get_quiz_set_by_id(quiz_set_id)
        if not quiz_set or quiz_set['teacher_id'] != session['user_id']:
            return jsonify({'error': 'Unauthorized'}), 403
        
        attempts = quiz_service.get_quiz_attempts(quiz_set_id)
        
        return jsonify({
            'success': True,
            'attempts': attempts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@quiz_bp.route('/api/quiz-sets/<quiz_set_id>', methods=['PUT'])
@auth_middleware.api_teacher_required
def update_quiz_set(quiz_set_id):
    """Update quiz set details"""
    try:
        data = request.get_json()
        
        # Verify teacher owns this quiz set
        quiz_set = db.get_quiz_set_by_id(quiz_set_id)
        if not quiz_set or quiz_set['teacher_id'] != session['user_id']:
            return jsonify({'error': 'Unauthorized'}), 403
        
        success, response = quiz_service.update_quiz_set(
            quiz_set_id=quiz_set_id,
            title=data.get('title'),
            description=data.get('description'),
            time_limit=data.get('time_limit'),
            max_attempts=data.get('max_attempts'),
            starts_at=data.get('starts_at'),
            ends_at=data.get('ends_at'),
            is_active=data.get('is_active')
        )
        
        if success:
            return jsonify({'success': True, 'message': response}), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@quiz_bp.route('/api/quiz-sets/<quiz_set_id>', methods=['DELETE'])
@auth_middleware.api_teacher_required
def delete_quiz_set(quiz_set_id):
    """Delete a quiz set"""
    try:
        # Verify teacher owns this quiz set
        quiz_set = db.get_quiz_set_by_id(quiz_set_id)
        if not quiz_set or quiz_set['teacher_id'] != session['user_id']:
            return jsonify({'error': 'Unauthorized'}), 403
        
        success, response = quiz_service.delete_quiz_set(quiz_set_id)
        
        if success:
            return jsonify({'success': True, 'message': response}), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@quiz_bp.route('/api/quiz-sets/<quiz_set_id>/questions/<question_id>', methods=['PUT'])
@auth_middleware.api_teacher_required
def update_quiz_question(question_id):
    """Update a quiz question"""
    try:
        data = request.get_json()
        
        # Verify teacher owns this question's quiz set
        question = db.get_quiz_question_by_id(question_id)
        if not question:
            return jsonify({'error': 'Question not found'}), 404
        
        quiz_set = db.get_quiz_set_by_id(question['quiz_set_id'])
        if not quiz_set or quiz_set['teacher_id'] != session['user_id']:
            return jsonify({'error': 'Unauthorized'}), 403
        
        success, response = quiz_service.update_quiz_question(
            question_id=question_id,
            question=data.get('question'),
            options=data.get('options'),
            correct_answer=data.get('correct_answer'),
            points=data.get('points'),
            question_order=data.get('question_order')
        )
        
        if success:
            return jsonify({'success': True, 'message': response}), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@quiz_bp.route('/api/quiz-sets/<quiz_set_id>/questions/<question_id>', methods=['DELETE'])
@auth_middleware.api_teacher_required
def delete_quiz_question(question_id):
    """Delete a quiz question"""
    try:
        # Verify teacher owns this question's quiz set
        question = db.get_quiz_question_by_id(question_id)
        if not question:
            return jsonify({'error': 'Question not found'}), 404
        
        quiz_set = db.get_quiz_set_by_id(question['quiz_set_id'])
        if not quiz_set or quiz_set['teacher_id'] != session['user_id']:
            return jsonify({'error': 'Unauthorized'}), 403
        
        success, response = quiz_service.delete_quiz_question(question_id)
        
        if success:
            return jsonify({'success': True, 'message': response}), 200
        else:
            return jsonify({'error': response}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500