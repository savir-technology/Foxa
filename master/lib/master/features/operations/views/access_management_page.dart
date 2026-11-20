// ignore_for_file: unused_element

part of '../../../../master_auth_app.dart';

class MasterAccessManagementPage extends StatefulWidget {
  const MasterAccessManagementPage({
    super.key,
    required this.session,
    required this.onLogout,
    this.api,
    this.serverNow,
    this.initialSubPage = 'overview',
  });

  final MasterSession session;
  final Future<void> Function() onLogout;
  final MasterAuthApiService? api;
  final DateTime? serverNow;
  final String initialSubPage;

  @override
  State<MasterAccessManagementPage> createState() =>
      _MasterAccessManagementPageState();
}

class _MasterAccessManagementPageState
    extends State<MasterAccessManagementPage> {
  late String _activeSubPage;
  late Future<_AccessManagementData> _accessFuture;
  final TextEditingController _employeeSearchController =
      TextEditingController();
  final TextEditingController _roleSearchController = TextEditingController();
  String _adminSearchQuery = '';
  String _adminRoleFilter = 'all';
  String _roleSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _activeSubPage = widget.initialSubPage;
    _accessFuture = _loadAccessData();
  }

  @override
  void dispose() {
    _employeeSearchController.dispose();
    _roleSearchController.dispose();
    super.dispose();
  }

  bool _isSuperAdmin() {
    final roleName = (widget.session.master.role?.roleName ?? '')
        .trim()
        .toLowerCase();
    final permissions =
        widget.session.master.role?.permissions ?? const <String>[];
    final normalizedPermissions = permissions
        .map((permission) => permission.trim().toLowerCase())
        .toSet();

    return widget.session.master.adminRoleId == 1 ||
        normalizedPermissions.contains('super_admin') ||
        normalizedPermissions.contains('*') ||
        roleName.contains('super') ||
        roleName.contains('سوبر');
  }

  bool _hasPermission(String permissionKey) {
    if (_isSuperAdmin()) {
      return true;
    }

    final permissions =
        widget.session.master.role?.permissions ?? const <String>[];
    final normalizedPermissions = permissions
        .map((permission) => permission.trim().toLowerCase())
        .toSet();
    final normalizedPermissionKey = permissionKey.trim().toLowerCase();

    return normalizedPermissions.contains(normalizedPermissionKey);
  }

  void _setAdminSearch(String value) {
    setState(() => _adminSearchQuery = value.trim());
  }

  void _setAdminRoleFilter(String value) {
    setState(() => _adminRoleFilter = value);
  }

  void _setRoleSearch(String value) {
    setState(() => _roleSearchQuery = value.trim());
  }

  Future<void> _refreshAccessData() async {
    setState(() {
      _accessFuture = _loadAccessData();
    });
  }

  Future<void> _updateReturnStatus(
    _AccessGenericRecord item,
    String status,
  ) async {
    if (item.id <= 0 || widget.api == null) return;
    try {
      await widget.api!.updateMasterReturnStatus(
        widget.session.token,
        returnId: item.id,
        statusLabel: status,
      );
      if (!mounted) return;
      _showMasterSnack(context, 'تم تحديث حالة طلب الإرجاع');
      await _refreshAccessData();
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, _extractErrorMessage(error));
      }
    }
  }

  Future<void> _toggleStockRule(_AccessGenericRecord item) async {
    if (item.id <= 0 || widget.api == null) return;
    try {
      final isActive =
          item.status.toLowerCase().contains('active') ||
          item.status.contains('نشط');
      await widget.api!.updateMasterStockRuleStatus(
        widget.session.token,
        ruleId: item.id,
        isActive: !isActive,
      );
      if (!mounted) return;
      _showMasterSnack(context, 'تم تحديث قاعدة المخزون');
      await _refreshAccessData();
    } catch (error) {
      if (mounted) _showMasterSnack(context, _extractErrorMessage(error));
    }
  }

  Future<void> _toggleScheduledReport(_AccessGenericRecord item) async {
    if (item.id <= 0 || widget.api == null) return;
    try {
      final isActive = item.status.toLowerCase() == 'active';
      await widget.api!.updateMasterScheduledReportStatus(
        widget.session.token,
        reportId: item.id,
        isActive: !isActive,
      );
      if (!mounted) return;
      _showMasterSnack(context, 'تم تحديث حالة التقرير المجدول');
      await _refreshAccessData();
    } catch (error) {
      if (mounted) _showMasterSnack(context, _extractErrorMessage(error));
    }
  }

  Future<void> _checkDeploymentHealth() async {
    if (widget.api == null) return;
    try {
      final health = await widget.api!.fetchMasterDeploymentHealth(
        widget.session.token,
      );
      if (!mounted) return;
      final missing = health['missing_tables'];
      final missingCount = missing is List ? missing.length : 0;
      final databaseReady = health['database_ready'] == true;
      _showMasterSnack(
        context,
        databaseReady && missingCount == 0
            ? 'فحص الجاهزية ناجح: قاعدة البيانات والجداول الأساسية متاحة'
            : 'فحص الجاهزية: توجد $missingCount جداول ناقصة أو مشكلة اتصال',
      );
    } catch (error) {
      if (mounted) _showMasterSnack(context, _extractErrorMessage(error));
    }
  }

  Future<String?> _promptForPassword(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('إعادة تعيين كلمة المرور'),
          content: TextField(
            controller: controller,
            obscureText: true,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
    return result?.trim().isNotEmpty == true ? result!.trim() : null;
  }

  BuildContext? _currentContextOrNull() {
    if (!mounted) {
      return null;
    }
    return context;
  }

  Future<bool> _confirmDangerAction(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content, textDirection: TextDirection.rtl),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  String _extractErrorMessage(Object? error) {
    if (error is MasterApiException) {
      return error.message;
    }
    if (error is Exception) {
      return error.toString();
    }
    if (error is String && error.trim().isNotEmpty) {
      return error;
    }
    return 'حدث خطأ غير متوقع';
  }

  Future<_AccessManagementData> _loadAccessData() async {
    final api = widget.api;
    if (api == null) {
      throw MasterApiException('Master API client is required');
    }
    final raw = await api
        ._fetchMasterAdministrationOverviewRaw(widget.session.token)
        .timeout(const Duration(seconds: 20));
    final roles = _asMapList(
      raw['roles'],
    ).map(MasterRoleProfile.fromJson).toList();
    return _AccessManagementData.fromRaw(roles: roles, raw: raw);
  }

  void _setSubPage(String value) {
    setState(() => _activeSubPage = value);
  }

  Future<void> _showAdminEditorDialog({
    _AccessEmployeeRecord? existing,
    required List<MasterRoleProfile> roles,
  }) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final passwordController = TextEditingController();
    final roleOptions = roles
        .where((role) => role.roleName.isNotEmpty)
        .toList();
    String selectedRoleValue = existing != null
        ? existing.roleId.toString()
        : (roleOptions.isNotEmpty ? roleOptions.first.roleId.toString() : '');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          title: Text(existing == null ? 'إضافة مسؤول جديد' : 'تعديل المسؤول'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    textDirection: TextDirection.rtl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    textDirection: TextDirection.rtl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  ),
                  const SizedBox(height: 10),
                  if (existing == null)
                    TextField(
                      controller: passwordController,
                      textDirection: TextDirection.rtl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور',
                      ),
                    ),
                  if (existing == null) const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue:
                        roleOptions.any(
                          (role) => role.roleId.toString() == selectedRoleValue,
                        )
                        ? selectedRoleValue
                        : (roleOptions.isNotEmpty
                              ? roleOptions.first.roleId.toString()
                              : null),
                    decoration: const InputDecoration(labelText: 'الدور'),
                    items: roleOptions
                        .map(
                          (role) => DropdownMenuItem<String>(
                            value: role.roleId.toString(),
                            child: Text(role.roleName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedRoleValue = value;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(existing == null ? 'إنشاء' : 'حفظ'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      return;
    }

    MasterRoleProfile? role;
    for (final item in roleOptions) {
      if (item.roleId.toString() == selectedRoleValue) {
        role = item;
        break;
      }
    }
    final roleId = role?.roleId ?? 0;

    try {
      if (existing == null) {
        await widget.api!.createAdministrator(
          widget.session.token,
          adminName: nameController.text.trim(),
          email: emailController.text.trim(),
          phone: phoneController.text.trim(),
          password: passwordController.text,
          roleId: roleId,
        );
      } else {
        await widget.api!.updateAdministrator(
          widget.session.token,
          adminId: existing.adminId,
          adminName: nameController.text.trim(),
          email: emailController.text.trim(),
          phone: phoneController.text.trim(),
          roleId: roleId,
        );
      }
      if (mounted) {
        _showMasterSnack(
          context,
          existing == null
              ? 'تم إنشاء المسؤول بنجاح'
              : 'تم تعديل المسؤول بنجاح',
        );
        await _refreshAccessData();
      }
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, error.toString());
      }
    }
  }

  // دوال مساعدة للتعامل مع الأقسام والأذونات
  List<String> getPermissionsForSection(String sectionKey) {
    switch (sectionKey) {
      case 'dashboard':
        return ['dashboard.view'];
      case 'restaurants':
        return [
          'restaurants.view',
          'restaurants.approve',
          'restaurants.reject',
          'restaurants.suspend',
          'restaurants.delete',
          'restaurants.edit',
        ];
      case 'drivers':
        return [
          'drivers.view',
          'drivers.approve',
          'drivers.reject',
          'drivers.suspend',
          'drivers.delete',
          'drivers.edit',
        ];
      case 'orders':
        return [
          'orders.view',
          'orders.edit',
          'orders.cancel',
          'orders.assign_driver',
        ];
      case 'customers':
        return ['customers.view', 'customers.edit', 'customers.block'];
      case 'coupons':
        return [
          'coupons.view',
          'coupons.create',
          'coupons.edit',
          'coupons.delete',
        ];
      case 'reports':
        return ['reports.view', 'reports.export'];
      case 'finance':
        return ['finance.view', 'finance.refund', 'finance.withdrawals'];
      case 'notifications':
        return ['notifications.send'];
      case 'settings':
        return ['settings.view', 'settings.edit'];
      case 'administration':
        return [
          'administration.view',
          'administration.create',
          'administration.edit',
          'administration.delete',
          'administration.manage_roles',
        ];
      default:
        return [];
    }
  }

  List<String> selectedPermissionsBySection(
    String sectionKey, {
    Set<String>? selected,
  }) {
    final sectionPermissions = getPermissionsForSection(sectionKey);
    return sectionPermissions
        .where((permission) => selected?.contains(permission) ?? false)
        .toList();
  }

  void addPermissionsForSection(String sectionKey, {Set<String>? selected}) {
    final sectionPermissions = getPermissionsForSection(sectionKey);
    for (final permission in sectionPermissions) {
      if (selected != null && !selected.contains(permission)) {
        selected.add(permission);
      }
    }
  }

  void removePermissionsForSection(String sectionKey, {Set<String>? selected}) {
    final sectionPermissions = getPermissionsForSection(sectionKey);
    for (final permission in sectionPermissions) {
      selected?.remove(permission);
    }
  }

  Future<void> _showRoleEditorDialog({MasterRoleProfile? existing}) async {
    final nameController = TextEditingController(
      text: existing?.roleName ?? '',
    );
    final scopeController = TextEditingController(
      text: existing?.roleScope ?? '',
    );
    final tintController = TextEditingController(
      text: existing?.tintHex ?? '#3B82F6',
    );
    final sortController = TextEditingController(
      text: existing?.sortOrder.toString() ?? '100',
    );
    final selected = <String>{...(existing?.permissions ?? const <String>[])};
    // الأقسام المتاحة في النظام
    final availableSections = [
      {'key': 'dashboard', 'name': 'لوحة التحكم', 'icon': Icons.dashboard},
      {'key': 'restaurants', 'name': 'إدارة المطاعم', 'icon': Icons.restaurant},
      {
        'key': 'drivers',
        'name': 'إدارة السائقين',
        'icon': Icons.local_shipping,
      },
      {'key': 'orders', 'name': 'إدارة الطلبات', 'icon': Icons.receipt_long},
      {'key': 'customers', 'name': 'إدارة العملاء', 'icon': Icons.people},
      {'key': 'finance', 'name': 'المالية', 'icon': Icons.attach_money},
      {'key': 'marketing', 'name': 'التسويق', 'icon': Icons.campaign},
      {'key': 'support', 'name': 'دعم العملاء', 'icon': Icons.support_agent},
      {'key': 'reports', 'name': 'التقارير', 'icon': Icons.assessment},
      {'key': 'settings', 'name': 'الإعدادات', 'icon': Icons.settings},
    ];

    // الأذونات العامة
    final permissionCatalog = <String>[
      // أذونات لوحة التحكم
      'dashboard.view',

      // أذونات المطاعم
      'restaurants.view',
      'restaurants.approve',
      'restaurants.reject',
      'restaurants.suspend',
      'restaurants.delete',
      'restaurants.edit',

      // أذونات السائقين
      'drivers.view',
      'drivers.approve',
      'drivers.reject',
      'drivers.suspend',
      'drivers.delete',
      'drivers.edit',

      // أذونات الطلبات
      'orders.view',
      'orders.edit',
      'orders.cancel',
      'orders.assign_driver',

      // أذونات العملاء
      'customers.view',
      'customers.edit',
      'customers.block',

      // أذونات الكوبونات
      'coupons.view',
      'coupons.create',
      'coupons.edit',
      'coupons.delete',

      // أذونات التقارير
      'reports.view',
      'reports.export',

      // أذونات المالية
      'finance.view',
      'finance.refund',
      'finance.withdrawals',

      // أذونات الإشعارات
      'notifications.send',

      // أذونات الإعدادات
      'settings.view',
      'settings.edit',

      // أذونات الإدارة
      'administration.view',
      'administration.create',
      'administration.edit',
      'administration.delete',
      'administration.manage_roles',

      // أذونات المسؤول المطلق
      'super_admin',
    ];

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setDialogState) {
            return AlertDialog(
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              title: Text(existing == null ? 'إنشاء دور جديد' : 'تعديل الدور'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: nameController,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          labelText: 'اسم الدور',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: scopeController,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          labelText: 'وصف الدور',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: tintController,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          labelText: 'لون الدور',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: sortController,
                        textDirection: TextDirection.rtl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'ترتيب العرض',
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'الأقسام الرئيسية',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: availableSections.map((section) {
                          final isSelected = selectedPermissionsBySection(
                            section['key'] as String,
                            selected: selected,
                          ).isNotEmpty;
                          return FilterChip(
                            label: Text(section['name'] as String),
                            selected: isSelected,
                            onSelected: (value) {
                              setDialogState(() {
                                if (value) {
                                  // إضافة جميع أذونات هذا القسم
                                  addPermissionsForSection(
                                    section['key'] as String,
                                    selected: selected,
                                  );
                                } else {
                                  // إزالة جميع أذونات هذا القسم
                                  removePermissionsForSection(
                                    section['key'] as String,
                                    selected: selected,
                                  );
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'الصلاحيات التفصيلية',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: permissionCatalog.map((permission) {
                          final checked = selected.contains(permission);
                          return FilterChip(
                            label: Text(permission),
                            selected: checked,
                            onSelected: (value) {
                              setDialogState(() {
                                if (value) {
                                  selected.add(permission);
                                } else {
                                  selected.remove(permission);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(existing == null ? 'إنشاء' : 'حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      return;
    }

    final permissions = selected.toList()..sort();
    try {
      if (existing == null) {
        await widget.api!.createRole(
          widget.session.token,
          roleName: nameController.text.trim(),
          roleScope: scopeController.text.trim(),
          permissions: permissions,
          tintHex: tintController.text.trim().isEmpty
              ? '#3B82F6'
              : tintController.text.trim(),
          sortOrder: int.tryParse(sortController.text.trim()) ?? 100,
        );
      } else {
        await widget.api!.updateRole(
          widget.session.token,
          roleId: existing.roleId,
          roleName: nameController.text.trim(),
          roleScope: scopeController.text.trim(),
          permissions: permissions,
          tintHex: tintController.text.trim().isEmpty
              ? '#3B82F6'
              : tintController.text.trim(),
          sortOrder: int.tryParse(sortController.text.trim()) ?? 100,
        );
      }
      if (mounted) {
        _showMasterSnack(
          context,
          existing == null ? 'تم إنشاء الدور بنجاح' : 'تم تعديل الدور بنجاح',
        );
        await _refreshAccessData();
      }
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, _extractErrorMessage(error));
      }
    }
  }

  Future<void> _handleAdminAction({
    required String action,
    int? adminId,
    String? password,
  }) async {
    if (widget.api == null) {
      return;
    }
    try {
      switch (action) {
        case 'toggle':
          await widget.api!.toggleAdministrator(
            widget.session.token,
            adminId: adminId ?? 0,
            enabled: true,
          );
          break;
        case 'disable':
          await widget.api!.toggleAdministrator(
            widget.session.token,
            adminId: adminId ?? 0,
            enabled: false,
          );
          break;
        case 'reset_password':
          if (password == null || password.trim().isEmpty) {
            _showMasterSnack(context, 'أدخل كلمة مرور جديدة');
            return;
          }
          await widget.api!.resetAdministratorPassword(
            widget.session.token,
            adminId: adminId ?? 0,
            password: password,
          );
          break;
        case 'delete':
          await widget.api!.deleteAdministrator(
            widget.session.token,
            adminId: adminId ?? 0,
          );
          break;
      }
      if (mounted) {
        await _refreshAccessData();
      }
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, _extractErrorMessage(error));
      }
    }
  }

  Future<void> _handleRoleAction({required String action, int? roleId}) async {
    if (widget.api == null) {
      return;
    }
    try {
      if (action == 'delete') {
        await widget.api!.deleteRole(widget.session.token, roleId: roleId ?? 0);
      }
      if (mounted) {
        await _refreshAccessData();
      }
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, _extractErrorMessage(error));
      }
    }
  }

  Future<void> _handleApprovalAction({
    required String type,
    required String action,
    required int id,
  }) async {
    if (widget.api == null) {
      return;
    }
    try {
      await widget.api!.approveAdministrationItem(
        widget.session.token,
        type: type,
        action: action,
        id: id,
      );
      if (mounted) {
        await _refreshAccessData();
      }
    } catch (error) {
      if (mounted) {
        _showMasterSnack(context, error.toString());
      }
    }
  }

  Future<void> onApproveRestaurant(_AccessApprovalRecord record) async {
    await _handleApprovalAction(
      type: 'restaurant',
      action: 'approve',
      id: record.id,
    );
  }

  Future<void> onRejectRestaurant(_AccessApprovalRecord record) async {
    await _handleApprovalAction(
      type: 'restaurant',
      action: 'reject',
      id: record.id,
    );
  }

  Future<void> onSuspendRestaurant(_AccessApprovalRecord record) async {
    await _handleApprovalAction(
      type: 'restaurant',
      action: 'suspend',
      id: record.id,
    );
  }

  Future<void> onApproveDriver(_AccessApprovalRecord record) async {
    await _handleApprovalAction(
      type: 'driver',
      action: 'approve',
      id: record.id,
    );
  }

  Future<void> onRejectDriver(_AccessApprovalRecord record) async {
    await _handleApprovalAction(
      type: 'driver',
      action: 'reject',
      id: record.id,
    );
  }

  Future<void> onSuspendDriver(_AccessApprovalRecord record) async {
    await _handleApprovalAction(
      type: 'driver',
      action: 'suspend',
      id: record.id,
    );
  }

  void _openSection(
    BuildContext context,
    String key, {
    String accessSubPage = 'overview',
  }) {
    _navigateToMasterSection(
      context,
      key: key,
      session: widget.session,
      onLogout: widget.onLogout,
      api: widget.api ?? MasterAuthApiService(),
      serverNow: widget.serverNow,
      accessSubPage: accessSubPage,
      replace: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final serverNow = widget.serverNow ?? DateTime.now();

    return FutureBuilder<_AccessManagementData>(
      future: _accessFuture,
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
                        'تعذر تحميل بيانات الإدارة',
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
                            _accessFuture = _loadAccessData();
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

        final accessData = snapshot.data ?? _AccessManagementData.empty();
        final roles = accessData.roles;
        final displayName = widget.session.master.adminName.trim().isNotEmpty
            ? widget.session.master.adminName.trim()
            : (widget.session.master.adminEmail.trim().isNotEmpty
                  ? widget.session.master.adminEmail.trim()
                  : 'Admin #${widget.session.master.adminId}');
        final roleLabel = _masterRoleArabicLabel(
          widget.session.master.adminRoleId,
          fallback: widget.session.master.role?.roleName,
        );

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFDFDFD),
                  Color(0xFFF7F8FA),
                  Color(0xFFF3F6F5),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // ignore: unused_local_variable
                    final sidebarWidth = constraints.maxWidth >= 1500
                        ? 314.0
                        : constraints.maxWidth >= 1320
                        ? 294.0
                        : 274.0;
                    // ignore: unused_local_variable
                    final header = _MasterOperationsTopBar(
                      displayName: displayName,
                      roleLabel: roleLabel,
                      notificationBadge: 12,
                      messageBadge: 5,
                      serverNow: serverNow,
                      statusLabel: 'مراقبة نشطة',
                      platformTitle: 'الإدارة والصلاحيات',
                      platformSubtitle: 'إدارة الموظفين والصلاحيات والرقابة',
                      onLogout: widget.onLogout,
                      onNotificationsTap: () =>
                          _openSection(context, 'notifications'),
                    );
                    final isSuperAdmin = _isSuperAdmin();
                    final canApproveRestaurants =
                        _hasPermission('restaurants.approve') || isSuperAdmin;
                    final canRejectRestaurants =
                        _hasPermission('restaurants.reject') || isSuperAdmin;
                    final canSuspendRestaurants =
                        _hasPermission('restaurants.suspend') || isSuperAdmin;
                    final canApproveDrivers =
                        _hasPermission('drivers.approve') || isSuperAdmin;
                    final canRejectDrivers =
                        _hasPermission('drivers.reject') || isSuperAdmin;
                    final canSuspendDrivers =
                        _hasPermission('drivers.suspend') || isSuperAdmin;
                    final canManageLegal =
                        _hasPermission('settings.view') || isSuperAdmin;

                    final content = _AccessSubPageContent(
                      master: widget.session.master,
                      activeSubPage: _activeSubPage,
                      roles: roles,
                      employees: accessData.employees,
                      activities: accessData.activities,
                      sessions: accessData.sessions,
                      onboardingQueue: accessData.onboardingQueue,
                      settlements: accessData.settlements,
                      fraudAlerts: accessData.fraudAlerts,
                      disputeCases: accessData.disputeCases,
                      broadcasts: accessData.broadcasts,
                      moderationQueue: accessData.moderationQueue,
                      returns: accessData.returns,
                      stockRules: accessData.stockRules,
                      onReturnStatusChanged: _updateReturnStatus,
                      onStockRuleToggle: _toggleStockRule,
                      onScheduledReportToggle: _toggleScheduledReport,
                      onHealthCheck: _checkDeploymentHealth,
                      scheduledExports: accessData.scheduledExports,
                      api: widget.api ?? MasterAuthApiService(),
                      token: widget.session.token,
                      pendingRestaurants: accessData.pendingRestaurants,
                      pendingDrivers: accessData.pendingDrivers,
                      serverNow: serverNow,
                      searchController: _employeeSearchController,
                      roleSearchController: _roleSearchController,
                      adminSearchQuery: _adminSearchQuery,
                      adminRoleFilter: _adminRoleFilter,
                      roleSearchQuery: _roleSearchQuery,
                      canManageAdministrators: isSuperAdmin,
                      canManageRoles: isSuperAdmin,
                      canApproveRestaurants: canApproveRestaurants,
                      canApproveDrivers: canApproveDrivers,
                      canManageLegal: canManageLegal,
                      onSubPageChanged: _setSubPage,
                      onAdminSearchChanged: _setAdminSearch,
                      onAdminRoleFilterChanged: _setAdminRoleFilter,
                      onRoleSearchChanged: _setRoleSearch,
                      onRefresh: _refreshAccessData,
                      onCreateAdministrator: isSuperAdmin
                          ? () => _showAdminEditorDialog(roles: roles)
                          : null,
                      onEditAdministrator: isSuperAdmin
                          ? (employee) => _showAdminEditorDialog(
                              existing: employee,
                              roles: roles,
                            )
                          : null,
                      onToggleAdministrator: isSuperAdmin
                          ? (employee, enabled) async {
                              await _handleAdminAction(
                                action: enabled ? 'toggle' : 'disable',
                                adminId: employee.adminId,
                              );
                            }
                          : null,
                      onResetPassword: isSuperAdmin
                          ? (employee) async {
                              final currentContext = _currentContextOrNull();
                              if (currentContext == null) {
                                return;
                              }
                              final confirmed = await _confirmDangerAction(
                                currentContext,
                                title: 'إعادة تعيين كلمة المرور',
                                content:
                                    'هل تريد حقًا إعادة تعيين كلمة مرور هذا الموظف؟',
                              );
                              if (!confirmed || !mounted) {
                                return;
                              }
                              if (!currentContext.mounted) {
                                return;
                              }
                              // ignore: use_build_context_synchronously
                              final password = await _promptForPassword(
                                currentContext,
                              );
                              if (password == null || !mounted) {
                                return;
                              }
                              await _handleAdminAction(
                                action: 'reset_password',
                                adminId: employee.adminId,
                                password: password,
                              );
                            }
                          : null,
                      onDeleteAdministrator: isSuperAdmin
                          ? (employee) async {
                              final currentContext = _currentContextOrNull();
                              if (currentContext == null) {
                                return;
                              }
                              final confirmed = await _confirmDangerAction(
                                currentContext,
                                title: 'حذف موظف',
                                content: 'هل تريد حذف هذا الموظف نهائيًا؟',
                              );
                              if (!confirmed || !mounted) {
                                return;
                              }
                              await _handleAdminAction(
                                action: 'delete',
                                adminId: employee.adminId,
                              );
                            }
                          : null,
                      onCreateRole: isSuperAdmin
                          ? () => _showRoleEditorDialog()
                          : null,
                      onEditRole: isSuperAdmin
                          ? (role) => _showRoleEditorDialog(existing: role)
                          : null,
                      onDeleteRole: isSuperAdmin
                          ? (role) async {
                              final currentContext = _currentContextOrNull();
                              if (currentContext == null) {
                                return;
                              }
                              final confirmed = await _confirmDangerAction(
                                currentContext,
                                title: 'حذف الدور',
                                content:
                                    'هل تريد حذف هذا الدور؟ قد يتأثر الموظفون المرتبطون به.',
                              );
                              if (!confirmed || !mounted) {
                                return;
                              }
                              await _handleRoleAction(
                                action: 'delete',
                                roleId: role.roleId,
                              );
                            }
                          : null,
                      onApproveRestaurant: canApproveRestaurants
                          ? (restaurant) async {
                              await _handleApprovalAction(
                                type: 'restaurant',
                                action: 'approve',
                                id: restaurant.id,
                              );
                            }
                          : null,
                      onRejectRestaurant: canRejectRestaurants
                          ? (restaurant) async {
                              await _handleApprovalAction(
                                type: 'restaurant',
                                action: 'reject',
                                id: restaurant.id,
                              );
                            }
                          : null,
                      onSuspendRestaurant: canSuspendRestaurants
                          ? (restaurant) async {
                              await _handleApprovalAction(
                                type: 'restaurant',
                                action: 'suspend',
                                id: restaurant.id,
                              );
                            }
                          : null,
                      onApproveDriver: canApproveDrivers
                          ? (driver) async {
                              await _handleApprovalAction(
                                type: 'driver',
                                action: 'approve',
                                id: driver.id,
                              );
                            }
                          : null,
                      onRejectDriver: canRejectDrivers
                          ? (driver) async {
                              await _handleApprovalAction(
                                type: 'driver',
                                action: 'reject',
                                id: driver.id,
                              );
                            }
                          : null,
                      onSuspendDriver: canSuspendDrivers
                          ? (driver) async {
                              await _handleApprovalAction(
                                type: 'driver',
                                action: 'suspend',
                                id: driver.id,
                              );
                            }
                          : null,
                    );

                    // ignore: unused_local_variable
                    final sidebar = _AccessRightSidebar(
                      activeSubPage: _activeSubPage,
                      onSubPageTap: _setSubPage,
                      onHomeTap: () => _openSection(context, 'home'),
                      onOperationsTap: () =>
                          _openSection(context, 'operations'),
                      onOrdersTap: () => _openSection(context, 'orders'),
                      onLogisticsTap: () => _openSection(context, 'delivery'),
                      onRestaurantsTap: () =>
                          _openSection(context, 'restaurants'),
                      onUsersTap: () => _openSection(context, 'users'),
                      onFinanceTap: () => _openSection(context, 'finance'),
                      onMarketingTap: () => _openSection(context, 'marketing'),
                      onMenuTap: (item) async {
                        try {
                          switch (item.label) {
                            case 'مركز التواصل':
                              _openSection(context, 'support');
                              break;
                            case 'التقارير والتحليلات':
                              _openSection(context, 'reports');
                              break;
                            case 'إعدادات المنصة':
                              _openSection(context, 'settings');
                              break;
                            case 'الإدارة والصلاحيات':
                              _openSection(context, 'operations');
                              break;
                            default:
                              _showMasterSnack(
                                context,
                                '${item.label} قيد التطوير',
                              );
                          }
                        } catch (error) {
                          _showMasterSnack(
                            context,
                            'فشل تنفيذ الأمر: ${error.toString()}',
                          );
                        }
                      },
                    );

                    final sidebarItems =
                        _masterFilterSidebarItems(widget.session, const [
                          _DashboardMenuItemData(
                            iconKey: 'access',
                            label: 'الإدارة والصلاحيات',
                            selected: true,
                          ),
                        ]);
                    return _buildMasterUnifiedShell(
                      context: context,
                      session: widget.session,
                      onLogout: widget.onLogout,
                      api: widget.api ?? MasterAuthApiService(),
                      sidebarItems: sidebarItems,
                      onSidebarItemTap: (key) => _openSection(context, key),
                      statusLabel: 'الصلاحيات محمية',
                      platformTitle: 'الإدارة والصلاحيات',
                      platformSubtitle: 'إدارة الموظفين والأدوار والموافقات',
                      serverNow: serverNow,
                      child: content,
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
}

class _AccessSubPageContent extends StatelessWidget {
  const _AccessSubPageContent({
    required this.master,
    required this.activeSubPage,
    required this.roles,
    required this.employees,
    required this.activities,
    required this.sessions,
    required this.onboardingQueue,
    required this.settlements,
    required this.fraudAlerts,
    required this.disputeCases,
    required this.broadcasts,
    required this.moderationQueue,
    required this.returns,
    required this.stockRules,
    required this.onReturnStatusChanged,
    required this.onStockRuleToggle,
    required this.onScheduledReportToggle,
    required this.onHealthCheck,
    required this.scheduledExports,
    required this.serverNow,
    required this.api,
    required this.token,
    required this.searchController,
    required this.roleSearchController,
    required this.onSubPageChanged,
    this.pendingRestaurants = const <_AccessApprovalRecord>[],
    this.pendingDrivers = const <_AccessApprovalRecord>[],
    this.adminSearchQuery = '',
    this.adminRoleFilter = 'all',
    this.roleSearchQuery = '',
    this.canManageAdministrators = false,
    this.canManageRoles = false,
    this.canApproveRestaurants = false,
    this.canApproveDrivers = false,
    this.canManageLegal = false,
    this.onAdminSearchChanged,
    this.onAdminRoleFilterChanged,
    this.onRoleSearchChanged,
    this.onRefresh,
    this.onCreateAdministrator,
    this.onEditAdministrator,
    this.onToggleAdministrator,
    this.onResetPassword,
    this.onDeleteAdministrator,
    this.onCreateRole,
    this.onEditRole,
    this.onDeleteRole,
    this.onApproveRestaurant,
    this.onRejectRestaurant,
    this.onSuspendRestaurant,
    this.onApproveDriver,
    this.onRejectDriver,
    this.onSuspendDriver,
  });

  final String activeSubPage;
  final MasterUser master;
  final List<MasterRoleProfile> roles;
  final List<_AccessEmployeeRecord> employees;
  final List<_AccessActivityRecord> activities;
  final List<_AccessSessionRecord> sessions;
  final List<_AccessGenericRecord> onboardingQueue;
  final List<_AccessGenericRecord> settlements;
  final List<_AccessGenericRecord> fraudAlerts;
  final List<_AccessGenericRecord> disputeCases;
  final List<_AccessGenericRecord> broadcasts;
  final List<_AccessGenericRecord> moderationQueue;
  final List<_AccessGenericRecord> returns;
  final List<_AccessGenericRecord> stockRules;
  final Future<void> Function(_AccessGenericRecord, String)
  onReturnStatusChanged;
  final Future<void> Function(_AccessGenericRecord) onStockRuleToggle;
  final Future<void> Function(_AccessGenericRecord) onScheduledReportToggle;
  final Future<void> Function() onHealthCheck;
  final List<_AccessGenericRecord> scheduledExports;
  final DateTime serverNow;
  final MasterAuthApiService api;
  final String token;
  final TextEditingController searchController;
  final TextEditingController roleSearchController;
  final ValueChanged<String> onSubPageChanged;
  final List<_AccessApprovalRecord> pendingRestaurants;
  final List<_AccessApprovalRecord> pendingDrivers;
  final String adminSearchQuery;
  final String adminRoleFilter;
  final String roleSearchQuery;
  final bool canManageAdministrators;
  final bool canManageRoles;
  final bool canApproveRestaurants;
  final bool canApproveDrivers;
  final bool canManageLegal;
  final ValueChanged<String>? onAdminSearchChanged;
  final ValueChanged<String>? onAdminRoleFilterChanged;
  final ValueChanged<String>? onRoleSearchChanged;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onCreateAdministrator;
  final ValueChanged<_AccessEmployeeRecord>? onEditAdministrator;
  final Future<void> Function(_AccessEmployeeRecord, bool)?
  onToggleAdministrator;
  final Future<void> Function(_AccessEmployeeRecord)? onResetPassword;
  final Future<void> Function(_AccessEmployeeRecord)? onDeleteAdministrator;
  final VoidCallback? onCreateRole;
  final ValueChanged<MasterRoleProfile>? onEditRole;
  final Future<void> Function(MasterRoleProfile)? onDeleteRole;
  final Future<void> Function(_AccessApprovalRecord)? onApproveRestaurant;
  final Future<void> Function(_AccessApprovalRecord)? onRejectRestaurant;
  final Future<void> Function(_AccessApprovalRecord)? onSuspendRestaurant;
  final Future<void> Function(_AccessApprovalRecord)? onApproveDriver;
  final Future<void> Function(_AccessApprovalRecord)? onRejectDriver;
  final Future<void> Function(_AccessApprovalRecord)? onSuspendDriver;

  @override
  Widget build(BuildContext context) {
    final visibleSubPage =
        (!canManageAdministrators && activeSubPage == 'employees') ||
            (!canManageRoles &&
                (activeSubPage == 'roles' || activeSubPage == 'settings')) ||
            (!canManageLegal && activeSubPage == 'legal')
        ? 'overview'
        : activeSubPage;

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AccessHeader(
                activeSubPage: visibleSubPage,
                canManageAdministrators: canManageAdministrators,
                canManageRoles: canManageRoles,
                canManageLegal: canManageLegal,
                onSubPageChanged: onSubPageChanged,
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: visibleSubPage == 'approvals'
                    ? _AccessApprovalsView(
                        key: const ValueKey('approvals'),
                        pendingRestaurants: pendingRestaurants,
                        pendingDrivers: pendingDrivers,
                        onApproveRestaurant: onApproveRestaurant,
                        onRejectRestaurant: onRejectRestaurant,
                        onSuspendRestaurant: onSuspendRestaurant,
                        onApproveDriver: onApproveDriver,
                        onRejectDriver: onRejectDriver,
                        onSuspendDriver: onSuspendDriver,
                      )
                    : visibleSubPage == 'employees'
                    ? _AccessEmployeesView(
                        key: const ValueKey('employees'),
                        master: master,
                        roles: roles,
                        employees: employees,
                        searchController: searchController,
                        adminSearchQuery: adminSearchQuery,
                        adminRoleFilter: adminRoleFilter,
                        canManageAdministrators: canManageAdministrators,
                        onAdminSearchChanged: onAdminSearchChanged,
                        onEditAdministrator: onEditAdministrator,
                        onToggleAdministrator: onToggleAdministrator,
                        onResetPassword: onResetPassword,
                        onDeleteAdministrator: onDeleteAdministrator,
                        onCreateAdministrator: onCreateAdministrator,
                      )
                    : visibleSubPage == 'roles'
                    ? _AccessRolesView(
                        key: const ValueKey('roles'),
                        roles: roles,
                        roleSearchController: roleSearchController,
                        roleSearchQuery: roleSearchQuery,
                        canManageRoles: canManageRoles,
                        onRoleSearchChanged: onRoleSearchChanged,
                        onEditRole: onEditRole,
                        onDeleteRole: onDeleteRole,
                        onCreateRole: onCreateRole,
                      )
                    : visibleSubPage == 'settings'
                    ? _AccessSettingsView(
                        key: const ValueKey('settings'),
                        api: api,
                        token: token,
                      )
                    : visibleSubPage == 'legal'
                    ? MasterLegalContentWorkspace(
                        key: const ValueKey('legal'),
                        api: api,
                        token: token,
                        canEdit: canManageLegal,
                      )
                    : visibleSubPage == 'communication'
                    ? _AccessCommunicationView(
                        key: const ValueKey('communication'),
                        broadcasts: broadcasts,
                        sessions: sessions,
                        activities: activities,
                      )
                    : visibleSubPage == 'reports'
                    ? _AccessReportsView(
                        key: const ValueKey('reports'),
                        scheduledExports: scheduledExports,
                        settlements: settlements,
                        returns: returns,
                        stockRules: stockRules,
                        onReturnStatusChanged: onReturnStatusChanged,
                        onStockRuleToggle: onStockRuleToggle,
                        onScheduledReportToggle: onScheduledReportToggle,
                        onHealthCheck: onHealthCheck,
                      )
                    : _AccessOverviewView(
                        key: const ValueKey('overview'),
                        master: master,
                        roles: roles,
                        employees: employees,
                        activities: activities,
                        sessions: sessions,
                        serverNow: serverNow,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessHeader extends StatelessWidget {
  const _AccessHeader({
    required this.activeSubPage,
    required this.canManageAdministrators,
    required this.canManageRoles,
    required this.canManageLegal,
    required this.onSubPageChanged,
  });

  final String activeSubPage;
  final bool canManageAdministrators;
  final bool canManageRoles;
  final bool canManageLegal;
  final ValueChanged<String> onSubPageChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      ('approvals', 'القبول والموافقات', Icons.how_to_reg_outlined),
      ('communication', 'مركز التواصل', Icons.notifications_active_outlined),
      ('reports', 'التقارير والتحليلات', Icons.query_stats_outlined),
      ('overview', 'الملخص', Icons.dashboard_outlined),
      ('employees', 'الموظفون', Icons.people_alt_outlined),
      ('roles', 'الأدوار والصلاحيات', Icons.admin_panel_settings_outlined),
      ('settings', 'إعدادات المنصة', Icons.settings_outlined),
      ('legal', 'السياسات والكوكيز', Icons.policy_outlined),
    ];

    final visibleTabs = tabs.where((tab) {
      if (tab.$1 == 'employees') {
        return canManageAdministrators;
      }
      if (tab.$1 == 'roles' || tab.$1 == 'settings') {
        return canManageRoles;
      }
      if (tab.$1 == 'legal') {
        return canManageLegal;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          textDirection: TextDirection.rtl,
          children: [
            const Icon(
              Icons.admin_panel_settings_outlined,
              color: _kPrimaryGreen,
            ),
            const SizedBox(width: 8),
            const Text(
              'الإدارة والصلاحيات',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7EE),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFD7E9DD)),
              ),
              child: const Text(
                'شاشات التحكم',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _kPrimaryGreen,
                ),
              ),
            ),
            const Spacer(),
            const Text(
              'إدارة الموظفين والصلاحيات والرقابة',
              style: TextStyle(
                fontSize: 12.2,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6F7680),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFDFDFD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE7ECE8)),
          ),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var index = 0; index < visibleTabs.length; index++)
                SizedBox(
                  width: 174,
                  child: _AccessModeTab(
                    label: visibleTabs[index].$2,
                    icon: visibleTabs[index].$3,
                    selected: activeSubPage == visibleTabs[index].$1,
                    onTap: () => onSubPageChanged(visibleTabs[index].$1),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccessOverviewView extends StatelessWidget {
  const _AccessOverviewView({
    super.key,
    required this.master,
    required this.roles,
    required this.employees,
    required this.activities,
    required this.sessions,
    required this.serverNow,
  });

  final MasterUser master;
  final List<MasterRoleProfile> roles;
  final List<_AccessEmployeeRecord> employees;
  final List<_AccessActivityRecord> activities;
  final List<_AccessSessionRecord> sessions;
  final DateTime serverNow;

  @override
  Widget build(BuildContext context) {
    final activeEmployees = employees
        .where((employee) => employee.status.trim() == 'نشط')
        .length;
    final pendingEmployees = employees
        .where((employee) => employee.status.contains('معلق'))
        .length;
    final inactiveEmployees = math.max(
      0,
      employees.length - activeEmployees - pendingEmployees,
    );
    final metrics = [
      _AccessMetricData(
        label: 'إجمالي الموظفين',
        value: employees.length.toString(),
        icon: Icons.people_alt_outlined,
        accent: const Color(0xFF1A8B4A),
        background: const Color(0xFFEAF5ED),
        trend: '',
      ),
      _AccessMetricData(
        label: 'نشط',
        value: activeEmployees.toString(),
        icon: Icons.verified_outlined,
        accent: const Color(0xFF1A8B4A),
        background: const Color(0xFFEAF5ED),
        trend: '',
      ),
      _AccessMetricData(
        label: 'غير نشط',
        value: inactiveEmployees.toString(),
        icon: Icons.pause_circle_outline_rounded,
        accent: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF4E4),
        trend: '',
      ),
      _AccessMetricData(
        label: 'معلق',
        value: pendingEmployees.toString(),
        icon: Icons.lock_clock_outlined,
        accent: const Color(0xFFD92C2C),
        background: const Color(0xFFFDEEEF),
        trend: '',
      ),
      _AccessMetricData(
        label: 'الأدوار',
        value: roles.length.toString(),
        icon: Icons.badge_outlined,
        accent: const Color(0xFF7C3AED),
        background: const Color(0xFFF1EEFF),
        trend: '+1',
      ),
    ];

    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in metrics)
              SizedBox(width: 198, child: _AccessStatCard(metric: metric)),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1200;
            final leftPanel = _AccessPanel(
              title: 'الموظفون',
              subtitle: 'أحدث حالة للمشرفين وأصحاب الصلاحيات',
              child: _AccessEmployeePreviewList(items: employees),
            );
            final middlePanel = _AccessPanel(
              title: 'الأدوار النظامية',
              subtitle: 'توزيع الأدوار وعدد المستخدمين',
              child: _AccessRolePreviewList(roles: roles),
            );
            final rightPanel = _AccessPanel(
              title: 'صلاحيات الأقسام',
              subtitle: 'مدى التغطية والصلاحيات عبر الوحدات',
              child: _AccessPermissionCoverageList(roles: roles),
            );

            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: leftPanel),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: middlePanel),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: rightPanel),
                    ],
                  )
                : Column(
                    children: [
                      leftPanel,
                      const SizedBox(height: 12),
                      middlePanel,
                      const SizedBox(height: 12),
                      rightPanel,
                    ],
                  );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1200;
            final activityPanel = _AccessPanel(
              title: 'سجل النشاط',
              subtitle: 'أحدث الأحداث الإدارية والحركية',
              child: _AccessActivityList(items: activities),
            );
            final sessionsPanel = _AccessPanel(
              title: 'جلسات الدخول',
              subtitle: 'الأجهزة والجلسات النشطة',
              child: _AccessSessionList(items: sessions),
            );
            final adminPanel = _AccessPanel(
              title: 'سجل العمليات',
              subtitle: 'الإجراءات الإدارية المنفذة اليوم',
              child: _AccessAdminOpsList(),
            );

            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: activityPanel),
                      const SizedBox(width: 12),
                      Expanded(child: sessionsPanel),
                      const SizedBox(width: 12),
                      Expanded(child: adminPanel),
                    ],
                  )
                : Column(
                    children: [
                      activityPanel,
                      const SizedBox(height: 12),
                      sessionsPanel,
                      const SizedBox(height: 12),
                      adminPanel,
                    ],
                  );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1000;
            final left = _AccessPanel(
              title: 'تحكم سريع',
              subtitle: 'إجراءات اختصار للإدارة',
              child: const _AccessQuickActionsGrid(),
            );
            final right = _AccessPanel(
              title: 'ملحوظات',
              subtitle: 'مؤشرات مرجعية للفريق',
              child: _AccessNotesCard(serverNow: serverNow),
            );

            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: left),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: right),
                    ],
                  )
                : Column(children: [left, const SizedBox(height: 12), right]);
          },
        ),
      ],
    );
  }
}

