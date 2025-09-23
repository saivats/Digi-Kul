"""
Main Application Entry Point
This is the new entry point for the Digi Kul Teachers Portal application.
"""

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
from utils.database_supabase import DatabaseManager
from utils.compression import compress_audio, compress_image, compress_pdf, get_file_type

# Import new modular components
from middlewares.auth_middleware import AuthMiddleware
from middlewares.cohort_middleware import CohortMiddleware
from services.cohort_service import CohortService
from services.lecture_service import LectureService
from services.quiz_service import QuizService
# from services.admin_service import AdminService  # TODO: Create admin service
from services.session_recording_service import SessionRecordingService
from utils.email_service import EmailService

# Import route blueprints
from routes.auth_routes import auth_bp
from routes.cohort_routes import cohort_bp
from routes.lecture_routes import lecture_bp
from routes.quiz_routes import quiz_bp
# from routes.admin_routes import admin_bp  # TODO: Create admin routes

# Initialize the database
db = DatabaseManager()
email_service = EmailService()

# Initialize services
cohort_service = CohortService(db, email_service)
lecture_service = LectureService(db, email_service)
quiz_service = QuizService(db, email_service)
# admin_service = AdminService(db, email_service)  # TODO: Create admin service
recording_service = SessionRecordingService(db)

# Initialize middleware
auth_middleware = AuthMiddleware(None, db)
cohort_middleware = CohortMiddleware(None, db)

app = Flask(__name__)
app.config.from_object(Config)

# Enhanced session security configuration
app.secret_key = os.environ.get('SECRET_KEY', 'your-secret-key-change-this')
app.permanent_session_lifetime = timedelta(hours=8)
app.config['SESSION_COOKIE_SECURE'] = True
app.config['SESSION_COOKIE_HTTPONLY'] = True
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'
app.config['SESSION_COOKIE_NAME'] = 'digi_kul_session'
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(hours=8)

# Additional security headers
@app.after_request
def set_security_headers(response):
    """Set security headers for all responses"""
    # Prevent caching of sensitive pages
    if request.endpoint in ['teacher_dashboard', 'student_dashboard', 'admin_dashboard', 'teacher', 'student']:
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

# Register blueprints
app.register_blueprint(auth_bp, url_prefix='/api/auth')
app.register_blueprint(cohort_bp, url_prefix='/api/cohorts')
app.register_blueprint(lecture_bp, url_prefix='/api/lectures')
app.register_blueprint(quiz_bp, url_prefix='/api/quiz')
# app.register_blueprint(admin_bp, url_prefix='/api/admin')  # TODO: Create admin routes

# ==================== BASIC ROUTES ====================

@app.route('/')
def index():
    """Landing page"""
    return render_template('index.html')

@app.route('/login')
def login_page():
    """Login page"""
    return render_template('login.html')

@app.route('/admin_login')
def admin_login_page():
    """Admin-only login page"""
    return render_template('login.html', admin_mode=True)

@app.route('/register')
def register_page():
    """Registration page"""
    return render_template('register.html')

@app.route('/logout', methods=['GET', 'POST'])
def logout_page():
    """Logout page with additional security measures"""
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
        return redirect(url_for('login_page'))

# ==================== DASHBOARD ROUTES ====================

@app.route('/teacher_dashboard')
@auth_middleware.teacher_required
def teacher_dashboard():
    """Teacher dashboard"""
    return render_template('teacher_dashboard.html', 
                         user_name=session.get('user_name'),
                         user_email=session.get('user_email'))

@app.route('/student_dashboard')
@auth_middleware.student_required
def student_dashboard():
    """Student dashboard"""
    return render_template('student_dashboard.html',
                         user_name=session.get('user_name'),
                         user_email=session.get('user_email'))

@app.route('/admin_dashboard')
@auth_middleware.admin_required
def admin_dashboard():
    """Admin dashboard"""
    return render_template('admin_dashboard.html',
                         user_name=session.get('user_name'),
                         user_email=session.get('user_email'))

@app.route('/student/<student_id>')
@auth_middleware.student_required
def student_profile(student_id):
    """Individual student profile page - redirects to dashboard"""
    if session.get('user_id') != student_id:
        flash('Access denied.', 'error')
        return redirect(url_for('student_dashboard'))
    
    # Redirect to student dashboard since individual profile page is not implemented
    flash('Profile page not available. Redirecting to dashboard.', 'info')
    return redirect(url_for('student_dashboard'))

