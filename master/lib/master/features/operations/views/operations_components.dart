// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

class _OperationsDataErrorState extends StatelessWidget {
  const _OperationsDataErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 36,
            color: Color(0xFFD92C2C),
          ),
          const SizedBox(height: 12),
          const Text(
            'تعذر تحميل بيانات لوحة العمليات',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E232A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6F7680),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}

class _MasterOperationsTopBar extends StatelessWidget {
  const _MasterOperationsTopBar({
    required this.displayName,
    required this.roleLabel,
    required this.notificationBadge,
    required this.messageBadge,
    required this.serverNow,
    required this.statusLabel,
    required this.platformTitle,
    required this.platformSubtitle,
    required this.onLogout,
    this.onNotificationsTap,
  });

  final String displayName;
  final String roleLabel;
  final int notificationBadge;
  final int messageBadge;
  final DateTime? serverNow;
  final String statusLabel;
  final String platformTitle;
  final String platformSubtitle;
  final Future<void> Function() onLogout;
  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          _MasterProfileChip(
            displayName: displayName,
            roleLabel: roleLabel,
            onLogout: onLogout,
          ),
          const SizedBox(width: 12),
          _MasterTopIconButton(
            icon: Icons.notifications_none_rounded,
            badge: notificationBadge > 0 ? notificationBadge.toString() : null,
            onTap: onNotificationsTap,
          ),
          const SizedBox(width: 8),
          _MasterTopIconButton(
            icon: Icons.chat_bubble_outline_rounded,
            badge: messageBadge > 0 ? messageBadge.toString() : null,
          ),
          const SizedBox(width: 8),
          const _MasterTopIconButton(icon: Icons.fullscreen_rounded),
          const SizedBox(width: 10),
          _MasterDateBlock(serverNow: serverNow),
          const SizedBox(width: 10),
          _MasterStatusPill(label: statusLabel),
          const Spacer(),
          _MasterPlatformTitle(
            title: platformTitle,
            subtitle: platformSubtitle,
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 36, color: const Color(0xFFF0F1F2)),
          const SizedBox(width: 10),
          const MasterBrandMark(width: 94, height: 42),
        ],
      ),
    );
  }
}

class _OperationsMainArea extends StatelessWidget {
  const _OperationsMainArea({
    required this.serverNow,
    required this.statCards,
    required this.mapMarkers,
    required this.performanceCards,
    required this.alertCards,
    required this.onRefresh,
  });

  final DateTime serverNow;
  final List<_OperationsStatCardData> statCards;
  final List<_OperationsMapMarkerData> mapMarkers;
  final List<_OperationsStatCardData> performanceCards;
  final List<_OperationsStatCardData> alertCards;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatArabicDateLabel(serverNow);

    var firstRowCards = <Widget>[];

    var secondRowCards = <Widget>[];

    var financeRowCards = <Widget>[];

