import 'package:flutter/cupertino.dart';
import 'dart:ui';

class BlurEffectView extends StatelessWidget {
  final Widget child;
  final double blurAmount;

  const BlurEffectView({Key? key, required this.child, this.blurAmount = 10})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          color: CupertinoColors.lightBackgroundGray.withOpacity(0.25),
          child: child,
        ),
      ),
    );
  }
}
