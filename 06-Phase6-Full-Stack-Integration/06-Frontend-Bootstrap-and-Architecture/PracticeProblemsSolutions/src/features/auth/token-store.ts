// In-memory access token + refresh helpers.
// Topic 7 wires this to the actual /auth/refresh endpoint.

let accessToken: string | null = null;

export function getAccessToken(): string | null {
  return accessToken;
}

export function setAccessToken(token: string | null): void {
  accessToken = token;
}

export function clearAuth(): void {
  accessToken = null;
}

// TODO Topic 7: POST /auth/refresh (HttpOnly cookie sent automatically with withCredentials)
export async function refreshAccessToken(): Promise<string | null> {
  return null;
}
