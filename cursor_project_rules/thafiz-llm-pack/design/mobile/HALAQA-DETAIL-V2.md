# Ḥalaqa detail v2 — teacher tabs

**Status:** awaiting Imad lock.  
**Old screen:** `halaqa-detail.html` remains **LOCKED** until Imad accepts v2 (do not delete or restyle it).

Brand shell matches locked login / halaqa-detail: Cairo · parchment `#F3EEE3` · primary `#1B4D3E` · 390×844 phone · topbar «المعلم» + back · tokens via `../tokens.css`.

## Files

| File | Role |
|---|---|
| `halaqa-detail-v2.css` | Shared chrome |
| `halaqa-detail-v2-attendance.html` | Tab الحضور (default daily) |
| `halaqa-detail-v2-progress.html` | Tab التقدم |
| `halaqa-detail-v2-overview.html` | Tab نظرة عامة |

## Shared layout (all 3)

1. Topbar: back · المعلم  
2. Ḥalaqa title row: «حلقة الفجر» + count pill (**4 طلاب**)  
3. **Date pill** `2026-09-10` **above** the tabs (day-scoped for attendance + progress)  
4. Tiny caption: «أيام العمل أحد–خميس · يتخطى الجمعة/السبت والعطل» — locked calendar behavior hint only; **no full calendar UI** in this mock  
5. Segmented top tabs (3 equal pills; active = primary outline)

### Tab order (RTL)

Visual order right→left: **الحضور** · **التقدم** · **نظرة عامة**.

**Why الحضور first:** daily marking starts with who’s here; progress is second; overview is reference. Putting الحضور rightmost (RTL start) matches “open ḥalaqa → take attendance” muscle memory.

## Tabs

| Tab | File | What it shows |
|---|---|---|
| الحضور | `…-attendance.html` | Summary chips + student list with attendance status; edit/save |
| التقدم | `…-progress.html` | Plan-type % metrics; per-row entry to locked `student-progress.html` |
| نظرة عامة | `…-overview.html` | Ḥalaqa meta + names-only roster |

### Sample attendance totals (mock)

حاضر **2** · غائب **1** · متأخر **0** · معذور **1** · الكل **4**

Students (same across tabs):

1. TEST Student CoS — حاضر  
2. أحمد محمد — غائب  
3. سارة علي — معذور  
4. خالد يوسف — حاضر  

Chip set locked: حاضر / غائب / متأخر / معذور (LEAVE→معذور). Soft light-green for حاضر.

---

## Attendance UX — view → edit → save

**Recommendation:** default **view mode** (locked badges) → CTA **تعديل الحضور** → 4 tappable att-chips → **حفظ الحضور**.

**Why not always-live chips:**
- Teachers scroll long rosters; accidental status flips are costly (wrong غائب sticks in reports).
- Matches the existing locked per-student attendance editor mental model: change intentionally, then commit.
- Always-on chips are faster for tiny lists (≤5) but weaker at **20+** students.

Mock: default screenshot = view. Tiny mock toggle + `?edit=1` deep-link for optional edit preview.

---

## Tab C choice — نظرة عامة (not الخطط)

**For Imad (plain):**

Daily work is **attendance + progress**. The third tab should answer «ما هذه الحلقة ومن فيها؟» without competing with the two action tabs.

- **نظرة عامة** = ḥalaqa meta (name, schedule hint أحد–خميس, student count) + simple roster (names only, no chips/actions).  
- **الخطط (Plans)** are rarer for teachers and often admin-owned — keep out of daily chrome unless Imad asks later.

---

## Progress tab notes

- Date pill stays visible (progress is day-scoped).  
- No attendance summary strip.  
- Row action **تسجيل تقدّم** / **تعديل** is an entry point only → locked `student-progress.html` until progress v2 is accepted (`STUDENT-PROGRESS-V2.md`).  
- No bulk save CTA (saves happen on the progress form).  
- Tiny hints «لم يُسجَّل اليوم» / «تم اليوم» are layout-only.

---

## Expected preview paths (parent will shoot)

- `previews/halaqa-detail-v2-attendance.png`  
- `previews/halaqa-detail-v2-progress.png`  
- `previews/halaqa-detail-v2-overview.png`  
- Optional later: `previews/halaqa-detail-v2-attendance-edit.png` via `?edit=1`
