import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/localization/changelocal.dart';

Future<void> showLanguageSelectorSheet() async {
  final localeController = Get.isRegistered<LocaleController>()
      ? Get.find<LocaleController>()
      : Get.put(LocaleController());

  await Get.bottomSheet<void>(
    _LanguageSelectorSheet(
      currentLanguageCode: localeController.language.languageCode,
      onSelected: (code) {
        if (localeController.language.languageCode != code) {
          localeController.changeLang(code);
        }
        Get.back<void>();
      },
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
  );
}

class _LanguageSelectorSheet extends StatelessWidget {
  const _LanguageSelectorSheet({
    required this.currentLanguageCode,
    required this.onSelected,
  });

  final String currentLanguageCode;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.12),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: colors.onSurface.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.language_rounded, color: colors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose language'.tr,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Select your preferred app language.'.tr,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.72),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _LanguageOptionTile(
              icon: Icons.translate_rounded,
              title: 'arabic'.tr,
              subtitle: 'use_arabic'.tr,
              selected: currentLanguageCode == 'ar',
              onTap: () => onSelected('ar'),
            ),
            const SizedBox(height: 12),
            _LanguageOptionTile(
              icon: Icons.language_rounded,
              title: 'english'.tr,
              subtitle: 'use_english'.tr,
              selected: currentLanguageCode == 'en',
              onTap: () => onSelected('en'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: selected
          ? colors.primary.withValues(alpha: 0.08)
          : theme.scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? colors.primary : theme.dividerColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.70),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? colors.primary : Colors.transparent,
                  border: Border.all(
                    color: selected ? colors.primary : colors.outlineVariant,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        color: colors.onPrimary,
                        size: 18,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
