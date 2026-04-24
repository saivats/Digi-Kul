# Digi-Kul
*Digital Gurukul — Bringing quality education to every corner of India, regardless of bandwidth*

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=flat&logo=fastapi)
![Next JS](https://img.shields.io/badge/Next-black?style=flat&logo=next.js&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)
![Status](https://img.shields.io/badge/Status-Active%20Development-orange.svg)

---

## The Problem

India has over 40,000 colleges under the AICTE mandate tasked with delivering digital education to millions of students. However, a significant reality remains overlooked: over 60% of students in Tier 2/3 cities and rural areas rely exclusively on fluctuating 2G, 3G, or low-end 4G mobile internet connections on mid-range Android devices. 

Existing proprietary platforms like Zoom, Google Meet, and Microsoft Teams were built for broadband infrastructure. They typically require stable 5-10 Mbps connections to function smoothly. For the majority of rural students, these platforms are entirely unusable, leading to severe audio stuttering, constant disconnections, and massive battery drain.

The result is a growing digital divide where policy mandates digital education, but the physical infrastructure cannot support it. Digi-Kul is built as an open-source solution to close this exact gap—delivering high-quality, continuous educational access on ultra-low bandwidth.

## The Solution

Digi-Kul solves the bandwidth crisis through an audio-first WebRTC architecture and an aggressively offline-capable mobile application.

| Feature | Description | Status |
|---|---|---|
| Audio-First Live Sessions | WebRTC with automatic degradation from video → audio → text based on bandwidth | 🚧 In Progress |
| Offline PWA | Materials and quizzes cached locally, quiz submissions sync when reconnected | 🚧 In Progress |
| Multi-Tenant Institutions | Each college gets isolated data, custom branding, own admin | 📋 Planned |
| Bandwidth Adaptation | Auto-detects connection quality and switches session mode in real time | 🚧 In Progress |
| Quiz Engine | Offline-tolerant quiz taking with analytics for teachers | 🚧 In Progress |
| Attendance Tracking | Per-student attendance calendar with threshold warnings | ✅ Complete |
| Material Management | Upload, compress, cache and download study materials offline | ✅ Complete |
| Session Recording | Chunk-based audio recording with playback | 📋 Planned |

## Architecture

```text
┌─────────────────────────────────────────────────────┐
│                    Digi-Kul Platform                 │
├──────────────┬──────────────────┬───────────────────┤
│   Flutter    │    Next.js 14    │   FastAPI Backend │
│  Mobile App  │    Web App       │                   │
│  (Students)  │ (Teachers +      │  REST API         │
│              │  Admins)         │  Socket.IO        │
│  Android     │  PWA             │  WebRTC Signaling │
│  iOS         │                  │                   │
└──────┬───────┴────────┬─────────┴────────┬──────────┘
       │                │                  │
       └────────────────┴──────────────────┘
                        │
              ┌─────────▼──────────┐
              │     Supabase       │
              │  PostgreSQL + RLS  │
              │  File Storage      │
              └────────────────────┘
```

- **mobile/** — Flutter student app (Android/iOS). Audio-first session joining, offline material access, quiz taking with sync queue.
- **frontend/** — Next.js 14 teacher and admin web app. Session hosting, material uploads, quiz creation, analytics.
- **backend/** — FastAPI server. REST API, Socket.IO real-time events, WebRTC signaling relay, email notifications.

## Repository Structure

```text
digi-kul/
├── backend/          # FastAPI (Python) — API + Socket.IO + WebRTC signaling
├── frontend/         # Next.js 14 — Teacher & Admin web app (PWA)
├── mobile/           # Flutter — Student mobile app (Android + iOS)
├── docs/             # Architecture diagrams, API docs
├── docker-compose.yml
└── README.md
```

> The backend and frontend are currently being rebuilt from the ground up with production-grade architecture. The Flutter mobile app is actively under development.

## Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| Mobile | Flutter 3.19 + Dart 3.3 | Student app — Android & iOS |
| Mobile State | Riverpod + Freezed | Reactive state + immutable models |
| Mobile Storage | Isar 3.x | Offline-first local database |
| Web Frontend | Next.js 14 (App Router) | Teacher & admin dashboard |
| Web Styling | Tailwind CSS + shadcn/ui | Component system |
| Backend | FastAPI (Python 3.11) | REST API + async performance |
| Real-time | Socket.IO + WebRTC | Live sessions + signaling |
| Database | Supabase (PostgreSQL) | Multi-tenant data + RLS |
| File Storage | Supabase Storage | Materials + recordings |
| Auth | JWT (httpOnly cookies) | Stateless, PWA-compatible |
| Background | Workmanager (Flutter) | Offline quiz sync |
| Notifications | Firebase Cloud Messaging | Push notifications |

## Getting Started

### Prerequisites
- Flutter 3.19+
- Python 3.11+
- Node.js 18+
- Docker + Docker Compose (optional but recommended)
- Supabase account (free tier works)

### Quick Start (Docker)
```bash
git clone https://github.com/saivats/Digi-Kul.git
cd Digi-Kul
cp .env.example .env   # fill in Supabase + SMTP keys
docker-compose up --build
```
Web portal and API: `http://localhost:5000`
Health check: `http://localhost:5000/api/health`

### Mobile App
```bash
cd mobile
flutter pub get
# Use --dart-define for local endpoints when needed
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000 --dart-define=SOCKET_URL=http://10.0.2.2:5000
```

### Manual Backend Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

### Production Checks
```bash
python -m py_compile main.py routes/*.py services/*.py middlewares/*.py utils/*.py
cd mobile && flutter analyze
```

GitHub Actions runs the same backend syntax and Flutter analyzer checks on pushes and pull requests to `main`.

## Environment Variables

Backend `.env`:
```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key
SECRET_KEY=your-strong-random-secret
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_HOURS=8
REFRESH_TOKEN_EXPIRE_DAYS=7
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_SENDER_EMAIL=noreply@digikul.in
SMTP_SENDER_NAME=Digi-Kul
FRONTEND_URL=http://localhost:3000
CORS_ORIGINS=http://localhost:3000
```

Mobile `.env` (dart-define):
```env
API_BASE_URL=http://10.0.2.2:8000
SOCKET_URL=http://10.0.2.2:8000
```

## Roadmap

**Phase 1 — Mobile Foundation** ✅
- Isar offline database, JWT auth, Dio client, go_router navigation

**Phase 2 — Core Student Features** ✅  
- Dashboard, Materials (with offline download), Attendance tracking

**Phase 3 — Live Sessions** 🚧
- WebRTC audio-first, Socket.IO, bandwidth-adaptive mode switching

**Phase 4 — Quiz Engine** 📋
- Offline quiz taking, IndexedDB sync queue, analytics

**Phase 5 — Backend (FastAPI)** 📋
- Full REST API, WebRTC signaling, email notifications, multi-tenancy

**Phase 6 — Web Frontend (Next.js)** 📋
- Teacher dashboard, session hosting, material management, PWA

**Phase 7 — Production** 📋
- Docker Compose, CI/CD, deployment docs, performance testing on 3G

## Contributing

- Fork the repository
- Create a feature branch: `git checkout -b feature/your-feature`
- Commit with conventional commits: `feat:`, `fix:`, `docs:` etc.
- Open a pull request against `main`
- All PRs must pass `flutter analyze` (mobile) and equivalent linting for backend/frontend

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

> Built to solve a real problem. Free to use, fork, and deploy for any educational institution.

---

> *Digi-Kul is an open-source initiative. "Digi" from Digital, "Kul" from Gurukul — the ancient Indian institution of learning. We believe every student deserves access to quality education, regardless of where they live or how fast their internet is.*
