import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/util/school_calendar.dart';
import '../../home/data/home_repository.dart';
import '../data/dto/halaqa_student.dart';

/// Wired ḥalaqa detail: Nest roster + locked mock UI (halaqa-detail.html).
class HalaqaDetailPage extends ConsumerStatefulWidget {
  const HalaqaDetailPage({super.key, required this.halaqaId});

  final String halaqaId;

  @override
  ConsumerState<HalaqaDetailPage> createState() => _HalaqaDetailPageState();
}

class _HalaqaDetailPageState extends ConsumerState<HalaqaDetailPage> {
  bool _loading = true;
  String? _error;
  List<HalaqaStudent> _students = const [];
  String _title = 'المعلم';
  late String _date; // YYYY-MM-DD
  Set<String> _holidays = const {};

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
      if (!fromRefresh || !SchoolCalendar.isSchoolDay(
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
        _students = students;
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
    setState(() => _date = ymd);
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
                  count: _students.length,
                  date: _date,
                  onPrev: _goPreviousSchoolDay,
                  onNext: _goNextSchoolDay,
                  onPickDate: _pickDate,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  _ErrorBanner(
                    message: _error!,
                    onRetry: () => _load(),
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
                          child: _students.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
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
                                )
                              : ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: _students.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, i) {
                                    final s = _students[i];
                                    return _StudentCard(
                                      student: s,
                                      onTap: () =>
                                          context.push(
                                        '/student/${s.id}/attendance?date=$_date&halaqaId=${widget.halaqaId}',
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('قريباً'),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    child: const Text('تعديل'),
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

class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.count,
    required this.date,
    required this.onPrev,
    required this.onNext,
    required this.onPickDate,
  });

  final int count;
  final String date;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPickDate;

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
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: AppColors.brand,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
        const Spacer(),
        // Prev (earlier) — first in RTL row sits on the visual right.
        _DateChevron(
          icon: Icons.chevron_right,
          onTap: onPrev,
          tooltip: 'اليوم السابق',
        ),
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

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student, required this.onTap});

  final HalaqaStudent student;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
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
                // Green accent on the visual right (start in RTL).
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
                            if (student.isPresent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.presentSoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'حاضر',
                                  style: TextStyle(
                                    color: AppColors.brand,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.chevron_left,
                    color: AppColors.textMuted,
                    size: 22,
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
