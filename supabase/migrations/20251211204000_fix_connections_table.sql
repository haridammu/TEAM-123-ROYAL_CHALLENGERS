-- Drop and recreate connections table with correct schema
DROP TABLE IF EXISTS connections CASCADE;

-- Create connections table (for friend requests)
CREATE TABLE IF NOT EXISTS connections (
  id SERIAL PRIMARY KEY,
  requester_id UUID REFERENCES auth.users ON DELETE CASCADE,
  receiver_id UUID REFERENCES auth.users ON DELETE CASCADE,
  status TEXT DEFAULT 'pending', -- pending, accepted, rejected
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(requester_id, receiver_id)
);

-- Enable RLS
ALTER TABLE connections ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own connections"
ON connections FOR ALL
USING (requester_id = auth.uid() OR receiver_id = auth.uid());

CREATE POLICY "Users can insert their own connections"
ON connections FOR INSERT
WITH CHECK (requester_id = auth.uid());