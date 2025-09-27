"""
Admin Service
General admin service that combines super admin and institution admin functionality.
"""

from datetime import datetime
from typing import Dict, List, Optional, Any
from utils.database_supabase import SupabaseDatabaseManager
from utils.email_service import EmailService
from services.super_admin_service import SuperAdminService
from services.institution_admin_service import InstitutionAdminService
import logging

logger = logging.getLogger(__name__)

class AdminService:
    """General admin service that handles both super admin and institution admin operations"""
    
    def __init__(self, db: SupabaseDatabaseManager, email_service: EmailService):
        self.db = db
        self.email_service = email_service
        self.super_admin_service = SuperAdminService(db, email_service)
        self.institution_admin_service = InstitutionAdminService(db, email_service)
    
    # ==================== USER MANAGEMENT ====================
    
    def get_all_users(self, user_type: Optional[str] = None, institution_id: Optional[str] = None) -> Dict[str, Any]:
        """Get all users with optional filtering"""
        try:
            if user_type == 'super_admin':
                return self.super_admin_service.get_all_super_admins()
            elif user_type == 'institution_admin':
                return self.get_institution_admins(institution_id)
            elif user_type == 'teacher':
                return self.institution_admin_service.get_teachers(institution_id)
            elif user_type == 'student':
                return self.institution_admin_service.get_students(institution_id)
            else:
                # Get all users across all types
                all_users = {
                    'super_admins': self.super_admin_service.get_all_super_admins(),
                    'institution_admins': self.get_institution_admins(institution_id),
                    'teachers': self.institution_admin_service.get_teachers(institution_id),
                    'students': self.institution_admin_service.get_students(institution_id)
                }
                return {
                    'success': True,
                    'users': all_users
                }
        except Exception as e:
            logger.error(f"Error getting users: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def get_institution_admins(self, institution_id: Optional[str] = None) -> Dict[str, Any]:
        """Get institution admins"""
        try:
            if institution_id:
                admins = self.db.get_institution_admins_by_institution(institution_id)
            else:
                admins = self.db.get_all_institution_admins()
            
            return {
                'success': True,
                'institution_admins': admins,
                'count': len(admins) if admins else 0
            }
        except Exception as e:
            logger.error(f"Error getting institution admins: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'institution_admins': [],
                'count': 0
            }
    
    def create_institution_admin(self, institution_id: str, admin_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new institution admin"""
        try:
            # Validate required fields
            required_fields = ['email', 'password', 'first_name', 'last_name']
            for field in required_fields:
                if not admin_data.get(field):
                    return {
                        'success': False,
                        'error': f'Missing required field: {field}'
                    }
            
            # Check if email already exists
            existing_admin = self.db.get_institution_admin_by_email(admin_data['email'])
            if existing_admin:
                return {
                    'success': False,
                    'error': 'Email already exists'
                }
            
            # Add institution_id to admin data
            admin_data['institution_id'] = institution_id
            
            # Create institution admin
            admin_id = self.db.create_institution_admin(admin_data)
            
            if admin_id:
                # Send welcome email
                try:
                    self.email_service.send_institution_admin_welcome_email(
                        admin_data['email'],
                        admin_data['first_name'],
                        institution_id
                    )
                except Exception as email_error:
                    logger.warning(f"Failed to send welcome email: {str(email_error)}")
                
                return {
                    'success': True,
                    'admin_id': admin_id,
                    'message': 'Institution admin created successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to create institution admin'
                }
                
        except Exception as e:
            logger.error(f"Error creating institution admin: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def update_user(self, user_id: str, user_type: str, update_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update user details based on user type"""
        try:
            if user_type == 'super_admin':
                success = self.db.update_super_admin(user_id, update_data)
            elif user_type == 'institution_admin':
                success = self.db.update_institution_admin(user_id, update_data)
            elif user_type == 'teacher':
                success = self.db.update_teacher(user_id, update_data)
            elif user_type == 'student':
                success = self.db.update_student(user_id, update_data)
            else:
                return {
                    'success': False,
                    'error': 'Invalid user type'
                }
            
            if success:
                return {
                    'success': True,
                    'message': f'{user_type.title()} updated successfully'
                }
            else:
                return {
                    'success': False,
                    'error': f'Failed to update {user_type}'
                }
        except Exception as e:
            logger.error(f"Error updating {user_type} {user_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def deactivate_user(self, user_id: str, user_type: str) -> Dict[str, Any]:
        """Deactivate user based on user type"""
        try:
            if user_type == 'super_admin':
                success = self.db.deactivate_super_admin(user_id)
            elif user_type == 'institution_admin':
                success = self.db.deactivate_institution_admin(user_id)
            elif user_type == 'teacher':
                success = self.db.deactivate_teacher(user_id)
            elif user_type == 'student':
                success = self.db.deactivate_student(user_id)
            else:
                return {
                    'success': False,
                    'error': 'Invalid user type'
                }
            
            if success:
                return {
                    'success': True,
                    'message': f'{user_type.title()} deactivated successfully'
                }
            else:
                return {
                    'success': False,
                    'error': f'Failed to deactivate {user_type}'
                }
        except Exception as e:
            logger.error(f"Error deactivating {user_type} {user_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    # ==================== INSTITUTION MANAGEMENT ====================
    
    def get_institutions(self) -> Dict[str, Any]:
        """Get all institutions"""
        return self.super_admin_service.get_all_institutions()
    
    def create_institution(self, institution_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new institution"""
        return self.super_admin_service.create_institution(institution_data)
    
    def update_institution(self, institution_id: str, update_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update institution details"""
        return self.super_admin_service.update_institution(institution_id, update_data)
    
    def deactivate_institution(self, institution_id: str) -> Dict[str, Any]:
        """Deactivate an institution"""
        return self.super_admin_service.deactivate_institution(institution_id)
    
    # ==================== COHORT MANAGEMENT ====================
    
    def get_cohorts(self, institution_id: Optional[str] = None) -> Dict[str, Any]:
        """Get cohorts"""
        if institution_id:
            return self.institution_admin_service.get_cohorts(institution_id)
        else:
            # Get all cohorts across all institutions
            try:
                cohorts = self.db.get_all_cohorts()
                return {
                    'success': True,
                    'cohorts': cohorts,
                    'count': len(cohorts) if cohorts else 0
                }
            except Exception as e:
                logger.error(f"Error getting all cohorts: {str(e)}")
                return {
                    'success': False,
                    'error': str(e),
                    'cohorts': [],
                    'count': 0
                }
    
    def create_cohort(self, institution_id: str, cohort_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new cohort"""
        return self.institution_admin_service.create_cohort(institution_id, cohort_data)
    
    def update_cohort(self, cohort_id: str, update_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update cohort details"""
        return self.institution_admin_service.update_cohort(cohort_id, update_data)
    
    def deactivate_cohort(self, cohort_id: str) -> Dict[str, Any]:
        """Deactivate a cohort"""
        return self.institution_admin_service.deactivate_cohort(cohort_id)
    
    # ==================== ANALYTICS ====================
    
    def get_platform_stats(self) -> Dict[str, Any]:
        """Get platform-wide statistics"""
        return self.super_admin_service.get_platform_stats()
    
    def get_institution_stats(self, institution_id: str) -> Dict[str, Any]:
        """Get institution statistics"""
        return self.institution_admin_service.get_institution_stats(institution_id)
    
    def get_system_health(self) -> Dict[str, Any]:
        """Get system health status"""
        return self.super_admin_service.get_system_health()
    
    # ==================== BULK OPERATIONS ====================
    
    def bulk_create_users(self, institution_id: str, users_data: List[Dict[str, Any]], user_type: str) -> Dict[str, Any]:
        """Bulk create users"""
        try:
            created_users = []
            failed_users = []
            
            for user_data in users_data:
                if user_type == 'teacher':
                    result = self.institution_admin_service.create_teacher(institution_id, user_data)
                elif user_type == 'student':
                    result = self.institution_admin_service.create_student(institution_id, user_data)
                elif user_type == 'institution_admin':
                    result = self.create_institution_admin(institution_id, user_data)
                else:
                    failed_users.append({
                        'user_data': user_data,
                        'error': 'Invalid user type'
                    })
                    continue
                
                if result['success']:
                    created_users.append(result)
                else:
                    failed_users.append({
                        'user_data': user_data,
                        'error': result['error']
                    })
            
            return {
                'success': True,
                'created_count': len(created_users),
                'failed_count': len(failed_users),
                'created_users': created_users,
                'failed_users': failed_users
            }
        except Exception as e:
            logger.error(f"Error in bulk user creation: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def export_user_data(self, institution_id: Optional[str] = None, user_type: Optional[str] = None) -> Dict[str, Any]:
        """Export user data"""
        try:
            users_result = self.get_all_users(user_type, institution_id)
            
            if users_result['success']:
                return {
                    'success': True,
                    'data': users_result,
                    'exported_at': datetime.now().isoformat()
                }
            else:
                return {
                    'success': False,
                    'error': users_result['error']
                }
        except Exception as e:
            logger.error(f"Error exporting user data: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
