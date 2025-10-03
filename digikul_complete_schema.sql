-- ========================================
-- DigiKul Multi-Tenant Educational Platform
-- Complete Database Schema with Super Admin & Institution Management
-- ========================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ========================================
-- Fix for missing columns (Run after table creation)
-- ========================================

-- ========================================
-- SUPER ADMIN SYSTEM
-- ========================================

-- Super Admins table (Global platform administrators)
CREATE TABLE IF NOT EXISTS super_admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    permissions JSONB DEFAULT '{"manage_institutions": true, "manage_super_admins": false, "view_analytics": true}'
);

-- ========================================
-- INSTITUTIONS SYSTEM
-- ========================================

-- Institutions table (Multi-tenant organizations)
CREATE TABLE IF NOT EXISTS institutions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    domain TEXT UNIQUE NOT NULL, -- e.g., "digikul.com", "techacademy.io"
    subdomain TEXT, -- e.g., "digikul", "techacademy" for custom URLs
    logo_url TEXT, -- Institution logo URL
    logo_data TEXT, -- Base64 encoded logo data
    primary_color TEXT DEFAULT '#007bff', -- Brand color
    secondary_color TEXT DEFAULT '#6c757d', -- Secondary brand color
    description TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    address TEXT,
    website TEXT,
    is_active BOOLEAN DEFAULT true,
    created_by UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    settings JSONB
);

-- ========================================
-- USER MANAGEMENT SYSTEM
-- ========================================

-- Institution-specific Admins (Can manage their institution only)
CREATE TABLE IF NOT EXISTS institution_admins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT DEFAULT 'admin', -- 'admin', 'moderator'
    permissions JSONB DEFAULT '{
        "manage_teachers": true,
        "manage_students": true,
        "manage_cohorts": true,
        "view_analytics": true,
        "manage_materials": false,
        "manage_quizzes": false
    }',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    UNIQUE(institution_id, email)
);

-- Teachers table (Institution-specific)
CREATE TABLE IF NOT EXISTS teachers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    subject TEXT NOT NULL,
    employee_id TEXT, -- Institution-specific employee ID
    department TEXT,
    phone TEXT,
    avatar_url TEXT,
    bio TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES institution_admins(id) ON DELETE SET NULL,
    UNIQUE(institution_id, email)
);

-- Students table (Institution-specific)
CREATE TABLE IF NOT EXISTS students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    student_id TEXT, -- Institution-specific student ID
    roll_number TEXT,
    class TEXT,
    section TEXT,
    phone TEXT,
    parent_phone TEXT,
    avatar_url TEXT,
    date_of_birth DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES institution_admins(id) ON DELETE SET NULL,
    UNIQUE(institution_id, email)
);

-- ========================================
-- COHORT MANAGEMENT SYSTEM
-- ========================================

-- Cohorts table (Institution-specific learning groups)
CREATE TABLE IF NOT EXISTS cohorts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    enrollment_code TEXT NOT NULL,
    max_students INTEGER DEFAULT 50,
    academic_year TEXT,
    semester TEXT,
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES institution_admins(id) ON DELETE SET NULL,
    UNIQUE(institution_id, enrollment_code)
);

-- Teacher-Cohort assignments (Many-to-many)
CREATE TABLE IF NOT EXISTS teacher_cohorts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    cohort_id UUID NOT NULL REFERENCES cohorts(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'teacher', -- 'teacher', 'coordinator', 'assistant'
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    assigned_by UUID REFERENCES institution_admins(id) ON DELETE SET NULL,
    UNIQUE(teacher_id, cohort_id)
);

-- ========================================
-- LECTURE SYSTEM
-- ========================================

-- Lectures table
CREATE TABLE IF NOT EXISTS lectures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    cohort_id UUID NOT NULL REFERENCES cohorts(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTEGER NOT NULL, -- in minutes
    meeting_link TEXT,
    meeting_id TEXT,
    meeting_password TEXT,
    status TEXT DEFAULT 'scheduled', -- 'scheduled', 'live', 'ended', 'cancelled'
    recording_enabled BOOLEAN DEFAULT true,
    chat_enabled BOOLEAN DEFAULT true,
    max_participants INTEGER DEFAULT 100,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Student enrollments in cohorts
CREATE TABLE IF NOT EXISTS enrollments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    cohort_id UUID NOT NULL REFERENCES cohorts(id) ON DELETE CASCADE,
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    enrolled_by UUID REFERENCES institution_admins(id) ON DELETE SET NULL,
    status TEXT DEFAULT 'active', -- 'active', 'inactive', 'suspended'
    is_active BOOLEAN DEFAULT true,
    UNIQUE(student_id, cohort_id)
);

-- ========================================
-- MATERIALS SYSTEM
-- ========================================

