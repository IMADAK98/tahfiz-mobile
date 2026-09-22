# ثفيز — مسودات تصميم HTML (بدون Figma MCP)

حزمة مراجعة أوفلاين عربية RTL للوحة إدارة المركز. ستُنقل لاحقاً إلى ملف Figma:

**https://www.figma.com/design/s0euKOYhKjnZwDSqJrTLCi**

(عند عودة حصة MCP)

## كيف تفتح المسودات

من المجلد `/workspace/thafiz/design/`:

```bash
# مثال
xdg-open 01-landing.html
# أو أي خادم ثابت
python3 -m http.server 8765 --directory /workspace/thafiz/design
```

ثم افتح `http://localhost:8765/01-landing.html` في المتصفح.  
الملفات تعتمد على `tokens.css` وخط Cairo من Google Fonts (يلزم اتصال للخط فقط).

## فهرس الملفات

| ملف | الوصف |
|---|---|
| `FOUNDATIONS.md` | النوع، الألوان، المسافات، المكوّنات، قواعد RTL، نطاق إدارة vs معلّم، بيانات TEST |
| `tokens.css` | رموز مشتركة مستوردة من كل HTML |
| `BATCH2.md` | دفعة 2: قائمة الملفات وترتيب المراجعة |
| `01-landing.html` | هبوط عام: دخول + تسجيل مركز (يسد فجوة الحيّ) |
| `02-login.html` | تسجيل دخول سليم + بوابة إلزامية لـ `/admin/*` |
| `03-dashboard.html` | هيكل إدارة يمين خلف auth + KPI + نشاط؛ تبديل فارغ/معبّأ (TEST spine) |
| `04-create-dawra-modal.html` | نافذة إنشاء دورة (اسم، تواريخ، تسجيل، إجازات، خطة) |
| `05-halaqat.html` | قائمة حلقات مع صف TEST + حالة فارغة بالتبديل |
| `06-create-halaqa-modal.html` | إنشاء حلقة: دورة صريحة + معلّم/طلاب عاملة + رقائق |
| `07-teachers.html` | قائمة المعلمين: بحث، بطاقات/جدول، مؤهلات، شارة نشط |
| `08-teacher-requests.html` | طلبات المعلمين: معلّق + قبول/رفض مع تأكيد |
| `09-teacher-signup.html` | تسجيل معلّم خطوتان (شخصي → مؤهلات) مع علامات مطلوب |
| `10-students.html` | الطلاب النشطون + رابط تسجيل على مضيف المنتج (`tahfiz.work`) |
| `11-student-requests.html` | طلبات الطلاب: ولي أمر + حالة حفظ + قبول/رفض |
| `12-student-signup.html` | تسجيل طالب خطوتان: شخصي/ولي ثم حالة الحفظ |
| `13-attendance-report.html` | تقرير الحضور (قراءة) — فلاتر حلقة/تاريخ/بحث |
| `14-progress-report.html` | تقرير التقدّم — نفس فلاتر الحضور + بند الخطة |
| `15-re-enrollment.html` | طلبات إعادة التسجيل: فارغ + عيّنة قبول/رفض |

## بيانات TEST المعروضة في الحالات المعبّأة

- دورة: `TEST-CoS-2026-09` (termId 12)
- حلقة: `TEST Halqa CoS` (ḥalaqaId 12)
- معلّم: محمد العتيبي · `test.teacher.cos@example.com` (userId 25)
- طالب: عبدالله بن سعد الدوسري · `test.student.cos@example.com` (userId 26)
- خطة دراسة #9: HIFZ / TATHBEET / MURAJAA

تسجيل الحضور اليومي **خارج** نطاق ويب الإدارة (تطبيق المعلّم).

## ترتيب مراجعة CoS المقترح

1. Landing → 2. Login → 3. Dashboard shell → 4. Create دورة → 5. حلقات  
ثم دفعة 2: 7 معلمون → 8 طلبات معلمين → 9 تسجيل معلّم → 10 طلاب → 11 طلبات طلاب → 12 تسجيل طالب → 13 حضور → 14 تقدّم → 15 إعادة تسجيل.

## Explorer findings (2026-09-10)

صُقلت المسودات وفق 5 ملاحظات Explorer — انظر `FOUNDATIONS.md` §14. بدون شاشات جديدة.

## تطبيق المعلم (جوال)

ملاحظات جرد الشاشات (ليست مسودات إدارة):
[`MOBILE-TEACHER-NOTES.md`](./MOBILE-TEACHER-NOTES.md)
| `16-identify.html` | تحقق هوية / رابط دعوة (مضيف المنتج) |
| `mobile/unbound-plan-empty.html` | جوال: خطة غير مربوطة — empty + CTA |
