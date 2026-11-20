import 'dart:convert';
import 'dart:typed_data';

import 'package:admin_tks/core/services/dashboard_session_service.dart';
import 'package:admin_tks/model/restaurant_settings_model.dart';
import 'package:admin_tks/remote/restaurant_settings_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/app_network_image.dart';
import 'package:admin_tks/widgets/dashboard_map_box.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RestaurantSettingsPage extends StatefulWidget {
  const RestaurantSettingsPage({super.key});

  @override
  State<RestaurantSettingsPage> createState() => _RestaurantSettingsPageState();
}

class _RestaurantSettingsPageState extends State<RestaurantSettingsPage> {
  final RestaurantSettingsData _data = RestaurantSettingsData();

  final _storeNameCtrl = TextEditingController();
  final _vendorNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'مصر');
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _coverageCtrl = TextEditingController();
  final _minimumDeliveryCtrl = TextEditingController(text: '0');
  final _minimumPickupCtrl = TextEditingController(text: '0');
  final _facebookCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();

  RestaurantSettingsSnapshot? _snapshot;
  List<StoreWorkingDay> _workingHours = _defaultWorkingHours();
  bool _loading = true;
  bool _saving = false;
  bool _isOpen = true;
  bool _acceptsDelivery = true;
  bool _acceptsPickup = true;
  bool _notificationsEnabled = true;
  bool _temporarilyClosed = false;
  String _languageCode = 'ar';
  String _currency = 'SAR';
  String _timezone = 'Africa/Cairo';
  String _dateFormat = 'YYYY/MM/DD';
  Uint8List? _logoBytes;
  String? _logoFileName;
  Uint8List? _bannerBytes;
  String? _bannerFileName;

  DashboardSession? get _session =>
      DashboardSessionService.instance.currentSession;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _vendorNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _taxCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _countryCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _streetCtrl.dispose();
    _coverageCtrl.dispose();
    _minimumDeliveryCtrl.dispose();
    _minimumPickupCtrl.dispose();
    _facebookCtrl.dispose();
    _instagramCtrl.dispose();
    _youtubeCtrl.dispose();
    _tiktokCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final snapshot = await _data.getSettings();
    if (!mounted) return;

    if (snapshot == null) {
      setState(() => _loading = false);
      _showSnack('تعذر تحميل إعدادات المطعم من الخادم.');
      return;
    }

    _bind(snapshot);
    setState(() {
      _snapshot = snapshot;
      _loading = false;
    });
  }

  void _bind(RestaurantSettingsSnapshot snapshot) {
    String extra(String key, [String fallback = '']) =>
        snapshot.profileSettings[key]?.toString().trim() ?? fallback;

    _storeNameCtrl.text = snapshot.storeName;
    _vendorNameCtrl.text = snapshot.vendorName;
    _descriptionCtrl.text = snapshot.vendorDescription ?? '';
    _taxCtrl.text = extra('tax_number');
    _phoneCtrl.text = snapshot.vendorPhone;
    _whatsappCtrl.text = extra('whatsapp_phone', snapshot.vendorPhone);
    _emailCtrl.text = snapshot.vendorEmail;
    _websiteCtrl.text = extra('website_url');
    _countryCtrl.text = 'مصر';
    _cityCtrl.text = _safeEgyptLocation(
      extra('city', _guessCity(snapshot.storeAddress)),
      fallback: 'القاهرة',
    );
    _districtCtrl.text = _safeEgyptLocation(
      extra('district', _guessDistrict(snapshot.storeAddress)),
      fallback: 'القاهرة',
    );
    _streetCtrl.text = _safeEgyptLocation(
      extra('street', snapshot.storeAddress ?? ''),
      fallback: '',
    );
    _coverageCtrl.text = (snapshot.coverageArea?.trim().isNotEmpty ?? false)
        ? snapshot.coverageArea!.trim()
        : (snapshot.coverageKm?.toStringAsFixed(0) ?? '');
    _minimumDeliveryCtrl.text = snapshot.minimumOrder.toStringAsFixed(0);
    _minimumPickupCtrl.text = extra('minimum_pickup', '0');
    _facebookCtrl.text = extra('facebook_url');
    _instagramCtrl.text = extra('instagram_url');
    _youtubeCtrl.text = extra('youtube_url');
    _tiktokCtrl.text = extra('tiktok_url');
    _isOpen = snapshot.isOpen;
    _notificationsEnabled = snapshot.notificationsEnabled;
    _temporarilyClosed = !snapshot.isOpen;
    _acceptsDelivery = extra('accepts_delivery', '1') == '1';
    _acceptsPickup = extra('accepts_pickup', '1') == '1';
    _languageCode =
        snapshot.languageCode.isEmpty ? 'ar' : snapshot.languageCode;
    _currency = extra('currency_code', 'SAR');
    _timezone = extra('timezone', 'Africa/Cairo');
    _dateFormat = extra('date_format', 'DD/MM/YYYY');
    _workingHours = snapshot.workingHours.isEmpty
        ? _defaultWorkingHours()
        : List<StoreWorkingDay>.from(snapshot.workingHours);
    _logoBytes = null;
    _logoFileName = null;
    _bannerBytes = null;
    _bannerFileName = null;
  }

  Future<void> _save() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    final session = _session;
    final current = _snapshot;
    if (session == null && current == null) {
      _showSnack('لا توجد جلسة فعالة للحفظ.');
      return;
    }

    setState(() => _saving = true);
    final updated = await _data.updateSettings(
      vendorName: _vendorNameCtrl.text.trim().isEmpty
          ? (current?.vendorName ?? session?.vendorName ?? '')
          : _vendorNameCtrl.text.trim(),
      storeName: _storeNameCtrl.text.trim().isEmpty
          ? (current?.storeName ?? session?.storeName ?? '')
          : _storeNameCtrl.text.trim(),
      vendorEmail: _emailCtrl.text.trim().isEmpty
          ? (current?.vendorEmail ?? session?.email ?? '')
          : _emailCtrl.text.trim(),
      vendorPhone: _phoneCtrl.text.trim(),
      vendorLogo: current?.vendorLogo,
      vendorLogoBase64: _logoBytes == null ? null : base64Encode(_logoBytes!),
      vendorDescription: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      storeBannerUrl: current?.storeBannerUrl,
      storeBannerBase64:
          _bannerBytes == null ? null : base64Encode(_bannerBytes!),
      storeAddress: [
        _countryCtrl.text.trim(),
        _cityCtrl.text.trim(),
        _districtCtrl.text.trim(),
        _streetCtrl.text.trim(),
      ].where((part) => part.isNotEmpty).join('، '),
      coverageArea: _coverageCtrl.text.trim(),
      coverageKm: double.tryParse(
        RegExp(r'-?\d+(?:[.,]\d+)?')
                .firstMatch(_coverageCtrl.text.trim())
                ?.group(0)
                ?.replaceAll(',', '.') ??
            '',
      ),
      storeLatitude: current?.storeLatitude,
      storeLongitude: current?.storeLongitude,
      minimumOrder: double.tryParse(_minimumDeliveryCtrl.text.trim()) ?? 0,
      languageCode: _languageCode,
      isOpen: _isOpen && !_temporarilyClosed,
      acceptsPreorders: current?.acceptsPreorders ?? true,
      preorderDaysLimit: current?.preorderDaysLimit ?? 7,
      notificationsEnabled: _notificationsEnabled,
      temporaryClosedReason:
          _temporarilyClosed ? 'مطعم مغلق مؤقتاً من لوحة التحكم' : null,
      workingHours: _workingHours,
      profileSettings: {
        'tax_number': _taxCtrl.text.trim(),
        'whatsapp_phone': _whatsappCtrl.text.trim(),
        'website_url': _websiteCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'street': _streetCtrl.text.trim(),
        'minimum_pickup': _minimumPickupCtrl.text.trim(),
        'facebook_url': _facebookCtrl.text.trim(),
        'instagram_url': _instagramCtrl.text.trim(),
        'youtube_url': _youtubeCtrl.text.trim(),
        'tiktok_url': _tiktokCtrl.text.trim(),
        'accepts_delivery': _acceptsDelivery ? 1 : 0,
        'accepts_pickup': _acceptsPickup ? 1 : 0,
        'currency_code': _currency,
        'timezone': _timezone,
        'date_format': _dateFormat,
      },
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (updated == null) {
      final reason = _data.lastError;
      _showSnack(
        reason == null || reason.trim().isEmpty
            ? 'تعذر حفظ الإعدادات الآن.'
            : 'تعذر حفظ الإعدادات: $reason',
      );
      return;
    }

    _bind(updated);
    setState(() => _snapshot = updated);
    _showSnack('تم حفظ إعدادات المطعم بنجاح.');
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _logoBytes = file.bytes;
      _logoFileName = file.name;
    });
  }

  Future<void> _pickBanner() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _bannerBytes = file.bytes;
      _bannerFileName = file.name;
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    Get.snackbar(
      'Roaq',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black.withValues(alpha: .82),
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return DashboardPageShell(
      title: 'إعدادات المطعم',
      subtitle: 'إدارة إعدادات ومعلومات المطعم',
      icon: Icons.settings_rounded,
      activeSidebarIndex: 11,
      actions: [
        IconButton.filledTonal(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_saving ? 'جارٍ الحفظ' : 'حفظ جميع الإعدادات'),
        ),
      ],
      body: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 90),
              child: Center(child: CircularProgressIndicator(color: kPrimary)),
            )
          : snapshot == null
              ? const DashboardEmptyState(
                  title: 'تعذر تحميل إعدادات المطعم',
                  subtitle: 'تحقق من الاتصال ثم حاول مرة أخرى.',
                  icon: Icons.cloud_off_rounded,
                )
              : _SettingsGrid(
                  snapshot: snapshot,
                  logoBytes: _logoBytes,
                  logoFileName: _logoFileName,
                  bannerBytes: _bannerBytes,
                  bannerFileName: _bannerFileName,
                  storeNameCtrl: _storeNameCtrl,
                  vendorNameCtrl: _vendorNameCtrl,
                  descriptionCtrl: _descriptionCtrl,
                  taxCtrl: _taxCtrl,
                  phoneCtrl: _phoneCtrl,
                  whatsappCtrl: _whatsappCtrl,
                  emailCtrl: _emailCtrl,
                  websiteCtrl: _websiteCtrl,
                  countryCtrl: _countryCtrl,
                  cityCtrl: _cityCtrl,
                  districtCtrl: _districtCtrl,
                  streetCtrl: _streetCtrl,
                  coverageCtrl: _coverageCtrl,
                  minimumDeliveryCtrl: _minimumDeliveryCtrl,
                  minimumPickupCtrl: _minimumPickupCtrl,
                  facebookCtrl: _facebookCtrl,
                  instagramCtrl: _instagramCtrl,
                  youtubeCtrl: _youtubeCtrl,
                  tiktokCtrl: _tiktokCtrl,
                  workingHours: _workingHours,
                  isOpen: _isOpen,
                  acceptsDelivery: _acceptsDelivery,
                  acceptsPickup: _acceptsPickup,
                  notificationsEnabled: _notificationsEnabled,
                  temporarilyClosed: _temporarilyClosed,
                  languageCode: _languageCode,
                  currency: _currency,
                  timezone: _timezone,
                  dateFormat: _dateFormat,
                  onPickLogo: _pickLogo,
                  onPickBanner: _pickBanner,
                  onOpenChanged: (value) => setState(() => _isOpen = value),
                  onAcceptsDeliveryChanged: (value) =>
                      setState(() => _acceptsDelivery = value),
                  onAcceptsPickupChanged: (value) =>
                      setState(() => _acceptsPickup = value),
                  onNotificationsChanged: (value) =>
                      setState(() => _notificationsEnabled = value),
                  onTemporarilyClosedChanged: (value) =>
                      setState(() => _temporarilyClosed = value),
                  onLanguageChanged: (value) =>
                      setState(() => _languageCode = value ?? _languageCode),
                  onCurrencyChanged: (value) =>
                      setState(() => _currency = value ?? _currency),
                  onTimezoneChanged: (value) =>
                      setState(() => _timezone = value ?? _timezone),
                  onDateFormatChanged: (value) =>
                      setState(() => _dateFormat = value ?? _dateFormat),
                  onLocationChanged: (latitude, longitude) {
                    final currentSnapshot = _snapshot;
                    if (currentSnapshot == null) return;
                    setState(() {
                      _snapshot = currentSnapshot.copyWith(
                        storeLatitude: latitude,
                        storeLongitude: longitude,
                      );
                    });
                  },
                  onWorkingDayChanged: (index, day) =>
                      setState(() => _workingHours[index] = day),
                  onSave: _save,
                ),
    );
  }
}

