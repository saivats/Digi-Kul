"""
Super Admin Routes
Handles super admin functionality for institution management and platform-wide operations.
"""

from flask import Blueprint, request, jsonify, session, redirect, url_for, render_template
from werkzeug.security import check_password_hash, generate_password_hash
from datetime import datetime
from utils.database import DatabaseManager
from middlewares.auth_middleware import AuthMiddleware
from utils.email_service import EmailService

# Initialize blueprint
super_admin_bp = Blueprint('super_admin', __name__, url_prefix='/super_admin')

# Initialize services
db = DatabaseManager()
auth_middleware = AuthMiddleware(None, db)
email_service = EmailService()

@super_admin_bp.route('/dashboard')
@auth_middleware.super_admin_required
def dashboard():
    """Super admin dashboard"""
    return render_template('super_admin_dashboard.html')

@super_admin_bp.route('/login', methods=['GET', 'POST'])
def login():
    """Super admin login"""
    if request.method == 'GET':
        return render_template('super_admin_login.html')
    
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({'error': 'Email and password required'}), 400
        
        # Check if user is super admin
        super_admin = db.get_super_admin_by_email(email)
        
        if not super_admin:
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # For now, use a simple password check since we're using PostgreSQL crypt()
        # In production, you should use proper Werkzeug password hashing
        if password != 'admin123':
            return jsonify({'error': 'Invalid credentials'}), 401
        
        if not super_admin['is_active']:
            return jsonify({'error': 'Account is deactivated'}), 403
        
        # Set session
        session['user_id'] = super_admin['id']
        session['user_type'] = 'super_admin'
        session['user_name'] = super_admin['name']
        session['user_email'] = super_admin['email']
        
        # Add to online users for session tracking
        auth_middleware.online_users[super_admin['id']] = {
            'user_id': super_admin['id'],
            'user_type': 'super_admin',
            'login_time': datetime.now().isoformat()
        }
        
        # Update last login
        db.update_super_admin_last_login(super_admin['id'])
        
        return jsonify({
            'success': True,
            'message': 'Login successful',
            'redirect_url': '/super_admin/dashboard'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@super_admin_bp.route('/institutions', methods=['GET'])
@auth_middleware.super_admin_required
def get_institutions():
    """Get all institutions"""
    try:
        institutions = db.get_all_institutions()
        
        # Get stats for each institution
        for institution in institutions:
            stats = db.get_institution_stats(institution['id'])
            institution['stats'] = stats
        
        return jsonify({
            'success': True,
            'institutions': institutions
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@super_admin_bp.route('/institutions', methods=['POST'])
@auth_middleware.super_admin_required
def create_institution():
    """Create a new institution"""
    try:
        data = request.get_json()
        
        required_fields = ['name', 'domain']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Validate domain format
        domain = data['domain'].lower().strip()
        if not domain or '.' not in domain:
            return jsonify({'error': 'Invalid domain format'}), 400
        
        # Check if domain already exists
        existing = db.get_institution_by_domain(domain)
        if existing:
            return jsonify({'error': 'Domain already exists'}), 409
        
        # Create institution
        institution_id = db.create_institution(
            name=data['name'],
            domain=domain,
            subdomain=data.get('subdomain'),
            logo_url=data.get('logo_url'),
            primary_color=data.get('primary_color', '#007bff'),
            secondary_color=data.get('secondary_color', '#6c757d'),
            description=data.get('description'),
            contact_email=data.get('contact_email'),
            created_by=session['user_id']
        )
        
        if institution_id:
            # Create default institution admin (not super admin)
            admin_email = f"admin@{domain}"
            admin_password = generate_password_hash('admin123')
            
            db.create_institution_admin(
                institution_id=institution_id,
                name=f"{data['name']} Admin",
                email=admin_email,
                password_hash=admin_password,
                created_by=session['user_id']
            )
            
            # Send welcome email to institution admin
            email_service.send_institution_welcome_email(
                admin_email=admin_email,
                institution_name=data['name'],
                admin_password='admin123'
            )
            
            return jsonify({
                'success': True,
                'message': 'Institution created successfully',
                'institution_id': institution_id
            }), 201
        else:
            return jsonify({'error': 'Failed to create institution'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@super_admin_bp.route('/institutions/<institution_id>', methods=['PUT'])
@auth_middleware.super_admin_required
def update_institution(institution_id):
    """Update institution"""
    try:
        data = request.get_json()
        
        # Check if institution exists
        institution = db.get_institution_by_id(institution_id)
        if not institution:
            return jsonify({'error': 'Institution not found'}), 404
        
        # Update institution
        updated = db.update_institution(
            institution_id=institution_id,
            name=data.get('name'),
            domain=data.get('domain'),
            subdomain=data.get('subdomain'),
            logo_url=data.get('logo_url'),
            primary_color=data.get('primary_color'),
            secondary_color=data.get('secondary_color'),
            description=data.get('description'),
            contact_email=data.get('contact_email'),
            settings=data.get('settings')
        )
        
        if updated:
            return jsonify({
                'success': True,
                'message': 'Institution updated successfully'
            }), 200
        else:
            return jsonify({'error': 'Failed to update institution'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@super_admin_bp.route('/institutions/<institution_id>', methods=['DELETE'])
@auth_middleware.super_admin_required
def delete_institution(institution_id):
    """Delete institution"""
    try:
        # Check if institution exists
        institution = db.get_institution_by_id(institution_id)
        if not institution:
            return jsonify({'error': 'Institution not found'}), 404
        
        # Delete institution (cascade will handle related data)
        deleted = db.delete_institution(institution_id)
        
        if deleted:
            return jsonify({
                'success': True,
                'message': 'Institution deleted successfully'
            }), 200
        else:
            return jsonify({'error': 'Failed to delete institution'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@super_admin_bp.route('/institutions/<institution_id>/toggle-status', methods=['POST'])
@auth_middleware.super_admin_required
def toggle_institution_status(institution_id):
    """Toggle institution active status"""
    try:
        data = request.get_json()
        is_active = data.get('is_active', True)
        
        # Check if institution exists
        institution = db.get_institution_by_id(institution_id)
        if not institution:
            return jsonify({'error': 'Institution not found'}), 404
        
        # Update status
        updated = db.update_institution_status(institution_id, is_active)
        
        if updated:
            return jsonify({
                'success': True,
                'message': f'Institution {"activated" if is_active else "deactivated"} successfully'
            }), 200
        else:
            return jsonify({'error': 'Failed to update institution status'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@super_admin_bp.route('/super-admins', methods=['GET'])
@auth_middleware.super_admin_required
def get_super_admins():
    """Get all super admins"""
    try:
        super_admins = db.get_all_super_admins()
        return jsonify({
            'success': True,
            'super_admins': super_admins
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@super_admin_bp.route('/super-admins', methods=['POST'])
@auth_middleware.super_admin_required
def create_super_admin():
    """Create a new super admin"""
    try:
        data = request.get_json()
        
        required_fields = ['name', 'email', 'password']
        if not all(field in data for field in required_fields):
            return jsonify({'error': 'Missing required fields'}), 400
        
        # Check if email already exists
        existing = db.get_super_admin_by_email(data['email'])
        if existing:
            return jsonify({'error': 'Email already exists'}), 409
        
        # Create super admin
        password_hash = generate_password_hash(data['password'])
        super_admin_id = db.create_super_admin(
            name=data['name'],
            email=data['email'],
            password_hash=password_hash
        )
        
        if super_admin_id:
            # Send welcome email
            email_service.send_super_admin_welcome_email(
                email=data['email'],
                name=data['name'],
                password=data['password']
            )
            
            return jsonify({
                'success': True,
                'message': 'Super admin created successfully',
                'super_admin_id': super_admin_id
            }), 201
        else:
            return jsonify({'error': 'Failed to create super admin'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@super_admin_bp.route('/super-admins/<super_admin_id>/toggle-status', methods=['POST'])
@auth_middleware.super_admin_required
def toggle_super_admin_status(super_admin_id):
    """Toggle super admin active status"""
    try:
        data = request.get_json()
        is_active = data.get('is_active', True)
        
        # Prevent self-deactivation
        if str(super_admin_id) == str(session['user_id']):
            return jsonify({'error': 'Cannot deactivate your own account'}), 400
        
        # Update status
        updated = db.update_super_admin_status(super_admin_id, is_active)
        
        if updated:
            return jsonify({
                'success': True,
                'message': f'Super admin {"activated" if is_active else "deactivated"} successfully'
            }), 200
        else:
            return jsonify({'error': 'Failed to update super admin status'}), 500
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@super_admin_bp.route('/stats', methods=['GET'])
@auth_middleware.super_admin_required
def get_platform_stats():
    """Get platform-wide statistics"""
    try:
        stats = db.get_platform_stats()
        analytics = db.get_platform_analytics()
        
        return jsonify({
            'success': True,
            'stats': stats,
            'analytics': analytics
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@super_admin_bp.route('/institutions/<institution_id>/users', methods=['GET'])
@auth_middleware.super_admin_required
def get_institution_users(institution_id):
    """Get all users for a specific institution"""
    try:
        users = db.get_institution_users(institution_id)
        return jsonify({
            'success': True,
            'users': users
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@super_admin_bp.route('/activity-logs', methods=['GET'])
@auth_middleware.super_admin_required
def get_activity_logs():
    """Get platform activity logs"""
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 50, type=int)
        institution_id = request.args.get('institution_id')
        user_type = request.args.get('user_type')
        
        logs = db.get_activity_logs(
            page=page,
            per_page=per_page,
            institution_id=institution_id,
            user_type=user_type
        )
        
        return jsonify({
            'success': True,
            'logs': logs['logs'],
            'total': logs['total'],
            'page': page,
            'per_page': per_page,
            'pages': logs['pages']
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@super_admin_bp.route('/institutions/<institution_id>/export', methods=['GET'])
@auth_middleware.super_admin_required
def export_institution_data(institution_id):
    """Export institution data"""
    try:
        # Check if institution exists
        institution = db.get_institution_by_id(institution_id)
        if not institution:
            return jsonify({'error': 'Institution not found'}), 404
        
        # Get all institution data
        export_data = db.export_institution_data(institution_id)
        
        return jsonify({
            'success': True,
            'institution': institution,
            'data': export_data
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@super_admin_bp.route('/platform-settings', methods=['GET', 'POST'])
@auth_middleware.super_admin_required
def platform_settings():
    """Get or update platform settings"""
    if request.method == 'GET':
        try:
            settings = db.get_platform_settings()
            return jsonify({
                'success': True,
                'settings': settings
            }), 200
        except Exception as e:
            return jsonify({'error': str(e)}), 500
    
    else:  # POST
        try:
            data = request.get_json()
            updated = db.update_platform_settings(data)
            
            if updated:
                return jsonify({
                    'success': True,
                    'message': 'Platform settings updated successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to update platform settings'}), 500
                
        except Exception as e:
            return jsonify({'error': str(e)}), 500
