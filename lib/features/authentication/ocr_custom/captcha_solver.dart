import 'dart:typed_data';
import 'captcha_result.dart';
import 'vellore_model.dart';
import 'vellore_preprocessor.dart';
import 'constants.dart';
import '../../../core/utils/logger.dart';

class CustomCaptchaSolver {
  static CustomCaptchaSolver? _instance;
  static CustomCaptchaSolver get instance =>
      _instance ??= CustomCaptchaSolver._();

  CustomCaptchaSolver._();

  final VelloreModel _model = VelloreModel();
  bool _isInitialized = false;

  /// Initialize the solver (load model weights)
  Future<void> initialize() async {
    if (_isInitialized) {
      Logger.d('CustomCaptcha', 'Already initialized');
      return;
    }

    try {
      Logger.d('CustomCaptcha', 'Initializing custom captcha solver...');
      final startTime = DateTime.now();

      await _model.loadModel();
      _isInitialized = true;

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      Logger.success(
        'CustomCaptcha',
        'Custom captcha solver initialized in ${duration}ms',
      );
      Logger.success('CustomCaptcha', 'Model info: ${_model.modelInfo}');
    } catch (e, stack) {
      Logger.e('CustomCaptcha', 'Initialization failed', e, stack);
      rethrow;
    }
  }

  /// Solve captcha from image bytes
  Future<CaptchaResult?> solveCaptcha(Uint8List imageBytes) async {
    if (!_isInitialized) {
      Logger.w('CustomCaptcha', 'Not initialized, initializing now...');
      await initialize();
    }

    final startTime = DateTime.now();

    try {
      Logger.d('CustomCaptcha', 'Starting custom captcha recognition');

      // Step 1: Preprocessing
      Logger.d('CustomCaptcha', 'Step 1: Preprocessing image...');
      final preprocessStart = DateTime.now();
      final blocks = VellorePreprocessor.preprocess(imageBytes);
      final preprocessTime =
          DateTime.now().difference(preprocessStart).inMilliseconds;
      Logger.d(
        'CustomCaptcha',
        'Preprocessing complete in ${preprocessTime}ms',
      );

      if (blocks.length != VelloreCaptchaConstants.numCharacters) {
        throw Exception(
          'Expected ${VelloreCaptchaConstants.numCharacters} blocks, got ${blocks.length}',
        );
      }

      // Step 2: Inference
      Logger.d('CustomCaptcha', 'Step 2: Running neural network inference...');
      final inferenceStart = DateTime.now();

      final characters = <String>[];
      final confidences = <double>[];

      for (int i = 0; i < blocks.length; i++) {
        final (char, confidence) = _model.predictCharacter(blocks[i]);
        characters.add(char);
        confidences.add(confidence);

        final confPercent = (confidence * 100).toStringAsFixed(1);
        final emoji =
            confidence >= VelloreCaptchaConstants.highConfidenceThreshold
                ? '✨'
                : confidence >= VelloreCaptchaConstants.confidenceThreshold
                ? '✔️'
                : '⚠️';
        Logger.d(
          'CustomCaptcha',
          '  $emoji Char ${i + 1}: "$char" (conf: $confPercent%)',
        );
      }

      final inferenceTime =
          DateTime.now().difference(inferenceStart).inMilliseconds;
      Logger.d('CustomCaptcha', 'Inference complete in ${inferenceTime}ms');

      // Step 3: Result aggregation
      Logger.d('CustomCaptcha', 'Step 3: Aggregating results...');

      final text = characters.join();

      double avgConfidence = 0.0;
      if (confidences.isNotEmpty) {
        final sum = confidences.reduce((a, b) => a + b);
        if (sum.isFinite && confidences.isNotEmpty) {
          avgConfidence = sum / confidences.length;
        }
      }

      if (!avgConfidence.isFinite || avgConfidence < 0.0) {
        avgConfidence = 0.0;
      } else if (avgConfidence > 1.0) {
        avgConfidence = 1.0;
      }

      final meetsThreshold =
          avgConfidence >= VelloreCaptchaConstants.confidenceThreshold;
      final totalTime = DateTime.now().difference(startTime).inMilliseconds;

      final result = CaptchaResult(
        text: text,
        averageConfidence: avgConfidence,
        characterConfidences: confidences,
        meetsThreshold: meetsThreshold,
        processingTimeMs: totalTime,
      );

      // Step 4: Logging
      if (meetsThreshold) {
        Logger.success('CustomCaptcha', 'HIGH CONFIDENCE PREDICTION');
        Logger.success('CustomCaptcha', '   Text: "$text"');
        Logger.success(
          'CustomCaptcha',
          '   Confidence: ${result.formattedConfidence}',
        );
        Logger.success('CustomCaptcha', '   Time: ${totalTime}ms');
        Logger.success('CustomCaptcha', '   Status: READY FOR AUTO-SUBMIT');
      } else {
        Logger.w('CustomCaptcha', 'LOW CONFIDENCE PREDICTION');
        Logger.w('CustomCaptcha', '   Text: "$text"');
        Logger.w(
          'CustomCaptcha',
          '   Confidence: ${result.formattedConfidence}',
        );
        Logger.w('CustomCaptcha', '   Time: ${totalTime}ms');
        Logger.w(
          'CustomCaptcha',
          '   Status: WILL TRY FALLBACK (manual input)',
        );
      }

      return result;
    } catch (e, stack) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      Logger.e(
        'CustomCaptcha',
        'Captcha recognition failed after ${duration}ms',
        e,
        stack,
      );
      return null;
    }
  }

  bool get isInitialized => _isInitialized;
  Map<String, dynamic> get modelInfo => _model.modelInfo;

  void dispose() {
    _model.dispose();
    _isInitialized = false;
    Logger.d('CustomCaptcha', 'Solver disposed');
  }
}
