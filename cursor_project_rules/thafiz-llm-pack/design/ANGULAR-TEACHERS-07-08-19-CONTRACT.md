# Angular FE contract — Teachers 07 / Requests 08 / Detail 19

**Nest truth:** `localization-refactor` + live `tahfiz.onrender.com` (not GitHub `main`).  
**Sources:** `API-SCREEN-MAP` §2.5–2.6 · discovery `02-teachers-students.md` · OpenAPI live shapes.

Auth: all admin routes under **`adminGuard`** (ADMIN / SYSTEM_ADMIN). Clients in **`core/api`**; feature folders + dto/enums; coerce **`id` string→number**; envelope HTTP 201 + body 200 common; success often **`data: null` → re-fetch lists**.

---

## 07 — Teachers list (`/admin/teachers`)

| | |
|---|---|
| List / search | `GET /center/{centerId}/active-teachers?page&limit&search` |
| Picker (halqa assign) | `GET /center/{centerId}/available-teachers?page&limit&search` — label distinctly; live TEST results often match active |
| Quirk | Active path message may say “Available teachers…” — ignore wording |
| Row id | `number \| string` → coerce |
| Manual add CTA | Opens form → **manual-create** (below), then refresh **active-teachers** (not requests queue) |

Typical list fields: `id`, `name`, `email`, `phone`, `nationality`, `qualification`, `isActive`, …

---

## 19 — Teacher detail (`/admin/teachers/:id`)

| | |
|---|---|
| Load | `GET /users/teachers/by-id/{id}` (path id number; coerce from route) |
| Profile extras | Optional `GET /teacher-profile/by-teacher-id/{teacherId}` if detail needs ḥifẓ/tajweed beyond user DTO |
| Update | Prefer `PATCH /teacher-profile/{id}` with `UpdateTeacherProfileDto` fields below; confirm live whether user name/email/phone go on same PATCH or a users route — if unsure, ship profile PATCH + name/email/phone when OpenAPI allows on that DTO |

**UpdateTeacherProfileDto (OpenAPI):** `name?`, `email?`, `phone?`, `password?` (min 6), `qualification?`, `hasCertificate?`, `numberOfMemorizedJuz?` (0–30), `hasIjazahInHifz?`, `hasSanadInHifz?`, `tajweedLevel?` (`BEGINNER\|INTERMEDIATE\|ADVANCED`), `teachingAgeGroup?[]`, `availableWorkPeriod?[]`.

Do **not** call `GET /halqa/by-teacher-id/{id}` with arbitrary id (IDOR lock — self-only for TEACHER).

---

## Manual-create teacher (admin, bypasses queue)

| | |
|---|---|
| Endpoint | **`POST /pending-teacher-request/manual-create`** (bearer ADMIN) — **not** under `/admin/…` |
| Body | Same shape as `CreatePendingTeacherRequestDto` |
| Effect | Creates user + profile + center assign; **no** pending row; emails approval |
| Response | Often `{ status:200, data:null, message }` → **re-list active-teachers** to get new id |

**CreatePendingTeacherRequestDto (required core):**  
`teacherName`, `email`, `password` (min 8), `nationality`, `phone`, `address`, `birthDate`, `qualification` (`HIGH_SCHOOL\|DIPLOMA\|BACHELOR\|MASTER\|PHD\|OTHER`), `hasCertificate`, `numberOfMemorizedJuz` (1–30), `hasIjazahInHifz`, `hasSanadInHifz`, `tajweedLevel`, `teachingAgeGroup[]`, `availableWorkPeriod[]`, **`centerId`** (number — JWT center).

Enums: teachingAgeGroup `PRESCHOOL|PRIMARY_LOWER|PRIMARY_UPPER|MIDDLE_SCHOOL|HIGH_SCHOOL|UNIVERSITY|ADULTS`; availableWorkPeriod `WEEKDAYS|AFTER_FAJR|AFTER_ASR|AFTER_MAGHRIB|AFTER_ISHA`.

Success copy ≠ public signup / ≠ approve-request.

---

## 08 — Teacher requests (`/admin/teacher-requests`)

| Action | Endpoint | Body |
|---|---|---|
| List | `GET /admin/teacher-requests` | — |
| Detail | `GET /admin/teacher-requests/{id}` | — |
| Approve | `POST /admin/teacher-requests/{id}/approve` | empty |
| Reject | `POST /admin/teacher-requests/{id}/reject` | **`{ rejectionReason: string }` required** |

- Public intake (out of scope for admin PR unless linked): `POST /pending-teacher-request` → PENDING row; create/approve return **`data:null`** — re-list; new user appears in `active-teachers` after approve (e.g. user **27**).
- Manual-create teachers **do not** appear here.
- UI: collapsible cards (design lock like 08); confirm reject; required سبب الرفض.
- Leave non-TEST pending rows alone on shared demos.

---

## Envelope / FE checklist

1. Coerce all teacher/request ids string→number.  
2. Paginated meta on active-teachers when present (`page`/`limit`/`totalItems`).  
3. SKIP_GLOBAL_ERROR_TOAST on inline forms; i18n toasts.  
4. Nest truth = localization-refactor + live only.
