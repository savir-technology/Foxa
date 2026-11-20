import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/data/datasource/remote/content/legal_content_data.dart';
import 'package:tks/view/widget/common/app_top_banner.dart';

class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({
    super.key,
    required this.config,
  });

  final LegalDocumentScreenConfig config;

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class LegalDocumentScreenConfig {
  const LegalDocumentScreenConfig({
    required this.assetPath,
    this.documentKey,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.summaryAr,
    required this.summaryEn,
    required this.accentColor,
    this.heroIcon = Icons.policy_outlined,
  });

  final String assetPath;
  final String? documentKey;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final List<String> summaryAr;
  final List<String> summaryEn;
  final Color accentColor;
  final IconData heroIcon;
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  late Future<_LegalDocumentBundle> _documentFuture;

  @override
  void initState() {
    super.initState();
    _documentFuture = _loadDocument();
  }

  Future<_LegalDocumentBundle> _loadDocument() async {
    final documentKey = widget.config.documentKey?.trim() ?? '';
    if (documentKey.isNotEmpty) {
      final remote = await const LegalContentData().fetchDocument(documentKey);
      if (remote != null) {
        return _LegalDocumentBundle.fromRemote(
          remote,
          config: widget.config,
        );
      }
    }

    final raw = await rootBundle.loadString(widget.config.assetPath);
    return _LegalDocumentBundle.fromFallback(widget.config, raw);
  }

  void _reloadDocument() {
    setState(() {
      _documentFuture = _loadDocument();
    });
  }

  void _handleBack() {
    if (Get.previousRoute.isNotEmpty) {
      Get.back();
    } else {
      Get.offAllNamed(AppRoutes.homepage);
    }
  }

  String _localized(bool isArabic, String arabic, String english) {
    return isArabic ? arabic : english;
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final isArabic = (Get.locale?.languageCode ?? 'ar') == 'ar';
    final isDark = baseTheme.brightness == Brightness.dark;
    const legalOrange = Color(0xFFFF6500);
    final legalTheme = baseTheme.copyWith(
      scaffoldBackgroundColor: isDark ? const Color(0xFF0B0B0B) : Colors.white,
      cardColor: isDark ? const Color(0xFF151515) : Colors.white,
      dividerColor: isDark ? const Color(0xFF343434) : const Color(0xFFF0D8CA),
      shadowColor: Colors.black,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: isDark ? const Color(0xFFFF761A) : legalOrange,
        secondary: isDark ? const Color(0xFFFF9A52) : const Color(0xFFE34F00),
        tertiary: isDark ? const Color(0xFF9AA8A0) : const Color(0xFF64748B),
        surface: isDark ? const Color(0xFF151515) : Colors.white,
        onSurface: isDark ? const Color(0xFFF7F7F7) : const Color(0xFF171717),
      ),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: isDark ? const Color(0xFFF4F7F4) : const Color(0xFF111827),
        displayColor:
            isDark ? const Color(0xFFF4F7F4) : const Color(0xFF111827),
      ),
    );

    return Theme(
      data: legalTheme,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          const accentPalette = <Color>[
            legalOrange,
            Color(0xFFE34F00),
            Color(0xFF64748B),
          ];

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Container(
              color: theme.scaffoldBackgroundColor,
              child: SafeArea(
                bottom: false,
                child: FutureBuilder<_LegalDocumentBundle>(
                  future: _documentFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return _LegalFailureState(
                        isArabic: isArabic,
                        onRetry: _reloadDocument,
                        icon: widget.config.heroIcon,
                      );
                    }

                    final document = snapshot.data!;
                    final accentColor = document.accentColor;
                    final summaryItems = document.summary(isArabic);
                    final sections = document.sections(isArabic);
                    final detailLabel = document.articleCount(isArabic) > 0
                        ? _localized(isArabic, 'المواد', 'Articles')
                        : _localized(isArabic, 'الفقرات', 'Paragraphs');
                    final detailValue = document.articleCount(isArabic) > 0
                        ? document.articleCount(isArabic)
                        : document.paragraphCount(isArabic);

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                      children: [
                        AppTopBanner(
                          title: document.title(isArabic),
                          subtitle: document.subtitle(isArabic),
                          leadingIcon: Icons.arrow_back_rounded,
                          onLeadingTap: _handleBack,
                          child: Row(
                            children: [
                              Expanded(
                                child: AppTopBannerMetric(
                                  value: sections.length.toString(),
                                  label: _localized(
                                      isArabic, 'الأقسام', 'Sections'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTopBannerMetric(
                                  value: detailValue.toString(),
                                  label: detailLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _LegalSummaryCard(
                          accentColor: accentColor,
                          title: _localized(
                            isArabic,
                            'نظرة سريعة',
                            'Quick summary',
                          ),
                          items: summaryItems,
                          isArabic: isArabic,
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _localized(
                            isArabic,
                            'الأقسام بالتفصيل',
                            'Detailed sections',
                          ),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (sections.isEmpty)
                          _LegalFallbackCard(
                            accentColor: accentColor,
                            text: document.raw(isArabic),
                            isArabic: isArabic,
                          )
                        else
                          ...sections.asMap().entries.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _LegalSectionCard(
                                    index: entry.key,
                                    section: entry.value,
                                    accentColor: accentPalette[
                                        entry.key % accentPalette.length],
                                    initiallyExpanded: entry.key == 0,
                                    isArabic: isArabic,
                                  ),
                                ),
                              ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LegalFailureState extends StatelessWidget {
  const _LegalFailureState({
    required this.isArabic,
    required this.onRetry,
    required this.icon,
  });

  final bool isArabic;
  final VoidCallback onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 46,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 14),
                Text(
                  isArabic ? 'تعذر تحميل الصفحة' : 'Unable to load page',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic
                      ? 'تحقق من تضمين ملف الوثيقة كأصل داخل التطبيق ثم حاول مرة أخرى.'
                      : 'Check that the document asset is bundled, then try again.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalSummaryCard extends StatelessWidget {
  const _LegalSummaryCard({
    required this.accentColor,
    required this.title,
    required this.items,
    required this.isArabic,
  });

  final Color accentColor;
  final String title;
  final List<String> items;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.dividerColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: borderColor),
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.verified_outlined, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LegalBulletItem(
                text: item,
                accentColor: accentColor,
                isArabic: isArabic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalBulletItem extends StatelessWidget {
  const _LegalBulletItem({
    required this.text,
    required this.accentColor,
    required this.isArabic,
  });

  final String text;
  final Color accentColor;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: 16,
            color: accentColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.55,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegalFallbackCard extends StatelessWidget {
  const _LegalFallbackCard({
    required this.accentColor,
    required this.text,
    required this.isArabic,
  });

  final Color accentColor;
  final String text;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
        color: theme.cardColor,
      ),
      child: SelectableText(
        text,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.7,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
        ),
      ),
    );
  }
}

class _LegalSectionCard extends StatelessWidget {
  const _LegalSectionCard({
    required this.index,
    required this.section,
    required this.accentColor,
    required this.initiallyExpanded,
    required this.isArabic,
  });

  final int index;
  final _LegalSection section;
  final Color accentColor;
  final bool initiallyExpanded;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyText = section.body.isEmpty ? section.raw : section.body;
    final title =
        section.title.isEmpty ? (isArabic ? 'قسم' : 'Section') : section.title;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor),
          color: theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            maintainState: true,
            tilePadding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            iconColor: accentColor,
            collapsedIconColor: accentColor,
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (index + 1).toString().padLeft(2, '0'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SelectableText(
                  bodyText,
                  textDirection:
                      isArabic ? TextDirection.rtl : TextDirection.ltr,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.72,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
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

class _LegalDocument {
  const _LegalDocument({
    required this.raw,
    required this.sections,
    required this.articleCount,
    required this.paragraphCount,
  });

  final String raw;
  final List<_LegalSection> sections;
  final int articleCount;
  final int paragraphCount;

  factory _LegalDocument.fromRaw(String raw) {
    final normalized = raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\u200f', '')
        .replaceAll('\ufeff', '')
        .trim();
    final chunks = _splitChunks(normalized);
    final sections = chunks
        .map(_LegalSection.fromChunk)
        .where((section) => section.raw.isNotEmpty)
        .toList(growable: false);
    final articleCount = sections
        .where((section) =>
            RegExp(r'^(المادة|Article|Section)\b').hasMatch(section.title))
        .length;
    final paragraphCount = normalized
        .split(RegExp(r'\n{2,}'))
        .where((part) => part.trim().isNotEmpty)
        .length;

    return _LegalDocument(
      raw: normalized,
      sections: sections,
      articleCount: articleCount,
      paragraphCount: paragraphCount,
    );
  }

  static List<String> _splitChunks(String text) {
    final lines = text.split('\n');
    final chunks = <String>[];
    final buffer = <String>[];

    void flush() {
      final chunk = buffer.join('\n').trim();
      if (chunk.isNotEmpty) {
        chunks.add(chunk);
      }
      buffer.clear();
    }

    for (final line in lines) {
      if (_isSeparatorLine(line)) {
        flush();
        continue;
      }
      buffer.add(line);
    }
    flush();

    if (chunks.length > 1) {
      return chunks;
    }

    return text
        .split(RegExp(r'\n{2,}'))
        .map((chunk) => chunk.trim())
        .where((chunk) => chunk.isNotEmpty)
        .toList(growable: false);
  }
}

class _LegalDocumentBundle {
  const _LegalDocumentBundle({
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.summaryAr,
    required this.summaryEn,
    required this.rawAr,
    required this.rawEn,
    required this.sectionsAr,
    required this.sectionsEn,
    required this.articleCountAr,
    required this.articleCountEn,
    required this.paragraphCountAr,
    required this.paragraphCountEn,
    required this.accentColor,
    required this.heroIcon,
  });

  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final List<String> summaryAr;
  final List<String> summaryEn;
  final String rawAr;
  final String rawEn;
  final List<_LegalSection> sectionsAr;
  final List<_LegalSection> sectionsEn;
  final int articleCountAr;
  final int articleCountEn;
  final int paragraphCountAr;
  final int paragraphCountEn;
  final Color accentColor;
  final IconData heroIcon;

  factory _LegalDocumentBundle.fromFallback(
    LegalDocumentScreenConfig config,
    String raw,
  ) {
    final document = _LegalDocument.fromRaw(raw);
    final englishDocument = _LegalDocument.fromRaw(
      _englishFallbackRaw(config),
    );
    return _LegalDocumentBundle(
      titleAr: config.titleAr,
      titleEn: config.titleEn,
      subtitleAr: config.subtitleAr,
      subtitleEn: config.subtitleEn,
      summaryAr: config.summaryAr,
      summaryEn: config.summaryEn,
      rawAr: document.raw,
      rawEn: englishDocument.raw,
      sectionsAr: document.sections,
      sectionsEn: englishDocument.sections,
      articleCountAr: document.articleCount,
      articleCountEn: englishDocument.articleCount,
      paragraphCountAr: document.paragraphCount,
      paragraphCountEn: englishDocument.paragraphCount,
      accentColor: config.accentColor,
      heroIcon: config.heroIcon,
    );
  }

  factory _LegalDocumentBundle.fromRemote(
    LegalDocumentPayload payload, {
    required LegalDocumentScreenConfig config,
  }) {
    final titleAr = payload.titleAr.trim().isNotEmpty
        ? payload.titleAr.trim()
        : config.titleAr;
    final titleEn = payload.titleEn.trim().isNotEmpty
        ? payload.titleEn.trim()
        : config.titleEn;
    final subtitleAr = payload.subtitleAr.trim().isNotEmpty
        ? payload.subtitleAr.trim()
        : config.subtitleAr;
    final subtitleEn = payload.subtitleEn.trim().isNotEmpty
        ? payload.subtitleEn.trim()
        : config.subtitleEn;
    final summaryAr =
        payload.summaryAr.isNotEmpty ? payload.summaryAr : config.summaryAr;
    final summaryEn =
        payload.summaryEn.isNotEmpty ? payload.summaryEn : config.summaryEn;
    final rawAr = payload.contentAr.trim();
    final rawEn =
        payload.contentEn.trim().isNotEmpty ? payload.contentEn.trim() : rawAr;
    final rawArEffective = rawAr.isNotEmpty ? rawAr : rawEn;
    final rawEnEffective = rawEn.isNotEmpty ? rawEn : rawArEffective;
    final arDocument = _LegalDocument.fromRaw(rawArEffective);
    final enDocument = _LegalDocument.fromRaw(rawEnEffective);

    return _LegalDocumentBundle(
      titleAr: titleAr,
      titleEn: titleEn,
      subtitleAr: subtitleAr,
      subtitleEn: subtitleEn,
      summaryAr: summaryAr,
      summaryEn: summaryEn,
      rawAr: rawArEffective,
      rawEn: rawEnEffective,
      sectionsAr: arDocument.sections,
      sectionsEn: enDocument.sections,
      articleCountAr: arDocument.articleCount,
      articleCountEn: enDocument.articleCount,
      paragraphCountAr: arDocument.paragraphCount,
      paragraphCountEn: enDocument.paragraphCount,
      accentColor: _parseColorValue(payload.accentColor, config.accentColor),
      heroIcon: _iconFromName(payload.heroIcon, config.heroIcon),
    );
  }

  String title(bool isArabic) => isArabic ? titleAr : titleEn;
  String subtitle(bool isArabic) => isArabic ? subtitleAr : subtitleEn;
  List<String> summary(bool isArabic) => isArabic ? summaryAr : summaryEn;
  String raw(bool isArabic) => isArabic ? rawAr : rawEn;
  List<_LegalSection> sections(bool isArabic) =>
      isArabic ? sectionsAr : sectionsEn;
  int articleCount(bool isArabic) => isArabic ? articleCountAr : articleCountEn;
  int paragraphCount(bool isArabic) =>
      isArabic ? paragraphCountAr : paragraphCountEn;
}

String _englishFallbackRaw(LegalDocumentScreenConfig config) {
  final lines = <String>[
    config.titleEn,
    config.subtitleEn,
    '',
    'Summary',
    ...config.summaryEn.map((item) => '• $item'),
    '',
    'Full document',
    'The complete English version is loaded from Aleppo Eats legal documents service when available. Please reconnect and reopen this page if the full document is not displayed.',
  ];

  return lines.join('\n').trim();
}

class _LegalSection {
  const _LegalSection({
    required this.title,
    required this.body,
    required this.raw,
  });

  final String title;
  final String body;
  final String raw;

  factory _LegalSection.fromChunk(String chunk) {
    final cleaned = _cleanText(chunk);
    final lines = cleaned
        .split('\n')
        .map(_cleanText)
        .where((line) => line.isNotEmpty)
        .toList(growable: false);

    if (lines.isEmpty) {
      return const _LegalSection(title: '', body: '', raw: '');
    }

    final title = lines.first;
    final body = lines.length > 1 ? lines.skip(1).join('\n').trim() : '';
    return _LegalSection(title: title, body: body, raw: cleaned);
  }
}

bool _isSeparatorLine(String line) {
  final cleaned = _cleanText(line);
  return RegExp(r'^(?:⸻|—{2,}|-{3,}|\*{3,}|•{3,})$').hasMatch(cleaned);
}

String _cleanText(String value) {
  return value.replaceAll('\u200f', '').replaceAll('\ufeff', '').trim();
}

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
    default:
      return fallback;
  }
}
