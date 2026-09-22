import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/data/dto/progress_models.dart';
import '../../home/data/home_repository.dart';
import '../data/dto/halaqa_study_plan.dart';
import 'plans_chrome.dart';

/// Teacher plans list — locked `halaqa-plans.html` (expand / delete / unassign).
class HalaqaPlansPage extends ConsumerStatefulWidget {
  const HalaqaPlansPage({
    super.key,
    required this.halaqaId,
    this.halaqaName,
    this.studentCount = 0,
  });

  final String halaqaId;
  final String? halaqaName;
  final int studentCount;

  @override
  ConsumerState<HalaqaPlansPage> createState() => _HalaqaPlansPageState();
}

class _HalaqaPlansPageState extends ConsumerState<HalaqaPlansPage> {
  bool _loading = true;
  String? _error;
  List<HalaqaStudyPlan> _plans = const [];
  final Set<int> _expanded = {};
  final Set<int> _loadingDetails = {};
  String _halaqaName = 'الحلقة';
  int _studentCount = 0;
  List<QuranSurah> _surahs = const [];

  @override
  void initState() {
    super.initState();
    _halaqaName = widget.halaqaName?.trim().isNotEmpty == true
        ? widget.halaqaName!.trim()
        : 'الحلقة';
    _studentCount = widget.studentCount;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool fromRefresh = false}) async {
    if (!fromRefresh) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    final repo = ref.read(homeRepositoryProvider);
    try {
      final futures = <Future<dynamic>>[
        repo.listHalaqaStudyPlans(widget.halaqaId),
        repo.getQuranSurahs(),
      ];
      if (widget.halaqaName == null || widget.halaqaName!.trim().isEmpty) {
        futures.add(repo.getHalqaName(widget.halaqaId));
      }
      final results = await Future.wait(futures);
      if (!mounted) return;
      final plans = results[0] as List<HalaqaStudyPlan>;
      final surahs = results[1] as List<QuranSurah>;
      String? name;
      if (results.length > 2) name = results[2] as String?;
      setState(() {
        _plans = plans;
        _surahs = surahs;
        if (name != null && name.trim().isNotEmpty) {
          _halaqaName = name.trim();
        }
        _loading = false;
        _error = null;
        if (plans.isNotEmpty && _expanded.isEmpty) {
          _expanded.add(plans.first.id);
        }
      });
      if (plans.isNotEmpty) {
        await _ensureDetails(plans.first.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is HomeException ? e.message : e.toString();
      });
    }
  }

  String _surahName(int number) {
    for (final s in _surahs) {
      if (s.number == number) return s.name;
    }
    return 'سورة $number';
  }

  Future<void> _ensureDetails(int planId) async {
    final idx = _plans.indexWhere((p) => p.id == planId);
    if (idx < 0) return;
    final current = _plans[idx];
    if (current.detailsLoaded && current.students.isNotEmpty) return;
    if (_loadingDetails.contains(planId)) return;
    setState(() => _loadingDetails.add(planId));
    try {
      final details =
          await ref.read(homeRepositoryProvider).getStudyPlanDetails(planId);
      if (!mounted) return;
      setState(() {
        _plans = [
          for (final p in _plans)
            if (p.id == planId)
              p.copyWith(
                name: details.name,
                items: details.items.isNotEmpty ? details.items : p.items,
                students: details.students,
                studentsCount: details.displayStudentCount,
                detailsLoaded: true,
              )
            else
              p,
        ];
        _loadingDetails.remove(planId);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDetails.remove(planId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is HomeException ? e.message : 'تعذر تحميل تفاصيل الخطة',
          ),
        ),
      );
    }
  }

  Future<void> _toggleExpand(int planId) async {
    final wasOpen = _expanded.contains(planId);
    setState(() {
      if (wasOpen) {
        _expanded.remove(planId);
      } else {
        _expanded.add(planId);
      }
    });
    if (!wasOpen) await _ensureDetails(planId);
  }

  Future<void> _confirmDelete(HalaqaStudyPlan plan) async {
    final ok = await showPlansConfirmSheet(
      context: context,
      title: 'حذف الخطة',
      body: 'هل أنت متأكد من حذف ${plan.name}؟ لا يمكن التراجع.',
      confirmLabel: 'تأكيد حذف',
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(homeRepositoryProvider).deleteStudyPlan(plan.id);
      if (!mounted) return;
      setState(() {
        _plans = _plans.where((p) => p.id != plan.id).toList();
        _expanded.remove(plan.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الخطة')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is HomeException ? e.message : 'تعذر حذف الخطة'),
        ),
      );
    }
  }

  Future<void> _confirmUnassign({
    required HalaqaStudyPlan plan,
    required PlanAssignedStudent student,
  }) async {
    final ok = await showPlansConfirmSheet(
      context: context,
      title: 'إزالة من الخطة',
      body: 'هل أنت متأكد من إزالة ${student.name} من الخطة؟',
      confirmLabel: 'تأكيد إزالة',
    );
    if (!ok || !mounted) return;
    final sid = int.tryParse(student.id);
    if (sid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('معرّف الطالب غير صالح')),
      );
      return;
    }
    try {
      await ref.read(homeRepositoryProvider).unassignStudentsFromPlan(
            planId: plan.id,
            studentIds: [sid],
          );
      if (!mounted) return;
      setState(() {
        _plans = [
          for (final p in _plans)
            if (p.id == plan.id)
              p.copyWith(
                students:
                    p.students.where((s) => s.id != student.id).toList(),
                studentsCount: (p.displayStudentCount - 1).clamp(0, 9999),
                detailsLoaded: true,
              )
            else
              p,
        ];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is HomeException ? e.message : 'تعذر إزالة الطالب'),
        ),
      );
    }
  }

  void _openCreate() {
    context.push(
      '/halaqa/${widget.halaqaId}/plans/create',
      extra: {
        'halaqaName': _halaqaName,
        'studentCount': _studentCount,
      },
    ).then((_) => _load(fromRefresh: true));
  }

  void _openAssign(HalaqaStudyPlan plan) {
    context.push(
      '/halaqa/${widget.halaqaId}/plans/${plan.id}/assign',
      extra: {
        'halaqaName': _halaqaName,
        'planName': plan.name,
        'assignedIds': plan.students.map((s) => s.id).toList(),
      },
    ).then((_) {
      _ensureDetails(plan.id);
      _load(fromRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.parchment,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PlansTopBar(
                  title: 'الخطط',
                  onBack: () => context.pop(),
                ),
                const SizedBox(height: 10),
                PlansHalaqaContext(
                  halaqaName: _halaqaName,
                  studentCount: _studentCount,
                  muted: 'خطط مرتبطة بالحلقة · ليست يومية',
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFC62828),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => _load(fromRefresh: true),
                          child: _plans.isEmpty
                              ? _EmptyPlans(onAdd: _openCreate)
                              : ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'خطط الدراسة',
                                            style: TextStyle(
                                              color: AppColors.brand,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        FilledButton(
                                          key: const Key('plans-add-btn'),
                                          onPressed: _openCreate,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: AppColors.brand,
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(0, 36),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                          child: const Text('إضافة خطة'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    for (final plan in _plans) ...[
                                      _PlanCard(
                                        plan: plan,
                                        expanded: _expanded.contains(plan.id),
                                        loadingDetails:
                                            _loadingDetails.contains(plan.id),
                                        surahName: _surahName,
                                        onToggle: () => _toggleExpand(plan.id),
                                        onAssign: () => _openAssign(plan),
                                        onDelete: () => _confirmDelete(plan),
                                        onUnassign: (s) => _confirmUnassign(
                                          plan: plan,
                                          student: s,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ],
                                ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyPlans extends StatelessWidget {
  const _EmptyPlans({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 48),
        const Icon(Icons.menu_book_outlined, size: 48, color: AppColors.textMuted),
        const SizedBox(height: 12),
        const Text(
          'لا توجد خطة مرتبطة',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.brand,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'أضِف خطة دراسة لهذه الحلقة قبل متابعة تقدّم الحفظ والتثبيت والمراجعة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('إضافة خطة'),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.expanded,
    required this.loadingDetails,
    required this.surahName,
    required this.onToggle,
    required this.onAssign,
    required this.onDelete,
    required this.onUnassign,
  });

  final HalaqaStudyPlan plan;
  final bool expanded;
  final bool loadingDetails;
  final String Function(int) surahName;
  final VoidCallback onToggle;
  final VoidCallback onAssign;
  final VoidCallback onDelete;
  final ValueChanged<PlanAssignedStudent> onUnassign;

  @override
  Widget build(BuildContext context) {
    final types = plan.typeSummary.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: Color(0x0A15241C), offset: Offset(0, 1)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    key: Key('plan-toggle-${plan.id}'),
                    onTap: onToggle,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 10, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      plan.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.brandSoft,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        HalaqaPlansCopy.studentsPill(
                                          plan.displayStudentCount,
                                        ),
                                        style: const TextStyle(
                                          color: AppColors.brand,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (types.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      for (final t in types) PlanTypeChip(type: t),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: AnimatedRotation(
                              turns: expanded ? -0.25 : 0,
                              duration: const Duration(milliseconds: 150),
                              child: Icon(
                                Icons.chevron_left,
                                color: expanded
                                    ? AppColors.brand
                                    : AppColors.textMuted,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (expanded) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 12, 10),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          OutlinedButton(
                            key: Key('plan-assign-${plan.id}'),
                            onPressed: onAssign,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.brand,
                              side: const BorderSide(
                                color: AppColors.borderStrong,
                                width: 1.5,
                              ),
                              minimumSize: const Size(0, 32),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                            child: const Text('تعيين طلاب'),
                          ),
                          OutlinedButton(
                            key: Key('plan-delete-${plan.id}'),
                            onPressed: onDelete,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFC62828),
                              side: BorderSide(
                                color: const Color(0xFFC62828)
                                    .withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                              minimumSize: const Size(0, 32),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                            child: const Text('حذف'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 12, 14),
                      child: loadingDetails && !plan.detailsLoaded
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'عناصر الخطة',
                                  style: TextStyle(
                                    color: AppColors.brand,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (plan.items.isEmpty)
                                  const Text(
                                    'لا عناصر في هذه الخطة',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                else
                                  for (final item in plan.items) ...[
                                    _PlanItemRow(
                                      item: item,
                                      surahName: surahName,
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                const SizedBox(height: 6),
                                const Text(
                                  'الطلاب المعيَّنون',
                                  style: TextStyle(
                                    color: AppColors.brand,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (plan.students.isEmpty)
                                  const Text(
                                    'لا طلاب على هذه الخطة بعد',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                else
                                  for (final s in plan.students) ...[
                                    _AssignedStudentRow(
                                      student: s,
                                      onRemove: () => onUnassign(s),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                              ],
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanItemRow extends StatelessWidget {
  const _PlanItemRow({required this.item, required this.surahName});

  final StudyPlanItemRef item;
  final String Function(int) surahName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PlanTypeChip(type: item.type),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.formatPlanRange(surahName: surahName, full: true),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.formatAmountLabel(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignedStudentRow extends StatelessWidget {
  const _AssignedStudentRow({required this.student, required this.onRemove});

  final PlanAssignedStudent student;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final initial = student.name.trim().isNotEmpty
        ? String.fromCharCodes(student.name.trim().runes.take(1))
        : '?';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.brand,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              student.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            key: Key('plan-unassign-${student.id}'),
            onPressed: onRemove,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
  }
}
