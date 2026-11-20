import 'package:flutter/material.dart';
import 'package:tks/view/widget/common/legal_document_screen.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      config: LegalDocumentScreenConfig(
        assetPath: 'lib/view/screen/من نحن',
        documentKey: 'about_us',
        titleAr: 'من نحن',
        titleEn: 'About us',
        subtitleAr: 'تعرف على هوية المنصة ونطاقها ومعلوماتها القانونية.',
        subtitleEn: 'Learn about the platform, its scope, and legal details.',
        summaryAr: [
          'منصة تقنية متخصصة في الطلب والتوصيل الرقمي.',
          'تجمع المستخدمين والمطاعم وشركاء التوصيل في تجربة واحدة.',
          'تلتزم بالحوكمة وحماية البيانات والامتثال التنظيمي.',
        ],
        summaryEn: [
          'A technology platform focused on digital ordering and delivery.',
          'Brings users, restaurants, and delivery partners into one flow.',
          'Committed to governance, data protection, and regulatory compliance.',
        ],
        accentColor: Color(0xFFFF6500),
        heroIcon: Icons.storefront_outlined,
      ),
    );
  }
}
