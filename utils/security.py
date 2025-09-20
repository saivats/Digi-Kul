"""
Security utilities for the Digi Kul Teachers Portal
Provides comprehensive security measures for authentication, session management, and logout
"""

import os
import hashlib
import secrets
from datetime import datetime, timedelta
from functools import wraps
from flask import request, session, jsonify, redirect, url_for, flash, make_response
from werkzeug.security import generate_password_hash, check_password_hash

class SecurityManager:
    """Comprehensive security management for the application"""
    
    def __init__(self, app=None):
        self.app = app
        self.session_timeout = timedelta(hours=8)
        self.max_login_attempts = 5
        self.lockout_duration = timedelta(minutes=15)
        self.login_attempts = {}
        
        if app:
            self.init_app(app)
    
    def init_app(self, app):
        """Initialize security with Flask app"""
        self.app = app
        
        # Enhanced session configuration
        app.config.update({
            'SESSION_COOKIE_SECURE': True,
            'SESSION_COOKIE_HTTPONLY': True,
            'SESSION_COOKIE_SAMESITE': 'Lax',
            'SESSION_COOKIE_NAME': 'digi_kul_secure_session',
            'PERMANENT_SESSION_LIFETIME': self.session_timeout,
            'WTF_CSRF_ENABLED': True,
            'WTF_CSRF_TIME_LIMIT': 3600
        })
    
    def generate_session_token(self, user_id, user_type):
        """Generate a secure session token"""
        timestamp = datetime.now().isoformat()
        random_data = secrets.token_hex(32)
        data = f"{user_id}:{user_type}:{timestamp}:{random_data}"
        return hashlib.sha256(data.encode()).hexdigest()
    
    def validate_session_token(self, token, user_id):
        """Validate session token"""
        # In a production environment, you would store and validate tokens
        # For now, we'll use the session-based approach
        return True
    
    def secure_logout(self, user_id=None, online_users=None):
        """Perform secure logout with complete session destruction"""
        try:
            # Remove from online users tracking
            if user_id and online_users and user_id in online_users:
                del online_users[user_id]
            
            # Clear all session data
            session.clear()
            session.permanent = False
            
            # Create secure response
            response = make_response()
            
            # Set session cookie to expire immediately
            response.set_cookie(
                self.app.config['SESSION_COOKIE_NAME'], 
                '', 
                expires=0,
                secure=self.app.config['SESSION_COOKIE_SECURE'],
                httponly=self.app.config['SESSION_COOKIE_HTTPONLY'],
                samesite=self.app.config['SESSION_COOKIE_SAMESITE']
            )
            
            # Security headers
            response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate, private'
            response.headers['Pragma'] = 'no-cache'
            response.headers['Expires'] = '0'
            response.headers['X-Content-Type-Options'] = 'nosniff'
            response.headers['X-Frame-Options'] = 'DENY'
            response.headers['X-XSS-Protection'] = '1; mode=block'
            
            return response
            
        except Exception as e:
            # Even if there's an error, clear the session
            session.clear()
            return make_response()
    
    def check_login_attempts(self, ip_address):
        """Check if IP has exceeded login attempts"""
        if ip_address in self.login_attempts:
            attempts, last_attempt = self.login_attempts[ip_address]
            if attempts >= self.max_login_attempts:
                if datetime.now() - last_attempt < self.lockout_duration:
                    return False
                else:
                    # Reset attempts after lockout period
                    del self.login_attempts[ip_address]
        return True
    
    def record_login_attempt(self, ip_address, success=False):
        """Record login attempt"""
        if success:
            # Clear attempts on successful login
            if ip_address in self.login_attempts:
                del self.login_attempts[ip_address]
        else:
            # Increment failed attempts
            if ip_address in self.login_attempts:
                self.login_attempts[ip_address] = (
                    self.login_attempts[ip_address][0] + 1,
                    datetime.now()
                )
            else:
                self.login_attempts[ip_address] = (1, datetime.now())
    
    def get_client_ip(self):
        """Get client IP address"""
        if request.headers.get('X-Forwarded-For'):
            return request.headers.get('X-Forwarded-For').split(',')[0].strip()
        return request.remote_addr

def secure_required(f):
    """Enhanced authentication decorator with security checks"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        # Check if session exists and is valid
        if 'user_id' not in session or not session.get('user_id'):
            session.clear()
            if request.is_json:
                return jsonify({'error': 'Authentication required'}), 401
            flash('Please log in to access this page.', 'error')
            return redirect(url_for('login_page'))
        
        # Additional security checks can be added here
        # For example: IP validation, device fingerprinting, etc.
        
        return f(*args, **kwargs)
    return decorated_function

def prevent_caching(f):
    """Decorator to prevent caching of sensitive pages"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        response = f(*args, **kwargs)
        
        if hasattr(response, 'headers'):
            response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate, private'
            response.headers['Pragma'] = 'no-cache'
            response.headers['Expires'] = '0'
        
        return response
    return decorated_function

def csrf_protect(f):
    """CSRF protection decorator"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if request.method == "POST":
            token = request.form.get('csrf_token')
            if not token or not session.get('csrf_token'):
                if request.is_json:
                    return jsonify({'error': 'CSRF token missing'}), 403
                flash('Security error. Please try again.', 'error')
                return redirect(request.url)
            
            if token != session.get('csrf_token'):
                if request.is_json:
                    return jsonify({'error': 'Invalid CSRF token'}), 403
                flash('Security error. Please try again.', 'error')
                return redirect(request.url)
        
        return f(*args, **kwargs)
    return decorated_function

def generate_csrf_token():
    """Generate CSRF token"""
    if 'csrf_token' not in session:
        session['csrf_token'] = secrets.token_hex(32)
    return session['csrf_token']

def validate_session_security(user_id, online_users):
    """Validate session security"""
    if not user_id or user_id not in online_users:
        session.clear()
        return False
    return True

def create_secure_response(data=None, status_code=200):
    """Create response with security headers"""
    if data is None:
        response = make_response()
    else:
        response = make_response(jsonify(data), status_code)
    
    # Security headers
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate, private'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
    response.headers['X-Content-Type-Options'] = 'nosniff'
    response.headers['X-Frame-Options'] = 'DENY'
    response.headers['X-XSS-Protection'] = '1; mode=block'
    response.headers['Referrer-Policy'] = 'strict-origin-when-cross-origin'
    
    return response

# Security constants
SECURITY_HEADERS = {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains'
}

CACHE_PREVENTION_HEADERS = {
    'Cache-Control': 'no-cache, no-store, must-revalidate, private',
    'Pragma': 'no-cache',
    'Expires': '0'
}
