import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await _service.loadFriends();
      setState(() => _isLoading = false);
      Logger.success('AddFriends', 'Data loaded successfully');
    } catch (e) {
      Logger.e('AddFriends', 'Failed to load data', e);
      setState(() => _isLoading = false);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to load friends');
      }
    }
  }

  Future<void> _toggleFriendSelection(String friendId) async {
    try {
      await _service.toggleFriendSelection(friendId);
      setState(() {});
    } catch (e) {
      Logger.e('AddFriends', 'Failed to toggle friend selection', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to update friend selection');
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
        Logger.e('AddFriends', 'Failed to remove friend', e);
        if (mounted) {
          SnackbarUtils.error(context, 'Failed to remove friend');
        }
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
        border: Border.all(color: theme.border.withOpacity(0.3)),
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
          color: theme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.primary.withOpacity(0.3)),
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
    showDialog(
      context: context,
      builder:
          (context) => QRScannerWidget(
            onQRScanned: (qrData) async {
              try {
                final friend = Friend.fromQRString(qrData);
                await _service.addFriend(friend);
                setState(() {});
                Navigator.pop(context);
                if (mounted) {
                  SnackbarUtils.success(
                    context,
                    '${friend.name} added successfully!',
                  );
                }
              } catch (e) {
                Logger.e('AddFriends', 'Failed to add friend from QR', e);
                Navigator.pop(context);
                if (mounted) {
                  SnackbarUtils.error(context, 'Invalid QR code');
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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        try {
          final controller = MobileScannerController(
            formats: [BarcodeFormat.qrCode],
          );

          final capture = await controller.analyzeImage(image.path);
          await controller.dispose();

          if (mounted) Navigator.pop(context);

          if (capture != null && capture.barcodes.isNotEmpty) {
            final qrData = capture.barcodes.first.rawValue;

            if (qrData != null && qrData.isNotEmpty) {
              try {
                final friend = Friend.fromQRString(qrData);
                await _service.addFriend(friend);
                setState(() {});

                if (mounted) {
                  SnackbarUtils.success(
                    context,
                    '${friend.name} added from image!',
                  );
                }

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
              color: theme.primary.withOpacity(0.5),
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
        final isSelected = _service.selectedFriends.any(
          (f) => f.id == friend.id,
        );

        return Container(
          margin: EdgeInsets.only(bottom: screenWidth < 360 ? 8 : 12),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? friend.color.withOpacity(0.5) : theme.border,
            ),
          ),
          child: ListTile(
            leading: Container(
              width: screenWidth < 360 ? 36 : 40,
              height: screenWidth < 360 ? 36 : 40,
              decoration: BoxDecoration(
                color: friend.color,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth < 360 ? 14 : 16,
                  ),
                ),
              ),
            ),
            title: Text(
              friend.name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: screenWidth < 360 ? 14 : 15,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.regNumber,
                  style: TextStyle(fontSize: screenWidth < 360 ? 12 : 13),
                ),
                Text(
                  '${friend.classSlots.length} classes',
                  style: TextStyle(
                    fontSize: screenWidth < 360 ? 11 : 12,
                    color: theme.muted,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: isSelected,
                  onChanged: (_) => _toggleFriendSelection(friend.id),
                  activeColor: friend.color,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeFriend(friend),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
