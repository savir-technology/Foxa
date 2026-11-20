import 'package:flutter/material.dart';

class CustomAppBaritems extends StatelessWidget {
  final String titleappbar;
  final void Function()? onPressedIcon;
  final void Function()? onPressedSearch;

  const CustomAppBaritems({
    super.key,
    required this.titleappbar,
    this.onPressedIcon,
    this.onPressedSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: theme.dividerColor.withValues(alpha: 0.85),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: TextField(
                onSubmitted: (_) => onPressedSearch?.call(),
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Icon(
                      Icons.search_rounded,
                      color: colors.primary,
                    ),
                  ),
                  hintText: titleappbar,
                  hintStyle: theme.textTheme.bodyMedium,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: IconButton(
              onPressed: onPressedIcon,
              icon: const Icon(
                Icons.notifications_active_outlined,
                size: 30,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
