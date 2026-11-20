import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Customtextformauth extends StatefulWidget {
  final String hinttext;
  final String labeltext;
  final IconData iconData;
  final TextEditingController? mycontroller;
  final String? Function(String?) valid;
  final bool isNumber;
  final bool? obscureText;
  final void Function()? onTapIcon;

  const Customtextformauth({
    super.key,
    this.obscureText,
    this.onTapIcon,
    required this.hinttext,
    required this.labeltext,
    required this.iconData,
    required this.mycontroller,
    required this.valid,
    required this.isNumber,
  });

  @override
  State<Customtextformauth> createState() => _CustomtextformauthState();
}

class _CustomtextformauthState extends State<Customtextformauth> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        keyboardType: widget.isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        validator: widget.valid,
        controller: widget.mycontroller,
        obscureText: widget.obscureText ?? false,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelText: widget.labeltext.tr,
          hintText: widget.hinttext.tr,
          prefixIcon: Icon(widget.iconData),
        ),
      ),
    );
  }
}
