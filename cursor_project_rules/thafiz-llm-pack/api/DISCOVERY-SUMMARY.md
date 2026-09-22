# Thafiz live discovery — 2026-09-10 (Explorer)

## Surfaces
| Surface | Host | Role |
|---------|------|------|
| Admin web | https://www.tahfiz.work | Center-admin ops |
| Registration | https://tahfiz-client.vercel.app | Student identify/register links |
| API | https://tahfiz.onrender.com | Nest backend (Bearer JWT) |
| Teacher mobile | Flutter APK (App Live paused) | Daily attendance + progress |

Product lock: **web = admin**; **mobile = teacher daily write**.

## Auth
- API admin login OK: `edoog2011@gmail.com` → ADMIN userId **2**, centerId **1**
- Web: **no working login UI** — `/user/login` → home; many `/login` variants 404; `/admin/dashboard` loads **ungated**
- Teacher API: `imadka224@gmail.com` TEACHER userId **3**; TEST teacher `test.teacher.cos@example.com` userId **25** (password reset to `TestTeacher123!` for exploration)

## TEST seed (API)
| Entity | ID | Name / email |
|--------|----|----------------|
| Term | 12 | TEST-CoS-2026-09 ACTIVE |
| Teacher | 25 | TEST Teacher CoS |
| Ḥalaqa | 12 | TEST Halqa CoS (+ UI-created **13** TEST Halqa UI-2) |
| Student | 26 | TEST Student CoS (enrolled in 12) |
| Study plan | 9 | HIFZ(17) + TATHBEET(18) + MURAJAA(19) |

Registration link (API): vercel host + token (expires 2026-09-30). Left non-TEST pending teacher#2 / student#11 untouched.

## Admin web findings
- Sidebar: dashboard, ḥalaqāt, attendance/progress reports, teachers, teacher requests/signup, students, student requests/signup, re-enrollment
- Study plans **exist** on `/admin/active-halqas/{id}` Plans tab
- Halqa create: no term picker; available-students picker empty
- Attendance aggregated empty until marks; after bulk marks shows counts
- Progress report lists student at 0% without marks
- Re-enrollment page empty-state only
- Student signup `/user/student/signup` multi-step; admin chrome still visible
- Registration-link button flaky (creating… then no URL)

## Attendance proof (API)
Bulk `POST /attendance/bulk` `{termDayId, students:[{userId,status}]}` for student 26:
- termDays 104 PRESENT, 105 ABSENT, 106 PRESENT → aggregated presentCount=2 absentCount=1
- activate-student same-term → 400 already enrolled

## Teacher App Live (paused — no more paid BS)
Folder: `/workspace/thafiz-discovery/mobile-walk/` + `SCREEN-LABELS.md`

Walk as imadka224 (assigned to ḥalaqa 12):
1. Login OK
2. Home lists TEST Halqa CoS
3. Attendance: **حاضر** selectable
4. Date on later shots: **2026-09-10**
5. **Progress blocker:** tapping HIFZ/MURAJAA summary shows snackbar **«يرجى تحديد حالة الحضور أولاً»** even when حاضر is visually selected — no progress editor before session expiry
6. Logcat: FlutterSecureStorage key-mismatch; OnBackInvokedCallback warnings

## Angular / Designer implications
1. Real auth gate on admin web
2. Halqa create: term picker + working teacher/student selectors
3. Attendance empty-state = “no marks” not “no students”; chip selection must commit before progress gate
4. Registration links on product host, stable copy UX
5. Teacher mobile: fix attendance→progress gate; document bottom nav Home / خطة الدراسة / الملف الشخصي

## Artifacts
- `/workspace/thafiz-discovery/first-pass-api.json`
- `/workspace/thafiz-discovery/attendance-vs-progress.md`
- `/workspace/thafiz-discovery/attendance-mark-proof.json`
- `/workspace/thafiz-discovery/mobile-walk/*`

## Batch 4 addendum (public)
- Unauth `/admin/dashboard` → 307 login (gate works)
- Landing Join → `/user/signup` center only; no teacher join
- Identify on vercel + tahfiz.work; pending-center accepts neither ID/passport
- Live web = Next.js; Angular = rewrite target
- See `web-cases/04-public-landing.md` + `screens/`
