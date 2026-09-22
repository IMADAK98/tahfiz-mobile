# Angular contract card — Screen 15 طلبات إعادة التسجيل

**Status:** **UNPARKED** (Imad 2026-09-16) — build on `IMADAK98/Tahfiz-Admin-ui`  
**Live truth:** `localization-refactor` deploy + Explorer `re-enroll-e2e/RESULT-rollover-prove.md`  
**Map:** `API-SCREEN-MAP.md` §2.12 · product locks `NEST-REENROLL-OPTION-A.md` (Option A + **H1**)

This card is for the **admin queue page only** (`/admin/re-enrollment-requests`). Creating requests is public identify (~16) via `POST /center/activate-student` — not this screen’s job.

---

## Route / auth

| | |
|---|---|
| Route | `/admin/re-enrollment-requests` (or `/admin/re-enrollment` — match Designer mock 15 + shell nav) under **`adminGuard`** |
| Roles | **ADMIN / SYSTEM_ADMIN** only (TEACHER → 403 on these APIs) |
| HTTP client | `ReEnrollmentApi` (or similar) in **`core/api`** |
| Feature | `features/re-enrollment/` folder-per-feature + `dto/` + `enums/`; thin `*.service.ts` |
| Errors | writes: `SKIP_GLOBAL_ERROR_TOAST` + inline/`ApiError.message`; success: i18n toasts (`toast.success.saved` / feature keys) |

---

## Endpoints (admin)

| Action | Method + path | Body |
|---|---|---|
| List | `GET /admin/re-enrollment-requests` | — |
| Detail (optional drawer) | `GET /admin/re-enrollment-requests/{id}` | — |
| Approve | `POST /admin/re-enrollment-requests/{id}/approve` | **empty** (no `halqaId` — **H1**) |
| Reject | `POST /admin/re-enrollment-requests/{id}/reject` | **`{ "rejectionReason": string }` required** |

**Not on this page:** `activate-student`, generate-reg-link, `enroll-students` / ḥalaqa assign. After approve, student is on **term only**; CTA to add ḥalaqa can deep-link students/ḥalaqa later — do not call enroll-students from approve.

---

## List / detail DTO (coerce ids)

OpenAPI `GetPendingReEnrollmentRequestDto` — treat all `id` / `*Id` as `number | string` → coerce to `number`.

| Field | Notes |
|---|---|
| `id` | request id |
| `name`, `email`, `phone`, `parentPhone` | display |
| `identificationNumber`, `passportNumber` | show one if present |
| `educationStage` | enum **with spaces** e.g. `ELEMENTARY SCHOOL` |
| `address`, `birthDate` | optional detail |
| `surah_from`, `surah_to`, `hifzQuality`, `isHafiz` | optional detail |
| `appliedToCenterId`, `termId`, `existingUserId` | coerce; show term id/name if you have a term label cache |
| `status` | `PENDING` \| `APPROVED` \| `REJECTED` |
| `rejectionReason` | set after reject |
| `createdAt`, `updatedAt` | ISO |

Default list filter UX: show **PENDING** first (or tabs PENDING / processed). Live list can be empty — that is normal.

---

## Envelope quirks (live)

- Success often **HTTP 201** + `body.status` / `statusCode` **200** — use existing `unwrapEnvelope` / `envelopeOk`.
- Approve live: HTTP 201 / body 200, message like «Re-enrollment request approved successfully»; **re-fetch list** (data may be thin/null).
- Reject: same envelope pattern; surface Nest `message` via i18n `فشل الطلب: {{message}}` if using global toast, or inline if SKIP.
- Do **not** expect `{ activated: true }` on this screen (that was stale `main` activate shape).

---

## Approve (H1)

1. Confirm dialog (Arabic).
2. `POST …/{id}/approve` — no body.
3. On success: toast + reload list. Student is on token/request **term**; **not** in a ḥalaqa.
4. Optional secondary copy: «أضف الطالب إلى حلقة من صفحة الحلقات» — no API call here.

---

## Reject

1. Modal with **required** `rejectionReason` (non-empty trim).
2. `POST …/{id}/reject` `{ rejectionReason }`.
3. Disable submit until reason filled; surface 400 if Nest rejects empty.

---

## Empty / error states

| State | Copy direction |
|---|---|
| Empty PENDING | «لا توجد طلبات إعادة تسجيل» + short hint: returning students appear after a new دورة + invite link (not from `available-students`) |
| Load error | `ApiError.message` / i18n unexpected |
| Already processed | 404 «Request not found or already processed» on approve/reject — toast + reload |

---

## Out of scope / do not

- Drive rows from `available-students` or term roster alone.
- Teacher-unassign / ḥalaqa pick on approve (**not H2**).
- Hardcoded Arabic for new toasts — use `public/i18n/ar.json` keys.
- Trust GitHub Nest `main` activate docs — live + `localization-refactor` only.

---

## Sources

1. `API-SCREEN-MAP.md` §2.12  
2. `/workspace/thafiz-discovery/web-cases/re-enroll-e2e/RESULT-rollover-prove.md` (requestId **14**, term **13**, H1)  
3. `NEST-REENROLL-OPTION-A.md`  
4. Mock: `15-re-enrollment.html`
