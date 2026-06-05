import { serviceClient } from "../_shared/supabase_client.ts";
import { errorMessage } from "../_shared/errors.ts";
import { providerSecret, requiredProviderSecret } from "../_shared/provider_config.ts";
// @ts-ignore JS module shared with Node tests.
import { assertOAuthState, buildBasecampConnectionRows } from "../_shared/oauth.mjs";
// @ts-ignore JS module shared with Node tests.
import { oauthCallbackFallbackResponse, optionsResponse, redirectResponse } from "../_shared/http.mjs";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return optionsResponse();

  const service = serviceClient();
  const url = new URL(req.url);
  const provider = url.searchParams.get("provider");
  const code = url.searchParams.get("code");
  const state = url.searchParams.get("state");

  try {
    if (!provider || !code || !state) {
      return oauthCallbackFallbackResponse({
        tone: "error",
        title: "Connection incomplete",
        message: "The authorization response was missing required data. Try connecting again from Ticked.",
      }, req.url);
    }

    const { data: oauthState, error: stateError } = await service
      .from("oauth_states")
      .select("*")
      .eq("state", state)
      .single();
    if (stateError) throw stateError;

    assertOAuthState(oauthState.state, state);
    if (oauthState.provider !== provider || oauthState.status !== "pending" || new Date(oauthState.expires_at) < new Date()) {
      throw new Error("OAuth state is no longer valid");
    }

    if (provider === "linear") {
      await completeLinearOAuth(service, oauthState, code);
    } else if (provider === "basecamp") {
      await completeBasecampOAuth(service, oauthState, code);
    } else {
      throw new Error("Unsupported OAuth callback provider");
    }

    await service.from("oauth_states").update({ status: "completed" }).eq("id", oauthState.id);
    return redirectResponse(oauthResultURL(provider, "connected"));
  } catch (error) {
    if (state) {
      await service.from("oauth_states").update({ status: "failed" }).eq("state", state);
    }
    if (provider) {
      return redirectResponse(oauthResultURL(provider, "failed"));
    }
    return oauthCallbackFallbackResponse({
      tone: "error",
      title: "Connection failed",
      message: "Ticked could not finish linking this account.",
      detail: errorMessage(error),
    }, req.url);
  }
});

function oauthResultURL(provider: string, status: "connected" | "failed"): string {
  const url = new URL("ticked://oauth-result");
  url.searchParams.set("provider", provider);
  url.searchParams.set("status", status);
  return url.toString();
}

async function completeLinearOAuth(service: any, oauthState: any, code: string) {
  const body = new URLSearchParams({
    grant_type: "authorization_code",
    code,
    redirect_uri: oauthState.redirect_uri,
    client_id: await requiredProviderSecret("LINEAR_CLIENT_ID"),
    code_verifier: oauthState.code_verifier,
  });
  const clientSecret = await providerSecret("LINEAR_CLIENT_SECRET");
  if (clientSecret) body.set("client_secret", clientSecret);

  const token = await exchangeToken("https://api.linear.app/oauth/token", body);
  const account = await fetchLinearAccount(token.access_token);
  const { data: connection, error } = await service
    .from("integration_connections")
    .upsert({
      user_id: oauthState.user_id,
      provider: "linear",
      account_label: account.name,
      external_account_id: account.id,
      external_account_url: account.url,
      status: "active",
      scopes: ["read"],
    }, { onConflict: "user_id,provider,external_account_id" })
    .select()
    .single();
  if (error) throw error;

  await storeToken(service, connection.id, token);
}

async function completeBasecampOAuth(service: any, oauthState: any, code: string) {
  const body = new URLSearchParams({
    type: "web_server",
    code,
    redirect_uri: oauthState.redirect_uri,
    client_id: await requiredProviderSecret("BASECAMP_CLIENT_ID"),
    client_secret: await requiredProviderSecret("BASECAMP_CLIENT_SECRET"),
  });

  const token = await exchangeToken("https://launchpad.37signals.com/authorization/token", body);
  const accounts = await fetchBasecampAccounts(token.access_token);
  const rows = buildBasecampConnectionRows(oauthState.user_id, accounts);
  if (!rows.length) throw new Error("Basecamp did not return a Basecamp account");

  const { data: connections, error } = await service
    .from("integration_connections")
    .upsert(rows, { onConflict: "user_id,provider,external_account_id" })
    .select();
  if (error) throw error;

  for (const connection of connections ?? []) {
    await storeToken(service, connection.id, token);
  }
}

async function exchangeToken(endpoint: string, body: URLSearchParams): Promise<Record<string, any>> {
  const response = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
  });
  if (!response.ok) {
    throw new Error(`Token exchange failed: ${response.status}`);
  }
  return await response.json();
}

async function fetchBasecampAccounts(accessToken: string): Promise<any[]> {
  const response = await fetch("https://launchpad.37signals.com/authorization.json", {
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
      "User-Agent": "Ticked (braudy@sessionwise.com)",
    },
  });
  if (!response.ok) throw new Error(`Basecamp account lookup failed: ${response.status}`);
  const body = await response.json();
  return body.accounts ?? [];
}

async function fetchLinearAccount(accessToken: string): Promise<{ id: string; name: string; url: string | null }> {
  const response = await fetch("https://api.linear.app/graphql", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      query: `query TickedLinearAccount {
        organization { id name urlKey }
      }`,
    }),
  });
  if (!response.ok) throw new Error(`Linear account lookup failed: ${response.status}`);

  const body = await response.json();
  const organization = body?.data?.organization;
  if (!organization?.id) {
    throw new Error("Linear did not return an organization");
  }

  return {
    id: organization.id,
    name: organization.name ?? "Linear",
    url: organization.urlKey ? `https://linear.app/${organization.urlKey}` : null,
  };
}

async function storeToken(service: any, connectionID: string, token: Record<string, any>) {
  const expiresIn = Number(token.expires_in ?? 0);
  const expiresAt = expiresIn > 0 ? new Date(Date.now() + expiresIn * 1000).toISOString() : null;
  const { error } = await service.rpc("ticked_upsert_integration_token", {
    p_connection_id: connectionID,
    p_access_token: token.access_token,
    p_refresh_token: token.refresh_token ?? null,
    p_expires_at: expiresAt,
    p_token_type: token.token_type ?? "bearer",
    p_raw_token: token,
  });
  if (error) throw error;
}
