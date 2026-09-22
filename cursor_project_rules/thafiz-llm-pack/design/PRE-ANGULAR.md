# Pre-Angular sprint — Thafiz

**Scope:** center-admin web rewrite only (نظام التحفيظ). Not Focused/Routine. Teacher daily attendance/progress stays Flutter.

**Sources read:** `FOUNDATIONS.md`, `tokens.css`, `README.md`, `BATCH2.md`, HTML `01`–`16`, `mobile/unbound-plan-empty.html`. RTL research (2025–2026): Angular Material MDC + CDK `Directionality`; PrimeNG RTL guide (`dir` / Flex logical props); Spartan/ng-primitives RTL docs rolling out 2026.

---

## 0 Status — **FULLY LOCKED** (Imad / CoS 2026-09-11)

| Item | Status |
|---|---|
| Kit | **LOCKED: PrimeNG** (Material runner-up) |
| Brand | **LOCKED B Damascus Paradise** — `#1B4D3E` / gold `#D4AF37` rare / adobe `#8B4A3A` / parchment `#F3EEE3` / ink `#15241C` / **Cairo** |
| MVP scope §5 | **All locked** — see below |
| Product locks | One ACTIVE term + **إنهاء الدورة in v1**; ADMIN/SYSTEM_ADMIN for create/assign/enroll/reg-link; host **`https://www.tahfiz.work`** |
| This doc | Pre-Angular decisions complete. HTML mocks remain source of truth; Figma deferred |
| Angular Dev | **Stand by** for CoS build brief / staffing |

**MVP scope locks (Imad 2026-09-11):**
1. **PARK** `15-re-enrollment` + `mobile/unbound-plan-empty` for web v1
2. **Ḥalaqa detail + Plans tab IN v1** (no new HTML mock — extend `05` route)
3. **Center signup** = landing CTA only (no full mock)
4. Production host always **`https://www.tahfiz.work`**
5. **«إنهاء الدورة» IN v1** (not only disabled-create messaging)
6. Kit = **PrimeNG** (already locked)

**Blockers for Angular start:** none on Designer side — awaiting CoS Angular build brief / Dev staffing. Pair with `API-SCREEN-MAP.md` (Tech Lead).

---

## 1 Kit recommendation (table + verdict)

### Comparison (Thafiz needs: RTL Arabic, tables, forms, dialogs, chips, empty states)

| Criterion | Angular Material (MDC) | PrimeNG | Spartan UI / ng-primitives |
|---|---|---|---|
| RTL maturity | Strong via CDK `Directionality` + `dir="rtl"`. Occasional component bugs (e.g. drawer `position="end"` regression fixed in Material 19.x; sliders historically flaky — irrelevant for admin). | **Documented first-class RTL** — set `dir="rtl"`; Flex + logical CSS; no JS config. Table resize/frozen had 2026 RTL fixes/issues — MVP lists/reports do not need frozen columns. | RTL docs/previews added ~2026; layout mostly Tailwind logical utils; behavior still depends on CDK Directionality for some widgets. Newer surface area. |
| Data tables | `mat-table` + sort/paginator — adequate, more DIY for filter bars / dense reports | **`p-table`** — filter, sort, paginate, empty message — maps 1:1 to teachers/students/requests/reports | Build table yourself on primitives — high control, high cost |
| Forms / selects / chips | `mat-form-field`, `mat-select`, `mat-chip-set` — solid; multi-select chips need composition | `p-inputText`, `p-select` / `p-multiSelect`, `p-chip`, `p-datepicker` — admin-complete | Headless + Helm — full token control, more wiring |
| Dialogs / toasts | `MatDialog`, `MatSnackBar` | `p-dialog` / `DynamicDialog`, **`p-toast`** (copy «تم النسخ») | Dialog + toast = custom or thin wrappers |
| Shell / nav | `mat-sidenav` (right = `position="end"` under RTL) | `p-menu` / layout DIY or PrimeBlocks-style shell | Full custom shell |
| Theming to teal+gold + warm surface | Excellent SCSS/CSS-var theming | Doable via PrimeNG design tokens / preset override — more fight vs Material for parchment aesthetic | Best visual match to `tokens.css` if timeline allows |
| DX / risk for v1 | Official Angular, large community | Admin-oriented; heavier bundle; still pragmatic | Novelty + build time — poor fit for sprint |

