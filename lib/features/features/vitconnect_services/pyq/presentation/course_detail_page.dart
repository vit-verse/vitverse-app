import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/app_card_styles.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../controller/pyq_controller.dart';
import '../data/pyq_models.dart';

/// Course Detail Page - shows papers for a specific course
class CourseDetailPage extends StatefulWidget {
  final String courseCode;
  final String courseTitle;
  final int totalPapers;

  const CourseDetailPage({
    super.key,
    required this.courseCode,
    required this.courseTitle,
    required this.totalPapers,
  });

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  static const _tag = 'CourseDetailPage';
  bool _isLoading = true;
  List<PyqPaper> _papers = [];
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPapers();
    });
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  Future<void> _loadPapers() async {
    final controller = Provider.of<PyqController>(context, listen: false);
    await controller.loadCourse(widget.courseCode);
    setState(() {
      _papers = controller.currentPapers;
      _isLoading = false;
    });
  }

  Future<void> _viewPdf(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      Logger.e(_tag, 'Failed to open PDF', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to open PDF');
      }
    }
  }

  Future<void> _downloadPdf(PyqPaper paper) async {
    try {
      // Always request storage permission
      PermissionStatus status;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          // Android 13+ doesn't need storage permission for downloads
          status = PermissionStatus.granted;
        } else {
          status = await Permission.storage.request();
        }
      } else {
        status = await Permission.storage.request();
      }

      if (!status.isGranted) {
        if (mounted) {
          SnackbarUtils.error(context, 'Storage permission denied');
        }
        return;
      }

      // Extract filename from URL
      String fileName = paper.paperId;
      if (paper.fileUrl.contains('/')) {
        final urlParts = paper.fileUrl.split('/');
        fileName = urlParts.last;
        if (fileName.contains('?')) {
          fileName = fileName.split('?').first;
        }
      }
      if (!fileName.toLowerCase().endsWith('.pdf')) {
        fileName = '$fileName.pdf';
      }

      if (mounted) {
        SnackbarUtils.info(context, 'Downloading...');
      }

      // Download file
      final response = await http.get(Uri.parse(paper.fileUrl));
      if (response.statusCode != 200) {
        throw 'Download failed with status: ${response.statusCode}';
      }

      // Save to Downloads directory (works on Android 10+)
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      Logger.i(_tag, 'Downloaded to: $filePath');

      // Show notification
      const androidDetails = AndroidNotificationDetails(
        'pyq_downloads',
        'PYQ Downloads',
        channelDescription: 'Notifications for PYQ paper downloads',
        importance: Importance.high,
        priority: Priority.high,
      );
      const notificationDetails = NotificationDetails(android: androidDetails);
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        'Download Complete',
        fileName,
        notificationDetails,
      );

      if (mounted) {
        SnackbarUtils.success(context, 'Downloaded to Downloads folder');
      }
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Download failed', e, stackTrace);
      if (mounted) {
        SnackbarUtils.error(context, 'Download failed: ${e.toString()}');
      }
    }
  }

  Map<String, List<PyqPaper>> _groupByExam() {
    final grouped = <String, List<PyqPaper>>{};
    for (final paper in _papers) {
      grouped.putIfAbsent(paper.exam, () => []).add(paper);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.courseCode,
              style: TextStyle(
                color: theme.text,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.courseTitle,
              style: TextStyle(color: theme.muted, fontSize: 12),
            ),
          ],
        ),
        backgroundColor: theme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.text),
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: theme.primary))
              : _papers.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: theme.muted),
                    const SizedBox(height: 16),
                    Text(
                      'No papers available',
                      style: TextStyle(color: theme.muted),
                    ),
                  ],
                ),
              )
              : ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildStatsCard(theme),
                  const SizedBox(height: 12),
                  ..._buildExamSections(theme),
                ],
              ),
    );
  }

  Widget _buildStatsCard(dynamic theme) {
    final grouped = _groupByExam();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.surface,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Total Papers: ',
            style: TextStyle(color: theme.muted, fontSize: 12),
          ),
          Text(
            '${_papers.length}',
            style: TextStyle(
              color: theme.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Container(
            width: 1,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: theme.border.withOpacity(0.3),
          ),
          Text('Exams: ', style: TextStyle(color: theme.muted, fontSize: 12)),
          Text(
            '${grouped.length}',
            style: TextStyle(
              color: theme.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildExamSections(dynamic theme) {
    final grouped = _groupByExam();
    return grouped.entries.map((entry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Text(
              entry.key,
              style: TextStyle(
                color: theme.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...entry.value.map((paper) => _buildPaperCard(paper, theme)),
          const SizedBox(height: 8),
        ],
      );
    }).toList();
  }

  Widget _buildPaperCard(PyqPaper paper, dynamic theme) {
    // Extract filename from URL
    String fileName = paper.paperId;
    if (paper.fileUrl.contains('/')) {
      final urlParts = paper.fileUrl.split('/');
      fileName = urlParts.last;
      // Remove query parameters if any
      if (fileName.contains('?')) {
        fileName = fileName.split('?').first;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: theme.isDark,
        customBackgroundColor: theme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  color: theme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _viewPdf(paper.fileUrl),
                icon: Icon(Icons.open_in_browser, size: 16),
                label: Text('View'),
                style: TextButton.styleFrom(
                  foregroundColor: theme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _downloadPdf(paper),
                icon: Icon(Icons.download, size: 16),
                label: Text('Download'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
