import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'constants.dart';
import '../../../core/utils/logger.dart';

class VelloreModel {
  List<double>? _biases;
  List<List<double>>? _weights;
  bool _isLoaded = false;

  /// Load model weights from assets
  Future<void> loadModel() async {
    if (_isLoaded) {
      Logger.d('VelloreModel', 'Model already loaded, skipping');
      return;
    }

    try {
      Logger.d('VelloreModel', 'Loading weights from assets...');
      final startTime = DateTime.now();

      final jsonString = await rootBundle.loadString(
        VelloreCaptchaConstants.weightsAssetPath,
      );
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      _biases =
          (data['biases'] as List).map((e) => (e as num).toDouble()).toList();
      _weights =
          (data['weights'] as List)
              .map(
                (row) =>
                    (row as List).map((e) => (e as num).toDouble()).toList(),
              )
              .toList();

      if (_biases!.length != VelloreCaptchaConstants.numClasses) {
        throw Exception(
          'Invalid biases length: ${_biases!.length}, expected ${VelloreCaptchaConstants.numClasses}',
        );
      }

      final inputSize = _weights!.length;
      final outputSize = _weights![0].length;

      if (outputSize != VelloreCaptchaConstants.numClasses) {
        throw Exception(
          'Invalid weights output size: $outputSize, expected ${VelloreCaptchaConstants.numClasses}',
        );
      }

      _isLoaded = true;

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      Logger.success(
        'VelloreModel',
        'Model loaded successfully in ${duration}ms (input: $inputSize, output: $outputSize)',
      );
    } catch (e, stack) {
      Logger.e('VelloreModel', 'Failed to load model', e, stack);
      rethrow;
    }
  }

  /// Predict single character from preprocessed block
  (String, double) predictCharacter(List<double> blockInput) {
    if (!_isLoaded) {
      throw StateError('Model not loaded. Call loadModel() first.');
    }

    try {
      final logits = _computeLogits(blockInput);
      final probs = _softmax(logits);

      int maxIdx = 0;
      double maxProb = probs[0];
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > maxProb) {
          maxProb = probs[i];
          maxIdx = i;
        }
      }

      final char = VelloreCaptchaConstants.characterSet[maxIdx];
      return (char, maxProb);
    } catch (e, stack) {
      Logger.e('VelloreModel', 'Prediction failed', e, stack);
      rethrow;
    }
  }

  /// Compute logits: input · weights + biases
  List<double> _computeLogits(List<double> input) {
    final inputLen = input.length;
    final outputLen = VelloreCaptchaConstants.numClasses;

    if (inputLen != _weights!.length) {
      throw ArgumentError(
        'Input length $inputLen does not match weights input size ${_weights!.length}',
      );
    }

    final logits = List<double>.filled(outputLen, 0.0);

    for (int i = 0; i < outputLen; i++) {
      double sum = 0.0;
      for (int j = 0; j < inputLen; j++) {
        sum += input[j] * _weights![j][i];
      }
      logits[i] = sum + _biases![i];
    }

    return logits;
  }

  /// Softmax activation function
  List<double> _softmax(List<double> logits) {
    final maxLogit = logits.reduce(math.max);
    final exp = logits.map((x) => math.exp(x - maxLogit)).toList();
    final sumExp = exp.reduce((a, b) => a + b);
    return exp.map((x) => x / sumExp).toList();
  }

  bool get isLoaded => _isLoaded;
  int? get inputSize => _weights?.length;
  int? get outputSize => _biases?.length;

  Map<String, dynamic> get modelInfo {
    if (!_isLoaded) return {'loaded': false};

    return {
      'loaded': true,
      'inputSize': inputSize,
      'outputSize': outputSize,
      'characterSet': VelloreCaptchaConstants.characterSet,
      'threshold': VelloreCaptchaConstants.confidenceThreshold,
    };
  }

  void dispose() {
    _biases = null;
    _weights = null;
    _isLoaded = false;
    Logger.d('VelloreModel', 'Model disposed');
  }
}
