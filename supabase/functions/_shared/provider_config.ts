import { serviceClient } from "./supabase_client.ts";

const vaultSecretNames: Record<string, string> = {
  LINEAR_CLIENT_ID: "linear_client_id",
  LINEAR_CLIENT_SECRET: "linear_client_secret",
  BASECAMP_CLIENT_ID: "basecamp_client_id",
  BASECAMP_CLIENT_SECRET: "basecamp_client_secret",
  TRELLO_API_KEY: "trello_api_key",
  TICKED_TRELLO_RETURN_URL: "ticked_trello_return_url",
};

const cache = new Map<string, string | null>();

export type ProviderCredentials = {
  linearClientId: string | null;
  linearClientSecret: string | null;
  basecampClientId: string | null;
  basecampClientSecret: string | null;
  trelloApiKey: string | null;
  trelloReturnUrl: string | null;
};

export async function providerSecret(envName: string): Promise<string | null> {
  const envValue = Deno.env.get(envName);
  if (envValue) return envValue;

  const vaultName = vaultSecretNames[envName];
  if (!vaultName) return null;

  if (cache.has(vaultName)) {
    return cache.get(vaultName) ?? null;
  }

  const { data, error } = await serviceClient().rpc("ticked_read_vault_secret", {
    p_secret_name: vaultName,
  });

  if (error) {
    throw new Error(`Could not load Vault secret ${vaultName}: ${error.message}`);
  }

  const value = data ?? null;
  cache.set(vaultName, value);
  return value;
}

export async function requiredProviderSecret(envName: string): Promise<string> {
  const value = await providerSecret(envName);
  if (!value) {
    throw new Error(`Missing provider secret: ${envName}`);
  }
  return value;
}

export async function loadProviderCredentials(): Promise<ProviderCredentials> {
  const [
    linearClientId,
    linearClientSecret,
    basecampClientId,
    basecampClientSecret,
    trelloApiKey,
    trelloReturnUrl,
  ] = await Promise.all([
    providerSecret("LINEAR_CLIENT_ID"),
    providerSecret("LINEAR_CLIENT_SECRET"),
    providerSecret("BASECAMP_CLIENT_ID"),
    providerSecret("BASECAMP_CLIENT_SECRET"),
    providerSecret("TRELLO_API_KEY"),
    providerSecret("TICKED_TRELLO_RETURN_URL"),
  ]);

  return {
    linearClientId,
    linearClientSecret,
    basecampClientId,
    basecampClientSecret,
    trelloApiKey,
    trelloReturnUrl,
  };
}
