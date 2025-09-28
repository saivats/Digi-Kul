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
        
        # If no cohorts assigned, allow access to any cohort (fallback)
        if not cohort_ids:
            print(f"Teacher {teacher_id} has no assigned cohorts, allowing access to {data['cohort_id']}")
        elif data['cohort_id'] not in cohort_ids:
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        # Get institution_id from teacher data
        teacher = db.get_teacher_by_id(teacher_id)
        if not teacher:
            return jsonify({'error': 'Teacher not found'}), 404
        
        # Create lecture
        lecture_id, message = db.create_lecture(
            institution_id=teacher['institution_id'],
            cohort_id=data['cohort_id'],
            teacher_id=teacher_id,
            title=data['title'],
            description=data.get('description'),
            scheduled_time=data['scheduled_time'],
            duration=data.get('duration', 60),
            created_by=teacher_id
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
        
        # If no cohorts found, try to get all cohorts and let teacher select
        if not cohorts:
            print(f"No cohorts found for teacher {teacher_id}, getting all cohorts")
            all_cohorts = db.get_all_cohorts()
            return jsonify({
                'success': True,
                'cohorts': all_cohorts,
                'message': 'No specific cohorts assigned. Showing all available cohorts.'
            }), 200
        
        return jsonify({
            'success': True,
            'cohorts': cohorts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/cohorts/assign', methods=['POST'])
@teacher_required
def assign_to_cohort():
    """Assign teacher to a cohort"""
    try:
        teacher_id = session.get('user_id')
        data = request.get_json()
        
        if 'cohort_id' not in data:
            return jsonify({'error': 'Missing cohort_id'}), 400
        
        cohort_id = data['cohort_id']
        
        # Assign teacher to cohort
        success = db.assign_teacher_to_cohort(teacher_id, cohort_id)
        
        if success:
            return jsonify({
                'success': True,
                'message': 'Successfully assigned to cohort'
            }), 200
        else:
            return jsonify({'error': 'Failed to assign to cohort'}), 500
            
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
        # Handle both JSON and form data
        if request.is_json:
            data = request.get_json()
        else:
            data = request.form.to_dict()
        
        teacher_id = session.get('user_id')
        
        required_fields = ['title', 'cohort_id']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Verify teacher has access to this cohort
        teacher_cohorts = db.get_teacher_cohorts(teacher_id)
        cohort_ids = [c['id'] for c in teacher_cohorts]
        
        # If no cohorts assigned, allow access to any cohort (fallback)
        if not cohort_ids:
            print(f"Teacher {teacher_id} has no assigned cohorts, allowing access to {data['cohort_id']}")
        elif data['cohort_id'] not in cohort_ids:
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        # Get teacher's institution_id
        teacher = db.get_teacher_by_id(teacher_id)
        if not teacher:
            return jsonify({'error': 'Teacher not found'}), 404
        
        # Handle file data with defaults
        file_name = data.get('file_name', f"material_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
        file_path = data.get('file_path', f"/materials/{file_name}")
        
        # Create material
        material_id, message = db.create_material(
            institution_id=teacher['institution_id'],
            title=data['title'],
            description=data.get('description', ''),
            teacher_id=teacher_id,
            cohort_id=data['cohort_id'],
            file_name=file_name,
            file_path=file_path,
            file_size=data.get('file_size', 0),
            file_type=data.get('file_type', 'document')
        )
        
        if material_id:
            return jsonify({
                'success': True,
                'material_id': material_id,
                'message': message
            }), 201
        else:
            return jsonify({'error': message}), 500
            
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
        
        # Get additional profile data
        cohorts = db.get_teacher_cohorts(teacher_id)
        lectures = db.get_lectures_by_teacher(teacher_id)
        materials = db.get_teacher_materials(teacher_id)
        polls = db.get_teacher_polls(teacher_id)
        
        profile_data = {
            'id': teacher['id'],
            'name': teacher['name'],
            'email': teacher['email'],
            'institution_id': teacher['institution_id'],
            'created_at': teacher['created_at'],
            'last_login': teacher.get('last_login'),
            'is_active': teacher['is_active'],
            'stats': {
                'total_cohorts': len(cohorts),
                'total_lectures': len(lectures),
                'total_materials': len(materials),
                'total_polls': len(polls)
            },
            'recent_activity': {
                'cohorts': cohorts[:3],
                'lectures': lectures[:3],
                'materials': materials[:3]
            }
        }
        
        return jsonify({
            'success': True,
            'teacher': profile_data
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


@teacher_bp.route('/quizzes', methods=['GET'])
@teacher_required
def get_quizzes():
    """Get teacher's quizzes"""
    try:
        teacher_id = session.get('user_id')
        
        # Get teacher's cohorts
        cohorts = db.get_teacher_cohorts(teacher_id)
        cohort_ids = [c['id'] for c in cohorts]
        
        all_quizzes = []
        for cohort_id in cohort_ids:
            # Get quiz sets for this cohort
            quiz_sets = db.get_quiz_sets_by_cohorts([cohort_id])
            all_quizzes.extend(quiz_sets)
        
        return jsonify({
            'success': True,
            'quizzes': all_quizzes
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/quizzes', methods=['POST'])
@teacher_required
def create_quiz():
    """Create a new quiz"""
    try:
        teacher_id = session.get('user_id')
        data = request.get_json()
        
        required_fields = ['cohort_id', 'title', 'questions']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Verify teacher has access to this cohort
        cohorts = db.get_teacher_cohorts(teacher_id)
        cohort_ids = [cohort['id'] for cohort in cohorts]
        
        # If no cohorts assigned, allow access to any cohort (fallback)
        if not cohort_ids:
            print(f"Teacher {teacher_id} has no assigned cohorts, allowing access to {data['cohort_id']}")
        elif data['cohort_id'] not in cohort_ids:
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        print(f"Creating quiz for cohort {data['cohort_id']} by teacher {teacher_id}")
        quiz_id, message = db.create_quiz(
            teacher_id=teacher_id,
            cohort_id=data['cohort_id'],
            title=data['title'],
            description=data.get('description', ''),
            questions=data['questions'],
            is_active=True
        )
        print(f"Quiz creation result: {quiz_id}, message: {message}")
        
        if quiz_id:
            return jsonify({
                'success': True,
                'quiz_id': quiz_id,
                'message': message
            }), 201
        else:
            return jsonify({'error': message}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/analytics', methods=['GET'])
@teacher_required
def get_analytics():
    """Get teacher analytics"""
    try:
        teacher_id = session.get('user_id')
        
        # Get teacher's lectures, polls, and materials
        lectures = db.get_lectures_by_teacher(teacher_id)
        materials = db.get_teacher_materials(teacher_id)
        cohorts = db.get_teacher_cohorts(teacher_id)
        
        # Get polls from cohorts (same as individual load functions)
        polls = []
        for cohort in cohorts:
            cohort_polls = db.get_polls_by_cohort(cohort['id'])
            polls.extend(cohort_polls)
        
        # Get total students across all cohorts
        total_students = 0
        for cohort in cohorts:
            students = db.get_cohort_students(cohort['id'])
            total_students += len(students)
        
        analytics = {
            'total_lectures': len(lectures),
            'total_polls': len(polls),
            'total_materials': len(materials),
            'total_cohorts': len(cohorts),
            'total_students': total_students,
            'recent_lectures': lectures[:5],
            'recent_polls': polls[:5],
            'recent_materials': materials[:5]
        }
        
        return jsonify({
            'success': True,
            'analytics': analytics
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/discussions', methods=['GET'])
@teacher_required
def get_discussions():
    """Get discussions for teacher's cohorts"""
    try:
        teacher_id = session.get('user_id')
        cohorts = db.get_teacher_cohorts(teacher_id)
        
        discussions = []
        for cohort in cohorts:
            cohort_discussions = db.get_cohort_discussions(cohort['id'])
            discussions.extend(cohort_discussions)
        
        return jsonify({
            'success': True,
            'discussions': discussions
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/discussions', methods=['POST'])
@teacher_required
def create_discussion():
    """Create a new discussion"""
    try:
        data = request.get_json()
        teacher_id = session.get('user_id')
        
        required_fields = ['cohort_id', 'title', 'content']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Verify teacher has access to this cohort
        teacher_cohorts = db.get_teacher_cohorts(teacher_id)
        cohort_ids = [c['id'] for c in teacher_cohorts]
        
        # If no cohorts assigned, allow access to any cohort (fallback)
        if not cohort_ids:
            print(f"Teacher {teacher_id} has no assigned cohorts, allowing access to {data['cohort_id']}")
        elif data['cohort_id'] not in cohort_ids:
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        # Create discussion
        print(f"Creating discussion for cohort {data['cohort_id']} by teacher {teacher_id}")
        discussion_id, message = db.create_discussion(
            cohort_id=data['cohort_id'],
            teacher_id=teacher_id,
            title=data['title'],
            content=data['content'],
            is_pinned=data.get('is_pinned', False)
        )
        print(f"Discussion creation result: {discussion_id}, message: {message}")
        
        if discussion_id:
            return jsonify({
                'success': True,
                'discussion_id': discussion_id,
                'message': message
            }), 201
        else:
            return jsonify({'error': message}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/lectures/<lecture_id>/join', methods=['GET'])
@teacher_required
def join_lecture(lecture_id):
    """Join a live lecture session"""
    try:
        teacher_id = session.get('user_id')
        
        # Get lecture details
        lecture = db.get_lecture_by_id(lecture_id)
        if not lecture:
            return jsonify({'error': 'Lecture not found'}), 404
        
        # Verify teacher has access to this lecture
        if lecture['teacher_id'] != teacher_id:
            return jsonify({'error': 'Access denied to this lecture'}), 403
        
        # Render the live session template
        return render_template('teacher_live_session.html', lecture_id=lecture_id)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/lectures/<lecture_id>/polls', methods=['GET'])
@teacher_required
def get_lecture_polls(lecture_id):
    """Get polls for a specific lecture"""
    try:
        teacher_id = session.get('user_id')
        
        # Verify teacher has access to this lecture
        lecture = db.get_lecture_by_id(lecture_id)
        if not lecture:
            return jsonify({'error': 'Lecture not found'}), 404
        
        if lecture['teacher_id'] != teacher_id:
            return jsonify({'error': 'Access denied to this lecture'}), 403
        
        # Get polls for this lecture
        polls = db.get_lecture_polls(lecture_id)
        
        return jsonify({
            'success': True,
            'polls': polls
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/lectures/<lecture_id>/polls', methods=['POST'])
@teacher_required
def create_lecture_poll(lecture_id):
    """Create a poll for a specific lecture"""
    try:
        teacher_id = session.get('user_id')
        data = request.get_json()
        
        # Verify teacher has access to this lecture
        lecture = db.get_lecture_by_id(lecture_id)
        if not lecture:
            return jsonify({'error': 'Lecture not found'}), 404
        
        if lecture['teacher_id'] != teacher_id:
            return jsonify({'error': 'Access denied to this lecture'}), 403
        
        required_fields = ['question', 'options']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Create poll for this lecture
        poll_id = db.create_lecture_poll(
            lecture_id=lecture_id,
            teacher_id=teacher_id,
            question=data['question'],
            options=data['options'],
            is_active=True
        )
        
        if poll_id:
            return jsonify({
                'success': True,
                'poll_id': poll_id,
                'message': 'Poll created successfully'
            }), 201
        else:
            return jsonify({'error': 'Failed to create poll'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/lecture/<lecture_id>/materials', methods=['GET'])
@teacher_required
def get_lecture_materials(lecture_id):
    """Get materials for a specific lecture"""
    try:
        teacher_id = session.get('user_id')
        
        # Verify teacher has access to this lecture
        lecture = db.get_lecture_by_id(lecture_id)
        if not lecture:
            return jsonify({'error': 'Lecture not found'}), 404
        
        if lecture['teacher_id'] != teacher_id:
            return jsonify({'error': 'Access denied to this lecture'}), 403
        
        # Get materials for this lecture
        materials = db.get_lecture_materials(lecture_id)
        
        return jsonify({
            'success': True,
            'materials': materials
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/cohorts/<cohort_id>/details', methods=['GET'])
@teacher_required
def get_cohort_details(cohort_id):
    """Get detailed information about a cohort"""
    try:
        teacher_id = session.get('user_id')
        
        # Verify teacher has access to this cohort
        cohorts = db.get_teacher_cohorts(teacher_id)
        cohort_ids = [cohort['id'] for cohort in cohorts]
        
        # If no cohorts assigned, allow access to any cohort (fallback)
        if not cohort_ids:
            print(f"Teacher {teacher_id} has no assigned cohorts, allowing access to {cohort_id}")
        elif cohort_id not in cohort_ids:
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        # Get cohort details
        cohort = db.get_cohort_by_id(cohort_id)
        if not cohort:
            return jsonify({'error': 'Cohort not found'}), 404
        
        # Get students in this cohort
        students = db.get_cohort_students(cohort_id)
        
        # Get discussions in this cohort
        discussions = db.get_cohort_discussions(cohort_id)
        
        # Get lectures for this cohort
        lectures = db.get_lectures_by_cohort(cohort_id)
        
        return jsonify({
            'success': True,
            'cohort': cohort,
            'students': students,
            'discussions': discussions,
            'lectures': lectures
        }), 200
        
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

@teacher_bp.route('/polls', methods=['GET'])
@teacher_required
def get_polls():
    """Get polls for teacher's cohorts"""
    try:
        teacher_id = session.get('user_id')
        cohorts = db.get_teacher_cohorts(teacher_id)
        cohort_ids = [c['id'] for c in cohorts]
        
        all_polls = []
        for cohort_id in cohort_ids:
            polls = db.get_polls_by_cohort(cohort_id)
            all_polls.extend(polls)
        
        return jsonify(all_polls)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/polls', methods=['POST'])
@teacher_required
def create_poll():
    """Create a new poll"""
    try:
        teacher_id = session.get('user_id')
        data = request.get_json()
        
        required_fields = ['cohort_id', 'question', 'options']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Verify teacher has access to this cohort
        cohorts = db.get_teacher_cohorts(teacher_id)
        cohort_ids = [cohort['id'] for cohort in cohorts]
        
        if data['cohort_id'] not in cohort_ids:
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        # Get teacher's institution_id
        teacher = db.get_teacher_by_id(teacher_id)
        if not teacher:
            return jsonify({'error': 'Teacher not found'}), 404
        
        poll_id, message = db.create_poll(
            institution_id=teacher['institution_id'],
            cohort_id=data['cohort_id'],
            teacher_id=teacher_id,
            question=data['question'],
            options=data['options'],
            lecture_id=data.get('lecture_id'),
            expires_at=data.get('expires_at')
        )
        
        if poll_id:
            return jsonify({
                'success': True,
                'poll_id': poll_id,
                'message': message
            }), 201
        else:
            return jsonify({'error': message}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/polls/<poll_id>/results', methods=['GET'])
@teacher_required
def get_poll_results(poll_id):
    """Get poll results"""
    try:
        results = db.get_poll_results(poll_id)
        return jsonify(results)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/quiz-responses/<quiz_set_id>', methods=['GET'])
@teacher_required
def get_quiz_responses(quiz_set_id):
    """Get quiz responses for a quiz set"""
    try:
        teacher_id = session.get('user_id')
        
        # Verify teacher has access to this quiz
        quiz_set = db.get_quiz_set_by_id(quiz_set_id)
        if not quiz_set:
            return jsonify({'error': 'Quiz not found'}), 404
        
        # Check if teacher owns this quiz
        if quiz_set.get('teacher_id') != teacher_id:
            return jsonify({'error': 'Access denied'}), 403
        
        responses = db.get_quiz_responses_by_quiz_set(quiz_set_id)
        attempts = db.get_quiz_attempts_by_quiz_set(quiz_set_id)
        
        return jsonify({
            'responses': responses,
            'attempts': attempts
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/discussions/<forum_id>/posts', methods=['POST'])
@teacher_required
def create_discussion_post(forum_id):
    """Create a discussion post"""
    try:
        teacher_id = session.get('user_id')
        data = request.get_json()
        
        required_fields = ['content']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Get teacher's institution_id
        teacher = db.get_teacher_by_id(teacher_id)
        if not teacher:
            return jsonify({'error': 'Teacher not found'}), 404
        
        post_id, message = db.create_discussion_post(
            institution_id=teacher['institution_id'],
            forum_id=forum_id,
            author_id=teacher_id,
            author_type='teacher',
            content=data['content'],
            title=data.get('title'),
            parent_post_id=data.get('parent_post_id')
        )
        
        if post_id:
            return jsonify({
                'success': True,
                'post_id': post_id,
                'message': message
            }), 201
        else:
            return jsonify({'error': message}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/discussions/<forum_id>/posts', methods=['GET'])
@teacher_required
def get_discussion_posts(forum_id):
    """Get discussion posts for a forum"""
    try:
        posts = db.get_discussion_posts(forum_id)
        return jsonify(posts)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500