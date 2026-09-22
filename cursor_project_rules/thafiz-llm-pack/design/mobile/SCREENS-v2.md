# Teacher mobile UI v2 — Login + Home shell

**Scope:** visual identity pass only (low-token). No new product flows.  
**Brand lock:** Damascus Paradise B — Cairo · تحفيظ · mark «ت» · primary `#1B4D3E` · accent gold rare.  
**Sources:** `mobile-walk/04-login.png`, `04-home.png` + `MOBILE-TEACHER-NOTES.md`.

## Δ vs old captures

### Login (`login.html` ← `04-login.png`)
| Before | After |
|---|---|
| Generic green circle + book glyph | Brand mark **ت** in bottle green circle; product name **تحفيظ** under welcome |
| Default system sans | **Cairo** |
| Flat white / generic green CTA | Parchment surface `#F3EEE3`; primary CTA `#1B4D3E`; soft field chrome |
| Copy: تسجيل الدخول · مرحباً بك · سجل دخولك للمتابعة · بريد · كلمة مرور · روابط | **Same copy + same fields + same links** (no flow invent) |

### Home + bottom nav (`home-shell.html` ← `04-home.png`)
| Before | After |
|---|---|
| Title-only top; no product brand | Compact top brand: mark **ت** + **تحفيظ** |
| Plain white card + green «التفاصيل» chip | Same ḥalaqa card structure (name · عدد طلاب · التفاصيل); brand-soft chip |
| Bottom nav: 3 tabs (الملف الشخصي / خطة الدراسة / الصفحة الرئيسية), active green | **Same 3 tabs, same RTL order, same labels**; active = primary green |
| Default sans | Cairo throughout |

## Out of scope (this pass)
Attendance/progress editors, ḥalaqa detail, Flutter implementation, full app dump.

## Files
- `login.html`
- `home-shell.html`
- Previews under `previews/`

---

## تفاصيل الحلقة / الطلاب (`halaqa-detail.html` ← `05-halaqa.png`)

| Before | After |
|---|---|
| Default sans · bright generic green | **Cairo** + Brand B `#1B4D3E` / parchment `#F3EEE3` (same language as login/home-shell) |
| Header «المعلم» + back | **Same title + RTL back** (no new chrome) |
| Date `2024-09-10` in capture | Restyle keeps structure; mock uses **`2026-09-10`** (locked year fix from notes — not a flow change) |
| Student card: accent bar · اسم · شارة حاضر · نسب 0% · سهم | **Same card anatomy**; brand-soft «حاضر» chip; primary accent bar; muted chevron |
| Bottom «تعديل» full-width green | Same CTA, primary bottle green |
| No bottom nav on this screen | **Still none** (detail push, as in capture) |

Out of scope: attendance chip editors / progress editors (next pages when Imad asks).

### Improve pass — `halaqa-detail.html` (Imad ask)

**Recommendations considered**
1. **Attendance-first card** — حاضر beside the name, larger; metrics quiet chips (not one red line). *Why:* daily marking is attendance-gated; 0% should not look like an error.
2. **Roster count** next to «الطلاب». *Why:* teacher sanity-checks “who’s on today’s list” before marking.
3. **Avatar initials** on the card. *Deferred* — nicer but more invent for this low-token pass.

**Applied (Δ)**
- حاضر moved up next to the name (bigger chip); metrics split into 3 quiet chips (الحفظ / المراجعة / التثبيت) in muted ink — no alarm red
- Count pill «1» beside «الطلاب»
- Same flows: header المعلّم + back, date, card chevron, bottom تعديل; no bottom nav; no editors

### Color legend — metric chips (`halaqa-detail.html`)

**خطة النوع (chip chrome / label)**
- حفظ → bottle green soft (`#E4F0EA` / `#1B4D3E`)
- تثبيت → teal-green soft (`#E3F2E9` / `#2E7D57`)
- مراجعة → gold soft (`#F8EFCF` / `#8A6A12`)

**نسبة % (value only — cleaner than recoloring the whole chip)**
- منخفض 0–33 → muted gray-green
- متوسط 34–66 → mid tint of that type
- مرتفع 67–100 → strong tint of that type

«حاضر» = soft light-green badge (restored from `05-halaqa.png`), not solid primary.

Sample % on the mock card (62 / 35 / 0) illustrate the scale for visual lock; live may be all 0%.

---
**LOCKED** تفاصيل الحلقة / الطلاب (`halaqa-detail.html`) — Imad 2026-09-17. Chip colors included. No further visual changes unless he asks.

---

## محرّر حضور الطالب (`student-attendance.html` ← `14-attendance-edit.png`)

| Before | After |
|---|---|
| Default sans · bright green | Cairo + Brand B parchment / `#1B4D3E` |
| حاضر selected = green outline family | **Soft light-green «حاضر»** (locked with حلقة detail); selected gets slightly stronger border in same family |
| غائب / متأخر / معذور gray chips | Same compact pills; **4 statuses only** (LEAVE→معذور — no إجازة) |
| Metrics as red essay line | Compact plan-type chips (حفظ/مراجعة/تثبيت) matching locked حلقة detail |
| Header المعلّم + back · الطلاب + date · card · تعديل | **Same flow/copy** — no bottom nav, no progress editors |

