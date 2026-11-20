// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

class MasterUsersPage extends StatefulWidget {
  const MasterUsersPage({
    super.key,
    required this.session,
    required this.onLogout,
    required this.api,
    this.serverNow,
    this.initialSubPage = 'users',
    this.unifiedFrame = true,
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService api;
  final DateTime? serverNow;
  final String initialSubPage;
  final bool unifiedFrame;

  @override
  State<MasterUsersPage> createState() => _MasterUsersPageState();
}

class _MasterUsersPageState extends State<MasterUsersPage> {
  late String _activeSubPage;
  bool _showNavigationSidebar = true;
  final TextEditingController _searchController = TextEditingController();
  int _selectedUserIndex = 0;
  int _selectedWalletIndex = 0;
  int _selectedAddressIndex = 0;
  int _selectedRecipientIndex = 0;
  bool _userActionRunning = false;
  String _statusFilter = 'all';
  String _countryFilter = 'all';
  String _cityFilter = 'all';

  late Future<_MasterUsersData> _usersFuture;

  @override
  void initState() {
    super.initState();
    _activeSubPage = widget.initialSubPage;
    _usersFuture = widget.api._fetchMasterUsersOverview(widget.session.token);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.unifiedFrame) {
      return _buildUnifiedUsersFrame(context);
    }
    final serverNow = widget.serverNow ?? DateTime.now();
    return FutureBuilder<_MasterUsersData>(
      future: _usersFuture,
      builder: (context, snapshot) {
        // Handle loading state
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFDFDFD),
                    Color(0xFFF7F8FA),
                    Color(0xFFF4F6F8),
                  ],
                ),
              ),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.8),
                ),
              ),
            ),
          );
        }

        // Handle error state
        if (snapshot.hasError) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFDFDFD),
                    Color(0xFFF7F8FA),
                    Color(0xFFF4F6F8),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  width: 420,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE7ECE8)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 34,
                        color: Color(0xFFD92C2C),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'تعذر تحميل بيانات المستخدمين',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E232A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error?.toString() ?? 'حدث خطأ غير متوقع',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.6,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6F7680),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _usersFuture = widget.api._fetchMasterUsersOverview(
                              widget.session.token,
                            );
                          });
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final liveData = snapshot.data ?? _MasterUsersData.empty();
        final liveUsers = liveData.users;
        final effectiveUsers = _filterUsers(liveUsers);
        final wallets = _buildUserWalletRecords(effectiveUsers);
        final addresses = liveData.addresses;
        final recipients = liveData.recipients;
        final favorites = liveData.favorites;
        return Scaffold(
          body: Container(
            color: const Color(0xFFF7F8FA),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final sidebarWidth = constraints.maxWidth >= 1280
                        ? 258.0
                        : 230.0;
                    return Row(
                      textDirection: TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _OrdersHeaderBar(
                                serverNow: serverNow,
                                onReload: _reload,
                                showInsightsSidebar: true,
                                showNavigationSidebar: _showNavigationSidebar,
                                onToggleInsightsSidebar: () {},
                                onToggleNavigationSidebar: () {
                                  setState(() {
                                    _showNavigationSidebar =
                                        !_showNavigationSidebar;
                                  });
                                },
                                title: _usersPageTitle(_activeSubPage),
                                subtitle: _usersPageSubtitle(_activeSubPage),
                                icon: _usersPageIcon(_activeSubPage),
                              ),
                              const SizedBox(height: 10),
                              _OrdersStatsStrip(
                                cards: _buildUserStatCardsByPage(
                                  effectiveUsers,
                                  _activeSubPage,
                                  addresses: addresses,
                                  recipients: recipients,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _UsersFiltersBar(
                                activeTab: _activeSubPage,
                                searchController: _searchController,
                                onSubmitted: _reload,
                                statusFilter: _statusFilter,
                                countryFilter: _countryFilter,
                                cityFilter: _cityFilter,
                                onStatusChanged: (value) {
                                  setState(() => _statusFilter = value);
                                },
                                onCountryChanged: (value) {
                                  setState(() => _countryFilter = value);
                                },
                                onCityChanged: (value) {
                                  setState(() => _cityFilter = value);
                                },
                                onAdvancedPressed: _showUsersAdvancedFilters,
                                onPrimaryPressed: () {
                                  if (_activeSubPage == 'users') {
                                    _showCreateUserDialog();
                                    return;
                                  }
                                  if (_activeSubPage == 'wallets' &&
                                      wallets.isNotEmpty) {
                                    final walletIndex = math.min(
                                      _selectedWalletIndex,
                                      wallets.length - 1,
                                    );
                                    _ensureUserWallet(wallets[walletIndex]);
                                    return;
                                  }
                                  if (_activeSubPage == 'addresses') {
                                    _showCreateAddressDialog(liveUsers);
                                    return;
                                  }
                                  if (_activeSubPage == 'orders') {
                                    _reload();
                                    return;
                                  }
                                  _reload();
                                },
                              ),
                              const SizedBox(height: 10),
                              _UsersTopTabs(
                                activeTab: _activeSubPage,
                                onTabSelected: (value) {
                                  setState(() => _activeSubPage = value);
                                },
                              ),
                              const SizedBox(height: 10),
                              Expanded(
                                child: _buildUsersWorkspace(
                                  liveUsers,
                                  wallets,
                                  addresses,
                                  recipients,
                                  favorites,
                                  snapshot,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showNavigationSidebar) ...[
                          const SizedBox(width: 12),
                          SizedBox(
                            width: sidebarWidth,
                            child: _UsersRightSidebar(
                              activeSubPage: _activeSubPage,
                              onSubPageTap: (value) {
                                setState(() => _activeSubPage = value);
                              },
                              onHomeTap: () => _navigateToMasterSection(
                                context,
                                key: 'home',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onOperationsTap: () => _navigateToMasterSection(
                                context,
                                key: 'operations',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onOrdersTap: () => _navigateToMasterSection(
                                context,
                                key: 'orders',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onLogisticsTap: () => _navigateToMasterSection(
                                context,
                                key: 'delivery',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onRestaurantsTap: () => _navigateToMasterSection(
                                context,
                                key: 'restaurants',
                                session: widget.session,
                                onLogout: widget.onLogout,
                                api: widget.api,
                                serverNow: serverNow,
                              ),
                              onFinanceTap: () {
                                _navigateToMasterSection(
                                  context,
                                  key: 'finance',
                                  session: widget.session,
                                  onLogout: widget.onLogout,
                                  api: widget.api,
                                  serverNow: serverNow,
                                );
                              },
                              onMarketingTap: () {
                                _navigateToMasterSection(
                                  context,
                                  key: 'marketing',
                                  session: widget.session,
                                  onLogout: widget.onLogout,
                                  api: widget.api,
                                  serverNow: serverNow,
                                );
                              },
                              onCollapse: () {
                                setState(() => _showNavigationSidebar = false);
                              },
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnifiedUsersFrame(BuildContext context) {
    final serverNow = widget.serverNow ?? DateTime.now();
    final sidebarItems = _masterFilterSidebarItems(widget.session, const [
      _DashboardMenuItemData(
        iconKey: 'users',
        label: 'العملاء',
        selected: true,
      ),
    ]);
    return _buildMasterUnifiedShell(
      context: context,
      session: widget.session,
      onLogout: widget.onLogout,
      api: widget.api,
      sidebarItems: sidebarItems,
      onSidebarItemTap: (itemKey) {
        final key = _masterCanonicalModuleKey(itemKey);
        if (key == 'users') return;
        _navigateToMasterSection(
          context,
          key: key,
          session: widget.session,
          onLogout: widget.onLogout,
          api: widget.api,
          serverNow: serverNow,
        );
      },
      statusLabel: 'إدارة العملاء',
      platformTitle: 'العملاء والمستخدمون',
      platformSubtitle: 'إدارة الحسابات والمحافظ والعناوين',
      serverNow: serverNow,
      child: FutureBuilder<_MasterUsersData>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(
              child: _UsersPlaceholderWorkspace(
                title: 'تعذر تحميل بيانات العملاء',
                description: snapshot.error?.toString() ?? 'حدث خطأ غير متوقع',
                icon: Icons.error_outline_rounded,
              ),
            );
          }
          final data = snapshot.data!;
          final users = _filterUsers(data.users);
          final wallets = _buildUserWalletRecords(users);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  for (final item in const <MapEntry<String, String>>[
                    MapEntry('users', 'المستخدمون'),
                    MapEntry('wallets', 'المحافظ'),
                    MapEntry('addresses', 'العناوين'),
                    MapEntry('recipients', 'المستلمون'),
                    MapEntry('favorites', 'المفضلة'),
                  ])
                    ChoiceChip(
                      selected: _activeSubPage == item.key,
                      label: Text(item.value),
                      onSelected: (_) =>
                          setState(() => _activeSubPage = item.key),
                    ),
                  FilledButton.icon(
                    onPressed: _showCreateUserDialog,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('إضافة مستخدم'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _OrdersStatsStrip(
                cards: _buildUserStatCardsByPage(
                  users,
                  _activeSubPage,
                  addresses: data.addresses,
                  recipients: data.recipients,
                ),
              ),
              const SizedBox(height: 12),
              _UsersFiltersBar(
                activeTab: _activeSubPage,
                searchController: _searchController,
                onSubmitted: _reload,
                statusFilter: _statusFilter,
                countryFilter: _countryFilter,
                cityFilter: _cityFilter,
                onStatusChanged: (value) =>
                    setState(() => _statusFilter = value),
                onCountryChanged: (value) =>
                    setState(() => _countryFilter = value),
                onCityChanged: (value) => setState(() => _cityFilter = value),
                onAdvancedPressed: _showUsersAdvancedFilters,
                onPrimaryPressed: _showCreateUserDialog,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildUsersWorkspace(
                  users,
                  wallets,
                  data.addresses,
                  data.recipients,
                  data.favorites,
                  snapshot,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _reload() {
    setState(() {
      _usersFuture = widget.api._fetchMasterUsersOverview(widget.session.token);
    });
  }

  List<_UserRecord> _filterUsers(List<_UserRecord> users) {
    return users.where((user) {
      if (_statusFilter == 'active' && !user.status.contains('نشط')) {
        return false;
      }
      if (_statusFilter == 'inactive' && user.status.contains('نشط')) {
        return false;
      }
      if (_statusFilter == 'blocked' && !user.status.contains('موقوف')) {
        return false;
      }
      if (_countryFilter != 'all' &&
          !user.country.toLowerCase().contains(_countryFilter)) {
        return false;
      }
      if (_cityFilter != 'all' &&
          !user.city.toLowerCase().contains(_cityFilter)) {
        return false;
      }
      final query = _searchController.text.trim().toLowerCase();
      if (query.isNotEmpty) {
        final haystack = [
          user.name,
          user.email,
          user.phone,
          user.country,
          user.city,
          user.id,
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _showUsersAdvancedFilters() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'الفلاتر المتقدمة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Text('الحالة: ${_usersFilterLabel(_statusFilter)}'),
              Text('الدولة: ${_usersFilterLabel(_countryFilter)}'),
              Text('المدينة: ${_usersFilterLabel(_cityFilter)}'),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  setState(() {
                    _statusFilter = 'all';
                    _countryFilter = 'all';
                    _cityFilter = 'all';
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.restart_alt_rounded),
                label: const Text('إعادة ضبط الفلاتر'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateUserDialog() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة مستخدم', textAlign: TextAlign.right),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  labelText: 'الاسم',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneController,
                textAlign: TextAlign.right,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.start,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('إضافة'),
          ),
        ],
      ),
    );
    if (saved == true && mounted) {
      try {
        await widget.api._runMasterUserAction(
          widget.session.token,
          action: 'create',
          data: {
            'name': nameController.text.trim(),
            'email': emailController.text.trim(),
            'phone': phoneController.text.trim(),
          },
        );
        if (mounted) {
          _showMasterSnack(context, 'تم إنشاء المستخدم في قاعدة البيانات');
          _reload();
        }
      } catch (error) {
        if (mounted) {
          _showMasterSnack(context, error.toString());
        }
      }
    }
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  Future<void> _ensureUserWallet(_UserWalletRecord wallet) async {
    final userId = int.tryParse(wallet.userId);
    if (userId == null || userId <= 0) {
      _showMasterSnack(context, 'لا يوجد معرف مستخدم صالح');
      return;
    }
    try {
      await widget.api._ensureMasterUserWallet(
        widget.session.token,
        userId: userId,
      );
      if (!mounted) {
        return;
      }
      _showMasterSnack(context, 'تم تجهيز محفظة العميل');
      _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMasterSnack(context, error.toString());
    }
  }

  Future<void> _refundOrderToUserWallet(_UserWalletRecord wallet) async {
    final request = await _showUserWalletRefundDialog(context, wallet);
    if (request == null || !mounted) {
      return;
    }
    try {
      await widget.api._refundCancelledOrderToWallet(
        widget.session.token,
        orderId: request.orderId,
        note: request.note,
      );
      if (!mounted) {
        return;
      }
      _showMasterSnack(context, 'تم رد قيمة الطلب إلى محفظة العميل');
      _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMasterSnack(context, error.toString());
    }
  }

  Widget _buildUsersWorkspace(
    List<_UserRecord> liveUsers,
    List<_UserWalletRecord> wallets,
    List<_SavedAddressRecord> addresses,
    List<_SavedRecipientRecord> recipients,
    List<_FavoriteRecord> favorites,
    AsyncSnapshot<_MasterUsersData> snapshot,
  ) {
    switch (_activeSubPage) {
      case 'wallets':
        final walletIndex = wallets.isEmpty
            ? 0
            : math.min(_selectedWalletIndex, wallets.length - 1);
        return _UsersWalletsWorkspace(
          wallets: wallets,
          selectedWalletIndex: walletIndex,
          onWalletSelected: (value) {
            setState(() => _selectedWalletIndex = value);
          },
          onEnsureWallet: _ensureUserWallet,
          onRefundOrder: _refundOrderToUserWallet,
        );
      case 'addresses':
        final addressIndex = addresses.isEmpty
            ? 0
            : math.min(_selectedAddressIndex, addresses.length - 1);
        return _UsersAddressesWorkspace(
          addresses: addresses,
          selectedAddressIndex: addressIndex,
          onAddressSelected: (value) {
            setState(() => _selectedAddressIndex = value);
          },
          onEditAddress: _showAddressEditor,
          onDeleteAddress: _deleteAddress,
        );
      case 'recipients':
        final recipientIndex = recipients.isEmpty
            ? 0
            : math.min(_selectedRecipientIndex, recipients.length - 1);
        return _UsersRecipientsWorkspace(
          recipients: recipients,
          selectedRecipientIndex: recipientIndex,
          onRecipientSelected: (value) {
            setState(() => _selectedRecipientIndex = value);
          },
        );
      case 'favorites':
        return _UsersFavoritesWorkspace(
          favorites: favorites,
          searchQuery: _searchController.text,
        );
      case 'orders':
        return _UsersOrdersWorkspace(
          orders: snapshot.data?.orders ?? const <_UserOrderRecord>[],
        );
      case 'users':
      default:
        if (snapshot.connectionState == ConnectionState.waiting &&
            liveUsers.isEmpty) {
          return const _UsersPlaceholderWorkspace(
            title: 'جاري تحميل المستخدمين',
            description:
                'نقوم الآن بجلب بيانات المستخدمين الحقيقية من الباك إند.',
            icon: Icons.hourglass_top_rounded,
          );
        }
        if (snapshot.hasError) {
          return const _UsersPlaceholderWorkspace(
            title: 'تعذر تحميل المستخدمين',
            description:
                'لم نتمكن من قراءة بيانات المستخدمين من قاعدة البيانات حالياً.',
            icon: Icons.error_outline_rounded,
          );
        }
        if (liveUsers.isEmpty) {
          return const _UsersPlaceholderWorkspace(
            title: 'لا يوجد مستخدمون',
            description: 'لم تصل أي سجلات مستخدمين من الباك إند حتى الآن.',
            icon: Icons.people_alt_outlined,
          );
        }
        final selectedUserIndex = _selectedUserIndex >= liveUsers.length
            ? liveUsers.length - 1
            : _selectedUserIndex;
        return _UsersDirectoryWorkspace(
          users: liveUsers,
          selectedUserIndex: selectedUserIndex,
          onUserSelected: (value) {
            setState(() => _selectedUserIndex = value);
          },
          onEditUser: _showUserEditor,
          onToggleUserStatus: _toggleUserStatus,
          onDeleteUser: _deleteUser,
          onCallUser: (user) => html.window.open('tel:${user.phone}', '_self'),
          onMessageUser: (user) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MasterSupportUnifiedPage(
                  session: widget.session,
                  onLogout: widget.onLogout,
                  api: widget.api,
                  serverNow: widget.serverNow,
                ),
              ),
            );
          },
          onOrdersUser: (user) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MasterOrdersPage(
                  session: widget.session,
                  onLogout: widget.onLogout,
                  api: widget.api,
                  unifiedFrame: true,
                  serverNow: widget.serverNow,
                ),
              ),
            );
          },
        );
    }
  }

  int _userNumericId(_UserRecord user) {
    return int.tryParse(user.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  Future<void> _runUserAction(
    _UserRecord user, {
    required String action,
    required String successMessage,
    Map<String, dynamic>? data,
  }) async {
    if (_userActionRunning) {
      return;
    }
    final userId = _userNumericId(user);
    if (userId <= 0) {
      _showMasterSnack(context, 'لا يوجد معرف مستخدم صالح');
      return;
    }
    setState(() => _userActionRunning = true);
    try {
      await widget.api._runMasterUserAction(
        widget.session.token,
        userId: userId,
        action: action,
        data: data,
      );
      if (!mounted) {
        return;
      }
      _showMasterSnack(context, successMessage);
      _reload();
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _userActionRunning = false);
      }
    }
  }

  Future<void> _toggleUserStatus(_UserRecord user) async {
    final isActive = user.status.contains('نشط');
    await _runUserAction(
      user,
      action: isActive ? 'disable' : 'approve',
      successMessage: isActive ? 'تم تعطيل المستخدم' : 'تم تفعيل المستخدم',
    );
  }

  Future<void> _deleteUser(_UserRecord user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف المستخدم', textAlign: TextAlign.right),
          content: Text(
            'سيتم تعطيل حساب ${user.name} بشكل آمن مع الحفاظ على الطلبات والمحفظة والعناوين المرتبطة به.',
            textAlign: TextAlign.right,
          ),
          actionsAlignment: MainAxisAlignment.start,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('تعطيل الحساب'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _runUserAction(
      user,
      action: 'delete',
      successMessage: 'تم تعطيل المستخدم وحفظ السجلات المرتبطة',
    );
  }

  Future<void> _showUserEditor(_UserRecord user) async {
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phone);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('تعديل المستخدم', textAlign: TextAlign.right),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'الاسم',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.start,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ'),
            ),
          ],
        );
      },
    );
    if (saved == true && mounted) {
      await _runUserAction(
        user,
        action: 'update',
        successMessage: 'تم حفظ بيانات المستخدم',
        data: {
          'name': nameController.text.trim(),
          'email': emailController.text.trim(),
          'phone': phoneController.text.trim(),
        },
      );
    }
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
  }

  int _addressNumericId(_SavedAddressRecord address) {
    return int.tryParse(address.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  Future<void> _runAddressAction(
    _SavedAddressRecord address, {
    required String action,
    required String successMessage,
    Map<String, dynamic>? data,
  }) async {
    final addressId = _addressNumericId(address);
    if (addressId <= 0) {
      _showMasterSnack(context, 'لا يوجد معرف عنوان صالح');
      return;
    }
    try {
      await widget.api._runMasterUserAddressAction(
        widget.session.token,
        addressId: addressId,
        action: action,
        data: data,
      );
      if (!mounted) {
        return;
      }
      _showMasterSnack(context, successMessage);
      _reload();
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, error.toString());
      }
    }
  }

  Future<void> _deleteAddress(_SavedAddressRecord address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف العنوان', textAlign: TextAlign.right),
          content: Text(
            'هل تريد حذف عنوان ${address.title}؟ لن يتم حذف الطلبات المرتبطة به.',
            textAlign: TextAlign.right,
          ),
          actionsAlignment: MainAxisAlignment.start,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('حذف'),
            ),
          ],
        );
      },
    );
    if (confirmed == true && mounted) {
      await _runAddressAction(
        address,
        action: 'address_delete',
        successMessage: 'تم حذف العنوان',
      );
    }
  }

  Future<void> _showCreateAddressDialog(List<_UserRecord> users) async {
    if (users.isEmpty) {
      _showMasterSnack(context, 'لا يوجد عملاء لإضافة العنوان لهم');
      return;
    }
    final title = TextEditingController();
    final city = TextEditingController();
    final district = TextEditingController();
    final phone = TextEditingController();
    var userId = int.tryParse(users.first.id) ?? 0;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة عنوان جديد'),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: userId,
                  decoration: const InputDecoration(labelText: 'العميل'),
                  items: users
                      .map(
                        (user) => DropdownMenuItem(
                          value: int.tryParse(user.id) ?? 0,
                          child: Text(user.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => userId = value ?? userId),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'اسم العنوان'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: city,
                  decoration: const InputDecoration(labelText: 'المدينة'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: district,
                  decoration: const InputDecoration(labelText: 'الشارع / الحي'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'الهاتف'),
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
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      try {
        await widget.api._runMasterUserAddressAction(
          widget.session.token,
          addressId: 0,
          userId: userId,
          action: 'address_create',
          data: {
            'title': title.text.trim(),
            'city': city.text.trim(),
            'district': district.text.trim(),
            'phone': phone.text.trim(),
          },
        );
        if (mounted) {
          _showMasterSnack(context, 'تم إنشاء العنوان');
          _reload();
        }
      } catch (error) {
        if (mounted) _showMasterSnack(context, error.toString());
      }
    }
    title.dispose();
    city.dispose();
    district.dispose();
    phone.dispose();
  }

  Future<void> _showAddressEditor(_SavedAddressRecord address) async {
    final titleController = TextEditingController(text: address.title);
    final cityController = TextEditingController(text: address.city);
    final districtController = TextEditingController(text: address.district);
    final phoneController = TextEditingController(text: address.userPhone);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('تعديل العنوان', textAlign: TextAlign.right),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'اسم العنوان',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: cityController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'المدينة',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: districtController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'الشارع / الحي',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.start,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.save_outlined),
              label: const Text('حفظ'),
            ),
          ],
        );
      },
    );
    if (saved == true && mounted) {
      await _runAddressAction(
        address,
        action: 'address_update',
        successMessage: 'تم حفظ العنوان',
        data: {
          'title': titleController.text.trim(),
          'city': cityController.text.trim(),
          'district': districtController.text.trim(),
          'phone': phoneController.text.trim(),
        },
      );
    }
    titleController.dispose();
    cityController.dispose();
    districtController.dispose();
    phoneController.dispose();
  }
}

