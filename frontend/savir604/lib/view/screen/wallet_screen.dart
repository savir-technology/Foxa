import 'package:flutter/material.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:get/get.dart';
import 'package:tks/controler/wallet/wallet_controller.dart';
import 'package:tks/core/class/handlingdataview.dart';
import 'package:tks/view/widget/common/app_top_banner.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<WalletController>(
      init: WalletController(),
      builder: (controller) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final isArabic = Get.locale?.languageCode == 'ar';
        String t(String ar, String en) => isArabic ? ar : en;
        final balanceLabel =
            '${controller.walletBalance.toStringAsFixed(2)} ${AppCurrency.code}';

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.10),
                    theme.scaffoldBackgroundColor,
                    theme.scaffoldBackgroundColor,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: HandlingDataView(
                  statusRequest: controller.statusRequest,
                  widget: RefreshIndicator(
                    onRefresh: controller.fetchWalletSummary,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      children: [
                        AppTopBanner(
                          title: t('رصيد الاسترداد', 'Refund credit'),
                          subtitle: t(
                            'الأموال المستردة من الطلبات الملغاة تتحول إلى نقاط يمكنك الدفع بها في الطلبات القادمة.',
                            'Refunded cancelled orders are returned as points that you can use for future payments.',
                          ),
                          leadingIcon: Icons.arrow_back_rounded,
                          onLeadingTap: Get.back,
                          trailingIcon: Icons.account_balance_wallet_outlined,
                          child: Row(
                            children: [
                              Expanded(
                                child: AppTopBannerMetric(
                                  value: balanceLabel,
                                  label: t('رصيد قابل للدفع', 'Usable credit'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: AppTopBannerMetric(
                                  value: controller.referralPoints.toString(),
                                  label: t('نقاط الاسترداد', 'Refund points'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _WalletCard(
                          title:
                              t('رصيد مسترد متاح', 'Available refund credit'),
                          value: balanceLabel,
                          subtitle: t(
                            'هذا الرصيد يضيفه الماستر عند إلغاء طلب مدفوع، ويمكن استخدامه مباشرة أثناء الدفع.',
                            'This credit is added by the master admin after a paid order is cancelled, and can be used directly at checkout.',
                          ),
                          icon: Icons.savings_outlined,
                        ),
                        const SizedBox(height: 14),
                        _WalletCard(
                          title: t(
                            'نقاط يمكن استخدامها لاحقًا',
                            'Points for future payments',
                          ),
                          value: controller.referralPoints.toString(),
                          subtitle: t(
                            'كل نقطة استرداد تمثل قيمة محفوظة لك، وتظهر ضمن خيارات الدفع عندما يكون لديك رصيد كاف.',
                            'Refund points represent saved value and appear in payment options when your balance is enough.',
                          ),
                          icon: Icons.workspace_premium_outlined,
                        ),
                        const SizedBox(height: 14),
                        _WalletInfoCard(
                          icon: Icons.history_rounded,
                          title: t('سجل الاسترداد', 'Refund activity'),
                          subtitle: t(
                            'ستظهر هنا عمليات تحويل مبالغ الطلبات الملغاة إلى نقاط بواسطة الإدارة.',
                            'Admin refund conversions from cancelled paid orders will appear here.',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _RefundRulesCard(
                          title: t('كيف يعمل الاسترداد؟', 'How refunds work'),
                          steps: [
                            t(
                              'إذا دفع العميل قيمة الطلب ثم تم إلغاء الطلب، يقوم الماستر بتحويل المبلغ إلى نقاط.',
                              'If a customer paid for an order and it gets cancelled, the master admin converts the amount into points.',
                            ),
                            t(
                              'يمكن استخدام النقاط لاحقًا كرصيد دفع داخل صفحة إتمام الطلب.',
                              'The points can later be used as payment credit during checkout.',
                            ),
                            t(
                              'لا يمكن شحن هذه المحفظة يدويًا من العميل، فهي مخصصة للاسترداد فقط.',
                              'Customers cannot manually top up this wallet; it is dedicated to refunds only.',
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t(
                                    'رصيد الاسترداد آمن ومحفوظ لحسابك، ويظهر تلقائيًا عند توفره للدفع.',
                                    'Refund credit is safely stored on your account and appears automatically when available for payment.',
                                  ),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: colors.primary),
                ),
                const SizedBox(width: 12),
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
              ],
            ),
            const SizedBox(height: 18),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletInfoCard extends StatelessWidget {
  const _WalletInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RefundRulesCard extends StatelessWidget {
  const _RefundRulesCard({
    required this.title,
    required this.steps,
  });

  final String title;
  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            for (var index = 0; index < steps.length; index++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      steps[index],
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
                ],
              ),
              if (index != steps.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
