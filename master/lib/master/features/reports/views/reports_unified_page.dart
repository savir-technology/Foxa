part of '../../../../master_auth_app.dart';

/// Unified reports workspace. The report data widgets remain reusable, while
/// this page owns the only active reports frame and navigation contract.
class MasterReportsUnifiedPage extends StatefulWidget {
  const MasterReportsUnifiedPage({
    super.key,
    required this.session,
    required this.onLogout,
    required this.api,
    this.serverNow,
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService api;
  final DateTime? serverNow;

  @override
  State<MasterReportsUnifiedPage> createState() =>
      _MasterReportsUnifiedPageState();
}

class _MasterReportsUnifiedPageState extends State<MasterReportsUnifiedPage> {
  String _selectedSub = 'overview';
  final Map<String, Widget> _reportPages = <String, Widget>{};

  static const List<String> _reportKeys = [
    'overview',
    'users',
    'drivers',
    'restaurants',
    'reference',
  ];

  Widget _buildSelectedPage() {
    return _reportPages.putIfAbsent(_selectedSub, () {
      switch (_selectedSub) {
        case 'users':
          return ReportsUsersPage(session: widget.session, api: widget.api);
        case 'drivers':
          return ReportsDriversPage(session: widget.session, api: widget.api);
        case 'restaurants':
          return ReportsRestaurantsPage(
            session: widget.session,
            api: widget.api,
          );
        case 'reference':
          return ReportsReferencePage(session: widget.session, api: widget.api);
        default:
          return ReportsOverviewPage(session: widget.session, api: widget.api);
      }
    });
  }

  Widget _buildReportPages() {
    _buildSelectedPage();
    final selectedIndex = _reportKeys.indexOf(_selectedSub);
    return IndexedStack(
      index: selectedIndex < 0 ? 0 : selectedIndex,
      children: [
        for (final key in _reportKeys)
          _reportPages[key] ?? const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildTab(String key, String label, IconData icon) {
    final selected = _selectedSub == key;
    return ChoiceChip(
      selected: selected,
      avatar: Icon(icon, size: 17),
      label: Text(label),
      onSelected: (_) => setState(() => _selectedSub = key),
      selectedColor: _kDeepGreen,
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF44505B),
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(color: selected ? _kDeepGreen : const Color(0xFFE0E7E2)),
      backgroundColor: Colors.white,
    );
  }

  void _openSidebarItem(String itemKey) {
    final key = _masterCanonicalModuleKey(itemKey);
    if (key == 'reports') return;
    _navigateToMasterSection(
      context,
      key: key,
      session: widget.session,
      onLogout: widget.onLogout,
      api: widget.api,
      serverNow: widget.serverNow,
    );
  }

  @override
  Widget build(BuildContext context) {
    _rememberMasterRuntime(widget.session, widget.onLogout, widget.api);
    final sidebarItems = _masterFilterSidebarItems(widget.session, const [
      _DashboardMenuItemData(
        iconKey: 'reports',
        label: 'التقارير والتحليلات',
        selected: true,
      ),
    ]);
    return _buildMasterUnifiedShell(
      context: context,
      session: widget.session,
      onLogout: widget.onLogout,
      api: widget.api,
      sidebarItems: sidebarItems,
      onSidebarItemTap: _openSidebarItem,
      statusLabel: 'التقارير',
      platformTitle: 'التقارير والتحليلات',
      platformSubtitle: 'تقارير المنصة الشاملة',
      serverNow: widget.serverNow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              _buildTab('overview', 'نظرة عامة', Icons.query_stats_outlined),
              _buildTab('users', 'المستخدمون', Icons.people_outline),
              _buildTab('drivers', 'السائقون', Icons.local_shipping_outlined),
              _buildTab(
                'restaurants',
                'المطاعم والمتاجر',
                Icons.storefront_outlined,
              ),
              _buildTab('reference', 'مرجع شامل', Icons.inventory_2_outlined),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildReportPages()),
        ],
      ),
    );
  }
}
