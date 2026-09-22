import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/util/school_calendar.dart';
import '../../home/data/home_repository.dart';
import '../data/attendance_status.dart';
import '../data/dto/halaqa_student.dart';

enum _DetailTab { attendance, progress, overview }

/// Ḥalaqa detail v2: attendance / progress / overview on `/halaqa/:id`.
class HalaqaDetailPage extends ConsumerStatefulWidget {
  const HalaqaDetailPage({
    super.key,
    required this.halaqaId,
    this.startInEdit = false,
  });

  final String halaqaId;
  final bool startInEdit;

  @override
  ConsumerState<HalaqaDetailPage> createState() => _HalaqaDetailPageState();
}

class _HalaqaDetailPageState extends ConsumerState<HalaqaDetailPage> {
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  String? _error;
  List<HalaqaStudent> _students = const [];
  String _title = 'المعلم';
  late String _date; // YYYY-MM-DD
  Set<String> _holidays = const {};
  _DetailTab _tab = _DetailTab.attendance;
  NestAttendanceStatus? _filter;

  /// Optimistic chip status keyed by Nest User.id.
  final Map<String, NestAttendanceStatus> _uiStatus = {};

  /// Last known Nest raw status (NOT_MARKED / PRESENT / …) for POST vs PUT.
  final Map<String, String?> _serverStatus = {};

  /// Snapshot of [_uiStatus] when edit started — dirty = current ≠ snapshot.
  final Map<String, NestAttendanceStatus> _editBaseline = {};

