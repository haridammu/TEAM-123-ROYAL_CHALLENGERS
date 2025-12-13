-- Create course_reels table
CREATE TABLE IF NOT EXISTS public.course_reels (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    course_id INTEGER REFERENCES public.courses(id) ON DELETE CASCADE,
    course_title TEXT NOT NULL,
    video_id TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    language TEXT NOT NULL DEFAULT 'English',
    likes INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create reel_likes table
CREATE TABLE IF NOT EXISTS public.reel_likes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    reel_id UUID REFERENCES public.course_reels(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    course_id INTEGER REFERENCES public.courses(id) ON DELETE CASCADE,
    language TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(reel_id, user_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_course_reels_course_id ON public.course_reels(course_id);
CREATE INDEX IF NOT EXISTS idx_course_reels_language ON public.course_reels(language);
CREATE INDEX IF NOT EXISTS idx_course_reels_created_at ON public.course_reels(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reel_likes_reel_id ON public.reel_likes(reel_id);
CREATE INDEX IF NOT EXISTS idx_reel_likes_user_id ON public.reel_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_reel_likes_course_id ON public.reel_likes(course_id);

-- Enable RLS (Row Level Security)
ALTER TABLE public.course_reels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reel_likes ENABLE ROW LEVEL SECURITY;

-- Create policies for course_reels
CREATE POLICY "Everyone can view course reels" ON public.course_reels
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert course reels" ON public.course_reels
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update course reels" ON public.course_reels
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete course reels" ON public.course_reels
    FOR DELETE USING (auth.role() = 'authenticated');

-- Create policies for reel_likes
CREATE POLICY "Everyone can view reel likes" ON public.reel_likes
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert reel likes" ON public.reel_likes
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can delete their own reel likes" ON public.reel_likes
    FOR DELETE USING (auth.uid() = user_id);

-- Create functions for incrementing/decrementing likes
CREATE OR REPLACE FUNCTION increment(value INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN value + 1;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement(value INTEGER)
RETURNS INTEGER AS $$
BEGIN
    RETURN GREATEST(value - 1, 0);
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT ALL ON TABLE public.course_reels TO authenticated;
GRANT ALL ON TABLE public.reel_likes TO authenticated;
GRANT EXECUTE ON FUNCTION increment TO authenticated;
GRANT EXECUTE ON FUNCTION decrement TO authenticated;