class _MasterUsersData {
  const _MasterUsersData({
    required this.users,
    required this.addresses,
    required this.recipients,
    required this.favorites,
    required this.orders,
  });

  final List<_UserRecord> users;
  final List<_SavedAddressRecord> addresses;
  final List<_SavedRecipientRecord> recipients;
  final List<_FavoriteRecord> favorites;
  final List<_UserOrderRecord> orders;

  factory _MasterUsersData.empty() {
    return const _MasterUsersData(
      users: <_UserRecord>[],
      addresses: <_SavedAddressRecord>[],
      recipients: <_SavedRecipientRecord>[],
      favorites: <_FavoriteRecord>[],
      orders: <_UserOrderRecord>[],
    );
  }

  factory _MasterUsersData.fromJson(Map<String, dynamic> json) {
    return _MasterUsersData(
      users: _asMapList(json['users']).map(_UserRecord.fromJson).toList(),
      addresses: _asMapList(
        json['addresses'],
      ).map(_SavedAddressRecord.fromJson).toList(),
      recipients: _asMapList(
        json['recipients'],
      ).map(_SavedRecipientRecord.fromJson).toList(),
      favorites: _asMapList(
        json['favorites'],
      ).map(_FavoriteRecord.fromJson).toList(),
      orders: _asMapList(
        json['orders'],
      ).map(_UserOrderRecord.fromJson).toList(),
    );
  }
}

