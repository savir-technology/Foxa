import 'package:tks/core/constant/color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Customtextbodyauth extends StatelessWidget {
  final String text;
  const Customtextbodyauth({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.symmetric(horizontal: 25),
        child: Text(
          text.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: "myfont", color: ColorApp.gray),
        ));
  }
}
