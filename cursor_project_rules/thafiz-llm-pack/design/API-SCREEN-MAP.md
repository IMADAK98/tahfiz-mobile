# ثفيز — API ↔ Screen Map (Admin MVP)

| Meta | Value |
|---|---|
| Date | **2026-09-11** (Asia/Riyadh, UTC+3) |
| Author track | Tech Lead (Imad) — pre-Angular sprint |
| API base | `https://tahfiz.onrender.com` (no global `/api` prefix; Swagger UI `/api`, OpenAPI `/api-json`) |
| **Nest truth (Imad 2026-09-16)** | Branch **`localization-refactor`** + live **`https://tahfiz.onrender.com`**. GitHub **`main` is stale** — never use as behavior reference until synced. |
| Branch note | Live contract ≈ `localization-refactor` on `IMADAK98/Tahfiz` (i18n `Accept-Language`, reports/enrollment) — see `as-built-api.md` |
| Auth | Bearer JWT scheme `access-token`; decode `role` / `userId` / `centerId` from token (login body has **no** user object) |
| Status | **MVP scope locked 2026-09-11** — guard PR held until CoS asks; CoS drafting Angular build brief |
| MVP locks (Imad 2026-09-11) | **PrimeNG**; brand **B Damascus Paradise** — primary `#1B4D3E`, gold `#D4AF37` (rare), adobe `#8B4A3A`, parchment `#F3EEE3`, ink `#15241C`, font **Cairo**; **PARK** re-enrollment + mobile unbound (web); **ḥalaqa detail + Plans tab in v1**; center signup **CTA-only**; product host **`https://www.tahfiz.work`**; **«إنهاء الدورة» in v1**. Re-enroll endpoints still documented for later. See `PRE-ANGULAR.md` / Designer brand pack. |
| Sources | `swagger.json`, `as-built-api.md`, `design/FOUNDATIONS.md` §1–2b + §16–19, Explorer `web-cases/01`–`04`, `DISCOVERY-SUMMARY.md`, authz memory lock (enroll B / UC025) |

**Product surfaces:** Admin web = center-admin ops (this map). Teacher daily attendance/progress = **mobile** (not primary web). OpenAPI has weak/no role annotations — roles below follow the **locked matrix**, not swagger.

---

## 1. Authz lock summary (Tech Lead / Imad 2026-09-10)

| Capability | ADMIN / SYSTEM_ADMIN | TEACHER | public |
|---|:---:|:---:|:---:|
| `/admin/*` (requests approve/reject, manual-create, re-enroll list) | ✅ | ❌ 403 | ❌ |
| Term CRUD (`POST/PUT/DELETE /term…`) | ✅ | ❌ (live: guard missing — treat as ADMIN-only in Angular) | ❌ |
| Ḥalaqa create/update/delete, `assign-teacher` | ✅ | ❌ (live: often reachable — **do not trust UI hide**) | ❌ |
| **`POST /halqa/enroll-students/{halqaId}`** (Imad lock B / UC025 delta) | ✅ | ❌ | ❌ |
| `POST /center/{id}/generate-registration-link`, `POST /center/activate-student` | ✅ | ❌ (reg-link 403 live; activate must stay admin) | ❌ |
| Attendance / progress **reports** (read) | ✅ center scope | ✅ **assigned ḥalaqa only** | ❌ |
| Study-plan create/assign on ḥalaqa | ✅ | ✅ **assigned ḥalaqa only** (Tech Lead rec.) | ❌ |
| `GET /halqa/by-teacher-id/{id}` | ✅ | ✅ **`id` = JWT `userId` only** (no IDOR) | ❌ |
| Login / register-token validate / pending-* create / center join | — | — | ✅ where noted |

> **Critical:** FE hide ≠ security. Backend RolesGuard + ḥalaqa ownership + center scope required. Guard PR held until CoS greenlights.

**One ACTIVE term UX (product lock):** when `GET /center/{centerId}/active-term` returns data → **disable** create-دورة + copy «أنهِ الدورة الحالية أولاً» (API rejects second ACTIVE / even future term with 400). **«إنهاء الدورة» is in v1** — UI must offer end-term; note OpenAPI `UpdateTermDto` has **no `status`** (only dates/holidays) while `Term.status` enum is `ACTIVE|INACTIVE|COMPLETED` — Angular brief / guard PR track must confirm the live end-term verb (undocumented status write vs dedicated route vs delete) before implementing.

