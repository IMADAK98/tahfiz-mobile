# Thafiz As-Built API Contract

Captured from live OpenAPI for Chief of Staff. Source: production Render deploy.

## Snapshot

| Field | Value |
|---|---|
| API base URL | `https://tahfiz.onrender.com` (no global `/api` prefix on routes; Swagger UI at `/api`) |
| OpenAPI JSON | `https://tahfiz.onrender.com/api-json` (Nest default; `/swagger-json` and `/api/json` 404) |
| OpenAPI version | 3.0.0 |
| Document title / version | API / 1.0 |
| Path count | 116 |
| Operation count | 157 |
| Tag count | 26 |
| Local copy | `/workspace/thafiz/swagger.json` |

## Auth

- Scheme name: **`access-token`**
- Type: HTTP **Bearer JWT** (`Authorization` header)
- Most protected routes declare `security: [{ access-token: [] }]`
- Global JWT auth guard is registered in `AppModule` (repo); some auth/register/public request routes omit bearer in swagger
- CORS allows `Authorization` and `Accept-Language` (i18n-aware)

### Operations without explicit bearer in OpenAPI (24)

- `DELETE /pending-student-request/{id}`
- `DELETE /progress-suggestion/{id}`
- `GET /pending-center-request/{id}`
- `GET /pending-student-request`
- `GET /pending-student-request/{id}`
- `GET /progress-suggestion`
- `GET /progress-suggestion/{id}`
- `GET /register-token/validate/{token}`
- `PATCH /pending-student-request/{id}`
- `PATCH /progress-suggestion/{id}`
- `POST /auth/activate`
- `POST /auth/login`
- `POST /auth/logout`
- `POST /auth/mobile/request-password-reset`
- `POST /auth/mobile/reset-password`
- `POST /auth/refresh`
- `POST /auth/register`
- `POST /auth/request-password-reset`
- `POST /auth/reset-password`
- `POST /pending-center-request`
- `POST /pending-center-request/resend-activation`
- `POST /pending-student-request`
- `POST /progress-suggestion`
- `POST /register-token/use/{token}`

## Tags (endpoint / operation counts)

| Tag | Operations |
|---|---:|
| Halqa | 13 |
| Quran | 12 |
| Centers | 11 |
| Study Plans | 11 |
| Authentication | 9 |
| Attendance | 7 |
| Student Daily Progress | 7 |
| Term Days | 7 |
| Terms | 7 |
| Users | 7 |
| Pending Teacher Requests | 6 |
| Teacher Profile | 6 |
| Admin Student Requests | 5 |
| AdminProfile | 5 |
| Pending Student Requests | 5 |
| ProgressSuggestion | 5 |
| Roles | 5 |
| StudentProfile | 5 |
| Study Plans items | 5 |
| Admin Re-Enrollment Requests | 4 |
| Admin Teacher Requests | 4 |
| AdminCenterRequest | 3 |
| PendingCenterRequest | 3 |
| App | 2 |
| RegisterToken | 2 |
| Reports | 1 |

## Top-level path prefixes (by path entry count)

| Prefix | Paths |
|---|---:|
| `/admin` | 13 |
| `/quran` | 12 |
| `/center` | 10 |
| `/halqa` | 10 |
| `/auth` | 9 |
| `/study-plan` | 8 |
| `/attendance` | 6 |
| `/student-daily-progress` | 5 |
| `/users` | 5 |
| `/term` | 4 |
| `/term-day` | 4 |
| `/pending-center-request` | 3 |
| `/pending-teacher-request` | 3 |
| `/study-plan-item` | 3 |
| `/system-admin` | 3 |
| `/teacher-profile` | 3 |
| `/admin-profile` | 2 |
| `/pending-student-request` | 2 |
| `/progress-suggestion` | 2 |
| `/register-token` | 2 |
| `/roles` | 2 |
| `/student-profile` | 2 |
| `/profile` | 1 |
| `/reports` | 1 |
| `/send-email` | 1 |

## Domain shape (notable vs typical early BRD)

Inferred from tag/path names only (no BRD file compared in this capture):

- **Multi-tenant centers**: Centers, Terms, Halqa, enrollments, registration tokens
- **Approval workflows**: Pending Student/Teacher/Center requests; Admin Student/Teacher/Re-Enrollment; system-admin center requests
- **Quran pedagogy**: Quran helpers, Study Plans / Study Plan items, Student Daily Progress (incl. murajaa), ProgressSuggestion, Attendance, Reports
- **Profiles/RBAC**: Users, Roles, Admin/Teacher/Student profiles, Authentication (login/register/refresh/logout/activate/password reset + mobile reset)
- **Localization-aware backend** (repo branch, not always visible in OpenAPI): i18n module, localized validation/errors, `Accept-Language`

## Repo branch note (`localization-refactor`)

- Confirmed on `IMADAK98/Tahfiz` (SHA `a723af906f0c48cc76c114a9fc1871481f27931b`)
- Ahead of default `main` (tip `cc091047…`, May 2026): adds I18nModule, GlobalHttpExceptionFilter, ScheduleModule, Reports/Enrollment wiring, halqa unassign, term/enrollment lifecycle hardening, etc.
- Live swagger above is the as-built contract from Render; branch may be what that deploy tracks or a close descendant.

