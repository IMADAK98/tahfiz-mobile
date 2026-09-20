import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SignupPagerDots extends StatelessWidget {
  const SignupPagerDots({super.key, required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.brand : const Color(0xFFC5BBA8),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
