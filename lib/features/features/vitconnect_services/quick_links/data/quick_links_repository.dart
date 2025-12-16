import '../../../../../core/utils/logger.dart';
import '../models/quick_links_data.dart';
import 'quick_links_constants.dart';

class QuickLinksRepository {
  static const String _tag = 'QuickLinksRepository';

  Future<QuickLinksData> fetchQuickLinksData() async {
    try {
      final importantLinks =
          QuickLinksConstants.importantLinks
              .map((e) => ImportantLink.fromJson(e))
              .toList();

      final communityLinks =
          QuickLinksConstants.communityLinks
              .map((e) => CommunityLink.fromJson(e))
              .toList();

      return QuickLinksData(
        importantLinks: importantLinks,
        communityLinks: communityLinks,
      );
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error fetching quick links: $e', stackTrace);
      return QuickLinksData.empty();
    }
  }
}