### Verdict: **PrimeNG** — **LOCKED by Imad 2026-09-11**

**Why for Thafiz (not novelty):** MVP admin is **list + filter + approve + report** heavy (`07`–`08`, `10`–`11`, `13`–`14`) plus multi-select chips in create-ḥalaqa (`06`) and toast-confirmed reg-link copy (`10`). PrimeNG ships those primitives with documented RTL. Material is a close second (better brand theming, thinner tables). Spartan only wins if Imad explicitly wants pixel-perfect control and accepts longer UI build — **not recommended for this sprint**.

**Adoption rules (locked):**
- Root: `lang="ar"` `dir="rtl"`; Western digits `0–9` for ops dates/IDs (FOUNDATIONS §3).
- Theme: map CSS variables from §2 into a PrimeNG preset (primary = teal; accent/gold sparingly; surface = warm).
- Avoid frozen/resizable table features until RTL QA passes on chosen PrimeNG major.
- Empty states stay **Thafiz custom** (copy + CTA) — kit only supplies layout slot / `p-table` empty template.

**Runner-up:** Angular Material — switch only if team strongly prefers official CDK theming and accepts more table DIY.

---

## 2 Tokens (locked vs provisional)

Source of truth today: `tokens.css` + FOUNDATIONS §4–6. Tighten for Angular theme bridge.

### Brand colors — **LOCKED B** Damascus Paradise / فسيفساء دمشق (see `brand/`)

| Token | Value | Use |
|---|---|---|
| `--color-primary` | `#1B4D3E` | Primary buttons, active nav, brand mark |
| `--color-primary-hover` | `#143B30` | Hover |
| `--color-primary-soft` | `#E4F0EA` | Active nav / soft fills |
| `--color-accent` | `#D4AF37` | Gold leaf — **rare** only |
| `--color-accent-soft` | `#F7EFCF` | Soft gold wash |
| `--color-secondary` | `#8B4A3A` | Adobe terracotta secondary |
| `--color-secondary-soft` | `#F3E6E1` | Soft adobe |
| `--color-surface` | `#F3EEE3` | Parchment page |
| `--color-surface-elevated` | `#FFFDF8` | Cards |
| `--color-text` | `#15241C` | Ink |
| Font family | **Cairo** | All admin UI |
| Direction | `dir="rtl"` `lang="ar"` | Root |
| One ACTIVE term UX | Disable create + «أنهِ الدورة الحالية أولاً» | Product lock |
| Reg host | Always **`https://www.tahfiz.work`** | Product lock |

### Provisional (OK to refine in Angular theming pass)

| Token / scale | Current | Note |
|---|---|---|
| Surface warm | `#F7F4EF` | Likely keep; confirm vs PrimeNG surface steps |
| Elevated / cards | `#FFFFFF` | Keep |
| Text / muted / border | `#1A1F1C` / `#5C675F` / `#E4DDD3` (+ strong `#C9C2B6`) | May add `--color-placeholder: #9AA39C` (already in CSS) |
| Semantic | danger / success / warning + soft pairs | Align to PrimeNG severity names |
| Spacing scale | 4 / 8 / 12 / 16 / 24 / 32 / 48 | Map to `--space-1`…`--space-7` |
| Radii | card 12 · input 10 · pill 999 · sm 8 · modal ~16 | Modal radius not a named token yet — **name it** `--radius-modal: 16px` |
| Shadows | sm / md / lg / modal | Keep; verify toast elevation |
| Type ramp | page 20–24/700 · section 16–18/700 · body 15 · label 14/600 · badge 12–13 | Express as `--text-*` in theme file (not yet in `tokens.css`) |
| Shell | sidebar **260px**, content max **~1440** (mocks often pad to ~1200) | Lock sidebar width; content max provisional |
| Focus ring | 2px primary + soft halo | Formalize `--focus-ring` |

