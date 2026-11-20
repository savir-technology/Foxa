import 'package:flutter/material.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:get/get.dart';
import 'package:tks/controler/orders/details.dart';
import 'package:tks/core/class/handlingdataview.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/data/datasource/model/itemsmodel.dart';

class OrdersDetails extends StatelessWidget {
  const OrdersDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: GetBuilder<OrdersDetailsController>(
        init: OrdersDetailsController(),
        global: false,
        builder: (controller) {
          final canRateItems = controller.ordersModel.isDeliveredOrder;

          return HandlingDataView(
            statusRequest: controller.statusRequest,
            widget: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.72),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withValues(alpha: 0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'الطلب #${controller.ordersModel.ordersId}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'الإجمالي: ${controller.ordersModel.ordersTotalprice ?? '0'} ${AppCurrency.code}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                        ),
                      ),
                      if ((controller.ordersModel.ordersRecipientName ?? '')
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'المستلم: ${controller.ordersModel.ordersRecipientName}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      if ((controller.ordersModel.ordersGiftMessage ?? '')
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'رسالة الإهداء: ${controller.ordersModel.ordersGiftMessage}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      if ((controller.ordersModel.ordersDeliveryNote ?? '')
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'ملاحظات التوصيل: ${controller.ordersModel.ordersDeliveryNote}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Get.toNamed(
                                  AppRoutes.orderTracking,
                                  arguments: controller.ordersModel.toJson(),
                                );
                              },
                              icon: const Icon(Icons.location_searching_rounded),
                              label: const Text('تتبع الطلب'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: controller.reorderCurrentOrder,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('إعادة الطلب'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...controller.data.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.72),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.itemsNameAr ?? item.itemsNameEn ?? '',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if ((item.cartItemColor ?? '').isNotEmpty ||
                            (item.cartItemSize ?? '').isNotEmpty)
                          Text(
                            'اللون: ${item.cartItemColor ?? '-'} | المقاس: ${item.cartItemSize ?? '-'}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        if ((item.cartLensName ?? '').isNotEmpty)
                          Text(
                            'الإضافات: ${item.cartLensName}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        if ((item.cartPrescriptionSummary ?? '').isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              item.cartPrescriptionSummary!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          'الكمية: ${item.countitems ?? '1'}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          'السعر: ${item.lineTotal ?? item.itemsPrice ?? '0'} ${AppCurrency.code}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colors.primary,
                          ),
                        ),
                        if ((item.itemsId ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: canRateItems
                                ? () {
                                    final itemsModel = ItemsModel(
                                      itemsId: item.itemsId,
                                      itemsNameEn: item.itemsNameEn,
                                      itemsNameAr: item.itemsNameAr,
                                      itemsDescEn: item.itemsDescEn,
                                      itemsDescAr: item.itemsDescAr,
                                      itemsImage: item.itemsImage,
                                      itemsPrice: item.itemsPrice,
                                      itemsDiscount: item.itemsDiscount,
                                      itemsCount: item.itemsCount,
                                      itemsActive: item.itemsActive,
                                      vendorId: item.cartVendorId,
                                      vendorName: controller.ordersModel.vendorName,
                                      storeName: controller.ordersModel.storeName,
                                      vendorLogo: controller.ordersModel.vendorLogo,
                                      averageRating: '0',
                                      ratingsCount: '0',
                                      ratingPercentage: '0',
                                    );

                                    Get.toNamed(
                                      AppRoutes.productdetails,
                                      arguments: {
                                        'item_id': itemsModel.itemsId,
                                        'itemsmodel': itemsModel,
                                      },
                                      parameters: {
                                        'item_id': itemsModel.itemsId ?? '',
                                        'mode': 'review',
                                      },
                                    );
                                  }
                                : null,
                            icon: Icon(
                              canRateItems
                                  ? Icons.star_border_rounded
                                  : Icons.lock_outline_rounded,
                            ),
                            label: Text(
                              canRateItems
                                  ? 'تقييم المنتج والمطعم'
                                  : 'متاح بعد الاستلام',
                            ),
                          ),
                          if (!canRateItems) ...[
                            const SizedBox(height: 6),
                            Text(
                              'يمكنك تقييم المنتج والمطعم بعد استلام الطلب فقط.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withValues(alpha: 0.72),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                if (controller.ordersModel.ordersType == "0")
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.72),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'عنوان التوصيل',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        _buildDeliveryAddress(
                          controller.ordersModel.addressCity,
                          controller.ordersModel.addressStreet,
                          controller.ordersModel.ordersRecipientAddressName,
                          controller.ordersModel.ordersRecipientAddressLine,
                        ),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _buildDeliveryAddress(
    String? city,
    String? street,
    String? recipientAddressName,
    String? recipientAddressLine,
  ) {
    final primary = [city ?? '', street ?? '']
        .where((item) => item.trim().isNotEmpty)
        .join(' ');
    if (primary.trim().isNotEmpty) {
      return primary;
    }
    return [
      recipientAddressName ?? '',
      recipientAddressLine ?? '',
    ].where((item) => item.trim().isNotEmpty).join(' - ');
  }
}
