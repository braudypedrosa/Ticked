create or replace function public.ticked_read_vault_secret(p_secret_name text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  secret_value text;
begin
  if auth.role() <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;

  select decrypted_secret
    into secret_value
  from vault.decrypted_secrets
  where name = p_secret_name;

  return secret_value;
end;
$$;

create or replace function public.ticked_upsert_integration_token(
  p_connection_id uuid,
  p_access_token text,
  p_refresh_token text,
  p_expires_at timestamptz,
  p_token_type text,
  p_raw_token jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.role() <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;

  insert into private.integration_tokens (
    connection_id,
    access_token,
    refresh_token,
    expires_at,
    token_type,
    raw_token,
    updated_at
  ) values (
    p_connection_id,
    p_access_token,
    p_refresh_token,
    p_expires_at,
    p_token_type,
    p_raw_token,
    now()
  )
  on conflict (connection_id) do update set
    access_token = excluded.access_token,
    refresh_token = excluded.refresh_token,
    expires_at = excluded.expires_at,
    token_type = excluded.token_type,
    raw_token = excluded.raw_token,
    updated_at = now();
end;
$$;

create or replace function public.ticked_get_integration_token(p_connection_id uuid)
returns table (
  connection_id uuid,
  access_token text,
  refresh_token text,
  expires_at timestamptz,
  token_type text,
  raw_token jsonb,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.role() <> 'service_role' then
    raise exception 'service role required' using errcode = '42501';
  end if;

  return query
  select
    t.connection_id,
    t.access_token,
    t.refresh_token,
    t.expires_at,
    t.token_type,
    t.raw_token,
    t.updated_at
  from private.integration_tokens as t
  where t.connection_id = p_connection_id;
end;
$$;

revoke all on function public.ticked_read_vault_secret(text) from public, anon, authenticated;
revoke all on function public.ticked_upsert_integration_token(uuid, text, text, timestamptz, text, jsonb) from public, anon, authenticated;
revoke all on function public.ticked_get_integration_token(uuid) from public, anon, authenticated;

grant execute on function public.ticked_read_vault_secret(text) to service_role;
grant execute on function public.ticked_upsert_integration_token(uuid, text, text, timestamptz, text, jsonb) to service_role;
grant execute on function public.ticked_get_integration_token(uuid) to service_role;
