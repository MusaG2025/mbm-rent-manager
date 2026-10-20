-- MBM V15 upgrade: run once in Supabase SQL Editor.
-- Safe if an earlier MBM schema is already installed.

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
