import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/util/school_calendar.dart';
import '../../home/data/home_repository.dart';
import '../data/dto/halaqa_student.dart';

enum _HalaqaTab { attendance, progress, overview }

/// Wired ḥalaqa detail v2 — locked 3-tab shell (attendance / progress / overview).
class HalaqaDetailPage extends ConsumerStatefulWidget {
  const HalaqaDetailPage({super.key, required this.halaqaId});

  final String halaqaId;

  @override
  ConsumerState<HalaqaDetailPage> createState() => _HalaqaDetailPageState();
}

class _HalaqaDetailPageState extends ConsumerState<HalaqaDetailPage> {
  bool _loading = true;
  bool _saving = false;
  bool _editingAttendance = false;
  String? _error;
  List<HalaqaStudent> _students = const [];
  String _halaqaName = '';
  late String _date; // YYYY-MM-DD
  Set<String> _holidays = const {};
  _HalaqaTab _tab = _HalaqaTab.attendance;
  Map<String, AttendanceMark> _draft = const {};

  static const _workdayCaption =
      'أيام العمل أحد–خميس · يتخطى الجمعة/السبت والعطل';

  @override
  void initState() {
    super.initState();
    _date = SchoolCalendar.toYmd(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool fromRefresh = false}) async {
    if (!fromRefresh) {
      setState(() {
        _loading = true;
        _error = null;
        _editingAttendance = false;
      });
    } else {
      setState(() {
        _error = null;
        _editingAttendance = false;
      });
    }

    final repo = ref.read(homeRepositoryProvider);

    // Holidays never block the screen — empty set + weekends still enforced.
    final holidays = await repo.getHolidayDatesForHalqa(widget.halaqaId);
    final snapped = SchoolCalendar.snapToSchoolDay(DateTime.now(), holidays);
    final snappedYmd = SchoolCalendar.toYmd(snapped);

    if (!mounted) return;
    setState(() {
      _holidays = holidays;
      if (!fromRefresh ||
          !SchoolCalendar.isSchoolDay(
            SchoolCalendar.parseYmd(_date) ?? DateTime.now(),
            holidays,
          )) {
        _date = snappedYmd;
      }
    });

    try {
      final results = await Future.wait([
        repo.getStudentsByHalqaId(halaqaId: widget.halaqaId, date: _date),
        repo.getHalqaName(widget.halaqaId),
      ]);
      if (!mounted) return;
      final students = results[0] as List<HalaqaStudent>;
      final name = results[1] as String?;
      setState(() {
        _students = students;
        if (name != null && name.isNotEmpty) {
          _halaqaName = name;
        }
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is HomeException ? e.message : e.toString();
      });
    }
  }

