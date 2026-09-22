# نظام التنبيهات — LOCKED (Imad 2026-09-16)

**Angular PR #10:** Visual PASS (2026-09-16). Nest bodies always `فشل الطلب: {msg}` unless already prefixed. Severity map is TL-locked.

**Shipping scope:** PrimeNG `<p-toast>` skin + behavior + Arabic copy only.  
**Not shipping:** the full designer demo page (`20-toasts.html`) and any sidebar «التنبيهات» nav item — that file is **skin reference** for Angular, not a product route.

## Locked placement & anatomy
- Place: top-left of content (away from RTL right sidebar)
- Shape: icon + optional title + body + ×
- Short locked copy: **body-only** (no separate title)
- Durations: success 3.5s · info 4s · warn 5s · error 7s
- Danger: `#C62828`
- Tokens + `20-toasts.html` = visual reference for Angular `p-toast` skin

## Locked Arabic copy
| نوع | نص |
|---|---|
| نجاح | تم الحفظ · تم إنشاء الدورة · تم إنشاء الحلقة · تم النسخ |
| خطأ | فشل الطلب: {رسالة الخادم} |
| تحذير | أنهِ الدورة الحالية أولاً |
| معلومة | لا يوجد طلاب متاحون للإضافة |

## Interceptor
HTTP interceptor pipes Nest `message` into toasts. Display: always `فشل الطلب: {رسالة الخادم}` (skip re-prefix if Nest text already starts with «فشل الطلب»). Severity map (e.g. 409→warn) is TL-locked — not a Designer change. Success stays feature-triggered.

## Previews
- `previews/20-toasts-gallery.png`
- `previews/20-toasts-placement.png`
