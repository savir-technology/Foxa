import 'package:admin_tks/model/restaurant_settings_model.dart';
import 'package:admin_tks/remote/restaurant_settings_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WorkingHoursPage extends StatefulWidget {
  const WorkingHoursPage({super.key});

  @override
  State<WorkingHoursPage> createState() => _WorkingHoursPageState();
}

class _WorkingHoursPageState extends State<WorkingHoursPage> {
  final RestaurantSettingsData _data = RestaurantSettingsData();
  final TextEditingController _temporaryReasonCtrl = TextEditingController();
  final TextEditingController _preorderDaysCtrl =
      TextEditingController(text: '7');

  bool _loading = true;
  bool _saving = false;
  bool _isOpen = true;
  bool _acceptsPreorders = true;
  bool _notificationsEnabled = true;
  bool _powerIssue = false;
  bool _maintenance = false;
  bool _outOfStock = false;
  bool _applyToAllBranches = true;
  RestaurantSettingsSnapshot? _snapshot;
  late List<StoreWorkingDay> _workingHours;

  @override
  void initState() {
    super.initState();
    _workingHours = List<StoreWorkingDay>.from(_defaultWorkingHours());
    _load();
  }

  @override
  void dispose() {
    _temporaryReasonCtrl.dispose();
    _preorderDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final snapshot = await _data.getSettings();
      if (!mounted) return;
      if (snapshot != null) {
        _bindSnapshot(snapshot);
      }
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل أوقات العمل: $e')),
      );
    }
  }

  void _bindSnapshot(RestaurantSettingsSnapshot snapshot) {
    _snapshot = snapshot;
    _isOpen = snapshot.isOpen;
    _acceptsPreorders = snapshot.acceptsPreorders;
    _notificationsEnabled = snapshot.notificationsEnabled;
    _workingHours = snapshot.workingHours.isEmpty
        ? List<StoreWorkingDay>.from(_defaultWorkingHours())
        : snapshot.workingHours;
    _temporaryReasonCtrl.text = snapshot.temporaryClosedReason ?? '';
    _preorderDaysCtrl.text = snapshot.preorderDaysLimit.toString();
  }

  void _syncTemporaryReason() {
    final reasons = <String>[];
    if (_powerIssue) reasons.add('عطل كهرباء');
    if (_maintenance) reasons.add('صيانة');
    if (_outOfStock) reasons.add('نفاد المواد');

    setState(() {
      if (reasons.isEmpty) {
        if (_temporaryReasonCtrl.text.trim().contains('عطل كهرباء') ||
            _temporaryReasonCtrl.text.trim().contains('صيانة') ||
            _temporaryReasonCtrl.text.trim().contains('نفاد المواد')) {
          _temporaryReasonCtrl.clear();
        }
      } else {
        _temporaryReasonCtrl.text = reasons.join('، ');
      }
    });
  }

  Future<void> _pickTime(int index, bool openTime) async {
    final current = _workingHours[index];
    final value = openTime ? current.openTime : current.closeTime;
    final parts = value.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.first) ?? 10,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked == null || !mounted) return;

    final formatted = _formatTime(picked);
    setState(() {
      _workingHours[index] = openTime
          ? current.copyWith(openTime: formatted)
          : current.copyWith(closeTime: formatted);
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    final snapshot = _snapshot;
    if (snapshot == null) {
      Get.snackbar(
        'أوقات العمل',
        'لا توجد بيانات حالية للحفظ.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _saving = true);

    final selectedReason = _temporaryReasonCtrl.text.trim().isEmpty
        ? null
        : _temporaryReasonCtrl.text.trim();

    final updated = await _data.updateSettings(
      vendorName: snapshot.vendorName,
      storeName: snapshot.storeName,
      vendorEmail: snapshot.vendorEmail,
      vendorPhone: snapshot.vendorPhone,
      vendorLogo: snapshot.vendorLogo,
      vendorDescription: snapshot.vendorDescription,
      storeBannerUrl: snapshot.storeBannerUrl,
      storeAddress: snapshot.storeAddress,
      coverageKm: snapshot.coverageKm,
      storeLatitude: snapshot.storeLatitude,
      storeLongitude: snapshot.storeLongitude,
      minimumOrder: snapshot.minimumOrder,
      languageCode: snapshot.languageCode,
      isOpen: _isOpen,
      acceptsPreorders: _acceptsPreorders,
      preorderDaysLimit: int.tryParse(_preorderDaysCtrl.text.trim()) ??
          snapshot.preorderDaysLimit,
      notificationsEnabled: _notificationsEnabled,
      temporaryClosedReason: selectedReason,
      workingHours: _workingHours,
    );

    if (!mounted) return;

    setState(() => _saving = false);
    if (updated == null) {
      final apiError = _data.lastError;
      if (apiError != null && apiError.trim().isNotEmpty) {
        debugPrint('[WorkingHours] save failed: $apiError');
      }
      Get.snackbar(
        'أوقات العمل',
        'تعذر حفظ التغييرات الآن.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _bindSnapshot(updated);
    setState(() => _snapshot = updated);
    Get.snackbar(
      'أوقات العمل',
      'تم حفظ التغييرات بنجاح',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final isOpen = snapshot?.isCurrentlyOpen ?? false;
    final statusColor = isOpen ? const Color(0xFF16A34A) : Colors.redAccent;

    return DashboardPageShell(
      title: 'أوقات العمل',
      subtitle: 'متابعة حالة المطعم وجدول العمل الأسبوعي.',
      icon: Icons.schedule_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_saving ? 'جاري الحفظ' : 'حفظ التغييرات'),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'الحالة الحالية',
          value: isOpen ? 'المطعم مفتوح الآن' : 'المطعم مغلق الآن',
          icon: isOpen ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
          tint: statusColor,
          width: 240,
        ),
        DashboardStatCard(
          label: 'الحجز المسبق',
          value: '${_preorderDaysCtrl.text} أيام',
          icon: Icons.event_available_rounded,
          tint: const Color(0xFF0F766E),
          width: 200,
        ),
        DashboardStatCard(
          label: 'الفروع',
          value: '${snapshot?.branchCount ?? 0} فرع',
          icon: Icons.store_mall_directory_rounded,
          tint: kPrimary,
          width: 180,
        ),
        DashboardStatCard(
          label: 'الإشعارات',
          value: _notificationsEnabled ? 'مفعلة' : 'متوقفة',
          icon: Icons.notifications_active_rounded,
          tint: const Color(0xFF3B82F6),
          width: 180,
        ),
      ],
      body: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 96),
              child: Center(child: CircularProgressIndicator(color: kPrimary)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1180;

                    final leftColumn = Column(
                      children: [
                        DashboardPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                title: 'تعيين إغلاق',
                                subtitle:
                                    'تعطيل المطعم مؤقتًا مع تحديد السبب بدقة.',
                                icon: Icons.lock_outline_rounded,
                              ),
                              const SizedBox(height: 16),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: _isOpen,
                                onChanged: (value) => setState(() => _isOpen = value),
                                title: Text(
                                  _isOpen ? 'المطعم مفتوح الآن' : 'المطعم مغلق الآن',
                                ),
                                subtitle: Text(
                                  _isOpen
                                      ? 'الإبقاء على استقبال الطلبات مباشرة.'
                                      : 'ستتوقف الطلبات الجديدة حتى إعادة الفتح.',
                                ),
                                secondary: Icon(
                                  _isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: () => setState(() => _isOpen = !_isOpen),
                                child: Text(
                                  _isOpen ? 'إغلاق المطعم الآن' : 'فتح المطعم الآن',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        DashboardPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                title: 'إغلاق مؤقت',
                                subtitle:
                                    'اختر سبب الإغلاق المؤقت ليظهر في اللوحة والعملاء.',
                                icon: Icons.timer_off_rounded,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _temporaryReasonCtrl,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'سبب الإغلاق المؤقت',
                                  hintText: 'مثال: صيانة المطبخ أو نفاد المواد',
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () => setState(() => _isOpen = false),
                                      child: const Text('إغلاق الآن'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F0F0),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.14)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded,
                                        color: Colors.redAccent.withValues(alpha: 0.9)),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'الحالة الحالية للمطعم',
                                        style: TextStyle(
                                          color: kTextPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      isOpen ? 'المطعم مفتوح الآن' : 'المطعم مغلق الآن',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        DashboardPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(
                                title: 'تعطيل تلقائي للمطعم',
                                subtitle: 'عند تفعيل السبب المختار يصبح الإغلاق سريعًا.',
                                icon: Icons.power_settings_new_rounded,
                              ),
                              const SizedBox(height: 12),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: _powerIssue,
                                onChanged: (value) {
                                  setState(() => _powerIssue = value);
                                  _syncTemporaryReason();
                                },
                                title: const Text('عطل كهرباء'),
                              ),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: _maintenance,
                                onChanged: (value) {
                                  setState(() => _maintenance = value);
                                  _syncTemporaryReason();
                                },
                                title: const Text('صيانة'),
                              ),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: _outOfStock,
                                onChanged: (value) {
                                  setState(() => _outOfStock = value);
                                  _syncTemporaryReason();
                                },
                                title: const Text('نفاد المواد'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final rightColumn = DashboardPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(
                            title: 'أوقات العمل الأسبوعية',
                            subtitle: 'حدد فتح وإغلاق كل يوم بدقة.',
                            icon: Icons.calendar_month_rounded,
                          ),
                          const SizedBox(height: 18),
                          _ScheduleHeader(),
                          const SizedBox(height: 10),
                          ...List.generate(_workingHours.length, (index) {
                            final day = _workingHours[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _DayRow(
                                day: day,
                                onToggle: (value) {
                                  setState(() {
                                    _workingHours[index] =
                                        day.copyWith(isOpen: value);
                                  });
                                },
                                onOpenTap: () => _pickTime(index, true),
                                onCloseTap: () => _pickTime(index, false),
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          const Text(
                            'ملاحظة: سيتم تطبيق أوقات العمل على جميع الفروع.',
                            style: TextStyle(color: kTextSecondary),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DashboardPanel(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'الطلبات المستقبلية',
                                        style: TextStyle(
                                          color: kTextPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'حدد عدد الأيام المسموح بها لحجز الطلبات مسبقًا.',
                                        style: TextStyle(color: kTextSecondary),
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          IconButton.filledTonal(
                                            onPressed: () {
                                              final current =
                                                  int.tryParse(_preorderDaysCtrl.text.trim()) ?? 7;
                                              setState(() => _preorderDaysCtrl.text =
                                                  (current > 1 ? current - 1 : 1)
                                                      .toString());
                                            },
                                            icon: const Icon(Icons.remove_rounded),
                                          ),
                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                _preorderDaysCtrl.text,
                                                style: const TextStyle(
                                                  color: kTextPrimary,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ),
                                          IconButton.filledTonal(
                                            onPressed: () {
                                              final current =
                                                  int.tryParse(_preorderDaysCtrl.text.trim()) ?? 7;
                                              setState(() => _preorderDaysCtrl.text =
                                                  (current + 1).toString());
                                            },
                                            icon: const Icon(Icons.add_rounded),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DashboardPanel(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'تطبيق مؤقت لإغلاق',
                                        style: TextStyle(
                                          color: kTextPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      RadioListTile<bool>(
                                        contentPadding: EdgeInsets.zero,
                                        value: true,
                                        groupValue: _applyToAllBranches,
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(() => _applyToAllBranches = value);
                                        },
                                        title: const Text('تطبيق على جميع الفروع'),
                                      ),
                                      RadioListTile<bool>(
                                        contentPadding: EdgeInsets.zero,
                                        value: false,
                                        groupValue: _applyToAllBranches,
                                        onChanged: (value) {
                                          if (value == null) return;
                                          setState(() => _applyToAllBranches = value);
                                        },
                                        title: const Text('تطبيق على فرع محدد فقط'),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF7E8),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: const Color(0xFFF59E0B)
                                                .withValues(alpha: 0.18),
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.info_outline_rounded,
                                                color: Color(0xFFD97706)),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                'سيتم إغلاق جميع الفروع المحددة خلال المدة المطلوبة.',
                                                style: TextStyle(
                                                  color: kTextPrimary,
                                                  fontWeight: FontWeight.w600,
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
                            ],
                          ),
                        ],
                      ),
                    );

                    if (!wide) {
                      return Column(
                        children: [
                          leftColumn,
                          const SizedBox(height: 16),
                          rightColumn,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 360, child: leftColumn),
                        const SizedBox(width: 16),
                        Expanded(child: rightColumn),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: SizedBox(
                    width: 280,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'جاري الحفظ' : 'حفظ التغييرات'),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: kPrimary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: kTextSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduleHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(flex: 3, child: Text('اليوم', textAlign: TextAlign.right)),
        Expanded(flex: 2, child: Text('من', textAlign: TextAlign.center)),
        Expanded(flex: 2, child: Text('إلى', textAlign: TextAlign.center)),
        Expanded(flex: 2, child: Text('مفتوح / مغلق', textAlign: TextAlign.center)),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.onToggle,
    required this.onOpenTap,
    required this.onCloseTap,
  });

  final StoreWorkingDay day;
  final ValueChanged<bool> onToggle;
  final VoidCallback onOpenTap;
  final VoidCallback onCloseTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: day.isOpen ? const Color(0xFFF9FBF9) : const Color(0xFFF6F7F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              day.dayLabel,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: kTextPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: _TimeField(
              value: day.openTime,
              enabled: day.isOpen,
              onTap: onOpenTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: _TimeField(
              value: day.closeTime,
              enabled: day.isOpen,
              onTap: onCloseTap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Center(
              child: Switch.adaptive(
                value: day.isOpen,
                onChanged: onToggle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF0F2F0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kStroke),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: enabled ? kTextPrimary : kTextSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.access_time_rounded, size: 16, color: kTextSecondary),
          ],
        ),
      ),
    );
  }
}

String _formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

List<StoreWorkingDay> _defaultWorkingHours() {
  return const [
    StoreWorkingDay(
      dayKey: 'mon',
      dayLabel: 'الاثنين',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:00',
    ),
    StoreWorkingDay(
      dayKey: 'tue',
      dayLabel: 'الثلاثاء',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:00',
    ),
    StoreWorkingDay(
      dayKey: 'wed',
      dayLabel: 'الأربعاء',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:00',
    ),
    StoreWorkingDay(
      dayKey: 'thu',
      dayLabel: 'الخميس',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:00',
    ),
    StoreWorkingDay(
      dayKey: 'fri',
      dayLabel: 'الجمعة',
      isOpen: true,
      openTime: '12:00',
      closeTime: '23:30',
    ),
    StoreWorkingDay(
      dayKey: 'sat',
      dayLabel: 'السبت',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:00',
    ),
    StoreWorkingDay(
      dayKey: 'sun',
      dayLabel: 'الأحد',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:00',
    ),
  ];
}
