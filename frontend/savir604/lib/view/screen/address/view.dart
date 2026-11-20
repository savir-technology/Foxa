import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/address/view_controller.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/data/datasource/model/addressmodel.dart';
import 'package:tks/view/widget/common/app_top_banner.dart';

class AddressView extends StatelessWidget {
  const AddressView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AddressViewController());
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primary.withValues(alpha: 0.10),
              theme.scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: GetBuilder<AddressViewController>(
            builder: (controller) {
              return Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                    children: [
                      _AddressHero(count: controller.data.length),
                      const SizedBox(height: 18),
                      if (controller.statusRequest == StatusRequest.loading)
                        const Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (controller.data.isEmpty)
                        _EmptyAddressState(
                          onAdd: () async {
                            final result =
                                await Get.toNamed(AppRoutes.addressadddetails);
                            if (result == true) {
                              controller.getData();
                            }
                          },
                        )
                      else
                        ...controller.data.map(
                          (address) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: CardAddress(
                              addressModel: address,
                              onDelete: () =>
                                  controller.deleteAddress(address.addressId!),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: SafeArea(
                      top: false,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result =
                              await Get.toNamed(AppRoutes.addressadddetails);
                          if (result == true) {
                            controller.getData();
                          }
                        },
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: Text('Add new address'.tr),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(58),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AddressHero extends StatelessWidget {
  final int count;

  const _AddressHero({required this.count});

  @override
  Widget build(BuildContext context) {
    return AppTopBanner(
      title: 'Saved addresses',
      subtitle:
          'Keep your delivery addresses ready so checkout stays fast and smooth.',
      leadingIcon: Icons.arrow_back_rounded,
      onLeadingTap: Get.back,
      trailingIcon: Icons.location_on_outlined,
      onTrailingTap: () {},
      child: AppTopBannerMetric(
        value: '$count',
        label: 'Saved places',
      ),
    );
  }
}

class _EmptyAddressState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyAddressState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: colors.primary.withValues(alpha: 0.12),
            child: Icon(Icons.map_outlined, color: colors.primary, size: 34),
          ),
          const SizedBox(height: 16),
          Text('No saved addresses yet'.tr, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Add your first address so it is ready when you place the next order.'
                .tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: Text('Create address'.tr),
          ),
        ],
      ),
    );
  }
}

class CardAddress extends StatelessWidget {
  final AddressModel addressModel;
  final void Function()? onDelete;

  const CardAddress({super.key, required this.addressModel, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.location_on_outlined, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  addressModel.addressName ?? '-',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AddressInfoRow(
            icon: Icons.location_city_outlined,
            text: addressModel.addressCity ?? '-',
          ),
          const SizedBox(height: 8),
          _AddressInfoRow(
            icon: Icons.signpost_outlined,
            text: addressModel.addressStreet ?? '-',
          ),
          const SizedBox(height: 8),
          _AddressInfoRow(
            icon: Icons.phone_outlined,
            text: addressModel.addressphone ?? '-',
          ),
        ],
      ),
    );
  }
}

class _AddressInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _AddressInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: theme.hintColor),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
