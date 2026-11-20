class DashboardRoutes {
  DashboardRoutes._();

  static const String home = '/';
  static const String orders = '/vendor/orders';
  static const String orderStatuses = '/vendor/order-statuses';
  static const String deliveryOperations = '/vendor/delivery-operations';
  static const String categories = '/vendor/categories';
  static const String menu = '/vendor/menu';
  static const String addProduct = '/vendor/add-product';
  static const String inventory = '/vendor/inventory';
  static const String coupons = '/vendor/coupons';
  static const String hours = '/vendor/hours';
  static const String reviews = '/vendor/reviews';
  static const String analytics = '/vendor/analytics';
  static const String salesReport = '/vendor/sales-report';
  static const String profitReport = '/vendor/profit-report';
  static const String settings = '/vendor/settings';
  static const String waste = '/vendor/waste';

  // Master console routes. These pages already exist in the project but were
  // not reachable from the application router.
  static const String masterVendors = '/master/vendors';
  static const String masterUsers = '/master/users';
  static const String masterAds = '/master/ads';
  static const String masterStories = '/master/stories';
}
