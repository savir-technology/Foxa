import 'package:flutter/material.dart';
import 'package:tks/view/widget/common/legal_document_screen.dart';

class ConsentManagementPolicyScreen extends StatelessWidget {
  const ConsentManagementPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      config: LegalDocumentScreenConfig(
        assetPath: 'lib/view/screen/سياسة ادارة الموافقات',
        documentKey: 'consent_management_policy',
        titleAr: 'سياسة إدارة الموافقات',
        titleEn: 'Consent management policy',
        subtitleAr: 'تعرف على كيف نطلب الموافقة ونخزنها ونسمح بسحبها.',
        subtitleEn: 'Learn how we request, store, and withdraw consent.',
        summaryAr: [
          'الموافقة تكون واضحة ومحددة وقابلة للسحب في أي وقت.',
          'يمكنك تغيير التفضيلات من الإعدادات أو من صفحة السياسة.',
          'المعالجة غير الضرورية لا تعمل إلا عند وجود أساس قانوني مناسب.',
        ],
        summaryEn: [
          'Consent must be clear, specific, and withdrawable at any time.',
          'You can change preferences from settings or the policy page.',
          'Non-essential processing should rely on a proper legal basis.',
        ],
        accentColor: Color(0xFFEA580C),
        heroIcon: Icons.fact_check_outlined,
      ),
    );
  }
}
