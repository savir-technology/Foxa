import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/data/datasource/remote/content/cookie_consent_data.dart';

class FirstLaunchCookiePolicyDialog extends StatefulWidget {
  const FirstLaunchCookiePolicyDialog({
    super.key,
    required this.isArabic,
    required this.onFinish,
  });

  final bool isArabic;
  final VoidCallback onFinish;

  @override
  State<FirstLaunchCookiePolicyDialog> createState() =>
      _FirstLaunchCookiePolicyDialogState();
}

class _FirstLaunchCookiePolicyDialogState
    extends State<FirstLaunchCookiePolicyDialog> {
  static const String _cookieConsentModeKey = MyServices.keyCookieConsentMode;
  static const String _cookieConsentUpdatedAtKey =
      MyServices.keyCookieConsentUpdatedAt;
  static const String _cookieConsentNecessaryKey =
      MyServices.keyCookieConsentNecessary;

  late final MyServices _services;
  late _CookieConsentDialogContent _content;
  bool _isSaving = false;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _services = Get.find<MyServices>();
    _content = _CookieConsentDialogContent.fallback(widget.isArabic);
    _loadRemoteContent();
  }

  String _t(String arabic, String english) =>
      widget.isArabic ? arabic : english;

  Future<void> _loadRemoteContent() async {
    try {
      final installationId =
          await _services.ensureCookieConsentInstallationId();
      final remote = await const CookieConsentData().fetchProfile(
        installationKey: installationId,
      );
      if (!mounted || remote == null || _hasInteracted) {
        return;
      }

      setState(() {
        _content = _CookieConsentDialogContent.fromProfile(
          widget.isArabic,
          remote,
        );
      });
    } catch (_) {
      // Keep the local fallback content if the network is unavailable.
    }
  }

  List<_ConsentOption> get _options => _content.options;

  Map<String, bool> _currentSelection() {
    final selection = <String, bool>{
      _cookieConsentNecessaryKey: true,
    };

    for (final option in _options) {
      final enabled = option.locked ? true : option.enabled;
      for (final key in option.preferenceKeys) {
        selection[key] = enabled;
      }
    }

    return selection;
  }

  void _setOptionalSelection(bool enabled) {
    _hasInteracted = true;
    for (final option in _options.where((item) => !item.locked)) {
      option.enabled = enabled;
    }
  }

  Future<void> _persistConsent({
    required String mode,
    required Map<String, bool> values,
  }) async {
    final prefs = _services.sharedPreferences;
    await prefs.setString(_cookieConsentModeKey, mode);
    await prefs.setBool(_cookieConsentNecessaryKey, true);

    for (final entry in values.entries) {
      await prefs.setBool(entry.key, entry.value);
    }

    await prefs.setString(
      _cookieConsentUpdatedAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
    await prefs.setBool(MyServices.keyCookieConsentBackendSynced, false);

    final record = await const CookieConsentData().saveConsent(
      services: _services,
      profileKey: _content.profileKey,
      consentMode: mode,
      preferences: values,
      localeCode: widget.isArabic ? 'ar' : 'en',
      shouldMarkSynced: true,
    );

    if (record == null) {
      await prefs.setBool(MyServices.keyCookieConsentBackendSynced, false);
    }
  }

  Future<void> _finishWithPersist(Future<void> Function() persist) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      await persist();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      Get.snackbar(
        _t('تعذر الحفظ', 'Unable to save'),
        _t(
          'تعذر حفظ تفضيلات الموافقة، حاول مرة أخرى.',
          'We could not save the consent preferences. Please try again.',
        ),
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    widget.onFinish();
  }

  Future<void> _acceptAll() async {
    _hasInteracted = true;
    _setOptionalSelection(true);
    await _finishWithPersist(() => _persistConsent(
          mode: 'accepted_all',
          values: _currentSelection(),
        ));
  }

  Future<void> _rejectOptional() async {
    _hasInteracted = true;
    _setOptionalSelection(false);
    await _finishWithPersist(() => _persistConsent(
          mode: 'rejected_optional',
          values: _currentSelection(),
        ));
  }

  Future<void> _savePreferences() async {
    _hasInteracted = true;
    await _finishWithPersist(() => _persistConsent(
          mode: 'custom',
          values: _currentSelection(),
        ));
  }

  void _openCookiePolicyPage() {
    Get.toNamed(AppRoutes.consentManagementPolicy);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = _content;
    const green = Color(0xFFFF6500);
    const titleColor = Color(0xFF111827);
    const bodyColor = Color(0xFF64748B);
    const borderColor = Color(0xFFE5E7EB);

    final shellBorder = borderColor.withValues(alpha: 0.92);

    final screenHeight = MediaQuery.sizeOf(context).height;
    final dialogMaxHeight =
        (screenHeight * 0.90).clamp(540.0, 780.0).toDouble();

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        backgroundColor: Colors.transparent,
        child: Directionality(
          textDirection:
              widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: 560, maxHeight: dialogMaxHeight),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: shellBorder),
                gradient: const LinearGradient(
                  colors: [Colors.white, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -22,
                    right: widget.isArabic ? null : -18,
                    left: widget.isArabic ? -18 : null,
                    child: _DecorBlob(
                      size: 140,
                      color: content.accentColor.withValues(
                        alpha: 0.07,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -24,
                    left: widget.isArabic ? null : -18,
                    right: widget.isArabic ? -18 : null,
                    child: _DecorBlob(
                      size: 112,
                      color: green.withValues(alpha: 0.05),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  color: content.accentColor.withValues(
                                    alpha: 0.10,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: content.accentColor.withValues(
                                        alpha: 0.10,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.cookie_outlined,
                                  size: 40,
                                  color: content.accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Center(
                              child: Text(
                                content.title,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: titleColor,
                                  fontWeight: FontWeight.w900,
                                  height: 1.12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                content.subtitle,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: bodyColor,
                                  height: 1.52,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: Text(
                                content.body,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: bodyColor.withValues(alpha: 0.92),
                                  height: 1.58,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _MiniTag(
                                  label: content.versionLabel,
                                  accentColor: content.accentColor,
                                ),
                                _MiniTag(
                                  label: _t('صارمة', 'Strict'),
                                  accentColor: const Color(0xFFFF6500),
                                ),
                                _MiniTag(
                                  label:
                                      _t('يمكن تعديلها لاحقًا', 'Change later'),
                                  accentColor: green,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ..._options.asMap().entries.map(
                                  (entry) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: entry.key == _options.length - 1
                                          ? 0
                                          : 10,
                                    ),
                                    child: _ConsentOptionCard(
                                      option: entry.value,
                                      isArabic: widget.isArabic,
                                      onChanged: (value) {
                                        setState(() {
                                          _hasInteracted = true;
                                          entry.value.enabled = value;
                                        });
                                      },
                                    ),
                                  ),
                                ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _isSaving ? null : _acceptAll,
                                style: FilledButton.styleFrom(
                                  backgroundColor: green,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Text(
                                  content.acceptAllLabel,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed:
                                    _isSaving ? null : _openCookiePolicyPage,
                                icon: const Icon(Icons.open_in_new_rounded),
                                label: Text(
                                  _t(
                                    'عرض صفحة الكوكيز الأساسية',
                                    'Open full cookie policy',
                                  ),
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: green,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: green,
                                  side: BorderSide(
                                    color: green.withValues(alpha: 0.35),
                                  ),
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: _isSaving ? null : _savePreferences,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  foregroundColor: green,
                                ),
                                child: Text(
                                  content.customizeLabel,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: green,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: _isSaving ? null : _rejectOptional,
                                style: TextButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  foregroundColor: bodyColor,
                                ),
                                child: Text(
                                  content.rejectOptionalLabel,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: bodyColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: Text(
                                content.footerNote,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: bodyColor.withValues(alpha: 0.82),
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
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

class _CookieConsentDialogContent {
  const _CookieConsentDialogContent({
    required this.profileKey,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.acceptAllLabel,
    required this.customizeLabel,
    required this.rejectOptionalLabel,
    required this.footerNote,
    required this.versionLabel,
    required this.accentColor,
    required this.options,
  });

  final String profileKey;
  final String title;
  final String subtitle;
  final String body;
  final String acceptAllLabel;
  final String customizeLabel;
  final String rejectOptionalLabel;
  final String footerNote;
  final String versionLabel;
  final Color accentColor;
  final List<_ConsentOption> options;

  factory _CookieConsentDialogContent.fallback(bool isArabic) {
    return _CookieConsentDialogContent(
      profileKey: _defaultProfileKey,
      title: isArabic ? 'سياسة الكوكيز' : 'Cookie policy',
      subtitle: isArabic
          ? 'نستخدم ملفات تعريف الارتباط الضرورية فقط لتشغيل المنصة، بينما تبقى الفئات الأخرى تحت سيطرتك قبل المتابعة.'
          : 'We only use the cookies that are necessary to run the platform, while optional categories stay under your control before you continue.',
      body: isArabic
          ? 'يمكنك الإبقاء على الكوكيز الضرورية فقط أو تخصيص الفئات الاختيارية بحسب ما يناسبك.'
          : 'You can keep only the essential cookies or tailor the optional categories to your preference.',
      acceptAllLabel: isArabic ? 'موافقة على الكل' : 'Accept all',
      customizeLabel: isArabic ? 'تخصيص الإعدادات' : 'Customize settings',
      rejectOptionalLabel: isArabic ? 'رفض غير الضروري' : 'Reject optional',
      footerNote: isArabic
          ? 'سيُحفظ اختيارك محليًا ويمكن تعديله لاحقًا من صفحة سياسة إدارة الموافقات.'
          : 'Your choice is stored locally and can be changed later from the consent management policy page.',
      versionLabel: 'v1',
      accentColor: Color(0xFFFF6500),
      options: _fallbackOptions(isArabic),
    );
  }

  factory _CookieConsentDialogContent.fromProfile(
    bool isArabic,
    CookieConsentProfilePayload profile,
  ) {
    final fallback = _CookieConsentDialogContent.fallback(isArabic);
    final resolvedOptions = profile.options
        .where((option) => option.isActive)
        .map((option) => _ConsentOption.fromPayload(isArabic, option))
        .toList(growable: false)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return _CookieConsentDialogContent(
      profileKey: profile.profileKey.trim().isNotEmpty
          ? profile.profileKey.trim()
          : fallback.profileKey,
      title: _localizedValue(
        isArabic,
        profile.titleAr,
        profile.titleEn,
        fallback.title,
      ),
      subtitle: _localizedValue(
        isArabic,
        profile.subtitleAr,
        profile.subtitleEn,
        fallback.subtitle,
      ),
      body: _localizedValue(
        isArabic,
        profile.bodyAr,
        profile.bodyEn,
        fallback.body,
      ),
      acceptAllLabel: _localizedValue(
        isArabic,
        profile.acceptAllLabelAr,
        profile.acceptAllLabelEn,
        fallback.acceptAllLabel,
      ),
      customizeLabel: _localizedValue(
        isArabic,
        profile.customizeLabelAr,
        profile.customizeLabelEn,
        fallback.customizeLabel,
      ),
      rejectOptionalLabel: _localizedValue(
        isArabic,
        profile.rejectOptionalLabelAr,
        profile.rejectOptionalLabelEn,
        fallback.rejectOptionalLabel,
      ),
      footerNote: _localizedValue(
        isArabic,
        profile.footerNoteAr,
        profile.footerNoteEn,
        fallback.footerNote,
      ),
      versionLabel: profile.versionLabel.trim().isNotEmpty
          ? profile.versionLabel.trim()
          : fallback.versionLabel,
      accentColor: _parseColorValue(profile.accentColor, fallback.accentColor),
      options: resolvedOptions.isNotEmpty ? resolvedOptions : fallback.options,
    );
  }
}

class _ConsentOption {
  _ConsentOption({
    required this.optionKey,
    required this.title,
    required this.description,
    required this.icon,
    required this.badge,
    required this.badgeColor,
    required this.locked,
    required this.preferenceKeys,
    required this.sortOrder,
    required this.enabled,
  });

  final String optionKey;
  final String title;
  final String description;
  final IconData icon;
  final String badge;
  final Color badgeColor;
  final bool locked;
  final List<String> preferenceKeys;
  final int sortOrder;
  bool enabled;

  factory _ConsentOption.fromPayload(
    bool isArabic,
    CookieConsentOptionPayload payload,
  ) {
    final preferenceKeys = payload.preferenceKeys.isNotEmpty
        ? payload.preferenceKeys
        : _defaultPreferenceKeysForOption(payload.optionKey);

    return _ConsentOption(
      optionKey: payload.optionKey,
      title: _localizedValue(
        isArabic,
        payload.titleAr,
        payload.titleEn,
        payload.optionKey,
      ),
      description: _localizedValue(
        isArabic,
        payload.descriptionAr,
        payload.descriptionEn,
        payload.optionKey,
      ),
      icon: _iconFromName(payload.iconName, Icons.tune_rounded),
      badge: _localizedValue(
        isArabic,
        payload.badgeAr,
        payload.badgeEn,
        payload.isLocked ? 'ثابت' : 'اختياري',
      ),
      badgeColor: _parseColorValue(payload.badgeColor, const Color(0xFFFF6500)),
      locked: payload.isLocked,
      preferenceKeys: preferenceKeys,
      sortOrder: payload.sortOrder,
      enabled: payload.isLocked ? true : payload.defaultEnabled,
    );
  }
}

class _ConsentOptionCard extends StatelessWidget {
  const _ConsentOptionCard({
    required this.option,
    required this.onChanged,
    required this.isArabic,
  });

  final _ConsentOption option;
  final ValueChanged<bool> onChanged;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const green = Color(0xFFFF6500);
    const titleColor = Color(0xFF111827);
    const bodyColor = Color(0xFF64748B);
    const borderColor = Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              option.icon,
              color: green,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (option.locked)
                      _MiniTag(
                        label: option.badge,
                        accentColor: option.badgeColor,
                      )
                    else
                      Switch.adaptive(
                        value: option.enabled,
                        onChanged: onChanged,
                        activeThumbColor: green,
                        activeTrackColor: green.withValues(alpha: 0.28),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  option.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: bodyColor,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({
    required this.label,
    required this.accentColor,
  });

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: accentColor,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DecorBlob extends StatelessWidget {
  const _DecorBlob({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

String _localizedValue(
  bool isArabic,
  String? arabic,
  String? english,
  String fallback,
) {
  final localized = isArabic ? arabic : english;
  final text = localized?.trim() ?? '';
  if (text.isNotEmpty) {
    return text;
  }

  final alternate = isArabic ? english : arabic;
  final alternateText = alternate?.trim() ?? '';
  if (alternateText.isNotEmpty) {
    return alternateText;
  }

  return fallback;
}

List<_ConsentOption> _fallbackOptions(bool isArabic) {
  return [
    _ConsentOption(
      optionKey: 'essential',
      title: isArabic ? 'الكوكيز الضرورية' : 'Essential cookies',
      description: isArabic
          ? 'تحافظ على تسجيل الدخول والجلسة والدفع والأمان، ولا يمكن إيقافها.'
          : 'Keep login, sessions, payments, and security working. These cannot be turned off.',
      icon: Icons.lock_rounded,
      badge: isArabic ? 'ثابت' : 'Locked',
      badgeColor: const Color(0xFFE34F00),
      locked: true,
      preferenceKeys: const [MyServices.keyCookieConsentNecessary],
      sortOrder: 0,
      enabled: true,
    ),
    _ConsentOption(
      optionKey: 'functional',
      title: isArabic ? 'الكوكيز الوظيفية' : 'Functional cookies',
      description: isArabic
          ? 'تتذكر اللغة والتفضيلات وبعض إعدادات الاستخدام لتسهيل التجربة.'
          : 'Remember language, preferences, and small usage settings to keep the experience smooth.',
      icon: Icons.tune_rounded,
      badge: isArabic ? 'اختياري' : 'Optional',
      badgeColor: const Color(0xFFB45309),
      locked: false,
      preferenceKeys: const [MyServices.keyCookieConsentFunctional],
      sortOrder: 1,
      enabled: false,
    ),
    _ConsentOption(
      optionKey: 'analytics_performance',
      title: isArabic ? 'تحليلات وأداء' : 'Analytics and performance',
      description: isArabic
          ? 'تساعدنا في فهم الاستقرار والأداء وتحسين الخدمة بشكل مستمر.'
          : 'Help us understand stability and performance so we can improve the service continuously.',
      icon: Icons.query_stats_rounded,
      badge: isArabic ? 'تحسين' : 'Improve',
      badgeColor: const Color(0xFF4338CA),
      locked: false,
      preferenceKeys: const [
        MyServices.keyCookieConsentAnalytics,
        MyServices.keyCookieConsentPerformance,
      ],
      sortOrder: 2,
      enabled: false,
    ),
    _ConsentOption(
      optionKey: 'communications',
      title: isArabic
          ? 'الاتصالات والخدمات الخارجية'
          : 'Communications and external services',
      description: isArabic
          ? 'تُستخدم لتنبيهات الطلبات ورسائل التحقق والخدمات المرتبطة بالتشغيل.'
          : 'Used for order notifications, verification messages, and related operating services.',
      icon: Icons.notifications_active_outlined,
      badge: isArabic ? 'تنبيه' : 'Alerts',
      badgeColor: const Color(0xFFFF6500),
      locked: false,
      preferenceKeys: const [
        MyServices.keyCookieConsentCommunication,
        MyServices.keyCookieConsentThirdParty,
      ],
      sortOrder: 3,
      enabled: false,
    ),
  ];
}

List<String> _defaultPreferenceKeysForOption(String optionKey) {
  switch (optionKey.trim()) {
    case 'essential':
    case 'necessary':
      return const [MyServices.keyCookieConsentNecessary];
    case 'functional':
      return const [MyServices.keyCookieConsentFunctional];
    case 'analytics':
    case 'performance':
    case 'analytics_performance':
      return const [
        MyServices.keyCookieConsentAnalytics,
        MyServices.keyCookieConsentPerformance,
      ];
    case 'communications':
    case 'communication':
    case 'third_party':
      return const [
        MyServices.keyCookieConsentCommunication,
        MyServices.keyCookieConsentThirdParty,
      ];
    default:
      return [optionKey];
  }
}

const String _defaultProfileKey = 'first_launch_cookie_policy';

Color _parseColorValue(String? value, Color fallback) {
  final raw = value?.trim().replaceAll('#', '') ?? '';
  if (raw.isEmpty) {
    return fallback;
  }

  final normalized = raw.length == 6 ? 'FF$raw' : raw;
  try {
    return Color(int.parse(normalized, radix: 16));
  } catch (_) {
    return fallback;
  }
}

IconData _iconFromName(String? value, IconData fallback) {
  switch ((value ?? '').trim()) {
    case 'policy_outlined':
      return Icons.policy_outlined;
    case 'storefront_outlined':
      return Icons.storefront_outlined;
    case 'privacy_tip_outlined':
      return Icons.privacy_tip_outlined;
    case 'description_outlined':
      return Icons.description_outlined;
    case 'verified_outlined':
      return Icons.verified_outlined;
    case 'fact_check_outlined':
      return Icons.fact_check_outlined;
    case 'account_balance_wallet_outlined':
      return Icons.account_balance_wallet_outlined;
    case 'payments_outlined':
      return Icons.payments_outlined;
    case 'shopping_cart_checkout_outlined':
      return Icons.shopping_cart_checkout_outlined;
    case 'card_giftcard_rounded':
      return Icons.card_giftcard_rounded;
    case 'star_border_rounded':
      return Icons.star_border_rounded;
    case 'star_rounded':
      return Icons.star_rounded;
    case 'star_outline_rounded':
      return Icons.star_outline_rounded;
    case 'cancel_outlined':
      return Icons.cancel_outlined;
    case 'assignment_return_outlined':
      return Icons.assignment_return_outlined;
    case 'block_outlined':
      return Icons.block_outlined;
    case 'notifications_active_outlined':
      return Icons.notifications_active_outlined;
    case 'shield_outlined':
      return Icons.shield_outlined;
    case 'cookie_outlined':
      return Icons.cookie_outlined;
    case 'handshake_outlined':
      return Icons.handshake_outlined;
    case 'reviews_outlined':
      return Icons.rate_review_outlined;
    case 'shopping_bag_outlined':
      return Icons.shopping_bag_outlined;
    case 'tune_rounded':
      return Icons.tune_rounded;
    case 'query_stats_rounded':
      return Icons.query_stats_rounded;
    case 'lock_rounded':
      return Icons.lock_rounded;
    default:
      return fallback;
  }
}
