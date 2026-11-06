import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';

/// Locked Direction A — soft parchment float.
///
/// One toast at a time: a new show replaces the current one (no stack on the
/// save button). Direction B (accent rail) is not implemented.
enum ThafizToastKind { success, error, info }

class _ToastLifetime extends StatefulWidget {
  const _ToastLifetime({required this.duration, required this.child});

  final Duration duration;
  final Widget child;

  @override
  State<_ToastLifetime> createState() => _ToastLifetimeState();
}

class _ToastLifetimeState extends State<_ToastLifetime> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, () {
      if (mounted) ThafizToast.dismiss();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

abstract final class ThafizToast {
  static const surface = Color(0xFFFFFDF8);
  static const text = Color(0xFF15241C);
  static const border = Color(0xFFEAE5DB);
  static const radius = 18.0;
  static const horizontalInset = 16.0;

  /// Above the primary CTA. Home-indicator inset is added on top.
  static const bottomClearance = 72.0;

  static const successDuration = Duration(milliseconds: 2800);
  static const infoDuration = Duration(milliseconds: 2800);
  static const errorDuration = Duration(seconds: 4);

  static const successFg = Color(0xFF1B6B45);
  static const successBg = Color(0xFFDBE7E1);
  static const errorFg = Color(0xFFA65A4C);
  static const errorBg = Color(0xFFF4E7E4);
  static const infoFg = Color(0xFF2E6B5A);
  static const infoBg = Color(0xFFE2EAE8);

  static const shadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x1F15241C),
      offset: Offset(0, 8),
      blurRadius: 28,
    ),
    BoxShadow(
      color: Color(0x0F15241C),
      offset: Offset(0, 2),
      blurRadius: 6,
    ),
  ];

  static OverlayEntry? _entry;

  static Duration durationFor(ThafizToastKind kind) => switch (kind) {
        ThafizToastKind.success => successDuration,
        ThafizToastKind.info => infoDuration,
        ThafizToastKind.error => errorDuration,
      };

  static Color iconColor(ThafizToastKind kind) => switch (kind) {
        ThafizToastKind.success => successFg,
        ThafizToastKind.error => errorFg,
        ThafizToastKind.info => infoFg,
      };

  static Color iconBackground(ThafizToastKind kind) => switch (kind) {
        ThafizToastKind.success => successBg,
        ThafizToastKind.error => errorBg,
        ThafizToastKind.info => infoBg,
      };

  static IconData iconFor(ThafizToastKind kind) => switch (kind) {
        ThafizToastKind.success => Icons.check,
        ThafizToastKind.error => Icons.error_outline,
        ThafizToastKind.info => Icons.info_outline,
      };

  static SemanticsRole roleFor(ThafizToastKind kind) => switch (kind) {
        ThafizToastKind.error => SemanticsRole.alert,
        ThafizToastKind.success || ThafizToastKind.info => SemanticsRole.status,
      };

  /// Shows [message]. Replaces any toast already on screen.
  static void show(
    BuildContext context, {
    required String message,
    required ThafizToastKind kind,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    dismiss();
    final entry = OverlayEntry(
      builder: (overlayContext) {
        final media = MediaQuery.of(overlayContext);
        final obstacle = math.max(
          media.viewPadding.bottom,
          media.viewInsets.bottom,
        );
        return Positioned(
          left: horizontalInset,
          right: horizontalInset,
          bottom: bottomClearance + obstacle,
          child: _ToastLifetime(
            duration: durationFor(kind),
            child: ThafizToastCard(
              message: message,
              kind: kind,
              onDismiss: dismiss,
            ),
          ),
        );
      },
    );
    _entry = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    final current = _entry;
    _entry = null;
    if (current != null && current.mounted) {
      current.remove();
    }
  }
}

class ThafizToastCard extends StatelessWidget {
  const ThafizToastCard({
    super.key,
    required this.message,
    required this.kind,
    required this.onDismiss,
  });

  final String message;
  final ThafizToastKind kind;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final font = Theme.of(context).textTheme.bodyMedium;
    return Semantics(
      container: true,
      excludeSemantics: true,
      role: ThafizToast.roleFor(kind),
      label: message,
      textDirection: TextDirection.rtl,
      onDismiss: onDismiss,
      child: GestureDetector(
        onTap: onDismiss,
        behavior: HitTestBehavior.opaque,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: ThafizToast.surface,
              borderRadius: BorderRadius.all(Radius.circular(ThafizToast.radius)),
              border: Border.fromBorderSide(BorderSide(color: ThafizToast.border)),
              boxShadow: ThafizToast.shadow,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: ThafizToast.iconBackground(kind),
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        ThafizToast.iconFor(kind),
                        size: 20,
                        color: ThafizToast.iconColor(kind),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      textAlign: TextAlign.start,
                      style: font?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.45,
                        color: ThafizToast.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