---

## 2. Per-screen map

### 2.1 Login — `02-login.html`

| | |
|---|---|
| **Screen / HTML** | تسجيل الدخول · `02-login.html` · route target `/login` (live Next: `/user/login`) |
| **Endpoints** | `POST /auth/login` body `{ email, password }` → envelope often HTTP **201** + `{ statusCode:200, data:{ accessToken, refreshToken } }` — **no user in body**. Optional: `POST /auth/refresh` `{ refreshToken }`; `POST /auth/logout`; `POST /auth/request-password-reset` `{ email }`. Profile after login: `GET /profile` (or decode JWT). |
| **Role** | **public** (unauthenticated). After login: ADMIN/SYSTEM_ADMIN → admin shell; TEACHER → redirect to mobile / not admin MVP. |
| **Live gaps** | Batch 4 / DISCOVERY: early crawl saw ungated admin; later unauth `/admin/dashboard` → **307** `/user/login?redirect=…` — keep gate. Email field `type=text` on live; page title `Create Next App`. |
| **Angular notes** | Store tokens; decode JWT for `role`/`userId`/`centerId` before painting nav. Accept HTTP 201 + body.status 200. Guard all `/admin/*`. |

---

### 2.2 Dashboard — `03-dashboard.html`

| | |
|---|---|
| **Screen / HTML** | نظرة عامة / لوحة التحكم · `03-dashboard.html` |
| **Endpoints** | `GET /center/{centerId}/active-term` · `GET /term/by-center-id/{centerId}` · `GET /center/{centerId}/active-halqas` and/or `GET /halqa?centerId=` · `GET /halqa/by-term/{termId}` · KPI helpers: `GET /center/{id}/active-students?search&limit`, `GET /center/{centerId}/active-teachers?search&limit`. Edit term card → `PUT /term/{id}` (reg/holiday/end; name/status not in UpdateTermDto). |
| **Role** | **ADMIN / SYSTEM_ADMIN** (admin shell). TEACHER not primary web. |
| **Live gaps** | Batch 1 UI: no clear «دورات» nav; create-term CTA hidden when ACTIVE exists (align with product lock). Session flicker → login on some paths (01-terms). |
| **Angular notes** | Empty state: no ACTIVE → CTA إنشاء دورة. Filled: show term 12 spine + ḥalaqa counts. Disable create when ACTIVE. |

---

### 2.3 Terms / دورة (list + create modal) — `04-create-dawra-modal.html`

| | |
|---|---|
| **Screen / HTML** | دورة · modal `04-create-dawra-modal.html` (+ term card on dashboard / ḥalaqāt context) |
| **Endpoints** | **List:** `GET /term`, `GET /term/by-center-id/{centerId}`, `GET /center/{centerId}/active-term`, `GET /term/{id}`, `GET /term/{id}/holiday-dates`. **Create:** `POST /term` `{ name, startDate, endDate, registerationStartDate, registerationEndDate, holidayDates[], centerId }`. **Update:** `PUT /term/{id}` (same date fields; API typo *registeration*). **Delete:** `DELETE /term/{id}` (admin only; avoid in MVP demos). |
| **Role** | **ADMIN / SYSTEM_ADMIN** only. TEACHER ❌. |
| **Live gaps** | Explorer `01-terms-halaqat-plans.md`: second/future term → **400** *An active term already exists*; regEnd must be before term endDate; OpenAPI allows `startDate` on PUT but start change is risky / UI often locks start. |
| **Angular notes** | One ACTIVE per center UX: disable create + «أنهِ الدورة الحالية أولاً». **«إنهاء الدورة» in v1** (confirm live verb — `UpdateTermDto` omits `status`). No scheduled INACTIVE create. Envelope `{ data, message, status }` on many writes. |

---

### 2.4 Ḥalaqāt CRUD (+ detail / plans) — `05-halaqat.html`, `06-create-halaqa-modal.html`

