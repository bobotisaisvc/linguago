-- LinguaGo database schema (Supabase PostgreSQL)
-- Run in Supabase Dashboard > SQL Editor.
-- IMPORTANT: XP in a browser-only starter can be manipulated by users.
-- For a competitive production leaderboard, award XP through a trusted server endpoint.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Pelajar' check (char_length(display_name) between 1 and 40),
  total_xp integer not null default 0 check (total_xp >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.user_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  progress jsonb not null default '{"xp":0,"lessons":0,"done":[],"level":1}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  language_code text not null default 'en',
  quiz_code text not null,
  score integer not null default 0 check (score >= 0),
  total_questions integer not null check (total_questions > 0),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.user_progress enable row level security;
alter table public.quiz_attempts enable row level security;

-- Profiles: authenticated users can read public leaderboard fields, but only
-- update their own display name. XP is maintained by a trigger below.
drop policy if exists "Public leaderboard profiles readable" on public.profiles;
create policy "Public leaderboard profiles readable"
on public.profiles for select to anon, authenticated using (true);

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
on public.profiles for update to authenticated
using ((select auth.uid()) = id)
with check ((select auth.uid()) = id);

revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to anon, authenticated;
grant update (display_name) on public.profiles to authenticated;

-- Each user can access only their own progress.
drop policy if exists "Users can read own progress" on public.user_progress;
create policy "Users can read own progress"
on public.user_progress for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can insert own progress" on public.user_progress;
create policy "Users can insert own progress"
on public.user_progress for insert to authenticated
with check ((select auth.uid()) = user_id);

drop policy if exists "Users can update own progress" on public.user_progress;
create policy "Users can update own progress"
on public.user_progress for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

revoke all on public.user_progress from anon, authenticated;
grant select, insert, update on public.user_progress to authenticated;

-- A user may only view and add their own quiz attempts.
drop policy if exists "Users can read own quiz attempts" on public.quiz_attempts;
create policy "Users can read own quiz attempts"
on public.quiz_attempts for select to authenticated
using ((select auth.uid()) = user_id);

drop policy if exists "Users can add own quiz attempts" on public.quiz_attempts;
create policy "Users can add own quiz attempts"
on public.quiz_attempts for insert to authenticated
with check ((select auth.uid()) = user_id);

revoke all on public.quiz_attempts from anon, authenticated;
grant select, insert on public.quiz_attempts to authenticated;

-- Create a profile automatically for every new Auth user.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(nullif(split_part(new.email, '@', 1), ''), 'Pelajar')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Reflect stored progress XP on the public leaderboard profile.
-- Note: since this starter accepts progress from the client, this is not
-- cheat-resistant. Move XP awarding to a trusted server function for production.
create or replace function public.sync_profile_xp()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare xp_value integer;
begin
  xp_value := greatest(0, coalesce((new.progress ->> 'xp')::integer, 0));
  update public.profiles
  set total_xp = xp_value, updated_at = now()
  where id = new.user_id;
  return new;
exception when others then
  return new;
end;
$$;

drop trigger if exists on_progress_changed on public.user_progress;
create trigger on_progress_changed
after insert or update of progress on public.user_progress
for each row execute procedure public.sync_profile_xp();

-- Read-only public leaderboard: only display name and XP are exposed.
create or replace view public.leaderboard
with (security_invoker = true)
as
select display_name, total_xp
from public.profiles
order by total_xp desc, display_name asc
limit 100;

grant select on public.leaderboard to anon, authenticated;

-- For a production-grade competitive app:
-- 1. Do not accept arbitrary XP from browser clients.
-- 2. Validate answers and award XP in a trusted Cloudflare Pages Function.
-- 3. Add request throttling and abuse monitoring.
