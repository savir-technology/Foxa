import 'package:flutter/material.dart';
import 'package:tks/view/widget/common/legal_document_screen.dart';

class PaymentsAndWalletPolicyScreen extends StatelessWidget {
  const PaymentsAndWalletPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      config: LegalDocumentScreenConfig(
        assetPath: 'lib/view/screen/سياسة المدفوعات والمحفظه',
        documentKey: 'payments_wallet_policy',
        titleAr: 'سياسة المدفوعات والمحفظة',
        titleEn: 'Payments and wallet policy',
        subtitleAr: 'تعرف على قواعد الدفع والمحفظة والاسترداد داخل التطبيق.',
        subtitleEn:
            'Review the payment, wallet, and refund rules used in the app.',
        summaryAr: [
          'تغطّي المدفوعات الإلكترونية والمحفظة الرقمية.',
          'توضّح الاسترداد والشحن والرصيد والقسائم.',
          'تشرح مسؤولياتك عند استخدام أي وسيلة دفع داخل المنصة.',
        ],
        summaryEn: [
          'Covers electronic payments and the digital wallet.',
          'Explains refunds, top-ups, balance, and coupons.',
          'Clarifies your responsibilities when using in-app payment methods.',
        ],
        accentColor: Color(0xFFFF6500),
        heroIcon: Icons.account_balance_wallet_outlined,
      ),
    );
  }
}
