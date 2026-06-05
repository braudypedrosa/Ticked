select vault.create_secret(
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR0c3JkZmtpaGJ1aGtlZXpwcndlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA2NjgwNjUsImV4cCI6MjA5NjI0NDA2NX0.JeZIRIBSb5nyXwGzd5AJGAedwYW8-Df4ZcA5yMWpQl8',
  'ticked_anon_key'
)
where not exists (select 1 from vault.secrets where name = 'ticked_anon_key');

select cron.unschedule('ticked-daily-sync');

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
