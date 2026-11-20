import 'package:flutter/material.dart';
import 'package:tks/view/widget/common/app_pill_button.dart';

class CustomButtomAuth extends StatelessWidget {
  final String text;
  final void Function()? onPressed;

  const CustomButtomAuth({super.key, required this.text, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AppPillButton(
      label: text,
      onPressed: onPressed,
      expanded: true,
    );
  }
}
