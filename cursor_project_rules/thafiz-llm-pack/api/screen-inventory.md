# Tahfiz.work screen inventory (Angular rewrite reference)

Observed live on 2026-09-10. Arabic UI is RTL with a shared right-side Admin navigation on admin-looking routes. This is an inventory of visible screens/blocks, not pixel specifications. No request was approved/rejected and no production record was created.

## A) Public / unauthenticated

| Route | Title / heading | Role | Purpose | Main UI blocks | Notable gaps / rough UX |
|---|---|---|---|---|---|
| `https://www.tahfiz.work/` | `مجمع خياركم التعليمي`; `سهّل عملك اليومي وارتقِ بإنتاجيتك`; `موثوق به من قبل` | Public | Marketing landing page for the education/halqa management product. | Logo; two `الصفحة الرئيسية` CTAs (both route to `/admin/dashboard`); large Arabic hero copy; short value proposition; trusted-by mosque chips/logos. | No visible login, join/signup, or password-recovery links; the home CTA leads to the admin dashboard; sparse landing page with no feature sections/footer observed. |
| `https://www.tahfiz.work/user/login` | No login heading rendered; request redirects to `/` | Public | Intended login destination, but not a usable login screen in the live build. | After navigation, only the home hero/trusted-by content appears. | Login form was not reachable, so credentials were not entered; no password-recovery link is exposed. |
| Join/signup links from home | None observed | Public | No distinct home join flow exposed. | Home contains only home/admin-dashboard links; teacher/student signup links appear in the admin sidebar instead. | No center join, teacher signup, or student signup link on the public home to open. |

## B) Admin area and secondary flows

### Shared admin shell

All admin routes below showed a right-side RTL sidebar headed `Admin`, with links: `لوحة التحكم`, `حلقات`, `تقرير الحضور`, `تقرير التقدم`, `المعلمين`, `طلبات المعلمين`, `تسجيل معلم`, `الطلاب`, `طلبات الطلاب`, `تسجيل طلاب`, `طلبات الإعادة التسجيل`; plus theme toggle, logo/home link, and a small icon/menu control. The admin screens rendered directly during this visit; no login gate was shown.

