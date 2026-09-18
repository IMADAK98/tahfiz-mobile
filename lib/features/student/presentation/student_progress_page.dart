import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/util/school_calendar.dart';
import '../../halaqa/data/dto/halaqa_student.dart';
import '../../home/data/dto/progress_models.dart';
import '../../home/data/home_repository.dart';

/// Student progress editor — locked mock `student-progress.html`.
///
/// Product locks:
/// - Plan block READ-ONLY (range + المقدار المطلوب اليوم)
/// - Teacher fills إلى سورة + إلى آية only
/// - HIFZ / TATHBEET: one pair; MURAJAA: list with add/remove
/// - Attendance chips read-only on this page
class StudentProgressPage extends ConsumerStatefulWidget {
  const StudentProgressPage({
    super.key,
    required this.studentId,
    this.date,
    this.halaqaId,
  });

  final String studentId;
  final String? date;
  final String? halaqaId;

  @override
  ConsumerState<StudentProgressPage> createState() =>
      _StudentProgressPageState();
}

class _StudentProgressPageState extends ConsumerState<StudentProgressPage> {
  bool _loading = true;
  bool _saving = false;
  bool _loadingTab = false;
  String? _error;

  late String _date;
  String _title = 'المعلم';
  String? _studentName;
  String? _attendanceStatus;

  List<StudyPlanItemRef> _items = const [];
  List<QuranSurah> _surahs = const [];
  PlanItemType? _selectedType;

  DailyProgressSnapshot? _progress;
  StudyPlanItemRef? get _activeItem {
    if (_selectedType == null) return null;
    for (final i in _items) {
      if (i.type == _selectedType) return i;
    }
    return null;
  }

  /// HIFZ / TATHBEET single end pair.
  int? _endSurah;
  final _endAyahCtrl = TextEditingController();

  /// MURAJAA rows.
  final List<_MurRow> _murRows = [];

  bool get _hasHalaqa =>
      widget.halaqaId != null && widget.halaqaId!.trim().isNotEmpty;

  bool get _isUnbound => !_loading && _items.isEmpty && _error == null;

  @override
  void initState() {
    super.initState();
    final incoming = SchoolCalendar.parseYmd(widget.date);
    _date = SchoolCalendar.toYmd(incoming ?? DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _endAyahCtrl.dispose();
    for (final r in _murRows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(homeRepositoryProvider);

    try {
      // Snap date if we have halaqa holidays.
      if (_hasHalaqa) {
        final holidays =
            await repo.getHolidayDatesForHalqa(widget.halaqaId!.trim());
        final snapped = SchoolCalendar.snapToSchoolDay(
          SchoolCalendar.parseYmd(_date) ?? DateTime.now(),
          holidays,
        );
        _date = SchoolCalendar.toYmd(snapped);
      }

      final futures = <Future<dynamic>>[
        repo.getStudentStudyPlan(studentId: widget.studentId, date: _date),
        repo.getQuranSurahs(),
      ];
      if (_hasHalaqa) {
        futures.add(repo.getStudentsByHalqaId(
          halaqaId: widget.halaqaId!.trim(),
          date: _date,
        ));
        futures.add(repo.getHalqaName(widget.halaqaId!.trim()));
      }

      final results = await Future.wait(futures);
      if (!mounted) return;

      final items = results[0] as List<StudyPlanItemRef>;
      final surahs = results[1] as List<QuranSurah>;

      String? name;
      String? att;
      if (_hasHalaqa && results.length >= 3) {
        final students = results[2] as List<HalaqaStudent>;
        for (final s in students) {
          if (s.id == widget.studentId) {
            name = s.name;
            att = s.attendanceStatus;
            break;
          }
        }
      }
      String? halaqaName;
      if (_hasHalaqa && results.length >= 4) {
        halaqaName = results[3] as String?;
      }

      // Deduplicate by type — keep first of each tab type.
      final byType = <PlanItemType, StudyPlanItemRef>{};
      for (final i in items) {
        byType.putIfAbsent(i.type, () => i);
      }
      final unique = byType.values.toList();

      PlanItemType? initial;
      for (final t in [
        PlanItemType.hifz,
        PlanItemType.tathbeet,
        PlanItemType.murajaa,
      ]) {
        if (byType.containsKey(t)) {
          initial = t;
          break;
        }
      }

      setState(() {
        _items = unique;
        _surahs = surahs;
        _studentName = name;
        _attendanceStatus = att;
        if (halaqaName != null && halaqaName.isNotEmpty) {
          _title = halaqaName;
        } else if (name != null && name.isNotEmpty) {
          _title = name;
        }
        _selectedType = initial;
        _loading = false;
      });

      if (initial != null) {
        await _loadProgressFor(initial);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is HomeException ? e.message : e.toString();
      });
    }
  }

  Future<void> _loadProgressFor(PlanItemType type) async {
    StudyPlanItemRef? item;
    for (final i in _items) {
      if (i.type == type) {
        item = i;
        break;
      }
    }
    if (item == null) return;

    setState(() {
      _loadingTab = true;
      _error = null;
    });

    final repo = ref.read(homeRepositoryProvider);
    try {
      // Enrich plan range from plan-reference if names missing.
      StudyPlanItemRef plan = item;
      if (plan.fromSurahName == null || plan.toSurahName == null) {
        final refItem = await repo.getPlanItemReference(plan.id);
        if (refItem != null) {
          plan = StudyPlanItemRef(
            id: plan.id,
            type: plan.type,
            fromSurah: refItem.fromSurah ?? plan.fromSurah,
            fromAyah: refItem.fromAyah ?? plan.fromAyah,
            toSurah: refItem.toSurah ?? plan.toSurah,
            toAyah: refItem.toAyah ?? plan.toAyah,
            fromSurahName: refItem.fromSurahName ?? plan.fromSurahName,
            toSurahName: refItem.toSurahName ?? plan.toSurahName,
            amountType: refItem.amountType ?? plan.amountType,
            amountValue: refItem.amountValue ?? plan.amountValue,
            direction: refItem.direction ?? plan.direction,
          );
          setState(() {
            _items = [
              for (final i in _items)
                if (i.id == plan.id) plan else i,
            ];
          });
        }
      }

      final snap = await repo.getDailyProgress(
        studentId: widget.studentId,
        date: _date,
        studyPlanItemId: plan.id,
      );
      if (!mounted) return;
      _applySnapshot(type, plan, snap);
      setState(() => _loadingTab = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingTab = false;
        _error = e is HomeException ? e.message : e.toString();
      });
    }
  }

