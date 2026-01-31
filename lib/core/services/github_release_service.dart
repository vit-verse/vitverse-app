import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// Service to fetch GitHub release information
class GitHubReleaseService {
  static const String _tag = 'GitHubRelease';
  static const String _repoOwner = 'vit-verse';
  static const String _repoName = 'vitverse-app';

  /// Fetch release information for a specific version
  /// Example: getRelease('2.1.0') fetches info for v2.1.0
  static Future<ReleaseInfo?> getRelease(String version) async {
    try {
      // Ensure version starts with 'v'
      final tagName = version.startsWith('v') ? version : 'v$version';
      final url =
          'https://api.github.com/repos/$_repoOwner/$_repoName/releases/tags/$tagName';

      Logger.d(_tag, 'Fetching release info for $tagName from $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final releaseInfo = ReleaseInfo.fromJson(data);
        Logger.i(_tag, 'Successfully fetched release: ${releaseInfo.name}');
        return releaseInfo;
      } else if (response.statusCode == 404) {
        Logger.w(_tag, 'Release not found for $tagName');
        return null;
      } else {
        Logger.w(_tag, 'Failed to fetch release: ${response.statusCode}');
        return null;
      }
    } catch (e, stack) {
      Logger.e(_tag, 'Error fetching release info', e, stack);
      return null;
    }
  }

  /// Get the latest release
  static Future<ReleaseInfo?> getLatestRelease() async {
    try {
      final url =
          'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

      Logger.d(_tag, 'Fetching latest release from $url');

      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final releaseInfo = ReleaseInfo.fromJson(data);
        Logger.i(
          _tag,
          'Successfully fetched latest release: ${releaseInfo.name}',
        );
        return releaseInfo;
      } else {
        Logger.w(
          _tag,
          'Failed to fetch latest release: ${response.statusCode}',
        );
        return null;
      }
    } catch (e, stack) {
      Logger.e(_tag, 'Error fetching latest release', e, stack);
      return null;
    }
  }
}

/// Release information model
class ReleaseInfo {
  final String tagName;
  final String name;
  final String body; // Release notes in markdown
  final String htmlUrl;
  final String publishedAt;
  final bool prerelease;
  final bool draft;

  const ReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
    required this.publishedAt,
    required this.prerelease,
    required this.draft,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    return ReleaseInfo(
      tagName: json['tag_name'] ?? '',
      name: json['name'] ?? '',
      body: json['body'] ?? '',
      htmlUrl: json['html_url'] ?? '',
      publishedAt: json['published_at'] ?? '',
      prerelease: json['prerelease'] ?? false,
      draft: json['draft'] ?? false,
    );
  }

  /// Get version number without 'v' prefix
  String get version =>
      tagName.startsWith('v') ? tagName.substring(1) : tagName;

  /// Get formatted publish date
  String get formattedDate {
    try {
      final date = DateTime.parse(publishedAt);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return publishedAt;
    }
  }
}
