import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../../shared/widgets/primary_button.dart';

/// Teacher signup stub (pending-teacher-request flow later).
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.parchment,
        appBar: AppBar(
          title: const Text('تسجيل معلم'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => context.pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BrandMark(),
              const SizedBox(height: 24),
              const TextField(
                decoration: InputDecoration(labelText: 'الاسم الكامل'),
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(labelText: 'البريد الإلكتروني'),
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(labelText: 'رقم الجوال'),
              ),
              const SizedBox(height: 12),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'كلمة المرور'),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'إرسال طلب التسجيل',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('طلب التسجيل (وهمية) — قيد المراجعة'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'سيتم مراجعة الطلب عبر pending-teacher-request',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