class _AccessApprovalsView extends StatelessWidget {
  const _AccessApprovalsView({
    super.key,
    required this.pendingRestaurants,
    required this.pendingDrivers,
    this.onApproveRestaurant,
    this.onRejectRestaurant,
    this.onSuspendRestaurant,
    this.onApproveDriver,
    this.onRejectDriver,
    this.onSuspendDriver,
  });

  final List<_AccessApprovalRecord> pendingRestaurants;
  final List<_AccessApprovalRecord> pendingDrivers;
  final Future<void> Function(_AccessApprovalRecord)? onApproveRestaurant;
  final Future<void> Function(_AccessApprovalRecord)? onRejectRestaurant;
  final Future<void> Function(_AccessApprovalRecord)? onSuspendRestaurant;
  final Future<void> Function(_AccessApprovalRecord)? onApproveDriver;
  final Future<void> Function(_AccessApprovalRecord)? onRejectDriver;
  final Future<void> Function(_AccessApprovalRecord)? onSuspendDriver;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _AccessMetricData(
        label: 'المطاعم المعلقة',
        value: pendingRestaurants.length.toString(),
        icon: Icons.storefront_outlined,
        accent: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF4E4),
        trend: '',
      ),
      _AccessMetricData(
        label: 'السائقين المعلقين',
        value: pendingDrivers.length.toString(),
        icon: Icons.two_wheeler_outlined,
        accent: const Color(0xFF0D4D8B),
        background: const Color(0xFFEAF1FD),
        trend: '',
      ),
      _AccessMetricData(
        label: 'إجمالي المعلق',
        value: (pendingRestaurants.length + pendingDrivers.length).toString(),
        icon: Icons.hourglass_bottom_outlined,
        accent: const Color(0xFFD92C2C),
        background: const Color(0xFFFDEEEF),
        trend: '',
      ),
    ];

    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in stats)
              SizedBox(width: 198, child: _AccessStatCard(metric: metric)),
          ],
        ),
        const SizedBox(height: 16),
        if (pendingRestaurants.isNotEmpty) ...[
          _AccessPanel(
            title: 'المطاعم والمتاجر المعلقة للموافقة',
            subtitle: 'الجهات الجديدة التي تحتاج موافقة إدارية',
            child: Column(
              children: [
                for (final restaurant in pendingRestaurants)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AccessApprovalCard(
                      title: restaurant.title,
                      subtitle: restaurant.subtitle,
                      status: restaurant.status,
                      onApprove: () => onApproveRestaurant?.call(restaurant),
                      onReject: () => onRejectRestaurant?.call(restaurant),
                      onSuspend: () => onSuspendRestaurant?.call(restaurant),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (pendingDrivers.isNotEmpty) ...[
          _AccessPanel(
            title: 'السائقين المعلقين للموافقة',
            subtitle: 'السائقين الجدد الذين ينتظرون التحقق',
            child: Column(
              children: [
                for (final driver in pendingDrivers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AccessApprovalCard(
                      title: driver.title,
                      subtitle: driver.subtitle,
                      status: driver.status,
                      onApprove: () => onApproveDriver?.call(driver),
                      onReject: () => onRejectDriver?.call(driver),
                      onSuspend: () => onSuspendDriver?.call(driver),
                    ),
                  ),
              ],
            ),
          ),
        ],
        if (pendingRestaurants.isEmpty && pendingDrivers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 48,
                    color: const Color(0xFF1A8B4A).withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'لا توجد عناصر معلقة',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6F7680).withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'جميع المطاعم والسائقين تمت الموافقة عليهم',
                    style: TextStyle(
                      fontSize: 12,
                      color: const Color(0xFF6F7680).withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AccessApprovalCard extends StatelessWidget {
  const _AccessApprovalCard({
    required this.title,
    required this.subtitle,
    required this.status,
    this.onApprove,
    this.onReject,
    this.onSuspend,
  });

  final String title;
  final String subtitle;
  final String status;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onSuspend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6F7680),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 20,
                  color: Color(0xFF1A8B4A),
                ),
                onPressed: onApprove,
                tooltip: 'موافقة',
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.cancel_outlined,
                  size: 20,
                  color: Color(0xFFD92C2C),
                ),
                onPressed: onReject,
                tooltip: 'رفض',
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(
                  Icons.pause_circle_outline_rounded,
                  size: 20,
                  color: Color(0xFFF59E0B),
                ),
                onPressed: onSuspend,
                tooltip: 'إيقاف',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccessEmployeesView extends StatelessWidget {
  const _AccessEmployeesView({
    super.key,
    required this.master,
    required this.roles,
    required this.employees,
    required this.searchController,
    required this.adminSearchQuery,
    required this.adminRoleFilter,
    required this.canManageAdministrators,
    this.onAdminSearchChanged,
    this.onCreateAdministrator,
    this.onEditAdministrator,
    this.onToggleAdministrator,
    this.onResetPassword,
    this.onDeleteAdministrator,
  });

  final MasterUser master;
  final List<MasterRoleProfile> roles;
  final List<_AccessEmployeeRecord> employees;
  final TextEditingController searchController;
  final String adminSearchQuery;
  final String adminRoleFilter;
  final bool canManageAdministrators;
  final ValueChanged<String>? onAdminSearchChanged;
  final VoidCallback? onCreateAdministrator;
  final ValueChanged<_AccessEmployeeRecord>? onEditAdministrator;
  final Future<void> Function(_AccessEmployeeRecord, bool)?
  onToggleAdministrator;
  final Future<void> Function(_AccessEmployeeRecord)? onResetPassword;
  final Future<void> Function(_AccessEmployeeRecord)? onDeleteAdministrator;

  @override
  Widget build(BuildContext context) {
    final query = adminSearchQuery.trim().toLowerCase();
    final items = employees.where((employee) {
      final matchesQuery =
          query.isEmpty ||
          employee.name.toLowerCase().contains(query) ||
          employee.email.toLowerCase().contains(query) ||
          employee.phone.toLowerCase().contains(query) ||
          employee.roleLabel.toLowerCase().contains(query);
      final matchesRole =
          adminRoleFilter == 'all' ||
          employee.roleId.toString() == adminRoleFilter;
      return matchesQuery && matchesRole;
    }).toList();
    final activeEmployees = items
        .where((employee) => employee.status.trim() == 'نشط')
        .length;
    final pendingEmployees = items
        .where((employee) => employee.status.contains('معلق'))
        .length;
    final inactiveEmployees = math.max(
      0,
      items.length - activeEmployees - pendingEmployees,
    );
    final stats = [
      _AccessMetricData(
        label: 'إجمالي الموظفين',
        value: items.length.toString(),
        icon: Icons.people_alt_outlined,
        accent: const Color(0xFF1A8B4A),
        background: const Color(0xFFEAF5ED),
        trend: '',
      ),
      _AccessMetricData(
        label: 'نشط',
        value: activeEmployees.toString(),
        icon: Icons.check_circle_outline_rounded,
        accent: const Color(0xFF1A8B4A),
        background: const Color(0xFFEAF5ED),
        trend: '',
      ),
      _AccessMetricData(
        label: 'غير نشط',
        value: inactiveEmployees.toString(),
        icon: Icons.pause_circle_outline_rounded,
        accent: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF4E4),
        trend: '',
      ),
      _AccessMetricData(
        label: 'معلق',
        value: pendingEmployees.toString(),
        icon: Icons.lock_clock_outlined,
        accent: const Color(0xFFD92C2C),
        background: const Color(0xFFFDEEEF),
        trend: '',
      ),
      _AccessMetricData(
        label: 'الأدوار',
        value: '${roles.length}',
        icon: Icons.badge_outlined,
        accent: const Color(0xFF7C3AED),
        background: const Color(0xFFF1EEFF),
        trend: '+9%',
      ),
    ];

    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in stats)
              SizedBox(width: 198, child: _AccessStatCard(metric: metric)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          textDirection: TextDirection.rtl,
          children: [
            ElevatedButton.icon(
              onPressed: onCreateAdministrator,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('إضافة موظف'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () {
                final rows = [
                  'name,email,phone,department,role,status,last_login',
                  for (final employee in items)
                    [
                      employee.name,
                      employee.email,
                      employee.phone,
                      employee.department,
                      employee.roleLabel,
                      employee.status,
                      employee.lastLogin,
                    ].map(_csvCell).join(','),
                ].join('\n');
                Clipboard.setData(ClipboardData(text: rows));
                _showMasterSnack(context, 'تم نسخ قائمة الموظفين بصيغة CSV');
              },
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('تصدير'),
            ),
            const Spacer(),
            SizedBox(
              width: 360,
              child: TextField(
                controller: searchController,
                onChanged: onAdminSearchChanged,
                textDirection: TextDirection.rtl,
                decoration: _searchDecoration(
                  'ابحث باسم الموظف أو البريد الإلكتروني...',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1200;
            final table = _AccessPanel(
              title: 'قائمة الموظفين',
              subtitle: 'إدارة الحسابات وأدوار الفريق',
              child: _AccessEmployeeTable(
                items: items,
                canManage: canManageAdministrators,
                onEdit: onEditAdministrator,
                onToggle: onToggleAdministrator,
                onResetPassword: onResetPassword,
                onDelete: onDeleteAdministrator,
              ),
            );
            final sidebar = _AccessPanel(
              title: 'تصفية الموظفين',
              subtitle: 'تضييق النتائج بسرعة',
              child: const _AccessEmployeeFilterSidebar(),
            );

            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: table),
                      const SizedBox(width: 12),
                      SizedBox(width: 320, child: sidebar),
                    ],
                  )
                : Column(
                    children: [table, const SizedBox(height: 12), sidebar],
                  );
          },
        ),
      ],
    );
  }
}

class _AccessRolesView extends StatelessWidget {
  const _AccessRolesView({
    super.key,
    required this.roles,
    required this.roleSearchController,
    required this.roleSearchQuery,
    required this.canManageRoles,
    this.onRoleSearchChanged,
    this.onCreateRole,
    this.onEditRole,
    this.onDeleteRole,
  });

  final List<MasterRoleProfile> roles;
  final TextEditingController roleSearchController;
  final String roleSearchQuery;
  final bool canManageRoles;
  final ValueChanged<String>? onRoleSearchChanged;
  final VoidCallback? onCreateRole;
  final ValueChanged<MasterRoleProfile>? onEditRole;
  final Future<void> Function(MasterRoleProfile)? onDeleteRole;

  @override
  Widget build(BuildContext context) {
    final query = roleSearchQuery.trim().toLowerCase();
    final visibleRoles = roles.where((role) {
      return query.isEmpty ||
          role.roleName.toLowerCase().contains(query) ||
          role.roleScope.toLowerCase().contains(query) ||
          role.permissions.any(
            (permission) => permission.toLowerCase().contains(query),
          );
    }).toList();
    final rolesWithPermissions = visibleRoles
        .where((role) => role.permissions.isNotEmpty)
        .length;
    final totalPermissions = visibleRoles.fold<int>(
      0,
      (sum, role) => sum + role.permissions.length,
    );
    final rolesWithoutPermissions = visibleRoles.length - rolesWithPermissions;
    final averagePermissions = visibleRoles.isEmpty
        ? 0
        : (totalPermissions / visibleRoles.length).round();
    final stats = [
      _AccessMetricData(
        label: 'الأدوار',
        value: visibleRoles.length.toString(),
        icon: Icons.grid_view_rounded,
        accent: const Color(0xFF7C3AED),
        background: const Color(0xFFF1EEFF),
        trend: '',
      ),
      _AccessMetricData(
        label: 'بدون صلاحيات',
        value: rolesWithoutPermissions.toString(),
        icon: Icons.pause_circle_outline_rounded,
        accent: const Color(0xFFD92C2C),
        background: const Color(0xFFFDEEEF),
        trend: '',
      ),
      _AccessMetricData(
        label: 'متوسط الصلاحيات',
        value: averagePermissions.toString(),
        icon: Icons.timelapse_outlined,
        accent: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF4E4),
        trend: '',
      ),
      _AccessMetricData(
        label: 'أدوار بصلاحيات',
        value: rolesWithPermissions.toString(),
        icon: Icons.group_outlined,
        accent: const Color(0xFF1A8B4A),
        background: const Color(0xFFEAF5ED),
        trend: '',
      ),
      _AccessMetricData(
        label: 'إجمالي الصلاحيات',
        value: totalPermissions.toString(),
        icon: Icons.people_alt_outlined,
        accent: const Color(0xFF0D4D8B),
        background: const Color(0xFFEAF1FD),
        trend: '',
      ),
    ];

    return Column(
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final metric in stats)
              SizedBox(width: 198, child: _AccessStatCard(metric: metric)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          textDirection: TextDirection.rtl,
          children: [
            ElevatedButton.icon(
              onPressed: onCreateRole,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('إضافة دور'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => _showMasterSnack(
                context,
                'استيراد الصلاحيات يحتاج ملف إعدادات',
              ),
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: const Text('استيراد'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () {
                final rows = [
                  'role_id,role_name,role_scope,permissions_count,permissions',
                  for (final role in roles)
                    [
                      role.roleId.toString(),
                      role.roleName,
                      role.roleScope,
                      role.permissions.length.toString(),
                      role.permissions.join(' | '),
                    ].map(_csvCell).join(','),
                ].join('\n');
                Clipboard.setData(ClipboardData(text: rows));
                _showMasterSnack(context, 'تم نسخ الصلاحيات بصيغة CSV');
              },
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('تصدير الصلاحيات'),
            ),
            const Spacer(),
            SizedBox(
              width: 340,
              child: TextField(
                controller: roleSearchController,
                onChanged: onRoleSearchChanged,
                textDirection: TextDirection.rtl,
                decoration: _searchDecoration('ابحث باسم الدور أو المسمى...'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1200;
            final table = _AccessPanel(
              title: 'قائمة الأدوار',
              subtitle: 'إدارة الأدوار وترتيبها',
              child: _AccessRoleTable(
                items: visibleRoles,
                canManage: canManageRoles,
                onEdit: onEditRole,
                onDelete: onDeleteRole,
              ),
            );
            final detail = _AccessPanel(
              title: 'تفاصيل الدور',
              subtitle: 'تخصيص الصلاحيات للدور المحدد',
              child: const _AccessRoleDetailSidebar(),
            );

            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: table),
                      const SizedBox(width: 12),
                      SizedBox(width: 360, child: detail),
                    ],
                  )
                : Column(children: [table, const SizedBox(height: 12), detail]);
          },
        ),
      ],
    );
  }
}

