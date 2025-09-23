# utils/database_supabase.py
import os
import json
import uuid
from datetime import datetime
from typing import Optional, Tuple, List, Dict, Any
from supabase import create_client, Client
from config import Config

class SupabaseDatabaseManager:
    def __init__(self):
        self.supabase_url = Config.SUPABASE_URL
        self.supabase_key = Config.SUPABASE_KEY
        
        # Check if we're in development mode with placeholder values
        if (self.supabase_url == 'https://placeholder.supabase.co' or 
            self.supabase_key == 'placeholder-key' or
            self.supabase_url == 'your-supabase-url' or
            self.supabase_key == 'your-supabase-key'):
            print("WARNING: Using placeholder Supabase credentials. Database operations will not work.")
            self.supabase = None
            return
        
        if not self.supabase_url or not self.supabase_key:
            raise ValueError("Supabase URL and Key must be set in environment variables")
        
        self.supabase: Client = create_client(self.supabase_url, self.supabase_key)
    
    def init_database(self):
        """Initialize database - tables should be created via SQL schema"""
        # This method is kept for compatibility but tables are created via SQL
        pass
    
    # Teacher methods
    def create_teacher(self, name: str, email: str, institution: str, subject: str, password_hash: str) -> Tuple[Optional[str], str]:
        """Create a new teacher"""
        try:
            # Check if email already exists
            existing = self.supabase.table('teachers').select('id').eq('email', email).execute()
            if existing.data:
                return None, "Email already registered"
            
            teacher_data = {
                'name': name,
                'email': email,
                'institution': institution,
                'subject': subject,
                'password_hash': password_hash,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('teachers').insert(teacher_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Teacher created successfully"
            else:
                return None, "Failed to create teacher"
                
        except Exception as e:
            return None, str(e)
    
    def get_teacher_by_email(self, email: str) -> Optional[Dict]:
        """Get teacher by email"""
        try:
            result = self.supabase.table('teachers').select('*').eq('email', email).eq('is_active', True).execute()
            return result.data[0] if result.data else None
        except Exception:
            return None
    
    def get_teacher_by_id(self, teacher_id: str) -> Optional[Dict]:
        """Get teacher by ID"""
        try:
            result = self.supabase.table('teachers').select('*').eq('id', teacher_id).eq('is_active', True).execute()
            return result.data[0] if result.data else None
        except Exception:
            return None
    
    def update_teacher_last_login(self, teacher_id: str) -> bool:
        """Update teacher's last login time"""
        try:
            self.supabase.table('teachers').update({
                'last_login': datetime.now().isoformat()
            }).eq('id', teacher_id).execute()
            return True
        except Exception:
            return False
    
    def get_all_teachers(self) -> List[Dict]:
        """Return all active teachers"""
        try:
            result = self.supabase.table('teachers').select(
                'id, name, email, institution, subject, created_at, last_login, is_active'
            ).eq('is_active', True).order('created_at', desc=True).execute()
            return result.data
        except Exception:
            return []
    
    # Student methods
    def create_student(self, name: str, email: str, institution: str, password_hash: str) -> Tuple[Optional[str], str]:
        """Create a new student"""
        try:
            # Check if email already exists
            existing = self.supabase.table('students').select('id').eq('email', email).execute()
            if existing.data:
                return None, "Email already registered"
            
            student_data = {
                'name': name,
                'email': email,
                'institution': institution,
                'password_hash': password_hash,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('students').insert(student_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Student created successfully"
            else:
                return None, "Failed to create student"
                
        except Exception as e:
            return None, str(e)
    
    def get_student_by_email(self, email: str) -> Optional[Dict]:
        """Get student by email"""
        try:
            result = self.supabase.table('students').select('*').eq('email', email).eq('is_active', True).execute()
            return result.data[0] if result.data else None
        except Exception:
            return None
    
    def get_student_by_id(self, student_id: str) -> Optional[Dict]:
        """Get student by ID"""
        try:
            result = self.supabase.table('students').select('*').eq('id', student_id).eq('is_active', True).execute()
            return result.data[0] if result.data else None
        except Exception:
            return None
    
    def get_all_students(self) -> List[Dict]:
        """Return all active students"""
        try:
            result = self.supabase.table('students').select(
                'id, name, email, institution, created_at, last_login, is_active'
            ).eq('is_active', True).order('created_at', desc=True).execute()
            return result.data
        except Exception:
            return []
    
    # Lecture methods
    def create_lecture(self, teacher_id: str, title: str, description: str, scheduled_time: str, duration: int) -> Tuple[Optional[str], str]:
        """Create a new lecture"""
        try:
            lecture_data = {
                'teacher_id': teacher_id,
                'title': title,
                'description': description,
                'scheduled_time': scheduled_time,
                'duration': duration,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('lectures').insert(lecture_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Lecture created successfully"
            else:
                return None, "Failed to create lecture"
                
        except Exception as e:
            return None, str(e)
    
    def get_teacher_lectures(self, teacher_id: str) -> List[Dict]:
        """Get all lectures for a teacher"""
        try:
            result = self.supabase.table('lectures').select('*').eq('teacher_id', teacher_id).eq('is_active', True).order('scheduled_time', desc=True).execute()
            return result.data
        except Exception:
            return []
    
    def get_all_lectures(self) -> List[Dict]:
        """Get all active lectures"""
        try:
            result = self.supabase.table('lectures').select(
                '*, teachers!inner(name, institution, id)'
            ).eq('is_active', True).order('scheduled_time', desc=True).execute()
            
            # Flatten the nested teacher data
            lectures = []
            for lecture in result.data:
                teacher_data = lecture.get('teachers', {})
                lecture['teacher_name'] = teacher_data.get('name')
                lecture['teacher_institution'] = teacher_data.get('institution')
                lecture['teacher_id'] = teacher_data.get('id')
                del lecture['teachers']  # Remove nested data
                lectures.append(lecture)
            
            return lectures
        except Exception:
            return []
    
    def get_lecture_by_id(self, lecture_id: str) -> Optional[Dict]:
        """Get lecture by ID"""
        try:
            result = self.supabase.table('lectures').select('*').eq('id', lecture_id).eq('is_active', True).execute()
            return result.data[0] if result.data else None
        except Exception:
            return None
    
    # Enrollment methods
    def enroll_student(self, student_id: str, lecture_id: str) -> Tuple[Optional[str], str]:
        """Enroll a student in a lecture"""
        try:
            # Check if already enrolled
            existing = self.supabase.table('enrollments').select('id').eq('student_id', student_id).eq('lecture_id', lecture_id).eq('is_active', True).execute()
            if existing.data:
                return None, "Already enrolled"
            
            enrollment_data = {
                'student_id': student_id,
                'lecture_id': lecture_id,
                'enrolled_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('enrollments').insert(enrollment_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Enrolled successfully"
            else:
                return None, "Failed to enroll"
                
        except Exception as e:
            return None, str(e)
    
    def is_student_enrolled(self, student_id: str, lecture_id: str) -> bool:
        """Check if student is enrolled in lecture"""
        try:
            result = self.supabase.table('enrollments').select('id').eq('student_id', student_id).eq('lecture_id', lecture_id).eq('is_active', True).execute()
            return len(result.data) > 0
        except Exception:
            return False
    
    def get_student_enrolled_lectures(self, student_id: str) -> List[Dict]:
        """Get lectures student is enrolled in"""
        try:
            result = self.supabase.table('enrollments').select(
                'lectures(*, teachers!inner(name, institution)), enrolled_at'
            ).eq('student_id', student_id).eq('is_active', True).execute()
            
            lectures = []
            for enrollment in result.data:
                lecture = enrollment['lectures']
                teacher_data = lecture.get('teachers', {})
                lecture['teacher_name'] = teacher_data.get('name')
                lecture['teacher_institution'] = teacher_data.get('institution')
                lecture['enrolled_at'] = enrollment['enrolled_at']
                del lecture['teachers']  # Remove nested data
                lectures.append(lecture)
            
            return lectures
        except Exception:
            return []
    
    def get_lecture_enrolled_students(self, lecture_id: str) -> List[Dict]:
        """Get students enrolled in a lecture"""
        try:
            result = self.supabase.table('enrollments').select(
                'students(*), enrolled_at'
            ).eq('lecture_id', lecture_id).eq('is_active', True).order('enrolled_at', desc=True).execute()
            
            students = []
            for enrollment in result.data:
                student = enrollment['students']
                student['enrolled_at'] = enrollment['enrolled_at']
                students.append(student)
            
            return students
        except Exception:
            return []
    
    # Material methods
    def add_material(self, lecture_id: str, title: str, description: str, file_path: str, compressed_path: str, file_size: int, file_type: str) -> Tuple[Optional[str], str]:
        """Add material to lecture"""
        try:
            material_data = {
                'lecture_id': lecture_id,
                'title': title,
                'description': description,
                'file_path': file_path,
                'compressed_path': compressed_path,
                'file_size': file_size,
                'file_type': file_type,
                'uploaded_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('materials').insert(material_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Material added successfully"
            else:
                return None, "Failed to add material"
                
        except Exception as e:
            return None, str(e)
    
    def get_lecture_materials(self, lecture_id: str) -> List[Dict]:
        """Get all materials for a lecture"""
        try:
            result = self.supabase.table('materials').select('*').eq('lecture_id', lecture_id).eq('is_active', True).order('uploaded_at', desc=True).execute()
            return result.data
        except Exception:
            return []
    
    def get_material_details(self, material_id: str) -> Optional[Dict]:
        """Get material details by ID"""
        try:
            result = self.supabase.table('materials').select(
                '*, lectures!inner(teacher_id, title)'
            ).eq('id', material_id).eq('is_active', True).execute()
            
            if result.data:
                material = result.data[0]
                lecture_data = material.get('lectures', {})
                material['teacher_id'] = lecture_data.get('teacher_id')
                material['lecture_title'] = lecture_data.get('title')
                del material['lectures']  # Remove nested data
                return material
            return None
        except Exception:
            return None
    
    def get_material_by_id(self, material_id: str) -> Optional[Dict]:
        """Get material by ID (simple version for ownership verification)"""
        try:
            result = self.supabase.table('materials').select('*').eq('id', material_id).eq('is_active', True).execute()
            return result.data[0] if result.data else None
        except Exception:
            return None
    
    def delete_material(self, material_id: str) -> bool:
        """Delete a material (soft delete)"""
        try:
            result = self.supabase.table('materials').update({'is_active': False}).eq('id', material_id).execute()
            return len(result.data) > 0
        except Exception:
            return False
    
    # Quiz methods
    def create_quiz(self, lecture_id: str, question: str, options: List[str], correct_answer: str) -> Tuple[Optional[str], str]:
        """Create a quiz for lecture"""
        try:
            quiz_data = {
                'lecture_id': lecture_id,
                'question': question,
                'options': options,  # Supabase handles JSON automatically
                'correct_answer': correct_answer,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('quizzes').insert(quiz_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Quiz created successfully"
            else:
                return None, "Failed to create quiz"
                
        except Exception as e:
            return None, str(e)
    
    def submit_quiz_response(self, student_id: str, quiz_id: str, response: str) -> Tuple[Optional[str], str]:
        """Submit quiz response"""
        try:
            # Get correct answer
            quiz_result = self.supabase.table('quizzes').select('correct_answer').eq('id', quiz_id).execute()
            if not quiz_result.data:
                return None, "Quiz not found"
            
            is_correct = response == quiz_result.data[0]['correct_answer']
            
            response_data = {
                'student_id': student_id,
                'quiz_id': quiz_id,
                'response': response,
                'is_correct': is_correct,
                'submitted_at': datetime.now().isoformat()
            }
            
            # Use upsert to handle unique constraint
            result = self.supabase.table('quiz_responses').upsert(response_data, on_conflict='student_id,quiz_id').execute()
            
            if result.data:
                return result.data[0]['id'], "Response submitted successfully"
            else:
                return None, "Failed to submit response"
                
        except Exception as e:
            return None, str(e)
    
    # Poll methods
    def create_poll(self, lecture_id: str, question: str, options: List[str], teacher_id: str = None) -> Tuple[Optional[str], str]:
        """Create a poll for lecture"""
        try:
            poll_data = {
                'lecture_id': lecture_id if lecture_id != 'general' else None,
                'question': question,
                'options': options,  # Supabase handles JSON automatically
                'created_at': datetime.now().isoformat()
            }
            
            if teacher_id:
                poll_data['teacher_id'] = teacher_id
            
            result = self.supabase.table('polls').insert(poll_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Poll created successfully"
            else:
                return None, "Failed to create poll"
                
        except Exception as e:
            return None, str(e)
    
    def submit_poll_response(self, student_id: str, poll_id: str, response: str) -> Tuple[Optional[str], str]:
        """Submit poll response"""
        try:
            response_data = {
                'student_id': student_id,
                'poll_id': poll_id,
                'response': response,
                'submitted_at': datetime.now().isoformat()
            }
            
            # Use upsert to handle duplicate responses
            result = self.supabase.table('poll_responses').upsert(
                response_data, 
                on_conflict='student_id,poll_id'
            ).execute()
            
            if result.data:
                return result.data[0]['id'], "Poll response submitted successfully"
            else:
                return None, "Failed to submit response"
                
        except Exception as e:
            return None, str(e)
    
    def get_poll_results(self, poll_id: str) -> Optional[Dict]:
        """Get poll results with vote counts"""
        try:
            # Get poll details
            poll_result = self.supabase.table('polls').select('*').eq('id', poll_id).execute()
            if not poll_result.data:
                return None
            
            poll = poll_result.data[0]
            
            # Get responses
            responses_result = self.supabase.table('poll_responses').select('response').eq('poll_id', poll_id).execute()
            
            # Count votes
            vote_counts = {}
            for response in responses_result.data:
                resp = response['response']
                vote_counts[resp] = vote_counts.get(resp, 0) + 1
            
            # Calculate percentages
            total_votes = sum(vote_counts.values())
            results = []
            
            for option in poll['options']:
                votes = vote_counts.get(option, 0)
                percentage = (votes / total_votes * 100) if total_votes > 0 else 0
                results.append({
                    'option': option,
                    'votes': votes,
                    'percentage': round(percentage, 1)
                })
            
            return {
                'poll_id': poll_id,
                'question': poll['question'],
                'total_votes': total_votes,
                'results': results,
                'created_at': poll['created_at']
            }
            
        except Exception as e:
            return None
    
    def get_lecture_polls(self, lecture_id: str) -> List[Dict]:
        """Get all polls for a lecture"""
        try:
            result = self.supabase.table('polls').select('*').eq('lecture_id', lecture_id).order('created_at', desc=True).execute()
            return result.data or []
        except Exception:
            return []
    
    def get_cohort_polls(self, cohort_id: str) -> List[Dict]:
        """Get all polls for a cohort"""
        try:
            # Get lectures in the cohort through cohort_lectures table
            cohort_lectures_result = self.supabase.table('cohort_lectures').select('lecture_id').eq('cohort_id', cohort_id).execute()
            lecture_ids = [cl['lecture_id'] for cl in cohort_lectures_result.data] if cohort_lectures_result.data else []
            
            if not lecture_ids:
                return []
            
            # Get polls for these lectures
            result = self.supabase.table('polls').select('*').in_('lecture_id', lecture_ids).order('created_at', desc=True).execute()
            return result.data or []
        except Exception:
            return []
    
    def get_teacher_polls(self, teacher_id: str) -> List[Dict]:
        """Get all polls created by a teacher"""
        try:
            result = self.supabase.table('polls').select('*').eq('teacher_id', teacher_id).order('created_at', desc=True).execute()
            return result.data or []
        except Exception:
            return []
    
    # Discussion methods
    def add_discussion_message(self, lecture_id: str, user_id: str, message: str, user_type: str = 'student') -> Tuple[Optional[str], str]:
        """Add message to discussion"""
        try:
            message_data = {
                'lecture_id': lecture_id,
                'user_id': user_id,
                'user_type': user_type,
                'message': message,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('discussion_messages').insert(message_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Message added successfully"
            else:
                return None, "Failed to add message"
                
        except Exception as e:
            return None, str(e)
    
    def get_discussion_messages(self, lecture_id: str) -> List[Dict]:
        """Get discussion messages for lecture"""
        try:
            # This is a complex query that would need to be handled differently in Supabase
            # For now, we'll get basic messages and handle user names in the application
            result = self.supabase.table('discussion_messages').select('*').eq('lecture_id', lecture_id).eq('is_active', True).order('created_at', desc=False).execute()
            return result.data
        except Exception:
            return []
    
    # Cohort methods
    def create_cohort(self, name: str, description: str, subject: str, teacher_id: str) -> Tuple[Optional[str], str]:
        """Create a new cohort"""
        try:
            cohort_data = {
                'name': name,
                'description': description,
                'subject': subject,
                'teacher_id': teacher_id,
                'code': str(uuid.uuid4())[:8],  # Generate short code
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('cohorts').insert(cohort_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Cohort created successfully"
            else:
                return None, "Failed to create cohort"
                
        except Exception as e:
            return None, str(e)
    
    def delete_cohort(self, cohort_id: str) -> Tuple[bool, str]:
        """Delete a cohort"""
        try:
            self.supabase.table('cohorts').update({'is_active': False}).eq('id', cohort_id).execute()
            return True, "Cohort deleted"
        except Exception as e:
            return False, str(e)
    
    def get_all_cohorts(self) -> List[Dict]:
        """Get all cohorts"""
        try:
            result = self.supabase.table('cohorts').select(
                '*, teachers!inner(name)'
            ).eq('is_active', True).order('created_at', desc=True).execute()
            
            cohorts = []
            for cohort in result.data:
                teacher_data = cohort.get('teachers', {})
                cohort['teacher_name'] = teacher_data.get('name')
                del cohort['teachers']  # Remove nested data
                cohorts.append(cohort)
            
            return cohorts
        except Exception:
            return []
    
    def get_cohort_by_id(self, cohort_id: str) -> Optional[Dict]:
        """Get cohort by ID"""
        try:
            result = self.supabase.table('cohorts').select('*').eq('id', cohort_id).eq('is_active', True).execute()
            return result.data[0] if result.data else None
        except Exception:
            return None
    
    def get_teacher_cohorts(self, teacher_id: str) -> List[Dict]:
        """Get cohorts for a teacher"""
        try:
            result = self.supabase.table('cohorts').select('*').eq('teacher_id', teacher_id).eq('is_active', True).order('created_at', desc=True).execute()
            return result.data
        except Exception:
            return []
    
    def get_student_cohorts(self, student_id: str) -> List[Dict]:
        """Get cohorts for a student"""
        try:
            result = self.supabase.table('cohort_students').select(
                'cohorts(*, teachers!inner(name))'
            ).eq('student_id', student_id).execute()
            
            cohorts = []
            for cs in result.data:
                cohort = cs['cohorts']
                teacher_data = cohort.get('teachers', {})
                cohort['teacher_name'] = teacher_data.get('name')
                del cohort['teachers']  # Remove nested data
                cohorts.append(cohort)
            
            return cohorts
        except Exception:
            return []
    
    def join_cohort_by_code(self, student_id: str, cohort_code: str) -> Tuple[bool, str]:
        """Join cohort by code"""
        try:
            # Find cohort by code
            cohort_result = self.supabase.table('cohorts').select('id').eq('code', cohort_code).eq('is_active', True).execute()
            if not cohort_result.data:
                return False, 'Invalid cohort code'
            
            cohort_id = cohort_result.data[0]['id']
            
            # Check if already in cohort
            existing = self.supabase.table('cohort_students').select('id').eq('cohort_id', cohort_id).eq('student_id', student_id).execute()
            if existing.data:
                return True, 'Already in cohort'
            
            # Add to cohort
            cs_data = {
                'cohort_id': cohort_id,
                'student_id': student_id,
                'joined_at': datetime.now().isoformat()
            }
            
            self.supabase.table('cohort_students').insert(cs_data).execute()
            return True, 'Joined cohort'
            
        except Exception as e:
            return False, str(e)
    
    def is_student_in_cohort(self, student_id: str, cohort_id: str) -> bool:
        """Check if student is in cohort"""
        try:
            result = self.supabase.table('cohort_students').select('id').eq('cohort_id', cohort_id).eq('student_id', student_id).execute()
            return len(result.data) > 0
        except Exception:
            return False
    
    def create_lecture_for_cohort(self, cohort_id: str, teacher_id: str, title: str, description: str, scheduled_time: str, duration: int) -> Tuple[Optional[str], str]:
        """Create lecture for cohort"""
        try:
            # Create lecture
            lecture_id, msg = self.create_lecture(teacher_id, title, description, scheduled_time, duration)
            if not lecture_id:
                return None, msg
            
            # Link to cohort
            cl_data = {
                'cohort_id': cohort_id,
                'lecture_id': lecture_id
            }
            
            self.supabase.table('cohort_lectures').insert(cl_data).execute()
            return lecture_id, 'Lecture created for cohort'
            
        except Exception as e:
            return None, str(e)
    
    def get_cohort_lectures(self, cohort_id: str) -> List[Dict]:
        """Get lectures for a cohort"""
        try:
            result = self.supabase.table('cohort_lectures').select(
                'lectures(*, teachers!inner(name))'
            ).eq('cohort_id', cohort_id).execute()
            
            lectures = []
            for cl in result.data:
                lecture = cl['lectures']
                teacher_data = lecture.get('teachers', {})
                lecture['teacher_name'] = teacher_data.get('name')
                del lecture['teachers']  # Remove nested data
                lectures.append(lecture)
            
            return lectures
        except Exception:
            return []
    
    def get_cohort_students(self, cohort_id: str) -> List[Dict]:
        """Get students in a cohort"""
        try:
            result = self.supabase.table('cohort_students').select(
                'students(*), joined_at'
            ).eq('cohort_id', cohort_id).order('joined_at', desc=True).execute()
            
            students = []
            for cs in result.data:
                student = cs['students']
                student['joined_at'] = cs['joined_at']
                students.append(student)
            
            return students
        except Exception:
            return []
    
    def add_student_to_cohort(self, cohort_id: str, student_id: str) -> Tuple[bool, str]:
        """Add student to cohort"""
        try:
            # Check if already in cohort
            existing = self.supabase.table('cohort_students').select('id').eq('cohort_id', cohort_id).eq('student_id', student_id).execute()
            if existing.data:
                return True, 'Already in cohort'
            
            cs_data = {
                'cohort_id': cohort_id,
                'student_id': student_id,
                'joined_at': datetime.now().isoformat()
            }
            
            self.supabase.table('cohort_students').insert(cs_data).execute()
            return True, 'Student added to cohort'
            
        except Exception as e:
            return False, str(e)
    
    def remove_student_from_cohort(self, cohort_id: str, student_id: str) -> Tuple[bool, str]:
        """Remove student from cohort"""
        try:
            self.supabase.table('cohort_students').delete().eq('cohort_id', cohort_id).eq('student_id', student_id).execute()
            return True, 'Removed from cohort'
        except Exception as e:
            return False, str(e)

    # Session Recording Methods
    def create_session_recording(self, recording_id: str, session_id: str, lecture_id: str, 
                                teacher_id: str, recording_type: str, started_at: str, 
                                stopped_at: str, duration: int, recording_path: str, 
                                participants: Dict, stats: Dict) -> Tuple[bool, str]:
        """Create a new session recording"""
        try:
            recording_data = {
                'id': recording_id,
                'session_id': session_id,
                'lecture_id': lecture_id,
                'teacher_id': teacher_id,
                'recording_type': recording_type,
                'started_at': started_at,
                'stopped_at': stopped_at,
                'duration': duration,
                'recording_path': recording_path,
                'participants': participants,
                'stats': stats,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('session_recordings').insert(recording_data).execute()
            
            if result.data:
                return True, "Recording saved successfully"
            else:
                return False, "Failed to save recording"
                
        except Exception as e:
            return False, str(e)

    def get_recording_by_id(self, recording_id: str) -> Optional[Dict]:
        """Get recording by ID"""
        try:
            result = self.supabase.table('session_recordings').select('*').eq('id', recording_id).single().execute()
            return result.data if result.data else None
        except Exception:
            return None

    def get_lecture_recordings(self, lecture_id: str) -> List[Dict]:
        """Get all recordings for a lecture"""
        try:
            result = self.supabase.table('session_recordings').select('*').eq('lecture_id', lecture_id).order('started_at', desc=True).execute()
            return result.data if result.data else []
        except Exception:
            return []

    def get_teacher_recordings(self, teacher_id: str) -> List[Dict]:
        """Get all recordings for a teacher"""
        try:
            result = self.supabase.table('session_recordings').select('*').eq('teacher_id', teacher_id).order('started_at', desc=True).execute()
            return result.data if result.data else []
        except Exception:
            return []

    def delete_recording(self, recording_id: str) -> Tuple[bool, str]:
        """Delete a recording"""
        try:
            self.supabase.table('session_recordings').delete().eq('id', recording_id).execute()
            return True, "Recording deleted successfully"
        except Exception as e:
            return False, str(e)

    def get_old_recordings(self, cutoff_date: str) -> List[Dict]:
        """Get recordings older than cutoff date"""
        try:
            result = self.supabase.table('session_recordings').select('*').lt('started_at', cutoff_date).execute()
            return result.data if result.data else []
        except Exception:
            return []

    def create_recording_chunk(self, recording_id: str, user_id: str, chunk_type: str, 
                              chunk_path: str, timestamp: str, file_size: int) -> Tuple[bool, str]:
        """Create a recording chunk record"""
        try:
            chunk_data = {
                'recording_id': recording_id,
                'user_id': user_id,
                'chunk_type': chunk_type,
                'chunk_path': chunk_path,
                'timestamp': timestamp,
                'file_size': file_size,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('recording_chunks').insert(chunk_data).execute()
            
            if result.data:
                return True, "Chunk saved successfully"
            else:
                return False, "Failed to save chunk"
                
        except Exception as e:
            return False, str(e)

    def get_recording_chunks(self, recording_id: str) -> List[Dict]:
        """Get all chunks for a recording"""
        try:
            result = self.supabase.table('recording_chunks').select('*').eq('recording_id', recording_id).order('timestamp').execute()
            return result.data if result.data else []
        except Exception:
            return []

    # ========================================
    # SUPER ADMIN METHODS
    # ========================================
    
    def create_super_admin(self, name: str, email: str, password_hash: str) -> Tuple[Optional[str], str]:
        """Create a new super admin"""
        try:
            if not self.supabase:
                return None, "Database not available"
                
            # Check if email already exists
            existing = self.supabase.table('super_admins').select('id').eq('email', email).execute()
            if existing.data:
                return None, "Email already registered"
            
            super_admin_data = {
                'name': name,
                'email': email,
                'password_hash': password_hash,
                'is_active': True,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('super_admins').insert(super_admin_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Super admin created successfully"
            else:
                return None, "Failed to create super admin"
                
        except Exception as e:
            return None, str(e)
    
    def get_super_admin_by_email(self, email: str) -> Optional[Dict]:
        """Get super admin by email"""
        try:
            if not self.supabase:
                return None
            result = self.supabase.table('super_admins').select('*').eq('email', email).eq('is_active', True).execute()
            return result.data[0] if result.data else None
        except Exception:
            return None

    def update_super_admin_last_login(self, super_admin_id: str) -> bool:
        """Update super admin last login timestamp"""
        try:
            if not self.supabase:
                return False
            from datetime import datetime
            result = self.supabase.table('super_admins').update({
                'last_login': datetime.utcnow().isoformat()
            }).eq('id', super_admin_id).execute()
            return len(result.data) > 0
        except Exception:
            return False

    # ========================================
    # INSTITUTION METHODS
    # ========================================
    
    def create_institution(self, name: str, domain: str, subdomain: str = None, 
                          logo_url: str = None, primary_color: str = '#007bff', 
                          secondary_color: str = '#6c757d', description: str = None,
                          contact_email: str = None, created_by: str = None) -> Tuple[Optional[str], str]:
        """Create a new institution"""
        try:
            if not self.supabase:
                return None, "Database not available"
                
            # Check if domain already exists
            existing = self.supabase.table('institutions').select('id').eq('domain', domain).execute()
            if existing.data:
                return None, "Domain already registered"
            
            institution_data = {
                'name': name,
                'domain': domain,
                'subdomain': subdomain,
                'logo_url': logo_url,
                'primary_color': primary_color,
                'secondary_color': secondary_color,
                'description': description,
                'contact_email': contact_email,
                'created_by': created_by,
                'is_active': True,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('institutions').insert(institution_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Institution created successfully"
            else:
                return None, "Failed to create institution"
                
        except Exception as e:
            return None, str(e)
    
    def get_institution_by_domain(self, domain: str) -> Optional[Dict]:
        """Get institution by domain"""
        try:
            if not self.supabase:
                return None
            result = self.supabase.table('institutions').select('*').eq('domain', domain).eq('is_active', True).execute()
            return result.data[0] if result.data else None
        except Exception:
            return None
    
    def get_institution_by_subdomain(self, subdomain: str) -> Optional[Dict]:
        """Get institution by subdomain"""
        try:
            if not self.supabase:
                return None
            result = self.supabase.table('institutions').select('*').eq('subdomain', subdomain).eq('is_active', True).execute()
            return result.data[0] if result.data else None
        except Exception:
            return None

    # ========================================
    # INSTITUTION ADMIN METHODS
    # ========================================
    
    def create_institution_admin(self, institution_id: str, name: str, email: str, 
                                password_hash: str, permissions: Dict = None) -> Tuple[Optional[str], str]:
        """Create a new institution admin"""
        try:
            if not self.supabase:
                return None, "Database not available"
                
            # Check if email already exists for this institution
            existing = self.supabase.table('institution_admins').select('id').eq('institution_id', institution_id).eq('email', email).execute()
            if existing.data:
                return None, "Email already registered for this institution"
            
            admin_data = {
                'institution_id': institution_id,
                'name': name,
                'email': email,
                'password_hash': password_hash,
                'permissions': permissions or {},
                'is_active': True,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('institution_admins').insert(admin_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Institution admin created successfully"
            else:
                return None, "Failed to create institution admin"
                
        except Exception as e:
            return None, str(e)
    
    def get_institution_admin_by_email(self, email: str) -> Optional[Dict]:
        """Get institution admin by email"""
        try:
            if not self.supabase:
                return None
            result = self.supabase.table('institution_admins').select('*').eq('email', email).eq('is_active', True).execute()
            return result.data[0] if result.data else None
        except Exception:
            return None

    # ========================================
    # ASSIGNMENT METHODS
    # ========================================
    
    def create_assignment(self, institution_id: str, cohort_id: str, teacher_id: str, 
                         title: str, description: str = None, instructions: str = None,
                         due_date: str = None, max_points: float = 100, 
                         file_url: str = None, file_name: str = None) -> Tuple[Optional[str], str]:
        """Create a new assignment"""
        try:
            if not self.supabase:
                return None, "Database not available"
            
            assignment_data = {
                'institution_id': institution_id,
                'cohort_id': cohort_id,
                'teacher_id': teacher_id,
                'title': title,
                'description': description,
                'instructions': instructions,
                'due_date': due_date,
                'max_points': max_points,
                'file_url': file_url,
                'file_name': file_name,
                'is_published': False,
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('assignments').insert(assignment_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Assignment created successfully"
            else:
                return None, "Failed to create assignment"
                
        except Exception as e:
            return None, str(e)
    
    def get_assignments_by_cohort(self, cohort_id: str) -> List[Dict]:
        """Get all assignments for a cohort"""
        try:
            if not self.supabase:
                return []
            result = self.supabase.table('assignments').select('*').eq('cohort_id', cohort_id).order('created_at', desc=True).execute()
            return result.data if result.data else []
        except Exception:
            return []

    # ========================================
    # ASSIGNMENT SUBMISSION METHODS
    # ========================================
    
    def create_assignment_submission(self, institution_id: str, assignment_id: str, 
                                   student_id: str, submission_text: str = None,
                                   file_url: str = None, file_name: str = None) -> Tuple[Optional[str], str]:
        """Create a new assignment submission"""
        try:
            if not self.supabase:
                return None, "Database not available"
            
            submission_data = {
                'institution_id': institution_id,
                'assignment_id': assignment_id,
                'student_id': student_id,
                'submission_text': submission_text,
                'file_url': file_url,
                'file_name': file_name,
                'submitted_at': datetime.now().isoformat(),
                'is_late': False
            }
            
            result = self.supabase.table('assignment_submissions').insert(submission_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Assignment submitted successfully"
            else:
                return None, "Failed to submit assignment"
                
        except Exception as e:
            return None, str(e)
    
    def get_assignment_submissions(self, assignment_id: str) -> List[Dict]:
        """Get all submissions for an assignment"""
        try:
            if not self.supabase:
                return []
            result = self.supabase.table('assignment_submissions').select('*').eq('assignment_id', assignment_id).order('submitted_at').execute()
            return result.data if result.data else []
        except Exception:
            return []

    # ========================================
    # ATTENDANCE METHODS
    # ========================================
    
    def create_attendance_record(self, institution_id: str, lecture_id: str, 
                                student_id: str, status: str = 'present',
                                joined_at: str = None, left_at: str = None,
                                notes: str = None) -> Tuple[Optional[str], str]:
        """Create an attendance record"""
        try:
            if not self.supabase:
                return None, "Database not available"
            
            attendance_data = {
                'institution_id': institution_id,
                'lecture_id': lecture_id,
                'student_id': student_id,
                'status': status,
                'joined_at': joined_at,
                'left_at': left_at,
                'notes': notes,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('attendance').insert(attendance_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Attendance recorded successfully"
            else:
                return None, "Failed to record attendance"
                
        except Exception as e:
            return None, str(e)
    
    def get_lecture_attendance(self, lecture_id: str) -> List[Dict]:
        """Get attendance for a lecture"""
        try:
            if not self.supabase:
                return []
            result = self.supabase.table('attendance').select('*').eq('lecture_id', lecture_id).execute()
            return result.data if result.data else []
        except Exception:
            return []

    # ========================================
    # NOTIFICATION METHODS
    # ========================================
    
    def create_notification(self, institution_id: str, user_id: str, user_type: str,
                           title: str, message: str, notification_type: str = 'info') -> Tuple[Optional[str], str]:
        """Create a new notification"""
        try:
            if not self.supabase:
                return None, "Database not available"
            
            notification_data = {
                'institution_id': institution_id,
                'user_id': user_id,
                'user_type': user_type,
                'title': title,
                'message': message,
                'notification_type': notification_type,
                'is_read': False,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('notifications').insert(notification_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Notification created successfully"
            else:
                return None, "Failed to create notification"
                
        except Exception as e:
            return None, str(e)
    
    def get_user_notifications(self, user_id: str, is_read: bool = None) -> List[Dict]:
        """Get notifications for a user"""
        try:
            if not self.supabase:
                return []
            
            query = self.supabase.table('notifications').select('*').eq('user_id', user_id)
            if is_read is not None:
                query = query.eq('is_read', is_read)
            
            result = query.order('created_at', desc=True).execute()
            return result.data if result.data else []
        except Exception:
            return []

    # ========================================
    # DISCUSSION FORUM METHODS
    # ========================================
    
    def create_discussion_forum(self, institution_id: str, cohort_id: str, 
                               title: str, description: str = None, 
                               created_by: str = None) -> Tuple[Optional[str], str]:
        """Create a new discussion forum"""
        try:
            if not self.supabase:
                return None, "Database not available"
            
            forum_data = {
                'institution_id': institution_id,
                'cohort_id': cohort_id,
                'title': title,
                'description': description,
                'is_active': True,
                'created_by': created_by,
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('discussion_forums').insert(forum_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Discussion forum created successfully"
            else:
                return None, "Failed to create discussion forum"
                
        except Exception as e:
            return None, str(e)
    
    def create_discussion_post(self, institution_id: str, forum_id: str, 
                              author_id: str, author_type: str, content: str,
                              title: str = None, parent_post_id: str = None) -> Tuple[Optional[str], str]:
        """Create a new discussion post"""
        try:
            if not self.supabase:
                return None, "Database not available"
            
            post_data = {
                'institution_id': institution_id,
                'forum_id': forum_id,
                'parent_post_id': parent_post_id,
                'author_id': author_id,
                'author_type': author_type,
                'title': title,
                'content': content,
                'is_pinned': False,
                'is_locked': False,
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('discussion_posts').insert(post_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Discussion post created successfully"
            else:
                return None, "Failed to create discussion post"
                
        except Exception as e:
            return None, str(e)
    
    def get_forum_posts(self, forum_id: str) -> List[Dict]:
        """Get all posts for a forum"""
        try:
            if not self.supabase:
                return []
            result = self.supabase.table('discussion_posts').select('*').eq('forum_id', forum_id).order('created_at', desc=True).execute()
            return result.data if result.data else []
        except Exception:
            return []

    # ========================================
    # GRADEBOOK METHODS
    # ========================================
    
    def create_gradebook_entry(self, institution_id: str, student_id: str, cohort_id: str,
                              teacher_id: str, grade_type: str, points_earned: float, points_possible: float,
                              assignment_id: str = None, quiz_id: str = None,
                              feedback: str = None, graded_by: str = None) -> Tuple[Optional[str], str]:
        """Create a new gradebook entry"""
        try:
            if not self.supabase:
                return None, "Database not available"
            
            percentage = (points_earned / points_possible * 100) if points_possible > 0 else 0
            
            # Determine letter grade based on percentage
            if percentage >= 90:
                letter_grade = 'A'
            elif percentage >= 80:
                letter_grade = 'B'
            elif percentage >= 70:
                letter_grade = 'C'
            elif percentage >= 60:
                letter_grade = 'D'
            else:
                letter_grade = 'F'
            
            gradebook_data = {
                'institution_id': institution_id,
                'student_id': student_id,
                'cohort_id': cohort_id,
                'teacher_id': teacher_id,
                'assignment_id': assignment_id,
                'quiz_id': quiz_id,
                'grade_type': grade_type,
                'points_earned': points_earned,
                'points_possible': points_possible,
                'percentage': percentage,
                'letter_grade': letter_grade,
                'feedback': feedback,
                'graded_by': graded_by,
                'graded_at': datetime.now().isoformat(),
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('gradebook').insert(gradebook_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Gradebook entry created successfully"
            else:
                return None, "Failed to create gradebook entry"
                
        except Exception as e:
            return None, str(e)
    
    def get_student_grades(self, student_id: str, cohort_id: str = None) -> List[Dict]:
        """Get grades for a student"""
        try:
            if not self.supabase:
                return []
            
            query = self.supabase.table('gradebook').select('*').eq('student_id', student_id)
            if cohort_id:
                query = query.eq('cohort_id', cohort_id)
            
            result = query.order('created_at', desc=True).execute()
            return result.data if result.data else []
        except Exception:
            return []

    # ========================================
    # SYSTEM SETTINGS METHODS
    # ========================================
    
    def create_system_setting(self, institution_id: str, setting_key: str, 
                             setting_value: str, setting_type: str = 'string',
                             description: str = None, is_public: bool = False) -> Tuple[Optional[str], str]:
        """Create a new system setting"""
        try:
            if not self.supabase:
                return None, "Database not available"
            
            setting_data = {
                'institution_id': institution_id,
                'setting_key': setting_key,
                'setting_value': setting_value,
                'setting_type': setting_type,
                'description': description,
                'is_public': is_public,
                'created_at': datetime.now().isoformat(),
                'updated_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('system_settings').insert(setting_data).execute()
            
            if result.data:
                return result.data[0]['id'], "System setting created successfully"
            else:
                return None, "Failed to create system setting"
                
        except Exception as e:
            return None, str(e)
    
    def get_system_setting(self, institution_id: str, setting_key: str) -> Optional[Dict]:
        """Get a system setting"""
        try:
            if not self.supabase:
                return None
            result = self.supabase.table('system_settings').select('*').eq('institution_id', institution_id).eq('setting_key', setting_key).execute()
            return result.data[0] if result.data else None
        except Exception:
            return None


# Create a global instance for compatibility
DatabaseManager = SupabaseDatabaseManager
