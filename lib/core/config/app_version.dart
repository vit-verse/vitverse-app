import 'package:package_info_plus/package_info_plus.dart';

/// App version information
class AppVersion {
  static PackageInfo? _packageInfo;

  static Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  static String get version => _packageInfo?.version ?? '1.1.0';

  static int get build => int.tryParse(_packageInfo?.buildNumber ?? '3') ?? 3;

  static String get fullVersion => '$version+$build';

  static int get versionCode => _calculateVersionCode(version);

  static int _calculateVersionCode(String version) {
    final parts = version.split('.');
    if (parts.length != 3) return 0;

    final major = int.tryParse(parts[0]) ?? 0;
    final minor = int.tryParse(parts[1]) ?? 0;
    final patch = int.tryParse(parts[2]) ?? 0;

    return (major * 10000) + (minor * 100) + patch;
  }
}
