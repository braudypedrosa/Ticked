export function assertOAuthState(expectedState, callbackState) {
  if (!callbackState) {
    throw new Error("Missing OAuth state");
  }
  if (expectedState !== callbackState) {
    throw new Error("OAuth state mismatch");
  }
}

export function buildLinearAuthorizeUrl({ clientId, redirectUri, state, codeChallenge, scopes = ["read"] }) {
  const url = new URL("https://linear.app/oauth/authorize");
  url.searchParams.set("client_id", clientId);
  url.searchParams.set("redirect_uri", redirectUri);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", scopes.join(","));
  url.searchParams.set("state", state);
  url.searchParams.set("code_challenge", codeChallenge);
  url.searchParams.set("code_challenge_method", "S256");
  return url;
}

export function buildBasecampAuthorizeUrl({ clientId, redirectUri, state }) {
  const url = new URL("https://launchpad.37signals.com/authorization/new");
  url.searchParams.set("type", "web_server");
  url.searchParams.set("client_id", clientId);
  url.searchParams.set("redirect_uri", redirectUri);
  url.searchParams.set("state", state);
  return url;
}

export function buildTrelloAuthorizeUrl({ appName, apiKey, returnUrl, scope = "read", expiration = "never" }) {
  const url = new URL("https://trello.com/1/authorize");
  url.searchParams.set("name", appName);
  url.searchParams.set("expiration", expiration);
  url.searchParams.set("scope", scope);
  url.searchParams.set("response_type", "token");
  url.searchParams.set("callback_method", "fragment");
  url.searchParams.set("return_url", returnUrl);
  url.searchParams.set("key", apiKey);
  return url;
}

export function tokenUpdateFromRefresh(existingToken, response, now = new Date()) {
  if (!response?.access_token) {
    throw new Error("Refresh response did not include access_token");
  }

  const expiresIn = Number(response.expires_in ?? 0);
  const expiresAt = expiresIn > 0
    ? new Date(now.getTime() + expiresIn * 1000).toISOString()
    : null;

  return {
    access_token: response.access_token,
    refresh_token: response.refresh_token ?? existingToken.refresh_token,
    expires_at: expiresAt,
  };
}

export function randomState(bytes = 24) {
  const array = new Uint8Array(bytes);
  crypto.getRandomValues(array);
  return Array.from(array, (value) => value.toString(16).padStart(2, "0")).join("");
}

export async function pkceChallenge(verifier) {
  const encoded = new TextEncoder().encode(verifier);
  const digest = await crypto.subtle.digest("SHA-256", encoded);
  return base64UrlEncode(new Uint8Array(digest));
}

export function base64UrlEncode(bytes) {
  const binary = Array.from(bytes, (byte) => String.fromCharCode(byte)).join("");
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

