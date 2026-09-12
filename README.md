# Digi-Kul

**Digital Gurukul — Bringing quality education to every corner of India, regardless of bandwidth**

![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=flat&logo=fastapi)
![Next.js](https://img.shields.io/badge/Next.js-black?style=flat&logo=next.js&logoColor=white)
![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

---

## The Problem

India's higher education system serves over 40,000 AICTE-affiliated institutions and millions of students. Government policy mandates digital education delivery, yet the physical infrastructure tells a different story: over 60% of students in Tier-2/3 cities and rural areas depend on fluctuating 2G/3G mobile connections on mid-range Android devices.

Mainstream platforms (Zoom, Google Meet, Microsoft Teams) require 5–10 Mbps of stable broadband to function. For most rural students, these tools are unusable—constant buffering, audio drops, and battery drain make sustained participation impossible.

The result is a widening digital divide where the students who need digital education the most are the least able to access it.

## The Solution

Digi-Kul is an open-source, audio-first educational platform designed from the ground up for ultra-low bandwidth environments.

| Capability | Description |
|---|---|
| **Audio-First Live Sessions** | WebRTC with automatic degradation: video → audio → text, based on real-time bandwidth detection |
| **Offline-First Mobile App** | Study materials and quizzes cached locally via Isar. Quiz submissions queue offline and sync when connectivity returns |
| **Multi-Tenant Architecture** | Each institution gets isolated data scoping. Teachers from Institution A cannot access Institution B data |
| **PWA Web Dashboard** | Teachers and admins access the platform through a progressive web app — installable, cacheable, works on intermittent connections |
| **Real-Time Collaboration** | Chat, whiteboard, polls, and hand-raise during live sessions via Socket.IO |
| **Quiz Engine** | Offline-tolerant quiz taking with automatic grading and analytics |

## Architecture

```text
┌─────────────────────────────────────────────────────────┐
│                     Digi-Kul Platform                    │
├───────────────┬──────────────────┬──────────────────────┤
│   Flutter     │    Next.js       │   FastAPI Backend     │
│  Mobile App   │    Web App       │                      │
│  (Students)   │ (Teachers +      │  57 REST endpoints   │
│               │  Admins)         │  Socket.IO events    │
│  Android/iOS  │  PWA             │  WebRTC signaling    │
└───────┬───────┴────────┬─────────┴──────────┬───────────┘
        │                │                    │
        └────────────────┴────────────────────┘
                         │
               ┌─────────▼──────────┐
               │     Supabase       │
               │  PostgreSQL + RLS  │
               │  File Storage      │
               └────────────────────┘
```

- **`mobile/`** — Flutter student app (Android/iOS). Audio-first session joining, offline material access, quiz taking with background sync queue.
- **`frontend/`** — Next.js teacher and admin web app. Live session hosting with WebRTC, material uploads, quiz creation, analytics dashboard. Ships as a PWA.
- **`backend/`** — FastAPI server. 57 REST API endpoints, Socket.IO real-time event layer, WebRTC signaling relay, JWT authentication, multi-tenant data scoping.

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Mobile | Flutter 3.19 + Dart 3.3 | Student app — Android & iOS |
| Mobile State | Riverpod + Freezed | Reactive state + immutable models |
| Mobile Storage | Isar 3.x | Offline-first local database |
| Web Frontend | Next.js (App Router, TypeScript) | Teacher & admin dashboard (PWA) |
| Web Styling | Tailwind CSS + shadcn/ui | Component system |
| Backend | FastAPI (Python 3.11) | Async REST API + 57 endpoints |
| Real-Time | Socket.IO + WebRTC | Live sessions + signaling |
| Database | Supabase (PostgreSQL) | Multi-tenant data + RLS |
| File Storage | Supabase Storage | Materials + recordings |
| Auth | JWT (Bearer tokens) | Stateless authentication |
| Background Sync | WorkManager (Flutter) | Offline quiz submission queue |
| Notifications | Firebase Cloud Messaging | Push notifications |

## Getting Started

### Prerequisites

- Docker + Docker Compose
- (Optional) Flutter 3.19+ for mobile development
- (Optional) Node.js 18+ for frontend development
- (Optional) Python 3.11+ for backend development

### Quick Start (Docker)

```bash
git clone https://github.com/saivats/Digi-Kul.git
cd Digi-Kul
cp backend/.env.example backend/.env   # fill in Supabase + SMTP credentials
cp frontend/.env.example frontend/.env.local
docker compose up --build
# more backend capacity: docker compose up --scale backend=3  (Redis makes this safe)
```

| Service | URL |
|---|---|
| Web App | `http://localhost` (port 80 via nginx) |
| API | `http://localhost/api/health` |
| Backend Direct | `http://localhost:8000` |
| Frontend Direct | `http://localhost:3000` |

### Manual Backend Setup

```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Linux/Mac: source venv/bin/activate
pip install -r requirements.txt
redis-server &                 # live sessions need Redis; REDIS_URL defaults to redis://localhost:6379/0
uvicorn app.main:app --host 127.0.0.1 --port 8000
```

### Backend tests (live-session layer)

```bash
cd backend
pip install -r requirements-dev.txt
redis-server --port 6379 &     # tests use DB 9 of this instance
python -m pytest -v
```

The suite boots the real app under `uvicorn --workers 2` and drives it with
two Socket.IO clients: teacher creates a session, a student joins, refreshes
(reconnects while the old socket is still open), and a WebRTC offer/answer
round-trips — plus ownership checks, relay scoping, rate limiting and
recording finalisation.

### Manual Frontend Setup

```bash
cd frontend
npm install
npm run dev
```

### Mobile App

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000 \
            --dart-define=SOCKET_URL=http://10.0.2.2:8000
```

## Environment Variables

### Backend (`backend/.env`) — see `backend/.env.example`

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-service-or-anon-key
SECRET_KEY=your-strong-random-secret
JWT_ALGORITHM=HS256
JWT_EXPIRE_HOURS=8
REDIS_URL=redis://localhost:6379/0      # docker-compose overrides to redis://redis:6379/0
CORS_ORIGINS=http://localhost:3000,https://digikul.example.com   # shared by REST + Socket.IO
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_SENDER_EMAIL=noreply@digikul.in
```

### Frontend (`frontend/.env.local`) — see `frontend/.env.example`

```env
# PRODUCTION: both must be the PUBLIC nginx-fronted origin users type into
# their browser, e.g. https://digikul.example.com — never localhost:8000.
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_SOCKET_URL=http://localhost:8000

# TURN relay for WebRTC audio (see below)
NEXT_PUBLIC_TURN_URL=turn:turn.example.com:3478
NEXT_PUBLIC_TURN_USERNAME=digikul
NEXT_PUBLIC_TURN_CREDENTIAL=change-me
```

## Production infrastructure notes

### Redis (required)

The live-session store and Socket.IO's cross-process broadcast live in
Redis. `docker-compose.yml` ships a `redis` service; if you run the backend
elsewhere (Kubernetes, multiple VMs) point every replica's `REDIS_URL` at one
shared Redis (a managed instance is fine — it holds only ephemeral session
state, persistence is off). The backend refuses to start if Redis is
unreachable.

### TURN server (strongly recommended)

STUN only discovers a peer's public address; it does not relay traffic. A
student on mobile data (carrier-grade NAT) or a locked-down campus network
will complete the offer/answer handshake and then hear nothing. A TURN
relay fixes that. The frontend reads `NEXT_PUBLIC_TURN_*` at build time and
falls back to Google STUN when they are unset (the session header shows
"STUN only" so you can tell).

Self-hosting with [coturn](https://github.com/coturn/coturn) on a small VM
with a public IP:

```bash
sudo apt install coturn
# /etc/turnserver.conf
listening-port=3478
tls-listening-port=5349
realm=turn.example.com
server-name=turn.example.com
external-ip=<PUBLIC_IP>            # /<PRIVATE_IP> if behind cloud NAT
lt-cred-mech
user=digikul:change-me             # static creds; or use-auth-secret for TURN REST
cert=/etc/letsencrypt/live/turn.example.com/fullchain.pem
pkey=/etc/letsencrypt/live/turn.example.com/privkey.pem
min-port=49152
max-port=65535
no-cli
```

Open UDP+TCP 3478, TCP 5349 and UDP 49152–65535 in the firewall, then set
`NEXT_PUBLIC_TURN_URL=turn:turn.example.com:3478,turns:turn.example.com:5349`
and rebuild the frontend. Managed alternatives (Twilio Network Traversal,
Metered.ca, Cloudflare Calls TURN) work the same way — paste their
url/username/credential into the three variables. Test it at
https://webrtc.github.io/samples/src/content/peerconnection/trickle-ice/ —
you should see `relay` candidates.

### nginx

`nginx.conf` proxies `/socket.io/` with WebSocket upgrade headers and
`proxy_read_timeout`/`proxy_send_timeout` of 3600s so an idle-but-alive
connection is not cut after nginx's default 60s. Terminate TLS at nginx (or a
load balancer in front of it); the app itself only speaks HTTP.

### Mobile (`--dart-define`)

```env
API_BASE_URL=http://10.0.2.2:8000
SOCKET_URL=http://10.0.2.2:8000
```

## Roadmap

- [x] **Mobile Foundation** — Isar offline database, JWT auth, Dio HTTP client, go_router navigation
- [x] **Core Student Features** — Dashboard, materials (offline download), attendance tracking
- [x] **Live Sessions** — WebRTC audio-first, Socket.IO, bandwidth-adaptive mode switching
- [x] **Quiz Engine** — Offline quiz taking, background sync queue, analytics
- [x] **Backend (FastAPI)** — 57 REST endpoints, WebRTC signaling, multi-tenant scoping, Socket.IO events
- [x] **Web Frontend (Next.js)** — Teacher/admin dashboards, live session hosting, PWA
- [x] **Docker Deployment** — Multi-service compose with nginx reverse proxy
- [ ] **Performance Testing** — 3G throttled benchmarks, load testing
- [ ] **Production Hardening** — Rate limiting, request logging, Sentry integration
- [ ] **Video Support** — Selective video streaming for high-bandwidth students

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit with conventional commits: `feat:`, `fix:`, `docs:`
4. Open a pull request against `main`
5. All PRs must pass `flutter analyze` and `npx tsc --noEmit`

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

> *Digi-Kul is an open-source initiative. "Digi" from Digital, "Kul" from Gurukul — the ancient Indian institution of learning. Built to solve a real problem: every student deserves access to quality education, regardless of where they live or how fast their internet is.*
