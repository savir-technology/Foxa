import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tks/core/constant/color.dart';

class CustomButtonCart extends StatelessWidget {
  final String textbutton;
  final void Function()? onPressed;
  const CustomButtonCart({super.key, required this.textbutton, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      child: MaterialButton(
        color: ColorApp.praimaryColor,
        textColor: const Color.fromARGB(255, 255, 255, 255),
        onPressed: onPressed,
        child: Text(textbutton.tr,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
