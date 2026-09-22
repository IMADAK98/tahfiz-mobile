import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/util/school_calendar.dart';
import '../../home/data/home_repository.dart';
import '../data/dto/halaqa_student.dart';
import 'plans_chrome.dart';

/// Assign students — locked `halaqa-plans-assign.html`.
class HalaqaPlansAssignPage extends ConsumerStatefulWidget {
  const HalaqaPlansAssignPage({
    super.key,
    required this.halaqaId,
    required this.planId,
    this.halaqaName,
    this.planName,
    this.alreadyAssignedIds = const {},
  });

  final String halaqaId;
  final int planId;
  final String? halaqaName;
  final String? planName;
  final Set<String> alreadyAssignedIds;

  @override
  ConsumerState<HalaqaPlansAssignPage> createState() =>
      _HalaqaPlansAssignPageState();
}

class _HalaqaPlansAssignPageState extends ConsumerState<HalaqaPlansAssignPage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<HalaqaStudent> _roster = const [];
  final Set<String> _selected = {};
  late Set<String> _assigned;

  String get _halaqaName =>
      widget.halaqaName?.trim().isNotEmpty == true
          ? widget.halaqaName!.trim()
          : 'الحلقة';

  String get _planName =>
      widget.planName?.trim().isNotEmpty == true
          ? widget.planName!.trim()
          : 'الخطة';

  @override
  void initState() {
    super.initState();
    _assigned = {...widget.alreadyAssignedIds};
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(homeRepositoryProvider);
    final date = SchoolCalendar.toYmd(DateTime.now());
    try {
      final students = await repo.getStudentsByHalqaId(
        halaqaId: widget.halaqaId,
        date: date,
      );
      if (!mounted) return;
      setState(() {
        _roster = students;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is HomeException ? e.message : e.toString();
      });
    }
  }

  Future<void> _submit() async {
    final ids = <int>[];
    for (final id in _selected) {
      final n = int.tryParse(id);
      if (n != null) ids.add(n);
    }
    if (ids.isEmpty) {
      setState(() => _error = 'اختر طالباً واحداً على الأقل');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(homeRepositoryProvider).assignStudentsToPlan(
            planId: widget.planId,
            studentIds: ids,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعيين الطلاب')),
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e is HomeException ? e.message : e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.parchment,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: PlansTopBar(
                  title: 'إضافة طلاب',
                  onBack: () => context.pop(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      const TextSpan(text: 'خطة: '),
                      TextSpan(
                        text: _planName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(text: ' · من قائمة $_halaqaName'),
                    ],
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFC62828),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(
                  'اختر الطلاب',
                  style: TextStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _roster.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final s = _roster[i];
                          final already = _assigned.contains(s.id);
                          final selected = already || _selected.contains(s.id);
                          return _StudentCheckRow(
                            key: Key('assign-student-${s.id}'),
                            name: s.name,
                            selected: selected,
                            alreadyAssigned: already,
                            onChanged: already
                                ? null
                                : (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selected.add(s.id);
                                      } else {
                                        _selected.remove(s.id);
                                      }
                                    });
                                  },
                          );
                        },
                      ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  10 + MediaQuery.paddingOf(context).bottom,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.parchment,
                  border: Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: Column(
                  children: [
                    PlansPrimaryButton(
                      key: const Key('assign-submit-btn'),
                      label: 'إضافة',
                      busy: _saving,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 8),
                    PlansSecondaryButton(
                      label: 'إلغاء',
                      onPressed: _saving ? null : () => context.pop(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentCheckRow extends StatelessWidget {
  const _StudentCheckRow({
    super.key,
    required this.name,
    required this.selected,
    required this.alreadyAssigned,
    required this.onChanged,
  });

  final String name;
  final bool selected;
  final bool alreadyAssigned;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty
        ? String.fromCharCodes(name.trim().runes.take(1))
        : '?';
    return Material(
      color: selected ? AppColors.brandSoft : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: alreadyAssigned || onChanged == null
            ? null
            : () => onChanged!(!selected),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.brand.withValues(alpha: 0.35) : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: alreadyAssigned ? null : onChanged,
                activeColor: AppColors.brand,
              ),
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.brand,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              if (alreadyAssigned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E4DA),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'مُعيَّن',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
