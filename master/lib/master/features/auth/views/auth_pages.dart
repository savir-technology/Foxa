// ignore_for_file: unused_element, dead_code

part of '../../../../master_auth_app.dart';

class MasterLoadingPage extends StatelessWidget {
  const MasterLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF061D14), Color(0xFF0C2718), Color(0xFF12311F)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.22,
                child: Image.asset(_kBackgroundAsset, fit: BoxFit.cover),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.2),
                    radius: 1.2,
                    colors: [
                      Colors.white.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MasterBrandMark(width: 180, height: 72),
                  const SizedBox(height: 18),
                  const MasterStateAnimation(size: 88),
                  const SizedBox(height: 6),
                  Text(
                    'جاري تجهيز لوحة الماستر...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MasterPortalDefinition {
  const MasterPortalDefinition({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String key;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

const List<MasterPortalDefinition> _masterPortals = [
  MasterPortalDefinition(
    key: 'finance',
    title: 'الإدارة المالية',
    description: 'الإيرادات والمحافظ والعروض والتقارير المالية',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFFF59E0B),
  ),
  MasterPortalDefinition(
    key: 'support',
    title: 'الدعم الفني',
    description: 'الدردشات ومتابعة العملاء والسائقين',
    icon: Icons.support_agent_rounded,
    color: Color(0xFFEC4899),
  ),
  MasterPortalDefinition(
    key: 'operations',
    title: 'إدارة العمليات',
    description: 'الطلبات والتوصيل والموافقات والحظر',
    icon: Icons.local_shipping_rounded,
    color: Color(0xFF2563EB),
  ),
  MasterPortalDefinition(
    key: 'merchants',
    title: 'إدارة المطاعم والمتاجر',
    description: 'المتاجر والمنتجات والأقسام والإعلانات',
    icon: Icons.storefront_rounded,
    color: Color(0xFF10B981),
  ),
  MasterPortalDefinition(
    key: 'analytics',
    title: 'التقارير والمراقبة',
    description: 'تحليلات المنظومة والمبيعات والمحتوى',
    icon: Icons.analytics_rounded,
    color: Color(0xFF8B5CF6),
  ),
  MasterPortalDefinition(
    key: 'legal',
    title: 'الأمن والشؤون القانونية',
    description: 'السياسات والكوكيز والوثائق القانونية',
    icon: Icons.gavel_rounded,
    color: Color(0xFF64748B),
  ),
];

class MasterPortalPage extends StatelessWidget {
  const MasterPortalPage({
    super.key,
    required this.api,
    required this.onAuthenticated,
  });

  final MasterAuthApiService api;
  final Future<void> Function(MasterSession session) onAuthenticated;

  @override
  Widget build(BuildContext context) {
    // Compatibility alias: legacy routes must use the redesigned portal too.
    return MasterPortalPageV2(api: api, onAuthenticated: onAuthenticated);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF061D14), Color(0xFF0C2718), Color(0xFF12311F)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MasterBrandMark(width: 158, height: 74),
                    const SizedBox(height: 12),
                    const Text(
                      'بوابات إدارة FOXA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اختر القسم المطلوب ثم سجّل الدخول بالحساب المخصص له',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Expanded(
                      child: GridView.builder(
                        itemCount: _masterPortals.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 360,
                              mainAxisExtent: 154,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                        itemBuilder: (context, index) {
                          final portal = _masterPortals[index];
                          return _MasterPortalCard(
                            portal: portal,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MasterLoginPage(
                                    api: api,
                                    portal: portal,
                                    onAuthenticated: onAuthenticated,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
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

class _MasterPortalCard extends StatelessWidget {
  const _MasterPortalCard({required this.portal, required this.onTap});

  final MasterPortalDefinition portal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _MasterPortalCardAnimated(portal: portal, onTap: onTap);
  }
}

class _MasterPortalCardAnimated extends StatefulWidget {
  const _MasterPortalCardAnimated({required this.portal, required this.onTap});

  final MasterPortalDefinition portal;
  final VoidCallback onTap;

  @override
  State<_MasterPortalCardAnimated> createState() =>
      _MasterPortalCardAnimatedState();
}

class _MasterPortalCardAnimatedState extends State<_MasterPortalCardAnimated> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final portal = widget.portal;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.018 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: _hovered ? 12 : 2,
          shadowColor: portal.color.withValues(alpha: 0.22),
          color: Colors.white.withValues(alpha: 0.98),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: _hovered
                  ? portal.color.withValues(alpha: 0.35)
                  : const Color(0x22FFFFFF),
            ),
          ),
          child: InkWell(
            onTap: widget.onTap,
            splashColor: portal.color.withValues(alpha: 0.08),
            highlightColor: portal.color.withValues(alpha: 0.035),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: portal.color.withValues(
                        alpha: _hovered ? 0.18 : 0.11,
                      ),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Icon(portal.icon, color: portal.color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          portal.title,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF10231A),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          portal.description,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF5B6B63),
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedSlide(
                    offset: _hovered ? const Offset(-0.16, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: portal.color,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MasterPortalPageV2 extends StatelessWidget {
  const MasterPortalPageV2({
    super.key,
    required this.api,
    required this.onAuthenticated,
  });

  final MasterAuthApiService api;
  final Future<void> Function(MasterSession session) onAuthenticated;

  @override
  Widget build(BuildContext context) {
    void openPortal(MasterPortalDefinition portal) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MasterLoginPage(
            api: api,
            portal: portal,
            onAuthenticated: onAuthenticated,
          ),
        ),
      );
    }

    return _PortalV3Shell(portals: _masterPortals, onPortalTap: openPortal);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3F8F5), Color(0xFFE8F1EB)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320, minHeight: 680),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 900;
                    final chooser = _PortalV2Chooser(
                      portals: _masterPortals,
                      onPortalTap: openPortal,
                    );
                    const hero = _PortalV2Hero();
                    return compact
                        ? Column(
                            children: [
                              const SizedBox(height: 250, child: hero),
                              const SizedBox(height: 12),
                              Expanded(child: chooser),
                            ],
                          )
                        : Row(
                            textDirection: TextDirection.rtl,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(flex: 7, child: chooser),
                              const SizedBox(width: 18),
                              const Expanded(flex: 5, child: hero),
                            ],
                          );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PortalV3Shell extends StatelessWidget {
  const _PortalV3Shell({required this.portals, required this.onPortalTap});

  final List<MasterPortalDefinition> portals;
  final ValueChanged<MasterPortalDefinition> onPortalTap;

  @override
  Widget build(BuildContext context) {
    final ordered = [
      portals[1],
      portals[0],
      portals[2],
      portals[3],
      portals[5],
      portals[4],
    ];

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/img/back.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xCC021E17),
                    const Color(0x33021E17),
                    Colors.white.withValues(alpha: 0.08),
                  ],
                  stops: const [0, 0.44, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1460,
                  minHeight: 680,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 980;
                      final panel = _PortalV3Workspace(
                        portals: ordered,
                        onPortalTap: onPortalTap,
                      );
                      const identity = _PortalV3Identity();
                      return compact
                          ? Column(
                              children: [
                                Expanded(child: panel),
                                const SizedBox(height: 18),
                                const SizedBox(height: 280, child: identity),
                              ],
                            )
                          : Row(
                              textDirection: TextDirection.rtl,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(flex: 7, child: panel),
                                const SizedBox(width: 24),
                                const Expanded(flex: 5, child: identity),
                              ],
                            );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PortalV3Identity extends StatelessWidget {
  const _PortalV3Identity();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 34, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _PortalV3Brand(),
          const Spacer(),
          const Text(
            'منصة التحكم الموحدة',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'إدارة وتشغيل منظومة التوصيل والمتاجر والمطاعم\nعلى نطاق واسع من مساحة عمل واحدة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 15,
              height: 1.7,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 26),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PortalV3Feature(icon: Icons.shield_outlined, label: 'أمان عالي'),
              SizedBox(width: 10),
              _PortalV3Feature(icon: Icons.bolt_rounded, label: 'أداء سريع'),
              SizedBox(width: 10),
              _PortalV3Feature(
                icon: Icons.analytics_outlined,
                label: 'تقارير دقيقة',
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _PortalV3Brand extends StatelessWidget {
  const _PortalV3Brand();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFF8ED12A),
          borderRadius: BorderRadius.circular(17),
          boxShadow: const [
            BoxShadow(color: Color(0x558ED12A), blurRadius: 22),
          ],
        ),
        child: const Icon(
          Icons.location_on_rounded,
          color: Color(0xFF07513E),
          size: 32,
        ),
      ),
      const SizedBox(width: 14),
      const Text(
        'FOXA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _PortalV3Feature extends StatelessWidget {
  const _PortalV3Feature({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF9BE242), size: 20),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _PortalV3Workspace extends StatelessWidget {
  const _PortalV3Workspace({required this.portals, required this.onPortalTap});

  final List<MasterPortalDefinition> portals;
  final ValueChanged<MasterPortalDefinition> onPortalTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(34, 28, 34, 24),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFD).withValues(alpha: 0.97),
      borderRadius: BorderRadius.circular(34),
      border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55001812),
          blurRadius: 40,
          offset: Offset(0, 18),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اختر مساحة العمل',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Color(0xFF081A15),
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'سجّل الدخول بالحساب المخصص للقسم المطلوب',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: const Color(0xFF53675E).withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFE2F4E8),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFC9E7D4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shield_rounded,
                    color: Color(0xFF5C9E1A),
                    size: 18,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'مساحة عمل آمنة',
                    style: TextStyle(
                      color: Color(0xFF18593C),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            itemCount: portals.length,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300,
              mainAxisExtent: 154,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) => _PortalV3Card(
              portal: portals[index],
              onTap: () => onPortalTap(portals[index]),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6F0),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFD2EBDD)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF56766A),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'يمكنك العودة واختيار مساحة أخرى في أي وقت',
                style: TextStyle(
                  color: Color(0xFF48675A),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PortalV3Card extends StatefulWidget {
  const _PortalV3Card({required this.portal, required this.onTap});

  final MasterPortalDefinition portal;
  final VoidCallback onTap;

  @override
  State<_PortalV3Card> createState() => _PortalV3CardState();
}

class _PortalV3CardState extends State<_PortalV3Card> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final portal = widget.portal;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: hovered ? portal.color.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hovered
                ? portal.color.withValues(alpha: 0.55)
                : const Color(0xFFDDE6E1),
          ),
          boxShadow: [
            BoxShadow(
              color: portal.color.withValues(alpha: hovered ? 0.16 : 0.06),
              blurRadius: hovered ? 18 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: portal.color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(portal.icon, color: portal.color, size: 27),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: hovered ? portal.color : const Color(0xFFF1F5F3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: hovered ? Colors.white : const Color(0xFF86988F),
                        size: 17,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  portal.title,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF091C15),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  portal.description,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF65776E),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PortalV2Hero extends StatelessWidget {
  const _PortalV2Hero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF041C15), Color(0xFF0A3C2D)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(
              top: -90,
              right: -70,
              child: _PortalV2Glow(color: Color(0x2E8ED12A), size: 260),
            ),
            const Positioned(
              bottom: -110,
              left: -90,
              child: _PortalV2Glow(color: Color(0x213AC69A), size: 300),
            ),
            Padding(
              padding: const EdgeInsets.all(38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'FOXA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8ED12A),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF07513E),
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Text(
                        'MASTER PLATFORM  /  INTERNAL ACCESS',
                        style: TextStyle(
                          color: Color(0xFFB9D6C8),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                        'مساحة التحكم\nفي منصة FOXA',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'أدر العمليات، راقب الأداء، واتخذ القرار من مكان واحد.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _PortalV2Badge(
                        icon: Icons.shield_outlined,
                        label: 'دخول آمن',
                      ),
                      SizedBox(width: 8),
                      _PortalV2Badge(
                        icon: Icons.bolt_rounded,
                        label: 'بيانات مباشرة',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PortalV2Chooser extends StatelessWidget {
  const _PortalV2Chooser({required this.portals, required this.onPortalTap});

  final List<MasterPortalDefinition> portals;
  final ValueChanged<MasterPortalDefinition> onPortalTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE0EAE3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12052A1E),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '6 OPERATIONAL DOMAINS',
                style: TextStyle(
                  color: Color(0xFF8A9B91),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5EE),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  'SECURE WORKSPACE',
                  style: TextStyle(
                    color: Color(0xFF16734A),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'اختر مساحة العمل',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Color(0xFF10231A),
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'سجّل الدخول بالحساب المخصص للقسم المطلوب',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Color(0xFF718078),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const MasterBrandMark(width: 86, height: 42),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              itemCount: portals.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 340,
                mainAxisExtent: 116,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) => _PortalV2Card(
                portal: portals[index],
                onTap: () => onPortalTap(portals[index]),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'يمكنك العودة واختيار بوابة أخرى في أي وقت',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9AA8A0), fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _PortalV2Card extends StatefulWidget {
  const _PortalV2Card({required this.portal, required this.onTap});

  final MasterPortalDefinition portal;
  final VoidCallback onTap;

  @override
  State<_PortalV2Card> createState() => _PortalV2CardState();
}

class _PortalV2CardState extends State<_PortalV2Card> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final portal = widget.portal;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: hovered
              ? portal.color.withValues(alpha: 0.055)
              : const Color(0xFFFBFCFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hovered
                ? portal.color.withValues(alpha: 0.42)
                : const Color(0xFFE6ECE8),
          ),
          boxShadow: hovered
              ? [
                  BoxShadow(
                    color: portal.color.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 7),
                  ),
                ]
              : const [],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: portal.color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(portal.icon, color: portal.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        portal.title,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF10231A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        portal.description,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF718078),
                          fontSize: 11.2,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_back_rounded,
                  color: hovered ? portal.color : const Color(0xFF9BA7A0),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PortalV2Glow extends StatelessWidget {
  const _PortalV2Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _PortalV2Badge extends StatelessWidget {
  const _PortalV2Badge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: const Color(0xFF9BE242)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class MasterLoginPage extends StatefulWidget {
  const MasterLoginPage({
    super.key,
    required this.api,
    required this.onAuthenticated,
    this.portal,
  });

  final MasterAuthApiService api;
  final Future<void> Function(MasterSession session) onAuthenticated;
  final MasterPortalDefinition? portal;

  @override
  State<MasterLoginPage> createState() => _MasterLoginPageState();
}

class _MasterLoginPageState extends State<MasterLoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final session = await widget.api.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        portal: widget.portal?.key,
      );
      await widget.onAuthenticated(session);
      // The app shell is rebuilt by onAuthenticated, but this page was
      // opened with Navigator.push. Remove the login route immediately so
      // the new authenticated shell is visible without a browser reload.
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on MasterApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('تعذر إتمام تسجيل الدخول');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterAuthShell(
      title: 'تسجيل الدخول',
      subtitle: 'مرحباً بك في لوحة تحكم منصة FOXA',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MasterTextField(
              label: 'البريد الإلكتروني',
              hintText: 'أدخل بريدك الإلكتروني',
              controller: _emailController,
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'أدخل البريد الإلكتروني';
                }
                if (!text.contains('@')) {
                  return 'البريد الإلكتروني غير صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            MasterTextField(
              label: 'كلمة المرور',
              hintText: 'أدخل كلمة المرور',
              controller: _passwordController,
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              suffixIcon: IconButton(
                splashRadius: 18,
                iconSize: 18,
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return 'أدخل كلمة المرور';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() => _rememberMe = value ?? true);
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'تذكرني',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            MasterForgotPasswordPage(api: widget.api),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _kPrimaryGreen,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'نسيت كلمة المرور؟',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MasterPrimaryButton(
              label: 'تسجيل الدخول',
              icon: Icons.login_rounded,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 18),
            const MasterDividerLabel(label: 'أو'),
            const SizedBox(height: 18),
            MasterOutlinedButton(
              label: 'إنشاء حساب موظف',
              icon: Icons.verified_user_outlined,
              onPressed: _startEmployeeSignup,
            ),
            const SizedBox(height: 18),
            if (false)
              TextButton.icon(
                onPressed: () {
                  _showMasterSnack(
                    context,
                    'الموقع الرئيسي غير مضاف داخل نسخة لوحة الماستر بعد',
                  );
                },
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text(
                  'العودة إلى الموقع الرئيسي',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF3B3B3B),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startEmployeeSignup() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final verifiedEmail = await widget.api.requestEmployeeSignupCode();
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MasterVerificationCodePage(
            api: widget.api,
            email: verifiedEmail,
            flow: VerificationFlow.employeeSignup,
          ),
        ),
      );
    } on MasterApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('تعذر إرسال كود التحقق إلى بريد الماستر');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class MasterSignupPage extends StatefulWidget {
  const MasterSignupPage({
    super.key,
    required this.api,
    this.ownerEmail,
    this.ownerCode,
  });

  final MasterAuthApiService api;
  final String? ownerEmail;
  final String? ownerCode;

  @override
  State<MasterSignupPage> createState() => _MasterSignupPageState();
}

class _MasterSignupPageState extends State<MasterSignupPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = true;
  bool _isLoading = false;
  bool _rolesLoading = true;
  bool _canCreateSuperAdmin = false;
  String? _rolesError;
  List<MasterRoleProfile> _roles = [];
  MasterRoleProfile? _selectedRole;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    setState(() {
      _rolesLoading = true;
      _rolesError = null;
    });

    try {
      final result = await widget.api.fetchRoles();
      final filteredRoles = result.roles
          .where((role) => role.roleId >= 10 && role.roleId <= 15)
          .toList();

      if (!mounted) {
        return;
      }
      setState(() {
        _roles = filteredRoles;
        _canCreateSuperAdmin = result.canCreateSuperAdmin;
        _selectedRole = filteredRoles.isNotEmpty ? filteredRoles.first : null;
        _rolesLoading = false;
      });
    } on MasterApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _rolesError = e.message;
        _rolesLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _rolesError = 'تعذر تحميل الأدوار';
        _rolesLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_selectedRole == null) {
      _showMessage('اختر الدور الوظيفي');
      return;
    }
    if (!_acceptTerms) {
      _showMessage('يجب الموافقة على الشروط والمتابعة');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('كلمتا المرور غير متطابقتين');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await widget.api.signup(
        adminName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        roleId: _selectedRole!.roleId,
        ownerEmail: widget.ownerEmail,
        ownerCode: widget.ownerCode,
      );

      if (!mounted) {
        return;
      }
      if (!result.verificationRequired) {
        _showMessage('تم إنشاء الحساب. في انتظار موافقة الأدمن الأساسي.');
        Navigator.of(context).pop();
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MasterVerificationCodePage(
            api: widget.api,
            email: result.email,
            flow: VerificationFlow.signup,
          ),
        ),
      );
    } on MasterApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('تعذر إنشاء الحساب');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roleOptions = _roles;

    return MasterAuthShell(
      title: 'إنشاء حساب موظف',
      subtitle: 'أنشئ حساباً جديداً للدخول إلى لوحة الماستر',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MasterTextField(
              label: 'الاسم الكامل',
              hintText: 'أدخل الاسم الكامل',
              controller: _nameController,
              prefixIcon: Icons.badge_outlined,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'أدخل الاسم الكامل';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            MasterTextField(
              label: 'البريد الإلكتروني',
              hintText: 'أدخل البريد الإلكتروني',
              controller: _emailController,
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'أدخل البريد الإلكتروني';
                }
                if (!text.contains('@')) {
                  return 'البريد الإلكتروني غير صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            MasterTextField(
              label: 'رقم الهاتف',
              hintText: 'مثال: +9639xxxxxxx',
              controller: _phoneController,
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'أدخل رقم الهاتف';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            if (_rolesLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              )
            else if (_rolesError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3F0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFFD2C9)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: Color(0xFFD65A31),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _rolesError!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF8B2E14),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loadRoles,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<MasterRoleProfile>(
                initialValue: _selectedRole,
                isDense: true,
                decoration: InputDecoration(
                  labelText: 'الدور الوظيفي',
                  hintText: 'اختر الدور',
                  prefixIcon: const Icon(Icons.work_outline_rounded, size: 18),
                  filled: true,
                  fillColor: Colors.white,
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
                    borderSide: const BorderSide(
                      color: _kPrimaryGreen,
                      width: 1.2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                ),
                items: roleOptions
                    .map(
                      (role) => DropdownMenuItem<MasterRoleProfile>(
                        value: role,
                        child: Text(
                          role.roleName,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedRole = value),
                validator: (value) =>
                    value == null ? 'اختر الدور الوظيفي' : null,
              ),
            const SizedBox(height: 10),
            if (_canCreateSuperAdmin)
              Text(
                'يمكن إنشاء الأدمن الأساسي من هذه الشاشة.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              )
            else
              Text(
                'الدور الأساسي محجوز بعد إنشاء الأدمن الأول.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 14),
            MasterTextField(
              label: 'كلمة المرور',
              hintText: 'أدخل كلمة مرور قوية',
              controller: _passwordController,
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                splashRadius: 18,
                iconSize: 18,
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return 'أدخل كلمة المرور';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            MasterTextField(
              label: 'تأكيد كلمة المرور',
              hintText: 'أعد إدخال كلمة المرور',
              controller: _confirmPasswordController,
              prefixIcon: Icons.lock_reset_outlined,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                splashRadius: 18,
                iconSize: 18,
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return 'أعد إدخال كلمة المرور';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            CheckboxListTile(
              value: _acceptTerms,
              onChanged: (value) =>
                  setState(() => _acceptTerms = value ?? true),
              controlAffinity: ListTileControlAffinity.trailing,
              contentPadding: EdgeInsets.zero,
              dense: true,
              visualDensity: VisualDensity.compact,
              title: const Text(
                'أوافق على الشروط والأحكام وسياسة الاستخدام',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 10),
            MasterPrimaryButton(
              label: 'إنشاء الحساب',
              icon: Icons.person_add_alt_1_rounded,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'لديك حساب بالفعل؟ تسجيل الدخول',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum VerificationFlow { signup, reset, employeeSignup }

class MasterVerificationCodePage extends StatefulWidget {
  const MasterVerificationCodePage({
    super.key,
    required this.api,
    required this.email,
    required this.flow,
  });

  final MasterAuthApiService api;
  final String email;
  final VerificationFlow flow;

  @override
  State<MasterVerificationCodePage> createState() =>
      _MasterVerificationCodePageState();
}

class _MasterVerificationCodePageState
    extends State<MasterVerificationCodePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  bool _resending = false;

  String get _displayEmail {
    final email = widget.email.trim();
    final separator = email.indexOf('@');
    if (separator <= 0) return email;
    final localPart = email.substring(0, separator);
    final domain = email.substring(separator);
    final visibleCount = localPart.length < 3 ? localPart.length : 3;
    return '${localPart.substring(0, visibleCount)}***$domain';
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String get _title => widget.flow == VerificationFlow.signup
      ? 'تأكيد البريد الإلكتروني'
      : 'التحقق من الرمز';
  String get _subtitle => widget.flow == VerificationFlow.signup
      ? 'أدخل رمز التحقق المرسل إلى البريد الإلكتروني'
      : 'أدخل رمز الاسترجاع الذي وصل إلى بريدك الإلكتروني';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.flow == VerificationFlow.signup) {
        await widget.api.verifySignupCode(
          email: widget.email,
          code: _codeController.text.trim(),
        );
        if (!mounted) {
          return;
        }
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (widget.flow == VerificationFlow.employeeSignup) {
        await widget.api.verifyResetCode(
          email: widget.email,
          code: _codeController.text.trim(),
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MasterSignupPage(
              api: widget.api,
              ownerEmail: widget.email,
              ownerCode: _codeController.text.trim(),
            ),
          ),
        );
      } else {
        await widget.api.verifyResetCode(
          email: widget.email,
          code: _codeController.text.trim(),
        );
        if (!mounted) {
          return;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => MasterResetPasswordPage(
              api: widget.api,
              email: widget.email,
              code: _codeController.text.trim(),
            ),
          ),
        );
      }
    } on MasterApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('تعذر التحقق من الرمز');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      if (widget.flow == VerificationFlow.signup) {
        await widget.api.resendSignupCode(widget.email);
      } else if (widget.flow == VerificationFlow.employeeSignup) {
        await widget.api.requestEmployeeSignupCode();
      } else {
        await widget.api.requestPasswordReset(widget.email);
      }
      _showMessage('تم إرسال رمز جديد');
    } on MasterApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('تعذر إعادة الإرسال');
    } finally {
      if (mounted) {
        setState(() => _resending = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterAuthShell(
      title: _title,
      subtitle: _subtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5FAF7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x1A177A48)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _kPrimaryGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.mark_email_read_outlined,
                      size: 20,
                      color: _kPrimaryGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تم إرسال الكود إلى البريد الإلكتروني',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _displayEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            MasterTextField(
              label: widget.flow == VerificationFlow.signup
                  ? 'رمز التحقق'
                  : 'رمز الاسترجاع',
              hintText: 'أدخل الرمز المكون من 6 أرقام',
              controller: _codeController,
              prefixIcon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              validator: (value) {
                if ((value ?? '').trim().length != 6) {
                  return 'أدخل الرمز المكون من 6 أرقام';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            MasterPrimaryButton(
              label: widget.flow == VerificationFlow.signup
                  ? 'تأكيد الحساب'
                  : 'تأكيد الرمز',
              icon: Icons.verified_outlined,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
            MasterOutlinedButton(
              label: 'إعادة إرسال الكود',
              icon: Icons.refresh_rounded,
              isLoading: _resending,
              onPressed: _resend,
            ),
            const SizedBox(height: 18),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'العودة للخلف',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MasterForgotPasswordPage extends StatefulWidget {
  const MasterForgotPasswordPage({super.key, required this.api});

  final MasterAuthApiService api;

  @override
  State<MasterForgotPasswordPage> createState() =>
      _MasterForgotPasswordPageState();
}

class _MasterForgotPasswordPageState extends State<MasterForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.api.requestPasswordReset(_emailController.text.trim());
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MasterCheckMailPage(
            api: widget.api,
            email: _emailController.text.trim(),
          ),
        ),
      );
    } on MasterApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('تعذر طلب إعادة التعيين');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterAuthShell(
      title: 'نسيت كلمة المرور',
      subtitle: 'أدخل البريد الإلكتروني المرتبط بالحساب',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MasterTextField(
              label: 'البريد الإلكتروني',
              hintText: 'أدخل البريد الإلكتروني',
              controller: _emailController,
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                final text = value?.trim() ?? '';
                if (text.isEmpty) {
                  return 'أدخل البريد الإلكتروني';
                }
                if (!text.contains('@')) {
                  return 'البريد الإلكتروني غير صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            MasterPrimaryButton(
              label: 'إرسال رمز الاسترجاع',
              icon: Icons.send_rounded,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'العودة إلى تسجيل الدخول',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MasterCheckMailPage extends StatefulWidget {
  const MasterCheckMailPage({
    super.key,
    required this.api,
    required this.email,
  });

  final MasterAuthApiService api;
  final String email;

  @override
  State<MasterCheckMailPage> createState() => _MasterCheckMailPageState();
}

class _MasterCheckMailPageState extends State<MasterCheckMailPage> {
  bool _isResending = false;

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      await widget.api.requestPasswordReset(widget.email);
      _showMessage('تم إعادة إرسال الرمز');
    } on MasterApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('تعذر إعادة الإرسال');
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterAuthShell(
      title: 'تحقق من البريد',
      subtitle: 'راجع صندوق الوارد وأدخل رمز التحقق',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5FAF7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0x1A177A48)),
            ),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: _kPrimaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 28,
                    color: _kPrimaryGreen,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'تم إرسال رسالة إلى بريدك الإلكتروني',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.email,
                  style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          MasterPrimaryButton(
            label: 'إدخال رمز التحقق',
            icon: Icons.verified_outlined,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MasterVerificationCodePage(
                    api: widget.api,
                    email: widget.email,
                    flow: VerificationFlow.reset,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          MasterOutlinedButton(
            label: 'إعادة إرسال الرمز',
            icon: Icons.refresh_rounded,
            isLoading: _isResending,
            onPressed: _resend,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text(
              'العودة إلى تسجيل الدخول',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class MasterResetPasswordPage extends StatefulWidget {
  const MasterResetPasswordPage({
    super.key,
    required this.api,
    required this.email,
    required this.code,
  });

  final MasterAuthApiService api;
  final String email;
  final String code;

  @override
  State<MasterResetPasswordPage> createState() =>
      _MasterResetPasswordPageState();
}

class _MasterResetPasswordPageState extends State<MasterResetPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showMessage('كلمتا المرور غير متطابقتين');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.api.resetPassword(
        email: widget.email,
        code: widget.code,
        password: _passwordController.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on MasterApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('تعذر تحديث كلمة المرور');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasterAuthShell(
      title: 'إعادة تعيين كلمة المرور',
      subtitle: 'ضع كلمة مرور جديدة وآمنة',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MasterTextField(
              label: 'البريد الإلكتروني',
              hintText: widget.email,
              controller: _emailController,
              prefixIcon: Icons.mail_outline_rounded,
              readOnly: true,
            ),
            const SizedBox(height: 14),
            MasterTextField(
              label: 'كلمة المرور الجديدة',
              hintText: 'أدخل كلمة مرور جديدة',
              controller: _passwordController,
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                splashRadius: 18,
                iconSize: 18,
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return 'أدخل كلمة المرور الجديدة';
                }
                if ((value ?? '').length < 8) {
                  return 'يجب ألا تقل كلمة المرور عن 8 أحرف';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            MasterTextField(
              label: 'تأكيد كلمة المرور',
              hintText: 'أعد إدخال كلمة المرور',
              controller: _confirmPasswordController,
              prefixIcon: Icons.lock_reset_outlined,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                splashRadius: 18,
                iconSize: 18,
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              validator: (value) {
                if ((value ?? '').isEmpty) {
                  return 'أعد إدخال كلمة المرور';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            MasterPrimaryButton(
              label: 'حفظ كلمة المرور',
              icon: Icons.save_outlined,
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text(
                'العودة إلى تسجيل الدخول',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
