import assert from "node:assert/strict";
import test from "node:test";
import {
  assertOAuthState,
  buildBasecampAuthorizeUrl,
  buildLinearAuthorizeUrl,
  buildTrelloAuthorizeUrl,
  tokenUpdateFromRefresh,
} from "../../supabase/functions/_shared/oauth.mjs";

test("assertOAuthState rejects missing or mismatched callback state", () => {
  assert.throws(() => assertOAuthState("expected", ""), /Missing OAuth state/);
  assert.throws(() => assertOAuthState("expected", "actual"), /OAuth state mismatch/);
  assert.doesNotThrow(() => assertOAuthState("expected", "expected"));
});

test("Linear OAuth URL uses PKCE and comma-separated read scope", () => {
  const url = buildLinearAuthorizeUrl({
    clientId: "lin_client",
    redirectUri: "efficiency://oauth/linear",
    state: "state-1",
    codeChallenge: "challenge",
    scopes: ["read"],
  });

  assert.equal(url.origin, "https://linear.app");
  assert.equal(url.pathname, "/oauth/authorize");
  assert.equal(url.searchParams.get("response_type"), "code");
  assert.equal(url.searchParams.get("scope"), "read");
  assert.equal(url.searchParams.get("code_challenge_method"), "S256");
});

test("Basecamp OAuth URL targets Launchpad web server flow", () => {
  const url = buildBasecampAuthorizeUrl({
    clientId: "bc_client",
    redirectUri: "https://project.supabase.co/functions/v1/oauth-callback",
    state: "state-2",
  });

  assert.equal(url.origin, "https://launchpad.37signals.com");
  assert.equal(url.pathname, "/authorization/new");
  assert.equal(url.searchParams.get("type"), "web_server");
  assert.equal(url.searchParams.get("state"), "state-2");
});

test("Trello authorization URL requests a durable read token", () => {
  const url = buildTrelloAuthorizeUrl({
    appName: "Ticked",
    apiKey: "trello_key",
    returnUrl: "efficiency://oauth/trello",
  });

  assert.equal(url.origin, "https://trello.com");
  assert.equal(url.pathname, "/1/authorize");
  assert.equal(url.searchParams.get("expiration"), "never");
  assert.equal(url.searchParams.get("scope"), "read");
  assert.equal(url.searchParams.get("response_type"), "token");
  assert.equal(url.searchParams.get("callback_method"), "fragment");
});

test("tokenUpdateFromRefresh rotates refresh tokens when provider returns one", () => {
  const update = tokenUpdateFromRefresh(
    { refresh_token: "old_refresh" },
    { access_token: "new_access", refresh_token: "new_refresh", expires_in: 86400 },
    new Date("2026-06-05T00:00:00Z")
  );

  assert.equal(update.access_token, "new_access");
  assert.equal(update.refresh_token, "new_refresh");
  assert.equal(update.expires_at, "2026-06-06T00:00:00.000Z");
});

