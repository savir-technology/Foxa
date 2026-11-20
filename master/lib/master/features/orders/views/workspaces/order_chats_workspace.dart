// ignore_for_file: unused_element

part of '../../../../../master_auth_app.dart';

class _OrderChatsWorkspace extends StatelessWidget {
  const _OrderChatsWorkspace({
    required this.data,
    required this.serverNow,
    required this.onReload,
    required this.searchController,
    required this.statusFilter,
    required this.chatStateFilter,
    required this.onSearchSubmitted,
    required this.onStatusChanged,
    required this.onChatStateChanged,
    required this.selectedOrderId,
    required this.onConversationSelected,
    required this.onSendAdminMessage,
    required this.onSendAdminMedia,
    required this.onNotifyCustomer,
    required this.onCancelOrder,
    required this.showNavigationSidebar,
    required this.onToggleNavigationSidebar,
  });

  final _MasterOrderChatsData data;
  final DateTime serverNow;
  final VoidCallback onReload;
  final TextEditingController searchController;
  final String statusFilter;
  final String chatStateFilter;
  final VoidCallback onSearchSubmitted;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onChatStateChanged;
  final int? selectedOrderId;
  final ValueChanged<_OrderChatConversationData> onConversationSelected;
  final Future<void> Function(String message) onSendAdminMessage;
  final Future<void> Function(html.File file, String message) onSendAdminMedia;
  final Future<void> Function(_OrderChatConversationData order)
  onNotifyCustomer;
  final Future<void> Function(_OrderChatConversationData order) onCancelOrder;
  final bool showNavigationSidebar;
  final VoidCallback onToggleNavigationSidebar;