class _AccessCommunicationView extends StatelessWidget {
  const _AccessCommunicationView({
    super.key,
    required this.broadcasts,
    required this.sessions,
    required this.activities,
  });

  final List<_AccessGenericRecord> broadcasts;
  final List<_AccessSessionRecord> sessions;
  final List<_AccessActivityRecord> activities;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _AccessMetricData(
        label: 'حملات التواصل',
        value: broadcasts.length.toString(),
        icon: Icons.campaign_outlined,
        accent: const Color(0xFF0D4D8B),
        background: const Color(0xFFEAF1FD),
        trend: '',
      ),
      _AccessMetricData(
        label: 'جلسات نشطة',
        value: sessions.length.toString(),
        icon: Icons.devices_outlined,
        accent: const Color(0xFF1A8B4A),
        background: const Color(0xFFEAF5ED),
        trend: '',
      ),
      _AccessMetricData(
        label: 'آخر أنشطة',
        value: activities.length.toString(),
        icon: Icons.history_rounded,
        accent: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF4E4),
        trend: '',
      ),
    ];

    return Column(
      children: [
        _AccessMetricsWrap(metrics: metrics),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1100;
            final campaigns = _AccessPanel(
              title: 'رسائل وإشعارات المنصة',
              subtitle: 'آخر الحملات والتنبيهات القادمة من قاعدة البيانات',
              child: _AccessGenericList(items: broadcasts),
            );
            final activity = _AccessPanel(
              title: 'نشاط فريق التواصل',
              subtitle: 'جلسات وأحداث مرتبطة بالأدمن وفريق الدعم',
              child: _AccessActivityList(items: activities),
            );
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: campaigns),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: activity),
                    ],
                  )
                : Column(
                    children: [campaigns, const SizedBox(height: 12), activity],
                  );
          },
        ),
      ],
    );
  }
}

