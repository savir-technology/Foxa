// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

class MasterSupportChatsPage extends StatefulWidget {
  const MasterSupportChatsPage({
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
  State<MasterSupportChatsPage> createState() => _MasterSupportChatsPageState();
}

class _MasterSupportChatsPageState extends State<MasterSupportChatsPage> {
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
    setState(() {
      _future = _load();
    });
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
      _showMasterSnack(context, 'اختر محادثة أولا');
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
      _showMasterSnack(context, 'اختر محادثة أولا');
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

  @override
  Widget build(BuildContext context) {
    _rememberMasterRuntime(widget.session, widget.onLogout, widget.api);
    final serverNow = widget.serverNow ?? DateTime.now();
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
            child: Column(
              children: [
                _SupportTopBar(
                  serverNow: serverNow,
                  onReload: _reload,
                  onBack: () => _navigateToMasterSection(
                    context,
                    key: 'home',
                    session: widget.session,
                    onLogout: widget.onLogout,
                    api: widget.api,
                    serverNow: serverNow,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: FutureBuilder<_MasterSupportChatsData>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.6),
                          ),
                        );
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
          ),
        ),
      ),
    );
  }
}

class _SupportTopBar extends StatelessWidget {
  const _SupportTopBar({
    required this.serverNow,
    required this.onReload,
    required this.onBack,
  });

  final DateTime serverNow;
  final VoidCallback onReload;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          _OrdersSidebarToggleButton(
            tooltip: 'العودة للرئيسية',
            icon: Icons.arrow_back_rounded,
            active: true,
            onTap: onBack,
          ),
          const SizedBox(width: 8),
          _OrdersSidebarToggleButton(
            tooltip: 'تحديث المحادثات',
            icon: Icons.refresh_rounded,
            active: true,
            onTap: onReload,
          ),
          const SizedBox(width: 12),
          _MasterStatusPill(label: 'الدعم الفني متصل بالداتا بيز'),
          const SizedBox(width: 12),
          _MasterDateBlock(serverNow: serverNow),
          const Spacer(),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'الدعم الفني',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E232A),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'محادثات العملاء مع فريق الإدارة والرد النصي أو الصوتي',
                style: TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6F7680),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          const Icon(Icons.support_agent_rounded, color: _kDeepGreen, size: 30),
        ],
      ),
    );
  }
}

class _SupportChatsBody extends StatelessWidget {
  const _SupportChatsBody({
    required this.data,
    required this.selectedUserId,
    required this.searchController,
    required this.onSearch,
    required this.onConversationSelected,
    required this.onSendText,
    required this.onSendAudio,
  });

  final _MasterSupportChatsData data;
  final int? selectedUserId;
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final ValueChanged<_SupportConversationData> onConversationSelected;
  final Future<void> Function(String message) onSendText;
  final Future<void> Function(html.File file, String message) onSendAudio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 980;
        _SupportConversationData? selected;
        for (final item in data.conversations) {
          if (item.userId == (selectedUserId ?? data.selectedUserId)) {
            selected = item;
            break;
          }
        }
        final list = _SupportConversationList(
          conversations: data.conversations,
          selectedUserId: selectedUserId ?? data.selectedUserId,
          searchController: searchController,
          onSearch: onSearch,
          onConversationSelected: onConversationSelected,
        );
        final panel = _SupportConversationPanel(
          conversation: selected,
          messages: data.messages,
          onSendText: onSendText,
          onSendAudio: onSendAudio,
        );
        final info = _SupportStatsPanel(
          stats: data.stats,
          conversation: selected,
        );

        if (compact) {
          return ListView(
            children: [
              SizedBox(height: 290, child: list),
              const SizedBox(height: 8),
              SizedBox(height: 520, child: panel),
              const SizedBox(height: 8),
              SizedBox(height: 220, child: info),
            ],
          );
        }

        return Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 290, child: list),
            const SizedBox(width: 8),
            Expanded(child: panel),
            const SizedBox(width: 8),
            SizedBox(width: 260, child: info),
          ],
        );
      },
    );
  }
}

class _SupportConversationList extends StatelessWidget {
  const _SupportConversationList({
    required this.conversations,
    required this.selectedUserId,
    required this.searchController,
    required this.onSearch,
    required this.onConversationSelected,
  });

