/// Constants for Vellore captcha model configuration
class VelloreCaptchaConstants {
  VelloreCaptchaConstants._();

  // Image dimensions
  static const int imageWidth = 200;
  static const int imageHeight = 40;

  // Character set (32 characters, excludes I, O, 0, 1)
  static const String characterSet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  static const int numClasses = 32;
  static const int numCharacters = 6;

  // Confidence thresholds
  static const double confidenceThreshold = 0.70;
  static const double highConfidenceThreshold = 0.90;

  // Block extraction coordinates
  static List<BlockCoordinates> getBlockCoordinates() {
    return List.generate(numCharacters, (a) {
      final x1 = (a + 1) * 25 + 2;
      final y1 = 7 + 5 * (a % 2) + 1;
      final x2 = (a + 2) * 25 + 1;
      final y2 = 35 - 5 * ((a + 1) % 2);
      return BlockCoordinates(x1: x1, y1: y1, x2: x2, y2: y2, index: a);
    });
  }

  // Model file path
  static const String weightsAssetPath = 'assets/ml/vellore_weights.json';

  // Performance targets
  static const int maxProcessingTimeMs = 500;
  static const double targetAccuracy = 0.90;
}

class BlockCoordinates {
  final int x1;
  final int y1;
  final int x2;
  final int y2;
  final int index;

  const BlockCoordinates({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.index,
  });

  int get width => x2 - x1;
  int get height => y2 - y1;

  @override
  String toString() =>
      'Block[$index]: x=($x1-$x2), y=($y1-$y2), size=${width}x$height';
}

//  Thanks to Pratyush ([VtopCaptchaSolver3.0](https://github.com/pratyush3124/VtopCaptchaSolver3.0)) for providing a high-accuracy (>95%) custom-trained VTOP captcha model.
//  ChennaiWeights are corrupted I thinkkk, giving incorrect predictions
//  So, I'm using Vellore Weights (assets\ml\vellore_weights.json)
