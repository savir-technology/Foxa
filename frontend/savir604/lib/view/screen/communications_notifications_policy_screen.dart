import 'package:flutter/material.dart';
import 'package:tks/view/widget/common/legal_document_screen.dart';

class CommunicationsNotificationsPolicyScreen extends StatelessWidget {
  const CommunicationsNotificationsPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      config: LegalDocumentScreenConfig(
        assetPath: 'lib/view/screen/سياسة الاتصالات والاشعارات',
        documentKey: 'communications_notifications_policy',
        titleAr: 'سياسة الاتصالات والإشعارات',
        titleEn: 'Communications and notifications policy',
        subtitleAr:
            'تعرف على رسائل التطبيق، والإشعارات، ورسائل التحقق والتشغيل.',
        subtitleEn:
            'Review in-app messages, notifications, and operational alerts.',
        summaryAr: [
          'تغطي رسائل التحقق والرسائل التشغيلية وإشعارات الطلبات.',
          'تشرح قنوات التواصل المسموح بها داخل التطبيق وخارجه.',
          'توضح كيف يمكن ضبط الإشعارات أو إيقافها عند الحاجة.',
        ],
        summaryEn: [
          'Covers verification messages, operational alerts, and order notifications.',
          'Explains permitted communication channels inside and outside the app.',
          'Shows how notifications can be controlled or muted when needed.',
        ],
        accentColor: Color(0xFF2563EB),
        heroIcon: Icons.notifications_active_outlined,
      ),
    );
  }
}