class _UserOrderRecord {
  const _UserOrderRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.status,
    required this.total,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String userName;
  final String userPhone;
  final String status;
  final String total;
  final String createdAt;

  factory _UserOrderRecord.fromJson(Map<String, dynamic> json) {
    return _UserOrderRecord(
      id: _toInt(json['order_id'] ?? json['id']),
      userId: _toInt(json['user_id']),
      userName: (json['user_name'] ?? '').toString(),
      userPhone: (json['user_phone'] ?? '').toString(),
      status: (json['status'] ?? 'غير محدد').toString(),
      total: (json['total'] ?? '0').toString(),
      createdAt: (json['created_at'] ?? '-').toString(),
    );
  }
}

class _UserRecord {
  const _UserRecord({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.country,
    required this.city,
    required this.typeLabel,
    required this.ordersCount,
    required this.totalSpendLabel,
    required this.lastOrderDate,
    required this.lastOrderTime,
    required this.status,
    required this.avatarUrl,
    required this.walletBalanceLabel,
    required this.walletExists,
    required this.walletPoints,
    required this.refundPoints,
    required this.refundAmountLabel,
    required this.lastRefundDate,
    required this.lastRefundTime,
    required this.favoriteCount,
    required this.savedAddressCount,
    required this.cartItemsCount,
    required this.userCouponsCount,
    required this.spinsCount,
    required this.referralsCount,
    required this.ratingAverage,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String country;
  final String city;
  final String typeLabel;
  final int ordersCount;
  final String totalSpendLabel;
  final String lastOrderDate;
  final String lastOrderTime;
  final String status;
  final String avatarUrl;
  final String walletBalanceLabel;
  final bool walletExists;
  final int walletPoints;
  final int refundPoints;
  final String refundAmountLabel;
  final String lastRefundDate;
  final String lastRefundTime;
  final int favoriteCount;
  final int savedAddressCount;
  final int cartItemsCount;
  final int userCouponsCount;
  final int spinsCount;
  final int referralsCount;
  final double ratingAverage;

  factory _UserRecord.fromJson(Map<String, dynamic> json) {
    final id = (json['users_id'] ?? json['id'] ?? '').toString();
    final imageName = (json['users_image'] ?? json['image'] ?? '')
        .toString()
        .trim();
    final status = _toInt(json['users_approve'] ?? json['approve'], 1) == 1
        ? 'نشط'
        : 'غير مفعل';
    final spendValue = (json['total_spend'] ?? '0').toString();
    final walletValue = (json['wallet_balance'] ?? '0').toString();

    return _UserRecord(
      id: id.isEmpty ? 'U-UNKNOWN' : id,
      name: (json['users_name'] ?? json['name'] ?? 'مستخدم').toString(),
      email: (json['users_email'] ?? json['email'] ?? '').toString(),
      phone: (json['users_phone'] ?? json['phone'] ?? '').toString(),
      country: (json['country'] ?? '-').toString(),
      city: (json['city'] ?? '-').toString(),
      typeLabel: status,
      ordersCount: _toInt(json['orders_count'] ?? json['orders']),
      totalSpendLabel:
          '${_normalizeUtf8Text(spendValue)} ${MasterCurrency.symbol}',
      lastOrderDate: (json['last_order_date'] ?? '-').toString(),
      lastOrderTime: (json['last_order_time'] ?? '-').toString(),
      status: status,
      avatarUrl: imageName.isEmpty
          ? ''
          : _masterMediaUrl('uploads/users/img/$imageName'),
      walletBalanceLabel: '$walletValue ${MasterCurrency.symbol}',
      walletExists:
          json['wallet_exists'] == true ||
          json['wallet_exists'] == 1 ||
          json['wallet_exists']?.toString() == '1',
      walletPoints: _toInt(json['wallet_points']),
      refundPoints: _toInt(json['refund_points']),
      refundAmountLabel: (json['refund_amount'] ?? '0').toString(),
      lastRefundDate: (json['last_refund_date'] ?? '-').toString(),
      lastRefundTime: (json['last_refund_time'] ?? '-').toString(),
      favoriteCount: _toInt(json['favorites_count']),
      savedAddressCount: _toInt(json['saved_addresses_count']),
      cartItemsCount: _toInt(json['cart_items_count']),
      userCouponsCount: _toInt(json['user_coupons_count']),
      spinsCount: _toInt(json['spins_count']),
      referralsCount: _toInt(json['referrals_count']),
      ratingAverage: _parseMasterDouble(json['rating_average']),
    );
  }
}

String _masterMediaUrl(String relativePath) {
  final trimmed = relativePath.trim();
  if (trimmed.isEmpty) {
    return '';
  }
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  return '$_kApiBaseUrl$trimmed';
}

double _parseMasterDouble(dynamic value, [double fallback = 0]) {
  if (value == null) {
    return fallback;
  }
  if (value is num) {
    return value.toDouble();
  }
  final normalized = value.toString().replaceAll(',', '.').trim();
  return double.tryParse(normalized) ?? fallback;
}

List<_OperationsStatCardData> _buildUserStatCards(List<_UserRecord> users) {
  final activeCount = users
      .where((user) => user.status.trim().contains('نشط'))
      .length;
  final totalSpend = users.fold<double>(
    0,
    (sum, user) => sum + _numericUserValue(user.totalSpendLabel),
  );
  final totalOrders = users.fold<int>(0, (sum, user) => sum + user.ordersCount);
  final totalWallets = users.fold<double>(
    0,
    (sum, user) => sum + _numericUserValue(user.walletBalanceLabel),
  );
  final walletsWithBalance = users
      .where((user) => _numericUserValue(user.walletBalanceLabel) > 0)
      .length;

  return [
    _OperationsStatCardData(
      title: 'إجمالي الإنفاق',
      value: _formatUserWholeNumber(totalSpend),
      icon: Icons.payments_outlined,
      accent: const Color(0xFFEF4444),
      background: const Color(0xFFFDECEC),
      detailLine: '${MasterCurrency.symbol}',
      trendLabel: '${users.length}',
      trendCaption: 'مستخدم',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'إجمالي الطلبات',
      value: _formatUserWholeNumber(totalOrders),
      icon: Icons.star_outline_rounded,
      accent: const Color(0xFF0B8F4D),
      background: const Color(0xFFF3E8FF),
      detailLine: 'طلب',
      trendLabel: '$activeCount',
      trendCaption: 'مستخدم نشط',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'إجمالي المحافظ',
      value: _formatUserWholeNumber(totalWallets),
      icon: Icons.account_balance_wallet_outlined,
      accent: const Color(0xFFF59E0B),
      background: const Color(0xFFFFF3DF),
      detailLine: 'محفظة',
      trendLabel: '$walletsWithBalance',
      trendCaption: 'محفظة برصيد',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'مستخدمون جدد',
      value: _formatUserWholeNumber(users.length),
      icon: Icons.person_add_alt_1_outlined,
      accent: const Color(0xFF60A5FA),
      background: const Color(0xFFEAF3FF),
      detailLine: 'مستخدم',
      trendLabel: '$activeCount',
      trendCaption: 'نشط',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'مستخدمون نشطون',
      value: _formatUserWholeNumber(activeCount),
      icon: Icons.check_circle_outline_rounded,
      accent: const Color(0xFF22C55E),
      background: const Color(0xFFEAF7EE),
      detailLine: 'مستخدم',
      trendLabel: '${users.length}',
      trendCaption: 'إجمالي',
      trendPositive: true,
    ),
    _OperationsStatCardData(
      title: 'إجمالي المستخدمين',
      value: _formatUserWholeNumber(users.length),
      icon: Icons.groups_2_outlined,
      accent: const Color(0xFF0B8F4D),
      background: const Color(0xFFF3E8FF),
      detailLine: 'مستخدم',
      trendLabel: '$activeCount',
      trendCaption: 'نشط',
      trendPositive: true,
    ),
  ];
}

String _usersFilterLabel(String value) {
  const labels = {
    'all': 'الكل',
    'active': 'نشط',
    'inactive': 'غير نشط',
    'blocked': 'موقوف',
    'sa': 'السعودية',
    'ae': 'الإمارات',
    'kw': 'الكويت',
    'riyadh': 'الرياض',
    'jeddah': 'جدة',
    'dubai': 'دبي',
  };
  return labels[value] ?? value;
}

class _UsersFiltersBar extends StatelessWidget {
  const _UsersFiltersBar({
    required this.activeTab,
    required this.searchController,
    required this.onSubmitted,
    required this.onPrimaryPressed,
    required this.statusFilter,
    required this.countryFilter,
    required this.cityFilter,
    required this.onStatusChanged,
    required this.onCountryChanged,
    required this.onCityChanged,
    required this.onAdvancedPressed,
  });

  final String activeTab;
  final TextEditingController searchController;
  final VoidCallback onSubmitted;
  final VoidCallback onPrimaryPressed;
  final String statusFilter;
  final String countryFilter;
  final String cityFilter;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onCountryChanged;
  final ValueChanged<String> onCityChanged;
  final VoidCallback onAdvancedPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          ElevatedButton.icon(
            onPressed: onPrimaryPressed,
            icon: const Icon(Icons.add_rounded),
            label: Text(_usersPrimaryActionText(activeTab)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B8F4D),
              foregroundColor: Colors.white,
              minimumSize: const Size(138, 44),
            ),
          ),
          const SizedBox(width: 10),
          _OrdersFilterButton(
            label: _usersFilterLabel(statusFilter),
            options: const {
              'all': 'جميع الحالات',
              'active': 'نشط',
              'inactive': 'غير نشط',
              'blocked': 'موقوف',
            },
            onChanged: onStatusChanged,
          ),
          const SizedBox(width: 8),
          _OrdersFilterButton(
            label: _usersFilterLabel(countryFilter),
            options: const {
              'all': 'جميع الدول',
              'sa': 'السعودية',
              'ae': 'الإمارات',
              'kw': 'الكويت',
            },
            onChanged: onCountryChanged,
          ),
          const SizedBox(width: 8),
          _OrdersFilterButton(
            label: _usersFilterLabel(cityFilter),
            options: const {
              'all': 'جميع المدن',
              'riyadh': 'الرياض',
              'jeddah': 'جدة',
              'dubai': 'دبي',
            },
            onChanged: onCityChanged,
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onAdvancedPressed,
            icon: const Icon(Icons.filter_alt_outlined, size: 16),
            label: const Text('تصفية متقدمة'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(126, 42)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _DeliverySearchBox(
              controller: searchController,
              hint: _usersSearchHint(activeTab),
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

class _UsersTopTabs extends StatelessWidget {
  const _UsersTopTabs({required this.activeTab, required this.onTabSelected});

  final String activeTab;
  final ValueChanged<String> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('users', 'المستخدمون', Icons.person_outline),
      ('wallets', 'المحافظ', Icons.account_balance_wallet_outlined),
      ('addresses', 'العناوين المحفوظة', Icons.location_on_outlined),
      ('recipients', 'المستلمون المحفوظون', Icons.star_border_rounded),
      ('favorites', 'المفضلات', Icons.favorite_border_rounded),
      ('orders', 'سجل الطلبات', Icons.receipt_long_outlined),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            Expanded(
              child: InkWell(
                onTap: () => onTabSelected(tabs[i].$1),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: activeTab == tabs[i].$1
                            ? const Color(0xFF0B8F4D)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(
                        tabs[i].$3,
                        size: 16,
                        color: activeTab == tabs[i].$1
                            ? const Color(0xFF0B8F4D)
                            : const Color(0xFF6F7680),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          tabs[i].$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.2,
                            fontWeight: activeTab == tabs[i].$1
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: activeTab == tabs[i].$1
                                ? const Color(0xFF0B8F4D)
                                : const Color(0xFF6F7680),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (i != tabs.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _UserDetailsPanel extends StatelessWidget {
  const _UserDetailsPanel({
    required this.user,
    required this.onEditUser,
    required this.onToggleUserStatus,
    required this.onDeleteUser,
    required this.onCallUser,
    required this.onMessageUser,
    required this.onOrdersUser,
  });

  final _UserRecord user;
  final VoidCallback onEditUser;
  final VoidCallback onToggleUserStatus;
  final VoidCallback onDeleteUser;
  final VoidCallback onCallUser;
  final VoidCallback onMessageUser;
  final VoidCallback onOrdersUser;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'تفاصيل المستخدم',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _statusPill(user.status),
            ),
            const SizedBox(height: 10),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                _AvatarThumb(url: user.avatarUrl, name: user.name, size: 58),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        user.name,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${user.id}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Color(0xFF6F7680)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          _statusPill(user.typeLabel),
                          const SizedBox(width: 8),
                          _statusPill(user.status),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              textDirection: TextDirection.rtl,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _quickUserAction(
                  context,
                  Icons.edit_outlined,
                  'تعديل',
                  onTap: onEditUser,
                ),
                _quickUserAction(
                  context,
                  Icons.call_outlined,
                  'اتصال',
                  onTap: onCallUser,
                ),
                _quickUserAction(
                  context,
                  Icons.event_note_outlined,
                  'عرض الطلبات',
                  onTap: onOrdersUser,
                ),
                _quickUserAction(
                  context,
                  Icons.chat_bubble_outline_rounded,
                  'رسالة',
                  onTap: onMessageUser,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const _InlineTabsBar(
              tabs: [
                'نظرة عامة',
                'المحفظة',
                'العناوين',
                'المفضلات',
                'الملاحظات',
              ],
              active: 'نظرة عامة',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              textDirection: TextDirection.rtl,
              children: [
                _detailMetricCard('إجمالي الطلبات', '${user.ordersCount} طلب'),
                _detailMetricCard('إجمالي الإنفاق', user.totalSpendLabel),
                _detailMetricCard(
                  'متوسط الطلب',
                  user.ordersCount > 0 ? ' ${MasterCurrency.symbol}' : '-',
                ),
                _detailMetricCard('المحفظة', user.walletBalanceLabel),
                _detailMetricCard('المفضلات', '${user.favoriteCount}'),
                _detailMetricCard('العناوين', '${user.savedAddressCount}'),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'معلومات الاتصال',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13.2, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            _detailLine(Icons.call_outlined, 'الهاتف', user.phone),
            _detailLine(Icons.email_outlined, 'البريد الإلكتروني', user.email),
            _detailLine(
              Icons.location_on_outlined,
              'المدينة',
              '${user.country} - ${user.city}',
            ),
            _detailLine(
              Icons.calendar_today_outlined,
              'تاريخ الانضمام',
              user.lastOrderDate != '-' ? user.lastOrderDate : '-',
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onToggleUserStatus,
                icon: const Icon(
                  Icons.block_outlined,
                  color: Color(0xFFDC2626),
                ),
                label: Text(
                  user.status.contains('نشط')
                      ? 'حظر المستخدم'
                      : 'فك حظر المستخدم',
                  style: const TextStyle(color: Color(0xFFDC2626)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onDeleteUser,
                icon: const Icon(
                  Icons.delete_outline,
                  color: Color(0xFFDC2626),
                ),
                label: const Text(
                  'حذف آمن للمستخدم',
                  style: TextStyle(color: Color(0xFFDC2626)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickUserAction(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap ?? () => _showMasterSnack(context, label),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE7ECE8)),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF4E5660)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9.8),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersRightSidebar extends StatelessWidget {
  const _UsersRightSidebar({
    required this.activeSubPage,
    required this.onSubPageTap,
    required this.onHomeTap,
    required this.onOperationsTap,
    required this.onOrdersTap,
    required this.onLogisticsTap,
    required this.onRestaurantsTap,
    required this.onFinanceTap,
    required this.onMarketingTap,
    required this.onCollapse,
  });

  final String activeSubPage;
  final ValueChanged<String> onSubPageTap;
  final VoidCallback onHomeTap;
  final VoidCallback onOperationsTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onLogisticsTap;
  final VoidCallback onRestaurantsTap;
  final VoidCallback onFinanceTap;
  final VoidCallback onMarketingTap;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final submenuItems = [
      ('users', 'المستخدمون', Icons.people_alt_outlined),
      ('wallets', 'المحافظ', Icons.account_balance_wallet_outlined),
      ('addresses', 'العناوين المحفوظة', Icons.bookmark_outline_rounded),
      ('recipients', 'المستلمون المحفوظون', Icons.star_border_rounded),
      ('favorites', 'المفضلات', Icons.favorite_border_rounded),
      ('orders', 'سجل الطلبات', Icons.receipt_long_outlined),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7ECE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                textDirection: TextDirection.rtl,
                children: [
                  const Expanded(
                    child: Text(
                      'التنقل',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _OrdersSidebarToggleButton(
                    tooltip: 'إخفاء القائمة الجانبية',
                    icon: Icons.keyboard_double_arrow_right_rounded,
                    active: true,
                    onTap: onCollapse,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _OperationsSidebarMainItem(
                label: 'الرئيسية',
                icon: Icons.home_rounded,
                selected: false,
                onTap: onHomeTap,
              ),
              const SizedBox(height: 10),
              _OperationsSidebarMainItem(
                label: 'لوحة العمليات',
                icon: Icons.grid_view_rounded,
                selected: false,
                onTap: onOperationsTap,
              ),
              const SizedBox(height: 10),
              _OperationsSidebarMainItem(
                label: 'إدارة الطلبات',
                icon: Icons.receipt_long_outlined,
                selected: false,
                onTap: onOrdersTap,
              ),
              const SizedBox(height: 10),
              _OperationsSidebarMainItem(
                label: 'التوصيل واللوجستيات',
                icon: Icons.delivery_dining_outlined,
                selected: false,
                onTap: onLogisticsTap,
              ),
              const SizedBox(height: 10),
              _OperationsSidebarMainItem(
                label: 'إدارة المطاعم',
                icon: Icons.storefront_outlined,
                selected: false,
                onTap: onRestaurantsTap,
              ),
              const SizedBox(height: 10),
              _OperationsSidebarMainItem(
                label: 'إدارة العملاء والمستخدمين',
                icon: Icons.people_alt_outlined,
                selected: true,
                onTap: () {},
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFDFD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7ECE8)),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < submenuItems.length; i++) ...[
                      Builder(
                        builder: (context) {
                          final item = submenuItems[i];
                          final selected = activeSubPage == item.$1;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => onSubPageTap(item.$1),
                              child: Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFF1F8F4)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Icon(
                                      item.$3,
                                      size: 16,
                                      color: selected
                                          ? _kPrimaryGreen
                                          : const Color(0xFF4E5660),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.$2,
                                        textAlign: TextAlign.right,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11.6,
                                          fontWeight: selected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: selected
                                              ? _kPrimaryGreen
                                              : const Color(0xFF4E5660),
                                        ),
                                      ),
                                    ),
                                    if (selected)
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: _kPrimaryGreen,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (i != submenuItems.length - 1)
                        const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final item in const [
                _OperationsSidebarTileData(
                  label: 'الإدارة المالية',
                  icon: Icons.account_balance_wallet_outlined,
                ),
                _OperationsSidebarTileData(
                  label: 'التسويق والنمو',
                  icon: Icons.campaign_outlined,
                ),
                _OperationsSidebarTileData(
                  label: 'مركز التواصل',
                  icon: Icons.notifications_active_outlined,
                ),
                // 'الجودة وخدمة العملاء' removed per user request
                _OperationsSidebarTileData(
                  label: 'التقارير والتحليلات',
                  icon: Icons.query_stats_outlined,
                ),
                _OperationsSidebarTileData(
                  label: 'إعدادات المنصة',
                  icon: Icons.settings_outlined,
                ),
                _OperationsSidebarTileData(
                  label: 'الإدارة والصلاحيات',
                  icon: Icons.admin_panel_settings_outlined,
                ),
              ]) ...[
                _OperationsSidebarMenuItem(
                  data: item,
                  onTap: () {
                    if (item.icon == Icons.account_balance_wallet_outlined) {
                      onFinanceTap();
                    } else if (item.icon == Icons.campaign_outlined) {
                      onMarketingTap();
                    } else if (item.icon ==
                        Icons.notifications_active_outlined) {
                      _navigateToRememberedMasterSection(
                        context,
                        'communication',
                      );
                    } else if (item.icon == Icons.query_stats_outlined) {
                      _navigateToRememberedMasterSection(context, 'reports');
                    } else if (item.icon == Icons.settings_outlined) {
                      _navigateToRememberedMasterSection(context, 'settings');
                    } else if (item.icon ==
                        Icons.admin_panel_settings_outlined) {
                      _navigateToRememberedMasterSection(context, 'access');
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersOrdersWorkspace extends StatelessWidget {
  const _UsersOrdersWorkspace({required this.orders});

  final List<_UserOrderRecord> orders;

  @override
  Widget build(BuildContext context) {
    return _RestaurantShellCard(
      title: 'سجل طلبات العملاء',
      child: orders.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'لا توجد طلبات مرتبطة بالعملاء حالياً',
                  style: TextStyle(
                    color: Color(0xFF6F7680),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final order = orders[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAF9),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE3EAE6)),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: Color(0xFF0B8F4D),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '#${order.id} · ${order.userName.isEmpty ? 'عميل غير معروف' : order.userName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.status} · ${order.createdAt}',
                              style: const TextStyle(
                                color: Color(0xFF6F7680),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${order.total} ${MasterCurrency.symbol}',
                        style: const TextStyle(
                          color: Color(0xFF0B8F4D),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _InlineTabsBar extends StatelessWidget {
  const _InlineTabsBar({required this.tabs, required this.active});

  final List<String> tabs;
  final String active;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: tabs[i] == active
                        ? const Color(0xFF0B8F4D)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tabs[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.2,
                  fontWeight: tabs[i] == active
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: tabs[i] == active
                      ? const Color(0xFF0B8F4D)
                      : const Color(0xFF6F7680),
                ),
              ),
            ),
          ),
          if (i != tabs.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _AvatarThumb extends StatelessWidget {
  const _AvatarThumb({required this.url, required this.name, this.size = 44});

  final String url;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? 'م'
        : name.trim().split(' ').take(2).map((part) => part[0]).join();
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF1F5F9),
      ),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, _, _) => Center(
          child: Text(
            initials,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}
