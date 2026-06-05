import { requireUser, serviceClient } from "../_shared/supabase_client.ts";
import { errorMessage } from "../_shared/errors.ts";
import { loadProviderCredentials } from "../_shared/provider_config.ts";
// @ts-ignore JS module shared with Node tests.
import { jsonResponse, optionsResponse } from "../_shared/http.mjs";
// @ts-ignore JS module shared with Node tests.
import { runSyncForConnections } from "../_shared/sync_runner.mjs";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return optionsResponse();

  try {
    const { user } = await requireUser(req);
    const service = serviceClient();
    const { data: connections, error } = await service
      .from("integration_connections")
      .select("*")
      .eq("user_id", user.id)
      .eq("status", "active");
    if (error) throw error;

    const credentials = await loadProviderCredentials();
    const result = await runSyncForConnections(service, connections ?? [], credentials);
    return jsonResponse(result);
  } catch (error) {
    if (error instanceof Response) return error;
    return jsonResponse({ error: errorMessage(error) }, 500);
  }
});
