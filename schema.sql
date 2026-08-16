-- ============================================================
-- OHWC Coach Sign-Up — database schema
-- Run this once in Supabase: Project → SQL Editor → New query → paste → Run
-- ============================================================

create extension if not exists pgcrypto;

-- ------------------------------------------------------------
-- Profiles: one row per logged-in member. Created automatically
-- the first time someone signs in. is_admin controls whether
-- someone sees the Committee tab and full mobile numbers.
-- ------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  is_admin boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "profiles_select_own_or_admin"
  on public.profiles for select
  using (
    auth.uid() = id
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  );

create policy "profiles_update_own"
  on public.profiles for update
  using ( auth.uid() = id )
  with check ( auth.uid() = id );

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer as $$
begin
  insert into public.profiles (id, email) values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ------------------------------------------------------------
-- Trips: only one is_active = true trip exists at a time.
-- Archiving a trip sets is_active = false and starts a new row.
-- ------------------------------------------------------------
create table public.trips (
  id uuid primary key default gen_random_uuid(),
  destination text not null,
  trip_date text not null,
  is_active boolean not null default true,
  archived_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.trips enable row level security;

create policy "trips_select_active_or_admin"
  on public.trips for select
  using (
    is_active = true
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  );

create policy "trips_write_admin_only"
  on public.trips for all
  using ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin) )
  with check ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin) );

-- ------------------------------------------------------------
-- Walks: the choices available on a given trip, each with a cap.
-- ------------------------------------------------------------
create table public.walks (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  label text not null,
  cap int not null default 12
);

alter table public.walks enable row level security;

create policy "walks_select_via_trip"
  on public.walks for select
  using (
    exists (
      select 1 from public.trips t
      where t.id = trip_id
        and (t.is_active or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin))
    )
  );

create policy "walks_write_admin_only"
  on public.walks for all
  using ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin) )
  with check ( exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin) );

-- ------------------------------------------------------------
-- Signups: the real booking data, including mobile numbers.
-- One signup per member per trip.
-- ------------------------------------------------------------
create table public.signups (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete cascade,
  walk_id uuid not null references public.walks(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  mobile text not null,
  pickup text not null check (pickup in ('O','AR','PPR','FP')),
  created_at timestamptz not null default now(),
  unique (trip_id, user_id)
);

alter table public.signups enable row level security;

-- Full row (including mobile) visible only to the member themself, or admins.
create policy "signups_select_own_or_admin"
  on public.signups for select
  using (
    user_id = auth.uid()
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  );

create policy "signups_insert_own"
  on public.signups for insert
  with check ( user_id = auth.uid() );

create policy "signups_delete_own_or_admin"
  on public.signups for delete
  using (
    user_id = auth.uid()
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  );

create policy "signups_update_own_or_admin"
  on public.signups for update
  using (
    user_id = auth.uid()
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  )
  with check (
    user_id = auth.uid()
    or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_admin)
  );

-- Public roster: what every member sees on "Who's coming" — no mobile column,
-- so there is nothing to leak even if a policy elsewhere is ever misconfigured.
create view public.signups_roster as
  select s.id, s.trip_id, s.walk_id, s.name, s.pickup, s.created_at
  from public.signups s
  join public.trips t on t.id = s.trip_id
  where t.is_active = true;

grant select on public.signups_roster to authenticated;

-- ------------------------------------------------------------
-- Server-side capacity enforcement: the actual fix for the
-- "two people grab the last spot at once" problem.
-- ------------------------------------------------------------
create or replace function public.enforce_walk_capacity()
returns trigger language plpgsql as $$
declare
  current_count int;
  walk_cap int;
begin
  select cap into walk_cap from public.walks where id = new.walk_id;
  select count(*) into current_count
    from public.signups
    where walk_id = new.walk_id
      and id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000');
  if current_count >= walk_cap then
    raise exception 'That walk is full — please choose another.';
  end if;
  return new;
end;
$$;

create trigger trg_enforce_capacity
  before insert or update on public.signups
  for each row execute procedure public.enforce_walk_capacity();

-- ============================================================
-- SEED DATA — edit the values below, then run this block once
-- to create the first trip. (Run this AFTER you have made your
-- own account an admin — see SETUP-GUIDE.txt step 5.)
-- ============================================================
insert into public.trips (destination, trip_date, is_active)
values ('Longnor, Staffordshire — Peak District', 'Sunday 6 September 2026', true);

insert into public.walks (trip_id, label, cap)
select id, w.label, 12
from public.trips t
cross join (values
  ('Walk 1 — Easy (8 miles)'),
  ('Walk 2 — Standard (10 miles)'),
  ('Walk 3 — Challenging (13 miles)')
) as w(label)
where t.is_active = true;
