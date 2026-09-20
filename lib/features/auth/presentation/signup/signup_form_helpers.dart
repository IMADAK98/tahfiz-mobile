import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

Widget signupLabel(String text, Color muted) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        color: muted,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

Widget signupCheck({
  required String label,
  required bool value,
  required ValueChanged<bool?> onChanged,
  required bool enabled,
  String? error,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        value: value,
        onChanged: enabled ? onChanged : null,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppColors.brand,
      ),
      if (error != null)
        Text(
          error,
          style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12),
        ),
    ],
  );
}
