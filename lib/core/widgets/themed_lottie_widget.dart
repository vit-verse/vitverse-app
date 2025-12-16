import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:dotlottie_loader/dotlottie_loader.dart';

class ThemedLottieWidget extends StatelessWidget {
  final String assetPath;
  final double width;
  final double height;
  final BoxFit fit;
  final bool repeat;
  final bool animate;

  final IconData? fallbackIcon;
  final String? fallbackText;
  final bool? showContainer;

  const ThemedLottieWidget({
    super.key,
    required this.assetPath,
    this.width = 200,
    this.height = 200,
    this.fit = BoxFit.contain,
    this.repeat = true,
    this.animate = true,

    this.fallbackIcon,
    this.fallbackText,
    this.showContainer,
  });

  @override
  Widget build(BuildContext context) {
    // If not a LottieBundle .lottie → normal Lottie
    if (!assetPath.toLowerCase().endsWith(".lottie")) {
      return Lottie.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        repeat: repeat,
        animate: animate,
      );
    }

    // .lottie → correct loader for dotlottie_loader >= 0.0.5
    return DotLottieLoader.fromAsset(
      assetPath,
      frameBuilder: (context, dot) {
        if (dot == null || dot.animations.isEmpty) {
          return SizedBox(width: width, height: height);
        }

        final raw = dot.animations.values.first;

        return Lottie.memory(
          raw,
          width: width,
          height: height,
          fit: fit,
          repeat: repeat,
          animate: animate,
        );
      },
    );
  }
}
