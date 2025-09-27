"""
Institution Routes
Handles institution-specific functionality and login pages.
"""

from flask import Blueprint, request, jsonify, session, redirect, url_for, render_template
from datetime import datetime
from werkzeug.security import check_password_hash
from utils.password_utils import check_password_hash_compatible
from utils.database_supabase import DatabaseManager
from utils.email_service import EmailService

# Initialize blueprint
institution_bp = Blueprint('institution', __name__)

# Initialize services
db = DatabaseManager()
email_service = EmailService()

@institution_bp.route('/<subdomain>')
def institution_home(subdomain):
    """Institution-specific home page"""
    try:
        # Get institution by subdomain
        institution = db.get_institution_by_subdomain(subdomain)
        
        if not institution:
            return render_template('404.html'), 404
        
        if not institution['is_active']:
            return render_template('institution_inactive.html', institution=institution), 403
        
        # Redirect to login page
        return redirect(url_for('institution.institution_login', subdomain=subdomain))
        
    except Exception as e:
        return render_template('500.html', error=str(e)), 500

@institution_bp.route('/<subdomain>/login')
def institution_login(subdomain):
    """Institution-specific login page"""
    try:
        # Get institution by subdomain
        institution = db.get_institution_by_subdomain(subdomain)
        
        if not institution:
            return render_template('404.html'), 404
        
        if not institution['is_active']:
            return render_template('institution_inactive.html', institution=institution), 403
        
        return render_template('institution_login.html', institution=institution)
        
    except Exception as e:
        return render_template('500.html', error=str(e)), 500