| | |
|---|---|
| **Screen / HTML** | حلقات · `05-halaqat.html` · create modal `06-create-halaqa-modal.html` · detail Plans tab (admin IA, FOUNDATIONS §8) |
| **Endpoints** | **List:** `GET /halqa?centerId=`, `GET /halqa/by-term/{termId}`, `GET /halqa/dropdown`, `GET /halqa/{id}`, `GET /center/{centerId}/active-halqas`. **Create:** `POST /halqa` `{ name, category, periods[], studentLimit, termId, teacherId, isActive?, studentsIds? }`. **Update:** `PUT /halqa/{id}`. **Delete:** `DELETE /halqa/{id}`. **Assign teacher:** `POST /halqa/assign-teacher/{halqaId}` `{ teacherId }`. **Enroll students:** `POST /halqa/enroll-students/{halqaId}` `{ studentsIds[] }` — **ADMIN only**. **Unenroll:** `DELETE /halqa/{halqaId}/students/{studentId}`. **Roster:** `GET /halqa/students/by-halqa-id/{halqaId}?date=YYYY-MM-DD` (**date required** or 400). **Pickers:** `GET /center/{centerId}/available-teachers|active-teachers`, `available-students|active-students`. **Plans:** `GET /halqa/study-plans/{halqaId}`, `POST /study-plan` `{ name, halqaId, studyPlanItems[], studentIds? }`, `GET /study-plan/{id}/details`, `POST /study-plan/{id}/assign-students` `{ studentIds }`, `DELETE /study-plan/{id}/unassign-students`, `PUT /study-plan-item/{id}` — prefer **`/details`** over stub `GET/PATCH /study-plan/{id}`. |
| **Role** | Term/ḥalaqa CRUD + assign-teacher + **enroll-students** → **ADMIN / SYSTEM_ADMIN**. Study-plan manage on assigned ḥalaqa → **TEACHER** allowed (mobile); **admin v1 KEEP: ḥalaqa detail + Plans tab** (ADMIN assign/manage plans). |
| **Live gaps** | `01-…`: available-students often **empty** after enroll — use active/term roster + explicit empty copy. Study-plan GET/PATCH plain-text stubs. Student 26 moved to ḥalaqa **14** in batch1. Ḥalaqa **13** teachers dirty **[3, 25]** after TEACHER assign probe (`03-…`). OpenAPI “one teacher” vs multi-teacher state. |
| **Angular notes** | Explicit term picker (preselect ACTIVE). Teacher/student chips. Empty picker ≠ silent. Label capacity `N / limit`. Do not call enroll as TEACHER. |

---

### 2.5 Teachers list — `07-teachers.html`

| | |
|---|---|
| **Screen / HTML** | المعلمون · `07-teachers.html` |
| **Endpoints** | `GET /center/{centerId}/active-teachers?page&limit&search` · `GET /center/{centerId}/available-teachers?…` · optional `GET /users/teachers/by-id/{id}`. |
| **Role** | **ADMIN / SYSTEM_ADMIN**. |
| **Live gaps** | `02-teachers-students.md`: active vs available nearly identical for TEST; message on *active* path says “Available…”. User ids often **strings** (`"25"`, `"27"`). |
| **Angular notes** | Label pickers distinctly: نشطون vs متاحون للتعيين. Coerce id string→number for forms. |

---

### 2.6 Teacher requests — `08-teacher-requests.html`

| | |
|---|---|
| **Screen / HTML** | طلبات المعلمين · `08-teacher-requests.html` |
| **Endpoints** | `GET /admin/teacher-requests` · `GET /admin/teacher-requests/{id}` · `POST /admin/teacher-requests/{id}/approve` · `POST /admin/teacher-requests/{id}/reject` body `{ rejectionReason }`. Public intake (signup screen): `POST /pending-teacher-request` (no bearer). |
| **Role** | List/approve/reject → **ADMIN / SYSTEM_ADMIN**. Submit request → **public**. TEACHER ❌ on `/admin/*`. |
| **Live gaps** | Create/approve return `data:null` — **re-list** to learn request id / new userId (e.g. **27**). Non-TEST pending **#2** left untouched — filter TEST on shared demos. |
| **Angular notes** | Confirm dialogs on reject. Don’t share success copy with manual-create paths. |

---

### 2.7 Students list — `10-students.html`

