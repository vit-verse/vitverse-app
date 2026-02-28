import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/database/entities/student_profile.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../services/report_data_collector.dart';
import '../services/pdf_generator.dart';
import '../services/json_export_service.dart';
import '../models/student_report_data.dart';

class ReportGenerationPage extends StatefulWidget {
  final StudentProfile profile;

  const ReportGenerationPage({super.key, required this.profile});

  @override
  State<ReportGenerationPage> createState() => _ReportGenerationPageState();
}

class _ReportGenerationPageState extends State<ReportGenerationPage> {
  static const String _tag = 'ReportGeneration';

  bool _isGenerating = true;
  bool _hasError = false;
  String _errorMessage = '';
  StudentReportData? _reportData;
  File? _pdfFile;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'ReportGeneration',
      screenClass: 'ReportGenerationPage',
    );
    _generateReport();
  }

  @override
  void dispose() {
    ReportDataCollectorService.clearCache();
    JsonExportService.clearCache();
    super.dispose();
  }

  Future<void> _generateReport() async {
    try {
      setState(() {
        _isGenerating = true;
        _hasError = false;
      });

      Logger.i(_tag, 'Starting fresh report generation');

      ReportDataCollectorService.clearCache();
      JsonExportService.clearCache();
      await _deleteOldCachedFiles();

      final collector = ReportDataCollectorService();
      final reportData = await collector.collectReportData(forceRefresh: true);

      setState(() {
        _reportData = reportData;
      });

      final pdfGenerator = PdfGeneratorService();
      final pdfFile = await pdfGenerator.generatePDFReport(reportData);

      setState(() {
        _pdfFile = pdfFile;
        _isGenerating = false;
      });

      Logger.success(_tag, 'Report generated successfully');

      if (mounted) {
        SnackbarUtils.success(context, 'Report generated successfully!');
      }
    } catch (e) {
      Logger.e(_tag, 'Failed to generate report', e);
      setState(() {
        _isGenerating = false;
        _hasError = true;
        _errorMessage = e.toString();
      });

      if (mounted) {
        SnackbarUtils.error(context, 'Failed to generate report');
      }
    }
  }

  Future<void> _deleteOldCachedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);

      if (await dir.exists()) {
        final files = dir.listSync();
        for (final file in files) {
          if (file is File) {
            final fileName = file.path.split('/').last;
            if (fileName.startsWith('VIT_Report_')) {
              await file.delete();
              Logger.d(_tag, 'Deleted old cached file: $fileName');
            }
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_report_path_${widget.profile.registerNumber}');
    } catch (e) {
      Logger.w(_tag, 'Failed to delete old cached files: $e');
    }
  }

  Future<void> _sharePDF() async {
    if (_pdfFile == null) return;

    try {
      await Share.shareXFiles(
        [XFile(_pdfFile!.path)],
        subject: 'Academic Report - ${widget.profile.name}',
        text: 'My Academic Report from VIT Verse',
      );

      AnalyticsService.instance.logEvent(
        name: 'report_shared',
        parameters: {'format': 'pdf'},
      );
    } catch (e) {
      Logger.e(_tag, 'Failed to share PDF', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to share PDF');
      }
    }
  }

  Future<void> _downloadPDF() async {
    if (_pdfFile == null) return;

    try {
      Logger.d(_tag, 'Starting PDF download');

      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        Logger.w(_tag, 'Storage permission denied');
        if (mounted) {
          SnackbarUtils.error(
            context,
            'Storage permission is required to download files',
          );
        }
        return;
      }

      Directory? targetDir;
      String folderDescription = 'Downloads';

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            targetDir = Directory('/storage/emulated/0/Documents/VIT Verse');
            folderDescription = 'Documents/VIT Verse';

            if (!await targetDir.exists()) {
              targetDir = Directory('/storage/emulated/0/Download/VIT Verse');
              folderDescription = 'Downloads/VIT Verse';
            }
          }
        } else {
          targetDir = Directory('/storage/emulated/0/Download/VIT Verse');
          folderDescription = 'Downloads/VIT Verse';
        }

        if (targetDir != null && !await targetDir.exists()) {
          await targetDir.create(recursive: true);
          Logger.d(_tag, 'Created directory: ${targetDir.path}');
        }
      } else {
        // iOS
        targetDir = await getApplicationDocumentsDirectory();
        folderDescription = 'Documents';
      }

      if (targetDir == null) {
        Logger.e(_tag, 'Could not determine target directory');
        if (mounted) {
          SnackbarUtils.error(context, 'Could not access storage');
        }
        return;
      }

      final fileName =
          'Academic_Report_${widget.profile.registerNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final destPath = '${targetDir.path}/$fileName';

      Logger.d(_tag, 'Copying PDF to: $destPath');
      await _pdfFile!.copy(destPath);
      Logger.success(_tag, 'PDF downloaded successfully');

      if (mounted) {
        SnackbarUtils.success(context, 'PDF saved to $folderDescription');
      }

      AnalyticsService.instance.logEvent(
        name: 'pdf_downloaded',
        parameters: {
          'register_number': widget.profile.registerNumber,
          'location': folderDescription,
        },
      );
    } catch (e) {
      Logger.e(_tag, 'Failed to download PDF', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to download PDF: ${e.toString()}');
      }
    }
  }

  Future<void> _downloadJSON() async {
    if (_reportData == null) return;

    try {
      Logger.d(_tag, 'Starting JSON download');

      // Request storage permission first
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        Logger.w(_tag, 'Storage permission denied');
        if (mounted) {
          SnackbarUtils.error(
            context,
            'Storage permission is required to download files',
          );
        }
        return;
      }

      // Get appropriate directory based on Android version
      Directory? targetDir;
      String folderDescription = 'Downloads';

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          // Android 13+ - Use app-specific external directory or Documents
          targetDir = Directory('/storage/emulated/0/Documents/VIT Verse');
          folderDescription = 'Documents/VIT Verse';

          // If Documents doesn't work, fall back to Downloads
          if (!await targetDir.exists()) {
            targetDir = Directory('/storage/emulated/0/Download/VIT Verse');
            folderDescription = 'Downloads/VIT Verse';
          }
        } else {
          // Android 10-12 - Use Downloads folder
          targetDir = Directory('/storage/emulated/0/Download/VIT Verse');
          folderDescription = 'Downloads/VIT Verse';
        }

        // Verify directory exists or create it
        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
          Logger.d(_tag, 'Created directory: ${targetDir.path}');
        }
      } else {
        // iOS
        targetDir = await getApplicationDocumentsDirectory();
        folderDescription = 'Documents';
      }

      // Export JSON
      final jsonService = JsonExportService();
      final jsonString = jsonService.getJsonString(_reportData!);

      final fileName =
          'Academic_Report_${widget.profile.registerNumber}_${DateTime.now().millisecondsSinceEpoch}.json';
      final destPath = '${targetDir.path}/$fileName';
      final file = File(destPath);

      Logger.d(_tag, 'Writing JSON to: $destPath');
      await file.writeAsString(jsonString);
      Logger.success(_tag, 'JSON downloaded successfully');

      if (mounted) {
        SnackbarUtils.success(context, 'JSON saved to $folderDescription');
      }

      AnalyticsService.instance.logEvent(
        name: 'json_downloaded',
        parameters: {'format': 'json', 'location': folderDescription},
      );
    } catch (e) {
      Logger.e(_tag, 'Failed to download JSON', e);
      if (mounted) {
        SnackbarUtils.error(
          context,
          'Failed to download JSON: ${e.toString()}',
        );
      }
    }
  }

  /// Request storage permission
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      try {
        // Check Android version
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        Logger.d(_tag, 'Android SDK: $sdkInt - Requesting storage permission');

        if (sdkInt >= 33) {
          // Android 13+ (API 33+)
          // For Downloads folder access, we need to use MediaStore API
          // or request MANAGE_EXTERNAL_STORAGE (which requires special approval)
          // For now, we'll use app-specific directories that don't need permission
          Logger.i(
            _tag,
            'Android 13+: Using scoped storage (no permission needed)',
          );
          return true; // No explicit permission needed for app directories
        } else if (sdkInt >= 30) {
          // Android 11-12 (API 30-32)
          // Try MANAGE_EXTERNAL_STORAGE first
          var status = await Permission.manageExternalStorage.status;

          if (status.isGranted) {
            Logger.i(_tag, 'MANAGE_EXTERNAL_STORAGE already granted');
            return true;
          }

          // Request the permission
          status = await Permission.manageExternalStorage.request();

          if (status.isGranted) {
            Logger.success(_tag, 'MANAGE_EXTERNAL_STORAGE granted');
            return true;
          } else if (status.isPermanentlyDenied) {
            // User permanently denied, guide them to settings
            if (mounted) {
              _showPermissionDialog();
            }
            return false;
          } else {
            Logger.w(_tag, 'MANAGE_EXTERNAL_STORAGE denied');
            return false;
          }
        } else {
          // Android 10 and below (API 29 and lower)
          var status = await Permission.storage.status;

          if (status.isGranted) {
            Logger.i(_tag, 'Storage permission already granted');
            return true;
          }

          status = await Permission.storage.request();

          if (status.isGranted) {
            Logger.success(_tag, 'Storage permission granted');
            return true;
          } else if (status.isPermanentlyDenied) {
            if (mounted) {
              _showPermissionDialog();
            }
            return false;
          } else {
            Logger.w(_tag, 'Storage permission denied');
            return false;
          }
        }
      } catch (e) {
        Logger.e(_tag, 'Error requesting storage permission', e);
        return false;
      }
    }
    return true; // iOS doesn't need explicit permission for documents
  }

  /// Show dialog to guide user to app settings
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Storage Permission Required'),
            content: const Text(
              'To download files to your device, please grant storage permission in app settings.\n\n'
              'Go to: Settings > Apps > VIT Verse > Permissions > Storage',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  Future<void> _copyJSON() async {
    if (_reportData == null) return;

    try {
      final jsonService = JsonExportService();
      final jsonString = jsonService.getJsonString(_reportData!);

      await Clipboard.setData(ClipboardData(text: jsonString));

      if (mounted) {
        SnackbarUtils.success(context, 'JSON copied to clipboard!');
      }

      AnalyticsService.instance.logEvent(
        name: 'json_copied',
        parameters: {'format': 'json'},
      );
    } catch (e) {
      Logger.e(_tag, 'Failed to copy JSON', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to copy JSON');
      }
    }
  }

  Future<void> _copyCSV() async {
    if (_reportData == null) return;

    try {
      final jsonService = JsonExportService();
      // Use the comprehensive text format instead of basic CSV
      final textData = jsonService.getTextString(_reportData!);

      await Clipboard.setData(ClipboardData(text: textData));

      if (mounted) {
        SnackbarUtils.success(context, 'Complete report copied to clipboard!');
      }

      AnalyticsService.instance.logEvent(
        name: 'text_copied',
        parameters: {'format': 'text'},
      );
    } catch (e) {
      Logger.e(_tag, 'Failed to copy text', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to copy text');
      }
    }
  }

  Future<void> _shareForAIAnalysis() async {
    if (_reportData == null) return;

    try {
      final jsonService = JsonExportService();
      final jsonFile = await jsonService.exportToJson(_reportData!);

      // Share the JSON file - user can choose their preferred AI app
      await Share.shareXFiles(
        [XFile(jsonFile.path)],
        subject: 'Academic Report Analysis Request',
        text: 'Please analyze my academic performance based on this data.',
      );

      AnalyticsService.instance.logEvent(
        name: 'ai_analysis_shared',
        parameters: {'format': 'json'},
      );

      if (mounted) {
        SnackbarUtils.success(
          context,
          'Select your preferred AI app (ChatGPT, Gemini, etc.) to analyze',
        );
      }
    } catch (e) {
      Logger.e(_tag, 'Failed to share for AI analysis', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to share for AI analysis');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text('Generate Report', style: TextStyle(color: theme.text)),
        backgroundColor: theme.surface,
        iconTheme: IconThemeData(color: theme.text),
        elevation: 0,
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(dynamic theme) {
    if (_hasError) {
      return _buildErrorState(theme);
    }

    if (_isGenerating) {
      return _buildLoadingState(theme);
    }

    return _buildSuccessState(theme);
  }

  Widget _buildLoadingState(dynamic theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.primary),
          const SizedBox(height: 24),
          Text(
            'Generating Your Report...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Collecting your academic data, performance metrics, and fee details',
              style: TextStyle(fontSize: 14, color: theme.muted),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          _buildProgressIndicators(theme),
        ],
      ),
    );
  }

  Widget _buildProgressIndicators(dynamic theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressItem(theme, 'Student Profile', true),
          _buildProgressItem(theme, 'Academic Performance', true),
          _buildProgressItem(theme, 'Grade History', true),
          _buildProgressItem(theme, 'Marks History', true),
          _buildProgressItem(theme, 'Fee Details', true),
          _buildProgressItem(theme, 'Generating PDF', _isGenerating),
        ],
      ),
    );
  }

  Widget _buildProgressItem(dynamic theme, String label, bool completed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? theme.primary : theme.muted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: completed ? theme.text : theme.muted,
              fontWeight: completed ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(dynamic theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Success Icon
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.primary.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 80,
              color: theme.primary,
            ),
          ),
          const SizedBox(height: 24),

          // Success Message
          Text(
            'Report Generated Successfully!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: theme.text,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Your comprehensive academic report is ready',
            style: TextStyle(fontSize: 14, color: theme.muted),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Regenerate Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _generateReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Regenerate Report'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: theme.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Main Action Buttons
          _buildPrimaryActionButton(
            theme: theme,
            icon: Icons.share,
            label: 'Share PDF File',
            onTap: _sharePDF,
          ),

          const SizedBox(height: 12),

          _buildPrimaryActionButton(
            theme: theme,
            icon: Icons.download,
            label: 'Download PDF File',
            onTap: _downloadPDF,
          ),

          const SizedBox(height: 12),

          _buildPrimaryActionButton(
            theme: theme,
            icon: Icons.download_outlined,
            label: 'Download JSON File',
            onTap: _downloadJSON,
          ),

          const SizedBox(height: 12),

          _buildPrimaryActionButton(
            theme: theme,
            icon: Icons.content_copy,
            label: 'Copy JSON Text',
            onTap: _copyJSON,
          ),

          const SizedBox(height: 12),

          _buildPrimaryActionButton(
            theme: theme,
            icon: Icons.table_chart,
            label: 'Copy Full Report (Text)',
            onTap: _copyCSV,
          ),

          const SizedBox(height: 30),

          // AI Analysis Button
          _buildPrimaryActionButton(
            theme: theme,
            icon: Icons.psychology,
            label: 'Analyze with AI',
            onTap: _shareForAIAnalysis,
          ),

          const SizedBox(height: 8),
          Text(
            'Share JSON file to your preferred AI app (ChatGPT, Gemini, etc.)',
            style: TextStyle(fontSize: 12, color: theme.muted),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          // Disclaimer
          _buildDisclaimer(theme),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton({
    required dynamic theme,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.surface,
          foregroundColor: theme.text,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: theme.border),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildReportSummary(dynamic theme) {
    if (_reportData == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(theme, 'CGPA', _reportData!.cgpa.toStringAsFixed(2)),
          _buildSummaryRow(
            theme,
            'Credits',
            '${_reportData!.creditsEarned.toStringAsFixed(0)}/${_reportData!.totalCreditsRequired.toStringAsFixed(0)}',
          ),
          _buildSummaryRow(
            theme,
            'Total Courses',
            _reportData!.totalCourses.toString(),
          ),
          _buildSummaryRow(
            theme,
            'Semesters',
            _reportData!.semesterPerformances.length.toString(),
          ),
          _buildSummaryRow(
            theme,
            'Total Fees Paid',
            '₹${_reportData!.totalFeesPaid.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(dynamic theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: theme.muted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.text,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildActionButton({
    required dynamic theme,
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: theme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: theme.muted),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: theme.muted, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimer(dynamic theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.muted, size: 18),
              const SizedBox(width: 8),
              Text(
                'Disclaimer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'This report is generated by VIT Verse for informational purposes only. It is NOT an official document and is NOT affiliated with VIT Chennai.',
            style: TextStyle(fontSize: 11, color: theme.muted, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(dynamic theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: theme.error),
            const SizedBox(height: 24),
            Text(
              'Failed to Generate Report',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: TextStyle(fontSize: 14, color: theme.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: _generateReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
