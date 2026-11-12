-- Core operational schema for Al-Jawadain School.
-- Apply after 0001_initial_schema.sql in Supabase SQL Editor.
-- User profiles are provisioned by a trusted administrator/service-role process.
-- Never expose the service-role key in the mobile app.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  school_id uuid not null references public.schools(id) on delete restrict,
  full_name text not null,
  phone text,
  role text not null check (role in ('admin', 'teacher', 'parent')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  name text not null,
  grade_level text not null,
  section text,
  academic_year text not null,
  created_at timestamptz not null default now(),
  unique (school_id, name, academic_year)
);

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  class_id uuid references public.classes(id) on delete set null,
  student_code text not null,
  full_name text not null,
  birth_date date,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (school_id, student_code)
);

create table if not exists public.parent_student (
  school_id uuid not null references public.schools(id) on delete cascade,
  parent_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  relationship text not null default 'ولي أمر',
  created_at timestamptz not null default now(),
  primary key (parent_id, student_id)
);

create table if not exists public.subjects (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  unique (school_id, name)
);

create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  attendance_date date not null,
  status text not null check (status in ('present', 'absent', 'late', 'excused')),
  note text,
  recorded_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  unique (student_id, attendance_date)
);

create table if not exists public.grades (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete restrict,
  assessment_name text not null,
  score numeric(7,2) not null check (score >= 0),
  max_score numeric(7,2) not null check (max_score > 0 and score <= max_score),
  assessment_date date not null default current_date,
  recorded_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  title text not null,
  body text not null,
  is_published boolean not null default false,
  published_at timestamptz,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.timetable_entries (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete restrict,
  weekday smallint not null check (weekday between 0 and 6),
  period_number smallint not null check (period_number > 0),
  starts_at time,
  ends_at time,
  room text,
  created_at timestamptz not null default now(),
  unique (class_id, weekday, period_number),
  check (ends_at is null or starts_at is null or ends_at > starts_at)
);

create index if not exists idx_profiles_school_role on public.profiles(school_id, role);
create index if not exists idx_students_school_class on public.students(school_id, class_id);
create index if not exists idx_parent_student_student on public.parent_student(student_id);
create index if not exists idx_attendance_school_date on public.attendance(school_id, attendance_date);
create index if not exists idx_grades_student_date on public.grades(student_id, assessment_date);
create index if not exists idx_announcements_school_published on public.announcements(school_id, is_published, published_at desc);
create index if not exists idx_timetable_class_day on public.timetable_entries(class_id, weekday, period_number);

-- Security-definer helpers avoid recursive RLS checks on profiles.
create or replace function public.current_school_id()
returns uuid
language sql stable security definer
set search_path = public, auth
as $$
  select p.school_id
  from public.profiles p
  where p.id = auth.uid() and p.is_active = true
  limit 1
$$;

create or replace function public.current_user_role()
returns text
language sql stable security definer
set search_path = public, auth
as $$
  select p.role
  from public.profiles p
  where p.id = auth.uid() and p.is_active = true
  limit 1
$$;

create or replace function public.is_linked_parent(target_student_id uuid)
returns boolean
language sql stable security definer
set search_path = public, auth
as $$
  select exists (
    select 1 from public.parent_student ps
    where ps.student_id = target_student_id and ps.parent_id = auth.uid()
  )
$$;

alter table public.schools enable row level security;
alter table public.profiles enable row level security;
alter table public.classes enable row level security;
alter table public.students enable row level security;
alter table public.parent_student enable row level security;
alter table public.subjects enable row level security;
alter table public.attendance enable row level security;
alter table public.grades enable row level security;
alter table public.announcements enable row level security;
alter table public.timetable_entries enable row level security;

drop policy if exists "school members read own school" on public.schools;
create policy "school members read own school" on public.schools
for select to authenticated using (id = public.current_school_id());

drop policy if exists "users read permitted profiles" on public.profiles;
create policy "users read permitted profiles" on public.profiles
for select to authenticated using (
  id = auth.uid()
  or (school_id = public.current_school_id() and public.current_user_role() = 'admin')
);

drop policy if exists "school members read classes" on public.classes;
create policy "school members read classes" on public.classes
for select to authenticated using (school_id = public.current_school_id());

drop policy if exists "admins manage classes" on public.classes;
create policy "admins manage classes" on public.classes
for all to authenticated using (
  school_id = public.current_school_id() and public.current_user_role() = 'admin'
) with check (
  school_id = public.current_school_id() and public.current_user_role() = 'admin'
);

drop policy if exists "staff and linked parents read students" on public.students;
create policy "staff and linked parents read students" on public.students
for select to authenticated using (
  school_id = public.current_school_id()
  and (public.current_user_role() in ('admin', 'teacher') or public.is_linked_parent(id))
);

drop policy if exists "admins manage students" on public.students;
create policy "admins manage students" on public.students
for all to authenticated using (
  school_id = public.current_school_id() and public.current_user_role() = 'admin'
) with check (
  school_id = public.current_school_id() and public.current_user_role() = 'admin'
);

drop policy if exists "parents and admins read links" on public.parent_student;
create policy "parents and admins read links" on public.parent_student
for select to authenticated using (
  parent_id = auth.uid()
  or (school_id = public.current_school_id() and public.current_user_role() = 'admin')
);

drop policy if exists "admins manage links" on public.parent_student;
create policy "admins manage links" on public.parent_student
for all to authenticated using (
  school_id = public.current_school_id() and public.current_user_role() = 'admin'
) with check (
  school_id = public.current_school_id() and public.current_user_role() = 'admin'
);

drop policy if exists "school members read subjects" on public.subjects;
create policy "school members read subjects" on public.subjects
for select to authenticated using (school_id = public.current_school_id());

drop policy if exists "admins manage subjects" on public.subjects;
create policy "admins manage subjects" on public.subjects
for all to authenticated using (
  school_id = public.current_school_id() and public.current_user_role() = 'admin'
) with check (
  school_id = public.current_school_id() and public.current_user_role() = 'admin'
);

drop policy if exists "authorized users read attendance" on public.attendance;
create policy "authorized users read attendance" on public.attendance
for select to authenticated using (
  school_id = public.current_school_id()
  and (public.current_user_role() in ('admin', 'teacher') or public.is_linked_parent(student_id))
);

drop policy if exists "staff record attendance" on public.attendance;
create policy "staff record attendance" on public.attendance
for insert to authenticated with check (
  school_id = public.current_school_id()
  and public.current_user_role() in ('admin', 'teacher')
  and recorded_by = auth.uid()
);

drop policy if exists "staff update attendance" on public.attendance;
create policy "staff update attendance" on public.attendance
for update to authenticated using (
  school_id = public.current_school_id() and public.current_user_role() in ('admin', 'teacher')
) with check (
  school_id = public.current_school_id() and public.current_user_role() in ('admin', 'teacher')
);

drop policy if exists "authorized users read grades" on public.grades;
create policy "authorized users read grades" on public.grades
for select to authenticated using (
  school_id = public.current_school_id()
  and (public.current_user_role() in ('admin', 'teacher') or public.is_linked_parent(student_id))
);

drop policy if exists "staff insert grades" on public.grades;
create policy "staff insert grades" on public.grades
for insert to authenticated with check (
  school_id = public.current_school_id()
  and public.current_user_role() in ('admin', 'teacher')
  and recorded_by = auth.uid()
);

drop policy if exists "staff update grades" on public.grades;
create policy "staff update grades" on public.grades
for update to authenticated using (
  school_id = public.current_school_id() and public.current_user_role() in ('admin', 'teacher')
) with check (
  school_id = public.current_school_id() and public.current_user_role() in ('admin', 'teacher')
);

drop policy if exists "members read published announcements" on public.announcements;
create policy "members read published announcements" on public.announcements
for select to authenticated using (
  school_id = public.current_school_id()
  and (is_published = true or public.current_user_role() = 'admin')
);

drop policy if exists "admins manage announcements" on public.announcements;
create policy "admins manage announcements" on public.announcements
for all to authenticated using (
  school_id = public.current_school_id() and public.current_user_role() = 'admin'
) with check (
  school_id = public.current_school_id()
  and public.current_user_role() = 'admin'
  and created_by = auth.uid()
);

drop policy if exists "members read timetable" on public.timetable_entries;
create policy "members read timetable" on public.timetable_entries
for select to authenticated using (school_id = public.current_school_id());

drop policy if exists "admins manage timetable" on public.timetable_entries;
create policy "admins manage timetable" on public.timetable_entries
for all to authenticated using (
  school_id = public.current_school_id() and public.current_user_role() = 'admin'
) with check (
  school_id = public.current_school_id() and public.current_user_role() = 'admin'
);

-- Authenticated users receive only the operations permitted by RLS policies.
grant select on public.schools, public.profiles, public.classes, public.students,
  public.parent_student, public.subjects, public.attendance, public.grades,
  public.announcements, public.timetable_entries to authenticated;
grant insert, update, delete on public.classes, public.students, public.parent_student,
  public.subjects, public.timetable_entries to authenticated;
grant insert, update on public.attendance, public.grades to authenticated;
grant insert, update, delete on public.announcements to authenticated;
grant execute on function public.current_school_id() to authenticated;
grant execute on function public.current_user_role() to authenticated;
grant execute on function public.is_linked_parent(uuid) to authenticated;