  @override
  void initState() {
    super.initState();
    _editing = widget.startInEdit;
    _date = SchoolCalendar.toYmd(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _syncRoster(List<HalaqaStudent> students) {
    _students = students;
    _serverStatus
      ..clear()
      ..addEntries(students.map((s) => MapEntry(s.id, s.attendanceStatus)));
    _uiStatus
      ..clear()
      ..addEntries(
        students.map(
          (s) => MapEntry(s.id, displayAttendanceStatus(s.attendanceStatus)),
        ),
      );
    if (_editing) {
      _editBaseline
        ..clear()
        ..addAll(_uiStatus);
    }
  }

  NestAttendanceStatus _statusFor(HalaqaStudent s) =>
      _uiStatus[s.id] ?? displayAttendanceStatus(s.attendanceStatus);

  List<String> _dirtyIds() {
    final ids = <String>[];
    for (final s in _students) {
      final current = _uiStatus[s.id];
      final base = _editBaseline[s.id];
      if (current != null && base != null && current != base) {
        ids.add(s.id);
      }
    }
    return ids;
  }

  int _countFor(NestAttendanceStatus status) {
    var n = 0;
    for (final s in _students) {
      if (_statusFor(s) == status) n++;
    }
    return n;
  }

  List<HalaqaStudent> _visibleStudents() {
    if (_tab != _DetailTab.attendance || _filter == null) {
      return _students;
    }
    return _students.where((s) => _statusFor(s) == _filter).toList();
  }

  void _enterEdit() {
    setState(() {
      _editing = true;
      _editBaseline
        ..clear()
        ..addAll(_uiStatus);
    });
  }

  Future<void> _openStudentHub(HalaqaStudent s) async {
    if (_editing && _dirtyIds().isNotEmpty) {
      final ok = await _saveAttendance();
      if (!ok) return;
    }
    if (!mounted) return;
    context.push(
      '/student/${s.id}?date=$_date&halaqaId=${widget.halaqaId}',
    );
  }

  Future<void> _openProgress(HalaqaStudent s) async {
    context.push(
      '/student/${s.id}/progress?date=$_date&halaqaId=${widget.halaqaId}',
    );
  }

  Future<bool> _saveAttendance() async {
    if (_saving) return false;
    final dirty = _dirtyIds();
    if (dirty.isEmpty) {
      if (mounted) {
        setState(() {
          _editing = false;
          _editBaseline.clear();
        });
      }
      return true;
    }

    setState(() => _saving = true);
    final repo = ref.read(homeRepositoryProvider);
    try {
      for (final id in dirty) {
        final next = _uiStatus[id];
        if (next == null) continue;
        final prev = _serverStatus[id];
        await repo.saveStudentAttendance(
          halaqaId: widget.halaqaId,
          date: _date,
          studentUserId: id,
          status: next.apiValue,
          previousStatus: prev,
        );
        _serverStatus[id] = next.apiValue;
      }
      if (!mounted) return false;
      setState(() {
        _editing = false;
        _saving = false;
        _editBaseline.clear();
      });
      await _reloadRoster();
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() => _saving = false);
      final msg = e is HomeException ? e.message : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'تعذر حفظ الحضور' : msg)),
      );
      return false;
    }
  }

  Future<void> _load({bool fromRefresh = false}) async {
    if (fromRefresh && (_editing || _saving)) return;
    if (!fromRefresh) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }

    final repo = ref.read(homeRepositoryProvider);

    // Holidays never block the screen — empty set + weekends still enforced.
    final holidays = await repo.getHolidayDatesForHalqa(widget.halaqaId);
    final snapped = SchoolCalendar.snapToSchoolDay(DateTime.now(), holidays);
    final snappedYmd = SchoolCalendar.toYmd(snapped);

    if (!mounted) return;
    setState(() {
      _holidays = holidays;
      // On first load / full refresh, snap initial date if today is off-day.
      // Keep user-selected date on pull-to-refresh if already set to a school day.
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
        _syncRoster(students);
        if (name != null && name.isNotEmpty) {
          _title = name;
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

  /// Reload roster only (keep title) after a date change.
  Future<void> _reloadRoster() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(homeRepositoryProvider);
    try {
      final students = await repo.getStudentsByHalqaId(
        halaqaId: widget.halaqaId,
        date: _date,
      );
      if (!mounted) return;
      setState(() {
        _syncRoster(students);
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

  Future<void> _setDate(DateTime day) async {
    final local = DateTime(day.year, day.month, day.day);
    if (!SchoolCalendar.isSchoolDay(local, _holidays)) return;
    final ymd = SchoolCalendar.toYmd(local);
    if (ymd == _date) return;
    setState(() {
      _date = ymd;
      _editing = false;
      _editBaseline.clear();
    });
    await _reloadRoster();
  }

  Future<void> _goPreviousSchoolDay() async {
    final current = SchoolCalendar.parseYmd(_date) ?? DateTime.now();
    final prev = SchoolCalendar.previousSchoolDay(current, _holidays);
    await _setDate(prev);
  }

  Future<void> _goNextSchoolDay() async {
    final current = SchoolCalendar.parseYmd(_date) ?? DateTime.now();
    final next = SchoolCalendar.nextSchoolDay(current, _holidays);
    final now = DateTime.now();
    final max = DateTime(now.year + 1, now.month, now.day);
    if (next.isAfter(max)) return;
    await _setDate(next);
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

  @override
  Widget build(BuildContext context) {
    final showAttendanceChrome = _tab == _DetailTab.attendance;
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
                _TopBar(
                  title: _title,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(height: 8),
                _TitleRow(name: _title, count: _students.length),
                const SizedBox(height: 8),
                _DateBar(
                  date: _date,
                  onPrev: _goPreviousSchoolDay,
                  onNext: _goNextSchoolDay,
                  onPickDate: _pickDate,
                ),
                const SizedBox(height: 6),
                const Text(
                  'أيام العمل أحد–خميس · يتخطى الجمعة/السبت والعطل',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  _ErrorBanner(
                    message: _error!,
                    onRetry: () => _load(),
                  ),
                ],
                const SizedBox(height: 10),
                _SegmentedTabs(
                  tab: _tab,
                  onChanged: (t) => setState(() => _tab = t),
                ),
                if (showAttendanceChrome) ...[
                  const SizedBox(height: 10),
                  _AttendanceSummary(
                    present: _countFor(NestAttendanceStatus.present),
                    absent: _countFor(NestAttendanceStatus.absent),
                    late: _countFor(NestAttendanceStatus.late),
                    leave: _countFor(NestAttendanceStatus.leave),
                    total: _students.length,
                    selected: _filter,
                    onSelected: (s) => setState(() => _filter = s),
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
                      : RefreshIndicator(
                          color: AppColors.brand,
                          onRefresh: () => _load(fromRefresh: true),
                          child: _tabList(),
                        ),
                ),
                if (showAttendanceChrome) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: (_saving || _loading)
                          ? null
                          : () async {
                              if (_editing) {
                                await _saveAttendance();
                              } else {
                                _enterEdit();
                              }
                            },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.brand.withValues(alpha: 0.45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      child: Text(_editing ? 'حفظ الحضور' : 'تعديل الحضور'),
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

  Widget _tabList() {
    if (_tab == _DetailTab.overview) {
      return _overviewList();
    }
    if (_tab == _DetailTab.progress) {
      return _progressList();
    }
    return _attendanceList();
  }

  Widget _emptyList(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 48),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _attendanceList() {
    final rows = _visibleStudents();
    if (_students.isEmpty) return _emptyList('لا يوجد طلاب');
    if (rows.isEmpty) return _emptyList('لا يوجد طلاب في هذا التصنيف');
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = rows[i];
        return _AttendanceCard(
          student: s,
          status: _statusFor(s),
          editing: _editing,
          onSelect: _editing
              ? (next) => setState(() => _uiStatus[s.id] = next)
              : null,
          onOpenHub: () => _openStudentHub(s),
        );
      },
    );
  }

  Widget _progressList() {
    if (_students.isEmpty) return _emptyList('لا يوجد طلاب');
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _students.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = _students[i];
        return _ProgressCard(
          student: s,
          onRecord: () => _openProgress(s),
        );
      },
    );
  }

  Widget _overviewList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _OverviewMeta(
          name: _title,
          count: _students.length,
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
          ...[
            for (var i = 0; i < _students.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              _NameOnlyRow(name: _students[i].name),
            ],
          ],
      ],
    );
  }
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
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
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

class _TitleRow extends StatelessWidget {
  const _TitleRow({required this.name, required this.count});

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
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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

class _DateBar extends StatelessWidget {
  const _DateBar({
    required this.date,
    required this.onPrev,
    required this.onNext,
    required this.onPickDate,
  });

  final String date;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Prev (earlier) — first in RTL row sits on the visual right.
        _DateChevron(
          icon: Icons.chevron_right,
          onTap: onPrev,
          tooltip: 'اليوم السابق',
        ),
        Expanded(
          child: Center(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: onPickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: AppColors.borderStrong, width: 1.5),
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
          ),
        ),
        _DateChevron(
          icon: Icons.chevron_left,
          onTap: onNext,
          tooltip: 'اليوم التالي',
        ),
      ],
    );
  }
}

class _DateChevron extends StatelessWidget {
  const _DateChevron({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            icon,
            size: 20,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.tab, required this.onChanged});

  final _DetailTab tab;
  final ValueChanged<_DetailTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Row(
        children: [
          _pill(label: 'الحضور', value: _DetailTab.attendance),
          _pill(label: 'التقدم', value: _DetailTab.progress),
          _pill(label: 'نظرة عامة', value: _DetailTab.overview),
        ],
      ),
    );
  }

  Widget _pill({required String label, required _DetailTab value}) {
    final selected = tab == value;
    return Expanded(
      child: Material(
        color: selected ? AppColors.brandSoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.brand : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.brand,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceSummary extends StatelessWidget {
  const _AttendanceSummary({
    required this.present,
    required this.absent,
    required this.late,
    required this.leave,
    required this.total,
    required this.selected,
    required this.onSelected,
  });

  final int present;
  final int absent;
  final int late;
  final int leave;
  final int total;
  final NestAttendanceStatus? selected;
  final ValueChanged<NestAttendanceStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        _SummaryChip(
          label: 'حاضر',
          count: present,
          selected: selected == NestAttendanceStatus.present,
          onTap: () => onSelected(
            selected == NestAttendanceStatus.present
                ? null
                : NestAttendanceStatus.present,
          ),
        ),
        _SummaryChip(
          label: 'غائب',
          count: absent,
          selected: selected == NestAttendanceStatus.absent,
          onTap: () => onSelected(
            selected == NestAttendanceStatus.absent
                ? null
                : NestAttendanceStatus.absent,
          ),
        ),
        _SummaryChip(
          label: 'متأخر',
          count: late,
          selected: selected == NestAttendanceStatus.late,
          onTap: () => onSelected(
            selected == NestAttendanceStatus.late
                ? null
                : NestAttendanceStatus.late,
          ),
        ),
        _SummaryChip(
          label: 'معذور',
          count: leave,
          selected: selected == NestAttendanceStatus.leave,
          onTap: () => onSelected(
            selected == NestAttendanceStatus.leave
                ? null
                : NestAttendanceStatus.leave,
          ),
        ),
        _SummaryChip(
          label: 'الكل',
          count: total,
          selected: selected == null,
          onTap: () => onSelected(null),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.brandSoft : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.borderStrong,
              width: 1.5,
            ),
          ),
          child: Text(
            '$label $count',
            style: TextStyle(
              color: selected ? AppColors.brand : AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.student,
    required this.status,
    required this.editing,
    required this.onOpenHub,
    this.onSelect,
  });

  final HalaqaStudent student;
  final NestAttendanceStatus status;
  final bool editing;
  final ValueChanged<NestAttendanceStatus>? onSelect;
  final VoidCallback onOpenHub;

  @override
  Widget build(BuildContext context) {
    final accent = status.accent;
    final cardBg = status.cardBackground;
    return Material(
      key: ValueKey('roster-${student.id}'),
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
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
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 6, 12),
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
                      if (editing)
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            for (final s in NestAttendanceStatus.values)
                              _AttChip(
                                key: ValueKey(
                                  'att-chip-${student.id}-${s.apiValue}',
                                ),
                                status: s,
                                selected: status == s,
                                onTap: () => onSelect?.call(s),
                              ),
                          ],
                        )
                      else
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: accent, width: 1.5),
                            ),
                            child: Text(
                              status.labelAr,
                              style: TextStyle(
                                color: accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: onOpenHub,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: Icon(
                      Icons.chevron_left,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
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

class _AttChip extends StatelessWidget {
  const _AttChip({
    super.key,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final NestAttendanceStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = status.accent;
    return Material(
      color: selected ? status.cardBackground : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? accent : AppColors.borderStrong,
              width: 1.5,
            ),
          ),
          child: Text(
            status.labelAr,
            style: TextStyle(
              color: selected ? accent : AppColors.textMuted,
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
  const _ProgressCard({required this.student, required this.onRecord});

  final HalaqaStudent student;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
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
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: onRecord,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text(
                  'تسجيل تقدّم',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewMeta extends StatelessWidget {
  const _OverviewMeta({required this.name, required this.count});

  final String name;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
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
          const SizedBox(height: 6),
          const Text(
            'أحد–خميس',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count طلاب',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _NameOnlyRow extends StatelessWidget {
  const _NameOnlyRow({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
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

    final valueColor = _valueColor(kind, percent);
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

  static Color _valueColor(_MetricKind kind, double percent) {
    // <34 low, <67 mid, else high
    if (percent < 34) return AppColors.percentLow;
    if (percent < 67) {
      return switch (kind) {
        _MetricKind.hifz => AppColors.percentMid,
        _MetricKind.tathbeet => AppColors.tathbeetPercentMid,
        _MetricKind.murajaa => AppColors.murajaaPercentMid,
      };
    }
    return switch (kind) {
      _MetricKind.hifz => AppColors.percentHigh,
      _MetricKind.tathbeet => AppColors.tathbeetPercentHigh,
      _MetricKind.murajaa => AppColors.murajaaPercentHigh,
    };
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
