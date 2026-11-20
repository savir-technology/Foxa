import 'package:flutter/material.dart';
import 'package:tks/view/widget/common/legal_document_screen.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      config: LegalDocumentScreenConfig(
        assetPath: 'lib/view/screen/سياسة الخصوصيه',
        documentKey: 'privacy_policy',
        titleAr: 'سياسة الخصوصية',
        titleEn: 'Privacy policy',
        subtitleAr: 'تعرف على كيفية جمع بياناتك واستخدامها وحمايتها.',
        subtitleEn: 'Learn how your data is collected, used, and protected.',
        summaryAr: [
          'نجمع الحد الأدنى من البيانات اللازمة لتشغيل الخدمة.',
          'نشارك البيانات فقط مع الجهات الضرورية مثل الدفع والإشعارات.',
          'يمكنك طلب الوصول إلى بياناتك أو تصحيحها أو حذفها عبر الدعم.',
        ],
        summaryEn: [
          'We collect only the data needed to run the service.',
          'Data is shared only with required providers such as payments and notifications.',
          'You can request access, correction, or deletion through support.',
        ],
        accentColor: Color(0xFF2563EB),
        heroIcon: Icons.privacy_tip_outlined,
      ),
    );
  }
}
