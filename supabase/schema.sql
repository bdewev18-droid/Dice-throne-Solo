-- ============================================================
-- Dice Throne Solo — Historique des parties (phase 1)
-- À exécuter dans Supabase : SQL Editor → New query → Run
-- ============================================================

-- 1. Table des records de parties
create table if not exists public.game_records (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  hero          text not null,                       -- HeroType.name
  mode          text not null,                       -- SurvivalMode.name
  score         integer not null default 0,
  enemies_defeated integer not null default 0,
  health_remaining integer,                          -- nullable (pv héros restants)
  boss_health_remaining integer,                     -- nullable (pv boss restants)
  duration_ms   bigint not null default 0,           -- Duration en millisecondes
  is_victory    boolean not null default false,
  played_at     timestamptz not null default now(), -- date de la partie
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- 2. Index pour filtrer/trier par user + date
create index if not exists game_records_user_played_at_idx
  on public.game_records (user_id, played_at desc);

-- 3. Active Row Level Security sur la table
alter table public.game_records enable row level security;

-- 4. Policies : un user ne voit et n'écrit QUE ses propres records
-- (idempotent : on drop d'abord pour pouvoir relancer le script sans erreur)
drop policy if exists "users_select_own_records" on public.game_records;
create policy "users_select_own_records"
  on public.game_records
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "users_insert_own_records" on public.game_records;
create policy "users_insert_own_records"
  on public.game_records
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "users_update_own_records" on public.game_records;
create policy "users_update_own_records"
  on public.game_records
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "users_delete_own_records" on public.game_records;
create policy "users_delete_own_records"
  on public.game_records
  for delete
  to authenticated
  using (auth.uid() = user_id);

-- 5. Trigger : met à jour updated_at automatiquement
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists game_records_set_updated_at on public.game_records;
create trigger game_records_set_updated_at
  before update on public.game_records
  for each row
  execute function public.set_updated_at();

-- ============================================================
-- NOTES
-- - RLS = Row Level Security : même avec la anon key publique,
--   un visiteur ne peut pas lire/écrire les records d'un autre user.
-- - auth.uid() renvoie l'id de la session courante.
-- - La colonne user_id doit TOUJOURS valoir l'id du user connecté
--   (vérifié côté policy + côté app via .eq('user_id', uid)).
-- ============================================================
