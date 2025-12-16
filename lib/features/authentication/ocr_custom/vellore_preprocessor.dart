import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'constants.dart';
import '../../../core/utils/logger.dart';

class VellorePreprocessor {
  VellorePreprocessor._();

  /// Full preprocessing pipeline: Image → 6 preprocessed blocks
  static List<List<double>> preprocess(Uint8List imageBytes) {
    try {
      Logger.d('VellorePrep', 'Starting preprocessing pipeline');
      final startTime = DateTime.now();

      // Step 1: Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image');
      }
      Logger.d('VellorePrep', 'Decoded image: ${image.width}x${image.height}');

      // Step 2: Resize to 200x40
      final resized = img.copyResize(
        image,
        width: VelloreCaptchaConstants.imageWidth,
        height: VelloreCaptchaConstants.imageHeight,
        interpolation: img.Interpolation.linear,
      );
      Logger.d('VellorePrep', 'Resized to: ${resized.width}x${resized.height}');

      // Step 3: Extract saturation channel
      final saturation = extractSaturation(resized);
      Logger.d(
        'VellorePrep',
        'Extracted saturation: ${saturation.length} values',
      );

      // Step 4: Reshape to 2D matrix
      final satImage = reshape(
        saturation,
        VelloreCaptchaConstants.imageHeight,
        VelloreCaptchaConstants.imageWidth,
      );
      Logger.d(
        'VellorePrep',
        'Reshaped to: ${satImage.length}x${satImage[0].length}',
      );

      // Step 5: Extract blocks
      final blocks = extractBlocks(satImage);
      Logger.d('VellorePrep', 'Extracted ${blocks.length} blocks');

      // Step 6: Preprocess each block (binarize + flatten)
      final processedBlocks = <List<double>>[];
      for (int i = 0; i < blocks.length; i++) {
        final processed = preprocessBlock(blocks[i]);
        processedBlocks.add(processed);
        Logger.d('VellorePrep', 'Block $i: ${processed.length} features');
      }

      final duration = DateTime.now().difference(startTime).inMilliseconds;
      Logger.success('VellorePrep', 'Preprocessing complete in ${duration}ms');

      return processedBlocks;
    } catch (e, stack) {
      Logger.e('VellorePrep', 'Preprocessing failed', e, stack);
      rethrow;
    }
  }

  /// Extract saturation channel from RGB image
  static List<double> extractSaturation(img.Image image) {
    final saturation = <double>[];

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);

        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        final min = math.min(math.min(r, g), b);
        final max = math.max(math.max(r, g), b);

        double sat = 0.0;
        if (max > 0) {
          sat = ((max - min) * 255) / max;
        }

        saturation.add(sat.roundToDouble());
      }
    }

    return saturation;
  }

  /// Reshape 1D array to 2D matrix
  static List<List<double>> reshape(List<double> data, int height, int width) {
    if (data.length != height * width) {
      throw ArgumentError(
        'Data length ${data.length} does not match ${height}x$width',
      );
    }

    final result = <List<double>>[];
    for (int y = 0; y < height; y++) {
      final row = <double>[];
      for (int x = 0; x < width; x++) {
        row.add(data[y * width + x]);
      }
      result.add(row);
    }

    return result;
  }

  /// Extract 6 character blocks from saturation image
  static List<List<List<double>>> extractBlocks(List<List<double>> satImage) {
    final blocks = <List<List<double>>>[];
    final coords = VelloreCaptchaConstants.getBlockCoordinates();

    for (final coord in coords) {
      final block = <List<double>>[];

      for (int y = coord.y1; y < coord.y2; y++) {
        final row = <double>[];
        for (int x = coord.x1; x < coord.x2; x++) {
          row.add(satImage[y][x]);
        }
        block.add(row);
      }

      blocks.add(block);
      Logger.d('VellorePrep', 'Extracted ${coord.toString()}');
    }

    return blocks;
  }

  /// Preprocess single block: binarize based on average + flatten
  static List<double> preprocessBlock(List<List<double>> block) {
    // Step 1: Calculate average
    double sum = 0.0;
    int count = 0;
    for (final row in block) {
      for (final val in row) {
        sum += val;
        count++;
      }
    }
    final avg = sum / count;

    // Step 2: Binarize and flatten
    final result = <double>[];
    for (final row in block) {
      for (final val in row) {
        result.add(val > avg ? 1.0 : 0.0);
      }
    }

    return result;
  }

  /// Get statistics about saturation values (for debugging)
  static Map<String, double> getSaturationStats(List<double> saturation) {
    if (saturation.isEmpty) return {};

    final sorted = List<double>.from(saturation)..sort();
    return {
      'min': sorted.first,
      'max': sorted.last,
      'mean': saturation.reduce((a, b) => a + b) / saturation.length,
      'median': sorted[sorted.length ~/ 2],
    };
  }
}
