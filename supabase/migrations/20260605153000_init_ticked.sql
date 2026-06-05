create extension if not exists pgcrypto;
create extension if not exists pg_cron;
create extension if not exists pg_net;
create extension if not exists supabase_vault with schema vault;

create schema if not exists private;

create type public.integration_provider as enum ('linear', 'basecamp', 'trello');
create type public.connection_status as enum ('active', 'needs_reauth', 'disabled');
create type public.sync_status as enum ('running', 'succeeded', 'failed');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.integration_connections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider public.integration_provider not null,
  account_label text not null,
  external_account_id text,
  external_account_url text,
  status public.connection_status not null default 'active',
  scopes text[] not null default '{}',
  last_synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.todos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  connection_id uuid not null references public.integration_connections(id) on delete cascade,
  provider public.integration_provider not null,
  external_id text not null,
  source_key text,
  title text not null,
  external_url text,
  source_name text,
  due_at timestamptz,
  first_seen_at timestamptz not null default now(),
  last_synced_at timestamptz not null default now(),
  local_completed_at timestamptz,
  raw_metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (connection_id, external_id)
);

create table public.sync_runs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  connection_id uuid references public.integration_connections(id) on delete cascade,
  status public.sync_status not null,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  imported_count integer not null default 0,
  error text,
  created_at timestamptz not null default now()
);

create table public.sync_cursors (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references public.integration_connections(id) on delete cascade,
  cursor_key text not null,
  cursor_value text not null,
  updated_at timestamptz not null default now(),
  unique (connection_id, cursor_key)
);

create table public.oauth_states (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  provider public.integration_provider not null,
  state text not null unique,
  redirect_uri text not null,
  code_verifier text,
  status text not null default 'pending',
  expires_at timestamptz not null default (now() + interval '10 minutes'),
  created_at timestamptz not null default now()
);

create table private.integration_tokens (
  connection_id uuid primary key references public.integration_connections(id) on delete cascade,
  access_token text not null,
  refresh_token text,
  expires_at timestamptz,
  token_type text,
  raw_token jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create index integration_connections_user_provider_idx on public.integration_connections(user_id, provider);
create index todos_user_provider_due_idx on public.todos(user_id, provider, due_at);
create index todos_connection_external_idx on public.todos(connection_id, external_id);
create index sync_runs_user_started_idx on public.sync_runs(user_id, started_at desc);
create index oauth_states_state_idx on public.oauth_states(state);

alter table public.profiles enable row level security;
alter table public.integration_connections enable row level security;
alter table public.todos enable row level security;
alter table public.sync_runs enable row level security;
alter table public.sync_cursors enable row level security;
alter table public.oauth_states enable row level security;
alter table private.integration_tokens enable row level security;

create policy "profiles_select_own" on public.profiles
  for select to authenticated using (id = auth.uid());
create policy "profiles_update_own" on public.profiles
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy "connections_select_own" on public.integration_connections
  for select to authenticated using (user_id = auth.uid());
create policy "connections_update_own_non_sensitive" on public.integration_connections
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "todos_select_own" on public.todos
  for select to authenticated using (user_id = auth.uid());
create policy "todos_update_local_completion_own" on public.todos
  for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy "sync_runs_select_own" on public.sync_runs
  for select to authenticated using (user_id = auth.uid());

create policy "sync_cursors_select_own_connection" on public.sync_cursors
  for select to authenticated using (
    exists (
      select 1 from public.integration_connections c
      where c.id = sync_cursors.connection_id and c.user_id = auth.uid()
    )
  );

create policy "oauth_states_select_own" on public.oauth_states
  for select to authenticated using (user_id = auth.uid());
create policy "oauth_states_insert_own" on public.oauth_states
  for insert to authenticated with check (user_id = auth.uid());

create policy "private_tokens_service_role_only" on private.integration_tokens
  for all to service_role using (true) with check (true);

grant usage on schema public to anon, authenticated;
grant select on public.profiles to authenticated;
grant select, update on public.integration_connections to authenticated;
grant select, update on public.todos to authenticated;
grant select on public.sync_runs to authenticated;
grant select on public.sync_cursors to authenticated;
grant select, insert on public.oauth_states to authenticated;
grant all on all tables in schema public to service_role;
grant usage on schema private to service_role;
grant all on all tables in schema private to service_role;

revoke all on schema private from anon, authenticated;
revoke all on all tables in schema private from anon, authenticated;

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function public.touch_updated_at();

create trigger connections_touch_updated_at
before update on public.integration_connections
for each row execute function public.touch_updated_at();

create trigger todos_touch_updated_at
before update on public.todos
for each row execute function public.touch_updated_at();

select vault.create_secret('https://ttsrdfkihbuhkeezprwe.supabase.co', 'ticked_project_url')
where not exists (select 1 from vault.secrets where name = 'ticked_project_url');

select vault.create_secret('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR0c3JkZmtpaGJ1aGtlZXpwcndlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA2NjgwNjUsImV4cCI6MjA5NjI0NDA2NX0.JeZIRIBSb5nyXwGzd5AJGAedwYW8-Df4ZcA5yMWpQl8', 'ticked_anon_key')
where not exists (select 1 from vault.secrets where name = 'ticked_anon_key');

select cron.schedule(
  'ticked-daily-sync',
  '15 8 * * *',
  $$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name = 'ticked_project_url') || '/functions/v1/sync-all',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || (select decrypted_secret from vault.decrypted_secrets where name = 'ticked_anon_key')
    ),
    body := '{}'::jsonb
  ) as request_id;
  $$
);
