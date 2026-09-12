/**
 * Public runtime configuration.
 *
 * NEXT_PUBLIC_* values are inlined at `next build` time, so they must be set
 * in the environment of the *build* (frontend/.env.local for docker-compose).
 *
 * PRODUCTION: NEXT_PUBLIC_API_URL and NEXT_PUBLIC_SOCKET_URL must point at
 * the public, nginx-fronted origin (e.g. https://digikul.example.com), NOT
 * localhost:8000. The browser is what connects to them — "localhost" in a
 * student's browser is the student's own phone, not your server. nginx.conf
 * routes /api/ and /socket.io/ from that one origin to the backend, so both
 * values are normally identical and equal to the site's own origin.
 */

const LOCAL_RE = /^(https?:\/\/)?(localhost|127\.0\.0\.1|0\.0\.0\.0)(:\d+)?/i;

function fromEnv(value: string | undefined, fallback: string): string {
  const v = (value ?? "").trim();
  return v.length > 0 ? v.replace(/\/+$/, "") : fallback;
}

export const API_URL = fromEnv(
  process.env.NEXT_PUBLIC_API_URL,
  "http://localhost:8000"
);

// Default the socket to the same origin as the API — with nginx in front
// they share one public origin.
export const SOCKET_URL = fromEnv(process.env.NEXT_PUBLIC_SOCKET_URL, API_URL);

export const SOCKET_PATH = "/socket.io";

let warned = false;
/** Loud, one-time warning when a production build is pointed at localhost. */
export function checkPublicUrls(): void {
  if (warned || typeof window === "undefined") return;
  warned = true;
  const pageIsLocal = LOCAL_RE.test(window.location.origin);
  const problems: string[] = [];
  if (!pageIsLocal && LOCAL_RE.test(API_URL)) {
    problems.push(`NEXT_PUBLIC_API_URL=${API_URL}`);
  }
  if (!pageIsLocal && LOCAL_RE.test(SOCKET_URL)) {
    problems.push(`NEXT_PUBLIC_SOCKET_URL=${SOCKET_URL}`);
  }
  if (problems.length > 0) {
    console.error(
      `[Digi-Kul config] This page is served from ${window.location.origin} but ` +
        `${problems.join(" and ")} point(s) at localhost. Browsers will try to reach ` +
        `their OWN machine. Set both NEXT_PUBLIC_API_URL and NEXT_PUBLIC_SOCKET_URL to ` +
        `the public nginx-fronted origin (usually ${window.location.origin}) and rebuild.`
    );
  }
}

export function isMisconfiguredForProduction(): boolean {
  if (typeof window === "undefined") return false;
  const pageIsLocal = LOCAL_RE.test(window.location.origin);
  return !pageIsLocal && (LOCAL_RE.test(API_URL) || LOCAL_RE.test(SOCKET_URL));
}
