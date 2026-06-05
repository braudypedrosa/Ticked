import { fetchBasecampTodos, fetchLinearTodos, fetchTrelloTodos } from "./provider_fetchers.mjs";
import { buildSyncRun, upsertImportedTodos } from "./sync.mjs";

export async function runSyncForConnections(service, connections, providerCredentials = {}) {
  const summary = { connections: connections.length, imported: 0, failed: 0 };

  for (const connection of connections) {
    const startedAt = new Date().toISOString();
    try {
      const token = await loadToken(service, connection.id);
      const providerResult = await fetchProviderTodos(connection, token, providerCredentials);
      if (providerResult.classification.kind === "auth_expired") {
        await service.from("integration_connections").update({ status: "needs_reauth" }).eq("id", connection.id);
        throw new Error("Provider authorization expired");
      }
      if (providerResult.classification.kind !== "ok") {
        throw new Error(`Provider sync failed: ${providerResult.classification.kind}`);
      }

      const { data: existingTodos, error: existingError } = await service
        .from("todos")
        .select("*")
        .eq("connection_id", connection.id);
      if (existingError) throw existingError;

      const finishedAt = new Date().toISOString();
      const upsertRows = upsertImportedTodos(existingTodos ?? [], providerResult.tasks, finishedAt);
      if (upsertRows.length) {
        const { error: upsertError } = await service
          .from("todos")
          .upsert(upsertRows, { onConflict: "connection_id,external_id" });
        if (upsertError) throw upsertError;
      }

      await insertRun(service, buildSyncRun({
        userId: connection.user_id,
        connectionId: connection.id,
        status: "succeeded",
        startedAt,
        finishedAt,
        importedCount: providerResult.tasks.length,
      }));
      await service.from("integration_connections").update({ last_synced_at: finishedAt }).eq("id", connection.id);
      summary.imported += providerResult.tasks.length;
    } catch (error) {
      summary.failed += 1;
      await insertRun(service, buildSyncRun({
        userId: connection.user_id,
        connectionId: connection.id,
        status: "failed",
        startedAt,
        finishedAt: new Date().toISOString(),
        error: error.message ?? "Unknown error",
      }));
    }
  }

  return summary;
}

async function loadToken(service, connectionID) {
  const { data, error } = await service
    .rpc("ticked_get_integration_token", { p_connection_id: connectionID })
    .single();
  if (error) throw error;
  return data;
}

async function fetchProviderTodos(connection, token, providerCredentials) {
  switch (connection.provider) {
    case "linear":
      return await fetchLinearTodos(connection, token, providerCredentials);
    case "basecamp":
      return await fetchBasecampTodos(connection, token, providerCredentials);
    case "trello":
      return await fetchTrelloTodos(connection, token, providerCredentials);
    default:
      throw new Error(`Unsupported provider ${connection.provider}`);
  }
}

async function insertRun(service, run) {
  const { error } = await service.from("sync_runs").insert(run);
  if (error) throw error;
}