  final List<_SupportConversationData> conversations;
  final int selectedUserId;
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final ValueChanged<_SupportConversationData> onConversationSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Text(
                    'محادثات العملاء (${conversations.length})',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E232A),
                    ),
                  ),
                ),
                const Icon(
                  Icons.forum_outlined,
                  size: 17,
                  color: _kPrimaryGreen,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFDFD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE7ECE8)),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: Color(0xFF69727D),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      onSubmitted: (_) => onSearch(),
                      decoration: const InputDecoration(
                        hintText: 'ابحث باسم العميل أو الهاتف...',
                        border: InputBorder.none,
                        isDense: true,
                        hintStyle: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9AA2AD),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: conversations.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد محادثات دعم حتى الآن',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8A919A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: conversations.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      return _SupportConversationItem(
                        conversation: conversation,
                        selected: conversation.userId == selectedUserId,
                        onTap: () => onConversationSelected(conversation),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SupportConversationItem extends StatelessWidget {
  const _SupportConversationItem({
    required this.conversation,
    required this.selected,
    required this.onTap,
  });

  final _SupportConversationData conversation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF1F8F4) : Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? const Color(0xFFD5EADB)
                  : const Color(0xFFE9EEEA),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              _SupportAvatar(conversation: conversation, size: 40),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: Text(
                            conversation.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 11.6,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          conversation.timeLabel,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8A919A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      conversation.customerPhone.isEmpty
                          ? 'عميل #${conversation.userId}'
                          : conversation.customerPhone,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 10.2,
                        color: _kPrimaryGreen,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 9.8,
                        color: Color(0xFF6F7680),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (conversation.unreadForAdmin > 0) ...[
                const SizedBox(width: 7),
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE12D2D),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${conversation.unreadForAdmin}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportAvatar extends StatelessWidget {
  const _SupportAvatar({required this.conversation, required this.size});

  final _SupportConversationData conversation;
  final double size;

  @override
  Widget build(BuildContext context) {
    final imageUrl = conversation.customerImageUrl.trim();
    final fallback = conversation.customerName.trim().isNotEmpty
        ? conversation.customerName.characters.first.toUpperCase()
        : 'A';
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5ED),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD7EBDD)),
      ),
      child: imageUrl.isEmpty
          ? Center(
              child: Text(
                fallback,
                style: TextStyle(
                  fontSize: size * 0.36,
                  fontWeight: FontWeight.w900,
                  color: _kPrimaryGreen,
                ),
              ),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(
                  fallback,
                  style: TextStyle(
                    fontSize: size * 0.36,
                    fontWeight: FontWeight.w900,
                    color: _kPrimaryGreen,
                  ),
                ),
              ),
            ),
    );
  }
}

class _SupportConversationPanel extends StatefulWidget {
  const _SupportConversationPanel({
    required this.conversation,
    required this.messages,
    required this.onSendText,
    required this.onSendAudio,
  });

  final _SupportConversationData? conversation;
  final List<_SupportMessageData> messages;
  final Future<void> Function(String message) onSendText;
  final Future<void> Function(html.File file, String message) onSendAudio;

  @override
  State<_SupportConversationPanel> createState() =>
      _SupportConversationPanelState();
}

