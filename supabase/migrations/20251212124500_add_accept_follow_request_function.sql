-- Add function to accept follow requests and create follow relationship
-- This function can bypass RLS policies since it runs on the server

CREATE OR REPLACE FUNCTION accept_follow_request(request_id INTEGER)
RETURNS VOID AS $$
DECLARE
  requester_uuid UUID;
  receiver_uuid UUID;
BEGIN
  -- Update the connection status to accepted
  UPDATE connections 
  SET status = 'accepted', updated_at = NOW()
  WHERE id = request_id;
  
  -- Get the connection details
  SELECT requester_id, receiver_id 
  INTO requester_uuid, receiver_uuid
  FROM connections 
  WHERE id = request_id;
  
  -- Create the follow relationship: requester follows receiver
  -- This bypasses RLS since it's done server-side
  INSERT INTO followers (follower_id, followed_id, created_at)
  VALUES (requester_uuid, receiver_uuid, NOW())
  ON CONFLICT (follower_id, followed_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION accept_follow_request(INTEGER) TO authenticated;