  void _applySnapshot(
    PlanItemType type,
    StudyPlanItemRef plan,
    DailyProgressSnapshot snap,
  ) {
    _progress = snap;

    final endSurah = snap.preferredEndSurah ?? plan.toSurah ?? plan.fromSurah;
    final endAyah = snap.preferredEndAyah ?? plan.toAyah ?? plan.fromAyah;

    if (type == PlanItemType.murajaa) {
      for (final r in _murRows) {
        r.dispose();
      }
      _murRows.clear();

      if (snap.murajaaRanges.isNotEmpty) {
        for (final r in snap.murajaaRanges) {
          _murRows.add(
            _MurRow(
              endSurah: r.endSurah ?? endSurah ?? 1,
              endAyah: TextEditingController(
                text: '${r.endAyah ?? endAyah ?? 1}',
              ),
              startSurah: r.startSurah ??
                  snap.preferredStartSurah ??
                  plan.fromSurah,
              startAyah: r.startAyah ??
                  snap.preferredStartAyah ??
                  plan.fromAyah,
            ),
          );
        }
      } else {
        _murRows.add(
          _MurRow(
            endSurah: endSurah ?? 1,
            endAyah: TextEditingController(text: '${endAyah ?? 1}'),
            startSurah: snap.preferredStartSurah ?? plan.fromSurah,
            startAyah: snap.preferredStartAyah ?? plan.fromAyah,
          ),
        );
      }
    } else {
      _endSurah = endSurah;
      _endAyahCtrl.text = '${endAyah ?? 1}';
    }
    setState(() {});
  }

  Future<void> _selectTab(PlanItemType type) async {
    if (_selectedType == type) return;
    setState(() => _selectedType = type);
    await _loadProgressFor(type);
  }

  void _addMurRow() {
    final last = _murRows.isNotEmpty ? _murRows.last : null;
    setState(() {
      _murRows.add(
        _MurRow(
          endSurah: last?.endSurah ?? _endSurah ?? 1,
          endAyah: TextEditingController(text: '1'),
          startSurah: last?.endSurah,
          startAyah: int.tryParse(last?.endAyah.text ?? ''),
        ),
      );
    });
  }

  void _removeMurRow(int index) {
    if (_murRows.length <= 1) return;
    setState(() {
      _murRows[index].dispose();
      _murRows.removeAt(index);
    });
  }

