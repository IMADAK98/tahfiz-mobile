**Status: LOCKED** Imad 2026-09-20 — no further visual changes unless he asks.

# Teacher signup — mobile Brand-B mocks

**Status:** LOCKED Imad 2026-09-20.  
**Sources:** `src-signup/step1-account.png` … `step4-availability.png`.  
**Shell:** `teacher-signup.css` + `../tokens.css` · Cairo · `#F3EEE3` · primary `#1B4D3E` · 390×844 phone like `login.html`.

## Pager — 4 steps kept

Legacy APK shows **4 dots / 4 screens**. Do not merge. Active = elongated primary pill; muted circles otherwise; dots above CTA.

## Field table

| Step | File | UI labels (AR) | Sample / state | CTA |
|---|---|---|---|---|
| 1 Account | `teacher-signup-1-account.html` | اسم المعلم · البريد الإلكتروني · كلمة المرور · كلمة المرور (confirm; aria تأكيد كلمة المرور) | test · testto@gmail.com · masked + eye | التالي |
| 2 Credentials | `teacher-signup-2-credentials.html` | المؤهل · مستوى التجويد · مركز العمل · شهادة خاتم مكنون؟ · إجازة في الحفظ؟ · سند في الحفظ؟ | الدبلوم · متقدم · Simon test · all ✓ | التالي |
| 3 Personal | `teacher-signup-3-personal.html` | الجنسية · العنوان · رقم الهاتف · تاريخ الميلاد · عدد الأجزاء المحفوظة | أفغانستان · yyrrdd · +558 89 965 5 · 20-09-2026 · 2 | التالي |
| 4 Availability | `teacher-signup-4-availability.html` | ابتدائية 6-11 · المتوسطة 12-14 · الثانوية 15-17 · الجامعية 18-22 · الكبار 23+ · فترة العمل المتاحة: أيام أحد–خميس · بعد الفجر/العصر/المغرب/العشاء | ابتدائية ✓ · أيام ✓ · فجر ✓ | **تسجيل** |

Login link all steps: هل لديك حساب؟ تسجيل الدخول.

## Nest hint

`POST pending-teacher-request` (and/or `register`) — map to **CreatePendingTeacherRequest** / pending-teacher-request body; confirm field names with Tech Lead before Flutter wire.

Obvious map: `teacherName`, `email`, `password`, `qualification`, `tajweedLevel`, `centerId`, `hasCertificate`, `hasIjazahInHifz`, `hasSanadInHifz`, `nationality`, `address`, `phone`, `birthDate`, `numberOfMemorizedJuz`, `teachingAgeGroup[]`, `availableWorkPeriod[]`.

## Previews (pending parent computerUse)

`previews/teacher-signup-1-account.png` … `-4-availability.png`
