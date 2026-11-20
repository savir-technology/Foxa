import 'dart:async';
import 'dart:typed_data';

import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/auth/dashboard_onboarding_views.dart';
import 'package:admin_tks/restaurant_dashboard_page.dart';
import 'package:admin_tks/store_dashboard_page.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_background.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardRootPage extends StatelessWidget {
  const DashboardRootPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<DashboardAuthController>();
    return Obx(() {
      if (!auth.isReady.value) {
        return const Scaffold(
          backgroundColor: kBackground,
          body: Center(child: CircularProgressIndicator(color: kPrimary)),
        );
      }

      if (auth.isLoggedIn) {
        return auth.isStore
            ? const StoreDashboardPage()
            : const RestaurantDashboardPage();
      }

      return const DashboardLoginPage();
    });
  }
}

class DashboardLoginPage extends StatefulWidget {
  const DashboardLoginPage({super.key});

  @override
  State<DashboardLoginPage> createState() => _DashboardLoginPageState();
}

class _DashboardLoginPageState extends State<DashboardLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _auth.loginVendor(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Get.offAllNamed('/');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLoginView(
      emailController: _emailController,
      passwordController: _passwordController,
      isSubmitting: _isSubmitting,
      obscurePassword: _obscurePassword,
      onTogglePassword: () {
        setState(() => _obscurePassword = !_obscurePassword);
      },
      onSubmit: _submit,
      onSignupTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const DashboardSignupPage(),
          ),
        );
      },
      onForgotPasswordTap: () =>
          Get.to(() => const DashboardForgotPasswordPage()),
    );
  }
}

class DashboardSignupPage extends StatefulWidget {
  const DashboardSignupPage({super.key});

  @override
  State<DashboardSignupPage> createState() => _DashboardSignupPageState();
}

class _DashboardSignupPageState extends State<DashboardSignupPage> {
  final _vendorNameController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  Uint8List? _logoBytes;
  String? _logoFileName;
  VendorLocationSelection? _locationSelection;
  String _vendorType = 'restaurant';
  String? _storeCategory;

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  @override
  void dispose() {
    _vendorNameController.dispose();
    _storeNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showMessage('تعذر قراءة صورة اللوجو');
      return;
    }

    setState(() {
      _logoBytes = bytes;
      _logoFileName = file.name;
    });
  }

  void _clearLogo() {
    setState(() {
      _logoBytes = null;
      _logoFileName = null;
    });
  }

  void _handleLocationChanged(VendorLocationSelection selection) {
    setState(() {
      _locationSelection = selection;
    });
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    final businessLabel = _vendorType == 'store' ? 'المتجر' : 'المطعم';

    if (_logoBytes == null || _logoBytes!.isEmpty) {
      _showMessage('من فضلك اختر صورة لوجو $businessLabel');
      return;
    }

    if (_locationSelection == null) {
      _showMessage('من فضلك اعتمد موقع $businessLabel من الخريطة');
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      _showMessage('من فضلك اكتب عنوان $businessLabel');
      return;
    }

    if (_vendorType == 'store' &&
        (_storeCategory == null || _storeCategory!.isEmpty)) {
      _showMessage('Please choose the store specialization');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final draft = VendorSignupDraft(
        vendorName: _vendorNameController.text.trim(),
        storeName: _storeNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        storeAddress: _addressController.text.trim(),
        storeLatitude: _locationSelection!.latitude,
        storeLongitude: _locationSelection!.longitude,
        logoBytes: _logoBytes!,
        logoFileName: _logoFileName ?? 'vendor-logo.png',
        vendorType: _vendorType,
        storeCategory: _storeCategory,
      );

      await _auth.signup(
        vendorName: draft.vendorName,
        storeName: draft.storeName,
        email: draft.email,
        phone: draft.phone,
        password: draft.password,
        logoBase64: draft.logoBase64,
        storeAddress: draft.storeAddress,
        storeLatitude: draft.storeLatitude,
        storeLongitude: draft.storeLongitude,
        vendorType: draft.vendorType,
        storeCategory: draft.storeCategory,
      );
      if (!mounted) return;
      Get.off(
        () => DashboardSignupVerifyCodePage(
          email: draft.email,
          draft: draft,
        ),
      );
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return DashboardSignupView(
      vendorNameController: _vendorNameController,
      storeNameController: _storeNameController,
      emailController: _emailController,
      phoneController: _phoneController,
      addressController: _addressController,
      passwordController: _passwordController,
      isSubmitting: _isSubmitting,
      obscurePassword: _obscurePassword,
      logoBytes: _logoBytes,
      logoFileName: _logoFileName,
      locationSelection: _locationSelection,
      vendorType: _vendorType,
      storeCategory: _storeCategory,
      onTogglePassword: () {
        setState(() => _obscurePassword = !_obscurePassword);
      },
      onPickLogo: _pickLogo,
      onClearLogo: _clearLogo,
      onLocationChanged: _handleLocationChanged,
      onVendorTypeChanged: (value) => setState(() {
        _vendorType = value;
        if (value == 'restaurant') _storeCategory = null;
      }),
      onStoreCategoryChanged: (value) => setState(() => _storeCategory = value),
      onSubmit: _submit,
      onLoginTap: () => Get.off(() => const DashboardLoginPage()),
    );
  }
}

class DashboardSignupVerifyCodePage extends StatefulWidget {
  const DashboardSignupVerifyCodePage({
    super.key,
    required this.email,
    required this.draft,
  });

  final String email;
  final VendorSignupDraft draft;

  @override
  State<DashboardSignupVerifyCodePage> createState() =>
      _DashboardSignupVerifyCodePageState();
}

