# تحفيظ — تطبيق المعلم (Flutter)

Teacher mobile client for Tahfiz ops (ḥalaqa, attendance, daily progress).
Package: `thafiz_teacher` · Android id: `com.thafiz.thafiz_teacher` · API: `https://tahfiz.onrender.com/`

## Map for web FE / BE developers

| Flutter | Web approx |
|---------|------------|
| Widget / `StatelessWidget` | React/Vue component |
| `go_router` routes | Client-side router (`/login`, `/halaqa/:id`, …) |
| `dio` + `ApiPaths` | `fetch` / Axios / HttpClient + path constants |
| `flutter_secure_storage` | `localStorage` / secure cookie jar for tokens |
| Riverpod `Provider` | DI + lightweight app state (Context / Zustand / Pinia) |
| `flutter_dotenv` `.env` | Vite/Next `VITE_*` / `process.env` |
| Feature folders under `lib/features/` | Domain modules (`auth/`, `halaqa/`, …) |

## Routes

| Path | Screen |
|------|--------|
| `/login` | Login |
| `/register` | Teacher signup stub |
| `/recover-account` | Recover + OTP (was `/revoverAccount`) |
| `/` | Bottom nav (home + profile) |
| `/halaqa/:id` | Ḥalaqa students list |
| `/student/:id` | Student hub |
| `/student/:id/attendance` | 4 chips: حاضر/غائب/متأخر/معذور |
| `/student/:id/progress` | Plan read-only; إلى سورة/آية; MURAJAA list |

## Product locks (progress UI)

- Plan block is **read-only**
- Teacher edits **only** `إلى سورة` + `إلى آية`
- HIFZ / TATHBEET: one pair each
- MURAJAA: add/remove list
- **No** وحدة / اتجاه fields
- Attendance: Nest `LEAVE` → معذور only (no إجازة chip)

## Brand

- Name: تحفيظ · mark: ت
- Green `#1B4D3E` · parchment `#F3EEE3`
- Font: Cairo via `google_fonts` (falls back to system)

## Run locally (dev)

```bash
flutter pub get
flutter analyze
# Do NOT require emulator for scaffold health — analyze is enough.
# When ready: flutter run
```

Ensure `.env` exists at project root with `API_BASE_URL=https://tahfiz.onrender.com/` and is listed under `flutter: assets:` in `pubspec.yaml`.

## Network stubs

- `lib/core/network/dio_client.dart` — Dio + Bearer interceptor
- `lib/core/network/api_paths.dart` — paths from RE of `com.example.sa_work`
- `features/*/data/*_api.dart` + `auth_repository.dart` — method stubs, no live calls yet

## Architecture sketch

```
lib/
  main.dart / app.dart
  core/     theme, env, dio, secure storage, go_router
  features/ auth, home, halaqa, student, profile
  shared/   brand mark, primary button
```