-- Materials table
CREATE TABLE IF NOT EXISTS materials (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE,
    cohort_id UUID REFERENCES cohorts(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    file_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_size INTEGER,
    is_public BOOLEAN DEFAULT false, -- Available to all students in cohort
    download_count INTEGER DEFAULT 0,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    -- Ensure either lecture_id or cohort_id is provided
    CONSTRAINT materials_lecture_or_cohort CHECK (
        (lecture_id IS NOT NULL) OR (cohort_id IS NOT NULL)
    )
);

-- ========================================
-- QUIZ SYSTEM
-- ========================================

-- Quiz sets table
CREATE TABLE IF NOT EXISTS quiz_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    cohort_id UUID NOT NULL REFERENCES cohorts(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    instructions TEXT,
    time_limit INTEGER, -- in minutes
    max_attempts INTEGER DEFAULT 1,
    passing_score INTEGER DEFAULT 50, -- percentage
    starts_at TIMESTAMP WITH TIME ZONE,
    ends_at TIMESTAMP WITH TIME ZONE,
    is_randomized BOOLEAN DEFAULT false,
    show_correct_answers BOOLEAN DEFAULT true,
    show_results_immediately BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Individual quiz questions
CREATE TABLE IF NOT EXISTS quizzes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quiz_set_id UUID NOT NULL REFERENCES quiz_sets(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_type TEXT NOT NULL DEFAULT 'multiple_choice', -- 'multiple_choice', 'true_false', 'short_answer', 'essay'
    options JSONB, -- For multiple choice: [{"a": "Option A", "b": "Option B", "c": "Option C", "d": "Option D"}]
    correct_answer TEXT, -- For multiple choice: "a", "b", etc. For true/false: "true", "false"
    explanation TEXT, -- Explanation for correct answer
    points INTEGER DEFAULT 1,
    order_index INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student quiz attempts
CREATE TABLE IF NOT EXISTS quiz_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quiz_set_id UUID NOT NULL REFERENCES quiz_sets(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    finished_at TIMESTAMP WITH TIME ZONE,
    score INTEGER,
    total_questions INTEGER,
    correct_answers INTEGER,
    is_completed BOOLEAN DEFAULT false,
    attempt_number INTEGER NOT NULL,
    time_spent INTEGER, -- in seconds
    UNIQUE(quiz_set_id, student_id, attempt_number)
);

-- Individual quiz responses
CREATE TABLE IF NOT EXISTS quiz_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    attempt_id UUID NOT NULL REFERENCES quiz_attempts(id) ON DELETE CASCADE,
    quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    selected_answer TEXT,
    is_correct BOOLEAN,
    points_earned INTEGER DEFAULT 0,
    responded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- POLLS SYSTEM
-- ========================================

-- Polls table
CREATE TABLE IF NOT EXISTS polls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    cohort_id UUID NOT NULL REFERENCES cohorts(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    options JSONB NOT NULL, -- Array of poll options
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Poll responses table
CREATE TABLE IF NOT EXISTS poll_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    poll_id UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    selected_option TEXT NOT NULL,
    responded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(poll_id, student_id)
);

-- ========================================
-- SESSION RECORDING SYSTEM
-- ========================================

-- Session recordings
CREATE TABLE IF NOT EXISTS session_recordings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID NOT NULL REFERENCES institutions(id) ON DELETE CASCADE,
    cohort_id UUID NOT NULL REFERENCES cohorts(id) ON DELETE CASCADE,
    session_id TEXT NOT NULL,
    lecture_id UUID NOT NULL REFERENCES lectures(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    title TEXT,
    description TEXT,
    recording_type TEXT NOT NULL DEFAULT 'full', -- 'full', 'audio_only', 'chat_only'
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    stopped_at TIMESTAMP WITH TIME ZONE,
    duration INTEGER, -- in seconds
    recording_path TEXT,
    thumbnail_path TEXT,
    file_size INTEGER,
    participants JSONB, -- List of participant IDs
    stats JSONB, -- Recording statistics
    is_public BOOLEAN DEFAULT false,
    download_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Recording chunks for streaming
CREATE TABLE IF NOT EXISTS recording_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recording_id UUID NOT NULL REFERENCES session_recordings(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    chunk_type TEXT NOT NULL, -- 'video', 'audio', 'screen'
    chunk_path TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    file_size INTEGER,
    duration INTEGER, -- in seconds
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- ANALYTICS & REPORTING
-- ========================================

-- User activity logs
CREATE TABLE IF NOT EXISTS activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    user_type TEXT NOT NULL, -- 'super_admin', 'institution_admin', 'teacher', 'student'
    action TEXT NOT NULL,
    resource_type TEXT, -- 'lecture', 'quiz', 'material', 'cohort', etc.
    resource_id UUID,
    details JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- System analytics
CREATE TABLE IF NOT EXISTS system_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    metric_name TEXT NOT NULL,
    metric_value NUMERIC,
    metric_data JSONB,
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- ADDITIONAL TABLES FOR COMPLETE PLATFORM
-- ========================================

-- Notifications table for system-wide notifications
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    user_type TEXT NOT NULL CHECK (user_type IN ('super_admin', 'institution_admin', 'teacher', 'student')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    notification_type TEXT NOT NULL DEFAULT 'info' CHECK (notification_type IN ('info', 'warning', 'error', 'success')),
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Assignment submissions table
CREATE TABLE IF NOT EXISTS assignment_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    assignment_id UUID NOT NULL,
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    submission_text TEXT,
    file_url TEXT,
    file_name TEXT,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    graded_at TIMESTAMP WITH TIME ZONE,
    grade NUMERIC,
    feedback TEXT,
    is_late BOOLEAN DEFAULT false
);

-- Assignments table
CREATE TABLE IF NOT EXISTS assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    cohort_id UUID REFERENCES cohorts(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES teachers(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    instructions TEXT,
    due_date TIMESTAMP WITH TIME ZONE,
    max_points NUMERIC DEFAULT 100,
    file_url TEXT,
    file_name TEXT,
    is_published BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Attendance tracking table
CREATE TABLE IF NOT EXISTS attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE,
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'present' CHECK (status IN ('present', 'absent', 'late', 'excused')),
    joined_at TIMESTAMP WITH TIME ZONE,
    left_at TIMESTAMP WITH TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Gradebook table
CREATE TABLE IF NOT EXISTS gradebook (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    student_id UUID REFERENCES students(id) ON DELETE CASCADE,
    cohort_id UUID REFERENCES cohorts(id) ON DELETE CASCADE,
    teacher_id UUID REFERENCES teachers(id) ON DELETE CASCADE,
    assignment_id UUID REFERENCES assignments(id) ON DELETE CASCADE,
    quiz_id UUID REFERENCES quiz_sets(id) ON DELETE CASCADE,
    grade_type TEXT NOT NULL CHECK (grade_type IN ('assignment', 'quiz', 'exam', 'participation')),
    points_earned NUMERIC,
    points_possible NUMERIC,
    percentage NUMERIC,
    letter_grade TEXT,
    feedback TEXT,
    graded_by UUID REFERENCES teachers(id),
    graded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Discussion forums table
CREATE TABLE IF NOT EXISTS discussion_forums (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    cohort_id UUID REFERENCES cohorts(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_by UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Discussion posts table
CREATE TABLE IF NOT EXISTS discussion_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    forum_id UUID REFERENCES discussion_forums(id) ON DELETE CASCADE,
    parent_post_id UUID REFERENCES discussion_posts(id) ON DELETE CASCADE,
    author_id UUID NOT NULL,
    author_type TEXT NOT NULL CHECK (author_type IN ('teacher', 'student')),
    title TEXT,
    content TEXT NOT NULL,
    is_pinned BOOLEAN DEFAULT false,
    is_locked BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- System settings table
CREATE TABLE IF NOT EXISTS system_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    setting_key TEXT NOT NULL,
    setting_value TEXT,
    setting_type TEXT DEFAULT 'string' CHECK (setting_type IN ('string', 'number', 'boolean', 'json')),
    description TEXT,
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(institution_id, setting_key)
);

-- ========================================
-- Fix for missing columns (Run immediately after table creation)
-- ========================================

-- Check if subdomain column exists and add it if missing
DO $$ 
BEGIN
    -- Add subdomain column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'institutions' 
        AND column_name = 'subdomain'
    ) THEN
        ALTER TABLE institutions ADD COLUMN subdomain TEXT;
        RAISE NOTICE 'Added subdomain column to institutions table';
    ELSE
        RAISE NOTICE 'subdomain column already exists in institutions table';
    END IF;
    
    -- Check and add other potentially missing columns to institutions table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'institutions' 
        AND column_name = 'logo_url'
    ) THEN
        ALTER TABLE institutions ADD COLUMN logo_url TEXT;
        RAISE NOTICE 'Added logo_url column to institutions table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'institutions' 
        AND column_name = 'logo_data'
    ) THEN
        ALTER TABLE institutions ADD COLUMN logo_data TEXT;
        RAISE NOTICE 'Added logo_data column to institutions table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'institutions' 
        AND column_name = 'primary_color'
    ) THEN
        ALTER TABLE institutions ADD COLUMN primary_color TEXT DEFAULT '#007bff';
        RAISE NOTICE 'Added primary_color column to institutions table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'institutions' 
        AND column_name = 'secondary_color'
    ) THEN
        ALTER TABLE institutions ADD COLUMN secondary_color TEXT DEFAULT '#6c757d';
        RAISE NOTICE 'Added secondary_color column to institutions table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'institutions' 
        AND column_name = 'description'
    ) THEN
        ALTER TABLE institutions ADD COLUMN description TEXT;
        RAISE NOTICE 'Added description column to institutions table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'institutions' 
        AND column_name = 'contact_email'
    ) THEN
        ALTER TABLE institutions ADD COLUMN contact_email TEXT;
        RAISE NOTICE 'Added contact_email column to institutions table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'institutions' 
        AND column_name = 'contact_phone'
    ) THEN
        ALTER TABLE institutions ADD COLUMN contact_phone TEXT;
        RAISE NOTICE 'Added contact_phone column to institutions table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'institutions' 
        AND column_name = 'address'
    ) THEN
        ALTER TABLE institutions ADD COLUMN address TEXT;
        RAISE NOTICE 'Added address column to institutions table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'institutions' 
        AND column_name = 'website'
    ) THEN
        ALTER TABLE institutions ADD COLUMN website TEXT;
        RAISE NOTICE 'Added website column to institutions table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'institutions' 
        AND column_name = 'is_active'
    ) THEN
        ALTER TABLE institutions ADD COLUMN is_active BOOLEAN DEFAULT true;
        RAISE NOTICE 'Added is_active column to institutions table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'institutions' 
        AND column_name = 'created_at'
    ) THEN
        ALTER TABLE institutions ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added created_at column to institutions table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'institutions' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE institutions ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to institutions table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'institutions' 
        AND column_name = 'settings'
    ) THEN
        ALTER TABLE institutions ADD COLUMN settings JSONB;
        RAISE NOTICE 'Added settings column to institutions table';
    END IF;
    
    -- Check and add created_by column to institutions table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'institutions' 
        AND column_name = 'created_by'
    ) THEN
        ALTER TABLE institutions ADD COLUMN created_by UUID;
        RAISE NOTICE 'Added created_by column to institutions table';
    END IF;
    
    -- Check and add created_by column to teachers table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'teachers' 
        AND column_name = 'created_by'
    ) THEN
        ALTER TABLE teachers ADD COLUMN created_by UUID;
        RAISE NOTICE 'Added created_by column to teachers table';
    END IF;
    
    -- Check and add created_by column to students table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'students' 
        AND column_name = 'created_by'
    ) THEN
        ALTER TABLE students ADD COLUMN created_by UUID;
        RAISE NOTICE 'Added created_by column to students table';
    END IF;
    
    -- Check and add created_by column to cohorts table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cohorts' 
        AND column_name = 'created_by'
    ) THEN
        ALTER TABLE cohorts ADD COLUMN created_by UUID;
        RAISE NOTICE 'Added created_by column to cohorts table';
    END IF;
    
    -- Check and add enrollment_code column to cohorts table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cohorts' 
        AND column_name = 'enrollment_code'
    ) THEN
        ALTER TABLE cohorts ADD COLUMN enrollment_code TEXT;
        RAISE NOTICE 'Added enrollment_code column to cohorts table';
    END IF;
    
    -- Check and add academic_year column to cohorts table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cohorts' 
        AND column_name = 'academic_year'
    ) THEN
        ALTER TABLE cohorts ADD COLUMN academic_year TEXT;
        RAISE NOTICE 'Added academic_year column to cohorts table';
    END IF;
    
    -- Check and add subject column to cohorts table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cohorts' 
        AND column_name = 'subject'
    ) THEN
        ALTER TABLE cohorts ADD COLUMN subject TEXT;
        RAISE NOTICE 'Added subject column to cohorts table';
    END IF;
    
    -- Check and add join_code column to cohorts table
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cohorts' 
        AND column_name = 'join_code'
    ) THEN
        ALTER TABLE cohorts ADD COLUMN join_code TEXT;
        RAISE NOTICE 'Added join_code column to cohorts table';
    END IF;
    
    -- Check and add institution_id column to various tables
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'institution_admins' 
        AND column_name = 'institution_id'
    ) THEN
        ALTER TABLE institution_admins ADD COLUMN institution_id UUID;
        RAISE NOTICE 'Added institution_id column to institution_admins table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'teachers' 
        AND column_name = 'institution_id'
    ) THEN
        ALTER TABLE teachers ADD COLUMN institution_id UUID;
        RAISE NOTICE 'Added institution_id column to teachers table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'students' 
        AND column_name = 'institution_id'
    ) THEN
        ALTER TABLE students ADD COLUMN institution_id UUID;
        RAISE NOTICE 'Added institution_id column to students table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'cohorts' 
        AND column_name = 'institution_id'
    ) THEN
        ALTER TABLE cohorts ADD COLUMN institution_id UUID;
        RAISE NOTICE 'Added institution_id column to cohorts table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lectures' 
        AND column_name = 'institution_id'
    ) THEN
        ALTER TABLE lectures ADD COLUMN institution_id UUID;
        RAISE NOTICE 'Added institution_id column to lectures table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'enrollments' 
        AND column_name = 'institution_id'
    ) THEN
        ALTER TABLE enrollments ADD COLUMN institution_id UUID;
        RAISE NOTICE 'Added institution_id column to enrollments table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'materials' 
        AND column_name = 'institution_id'
    ) THEN
        ALTER TABLE materials ADD COLUMN institution_id UUID;
        RAISE NOTICE 'Added institution_id column to materials table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'quiz_sets' 
        AND column_name = 'institution_id'
    ) THEN
        ALTER TABLE quiz_sets ADD COLUMN institution_id UUID;
        RAISE NOTICE 'Added institution_id column to quiz_sets table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'session_recordings' 
        AND column_name = 'institution_id'
    ) THEN
        ALTER TABLE session_recordings ADD COLUMN institution_id UUID;
        RAISE NOTICE 'Added institution_id column to session_recordings table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'session_recordings' 
        AND column_name = 'cohort_id'
    ) THEN
        ALTER TABLE session_recordings ADD COLUMN cohort_id UUID;
        RAISE NOTICE 'Added cohort_id column to session_recordings table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'session_recordings' 
        AND column_name = 'title'
    ) THEN
        ALTER TABLE session_recordings ADD COLUMN title TEXT;
        RAISE NOTICE 'Added title column to session_recordings table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'session_recordings' 
        AND column_name = 'description'
    ) THEN
        ALTER TABLE session_recordings ADD COLUMN description TEXT;
        RAISE NOTICE 'Added description column to session_recordings table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'session_recordings' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE session_recordings ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'Added updated_at column to session_recordings table';
    END IF;
    
    -- Add conditional ALTER TABLE statements for poll_responses
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'poll_responses' 
        AND column_name = 'institution_id'
    ) THEN
        ALTER TABLE poll_responses ADD COLUMN institution_id UUID;
        RAISE NOTICE 'Added institution_id column to poll_responses table';
    END IF;
    
    -- Add foreign key constraint for cohort_id if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_session_recordings_cohort'
    ) THEN
        ALTER TABLE session_recordings ADD CONSTRAINT fk_session_recordings_cohort 
        FOREIGN KEY (cohort_id) REFERENCES cohorts(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added foreign key constraint for cohort_id in session_recordings table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'activity_logs' 
        AND column_name = 'institution_id'
    ) THEN
        ALTER TABLE activity_logs ADD COLUMN institution_id UUID;
        RAISE NOTICE 'Added institution_id column to activity_logs table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'system_analytics' 
        AND column_name = 'institution_id'
    ) THEN
        ALTER TABLE system_analytics ADD COLUMN institution_id UUID;
        RAISE NOTICE 'Added institution_id column to system_analytics table';
    END IF;
    
    -- Check and add cohort_id column to various tables
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'teacher_cohorts' 
        AND column_name = 'cohort_id'
    ) THEN
        ALTER TABLE teacher_cohorts ADD COLUMN cohort_id UUID;
        RAISE NOTICE 'Added cohort_id column to teacher_cohorts table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'lectures' 
        AND column_name = 'cohort_id'
    ) THEN
        ALTER TABLE lectures ADD COLUMN cohort_id UUID;
        RAISE NOTICE 'Added cohort_id column to lectures table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'enrollments' 
        AND column_name = 'cohort_id'
    ) THEN
        ALTER TABLE enrollments ADD COLUMN cohort_id UUID;
        RAISE NOTICE 'Added cohort_id column to enrollments table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'materials' 
        AND column_name = 'cohort_id'
    ) THEN
        ALTER TABLE materials ADD COLUMN cohort_id UUID;
        RAISE NOTICE 'Added cohort_id column to materials table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'assignments' 
        AND column_name = 'cohort_id'
    ) THEN
        ALTER TABLE assignments ADD COLUMN cohort_id UUID;
        RAISE NOTICE 'Added cohort_id column to assignments table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'gradebook' 
        AND column_name = 'cohort_id'
    ) THEN
        ALTER TABLE gradebook ADD COLUMN cohort_id UUID;
        RAISE NOTICE 'Added cohort_id column to gradebook table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'discussion_forums' 
        AND column_name = 'cohort_id'
    ) THEN
        ALTER TABLE discussion_forums ADD COLUMN cohort_id UUID;
        RAISE NOTICE 'Added cohort_id column to discussion_forums table';
    END IF;
    
