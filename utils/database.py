# utils/database.py
import sqlite3
import json
import uuid
from datetime import datetime
from typing import Optional, Tuple, List, Dict

class DatabaseManager:
    def __init__(self, db_path='digikul.db'):
        self.db_path = db_path
        self.init_database()
    
    def init_database(self):
        """Initialize database with all required tables"""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Teachers table (updated with password)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS teachers (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                institution TEXT NOT NULL,
                subject TEXT NOT NULL,
                password_hash TEXT NOT NULL,
                created_at TEXT NOT NULL,
                last_login TEXT,
                is_active BOOLEAN DEFAULT 1
            )
        ''')
        
        # Students table (updated with password)
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS students (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                institution TEXT NOT NULL,
                password_hash TEXT NOT NULL,
                created_at TEXT NOT NULL,
                last_login TEXT,
                is_active BOOLEAN DEFAULT 1
            )
        ''')
        
        # Lectures table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS lectures (
                id TEXT PRIMARY KEY,
                teacher_id TEXT NOT NULL,
                title TEXT NOT NULL,
                description TEXT,
                scheduled_time TEXT NOT NULL,
                duration INTEGER NOT NULL,
                created_at TEXT NOT NULL,
                is_active BOOLEAN DEFAULT 1,
                FOREIGN KEY (teacher_id) REFERENCES teachers (id)
            )
        ''')
        
        # Enrollments table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS enrollments (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                lecture_id TEXT NOT NULL,
                enrolled_at TEXT NOT NULL,
                is_active BOOLEAN DEFAULT 1,
                FOREIGN KEY (student_id) REFERENCES students (id),
                FOREIGN KEY (lecture_id) REFERENCES lectures (id),
                UNIQUE(student_id, lecture_id)
            )
        ''')
        
        # Materials table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS materials (
                id TEXT PRIMARY KEY,
                lecture_id TEXT NOT NULL,
                title TEXT NOT NULL,
                description TEXT,
                file_path TEXT NOT NULL,
                compressed_path TEXT NOT NULL,
                file_size INTEGER NOT NULL,
                file_type TEXT NOT NULL,
                uploaded_at TEXT NOT NULL,
                is_active BOOLEAN DEFAULT 1,
                FOREIGN KEY (lecture_id) REFERENCES lectures (id)
            )
        ''')
        
        # Quizzes table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS quizzes (
                id TEXT PRIMARY KEY,
                lecture_id TEXT NOT NULL,
                question TEXT NOT NULL,
                options TEXT NOT NULL,
                correct_answer TEXT NOT NULL,
                created_at TEXT NOT NULL,
                is_active BOOLEAN DEFAULT 1,
                FOREIGN KEY (lecture_id) REFERENCES lectures (id)
            )
        ''')
        
        # Quiz responses table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS quiz_responses (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                quiz_id TEXT NOT NULL,
                response TEXT NOT NULL,
                is_correct INTEGER,
                submitted_at TEXT NOT NULL,
                FOREIGN KEY (student_id) REFERENCES students (id),
                FOREIGN KEY (quiz_id) REFERENCES quizzes (id),
                UNIQUE(student_id, quiz_id)
            )
        ''')
        
        # Polls table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS polls (
                id TEXT PRIMARY KEY,
                lecture_id TEXT NOT NULL,
                question TEXT NOT NULL,
                options TEXT NOT NULL,
                created_at TEXT NOT NULL,
                is_active BOOLEAN DEFAULT 1,
                FOREIGN KEY (lecture_id) REFERENCES lectures (id)
            )
        ''')
        
        # Poll responses table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS poll_responses (
                id TEXT PRIMARY KEY,
                student_id TEXT NOT NULL,
                poll_id TEXT NOT NULL,
                response TEXT NOT NULL,
                submitted_at TEXT NOT NULL,
                FOREIGN KEY (student_id) REFERENCES students (id),
                FOREIGN KEY (poll_id) REFERENCES polls (id)
            )
        ''')
        
        # Discussion messages table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS discussion_messages (
                id TEXT PRIMARY KEY,
                lecture_id TEXT NOT NULL,
                user_id TEXT NOT NULL,
                user_type TEXT NOT NULL,
                message TEXT NOT NULL,
                created_at TEXT NOT NULL,
                is_active BOOLEAN DEFAULT 1,
                FOREIGN KEY (lecture_id) REFERENCES lectures (id)
            )
        ''')
        
        # Session recordings table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS session_recordings (
                id TEXT PRIMARY KEY,
                session_id TEXT NOT NULL,
                lecture_id TEXT NOT NULL,
                teacher_id TEXT NOT NULL,
                recording_path TEXT,
                started_at TEXT NOT NULL,
                ended_at TEXT,
                file_size INTEGER,
                duration INTEGER,
                is_active BOOLEAN DEFAULT 1,
                FOREIGN KEY (lecture_id) REFERENCES lectures (id),
                FOREIGN KEY (teacher_id) REFERENCES teachers (id)
            )
        ''')

        # Cohorts table
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS cohorts (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT,
                subject TEXT NOT NULL,
                teacher_id TEXT NOT NULL,
                code TEXT UNIQUE NOT NULL,
                created_at TEXT NOT NULL,
                is_active BOOLEAN DEFAULT 1,
                FOREIGN KEY (teacher_id) REFERENCES teachers (id)
            )
        ''')

        # Cohort-Students relation
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS cohort_students (
                id TEXT PRIMARY KEY,
                cohort_id TEXT NOT NULL,
                student_id TEXT NOT NULL,
                joined_at TEXT NOT NULL,
                UNIQUE(cohort_id, student_id),
                FOREIGN KEY (cohort_id) REFERENCES cohorts (id),
                FOREIGN KEY (student_id) REFERENCES students (id)
            )
        ''')

        # Cohort-Lectures relation
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS cohort_lectures (
                id TEXT PRIMARY KEY,
                cohort_id TEXT NOT NULL,
                lecture_id TEXT NOT NULL,
                UNIQUE(cohort_id, lecture_id),
                FOREIGN KEY (cohort_id) REFERENCES cohorts (id),
                FOREIGN KEY (lecture_id) REFERENCES lectures (id)
            )
        ''')
        
        conn.commit()
        conn.close()
    
    def get_connection(self):
        """Get database connection"""
        conn = sqlite3.connect(self.db_path)
        conn.row_factory = sqlite3.Row
        return conn
    
    # Teacher methods
    @staticmethod
    def create_teacher(name: str, email: str, institution: str, subject: str, password_hash: str) -> Tuple[Optional[str], str]:
        """Create a new teacher"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            # Check if email already exists
            cursor.execute('SELECT id FROM teachers WHERE email = ?', (email,))
            if cursor.fetchone():
                conn.close()
                return None, "Email already registered"
            
            teacher_id = str(uuid.uuid4())
            created_at = datetime.now().isoformat()
            
            cursor.execute('''
                INSERT INTO teachers (id, name, email, institution, subject, password_hash, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (teacher_id, name, email, institution, subject, password_hash, created_at))
            
            conn.commit()
            conn.close()
            
            return teacher_id, "Teacher created successfully"
            
        except Exception as e:
            return None, str(e)
    
    @staticmethod
    def get_teacher_by_email(email: str) -> Optional[Dict]:
        """Get teacher by email"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('SELECT * FROM teachers WHERE email = ? AND is_active = 1', (email,))
            teacher = cursor.fetchone()
            conn.close()
            
            return dict(teacher) if teacher else None
            
        except Exception:
            return None
    
    @staticmethod
    def get_teacher_by_id(teacher_id: str) -> Optional[Dict]:
        """Get teacher by ID"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('SELECT * FROM teachers WHERE id = ? AND is_active = 1', (teacher_id,))
            teacher = cursor.fetchone()
            conn.close()
            
            return dict(teacher) if teacher else None
            
        except Exception:
            return None
    
    @staticmethod
    def update_teacher_last_login(teacher_id: str) -> bool:
        """Update teacher's last login time"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('''
                UPDATE teachers SET last_login = ? WHERE id = ?
            ''', (datetime.now().isoformat(), teacher_id))
            
            conn.commit()
            conn.close()
            return True
            
        except Exception:
            return False
    
    @staticmethod
    def get_all_teachers() -> List[Dict]:
        """Return all active teachers"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            cursor.execute('''
                SELECT id, name, email, institution, subject, created_at, last_login, is_active
                FROM teachers
                WHERE is_active = 1
                ORDER BY created_at DESC
            ''')
            teachers = [dict(row) for row in cursor.fetchall()]
            conn.close()
            return teachers
        except Exception:
            return []
    
    # Student methods
    @staticmethod
    def create_student(name: str, email: str, institution: str, password_hash: str) -> Tuple[Optional[str], str]:
        """Create a new student"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            # Check if email already exists
            cursor.execute('SELECT id FROM students WHERE email = ?', (email,))
            if cursor.fetchone():
                conn.close()
                return None, "Email already registered"
            
            student_id = str(uuid.uuid4())
            created_at = datetime.now().isoformat()
            
            cursor.execute('''
                INSERT INTO students (id, name, email, institution, password_hash, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (student_id, name, email, institution, password_hash, created_at))
            
            conn.commit()
            conn.close()
            
            return student_id, "Student created successfully"
            
        except Exception as e:
            return None, str(e)
    
    @staticmethod
    def get_student_by_email(email: str) -> Optional[Dict]:
        """Get student by email"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('SELECT * FROM students WHERE email = ? AND is_active = 1', (email,))
            student = cursor.fetchone()
            conn.close()
            
            return dict(student) if student else None
            
        except Exception:
            return None
    
    @staticmethod
    def get_student_by_id(student_id: str) -> Optional[Dict]:
        """Get student by ID"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('SELECT * FROM students WHERE id = ? AND is_active = 1', (student_id,))
            student = cursor.fetchone()
            conn.close()
            
            return dict(student) if student else None
            
        except Exception:
            return None
    
    @staticmethod
    def get_all_students() -> List[Dict]:
        """Return all active students"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            cursor.execute('''
                SELECT id, name, email, institution, created_at, last_login, is_active
                FROM students
                WHERE is_active = 1
                ORDER BY created_at DESC
            ''')
            students = [dict(row) for row in cursor.fetchall()]
            conn.close()
            return students
        except Exception:
            return []
    
    # Lecture methods
    @staticmethod
    def create_lecture(teacher_id: str, title: str, description: str, scheduled_time: str, duration: int) -> Tuple[Optional[str], str]:
        """Create a new lecture"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            lecture_id = str(uuid.uuid4())
            created_at = datetime.now().isoformat()
            
            cursor.execute('''
                INSERT INTO lectures (id, teacher_id, title, description, scheduled_time, duration, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (lecture_id, teacher_id, title, description, scheduled_time, duration, created_at))
            
            conn.commit()
            conn.close()
            
            return lecture_id, "Lecture created successfully"
            
        except Exception as e:
            return None, str(e)
    
    @staticmethod
    def get_teacher_lectures(teacher_id: str) -> List[Dict]:
        """Get all lectures for a teacher"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT * FROM lectures 
                WHERE teacher_id = ? AND is_active = 1 
                ORDER BY scheduled_time DESC
            ''', (teacher_id,))
            
            lectures = [dict(row) for row in cursor.fetchall()]
            conn.close()
            
            return lectures
            
        except Exception:
            return []
    
    @staticmethod
    def get_all_lectures() -> List[Dict]:
        """Get all active lectures"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT l.*, t.name as teacher_name, t.institution as teacher_institution, t.id as teacher_id
                FROM lectures l
                JOIN teachers t ON l.teacher_id = t.id
                WHERE l.is_active = 1 AND t.is_active = 1
                ORDER BY l.scheduled_time DESC
            ''')
            
            lectures = [dict(row) for row in cursor.fetchall()]
            conn.close()
            
            return lectures
            
        except Exception:
            return []
    
    @staticmethod
    def get_lecture_by_id(lecture_id: str) -> Optional[Dict]:
        """Get lecture by ID"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('SELECT * FROM lectures WHERE id = ? AND is_active = 1', (lecture_id,))
            lecture = cursor.fetchone()
            conn.close()
            
            return dict(lecture) if lecture else None
            
        except Exception:
            return None
    
    # Enrollment methods
    @staticmethod
    def enroll_student(student_id: str, lecture_id: str) -> Tuple[Optional[str], str]:
        """Enroll a student in a lecture"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            # Check if already enrolled
            cursor.execute('''
                SELECT id FROM enrollments 
                WHERE student_id = ? AND lecture_id = ? AND is_active = 1
            ''', (student_id, lecture_id))
            
            if cursor.fetchone():
                conn.close()
                return None, "Already enrolled"
            
            enrollment_id = str(uuid.uuid4())
            enrolled_at = datetime.now().isoformat()
            
            cursor.execute('''
                INSERT INTO enrollments (id, student_id, lecture_id, enrolled_at)
                VALUES (?, ?, ?, ?)
            ''', (enrollment_id, student_id, lecture_id, enrolled_at))
            
            conn.commit()
            conn.close()
            
            return enrollment_id, "Enrolled successfully"
            
        except Exception as e:
            return None, str(e)
    
    @staticmethod
    def is_student_enrolled(student_id: str, lecture_id: str) -> bool:
        """Check if student is enrolled in lecture"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT id FROM enrollments 
                WHERE student_id = ? AND lecture_id = ? AND is_active = 1
            ''', (student_id, lecture_id))
            
            result = cursor.fetchone()
            conn.close()
            
            return result is not None
            
        except Exception:
            return False
    
    @staticmethod
    def get_student_enrolled_lectures(student_id: str) -> List[Dict]:
        """Get lectures student is enrolled in"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT l.*, t.name as teacher_name, t.institution as teacher_institution,
                       e.enrolled_at
                FROM lectures l
                JOIN enrollments e ON l.id = e.lecture_id
                JOIN teachers t ON l.teacher_id = t.id
                WHERE e.student_id = ? AND e.is_active = 1 
                  AND l.is_active = 1 AND t.is_active = 1
                ORDER BY l.scheduled_time DESC
            ''', (student_id,))
            
            lectures = [dict(row) for row in cursor.fetchall()]
            conn.close()
            
            return lectures
            
        except Exception:
            return []
    
    @staticmethod
    def get_lecture_enrolled_students(lecture_id: str) -> List[Dict]:
        """Get students enrolled in a lecture"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT s.*, e.enrolled_at
                FROM students s
                JOIN enrollments e ON s.id = e.student_id
                WHERE e.lecture_id = ? AND e.is_active = 1 AND s.is_active = 1
                ORDER BY e.enrolled_at DESC
            ''', (lecture_id,))
            
            students = [dict(row) for row in cursor.fetchall()]
            conn.close()
            
            return students
            
        except Exception:
            return []
    
    # Material methods
    @staticmethod
    def add_material(lecture_id: str, title: str, description: str, file_path: str, compressed_path: str, file_size: int, file_type: str) -> Tuple[Optional[str], str]:
        """Add material to lecture"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            material_id = str(uuid.uuid4())
            uploaded_at = datetime.now().isoformat()
            
            cursor.execute('''
                INSERT INTO materials 
                (id, lecture_id, title, description, file_path, compressed_path, file_size, file_type, uploaded_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (material_id, lecture_id, title, description, file_path, 
                  compressed_path, file_size, file_type, uploaded_at))
            
            conn.commit()
            conn.close()
            
            return material_id, "Material added successfully"
            
        except Exception as e:
            return None, str(e)
    
    @staticmethod
    def get_lecture_materials(lecture_id: str) -> List[Dict]:
        """Get all materials for a lecture"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT * FROM materials 
                WHERE lecture_id = ? AND is_active = 1 
                ORDER BY uploaded_at DESC
            ''', (lecture_id,))
            
            materials = [dict(row) for row in cursor.fetchall()]
            conn.close()
            
            return materials
            
        except Exception:
            return []
    
    @staticmethod
    def get_material_details(material_id: str) -> Optional[Dict]:
        """Get material details by ID"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT m.*, l.teacher_id, l.title as lecture_title
                FROM materials m
                JOIN lectures l ON m.lecture_id = l.id
                WHERE m.id = ? AND m.is_active = 1
            ''', (material_id,))
            
            material = cursor.fetchone()
            conn.close()
            
            return dict(material) if material else None
            
        except Exception:
            return None
    
    # Quiz methods
    @staticmethod
    def create_quiz(lecture_id: str, question: str, options: List[str], correct_answer: str) -> Tuple[Optional[str], str]:
        """Create a quiz for lecture"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            quiz_id = str(uuid.uuid4())
            created_at = datetime.now().isoformat()
            options_json = json.dumps(options)
            
            cursor.execute('''
                INSERT INTO quizzes (id, lecture_id, question, options, correct_answer, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (quiz_id, lecture_id, question, options_json, correct_answer, created_at))
            
            conn.commit()
            conn.close()
            
            return quiz_id, "Quiz created successfully"
            
        except Exception as e:
            return None, str(e)
    
    @staticmethod
    def submit_quiz_response(student_id: str, quiz_id: str, response: str) -> Tuple[Optional[str], str]:
        """Submit quiz response"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            # Get correct answer
            cursor.execute('SELECT correct_answer FROM quizzes WHERE id = ?', (quiz_id,))
            quiz = cursor.fetchone()
            
            if not quiz:
                conn.close()
                return None, "Quiz not found"
            
            is_correct = 1 if response == quiz['correct_answer'] else 0
            response_id = str(uuid.uuid4())
            submitted_at = datetime.now().isoformat()
            
            # Insert or replace response (unique per student+quiz)
            cursor.execute('''
                INSERT OR REPLACE INTO quiz_responses 
                (id, student_id, quiz_id, response, is_correct, submitted_at)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (response_id, student_id, quiz_id, response, is_correct, submitted_at))
            
            conn.commit()
            conn.close()
            
            return response_id, "Response submitted successfully"
            
        except Exception as e:
            return None, str(e)
    
    # Poll methods
    @staticmethod
    def create_poll(lecture_id: str, question: str, options: List[str]) -> Tuple[Optional[str], str]:
        """Create a poll for lecture"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            poll_id = str(uuid.uuid4())
            created_at = datetime.now().isoformat()
            options_json = json.dumps(options)
            
            cursor.execute('''
                INSERT INTO polls (id, lecture_id, question, options, created_at)
                VALUES (?, ?, ?, ?, ?)
            ''', (poll_id, lecture_id, question, options_json, created_at))
            
            conn.commit()
            conn.close()
            
            return poll_id, "Poll created successfully"
            
        except Exception as e:
            return None, str(e)
    
    @staticmethod
    def submit_poll_response(student_id: str, poll_id: str, response: str) -> Tuple[Optional[str], str]:
        """Submit poll response"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            response_id = str(uuid.uuid4())
            submitted_at = datetime.now().isoformat()
            
            cursor.execute('''
                INSERT INTO poll_responses (id, student_id, poll_id, response, submitted_at)
                VALUES (?, ?, ?, ?, ?)
            ''', (response_id, student_id, poll_id, response, submitted_at))
            
            conn.commit()
            conn.close()
            
            return response_id, "Poll response submitted successfully"
        except Exception as e:
            return None, str(e)
    
    # Discussion methods
    @staticmethod
    def add_discussion_message(lecture_id: str, user_id: str, message: str, user_type: str = 'student') -> Tuple[Optional[str], str]:
        """Add message to discussion"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            message_id = str(uuid.uuid4())
            created_at = datetime.now().isoformat()
            
            cursor.execute('''
                INSERT INTO discussion_messages (id, lecture_id, user_id, user_type, message, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (message_id, lecture_id, user_id, user_type, message, created_at))
            
            conn.commit()
            conn.close()
            
            return message_id, "Message added successfully"
            
        except Exception as e:
            return None, str(e)
    
    @staticmethod
    def get_discussion_messages(lecture_id: str) -> List[Dict]:
        """Get discussion messages for lecture"""
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            
            cursor.execute('''
                SELECT dm.*, 
                       CASE 
                           WHEN dm.user_type = 'teacher' THEN t.name
                           WHEN dm.user_type = 'student' THEN s.name
                           ELSE dm.user_id
                       END as user_name
                FROM discussion_messages dm
                LEFT JOIN teachers t ON dm.user_id = t.id AND dm.user_type = 'teacher'
                LEFT JOIN students s ON dm.user_id = s.id AND dm.user_type = 'student'
                WHERE dm.lecture_id = ? AND dm.is_active = 1
                ORDER BY dm.created_at ASC
            ''', (lecture_id,))
            
            messages = [dict(row) for row in cursor.fetchall()]
            conn.close()
            
            return messages
            
        except Exception:
            return []

    # Cohort methods
    @staticmethod
    def create_cohort(name: str, description: str, subject: str, teacher_id: str) -> Tuple[Optional[str], str]:
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            cohort_id = str(uuid.uuid4())
            created_at = datetime.now().isoformat()
            code = cohort_id.split('-')[0]
            cursor.execute('''
                INSERT INTO cohorts (id, name, description, subject, teacher_id, code, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (cohort_id, name, description, subject, teacher_id, code, created_at))
            conn.commit()
            conn.close()
            return cohort_id, "Cohort created successfully"
        except Exception as e:
            return None, str(e)

    @staticmethod
    def delete_cohort(cohort_id: str) -> Tuple[bool, str]:
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            cursor.execute('UPDATE cohorts SET is_active = 0 WHERE id = ?', (cohort_id,))
            # Note: keep relations; they become inactive via cohort inactive
            conn.commit()
            conn.close()
            return True, "Cohort deleted"
        except Exception as e:
            return False, str(e)

    @staticmethod
    def get_all_cohorts() -> List[Dict]:
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            cursor.execute('''
                SELECT c.*, t.name AS teacher_name,
                    (SELECT COUNT(*) FROM cohort_students cs WHERE cs.cohort_id = c.id) AS student_count
                FROM cohorts c
                JOIN teachers t ON c.teacher_id = t.id
                WHERE c.is_active = 1 AND t.is_active = 1
                ORDER BY c.created_at DESC
            ''')
            rows = [dict(row) for row in cursor.fetchall()]
            conn.close()
            return rows
        except Exception:
            return []

    @staticmethod
    def get_cohort_by_id(cohort_id: str) -> Optional[Dict]:
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            cursor.execute('''
                SELECT * FROM cohorts WHERE id = ? AND is_active = 1
            ''', (cohort_id,))
            row = cursor.fetchone()
            conn.close()
            return dict(row) if row else None
        except Exception:
            return None

    @staticmethod
    def get_teacher_cohorts(teacher_id: str) -> List[Dict]:
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            cursor.execute('''
                SELECT c.*, (SELECT COUNT(*) FROM cohort_students cs WHERE cs.cohort_id = c.id) AS student_count
                FROM cohorts c
                WHERE c.teacher_id = ? AND c.is_active = 1
                ORDER BY c.created_at DESC
            ''', (teacher_id,))
            rows = [dict(row) for row in cursor.fetchall()]
            conn.close()
            return rows
        except Exception:
            return []

    @staticmethod
    def get_student_cohorts(student_id: str) -> List[Dict]:
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            cursor.execute('''
                SELECT c.*, t.name AS teacher_name
                FROM cohorts c
                JOIN cohort_students cs ON cs.cohort_id = c.id
                JOIN teachers t ON c.teacher_id = t.id
                WHERE cs.student_id = ? AND c.is_active = 1 AND t.is_active = 1
                ORDER BY c.created_at DESC
            ''', (student_id,))
            rows = [dict(row) for row in cursor.fetchall()]
            conn.close()
            return rows
        except Exception:
            return []

    @staticmethod
    def join_cohort_by_code(student_id: str, cohort_code: str) -> Tuple[bool, str]:
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            cursor.execute('SELECT id FROM cohorts WHERE code = ? AND is_active = 1', (cohort_code,))
            row = cursor.fetchone()
            if not row:
                conn.close()
                return False, 'Invalid cohort code'
            cohort_id = row['id']
            # Upsert membership
            cursor.execute('SELECT id FROM cohort_students WHERE cohort_id = ? AND student_id = ?', (cohort_id, student_id))
            if cursor.fetchone():
                conn.close()
                return True, 'Already in cohort'
            cs_id = str(uuid.uuid4())
            joined_at = datetime.now().isoformat()
            cursor.execute('''
                INSERT INTO cohort_students (id, cohort_id, student_id, joined_at)
                VALUES (?, ?, ?, ?)
            ''', (cs_id, cohort_id, student_id, joined_at))
            conn.commit()
            conn.close()
            return True, 'Joined cohort'
        except Exception as e:
            return False, str(e)

    @staticmethod
    def is_student_in_cohort(student_id: str, cohort_id: str) -> bool:
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            cursor.execute('SELECT 1 FROM cohort_students WHERE cohort_id = ? AND student_id = ?', (cohort_id, student_id))
            ok = cursor.fetchone() is not None
            conn.close()
            return ok
        except Exception:
            return False

    @staticmethod
    def create_lecture_for_cohort(cohort_id: str, teacher_id: str, title: str, description: str, scheduled_time: str, duration: int) -> Tuple[Optional[str], str]:
        try:
            # Create lecture
            lecture_id, msg = DatabaseManager.create_lecture(teacher_id, title, description, scheduled_time, duration)
            if not lecture_id:
                return None, msg
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            link_id = str(uuid.uuid4())
            cursor.execute('''
                INSERT INTO cohort_lectures (id, cohort_id, lecture_id)
                VALUES (?, ?, ?)
            ''', (link_id, cohort_id, lecture_id))
            conn.commit()
            conn.close()
            return lecture_id, 'Lecture created for cohort'
        except Exception as e:
            return None, str(e)

    @staticmethod
    def get_cohort_lectures(cohort_id: str) -> List[Dict]:
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            cursor.execute('''
                SELECT l.*, t.name AS teacher_name
                FROM cohort_lectures cl
                JOIN lectures l ON cl.lecture_id = l.id
                JOIN teachers t ON l.teacher_id = t.id
                WHERE cl.cohort_id = ? AND l.is_active = 1 AND t.is_active = 1
                ORDER BY l.scheduled_time DESC
            ''', (cohort_id,))
            rows = [dict(row) for row in cursor.fetchall()]
            conn.close()
            return rows
        except Exception:
            return []

    @staticmethod
    def get_cohort_students(cohort_id: str) -> List[Dict]:
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            cursor.execute('''
                SELECT s.* FROM cohort_students cs
                JOIN students s ON s.id = cs.student_id
                WHERE cs.cohort_id = ?
                ORDER BY cs.joined_at DESC
            ''', (cohort_id,))
            rows = [dict(row) for row in cursor.fetchall()]
            conn.close()
            return rows
        except Exception:
            return []

    @staticmethod
    def add_student_to_cohort(cohort_id: str, student_id: str) -> Tuple[bool, str]:
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            cursor.execute('SELECT id FROM cohort_students WHERE cohort_id = ? AND student_id = ?', (cohort_id, student_id))
            if cursor.fetchone():
                conn.close()
                return True, 'Already in cohort'
            cs_id = str(uuid.uuid4())
            joined_at = datetime.now().isoformat()
            cursor.execute('INSERT INTO cohort_students (id, cohort_id, student_id, joined_at) VALUES (?, ?, ?, ?)', (cs_id, cohort_id, student_id, joined_at))
            conn.commit()
            conn.close()
            return True, 'Student added to cohort'
        except Exception as e:
            return False, str(e)

    @staticmethod
    def remove_student_from_cohort(cohort_id: str, student_id: str) -> Tuple[bool, str]:
        try:
            db = DatabaseManager()
            conn = db.get_connection()
            cursor = conn.cursor()
            cursor.execute('DELETE FROM cohort_students WHERE cohort_id = ? AND student_id = ?', (cohort_id, student_id))
            conn.commit()
            conn.close()
            return True, 'Removed from cohort'
        except Exception as e:
            return False, str(e)