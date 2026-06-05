export function upsertImportedTodos(existingTodos, importedTodos, nowIso = new Date().toISOString()) {
  const byExternalKey = new Map();

  for (const todo of existingTodos) {
    byExternalKey.set(todoKey(todo), { ...todo });
  }

  for (const imported of importedTodos) {
    const key = todoKey(imported);
    const existing = byExternalKey.get(key);
    byExternalKey.set(key, {
      ...existing,
      ...imported,
      first_seen_at: existing?.first_seen_at ?? nowIso,
      local_completed_at: existing?.local_completed_at ?? null,
      last_synced_at: nowIso,
    });
  }

  return Array.from(byExternalKey.values());
}

export function classifyProviderStatus(status, headers = {}) {
  if (status >= 200 && status < 300) {
    return { kind: "ok" };
  }
  if (status === 401 || status === 403) {
    return { kind: "auth_expired" };
  }
  if (status === 404) {
    return { kind: "not_found" };
  }
  if (status === 429 || status >= 500) {
    const retryAfter = headers["retry-after"] ?? headers["Retry-After"];
    return {
      kind: "retry",
      retryAfterSeconds: retryAfter == null ? null : Number(retryAfter),
    };
  }
  return { kind: "error" };
}

export function buildSyncRun({ userId, connectionId, status, startedAt, finishedAt, importedCount = 0, error = null }) {
  return {
    user_id: userId,
    connection_id: connectionId,
    status,
    started_at: startedAt,
    finished_at: finishedAt,
    imported_count: importedCount,
    error,
  };
}

export function todoKey(todo) {
  return `${todo.connection_id}:${todo.external_id}`;
}