END $$;

-- ========================================
-- INDEXES FOR PERFORMANCE
-- ========================================

-- Super Admin indexes
CREATE INDEX IF NOT EXISTS idx_super_admins_email ON super_admins(email);
CREATE INDEX IF NOT EXISTS idx_super_admins_active ON super_admins(is_active);

-- Institution indexes
CREATE INDEX IF NOT EXISTS idx_institutions_domain ON institutions(domain);
CREATE INDEX IF NOT EXISTS idx_institutions_subdomain ON institutions(subdomain);
CREATE INDEX IF NOT EXISTS idx_institutions_active ON institutions(is_active);
CREATE INDEX IF NOT EXISTS idx_institutions_created_by ON institutions(created_by);

-- User indexes
CREATE INDEX IF NOT EXISTS idx_institution_admins_institution ON institution_admins(institution_id);
CREATE INDEX IF NOT EXISTS idx_institution_admins_email ON institution_admins(email);
CREATE INDEX IF NOT EXISTS idx_teachers_institution ON teachers(institution_id);
CREATE INDEX IF NOT EXISTS idx_teachers_email ON teachers(email);
CREATE INDEX IF NOT EXISTS idx_students_institution ON students(institution_id);
CREATE INDEX IF NOT EXISTS idx_students_email ON students(email);