  Future<void> _reloadRoster({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
        _editingAttendance = false;
      });
    }
    final repo = ref.read(homeRepositoryProvider);
    try {
      final students = await repo.getStudentsByHalqaId(
        halaqaId: widget.halaqaId,
        date: _date,
      );
      if (!mounted) return;
      setState(() {
        _students = students;
        _loading = false;
        _error = null;
        if (!silent) _editingAttendance = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is HomeException ? e.message : e.toString();
      });
    }
  }

  Future<void> _setDate(DateTime day) async {
    final local = DateTime(day.year, day.month, day.day);
    if (!SchoolCalendar.isSchoolDay(local, _holidays)) return;
    final ymd = SchoolCalendar.toYmd(local);
    if (ymd == _date) return;
    setState(() {
      _date = ymd;
      _editingAttendance = false;
      _draft = const {};
    });
    await _reloadRoster();
  }

  Future<void> _pickDate() async {
    final current = SchoolCalendar.parseYmd(_date) ?? DateTime.now();
    final now = DateTime.now();
    final first = DateTime(now.year - 1, now.month, now.day);
    final last = DateTime(now.year + 1, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(first)
          ? first
          : (current.isAfter(last) ? last : current),
      firstDate: first,
      lastDate: last,
      selectableDayPredicate: (day) =>
          SchoolCalendar.isSchoolDay(day, _holidays),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.brand,
                    onPrimary: Colors.white,
                  ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    await _setDate(picked);
  }

  void _enterEdit() {
    final draft = <String, AttendanceMark>{};
    for (final s in _students) {
      draft[s.id] = s.attendanceMark ?? AttendanceMark.present;
    }
    setState(() {
      _draft = draft;
      _editingAttendance = true;
    });
  }

  Future<void> _saveAttendance() async {
    if (_students.isEmpty || _saving) return;
    setState(() => _saving = true);
    final repo = ref.read(homeRepositoryProvider);
    final entries = [
      for (final s in _students)
        (
          userId: s.id,
          status: (_draft[s.id] ?? AttendanceMark.present).apiValue,
          previousStatus: s.attendanceStatus,
        ),
    ];
    try {
      await repo.saveHalaqaAttendance(
        halaqaId: widget.halaqaId,
        date: _date,
        entries: entries,
      );
      if (!mounted) return;
      setState(() {
        _students = [
          for (final s in _students)
            s.copyWith(
              attendanceStatus:
                  (_draft[s.id] ?? AttendanceMark.present).apiValue,
            ),
        ];
        _editingAttendance = false;
        _draft = const {};
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الحضور')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final msg = e is HomeException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> _openProgress(HalaqaStudent student) async {
    await context.push(
      '/student/${student.id}/progress?date=$_date&halaqaId=${widget.halaqaId}',
    );
    if (mounted) await _reloadRoster(silent: true);
  }

  AttendanceMark? _markFor(HalaqaStudent student) {
    if (_editingAttendance) return _draft[student.id];
    return student.attendanceMark;
  }

  (int present, int absent, int late, int leave) _counts() {
    var present = 0;
    var absent = 0;
    var late = 0;
    var leave = 0;
    for (final s in _students) {
      switch (_markFor(s)) {
        case AttendanceMark.present:
          present++;
        case AttendanceMark.absent:
          absent++;
        case AttendanceMark.late:
          late++;
        case AttendanceMark.leave:
          leave++;
        case null:
          break;
      }
    }
    return (present, absent, late, leave);
  }

  @override
  Widget build(BuildContext context) {
    final title = _halaqaName.isEmpty ? 'حلقة' : _halaqaName;
    final showCta = _tab == _HalaqaTab.attendance && !_loading;

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
                _TopBar(onBack: () => context.pop()),
                const SizedBox(height: 4),
                _HalaqaHead(name: title, count: _students.length),
                const SizedBox(height: 8),
                _DateRow(date: _date, onPickDate: _pickDate),
                const SizedBox(height: 10),
                _SegTabs(
                  selected: _tab,
                  onSelect: (tab) => setState(() => _tab = tab),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  _ErrorBanner(
                    message: _error!,
                    onRetry: () => _load(),
                  ),
                ],
                const SizedBox(height: 12),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.brand,
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.brand,
                          onRefresh: () => _load(fromRefresh: true),
                          child: switch (_tab) {
                            _HalaqaTab.attendance => _attendanceBody(),
                            _HalaqaTab.progress => _progressBody(),
                            _HalaqaTab.overview => _overviewBody(title),
                          },
                        ),
                ),
                if (showCta) ...[
                  const SizedBox(height: 8),
                  _AttendanceCta(
                    editing: _editingAttendance,
                    saving: _saving,
                    enabled: _students.isNotEmpty && !_saving,
                    onEdit: _enterEdit,
                    onSave: _saveAttendance,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _attendanceBody() {
    final counts = _counts();
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _AttSummary(
          present: counts.$1,
          absent: counts.$2,
          late: counts.$3,
          leave: counts.$4,
          total: _students.length,
        ),
        const SizedBox(height: 12),
        if (_students.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 36),
            child: Text(
              'لا يوجد طلاب',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          ..._students.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AttendanceCard(
                student: s,
                editing: _editingAttendance,
                selected: _markFor(s),
                onSelect: (mark) => setState(() {
                  _draft = Map<String, AttendanceMark>.from(_draft)
                    ..[s.id] = mark;
                }),
              ),
            ),
          ),
      ],
    );
  }

  Widget _progressBody() {
    if (_students.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 48),
          Text(
            'لا يوجد طلاب',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _students.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = _students[i];
        return _ProgressCard(
          student: s,
          onOpen: () => _openProgress(s),
        );
      },
    );
  }

  Widget _overviewBody(String title) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _MetaCard(name: title, count: _students.length),
        const SizedBox(height: 12),
        const Text(
          'قائمة الطلاب',
          style: TextStyle(
            color: AppColors.brand,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        if (_students.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: Text(
              'لا يوجد طلاب',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          ..._students.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RosterCard(name: s.name),
            ),
          ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

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
              borderRadius: BorderRadius.circular(10),
              onTap: onBack,
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  // In RTL, arrow_forward points toward the trailing edge (visual back).
                  Icons.arrow_forward,
                  color: AppColors.brand,
                  size: 20,
                ),
              ),
            ),
          ),
          const Expanded(
            child: Text(
              'المعلم',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
}

class _HalaqaHead extends StatelessWidget {
  const _HalaqaHead({required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.brand,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count طلاب',
            style: const TextStyle(
              color: AppColors.brand,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.onPickDate});

  final String date;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.borderStrong, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    date,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          _HalaqaDetailPageState._workdayCaption,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _SegTabs extends StatelessWidget {
  const _SegTabs({required this.selected, required this.onSelect});

  final _HalaqaTab selected;
  final ValueChanged<_HalaqaTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SegTab(
            key: const Key('halaqa-tab-attendance'),
            label: 'الحضور',
            active: selected == _HalaqaTab.attendance,
            onTap: () => onSelect(_HalaqaTab.attendance),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _SegTab(
            key: const Key('halaqa-tab-progress'),
            label: 'التقدم',
            active: selected == _HalaqaTab.progress,
            onTap: () => onSelect(_HalaqaTab.progress),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _SegTab(
            key: const Key('halaqa-tab-overview'),
            label: 'نظرة عامة',
            active: selected == _HalaqaTab.overview,
            onTap: () => onSelect(_HalaqaTab.overview),
          ),
        ),
      ],
    );
  }
}

class _SegTab extends StatelessWidget {
  const _SegTab({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.brandSoft : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active ? AppColors.brand : AppColors.borderStrong,
              width: 1.5,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.18),
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? AppColors.brand : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _AttSummary extends StatelessWidget {
  const _AttSummary({
    required this.present,
    required this.absent,
    required this.late,
    required this.leave,
    required this.total,
  });

  final int present;
  final int absent;
  final int late;
  final int leave;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _StatChip(label: 'حاضر', count: present, present: true),
        _StatChip(label: 'غائب', count: absent),
        _StatChip(label: 'متأخر', count: late),
        _StatChip(label: 'معذور', count: leave),
        _StatChip(label: 'الكل', count: total, all: true),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.count,
    this.present = false,
    this.all = false,
  });

  final String label;
  final int count;
  final bool present;
  final bool all;

  @override
  Widget build(BuildContext context) {
    final bg = present
        ? AppColors.presentSoft
        : (all ? Colors.white : AppColors.chipIdle);
    final fg = present || all ? AppColors.brand : AppColors.textMuted;
    final border = present
        ? AppColors.brand.withValues(alpha: 0.22)
        : (all ? AppColors.borderStrong : AppColors.border);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AccentCard extends StatelessWidget {
  const _AccentCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
      clipBehavior: Clip.antiAlias,
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
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.student,
    required this.editing,
    required this.selected,
    required this.onSelect,
  });

  final HalaqaStudent student;
  final bool editing;
  final AttendanceMark? selected;
  final ValueChanged<AttendanceMark> onSelect;

  @override
  Widget build(BuildContext context) {
    return _AccentCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    student.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (!editing && selected != null) ...[
                  const SizedBox(width: 8),
                  _AttBadge(mark: selected!),
                ],
              ],
            ),
            if (editing) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (final mark in AttendanceMark.values)
                    _AttChip(
                      key: Key('att-chip-${student.id}-${mark.apiValue}'),
                      label: mark.labelAr,
                      selected: selected == mark,
                      onTap: () => onSelect(mark),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttBadge extends StatelessWidget {
  const _AttBadge({required this.mark});

  final AttendanceMark mark;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (mark) {
      AttendanceMark.present => (AppColors.presentSoft, AppColors.brand),
      AttendanceMark.absent => (AppColors.absentBadge, AppColors.absentFg),
      AttendanceMark.late => (AppColors.lateBadge, AppColors.lateFg),
      AttendanceMark.leave => (AppColors.leaveBadge, AppColors.leaveFg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        mark.labelAr,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AttChip extends StatelessWidget {
  const _AttChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.presentSoft : AppColors.chipIdle,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.chipIdleBorder,
              width: 1.5,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.brand.withValues(alpha: 0.18),
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.brand : AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.student, required this.onOpen});

  final HalaqaStudent student;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final recorded = student.hasProgressToday;
    return _AccentCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _MetricPill(
                  kind: _MetricKind.hifz,
                  label: 'حفظ',
                  percent: student.hifzPercent,
                ),
                _MetricPill(
                  kind: _MetricKind.murajaa,
                  label: 'مراجعة',
                  percent: student.murajaaPercent,
                ),
                _MetricPill(
                  kind: _MetricKind.tathbeet,
                  label: 'تثبيت',
                  percent: student.tathbeetPercent,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  recorded ? 'تم اليوم' : 'لم يُسجَّل اليوم',
                  style: TextStyle(
                    color: recorded
                        ? AppColors.progressDone
                        : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onOpen,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          recorded ? 'تعديل' : 'تسجيل تقدّم',
                          style: const TextStyle(
                            color: AppColors.brand,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_left,
                          color: AppColors.brand,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    return _AccentCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.chipIdle,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'أحد–خميس',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$count طلاب',
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RosterCard extends StatelessWidget {
  const _RosterCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return _AccentCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
        child: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _AttendanceCta extends StatelessWidget {
  const _AttendanceCta({
    required this.editing,
    required this.saving,
    required this.enabled,
    required this.onEdit,
    required this.onSave,
  });

  final bool editing;
  final bool saving;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        key: Key(editing ? 'halaqa-cta-save' : 'halaqa-cta-edit'),
        onPressed: enabled ? (editing ? onSave : onEdit) : null,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.brand.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        child: saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(editing ? 'حفظ الحضور' : 'تعديل الحضور'),
      ),
    );
  }
}

enum _MetricKind { hifz, tathbeet, murajaa }

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.kind,
    required this.label,
    required this.percent,
  });

  final _MetricKind kind;
  final String label;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final (bg, labelColor, border) = switch (kind) {
      _MetricKind.hifz => (
          AppColors.hifzSoft,
          AppColors.hifz,
          AppColors.hifz.withValues(alpha: 0.25),
        ),
      _MetricKind.tathbeet => (
          AppColors.tathbeetSoft,
          AppColors.tathbeet,
          AppColors.tathbeet.withValues(alpha: 0.30),
        ),
      _MetricKind.murajaa => (
          AppColors.murajaaSoft,
          AppColors.murajaa,
          const Color(0xFFD4AF37).withValues(alpha: 0.45),
        ),
    };

    final valueColor = percent < 34
        ? AppColors.percentLow
        : (percent < 67
            ? switch (kind) {
                _MetricKind.hifz => AppColors.percentMid,
                _MetricKind.tathbeet => AppColors.tathbeetPercentMid,
                _MetricKind.murajaa => AppColors.murajaaPercentMid,
              }
            : switch (kind) {
                _MetricKind.hifz => AppColors.percentHigh,
                _MetricKind.tathbeet => AppColors.tathbeetPercentHigh,
                _MetricKind.murajaa => AppColors.murajaaPercentHigh,
              });
    final shown = percent.round().clamp(0, 100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$shown%',
            style: TextStyle(
              color: valueColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.absentSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8B4B4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message.isEmpty ? 'تعذر التحميل' : message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(foregroundColor: AppColors.brand),
            child: const Text(
              'إعادة المحاولة',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
