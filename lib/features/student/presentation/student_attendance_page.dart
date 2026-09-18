import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/util/school_calendar.dart';
import '../../halaqa/data/dto/halaqa_student.dart';
import '../../home/data/home_repository.dart';

/// Nest attendance enums used by chips (LEAVE → معذور label only).
enum NestAttendanceStatus { present, absent, late, leave }

extension on NestAttendanceStatus {
  String get apiValue => switch (this) {
        NestAttendanceStatus.present => 'PRESENT',
        NestAttendanceStatus.absent => 'ABSENT',
        NestAttendanceStatus.late => 'LATE',
        NestAttendanceStatus.leave => 'LEAVE',
      };

  String get labelAr => switch (this) {
        NestAttendanceStatus.present => 'حاضر',
        NestAttendanceStatus.absent => 'غائب',
        NestAttendanceStatus.late => 'متأخر',
        NestAttendanceStatus.leave => 'معذور',
      };
}

NestAttendanceStatus? _parseNestStatus(String? raw) {
  if (raw == null) return null;
  final s = raw.trim().toUpperCase();
  if (s.isEmpty || s == 'NOT_MARKED' || s == 'HOLIDAY' || s == 'NULL') {
    return null;
  }
  return switch (s) {
    'PRESENT' => NestAttendanceStatus.present,
    'ABSENT' => NestAttendanceStatus.absent,
    'LATE' => NestAttendanceStatus.late,
    'LEAVE' || 'EXCUSED' => NestAttendanceStatus.leave,
    _ => null,
  };
}

/// Single-student attendance editor — locked mock student-attendance.html.
class StudentAttendancePage extends ConsumerStatefulWidget {
  const StudentAttendancePage({
    super.key,
    required this.studentId,
    this.date,
    this.halaqaId,
  });

  final String studentId;

  /// YYYY-MM-DD from navigation (ḥalaqa detail).
  final String? date;

  /// Ḥalaqa id required to load roster + save.
  final String? halaqaId;

  @override
  ConsumerState<StudentAttendancePage> createState() =>
      _StudentAttendancePageState();
}