@institution_bp.route('/api/institution-login', methods=['POST'])
def institution_login_api():
    """Handle institution-specific login"""
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        user_type = data.get('user_type', 'student')
        institution_id = data.get('institution_id')
        
        if not all([email, password, institution_id]):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Validate email domain
        email_domain = email.split('@')[1] if '@' in email else ''
        institution = db.get_institution_by_id(institution_id)
        
        if not institution:
            return jsonify({'error': 'Invalid institution'}), 404
        
        if email_domain != institution['domain']:
            return jsonify({'error': f'Please use your {institution["name"]} email address'}), 400
        
        # Authenticate user based on type
        user = None
        user_data = None
        
        if user_type == 'student':
            user = db.get_student_by_email_and_institution(email, institution_id)
        elif user_type == 'teacher':
            user = db.get_teacher_by_email_and_institution(email, institution_id)
        elif user_type == 'admin':
            user = db.get_institution_admin_by_email_and_institution(email, institution_id)
        else:
            return jsonify({'error': 'Invalid user type'}), 400
        
        if not user:
            return jsonify({'error': 'Invalid credentials'}), 401
            
        # Check password with backward compatibility
        if not check_password_hash_compatible(user['password_hash'], password):
            return jsonify({'error': 'Invalid credentials'}), 401
        
        if not user.get('is_active', True):
            return jsonify({'error': 'Account is deactivated'}), 403
        
        # Set session
        session['user_id'] = user['id']
        session['user_type'] = user_type
        session['user_name'] = user['name']
        session['user_email'] = user['email']
        session['institution_id'] = institution_id
        session['institution_name'] = institution['name']
        session['institution_domain'] = institution['domain']
        
        # Update last login
        if user_type == 'student':
            db.update_student_last_login(user['id'])
        elif user_type == 'teacher':
            db.update_teacher_last_login(user['id'])
        elif user_type == 'admin':
            db.update_institution_admin_last_login(user['id'])
        
        # Add user to online users for session management
        from middlewares.auth_middleware import AuthMiddleware
        # We need to access the global auth_middleware instance
        # For now, we'll skip this and let the session handle it
        pass
        
        # Log activity
        db.log_user_activity(
            institution_id=institution_id,
            user_id=user['id'],
            user_type=user_type,
            action='login',
            resource_type='authentication',
            details={'login_method': 'institution_login'}
        )
        
        # Determine redirect URL based on user type
        redirect_url = '/dashboard'  # Default
        if user_type == 'admin':
            redirect_url = '/institution-admin/dashboard'
        elif user_type == 'teacher':
            redirect_url = '/teacher/dashboard'
        elif user_type == 'student':
            redirect_url = '/student/dashboard'
        
        return jsonify({
            'success': True,
            'message': 'Login successful',
            'user_type': user_type,
            'institution_name': institution['name'],
            'redirect_url': redirect_url
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_bp.route('/<subdomain>/dashboard')
def institution_dashboard_redirect(subdomain):
    """Redirect to appropriate dashboard based on user type"""
    try:
        if 'user_type' not in session:
            return redirect(url_for('institution.institution_login', subdomain=subdomain))
        
        # Verify user belongs to this institution
        institution = db.get_institution_by_subdomain(subdomain)
        if not institution or str(institution['id']) != str(session.get('institution_id')):
            session.clear()
            return redirect(url_for('institution.institution_login', subdomain=subdomain))
        
        # Redirect based on user type
        user_type = session['user_type']
        if user_type == 'student':
            return redirect(url_for('student.dashboard'))
        elif user_type == 'teacher':
            return redirect(url_for('teacher.dashboard'))
        elif user_type == 'admin':
            return redirect(url_for('admin.dashboard'))
        else:
            session.clear()
            return redirect(url_for('institution.institution_login', subdomain=subdomain))
            
    except Exception as e:
        return render_template('500.html', error=str(e)), 500

@institution_bp.route('/api/institutions/<institution_id>/info')
def get_institution_info(institution_id):
    """Get institution information for public access"""
    try:
        institution = db.get_institution_by_id(institution_id)
        
        if not institution:
            return jsonify({'error': 'Institution not found'}), 404
        
        # Return public information only
        public_info = {
            'id': institution['id'],
            'name': institution['name'],
            'domain': institution['domain'],
            'subdomain': institution['subdomain'],
            'description': institution['description'],
            'logo_url': institution['logo_url'],
            'primary_color': institution['primary_color'],
            'secondary_color': institution['secondary_color'],
            'contact_email': institution['contact_email'],
            'is_active': institution['is_active']
        }
        
        return jsonify({
            'success': True,
            'institution': public_info
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_bp.route('/api/validate-domain')
def validate_domain():
    """Validate if domain exists and is active"""
    try:
        domain = request.args.get('domain')
        
        if not domain:
            return jsonify({'error': 'Domain required'}), 400
        
        institution = db.get_institution_by_domain(domain)
        
        if not institution:
            return jsonify({
                'success': False,
                'message': 'Institution not found'
            }), 404
        
        if not institution['is_active']:
            return jsonify({
                'success': False,
                'message': 'Institution is currently inactive'
            }), 403
        
        return jsonify({
            'success': True,
            'institution': {
                'id': institution['id'],
                'name': institution['name'],
                'subdomain': institution['subdomain'],
                'logo_url': institution['logo_url']
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_bp.route('/api/check-email-domain')
def check_email_domain():
    """Check if email domain matches any institution"""
    try:
        email = request.args.get('email')
        
        if not email or '@' not in email:
            return jsonify({'error': 'Valid email required'}), 400
        
        domain = email.split('@')[1]
        institution = db.get_institution_by_domain(domain)
        
        if not institution:
            return jsonify({
                'success': False,
                'message': 'Email domain not recognized'
            }), 404
        
        if not institution['is_active']:
            return jsonify({
                'success': False,
                'message': 'Institution is currently inactive'
            }), 403
        
        return jsonify({
            'success': True,
            'institution': {
                'id': institution['id'],
                'name': institution['name'],
                'domain': institution['domain'],
                'subdomain': institution['subdomain'],
                'logo_url': institution['logo_url'],
                'primary_color': institution['primary_color'],
                'secondary_color': institution['secondary_color']
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_bp.route('/<subdomain>/register')
def institution_register(subdomain):
    """Institution-specific registration page (admin only)"""
    try:
        # Get institution by subdomain
        institution = db.get_institution_by_subdomain(subdomain)
        
        if not institution:
            return render_template('404.html'), 404
        
        if not institution['is_active']:
            return render_template('institution_inactive.html', institution=institution), 403
        
        # Check if user is logged in as institution admin
        if session.get('user_type') != 'admin' or str(session.get('institution_id')) != str(institution['id']):
            flash('Only administrators can access user registration.', 'warning')
            return redirect(url_for('institution.institution_login', subdomain=subdomain))
        
        return render_template('register.html', institution=institution)
        
    except Exception as e:
        return render_template('500.html', error=str(e)), 500

@institution_bp.route('/<subdomain>/logout')
def institution_logout(subdomain):
    """Institution-specific logout"""
    try:
        # Log activity before clearing session
        if session.get('user_id') and session.get('institution_id'):
            db.log_user_activity(
                institution_id=session['institution_id'],
                user_id=session['user_id'],
                user_type=session['user_type'],
                action='logout',
                resource_type='authentication'
            )
        
        session.clear()
        return redirect(url_for('institution.institution_login', subdomain=subdomain))
        
    except Exception as e:
        session.clear()  # Clear session even if logging fails
        return redirect(url_for('institution.institution_login', subdomain=subdomain))

@institution_bp.route('/<subdomain>/contact')
def institution_contact(subdomain):
    """Institution contact page"""
    try:
        # Get institution by subdomain
        institution = db.get_institution_by_subdomain(subdomain)
        
        if not institution:
            return render_template('404.html'), 404
        
        return render_template('institution_contact.html', institution=institution)
        
    except Exception as e:
        return render_template('500.html', error=str(e)), 500

@institution_bp.route('/api/institutions/<institution_id>/stats')
def get_institution_public_stats(institution_id):
    """Get public statistics for institution"""
    try:
        institution = db.get_institution_by_id(institution_id)
        
        if not institution or not institution['is_active']:
            return jsonify({'error': 'Institution not found or inactive'}), 404
        
        # Get public stats only
        stats = db.get_institution_public_stats(institution_id)
        
        return jsonify({
            'success': True,
            'stats': stats
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