| | |
|---|---|
| **Screen / HTML** | الطلاب · `10-students.html` (+ reg-link panel — see §2.9) |
| **Endpoints** | `GET /center/{id}/active-students?page&limit&search` · `GET /center/{centerId}/available-students` · optional `GET /users/students?halqaId&withoutPlan`. Manual add: `POST /admin/student-requests/manual-create` (bypasses pending queue). |
| **Role** | **ADMIN / SYSTEM_ADMIN**. |
| **Live gaps** | `02-…`: manual-create user **28** appears in active/available, **not** in student-requests. Ids as strings. available vs term roster disagreement for 28 (`03-…`). |
| **Angular notes** | Show manual-created in active list, not requests queue. Empty available ≠ “no students in center”. |

---

### 2.8 Student requests — `11-student-requests.html`

| | |
|---|---|
| **Screen / HTML** | طلبات الطلاب · `11-student-requests.html` |
| **Endpoints** | `GET /admin/student-requests` · `GET /admin/student-requests/{id}` · `POST /admin/student-requests/{id}/approve` · `POST /admin/student-requests/{id}/reject` `{ rejectionReason }`. Public: `POST /pending-student-request` (token-bearing signup). |
| **Role** | Admin ops → **ADMIN / SYSTEM_ADMIN**. Public submit with reg token. |
| **Live gaps** | Non-TEST pending **#11** present — list-only in Explorer. Manual-create bypasses this queue. |
| **Angular notes** | Parent + ḥifẓ fields from DTO; confirm reject reason. |

---

### 2.9 Enrollment / registration link (center ops)

| | |
|---|---|
| **Screen / HTML** | Embedded on `10-students.html` (and ops surfaces); no separate HTML file — product host copy UX per FOUNDATIONS §11 |
| **Endpoints** | `POST /center/{centerId}/generate-registration-link` → `{ url, token, expiresAt, … }` · `GET /register-token/validate/{token}` (public) · `POST /center/activate-student` `{ token, studentId:number }` (returning student) · `POST /register-token/use/{token}` (public consume). |
| **Role** | Generate + activate → **ADMIN / SYSTEM_ADMIN** (TEACHER gets 403 on generate live). Validate/use → **public**. |
| **Live gaps** | `02`/`03`/`04`: link host **`tahfiz-client.vercel.app`**, not `tahfiz.work` / `www.tahfiz.work`. Copy UX flaky on live admin. activate-student → 400 if already on term roster (student **28**). Non-UUID validate → **500**. |
| **Angular notes** | Display/rewrite to **product host** (`https://www.tahfiz.work/...` or locked `{app-host}`) in UI even if API returns vercel. Toast «تم النسخ». `studentId` must be **number**. |

---

### 2.10 Attendance report — `13-attendance-report.html`

| | |
|---|---|
| **Screen / HTML** | تقرير الحضور · `13-attendance-report.html` (admin **read-only**) |
| **Endpoints** | `GET /attendance/halqa/{halqaId}/aggregated?dateFrom&dateTo` · `GET /attendance/halqa/{halqaId}/weekly-table?weekStartDate&studentId?` · `GET /attendance/halqa/{halqaId}/weekly?weekStartDate` · optional timeline `…/students/{studentId}/timeline?dateFrom&dateTo` · term-level `GET /attendance/term/{termId}/aggregated?…`. Ḥalaqa filter source: `GET /halqa/by-term/{termId}` / dropdown. **Writes** (`POST/PUT /attendance/bulk`) = **teacher mobile**, not this screen. |
| **Role** | Admin read: **ADMIN**. Teacher read/write: **TEACHER** on **assigned** ḥalaqa only (mobile). |
| **Live gaps** | `03-…` + DISCOVERY: aggregated `students:[]` before marks ≠ no roster; weekly-table needs **Sunday** `weekStartDate` (Saudi Sun–Thu). TEACHER can read unassigned ḥalaqa live (authz hole). |
| **Angular notes** | Shared filters with progress (ḥalaqa + date range + search). Empty copy: «لا علامات حضور بعد» / weekly blanks — not «لا يوجد طلاب». Span multi-week ranges with multiple Sunday starts. |

---

### 2.11 Progress report — `14-progress-report.html`

