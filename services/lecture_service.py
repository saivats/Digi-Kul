"""
Lecture Service for advanced lecture management
Handles lecture scheduling, expiry, materials, and notifications.
"""

import uuid
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any, Tuple
from utils.database_supabase import DatabaseManager
from utils.email_service import EmailService

class LectureService:
    def __init__(self, db: DatabaseManager, email_service: EmailService):
        """Initialize lecture service with database and email service"""
        self.db = db
        self.email_service = email_service
    
    def create_lecture(self, teacher_id: str, title: str, description: str, 
                      scheduled_time: str, duration: int, cohort_id: Optional[str] = None) -> Tuple[Optional[str], str]:
        """
        Create a new lecture with validation
        
        Args:
            teacher_id: ID of the teacher
            title: Lecture title
            description: Lecture description
            scheduled_time: When the lecture is scheduled (ISO format)
            duration: Duration in minutes
            cohort_id: ID of the cohort (optional)
            
        Returns:
            Tuple of (lecture_id, message)
        """
        try:
            # Validate scheduled time is not in the past
            scheduled_dt = datetime.fromisoformat(scheduled_time.replace('Z', '+00:00'))
            now = datetime.now()
            
            # Allow creating lectures starting "now" (within 5 minutes)
            if scheduled_dt < now - timedelta(minutes=5):
                return None, "Cannot schedule lectures in the past. Please select a future time."
            
            # Validate duration
            if duration < 15 or duration > 180:
                return None, "Duration must be between 15 and 180 minutes"
            
            # Create lecture
            lecture_data = {
                'teacher_id': teacher_id,
                'title': title,
                'description': description,
                'scheduled_time': scheduled_time,
                'duration': duration,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.db.supabase.table('lectures').insert(lecture_data).execute()
            
            if not result.data:
                return None, "Failed to create lecture"
            
            lecture_id = result.data[0]['id']
            
            # Link to cohort if provided
            if cohort_id:
                self.db.supabase.table('cohort_lectures').insert({
                    'cohort_id': cohort_id,
                    'lecture_id': lecture_id
                }).execute()
                
                # Send notification emails to students in the cohort
                self._send_lecture_notification(cohort_id, lecture_id, title, teacher_id, scheduled_time)
            
            return lecture_id, "Lecture created successfully"
            
        except Exception as e:
            return None, str(e)
    
    def create_instant_lecture(self, teacher_id: str, title: str, description: str, 
                              duration: int, cohort_id: Optional[str] = None) -> Tuple[Optional[str], str]:
        """
        Create an instant lecture starting now
        
        Args:
            teacher_id: ID of the teacher
            title: Lecture title
            description: Lecture description
            duration: Duration in minutes
            cohort_id: ID of the cohort (optional)
            
        Returns:
            Tuple of (lecture_id, message)
        """
        now = datetime.now()
        scheduled_time = now.isoformat()
        
        return self.create_lecture(teacher_id, title, description, scheduled_time, duration, cohort_id)
    
    def get_lecture_by_id(self, lecture_id: str) -> Optional[Dict]:
        """Get lecture by ID with related information"""
        try:
            result = self.db.supabase.table('lectures').select(
                '*, teachers!inner(name, email), institutions!inner(name)'
            ).eq('id', lecture_id).eq('is_active', True).execute()
            
            if not result.data:
                return None
            
            lecture = result.data[0]
            teacher_data = lecture.get('teachers', {})
            institution_data = lecture.get('institutions', {})
            lecture['teacher_name'] = teacher_data.get('name')
            lecture['teacher_email'] = teacher_data.get('email')
            lecture['institution_name'] = institution_data.get('name')
            del lecture['teachers']
            del lecture['institutions']
            
            # Calculate status
            lecture['status'] = self._calculate_lecture_status(lecture)
            
            return lecture
        except Exception:
            return None
    
    def get_teacher_lectures(self, teacher_id: str) -> List[Dict]:
        """Get all lectures for a teacher with status information"""
        try:
            result = self.db.supabase.table('lectures').select('*').eq('teacher_id', teacher_id).eq('is_active', True).order('scheduled_time', desc=True).execute()
            
            lectures = []
            for lecture in result.data or []:
                lecture['status'] = self._calculate_lecture_status(lecture)
                lectures.append(lecture)
            
            return lectures
        except Exception:
            return []
    
    def get_cohort_lectures(self, cohort_id: str) -> List[Dict]:
        """Get all lectures for a cohort"""
        try:
            result = self.db.supabase.table('cohort_lectures').select(
                'lectures(*, teachers!inner(name, email))'
            ).eq('cohort_id', cohort_id).execute()
            
            lectures = []
            for cl in result.data or []:
                lecture = cl['lectures']
                teacher_data = lecture.get('teachers', {})
                lecture['teacher_name'] = teacher_data.get('name')
                lecture['teacher_email'] = teacher_data.get('email')
                del lecture['teachers']
                
                # Calculate status
                lecture['status'] = self._calculate_lecture_status(lecture)
                
                lectures.append(lecture)
            
            return lectures
        except Exception:
            return []
    
    def get_student_lectures(self, student_id: str) -> List[Dict]:
        """Get all lectures available to a student through their cohorts"""
        try:
            # Get student's cohorts
            cohorts_result = self.db.supabase.table('cohort_students').select('cohort_id').eq('student_id', student_id).execute()
            cohort_ids = [cs['cohort_id'] for cs in cohorts_result.data or []]
            
            if not cohort_ids:
                return []
            
            # Get lectures from all cohorts
            result = self.db.supabase.table('cohort_lectures').select(
                'lectures(*, teachers!inner(name, email)), cohorts!inner(name)'
            ).in_('cohort_id', cohort_ids).execute()
            
            lectures = []
            for cl in result.data or []:
                lecture = cl['lectures']
                cohort = cl['cohorts']
                teacher_data = lecture.get('teachers', {})
                
                lecture['teacher_name'] = teacher_data.get('name')
                lecture['teacher_email'] = teacher_data.get('email')
                lecture['cohort_name'] = cohort.get('name')
                del lecture['teachers']
                del lecture['cohorts']
                
                # Calculate status
                lecture['status'] = self._calculate_lecture_status(lecture)
                
                lectures.append(lecture)
            
            return lectures
        except Exception:
            return []
    
    def get_active_lectures(self) -> List[Dict]:
        """Get all currently active lectures"""
        try:
            now = datetime.now()
            result = self.db.supabase.table('lectures').select(
                '*, teachers!inner(name, email)'
            ).eq('is_active', True).execute()
            
            active_lectures = []
            for lecture in result.data or []:
                scheduled_dt = datetime.fromisoformat(lecture['scheduled_time'].replace('Z', '+00:00'))
                end_dt = scheduled_dt + timedelta(minutes=lecture['duration'])
                
                # Check if lecture is currently active
                if scheduled_dt <= now <= end_dt:
                    teacher_data = lecture.get('teachers', {})
                    lecture['teacher_name'] = teacher_data.get('name')
                    lecture['teacher_email'] = teacher_data.get('email')
                    del lecture['teachers']
                    
                    lecture['status'] = 'active'
                    active_lectures.append(lecture)
            
            return active_lectures
        except Exception:
            return []
    
    def get_expired_lectures(self) -> List[Dict]:
        """Get all expired lectures that need to be marked as inactive"""
        try:
            now = datetime.now()
            result = self.db.supabase.table('lectures').select('*').eq('is_active', True).execute()
            
            expired_lectures = []
            for lecture in result.data or []:
                scheduled_dt = datetime.fromisoformat(lecture['scheduled_time'].replace('Z', '+00:00'))
                end_dt = scheduled_dt + timedelta(minutes=lecture['duration'])
                
                # Check if lecture has expired
                if now > end_dt:
                    lecture['status'] = 'expired'
                    expired_lectures.append(lecture)
            
            return expired_lectures
        except Exception:
            return []
    
    def expire_lecture(self, lecture_id: str) -> bool:
        """Mark a lecture as expired (soft delete)"""
        try:
            result = self.db.supabase.table('lectures').update({'is_active': False}).eq('id', lecture_id).execute()
            return len(result.data) > 0
        except Exception:
            return False
    
    def expire_all_lectures(self) -> int:
        """Expire all lectures that have ended and return count of expired lectures"""
        expired_lectures = self.get_expired_lectures()
        count = 0
        
        for lecture in expired_lectures:
            if self.expire_lecture(lecture['id']):
                count += 1
        
        return count
    
    def add_material(self, lecture_id: str, title: str, description: str, 
                    file_path: str, compressed_path: str, file_size: int, 
                    file_type: str) -> Tuple[Optional[str], str]:
        """
        Add material to a lecture
        
        Args:
            lecture_id: ID of the lecture
            title: Material title
            description: Material description
            file_path: Path to original file
            compressed_path: Path to compressed file
            file_size: File size in bytes
            file_type: Type of file
            
        Returns:
            Tuple of (material_id, message)
        """
        try:
            # Use the database manager's add_material method which handles all required fields
            return self.db.add_material(
                lecture_id=lecture_id,
                title=title,
                description=description,
                file_path=file_path,
                compressed_path=compressed_path,
                file_size=file_size,
                file_type=file_type
            )
        except Exception as e:
            return None, str(e)
    
    def get_lecture_materials(self, lecture_id: str) -> List[Dict]:
        """Get all materials for a lecture"""
        try:
            result = self.db.supabase.table('materials').select('*').eq('lecture_id', lecture_id).eq('is_active', True).order('uploaded_at', desc=True).execute()
            return result.data or []
        except Exception:
            return []
    
    def delete_material(self, material_id: str) -> bool:
        """Delete a material (soft delete)"""
        try:
            result = self.db.supabase.table('materials').update({'is_active': False}).eq('id', material_id).execute()
            return len(result.data) > 0
        except Exception:
            return False
    
    def get_lecture_analytics(self, lecture_id: str) -> Dict[str, Any]:
        """
        Get analytics for a lecture
        
        Args:
            lecture_id: ID of the lecture
            
        Returns:
            Dictionary with lecture analytics
        """
        try:
            lecture = self.get_lecture_by_id(lecture_id)
            if not lecture:
                return {}
            
            # Get materials count
            materials_result = self.db.supabase.table('materials').select('id', count='exact').eq('lecture_id', lecture_id).eq('is_active', True).execute()
            materials_count = materials_result.count if materials_result.count else 0
            
            # Get student count (through cohorts)
            cohorts_result = self.db.supabase.table('cohort_lectures').select('cohort_id').eq('lecture_id', lecture_id).execute()
            cohort_ids = [cl['cohort_id'] for cl in cohorts_result.data or []]
            
            student_count = 0
            if cohort_ids:
                for cohort_id in cohort_ids:
                    students_result = self.db.supabase.table('cohort_students').select('id', count='exact').eq('cohort_id', cohort_id).execute()
                    student_count += students_result.count if students_result.count else 0
            
            # Get attendance (if tracking is implemented)
            attendance_count = 0  # Placeholder for future implementation
            
            return {
                'lecture_id': lecture_id,
                'lecture_title': lecture['title'],
                'status': lecture['status'],
                'scheduled_time': lecture['scheduled_time'],
                'duration': lecture['duration'],
                'materials_count': materials_count,
                'student_count': student_count,
                'attendance_count': attendance_count,
                'attendance_rate': round((attendance_count / student_count * 100), 2) if student_count > 0 else 0,
                'teacher_name': lecture.get('teacher_name'),
                'created_at': lecture['created_at']
            }
            
        except Exception:
            return {}
    
    def _calculate_lecture_status(self, lecture: Dict) -> str:
        """Calculate the status of a lecture"""
        try:
            now = datetime.now()
            scheduled_dt = datetime.fromisoformat(lecture['scheduled_time'].replace('Z', '+00:00'))
            end_dt = scheduled_dt + timedelta(minutes=lecture['duration'])
            
            if now < scheduled_dt:
                return 'scheduled'
            elif scheduled_dt <= now <= end_dt:
                return 'active'
            else:
                return 'completed'
        except Exception:
            return 'unknown'
    
    def _send_lecture_notification(self, cohort_id: str, lecture_id: str, 
                                  title: str, teacher_id: str, scheduled_time: str):
        """Send notification emails to students in a cohort about a new lecture"""
        try:
            # Get teacher information
            teacher = self.db.get_teacher_by_id(teacher_id)
            if not teacher:
                return
            
            # Get students in the cohort
            students_result = self.db.supabase.table('cohort_students').select(
                'students(*)'
            ).eq('cohort_id', cohort_id).execute()
            
            # Send email to each student
            for cs in students_result.data or []:
                student = cs['students']
                self.email_service.send_lecture_notification(
                    user_email=student['email'],
                    user_name=student['name'],
                    lecture_title=title,
                    teacher_name=teacher['name'],
                    scheduled_time=scheduled_time
                )
                
        except Exception as e:
            # Log error but don't fail the lecture creation
            print(f"Failed to send lecture notifications: {str(e)}")
    
    def get_teacher_lecture_analytics(self, teacher_id: str) -> Dict[str, Any]:
        """Get comprehensive analytics for all teacher's lectures"""
        try:
            lectures = self.get_teacher_lectures(teacher_id)
            
            if not lectures:
                return {
                    'total_lectures': 0,
                    'active_lectures': 0,
                    'scheduled_lectures': 0,
                    'completed_lectures': 0,
                    'total_materials': 0,
                    'total_students': 0
                }
            
            active_count = sum(1 for l in lectures if l['status'] == 'active')
            scheduled_count = sum(1 for l in lectures if l['status'] == 'scheduled')
            completed_count = sum(1 for l in lectures if l['status'] == 'completed')
            
            # Get total materials
            total_materials = 0
            for lecture in lectures:
                materials_result = self.db.supabase.table('materials').select('id', count='exact').eq('lecture_id', lecture['id']).eq('is_active', True).execute()
                total_materials += materials_result.count if materials_result.count else 0
            
            # Get total students across all cohorts
            total_students = 0
            cohorts_result = self.db.supabase.table('cohort_lectures').select('cohort_id').in_('lecture_id', [l['id'] for l in lectures]).execute()
            cohort_ids = list(set(cl['cohort_id'] for cl in cohorts_result.data or []))
            
            for cohort_id in cohort_ids:
                students_result = self.db.supabase.table('cohort_students').select('id', count='exact').eq('cohort_id', cohort_id).execute()
                total_students += students_result.count if students_result.count else 0
            
            return {
                'total_lectures': len(lectures),
                'active_lectures': active_count,
                'scheduled_lectures': scheduled_count,
                'completed_lectures': completed_count,
                'total_materials': total_materials,
                'total_students': total_students
            }
            
        except Exception:
            return {}
    
    def delete_lecture(self, lecture_id: str) -> bool:
        """
        Delete a lecture by setting is_active to False
        
        Args:
            lecture_id: ID of the lecture to delete
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            return self.db.delete_lecture(lecture_id)
        except Exception as e:
            print(f"Error deleting lecture: {e}")
            return False

