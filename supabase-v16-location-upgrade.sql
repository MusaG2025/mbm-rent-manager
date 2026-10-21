-- MBM V16: property Smart Location fields.
-- Safe for an existing database: no existing records are deleted or changed.

alter table public.properties
  add column if not exists locality text,
  add column if not exists country text,
  add column if not exists latitude numeric(10,7),
  add column if not exists longitude numeric(10,7),
  add column if not exists location_source text,
  add column if not exists location_accuracy_m numeric(10,2),
  add column if not exists location_verified_at timestamptz;

comment on column public.properties.latitude is 'Property GPS latitude captured from verified map pin, address search or device GPS.';
comment on column public.properties.longitude is 'Property GPS longitude captured from verified map pin, address search or device GPS.';
