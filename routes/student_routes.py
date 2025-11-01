"""
Student Routes
Handles student-specific functionality including enrollment, materials, quizzes, and profile management.
"""

from flask import Blueprint, request, jsonify, session, redirect, url_for, render_template, send_file
from werkzeug.security import check_password_hash, generate_password_hash
from datetime import datetime, timedelta, timezone
import os
from utils.database_supabase import SupabaseDatabaseManager as DatabaseManager
from middlewares.auth_middleware import AuthMiddleware
from utils.email_service import EmailService

# Try to import OpenAI (optional)
try:
    import openai
    OPENAI_AVAILABLE = True
except ImportError:
    OPENAI_AVAILABLE = False

# Initialize blueprint
student_bp = Blueprint('student', __name__)

# Initialize services
db = DatabaseManager()
email_service = EmailService()

# Global variable to store auth_middleware reference
auth_middleware = None

def set_auth_middleware(middleware):
    """Set the auth middleware reference from main.py"""
    global auth_middleware
    auth_middleware = middleware

def student_required(f):
    """Decorator to require student role - gets middleware at runtime"""
    from functools import wraps
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if auth_middleware is None:
            from flask import jsonify
            return jsonify({'error': 'Authentication service not available'}), 500
        return auth_middleware.student_required(f)(*args, **kwargs)
    return decorated_function

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


@student_bp.route('/debug/storage/recordings/<lecture_id>', methods=['GET'])
@student_required
def debug_list_recordings_student(lecture_id):
    """List files under recordings/lecture_<lecture_id> in Supabase Storage (student view)"""
    try:
        storage = getattr(db, 'storage', None)
        if not storage:
            from config import Config
            from utils.storage_supabase import SupabaseStorageManager
            storage = SupabaseStorageManager(Config.SUPABASE_URL, Config.SUPABASE_KEY)

        folder = f"lecture_{lecture_id}"
        print(f"Listing files in bucket 'recordings' folder '{folder}'")
        files = storage.list_files('recordings', folder)
        return jsonify({'success': True, 'folder': folder, 'files': files}), 200
    except Exception as e:
        print(f"Error listing recordings: {e}")
        return jsonify({'error': str(e)}), 500


@student_bp.route('/debug/storage/recordings/<lecture_id>/info', methods=['GET'])
@student_required
def debug_recording_info_student(lecture_id):
    """Get info for files under recordings/lecture_<lecture_id> (returns info for each file) - student view"""
    try:
        storage = getattr(db, 'storage', None)
        if not storage:
            from config import Config
            from utils.storage_supabase import SupabaseStorageManager
            storage = SupabaseStorageManager(Config.SUPABASE_URL, Config.SUPABASE_KEY)

        folder = f"lecture_{lecture_id}"
        files = storage.list_files('recordings', folder)
        info_list = []
        for f in files or []:
            path = f.get('name') if isinstance(f, dict) and 'name' in f else f
            try:
                info = storage.get_file_info('recordings', f"{folder}/{path}")
            except Exception as e:
                info = {'error': str(e)}
            info_list.append({'path': path, 'info': info})

        return jsonify({'success': True, 'info': info_list}), 200
    except Exception as e:
        print(f"Error getting recording info: {e}")
        return jsonify({'error': str(e)}), 500


@student_bp.route('/dashboard')
@student_required
def dashboard():
    """Student dashboard"""
    return render_template('student_dashboard.html')

@student_bp.route('/enroll', methods=['POST'])
@student_required
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
@student_required
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
@student_required
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
@student_required
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

