import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/address/adddetails_controller.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/view/widget/common/app_top_banner.dart';

class AddressAddDetails extends StatelessWidget {
  const AddressAddDetails({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AddAddressDetailsController());
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
          child: GetBuilder<AddAddressDetailsController>(
            builder: (controller) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  const _AddressAddHero(),
                  const SizedBox(height: 16),
                  _MapSelectionCard(
                    controller: controller,
                    onPickMap: controller.isPickingLocation
                        ? null
                        : controller.openMapPicker,
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Address details'.tr,
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _AddressField(
                            controller: controller.name,
                            label: 'Address name',
                            hint: 'Home, office, company...',
                            icon: Icons.place_outlined,
                          ),
                          const SizedBox(height: 12),
                          _AddressField(
                            controller: controller.city,
                            label: 'City',
                            hint: 'Enter the city name',
                            icon: Icons.location_city_outlined,
                          ),
                          const SizedBox(height: 12),
                          _AddressField(
                            controller: controller.street,
                            label: 'Street',
                            hint: 'Street name or district',
                            icon: Icons.signpost_outlined,
                          ),
                          const SizedBox(height: 12),
                          _AddressField(
                            controller: controller.phone,
                            label: 'Phone number',
                            hint: 'A number we can reach',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          _LocationSummary(
                            coordinates: controller.selectedCoordinates,
                            label: controller.selectedMapLabel,
                            hasSelection: controller.hasSelectedLocation,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  controller.statusRequest ==
                                          StatusRequest.loading
                                      ? null
                                      : controller.hasSelectedLocation
                                          ? controller.addAddress
                                          : null,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: controller.statusRequest ==
                                      StatusRequest.loading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text('Save address'.tr),
                            ),
                          ),
                        ],
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

class _AddressAddHero extends StatelessWidget {
  const _AddressAddHero();

  @override
  Widget build(BuildContext context) {
    return AppTopBanner(
      title: 'Add address',
      subtitle:
          'Enter the delivery address you want to receive the order at, whether it is for you or for someone else.',
      leadingIcon: Icons.arrow_back_rounded,
      onLeadingTap: Get.back,
      trailingIcon: Icons.add_location_alt_outlined,
      onTrailingTap: () {},
      child: const AppTopBannerMetric(
        value: '4',
        label: 'Required fields',
      ),
    );
  }
}

class _MapSelectionCard extends StatelessWidget {
  const _MapSelectionCard({
    required this.controller,
    required this.onPickMap,
  });

  final AddAddressDetailsController controller;
  final VoidCallback? onPickMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.map_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pick location on map'.tr,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose the exact delivery point on the map and keep it saved for checkout.'
                            .tr,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (controller.hasSelectedLocation) ...[
              _SelectedLocationPreview(
                label: controller.selectedMapLabel,
                coordinates: controller.selectedCoordinates,
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPickMap,
                icon: controller.isPickingLocation
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.place_outlined),
                label: Text(
                  controller.hasSelectedLocation
                      ? 'Change location'.tr
                      : 'Open map'.tr,
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedLocationPreview extends StatelessWidget {
  const _SelectedLocationPreview({
    required this.label,
    required this.coordinates,
  });

  final String label;
  final String coordinates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (coordinates.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              coordinates,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationSummary extends StatelessWidget {
  const _LocationSummary({
    required this.coordinates,
    required this.label,
    required this.hasSelection,
  });

  final String coordinates;
  final String label;
  final bool hasSelection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasSelection
            ? theme.colorScheme.primary.withValues(alpha: 0.08)
            : theme.colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasSelection ? 'Saved map location'.tr : 'Map location'.tr,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (coordinates.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              coordinates,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _AddressField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
        decoration: InputDecoration(
        labelText: label.tr,
        hintText: hint.tr,
        prefixIcon: Icon(icon, color: colors.primary),
        filled: true,
        fillColor:
            theme.inputDecorationTheme.fillColor ?? theme.scaffoldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