    final databaseCards = statCards
        .map((card) => card.toWidget(height: 102, valueFontSize: 20))
        .toList();
    firstRowCards = databaseCards.take(7).toList();
    secondRowCards = databaseCards.skip(7).take(6).toList();
    financeRowCards = databaseCards.skip(13).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.end,
                    children: [
                      _OperationsFilterChip(
                        label: 'تحديث',
                        icon: Icons.refresh_rounded,
                        backgroundColor: Colors.white,
                        borderColor: const Color(0xFFE6EAE6),
                        iconColor: const Color(0xFF4E5660),
                        textColor: const Color(0xFF4E5660),
                        onTap: onRefresh,
                      ),
                      _OperationsPopupFilterChip(
                        label: 'جميع المناطق',
                        icon: Icons.keyboard_arrow_down_rounded,
                        value: 'all',
                        options: const {
                          'all': 'جميع المناطق',
                          'active': 'مناطق نشطة',
                          'pressure': 'مناطق ضغط',
                        },
                        onChanged: (_) => _showMasterSnack(
                          context,
                          'فلتر المناطق سيطبق مع بيانات المناطق القادمة من الخادم',
                        ),
                      ),
                      _OperationsFilterChip(
                        label: dateLabel,
                        icon: Icons.calendar_month_rounded,
                        backgroundColor: Colors.white,
                        borderColor: const Color(0xFFE6EAE6),
                        iconColor: const Color(0xFF4E5660),
                        textColor: const Color(0xFF4E5660),
                        trailingIcon: Icons.keyboard_arrow_down_rounded,
                      ),
                      _OperationsPopupFilterChip(
                        label: 'اليوم',
                        icon: Icons.today_rounded,
                        value: 'today',
                        options: const {
                          'today': 'اليوم',
                          'week': 'هذا الأسبوع',
                          'month': 'هذا الشهر',
                        },
                        onChanged: (_) => _showMasterSnack(
                          context,
                          'فلتر الفترة سيطبق مع Endpoint التحليلات التفصيلية',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.rtl,
                child: _OperationsStatSection(
                  wideColumns: 7,
                  mediumColumns: 4,
                  cardHeight: 95,
                  cards: firstRowCards,
                ),
              ),
              const SizedBox(height: 10),
              _OperationsStatSection(
                wideColumns: 6,
                mediumColumns: 3,
                cardHeight: 100,
                cards: secondRowCards,
              ),
              const SizedBox(height: 10),
              _OperationsStatSection(
                wideColumns: 5,
                mediumColumns: 3,
                cardHeight: 100,
                cards: financeRowCards,
              ),
              const SizedBox(height: 14),
              _OperationsPerformanceAndAlerts(
                performanceCards: performanceCards,
                alertCards: alertCards,
              ),
              const SizedBox(height: 14),
              _OperationsMapPanel(markers: mapMarkers),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationsFilterChip extends StatelessWidget {
  const _OperationsFilterChip({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
    required this.textColor,
    this.trailingIcon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;
  final Color textColor;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.8,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.0,
              ),
            ),
            if (trailingIcon != null) ...[
              const SizedBox(width: 4),
              Icon(trailingIcon, size: 16, color: iconColor),
            ],
          ],
        ),
      ),
    );
  }
}

class _OperationsPopupFilterChip extends StatelessWidget {
  const _OperationsPopupFilterChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String value;
  final Map<String, String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value != 'all';
    return PopupMenuButton<String>(
      tooltip: label,
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => options.entries
          .map(
            (entry) => PopupMenuItem<String>(
              value: entry.key,
              child: Text(entry.value, textAlign: TextAlign.right),
            ),
          )
          .toList(),
      child: _OperationsFilterChip(
        label: label,
        icon: icon,
        backgroundColor: selected ? const Color(0xFFF1F8F4) : Colors.white,
        borderColor: selected
            ? const Color(0xFFD7EBDD)
            : const Color(0xFFE6EAE6),
        iconColor: selected ? const Color(0xFF1A8B4A) : const Color(0xFF4E5660),
        textColor: selected ? const Color(0xFF1A8B4A) : const Color(0xFF4E5660),
        trailingIcon: Icons.keyboard_arrow_down_rounded,
      ),
    );
  }
}

class _OperationsStatSection extends StatelessWidget {
  const _OperationsStatSection({
    required this.cards,
    required this.wideColumns,
    required this.mediumColumns,
    required this.cardHeight,
  });

