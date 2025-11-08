"""
Main Application Entry Point
Digi Kul Teachers Portal - Complete Route Refactor
"""

# Load environment variables from .env file
from dotenv import load_dotenv
load_dotenv()

from flask import Flask, request, jsonify, send_file, render_template, session, redirect, url_for, flash, make_response
from flask_cors import CORS
try:
    from flask_socketio import SocketIO, emit, join_room, leave_room, rooms
except ImportError:
    print("Flask-SocketIO not installed. Install with: pip install flask-socketio")
    SocketIO = None
    emit = join_room = leave_room = rooms = None
from werkzeug.utils import secure_filename
from werkzeug.security import generate_password_hash, check_password_hash
import os
import uuid
import json
import threading
import time
from datetime import datetime, timedelta
from functools import wraps

# Import configuration and utilities
from config import Config
from utils.database_supabase import SupabaseDatabaseManager as DatabaseManager
from utils.compression import compress_audio, compress_image, compress_pdf, get_file_type

# Import new modular components
from middlewares.auth_middleware import AuthMiddleware
from middlewares.cohort_middleware import CohortMiddleware
from services.cohort_service import CohortService
from services.lecture_service import LectureService
from services.quiz_service import QuizService
from services.session_recording_service import SessionRecordingService
from utils.email_service import EmailService

# Import route blueprints
from routes.auth_routes import auth_bp
from routes.cohort_routes import cohort_bp
from routes.lecture_routes import lecture_bp
from routes.quiz_routes import quiz_bp
from routes.super_admin_routes import super_admin_bp
from routes.institution_routes import institution_bp
from routes.institution_admin_routes import institution_admin_bp
from routes.teacher_routes import teacher_bp
from routes.student_routes import student_bp
from routes.chat_routes import chat_bp
from routes.admin_routes import admin_bp

# Initialize the database
db = DatabaseManager()
email_service = EmailService()

# Initialize services
cohort_service = CohortService(db, email_service)
lecture_service = LectureService(db, email_service)
quiz_service = QuizService(db, email_service)
recording_service = SessionRecordingService(db)

# Initialize middleware (will be properly initialized after app creation)
auth_middleware = None
cohort_middleware = None

app = Flask(__name__)
app.config.from_object(Config)

# Initialize middleware with the app
auth_middleware = AuthMiddleware(app, db)
cohort_middleware = CohortMiddleware(app, db)

# Set auth middleware reference in routes
from routes.super_admin_routes import set_auth_middleware
from routes.institution_routes import set_auth_middleware as set_institution_auth_middleware
from routes.teacher_routes import set_auth_middleware as set_teacher_auth_middleware
from routes.student_routes import set_auth_middleware as set_student_auth_middleware
set_auth_middleware(auth_middleware)
set_institution_auth_middleware(auth_middleware)
set_teacher_auth_middleware(auth_middleware)
set_student_auth_middleware(auth_middleware)

# Enhanced session security configuration
app.secret_key = os.environ.get('SECRET_KEY', 'your-secret-key-change-this')
app.permanent_session_lifetime = timedelta(hours=8)
app.config['SESSION_COOKIE_SECURE'] = False  # Set to False for localhost testing
app.config['SESSION_COOKIE_HTTPONLY'] = True
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'
app.config['SESSION_COOKIE_NAME'] = 'digi_kul_session'
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(hours=8)

# Additional security headers
@app.after_request
def set_security_headers(response):
    """Set security headers for all responses"""
    # Prevent caching of sensitive pages
    if request.endpoint and any(x in request.endpoint for x in ['dashboard', 'admin', 'teacher', 'student']):
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate, private'
        response.headers['Pragma'] = 'no-cache'
        response.headers['Expires'] = '0'
    
    # Security headers
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    
    return response

CORS(app, origins="*", supports_credentials=True)

if SocketIO:
    socketio = SocketIO(app, cors_allowed_origins="*", async_mode='threading')
else:
    socketio = None

# Global session storage for active sessions
active_sessions = {}
session_participants = {}
online_users = {}

def cleanup_session(session_id):
    """Clean up session data when session ends"""
    if session_id in active_sessions:
        del active_sessions[session_id]
    if session_id in session_participants:
        del session_participants[session_id]

# Ensure upload directories exist
os.makedirs(os.path.join(app.config['UPLOAD_FOLDER'], 'audio'), exist_ok=True)
os.makedirs(os.path.join(app.config['UPLOAD_FOLDER'], 'images'), exist_ok=True)
os.makedirs(os.path.join(app.config['UPLOAD_FOLDER'], 'documents'), exist_ok=True)
os.makedirs(os.path.join(app.config['COMPRESSED_FOLDER'], 'audio'), exist_ok=True)
os.makedirs(os.path.join(app.config['COMPRESSED_FOLDER'], 'images'), exist_ok=True)
os.makedirs(os.path.join(app.config['COMPRESSED_FOLDER'], 'documents'), exist_ok=True)

# ==================== BLUEPRINT REGISTRATION ====================

# Register blueprints with proper URL prefixes
app.register_blueprint(auth_bp, url_prefix='/api/auth')
app.register_blueprint(cohort_bp, url_prefix='/api/cohorts')
app.register_blueprint(lecture_bp, url_prefix='/api/lectures')
app.register_blueprint(quiz_bp, url_prefix='/api/quiz')
app.register_blueprint(super_admin_bp)  # No prefix since it's already defined in the blueprint
app.register_blueprint(institution_bp, url_prefix='/institution')
app.register_blueprint(institution_admin_bp, url_prefix='/institution-admin')
app.register_blueprint(teacher_bp, url_prefix='/api/teacher')
app.register_blueprint(student_bp, url_prefix='/api/student')
app.register_blueprint(admin_bp, url_prefix='/api/admin')
app.register_blueprint(chat_bp, url_prefix='/api')

