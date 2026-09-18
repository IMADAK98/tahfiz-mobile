import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';

/// Recover account stub — email + code paths match Nest mobile reset DTOs.
/// UI only; does not call the API yet (login link routes here).
class RecoverAccountPage extends StatefulWidget {
  const RecoverAccountPage({super.key});

  @override
  State<RecoverAccountPage> createState() => _RecoverAccountPageState();
}

class _RecoverAccountPageState extends State<RecoverAccountPage> {
  bool _codeSent = false;
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.parchment,
        appBar: AppBar(
          title: const Text('استعادة الحساب'),
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
              if (!_codeSent) ...[
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'إرسال رمز التحقق',
                  onPressed: () => setState(() => _codeSent = true),
                ),
              ] else ...[
                Text(
                  'أدخل رمز التحقق المرسل إلى ${_email.text}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _code,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(labelText: 'رمز التحقق'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور الجديدة',
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'تعيين كلمة المرور',
                  onPressed: () => context.go('/login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}