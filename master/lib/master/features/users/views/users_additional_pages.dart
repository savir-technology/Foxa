// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

String _usersPageTitle(String key) {
  switch (key) {
    case 'wallets':
      return 'المحافظ';
    case 'addresses':
      return 'العناوين المحفوظة';
    case 'recipients':
      return 'المستلمون المحفوظون';
    case 'favorites':
      return 'المفضلات';
    case 'orders':
      return 'سجل الطلبات';
    case 'users':
    default:
      return 'المستخدمون';
  }
}

String _usersPageSubtitle(String key) {
  switch (key) {
    case 'wallets':
      return 'إدارة جميع محافظ العملاء في المنصة';
    case 'addresses':
      return 'إدارة جميع العناوين المحفوظة للمستخدمين';
    case 'recipients':
      return 'إدارة جميع المستلمين المحفوظين لدى المستخدمين';
    case 'favorites':
      return 'عرض الأصناف والمطاعم المفضلة لدى العملاء';
    case 'orders':
      return 'مراجعة الطلبات المرتبطة بالمستخدمين';
    case 'users':
    default:
      return 'إدارة جميع العملاء والمستخدمين في المنصة';
  }
}

IconData _usersPageIcon(String key) {
  switch (key) {
    case 'wallets':
      return Icons.account_balance_wallet_outlined;
    case 'addresses':
      return Icons.location_on_outlined;
    case 'recipients':
      return Icons.person_pin_circle_outlined;
    case 'favorites':
      return Icons.favorite_border_rounded;
    case 'orders':
      return Icons.receipt_long_outlined;
    case 'users':
    default:
      return Icons.people_alt_outlined;
  }
}

String _usersPrimaryActionText(String key) {
  switch (key) {
    case 'wallets':
      return 'إضافة محفظة';
    case 'addresses':
      return 'إضافة عنوان جديد';
    case 'recipients':
      return 'تحديث البيانات';
    case 'favorites':
      return 'تحديث البيانات';
    case 'orders':
      return 'تحديث الطلبات';
    case 'users':
    default:
      return 'إضافة مستخدم';
  }
}

String _usersPrimaryActionLabel(String key) {
  switch (key) {
    case 'wallets':
      return 'سيتم إنشاء المحفظة عند تنفيذ أول عملية مالية';
    case 'addresses':
      return 'استخدم زر إضافة عنوان جديد';
    case 'recipients':
      return 'سيتم توفير الإضافة بعد ربط نموذج المستلم';
    case 'favorites':
      return 'المفضلة للعرض فقط حالياً';
    case 'orders':
      return 'يتم تحديث سجل الطلبات من قاعدة البيانات';
    case 'users':
    default:
      return 'إضافة مستخدم';
  }
}

String _usersSearchHint(String key) {
  switch (key) {
    case 'wallets':
      return 'ابحث برقم المحفظة أو اسم المستخدم...';
    case 'addresses':
      return 'ابحث عن عنوان أو مستخدم...';
    case 'recipients':
      return 'ابحث عن اسم مستلم أو هاتف...';
    case 'favorites':
      return 'ابحث عن صنف أو مطعم مفضل...';
    case 'orders':
      return 'ابحث عن طلب مرتبط بالمستخدم...';
    case 'users':
    default:
      return 'ابحث بالاسم أو رقم هاتف أو بريد إلكتروني...';
  }
}

class _FavoriteRecord {
  const _FavoriteRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.itemId,
    required this.itemName,
    required this.itemImage,
    required this.price,
    required this.active,
  });

  final int id;
  final int userId;
  final String userName;
  final String userPhone;
  final int itemId;
  final String itemName;
  final String itemImage;
  final String price;
  final bool active;

  factory _FavoriteRecord.fromJson(Map<String, dynamic> json) {
    return _FavoriteRecord(
      id: _toInt(json['favorite_id']),
      userId: _toInt(json['user_id']),
      userName: _normalizeUtf8Text(json['user_name']?.toString() ?? ''),
      userPhone: _normalizeUtf8Text(json['user_phone']?.toString() ?? ''),
      itemId: _toInt(json['item_id']),
      itemName: _normalizeUtf8Text(json['item_name']?.toString() ?? ''),
      itemImage: _favoriteImageUrl(json['item_image']),
      price: _normalizeUtf8Text(json['price']?.toString() ?? ''),
      active: json['active'] == true || _toInt(json['active']) == 1,
    );
  }
}

String _favoriteImageUrl(dynamic value) {
  final image = value?.toString().trim() ?? '';
  if (image.isEmpty) return '';
  if (image.startsWith('http://') || image.startsWith('https://')) {
    return image;
  }
  return _masterMediaUrl('uploud/items/$image');
}

class _UsersFavoritesWorkspace extends StatelessWidget {
  const _UsersFavoritesWorkspace({
    required this.favorites,
    required this.searchQuery,
  });