@student_bp.route('/lecture/<lecture_id>/materials', methods=['GET'])
@student_required
def get_lecture_materials(lecture_id):
    """Get materials for a specific lecture"""
    try:
        student_id = session.get('user_id')
        
        # Verify student has access to this lecture
        lecture = db.get_lecture_by_id(lecture_id)
        if not lecture:
            return jsonify({'error': 'Lecture not found'}), 404
        
        # Check if student is enrolled in the cohort
        student_cohorts = db.get_student_cohorts(student_id)
        cohort_ids = [c['id'] for c in student_cohorts]
        
        if lecture['cohort_id'] not in cohort_ids:
            return jsonify({'error': 'Access denied to this lecture'}), 403
        
        # Get materials for this lecture
        materials = db.get_lecture_materials(lecture_id)
        
        return jsonify({
            'success': True,
            'materials': materials
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/recordings', methods=['GET'])
@student_required
def get_recordings():
    """Get recorded lectures for student's cohorts"""
    try:
        student_id = session.get('user_id')
        
        # Get student's cohorts
        cohorts = db.get_student_cohorts(student_id)
        cohort_ids = [c['id'] for c in cohorts]
        
        if not cohort_ids:
            return jsonify({
                'success': True,
                'recordings': []
            }), 200
        
        # Get recordings for these cohorts
        recordings = []
        for cohort_id in cohort_ids:
            # Get lectures for this cohort
            lectures = db.get_lectures_by_cohort(cohort_id)
            for lecture in lectures:
                # Get recordings for this lecture
                lecture_recordings = db.get_lecture_recordings(lecture['id'])
                recordings.extend(lecture_recordings)
        
        return jsonify({
            'success': True,
            'recordings': recordings
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/recordings/<recording_id>/debug', methods=['GET'])
@student_required
def debug_recording(recording_id):
    """Debug recording data"""
    try:
        recording = db.get_recording_by_id(recording_id)
        if not recording:
            return jsonify({'error': 'Recording not found'}), 404
        # Also include lecture info and student's enrolled cohorts for debugging
        lecture = None
        try:
            lecture = db.get_lecture_by_id(recording.get('lecture_id'))
        except Exception:
            lecture = None

        student_id = session.get('user_id')
        student_cohorts = []
        try:
            student_cohorts = db.get_student_cohorts(student_id)
        except Exception:
            student_cohorts = []

        return jsonify({
            'recording_id': recording_id,
            'recording_data': recording,
            'recording_path': recording.get('recording_path'),
            'lecture_id': recording.get('lecture_id'),
            'lecture': lecture,
            'student_cohorts': student_cohorts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/recordings/<recording_id>/download', methods=['GET'])
@student_required
def download_recording(recording_id):
    """Download a recorded lecture"""
    try:
        student_id = session.get('user_id')
        
        # Get recording details
        recording = db.get_recording_by_id(recording_id)
        if not recording:
            return jsonify({'error': 'Recording not found'}), 404
        
        # Check if student has access to this recording
        lecture = db.get_lecture_by_id(recording['lecture_id'])
        if not lecture:
            return jsonify({'error': 'Lecture not found'}), 404
        
        # Check if student is enrolled in the cohort
        student_cohorts = db.get_student_cohorts(student_id)
        cohort_ids = [c['id'] for c in student_cohorts]
        
        if lecture['cohort_id'] not in cohort_ids:
            # Log useful debug info for quick triage
            print(f"Access denied: student_id={student_id}, lecture_cohort={lecture.get('cohort_id')}, student_cohort_ids={cohort_ids}")
            return jsonify({'error': 'Access denied to this recording', 'lecture_cohort': lecture.get('cohort_id'), 'student_cohorts': cohort_ids}), 403
        
        # Handle recording file path
        recording_path = recording.get('recording_path')
        if not recording_path:
            return jsonify({'error': 'Recording file path not found'}), 404
        
        # Increment download count
        db.increment_recording_download_count(recording_id)
        
        # Handle recording file path
        print(f"Recording path from database: {recording_path}")
        
        if recording_path.startswith('http'):
            # It's already a full URL (public or private). Prefer generating a signed URL
            # using Supabase storage (in case the bucket is private) before redirecting.
            try:
                from config import Config
                from utils.storage_supabase import SupabaseStorageManager

                storage = getattr(db, 'storage', None)
                if not storage:
                    storage = SupabaseStorageManager(Config.SUPABASE_URL, Config.SUPABASE_KEY)

                marker = '/storage/v1/object/public/'
                if marker in recording_path:
                    suffix = recording_path.split(marker, 1)[1]
                    parts = suffix.split('/', 1)
                    bucket = parts[0] if parts else 'recordings'
                    object_path = parts[1] if len(parts) > 1 else ''

                    if object_path:
                        print(f"Attempting to get signed URL for bucket='{bucket}', path='{object_path}'")
                        signed_url = storage.get_signed_url(bucket, object_path)
                        if signed_url:
                            print(f"Successfully got signed URL: {signed_url}")
                            return redirect(signed_url)
                        else:
                            print(f"Signed URL not available for {object_path}, falling back to public URL")
                        # Try listing the folder to find an object that matches the base name
                        try:
                            folder = object_path.split('/', 1)[0] if '/' in object_path else object_path
                            base_name = os.path.basename(object_path)
                            print(f"Listing files in bucket '{bucket}' folder '{folder}' to find candidate for base '{base_name}'")
                            files = storage.list_files(bucket, folder)
                            print(f"Found {len(files) if files else 0} files in folder: {files}")
                            for f in files or []:
                                # Get name relative to folder
                                candidate = f.get('name', '')
                                if not candidate:
                                    continue
                                print(f"Checking candidate in folder '{folder}': {candidate}")
                                # Compare the base name since list returns relative paths
                                candidate_base = os.path.basename(candidate)
                                if candidate_base == base_name or candidate_base.startswith(base_name):
                                    # Reconstruct full path relative to bucket
                                    candidate_path = f"{folder}/{candidate}"
                                    print(f"Found matching file, trying signed URL for: {candidate_path}")
                                    signed_url = storage.get_signed_url(bucket, candidate_path)
                                    if signed_url:
                                        print(f"Successfully got signed URL for match: {signed_url}")
                                        db.increment_recording_download_count(recording_id)
                                        return redirect(signed_url)
                                    # Reconstruct full path relative to bucket
                                    candidate_path = f"{folder}/{candidate}"
                                    print(f"Found matching file, trying signed URL for: {candidate_path}")
                                    signed_url = storage.get_signed_url(bucket, candidate_path)
                                    if signed_url:
                                        print(f"Successfully got signed URL for match: {signed_url}")
                                        db.increment_recording_download_count(recording_id)
                                        return redirect(signed_url)
                                if candidate == base_name or candidate.startswith(base_name):
                                    candidate_path = f"{folder}/{candidate}"
                                    print(f"Found candidate object: {candidate_path}, attempting signed URL")
                                    candidate_signed = storage.get_signed_url(bucket, candidate_path)
                                    if candidate_signed:
                                        print(f"Successfully got signed URL for candidate: {candidate_signed}")
                                        return redirect(candidate_signed)
                        except Exception as e:
                            print(f"Error while listing bucket '{bucket}' folder '{folder}': {e}")

                # Not a Supabase storage URL or signed URL unavailable — redirect to the stored URL
                print(f"Recording is already a URL, redirecting to: {recording_path}")
                return redirect(recording_path)
            except Exception as e:
                print(f"Error trying to generate signed URL from public URL: {e}")
                return redirect(recording_path)

        else:
            # Try to get a signed URL from Supabase Storage for local/object paths
            try:
                storage = getattr(db, 'storage', None)
                if not storage:
                    from config import Config
                    from utils.storage_supabase import SupabaseStorageManager
                    storage = SupabaseStorageManager(Config.SUPABASE_URL, Config.SUPABASE_KEY)

                relative_path = recording_path
                if not recording_path.startswith('lecture_'):
                    lecture_id = recording.get('lecture_id', '')
                    if lecture_id:
                        relative_path = f"lecture_{lecture_id}/{recording_path}"

                print(f"Attempting to get signed URL for path: {relative_path}")
                signed_url = storage.get_signed_url('recordings', relative_path)
                if not signed_url:
                    for ext in ('.webm', '.mp4', '.mkv'):
                        try_path = f"{relative_path}{ext}"
                        print(f"Trying path with extension: {try_path}")
                        signed_url = storage.get_signed_url('recordings', try_path)
                        if signed_url:
                            relative_path = try_path
                            break

                if signed_url:
                    print(f"Successfully got signed URL: {signed_url}")
                    return redirect(signed_url)
                else:
                    print(f"Failed to get signed URL for path: {relative_path}")
            except Exception as e:
                print(f"Error getting signed URL for recording: {e}")

            # Fallback to local file handling (legacy support)
            possible_paths = [
                recording_path,
                os.path.join('uploads', recording_path),
                os.path.join('uploads', 'videos', os.path.basename(recording_path)),
                os.path.join('recordings', 'videos', os.path.basename(recording_path)),
                os.path.join('uploads', 'recordings', os.path.basename(recording_path))
            ]
            
            found_path = None
            for path in possible_paths:
                if os.path.exists(path):
                    found_path = path
                    break
            
            if not found_path:
                return jsonify({'error': f'Recording file not found. Tried paths: {possible_paths}'}), 404
            
            # Return file for download
            return send_file(
                found_path,
                as_attachment=True,
                download_name=f"lecture_recording_{recording_id}.webm"
            )
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/quizzes', methods=['GET'])
@student_required
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
@student_required
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

@student_bp.route('/discussion/<forum_id>')
@student_required
def discussion_forum_page(forum_id):
    """Discussion forum page"""
    try:
        student_id = session.get('user_id')
        
        # Verify student has access to this forum
        forum = db.supabase.table('discussion_forums').select('*').eq('id', forum_id).execute()
        if not forum.data:
            return render_template('error.html', 
                                 error="Discussion forum not found", 
                                 message="The requested discussion forum could not be found"), 404
        
        forum_data = forum.data[0]
        
        # Check if student is enrolled in the cohort
        student_cohorts = db.get_student_cohorts(student_id)
        cohort_ids = [c['id'] for c in student_cohorts]
        
        if forum_data['cohort_id'] not in cohort_ids:
            return render_template('error.html', 
                                 error="Access denied", 
                                 message="You don't have access to this discussion forum"), 403
        
        # Use the real-time chatroom template instead
        return render_template('realtime_chatroom.html', 
                             forum_id=forum_id, 
                             forum=forum_data,
                             session=session)
        
    except Exception as e:
        return render_template('error.html', 
                             error="Error loading discussion forum", 
                             message=str(e)), 500

@student_bp.route('/discussions/<forum_id>/messages', methods=['GET'])
@student_required
def get_forum_messages(forum_id):
    """Get messages for a discussion forum"""
    try:
        student_id = session.get('user_id')
        
        # Verify student has access to this forum
        forum = db.supabase.table('discussion_forums').select('*').eq('id', forum_id).execute()
        if not forum.data:
            return jsonify({'error': 'Forum not found'}), 404
        
        forum_data = forum.data[0]
        
        # Check if student is enrolled in the cohort
        student_cohorts = db.get_student_cohorts(student_id)
        cohort_ids = [c['id'] for c in student_cohorts]
        
        if forum_data['cohort_id'] not in cohort_ids:
            return jsonify({'error': 'Access denied'}), 403

        # Get recent messages (last 50) via ChatService to merge legacy and new messages
        from services.chat_service import ChatService
        chat_service = ChatService()
        messages = chat_service.get_forum_messages(forum_id, limit=50)

        return jsonify({
            'success': True,
            'messages': messages
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/quiz-attempt/<quiz_set_id>')
@student_required
def quiz_attempt_page(quiz_set_id):
    """Quiz attempt page"""
    try:
        student_id = session.get('user_id')
        
        # Verify student has access to this quiz
        quiz_set = db.get_quiz_set_by_id(quiz_set_id)
        if not quiz_set:
            return render_template('error.html', 
                                 error="Quiz not found", 
                                 message="The requested quiz could not be found"), 404
        
        # Check if student is enrolled in the cohort
        student_cohorts = db.get_student_cohorts(student_id)
        cohort_ids = [c['id'] for c in student_cohorts]
        
        if quiz_set['cohort_id'] not in cohort_ids:
            return render_template('error.html', 
                                 error="Access denied", 
                                 message="You don't have access to this quiz"), 403
        
        return render_template('quiz_attempt.html', quiz_set_id=quiz_set_id)
        
    except Exception as e:
        return render_template('error.html', 
                             error="Error loading quiz", 
                             message=str(e)), 500

@student_bp.route('/quiz-attempts/<attempt_id>/questions', methods=['GET'])
@student_required
def get_quiz_questions(attempt_id):
    """Get quiz questions for an attempt"""
    try:
        student_id = session.get('user_id')
        
        # Verify student has access to this attempt
        attempt = db.get_quiz_attempt_by_id(attempt_id)
        if not attempt:
            return jsonify({'error': 'Quiz attempt not found'}), 404
        
        if attempt['student_id'] != student_id:
            return jsonify({'error': 'Access denied'}), 403
        
        # Get quiz questions
        questions = db.get_quiz_questions(attempt['quiz_set_id'])
        quiz_set = db.get_quiz_set_by_id(attempt['quiz_set_id'])
        
        return jsonify({
            'success': True,
            'questions': questions,
            'title': quiz_set.get('title', 'Quiz'),
            'description': quiz_set.get('description', ''),
            'time_limit': quiz_set.get('time_limit')
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/quiz-responses', methods=['POST'])
@student_required
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
        response_id, message = db.submit_quiz_response(
            attempt_id=attempt_id,
            quiz_id=question_id,
            student_id=student_id,
            selected_answer=response
        )
        
        if response_id:
            return jsonify({
                'success': True,
                'message': 'Response submitted successfully'
            }), 200
        else:
            return jsonify({'error': message}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/quiz-attempts/<attempt_id>/finish', methods=['POST'])
@student_required
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
@student_required
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
@student_required
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
@student_required
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

# ========================================
# ADDITIONAL STUDENT ROUTES
# ========================================

@student_bp.route('/stats', methods=['GET'])
@student_required
def get_stats():
    """Get student statistics"""
    try:
        student_id = session.get('user_id')
        
        # Get basic stats
        cohorts = db.get_student_cohorts(student_id)
        lectures = []
        materials = []
        quiz_sets = []
        
        for cohort in cohorts:
            # Get lectures for this cohort
            cohort_lectures = db.get_lectures_by_cohort(cohort['id'])
            lectures.extend(cohort_lectures)
            
            # Get materials for this cohort
            cohort_materials = db.get_materials_by_cohort(cohort['id'])
            materials.extend(cohort_materials)
            
            # Get quiz sets for this cohort
            cohort_quiz_sets = db.get_quiz_sets_by_cohorts([cohort['id']])
            quiz_sets.extend(cohort_quiz_sets)
        
        # Get upcoming lectures (next 7 days)
        from datetime import datetime, timedelta, timezone, timezone
        now = datetime.now(timezone.utc)
        week_from_now = now + timedelta(days=7)
        
        upcoming_lectures = [
            lecture for lecture in lectures 
            if lecture.get('scheduled_time') and 
            now <= db.parse_datetime(lecture['scheduled_time']) <= week_from_now
        ]
        
        stats = {
            'enrolled_cohorts': len(cohorts),
            'total_lectures': len(lectures),
            'upcoming_lectures': len(upcoming_lectures),
            'available_materials': len(materials),
            'available_quizzes': len(quiz_sets)
        }
        
        return jsonify({
            'success': True,
            'stats': stats
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/materials/<material_id>/download', methods=['GET'])
@student_required
def download_material(material_id):
    """Download a material file"""
    try:
        student_id = session.get('user_id')
        
        # Get material details
        material = db.get_material_by_id(material_id)
        if not material:
            return jsonify({'error': 'Material not found'}), 404
        
        # Check if student has access to this material
        student_cohorts = db.get_student_cohorts(student_id)
        cohort_ids = [c['id'] for c in student_cohorts]
        
        # Check if material belongs to student's cohort
        if material.get('cohort_id') not in cohort_ids:
            return jsonify({'error': 'Access denied to this material'}), 403
        
        # Get download URL
        download_url, message = db.get_material_download_url(material_id)
        if not download_url:
            return jsonify({'error': f'Failed to get download URL: {message}'}), 404
        
        # Increment download count
        db.increment_material_download_count(material_id)
        
        # If it's a Supabase Storage URL, redirect to it
        if download_url.startswith('http'):
            return redirect(download_url)
        else:
            # Handle different path formats
            file_path = download_url
            if not file_path.startswith('/'):
                file_path = os.path.join('uploads', file_path)
            
            # Try different possible paths
            possible_paths = [
                file_path,
                os.path.join('uploads', 'materials', os.path.basename(file_path)),
                os.path.join('uploads', 'documents', os.path.basename(file_path)),
                os.path.join('materials', os.path.basename(file_path)),
                os.path.join('documents', os.path.basename(file_path))
            ]
            
            found_path = None
            for path in possible_paths:
                if os.path.exists(path):
                    found_path = path
                    break
            
            if not found_path:
                return jsonify({'error': f'Material file not found. Tried paths: {possible_paths}'}), 404
            
            return send_file(
                found_path,
                as_attachment=True,
                download_name=material.get('file_name', 'material')
            )
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/polls', methods=['GET'])
@student_required
def get_polls():
    """Get polls for student's cohorts"""
    try:
        student_id = session.get('user_id')
        
        # Get student's cohorts
        cohorts = db.get_student_cohorts(student_id)
        cohort_ids = [c['id'] for c in cohorts]
        
        if not cohort_ids:
            return jsonify({
                'success': True,
                'polls': []
            }), 200
        
        # Get polls for these cohorts
        polls = []
        for cohort_id in cohort_ids:
            cohort_polls = db.get_polls_by_cohort(cohort_id)
            polls.extend(cohort_polls)
        
        # Filter out polls that student has already responded to
        filtered_polls = []
        for poll in polls:
            # Check if student has already responded
            existing_response = db.supabase.table('poll_responses').select('*').eq('poll_id', poll['id']).eq('student_id', student_id).execute()
            if not existing_response.data:
                filtered_polls.append(poll)
        
        polls = filtered_polls
        
        return jsonify({
            'success': True,
            'polls': polls
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/polls/<poll_id>/vote', methods=['POST'])
@student_required
def vote_poll(poll_id):
    """Vote on a poll"""
    try:
        student_id = session.get('user_id')
        data = request.get_json()
        selected_option = data.get('selected_option')
        
        if not selected_option:
            return jsonify({'error': 'Selected option is required'}), 400
        
        # Submit poll response
        response_id, message = db.submit_poll_response(
            student_id=student_id,
            poll_id=poll_id,
            response=selected_option
        )
        
        if response_id:
            return jsonify({
                'success': True,
                'message': 'Vote submitted successfully'
            }), 200
        else:
            return jsonify({'error': message}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/polls/<poll_id>/results', methods=['GET'])
@student_required
def get_poll_results(poll_id):
    """Get poll results"""
    try:
        student_id = session.get('user_id')
        
        # Get poll results
        results = db.get_poll_results(poll_id)
        
        if not results:
            return jsonify({'error': 'Poll not found'}), 404
        
        return jsonify({
            'success': True,
            'results': results
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/discussions', methods=['GET'])
@student_required
def get_discussions():
    """Get discussions for student's cohorts"""
    try:
        student_id = session.get('user_id')
        
        # Get student's cohorts
        cohorts = db.get_student_cohorts(student_id)
        cohort_ids = [c['id'] for c in cohorts]
        
        if not cohort_ids:
            return jsonify({
                'success': True,
                'discussions': []
            }), 200
        
        # Get discussions for these cohorts
        discussions = []
        for cohort_id in cohort_ids:
            try:
                cohort_discussions = db.get_cohort_discussions(cohort_id)
                if cohort_discussions:
                    discussions.extend(cohort_discussions)
            except Exception as e:
                print(f"Error getting discussions for cohort {cohort_id}: {e}")
                continue
        
        return jsonify({
            'success': True,
            'discussions': discussions
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/discussions/<forum_id>/posts', methods=['GET'])
@student_required
def get_discussion_posts(forum_id):
    """Get posts for a discussion forum"""
    try:
        student_id = session.get('user_id')
        
        # Get discussion posts
        posts = db.get_discussion_posts(forum_id)
        
        return jsonify({
            'success': True,
            'posts': posts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/discussions/<forum_id>/posts', methods=['POST'])
@student_required
def create_discussion_post(forum_id):
    """Create a new discussion post"""
    try:
        student_id = session.get('user_id')
        data = request.get_json()
        
        content = data.get('content')
        title = data.get('title')
        
        if not content:
            return jsonify({'error': 'Content is required'}), 400
        
        # Create discussion post
        post_id, message = db.add_discussion_post(
            forum_id=forum_id,
            author_id=student_id,
            author_type='student',
            content=content,
            title=title
        )
        
        if post_id:
            return jsonify({
                'success': True,
                'post_id': post_id,
                'message': 'Post created successfully'
            }), 201
        else:
            return jsonify({'error': message}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/grades', methods=['GET'])
@student_required
def get_grades():
    """Get student grades"""
    try:
        student_id = session.get('user_id')
        cohort_id = request.args.get('cohort_id')
        
        # Get student grades
        try:
            grades = db.get_student_grades(student_id, cohort_id)
            if not grades:
                # Try to get grades without cohort filter
                grades = db.get_student_grades(student_id)
        except Exception as e:
            print(f"Error getting grades: {e}")
            grades = []
        
        return jsonify({
            'success': True,
            'grades': grades
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/grades/summary', methods=['GET'])
@student_required
def get_grade_summary():
    """Get student grade summary"""
    try:
        student_id = session.get('user_id')
        cohort_id = request.args.get('cohort_id')
        
        # Get grade summary
        summary = db.get_student_grade_summary(student_id, cohort_id)
        
        return jsonify({
            'success': True,
            'summary': summary
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/live-session/<lecture_id>', methods=['GET'])
@student_required
def join_live_session(lecture_id):
    """Join a live session"""
    try:
        student_id = session.get('user_id')
        
        # Verify student has access to this lecture
        lecture = db.get_lecture_by_id(lecture_id)
        if not lecture:
            return jsonify({'error': 'Lecture not found'}), 404
        
        # Check if student is enrolled in the cohort
        student_cohorts = db.get_student_cohorts(student_id)
        cohort_ids = [c['id'] for c in student_cohorts]
        
        if lecture['cohort_id'] not in cohort_ids:
            return jsonify({'error': 'Access denied to this lecture'}), 403
        
        # Allow students to join real-time - no status check needed
        # Teacher controls the session and students can join anytime
        
        # Return live session page
        return render_template('student_live_session.html', 
                             lecture_id=lecture_id,
                             session_id=f"session_{lecture_id}")
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/notifications', methods=['GET'])
@student_required
def get_notifications():
    """Get student notifications"""
    try:
        student_id = session.get('user_id')
        
        # Get notifications
        notifications = db.get_user_notifications(student_id)
        
        return jsonify({
            'success': True,
            'notifications': notifications
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/notifications/<notification_id>/read', methods=['POST'])
@student_required
def mark_notification_read(notification_id):
    """Mark notification as read"""
    try:
        student_id = session.get('user_id')
        
        # Mark notification as read
        # This would need to be implemented in the database manager
        # For now, return success
        return jsonify({
            'success': True,
            'message': 'Notification marked as read'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@student_bp.route('/chatbot/ask', methods=['POST'])
@student_required
def ask_chatbot():
    """Ask the AI chatbot a question"""
    try:
        data = request.get_json()
        message = data.get('message')
        user_id = session.get('user_id')
        user_name = session.get('user_name', 'Student')
        
        if not message:
            return jsonify({'error': 'Message is required'}), 400
        
        # Check if OpenAI API key is configured
        openai_api_key = os.getenv('OPENAI_API_KEY')
        if not openai_api_key:
            return jsonify({
                'success': False,
                'error': 'AI service not configured. Please contact administrator.'
            }), 503
        
        # Check if OpenAI is available
        if not OPENAI_AVAILABLE:
            return jsonify({
                'success': False,
                'error': 'OpenAI library not installed. Please contact administrator.'
            }), 503
        
        # Use OpenAI
        try:
            openai.api_key = openai_api_key
            
            # Create a context-aware prompt
            prompt = f"""You are Asha, an AI learning assistant for students. You are helping {user_name} with their studies.

Student's question: {message}

Please provide a helpful, educational response that:
1. Directly addresses their question
2. Provides practical study advice
3. Encourages learning
4. Is friendly and supportive
5. Keeps responses concise but informative

Response:"""
            
            # Call OpenAI API
            response = openai.ChatCompletion.create(
                model="gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "You are Asha, a helpful AI learning assistant for students. Provide educational, supportive, and practical advice."},
                    {"role": "user", "content": message}
                ],
                max_tokens=500,
                temperature=0.7
            )
            
            ai_response = response.choices[0].message.content.strip()
            
            return jsonify({
                'success': True,
                'response': ai_response
            }), 200
            
        except Exception as e:
            return jsonify({
                'success': False,
                'error': f'AI service error: {str(e)}'
            }), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500