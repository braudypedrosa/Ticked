import { requireUser } from "../_shared/supabase_client.ts";
import { errorMessage, requiredEnv } from "../_shared/errors.ts";
import { providerSecret, requiredProviderSecret } from "../_shared/provider_config.ts";
// @ts-ignore JS module shared with Node tests.
import { buildBasecampAuthorizeUrl, buildLinearAuthorizeUrl, buildTrelloAuthorizeUrl, pkceChallenge, randomState } from "../_shared/oauth.mjs";
// @ts-ignore JS module shared with Node tests.
import { jsonResponse, optionsResponse } from "../_shared/http.mjs";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    const url = new URL(req.url);
    const provider = url.searchParams.get("provider");
    if (!["linear", "basecamp", "trello"].includes(provider ?? "")) {
      return jsonResponse({ error: "Unsupported provider" }, 400);
    }

    const { client, user } = await requireUser(req);
    const state = randomState();
    const codeVerifier = randomState(32);
    const callbackBase = `${requiredEnv("SUPABASE_URL")}/functions/v1/oauth-callback`;
    const redirectUri = `${callbackBase}?provider=${provider}`;

    const { error } = await client.from("oauth_states").insert({
      user_id: user.id,
      provider,
      state,
      redirect_uri: redirectUri,
      code_verifier: provider === "linear" ? codeVerifier : null,
    });
    if (error) throw error;

    let authorizeURL;
    if (provider === "linear") {
      authorizeURL = buildLinearAuthorizeUrl({
        clientId: await requiredProviderSecret("LINEAR_CLIENT_ID"),
        redirectUri,
        state,
        codeChallenge: await pkceChallenge(codeVerifier),
        scopes: ["read"],
        prompt: "consent",
      });
    } else if (provider === "basecamp") {
      authorizeURL = buildBasecampAuthorizeUrl({
        clientId: await requiredProviderSecret("BASECAMP_CLIENT_ID"),
        redirectUri,
        state,
      });
    } else {
      const trelloReturnUrl = await providerSecret("TICKED_TRELLO_RETURN_URL");
      const returnUrl = `${trelloReturnUrl ?? "ticked://oauth/trello"}?state=${encodeURIComponent(state)}`;
      authorizeURL = buildTrelloAuthorizeUrl({
        appName: "Ticked",
        apiKey: await requiredProviderSecret("TRELLO_API_KEY"),
        returnUrl,
      });
    }

    return jsonResponse({ authorize_url: authorizeURL.toString() });
  } catch (error) {
    if (error instanceof Response) return error;
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});