| Route | Title / heading | Role | Purpose | Main UI blocks | Notable gaps / rough UX |
|---|---|---|---|---|---|
| `/admin/dashboard` | `مرحباً بك` | Admin | Starting dashboard; prompt to establish the first course. | Empty-state welcome; copy says to create the first course; primary `انشاء دورة` CTA. | Empty dashboard gives little operational summary; admin route was reachable without a visible auth step. |
| `/admin/active-halqas` | `الحلقات` | Admin | List/manage active Quran circles (halqas). | Empty state `لا توجد حلقات نشطة`; `إنشاء حلقه` CTA. Create-halqa modal includes name; category radios (`ابتدائي`, `متوسط`, `ثانوي`, `متميزين`, `تلقين`, `تلاوة`); period radios (`عن بُعد`, `الفجر`, `الظهر`, `العصر`, `المغرب`, `العشاء`); student count; student selector (no available students); teacher selector; submit/close. | Empty data makes selectors unusable; modal defaults are preselected and has no apparent validation guidance beyond disabled/empty selectors. |
| `/admin/reports/attendance` | `قائمة حضور الطلاب` | Admin | Filter and review student attendance. | Halqa combobox; start/end date pickers; `بحث` (disabled until filters are usable); table columns `الطالب`, `حضور`, `غياب`, `إجازة`, `تأخير`; empty state `لا يوجد طلاب في هذا الوقت`. | Search disabled with no selectable active data; report is empty on first load. |
| `/admin/reports/progress` | `تقرير تقدم الطلاب` | Admin | Filter and review memorization progress. | Halqa combobox; second combobox `بدون تحديد`; start/end date pickers; disabled `بحث`; table columns `الطالب`, `نسبة الحفظ`, `نسبة المراجعة`, `نسبة التثبيت`; empty state `لا يوجد بيانات تقدم في هذا الوقت`. | No data and disabled search on initial state; meaning of the second filter is not explained. |
| `/admin/active-teacher` | `قائمة المعلمين` | Admin | Browse active teachers and inspect their profiles. | Search field `ابحث عن اسم المعلم`; link to teacher requests; teacher cards with active status and profile sections. Cards show personal/contact fields (name/email/phone/address/ID/birth date/nationality) and teaching profile fields (certificate, leave/sanad indicators, saved parts, tajweed level, age bands, available work periods). | Cards are very dense/long and mix personal data with profile data; labels/values can wrap awkwardly. |
| `/admin/teacher-requests` | `طلبات المعلمين`; card subsection `تفاصيل التعليم والحفظ` | Admin | Review pending teacher applications. | Pending request card; contact/personal fields; education/memorization details; yellow pending badge; red `رفض` and green `قبول` actions. | Contains placeholder-looking request values; approve/reject actions are high-impact and were intentionally not used; no visible confirmation flow was explored. |
| `/user/teacher/signup` | `تسجيل معلم جديد`; sections `المعلومات الشخصية`, `المؤهلات والخبرة` | Admin/sidebar signup flow | Collect a new teacher application. | Personal fields: teacher name, email, password, phone, birth date, address, nationality. Qualifications: academic qualification dropdown; Maknoon certificate checkbox; saved-parts count (default 0); memorization license/sanad checkboxes; tajweed-level dropdown; teaching-age checkboxes (under 6, 6–8, 9–11, 12–14, 15–17, 18–22, 23+); work-period checkboxes (weekly, after Fajr/Asr/Maghrib/Isha); `تسجيل معلم`. | Long two-column form; many required-looking fields do not visibly indicate required/optional status; no upload control observed for certificates. |
| `/admin/active-students` | `الطلاب النشطين` | Admin | Search/manage active students and start registration. | Student-name search; `تسجيل طالب` links; `رابط تسجيل الطالب` button; empty state `لا يوجد طلاب نشطين`; inline `تسجيل طالب` CTA. The registration-link button showed a brief `جاري إنشاء رابط` state but no visible dialog/result in the observed screen. | Empty state repeats registration CTAs; generated-link feedback is transient/non-obvious. |
| `/admin/student-requests` | `طلبات الطلاب`; card subsection `تفاصيل التعليم والحفظ` | Admin | Review pending student applications. | `تسجيل طالب` link and registration-link button; pending request card with personal/contact fields, guardian contact, education stage, memorization status/quality; red `رفض` and green `قبول`. | Contains placeholder-looking sample data; approve/reject actions were not used; no visible confirmation flow explored. |
| `/user/student/signup` (step 1) | `تسجيل بيانات الطالب` | Admin/sidebar signup flow | Collect basic student and guardian details. | Tabs `تسجيل بيانات الطالب` and `المعلومات التعليمية`; full name, email, school stage dropdown, phone, identity number, `لا يوجد رقم هوية` checkbox, address, birth date, guardian phone; `التالي`. | Multi-step state is tab-based; required-field/error affordances are not apparent before submission. |
| `/user/student/signup` (step 2) | `معلومات الحفظ` | Admin/sidebar signup flow | Collect memorization status before submitting a student request. | `حالة الحفظ` radios: `لم يسبق له حفظ`, `حفظ جزئي`, `خاتم`; `إرسال الطلب`. | Educational tab can be opened independently; no visible review/back step or summary before final submit. |
| `/admin/re-enrollment-requests` | `طلبات إعادة التسجيل` | Admin | Review requests to re-enroll students. | Empty card/message `لا توجد طلبات إعادة تسجيل`. | No filters, CTA, or request details when empty. |

## Create-term flow (opened read-only)

From `/admin/dashboard`, `انشاء دورة` opens an overlay titled `انشاء دورة` with:

- `اسم الدورة` text field.
- `تاريخ البداية` and `تاريخ النهاية` date controls.
- `تاريخ البداية التسجيل` and `تاريخ النهاية التسجيل` date controls.
- `ايام الاجازات` holiday selector, initially disabled with helper `يرجى تحديد تاريخ بداية ونهاية الدورة أولاً`.
- `إرسال` and close controls.

The overlay was closed without filling or submitting because creation could add production data. No term/course was created.

## Coverage notes

- All requested admin sidebar routes were visited.
- No password-recovery route/link was discoverable from the public home or reachable login destination.
- No public home signup/join links were present; the teacher/student signup screens were opened from the admin navigation.
- No real request was approved/rejected, and no create-term or create-halqa form was submitted.