| | |
|---|---|
| **Screen / HTML** | تقرير التقدّم · `14-progress-report.html` (admin read-only) |
| **Endpoints** | `GET /reports/progress?halqaId=&period=day|week|month&startingDate=&endingDate=` → `{ halqa, students[{ studentId, studentName, progress[{ planItemType: HIFZ|TATHBEET|MURAJAA, totalPercentage }] }] }`. |
| **Role** | **ADMIN** (center). **TEACHER** assigned ḥalaqa only for related reads; daily writes via mobile student-daily-progress (out of admin MVP map). |
| **Live gaps** | Period must be **lowercase**; shape stable; often **0%** without mobile writes (`03-…`). TEACHER unscoped read live. |
| **Angular notes** | Same base filters as attendance + optional plan-item filter after. Roster-based rows even at 0%. |

---

### 2.12 Re-enrollment — `15-re-enrollment.html`

| | |
|---|---|
| **Screen / HTML** | طلبات إعادة التسجيل · `15-re-enrollment.html` · **UNPARKED** (Imad 2026-09-16) — build Angular; contract `ANGULAR-REENROLL-15-CONTRACT.md` |
| **Product lock (Imad 2026-09-16)** | **Option A — pending queue** (target). Lifecycle: term ends → students inactive → new term + reg link → returning ID/passport → **PENDING** request → admin approve/reject. Full Nest delta: `NEST-REENROLL-OPTION-A.md`. |
| **Target endpoints** | Create: `POST /center/activate-student` → `{ requestSubmitted, requestId }` (**no** direct enroll). Queue: `GET /admin/re-enrollment-requests` · `GET …/{id}` · `POST …/{id}/approve` · `POST …/{id}/reject` `{ rejectionReason }`. Not from `available-students`. |
| **Role** | Activate create: public/ops per Nest choice. Queue approve/reject: **ADMIN / SYSTEM_ADMIN**. |
| **Live + `localization-refactor` (truth)** | Option A **WORKS** — activate → `{ requestSubmitted, requestId }` PENDING → approve H1 term-only. Prove 2026-09-16. |
| **Stale GitHub `main`** | Still direct `enrollUserInTerm` + `{ activated:true }` — ignore for Thafiz; sync from localization-refactor. |
| **Ḥalaqa on approve** | **LOCKED H1** — approve = term enroll only; ḥalaqa via `POST /halqa/enroll-students` (ADMIN). Not H2. |
| **Live prove** | `re-enroll-e2e/RESULT-rollover-prove.md`: term 13 + requestId 14 + approve H1. |
| **Angular notes** | Build now. List from re-enrollment-requests only; identify (~16) creates rows via activate; never from available-students alone. |

---

### 2.13 Identify-token (public) — `16-identify.html`

| | |
|---|---|
| **Screen / HTML** | تعريف / رابط دعوة · `16-identify.html` |
| **Endpoints** | `GET /register-token/validate/{token}` → `{ centerName, termName, expiresAt }` · then identify existing user: `GET /users/students/by-identification-number?identification=&passportNumber=` · optional `POST /center/activate-student` (admin/ops) or continue to student signup with token. Query pattern live: `?term={termName}&token={uuid}`. |
| **Role** | **public**. |
| **Live gaps** | `04-public-landing.md`: invalid token UI still shows form; no center/term/expiry banner; works on **tahfiz.work** and **vercel**; validate non-UUID → 500; missing token HTTP 200 + body status 400. |
| **Angular notes** | Gate submit on validate success; show center · term · expiry; product host preferred; soft-fail client errors. |

---

### 2.14 Public landing / signup (brief)

| Screen | HTML | Endpoints | Role | Notes |
|---|---|---|---|---|
| Landing | `01-landing.html` | none required | public | CTAs: دخول · تسجيل مركز. Live Join → center only (no teacher). |
| Center signup | (landing → signup) | `POST /pending-center-request` DTO admin+center fields; `POST …/resend-activation` `{email}` | public | **MVP lock: CTA-only** on landing (deep form may defer). **Bug:** accepts neither ID nor passport → 201 (`04-…`). SYSTEM_ADMIN lists/approves via `/system-admin/…` (out of center-admin MVP). |
| Teacher signup | `09-teacher-signup.html` | `POST /pending-teacher-request` (long DTO) | public | Two-step UI; not on landing Join. |
| Student signup | `12-student-signup.html` | `POST /pending-student-request` (+ `token`) | public | Needs reg token for term context; empty `اسم الدورة` without token. |

