import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tks/controler/offers/offers_controller.dart';
import 'package:tks/core/class/StatusRequest.dart';
import 'package:tks/data/datasource/model/aleppo_home_model.dart';
import 'package:tks/data/datasource/model/couponmodel.dart';

class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OffersController>(
      init: OffersController(),
      builder: (controller) {
        final isArabic = controller.isArabic;
        return Directionality(
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xfff7f8f5),
            body: SafeArea(
              bottom: false,
              child: RefreshIndicator(
                color: const Color(0xff2f6b3b),
                onRefresh: () => controller.fetchOffers(refresh: true),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(child: _OffersHeader(controller: controller)),
                    if (controller.statusRequest == StatusRequest.loading &&
                        !controller.hasContent)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 40),
                        sliver: SliverList.list(
                          children: [
                            _CouponInput(controller: controller),
                            if (controller.appliedCoupon != null) ...[
                              const SizedBox(height: 12),
                              _AppliedCoupon(controller: controller),
                            ],
                            const SizedBox(height: 28),
                            _SectionHeading(
                              title: isArabic ? 'الكوبونات المتاحة' : 'Available coupons',
                              subtitle: isArabic
                                  ? 'انسخ الكود واستخدمه قبل تأكيد الطلب'
                                  : 'Copy a code and use it before checkout',
                              count: controller.coupons.length,
                            ),
                            const SizedBox(height: 14),
                            if (controller.coupons.isEmpty)
                              _EmptyOffers(
                                icon: Icons.confirmation_number_outlined,
                                text: isArabic
                                    ? 'لا توجد كوبونات متاحة حاليًا'
                                    : 'No active coupons right now',
                              )
                            else
                              ...controller.coupons.asMap().entries.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _CouponCard(
                                    coupon: entry.value,
                                    index: entry.key,
                                    controller: controller,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            _SectionHeading(
                              title: isArabic ? 'العروض الخاصة' : 'Special offers',
                              subtitle: isArabic
                                  ? 'عروض منشورة من لوحة الإدارة'
                                  : 'Offers published from the admin panel',
                              count: controller.specialOffers.length,
                            ),
                            const SizedBox(height: 14),
                            if (controller.specialOffers.isEmpty)
                              _EmptyOffers(
                                icon: Icons.local_offer_outlined,
                                text: isArabic
                                    ? 'لا توجد عروض خاصة حاليًا'
                                    : 'No special offers right now',
                              )
                            else
                              ...controller.specialOffers.asMap().entries.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _SpecialOfferCard(
                                    banner: entry.value,
                                    index: entry.key,
                                    controller: controller,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OffersHeader extends StatelessWidget {
  const _OffersHeader({required this.controller});
  final OffersController controller;

  @override
  Widget build(BuildContext context) {
    final isArabic = controller.isArabic;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xff183b25),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: Get.back,
                color: Colors.white,
                icon: Icon(isArabic ? Icons.arrow_forward : Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  isArabic ? 'العروض والخصومات' : 'Offers & discounts',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                onPressed: () => controller.fetchOffers(refresh: true),
                color: Colors.white,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isArabic ? 'وفر أكتر في طلبك الجاي' : 'Save more on your next order',
            style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle, required this.count});
  final String title;
  final String subtitle;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xff1d2b21))),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
        CircleAvatar(
          radius: 17,
          backgroundColor: const Color(0xffe2efe4),
          child: Text('$count', style: const TextStyle(color: Color(0xff2f6b3b), fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

class _CouponInput extends StatelessWidget {
  const _CouponInput({required this.controller});
  final OffersController controller;

  @override
  Widget build(BuildContext context) {
    final isArabic = controller.isArabic;
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xffe2e7e2))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller.couponController,
              textDirection: ui.TextDirection.ltr,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.confirmation_number_outlined, color: Color(0xff2f6b3b)),
                hintText: isArabic ? 'اكتب كود الخصم' : 'Enter coupon code',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => controller.applyCoupon(),
            ),
          ),
          FilledButton(
            onPressed: controller.isApplyingCoupon ? null : controller.applyCoupon,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xff2f6b3b), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13)),
            child: controller.isApplyingCoupon
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(isArabic ? 'تطبيق' : 'Apply'),
          ),
        ],
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.coupon, required this.index, required this.controller});
  final CouponModel coupon;
  final int index;
  final OffersController controller;

  @override
  Widget build(BuildContext context) {
    final isArabic = controller.isArabic;
    final accent = index.isEven ? const Color(0xff2f6b3b) : const Color(0xffbb6b2d);
    return InkWell(
      onTap: () {
        controller.couponController.text = coupon.codeLabel;
        Clipboard.setData(ClipboardData(text: coupon.codeLabel));
        Get.snackbar(isArabic ? 'تم نسخ الكود' : 'Code copied', coupon.codeLabel, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xffe2e7e2))),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(16)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(coupon.discountLabel, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                Text(isArabic ? 'خصم' : 'OFF', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(coupon.codeLabel, style: TextStyle(color: accent, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1)),
                const SizedBox(height: 5),
                Text(isArabic ? 'اضغط لنسخ الكود واستخدامه عند الدفع' : 'Tap to copy and use at checkout', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                if (coupon.expireDate != null) ...[
                  const SizedBox(height: 7),
                  Text('${isArabic ? 'ساري حتى' : 'Valid until'} ${_date(coupon.expireDate!)}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                ],
              ]),
            ),
            Icon(Icons.copy_rounded, color: accent, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SpecialOfferCard extends StatelessWidget {
  const _SpecialOfferCard({required this.banner, required this.index, required this.controller});
  final AleppoHomeBannerModel banner;
  final int index;
  final OffersController controller;

  @override
  Widget build(BuildContext context) {
    final isArabic = controller.isArabic;
    final title = isArabic ? banner.titleAr : banner.titleEn;
    final subtitle = isArabic ? banner.subtitleAr : banner.subtitleEn;
    return InkWell(
      onTap: () => controller.openBanner(banner),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 148,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _color(index),
          borderRadius: BorderRadius.circular(20),
          image: banner.imageUrl.trim().isEmpty ? null : DecorationImage(image: NetworkImage(banner.imageUrl), fit: BoxFit.cover, colorFilter: const ColorFilter.mode(Colors.black38, BlendMode.darken)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
          Text(title.isEmpty ? (isArabic ? 'عرض خاص' : 'Special offer') : title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _AppliedCoupon extends StatelessWidget {
  const _AppliedCoupon({required this.controller});
  final OffersController controller;

  @override
  Widget build(BuildContext context) {
    final coupon = controller.appliedCoupon!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(color: const Color(0xffe2efe4), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Icon(Icons.check_circle, color: Color(0xff2f6b3b)),
        const SizedBox(width: 8),
        Expanded(child: Text('${controller.isArabic ? 'تم تفعيل' : 'Active'} ${coupon.codeLabel} (${coupon.discountLabel})', style: const TextStyle(color: Color(0xff2f6b3b), fontWeight: FontWeight.w700))),
        IconButton(onPressed: controller.clearAppliedCoupon, icon: const Icon(Icons.close, size: 18)),
      ]),
    );
  }
}

class _EmptyOffers extends StatelessWidget {
  const _EmptyOffers({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xffe2e7e2))),
      child: Column(children: [Icon(icon, size: 35, color: Colors.grey.shade400), const SizedBox(height: 8), Text(text, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600))]),
    );
  }
}

String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';

Color _color(int index) {
  const colors = [Color(0xff2f6b3b), Color(0xff8f5c27), Color(0xff365d78), Color(0xff70466f)];
  return colors[index % colors.length];
}