**Not tokens / product copy (locked strings):** «أنهِ الدورة الحالية أولاً» · «لا يوجد طلاب متاحون للإضافة» · «لا علامات حضور بعد» · toast «تم النسخ».

---

## 3 MVP screens KEEP vs PARK (table with file refs)

Web Angular = center-admin ops. Teacher daily recording is **out**. Counts: **KEEP 15** · **PARK 2**.

| File | Verdict | One-line why |
|---|---|---|
| `01-landing.html` | **KEEP** | Public entry: دخول + تسجيل مركز; closes live ungated/marketing gap. |
| `02-login.html` | **KEEP** | Auth gate for all `/admin/*`; email + recovery + center signup link. |
| `03-dashboard.html` | **KEEP** | Admin shell + KPI + ACTIVE-term CTA lock; empty/populated spine. |
| `04-create-dawra-modal.html` | **KEEP** | Term create modal + disabled path when ACTIVE exists. |
| `05-halaqat.html` | **KEEP** | Ḥalaqāt list (cards/table) + empty; gateway to create/detail. |
| `06-create-halaqa-modal.html` | **KEEP** | Create ḥalaqa: term picker + teacher/students + chips + empty-picker copy. |
| `07-teachers.html` | **KEEP** | Active teachers list for assign/ops (ADMIN). |
| `08-teacher-requests.html` | **KEEP** | Approve/reject teacher requests — core admin queue. |
| `09-teacher-signup.html` | **KEEP** | Public two-step signup (not teacher-daily admin); needed for intake. |
| `10-students.html` | **KEEP** | Active students + reg-link modal on `tahfiz.work` + copy toast. |
| `11-student-requests.html` | **KEEP** | Student request queue (guardian + ḥifẓ status). |
| `12-student-signup.html` | **KEEP** | Public two-step student signup (reg-link destination). |
| `13-attendance-report.html` | **KEEP** | Read-only attendance report; shared filter bar. |
| `14-progress-report.html` | **KEEP** | Read-only progress (HIFZ/TATHBEET/MURAJAA) + shared filters. |
| `15-re-enrollment.html` | **PARK** | Secondary ops; ship after core term/ḥalaqa/people/reports; empty-state nuance can wait. |
| `16-identify.html` | **KEEP** | Invite/token identify: show center · term · expiry before ID entry. |
| `mobile/unbound-plan-empty.html` | **PARK** (web) | Flutter teacher empty-state for unbound plan — **not** Angular MVP surface. |

**Implicit KEEP (locked, no standalone HTML):** ḥalaqa **detail** with **Plans** tab (FOUNDATIONS §8) — **IN v1**; route under ḥalaqāt; ADMIN assign plans; not daily teacher entry. No new HTML mock required.

**Explicitly not MVP web:** teacher daily attendance/progress UIs; TEACHER-heavy admin chrome; scheduled INACTIVE terms; Vercel host in reg URLs.

---

## 4 Component inventory → kit mapping

Chosen kit: **PrimeNG** (concrete APIs below). Custom = Thafiz shell/copy on top of kit.

