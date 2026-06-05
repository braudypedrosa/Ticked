import assert from "node:assert/strict";
import test from "node:test";
import {
  buildSyncRun,
  classifyProviderStatus,
  upsertImportedTodos,
} from "../../supabase/functions/_shared/sync.mjs";

test("upsertImportedTodos preserves first_seen_at and local completion on duplicate imports", () => {
  const existing = [{
    id: "todo-1",
    connection_id: "connection-1",
    external_id: "issue-1",
    title: "Old title",
    first_seen_at: "2026-06-01T00:00:00.000Z",
    local_completed_at: "2026-06-04T00:00:00.000Z",
  }];
  const imported = [{
    connection_id: "connection-1",
    provider: "linear",
    external_id: "issue-1",
    title: "New title",
    due_at: "2026-06-05T00:00:00.000Z",
  }];

  const result = upsertImportedTodos(existing, imported, "2026-06-05T12:00:00.000Z");

  assert.equal(result.length, 1);
  assert.equal(result[0].title, "New title");
  assert.equal(result[0].first_seen_at, "2026-06-01T00:00:00.000Z");
  assert.equal(result[0].local_completed_at, "2026-06-04T00:00:00.000Z");
  assert.equal(result[0].last_synced_at, "2026-06-05T12:00:00.000Z");
});

test("upsertImportedTodos creates one row for repeated new external IDs", () => {
  const imported = [
    { connection_id: "connection-1", provider: "trello", external_id: "card-1", title: "Card" },
    { connection_id: "connection-1", provider: "trello", external_id: "card-1", title: "Card duplicate" },
  ];

  const result = upsertImportedTodos([], imported, "2026-06-05T12:00:00.000Z");

  assert.equal(result.length, 1);
  assert.equal(result[0].title, "Card duplicate");
});

test("classifyProviderStatus distinguishes auth, retry, and success outcomes", () => {
  assert.deepEqual(classifyProviderStatus(200), { kind: "ok" });
  assert.deepEqual(classifyProviderStatus(401), { kind: "auth_expired" });
  assert.deepEqual(classifyProviderStatus(429, { "retry-after": "15" }), { kind: "retry", retryAfterSeconds: 15 });
  assert.deepEqual(classifyProviderStatus(503), { kind: "retry", retryAfterSeconds: null });
  assert.deepEqual(classifyProviderStatus(404), { kind: "not_found" });
});

test("buildSyncRun captures status and error details", () => {
  const run = buildSyncRun({
    userId: "user-1",
    connectionId: "connection-1",
    status: "failed",
    startedAt: "2026-06-05T11:59:00.000Z",
    finishedAt: "2026-06-05T12:00:00.000Z",
    importedCount: 3,
    error: "401",
  });

  assert.equal(run.user_id, "user-1");
  assert.equal(run.imported_count, 3);
  assert.equal(run.error, "401");
});

