import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/core/services/mapbox_runtime_config.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_background.dart';
import 'package:admin_tks/widgets/dashboard_map_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';

class VendorSignupDraft {
  const VendorSignupDraft({
    required this.vendorName,
    required this.storeName,
    required this.email,
    required this.phone,
    required this.password,
    required this.storeAddress,
    required this.storeLatitude,
    required this.storeLongitude,
    required this.logoBytes,
    required this.logoFileName,
    required this.vendorType,
    required this.storeCategory,
  });

  final String vendorName;
  final String storeName;
  final String email;
  final String phone;
  final String password;
  final String storeAddress;
  final double storeLatitude;
  final double storeLongitude;
  final Uint8List logoBytes;
  final String logoFileName;
  final String vendorType;
  final String? storeCategory;

  String get logoBase64 => base64Encode(logoBytes);
}

class VendorLocationSelection {
  const VendorLocationSelection({
    required this.latitude,
    required this.longitude,
    this.label,
  });

  final double latitude;
  final double longitude;
  final String? label;
}

class DashboardLoginView extends StatelessWidget {
  const DashboardLoginView({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isSubmitting,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onSignupTap,
    required this.onForgotPasswordTap,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onSignupTap;
  final VoidCallback onForgotPasswordTap;

  @override
  Widget build(BuildContext context) {
    return _SplitAuthScaffold(
      intro: const _IntroPanel(
        logoAsset: 'assets/img/restaurant.png',
        title: 'لوحة تحكم المطعم',
        englishSubtitle: 'Restaurant Dashboard',
        illustrationAsset: 'assets/img/restaurant.png',
        description:
            'تسجيل الدخول يتم بواسطة البريد الإلكتروني وكلمة المرور مع حماية كاملة لبيانات المطعم.',
        activeStep: 0,
      ),
      formChild: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _AuthSectionHeader(
              title: 'مرحباً بك !',
              subtitle: 'سجل الدخول لإدارة مطعمك',
            ),
            const SizedBox(height: 18),
            const _SectionDivider(),
            const SizedBox(height: 24),
            const _FieldLabel(text: 'البريد الإلكتروني'),
            const SizedBox(height: 10),
            _RoundedInputField(
              controller: emailController,
              hintText: 'restaurant@example.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline_rounded,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 18),
            const _FieldLabel(text: 'كلمة المرور'),
            const SizedBox(height: 10),
            _RoundedInputField(
              controller: passwordController,
              hintText: 'أدخل كلمة المرور',
              obscureText: obscurePassword,
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                tooltip:
                    obscurePassword ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
              ),
              textDirection: TextDirection.ltr,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPasswordTap,
                child: const Text('نسيت كلمة المرور؟'),
              ),
            ),
            const SizedBox(height: 8),
            _GradientActionButton(
              label: 'تسجيل الدخول',
              icon: Icons.lock_rounded,
              isLoading: isSubmitting,
              onPressed: onSubmit,
            ),
            const SizedBox(height: 16),
            _SecondaryActionButton(
              label: 'إنشاء حساب مطعم جديد',
              icon: Icons.store_mall_directory_rounded,
              onPressed: onSignupTap,
            ),
            const SizedBox(height: 18),
            const _SecurityFooter(),
          ],
        ),
      ),
    );
  }
}

class DashboardSignupView extends StatelessWidget {
  const DashboardSignupView({
    super.key,
    required this.vendorNameController,
    required this.storeNameController,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
    required this.passwordController,
    required this.isSubmitting,
    required this.obscurePassword,
    required this.logoBytes,
    required this.logoFileName,
    required this.locationSelection,
    required this.vendorType,
    required this.storeCategory,
    required this.onTogglePassword,
    required this.onPickLogo,
    required this.onClearLogo,
    required this.onLocationChanged,
    required this.onSubmit,
    required this.onLoginTap,
    required this.onVendorTypeChanged,
    required this.onStoreCategoryChanged,
  });