  final List<_FavoriteRecord> favorites;
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    final query = searchQuery.trim().toLowerCase();
    final visible = query.isEmpty
        ? favorites
        : favorites.where((favorite) {
            return favorite.itemName.toLowerCase().contains(query) ||
                favorite.userName.toLowerCase().contains(query) ||
                favorite.userPhone.contains(query);
          }).toList();
    if (visible.isEmpty) {
      return const _UsersPlaceholderWorkspace(
        title: 'المفضلات',
        description: 'لا توجد أصناف مفضلة مطابقة للبحث حالياً.',
        icon: Icons.favorite_border_rounded,
      );
    }
    return _RestaurantShellCard(
      title: 'قائمة المفضلات (${visible.length})',
      child: Column(
        children: [
          const _RestaurantTableHeader(
            columns: [
              (24, 'الصنف'),
              (18, 'المستخدم'),
              (16, 'رقم الهاتف'),
              (12, 'السعر'),
              (12, 'الحالة'),
              (10, 'الإضافة'),
            ],
          ),
          Expanded(
            child: ListView.separated(
              itemCount: visible.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final favorite = visible[index];
                return Container(
                  height: 76,
                  color: index.isEven ? const Color(0xFFF8FBF9) : Colors.white,
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      _OrdersTableCell(
                        flex: 24,
                        child: Row(
                          textDirection: TextDirection.rtl,
                          children: [
                            _AvatarThumb(
                              url: favorite.itemImage,
                              name: favorite.itemName,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _OrdersTwoLine(
                                title: favorite.itemName,
                                subtitle: 'ID: ${favorite.itemId}',
                              ),
                            ),
                          ],
                        ),
                      ),
                      _OrdersTableCell(
                        flex: 18,
                        child: _OrdersTwoLine(
                          title: favorite.userName.isEmpty
                              ? 'مستخدم غير معروف'
                              : favorite.userName,
                          subtitle: 'ID: ${favorite.userId}',
                        ),
                      ),
                      _OrdersTableCell(
                        flex: 16,
                        child: Text(favorite.userPhone),
                      ),
                      _OrdersTableCell(
                        flex: 12,
                        child: Text(
                          '${favorite.price} ${MasterCurrency.symbol}',
                        ),
                      ),
                      _OrdersTableCell(
                        flex: 12,
                        child: _statusPill(
                          favorite.active ? 'متاح' : 'غير متاح',
                        ),
                      ),
                      _OrdersTableCell(
                        flex: 10,
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFE25555),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserWalletRecord {
  const _UserWalletRecord({
    required this.walletId,
    required this.userId,
    required this.userName,
    required this.phone,
    this.walletExists = true,
    required this.walletType,
    required this.currentBalance,
    this.rewardPoints = 0,
    this.compensationPoints = 0,
    this.compensationAmount = '0',
    required this.blockedBalance,
    required this.transactionsCount,
    required this.status,
    required this.lastAction,
    required this.lastActionTime,
    required this.dailyLimit,
    required this.dailySpent,
    required this.defaultMethod,
    required this.avatarUrl,
  });

  final String walletId;
  final String userId;
  final String userName;
  final String phone;
  final bool walletExists;
  final String walletType;
  final String currentBalance;
  final int rewardPoints;
  final int compensationPoints;
  final String compensationAmount;
  final String blockedBalance;
  final int transactionsCount;
  final String status;
  final String lastAction;
  final String lastActionTime;
  final String dailyLimit;
  final String dailySpent;
  final String defaultMethod;
  final String avatarUrl;
}

class _SavedAddressRecord {
  const _SavedAddressRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userAvatar,
    required this.typeLabel,
    required this.title,
    required this.city,
    required this.district,
    required this.landmark,
    required this.status,
    required this.savedDate,
    required this.lastOrder,
    required this.postalCode,
    required this.linkedOrders,
    required this.lat,
    required this.lng,
  });

  final String id;
  final int userId;
  final String userName;
  final String userPhone;
  final String userAvatar;
  final String typeLabel;
  final String title;
  final String city;
  final String district;
  final String landmark;
  final String status;
  final String savedDate;
  final String lastOrder;
  final String postalCode;
  final int linkedOrders;
  final double lat;
  final double lng;

  bool get hasCoordinates => lat.abs() > 0.000001 && lng.abs() > 0.000001;

  factory _SavedAddressRecord.fromJson(Map<String, dynamic> json) {
    return _SavedAddressRecord(
      id: _firstText([json['address_id'], json['id'], '']),
      userId: _toInt(json['user_id'] ?? json['address_usersid']),
      userName: _normalizeUtf8Text(_firstText([json['user_name'], 'مستخدم'])),
      userPhone: _firstText([json['user_phone'], '-']),
      userAvatar: _masterMediaUrl(_firstText([json['user_avatar'], ''])),
      typeLabel: _normalizeUtf8Text(_firstText([json['type_label'], 'منزل'])),
      title: _normalizeUtf8Text(_firstText([json['title'], 'عنوان محفوظ'])),
      city: _normalizeUtf8Text(_firstText([json['city'], '-'])),
      district: _normalizeUtf8Text(_firstText([json['district'], '-'])),
      landmark: _normalizeUtf8Text(_firstText([json['landmark'], '-'])),
      status: _normalizeUtf8Text(_firstText([json['status'], 'نشط'])),
      savedDate: _firstText([json['saved_date'], '-']),
      lastOrder: _firstText([json['last_order'], '-']),
      postalCode: _firstText([json['postal_code'], '-']),
      linkedOrders: _toInt(json['linked_orders']),
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
    );
  }
}

class _SavedRecipientRecord {
  const _SavedRecipientRecord({
    required this.userName,
    required this.userAvatar,
    required this.recipientName,
    required this.phone,
    required this.email,
    required this.typeLabel,
    required this.defaultLabel,
    required this.addressTitle,
    required this.city,
    required this.savedDate,
    required this.lastUsed,
    required this.status,
    required this.totalOrders,
    required this.lat,
    required this.lng,
  });

  final String userName;
  final String userAvatar;
  final String recipientName;
  final String phone;
  final String email;
  final String typeLabel;
  final String defaultLabel;
  final String addressTitle;
  final String city;
  final String savedDate;
  final String lastUsed;
  final String status;
  final int totalOrders;
  final double lat;
  final double lng;

  factory _SavedRecipientRecord.fromJson(Map<String, dynamic> json) {
    return _SavedRecipientRecord(
      userName: _normalizeUtf8Text(_firstText([json['user_name'], 'مستخدم'])),
      userAvatar: _masterMediaUrl(_firstText([json['user_avatar'], ''])),
      recipientName: _normalizeUtf8Text(
        _firstText([json['recipient_name'], 'مستلم']),
      ),
      phone: _firstText([json['phone'], '-']),
      email: _firstText([json['email'], '-']),
      typeLabel: _normalizeUtf8Text(_firstText([json['type_label'], 'مستلم'])),
      defaultLabel: _normalizeUtf8Text(
        _firstText([json['default_label'], '-']),
      ),
      addressTitle: _normalizeUtf8Text(
        _firstText([json['address_title'], '-']),
      ),
      city: _normalizeUtf8Text(_firstText([json['city'], '-'])),
      savedDate: _firstText([json['saved_date'], '-']),
      lastUsed: _firstText([json['last_used'], '-']),
      status: _normalizeUtf8Text(_firstText([json['status'], 'نشط'])),
      totalOrders: _toInt(json['total_orders']),
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
    );
  }
}

double _numericUserValue(String value) {
  final sanitized = value.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(sanitized) ?? 0;
}

bool get _useLiveWalletRecords => true;

bool get _showLegacyUserWalletActions => false;

class _UserWalletRefundRequest {
  const _UserWalletRefundRequest({required this.orderId, required this.note});

  final int orderId;
  final String note;
}

Future<_UserWalletRefundRequest?> _showUserWalletRefundDialog(
  BuildContext context,
  _UserWalletRecord wallet,
) async {
  final orderController = TextEditingController();
  final noteController = TextEditingController(
    text: 'رد نقاط إلى محفظة العميل بعد إلغاء طلب مدفوع إلكترونيا',
  );
  String? errorText;

  final result = await showDialog<_UserWalletRefundRequest>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('رد نقاط طلب ملغي'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    wallet.userName,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: orderController,
                    textAlign: TextAlign.right,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'رقم الطلب الملغي',
                      hintText: 'مثال: 5489',
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteController,
                    textAlign: TextAlign.right,
                    minLines: 2,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'ملاحظة إدارية',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'سيتم التحقق من أن الطلب ملغي ومدفوع إلكترونيا، ثم تضاف قيمته إلى رصيد محفظة العميل كنقاط قابلة للدفع لاحقا.',
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.start,
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('إلغاء'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final orderId = int.tryParse(orderController.text.trim());
                  if (orderId == null || orderId <= 0) {
                    setDialogState(() {
                      errorText = 'أدخل رقم طلب صحيح';
                    });
                    return;
                  }
                  Navigator.of(dialogContext).pop(
                    _UserWalletRefundRequest(
                      orderId: orderId,
                      note: noteController.text.trim(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimaryGreen,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.assignment_return_outlined, size: 18),
                label: const Text('رد النقاط'),
              ),
            ],
          );
        },
      );
    },
  );

  orderController.dispose();
  noteController.dispose();
  return result;
}

String _formatUserWholeNumber(num value) {
  final rounded = value.round().toString();
  return rounded.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
}

List<_UserWalletRecord> _buildUserWalletRecords(List<_UserRecord> users) {
  if (users.isEmpty) {
    return const <_UserWalletRecord>[];
  }

  if (_useLiveWalletRecords) {
    return users.map((user) {
      final spend = _numericUserValue(user.totalSpendLabel);
      final currentBalance = _numericUserValue(user.walletBalanceLabel);
      final hasRefund = user.refundPoints > 0;
      final lastRefundAt =
          user.lastRefundDate != '-' && user.lastRefundTime != '-'
          ? '${user.lastRefundDate} ${user.lastRefundTime}'
          : '-';
      final lastOrderAt = user.lastOrderDate != '-' && user.lastOrderTime != '-'
          ? '${user.lastOrderDate} ${user.lastOrderTime}'
          : '-';

      return _UserWalletRecord(
        walletId: 'WAL-${user.id}',
        userId: user.id,
        userName: user.name,
        phone: user.phone,
        walletExists: user.walletExists,
        walletType: user.walletExists ? 'أساسية' : 'غير منشأة',
        currentBalance:
            '${_formatUserWholeNumber(currentBalance)} ${MasterCurrency.symbol}',
        rewardPoints: user.walletPoints,
        compensationPoints: user.refundPoints,
        compensationAmount: user.refundAmountLabel,
        blockedBalance: '${_formatUserWholeNumber(0)} ${MasterCurrency.symbol}',
        transactionsCount: user.ordersCount,
        status: user.walletExists ? user.status : 'غير مفعلة',
        lastAction: hasRefund ? 'رد نقاط طلب' : (spend > 0 ? 'دفع طلب' : '-'),
        lastActionTime: hasRefund ? lastRefundAt : lastOrderAt,
        dailyLimit: _formatUserWholeNumber(0),
        dailySpent: _formatUserWholeNumber(0),
        defaultMethod: 'رصيد المحفظة',
        avatarUrl: user.avatarUrl,
      );
    }).toList();
  }

  return users.map((user) {
    final spend = _numericUserValue(user.totalSpendLabel);
    final currentBalance = _numericUserValue(user.walletBalanceLabel);

    return _UserWalletRecord(
      walletId: 'WAL-${user.id}',
      userId: user.id,
      userName: user.name,
      phone: user.phone,
      walletType: 'أساسية',
      currentBalance:
          '${_formatUserWholeNumber(currentBalance)} ${MasterCurrency.symbol}',
      blockedBalance: '${_formatUserWholeNumber(0)} ${MasterCurrency.symbol}',
      transactionsCount: user.ordersCount,
      status: user.status.trim().isEmpty ? 'نشط' : user.status,
      lastAction: spend > 0 ? 'دفع طلب' : '-',
      lastActionTime: user.lastOrderDate != '-' && user.lastOrderTime != '-'
          ? '${user.lastOrderDate} ${user.lastOrderTime}'
          : '-',
      dailyLimit: _formatUserWholeNumber(0),
      dailySpent: _formatUserWholeNumber(0),
      defaultMethod: '-',
      avatarUrl: user.avatarUrl,
    );
  }).toList();
}

List<_SavedAddressRecord> _buildSavedAddressRecords(List<_UserRecord> users) {
  return const <_SavedAddressRecord>[];
}

List<_SavedRecipientRecord> _buildSavedRecipientRecords(
  List<_UserRecord> users,
) {
  return const <_SavedRecipientRecord>[];
}

List<_OperationsStatCardData> _buildUserStatCardsByPage(
  List<_UserRecord> users,
  String key, {
  List<_SavedAddressRecord> addresses = const <_SavedAddressRecord>[],
  List<_SavedRecipientRecord> recipients = const <_SavedRecipientRecord>[],
}) {
  final wallets = _buildUserWalletRecords(users);
  if (key == 'wallets') {
    final totalBalance = wallets.fold<double>(
      0,
      (sum, wallet) => sum + _numericUserValue(wallet.currentBalance),
    );
    final totalSpend = users.fold<double>(
      0,
      (sum, user) => sum + _numericUserValue(user.totalSpendLabel),
    );
    final compensationPoints = wallets.fold<int>(
      0,
      (sum, wallet) => sum + wallet.compensationPoints,
    );
    final existingWallets = wallets
        .where((wallet) => wallet.walletExists)
        .length;
    final activeWallets = wallets
        .where((wallet) => wallet.walletExists && wallet.status == 'نشط')
        .length;
    return [
      _OperationsStatCardData(
        title: 'إجمالي الرصيد',
        value: _formatUserWholeNumber(totalBalance),
        icon: Icons.account_balance_wallet_outlined,
        accent: const Color(0xFF16A34A),
        background: const Color(0xFFEAF7EE),
        detailLine: '${MasterCurrency.symbol}',
        trendLabel: '28%',
        trendCaption: 'عن أمس',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'إجمالي الإنفاق',
        value: _formatUserWholeNumber(totalSpend),
        icon: Icons.add_circle_outline,
        accent: const Color(0xFF22C55E),
        background: const Color(0xFFEAF7EE),
        detailLine: '${MasterCurrency.symbol}',
        trendLabel: '24%',
        trendCaption: 'عن أمس',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'نقاط التعويض',
        value: _formatUserWholeNumber(compensationPoints),
        icon: Icons.payments_outlined,
        accent: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF3DF),
        detailLine: 'نقطة',
        trendLabel: '18%',
        trendCaption: 'عن أمس',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'عدد العمليات',
        value:
            '${wallets.fold<int>(0, (sum, wallet) => sum + wallet.transactionsCount)}',
        icon: Icons.request_page_outlined,
        accent: const Color(0xFF60A5FA),
        background: const Color(0xFFEAF3FF),
        detailLine: 'عملية',
        trendLabel: '16%',
        trendCaption: 'عن أمس',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'المحافظ النشطة',
        value: '$activeWallets',
        icon: Icons.sync_alt_rounded,
        accent: const Color(0xFFF43F5E),
        background: const Color(0xFFFFEEF2),
        detailLine: 'محفظة',
        trendLabel: '12%',
        trendCaption: 'عن أمس',
        trendPositive: false,
      ),
      _OperationsStatCardData(
        title: 'إجمالي المحافظ',
        value: '$existingWallets',
        icon: Icons.people_alt_outlined,
        accent: const Color(0xFFB779FF),
        background: const Color(0xFFEAF7EE),
        detailLine: 'محفظة',
        trendLabel: '18%',
        trendCaption: 'عن أمس',
        trendPositive: true,
      ),
    ];
  }
  if (key == 'addresses') {
    final activeAddresses = addresses
        .where((address) => address.status == 'نشط')
        .length;
    final homeAddresses = addresses
        .where((address) => address.typeLabel == 'المنزل')
        .length;
    final workAddresses = addresses
        .where((address) => address.typeLabel == 'العمل')
        .length;
    return [
      _OperationsStatCardData(
        title: 'إجمالي العناوين',
        value: '${addresses.length}',
        icon: Icons.location_on_outlined,
        accent: const Color(0xFF16A34A),
        background: const Color(0xFFEAF7EE),
        detailLine: 'عنوان',
        trendLabel: '18%',
        trendCaption: 'عن أمس',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'عناوين نشطة',
        value: '$activeAddresses',
        icon: Icons.check_circle_outline,
        accent: const Color(0xFF22C55E),
        background: const Color(0xFFEAF7EE),
        detailLine: 'عنوان',
        trendLabel: '16%',
        trendCaption: 'عن أمس',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'عناوين غير مفعلة',
        value: '${math.max(0, addresses.length - activeAddresses)}',
        icon: Icons.schedule_outlined,
        accent: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF3DF),
        detailLine: 'عنوان',
        trendLabel: '12%',
        trendCaption: 'عن أمس',
        trendPositive: false,
      ),
      _OperationsStatCardData(
        title: 'الطلبات المرتبطة',
        value:
            '${addresses.fold<int>(0, (sum, address) => sum + address.linkedOrders)}',
        icon: Icons.star_border_rounded,
        accent: const Color(0xFF60A5FA),
        background: const Color(0xFFEAF3FF),
        detailLine: 'طلب',
        trendLabel: '20%',
        trendCaption: 'عن أمس',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'عناوين المنزل',
        value: '$homeAddresses',
        icon: Icons.home_outlined,
        accent: const Color(0xFFF973A9),
        background: const Color(0xFFFFEEF4),
        detailLine: 'عنوان',
        trendLabel: '15%',
        trendCaption: 'عن أمس',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'عناوين العمل',
        value: '$workAddresses',
        icon: Icons.work_outline_rounded,
        accent: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF3DF),
        detailLine: 'عنوان',
        trendLabel: '14%',
        trendCaption: 'عن أمس',
        trendPositive: true,
      ),
    ];
  }
  if (key == 'recipients') {
    final activeRecipients = recipients
        .where((recipient) => recipient.status == 'نشط')
        .length;
    final defaultRecipients = recipients
        .where((recipient) => recipient.defaultLabel == 'افتراضي')
        .length;
    return [
      _OperationsStatCardData(
        title: 'إجمالي المستلمين',
        value: '${recipients.length}',
        icon: Icons.person_pin_circle_outlined,
        accent: const Color(0xFF16A34A),
        background: const Color(0xFFEAF7EE),
        detailLine: 'مستلم',
        trendLabel: '18%',
        trendCaption: 'عن أمس',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'مستلمون نشطون',
        value: '$activeRecipients',
        icon: Icons.check_circle_outline,
        accent: const Color(0xFF22C55E),
        background: const Color(0xFFEAF7EE),
        detailLine: 'مستلم',
        trendLabel: '21%',
        trendCaption: 'عن أمس',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'إجمالي الطلبات',
        value:
            '${recipients.fold<int>(0, (sum, recipient) => sum + recipient.totalOrders)}',
        icon: Icons.person_add_alt_1_outlined,
        accent: const Color(0xFF60A5FA),
        background: const Color(0xFFEAF3FF),
        detailLine: 'طلب',
        trendLabel: '15%',
        trendCaption: 'عن أمس',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'المستخدمون المرتبطون',
        value: '${users.length}',
        icon: Icons.schedule_outlined,
        accent: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF3DF),
        detailLine: 'مستخدم',
        trendLabel: '17%',
        trendCaption: 'عن أمس',
        trendPositive: true,
      ),
      _OperationsStatCardData(
        title: 'المستلمون الافتراضيون',
        value: '$defaultRecipients',
        icon: Icons.star_border_rounded,
        accent: const Color(0xFFF43F5E),
        background: const Color(0xFFFFEEF2),
        detailLine: 'مستلم',
        trendLabel: '12%',
        trendCaption: 'عن أمس',
        trendPositive: false,
      ),
      _OperationsStatCardData(
        title: 'العناوين المرتبطة',
        value: '${addresses.length}',
        icon: Icons.location_on_outlined,
        accent: const Color(0xFF8B5CF6),
        background: const Color(0xFFEAF7EE),
        detailLine: 'عنوان',
        trendLabel: '19%',
        trendCaption: 'عن أمس',
        trendPositive: true,
      ),
    ];
  }
  return _buildUserStatCards(users);
}