class _SettingsGrid extends StatelessWidget {
  const _SettingsGrid({
    required this.snapshot,
    required this.logoBytes,
    required this.logoFileName,
    required this.bannerBytes,
    required this.bannerFileName,
    required this.storeNameCtrl,
    required this.vendorNameCtrl,
    required this.descriptionCtrl,
    required this.taxCtrl,
    required this.phoneCtrl,
    required this.whatsappCtrl,
    required this.emailCtrl,
    required this.websiteCtrl,
    required this.countryCtrl,
    required this.cityCtrl,
    required this.districtCtrl,
    required this.streetCtrl,
    required this.coverageCtrl,
    required this.minimumDeliveryCtrl,
    required this.minimumPickupCtrl,
    required this.facebookCtrl,
    required this.instagramCtrl,
    required this.youtubeCtrl,
    required this.tiktokCtrl,
    required this.workingHours,
    required this.isOpen,
    required this.acceptsDelivery,
    required this.acceptsPickup,
    required this.notificationsEnabled,
    required this.temporarilyClosed,
    required this.languageCode,
    required this.currency,
    required this.timezone,
    required this.dateFormat,
    required this.onPickLogo,
    required this.onPickBanner,
    required this.onOpenChanged,
    required this.onAcceptsDeliveryChanged,
    required this.onAcceptsPickupChanged,
    required this.onNotificationsChanged,
    required this.onTemporarilyClosedChanged,
    required this.onLanguageChanged,
    required this.onCurrencyChanged,
    required this.onTimezoneChanged,
    required this.onDateFormatChanged,
    required this.onLocationChanged,
    required this.onWorkingDayChanged,
    required this.onSave,
  });