  final TextEditingController vendorNameController;
  final TextEditingController storeNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final bool obscurePassword;
  final Uint8List? logoBytes;
  final String? logoFileName;
  final VendorLocationSelection? locationSelection;
  final String vendorType;
  final String? storeCategory;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onPickLogo;
  final VoidCallback onClearLogo;
  final ValueChanged<VendorLocationSelection> onLocationChanged;
  final VoidCallback onSubmit;
  final VoidCallback onLoginTap;
  final ValueChanged<String> onVendorTypeChanged;
  final ValueChanged<String?> onStoreCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final isStore = vendorType == 'store';
    final businessLabel = isStore ? 'المتجر' : 'المطعم';
    final businessPossessive = isStore ? 'متجرك' : 'مطعمك';
    return _SplitAuthScaffold(
      intro: _IntroPanel(
        logoAsset: 'assets/img/restaurant.png',
        title: 'إنشاء حساب $businessLabel',
        englishSubtitle: isStore ? 'Store Onboarding' : 'Restaurant Onboarding',
        illustrationAsset: 'assets/img/restaurant.png',
        topAligned: true,
        description:
            'أضف شعار $businessLabel وبيانات المالك وموقع $businessLabel بدقة، ثم نرسل لك رمز OTP لمتابعة الطلب.',
        activeStep: 1,
      ),
      formChild: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AuthSectionHeader(
              title: 'أنشئ حساب $businessPossessive',
              subtitle: 'أكمل البيانات التالية لبدء المراجعة',
            ),
            const SizedBox(height: 18),
            const _SectionDivider(),
            const SizedBox(height: 20),
            const _FieldLabel(text: 'نوع النشاط'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: vendorType,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category_rounded),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'restaurant', child: Text('مطعم')),
                DropdownMenuItem(value: 'store', child: Text('متجر')),
              ],
              onChanged: (value) {
                if (value != null) onVendorTypeChanged(value);
              },
            ),
            if (vendorType == 'store') ...[
              const SizedBox(height: 18),
              const _FieldLabel(text: 'تخصص المتجر'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: storeCategory,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.storefront_rounded),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'fashion', child: Text('ملابس')),
                  DropdownMenuItem(value: 'shoes', child: Text('أحذية')),
                  DropdownMenuItem(value: 'perfume', child: Text('عطور')),
                  DropdownMenuItem(value: 'grocery', child: Text('بقالة')),
                  DropdownMenuItem(
                      value: 'fresh_food', child: Text('أغذية طازجة')),
                  DropdownMenuItem(
                      value: 'canned_food', child: Text('أغذية معلبة')),
                  DropdownMenuItem(
                      value: 'electronics', child: Text('إلكترونيات')),
                  DropdownMenuItem(value: 'toys', child: Text('ألعاب')),
                  DropdownMenuItem(value: 'general', child: Text('متجر عام')),
                ],
                onChanged: onStoreCategoryChanged,
              ),
            ],
            const SizedBox(height: 18),
            _FieldLabel(
              text: 'صورة لوجو $businessLabel',
            ),
            const SizedBox(height: 10),
            _LogoUploadTile(
              logoBytes: logoBytes,
              fileName: logoFileName,
              onPick: onPickLogo,
              onClear: onClearLogo,
            ),
            const SizedBox(height: 18),
            _FieldLabel(
              text: vendorType == 'store' ? 'اسم المتجر' : 'اسم المطعم',
            ),
            const SizedBox(height: 10),
            _RoundedInputField(
              controller: storeNameController,
              hintText:
                  vendorType == 'store' ? 'اكتب اسم المتجر' : 'اكتب اسم المطعم',
              prefixIcon: Icons.storefront_rounded,
            ),
            const SizedBox(height: 18),
            _FieldLabel(
              text:
                  vendorType == 'store' ? 'اسم صاحب المتجر' : 'اسم صاحب المطعم',
            ),
            const SizedBox(height: 10),
            _RoundedInputField(
              controller: vendorNameController,
              hintText: 'اسم المالك أو المسؤول',
              prefixIcon: Icons.person_rounded,
            ),
            const SizedBox(height: 18),
            const _FieldLabel(text: 'رقم الهاتف'),
            const SizedBox(height: 10),
            _RoundedInputField(
              controller: phoneController,
              hintText: '01xxxxxxxxx',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_rounded,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 18),
            const _FieldLabel(text: 'البريد الإلكتروني'),
            const SizedBox(height: 10),
            _RoundedInputField(
              controller: emailController,
              hintText: 'restaurant@example.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline_rounded,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 18),
            _FieldLabel(
              text: vendorType == 'store' ? 'عنوان المتجر' : 'عنوان المطعم',
            ),
            const SizedBox(height: 10),
            _RoundedInputField(
              controller: addressController,
              hintText: 'الشارع، المنطقة، المدينة',
              prefixIcon: Icons.location_on_rounded,
            ),
            const SizedBox(height: 18),
            VendorLocationPicker(
              addressController: addressController,
              selection: locationSelection,
              onChanged: onLocationChanged,
            ),
            const SizedBox(height: 18),
            const _FieldLabel(text: 'كلمة المرور'),
            const SizedBox(height: 10),
            _RoundedInputField(
              controller: passwordController,
              hintText: 'أدخل كلمة المرور',
              obscureText: obscurePassword,
              prefixIcon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: onTogglePassword,
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                tooltip:
                    obscurePassword ? 'إظهار كلمة المرور' : 'إخفاء كلمة المرور',
              ),
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 20),
            _GradientActionButton(
              label: 'إرسال طلب التسجيل',
              icon: Icons.verified_user_rounded,
              isLoading: isSubmitting,
              onPressed: onSubmit,
            ),
            const SizedBox(height: 14),
            _SecondaryActionButton(
              label: 'لدي حساب بالفعل',
              icon: Icons.login_rounded,
              onPressed: onLoginTap,
            ),
            const SizedBox(height: 18),
            const _PendingHint(),
          ],
        ),
      ),
    );
  }
}

