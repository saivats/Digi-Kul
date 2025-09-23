"""
Cohort Service for managing institutions, cohorts, and user assignments
Handles business logic for cohort management and user notifications.
"""

import uuid
from datetime import datetime
from typing import Optional, List, Dict, Any, Tuple
from utils.database_supabase import DatabaseManager
from utils.email_service import EmailService

class CohortService:
    def __init__(self, db: DatabaseManager, email_service: EmailService):
        """Initialize cohort service with database and email service"""
        self.db = db
        self.email_service = email_service
    
    # Institution Management
    def create_institution(self, name: str, domain: Optional[str] = None, 
                          description: Optional[str] = None) -> Tuple[Optional[str], str]:
        """
        Create a new institution
        
        Args:
            name: Institution name
            domain: Institution domain (optional)
            description: Institution description (optional)
            
        Returns:
            Tuple of (institution_id, message)
        """
        try:
            institution_data = {
                'name': name,
                'domain': domain,
                'description': description,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.db.supabase.table('institutions').insert(institution_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Institution created successfully"
            else:
                return None, "Failed to create institution"
                
        except Exception as e:
            return None, str(e)
    
    def get_all_institutions(self) -> List[Dict]:
        """Get all active institutions"""
        try:
            result = self.db.supabase.table('institutions').select('*').eq('is_active', True).order('created_at', desc=True).execute()
            return result.data or []
        except Exception:
            return []
    
    def get_institution_by_id(self, institution_id: str) -> Optional[Dict]:
        """Get institution by ID"""
        try:
            result = self.db.supabase.table('institutions').select('*').eq('id', institution_id).eq('is_active', True).execute()
            return result.data[0] if result.data else None
        except Exception:
            return None
    
    # Cohort Management
    def create_cohort(self, name: str, description: str, subject: str, 
                     teacher_id: str, institution_id: str) -> Tuple[Optional[str], str]:
        """
        Create a new cohort
        
        Args:
            name: Cohort name
            description: Cohort description
            subject: Subject taught in cohort
            teacher_id: ID of the teacher assigned to cohort
            institution_id: ID of the institution
            
        Returns:
            Tuple of (cohort_id, message)
        """
        try:
            cohort_data = {
                'name': name,
                'description': description,
                'subject': subject,
                'teacher_id': teacher_id,
                'institution_id': institution_id,
                'code': str(uuid.uuid4())[:8].upper(),  # Generate short uppercase code
                'created_at': datetime.now().isoformat()
            }
            
            result = self.db.supabase.table('cohorts').insert(cohort_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Cohort created successfully"
            else:
                return None, "Failed to create cohort"
                
        except Exception as e:
            return None, str(e)
    
    def get_cohort_by_id(self, cohort_id: str) -> Optional[Dict]:
        """Get cohort by ID with related information"""
        try:
            result = self.db.supabase.table('cohorts').select(
                '*, teachers!inner(name, email), institutions!inner(name)'
            ).eq('id', cohort_id).eq('is_active', True).execute()
            
            if result.data:
                cohort = result.data[0]
                # Flatten nested data
                teacher_data = cohort.get('teachers', {})
                institution_data = cohort.get('institutions', {})
                cohort['teacher_name'] = teacher_data.get('name')
                cohort['teacher_email'] = teacher_data.get('email')
                cohort['institution_name'] = institution_data.get('name')
                del cohort['teachers']
                del cohort['institutions']
                return cohort
            return None
        except Exception:
            return None
    
    def get_cohorts_by_institution(self, institution_id: str) -> List[Dict]:
        """Get all cohorts for an institution"""
        try:
            result = self.db.supabase.table('cohorts').select(
                '*, teachers!inner(name, email)'
            ).eq('institution_id', institution_id).eq('is_active', True).order('created_at', desc=True).execute()
            
            cohorts = []
            for cohort in result.data or []:
                teacher_data = cohort.get('teachers', {})
                cohort['teacher_name'] = teacher_data.get('name')
                cohort['teacher_email'] = teacher_data.get('email')
                del cohort['teachers']
                cohorts.append(cohort)
            
            return cohorts
        except Exception:
            return []
    
    def get_teacher_cohorts(self, teacher_id: str) -> List[Dict]:
        """Get all cohorts for a teacher with student count"""
        try:
            result = self.db.supabase.table('cohorts').select(
                '*, institutions!inner(name)'
            ).eq('teacher_id', teacher_id).eq('is_active', True).order('created_at', desc=True).execute()
            
            cohorts = []
            for cohort in result.data or []:
                institution_data = cohort.get('institutions', {})
                cohort['institution_name'] = institution_data.get('name')
                del cohort['institutions']
                
                # Get student count
                student_count = self.db.supabase.table('cohort_students').select('id', count='exact').eq('cohort_id', cohort['id']).execute()
                cohort['student_count'] = student_count.count if student_count.count else 0
                
                cohorts.append(cohort)
            
            return cohorts
        except Exception:
            return []
    
    def get_student_cohorts(self, student_id: str) -> List[Dict]:
        """Get all cohorts for a student"""
        try:
            result = self.db.supabase.table('cohort_students').select(
                'cohorts(*, teachers!inner(name, email), institutions!inner(name)), joined_at'
            ).eq('student_id', student_id).execute()
            
            cohorts = []
            for cs in result.data or []:
                cohort = cs['cohorts']
                teacher_data = cohort.get('teachers', {})
                institution_data = cohort.get('institutions', {})
                cohort['teacher_name'] = teacher_data.get('name')
                cohort['teacher_email'] = teacher_data.get('email')
                cohort['institution_name'] = institution_data.get('name')
                cohort['joined_at'] = cs['joined_at']
                del cohort['teachers']
                del cohort['institutions']
                cohorts.append(cohort)
            
            return cohorts
        except Exception:
            return []
    
    def add_student_to_cohort(self, cohort_id: str, student_id: str) -> Tuple[bool, str]:
        """
        Add a student to a cohort and send welcome email
        
        Args:
            cohort_id: ID of the cohort
            student_id: ID of the student
            
        Returns:
            Tuple of (success, message)
        """
        try:
            # Check if already in cohort
            existing = self.db.supabase.table('cohort_students').select('id').eq('cohort_id', cohort_id).eq('student_id', student_id).execute()
            if existing.data:
                return True, 'Student already in cohort'
            
            # Get student and cohort information for email
            student = self.db.get_student_by_id(student_id)
            cohort = self.get_cohort_by_id(cohort_id)
            
            if not student or not cohort:
                return False, 'Student or cohort not found'
            
            # Add to cohort
            cs_data = {
                'cohort_id': cohort_id,
                'student_id': student_id,
                'joined_at': datetime.now().isoformat()
            }
            
            self.db.supabase.table('cohort_students').insert(cs_data).execute()
            
            # Send welcome email
            self.email_service.send_welcome_email(
                user_email=student['email'],
                user_name=student['name'],
                user_type='student',
                cohort_name=cohort['name'],
                cohort_code=cohort['code']
            )
            
            return True, 'Student added to cohort and welcome email sent'
            
        except Exception as e:
            return False, str(e)
    
    def remove_student_from_cohort(self, cohort_id: str, student_id: str) -> Tuple[bool, str]:
        """Remove a student from a cohort"""
        try:
            self.db.supabase.table('cohort_students').delete().eq('cohort_id', cohort_id).eq('student_id', student_id).execute()
            return True, 'Student removed from cohort'
        except Exception as e:
            return False, str(e)
    
    def join_cohort_by_code(self, student_id: str, cohort_code: str) -> Tuple[bool, str]:
        """
        Join a cohort using cohort code and send welcome email
        
        Args:
            student_id: ID of the student
            cohort_code: Cohort code to join
            
        Returns:
            Tuple of (success, message)
        """
        try:
            # Find cohort by code
            cohort_result = self.db.supabase.table('cohorts').select('id').eq('code', cohort_code).eq('is_active', True).execute()
            if not cohort_result.data:
                return False, 'Invalid cohort code'
            
            cohort_id = cohort_result.data[0]['id']
            
            # Check if already in cohort
            existing = self.db.supabase.table('cohort_students').select('id').eq('cohort_id', cohort_id).eq('student_id', student_id).execute()
            if existing.data:
                return True, 'Already in cohort'
            
            # Get student and cohort information for email
            student = self.db.get_student_by_id(student_id)
            cohort = self.get_cohort_by_id(cohort_id)
            
            if not student or not cohort:
                return False, 'Student or cohort not found'
            
            # Add to cohort
            cs_data = {
                'cohort_id': cohort_id,
                'student_id': student_id,
                'joined_at': datetime.now().isoformat()
            }
            
            self.db.supabase.table('cohort_students').insert(cs_data).execute()
            
            # Send welcome email
            self.email_service.send_welcome_email(
                user_email=student['email'],
                user_name=student['name'],
                user_type='student',
                cohort_name=cohort['name'],
                cohort_code=cohort['code']
            )
            
            return True, 'Successfully joined cohort and welcome email sent'
            
        except Exception as e:
            return False, str(e)
    
    def is_student_in_cohort(self, student_id: str, cohort_id: str) -> bool:
        """Check if student is in cohort"""
        try:
            result = self.db.supabase.table('cohort_students').select('id').eq('cohort_id', cohort_id).eq('student_id', student_id).execute()
            return len(result.data) > 0
        except Exception:
            return False
    
    def get_cohort_students(self, cohort_id: str) -> List[Dict]:
        """Get all students in a cohort"""
        try:
            result = self.db.supabase.table('cohort_students').select(
                'students(*), joined_at'
            ).eq('cohort_id', cohort_id).order('joined_at', desc=True).execute()
            
            students = []
            for cs in result.data or []:
                student = cs['students']
                student['joined_at'] = cs['joined_at']
                students.append(student)
            
            return students
        except Exception:
            return []
    
    def get_cohort_analytics(self, cohort_id: str) -> Dict[str, Any]:
        """
        Get analytics for a cohort
        
        Args:
            cohort_id: ID of the cohort
            
        Returns:
            Dictionary with cohort analytics
        """
        try:
            cohort = self.get_cohort_by_id(cohort_id)
            if not cohort:
                return {}
            
            # Get student count
            students_result = self.db.supabase.table('cohort_students').select('id', count='exact').eq('cohort_id', cohort_id).execute()
            student_count = students_result.count if students_result.count else 0
            
            # Get lecture count
            lectures_result = self.db.supabase.table('cohort_lectures').select('id', count='exact').eq('cohort_id', cohort_id).execute()
            lecture_count = lectures_result.count if lectures_result.count else 0
            
            # Get quiz count
            quiz_sets_result = self.db.supabase.table('quiz_sets').select('id', count='exact').eq('cohort_id', cohort_id).execute()
            quiz_count = quiz_sets_result.count if quiz_sets_result.count else 0
            
            return {
                'cohort_id': cohort_id,
                'cohort_name': cohort['name'],
                'student_count': student_count,
                'lecture_count': lecture_count,
                'quiz_count': quiz_count,
                'created_at': cohort['created_at'],
                'teacher_name': cohort.get('teacher_name'),
                'institution_name': cohort.get('institution_name')
            }
        except Exception:
            return {}
    
    def delete_cohort(self, cohort_id: str) -> Tuple[bool, str]:
        """Delete a cohort (soft delete)"""
        try:
            result = self.db.supabase.table('cohorts').update({'is_active': False}).eq('id', cohort_id).execute()
            if result.data:
                return True, "Cohort deleted successfully"
            else:
                return False, "Cohort not found"
        except Exception as e:
            return False, str(e)
    
    def assign_teacher_to_cohort(self, cohort_id: str, teacher_id: str) -> Tuple[bool, str]:
        """
        Assign a teacher to a cohort and send notification email
        
        Args:
            cohort_id: ID of the cohort
            teacher_id: ID of the teacher
            
        Returns:
            Tuple of (success, message)
        """
        try:
            # Get teacher and cohort information
            teacher = self.db.get_teacher_by_id(teacher_id)
            cohort = self.get_cohort_by_id(cohort_id)
            
            if not teacher or not cohort:
                return False, 'Teacher or cohort not found'
            
            # Update cohort with new teacher
            self.db.supabase.table('cohorts').update({'teacher_id': teacher_id}).eq('id', cohort_id).execute()
            
            # Send welcome email to teacher
            self.email_service.send_welcome_email(
                user_email=teacher['email'],
                user_name=teacher['name'],
                user_type='teacher',
                cohort_name=cohort['name']
            )
            
            return True, 'Teacher assigned to cohort and welcome email sent'
            
        except Exception as e:
            return False, str(e)

