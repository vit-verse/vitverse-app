import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../models/friend.dart';
import '../services/friends_timetable_service.dart';
import '../widgets/qr_scanner_widget.dart';

class AddFriendsPage extends StatefulWidget {
  const AddFriendsPage({super.key});

  @override
  State<AddFriendsPage> createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  final FriendsScheduleService _service = FriendsScheduleService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'AddFriends',
      screenClass: 'AddFriendsPage',
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _service.loadFriends();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to load friends');
      }
    }
  }

  Future<void> _toggleFriendsScheduleVisibility(String friendId) async {
    try {
      await _service.toggleFriendsScheduleVisibility(friendId);
      setState(() {});
    } catch (e) {
      if (mounted) {
        SnackbarUtils.error(
          context,
          'Failed to update Friends Schedule visibility',
        );
      }
    }
  }

  Future<void> _toggleHomePageVisibility(String friendId) async {
    try {
      await _service.toggleHomePageVisibility(friendId);
      setState(() {});
    } catch (e) {
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to update Home Page visibility');
      }
    }
  }

  Future<void> _updateNickname(Friend friend) async {
    final controller = TextEditingController(text: friend.nickname);

    final newNickname = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Nickname'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nickname',
                hintText: 'Enter a nickname for this friend',
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (newNickname != null &&
        newNickname.isNotEmpty &&
        newNickname != friend.nickname) {
      try {
        await _service.updateFriendNickname(friend.id, newNickname);
        setState(() {});
        if (mounted) {
          SnackbarUtils.success(context, 'Nickname updated to "$newNickname"');
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.error(context, 'Failed to update nickname');
        }
      }
    }
  }

  Future<void> _removeFriend(Friend friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Friend'),
            content: Text('Are you sure you want to remove ${friend.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remove'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await _service.removeFriend(friend.id);
        setState(() {});
        if (mounted) {
          SnackbarUtils.success(context, '${friend.name} removed');
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtils.error(context, 'Failed to remove friend');
        }
      }
    }
  }

  Future<void> _saveTimetableToFile(Friend friend) async {
    try {
      // Generate QR data string for re-importable format
      final qrData = friend.toQRString();

      // Create text content in VIT Verse format
      final textContent = '''VIT Verse Timetable Data

Student Name: ${friend.name}
Registration Number: ${friend.regNumber}
Exported: ${DateTime.now()}

--- QR Data ---
$qrData

--- Instructions ---
To import this data:
1. Open VIT Verse app
2. Go to Friends' Schedule
3. Tap "Add Friends"
4. Select "Import Text File"
5. Choose this file

Generated by VIT Verse - Your Academic Companion''';

      // Request storage permission
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      // Get Downloads directory
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

      // Create file name with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'VITVerse_${friend.name.replaceAll(' ', '_')}_${friend.regNumber}_$timestamp.txt';

      final file = File('${directory.path}/$fileName');

      // Write to file
      await file.writeAsString(textContent);

      Logger.success('AddFriendsPage', 'Timetable saved: ${friend.name}');

      if (mounted) {
        SnackbarUtils.success(
          context,
          'Timetable saved to Downloads/$fileName',
        );
      }
    } catch (e) {
      Logger.e('AddFriendsPage', 'Failed to save timetable', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to save timetable');
      }
    }
  }

  Widget _buildAddOptions(dynamic theme, double screenWidth) {
    return Container(
      margin: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
      padding: EdgeInsets.all(screenWidth < 360 ? 12 : 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ADD FRIEND',
            style: TextStyle(
              fontSize: screenWidth < 360 ? 11 : 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: theme.text,
            ),
          ),
          SizedBox(height: screenWidth < 360 ? 12 : 16),
          Row(
            children: [
              Expanded(
                child: _buildOptionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan QR',
                  onTap: _showQRScanner,
                  theme: theme,
                  screenWidth: screenWidth,
                ),
              ),
              SizedBox(width: screenWidth < 360 ? 8 : 12),
              Expanded(
                child: _buildOptionButton(
                  icon: Icons.image,
                  label: 'Gallery',
                  onTap: _importFromGallery,
                  theme: theme,
                  screenWidth: screenWidth,
                ),
              ),
              SizedBox(width: screenWidth < 360 ? 8 : 12),
              Expanded(
                child: _buildOptionButton(
                  icon: Icons.file_copy,
                  label: 'Text File',
                  onTap: _importFromTextFile,
                  theme: theme,
                  screenWidth: screenWidth,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required dynamic theme,
    required double screenWidth,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: screenWidth < 360 ? 12 : 14,
          horizontal: screenWidth < 360 ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: theme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.primary, size: screenWidth < 360 ? 24 : 28),
            SizedBox(height: screenWidth < 360 ? 6 : 8),
            Text(
              label,
              style: TextStyle(
                fontSize: screenWidth < 360 ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: theme.text,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showQRScanner() {
    final scaffoldContext = context;
    showDialog(
      context: context,
      builder:
          (dialogContext) => QRScannerWidget(
            onQRScanned: (qrData) async {
              try {
                final friend = Friend.fromQRString(qrData);
                await _service.addFriend(friend);
                if (context.mounted) {
                  setState(() {});
                  Navigator.pop(dialogContext);
                  SnackbarUtils.success(
                    scaffoldContext,
                    '${friend.name} added successfully!',
                  );
                }
              } catch (e) {
                Logger.e('AddFriends', 'Failed to add friend from QR', e);
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  SnackbarUtils.error(scaffoldContext, 'Invalid QR code');
                }
              }
            },
          ),
    );
  }

  void _importFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (dialogContext) =>
                  const Center(child: CircularProgressIndicator()),
        );

        try {
          final controller = MobileScannerController(
            formats: [BarcodeFormat.qrCode],
          );

          final capture = await controller.analyzeImage(image.path);
          await controller.dispose();

          if (!mounted) return;
          Navigator.pop(context);

          if (capture != null && capture.barcodes.isNotEmpty) {
            final qrData = capture.barcodes.first.rawValue;

            if (qrData != null && qrData.isNotEmpty) {
              try {
                final friend = Friend.fromQRString(qrData);
                await _service.addFriend(friend);

                if (!mounted) return;
                setState(() {});
                SnackbarUtils.success(
                  context,
                  '${friend.name} added from image!',
                );

                Logger.success(
                  'AddFriends',
                  'Friend imported from gallery: ${friend.name}',
                );
              } catch (e) {
                Logger.e('AddFriends', 'Failed to parse QR data from image', e);
                if (mounted) {
                  SnackbarUtils.error(context, 'Invalid QR code format');
                }
              }
            } else {
              if (mounted) {
                SnackbarUtils.warning(
                  context,
                  'QR code is empty or unreadable',
                );
              }
            }
          } else {
            if (mounted) {
              SnackbarUtils.warning(context, 'No QR code found in the image');
            }
          }
        } catch (e) {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          Logger.e('AddFriends', 'Failed to scan QR from image', e);
          if (mounted) {
            SnackbarUtils.error(context, 'Failed to scan QR code');
          }
        }
      }
    } catch (e) {
      Logger.e('AddFriends', 'Failed to import from gallery', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to access gallery');
      }
    }
  }

  void _importFromTextFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();

        try {
          String qrData = content;

          if (content.contains('--- QR Data ---')) {
            final lines = content.split('\n');
            bool inQRSection = false;
            final qrLines = <String>[];

            for (final line in lines) {
              if (line.trim() == '--- QR Data ---') {
                inQRSection = true;
                continue;
              }
              if (line.trim() == '--- Instructions ---') {
                break;
              }
              if (inQRSection && line.trim().isNotEmpty) {
                qrLines.add(line.trim());
              }
            }

            if (qrLines.isNotEmpty) {
              qrData = qrLines.join('');
            }
          }

          final friend = Friend.fromQRString(qrData);
          await _service.addFriend(friend);
          setState(() {});

          if (mounted) {
            SnackbarUtils.success(context, '${friend.name} added from file!');
          }

          Logger.success(
            'AddFriends',
            'Friend imported from text file: ${friend.name}',
          );
        } catch (e) {
          Logger.e('AddFriends', 'Failed to parse text file content', e);
          if (mounted) {
            SnackbarUtils.error(
              context,
              'Invalid file format or corrupted data',
            );
          }
        }
      }
    } catch (e) {
      Logger.e('AddFriends', 'Failed to import from text file', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to access text file');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: const Text('Manage Friends'),
        backgroundColor: theme.surface,
        foregroundColor: theme.text,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildAddOptions(theme, screenWidth),
                  Expanded(
                    child:
                        _service.friends.isEmpty
                            ? _buildEmptyState(theme, screenWidth)
                            : _buildFriendsList(theme, screenWidth),
                  ),
                ],
              ),
    );
  }

  Widget _buildEmptyState(dynamic theme, double screenWidth) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth < 360 ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_alt_outlined,
              size: screenWidth < 360 ? 60 : 80,
              color: theme.primary.withValues(alpha: 0.5),
            ),
            SizedBox(height: screenWidth < 360 ? 20 : 24),
            Text(
              'No Friends Added',
              style: TextStyle(
                fontSize: screenWidth < 360 ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
            SizedBox(height: screenWidth < 360 ? 8 : 12),
            Text(
              'Use options above to add your first friend',
              style: TextStyle(
                fontSize: screenWidth < 360 ? 14 : 16,
                color: theme.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(dynamic theme, double screenWidth) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth < 360 ? 12 : 16,
        vertical: screenWidth < 360 ? 12 : 16,
      ),
      itemCount: _service.friends.length,
      itemBuilder: (context, index) {
        final friend = _service.friends[index];

        return Container(
          margin: EdgeInsets.only(bottom: screenWidth < 360 ? 12 : 16),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.border.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: theme.muted.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(screenWidth < 360 ? 16 : 20),
            child: Column(
              children: [
                // Header Row: Avatar, Name, Delete
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: screenWidth < 360 ? 48 : 56,
                      height: screenWidth < 360 ? 48 : 56,
                      decoration: BoxDecoration(
                        color: friend.color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: friend.color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          friend.name.isNotEmpty
                              ? friend.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth < 360 ? 18 : 22,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth < 360 ? 16 : 20),

                    // Name and Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth < 360 ? 16 : 18,
                              color: theme.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            friend.regNumber,
                            style: TextStyle(
                              fontSize: screenWidth < 360 ? 13 : 14,
                              color: theme.muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Save and Delete Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Save Button
                        InkWell(
                          onTap: () => _saveTimetableToFile(friend),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.save_outlined,
                              color: Colors.blue.shade600,
                              size: screenWidth < 360 ? 18 : 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Delete Button
                        InkWell(
                          onTap: () => _removeFriend(friend),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade600,
                              size: screenWidth < 360 ? 18 : 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: screenWidth < 360 ? 16 : 20),

                // Nickname Section
                GestureDetector(
                  onTap: () => _updateNickname(friend),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth < 360 ? 10 : 12),
                    decoration: BoxDecoration(
                      color: friend.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: friend.color.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          color: friend.color,
                          size: screenWidth < 360 ? 16 : 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Nickname: ',
                          style: TextStyle(
                            fontSize: screenWidth < 360 ? 12 : 13,
                            color: theme.muted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            friend.nickname,
                            style: TextStyle(
                              fontSize: screenWidth < 360 ? 13 : 14,
                              color: friend.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: friend.color.withValues(alpha: 0.6),
                          size: 12,
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: screenWidth < 360 ? 12 : 16),

                // Total Classes - Horizontal Bar
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth < 360 ? 12 : 14,
                    vertical: screenWidth < 360 ? 8 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.primary.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Total Classes: ',
                        style: TextStyle(
                          fontSize: screenWidth < 360 ? 10 : 11,
                          color: theme.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${friend.classSlots.length}',
                        style: TextStyle(
                          fontSize: screenWidth < 360 ? 14 : 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenWidth < 360 ? 12 : 16),

                // Toggle Controls (Vertical)
                Column(
                  children: [
                    // Friends Schedule Toggle
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth < 360 ? 10 : 12,
                        vertical: screenWidth < 360 ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            friend.showInFriendsSchedule
                                ? friend.color.withValues(alpha: 0.08)
                                : theme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              friend.showInFriendsSchedule
                                  ? friend.color.withValues(alpha: 0.3)
                                  : theme.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Show in Friends Schedule',
                              style: TextStyle(
                                fontSize: screenWidth < 360 ? 10 : 11,
                                fontWeight: FontWeight.w600,
                                color:
                                    friend.showInFriendsSchedule
                                        ? friend.color
                                        : theme.muted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: friend.showInFriendsSchedule,
                              onChanged:
                                  (_) => _toggleFriendsScheduleVisibility(
                                    friend.id,
                                  ),
                              activeColor: friend.color,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Home Page Toggle
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth < 360 ? 10 : 12,
                        vertical: screenWidth < 360 ? 6 : 8,
                      ),
                      decoration: BoxDecoration(
                        color:
                            friend.showInHomePage
                                ? friend.color.withValues(alpha: 0.08)
                                : theme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              friend.showInHomePage
                                  ? friend.color.withValues(alpha: 0.3)
                                  : theme.border.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Show in Home Page',
                              style: TextStyle(
                                fontSize: screenWidth < 360 ? 10 : 11,
                                fontWeight: FontWeight.w600,
                                color:
                                    friend.showInHomePage
                                        ? friend.color
                                        : theme.muted,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Transform.scale(
                            scale: 0.7,
                            child: Switch(
                              value: friend.showInHomePage,
                              onChanged:
                                  (_) => _toggleHomePageVisibility(friend.id),
                              activeColor: friend.color,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
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
        );
      },
    );
  }
}
