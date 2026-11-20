part of '../../../../../master_auth_app.dart';

class ReportsOverviewPage extends StatefulWidget {
  const ReportsOverviewPage({
    super.key,
    required this.session,
    required this.api,
  });

  final MasterSession session;
  final MasterAuthApiService api;

  @override
  State<ReportsOverviewPage> createState() => _ReportsOverviewPageState();
}

class _ReportsOverviewPageState extends State<ReportsOverviewPage> {
  late final Future<_ReportsOverviewResult> _overviewFuture;

  @override
  void initState() {
    super.initState();
    _overviewFuture = _loadOverviewData();
  }

  Future<_ReportsOverviewResult> _loadOverviewData() async {
    final overview = await widget.api._fetchReportsOverviewRaw(
      widget.session.token,
    );
    final topRestaurants = await widget.api._fetchReportsTopRestaurantsRaw(
      widget.session.token,
    );
    return _ReportsOverviewResult.fromJson(overview, topRestaurants);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ReportsOverviewResult>(
      future: _overviewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ReportsLoadingCard();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _ReportsErrorCard(message: snapshot.error?.toString() ?? '');
        }

        final result = snapshot.data!;
        return _ReportsSurface(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ReportsHeader(
                  icon: Icons.query_stats_outlined,
                  title: 'نظرة عامة على التقارير',
                  subtitle:
                      'مؤشرات تشغيلية حقيقية مجمعة من الطلبات والمستخدمين والمطاعم',
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final cardWidth = width >= 1150
                        ? (width - 48) / 4
                        : width >= 760
                        ? (width - 24) / 2
                        : width;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _ReportsMetricCard(
                          width: cardWidth,
                          icon: Icons.receipt_long_outlined,
                          title: 'إجمالي الطلبات',
                          value: _formatInt(result.totalOrders),
                          tint: const Color(0xFFEAF5ED),
                          color: _kPrimaryGreen,
                        ),
                        _ReportsMetricCard(
                          width: cardWidth,
                          icon: Icons.payments_outlined,
                          title: 'الإيرادات المكتملة',
                          value: _formatMoney(result.revenue),
                          tint: const Color(0xFFFFF8E4),
                          color: const Color(0xFFB7791F),
                        ),
                        _ReportsMetricCard(
                          width: cardWidth,
                          icon: Icons.timer_outlined,
                          title: 'متوسط زمن التوصيل',
                          value: _formatMinutes(result.avgDeliveryMinutes),
                          tint: const Color(0xFFEAF1FF),
                          color: const Color(0xFF2563EB),
                        ),
                        _ReportsMetricCard(
                          width: cardWidth,
                          icon: Icons.person_add_alt_1_outlined,
                          title: 'مستخدمون جدد',
                          value: _formatInt(result.newUsers),
                          tint: const Color(0xFFF1ECFF),
                          color: const Color(0xFF7C3AED),
                        ),
                        _ReportsMetricCard(
                          width: cardWidth,
                          icon: Icons.task_alt_outlined,
                          title: 'معدل الإكمال',
                          value: _formatPercent(result.acceptanceRate),
                          tint: const Color(0xFFEAF8F2),
                          color: const Color(0xFF14936B),
                        ),
                        _ReportsMetricCard(
                          width: cardWidth,
                          icon: Icons.cancel_outlined,
                          title: 'معدل الإلغاء',
                          value: _formatPercent(result.cancellationsRate),
                          tint: const Color(0xFFFDEEEF),
                          color: const Color(0xFFD92C2C),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                _ReportsSectionCard(
                  title: 'نمو الطلبات خلال 30 يوم',
                  icon: Icons.bar_chart_rounded,
                  child: SizedBox(
                    height: 300,
                    child: _ReportsBarChart(series: result.series),
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 900;
                    final children = [
                      Flexible(
                        fit: FlexFit.loose,
                        child: _ReportsSectionCard(
                          title: 'أعلى المطاعم حسب المبيعات',
                          icon: Icons.storefront_outlined,
                          child: _ReportsTopRestaurantsList(
                            restaurants: result.topRestaurants,
                          ),
                        ),
                      ),
                      Flexible(
                        fit: FlexFit.loose,
                        child: _ReportsSectionCard(
                          title: 'توزيع تقييمات العملاء',
                          icon: Icons.star_outline_rounded,
                          child: _ReportsKeyValueList(
                            metrics: result.ratingsMetrics,
                            emptyLabel: 'لا توجد تقييمات مسجلة بعد',
                          ),
                        ),
                      ),
                    ];
                    if (stacked) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          children.first,
                          const SizedBox(height: 14),
                          children.last,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        children.first,
                        const SizedBox(width: 14),
                        children.last,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ReportsUsersPage extends StatefulWidget {
  const ReportsUsersPage({super.key, required this.session, required this.api});

  final MasterSession session;
  final MasterAuthApiService api;

  @override
  State<ReportsUsersPage> createState() => _ReportsUsersPageState();
}

class _ReportsUsersPageState extends State<ReportsUsersPage> {
  late final Future<Map<String, dynamic>> _usersMetricsFuture;

  @override
  void initState() {
    super.initState();
    _usersMetricsFuture = widget.api._fetchReportsUsersMetricsRaw(
      widget.session.token,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ReportsMetricsPage(
      future: _usersMetricsFuture,
      icon: Icons.people_alt_outlined,
      title: 'تقارير المستخدمين',
      subtitle: 'نشاط العملاء، النمو، التكرار، والتقييمات',
      emptyLabel: 'لا توجد بيانات مستخدمين متاحة',
    );
  }
}

class ReportsDriversPage extends StatefulWidget {
  const ReportsDriversPage({
    super.key,
    required this.session,
    required this.api,
  });

  final MasterSession session;
  final MasterAuthApiService api;

  @override
  State<ReportsDriversPage> createState() => _ReportsDriversPageState();
}

class _ReportsDriversPageState extends State<ReportsDriversPage> {
  late final Future<Map<String, dynamic>> _driversMetricsFuture;

  @override
  void initState() {
    super.initState();
    _driversMetricsFuture = widget.api._fetchReportsDriversMetricsRaw(
      widget.session.token,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _ReportsMetricsPage(
      future: _driversMetricsFuture,
      icon: Icons.local_shipping_rounded,
      title: 'تقارير السائقين',
      subtitle: 'الاتصال، الطلبات النشطة، الطوارئ، ومتوسطات الأداء',
      emptyLabel: 'لا توجد بيانات سائقين متاحة',
    );
  }
}

class ReportsRestaurantsPage extends StatefulWidget {
  const ReportsRestaurantsPage({
    super.key,
    required this.session,
    required this.api,
  });

  final MasterSession session;
  final MasterAuthApiService api;

  @override
  State<ReportsRestaurantsPage> createState() => _ReportsRestaurantsPageState();
}

class _ReportsRestaurantsPageState extends State<ReportsRestaurantsPage> {
  late final Future<List<_ReportsTopRestaurant>> _topRestaurantsFuture;

  @override
  void initState() {
    super.initState();
    _topRestaurantsFuture = widget.api
        ._fetchReportsTopRestaurantsRaw(widget.session.token)
        .then((rows) => rows.map(_ReportsTopRestaurant.fromJson).toList());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_ReportsTopRestaurant>>(
      future: _topRestaurantsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ReportsLoadingCard();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _ReportsErrorCard(message: snapshot.error?.toString() ?? '');
        }
        final restaurants = snapshot.data!;
        return _ReportsSurface(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ReportsHeader(
                  icon: Icons.storefront_outlined,
                  title: 'تقارير المطاعم',
                  subtitle: 'ترتيب المطاعم حسب المبيعات المكتملة والطلبات',
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _ReportsRestaurantsTable(restaurants: restaurants),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ReportsReferencePage extends StatefulWidget {
  const ReportsReferencePage({
    super.key,
    required this.session,
    required this.api,
  });

  final MasterSession session;
  final MasterAuthApiService api;

  @override
  State<ReportsReferencePage> createState() => _ReportsReferencePageState();
}

class _ReportsReferencePageState extends State<ReportsReferencePage> {
  late Future<_ReportsReferenceData> _referenceFuture;

  @override
  void initState() {
    super.initState();
    _referenceFuture = _loadReferenceData();
  }

  Future<_ReportsReferenceData> _loadReferenceData() async {
    final token = widget.session.token;
    final results = await Future.wait<dynamic>([
      widget.api._fetchMasterUsersOverview(token),
      widget.api._fetchDeliveryLogistics(token, view: 'drivers'),
      widget.api._fetchMasterRestaurantsOverviewRaw(token),
      widget.api._fetchMasterFinanceOverviewRaw(token),
      widget.api._fetchReportsOverviewRaw(token),
    ]);

    return _ReportsReferenceData(
      users: results[0] as _MasterUsersData,
      delivery: results[1] as _MasterDeliveryLogisticsData,
      restaurants: _buildReportsRestaurantSeed(
        Map<String, dynamic>.from(results[2] as Map),
      ),
      finance: Map<String, dynamic>.from(results[3] as Map),
      overview: _ReportsOverviewResult.fromJson(
        Map<String, dynamic>.from(results[4] as Map),
        const <Map<String, dynamic>>[],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ReportsReferenceData>(
      future: _referenceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ReportsLoadingCard();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _ReportsErrorCard(message: snapshot.error?.toString() ?? '');
        }

        final data = snapshot.data!;
        final users = data.users.users;
        final activeUsers = users
            .where(
              (user) =>
                  user.status.contains('???') || user.status.contains('نشط'),
            )
            .length;
        final wallets = _asMapList(data.finance['wallets']);
        final commissions = _asMapList(data.finance['commissions']);
        final fees = _asMapList(data.finance['fees']);
        final records = _asMapList(data.finance['records']);
        final financeCoupons = _asMapList(data.finance['coupons']);
        final totalWalletBalance = users.fold<double>(
          0,
          (sum, user) => sum + _numericUserValue(user.walletBalanceLabel),
        );
        final totalUserSpend = users.fold<double>(
          0,
          (sum, user) => sum + _numericUserValue(user.totalSpendLabel),
        );
        final totalUserOrders = users.fold<int>(
          0,
          (sum, user) => sum + user.ordersCount,
        );
        final onlineDrivers = data.delivery.drivers.where((driver) {
          final value = '${driver.statusKey} ${driver.statusLabel}'
              .toLowerCase();
          return value.contains('online') ||
              value.contains('available') ||
              value.contains('متاح') ||
              value.contains('متصل');
        }).length;
        final activeRestaurants = data.restaurants.restaurants
            .where(
              (restaurant) =>
                  restaurant.status.contains('نشط') ||
                  restaurant.status.contains('نشط'),
            )
            .length;

        return _ReportsSurface(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ReportsHeader(
                  icon: Icons.inventory_2_outlined,
                  title: 'المرجع الشامل للمنصة',
                  subtitle:
                      'قاعدة تشغيلية موحدة تجمع المستخدمين، الدليفري، المطاعم، المنتجات، المحافظ، والماليات',
                ),
                const SizedBox(height: 14),
                _ReportsMetricsWrap(
                  metrics: [
                    _ReportsMetricSpec(
                      icon: Icons.groups_2_outlined,
                      title: 'إجمالي المستخدمين',
                      value: _formatInt(users.length),
                      tint: const Color(0xFFEAF1FF),
                      color: const Color(0xFF2563EB),
                    ),
                    _ReportsMetricSpec(
                      icon: Icons.verified_user_outlined,
                      title: 'المستخدمون النشطون',
                      value: _formatInt(activeUsers),
                      tint: const Color(0xFFEAF8F2),
                      color: const Color(0xFF14936B),
                    ),
                    _ReportsMetricSpec(
                      icon: Icons.receipt_long_outlined,
                      title: 'طلبات المستخدمين',
                      value: _formatInt(totalUserOrders),
                      tint: const Color(0xFFF1ECFF),
                      color: const Color(0xFF7C3AED),
                    ),
                    _ReportsMetricSpec(
                      icon: Icons.payments_outlined,
                      title: 'إنفاق المستخدمين',
                      value: _formatMoney(totalUserSpend),
                      tint: const Color(0xFFFFF8E4),
                      color: const Color(0xFFB7791F),
                    ),
                    _ReportsMetricSpec(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'رصيد المحافظ',
                      value: _formatMoney(totalWalletBalance),
                      tint: const Color(0xFFFFF3DF),
                      color: const Color(0xFFF59E0B),
                    ),
                    _ReportsMetricSpec(
                      icon: Icons.location_on_outlined,
                      title: 'العناوين المحفوظة',
                      value: _formatInt(data.users.addresses.length),
                      tint: const Color(0xFFEAF5ED),
                      color: _kPrimaryGreen,
                    ),
                    _ReportsMetricSpec(
                      icon: Icons.local_shipping_outlined,
                      title: 'السائقون',
                      value: _formatInt(data.delivery.drivers.length),
                      tint: const Color(0xFFEAF1FF),
                      color: const Color(0xFF2563EB),
                    ),
                    _ReportsMetricSpec(
                      icon: Icons.route_outlined,
                      title: 'طلبات دليفري نشطة',
                      value: _formatInt(data.delivery.activeOrders.length),
                      tint: const Color(0xFFEAF8F2),
                      color: const Color(0xFF14936B),
                    ),
                    _ReportsMetricSpec(
                      icon: Icons.pending_actions_outlined,
                      title: 'طلبات غير موزعة',
                      value: _formatInt(data.delivery.unassignedOrders.length),
                      tint: const Color(0xFFFDEEEF),
                      color: const Color(0xFFD92C2C),
                    ),
                    _ReportsMetricSpec(
                      icon: Icons.storefront_outlined,
                      title: 'المطاعم',
                      value: _formatInt(data.restaurants.restaurants.length),
                      tint: const Color(0xFFEAF5ED),
                      color: _kPrimaryGreen,
                    ),
                    _ReportsMetricSpec(
                      icon: Icons.restaurant_menu_outlined,
                      title: 'المنتجات',
                      value: _formatInt(data.restaurants.products.length),
                      tint: const Color(0xFFF1ECFF),
                      color: const Color(0xFF7C3AED),
                    ),
                    _ReportsMetricSpec(
                      icon: Icons.sell_outlined,
                      title: 'العروض والكوبونات',
                      value: _formatInt(
                        data.restaurants.offers.length +
                            data.restaurants.coupons.length +
                            financeCoupons.length,
                      ),
                      tint: const Color(0xFFFFF8E4),
                      color: const Color(0xFFB7791F),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ReportsSectionCard(
                  title: 'ملخص المنصة التنفيذي',
                  icon: Icons.dashboard_customize_outlined,
                  child: _ReportsKeyValueList(
                    metrics: {
                      'إجمالي الطلبات': _formatInt(data.overview.totalOrders),
                      'الإيرادات المكتملة': _formatMoney(data.overview.revenue),
                      'معدل الإكمال': _formatPercent(
                        data.overview.acceptanceRate,
                      ),
                      'معدل الإلغاء': _formatPercent(
                        data.overview.cancellationsRate,
                      ),
                      'متوسط وقت التوصيل': _formatMinutes(
                        data.overview.avgDeliveryMinutes,
                      ),
                      'سائقون متصلون/متاحون': _formatInt(onlineDrivers),
                      'مطاعم نشطة': _formatInt(activeRestaurants),
                      'سجلات مالية معروضة': _formatInt(records.length),
                    },
                    emptyLabel: 'لا توجد مؤشرات متاحة',
                  ),
                ),
                const SizedBox(height: 14),
                _ReportsSectionCard(
                  title: 'المستخدمون والعملاء',
                  icon: Icons.people_alt_outlined,
                  child: _ReportsSimpleTable(
                    headers: const [
                      'ID',
                      'الاسم',
                      'الهاتف',
                      'المدينة',
                      'الطلبات',
                      'الإنفاق',
                      'المحفظة',
                      'التقييم',
                      'الحالة',
                    ],
                    rows: [
                      for (final user in [
                        ...users,
                      ]..sort((a, b) => b.ordersCount.compareTo(a.ordersCount)))
                        [
                          user.id,
                          user.name,
                          user.phone,
                          user.city,
                          _formatInt(user.ordersCount),
                          user.totalSpendLabel,
                          user.walletBalanceLabel,
                          user.ratingAverage.toStringAsFixed(1),
                          user.status,
                        ],
                    ],
                    emptyLabel: 'لا توجد بيانات مستخدمين',
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 980;
                    final addresses = _ReportsSectionCard(
                      title: 'العناوين المحفوظة',
                      icon: Icons.location_on_outlined,
                      child: _ReportsSimpleTable(
                        headers: const [
                          'المستخدم',
                          'الهاتف',
                          'العنوان',
                          'المدينة',
                          'الحي',
                          'طلبات مرتبطة',
                          'الحالة',
                        ],
                        rows: [
                          for (final item in data.users.addresses)
                            [
                              item.userName,
                              item.userPhone,
                              item.title,
                              item.city,
                              item.district,
                              _formatInt(item.linkedOrders),
                              item.status,
                            ],
                        ],
                        emptyLabel: 'لا توجد عناوين محفوظة',
                      ),
                    );
                    final recipients = _ReportsSectionCard(
                      title: 'المستلمون المحفوظون',
                      icon: Icons.contact_phone_outlined,
                      child: _ReportsSimpleTable(
                        headers: const [
                          'المستخدم',
                          'المستلم',
                          'الهاتف',
                          'العنوان',
                          'المدينة',
                          'الطلبات',
                          'الحالة',
                        ],
                        rows: [
                          for (final item in data.users.recipients)
                            [
                              item.userName,
                              item.recipientName,
                              item.phone,
                              item.addressTitle,
                              item.city,
                              _formatInt(item.totalOrders),
                              item.status,
                            ],
                        ],
                        emptyLabel: 'لا توجد بيانات مستلمين',
                      ),
                    );
                    if (stacked) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          addresses,
                          const SizedBox(height: 14),
                          recipients,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: addresses),
                        const SizedBox(width: 14),
                        Expanded(child: recipients),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                _ReportsSectionCard(
                  title: 'السائقون والدليفري',
                  icon: Icons.local_shipping_rounded,
                  child: _ReportsSimpleTable(
                    headers: const [
                      'ID',
                      'السائق',
                      'الهاتف',
                      'المركبة',
                      'الحالة',
                      'طلبات اليوم',
                      'نشطة',
                      'التقييم',
                      'الموقع',
                    ],
                    rows: [
                      for (final driver in data.delivery.drivers)
                        [
                          driver.driverId.toString(),
                          driver.name,
                          driver.phone,
                          '${driver.vehicleType} ${driver.vehicleNumber}'
                              .trim(),
                          driver.statusLabel,
                          _formatInt(driver.todayOrders),
                          _formatInt(driver.activeOrders),
                          driver.rating.toStringAsFixed(1),
                          driver.currentLocation,
                        ],
                    ],
                    emptyLabel: 'لا توجد بيانات سائقين',
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 980;
                    final unassigned = _ReportsSectionCard(
                      title: 'طلبات دليفري غير موزعة',
                      icon: Icons.pending_actions_outlined,
                      child: _ReportsSimpleTable(
                        headers: const [
                          'الطلب',
                          'العميل',
                          'الهاتف',
                          'المطعم',
                          'القيمة',
                          'الحالة',
                          'العنوان',
                        ],
                        rows: [
                          for (final order in data.delivery.unassignedOrders)
                            [
                              order.orderNo,
                              order.customer,
                              order.phone,
                              order.restaurant,
                              order.amountLabel,
                              order.statusLabel,
                              order.addressLabel,
                            ],
                        ],
                        emptyLabel: 'لا توجد طلبات غير موزعة',
                      ),
                    );
                    final active = _ReportsSectionCard(
                      title: 'طلبات دليفري نشطة',
                      icon: Icons.route_outlined,
                      child: _ReportsSimpleTable(
                        headers: const [
                          'الطلب',
                          'العميل',
                          'السائق',
                          'المطعم',
                          'القيمة',
                          'الحالة',
                          'الوقت',
                        ],
                        rows: [
                          for (final order in data.delivery.activeOrders)
                            [
                              order.orderNo,
                              order.customer,
                              order.driverName,
                              order.restaurant,
                              order.amountLabel,
                              order.statusLabel,
                              order.timeLabel,
                            ],
                        ],
                        emptyLabel: 'لا توجد طلبات نشطة',
                      ),
                    );
                    if (stacked) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          unassigned,
                          const SizedBox(height: 14),
                          active,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: unassigned),
                        const SizedBox(width: 14),
                        Expanded(child: active),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                _ReportsSectionCard(
                  title: 'المطاعم',
                  icon: Icons.storefront_outlined,
                  child: _ReportsSimpleTable(
                    headers: const [
                      'ID',
                      'المطعم',
                      'المالك',
                      'الهاتف',
                      'المدينة',
                      'المنطقة',
                      'طلبات اليوم',
                      'التقييم',
                      'الحالة',
                    ],
                    rows: [
                      for (final restaurant in data.restaurants.restaurants)
                        [
                          restaurant.id,
                          restaurant.name,
                          restaurant.owner,
                          restaurant.phone,
                          restaurant.city,
                          restaurant.zone,
                          _formatInt(restaurant.todayOrders),
                          restaurant.rating.toStringAsFixed(1),
                          restaurant.status,
                        ],
                    ],
                    emptyLabel: 'لا توجد بيانات مطاعم',
                  ),
                ),
                const SizedBox(height: 14),
                _ReportsSectionCard(
                  title: 'المنتجات والتصنيفات',
                  icon: Icons.restaurant_menu_outlined,
                  child: _ReportsSimpleTable(
                    headers: const [
                      'ID',
                      'المنتج',
                      'المطعم',
                      'التصنيف',
                      'السعر',
                      'بعد الخصم',
                      'الطلبات',
                      'التقييم',
                      'الحالة',
                    ],
                    rows: [
                      for (final product in [
                        ...data.restaurants.products,
                      ]..sort((a, b) => b.orders.compareTo(a.orders)))
                        [
                          product.id,
                          product.name,
                          product.restaurant,
                          product.section,
                          product.price,
                          product.discountedPrice,
                          _formatInt(product.orders),
                          product.rating.toStringAsFixed(1),
                          product.status,
                        ],
                    ],
                    emptyLabel: 'لا توجد منتجات',
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 980;
                    final offers = _ReportsSectionCard(
                      title: 'عروض المطاعم',
                      icon: Icons.local_offer_outlined,
                      child: _ReportsSimpleTable(
                        headers: const [
                          'ID',
                          'العرض',
                          'المطعم',
                          'الخصم',
                          'الحد الأدنى',
                          'طلبات',
                          'النهاية',
                          'الحالة',
                        ],
                        rows: [
                          for (final offer in data.restaurants.offers)
                            [
                              offer.id,
                              offer.name,
                              offer.restaurant,
                              offer.discountValue,
                              offer.minOrder,
                              _formatInt(offer.performanceOrders),
                              offer.endDate,
                              offer.status,
                            ],
                        ],
                        emptyLabel: 'لا توجد عروض',
                      ),
                    );
                    final coupons = _ReportsSectionCard(
                      title: 'كوبونات المطاعم والمنصة',
                      icon: Icons.confirmation_number_outlined,
                      child: _ReportsSimpleTable(
                        headers: const [
                          'ID',
                          'الكود',
                          'المطعم',
                          'النوع',
                          'القيمة',
                          'الاستخدام',
                          'النهاية',
                          'الحالة',
                        ],
                        rows: [
                          for (final coupon in data.restaurants.coupons)
                            [
                              coupon.id,
                              coupon.code,
                              coupon.restaurant,
                              coupon.type,
                              coupon.value,
                              coupon.uses,
                              coupon.endDate,
                              coupon.status,
                            ],
                          for (final coupon in financeCoupons)
                            [
                              _firstText([
                                coupon['coupon_id'],
                                coupon['id'],
                                '-',
                              ]),
                              _firstText([coupon['code'], '-']),
                              _firstText([coupon['restaurant'], 'المنصة']),
                              _firstText([coupon['type_label'], '-']),
                              _firstText([coupon['value_label'], '-']),
                              _firstText([coupon['usage_label'], '-']),
                              _firstText([coupon['end_date'], '-']),
                              _firstText([coupon['status'], '-']),
                            ],
                        ],
                        emptyLabel: 'لا توجد كوبونات',
                      ),
                    );
                    if (stacked) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [offers, const SizedBox(height: 14), coupons],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: offers),
                        const SizedBox(width: 14),
                        Expanded(child: coupons),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                _ReportsSectionCard(
                  title: 'المحافظ والماليات',
                  icon: Icons.account_balance_wallet_outlined,
                  child: _ReportsSimpleTable(
                    headers: const [
                      'المحفظة',
                      'المستخدم',
                      'الهاتف',
                      'الرصيد',
                      'النقاط',
                      'الطلبات',
                      'الإنفاق',
                      'آخر نشاط',
                      'الحالة',
                    ],
                    rows: [
                      for (final wallet in wallets)
                        [
                          _firstText([wallet['wallet_id'], '-']),
                          _firstText([wallet['user_name'], '-']),
                          _firstText([wallet['phone'], '-']),
                          _formatMoney(_toDouble(wallet['wallet_balance'])),
                          _formatInt(
                            _toInt(
                              wallet['wallet_points'] ??
                                  wallet['refund_points'],
                            ),
                          ),
                          _formatInt(_toInt(wallet['orders_count'])),
                          _formatMoney(_toDouble(wallet['total_spend'])),
                          _firstText([
                            wallet['last_activity'],
                            wallet['created_at'],
                            '-',
                          ]),
                          _firstText([wallet['status'], '-']),
                        ],
                    ],
                    emptyLabel: 'لا توجد محافظ',
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 980;
                    final commissionCard = _ReportsSectionCard(
                      title: 'عمولات وتسويات المطاعم',
                      icon: Icons.price_check_outlined,
                      child: _ReportsSimpleTable(
                        headers: const [
                          'المطعم',
                          'الأوامر',
                          'الإجمالي',
                          'المعلق',
                          'المدفوع',
                          'النسبة',
                          'الحالة',
                        ],
                        rows: [
                          for (final row in commissions)
                            [
                              _firstText([
                                row['applies_to'],
                                row['rule_name'],
                                '-',
                              ]),
                              _formatInt(_toInt(row['orders_count'])),
                              _formatMoney(_toDouble(row['gross_amount'])),
                              _formatMoney(_toDouble(row['pending_amount'])),
                              _formatMoney(_toDouble(row['paid_amount'])),
                              _firstText([row['value_label'], '-']),
                              _firstText([row['status'], '-']),
                            ],
                        ],
                        emptyLabel: 'لا توجد بيانات عمولات',
                      ),
                    );
                    final feesCard = _ReportsSectionCard(
                      title: 'مناطق ورسوم التوصيل',
                      icon: Icons.map_outlined,
                      child: _ReportsSimpleTable(
                        headers: const [
                          'المطعم/المنطقة',
                          'المدينة',
                          'رسوم ثابتة',
                          'لكل كم',
                          'خدمة',
                          'حد أدنى',
                          'الحالة',
                        ],
                        rows: [
                          for (final row in fees)
                            [
                              _firstText([row['zone_name'], '-']),
                              _firstText([row['city'], '-']),
                              _formatMoney(_toDouble(row['fixed_fee'])),
                              _formatMoney(_toDouble(row['extra_km_fee'])),
                              _formatMoney(_toDouble(row['service_fee'])),
                              _formatMoney(_toDouble(row['minimum_order'])),
                              _firstText([row['status'], '-']),
                            ],
                        ],
                        emptyLabel: 'لا توجد بيانات رسوم',
                      ),
                    );
                    if (stacked) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          commissionCard,
                          const SizedBox(height: 14),
                          feesCard,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: commissionCard),
                        const SizedBox(width: 14),
                        Expanded(child: feesCard),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                _ReportsSectionCard(
                  title: 'آخر السجلات المالية',
                  icon: Icons.receipt_long_outlined,
                  child: _ReportsSimpleTable(
                    headers: const [
                      'المرجع',
                      'التاريخ',
                      'الوصف',
                      'الحساب',
                      'النوع',
                      'القيمة',
                      'الرصيد بعد',
                      'الحالة',
                    ],
                    rows: [
                      for (final row in records)
                        [
                          _firstText([row['reference'], '-']),
                          _firstText([row['datetime'], '-']),
                          _firstText([row['description'], '-']),
                          _firstText([row['account'], '-']),
                          _firstText([row['type_label'], '-']),
                          _formatMoney(_toDouble(row['amount'])),
                          _formatMoney(_toDouble(row['balance_after'])),
                          _firstText([row['status'], '-']),
                        ],
                    ],
                    emptyLabel: 'لا توجد سجلات مالية',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MasterReportsPage extends StatefulWidget {
  const MasterReportsPage({
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
  State<MasterReportsPage> createState() => _MasterReportsPageState();
}

class _MasterReportsPageState extends State<MasterReportsPage> {
  String _selectedSub = 'overview';

  List<_DashboardMenuItemData> get _masterSidebarItems =>
      _masterFilterSidebarItems(widget.session, const [
        _DashboardMenuItemData(iconKey: 'home', label: 'الرئيسية'),
        _DashboardMenuItemData(iconKey: 'operations', label: 'لوحة العمليات'),
        _DashboardMenuItemData(iconKey: 'orders', label: 'إدارة الطلبات'),
        _DashboardMenuItemData(
          iconKey: 'delivery',
          label: 'التوصيل والوجستيات',
        ),
        _DashboardMenuItemData(iconKey: 'store', label: 'إدارة المطاعم'),
        _DashboardMenuItemData(iconKey: 'users', label: 'العملاء'),
        _DashboardMenuItemData(iconKey: 'finance', label: 'الإدارة المالية'),
        _DashboardMenuItemData(iconKey: 'marketing', label: 'التسويق والنمو'),
        _DashboardMenuItemData(iconKey: 'communication', label: 'مركز التواصل'),
        _DashboardMenuItemData(
          iconKey: 'quality',
          label: 'الجودة وخدمة العملاء',
        ),
        _DashboardMenuItemData(
          iconKey: 'reports',
          label: 'التقارير والتحليلات',
          selected: true,
        ),
        _DashboardMenuItemData(iconKey: 'settings', label: 'إعدادات المنصة'),
        _DashboardMenuItemData(
          iconKey: 'administration',
          label: 'الإدارة والصلاحيات',
        ),
      ]);

  List<_DashboardMenuItemData> get _reportTabs => [
    _DashboardMenuItemData(
      iconKey: 'reports',
      label: 'نظرة عامة',
      selected: _selectedSub == 'overview',
    ),
    _DashboardMenuItemData(
      iconKey: 'users',
      label: 'المستخدمون',
      selected: _selectedSub == 'users',
    ),
    _DashboardMenuItemData(
      iconKey: 'truck',
      label: 'السائقون',
      selected: _selectedSub == 'drivers',
    ),
    _DashboardMenuItemData(
      iconKey: 'store',
      label: 'المطاعم',
      selected: _selectedSub == 'restaurants',
    ),
    _DashboardMenuItemData(
      iconKey: 'inventory',
      label: 'مرجع شامل',
      selected: _selectedSub == 'reference',
    ),
  ];

  void _openSidebarItem(String itemKey) {
    final key = _masterCanonicalModuleKey(itemKey);
    if (key == 'reports') {
      return;
    }
    _navigateToMasterSection(
      context,
      key: key,
      session: widget.session,
      onLogout: widget.onLogout,
      api: widget.api,
      serverNow: widget.serverNow,
    );
  }

  void _selectReportTab(String itemKey) {
    setState(() {
      switch (itemKey) {
        case 'users':
          _selectedSub = 'users';
          break;
        case 'truck':
        case 'delivery':
          _selectedSub = 'drivers';
          break;
        case 'store':
          _selectedSub = 'restaurants';
          break;
        case 'inventory':
          _selectedSub = 'reference';
          break;
        case 'reports':
        case 'query_stats':
        default:
          _selectedSub = 'overview';
      }
    });
  }

  Widget _buildSelectedPage() {
    switch (_selectedSub) {
      case 'users':
        return ReportsUsersPage(session: widget.session, api: widget.api);
      case 'drivers':
        return ReportsDriversPage(session: widget.session, api: widget.api);
      case 'restaurants':
        return ReportsRestaurantsPage(session: widget.session, api: widget.api);
      case 'reference':
        return ReportsReferencePage(session: widget.session, api: widget.api);
      case 'overview':
      default:
        return ReportsOverviewPage(session: widget.session, api: widget.api);
    }
  }

  Widget _buildReportsWorkspace() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReportsTabs(items: _reportTabs, onSelected: _selectReportTab),
        const SizedBox(height: 12),
        Expanded(child: _buildSelectedPage()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    _rememberMasterRuntime(widget.session, widget.onLogout, widget.api);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDFDFD), Color(0xFFF7F8FA), Color(0xFFF4F6F8)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wideLayout = constraints.maxWidth >= 1120;
                final sidebarWidth = constraints.maxWidth >= 1450
                    ? 246.0
                    : 232.0;
                final dashboardBodyHeight = constraints.maxHeight + 120.0;
                return Column(
                  children: [
                    _MasterDashboardTopBar(
                      displayName: widget.session.master.adminName,
                      roleLabel: widget.session.master.role?.roleName ?? '',
                      notificationBadge: 0,
                      serverNow: widget.serverNow,
                      statusLabel: 'التقارير',
                      platformTitle: 'التقارير والتحليلات',
                      platformSubtitle: 'تقارير المنصة الشاملة',
                      onLogout: widget.onLogout,
                      onSupportChatTap: () => _openMasterSupportChats(
                        context,
                        serverNow: widget.serverNow,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: SizedBox(
                          height: dashboardBodyHeight,
                          child: wideLayout
                              ? Row(
                                  textDirection: TextDirection.rtl,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(
                                      width: sidebarWidth,
                                      child: _MasterDashboardSidebar(
                                        items: _masterSidebarItems,
                                        onItemTap: _openSidebarItem,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: _buildReportsWorkspace(),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Expanded(child: _buildReportsWorkspace()),
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      height: 260,
                                      child: _MasterDashboardSidebar(
                                        items: _masterSidebarItems,
                                        onItemTap: _openSidebarItem,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportsOverviewResult {
  const _ReportsOverviewResult({
    required this.totalOrders,
    required this.revenue,
    required this.avgDeliveryMinutes,
    required this.newUsers,
    required this.acceptanceRate,
    required this.cancellationsRate,
    required this.series,
    required this.topRestaurants,
    required this.ratingsMetrics,
  });

  final int totalOrders;
  final double revenue;
  final double avgDeliveryMinutes;
  final int newUsers;
  final double acceptanceRate;
  final double cancellationsRate;
  final List<_ReportsTimeSeriesPoint> series;
  final List<_ReportsTopRestaurant> topRestaurants;
  final Map<String, dynamic> ratingsMetrics;

  factory _ReportsOverviewResult.fromJson(
    Map<String, dynamic> json,
    List<Map<String, dynamic>> topRestaurantsJson,
  ) {
    final ratings = _asMap(json['ratings']);
    return _ReportsOverviewResult(
      totalOrders: _toInt(json['total_orders']),
      revenue: _toDouble(json['revenue']),
      avgDeliveryMinutes: _toDouble(json['avg_delivery_minutes']),
      newUsers: _toInt(json['new_users']),
      acceptanceRate: _toDouble(json['acceptance_rate']),
      cancellationsRate: _toDouble(json['cancellations_rate']),
      series: _asMapList(
        json['series'],
      ).map(_ReportsTimeSeriesPoint.fromJson).toList(),
      topRestaurants: topRestaurantsJson
          .map(_ReportsTopRestaurant.fromJson)
          .toList(),
      ratingsMetrics: {
        for (final entry in ratings.entries) '${entry.key} نجوم': entry.value,
      },
    );
  }
}

class _ReportsTimeSeriesPoint {
  const _ReportsTimeSeriesPoint({required this.date, required this.value});

  final String date;
  final double value;

  factory _ReportsTimeSeriesPoint.fromJson(Map<String, dynamic> json) {
    return _ReportsTimeSeriesPoint(
      date: (json['date'] ?? '').toString(),
      value: _toDouble(json['value']),
    );
  }
}

class _ReportsTopRestaurant {
  const _ReportsTopRestaurant({
    required this.rank,
    required this.name,
    required this.sales,
    required this.orders,
  });

  final int rank;
  final String name;
  final double sales;
  final int orders;

  factory _ReportsTopRestaurant.fromJson(Map<String, dynamic> json) {
    return _ReportsTopRestaurant(
      rank: _toInt(json['rank']),
      name: _firstText([json['name']], 'مطعم غير محدد'),
      sales: _toDouble(json['sales']),
      orders: _toInt(json['orders'] ?? json['orders_count']),
    );
  }
}

class _ReportsReferenceData {
  const _ReportsReferenceData({
    required this.users,
    required this.delivery,
    required this.restaurants,
    required this.finance,
    required this.overview,
  });

  final _MasterUsersData users;
  final _MasterDeliveryLogisticsData delivery;
  final _RestaurantManagementSeed restaurants;
  final Map<String, dynamic> finance;
  final _ReportsOverviewResult overview;
}

class _ReportsMetricSpec {
  const _ReportsMetricSpec({
    required this.icon,
    required this.title,
    required this.value,
    required this.tint,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color tint;
  final Color color;
}

class _ReportsMetricsWrap extends StatelessWidget {
  const _ReportsMetricsWrap({required this.metrics});

  final List<_ReportsMetricSpec> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = width >= 1280
            ? (width - 48) / 4
            : width >= 920
            ? (width - 36) / 3
            : width >= 620
            ? (width - 12) / 2
            : width;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in metrics)
              _ReportsMetricCard(
                width: cardWidth,
                icon: metric.icon,
                title: metric.title,
                value: metric.value,
                tint: metric.tint,
                color: metric.color,
              ),
          ],
        );
      },
    );
  }
}

class _ReportsSimpleTable extends StatelessWidget {
  const _ReportsSimpleTable({
    required this.headers,
    required this.rows,
    required this.emptyLabel,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return SizedBox(height: 160, child: Center(child: Text(emptyLabel)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final minWidth = math.max(constraints.maxWidth, headers.length * 132.0);
        return SizedBox(
          height: math.min(420, 58.0 + (rows.length * 46.0)),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: minWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ReportsSimpleTableRow(
                      cells: headers,
                      header: true,
                      columnCount: headers.length,
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: rows.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final source = rows[index];
                          return _ReportsSimpleTableRow(
                            cells: [
                              for (var i = 0; i < headers.length; i++)
                                i < source.length ? source[i] : '-',
                            ],
                            columnCount: headers.length,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReportsSimpleTableRow extends StatelessWidget {
  const _ReportsSimpleTableRow({
    required this.cells,
    required this.columnCount,
    this.header = false,
  });

  final List<String> cells;
  final int columnCount;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: header ? const Color(0xFFF3F7F4) : Colors.transparent,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          for (var index = 0; index < columnCount; index++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  index < cells.length && cells[index].trim().isNotEmpty
                      ? cells[index]
                      : '-',
                  textAlign: TextAlign.right,
                  maxLines: header ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: header ? 11.5 : 12,
                    fontWeight: header ? FontWeight.w900 : FontWeight.w600,
                    color: header
                        ? const Color(0xFF243127)
                        : const Color(0xFF4E5660),
                    height: 1.25,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

_RestaurantManagementSeed _buildReportsRestaurantSeed(
  Map<String, dynamic> overview,
) {
  final restaurants = _asMapList(
    overview['restaurants'],
  ).map(_RestaurantProfile.fromJson).toList();
  final categoryRows = _asMapList(overview['categories']);
  final productRows = _asMapList(overview['products']);

  final categoryNameById = <String, String>{};
  for (final row in categoryRows) {
    final id = (row['categories_id'] ?? '').toString();
    final name = _normalizeUtf8Text(
      _firstText([
        row['categories_name_ar'],
        row['categories_name_en'],
        'تصنيف',
      ]),
    );
    if (id.isNotEmpty) {
      categoryNameById[id] = name;
    }
  }

  final products = [
    for (final row in productRows)
      _buildLiveProductRecord(row, categoryNameById: categoryNameById),
  ];
  final categories = [
    for (var index = 0; index < categoryRows.length; index++)
      _buildLiveCategoryRecord(
        categoryRows[index],
        index: index,
        products: products,
      ),
  ];
  final menuSections = [
    for (final category in categories)
      _MenuSectionRecord(
        category.name,
        category.productsCount,
        category.status,
        category.icon,
      ),
  ];
  final restaurantNameById = <String, String>{
    for (final restaurant in restaurants) restaurant.id: restaurant.name,
    for (final restaurant in restaurants)
      restaurant.id.replaceFirst('RST-', ''): restaurant.name,
  };

  return _RestaurantManagementSeed.empty().copyWith(
    restaurants: restaurants,
    categories: categories,
    products: products,
    menuSections: menuSections,
    toppings: [
      for (final row in _asMapList(overview['toppings']))
        _buildLiveToppingRecord(row, categoryNameById: categoryNameById),
    ],
    offers: [
      for (final row in _asMapList(overview['offers']))
        _buildLiveOfferRecord(row, restaurantNameById),
    ],
    coupons: [
      for (final row in _asMapList(overview['coupons']))
        _buildLiveCouponRecord(row),
    ],
  );
}

class _ReportsSurface extends StatelessWidget {
  const _ReportsSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _ReportsHeader extends StatelessWidget {
  const _ReportsHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5ED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _kPrimaryGreen, size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E232A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6F7680),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportsMetricCard extends StatelessWidget {
  const _ReportsMetricCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.value,
    required this.tint,
    required this.color,
  });

  final double width;
  final IconData icon;
  final String title;
  final String value;
  final Color tint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 112,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFECEFF0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.2,
                      color: Color(0xFF6F7680),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: Color(0xFF151A20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportsSectionCard extends StatelessWidget {
  const _ReportsSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEFF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, size: 18, color: _kPrimaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReportsBarChart extends StatelessWidget {
  const _ReportsBarChart({required this.series});

  final List<_ReportsTimeSeriesPoint> series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const Center(child: Text('لا توجد بيانات للعرض'));
    }
    final visible = series.length > 30
        ? series.sublist(series.length - 30)
        : series;
    final maxValue = visible
        .map((item) => item.value)
        .fold<double>(0, math.max);
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final point in visible)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Tooltip(
                      message:
                          '${point.date} - ${_formatInt(point.value.round())}',
                      child: FractionallySizedBox(
                        heightFactor: maxValue > 0
                            ? (point.value / maxValue).clamp(0.04, 1.0)
                            : 0.04,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _kPrimaryGreen.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final point in visible.where((item) {
              final index = visible.indexOf(item);
              return index == 0 ||
                  index == visible.length - 1 ||
                  index == visible.length ~/ 2;
            }))
              Expanded(
                child: Text(
                  point.date,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6F7680),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ReportsTopRestaurantsList extends StatelessWidget {
  const _ReportsTopRestaurantsList({required this.restaurants});

  final List<_ReportsTopRestaurant> restaurants;

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('لا توجد مبيعات مطاعم مكتملة بعد')),
      );
    }
    return Column(
      children: [
        for (final item in restaurants.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                _ReportsRankBadge(rank: item.rank),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _formatMoney(item.sales),
                  style: const TextStyle(
                    fontSize: 12.2,
                    color: Color(0xFF4E5660),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReportsRestaurantsTable extends StatelessWidget {
  const _ReportsRestaurantsTable({required this.restaurants});

  final List<_ReportsTopRestaurant> restaurants;

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) {
      return const Center(child: Text('لا توجد بيانات مطاعم للعرض'));
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: restaurants.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = restaurants[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              _ReportsRankBadge(rank: item.rank),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  item.name,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              Expanded(
                child: Text(
                  '${_formatInt(item.orders)} طلب',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF6F7680)),
                ),
              ),
              Expanded(
                child: Text(
                  _formatMoney(item.sales),
                  textAlign: TextAlign.left,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReportsRankBadge extends StatelessWidget {
  const _ReportsRankBadge({required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5ED),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        rank <= 0 ? '-' : '$rank',
        style: const TextStyle(
          color: _kPrimaryGreen,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ReportsMetricsPage extends StatelessWidget {
  const _ReportsMetricsPage({
    required this.future,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.emptyLabel,
  });

  final Future<Map<String, dynamic>> future;
  final IconData icon;
  final String title;
  final String subtitle;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _ReportsLoadingCard();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return _ReportsErrorCard(message: snapshot.error?.toString() ?? '');
        }
        final metrics = Map<String, dynamic>.from(snapshot.data!);
        final ratings = _asMap(metrics.remove('ratings'));
        return _ReportsSurface(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReportsHeader(icon: icon, title: title, subtitle: subtitle),
                const SizedBox(height: 14),
                _ReportsMetricsGrid(metrics: metrics, emptyLabel: emptyLabel),
                if (ratings.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _ReportsSectionCard(
                    title: 'توزيع التقييمات',
                    icon: Icons.star_outline_rounded,
                    child: _ReportsKeyValueList(
                      metrics: {
                        for (final entry in ratings.entries)
                          '${entry.key} نجوم': entry.value,
                      },
                      emptyLabel: 'لا توجد تقييمات',
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReportsMetricsGrid extends StatelessWidget {
  const _ReportsMetricsGrid({required this.metrics, required this.emptyLabel});

  final Map<String, dynamic> metrics;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return SizedBox(height: 220, child: Center(child: Text(emptyLabel)));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = width >= 1050
            ? (width - 36) / 4
            : width >= 760
            ? (width - 24) / 3
            : width >= 520
            ? (width - 12) / 2
            : width;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final entry in metrics.entries)
              _ReportsMetricCard(
                width: cardWidth,
                icon: Icons.analytics_outlined,
                title: entry.key,
                value: entry.value.toString(),
                tint: const Color(0xFFEAF5ED),
                color: _kPrimaryGreen,
              ),
          ],
        );
      },
    );
  }
}

class _ReportsKeyValueList extends StatelessWidget {
  const _ReportsKeyValueList({required this.metrics, required this.emptyLabel});

  final Map<String, dynamic> metrics;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return SizedBox(height: 180, child: Center(child: Text(emptyLabel)));
    }
    return Column(
      children: [
        for (final entry in metrics.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Text(
                    entry.key,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12.4,
                      color: Color(0xFF4E5660),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  entry.value.toString(),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReportsTabs extends StatelessWidget {
  const _ReportsTabs({required this.items, required this.onSelected});

  final List<_DashboardMenuItemData> items;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final item in items)
            _ReportsTabButton(
              item: item,
              onTap: () => onSelected(item.iconKey),
            ),
        ],
      ),
    );
  }
}

class _ReportsTabButton extends StatelessWidget {
  const _ReportsTabButton({required this.item, required this.onTap});

  final _DashboardMenuItemData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = item.selected;
    return Tooltip(
      message: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: selected ? _kDeepGreen : const Color(0xFFF8FAF9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? _kDeepGreen : const Color(0xFFE5E8E5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.rtl,
              children: [
                Icon(
                  item.icon,
                  size: 16,
                  color: selected ? Colors.white : const Color(0xFF4E5660),
                ),
                const SizedBox(width: 7),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12.2,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? Colors.white : const Color(0xFF4E5660),
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

class _ReportsLoadingCard extends StatelessWidget {
  const _ReportsLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const _ReportsSurface(
      child: SizedBox(
        height: 420,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.8)),
      ),
    );
  }
}

class _ReportsErrorCard extends StatelessWidget {
  const _ReportsErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _ReportsSurface(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFD92C2C),
                size: 34,
              ),
              const SizedBox(height: 10),
              const Text(
                'تعذر تحميل بيانات التقارير',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                message.isEmpty ? 'حاول مرة أخرى بعد قليل' : message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6F7680), height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatInt(num value) {
  final text = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final fromEnd = text.length - i;
    buffer.write(text[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String _formatMoney(num value) => '${_formatInt(value)} س';

String _formatPercent(num value) => '${value.toStringAsFixed(1)}%';

String _formatMinutes(num value) {
  if (value <= 0) {
    return '0 دقيقة';
  }
  return '${value.round()} دقيقة';
}
