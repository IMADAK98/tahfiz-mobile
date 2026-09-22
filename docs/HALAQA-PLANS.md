# Teacher mobile — ḥalaqa plans management (الخطط)

**Status:** LOCKED by Imad 2026-09-22 (styled create/assign; no إلى on create; entry from نظرة عامة).
**Date:** 2026-09-22.  
**Δ:** Teacher manages plans. Create: from-only (no إلى). **2026-09-22b:** fixed form chrome (`.control` + type pills + full-width footer) after Imad unstyled complaint.

## Placement decision

| Chosen | Not chosen |
|---|---|
| Entry from **نظرة عامة** → dedicated `halaqa-plans.html` | 4th segmented tab (crowds locked daily chrome) |
| | Replacing نظرة عامة with plans |

**Rationale (plain):** Daily work stays **الحضور / التقدم**. Plans management is secondary but full CRUD + assign — open from overview, not a 4th tab.

## Files

| File | Role |
|---|---|
| `halaqa-detail-v2-overview-plans-entry.html` | Proposed overview Δ — «الخطط» row → plans list. **Does not replace** locked `halaqa-detail-v2-overview.html` until Imad accepts. |
| `halaqa-plans.html` | Plans list + expand/collapse + delete/unassign confirm dialogs (`?empty=1`, `?delete=1`) |
| `halaqa-plans-create.html` | Create form (name + items) |
| `halaqa-plans-assign.html` | Assign students from ḥalaqa roster |
| `halaqa-plans.css` | Shared styles (with `halaqa-detail-v2.css`) |
| `HALAQA-PLANS.md` | This note |

**Do not modify (LOCKED):** `halaqa-detail-v2-overview.html` / attendance / progress / `halaqa-detail-v2.css`, `student-attendance.html`, `student-progress.html`, login, home, teacher-signup-*. Do not redesign attendance/progress forms.

## Teacher can

| Action | Screen / UI | Nest (teacher JWT) |
|---|---|---|
| List + expand/collapse | `halaqa-plans.html` | `GET /halqa/study-plans/{halqaId}` |
| Create plan | `halaqa-plans-create.html` | `POST /study-plan` |
| Delete plan | Confirm dialog on list | `DELETE /study-plan/{id}` |
| Assign students | `halaqa-plans-assign.html` | `POST /study-plan/{id}/assign-students` |
| Unassign student | Confirm dialog on chip «إزالة» | `DELETE /study-plan/{id}/unassign-students` |

### Create form fields

- اسم الخطة  
- Items (1+): type **حفظ / تثبيت / مراجعة** · **من سورة / من آية** only · amount type (أسطر/صفحات) + value  
- At most **one item of each type** (1 HIFZ + 1 TATHBEET + 1 MURAJAA). A second of the same type is refused. «+ إضافة عنصر» adds an unused type only (max 3).
- **Create does not ask for «إلى».** List/expand may still **display** computed from→to if Nest returns it.

- Assign students **after** save (separate screen) — keeps create form mobile-length

### List vs expand (align admin page 18)

| State | Shows |
|---|---|
| **Collapsed** | Plan name · student-count pill · type chips summary · chevron |
| **Expanded** | Full item list with **from→to** ranges + amounts · assigned students (with إزالة) · **إضافة طلاب** · **حذف الخطة** |

### Ranges (expanded)

Always full from→to: `من الفاتحة آية 1 → إلى البقرة آية 1` (same pattern as locked `student-progress.html`).

## Nest (Tech Lead matrix — 2026-09-22)

Teacher JWT **can already** call:
- `POST /study-plan` (create: name, halqaId, studyPlanItems[], optional studentIds enrolled in ḥalaqa)
- `DELETE /study-plan/{id}`
- `POST …/assign-students` · `DELETE …/unassign-students`
- `GET /halqa/study-plans/{halqaId}` · `GET /study-plan/{id}/details`
- `PUT /study-plan-item/{id}`

Prefer list + details endpoints; ignore stub `GET/PATCH /study-plan/{id}`.

**UI constraint:** Nest does **not** yet enforce assigned-ḥalaqa ownership — only show plans for ḥalaqāt this teacher teaches (client-side scope).

**Create body (Nest locked 2026-09-22):** POST items send `type`, `direction`, `fromSurah`, `fromAyah`, `amountType`, `amountValue` only — **omit to***. Nest computes `to*`. List/expand **display** `to*` from response.


## Brand

Cairo · parchment `#F3EEE3` · primary `#1B4D3E` · type chips:

- حفظ → `#E4F0EA` / `#1B4D3E`  
- تثبيت → `#E3F2E9` / `#2E7D57`  
- مراجعة → `#F8EFCF` / `#8A6A12`

## Expected previews (parent shoots PNGs)

- `previews/halaqa-overview-plans-entry.png`  
- `previews/halaqa-plans.png` (expanded + collapsed; actions visible)  
- `previews/halaqa-plans-create.png`  
- `previews/halaqa-plans-assign.png`  
- Optional: `previews/halaqa-plans-delete.png` via `?delete=1`

## Lock bullets for Imad

1. Keep **3 tabs**; plans open from نظرة عامة via «الخطط» — not a 4th tab.  
2. Teacher **manages** plans: create · delete (confirm) · assign · unassign.  
3. Create = name + items (type · from surah/ayah · amount — no «to»); assign is a separate screen from ḥalaqa roster.  
4. Collapsed = summary; expanded = full from→to items + students + actions.  
5. Overview entry file stays a **proposed delta** until you merge it into locked overview.
