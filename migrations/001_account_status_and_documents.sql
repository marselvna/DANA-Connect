-- ============================================================
-- Migration 001: Account statuses + document versions + consent log
-- Week 1, Day 1-2 (19-20 Aug 2026)
-- Run this entire block in the Supabase SQL Editor.
-- Idempotent: safe to re-run.
-- ============================================================

set search_path = public;

-- ============================================================
-- 1. ACCOUNT STATUS on profiles
-- ============================================================
-- Statuses: pending, active, paused (mentor "stop-intake" only),
-- suspended (admin action), deactivated (self or admin closed)

alter table public.profiles
add column if not exists account_status text
  default 'pending'
  check (account_status in ('pending', 'active', 'paused', 'suspended', 'deactivated'));

alter table public.profiles
add column if not exists rejection_reason text;

alter table public.profiles
add column if not exists reviewed_by uuid references public.profiles(id);

alter table public.profiles
add column if not exists reviewed_at timestamptz;

-- Existing users already have full access today — do not lock them out.
-- Backfill anyone created before this migration as 'active'.
update public.profiles
set account_status = 'active'
where account_status = 'pending'
  and created_at < now();

-- ============================================================
-- 2. PLATFORM DOCUMENTS (versioned)
-- ============================================================

create table if not exists public.platform_documents (
  id uuid default gen_random_uuid() primary key,
  doc_type text not null check (doc_type in (
    'terms_of_service',
    'privacy_policy',
    'code_of_conduct',
    'mentor_agreement',
    'mentor_nda',
    'marketing_consent'
  )),
  version text not null,
  title text not null,
  body_url text,
  body_text text,
  applies_to_role text check (applies_to_role in ('mentor', 'mentee', 'all')) default 'all',
  is_active boolean default true,
  created_at timestamptz default now(),
  unique (doc_type, version)
);

-- Only one active version per doc_type at a time.
create unique index if not exists platform_documents_one_active_per_type
  on public.platform_documents (doc_type)
  where is_active;

-- ============================================================
-- 3. CONSENT LOG (audit trail)
-- ============================================================

create table if not exists public.user_consents (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  document_id uuid references public.platform_documents(id) not null,
  doc_type text not null,
  version text not null,
  method text default 'checkbox',
  signed_at timestamptz default now(),
  unique (user_id, document_id)
);

create index if not exists user_consents_user_idx on public.user_consents(user_id);

-- ============================================================
-- TRIGGERS
-- ============================================================

alter table public.platform_documents
add column if not exists updated_at timestamptz default now();

do $$
begin
  if not exists (
    select 1 from pg_trigger where tgname = 'platform_documents_updated_at'
  ) then
    create trigger platform_documents_updated_at
      before update on public.platform_documents
      for each row execute function update_updated_at();
  end if;
end $$;

-- ============================================================
-- 4. ROW LEVEL SECURITY
-- ============================================================

alter table public.platform_documents enable row level security;
alter table public.user_consents enable row level security;

-- Anyone (incl. anon, for the register page) can read active documents.
drop policy if exists "public_read_active_documents" on public.platform_documents;
create policy "public_read_active_documents" on public.platform_documents
  for select using (is_active = true);

-- Users can read + insert their own consent records; no update/delete
-- (consent log is append-only — re-consenting on a new version inserts a new row).
drop policy if exists "user_read_own_consents" on public.user_consents;
create policy "user_read_own_consents" on public.user_consents
  for select using (user_id = auth.uid());

drop policy if exists "user_insert_own_consents" on public.user_consents;
create policy "user_insert_own_consents" on public.user_consents
  for insert with check (user_id = auth.uid());

-- ============================================================
-- 5. SEED: initial document versions (placeholder text — replace
-- body_text/body_url with real legal copy before go-live)
-- ============================================================

insert into public.platform_documents (doc_type, version, title, applies_to_role, body_text)
values
  ('terms_of_service', '1.0', 'Пользовательское соглашение', 'all', 'TODO: заменить на реальный текст.'),
  ('privacy_policy', '1.0', 'Согласие на обработку персональных данных', 'all', 'TODO: заменить на реальный текст.'),
  ('code_of_conduct', '1.0', 'Кодекс поведения и этики платформы', 'all', 'TODO: заменить на реальный текст.'),
  ('mentor_agreement', '1.0', 'Соглашение об участии в программе наставничества', 'mentor', 'TODO: заменить на реальный текст.'),
  ('mentor_nda', '1.0', 'Соглашение о конфиденциальности (NDA)', 'mentor', 'TODO: заменить на реальный текст.')
on conflict (doc_type, version) do nothing;