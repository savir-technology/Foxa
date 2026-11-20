import 'package:flutter/material.dart';

class CustomButtonAppBar extends StatelessWidget {
  final void Function()? onPressed;
  final String textbutton;
  final IconData icondata;
  final bool? active;
  const CustomButtonAppBar(
      {super.key,
      required this.textbutton,
      required this.icondata,
      required this.onPressed,
      required this.active});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return MaterialButton(
      onPressed: onPressed,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          icondata,
          color: active == true ? colors.primary : colors.onSurface.withValues(alpha: 0.65),
        ),
        // Text(textbutton,
        //     style: TextStyle(
        //         color: active == true ? ColorApp.praimaryColor : Colors.black))
      ]),
    );
  }
}