Mock chips are tap-toggle for review only (single-select).

---
**LOCKED** محرّر حضور الطالب (`student-attendance.html`) — Imad 2026-09-17. No further visual changes unless he asks.

---

## محرّر تقدّم الطالب (`student-progress.html`) — **LOCKED**

**Status:** **LOCKED** Imad 2026-09-17 — teacher fill (إلى سورة/آية; مراجعة list). No further visual changes unless he asks.

| Piece | Choice |
|---|---|
| Shell | Same as attendance: المعلّم + back · الطلاب + date · student card |
| Attendance | Shown **committed / read-only** (حاضر) |
| Plan types | Tab chips حفظ / تثبيت / مراجعة with **locked type colors** |
| Plan block | **Read-only**: range + المقدار المطلوب اليوم |
| Teacher fill | **إلى سورة + إلى آية only** — حفظ/تثبيت: one pair · مراجعة: list (+ إضافة / إزالة) |
| Out | No وحدة/اتجاه · no hint text · no bottom nav |
| Previews | `previews/student-progress.png` (مراجعة list) · `previews/student-progress-hifz.png` (حفظ pair) |

**Imad reopen (2026-09-17):** Plan stays assigned/read-only; teacher records how far the student reached today via إلى سورة / إلى آية.


---

## تسجيل المعلم (`teacher-signup-*.html`) — **LOCKED**

**Status:** **LOCKED** Imad 2026-09-20 — Brand-B teacher signup mocks. No further visual changes unless he asks.

### Pager decision — keep clear 4-step pager (4 dots)

**Rationale:** Legacy APK screenshots show **4 dots** and **4 distinct screens**. Merging steps would bury fields (credentials checkboxes + personal + availability). Active step = elongated pill/dot in primary `#1B4D3E`; others muted circles. Dots sit **above** the primary CTA (APK pattern). RTL: step 1 on the right → step 4 on the left.

### Fields per step (field-accurate to APK)

| Step | File | Fields / controls | CTA |
|---|---|---|---|
| 1 | `teacher-signup-1-account.html` | اسم المعلم · البريد الإلكتروني · كلمة المرور (eye) · كلمة المرور confirm (eye; visible label same as APK; `aria-label` تأكيد كلمة المرور) — sample: `test` / `testto@gmail.com` / masked | التالي |
| 2 | `teacher-signup-2-credentials.html` | Dropdowns: المؤهل (الدبلوم) · مستوى التجويد (متقدم) · مركز العمل (Simon test). Checkboxes (all checked): شهادة خاتم مكنون… · إجازة في الحفظ · سند في الحفظ. Back chevron | التالي |
| 3 | `teacher-signup-3-personal.html` | الجنسية (أفغانستان) · العنوان (yyrrdd) · رقم الهاتف (+558 89 965 5) · تاريخ الميلاد (20-09-2026) · عدد الأجزاء المحفوظة (2). Back chevron | التالي |
| 4 | `teacher-signup-4-availability.html` | Age groups: ابتدائية 6-11 ✓ · المتوسطة 12-14 · الثانوية 15-17 · الجامعية 18-22 · الكبار 23 فما أعلى. Section **فترة العمل المتاحة** (green accent bar on RTL start). Work: أيام العمل الأسبوعية (أحد–خميس) ✓ · بعد الفجر (ساعتين) ✓ · بعد العصر · بعد المغرب · بعد العشاء. Back chevron | **تسجيل** |

Footer on all steps: `هل لديك حساب؟ تسجيل الدخول` → `login.html`. Shared chrome: `teacher-signup.css` + `../tokens.css` · Cairo · parchment · 390×844 phone · mark «ت» + تحفيظ.

### Nest hint (Flutter wire)

- Public intake: **`POST /pending-teacher-request`** (and/or app path `/register`).
- Map UI → `CreatePendingTeacherRequest` / pending-teacher-request body (confirm exact swagger names with Tech Lead before Flutter wire):
  - اسم المعلم → `teacherName`
  - البريد / كلمة المرور → `email` / `password`
  - المؤهل → `qualification` (e.g. DIPLOMA)
  - مستوى التجويد → `tajweedLevel`
  - مركز العمل → `centerId`
  - شهادة خاتم / إجازة / سند → `hasCertificate` / `hasIjazahInHifz` / `hasSanadInHifz`
  - الجنسية / العنوان / الهاتف / الميلاد / الأجزاء → `nationality` / `address` / `phone` / `birthDate` / `numberOfMemorizedJuz`
  - الفئات العمرية → `teachingAgeGroup[]`
  - فترة العمل → `availableWorkPeriod[]` (e.g. WEEKDAYS, AFTER_FAJR, …)

### Preview paths (once shot)

