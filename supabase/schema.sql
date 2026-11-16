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
-- 6. Table des Run Logs de combat & Bugs IA
-- ============================================================
create table if not exists public.combat_run_logs (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid references auth.users(id) on delete set null,
  user_email     text,
  hero           text not null,
  enemy_key      text,
  enemy_name     text not null,
  enemy_rank     text,
  mode           text,
  outcome        text,
  has_ai_bug     boolean not null default false,
  deselect_count integer not null default 0,
  is_archived    boolean not null default false,
  run_log_json   jsonb not null,
  created_at     timestamptz not null default now()
);

alter table public.combat_run_logs
  add column if not exists is_archived boolean not null default false;

create index if not exists combat_run_logs_bug_created_idx
  on public.combat_run_logs (has_ai_bug, created_at desc);

alter table public.combat_run_logs enable row level security;

drop policy if exists "anyone_insert_combat_run_logs" on public.combat_run_logs;
create policy "anyone_insert_combat_run_logs"
  on public.combat_run_logs
  for insert
  to authenticated, anon
  with check (user_id is null or auth.uid() = user_id);

drop policy if exists "admin_or_owner_select_combat_run_logs" on public.combat_run_logs;
create policy "admin_or_owner_select_combat_run_logs"
  on public.combat_run_logs
  for select
  to authenticated
  using (
    (auth.jwt() ->> 'email') = 'bdewev18@gmail.com'
    or auth.uid() = user_id
  );

drop policy if exists "admin_update_combat_run_logs" on public.combat_run_logs;
create policy "admin_update_combat_run_logs"
  on public.combat_run_logs
  for update
  to authenticated
  using ((auth.jwt() ->> 'email') = 'bdewev18@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'bdewev18@gmail.com');

-- ============================================================
-- 7. Table des propositions d'ennemis de la communauté
-- ============================================================
create table if not exists public.community_enemy_proposals (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid references auth.users(id) on delete set null,
  user_email     text not null,
  enemy_type     text not null check (enemy_type in ('minion', 'boss')),
  minion_rank    text,
  name           text not null,
  description    text,
  image_mode     text not null default 'link',
  image_value    text,
  hp             integer,
  cp             integer,
  cp_infinite    boolean not null default false,
  attacks_text   text,
  passives_text  text,
  defense_text   text,
  status         text not null default 'pending' check (status in ('pending', 'accepted', 'rejected')),
  created_at     timestamptz not null default now()
);

create index if not exists community_enemy_proposals_type_created_idx
  on public.community_enemy_proposals (enemy_type, created_at desc);

alter table public.community_enemy_proposals enable row level security;

drop policy if exists "authenticated_insert_community_proposals" on public.community_enemy_proposals;
create policy "authenticated_insert_community_proposals"
  on public.community_enemy_proposals
  for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and coalesce(auth.jwt() ->> 'email', '') <> ''
  );

drop policy if exists "admin_or_owner_select_community_proposals" on public.community_enemy_proposals;
create policy "admin_or_owner_select_community_proposals"
  on public.community_enemy_proposals
  for select
  to authenticated
  using (
    (auth.jwt() ->> 'email') = 'bdewev18@gmail.com'
    or auth.uid() = user_id
  );

drop policy if exists "admin_update_community_proposals" on public.community_enemy_proposals;
create policy "admin_update_community_proposals"
  on public.community_enemy_proposals
  for update
  to authenticated
  using ((auth.jwt() ->> 'email') = 'bdewev18@gmail.com')
  with check ((auth.jwt() ->> 'email') = 'bdewev18@gmail.com');

-- ============================================================
-- NOTES
-- - RLS = Row Level Security : même avec la anon key publique,
--   un visiteur ne peut pas lire/écrire les records d'un autre user.
-- - auth.uid() renvoie l'id de la session courante.
-- - La colonne user_id doit TOUJOURS valoir l'id du user connecté
--   (vérifié côté policy + côté app via .eq('user_id', uid)).
-- ============================================================


