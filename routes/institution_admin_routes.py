"""
Institution Admin Routes
Handles institution admin dashboard and management operations
"""

from flask import Blueprint, request, jsonify, session, render_template
from werkzeug.security import generate_password_hash
from middlewares.auth_middleware import AuthMiddleware
from utils.database_supabase import DatabaseManager
from utils.email_service import EmailService
from datetime import datetime

# Initialize blueprint
institution_admin_bp = Blueprint('institution_admin', __name__, url_prefix='/institution-admin')

# Initialize services
db = DatabaseManager()
auth_middleware = AuthMiddleware(None, db)
email_service = EmailService()

@institution_admin_bp.route('/dashboard')
def dashboard():
    """Institution admin dashboard"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return redirect('/institution-admin/login')
        
        institution = db.get_institution_by_id(institution_id)
        if not institution:
            return redirect('/institution-admin/login')
        
        return render_template('institution_admin_dashboard.html', institution=institution)
    except Exception as e:
        return render_template('error.html', error="Error loading dashboard", message=str(e)), 500

@institution_admin_bp.route('/login', methods=['GET', 'POST'])
def login():
    """Institution admin login"""
    if request.method == 'GET':
        return render_template('institution_login.html')
    
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        
        if not email or not password:
            return jsonify({'error': 'Email and password are required'}), 400
        
        # Get institution admin
        admin = db.get_institution_admin_by_email(email)
        if not admin:
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Check password
        from utils.password_utils import check_password_hash_compatible
        if not check_password_hash_compatible(admin['password_hash'], password):
            return jsonify({'error': 'Invalid credentials'}), 401
        
        # Set session
        session['user_id'] = admin['id']
        session['user_type'] = 'admin'
        session['institution_id'] = admin['institution_id']
        session['name'] = admin['name']
        session['email'] = admin['email']
        
        # Update last login
        db.update_institution_admin_last_login(admin['id'])
        
        return jsonify({
            'success': True,
            'message': 'Login successful',
            'redirect_url': '/institution-admin/dashboard'
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/api/stats')
@auth_middleware.institution_admin_required
def get_stats():
    """Get institution statistics"""
    try:
        institution_id = session.get('institution_id')
        stats = db.get_institution_stats(institution_id)
        return jsonify({'success': True, 'stats': stats}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/api/teachers')
@auth_middleware.institution_admin_required
def get_teachers():
    """Get all teachers in institution"""
    try:
        institution_id = session.get('institution_id')
        teachers = db.get_teachers_by_institution(institution_id)
        return jsonify({'success': True, 'teachers': teachers}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/api/students')
@auth_middleware.institution_admin_required
def get_students():
    """Get all students in institution"""
    try:
        institution_id = session.get('institution_id')
        students = db.get_students_by_institution(institution_id)
        return jsonify({'success': True, 'students': students}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/api/cohorts')
@auth_middleware.institution_admin_required
def get_cohorts():
    """Get all cohorts in institution"""
    try:
        institution_id = session.get('institution_id')
        cohorts = db.get_cohorts_by_institution(institution_id)
        return jsonify({'success': True, 'cohorts': cohorts}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/api/lectures')
@auth_middleware.institution_admin_required
def get_lectures():
    """Get all lectures in institution"""
    try:
        institution_id = session.get('institution_id')
        lectures = db.get_lectures_by_institution(institution_id)
        return jsonify({'success': True, 'lectures': lectures}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/teachers', methods=['POST'])
@auth_middleware.institution_admin_required
def create_teacher():
    """Create a new teacher"""
    try:
        institution_id = session.get('institution_id')
        data = request.get_json()
        
        teacher_id, message = db.create_teacher(
            institution_id=institution_id,
            name=data['name'],
            email=data['email'],
            subject=data['subject'],
            password_hash=generate_password_hash(data['password'], method='scrypt'),
            employee_id=data.get('employee_id'),
            department=data.get('department'),
            phone=data.get('phone'),
            bio=data.get('bio'),
            created_by=session.get('user_id')
        )
        
        if teacher_id:
            try:
                email_service.send_welcome_email(
                    user_email=data['email'],
                    user_name=data['name'],
                    user_type='teacher'
                )
            except Exception as email_error:
                print(f"Failed to send welcome email: {str(email_error)}")
            
            return jsonify({
                'success': True,
                'message': 'Teacher created successfully',
                'teacher_id': teacher_id
            }), 201
        else:
            return jsonify({'error': message}), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/students', methods=['POST'])
@auth_middleware.institution_admin_required
def create_student():
    """Create a new student"""
    try:
        institution_id = session.get('institution_id')
        data = request.get_json()
        
        student_id, message = db.create_student(
            institution_id=institution_id,
            name=data['name'],
            email=data['email'],
            password_hash=generate_password_hash(data['password'], method='scrypt'),
            student_id=data.get('student_id'),
            roll_number=data.get('roll_number'),
            class_name=data.get('class'),
            section=data.get('section'),
            phone=data.get('phone'),
            parent_phone=data.get('parent_phone'),
            date_of_birth=data.get('date_of_birth'),
            created_by=session.get('user_id')
        )
        
        if student_id:
            try:
                email_service.send_welcome_email(
                    user_email=data['email'],
                    user_name=data['name'],
                    user_type='student'
                )
            except Exception as email_error:
                print(f"Failed to send welcome email: {str(email_error)}")
            
            return jsonify({
                'success': True,
                'message': 'Student created successfully',
                'student_id': student_id
            }), 201
        else:
            return jsonify({'error': message}), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/cohorts', methods=['POST'])
@auth_middleware.institution_admin_required
def create_cohort():
    """Create a new cohort"""
    try:
        institution_id = session.get('institution_id')
        data = request.get_json()
        
        cohort_id, message = db.create_cohort(
            institution_id=institution_id,
            name=data['name'],
            description=data.get('description'),
            enrollment_code=data.get('enrollment_code'),
            max_students=data.get('max_students', 50),
            academic_year=data.get('academic_year'),
            semester=data.get('semester'),
            session=data.get('session'),
            start_date=data.get('start_date'),
            end_date=data.get('end_date'),
            subject=data.get('subject', 'General'),
            created_by=session.get('user_id')
        )
        
        if cohort_id:
            print(f"✅ Cohort created successfully: {cohort_id}")
            print(f"📧 Starting email notification process...")
            
            # Check email service configuration
            if not email_service.smtp_username or not email_service.smtp_password:
                print("⚠️ Email service not configured - SMTP credentials missing")
                return jsonify({
                    'success': True,
                    'message': 'Cohort created successfully (email notifications disabled)',
                    'cohort_id': cohort_id
                }), 201
            
            # Send email notifications
            try:
                # Get institution admin details
                admin = db.get_institution_admin_by_id(session.get('user_id'))
                cohort = db.get_cohort_by_id(cohort_id)
                
                if admin and cohort:
                    # Send confirmation email to admin
                    try:
                        email_service.send_welcome_email(
                            user_email=admin['email'],
                            user_name=admin['name'],
                            user_type='institution_admin',
                            cohort_name=cohort['name']
                        )
                        print(f"✅ Sent cohort creation confirmation to admin: {admin['email']}")
                    except Exception as admin_email_error:
                        print(f"❌ Error sending confirmation to admin: {admin_email_error}")
                    
                    # Get all teachers in the institution
                    teachers = db.get_institution_teachers(institution_id)
                    print(f"📧 Sending cohort notifications to {len(teachers)} teachers")
                    
                    # Send email to each teacher
                    for teacher in teachers:
                        try:
                            email_service.send_welcome_email(
                                user_email=teacher['email'],
                                user_name=teacher['name'],
                                user_type='teacher',
                                cohort_name=cohort['name']
                            )
                            print(f"✅ Sent notification to teacher: {teacher['email']}")
                        except Exception as teacher_email_error:
                            print(f"❌ Error sending notification to teacher {teacher['email']}: {teacher_email_error}")
            except Exception as email_error:
                print(f"Error sending cohort notifications: {email_error}")
                # Don't fail the cohort creation if email fails
            
            return jsonify({
                'success': True,
                'message': 'Cohort created successfully',
                'cohort_id': cohort_id
            }), 201
        else:
            return jsonify({'error': message}), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/lectures', methods=['POST'])
@auth_middleware.institution_admin_required
def create_lecture():
    """Create a new lecture"""
    try:
        institution_id = session.get('institution_id')
        data = request.get_json()
        
        lecture_id, message = db.create_lecture(
            institution_id=institution_id,
            cohort_id=data['cohort_id'],
            teacher_id=data['teacher_id'],
            title=data['title'],
            description=data.get('description'),
            scheduled_time=data.get('scheduled_time'),
            duration=data.get('duration', 60),
            lecture_type=data.get('lecture_type', 'live'),
            meeting_link=data.get('meeting_link'),
            meeting_id=data.get('meeting_id'),
            meeting_password=data.get('meeting_password'),
            recording_enabled=data.get('recording_enabled', True),
            chat_enabled=data.get('chat_enabled', True),
            max_participants=data.get('max_participants', 100),
            created_by=session.get('user_id')
        )
        
        if lecture_id:
            # Send lecture notification to teacher
            try:
                teacher = db.get_teacher_by_id(data['teacher_id'])
                if teacher:
                    email_service.send_lecture_notification(
                        user_email=teacher['email'],
                        user_name=teacher['name'],
                        lecture_title=data['title'],
                        teacher_name=teacher['name'],
                        scheduled_time=data.get('scheduled_time')
                    )
            except Exception as email_error:
                print(f"Failed to send lecture notification: {str(email_error)}")
            
            return jsonify({
                'success': True,
                'message': 'Lecture created successfully',
                'lecture_id': lecture_id
            }), 201
        else:
            return jsonify({'error': message}), 400
            
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/cohorts/<cohort_id>/teachers', methods=['GET', 'POST', 'DELETE'])
@auth_middleware.institution_admin_required
def manage_cohort_teachers(cohort_id):
    """Manage teacher assignments to cohorts"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        if request.method == 'GET':
            # Get teachers assigned to cohort
            teachers = db.get_cohort_teachers(cohort_id)
            return jsonify({
                'success': True,
                'teachers': teachers
            }), 200
            
        elif request.method == 'POST':
            # Assign teacher to cohort
            data = request.get_json()
            teacher_id = data.get('teacher_id')
            role = data.get('role', 'teacher')
            
            if not teacher_id:
                return jsonify({'error': 'Teacher ID is required'}), 400
            
            success = db.assign_teacher_to_cohort(
                teacher_id=teacher_id, 
                cohort_id=cohort_id, 
                role=role, 
                assigned_by=session.get('user_id')
            )
            
            if success:
                # Send email notification to teacher
                try:
                    teacher = db.get_teacher_by_id(teacher_id)
                    cohort = db.get_cohort_by_id(cohort_id)
                    
                    if teacher and cohort:
                        email_service.send_welcome_email(
                            user_email=teacher['email'],
                            user_name=teacher['name'],
                            user_type='teacher',
                            cohort_name=cohort['name']
                        )
                        print(f"✅ Sent teacher assignment notification to: {teacher['email']}")
                except Exception as email_error:
                    print(f"❌ Error sending teacher assignment notification: {email_error}")
                    # Don't fail the assignment if email fails
                
                return jsonify({
                    'success': True,
                    'message': 'Teacher assigned to cohort successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to assign teacher to cohort'}), 400
                
        elif request.method == 'DELETE':
            # Remove teacher from cohort
            data = request.get_json()
            teacher_id = data.get('teacher_id')
            
            if not teacher_id:
                return jsonify({'error': 'Teacher ID is required'}), 400
            
            success = db.remove_teacher_from_cohort(teacher_id, cohort_id)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Teacher removed from cohort successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to remove teacher from cohort'}), 400
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/cohorts/<cohort_id>/students', methods=['GET', 'POST', 'DELETE'])
@auth_middleware.institution_admin_required
def manage_cohort_students(cohort_id):
    """Manage student enrollments in cohorts"""
    try:
        institution_id = session.get('institution_id')
        if not institution_id:
            return jsonify({'error': 'Not authenticated'}), 401
        
        if request.method == 'GET':
            # Get students enrolled in cohort
            students = db.get_cohort_students(cohort_id)
            return jsonify({
                'success': True,
                'students': students
            }), 200
            
        elif request.method == 'POST':
            # Enroll student in cohort
            data = request.get_json()
            student_id = data.get('student_id')
            
            if not student_id:
                return jsonify({'error': 'Student ID is required'}), 400
            
            success = db.enroll_student_in_cohort(
                institution_id=institution_id,
                student_id=student_id, 
                cohort_id=cohort_id, 
                enrolled_by=session.get('user_id')
            )
            
            if success:
                # Send enrollment notification to student
                try:
                    student = db.get_student_by_id(student_id)
                    cohort = db.get_cohort_by_id(cohort_id)
                    if student and cohort:
                        email_service.send_welcome_email(
                            user_email=student['email'],
                            user_name=student['name'],
                            user_type='student',
                            cohort_name=cohort['name'],
                            cohort_code=cohort.get('enrollment_code')
                        )
                except Exception as email_error:
                    print(f"Failed to send enrollment notification: {str(email_error)}")
                
                return jsonify({
                    'success': True,
                    'message': 'Student enrolled in cohort successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to enroll student in cohort'}), 400
                
        elif request.method == 'DELETE':
            # Remove student from cohort
            data = request.get_json()
            student_id = data.get('student_id')
            
            if not student_id:
                return jsonify({'error': 'Student ID is required'}), 400
            
            success = db.remove_student_from_cohort(student_id, cohort_id)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Student removed from cohort successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to remove student from cohort'}), 400
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/teachers/<teacher_id>', methods=['PUT', 'DELETE'])
@auth_middleware.institution_admin_required
def manage_teacher(teacher_id):
    """Update or delete a teacher"""
    try:
        institution_id = session.get('institution_id')
        
        if request.method == 'PUT':
            # Update teacher
            data = request.get_json()
            
            # Verify teacher belongs to this institution
            teacher = db.get_teacher_by_id(teacher_id)
            if not teacher or teacher['institution_id'] != institution_id:
                return jsonify({'error': 'Teacher not found'}), 404
            
            # Update teacher data
            update_data = {}
            if 'name' in data:
                update_data['name'] = data['name']
            if 'email' in data:
                update_data['email'] = data['email']
            if 'subject' in data:
                update_data['subject'] = data['subject']
            if 'is_active' in data:
                update_data['is_active'] = data['is_active']
            
            success = db.update_teacher(teacher_id, update_data)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Teacher updated successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to update teacher'}), 400
                
        elif request.method == 'DELETE':
            # Delete teacher (soft delete)
            teacher = db.get_teacher_by_id(teacher_id, active_only=False)
            if not teacher or teacher['institution_id'] != institution_id:
                return jsonify({'error': 'Teacher not found'}), 404
            
            success = db.delete_teacher(teacher_id)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Teacher deleted successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to delete teacher'}), 400
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/students/<student_id>', methods=['PUT', 'DELETE'])
@auth_middleware.institution_admin_required
def manage_student(student_id):
    """Update or delete a student"""
    try:
        institution_id = session.get('institution_id')
        
        if request.method == 'PUT':
            # Update student
            data = request.get_json()
            
            # Verify student belongs to this institution
            student = db.get_student_by_id(student_id)
            if not student or student['institution_id'] != institution_id:
                return jsonify({'error': 'Student not found'}), 404
            
            # Update student data
            update_data = {}
            if 'name' in data:
                update_data['name'] = data['name']
            if 'email' in data:
                update_data['email'] = data['email']
            if 'is_active' in data:
                update_data['is_active'] = data['is_active']
            
            success = db.update_student(student_id, update_data)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Student updated successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to update student'}), 400
                
        elif request.method == 'DELETE':
            # Delete student (soft delete)
            student = db.get_student_by_id(student_id, active_only=False)
            if not student or student['institution_id'] != institution_id:
                return jsonify({'error': 'Student not found'}), 404
            
            success = db.delete_student(student_id)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Student deleted successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to delete student'}), 400
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/cohorts/<cohort_id>', methods=['PUT', 'DELETE'])
@auth_middleware.institution_admin_required
def manage_cohort(cohort_id):
    """Update or delete a cohort"""
    try:
        institution_id = session.get('institution_id')
        
        if request.method == 'PUT':
            # Update cohort
            data = request.get_json()
            
            # Verify cohort belongs to this institution
            cohort = db.get_cohort_by_id(cohort_id)
            if not cohort or cohort['institution_id'] != institution_id:
                return jsonify({'error': 'Cohort not found'}), 404
            
            # Update cohort data
            update_data = {}
            if 'name' in data:
                update_data['name'] = data['name']
            if 'description' in data:
                update_data['description'] = data['description']
            if 'subject' in data:
                update_data['subject'] = data['subject']
            if 'is_active' in data:
                update_data['is_active'] = data['is_active']
            
            success = db.update_cohort(cohort_id, update_data)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Cohort updated successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to update cohort'}), 400
                
        elif request.method == 'DELETE':
            # Delete cohort (soft delete)
            cohort = db.get_cohort_by_id(cohort_id, active_only=False)
            if not cohort or cohort['institution_id'] != institution_id:
                return jsonify({'error': 'Cohort not found'}), 404
            
            success = db.delete_cohort(cohort_id)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Cohort deleted successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to delete cohort'}), 400
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@institution_admin_bp.route('/lectures/<lecture_id>', methods=['PUT', 'DELETE'])
@auth_middleware.institution_admin_required
def manage_lecture(lecture_id):
    """Update or delete a lecture"""
    try:
        institution_id = session.get('institution_id')
        
        if request.method == 'PUT':
            # Update lecture
            data = request.get_json()
            
            # Verify lecture belongs to this institution
            lecture = db.get_lecture_by_id(lecture_id)
            if not lecture or lecture['institution_id'] != institution_id:
                return jsonify({'error': 'Lecture not found'}), 404
            
            # Update lecture data
            update_data = {}
            if 'title' in data:
                update_data['title'] = data['title']
            if 'description' in data:
                update_data['description'] = data['description']
            if 'scheduled_time' in data:
                update_data['scheduled_time'] = data['scheduled_time']
            if 'duration' in data:
                update_data['duration'] = data['duration']
            if 'status' in data:
                update_data['status'] = data['status']
            if 'is_active' in data:
                update_data['is_active'] = data['is_active']
            
            success = db.update_lecture(lecture_id, update_data)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Lecture updated successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to update lecture'}), 400
                
        elif request.method == 'DELETE':
            # Delete lecture (soft delete)
            lecture = db.get_lecture_by_id(lecture_id, active_only=False)
            if not lecture or lecture['institution_id'] != institution_id:
                return jsonify({'error': 'Lecture not found'}), 404
            
            success = db.delete_lecture(lecture_id)
            
            if success:
                return jsonify({
                    'success': True,
                    'message': 'Lecture deleted successfully'
                }), 200
            else:
                return jsonify({'error': 'Failed to delete lecture'}), 400
                
    except Exception as e:
        return jsonify({'error': str(e)}), 500
