// Study-plan item + daily-progress models for the teacher progress editor.

enum PlanItemType { hifz, tathbeet, murajaa }

extension PlanItemTypeX on PlanItemType {
  String get apiValue => switch (this) {
        PlanItemType.hifz => 'HIFZ',
        PlanItemType.tathbeet => 'TATHBEET',
        PlanItemType.murajaa => 'MURAJAA',
      };

  String get labelAr => switch (this) {
        PlanItemType.hifz => 'حفظ',
        PlanItemType.tathbeet => 'تثبيت',
        PlanItemType.murajaa => 'مراجعة',
      };

  /// Tab key matching the locked mock (`hifz` / `tath` / `mur`).
  String get tabKey => switch (this) {
        PlanItemType.hifz => 'hifz',
        PlanItemType.tathbeet => 'tath',
        PlanItemType.murajaa => 'mur',
      };

  static PlanItemType? tryParse(String? raw) {
    if (raw == null) return null;
    final s = raw.trim().toUpperCase();
    return switch (s) {
      'HIFZ' || 'MEMORIZATION' || 'HAIFZ' => PlanItemType.hifz,
      'TATHBEET' || 'RETENTION' || 'TATHBEET_PLAN' => PlanItemType.tathbeet,
      'MURAJAA' || 'REVISION' || 'REVIEW' => PlanItemType.murajaa,
      _ => null,
    };
  }
}

class QuranSurah {
  const QuranSurah({required this.number, required this.name});

  final int number;
  final String name;
}

class StudyPlanItemRef {
  const StudyPlanItemRef({
    required this.id,
    required this.type,
    this.fromSurah,
    this.fromAyah,
    this.toSurah,
    this.toAyah,
    this.fromSurahName,
    this.toSurahName,
    this.amountType,
    this.amountValue,
    this.direction,
  });

  final int id;
  final PlanItemType type;
  final int? fromSurah;
  final int? fromAyah;
  final int? toSurah;
  final int? toAyah;
  final String? fromSurahName;
  final String? toSurahName;
  final String? amountType;
  final num? amountValue;
  final String? direction;

  factory StudyPlanItemRef.fromJson(Map<String, dynamic> json) {
    final type = PlanItemTypeX.tryParse(
          (json['type'] ?? json['planType'] ?? json['itemType'])?.toString(),
        ) ??
        PlanItemType.hifz;

    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    num? asNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString());
    }

    final id = asInt(json['id'] ?? json['studyPlanItemId']) ?? 0;

    return StudyPlanItemRef(
      id: id,
      type: type,
      fromSurah: asInt(
        json['fromSurah'] ??
            json['fromSurahNumber'] ??
            json['from_surah'] ??
            json['fromSurahId'],
      ),
      fromAyah: asInt(json['fromAyah'] ?? json['from_ayah']),
      toSurah: asInt(
        json['toSurah'] ??
            json['toSurahNumber'] ??
            json['to_surah'] ??
            json['toSurahId'],
      ),
      toAyah: asInt(json['toAyah'] ?? json['to_ayah']),
      fromSurahName: (json['fromSurahName'] ?? json['from_surah_name'])
          ?.toString(),
      toSurahName:
          (json['toSurahName'] ?? json['to_surah_name'])?.toString(),
      amountType: (json['amountType'] ?? json['amount_type'] ?? json['unit'])
          ?.toString(),
      amountValue: asNum(
        json['amountValue'] ?? json['amount_value'] ?? json['amount'],
      ),
      direction: json['direction']?.toString(),
    );
  }

  /// Cross-surah: `من [سورة] آية X → إلى [سورة] آية Y`; same-surah compact.
  String formatPlanRange({String Function(int)? surahName}) {
    final fs = fromSurah;
    final fa = fromAyah;
    final ts = toSurah;
    final ta = toAyah;
    if (fs == null || fa == null || ts == null || ta == null) {
      return '—';
    }
    final fromName = fromSurahName?.trim().isNotEmpty == true
        ? fromSurahName!.trim()
        : (surahName?.call(fs) ?? 'سورة $fs');
    final toName = toSurahName?.trim().isNotEmpty == true
        ? toSurahName!.trim()
        : (surahName?.call(ts) ?? 'سورة $ts');

    if (fs == ts) {
      return '$fromName $fa–$ta';
    }
    return 'من $fromName آية $fa → إلى $toName آية $ta';
  }

  String formatAmountLabel() {
    final v = amountValue;
    if (v == null) return '—';
    final t = (amountType ?? '').toUpperCase();
    final asDouble = v.toDouble();
    final n = asDouble == asDouble.roundToDouble() ? asDouble.toInt() : v;
    if (t == 'LINE' || t == 'LINES') {
      return '$n أسطر';
    }
    if (t == 'PAGE' || t == 'PAGES') {
      if (asDouble == 1) return '1 صفحة';
      return '$n صفحات';
    }
    if (t == 'AYAH' || t == 'AYA' || t == 'AYAHS') {
      if (asDouble == 1) return '1 آية';
      return '$n آيات';
    }
    return '$n';
  }
}

