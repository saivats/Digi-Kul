"""
Quiz Service for comprehensive quiz management
Handles quiz creation, attempts, analytics, and visualizations.
"""

import uuid
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any, Tuple
from utils.database_supabase import DatabaseManager

class QuizService:
    def __init__(self, db: DatabaseManager):
        """Initialize quiz service with database"""
        self.db = db
    
    def create_quiz_set(self, title: str, description: str, cohort_id: str, 
                       teacher_id: str, time_limit: Optional[int] = None,
                       max_attempts: int = 1, starts_at: Optional[str] = None,
                       ends_at: Optional[str] = None) -> Tuple[Optional[str], str]:
        """
        Create a new quiz set
        
        Args:
            title: Quiz title
            description: Quiz description
            cohort_id: ID of the cohort
            teacher_id: ID of the teacher
            time_limit: Time limit in minutes (optional)
            max_attempts: Maximum number of attempts allowed
            starts_at: When quiz becomes available (optional)
            ends_at: When quiz expires (optional)
            
        Returns:
            Tuple of (quiz_set_id, message)
        """
        try:
            quiz_set_data = {
                'title': title,
                'description': description,
                'cohort_id': cohort_id,
                'teacher_id': teacher_id,
                'time_limit': time_limit,
                'max_attempts': max_attempts,
                'starts_at': starts_at,
                'ends_at': ends_at,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.db.supabase.table('quiz_sets').insert(quiz_set_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Quiz set created successfully"
            else:
                return None, "Failed to create quiz set"
                
        except Exception as e:
            return None, str(e)
    
    def add_question_to_quiz_set(self, quiz_set_id: str, question: str, 
                                options: List[str], correct_answer: str,
                                points: int = 1, question_order: int = 1) -> Tuple[Optional[str], str]:
        """
        Add a question to a quiz set
        
        Args:
            quiz_set_id: ID of the quiz set
            question: Question text
            options: List of answer options
            correct_answer: Correct answer
            points: Points for this question
            question_order: Order of the question
            
        Returns:
            Tuple of (question_id, message)
        """
        try:
            question_data = {
                'quiz_set_id': quiz_set_id,
                'question': question,
                'options': options,
                'correct_answer': correct_answer,
                'points': points,
                'question_order': question_order,
                'created_at': datetime.now().isoformat()
            }
            
            result = self.db.supabase.table('quizzes').insert(question_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Question added successfully"
            else:
                return None, "Failed to add question"
                
        except Exception as e:
            return None, str(e)
    
    def get_quiz_set_by_id(self, quiz_set_id: str) -> Optional[Dict]:
        """Get quiz set by ID with questions"""
        try:
            # Get quiz set details
            quiz_set_result = self.db.supabase.table('quiz_sets').select(
                '*, teachers!inner(name), cohorts!inner(name)'
            ).eq('id', quiz_set_id).eq('is_active', True).execute()
            
            if not quiz_set_result.data:
                return None
            
            quiz_set = quiz_set_result.data[0]
            teacher_data = quiz_set.get('teachers', {})
            cohort_data = quiz_set.get('cohorts', {})
            quiz_set['teacher_name'] = teacher_data.get('name')
            quiz_set['cohort_name'] = cohort_data.get('name')
            del quiz_set['teachers']
            del quiz_set['cohorts']
            
            # Get questions
            questions_result = self.db.supabase.table('quizzes').select('*').eq('quiz_set_id', quiz_set_id).eq('is_active', True).order('question_order').execute()
            quiz_set['questions'] = questions_result.data or []
            
            return quiz_set
        except Exception:
            return None
    
    def get_cohort_quiz_sets(self, cohort_id: str) -> List[Dict]:
        """Get all quiz sets for a cohort"""
        try:
            result = self.db.supabase.table('quiz_sets').select(
                '*, teachers!inner(name)'
            ).eq('cohort_id', cohort_id).eq('is_active', True).order('created_at', desc=True).execute()
            
            quiz_sets = []
            for quiz_set in result.data or []:
                teacher_data = quiz_set.get('teachers', {})
                quiz_set['teacher_name'] = teacher_data.get('name')
                del quiz_set['teachers']
                
                # Get question count
                questions_result = self.db.supabase.table('quizzes').select('id', count='exact').eq('quiz_set_id', quiz_set['id']).execute()
                quiz_set['question_count'] = questions_result.count if questions_result.count else 0
                
                quiz_sets.append(quiz_set)
            
            return quiz_sets
        except Exception:
            return []
    
    def get_student_quiz_sets(self, student_id: str) -> List[Dict]:
        """Get all quiz sets available to a student"""
        try:
            # Get student's cohorts
            cohorts_result = self.db.supabase.table('cohort_students').select('cohort_id').eq('student_id', student_id).execute()
            cohort_ids = [cs['cohort_id'] for cs in cohorts_result.data or []]
            
            if not cohort_ids:
                return []
            
            # Get quiz sets from all cohorts
            result = self.db.supabase.table('quiz_sets').select(
                '*, teachers!inner(name), cohorts!inner(name)'
            ).in_('cohort_id', cohort_ids).eq('is_active', True).order('created_at', desc=True).execute()
            
            quiz_sets = []
            for quiz_set in result.data or []:
                teacher_data = quiz_set.get('teachers', {})
                cohort_data = quiz_set.get('cohorts', {})
                quiz_set['teacher_name'] = teacher_data.get('name')
                quiz_set['cohort_name'] = cohort_data.get('name')
                del quiz_set['teachers']
                del quiz_set['cohorts']
                
                # Check if student has attempted this quiz
                attempts_result = self.db.supabase.table('quiz_attempts').select('id', count='exact').eq('student_id', student_id).eq('quiz_set_id', quiz_set['id']).execute()
                quiz_set['attempt_count'] = attempts_result.count if attempts_result.count else 0
                
                # Get latest attempt
                latest_attempt_result = self.db.supabase.table('quiz_attempts').select('*').eq('student_id', student_id).eq('quiz_set_id', quiz_set['id']).order('started_at', desc=True).limit(1).execute()
                if latest_attempt_result.data:
                    quiz_set['latest_attempt'] = latest_attempt_result.data[0]
                
                quiz_sets.append(quiz_set)
            
            return quiz_sets
        except Exception:
            return []
    
    def start_quiz_attempt(self, student_id: str, quiz_set_id: str) -> Tuple[Optional[str], str]:
        """
        Start a new quiz attempt for a student
        
        Args:
            student_id: ID of the student
            quiz_set_id: ID of the quiz set
            
        Returns:
            Tuple of (attempt_id, message)
        """
        try:
            # Check if student is in the cohort
            quiz_set = self.get_quiz_set_by_id(quiz_set_id)
            if not quiz_set:
                return None, "Quiz set not found"
            
            # Check if student is in the cohort
            is_in_cohort = self.db.supabase.table('cohort_students').select('id').eq('student_id', student_id).eq('cohort_id', quiz_set['cohort_id']).execute()
            if not is_in_cohort.data:
                return None, "Student not enrolled in this cohort"
            
            # Check attempt limit
            attempts_result = self.db.supabase.table('quiz_attempts').select('id', count='exact').eq('student_id', student_id).eq('quiz_set_id', quiz_set_id).execute()
            current_attempts = attempts_result.count if attempts_result.count else 0
            
            if current_attempts >= quiz_set['max_attempts']:
                return None, f"Maximum attempts ({quiz_set['max_attempts']}) reached"
            
            # Check if quiz is available
            now = datetime.now()
            if quiz_set['starts_at'] and datetime.fromisoformat(quiz_set['starts_at'].replace('Z', '+00:00')) > now:
                return None, "Quiz not yet available"
            
            if quiz_set['ends_at'] and datetime.fromisoformat(quiz_set['ends_at'].replace('Z', '+00:00')) < now:
                return None, "Quiz has expired"
            
            # Create new attempt
            attempt_number = current_attempts + 1
            attempt_data = {
                'student_id': student_id,
                'quiz_set_id': quiz_set_id,
                'attempt_number': attempt_number,
                'started_at': datetime.now().isoformat()
            }
            
            result = self.db.supabase.table('quiz_attempts').insert(attempt_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Quiz attempt started successfully"
            else:
                return None, "Failed to start quiz attempt"
                
        except Exception as e:
            return None, str(e)
    
    def submit_quiz_response(self, attempt_id: str, quiz_id: str, response: str) -> Tuple[Optional[str], str]:
        """
        Submit a response for a quiz question
        
        Args:
            attempt_id: ID of the quiz attempt
            quiz_id: ID of the quiz question
            response: Student's response
            
        Returns:
            Tuple of (response_id, message)
        """
        try:
            # Get attempt and quiz details
            attempt_result = self.db.supabase.table('quiz_attempts').select('*').eq('id', attempt_id).execute()
            if not attempt_result.data:
                return None, "Quiz attempt not found"
            
            attempt = attempt_result.data[0]
            
            quiz_result = self.db.supabase.table('quizzes').select('*').eq('id', quiz_id).execute()
            if not quiz_result.data:
                return None, "Quiz question not found"
            
            quiz = quiz_result.data[0]
            
            # Check if attempt is still active
            if attempt['submitted_at']:
                return None, "Quiz attempt already submitted"
            
            # Calculate points
            is_correct = response == quiz['correct_answer']
            points_earned = quiz['points'] if is_correct else 0
            
            # Check if response already exists
            existing_response = self.db.supabase.table('quiz_responses').select('id').eq('attempt_id', attempt_id).eq('quiz_id', quiz_id).execute()
            
            response_data = {
                'attempt_id': attempt_id,
                'quiz_id': quiz_id,
                'student_id': attempt['student_id'],
                'response': response,
                'is_correct': is_correct,
                'points_earned': points_earned,
                'submitted_at': datetime.now().isoformat()
            }
            
            if existing_response.data:
                # Update existing response
                result = self.db.supabase.table('quiz_responses').update(response_data).eq('id', existing_response.data[0]['id']).execute()
            else:
                # Create new response
                result = self.db.supabase.table('quiz_responses').insert(response_data).execute()
            
            if result.data:
                return result.data[0]['id'], "Response submitted successfully"
            else:
                return None, "Failed to submit response"
                
        except Exception as e:
            return None, str(e)
    
    def submit_quiz_attempt(self, attempt_id: str) -> Tuple[bool, str]:
        """
        Submit and finalize a quiz attempt
        
        Args:
            attempt_id: ID of the quiz attempt
            
        Returns:
            Tuple of (success, message)
        """
        try:
            # Get attempt details
            attempt_result = self.db.supabase.table('quiz_attempts').select('*').eq('id', attempt_id).execute()
            if not attempt_result.data:
                return False, "Quiz attempt not found"
            
            attempt = attempt_result.data[0]
            
            if attempt['submitted_at']:
                return False, "Quiz attempt already submitted"
            
            # Calculate total score
            responses_result = self.db.supabase.table('quiz_responses').select('points_earned').eq('attempt_id', attempt_id).execute()
            total_score = sum(response['points_earned'] for response in responses_result.data or [])
            
            # Get max possible score
            quiz_set_result = self.db.supabase.table('quiz_sets').select('*').eq('id', attempt['quiz_set_id']).execute()
            if not quiz_set_result.data:
                return False, "Quiz set not found"
            
            quiz_set = quiz_set_result.data[0]
            questions_result = self.db.supabase.table('quizzes').select('points').eq('quiz_set_id', attempt['quiz_set_id']).execute()
            max_score = sum(question['points'] for question in questions_result.data or [])
            
            # Calculate time taken
            started_at = datetime.fromisoformat(attempt['started_at'].replace('Z', '+00:00'))
            time_taken = int((datetime.now() - started_at).total_seconds())
            
            # Update attempt
            update_data = {
                'submitted_at': datetime.now().isoformat(),
                'time_taken': time_taken,
                'total_score': total_score,
                'max_score': max_score,
                'is_completed': True
            }
            
            result = self.db.supabase.table('quiz_attempts').update(update_data).eq('id', attempt_id).execute()
            
            if result.data:
                return True, "Quiz attempt submitted successfully"
            else:
                return False, "Failed to submit quiz attempt"
                
        except Exception as e:
            return False, str(e)
    
    def get_quiz_analytics(self, quiz_set_id: str) -> Dict[str, Any]:
        """
        Get comprehensive analytics for a quiz set
        
        Args:
            quiz_set_id: ID of the quiz set
            
        Returns:
            Dictionary with quiz analytics
        """
        try:
            quiz_set = self.get_quiz_set_by_id(quiz_set_id)
            if not quiz_set:
                return {}
            
            # Get all attempts
            attempts_result = self.db.supabase.table('quiz_attempts').select('*').eq('quiz_set_id', quiz_set_id).execute()
            attempts = attempts_result.data or []
            
            if not attempts:
                return {
                    'quiz_set_id': quiz_set_id,
                    'quiz_title': quiz_set['title'],
                    'total_attempts': 0,
                    'completed_attempts': 0,
                    'average_score': 0,
                    'average_time': 0,
                    'question_analytics': [],
                    'score_distribution': {}
                }
            
            completed_attempts = [a for a in attempts if a['is_completed']]
            
            # Calculate basic stats
            total_attempts = len(attempts)
            completed_count = len(completed_attempts)
            average_score = sum(a['total_score'] for a in completed_attempts) / completed_count if completed_count > 0 else 0
            average_time = sum(a['time_taken'] for a in completed_attempts) / completed_count if completed_count > 0 else 0
            
            # Score distribution
            score_ranges = {
                '0-20': 0, '21-40': 0, '41-60': 0, '61-80': 0, '81-100': 0
            }
            
            for attempt in completed_attempts:
                percentage = (attempt['total_score'] / attempt['max_score'] * 100) if attempt['max_score'] > 0 else 0
                if percentage <= 20:
                    score_ranges['0-20'] += 1
                elif percentage <= 40:
                    score_ranges['21-40'] += 1
                elif percentage <= 60:
                    score_ranges['41-60'] += 1
                elif percentage <= 80:
                    score_ranges['61-80'] += 1
                else:
                    score_ranges['81-100'] += 1
            
            # Question analytics
            question_analytics = []
            for question in quiz_set['questions']:
                responses_result = self.db.supabase.table('quiz_responses').select('is_correct').eq('quiz_id', question['id']).execute()
                responses = responses_result.data or []
                
                correct_count = sum(1 for r in responses if r['is_correct'])
                total_responses = len(responses)
                accuracy = (correct_count / total_responses * 100) if total_responses > 0 else 0
                
                question_analytics.append({
                    'question_id': question['id'],
                    'question_text': question['question'],
                    'question_order': question['question_order'],
                    'total_responses': total_responses,
                    'correct_responses': correct_count,
                    'accuracy_percentage': round(accuracy, 2),
                    'points': question['points']
                })
            
            return {
                'quiz_set_id': quiz_set_id,
                'quiz_title': quiz_set['title'],
                'total_attempts': total_attempts,
                'completed_attempts': completed_count,
                'completion_rate': round((completed_count / total_attempts * 100), 2) if total_attempts > 0 else 0,
                'average_score': round(average_score, 2),
                'average_percentage': round((average_score / quiz_set['questions'][0]['points'] * 100), 2) if quiz_set['questions'] else 0,
                'average_time': round(average_time, 2),
                'question_analytics': question_analytics,
                'score_distribution': score_ranges,
                'created_at': quiz_set['created_at']
            }
            
        except Exception as e:
            return {}
    
    def get_student_quiz_history(self, student_id: str) -> List[Dict]:
        """Get quiz attempt history for a student"""
        try:
            result = self.db.supabase.table('quiz_attempts').select(
                '*, quiz_sets!inner(title, description), cohorts!inner(name)'
            ).eq('student_id', student_id).order('started_at', desc=True).execute()
            
            attempts = []
            for attempt in result.data or []:
                quiz_set_data = attempt.get('quiz_sets', {})
                cohort_data = attempt.get('cohorts', {})
                attempt['quiz_title'] = quiz_set_data.get('title')
                attempt['quiz_description'] = quiz_set_data.get('description')
                attempt['cohort_name'] = cohort_data.get('name')
                del attempt['quiz_sets']
                del attempt['cohorts']
                
                # Calculate percentage
                if attempt['max_score'] > 0:
                    attempt['percentage'] = round((attempt['total_score'] / attempt['max_score'] * 100), 2)
                else:
                    attempt['percentage'] = 0
                
                attempts.append(attempt)
            
            return attempts
        except Exception:
            return []
    
    def delete_quiz_set(self, quiz_set_id: str) -> Tuple[bool, str]:
        """Delete a quiz set (soft delete)"""
        try:
            result = self.db.supabase.table('quiz_sets').update({'is_active': False}).eq('id', quiz_set_id).execute()
            if result.data:
                return True, "Quiz set deleted successfully"
            else:
                return False, "Quiz set not found"
        except Exception as e:
            return False, str(e)