  @override
  Widget build(BuildContext context) {
    final selectedOrder =
        data.selectedOrder ??
        (data.conversations.isEmpty ? null : data.conversations.first);
    return Column(
      children: [
        _OrdersHeaderBar(
          serverNow: serverNow,
          onReload: onReload,
          showInsightsSidebar: true,
          showNavigationSidebar: showNavigationSidebar,
          onToggleInsightsSidebar: () {},
          onToggleNavigationSidebar: onToggleNavigationSidebar,
          title: 'دردشات الطلبات المرتبطة',
          subtitle: 'التواصل مع العملاء والمطاعم والسائقين لجميع الطلبات',
          icon: Icons.chat_bubble_outline_rounded,
        ),
        const SizedBox(height: 8),
        _OrdersStatsStrip(cards: _orderChatsStats(data)),
        const SizedBox(height: 8),
        _OrderChatsToolbar(
          onReload: onReload,
          searchController: searchController,
          statusFilter: statusFilter,
          chatStateFilter: chatStateFilter,
          onSearchSubmitted: onSearchSubmitted,
          onStatusChanged: onStatusChanged,
          onChatStateChanged: onChatStateChanged,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 255,
                child: _OrderChatsListPanel(
                  data: data,
                  selectedOrderId: selectedOrder?.orderId ?? selectedOrderId,
                  onConversationSelected: onConversationSelected,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OrderChatConversationPanel(
                  order: selectedOrder,
                  messages: data.messages,
                  onSendAdminMessage: onSendAdminMessage,
                  onSendAdminMedia: onSendAdminMedia,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 245,
                child: _OrderChatInfoPanel(
                  order: selectedOrder,
                  onNotifyCustomer: onNotifyCustomer,
                  onCancelOrder: onCancelOrder,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrderChatsToolbar extends StatelessWidget {
  const _OrderChatsToolbar({
    required this.onReload,
    required this.searchController,
    required this.statusFilter,
    required this.chatStateFilter,
    required this.onSearchSubmitted,
    required this.onStatusChanged,
    required this.onChatStateChanged,
  });

  final VoidCallback onReload;
  final TextEditingController searchController;
  final String statusFilter;
  final String chatStateFilter;
  final VoidCallback onSearchSubmitted;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onChatStateChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7ECE8)),
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                const Icon(Icons.search_rounded, color: Color(0xFF69727D)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    onSubmitted: (_) => onSearchSubmitted(),
                    decoration: const InputDecoration(
                      hintText:
                          'ابحث برقم الطلب أو اسم العميل أو رقم الهاتف...',
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
        const SizedBox(width: 8),
        _OrdersFilterButton(
          label: 'اليوم',
          options: const {'today': 'اليوم', 'week': 'هذا الأسبوع'},
          onChanged: (_) => onReload(),
        ),
        const SizedBox(width: 8),
        _OrdersFilterButton(
          label: 'كل الطلبات',
          options: const {'all': 'كل الطلبات', 'active': 'النشطة'},
          onChanged: (_) => onReload(),
        ),
        const SizedBox(width: 8),
        _OrdersFilterButton(
          label: _ordersFilterLabel(statusFilter, _ordersStatusFilterOptions),
          options: _ordersStatusFilterOptions,
          onChanged: onStatusChanged,
        ),
        const SizedBox(width: 8),
        _OrdersFilterButton(
          label: _ordersFilterLabel(chatStateFilter, const {
            'all': 'كل المحادثات',
            'unread': 'غير مقروء',
            'critical': 'حرجة',
            'with_driver': 'مع سائق',
          }),
          options: const {
            'all': 'كل المحادثات',
            'unread': 'غير مقروء',
            'critical': 'حرجة',
            'with_driver': 'مع سائق',
          },
          onChanged: onChatStateChanged,
        ),
        const SizedBox(width: 8),
        _OrdersFilterButton(
          label: 'كل المطاعم',
          options: const {'all': 'كل المطاعم'},
          onChanged: (_) => onReload(),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            onPressed: () => _showChatAdvancedFiltersSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimaryGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            icon: const Icon(Icons.filter_alt_outlined, size: 16),
            label: const Text(
              'فلترة متقدمة',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderChatsListPanel extends StatelessWidget {
  const _OrderChatsListPanel({
    required this.data,
    required this.selectedOrderId,
    required this.onConversationSelected,
  });

  final _MasterOrderChatsData data;
  final int? selectedOrderId;
  final ValueChanged<_OrderChatConversationData> onConversationSelected;

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
                    'المحادثات (${data.total})',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12.8,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E232A),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: _kPrimaryGreen,
                ),
              ],
            ),
          ),
          Expanded(
            child: data.conversations.isEmpty
                ? const Center(
                    child: Text(
                      'لا توجد محادثات مرتبطة بالطلبات الآن',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8A919A),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: data.conversations.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final order = data.conversations[index];
                      return _OrderChatListItem(
                        order: order,
                        selected: order.orderId == selectedOrderId,
                        onTap: () => onConversationSelected(order),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: OutlinedButton(
              onPressed: () => _showMasterSnack(
                context,
                'تم تحميل المحادثات المتاحة من الطلبات',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(34),
                foregroundColor: _kPrimaryGreen,
                side: const BorderSide(color: Color(0xFFE1E7E2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
              child: const Text(
                'عرض المزيد',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderChatAvatar extends StatelessWidget {
  const _OrderChatAvatar({required this.order, required this.size});

  final _OrderChatConversationData order;
  final double size;

  @override
  Widget build(BuildContext context) {
    final logoUrl = order.restaurantLogoUrl.trim();
    final fallback =
        (order.customer.trim().isNotEmpty
                ? order.customer.trim()
                : order.restaurant.trim().isNotEmpty
                ? order.restaurant.trim()
                : 'A')
            .characters
            .first
            .toUpperCase();
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5ED),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD7EBDD)),
      ),
      child: logoUrl.isEmpty
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
              logoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Text(
                    fallback,
                    style: TextStyle(
                      fontSize: size * 0.36,
                      fontWeight: FontWeight.w900,
                      color: _kPrimaryGreen,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _OrderChatListItem extends StatelessWidget {
  const _OrderChatListItem({
    required this.order,
    required this.selected,
    required this.onTap,
  });

  final _OrderChatConversationData order;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = _chatStateForOrder(order);
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
              _OrderChatAvatar(order: order, size: 38),
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
                            order.customer.isEmpty
                                ? order.restaurant
                                : order.customer,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.4,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          order.timeLabel,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8A919A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Expanded(
                          child: Text(
                            order.orderNo,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 10.5,
                              color: _kPrimaryGreen,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: state.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _chatPreviewForOrder(order),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9.8,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6F7680),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.badge > 0) ...[
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
                    '${state.badge}',
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

class _OrderChatConversationPanel extends StatefulWidget {
  const _OrderChatConversationPanel({
    required this.order,
    required this.messages,
    required this.onSendAdminMessage,
    required this.onSendAdminMedia,
  });

  final _OrderChatConversationData? order;
  final List<_OrderChatMessageData> messages;
  final Future<void> Function(String message) onSendAdminMessage;
  final Future<void> Function(html.File file, String message) onSendAdminMedia;

  @override
  State<_OrderChatConversationPanel> createState() =>
      _OrderChatConversationPanelState();
}

class _OrderChatConversationPanelState
    extends State<_OrderChatConversationPanel> {
  final TextEditingController _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _OrderChatConversationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order?.orderId != oldWidget.order?.orderId) {
      _messageController.clear();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    setState(() {
      _sending = true;
    });
    try {
      await widget.onSendAdminMessage(text);
      _messageController.clear();
      if (mounted) {
        _showMasterSnack(context, 'تم إرسال رسالة الأدمن وحفظها في المحادثة');
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

  Future<void> _pickAndSendMedia(String accept) async {
    if (_sending || widget.order == null) {
      return;
    }
    final input = html.FileUploadInputElement()
      ..accept = accept
      ..multiple = false;
    input.click();
    await input.onChange.first;
    final file = input.files?.isNotEmpty == true ? input.files!.first : null;
    if (file == null) {
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.onSendAdminMedia(file, _messageController.text.trim());
      _messageController.clear();
      if (mounted) {
        _showMasterSnack(context, 'تم رفع المرفق وحفظه في المحادثة');
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
    final order = widget.order;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: order == null
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
                _OrderChatPanelHeader(order: order),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F6F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'اليوم',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6F7680),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final message in widget.messages)
                        _OrderChatBubble(message: message),
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
                              maxLines: 2,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: const InputDecoration(
                                hintText: 'اكتب رسالة...',
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
                            icon: Icons.attach_file_rounded,
                            onTap: () => _pickAndSendMedia(
                              'image/*,application/pdf,audio/*',
                            ),
                          ),
                          const SizedBox(width: 6),
                          _ChatIconButton(
                            icon: Icons.image_outlined,
                            onTap: () => _pickAndSendMedia('image/*'),
                          ),
                          const SizedBox(width: 6),
                          _ChatIconButton(
                            icon: Icons.sentiment_satisfied_alt_rounded,
                            onTap: () => _messageController.text += ' شكرا',
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 42,
                            height: 38,
                            child: ElevatedButton(
                              onPressed: _sending ? null : _sendMessage,
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
                      const SizedBox(height: 8),
                      Container(
                        height: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFAEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE8B4)),
                        ),
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: const [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: Color(0xFFF59E0B),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'يمكنك استخدام الرسائل الجاهزة للرد بسرعة على العملاء',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF9A6500),
                                ),
                              ),
                            ),
                            Text(
                              'الرسائل الجاهزة',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF9A6500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _OrderChatPanelHeader extends StatelessWidget {
  const _OrderChatPanelHeader({required this.order});

  final _OrderChatConversationData order;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7ECE8))),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          _OrderChatAvatar(order: order, size: 38),
          const SizedBox(width: 8),
          Expanded(
            child: _OrdersTwoLine(
              title: order.customer.isEmpty ? order.restaurant : order.customer,
              subtitle: order.phone,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD7EBDD)),
            ),
            child: Text(
              order.orderNo,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: _kPrimaryGreen,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'إجراءات المحادثة',
            onPressed: () => _showOrderChatDetailsSheet(context, order),
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
    );
  }
}

class _OrderChatBubble extends StatelessWidget {
  const _OrderChatBubble({required this.message});

  final _OrderChatMessageData message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.outgoing
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final color = message.outgoing ? const Color(0xFFEAF5ED) : Colors.white;
    final borderColor = message.outgoing
        ? const Color(0xFFD5EADB)
        : const Color(0xFFE7ECE8);
    final attachmentUrl = message.audioUrl.trim();
    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.text.trim().isNotEmpty)
              Text(
                message.text,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 11.3,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E232A),
                ),
              ),
            if (attachmentUrl.isNotEmpty) ...[
              if (message.text.trim().isNotEmpty) const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => html.window.open(attachmentUrl, '_blank'),
                  icon: const Icon(Icons.attach_file_rounded, size: 15),
                  label: const Text('فتح المرفق'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: _kPrimaryGreen,
                    side: const BorderSide(color: Color(0xFFD7EBDD)),
                    textStyle: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              '${message.sender} · ${message.time}',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A919A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderChatInfoPanel extends StatelessWidget {
  const _OrderChatInfoPanel({
    required this.order,
    required this.onNotifyCustomer,
    required this.onCancelOrder,
  });

  final _OrderChatConversationData? order;
  final Future<void> Function(_OrderChatConversationData order)
  onNotifyCustomer;
  final Future<void> Function(_OrderChatConversationData order) onCancelOrder;

  @override
  Widget build(BuildContext context) {
    final activeOrder = order;
    if (activeOrder == null) {
      return const _OrdersSideCard(
        title: 'معلومات الطلب',
        children: [
          Text(
            'اختر محادثة لعرض تفاصيل الطلب',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF8A919A)),
          ),
        ],
      );
    }
    return ListView(
      children: [
        _OrdersSideCard(
          title: 'معلومات الطلب',
          children: [
            _OrdersMetricLine(label: 'رقم الطلب', value: activeOrder.orderNo),
            _OrdersMetricLine(
              label: 'حالة الطلب',
              value: activeOrder.statusLabel,
            ),
            _OrdersMetricLine(label: 'نوع الطلب', value: activeOrder.typeLabel),
            _OrdersMetricLine(label: 'وقت الطلب', value: activeOrder.timeLabel),
            _OrdersMetricLine(label: 'المطعم', value: activeOrder.restaurant),
            _OrdersMetricLine(label: 'المبلغ', value: activeOrder.amountLabel),
            _OrdersMetricLine(
              label: 'طريقة الدفع',
              value: activeOrder.paymentLabel,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _OrdersSideCard(
          title: 'إجراءات سريعة',
          children: [
            _OrderChatQuickAction(
              icon: Icons.visibility_outlined,
              label: 'عرض تفاصيل الطلب',
              onTap: () => _showOrderChatDetailsSheet(context, activeOrder),
            ),
            _OrderChatQuickAction(
              icon: Icons.route_outlined,
              label: 'تتبع الطلب مباشر',
              onTap: () => _showMasterSnack(
                context,
                'التتبع المباشر متاح من صفحة التتبع داخل لوحة العمليات',
              ),
            ),
            _OrderChatQuickAction(
              icon: Icons.phone_outlined,
              label: 'اتصال بالعميل',
              onTap: () {
                if (activeOrder.phone.trim().isEmpty) {
                  _showMasterSnack(context, 'لا يوجد رقم هاتف مسجل لهذا الطلب');
                  return;
                }
                html.window.open('tel:${activeOrder.phone}', '_self');
              },
            ),
            _OrderChatQuickAction(
              icon: Icons.delivery_dining_outlined,
              label: 'اتصال بالسائق',
              onTap: () {
                if (activeOrder.driverPhone.trim().isEmpty) {
                  _showMasterSnack(context, 'لا يوجد رقم سائق مسجل لهذا الطلب');
                  return;
                }
                html.window.open('tel:${activeOrder.driverPhone}', '_self');
              },
            ),
            _OrderChatQuickAction(
              icon: Icons.notifications_none_rounded,
              label: 'إرسال إشعار للعميل',
              onTap: () => onNotifyCustomer(activeOrder),
            ),
            _OrderChatQuickAction(
              icon: Icons.cancel_outlined,
              label: 'إلغاء الطلب',
              destructive: true,
              onTap: () => onCancelOrder(activeOrder),
            ),
          ],
        ),
      ],
    );
  }
}

class _OrderChatQuickAction extends StatelessWidget {
  const _OrderChatQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFD92C2C)
        : const Color(0xFF4E5660);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label, overflow: TextOverflow.ellipsis),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          alignment: Alignment.centerRight,
          minimumSize: const Size.fromHeight(34),
          textStyle: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
          ),
          side: BorderSide(
            color: destructive
                ? const Color(0xFFF8DADA)
                : const Color(0xFFE7ECE8),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

class _ChatIconButton extends StatelessWidget {
  const _ChatIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: const Color(0xFF4E5660),
          side: const BorderSide(color: Color(0xFFE7ECE8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _OrderChatMessageData {
  const _OrderChatMessageData({
    required this.text,
    required this.time,
    required this.outgoing,
    required this.sender,
    required this.senderRole,
    required this.audioUrl,
  });

  final String text;
  final String time;
  final bool outgoing;
  final String sender;
  final String senderRole;
  final String audioUrl;

  factory _OrderChatMessageData.fromJson(Map<String, dynamic> json) {
    final role = (json['sender_role'] ?? '').toString().toLowerCase();
    return _OrderChatMessageData(
      text: (json['message'] ?? '').toString(),
      time: (json['time_label'] ?? '').toString(),
      outgoing: role == 'user' || role == 'admin' || role == 'support',
      sender: (json['sender_name'] ?? _chatSenderRoleLabel(role)).toString(),
      senderRole: role,
      audioUrl: (json['audio_url'] ?? '').toString(),
    );
  }
}

class _OrderChatStateData {
  const _OrderChatStateData({
    required this.color,
    required this.badge,
    required this.label,
  });

  final Color color;
  final int badge;
  final String label;
}

List<_OperationsStatCardData> _orderChatsStats(_MasterOrderChatsData data) {
  final stats = data.stats;
  return [
    _chatStat(
      title: 'تقييم المحادثات',
      value: stats.rating.toStringAsFixed(1),
      icon: Icons.stars_rounded,
      color: const Color(0xFF2563EB),
      caption: 'رضا العملاء',
    ),
    _chatStat(
      title: 'محادثات حرجة',
      value: '${stats.critical}',
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFD92C2C),
      positive: false,
      caption: 'عن أمس',
    ),
    _chatStat(
      title: 'تم حلها اليوم',
      value: '${stats.resolvedToday}',
      icon: Icons.check_circle_outline_rounded,
      color: const Color(0xFF7C3AED),
      caption: 'اليوم',
    ),
    _chatStat(
      title: 'بانتظار الرد',
      value: '${stats.waiting}',
      icon: Icons.schedule_rounded,
      color: const Color(0xFFF59E0B),
      caption: 'محادثة',
    ),
    _chatStat(
      title: 'محادثات مفتوحة',
      value: '${stats.open}',
      icon: Icons.mark_chat_unread_outlined,
      color: _kPrimaryGreen,
      caption: 'نشطة',
    ),
    _chatStat(
      title: 'إجمالي المحادثات',
      value: '${stats.total}',
      icon: Icons.groups_2_outlined,
      color: const Color(0xFF7C3AED),
      caption: 'عن أمس',
    ),
  ];
}

_OperationsStatCardData _chatStat({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  required String caption,
  bool positive = true,
}) {
  return _OperationsStatCardData(
    title: title,
    value: value,
    icon: icon,
    accent: color,
    background: color.withValues(alpha: 0.11),
    detailLine: caption,
    trendLabel: positive ? '↑' : '↓',
    trendCaption: caption,
    trendPositive: positive,
  );
}

bool _isClosedChatOrder(_OrderChatConversationData order) {
  return _containsAny(order.statusLabel, const [
        'مكتمل',
        'تم التسليم',
        'ملغ',
        'مرفوض',
      ]) ||
      _containsAny(order.statusLabel, const [
        'complete',
        'delivered',
        'cancel',
        'reject',
      ]);
}

bool _containsAny(String value, List<String> needles) {
  final lower = value.toLowerCase();
  return needles.any((needle) => lower.contains(needle.toLowerCase()));
}

String _chatPreviewForOrder(_OrderChatConversationData order) {
  return order.lastMessage.trim().isEmpty
      ? 'لا توجد رسائل بعد'
      : '${order.lastSenderLabel}: ${order.lastMessage}';
}

_OrderChatStateData _chatStateForOrder(_OrderChatConversationData order) {
  if (order.critical) {
    return _OrderChatStateData(
      color: Color(0xFFD92C2C),
      badge: order.unreadForAdmin,
      label: 'حرجة',
    );
  }
  if (order.unreadForAdmin > 0) {
    return _OrderChatStateData(
      color: Color(0xFFF59E0B),
      badge: order.unreadForAdmin,
      label: 'بانتظار الرد',
    );
  }
  return const _OrderChatStateData(
    color: _kPrimaryGreen,
    badge: 0,
    label: 'مفتوحة',
  );
}

String _chatSenderRoleLabel(String role) {
  if (role == 'driver') {
    return 'السائق';
  }
  if (role == 'admin' || role == 'support') {
    return 'الدعم';
  }
  return 'العميل';
}

void _showOrderChatDetailsSheet(
  BuildContext context,
  _OrderChatConversationData order,
) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تفاصيل محادثة ${order.orderNo}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _OrdersMetricLine(label: 'العميل', value: order.customer),
            _OrdersMetricLine(label: 'السائق', value: order.driverName),
            _OrdersMetricLine(label: 'المطعم', value: order.restaurant),
            _OrdersMetricLine(label: 'الحالة', value: order.statusLabel),
            _OrdersMetricLine(
              label: 'الرسائل',
              value: '${order.totalMessages}',
            ),
            _OrdersMetricLine(
              label: 'غير مقروء',
              value: '${order.unreadForAdmin}',
            ),
          ],
        ),
      );
    },
  );
}

void _showChatAdvancedFiltersSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'فلترة المحادثات المتقدمة',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const Text(
              'الفلاتر الحالية تعمل على بيانات الطلبات من الباك اند. عند إضافة API مخصص للمحادثات سيتم تفعيل القنوات والتقييمات مباشرة.',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6F7680),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimaryGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('تم'),
            ),
          ],
        ),
      );
    },
  );
}