class DailyProgressSnapshot {
  const DailyProgressSnapshot({
    this.id,
    this.isProgress = false,
    this.actualStartSurah,
    this.actualStartAyah,
    this.actualEndSurah,
    this.actualEndAyah,
    this.suggestedStartSurah,
    this.suggestedStartAyah,
    this.suggestedEndSurah,
    this.suggestedEndAyah,
    this.plannedAmountType,
    this.plannedAmountValue,
    this.murajaaRanges = const [],
  });

  final int? id;
  final bool isProgress;
  final int? actualStartSurah;
  final int? actualStartAyah;
  final int? actualEndSurah;
  final int? actualEndAyah;
  final int? suggestedStartSurah;
  final int? suggestedStartAyah;
  final int? suggestedEndSurah;
  final int? suggestedEndAyah;
  final String? plannedAmountType;
  final num? plannedAmountValue;

  /// Extra murajaa ranges when API returns a list of progress rows.
  final List<({int? endSurah, int? endAyah, int? startSurah, int? startAyah})>
      murajaaRanges;

  int? get preferredEndSurah => actualEndSurah ?? suggestedEndSurah;
  int? get preferredEndAyah => actualEndAyah ?? suggestedEndAyah;
  int? get preferredStartSurah =>
      actualStartSurah ?? suggestedStartSurah;
  int? get preferredStartAyah => actualStartAyah ?? suggestedStartAyah;

  bool get hasSavedProgress =>
      isProgress && id != null && id! > 0;

  factory DailyProgressSnapshot.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    num? asNum(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      return num.tryParse(v.toString());
    }

    final isProgress = json['isProgress'] == true ||
        json['is_progress'] == true ||
        (json['status'] != null &&
            json['status'].toString().toUpperCase() != 'SUGGESTION');

    return DailyProgressSnapshot(
      id: asInt(json['id']),
      isProgress: isProgress,
      actualStartSurah:
          asInt(json['actualStartSurah'] ?? json['actual_start_surah']),
      actualStartAyah:
          asInt(json['actualStartAyah'] ?? json['actual_start_ayah']),
      actualEndSurah:
          asInt(json['actualEndSurah'] ?? json['actual_end_surah']),
      actualEndAyah:
          asInt(json['actualEndAyah'] ?? json['actual_end_ayah']),
      suggestedStartSurah: asInt(
        json['suggestedStartSurah'] ?? json['suggested_start_surah'],
      ),
      suggestedStartAyah: asInt(
        json['suggestedStartAyah'] ?? json['suggested_start_ayah'],
      ),
      suggestedEndSurah: asInt(
        json['suggestedEndSurah'] ?? json['suggested_end_surah'],
      ),
      suggestedEndAyah: asInt(
        json['suggestedEndAyah'] ?? json['suggested_end_ayah'],
      ),
      plannedAmountType:
          (json['plannedAmountType'] ?? json['planned_amount_type'])
              ?.toString(),
      plannedAmountValue: asNum(
        json['plannedAmountValue'] ?? json['planned_amount_value'],
      ),
    );
  }
}