class DashboardSignupPendingPage extends StatefulWidget {
  const DashboardSignupPendingPage({
    super.key,
    required this.draft,
  });

  final VendorSignupDraft draft;

  @override
  State<DashboardSignupPendingPage> createState() =>
      _DashboardSignupPendingPageState();
}

class _DashboardSignupPendingPageState
    extends State<DashboardSignupPendingPage> {
  Timer? _statusTimer;
  bool _checkingStatus = false;
  bool _redirecting = false;

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  @override
  void initState() {
    super.initState();
    _checkApproval();
    _statusTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkApproval();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkApproval() async {
    if (_checkingStatus || _redirecting) {
      return;
    }

    _checkingStatus = true;
    try {
      final status = await _auth.checkSignupStatus(widget.draft.email);
      final vendorStatus =
          status['vendor_status']?.toString().trim().toLowerCase() ?? '';
      final verified = status['vendor_is_verified'] == 1 ||
          status['vendor_is_verified']?.toString() == '1';

      if (!mounted) {
        return;
      }

      if (vendorStatus == 'active' && verified) {
        _redirecting = true;
        _statusTimer?.cancel();
        Get.offAllNamed('/');
      }
    } catch (_) {
      // Silent polling keeps the review page calm if the network is unstable.
    } finally {
      _checkingStatus = false;
    }
  }

  Future<void> _openSupport() async {
    final uri = Uri.parse(
      'mailto:support@savir-technology.online?subject=Vendor%20review%20support',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: DashboardBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.97),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: kStroke),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: kPrimary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.assignment_turned_in_rounded,
                            size: 58,
                            color: kPrimary,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'طلبك قيد المعالجة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'تم استلام طلب تسجيل مطعمك بنجاح، وسيتم مراجعته من الإدارة. بمجرد الموافقة عليك ستتمكن من تسجيل الدخول مباشرة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 15,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8F3),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: kStroke),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: kPrimary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child:
                                      logoBytesPreview(widget.draft.logoBytes),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.draft.storeName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: kTextPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.draft.email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: kTextSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const _StatusPill(label: 'قيد المراجعة'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _PendingMetric(
                                label: 'اسم المالك',
                                value: widget.draft.vendorName,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PendingMetric(
                                label: 'رقم الهاتف',
                                value: widget.draft.phone,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _PendingMetric(
                                label: 'العنوان',
                                value: widget.draft.storeAddress,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _SupportAction(onPressed: _openSupport),
                        const SizedBox(height: 14),
                        const Text(
                          'لن تتمكن من الوصول إلى لوحة الإدارة حتى يتم اعتماد مطعمك من قبل المستر أدمن.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 14,
                            height: 1.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VendorLocationPicker extends StatefulWidget {
  const VendorLocationPicker({
    super.key,
    required this.addressController,
    required this.onChanged,
    this.selection,
  });

  final TextEditingController addressController;
  final VendorLocationSelection? selection;
  final ValueChanged<VendorLocationSelection> onChanged;

  @override
  State<VendorLocationPicker> createState() => _VendorLocationPickerState();
}

class _VendorLocationPickerState extends State<VendorLocationPicker> {
  final MapController _mapController = MapController();
  late LatLng _center;
  bool _mapReady = false;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _center = LatLng(
      widget.selection?.latitude ?? 30.0444,
      widget.selection?.longitude ?? 31.2357,
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _confirmLocation() async {
    if (_resolving) return;
    setState(() => _resolving = true);
    final token = MapboxRuntimeConfig.accessToken.trim();
    if (token.isNotEmpty) {
      final resolvedAddress =
          await _reverseGeocode(_center.latitude, _center.longitude);
      if (resolvedAddress != null &&
          widget.addressController.text.trim().isEmpty) {
        widget.addressController.text = resolvedAddress;
      }
    }

    widget.onChanged(
      VendorLocationSelection(
        latitude: _center.latitude,
        longitude: _center.longitude,
      ),
    );
    if (!mounted) return;
    setState(() => _resolving = false);
  }

  Future<String?> _reverseGeocode(double latitude, double longitude) async {
    final token = MapboxRuntimeConfig.accessToken.trim();
    if (token.isEmpty) {
      return null;
    }

    try {
      final uri = Uri.https(
        'api.mapbox.com',
        '/geocoding/v5/mapbox.places/$longitude,$latitude.json',
        {
          'access_token': token,
          'language': 'ar',
          'types': 'address,place,locality,neighborhood,poi',
          'limit': '1',
        },
      );

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return null;
      }

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final features = (decoded is Map ? decoded['features'] : null) as List?;
      if (features == null || features.isEmpty) {
        return null;
      }

      final first = features.first;
      if (first is! Map) {
        return null;
      }

      final feature = first.cast<String, dynamic>();
      final placeName = feature['place_name']?.toString().trim() ?? '';
      return placeName.isNotEmpty ? placeName : null;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.map_rounded, color: kPrimary, size: 20),
              SizedBox(width: 8),
              Text(
                'الخريطة',
                style: TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _center,
                        initialZoom: 15.2,
                        onMapReady: () {
                          if (mounted) {
                            setState(() => _mapReady = true);
                          }
                        },
                        onPositionChanged: (camera, hasGesture) {
                          if (!mounted) {
                            return;
                          }
                          setState(() {
                            _center = camera.center;
                          });
                        },
                        onTap: (tapPosition, point) {
                          setState(() {
                            _center = point;
                          });
                          _mapController.move(
                              point, _mapController.camera.zoom);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: dashboardMapTileUrlTemplate(),
                          userAgentPackageName:
                              'com.aleppoeats.admin.dashboard',
                        ),
                      ],
                    ),
                  ),
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: _MapPin(),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    top: 12,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'حرك الخريطة وحدد موقع المطعم بدقة ثم اضغط اعتماد الموقع',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricChip(
                icon: Icons.straighten_rounded,
                label: 'خط العرض',
                value: _center.latitude.toStringAsFixed(6),
              ),
              _MetricChip(
                icon: Icons.alt_route_rounded,
                label: 'خط الطول',
                value: _center.longitude.toStringAsFixed(6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _resolving
                  ? null
                  : () async {
                      await _confirmLocation();
                    },
              icon: _resolving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.gps_fixed_rounded),
              label: Text(
                _mapReady ? 'اعتماد الموقع الحالي' : 'جاري تجهيز الخريطة...',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitAuthScaffold extends StatelessWidget {
  const _SplitAuthScaffold({
    required this.intro,
    required this.formChild,
  });

  final Widget intro;
  final Widget formChild;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: DashboardBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 10 : 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1500),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.98),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(color: kStroke),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 40,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: isMobile
                        ? Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: formChild,
                              ),
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: kStroke,
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: intro,
                              ),
                            ],
                          )
                        : IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: intro),
                                const VerticalDivider(
                                  width: 1,
                                  thickness: 1,
                                  color: kStroke,
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.all(28),
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 760,
                                        ),
                                        child: formChild,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroPanel extends StatelessWidget {
  const _IntroPanel({
    required this.logoAsset,
    required this.title,
    required this.englishSubtitle,
    required this.illustrationAsset,
    required this.description,
    required this.activeStep,
    this.topAligned = false,
  });

  final String logoAsset;
  final String title;
  final String englishSubtitle;
  final String illustrationAsset;
  final String description;
  final int activeStep;
  final bool topAligned;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 600;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 18 : 28,
        vertical: compact ? 24 : (topAligned ? 44 : 28),
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFDFEFD),
            Color(0xFFFFF8F3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          mainAxisAlignment:
              topAligned ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kPrimary,
                fontSize: compact ? 32 : 54,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              englishSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTextSecondary,
                fontSize: compact ? 18 : 26,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: compact ? 220 : 360),
              child: Image.asset(
                illustrationAsset,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 22),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: compact ? 13 : 16,
                  height: 1.85,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _StepDots(activeStep: activeStep),
          ],
        ),
      ),
    );
  }
}

