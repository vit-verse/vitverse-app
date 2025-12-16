import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/app_card_styles.dart';
import '../../core/auth_service.dart';
import '../../utils/auth_states.dart';

class CaptchaDialog extends StatefulWidget {
  final VTOPAuthService authService;

  const CaptchaDialog({super.key, required this.authService});

  @override
  State<CaptchaDialog> createState() => _CaptchaDialogState();
}

class _CaptchaDialogState extends State<CaptchaDialog> {
  final _captchaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    widget.authService.addListener(_handleAuthStateChange);

    final ocrText = widget.authService.ocrRecognizedText;
    if (ocrText != null && ocrText.isNotEmpty) {
      _captchaController.text = ocrText;
    }
  }

  @override
  void dispose() {
    widget.authService.removeListener(_handleAuthStateChange);
    _captchaController.dispose();
    super.dispose();
  }

  void _handleAuthStateChange() {
    if (!mounted) return;

    if (widget.authService.authState != AuthState.captchaRequired) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitCaptcha() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.authService.solveCaptcha(_captchaController.text.trim());
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _captchaController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return PopScope(
      canPop: !_isSubmitting,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: AppCardStyles.largeCardDecoration(
            isDark: themeProvider.currentTheme.isDark,
            customBackgroundColor: themeProvider.currentTheme.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    'Enter Captcha',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Captcha image
                  if (widget.authService.captchaType ==
                          CaptchaType.defaultCaptcha &&
                      widget.authService.captchaImage != null) ...[
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Image.memory(
                          widget.authService.captchaImage!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // reCAPTCHA message
                  if (widget.authService.captchaType ==
                      CaptchaType.reCaptcha) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Solving reCAPTCHA automatically...',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // OCR status
                  if (widget.authService.isOCREnabled &&
                      widget.authService.ocrRecognizedText != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'OCR: ${widget.authService.ocrRecognizedText}',
                              style: const TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (widget.authService.captchaType ==
                      CaptchaType.defaultCaptcha) ...[
                    TextFormField(
                      controller: _captchaController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'Captcha',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.security),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      autofocus: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the captcha';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _submitCaptcha(),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'reCAPTCHA is being processed automatically. Please wait...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  if (widget.authService.captchaType ==
                      CaptchaType.defaultCaptcha) ...[
                    FilledButton(
                      onPressed: _isSubmitting ? null : _submitCaptcha,
                      child:
                          _isSubmitting
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Submit'),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: null, // Disabled for reCAPTCHA
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Processing...'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // This will trigger a page refresh
                          },
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
