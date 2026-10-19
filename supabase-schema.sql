-- MBM Rent Manager: secure Supabase database schema
-- Run this whole script once in Supabase: SQL Editor > New query > Run.
-- This schema gives every signed-in user a completely private copy of their MBM data.

create table if not exists public.mbm_app_state (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  tenant_master jsonb not null default '[]'::jsonb,
  property_master jsonb not null default '[]'::jsonb,
  receipt_history jsonb not null default '[]'::jsonb,
  municipal_accounts jsonb not null default '[]'::jsonb,
  operations_data jsonb not null default '{"workOrders":[],"inspections":[]}'::jsonb,
  renewal_cases jsonb not null default '[]'::jsonb,
  calendar_events jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

-- Safe upgrade for a project where the earlier MBM schema has already run.
alter table public.mbm_app_state
add column if not exists municipal_accounts jsonb not null default '[]'::jsonb;

alter table public.mbm_app_state
add column if not exists operations_data jsonb not null default '{"workOrders":[],"inspections":[]}'::jsonb;

alter table public.mbm_app_state
add column if not exists renewal_cases jsonb not null default '[]'::jsonb;

alter table public.mbm_app_state
add column if not exists calendar_events jsonb not null default '[]'::jsonb;

-- Private contract-document vault. Files are stored only beneath the signed-in owner's folder.
insert into storage.buckets (id, name, public)
values ('mbm-private-documents', 'mbm-private-documents', false)
on conflict (id) do nothing;

drop policy if exists "MBM owners can read private documents" on storage.objects;
create policy "MBM owners can read private documents"
on storage.objects for select
to authenticated
using (bucket_id = 'mbm-private-documents' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "MBM owners can upload private documents" on storage.objects;
create policy "MBM owners can upload private documents"
on storage.objects for insert
to authenticated
with check (bucket_id = 'mbm-private-documents' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "MBM owners can update private documents" on storage.objects;
create policy "MBM owners can update private documents"
on storage.objects for update
to authenticated
using (bucket_id = 'mbm-private-documents' and (storage.foldername(name))[1] = auth.uid()::text)
with check (bucket_id = 'mbm-private-documents' and (storage.foldername(name))[1] = auth.uid()::text);

drop policy if exists "MBM owners can delete private documents" on storage.objects;
create policy "MBM owners can delete private documents"
on storage.objects for delete
to authenticated
using (bucket_id = 'mbm-private-documents' and (storage.foldername(name))[1] = auth.uid()::text);

alter table public.mbm_app_state enable row level security;

drop policy if exists "MBM users can read their own data" on public.mbm_app_state;
create policy "MBM users can read their own data"
on public.mbm_app_state for select
to authenticated
using (owner_id = auth.uid());

drop policy if exists "MBM users can insert their own data" on public.mbm_app_state;
create policy "MBM users can insert their own data"
on public.mbm_app_state for insert
to authenticated
with check (owner_id = auth.uid());

drop policy if exists "MBM users can update their own data" on public.mbm_app_state;
create policy "MBM users can update their own data"
on public.mbm_app_state for update
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

drop policy if exists "MBM users can delete their own data" on public.mbm_app_state;
create policy "MBM users can delete their own data"
on public.mbm_app_state for delete
to authenticated
using (owner_id = auth.uid());

create or replace function public.mbm_touch_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists mbm_app_state_touch_updated_at on public.mbm_app_state;
create trigger mbm_app_state_touch_updated_at
before update on public.mbm_app_state
for each row execute function public.mbm_touch_updated_at();
