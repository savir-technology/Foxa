import 'package:delvery/controllers/shift_controller.dart';
import 'package:delvery/core/localization/driver_text.dart';
import 'package:delvery/core/services/driver_session_service.dart';
import 'package:delvery/widgets/driver_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ShiftScreen extends GetView<ShiftController> {
  const ShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionService = Get.find<DriverSessionService>();
    return Scaffold(
      appBar: AppBar(
        title: Text(tx('بدء المناوبة')),
        actions: [
          IconButton(
            onPressed: controller.endShift,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final isShiftActive = sessionService.isShiftActive.value;
          final hasInternet = sessionService.hasInternet.value;
          final gpsEnabled = sessionService.gpsEnabled.value;
          final isLoggedIn = sessionService.isLoggedIn.value;
          final isLoading = controller.startLoading.value;
          final _ = sessionService.dashboardTick.value;
          final canStartShift = sessionService.isWithinOfficialWorkingHours();
          final officialHoursText = sessionService
              .officialWorkingHoursTodayText();
          final officialHoursWeeklyText = sessionService
              .officialWorkingHoursWeeklyText();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _StatusPanel(
                isShiftActive: isShiftActive,
                canStartShift: canStartShift,
              ),
              const SizedBox(height: 18),
              _CheckRow(
                title: tx('اتصال الإنترنت'),
                value: hasInternet,
                icon: Icons.wifi_rounded,
                trueLabel: tx('متصل'),
                falseLabel: tx('غير متصل'),
              ),
              const SizedBox(height: 12),
              _CheckRow(
                title: 'GPS',
                value: gpsEnabled,
                icon: Icons.gps_fixed_rounded,
                trueLabel: tx('مفعّل'),
                falseLabel: tx('متوقف'),
              ),
              const SizedBox(height: 12),
              _CheckRow(
                title: tx('الحساب'),
                value: isLoggedIn,
                icon: Icons.badge_rounded,
                trueLabel: tx('مسجل الدخول'),
                falseLabel: tx('مطلوب تسجيل الدخول'),
              ),
              const SizedBox(height: 22),
              Text(
                controller.statusMessage.value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              _WorkingHoursCard(
                canStartShift: canStartShift,
                officialHoursText: officialHoursText,
                weeklySummaryText: officialHoursWeeklyText,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: isLoading || !canStartShift
                    ? null
                    : controller.startShift,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(
                  canStartShift ? tx('بدء المناوبة') : tx('خارج وقت العمل'),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                canStartShift
                    ? tx(
                        'عند بدء المناوبة يبدأ التتبع الجغرافي ومراقبة الطلبات تلقائياً.',
                      )
                    : tx(
                        'لن تتمكن من بدء المناوبة إلا خلال أوقات العمل الرسمية المحددة من داش بورد المستر.',
                      ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.isShiftActive,
    required this.canStartShift,
  });

  final bool isShiftActive;
  final bool canStartShift;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isShiftActive
              ? [const Color(0xFF174A2F), const Color(0xFF0E1C14)]
              : canStartShift
              ? [const Color(0xFF2B1E1E), const Color(0xFF181213)]
              : [const Color(0xFF4A1D1D), const Color(0xFF231010)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isShiftActive
                ? tx('أنت متاح')
                : canStartShift
                ? tx('أنت غير متاح')
                : tx('لا يمكن التفعيل الآن'),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            isShiftActive
                ? tx('يمكن للإدارة إرسال الطلبات إليك الآن.')
                : canStartShift
                ? tx('ابدأ المناوبة للانضمام إلى الأسطول.')
                : tx(
                    'أنت خارج أوقات العمل الرسمية المحددة من داش بورد المستر.',
                  ),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _WorkingHoursCard extends StatelessWidget {
  const _WorkingHoursCard({
    required this.canStartShift,
    required this.officialHoursText,
    required this.weeklySummaryText,
  });

  final bool canStartShift;
  final String officialHoursText;
  final String weeklySummaryText;

  @override
  Widget build(BuildContext context) {
    final background = canStartShift
        ? const Color(0xFFFFF8F3)
        : const Color(0xFFFFF3F3);
    final borderColor = canStartShift
        ? const Color(0xFFF0D8CA)
        : const Color(0xFFF2D5D5);
    final iconColor = canStartShift
        ? DriverUi.primary
        : const Color(0xFFC24141);
    final titleColor = canStartShift
        ? DriverUi.primary
        : const Color(0xFF8B1F1F);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: Icon(Icons.schedule_rounded, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx('أوقات العمل الرسمية'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  officialHoursText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF555555),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  weeklySummaryText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF777777),
                    height: 1.2,
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

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.title,
    required this.value,
    required this.icon,
    required this.trueLabel,
    required this.falseLabel,
  });

  final String title;
  final bool value;
  final IconData icon;
  final String trueLabel;
  final String falseLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  value ? trueLabel : falseLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Icon(
            value ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: value
                ? const Color(0xFF59D98E)
                : Theme.of(context).colorScheme.secondary,
          ),
        ],
      ),
    );
  }
}
