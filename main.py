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
        
        # Get file path
        file_path = material.get('file_path')
        if not file_path or not os.path.exists(file_path):
            return jsonify({'error': 'File not found'}), 404
        
        # Send file
        return send_file(file_path, as_attachment=True, download_name=material['file_name'])
        
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
    
    @socketio.on('disconnect')
    def handle_disconnect():
        """Handle client disconnection"""
        print(f'Client disconnected: {request.sid}')
    
    @socketio.on('join_session')
    def handle_join_session(data):
        """Handle joining a live session"""
        session_id = data.get('session_id')
        user_id = session.get('user_id')
        user_type = session.get('user_type')
        
        if not session_id or not user_id:
            emit('error', {'message': 'Invalid session or user'})
            return
        
        if session_id not in active_sessions:
            emit('error', {'message': 'Session not found'})
            return
        
        # Join the session room
        join_room(session_id)
        
        # Add to session participants
        if session_id not in session_participants:
            session_participants[session_id] = []
        
        participant = {
            'user_id': user_id,
            'user_type': user_type,
            'name': session.get('user_name', 'Unknown'),
            'joined_at': datetime.now().isoformat()
        }
        
        if participant not in session_participants[session_id]:
            session_participants[session_id].append(participant)
        
        # Notify others in the session
        emit('user_joined', participant, room=session_id, include_self=False)
        
        # Send current participants to the new user
        emit('session_participants', session_participants[session_id])

    @socketio.on('leave_session')
    def handle_leave_session(data):
        """Handle leaving a live session"""
        session_id = data.get('session_id')
        user_id = session.get('user_id')
        
        if session_id and user_id:
            leave_room(session_id)
            
            # Remove from session participants
            if session_id in session_participants:
                session_participants[session_id] = [
                    p for p in session_participants[session_id] 
                    if p['user_id'] != user_id
                ]
            
            # Notify others in the session
            emit('user_left', {'user_id': user_id}, room=session_id, include_self=False)
    
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
        
        # Broadcast message to all participants in the session
        message_data = {
            'user_id': user_id,
            'user_name': user_name,
            'message': message,
            'timestamp': datetime.now().isoformat()
        }
        
        emit('chat_message', message_data, room=session_id, include_self=False)
    
    @socketio.on('session_control')
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
        