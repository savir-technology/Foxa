import 'package:admin_tks/model/admin_notification_model.dart';
import 'package:admin_tks/remote/admin_notifications_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final AdminNotificationsData api = AdminNotificationsData();
  final TextEditingController _searchController = TextEditingController();

  AdminNotificationSummary summary =
      AdminNotificationSummary(totalCount: 0, unreadCount: 0, readCount: 0);
  List<AdminNotification> rows = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetch() async {
    setState(() => loading = true);
    final res = await api.getAll();
    if (!mounted) return;
    setState(() {
      summary = res?.summary ??
          AdminNotificationSummary(totalCount: 0, unreadCount: 0, readCount: 0);
      rows = res?.rows ?? [];
      loading = false;
    });
  }

  Future<void> _markRead(AdminNotification n) async {
    if (n.isRead) return;
    final ok = await api.markRead(n.notificationId);
    if (!mounted) return;
    if (ok) {
      fetch();
    }
  }

  Future<void> _markAllRead() async {
    final ok = await api.markAllRead();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تعليم كل الإشعارات كمقروءة')),
      );
      fetch();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل تحديث حالة الإشعارات')),
      );
    }
  }

  List<AdminNotification> get _filteredRows {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((n) {
      final text = '${n.title} ${n.body} ${n.type} ${n.userId}'.toLowerCase();
      return text.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRows;
    final isMobile = MediaQuery.of(context).size.width < 920;

    return DashboardPageShell(
      title: 'الإشعارات',
      subtitle: 'متابعة كل تنبيهات النظام مع إمكانية تعليمها كمقروءة.',
      icon: Icons.notifications_active_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: fetch,
          icon: const Icon(Icons.refresh_rounded),
        ),
        IconButton.filled(
          onPressed: _markAllRead,
          icon: const Icon(Icons.done_all_rounded),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'إجمالي الإشعارات',
          value: '${summary.totalCount}',
          icon: Icons.notifications_rounded,
          tint: kPrimary,
        ),
        DashboardStatCard(
          label: 'غير مقروء',
          value: '${summary.unreadCount}',
          icon: Icons.mark_chat_unread_rounded,
          tint: Colors.redAccent,
        ),
        DashboardStatCard(
          label: 'مقروء',
          value: '${summary.readCount}',
          icon: Icons.mark_chat_read_rounded,
          tint: Colors.green,
        ),
      ],
      body: Column(
        children: [
          DashboardPanel(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'ابحث في العنوان أو المحتوى أو النوع',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 70),
              child: CircularProgressIndicator(color: kPrimary),
            )
          else if (filtered.isEmpty)
            const DashboardEmptyState(
              title: 'لا توجد إشعارات',
              subtitle: 'عند وصول إشعارات جديدة ستظهر هنا.',
              icon: Icons.notifications_none_rounded,
            )
          else if (isMobile)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _NotificationCard(
                item: filtered[index],
                onMarkRead: () => _markRead(filtered[index]),
              ),
            )
          else
            DashboardPanel(
              padding: const EdgeInsets.all(0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('الحالة')),
                    DataColumn(label: Text('العنوان')),
                    DataColumn(label: Text('المحتوى')),
                    DataColumn(label: Text('النوع')),
                    DataColumn(label: Text('المستخدم')),
                    DataColumn(label: Text('التاريخ')),
                    DataColumn(label: Text('إجراء')),
                  ],
                  rows: filtered.map((n) {
                    return DataRow(cells: [
                      DataCell(_ReadBadge(isRead: n.isRead)),
                      DataCell(Text(n.title)),
                      DataCell(
                        SizedBox(
                          width: 340,
                          child: Text(
                            n.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text(n.type)),
                      DataCell(Text('#${n.userId}')),
                      DataCell(Text(n.createdAt)),
                      DataCell(
                        n.isRead
                            ? const Icon(Icons.done_rounded, color: Colors.green)
                            : IconButton(
                                tooltip: 'تعليم كمقروء',
                                onPressed: () => _markRead(n),
                                icon: const Icon(Icons.mark_email_read_rounded),
                              ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onMarkRead,
  });

  final AdminNotification item;
  final VoidCallback onMarkRead;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _ReadBadge(isRead: item.isRead),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.body,
            style: const TextStyle(color: kTextPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'النوع: ${item.type} - المستخدم: #${item.userId}',
            style: const TextStyle(color: kTextSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            item.createdAt,
            style: const TextStyle(color: kTextSecondary, fontSize: 12),
          ),
          if (!item.isRead) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onMarkRead,
                icon: const Icon(Icons.mark_email_read_rounded),
                label: const Text('تعليم كمقروء'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadBadge extends StatelessWidget {
  const _ReadBadge({required this.isRead});

  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final color = isRead ? Colors.green : Colors.redAccent;
    final label = isRead ? 'مقروء' : 'جديد';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
