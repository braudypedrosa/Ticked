# Ticked

SwiftUI macOS todo app backed by Supabase. It imports assigned tasks from Linear, Basecamp, and Trello into a local-completion todo inbox with List/Card views.

Ticked supports multiple connections per provider. Linear uses OAuth consent on
each connect attempt so another workspace can be selected, and Basecamp stores
one connection per Basecamp account returned by Launchpad authorization.

## Local App

Set runtime values before launching:

```bash
export TICKED_SUPABASE_URL="https://ttsrdfkihbuhkeezprwe.supabase.co"
export TICKED_SUPABASE_PUBLISHABLE_KEY="sb_publishable_EqjNNixWGshcZyF9ysKwOw_n3jstz8j"
```

Run from Codex with the `Run` action, or from the terminal:

```bash
./script/build_and_run.sh
```

The generated app bundle registers `ticked://` for Supabase magic-link and Trello callback handling.

The project-local run script also sources `.env` automatically.

## Supabase

The repo includes:

- `supabase/migrations/20260605153000_init_ticked.sql`
- Edge Functions in `supabase/functions/*`
- `.env.example` with required app and provider credentials

After creating the Supabase project, replace the placeholder Vault secrets created by the migration:

- `ticked_project_url`
- `ticked_anon_key`

Then deploy functions with Supabase CLI once installed and authenticated.

Provider OAuth credentials can be configured as Supabase Edge Function
environment variables or as Supabase Vault secrets. Ticked checks Edge Function
env vars first, then the Vault names in parentheses:

- `LINEAR_CLIENT_ID` (`linear_client_id`)
- `LINEAR_CLIENT_SECRET` (`linear_client_secret`)
- `BASECAMP_CLIENT_ID` (`basecamp_client_id`)
- `BASECAMP_CLIENT_SECRET` (`basecamp_client_secret`)
- `TRELLO_API_KEY` (`trello_api_key`)
- `TICKED_TRELLO_RETURN_URL=ticked://oauth/trello` (`ticked_trello_return_url`)

## Verification

```bash
swift test
npm run test:edge
./script/build_and_run.sh --verify
```