  final List<Widget> cards;
  final int wideColumns;
  final int mediumColumns;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1240
            ? wideColumns
            : constraints.maxWidth >= 900
            ? mediumColumns
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        final spacing = 8.0;
        final itemWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: SizedBox(height: cardHeight, child: card),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _OperationsStatCard extends StatelessWidget {
  const _OperationsStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
    required this.background,
    this.height = 102,
    this.detailLine,
    this.trendLabel,
    this.trendCaption,
    this.trendPositive = true,
    this.showTrendIcon = true,
    this.valueFontSize = 20.0,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;
  final Color background;
  final double height;
  final String? detailLine;
  final String? trendLabel;
  final String? trendCaption;
  final bool trendPositive;
  final bool showTrendIcon;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    final trendColor = trendPositive ? _kPrimaryGreen : const Color(0xFFD92C2C);
    return Container(
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E232A),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: TextStyle(
                          fontSize: valueFontSize,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E232A),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (detailLine != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detailLine!,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9.8,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6F7680),
                      height: 1.0,
                    ),
                  ),
                ],
                if (trendLabel != null) ...[
                  const SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.rtl,
                    children: [
                      if (showTrendIcon)
                        Icon(
                          trendPositive
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 11,
                          color: trendColor,
                        ),
                      if (showTrendIcon) const SizedBox(width: 4),
                      Text(
                        trendLabel!,
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w700,
                          color: trendColor,
                          height: 1.0,
                        ),
                      ),
                      if (trendCaption != null) ...[
                        const SizedBox(width: 5),
                        Text(
                          trendCaption!,
                          style: const TextStyle(
                            fontSize: 9.4,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7A8088),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationsSectionHeader extends StatelessWidget {
  const _OperationsSectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E232A),
            height: 1.0,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 11.2,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6F7680),
              height: 1.0,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _OperationsPerformanceAndAlerts extends StatelessWidget {
  const _OperationsPerformanceAndAlerts({
    required this.performanceCards,
    required this.alertCards,
  });

  final List<_OperationsStatCardData> performanceCards;
  final List<_OperationsStatCardData> alertCards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 980) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _OperationsPerformancePanel(cards: performanceCards),
              ),
              const SizedBox(width: 12),
              Expanded(child: _OperationsAlertPanel(cards: alertCards)),
            ],
          );
        }

        return Column(
          children: [
            _OperationsPerformancePanel(cards: performanceCards),
            const SizedBox(height: 12),
            _OperationsAlertPanel(cards: alertCards),
          ],
        );
      },
    );
  }
}

class _OperationsPerformancePanel extends StatelessWidget {
  const _OperationsPerformancePanel({required this.cards});

  final List<_OperationsStatCardData> cards;

