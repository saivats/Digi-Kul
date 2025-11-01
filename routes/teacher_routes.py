"""
Teacher Routes
Handles teacher-specific functionality including lecture management, materials, and student interaction.
"""

from flask import Blueprint, request, jsonify, session, redirect, url_for, render_template, send_file
from werkzeug.security import check_password_hash, generate_password_hash
from datetime import datetime, timedelta, timezone
import os
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

@teacher_bp.route('/debug/storage/recordings/<lecture_id>', methods=['GET'])
@teacher_required
def debug_list_recordings(lecture_id):
    """List files under recordings/lecture_<lecture_id> in Supabase Storage"""
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


@teacher_bp.route('/debug/storage/recordings/<lecture_id>/info', methods=['GET'])
@teacher_required
def debug_recording_info(lecture_id):
    """Get info for files under recordings/lecture_<lecture_id> (returns info for each file)"""
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
            # SDK may return dicts or strings
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

@teacher_bp.route('/dashboard')
@teacher_required
def dashboard():
    """Teacher dashboard"""
    try:
        teacher_id = session.get('user_id')
        
        # Get teacher statistics
        stats = db.get_teacher_stats(teacher_id)
        
        # Get teacher's cohorts
        cohorts = db.get_teacher_cohorts(teacher_id)
        
        # Get recent lectures
        lectures = db.get_lectures_by_teacher(teacher_id)
        
        return render_template('teacher_dashboard.html', 
                             stats=stats, 
                             cohorts=cohorts, 
                             lectures=lectures)
    except Exception as e:
        print(f"Error loading teacher dashboard: {e}")
        return render_template('teacher_dashboard.html', 
                             stats={'cohorts': 0, 'lectures': 0, 'students': 0, 'materials': 0, 'quizzes': 0}, 
                             cohorts=[], 
                             lectures=[])

