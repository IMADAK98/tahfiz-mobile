# Thafiz Android APK Analysis Report

**APK:** `/workspace/thafiz/app-release.apk` (50 MB)  
**Analyzed:** 2026-09-10 (Asia/Riyadh)  
**Tools:** aapt, unzip, `strings` on Flutter AOT `libapp.so`

---

## 1. Package / version / SDK / label

| Field | Value |
|--------|--------|
| **package** | `com.example.sa_work` |
| **versionName** | `1.0.0` |
| **versionCode** | `2` |
| **minSdk** | `24` (Android 7.0) |
| **targetSdk** | `36` |
| **compileSdk** | `36` |
| **application-label** | `sa_work` |
| **launchable activity** | `com.example.sa_work.MainActivity` |
| **ABIs** | `arm64-v8a`, `armeabi-v7a`, `x86_64` |

Notes: package id and display name still look like a Flutter default/project name (`com.example.sa_work` / `sa_work`), not a production “Thafiz” branding. Build path leftover in binary: `.../sa_work/sa_work/`.

---

## 2. Framework

**Flutter (release/AOT), embedding v2.**

Evidence:
- Manifest `flutterEmbedding` = 2; `io.flutter.embedding.android.NormalTheme`
- `lib/*/libflutter.so` + `lib/*/libapp.so`
- `assets/flutter_assets/` with `AssetManifest.bin`, fonts, shaders
- **No** `kernel_blob.bin` (debug) and **no** RN `index.android.bundle`
- Dart packages under `package:sa_work/...`
- Stack: **Dio** HTTP, **flutter_dotenv**, **flutter_secure_storage**, Riverpod-style `*Provider`s, custom `AppRouter`

Not Capacitor/Cordova/RN/native-only.

---

## 3. API base URL / hosts

Bundled env file (primary source of truth):

`assets/flutter_assets/.env`:
```
API_BASE_URL=https://tahfiz.onrender.com/
```

| Host / URL | Role |
|------------|------|
| **`https://tahfiz.onrender.com/`** | **API base** (`API_BASE_URL` via dotenv → `baseUrl`) |
| `https://fallback.com` | Hardcoded fallback string in binary (likely unused default) |
| `https://fonts.gstatic.com/...` | Google Fonts |
| Flutter/docs URLs | Framework noise only |

No localhost / AWS / Firebase / Supabase hosts found as app backends. Backend appears to be a **Render.com** deployment named **tahfiz**.

---

## 4. API path surface (relative to base)

Auth (`auth_api.dart` / `auth_repository.dart`):
- `auth/login`
- `auth/logout`
- `auth/refresh`
- `auth/mobile/request-password-reset`
- `auth/mobile/reset-password`
- `/register` (teacher signup path fragment also present)
- `pending-teacher-request`

Teacher / profile / home:
- `/teacher-profile/`
- `/teacher-profile/by-teacher-id/`
- `halqa/by-teacher-id/`
- `/users/students`

Halqa (circle/section) / students:
- `/halqa/students/by-halqa-id/`
- `/halqa/study-plans/`
- `/students`
- `/student`
- `/assign-students`
- `/unassign-students`

Study plans / daily progress (Hifz/Murajaa):
- `/study-plan`, `/study-plan/`
- `study-plan/student/`
- `/student-daily-progress/`
- `/student-daily-progress/progress`
- `student-daily-progress/murajaa-plan`
- `/murajaa-plan` (fragment)

Attendance / calendar / Quran reference:
- `attendance/bulk`
- `/holiday-dates`
- `/term/`
- `/quran/surah/` and `quran/surahs`

Auth tokens in client: `accessToken`, `refreshToken`, `Authorization` / `Bearer`; stored via **flutter_secure_storage**.

---

## 5. Activities / navigation / deep links

**Android components**
- **Activity:** only `com.example.sa_work.MainActivity` (exported, MAIN/LAUNCHER)
- **Provider:** `androidx.startup.InitializationProvider`
- **Receiver:** `androidx.profileinstaller.ProfileInstallReceiver`
- **No** `VIEW`/`BROWSABLE` intent-filters → **no Android App Links / custom-scheme deep links** in the manifest

**In-app routes** (`AppRouter` / `goTo*`):
- `/login`, `/register`, `/revoverAccount` (typo in route name), `/bottomNav`, `/sectionDetail`, `/student`
- Screens: Login, Register (teacher signup), RecoverAccount + OtpVerification, BottomNav, Home, Profile/EditProfile, SectionDetails, Student, StudentPlan, StudyPlan, Plans, AvailableStudents

---

## 6. Permissions of interest

| Permission | Notes |
|------------|--------|
| `android.permission.INTERNET` | Only runtime-relevant app permission |
| `com.example.sa_work.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | AndroidX internal |

**Not requested:** CAMERA, LOCATION, STORAGE/MEDIA, CONTACTS, RECORD_AUDIO, POST_NOTIFICATIONS, etc. Fits a network-only teacher attendance / progress client.

---

## 7. Auth / roles (teacher–student mapping for BRD)

**Roles present in binary:** `teacher`, `student` (string literals + `Role` / `Role.fromJson`).  
**No clear `admin` role** in the mobile client strings — admin is likely web/backend-only if it exists.

**Teacher-centric mobile flows (strong evidence this APK is primarily a teacher app):**
- `TeacherSignupRequestModel`, `TeacherUser`, `TeacherData`, `getTeacherProfile`, `updateTeacherProfile`
- `pending-teacher-request` → signup may require approval before full access
- Halqa ownership: `halqa/by-teacher-id/`, assign/unassign students, available students
- Mark progress: post/edit/delete **student daily progress**, **murajaa** progress, bulk **attendance** (`PRESENT` / `ABSENT` / `LATE`)
- Plan types/status fragments: `HIFZ`, `MURAJAA`, `INTERMEDIATE`
- Fields: `markedByTeacherId`, `markingTeacherId`, `markingTeacherName`, `numberOfStudents`, `studentLimit`

**Student as data subject (not necessarily a separate student login UX):**
- Models/screens for student list, profile, study plan, daily progress — operated from teacher UI (`StudentScreen`, `AvailableStudentScreen`, etc.)
- Literal role `student` exists; dedicated student-app navigation is weaker than teacher signup/login/halqa management

**Auth UX:** login + teacher register/signup + mobile password reset (request → OTP screen → reset). Tokens refreshed via `auth/refresh`.

---

## 8. App structure map (high level)

```
sa_work (Flutter)
├── networks: auth_api, home_api, general_api, plan_api, dio_provider
├── repositories: auth, home, general, plan
├── ui: login, signup, recovery(OTP), bottom_nav, home,
│       section (halqa details / students / attendance),
│       curriculum (plans, study plan, available students),
│       profile
└── services: secure_storage_service (.env → API_BASE_URL)
```

Domain language matches Islamic Tahfiz ops: **halqa**, **hifz**, **murajaa**, **surah/ayah**, **term/holiday**, **attendance**, **study plans**.

---

## 9. Takeaways for BRD alignment

1. **Framework:** Flutter release app, package still `com.example.sa_work` / label `sa_work`.
2. **Backend:** `https://tahfiz.onrender.com/` (from bundled `.env`).
3. **Primary persona in this APK:** **Teacher** (signup, pending approval, halqa, assign students, attendance, daily hifz/murajaa progress, plans). **Student** appears as managed entity + role enum; dedicated student-app flows are not as strongly evidenced. **Admin** not visible in client.
4. **Permissions:** INTERNET only — no media/location.
5. **No OS deep links**; navigation is in-app router only.

