export function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : "Unknown error";
}

export function requiredEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) {
    throw new Error(`Missing environment variable: ${name}`);
  }
  return value;
}

