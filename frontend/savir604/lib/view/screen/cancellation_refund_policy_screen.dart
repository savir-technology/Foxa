import 'package:flutter/material.dart';
import 'package:tks/view/widget/common/legal_document_screen.dart';

class CancellationRefundPolicyScreen extends StatelessWidget {
  const CancellationRefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      config: LegalDocumentScreenConfig(
        assetPath: 'lib/view/screen/سياسة الالغاء والطلبات والاسترداد',
        documentKey: 'cancellation_refund_policy',
        titleAr: 'سياسة الإلغاء والطلبات والاسترداد',
        titleEn: 'Cancellation, orders, and refunds policy',
        subtitleAr: 'راجع متى يمكن الإلغاء ومتى ينطبق الاسترداد أو التعويض.',
        subtitleEn: 'Review when cancellations or refunds may apply.',
        summaryAr: [
          'تشرح حالات الإلغاء قبل التجهيز وأثناء التنفيذ وبعدها.',
          'تحدد متى يُقبل الاسترداد ومتى يُرفض وفق الحالة الفعلية.',
          'تغطي النزاعات والرسوم والطلبات التي تتطلب معالجة خاصة.',
        ],
        summaryEn: [
          'Explains cancellation before preparation, during handling, and after.',
          'Defines when a refund or compensation may be granted.',
          'Covers disputes, fees, and cases that need special handling.',
        ],
        accentColor: Color(0xFFEA580C),
        heroIcon: Icons.assignment_return_outlined,
      ),
    );
  }
}
