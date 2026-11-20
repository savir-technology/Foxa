// ignore_for_file: unused_element

part of '../../../../../master_auth_app.dart';

class _OrdersMainWorkspace extends StatelessWidget {
  const _OrdersMainWorkspace({
    required this.data,
    required this.serverNow,
    required this.onReload,
    required this.searchController,
    required this.paymentFilter,
    required this.statusFilter,
    required this.typeFilter,
    required this.onSearchSubmitted,
    required this.onPaymentChanged,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.showInsightsSidebar,
    required this.showNavigationSidebar,
    required this.onToggleInsightsSidebar,
    required this.onToggleNavigationSidebar,
    required this.onExport,
    this.onSubPageTap,
    this.activeSubPage = 'all',
  });

  final _MasterOrdersData data;
  final DateTime serverNow;
  final VoidCallback onReload;
  final TextEditingController searchController;
  final String paymentFilter;
  final String statusFilter;
  final String typeFilter;
  final VoidCallback onSearchSubmitted;
  final ValueChanged<String> onPaymentChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onTypeChanged;
  final bool showInsightsSidebar;
  final bool showNavigationSidebar;
  final VoidCallback onToggleInsightsSidebar;
  final VoidCallback onToggleNavigationSidebar;
  final VoidCallback onExport;
  final ValueChanged<String>? onSubPageTap;
  final String activeSubPage;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _OrdersHeaderBar(
          serverNow: serverNow,
          onReload: onReload,
          showInsightsSidebar: showInsightsSidebar,
          showNavigationSidebar: showNavigationSidebar,
          onToggleInsightsSidebar: onToggleInsightsSidebar,
          onToggleNavigationSidebar: onToggleNavigationSidebar,
        ),
        const SizedBox(height: 8),
        if (onSubPageTap != null) ...[
          _OrdersSectionTabs(activeKey: activeSubPage, onTap: onSubPageTap!),
          const SizedBox(height: 8),
        ],
        _OrdersStatsStrip(cards: data.stats),
        const SizedBox(height: 8),
        _OrdersToolbar(
          data: data,
          onReload: onReload,
          searchController: searchController,
          paymentFilter: paymentFilter,
          statusFilter: statusFilter,
          typeFilter: typeFilter,
          onSearchSubmitted: onSearchSubmitted,
          onPaymentChanged: onPaymentChanged,
          onStatusChanged: onStatusChanged,
          onTypeChanged: onTypeChanged,
          onExport: onExport,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 980;
              if (compact && showInsightsSidebar) {
                return Column(
                  children: [
                    Expanded(child: _OrdersTablePanel(data: data)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 178,
                      child: _OrdersInsightsPanel(data: data),
                    ),
                  ],
                );
              }
              return Row(
                textDirection: TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showInsightsSidebar) ...[
                    SizedBox(
                      width: compact ? 190 : 228,
                      child: _OrdersInsightsPanel(data: data),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(child: _OrdersTablePanel(data: data)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OrdersSectionTabs extends StatelessWidget {
  const _OrdersSectionTabs({required this.activeKey, required this.onTap});

  final String activeKey;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    const tabs = <(String, String, IconData)>[
      ('all', 'كل الطلبات', Icons.receipt_long_outlined),
      ('statuses', 'حالات الطلبات', Icons.track_changes_outlined),
      ('scheduled', 'المجدولة', Icons.schedule_outlined),
      ('pickup', 'Pickup', Icons.storefront_outlined),
      ('printing', 'الفواتير والطباعة', Icons.print_outlined),
      ('chats', 'محادثات الطلبات', Icons.forum_outlined),
    ];
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SizedBox(
        width: double.infinity,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(
            reverse: true,
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final tab in tabs) ...[
                  ChoiceChip(
                    selected: activeKey == tab.$1,
                    label: Text(tab.$2),
                    avatar: Icon(tab.$3, size: 16),
                    onSelected: (_) => onTap(tab.$1),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
