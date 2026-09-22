# Student progress v2 — teacher daily editor

**Status:** Imad asked to ship on the existing student progress route. Old `student-progress.html` remains **LOCKED** as v1.

Brand shell matches ḥalaqa-detail v2: Cairo · parchment `#F3EEE3` · primary `#1B4D3E` · 390×844 phone · back + ḥalaqa title · `../tokens.css`.

Entry: ḥalaqa v2 tab التقدم → **تسجيل تقدّم**. No new route.

## Files

| File | Role |
|---|---|
| `student-progress-v2.css` | Shared chrome |
| `student-progress-v2.html` | حفظ — one إلى سورة / إلى آية pair |
| `student-progress-v2-tathbeet.html` | تثبيت — same pair layout |
| `student-progress-v2-murajaa.html` | مراجعة — list + إضافة / إزالة |
| `student-progress-v2-unbound.html` | No plan — empty + CTA → `assign-plan.html` |

## Why a v2 (vs locked editor)

Locked `student-progress.html` copies the old combined student card: 4 attendance chips + type pills on one form. After ḥalaqa v2, الحضور already owns marking. This page is **daily write of HIFZ / TATHBEET / MURAJAA only**.

Δ from v1:

| v1 (locked) | v2 (this mock) |
|---|---|
| 4 read-only attendance chips | One **حاضر** badge next to the name (committed status). Edit attendance on ḥalaqa tab الحضور |
| Type pills can fill solid and hide the label | Equal segmented tabs; **label always visible**; active = type-soft fill + type border |
| No term % on the editor | Quiet chips حفظ / مراجعة / تثبيت = **term-to-date** (`GET /reports/progress` dates, not that day’s `*_percentage`) |
| «الطلاب» leftover label | Date pill above the card (same language as ḥalaqa v2) |
| No today hint | «لم يُسجَّل اليوم» / «تم اليوم» under the type tabs |

## Product locks that stay

- Plan block **read-only** (range + المقدار المطلوب اليوم).
- Teacher fills **إلى سورة + إلى آية only**.
- حفظ / تثبيت: one pair. مراجعة: list (+ إضافة / إزالة).
- No وحدة / اتجاه.
- Unbound plan = empty + CTA «تعيين / ربط خطة دراسية», never a blank screen. Mock destination: `ASSIGN-PLAN.md` (awaiting lock).
- CTA **حفظ التقدّم** (saves current type). Nest: `POST/PUT /student-daily-progress` · مراجعة `…/murajaa-plan`.

## Chrome

1. Topbar: back · ḥalaqa name (sample «نموذج عماد»)
2. Date pill `2026-09-20` · caption «يوم التسجيل · أحد–خميس»
3. Card: name + حاضر badge · term % chips · type tabs · today hint · plan · fill · dock CTA

### Type tabs (RTL visual)

Right → left: **حفظ** · **تثبيت** · **مراجعة**. Active uses locked type colors (حفظ bottle · تثبيت teal · مراجعة gold). Never paint the tab solid with no text.

## Sample (TEST Student PriorTerm · ḥalaqa 16)

| Type | Plan (read-only) | مقدار | Fill |
|---|---|---|---|
| حفظ | من الفاتحة آية 1 → إلى البقرة آية 1 | 1 صفحة | البقرة / 17 · لم يُسجَّل اليوم |
| تثبيت | من الفاتحة آية 2 → إلى البقرة آية 5 | 1 صفحة | البقرة / 5 · تم اليوم |
| مراجعة | الفاتحة 1–2 | 1 سطر | list · تم اليوم |
| Term % | حفظ 59 · مراجعة 100 · تثبيت 100 (clamp >100) | | |

## Expected previews (parent shoots)

- `previews/student-progress-v2-hifz.png`
- `previews/student-progress-v2-tathbeet.png`
- `previews/student-progress-v2-murajaa.png`
- `previews/student-progress-v2-unbound.png`

Open locally:

```bash
python -m http.server 8765 --directory cursor_project_rules/thafiz-llm-pack/design
```

then `http://localhost:8765/mobile/student-progress-v2.html`

Unbound CTA opens `mobile/assign-plan.html`.
