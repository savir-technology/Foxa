import 'dart:math' as math;

import 'package:admin_tks/controler/dashboard_auth_controller.dart';
import 'package:admin_tks/core/services/dashboard_api_client.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ReviewsRatingsPage extends StatefulWidget {
  const ReviewsRatingsPage({super.key});

  @override
  State<ReviewsRatingsPage> createState() => _ReviewsRatingsPageState();
}

class _ReviewsRatingsPageState extends State<ReviewsRatingsPage> {
  static const String _baseUrl =
      'https://savir-technology.online/roaqv2/ratings/vendor_ratings.php';

  final List<VendorReview> _reviews = [];
  bool _loading = true;

  String _ratingFilter = 'all';
  String _sentimentFilter = 'all';
  String _topicFilter = 'all';
  DateTimeRange? _dateRange;

  DashboardAuthController get _auth => Get.find<DashboardAuthController>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final vendorId = _auth.vendorId;
      final response = await DashboardApiClient.getUrl(
        '$_baseUrl?vendor_id=$vendorId',
      );
      final decoded = DashboardApiClient.decodeJson(response);

      final rows = <VendorReview>[];
      if (decoded is Map && decoded['status'] == 'success') {
        final ratings = decoded['ratings'];
        if (ratings is List) {
          for (final entry in ratings.whereType<Map>()) {
            rows.add(VendorReview.fromJson(entry.cast<String, dynamic>()));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _reviews
          ..clear()
          ..addAll(rows);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل التقييمات: $e')),
      );
    }
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.fold<double>(0, (sum, review) => sum + review.rating) /
        _reviews.length;
  }

  int get _totalReviews => _reviews.length;

  int get _positiveCount =>
      _reviews.where((review) => review.rating >= 4).length;

  int get _negativeCount =>
      _reviews.where((review) => review.rating <= 2).length;