class _StudentAttendancePageState
    extends ConsumerState<StudentAttendancePage> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _title = 'المعلم';
  late String _date;
  Set<String> _holidays = const {};

  HalaqaStudent? _student;
  NestAttendanceStatus? _selected;
  /// Server status used for POST vs PUT heuristic (raw Nest string).
  String? _serverStatus;

  bool get _hasHalaqaContext =>
      widget.halaqaId != null && widget.halaqaId!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    final incoming = SchoolCalendar.parseYmd(widget.date);
    _date = SchoolCalendar.toYmd(incoming ?? DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool fromRefresh = false}) async {
    if (!_hasHalaqaContext) {
      setState(() {
        _loading = false;
        _error = 'افتح من الحلقة';
        _student = null;
        _selected = null;
        _serverStatus = null;
      });
      return;
    }

    if (!fromRefresh) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _error = null);
    }

    final halaqaId = widget.halaqaId!.trim();
    final repo = ref.read(homeRepositoryProvider);

    final holidays = await repo.getHolidayDatesForHalqa(halaqaId);
    final snapped = SchoolCalendar.snapToSchoolDay(
      SchoolCalendar.parseYmd(_date) ?? DateTime.now(),
      holidays,
    );
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
        repo.getStudentsByHalqaId(halaqaId: halaqaId, date: _date),
        repo.getHalqaName(halaqaId),
      ]);
      if (!mounted) return;
      final students = results[0] as List<HalaqaStudent>;
      final name = results[1] as String?;
      HalaqaStudent? match;
      for (final s in students) {
        if (s.id == widget.studentId) {
          match = s;
          break;
        }
      }
      setState(() {
        _student = match;
        _serverStatus = match?.attendanceStatus;
        _selected = _parseNestStatus(match?.attendanceStatus) ??
            NestAttendanceStatus.present;
        if (name != null && name.isNotEmpty) {
          _title = name;
        }
        _loading = false;
        _error = match == null ? 'الطالب غير موجود في هذه الحلقة' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e is HomeException ? e.message : e.toString();
      });
    }
  }

  Future<void> _reloadForDate() async {
    if (!_hasHalaqaContext) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(homeRepositoryProvider);
    try {
      final students = await repo.getStudentsByHalqaId(
        halaqaId: widget.halaqaId!.trim(),
        date: _date,
      );
      if (!mounted) return;
      HalaqaStudent? match;
      for (final s in students) {
        if (s.id == widget.studentId) {
          match = s;
          break;
        }
      }
      setState(() {
        _student = match;
        _serverStatus = match?.attendanceStatus;
        _selected = _parseNestStatus(match?.attendanceStatus) ??
            NestAttendanceStatus.present;
        _loading = false;
        _error = match == null ? 'الطالب غير موجود في هذه الحلقة' : null;
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
    setState(() => _date = ymd);
    await _reloadForDate();
  }

  Future<void> _pickDate() async {
    if (!_hasHalaqaContext) return;
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

  Future<void> _save() async {
    if (!_hasHalaqaContext) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('افتح من الحلقة')),
      );
      return;
    }
    final selected = _selected;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر حالة الحضور')),
      );
      return;
    }
    setState(() => _saving = true);
    final repo = ref.read(homeRepositoryProvider);
    try {
      await repo.saveStudentAttendance(
        halaqaId: widget.halaqaId!.trim(),
        date: _date,
        studentUserId: widget.studentId,
        status: selected.apiValue,
        previousStatus: _serverStatus,
      );
      if (!mounted) return;
      setState(() {
        _serverStatus = selected.apiValue;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ ${selected.labelAr}')),
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

  @override
  Widget build(BuildContext context) {
    final canSave = _hasHalaqaContext &&
        !_loading &&
        _student != null &&
        _selected != null &&
        !_saving;

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
                  onBack: () => context.pop(),
                ),
                const SizedBox(height: 8),
                _ContextRow(
                  date: _date,
                  onPickDate: _hasHalaqaContext ? _pickDate : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  _ErrorBanner(
                    message: _error!,
                    onRetry: _hasHalaqaContext ? () => _load() : null,
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
                          onRefresh: _hasHalaqaContext
                              ? () => _load(fromRefresh: true)
                              : () async {},
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              if (_student != null)
                                _StudentCard(
                                  student: _student!,
                                  selected: _selected,
                                  onSelect: (s) =>
                                      setState(() => _selected = s),
                                  onOpenHub: () {
                                    final hid = widget.halaqaId?.trim();
                                    final qs = <String>[
                                      'date=$_date',
                                      if (hid != null && hid.isNotEmpty)
                                        'halaqaId=$hid',
                                    ].join('&');
                                    context.push(
                                      '/student/${widget.studentId}/progress?$qs',
                                    );
                                  },
                                )
                              else if (_error == null)
                                const Padding(
                                  padding: EdgeInsets.only(top: 48),
                                  child: Text(
                                    'لا توجد بيانات',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
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
                        : const Text('تعديل'),
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
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onBack,
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
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

class _ContextRow extends StatelessWidget {
  const _ContextRow({required this.date, this.onPickDate});

  final String date;
  final VoidCallback? onPickDate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'الطلاب',
          style: TextStyle(
            color: AppColors.brand,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const Spacer(),
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
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.selected,
    required this.onSelect,
    required this.onOpenHub,
  });

  final HalaqaStudent student;
  final NestAttendanceStatus? selected;
  final ValueChanged<NestAttendanceStatus> onSelect;
  final VoidCallback onOpenHub;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
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
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: NestAttendanceStatus.values
                            .map(
                              (s) => _AttChip(
                                label: s.labelAr,
                                selected: selected == s,
                                onTap: () => onSelect(s),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 1,
                        color: AppColors.border,
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
                      color: AppColors.brand,
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
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _unselectedBg = Color(0xFFF7F4EE);
  static const _unselectedBorder = Color(0xFFD9D3C7);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.presentSoft : _unselectedBg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.brand : _unselectedBorder,
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
  const _ErrorBanner({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

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
          if (onRetry != null)
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