  Future<void> _save() async {
    final item = _activeItem;
    final type = _selectedType;
    if (item == null || type == null) return;

    final snap = _progress;
    final startSurah = snap?.preferredStartSurah ??
        item.fromSurah ??
        1;
    final startAyah = snap?.preferredStartAyah ?? item.fromAyah ?? 1;

    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(homeRepositoryProvider);
    try {
      if (type == PlanItemType.murajaa) {
        final ranges = <Map<String, int>>[];
        var prevEndSurah = startSurah;
        var prevEndAyah = startAyah;
        for (var i = 0; i < _murRows.length; i++) {
          final row = _murRows[i];
          final endS = row.endSurah;
          final endA = int.tryParse(row.endAyah.text.trim());
          if (endS == null || endA == null || endA < 1) {
            throw HomeException('تحقق من إلى سورة / إلى آية في صف المراجعة');
          }
          final sSurah = i == 0
              ? (row.startSurah ?? startSurah)
              : (row.startSurah ?? prevEndSurah);
          final sAyah = i == 0
              ? (row.startAyah ?? startAyah)
              : (row.startAyah ?? prevEndAyah);
          ranges.add({
            'actualStartSurah': sSurah,
            'actualStartAyah': sAyah,
            'actualEndSurah': endS,
            'actualEndAyah': endA,
          });
          prevEndSurah = endS;
          prevEndAyah = endA;
        }
        await repo.saveMurajaaProgress(
          studentId: widget.studentId,
          termDayDate: _date,
          studyPlanItemId: item.id,
          progressRanges: ranges,
        );
      } else {
        final endS = _endSurah;
        final endA = int.tryParse(_endAyahCtrl.text.trim());
        if (endS == null || endA == null || endA < 1) {
          throw HomeException('حدد إلى سورة وإلى آية');
        }
        await repo.saveDailyProgress(
          studentId: widget.studentId,
          termDayDate: _date,
          studyPlanItemId: item.id,
          actualStartSurah: startSurah,
          actualStartAyah: startAyah,
          actualEndSurah: endS,
          actualEndAyah: endA,
          existingProgressId:
              snap != null && snap.hasSavedProgress ? snap.id : null,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التقدّم')),
      );
      await _loadProgressFor(type);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is HomeException ? e.message : e.toString();
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _surahName(int number) {
    for (final s in _surahs) {
      if (s.number == number) return s.name;
    }
    return 'سورة $number';
  }

  String _amountDisplay(StudyPlanItemRef item) {
    // Prefer planned amount from progress snapshot when present.
    final snap = _progress;
    if (snap?.plannedAmountValue != null) {
      final tmp = StudyPlanItemRef(
        id: item.id,
        type: item.type,
        amountType: snap!.plannedAmountType ?? item.amountType,
        amountValue: snap.plannedAmountValue,
      );
      return tmp.formatAmountLabel();
    }
    return item.formatAmountLabel();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_loading &&
        !_loadingTab &&
        !_saving &&
        !_isUnbound &&
        _activeItem != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.parchment,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(title: _title, onBack: () => context.pop()),
                const SizedBox(height: 8),
                _ContextRow(date: _date),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  _ErrorBanner(
                    message: _error!,
                    onRetry: _bootstrap,
                  ),
                ],
                const SizedBox(height: 10),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.brand,
                          ),
                        )
                      : _isUnbound
                          ? _UnboundBody(
                              studentName:
                                  _studentName ?? 'الطالب #${widget.studentId}',
                              onAssignStub: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'ربط الخطة يتم من إدارة الحلقة (قريباً)',
                                    ),
                                  ),
                                );
                              },
                              onBackToHalaqa: () {
                                if (_hasHalaqa) {
                                  context.go(
                                    '/halaqa/${widget.halaqaId!.trim()}',
                                  );
                                } else {
                                  context.pop();
                                }
                              },
                            )
                          : ListView(
                              children: [
                                _StudentCard(
                                  name: _studentName ??
                                      'الطالب #${widget.studentId}',
                                  attendanceStatus: _attendanceStatus,
                                  items: _items,
                                  selected: _selectedType,
                                  onSelect: _selectTab,
                                  loadingTab: _loadingTab,
                                  activeItem: _activeItem,
                                  surahName: _surahName,
                                  amountDisplay: _activeItem == null
                                      ? '—'
                                      : _amountDisplay(_activeItem!),
                                  endSurah: _endSurah,
                                  endAyahCtrl: _endAyahCtrl,
                                  surahs: _surahs,
                                  onEndSurah: (n) =>
                                      setState(() => _endSurah = n),
                                  murRows: _murRows,
                                  onMurSurah: (i, n) => setState(
                                    () => _murRows[i].endSurah = n,
                                  ),
                                  onAddMur: _addMurRow,
                                  onRemoveMur: _removeMurRow,
                                ),
                              ],
                            ),
                ),
                if (!_isUnbound && !_loading) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: canSave ? _save : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.brand.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('حفظ التقدّم'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MurRow {
  _MurRow({
    required this.endSurah,
    required this.endAyah,
    this.startSurah,
    this.startAyah,
  });

  int? endSurah;
  final TextEditingController endAyah;
  int? startSurah;
  int? startAyah;

  void dispose() => endAyah.dispose();
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            elevation: 0,
            child: InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(10),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.brand,
                  size: 22,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.brand,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({required this.date});

  final String date;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'الطلاب',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.brand,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.borderStrong, width: 1.5),
          ),
          child: Text(
            date,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFC62828).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('إعادة')),
        ],
      ),
    );
  }
}

