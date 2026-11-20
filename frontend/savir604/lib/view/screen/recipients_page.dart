import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/controler/recipients/recipients_controller.dart';
import 'package:tks/data/datasource/model/recipient_model.dart';
import 'package:tks/view/widget/common/app_top_banner.dart';

class RecipientsPage extends StatelessWidget {
  const RecipientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(RecipientsController());
    final theme = Theme.of(context);
    final isArabic = (Get.locale?.languageCode ?? 'ar') == 'ar';
    String t(String arabic, String english) => isArabic ? arabic : english;
    final fromCheckout =
        Get.arguments is Map && (Get.arguments as Map)['select_mode'] == true;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.10),
                theme.scaffoldBackgroundColor,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: GetBuilder<RecipientsController>(
              builder: (controller) {
                return Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                      children: [
                        AppTopBanner(
                          title: t('المستلمون', 'Recipients'),
                          subtitle: t(
                            'احفظ بيانات المستلم مرة واحدة واستخدمها عند إرسال طلب هدية.',
                            'Save recipient details once and reuse them whenever you place a gift order.',
                          ),
                          leadingIcon: Icons.arrow_back_rounded,
                          onLeadingTap: Get.back,
                          trailingIcon: Icons.people_alt_outlined,
                          onTrailingTap: () {},
                          child: AppTopBannerMetric(
                            value: controller.recipients.length.toString(),
                            label: t('جهات محفوظة', 'Saved contacts'),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (!controller.hasRecipients)
                          _RecipientsEmptyState(
                            onAdd: () => controller.openRecipientEditor(
                              popWithSelection: false,
                            ),
                          )
                        else
                          ...controller.recipients.map(
                            (recipient) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _RecipientCard(
                                recipient: recipient,
                                showSelectAction: fromCheckout,
                                onSelect: () => Get.back(
                                  result: recipient.toJson(),
                                ),
                                onEdit: () => controller.openRecipientEditor(
                                  initialRecipient: recipient,
                                ),
                                onDelete: () =>
                                    controller.deleteRecipient(recipient.id),
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
                          onPressed: () => controller.openRecipientEditor(
                            popWithSelection: false,
                          ),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: Text(t('إضافة مستلم', 'Add recipient')),
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
      ),
    );
  }
}

class _RecipientsEmptyState extends StatelessWidget {
  const _RecipientsEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isArabic = (Get.locale?.languageCode ?? 'ar') == 'ar';
    String t(String arabic, String english) => isArabic ? arabic : english;

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
            child: Icon(
              Icons.people_outline_rounded,
              color: colors.primary,
              size: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(t('لا يوجد مستلمون محفوظون بعد', 'No saved recipients yet'),
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            t(
              'أضف أول مستلم حتى يصبح إرسال الطلبات للعائلة والأصدقاء أسرع.',
              'Add your first recipient so family and friends are ready to receive orders in one tap.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(t('إنشاء مستلم', 'Create recipient')),
          ),
        ],
      ),
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({
    required this.recipient,
    required this.showSelectAction,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final RecipientModel recipient;
  final bool showSelectAction;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isArabic = (Get.locale?.languageCode ?? 'ar') == 'ar';
    String t(String arabic, String english) => isArabic ? arabic : english;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
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
                child:
                    Icon(Icons.person_outline_rounded, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipient.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(recipient.name, style: theme.textTheme.bodyMedium),
                  ],
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
          _RecipientInfo(icon: Icons.phone_outlined, text: recipient.phone),
          const SizedBox(height: 8),
          _RecipientInfo(
            icon: Icons.place_outlined,
            text: recipient.shortAddress,
          ),
          if (recipient.locationNote.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _RecipientInfo(
              icon: Icons.edit_location_alt_outlined,
              text: recipient.locationNote,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(t('تعديل', 'Edit')),
              ),
              const SizedBox(width: 10),
              if (showSelectAction)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSelect,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: Text(t('استخدام المستلم', 'Use recipient')),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecipientInfo extends StatelessWidget {
  const _RecipientInfo({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

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
