// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

class _OperationsTrackingCenterPanel extends StatelessWidget {
  const _OperationsTrackingCenterPanel({
    required this.serverNow,
    required this.mapMarkers,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    this.selectedDate,
    this.onDateChanged,
    this.autoRefresh = true,
    this.refreshSeconds = 30,
    this.orderType = 'all',
    this.onAutoRefreshChanged,
    this.onRefreshSecondsChanged,
    this.onOrderTypeChanged,
    this.routes = const [],
    this.onSuperTrackingPressed,
    this.showHeaderControls = true,
  });

  final DateTime serverNow;
  final List<_OperationsMapMarkerData> mapMarkers;
  final String statusFilter;
  final ValueChanged<String> onStatusFilterChanged;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateChanged;
  final bool autoRefresh;
  final int refreshSeconds;
  final String orderType;
  final ValueChanged<bool>? onAutoRefreshChanged;
  final ValueChanged<int>? onRefreshSecondsChanged;
  final ValueChanged<String>? onOrderTypeChanged;
  final List<_OperationsRouteData> routes;
  final VoidCallback? onSuperTrackingPressed;
  final bool showHeaderControls;

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatArabicDateLabel(serverNow);

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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'التتبع المباشر',
                            style: TextStyle(
                              fontSize: 17,
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
                              border: Border.all(
                                color: const Color(0xFFD7EBDD),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: Color(0xFF1A8B4A),
                                ),
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
                      const SizedBox(height: 4),
                      const Text(
                        'مراقبة الطلبات والسائقين والمطاعم بشكل لحظي',
                        style: TextStyle(
                          fontSize: 12.1,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6F7680),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (showHeaderControls)
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _InteractiveTrackingHeaderFilters(
                        dateLabel: dateLabel,
                        selectedDate: selectedDate,
                        onDateChanged: onDateChanged,
                        statusFilter: statusFilter,
                        onStatusFilterChanged: onStatusFilterChanged,
                        autoRefresh: autoRefresh,
                        refreshSeconds: refreshSeconds,
                        orderType: orderType,
                        onAutoRefreshChanged: onAutoRefreshChanged,
                        onRefreshSecondsChanged: onRefreshSecondsChanged,
                        onOrderTypeChanged: onOrderTypeChanged,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    _TrackingStatusChip(
                      value: 'all',
                      selectedValue: statusFilter,
                      label: 'الكل',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF1A8B4A),
                      onChanged: onStatusFilterChanged,
                    ),
                    _TrackingStatusChip(
                      value: 'on_way',
                      selectedValue: statusFilter,
                      label: 'على الطريق',
                      icon: Icons.electric_scooter_rounded,
                      color: const Color(0xFF1E7D3F),
                      onChanged: onStatusFilterChanged,
                    ),
                    _TrackingStatusChip(
                      value: 'with_driver',
                      selectedValue: statusFilter,
                      label: 'مع السائق',
                      icon: Icons.delivery_dining_rounded,
                      color: const Color(0xFF2563EB),
                      onChanged: onStatusFilterChanged,
                    ),
                    _TrackingStatusChip(
                      value: 'ready',
                      selectedValue: statusFilter,
                      label: 'جاهزة',
                      icon: Icons.storefront_outlined,
                      color: const Color(0xFFF59E0B),
                      onChanged: onStatusFilterChanged,
                    ),
                    if (onSuperTrackingPressed != null)
                      _SuperTrackingChip(onTap: onSuperTrackingPressed!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _TrackingMapPanel(markers: mapMarkers, routes: routes),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingPill extends StatelessWidget {
  const _TrackingPill({
    required this.label,
    required this.background,
    required this.borderColor,
    required this.textColor,
    this.icon,
  });

  final String label;
  final Color background;
  final Color borderColor;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: textColor),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.2,
              fontWeight: FontWeight.w600,
              color: textColor,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingDatePill extends StatelessWidget {
  const _TrackingDatePill({required this.date, this.onChanged});

  final DateTime date;
  final ValueChanged<DateTime>? onChanged;

  @override
  Widget build(BuildContext context) {
    final label = _formatArabicDateLabel(date);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onChanged == null
          ? null
          : () async {
              final selected = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                locale: const Locale('ar'),
                builder: (context, child) {
                  final base = Theme.of(context);
                  return Theme(
                    data: base.copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF0B5B52),
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Color(0xFF1E232A),
                      ),
                      datePickerTheme: const DatePickerThemeData(
                        backgroundColor: Colors.white,
                        surfaceTintColor: Colors.white,
                        headerBackgroundColor: Color(0xFF0B5B52),
                        headerForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(22)),
                        ),
                        dividerColor: Color(0xFFE7ECE8),
                      ),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  );
                },
              );
              if (selected != null) onChanged!(selected);
            },
      child: _TrackingPill(
        label: label,
        background: Colors.white,
        borderColor: const Color(0xFFE3E8E3),
        textColor: const Color(0xFF4E5660),
        icon: Icons.calendar_month_rounded,
      ),
    );
  }
}

class _TrackingHeaderFilters extends StatelessWidget {
  // ignore: unused_element_parameter
  const _TrackingHeaderFilters({
    required this.dateLabel,
    // ignore: unused_element_parameter
    this.selectedDate,
    // ignore: unused_element_parameter
    this.onDateChanged,
  });

