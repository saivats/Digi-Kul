"""
Authentication Middleware
Handles user authentication, session management, and access control.
"""

from functools import wraps
from flask import request, session, redirect, url_for, flash, jsonify
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from utils.database_supabase import SupabaseDatabaseManager as DatabaseManager

# Module-level decorators for convenience (allow importing directly)
def login_required(f):
    """Decorator to require login for routes (works for web and API endpoints)."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session or not session.get('user_id'):
            # If it's an API request, return JSON
            if request.is_json or request.path.startswith('/api/'):
                return jsonify({'error': 'Please log in to access this API'}), 401
            session.clear()
            flash('Please log in to access this page.', 'error')
            return redirect(url_for('login_page'))

        return f(*args, **kwargs)
    return decorated_function

def api_login_required(f):
    """Decorator specifically for API routes that require login."""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'user_id' not in session or not session.get('user_id'):
            return jsonify({'error': 'Please log in to access this API'}), 401
        return f(*args, **kwargs)
    return decorated_function

class AuthMiddleware:
    def __init__(self, app, db: DatabaseManager):
        """Initialize authentication middleware"""
        self.app = app
        self.db = db
        self.online_users = {}
        
        # Register middleware with Flask app
        self._register_middleware()
    
    def _register_middleware(self):
        """Register middleware functions with Flask app"""
        pass  # Middleware functions will be used as decorators
    
    def login_required(self, f):
        """Decorator to require login for routes"""
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Check if session exists and is valid
            if 'user_id' not in session or not session.get('user_id'):
                session.clear()
                flash('Please log in to access this page.', 'error')
                return redirect(url_for('login_page'))
            
            # Additional security: Check if user is still in online_users (session validation)
            user_id = session.get('user_id')
            if user_id not in self.online_users:
                session.clear()
                flash('Session expired. Please log in again.', 'error')
                return redirect(url_for('login_page'))
            
            return f(*args, **kwargs)
        return decorated_function
    
    def teacher_required(self, f):
        """Decorator to require teacher role for routes"""
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Check if session exists and is valid
            if 'user_id' not in session or not session.get('user_id'):
                session.clear()
                flash('Please log in to access this page.', 'error')
                return redirect(url_for('login_page'))
            
            # Check user type
            if session.get('user_type') != 'teacher':
                session.clear()
                flash('Access denied. Teachers only.', 'error')
                return redirect(url_for('login_page'))
            
            # Additional security: Check if user is still in online_users
            user_id = session.get('user_id')
            if user_id not in self.online_users:
                session.clear()
                flash('Session expired. Please log in again.', 'error')
                return redirect(url_for('login_page'))
            
            return f(*args, **kwargs)
        return decorated_function
    
    def student_required(self, f):
        """Decorator to require student role for routes"""
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Check if session exists and is valid
            if 'user_id' not in session or not session.get('user_id'):
                session.clear()
                flash('Please log in to access this page.', 'error')
                return redirect(url_for('login_page'))
            
            # Check user type
            if session.get('user_type') != 'student':
                session.clear()
                flash('Access denied. Students only.', 'error')
                return redirect(url_for('login_page'))
            
            # Additional security: Check if user is still in online_users
            user_id = session.get('user_id')
            if user_id not in self.online_users:
                session.clear()
                flash('Session expired. Please log in again.', 'error')
                return redirect(url_for('login_page'))
            
            return f(*args, **kwargs)
        return decorated_function
    
    def admin_required(self, f):
        """Decorator to require admin role for routes"""
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Check if session exists and is valid
            if 'user_id' not in session or not session.get('user_id'):
                session.clear()
                flash('Please log in to access this page.', 'error')
                return redirect(url_for('login_page'))
            
            # Check user type
            if session.get('user_type') != 'admin':
                session.clear()
                flash('Access denied. Admin only.', 'error')
                return redirect(url_for('login_page'))
            
            # Additional security: Check if user is still in online_users
            user_id = session.get('user_id')
            if user_id not in self.online_users:
                session.clear()
                flash('Session expired. Please log in again.', 'error')
                return redirect(url_for('login_page'))
            
            return f(*args, **kwargs)
        return decorated_function
    
    def api_login_required(self, f):
        """Decorator for API routes that require login"""
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Check if session exists and is valid
            if 'user_id' not in session or not session.get('user_id'):
                return jsonify({'error': 'Please log in to access this API'}), 401
            
            # Additional security: Check if user is still in online_users
            user_id = session.get('user_id')
            if user_id not in self.online_users:
                session.clear()
                return jsonify({'error': 'Session expired. Please log in again.'}), 401
            
            return f(*args, **kwargs)
        return decorated_function
    
    def api_teacher_required(self, f):
        """Decorator for API routes that require teacher role"""
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Check if session exists and is valid
            if 'user_id' not in session or not session.get('user_id'):
                return jsonify({'error': 'Please log in to access this API'}), 401
            
            # Check user type
            if session.get('user_type') != 'teacher':
                return jsonify({'error': 'Access denied. Teachers only.'}), 403
            
            # Additional security: Check if user is still in online_users
            user_id = session.get('user_id')
            if user_id not in self.online_users:
                session.clear()
                return jsonify({'error': 'Session expired. Please log in again.'}), 401
            
            return f(*args, **kwargs)
        return decorated_function
    
    def api_student_required(self, f):
        """Decorator for API routes that require student role"""
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Check if session exists and is valid
            if 'user_id' not in session or not session.get('user_id'):
                return jsonify({'error': 'Please log in to access this API'}), 401
            
            # Check user type
            if session.get('user_type') != 'student':
                return jsonify({'error': 'Access denied. Students only.'}), 403
            
            # Additional security: Check if user is still in online_users
            user_id = session.get('user_id')
            if user_id not in self.online_users:
                session.clear()
                return jsonify({'error': 'Session expired. Please log in again.'}), 401
            
            return f(*args, **kwargs)
        return decorated_function
    
    def api_admin_required(self, f):
        """Decorator for API routes that require admin role"""
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Check if session exists and is valid
            if 'user_id' not in session or not session.get('user_id'):
                return jsonify({'error': 'Please log in to access this API'}), 401
            
            # Check user type
            if session.get('user_type') != 'admin':
                return jsonify({'error': 'Access denied. Admin only.'}), 403
            
            # Additional security: Check if user is still in online_users
            user_id = session.get('user_id')
            if user_id not in self.online_users:
                session.clear()
                return jsonify({'error': 'Session expired. Please log in again.'}), 401
            
            return f(*args, **kwargs)
        return decorated_function
    
    def api_auth_required(self, f):
        """Decorator for API routes that require any valid authentication"""
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Check session first with enhanced validation
            if 'user_id' in session and session.get('user_id'):
                user_id = session.get('user_id')
                # Additional security: Check if user is still in online_users
                if user_id not in self.online_users:
                    session.clear()
                    return jsonify({'error': 'Session expired. Please log in again.'}), 401
                return f(*args, **kwargs)
            
            # Check Authorization header for API requests
            auth_header = request.headers.get('Authorization')
            if auth_header and auth_header.startswith('Bearer '):
                token = auth_header.split(' ')[1]
                # Validate token (implement your token validation logic)
                user_id = self._validate_token(token)
                if user_id:
                    return f(*args, **kwargs)
            
            return jsonify({'error': 'Authentication required'}), 401
        return decorated_function
    
    def _validate_token(self, token: str) -> Optional[str]:
        """Validate JWT token and return user_id if valid"""
        try:
            # Implement JWT validation here
            # For now, return None (tokens not implemented yet)
            return None
        except:
            return None
    
    def login_user(self, user_id: str, user_type: str, user_name: str, user_email: str) -> bool:
        """
        Log in a user and track them as online
        
        Args:
            user_id: User ID
            user_type: Type of user (student, teacher, admin)
            user_name: User's name
            user_email: User's email
            
        Returns:
            bool: True if login successful
        """
        try:
            # Set session data
            session.permanent = True
            session['user_id'] = user_id
            session['user_type'] = user_type
            session['user_name'] = user_name
            session['user_email'] = user_email
            
            # Track online users
            self.online_users[user_id] = {
                'name': user_name,
                'email': user_email,
                'type': user_type,
                'login_time': datetime.now().isoformat()
            }
            
            # Update last login in database
            if user_type == 'teacher':
                self.db.update_teacher_last_login(user_id)
            elif user_type == 'student':
                # Add similar method for students if needed
                pass
            
            return True
        except Exception:
            return False
    
    def logout_user(self, user_id: Optional[str] = None) -> bool:
        """
        Log out a user and remove them from online tracking
        
        Args:
            user_id: User ID to logout (optional, uses session if not provided)
            
        Returns:
            bool: True if logout successful
        """
        try:
            if not user_id:
                user_id = session.get('user_id')
            
            # Remove from online users tracking
            if user_id and user_id in self.online_users:
                del self.online_users[user_id]
            
            # Clear all session data
            session.clear()
            session.permanent = False
            
            return True
        except Exception:
            return False
    
    def get_current_user(self) -> Optional[Dict[str, Any]]:
        """Get current user information from session"""
        if 'user_id' not in session:
            return None
        
        user_id = session.get('user_id')
        user_type = session.get('user_type')
        
        # Get additional user info from database
        if user_type == 'teacher':
            user_data = self.db.get_teacher_by_id(user_id)
        elif user_type == 'student':
            user_data = self.db.get_student_by_id(user_id)
        elif user_type == 'admin':
            user_data = {
                'id': 'admin',
                'name': 'Admin',
                'email': 'admin@local',
                'type': 'admin'
            }
        else:
            return None
        
        if user_data:
            user_data['user_type'] = user_type
            return user_data
        
        return None
    
    def is_user_online(self, user_id: str) -> bool:
        """Check if a user is currently online"""
        return user_id in self.online_users
    
    def get_online_users(self) -> Dict[str, Dict[str, Any]]:
        """Get all currently online users"""
        return self.online_users.copy()
    
    def validate_session(self) -> bool:
        """Validate current session"""
        if 'user_id' not in session or not session.get('user_id'):
            return False
        
        user_id = session.get('user_id')
        return user_id in self.online_users
    
    def require_institution_access(self, institution_id: str):
        """Decorator to require access to a specific institution"""
        def decorator(f):
            @wraps(f)
            def decorated_function(*args, **kwargs):
                user = self.get_current_user()
                if not user:
                    return jsonify({'error': 'Authentication required'}), 401
                
                # Check if user has access to the institution
                if user['user_type'] == 'admin':
                    # Admins have access to all institutions
                    return f(*args, **kwargs)
                
                # For teachers and students, check their institution_id
                if user.get('institution_id') != institution_id:
                    return jsonify({'error': 'Access denied to this institution'}), 403
                
                return f(*args, **kwargs)
            return decorated_function
        return decorator
    
    def super_admin_required(self, f):
        """Decorator to require super admin role for routes"""
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Check if session exists and is valid
            if 'user_id' not in session or not session.get('user_id'):
                if request.is_json:
                    return jsonify({'error': 'Authentication required'}), 401
                session.clear()
                flash('Please log in to access this page.', 'error')
                return redirect('/super-admin/login')
            
            # Check if user is super admin
            if session.get('user_type') != 'super_admin':
                if request.is_json:
                    return jsonify({'error': 'Super admin access required'}), 403
                session.clear()
                flash('Super admin access required.', 'error')
                return redirect('/super-admin/login')
            
            # Additional security: Check if user is still in online_users (session validation)
            user_id = session.get('user_id')
            if user_id not in self.online_users:
                if request.is_json:
                    return jsonify({'error': 'Session expired'}), 401
                session.clear()
                flash('Session expired. Please log in again.', 'error')
                return redirect(url_for('super_admin.login'))
            
            return f(*args, **kwargs)
        return decorated_function
    
    def institution_admin_required(self, f):
        """Decorator to require institution admin role for routes"""
        @wraps(f)
        def decorated_function(*args, **kwargs):
            # Check if session exists and is valid
            if 'user_id' not in session or not session.get('user_id'):
                if request.is_json:
                    return jsonify({'error': 'Authentication required'}), 401
                session.clear()
                flash('Please log in to access this page.', 'error')
                return redirect(url_for('institution_admin.login'))
            
            # Check if user is institution admin
            if session.get('user_type') != 'admin':
                if request.is_json:
                    return jsonify({'error': 'Institution admin access required'}), 403
                session.clear()
                flash('Institution admin access required.', 'error')
                return redirect(url_for('institution_admin.login'))
            
            # Additional security: Check if user is still in online_users (session validation)
            # For now, we'll skip this check to allow session-based authentication
            # user_id = session.get('user_id')
            # if user_id not in self.online_users:
            #     if request.is_json:
            #         return jsonify({'error': 'Session expired'}), 401
            #     session.clear()
            #     flash('Session expired. Please log in again.', 'error')
            #     return redirect(url_for('institution_admin.login'))
            
            return f(*args, **kwargs)
        return decorated_function
    
    def require_cohort_access(self, cohort_id: str):
        """Decorator to require access to a specific cohort"""
        def decorator(f):
            @wraps(f)
            def decorated_function(*args, **kwargs):
                user = self.get_current_user()
                if not user:
                    return jsonify({'error': 'Authentication required'}), 401
                
                # Check if user has access to the cohort
                if user['user_type'] == 'admin':
                    # Admins have access to all cohorts
                    return f(*args, **kwargs)
                
                # For teachers, check if they teach this cohort
                if user['user_type'] == 'teacher':
                    # This would need to be implemented in the database layer
                    # For now, we'll allow access
                    return f(*args, **kwargs)
                
                # For students, check if they're enrolled in this cohort
                if user['user_type'] == 'student':
                    # This would need to be implemented in the database layer
                    # For now, we'll allow access
                    return f(*args, **kwargs)
                
                return jsonify({'error': 'Access denied to this cohort'}), 403
            return decorated_function
        return decorator

