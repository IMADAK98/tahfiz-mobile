# Attendance report empty vs progress report shows student

**Investigated:** 2026-09-10 15:00 AST  
**API base:** `https://tahfiz.onrender.com`  
**Subject:** termId=12 `TEST-CoS-2026-09`, halqaId=12 `TEST Halqa CoS`, studentId=26 `TEST Student CoS`

## Host split (explicit)

| Surface | Host | Role |
|---------|------|------|
| Product web (admin) | `https://www.tahfiz.work` | Admin setup + reports (Next.js on Vercel). Routes e.g. `/admin/reports/attendance`, `/admin/reports/progress`. Unauthenticated → 307 `/user/login`. Layout bundle API base: `https://tahfiz.onrender.com`. |
| Registration / client links | `https://tahfiz-client.vercel.app/...` | Public/registration flows (separate Vercel app). |
| Backend API | `https://tahfiz.onrender.com` | Nest/OpenAPI. Auth: `POST /auth/login` → Bearer `data.accessToken`. Spec: `/api-json` (also `/tmp/tahfiz-openapi.json`). |

Mobile teacher app owns **writes** (bulk attendance marks + daily progress). Web admin reports are **read/filter** only (design copy on attendance report).

---

## Root cause hypothesis (with evidence)

**Empty attendance UI is not “no students enrolled.”** Student 26 **is** enrolled on halqa 12. The admin attendance report columns (`حضور / غياب / إجازة / تأخير`) match **aggregated counts**:

`GET /attendance/halqa/{halqaId}/aggregated` (optional `dateFrom` / `dateTo`)

That endpoint returns **`data.students: []`** when there are **no marked attendance rows**. It does **not** synthesize roster rows for `NOT_MARKED`.

Progress uses enrollment roster:

`GET /reports/progress?halqaId=12&period=week&startingDate=...&endingDate=...`

→ always includes student 26 with 0% HIFZ/TATHBEET/MURAJAA.

**Conclusion: empty because zero attendance marks (aggregated omits unmarked enrolled students), not because enrollment failed.**

Secondary date trap: term starts **2026-09-10**. Dates before that return empty on `/halqa/students/by-halqa-id/...`. Weekly-table for Sunday 2026-09-06 only has column Thu 2026-09-10.

---

## Evidence matrix

### Enrollment / roster

| Call | HTTP | Shape that matters |
|------|------|--------------------|
| `GET /halqa/12` | 200 | `studentsCount: 1`, student id 26 `TEST Student CoS`, `assignedToTermId: 12` |
| `GET /halqa/by-term/12` | 200 | Enrollment 35 for user 26, `isActive: true` |
| `GET /term/12` | 200 | `startDate: 2026-09-10` … `endDate: 2026-10-10`, ACTIVE, student 26 |
| `GET /halqa/students/by-halqa-id/12?date=2026-09-10` | 200 | 1 row; `attendance.status: "NOT_MARKED"` |
| `GET /halqa/students/by-halqa-id/12?date=2026-09-06` | 200 | `data: []` (before term start) |
| `GET /halqa/students/by-halqa-id/12?date=2026-09-01` | 200 | `data: []` |
| `GET /halqa/13` (UI-2) | 200 | `studentsCount: 0` |
| `GET /halqa/students/by-halqa-id/13?date=2026-09-10` | 200 | `data: []` |

### Attendance (halqa 12)

| Call | HTTP | Result |
|------|------|--------|
| `GET /attendance/term/12/aggregated` (+ optional date range) | 200 | `data: []` |
| `GET /attendance/halqa/12/aggregated` (+ ranges) | 200 | `data.students: []` |
| `GET /attendance/halqa/12/weekly?weekStartDate=2026-09-06\|13` | 200 | `data: []` (no raw marks) |
| `GET /attendance/halqa/12/weekly-table?weekStartDate=2026-09-06` | 200 | **student 26**, Thu 2026-09-10 `NOT_MARKED` |
| `GET /attendance/halqa/12/weekly-table?weekStartDate=2026-09-13` | 200 | **student 26**, Sun–Thu all `NOT_MARKED` |
| `GET /attendance/halqa/12/students/26/timeline?dateFrom=2026-09-01&dateTo=2026-09-30` | 200 | summary `notMarkedCount:15`, all other counts 0 |

**Aggregated snippet (UI-shaped empty):**
```json
{
  "message": "Halqa attendance summary fetched successfully",
  "status": 200,
  "data": {
    "halqa": { "id": 12, "name": "TEST Halqa CoS" },
    "students": []
  }
}
```