class _AccessQualityView extends StatelessWidget {
  const _AccessQualityView({
    required this.fraudAlerts,
    required this.disputeCases,
    required this.moderationQueue,
    required this.onboardingQueue,
  });

  final List<_AccessGenericRecord> fraudAlerts;
  final List<_AccessGenericRecord> disputeCases;
  final List<_AccessGenericRecord> moderationQueue;
  final List<_AccessGenericRecord> onboardingQueue;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _AccessMetricData(
        label: 'تنبيهات المخاطر',
        value: fraudAlerts.length.toString(),
        icon: Icons.warning_amber_rounded,
        accent: const Color(0xFFD92C2C),
        background: const Color(0xFFFDEEEF),
        trend: '',
      ),
      _AccessMetricData(
        label: 'حالات النزاع',
        value: disputeCases.length.toString(),
        icon: Icons.support_agent_rounded,
        accent: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF4E4),
        trend: '',
      ),
      _AccessMetricData(
        label: 'مراجعات المحتوى',
        value: moderationQueue.length.toString(),
        icon: Icons.fact_check_outlined,
        accent: const Color(0xFF7C3AED),
        background: const Color(0xFFF1EEFF),
        trend: '',
      ),
      _AccessMetricData(
        label: 'متابعة المطاعم',
        value: onboardingQueue.length.toString(),
        icon: Icons.storefront_outlined,
        accent: const Color(0xFF1A8B4A),
        background: const Color(0xFFEAF5ED),
        trend: '',
      ),
    ];

    return Column(
      children: [
        _AccessMetricsWrap(metrics: metrics),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1180;
            final risks = _AccessPanel(
              title: 'تنبيهات الجودة والمخاطر',
              subtitle: 'فحص حي للطلبات والدفع والمطاعم المعلقة',
              child: _AccessGenericList(items: fraudAlerts),
            );
            final disputes = _AccessPanel(
              title: 'خدمة العملاء والنزاعات',
              subtitle: 'الحالات التي تحتاج تصعيد أو مراجعة مالية',
              child: _AccessGenericList(items: disputeCases),
            );
            final moderation = _AccessPanel(
              title: 'جودة المحتوى',
              subtitle: 'مراجعة الفيديوهات والإعلانات والروابط المعطلة',
              child: _AccessGenericList(items: moderationQueue),
            );
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: risks),
                      const SizedBox(width: 12),
                      Expanded(child: disputes),
                      const SizedBox(width: 12),
                      Expanded(child: moderation),
                    ],
                  )
                : Column(
                    children: [
                      risks,
                      const SizedBox(height: 12),
                      disputes,
                      const SizedBox(height: 12),
                      moderation,
                    ],
                  );
          },
        ),
      ],
    );
  }
}

