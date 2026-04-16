import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

// ─── Shared form helpers untuk Login & Register pages ────────────────────────

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}

InputDecoration authInputDecoration(
  BuildContext context, {
  required String hint,
  required IconData icon,
  Widget? suffix,
}) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.35)),
    prefixIcon:
        Icon(icon, size: 20, color: cs.onSurface.withValues(alpha: 0.45)),
    suffixIcon: suffix,
    filled: true,
    fillColor: cs.surfaceContainerHigh,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide:
          BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5), width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.error, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: cs.error, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
