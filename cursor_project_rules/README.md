# Thafiz teacher — knowledge base

Source: `thafiz-llm-pack` (offline LLM handoff). Read this folder before coding.
This repo is the **Flutter teacher mobile** client only. Do not build Angular admin screens here.

## Read first

1. `thafiz-llm-pack/README-FOR-LLM.md` — product locks + next work
2. `implementation-plan.mdc` — ordered steps for this checkout
3. `thafiz-llm-pack/design/mobile/SCREENS-v2.md` — locked login / home / ḥalaqa / attendance / progress / signup + v2 drafts
4. `thafiz-llm-pack/api/openapi-teacher-mobile-slice.json` — Nest paths for this app
5. `thafiz-llm-pack/design/FOUNDATIONS.md` §1–2b + Brand B colors — admin vs teacher split

## Teacher-mobile files

| File | Use |
|---|---|
| `thafiz-llm-pack/design/mobile/TEACHER-SIGNUP.md` | 4-step signup lock |
| `thafiz-llm-pack/design/mobile/HALAQA-DETAIL-V2.md` | Ḥalaqa tabs — Imad asked to ship on `/halaqa/:id` |
| `thafiz-llm-pack/design/mobile/STUDENT-PROGRESS-V2.md` | **Awaiting Imad lock** — daily progress editor v2 |
| `thafiz-llm-pack/design/mobile/ASSIGN-PLAN.md` | **Awaiting Imad lock** — bind student to ḥalaqa plan |
| `thafiz-llm-pack/design/MOBILE-TEACHER-NOTES.md` | Explorer gaps (progress gate, unbound plan) |
| `thafiz-llm-pack/api/attendance-vs-progress.md` | Roster vs aggregated; `assignedToTermId`; bulk marks |
| `thafiz-llm-pack/api/as-built-api.md` | Live API shape; Nest truth = `localization-refactor` + Render |

## Angular-only (do not implement in this repo)

`design/ANGULAR-*.md`, `NEST-REENROLL-OPTION-A.md`, `PRE-ANGULAR.md`, `api/screen-inventory.md`.
Use only when a mobile call must match the same Nest field or enum.