| Thafiz need | Mock cue | PrimeNG / app mapping |
|---|---|---|
| **App shell** | `.app-shell`, sticky right sidebar | Custom layout: CSS grid/flex + `dir="rtl"`; sidebar on **inline-start** (visual right). Optional `p-drawer` only if mobile collapse needed later. |
| **Nav** | `.nav-section`, `.nav-link.active` | Custom nav links (routerLink) styled with tokens; or `p-menu` / `p-panelmenu` if we want keyboard patterns — prefer custom to match mock density. |
| **Topbar** | `.topbar`, title, user chip | Custom header; user menu → `p-menu` overlay or `p-avatar` + menu. |
| **Data table** | `.data-table` / ḥalaqa table; reports | **`p-table`**: columns, sort, paginator, filter row as needed; `[rowTrackBy]`; empty via `ng-template pTemplate="emptymessage"`. |
| **Filter bar** (reports) | ḥalaqa + date range + search | `p-select` (ḥalaqa) + `p-datepicker` (range) + `p-inputText` + `p-button` «بحث» — shared component for `13`/`14`. |
| **Form fields** | `.input-group`, labels above | `p-inputText`, `p-password`, `p-textarea`, `p-select`, `p-datepicker`; labels above (FloatLabel off or `p-floatlabel` only if it stays RTL-clean). |
| **Radio / choice chips** | `.radio-chip` (category/period) | `p-selectButton` or `p-toggleButton` group; else `p-radiobutton` inside custom chip styling. |
| **Selection chips** | `.sel-chip` teacher/students | **`p-multiSelect`** display + **`p-chip`** removable tokens (create ḥalaqa / plan assign). |
| **Status chips / badges** | `.badge-*` | **`p-tag`** severities (success/warn/danger/info) mapped to Thafiz soft colors; or `p-chip` read-only. |
| **Modal / dialog** | `.modal-backdrop`, create dawra/ḥalaqa, reg-link | **`p-dialog`** (header/footer templates); confirm reject → `p-confirmdialog` / `ConfirmationService`. |
| **Primary / secondary / danger buttons** | `.btn-*` | **`p-button`** severity + outlined/text; gold accent = custom severity or `styleClass` → `--color-accent`. |
| **Empty states** | `.empty-block` + CTA | **Custom** presentational component (`ThEmptyState`); plug into pages and `p-table` emptymessage. Copy per FOUNDATIONS §12. |
| **Toasts** | «تم النسخ» on reg-link | **`p-toast`** + `MessageService` (success); keep link visible in dialog field. |
| **KPI cards** | dashboard cards | Custom `.card` grid; optional `p-card` if theming matches. |
| **Disabled create-term** | CTA + hint | `p-button` `[disabled]` + tooltip/`p-message` text «أنهِ الدورة الحالية أولاً». |
| **Auth pages** | landing / login / signups / identify | Mostly custom layouts + PrimeNG form controls; no admin shell. |

**Authz in UI (not security):** hide/disable term/ḥalaqa create, assign-teacher, enroll-students, admin, reg-link for non–ADMIN/SYSTEM_ADMIN; TEACHER web = limited — do not center MVP IA on teacher admin.

---

## 5 Decisions (all locked — Imad 2026-09-11)

1. **Kit:** PrimeNG — **LOCKED**.
2. **PARK** `15-re-enrollment` + mobile unbound for web v1 — **LOCKED**.
3. Ḥalaqa **detail + Plans tab IN v1** without new HTML mock — **LOCKED**.
4. Center **signup** = CTA from `01-landing` only (no full mock) — **LOCKED**.
5. Production host always **`https://www.tahfiz.work`** — **LOCKED**. (Path shape `/join/…` vs `/register/…` still follow live/API when wiring.)
6. **«إنهاء الدورة» IN v1** — **LOCKED**.

---

## 6 Next (awaiting CoS build brief / Dev staffing)

1. Scaffold Angular app (standalone) + **PrimeNG** + **Cairo** + `dir="rtl"`.
2. Bridge `tokens.css` → PrimeNG preset / theme (Damascus Paradise B).
3. Build **shell + auth gate** (`02` → `/admin/*`).
4. Implement KEEP screens: Dashboard → دورة create + **إنهاء الدورة** → حلقات list → **ḥalaqa detail + Plans tab** → create ḥalaqa → teachers/students + requests → reports → public signup/identify/reg-link (center signup = landing CTA only).
5. Wire RolesGuard-aligned UI gates; all public/reg URLs on **`https://www.tahfiz.work`**; ACTIVE-term create lock + end-term flow.
6. Parked: re-enrollment + Flutter unbound-plan (separate track).
7. Figma transfer later (MCP) — out of this sprint’s file work.
8. Designer stands by for CoS Angular build brief; HTML pack remains source of truth.

---

*Thafiz-only · §0–§5 fully locked 2026-09-11 · HTML mocks source of truth · Figma deferred*
