import 'package:admin_tks/controler/support_controller.dart';
import 'package:admin_tks/model/support_model.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final SupportController _controller = SupportController();
  late Future<List<support_model>> _complaintsFuture;
  int _complaintsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    final future = _controller.fetchComplaints();
    setState(() {
      _complaintsFuture = future;
    });

    try {
      final complaints = await future;
      if (!mounted) return;
      setState(() {
        _complaintsCount = complaints.length;
      });
    } catch (_) {}
  }

  Widget _buildComplaintCard(support_model complaint) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.support_agent_rounded, color: kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      complaint.userName ?? 'مستخدم غير معروف',
                      style: const TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint.submissionDate ?? 'بدون تاريخ',
                      style: const TextStyle(
                        color: kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            complaint.complaintDescription ?? 'لا يوجد وصف',
            style: const TextStyle(
              color: kTextPrimary,
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoChip(
                icon: Icons.phone_rounded,
                label: complaint.userPhone ?? 'لا يوجد رقم',
              ),
              _InfoChip(
                icon: Icons.email_rounded,
                label: complaint.userEmail ?? 'لا يوجد بريد',
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardPageShell(
      title: 'الدعم والشكاوى',
      subtitle: 'متابعة شكاوى العملاء والرد عليها من داخل لوحة المطعم.',
      icon: Icons.support_agent_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: _loadComplaints,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'الشكاوى المسجلة',
          value: '$_complaintsCount',
          icon: Icons.mark_unread_chat_alt_rounded,
          tint: kPrimary,
        ),
      ],
      body: FutureBuilder<List<support_model>>(
        future: _complaintsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 84),
              child: Center(child: CircularProgressIndicator(color: kPrimary)),
            );
          }

          if (snapshot.hasError) {
            return DashboardEmptyState(
              title: 'تعذر تحميل الشكاوى',
              subtitle: snapshot.error.toString(),
              icon: Icons.cloud_off_rounded,
            );
          }

          final complaints = snapshot.data ?? const <support_model>[];
          if (complaints.isEmpty) {
            return const DashboardEmptyState(
              title: 'لا توجد شكاوى الآن',
              subtitle: 'عندما تصل شكاوى جديدة ستظهر هنا بشكل منظم وسريع.',
              icon: Icons.inbox_rounded,
            );
          }

          return DashboardPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'قائمة الشكاوى',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      '${complaints.length} عنصر',
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
                  itemCount: complaints.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _buildComplaintCard(complaints[index]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kSurfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kStroke),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: kTextSecondary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: kTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
