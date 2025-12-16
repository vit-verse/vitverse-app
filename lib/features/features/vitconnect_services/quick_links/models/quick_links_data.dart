/// Important Link Model (for Quick Links feature)
class ImportantLink {
  final int id;
  final String title;
  final String link;
  final String desc;

  ImportantLink({
    required this.id,
    required this.title,
    required this.link,
    required this.desc,
  });

  factory ImportantLink.fromJson(Map<String, dynamic> json) {
    return ImportantLink(
      id: json['id'] as int,
      title: json['title'] as String,
      link: json['link'] as String,
      desc: json['desc'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'title': title, 'link': link, 'desc': desc};
  }
}

/// Community Link Model
class CommunityLink {
  final String title;
  final String link;
  final String icon;

  CommunityLink({required this.title, required this.link, required this.icon});

  factory CommunityLink.fromJson(Map<String, dynamic> json) {
    return CommunityLink(
      title: json['title'] as String,
      link: json['link'] as String,
      icon: json['icon'] as String,
    );
  }
}

/// Wrapper model for Quick Links data
/// Combines important links and community links
class QuickLinksData {
  final List<ImportantLink> importantLinks;
  final List<CommunityLink> communityLinks;

  QuickLinksData({required this.importantLinks, required this.communityLinks});

  /// Check if there are any links
  bool get hasAnyLinks =>
      importantLinks.isNotEmpty || communityLinks.isNotEmpty;

  /// Check if there are important links
  bool get hasImportantLinks => importantLinks.isNotEmpty;

  /// Check if there are community links
  bool get hasCommunityLinks => communityLinks.isNotEmpty;

  /// Create empty instance
  factory QuickLinksData.empty() {
    return QuickLinksData(importantLinks: [], communityLinks: []);
  }
}
