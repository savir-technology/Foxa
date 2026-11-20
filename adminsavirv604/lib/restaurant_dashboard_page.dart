// ignore_for_file: prefer_const_constructors

import 'dart:async';

import 'package:admin_tks/categories_page.dart';
import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/core/services/dashboard_routes.dart';
import 'package:admin_tks/delivery_operations_page.dart';
import 'package:admin_tks/menu_management_page.dart';
import 'package:admin_tks/model/report_models.dart';
import 'package:admin_tks/model/restaurant_settings_model.dart';
import 'package:admin_tks/model/store_operations_model.dart';
import 'package:admin_tks/model/vendor_dashboard_model.dart';
import 'package:admin_tks/model/admin_notification_model.dart';
import 'package:admin_tks/remote/accounting_data.dart';
import 'package:admin_tks/remote/admin_notifications_data.dart';
import 'package:admin_tks/order_page.dart';
import 'package:admin_tks/notifications_page.dart';
import 'package:admin_tks/profit_report_page.dart';
import 'package:admin_tks/offers_marketing_page.dart';
import 'package:admin_tks/remote/restaurant_settings_data.dart';
import 'package:admin_tks/remote/vendor_dashboard_data.dart';
import 'package:admin_tks/reviews_ratings_page.dart';
import 'package:admin_tks/sales_report_page.dart';
import 'package:admin_tks/statistics_page.dart';
import 'package:admin_tks/story_management_page.dart';
import 'package:admin_tks/restaurant_settings_page.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:admin_tks/widgets/app_network_image.dart';
import 'package:admin_tks/waste_ledger_page.dart';
import 'package:admin_tks/working_hours_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RestaurantDashboardPage extends StatefulWidget {
  const RestaurantDashboardPage({super.key});

  @override
  State<RestaurantDashboardPage> createState() =>
      _RestaurantDashboardPageState();
}

class _RestaurantDashboardPageState extends State<RestaurantDashboardPage> {
  final VendorDashboardData _dashboardData = VendorDashboardData();
  final RestaurantSettingsData _settingsData = RestaurantSettingsData();
  final AccountingData _accountingData = AccountingData();
  final AdminNotificationsData _notificationsData = AdminNotificationsData();

  Timer? _refreshTimer;
  int _activeSidebarIndex = 0;

  VendorDashboardSnapshot? _snapshot;
  RestaurantSettingsSnapshot? _settings;
  SalesReportResponse? _salesReport;
  AdminNotificationSummary? _notificationSummary;

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  late final List<_DashboardSection> _sections;

