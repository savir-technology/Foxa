import 'package:flutter/material.dart';
import 'package:tks/view/widget/common/legal_document_screen.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LegalDocumentScreen(
      config: LegalDocumentScreenConfig(
        assetPath: 'lib/view/screen/شروط الاستخدام',
        documentKey: 'terms_of_use',
        titleAr: 'شروط الاستخدام',
        titleEn: 'Terms of use',
        subtitleAr: 'راجع الشروط التي تنظّم استخدامك للمنصة والتطبيق.',
        subtitleEn: 'Review the terms that govern your use of the platform.',
        summaryAr: [
          'استخدم بيانات صحيحة وقابلة للتواصل عند إنشاء الحساب أو الطلب.',
          'أوقات التسليم تقديرية وقد تتغير حسب الظروف التشغيلية.',
          'يجوز تقييد الحسابات أو إيقافها عند المخالفات أو إساءة الاستخدام.',
        ],
        summaryEn: [
          'Use accurate and reachable details when creating accounts or orders.',
          'Delivery times are estimates and may change with operational conditions.',
          'Accounts may be restricted or suspended for misuse or violations.',
        ],
        accentColor: Color(0xFFB45309),
        heroIcon: Icons.description_outlined,
      ),
    );
  }
}
