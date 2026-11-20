import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:tks/controler/settings/settings_controller.dart';
import 'package:tks/core/constant/imsgesassets.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/core/services/services.dart';
import 'package:tks/linkapi/linkapi.dart';
import 'package:tks/view/widget/common/app_top_banner.dart';

class ProfilePage extends StatefulWidget {
  final int userId;

  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    getProfile();
  }

  Future<void> getProfile() async {
    final url =
        Uri.parse('${AppLink.server}/dash/users/profile/get_profile.php');

    try {
      final response = await http.post(url, body: {
        'user_id': widget.userId.toString(),
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          userData = decoded is Map<String, dynamic>
              ? decoded
              : Map<String, dynamic>.from(decoded);
          loading = false;
        });
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      loading = false;
    });
  }

  Future<void> uploadImage(File imageFile) async {
    final url =
        Uri.parse('${AppLink.server}/dash/users/profile/upload_image.php');

    final request = http.MultipartRequest('POST', url);
    request.fields['user_id'] = widget.userId.toString();
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final data = json.decode(responseBody);

    if (data['status'] == 'success') {
      setState(() {
        userData ??= {};
        userData!['users_image'] = data['name'];
      });

      try {
        if (Get.isRegistered<SettingsController>()) {
          final settingsCtrl = Get.find<SettingsController>();
          settingsCtrl.userData ??= {};
          settingsCtrl.userData!['users_image'] = data['name'];
          settingsCtrl.update();
        }
      } catch (_) {}

      try {
        final myServices = Get.find<MyServices>();
        await myServices.sharedPreferences
            .setString('users_image', data['name']);
      } catch (_) {}

      try {
        final newUrl = AppLink.normalizeUrl(
            '${AppLink.server}/uploads/users/img/${data['name']}');
        await CachedNetworkImage.evictFromCache(newUrl);
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث الصورة بنجاح'.tr)),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل رفع الصورة'.tr)),
      );
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      await uploadImage(File(picked.path));
    }
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
  }) async {
    final url =
        Uri.parse('${AppLink.server}/dash/users/profile/update_profile.php');

    final response = await http.post(
      url,
      body: {
        'user_id': widget.userId.toString(),
        'users_name': name.trim(),
        'users_phone': phone.trim(),
        'users_email': (userData?['users_email'] ?? '').toString(),
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('حدث خطأ في الاتصال بالخادم');
    }

    dynamic decoded;
    try {
      decoded = json.decode(response.body);
    } catch (_) {
      throw Exception('رد غير صالح من الخادم');
    }

    final map = decoded is Map<String, dynamic>
        ? decoded
        : Map<String, dynamic>.from(decoded);

    if (map['status'] == 'success') {
      final updated = map['data'] is Map<String, dynamic>
          ? map['data'] as Map<String, dynamic>
          : userData ?? <String, dynamic>{};

      setState(() {
        userData = updated;
      });

      final myServices = Get.find<MyServices>();
      await myServices.sharedPreferences
          .setString('username', (updated['users_name'] ?? name).toString());
      await myServices.sharedPreferences
          .setString('phone', (updated['users_phone'] ?? phone).toString());

      if (Get.isRegistered<SettingsController>()) {
        final settingsCtrl = Get.find<SettingsController>();
        settingsCtrl.userData ??= {};
        settingsCtrl.userData!['users_name'] =
            (updated['users_name'] ?? name).toString();
        settingsCtrl.userData!['users_phone'] =
            (updated['users_phone'] ?? phone).toString();
        settingsCtrl.update();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديث البيانات بنجاح'.tr)),
      );
      return;
    }

    final status = (map['status'] ?? '').toString();
    String message = 'تعذر تحديث البيانات';
    if (status == 'phone_exists') {
      message = 'رقم الهاتف مستخدم بالفعل';
    } else if (status == 'invalid_phone') {
      message = 'رقم الهاتف غير صالح';
    } else if (status == 'invalid_name') {
      message = 'الاسم غير صالح';
    }

    throw Exception(message);
  }

  Future<void> showEditProfileDialog() async {
    final nameController =
        TextEditingController(text: (userData?['users_name'] ?? '').toString());
    final phoneController = TextEditingController(
      text: (userData?['users_phone'] ?? '').toString(),
    );
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text('تعديل البيانات'.tr),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'الاسم'.tr,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'رقم الهاتف'.tr,
                        prefixIcon: const Icon(Icons.phone_android_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSaving ? null : () => Navigator.of(dialogContext).pop(),
                  child: Text('إلغاء'.tr),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final phone = phoneController.text.trim();
                          if (name.isEmpty || phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('الرجاء إدخال الاسم ورقم الهاتف'.tr),
                              ),
                            );
                            return;
                          }

                          setStateDialog(() => isSaving = true);
                          try {
                            await updateProfile(name: name, phone: phone);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          } on TimeoutException {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    Text('انتهت مهلة الاتصال، حاول مرة أخرى'.tr),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst('Exception: ', ''),
                                ),
                              ),
                            );
                          } finally {
                            if (dialogContext.mounted) {
                              setStateDialog(() => isSaving = false);
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('حفظ'.tr),
                ),
              ],
            );
          },
        );
      },
    );

    // Intentionally not disposing here to avoid dispose/rebuild race
    // while dialog route is still transitioning.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final imageName = userData?['users_image'];
    final imageUrl = (imageName == null || imageName == '')
        ? null
        : AppLink.normalizeUrl(
            '${AppLink.server}/uploads/users/img/$imageName');

    if (loading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    final avatar = imageUrl == null
        ? Image.asset(AppImageAsset.avatar, fit: BoxFit.cover)
        : CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: Colors.white.withValues(alpha: 0.10),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (_, __, ___) =>
                Image.asset(AppImageAsset.avatar, fit: BoxFit.cover),
          );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primary.withValues(alpha: 0.10),
              theme.scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              AppTopBanner(
                title: userData?['users_name'] ?? 'User',
                subtitle: userData?['users_email'] ?? '',
                leadingIcon: Icons.arrow_back_rounded,
                onLeadingTap: () {
                  if (Get.previousRoute.isNotEmpty) {
                    Get.back();
                  } else {
                    Get.offAllNamed(AppRoutes.homepage);
                  }
                },
                trailingIcon: Icons.edit_outlined,
                onTrailingTap: pickImage,
                child: Column(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: pickImage,
                        child: Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                              child: ClipOval(
                                child: SizedBox(
                                  width: 108,
                                  height: 108,
                                  child: avatar,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 4,
                              bottom: 4,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _CompactProfileMetric(
                            value: userData?['users_phone'] ?? '-',
                            label: 'الهاتف',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CompactProfileMetric(
                            value: widget.userId.toString(),
                            label: 'معرف الحساب',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('بيانات الحساب'.tr, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 14),
                      _infoTile(context,
                          icon: Icons.person_outline,
                          title: 'الاسم'.tr,
                          value: userData?['users_name'] ?? '-'),
                      const SizedBox(height: 10),
                      _infoTile(context,
                          icon: Icons.email_outlined,
                          title: 'البريد الإلكتروني'.tr,
                          value: userData?['users_email'] ?? '-'),
                      const SizedBox(height: 10),
                      _infoTile(context,
                          icon: Icons.phone_android_outlined,
                          title: 'رقم الهاتف'.tr,
                          value: userData?['users_phone'] ?? '-'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('إجراءات سريعة'.tr, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 14),
                      _actionTile(
                        context,
                        icon: Icons.photo_camera_outlined,
                        title: 'تغيير الصورة الشخصية'.tr,
                        onTap: pickImage,
                      ),
                      const SizedBox(height: 10),
                      _actionTile(
                        context,
                        icon: Icons.edit_note_rounded,
                        title: 'تعديل الاسم ورقم الهاتف'.tr,
                        onTap: showEditProfileDialog,
                      ),
                      const SizedBox(height: 10),
                      _actionTile(
                        context,
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'المحفظة'.tr,
                        onTap: () => Get.toNamed(AppRoutes.wallet),
                      ),
                      const SizedBox(height: 10),
                      _actionTile(
                        context,
                        icon: Icons.local_offer_outlined,
                        title: 'العروض'.tr,
                        onTap: () => Get.toNamed(AppRoutes.offers),
                      ),
                      const SizedBox(height: 10),
                      _actionTile(
                        context,
                        icon: Icons.archive_outlined,
                        title: 'أرشيف الطلبات'.tr,
                        onTap: () => Get.toNamed(AppRoutes.ordersarchive_page),
                      ),
                      const SizedBox(height: 10),
                      _actionTile(
                        context,
                        icon: Icons.local_shipping_outlined,
                        title: 'الطلبات الحالية'.tr,
                        onTap: () => Get.toNamed(AppRoutes.orderspending),
                      ),
                      const SizedBox(height: 10),
                      _actionTile(
                        context,
                        icon: Icons.favorite_border_rounded,
                        title: 'المفضلة'.tr,
                        onTap: () => Get.toNamed(AppRoutes.myfavroite),
                      ),
                      const SizedBox(height: 10),
                      _actionTile(
                        context,
                        icon: Icons.notifications_none_rounded,
                        title: 'الإشعارات'.tr,
                        onTap: () => Get.toNamed(AppRoutes.notificationPage),
                      ),
                      const SizedBox(height: 10),
                      _actionTile(
                        context,
                        icon: Icons.people_alt_outlined,
                        title: 'المستلمون المحفوظون'.tr,
                        onTap: () => Get.toNamed(AppRoutes.recipients),
                      ),
                      const SizedBox(height: 10),
                      _actionTile(
                        context,
                        icon: Icons.location_on_outlined,
                        title: 'العناوين'.tr,
                        onTap: () => Get.toNamed(AppRoutes.addressview),
                      ),
                      const SizedBox(height: 10),
                      _actionTile(
                        context,
                        icon: Icons.support_agent_outlined,
                        title: 'مركز المساعدة'.tr,
                        onTap: () => Get.toNamed(AppRoutes.helpCenter),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _logoutTile(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
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
                Text(title.tr, style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(value, style: theme.textTheme.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: theme.scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: theme.hintColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoutTile(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () async {
          final confirmed = await Get.dialog<bool>(
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text('confirm_logout'.tr),
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

          if (confirmed == true) {
            final controller = Get.isRegistered<SettingsController>()
                ? Get.find<SettingsController>()
                : Get.put(SettingsController());
            await controller.logout();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.16),
            ),
            gradient: LinearGradient(
              colors: [
                Colors.redAccent.withValues(alpha: 0.10),
                theme.cardColor,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تسجيل الخروج'.tr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'confirm_logout_message'.tr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color
                            ?.withValues(alpha: 0.72),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.redAccent.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactProfileMetric extends StatelessWidget {
  final String value;
  final String label;

  const _CompactProfileMetric({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.tr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}
