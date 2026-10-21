-- MBM Property Manager V1: relational Supabase foundation
-- Run once in Supabase SQL Editor after reviewing the script.
-- This replaces the old single JSON backup model for the new V1 application.

create extension if not exists pgcrypto;

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid not null references auth.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.organization_members (
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('Administrator','Property Manager','Finance','Operations','Legal','Viewer')),
  created_at timestamptz not null default now(),
  primary key (organization_id, user_id)
);

create or replace function public.mbm_is_member(p_organization_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.organization_members m
    where m.organization_id = p_organization_id and m.user_id = auth.uid()
  );
$$;

create or replace function public.mbm_can_write(p_organization_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.organization_members m
    where m.organization_id = p_organization_id
      and m.user_id = auth.uid()
      and m.role <> 'Viewer'
  );
$$;

create or replace function public.mbm_is_admin(p_organization_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.organization_members m
    where m.organization_id = p_organization_id
      and m.user_id = auth.uid()
      and m.role = 'Administrator'
  );
$$;

create table if not exists public.properties (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  code text not null, name text not null, erf text, address text, locality text, country text,
  latitude numeric(10,7), longitude numeric(10,7), location_source text, location_accuracy_m numeric(10,2), location_verified_at timestamptz,
  property_type text not null default 'Residential', status text not null default 'Active',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique (organization_id, code)
);
create table if not exists public.units (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade, name text not null, unit_type text not null default 'Rental Unit', status text not null default 'Vacant', market_rent numeric(14,2) not null default 0,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique (property_id, name)
);
create table if not exists public.contacts (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  contact_type text not null default 'Tenant', legal_name text not null, phone text, email text, id_reference text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.leases (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  property_id uuid not null references public.properties(id), unit_id uuid not null references public.units(id), tenant_id uuid not null references public.contacts(id),
  lease_number text not null, status text not null default 'Draft', start_date date, end_date date, monthly_rent numeric(14,2) not null default 0,
  annual_escalation_pct numeric(6,3) not null default 0, deposit_amount numeric(14,2) not null default 0, notice_days integer not null default 60, notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique (organization_id, lease_number)
);
create table if not exists public.lease_documents (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  lease_id uuid not null references public.leases(id) on delete cascade, document_type text not null, file_name text not null, storage_path text, status text not null default 'Current', review_or_expiry_date date, notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.renewal_cases (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  lease_id uuid not null references public.leases(id) on delete cascade, stage text not null default 'Expiry review', next_action_date date, notice_date date,
  proposed_term_months integer, proposed_monthly_rent numeric(14,2), escalation_pct numeric(6,3), legal_status text not null default 'Not started', management_status text not null default 'Not requested',
  new_agreement_reference text, signature_date date, billing_activation_date date, notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique (lease_id)
);
create table if not exists public.charges (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  lease_id uuid not null references public.leases(id), charge_date date not null, charge_type text not null, description text, amount numeric(14,2) not null check (amount >= 0), status text not null default 'Open',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  lease_id uuid references public.leases(id), receipt_number text not null, payment_date date not null, rental_period text, amount numeric(14,2) not null check (amount > 0), method text, notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique (organization_id, receipt_number)
);
create table if not exists public.payment_allocations (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  payment_id uuid not null references public.payments(id) on delete cascade, charge_id uuid not null references public.charges(id) on delete cascade, amount numeric(14,2) not null check (amount > 0),
  created_at timestamptz not null default now(), unique (payment_id, charge_id)
);
create table if not exists public.municipal_accounts (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade, account_number text, current_balance numeric(14,2) not null default 0, statement_date date, due_date date, notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique (property_id)
);

-- V15: municipal debt-collector repayment agreement tracked per property/account.
-- These ALTER statements are safe if the V1 schema has already been run.
alter table public.municipal_accounts add column if not exists arrangement_status text not null default 'No arrangement';
alter table public.municipal_accounts add column if not exists collector_name text;
alter table public.municipal_accounts add column if not exists agreement_reference text;
alter table public.municipal_accounts add column if not exists agreement_total numeric(14,2) not null default 0;
alter table public.municipal_accounts add column if not exists arrangement_balance numeric(14,2) not null default 0;
alter table public.municipal_accounts add column if not exists monthly_installment numeric(14,2) not null default 0;
alter table public.municipal_accounts add column if not exists arrangement_start_date date;
alter table public.municipal_accounts add column if not exists arrangement_end_date date;
alter table public.municipal_accounts add column if not exists next_arrangement_due_date date;

alter table public.lease_documents add column if not exists uploaded_at timestamptz not null default now();
create table if not exists public.work_orders (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  property_id uuid not null references public.properties(id), unit_id uuid references public.units(id), title text not null, description text, priority text not null default 'Normal', assignee text, due_date date, status text not null default 'Open',
  estimated_cost numeric(14,2) not null default 0, actual_cost numeric(14,2) not null default 0, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.inspections (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  property_id uuid not null references public.properties(id), unit_id uuid references public.units(id), inspection_type text not null, scheduled_date date not null, inspector text, status text not null default 'Scheduled', notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  title text not null, due_date date not null, owner_name text, priority text not null default 'Normal', status text not null default 'Open', notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.audit_log (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  actor_id uuid references auth.users(id), action text not null, record_type text, record_id uuid, detail text, created_at timestamptz not null default now()
);

-- V10 integrated property-management extensions. These preserve a lean start,
-- while giving MBM a normalised path for vacancies, owners, payables, operations
-- and communications rather than another browser-only rewrite.
create table if not exists public.property_owners (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  property_id uuid not null references public.properties(id) on delete cascade, owner_contact_id uuid not null references public.contacts(id) on delete cascade,
  ownership_pct numeric(7,4), management_fee_pct numeric(7,4), reserve_target numeric(14,2), status text not null default 'Active',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(property_id, owner_contact_id)
);
create table if not exists public.prospects (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  legal_name text not null, phone text, email text, requested_property_id uuid references public.properties(id), requested_unit_id uuid references public.units(id),
  stage text not null default 'Lead', source text, follow_up_date date, notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.unit_listings (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  unit_id uuid not null references public.units(id) on delete cascade, status text not null default 'Draft', available_from date, asking_rent numeric(14,2) not null default 0,
  marketing_title text, description text, published_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(unit_id)
);
create table if not exists public.recurring_charges (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  lease_id uuid not null references public.leases(id) on delete cascade, charge_type text not null, description text, amount numeric(14,2) not null check(amount >= 0),
  start_date date not null, end_date date, due_day integer check(due_day between 1 and 31), status text not null default 'Active', created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.payment_arrangements (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  lease_id uuid not null references public.leases(id) on delete cascade, agreed_amount numeric(14,2) not null check(agreed_amount > 0), frequency text not null default 'Monthly', start_date date not null, end_date date,
  status text not null default 'Proposed', approved_by uuid references auth.users(id), notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.vendors (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  legal_name text not null, trade text, phone text, email text, payment_terms text, status text not null default 'Active', notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.work_order_quotes (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  work_order_id uuid not null references public.work_orders(id) on delete cascade, vendor_id uuid references public.vendors(id), quote_number text, quoted_amount numeric(14,2) not null default 0,
  quoted_date date, expiry_date date, status text not null default 'Requested', approved_by uuid references auth.users(id), notes text, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.vendor_bills (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  vendor_id uuid not null references public.vendors(id), property_id uuid references public.properties(id), work_order_id uuid references public.work_orders(id),
  bill_number text, bill_date date not null, due_date date, amount numeric(14,2) not null check(amount >= 0), paid_amount numeric(14,2) not null default 0 check(paid_amount >= 0), status text not null default 'Open', notes text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.inspection_items (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  inspection_id uuid not null references public.inspections(id) on delete cascade, area text not null, item_name text not null, result text not null default 'Not assessed',
  condition_score integer check(condition_score between 1 and 5), defect_description text, follow_up_work_order_id uuid references public.work_orders(id), evidence_path text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.calendar_events (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  property_id uuid references public.properties(id), lease_id uuid references public.leases(id), event_date date not null, event_type text not null, title text not null, notes text, status text not null default 'Open',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.communication_log (
  id uuid primary key default gen_random_uuid(), organization_id uuid not null references public.organizations(id) on delete cascade,
  contact_id uuid references public.contacts(id), lease_id uuid references public.leases(id), channel text not null, direction text not null default 'Outbound', subject text, body text, status text, sent_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);

-- Transitional browser-workspace backup. This is not the operating source of truth;
-- it keeps the free V10 browser edition safe while the screens are wired table by table.
create table if not exists public.mbm_workspace_backups (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  payload jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

-- Private document vault used for agreements, notices, supplier quotes and inspection evidence.
insert into storage.buckets (id, name, public) values ('mbm-private-documents', 'mbm-private-documents', false)
on conflict (id) do nothing;
drop policy if exists "MBM V10 private document read" on storage.objects;
create policy "MBM V10 private document read" on storage.objects for select to authenticated
using (bucket_id='mbm-private-documents' and (storage.foldername(name))[1]=auth.uid()::text);
drop policy if exists "MBM V10 private document upload" on storage.objects;
create policy "MBM V10 private document upload" on storage.objects for insert to authenticated
with check (bucket_id='mbm-private-documents' and (storage.foldername(name))[1]=auth.uid()::text);

create or replace function public.mbm_touch_updated_at() returns trigger language plpgsql security invoker set search_path = public as $$ begin new.updated_at = now(); return new; end; $$;
do $$ declare t text; begin
  foreach t in array array['organizations','properties','units','contacts','leases','lease_documents','renewal_cases','charges','payments','municipal_accounts','work_orders','inspections','tasks','property_owners','prospects','unit_listings','recurring_charges','payment_arrangements','vendors','work_order_quotes','vendor_bills','inspection_items','calendar_events','communication_log','mbm_workspace_backups'] loop
    execute format('drop trigger if exists mbm_touch_%1$s on public.%1$s', t);
    execute format('create trigger mbm_touch_%1$s before update on public.%1$s for each row execute function public.mbm_touch_updated_at()', t);
  end loop;
end $$;

-- Tenant/property data is never public. Every organization-scoped table inherits member-based access.
alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.mbm_workspace_backups enable row level security;
do $$ declare t text; begin
  foreach t in array array['properties','units','contacts','leases','lease_documents','renewal_cases','charges','payments','payment_allocations','municipal_accounts','work_orders','inspections','tasks','audit_log','property_owners','prospects','unit_listings','recurring_charges','payment_arrangements','vendors','work_order_quotes','vendor_bills','inspection_items','calendar_events','communication_log'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists mbm_read_%I on public.%I', t, t);
    execute format('drop policy if exists mbm_write_%I on public.%I', t, t);
    execute format('create policy mbm_read_%1$I on public.%1$I for select to authenticated using (public.mbm_is_member(organization_id))', t);
    execute format('create policy mbm_write_%1$I on public.%1$I for all to authenticated using (public.mbm_can_write(organization_id)) with check (public.mbm_can_write(organization_id))', t);
  end loop;
end $$;
drop policy if exists mbm_read_organizations on public.organizations;
create policy mbm_read_organizations on public.organizations for select to authenticated using (public.mbm_is_member(id));
drop policy if exists mbm_create_organizations on public.organizations;
create policy mbm_create_organizations on public.organizations for insert to authenticated with check (owner_id = auth.uid());
drop policy if exists mbm_read_members on public.organization_members;
create policy mbm_read_members on public.organization_members for select to authenticated using (public.mbm_is_member(organization_id));
drop policy if exists mbm_manage_members on public.organization_members;
create policy mbm_manage_members on public.organization_members for all to authenticated using (public.mbm_is_admin(organization_id)) with check (public.mbm_is_admin(organization_id));
drop policy if exists mbm_initial_owner_membership on public.organization_members;
create policy mbm_initial_owner_membership on public.organization_members for insert to authenticated
with check (
  user_id = auth.uid()
  and role = 'Administrator'
  and exists (select 1 from public.organizations o where o.id = organization_id and o.owner_id = auth.uid())
);

drop policy if exists mbm_read_workspace_backup on public.mbm_workspace_backups;
create policy mbm_read_workspace_backup on public.mbm_workspace_backups for select to authenticated using (owner_id = auth.uid());
drop policy if exists mbm_write_workspace_backup on public.mbm_workspace_backups;
create policy mbm_write_workspace_backup on public.mbm_workspace_backups for all to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid());

-- Call this once from the authenticated application to create the first MBM workspace safely.
create or replace function public.mbm_create_organization(p_name text)
returns uuid language plpgsql security definer set search_path = public as $$
declare new_id uuid;
begin
  if auth.uid() is null then raise exception 'An authenticated user is required'; end if;
  insert into public.organizations (name, owner_id) values (trim(p_name), auth.uid()) returning id into new_id;
  insert into public.organization_members (organization_id, user_id, role) values (new_id, auth.uid(), 'Administrator');
  return new_id;
end;
$$;
revoke all on function public.mbm_create_organization(text) from public;
grant execute on function public.mbm_create_organization(text) to authenticated;

-- Reporting view: safe only when queried through authenticated RLS-protected tables/views.
create or replace view public.v_mbm_property_summary with (security_invoker = true) as
select p.organization_id, p.id as property_id, p.code, p.name,
       count(distinct u.id) as total_units,
       count(distinct u.id) filter (where u.status = 'Occupied') as occupied_units,
       coalesce(sum(l.monthly_rent) filter (where l.status in ('Active','Signed','Renewal in progress')),0) as active_monthly_rent,
       coalesce(ma.current_balance,0) as municipal_balance
from public.properties p
left join public.units u on u.property_id = p.id
left join public.leases l on l.property_id = p.id
left join public.municipal_accounts ma on ma.property_id = p.id
group by p.organization_id,p.id,p.code,p.name,ma.current_balance;