  final String dateLabel;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateChanged;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: [
          _TrackingPill(
            label: 'تحديث تلقائي',
            background: const Color(0xFFF7F9F7),
            borderColor: const Color(0xFFE3E8E3),
            textColor: const Color(0xFF4E5660),
            icon: Icons.refresh_rounded,
          ),
          _TrackingPill(
            label: '30 ثانية',
            background: const Color(0xFFEAF5ED),
            borderColor: const Color(0xFFD7EBDD),
            textColor: const Color(0xFF1A8B4A),
          ),
          _TrackingPill(
            label: 'جميع الحالات',
            background: Colors.white,
            borderColor: const Color(0xFFE3E8E3),
            textColor: const Color(0xFF4E5660),
            icon: Icons.keyboard_arrow_down_rounded,
          ),
          _TrackingDatePill(
            date: selectedDate ?? DateTime.now(),
            onChanged: onDateChanged,
          ),
          _TrackingPill(
            label: 'كل أنواع الطلبات',
            background: Colors.white,
            borderColor: const Color(0xFFE3E8E3),
            textColor: const Color(0xFF4E5660),
            icon: Icons.keyboard_arrow_down_rounded,
          ),
        ],
      ),
    );
  }
}

class _InteractiveTrackingHeaderFilters extends StatelessWidget {
  const _InteractiveTrackingHeaderFilters({
    required this.dateLabel,
    required this.selectedDate,
    required this.onDateChanged,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.autoRefresh,
    required this.refreshSeconds,
    required this.orderType,
    this.onAutoRefreshChanged,
    this.onRefreshSecondsChanged,
    this.onOrderTypeChanged,
  });

  final String dateLabel;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDateChanged;
  final String statusFilter;
  final ValueChanged<String> onStatusFilterChanged;
  final bool autoRefresh;
  final int refreshSeconds;
  final String orderType;
  final ValueChanged<bool>? onAutoRefreshChanged;
  final ValueChanged<int>? onRefreshSecondsChanged;
  final ValueChanged<String>? onOrderTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: [
          _TrackingMenuPill(
            label: autoRefresh ? 'تحديث تلقائي' : 'التحديث متوقف',
            value: autoRefresh ? 'on' : 'off',
            items: const {'on': 'تحديث تلقائي', 'off': 'التحديث متوقف'},
            icon: Icons.refresh_rounded,
            selected: autoRefresh,
            onSelected: (value) => onAutoRefreshChanged?.call(value == 'on'),
          ),
          _TrackingMenuPill(
            label: '$refreshSeconds ثانية',
            value: '$refreshSeconds',
            items: const {'15': '15 ثانية', '30': '30 ثانية', '60': '60 ثانية'},
            selected: true,
            onSelected: (value) =>
                onRefreshSecondsChanged?.call(int.tryParse(value) ?? 30),
          ),
          _TrackingDatePill(
            date: selectedDate ?? DateTime.now(),
            onChanged: onDateChanged,
          ),
          _TrackingMenuPill(
            label: _trackingFilterLabel(statusFilter),
            value: statusFilter,
            items: const {
              'all': 'جميع الحالات',
              'on_way': 'على الطريق',
              'with_driver': 'مع السائق',
              'ready': 'جاهزة',
            },
            onSelected: onStatusFilterChanged,
          ),
          _TrackingMenuPill(
            label: _trackingOrderTypeLabel(orderType),
            value: orderType,
            items: const {
              'all': 'كل أنواع الطلبات',
              'food': 'طلبات الطعام',
              'store': 'طلبات المتاجر',
              'pharmacy': 'طلبات الصيدلية',
            },
            onSelected: (value) => onOrderTypeChanged?.call(value),
          ),
        ],
      ),
    );
  }

  String _trackingFilterLabel(String value) {
    return const {
          'all': 'جميع الحالات',
          'on_way': 'على الطريق',
          'with_driver': 'مع السائق',
          'ready': 'جاهزة',
        }[value] ??
        'جميع الحالات';
  }

  String _trackingOrderTypeLabel(String value) {
    if (value == 'food') {
      return '\u0637\u0644\u0628\u0627\u062a \u0627\u0644\u0645\u0637\u0627\u0639\u0645';
    }
    return const {
          'all': 'كل أنواع الطلبات',
          'food': 'طلبات الطعام',
          'store': 'طلبات المتاجر',
          'pharmacy': 'طلبات الصيدلية',
        }[value] ??
        'كل أنواع الطلبات';
  }
}

class _TrackingMenuPill extends StatelessWidget {
  const _TrackingMenuPill({
    required this.label,
    required this.value,
    required this.items,
    required this.onSelected,
    this.icon,
    this.selected = false,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onSelected;
  final IconData? icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final background = selected ? const Color(0xFFEAF5ED) : Colors.white;
    final border = selected ? const Color(0xFFD7EBDD) : const Color(0xFFE3E8E3);
    final text = selected ? const Color(0xFF1A8B4A) : const Color(0xFF4E5660);

    return PopupMenuButton<String>(
      initialValue: items.containsKey(value) ? value : null,
      onSelected: onSelected,
      tooltip: label,
      position: PopupMenuPosition.under,
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE3E8E3)),
      ),
      itemBuilder: (context) => items.entries
          .where((entry) => entry.key != 'pharmacy')
          .map(
            (entry) => PopupMenuItem<String>(
              value: entry.key,
              child: Text(
                entry.value,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: text),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11.2,
                fontWeight: FontWeight.w700,
                color: text,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: text),
          ],
        ),
      ),
    );
  }
}