class _UsersDirectoryWorkspace extends StatelessWidget {
  const _UsersDirectoryWorkspace({
    required this.users,
    required this.selectedUserIndex,
    required this.onUserSelected,
    required this.onEditUser,
    required this.onToggleUserStatus,
    required this.onDeleteUser,
    required this.onCallUser,
    required this.onMessageUser,
    required this.onOrdersUser,
  });

  final List<_UserRecord> users;
  final int selectedUserIndex;
  final ValueChanged<int> onUserSelected;
  final ValueChanged<_UserRecord> onEditUser;
  final ValueChanged<_UserRecord> onToggleUserStatus;
  final ValueChanged<_UserRecord> onDeleteUser;
  final ValueChanged<_UserRecord> onCallUser;
  final ValueChanged<_UserRecord> onMessageUser;
  final ValueChanged<_UserRecord> onOrdersUser;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const _UsersPlaceholderWorkspace(
        title: 'لا يوجد مستخدمون',
        description:
            'ستظهر هنا سجلات المستخدمين بمجرد وصولها من قاعدة البيانات.',
        icon: Icons.people_alt_outlined,
      );
    }
    final safeSelectedUserIndex = selectedUserIndex >= users.length
        ? users.length - 1
        : selectedUserIndex;
    final selectedUser = users[safeSelectedUserIndex];
    return Row(
      textDirection: TextDirection.rtl,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _RestaurantShellCard(
            title: 'قائمة المستخدمين (${users.length})',
            child: Column(
              children: [
                const _RestaurantTableHeader(
                  columns: [
                    (16, 'المستخدم'),
                    (14, 'رقم الهاتف'),
                    (16, 'البريد الإلكتروني'),
                    (12, 'الدولة / المدينة'),
                    (8, 'النوع'),
                    (8, 'الطلبات'),
                    (10, 'إجمالي الإنفاق'),
                    (10, 'آخر طلب'),
                    (10, 'الإجراءات'),
                  ],
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final selected = index == safeSelectedUserIndex;
                      return InkWell(
                        onTap: () => onUserSelected(index),
                        child: Container(
                          height: 66,
                          color: selected
                              ? const Color(0xFFF0F9F5)
                              : Colors.transparent,
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              _OrdersTableCell(
                                flex: 16,
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    _AvatarThumb(
                                      url: user.avatarUrl,
                                      name: user.name,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _OrdersTwoLine(
                                        title: user.name,
                                        subtitle: 'ID: ${user.id}',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 14,
                                child: Text(
                                  user.phone,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 16,
                                child: Text(
                                  user.email,
                                  textAlign: TextAlign.right,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 12,
                                child: _OrdersTwoLine(
                                  title: user.country,
                                  subtitle: user.city,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 8,
                                child: _statusPill(user.typeLabel),
                              ),
                              _OrdersTableCell(
                                flex: 8,
                                child: Text(
                                  '${user.ordersCount}',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 10,
                                child: Text(
                                  user.totalSpendLabel,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 10,
                                child: _OrdersTwoLine(
                                  title: user.lastOrderDate,
                                  subtitle: user.lastOrderTime,
                                ),
                              ),
                              _OrdersTableCell(
                                flex: 10,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _MiniIconButton(
                                      icon: Icons.edit_outlined,
                                      tooltip: 'تعديل',
                                      onTap: () => onEditUser(user),
                                    ),
                                    const SizedBox(width: 2),
                                    _MiniIconButton(
                                      icon: user.status.contains('نشط')
                                          ? Icons.block_outlined
                                          : Icons.check_circle_outline,
                                      tooltip: user.status.contains('نشط')
                                          ? 'تعطيل'
                                          : 'تفعيل',
                                      onTap: () => onToggleUserStatus(user),
                                    ),
                                    const SizedBox(width: 2),
                                    _MiniIconButton(
                                      icon: Icons.delete_outline,
                                      tooltip: 'حذف آمن',
                                      onTap: () => onDeleteUser(user),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 356,
          child: _UserDetailsPanel(
            user: selectedUser,
            onEditUser: () => onEditUser(selectedUser),
            onToggleUserStatus: () => onToggleUserStatus(selectedUser),
            onDeleteUser: () => onDeleteUser(selectedUser),
            onCallUser: () => onCallUser(selectedUser),
            onMessageUser: () => onMessageUser(selectedUser),
            onOrdersUser: () => onOrdersUser(selectedUser),
          ),
        ),
      ],
    );
  }
}

class _UsersWalletsWorkspace extends StatelessWidget {
  const _UsersWalletsWorkspace({
    required this.wallets,
    required this.selectedWalletIndex,
    required this.onWalletSelected,
    required this.onEnsureWallet,
    required this.onRefundOrder,
  });

  final List<_UserWalletRecord> wallets;
  final int selectedWalletIndex;
  final ValueChanged<int> onWalletSelected;
  final ValueChanged<_UserWalletRecord> onEnsureWallet;
  final ValueChanged<_UserWalletRecord> onRefundOrder;

  @override
  Widget build(BuildContext context) {
    if (wallets.isEmpty) {
      return const _UsersPlaceholderWorkspace(
        title: 'المحافظ',
        description:
            'لا توجد بيانات محافظ حية راجعة من قاعدة البيانات لهذا القسم حالياً.',
        icon: Icons.account_balance_wallet_outlined,
      );
    }
    final selected = wallets[selectedWalletIndex];
    return _MasterDetailTableLayout(
      title: 'قائمة المحافظ (${wallets.length})',
      detail: _UserWalletDetailsPanel(
        wallet: selected,
        onEnsureWallet: onEnsureWallet,
        onRefundOrder: onRefundOrder,
      ),
      child: Column(
        children: [
          const _RestaurantTableHeader(
            columns: [
              (18, 'المستخدم'),
              (12, 'رقم الهاتف'),
              (10, 'نوع المحفظة'),
              (12, 'الرصيد الحالي'),
              (10, 'المعاملات'),
              (12, 'آخر عملية'),
              (8, 'الحالة'),
              (8, 'الإجراءات'),
            ],
          ),
          Expanded(
            child: ListView.separated(
              itemCount: wallets.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final wallet = wallets[index];
                final isSelected = index == selectedWalletIndex;
                return InkWell(
                  onTap: () => onWalletSelected(index),
                  child: Container(
                    height: 66,
                    color: isSelected
                        ? const Color(0xFFF0F9F5)
                        : Colors.transparent,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _OrdersTableCell(
                          flex: 18,
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              _AvatarThumb(
                                url: wallet.avatarUrl,
                                name: wallet.userName,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _OrdersTwoLine(
                                  title: wallet.userName,
                                  subtitle: 'ID: ${wallet.userId}',
                                ),
                              ),
                            ],
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: Text(wallet.phone, textAlign: TextAlign.right),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: _statusPill(wallet.walletType),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: Text(
                            wallet.currentBalance,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(
                            '${wallet.transactionsCount}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: _OrdersTwoLine(
                            title: wallet.lastAction,
                            subtitle: wallet.lastActionTime,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 8,
                          child: _statusPill(wallet.status),
                        ),
                        _OrdersTableCell(
                          flex: 8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _MiniIconButton(
                                icon: Icons.visibility_outlined,
                                tooltip: 'عرض',
                                onTap: () => onWalletSelected(index),
                              ),
                              const SizedBox(width: 4),
                              _MiniIconButton(
                                icon: Icons.account_balance_wallet_outlined,
                                tooltip: 'تجهيز المحفظة',
                                onTap: () => onEnsureWallet(wallet),
                              ),
                              const SizedBox(width: 4),
                              _MiniIconButton(
                                icon: Icons.assignment_return_outlined,
                                tooltip: 'رد نقاط طلب ملغي',
                                onTap: wallet.walletExists
                                    ? () => onRefundOrder(wallet)
                                    : () => onEnsureWallet(wallet),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersAddressesWorkspace extends StatelessWidget {
  const _UsersAddressesWorkspace({
    required this.addresses,
    required this.selectedAddressIndex,
    required this.onAddressSelected,
    required this.onEditAddress,
    required this.onDeleteAddress,
  });

  final List<_SavedAddressRecord> addresses;
  final int selectedAddressIndex;
  final ValueChanged<int> onAddressSelected;
  final ValueChanged<_SavedAddressRecord> onEditAddress;
  final ValueChanged<_SavedAddressRecord> onDeleteAddress;

  @override
  Widget build(BuildContext context) {
    if (addresses.isEmpty) {
      return const _UsersPlaceholderWorkspace(
        title: 'العناوين المحفوظة',
        description:
            'لا توجد بيانات عناوين حية راجعة من قاعدة البيانات لهذا القسم حالياً.',
        icon: Icons.location_on_outlined,
      );
    }
    final selected = addresses[selectedAddressIndex];
    return _MasterDetailTableLayout(
      title: 'قائمة العناوين (${addresses.length})',
      detail: _SavedAddressDetailsPanel(
        address: selected,
        onDelete: () => onDeleteAddress(selected),
        onEdit: () => onEditAddress(selected),
      ),
      child: Column(
        children: [
          const _RestaurantTableHeader(
            columns: [
              (14, 'المستخدم'),
              (10, 'النوع'),
              (20, 'العنوان'),
              (12, 'المدينة / الحي'),
              (10, 'الموقع'),
              (10, 'تم الحفظ'),
              (8, 'الحالة'),
              (10, 'آخر طلب'),
              (6, 'الإجراءات'),
            ],
          ),
          Expanded(
            child: ListView.separated(
              itemCount: addresses.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final address = addresses[index];
                final selected = index == selectedAddressIndex;
                return InkWell(
                  onTap: () => onAddressSelected(index),
                  child: Container(
                    height: 68,
                    color: selected
                        ? const Color(0xFFF0F9F5)
                        : Colors.transparent,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _OrdersTableCell(
                          flex: 14,
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              _AvatarThumb(
                                url: address.userAvatar,
                                name: address.userName,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _OrdersTwoLine(
                                  title: address.userName,
                                  subtitle: address.userPhone,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: _statusPill(address.typeLabel),
                        ),
                        _OrdersTableCell(
                          flex: 20,
                          child: Text(
                            address.title,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: _OrdersTwoLine(
                            title: address.city,
                            subtitle: address.district,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(
                            'عرض على الخريطة',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 10.2,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(
                            address.savedDate,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 8,
                          child: _statusPill(address.status),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(
                            address.lastOrder,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 6,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _MiniIconButton(
                                icon: Icons.edit_outlined,
                                tooltip: 'تعديل',
                                onTap: () => onEditAddress(address),
                              ),
                              const SizedBox(width: 4),
                              _MiniIconButton(
                                icon: Icons.delete_outline,
                                tooltip: 'حذف',
                                onTap: () => onDeleteAddress(address),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersRecipientsWorkspace extends StatelessWidget {
  const _UsersRecipientsWorkspace({
    required this.recipients,
    required this.selectedRecipientIndex,
    required this.onRecipientSelected,
  });

  final List<_SavedRecipientRecord> recipients;
  final int selectedRecipientIndex;
  final ValueChanged<int> onRecipientSelected;

  @override
  Widget build(BuildContext context) {
    if (recipients.isEmpty) {
      return const _UsersPlaceholderWorkspace(
        title: 'المستلمون المحفوظون',
        description:
            'لا توجد بيانات مستلمين حية راجعة من قاعدة البيانات لهذا القسم حالياً.',
        icon: Icons.person_pin_circle_outlined,
      );
    }
    final selected = recipients[selectedRecipientIndex];
    return _MasterDetailTableLayout(
      title: 'قائمة المستلمين (${recipients.length})',
      detail: _SavedRecipientDetailsPanel(recipient: selected),
      child: Column(
        children: [
          const _RestaurantTableHeader(
            columns: [
              (14, 'المستخدم'),
              (16, 'معلومات الاتصال'),
              (12, 'المستلم'),
              (10, 'النوع'),
              (8, 'افتراضي'),
              (10, 'تاريخ الإضافة'),
              (10, 'آخر استخدام'),
              (8, 'الحالة'),
              (6, 'الإجراءات'),
            ],
          ),
          Expanded(
            child: ListView.separated(
              itemCount: recipients.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final recipient = recipients[index];
                final selected = index == selectedRecipientIndex;
                return InkWell(
                  onTap: () => onRecipientSelected(index),
                  child: Container(
                    height: 68,
                    color: selected
                        ? const Color(0xFFF0F9F5)
                        : Colors.transparent,
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        _OrdersTableCell(
                          flex: 14,
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              _AvatarThumb(
                                url: recipient.userAvatar,
                                name: recipient.userName,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  recipient.userName,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 16,
                          child: _OrdersTwoLine(
                            title: recipient.phone,
                            subtitle: recipient.email,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 12,
                          child: Text(
                            recipient.recipientName,
                            textAlign: TextAlign.right,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: _statusPill(recipient.typeLabel),
                        ),
                        _OrdersTableCell(
                          flex: 8,
                          child: _statusPill(recipient.defaultLabel),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(
                            recipient.savedDate,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 10,
                          child: Text(
                            recipient.lastUsed,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        _OrdersTableCell(
                          flex: 8,
                          child: _statusPill(recipient.status),
                        ),
                        _OrdersTableCell(
                          flex: 6,
                          child: const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersPlaceholderWorkspace extends StatelessWidget {
  const _UsersPlaceholderWorkspace({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: title,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, size: 24, color: const Color(0xFF0B8F4D)),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6F7680), height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserWalletDetailsPanel extends StatelessWidget {
  const _UserWalletDetailsPanel({
    required this.wallet,
    required this.onEnsureWallet,
    required this.onRefundOrder,
  });

  final _UserWalletRecord wallet;
  final ValueChanged<_UserWalletRecord> onEnsureWallet;
  final ValueChanged<_UserWalletRecord> onRefundOrder;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'تفاصيل المحفظة',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _statusPill(wallet.status),
            ),
            const SizedBox(height: 10),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                _AvatarThumb(
                  url: wallet.avatarUrl,
                  name: wallet.userName,
                  size: 54,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        wallet.userName,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ID: ${wallet.userId}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF6F7680)),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        textDirection: TextDirection.rtl,
                        children: [
                          _statusPill(wallet.walletType),
                          _statusPill('عميل مميز'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B8F4D), Color(0xFF16A34A)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'رصيد المحفظة الحالي',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    wallet.currentBalance,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _detailMetricCard(
                    'الرصيد المعلق',
                    wallet.blockedBalance,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _detailMetricCard(
                    'إجمالي المعاملات',
                    '${wallet.transactionsCount}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: _detailMetricCard(
                    'نقاط التعويض',
                    '${wallet.compensationPoints} نقطة',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _detailMetricCard(
                    'قيمة التعويضات',
                    wallet.compensationAmount,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: wallet.walletExists
                        ? () => onRefundOrder(wallet)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 44),
                    ),
                    icon: const Icon(
                      Icons.assignment_return_outlined,
                      size: 16,
                    ),
                    label: const Text('رد نقاط طلب ملغي'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onEnsureWallet(wallet),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kPrimaryGreen,
                      minimumSize: const Size(0, 44),
                    ),
                    icon: const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 16,
                    ),
                    label: Text(
                      wallet.walletExists ? 'تجهيز المحفظة' : 'إنشاء المحفظة',
                    ),
                  ),
                ),
              ],
            ),
            if (_showLegacyUserWalletActions) ...[
              const SizedBox(height: 12),
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  Expanded(
                    child: _walletActionButton(
                      context,
                      Icons.add_circle_outline,
                      'إضافة رصيد',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _walletActionButton(
                      context,
                      Icons.file_download_outlined,
                      'طلب سحب',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _walletActionButton(
                      context,
                      Icons.swap_horiz_rounded,
                      'تحويل رصيد',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _walletActionButton(
                      context,
                      Icons.restart_alt_rounded,
                      'استرداد',
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            _detailLine(
              Icons.calendar_today_outlined,
              'تاريخ الإنشاء',
              wallet.lastActionTime,
            ),
            _detailLine(
              Icons.update_outlined,
              'آخر تحديث',
              wallet.lastActionTime,
            ),
            _detailLine(
              Icons.credit_card_outlined,
              'طريقة الدفع الافتراضية',
              wallet.defaultMethod,
            ),
            _detailLine(
              Icons.shield_outlined,
              'حد السحب اليومي',
              wallet.dailyLimit,
            ),
            _detailLine(
              Icons.bar_chart_outlined,
              'المنفق اليوم',
              wallet.dailySpent,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _showMasterSnack(context, 'عرض سجل المحفظة'),
              icon: const Icon(Icons.history_rounded),
              label: const Text('عرض المعاملات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletActionButton(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    return InkWell(
      onTap: () => _showMasterSnack(context, label),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7ECE8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF0B8F4D)),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedAddressDetailsPanel extends StatelessWidget {
  const _SavedAddressDetailsPanel({
    required this.address,
    required this.onDelete,
    required this.onEdit,
  });

  final _SavedAddressRecord address;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'تفاصيل العنوان',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                _statusPill(address.typeLabel),
                const Spacer(),
                _statusPill(address.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              address.title,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              '${address.city} - ${address.district}',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Color(0xFF6F7680)),
            ),
            const SizedBox(height: 10),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                _AvatarThumb(
                  url: address.userAvatar,
                  name: address.userName,
                  size: 44,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _OrdersTwoLine(
                    title: address.userName,
                    subtitle: address.userPhone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (address.hasCoordinates)
              SizedBox(
                height: 132,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _LiveOperationsMap(
                    markers: [
                      _OperationsMapMarkerData(
                        type: 'address',
                        label: address.title,
                        subtitle: address.city,
                        point: LatLng(address.lat, address.lng),
                        icon: Icons.location_on_rounded,
                        color: const Color(0xFFEF4444),
                      ),
                    ],
                    showLayerPanel: false,
                    showWeatherBadge: false,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Text(
                  'لا توجد إحداثيات محفوظة لهذا العنوان.',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            _detailLine(
              Icons.location_on_outlined,
              'المنطقة',
              '${address.city} - ${address.district}',
            ),
            _detailLine(
              Icons.mark_email_read_outlined,
              'الرمز البريدي',
              address.postalCode,
            ),
            _detailLine(
              Icons.pin_drop_outlined,
              'تفاصيل الموقع',
              address.landmark,
            ),
            _detailLine(
              Icons.calendar_today_outlined,
              'تم الحفظ',
              address.savedDate,
            ),
            _detailLine(
              Icons.shopping_bag_outlined,
              'عدد الطلبات',
              '${address.linkedOrders} طلب',
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _showMasterSnack(context, 'حذف العنوان'),
              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
              label: const Text(
                'حذف العنوان',
                style: TextStyle(color: Color(0xFFDC2626)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedRecipientDetailsPanel extends StatelessWidget {
  const _SavedRecipientDetailsPanel({required this.recipient});

  final _SavedRecipientRecord recipient;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'تفاصيل المستلم',
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _statusPill(recipient.status),
            ),
            const SizedBox(height: 10),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                _AvatarThumb(
                  url: recipient.userAvatar,
                  name: recipient.recipientName,
                  size: 66,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        recipient.recipientName,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        textDirection: TextDirection.rtl,
                        children: [
                          _statusPill(recipient.defaultLabel),
                          _statusPill(recipient.typeLabel),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _detailLine(Icons.call_outlined, 'الهاتف', recipient.phone),
            _detailLine(
              Icons.email_outlined,
              'البريد الإلكتروني',
              recipient.email,
            ),
            _detailLine(Icons.person_outline, 'المستخدم', recipient.userName),
            const SizedBox(height: 12),
            SizedBox(
              height: 176,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _LiveOperationsMap(
                  markers: [
                    _OperationsMapMarkerData(
                      type: 'recipient',
                      label: recipient.recipientName,
                      subtitle: recipient.addressTitle,
                      point: LatLng(recipient.lat, recipient.lng),
                      icon: Icons.person_pin_circle_outlined,
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                  showLayerPanel: false,
                  showWeatherBadge: false,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _detailLine(
              Icons.place_outlined,
              'العنوان',
              recipient.addressTitle,
            ),
            _detailLine(
              Icons.location_city_outlined,
              'المدينة',
              recipient.city,
            ),
            _detailLine(
              Icons.calendar_today_outlined,
              'تاريخ الإضافة',
              recipient.savedDate,
            ),
            _detailLine(
              Icons.schedule_outlined,
              'آخر استخدام',
              recipient.lastUsed,
            ),
            _detailLine(
              Icons.shopping_bag_outlined,
              'إجمالي الطلبات',
              '${recipient.totalOrders} طلب',
            ),
            const Spacer(),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showMasterSnack(context, 'تعديل المستلم'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('تعديل'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showMasterSnack(context, 'حذف المستلم'),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFDC2626),
                    ),
                    label: const Text(
                      'حذف',
                      style: TextStyle(color: Color(0xFFDC2626)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showMasterSnack(context, 'إرسال للمستخدم'),
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('إرسال للمستخدم'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