class _AccessReportsView extends StatelessWidget {
  const _AccessReportsView({
    super.key,
    required this.scheduledExports,
    required this.settlements,
    required this.returns,
    required this.stockRules,
    required this.onReturnStatusChanged,
    required this.onStockRuleToggle,
    required this.onScheduledReportToggle,
    required this.onHealthCheck,
  });

  final List<_AccessGenericRecord> scheduledExports;
  final List<_AccessGenericRecord> settlements;
  final List<_AccessGenericRecord> returns;
  final List<_AccessGenericRecord> stockRules;
  final Future<void> Function(_AccessGenericRecord, String)
  onReturnStatusChanged;
  final Future<void> Function(_AccessGenericRecord) onStockRuleToggle;
  final Future<void> Function(_AccessGenericRecord) onScheduledReportToggle;
  final Future<void> Function() onHealthCheck;

  @override
  Widget build(BuildContext context) {
    final activeExports = scheduledExports
        .where((item) => item.status.toLowerCase() == 'active')
        .length;
    final metrics = [
      _AccessMetricData(
        label: 'مصادر التقارير',
        value: scheduledExports.length.toString(),
        icon: Icons.query_stats_outlined,
        accent: const Color(0xFF0D4D8B),
        background: const Color(0xFFEAF1FD),
        trend: '',
      ),
      _AccessMetricData(
        label: 'تقارير فعالة',
        value: activeExports.toString(),
        icon: Icons.check_circle_outline_rounded,
        accent: const Color(0xFF1A8B4A),
        background: const Color(0xFFEAF5ED),
        trend: '',
      ),
      _AccessMetricData(
        label: 'تسويات مطاعم',
        value: settlements.length.toString(),
        icon: Icons.account_balance_wallet_outlined,
        accent: const Color(0xFFF59E0B),
        background: const Color(0xFFFFF4E4),
        trend: '',
      ),
      _AccessMetricData(
        label: 'طلبات الإرجاع',
        value: returns.length.toString(),
        icon: Icons.assignment_return_outlined,
        accent: const Color(0xFFDC2626),
        background: const Color(0xFFFDECEC),
        trend: '',
      ),
      _AccessMetricData(
        label: 'قواعد المخزون',
        value: stockRules.length.toString(),
        icon: Icons.inventory_2_outlined,
        accent: const Color(0xFF2563EB),
        background: const Color(0xFFEAF1FD),
        trend: '',
      ),
    ];

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onHealthCheck,
            icon: const Icon(Icons.health_and_safety_outlined, size: 17),
            label: const Text('فحص جاهزية النشر'),
          ),
        ),
        const SizedBox(height: 10),
        _AccessMetricsWrap(metrics: metrics),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1080;
            final exports = _AccessPanel(
              title: 'التقارير والتحليلات',
              subtitle: 'مصادر تصدير جاهزة من قاعدة البيانات الحية',
              child: _AccessScheduledReportList(
                items: scheduledExports,
                onToggle: onScheduledReportToggle,
              ),
            );
            final finance = _AccessPanel(
              title: 'ملخصات مالية للمطاعم',
              subtitle: 'تسويات وإجماليات مرتبطة بسجلات المطاعم',
              child: _AccessGenericList(items: settlements),
            );
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: exports),
                      const SizedBox(width: 12),
                      Expanded(child: finance),
                    ],
                  )
                : Column(
                    children: [exports, const SizedBox(height: 12), finance],
                  );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1080;
            final returnsPanel = _AccessPanel(
              title: 'إدارة الإرجاعات',
              subtitle: 'طلبات الإرجاع المرتبطة ببيانات التشغيل الحية',
              child: _AccessReturnList(
                items: returns,
                onStatusChanged: onReturnStatusChanged,
              ),
            );
            final stockPanel = _AccessPanel(
              title: 'مراقبة المخزون',
              subtitle: 'قواعد الحد الأدنى والتوريد للمنتجات',
              child: _AccessStockList(
                items: stockRules,
                onToggle: onStockRuleToggle,
              ),
            );
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: returnsPanel),
                      const SizedBox(width: 12),
                      Expanded(child: stockPanel),
                    ],
                  )
                : Column(
                    children: [
                      returnsPanel,
                      const SizedBox(height: 12),
                      stockPanel,
                    ],
                  );
          },
        ),
      ],
    );
  }
}

class _AccessSettingsView extends StatefulWidget {
  const _AccessSettingsView({
    super.key,
    required this.api,
    required this.token,
  });

  final MasterAuthApiService api;
  final String token;

  @override
  State<_AccessSettingsView> createState() => _AccessSettingsViewState();
}

