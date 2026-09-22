import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/data/dto/progress_models.dart';
import '../../home/data/home_repository.dart';
import 'plans_chrome.dart';

/// Shown when a draft would save two items of the same type.
const kDuplicatePlanItemTypeError =
    'لا يمكن إضافة أكثر من عنصر واحد من نفس النوع';

/// First type not already in [used], or null when HIFZ, TATHBEET, and MURAJAA are taken.
PlanItemType? nextUnusedPlanItemType(Iterable<PlanItemType> used) {
  final taken = used.toSet();
  for (final type in PlanItemType.values) {
    if (!taken.contains(type)) return type;
  }
  return null;
}

/// Non-null when [types] repeats a type. One plan: at most one of each type.
String? duplicatePlanItemTypeError(Iterable<PlanItemType> types) {
  final list = types.toList();
  if (list.length != list.toSet().length) return kDuplicatePlanItemTypeError;
  return null;
}

class _DraftItem {
  PlanItemType type = PlanItemType.hifz;
  int fromSurah = 1;
  final fromAyah = TextEditingController(text: '1');
  String amountType = 'LINE'; // LINE | PAGE
  final amountValue = TextEditingController(text: '5');

  void dispose() {
    fromAyah.dispose();
    amountValue.dispose();
  }

  Map<String, dynamic>? toApiBody() {
    final ayah = int.tryParse(fromAyah.text.trim());
    final amount = num.tryParse(amountValue.text.trim());
    if (ayah == null || ayah < 1) return null;
    if (amount == null || amount <= 0) return null;
    // Nest locked: type · direction · from* · amount* only — omit to*.
    return {
      'type': type.apiValue,
      'direction': 'NORMAL',
      'fromSurah': fromSurah,
      'fromAyah': ayah,
      'amountType': amountType,
      'amountValue': amount,
    };
  }
}

/// Create plan form — locked `halaqa-plans-create.html` (from-only, no إلى).
class HalaqaPlansCreatePage extends ConsumerStatefulWidget {
  const HalaqaPlansCreatePage({
    super.key,
    required this.halaqaId,
    this.halaqaName,
    this.studentCount = 0,
    this.initialItemTypes,
  });

  final String halaqaId;
  final String? halaqaName;
  final int studentCount;

  /// Seed draft types. Null = one HIFZ row. Tests pass duplicates to prove save blocks.
  final List<PlanItemType>? initialItemTypes;

  @override
  ConsumerState<HalaqaPlansCreatePage> createState() =>
      _HalaqaPlansCreatePageState();
}

class _HalaqaPlansCreatePageState extends ConsumerState<HalaqaPlansCreatePage> {
  final _nameCtrl = TextEditingController();
  final _items = <_DraftItem>[];
  List<QuranSurah> _surahs = const [];
  bool _loadingSurahs = true;
  bool _saving = false;
  String? _error;

  String get _halaqaName =>
      widget.halaqaName?.trim().isNotEmpty == true
          ? widget.halaqaName!.trim()
          : 'الحلقة';