  final RestaurantSettingsSnapshot snapshot;
  final Uint8List? logoBytes;
  final String? logoFileName;
  final Uint8List? bannerBytes;
  final String? bannerFileName;
  final TextEditingController storeNameCtrl;
  final TextEditingController vendorNameCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController taxCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController whatsappCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController websiteCtrl;
  final TextEditingController countryCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController districtCtrl;
  final TextEditingController streetCtrl;
  final TextEditingController coverageCtrl;
  final TextEditingController minimumDeliveryCtrl;
  final TextEditingController minimumPickupCtrl;
  final TextEditingController facebookCtrl;
  final TextEditingController instagramCtrl;
  final TextEditingController youtubeCtrl;
  final TextEditingController tiktokCtrl;
  final List<StoreWorkingDay> workingHours;
  final bool isOpen;
  final bool acceptsDelivery;
  final bool acceptsPickup;
  final bool notificationsEnabled;
  final bool temporarilyClosed;
  final String languageCode;
  final String currency;
  final String timezone;
  final String dateFormat;
  final VoidCallback onPickLogo;
  final VoidCallback onPickBanner;
  final ValueChanged<bool> onOpenChanged;
  final ValueChanged<bool> onAcceptsDeliveryChanged;
  final ValueChanged<bool> onAcceptsPickupChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onTemporarilyClosedChanged;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<String?> onTimezoneChanged;
  final ValueChanged<String?> onDateFormatChanged;
  final void Function(double latitude, double longitude) onLocationChanged;
  final void Function(int index, StoreWorkingDay day) onWorkingDayChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1180;
        final medium = constraints.maxWidth >= 820;
        final logo = _LogoSettingsCard(
          snapshot: snapshot,
          logoBytes: logoBytes,
          logoFileName: logoFileName,
          bannerBytes: bannerBytes,
          bannerFileName: bannerFileName,
          onPickLogo: onPickLogo,
          onPickBanner: onPickBanner,
        );
        final info = _RestaurantInfoCard(
          storeNameCtrl: storeNameCtrl,
          vendorNameCtrl: vendorNameCtrl,
          descriptionCtrl: descriptionCtrl,
          taxCtrl: taxCtrl,
          onSave: onSave,
        );
        final contact = _ContactInfoCard(
          phoneCtrl: phoneCtrl,
          whatsappCtrl: whatsappCtrl,
          emailCtrl: emailCtrl,
          websiteCtrl: websiteCtrl,
        );
        final address = _AddressCard(
          snapshot: snapshot,
          countryCtrl: countryCtrl,
          cityCtrl: cityCtrl,
          districtCtrl: districtCtrl,
          streetCtrl: streetCtrl,
          onLocationChanged: onLocationChanged,
        );
        final coverage = _CoverageCard(
          coverageCtrl: coverageCtrl,
          acceptsDelivery: acceptsDelivery,
          acceptsPickup: acceptsPickup,
          onAcceptsDeliveryChanged: onAcceptsDeliveryChanged,
          onAcceptsPickupChanged: onAcceptsPickupChanged,
        );
        final minimum = _MinimumOrderCard(
          deliveryCtrl: minimumDeliveryCtrl,
          pickupCtrl: minimumPickupCtrl,
        );
        final hours = _WorkingHoursCard(
          workingHours: workingHours,
          isOpen: isOpen,
          temporarilyClosed: temporarilyClosed,
          onOpenChanged: onOpenChanged,
          onTemporarilyClosedChanged: onTemporarilyClosedChanged,
          onWorkingDayChanged: onWorkingDayChanged,
        );
        final social = _SocialLinksCard(
          facebookCtrl: facebookCtrl,
          instagramCtrl: instagramCtrl,
          youtubeCtrl: youtubeCtrl,
          tiktokCtrl: tiktokCtrl,
        );
        final prefs = _PreferencesCard(
          languageCode: languageCode,
          currency: currency,
          timezone: timezone,
          dateFormat: dateFormat,
          notificationsEnabled: notificationsEnabled,
          onLanguageChanged: onLanguageChanged,
          onCurrencyChanged: onCurrencyChanged,
          onTimezoneChanged: onTimezoneChanged,
          onDateFormatChanged: onDateFormatChanged,
          onNotificationsChanged: onNotificationsChanged,
          onSave: onSave,
        );

