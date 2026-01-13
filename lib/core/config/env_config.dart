class EnvConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static const String supabaseEventsUrl = String.fromEnvironment(
    'SUPABASE_EVENTS_URL',
    defaultValue: '',
  );

  static const String supabaseEventsAnonKey = String.fromEnvironment(
    'SUPABASE_EVENTS_ANON_KEY',
    defaultValue: '',
  );

  static const String githubVitconnectToken = String.fromEnvironment(
    'GITHUB_VITCONNECT_TOKEN',
    defaultValue:
        '',
  );

  static const String pyqSecretHeader = String.fromEnvironment(
    'PYQ_SECRET_HEADER',
    defaultValue: '',
  );

  static const String eventsSecretHeader = String.fromEnvironment(
    'EVENTS_SECRET_HEADER',
    defaultValue: '',
  );

  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        githubVitconnectToken.isNotEmpty &&
        pyqSecretHeader.isNotEmpty &&
        supabaseEventsUrl.isNotEmpty &&
        supabaseEventsAnonKey.isNotEmpty &&
        eventsSecretHeader.isNotEmpty;
  }

  static bool get isEventsConfigured {
    return supabaseEventsUrl.isNotEmpty && 
        supabaseEventsAnonKey.isNotEmpty &&
        eventsSecretHeader.isNotEmpty;
  }

  static List<String> getMissingVars() {
    final missing = <String>[];
    if (supabaseUrl.isEmpty) missing.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missing.add('SUPABASE_ANON_KEY');
    if (githubVitconnectToken.isEmpty) missing.add('GITHUB_VITCONNECT_TOKEN');
    if (pyqSecretHeader.isEmpty) missing.add('PYQ_SECRET_HEADER');
    if (supabaseEventsUrl.isEmpty) missing.add('SUPABASE_EVENTS_URL');
    if (supabaseEventsAnonKey.isEmpty) missing.add('SUPABASE_EVENTS_ANON_KEY');
    if (eventsSecretHeader.isEmpty) missing.add('EVENTS_SECRET_HEADER');
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
