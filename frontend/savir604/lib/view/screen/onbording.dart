import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/onbourding/onbording_controler.dart';
import 'package:tks/data/static/static.dart';
import 'package:tks/view/widget/common/app_pill_button.dart';

class OnBoarding extends StatelessWidget {
  const OnBoarding({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(OnBordingControlerImp());
    final theme = Theme.of(context);
    final pages = buildOnboardingList();

    return Scaffold(
      body: GetBuilder<OnBordingControlerImp>(
        builder: (controller) {
          final isLast = controller.currentPage == pages.length - 1;

          return Container(
            color: theme.scaffoldBackgroundColor,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Text(
                            '${controller.currentPage + 1}/${pages.length}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: controller.skip,
                          child: const Text('Skip'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: controller.pageController,
                      onPageChanged: controller.onPageChanged,
                      itemCount: pages.length,
                      itemBuilder: (context, index) {
                        final item = pages[index];
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                          child: Column(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF141414),
                                    borderRadius: BorderRadius.circular(34),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(22),
                                    child: _OnboardingArt(index: index),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Expanded(
                                flex: 4,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    18,
                                    20,
                                    18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: theme.dividerColor,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.05),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          item.badge ?? 'Step',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        item.title ?? '',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(height: 1.12),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        item.body ?? '',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: item.highlights
                                            .map(
                                              (highlight) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(999),
                                                ),
                                                child: Text(
                                                  highlight,
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: List.generate(
                              pages.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                margin:
                                    const EdgeInsetsDirectional.only(end: 8),
                                width: controller.currentPage == index ? 28 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: controller.currentPage == index
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurface
                                          .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: AppPillDock(
                            leading: AppPillIconButton(
                              icon: controller.currentPage == 0
                                  ? Icons.public_rounded
                                  : Icons.arrow_back_rounded,
                              onTap: controller.currentPage == 0
                                  ? null
                                  : () {
                                      controller.pageController.previousPage(
                                        duration:
                                            const Duration(milliseconds: 280),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                            ),
                            center: AppPillButton(
                              label: isLast ? 'Get started' : 'Next',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: controller.next,
                              expanded: true,
                            ),
                            trailing: AppPillIconButton(
                              icon: Icons.skip_next_rounded,
                              onTap: controller.skip,
                            ),
                          ),
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
    );
  }
}

class _OnboardingArt extends StatelessWidget {
  const _OnboardingArt({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 0:
        return const Stack(
          children: [
            Positioned(
              top: 8,
              right: 10,
              child: _DarkChip(label: 'Anywhere'),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: _DarkChip(label: 'Aleppo'),
            ),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IconPlate(icon: Icons.public_rounded),
                  SizedBox(width: 18),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(width: 18),
                  _IconPlate(icon: Icons.restaurant_rounded),
                ],
              ),
            ),
          ],
        );
      case 1:
        return const Stack(
          children: [
            Positioned(
              top: 12,
              left: 10,
              child: _DarkChip(label: 'Live'),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: _DarkChip(label: 'Driver'),
            ),
            Center(
              child: SizedBox(
                width: 180,
                height: 180,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0x2EFFFFFF), width: 2),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.location_searching_rounded,
                      size: 62,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      default:
        return const Stack(
          children: [
            Positioned(
              top: 8,
              left: 10,
              child: _DarkChip(label: 'Wallet'),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: _DarkChip(label: 'Gift'),
            ),
            Center(
              child: SizedBox(
                width: 190,
                height: 120,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0x14FFFFFF),
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                    border: Border.fromBorderSide(
                      BorderSide(color: Color(0x1FFFFFFF)),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lock_rounded,
                      size: 46,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}

class _DarkChip extends StatelessWidget {
  const _DarkChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _IconPlate extends StatelessWidget {
  const _IconPlate({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Icon(icon, color: Colors.black, size: 40),
    );
  }
}
