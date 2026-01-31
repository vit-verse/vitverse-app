import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';

class QRCodeShareWidget extends StatefulWidget {
  final String qrData;
  final String studentName;
  final String studentReg;

  const QRCodeShareWidget({
    super.key,
    required this.qrData,
    required this.studentName,
    required this.studentReg,
  });

  @override
  State<QRCodeShareWidget> createState() => _QRCodeShareWidgetState();
}

class _QRCodeShareWidgetState extends State<QRCodeShareWidget> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Share Your Schedule'),
        backgroundColor: theme.surface,
        foregroundColor: theme.text,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: widget.qrData,
                        version: QrVersions.auto,
                        size: 340,
                        backgroundColor: Colors.white,
                        errorStateBuilder: (context, error) {
                          return Container(
                            width: 340,
                            height: 340,
                            color: Colors.grey.shade100,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 40,
                                    color: Colors.red.shade400,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Failed to generate QR',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/vitconnect-icon.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.qr_code_2,
                                    size: 28,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Student Details - Compact
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.studentName.isNotEmpty
                                      ? widget.studentName
                                      : 'Unknown Student',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0A0E27),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.studentReg.isNotEmpty
                                      ? widget.studentReg
                                      : 'No Registration Number',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Hi! I\'m ${widget.studentName.isNotEmpty ? widget.studentName : 'Unknown Student'}'
                  ' (${widget.studentReg.isNotEmpty ? widget.studentReg : 'No Reg'}). '
                  'Scan this QR code to add my schedule in VIT Verse!',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 16), // Action buttons
              _buildActionButtons(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, dynamic theme) {
    return Column(
      children: [
        // Share Button (Primary)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isExporting ? null : () => _shareQRCode(context),
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share QR Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Export to Gallery Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isExporting ? null : () => _exportToGallery(context),
            icon:
                _isExporting
                    ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.download, size: 18),
            label: Text(_isExporting ? 'Exporting...' : 'Save to Gallery'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primary,
              side: BorderSide(color: theme.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Export as Text File Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isExporting ? null : () => _exportAsTextFile(context),
            icon: const Icon(Icons.file_copy, size: 18),
            label: const Text('Export as Text File'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primary,
              side: BorderSide(color: theme.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportToGallery(BuildContext context) async {
    try {
      setState(() => _isExporting = true);
      Logger.d('QRCodeShare', 'Saving QR code to gallery...');

      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      // For Android 13+, use photos permission
      if (Platform.isAndroid) {
        var photosStatus = await Permission.photos.status;
        if (!photosStatus.isGranted) {
          photosStatus = await Permission.photos.request();
        }
      }

      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Could not find QR code widget');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'VITConnect_${widget.studentName.replaceAll(' ', '_')}_${widget.studentReg}_$timestamp.png';

      // Save to gallery
      final result = await ImageGallerySaverPlus.saveImage(
        byteData.buffer.asUint8List(),
        name: fileName,
        quality: 100,
      );

      Logger.success('QRCodeShare', 'QR saved to gallery');

      if (context.mounted) {
        SnackbarUtils.success(context, 'QR code saved to gallery');
      }
    } catch (e) {
      Logger.e('QRCodeShare', 'Failed to save to gallery', e);
      if (context.mounted) {
        SnackbarUtils.error(context, 'Failed to save to gallery');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _shareQRCode(BuildContext context) async {
    try {
      setState(() => _isExporting = true);
      Logger.d('QRCodeShare', 'Sharing QR code...');

      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Could not find QR code widget');
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      final fileName =
          'VITConnect_QR_${widget.studentName.replaceAll(' ', '_')}_${widget.studentReg}.png';
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Hi! I\'m ${widget.studentName} (${widget.studentReg}). '
            'Scan this QR code to add my schedule in VIT Verse!',
      );

      Logger.success('QRCodeShare', 'QR code shared');
    } catch (e) {
      Logger.e('QRCodeShare', 'Failed to share QR', e);
      if (context.mounted) {
        SnackbarUtils.error(context, 'Failed to share QR code');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportAsTextFile(BuildContext context) async {
    setState(() => _isExporting = true);

    try {
      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'VITVerse_${widget.studentName.replaceAll(' ', '_')}_${widget.studentReg}_$timestamp.txt';

      // Create text content
      final textContent = '''VIT Verse Timetable Data

Student Name: ${widget.studentName}
Registration Number: ${widget.studentReg}
Exported: ${DateTime.now().toString()}

--- QR Data ---
${widget.qrData}

--- Instructions ---
To import this data:
1. Open VIT Verse app
2. Go to Friends' Schedule
3. Tap "Add Friends"
4. Select "Import Text File"
5. Choose this file

Generated by VIT Verse - Your Academic Companion''';

      // Save to Downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      final file = File('${directory.path}/$fileName');
      await file.writeAsString(textContent);

      Logger.success('QRCodeShare', 'Text file saved');

      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Hi! I\'m ${widget.studentName} (${widget.studentReg}). '
            'Here\'s my VIT Verse timetable data file. '
            'Import this in VIT Verse to add my schedule!',
      );

      if (context.mounted) {
        SnackbarUtils.success(context, 'Text file saved and shared');
      }
    } catch (e) {
      Logger.e('QRCodeShare', 'Failed to export text file', e);
      if (context.mounted) {
        SnackbarUtils.error(context, 'Failed to export text file');
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }
}
