"""
Institution Admin Service
Handles institution admin operations like user management, cohort management, and institution-specific analytics.
"""

from datetime import datetime
from typing import Dict, List, Optional, Any
from utils.database_supabase import SupabaseDatabaseManager
from utils.email_service import EmailService
import logging

logger = logging.getLogger(__name__)

class InstitutionAdminService:
    """Service class for institution admin operations"""
    
    def __init__(self, db: SupabaseDatabaseManager, email_service: EmailService):
        self.db = db
        self.email_service = email_service
    
    # ==================== TEACHER MANAGEMENT ====================
    
    def get_teachers(self, institution_id: str) -> Dict[str, Any]:
        """Get all teachers for an institution"""
        try:
            teachers = self.db.get_teachers_by_institution(institution_id)
            return {
                'success': True,
                'teachers': teachers,
                'count': len(teachers) if teachers else 0
            }
        except Exception as e:
            logger.error(f"Error getting teachers for institution {institution_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'teachers': [],
                'count': 0
            }
    
    def get_teacher_by_id(self, teacher_id: str) -> Dict[str, Any]:
        """Get teacher by ID"""
        try:
            teacher = self.db.get_teacher_by_id(teacher_id)
            if teacher:
                return {
                    'success': True,
                    'teacher': teacher
                }
            else:
                return {
                    'success': False,
                    'error': 'Teacher not found'
                }
        except Exception as e:
            logger.error(f"Error getting teacher {teacher_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def create_teacher(self, institution_id: str, teacher_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new teacher"""
        try:
            # Validate required fields
            required_fields = ['email', 'password', 'first_name', 'last_name', 'subject']
            for field in required_fields:
                if not teacher_data.get(field):
                    return {
                        'success': False,
                        'error': f'Missing required field: {field}'
                    }
            
            # Check if email already exists
            existing_teacher = self.db.get_teacher_by_email(teacher_data['email'])
            if existing_teacher:
                return {
                    'success': False,
                    'error': 'Email already exists'
                }
            
            # Add institution_id to teacher data
            teacher_data['institution_id'] = institution_id
            
            # Create teacher
            teacher_id = self.db.create_teacher(teacher_data)
            
            if teacher_id:
                # Send welcome email
                try:
                    self.email_service.send_teacher_welcome_email(
                        teacher_data['email'],
                        teacher_data['first_name'],
                        teacher_data['subject']
                    )
                except Exception as email_error:
                    logger.warning(f"Failed to send welcome email: {str(email_error)}")
                
                return {
                    'success': True,
                    'teacher_id': teacher_id,
                    'message': 'Teacher created successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to create teacher'
                }
                
        except Exception as e:
            logger.error(f"Error creating teacher: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def update_teacher(self, teacher_id: str, update_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update teacher details"""
        try:
            success = self.db.update_teacher(teacher_id, update_data)
            if success:
                return {
                    'success': True,
                    'message': 'Teacher updated successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to update teacher'
                }
        except Exception as e:
            logger.error(f"Error updating teacher {teacher_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def deactivate_teacher(self, teacher_id: str) -> Dict[str, Any]:
        """Deactivate a teacher"""
        try:
            success = self.db.deactivate_teacher(teacher_id)
            if success:
                return {
                    'success': True,
                    'message': 'Teacher deactivated successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to deactivate teacher'
                }
        except Exception as e:
            logger.error(f"Error deactivating teacher {teacher_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    # ==================== STUDENT MANAGEMENT ====================
    
    def get_students(self, institution_id: str) -> Dict[str, Any]:
        """Get all students for an institution"""
        try:
            students = self.db.get_students_by_institution(institution_id)
            return {
                'success': True,
                'students': students,
                'count': len(students) if students else 0
            }
        except Exception as e:
            logger.error(f"Error getting students for institution {institution_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'students': [],
                'count': 0
            }
    
    def get_student_by_id(self, student_id: str) -> Dict[str, Any]:
        """Get student by ID"""
        try:
            student = self.db.get_student_by_id(student_id)
            if student:
                return {
                    'success': True,
                    'student': student
                }
            else:
                return {
                    'success': False,
                    'error': 'Student not found'
                }
        except Exception as e:
            logger.error(f"Error getting student {student_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def create_student(self, institution_id: str, student_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new student"""
        try:
            # Validate required fields
            required_fields = ['email', 'password', 'first_name', 'last_name', 'grade']
            for field in required_fields:
                if not student_data.get(field):
                    return {
                        'success': False,
                        'error': f'Missing required field: {field}'
                    }
            
            # Check if email already exists
            existing_student = self.db.get_student_by_email(student_data['email'])
            if existing_student:
                return {
                    'success': False,
                    'error': 'Email already exists'
                }
            
            # Add institution_id to student data
            student_data['institution_id'] = institution_id
            
            # Create student
            student_id = self.db.create_student(student_data)
            
            if student_id:
                # Send welcome email
                try:
                    self.email_service.send_student_welcome_email(
                        student_data['email'],
                        student_data['first_name'],
                        student_data['grade']
                    )
                except Exception as email_error:
                    logger.warning(f"Failed to send welcome email: {str(email_error)}")
                
                return {
                    'success': True,
                    'student_id': student_id,
                    'message': 'Student created successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to create student'
                }
                
        except Exception as e:
            logger.error(f"Error creating student: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def update_student(self, student_id: str, update_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update student details"""
        try:
            success = self.db.update_student(student_id, update_data)
            if success:
                return {
                    'success': True,
                    'message': 'Student updated successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to update student'
                }
        except Exception as e:
            logger.error(f"Error updating student {student_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def deactivate_student(self, student_id: str) -> Dict[str, Any]:
        """Deactivate a student"""
        try:
            success = self.db.deactivate_student(student_id)
            if success:
                return {
                    'success': True,
                    'message': 'Student deactivated successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to deactivate student'
                }
        except Exception as e:
            logger.error(f"Error deactivating student {student_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    # ==================== COHORT MANAGEMENT ====================
    
    def get_cohorts(self, institution_id: str) -> Dict[str, Any]:
        """Get all cohorts for an institution"""
        try:
            cohorts = self.db.get_cohorts_by_institution(institution_id)
            return {
                'success': True,
                'cohorts': cohorts,
                'count': len(cohorts) if cohorts else 0
            }
        except Exception as e:
            logger.error(f"Error getting cohorts for institution {institution_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'cohorts': [],
                'count': 0
            }
    
    def get_cohort_by_id(self, cohort_id: str) -> Dict[str, Any]:
        """Get cohort by ID"""
        try:
            cohort = self.db.get_cohort_by_id(cohort_id)
            if cohort:
                return {
                    'success': True,
                    'cohort': cohort
                }
            else:
                return {
                    'success': False,
                    'error': 'Cohort not found'
                }
        except Exception as e:
            logger.error(f"Error getting cohort {cohort_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def create_cohort(self, institution_id: str, cohort_data: Dict[str, Any]) -> Dict[str, Any]:
        """Create a new cohort"""
        try:
            # Validate required fields
            required_fields = ['name', 'description', 'teacher_id', 'subject']
            for field in required_fields:
                if not cohort_data.get(field):
                    return {
                        'success': False,
                        'error': f'Missing required field: {field}'
                    }
            
            # Add institution_id to cohort data
            cohort_data['institution_id'] = institution_id
            
            # Create cohort
            cohort_id = self.db.create_cohort(cohort_data)
            
            if cohort_id:
                return {
                    'success': True,
                    'cohort_id': cohort_id,
                    'message': 'Cohort created successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to create cohort'
                }
                
        except Exception as e:
            logger.error(f"Error creating cohort: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def update_cohort(self, cohort_id: str, update_data: Dict[str, Any]) -> Dict[str, Any]:
        """Update cohort details"""
        try:
            success = self.db.update_cohort(cohort_id, update_data)
            if success:
                return {
                    'success': True,
                    'message': 'Cohort updated successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to update cohort'
                }
        except Exception as e:
            logger.error(f"Error updating cohort {cohort_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def deactivate_cohort(self, cohort_id: str) -> Dict[str, Any]:
        """Deactivate a cohort"""
        try:
            success = self.db.deactivate_cohort(cohort_id)
            if success:
                return {
                    'success': True,
                    'message': 'Cohort deactivated successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to deactivate cohort'
                }
        except Exception as e:
            logger.error(f"Error deactivating cohort {cohort_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    # ==================== INSTITUTION ANALYTICS ====================
    
    def get_institution_stats(self, institution_id: str) -> Dict[str, Any]:
        """Get statistics for the institution"""
        try:
            stats = self.db.get_institution_stats(institution_id)
            return {
                'success': True,
                'stats': stats
            }
        except Exception as e:
            logger.error(f"Error getting institution stats for {institution_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'stats': {}
            }
    
    def get_teacher_performance(self, institution_id: str, teacher_id: Optional[str] = None) -> Dict[str, Any]:
        """Get teacher performance metrics"""
        try:
            if teacher_id:
                # Get performance for specific teacher
                performance = self.db.get_teacher_performance(teacher_id)
            else:
                # Get performance for all teachers in institution
                performance = self.db.get_institution_teacher_performance(institution_id)
            
            return {
                'success': True,
                'performance': performance
            }
        except Exception as e:
            logger.error(f"Error getting teacher performance: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'performance': {}
            }
    
    def get_student_analytics(self, institution_id: str) -> Dict[str, Any]:
        """Get student analytics for the institution"""
        try:
            analytics = self.db.get_institution_student_analytics(institution_id)
            return {
                'success': True,
                'analytics': analytics
            }
        except Exception as e:
            logger.error(f"Error getting student analytics for {institution_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'analytics': {}
            }
    
    # ==================== ENROLLMENT MANAGEMENT ====================
    
    def enroll_student_in_cohort(self, student_id: str, cohort_id: str) -> Dict[str, Any]:
        """Enroll a student in a cohort"""
        try:
            success = self.db.enroll_student_in_cohort(student_id, cohort_id)
            if success:
                return {
                    'success': True,
                    'message': 'Student enrolled successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to enroll student'
                }
        except Exception as e:
            logger.error(f"Error enrolling student {student_id} in cohort {cohort_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def unenroll_student_from_cohort(self, student_id: str, cohort_id: str) -> Dict[str, Any]:
        """Unenroll a student from a cohort"""
        try:
            success = self.db.unenroll_student_from_cohort(student_id, cohort_id)
            if success:
                return {
                    'success': True,
                    'message': 'Student unenrolled successfully'
                }
            else:
                return {
                    'success': False,
                    'error': 'Failed to unenroll student'
                }
        except Exception as e:
            logger.error(f"Error unenrolling student {student_id} from cohort {cohort_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e)
            }
    
    def get_cohort_enrollments(self, cohort_id: str) -> Dict[str, Any]:
        """Get all enrollments for a cohort"""
        try:
            enrollments = self.db.get_cohort_enrollments(cohort_id)
            return {
                'success': True,
                'enrollments': enrollments,
                'count': len(enrollments) if enrollments else 0
            }
        except Exception as e:
            logger.error(f"Error getting enrollments for cohort {cohort_id}: {str(e)}")
            return {
                'success': False,
                'error': str(e),
                'enrollments': [],
                'count': 0
            }
