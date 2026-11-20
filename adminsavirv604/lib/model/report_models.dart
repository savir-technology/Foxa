class SalesReportRow {
  SalesReportRow({
    required this.saleDate,
    required this.totalSales,
  });

  factory SalesReportRow.fromJson(Map<String, dynamic> json) {
    return SalesReportRow(
      saleDate: json['sale_date']?.toString() ?? '',
      totalSales: double.tryParse(json['total_sales']?.toString() ?? '') ?? 0,
    );
  }

  final String saleDate;
  final double totalSales;
}

class SalesReportSummary {
  SalesReportSummary({
    required this.totalSales,
    required this.daysCount,
    required this.averageDailySales,
  });

  factory SalesReportSummary.fromJson(Map<String, dynamic> json) {
    return SalesReportSummary(
      totalSales: double.tryParse(json['total_sales']?.toString() ?? '') ?? 0,
      daysCount: int.tryParse(json['days_count']?.toString() ?? '') ?? 0,
      averageDailySales:
          double.tryParse(json['average_daily_sales']?.toString() ?? '') ?? 0,
    );
  }

  final double totalSales;
  final int daysCount;
  final double averageDailySales;
}

class SalesReportResponse {
  SalesReportResponse({
    required this.summary,
    required this.rows,
  });

  final SalesReportSummary summary;
  final List<SalesReportRow> rows;
}

class ProfitReport {
  ProfitReport({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalWasteCost,
    required this.netProfit,
    required this.inventoryUnits,
    required this.inventoryValue,
  });

  factory ProfitReport.fromJson(Map<String, dynamic> json) {
    return ProfitReport(
      totalRevenue: double.tryParse(json['total_revenue']?.toString() ?? '') ?? 0,
      totalExpenses:
          double.tryParse(json['total_expenses']?.toString() ?? '') ?? 0,
      totalWasteCost:
          double.tryParse(json['total_waste_cost']?.toString() ?? '') ?? 0,
      netProfit: double.tryParse(json['net_profit']?.toString() ?? '') ?? 0,
      inventoryUnits:
          int.tryParse(json['inventory_units']?.toString() ?? '') ?? 0,
      inventoryValue:
          double.tryParse(json['inventory_value']?.toString() ?? '') ?? 0,
    );
  }

  final double totalRevenue;
  final double totalExpenses;
  final double totalWasteCost;
  final double netProfit;
  final int inventoryUnits;
  final double inventoryValue;
}