class _AccessSettingsViewState extends State<_AccessSettingsView> {
  late Future<Map<String, dynamic>> _settingsFuture;
  final _currencyController = TextEditingController();
  final _symbolController = TextEditingController();
  final _currencyNameController = TextEditingController();
  final _currencyNameEnController = TextEditingController();
  final _commissionController = TextEditingController();
  final _baseFeeController = TextEditingController();
  final _perKmController = TextEditingController();
  final _maxDistanceController = TextEditingController();
  final _minPayoutController = TextEditingController();
  final _supportPhoneController = TextEditingController();
  final _supportEmailController = TextEditingController();
  final _platformNameArController = TextEditingController();
  final _platformNameEnController = TextEditingController();
  final _platformTimezoneController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Platform settings are editable server-side; never reuse an older
    // in-memory response when reopening this screen.
    widget.api.clearReadCache();
    _settingsFuture = widget.api._fetchMasterPlatformSettings(widget.token);
  }

  @override
  void dispose() {
    for (final controller in [
      _currencyController,
      _symbolController,
      _currencyNameController,
      _currencyNameEnController,
      _commissionController,
      _baseFeeController,
      _perKmController,
      _maxDistanceController,
      _minPayoutController,
      _supportPhoneController,
      _supportEmailController,
      _platformNameArController,
      _platformNameEnController,
      _platformTimezoneController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initialize(Map<String, dynamic> data) {
    if (_initialized) return;
    _initialized = true;
    String value(String key, [String fallback = '']) =>
        (data[key] ?? fallback).toString();
    _currencyController.text = value('default_currency_code', 'SAR');
    _symbolController.text = value('default_currency_symbol', 'ر.س');
    _currencyNameController.text = value(
      'default_currency_name',
      'الريال السعودي',
    );
    _currencyNameEnController.text = value(
      'default_currency_name_en',
      'Saudi Riyal',
    );
    _commissionController.text = value('platform_commission_percent', '15');
    _baseFeeController.text = value('delivery_base_fee', '10');
    _perKmController.text = value('delivery_cost_per_km', '2.5');
    _maxDistanceController.text = value('max_delivery_distance_km', '25');
    _minPayoutController.text = value('min_vendor_payout', '500');
    _supportPhoneController.text = value('support_phone');
    _supportEmailController.text = value('support_email');
    _platformNameArController.text = value('platform_name_ar', 'جييب');
    _platformNameEnController.text = value('platform_name_en', 'FOXA');
    _platformTimezoneController.text = value(
      'platform_timezone',
      'Africa/Cairo',
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final settings = <String, dynamic>{
        'default_currency_code': _currencyController.text.trim(),
        'default_currency_symbol': _symbolController.text.trim(),
        'default_currency_name': _currencyNameController.text.trim(),
        'default_currency_name_en': _currencyNameEnController.text.trim(),
        'platform_commission_percent':
            double.tryParse(_commissionController.text) ?? 15,
        'delivery_base_fee': double.tryParse(_baseFeeController.text) ?? 10,
        'delivery_cost_per_km': double.tryParse(_perKmController.text) ?? 2.5,
        'max_delivery_distance_km':
            double.tryParse(_maxDistanceController.text) ?? 25,
        'min_vendor_payout': double.tryParse(_minPayoutController.text) ?? 500,
        'support_phone': _supportPhoneController.text.trim(),
        'support_email': _supportEmailController.text.trim(),
        'platform_name_ar': _platformNameArController.text.trim(),
        'platform_name_en': _platformNameEnController.text.trim(),
        'platform_timezone': _platformTimezoneController.text.trim(),
      };
      await widget.api._saveMasterPlatformSettings(widget.token, settings);
      MasterCurrency.apply(settings);
      if (mounted) {
        _showMasterSnack(context, 'تم حفظ إعدادات المنصة في قاعدة البيانات');
      }
    } catch (error) {
      if (mounted) _showMasterSnack(context, 'تعذر حفظ إعدادات المنصة: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool numeric = false,
  }) {
    return SizedBox(
      width: 245,
      child: TextField(
        controller: controller,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildPlatformSettingsForm(Map<String, dynamic> data) {
    _initialize(data);
    return _AccessPanel(
      title: 'إعدادات المنصة الفعلية',
      subtitle:
          'العملة والعمولات وتكلفة التوصيل وبيانات الدعم محفوظة مباشرة في قاعدة البيانات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              _field('رمز العملة', _currencyController),
              _field('رمز العرض', _symbolController),
              _field('اسم العملة', _currencyNameController),
              _field('Currency name (English)', _currencyNameEnController),
              _field('Timezone (IANA)', _platformTimezoneController),
              _field('اسم المنصة بالعربية', _platformNameArController),
              _field('اسم المنصة بالإنجليزية', _platformNameEnController),
              _field('نسبة العمولة %', _commissionController, numeric: true),
              _field(
                'رسوم التوصيل الأساسية',
                _baseFeeController,
                numeric: true,
              ),
              _field('التكلفة لكل كيلومتر', _perKmController, numeric: true),
              _field(
                'أقصى مسافة توصيل كم',
                _maxDistanceController,
                numeric: true,
              ),
              _field(
                'الحد الأدنى لسحب المتجر',
                _minPayoutController,
                numeric: true,
              ),
              _field('هاتف الدعم', _supportPhoneController),
              _field('بريد الدعم', _supportEmailController),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'جار الحفظ...' : 'حفظ إعدادات المنصة'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _settingsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError && !snapshot.hasData) {
          return _OperationsDataErrorState(
            message: snapshot.error.toString(),
            onRetry: () => setState(() {
              _initialized = false;
              _settingsFuture = widget.api._fetchMasterPlatformSettings(
                widget.token,
              );
            }),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildSettingsBody(context, snapshot.data!);
      },
    );
  }

  Widget _buildSettingsBody(BuildContext context, Map<String, dynamic> data) {
    final cards = const [
      ('إعدادات الطلبات', Icons.receipt_long_outlined),
      ('الحسابات والتسجيل', Icons.person_outline_rounded),
      ('اللغات والمنطقة', Icons.language_rounded),
      ('إعدادات الخدمة والتوصيل', Icons.delivery_dining_outlined),
      ('إعدادات المحفظة', Icons.account_balance_wallet_outlined),
      ('إعدادات التسليم', Icons.inventory_2_outlined),
      ('إعدادات المطور', Icons.code_rounded),
      ('النسخ الاحتياطي', Icons.backup_outlined),
    ];

    return Column(
      children: [
        _buildPlatformSettingsForm(data),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards)
              SizedBox(
                width: 252,
                child: _AccessSettingsCard(title: card.$1, icon: card.$2),
              ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1180;
            final left = _AccessPanel(
              title: 'مفاتيح التحكم السريعة',
              subtitle: 'تفعيل وإيقاف وحدات المنصة',
              child: const _AccessModuleToggles(),
            );
            final right = _AccessPanel(
              title: 'النسخ الاحتياطي والاستعادة',
              subtitle: 'حماية البيانات واستعادتها',
              child: const _AccessBackupPanel(),
            );

            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: left),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: right),
                    ],
                  )
                : Column(children: [left, const SizedBox(height: 12), right]);
          },
        ),
      ],
    );
  }
}

class _AccessRightSidebar extends StatelessWidget {
  const _AccessRightSidebar({
    required this.activeSubPage,
    required this.onSubPageTap,
    required this.onHomeTap,
    required this.onOperationsTap,
    required this.onOrdersTap,
    required this.onLogisticsTap,
    required this.onRestaurantsTap,
    required this.onUsersTap,
    required this.onFinanceTap,
    required this.onMarketingTap,
    required this.onMenuTap,
  });

  final String activeSubPage;
  final ValueChanged<String> onSubPageTap;
  final VoidCallback onHomeTap;
  final VoidCallback onOperationsTap;
  final VoidCallback onOrdersTap;
  final VoidCallback onLogisticsTap;
  final VoidCallback onRestaurantsTap;
  final VoidCallback onUsersTap;
  final VoidCallback onFinanceTap;
  final VoidCallback onMarketingTap;
  final ValueChanged<_OperationsSidebarTileData> onMenuTap;

  @override
  Widget build(BuildContext context) {
    final bottomMenuItems = <_OperationsSidebarTileData>[
      const _OperationsSidebarTileData(
        label: 'مركز التواصل',
        icon: Icons.notifications_active_outlined,
      ),
      // 'الجودة وخدمة العملاء' removed per user request
      const _OperationsSidebarTileData(
        label: 'التقارير والتحليلات',
        icon: Icons.query_stats_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'إعدادات المنصة',
        icon: Icons.settings_outlined,
      ),
      const _OperationsSidebarTileData(
        label: 'الإدارة والصلاحيات',
        icon: Icons.admin_panel_settings_outlined,
      ),
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
              const SizedBox(height: 6),
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
                selected: false,
                onTap: onUsersTap,
              ),
              const SizedBox(height: 10),
              _OperationsSidebarMainItem(
                label: 'الإدارة المالية',
                icon: Icons.account_balance_wallet_outlined,
                selected: false,
                onTap: onFinanceTap,
              ),
              const SizedBox(height: 10),
              _OperationsSidebarMainItem(
                label: 'التسويق والنمو',
                icon: Icons.campaign_outlined,
                selected: false,
                onTap: onMarketingTap,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFDFD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7ECE8)),
                ),
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index <
                          const [
                            'overview',
                            'employees',
                            'roles',
                            'settings',
                          ].length;
                      index++
                    ) ...[
                      _AccessModeTab(
                        label: const [
                          'الملخص',
                          'الموظفون',
                          'الأدوار والصلاحيات',
                          'إعدادات المنصة',
                        ][index],
                        icon: const [
                          Icons.dashboard_outlined,
                          Icons.people_alt_outlined,
                          Icons.admin_panel_settings_outlined,
                          Icons.settings_outlined,
                        ][index],
                        selected:
                            activeSubPage ==
                            const [
                              'overview',
                              'employees',
                              'roles',
                              'settings',
                            ][index],
                        onTap: () => onSubPageTap(
                          const [
                            'overview',
                            'employees',
                            'roles',
                            'settings',
                          ][index],
                        ),
                      ),
                      if (index != 3) const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final item in bottomMenuItems) ...[
                _OperationsSidebarMenuItem(
                  data: item,
                  onTap: () {
                    if (item.icon == Icons.notifications_active_outlined) {
                      onSubPageTap('communication');
                      return;
                    }
                    if (item.icon == Icons.verified_user_outlined) {
                      onSubPageTap('quality');
                      return;
                    }
                    if (item.icon == Icons.query_stats_outlined) {
                      onSubPageTap('reports');
                      return;
                    }
                    if (item.icon == Icons.settings_outlined) {
                      onSubPageTap('settings');
                      return;
                    }
                    if (item.icon == Icons.admin_panel_settings_outlined) {
                      onSubPageTap('overview');
                      return;
                    }
                    onMenuTap(item);
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

class _AccessModeTab extends StatelessWidget {
  const _AccessModeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF1F8F4) : const Color(0xFFF8FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFFD7E9DD)
                  : const Color(0xFFE7ECE8),
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? _kPrimaryGreen : const Color(0xFF4E5660),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11.2,
                    fontWeight: FontWeight.w800,
                    color: selected ? _kPrimaryGreen : const Color(0xFF4E5660),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessMetricsWrap extends StatelessWidget {
  const _AccessMetricsWrap({required this.metrics});

  final List<_AccessMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final metric in metrics)
          SizedBox(width: 198, child: _AccessStatCard(metric: metric)),
      ],
    );
  }
}

class _AccessGenericList extends StatelessWidget {
  const _AccessGenericList({required this.items});

