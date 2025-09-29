# utils/database_supabase.py
import os
import json
import uuid
from datetime import datetime
from typing import Optional, Tuple, List, Dict, Any
from supabase import create_client, Client
from dotenv import load_dotenv
load_dotenv()  # Load environment variables before importing config
from config import Config

class SupabaseDatabaseManager:
    def __init__(self):
        self.supabase_url = Config.SUPABASE_URL
        self.supabase_key = Config.SUPABASE_KEY
        
        # Check if we're in development mode with placeholder values
        if (self.supabase_url == 'https://placeholder.supabase.co' or 
            self.supabase_key == 'placeholder-key' or
            self.supabase_url == 'your-supabase-url' or
            self.supabase_key == 'your-supabase-key' or
            self.supabase_url == 'https://demo.supabase.co' or
            self.supabase_key == 'demo-key'):
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
    
    def get_teacher_by_email_and_institution(self, email: str, institution_id: str) -> Optional[Dict]:
        """Get teacher by email and institution ID"""
        try:
            result = self.supabase.table('teachers').select('*').eq('email', email).eq('institution_id', institution_id).eq('is_active', True).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting teacher by email and institution: {e}")
            return None
    
    def get_teacher_by_id(self, teacher_id: str, active_only: bool = True) -> Optional[Dict]:
        """Get teacher by ID"""
        try:
            query = self.supabase.table('teachers').select('*').eq('id', teacher_id)
            if active_only:
                query = query.eq('is_active', True)
            result = query.execute()
            return result.data[0] if result.data else None
        except Exception:
            return None
    
    def update_teacher_last_login(self, teacher_id: str) -> bool:
        """Update teacher's last login time"""
        try:
            if not self.supabase:
                return False
            self.supabase.table('teachers').update({
                'last_login': datetime.now().isoformat()
            }).eq('id', teacher_id).execute()
            return True
        except Exception as e:
            print(f"Error updating teacher last login: {e}")
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
    
    def get_student_by_email_and_institution(self, email: str, institution_id: str) -> Optional[Dict]:
        """Get student by email and institution ID"""
        try:
            result = self.supabase.table('students').select('*').eq('email', email).eq('institution_id', institution_id).eq('is_active', True).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting student by email and institution: {e}")
            return None
    
    def get_student_by_id(self, student_id: str, active_only: bool = True) -> Optional[Dict]:
        """Get student by ID"""
        try:
            query = self.supabase.table('students').select('*').eq('id', student_id)
            if active_only:
                query = query.eq('is_active', True)
            result = query.execute()
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
            # Get teacher details to find required fields
            teacher_result = self.supabase.table('teachers').select('institution_id').eq('id', teacher_id).execute()
            if not teacher_result.data:
                return None, "Teacher not found"
            
            teacher = teacher_result.data[0]
            
            lecture_data = {
                'institution_id': teacher['institution_id'],
                'teacher_id': teacher_id,
                'title': title,
                'description': description,
                'scheduled_time': scheduled_time,
                'duration': duration,
                'status': 'scheduled',
                'recording_enabled': True,
                'chat_enabled': True,
                'max_participants': 100,
                'is_active': True,
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
    
    def get_lecture_by_id(self, lecture_id: str, active_only: bool = True) -> Optional[Dict]:
        """Get lecture by ID"""
        try:
            query = self.supabase.table('lectures').select('*').eq('id', lecture_id)
            if active_only:
                query = query.eq('is_active', True)
            result = query.execute()
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
            # Get lecture details to find required fields
            lecture_result = self.supabase.table('lectures').select('institution_id, cohort_id, teacher_id').eq('id', lecture_id).execute()
            if not lecture_result.data:
                return None, "Lecture not found"
            
            lecture = lecture_result.data[0]
            
            material_data = {
                'institution_id': lecture['institution_id'],
                'lecture_id': lecture_id,
                'cohort_id': lecture['cohort_id'],
                'teacher_id': lecture['teacher_id'],
                'title': title,
                'description': description,
                'file_path': file_path,
                'file_name': file_path.split('/')[-1],  # Extract filename from path
                'file_type': file_type,
                'file_size': file_size,
                'is_public': False,
                'download_count': 0,
                'is_active': True,
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
            # This method is deprecated - quizzes should be created through quiz_sets
            # For now, we'll create a simple quiz_set and add the question
            # First, get the lecture details to find cohort and teacher
            lecture_result = self.supabase.table('lectures').select('cohort_id, teacher_id, institution_id').eq('id', lecture_id).execute()
            if not lecture_result.data:
                return None, "Lecture not found"
            
            lecture = lecture_result.data[0]
            
            # Create a quiz set for this lecture
            quiz_set_data = {
                'institution_id': lecture['institution_id'],
                'cohort_id': lecture['cohort_id'],
                'teacher_id': lecture['teacher_id'],
                'title': f"Quiz for Lecture {lecture_id}",
                'description': "Auto-generated quiz",
                'is_active': True,
                'created_at': datetime.now().isoformat()
            }
            quiz_set_result = self.supabase.table('quiz_sets').insert(quiz_set_data).execute()
            
            if quiz_set_result.data:
                quiz_set_id = quiz_set_result.data[0]['id']
                
                # Add the question to the quiz set - use minimal fields to avoid schema cache issues
                question_data = {
                    'quiz_set_id': quiz_set_id,
                    'question_text': question,
                    'question_type': 'multiple_choice'
                }
                
                # Only add optional fields if they have values
                if options:
                    question_data['options'] = options
                if correct_answer:
                    question_data['correct_answer'] = correct_answer
                
                result = self.supabase.table('quizzes').insert(question_data).execute()
                
                if result.data:
                    return result.data[0]['id'], "Quiz created successfully"
                else:
                    return None, "Failed to create quiz question"
            else:
                return None, "Failed to create quiz set"
                
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
    
    def get_cohort_by_id(self, cohort_id: str, active_only: bool = True) -> Optional[Dict]:
        """Get cohort by ID"""
        try:
            query = self.supabase.table('cohorts').select('*').eq('id', cohort_id)
            if active_only:
                query = query.eq('is_active', True)
            result = query.execute()
            return result.data[0] if result.data else None
        except Exception:
            return None
    
    
    def get_lectures_by_teacher(self, teacher_id: str) -> List[Dict]:
        """Get lectures for a teacher"""
        try:
            if not self.supabase:
                return []
            result = self.supabase.table('lectures').select('*').eq('teacher_id', teacher_id).eq('is_active', True).order('scheduled_time', desc=True).execute()
            return result.data
        except Exception as e:
            print(f"Error getting teacher lectures: {e}")
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
    
    def get_lectures_by_cohort(self, cohort_id: str) -> List[Dict]:
        """Get lectures for a cohort (alias for get_cohort_lectures)"""
        return self.get_cohort_lectures(cohort_id)
    
    def enroll_student_in_cohort(self, institution_id: str, student_id: str, cohort_id: str, enrolled_by: str = None) -> bool:
        """Enroll a student in a cohort"""
        try:
            if not self.supabase:
                return False
            # Check if already enrolled
            existing = self.supabase.table('enrollments').select('id').eq('student_id', student_id).eq('cohort_id', cohort_id).execute()
            if existing.data:
                return True  # Already enrolled
            
            enrollment_data = {
                'institution_id': institution_id,
                'student_id': student_id,
                'cohort_id': cohort_id,
                'enrolled_at': datetime.now().isoformat(),
                'is_active': True
            }
            
            # Note: enrolled_by and status columns don't exist in actual Supabase schema
            # lecture_id is available but not used for cohort enrollments
            
            result = self.supabase.table('enrollments').insert(enrollment_data).execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error enrolling student in cohort: {e}")
            return False

    def remove_student_from_cohort(self, student_id: str, cohort_id: str) -> bool:
        """Remove a student from a cohort"""
        try:
            if not self.supabase:
                return False
            
            result = self.supabase.table('enrollments').update({
                'is_active': False,
                'status': 'inactive'
            }).eq('student_id', student_id).eq('cohort_id', cohort_id).execute()
            
            return bool(result.data)
        except Exception as e:
            print(f"Error removing student from cohort: {e}")
            return False

    def assign_teacher_to_cohort(self, teacher_id: str, cohort_id: str, role: str = 'teacher', assigned_by: str = None) -> bool:
        """Assign a teacher to a cohort"""
        try:
            if not self.supabase:
                return False
            
            # Check if already assigned
            existing = self.supabase.table('teacher_cohorts').select('id').eq('teacher_id', teacher_id).eq('cohort_id', cohort_id).execute()
            if existing.data:
                return True  # Already assigned
            
            assignment_data = {
                'teacher_id': teacher_id,
                'cohort_id': cohort_id,
                'role': role,
                'assigned_at': datetime.now().isoformat(),
                'assigned_by': assigned_by
            }
            
            result = self.supabase.table('teacher_cohorts').insert(assignment_data).execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error assigning teacher to cohort: {e}")
            return False

    def remove_teacher_from_cohort(self, teacher_id: str, cohort_id: str) -> bool:
        """Remove a teacher from a cohort"""
        try:
            if not self.supabase:
                return False
            
            result = self.supabase.table('cohort_teachers').update({
                'is_active': False
            }).eq('teacher_id', teacher_id).eq('cohort_id', cohort_id).execute()
            
            return bool(result.data)
        except Exception as e:
            print(f"Error removing teacher from cohort: {e}")
            return False

    def get_cohort_teachers(self, cohort_id: str) -> List[Dict]:
        """Get teachers assigned to a cohort"""
        try:
            if not self.supabase:
                return []
            
            result = self.supabase.table('teacher_cohorts').select(
                '*, teachers!inner(*)'
            ).eq('cohort_id', cohort_id).execute()
            
            teachers = []
            for assignment in result.data:
                teacher_data = assignment.get('teachers', {})
                teacher_data['assigned_at'] = assignment.get('assigned_at')
                teacher_data['role'] = assignment.get('role')
                teachers.append(teacher_data)
            
            return teachers
        except Exception as e:
            print(f"Error getting cohort teachers: {e}")
            return []

    def get_cohort_students(self, cohort_id: str) -> List[Dict]:
        """Get students enrolled in a cohort"""
        try:
            if not self.supabase:
                return []
            
            result = self.supabase.table('enrollments').select(
                '*, students!inner(*)'
            ).eq('cohort_id', cohort_id).eq('is_active', True).execute()
            
            students = []
            for enrollment in result.data:
                student_data = enrollment.get('students', {})
                student_data['enrolled_at'] = enrollment.get('enrolled_at')
                student_data['enrollment_status'] = enrollment.get('status')
                students.append(student_data)
            
            return students
        except Exception as e:
            print(f"Error getting cohort students: {e}")
            return []

    def get_teacher_cohorts(self, teacher_id: str) -> List[Dict]:
        """Get cohorts assigned to a teacher"""
        try:
            if not self.supabase:
                print("Database not available")
                return []
            
            print(f"Getting cohorts for teacher: {teacher_id}")
            
            # Check if teacher is directly assigned to cohorts
            try:
                result = self.supabase.table('cohorts').select('*').eq('teacher_id', teacher_id).eq('is_active', True).execute()
                print(f"Direct assignment query result: {len(result.data) if result.data else 0} records")
                
                if result.data:
                    return result.data
            except Exception as e:
                print(f"Direct assignment query failed: {e}")
            
            # If no assignments found, return empty list
            print("No cohorts found for teacher")
            return []
            
        except Exception as e:
            print(f"Error getting teacher cohorts: {e}")
            return []

    def get_student_cohorts(self, student_id: str) -> List[Dict]:
        """Get cohorts enrolled by a student"""
        try:
            if not self.supabase:
                return []
            
            result = self.supabase.table('enrollments').select(
                '*, cohorts!inner(*)'
            ).eq('student_id', student_id).eq('is_active', True).execute()
            
            cohorts = []
            for enrollment in result.data:
                cohort_data = enrollment.get('cohorts', {})
                cohort_data['enrolled_at'] = enrollment.get('enrolled_at')
                cohort_data['enrollment_status'] = enrollment.get('status')
                cohorts.append(cohort_data)
            
            return cohorts
        except Exception as e:
            print(f"Error getting student cohorts: {e}")
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
    
    def get_institution_public_stats(self, institution_id: str) -> Dict[str, Any]:
        """Get public statistics for an institution"""
        if not self.supabase:
            return {
                'total_users': 0,
                'teachers': 0,
                'students': 0,
                'cohorts': 0
            }
        try:
            # Get user counts for this institution
            teachers_result = self.supabase.table('teachers').select('id', count='exact').eq('institution_id', institution_id).eq('is_active', True).execute()
            students_result = self.supabase.table('students').select('id', count='exact').eq('institution_id', institution_id).eq('is_active', True).execute()
            cohorts_result = self.supabase.table('cohorts').select('id', count='exact').eq('institution_id', institution_id).eq('is_active', True).execute()
            
            return {
                'total_users': (teachers_result.count or 0) + (students_result.count or 0),
                'teachers': teachers_result.count or 0,
                'students': students_result.count or 0,
                'cohorts': cohorts_result.count or 0
            }
        except Exception as e:
            print(f"Error getting institution public stats: {e}")
            return {
                'total_users': 0,
                'teachers': 0,
                'students': 0,
                'cohorts': 0
            }

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


    # Institution Management Methods
    def get_all_institutions(self) -> List[Dict[str, Any]]:
        """Get all institutions"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('institutions').select('*').execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting institutions: {e}")
            return []
    
    def get_institution_by_id(self, institution_id: str) -> Optional[Dict[str, Any]]:
        """Get institution by ID"""
        if not self.supabase:
            return None
        try:
            result = self.supabase.table('institutions').select('*').eq('id', institution_id).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting institution: {e}")
            return None
    
    def create_institution(self, name: str, domain: str, subdomain: str = None, 
                          logo_url: str = None, primary_color: str = '#007bff',
                          secondary_color: str = '#6c757d', description: str = None,
                          contact_email: str = None, created_by: str = None) -> Optional[str]:
        """Create a new institution"""
        if not self.supabase:
            return None
        try:
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
            return result.data[0]['id'] if result.data else None
        except Exception as e:
            print(f"Error creating institution: {e}")
            return None
    
    def get_platform_stats(self) -> Dict[str, Any]:
        """Get platform-wide statistics"""
        if not self.supabase:
            return {
                'institutions': 0,
                'total_users': 0,
                'teachers': 0,
                'students': 0,
                'active_lectures': 0,
                'total_quizzes': 0
            }
        try:
            # Get institution count
            institutions_result = self.supabase.table('institutions').select('id', count='exact').execute()
            
            # Get user counts
            teachers_result = self.supabase.table('teachers').select('id', count='exact').execute()
            students_result = self.supabase.table('students').select('id', count='exact').execute()
            
            # Get lecture count
            lectures_result = self.supabase.table('lectures').select('id', count='exact').execute()
            
            return {
                'institutions': institutions_result.count or 0,
                'total_users': (teachers_result.count or 0) + (students_result.count or 0),
                'teachers': teachers_result.count or 0,
                'students': students_result.count or 0,
                'active_lectures': lectures_result.count or 0,
                'total_quizzes': 0  # Placeholder
            }
        except Exception as e:
            print(f"Error getting platform stats: {e}")
            return {
                'institutions': 0,
                'total_users': 0,
                'teachers': 0,
                'students': 0,
                'active_lectures': 0,
                'total_quizzes': 0
            }
    
    def update_institution(self, institution_id: str, **kwargs) -> bool:
        """Update institution details"""
        if not self.supabase:
            return False
        try:
            # Remove None values and prepare update data
            update_data = {k: v for k, v in kwargs.items() if v is not None}
            update_data['updated_at'] = datetime.now().isoformat()
            
            result = self.supabase.table('institutions').update(update_data).eq('id', institution_id).execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error updating institution: {e}")
            return False
    
    def deactivate_institution(self, institution_id: str) -> bool:
        """Deactivate an institution"""
        if not self.supabase:
            return False
        try:
            result = self.supabase.table('institutions').update({
                'is_active': False,
                'updated_at': datetime.now().isoformat()
            }).eq('id', institution_id).execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error deactivating institution: {e}")
            return False
    
    def update_institution_status(self, institution_id: str, is_active: bool) -> bool:
        """Update institution active status"""
        if not self.supabase:
            return False
        try:
            result = self.supabase.table('institutions').update({
                'is_active': is_active,
                'updated_at': datetime.now().isoformat()
            }).eq('id', institution_id).execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error updating institution status: {e}")
            return False
    
    def delete_institution(self, institution_id: str) -> bool:
        """Delete an institution"""
        if not self.supabase:
            return False
        try:
            result = self.supabase.table('institutions').delete().eq('id', institution_id).execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error deleting institution: {e}")
            return False
    
    def get_all_super_admins(self) -> List[Dict[str, Any]]:
        """Get all super admins"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('super_admins').select('*').execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting super admins: {e}")
            return []
    
    def get_super_admin_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Get super admin by email"""
        if not self.supabase:
            return None
        try:
            result = self.supabase.table('super_admins').select('*').eq('email', email).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting super admin: {e}")
            return None
    
    def create_super_admin(self, name: str, email: str, password_hash: str) -> Optional[str]:
        """Create a new super admin"""
        if not self.supabase:
            return None
        try:
            super_admin_data = {
                'name': name,
                'email': email,
                'password_hash': password_hash,
                'is_active': True,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('super_admins').insert(super_admin_data).execute()
            return result.data[0]['id'] if result.data else None
        except Exception as e:
            print(f"Error creating super admin: {e}")
            return None
    
    def get_super_admin_by_id(self, admin_id: str) -> Optional[Dict[str, Any]]:
        """Get super admin by ID"""
        if not self.supabase:
            return None
        try:
            result = self.supabase.table('super_admins').select('*').eq('id', admin_id).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting super admin: {e}")
            return None
    
    def update_super_admin_status(self, admin_id: str, is_active: bool) -> bool:
        """Update super admin active status"""
        if not self.supabase:
            return False
        try:
            result = self.supabase.table('super_admins').update({
                'is_active': is_active,
                'updated_at': datetime.now().isoformat()
            }).eq('id', admin_id).execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error updating super admin status: {e}")
            return False
    
    def get_platform_analytics(self) -> Dict[str, Any]:
        """Get platform analytics data"""
        if not self.supabase:
            return {
                'growth_labels': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                'growth_data': [0, 0, 0, 0, 0, 0],
                'user_counts': {
                    'teachers': 0,
                    'students': 0,
                    'admins': 0
                }
            }
        try:
            # This is a simplified version - you can expand this
            # to include more complex analytics based on your needs
            return {
                'growth_labels': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                'growth_data': [0, 1, 2, 3, 5, 8],  # Placeholder data
                'user_counts': {
                    'teachers': 0,
                    'students': 0,
                    'admins': 0
                }
            }
        except Exception as e:
            print(f"Error getting platform analytics: {e}")
            return {
                'growth_labels': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'],
                'growth_data': [0, 1, 2, 3, 5, 8],
                'user_counts': {
                    'teachers': 0,
                    'students': 0,
                    'admins': 0
                }
            }
    
    def get_institution_stats(self, institution_id: str) -> Dict[str, Any]:
        """Get statistics for a specific institution"""
        if not self.supabase:
            return {
                'total_users': 0,
                'teachers': 0,
                'students': 0,
                'cohorts': 0,
                'lectures': 0
            }
        try:
            # Get active user counts for this institution
            teachers_result = self.supabase.table('teachers').select('id', count='exact').eq('institution_id', institution_id).eq('is_active', True).execute()
            students_result = self.supabase.table('students').select('id', count='exact').eq('institution_id', institution_id).eq('is_active', True).execute()
            
            # Get active cohort count for this institution
            cohorts_result = self.supabase.table('cohorts').select('id', count='exact').eq('institution_id', institution_id).eq('is_active', True).execute()
            
            # Get active lecture count for this institution
            lectures_result = self.supabase.table('lectures').select('id', count='exact').eq('institution_id', institution_id).eq('is_active', True).execute()
            
            return {
                'total_users': (teachers_result.count or 0) + (students_result.count or 0),
                'teachers': teachers_result.count or 0,
                'students': students_result.count or 0,
                'cohorts': cohorts_result.count or 0,
                'lectures': lectures_result.count or 0
            }
        except Exception as e:
            print(f"Error getting institution stats: {e}")
            return {
                'total_users': 0,
                'teachers': 0,
                'students': 0,
                'cohorts': 0,
                'lectures': 0
            }
    
    # Institution Admin Management Methods
    def get_institution_admins(self, institution_id: str) -> List[Dict[str, Any]]:
        """Get all institution admins for a specific institution"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('institution_admins').select('*').eq('institution_id', institution_id).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting institution admins: {e}")
            return []
    
    def get_institution_admin_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Get institution admin by email"""
        if not self.supabase:
            return None
        try:
            result = self.supabase.table('institution_admins').select('*').eq('email', email).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting institution admin: {e}")
            return None
    
    def get_institution_admin_by_email_and_institution(self, email: str, institution_id: str) -> Optional[Dict[str, Any]]:
        """Get institution admin by email and institution ID"""
        if not self.supabase:
            return None
        try:
            result = self.supabase.table('institution_admins').select('*').eq('email', email).eq('institution_id', institution_id).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting institution admin by email and institution: {e}")
            return None
    
    def update_institution_admin_last_login(self, admin_id: str) -> bool:
        """Update institution admin last login timestamp"""
        if not self.supabase:
            return False
        try:
            result = self.supabase.table('institution_admins').update({
                'last_login': datetime.now().isoformat()
            }).eq('id', admin_id).execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error updating institution admin last login: {e}")
            return False
    
    def log_user_activity(self, user_id: str, user_type: str, action: str, institution_id: str = None, resource_type: str = None, details: dict = None) -> bool:
        """Log user activity"""
        if not self.supabase:
            return False
        try:
            activity_data = {
                'user_id': user_id,
                'user_type': user_type,
                'action': action,
                'institution_id': institution_id,
                'resource_type': resource_type,
                'details': details,
                'timestamp': datetime.now().isoformat()
            }
            result = self.supabase.table('activity_logs').insert(activity_data).execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error logging user activity: {e}")
            return False
    
    def create_institution_admin(self, institution_id: str, name: str, email: str, password_hash: str, 
                                role: str = 'admin', permissions: Dict = None) -> Optional[str]:
        """Create a new institution admin"""
        if not self.supabase:
            return None
        try:
            if permissions is None:
                permissions = {
                    "manage_teachers": True,
                    "manage_students": True,
                    "manage_cohorts": True,
                    "view_analytics": True,
                    "manage_materials": False,
                    "manage_quizzes": False
                }
            
            admin_data = {
                'institution_id': institution_id,
                'name': name,
                'email': email,
                'password_hash': password_hash,
                'role': role,
                'permissions': permissions,
                'is_active': True,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('institution_admins').insert(admin_data).execute()
            return result.data[0]['id'] if result.data else None
        except Exception as e:
            print(f"Error creating institution admin: {e}")
            return None
    
    # Teacher Management Methods (Updated for new schema)
    def get_teachers_by_institution(self, institution_id: str) -> List[Dict[str, Any]]:
        """Get all active teachers for a specific institution"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('teachers').select('*').eq('institution_id', institution_id).eq('is_active', True).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting teachers: {e}")
            return []
    
    def create_teacher(self, institution_id: str, name: str, email: str, subject: str, 
                      password_hash: str, employee_id: str = None, department: str = None,
                      phone: str = None, bio: str = None, created_by: str = None) -> Tuple[Optional[str], str]:
        """Create a new teacher"""
        if not self.supabase:
            return None, "Database not available"
        try:
            # Check if email already exists in this institution
            existing = self.supabase.table('teachers').select('id').eq('institution_id', institution_id).eq('email', email).execute()
            if existing.data:
                return None, "Email already registered in this institution"
            
            teacher_data = {
                'institution_id': institution_id,
                'name': name,
                'email': email,
                'password_hash': password_hash,
                'subject': subject,
                'created_by': created_by,
                'is_active': True,
                'created_at': datetime.now().isoformat()
            }
            
            # Note: The following columns don't exist in the actual Supabase schema:
            # employee_id, department, phone, bio
            # These parameters are accepted but not stored in the database
            
            result = self.supabase.table('teachers').insert(teacher_data).execute()
            return result.data[0]['id'] if result.data else None, "Teacher created successfully"
        except Exception as e:
            print(f"Error creating teacher: {e}")
            return None, str(e)
    
    # Student Management Methods (Updated for new schema)
    def get_students_by_institution(self, institution_id: str) -> List[Dict[str, Any]]:
        """Get all active students for a specific institution"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('students').select('*').eq('institution_id', institution_id).eq('is_active', True).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting students: {e}")
            return []
    
    def create_student(self, institution_id: str, name: str, email: str, password_hash: str,
                      student_id: str = None, roll_number: str = None, class_name: str = None,
                      section: str = None, phone: str = None, parent_phone: str = None,
                      date_of_birth: str = None, created_by: str = None) -> Tuple[Optional[str], str]:
        """Create a new student"""
        if not self.supabase:
            return None, "Database not available"
        try:
            # Check if email already exists in this institution
            existing = self.supabase.table('students').select('id').eq('institution_id', institution_id).eq('email', email).execute()
            if existing.data:
                return None, "Email already registered in this institution"
            
            student_data = {
                'institution_id': institution_id,
                'name': name,
                'email': email,
                'password_hash': password_hash,
                'created_by': created_by,
                'is_active': True,
                'created_at': datetime.now().isoformat()
            }
            
            # Note: The following columns don't exist in the actual Supabase schema:
            # student_id, roll_number, class, section, phone, parent_phone, date_of_birth
            # These parameters are accepted but not stored in the database
            
            result = self.supabase.table('students').insert(student_data).execute()
            return result.data[0]['id'] if result.data else None, "Student created successfully"
        except Exception as e:
            print(f"Error creating student: {e}")
            return None, str(e)
    
    # Cohort Management Methods (Updated for new schema)
    def get_cohorts_by_institution(self, institution_id: str) -> List[Dict[str, Any]]:
        """Get all active cohorts for a specific institution with student and teacher counts"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('cohorts').select('*').eq('institution_id', institution_id).eq('is_active', True).execute()
            cohorts = result.data if result.data else []
            
            # Add student and teacher counts for each cohort
            for cohort in cohorts:
                cohort_id = cohort['id']
                
                # Get student count
                student_count = self.supabase.table('enrollments').select('id', count='exact').eq('cohort_id', cohort_id).eq('is_active', True).execute()
                cohort['student_count'] = student_count.count if student_count.count else 0
                
                # Get teacher count
                teacher_count = self.supabase.table('teacher_cohorts').select('id', count='exact').eq('cohort_id', cohort_id).execute()
                cohort['teacher_count'] = teacher_count.count if teacher_count.count else 0
            
            return cohorts
        except Exception as e:
            print(f"Error getting cohorts: {e}")
            return []
    
    def create_cohort(self, institution_id: str, name: str, description: str = None,
                     enrollment_code: str = None, max_students: int = 50,
                     academic_year: str = None, semester: str = None, session: str = None,
                     start_date: str = None, end_date: str = None, subject: str = "General",
                     created_by: str = None) -> Tuple[Optional[str], str]:
        """Create a new cohort"""
        if not self.supabase:
            return None, "Database not available"
        try:
            # Generate enrollment code if not provided
            if not enrollment_code:
                enrollment_code = f"COHORT-{datetime.now().strftime('%Y%m%d%H%M%S')}"
            
            # Generate join code if not provided (required field)
            join_code = f"JOIN-{datetime.now().strftime('%Y%m%d%H%M%S')}"
            
            cohort_data = {
                'institution_id': institution_id,
                'name': name,
                'description': description,
                'enrollment_code': enrollment_code,
                'join_code': join_code,  # Required field in actual schema
                'academic_year': academic_year,
                'subject': subject,  # Required field in actual schema
                'created_by': created_by,
                'is_active': True,
                'created_at': datetime.now().isoformat()
            }
            
            # Note: The following columns don't exist in the actual Supabase schema:
            # max_students, semester, start_date, end_date, session
            # These parameters are accepted but not stored in the database
            
            result = self.supabase.table('cohorts').insert(cohort_data).execute()
            return result.data[0]['id'] if result.data else None, "Cohort created successfully"
        except Exception as e:
            print(f"Error creating cohort: {e}")
            return None, str(e)
    
    # Lecture Management Methods (Updated for new schema)
    def get_lectures_by_institution(self, institution_id: str) -> List[Dict[str, Any]]:
        """Get all active lectures for a specific institution with teacher and cohort names"""
        if not self.supabase:
            return []
        try:
            # First get all lectures
            result = self.supabase.table('lectures').select('*').eq('institution_id', institution_id).eq('is_active', True).execute()
            
            lectures = []
            for lecture in result.data:
                # Get teacher name
                teacher_id = lecture.get('teacher_id')
                teacher_name = 'N/A'
                teacher_email = 'N/A'
                if teacher_id:
                    try:
                        teacher_result = self.supabase.table('teachers').select('name, email').eq('id', teacher_id).execute()
                        if teacher_result.data:
                            teacher_data = teacher_result.data[0]
                            teacher_name = teacher_data.get('name', 'N/A')
                            teacher_email = teacher_data.get('email', 'N/A')
                    except:
                        pass
                
                # Get cohort name
                cohort_id = lecture.get('cohort_id')
                cohort_name = 'N/A'
                if cohort_id:
                    try:
                        cohort_result = self.supabase.table('cohorts').select('name').eq('id', cohort_id).execute()
                        if cohort_result.data:
                            cohort_name = cohort_result.data[0].get('name', 'N/A')
                    except:
                        pass
                
                # Add the names to the lecture data
                lecture['teacher_name'] = teacher_name
                lecture['teacher_email'] = teacher_email
                lecture['cohort_name'] = cohort_name
                
                lectures.append(lecture)
            
            return lectures
        except Exception as e:
            print(f"Error getting lectures: {e}")
            return []
    
    def create_lecture(self, institution_id: str, cohort_id: str, teacher_id: str, title: str,
                      description: str = None, scheduled_time: str = None, duration: int = 60,
                      lecture_type: str = 'live', meeting_link: str = None, meeting_id: str = None, 
                      meeting_password: str = None, recording_enabled: bool = True, chat_enabled: bool = True,
                      max_participants: int = 100, created_by: str = None) -> Tuple[Optional[str], str]:
        """Create a new lecture"""
        if not self.supabase:
            return None, "Database not available"
        try:
            lecture_data = {
                'institution_id': institution_id,
                'cohort_id': cohort_id,
                'teacher_id': teacher_id,
                'title': title,
                'description': description,
                'scheduled_time': scheduled_time or datetime.now().isoformat(),
                'duration': duration,
                'status': 'scheduled',
                'is_active': True,
                'created_at': datetime.now().isoformat()
            }
            
            # Note: The following columns don't exist in the actual Supabase schema:
            # meeting_link, meeting_id, meeting_password, recording_enabled, chat_enabled, 
            # max_participants, lecture_type, created_by
            # These parameters are accepted but not stored in the database
            
            result = self.supabase.table('lectures').insert(lecture_data).execute()
            return result.data[0]['id'] if result.data else None, "Lecture created successfully"
        except Exception as e:
            print(f"Error creating lecture: {e}")
            return None, str(e)
    
    # Additional methods needed for the new routes
    def get_cohort_by_enrollment_code(self, enrollment_code: str) -> Optional[Dict[str, Any]]:
        """Get cohort by enrollment code"""
        if not self.supabase:
            return None
        try:
            result = self.supabase.table('cohorts').select('*').eq('enrollment_code', enrollment_code).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting cohort by enrollment code: {e}")
            return None
    
    def get_materials_by_cohorts(self, cohort_ids: List[str]) -> List[Dict[str, Any]]:
        """Get materials for specific cohorts"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('materials').select('*').in_('cohort_id', cohort_ids).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting materials by cohorts: {e}")
            return []
    
    def get_quiz_sets_by_cohorts(self, cohort_ids: List[str]) -> List[Dict[str, Any]]:
        """Get quiz sets for specific cohorts"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('quiz_sets').select('*').in_('cohort_id', cohort_ids).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting quiz sets by cohorts: {e}")
            return []
    
    def get_quiz_set_by_id(self, quiz_set_id: str) -> Optional[Dict[str, Any]]:
        """Get quiz set by ID"""
        if not self.supabase:
            return None
        try:
            result = self.supabase.table('quiz_sets').select('*').eq('id', quiz_set_id).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting quiz set: {e}")
            return None
    
    def start_quiz_attempt(self, student_id: str, quiz_set_id: str) -> Tuple[Optional[str], str]:
        """Start a new quiz attempt"""
        if not self.supabase:
            return None, "Database not available"
        try:
            # Get attempt number
            attempts_result = self.supabase.table('quiz_attempts').select('attempt_number').eq('student_id', student_id).eq('quiz_set_id', quiz_set_id).execute()
            attempt_number = len(attempts_result.data) + 1 if attempts_result.data else 1
            
            attempt_data = {
                'quiz_set_id': quiz_set_id,
                'student_id': student_id,
                'started_at': datetime.now().isoformat(),
                'attempt_number': attempt_number,
                'is_completed': False
            }
            
            result = self.supabase.table('quiz_attempts').insert(attempt_data).execute()
            return result.data[0]['id'] if result.data else None, "Quiz attempt started"
        except Exception as e:
            print(f"Error starting quiz attempt: {e}")
            return None, str(e)
    
    def get_quiz_questions(self, quiz_set_id: str) -> List[Dict[str, Any]]:
        """Get questions for a quiz set"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('quizzes').select('*').eq('quiz_set_id', quiz_set_id).order('order_index').execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting quiz questions: {e}")
            return []
    
    def submit_quiz_response(self, attempt_id: str, quiz_id: str, student_id: str, selected_answer: str) -> Tuple[Optional[str], str]:
        """Submit a quiz response"""
        if not self.supabase:
            return None, "Database not available"
        try:
            # Get the quiz to check correct answer
            quiz_result = self.supabase.table('quizzes').select('*').eq('id', quiz_id).execute()
            if not quiz_result.data:
                return None, "Quiz not found"
            
            quiz = quiz_result.data[0]
            is_correct = selected_answer == quiz.get('correct_answer')
            points_earned = quiz.get('points', 1) if is_correct else 0
            
            response_data = {
                'attempt_id': attempt_id,
                'quiz_id': quiz_id,
                'student_id': student_id,
                'selected_answer': selected_answer,
                'is_correct': is_correct,
                'points_earned': points_earned,
                'responded_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('quiz_responses').insert(response_data).execute()
            return result.data[0]['id'] if result.data else None, "Response submitted"
        except Exception as e:
            print(f"Error submitting quiz response: {e}")
            return None, str(e)
    
    def finish_quiz_attempt(self, attempt_id: str, student_id: str) -> Tuple[bool, str]:
        """Finish a quiz attempt and calculate score"""
        if not self.supabase:
            return False, "Database not available"
        try:
            # Get all responses for this attempt
            responses_result = self.supabase.table('quiz_responses').select('*').eq('attempt_id', attempt_id).execute()
            responses = responses_result.data if responses_result.data else []
            
            # Calculate score
            total_questions = len(responses)
            correct_answers = sum(1 for r in responses if r.get('is_correct', False))
            total_points = sum(r.get('points_earned', 0) for r in responses)
            score = int((correct_answers / total_questions * 100)) if total_questions > 0 else 0
            
            # Update attempt
            update_data = {
                'finished_at': datetime.now().isoformat(),
                'score': score,
                'total_questions': total_questions,
                'correct_answers': correct_answers,
                'is_completed': True
            }
            
            result = self.supabase.table('quiz_attempts').update(update_data).eq('id', attempt_id).execute()
            return bool(result.data), "Quiz attempt finished"
        except Exception as e:
            print(f"Error finishing quiz attempt: {e}")
            return False, str(e)
    
    def get_quiz_attempt_by_id(self, attempt_id: str) -> Optional[Dict[str, Any]]:
        """Get quiz attempt by ID"""
        if not self.supabase:
            return None
        try:
            result = self.supabase.table('quiz_attempts').select('*').eq('id', attempt_id).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting quiz attempt: {e}")
            return None
    
    def get_teacher_materials(self, teacher_id: str) -> List[Dict[str, Any]]:
        """Get materials uploaded by a teacher"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('materials').select('*').eq('teacher_id', teacher_id).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting teacher materials: {e}")
            return []
    
    def create_material(self, institution_id: str, lecture_id: str = None, cohort_id: str = None,
                       teacher_id: str = None, title: str = None, description: str = None,
                       file_path: str = None, file_name: str = None, file_type: str = None,
                       file_size: int = None) -> Tuple[Optional[str], str]:
        """Create a new material"""
        if not self.supabase:
            return None, "Database not available"
        try:
            # Create material data with all required fields
            material_data = {
                'institution_id': institution_id,
                'teacher_id': teacher_id,
                'title': title,
                'file_path': file_path,
                'file_name': file_name,
                'file_type': file_type,
                'is_active': True
            }
            
            # Add optional fields - handle lecture_id constraint
            if lecture_id:
                material_data['lecture_id'] = lecture_id
            # If no lecture_id provided, we'll omit it from the insert
            # The schema allows NULL for lecture_id, so this should work
                
            if cohort_id:
                material_data['cohort_id'] = cohort_id
            if description:
                material_data['description'] = description
            if file_size is not None:
                material_data['file_size'] = file_size
            
            result = self.supabase.table('materials').insert(material_data).execute()
            return result.data[0]['id'] if result.data else None, "Material created successfully"
        except Exception as e:
            print(f"Error creating material: {e}")
            return None, str(e)
    
    def update_lecture(self, lecture_id: str, **kwargs) -> bool:
        """Update a lecture"""
        if not self.supabase:
            return False
        try:
            result = self.supabase.table('lectures').update(kwargs).eq('id', lecture_id).execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error updating lecture: {e}")
            return False
    
    def delete_lecture(self, lecture_id: str) -> bool:
        """Delete a lecture"""
        if not self.supabase:
            return False
        try:
            result = self.supabase.table('lectures').update({'is_active': False}).eq('id', lecture_id).execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error deleting lecture: {e}")
            return False
    
    def update_teacher(self, teacher_id: str, **kwargs) -> bool:
        """Update a teacher"""
        if not self.supabase:
            return False
        try:
            result = self.supabase.table('teachers').update(kwargs).eq('id', teacher_id).execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error updating teacher: {e}")
            return False
    
    def update_student(self, student_id: str, **kwargs) -> bool:
        """Update a student"""
        if not self.supabase:
            return False
        try:
            result = self.supabase.table('students').update(kwargs).eq('id', student_id).execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error updating student: {e}")
            return False
    
    def update_student_last_login(self, student_id: str) -> bool:
        """Update student last login time"""
        if not self.supabase:
            return False
        try:
            result = self.supabase.table('students').update({'last_login': datetime.now().isoformat()}).eq('id', student_id).execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error updating student last login: {e}")
            return False
    
    def get_activity_logs(self, limit: int = 100, offset: int = 0, institution_id: str = None) -> List[Dict[str, Any]]:
        """Get system activity logs"""
        if not self.supabase:
            return []
        try:
            query = self.supabase.table('activity_logs').select('*')
            
            if institution_id:
                query = query.eq('institution_id', institution_id)
            
            result = query.order('created_at', desc=True).range(offset, offset + limit - 1).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting activity logs: {e}")
            return []
    
    def get_platform_settings(self) -> Dict[str, Any]:
        """Get platform settings"""
        if not self.supabase:
            return {}
        try:
            result = self.supabase.table('platform_settings').select('*').execute()
            if result.data:
                return result.data[0]
            return {}
        except Exception as e:
            print(f"Error getting platform settings: {e}")
            return {}
    
    def update_platform_settings(self, settings: Dict[str, Any]) -> bool:
        """Update platform settings"""
        if not self.supabase:
            return False
        try:
            # Check if settings exist
            existing = self.supabase.table('platform_settings').select('id').execute()
            
            settings_data = {
                **settings,
                'updated_at': datetime.now().isoformat()
            }
            
            if existing.data:
                # Update existing
                result = self.supabase.table('platform_settings').update(settings_data).eq('id', existing.data[0]['id']).execute()
            else:
                # Create new
                settings_data['created_at'] = datetime.now().isoformat()
                result = self.supabase.table('platform_settings').insert(settings_data).execute()
            
            return bool(result.data)
        except Exception as e:
            print(f"Error updating platform settings: {e}")
            return False
    
    def test_connection(self) -> bool:
        """Test database connection"""
        if not self.supabase:
            return False
        try:
            # Simple query to test connection
            result = self.supabase.table('institutions').select('id').limit(1).execute()
            return True
        except Exception as e:
            print(f"Database connection test failed: {e}")
            return False
    
    def delete_teacher(self, teacher_id: str) -> bool:
        """Soft delete a teacher by setting is_active to False"""
        if not self.supabase:
            return False
        try:
            result = self.supabase.table('teachers').update({'is_active': False}).eq('id', teacher_id).execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error deleting teacher: {e}")
            return False
    
    def delete_student(self, student_id: str) -> bool:
        """Soft delete a student by setting is_active to False"""
        if not self.supabase:
            return False
        try:
            result = self.supabase.table('students').update({'is_active': False}).eq('id', student_id).execute()
            return bool(result.data)
        except Exception as e:
            print(f"Error deleting student: {e}")
            return False

    def create_poll(self, teacher_id: str, cohort_id: str, question: str, options: List[str], is_active: bool = True) -> Optional[str]:
        """Create a poll for a cohort"""
        if not self.supabase:
            return None
        try:
            poll_data = {
                'teacher_id': teacher_id,
                'cohort_id': cohort_id,
                'question': question,
                'options': options,
                'is_active': is_active,
                'created_at': datetime.now().isoformat()
            }
            result = self.supabase.table('polls').insert(poll_data).execute()
            return result.data[0]['id'] if result.data else None
        except Exception as e:
            print(f"Error creating poll: {e}")
            return None

    def get_cohort_discussions(self, cohort_id: str) -> List[Dict[str, Any]]:
        """Get discussions for a cohort"""
        if not self.supabase:
            return []
        try:
            # Get discussion forums for the cohort with post count
            result = self.supabase.table('discussion_forums').select('*').eq('cohort_id', cohort_id).eq('is_active', True).order('created_at', desc=True).execute()
            discussions = result.data if result.data else []
            
            # Add post count and latest post info to each discussion
            for discussion in discussions:
                try:
                    # Get post count
                    posts_result = self.supabase.table('discussion_posts').select('id').eq('forum_id', discussion['id']).execute()
                    discussion['post_count'] = len(posts_result.data) if posts_result.data else 0
                    
                    # Get latest post
                    latest_post = self.supabase.table('discussion_posts').select('*').eq('forum_id', discussion['id']).order('created_at', desc=True).limit(1).execute()
                    if latest_post.data:
                        discussion['latest_post'] = latest_post.data[0]
                except Exception as e:
                    print(f"Error getting discussion details: {e}")
                    discussion['post_count'] = 0
                    discussion['latest_post'] = None
            
            return discussions
        except Exception as e:
            print(f"Error getting cohort discussions: {e}")
            return []

    def create_discussion(self, cohort_id: str, teacher_id: str, title: str, content: str, is_pinned: bool = False) -> Tuple[Optional[str], str]:
        """Create a discussion for a cohort"""
        if not self.supabase:
            return None, "Database not available"
        try:
            # First, get the institution_id from the cohort
            cohort_result = self.supabase.table('cohorts').select('institution_id').eq('id', cohort_id).execute()
            if not cohort_result.data:
                return None, "Cohort not found"
            
            institution_id = cohort_result.data[0]['institution_id']
            
            # Create discussion forum
            forum_data = {
                'institution_id': institution_id,
                'cohort_id': cohort_id,
                'title': title,
                'description': content,
                'is_active': True,
                'created_by': teacher_id,
                'created_at': datetime.now().isoformat()
            }
            forum_result = self.supabase.table('discussion_forums').insert(forum_data).execute()
            
            if forum_result.data:
                forum_id = forum_result.data[0]['id']
                
                # Create the initial post
                post_data = {
                    'institution_id': institution_id,
                    'forum_id': forum_id,
                    'author_id': teacher_id,
                    'author_type': 'teacher',
                    'title': title,
                    'content': content,
                    'is_pinned': is_pinned,
                    'created_at': datetime.now().isoformat()
                }
                post_result = self.supabase.table('discussion_posts').insert(post_data).execute()
                
                if post_result.data:
                    return post_result.data[0]['id'], "Discussion created successfully"
                else:
                    return None, "Failed to create discussion post"
            else:
                return None, "Failed to create discussion forum"
        except Exception as e:
            print(f"Error creating discussion: {e}")
            return None, f"Error creating discussion: {str(e)}"
    
    def get_discussion_posts(self, forum_id: str) -> List[Dict[str, Any]]:
        """Get all posts for a discussion forum"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('discussion_posts').select('*').eq('forum_id', forum_id).order('created_at', desc=False).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting discussion posts: {e}")
            return []
    
    def add_discussion_post(self, forum_id: str, author_id: str, author_type: str, content: str, title: str = None) -> Tuple[Optional[str], str]:
        """Add a post to a discussion forum"""
        if not self.supabase:
            return None, "Database not available"
        try:
            # Get institution_id from forum
            forum_result = self.supabase.table('discussion_forums').select('institution_id').eq('id', forum_id).execute()
            if not forum_result.data:
                return None, "Forum not found"
            
            institution_id = forum_result.data[0]['institution_id']
            
            post_data = {
                'institution_id': institution_id,
                'forum_id': forum_id,
                'author_id': author_id,
                'author_type': author_type,
                'content': content,
                'is_pinned': False,
                'is_locked': False,
                'created_at': datetime.now().isoformat()
            }
            
            if title:
                post_data['title'] = title
            
            result = self.supabase.table('discussion_posts').insert(post_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Post added successfully"
            else:
                return None, "Failed to add post"
        except Exception as e:
            print(f"Error adding discussion post: {e}")
            return None, str(e)

    def get_lecture_polls(self, lecture_id: str) -> List[Dict[str, Any]]:
        """Get polls for a specific lecture"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('polls').select('*').eq('lecture_id', lecture_id).eq('is_active', True).order('created_at', desc=True).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting lecture polls: {e}")
            return []

    def create_lecture_poll(self, lecture_id: str, teacher_id: str, question: str, options: List[str], is_active: bool = True) -> Optional[str]:
        """Create a poll for a specific lecture"""
        if not self.supabase:
            return None
        try:
            poll_data = {
                'lecture_id': lecture_id,
                'teacher_id': teacher_id,
                'question': question,
                'options': options,
                'is_active': is_active,
                'created_at': datetime.now().isoformat()
            }
            result = self.supabase.table('polls').insert(poll_data).execute()
            return result.data[0]['id'] if result.data else None
        except Exception as e:
            print(f"Error creating lecture poll: {e}")
            return None

    def assign_teacher_to_cohort(self, teacher_id: str, cohort_id: str) -> bool:
        """Assign a teacher to a cohort"""
        if not self.supabase:
            return False
        try:
            # Check if assignment already exists
            existing = self.supabase.table('cohort_teachers').select('*').eq('teacher_id', teacher_id).eq('cohort_id', cohort_id).execute()
            
            if existing.data:
                # Update existing assignment to active
                result = self.supabase.table('cohort_teachers').update({
                    'is_active': True,
                    'assigned_at': datetime.now().isoformat()
                }).eq('teacher_id', teacher_id).eq('cohort_id', cohort_id).execute()
                return bool(result.data)
            else:
                # Create new assignment
                assignment_data = {
                    'teacher_id': teacher_id,
                    'cohort_id': cohort_id,
                    'is_active': True,
                    'assigned_at': datetime.now().isoformat()
                }
                result = self.supabase.table('cohort_teachers').insert(assignment_data).execute()
                return bool(result.data)
        except Exception as e:
            print(f"Error assigning teacher to cohort: {e}")
            return False

    def get_all_cohorts(self) -> List[Dict[str, Any]]:
        """Get all active cohorts"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('cohorts').select('*').eq('is_active', True).order('created_at', desc=True).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting all cohorts: {e}")
            return []

    def create_quiz(self, teacher_id: str, cohort_id: str, title: str, description: str, questions: List[Dict], is_active: bool = True) -> Tuple[Optional[str], str]:
        """Create a quiz for a cohort"""
        if not self.supabase:
            return None, "Database not available"
        try:
            # First, get the institution_id from the cohort
            cohort_result = self.supabase.table('cohorts').select('institution_id').eq('id', cohort_id).execute()
            if not cohort_result.data:
                return None, "Cohort not found"
            
            institution_id = cohort_result.data[0]['institution_id']
            
            # Create quiz set
            quiz_set_data = {
                'institution_id': institution_id,
                'cohort_id': cohort_id,
                'teacher_id': teacher_id,
                'title': title,
                'description': description,
                'is_active': is_active,
                'created_at': datetime.now().isoformat()
            }
            quiz_set_result = self.supabase.table('quiz_sets').insert(quiz_set_data).execute()
            
            if quiz_set_result.data:
                quiz_set_id = quiz_set_result.data[0]['id']
                
                # Add questions to the quiz set
                for i, question in enumerate(questions):
                    question_data = {
                        'quiz_set_id': quiz_set_id,
                        'question_text': question.get('question', ''),
                        'question_type': question.get('type', 'multiple_choice'),
                        'order_index': i
                    }
                    
                    # Add optional fields if they have values
                    if question.get('options'):
                        question_data['options'] = question.get('options')
                    if question.get('correct_answer'):
                        question_data['correct_answer'] = question.get('correct_answer')
                    if question.get('points'):
                        question_data['points'] = question.get('points', 1)
                    if question.get('explanation'):
                        question_data['explanation'] = question.get('explanation')
                    
                    self.supabase.table('quizzes').insert(question_data).execute()
                
                return quiz_set_id, "Quiz created successfully"
            else:
                return None, "Failed to create quiz set"
        except Exception as e:
            print(f"Error creating quiz: {e}")
            return None, f"Error creating quiz: {str(e)}"

    def get_lecture_materials(self, lecture_id: str) -> List[Dict[str, Any]]:
        """Get materials for a specific lecture"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('materials').select('*').eq('lecture_id', lecture_id).eq('is_active', True).order('created_at', desc=True).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting lecture materials: {e}")
            return []

    def get_cohort_by_id(self, cohort_id: str) -> Optional[Dict[str, Any]]:
        """Get cohort by ID"""
        if not self.supabase:
            return None
        try:
            result = self.supabase.table('cohorts').select('*').eq('id', cohort_id).eq('is_active', True).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting cohort by ID: {e}")
            return None

    def get_lectures_by_cohort(self, cohort_id: str) -> List[Dict[str, Any]]:
        """Get lectures for a specific cohort"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('lectures').select('*').eq('cohort_id', cohort_id).eq('is_active', True).order('scheduled_time', desc=True).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting lectures by cohort: {e}")
            return []

    def get_quiz_responses_by_quiz_set(self, quiz_set_id: str) -> List[Dict[str, Any]]:
        """Get all responses for a quiz set"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('quiz_responses').select('*, quiz_attempts(*, students(name, email))').eq('quiz_id', quiz_set_id).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting quiz responses: {e}")
            return []

    def get_quiz_attempts_by_quiz_set(self, quiz_set_id: str) -> List[Dict[str, Any]]:
        """Get all attempts for a quiz set"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('quiz_attempts').select('*, students(name, email)').eq('quiz_set_id', quiz_set_id).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting quiz attempts: {e}")
            return []

    def create_poll(self, institution_id: str, cohort_id: str, teacher_id: str, question: str, options: List[str], lecture_id: str = None, expires_at: str = None) -> Tuple[Optional[str], str]:
        """Create a new poll"""
        if not self.supabase:
            return None, "Database connection not available"
        
        try:
            poll_data = {
                'institution_id': institution_id,
                'cohort_id': cohort_id,
                'teacher_id': teacher_id,
                'question': question,
                'options': options,
                'is_active': True,
                'created_at': datetime.now().isoformat()
            }
            
            if lecture_id:
                poll_data['lecture_id'] = lecture_id
            if expires_at:
                poll_data['expires_at'] = expires_at
            
            result = self.supabase.table('polls').insert(poll_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Poll created successfully"
            else:
                return None, "Failed to create poll"
        except Exception as e:
            print(f"Error creating poll: {e}")
            return None, f"Error creating poll: {str(e)}"

    def get_polls_by_cohort(self, cohort_id: str) -> List[Dict[str, Any]]:
        """Get polls for a cohort"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('polls').select('*').eq('cohort_id', cohort_id).eq('is_active', True).order('created_at', desc=True).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting polls: {e}")
            return []

    def submit_poll_response(self, poll_id: str, student_id: str, selected_option: str) -> Tuple[Optional[str], str]:
        """Submit a poll response"""
        if not self.supabase:
            return None, "Database connection not available"
        
        try:
            # Check if student already responded
            existing = self.supabase.table('poll_responses').select('*').eq('poll_id', poll_id).eq('student_id', student_id).execute()
            
            if existing.data:
                return None, "You have already responded to this poll"
            
            # Get poll institution_id
            poll_result = self.supabase.table('polls').select('institution_id').eq('id', poll_id).execute()
            if not poll_result.data:
                return None, "Poll not found"
            
            response_data = {
                'institution_id': poll_result.data[0]['institution_id'],
                'poll_id': poll_id,
                'student_id': student_id,
                'selected_option': selected_option,
                'responded_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('poll_responses').insert(response_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Response submitted successfully"
            else:
                return None, "Failed to submit response"
        except Exception as e:
            print(f"Error submitting poll response: {e}")
            return None, f"Error submitting poll response: {str(e)}"

    def get_poll_results(self, poll_id: str) -> Dict[str, Any]:
        """Get poll results"""
        if not self.supabase:
            return {}
        try:
            # Get poll details
            poll_result = self.supabase.table('polls').select('*').eq('id', poll_id).execute()
            if not poll_result.data:
                return {}
            
            poll = poll_result.data[0]
            
            # Get responses
            responses_result = self.supabase.table('poll_responses').select('*').eq('poll_id', poll_id).execute()
            responses = responses_result.data if responses_result.data else []
            
            # Count responses by option
            option_counts = {}
            for response in responses:
                option = response['selected_option']
                option_counts[option] = option_counts.get(option, 0) + 1
            
            return {
                'poll': poll,
                'total_responses': len(responses),
                'option_counts': option_counts,
                'responses': responses
            }
        except Exception as e:
            print(f"Error getting poll results: {e}")
            return {}

    def create_discussion_post(self, institution_id: str, forum_id: str, author_id: str, author_type: str, content: str, title: str = None, parent_post_id: str = None) -> Tuple[Optional[str], str]:
        """Create a discussion post"""
        if not self.supabase:
            return None, "Database connection not available"
        
        try:
            post_data = {
                'institution_id': institution_id,
                'forum_id': forum_id,
                'author_id': author_id,
                'author_type': author_type,
                'content': content,
                'created_at': datetime.now().isoformat()
            }
            
            if title:
                post_data['title'] = title
            if parent_post_id:
                post_data['parent_post_id'] = parent_post_id
            
            result = self.supabase.table('discussion_posts').insert(post_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Post created successfully"
            else:
                return None, "Failed to create post"
        except Exception as e:
            print(f"Error creating discussion post: {e}")
            return None, f"Error creating discussion post: {str(e)}"

    def get_discussion_posts(self, forum_id: str) -> List[Dict[str, Any]]:
        """Get discussion posts for a forum"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('discussion_posts').select('*, teachers(name), students(name)').eq('forum_id', forum_id).order('created_at', desc=True).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting discussion posts: {e}")
            return []

    def create_discussion_forum(self, institution_id: str, cohort_id: str, title: str, description: str = None, created_by: str = None) -> Tuple[Optional[str], str]:
        """Create a discussion forum"""
        if not self.supabase:
            return None, "Database connection not available"
        
        try:
            forum_data = {
                'institution_id': institution_id,
                'cohort_id': cohort_id,
                'title': title,
                'description': description,
                'created_by': created_by,
                'is_active': True,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.supabase.table('discussion_forums').insert(forum_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Forum created successfully"
            else:
                return None, "Failed to create forum"
        except Exception as e:
            print(f"Error creating discussion forum: {e}")
            return None, f"Error creating discussion forum: {str(e)}"

    def get_discussion_forums_by_cohort(self, cohort_id: str) -> List[Dict[str, Any]]:
        """Get discussion forums for a cohort"""
        if not self.supabase:
            return []
        try:
            result = self.supabase.table('discussion_forums').select('*').eq('cohort_id', cohort_id).eq('is_active', True).order('created_at', desc=True).execute()
            return result.data if result.data else []
        except Exception as e:
            print(f"Error getting discussion forums: {e}")
            return []


# Create a global instance for compatibility
DatabaseManager = SupabaseDatabaseManager
