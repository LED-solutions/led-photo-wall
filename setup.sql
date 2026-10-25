-- ============================================================
-- LED Photo Wall · Supabase setup
-- Run this whole file ONCE in Supabase → SQL Editor → New query → Run.
-- Safe to run again later (it updates instead of duplicating).
-- ============================================================

create extension if not exists pgcrypto;

-- ---------- Tables ----------

-- One row per wedding / gala
create table if not exists public.events (
  slug          text primary key check (slug ~ '^[a-z0-9][a-z0-9-]{1,39}$'),
  title         text not null,
  subtitle      text,
  auto_approve  boolean not null default false,
  open          boolean not null default true,      -- guests can upload
  show_qr       boolean not null default true,      -- QR code on the screen
  mode          text not null default 'spotlight'
                check (mode in ('spotlight','slideshow','mosaic','polaroid','overlay')),
  spotlight_id  uuid,                               -- "Show now" photo
  spotlight_at  timestamptz,
  rev           integer not null default 0,         -- bumped when a shown photo is hidden
  created_at    timestamptz not null default now()
);

-- One row per uploaded photo
create table if not exists public.photos (
  id          uuid primary key default gen_random_uuid(),
  event_slug  text not null references public.events(slug) on delete cascade,
  path        text not null,
  guest_name  text check (char_length(guest_name) <= 40),
  message     text check (char_length(message) <= 140),
  width       integer,
  height      integer,
  status      text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at  timestamptz not null default now(),
  approved_at timestamptz
);
create index if not exists photos_event_status_idx on public.photos (event_slug, status, approved_at);

-- Who can moderate (filled in step 4 of the README)
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);

-- ---------- Helpers ----------

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- Guests can't choose the status of their own photo: the event decides.
create or replace function public.photos_before_insert() returns trigger
language plpgsql security definer set search_path = public as $$
declare ev public.events;
begin
  select * into ev from public.events where slug = new.event_slug;
  if not found then raise exception 'Unknown event'; end if;
  if not ev.open and not public.is_admin() then raise exception 'Photo sharing is closed'; end if;
  if new.path not like new.event_slug || '/%' then raise exception 'Bad photo path'; end if;
  new.created_at := now();
  if ev.auto_approve then
    new.status := 'approved'; new.approved_at := now();
  else
    new.status := 'pending'; new.approved_at := null;
  end if;
  return new;
end $$;

drop trigger if exists photos_before_insert on public.photos;
create trigger photos_before_insert before insert on public.photos
  for each row execute function public.photos_before_insert();

-- Approval time + tell the screen when a shown photo is hidden
create or replace function public.photos_before_update() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'approved' and old.status <> 'approved' then new.approved_at := now(); end if;
  if old.status = 'approved' and new.status <> 'approved' then
    update public.events set rev = rev + 1 where slug = old.event_slug;
  end if;
  return new;
end $$;

drop trigger if exists photos_before_update on public.photos;
create trigger photos_before_update before update on public.photos
  for each row execute function public.photos_before_update();

create or replace function public.photos_after_delete() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if old.status = 'approved' then
    update public.events set rev = rev + 1 where slug = old.event_slug;
  end if;
  return old;
end $$;

drop trigger if exists photos_after_delete on public.photos;
create trigger photos_after_delete after delete on public.photos
  for each row execute function public.photos_after_delete();

-- ---------- Security (who can do what) ----------

alter table public.events enable row level security;
alter table public.photos enable row level security;
alter table public.admins enable row level security;

drop policy if exists "events readable by all" on public.events;
create policy "events readable by all" on public.events for select using (true);

drop policy if exists "events managed by admins" on public.events;
create policy "events managed by admins" on public.events for all to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists "guests add photos" on public.photos;
create policy "guests add photos" on public.photos for insert to anon, authenticated
  with check (true);  -- the trigger above checks the event and forces the status

drop policy if exists "approved photos readable" on public.photos;
create policy "approved photos readable" on public.photos for select
  using (status = 'approved' or public.is_admin());

drop policy if exists "admins update photos" on public.photos;
create policy "admins update photos" on public.photos for update to authenticated
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists "admins delete photos" on public.photos;
create policy "admins delete photos" on public.photos for delete to authenticated
  using (public.is_admin());

drop policy if exists "admins see themselves" on public.admins;
create policy "admins see themselves" on public.admins for select to authenticated
  using (user_id = auth.uid());

-- ---------- Photo storage ----------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('photos', 'photos', true, 6291456, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
  set public = true,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "guests upload photo files" on storage.objects;
create policy "guests upload photo files" on storage.objects for insert to anon, authenticated
  with check (bucket_id = 'photos');

drop policy if exists "admins delete photo files" on storage.objects;
create policy "admins delete photo files" on storage.objects for delete to authenticated
  using (bucket_id = 'photos' and public.is_admin());

-- ---------- Live updates ----------

do $$
begin
  begin alter publication supabase_realtime add table public.photos;
  exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.events;
  exception when duplicate_object then null; end;
end $$;

-- ============================================================
-- LAST STEP (after creating your user in Authentication → Users):
-- replace the email below with yours, select ONLY these two lines, and run.
--
-- insert into public.admins (user_id)
--   select id from auth.users where email = 'you@example.com';
-- ============================================================