class _TrackingStatusChip extends StatelessWidget {
  const _TrackingStatusChip({
    required this.value,
    required this.selectedValue,
    required this.label,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  final String value;
  final String selectedValue;
  final String label;
  final IconData icon;
  final Color color;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;
    return _OperationsFilterChip(
      label: label,
      icon: icon,
      backgroundColor: selected ? color.withValues(alpha: 0.1) : Colors.white,
      borderColor: selected
          ? color.withValues(alpha: 0.28)
          : const Color(0xFFE3E8E3),
      iconColor: color,
      textColor: selected ? color : const Color(0xFF4E5660),
      onTap: () => onChanged(value),
    );
  }
}

class _SuperTrackingChip extends StatelessWidget {
  const _SuperTrackingChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B514B),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0xFF0B514B)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: TextDirection.rtl,
            children: [
              Icon(Icons.public_rounded, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'التتبع الخارق',
                style: TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingWeatherBadge extends StatelessWidget {
  const _TrackingWeatherBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wb_sunny_rounded, size: 14, color: Color(0xFFF59E0B)),
          SizedBox(width: 6),
          Text(
            '28°',
            style: TextStyle(
              fontSize: 11.8,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E232A),
              height: 1.0,
            ),
          ),
          SizedBox(width: 6),
          Text(
            'صحو',
            style: TextStyle(
              fontSize: 10.2,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6F7680),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingMapControlButton extends StatelessWidget {
  const _TrackingMapControlButton({
    required this.icon,
    this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String? tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? 'تحكم الخريطة',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE7ECE8)),
            ),
            child: Icon(icon, size: 17, color: const Color(0xFF4E5660)),
          ),
        ),
      ),
    );
  }
}

class _TrackingMapPanel extends StatelessWidget {
  const _TrackingMapPanel({required this.markers, this.routes = const []});

  final List<_OperationsMapMarkerData> markers;
  final List<_OperationsRouteData> routes;

  @override
  Widget build(BuildContext context) {
    return _LiveOperationsMap(
      markers: markers,
      routes: routes,
      showWeatherBadge: true,
      showLayerPanel: false,
    );
    /*
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _OpsMapBackdropPainter()),
                ),
                Positioned(
                  left: 14,
                  top: 14,
                  child: const _TrackingWeatherBadge(),
                ),
                Positioned(
                  left: w * 0.43,
                  top: h * 0.51,
                  child: Opacity(
                    opacity: 0.38,
                    child: Text(
                      'حلب',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E232A).withValues(alpha: 0.55),
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Column(
                    children: const [
                      _TrackingMapControlButton(icon: Icons.layers_rounded),
                      SizedBox(height: 8),
                      _TrackingMapControlButton(icon: Icons.add_rounded),
                      SizedBox(height: 8),
                      _TrackingMapControlButton(icon: Icons.remove_rounded),
                      SizedBox(height: 8),
                      _TrackingMapControlButton(
                        icon: Icons.my_location_rounded,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: w * 0.13,
                  top: h * 0.29,
                  child: _OpsMapMarker(
                    label: 'الزبداني',
                    icon: Icons.storefront_outlined,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                Positioned(
                  left: w * 0.24,
                  top: h * 0.18,
                  child: _OpsMapMarker(
                    label: 'جامعة حلب',
                    icon: Icons.electric_scooter_rounded,
                    color: Color(0xFF1E7D3F),
                  ),
                ),
                Positioned(
                  left: w * 0.46,
                  top: h * 0.58,
                  child: _OpsMapMarker(
                    label: 'حلب',
                    icon: Icons.local_fire_department_outlined,
                    color: Color(0xFFD92C2C),
                  ),
                ),
                Positioned(
                  left: w * 0.63,
                  top: h * 0.30,
                  child: _OpsMapMarker(
                    label: 'المقدمة',
                    icon: Icons.delivery_dining_rounded,
                    color: Color(0xFF2563EB),
                  ),
                ),
                Positioned(
                  left: w * 0.80,
                  top: h * 0.42,
                  child: _OpsMapMarker(
                    label: 'الزهراء',
                    icon: Icons.electric_scooter_rounded,
                    color: Color(0xFF1E7D3F),
                  ),
                ),
                Positioned(
                  left: w * 0.72,
                  top: h * 0.69,
                  child: _OpsMapMarker(
                    label: 'الشيخ مقصود',
                    icon: Icons.storefront_outlined,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                Positioned(
                  left: w * 0.79,
                  top: h * 0.28,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFD3FF)),
                    ),
                    child: const Text(
                      'على الطريق',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D6BFF),
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 12,
                  child: Center(child: _OperationsLegendBar()),
                ),
              ],
            );
          },
        ),
      ),
    );
    */
  }
}

class _OperationsTrackingFilterSidebar extends StatelessWidget {
  const _OperationsTrackingFilterSidebar({
    required this.drivers,
    required this.restaurants,
  });

  final List<_TrackingListItemData> drivers;
  final List<_TrackingListItemData> restaurants;

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _OperationsSectionHeader(
                title: 'فلاتر الخريطة',
                subtitle: 'إظهار على الخريطة',
              ),
              const SizedBox(height: 12),
              for (final option in _kTrackingFilterOptions) ...[
                _TrackingFilterToggle(option: option),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              _TrackingMiniListCard(
                title: 'قائمة السائقين',
                countLabel: '(${drivers.length})',
                actionLabel: 'عرض الكل',
                items: drivers,
                buttonLabel: 'عرض جميع السائقين',
              ),
              const SizedBox(height: 12),
              _TrackingMiniListCard(
                title: 'قائمة المطاعم',
                countLabel: '(${restaurants.length})',
                actionLabel: 'عرض الكل',
                items: restaurants,
                buttonLabel: 'عرض جميع المطاعم',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingFilterToggle extends StatelessWidget {
  const _TrackingFilterToggle({required this.option});

  final _TrackingFilterOptionData option;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6EAE6)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 17,
            height: 17,
            decoration: BoxDecoration(
              color: option.selected ? option.color : Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: option.selected ? option.color : const Color(0xFFCBD3CB),
              ),
            ),
            child: option.selected
                ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 7),
          Icon(option.icon, size: 15, color: option.color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              option.label,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4E5660),
                height: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingMiniListCard extends StatelessWidget {
  const _TrackingMiniListCard({
    required this.title,
    required this.countLabel,
    required this.actionLabel,
    required this.items,
    required this.buttonLabel,
  });

  final String title;
  final String countLabel;
  final String actionLabel;
  final List<_TrackingListItemData> items;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Text(
                '$title $countLabel',
                style: const TextStyle(
                  fontSize: 12.2,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E232A),
                  height: 1.0,
                ),
              ),
              const Spacer(),
              Text(
                actionLabel,
                style: const TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A56D2),
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var index = 0; index < items.length; index++) ...[
            _TrackingMiniListTile(item: items[index]),
            if (index != items.length - 1)
              const Divider(height: 1, thickness: 1),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  _showTrackingItemsSheet(context, title: title, items: items),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(36),
                side: const BorderSide(color: Color(0xFFE5E8E5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 11.0,
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

class _TrackingMiniListTile extends StatelessWidget {
  const _TrackingMiniListTile({required this.item});

  final _TrackingListItemData item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: item.background,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 14, color: item.iconColor),
          ),
          const SizedBox(width: 7),
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
                    fontSize: 11.1,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E232A),
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.4,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6F7680),
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _TrackingStatusPill(
                label: item.statusLabel,
                color: item.statusColor,
              ),
              const SizedBox(height: 4),
              Text(
                item.note,
                style: const TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A919A),
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

