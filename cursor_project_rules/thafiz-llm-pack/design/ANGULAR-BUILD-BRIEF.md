# Thafiz Angular — Build Brief (v1 Admin)

**Date:** 2026-09-11 · **Owner:** Chief of Staff — Thafiz · **Status:** Ready to staff

## Mission
Replace live Next.js admin at `https://www.tahfiz.work` with a new **Angular** center-admin app. Inspired by live + HTML pack — **not a clone**. Teacher daily attendance/progress stays **Flutter** (out of scope).

## Locked decisions
| Topic | Lock |
|---|---|
| UI kit | **PrimeNG** |
| Brand | Damascus Paradise: bottle green `#1B4D3E` + gold `#D4AF37` (rare) + adobe `#8B4A3A` + parchment `#F3EEE3` + Cairo; `dir="rtl"` `lang="ar"` |
| Host | Always `https://www.tahfiz.work` (no Vercel in product URLs) |
| API | `https://tahfiz.onrender.com` · JWT `role` / `userId` / `centerId` (login body has no user) |
| Authz (UI + expect API) | Term/ḥalaqa CRUD, assign-teacher, enroll-students, admin queues, reg-link = **ADMIN/SYSTEM_ADMIN only** |
| One ACTIVE term | Disable create + «أنهِ الدورة الحالية أولاً»; **إنهاء الدورة** in v1 |
| PARK | `15-re-enrollment`, mobile unbound-plan (web) |
| Plans | Ḥalaqa **detail + Plans tab** in v1 (no dedicated HTML yet — follow FOUNDATIONS §8) |
| Center signup | Landing **CTA only** — no full mock required before build |
| Figma | Deferred — HTML pack is source of truth |

## Source of truth (read these)
1. `/workspace/thafiz/design/PRE-ANGULAR.md`
2. `/workspace/thafiz/design/API-SCREEN-MAP.md`
3. `/workspace/thafiz/design/FOUNDATIONS.md` + `tokens.css`
4. HTML KEEP: `01`–`14`, `16` (+ Plans as extension of `05`)
5. `/workspace/thafiz/as-built-api.md` + `/workspace/thafiz/swagger.json`

## Scaffold
- Angular standalone + PrimeNG + **Cairo**
- Theme: map `tokens.css` → PrimeNG preset (Damascus Paradise: bottle green primary; gold rare; adobe secondary; parchment surface)
- Root RTL; Western digits for ops IDs/dates
- Auth gate: unauth `/admin/*` → login

## Build order
1. Shell + auth (`02` → admin gate) + token storage / JWT decode
2. Dashboard (`03`) + ACTIVE-term CTA + **إنهاء الدورة**
3. Create دورة modal (`04`) with disable path
4. Ḥalaqāt list (`05`) + create modal (`06`) + **detail/Plans tab**
5. Teachers (`07`) + teacher requests (`08`) + public teacher signup (`09`)
6. Students (`10`) + reg-link on `tahfiz.work` + toast «تم النسخ» + requests (`11`) + student signup (`12`)
7. Reports attendance (`13`) + progress (`14`) shared filters
8. Public: landing (`01`) + identify (`16`)

## Component rules (PrimeNG)
- Tables → `p-table` · dialogs → `p-dialog` · toasts → `p-toast` · chips/tags → `p-chip`/`p-tag`
- Empty states → **custom** `ThEmptyState` (copy from FOUNDATIONS)
- Shell/nav → mostly custom to match mocks
- Avoid frozen/resizable table columns until RTL QA

## Non-goals (v1)
- Teacher daily write flows on web
- Re-enrollment UI
- Scheduled INACTIVE terms
- Relying on UI hide for authz (document expected 403s; backend RolesGuard is separate track)
- Figma parity

## Definition of done (v1)
- KEEP screens implementable against live API per API-SCREEN-MAP
- Reg links show `tahfiz.work` host in UI
- ACTIVE-term create lock + end-term path work
- ADMIN vs TEACHER nav/actions match matrix (TEACHER not primary web IA)
- RTL Arabic usable on desktop width ≥1280

## Held separately
- Backend RolesGuard PR (Tech Lead) — ask CoS to greenlight
- Ḥalaqa 13 dirty teachers `[3,25]` data fix
- Flutter unbound-plan empty state (mobile track)
