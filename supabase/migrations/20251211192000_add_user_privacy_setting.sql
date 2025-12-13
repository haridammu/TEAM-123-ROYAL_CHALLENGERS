-- Add is_private column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false;

-- Add comment to explain the column purpose
COMMENT ON COLUMN users.is_private IS 'Indicates if the user profile is private (true) or public (false)';