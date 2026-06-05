import { classifyProviderStatus } from "./sync.mjs";
import { tokenUpdateFromRefresh } from "./oauth.mjs";

export async function fetchLinearTodos(connection, token, credentials = {}) {
  const response = await fetch("https://api.linear.app/graphql", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token.access_token}`,
    },
    body: JSON.stringify({
      query: `query AssignedIssues {
        viewer {
          assignedIssues(filter: { state: { type: { nin: ["completed", "canceled"] } } }) {
            nodes {
              id
              identifier
              title
              url
              dueDate
              team { name }
              state { name }
            }
          }
        }
      }`,
    }),
  });

  const classification = classifyProviderStatus(response.status, Object.fromEntries(response.headers.entries()));
  if (classification.kind !== "ok") return { classification, tasks: [] };

  const data = await response.json();
  const nodes = data?.data?.viewer?.assignedIssues?.nodes ?? [];
  return {
    classification,
    tasks: nodes.map((issue) => ({
      connection_id: connection.id,
      user_id: connection.user_id,
      provider: "linear",
      external_id: issue.id,
      source_key: issue.identifier,
      title: issue.title,
      external_url: issue.url,
      source_name: issue.team?.name ?? null,
      due_at: issue.dueDate ? `${issue.dueDate}T00:00:00.000Z` : null,
      raw_metadata: issue,
    })),
  };
}

export async function fetchBasecampTodos(connection, token, credentials = {}) {
  const accountID = connection.external_account_id;
  const url = `https://3.basecampapi.com/${accountID}/my/assignments.json`;
  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${token.access_token}`,
      "User-Agent": "Ticked (braudy@sessionwise.com)",
      Accept: "application/json",
    },
  });

  const classification = classifyProviderStatus(response.status, Object.fromEntries(response.headers.entries()));
  if (classification.kind !== "ok") return { classification, tasks: [] };

  const data = await response.json();
  const assignments = [...(data.priorities ?? []), ...(data.non_priorities ?? [])];
  return {
    classification,
    tasks: assignments
      .filter((assignment) => !assignment.completed)
      .map((assignment) => ({
        connection_id: connection.id,
        user_id: connection.user_id,
        provider: "basecamp",
        external_id: String(assignment.id),
        source_key: null,
        title: assignment.content,
        external_url: assignment.app_url,
        source_name: [assignment.bucket?.name, assignment.parent?.title].filter(Boolean).join(" / ") || null,
        due_at: assignment.due_on ? `${assignment.due_on}T00:00:00.000Z` : null,
        raw_metadata: assignment,
      })),
  };
}

export async function fetchTrelloTodos(connection, token, credentials = {}) {
  const apiKey = requiredCredential("Trello API key", credentials.trelloApiKey ?? env("TRELLO_API_KEY"));
  const url = new URL("https://api.trello.com/1/members/me/cards");
  url.searchParams.set("filter", "open");
  url.searchParams.set("fields", "id,name,url,due,dueComplete,closed,idBoard,idList");
  url.searchParams.set("key", apiKey);
  url.searchParams.set("token", token.access_token);

  const response = await fetch(url);
  const classification = classifyProviderStatus(response.status, Object.fromEntries(response.headers.entries()));
  if (classification.kind !== "ok") return { classification, tasks: [] };

  const cards = await response.json();
  return {
    classification,
    tasks: cards
      .filter((card) => !card.closed && !card.dueComplete)
      .map((card) => ({
        connection_id: connection.id,
        user_id: connection.user_id,
        provider: "trello",
        external_id: card.id,
        source_key: null,
        title: card.name,
        external_url: card.url,
        source_name: null,
        due_at: card.due,
        raw_metadata: card,
      })),
  };
}

export async function refreshLinearToken(token, credentials = {}) {
  const clientId = requiredCredential("Linear client ID", credentials.linearClientId ?? env("LINEAR_CLIENT_ID"));
  const body = new URLSearchParams({
    grant_type: "refresh_token",
    refresh_token: token.refresh_token,
    client_id: clientId,
  });

  const clientSecret = credentials.linearClientSecret ?? env("LINEAR_CLIENT_SECRET");
  if (clientSecret) body.set("client_secret", clientSecret);

  const response = await fetch("https://api.linear.app/oauth/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body,
  });

  if (!response.ok) throw new Error(`Linear token refresh failed: ${response.status}`);
  return tokenUpdateFromRefresh(token, await response.json(), new Date());
}

function env(name) {
  return globalThis.Deno?.env?.get?.(name) ?? null;
}

function requiredCredential(label, value) {
  if (!value) throw new Error(`Missing ${label}`);
  return value;
}
