import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.form,
    required this.hero,
    this.headerAction,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget form;
  final Widget hero;
  final Widget? headerAction;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final appTheme = Theme.of(context);
    final authTheme = appTheme.copyWith(
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.white,
      canvasColor: Colors.white,
      cardColor: Colors.white,
      colorScheme: appTheme.colorScheme.copyWith(
        brightness: Brightness.light,
        primary: const Color(0xFFFF6500),
        onPrimary: Colors.white,
        secondary: const Color(0xFFE34F00),
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: const Color(0xFF171717),
      ),
      textTheme: appTheme.textTheme.apply(
        bodyColor: const Color(0xFF344054),
        displayColor: const Color(0xFF243233),
      ),
      dividerTheme: appTheme.dividerTheme.copyWith(
        color: const Color(0xFFD1D8DE),
      ),
    );

    return Theme(
      data: authTheme,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: ColoredBox(
          color: Colors.white,
          child: Stack(
            children: [
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(width: 48),
                              headerAction ?? const SizedBox(width: 48),
                            ],
                          ),
                          Center(
                            child: SizedBox(
                              height: 88,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: hero,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title.tr,
                            textAlign: TextAlign.center,
                            style: authTheme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle.tr,
                            textAlign: TextAlign.center,
                            style: authTheme.textTheme.bodyMedium?.copyWith(
                              color: authTheme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.88),
                            ),
                          ),
                          const SizedBox(height: 8),
                          form,
                          if (footer != null) ...[
                            const SizedBox(height: 22),
                            footer!,
                          ],
                        ],
                      ),
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

class AuthSectionTitle extends StatelessWidget {
  const AuthSectionTitle({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        Text(text,
            style: TextStyle(
                color: primary, fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Container(
            width: 48,
            height: 3,
            decoration: BoxDecoration(
                color: primary, borderRadius: BorderRadius.circular(8))),
        const SizedBox(height: 14),
      ],
    );
  }
}

class AuthField extends StatelessWidget {
  const AuthField(
      {super.key,
      required this.controller,
      required this.hint,
      required this.icon,
      this.obscureText = false,
      this.onToggle,
      this.keyboardType,
      this.validator});
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final VoidCallback? onToggle;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldTextColor =
        isDark ? const Color(0xFFE5E7EB) : const Color(0xFF344054);
    final hintColor =
        isDark ? const Color(0xFFB8C0CC) : const Color(0xFF697586);
    final iconColor =
        isDark ? const Color(0xFFD1D5DB) : const Color(0xFF667085);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        textDirection: TextDirection.rtl,
        style: TextStyle(fontSize: 14, color: fieldTextColor),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: isDark ? const Color(0xFF1D2422) : Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          hintText: hint,
          hintStyle: TextStyle(fontSize: 14, color: hintColor),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(
                color:
                    isDark ? const Color(0xFF4B5563) : const Color(0xFFDCE1E8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFFF6500), width: 1.5),
          ),
          prefixIcon: Icon(icon, size: 20, color: iconColor),
          suffixIcon: onToggle == null
              ? null
              : IconButton(
                  onPressed: onToggle,
                  icon: Icon(
                    obscureText
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: iconColor,
                  ),
                ),
        ),
      ),
    );
  }
}
