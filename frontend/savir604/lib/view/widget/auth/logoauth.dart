import 'package:flutter/material.dart';
import 'package:tks/core/constant/imsgesassets.dart';

class Logoauth extends StatelessWidget {
  const Logoauth({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppImageAsset.aleppoLogo,
      fit: BoxFit.contain,
    );
  }
}