@teacher_bp.route('/stats', methods=['GET'])
@teacher_required
def get_stats():
    """Get teacher statistics"""
    try:
        teacher_id = session.get('user_id')
        stats = db.get_teacher_stats(teacher_id)
        
        return jsonify({
            'success': True,
            'stats': stats
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/materials/<material_id>/download', methods=['GET'])
@teacher_required
def download_material(material_id):
    """Download a material file"""
    try:
        teacher_id = session.get('user_id')
        print(f"Downloading material {material_id} for teacher {teacher_id}")
        
        # Get material details
        material = db.get_material_by_id(material_id)
        print(f"Material found: {material}")
        
        if not material:
            return jsonify({'error': 'Material not found'}), 404
        
        # Verify teacher has access to this material
        if material.get('teacher_id') != teacher_id:
            return jsonify({'error': 'Access denied to this material'}), 403
        
        # Get download URL using the new method
        download_url, message = db.get_material_download_url(material_id)
        print(f"Download URL: {download_url}")
        
        if not download_url:
            return jsonify({'error': f'Failed to get download URL: {message}'}), 404
        
        # Increment download count
        db.increment_material_download_count(material_id)
        
        # If it's a Supabase Storage URL, redirect to it
        if download_url.startswith('http'):
            return redirect(download_url)
        else:
            # Fallback for local files (legacy support)
            if not os.path.exists(download_url):
                return jsonify({'error': f'Material file not found at path: {download_url}'}), 404
            
            return send_file(
                download_url,
                as_attachment=True,
                download_name=material.get('file_name', 'material')
            )
        
    except Exception as e:
        print(f"Error downloading material: {e}")
        return jsonify({'error': f'Download failed: {str(e)}'}), 500

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

@teacher_bp.route('/recorded-lectures', methods=['GET'])
@teacher_required
def get_recorded_lectures():
    """Get teacher's recorded lectures with filters"""
    try:
        teacher_id = session.get('user_id')
        cohort_id = request.args.get('cohort_id')
        date_from = request.args.get('date_from')
        date_to = request.args.get('date_to')
        
        # Get teacher's cohorts first
        cohorts = db.get_teacher_cohorts(teacher_id)
        cohort_ids = [c['id'] for c in cohorts]
        
        if not cohort_ids:
            return jsonify({
                'success': True,
                'recordings': [],
                'cohorts': []
            }), 200
        
        # Get recordings for teacher's cohorts
        recordings = []
        for cohort_id in cohort_ids:
            cohort_recordings = db.get_cohort_recordings(cohort_id, date_from, date_to)
            recordings.extend(cohort_recordings)
        
        return jsonify({
            'success': True,
            'recordings': recordings,
            'cohorts': cohorts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/recordings/upload', methods=['POST'])
@teacher_required
def upload_recording():
    """Upload a recorded lecture directly to Supabase Storage"""
    try:
        teacher_id = session.get('user_id')
        
        # Check if file is present
        if 'recording' not in request.files:
            return jsonify({'error': 'No recording file provided'}), 400
        
        file = request.files['recording']
        if file.filename == '':
            return jsonify({'error': 'No recording file selected'}), 400
        
        # Get form data
        lecture_id = request.form.get('lecture_id')
        cohort_id = request.form.get('cohort_id')
        title = request.form.get('title', 'Recorded Lecture')
        description = request.form.get('description', '')
        
        if not lecture_id or not cohort_id:
            return jsonify({'error': 'Lecture ID and Cohort ID are required'}), 400
        
        # Upload directly to Supabase Storage
        storage_url = None
        if db.storage:
            try:
                storage_url, message = db.storage.upload_file(
                    file=file,
                    bucket_name='recordings',
                    folder_path=f"lecture_{lecture_id}",
                    custom_filename=f"{title}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                )
                
                if not storage_url:
                    print(f"Storage upload failed: {message}")
                    storage_url = None
            except Exception as e:
                print(f"Storage upload error: {e}")
                storage_url = None
        
        # Fallback to local storage if Supabase Storage is not available
        if not storage_url:
            # Create upload directory if it doesn't exist
            upload_dir = 'recordings/videos'
            os.makedirs(upload_dir, exist_ok=True)
            
            # Generate unique filename
            file_extension = os.path.splitext(file.filename)[1]
            unique_filename = f"{title}_{datetime.now().strftime('%Y%m%d_%H%M%S')}{file_extension}"
            file_path = os.path.join(upload_dir, unique_filename)
            
            # Save file locally
            file.save(file_path)
            storage_url = file_path
            print(f"Saved recording locally: {file_path}")
        
        # Get file size
        file_size = len(file.read())
        file.seek(0)  # Reset file pointer
        
        # Upload to Supabase database with Storage URL
        recording_id, message = db.create_session_recording(
            lecture_id=lecture_id,
            cohort_id=cohort_id,
            teacher_id=teacher_id,
            title=title,
            description=description,
            recording_path=storage_url,  # Supabase Storage URL
            file_size=file_size,
            duration=request.form.get('duration', 0)
        )
        
        if recording_id:
            return jsonify({
                'success': True,
                'recording_id': recording_id,
                'message': message,
                'file_url': storage_url
            }), 201
        else:
            return jsonify({'error': message}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/debug/storage', methods=['GET'])
@teacher_required
def debug_storage():
    """Debug storage connection"""
    try:
        if not db.storage:
            return jsonify({
                'success': False,
                'message': 'Storage manager not initialized',
                'storage_available': False
            }), 500
        
        # Test storage connection
        try:
            # Try to list files in materials bucket
            files = db.storage.list_files('materials')
            return jsonify({
                'success': True,
                'message': 'Storage connection working',
                'storage_available': True,
                'materials_files': len(files) if files else 0
            }), 200
        except Exception as e:
            return jsonify({
                'success': False,
                'message': f'Storage connection failed: {str(e)}',
                'storage_available': False
            }), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/debug/email', methods=['GET'])
@teacher_required
def debug_email():
    """Debug email service"""
    try:
        teacher_id = session.get('user_id')
        teacher = db.get_teacher_by_id(teacher_id)
        
        if not teacher:
            return jsonify({'error': 'Teacher not found'}), 404
        
        # Test email configuration
        email_config = {
            'smtp_host': email_service.smtp_host,
            'smtp_port': email_service.smtp_port,
            'smtp_username': email_service.smtp_username,
            'from_email': email_service.from_email,
            'smtp_configured': bool(email_service.smtp_username and email_service.smtp_password)
        }
        
        # Try to send a test email
        try:
            test_result = email_service.send_lecture_notification(
                user_email=teacher['email'],
                user_name=teacher['name'],
                lecture_title='Test Lecture',
                teacher_name=teacher['name'],
                scheduled_time='2024-01-01 10:00:00',
                cohort_name='Test Cohort'
            )
            
            return jsonify({
                'success': True,
                'message': 'Email service test completed',
                'email_config': email_config,
                'test_email_sent': test_result,
                'teacher_email': teacher['email']
            }), 200
            
        except Exception as e:
            return jsonify({
                'success': False,
                'message': f'Email test failed: {str(e)}',
                'email_config': email_config,
                'teacher_email': teacher['email']
            }), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@teacher_bp.route('/lecture/<lecture_id>/materials', methods=['GET'])
@teacher_required
def get_lecture_materials(lecture_id):
    """Get materials for a specific lecture in live session"""
    try:
        teacher_id = session.get('user_id')
        
        # Verify teacher has access to this lecture
        lecture = db.get_lecture_by_id(lecture_id)
        if not lecture or lecture['teacher_id'] != teacher_id:
            return jsonify({'error': 'Access denied to this lecture'}), 403
        
        # Get materials for this lecture
        materials = db.get_lecture_materials(lecture_id)
        
        return jsonify({
            'success': True,
            'materials': materials
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/lecture/<lecture_id>/polls', methods=['GET'])
@teacher_required
def get_lecture_polls(lecture_id):
    """Get polls for a specific lecture in live session"""
    try:
        teacher_id = session.get('user_id')
        
        # Verify teacher has access to this lecture
        lecture = db.get_lecture_by_id(lecture_id)
        if not lecture or lecture['teacher_id'] != teacher_id:
            return jsonify({'error': 'Access denied to this lecture'}), 403
        
        # Get polls for this lecture
        polls = db.get_lecture_polls(lecture_id)
        
        return jsonify({
            'success': True,
            'polls': polls
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/recordings/<recording_id>/debug', methods=['GET'])
@teacher_required
def debug_recording(recording_id):
    """Debug recording data"""
    try:
        recording = db.get_recording_by_id(recording_id)
        if not recording:
            return jsonify({'error': 'Recording not found'}), 404
        
        return jsonify({
            'recording_id': recording_id,
            'recording_data': recording,
            'recording_path': recording.get('recording_path'),
            'lecture_id': recording.get('lecture_id')
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/recordings/<recording_id>/download', methods=['GET'])
@teacher_required
def download_recording(recording_id):
    """Download a recorded lecture"""
    try:
        teacher_id = session.get('user_id')
        
        # Get recording details
        recording = db.get_recording_by_id(recording_id)
        if not recording:
            return jsonify({'error': 'Recording not found'}), 404
        
        # Verify teacher has access to this recording
        if recording.get('teacher_id') != teacher_id:
            return jsonify({'error': 'Access denied to this recording'}), 403
        
        # Get file URL from Supabase Storage
        file_url = recording.get('recording_path')
        print(f"Recording file URL: {file_url}")
        
        if not file_url:
            return jsonify({'error': 'Recording file URL not found'}), 404
        
        # Handle recording file path
        print(f"Recording file URL from database: {file_url}")
        
        if file_url.startswith('http'):
            # It's already a full URL (public or private). Prefer generating a signed URL
            # using Supabase storage (in case the bucket is private) before redirecting.
            try:
                from config import Config
                from utils.storage_supabase import SupabaseStorageManager

                # Prefer using the existing storage manager on the db object
                storage = getattr(db, 'storage', None)
                if not storage:
                    # Construct a storage manager with config values
                    storage = SupabaseStorageManager(Config.SUPABASE_URL, Config.SUPABASE_KEY)

                # If the URL is a Supabase public storage URL, extract bucket and object path
                marker = '/storage/v1/object/public/'
                if marker in file_url:
                    suffix = file_url.split(marker, 1)[1]
                    # suffix is like: 'recordings/lecture_xxx/filename'
                    parts = suffix.split('/', 1)
                    bucket = parts[0] if parts else 'recordings'
                    object_path = parts[1] if len(parts) > 1 else ''

                    if object_path:
                        print(f"Attempting to get signed URL for bucket='{bucket}', path='{object_path}'")
                        signed_url = storage.get_signed_url(bucket, object_path)
                        if signed_url:
                            print(f"Successfully got signed URL: {signed_url}")
                            db.increment_recording_download_count(recording_id)
                            return redirect(signed_url)
                        else:
                            print(f"Signed URL not available for {object_path}, falling back to public URL")
                        # If signed URL not available, try to list the lecture folder and find a matching filename
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
                                # Match exact or prefix (handles names without extensions)
                                if candidate == base_name or candidate.startswith(base_name):
                                    candidate_path = f"{folder}/{candidate}"
                                    print(f"Found candidate object: {candidate_path}, attempting signed URL")
                                    signed_url = storage.get_signed_url(bucket, candidate_path)
                                    if signed_url:
                                        print(f"Successfully got signed URL for candidate: {signed_url}")
                                        db.increment_recording_download_count(recording_id)
                                        return redirect(signed_url)
                        except Exception as e:
                            print(f"Error while listing bucket '{bucket}' folder '{folder}': {e}")

                # Not a Supabase storage URL or signed URL unavailable — redirect to the stored URL
                print(f"Recording is already a URL, redirecting to: {file_url}")
                db.increment_recording_download_count(recording_id)
                return redirect(file_url)

            except Exception as e:
                print(f"Error trying to generate signed URL from public URL: {e}")
                # Fall back to redirecting to the public URL
                db.increment_recording_download_count(recording_id)
                return redirect(file_url)

        else:
            # Try to get a signed URL from Supabase Storage for local/object paths
            try:
                storage = getattr(db, 'storage', None)
                if not storage:
                    from config import Config
                    from utils.storage_supabase import SupabaseStorageManager
                    storage = SupabaseStorageManager(Config.SUPABASE_URL, Config.SUPABASE_KEY)

                # Extract the relative path from the file_url
                # file_url might be: "lecture_0253d886-c0e0-40d9-9b64-6436d5e69585/TEst_20251003_192852"
                # or just the filename: "TEst_20251003_192852"
                relative_path = file_url
                if not file_url.startswith('lecture_'):
                    # Try to construct the path with lecture folder
                    lecture_id = recording.get('lecture_id', '')
                    if lecture_id:
                        relative_path = f"lecture_{lecture_id}/{file_url}"

                print(f"Attempting to get signed URL for path: {relative_path}")
                signed_url = storage.get_signed_url('recordings', relative_path)
                if not signed_url:
                    # Try common extensions if the object was stored with an extension
                    for ext in ('.webm', '.mp4', '.mkv'):
                        try_path = f"{relative_path}{ext}"
                        print(f"Trying path with extension: {try_path}")
                        signed_url = storage.get_signed_url('recordings', try_path)
                        if signed_url:
                            relative_path = try_path
                            break

                if signed_url:
                    print(f"Successfully got signed URL: {signed_url}")
                    db.increment_recording_download_count(recording_id)
                    return redirect(signed_url)
                else:
                    print(f"Failed to get signed URL for path: {relative_path}")

            except Exception as e:
                print(f"Error getting signed URL for recording: {e}")

            # Fallback for local files (legacy support)
            file_path = file_url
            if not os.path.exists(file_path):
                return jsonify({'error': f'Recording file not found at path: {file_path}'}), 404
            
            db.increment_recording_download_count(recording_id)
            return send_file(
                file_path,
                as_attachment=True,
                download_name=f"recording_{recording_id}.webm"
            )
        
    except Exception as e:
        print(f"Error downloading recording: {e}")
        return jsonify({'error': f'Download failed: {str(e)}'}), 500

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
            print(f"✅ Lecture created successfully: {lecture_id}")
            print(f"📧 Starting email notification process...")
            
            # Check email service configuration
            if not email_service.smtp_username or not email_service.smtp_password:
                print("⚠️ Email service not configured - SMTP credentials missing")
                return jsonify({
                    'success': True,
                    'lecture_id': lecture_id,
                    'message': 'Lecture created successfully (email notifications disabled)'
                }), 201
            
            # Send email notifications to students in the cohort
            try:
                # Get cohort details
                cohort = db.get_cohort_by_id(data['cohort_id'])
                if cohort:
                    print(f"📋 Cohort found: {cohort['name']} (ID: {cohort['id']})")
                    # Send confirmation email to teacher
                    try:
                        email_service.send_lecture_notification(
                            user_email=teacher['email'],
                            user_name=teacher['name'],
                            lecture_title=data['title'],
                            teacher_name=teacher['name'],
                            scheduled_time=data['scheduled_time'],
                            cohort_name=cohort['name']
                        )
                        print(f"✅ Sent lecture creation confirmation to teacher: {teacher['email']}")
                    except Exception as teacher_email_error:
                        print(f"❌ Error sending confirmation to teacher: {teacher_email_error}")
                    
                    # Get students in the cohort
                    students = db.get_cohort_students(data['cohort_id'])
                    print(f"📧 Sending lecture notifications to {len(students)} students")
                    
                    # Send email to each student
                    for student in students:
                        try:
                            email_service.send_lecture_notification(
                                user_email=student['email'],
                                user_name=student['name'],
                                lecture_title=data['title'],
                                teacher_name=teacher['name'],
                                scheduled_time=data['scheduled_time'],
                                cohort_name=cohort['name']
                            )
                            print(f"✅ Sent notification to student: {student['email']}")
                        except Exception as student_email_error:
                            print(f"❌ Error sending notification to student {student['email']}: {student_email_error}")
            except Exception as email_error:
                print(f"Error sending lecture notifications: {email_error}")
                # Don't fail the lecture creation if email fails
            
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
            # Send email notification to teacher
            try:
                teacher = db.get_teacher_by_id(teacher_id)
                cohort = db.get_cohort_by_id(cohort_id)
                
                if teacher and cohort:
                    email_service.send_welcome_email(
                        user_email=teacher['email'],
                        user_name=teacher['name'],
                        user_type='teacher',
                        cohort_name=cohort['name']
                    )
            except Exception as email_error:
                print(f"Error sending teacher assignment notification: {email_error}")
                # Don't fail the assignment if email fails
            
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

@teacher_bp.route('/materials/upload', methods=['POST'])
@teacher_required
def upload_material():
    """Upload material file directly to Supabase Storage"""
    try:
        teacher_id = session.get('user_id')
        
        # Check if file is present
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        # Get form data
        title = request.form.get('title')
        description = request.form.get('description', '')
        cohort_id = request.form.get('cohort_id')
        lecture_id = request.form.get('lecture_id')  # Optional
        
        if not title or not cohort_id:
            return jsonify({'error': 'Title and cohort are required'}), 400
        
        # Get teacher info
        teacher = db.get_teacher_by_id(teacher_id)
        if not teacher:
            return jsonify({'error': 'Teacher not found'}), 404
        
        # Upload directly to Supabase Storage
        storage_url = None
        if db.storage:
            try:
                print(f"Attempting to upload to Supabase Storage...")
                if lecture_id:
                    # Upload to lecture folder
                    storage_url, message = db.storage.upload_file(
                        file=file,
                        bucket_name='materials',
                        folder_path=f"lecture_{lecture_id}",
                        custom_filename=f"{title}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                    )
                else:
                    # Upload to cohort folder
                    storage_url, message = db.storage.upload_file(
                        file=file,
                        bucket_name='materials',
                        folder_path=f"cohort_{cohort_id}",
                        custom_filename=f"{title}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                    )
                
                if storage_url:
                    print(f"✅ Successfully uploaded to Supabase Storage: {storage_url}")
                else:
                    print(f"❌ Storage upload failed: {message}")
                    # Don't fall back to local storage - fail the upload
                    return jsonify({'error': f'Failed to upload to storage: {message}'}), 500
            except Exception as e:
                print(f"❌ Storage upload error: {e}")
                return jsonify({'error': f'Storage upload failed: {str(e)}'}), 500
        else:
            print("❌ Storage manager not available")
            return jsonify({'error': 'Storage service not available'}), 500
        
        # Get file size
        file_size = len(file.read())
        file.seek(0)  # Reset file pointer
        
        # Determine file type
        file_extension = os.path.splitext(file.filename)[1]
        file_type = file_extension[1:].lower() if file_extension else 'unknown'
        
        # Add material to database with Supabase Storage URL
        if lecture_id:
            # Add to specific lecture
            material_id, message = db.add_material(
                lecture_id=lecture_id,
                title=title,
                description=description,
                file_path=storage_url,  # Supabase Storage URL
                compressed_path=storage_url,
                file_size=file_size,
                file_type=file_type
            )
        else:
            # Add to cohort
            material_id, message = db.add_material_to_cohort(
                cohort_id=cohort_id,
                teacher_id=teacher_id,
                title=title,
                description=description,
                file_path=storage_url,  # Supabase Storage URL
                file_size=file_size,
                file_type=file_type
            )
        
        if material_id:
            return jsonify({
                'success': True,
                'material_id': material_id,
                'message': message,
                'file_url': storage_url
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
            print(f"✅ Quiz created successfully: {quiz_id}")
            print(f"📧 Starting email notification process...")
            
            # Check email service configuration
            if not email_service.smtp_username or not email_service.smtp_password:
                print("⚠️ Email service not configured - SMTP credentials missing")
                return jsonify({
                    'success': True,
                    'quiz_id': quiz_id,
                    'message': 'Quiz created successfully (email notifications disabled)'
                }), 201
            
            # Send email notifications
            try:
                # Get teacher and cohort details
                teacher = db.get_teacher_by_id(teacher_id)
                cohort = db.get_cohort_by_id(data['cohort_id'])
                
                if teacher and cohort:
                    # Send confirmation email to teacher
                    try:
                        email_service.send_quiz_notification(
                            user_email=teacher['email'],
                            user_name=teacher['name'],
                            quiz_title=data['title'],
                            teacher_name=teacher['name'],
                            cohort_name=cohort['name']
                        )
                        print(f"✅ Sent quiz creation confirmation to teacher: {teacher['email']}")
                    except Exception as teacher_email_error:
                        print(f"❌ Error sending confirmation to teacher: {teacher_email_error}")
                    
                    # Get students in the cohort
                    students = db.get_cohort_students(data['cohort_id'])
                    print(f"📧 Sending quiz notifications to {len(students)} students")
                    
                    # Send email to each student
                    for student in students:
                        try:
                            email_service.send_quiz_notification(
                                user_email=student['email'],
                                user_name=student['name'],
                                quiz_title=data['title'],
                                teacher_name=teacher['name'],
                                cohort_name=cohort['name']
                            )
                            print(f"✅ Sent notification to student: {student['email']}")
                        except Exception as student_email_error:
                            print(f"❌ Error sending notification to student {student['email']}: {student_email_error}")
            except Exception as email_error:
                print(f"Error sending quiz notifications: {email_error}")
                # Don't fail the quiz creation if email fails
            
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

@teacher_bp.route('/lectures/<lecture_id>/start-recording', methods=['POST'])
@teacher_required
def start_recording(lecture_id):
    """Start recording a lecture session"""
    try:
        teacher_id = session.get('user_id')
        
        # Get lecture details
        lecture = db.get_lecture_by_id(lecture_id)
        if not lecture:
            return jsonify({'error': 'Lecture not found'}), 404
        
        # Verify teacher has access to this lecture
        if lecture['teacher_id'] != teacher_id:
            return jsonify({'error': 'Access denied to this lecture'}), 403
        
        # Create a session recording entry
        recording_id, message = db.create_session_recording(
            lecture_id=lecture_id,
            cohort_id=lecture['cohort_id'],
            teacher_id=teacher_id,
            title=f"Recording - {lecture['title']}",
            description=f"Live recording of {lecture['title']}",
            recording_path="",  # Will be updated when recording stops
            file_size=0,
            duration=0
        )
        
        if recording_id:
            return jsonify({
                'success': True,
                'recording_id': recording_id,
                'message': 'Recording started successfully'
            }), 200
        else:
            return jsonify({'error': message}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/lectures/<lecture_id>/stop-recording', methods=['POST'])
@teacher_required
def stop_recording(lecture_id):
    """Stop recording a lecture session and upload to Supabase"""
    try:
        teacher_id = session.get('user_id')
        data = request.get_json()
        
        recording_id = data.get('recording_id')
        recording_data = data.get('recording_data')  # Base64 encoded video data
        
        if not recording_id or not recording_data:
            return jsonify({'error': 'Recording ID and data are required'}), 400
        
        # Get lecture details
        lecture = db.get_lecture_by_id(lecture_id)
        if not lecture:
            return jsonify({'error': 'Lecture not found'}), 404
        
        # Verify teacher has access to this lecture
        if lecture['teacher_id'] != teacher_id:
            return jsonify({'error': 'Access denied to this lecture'}), 403
        
        # Create upload directory if it doesn't exist
        upload_dir = 'recordings/videos'
        os.makedirs(upload_dir, exist_ok=True)
        
        # Generate unique filename
        unique_filename = f"recording_{lecture_id}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.webm"
        file_path = os.path.join(upload_dir, unique_filename)
        
        # Save recording data to file
        import base64
        video_data = base64.b64decode(recording_data)
        with open(file_path, 'wb') as f:
            f.write(video_data)
        
        # Get file size
        file_size = os.path.getsize(file_path)
        
        # Update the recording entry with file path and size
        success = db.update_session_recording(
            recording_id=recording_id,
            recording_path=file_path,
            file_size=file_size,
            duration=data.get('duration', 0)
        )
        
        if success:
            return jsonify({
                'success': True,
                'message': 'Recording saved successfully',
                'file_path': file_path
            }), 200
        else:
            return jsonify({'error': 'Failed to save recording'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/cohorts/<cohort_id>/lectures', methods=['GET'])
@teacher_required
def get_cohort_lectures(cohort_id):
    """Get lectures for a specific cohort"""
    try:
        teacher_id = session.get('user_id')
        
        # Verify teacher has access to this cohort
        cohorts = db.get_teacher_cohorts(teacher_id)
        cohort_ids = [c['id'] for c in cohorts]
        
        if cohort_id not in cohort_ids:
            return jsonify({'error': 'Access denied to this cohort'}), 403
        
        # Get lectures for this cohort
        lectures = db.get_lectures_by_cohort(cohort_id)
        
        print(f"Found {len(lectures)} lectures for cohort {cohort_id}")
        for lecture in lectures:
            print(f"  - {lecture.get('title', 'No title')} (ID: {lecture.get('id', 'No ID')})")
        
        return jsonify({
            'success': True,
            'lectures': lectures
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
            print(f"✅ Poll created successfully: {poll_id}")
            print(f"📧 Starting email notification process...")
            
            # Check email service configuration
            if not email_service.smtp_username or not email_service.smtp_password:
                print("⚠️ Email service not configured - SMTP credentials missing")
                return jsonify({
                    'success': True,
                    'poll_id': poll_id,
                    'message': 'Poll created successfully (email notifications disabled)'
                }), 201
            
            # Send email notifications
            try:
                # Get cohort details
                cohort = db.get_cohort_by_id(data['cohort_id'])
                
                if cohort:
                    # Send confirmation email to teacher
                    try:
                        email_service.send_welcome_email(
                            user_email=teacher['email'],
                            user_name=teacher['name'],
                            user_type='teacher',
                            cohort_name=cohort['name']
                        )
                        print(f"✅ Sent poll creation confirmation to teacher: {teacher['email']}")
                    except Exception as teacher_email_error:
                        print(f"❌ Error sending confirmation to teacher: {teacher_email_error}")
                    
                    # Get students in the cohort
                    students = db.get_cohort_students(data['cohort_id'])
                    print(f"📧 Sending poll notifications to {len(students)} students")
                    
                    # Send email to each student
                    for student in students:
                        try:
                            email_service.send_welcome_email(
                                user_email=student['email'],
                                user_name=student['name'],
                                user_type='student',
                                cohort_name=cohort['name']
                            )
                            print(f"✅ Sent notification to student: {student['email']}")
                        except Exception as student_email_error:
                            print(f"❌ Error sending notification to student {student['email']}: {student_email_error}")
            except Exception as email_error:
                print(f"Error sending poll notifications: {email_error}")
                # Don't fail the poll creation if email fails
            
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
        teacher_id = session.get('user_id')
        
        # Verify teacher has access to this poll
        poll = db.supabase.table('polls').select('*').eq('id', poll_id).execute()
        if not poll.data:
            return jsonify({'error': 'Poll not found'}), 404
        
        poll_data = poll.data[0]
        if poll_data.get('teacher_id') != teacher_id:
            return jsonify({'error': 'Access denied'}), 403
        
        results = db.get_poll_results(poll_id)
        
        if not results:
            return jsonify({'error': 'No results found'}), 404
        
        # Return results in the format expected by the frontend
        return jsonify({
            'success': True,
            'question': results.get('question'),
            'results': results.get('results', []),
            'total_votes': results.get('total_votes', 0)
        }), 200
        
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
        
        # Get quiz set details
        quiz_set = db.get_quiz_set_by_id(quiz_set_id)
        if not quiz_set:
            return jsonify({'error': 'Quiz not found'}), 404
        
        # Get quiz questions
        questions = db.get_quiz_questions_by_set(quiz_set_id)
        
        # Get quiz attempts
        attempts = db.get_quiz_attempts_by_quiz_set(quiz_set_id)
        
        # Get quiz responses - using direct Supabase query since the function might be missing
        try:
            responses_result = db.supabase.table('quiz_responses').select('*').eq('quiz_set_id', quiz_set_id).execute()
            responses = responses_result.data
        except Exception as e:
            print(f"Error fetching quiz responses: {str(e)}")
            responses = []
        
        # Calculate statistics
        total_attempts = len(attempts)
        completed_attempts = len([a for a in attempts if a.get('completed', False)])
        average_score = sum([a.get('score', 0) for a in attempts]) / total_attempts if total_attempts > 0 else 0
        completion_rate = (completed_attempts / total_attempts * 100) if total_attempts > 0 else 0
        
        # Calculate question accuracy
        question_stats = []
        for question in questions:
            question_responses = [r for r in responses if r.get('question_id') == question['id']]
            correct_responses = len([r for r in question_responses if r.get('is_correct', False)])
            total_responses = len(question_responses)
            accuracy = (correct_responses / total_responses * 100) if total_responses > 0 else 0
            
            question_stats.append({
                'question_id': question['id'],
                'question_text': question['question_text'],
                'correct_answer': question['correct_answer'],
                'accuracy': accuracy,
                'total_responses': total_responses,
                'correct_responses': correct_responses
            })
        
        return jsonify({
            'success': True,
            'quiz_set': quiz_set,
            'questions': question_stats,
            'attempts': attempts,
            'responses': responses,
            'total_attempts': total_attempts,
            'completed_attempts': completed_attempts,
            'average_score': round(average_score, 1),
            'completion_rate': round(completion_rate, 1),
            'average_accuracy': round(sum([q['accuracy'] for q in question_stats]) / len(question_stats), 1) if question_stats else 0
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
        
        post_id, message = db.add_discussion_post(
            forum_id=forum_id,
            author_id=teacher_id,
            author_type='teacher',
            content=data['content'],
            title=data.get('title')
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
        return jsonify({
            'success': True,
            'posts': posts
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@teacher_bp.route('/discussion/<forum_id>')
@teacher_required
def discussion_forum_page(forum_id):
    """Discussion forum page for teachers"""
    try:
        teacher_id = session.get('user_id')
        
        # Verify teacher has access to this forum
        forum = db.supabase.table('discussion_forums').select('*').eq('id', forum_id).execute()
        if not forum.data:
            return render_template('error.html', 
                                 error="Discussion forum not found", 
                                 message="The requested discussion forum could not be found"), 404
        
        forum_data = forum.data[0]
        
        # Check if teacher has access to this cohort
        teacher_cohorts = db.get_teacher_cohorts(teacher_id)
        cohort_ids = [c['id'] for c in teacher_cohorts]
        
        if forum_data['cohort_id'] not in cohort_ids:
            return render_template('error.html', 
                                 error="Access denied", 
                                 message="You don't have access to this discussion forum"), 403
        
        # Use the real-time chatroom template
        return render_template('realtime_chatroom.html', 
                             forum_id=forum_id, 
                             forum=forum_data,
                             session=session)
        
    except Exception as e:
        return render_template('error.html', 
                             error="Error loading discussion forum", 
                             message=str(e)), 500

@teacher_bp.route('/discussions/<forum_id>/messages', methods=['GET'])
@teacher_required
def get_forum_messages(forum_id):
    """Get messages for a discussion forum"""
    try:
        teacher_id = session.get('user_id')
        
        # Verify teacher has access to this forum
        forum = db.supabase.table('discussion_forums').select('*').eq('id', forum_id).execute()
        if not forum.data:
            return jsonify({'error': 'Forum not found'}), 404
        
        forum_data = forum.data[0]
        
        # Check if teacher has access to this cohort
        teacher_cohorts = db.get_teacher_cohorts(teacher_id)
        cohort_ids = [c['id'] for c in teacher_cohorts]
        
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

@teacher_bp.route('/live-session/<lecture_id>', methods=['GET'])
@teacher_required
def start_live_session(lecture_id):
    """Start a live session for a lecture"""
    try:
        teacher_id = session.get('user_id')
        
        # Verify teacher has access to this lecture
        lecture = db.get_lecture_by_id(lecture_id)
        if not lecture:
            return jsonify({'error': 'Lecture not found'}), 404
        
        # Check if teacher owns this lecture
        if lecture['teacher_id'] != teacher_id:
            return jsonify({'error': 'Access denied to this lecture'}), 403
        
        # Allow teachers to start lectures anytime
        # No time restrictions for lecture start
        
        # Update lecture status to live
        db.update_lecture_status(lecture_id, 'live')
        
        # Add session to active_sessions for Socket.IO
        from main import active_sessions, session_participants
        session_id = f"session_{lecture_id}"
        active_sessions[session_id] = {
            'lecture_id': lecture_id,
            'teacher_id': teacher_id,
            'started_at': datetime.now().isoformat()
        }
        session_participants[session_id] = []
        
        # Return live session page
        return render_template('teacher_live_session.html', 
                             lecture_id=lecture_id,
                             session_id=session_id)
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500