# Thafiz — offline LLM handoff pack

Use this pack to continue **teacher mobile** + design/API context without Grok Bot tokens.

## Repos / paths
- Flutter teacher app (GitHub): `https://github.com/IMADAK98/tahfiz-mobile`
- Local checkout (Imad PC): `C:\Users\user\tahfiz-ui\thafiz_teacher`
- Package: `com.thafiz.thafiz_teacher` (not legacy `com.example.sa_work`)
- Admin Angular: `https://github.com/IMADAK98/Tahfiz-Admin-ui`
- Nest API (live truth for behavior): `https://tahfiz.onrender.com` — OpenAPI `https://tahfiz.onrender.com/api-json`
- Nest branch of truth: `localization-refactor` (not GitHub `main` until synced)

## Coding rule (Imad lock)
App coding must be **Cursor** (local Cursor agent + host emulator, or Cursor cloud agent). Do **not** use Grok Bot agents to write Flutter.

## Brand (mobile)
Cairo · تحفيظ · mark ت · primary `#1B4D3E` · parchment `#F3EEE3`

## Locked mobile screens (design/mobile)
- login + home-shell
- halaqa-detail.html (v1 LOCKED) — **v2 3-tab redesign awaiting Imad lock** (`HALAQA-DETAIL-V2.md`)
- student-attendance.html, student-progress.html (v1 LOCKED)
- student-progress v2 mocks **awaiting Imad lock** (`STUDENT-PROGRESS-V2.md`)
- assign/bind plan mocks **awaiting Imad lock** (`ASSIGN-PLAN.md`)
- teacher-signup 1–4 LOCKED (`TEACHER-SIGNUP.md`) — Flutter PR #2 already merged on tahfiz-mobile

## Attendance product locks
Chips: حاضر / غائب / متأخر / معذور only (Nest `LEAVE` → معذور). Soft light-green for حاضر.
Calendar: skip Fri/Sat + Nest holidayDates.
Nest bulk: `POST`/`PUT` `/attendance/bulk` with `{ termDayId, students: [{ userId, status }] }`.
Ḥalaqa term id: Nest `GetHalqaDto.assignedToTermId` (not `termId`).
Roster id for bulk: prefer `userId` / `user.id`.

## Progress form locks
Plan fields read-only. Teacher fills إلى سورة + إلى آية. HIFZ/TATHBEET one pair each. MURAJAA = list of entries. No وحدة/اتجاه chips.

## Nest field errors (Admin UI live; mobile signup uses same shape)
```json
{
  "statusCode": 400,
  "error": "Bad Request",
  "message": "Validation failed",
  "errors": [{ "fieldName": "adminEmail", "message": "..." }]
}
```

## Pack layout
- `design/` — foundations, screen map, Angular contracts, mobile notes
- `design/mobile/` — SCREENS-v2, TEACHER-SIGNUP, HALAQA-DETAIL-V2, STUDENT-PROGRESS-V2, ASSIGN-PLAN
- `api/` — apk-report, as-built-api, discovery summary, OpenAPI teacher/mobile slice
- `mobile/` — (this README pointers; use GitHub repo for code)

## Suggested next work (when continuing in Cursor)
1. Imad lock (or revise) assign/bind plan mocks (`ASSIGN-PLAN.md`) then Flutter Step 3
2. Imad lock (or revise) ḥalaqa-detail v2 tabs: الحضور · التقدم · نظرة عامة
3. Optional: multi-state attendance toggle POC was cancelled — only resume if Imad asks again

## HTML mocks live on CoS box (not all in this zip)
`/workspace/thafiz/design/mobile/*.html` and `previews/*.png` — ask CoS if you need the HTML/PNG zip too.
