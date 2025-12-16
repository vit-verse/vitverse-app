import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/theme/app_card_styles.dart';
import '../core/auth_service.dart';
import '../utils/auth_states.dart';
import 'dialogs/captcha_dialog.dart';
import 'dialogs/semester_selection_dialog.dart';
import '../../profile/about/markdown_viewer_page.dart';
import '../../profile/about/about_constants.dart';
import '../../main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late VTOPAuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = VTOPAuthService.instance;
    _authService.addListener(_handleAuthStateChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authService.initialize();
    });

    _loadStoredCredentials();
  }

  Future<void> _loadStoredCredentials() async {
    try {
      final hasCreds = await _authService.hasSavedCredentials();
      if (hasCreds && mounted) {
        final creds = await _authService.getSavedCredentials();
        if (creds['username'] != null) {
          setState(() {
            _usernameController.text = creds['username']!;
            if (creds['password'] != null) {
              _passwordController.text = creds['password']!;
            }
          });
        }
      }
    } catch (e) {
      // Silently handle credential loading errors
    }
  }

  @override
  void dispose() {
    _authService.removeListener(_handleAuthStateChange);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleAuthStateChange() {
    if (!mounted) return;

    switch (_authService.authState) {
      case AuthState.captchaRequired:
        _showCaptchaDialog();
        break;
      case AuthState.semesterSelection:
        _showSemesterDialog();
        break;
      case AuthState.complete:
        // Notify platform to save credentials for autofill
        TextInput.finishAutofillContext(shouldSave: true);
        _navigateToHome();
        break;
      case AuthState.error:
        _showError(_authService.errorMessage ?? 'Authentication failed');
        break;
      default:
        break;
    }
  }

  void _showCaptchaDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CaptchaDialog(authService: _authService),
    );
  }

  void _showSemesterDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SemesterSelectionDialog(authService: _authService),
    );
  }

  void _navigateToHome() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleLogin() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    await _authService.authenticate(username, password);
  }

  void _handleLoginLater() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
  }

  String _getLoginProgressText() {
    // Get current sync phase from auth service
    final phase = _authService.currentSyncPhase;

    if (phase == 'P1') {
      return 'Phase 1: Primary Data...';
    } else if (phase == 'P2') {
      return 'Phase 2: Additional Data...';
    } else {
      return 'Authenticating...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _authService,
          builder: (context, child) {
            final isLoading =
                _authService.authState == AuthState.loading ||
                _authService.authState == AuthState.dataDownloading;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    decoration: AppCardStyles.largeCardDecoration(
                      isDark: themeProvider.currentTheme.isDark,
                      customBackgroundColor: themeProvider.currentTheme.surface,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: AutofillGroup(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // VIT Connect Logo with themed background
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color:
                                        themeProvider.currentTheme.isDark
                                            ? themeProvider.currentTheme.primary
                                                .withValues(alpha: 0.1)
                                            : themeProvider.currentTheme.primary
                                                .withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: themeProvider.currentTheme.primary
                                          .withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/images/vitconnect-icon.png',
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.contain,
                                      errorBuilder:
                                          (context, error, stackTrace) => Icon(
                                            Icons.school,
                                            size: 80,
                                            color: theme.colorScheme.primary,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'VIT Verse',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sign in with your VTOP credentials',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Username
                              TextFormField(
                                controller: _usernameController,
                                enabled: !isLoading,
                                autofillHints: const [AutofillHints.username],
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Registration Number',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                textCapitalization:
                                    TextCapitalization.characters,
                                onChanged: (value) {
                                  // Auto-convert to uppercase
                                  final upperCaseValue = value.toUpperCase();
                                  if (value != upperCaseValue) {
                                    _usernameController.value =
                                        _usernameController.value.copyWith(
                                          text: upperCaseValue,
                                          selection: TextSelection.collapsed(
                                            offset: upperCaseValue.length,
                                          ),
                                        );
                                  }
                                },
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your registration number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password
                              TextFormField(
                                controller: _passwordController,
                                enabled: !isLoading,
                                obscureText: _obscurePassword,
                                autofillHints: const [AutofillHints.password],
                                keyboardType: TextInputType.visiblePassword,
                                textInputAction: TextInputAction.done,
                                onEditingComplete:
                                    () => TextInput.finishAutofillContext(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // OCR Enabled Toggle
                              SwitchListTile(
                                value: _authService.isOCREnabled,
                                onChanged:
                                    isLoading
                                        ? null
                                        : _authService.toggleAutoCaptcha,
                                title: const Text('OCR Enabled'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),

                              // Current Semester Toggle
                              SwitchListTile(
                                value: _authService.isAutoSemesterEnabled,
                                onChanged:
                                    isLoading
                                        ? null
                                        : _authService.toggleAutoSemester,
                                title: const Text('Current Semester'),
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              const SizedBox(height: 8),

                              // Login Button
                              FilledButton(
                                onPressed: isLoading ? null : _handleLogin,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child:
                                    isLoading
                                        ? Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Colors.white70),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Flexible(
                                              child: Text(
                                                _getLoginProgressText(),
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        )
                                        : const Text('Login'),
                              ),

                              // Error message below login button
                              if (_authService.authState == AuthState.error &&
                                  _authService.errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _authService.errorMessage!,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 16),

                              // Login Later
                              TextButton(
                                onPressed: _handleLoginLater,
                                child: const Text('Login Later'),
                              ),

                              const SizedBox(height: 8),

                              // Privacy Policy
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => MarkdownViewerPage(
                                            title: 'Privacy Policy',
                                            githubUrl:
                                                AboutConstants
                                                    .privacyPolicyGithub,
                                            directUrl:
                                                AboutConstants
                                                    .privacyPolicyRawUrl,
                                          ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Privacy Policy',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
