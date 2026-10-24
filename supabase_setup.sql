-- ILATU public website content management (additive setup)
-- This script creates new website-content objects only. It does not change the existing IWDA member, payment, contribution, receipt or profile tables.
-- Run this once in Supabase Dashboard > SQL Editor for the project already used by the ILATU website.

create extension if not exists pgcrypto;

create table if not exists public.ilatu_site_content (
  id uuid primary key default gen_random_uuid(),
  content_type text not null check (content_type in ('photo','news','event')),
  title text not null check (length(trim(title)) between 1 and 180),
  body text not null default '',
  caption text not null default '',
  image_url text,
  event_date date,
  event_location text,
  status text not null default 'draft' check (status in ('draft','published')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint ilatu_site_event_fields_type check (content_type = 'event' or (event_date is null and event_location is null))
);

create index if not exists ilatu_site_content_publication_idx
  on public.ilatu_site_content (status, content_type, created_at desc);

create or replace function public.ilatu_touch_site_content_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists ilatu_site_content_touch_updated_at on public.ilatu_site_content;
create trigger ilatu_site_content_touch_updated_at
before update on public.ilatu_site_content
for each row execute function public.ilatu_touch_site_content_updated_at();

-- A verified Supabase Auth account with the exact administrator email is required.
-- SECURITY DEFINER permits checking auth.users safely without exposing the auth.users table.
create or replace function public.is_ilatu_site_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from auth.users as u
    where u.id = auth.uid()
      and lower(coalesce(u.email, '')) = 'hillaryk171@gmail.com'
      and u.email_confirmed_at is not null
  );
$$;

revoke all on function public.is_ilatu_site_admin() from public;
grant execute on function public.is_ilatu_site_admin() to anon, authenticated;

alter table public.ilatu_site_content enable row level security;

drop policy if exists ilatu_site_content_public_read on public.ilatu_site_content;
create policy ilatu_site_content_public_read
on public.ilatu_site_content for select to anon, authenticated
using (status = 'published' or public.is_ilatu_site_admin());

drop policy if exists ilatu_site_content_admin_insert on public.ilatu_site_content;
create policy ilatu_site_content_admin_insert
on public.ilatu_site_content for insert to authenticated
with check (public.is_ilatu_site_admin());

drop policy if exists ilatu_site_content_admin_update on public.ilatu_site_content;
create policy ilatu_site_content_admin_update
on public.ilatu_site_content for update to authenticated
using (public.is_ilatu_site_admin())
with check (public.is_ilatu_site_admin());

drop policy if exists ilatu_site_content_admin_delete on public.ilatu_site_content;
create policy ilatu_site_content_admin_delete
on public.ilatu_site_content for delete to authenticated
using (public.is_ilatu_site_admin());

grant select on public.ilatu_site_content to anon, authenticated;
grant insert, update, delete on public.ilatu_site_content to authenticated;

-- Public images are served through their public object URLs; only the verified site admin may upload, replace or delete storage objects.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'ilatu-site-media',
  'ilatu-site-media',
  true,
  15728640,
  array['image/jpeg','image/png','image/webp','image/gif']::text[]
)
on conflict (id) do update set
  name = excluded.name,
  public = true,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists ilatu_site_media_admin_insert on storage.objects;
create policy ilatu_site_media_admin_insert
on storage.objects for insert to authenticated
with check (bucket_id = 'ilatu-site-media' and public.is_ilatu_site_admin());

drop policy if exists ilatu_site_media_admin_update on storage.objects;
create policy ilatu_site_media_admin_update
on storage.objects for update to authenticated
using (bucket_id = 'ilatu-site-media' and public.is_ilatu_site_admin())
with check (bucket_id = 'ilatu-site-media' and public.is_ilatu_site_admin());

drop policy if exists ilatu_site_media_admin_delete on storage.objects;
create policy ilatu_site_media_admin_delete
on storage.objects for delete to authenticated
using (bucket_id = 'ilatu-site-media' and public.is_ilatu_site_admin());

-- Note: Supabase public bucket URLs allow visitors to view published images. Content rows remain protected by RLS.
