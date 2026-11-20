import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/settings/settings_controller.dart';
import 'package:tks/controler/them/theme_controller.dart';
import 'package:tks/core/constant/imsgesassets.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/localization/changelocal.dart';
import 'package:tks/core/services/background_music_service.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/linkapi/linkapi.dart';
import 'package:tks/view/screen/profile_page.dart';
import 'package:tks/view/widget/common/app_top_banner.dart';
import 'package:tks/view/widget/common/language_selector_sheet.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  late final ThemeController themeController;
  late final LocaleController localeController;
  late final MyServices myServices;
  late final BackgroundMusicService musicService;
  bool notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    Get.put(SettingsController());
    themeController = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : Get.put(ThemeController(Get.find()));
    localeController = Get.find<LocaleController>();
    myServices = Get.find<MyServices>();
    musicService = Get.find<BackgroundMusicService>();
    notificationsEnabled =
        myServices.sharedPreferences.getBool('notifications_enabled') ?? true;
  }

  Future<void> _setNotifications(bool value) async {
    await myServices.sharedPreferences.setBool('notifications_enabled', value);
    if (!mounted) return;
    setState(() => notificationsEnabled = value);
  }

  String _currentLanguageLabel() {
    final code = localeController.language.languageCode;
    return code == 'ar'
        ? 'Current language: Arabic'
        : 'Current language: English';
  }

  Future<void> _confirmDeleteAccount(SettingsController controller) async {
    final shouldDelete = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Delete account'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action will permanently delete your account and sign you out.'
                  .tr,
            ),
            const SizedBox(height: 8),
            Text(
              'This cannot be undone.'.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(alpha: 0.72),
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel'.tr),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: Text('Delete'.tr),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await controller.deleteAccount();
      } catch (error) {
        if (!mounted) return;
        Get.snackbar(
          'Delete account'.tr,
          error.toString().replaceFirst('Exception: ', '').tr,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SettingsController>(
      builder: (controller) {
        final theme = Theme.of(context);
        final isArabic = (Get.locale?.languageCode ?? 'ar') == 'ar';
        String t(String arabic, String english) => isArabic ? arabic : english;
        final username = myServices.sharedPreferences.getString('username') ??
            'profile_default_user'.tr;
        final legalDocs = [
          (
            Icons.account_balance_wallet_outlined,
            t('سياسة المدفوعات والمحفظة', 'Payments and wallet policy'),
            t(
              'تعرف على قواعد الدفع والمحفظة والاسترداد.',
              'Read the payment, wallet, and refund rules.',
            ),
            AppRoutes.paymentsAndWalletPolicy,
          ),
          (
            Icons.card_giftcard_rounded,
            t('سياسة الطلبات المقدمة للغير', 'Orders for others policy'),
            t(
              'راجع قواعد الطلب نيابة عن شخص آخر.',
              'Review how orders for another person are handled.',
            ),
            AppRoutes.ordersForOthersPolicy,
          ),
          (
            Icons.star_outline_rounded,
            t('سياسة التقييمات والمراجعات', 'Ratings and reviews policy'),
            t(
              'تعرف على قواعد التقييم والمراجعة.',
              'Read the rules for ratings and reviews.',
            ),
            AppRoutes.reviewsPolicy,
          ),
          (
            Icons.assignment_return_outlined,
            t(
              'سياسة الإلغاء والطلبات والاسترداد',
              'Cancellation and refund policy',
            ),
            t(
              'راجع متى يمكن الإلغاء أو الاسترداد.',
              'See when cancellation or refunds may apply.',
            ),
            AppRoutes.cancellationRefundPolicy,
          ),
          (
            Icons.block_outlined,
            t(
              'سياسة الاستخدام المحظور والسلوك المقبول',
              'Prohibited use policy',
            ),
            t(
              'تعرف على ما هو مسموح وما هو محظور.',
              'See what is allowed and what is prohibited.',
            ),
            AppRoutes.prohibitedUsePolicy,
          ),
          (
            Icons.notifications_active_outlined,
            t('سياسة الاتصالات والإشعارات', 'Communications policy'),
            t(
              'تعرف على إشعارات التطبيق ورسائل التشغيل.',
              'Review app notifications and operational messages.',
            ),
            AppRoutes.communicationsPolicy,
          ),
        ];

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.11),
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  AppTopBanner(
                    title: 'settings_title',
                    subtitle:
                        'Manage your account, language, privacy, and consent preferences.',
                    leadingIcon: Icons.arrow_back_rounded,
                    onLeadingTap: () {
                      if (Get.previousRoute.isNotEmpty) {
                        Get.back();
                      } else {
                        Get.offAllNamed(AppRoutes.homepage);
                      }
                    },
                    trailingIcon: Icons.person_outline_rounded,
                    onTrailingTap: () {
                      final userId =
                          myServices.sharedPreferences.getInt('id') ?? 0;
                      if (userId > 0) {
                        Get.to(() => ProfilePage(userId: userId));
                      }
                    },
                    child: Row(
                      children: [
                        _ProfileAvatar(imageUrl: _profileImageUrl(controller)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                username,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                myServices.sharedPreferences
                                        .getString('phone') ??
                                    '',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'Language preferences'),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.language_rounded,
                    title: 'Choose language',
                    subtitle: _currentLanguageLabel(),
                    onTap: () async {
                      await showLanguageSelectorSheet();
                      if (mounted) {
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  _SwitchCard(
                    title: 'dark_theme',
                    subtitle: 'switch_theme',
                    value: themeController.isDarkMode.value,
                    onChanged: (_) {
                      themeController.toggleTheme();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  _SwitchCard(
                    title: 'Ambient music',
                    subtitle: 'Turn in-app background music on or off.',
                    value: musicService.isEnabled.value,
                    onChanged: (value) async {
                      await musicService.toggle(value);
                      if (!mounted) return;
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  _SwitchCard(
                    title: 'notifications_title',
                    subtitle: 'Control app alerts and order notifications.',
                    value: notificationsEnabled,
                    onChanged: _setNotifications,
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'Account center'),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Wallet',
                    subtitle:
                        'Manage your balance, referral points, and saved value in one place.',
                    onTap: () => Get.toNamed(AppRoutes.wallet),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.local_offer_outlined,
                    title: 'special_offers',
                    subtitle: 'Seasonal deals and active promotions.',
                    onTap: () => Get.toNamed(AppRoutes.offers),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.location_on_outlined,
                    title: 'addresses',
                    subtitle: 'address_subtitle',
                    onTap: () => Get.toNamed(AppRoutes.addressview),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.archive_outlined,
                    title: 'orders_archive_title',
                    subtitle: 'orders_archive_subtitle',
                    onTap: () => Get.toNamed(AppRoutes.ordersarchive_page),
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'Help and policies'),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.support_agent_outlined,
                    title: 'support',
                    subtitle: 'FAQ, contact options, and policy summaries.',
                    onTap: () => Get.toNamed(AppRoutes.helpCenter),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy policy',
                    subtitle: 'Read how your data is handled and protected.',
                    onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.fact_check_outlined,
                    title: 'Consent management policy',
                    subtitle:
                        'Review how consent is requested, recorded, and withdrawn.',
                    onTap: () => Get.toNamed(
                      AppRoutes.consentManagementPolicy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.description_outlined,
                    title: 'Terms of use',
                    subtitle: 'Read the full legal terms and platform rules.',
                    onTap: () => Get.toNamed(AppRoutes.termsOfUse),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.info_outline_rounded,
                    title: 'about_app_title',
                    subtitle: 'about_app_subtitle',
                    onTap: () => Get.toNamed(AppRoutes.aboutus),
                  ),
                  const SizedBox(height: 18),
                  _SectionTitle(
                    title:
                        t('المستندات القانونية الأخرى', 'More legal documents'),
                  ),
                  const SizedBox(height: 12),
                  ...legalDocs.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ActionCard(
                        icon: item.$1,
                        title: item.$2,
                        subtitle: item.$3,
                        onTap: () => Get.toNamed(item.$4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const _SectionTitle(title: 'Delete account'),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: controller.isDeletingAccount
                        ? Icons.hourglass_bottom_rounded
                        : Icons.delete_outline_rounded,
                    title: 'Delete account',
                    subtitle:
                        'This action will permanently delete your account and sign you out.',
                    accentColor: Colors.redAccent,
                    onTap: controller.isDeletingAccount
                        ? null
                        : () => _confirmDeleteAccount(controller),
                    trailing: controller.isDeletingAccount
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.redAccent.withValues(alpha: 0.85),
                          ),
                  ),
                  const SizedBox(height: 12),
                  _LogoutCard(onLogout: controller.logout),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String? _profileImageUrl(SettingsController controller) {
    final dynamic remoteImage = controller.userData?['users_image'];
    final String storedImage =
        myServices.sharedPreferences.getString('users_image') ?? '';
    final imageName = ((remoteImage ?? storedImage)).toString().trim();
    return imageName.isEmpty
        ? null
        : AppLink.normalizeUrl(
            '${AppLink.server}/uploads/users/img/$imageName');
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final image = imageUrl == null
        ? Image.asset(AppImageAsset.avatar, fit: BoxFit.cover)
        : CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: Colors.white.withValues(alpha: 0.10),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, __, ___) =>
                Image.asset(AppImageAsset.avatar, fit: BoxFit.cover),
          );

    return CircleAvatar(
      radius: 34,
      backgroundColor: Colors.white,
      child: ClipOval(
        child: SizedBox.expand(child: image),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.tr,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        title: Text(title.tr),
        subtitle: Text(subtitle.tr),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = accentColor ?? colors.primary;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accent.withValues(alpha: onTap == null ? 0.12 : 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.75),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing ??
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: accent.withValues(alpha: 0.85),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () async {
        final result = await Get.dialog<bool>(
          AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Text('logout'.tr),
            content: Text('confirm_logout_message'.tr),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: Text('Cancel'.tr),
              ),
              ElevatedButton(
                onPressed: () => Get.back(result: true),
                child: Text('logout'.tr),
              ),
            ],
          ),
        );

        if (result == true) {
          onLogout();
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.black87),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'logout'.tr,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }
}
