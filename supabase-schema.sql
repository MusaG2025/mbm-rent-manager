-- MBM Rent Manager: secure Supabase database schema
-- Run this whole script once in Supabase: SQL Editor > New query > Run.
-- This schema gives every signed-in user a completely private copy of their MBM data.

create table if not exists public.mbm_app_state (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  tenant_master jsonb not null default '[]'::jsonb,
  property_master jsonb not null default '[]'::jsonb,
  receipt_history jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

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
