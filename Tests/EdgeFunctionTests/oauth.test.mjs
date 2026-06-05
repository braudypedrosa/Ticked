import assert from "node:assert/strict";
import test from "node:test";
import {
  assertOAuthState,
  buildBasecampConnectionRows,
  buildBasecampAuthorizeUrl,
  buildLinearAuthorizeUrl,
  buildTrelloAuthorizeUrl,
  tokenUpdateFromRefresh,
} from "../../supabase/functions/_shared/oauth.mjs";
import {
  htmlResponse,
  oauthCallbackFallbackResponse,
  oauthCallbackPage,
  redirectResponse,
} from "../../supabase/functions/_shared/http.mjs";

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
  assert.equal(url.searchParams.get("prompt"), null);
});

test("Linear OAuth URL can force consent for connecting another workspace", () => {
  const url = buildLinearAuthorizeUrl({
    clientId: "lin_client",
    redirectUri: "ticked://oauth/linear",
    state: "state-1",
    codeChallenge: "challenge",
    scopes: ["read"],
    prompt: "consent",
  });

  assert.equal(url.searchParams.get("prompt"), "consent");
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

test("Basecamp OAuth callback builds one connection row per Basecamp account", () => {
  const rows = buildBasecampConnectionRows("user-1", [
    {
      product: "bc3",
      id: 101,
      name: "Client One",
      href: "https://3.basecampapi.com/101",
    },
    {
      product: "bc3",
      id: 202,
      name: "Client Two",
      href: "https://3.basecampapi.com/202",
    },
    {
      product: "highrise",
      id: 303,
      name: "Ignored",
      href: "https://example.com",
    },
  ]);

  assert.deepEqual(rows.map((row) => row.external_account_id), ["101", "202"]);
  assert.deepEqual(rows.map((row) => row.account_label), ["Client One", "Client Two"]);
  assert.equal(rows[0].provider, "basecamp");
  assert.deepEqual(rows[0].scopes, ["read"]);
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

test("OAuth callback page renders a branded success state", () => {
  const html = oauthCallbackPage({
    title: "Linear connected",
    message: "Your account is linked. You can close this window and return to Ticked.",
  });

  assert.match(html, /<!doctype html>/);
  assert.match(html, /Linear connected/);
  assert.match(html, /Close Window/);
  assert.doesNotMatch(html, /<h1>Connected<\/h1><p>/);
});

test("HTML responses declare browser-renderable content type", () => {
  const response = htmlResponse(oauthCallbackPage());

  assert.equal(response.headers.get("content-type"), "text/html; charset=utf-8");
  assert.match(response.headers.get("content-security-policy"), /style-src 'unsafe-inline'/);
});

test("OAuth fallback uses plain text on the default Supabase functions domain", async () => {
  const response = oauthCallbackFallbackResponse({
    title: "Connection incomplete",
    message: "Try connecting again from Ticked.",
  }, "https://project.supabase.co/functions/v1/oauth-callback");
  const body = await response.text();

  assert.equal(response.headers.get("content-type"), "text/plain; charset=utf-8");
  assert.match(body, /Ticked\n\nConnection incomplete/);
  assert.doesNotMatch(body, /<html/);
});

test("OAuth result redirects can open Ticked after the server callback finishes", () => {
  const response = redirectResponse("ticked://oauth-result?provider=linear&status=connected");

  assert.equal(response.status, 302);
  assert.equal(response.headers.get("location"), "ticked://oauth-result?provider=linear&status=connected");
});

test("OAuth callback page escapes failure details", () => {
  const html = oauthCallbackPage({
    tone: "error",
    title: "Connection failed",
    message: "Could not connect.",
    detail: "<script>alert('x')</script>",
  });

  assert.match(html, /&lt;script&gt;alert/);
  assert.doesNotMatch(html, /<script>alert/);
});