  List<VendorReview> get _filteredReviews {
    return _reviews.where((review) {
      final ratingMatch = _ratingFilter == 'all'
          ? true
          : _ratingFilter == review.rating.floor().toString();
      final sentimentMatch = switch (_sentimentFilter) {
        'positive' => review.rating >= 4,
        'negative' => review.rating <= 2,
        'neutral' => review.rating == 3,
        _ => true,
      };
      final topicMatch =
          _topicFilter == 'all' ? true : review.topicKey == _topicFilter;
      final dateMatch =
          _dateRange == null ? true : review.matchesDateRange(_dateRange!);
      return ratingMatch && sentimentMatch && topicMatch && dateMatch;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Map<String, int> get _topicCounts {
    final counts = <String, int>{};
    for (final review in _reviews.where((item) => item.rating <= 3)) {
      counts.update(review.topicKey, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  Map<int, int> get _ratingBreakdown {
    final counts = <int, int>{for (var i = 1; i <= 5; i++) i: 0};
    for (final review in _reviews) {
      counts.update(review.rating.round().clamp(1, 5), (value) => value + 1,
          ifAbsent: () => 1);
    }
    return counts;
  }

  String _topicLabel(String key) {
    switch (key) {
      case 'delay':
        return 'تأخير';
      case 'quality':
        return 'جودة الطعام';
      case 'price':
        return 'سعر مرتفع';
      case 'error':
        return 'أخطاء الطلب';
      case 'service':
        return 'خدمة';
      default:
        return 'أخرى';
    }
  }

  Color _topicColor(String key) {
    switch (key) {
      case 'delay':
        return Colors.redAccent;
      case 'quality':
        return const Color(0xFFF59E0B);
      case 'price':
        return const Color(0xFF3B82F6);
      case 'error':
        return const Color(0xFF8B5CF6);
      case 'service':
        return const Color(0xFF14B8A6);
      default:
        return Colors.grey;
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );
    if (picked == null || !mounted) return;
    setState(() => _dateRange = picked);
  }

  void _resetFilters() {
    setState(() {
      _ratingFilter = 'all';
      _sentimentFilter = 'all';
      _topicFilter = 'all';
      _dateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReviews;
    final topicEntries = _topicCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final ratingEntries = _ratingBreakdown.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return DashboardPageShell(
      title: 'التقييمات والمراجعات',
      subtitle: 'إدارة آراء العملاء وتقييمات المطعم من مكان واحد.',
      icon: Icons.star_outline_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'متوسط التقييم',
          value: _averageRating.toStringAsFixed(1),
          icon: Icons.star_rounded,
          tint: const Color(0xFF16A34A),
        ),
        DashboardStatCard(
          label: 'إجمالي التقييمات',
          value: '$_totalReviews',
          icon: Icons.chat_bubble_outline_rounded,
          tint: kPrimary,
        ),
        DashboardStatCard(
          label: 'تقييمات إيجابية',
          value: '$_positiveCount',
          icon: Icons.sentiment_satisfied_alt_rounded,
          tint: const Color(0xFFF59E0B),
        ),
        DashboardStatCard(
          label: 'تقييمات سلبية',
          value: '$_negativeCount',
          icon: Icons.sentiment_dissatisfied_rounded,
          tint: Colors.redAccent,
        ),
      ],
      body: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 96),
              child: Center(child: CircularProgressIndicator(color: kPrimary)),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 1180;

                final complaintsPanel = DashboardPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        title: 'تصنيف أسباب الشكاوى',
                        subtitle: 'أكثر الأسباب ظهورًا داخل التقييمات السلبية.',
                        icon: Icons.info_outline_rounded,
                      ),
                      const SizedBox(height: 18),
                      if (topicEntries.isEmpty)
                        const SizedBox(
                          height: 150,
                          child: Center(
                            child: Text(
                              'لا توجد شكاوى واضحة حتى الآن',
                              style: TextStyle(
                                color: kTextSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else
                        ...topicEntries.take(5).map((entry) {
                          final total = math.max(1, _negativeCount);
                          final progress = entry.value / total;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _MetricBar(
                              label: _topicLabel(entry.key),
                              value: entry.value,
                              progress: progress,
                              tint: _topicColor(entry.key),
                            ),
                          );
                        }),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() => _topicFilter = 'all');
                          },
                          child: const Text('عرض كل الشكاوى'),
                        ),
                      ),
                    ],
                  ),
                );

                final ratingPanel = DashboardPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        title: 'توزيع التقييمات',
                        subtitle: 'عدد التقييمات لكل نجمة.',
                        icon: Icons.star_border_rounded,
                      ),
                      const SizedBox(height: 18),
                      ...ratingEntries.map((entry) {
                        final total = math.max(1, _totalReviews);
                        final progress = entry.value / total;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _RatingBreakdownRow(
                            stars: entry.key,
                            count: entry.value,
                            progress: progress,
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {},
                          child: const Text('عرض كل التقييمات'),
                        ),
                      ),
                    ],
                  ),
                );

                final reviewsColumn = DashboardPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        title: 'أحدث التقييمات',
                        subtitle: 'أحدث آراء العملاء وتعليقاتهم على الأصناف.',
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                      const SizedBox(height: 16),
                      if (filtered.isEmpty)
                        const DashboardEmptyState(
                          title: 'لا توجد تقييمات مطابقة',
                          subtitle: 'جرّب تغيير الفلاتر أو النطاق الزمني.',
                          icon: Icons.rate_review_outlined,
                        )
                      else
                        ...filtered.take(5).map(
                              (review) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ReviewTile(review: review),
                              ),
                            ),
                    ],
                  ),
                );

                final filterColumn = DashboardPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        title: 'فلترة التقييمات',
                        subtitle: 'قيد التصفية حسب النجوم، النوع، والفترة.',
                        icon: Icons.filter_alt_rounded,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _ratingFilter,
                        decoration: const InputDecoration(
                          labelText: 'جميع التقييمات',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('جميع التقييمات')),
                          DropdownMenuItem(value: '5', child: Text('5 نجوم')),
                          DropdownMenuItem(value: '4', child: Text('4 نجوم')),
                          DropdownMenuItem(value: '3', child: Text('3 نجوم')),
                          DropdownMenuItem(value: '2', child: Text('2 نجوم')),
                          DropdownMenuItem(value: '1', child: Text('1 نجمة')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _ratingFilter = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _sentimentFilter,
                        decoration: const InputDecoration(
                          labelText: 'جميع الأنواع',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('جميع الأنواع')),
                          DropdownMenuItem(
                              value: 'positive', child: Text('إيجابي')),
                          DropdownMenuItem(
                              value: 'neutral', child: Text('محايد')),
                          DropdownMenuItem(
                              value: 'negative', child: Text('سلبي')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _sentimentFilter = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _topicFilter,
                        decoration: const InputDecoration(
                          labelText: 'جميع الأسباب',
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: 'all', child: Text('جميع الأسباب')),
                          ...const [
                            'delay',
                            'quality',
                            'price',
                            'error',
                            'service',
                            'other',
                          ].map(
                            (topic) => DropdownMenuItem(
                              value: topic,
                              child: Text(_topicLabel(topic)),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _topicFilter = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        readOnly: true,
                        onTap: _pickDateRange,
                        decoration: InputDecoration(
                          labelText: _dateRange == null
                              ? 'الفترة الزمنية'
                              : '${_shortDate(_dateRange!.start)} - ${_shortDate(_dateRange!.end)}',
                          prefixIcon: const Icon(Icons.date_range_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _resetFilters,
                              child: const Text('إعادة تعيين'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => setState(() {}),
                              child: const Text('تطبيق الفلتر'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );

                if (!wide) {
                  return Column(
                    children: [
                      complaintsPanel,
                      const SizedBox(height: 16),
                      ratingPanel,
                      const SizedBox(height: 16),
                      reviewsColumn,
                      const SizedBox(height: 16),
                      filterColumn,
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: complaintsPanel),
                        const SizedBox(width: 16),
                        Expanded(child: ratingPanel),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: reviewsColumn),
                        const SizedBox(width: 16),
                        Expanded(child: filterColumn),
                      ],
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class VendorReview {
  const VendorReview({
    required this.ratingId,
    required this.itemId,
    required this.userId,
    required this.userName,
    required this.itemName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.topicKey,
  });

  factory VendorReview.fromJson(Map<String, dynamic> json) {
    final rating = double.tryParse(json['rating']?.toString() ?? '') ?? 0;
    final comment = json['comment']?.toString().trim() ?? '';
    return VendorReview(
      ratingId: int.tryParse(json['rating_id']?.toString() ?? '') ?? 0,
      itemId: int.tryParse(json['items_id']?.toString() ?? '') ?? 0,
      userId: int.tryParse(json['users_id']?.toString() ?? '') ?? 0,
      userName: json['users_name']?.toString().trim().isNotEmpty == true
          ? json['users_name'].toString().trim()
          : 'مستخدم',
      itemName: json['item_name']?.toString().trim().isNotEmpty == true
          ? json['item_name'].toString().trim()
          : 'صنف',
      rating: rating,
      comment: comment,
      createdAt: _parseDate(json['created_at']),
      topicKey: _detectTopic(comment, rating),
    );
  }

  final int ratingId;
  final int itemId;
  final int userId;
  final String userName;
  final String itemName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String topicKey;

  bool get isPositive => rating >= 4;
  bool get isNegative => rating <= 2;
  bool get isNeutral => rating == 3;

  String get sentimentLabel {
    if (isPositive) return 'إيجابي';
    if (isNegative) return 'سلبي';
    return 'محايد';
  }

  Color get sentimentColor {
    if (isPositive) return const Color(0xFF16A34A);
    if (isNegative) return Colors.redAccent;
    return const Color(0xFFF59E0B);
  }

  bool matchesDateRange(DateTimeRange range) {
    final day = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final start =
        DateTime(range.start.year, range.start.month, range.start.day);
    final end =
        DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
    return !day.isBefore(start) && !day.isAfter(end);
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: kPrimary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: kTextSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.progress,
    required this.tint,
  });

  final String label;
  final int value;
  final double progress;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                color: tint,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress.clamp(0, 1),
            backgroundColor: const Color(0xFFEAEFED),
            valueColor: AlwaysStoppedAnimation<Color>(tint),
          ),
        ),
      ],
    );
  }
}

class _RatingBreakdownRow extends StatelessWidget {
  const _RatingBreakdownRow({
    required this.stars,
    required this.count,
    required this.progress,
  });

  final int stars;
  final int count;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final activeColor = stars >= 4
        ? const Color(0xFF16A34A)
        : stars == 3
            ? const Color(0xFFF59E0B)
            : stars == 2
                ? Colors.orange
                : Colors.redAccent;
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            '$stars نجوم',
            style: const TextStyle(color: kTextPrimary),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress.clamp(0, 1),
              backgroundColor: const Color(0xFFE9ECE9),
              valueColor: AlwaysStoppedAnimation<Color>(activeColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 48,
          child: Text(
            '$count',
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: kTextSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReviewTile extends StatefulWidget {
  const _ReviewTile({required this.review});

  final VendorReview review;

  @override
  State<_ReviewTile> createState() => _ReviewTileState();
}

class _ReviewTileState extends State<_ReviewTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final initials =
        review.userName.trim().isNotEmpty ? review.userName.trim()[0] : '?';

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FBF9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kStroke),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      review.sentimentColor.withValues(alpha: 0.12),
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: review.sentimentColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        review.itemName,
                        style: const TextStyle(color: kTextSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _shortDate(review.createdAt),
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StarRow(value: review.rating),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: kTextSecondary,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              Text(
                review.comment.isEmpty ? 'لا يوجد تعليق نصي' : review.comment,
                style: const TextStyle(color: kTextPrimary, height: 1.45),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _TopicChip(
                    label: _topicLabel(review.topicKey),
                    tint: review.sentimentColor,
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('رد سريع'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final threshold = index + 1;
        final icon = value >= threshold
            ? Icons.star_rounded
            : value >= threshold - 0.5
                ? Icons.star_half_rounded
                : Icons.star_border_rounded;
        final color =
            value >= threshold ? const Color(0xFFF4B400) : Colors.grey.shade300;
        return Icon(icon, size: 16, color: color);
      }),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: tint,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

DateTime _parseDate(dynamic raw) {
  final value = raw?.toString().trim() ?? '';
  if (value.isEmpty) return DateTime.now();
  return DateTime.tryParse(value.replaceFirst(' ', 'T')) ?? DateTime.now();
}

String _shortDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year/$month/$day';
}

String _detectTopic(String comment, double rating) {
  final text = comment.toLowerCase();
  if (text.contains('تأخير') ||
      text.contains('متأخر') ||
      text.contains('delay') ||
      text.contains('late')) {
    return 'delay';
  }
  if (text.contains('جودة') ||
      text.contains('بارد') ||
      text.contains('cold') ||
      text.contains('quality')) {
    return 'quality';
  }
  if (text.contains('سعر') ||
      text.contains('غالي') ||
      text.contains('price') ||
      text.contains('expensive')) {
    return 'price';
  }
  if (text.contains('خطأ') ||
      text.contains('ناقص') ||
      text.contains('missing') ||
      text.contains('error')) {
    return 'error';
  }
  if (text.contains('خدمة') ||
      text.contains('معاملة') ||
      text.contains('service') ||
      text.contains('staff')) {
    return 'service';
  }

  if (rating <= 2) {
    return 'other';
  }

  return 'other';
}

String _topicLabel(String key) {
  switch (key) {
    case 'delay':
      return 'تأخير';
    case 'quality':
      return 'جودة الطعام';
    case 'price':
      return 'سعر مرتفع';
    case 'error':
      return 'أخطاء الطلب';
    case 'service':
      return 'خدمة';
    default:
      return 'أخرى';
  }
}
