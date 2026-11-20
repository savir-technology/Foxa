import 'package:admin_tks/remote/master_vendors_data.dart';
import 'package:admin_tks/theme.dart';
import 'package:admin_tks/widgets/dashboard_page_shell.dart';
import 'package:flutter/material.dart';

class VendorsPage extends StatefulWidget {
  const VendorsPage({super.key});

  @override
  State<VendorsPage> createState() => _VendorsPageState();
}

class _VendorsPageState extends State<VendorsPage> {
  final MasterVendorsData _vendorsData = MasterVendorsData();
  final TextEditingController _searchController = TextEditingController();

  List<MasterVendorRecord> _vendors = const [];
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    setState(() => _isLoading = true);
    try {
      _vendors = await _vendorsData.fetchVendors();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(MasterVendorRecord vendor, String status) async {
    if (_isUpdating) return;
    setState(() => _isUpdating = true);
    try {
      await _vendorsData.updateVendorStatus(
        vendorId: vendor.vendorId,
        status: status,
      );
      await _loadVendors();
    } catch (e) {
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  List<MasterVendorRecord> get _filteredVendors {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _vendors;

    return _vendors.where((vendor) {
      final haystack = [
        vendor.vendorName,
        vendor.storeName,
        vendor.storeSlug,
        vendor.email,
        vendor.phone,
        '${vendor.vendorId}',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final activeCount =
        _vendors.where((vendor) => vendor.status == 'active').length;
    final pendingCount =
        _vendors.where((vendor) => vendor.status == 'pending').length;
    final suspendedCount =
        _vendors.where((vendor) => vendor.status == 'suspended').length;

    return DashboardPageShell(
      title: 'البائعون',
      subtitle: 'إدارة المتاجر وحالة التفعيل من لوحة الماستر.',
      icon: Icons.store_mall_directory_rounded,
      actions: [
        IconButton.filledTonal(
          onPressed: _loadVendors,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      stats: [
        DashboardStatCard(
          label: 'إجمالي البائعين',
          value: '${_vendors.length}',
          icon: Icons.groups_rounded,
          tint: kPrimary,
        ),
        DashboardStatCard(
          label: 'نشط',
          value: '$activeCount',
          icon: Icons.verified_rounded,
          tint: kAccent,
        ),
        DashboardStatCard(
          label: 'معلق',
          value: '$pendingCount',
          icon: Icons.hourglass_bottom_rounded,
          tint: kSecondary,
        ),
        DashboardStatCard(
          label: 'موقوف',
          value: '$suspendedCount',
          icon: Icons.pause_circle_rounded,
          tint: Colors.redAccent,
        ),
      ],
      body: Column(
        children: [
          DashboardPanel(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'ابحث باسم البائع أو المتجر أو البريد',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: Center(child: CircularProgressIndicator(color: kPrimary)),
            )
          else if (_filteredVendors.isEmpty)
            const DashboardEmptyState(
              title: 'لا يوجد بائعون مطابقون',
              subtitle: 'جرّب كلمة بحث أخرى أو أضف بائعين جدد للنظام.',
              icon: Icons.storefront_outlined,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredVendors.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final vendor = _filteredVendors[index];
                return _VendorCard(
                  vendor: vendor,
                  isUpdating: _isUpdating,
                  onStatusChanged: (status) => _updateStatus(vendor, status),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _VendorCard extends StatelessWidget {
  const _VendorCard({
    required this.vendor,
    required this.isUpdating,
    required this.onStatusChanged,
  });

  final MasterVendorRecord vendor;
  final bool isUpdating;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _VendorStatusChip(status: vendor.status),
              if (vendor.isVerified)
                const _VendorBadge(
                  label: 'Verified',
                  color: kAccent,
                ),
              Text(
                vendor.storeName.isNotEmpty
                    ? vendor.storeName
                    : vendor.vendorName,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'البائع: ${vendor.vendorName}',
            style: const TextStyle(color: kTextSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'البريد: ${vendor.email}',
            style: const TextStyle(color: kTextSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'الهاتف: ${vendor.phone.isEmpty ? 'غير متوفر' : vendor.phone}',
            style: const TextStyle(color: kTextSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'المعرف: #${vendor.vendorId}  |  slug: ${vendor.storeSlug}',
            style: const TextStyle(color: kTextSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in const ['pending', 'active', 'suspended'])
                ChoiceChip(
                  selected: vendor.status == status,
                  label: Text(status.toUpperCase()),
                  onSelected:
                      isUpdating ? null : (_) => onStatusChanged(status),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VendorStatusChip extends StatelessWidget {
  const _VendorStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' => kAccent,
      'suspended' => Colors.redAccent,
      _ => kSecondary,
    };

    return _VendorBadge(
      label: status.toUpperCase(),
      color: color,
    );
  }
}

class _VendorBadge extends StatelessWidget {
  const _VendorBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