class _OperationsTrackingOrdersPanel extends StatelessWidget {
  const _OperationsTrackingOrdersPanel({
    required this.items,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.onOrderTap,
  });

  final List<_TrackingOrderData> items;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<_TrackingOrderData>? onOrderTap;

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
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Text(
                  'الطلبات النشطة (${items.length})',
                  style: const TextStyle(
                    fontSize: 15.2,
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
                          fontSize: 10.2,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A8B4A),
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'عرض الكل',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A56D2),
                    height: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                _TrackingOrderTabChip(
                  label: 'الكل',
                  selected: selectedFilter == 'all',
                  onTap: () => onFilterChanged('all'),
                ),
                const SizedBox(width: 6),
                _TrackingOrderTabChip(
                  label: 'على الطريق',
                  selected: selectedFilter == 'on_way',
                  onTap: () => onFilterChanged('on_way'),
                ),
                const SizedBox(width: 6),
                _TrackingOrderTabChip(
                  label: 'مع السائق',
                  selected: selectedFilter == 'with_driver',
                  onTap: () => onFilterChanged('with_driver'),
                ),
                const SizedBox(width: 6),
                _TrackingOrderTabChip(
                  label: 'جاهزة',
                  selected: selectedFilter == 'ready',
                  onTap: () => onFilterChanged('ready'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _OperationsTrackingOrderCard(
                  item: items[index],
                  onTap: onOrderTap == null
                      ? null
                      : () => onOrderTap!(items[index]),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showTrackingOrdersSheet(
                  context,
                  title: 'جميع الطلبات النشطة',
                  items: items,
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  side: const BorderSide(color: Color(0xFFE5E8E5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'عرض جميع الطلبات النشطة',
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4E5660),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackingOrderTabChip extends StatelessWidget {
  const _TrackingOrderTabChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F8F4) : const Color(0xFFFDFDFD),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFD7EBDD) : const Color(0xFFE6EAE6),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.6,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? _kPrimaryGreen : const Color(0xFF4E5660),
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _OperationsTrackingOrderCard extends StatelessWidget {
  const _OperationsTrackingOrderCard({required this.item, this.onTap});

  final _TrackingOrderData item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 94,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7ECE8)),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: item.avatarBackground,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: item.statusColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Icon(item.avatarIcon, size: 18, color: item.statusColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.orderNo,
                          style: const TextStyle(
                            fontSize: 11.7,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E232A),
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TrackingStatusPill(
                          label: item.statusLabel,
                          color: item.statusColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.customer,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.3,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E232A),
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.destination,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.7,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6F7680),
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.timeLabel,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8A919A),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingStatusPill extends StatelessWidget {
  const _TrackingStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.1,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

class _OperationsTrackingBottomStrip extends StatelessWidget {
  const _OperationsTrackingBottomStrip({
    required this.momentMetrics,
    required this.pressureAreas,
    required this.shortageAreas,
    required this.liveStats,
  });

  final List<_TrackingMomentMetricData> momentMetrics;
  final List<_TrackingAreaStatusData> pressureAreas;
  final List<_TrackingAreaStatusData> shortageAreas;
  final List<_TrackingLiveStatData> liveStats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1020) {
          return Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _TrackingMomentInsightsCard(items: momentMetrics),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TrackingAreaHighlightsCard(
                  title: 'مناطق الضغط الحالية',
                  subtitle: 'أعلى الحمل الآن',
                  footerLabel: 'عرض جميع المناطق',
                  items: pressureAreas,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TrackingAreaHighlightsCard(
                  title: 'مناطق نقص السائقين',
                  subtitle: 'أولوية التغطية الآن',
                  footerLabel: 'عرض جميع المناطق',
                  items: shortageAreas,
                  accentColor: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _TrackingLiveStatsCard(items: liveStats)),
            ],
          );
        }

        return Column(
          children: [
            Expanded(
              child: Row(
                textDirection: TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _TrackingMomentInsightsCard(items: momentMetrics),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TrackingAreaHighlightsCard(
                      title: 'مناطق الضغط الحالية',
                      subtitle: 'أعلى الحمل الآن',
                      footerLabel: 'عرض جميع المناطق',
                      items: pressureAreas,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                textDirection: TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _TrackingAreaHighlightsCard(
                      title: 'مناطق نقص السائقين',
                      subtitle: 'أولوية التغطية الآن',
                      footerLabel: 'عرض جميع المناطق',
                      items: shortageAreas,
                      accentColor: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _TrackingLiveStatsCard(items: liveStats)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TrackingMomentInsightsCard extends StatelessWidget {
  const _TrackingMomentInsightsCard({required this.items});

  final List<_TrackingMomentMetricData> items;

  @override
  Widget build(BuildContext context) {
    return _TrackingBottomCardShell(
      title: 'مؤشرات اللحظة',
      subtitle: 'قراءة مباشرة من النظام',
      child: Row(
        textDirection: TextDirection.rtl,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(child: _TrackingRingMetric(item: items[i])),
            if (i != items.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _TrackingRingMetric extends StatelessWidget {
  const _TrackingRingMetric({required this.item});

  final _TrackingMomentMetricData item;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: item.progress,
                strokeWidth: 3.0,
                backgroundColor: item.background,
                valueColor: AlwaysStoppedAnimation<Color>(item.color),
              ),
              Center(
                child: Text(
                  item.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.4,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E232A),
                    height: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9.1,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5E6670),
            height: 1.15,
          ),
        ),
      ],
    );
  }
}

class _TrackingAreaHighlightsCard extends StatelessWidget {
  const _TrackingAreaHighlightsCard({
    required this.title,
    required this.subtitle,
    required this.footerLabel,
    required this.items,
    this.accentColor = const Color(0xFFD92C2C),
  });

  final String title;
  final String subtitle;
  final String footerLabel;
  final List<_TrackingAreaStatusData> items;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return _TrackingBottomCardShell(
      title: title,
      subtitle: subtitle,
      footerLabel: footerLabel,
      footerColor: accentColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _TrackingAreaRow(item: items[index]),
            if (index != items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 7),
                child: Divider(height: 1, thickness: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class _TrackingAreaRow extends StatelessWidget {
  const _TrackingAreaRow({required this.item});

  final _TrackingAreaStatusData item;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: item.dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
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
                  fontSize: 11.4,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E232A),
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.2,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6F7680),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _TrackingStatusPill(label: item.status, color: item.statusColor),
      ],
    );
  }
}

class _TrackingLiveStatsCard extends StatelessWidget {
  const _TrackingLiveStatsCard({required this.items});

  final List<_TrackingLiveStatData> items;

  @override
  Widget build(BuildContext context) {
    return _TrackingBottomCardShell(
      title: 'إحصائيات مباشرة',
      subtitle: 'أرقام لحظية من المنصة',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _TrackingLiveStatRow(item: items[index]),
            if (index != items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 7),
                child: Divider(height: 1, thickness: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class _TrackingLiveStatRow extends StatelessWidget {
  const _TrackingLiveStatRow({required this.item});

  final _TrackingLiveStatData item;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: item.background,
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, size: 12, color: item.color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            item.label,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4E5660),
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          item.value,
          style: const TextStyle(
            fontSize: 12.4,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E232A),
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

class _TrackingBottomCardShell extends StatelessWidget {
  const _TrackingBottomCardShell({
    required this.title,
    required this.child,
    this.subtitle,
    this.footerLabel,
    this.footerColor,
  });

  final String title;
  final String? subtitle;
  final String? footerLabel;
  final Color? footerColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.022),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.2,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E232A),
                height: 1.0,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9.1,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF7A8088),
                  height: 1.0,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: child,
                    ),
                  );
                },
              ),
            ),
            if (footerLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                footerLabel!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10.0,
                  fontWeight: FontWeight.w700,
                  color: footerColor ?? _kPrimaryGreen,
                  height: 1.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showMasterSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

String _masterCsvEscape(Object? value) {
  final text = (value ?? '').toString();
  return '"${text.replaceAll('"', '""')}"';
}

void _copyMasterRowsToClipboard(
  BuildContext context, {
  required String label,
  required List<String> headers,
  required List<List<Object?>> rows,
}) {
  final csvRows = <List<Object?>>[headers, ...rows];
  final csv = csvRows
      .map((row) => row.map(_masterCsvEscape).join(','))
      .join('\n');
  Clipboard.setData(ClipboardData(text: csv));
  _showMasterSnack(context, 'تم تصدير $label إلى الحافظة بصيغة CSV');
}

void _copyMasterTextToClipboard(
  BuildContext context, {
  required String label,
  required String text,
}) {
  Clipboard.setData(ClipboardData(text: text));
  _showMasterSnack(context, 'تم نسخ $label إلى الحافظة');
}

void _showMasterDetailsDialog(
  BuildContext context, {
  required String title,
  required List<(String, String)> rows,
}) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 132,
                            child: Text(
                              row.$1,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              row.$2.trim().isEmpty ? '-' : row.$2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      );
    },
  );
}

void _showOperationsSheet(
  BuildContext context, {
  required String title,
  required List<Widget> children,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      final content = children.isEmpty
          ? <Widget>[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 34),
                child: Center(
                  child: Text(
                    'لا توجد بيانات متاحة الآن',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6F7680),
                    ),
                  ),
                ),
              ),
            ]
          : children;
      return Directionality(
        textDirection: TextDirection.rtl,
        child: DraggableScrollableSheet(
          initialChildSize: 0.68,
          minChildSize: 0.34,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8DED9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E232A),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'إغلاق',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: content.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) => content[index],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