  @override
  Widget build(BuildContext context) {
    final cardWidgets = cards
        .map((card) => card.toWidget(height: 114, valueFontSize: 21))
        .toList();
    /*
    final cards = <Widget>[
      const _OperationsStatCard(
        title: 'متوسط وقت قبول الطلب',
        value: '2:15',
        icon: Icons.access_time_rounded,
        accent: Color(0xFF1E7D3F),
        background: Color(0xFFEAF5ED),
        detailLine: 'دقيقة',
        trendLabel: '8%',
        trendCaption: 'عن أمس',
        trendPositive: true,
        valueFontSize: 21,
        height: 114,
      ),
      const _OperationsStatCard(
        title: 'متوسط وقت التحضير',
        value: '18:40',
        icon: Icons.timer_outlined,
        accent: Color(0xFFD92C2C),
        background: Color(0xFFFDEEEF),
        detailLine: 'دقيقة',
        trendLabel: '5%',
        trendCaption: 'عن أمس',
        trendPositive: false,
        valueFontSize: 21,
        height: 114,
      ),
      const _OperationsStatCard(
        title: 'متوسط وقت التوصيل',
        value: '32:25',
        icon: Icons.av_timer_rounded,
        accent: Color(0xFF7C3AED),
        background: Color(0xFFF1ECFF),
        detailLine: 'دقيقة',
        trendLabel: '7%',
        trendCaption: 'عن أمس',
        trendPositive: false,
        valueFontSize: 21,
        height: 114,
      ),
    ];
    */

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _OperationsSectionHeader(
            title: 'مؤشرات الأداء',
            subtitle: 'معدلات تشغيلية مختصرة',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900 ? 3 : 1;
              final spacing = 10.0;
              final itemWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - (spacing * (columns - 1))) /
                        columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: cardWidgets
                    .map((card) => SizedBox(width: itemWidth, child: card))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showOperationsStatCardsSheet(
                context,
                title: 'جميع مؤشرات الأداء',
                cards: cards,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                side: const BorderSide(color: Color(0xFFE5E8E5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'عرض جميع مؤشرات الأداء',
                style: TextStyle(
                  fontSize: 12.2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4E5660),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationsAlertPanel extends StatelessWidget {
  const _OperationsAlertPanel({required this.cards});

  final List<_OperationsStatCardData> cards;

  @override
  Widget build(BuildContext context) {
    final cardWidgets = cards
        .map(
          (card) => _OperationsAlertTile(
            title: card.title,
            count: card.value,
            icon: card.icon,
            accent: card.accent,
            background: card.background,
            subtitle: card.detailLine,
          ),
        )
        .toList();
    /*
    final cards = <Widget>[
      const _OperationsAlertTile(
        title: 'طلبات متأخرة',
        count: '8',
        icon: Icons.schedule_rounded,
        accent: Color(0xFFD92C2C),
        background: Color(0xFFFDEEEF),
        subtitle: 'عرض التفاصيل',
      ),
      const _OperationsAlertTile(
        title: 'مطاعم متأخرة',
        count: '3',
        icon: Icons.storefront_outlined,
        accent: Color(0xFFF59E0B),
        background: Color(0xFFFFF4E4),
        subtitle: 'عرض التفاصيل',
      ),
      const _OperationsAlertTile(
        title: 'سائقون متأخرون',
        count: '5',
        icon: Icons.drive_eta_rounded,
        accent: Color(0xFFD92C2C),
        background: Color(0xFFFDEEEF),
        subtitle: 'عرض التفاصيل',
      ),
      const _OperationsAlertTile(
        title: 'شكاوى جديدة',
        count: '4',
        icon: Icons.report_problem_outlined,
        accent: Color(0xFF7C3AED),
        background: Color(0xFFF1ECFF),
        subtitle: 'عرض التفاصيل',
      ),
      const _OperationsAlertTile(
        title: 'رسائل دعم جديدة',
        count: '2',
        icon: Icons.headset_mic_outlined,
        accent: Color(0xFF2563EB),
        background: Color(0xFFEAF1FF),
        subtitle: 'عرض التفاصيل',
      ),
      const _OperationsAlertTile(
        title: 'تنبيهات سلبية',
        count: '6',
        icon: Icons.star_border_rounded,
        accent: Color(0xFFD92C2C),
        background: Color(0xFFFDEEEF),
        subtitle: 'عرض التفاصيل',
      ),
    ];
    */

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _OperationsSectionHeader(
            title: 'التنبيهات المهمة',
            subtitle: 'عرض سريع للحالات التي تحتاج متابعة',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 700 ? 2 : 1;
              final spacing = 10.0;
              final itemWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: cardWidgets
                    .map((card) => SizedBox(width: itemWidth, child: card))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showOperationsStatCardsSheet(
                context,
                title: 'جميع التنبيهات',
                cards: cards,
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                side: const BorderSide(color: Color(0xFFE5E8E5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'عرض جميع التنبيهات',
                style: TextStyle(
                  fontSize: 12.2,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4E5660),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OperationsAlertTile extends StatelessWidget {
  const _OperationsAlertTile({
    required this.title,
    required this.count,
    required this.icon,
    required this.accent,
    required this.background,
    required this.subtitle,
  });

  final String title;
  final String count;
  final IconData icon;
  final Color accent;
  final Color background;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E232A),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.6,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7A8088),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperationsLivePanel extends StatelessWidget {
  const _OperationsLivePanel({required this.items});

  final List<_OperationsLiveItemData> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                const Text(
                  'النشاط المباشر',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E232A),
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5ED),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFD7EBDD)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 6, color: Color(0xFF1A8B4A)),
                      SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A8B4A),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) =>
                    _OperationsLiveItem(item: items[index]),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showOperationsLiveItemsSheet(
                  context,
                  title: 'كل النشاط المباشر',
                  items: items,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  side: const BorderSide(color: Color(0xFFE5E8E5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.list_alt_rounded, size: 18),
                label: const Text(
                  'عرض كل النشاط',
                  style: TextStyle(fontSize: 12.2, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperationsLiveItem extends StatelessWidget {
  const _OperationsLiveItem({required this.item});

  final _OperationsLiveItemData item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: item.background,
              shape: BoxShape.circle,
              border: Border.all(color: item.border),
            ),
            child: Icon(item.icon, size: 17, color: item.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.title,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.6,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E232A),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.7,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6F7680),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.timeLabel,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.2,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8A919A),
                    height: 1.0,
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

class _OperationsNavigationSidebar extends StatelessWidget {
  const _OperationsNavigationSidebar({
    required this.activeSubSection,
    required this.onHomeTap,
    required this.onSubSectionTap,
    required this.onMenuTap,
  });

  final String activeSubSection;
  final VoidCallback onHomeTap;
  final void Function(String sectionKey) onSubSectionTap;
  final ValueChanged<_OperationsSidebarTileData> onMenuTap;

  @override
  Widget build(BuildContext context) {
    final menuItems = <_OperationsSidebarTileData>[
      const _OperationsSidebarTileData(
        label: 'إدارة الطلبات',
        icon: Icons.receipt_long_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'التوصيل والوجستيات',
        icon: Icons.delivery_dining_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'إدارة المطاعم',
        icon: Icons.storefront_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'العملاء',
        icon: Icons.people_alt_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'الإدارة المالية',
        icon: Icons.account_balance_wallet_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'التسويق والنمو',
        icon: Icons.campaign_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'مركز التواصل',
        icon: Icons.notifications_active_outlined,
      ),
      // 'الجودة وخدمة العملاء' removed per user request
      const _OperationsSidebarTileData(
        label: 'التقارير والتحليلات',
        icon: Icons.query_stats_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'إعدادات المنصة',
        icon: Icons.settings_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'الإدارة والصلاحيات',
        icon: Icons.admin_panel_settings_outlined,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _OperationsSidebarMainItem(
              label: 'الرئيسية',
              icon: Icons.home_rounded,
              selected: false,
              onTap: onHomeTap,
            ),
            const SizedBox(height: 10),
            _OperationsSidebarMainItem(
              label: 'لوحة العمليات',
              icon: Icons.grid_view_rounded,
              selected: true,
              onTap: () => onSubSectionTap('overview'),
            ),
            const SizedBox(height: 10),
            _OperationsSubMenuCard(
              activeSubSection: activeSubSection,
              onTap: onSubSectionTap,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: menuItems.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return _OperationsSidebarMenuItem(
                    data: item,
                    onTap: () => onMenuTap(item),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _OperationsSidebarMainItem extends StatelessWidget {
  const _OperationsSidebarMainItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: selected ? _kDeepGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.transparent : const Color(0xFFE6EAE6),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _kDeepGreen.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              const SizedBox(width: 12),
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : const Color(0xFF4E5660),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.6,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF4E5660),
                    height: 1.0,
                  ),
                ),
              ),
              if (!selected)
                const Padding(
                  padding: EdgeInsets.only(left: 10),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 18,
                    color: Color(0xFFB1B7BD),
                  ),
                )
              else
                const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationsSubMenuCard extends StatelessWidget {
  const _OperationsSubMenuCard({
    required this.activeSubSection,
    required this.onTap,
  });

  final String activeSubSection;
  final void Function(String sectionKey) onTap;

  @override
  Widget build(BuildContext context) {
    final items = <_OperationsSubMenuTileData>[
      _OperationsSubMenuTileData(
        label: 'الصفحة الرئيسية',
        icon: Icons.radio_button_checked_rounded,
        sectionKey: 'overview',
      ),
      _OperationsSubMenuTileData(
        label: 'التتبع المباشر',
        icon: Icons.location_on_outlined,
        sectionKey: 'tracking',
      ),
      _OperationsSubMenuTileData(
        label: 'سجل النشاط المباشر',
        icon: Icons.show_chart_rounded,
        sectionKey: 'activity',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _OperationsSubMenuTile(
              data: items[index],
              selected: activeSubSection == items[index].sectionKey,
              onTap: () => onTap(items[index].sectionKey),
            ),
            if (index != items.length - 1) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _OperationsSubMenuTile extends StatelessWidget {
  const _OperationsSubMenuTile({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _OperationsSubMenuTileData data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF1F8F4) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(
                data.icon,
                size: 16,
                color: selected ? _kPrimaryGreen : const Color(0xFF4E5660),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.label,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.6,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? _kPrimaryGreen : const Color(0xFF4E5660),
                    height: 1.0,
                  ),
                ),
              ),
              if (selected)
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: _kPrimaryGreen,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OperationsSidebarMenuItem extends StatelessWidget {
  const _OperationsSidebarMenuItem({required this.data, required this.onTap});

  final _OperationsSidebarTileData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6EAE6)),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(data.icon, size: 18, color: const Color(0xFF4E5660)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.label,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4E5660),
                    height: 1.0,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_left_rounded,
                size: 18,
                color: Color(0xFFB1B7BD),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
