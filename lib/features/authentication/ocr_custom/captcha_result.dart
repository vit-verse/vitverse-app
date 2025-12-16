/// Result of custom captcha recognition with confidence scores
class CaptchaResult {
  final String text;
  final double averageConfidence;
  final List<double> characterConfidences;
  final bool meetsThreshold;
  final int processingTimeMs;
  final DateTime timestamp;

  CaptchaResult({
    required this.text,
    required this.averageConfidence,
    required this.characterConfidences,
    required this.meetsThreshold,
    required this.processingTimeMs,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now() {
    assert(text.length == 6, 'Captcha text must be exactly 6 characters');
    assert(
      characterConfidences.length == 6,
      'Must have confidence for each character',
    );
    assert(
      averageConfidence.isFinite &&
          averageConfidence >= 0.0 &&
          averageConfidence <= 1.0,
      'Confidence must be finite and between 0 and 1',
    );
  }

  double get confidencePercentage =>
      averageConfidence.isFinite ? (averageConfidence * 100) : 0.0;

  double get minConfidence {
    if (characterConfidences.isEmpty) return 0.0;
    final min = characterConfidences.reduce((a, b) => a < b ? a : b);
    return min.isFinite ? min : 0.0;
  }

  double get maxConfidence {
    if (characterConfidences.isEmpty) return 0.0;
    final max = characterConfidences.reduce((a, b) => a > b ? a : b);
    return max.isFinite ? max : 0.0;
  }

  bool get isHighConfidence => averageConfidence >= 0.90;

  String get formattedConfidence {
    if (!averageConfidence.isFinite) return '0.0%';
    return '${(averageConfidence * 100).toStringAsFixed(1)}%';
  }

  String get characterBreakdown {
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final conf =
          characterConfidences[i].isFinite ? characterConfidences[i] : 0.0;
      buffer.write('${text[i]}:${(conf * 100).toStringAsFixed(1)}%');
      if (i < text.length - 1) buffer.write(', ');
    }
    return buffer.toString();
  }

  @override
  String toString() {
    return 'CaptchaResult(text: "$text", confidence: $formattedConfidence, threshold: $meetsThreshold, time: ${processingTimeMs}ms)';
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'averageConfidence': averageConfidence,
      'characterConfidences': characterConfidences,
      'meetsThreshold': meetsThreshold,
      'processingTimeMs': processingTimeMs,
      'timestamp': timestamp.toIso8601String(),
      'characterBreakdown': characterBreakdown,
    };
  }

  factory CaptchaResult.fromJson(Map<String, dynamic> json) {
    return CaptchaResult(
      text: json['text'] as String,
      averageConfidence: (json['averageConfidence'] as num).toDouble(),
      characterConfidences:
          (json['characterConfidences'] as List)
              .map((e) => (e as num).toDouble())
              .toList(),
      meetsThreshold: json['meetsThreshold'] as bool,
      processingTimeMs: json['processingTimeMs'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
