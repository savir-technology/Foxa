import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.embedInShell = false});

  final bool embedInShell;

  @override
  Widget build(BuildContext context) {
    final sessionService = Get.find<DriverSessionService>();

    return Scaffold(
      appBar: null,
      body: SafeArea(
        top: true,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            DriverHeaderBar(
              onLeadingTap: () => Get.toNamed(AppRoutes.notifications),
              onTrailingTap: () => Get.toNamed(AppRoutes.help),
            ),
            const SizedBox(height: 18),
            DriverPageHeader(
              title: tx('الملف الشخصي'),
              subtitle: tx('عرض وإدارة معلومات حسابك'),
            ),
            const SizedBox(height: 22),
            _ProfileSummaryCard(sessionService: sessionService),
            const SizedBox(height: 16),
            _MenuCard(
              sessionService: sessionService,
              embedInShell: embedInShell,
            ),
            const SizedBox(height: 16),
            const _EmergencyCard(),
          ],
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  const _ProfileSummaryCard({required this.sessionService});

  final DriverSessionService sessionService;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = sessionService.profile.value;
      final photoUrl = sessionService.api.resolveUrl(profile.photoUrl);
      final hasPhoto = photoUrl.isNotEmpty;

      return DriverCard(
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: DriverUi.primarySoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: DriverUi.line, width: 1.2),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: hasPhoto
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.person_rounded,
                                    size: 44,
                                    color: DriverUi.primary.withValues(
                                      alpha: 0.75,
                                    ),
                                  ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              size: 44,
                              color: DriverUi.primary.withValues(alpha: 0.75),
                            ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2FB344),
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.name.isEmpty ? tx('السائق') : profile.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: DriverUi.text,
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: DriverUi.primarySoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              profile.profileCompleted
                                  ? tx('مفعّل')
                                  : tx('غير مكتمل'),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: DriverUi.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        tx('سائق توصيل'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: DriverUi.mutedText,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        profile.vehicleType.isEmpty
                            ? tx('المركبة غير محددة')
                            : profile.vehicleType,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DriverUi.mutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _CompactInfo(
                    icon: Icons.phone_outlined,
                    label: tx('رقم الهاتف'),
                    value: profile.phone.isEmpty ? '- - -' : profile.phone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CompactInfo(
                    icon: Icons.email_outlined,
                    label: tx('البريد الإلكتروني'),
                    value: profile.email.isEmpty ? '- - -' : profile.email,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _CompactInfo extends StatelessWidget {
  const _CompactInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DriverUi.surfaceWarm,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DriverUi.line),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: DriverUi.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: DriverUi.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DriverUi.mutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DriverUi.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.sessionService, required this.embedInShell});

  final DriverSessionService sessionService;
  final bool embedInShell;

  @override
  Widget build(BuildContext context) {
    return DriverCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.person_outline_rounded,
            title: tx('المعلومات الشخصية'),
            subtitle: tx('عرض وتعديل معلوماتك الشخصية'),
            onTap: () => Get.toNamed(AppRoutes.profileSetup),
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.receipt_long_outlined,
            title: tx('المستندات'),
            subtitle: tx('عرض وإدارة مستنداتك'),
            onTap: () => Get.toNamed(AppRoutes.history),
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.two_wheeler_outlined,
            title: tx('المركبة'),
            subtitle: tx('عرض معلومات مركبتك'),
            onTap: () => Get.toNamed(AppRoutes.profileSetup),
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.account_balance_wallet_outlined,
            title: tx('المحفظة والأرباح'),
            subtitle: tx('عرض أرباحك وعمليات السحب'),
            onTap: () => Get.toNamed(AppRoutes.history),
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.star_border_rounded,
            title: tx('تقييماتي'),
            subtitle: tx('عرض تقييمات العملاء'),
            onTap: () => Get.toNamed(AppRoutes.history),
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.settings_outlined,
            title: tx('الإعدادات'),
            subtitle: tx('إعدادات التطبيق والحساب'),
            onTap: () => Get.toNamed(AppRoutes.settings),
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.shield_outlined,
            title: tx('الأمان'),
            subtitle: tx('تغيير كلمة المرور وإعدادات الأمان'),
            onTap: () => Get.toNamed(AppRoutes.settings),
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.language_rounded,
            title: tx('اللغة'),
            subtitle: tx('تغيير لغة التطبيق'),
            onTap: () => Get.toNamed(AppRoutes.settings),
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.notifications_none_rounded,
            title: tx('الإشعارات'),
            subtitle: tx('إدارة الإشعارات والتنبيهات'),
            onTap: () => Get.toNamed(AppRoutes.notifications),
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.help_outline_rounded,
            title: tx('مركز المساعدة'),
            subtitle: tx('إجابات على أكثر الأسئلة شيوعًا'),
            onTap: () => Get.toNamed(AppRoutes.help),
          ),
          const Divider(height: 1),
          _MenuTile(
            icon: Icons.logout_rounded,
            title: tx('تسجيل الخروج'),
            subtitle: tx('خروج من حسابك'),
            danger: true,
            onTap: () => sessionService.signOut().then((_) {
              Get.offAllNamed(AppRoutes.login);
            }),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final iconColor = danger ? DriverUi.danger : DriverUi.primary;
    final badgeColor = danger ? DriverUi.dangerSoft : DriverUi.primarySoft;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: danger ? DriverUi.danger : DriverUi.text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DriverUi.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: DriverUi.mutedText.withValues(alpha: 0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard();

  @override
  Widget build(BuildContext context) {
    return DriverCard(
      color: DriverUi.dangerSoft,
      borderColor: const Color(0xFFF0C6C6),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.emergency_outlined,
              color: DriverUi.danger,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx('في حالة الطوارئ'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: DriverUi.danger,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tx(
                    'إذا كنت في خطر أو تحتاج مساعدة فورية، يرجى الاتصال بالطوارئ المحلية.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DriverUi.text,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
