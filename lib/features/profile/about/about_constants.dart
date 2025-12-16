import '../../../core/config/app_version.dart';

/// All constants for the About page
class AboutConstants {
  AboutConstants._();

  // APP INFO
  static const String appName = 'VIT Verse';
  static String get appVersion => AppVersion.version;
  static const String appTagline = '🌻';

  // DISCLAIMER
  static const String disclaimerTitle = 'Disclaimer';
  static const String disclaimerText =
      'VIT Verse is independently developed and has no official affiliation with VIT Chennai. Created by students for students. You can uninstall the app anytime.';

  // SECURITY & PRIVACY
  static const String securityTitle = 'Security & Privacy';
  static const String securityText =
      'Your credentials are encrypted using AES-256 and stored locally on your device only. Direct communication with VTOP servers. No data is sent to third parties.';

  // TECH STACK
  static const String techStackTitle = 'Tech Stack';
  static const String techStackDescription =
      'Flutter Framework • Firebase Analytics, Crashlytics, Messaging, Functions • Supabase Database • GitHub Version Control • Vercel Edge Runtime • + many more';

  // Tech Stack Icons
  static const List<Map<String, String>> techStackIcons = [
    {'name': 'Flutter', 'icon': 'assets/icons/flutter.png'},
    {'name': 'Firebase', 'icon': 'assets/icons/firebase.png'},
    {'name': 'Supabase', 'icon': 'assets/icons/supabase.png'},
    {'name': 'GitHub', 'icon': 'assets/icons/github.png'},
    {'name': 'Vercel', 'icon': 'assets/icons/vercel.png'},
  ];

  // LEAD DEVELOPER
  static const String leadDeveloperTitle = 'LEAD DEVELOPER';
  static const String leadDeveloperName = 'Divyanshu Patel';
  static const String leadDeveloperRole = 'Lead Developer';
  static const String leadDeveloperGithub =
      'https://github.com/divyanshupatel17';
  static const String leadDeveloperLinkedin =
      'https://www.linkedin.com/in/patel-divyanshu';

  // COLLABORATIONS
  static const String collaborationsTitle = 'COLLABORATIONS';
  static const String collaborationProject = 'Unmessify';
  static const String collaborationDescription =
      'Developed by Kanishka Chakraborty & Teesha Saxena';
  static const String collaborationWebsite = 'https://kaffeine.tech/unmessify';
  static const String collaborationGithub =
      'https://github.com/Kanishka-Developer/unmessify';

  // CONTRIBUTORS & CREDITS
  static const String contributorsTitle = 'CONTRIBUTORS & CREDITS';
  static const List<Map<String, String>> contributors = [
    {
      'name': 'Ashutosh Gunjal',
      'github': 'https://github.com/ashutosh-gunjal-001',
      'linkedin': 'https://www.linkedin.com/in/ashutosh-gunjal-7a2b8228b',
    },
  ];

  // LINKS
  static const String githubRepo = 'https://github.com/vit-verse';
  static const String whatsappGroup =
      'https://chat.whatsapp.com/G1CNYLaMgYu6ePIzT2csWM';
  // static const String vitVerseOrg = 'https://github.com/vit-verse';
  static const String appWebsite = 'https://vitverse.divyanshupatel.com';
  static const String feedbackFormUrl =
      'https://docs.google.com/forms/d/e/1FAIpQLSe_qJctOUUB5h9u7kCzAOjJy_1IyGbhdlJATHGOkyjcGPmjUA/viewform?usp=dialog';

  // GITHUB REPOSITORY INFO
  static const String githubRepoOwner = 'vit-verse';
  static const String githubRepoName = 'vitverse-app';

  // LEGAL DOCUMENTS (GitHub URLs)
  static const String privacyPolicyGithub =
      'https://github.com/vit-verse/vitverse-app/blob/main/PRIVACY_POLICY.md';
  static const String termsOfServiceGithub =
      'https://github.com/vit-verse/vitverse-app/blob/main/TERMS_OF_SERVICE.md';

  // LEGAL DOCUMENTS (Direct Raw URLs for fetching)
  static const String privacyPolicyRawUrl =
      'https://raw.githubusercontent.com/vit-verse/vitverse-app/main/PRIVACY_POLICY.md';
  static const String termsOfServiceRawUrl =
      'https://raw.githubusercontent.com/vit-verse/vitverse-app/main/TERMS_OF_SERVICE.md';

  // SHARE TEXT
  static const String shareAppText = '''
Check out VIT Verse - your ultimate VIT Chennai companion!

📚 Track Attendance & Academic Progress
🎓 Seamless VTOP Integration
🤝 Connect with Fellow VITians
📅 Add Your Friends' Schedules
✨ Explore 20+ Smart Student Features

It's live now - don't miss out!
👇 Download Now: https://vitverse.divyanshupatel.com
''';

  // BUTTON LABELS
  static const String checkUpdateLabel = 'Check Update';
  static const String shareAppLabel = 'Share App';
  static const String visitWebsiteLabel = 'Visit VIT Verse Website';
  static const String websiteSubtitle = 'Explore our website';
  static const String openSourceLabel = 'Open Source';
  static const String viewRepositoryLabel = 'View repository on GitHub';
  static const String joinCommunityLabel = 'Join Community Group';
  static const String communitySubtitle = 'Got doubts? Ask on WhatsApp';
  static const String vitVerseOrgLabel = 'VIT Verse Organization';
  static const String vitVerseOrgSubtitle =
      'Explore related projects & contribute';
  static const String requestFeatureLabel = 'Request Feature';
  static const String reportBugLabel = 'Report Bug';
  static const String privacyPolicyLabel = 'Privacy Policy';
  static const String termsOfServiceLabel = 'Terms of Service';
  static const String submitFeedbackLabel = 'Submit Feedback';
  static const String feedbackSubtitle = 'Share your thoughts with us';

  // SOCIAL ICONS (using existing assets)
  static const String githubAsset = 'assets/icons/github.png';
  static const String linkedinAsset = 'assets/icons/linkedin.png';
  static const String whatsappAsset = 'assets/icons/whatsapp.png';
  static const String websiteIconAsset = 'assets/icons/website.png';
  static const String developerIconAsset = 'assets/icons/developer.png';
  static const String collaborationIconAsset = 'assets/icons/collaboration.png';
  static const String contributionIconAsset = 'assets/icons/contributation.png';

  // APP LOGO
  static const String appLogoAsset = 'assets/images/vitconnect-icon.png';
}