-- ============================================================
-- 8. Profils Joueurs, Classement Communauté & Clans
-- ============================================================
alter table public.game_records
  add column if not exists boss_key text;

create table if not exists public.player_profiles (
  user_id       uuid primary key references auth.users(id) on delete cascade,
  pseudo        text not null default '',
  generic_id    text not null default '',
  country_code  text not null default 'FR',
  favorite_hero text not null default 'barbare',
  share_stats   boolean not null default true,
  updated_at    timestamptz not null default now()
);

alter table public.player_profiles enable row level security;

drop policy if exists "anyone_select_public_profiles" on public.player_profiles;
create policy "anyone_select_public_profiles"
  on public.player_profiles
  for select
  to authenticated, anon
  using (share_stats = true or auth.uid() = user_id);

drop policy if exists "users_upsert_own_profile" on public.player_profiles;
create policy "users_upsert_own_profile"
  on public.player_profiles
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "users_update_own_profile" on public.player_profiles;
create policy "users_update_own_profile"
  on public.player_profiles
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Permettre la lecture des records des joueurs qui ont activé share_stats
drop policy if exists "anyone_select_shared_game_records" on public.game_records;
create policy "anyone_select_shared_game_records"
  on public.game_records
  for select
  to authenticated, anon
  using (
    auth.uid() = user_id
    or exists (
      select 1 from public.player_profiles p
      where p.user_id = game_records.user_id
        and p.share_stats = true
    )
  );

-- Table des Clans (Groupes de joueurs)
create table if not exists public.clans (
  id            text primary key,
  name          text not null,
  owner_id      uuid not null references auth.users(id) on delete cascade,
  owner_pseudo  text not null default '',
  created_at    timestamptz not null default now()
);

alter table public.clans enable row level security;

drop policy if exists "anyone_select_clans" on public.clans;
create policy "anyone_select_clans"
  on public.clans
  for select
  to authenticated, anon
  using (true);

drop policy if exists "authenticated_insert_clans" on public.clans;
create policy "authenticated_insert_clans"
  on public.clans
  for insert
  to authenticated
  with check (auth.uid() = owner_id);

drop policy if exists "owner_update_clans" on public.clans;
create policy "owner_update_clans"
  on public.clans
  for update
  to authenticated
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- Table des membres de Clans (avec statut pending / approved / rejected)
create table if not exists public.clan_members (
  id            uuid primary key default gen_random_uuid(),
  clan_id       text not null references public.clans(id) on delete cascade,
  user_id       uuid not null references auth.users(id) on delete cascade,
  pseudo        text not null default '',
  country_code  text not null default 'FR',
  favorite_hero text not null default 'barbare',
  status        text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  role          text not null default 'member' check (role in ('admin', 'member')),
  created_at    timestamptz not null default now(),
  unique (clan_id, user_id)
);

create index if not exists clan_members_clan_id_idx
  on public.clan_members (clan_id, status);

create index if not exists clan_members_user_id_idx
  on public.clan_members (user_id);

alter table public.clan_members enable row level security;

drop policy if exists "anyone_select_clan_members" on public.clan_members;
create policy "anyone_select_clan_members"
  on public.clan_members
  for select
  to authenticated, anon
  using (true);

drop policy if exists "users_insert_own_clan_membership" on public.clan_members;
create policy "users_insert_own_clan_membership"
  on public.clan_members
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "user_or_admin_update_clan_membership" on public.clan_members;
create policy "user_or_admin_update_clan_membership"
  on public.clan_members
  for update
  to authenticated
  using (
    auth.uid() = user_id
    or exists (
      select 1 from public.clans c
      where c.id = clan_members.clan_id
        and c.owner_id = auth.uid()
    )
  );

drop policy if exists "user_or_admin_delete_clan_membership" on public.clan_members;
create policy "user_or_admin_delete_clan_membership"
  on public.clan_members
  for delete
  to authenticated
  using (
    auth.uid() = user_id
    or exists (
      select 1 from public.clans c
      where c.id = clan_members.clan_id
        and c.owner_id = auth.uid()
    )
  );