**Weekly-table snippet (roster visible, unmarked):**
```json
{
  "data": {
    "halqa": { "id": 12, "name": "TEST Halqa CoS" },
    "weekStartDate": "2026-09-06T00:00:00.000Z",
    "weekEndDate": "2026-09-10T00:00:00.000Z",
    "columns": [{ "dayOfWeek": "Thursday", "date": "2026-09-10", "termDayId": 104 }],
    "students": [{
      "student": { "id": 26, "name": "TEST Student CoS" },
      "days": [{ "date": "2026-09-10", "status": "NOT_MARKED" }]
    }]
  }
}
```

OpenAPI: aggregated = counts for charts/summary; weekly-table = all enrolled + `NOT_MARKED` for missing. Screen inventory attendance columns match aggregated; empty copy `لا يوجد طلاب في هذا الوقت`.

### Progress

OpenAPI `GET /reports/progress` query:

| Param | Required | Notes |
|-------|----------|-------|
| `halqaId` | yes | number |
| `period` | no | `day` \| `week` \| `month` (lowercase) |
| `startingDate` | no | YYYY-MM-DD |
| `endingDate` | no | YYYY-MM-DD |

400 if neither period nor both dates.

| Call | HTTP | Result |
|------|------|--------|
| `...?halqaId=12&period=week&startingDate=2026-09-06&endingDate=2026-09-10` | 200 | student 26 @ 0% all types |
| `...?halqaId=12&period=day&startingDate=2026-09-10&endingDate=2026-09-10` | 200 | student 26 present |
| `...?halqaId=12` | 400 | missing period/dates |
| `...?halqaId=13&period=week&...` | 200 | `students: []` (true empty) |

**Progress snippet:**
```json
{
  "status": 200,
  "message": "Progress fetched successfully",
  "data": {
    "halqa": { "id": 12, "name": "TEST Halqa CoS" },
    "students": [{
      "studentId": 26,
      "studentName": "TEST Student CoS",
      "progress": [
        { "planItemType": "HIFZ", "totalPercentage": 0 },
        { "planItemType": "TATHBEET", "totalPercentage": 0 },
        { "planItemType": "MURAJAA", "totalPercentage": 0 }
      ]
    }]
  }
}
```

---

## Task 5 compare

| Question | Answer |
|----------|--------|
| Does attendance see enrolled student? | **Yes** on weekly-table, timeline, students-by-halqa (in-term). **No** on aggregated/weekly-raw when unmarked. |
| Empty = no marks vs no enrollment? | **No marks.** Enrollment OK; aggregated empty until mobile `POST/PUT /attendance/bulk`. |

---

## Exact working curls

```bash
API=https://tahfiz.onrender.com
TOKEN=$(curl -sS -X POST "$API/auth/login" \
  -H 'Content-Type: application/json' \
  -d '{"email":"edoog2011@gmail.com","password":"1234567890"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])")
AUTH="Authorization: Bearer $TOKEN"

# Progress (shows TEST Student CoS)
curl -sS -H "$AUTH" \
  "$API/reports/progress?halqaId=12&period=week&startingDate=2026-09-06&endingDate=2026-09-10"
curl -sS -H "$AUTH" \
  "$API/reports/progress?halqaId=12&period=day&startingDate=2026-09-10&endingDate=2026-09-10"

# Attendance report UI shape (EMPTY until marks)
curl -sS -H "$AUTH" \
  "$API/attendance/halqa/12/aggregated?dateFrom=2026-09-10&dateTo=2026-10-10"
curl -sS -H "$AUTH" \
  "$API/attendance/term/12/aggregated?dateFrom=2026-09-10&dateTo=2026-10-10"

# Grid that lists enrolled unmarked students
curl -sS -H "$AUTH" \
  "$API/attendance/halqa/12/weekly-table?weekStartDate=2026-09-06"
curl -sS -H "$AUTH" \
  "$API/attendance/halqa/12/weekly-table?weekStartDate=2026-09-13"

# Roster
curl -sS -H "$AUTH" "$API/halqa/12"
curl -sS -H "$AUTH" "$API/halqa/students/by-halqa-id/12?date=2026-09-10"
```

---

## Blockers / pitfalls

1. Aggregated empty ≠ unenrolled — progress still lists the student.
2. `weekStartDate` must be Sunday (Saudi work week).
3. Term starts 2026-09-10 — earlier dates empty on students-by-halqa.
4. Progress needs `period` or both dates; period lowercase.
5. Timeline needs `dateFrom`+`dateTo`.
6. Marks only via mobile bulk attendance write.
7. Hosts: admin `www.tahfiz.work`, registration `tahfiz-client.vercel.app`, API `tahfiz.onrender.com`.

## Suggested follow-ups (not done)

- Include unmarked enrolled students in aggregated (zeros), or align empty-state copy with design (“no attendance recorded”).
- Use weekly-table if a day grid is intended for the report page.
