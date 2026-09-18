import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

/// Student hub — navigate to attendance / progress editors.
class StudentPage extends StatelessWidget {
  const StudentPage({
    super.key,
    required this.studentId,
    this.date,
    this.halaqaId,
  });

  final String studentId;
  final String? date;
  final String? halaqaId;

  String _qs() {
    final parts = <String>[];
    if (date != null && date!.trim().isNotEmpty) {
      parts.add('date=${Uri.encodeQueryComponent(date!.trim())}');
    }
    if (halaqaId != null && halaqaId!.trim().isNotEmpty) {
      parts.add('halaqaId=${Uri.encodeQueryComponent(halaqaId!.trim())}');
    }
    if (parts.isEmpty) return '';
    return '?${parts.join('&')}';
  }

  @override
  Widget build(BuildContext context) {
    final qs = _qs();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.parchment,
        appBar: AppBar(
          title: Text('الطالب #$studentId'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => context.pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الطالب #$studentId',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                      if (date != null && date!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'اليوم: $date',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _NavTile(
                icon: Icons.fact_check_outlined,
                title: 'تسجيل الحضور',
                subtitle: 'حاضر / غائب / متأخر / معذور',
                onTap: () =>
                    context.push('/student/$studentId/attendance$qs'),
              ),
              const SizedBox(height: 12),
              _NavTile(
                icon: Icons.menu_book_outlined,
                title: 'تسجيل التقدّم',
                subtitle: 'إلى سورة / آية · مراجعة',
                onTap: () =>
                    context.push('/student/$studentId/progress$qs'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.presentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.brand),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