# Set session globals in teacher_routes so they reference the same objects
from routes.teacher_routes import set_session_globals
set_session_globals(active_sessions, session_participants, socketio)
print(f"[MAIN] Set session globals: active_sessions={id(active_sessions)}, participants={id(session_participants)}")

# ==================== MAIN APPLICATION ROUTES ====================

@app.route('/')
def index():
    """Main login page with institution selection"""
    return render_template('index.html')

@app.route('/api/public/institutions', methods=['GET'])
def get_public_institutions():
    """Get all institutions for public display (no authentication required)"""
    try:
        institutions = db.get_all_institutions()
        return jsonify({
            'success': True,
            'institutions': institutions,
            'count': len(institutions) if institutions else 0
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/login')
def login_page():
    """Main login page - redirects to appropriate login based on user type"""
    return render_template('login.html')

# Super admin login route is handled by the super_admin_bp blueprint

@app.route('/institution/<subdomain>/login')
def institution_login_page(subdomain):
    """Institution-specific login page"""
    try:
        # Get institution details by subdomain
        institution = db.get_institution_by_subdomain(subdomain)
        if not institution:
            return render_template('error.html', 
                                 error="Institution not found", 
                                 message=f"No institution found with subdomain: {subdomain}"), 404
        
        return render_template('institution_login.html', institution=institution)
    except Exception as e:
        return render_template('error.html', 
                             error="Error loading institution", 
                             message=str(e)), 500

@app.route('/institution/<subdomain>/register')
def institution_student_registration(subdomain):
    """Institution-specific student registration page"""
    try:
        # Get institution details by subdomain
        institution = db.get_institution_by_subdomain(subdomain)
        if not institution:
            return render_template('error.html', 
                                 error="Institution not found", 
                                 message=f"No institution found with subdomain: {subdomain}"), 404
        
        return render_template('student_registration.html', institution=institution)
    except Exception as e:
        return render_template('error.html', 
                             error="Error loading institution", 
                             message=str(e)), 500

# Super admin dashboard route is handled by the super_admin_bp blueprint

@app.route('/institution-admin/dashboard')
@auth_middleware.institution_admin_required
def institution_admin_dashboard():
    """Institution admin dashboard"""
    return render_template('institution_admin_dashboard.html')

@app.route('/teacher/dashboard')
@auth_middleware.teacher_required
def teacher_dashboard():
    """Teacher dashboard"""
    return render_template('teacher_dashboard.html')

@app.route('/student/dashboard')
@auth_middleware.student_required
def student_dashboard():
    """Student dashboard"""
    return render_template('student_dashboard.html')

# Removed generic admin dashboard - only super admin and institution admin exist

@app.route('/register')
def register_page():
    """Registration page"""
    return render_template('register.html')

@app.route('/logout')
def logout_page():
    """Logout page"""
    try:
        user_id = session.get('user_id')
        user_type = session.get('user_type')
        
        # Remove from online users tracking
        if user_id and user_id in online_users:
            del online_users[user_id]
        
        # Clear all session data
        session.clear()
        session.permanent = False
        
        # Create response
        response = make_response(render_template('logout.html'))
        
        # Set session cookie to expire immediately
        response.set_cookie(
            app.config['SESSION_COOKIE_NAME'], 
            '', 
            expires=0,
            secure=app.config['SESSION_COOKIE_SECURE'],
            httponly=app.config['SESSION_COOKIE_HTTPONLY'],
            samesite=app.config['SESSION_COOKIE_SAMESITE']
        )
        
        # Security headers
        response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate, private'
        response.headers['Pragma'] = 'no-cache'
        response.headers['Expires'] = '0'
        
        return response
        
    except Exception as e:
        return redirect(url_for('index'))

# ==================== LIVE SESSION ROUTES ====================

@app.route('/student/<student_id>')
@auth_middleware.student_required
def student_profile(student_id):
    """Student profile page"""
    if session.get('user_id') != student_id and session.get('user_type') not in ['admin', 'teacher']:
        flash('Access denied.', 'error')
        return redirect(url_for('student_dashboard'))
    
    return render_template('student_profile.html', student_id=student_id)

@app.route('/student/join_session/<session_id>')
@auth_middleware.student_required
def student_join_session(session_id):
    """Student join live session page"""
    if session_id not in active_sessions:
        flash('Session not found or has ended.', 'error')
        return redirect(url_for('student_dashboard'))
    
    session_info = active_sessions[session_id]
    return render_template('student_live_session.html', 
                         session_id=session_id, 
                         lecture_id=session_info['lecture_id'])

@app.route('/teacher/manage_session/<session_id>')
@auth_middleware.teacher_required
def manage_session_page(session_id):
    """Manage live session page for teachers"""
    if session_id not in active_sessions:
        flash('Session not found.', 'error')
        return redirect(url_for('teacher_dashboard'))
    
    session_info = active_sessions[session_id]
    if session_info['teacher_id'] != session['user_id']:
        flash('Access denied.', 'error')
        return redirect(url_for('teacher_dashboard'))
    
    return render_template('teacher_live_session.html', lecture_id=session_info['lecture_id'])

# ==================== FILE DOWNLOAD ROUTES ====================

@app.route('/api/download/<material_id>')
@auth_middleware.api_auth_required
def download_material(material_id):
    """Download material file"""
    try:
        # Get material info from database
        material = db.get_material_by_id(material_id)
        if not material:
            return jsonify({'error': 'Material not found'}), 404
        
        # Check if user has access to this material
        user_type = session.get('user_type')
        user_id = session.get('user_id')
        
        if user_type == 'student':
            # Check if student is enrolled in cohorts that have this material
            student_cohorts = db.get_student_cohorts(user_id)
            cohort_ids = [c['id'] for c in student_cohorts]
            if material['cohort_id'] not in cohort_ids:
                return jsonify({'error': 'Access denied'}), 403
        elif user_type == 'teacher':
            # Check if teacher teaches cohorts that have this material
            teacher_cohorts = db.get_teacher_cohorts(user_id)
            cohort_ids = [c['id'] for c in teacher_cohorts]
            if material['cohort_id'] not in cohort_ids:
                return jsonify({'error': 'Access denied'}), 403
        elif user_type not in ['admin', 'super_admin', 'institution_admin']:
            return jsonify({'error': 'Access denied'}), 403
        
        # Resolve download URL (handles Supabase signed URLs and local paths)
        download_url, message = db.get_material_download_url(material_id)
        if not download_url:
            return jsonify({'error': f'Failed to get download URL: {message}'}), 404

        # Increment download count
        db.increment_material_download_count(material_id)

        # If it's a Supabase Storage URL, redirect to it
        if download_url.startswith('http'):
            return redirect(download_url)
        else:
            # Fallback for local files with robust path resolution
            raw_path = download_url
            base_dir = app.config.get('UPLOAD_FOLDER', 'uploads')
            filename = os.path.basename(raw_path.rstrip('/\\'))

            # Map likely subfolders by type
            file_type = (material.get('file_type') or '').lower()
            type_folder = None
            if file_type in ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'txt']:
                type_folder = 'documents'
            elif file_type in ['jpg', 'jpeg', 'png', 'gif', 'webp']:
                type_folder = 'images'
            elif file_type in ['mp3', 'wav', 'm4a', 'aac']:
                type_folder = 'audio'

            candidates = []
            # Absolute as-is
            if os.path.isabs(raw_path):
                candidates.append(raw_path)
            # Relative variants
            candidates.extend([
                os.path.join(base_dir, raw_path),
                os.path.join(base_dir, filename),
                os.path.join(base_dir, 'materials', filename),
                os.path.join(base_dir, 'documents', filename),
                os.path.join(base_dir, 'images', filename),
                os.path.join(base_dir, 'audio', filename),
                os.path.join('materials', filename),
                os.path.join('documents', filename),
                os.path.join('images', filename),
                os.path.join('audio', filename)
            ])
            if type_folder:
                candidates.insert(0, os.path.join(base_dir, type_folder, filename))

            found_path = next((p for p in candidates if p and os.path.exists(p)), None)

            if not found_path:
                return jsonify({'error': 'File not found', 'tried': candidates}), 404

            return send_file(
                os.path.abspath(found_path),
                as_attachment=True,
                download_name=material.get('file_name', filename or 'material')
            )
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ==================== RECORDING ROUTES ====================

@app.route('/api/recordings/start', methods=['POST'])
@auth_middleware.api_teacher_required
def start_recording():
    """Start recording a live session"""
    try:
        data = request.get_json()
        session_id = data.get('session_id')
        lecture_id = data.get('lecture_id')
        
        if not session_id or not lecture_id:
            return jsonify({'error': 'Session ID and Lecture ID required'}), 400
        
        if session_id not in active_sessions:
            return jsonify({'error': 'Session not found'}), 404
        
        # Start recording
        recording_id = recording_service.start_recording(
            session_id=session_id,
            lecture_id=lecture_id,
            teacher_id=session['user_id']
        )
        
        if recording_id:
            return jsonify({
                'success': True,
                'recording_id': recording_id,
                'message': 'Recording started successfully'
            }), 200
        else:
            return jsonify({'error': 'Failed to start recording'}), 500
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/recordings/stop', methods=['POST'])
@auth_middleware.api_teacher_required
def stop_recording():
    """Stop recording a live session"""
    try:
        data = request.get_json()
        recording_id = data.get('recording_id')
        
        if not recording_id:
            return jsonify({'error': 'Recording ID required'}), 400
        
        # Stop recording
        success = recording_service.stop_recording(recording_id, session['user_id'])
        
        if success:
            return jsonify({
                'success': True,
                'message': 'Recording stopped successfully'
            }), 200
        else:
            return jsonify({'error': 'Failed to stop recording'}), 500
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/recordings/status/<session_id>', methods=['GET'])
@auth_middleware.api_auth_required
def get_recording_status(session_id):
    """Get recording status for a session"""
    try:
        status = recording_service.get_recording_status(session_id)
        return jsonify({
            'success': True,
            'recording_status': status
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/lectures/<lecture_id>/recordings', methods=['GET'])
@auth_middleware.api_auth_required
def get_lecture_recordings(lecture_id):
    """Get all recordings for a lecture"""
    try:
        user_type = session.get('user_type')
        user_id = session.get('user_id')
        
        # Check access permissions
        if user_type == 'student':
            # Check if student has access to this lecture
            student_cohorts = db.get_student_cohorts(user_id)
            lecture = db.get_lecture_by_id(lecture_id)
            if not lecture or lecture['cohort_id'] not in [c['id'] for c in student_cohorts]:
                return jsonify({'error': 'Access denied'}), 403
        elif user_type == 'teacher':
            # Check if teacher teaches this lecture
            lecture = db.get_lecture_by_id(lecture_id)
            if not lecture or lecture['teacher_id'] != user_id:
                return jsonify({'error': 'Access denied'}), 403
        
        recordings = recording_service.get_lecture_recordings(lecture_id)
        
        return jsonify({
            'success': True,
            'recordings': recordings
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/recordings/<recording_id>', methods=['GET'])
@auth_middleware.api_auth_required
def get_recording(recording_id):
    """Get recording details and download link"""
    try:
        recording = recording_service.get_recording(recording_id)
        if not recording:
            return jsonify({'error': 'Recording not found'}), 404
        
        # Check access permissions
        user_type = session.get('user_type')
        user_id = session.get('user_id')
        
        if user_type == 'student':
            # Check if student has access to this recording
            student_cohorts = db.get_student_cohorts(user_id)
            lecture = db.get_lecture_by_id(recording['lecture_id'])
            if not lecture or lecture['cohort_id'] not in [c['id'] for c in student_cohorts]:
                return jsonify({'error': 'Access denied'}), 403
        elif user_type == 'teacher':
            # Check if teacher owns this recording
            if recording['teacher_id'] != user_id:
                return jsonify({'error': 'Access denied'}), 403
        
        return jsonify({
            'success': True,
            'recording': recording
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/recordings/<recording_id>', methods=['DELETE'])
@auth_middleware.api_teacher_required
def delete_recording(recording_id):
    """Delete a recording"""
    try:
        recording = recording_service.get_recording(recording_id)
        if not recording:
            return jsonify({'error': 'Recording not found'}), 404
        
        # Check if teacher owns this recording
        if recording['teacher_id'] != session['user_id']:
            return jsonify({'error': 'Access denied'}), 403
        
        success = recording_service.delete_recording(recording_id)
        
        if success:
            return jsonify({
                'success': True,
                'message': 'Recording deleted successfully'
            }), 200
        else:
            return jsonify({'error': 'Failed to delete recording'}), 500
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/recordings/cleanup', methods=['POST'])
@auth_middleware.api_auth_required
def cleanup_recordings():
    """Clean up old recordings (admin only)"""
    try:
        if session.get('user_type') not in ['admin', 'super_admin', 'institution_admin']:
            return jsonify({'error': 'Admin access required'}), 403
        
        cleaned_count = recording_service.cleanup_old_recordings()
        
        return jsonify({
            'success': True,
            'message': f'Cleaned up {cleaned_count} old recordings'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ==================== SOCKET.IO EVENTS ====================

if socketio:
    @socketio.on('connect')
    def handle_connect():
        """Handle client connection"""
        print(f'Client connected: {request.sid}')
        # Initialize per-socket heartbeat metadata
        session['last_heartbeat'] = datetime.now().isoformat()
    
    @socketio.on('disconnect')
    def handle_disconnect():
        """Handle client disconnection"""
        print(f'Client disconnected: {request.sid}')

    @socketio.on('heartbeat')
    def handle_heartbeat(data):
        """Client heartbeat to measure RTT and keep session active.
        Expects: { session_id, sent_at }
        Returns ACK: { status, server_time, rtt_ms }
        """
        try:
            sent_at = data.get('sent_at')
            session_id = data.get('session_id')
            # Basic validation
            if not session_id:
                return {'status': 'error', 'message': 'session_id required'}
            # Track last heartbeat for uptime metrics
            session['last_heartbeat'] = datetime.now().isoformat()
            # Compute RTT if client provided sent_at
            rtt_ms = None
            if sent_at:
                try:
                    client_time = datetime.fromisoformat(sent_at)
                    rtt_ms = int((datetime.now() - client_time).total_seconds() * 1000)
                except Exception:
                    rtt_ms = None
            # Optionally accumulate RTT samples in active_sessions for health analytics
            if session_id in active_sessions:
                metrics = active_sessions[session_id].setdefault('metrics', {})
                rtts = metrics.setdefault('rtt_samples', [])
                if rtt_ms is not None:
                    rtts.append(rtt_ms)
                    if len(rtts) > 50:  # cap list size
                        metrics['rtt_samples'] = rtts[-50:]
                metrics['last_heartbeat'] = session['last_heartbeat']
            return {
                'status': 'ok',
                'server_time': datetime.now().isoformat(),
                'rtt_ms': rtt_ms
            }
        except Exception as e:
            return {'status': 'error', 'message': str(e)}
    
    @socketio.on('join_session')
    def handle_join_session(data):
        """Handle joining a live session"""
        session_id = data.get('session_id')
        user_id = session.get('user_id')
        user_type = session.get('user_type')
        
        print(f"[JOIN_SESSION] Received request: session_id={session_id}, user_id={user_id}, user_type={user_type}")
        print(f"[JOIN_SESSION] active_sessions object ID: {id(active_sessions)}")
        print(f"[JOIN_SESSION] Active sessions: {list(active_sessions.keys())}")
        
        if not session_id or not user_id:
            error_msg = f"Invalid session or user: session_id={session_id}, user_id={user_id}"
            print(f"[JOIN_SESSION] ERROR: {error_msg}")
            # Also return ACK-style error for callers expecting a callback
            emit('error', {'message': error_msg})
            return {'status': 'error', 'message': error_msg}
        
        if session_id not in active_sessions:
            error_msg = f"Session not found: {session_id}. Active: {list(active_sessions.keys())}"
            print(f"[JOIN_SESSION] ERROR: {error_msg}")
            emit('error', {'message': 'Session not found', 'session_id': session_id, 'active_sessions': list(active_sessions.keys())})
            return {'status': 'error', 'message': 'Session not found', 'session_id': session_id}
        
        print(f"[JOIN_SESSION] User {user_id} joining session room: {session_id}")
        # Join the session room
        join_room(session_id)
        
        # Add to session participants
        if session_id not in session_participants:
            session_participants[session_id] = []
        
        # Resolve user_name if missing/placeholder
        resolved_name = session.get('user_name')
        if not resolved_name or resolved_name in ['Unknown', '', None]:
            try:
                if user_type == 'teacher':
                    teacher = db.get_teacher_by_id(user_id)
                    if teacher and teacher.get('name'):
                        resolved_name = teacher.get('name')
                elif user_type == 'student':
                    student = db.get_student_by_id(user_id)
                    if student and student.get('name'):
                        resolved_name = student.get('name')
                elif user_type == 'institution_admin':
                    admin = db.get_institution_admin_by_id(user_id)
                    if admin and admin.get('name'):
                        resolved_name = admin.get('name')
                # Persist back
                if resolved_name:
                    session['user_name'] = resolved_name
            except Exception as _e:
                # Keep placeholder if lookup fails
                resolved_name = resolved_name or 'User'

        participant = {
            'user_id': user_id,
            'user_type': user_type,
            'user_name': resolved_name or 'User',
            'name': resolved_name or 'User',
            'joined_at': datetime.now().isoformat()
        }
        
        # Check if participant already exists and remove if so
        session_participants[session_id] = [
            p for p in session_participants[session_id] if p['user_id'] != user_id
        ]
        session_participants[session_id].append(participant)
        
        # Notify others in the session
        emit('user_joined', {
            **participant,
            'participants_count': len(session_participants[session_id])
        }, room=session_id, include_self=False)
        
        # Send current participants to the new user
        emit('session_participants', session_participants[session_id])

        print(f"[JOIN_SESSION] SUCCESS: User {resolved_name or user_id} joined session {session_id}. Total participants: {len(session_participants[session_id])}")

        # Return ACK payload for reliable clients using callbacks
        return {
            'status': 'ok',
            'session_id': session_id,
            'participants': session_participants[session_id],
            'participant_count': len(session_participants[session_id])
        }

    @socketio.on('leave_session')
    def handle_leave_session(data):
        """Handle leaving a live session"""
        session_id = data.get('session_id')
        user_id = session.get('user_id')
        user_name = session.get('user_name', 'Unknown')
        
        if session_id and user_id:
            leave_room(session_id)
            
            # Remove from session participants
            if session_id in session_participants:
                session_participants[session_id] = [
                    p for p in session_participants[session_id] 
                    if p['user_id'] != user_id
                ]
            
            # Notify others in the session
            emit('user_left', {
                'user_id': user_id,
                'user_name': user_name,
                'participants_count': len(session_participants.get(session_id, []))
            }, room=session_id, include_self=False)
    
    @socketio.on('session_message')
    def handle_session_message(data):
        """Handle messages in live session"""
        session_id = data.get('session_id')
        message = data.get('message')
        user_id = session.get('user_id')
        user_name = session.get('user_name', 'Unknown')
        
        if not session_id or not message or not user_id:
            emit('error', {'message': 'Invalid message data'})
            return
        
        if session_id not in active_sessions:
            emit('error', {'message': 'Session not found'})
            return
        
        # Broadcast message to all participants in the session
        message_data = {
            'user_id': user_id,
            'user_name': user_name,
            'message': message,
            'timestamp': datetime.now().isoformat()
        }
        
        emit('session_message', message_data, room=session_id, include_self=False)
    
    @socketio.on('chat_message')
    def handle_chat_message(data):
        """Handle chat messages in live session"""
        session_id = data.get('session_id')
        message = data.get('message')
        user_id = session.get('user_id')
        user_name = session.get('user_name', 'Unknown')
        
        if not session_id or not message or not user_id:
            emit('error', {'message': 'Invalid message data'})
            return
        
        if session_id not in active_sessions:
            emit('error', {'message': 'Session not found'})
            return
        
        print(f"Chat message from {user_name} in session {session_id}: {message}")
        
        # Store message in database
        try:
            # Get lecture ID from session
            lecture_id = active_sessions.get(session_id, {}).get('lecture_id')
            if lecture_id:
                # Store in discussion_posts table
                db.create_discussion_post(
                    institution_id=session.get('institution_id'),
                    forum_id=lecture_id,
                    author_id=user_id,
                    author_type=session.get('user_type', 'student'),
                    content=message
                )
                print(f"Chat message stored in database for lecture {lecture_id}")
        except Exception as e:
            print(f"Error storing chat message: {e}")
        
        # Broadcast message to all participants in the session
        message_data = {
            'user_id': user_id,
            'user_name': user_name,
            'message': message,
            'timestamp': datetime.now().isoformat()
        }
        
        emit('chat_message', message_data, room=session_id, include_self=False)
        print(f"Chat message broadcasted to session {session_id}")
    
    @socketio.on('whiteboard_draw')
    def handle_whiteboard_draw(data):
        """Handle whiteboard drawing events"""
        session_id = data.get('session_id')
        user_id = session.get('user_id')
        user_name = session.get('user_name', 'Unknown')
        
        if not session_id or not user_id:
            emit('error', {'message': 'Invalid whiteboard data'})
            return
        
        if session_id not in active_sessions:
            emit('error', {'message': 'Session not found'})
            return
        
        # Broadcast drawing data to all participants
        drawing_data = {
            'user_id': user_id,
            'user_name': user_name,
            'drawing_data': data.get('drawing_data'),
            'timestamp': datetime.now().isoformat()
        }
        
        emit('whiteboard_draw', drawing_data, room=session_id, include_self=False)
        print(f"Whiteboard drawing from {user_name} broadcasted to session {session_id}")
    
    @socketio.on('whiteboard_clear')
    def handle_whiteboard_clear(data):
        """Handle whiteboard clear events"""
        session_id = data.get('session_id')
        user_id = session.get('user_id')
        user_name = session.get('user_name', 'Unknown')
        
        if not session_id or not user_id:
            emit('error', {'message': 'Invalid whiteboard data'})
            return
        
        if session_id not in active_sessions:
            emit('error', {'message': 'Session not found'})
            return
        
        # Broadcast clear event to all participants
        clear_data = {
            'user_id': user_id,
            'user_name': user_name,
            'timestamp': datetime.now().isoformat()
        }
        
        emit('whiteboard_clear', clear_data, room=session_id, include_self=False)
        print(f"Whiteboard cleared by {user_name} in session {session_id}")
    
    @socketio.on('screen_share_started')
    def handle_screen_share_started(data):
        """Handle screen sharing started events"""
        session_id = data.get('session_id')
        user_id = session.get('user_id')
        user_name = session.get('user_name', 'Unknown')
        
        if not session_id or not user_id:
            emit('error', {'message': 'Invalid screen share data'})
            return
        
        if session_id not in active_sessions:
            emit('error', {'message': 'Session not found'})
            return
        
        # Broadcast screen share event to all participants
        share_data = {
            'user_id': user_id,
            'user_name': user_name,
            'timestamp': datetime.now().isoformat()
        }
        
        emit('screen_share_started', share_data, room=session_id, include_self=False)
        print(f"Screen share started by {user_name} in session {session_id}")
    
    @socketio.on('screen_share_stopped')
    def handle_screen_share_stopped(data):
        """Handle screen sharing stopped events"""
        session_id = data.get('session_id')
        user_id = session.get('user_id')
        user_name = session.get('user_name', 'Unknown')
        
        if not session_id or not user_id:
            emit('error', {'message': 'Invalid screen share data'})
            return
        
        if session_id not in active_sessions:
            emit('error', {'message': 'Session not found'})
            return
        
        # Broadcast screen share stopped event to all participants
        share_data = {
            'user_id': user_id,
            'user_name': user_name,
            'timestamp': datetime.now().isoformat()
        }
        
        emit('screen_share_stopped', share_data, room=session_id, include_self=False)
        print(f"Screen share stopped by {user_name} in session {session_id}")
    
    # WebRTC signaling events
    @socketio.on('webrtc_offer')
    def handle_webrtc_offer(data):
        """Relay WebRTC offer from one peer to another"""
        session_id = data.get('session_id')
        target_user_id = data.get('target_user_id')
        offer = data.get('offer')
        sender_id = session.get('user_id')
        sender_name = session.get('user_name', 'Unknown')
        
        if not session_id or not offer:
            print(f"WebRTC offer missing session_id or offer data")
            emit('error', {'message': 'Invalid WebRTC offer data'})
            return
        
        if session_id not in active_sessions:
            print(f"WebRTC offer: session {session_id} not found in active_sessions")
            emit('error', {'message': 'Session not found'})
            return
        
        print(f"[WEBRTC_OFFER] From {sender_name} (user_id: {sender_id}) in session {session_id}")
        
        # Relay offer to target user or broadcast to all in session
        relay_data = {
            'session_id': session_id,
            'from_user_id': sender_id,  # Use from_user_id to match template expectations
            'user_name': sender_name,
            'offer': offer,
            'timestamp': datetime.now().isoformat()
        }
        
        if target_user_id:
            # Direct offer to specific user
            relay_data['target_user_id'] = target_user_id
            emit('webrtc_offer', relay_data, room=session_id, include_self=False)
            print(f"[WEBRTC_OFFER] Relayed to target user {target_user_id} in session {session_id}")
        else:
            # Broadcast to all participants in the session
            emit('webrtc_offer', relay_data, room=session_id, include_self=False)
            print(f"[WEBRTC_OFFER] Broadcasted to session {session_id}")
    
    @socketio.on('webrtc_answer')
    def handle_webrtc_answer(data):
        """Relay WebRTC answer from one peer to another"""
        session_id = data.get('session_id')
        target_user_id = data.get('target_user_id')
        answer = data.get('answer')
        sender_id = session.get('user_id')
        sender_name = session.get('user_name', 'Unknown')
        
        if not session_id or not answer:
            print(f"WebRTC answer missing session_id or answer data")
            emit('error', {'message': 'Invalid WebRTC answer data'})
            return
        
        if session_id not in active_sessions:
            print(f"WebRTC answer: session {session_id} not found in active_sessions")
            emit('error', {'message': 'Session not found'})
            return
        
        print(f"[WEBRTC_ANSWER] From {sender_name} (user_id: {sender_id}) in session {session_id}")
        
        # Relay answer to target user or broadcast to all in session
        relay_data = {
            'session_id': session_id,
            'from_user_id': sender_id,  # Use from_user_id to match template expectations
            'user_name': sender_name,
            'answer': answer,
            'timestamp': datetime.now().isoformat()
        }
        
        if target_user_id:
            relay_data['target_user_id'] = target_user_id
            emit('webrtc_answer', relay_data, room=session_id, include_self=False)
            print(f"[WEBRTC_ANSWER] Relayed to target user {target_user_id} in session {session_id}")
        else:
            emit('webrtc_answer', relay_data, room=session_id, include_self=False)
            print(f"[WEBRTC_ANSWER] Broadcasted to session {session_id}")
    
    @socketio.on('webrtc_ice_candidate')
    def handle_webrtc_ice_candidate(data):
        """Relay ICE candidate from one peer to another"""
        session_id = data.get('session_id')
        target_user_id = data.get('target_user_id')
        candidate = data.get('candidate')
        sender_id = session.get('user_id')
        sender_name = session.get('user_name', 'Unknown')
        
        if not session_id or not candidate:
            print(f"WebRTC ICE candidate missing session_id or candidate data")
            emit('error', {'message': 'Invalid ICE candidate data'})
            return
        
        if session_id not in active_sessions:
            print(f"WebRTC ICE candidate: session {session_id} not found in active_sessions")
            emit('error', {'message': 'Session not found'})
            return
        
        print(f"[WEBRTC_ICE] From {sender_name} (user_id: {sender_id}) in session {session_id}")
        
        # Relay ICE candidate to target user or broadcast to all in session
        relay_data = {
            'session_id': session_id,
            'from_user_id': sender_id,  # Use from_user_id to match template expectations
            'user_name': sender_name,
            'candidate': candidate,
            'timestamp': datetime.now().isoformat()
        }
        
        if target_user_id:
            relay_data['target_user_id'] = target_user_id
            emit('ice_candidate', relay_data, room=session_id, include_self=False)
            print(f"[WEBRTC_ICE] Relayed to target user {target_user_id} in session {session_id}")
        else:
            emit('ice_candidate', relay_data, room=session_id, include_self=False)
            print(f"[WEBRTC_ICE] Broadcasted to session {session_id}")
    
    # Forum chat events
    @socketio.on('join_forum')
    def handle_join_forum(data):
        """Handle joining a discussion forum"""
        forum_id = data.get('forum_id')
        user_id = session.get('user_id')
        user_name = session.get('user_name', 'Unknown')
        user_type = session.get('user_type', 'student')
        
        if not forum_id or not user_id:
            return
        
        # Join the forum room
        join_room(f"forum_{forum_id}")
        
        # Add user to online users for this forum
        if forum_id not in online_users:
            online_users[forum_id] = {}
        
        # If session did not have a name, try to resolve it from DB
        if not user_name or user_name in ['Unknown', '']:
            try:
                if user_type == 'teacher':
                    teacher = db.get_teacher_by_id(user_id)
                    if teacher and teacher.get('name'):
                        user_name = teacher.get('name')
                else:
                    student = db.get_student_by_id(user_id)
                    if student and student.get('name'):
                        user_name = student.get('name')
                # persist back to session for future events
                session['user_name'] = user_name
            except Exception:
                # leave user_name as-is if lookup fails
                pass

        online_users[forum_id][user_id] = {
            'id': user_id,
            'name': user_name,
            'type': user_type
        }
        
        # Notify others in the forum
        emit('user_joined_forum', {
            'user': {
                'id': user_id,
                'name': user_name,
                'type': user_type
            }
        }, room=f"forum_{forum_id}", include_self=False)
        
        # Send current online users to the new user
        emit('forum_users', list(online_users[forum_id].values()), room=f"forum_{forum_id}")
        print(f"User {user_name} joined forum {forum_id}")
    
    @socketio.on('leave_forum')
    def handle_leave_forum(data):
        """Handle leaving a discussion forum"""
        forum_id = data.get('forum_id')
        user_id = session.get('user_id')
        user_name = session.get('user_name', 'Unknown')
        
        if not forum_id or not user_id:
            return
        
        # Leave the forum room
        leave_room(f"forum_{forum_id}")
        
        # Remove user from online users
        if forum_id in online_users and user_id in online_users[forum_id]:
            del online_users[forum_id][user_id]
            
            # Notify others in the forum
            emit('user_left_forum', {
                'user_id': user_id,
                'user_name': user_name
            }, room=f"forum_{forum_id}", include_self=False)
        
        print(f"User {user_name} left forum {forum_id}")
    
    @socketio.on('forum_message')
    def handle_forum_message(data):
        """Handle messages in discussion forum"""
        forum_id = data.get('forum_id')
        message = data.get('message')
        attachment = data.get('attachment')
        user_id = session.get('user_id')
        user_name = session.get('user_name', 'Unknown')
        user_type = session.get('user_type', 'student')

        if not forum_id or (not message and not attachment) or not user_id:
            return

        try:
            # Use ChatService to save messages
            from services.chat_service import ChatService
            chat_service = ChatService()

            # If attachment is present, ensure it has url and name
            saved_attachment = None
            if attachment and isinstance(attachment, dict) and attachment.get('url'):
                saved_attachment = attachment

            saved = chat_service.save_message(
                institution_id=session.get('institution_id') or None,
                forum_id=forum_id,
                user_id=user_id,
                user_name=user_name,
                user_type=user_type,
                message=message or '',
                attachment=saved_attachment
            )

            timestamp = saved.get('created_at') if saved else datetime.now().isoformat()

            # Broadcast message to all users in the forum
            emit('forum_message', {
                'message': message,
                'user_id': user_id,
                'user_name': user_name,
                'user_type': user_type,
                'attachment': saved_attachment,
                'timestamp': timestamp
            }, room=f"forum_{forum_id}")
            print(f"Forum message from {user_name} broadcasted to forum {forum_id}")

        except Exception as e:
            print(f"Error handling forum message: {e}")
    def handle_session_control(data):
        """Handle session control commands (teacher only)"""
        session_id = data.get('session_id')
        command = data.get('command')
        user_id = session.get('user_id')
        user_type = session.get('user_type')
        
        if user_type != 'teacher':
            emit('error', {'message': 'Only teachers can control sessions'})
            return
        
        if session_id not in active_sessions:
            emit('error', {'message': 'Session not found'})
            return
        
        session_info = active_sessions[session_id]
        if session_info['teacher_id'] != user_id:
            emit('error', {'message': 'Access denied'})
            return
        
        # Broadcast control command to all participants
        control_data = {
            'command': command,
            'timestamp': datetime.now().isoformat()
        }
        
        emit('session_control', control_data, room=session_id, include_self=False)

# ==================== ERROR HANDLERS ====================

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    if request.path.startswith('/api/'):
        return jsonify({'error': 'API endpoint not found'}), 404
    return render_template('404.html'), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    if request.path.startswith('/api/'):
        return jsonify({'error': 'Internal server error'}), 500
    return render_template('500.html'), 500

@app.errorhandler(403)
def forbidden(error):
    """Handle 403 errors"""
    if request.path.startswith('/api/'):
        return jsonify({'error': 'Access forbidden'}), 403
    return render_template('403.html'), 403

# ==================== HEALTH CHECK ====================

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    try:
        # Check database connection
        db_status = "connected" if db.supabase else "disconnected"
        
        # Check services
        services_status = {
            'database': db_status,
            'email_service': "active" if email_service else "inactive",
            'cohort_service': "active" if cohort_service else "inactive",
            'lecture_service': "active" if lecture_service else "inactive",
            'quiz_service': "active" if quiz_service else "inactive",
            'recording_service': "active" if recording_service else "inactive"
        }
        
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'services': services_status,
            'active_sessions': len(active_sessions),
            'online_users': len(online_users)
        }), 200
        
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/api/session_health/<session_id>', methods=['GET'])
def session_health_check(session_id):
    """Session health check endpoint"""
    try:
        if session_id not in active_sessions:
            return jsonify({
                'success': False,
                'status': 'not_found',
                'message': 'Session not found'
            }), 404
        
        session_info = active_sessions[session_id]
        participants = session_participants.get(session_id, [])
        
        # Compute uptime
        started_at_iso = session_info.get('started_at')
        uptime_seconds = None
        if started_at_iso:
            try:
                started_dt = datetime.fromisoformat(started_at_iso)
                uptime_seconds = int((datetime.now() - started_dt).total_seconds())
            except Exception:
                uptime_seconds = None
        # Derive average RTT if samples exist
        metrics = session_info.get('metrics', {})
        rtts = metrics.get('rtt_samples', [])
        avg_rtt_ms = int(sum(rtts) / len(rtts)) if rtts else None
        last_heartbeat = metrics.get('last_heartbeat')
        return jsonify({
            'success': True,
            'status': 'active',
            'session_id': session_id,
            'lecture_id': session_info.get('lecture_id'),
            'started_at': started_at_iso,
            'uptime_seconds': uptime_seconds,
            'participants_count': len(participants),
            'participants': participants,
            'recording_status': session_info.get('recording_status'),
            'quality_reports': session_info.get('quality_reports', []),
            'avg_rtt_ms': avg_rtt_ms,
            'last_heartbeat': last_heartbeat,
            'timestamp': datetime.now().isoformat()
        }), 200
        
    except Exception as e:
        return jsonify({
            'success': False,
            'status': 'error',
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

@app.route('/api/session/by_lecture/<lecture_id>', methods=['GET'])
def get_session_by_lecture(lecture_id):
    """Get active session_id for a lecture"""
    try:
        session_id = f"session_{lecture_id}"
        
        if session_id in active_sessions:
            session_info = active_sessions[session_id]
            return jsonify({
                'success': True,
                'session_id': session_id,
                'lecture_id': lecture_id,
                'active': True,
                'started_at': session_info.get('started_at'),
                'teacher_id': session_info.get('teacher_id'),
                'participants_count': len(session_participants.get(session_id, [])),
                'timestamp': datetime.now().isoformat()
            }), 200
        else:
            return jsonify({
                'success': False,
                'session_id': session_id,
                'lecture_id': lecture_id,
                'active': False,
                'message': 'No active session for this lecture',
                'timestamp': datetime.now().isoformat()
            }), 404
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500

# ==================== ERROR HANDLERS ====================

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    if request.path.startswith('/api/'):
        return jsonify({'error': 'Endpoint not found'}), 404
    return render_template('404.html'), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    if request.path.startswith('/api/'):
        return jsonify({'error': 'Internal server error'}), 500
    return render_template('500.html'), 500

# ==================== APPLICATION STARTUP ====================

if __name__ == '__main__':
    print("🚀 Starting Digi Kul Teachers Portal...")
    print("📚 Educational Platform Management System")
    print("🔐 Multi-tenant Architecture with Role-based Access")
    print("=" * 60)
    
    # Print available routes
    print("\n📋 Available Routes:")
    print("🏠 Main Routes:")
    print("  GET  /                           - Landing page")
    print("  GET  /login                      - Main login page")
    print("  GET  /super-admin/login          - Super admin login")
    print("  GET  /institution/<subdomain>/login - Institution-specific login")
    print("  GET  /institution/<subdomain>/register - Student registration")
    print("  GET  /super-admin/dashboard      - Super admin dashboard")
    print("  GET  /institution-admin/dashboard - Institution admin dashboard")
    print("  GET  /teacher/dashboard          - Teacher dashboard")
    print("  GET  /student/dashboard          - Student dashboard")
    # Removed generic admin dashboard - only super admin and institution admin exist
    print("  GET  /register                   - Registration page")
    print("  GET  /logout                     - Logout page")
    
    print("\n🔐 Authentication API:")
    print("  POST /api/auth/login             - User login")
    print("  POST /api/auth/logout            - User logout")
    print("  GET  /api/auth/validate-session  - Validate session")
    
    print("\n👑 Super Admin API:")
    print("  GET  /api/super-admin/institutions - Get institutions")
    print("  POST /api/super-admin/institutions - Create institution")
    print("  GET  /api/super-admin/stats      - Platform statistics")
    
    print("\n🏛️ Institution Admin API:")
    print("  GET  /api/institution-admin/teachers - Get teachers")
    print("  POST /api/institution-admin/teachers - Create teacher")
    print("  GET  /api/institution-admin/students - Get students")
    print("  POST /api/institution-admin/students - Create student")
    
    print("\n👨‍🏫 Teacher API:")
    print("  GET  /api/teacher/lectures       - Get lectures")
    print("  POST /api/teacher/lectures       - Create lecture")
    print("  GET  /api/teacher/cohorts        - Get cohorts")
    print("  GET  /api/teacher/materials      - Get materials")
    
    print("\n👨‍🎓 Student API:")
    print("  GET  /api/student/cohorts        - Get enrolled cohorts")
    print("  POST /api/student/enroll         - Enroll in cohort")
    print("  GET  /api/student/lectures       - Get lectures")
    print("  GET  /api/student/materials      - Get materials")
    print("  GET  /api/student/quizzes        - Get quizzes")
    
    print("\n📚 Course Management API:")
    print("  GET  /api/cohorts                - Get cohorts")
    print("  POST /api/cohorts                - Create cohort")
    print("  GET  /api/lectures               - Get lectures")
    print("  POST /api/lectures               - Create lecture")
    print("  GET  /api/quiz/quiz-sets         - Get quiz sets")
    print("  POST /api/quiz/quiz-sets         - Create quiz set")
    
    print("\n📁 File Management:")
    print("  GET  /api/download/<material_id> - Download material")
    print("  POST /api/recordings/start       - Start recording")
    print("  POST /api/recordings/stop        - Stop recording")
    
    print("\n🏥 System:")
    print("  GET  /api/health                 - Health check")
    
    print("=" * 60)
    print("🌐 Server starting on http://localhost:5000")
    print("📖 Documentation: Check route comments for details")
    print("🔧 Debug mode: ON")
    print("=" * 60)
    
    if socketio:
        socketio.run(app, debug=True, host='0.0.0.0', port=5000)
    else:
        app.run(debug=True, host='0.0.0.0', port=5000)
        