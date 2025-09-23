-- Supabase Database Schema for DigiKul Teachers Portal
-- This file contains the SQL schema to create all tables in Supabase

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Institutions table
CREATE TABLE IF NOT EXISTS institutions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    domain TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Teachers table
CREATE TABLE IF NOT EXISTS teachers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    subject TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true
);

-- Students table
CREATE TABLE IF NOT EXISTS students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    password_hash TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true
);

-- Lectures table
CREATE TABLE IF NOT EXISTS lectures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
    duration INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Enrollments table
CREATE TABLE IF NOT EXISTS enrollments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    lecture_id UUID NOT NULL REFERENCES lectures(id) ON DELETE CASCADE,
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    UNIQUE(student_id, lecture_id)
);

-- Materials table
CREATE TABLE IF NOT EXISTS materials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lecture_id UUID NOT NULL REFERENCES lectures(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    file_path TEXT NOT NULL,
    compressed_path TEXT NOT NULL,
    file_size INTEGER NOT NULL,
    file_type TEXT NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Quiz sets table (for grouping multiple questions)
CREATE TABLE IF NOT EXISTS quiz_sets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    cohort_id UUID NOT NULL REFERENCES cohorts(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    time_limit INTEGER, -- in minutes, NULL means no time limit
    max_attempts INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    starts_at TIMESTAMP WITH TIME ZONE,
    ends_at TIMESTAMP WITH TIME ZONE
);

-- Quizzes table (individual questions)
CREATE TABLE IF NOT EXISTS quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    quiz_set_id UUID NOT NULL REFERENCES quiz_sets(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    options JSONB NOT NULL,
    correct_answer TEXT NOT NULL,
    points INTEGER DEFAULT 1,
    question_order INTEGER DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Quiz attempts table (student attempts at quiz sets)
CREATE TABLE IF NOT EXISTS quiz_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    quiz_set_id UUID NOT NULL REFERENCES quiz_sets(id) ON DELETE CASCADE,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    submitted_at TIMESTAMP WITH TIME ZONE,
    time_taken INTEGER, -- in seconds
    total_score INTEGER DEFAULT 0,
    max_score INTEGER DEFAULT 0,
    attempt_number INTEGER DEFAULT 1,
    is_completed BOOLEAN DEFAULT false,
    UNIQUE(student_id, quiz_set_id, attempt_number)
);

-- Quiz responses table (individual question responses)
CREATE TABLE IF NOT EXISTS quiz_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    attempt_id UUID NOT NULL REFERENCES quiz_attempts(id) ON DELETE CASCADE,
    quiz_id UUID NOT NULL REFERENCES quizzes(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    response TEXT NOT NULL,
    is_correct BOOLEAN,
    points_earned INTEGER DEFAULT 0,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Polls table
CREATE TABLE IF NOT EXISTS polls (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lecture_id UUID REFERENCES lectures(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    question TEXT NOT NULL,
    options JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Poll responses table
CREATE TABLE IF NOT EXISTS poll_responses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    poll_id UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
    response TEXT NOT NULL,
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Discussion messages table
CREATE TABLE IF NOT EXISTS discussion_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    lecture_id UUID NOT NULL REFERENCES lectures(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    user_type TEXT NOT NULL CHECK (user_type IN ('teacher', 'student')),
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Session recordings table
CREATE TABLE IF NOT EXISTS session_recordings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id TEXT NOT NULL,
    lecture_id UUID NOT NULL REFERENCES lectures(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    recording_path TEXT,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    file_size INTEGER,
    duration INTEGER,
    is_active BOOLEAN DEFAULT true
);

-- Cohorts table
CREATE TABLE IF NOT EXISTS cohorts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    subject TEXT NOT NULL,
    institution_id UUID REFERENCES institutions(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    code TEXT UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

-- Cohort-Students relation
CREATE TABLE IF NOT EXISTS cohort_students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cohort_id UUID NOT NULL REFERENCES cohorts(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(cohort_id, student_id)
);

-- Cohort-Lectures relation
CREATE TABLE IF NOT EXISTS cohort_lectures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cohort_id UUID NOT NULL REFERENCES cohorts(id) ON DELETE CASCADE,
    lecture_id UUID NOT NULL REFERENCES lectures(id) ON DELETE CASCADE,
    UNIQUE(cohort_id, lecture_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_institutions_active ON institutions(is_active);
CREATE INDEX IF NOT EXISTS idx_teachers_email ON teachers(email);
CREATE INDEX IF NOT EXISTS idx_teachers_active ON teachers(is_active);
CREATE INDEX IF NOT EXISTS idx_teachers_institution_id ON teachers(institution_id);
CREATE INDEX IF NOT EXISTS idx_students_email ON students(email);
CREATE INDEX IF NOT EXISTS idx_students_active ON students(is_active);
CREATE INDEX IF NOT EXISTS idx_students_institution_id ON students(institution_id);
CREATE INDEX IF NOT EXISTS idx_lectures_teacher_id ON lectures(teacher_id);
CREATE INDEX IF NOT EXISTS idx_lectures_active ON lectures(is_active);
CREATE INDEX IF NOT EXISTS idx_lectures_scheduled_time ON lectures(scheduled_time);
CREATE INDEX IF NOT EXISTS idx_enrollments_student_id ON enrollments(student_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_lecture_id ON enrollments(lecture_id);
CREATE INDEX IF NOT EXISTS idx_materials_lecture_id ON materials(lecture_id);
CREATE INDEX IF NOT EXISTS idx_quiz_sets_cohort_id ON quiz_sets(cohort_id);
CREATE INDEX IF NOT EXISTS idx_quiz_sets_teacher_id ON quiz_sets(teacher_id);
CREATE INDEX IF NOT EXISTS idx_quiz_sets_active ON quiz_sets(is_active);
CREATE INDEX IF NOT EXISTS idx_quizzes_quiz_set_id ON quizzes(quiz_set_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_student_id ON quiz_attempts(student_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_quiz_set_id ON quiz_attempts(quiz_set_id);
CREATE INDEX IF NOT EXISTS idx_quiz_responses_attempt_id ON quiz_responses(attempt_id);
CREATE INDEX IF NOT EXISTS idx_quiz_responses_quiz_id ON quiz_responses(quiz_id);
CREATE INDEX IF NOT EXISTS idx_quiz_responses_student_id ON quiz_responses(student_id);
CREATE INDEX IF NOT EXISTS idx_polls_lecture_id ON polls(lecture_id);
CREATE INDEX IF NOT EXISTS idx_poll_responses_student_id ON poll_responses(student_id);
CREATE INDEX IF NOT EXISTS idx_poll_responses_poll_id ON poll_responses(poll_id);
CREATE INDEX IF NOT EXISTS idx_discussion_messages_lecture_id ON discussion_messages(lecture_id);
CREATE INDEX IF NOT EXISTS idx_session_recordings_lecture_id ON session_recordings(lecture_id);
CREATE INDEX IF NOT EXISTS idx_cohorts_teacher_id ON cohorts(teacher_id);
CREATE INDEX IF NOT EXISTS idx_cohorts_institution_id ON cohorts(institution_id);
CREATE INDEX IF NOT EXISTS idx_cohorts_code ON cohorts(code);
CREATE INDEX IF NOT EXISTS idx_cohort_students_cohort_id ON cohort_students(cohort_id);
CREATE INDEX IF NOT EXISTS idx_cohort_students_student_id ON cohort_students(student_id);
CREATE INDEX IF NOT EXISTS idx_cohort_lectures_cohort_id ON cohort_lectures(cohort_id);
CREATE INDEX IF NOT EXISTS idx_cohort_lectures_lecture_id ON cohort_lectures(lecture_id);

-- Add teacher_id column to polls table if it doesn't exist (for existing databases)
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'polls' AND column_name = 'teacher_id') THEN
        ALTER TABLE polls ADD COLUMN teacher_id UUID REFERENCES teachers(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Make lecture_id nullable in polls table if it's not already
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'polls' AND column_name = 'lecture_id' AND is_nullable = 'NO') THEN
        ALTER TABLE polls ALTER COLUMN lecture_id DROP NOT NULL;
    END IF;
END $$;

-- Enable Row Level Security (RLS) for better security
ALTER TABLE institutions ENABLE ROW LEVEL SECURITY;
ALTER TABLE teachers ENABLE ROW LEVEL SECURITY;
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE lectures ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_sets ENABLE ROW LEVEL SECURITY;
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_recordings ENABLE ROW LEVEL SECURITY;
ALTER TABLE cohorts ENABLE ROW LEVEL SECURITY;
ALTER TABLE cohort_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE cohort_lectures ENABLE ROW LEVEL SECURITY;

-- Create policies for RLS (basic policies - can be customized based on requirements)
-- Note: DROP POLICY IF EXISTS is used to avoid conflicts when re-running this schema

-- Teachers can read their own data
DROP POLICY IF EXISTS "Teachers can read own data" ON teachers;
CREATE POLICY "Teachers can read own data" ON teachers FOR SELECT USING (auth.uid()::text = id::text);

DROP POLICY IF EXISTS "Teachers can update own data" ON teachers;
CREATE POLICY "Teachers can update own data" ON teachers FOR UPDATE USING (auth.uid()::text = id::text);

-- Students can read their own data
DROP POLICY IF EXISTS "Students can read own data" ON students;
CREATE POLICY "Students can read own data" ON students FOR SELECT USING (auth.uid()::text = id::text);

DROP POLICY IF EXISTS "Students can update own data" ON students;
CREATE POLICY "Students can update own data" ON students FOR UPDATE USING (auth.uid()::text = id::text);

-- Allow public read access to lectures (for browsing)
DROP POLICY IF EXISTS "Anyone can read lectures" ON lectures;
CREATE POLICY "Anyone can read lectures" ON lectures FOR SELECT USING (is_active = true);

-- Teachers can manage their own lectures
DROP POLICY IF EXISTS "Teachers can manage own lectures" ON lectures;
CREATE POLICY "Teachers can manage own lectures" ON lectures FOR ALL USING (auth.uid()::text = teacher_id::text);

-- Students can read enrollments they're part of
DROP POLICY IF EXISTS "Students can read own enrollments" ON enrollments;
CREATE POLICY "Students can read own enrollments" ON enrollments FOR SELECT USING (auth.uid()::text = student_id::text);

-- Teachers can read enrollments for their lectures
DROP POLICY IF EXISTS "Teachers can read lecture enrollments" ON enrollments;
CREATE POLICY "Teachers can read lecture enrollments" ON enrollments FOR SELECT USING (
    EXISTS (SELECT 1 FROM lectures WHERE lectures.id = enrollments.lecture_id AND lectures.teacher_id::text = auth.uid()::text)
);

-- Allow reading materials for enrolled students and lecture owners
DROP POLICY IF EXISTS "Enrolled students can read materials" ON materials;
CREATE POLICY "Enrolled students can read materials" ON materials FOR SELECT USING (
    is_active = true AND (
        EXISTS (
            SELECT 1 FROM enrollments 
            WHERE enrollments.lecture_id = materials.lecture_id 
            AND enrollments.student_id::text = auth.uid()::text
        ) OR
        EXISTS (
            SELECT 1 FROM lectures 
            WHERE lectures.id = materials.lecture_id 
            AND lectures.teacher_id::text = auth.uid()::text
        )
    )
);

-- Additional policies for polls, cohorts, and other tables
DROP POLICY IF EXISTS "Teachers can manage own polls" ON polls;
CREATE POLICY "Teachers can manage own polls" ON polls FOR ALL USING (auth.uid()::text = teacher_id::text);

DROP POLICY IF EXISTS "Students can read polls for enrolled lectures" ON polls;
CREATE POLICY "Students can read polls for enrolled lectures" ON polls FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM enrollments 
        WHERE enrollments.lecture_id = polls.lecture_id 
        AND enrollments.student_id::text = auth.uid()::text
    )
);

DROP POLICY IF EXISTS "Teachers can manage own cohorts" ON cohorts;
CREATE POLICY "Teachers can manage own cohorts" ON cohorts FOR ALL USING (auth.uid()::text = teacher_id::text);

DROP POLICY IF EXISTS "Students can read cohorts they're enrolled in" ON cohorts;
CREATE POLICY "Students can read cohorts they're enrolled in" ON cohorts FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM cohort_students 
        WHERE cohort_students.cohort_id = cohorts.id 
        AND cohort_students.student_id::text = auth.uid()::text
    )
);

-- Session Recording Tables
CREATE TABLE IF NOT EXISTS session_recordings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id TEXT NOT NULL,
    lecture_id UUID NOT NULL REFERENCES lectures(id) ON DELETE CASCADE,
    teacher_id UUID NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
    recording_type TEXT NOT NULL DEFAULT 'full', -- 'full', 'audio_only', 'chat_only'
    started_at TIMESTAMP WITH TIME ZONE NOT NULL,
    stopped_at TIMESTAMP WITH TIME ZONE,
    duration INTEGER, -- in seconds
    recording_path TEXT,
    participants JSONB,
    stats JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true
);

CREATE TABLE IF NOT EXISTS recording_chunks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recording_id UUID NOT NULL REFERENCES session_recordings(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    chunk_type TEXT NOT NULL, -- 'video', 'audio'
    chunk_path TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    file_size INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for session recording tables
CREATE INDEX IF NOT EXISTS idx_session_recordings_lecture ON session_recordings(lecture_id);
CREATE INDEX IF NOT EXISTS idx_session_recordings_teacher ON session_recordings(teacher_id);
CREATE INDEX IF NOT EXISTS idx_session_recordings_session ON session_recordings(session_id);
CREATE INDEX IF NOT EXISTS idx_recording_chunks_recording ON recording_chunks(recording_id);
CREATE INDEX IF NOT EXISTS idx_recording_chunks_user ON recording_chunks(user_id);

-- Enable RLS for session recording tables
ALTER TABLE session_recordings ENABLE ROW LEVEL SECURITY;
ALTER TABLE recording_chunks ENABLE ROW LEVEL SECURITY;

-- RLS Policies for session recordings
DROP POLICY IF EXISTS "Teachers can manage own recordings" ON session_recordings;
CREATE POLICY "Teachers can manage own recordings" ON session_recordings FOR ALL USING (auth.uid()::text = teacher_id::text);

DROP POLICY IF EXISTS "Students can read recordings for enrolled lectures" ON session_recordings;
CREATE POLICY "Students can read recordings for enrolled lectures" ON session_recordings FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM enrollments 
        WHERE enrollments.lecture_id = session_recordings.lecture_id 
        AND enrollments.student_id::text = auth.uid()::text
    )
);

DROP POLICY IF EXISTS "Teachers can manage own recording chunks" ON recording_chunks;
CREATE POLICY "Teachers can manage own recording chunks" ON recording_chunks FOR ALL USING (
    EXISTS (
        SELECT 1 FROM session_recordings 
        WHERE session_recordings.id = recording_chunks.recording_id 
        AND session_recordings.teacher_id::text = auth.uid()::text
    )
);

-- Similar policies for other tables...
-- (Additional policies can be added as needed)