Focus remains **admin MVP** screens above.

---

## 3. Cross-cutting Angular contract checklist

1. **Auth envelope:** login HTTP 201 + `{ accessToken, refreshToken }` only — decode JWT for `role` / `userId` / `centerId`; optional `GET /profile`.
2. **Many writes:** HTTP 201 with `body.status` 200 and sometimes `data:null` → re-fetch lists.
3. **Id types:** coerce JSON string ids (`"27"`, `"28"`) to numbers where DTO requires number (`activate-student`).
4. **One ACTIVE term:** disable create + finish-current copy; don’t schedule INACTIVE yet.
5. **Sunday `weekStartDate`** for weekly attendance (Sun–Thu work week).
6. **Progress `period`:** lowercase `day|week|month` only.
7. **Study plans:** use `/details`, assign/unassign, `PUT /study-plan-item/{id}` — ignore stub GET/PATCH `/study-plan/{id}`.
8. **Ḥalaqas by term empty (locked 2026-09-16):** `GET /halqa/by-term/{termId}` (and equivalents) must return **HTTP/body 200 + `[]`** when zero ḥalaqas — **never** 404 «No halqas found for this term». FE may defensively map that legacy 404 → [].
9. **Halqa roster date:** `GET /halqa/students/by-halqa-id/{id}?date=` required.
9. **Reg-link host (locked):** rewrite/display as **`https://www.tahfiz.work/...`** even if API returns `tahfiz-client.vercel.app`.
10. **Authz:** enroll-students + term/ḥalaqa CRUD + assign-teacher + `/admin/*` + generate-reg-link = ADMIN only; TEACHER study-plan + attendance/progress on assigned ḥalaqa; `by-teacher-id` self-only.
11. **i18n:** send `Accept-Language` (localization-refactor).
12. **MVP KEEP/PARK (locked):** `15-re-enrollment` **UNPARKED** 2026-09-16; PARK mobile unbound (web); KEEP ḥalaqa **detail + Plans** in v1; center signup **CTA-only** on landing (full form may defer); **«إنهاء الدورة»** in v1 (confirm API verb — see §1).
13. **UI kit (locked):** PrimeNG + brand **B Damascus Paradise** (`#1B4D3E` / `#D4AF37`, Cairo) — tokens from `tokens.css` / Designer brand pack.

---

## 4. Open issues / dirty data (do not “fix” without CoS)

| Issue | Ref |
|---|---|
| Ḥalaqa **13** teachers **[3, 25]** after TEACHER `assign-teacher` probe; no unassign-teacher API; unrestored | Explorer `03-reports-reenroll-roles.md` |
| Student **28** on term **12** roster + `available-students`, no ḥalaqa; activate-student 400 | `03-…` |
| Student **26** enrollment moved toward ḥalaqa **14** in batch1 (12 roster empty on some date queries) | `01-…` |
| Reg links host **tahfiz-client.vercel.app** vs admin **tahfiz.work** | `02`/`04` |
| Study-plan GET/PATCH stubs; create response omits items | `01-…` |
| `available-students` empty vs active after enroll; picker UX | `01`/`FOUNDATIONS` §12 |
| TEACHER missing write guards (term/ḥalaqa/assign/enroll handlers reachable) — Critical; PR held | `03` + memory lock |
| Pending non-TEST teacher **#2** / student **#11** still in queues | `02` |
| Accidental pending center `TEST-Center` (`data:null`) — not approved | `04` |
| Validate token non-UUID → 500; pending-center XOR ID/passport not enforced | `04` |

---

## 5. Out of scope (this doc)

- Angular Dev staffing / implementation
- RolesGuard / ownership **PR** until CoS explicitly asks
- Teacher mobile daily write UX as primary web screens (see `MOBILE-TEACHER-NOTES.md`)
- SYSTEM_ADMIN center-request console
- Live mutating API calls from this track; Linear tickets; opening PRs

---

*MVP scope locked 2026-09-11 — ready for CoS Angular build brief. Guard PR still held.*