Widget _operationsSheetRow({
  required IconData icon,
  required Color iconColor,
  required String title,
  String subtitle = '',
  String trailing = '',
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFDFDFD),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE7ECE8)),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E232A),
                ),
              ),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.2,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6F7680),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing.trim().isNotEmpty) ...[
          const SizedBox(width: 10),
          Text(
            trailing,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: iconColor,
            ),
          ),
        ],
      ],
    ),
  );
}

void _showOperationsStatCardsSheet(
  BuildContext context, {
  required String title,
  required List<_OperationsStatCardData> cards,
}) {
  _showOperationsSheet(
    context,
    title: title,
    children: [
      for (final card in cards)
        _operationsSheetRow(
          icon: card.icon,
          iconColor: card.accent,
          title: card.title,
          subtitle: [
            card.detailLine,
            card.trendCaption,
          ].where((item) => item.trim().isNotEmpty).join(' - '),
          trailing: card.value,
        ),
    ],
  );
}

void _showOperationsLiveItemsSheet(
  BuildContext context, {
  required String title,
  required List<_OperationsLiveItemData> items,
}) {
  _showOperationsSheet(
    context,
    title: title,
    children: [
      for (final item in items)
        _operationsSheetRow(
          icon: item.icon,
          iconColor: item.accent,
          title: item.title,
          subtitle: item.subtitle,
          trailing: item.timeLabel,
        ),
    ],
  );
}

