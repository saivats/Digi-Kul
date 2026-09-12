/**
 * ICE server configuration for the live-session peer connections.
 *
 * STUN alone only works when both peers have a "friendly" NAT. Students on
 * mobile data (carrier-grade NAT) and campus networks behind strict
 * firewalls need a TURN relay, otherwise the offer/answer completes but no
 * audio ever flows. Provide your own TURN server via:
 *
 *   NEXT_PUBLIC_TURN_URL=turn:turn.example.com:3478          (comma-separate multiple)
 *   NEXT_PUBLIC_TURN_USERNAME=digikul
 *   NEXT_PUBLIC_TURN_CREDENTIAL=<shared secret / static password>
 *
 * These are inlined at build time. If unset, we fall back to public STUN
 * (works on most home/office wifi, NOT reliably on mobile data).
 */

const DEFAULT_STUN: RTCIceServer[] = [
  { urls: "stun:stun.l.google.com:19302" },
  { urls: "stun:stun1.l.google.com:19302" },
];

function parseTurnUrls(raw: string | undefined): string[] {
  return (raw ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter((s) => /^turns?:/i.test(s));
}

export function getIceServers(): RTCIceServer[] {
  const turnUrls = parseTurnUrls(process.env.NEXT_PUBLIC_TURN_URL);
  const username = (process.env.NEXT_PUBLIC_TURN_USERNAME ?? "").trim();
  const credential = (process.env.NEXT_PUBLIC_TURN_CREDENTIAL ?? "").trim();

  const servers: RTCIceServer[] = [...DEFAULT_STUN];
  if (turnUrls.length > 0 && username && credential) {
    servers.push({ urls: turnUrls, username, credential });
  } else if (turnUrls.length > 0) {
    // A TURN URL without credentials is useless — say so once, loudly.
    console.warn(
      "[Digi-Kul webrtc] NEXT_PUBLIC_TURN_URL is set but NEXT_PUBLIC_TURN_USERNAME / " +
        "NEXT_PUBLIC_TURN_CREDENTIAL are missing; falling back to STUN only."
    );
  }
  return servers;
}

export function hasTurnConfigured(): boolean {
  return getIceServers().some((s) =>
    (Array.isArray(s.urls) ? s.urls : [s.urls]).some((u) => /^turns?:/i.test(u))
  );
}

export function getRtcConfig(): RTCConfiguration {
  return {
    iceServers: getIceServers(),
    // Keep candidate gathering cheap on low-end devices.
    iceCandidatePoolSize: 0,
  };
}
