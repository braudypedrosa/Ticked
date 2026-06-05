import { requireUser, serviceClient } from "../_shared/supabase_client.ts";
import { errorMessage } from "../_shared/errors.ts";
// @ts-ignore JS module shared with Node tests.
import { assertOAuthState } from "../_shared/oauth.mjs";
// @ts-ignore JS module shared with Node tests.
import { jsonResponse, optionsResponse, requestJSON } from "../_shared/http.mjs";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    const { user } = await requireUser(req);
    const service = serviceClient();
    const body = await requestJSON(req);
    if (!body.token) {
      return jsonResponse({ error: "Missing Trello token" }, 400);
    }

    if (body.state) {
      const { data: oauthState, error: stateError } = await service
        .from("oauth_states")
        .select("*")
        .eq("state", body.state)
        .single();
      if (stateError) throw stateError;
      assertOAuthState(oauthState.state, body.state);
      if (oauthState.user_id !== user.id || oauthState.provider !== "trello" || oauthState.status !== "pending") {
        throw new Error("OAuth state is no longer valid");
      }
      await service.from("oauth_states").update({ status: "completed" }).eq("id", oauthState.id);
    }

    const { data: connection, error } = await service
      .from("integration_connections")
      .insert({
        user_id: user.id,
        provider: "trello",
        account_label: "Trello",
        external_account_id: "me",
        scopes: ["read"],
      })
      .select()
      .single();
    if (error) throw error;

    const { error: tokenError } = await service.rpc("ticked_upsert_integration_token", {
      p_connection_id: connection.id,
      p_access_token: body.token,
      p_refresh_token: null,
      p_expires_at: null,
      p_token_type: "trello-token",
      p_raw_token: { token_received_at: new Date().toISOString() },
    });
    if (tokenError) throw tokenError;

    return jsonResponse({ ok: true, connection_id: connection.id });
  } catch (error) {
    if (error instanceof Response) return error;
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});