void _showActivitySummarySheet(
  BuildContext context, {
  required String title,
  required List<_ActivitySummaryGroupData> groups,
}) {
  _showOperationsSheet(
    context,
    title: title,
    children: [
      for (final group in groups) ...[
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Text(
            group.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: group.headerAccent,
            ),
          ),
        ),
        for (final item in group.items)
          _operationsSheetRow(
            icon: item.icon,
            iconColor: item.accent,
            title: item.label,
            trailing: item.value,
          ),
      ],
    ],
  );
}

void _showActivityFeedSheet(
  BuildContext context, {
  required String title,
  required List<_ActivityFeedItemData> items,
}) {
  _showOperationsSheet(
    context,
    title: title,
    children: [
      for (final item in items)
        _operationsSheetRow(
          icon: item.icon,
          iconColor: item.accent,
          title: item.title,
          subtitle: [
            item.subtitle,
            item.detail,
          ].where((value) => value.trim().isNotEmpty).join(' - '),
          trailing: item.relativeLabel.isNotEmpty
              ? item.relativeLabel
              : item.timeLabel,
        ),
    ],
  );
}

void _showActivityEventsSheet(
  BuildContext context, {
  required String title,
  required List<_ActivityEventItemData> items,
}) {
  _showOperationsSheet(
    context,
    title: title,
    children: [
      for (final item in items)
        _operationsSheetRow(
          icon: item.icon,
          iconColor: item.accent,
          title: item.title,
          subtitle: [
            item.reference,
            item.role,
            item.note,
          ].where((value) => value.trim().isNotEmpty).join(' - '),
          trailing: item.timeLabel,
        ),
    ],
  );
}

void _showActivityEventDetailsSheet(
  BuildContext context,
  _ActivityEventItemData item,
) {
  _showActivityEventsSheet(context, title: item.title, items: [item]);
}

void _showTrackingItemsSheet(
  BuildContext context, {
  required String title,
  required List<_TrackingListItemData> items,
}) {
  _showOperationsSheet(
    context,
    title: title,
    children: [
      for (final item in items)
        _operationsSheetRow(
          icon: item.icon,
          iconColor: item.statusColor,
          title: item.title,
          subtitle: [
            item.subtitle,
            item.note,
          ].where((value) => value.trim().isNotEmpty).join(' - '),
          trailing: item.statusLabel,
        ),
    ],
  );
}

void _showTrackingOrdersSheet(
  BuildContext context, {
  required String title,
  required List<_TrackingOrderData> items,
}) {
  _showOperationsSheet(
    context,
    title: title,
    children: [
      for (final item in items)
        _operationsSheetRow(
          icon: item.avatarIcon,
          iconColor: item.statusColor,
          title: '${item.orderNo} - ${item.customer}',
          subtitle: item.destination,
          trailing: item.statusLabel,
        ),
    ],
  );
}

void _showTrackingOrderDetails(BuildContext context, _TrackingOrderData order) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'تفاصيل الطلب ${order.orderNo}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E232A),
                  ),
                ),
                const SizedBox(height: 14),
                _trackingDetailRow('العميل', order.customer),
                _trackingDetailRow('العنوان', order.destination),
                _trackingDetailRow('الحالة', order.statusLabel),
                _trackingDetailRow('الوقت', order.timeLabel),
                _trackingConfirmationCode(order.confirmationCode),
                if (order.orderId > 0)
                  _trackingDetailRow('رقم الطلب', '#${order.orderId}'),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text('إغلاق'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _trackingConfirmationCode(String code) {
  final normalized = code.trim();
  if (normalized.isEmpty) {
    return _trackingDetailRow('كود التأكيد', 'غير متوفر');
  }
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF5ED),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFBFE2C9)),
    ),
    child: Row(
      children: [
        const Icon(Icons.verified_rounded, color: Color(0xFF1A8B4A), size: 20),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'كود تأكيد الطلب',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A8B4A),
            ),
          ),
        ),
        SelectableText(
          normalized,
          style: const TextStyle(
            fontSize: 19,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
            color: Color(0xFF14532D),
          ),
        ),
      ],
    ),
  );
}

Widget _trackingDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6F7680),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.trim().isEmpty ? 'غير متوفر' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E232A),
            ),
          ),
        ),
      ],
    ),
  );
}

void _showSuperTrackingMap(
  BuildContext context, {
  required List<_OperationsMapMarkerData> markers,
  required List<_OperationsRouteData> routes,
  required Future<_MasterOperationsData> Function() reload,
  required MasterAuthApiService api,
  required String token,
}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _SuperTrackingMapPage(
      initialMarkers: markers,
      initialRoutes: routes,
      reload: reload,
      api: api,
      token: token,
    ),
  );
}

class _SuperTrackingMapPage extends StatefulWidget {
  const _SuperTrackingMapPage({
    required this.initialMarkers,
    required this.initialRoutes,
    required this.reload,
    required this.api,
    required this.token,
  });

  final List<_OperationsMapMarkerData> initialMarkers;
  final List<_OperationsRouteData> initialRoutes;
  final Future<_MasterOperationsData> Function() reload;
  final MasterAuthApiService api;
  final String token;

  @override
  State<_SuperTrackingMapPage> createState() => _SuperTrackingMapPageState();
}

