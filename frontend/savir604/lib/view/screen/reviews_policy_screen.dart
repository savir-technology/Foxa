import 'package:flutter/material.dart';
import 'package:tks/view/widget/common/legal_document_screen.dart';

class ReviewsPolicyScreen extends StatelessWidget {
  const ReviewsPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      config: LegalDocumentScreenConfig(
        assetPath: 'lib/view/screen/سياسة التقييمات والمراجعات',
        documentKey: 'reviews_policy',
        titleAr: 'سياسة التقييمات والمراجعات',
        titleEn: 'Ratings and reviews policy',
        subtitleAr: 'تعرف على قواعد كتابة المراجعات وتقييم السائقين والمطاعم.',
        subtitleEn:
            'Learn the rules for ratings, reviews, and feedback submissions.',
        summaryAr: [
          'التقييمات يجب أن تكون صادقة ومبنية على تجربة فعلية.',
          'يُمنع الإساءة أو التشهير أو المحتوى المكرر.',
          'يمكن إزالة المحتوى المخالف أو غير الملائم لحماية المنصة والمستخدمين.',
        ],
        summaryEn: [
          'Ratings must be honest and based on real experience.',
          'Abusive, defamatory, or repetitive content is not allowed.',
          'Violating content may be removed to protect users and the platform.',
        ],
        accentColor: Color(0xFF7C3AED),
        heroIcon: Icons.star_outline_rounded,
      ),
    );
  }
}
