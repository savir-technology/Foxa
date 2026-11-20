import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:tks/controler/cart/cart_controller.dart';
import 'package:tks/controler/checkout/checkout_controller.dart';
import 'package:tks/core/class/handlingdataview.dart';
import 'package:tks/core/constants/currency.dart';
import 'package:tks/core/constant/routes.dart';
import 'package:tks/view/widget/common/app_top_banner.dart';

class Checkout extends StatelessWidget {
  const Checkout({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(CheckoutController());
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.10),
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: GetBuilder<CheckoutController>(
            builder: (controller) => HandlingDataView(
              statusRequest: controller.statusRequest,
              widget: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: AppTopBanner(
                      title: 'إتمام الطلب',
                      subtitle:
                          'اختر طريقة الدفع، ومن يستلم الطلب، وكيفية التوصيل.',
                      leadingIcon: Icons.arrow_back_rounded,
                      onLeadingTap: Get.back,
                      trailingIcon: Icons.receipt_long_rounded,
                      onTrailingTap: () {},
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
                      children: [
                        _SectionCard(
                          title: 'من هذا الطلب؟',
                          child: Row(
                            children: [
                              Expanded(
                                child: _ChoiceCard(
                                  title: 'لي',
                                  subtitle: 'سيصل الطلب إلي',
                                  icon: Icons.person_outline_rounded,
                                  active: controller.orderFor == 'self',
                                  onTap: () => controller.chooseOrderFor('self'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ChoiceCard(
                                  title: 'لشخص آخر',
                                  subtitle: 'أرسل الطلب لشخص آخر',
                                  icon: Icons.card_giftcard_rounded,
                                  active: controller.orderFor == 'other',
                                  onTap: () => controller.chooseOrderFor('other'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (controller.isOrderingForOther) ...[
                          _SectionCard(
                            title: 'تفاصيل المستلم',
                            child: controller.selectedRecipient == null
                                ? _EmptyStateCard(
                                    title: 'لم يتم تحديد مستلم بعد',
                                    body:
                                        'اختر مستلمًا محفوظًا أو أضف مستلمًا جديدًا قبل إتمام الطلب.',
                                    buttonLabel: 'اختيار مستلم',
                                    icon: Icons.people_alt_outlined,
                                    onPressed: controller.openRecipientPicker,
                                  )
                                : _RecipientCard(controller: controller),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _SectionCard(
                          title: 'طريقة الدفع',
                          child: Column(
                            children: [
                              _PaymentOptionTile(
                                title: 'الدفع عند الاستلام',
                                subtitle: 'ادفع عند وصول الطلب للمستلم',
                                icon: Icons.payments_outlined,
                                active: controller.paymentMethod == '0',
                                onTap: () =>
                                    controller.choosePaymentMethod('0'),
                              ),
                              const SizedBox(height: 10),
                              _PaymentOptionTile(
                                title: 'الدفع الإلكتروني',
                                subtitle: 'استخدم بوابة الدفع الإلكترونية',
                                icon: Icons.credit_card_rounded,
                                active: controller.paymentMethod == '1',
                                onTap: () =>
                                    controller.choosePaymentMethod('1'),
                              ),
                              const SizedBox(height: 10),
                              _PaymentOptionTile(
                                title: 'المحفظة',
                                subtitle: 'استخدم رصيد المحفظة للدفع الفوري',
                                icon: Icons.account_balance_wallet_outlined,
                                active: controller.paymentMethod == '2',
                                onTap: () =>
                                    controller.choosePaymentMethod('2'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'طريقة التوصيل',
                          child: Column(
                            children: [
                              _PaymentOptionTile(
                                title: 'توصيل',
                                subtitle: controller.isOrderingForOther
                                    ? 'إلى عنوان المستلم المحدد'
                                    : 'إلى عنوانك المحفوظ',
                                icon: Icons.delivery_dining_outlined,
                                active: controller.deliveryType == '0',
                                onTap: () =>
                                    controller.chooseDeliveryType('0'),
                              ),
                              const SizedBox(height: 10),
                              _PaymentOptionTile(
                                title: 'استلام من المطعم',
                                subtitle:
                                    'بدون رسوم توصيل وسيتم إنشاء رمز استلام',
                                icon: Icons.storefront_outlined,
                                active: controller.deliveryType == '1',
                                onTap: () =>
                                    controller.chooseDeliveryType('1'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'موعد الطلب',
                          child: _OrderModeSummaryCard(controller: controller),
                        ),
                        const SizedBox(height: 16),
                        if (controller.deliveryType == '0' &&
                            !controller.isOrderingForOther) ...[
                          _SectionCard(
                            title: 'عنوان التوصيل',
                            child: Column(
                              children: [
                                if (controller.dataaddress.isEmpty)
                                  _EmptyStateCard(
                                    title: 'لم يتم العثور على عنوان محفوظ',
                                    body:
                                        'أضف عنوانًا من الخريطة حتى نصل للمكان الصحيح.',
                                    buttonLabel: 'إضافة عنوان من الخريطة',
                                    icon: Icons.location_on_outlined,
                                    onPressed: () async {
                                      await Get.toNamed(
                                        AppRoutes.addressadddetails,
                                      );
                                      controller.getShippingAddress();
                                    },
                                  )
                                else
                                  Column(
                                    children: controller.dataaddress
                                        .map(
                                          (address) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            child: _SelectionTile(
                                              title:
                                                  address.addressName ?? 'عنوان',
                                              subtitle:
                                                  '${address.addressCity ?? ''} ${address.addressStreet ?? ''}'
                                                      .trim(),
                                              active: controller.addressid ==
                                                  address.addressId,
                                              icon: Icons.location_on_outlined,
                                              onTap: () => controller
                                                  .chooseShippingAddress(
                                                address.addressId ?? '0',
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await Get.toNamed(
                                      AppRoutes.addressadddetails,
                                    );
                                    controller.getShippingAddress();
                                  },
                                  icon: const Icon(Icons.map_outlined),
                                  label: Text('إضافة عنوان من الخريطة'.tr),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                          _SectionCard(
                            title: 'ملاحظات الطلب',
                            child: Column(
                            children: [
                              if (controller.isOrderingForOther) ...[
                                TextField(
                                  controller: controller.giftMessageController,
                                  minLines: 2,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: 'رسالة إهداء'.tr,
                                    hintText: 'استمتع بوجبتك'.tr,
                                    prefixIcon: const Icon(
                                      Icons.card_giftcard_rounded,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                              TextField(
                                controller: controller.deliveryNoteController,
                                minLines: 2,
                                maxLines: 4,
                                decoration: InputDecoration(
                                  labelText: 'ملاحظات التوصيل'.tr,
                                  hintText:
                                      'مثال: اتصل قبل الوصول أو بدون بصل'.tr,
                                  prefixIcon:
                                      const Icon(Icons.edit_note_rounded),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'ملخص الطلب',
                          child: _OrderSummaryCard(controller: controller),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: GetBuilder<CheckoutController>(
        builder: (controller) {
          final cart = Get.find<CartController>();
          final requiresAddress = controller.deliveryType == '0';
          final canUseSavedAddress = !controller.isOrderingForOther &&
              controller.hasSelectedAddress && controller.hasSelectedAddressCoordinates;
          final canUseRecipientDestination =
              controller.isOrderingForOther &&
              controller.selectedRecipient != null &&
              controller.hasSelectedRecipientCoordinates;
          final canCheckout = !controller.isSubmittingOrder &&
              (!requiresAddress ||
              canUseSavedAddress ||
              canUseRecipientDestination);

          return Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(26),
                topRight: Radius.circular(26),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 16,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('الإجمالي النهائي'.tr, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                          '${controller.checkoutTotal.toStringAsFixed(2)} ${AppCurrency.code}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (cart.discountcoupon > 0)
                          Text(
                            'يشمل خصم كوبون بنسبة'
                                .trParams({'discount': cart.discountcoupon.toStringAsFixed(0)}),
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: canCheckout ? controller.checkout : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(156, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('إتمام الطلب'.tr),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.tr, style: theme.textTheme.titleLarge),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? colors.primary.withValues(alpha: 0.10) : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active
                ? colors.primary
                : theme.dividerColor.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: active ? colors.primary : theme.hintColor),
            const SizedBox(height: 10),
            Text(
              title.tr,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle.tr, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? colors.primary.withValues(alpha: 0.08) : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active
                ? colors.primary
                : theme.dividerColor.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: active
                    ? colors.primary.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.tr,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle.tr, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              active
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderModeSummaryCard extends StatelessWidget {
  const _OrderModeSummaryCard({required this.controller});

  final CheckoutController controller;

  String _formatSlot(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) {
      return raw;
    }
    final locale = Get.locale?.languageCode == 'ar' ? 'ar' : 'en';
    return DateFormat('yyyy/MM/dd h:mm a', locale).format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Get.locale?.languageCode == 'ar';
    final hasSlot =
        (controller.selectedOrderSlotValue ?? '').trim().isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  controller.selectedOrderModeLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            controller.selectedOrderMode == 'asap'
                ? (isArabic
                    ? 'سيتم تنفيذ الطلب في أسرع وقت متاح من المطعم.'
                    : 'The order will be prepared as soon as the restaurant can handle it.')
                : (isArabic
                    ? 'الموعد المختار محفوظ من صفحة المطعم ويمكنك مراجعته هنا.'
                    : 'The selected time is saved from the restaurant page and shown here.'),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
          if (hasSlot) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_rounded, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _formatSlot(controller.selectedOrderSlotValue!),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.title,
    required this.subtitle,
    required this.active,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool active;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? colors.primary.withValues(alpha: 0.08) : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active
                ? colors.primary
                : theme.dividerColor.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.tr, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle.tr, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              active
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: colors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.body,
    required this.buttonLabel,
    required this.icon,
    required this.onPressed,
  });

  final String title;
  final String body;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.primary.withValues(alpha: 0.12),
                child: Icon(icon, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body.tr, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(buttonLabel.tr),
          ),
        ],
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({required this.controller});

  final CheckoutController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipient = controller.selectedRecipient!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  recipient.label.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: controller.openRecipientPicker,
                child: Text('تغيير'.tr),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(recipient.name, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(recipient.phone, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(recipient.shortAddress, style: theme.textTheme.bodyMedium),
          if (recipient.locationNote.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(recipient.locationNote, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.controller});

  final CheckoutController controller;

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    final theme = Theme.of(context);
    final subtotal = cart.getSubtotal();
    final itemsDiscount = cart.getTotalItemsDiscountAmount();
    final couponDiscount = cart.getCouponDiscountAmount();
    final finalTotal = controller.checkoutTotal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'المجموع الفرعي'.tr,
            value: '${subtotal.toStringAsFixed(2)} ${AppCurrency.code}',
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'خصم العناصر'.tr,
            value: '-${itemsDiscount.toStringAsFixed(2)} ${AppCurrency.code}',
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'خصم الكوبون'.tr,
            value: '-${couponDiscount.toStringAsFixed(2)} ${AppCurrency.code}',
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'رسوم التوصيل'.tr,
            value: '${controller.shippingFee.toStringAsFixed(2)} ${AppCurrency.code}',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _SummaryRow(
            label: 'الإجمالي'.tr,
            value: '${finalTotal.toStringAsFixed(2)} ${AppCurrency.code}',
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label.tr, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
