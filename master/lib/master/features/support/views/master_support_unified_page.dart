part of '../../../../master_auth_app.dart';

/// Unified support workspace. The existing conversation widgets remain the
/// source of truth for chat behavior; only the page frame is replaced.
class MasterSupportUnifiedPage extends StatefulWidget {
  const MasterSupportUnifiedPage({
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
  State<MasterSupportUnifiedPage> createState() =>
      _MasterSupportUnifiedPageState();
}

class _MasterSupportUnifiedPageState extends State<MasterSupportUnifiedPage> {
  final TextEditingController _searchController = TextEditingController();
  late Future<_MasterSupportChatsData> _future;
  int? _selectedUserId;

  @override
  void initState() {
    super.initState();
    _rememberMasterRuntime(widget.session, widget.onLogout, widget.api);
    _future = _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<_MasterSupportChatsData> _load() {
    return widget.api._fetchMasterSupportChats(
      widget.session.token,
      query: _searchController.text,
      userId: _selectedUserId,
    );
  }

  void _reload() {
    setState(() => _future = _load());
  }

  void _selectConversation(_SupportConversationData conversation) {
    setState(() {
      _selectedUserId = conversation.userId;
      _future = _load();
    });
  }

  Future<void> _sendText(String message) async {
    final userId = _selectedUserId;
    if (userId == null || userId <= 0) {
      _showMasterSnack(context, 'اختر محادثة أولًا');
      return;
    }
    await widget.api._sendMasterSupportMessage(
      widget.session.token,
      userId: userId,
      message: message,
    );
    _reload();
  }

  Future<void> _sendAudio(html.File file, String message) async {
    final userId = _selectedUserId;
    if (userId == null || userId <= 0) {
      _showMasterSnack(context, 'اختر محادثة أولًا');
      return;
    }
    await widget.api._uploadMasterSupportAudio(
      widget.session.token,
      userId: userId,
      file: file,
      message: message,
    );
    _reload();
  }

  void _openSidebarItem(String itemKey) {
    final key = _masterCanonicalModuleKey(itemKey);
    if (key == 'communication') return;
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
        iconKey: 'communication',
        label: 'مركز التواصل',
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
      statusLabel: 'الدعم الفني متصل',
      platformTitle: 'الدعم الفني',
      platformSubtitle: 'محادثات العملاء ومراقبة التواصل',
      serverNow: widget.serverNow,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _reload,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('تحديث المحادثات'),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: FutureBuilder<_MasterSupportChatsData>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return _SupportErrorView(
                    message:
                        snapshot.error?.toString() ??
                        'تعذر تحميل محادثات الدعم',
                    onRetry: _reload,
                  );
                }
                final data = snapshot.data!;
                if (_selectedUserId == null && data.selectedUserId > 0) {
                  _selectedUserId = data.selectedUserId;
                }
                return _SupportChatsBody(
                  data: data,
                  selectedUserId: _selectedUserId,
                  searchController: _searchController,
                  onSearch: _reload,
                  onConversationSelected: _selectConversation,
                  onSendText: _sendText,
                  onSendAudio: _sendAudio,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
