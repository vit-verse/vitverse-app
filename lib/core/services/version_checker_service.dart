import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/utils/logger.dart';

/// Service to check for app updates from GitHub repository
class VersionCheckerService {
  static const String _tag = 'VersionChecker';

  // GitHub raw URL for pubspec.yaml
  static const String _pubspecUrl =
      'https://raw.githubusercontent.com/vit-verse/vitverse-app/main/pubspec.yaml';

  /// Check if a new version is available
  /// Returns a map with status and version info
  static Future<VersionCheckResult> checkForUpdate() async {
    try {
      Logger.d(_tag, 'Checking for updates from GitHub...');

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final currentBuildNumber = packageInfo.buildNumber;

      Logger.d(_tag, 'Current version: $currentVersion+$currentBuildNumber');

      // Fetch latest pubspec.yaml from GitHub
      final response = await http
          .get(Uri.parse(_pubspecUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        Logger.w(_tag, 'Failed to fetch pubspec.yaml: ${response.statusCode}');
        return VersionCheckResult(
          status: UpdateStatus.error,
          currentVersion: currentVersion,
          message: 'Unable to check for updates',
        );
      }

      // Parse the pubspec.yaml content
      final pubspecContent = response.body;
      final latestVersion = _extractVersionFromPubspec(pubspecContent);

      if (latestVersion == null) {
        Logger.w(_tag, 'Could not extract version from pubspec.yaml');
        return VersionCheckResult(
          status: UpdateStatus.error,
          currentVersion: currentVersion,
          message: 'Unable to check for updates',
        );
      }

      Logger.d(_tag, 'Latest version: $latestVersion');

      // Compare versions
      final comparison = _compareVersions(currentVersion, latestVersion);

      if (comparison < 0) {
        // Current version is older
        Logger.i(_tag, 'Update available: $currentVersion -> $latestVersion');
        return VersionCheckResult(
          status: UpdateStatus.updateAvailable,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          message: 'Update available',
        );
      } else {
        // Already up to date or ahead
        Logger.i(_tag, 'App is up to date');
        return VersionCheckResult(
          status: UpdateStatus.upToDate,
          currentVersion: currentVersion,
          latestVersion: latestVersion,
          message: 'Already updated',
        );
      }
    } catch (e, stack) {
      Logger.e(_tag, 'Error checking for updates', e, stack);
      return VersionCheckResult(
        status: UpdateStatus.error,
        currentVersion: 'Unknown',
        message: 'Unable to check for updates',
      );
    }
  }

  /// Extract version string from pubspec.yaml content
  static String? _extractVersionFromPubspec(String content) {
    try {
      // Look for "version: x.x.x+x" pattern
      final versionRegex = RegExp(r'version:\s*(\d+\.\d+\.\d+(?:\+\d+)?)');
      final match = versionRegex.firstMatch(content);

      if (match != null && match.groupCount >= 1) {
        final fullVersion = match.group(1)!;
        // Return only the version part without build number
        return fullVersion.split('+').first;
      }

      return null;
    } catch (e) {
      Logger.e(_tag, 'Error extracting version from pubspec', e);
      return null;
    }
  }

  /// Compare two semantic version strings (e.g., "1.1.0" vs "1.2.0")
  /// Returns:
  ///   -1 if v1 < v2
  ///    0 if v1 == v2
  ///    1 if v1 > v2
  static int _compareVersions(String v1, String v2) {
    try {
      final v1Parts = v1.split('.').map(int.parse).toList();
      final v2Parts = v2.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final part1 = i < v1Parts.length ? v1Parts[i] : 0;
        final part2 = i < v2Parts.length ? v2Parts[i] : 0;

        if (part1 < part2) return -1;
        if (part1 > part2) return 1;
      }

      return 0; // Equal
    } catch (e) {
      Logger.e(_tag, 'Error comparing versions', e);
      return 0; // Assume equal on error
    }
  }
}

/// Update status enum
enum UpdateStatus { upToDate, updateAvailable, error }

/// Result of version check
class VersionCheckResult {
  final UpdateStatus status;
  final String currentVersion;
  final String? latestVersion;
  final String message;

  const VersionCheckResult({
    required this.status,
    required this.currentVersion,
    this.latestVersion,
    required this.message,
  });

  bool get isUpdateAvailable => status == UpdateStatus.updateAvailable;
  bool get isUpToDate => status == UpdateStatus.upToDate;
  bool get hasError => status == UpdateStatus.error;
}
