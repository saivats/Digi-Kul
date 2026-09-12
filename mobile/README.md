# digikul_student

Digi-Kul Student Mobile App

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## Build configuration (environments)

All URLs are fixed at build time via `--dart-define`; there is no hardcoded
LAN IP any more (`lib/core/constants/api_constants.dart`).

| Build | Command | API / socket base |
|---|---|---|
| Emulator dev | `flutter run` | `http://10.0.2.2:8000` (host machine) |
| Phone on LAN | `flutter run --dart-define=API_BASE_URL=http://192.168.1.4:8000` | as given |
| Staging | `flutter build apk --dart-define=APP_ENV=staging` | `https://staging-api.digikul.in` |
| **Release** | `flutter build apk --release` | **`https://api.digikul.in`** (prod default) |

`SOCKET_URL` defaults to the API base (nginx proxies `/socket.io/` on the same
origin). TURN for WebRTC audio (recommended for mobile data):

```
flutter build apk --release \
  --dart-define=TURN_URL=turn:turn.digikul.in:3478 \
  --dart-define=TURN_USERNAME=digikul --dart-define=TURN_CREDENTIAL=<secret>
```

Backend contract: every endpoint in `ApiConstants` exists on
`backend/app/routers/student.py` (`/api/students/...`). Verify against a
running backend with `python backend/tests/mobile_contract.py`.
Push notifications need `google-services.json` and the
`migrations/20260912_create_student_devices.sql` table.
