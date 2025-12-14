-- Enable the pgvector extension to work with embedding vectors
create extension if not exists vector;

-- Create a table to store your course documents/chunks
create table if not exists course_documents (
  id bigserial primary key,
  content text, -- The actual text content (e.g. paragraph from course)
  metadata jsonb, -- Extra info like course_id, module_id, title
  embedding vector(768) -- Vector size matches your embedding model (e.g. Gemini/HuggingFace use 768, OpenAI uses 1536)
);

-- Turn on Row Level Security (optional, depends on if users generate their own docs)
alter table course_documents enable row level security;
create policy "Read access for everyone" on course_documents for select using (true);

-- Create a function to search for similar documents
create or replace function match_course_documents (
  query_embedding vector(768),
  match_threshold float,
  match_count int
) returns table (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
) language plpgsql stable as $$
begin
  return query
  select
    course_documents.id,
    course_documents.content,
    course_documents.metadata,
    1 - (course_documents.embedding <=> query_embedding) as similarity
  from course_documents
  where 1 - (course_documents.embedding <=> query_embedding) > match_threshold
  order by course_documents.embedding <=> query_embedding
  limit match_count;
end;
$$;
