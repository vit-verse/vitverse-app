import 'package:http/http.dart' as http;
import '../config/app_version.dart';
import '../utils/logger.dart';

class VersionCheckerService {
  static const String _tag = 'VersionChecker';

  static const String _pubspecUrl =
      'https://raw.githubusercontent.com/vit-verse/vitverse-app/working/pubspec.yaml';

  static String get _currentVersion => AppVersion.version;

  static Future<KillSwitchResult> checkKillSwitch() async {
    try {
      Logger.d(_tag, 'Kill switch check — current: $_currentVersion');

      final pubspecContent = await _fetchPubspec();
      if (pubspecContent == null) {
        Logger.w(
          _tag,
          'Kill switch: could not fetch pubspec — allowing through',
        );
        return KillSwitchResult.passThrough(_currentVersion);
      }

      final minVersion = _extractField(pubspecContent, 'min_version');
      if (minVersion == null) {
        Logger.d(_tag, 'Kill switch: min_version not set — allowing through');
        return KillSwitchResult.passThrough(_currentVersion);
      }

      Logger.d(_tag, 'Kill switch: min=$minVersion current=$_currentVersion');

      final isBlocked = _compareVersions(_currentVersion, minVersion) < 0;
      if (isBlocked) {
        Logger.w(_tag, 'Kill switch TRIGGERED: $_currentVersion < $minVersion');
        return KillSwitchResult.blocked(_currentVersion, minVersion);
      }

      return KillSwitchResult.passThrough(_currentVersion);
    } catch (e) {
      Logger.e(_tag, 'Kill switch check failed — allowing through', e);
      return KillSwitchResult.passThrough(_currentVersion);
    }
  }

  static Future<VersionCheckResult> checkForUpdate() async {
    try {
      Logger.d(_tag, 'Checking for updates from GitHub...');

      final currentVersion = _currentVersion;
      Logger.d(_tag, 'Current version: ${AppVersion.fullVersion}');

      final pubspecContent = await _fetchPubspec();
      if (pubspecContent == null) {
        return VersionCheckResult(
          status: UpdateStatus.error,
          currentVersion: currentVersion,
          message: 'Unable to check for updates',
        );
      }

      final latestVersion = _extractField(pubspecContent, 'version');
      if (latestVersion == null) {
        Logger.w(_tag, 'Could not extract version from pubspec.yaml');
        return VersionCheckResult(
          status: UpdateStatus.error,
          currentVersion: currentVersion,
          message: 'Unable to check for updates',
        );
      }

      final latestClean = latestVersion.split('+').first;
      Logger.d(_tag, 'Latest version: $latestClean');

      final comparison = _compareVersions(currentVersion, latestClean);
      if (comparison < 0) {
        Logger.i(_tag, 'Update available: $currentVersion -> $latestClean');
        return VersionCheckResult(
          status: UpdateStatus.updateAvailable,
          currentVersion: currentVersion,
          latestVersion: latestClean,
          message: 'Update available',
        );
      }

      Logger.i(_tag, 'App is up to date');
      return VersionCheckResult(
        status: UpdateStatus.upToDate,
        currentVersion: currentVersion,
        latestVersion: latestClean,
        message: 'Already updated',
      );
    } catch (e, stack) {
      Logger.e(_tag, 'Error checking for updates', e, stack);
      return VersionCheckResult(
        status: UpdateStatus.error,
        currentVersion: _currentVersion,
        message: 'Unable to check for updates',
      );
    }
  }

  static Future<String?> _fetchPubspec() async {
    try {
      final response = await http
          .get(Uri.parse(_pubspecUrl), headers: {'Cache-Control': 'no-cache'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) return response.body;

      Logger.w(_tag, 'Pubspec fetch status: ${response.statusCode}');
      return null;
    } catch (e) {
      Logger.w(_tag, 'Pubspec fetch failed: $e');
      return null;
    }
  }

  static String? _extractField(String content, String field) {
    try {
      final regex = RegExp('^$field:\\s*([^\\s#]+)', multiLine: true);
      final match = regex.firstMatch(content);
      return match?.group(1);
    } catch (e) {
      Logger.e(_tag, 'Error extracting field "$field"', e);
      return null;
    }
  }

  static int _compareVersions(String v1, String v2) {
    try {
      final p1 = v1.split('+').first.split('.').map(int.parse).toList();
      final p2 = v2.split('+').first.split('.').map(int.parse).toList();
      for (int i = 0; i < 3; i++) {
        final a = i < p1.length ? p1[i] : 0;
        final b = i < p2.length ? p2[i] : 0;
        if (a < b) return -1;
        if (a > b) return 1;
      }
      return 0;
    } catch (e) {
      Logger.e(_tag, 'Error comparing versions', e);
      return 0;
    }
  }
}

enum UpdateStatus { upToDate, updateAvailable, error }

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

class KillSwitchResult {
  final bool isBlocked;
  final String currentVersion;
  final String? minVersion;

  const KillSwitchResult._({
    required this.isBlocked,
    required this.currentVersion,
    this.minVersion,
  });

  factory KillSwitchResult.blocked(String current, String min) =>
      KillSwitchResult._(
        isBlocked: true,
        currentVersion: current,
        minVersion: min,
      );

  factory KillSwitchResult.passThrough(String current) =>
      KillSwitchResult._(isBlocked: false, currentVersion: current);
}
