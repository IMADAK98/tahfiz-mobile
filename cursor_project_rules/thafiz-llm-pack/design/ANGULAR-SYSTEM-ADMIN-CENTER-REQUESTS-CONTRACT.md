# Angular FE contract — SYSTEM_ADMIN center requests

**Nest truth:** `localization-refactor` + live `tahfiz.onrender.com`.  
**Source:** Nest `AdminCenterRequestController` + `PendingCenterRequestService.approveRequest` on `localization-refactor`.

**Role:** **`SYSTEM_ADMIN` only** (`@Roles(RoleEnum.SYSTEM_ADMIN)`). Center `ADMIN` → **403**. Separate from center-admin `/admin/*` shell.

---

## Endpoints

| Action | Method + path | Body |
|---|---|---|
| List all requests | `GET /system-admin/center-requests` | — |
| Approve | `POST /system-admin/center-requests/{id}/approve` | empty |
| Reject | `POST /system-admin/center-requests/{id}/reject` | **`{ rejectionReason: string }` required** |

- No query filter for pending-only — Nest `findAll()` returns **all** rows. FE should default-filter / tab to `status === 'PENDING'` for the accept queue (live dashboard cards = pending).
- Path `id` = pending-request id (coerce `string→number`).
- Approve / reject often return **`data: null`** → re-list.
- Public intake (out of scope for this UI): `POST /pending-center-request` (creates PENDING; `data:null` on create).
- Resend activation (optional later): `POST /pending-center-request/resend-activation` `{ email }`.

---

## What approve does (Nest as-built)

In one transaction:

1. Create **Center** `{ name: centerName, address: centerAddress, isActive: true }`.
2. Create **ADMIN** user from request admin fields (`isActive: false`) + `AdminProfile`, linked to that center.
3. Issue activation token; email activation link (`FRONTEND_URL/activate?token=…`).
4. Mark request `APPROVED` and set `center` relation.

Reject: set `status=REJECTED` + `rejectionReason` only (no center/user created).

---

## Card / list fields (entity — no Students/Terms/Ḥalaqāt counts)

There are **no** `studentsCount` / `termsCount` / `halaqatCount` on this list. Pending centers have no term/ḥalaqa yet (counts would be 0). Do **not** invent KPI counters from this endpoint.

**Fields on each row (`PendingCenterRequest`):**

| Field | Notes |
|---|---|
| `id` | request id (`number \| string`) |
| `centerName` | center name |
| `centerAddress` | center address |
| `adminName` | center-admin name |
| `adminEmail` | |
| `adminPhone` | |
| `adminIdentificationNumber` | nullable |
| `adminPassportNumber` | nullable |
| `adminBirthDate` | nullable string |
| `adminNationality` | nullable |
| `adminAddress` | nullable |
| `status` | `PENDING` \| `APPROVED` \| `REJECTED` |
| `rejectionReason` | nullable; set on reject |
| `centerId` | set after approve (nullable while PENDING) |
| `createdAt` / `updatedAt` | BaseEntity |

**UI mapping for live cards:** center block ← `centerName` + `centerAddress`; admin block ← `adminName` / `adminEmail` / `adminPhone` (+ ID/passport/nationality as detail). Status badge ← `status`. Accept/Reject only when `PENDING`.

---

## FE notes

1. New **system-admin** route (not under center `/admin` shell) — e.g. `/systemadmin/dashboard` or `/system-admin/center-requests`; guard = JWT role `SYSTEM_ADMIN` only.
2. Coerce ids; SKIP_GLOBAL_ERROR_TOAST on reject form; feature success toasts; required سبب الرفض.
3. Nest truth = localization-refactor + live only.
