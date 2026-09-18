import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Brand mark «ت» + optional title «تحفيظ».
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.showTitle = true,
    this.size = 44,
  });

  final bool showTitle;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'ت',
            style: TextStyle(
              color: AppColors.onBrand,
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (showTitle) ...[
          const SizedBox(width: 12),
          Text(
            'تحفيظ',
            style: TextStyle(
              color: AppColors.brand,
              fontSize: size * 0.55,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
