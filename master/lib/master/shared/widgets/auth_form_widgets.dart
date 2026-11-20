// ignore_for_file: unused_element

part of '../../../master_auth_app.dart';

class _AuthHeroPanelV2 extends StatelessWidget {
  const _AuthHeroPanelV2();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40001510),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_kAuthBackgroundAsset, fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF03251C).withValues(alpha: 0.40),
                  const Color(0xFF03251C).withValues(alpha: 0.20),
                  const Color(0xFF03251C).withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(30, 24, 30, 28),
            child: Column(
              children: [
                const MasterBrandMark(width: 210, height: 76, onDark: true),
                const Text(
                  'Master Platform',
                  style: TextStyle(
                    color: Color(0xFFD8E9E1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text.rich(
                  TextSpan(
                    text: 'لوحة تحكم متكاملة\n',
                    children: [
                      TextSpan(
                        text: 'لإدارة منصة التوصيل الخاصة بك',
                        style: TextStyle(color: Color(0xFFB5EF16)),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    height: 1.28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'تحكم كامل في الطلبات، المطاعم، المتاجر، السائقين، والمستخدمين\nمن مكان واحد وبأعلى كفاءة وأمان.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13.5,
                    height: 1.65,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 26),
                const _AuthFeatureGridV2(),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthFeatureGridV2 extends StatelessWidget {
  const _AuthFeatureGridV2();

  @override
  Widget build(BuildContext context) {
    const features = [
      (Icons.layers_rounded, 'إدارة شاملة', 'لوحة واحدة لكل العمليات'),
      (Icons.security_rounded, 'صلاحيات مرنة', 'للمستخدمين والفرق'),
      (Icons.delivery_dining_rounded, 'إدارة العمليات', 'الطلبات والتوصيل'),
    ];
    return Row(
      children: features
          .map(
            (feature) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(feature.$1, color: const Color(0xFFB5EF16), size: 23),
                    const SizedBox(height: 8),
                    Text(
                      feature.$2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature.$3,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AuthHeroPanel extends StatelessWidget {
  const _AuthHeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(_kAuthBackgroundAsset, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    const Color(0xFF06341F).withValues(alpha: 0.42),
                    const Color(0xFF0F5E33).withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: const MasterBrandMark(
                              width: 184,
                              height: 70,
                              onDark: true,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'لوحة تحكم متكاملة\nلإدارة منصة التوصيل الخاصة بك',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 29,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'تحكم كامل في الطلبات، المطاعم، السائقين، والمستخدمين من مكان واحد مع صلاحيات دقيقة لكل موظف.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13.2,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 22),
                          const _FeatureGrid(),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactAuthHero extends StatelessWidget {
  const _CompactAuthHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(_kAuthBackgroundAsset, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withValues(alpha: 0.58),
                  const Color(0xFF0B5E34).withValues(alpha: 0.38),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const MasterBrandMark(width: 110, height: 48, onDark: true),
                const SizedBox(height: 6),
                const Text(
                  'لوحة تحكم متكاملة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'إدارة المنصة الخاصة بك من مكان واحد',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
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

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    const items = <_FeatureItemData>[
      _FeatureItemData(
        icon: Icons.analytics_outlined,
        title: 'إدارة شاملة',
        subtitle: 'لوحة واحدة لكل العمليات',
      ),
      _FeatureItemData(
        icon: Icons.security_outlined,
        title: 'أمان وموثوقية',
        subtitle: 'صلاحيات واضحة لكل حساب',
      ),
      _FeatureItemData(
        icon: Icons.schedule_outlined,
        title: 'الوقت الفعلي',
        subtitle: 'متابعة تشغيلية لحظية',
      ),
      _FeatureItemData(
        icon: Icons.headset_mic_outlined,
        title: 'دعم مستمر',
        subtitle: 'فريق متابعة جاهز دائماً',
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => Container(
              width: 150,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(item.icon, color: const Color(0xFF6DE3A2), size: 18),
                  const SizedBox(height: 10),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AuthSubtitle extends StatelessWidget {
  const _AuthSubtitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final brand = 'FOXA';
    final brandIndex = text.indexOf(brand);

    if (brandIndex < 0) {
      return Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14.5,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 14.5,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(text: text.substring(0, brandIndex)),
          TextSpan(
            text: brand,
            style: TextStyle(
              color: _kPrimaryGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: text.substring(brandIndex + brand.length)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _FeatureItemData {
  const _FeatureItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

class MasterTextField extends StatelessWidget {
  const MasterTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    required this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
    this.maxLength,
    this.maxLines = 1,
    this.readOnly = false,
    this.textAlign = TextAlign.start,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String? value)? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final int? maxLength;
  final int maxLines;
  final bool readOnly;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3C4350),
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          maxLength: maxLength,
          maxLines: maxLines,
          readOnly: readOnly,
          textAlign: textAlign,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(prefixIcon, size: 18),
            suffixIcon: suffixIcon,
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0x17000000)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0x17000000)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _kPrimaryGreen, width: 1.2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE26A5E),
                width: 1.1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFE26A5E),
                width: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MasterPrimaryButton extends StatelessWidget {
  const MasterPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_kPrimaryGreen, _kAccentGreen],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kPrimaryGreen.withValues(alpha: 0.24),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : onPressed,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(icon, size: 18),
          label: Text(
            label,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            disabledForegroundColor: Colors.white70,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class MasterOutlinedButton extends StatelessWidget {
  const MasterOutlinedButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_kPrimaryGreen),
                ),
              )
            : Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _kPrimaryGreen,
          side: const BorderSide(color: _kPrimaryGreen, width: 1.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}

class MasterDividerLabel extends StatelessWidget {
  const MasterDividerLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Expanded(child: Divider(height: 1)),
      ],
    );
  }
}

class _LanguagePill extends StatelessWidget {
  const _LanguagePill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x14000000)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF30353B)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF30353B),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFF30353B),
          ),
        ],
      ),
    );
  }
}
