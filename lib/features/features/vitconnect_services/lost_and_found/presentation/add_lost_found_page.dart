import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/database/entities/student_profile.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../data/lost_found_repository.dart';
import '../widgets/verified_info_card.dart';

/// Add Lost/Found item page
class AddLostFoundPage extends StatefulWidget {
  const AddLostFoundPage({super.key});

  @override
  State<AddLostFoundPage> createState() => _AddLostFoundPageState();
}

class _AddLostFoundPageState extends State<AddLostFoundPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = LostFoundRepository();
  final _picker = ImagePicker();

  String _selectedType = 'lost';
  final _itemNameController = TextEditingController();
  final _placeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactNumberController = TextEditingController();

  XFile? _selectedImage;
  bool _notifyAll = false;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;

  StudentProfile? _profile;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'AddLostFound',
      screenClass: 'AddLostFoundPage',
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _placeController.dispose();
    _descriptionController.dispose();
    _contactNameController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('student_profile');

      if (profileJson == null || profileJson.isEmpty) {
        if (mounted) {
          SnackbarUtils.error(
            context,
            'Student profile not found. Please re-login.',
          );
          Navigator.pop(context);
        }
        return;
      }

      final profile = StudentProfile.fromJson(jsonDecode(profileJson));
      setState(() {
        _profile = profile;
        _contactNameController.text = profile.name;
      });
    } catch (e) {
      Logger.e('AddLostFound', 'Error loading profile', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to load profile');
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    if (_profile == null) {
      return Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: const Text('Post Item'),
          backgroundColor: theme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(
          'Post Item',
          style: TextStyle(
            color: theme.text,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.text),
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type selector
              _buildTypeSelector(theme),

              // Verified info card
              VerifiedInfoCard(
                name: _profile!.name,
                regNumber: _profile!.registerNumber,
              ),

              // Form fields
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField(
                      controller: _itemNameController,
                      label: 'Item Name',
                      hint: 'e.g., ID Card, Wallet, Keys',
                      icon: Icons.inventory_2_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter item name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _placeController,
                      label: 'Place',
                      hint: 'e.g., Main Block, Library, Cafeteria',
                      icon: Icons.location_on_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter place';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description (Optional)',
                      hint: 'Additional details about the item',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _contactNameController,
                      label: 'Contact Name',
                      hint: 'Your name',
                      icon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter contact name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _contactNumberController,
                      label: 'Contact Number',
                      hint: 'Your phone number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter contact number';
                        }
                        if (value.trim().length < 10) {
                          return 'Please enter valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Image picker
                    _buildImagePicker(theme),
                    const SizedBox(height: 24),

                    // Notify all toggle
                    _buildNotifyToggle(theme),
                    const SizedBox(height: 24),

                    // Progress indicator (when uploading)
                    if (_isSubmitting) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.border),
                        ),
                        child: LinearProgressIndicator(
                          value: _uploadProgress,
                          backgroundColor: theme.border,
                          valueColor: AlwaysStoppedAnimation(theme.primary),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: theme.primary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        child:
                            _isSubmitting
                                ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Uploading...',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                                : const Text(
                                  'Post Item',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeChip(
              label: 'Lost',
              icon: Icons.help_outline,
              value: 'lost',
              color: Colors.red,
              theme: theme,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTypeChip(
              label: 'Found',
              icon: Icons.check_circle_outline,
              value: 'found',
              color: Colors.green,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required IconData icon,
    required String value,
    required Color color,
    required theme,
  }) {
    final isSelected = _selectedType == value;
    return InkWell(
      onTap: () => setState(() => _selectedType = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? color : theme.text.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : theme.text.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildImagePicker(theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Image (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.text.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
            ),
            child:
                _selectedImage == null
                    ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: theme.text.withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to add image',
                          style: TextStyle(
                            color: theme.text.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    )
                    : Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_selectedImage!.path),
                            width: double.infinity,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            onPressed:
                                () => setState(() => _selectedImage = null),
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotifyToggle(theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_outlined, color: theme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notify all users',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.text,
                  ),
                ),
                Text(
                  'Send notification to all VIT Verse users',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.text.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _notifyAll,
            onChanged: (value) => setState(() => _notifyAll = value),
            activeColor: theme.primary,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        // Check file size and compress if needed
        final compressedImage = await _compressImageIfNeeded(image);
        setState(() => _selectedImage = compressedImage);
      }
    } catch (e) {
      Logger.e('AddLostFound', 'Error picking image', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to pick image');
      }
    }
  }

  /// Compress image to under 1MB if needed
  Future<XFile> _compressImageIfNeeded(XFile imageFile) async {
    const int maxSizeBytes = 1024 * 1024; // 1MB
    final file = File(imageFile.path);
    int fileSize = await file.length();

    // If file is already under 1MB, return as is
    if (fileSize <= maxSizeBytes) {
      Logger.d('AddLostFound', 'Image size OK: ${fileSize ~/ 1024}KB');
      return imageFile;
    }

    Logger.d(
      'AddLostFound',
      'Compressing image from ${fileSize ~/ 1024}KB to under 1MB',
    );

    // Read and decode image
    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      Logger.w('AddLostFound', 'Failed to decode image');
      return imageFile;
    }

    // Compress with progressively lower quality until under 1MB
    int quality = 85;
    List<int>? compressedBytes;

    while (quality > 10) {
      compressedBytes = img.encodeJpg(image, quality: quality);

      if (compressedBytes.length <= maxSizeBytes) {
        break;
      }

      quality -= 10;
    }

    // If still too large, resize image
    if (compressedBytes != null && compressedBytes.length > maxSizeBytes) {
      Logger.d('AddLostFound', 'Resizing image for further compression');
      final resized = img.copyResize(
        image,
        width: image.width ~/ 2,
        height: image.height ~/ 2,
      );
      compressedBytes = img.encodeJpg(resized, quality: 75);
    }

    // Save compressed image
    if (compressedBytes != null) {
      final tempDir = await file.parent.createTemp('compressed_');
      final compressedFile = File('${tempDir.path}/compressed.jpg');
      await compressedFile.writeAsBytes(compressedBytes);

      final finalSize = compressedBytes.length;
      Logger.success(
        'AddLostFound',
        'Image compressed: ${fileSize ~/ 1024}KB → ${finalSize ~/ 1024}KB',
      );

      return XFile(compressedFile.path);
    }

    return imageFile;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });

    try {
      await _repository.addItem(
        type: _selectedType,
        itemName: _itemNameController.text.trim(),
        place: _placeController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        contactName: _contactNameController.text.trim(),
        contactNumber: _contactNumberController.text.trim(),
        postedByName: _profile!.name,
        postedByRegno: _profile!.registerNumber,
        imageFile: _selectedImage,
        notifyAll: _notifyAll,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      Logger.e('AddLostFound', 'Error submitting item', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to post item. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0.0;
        });
      }
    }
  }
}