class _SupportConversationPanelState extends State<_SupportConversationPanel> {
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _SupportConversationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation?.userId != widget.conversation?.userId) {
      _messageController.clear();
    }
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending || widget.conversation == null) {
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.onSendText(text);
      _messageController.clear();
      if (mounted) {
        _showMasterSnack(context, 'تم إرسال الرد للعميل');
      }
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _pickAudio() async {
    if (_sending || widget.conversation == null) {
      return;
    }
    final input = html.FileUploadInputElement()
      ..accept = 'audio/*'
      ..multiple = false;
    input.click();
    await input.onChange.first;
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) {
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.onSendAudio(file, _messageController.text.trim());
      _messageController.clear();
      if (mounted) {
        _showMasterSnack(context, 'تم إرسال الرسالة الصوتية');
      }
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversation = widget.conversation;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: conversation == null
          ? const Center(
              child: Text(
                'اختر محادثة من القائمة',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8A919A),
                ),
              ),
            )
          : Column(
              children: [
                _SupportPanelHeader(conversation: conversation),
                Expanded(
                  child: widget.messages.isEmpty
                      ? const Center(
                          child: Text(
                            'لا توجد رسائل في هذه المحادثة بعد',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF8A919A),
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(14),
                          children: [
                            for (final message in widget.messages)
                              _SupportMessageBubble(message: message),
                          ],
                        ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFE7ECE8))),
                  ),
                  child: Column(
                    children: [
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              minLines: 1,
                              maxLines: 3,
                              onSubmitted: (_) => _sendText(),
                              decoration: const InputDecoration(
                                hintText: 'اكتب رد الدعم الفني...',
                                border: InputBorder.none,
                                isDense: true,
                                hintStyle: TextStyle(
                                  color: Color(0xFF9AA2AD),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                          _ChatIconButton(
                            icon: Icons.mic_none_rounded,
                            onTap: _pickAudio,
                          ),
                          const SizedBox(width: 6),
                          _ChatIconButton(
                            icon: Icons.sentiment_satisfied_alt_rounded,
                            onTap: () {
                              _messageController.text =
                                  '${_messageController.text} 😊';
                            },
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 42,
                            height: 38,
                            child: ElevatedButton(
                              onPressed: _sending ? null : _sendText,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kPrimaryGreen,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _sending
                                  ? const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded, size: 18),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          _SupportQuickReply(
                            label: 'تم الاستلام',
                            onTap: () => _messageController.text =
                                'تم استلام رسالتك وسنراجعها الآن.',
                          ),
                          const SizedBox(width: 6),
                          _SupportQuickReply(
                            label: 'قيد المتابعة',
                            onTap: () => _messageController.text =
                                'طلبك قيد المتابعة من فريق الدعم الفني.',
                          ),
                          const SizedBox(width: 6),
                          _SupportQuickReply(
                            label: 'شكرا',
                            onTap: () =>
                                _messageController.text = 'شكرا لتواصلك معنا.',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _SupportPanelHeader extends StatelessWidget {
  const _SupportPanelHeader({required this.conversation});

  final _SupportConversationData conversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7ECE8))),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _SupportAvatar(conversation: conversation, size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E232A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  conversation.customerPhone.isEmpty
                      ? 'عميل #${conversation.userId}'
                      : conversation.customerPhone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6F7680),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'الدعم الفني',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: _kPrimaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportMessageBubble extends StatelessWidget {
  const _SupportMessageBubble({required this.message});

  final _SupportMessageData message;

  @override
  Widget build(BuildContext context) {
    final outgoing = message.outgoing;
    final audioUrl = message.audioUrl.trim();
    return Align(
      alignment: outgoing ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: outgoing ? const Color(0xFFEAF5ED) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: outgoing ? const Color(0xFFD5EADB) : const Color(0xFFE7ECE8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.text.trim().isNotEmpty)
              Text(
                message.text,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F252B),
                  height: 1.45,
                ),
              ),
            if (audioUrl.isNotEmpty) ...[
              if (message.text.trim().isNotEmpty) const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => html.window.open(audioUrl, '_blank'),
                icon: const Icon(Icons.play_arrow_rounded, size: 17),
                label: const Text('تشغيل الرسالة الصوتية'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimaryGreen,
                  side: const BorderSide(color: Color(0xFFD8EBDD)),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${message.senderName} · ${message.timeLabel}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8A919A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportQuickReply extends StatelessWidget {
  const _SupportQuickReply({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8F7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE1E7E2)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: _kPrimaryGreen,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SupportStatsPanel extends StatelessWidget {
  const _SupportStatsPanel({required this.stats, required this.conversation});

  final _SupportStatsData stats;
  final _SupportConversationData? conversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ملخص الدعم',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E232A),
            ),
          ),
          const SizedBox(height: 10),
          _SupportMetric(
            label: 'كل المحادثات',
            value: '${stats.totalConversations}',
          ),
          _SupportMetric(
            label: 'غير المقروء',
            value: '${stats.unreadMessages}',
          ),
          _SupportMetric(label: 'رسائل اليوم', value: '${stats.todayMessages}'),
          const Spacer(),
          if (conversation != null) ...[
            const Divider(color: Color(0xFFE7ECE8)),
            _SupportMetric(
              label: 'رسائل العميل',
              value: '${conversation!.totalMessages}',
            ),
            _SupportMetric(
              label: 'آخر تفاعل',
              value: conversation!.relativeLabel,
            ),
          ],
        ],
      ),
    );
  }
}

class _SupportMetric extends StatelessWidget {
  const _SupportMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6F7680),
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E232A),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportErrorView extends StatelessWidget {
  const _SupportErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE7ECE8)),
        ),
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
              'تعذر تحميل الدعم الفني',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF6F7680)),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 17),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MasterSupportChatsData {
  const _MasterSupportChatsData({
    required this.serverNow,
    required this.selectedUserId,
    required this.stats,
    required this.conversations,
    required this.messages,
  });

  final DateTime? serverNow;
  final int selectedUserId;
  final _SupportStatsData stats;
  final List<_SupportConversationData> conversations;
  final List<_SupportMessageData> messages;

  factory _MasterSupportChatsData.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data'] ?? json);
    return _MasterSupportChatsData(
      serverNow: _parseDateTime(data['server_now']),
      selectedUserId: _toInt(data['selected_user_id']),
      stats: _SupportStatsData.fromJson(_asMap(data['stats'])),
      conversations: _asMapList(
        data['conversations'],
      ).map(_SupportConversationData.fromJson).toList(),
      messages: _asMapList(
        data['messages'],
      ).map(_SupportMessageData.fromJson).toList(),
    );
  }
}

