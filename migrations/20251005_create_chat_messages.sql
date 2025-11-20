-- Create trigger function for updating timestamps
CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create chat_messages table
CREATE TABLE chat_messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    institution_id UUID NOT NULL,
    forum_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    user_name VARCHAR(255) NOT NULL,
    user_type VARCHAR(50) NOT NULL,
    message TEXT,
    attachment JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    FOREIGN KEY (institution_id) REFERENCES institutions(id) ON DELETE CASCADE
);

-- Create indexes for faster message retrieval
CREATE INDEX idx_chat_messages_forum_id ON chat_messages(forum_id);
CREATE INDEX idx_chat_messages_institution_id ON chat_messages(institution_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);
CREATE INDEX idx_chat_messages_user_id ON chat_messages(user_id);

-- Enable Row Level Security
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Create policy for inserting messages
CREATE POLICY "Users can insert their own messages"
    ON chat_messages FOR INSERT
    TO authenticated
    WITH CHECK (
        auth.uid()::text = user_id::text OR
        EXISTS (
            SELECT 1 FROM teachers 
            WHERE teachers.id::text = auth.uid()::text 
            AND teachers.institution_id = institution_id
        ) OR
        EXISTS (
            SELECT 1 FROM students 
            WHERE students.id::text = auth.uid()::text 
            AND students.institution_id = institution_id
        )
    );

-- Create policy for reading messages
CREATE POLICY "Users can read messages in their forums"
    ON chat_messages FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM teachers 
            WHERE teachers.id::text = auth.uid()::text 
            AND teachers.institution_id = institution_id
        ) OR
        EXISTS (
            SELECT 1 FROM students 
            WHERE students.id::text = auth.uid()::text 
            AND students.institution_id = institution_id
        )
    );

-- Create policy for updating own messages
CREATE POLICY "Users can update their own messages"
    ON chat_messages FOR UPDATE
    TO authenticated
    USING (auth.uid()::text = user_id::text)
    WITH CHECK (auth.uid()::text = user_id::text);

-- Trigger to update updated_at timestamp
CREATE TRIGGER set_timestamp
    BEFORE UPDATE ON chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION trigger_set_timestamp();