# ==================== LIVE SESSION ROUTES ====================

@app.route('/student/join_session/<session_id>')
@auth_middleware.student_required
def join_session_page(session_id):
    """Join live session page for students"""
    if session_id not in active_sessions:
        flash('Session not found or has ended.', 'error')
        return redirect(url_for('student_dashboard'))
    
    session_info = active_sessions[session_id]
    return render_template('student_live_session.html', lecture_id=session_info['lecture_id'])

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

# ==================== FILE DOWNLOAD ====================

@app.route('/api/download/<material_id>')
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

# ==================== SESSION RECORDING ROUTES ====================

@app.route('/api/recordings/start', methods=['POST'])
@auth_middleware.api_teacher_required
def start_session_recording():
    """Start recording a live session"""
    try:
        data = request.get_json()
        session_id = data.get('session_id')
        lecture_id = data.get('lecture_id')
        recording_type = data.get('recording_type', 'full')
        
        if not session_id or not lecture_id:
            return jsonify({'error': 'Session ID and Lecture ID are required'}), 400
        
        # Verify teacher owns this lecture
        lecture = lecture_service.get_lecture_by_id(lecture_id)
        if not lecture or lecture['teacher_id'] != session['user_id']:
            return jsonify({'error': 'Unauthorized'}), 403
        
        success, message = recording_service.start_recording(
            session_id=session_id,
            lecture_id=lecture_id,
            teacher_id=session['user_id'],
            recording_type=recording_type
        )
        
        if success:
            return jsonify({
                'success': True,
                'message': message,
                'recording_id': message.split(': ')[-1] if ': ' in message else None
            }), 201
        else:
            return jsonify({'error': message}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/recordings/stop', methods=['POST'])
@auth_middleware.api_teacher_required
def stop_session_recording():
    """Stop recording a live session"""
    try:
        data = request.get_json()
        session_id = data.get('session_id')
        
        if not session_id:
            return jsonify({'error': 'Session ID is required'}), 400
        
        success, message = recording_service.stop_recording(session_id)
        
        if success:
            return jsonify({'success': True, 'message': message}), 200
        else:
            return jsonify({'error': message}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/recordings/status/<session_id>', methods=['GET'])
@auth_middleware.api_login_required
def get_recording_status(session_id):
    """Get recording status for a session"""
    try:
        recording_status = recording_service.get_recording_status(session_id)
        
        if recording_status:
            return jsonify({'success': True, 'recording': recording_status}), 200
        else:
            return jsonify({'success': False, 'message': 'No active recording found'}), 404
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/lectures/<lecture_id>/recordings', methods=['GET'])
@auth_middleware.api_login_required
def get_lecture_recordings(lecture_id):
    """Get all recordings for a lecture"""
    try:
        # Check if user has access to this lecture
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
        
        recordings = recording_service.get_session_recordings(lecture_id)
        
        return jsonify({'success': True, 'recordings': recordings}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/recordings/<recording_id>', methods=['GET'])
@auth_middleware.api_login_required
def get_recording_details(recording_id):
    """Get detailed information about a recording"""
    try:
        recording = recording_service.get_recording_details(recording_id)
        
        if not recording:
            return jsonify({'error': 'Recording not found'}), 404
        
        # Check if user has access to this recording
        lecture = lecture_service.get_lecture_by_id(recording['lecture_id'])
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
            if not any(l['id'] == recording['lecture_id'] for l in student_lectures):
                return jsonify({'error': 'Unauthorized'}), 403
        
        return jsonify({'success': True, 'recording': recording}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/recordings/<recording_id>', methods=['DELETE'])
@auth_middleware.api_teacher_required
def delete_recording(recording_id):
    """Delete a recording (teacher only)"""
    try:
        # Get recording details to verify ownership
        recording = recording_service.get_recording_details(recording_id)
        if not recording:
            return jsonify({'error': 'Recording not found'}), 404
        
        # Verify teacher owns the lecture this recording belongs to
        lecture = lecture_service.get_lecture_by_id(recording['lecture_id'])
        if not lecture or lecture['teacher_id'] != session['user_id']:
            return jsonify({'error': 'Unauthorized'}), 403
        
        success, message = recording_service.delete_recording(recording_id)
        
        if success:
            return jsonify({'success': True, 'message': message}), 200
        else:
            return jsonify({'error': message}), 400
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/recordings/cleanup', methods=['POST'])
@auth_middleware.api_admin_required
def cleanup_old_recordings():
    """Clean up old recordings (admin only)"""
    try:
        data = request.get_json()
        days_old = data.get('days_old', 30)
        
        cleaned_count = recording_service.cleanup_old_recordings(days_old)
        
        return jsonify({
            'success': True,
            'message': f'Cleaned up {cleaned_count} old recordings',
            'cleaned_count': cleaned_count
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# ==================== WEBSOCKET EVENTS ====================

if socketio:
    @socketio.on('connect')
    def handle_connect():
        if 'user_id' in session:
            user_type = session.get('user_type')
            join_room(user_type + 's')
            
            emit('connected', {
                'message': f'Connected as {user_type}',
                'user_id': session['user_id']
            })
    
    @socketio.on('disconnect')
    def handle_disconnect():
        if 'user_id' in session:
            user_type = session.get('user_type')
            leave_room(user_type + 's')
    
    @socketio.on('join_session')
    def handle_join_session(data):
        session_id = data.get('session_id')
        
        if 'user_id' not in session:
            emit('error', {'message': 'Authentication required'})
            return
        
        user_id = session['user_id']
        user_type = session['user_type']
        user_name = session['user_name']
        
        if session_id not in active_sessions:
            emit('error', {'message': 'Session not found'})
            return
        
        join_room(session_id)
        
        if session_id not in session_participants:
            session_participants[session_id] = {}
        
        session_participants[session_id][user_id] = {
            'user_type': user_type,
            'user_name': user_name,
            'socket_id': request.sid,
            'joined_at': datetime.now().isoformat()
        }
        
        # Log participant join for recording if active
        if session_id in recording_service.active_recordings:
            recording_service.log_participant_activity(session_id, user_id, user_name, 'join')
        
        emit('user_joined', {
            'user_id': user_id,
            'user_name': user_name,
            'user_type': user_type,
            'participants_count': len(session_participants[session_id])
        }, room=session_id, include_self=False)
        
        emit('session_info', {
            'session_id': session_id,
            'participants': list(session_participants[session_id].values()),
            'participants_count': len(session_participants[session_id])
        })

    @socketio.on('leave_session')
    def handle_leave_session(data):
        session_id = data.get('session_id')
        user_id = data.get('user_id') or (session.get('user_id') if 'user_id' in session else None)
        if not session_id or not user_id:
            return
        leave_room(session_id)
        if session_id in session_participants and user_id in session_participants[session_id]:
            # Log participant leave for recording if active
            if session_id in recording_service.active_recordings:
                user_name = session_participants[session_id][user_id].get('user_name', 'Unknown User')
                recording_service.log_participant_activity(session_id, user_id, user_name, 'leave')
            
            del session_participants[session_id][user_id]
            participants_count = len(session_participants[session_id])
            emit('user_left', {
                'user_id': user_id,
                'participants_count': participants_count
            }, room=session_id)
            
            # If no participants left, end the session
            if participants_count == 0:
                if session_id in active_sessions:
                    active_sessions[session_id]['status'] = 'ended'
                    emit('session_ended', {}, room=session_id)
                    # Clean up after a delay
                    threading.Timer(5.0, lambda: cleanup_session(session_id)).start()

    @socketio.on('webrtc_offer')
    def handle_webrtc_offer(data):
        session_id = data.get('session_id')
        target_user_id = data.get('target_user_id')
        offer = data.get('offer')
        from_user_id = data.get('from_user_id')
        if not session_id or not target_user_id or session_id not in session_participants:
            emit('error', {'message': 'Invalid signaling data'})
            return
        target = session_participants[session_id].get(target_user_id)
        if not target:
            emit('error', {'message': 'Target not found'})
            return
        emit('webrtc_offer', {
            'from_user_id': from_user_id,
            'offer': offer
        }, room=target['socket_id'])

    @socketio.on('webrtc_answer')
    def handle_webrtc_answer(data):
        session_id = data.get('session_id')
        target_user_id = data.get('target_user_id')
        answer = data.get('answer')
        from_user_id = data.get('from_user_id')
        if not session_id or not target_user_id or session_id not in session_participants:
            emit('error', {'message': 'Invalid signaling data'})
            return
        target = session_participants[session_id].get(target_user_id)
        if not target:
            emit('error', {'message': 'Target not found'})
            return
        emit('webrtc_answer', {
            'from_user_id': from_user_id,
            'answer': answer
        }, room=target['socket_id'])

    @socketio.on('ice_candidate')
    def handle_ice_candidate(data):
        session_id = data.get('session_id')
        target_user_id = data.get('target_user_id')
        candidate = data.get('candidate')
        from_user_id = data.get('from_user_id')
        if not session_id or not target_user_id or session_id not in session_participants:
            emit('error', {'message': 'Invalid signaling data'})
            return
        target = session_participants[session_id].get(target_user_id)
        if not target:
            emit('error', {'message': 'Target not found'})
            return
        emit('ice_candidate', {
            'from_user_id': from_user_id,
            'candidate': candidate
        }, room=target['socket_id'])

    @socketio.on('chat_message')
    def handle_chat_message(data):
        session_id = data.get('session_id')
        if not session_id:
            return
        
        # Log chat message for recording if active
        if session_id in recording_service.active_recordings:
            user_id = session.get('user_id', 'anonymous')
            user_name = session.get('user_name', 'Unknown User')
            message = data.get('message', '')
            recording_service.log_chat_message(session_id, user_id, user_name, message)
        
        emit('chat_message', data, room=session_id)

    @socketio.on('quality_report')
    def handle_quality_report(data):
        # In the future, persist or analyze quality reports
        pass

    @socketio.on('recording_chunk')
    def handle_recording_chunk(data):
        """Handle video/audio chunks for recording"""
        session_id = data.get('session_id')
        user_id = session.get('user_id')
        chunk_type = data.get('chunk_type', 'video')
        chunk_data = data.get('chunk_data')
        
        if not session_id or not user_id or not chunk_data:
            return
        
        # Save chunk for recording if active
        if session_id in recording_service.active_recordings:
            # Convert base64 chunk data back to bytes
            import base64
            try:
                chunk_bytes = base64.b64decode(chunk_data)
                recording_service.save_video_chunk(session_id, user_id, chunk_bytes, chunk_type)
            except Exception as e:
                print(f"Failed to save recording chunk: {e}")  # TODO: Add proper logging

    @socketio.on('start_recording')
    def handle_start_recording(data):
        """Start recording via WebSocket"""
        session_id = data.get('session_id')
        lecture_id = data.get('lecture_id')
        recording_type = data.get('recording_type', 'full')
        
        if not session_id or not lecture_id:
            emit('recording_error', {'message': 'Session ID and Lecture ID required'})
            return
        
        # Verify teacher owns this lecture
        lecture = lecture_service.get_lecture_by_id(lecture_id)
        if not lecture or lecture['teacher_id'] != session.get('user_id'):
            emit('recording_error', {'message': 'Unauthorized'})
            return
        
        success, message = recording_service.start_recording(
            session_id=session_id,
            lecture_id=lecture_id,
            teacher_id=session['user_id'],
            recording_type=recording_type
        )
        
        if success:
            emit('recording_started', {
                'session_id': session_id,
                'message': message,
                'recording_id': message.split(': ')[-1] if ': ' in message else None
            }, room=session_id)
        else:
            emit('recording_error', {'message': message})

    @socketio.on('stop_recording')
    def handle_stop_recording(data):
        """Stop recording via WebSocket"""
        session_id = data.get('session_id')
        
        if not session_id:
            emit('recording_error', {'message': 'Session ID required'})
            return
        
        success, message = recording_service.stop_recording(session_id)
        
        if success:
            emit('recording_stopped', {
                'session_id': session_id,
                'message': message
            }, room=session_id)
        else:
            emit('recording_error', {'message': message})

    @socketio.on('get_recording_status')
    def handle_get_recording_status(data):
        """Get recording status via WebSocket"""
        session_id = data.get('session_id')
        
        if not session_id:
            emit('recording_error', {'message': 'Session ID required'})
            return
        
        recording_status = recording_service.get_recording_status(session_id)
        
        if recording_status:
            emit('recording_status', {
                'session_id': session_id,
                'recording': recording_status
            })
        else:
            emit('recording_status', {
                'session_id': session_id,
                'recording': None,
                'message': 'No active recording found'
            })

# ==================== HEALTH CHECK ====================

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'active_sessions': len([s for s in active_sessions.values() if s['status'] == 'active']),
        'online_users': len(online_users)
    }), 200

# ==================== APPLICATION STARTUP ====================

if __name__ == '__main__':
    os.makedirs('templates', exist_ok=True)
    os.makedirs('static', exist_ok=True)
    
    if socketio:
        socketio.run(app, debug=True, host='0.0.0.0', port=5000)
    else:
        app.run(debug=True, host='0.0.0.0', port=5000)