class _AuthSectionHeader extends StatelessWidget {
  const _AuthSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kPrimary,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kTextSecondary,
            fontSize: 15,
            height: 1.65,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        text,
        style: const TextStyle(
          color: kTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _DividerSegment(active: true),
        SizedBox(width: 8),
        _DividerSegment(active: false),
        SizedBox(width: 8),
        _DividerSegment(active: false),
      ],
    );
  }
}

class _DividerSegment extends StatelessWidget {
  const _DividerSegment({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 48 : 28,
      height: 5,
      decoration: BoxDecoration(
        color: active ? kPrimary : const Color(0xFFD1E3D6),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _RoundedInputField extends StatelessWidget {
  const _RoundedInputField({
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.textDirection,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textDirection: textDirection,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFFFFBF8),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: kStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: kStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: kPrimary, width: 1.4),
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [kPrimary, kSecondary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, size: 22),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: kPrimary,
          side: const BorderSide(color: kStroke),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          backgroundColor: const Color(0xFFFFFBF8),
        ),
      ),
    );
  }
}

class _SecurityFooter extends StatelessWidget {
  const _SecurityFooter();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user_rounded, color: kPrimary, size: 18),
        SizedBox(width: 8),
        Text(
          'تسجيل دخول آمن لحماية بياناتك',
          style: TextStyle(
            color: kTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LogoUploadTile extends StatelessWidget {
  const _LogoUploadTile({
    required this.logoBytes,
    required this.fileName,
    required this.onPick,
    required this.onClear,
  });

  final Uint8List? logoBytes;
  final String? fileName;
  final Future<void> Function() onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasLogo = logoBytes != null && logoBytes!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        children: [
          Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: kStroke),
            ),
            child: hasLogo
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.memory(
                      logoBytes!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.add_photo_alternate_rounded,
                    color: kTextSecondary, size: 36),
          ),
          const SizedBox(height: 14),
          Text(
            hasLogo
                ? (fileName ?? 'صورة الشعار جاهزة')
                : 'اختر صورة المطعم بصيغة PNG أو JPG',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => onPick(),
                icon: const Icon(Icons.upload_rounded),
                label: Text(hasLogo ? 'تغيير الصورة' : 'اختيار الصورة'),
              ),
              if (hasLogo)
                OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('حذف'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingHint extends StatelessWidget {
  const _PendingHint();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_rounded, color: kPrimary, size: 18),
        SizedBox(width: 8),
        Flexible(
          child: Text(
            'بعد التحقق من OTP سيظهر لك طلبك قيد المراجعة حتى الموافقة النهائية.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: kTextSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child:
              const Icon(Icons.location_on_rounded, color: kPrimary, size: 28),
        ),
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: kTextSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: kTextSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kPrimary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: kPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PendingMetric extends StatelessWidget {
  const _PendingMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.isEmpty ? 'غير متوفر' : value,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportAction extends StatelessWidget {
  const _SupportAction({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.headset_mic_rounded),
        label: const Text(
          'مركز الدعم',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: kPrimary,
          side: const BorderSide(color: kPrimary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

Widget logoBytesPreview(Uint8List bytes) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Image.memory(bytes, fit: BoxFit.cover),
  );
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.activeStep});

  final int activeStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index == activeStep;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: isActive ? 34 : 18,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? kPrimary : const Color(0xFFC7D7CB),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        );
      }),
    );
  }
}
