part of '../../../../master_auth_app.dart';

class MasterNotificationsPage extends StatefulWidget {
  const MasterNotificationsPage({
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
  State<MasterNotificationsPage> createState() =>
      _MasterNotificationsPageState();
}

class _MasterNotificationsPageState extends State<MasterNotificationsPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api._fetchMasterNotificationsRaw(widget.session.token);
  }

  void _reload() {
    setState(() {
      _future = widget.api._fetchMasterNotificationsRaw(widget.session.token);
    });
  }

  Future<void> _markAll() async {
    await widget.api._markAllMasterNotificationsRead(widget.session.token);
    if (mounted) _reload();
  }

  Future<void> _markOne(int id) async {
    await widget.api._markMasterNotificationRead(widget.session.token, id);
    if (mounted) _reload();
  }

  Future<void> _send() async {
    final title = TextEditingController();
    final body = TextEditingController();
    var audience = 'approved_users';
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إرسال إشعار جماعي'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'عنوان الإشعار'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: body,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'نص الإشعار'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: audience,
                  decoration: const InputDecoration(labelText: 'الجمهور'),
                  items: const [
                    DropdownMenuItem(
                      value: 'approved_users',
                      child: Text('كل العملاء المعتمدين'),
                    ),
                    DropdownMenuItem(
                      value: 'recent_buyers',
                      child: Text('العملاء الذين اشتروا مؤخرًا'),
                    ),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => audience = value ?? audience),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('إرسال'),
            ),
          ],
        ),
      ),
    );
    if (result != true ||
        title.text.trim().isEmpty ||
        body.text.trim().isEmpty) {
      title.dispose();
      body.dispose();
      return;
    }
    try {
      await widget.api._sendMasterBroadcast(
        widget.session.token,
        audience: audience,
        title: title.text,
        body: body.text,
      );
      if (mounted) {
        _showMasterSnack(context, 'تم إرسال الإشعار بنجاح');
        _reload();
      }
    } catch (error) {
      if (mounted) _showMasterSnack(context, error.toString());
    }
    title.dispose();
    body.dispose();
  }

  void _openSidebarItem(String itemKey) {
    final key = _masterCanonicalModuleKey(itemKey);
    if (key == 'home') return;
    _navigateToMasterSection(
      context,
      key: key,
      session: widget.session,
      onLogout: widget.onLogout,
      api: widget.api,
      serverNow: widget.serverNow,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sidebarItems = _masterFilterSidebarItems(widget.session, const [
      _DashboardMenuItemData(
        iconKey: 'notifications',
        label: 'مركز الإشعارات',
        selected: true,
      ),
    ]);
    return _buildMasterUnifiedShell(
      context: context,
      session: widget.session,
      onLogout: widget.onLogout,
      api: widget.api,
      sidebarItems: sidebarItems,
      onSidebarItemTap: _openSidebarItem,
      statusLabel: 'مركز الإشعارات',
      platformTitle: 'مركز الإشعارات',
      platformSubtitle: 'إدارة إشعارات المنصة',
      serverNow: widget.serverNow,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _markAll,
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('تحديد الكل كمقروء'),
                ),
                FilledButton.icon(
                  onPressed: _send,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('إرسال إشعار'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('تعذر تحميل الإشعارات'),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _reload,
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                }
                final json = snapshot.data ?? const <String, dynamic>{};
                final rows = (json['data'] is List)
                    ? (json['data'] as List).map((e) => _asMap(e)).toList()
                    : <Map<String, dynamic>>[];
                final summary = _asMap(json['summary']);
                return Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'غير مقروء: ${_toInt(summary['unread_count'])}  •  الإجمالي: ${rows.length}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: rows.isEmpty
                          ? const Center(child: Text('لا توجد إشعارات'))
                          : ListView.separated(
                              itemCount: rows.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final row = rows[index];
                                final unread =
                                    _toInt(row['notification_is_read']) == 0;
                                return Card(
                                  child: ListTile(
                                    leading: Icon(
                                      unread
                                          ? Icons.notifications_active_rounded
                                          : Icons.notifications_none_rounded,
                                      color: unread
                                          ? _kPrimaryGreen
                                          : Colors.grey,
                                    ),
                                    title: Text(
                                      (row['notification_title'] ?? 'إشعار')
                                          .toString(),
                                      style: TextStyle(
                                        fontWeight: unread
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      (row['notification_body'] ?? '')
                                          .toString(),
                                    ),
                                    trailing: unread
                                        ? TextButton(
                                            onPressed: () => _markOne(
                                              _toInt(row['notification_id']),
                                            ),
                                            child: const Text('تمت القراءة'),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