  final List<_AccessGenericRecord> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _UsersPlaceholderWorkspace(
        title: 'لا توجد بيانات',
        description: 'لم يرجع الباك إند سجلات لهذا القسم حاليًا.',
        icon: Icons.inbox_outlined,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _AccessGenericListTile(item: items[index]),
          if (index != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AccessScheduledReportList extends StatelessWidget {
  const _AccessScheduledReportList({
    required this.items,
    required this.onToggle,
  });

  final List<_AccessGenericRecord> items;
  final Future<void> Function(_AccessGenericRecord) onToggle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _UsersPlaceholderWorkspace(
        title: 'لا توجد تقارير مجدولة',
        description: 'لم يتم تسجيل تقارير مجدولة حاليًا.',
        icon: Icons.schedule_outlined,
      );
    }
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _AccessGenericListTile(
            item: items[index],
            trailing: OutlinedButton.icon(
              onPressed: () => onToggle(items[index]),
              icon: Icon(
                items[index].status.toLowerCase() == 'active'
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                size: 15,
              ),
              label: Text(
                items[index].status.toLowerCase() == 'active'
                    ? 'تعطيل'
                    : 'تفعيل',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: items[index].status.toLowerCase() == 'active'
                    ? const Color(0xFFB45309)
                    : const Color(0xFF16834A),
                side: BorderSide(
                  color: items[index].status.toLowerCase() == 'active'
                      ? const Color(0xFFF5D9A7)
                      : const Color(0xFFBCE5CA),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
            ),
          ),
          if (index != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AccessReturnList extends StatelessWidget {
  const _AccessReturnList({required this.items, required this.onStatusChanged});

  final List<_AccessGenericRecord> items;
  final Future<void> Function(_AccessGenericRecord, String) onStatusChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _UsersPlaceholderWorkspace(
        title: 'لا توجد طلبات إرجاع',
        description: 'لا توجد طلبات إرجاع مسجلة حاليًا.',
        icon: Icons.assignment_return_outlined,
      );
    }
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _AccessGenericListTile(
            item: items[index],
            trailing: PopupMenuButton<String>(
              tooltip: 'تغيير الحالة',
              onSelected: (value) => onStatusChanged(items[index], value),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'Approved', child: Text('اعتماد')),
                PopupMenuItem(value: 'Rejected', child: Text('رفض')),
                PopupMenuItem(value: 'Completed', child: Text('مكتمل')),
              ],
              child: const Icon(Icons.more_vert_rounded, size: 20),
            ),
          ),
          if (index != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AccessStockList extends StatelessWidget {
  const _AccessStockList({required this.items, required this.onToggle});

  final List<_AccessGenericRecord> items;
  final Future<void> Function(_AccessGenericRecord) onToggle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _UsersPlaceholderWorkspace(
        title: 'لا توجد قواعد مخزون',
        description: 'لا توجد قواعد مخزون مسجلة حاليًا.',
        icon: Icons.inventory_2_outlined,
      );
    }
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _AccessGenericListTile(
            item: items[index],
            trailing: IconButton(
              tooltip: 'تفعيل أو إيقاف القاعدة',
              onPressed: () => onToggle(items[index]),
              icon: Icon(
                items[index].status.toLowerCase().contains('active') ||
                        items[index].status.contains('نشط')
                    ? Icons.toggle_on_outlined
                    : Icons.toggle_off_outlined,
                color: const Color(0xFF2563EB),
              ),
            ),
          ),
          if (index != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AccessGenericListTile extends StatelessWidget {
  const _AccessGenericListTile({required this.item, this.trailing});

  final _AccessGenericRecord item;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: item.tint.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(item.icon, size: 19, color: item.tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12.6,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E232A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6F7680),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: item.tint.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: item.tint.withValues(alpha: 0.22)),
            ),
            child: Text(
              item.status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.4,
                fontWeight: FontWeight.w800,
                color: item.tint,
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _AccessPanel extends StatelessWidget {
  const _AccessPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E232A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11.2,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6F7680),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF7B8190),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AccessStatCard extends StatelessWidget {
  const _AccessStatCard({required this.metric});

  final _AccessMetricData metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: metric.background,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(metric.icon, color: metric.accent, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  metric.label,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.4,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E232A),
                  ),
                ),
                Text(
                  metric.value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E232A),
                    height: 1.0,
                  ),
                ),
                if (metric.trend.isNotEmpty)
                  Text(
                    metric.trend,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: metric.accent,
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

class _AccessEmployeePreviewList extends StatelessWidget {
  const _AccessEmployeePreviewList({required this.items});

  final List<_AccessEmployeeRecord> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items.take(5))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFCFD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE7ECE8)),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: item.avatarColor,
                    child: Text(
                      item.name.isNotEmpty ? item.name[0] : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.name,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.email,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 10.2,
                            color: Color(0xFF6F7680),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _AccessPill(label: item.status, color: item.statusColor),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AccessRolePreviewList extends StatelessWidget {
  const _AccessRolePreviewList({required this.roles});

  final List<MasterRoleProfile> roles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < roles.take(5).length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFCFD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE7ECE8)),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: roles[index].tintColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.brightness_1,
                      size: 10,
                      color: roles[index].tintColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          roles[index].roleName,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          roles[index].roleScope,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 10.2,
                            color: Color(0xFF6F7680),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    roles[index].permissions.length.toString(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AccessPermissionCoverageList extends StatelessWidget {
  const _AccessPermissionCoverageList({required this.roles});

  final List<MasterRoleProfile> roles;

  @override
  Widget build(BuildContext context) {
    final maxPermissions = roles.fold<int>(
      0,
      (max, role) =>
          role.permissions.length > max ? role.permissions.length : max,
    );
    final groups = roles.where((role) => role.roleName.trim().isNotEmpty).map((
      role,
    ) {
      final progress = maxPermissions == 0
          ? 0.0
          : role.permissions.length / maxPermissions;
      return _AccessPermissionCoverageData(
        role.roleName,
        progress.clamp(0.0, 1.0),
        role.permissions.length.toString(),
      );
    }).toList();

    if (groups.isEmpty) {
      return const Text(
        'لا توجد بيانات صلاحيات',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6F7680),
        ),
      );
    }

    return Column(
      children: [
        for (final group in groups)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Expanded(
                      child: Text(
                        group.label,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      group.value,
                      style: const TextStyle(
                        fontSize: 11.2,
                        fontWeight: FontWeight.w900,
                        color: _kPrimaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: group.progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE8ECEF),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      _kPrimaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AccessActivityList extends StatelessWidget {
  const _AccessActivityList({required this.items});

  final List<_AccessActivityRecord> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFCFD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE7ECE8)),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(item.icon, size: 18, color: item.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.title,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 10.2,
                            color: Color(0xFF6F7680),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.timeLabel,
                    style: const TextStyle(
                      fontSize: 10.6,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6F7680),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AccessSessionList extends StatelessWidget {
  const _AccessSessionList({required this.items});

  final List<_AccessSessionRecord> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFCFD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE7ECE8)),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: item.avatarColor,
                    child: Text(
                      item.name.isNotEmpty ? item.name[0] : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.name,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12.4,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.platform,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 10.2,
                            color: Color(0xFF6F7680),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _AccessPill(label: item.status, color: item.statusColor),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AccessAdminOpsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = const [
      ('إنشاء موظف جديد', Icons.person_add_alt_rounded, 'منذ يوم'),
      ('تعديل دور موظف', Icons.edit_outlined, 'منذ يومين'),
      ('حذف موظف', Icons.delete_outline_rounded, 'منذ 3 أيام'),
      ('تحديث صلاحيات', Icons.verified_user_outlined, 'منذ 4 أيام'),
      ('تغيير إعدادات النظام', Icons.settings_outlined, 'منذ 5 أيام'),
    ];

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFCFD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE7ECE8)),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(item.$2, size: 18, color: _kPrimaryGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.$1,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 12.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.$3,
                    style: const TextStyle(
                      fontSize: 10.4,
                      color: Color(0xFF6F7680),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AccessQuickActionsGrid extends StatelessWidget {
  const _AccessQuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'استخدم جداول الموظفين والأدوار لتنفيذ الإجراءات مع التحقق من الصلاحيات.',
      textAlign: TextAlign.right,
      style: TextStyle(
        color: Color(0xFF6F7680),
        fontWeight: FontWeight.w700,
        height: 1.5,
      ),
    );
  }
}

class _AccessNotesCard extends StatelessWidget {
  const _AccessNotesCard({required this.serverNow});

  final DateTime serverNow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AccessNoteLine(
          label: 'آخر تحديث',
          value: _formatArabicDateLabel(serverNow),
        ),
        const SizedBox(height: 8),
        _AccessNoteLine(label: 'أعلى صلاحية', value: 'مدير النظام'),
        const SizedBox(height: 8),
        _AccessNoteLine(label: 'أكثر استخداماً', value: 'إدارة الطلبات'),
        const SizedBox(height: 8),
        _AccessNoteLine(label: 'متوسط النشاط', value: '62%'),
      ],
    );
  }
}

class _AccessEmployeeTable extends StatelessWidget {
  const _AccessEmployeeTable({
    required this.items,
    required this.canManage,
    this.onEdit,
    this.onToggle,
    this.onResetPassword,
    this.onDelete,
  });

  final List<_AccessEmployeeRecord> items;
  final bool canManage;
  final ValueChanged<_AccessEmployeeRecord>? onEdit;
  final Future<void> Function(_AccessEmployeeRecord, bool)? onToggle;
  final Future<void> Function(_AccessEmployeeRecord)? onResetPassword;
  final Future<void> Function(_AccessEmployeeRecord)? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AccessTableHeaderRow(
          columns: const [
            'الموظف',
            'الوظيفة',
            'الإدارة',
            'الدور',
            'الحالة',
            'آخر دخول',
            'الإجراءات',
          ],
        ),
        const SizedBox(height: 10),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AccessEmployeeTableRow(
              item: item,
              canManage: canManage,
              onEdit: onEdit,
              onToggle: onToggle,
              onResetPassword: onResetPassword,
              onDelete: onDelete,
            ),
          ),
      ],
    );
  }
}

class _AccessRoleTable extends StatelessWidget {
  const _AccessRoleTable({
    required this.items,
    required this.canManage,
    this.onEdit,
    this.onDelete,
  });

  final List<MasterRoleProfile> items;
  final bool canManage;
  final ValueChanged<MasterRoleProfile>? onEdit;
  final Future<void> Function(MasterRoleProfile)? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AccessTableHeaderRow(
          columns: const [
            'الدور',
            'الوصف',
            'عدد الموظفين',
            'الصلاحيات',
            'الحالة',
            'آخر تعديل',
            'الإجراءات',
          ],
        ),
        const SizedBox(height: 10),
        for (var index = 0; index < items.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AccessRoleTableRow(
              role: items[index],
              employeeCount: 0,
              permissionsCount: items[index].permissions.length,
              active: true,
              updatedLabel: '-',
              canManage: canManage,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ),
      ],
    );
  }
}

class _AccessRoleDetailSidebar extends StatelessWidget {
  const _AccessRoleDetailSidebar();

  @override
  Widget build(BuildContext context) {
    final sections = const [
      'لوحة العمليات',
      'إدارة الطلبات',
      'التوصيل والوجستيات',
      'إدارة المطاعم',
      'إدارة العملاء والمستخدمين',
      'الإدارة المالية',
      'التسويق والنمو',
      'مركز التواصل',
      // 'الجودة وخدمة العملاء' removed per user request
      'التقارير والتحليلات',
      'إعدادات المنصة',
      'الإدارة والصلاحيات',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AccessPanelBox(
          title: 'معلومات الدور المحدد',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'مدير النظام',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              const Text(
                'صلاحيات كاملة على جميع الأقسام والإعدادات',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11.2, color: Color(0xFF6F7680)),
              ),
              const SizedBox(height: 12),
              for (final section in sections)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AccessPermissionCheckboxRow(
                    label: section,
                    checked:
                        section != 'التقارير والتحليلات' &&
                        section != 'إعدادات المنصة',
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _AccessPanelBox(
          title: 'أفضل الأدوار أداءً',
          child: const Column(
            children: [
              _AccessRolePerformanceRow(label: 'مدير النظام', value: '85%'),
              SizedBox(height: 10),
              _AccessRolePerformanceRow(label: 'مدير العمليات', value: '78%'),
              SizedBox(height: 10),
              _AccessRolePerformanceRow(label: 'المحاسب', value: '65%'),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccessEmployeeFilterSidebar extends StatelessWidget {
  const _AccessEmployeeFilterSidebar();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _filterField(label: 'البحث', hint: 'ابحث...'),
        const SizedBox(height: 10),
        _filterField(label: 'الإدارة', hint: 'كل الإدارات'),
        const SizedBox(height: 10),
        _filterField(label: 'الدور', hint: 'كل الأدوار'),
        const SizedBox(height: 10),
        _filterField(label: 'الحالة', hint: 'كل الحالات'),
        const SizedBox(height: 10),
        _filterField(label: 'تاريخ الانضمام', hint: 'من / إلى'),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => _showMasterSnack(context, 'تم تطبيق الفلاتر محليًا'),
          child: const Text('تطبيق الفلاتر'),
        ),
        const SizedBox(height: 12),
        const _AccessPanelBox(
          title: 'إجراءات سريعة',
          child: _AccessQuickActionsGrid(),
        ),
      ],
    );
  }
}

Widget _filterField({required String label, required String hint}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        textAlign: TextAlign.right,
        style: const TextStyle(
          fontSize: 11.2,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4E5660),
        ),
      ),
      const SizedBox(height: 6),
      Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFCFD),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7ECE8)),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            const Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: Color(0xFF4E5660),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hint,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 11.2,
                  color: Color(0xFF8B929B),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _AccessModuleToggles extends StatelessWidget {
  const _AccessModuleToggles();

  @override
  Widget build(BuildContext context) {
    final items = const [
      ('الطلبات', true),
      ('التوصيل المباشر', true),
      ('المحفظة', true),
      ('الكوبونات', true),
      ('التقييمات', true),
      ('وضع الصيانة', false),
    ];

    return Column(
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _AccessToggleRow(label: item.$1, value: item.$2),
          ),
      ],
    );
  }
}

class _AccessBackupPanel extends StatelessWidget {
  const _AccessBackupPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showMasterSnack(
                  context,
                  'استعادة النسخة الاحتياطية تحتاج ملفًا محددًا',
                ),
                icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                label: const Text('استعادة'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    _showMasterSnack(context, 'تم طلب إنشاء نسخة احتياطية'),
                icon: const Icon(Icons.cloud_download_outlined, size: 18),
                label: const Text('إنشاء نسخة'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _AccessNoteLine(label: 'آخر نسخة احتياطية', value: '-'),
        const SizedBox(height: 8),
        const _AccessNoteLine(label: 'الحالة', value: 'نجحت'),
      ],
    );
  }
}

class _AccessSettingsCard extends StatelessWidget {
  const _AccessSettingsCard({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            children: [
              Icon(icon, size: 18, color: _kPrimaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          const Text(
            'عرض التفاصيل',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6F7680),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessPill extends StatelessWidget {
  const _AccessPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.8,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _AccessNoteLine extends StatelessWidget {
  const _AccessNoteLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 11.8,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6F7680),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E232A),
          ),
        ),
      ],
    );
  }
}

class _AccessPanelBox extends StatelessWidget {
  const _AccessPanelBox({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12.8, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AccessToggleRow extends StatelessWidget {
  const _AccessToggleRow({required this.label, required this.value});

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11.8, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Switch(value: value, onChanged: null),
      ],
    );
  }
}

class _AccessPermissionCheckboxRow extends StatelessWidget {
  const _AccessPermissionCheckboxRow({
    required this.label,
    required this.checked,
  });

  final String label;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Checkbox(value: checked, onChanged: null),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11.2, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _AccessRolePerformanceRow extends StatelessWidget {
  const _AccessRolePerformanceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 11.6, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11.6,
            fontWeight: FontWeight.w800,
            color: _kPrimaryGreen,
          ),
        ),
      ],
    );
  }
}

class _AccessTableHeaderRow extends StatelessWidget {
  const _AccessTableHeaderRow({required this.columns});

  final List<String> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFCFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          for (var index = 0; index < columns.length; index++) ...[
            Expanded(
              child: Text(
                columns[index],
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 10.8,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF4E5660),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccessEmployeeTableRow extends StatelessWidget {
  const _AccessEmployeeTableRow({
    required this.item,
    required this.canManage,
    this.onEdit,
    this.onToggle,
    this.onResetPassword,
    this.onDelete,
  });

  final _AccessEmployeeRecord item;
  final bool canManage;
  final ValueChanged<_AccessEmployeeRecord>? onEdit;
  final Future<void> Function(_AccessEmployeeRecord, bool)? onToggle;
  final Future<void> Function(_AccessEmployeeRecord)? onResetPassword;
  final Future<void> Function(_AccessEmployeeRecord)? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: item.avatarColor,
                  child: Text(
                    item.name.isNotEmpty ? item.name[0] : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.name,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              item.jobTitle,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11.4),
            ),
          ),
          Expanded(
            child: Text(
              item.department,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11.4),
            ),
          ),
          Expanded(
            child: Text(
              item.roleLabel,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11.4),
            ),
          ),
          Expanded(
            child: _AccessPill(label: item.status, color: item.statusColor),
          ),
          Expanded(
            child: Text(
              item.lastLogin,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11.2, color: Color(0xFF6F7680)),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _RowActionIcon(
                  icon: Icons.edit_outlined,
                  tooltip: 'تعديل',
                  onTap: canManage && onEdit != null
                      ? () => onEdit!(item)
                      : null,
                ),
                const SizedBox(width: 6),
                _RowActionIcon(
                  icon: item.isActive
                      ? Icons.lock_outline_rounded
                      : Icons.lock_open_rounded,
                  tooltip: item.isActive ? 'تعطيل' : 'تفعيل',
                  onTap: canManage && onToggle != null
                      ? () => onToggle!(item, !item.isActive)
                      : null,
                ),
                const SizedBox(width: 6),
                _RowActionIcon(
                  icon: Icons.password_rounded,
                  tooltip: 'إعادة كلمة المرور',
                  onTap: canManage && onResetPassword != null
                      ? () => onResetPassword!(item)
                      : null,
                ),
                const SizedBox(width: 6),
                _RowActionIcon(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'حذف',
                  onTap: canManage && !item.isSuperAdmin && onDelete != null
                      ? () => onDelete!(item)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessRoleTableRow extends StatelessWidget {
  const _AccessRoleTableRow({
    required this.role,
    required this.employeeCount,
    required this.permissionsCount,
    required this.active,
    required this.updatedLabel,
    required this.canManage,
    this.onEdit,
    this.onDelete,
  });

  final MasterRoleProfile role;
  final int employeeCount;
  final int permissionsCount;
  final bool active;
  final String updatedLabel;
  final bool canManage;
  final ValueChanged<MasterRoleProfile>? onEdit;
  final Future<void> Function(MasterRoleProfile)? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7ECE8)),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: role.tintColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.brightness_1,
                    size: 10,
                    color: role.tintColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    role.roleName,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12.4,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              role.roleScope,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11.2),
            ),
          ),
          Expanded(
            child: Text(
              '$employeeCount',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11.2),
            ),
          ),
          Expanded(
            child: Text(
              '$permissionsCount',
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11.2),
            ),
          ),
          Expanded(
            child: _AccessPill(
              label: active ? 'نشط' : 'مغلق',
              color: active ? _kPrimaryGreen : const Color(0xFFD92C2C),
            ),
          ),
          Expanded(
            child: Text(
              updatedLabel,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11.2, color: Color(0xFF6F7680)),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _RowActionIcon(
                  icon: Icons.edit_outlined,
                  tooltip: 'تعديل',
                  onTap: canManage && onEdit != null
                      ? () => onEdit!(role)
                      : null,
                ),
                const SizedBox(width: 6),
                _RowActionIcon(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'حذف',
                  onTap: canManage && role.roleId != 1 && onDelete != null
                      ? () => onDelete!(role)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowActionIcon extends StatelessWidget {
  const _RowActionIcon({required this.icon, this.tooltip = '', this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: onTap == null
              ? const Color(0xFFF1F3F4)
              : const Color(0xFFF8FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE7ECE8)),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 14,
          color: onTap == null
              ? const Color(0xFFB8BEC5)
              : const Color(0xFF4E5660),
        ),
      ),
    );
    if (tooltip.isEmpty) {
      return button;
    }
    return Tooltip(message: tooltip, child: button);
  }
}