        if (!medium) {
          return Column(
            children: [
              logo,
              const SizedBox(height: 12),
              info,
              const SizedBox(height: 12),
              contact,
              const SizedBox(height: 12),
              address,
              const SizedBox(height: 12),
              coverage,
              const SizedBox(height: 12),
              minimum,
              const SizedBox(height: 12),
              hours,
              const SizedBox(height: 12),
              social,
              const SizedBox(height: 12),
              prefs,
            ],
          );
        }

        if (!wide) {
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: logo),
                  const SizedBox(width: 12),
                  Expanded(child: contact),
                ],
              ),
              const SizedBox(height: 12),
              info,
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: address),
                  const SizedBox(width: 12),
                  Expanded(child: coverage),
                ],
              ),
              const SizedBox(height: 12),
              minimum,
              const SizedBox(height: 12),
              hours,
              const SizedBox(height: 12),
              social,
              const SizedBox(height: 12),
              prefs,
            ],
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: logo),
                const SizedBox(width: 12),
                Expanded(flex: 5, child: info),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: contact),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: address),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: coverage),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: minimum),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: hours),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: social),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: prefs),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'يمكنك إدارة معلومات مطعمك وتحديث الإعدادات في أي وقت.',
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LogoSettingsCard extends StatelessWidget {
  const _LogoSettingsCard({
    required this.snapshot,
    required this.logoBytes,
    required this.logoFileName,
    required this.bannerBytes,
    required this.bannerFileName,
    required this.onPickLogo,
    required this.onPickBanner,
  });

  final RestaurantSettingsSnapshot snapshot;
  final Uint8List? logoBytes;
  final String? logoFileName;
  final Uint8List? bannerBytes;
  final String? bannerFileName;
  final VoidCallback onPickLogo;
  final VoidCallback onPickBanner;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'الشعار والغلاف',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 120,
              height: 120,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAF8),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: kStroke,
                  style: BorderStyle.solid,
                ),
              ),
              child: logoBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.memory(logoBytes!, fit: BoxFit.cover),
                    )
                  : AppNetworkImage(
                      imageUrl: snapshot.vendorLogo ?? '',
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(13),
                      placeholderIcon: Icons.storefront_rounded,
                    ),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onPickLogo,
            icon: const Icon(Icons.cloud_upload_outlined, size: 17),
            label: Text(
              logoFileName == null ? 'تغيير الشعار' : logoFileName!,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'صورة غلاف المطعم',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: kTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 96,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAF8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kStroke),
            ),
            child: bannerBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.memory(
                      bannerBytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : AppNetworkImage(
                    imageUrl: snapshot.storeBannerUrl ?? '',
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(13),
                    placeholderIcon: Icons.image_rounded,
                  ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onPickBanner,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 17),
            label: Text(
              bannerFileName == null ? 'تغيير صورة الغلاف' : bannerFileName!,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'PNG, JPG, SVG | الحد الأقصى 2MB',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _RestaurantInfoCard extends StatelessWidget {
  const _RestaurantInfoCard({
    required this.storeNameCtrl,
    required this.vendorNameCtrl,
    required this.descriptionCtrl,
    required this.taxCtrl,
    required this.onSave,
  });

  final TextEditingController storeNameCtrl;
  final TextEditingController vendorNameCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController taxCtrl;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'معلومات المطعم',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SmallField(
                  controller: storeNameCtrl,
                  label: 'الاسم *',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SmallField(
                  controller: taxCtrl,
                  label: 'الرقم الضريبي (إن وجد)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SmallField(
                  controller: vendorNameCtrl,
                  label: 'المالك الفعلي *',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SmallField(
                  controller: descriptionCtrl,
                  label: 'الوصف *',
                  maxLines: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save_rounded, size: 17),
              label: const Text('حفظ التغييرات'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  const _ContactInfoCard({
    required this.phoneCtrl,
    required this.whatsappCtrl,
    required this.emailCtrl,
    required this.websiteCtrl,
  });

  final TextEditingController phoneCtrl;
  final TextEditingController whatsappCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController websiteCtrl;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'معلومات التواصل',
      child: Column(
        children: [
          _SmallField(
            controller: phoneCtrl,
            label: 'رقم الهاتف *',
            icon: Icons.phone_rounded,
          ),
          const SizedBox(height: 10),
          _SmallField(
            controller: whatsappCtrl,
            label: 'رقم واتساب',
            icon: Icons.chat_rounded,
          ),
          const SizedBox(height: 10),
          _SmallField(
            controller: emailCtrl,
            label: 'البريد الإلكتروني',
            icon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 10),
          _SmallField(
            controller: websiteCtrl,
            label: 'الموقع الإلكتروني (إن وجد)',
            icon: Icons.language_rounded,
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.snapshot,
    required this.countryCtrl,
    required this.cityCtrl,
    required this.districtCtrl,
    required this.streetCtrl,
    required this.onLocationChanged,
  });

  final RestaurantSettingsSnapshot snapshot;
  final TextEditingController countryCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController districtCtrl;
  final TextEditingController streetCtrl;
  final void Function(double latitude, double longitude) onLocationChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'عنوان المطعم',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child:
                      _SmallField(controller: countryCtrl, label: 'الدولة *')),
              const SizedBox(width: 8),
              Expanded(
                  child:
                      _SmallField(controller: cityCtrl, label: 'المحافظة *')),
              const SizedBox(width: 8),
              Expanded(
                  child: _SmallField(
                      controller: districtCtrl, label: 'المدينة *')),
            ],
          ),
          const SizedBox(height: 10),
          _SmallField(controller: streetCtrl, label: 'الشارع'),
          const SizedBox(height: 10),
          DashboardMapBox(
            latitude: snapshot.storeLatitude,
            longitude: snapshot.storeLongitude,
            title: 'موقع المطعم',
            subtitle: [
              countryCtrl.text.trim(),
              cityCtrl.text.trim(),
              districtCtrl.text.trim(),
              streetCtrl.text.trim(),
            ].where((part) => part.isNotEmpty).join('، '),
            height: 116,
            interactive: true,
            onMapTap: onLocationChanged,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: snapshot.storeLatitude == null
                ? null
                : () => onLocationChanged(
                      snapshot.storeLatitude!,
                      snapshot.storeLongitude ?? 0,
                    ),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 17),
            label: const Text('تحديد الموقع على الخريطة'),
          ),
        ],
      ),
    );
  }
}