class _DashboardSignupVerifyCodePageState
    extends State<DashboardSignupVerifyCodePage> {
  final _codeController = TextEditingController();
  bool _isSubmitting = false;
  bool _isResending = false;

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _auth.verifySignupCode(
        email: widget.email,
        code: _codeController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم التحقق من البريد، والطلب الآن قيد المراجعة')),
      );
      Get.offAll(() => DashboardSignupPendingPage(draft: widget.draft));
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resend() async {
    if (_isResending) return;
    setState(() => _isResending = true);
    try {
      await _auth.resendSignupCode(widget.email);
      _showMessage('تم إرسال رمز جديد إلى بريدك الإلكتروني');
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      icon: Icons.mark_email_read_rounded,
      title: 'تأكيد الحساب',
      subtitle: 'أدخل رمز التحقق المرسل إلى ${widget.email}.',
      child: Column(
        children: [
          _AuthField(
            controller: _codeController,
            label: 'رمز التحقق',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _PrimaryAuthButton(
            label: 'تأكيد الرمز',
            isLoading: _isSubmitting,
            onPressed: _verify,
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _isResending ? null : _resend,
            child: Text(_isResending ? 'جارٍ الإرسال...' : 'إعادة إرسال الرمز'),
          ),
        ],
      ),
    );
  }
}

class DashboardForgotPasswordPage extends StatefulWidget {
  const DashboardForgotPasswordPage({super.key});

  @override
  State<DashboardForgotPasswordPage> createState() =>
      _DashboardForgotPasswordPageState();
}

class _DashboardForgotPasswordPageState
    extends State<DashboardForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _auth.sendResetCode(_emailController.text);
      if (!mounted) return;
      Get.off(
          () => DashboardCheckMailPage(email: _emailController.text.trim()));
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      icon: Icons.lock_reset_rounded,
      title: 'استعادة كلمة المرور',
      subtitle: 'أدخل بريد المتجر وسنرسل لك رمز التحقق الخاص بإعادة التعيين.',
      child: Column(
        children: [
          _AuthField(
            controller: _emailController,
            label: 'البريد الإلكتروني',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _PrimaryAuthButton(
            label: 'إرسال الرمز',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class DashboardCheckMailPage extends StatelessWidget {
  const DashboardCheckMailPage({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      icon: Icons.mail_outline_rounded,
      title: 'تحقق من بريدك',
      subtitle: 'أرسلنا رمز إعادة التعيين إلى $email.',
      child: Column(
        children: [
          const Text(
            'بعد استلام الرمز يمكنك المتابعة إلى شاشة التحقق ثم تغيير كلمة المرور.',
            style: TextStyle(color: kTextSecondary, height: 1.6),
          ),
          const SizedBox(height: 18),
          _PrimaryAuthButton(
            label: 'متابعة',
            onPressed: () =>
                Get.off(() => DashboardForgotVerifyCodePage(email: email)),
          ),
        ],
      ),
    );
  }
}

class DashboardForgotVerifyCodePage extends StatefulWidget {
  const DashboardForgotVerifyCodePage({super.key, required this.email});

  final String email;

  @override
  State<DashboardForgotVerifyCodePage> createState() =>
      _DashboardForgotVerifyCodePageState();
}

class _DashboardForgotVerifyCodePageState
    extends State<DashboardForgotVerifyCodePage> {
  final _codeController = TextEditingController();
  bool _isSubmitting = false;

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await _auth.verifyResetCode(
        email: widget.email,
        code: _codeController.text,
      );
      if (!mounted) return;
      Get.off(
        () => DashboardChangePasswordPage(
          email: widget.email,
          code: _codeController.text.trim(),
        ),
      );
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      icon: Icons.password_rounded,
      title: 'تأكيد رمز الاستعادة',
      subtitle: 'أدخل الرمز المرسل إلى ${widget.email}.',
      child: Column(
        children: [
          _AuthField(
            controller: _codeController,
            label: 'رمز الاستعادة',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _PrimaryAuthButton(
            label: 'تحقق',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class DashboardChangePasswordPage extends StatefulWidget {
  const DashboardChangePasswordPage({
    super.key,
    required this.email,
    required this.code,
  });

  final String email;
  final String code;

  @override
  State<DashboardChangePasswordPage> createState() =>
      _DashboardChangePasswordPageState();
}

class _DashboardChangePasswordPageState
    extends State<DashboardChangePasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isSubmitting = false;

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (_passwordController.text != _confirmController.text) {
      _showMessage('كلمتا المرور غير متطابقتين');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _auth.changePassword(
        email: widget.email,
        code: widget.code,
        password: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')),
      );
      Get.offAll(() => const DashboardLoginPage());
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(
      icon: Icons.lock_open_rounded,
      title: 'تغيير كلمة المرور',
      subtitle: 'اختر كلمة مرور جديدة لمتجرك.',
      child: Column(
        children: [
          _AuthField(
            controller: _passwordController,
            label: 'كلمة المرور الجديدة',
            obscureText: true,
          ),
          const SizedBox(height: 12),
          _AuthField(
            controller: _confirmController,
            label: 'تأكيد كلمة المرور',
            obscureText: true,
          ),
          const SizedBox(height: 16),
          _PrimaryAuthButton(
            label: 'حفظ كلمة المرور',
            isLoading: _isSubmitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _AuthShell extends StatelessWidget {
  const _AuthShell({
    required this.title,
    required this.subtitle,
    required this.child,
    this.icon = Icons.storefront_rounded,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: kBackground,
      body: DashboardBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: EdgeInsets.all(width < 600 ? 22 : 30),
                decoration: BoxDecoration(
                  color: kSurface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: kStroke),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: kPrimary, size: 34),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 22),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF7F9FC),
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

class _PrimaryAuthButton extends StatelessWidget {
  const _PrimaryAuthButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Text(label),
      ),
    );
  }
}
