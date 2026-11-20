import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/view/screen/support.dart';
import 'package:tks/view/widget/common/app_top_banner.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final services = Get.find<MyServices>();
    final userId = services.sharedPreferences.getInt('id') ?? 0;
    final isArabic = (Get.locale?.languageCode ?? 'ar') == 'ar';
    String t(String arabic, String english) => isArabic ? arabic : english;

    final legalDocs = [
      _LegalHelpItem(
        icon: Icons.account_balance_wallet_outlined,
        title: t('سياسة المدفوعات والمحفظة', 'Payments and wallet policy'),
        subtitle: t(
          'تعرف على قواعد الدفع والمحفظة والاسترداد.',
          'Read the payment, wallet, and refund rules.',
        ),
        route: AppRoutes.paymentsAndWalletPolicy,
      ),
      _LegalHelpItem(
        icon: Icons.card_giftcard_rounded,
        title: t('سياسة الطلبات المقدمة للغير', 'Orders for others policy'),
        subtitle: t(
          'افهم بيانات المستلم ومسؤولية مقدم الطلب.',
          'Understand recipient details and customer responsibility.',
        ),
        route: AppRoutes.ordersForOthersPolicy,
      ),
      _LegalHelpItem(
        icon: Icons.star_outline_rounded,
        title: t('سياسة التقييمات والمراجعات', 'Ratings and reviews policy'),
        subtitle: t(
          'تعرف على قواعد التقييم والمراجعة والمحتوى المسموح.',
          'Review the rules for ratings, reviews, and allowed content.',
        ),
        route: AppRoutes.reviewsPolicy,
      ),
      _LegalHelpItem(
        icon: Icons.assignment_return_outlined,
        title: t(
          'سياسة الإلغاء والطلبات والاسترداد',
          'Cancellation and refund policy',
        ),
        subtitle: t(
          'راجع حالات الإلغاء ومتى ينطبق الاسترداد.',
          'See when cancellation or refund may apply.',
        ),
        route: AppRoutes.cancellationRefundPolicy,
      ),
      _LegalHelpItem(
        icon: Icons.block_outlined,
        title: t(
          'سياسة الاستخدام المحظور والسلوك المقبول',
          'Prohibited use policy',
        ),
        subtitle: t(
          'تعرف على ما هو مسموح وما هو محظور داخل المنصة.',
          'See what is allowed and what is prohibited on the platform.',
        ),
        route: AppRoutes.prohibitedUsePolicy,
      ),
      _LegalHelpItem(
        icon: Icons.notifications_active_outlined,
        title: t('سياسة الاتصالات والإشعارات', 'Communications policy'),
        subtitle: t(
          'راجع الرسائل التشغيلية والإشعارات والتواصل.',
          'Review operational messages, notifications, and communication.',
        ),
        route: AppRoutes.communicationsPolicy,
      ),
      _LegalHelpItem(
        icon: Icons.storefront_outlined,
        title: t('من نحن', 'About us'),
        subtitle: t(
          'تعرف على هوية المنصة ونطاقها القانوني.',
          'Learn about the platform identity and legal scope.',
        ),
        route: AppRoutes.aboutus,
      ),
    ];

    final faqItems = [
      (
        t(
          'كيف أرسل طلبًا لشخص آخر؟',
          'How do I send an order to someone else?',
        ),
        t(
          'من السلة اختر الطلب لشخص آخر، ثم اختر مستلمًا محفوظًا أو أضف مستلمًا جديدًا.',
          'From the cart, choose "Someone else" and then select a saved recipient or add a new one.',
        ),
      ),
      (
        t('كيف أتابع الطلب مباشرة؟', 'How can I track the order live?'),
        t(
          'بعد إنشاء الطلب ستظهر شاشة التتبع وفيها مرحلة الطلب وموقع السائق عند توفره.',
          'After placing the order, the live tracking screen shows the order stage and driver position when available.',
        ),
      ),
      (
        t('هل يمكنني الدفع من خارج مصر؟', 'Can I pay from outside Egypt?'),
        t(
          'نعم، التطبيق مجهز لبوابات دفع متعددة بالإضافة إلى المحفظة عند تفعيلها.',
          'Yes. The app is prepared for multiple payment gateways in addition to wallet payments when enabled.',
        ),
      ),
    ];

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.10),
                theme.scaffoldBackgroundColor,
                theme.scaffoldBackgroundColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                AppTopBanner(
                  title: t('مركز المساعدة', 'Help center'),
                  subtitle: t(
                    'الأسئلة الشائعة، التواصل مع الدعم، الخصوصية، إدارة الموافقات، وشروط الاستخدام الأساسية.',
                    'FAQ, support contact, privacy, consent management, and core usage terms.',
                  ),
                  leadingIcon: Icons.arrow_back_rounded,
                  onLeadingTap: Get.back,
                  trailingIcon: Icons.support_agent_rounded,
                  onTrailingTap: () =>
                      Get.to(() => SupportHome(userId: userId)),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppTopBannerMetric(
                          value: '24/7',
                          label: t('الدعم', 'Support'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTopBannerMetric(
                          value: 'FAQ',
                          label: t('إجابات سريعة', 'Quick answers'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _ActionTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: t('الدردشة المباشرة', 'Live chat'),
                  subtitle: t(
                    'تواصل مع فريق الدعم من داخل التطبيق.',
                    'Talk to the support team inside the app.',
                  ),
                  onTap: () => Get.to(() => SupportHome(userId: userId)),
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.email_outlined,
                  title: t('الدعم عبر البريد', 'Email support'),
                  subtitle: AppCurrency.supportEmail.isEmpty
                      ? 'support@savir.site'
                      : AppCurrency.supportEmail,
                  onTap: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: AppCurrency.supportEmail.isEmpty
                            ? 'support@savir.site'
                            : AppCurrency.supportEmail,
                      ),
                    );
                    Get.snackbar(
                      t('تم النسخ', 'Copied'),
                      t('تم نسخ بريد الدعم.', 'Support email copied.'),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.call_outlined,
                  title: t('الاتصال بالدعم', 'Call support'),
                  subtitle: AppCurrency.supportPhone.isEmpty
                      ? '+20 1112608734'
                      : AppCurrency.supportPhone,
                  onTap: () {
                    final phone = AppCurrency.supportPhone.isEmpty
                        ? '+201112608734'
                        : AppCurrency.supportPhone;
                    _launchUri(Uri.parse('tel:${phone.replaceAll(' ', '')}'));
                  },
                ),
                const SizedBox(height: 22),
                _SectionTitle(title: t('الأسئلة الشائعة', 'FAQ')),
                const SizedBox(height: 12),
                ...faqItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FaqCard(question: item.$1, answer: item.$2),
                  ),
                ),
                const SizedBox(height: 10),
                _SectionTitle(title: t('سياسة الخصوصية', 'Privacy policy')),
                const SizedBox(height: 12),
                _PolicyCard(
                  lines: [
                    t(
                      'نستخدم بيانات الحساب والطلبات فقط لتشغيل الخدمة وتحسين التوصيل.',
                      'We use account and order data only to operate the service and improve delivery.',
                    ),
                    t(
                      'لا تتم مشاركة البيانات الحساسة إلا مع المزودين الضروريين مثل الدفع والإشعارات.',
                      'Sensitive data is shared only with required providers such as payments and notifications.',
                    ),
                    t(
                      'يمكنك طلب مراجعة بيانات حسابك من خلال الدعم.',
                      'You can request a review of your account data through support.',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title:
                      t('فتح سياسة الخصوصية كاملة', 'Open full privacy policy'),
                  subtitle: t(
                    'اقرأ كيف نجمع بياناتك ونحميها.',
                    'Read how we collect and protect your data.',
                  ),
                  onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  title:
                      t('سياسة إدارة الموافقات', 'Consent management policy'),
                ),
                const SizedBox(height: 12),
                _PolicyCard(
                  lines: [
                    t(
                      'طلبات الموافقة واضحة ومنفصلة ويسهل رفضها.',
                      'Consent requests are clear, separate, and easy to reject.',
                    ),
                    t(
                      'يمكنك سحب أو تغيير الموافقة لاحقًا من الإعدادات أو أدوات الموافقة.',
                      'You can withdraw or change consent later from settings or consent tools.',
                    ),
                    t(
                      'قد تتطلب الكوكيز غير الضرورية والتسويق وميزات الموقع الاختيارية موافقة.',
                      'Non-essential cookies, marketing, and optional location features may require consent.',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.fact_check_outlined,
                  title: t(
                    'فتح سياسة الموافقات كاملة',
                    'Open full consent policy',
                  ),
                  subtitle: t(
                    'اقرأ كيف نطلب الموافقات ونخزنها ونسحبها.',
                    'Read how we request, store, and withdraw consents.',
                  ),
                  onTap: () => Get.toNamed(AppRoutes.consentManagementPolicy),
                ),
                const SizedBox(height: 18),
                _SectionTitle(title: t('شروط الاستخدام', 'Terms of use')),
                const SizedBox(height: 12),
                _PolicyCard(
                  lines: [
                    t(
                      'يجب أن تستخدم الطلبات وبيانات الحساب معلومات صحيحة وقابلة للتواصل.',
                      'Orders and account details must use valid, contactable information.',
                    ),
                    t(
                      'قد يتم تقييد الحسابات عند إساءة الاستخدام أو الاحتيال أو تكرار المخالفات.',
                      'Accounts may be restricted for abuse, fraud, or repeated misuse.',
                    ),
                    t(
                      'أوقات التوصيل تقديرية وتعتمد على ظروف المطعم والسائق.',
                      'Delivery timings are estimates and depend on restaurant and driver conditions.',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.description_outlined,
                  title: t('فتح الشروط كاملة', 'Open full terms'),
                  subtitle: t(
                    'اقرأ الشروط القانونية الكاملة في صفحة مخصصة.',
                    'Read the complete legal terms in a dedicated page.',
                  ),
                  onTap: () => Get.toNamed(AppRoutes.termsOfUse),
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  title: t(
                    'المستندات القانونية الأخرى',
                    'More legal documents',
                  ),
                ),
                const SizedBox(height: 12),
                ...legalDocs.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ActionTile(
                      icon: item.icon,
                      title: item.title,
                      subtitle: item.subtitle,
                      onTap: () => Get.toNamed(item.route),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalHelpItem {
  const _LegalHelpItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  const _FaqCard({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        title: Text(
          question,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(answer, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines
              .map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 7),
                        child: Icon(Icons.circle, size: 6),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(line, style: theme.textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

Future<void> _launchUri(Uri uri) async {
  await launchUrl(uri);
}
