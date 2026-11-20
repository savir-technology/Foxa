import 'package:flutter/material.dart';
import 'package:tks/view/widget/common/legal_document_screen.dart';

class ProhibitedUsePolicyScreen extends StatelessWidget {
  const ProhibitedUsePolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      config: LegalDocumentScreenConfig(
        assetPath: 'lib/view/screen/سياسة الاستخدام المحظور والسلوك المقبول',
        documentKey: 'prohibited_use_policy',
        titleAr: 'سياسة الاستخدام المحظور والسلوك المقبول',
        titleEn: 'Prohibited use and acceptable behaviour policy',
        subtitleAr: 'تعرف على السلوك المسموح والممنوع داخل المنصة والتطبيق.',
        subtitleEn:
            'Read what is allowed and what is prohibited on the platform.',
        summaryAr: [
          'تحظر الاحتيال وانتحال الهوية وإساءة الاستخدام.',
          'توضح السلوك المقبول عند التواصل والدفع والتقييم.',
          'تمنح المنصة حق تقييد الحسابات المخالفة أو إيقافها.',
        ],
        summaryEn: [
          'Prohibits fraud, impersonation, and abusive use.',
          'Covers acceptable behavior in communication, payment, and reviews.',
          'Allows the platform to restrict or suspend violating accounts.',
        ],
        accentColor: Color(0xFFDC2626),
        heroIcon: Icons.block_outlined,
      ),
    );
  }
}
