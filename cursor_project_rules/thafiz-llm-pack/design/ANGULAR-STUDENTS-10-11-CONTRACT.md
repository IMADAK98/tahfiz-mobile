# Angular FE contract — Students 10 / Requests 11

**Nest truth:** `localization-refactor` + live `tahfiz.onrender.com` (not GitHub `main`).  
**Sources:** `API-SCREEN-MAP` §2.7–2.8 · discovery `02-teachers-students.md` · live OpenAPI + prove 2026-09-10.

Auth: all admin routes under **`adminGuard`** (ADMIN / SYSTEM_ADMIN). Clients in **`core/api`**; feature folders + dto/enums; coerce **`id` string→number**; envelope HTTP 201 + body 200 common; success often **`data: null` → re-fetch lists**.

---

## 10 — Students list (`/admin/students`)

| | |
|---|---|
| List / search | `GET /center/{centerId}/active-students?page&limit&search` |
| Picker (halqa enroll) | `GET /center/{centerId}/available-students` — students **not yet in any ḥalaqa**. Empty available ≠ “no students in center”. Live often empty after enroll. |
| Optional filter | `GET /users/students?halqaId=&withoutPlan=` (boolean `withoutPlan` required by OpenAPI when used) |
| Identify | `GET /users/students/by-identification-number?identification=&passportNumber=` |

**Active/available row fields (live):** `id` (`number \| string` — coerce), `name`, `email`, `phone`, `identificationNumber`, `passportNumber`, `birthDate`, `address`, `nationality`, `isActive`, `createdAt`, `updatedAt`.  
**Quirk:** list ids often arrive as **strings** (`"28"`). Coerce on map. Paginated meta on active when present (`page`/`limit`/`totalItems`).

**Manual add CTA** → `POST /admin/student-requests/manual-create` (below), then **re-list active-students** (not the requests queue). Manual-created users **do not** appear in student-requests.

**Success copy** for manual-create ≠ public signup ≠ approve-request.

---

## Manual-create student (admin, bypasses queue)

| | |
|---|---|
| Endpoint | **`POST /admin/student-requests/manual-create`** (bearer ADMIN) |
| Body | `CreatePendingStudentRequestFromAdminDto` — **no `centerId`** (taken from JWT) |
| Effect | Creates user (+ profile) directly; **no** pending row; emails activation |
| Response | Often `{ status:200, data: { id:"28", … } }` or `data:null` → **re-list** to be safe |

**Required body fields (live prove + OpenAPI):**

| Field | Type / notes |
|---|---|
| `name` | string |
| `email` | string (email) |
| `phone` | string |
| `educationStage` | enum with **spaces**: `KINDERGARTEN` \| `ELEMENTARY SCHOOL` \| `MIDDLE SCHOOL` \| `HIGH SCHOOL` \| `UNIVERSITY` \| `POSTGRADUATE` |
| `identificationNumber` | string |
| `passportNumber` | string |
| `address` | string |
| `birthDate` | ISO date-time string |
| `parentPhone` | string |
| `surahFrom` | number 1–114 |
| `surahTo` | number 1–114 |
| `hifzQuality` | `HAFIZ` \| `NON_HAFIZ` \| `MUTQEN` \| `NON_MUTQEN` |
| `isHafiz` | boolean |

Live request that created user **28** used exactly those keys (`surahFrom`/`surahTo` camelCase).

---

## 11 — Student requests (`/admin/student-requests`)

| Action | Endpoint | Body |
|---|---|---|
| List | `GET /admin/student-requests` | — |
| Detail | `GET /admin/student-requests/{id}` | — |
| Approve | `POST /admin/student-requests/{id}/approve` | empty |
| Reject | `POST /admin/student-requests/{id}/reject` | **`{ rejectionReason: string }` required** |

- Public intake (out of scope for admin PR unless linked): `POST /pending-student-request` `{ …same fields…, token }` → PENDING row.
- Approve / reject / manual-create often return **`data: null`** — re-list; new user appears in `active-students` after approve.
- Manual-create students **do not** appear here.
- UI: collapsible cards (design lock like 08/11); confirm reject; required سبب الرفض.
- Leave non-TEST pending rows alone on shared demos (e.g. student request **#11**).

**List row shape (live, note snake_case surah keys on the entity):**  
`id`, `name`, `email`, `phone`, `educationStage`, `identificationNumber`, `passportNumber`, `address`, `birthDate`, `parentPhone`, `surah_from` / `surah_to` (nullable; request DTO uses camelCase), `hifzQuality`, `isHafiz`, `appliedToCenterId`, `termId`, `existingUserId`, `status` (`PENDING`), `rejectionReason`.  
Coerce request `id` string→number.

---

## Detail / edit (list «التفاصيل» / edit)

| Need | Endpoint | Notes |
|---|---|---|
| Detail by user id | **No** `GET /users/students/by-id/{id}` (teachers have this; students do not) | Use list row, or `GET /users/{id}` (generic user), or `GET /admin/student-requests/{id}` for pending only |
| Profile read | `GET /student-profile/{id}` | Path id = **studentProfile.id**, not user id |
| Profile update | `PATCH /student-profile/{id}` | OpenAPI `UpdateStudentProfileDto` is **empty `{}`** — do **not** invent edit fields. Prefer **read-only detail** from list/`GET /users/{id}` unless Nest ships a real DTO |
| User name/email/phone PATCH | **No** dedicated admin users PATCH in OpenAPI | Same as teachers: only patch what Nest documents |

**FE guidance for mock 10 «التفاصيل» / edit:** ship **read-only detail** (modal or `/admin/students/:id`) from the active-students row + optional `GET /users/{id}`. Do **not** wire a fake edit form against empty `UpdateStudentProfileDto`. Ḥalaqa enroll stays on ḥalaqa detail (`POST /halqa/enroll-students/{id}` — ADMIN only), not this screen.

---

## Envelope / FE checklist

1. Coerce all student/request ids string→number.  
2. Paginated meta on active-students when present.  
3. SKIP_GLOBAL_ERROR_TOAST on inline forms; i18n toasts.  
4. Nest truth = localization-refactor + live only.  
5. Empty `available-students` → empty-picker copy, never “no students”.  
6. `educationStage` enum values include spaces — match live exactly.
