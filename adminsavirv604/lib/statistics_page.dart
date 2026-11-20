import 'dart:convert';
import 'dart:math' as math;

import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';

class ProductStatisticsPage extends StatefulWidget {
  const ProductStatisticsPage({super.key});

  @override
  State<ProductStatisticsPage> createState() => _ProductStatisticsPageState();
}

class _ProductStatisticsPageState extends State<ProductStatisticsPage> {
  final List<ProductData> _productData = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    fetchProductData();
  }

  double get _totalInterest =>
      _productData.fold<double>(0, (sum, item) => sum + item.interestedUsers);

  double get _topInterest => _productData.fold<double>(
        0,
        (currentMax, item) => math.max(currentMax, item.interestedUsers),
      );

  Future<void> fetchProductData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final response = await DashboardApiClient.getUrl(
        'https://savir-technology.online/roaqv2/dash/fav/get/get_favorite_stats.php',
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load statistics');
      }

      final decoded = json.decode(utf8.decode(response.bodyBytes));
      final List<dynamic> rows = decoded is List
          ? decoded
          : decoded is Map && decoded['data'] is List
              ? decoded['data'] as List<dynamic>
              : const <dynamic>[];

      final parsed = rows.whereType<Map>().map((item) {
        final map = item.cast<String, dynamic>();
        return ProductData(
          productName: map['product_name']?.toString() ?? '-',
          interestedUsers:
              double.tryParse(map['interested_users']?.toString() ?? '0') ?? 0,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _productData
          ..clear()
          ..addAll(parsed);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardPageShell(
      title: 'إحصائيات المنتجات',
      subtitle: 'عرض سريع للمنتجات الأكثر جذبًا داخل المطعم ومؤشرات الاهتمام.',
      icon: Icons.query_stats_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: fetchProductData,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'إجمالي المنتجات',
          value: '${_productData.length}',
          icon: Icons.inventory_2_rounded,
          tint: kPrimary,
        ),
        DashboardStatCard(
          label: 'إجمالي الاهتمام',
          value: '${_totalInterest.toInt()}',
          icon: Icons.favorite_rounded,
          tint: kAccent,
        ),
        DashboardStatCard(
          label: 'أعلى اهتمام',
          value: '${_topInterest.toInt()}',
          icon: Icons.trending_up_rounded,
          tint: const Color(0xFFF59E0B),
        ),
      ],
      body: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 84),
              child: Center(child: CircularProgressIndicator(color: kPrimary)),
            )
          : _error != null
              ? DashboardEmptyState(
                  title: 'تعذر تحميل الإحصائيات',
                  subtitle: _error!,
                  icon: Icons.cloud_off_rounded,
                )
              : _productData.isEmpty
                  ? const DashboardEmptyState(
                      title: 'لا توجد بيانات بعد',
                      subtitle:
                          'أضف منتجات أو انتظر تراكم التفاعل لتظهر الإحصائيات هنا.',
                      icon: Icons.bar_chart_rounded,
                    )
                  : DashboardPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'المنتجات الأكثر اهتمامًا',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                '${_productData.length} صنف',
                                style: const TextStyle(
                                  color: kTextSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _productData.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1, color: kStroke),
                            itemBuilder: (context, index) {
                              final product = _productData[index];
                              final progress = _topInterest == 0
                                  ? 0.0
                                  : (product.interestedUsers / _topInterest)
                                      .clamp(0.0, 1.0);

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 2,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            product.productName,
                                            style: const TextStyle(
                                              color: kTextPrimary,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          product.interestedUsers
                                              .toInt()
                                              .toString(),
                                          style: const TextStyle(
                                            color: kTextSecondary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        minHeight: 9,
                                        value: progress,
                                        backgroundColor:
                                            const Color(0xFFEAF0EA),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          kPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class ProductData {
  const ProductData({
    required this.productName,
    required this.interestedUsers,
  });

  final String productName;
  final double interestedUsers;
}