class _CoverageCard extends StatelessWidget {
  const _CoverageCard({
    required this.coverageCtrl,
    required this.acceptsDelivery,
    required this.acceptsPickup,
    required this.onAcceptsDeliveryChanged,
    required this.onAcceptsPickupChanged,
  });

  final TextEditingController coverageCtrl;
  final bool acceptsDelivery;
  final bool acceptsPickup;
  final ValueChanged<bool> onAcceptsDeliveryChanged;
  final ValueChanged<bool> onAcceptsPickupChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'نطاق التغطية',
      subtitle: 'حدد المناطق التي تخدمها في التوصيل والاستلام',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _CheckOption(
                  label: 'استلام ذاتي',
                  value: acceptsPickup,
                  enabled: false,
                  onChanged: onAcceptsPickupChanged,
                ),
                const SizedBox(width: 18),
                _CheckOption(
                  label: 'توصيل',
                  value: acceptsDelivery,
                  enabled: false,
                  onChanged: onAcceptsDeliveryChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SmallField(
            controller: coverageCtrl,
            label: 'المناطق التي نخدمها *',
            icon: Icons.map_rounded,
            readOnly: false,
            enabled: true,
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: coverageCtrl,
            builder: (context, value, child) => Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                for (final area in _coverageAreasFromText(value.text))
                  _AreaChip(area),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'نطاق التغطية للعرض فقط. تتم إضافة وتعديل المناطق من لوحة الماستر.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.redAccent, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MinimumOrderCard extends StatelessWidget {
  const _MinimumOrderCard({
    required this.deliveryCtrl,
    required this.pickupCtrl,
  });

  final TextEditingController deliveryCtrl;
  final TextEditingController pickupCtrl;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'الحد الأدنى للطلب',
      child: Column(
        children: [
          _SmallField(
            controller: deliveryCtrl,
            label: 'الحد الأدنى للطلب للتوصيل',
            suffix: 'SAR',
          ),
          const SizedBox(height: 12),
          _SmallField(
            controller: pickupCtrl,
            label: 'الحد الأدنى للطلب للاستلام',
            suffix: 'SAR',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kPrimary.withValues(alpha: .25)),
            ),
            child: const Row(
              textDirection: TextDirection.rtl,
              children: [
                Icon(Icons.info_outline_rounded, color: kPrimary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'لن يتم قبول الطلبات التي تقل عن الحد الأدنى المحدد لكل خدمة.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: kPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
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

class _WorkingHoursCard extends StatelessWidget {
  const _WorkingHoursCard({
    required this.workingHours,
    required this.isOpen,
    required this.temporarilyClosed,
    required this.onOpenChanged,
    required this.onTemporarilyClosedChanged,
    required this.onWorkingDayChanged,
  });

  final List<StoreWorkingDay> workingHours;
  final bool isOpen;
  final bool temporarilyClosed;
  final ValueChanged<bool> onOpenChanged;
  final ValueChanged<bool> onTemporarilyClosedChanged;
  final void Function(int index, StoreWorkingDay day) onWorkingDayChanged;

  @override
  Widget build(BuildContext context) {
    final firstOpen = workingHours.firstWhere(
      (day) => day.isOpen,
      orElse: () => workingHours.first,
    );

    return _SettingsCard(
      title: 'أوقات العمل',
      subtitle: 'حدد ساعات عمل مطعمك بشكل عام',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    _TimeDisplay(label: 'وقت الفتح', value: firstOpen.openTime),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeDisplay(
                    label: 'وقت الإغلاق', value: firstOpen.closeTime),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < workingHours.length; i++)
                ChoiceChip(
                  label: Text(workingHours[i].dayLabel),
                  selected: workingHours[i].isOpen,
                  onSelected: (selected) => onWorkingDayChanged(
                    i,
                    workingHours[i].copyWith(isOpen: selected),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _CheckOption(
            label: 'مطعم مفتوح الآن',
            value: isOpen,
            onChanged: onOpenChanged,
          ),
          _CheckOption(
            label: 'مطعم مغلق مؤقتاً',
            value: temporarilyClosed,
            onChanged: onTemporarilyClosedChanged,
          ),
        ],
      ),
    );
  }
}

class _SocialLinksCard extends StatelessWidget {
  const _SocialLinksCard({
    required this.facebookCtrl,
    required this.instagramCtrl,
    required this.youtubeCtrl,
    required this.tiktokCtrl,
  });

  final TextEditingController facebookCtrl;
  final TextEditingController instagramCtrl;
  final TextEditingController youtubeCtrl;
  final TextEditingController tiktokCtrl;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'الوسائط الاجتماعية',
      subtitle: 'روابط صفحاتك على وسائل التواصل الاجتماعي',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child:
                      _SmallField(controller: facebookCtrl, label: 'فيسبوك')),
              const SizedBox(width: 10),
              Expanded(
                  child: _SmallField(
                      controller: instagramCtrl, label: 'انستغرام')),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _SmallField(controller: youtubeCtrl, label: 'يوتيوب')),
              const SizedBox(width: 10),
              Expanded(
                  child: _SmallField(controller: tiktokCtrl, label: 'تيك توك')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({
    required this.languageCode,
    required this.currency,
    required this.timezone,
    required this.dateFormat,
    required this.notificationsEnabled,
    required this.onLanguageChanged,
    required this.onCurrencyChanged,
    required this.onTimezoneChanged,
    required this.onDateFormatChanged,
    required this.onNotificationsChanged,
    required this.onSave,
  });

  final String languageCode;
  final String currency;
  final String timezone;
  final String dateFormat;
  final bool notificationsEnabled;
  final ValueChanged<String?> onLanguageChanged;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<String?> onTimezoneChanged;
  final ValueChanged<String?> onDateFormatChanged;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      title: 'اللغة والتفضيلات',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SmallDropdown(
                  label: 'اللغة',
                  value: languageCode,
                  items: const {
                    'ar': 'العربية',
                    'en': 'English',
                  },
                  onChanged: onLanguageChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallDropdown(
                  label: 'العملة',
                  value: currency,
                  items: const {
                    'SAR': 'الريال السعودي',
                    'USD': 'دولار',
                  },
                  onChanged: onCurrencyChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SmallDropdown(
                  label: 'شكل التاريخ',
                  value: dateFormat,
                  items: const {
                    'YYYY/MM/DD': 'YYYY/MM/DD',
                    'DD/MM/YYYY': 'DD/MM/YYYY',
                  },
                  onChanged: onDateFormatChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SmallDropdown(
                  label: 'المنطقة الزمنية',
                  value: timezone,
                  items: const {
                    'Africa/Cairo': 'Africa/Cairo (GMT +02:00/+03:00)',
                    '(GMT +03:00)': '(GMT +03:00)',
                    '(GMT +02:00)': '(GMT +02:00)',
                  },
                  onChanged: onTimezoneChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CheckOption(
            label: 'إشعارات المطعم مفعلة',
            value: notificationsEnabled,
            onChanged: onNotificationsChanged,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save_rounded, size: 17),
            label: const Text('حفظ جميع الإعدادات'),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.right,
              style: const TextStyle(color: kTextSecondary, fontSize: 11),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SmallField extends StatelessWidget {
  const _SmallField({
    required this.controller,
    required this.label,
    this.icon,
    this.suffix,
    this.maxLines = 1,
    this.readOnly = false,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final String? suffix;
  final int maxLines;
  final bool readOnly;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      enabled: enabled,
      textAlign: TextAlign.right,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon == null ? null : Icon(icon, size: 17),
        suffixText: suffix,
      ),
    );
  }
}

class _SmallDropdown extends StatelessWidget {
  const _SmallDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedValue = items.containsKey(value) ? value : items.keys.first;
    return DropdownButtonFormField<String>(
      initialValue: selectedValue,
      decoration: InputDecoration(labelText: label),
      items: items.entries
          .map(
            (entry) => DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _CheckOption extends StatelessWidget {
  const _CheckOption({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        Checkbox(
          value: value,
          onChanged: enabled ? (next) => onChanged(next ?? value) : null,
        ),
        Text(
          label,
          style: TextStyle(
            color: enabled ? kTextPrimary : kTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _AreaChip extends StatelessWidget {
  const _AreaChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      side: BorderSide(color: kPrimary.withValues(alpha: .22)),
      backgroundColor: kPrimary.withValues(alpha: .06),
    );
  }
}

List<String> _coverageAreasFromText(String value) {
  final raw = value.trim();
  if (raw.isEmpty) {
    return const ['لم يتم تحديد مناطق بعد'];
  }

  final number = double.tryParse(raw.replaceAll(',', '.'));
  if (number != null) {
    final label = number == number.roundToDouble()
        ? number.toStringAsFixed(0)
        : number.toStringAsFixed(1);
    return ['نطاق $label كم'];
  }

  final areas = raw
      .split(RegExp(r'[,،\n\r]+'))
      .map((area) => area.trim())
      .where((area) => area.isNotEmpty)
      .toList();
  return areas.isEmpty ? const ['لم يتم تحديد مناطق بعد'] : areas;
}

class _TimeDisplay extends StatelessWidget {
  const _TimeDisplay({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          const Icon(Icons.schedule_rounded, color: kTextSecondary, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 12,
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

List<StoreWorkingDay> _defaultWorkingHours() {
  return const [
    StoreWorkingDay(
      dayKey: 'sat',
      dayLabel: 'السبت',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:30',
    ),
    StoreWorkingDay(
      dayKey: 'sun',
      dayLabel: 'الأحد',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:30',
    ),
    StoreWorkingDay(
      dayKey: 'mon',
      dayLabel: 'الاثنين',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:30',
    ),
    StoreWorkingDay(
      dayKey: 'tue',
      dayLabel: 'الثلاثاء',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:30',
    ),
    StoreWorkingDay(
      dayKey: 'wed',
      dayLabel: 'الأربعاء',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:30',
    ),
    StoreWorkingDay(
      dayKey: 'thu',
      dayLabel: 'الخميس',
      isOpen: true,
      openTime: '10:00',
      closeTime: '23:30',
    ),
    StoreWorkingDay(
      dayKey: 'fri',
      dayLabel: 'الجمعة',
      isOpen: false,
      openTime: '10:00',
      closeTime: '23:30',
    ),
  ];
}

String _guessCity(String? address) {
  final raw = address?.trim() ?? '';
  if (raw.isEmpty) return 'القاهرة';
  final parts = raw
      .split(RegExp(r'[,،]'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  return parts.firstWhere(
    (part) => part.contains('القاهرة') || part.toLowerCase().contains('cairo'),
    orElse: () => parts.length > 1 ? parts[1] : parts.first,
  );
}

String _guessDistrict(String? address) {
  final raw = address?.trim() ?? '';
  final parts = raw
      .split(RegExp(r'[,،]'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'القاهرة';
  return parts.length > 2 ? parts[2] : parts.first;
}

String _safeEgyptLocation(String value, {required String fallback}) {
  final normalized = value.trim().toLowerCase();
  const blocked = <String>[
    'مصر',
    'القاهرة',
    'الجيزة',
    'Egypt',
    'cairo',
    'giza',
  ];
  if (blocked.any(normalized.contains)) {
    return fallback;
  }
  return value.trim();
}
