# Nest contract delta — Re-enrollment Option A (LOCKED product)

**Date:** 2026-09-16 Asia/Riyadh  
**Product lock (Imad):** Option **A — pending queue** + **H1** (term-only approve).  
**LIVE PROVE (2026-09-16):** **WORKS** — after term 12 COMPLETED, activate student 30 → `requestId:14` PENDING → approve → on term 13, no ḥalaqa. See `/workspace/thafiz-discovery/web-cases/re-enroll-e2e/RESULT-rollover-prove.md`.

**Source of truth for Nest code:** GitHub branch **`localization-refactor`** (`activateStudent` → `pendingStudentRequestService.submitReturningStudentRequest`).  
**Stale:** GitHub **`main`** still auto-enrolls (`enrollUserInTerm` + `{activated:true}`) — do not use for Thafiz deploy/Angular contracts.  
**Nest Option A CloudAgent PR:** cancelled as redundant (live + localization-refactor already correct).

**Angular:** screen `15` can **unpark** against live prove (CoS/Imad). Until unparked, keep PARK note in API-SCREEN-MAP.

---

## Intended lifecycle (center)

1. Student registered in center (pending-student approve, manual-create, or prior term).
2. Term ends → students become inactive for that term context (term status / enrollment inactive — implement consistently with end-term).
3. New term starts; admin generates reg link (`POST /center/{id}/generate-registration-link`) while registration window open.
4. Returning student opens link → identify by **ID or passport** → Nest creates **PENDING** re-enrollment request (طلبات إعادة التسجيل).
5. Admin **approve** → set student **active** + **enroll in token’s term**.  
   **Ḥalaqa:** see open flag below (TL recommends **term-only** on approve).
6. Admin **reject** → `{ rejectionReason }`; no term enrollment.

**Contrast — new student on same link:** `POST /pending-student-request` (+ token) → `/admin/student-requests` (~11), **not** re-enroll (~15).

---

## Endpoint contracts (target)

### `POST /center/activate-student` (public or bearer — pick one and document; live often works without JWT)

**Request**

```json
{ "token": "<uuid>", "studentId": 28 }
```

- `studentId` **number** only (string → 400 validator).
- Token must be valid, unused/unexpired, center matches student’s center, term = token term, registration window OK.

**Success (target — replace as-built)**

```json
{
  "status": 200,
  "message": "Re-enrollment request submitted successfully",
  "data": {
    "requestSubmitted": true,
    "requestId": 42
  }
}
```

**Behavior on success**

- Create `PENDING` re-enrollment request linked to: `existingUserId`, `termId` (from token), `appliedToCenterId`, snapshot fields as needed.
- **Do not** call `enrollUserInTerm`.
- **Do not** set term enrollment active yet.
- Optionally keep `isActive` unchanged until approve (or set flag only on approve — prefer **activate on approve** only).

**Business failures (envelope; often HTTP 201 + body status 400)**

| Condition | `message` (stable English ok; FE wraps `فشل الطلب: …`) | `data` |
|---|---|---|
| Already enrolled in token’s term | `Student already enrolled in this term` | `null` |
| Duplicate pending for same user+term | e.g. `Re-enrollment request already pending` | `null` or existing `requestId` |
| Invalid / expired / used token | clear reason | `null` |
| Student not found / wrong center | 404 / 400 | `null` |

**Remove as-built success shape:** `{ activated: true }` after direct enroll.

---

### Admin queue — ReEnrollment module (wire in `AppModule`)

| Method | Path | Role | Notes |
|---|---|---|---|
| `GET` | `/admin/re-enrollment-requests` | ADMIN / SYSTEM_ADMIN | Pending (and optionally filter by status) |
| `GET` | `/admin/re-enrollment-requests/{id}` | ADMIN / SYSTEM_ADMIN | 404 if missing |
| `POST` | `/admin/re-enrollment-requests/{id}/approve` | ADMIN / SYSTEM_ADMIN | See approve semantics |
| `POST` | `/admin/re-enrollment-requests/{id}/reject` | ADMIN / SYSTEM_ADMIN | Body `{ "rejectionReason": string }` **required** |

**List/detail DTO** (align existing OpenAPI `GetPendingReEnrollmentRequestDto`):  
`id`, identity/contact fields, `educationStage`, `appliedToCenterId`, `termId`, `existingUserId`, `status` (`PENDING` \| `APPROVED` \| `REJECTED`), `rejectionReason`, timestamps. Coerce string ids in FE.

---

### Approve semantics (target)

On `POST …/{id}/approve` for a `PENDING` request:

1. Validate request still `PENDING` and term still enrollable (ACTIVE / registration rules as product decides).
2. Set student `isActive = true`.
3. `enrollUserInTerm(existingUserId, termId, STUDENT)` (idempotent if race).
4. Mark request `APPROVED`.
5. Return success envelope (`data` may be null; FE re-fetches list).

**Ḥalaqa on approve — LOCKED H1 (Imad 2026-09-16)**

- Approve = set student **active** + `enrollUserInTerm` for token term **only**.
- **Not H2** — no `halqaId` on approve.
- Ḥalaqa assignment stays separate: `POST /halqa/enroll-students/{halqaId}` **ADMIN only** (authz lock B).
- UI after approve: CTA to add student to a ḥalaqa (students / ḥalaqa detail), not part of re-enroll approve.

---

### Reject semantics

- Body `{ rejectionReason }` required.
- Status → `REJECTED`; no term enrollment; student remains as before.

---

## Module / code delta (Nest)

1. Add **`ReEnrollmentModule`** (entity + service + `AdminReEnrollmentRequestController`) and import in `AppModule`.
2. Change **`CenterService.activateStudent`**: create pending row; **delete** direct `enrollUserInTerm` success path.
3. Align **controller + OpenAPI** with pending success (`requestId`) and failure messages; remove “Student activated successfully / activated:true” as happy path.
4. Approve service owns **active + term enroll** (and ḥalaqa only if H2).
5. Fix swagger drift: live/workspace swagger that already describes pending must match **code**; GitHub `main` swagger currently describes activate-as-activate — update both.

---

## Explorer proof checklist (before unpark Angular 15)

- [ ] Student **not** on new term roster (after term end + new term, or lab unenroll).
- [ ] `activate-student` → `requestSubmitted: true` + `requestId`.
- [ ] `GET /admin/re-enrollment-requests` contains that id (`PENDING`).
- [ ] Approve → student on term; request `APPROVED`; list updates.
- [ ] Reject path with reason.
- [ ] Already-on-term still 400, no new row.
- [ ] New student path still hits student-requests only.

---

## Angular until Nest A ships

- Keep **PARK** `15`.
- Ship ~10 generate/copy (host rewrite), ~16 identify, ~11 student-requests as needed.
- Do **not** drive re-enroll from `available-students`.
- After Nest A + proof: unpark 15 against this contract (H1 or H2 as locked).

---

## Locked decisions

- Product: Option **A** pending queue.
- Ḥalaqa: **H1** term-only on approve (Imad 2026-09-16).