class _AccessMetricData {
  const _AccessMetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.background,
    required this.trend,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color background;
  final String trend;
}

class _AccessManagementData {
  const _AccessManagementData({
    required this.roles,
    required this.employees,
    required this.activities,
    required this.sessions,
    required this.onboardingQueue,
    required this.settlements,
    required this.fraudAlerts,
    required this.disputeCases,
    required this.broadcasts,
    required this.moderationQueue,
    required this.returns,
    required this.stockRules,
    required this.scheduledExports,
    required this.pendingRestaurants,
    required this.pendingDrivers,
  });

  final List<MasterRoleProfile> roles;
  final List<_AccessEmployeeRecord> employees;
  final List<_AccessActivityRecord> activities;
  final List<_AccessSessionRecord> sessions;
  final List<_AccessGenericRecord> onboardingQueue;
  final List<_AccessGenericRecord> settlements;
  final List<_AccessGenericRecord> fraudAlerts;
  final List<_AccessGenericRecord> disputeCases;
  final List<_AccessGenericRecord> broadcasts;
  final List<_AccessGenericRecord> moderationQueue;
  final List<_AccessGenericRecord> returns;
  final List<_AccessGenericRecord> stockRules;
  final List<_AccessGenericRecord> scheduledExports;
  final List<_AccessApprovalRecord> pendingRestaurants;
  final List<_AccessApprovalRecord> pendingDrivers;

  factory _AccessManagementData.empty() {
    return const _AccessManagementData(
      roles: <MasterRoleProfile>[],
      employees: <_AccessEmployeeRecord>[],
      activities: <_AccessActivityRecord>[],
      sessions: <_AccessSessionRecord>[],
      onboardingQueue: <_AccessGenericRecord>[],
      settlements: <_AccessGenericRecord>[],
      fraudAlerts: <_AccessGenericRecord>[],
      disputeCases: <_AccessGenericRecord>[],
      broadcasts: <_AccessGenericRecord>[],
      moderationQueue: <_AccessGenericRecord>[],
      returns: <_AccessGenericRecord>[],
      stockRules: <_AccessGenericRecord>[],
      scheduledExports: <_AccessGenericRecord>[],
      pendingRestaurants: <_AccessApprovalRecord>[],
      pendingDrivers: <_AccessApprovalRecord>[],
    );
  }

  factory _AccessManagementData.fromRaw({
    required List<MasterRoleProfile> roles,
    required Map<String, dynamic> raw,
  }) {
    return _AccessManagementData(
      roles: roles,
      employees: _asMapList(
        raw['employees'],
      ).map(_AccessEmployeeRecord.fromJson).toList(),
      activities: _asMapList(
        raw['audit_logs'],
      ).map(_AccessActivityRecord.fromJson).toList(),
      sessions: _asMapList(
        raw['sessions'],
      ).map(_AccessSessionRecord.fromJson).toList(),
      onboardingQueue: _asMapList(raw['onboarding_queue'])
          .map((row) => _AccessGenericRecord.fromJson(row, kind: 'onboarding'))
          .toList(),
      pendingRestaurants: _asMapList(raw['pending_restaurants'])
          .map((row) => _AccessApprovalRecord.fromJson(row, kind: 'restaurant'))
          .toList(),
      pendingDrivers: _asMapList(raw['pending_drivers'])
          .map((row) => _AccessApprovalRecord.fromJson(row, kind: 'driver'))
          .toList(),
      settlements: _asMapList(raw['settlements'])
          .map((row) => _AccessGenericRecord.fromJson(row, kind: 'settlement'))
          .toList(),
      fraudAlerts: _asMapList(
        raw['fraud_alerts'],
      ).map((row) => _AccessGenericRecord.fromJson(row, kind: 'risk')).toList(),
      disputeCases: _asMapList(raw['dispute_cases'])
          .map((row) => _AccessGenericRecord.fromJson(row, kind: 'dispute'))
          .toList(),
      broadcasts: _asMapList(raw['broadcasts'])
          .map((row) => _AccessGenericRecord.fromJson(row, kind: 'broadcast'))
          .toList(),
      moderationQueue: _asMapList(raw['moderation_queue'])
          .map((row) => _AccessGenericRecord.fromJson(row, kind: 'moderation'))
          .toList(),
      returns: _asMapList(raw['returns'])
          .map((row) => _AccessGenericRecord.fromJson(row, kind: 'return'))
          .toList(),
      stockRules: _asMapList(raw['stock_rules'])
          .map((row) => _AccessGenericRecord.fromJson(row, kind: 'stock'))
          .toList(),
      scheduledExports: _asMapList(raw['scheduled_exports'])
          .map((row) => _AccessGenericRecord.fromJson(row, kind: 'export'))
          .toList(),
    );
  }
}

class _AccessGenericRecord {
  const _AccessGenericRecord({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.tint,
    required this.icon,
  });

  final int id;
  final String title;
  final String subtitle;
  final String status;
  final Color tint;
  final IconData icon;

  factory _AccessGenericRecord.fromJson(
    Map<String, dynamic> json, {
    required String kind,
  }) {
    final title = _firstText([
      json['campaign_title'],
      json['alert_title'],
      json['order_label'],
      json['item_label'],
      json['export_name'],
      json['vendor_name'],
      json['step_name'],
      json['name'],
      'سجل',
    ]);
    final subtitle = _firstText([
      json['alert_detail'],
      json['issue_text'],
      json['reason_text'],
      json['schedule_label'],
      json['audience_label'],
      json['period_label'],
      json['owner_label'],
      json['channel_label'],
      json['format_label'],
      '-',
    ]);
    final status = _firstText([
      json['status_label'],
      json['state_label'],
      json['format_label'],
      json['is_active'] == 1 || json['is_active'] == true ? 'active' : null,
      '-',
    ]);
    final id = _toInt(
      json['report_id'] ??
          json['return_id'] ??
          json['case_id'] ??
          json['alert_id'] ??
          json['moderation_id'] ??
          json['export_id'] ??
          json['vendor_id'] ??
          json['queue_id'],
    );

    return _AccessGenericRecord(
      id: id,
      title: title,
      subtitle: subtitle,
      status: status,
      tint: _hexToColor(
        json['tint_hex']?.toString(),
        fallback: _kindTint(kind),
      ),
      icon: _kindIcon(kind),
    );
  }
}

Color _kindTint(String kind) {
  switch (kind) {
    case 'risk':
    case 'dispute':
      return const Color(0xFFD92C2C);
    case 'broadcast':
      return const Color(0xFF0D4D8B);
    case 'export':
      return const Color(0xFF1A8B4A);
    case 'settlement':
      return const Color(0xFFF59E0B);
    case 'moderation':
      return const Color(0xFF7C3AED);
    default:
      return const Color(0xFF1A8B4A);
  }
}

IconData _kindIcon(String kind) {
  switch (kind) {
    case 'risk':
      return Icons.warning_amber_rounded;
    case 'dispute':
      return Icons.support_agent_rounded;
    case 'broadcast':
      return Icons.notifications_active_outlined;
    case 'export':
      return Icons.file_download_outlined;
    case 'settlement':
      return Icons.account_balance_wallet_outlined;
    case 'moderation':
      return Icons.fact_check_outlined;
    case 'onboarding':
      return Icons.storefront_outlined;
    default:
      return Icons.info_outline_rounded;
  }
}

class _AccessEmployeeRecord {
  const _AccessEmployeeRecord({
    required this.adminId,
    required this.roleId,
    required this.name,
    required this.email,
    required this.phone,
    required this.department,
    required this.roleLabel,
    required this.jobTitle,
    required this.status,
    required this.statusColor,
    required this.lastLogin,
    required this.avatarColor,
    required this.isActive,
    required this.isSuperAdmin,
  });

  final int adminId;
  final int roleId;
  final String name;
  final String email;
  final String phone;
  final String department;
  final String roleLabel;
  final String jobTitle;
  final String status;
  final Color statusColor;
  final String lastLogin;
  final Color avatarColor;
  final bool isActive;
  final bool isSuperAdmin;

  factory _AccessEmployeeRecord.fromJson(Map<String, dynamic> json) {
    final statusText = _firstText([json['status'], 'غير نشط']);
    final statusKey = (json['status_key'] ?? '').toString().toLowerCase();
    final isActive = statusKey == 'active' || statusText == 'نشط';
    final isSuperAdmin =
        _toInt(json['admin_role_id'] ?? json['role_id']) == 1 ||
        (json['is_super_admin'] ?? false) == true;

    return _AccessEmployeeRecord(
      adminId: _toInt(json['admin_id'] ?? json['id']),
      roleId: _toInt(json['role_id'] ?? json['admin_role_id']),
      name: _firstText([json['name'], json['admin_name'], 'موظف']),
      email: _firstText([json['email'], json['admin_email'], '-']),
      phone: _firstText([json['phone'], json['admin_phone'], '-']),
      department: _firstText([json['department'], 'Master Control']),
      roleLabel: _firstText([json['role_label'], json['role_name'], '-']),
      jobTitle: _firstText([json['job_title'], json['role_label'], '-']),
      status: statusText,
      statusColor: _hexToColor(
        json['status_hex']?.toString(),
        fallback: const Color(0xFFF59E0B),
      ),
      lastLogin: _firstText([json['last_login'], '-']),
      avatarColor: _hexToColor(json['avatar_hex']?.toString()),
      isActive: isActive,
      isSuperAdmin: isSuperAdmin,
    );
  }
}

class _AccessApprovalRecord {
  const _AccessApprovalRecord({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.kind,
  });

  final int id;
  final String title;
  final String subtitle;
  final String status;
  final String kind;

  factory _AccessApprovalRecord.fromJson(
    Map<String, dynamic> json, {
    required String kind,
  }) {
    final isStore =
        (json['vendor_type'] ?? '').toString().toLowerCase() == 'store';
    final entityName = _firstText([
      json['restaurant_name'],
      json['store_name'],
      json['driver_name'],
      json['name'],
      'عنصر',
    ]);
    return _AccessApprovalRecord(
      id: _toInt(json['vendor_id'] ?? json['driver_id'] ?? json['id']),
      title: kind == 'restaurant' && isStore
          ? '$entityName (متجر)'
          : entityName,
      subtitle: _firstText([
        json['owner_name'],
        json['phone'],
        json['email'],
        json['address'],
        'قيد المراجعة',
      ]),
      status: _firstText([json['status'], 'pending']),
      kind: kind,
    );
  }
}

class _AccessActivityRecord {
  const _AccessActivityRecord({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String timeLabel;
  final IconData icon;
  final Color accent;

  factory _AccessActivityRecord.fromJson(Map<String, dynamic> json) {
    return _AccessActivityRecord(
      title: _firstText([json['action_text'], json['title'], 'نشاط إداري']),
      subtitle: _firstText([json['entity_label'], json['subtitle'], '-']),
      timeLabel: _firstText([json['action_time_label'], json['time'], '-']),
      icon: _iconFromKey(json['icon_key']?.toString() ?? 'activity'),
      accent: _hexToColor(json['tint_hex']?.toString()),
    );
  }
}

class _AccessSessionRecord {
  const _AccessSessionRecord({
    required this.name,
    required this.platform,
    required this.status,
    required this.statusColor,
    required this.avatarColor,
  });

  final String name;
  final String platform;
  final String status;
  final Color statusColor;
  final Color avatarColor;

  factory _AccessSessionRecord.fromJson(Map<String, dynamic> json) {
    return _AccessSessionRecord(
      name: _firstText([json['name'], json['admin_name'], 'جلسة']),
      platform: _firstText([json['platform'], json['user_agent'], '-']),
      status: _firstText([json['status'], 'نشطة']),
      statusColor: _hexToColor(json['status_hex']?.toString()),
      avatarColor: _hexToColor(json['avatar_hex']?.toString()),
    );
  }
}

class _AccessPermissionCoverageData {
  const _AccessPermissionCoverageData(this.label, this.progress, this.value);

  final String label;
  final double progress;
  final String value;
}

String _csvCell(String value) {
  final normalized = value.replaceAll('"', '""');
  return '"$normalized"';
}

InputDecoration _searchDecoration(String hintText) {
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: const Color(0xFFFBFCFD),
    hintText: hintText,
    hintStyle: const TextStyle(fontSize: 11.4, color: Color(0xFF8B929B)),
    prefixIcon: const Icon(Icons.search_rounded, size: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE7ECE8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFE7ECE8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: _kPrimaryGreen, width: 1.2),
    ),
  );
}