  @override
  void initState() {
    super.initState();
    final seed = widget.initialItemTypes;
    if (seed == null || seed.isEmpty) {
      _items.add(_DraftItem());
    } else {
      for (final type in seed) {
        _items.add(_DraftItem()..type = type);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSurahs());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    try {
      final list = await ref.read(homeRepositoryProvider).getQuranSurahs();
      if (!mounted) return;
      setState(() {
        _surahs = list.isNotEmpty
            ? list
            : List.generate(
                114,
                (i) => QuranSurah(number: i + 1, name: 'سورة ${i + 1}'),
              );
        _loadingSurahs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _surahs = List.generate(
          114,
          (i) => QuranSurah(number: i + 1, name: 'سورة ${i + 1}'),
        );
        _loadingSurahs = false;
      });
    }
  }

  void _addItem() {
    final next = nextUnusedPlanItemType(_items.map((item) => item.type));
    if (next == null) return;
    setState(() => _items.add(_DraftItem()..type = next));
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items.removeAt(index).dispose();
    });
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'أدخل اسم الخطة');
      return;
    }
    final halaqaId = int.tryParse(widget.halaqaId);
    if (halaqaId == null) {
      setState(() => _error = 'معرّف الحلقة غير صالح');
      return;
    }
    final typeError = duplicatePlanItemTypeError(
      _items.map((item) => item.type),
    );
    if (typeError != null) {
      setState(() => _error = typeError);
      return;
    }
    final bodies = <Map<String, dynamic>>[];
    for (var i = 0; i < _items.length; i++) {
      final body = _items[i].toApiBody();
      if (body == null) {
        setState(() => _error = 'تحقق من حقول العنصر ${i + 1}');
        return;
      }
      bodies.add(body);
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(homeRepositoryProvider).createStudyPlan(
            name: name,
            halaqaId: halaqaId,
            studyPlanItems: bodies,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الخطة')),
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
    final canAddItem =
        nextUnusedPlanItemType(_items.map((item) => item.type)) != null;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.parchment,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: PlansTopBar(
                  title: 'إضافة خطة',
                  onBack: () => context.pop(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: PlansHalaqaContext(
                  halaqaName: _halaqaName,
                  studentCount: widget.studentCount,
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
              Expanded(
                child: _loadingSurahs
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        children: [
                          const Text(
                            'اسم الخطة',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: AppColors.brand,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            key: const Key('plan-name-field'),
                            controller: _nameCtrl,
                            decoration: _inputDecoration(
                              hint: 'مثال: خطة الحفظ الأسبوعية',
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'عناصر الخطة',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.brand,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (var i = 0; i < _items.length; i++) ...[
                            _ItemBlock(
                              index: i,
                              item: _items[i],
                              surahs: _surahs,
                              canRemove: _items.length > 1,
                              takenByOthers: {
                                for (var j = 0; j < _items.length; j++)
                                  if (j != i) _items[j].type,
                              },
                              onChanged: () => setState(() {}),
                              onRemove: () => _removeItem(i),
                            ),
                            const SizedBox(height: 12),
                          ],
                          OutlinedButton(
                            key: const Key('plan-add-item'),
                            onPressed: canAddItem ? _addItem : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.brand,
                              side: const BorderSide(
                                color: AppColors.borderStrong,
                              ),
                              minimumSize: const Size(double.infinity, 42),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: const Text('+ إضافة عنصر'),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'تعيين الطلاب بعد الحفظ من شاشة الخطة',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
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
                      key: const Key('plan-save-btn'),
                      label: 'حفظ الخطة',
                      busy: _saving,
                      onPressed: _save,
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

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
      ),
    );
  }
}

class _ItemBlock extends StatelessWidget {
  const _ItemBlock({
    required this.index,
    required this.item,
    required this.surahs,
    required this.canRemove,
    required this.takenByOthers,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final _DraftItem item;
  final List<QuranSurah> surahs;
  final bool canRemove;
  final Set<PlanItemType> takenByOthers;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
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
                padding: const EdgeInsets.fromLTRB(10, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'عنصر ${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.brand,
                            ),
                          ),
                        ),
                        if (canRemove)
                          TextButton(
                            onPressed: onRemove,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFC62828),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: const Text('إزالة'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in PlanItemType.values)
                          _TypePill(
                            key: Key('plan-item-$index-type-${t.apiValue}'),
                            type: t,
                            selected: item.type == t,
                            enabled:
                                t == item.type || !takenByOthers.contains(t),
                            onTap: () {
                              if (takenByOthers.contains(t)) return;
                              item.type = t;
                              onChanged();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _Labeled(
                            label: 'من سورة',
                            child: DropdownButtonFormField<int>(
                              value: item.fromSurah,
                              isExpanded: true,
                              decoration: _fieldDecoration(),
                              items: [
                                for (final s in surahs)
                                  DropdownMenuItem(
                                    value: s.number,
                                    child: Text(
                                      s.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                item.fromSurah = v;
                                onChanged();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Labeled(
                            label: 'من آية',
                            child: TextField(
                              controller: item.fromAyah,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: _fieldDecoration(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _Labeled(
                            label: 'نوع المقدار',
                            child: DropdownButtonFormField<String>(
                              value: item.amountType,
                              decoration: _fieldDecoration(),
                              items: const [
                                DropdownMenuItem(
                                  value: 'LINE',
                                  child: Text('أسطر'),
                                ),
                                DropdownMenuItem(
                                  value: 'PAGE',
                                  child: Text('صفحات'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v == null) return;
                                item.amountType = v;
                                onChanged();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Labeled(
                            label: 'القيمة',
                            child: TextField(
                              controller: item.amountValue,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: _fieldDecoration(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.borderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final PlanItemType type;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (type) {
      PlanItemType.hifz => (AppColors.hifzSoft, AppColors.hifz),
      PlanItemType.tathbeet => (AppColors.tathbeetSoft, AppColors.tathbeet),
      PlanItemType.murajaa => (AppColors.murajaaSoft, AppColors.murajaa),
    };
    return Opacity(
      opacity: enabled ? 1 : 0.38,
      child: Material(
        color: selected ? bg : Colors.white,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected ? fg : AppColors.borderStrong,
                width: 1.5,
              ),
            ),
            child: Text(
              type.labelAr,
              style: TextStyle(
                color: selected ? fg : AppColors.textMuted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