class _SuperTrackingMapPageState extends State<_SuperTrackingMapPage> {
  late List<_OperationsMapMarkerData> _markers;
  late List<_OperationsRouteData> _routes;
  Timer? _refreshTimer;
  bool _refreshing = false;
  _OperationsMapMarkerData? _selectedMarker;
  Map<String, dynamic>? _vendorDetails;
  bool _loadingDetails = false;

  @override
  void initState() {
    super.initState();
    _markers = widget.initialMarkers;
    _routes = widget.initialRoutes;
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _refreshMap(),
    );
  }

  Future<void> _refreshMap() async {
    if (_refreshing || !mounted || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    _refreshing = true;
    try {
      final data = await widget.reload();
      if (mounted) {
        setState(() {
          _markers = data.trackingMapMarkers;
          _routes = data.trackingRoutes;
        });
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _openMarker(_OperationsMapMarkerData marker) async {
    setState(() {
      _selectedMarker = marker;
      _vendorDetails = null;
      _loadingDetails = true;
    });
    try {
      final entityType = marker.type == 'restaurant' || marker.type == 'store'
          ? 'vendor'
          : (marker.type == 'emergency' ? 'driver' : marker.type);
      final details = marker.entityId > 0
          ? await widget.api._fetchOperationsEntityDetails(
              widget.token,
              type: entityType,
              id: marker.entityId,
            )
          : <String, dynamic>{};
      if (mounted) {
        setState(() {
          _vendorDetails = details;
          _loadingDetails = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.white,
      child: Stack(
        children: [
          Positioned.fill(
            child: _LiveOperationsMap(
              markers: _markers,
              routes: _routes,
              onMarkerTap: _openMarker,
              showWeatherBadge: true,
              showLayerPanel: true,
            ),
          ),
          if (_selectedMarker != null)
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: 370,
              child: _SuperTrackingEntityPanel(
                marker: _selectedMarker!,
                details: _vendorDetails,
                loading: _loadingDetails,
                onClose: () => setState(() {
                  _selectedMarker = null;
                  _vendorDetails = null;
                }),
              ),
            ),
          if (_selectedMarker == null)
            Positioned(
              top: 18,
              right: 18,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE7ECE8)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF4E5660),
                    ),
                  ),
                ),
              ),
            ),
          if (_selectedMarker != null && _selectedMarker!.type == '__hidden__')
            Positioned(
              top: 18,
              left: 18,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B514B).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  textDirection: TextDirection.rtl,
                  children: [
                    Icon(Icons.radar_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 7),
                    Text(
                      'التتبع الخارق • LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuperTrackingEntityPanel extends StatelessWidget {
  const _SuperTrackingEntityPanel({
    required this.marker,
    required this.details,
    required this.loading,
    required this.onClose,
  });

  final _OperationsMapMarkerData marker;
  final Map<String, dynamic>? details;
  final bool loading;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final vendor = _asMap(details?['entity'] ?? details?['vendor']);
    final driver = _asMap(details?['driver'] ?? details?['entity']);
    final customer = _asMap(details?['customer'] ?? details?['entity']);
    final products = _asMapList(details?['products']);
    final orders = _asMapList(details?['orders'] ?? details?['previous_trips']);
    final currentTrips = _asMapList(details?['current_trips']);
    final favorites = _asMapList(details?['favorites']);
    final hours = _asMapList(details?['hours']);
    final isEmergency = marker.type == 'emergency';
    final isDriver = marker.type == 'driver' || isEmergency;
    final isCustomer = marker.type == 'order' || marker.type == 'customer';
    final title =
        ((isDriver
                    ? driver['name']
                    : isCustomer
                    ? customer['name']
                    : (vendor['store_name'] ?? vendor['vendor_name'])) ??
                marker.label)
            .toString();
    final tabLabels = isDriver
        ? const ['البيانات', 'الرحلات الحالية', 'السجل', 'التقييمات']
        : isCustomer
        ? const ['البيانات', 'المفضلة', 'الطلب الحالي', 'الطلبات']
        : const ['البيانات', 'المنتجات', 'المواعيد', 'الطلبات'];
    final tabViews = isDriver
        ? <Widget>[
            _entityProfile(driver, marker),
            _entityOrders(currentTrips),
            _entityOrders(orders),
            _entityRatings(_asMap(details?['ratings'])),
          ]
        : isCustomer
        ? <Widget>[
            _entityProfile(customer, marker),
            _entityFavorites(favorites),
            _entityOrders(
              _asMapList(
                details?['current_order'] == null
                    ? null
                    : [details!['current_order']],
              ),
            ),
            _entityOrders(orders),
          ]
        : <Widget>[
            _entityProfile(vendor, marker),
            _entityProducts(products),
            _entityHours(hours),
            _entityOrders(orders),
          ];
    return Material(
      elevation: 18,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isEmergency)
                Container(
                  margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE8E8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF5A3A3)),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      const Icon(
                        Icons.emergency_rounded,
                        color: Color(0xFFD92C2C),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'تنبيه طوارئ حديث • ${marker.subtitle}',
                          style: const TextStyle(
                            color: Color(0xFF9B1C1C),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF07564F),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    _entityAvatar(
                      ((isDriver
                                  ? driver['image_url']
                                  : isCustomer
                                  ? customer['image_url']
                                  : vendor['logo_url']) ??
                              '')
                          .toString(),
                      isDriver
                          ? Icons.two_wheeler_rounded
                          : isCustomer
                          ? Icons.person_rounded
                          : Icons.storefront_rounded,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'إغلاق',
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F8F4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _entityBadge(
                            'الحالة',
                            (isEmergency
                                    ? 'طوارئ'
                                    : isDriver
                                    ? driver['status']
                                    : vendor['vendor_status']) ??
                                'غير محدد',
                          ),
                          _entityBadge(
                            isDriver ? 'الرحلات الحالية' : 'الطلبات',
                            isDriver ? currentTrips.length : orders.length,
                          ),
                          if (!isDriver && !isCustomer)
                            _entityBadge('المنتجات', products.length),
                          if (isDriver)
                            _entityBadge(
                              'التقييم',
                              _asMap(details?['ratings'])['average_rating'] ??
                                  '--',
                            ),
                        ],
                      ),
              ),
              if (!loading)
                Expanded(
                  child: DefaultTabController(
                    length: tabLabels.length,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: Color(0xFF0B514B),
                          unselectedLabelColor: Color(0xFF6F7680),
                          indicatorColor: Color(0xFF0B514B),
                          tabs: tabLabels
                              .map((label) => Tab(text: label))
                              .toList(),
                        ),
                        Expanded(child: TabBarView(children: tabViews)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _entityProfile(
    Map<String, dynamic> vendor,
    _OperationsMapMarkerData marker,
  ) {
    if (marker.type == 'driver' || marker.type == 'emergency') {
      return _entityGenericProfile({
        'الاسم': vendor['name'] ?? marker.label,
        'الهاتف': vendor['phone'],
        'البريد': vendor['email'],
        'الحالة': vendor['status'],
        'المركبة': [vendor['vehicle_type'], vendor['vehicle_number']]
            .where(
              (value) => value != null && value.toString().trim().isNotEmpty,
            )
            .join(' - '),
        'آخر ظهور': vendor['last_seen_at'],
      });
    }
    if (marker.type == 'order' || marker.type == 'customer') {
      return _entityGenericProfile({
        'الاسم': vendor['name'] ?? marker.label,
        'الهاتف': vendor['phone'],
        'العنوان': vendor['address'],
      });
    }
    final rows = <String, dynamic>{
      'الاسم': vendor['store_name'] ?? vendor['vendor_name'] ?? marker.label,
      'العنوان': vendor['address'] ?? 'غير متوفر',
      'الهاتف': vendor['phone'] ?? 'غير متوفر',
      'البريد': vendor['email'] ?? 'غير متوفر',
      'الوصف': vendor['description'] ?? 'غير متوفر',
      'التوثيق': vendor['vendor_is_verified'] == 1 ? 'موثق' : 'غير موثق',
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: rows.entries
          .map((entry) => _entityInfoRow(entry.key, entry.value.toString()))
          .toList(),
    );
  }

  Widget _entityGenericProfile(Map<String, dynamic> rows) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: rows.entries
          .map((entry) => _entityInfoRow(entry.key, '${entry.value ?? ''}'))
          .toList(),
    );
  }

  Widget _entityAvatar(String url, IconData fallback) {
    final image = url.trim();
    return CircleAvatar(
      radius: 28,
      backgroundColor: const Color(0xFFEAF5ED),
      backgroundImage: image.isEmpty ? null : NetworkImage(image),
      onBackgroundImageError: image.isEmpty ? null : (_, _) {},
      child: image.isEmpty
          ? Icon(fallback, color: const Color(0xFF0B514B), size: 28)
          : null,
    );
  }

  Widget _entityRatings(Map<String, dynamic> ratings) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _entityInfoRow(
          'متوسط التقييم',
          '${ratings['average_rating'] ?? '--'} / 5',
        ),
        _entityInfoRow('عدد التقييمات', '${ratings['ratings_count'] ?? 0}'),
        const SizedBox(height: 16),
        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 54),
      ],
    );
  }

  Widget _entityProducts(List<Map<String, dynamic>> products) {
    if (products.isEmpty) return _entityEmpty('لا توجد منتجات مسجلة');
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: products.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final item = products[index];
        final name = (item['name_ar'] ?? item['name_en'] ?? 'منتج').toString();
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFEAF5ED),
            child: Text('${index + 1}'),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text((item['description'] ?? '').toString()),
          trailing: Text('${item['price'] ?? 0}'),
        );
      },
    );
  }

  Widget _entityFavorites(List<Map<String, dynamic>> favorites) {
    if (favorites.isEmpty) return _entityEmpty('لا توجد عناصر في المفضلة');
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: favorites.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final item = favorites[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.favorite_rounded, color: Color(0xFFD92C2C)),
          title: Text(
            (item['name_ar'] ?? item['name_en'] ?? 'منتج').toString(),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          trailing: Text('${item['price'] ?? 0}'),
        );
      },
    );
  }

  Widget _entityHours(List<Map<String, dynamic>> hours) {
    if (hours.isEmpty) return _entityEmpty('مواعيد العمل غير مسجلة');
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: hours.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final row = hours[index];
        final isOpen = _toInt(row['is_open']) == 1;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.schedule_rounded,
            color: isOpen ? const Color(0xFF1E7D3F) : const Color(0xFFD92C2C),
          ),
          title: Text(
            (row['day_key'] ?? 'اليوم').toString(),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          trailing: Text(
            isOpen
                ? '${row['opens_at'] ?? '--'} - ${row['closes_at'] ?? '--'}'
                : 'مغلق',
          ),
        );
      },
    );
  }

  Widget _entityOrders(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) return _entityEmpty('لا توجد طلبات مرتبطة');
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final order = orders[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(
            Icons.receipt_long_rounded,
            color: Color(0xFF2563EB),
          ),
          title: Text(
            '#${order['id'] ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '${order['customer_name'] ?? 'عميل'} • ${order['status'] ?? ''}',
          ),
          trailing: Text('${order['total'] ?? 0}'),
        );
      },
    );
  }

  Widget _entityEmpty(String message) => Center(
    child: Text(message, style: const TextStyle(color: Color(0xFF6F7680))),
  );

  Widget _entityInfoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6F7680),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'غير متوفر' : value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );

  Widget _entityBadge(String label, dynamic value) => Chip(
    label: Text(
      '$label: $value',
      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700),
    ),
    backgroundColor: Colors.white,
    side: const BorderSide(color: Color(0xFFD7EBDD)),
  );
}
