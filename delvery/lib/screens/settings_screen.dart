import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/core/routes/app_routes.dart';
import 'package:delvery/controllers/settings_controller.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsScreen extends GetView<SettingsController> {
  const SettingsScreen({super.key, this.embedInShell = false});

  final bool embedInShell;

  @override
  Widget build(BuildContext context) {
    final sessionService = Get.find<DriverSessionService>();
    return Scaffold(
      appBar: null,
      backgroundColor: DriverUi.background,
      body: SafeArea(
        top: !embedInShell,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            DriverHeaderBar(
              onLeadingTap: () => Get.toNamed(AppRoutes.notifications),
              onTrailingTap: () => Get.toNamed(AppRoutes.help),
            ),
            const SizedBox(height: 18),
            DriverPageHeader(
              title: t('الإعدادات', 'Settings'),
              subtitle: t(
                'خصّص التطبيق حسب تفضيلاتك',
                'Customize the app to your preferences',
              ),
            ),
            const SizedBox(height: 22),
            _PreferencesCard(controller: controller),
            const SizedBox(height: 16),
            _SupportCard(sessionService: sessionService),
            const SizedBox(height: 16),
            _LogoutCard(onLogout: controller.signOut),
          ],
        ),
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return DriverCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _SettingTile(
            icon: Icons.person_outline_rounded,
            title: t('تفضيلات التطبيق', 'App preferences'),
            subtitle: t('تخصيص تجربة استخدام التطبيق', 'Adjust the app experience'),
            trailing: const SizedBox.shrink(),
            onTap: () {},
          ),
          const Divider(height: 1),
          Obx(
            () => _ToggleTile(
              icon: Icons.notifications_none_rounded,
              title: t('الإشعارات', 'Notifications'),
              subtitle: t(
                'إدارة الإشعارات والتنبيهات',
                'Control notifications and alerts',
              ),
              value: controller.notificationsEnabled.value,
              onChanged: controller.setNotificationsEnabled,
            ),
          ),
          const Divider(height: 1),
          Obx(
            () => _ToggleTile(
              icon: Icons.route_rounded,
              title: t('الموقع والخرائط', 'Location and maps'),
              subtitle: t(
                'إعدادات الموقع والخرائط',
                'Location and map settings',
              ),
              value: controller.locationSharingEnabled.value,
              onChanged: controller.setLocationSharingEnabled,
            ),
          ),
          const Divider(height: 1),
          Obx(
            () => _SettingTile(
              icon: Icons.language_rounded,
              title: t('اللغة', 'Language'),
              subtitle: controller.localeLabel.value,
              onTap: () => controller.toggleLocale(
                controller.sessionService.localeCode.value == 'ar'
                    ? 'en'
                    : 'ar',
              ),
            ),
          ),
          const Divider(height: 1),
          _SettingTile(
            icon: Icons.data_usage_rounded,
            title: t('توفير البيانات', 'Data saver'),
            subtitle: t(
              'تقليل استهلاك البيانات أثناء الاستخدام',
              'Reduce data usage while using the app',
            ),
            onTap: () => controller.setLocationSharingEnabled(
              !controller.locationSharingEnabled.value,
            ),
          ),
          const Divider(height: 1),
          Obx(
            () => _ToggleTile(
              icon: Icons.vibration_rounded,
              title: t('الاهتزاز', 'Vibration'),
              subtitle: t(
                'تشغيل أو إيقاف اهتزاز الجهاز',
                'Enable or disable device vibration',
              ),
              value: controller.vibrationEnabled.value,
              onChanged: controller.setVibrationEnabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing = const Icon(Icons.chevron_left_rounded),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: DriverUi.primarySoftAdaptive,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: DriverUi.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: DriverUi.textAdaptive,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: DriverUi.mutedTextAdaptive),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DriverUi.primarySoftAdaptive,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: DriverUi.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: DriverUi.textAdaptive,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: DriverUi.mutedTextAdaptive,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: DriverUi.primary,
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({required this.sessionService});

  final DriverSessionService sessionService;

  @override
  Widget build(BuildContext context) {
    return DriverCard(
      color: DriverUi.warningSoftAdaptive,
      borderColor: DriverUi.isDark
          ? const Color(0xFF4A3A1C)
          : const Color(0xFFF1E8CE),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: DriverUi.isDark
                  ? const Color(0xFF3A2E18)
                  : const Color(0xFFFFF4D9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: Color(0xFFC28E13)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('في حالة الطوارئ', 'In case of emergency'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: DriverUi.isDark
                        ? const Color(0xFFE6C56C)
                        : const Color(0xFF7B5A00),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t(
                    'إذا كنت في خطر أو تحتاج مساعدة فورية، تواصل مع الطوارئ المحلية.',
                    'If you are in danger or need immediate help, contact local emergency services.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: DriverUi.isDark
                        ? const Color(0xFFD0C39F)
                        : const Color(0xFF7A6A3E),
                    height: 1.45,
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

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onLogout});

  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          await onLogout();
        },
        icon: const Icon(Icons.logout_rounded),
        label: Text(t('تسجيل الخروج', 'Log out')),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          backgroundColor: DriverUi.dangerSoftAdaptive,
          foregroundColor: DriverUi.danger,
          side: BorderSide(color: Colors.red.shade100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}