-- Cohort indexes
CREATE INDEX IF NOT EXISTS idx_cohorts_institution ON cohorts(institution_id);
CREATE INDEX IF NOT EXISTS idx_cohorts_enrollment_code ON cohorts(enrollment_code);
CREATE INDEX IF NOT EXISTS idx_teacher_cohorts_teacher ON teacher_cohorts(teacher_id);
CREATE INDEX IF NOT EXISTS idx_teacher_cohorts_cohort ON teacher_cohorts(cohort_id);

-- Lecture indexes
CREATE INDEX IF NOT EXISTS idx_lectures_institution ON lectures(institution_id);
CREATE INDEX IF NOT EXISTS idx_lectures_cohort ON lectures(cohort_id);
CREATE INDEX IF NOT EXISTS idx_lectures_teacher ON lectures(teacher_id);
CREATE INDEX IF NOT EXISTS idx_lectures_time ON lectures(scheduled_time);

-- Enrollment indexes
CREATE INDEX IF NOT EXISTS idx_enrollments_institution ON enrollments(institution_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_student ON enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_cohort ON enrollments(cohort_id);

-- Material indexes
CREATE INDEX IF NOT EXISTS idx_materials_institution ON materials(institution_id);
CREATE INDEX IF NOT EXISTS idx_materials_lecture ON materials(lecture_id);
CREATE INDEX IF NOT EXISTS idx_materials_cohort ON materials(cohort_id);
CREATE INDEX IF NOT EXISTS idx_materials_teacher ON materials(teacher_id);

-- Quiz indexes
CREATE INDEX IF NOT EXISTS idx_quiz_sets_institution ON quiz_sets(institution_id);
CREATE INDEX IF NOT EXISTS idx_quiz_sets_cohort ON quiz_sets(cohort_id);
CREATE INDEX IF NOT EXISTS idx_quiz_sets_teacher ON quiz_sets(teacher_id);
CREATE INDEX IF NOT EXISTS idx_quizzes_quiz_set ON quizzes(quiz_set_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_student ON quiz_attempts(student_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_quiz_set ON quiz_attempts(quiz_set_id);
CREATE INDEX IF NOT EXISTS idx_quiz_responses_attempt ON quiz_responses(attempt_id);

-- Poll indexes
CREATE INDEX IF NOT EXISTS idx_polls_institution ON polls(institution_id);
CREATE INDEX IF NOT EXISTS idx_polls_cohort ON polls(cohort_id);
CREATE INDEX IF NOT EXISTS idx_polls_teacher ON polls(teacher_id);
CREATE INDEX IF NOT EXISTS idx_polls_lecture ON polls(lecture_id);
CREATE INDEX IF NOT EXISTS idx_polls_active ON polls(is_active);
CREATE INDEX IF NOT EXISTS idx_poll_responses_poll ON poll_responses(poll_id);
CREATE INDEX IF NOT EXISTS idx_poll_responses_student ON poll_responses(student_id);

-- Recording indexes
CREATE INDEX IF NOT EXISTS idx_session_recordings_institution ON session_recordings(institution_id);
CREATE INDEX IF NOT EXISTS idx_session_recordings_cohort ON session_recordings(cohort_id);
CREATE INDEX IF NOT EXISTS idx_session_recordings_lecture ON session_recordings(lecture_id);
CREATE INDEX IF NOT EXISTS idx_session_recordings_teacher ON session_recordings(teacher_id);
CREATE INDEX IF NOT EXISTS idx_session_recordings_active ON session_recordings(is_active);
CREATE INDEX IF NOT EXISTS idx_recording_chunks_recording ON recording_chunks(recording_id);

-- Activity log indexes
CREATE INDEX IF NOT EXISTS idx_activity_logs_institution ON activity_logs(institution_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_user ON activity_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_activity_logs_action ON activity_logs(action);
CREATE INDEX IF NOT EXISTS idx_activity_logs_created_at ON activity_logs(created_at);

-- Analytics indexes
CREATE INDEX IF NOT EXISTS idx_system_analytics_institution ON system_analytics(institution_id);
CREATE INDEX IF NOT EXISTS idx_system_analytics_metric ON system_analytics(metric_name);
CREATE INDEX IF NOT EXISTS idx_system_analytics_recorded_at ON system_analytics(recorded_at);

-- Index for analytics (institution, metric, and timestamp)
-- Note: Using timestamp instead of date to avoid function casting issues
CREATE INDEX IF NOT EXISTS idx_system_analytics_unique_daily 
ON system_analytics(institution_id, metric_name, recorded_at);

-- Additional table indexes
CREATE INDEX IF NOT EXISTS idx_notifications_institution ON notifications(institution_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read);

CREATE INDEX IF NOT EXISTS idx_assignment_submissions_institution ON assignment_submissions(institution_id);
CREATE INDEX IF NOT EXISTS idx_assignment_submissions_assignment ON assignment_submissions(assignment_id);
CREATE INDEX IF NOT EXISTS idx_assignment_submissions_student ON assignment_submissions(student_id);

CREATE INDEX IF NOT EXISTS idx_assignments_institution ON assignments(institution_id);
CREATE INDEX IF NOT EXISTS idx_assignments_cohort ON assignments(cohort_id);
CREATE INDEX IF NOT EXISTS idx_assignments_teacher ON assignments(teacher_id);
CREATE INDEX IF NOT EXISTS idx_assignments_due_date ON assignments(due_date);

CREATE INDEX IF NOT EXISTS idx_attendance_institution ON attendance(institution_id);
CREATE INDEX IF NOT EXISTS idx_attendance_lecture ON attendance(lecture_id);
CREATE INDEX IF NOT EXISTS idx_attendance_student ON attendance(student_id);
CREATE INDEX IF NOT EXISTS idx_attendance_status ON attendance(status);

CREATE INDEX IF NOT EXISTS idx_gradebook_institution ON gradebook(institution_id);
CREATE INDEX IF NOT EXISTS idx_gradebook_student ON gradebook(student_id);
CREATE INDEX IF NOT EXISTS idx_gradebook_cohort ON gradebook(cohort_id);
CREATE INDEX IF NOT EXISTS idx_gradebook_teacher ON gradebook(teacher_id);

CREATE INDEX IF NOT EXISTS idx_discussion_forums_institution ON discussion_forums(institution_id);
CREATE INDEX IF NOT EXISTS idx_discussion_forums_cohort ON discussion_forums(cohort_id);

CREATE INDEX IF NOT EXISTS idx_discussion_posts_institution ON discussion_posts(institution_id);
CREATE INDEX IF NOT EXISTS idx_discussion_posts_forum ON discussion_posts(forum_id);
CREATE INDEX IF NOT EXISTS idx_discussion_posts_parent ON discussion_posts(parent_post_id);
CREATE INDEX IF NOT EXISTS idx_discussion_posts_author ON discussion_posts(author_id);

CREATE INDEX IF NOT EXISTS idx_system_settings_institution ON system_settings(institution_id);
CREATE INDEX IF NOT EXISTS idx_system_settings_key ON system_settings(setting_key);

-- ========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ========================================

-- Enable RLS on all tables
ALTER TABLE super_admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE institutions ENABLE ROW LEVEL SECURITY;
ALTER TABLE institution_admins ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE cohorts ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_cohorts ENABLE ROW LEVEL SECURITY;
ALTER TABLE lectures ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_recordings ENABLE ROW LEVEL SECURITY;
ALTER TABLE recording_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_forums ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_posts ENABLE ROW LEVEL SECURITY;

-- Super Admin policies
DROP POLICY IF EXISTS "Super admins can manage all" ON super_admins;
CREATE POLICY "Super admins can manage all" ON super_admins FOR ALL USING (
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

-- Institution policies
DROP POLICY IF EXISTS "Super admins can manage institutions" ON institutions;
CREATE POLICY "Super admins can manage institutions" ON institutions FOR ALL USING (
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

DROP POLICY IF EXISTS "Institution admins can read their institution" ON institutions;
CREATE POLICY "Institution admins can read their institution" ON institutions FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = institutions.id
    )
);

-- Institution Admin policies
DROP POLICY IF EXISTS "Institution admins can manage their own data" ON institution_admins;
CREATE POLICY "Institution admins can manage their own data" ON institution_admins FOR ALL USING (
    auth.uid()::text = id::text OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

-- Teacher policies
DROP POLICY IF EXISTS "Teachers can view own data" ON teachers;
CREATE POLICY "Teachers can view own data" ON teachers FOR SELECT USING (
    auth.uid()::text = id::text OR
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = teachers.institution_id
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

DROP POLICY IF EXISTS "Institution admins can manage teachers" ON teachers;
CREATE POLICY "Institution admins can manage teachers" ON teachers FOR ALL USING (
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = teachers.institution_id
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

-- Student policies
DROP POLICY IF EXISTS "Students can view own data" ON students;
CREATE POLICY "Students can view own data" ON students FOR SELECT USING (
    auth.uid()::text = id::text OR
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = students.institution_id
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

DROP POLICY IF EXISTS "Institution admins can manage students" ON students;
CREATE POLICY "Institution admins can manage students" ON students FOR ALL USING (
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = students.institution_id
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

-- Cohort policies
DROP POLICY IF EXISTS "Institution users can access their cohorts" ON cohorts;
CREATE POLICY "Institution users can access their cohorts" ON cohorts FOR ALL USING (
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = cohorts.institution_id
    ) OR
    EXISTS (
        SELECT 1 FROM teachers 
        WHERE teachers.id::text = auth.uid()::text 
        AND teachers.institution_id = cohorts.institution_id
    ) OR
    EXISTS (
        SELECT 1 FROM students 
        WHERE students.id::text = auth.uid()::text 
        AND students.institution_id = cohorts.institution_id
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

-- Lecture policies
DROP POLICY IF EXISTS "Teachers can manage their lectures" ON lectures;
CREATE POLICY "Teachers can manage their lectures" ON lectures FOR ALL USING (
    auth.uid()::text = teacher_id::text OR
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = lectures.institution_id
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

DROP POLICY IF EXISTS "Students can view enrolled lectures" ON lectures;
CREATE POLICY "Students can view enrolled lectures" ON lectures FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM enrollments 
        WHERE enrollments.student_id::text = auth.uid()::text 
        AND enrollments.cohort_id = lectures.cohort_id
        AND enrollments.is_active = true
    ) OR
    auth.uid()::text = teacher_id::text OR
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = lectures.institution_id
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

-- Material policies
DROP POLICY IF EXISTS "Teachers can manage materials for their lectures" ON materials;
CREATE POLICY "Teachers can manage materials for their lectures" ON materials FOR ALL USING (
    auth.uid()::text = teacher_id::text OR
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = materials.institution_id
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

DROP POLICY IF EXISTS "Students can read materials for enrolled lectures" ON materials;
CREATE POLICY "Students can read materials for enrolled lectures" ON materials FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM enrollments e
        JOIN lectures l ON e.cohort_id = l.cohort_id
        WHERE e.student_id::text = auth.uid()::text 
        AND l.id = materials.lecture_id
        AND e.is_active = true
    ) OR
    auth.uid()::text = teacher_id::text OR
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = materials.institution_id
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

-- Quiz policies
DROP POLICY IF EXISTS "Teachers can manage quiz sets for their cohorts" ON quiz_sets;
CREATE POLICY "Teachers can manage quiz sets for their cohorts" ON quiz_sets FOR ALL USING (
    auth.uid()::text = teacher_id::text OR
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = quiz_sets.institution_id
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

DROP POLICY IF EXISTS "Students can read quiz sets for enrolled cohorts" ON quiz_sets;
CREATE POLICY "Students can read quiz sets for enrolled cohorts" ON quiz_sets FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM enrollments 
        WHERE enrollments.student_id::text = auth.uid()::text 
        AND enrollments.cohort_id = quiz_sets.cohort_id
        AND enrollments.is_active = true
    ) OR
    auth.uid()::text = teacher_id::text OR
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = quiz_sets.institution_id
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

-- Quiz attempt policies
DROP POLICY IF EXISTS "Students can manage their own quiz attempts" ON quiz_attempts;
CREATE POLICY "Students can manage their own quiz attempts" ON quiz_attempts FOR ALL USING (
    auth.uid()::text = student_id::text OR
    EXISTS (
        SELECT 1 FROM quiz_sets qs
        WHERE qs.id = quiz_attempts.quiz_set_id
        AND qs.teacher_id::text = auth.uid()::text
    ) OR
    EXISTS (
        SELECT 1 FROM quiz_sets qs
        JOIN institution_admins ia ON ia.institution_id = qs.institution_id
        WHERE qs.id = quiz_attempts.quiz_set_id
        AND ia.id::text = auth.uid()::text
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

-- Session recording policies
DROP POLICY IF EXISTS "Teachers can manage own recordings" ON session_recordings;
CREATE POLICY "Teachers can manage own recordings" ON session_recordings FOR ALL USING (
    auth.uid()::text = teacher_id::text OR
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = session_recordings.institution_id
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

DROP POLICY IF EXISTS "Students can read recordings for enrolled lectures" ON session_recordings;
CREATE POLICY "Students can read recordings for enrolled lectures" ON session_recordings FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM enrollments e
        JOIN lectures l ON e.cohort_id = l.cohort_id
        WHERE e.student_id::text = auth.uid()::text 
        AND l.id = session_recordings.lecture_id
        AND e.is_active = true
    ) OR
    auth.uid()::text = teacher_id::text OR
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = session_recordings.institution_id
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

-- Poll policies
DROP POLICY IF EXISTS "Teachers can manage polls for their cohorts" ON polls;
CREATE POLICY "Teachers can manage polls for their cohorts" ON polls FOR ALL USING (
    auth.uid()::text = teacher_id::text OR
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = polls.institution_id
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

DROP POLICY IF EXISTS "Students can read polls for enrolled cohorts" ON polls;
CREATE POLICY "Students can read polls for enrolled cohorts" ON polls FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM enrollments 
        WHERE enrollments.student_id::text = auth.uid()::text 
        AND enrollments.cohort_id = polls.cohort_id
        AND enrollments.is_active = true
    ) OR
    auth.uid()::text = teacher_id::text OR
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = polls.institution_id
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

-- Poll response policies
DROP POLICY IF EXISTS "Students can manage their own poll responses" ON poll_responses;
CREATE POLICY "Students can manage their own poll responses" ON poll_responses FOR ALL USING (
    auth.uid()::text = student_id::text OR
    EXISTS (
        SELECT 1 FROM polls p
        WHERE p.id = poll_responses.poll_id
        AND p.teacher_id::text = auth.uid()::text
    ) OR
    EXISTS (
        SELECT 1 FROM polls p
        JOIN institution_admins ia ON ia.institution_id = p.institution_id
        WHERE p.id = poll_responses.poll_id
        AND ia.id::text = auth.uid()::text
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

-- Discussion forum policies
DROP POLICY IF EXISTS "Users can access forums for their cohorts" ON discussion_forums;
CREATE POLICY "Users can access forums for their cohorts" ON discussion_forums FOR ALL USING (
    EXISTS (
        SELECT 1 FROM institution_admins 
        WHERE institution_admins.id::text = auth.uid()::text 
        AND institution_admins.institution_id = discussion_forums.institution_id
    ) OR
    EXISTS (
        SELECT 1 FROM teachers 
        WHERE teachers.id::text = auth.uid()::text 
        AND teachers.institution_id = discussion_forums.institution_id
    ) OR
    EXISTS (
        SELECT 1 FROM students 
        WHERE students.id::text = auth.uid()::text 
        AND students.institution_id = discussion_forums.institution_id
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

-- Discussion post policies
DROP POLICY IF EXISTS "Users can manage posts in their forums" ON discussion_posts;
CREATE POLICY "Users can manage posts in their forums" ON discussion_posts FOR ALL USING (
    auth.uid()::text = author_id::text OR
    EXISTS (
        SELECT 1 FROM discussion_forums df
        JOIN institution_admins ia ON ia.institution_id = df.institution_id
        WHERE df.id = discussion_posts.forum_id
        AND ia.id::text = auth.uid()::text
    ) OR
    EXISTS (
        SELECT 1 FROM discussion_forums df
        JOIN teachers t ON t.institution_id = df.institution_id
        WHERE df.id = discussion_posts.forum_id
        AND t.id::text = auth.uid()::text
    ) OR
    EXISTS (
        SELECT 1 FROM discussion_forums df
        JOIN students s ON s.institution_id = df.institution_id
        WHERE df.id = discussion_posts.forum_id
        AND s.id::text = auth.uid()::text
    ) OR
    EXISTS (SELECT 1 FROM super_admins WHERE super_admins.id::text = auth.uid()::text)
);

-- ========================================
-- SAMPLE DATA
-- ========================================

-- Create sample super admin
INSERT INTO super_admins (name, email, password_hash) VALUES
('System Administrator', 'admin@digikul.com', crypt('admin123', gen_salt('bf')))
ON CONFLICT (email) DO NOTHING;

-- Create sample institutions
INSERT INTO institutions (name, domain, subdomain, logo_url, primary_color, secondary_color, description, contact_email, created_by) 
SELECT 
    'DigiKul University',
    'digikul.com',
    'digikul',
    'https://via.placeholder.com/200x80/007bff/ffffff?text=DigiKul',
    '#007bff',
    '#6c757d',
    'A leading online university for digital education and technology.',
    'info@digikul.com',
    sa.id
FROM super_admins sa 
WHERE sa.email = 'admin@digikul.com'
ON CONFLICT (domain) DO NOTHING;

INSERT INTO institutions (name, domain, subdomain, logo_url, primary_color, secondary_color, description, contact_email, created_by) 
SELECT 
    'Tech Academy',
    'techacademy.io',
    'techacademy',
    'https://via.placeholder.com/200x80/28a745/ffffff?text=Tech+Academy',
    '#28a745',
    '#20c997',
    'Specializing in cutting-edge technology courses and certifications.',
    'contact@techacademy.io',
    sa.id
FROM super_admins sa 
WHERE sa.email = 'admin@digikul.com'
ON CONFLICT (domain) DO NOTHING;

INSERT INTO institutions (name, domain, subdomain, logo_url, primary_color, secondary_color, description, contact_email, created_by) 
SELECT 
    'Online Learning Hub',
    'learnhub.org',
    'learnhub',
    'https://via.placeholder.com/200x80/dc3545/ffffff?text=LearnHub',
    '#dc3545',
    '#fd7e14',
    'A community-driven platform for diverse online courses and learning.',
    'support@learnhub.org',
    sa.id
FROM super_admins sa 
WHERE sa.email = 'admin@digikul.com'
ON CONFLICT (domain) DO NOTHING;

-- Create sample institution admins
INSERT INTO institution_admins (institution_id, name, email, password_hash, permissions)
SELECT 
    i.id,
    'DigiKul Admin',
    'admin@digikul.com',
    crypt('digikul123', gen_salt('bf')),
    '{
        "manage_teachers": true,
        "manage_students": true,
        "manage_cohorts": true,
        "view_analytics": true,
        "manage_materials": true,
        "manage_quizzes": true
    }'
FROM institutions i 
WHERE i.domain = 'digikul.com'
ON CONFLICT (institution_id, email) DO NOTHING;

INSERT INTO institution_admins (institution_id, name, email, password_hash)
SELECT 
    i.id,
    'Tech Academy Admin',
    'admin@techacademy.io',
    crypt('tech123', gen_salt('bf'))
FROM institutions i 
WHERE i.domain = 'techacademy.io'
ON CONFLICT (institution_id, email) DO NOTHING;

INSERT INTO institution_admins (institution_id, name, email, password_hash)
SELECT 
    i.id,
    'Learning Hub Admin',
    'admin@learnhub.org',
    crypt('hub123', gen_salt('bf'))
FROM institutions i 
WHERE i.domain = 'learnhub.org'
ON CONFLICT (institution_id, email) DO NOTHING;

-- Create sample cohorts
INSERT INTO cohorts (institution_id, name, description, subject, enrollment_code, join_code, academic_year, created_by)
SELECT 
    i.id,
    'CS-101: Introduction to Programming',
    'Fundamental concepts of computer programming',
    'Computer Science',
    'CS1012024',
    'JOIN-CS101-2024',
    '2024-2025',
    ia.id
FROM institutions i 
JOIN institution_admins ia ON ia.institution_id = i.id
WHERE i.domain = 'digikul.com' AND ia.email = 'admin@digikul.com'
ON CONFLICT (institution_id, enrollment_code) DO NOTHING;


-- Add constraints after sample data is inserted
DO $$ 
BEGIN
    -- Add foreign key constraint if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_institutions_created_by'
    ) THEN
        ALTER TABLE institutions ADD CONSTRAINT fk_institutions_created_by 
        FOREIGN KEY (created_by) REFERENCES super_admins(id) ON DELETE SET NULL;
    END IF;
    
    -- Add unique constraint for subdomain if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'uk_institutions_subdomain'
    ) THEN
        ALTER TABLE institutions ADD CONSTRAINT uk_institutions_subdomain UNIQUE (subdomain);
    END IF;
END $$;

-- ========================================
-- FUNCTIONS AND TRIGGERS
-- ========================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to automatically update updated_at
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'update_institutions_updated_at'
    ) THEN
        CREATE TRIGGER update_institutions_updated_at 
            BEFORE UPDATE ON institutions 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

-- Function to log user activity
CREATE OR REPLACE FUNCTION log_user_activity()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO activity_logs (
        institution_id,
        user_id,
        user_type,
        action,
        resource_type,
        resource_id,
        details
    ) VALUES (
        COALESCE(NEW.institution_id, OLD.institution_id),
        COALESCE(NEW.id, OLD.id),
        TG_TABLE_NAME::text,
        TG_OP::text,
        TG_TABLE_NAME::text,
        COALESCE(NEW.id, OLD.id),
        to_jsonb(COALESCE(NEW, OLD))
    );
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

-- ========================================
-- VIEWS FOR COMMON QUERIES
-- ========================================

-- View for institution dashboard statistics
CREATE OR REPLACE VIEW institution_stats AS
SELECT 
    i.id as institution_id,
    i.name as institution_name,
    i.domain,
    COUNT(DISTINCT ia.id) as admin_count,
    COUNT(DISTINCT t.id) as teacher_count,
    COUNT(DISTINCT s.id) as student_count,
    COUNT(DISTINCT c.id) as cohort_count,
    COUNT(DISTINCT l.id) as lecture_count,
    COUNT(DISTINCT qs.id) as quiz_count
FROM institutions i
LEFT JOIN institution_admins ia ON ia.institution_id = i.id AND ia.is_active = true
LEFT JOIN teachers t ON t.institution_id = i.id AND t.is_active = true
LEFT JOIN students s ON s.institution_id = i.id AND s.is_active = true
LEFT JOIN cohorts c ON c.institution_id = i.id AND c.is_active = true
LEFT JOIN lectures l ON l.institution_id = i.id AND l.is_active = true
LEFT JOIN quiz_sets qs ON qs.institution_id = i.id AND qs.is_active = true
WHERE i.is_active = true
GROUP BY i.id, i.name, i.domain;

-- View for user authentication info
CREATE OR REPLACE VIEW user_auth_info AS
SELECT 
    'super_admin' as user_type,
    id,
    name,
    email,
    is_active,
    created_at
FROM super_admins
WHERE is_active = true

UNION ALL

SELECT 
    'institution_admin' as user_type,
    id,
    name,
    email,
    is_active,
    created_at
FROM institution_admins
WHERE is_active = true

UNION ALL

SELECT 
    'teacher' as user_type,
    id,
    name,
    email,
    is_active,
    created_at
FROM teachers
WHERE is_active = true

UNION ALL

SELECT 
    'student' as user_type,
    id,
    name,
    email,
    is_active,
    created_at
FROM students
WHERE is_active = true;

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

-- Function to get user's institution based on email domain
CREATE OR REPLACE FUNCTION get_institution_by_email(user_email TEXT)
RETURNS TABLE(institution_id UUID, institution_name TEXT, domain TEXT) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        i.id,
        i.name,
        i.domain
    FROM institutions i
    WHERE user_email LIKE '%@' || i.domain
    AND i.is_active = true
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Function to check if user has access to institution
CREATE OR REPLACE FUNCTION check_institution_access(user_email TEXT, institution_domain TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_domain TEXT;
BEGIN
    -- Extract domain from email
    user_domain := split_part(user_email, '@', 2);
    
    -- Check if user's email domain matches the institution domain
    RETURN user_domain = institution_domain;
END;
$$ LANGUAGE plpgsql;

-- Function to get user type and institution
CREATE OR REPLACE FUNCTION get_user_context(user_email TEXT)
RETURNS TABLE(
    user_type TEXT,
    user_id UUID,
    institution_id UUID,
    institution_name TEXT,
    institution_domain TEXT,
    has_access BOOLEAN
) AS $$
BEGIN
    RETURN QUERY
    WITH user_info AS (
        SELECT 
            'super_admin' as type,
            id,
            NULL::UUID as inst_id
        FROM super_admins 
        WHERE email = user_email AND is_active = true
        
        UNION ALL
        
        SELECT 
            'institution_admin' as type,
            id,
            institution_id as inst_id
        FROM institution_admins 
        WHERE email = user_email AND is_active = true
        
        UNION ALL
        
        SELECT 
            'teacher' as type,
            id,
            institution_id as inst_id
        FROM teachers 
        WHERE email = user_email AND is_active = true
        
        UNION ALL
        
        SELECT 
            'student' as type,
            id,
            institution_id as inst_id
        FROM students 
        WHERE email = user_email AND is_active = true
    )
    SELECT 
        ui.type,
        ui.id,
        ui.inst_id,
        i.name,
        i.domain,
        CASE 
            WHEN ui.type = 'super_admin' THEN true
            ELSE check_institution_access(user_email, i.domain)
        END
    FROM user_info ui
    LEFT JOIN institutions i ON i.id = ui.inst_id
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- ========================================
-- END OF SCHEMA
-- ========================================

COMMENT ON DATABASE postgres IS 'DigiKul Multi-Tenant Educational Platform Database Schema';
