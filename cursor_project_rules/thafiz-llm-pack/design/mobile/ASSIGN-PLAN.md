# Assign / bind study plan — teacher mobile

**Status:** awaiting Imad lock. Flutter unbound CTA stays `قريباً` until he ships this.

Brand shell matches progress v2: Cairo · parchment `#F3EEE3` · primary `#1B4D3E` · 390×844 phone · back + ḥalaqa title · `../tokens.css`.

Entry: progress v2 unbound → **تعيين / ربط خطة دراسية**. Not a new daily-write surface. Not enroll.

## Files

| File | Role |
|---|---|
| `assign-plan.css` | Picker chrome on top of `student-progress-v2.css` |
| `assign-plan.html` | Ḥalaqa has plans — pick one, CTA «ربط بهذه الخطة» |
| `assign-plan-empty.html` | Ḥalaqa has **no** plans — no create, no enroll |
| `student-progress-v2-unbound.html` | CTA now links here |

## Why this screen

Unbound progress is empty + CTA (locked product). Step 3 is the CTA’s destination: bind **this** student to a plan that already exists on **this** ḥalaqa.

Δ vs inventing a plan editor / student roster:

| In | Out |
|---|---|
| List `GET /halqa/study-plans/{halaqaId}` | `POST /halqa/enroll-students` |
| Bind `POST /study-plan/{id}/assign-students` `{ studentIds: [thisStudent] }` | Create plan `POST /study-plan` |
| One student (the one on progress) | Multi-student picker / AvailableStudents |
| Type chips حفظ / تثبيت / مراجعة (read-only) | وحدة / اتجاه · daily إلى سورة/آية |

## Chrome

1. Topbar: back → unbound progress · ḥalaqa name (sample «نموذج عماد»)
2. Same student chip as unbound: name + حاضر + «الخطة: غير محددة»
3. Gold hint: هذا الطالب فقط · تسجيل الطلاب من الإدارة
4. Radio cards of ḥalaqa plans (name · N طلاب مربوطون · type ranges)
5. Dock «ربط بهذه الخطة» · إلغاء

Empty ḥalaqa: copy that the center must create a plan first. Outline «العودة لتسجيل التقدّم» only.

## Sample (TEST Student PriorTerm · ḥalaqa 16)

| Plan | Items |
|---|---|
| خطة نموذج عماد · 2 مربوطون | حفظ الفاتحة 1→البقرة 1 · تثبيت 2→5 · مراجعة 1–2 |
| خطة الفاتحة · 0 مربوطون | حفظ الفاتحة 1→7 |

After bind, mock jumps to `student-progress-v2.html` (editor with plan). Live: refetch `GET /study-plan/student/{id}?date=` then show the editor.

## Expected previews (parent shoots)

- `previews/assign-plan.png`
- `previews/assign-plan-empty.png`

Open locally:

```bash
python -m http.server 8765 --directory cursor_project_rules/thafiz-llm-pack/design
```

then `http://localhost:8765/mobile/assign-plan.html`
