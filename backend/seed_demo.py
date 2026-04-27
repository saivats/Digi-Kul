import sys
import os

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from app.utils.security import hash_password
from app.database import get_supabase

def seed():
    sb = get_supabase()
    password = hash_password("password123")
    
    try:
        # Check if Super Admin exists
        existing_sa = sb.table('super_admins').select('*').eq('email', 'super@digikul.com').execute()
        if not existing_sa.data:
            sb.table('super_admins').insert({
                'name': 'Demo Super Admin',
                'email': 'super@digikul.com',
                'password_hash': password,
                'is_active': True,
            }).execute()

        # Check if Institution exists
        existing_inst = sb.table('institutions').select('*').eq('domain', 'digikul.in').execute()
        if not existing_inst.data:
            inst_res = sb.table('institutions').insert({
                'name': 'Digi-Kul Academy',
                'domain': 'digikul.in'
            }).execute()
            inst_id = inst_res.data[0]['id']
        else:
            inst_id = existing_inst.data[0]['id']

        existing_admin = sb.table('institution_admins').select('*').eq('email', 'admin@digikul.in').execute()
        if not existing_admin.data:
            sb.table('institution_admins').insert({
                'name': 'Admin User',
                'email': 'admin@digikul.in',
                'password_hash': password,
                'institution_id': inst_id,
                'is_active': True,
            }).execute()

        existing_teacher = sb.table('teachers').select('*').eq('email', 'teacher@digikul.in').execute()
        if not existing_teacher.data:
            sb.table('teachers').insert({
                'name': 'Teacher User',
                'email': 'teacher@digikul.in',
                'password_hash': password,
                'institution_id': inst_id,
                'subject': 'Computer Science',
                'is_active': True,
            }).execute()

        existing_student = sb.table('students').select('*').eq('email', 'student@digikul.in').execute()
        if not existing_student.data:
            sb.table('students').insert({
                'name': 'Student User',
                'email': 'student@digikul.in',
                'password_hash': password,
                'institution_id': inst_id,
                'is_active': True,
            }).execute()
        print("Creating demo cohort...")
        existing_cohort = sb.table('cohorts').select('*').eq('name', 'Demo Cohort 2026').execute()
        if not existing_cohort.data:
            cohort_res = sb.table('cohorts').insert({
                'institution_id': inst_id,
                'name': 'Demo Cohort 2026',
                'description': 'A sample cohort for demonstrating the platform.',
                'enrollment_code': 'DEMO2026',
                'max_students': 50,
                'academic_year': '2026',
                'semester': 'Spring',
                'start_date': '2026-01-01',
                'end_date': '2026-06-30',
                'created_by': existing_admin.data[0]['id'] if existing_admin.data else None
            }).execute()
            cohort_id = cohort_res.data[0]['id']
        else:
            cohort_id = existing_cohort.data[0]['id']

        print("Assigning teacher and student to cohort...")
        # Get teacher and student IDs
        t_id = existing_teacher.data[0]['id'] if existing_teacher.data else sb.table('teachers').select('id').eq('email', 'teacher@digikul.in').execute().data[0]['id']
        s_id = existing_student.data[0]['id'] if existing_student.data else sb.table('students').select('id').eq('email', 'student@digikul.in').execute().data[0]['id']

        # Assign teacher
        existing_ta = sb.table('teacher_cohorts').select('*').eq('cohort_id', cohort_id).eq('teacher_id', t_id).execute()
        if not existing_ta.data:
            sb.table('teacher_cohorts').insert({
                'cohort_id': cohort_id,
                'teacher_id': t_id,
                'role': 'teacher'
            }).execute()

        # Enroll student
        existing_se = sb.table('enrollments').select('*').eq('cohort_id', cohort_id).eq('student_id', s_id).execute()
        if not existing_se.data:
            sb.table('enrollments').insert({
                'cohort_id': cohort_id,
                'student_id': s_id,
                'institution_id': inst_id,
                'status': 'active'
            }).execute()

        print("Creating demo lectures...")
        existing_lec = sb.table('lectures').select('*').eq('cohort_id', cohort_id).execute()
        if not existing_lec.data:
            sb.table('lectures').insert([
                {
                    'cohort_id': cohort_id,
                    'teacher_id': t_id,
                    'title': 'Introduction to Computer Science',
                    'description': 'Basic concepts and overview.',
                    'scheduled_time': '2026-05-01T10:00:00Z',
                    'duration': 60,
                    'status': 'scheduled',
                    'institution_id': inst_id
                },
                {
                    'cohort_id': cohort_id,
                    'teacher_id': t_id,
                    'title': 'Data Structures',
                    'description': 'Arrays, Lists, Trees.',
                    'scheduled_time': '2026-05-02T10:00:00Z',
                    'duration': 60,
                    'status': 'scheduled',
                    'institution_id': inst_id
                }
            ]).execute()

        print("\nAll demo data created successfully!")
    except Exception as e:
        print(f"Error seeding database: {e}")

if __name__ == "__main__":
    seed()
