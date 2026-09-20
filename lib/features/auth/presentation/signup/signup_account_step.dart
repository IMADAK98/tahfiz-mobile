import 'package:flutter/material.dart';

import 'signup_form_helpers.dart';

class SignupAccountStep extends StatelessWidget {
  const SignupAccountStep({
    super.key,
    required this.muted,
    required this.teacherName,
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.enabled,
    required this.errorFor,
    required this.onTogglePassword,
    required this.onToggleConfirm,
  });

  final Color muted;
  final TextEditingController teacherName;
  final TextEditingController email;
  final TextEditingController password;
  final TextEditingController confirmPassword;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool enabled;
  final String? Function(String key) errorFor;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      children: [
        signupLabel('اسم المعلم', muted),
        TextField(
          controller: teacherName,
          enabled: enabled,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(errorText: errorFor('teacherName')),
        ),
        const SizedBox(height: 12),
        signupLabel('البريد الإلكتروني', muted),
        TextField(
          controller: email,
          enabled: enabled,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(errorText: errorFor('email')),
        ),
        const SizedBox(height: 12),
        signupLabel('كلمة المرور', muted),
        TextField(
          controller: password,
          enabled: enabled,
          obscureText: obscurePassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            errorText: errorFor('password'),
            suffixIcon: IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: muted,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        signupLabel('كلمة المرور', muted),
        TextField(
          controller: confirmPassword,
          enabled: enabled,
          obscureText: obscureConfirm,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            errorText: errorFor('confirmPassword'),
            suffixIcon: IconButton(
              onPressed: onToggleConfirm,
              icon: Icon(
                obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: muted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
