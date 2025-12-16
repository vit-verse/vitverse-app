import 'dart:math';

/// Utility for generating random avatar IDs
class AvatarUtils {
  static List<String> generateRandomIds(int count) {
    final random = Random.secure();
    return List.generate(count, (_) {
      return List.generate(12, (_) => random.nextInt(10)).join();
    });
  }
}
