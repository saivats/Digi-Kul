"""
Super Admin Service
Handles super admin operations like institution management, platform analytics, and global settings.
"""

from datetime import datetime
from typing import Dict, List, Optional, Any
from utils.database_supabase import SupabaseDatabaseManager
from utils.email_service import EmailService
import logging

logger = logging.getLogger(__name__)

class SuperAdminService:
    """Service class for super admin operations"""
    
    def __init__(self, db: SupabaseDatabaseManager, email_service: EmailService):
        self.db = db
        self.email_service = email_service
    
    # ==================== INSTITUTION MANAGEMENT ====================
    
    def get_all_institutions(self) -> Dict[str, Any]:
        """Get all institutions with their details"""
        try:
            institutions = self.db.get_all_institutions()
            return {
                'success': True,
                'institutions': institutions,
                'count': len(institutions) if institutions else 0
            }
        except Exception as e:
            logger.error(f"Error getting institutions: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'institutions': [],
                'count': 0
            }
    
    def get_institution_by_id(self, institution_id: str) -> Dict[str, Any]:
        """Get institution by ID"""
        try:
            institution = self.db.get_institution_by_id(institution_id)
            if institution:
                return {
                    'success': True,
                    'institution': institution
                }
            else:
                return {
                    'success': False,
                    'error': 'Institution not found'
                }
        except Exception as e:
            logger.error(f"Error getting institution {institution_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def create_institution(self, institution_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new institution"""
        try:
            # Validate required fields
            required_fields = ['name', 'contact_email']
            for field in required_fields:
                if not institution_data.get(field):
                    return {
                        'success': False,
                        'error': f'{field} is required'
                    }
            
            # Create institution
            institution_id = self.db.create_institution(
                name=institution_data['name'],
                domain=institution_data.get('domain'),
                subdomain=institution_data.get('subdomain'),
                logo_url=institution_data.get('logo_url'),
                primary_color=institution_data.get('primary_color', '#007bff'),
                secondary_color=institution_data.get('secondary_color', '#6c757d'),
                description=institution_data.get('description'),
                contact_email=institution_data['contact_email'],
                created_by=institution_data.get('created_by')
            )
            
            if institution_id:
                # Create default institution admin
                admin_name = f"{institution_data['name']} Administrator"
                admin_email = institution_data['contact_email']
                admin_password = "admin123"  # Default password - should be changed on first login
                
                # Hash the password
                from werkzeug.security import generate_password_hash
                admin_password_hash = generate_password_hash(admin_password, method='scrypt')
                
                # Create the institution admin
                admin_id = self.db.create_institution_admin(
                    institution_id=institution_id,
                    name=admin_name,
                    email=admin_email,
                    password_hash=admin_password_hash
                )
                
                return {
                    'success': True,
                    'institution': {
                        'id': institution_id,
                        'name': institution_data['name'],
                        'domain': institution_data.get('domain'),
                        'subdomain': institution_data.get('subdomain'),
                        'contact_email': institution_data['contact_email']
                    },
                    'admin': {
                        'id': admin_id,
                        'name': admin_name,
                        'email': admin_email,
                        'password': admin_password  # Include for reference
                    },
                    'message': 'Institution and default admin created successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to create institution'
                }
        except Exception as e:
            logger.error(f"Error creating institution: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def update_institution(self, institution_id: str, update_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update institution details"""
        try:
            success = self.db.update_institution(institution_id, **update_data)
            if success:
                return {
                    'success': True,
                    'message': 'Institution updated successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to update institution'
                }
        except Exception as e:
            logger.error(f"Error updating institution {institution_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def toggle_institution_status(self, institution_id: str) -> Dict[str, Any]:
        """Toggle institution active status"""
        try:
            # Get current status
            institution = self.db.get_institution_by_id(institution_id)
            if not institution:
                return {
                    'success': False,
                    'error': 'Institution not found'
                }
            
            # Toggle status
            new_status = not institution.get('is_active', True)
            success = self.db.update_institution_status(institution_id, new_status)
            
            if success:
                return {
                    'success': True,
                    'message': f'Institution {"activated" if new_status else "deactivated"} successfully',
                    'is_active': new_status
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to update institution status'
                }
        except Exception as e:
            logger.error(f"Error toggling institution status {institution_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def delete_institution(self, institution_id: str) -> Dict[str, Any]:
        """Delete an institution"""
        try:
            success = self.db.delete_institution(institution_id)
            if success:
                return {
                    'success': True,
                    'message': 'Institution deleted successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to delete institution'
                }
        except Exception as e:
            logger.error(f"Error deleting institution {institution_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    # ==================== SUPER ADMIN MANAGEMENT ====================
    
    def get_all_super_admins(self) -> Dict[str, Any]:
        """Get all super admins"""
        try:
            super_admins = self.db.get_all_super_admins()
            return {
                'success': True,
                'super_admins': super_admins,
                'count': len(super_admins) if super_admins else 0
            }
        except Exception as e:
            logger.error(f"Error getting super admins: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'super_admins': [],
                'count': 0
            }
    
    def create_super_admin(self, admin_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new super admin"""
        try:
            # Validate required fields
            required_fields = ['name', 'email', 'password']
            for field in required_fields:
                if not admin_data.get(field):
                    return {
                        'success': False,
                        'error': f'{field} is required'
                    }
            
            # Hash password
            from werkzeug.security import generate_password_hash
            password_hash = generate_password_hash(admin_data['password'])
            
            # Create super admin
            admin_id = self.db.create_super_admin(
                name=admin_data['name'],
                email=admin_data['email'],
                password_hash=password_hash
            )
            
            if admin_id:
                return {
                    'success': True,
                    'super_admin': {
                        'id': admin_id,
                        'name': admin_data['name'],
                        'email': admin_data['email']
                    },
                    'message': 'Super admin created successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to create super admin'
                }
        except Exception as e:
            logger.error(f"Error creating super admin: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def toggle_super_admin_status(self, admin_id: str) -> Dict[str, Any]:
        """Toggle super admin active status"""
        try:
            # Get current status
            admin = self.db.get_super_admin_by_id(admin_id)
            if not admin:
                return {
                    'success': False,
                    'error': 'Super admin not found'
                }
            
            # Toggle status
            new_status = not admin.get('is_active', True)
            success = self.db.update_super_admin_status(admin_id, new_status)
            
            if success:
                return {
                    'success': True,
                    'message': f'Super admin {"activated" if new_status else "deactivated"} successfully',
                    'is_active': new_status
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to update super admin status'
                }
        except Exception as e:
            logger.error(f"Error toggling super admin status {admin_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    # ==================== PLATFORM STATISTICS ====================
    
    def get_platform_stats(self) -> Dict[str, Any]:
        """Get platform-wide statistics"""
        try:
            stats = self.db.get_platform_stats()
            analytics = self.db.get_platform_analytics()
            
            return {
                'success': True,
                'stats': stats,
                'analytics': analytics
            }
        except Exception as e:
            logger.error(f"Error getting platform stats: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'stats': {
                    'institutions': 0,
                    'total_users': 0,
                    'teachers': 0,
                    'students': 0,
                    'active_lectures': 0,
                    'total_quizzes': 0
                },
                'analytics': {
                    'growth_labels': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                    'growth_data': [0, 0, 0, 0, 0, 0],
                    'user_counts': {
                        'teachers': 0,
                        'students': 0,
                        'admins': 0
                    }
                }
            }
    
    def get_activity_logs(self, limit: int = 100, offset: int = 0) -> Dict[str, Any]:
        """Get system activity logs"""
        try:
            logs = self.db.get_activity_logs(limit=limit, offset=offset)
            return {
                'success': True,
                'logs': logs,
                'count': len(logs) if logs else 0
            }
        except Exception as e:
            logger.error(f"Error getting activity logs: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'logs': [],
                'count': 0
            }
    
    # ==================== PLATFORM SETTINGS ====================
    
    def get_platform_settings(self) -> Dict[str, Any]:
        """Get platform settings"""
        try:
            settings = self.db.get_platform_settings()
            return {
                'success': True,
                'settings': settings
            }
        except Exception as e:
            logger.error(f"Error getting platform settings: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'settings': {}
            }
    
    def update_platform_settings(self, settings: Dict[str, Any]) -> Dict[str, Any]:
        """Update platform settings"""
        try:
            success = self.db.update_platform_settings(settings)
            if success:
                return {
                    'success': True,
                    'message': 'Platform settings updated successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to update platform settings'
                }
        except Exception as e:
            logger.error(f"Error updating platform settings: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    # ==================== INSTITUTION USERS ====================
    
    def get_institution_users(self, institution_id: str) -> Dict[str, Any]:
        """Get all users for a specific institution"""
        try:
            # Get teachers and students for the institution
            teachers = self.db.get_teachers_by_institution(institution_id)
            students = self.db.get_students_by_institution(institution_id)
            admins = self.db.get_institution_admins(institution_id)
            
            return {
                'success': True,
                'users': {
                    'teachers': teachers or [],
                    'students': students or [],
                    'admins': admins or []
                },
                'counts': {
                    'teachers': len(teachers) if teachers else 0,
                    'students': len(students) if students else 0,
                    'admins': len(admins) if admins else 0,
                    'total': (len(teachers) if teachers else 0) + 
                            (len(students) if students else 0) + 
                            (len(admins) if admins else 0)
                }
            }
        except Exception as e:
            logger.error(f"Error getting institution users {institution_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'users': {
                    'teachers': [],
                    'students': [],
                    'admins': []
                },
                'counts': {
                    'teachers': 0,
                    'students': 0,
                    'admins': 0,
                    'total': 0
                }
            }