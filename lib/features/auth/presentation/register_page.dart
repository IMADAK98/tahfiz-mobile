import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../data/auth_repository.dart';
import '../data/dto/center_option.dart';
import '../data/dto/create_pending_teacher_request.dart';
import '../data/teacher_signup_options.dart';

const _fieldBorder = Color(0xFFC9C0B0);
const _pagerMuted = Color(0xFFC5BBA8);
const _errorRed = Color(0xFFB3261E);

/// Teacher signup wizard — locked Brand B (`teacher-signup-1..4`).
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _teacherName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _birthDate = TextEditingController();
  final _juz = TextEditingController();

  int _step = 0;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _submitting = false;

  String? _qualification;
  String? _tajweedLevel;
  int? _centerId;
  String? _nationality;

  bool _hasCertificate = false;
  bool _hasIjazahInHifz = false;
  bool _hasSanadInHifz = false;

  final Set<String> _ageGroups = {};
  final Set<String> _workPeriods = {};

  List<CenterOption> _centers = const [];
  Map<String, String> _fieldErrors = {};
  String? _banner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCenters());
  }

  @override
  void dispose() {
    _teacherName.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _address.dispose();
    _phone.dispose();
    _birthDate.dispose();
    _juz.dispose();
    super.dispose();
  }

  Future<void> _loadCenters() async {
    setState(() => _loading = true);
    try {
      final centers = await ref.read(authRepositoryProvider).listCenters();
      if (!mounted) return;
      setState(() => _centers = centers);
    } catch (e) {
      if (!mounted) return;
      setState(() => _banner = nestErrorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearField(String name) {
    if (!_fieldErrors.containsKey(name) && _banner == null) return;
    setState(() {
      _fieldErrors = Map.of(_fieldErrors)..remove(name);
      _banner = null;
    });
  }

  String? _err(String name) {
    final value = _fieldErrors[name];
    if (value == null || value.isEmpty) return null;
    return value;
  }

  bool _validateStep(int step) {
    final next = <String, String>{};

    if (step == 0) {
      if (_teacherName.text.trim().isEmpty) {
        next['teacherName'] = 'يرجى إدخال اسم المعلم';
      }
      if (_email.text.trim().isEmpty) {
        next['email'] = 'يرجى إدخال البريد الإلكتروني';
      }
      if (_password.text.isEmpty) {
        next['password'] = 'يرجى إدخال كلمة المرور';
      } else if (_password.text.length < 8) {
        next['password'] = 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
      }
      if (_passwordConfirm.text != _password.text) {
        next['passwordConfirm'] = 'كلمتا المرور غير متطابقتين';
      }
    } else if (step == 1) {
      if (_qualification == null) next['qualification'] = 'يرجى اختيار المؤهل';
      if (_tajweedLevel == null) {
        next['tajweedLevel'] = 'يرجى اختيار مستوى التجويد';
      }
      if (_centerId == null) next['centerId'] = 'يرجى اختيار مركز العمل';
    } else if (step == 2) {
      if (_nationality == null || _nationality!.isEmpty) {
        next['nationality'] = 'يرجى اختيار الجنسية';
      }
      if (_address.text.trim().isEmpty) next['address'] = 'يرجى إدخال العنوان';
      if (_phone.text.trim().isEmpty) next['phone'] = 'يرجى إدخال رقم الهاتف';
      if (_birthDate.text.trim().isEmpty) {
        next['birthDate'] = 'يرجى إدخال تاريخ الميلاد';
      }
      final juz = int.tryParse(_juz.text.trim());
      if (juz == null || juz < 1 || juz > 30) {
        next['numberOfMemorizedJuz'] = 'عدد الأجزاء يجب أن يكون بين 1 و 30';
      }
    } else if (step == 3) {
      if (_ageGroups.isEmpty) {
        next['teachingAgeGroup'] = 'يرجى اختيار فئة عمرية واحدة على الأقل';
      }
      if (_workPeriods.isEmpty) {
        next['availableWorkPeriod'] =
            'يرجى اختيار فترة عمل واحدة على الأقل';
      }
    }

    setState(() {
      _fieldErrors = next;
      _banner = null;
    });
    return next.isEmpty;
  }

  void _goNext() {
    if (!_validateStep(_step)) return;
    if (_step < 3) setState(() => _step += 1);
  }

  void _goBack() {
    if (_step == 0) {
      context.go('/login');
      return;
    }
    setState(() => _step -= 1);
  }

  CreatePendingTeacherRequestDto _toDto() {
    return CreatePendingTeacherRequestDto(
      teacherName: _teacherName.text.trim(),
      email: _email.text.trim(),
      password: _password.text,
      nationality: _nationality ?? '',
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      birthDate: _birthDate.text.trim(),
      qualification: _qualification ?? '',
      hasCertificate: _hasCertificate,
      numberOfMemorizedJuz: int.parse(_juz.text.trim()),
      hasIjazahInHifz: _hasIjazahInHifz,
      hasSanadInHifz: _hasSanadInHifz,
      tajweedLevel: _tajweedLevel ?? '',
      teachingAgeGroup: _ageGroups.toList(),
      availableWorkPeriod: _workPeriods.toList(),
      centerId: _centerId ?? 0,
    );
  }

  Future<void> _submit() async {
    if (!_validateStep(3)) return;
    setState(() {
      _submitting = true;
      _banner = null;
    });
    try {
      await ref.read(authRepositoryProvider).submitPendingTeacherRequest(
            _toDto(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إرسال طلب التسجيل بنجاح. سيتم مراجعته.',
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: AppColors.brand,
        ),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      final fields = nestFieldErrors(e);
      setState(() {
        _fieldErrors = fields;
        _banner = fields.isEmpty ? nestErrorMessage(e) : null;
        if (fields.isNotEmpty) {
          _step = firstSignupStepForFields(fields);
        }
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  double get _brandSize {
    if (_step == 0) return 56;
    if (_step == 3) return 40;
    return 44;
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.textMuted;
    final brandSize = _brandSize;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.parchment,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              children: [
                _SignupHeader(
                  showBack: _step > 0,
                  onBack: _submitting ? null : _goBack,
                ),
                SizedBox(height: _step == 0 ? 2 : 0),
                _SignupBrand(size: brandSize),
                if (_banner != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _banner!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _errorRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _step == 0
                        ? _buildStepAccount(muted)
                        : _step == 1
                            ? _buildStepCredentials(muted)
                            : _step == 2
                                ? _buildStepPersonal(muted)
                                : _buildStepAvailability(),
                  ),
                ),
                const SizedBox(height: 8),
                _SignupPager(step: _step),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: _step == 3 ? 'تسجيل' : 'التالي',
                  isLoading: _submitting,
                  onPressed: _submitting
                      ? null
                      : (_step == 3 ? _submit : _goNext),
                ),
                const SizedBox(height: 10),
                _LoginLink(
                  onTap: _submitting ? null : () => context.go('/login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepAccount(Color muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          label: 'اسم المعلم',
          error: _err('teacherName'),
          child: TextField(
            controller: _teacherName,
            textInputAction: TextInputAction.next,
            enabled: !_submitting,
            decoration: _input(),
            onChanged: (_) => _clearField('teacherName'),
          ),
        ),
        _Field(
          label: 'البريد الإلكتروني',
          error: _err('email'),
          child: TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_submitting,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            decoration: _input(),
            onChanged: (_) => _clearField('email'),
          ),
        ),
        _Field(
          label: 'كلمة المرور',
          error: _err('password'),
          child: TextField(
            controller: _password,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            enabled: !_submitting,
            decoration: _input(
              suffix: _EyeButton(
                obscured: _obscurePassword,
                tooltip: 'إظهار كلمة المرور',
                onPressed: _submitting
                    ? null
                    : () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
              ),
            ),
            onChanged: (_) => _clearField('password'),
          ),
        ),
        _Field(
          label: 'كلمة المرور',
          error: _err('passwordConfirm'),
          child: Semantics(
            label: 'تأكيد كلمة المرور',
            child: TextField(
              controller: _passwordConfirm,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              enabled: !_submitting,
              decoration: _input(
                suffix: _EyeButton(
                  obscured: _obscureConfirm,
                  tooltip: 'إظهار تأكيد كلمة المرور',
                  onPressed: _submitting
                      ? null
                      : () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                ),
              ),
              onChanged: (_) => _clearField('passwordConfirm'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCredentials(Color muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          label: 'المؤهل',
          error: _err('qualification'),
          child: DropdownButtonFormField<String>(
            key: const Key('qualification'),
            initialValue: _qualification,
            isExpanded: true,
            isDense: true,
            decoration: _input(),
            icon: Icon(Icons.keyboard_arrow_down, color: muted),
            items: [
              for (final o in qualificationOptions)
                DropdownMenuItem(value: o.value, child: Text(o.label)),
            ],
            onChanged: _submitting
                ? null
                : (v) {
                    setState(() => _qualification = v);
                    _clearField('qualification');
                  },
          ),
        ),
        _Field(
          label: 'مستوى التجويد',
          error: _err('tajweedLevel'),
          child: DropdownButtonFormField<String>(
            key: const Key('tajweedLevel'),
            initialValue: _tajweedLevel,
            isExpanded: true,
            isDense: true,
            decoration: _input(),
            icon: Icon(Icons.keyboard_arrow_down, color: muted),
            items: [
              for (final o in tajweedLevelOptions)
                DropdownMenuItem(value: o.value, child: Text(o.label)),
            ],
            onChanged: _submitting
                ? null
                : (v) {
                    setState(() => _tajweedLevel = v);
                    _clearField('tajweedLevel');
                  },
          ),
        ),
        _Field(
          label: 'مركز العمل',
          error: _err('centerId'),
          child: DropdownButtonFormField<int>(
            key: const Key('centerId'),
            initialValue: _centerId,
            isExpanded: true,
            isDense: true,
            decoration: _input(),
            icon: Icon(Icons.keyboard_arrow_down, color: muted),
            items: [
              for (final c in _centers)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: _submitting || _loading
                ? null
                : (v) {
                    setState(() => _centerId = v);
                    _clearField('centerId');
                  },
          ),
        ),
        _CheckRow(
          label: 'هل لديك شهادة خاتم للقرآن الكريم من جمعية مكنون أو غيرها؟',
          value: _hasCertificate,
          error: _err('hasCertificate'),
          onChanged: _submitting
              ? null
              : (v) {
                  setState(() => _hasCertificate = v);
                  _clearField('hasCertificate');
                },
        ),
        _CheckRow(
          label: 'لديه إجازة في الحفظ؟',
          value: _hasIjazahInHifz,
          error: _err('hasIjazahInHifz'),
          onChanged: _submitting
              ? null
              : (v) {
                  setState(() => _hasIjazahInHifz = v);
                  _clearField('hasIjazahInHifz');
                },
        ),
        _CheckRow(
          label: 'لديه سند في الحفظ؟',
          value: _hasSanadInHifz,
          error: _err('hasSanadInHifz'),
          onChanged: _submitting
              ? null
              : (v) {
                  setState(() => _hasSanadInHifz = v);
                  _clearField('hasSanadInHifz');
                },
        ),
      ],
    );
  }

  Widget _buildStepPersonal(Color muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Field(
          label: 'الجنسية',
          error: _err('nationality'),
          child: DropdownButtonFormField<String>(
            key: const Key('nationality'),
            initialValue: _nationality,
            isExpanded: true,
            isDense: true,
            decoration: _input(),
            icon: Icon(Icons.keyboard_arrow_down, color: muted),
            items: [
              for (final n in nationalityOptions)
                DropdownMenuItem(value: n, child: Text(n)),
            ],
            onChanged: _submitting
                ? null
                : (v) {
                    setState(() => _nationality = v);
                    _clearField('nationality');
                  },
          ),
        ),
        _Field(
          label: 'العنوان',
          error: _err('address'),
          child: TextField(
            controller: _address,
            textInputAction: TextInputAction.next,
            enabled: !_submitting,
            decoration: _input(),
            onChanged: (_) => _clearField('address'),
          ),
        ),
        _Field(
          label: 'رقم الهاتف',
          error: _err('phone'),
          child: TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            enabled: !_submitting,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.right,
            decoration: _input(),
            onChanged: (_) => _clearField('phone'),
          ),
        ),
        _Field(
          label: 'تاريخ الميلاد',
          error: _err('birthDate'),
          child: TextField(
            controller: _birthDate,
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.next,
            enabled: !_submitting,
            decoration: _input(),
            onChanged: (_) => _clearField('birthDate'),
          ),
        ),
        _Field(
          label: 'عدد الأجزاء المحفوظة',
          error: _err('numberOfMemorizedJuz'),
          child: TextField(
            controller: _juz,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            enabled: !_submitting,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _input(),
            onChanged: (_) => _clearField('numberOfMemorizedJuz'),
          ),
        ),
      ],
    );
  }

  Widget _buildStepAvailability() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final o in teachingAgeGroupOptions)
          _CheckRow(
            label: o.label,
            value: _ageGroups.contains(o.value),
            onChanged: _submitting
                ? null
                : (v) {
                    setState(() {
                      if (v) {
                        _ageGroups.add(o.value);
                      } else {
                        _ageGroups.remove(o.value);
                      }
                    });
                    _clearField('teachingAgeGroup');
                  },
          ),
        if (_err('teachingAgeGroup') != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _err('teachingAgeGroup')!,
              style: const TextStyle(color: _errorRed, fontSize: 12),
            ),
          ),
        const _SectionBar(title: 'فترة العمل المتاحة'),
        for (final o in availableWorkPeriodOptions)
          _CheckRow(
            label: o.label,
            value: _workPeriods.contains(o.value),
            onChanged: _submitting
                ? null
                : (v) {
                    setState(() {
                      if (v) {
                        _workPeriods.add(o.value);
                      } else {
                        _workPeriods.remove(o.value);
                      }
                    });
                    _clearField('availableWorkPeriod');
                  },
          ),
        if (_err('availableWorkPeriod') != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _err('availableWorkPeriod')!,
              style: const TextStyle(color: _errorRed, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

InputDecoration _input({Widget? suffix}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: _fieldBorder, width: 1.5),
  );
  return InputDecoration(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
    ),
    suffixIcon: suffix,
  );
}

class _SignupHeader extends StatelessWidget {
  const _SignupHeader({required this.showBack, required this.onBack});

  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          if (showBack)
            IconButton(
              tooltip: 'رجوع',
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_forward,
                color: AppColors.textPrimary,
                textDirection: TextDirection.ltr,
              ),
            )
          else
            const SizedBox(width: 40),
          Expanded(
            child: Text(
              'تسجيل المعلم',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                    fontSize: 18.4,
                  ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _SignupBrand extends StatelessWidget {
  const _SignupBrand({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final nameSize = size >= 56 ? 15.2 : (size >= 44 ? 14.0 : 13.0);
    return Padding(
      padding: EdgeInsets.only(bottom: size >= 56 ? 14 : 10),
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brand,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              'ت',
              style: TextStyle(
                color: AppColors.onBrand,
                fontSize: size * 0.46,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(height: size >= 56 ? 8 : 6),
          Text(
            'تحفيظ',
            style: TextStyle(
              color: AppColors.brand,
              fontWeight: FontWeight.w800,
              fontSize: nameSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.child,
    this.error,
  });

  final String label;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(height: 48, child: child),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              error!,
              style: const TextStyle(color: _errorRed, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _EyeButton extends StatelessWidget {
  const _EyeButton({
    required this.obscured,
    required this.tooltip,
    required this.onPressed,
  });

  final bool obscured;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.error,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onChanged == null ? null : () => onChanged!(!value),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: _LockCheck(value: value),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (error != null)
            Text(
              error!,
              style: const TextStyle(color: _errorRed, fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _LockCheck extends StatelessWidget {
  const _LockCheck({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: value ? AppColors.brand : Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: value ? AppColors.brand : _fieldBorder,
          width: 2,
        ),
      ),
      child: value
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
  }
}

class _SectionBar extends StatelessWidget {
  const _SectionBar({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.brand,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignupPager extends StatelessWidget {
  const _SignupPager({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'الخطوة ${step + 1} من 4',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        textDirection: TextDirection.rtl,
        children: [
          for (var i = 0; i < 4; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: i == step ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == step ? AppColors.brand : _pagerMuted,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoginLink extends StatelessWidget {
  const _LoginLink({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text.rich(
        TextSpan(
          text: 'هل لديك حساب؟ ',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          children: [
            TextSpan(
              text: 'تسجيل الدخول',
              style: TextStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