class _SupportStatsData {
  const _SupportStatsData({
    required this.totalConversations,
    required this.visibleConversations,
    required this.unreadMessages,
    required this.todayMessages,
  });

  final int totalConversations;
  final int visibleConversations;
  final int unreadMessages;
  final int todayMessages;

  factory _SupportStatsData.fromJson(Map<String, dynamic> json) {
    return _SupportStatsData(
      totalConversations: _toInt(json['total_conversations']),
      visibleConversations: _toInt(json['visible_conversations']),
      unreadMessages: _toInt(json['unread_messages']),
      todayMessages: _toInt(json['today_messages']),
    );
  }
}

class _SupportConversationData {
  const _SupportConversationData({
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.customerImageUrl,
    required this.lastMessage,
    required this.lastSenderType,
    required this.timeLabel,
    required this.relativeLabel,
    required this.totalMessages,
    required this.unreadForAdmin,
  });

  final int userId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String customerImageUrl;
  final String lastMessage;
  final String lastSenderType;
  final String timeLabel;
  final String relativeLabel;
  final int totalMessages;
  final int unreadForAdmin;

  factory _SupportConversationData.fromJson(Map<String, dynamic> json) {
    return _SupportConversationData(
      userId: _toInt(json['user_id']),
      customerName: (json['customer_name'] ?? '').toString(),
      customerPhone: (json['customer_phone'] ?? '').toString(),
      customerEmail: (json['customer_email'] ?? '').toString(),
      customerImageUrl: (json['customer_image_url'] ?? '').toString(),
      lastMessage: (json['last_message'] ?? '').toString(),
      lastSenderType: (json['last_sender_type'] ?? '').toString(),
      timeLabel: (json['time_label'] ?? '').toString(),
      relativeLabel: (json['relative_label'] ?? '').toString(),
      totalMessages: _toInt(json['total_messages']),
      unreadForAdmin: _toInt(json['unread_for_admin']),
    );
  }
}

class _SupportMessageData {
  const _SupportMessageData({
    required this.id,
    required this.userId,
    required this.senderType,
    required this.senderName,
    required this.text,
    required this.audioUrl,
    required this.timeLabel,
  });

  final int id;
  final int userId;
  final String senderType;
  final String senderName;
  final String text;
  final String audioUrl;
  final String timeLabel;

  bool get outgoing => senderType == 'admin' || senderType == 'support';

  factory _SupportMessageData.fromJson(Map<String, dynamic> json) {
    return _SupportMessageData(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      senderType: (json['sender_type'] ?? '').toString().toLowerCase(),
      senderName: (json['sender_name'] ?? '').toString(),
      text: (json['message'] ?? '').toString(),
      audioUrl: (json['audio_url'] ?? '').toString(),
      timeLabel: (json['time_label'] ?? '').toString(),
    );
  }
}
