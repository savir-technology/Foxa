import 'package:flutter/material.dart';
import 'package:tks/view/widget/common/legal_document_screen.dart';

class OrdersForOthersPolicyScreen extends StatelessWidget {
  const OrdersForOthersPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      config: LegalDocumentScreenConfig(
        assetPath: 'lib/view/screen/سياسة الطلبات المقدمه للغير',
        documentKey: 'orders_for_others_policy',
        titleAr: 'سياسة الطلبات المقدمة للغير',
        titleEn: 'Orders for others policy',
        subtitleAr:
            'تعرف على شروط الطلب كهديّة أو لشخص آخر وكيفية إدخال بياناته.',
        subtitleEn:
            'Read the rules for ordering for another person or as a gift.',
        summaryAr: [
          'توضح من يُعدّ صاحب الطلب ومسؤول الدفع.',
          'تشرح بيانات المستلم وتأكيد التسليم وإشعارات الحالة.',
          'تحدّد الحالات التي تبقى فيها المسؤولية على مقدم الطلب.',
        ],
        summaryEn: [
          'Explains who remains responsible for the order and payment.',
          'Covers recipient details, delivery confirmation, and status updates.',
          'Defines when the ordering customer keeps legal responsibility.',
        ],
        accentColor: Color(0xFFBE123C),
        heroIcon: Icons.card_giftcard_rounded,
      ),
    );
  }
}