- `previews/teacher-signup-1-account.png`
- `previews/teacher-signup-2-credentials.png`
- `previews/teacher-signup-3-personal.png`
- `previews/teacher-signup-4-availability.png`

**Out of scope:** OTP, success screen, extra steps, edits to locked login/home/halaqa/attendance/progress mocks.

---

## تفاصيل الحلقة v2 — 3 top tabs (`halaqa-detail-v2-*.html`) — awaiting Imad lock

**Status:** awaiting Imad lock. Old `halaqa-detail.html` remains **LOCKED** until Imad accepts v2.

**Shared:** `halaqa-detail-v2.css` · Brand B shell (Cairo · parchment · `#1B4D3E` · 390×844 · المعلم + back · `../tokens.css`).

### Chrome (all 3 previews)

| Piece | Notes |
|---|---|
| Ḥalaqa title | «حلقة الفجر» + count pill **4 طلاب** |
| Date | Pill `2026-09-10` **above** tabs; caption «أيام العمل أحد–خميس · يتخطى الجمعة/السبت والعطل» (no full calendar UI) |
| Tabs (RTL) | **الحضور** (first / rightmost) · التقدم · نظرة عامة — equal pills; active = primary outline |

**Why الحضور first:** daily open → take attendance; progress second; overview is reference.

### Tab table

| Tab | File | Content |
|---|---|---|
| الحضور | `halaqa-detail-v2-attendance.html` | Summary: حاضر 2 · غائب 1 · متأخر 0 · معذور 1 · الكل 4. View badges → **تعديل الحضور** → att-chips → **حفظ الحضور**. Soft light-green حاضر. `?edit=1` starts edit. |
| التقدم | `halaqa-detail-v2-progress.html` | Date kept; no att summary. Rows: name + حفظ/مراجعة/تثبيت % chips. Per-row **تسجيل تقدّم** → locked `student-progress.html`. No bulk save. |
| نظرة عامة | `halaqa-detail-v2-overview.html` | Meta card (حلقة الفجر · أحد–خميس · 4 طلاب) + names-only roster. No save CTA. |

### Attendance edit/save rationale

Recommend **view → تعديل الحضور → chip edit → حفظ الحضور** over always-live chips: teachers scroll a lot; accidental flips are costly; matches locked per-student attendance editor (commit intentionally). Always-on chips faster for tiny lists, weaker at 20+.

### Tab C rationale — نظرة عامة (not الخطط)

Daily work = attendance + progress. Third tab answers «ما هذه الحلقة ومن فيها؟» without competing with action tabs. Plans (الخطط) are rarer / often admin-owned — keep out of daily chrome unless Imad asks.

### Sample students (consistent)

1. TEST Student CoS — حاضر · 2. أحمد محمد — غائب · 3. سارة علي — معذور · 4. خالد يوسف — حاضر

### Expected previews (parent shoots PNGs)

- `previews/halaqa-detail-v2-attendance.png`
- `previews/halaqa-detail-v2-progress.png`
- `previews/halaqa-detail-v2-overview.png`
- Optional: attendance-edit via `?edit=1`

See also: `HALAQA-DETAIL-V2.md`.

---

## محرّر تقدّم الطالب v2 (`student-progress-v2-*.html`) — awaiting Imad lock

**Status:** Imad asked to ship. Old `student-progress.html` remains **LOCKED**. Flutter editor is the v2 wire.

**Shared:** `student-progress-v2.css` + `../tokens.css` · 390×844 · Cairo · parchment · `#1B4D3E`.

| File | Content |
|---|---|
| `student-progress-v2.html` | حفظ pair |
| `student-progress-v2-tathbeet.html` | تثبيت pair |
| `student-progress-v2-murajaa.html` | مراجعة list |
| `student-progress-v2-unbound.html` | empty + CTA → assign-plan |

Δ vs locked editor: drop the 4 attendance chips (ḥalaqa v2 الحضور owns them); one حاضر badge; readable type tabs; term % chips; date pill; «لم يُسجَّل اليوم» / «تم اليوم». Product fill locks unchanged (إلى سورة / إلى آية · no وحدة/اتجاه).

See `STUDENT-PROGRESS-V2.md`.

---

## تعيين / ربط خطة دراسية (`assign-plan*.html`) — awaiting Imad lock

**Status:** awaiting Imad lock. Flutter CTA on unbound progress stays `قريباً`.

**Shared:** `assign-plan.css` + `student-progress-v2.css` + `../tokens.css` · 390×844 · Cairo · parchment · `#1B4D3E`.

| File | Content |
|---|---|
| `assign-plan.html` | Pick a ḥalaqa plan · CTA «ربط بهذه الخطة» |
| `assign-plan-empty.html` | No plans on ḥalaqa · no create · no enroll |

In: `GET /halqa/study-plans/{halaqaId}` then `POST /study-plan/{id}/assign-students` `{ studentIds: [thisStudent] }`. Out: enroll-students, create-plan, multi-student picker.

See `ASSIGN-PLAN.md`.
