# Angular FE contract — Student signup 12 + Identify 16

**Nest truth:** `localization-refactor` + live `tahfiz.onrender.com` (not GitHub `main`).  
**Sources:** OpenAPI on live · `API-SCREEN-MAP` §2.8–2.9 / §2.13–2.14 · students 10/11 contract · local-build notes.

Envelope: coerce ids string→number; HTTP 201 + body status 200 common; public routes = **no bearer**.

---

## 12 — Student signup (public via center reg link)

| | |
|---|---|
| Route (FE) | `/signup/student?token={uuid}` (product host `www.tahfiz.work`) |
| Validate invite | `GET /register-token/validate/{token}` — **public** |
| Submit | `POST /pending-student-request` — **public** |
| Consume token (optional) | `POST /register-token/use/{token}` — **public** |

### Token / link validation

1. Gate the form on validate success before submit.  
2. Live shape (discovery): `{ centerName, termName, expiresAt }` (plus any extra Nest fields — do not invent UI without validate payload).  
3. Query pattern live: `?term={termName}&token={uuid}` (also accept token-only).  
4. **Live gaps:** non-UUID token → often **500**; missing token → HTTP 200 + body status 400. Soft-fail client errors; show banner only when validate OK.  
5. Admin generates link: `POST /center/{centerId}/generate-registration-link` (ADMIN/SYSTEM_ADMIN). Display/rewrite host to **`https://www.tahfiz.work/...`** even if API returns `tahfiz-client.vercel.app`.

### `POST /pending-student-request` body (all **required**)

| Field | Notes |
|---|---|
| `name` | string |
| `email` | email |
| `phone` | string |
| `educationStage` | `KINDERGARTEN` \| `ELEMENTARY SCHOOL` \| `MIDDLE SCHOOL` \| `HIGH SCHOOL` \| `UNIVERSITY` \| `POSTGRADUATE` (spaces in values) |
| `identificationNumber` | string max 10 |
| `passportNumber` | string max 10 |
| `address` | string |
| `birthDate` | ISO date-time |
| `parentPhone` | string |
| `surahFrom` / `surahTo` | number 1–114 (camelCase) |
| `hifzQuality` | `HAFIZ` \| `NON_HAFIZ` \| `MUTQEN` \| `NON_MUTQEN` |
| `isHafiz` | boolean |
| `token` | reg-link token string |

Unused ID/passport key may be sent as `""` if UI collects one primary identifier — still send both keys.

### Success / error

| Case | Expect |
|---|---|
| Success | HTTP **201**; body e.g. `{ status:201, message, data }` → PENDING row; admin queue is screens **11** (approve creates user + term context). Success copy ≠ manual-create ≠ approve. |
| Bad / expired / missing token | 4xx (or 500 on non-UUID) — block submit; Arabic error toast |
| Validation (DTO) | 400 — field errors |
| Duplicate / already on term | Nest message passthrough (do not invent copy) |

After public submit, student appears in **`GET /admin/student-requests`** (not active-students) until approve. Manual-create bypasses this queue (see students 10/11 contract).

---

## 16 — Identify

| Step | Endpoint | Auth (OpenAPI) |
|---|---|---|
| 1. Validate invite | `GET /register-token/validate/{token}` | **public** |
| 2. Lookup existing student | `GET /users/students/by-identification-number?identification=&passportNumber=` | OpenAPI: **bearer** (`access-token`) |
| 3. Returning / re-enroll | `POST /center/activate-student` body `{ token, studentId:number }` | OpenAPI: **bearer** |

### Identify lookup

- Query: `identification` and/or `passportNumber` (both optional in OpenAPI; send at least one).  
- **404** = not found.  
- Response = student user shape when found (coerce `id`).  
- Admin students list also uses this endpoint (JWT).

### Roles — who can call what

| Call | Intended product (screen 16) | OpenAPI / Nest |
|---|---|---|
| `register-token/validate` | **public** | public |
| `pending-student-request` | **public** (new student + token) | public |
| `by-identification-number` | public identify after validate | **JWT required in OpenAPI** — live public call **not proven** (may 401). If Angular public identify 401s, stop and flag CoS (Nest may need public allow, or identify stays post-login). |
| `activate-student` | returning student + token | OpenAPI JWT; live Option A returns `{ requestSubmitted, requestId }` PENDING (localization-refactor). `studentId` must be **number**. Already-on-term → 400. |

**ADMIN / SYSTEM_ADMIN:** generate-reg-link + admin queues + manual-create.  
**TEACHER:** ❌ generate-reg-link / activate / `/admin/*`.  
**Public:** validate + pending-student-request; identify/activate = see uncertainty above.

### FE flow (tight)

1. Load `?token=` → validate → banner: center · term · expiry.  
2. Collect identification and/or passport → lookup.  
3. Found → continue returning path (`activate-student` when product lock requires) or resume signup.  
4. Not found → new-student signup (`12`) with same token.  
5. Re-enroll queue UX = screen **15** contract (not available-students).

---

## Envelope / FE checklist

1. No bearer on validate + `POST /pending-student-request`.  
2. `educationStage` values include spaces — match live exactly.  
3. Coerce ids; rewrite reg-link host to `www.tahfiz.work`.  
4. Gate submit on validate OK.  
5. Point admin approve/reject to students **11** contract; re-enroll **15** for activate queue.  
6. `p-button` only on public forms (FE lock).