  List<_DashboardSection> _buildSections() {
    return [
      const _DashboardSection(
        title: 'نظرة عامة',
        icon: Icons.space_dashboard_rounded,
        description: 'ملخص يومي للطلبات والمبيعات وحالة المطعم.',
        route: DashboardRoutes.home,
      ),
      const _DashboardSection(
        title: 'الطلبات',
        icon: Icons.receipt_long_rounded,
        description: 'إدارة الطلبات الجديدة والجارية والمجدولة من مكان واحد.',
        route: DashboardRoutes.orders,
        pageBuilder: OrderPage.new,
      ),
      _DashboardSection(
        title: 'التسليم والاستلام',
        icon: Icons.delivery_dining_rounded,
        description:
            'متابعة الطلبات بين المطعم والسائق والعملاء في الوقت الفعلي.',
        route: null,
        pageBuilder: () => DeliveryOperationsPage(
          sidebarItems: _sidebarItems,
          activeSidebarIndex: 2,
        ),
      ),
      const _DashboardSection(
        title: 'المنتجات',
        icon: Icons.restaurant_menu_rounded,
        description: 'الأصناف، الصور، الإضافات، والتفاصيل الخاصة بكل صنف.',
        route: DashboardRoutes.menu,
        pageBuilder: MenuManagementPage.new,
      ),
      if (_auth.isMaster)
        const _DashboardSection(
          title: 'الأقسام',
          icon: Icons.category_rounded,
          description: 'تنظيم العروض والوجبات والمشاوي والمشروبات والحلويات.',
          route: DashboardRoutes.categories,
          pageBuilder: CategoriesPage.new,
        ),
      const _DashboardSection(
        title: 'العروض والتسويق',
        icon: Icons.local_offer_rounded,
        description: 'إدارة العروض والخصومات والكوبونات وبرامج التسويق.',
        route: DashboardRoutes.coupons,
        pageBuilder: OffersMarketingPage.new,
      ),
      const _DashboardSection(
        title: 'أوقات العمل',
        icon: Icons.access_time_rounded,
        description: 'ضبط ساعات العمل والإغلاق المؤقت والتعيين التلقائي.',
        route: DashboardRoutes.hours,
        pageBuilder: WorkingHoursPage.new,
      ),
      const _DashboardSection(
        title: 'التقييمات والمراجعات',
        icon: Icons.star_rounded,
        description: 'متابعة آراء العملاء وتصنيفاتهم والشكاوى الشائعة.',
        route: DashboardRoutes.reviews,
        pageBuilder: ReviewsRatingsPage.new,
      ),
      const _DashboardSection(
        title: '\u0627\u0644\u0642\u0635\u0635',
        icon: Icons.auto_stories_rounded,
        description:
            '\u0631\u0641\u0639 \u0627\u0644\u0642\u0635\u0635 \u0627\u0644\u062f\u0627\u062e\u0644\u064a\u0629 \u0648\u062a\u062d\u062f\u064a\u062f \u0627\u0644\u062a\u0648\u062c\u064a\u0647 \u0625\u0644\u0649 \u0645\u0637\u0639\u0645 \u0623\u0648 \u0645\u0646\u062a\u062c.',
        route: null,
        pageBuilder: StoryManagementPage.new,
      ),
      const _DashboardSection(
        title: 'التقارير',
        icon: Icons.query_stats_rounded,
        description: 'تحليلات مباشرة للمبيعات والأداء اليومي والشهري.',
        route: DashboardRoutes.analytics,
        pageBuilder: ProductStatisticsPage.new,
      ),
      const _DashboardSection(
        title: 'الإيرادات',
        icon: Icons.payments_rounded,
        description: 'قراءة سريعة للمبيعات اليومية والأسبوعية والشهرية.',
        route: DashboardRoutes.salesReport,
        pageBuilder: SalesReportPage.new,
      ),
      const _DashboardSection(
        title: 'الأرباح',
        icon: Icons.account_balance_wallet_rounded,
        description: 'متابعة الربح والتكلفة والهامش المالي بسرعة.',
        route: DashboardRoutes.profitReport,
        pageBuilder: ProfitReportPage.new,
      ),
      const _DashboardSection(
        title: 'الإعدادات',
        icon: Icons.tune_rounded,
        description: 'بيانات المطعم وأوقات العمل والموقع وحالة الفتح.',
        route: DashboardRoutes.settings,
        pageBuilder: RestaurantSettingsPage.new,
      ),
      const _DashboardSection(
        title: 'المرتجعات والتالف',
        icon: Icons.delete_sweep_rounded,
        description: 'مراجعة المرتجعات والتالف وحالات الإرجاع غير النشطة.',
        route: DashboardRoutes.waste,
        pageBuilder: WasteLedgerPage.new,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _sections = _buildSections();
    _loadDashboard();
    _refreshTimer = Timer.periodic(const Duration(seconds: 45), (_) {
      if (mounted) {
        _loadDashboard(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    try {
      final results = await Future.wait([
        _dashboardData.getSnapshot(),
        _settingsData.getSettings(),
        _accountingData.getSalesReport(),
        _notificationsData.getAll(),
      ]);

      if (!mounted) return;
      final snapshot = results[0] as VendorDashboardSnapshot?;
      final settings = results[1] as RestaurantSettingsSnapshot?;
      final salesReport = results[2] as SalesReportResponse?;
      final notifications = results[3] as AdminNotificationResponse?;

      setState(() {
        _snapshot = snapshot;
        _settings = settings;
        _salesReport = salesReport;
        _notificationSummary = notifications?.summary;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Dashboard load failed: $e');
    }
  }

  void _openSection(_DashboardSection section) {
    final route = section.route?.trim() ?? '';
    if (route.isNotEmpty) {
      Get.offNamed(
        route,
        arguments: {
          'sidebarIndex': _sections.indexOf(section),
        },
        preventDuplicates: false,
      );
      return;
    }

    final page = section.pageBuilder?.call();
    if (page == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  void _handleSidebarTap(int index) {
    setState(() => _activeSidebarIndex = index);
    final section = _sections[index];
    _openSection(section);
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (mounted) {
      Get.offAllNamed('/');
    }
  }

  List<Map<String, dynamic>> get _sidebarItems => _sections
      .map(
        (section) => {
          'title': section.title,
          'icon': section.icon,
          'route': section.route,
          'arguments': {'sidebarIndex': _sections.indexOf(section)},
          'page': section.pageBuilder,
        },
      )
      .toList();

  // ignore: unused_element
  String _formatMoney(double value) =>
      '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)} SAR';

  @override
  Widget build(BuildContext context) {
    final shellSnapshot = _snapshot;
    final shellSettings = _settings;
    final shellSalesReport = _salesReport;
    final unreadNotifications = _notificationSummary?.unreadCount ?? 0;
    final summary = shellSnapshot?.summary;
    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth < 1280 ? 76.0 : 248.0;
    final contentWidth = (screenWidth - sidebarWidth - 44)
        .clamp(0.0, double.infinity)
        .toDouble();
    final statCardWidth =
        (((contentWidth - 24) / 3).clamp(220.0, 420.0)).toDouble();

    final shellStats = <Widget>[
      DashboardStatCard(
        label: 'الطلبات الجديدة',
        subtitle: 'عدد الطلبات الجديدة التي لم يتم قبولها بعد',
        value: '${summary?.newOrdersCount ?? 0}',
        valueLabel: 'طلب',
        icon: Icons.shopping_bag_rounded,
        tint: const Color(0xFF1B7A3A),
        width: statCardWidth,
      ),
      DashboardStatCard(
        label: 'قيد التحضير',
        subtitle: 'عدد الطلبات قيد التحضير',
        value: '${summary?.preparingCount ?? 0}',
        valueLabel: 'طلب',
        icon: Icons.assignment_rounded,
        tint: const Color(0xFFF59E0B),
        width: statCardWidth,
      ),
      DashboardStatCard(
        label: 'جاهزة للاستلام',
        subtitle: 'عدد الطلبات الجاهزة للاستلام',
        value: '${summary?.readyToReceiveCount ?? 0}',
        valueLabel: 'طلب',
        icon: Icons.work_outline_rounded,
        tint: const Color(0xFF2563EB),
        width: statCardWidth,
      ),
      DashboardStatCard(
        label: 'تم توصيلها اليوم',
        subtitle: 'عدد الطلبات التي تم توصيلها',
        value: '${summary?.inDeliveryCount ?? 0}',
        valueLabel: 'طلب',
        icon: Icons.delivery_dining_rounded,
        tint: const Color(0xFF10B981),
        width: statCardWidth,
      ),
      DashboardStatCard(
        label: 'مكتملة اليوم',
        subtitle: 'إجمالي الطلبات المكتملة',
        value: '${summary?.completedTodayCount ?? 0}',
        valueLabel: 'طلب',
        icon: Icons.verified_rounded,
        tint: const Color(0xFF7C3AED),
        width: statCardWidth,
      ),
      DashboardStatCard(
        label: 'لم يتم تسليمها',
        subtitle: 'عدد الطلبات لم تسلم بعد',
        value:
            '${summary?.notDeliveredCount ?? summary?.canceledTodayCount ?? 0}',
        valueLabel: 'طلب',
        icon: Icons.access_time_rounded,
        tint: const Color(0xFFEF4444),
        width: statCardWidth,
      ),
    ];

    return DashboardPageShell(
      title: 'الصفحة الرئيسية',
      subtitle: 'نظرة عامة على أداء المطعم اليوم',
      icon: Icons.home_rounded,
      actions: [
        _DashboardNotificationButton(
          unreadCount: unreadNotifications,
          onPressed: () => Get.to(() => const NotificationsPage()),
        ),
      ],
      stats: shellStats,
      statusLabel: shellSettings == null
          ? 'جاري تحميل بيانات المطعم'
          : (shellSettings.isOpen ? 'المطعم مفتوح الآن' : 'المطعم مغلق الآن'),
      statusTint: shellSettings == null
          ? kPrimary
          : (shellSettings.isOpen
              ? const Color(0xFF10B981)
              : const Color(0xFFEF4444)),
      sidebarItems: _sidebarItems,
      activeSidebarIndex: _activeSidebarIndex,
      onSidebarItemTap: _handleSidebarTap,
      profileName:
          _auth.displayName.isNotEmpty ? _auth.displayName : _auth.storeName,
      profileSubtitle:
          shellSettings?.vendorDescription?.trim().isNotEmpty == true
              ? shellSettings!.vendorDescription!.trim()
              : 'لوحة إدارة المطعم',
      profileAvatarUrl: shellSettings?.vendorLogo,
      body: _RestaurantDashboardHomeBody(
        snapshot: shellSnapshot,
        settings: shellSettings,
        salesReport: shellSalesReport,
      ),
    );
  }
}
/*

    if (_activeSidebarIndex >= _sections.length) {
      _activeSidebarIndex = 0;
    }

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 760;
    final isTablet = width >= 760 && width < 1180;
    final snapshot = _snapshot;
    final settings = _settings;
    final operations = _operations;
    final notifications = _notifications;
    final summary = snapshot?.summary;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBackground,
      drawer: isMobile
          ? Drawer(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: SafeArea(
                child: AdminSidebar(
                  items: _sidebarItems,
                  activeIndex: _activeSidebarIndex,
                  isCollapsed: false,
                  onItemTap: _handleSidebarTap,
                  onAddPressed: _openAddProduct,
                  onLogoutPressed: _logout,
                ),
              ),
            )
          : null,
      body: DashboardBackground(
        child: SafeArea(
          child: Row(
            children: [
              if (!isMobile)
                AdminSidebar(
                  items: _sidebarItems,
                  activeIndex: _activeSidebarIndex,
                  isCollapsed: isTablet,
                  onItemTap: _handleSidebarTap,
                  onAddPressed: _openAddProduct,
                  onLogoutPressed: _logout,
                ),
              Expanded(
                child: Column(
                  children: [
                    _DashboardTopBar(
                      isMobile: isMobile,
                      statusMessage: _error ??
                          (settings?.isOpen == true ? 'المطعم مفتوح' : 'المطعم مغلق'),
                      storeName: _auth.storeName,
                      displayName: _auth.displayName,
                      onLogoutPressed: _auth.logout,
                      onMenuPressed: () =>
                          _scaffoldKey.currentState?.openDrawer(),
                      onRefreshPressed: () => _loadDashboard(),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          isMobile ? 16 : 24,
                          12,
                          isMobile ? 16 : 24,
                          24,
                        ),
                        child: _loading && snapshot == null
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 100),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: kPrimary,
                                  ),
                                ),
                              )
                            : _error != null && snapshot == null
                                ? DashboardEmptyState(
                                    title: 'تعذر تحميل لوحة المطعم',
                                    subtitle: _error!,
                                    icon: Icons.cloud_off_rounded,
                                  )
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _RestaurantHeroCard(
                                        storeName: _auth.storeName,
                                        vendorName: _auth.vendorName,
                                        settings: settings,
                                        unreadNotifications:
                                            notifications?.summary.unreadCount ??
                                                0,
                                        totalOrders:
                                            summary?.totalOrdersCount ?? 0,
                                        onOpenOrders: () => _openSection(
                                          _sections.firstWhere(
                                            (section) =>
                                                section.title == 'الطلبات',
                                          ),
                                        ),
                                        onOpenMenu: _openAddProduct,
                                        onOpenSettings: () => _openSection(
                                          _sections.firstWhere(
                                            (section) =>
                                                section.title == 'الإعدادات',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const _SectionHeader(
                                        title: 'مؤشرات اليوم',
                                        subtitle:
                                            'كل الأرقام هنا تأتي مباشرة من قاعدة البيانات الحالية للمتجر.',
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          DashboardStatCard(
                                            label: 'جاهزة للشحن',
                                            value:
                                                '${summary?.readyToReceiveCount ?? 0} طلب',
                                            icon: Icons.inbox_rounded,
                                            tint: const Color(0xFF3B82F6),
                                            width: 210,
                                          ),
                                          DashboardStatCard(
                                            label: 'قيد الشحن',
                                            value:
                                                '${summary?.inDeliveryCount ?? 0} طلب',
                                            icon: Icons.local_shipping_rounded,
                                            tint: const Color(0xFF14B8A6),
                                            width: 210,
                                          ),
                                          DashboardStatCard(
                                            label: 'مكتملة اليوم',
                                            value:
                                                '${summary?.completedTodayCount ?? 0} طلب',
                                            icon: Icons.verified_rounded,
                                            tint: const Color(0xFF10B981),
                                            width: 210,
                                          ),
                                          DashboardStatCard(
                                            label: 'ملغاة اليوم',
                                            value:
                                                '${summary?.canceledTodayCount ?? 0} طلب',
                                            icon: Icons.cancel_rounded,
                                            tint: const Color(0xFFEF4444),
                                            width: 210,
                                          ),
                                          DashboardStatCard(
                                            label: 'مبيعات اليوم',
                                            value: _formatMoney(
                                              summary?.salesToday ?? 0,
                                            ),
                                            icon: Icons.attach_money_rounded,
                                            tint: const Color(0xFF3B82F6),
                                            width: 210,
                                          ),
                                          DashboardStatCard(
                                            label: 'متوسط التجهيز',
                                            value: _formatPrepWindow(settings),
                                            icon: Icons.timer_rounded,
                                            tint: const Color(0xFFF59E0B),
                                            width: 210,
                                          ),
                                          DashboardStatCard(
                                            label: 'تقييم المطعم',
                                            value:
                                                '${summary?.averageRating.toStringAsFixed(1) ?? '0.0'} ★',
                                            icon: Icons.star_rounded,
                                            tint: const Color(0xFF14B8A6),
                                            width: 210,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      DashboardPanel(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const _PanelHeader(
                                              title: 'حالة المطعم والتشغيل',
                                              subtitle:
                                                  'مؤشر الحالة يبين ما إذا كان المطعم مفتوحًا، وعدد الفروع، والشحن، وساعات العمل.',
                                            ),
                                            const SizedBox(height: 12),
                                            Wrap(
                                              spacing: 12,
                                              runSpacing: 12,
                                              children: [
                                                _StatusChip(
                                                  label: settings?.isOpen == true
                                                      ? 'المطعم مفتوح'
                                                      : 'المطعم مغلق',
                                                  tint: settings?.isOpen == true
                                                      ? const Color(0xFF10B981)
                                                      : const Color(0xFFEF4444),
                                                ),
                                                _StatusChip(
                                                  label:
                                                      '${settings?.branchCount ?? 0} فرع',
                                                  tint: const Color(0xFF3B82F6),
                                                ),
                                                _StatusChip(
                                                  label: _formatDeliveryFee(settings),
                                                  tint: const Color(0xFFF59E0B),
                                                ),
                                                _StatusChip(
                                                  label:
                                                      settings?.acceptsPreorders ==
                                                              true
                                                          ? 'الطلبات المسبقة مفعلة'
                                                          : 'الطلبات المسبقة متوقفة',
                                                  tint: const Color(0xFF8B5CF6),
                                                ),
                                                _StatusChip(
                                                  label:
                                                      '${settings?.preorderDaysLimit ?? 7} أيام للحجز المسبق',
                                                  tint: const Color(0xFF0F766E),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'أوقات العمل: ${_workingHoursSummary(settings)}',
                                              style: const TextStyle(
                                                color: kTextSecondary,
                                              ),
                                            ),
                                            if ((settings?.temporaryClosedReason ?? '')
                                                .trim()
                                                .isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                'سبب الإغلاق المؤقت: ${settings!.temporaryClosedReason}',
                                                style: const TextStyle(
                                                  color: kTextSecondary,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const _SectionHeader(
                                        title: 'الطلبات الحالية',
                                        subtitle:
                                            'استعرض أحدث الطلبات والطلبات المجدولة وابدأ القبول أو الرفض مباشرة.',
                                      ),
                                      const SizedBox(height: 12),
                                      if (snapshot != null)
                                        DashboardPanel(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      'الطلبات الجديدة والجارية',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w800,
                                                          ),
                                                    ),
                                                  ),
                                                  TextButton.icon(
                                                    onPressed: () =>
                                                        _openSection(
                                                      _sections.firstWhere(
                                                        (section) =>
                                                            section.title ==
                                                            'الطلبات',
                                                      ),
                                                    ),
                                                    icon: const Icon(
                                                      Icons.open_in_new_rounded,
                                                    ),
                                                    label: const Text('فتح الكل'),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              if (snapshot.recentOrders.isEmpty)
                                                const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 20,
                                                  ),
                                                  child: Text(
                                                    'لا توجد طلبات حالية.',
                                                    style: TextStyle(
                                                      color: kTextSecondary,
                                                    ),
                                                  ),
                                                )
                                              else
                                                ListView.separated(
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  itemCount: snapshot.recentOrders
                                                      .take(5)
                                                      .length,
                                                  separatorBuilder: (_, __) =>
                                                      const SizedBox(height: 12),
                                                  itemBuilder: (context, index) {
                                                    final order = snapshot
                                                        .recentOrders[index];
                                                    return _OrderPreviewCard(
                                                      order: order,
                                                      onAccept: order.vendorStatus ==
                                                              'pending'
                                                          ? () => _acceptOrder(
                                                                order,
                                                              )
                                                          : null,
                                                      onReject: order.vendorStatus ==
                                                              'pending'
                                                          ? () => _rejectOrder(
                                                                order,
                                                              )
                                                          : null,
                                                      onOpen: () => _openSection(
                                                        _sections.firstWhere(
                                                          (section) =>
                                                              section.title ==
                                                              'الطلبات',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                      if (snapshot != null &&
                                          snapshot.scheduledOrders.isNotEmpty)
                                        DashboardPanel(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const _PanelHeader(
                                                title: 'الطلبات المجدولة',
                                                subtitle:
                                                    'طلبات مستقبلية أو مسبقة مع وقت التنفيذ المحدد ومعلومات العميل.',
                                              ),
                                              const SizedBox(height: 12),
                                              for (final order in snapshot
                                                  .scheduledOrders
                                                  .take(4))
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    bottom: 12,
                                                  ),
                                                  child: _ScheduledOrderCard(
                                                    order: order,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                      const _SectionHeader(
                                        title: 'التنبيهات التشغيلية',
                                        subtitle:
                                            'البيانات التالية تعرض آخر التنبيهات المرتبطة بالطلبات والإدارة الداخلية.',
                                      ),
                                      const SizedBox(height: 12),
                                      if (operations != null)
                                        Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          children: [
                                            DashboardStatCard(
                                              label: 'مرتجعات مفتوحة',
                                              value:
                                                  '${operations.summary.openReturnsCount} طلب',
                                              icon: Icons.keyboard_return_rounded,
                                              tint: const Color(0xFF8B5CF6),
                                              width: 200,
                                            ),
                                            DashboardStatCard(
                                              label: 'عملاء متكررون',
                                              value:
                                                  '${operations.summary.repeatCustomersCount} عميل',
                                              icon: Icons.people_alt_rounded,
                                              tint: const Color(0xFF3B82F6),
                                              width: 200,
                                            ),
                                            DashboardStatCard(
                                              label: 'تقارير مجدولة',
                                              value:
                                                  '${operations.summary.scheduledReportsCount} تقرير',
                                              icon: Icons.schedule_send_rounded,
                                              tint: const Color(0xFF10B981),
                                              width: 200,
                                            ),
                                          ],
                                        ),
                                      if (operations != null) ...[
                                        const SizedBox(height: 12),
                                        DashboardPanel(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const _PanelHeader(
                                                title: 'التنبيهات النظامية',
                                                subtitle:
                                                    'أحدث التنبيهات المرسلة للمتجر من الطلبات والبيانات التشغيلية.',
                                              ),
                                              const SizedBox(height: 12),
                                              if ((notifications?.rows ?? [])
                                                  .isEmpty)
                                                const Text(
                                                  'لا توجد إشعارات بعد.',
                                                  style: TextStyle(
                                                    color: kTextSecondary,
                                                  ),
                                                )
                                              else
                                                Column(
                                                  children: notifications!.rows
                                                      .take(4)
                                                      .map(
                                                        (notification) =>
                                                            Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                            bottom: 10,
                                                          ),
                                                          child: _NotificationRow(
                                                            item: notification,
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      const _SectionHeader(
                                        title: 'الاختصارات السريعة',
                                        subtitle:
                                            'لوحة مختصرة للمنتجات والطلبات والتنبيهات اليومية.',
                                      ),
                                      const SizedBox(height: 12),
                                      _QuickModulesGrid(
                                        modules: _quickModules,
                                        onTap: _openModule,
                                      ),
                                    ],
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
    );
  }

  List<_QuickModule> get _quickModules => const [
        _QuickModule(
          title: 'الطلبات',
          icon: Icons.receipt_long_rounded,
          subtitle: 'إدارة جميع الطلبات',
          pageBuilder: OrderPage.new,
          tint: Color(0xFF3B82F6),
        ),
        _QuickModule(
          title: 'المنتجات',
          icon: Icons.restaurant_menu_rounded,
          subtitle: 'المنتجات والإضافات',
          pageBuilder: MenuManagementPage.new,
          tint: Color(0xFF14B8A6),
        ),
        _QuickModule(
          title: 'الأقسام',
          icon: Icons.category_rounded,
          subtitle: 'وجبات ومشروبات',
          pageBuilder: CategoriesPage.new,
          tint: Color(0xFFF59E0B),
        ),
        _QuickModule(
          title: 'العروض والتسويق',
          icon: Icons.local_offer_rounded,
          subtitle: 'الخصومات والعروض',
          pageBuilder: OffersMarketingPage.new,
          tint: Color(0xFFEC4899),
        ),
        _QuickModule(
          title: 'أوقات العمل',
          icon: Icons.access_time_rounded,
          subtitle: 'الساعات والإغلاق المؤقت',
          pageBuilder: WorkingHoursPage.new,
          tint: Color(0xFF0F766E),
        ),
        _QuickModule(
          title: 'التقييمات',
          icon: Icons.star_rounded,
          subtitle: 'آراء العملاء والمراجعات',
          pageBuilder: ReviewsRatingsPage.new,
          tint: Color(0xFFF59E0B),
        ),
        _QuickModule(
          title: 'التقارير',
          icon: Icons.query_stats_rounded,
          subtitle: 'تحليلات المبيعات',
          pageBuilder: ProductStatisticsPage.new,
          tint: Color(0xFF8B5CF6),
        ),
        _QuickModule(
          title: 'الإعدادات',
          icon: Icons.tune_rounded,
          subtitle: 'الهوية وأوقات العمل',
          pageBuilder: RestaurantSettingsPage.new,
          tint: Color(0xFF0F4C81),
        ),
        _QuickModule(
          title: 'الإشعارات',
          icon: Icons.notifications_active_rounded,
          subtitle: 'تنبيهات المطعم',
          pageBuilder: NotificationsPage.new,
          tint: Color(0xFF14B8A6),
        ),
        _QuickModule(
          title: 'الدعم',
          icon: Icons.support_agent_rounded,
          subtitle: 'غرف المحادثة',
          pageBuilder: SupportPage.new,
          tint: Color(0xFFEF4444),
        ),
        _QuickModule(
          title: 'الهدر',
          icon: Icons.delete_sweep_rounded,
          subtitle: 'سجل الهدر',
          pageBuilder: WasteLedgerPage.new,
          tint: Color(0xFF8B5CF6),
        ),
        _QuickModule(
          title: 'إضافة منتج',
          icon: Icons.add_box_rounded,
          subtitle: 'منتج جديد بسرعة',
          pageBuilder: AddProductPage.new,
          tint: Color(0xFF10B981),
        ),
      ];

  void _openModule(_QuickModule module) {
    final page = module.pageBuilder?.call();
    if (page == null) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

*/

class _RestaurantDashboardHomeBody extends StatelessWidget {
  const _RestaurantDashboardHomeBody({
    required this.snapshot,
    required this.settings,
    required this.salesReport,
  });

  final VendorDashboardSnapshot? snapshot;
  final RestaurantSettingsSnapshot? settings;
  final SalesReportResponse? salesReport;

  @override
  Widget build(BuildContext context) {
    final dashboard = snapshot;
    final store = settings;

    if (dashboard == null || store == null) {
      return const DashboardEmptyState(
        title: 'جاري تحميل لوحة المطعم',
        subtitle: 'نقوم بجلب الإحصاءات والطلبات والمنتجات من قاعدة البيانات.',
        icon: Icons.dashboard_rounded,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= 1320;
        final mid = width >= 980 && width < 1320;
        final salesPanel = _SalesTrendPanel(report: salesReport);
        final productsPanel = _TopProductsPanel(
          products: dashboard.topProductsToday,
        );
        final alertsPanel = _AlertsPanel(
          alerts: dashboard.alerts,
        );
        final metricsPanel = _DashboardMiniMetrics(
          summary: dashboard.summary,
        );

        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    salesPanel,
                    const SizedBox(height: 16),
                    metricsPanel,
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: productsPanel),
              const SizedBox(width: 16),
              Expanded(flex: 4, child: alertsPanel),
            ],
          );
        }

        if (mid) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              salesPanel,
              const SizedBox(height: 16),
              metricsPanel,
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: productsPanel),
                  const SizedBox(width: 16),
                  Expanded(child: alertsPanel),
                ],
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            salesPanel,
            const SizedBox(height: 16),
            metricsPanel,
            const SizedBox(height: 16),
            productsPanel,
            const SizedBox(height: 16),
            alertsPanel,
          ],
        );
      },
    );
  }
}

class _SalesTrendPanel extends StatelessWidget {
  const _SalesTrendPanel({required this.report});

  final SalesReportResponse? report;

  @override
  Widget build(BuildContext context) {
    final rows = [...(report?.rows ?? const <SalesReportRow>[])];
    rows.sort((a, b) => a.saleDate.compareTo(b.saleDate));

    if (rows.isEmpty) {
      return const DashboardEmptyState(
        title: 'لا توجد بيانات مبيعات',
        subtitle:
            'سيظهر هنا منحنى المبيعات اليومية بعد وصول بيانات من قاعدة البيانات.',
        icon: Icons.show_chart_rounded,
      );
    }

    final spots = <FlSpot>[];
    var maxY = 0.0;
    for (var i = 0; i < rows.length; i++) {
      final value = rows[i].totalSales;
      spots.add(FlSpot(i.toDouble(), value));
      if (value > maxY) maxY = value;
    }
    if (maxY <= 0) maxY = 100;
    maxY *= 1.15;

    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            title: 'المبيعات',
            subtitle:
                'منحنى يومي يعتمد على تقرير المبيعات المخزن في قاعدة البيانات.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _TinyPill(label: 'اليوم', active: true),
              _TinyPill(label: 'الأسبوع'),
              _TinyPill(label: 'الشهر'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (spots.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: kStroke,
                    strokeWidth: 1,
                    dashArray: const [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: kPrimary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 3.6,
                        color: kPrimary,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: kPrimary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) => Text(
                        _money(value),
                        style: const TextStyle(
                          color: kTextSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= rows.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _shortDate(rows[index].saleDate),
                            style: const TextStyle(
                              color: kTextSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => kPrimary,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        final label = index >= 0 && index < rows.length
                            ? rows[index].saleDate
                            : '';
                        return LineTooltipItem(
                          '$label\n${_money(spot.y)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
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

class _DashboardMiniMetrics extends StatelessWidget {
  const _DashboardMiniMetrics({required this.summary});

  final VendorDashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 520;
        final prepCard = _MiniMetricCard(
          title: 'متوسط وقت التحضير',
          value: summary.averagePrepMinutes.toStringAsFixed(0),
          valueLabel: 'دقيقة',
          subtitle: 'متوسط الوقت لجميع الطلبات',
          icon: Icons.schedule_rounded,
          tint: const Color(0xFFF59E0B),
        );
        final ratingCard = _MiniMetricCard(
          title: 'تقييم المطعم',
          value: summary.averageRating.toStringAsFixed(1),
          subtitle: '${summary.totalReviews} تقييم عام',
          icon: Icons.star_rounded,
          tint: const Color(0xFFF4B400),
          showStars: true,
          starValue: summary.averageRating,
        );

        if (wide) {
          final cardWidth = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: cardWidth, child: prepCard),
              SizedBox(width: cardWidth, child: ratingCard),
            ],
          );
        }

        return Column(
          children: [
            prepCard,
            const SizedBox(height: 12),
            ratingCard,
          ],
        );
      },
    );
  }
}

class _MiniMetricCard extends StatelessWidget {
  const _MiniMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.tint,
    this.valueLabel,
    this.showStars = false,
    this.starValue,
  });

  final String title;
  final String value;
  final String? valueLabel;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final bool showStars;
  final double? starValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kStroke),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: tint, size: 16),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (valueLabel != null && valueLabel!.trim().isNotEmpty)
            Column(
              children: [
                Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valueLabel!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ],
            )
          else
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          if (showStars) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ..._buildRatingIcons(starValue ?? 0),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopProductsPanel extends StatelessWidget {
  const _TopProductsPanel({
    required this.products,
  });

  final List<VendorDashboardProduct> products;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            title: 'أكثر المنتجات مبيعًا اليوم',
            subtitle: 'المنتجات الأعلى طلبًا مع صورها من قاعدة البيانات.',
          ),
          const SizedBox(height: 10),
          if (products.isEmpty)
            const DashboardEmptyState(
              title: 'لا توجد منتجات مباعة اليوم',
              subtitle:
                  'بمجرد تسجيل الطلبات سيظهر هنا الترتيب المباشر للمنتجات.',
              icon: Icons.restaurant_menu_rounded,
            )
          else
            Column(
              children: products.take(3).map((product) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBF9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kStroke),
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 84,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFFF2F6F2),
                          ),
                          child: product.imageUrl.trim().isNotEmpty
                              ? AppNetworkImage(
                                  imageUrl: product.imageUrl,
                                  fit: BoxFit.cover,
                                  borderRadius: BorderRadius.circular(16),
                                  placeholderIcon:
                                      Icons.restaurant_menu_rounded,
                                )
                              : const Icon(
                                  Icons.restaurant_menu_rounded,
                                  color: kTextSecondary,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.productName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'الكمية: ${product.quantitySold}',
                                style: const TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F5F0),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'عدد',
                                style: TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${product.ordersCount}',
                                style: const TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _AlertsPanel extends StatelessWidget {
  const _AlertsPanel({
    required this.alerts,
  });

  final List<VendorDashboardAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            title: 'التنبيهات',
            subtitle: 'تنبيهات تشغيلية وتذكيرات مهمة مبنية على بيانات المطعم.',
          ),
          const SizedBox(height: 10),
          if (alerts.isEmpty)
            const DashboardEmptyState(
              title: 'لا توجد تنبيهات الآن',
              subtitle: 'عندما تظهر طلبات متأخرة أو تحديثات تشغيلية ستظهر هنا.',
              icon: Icons.notifications_none_rounded,
            )
          else
            Column(
              children: alerts.take(3).map((alert) {
                final cleanLabel = _cleanAlertLabel(alert.label);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: alert.tint.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: alert.tint.withValues(alpha: 0.16)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _alertIcon(alert.label),
                            color: alert.tint,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cleanLabel,
                                style: const TextStyle(
                                  color: kTextPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                alert.subtitle,
                                style: const TextStyle(
                                  color: kTextSecondary,
                                  height: 1.4,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _OrdersPanel extends StatelessWidget {
  const _OrdersPanel({
    required this.title,
    required this.subtitle,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    required this.orders,
    required this.accent,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String subtitle;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final List<VendorDashboardOrder> orders;
  final Color accent;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _PanelHeader(title: title, subtitle: subtitle)),
              TextButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(actionLabel),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            DashboardEmptyState(
              title: emptyTitle,
              subtitle: emptySubtitle,
              icon: emptyIcon,
            )
          else
            Column(
              children: orders.take(4).map((order) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CompactOrderCard(
                    order: order,
                    accent: accent,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _OperationsPanel extends StatelessWidget {
  const _OperationsPanel({
    required this.operations,
    required this.store,
    required this.onOpenMenu,
  });

  final StoreOperationsOverview? operations;
  final RestaurantSettingsSnapshot store;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final summary = operations?.summary;
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(
            title: 'ملخص التشغيل',
            subtitle: 'إشارات سريعة تساعد على اتخاذ القرار داخل المطعم.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricChip(
                label: 'مرتجعات مفتوحة',
                value: '${summary?.openReturnsCount ?? 0}',
                tint: const Color(0xFF8B5CF6),
                icon: Icons.keyboard_return_rounded,
              ),
              _MetricChip(
                label: 'عملاء متكررون',
                value: '${summary?.repeatCustomersCount ?? 0}',
                tint: const Color(0xFF3B82F6),
                icon: Icons.groups_rounded,
              ),
              _MetricChip(
                label: 'تقارير مجدولة',
                value: '${summary?.scheduledReportsCount ?? 0}',
                tint: const Color(0xFF10B981),
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: store.isOpen
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: store.isOpen
                    ? const Color(0xFFBBF7D0)
                    : const Color(0xFFFECACA),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  store.isOpen ? 'المطعم يعمل طبيعيًا' : 'المطعم مغلق حاليًا',
                  style: TextStyle(
                    color: store.isOpen ? kPrimary : const Color(0xFFB91C1C),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'أوقات العمل: ${_workingHoursSummary(store)}',
                  style: const TextStyle(
                    color: kTextSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onOpenMenu,
                  icon: const Icon(Icons.add_box_rounded),
                  label: const Text('إضافة منتج سريع'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _CompactOrderCard extends StatelessWidget {
  const _CompactOrderCard({
    required this.order,
    required this.accent,
  });

  final VendorDashboardOrder order;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              order.isScheduled
                  ? Icons.schedule_rounded
                  : Icons.receipt_long_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#${order.orderId}  ·  ${order.customerName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _TinyPill(label: order.orderTypeLabel, active: true),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  order.itemsSummary.isEmpty
                      ? 'تفاصيل الطلب غير متاحة'
                      : order.itemsSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kTextSecondary,
                    height: 1.4,
                  ),
                ),
                if (order.giftMessage.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'رسالة الإهداء: ${order.giftMessage}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kPrimary,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (order.deliveryNote.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'ملاحظات التوصيل: ${order.deliveryNote}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kTextSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _prettyDate(order.ordersDatetime),
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _money(order.totalPrice),
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.tint,
    required this.icon,
  });

  final String label;
  final String value;
  final Color tint;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: tint, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: tint,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (value.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: kTextSecondary,
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _TinyPill extends StatelessWidget {
  const _TinyPill({
    required this.label,
    this.active = false,
  });

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            active ? kPrimary.withValues(alpha: 0.12) : const Color(0xFFF3F6F3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? kPrimary.withValues(alpha: 0.18) : kStroke,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? kPrimary : kTextSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DashboardNotificationButton extends StatelessWidget {
  const _DashboardNotificationButton({
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = unreadCount > 99 ? '99+' : '$unreadCount';

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kStroke),
              ),
              child: IconButton(
                onPressed: onPressed,
                icon: const Icon(Icons.notifications_none_rounded, size: 20),
              ),
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

List<Icon> _buildRatingIcons(double rating) {
  final safeRating = rating.clamp(0, 5).toDouble();
  final fullStars = safeRating.floor();
  final fraction = safeRating - fullStars;
  final hasHalfStar = fraction >= 0.25 && fraction < 0.75;

  return List<Icon>.generate(5, (index) {
    IconData icon;
    if (index < fullStars) {
      icon = Icons.star_rounded;
    } else if (index == fullStars && hasHalfStar) {
      icon = Icons.star_half_rounded;
    } else {
      icon = Icons.star_border_rounded;
    }

    return Icon(
      icon,
      color: const Color(0xFFF4B400),
      size: 16,
    );
  });
}

// ignore: unused_element
class _SummaryFooter extends StatelessWidget {
  const _SummaryFooter({
    required this.onRefresh,
    required this.onOpenMenu,
  });

  final VoidCallback onRefresh;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Row(
        children: [
          Expanded(
            child: Text(
              'كل العناصر المعروضة هنا متصلة بقاعدة البيانات ويتم تحديثها عند طلب التحديث.',
              style: const TextStyle(
                color: kTextSecondary,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('تحديث'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onOpenMenu,
            icon: const Icon(Icons.add_box_rounded),
            label: const Text('إضافة منتج'),
          ),
        ],
      ),
    );
  }
}

String _money(double value) {
  final rounded = value.roundToDouble();
  if (value == rounded) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

String _shortDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}';
}

String _prettyDate(DateTime? dateTime) {
  if (dateTime == null) return '-';
  final now = DateTime.now();
  final dayDelta = DateTime(dateTime.year, dateTime.month, dateTime.day)
      .difference(DateTime(now.year, now.month, now.day))
      .inDays;
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  if (dayDelta == 0) return 'اليوم $hour:$minute';
  if (dayDelta == 1) return 'غداً $hour:$minute';
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} $hour:$minute';
}

String _workingHoursSummary(RestaurantSettingsSnapshot? settings) {
  if (settings == null || settings.workingHours.isEmpty) {
    return '10:00 - 23:00';
  }

  final openDays = settings.workingHours.where((day) => day.isOpen).toList();
  if (openDays.isEmpty) {
    return 'المطعم مغلق طوال الأسبوع';
  }

  final first = openDays.first;
  final last = openDays.last;
  return '${first.openTime} - ${last.closeTime}';
}

String _cleanAlertLabel(String label) {
  return label
      .replaceFirst('🟡', '')
      .replaceFirst('🟢', '')
      .replaceFirst('🔴', '')
      .replaceFirst('🟠', '')
      .trim();
}

IconData _alertIcon(String label) {
  if (label.contains('متأخر')) return Icons.warning_amber_rounded;
  if (label.contains('مخزون')) return Icons.inventory_2_rounded;
  if (label.contains('تقييم')) return Icons.check_circle_rounded;
  if (label.contains('مجدول')) return Icons.access_time_rounded;
  return Icons.notifications_rounded;
}

class _DashboardSection {
  const _DashboardSection({
    required this.title,
    required this.icon,
    required this.description,
    this.route,
    this.pageBuilder,
  });

  final String title;
  final IconData icon;
  final String description;
  final String? route;
  final Widget Function()? pageBuilder;
}
