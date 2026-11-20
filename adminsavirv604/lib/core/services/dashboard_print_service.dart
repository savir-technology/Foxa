import 'package:admin_tks/core/services/dashboard_print_service_stub.dart'
    if (dart.library.html) 'package:admin_tks/core/services/dashboard_print_service_web.dart'
    as dashboard_print;

Future<void> triggerDashboardPrint() => dashboard_print.triggerDashboardPrint();