class _UnboundBody extends StatelessWidget {
  const _UnboundBody({
    required this.studentName,
    required this.onAssignStub,
    required this.onBackToHalaqa,
  });

  final String studentName;
  final VoidCallback onAssignStub;
  final VoidCallback onBackToHalaqa;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              const Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                  children: [
                    TextSpan(text: 'الخطة: '),
                    TextSpan(
                      text: 'غير محددة',
                      style: TextStyle(color: Color(0xFF8A6A12)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'لا توجد خطة دراسية مربوطة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'لا يمكن تسجيل الحفظ أو التثبيت أو المراجعة قبل ربط خطة لهذا الطالب في الحلقة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: FilledButton(
                  onPressed: onAssignStub,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'تعيين / ربط خطة دراسية',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onBackToHalaqa,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(
                      color: AppColors.borderStrong,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'العودة للحلقة',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.name,
    required this.attendanceStatus,
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.loadingTab,
    required this.activeItem,
    required this.surahName,
    required this.amountDisplay,
    required this.endSurah,
    required this.endAyahCtrl,
    required this.surahs,
    required this.onEndSurah,
    required this.murRows,
    required this.onMurSurah,
    required this.onAddMur,
    required this.onRemoveMur,
  });

  final String name;
  final String? attendanceStatus;
  final List<StudyPlanItemRef> items;
  final PlanItemType? selected;
  final ValueChanged<PlanItemType> onSelect;
  final bool loadingTab;
  final StudyPlanItemRef? activeItem;
  final String Function(int) surahName;
  final String amountDisplay;
  final int? endSurah;
  final TextEditingController endAyahCtrl;
  final List<QuranSurah> surahs;
  final ValueChanged<int> onEndSurah;
  final List<_MurRow> murRows;
  final void Function(int index, int surah) onMurSurah;
  final VoidCallback onAddMur;
  final ValueChanged<int> onRemoveMur;

  @override
  Widget build(BuildContext context) {
    final typesPresent = items.map((e) => e.type).toSet();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A15241C),
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.brand,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _LockedAttendanceRow(status: attendanceStatus),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 5,
                      runSpacing: 5,
                      children: [
                        for (final t in [
                          PlanItemType.hifz,
                          PlanItemType.tathbeet,
                          PlanItemType.murajaa,
                        ])
                          if (typesPresent.contains(t))
                            _TypeTab(
                              type: t,
                              selected: selected == t,
                              onTap: () => onSelect(t),
                            ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (loadingTab)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.brand,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    else if (activeItem != null) ...[
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(text: 'من الخطة: '),
                            TextSpan(
                              text: activeItem!.formatPlanRange(
                                surahName: surahName,
                              ),
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'المقدار المطلوب اليوم',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        amountDisplay,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(height: 1, color: AppColors.border),
                      const SizedBox(height: 12),
                      Text(
                        selected == PlanItemType.murajaa
                            ? 'ما أنجزه الطالب اليوم — مراجعة'
                            : 'ما أنجزه الطالب اليوم',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.brand,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (selected == PlanItemType.murajaa)
                        _MurajaaEditor(
                          rows: murRows,
                          surahs: surahs,
                          onSurah: onMurSurah,
                          onAdd: onAddMur,
                          onRemove: onRemoveMur,
                        )
                      else
                        _EndPairRow(
                          surahs: surahs,
                          endSurah: endSurah,
                          endAyahCtrl: endAyahCtrl,
                          onSurah: onEndSurah,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LockedAttendanceRow extends StatelessWidget {
  const _LockedAttendanceRow({required this.status});

  final String? status;

  static const _chips = [
    ('PRESENT', 'حاضر'),
    ('ABSENT', 'غائب'),
    ('LATE', 'متأخر'),
    ('LEAVE', 'معذور'),
  ];

  @override
  Widget build(BuildContext context) {
    final raw = status?.trim().toUpperCase();
    String? on;
    if (raw == 'PRESENT') {
      on = 'PRESENT';
    } else if (raw == 'ABSENT') {
      on = 'ABSENT';
    } else if (raw == 'LATE') {
      on = 'LATE';
    } else if (raw == 'LEAVE' || raw == 'EXCUSED') {
      on = 'LEAVE';
    }

    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: [
          for (final c in _chips)
            Opacity(
              opacity: 0.55,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: on == c.$1
                      ? AppColors.presentSoft
                      : const Color(0xFFF7F4EE),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: on == c.$1
                        ? AppColors.brand
                        : const Color(0xFFD9D3C7),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  c.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: on == c.$1
                        ? AppColors.brand
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final PlanItemType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (type) {
      PlanItemType.hifz => (AppColors.hifzSoft, AppColors.hifz),
      PlanItemType.tathbeet => (AppColors.tathbeetSoft, AppColors.tathbeet),
      PlanItemType.murajaa => (AppColors.murajaaSoft, AppColors.murajaa),
    };

    return Opacity(
      opacity: selected ? 1 : 0.55,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? fg : fg.withValues(alpha: 0.3),
                width: selected ? 1.5 : 1.5,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: fg, spreadRadius: 0.5, blurRadius: 0)]
                  : null,
            ),
            child: Text(
              type.labelAr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EndPairRow extends StatelessWidget {
  const _EndPairRow({
    required this.surahs,
    required this.endSurah,
    required this.endAyahCtrl,
    required this.onSurah,
  });

  final List<QuranSurah> surahs;
  final int? endSurah;
  final TextEditingController endAyahCtrl;
  final ValueChanged<int> onSurah;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _SurahField(
            label: 'إلى سورة',
            value: endSurah,
            surahs: surahs,
            onChanged: onSurah,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AyahField(label: 'إلى آية', controller: endAyahCtrl),
        ),
      ],
    );
  }
}

class _MurajaaEditor extends StatelessWidget {
  const _MurajaaEditor({
    required this.rows,
    required this.surahs,
    required this.onSurah,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_MurRow> rows;
  final List<QuranSurah> surahs;
  final void Function(int index, int surah) onSurah;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _SurahField(
                  label: 'إلى سورة',
                  value: rows[i].endSurah,
                  surahs: surahs,
                  onChanged: (n) => onSurah(i, n),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AyahField(
                  label: 'إلى آية',
                  controller: rows[i].endAyah,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                height: 40,
                child: OutlinedButton(
                  onPressed: rows.length <= 1 ? null : () => onRemove(i),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: const Color(0xFFC62828),
                    disabledForegroundColor:
                        const Color(0xFFC62828).withValues(alpha: 0.35),
                    side: const BorderSide(
                      color: Color(0xFFC62828),
                      width: 1.5,
                    ),
                    backgroundColor: const Color(0xFFFDECEC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    '×',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (i < rows.length - 1) const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 40,
          child: OutlinedButton(
            onPressed: onAdd,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brand,
              backgroundColor: AppColors.brandSoft,
              side: const BorderSide(
                color: AppColors.brand,
                width: 1.5,
                style: BorderStyle.solid,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              '+ إضافة مراجعة',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }
}

class _SurahField extends StatelessWidget {
  const _SurahField({
    required this.label,
    required this.value,
    required this.surahs,
    required this.onChanged,
  });

  final String label;
  final int? value;
  final List<QuranSurah> surahs;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = surahs.isNotEmpty
        ? surahs
        : List.generate(
            114,
            (i) => QuranSurah(number: i + 1, name: 'سورة ${i + 1}'),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderStrong, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: value != null &&
                      items.any((s) => s.number == value)
                  ? value
                  : (items.isNotEmpty ? items.first.number : null),
              items: [
                for (final s in items)
                  DropdownMenuItem(
                    value: s.number,
                    child: Text(
                      s.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AyahField extends StatelessWidget {
  const _AyahField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 40,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.borderStrong,
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.borderStrong,
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.brand,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
