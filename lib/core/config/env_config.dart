class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String githubVitconnectToken = String.fromEnvironment(
    'GITHUB_VITCONNECT_TOKEN',
    defaultValue: '',
  );

  static const String facultyRatingScriptUrl = String.fromEnvironment(
    'FACULTY_RATING_SCRIPT_URL',
    defaultValue: '',
  );

  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        githubVitconnectToken.isNotEmpty &&
        facultyRatingScriptUrl.isNotEmpty;
  }

  static List<String> getMissingVars() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
    if (githubVitconnectToken.isEmpty) missing.add('GITHUB_VITCONNECT_TOKEN');
    if (facultyRatingScriptUrl.isEmpty)
      missing.add('FACULTY_RATING_SCRIPT_URL');
    return missing;
  }

  static String getConfigStatus() {
    if (isConfigured) {
      return 'All variables configured';
    } else {
      final missing = getMissingVars();
      return 'Missing: ${missing.join(", ")}';
    }
  }
}
