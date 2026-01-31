import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/config/env_config.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/database/entities/student_profile.dart';
import '../../../../../core/database_vitverse/database.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../supabase/core/supabase_events_client.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../data/events_repository.dart';
import '../data/events_vitverse_service.dart';
import '../models/event_model.dart';

class PostEventPage extends StatefulWidget {
  const PostEventPage({super.key});

  @override
  State<PostEventPage> createState() => _PostEventPageState();
}

class _PostEventPageState extends State<PostEventPage> {
  final _formKey = GlobalKey<FormState>();
  late final EventsRepository _repository;
  final _picker = ImagePicker();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _teamSizeController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _eventLinkController = TextEditingController();

  String _selectedCategory = 'Technical';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  XFile? _selectedImage;
  String? _selectedImageSize;
  bool _notifyAll = false;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;

  StudentProfile? _profile;

  final List<String> _categories = [
    'Technical',
    'Cultural',
    'Sports',
    'Workshop',
    'Seminar',
    'Competition',
    'Social',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'PostEvent',
      screenClass: 'PostEventPage',
    );
    _repository = EventsRepository(
      SupabaseEventsClient.client,
      EventsVitverseService(VitVerseDatabase.instance),
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _entryFeeController.dispose();
    _teamSizeController.dispose();
    _contactInfoController.dispose();
    _eventLinkController.dispose();
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

      final jsonMap = jsonDecode(profileJson) as Map<String, dynamic>;
      setState(() => _profile = StudentProfile.fromJson(jsonMap));
      _contactInfoController.text = _profile!.vitEmail;
    } catch (e) {
      Logger.e('PostEvent', 'Error loading profile', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to load profile');
        Navigator.pop(context);
      }
    }
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
        final compressedImage = await _compressImageIfNeeded(image);
        final file = File(compressedImage.path);
        final sizeInBytes = await file.length();
        final sizeInKB = (sizeInBytes / 1024).toStringAsFixed(2);
        setState(() {
          _selectedImage = compressedImage;
          _selectedImageSize = '$sizeInKB KB';
        });
      }
    } catch (e) {
      Logger.e('PostEvent', 'Error picking image', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to pick image');
      }
    }
  }

  Future<XFile> _compressImageIfNeeded(XFile imageFile) async {
    const int maxSizeBytes = 1024 * 1024;
    final file = File(imageFile.path);
    int fileSize = await file.length();

    if (fileSize <= maxSizeBytes) {
      Logger.d('PostEvent', 'Image size OK: ${fileSize ~/ 1024}KB');
      return imageFile;
    }

    Logger.d('PostEvent', 'Compressing image from ${fileSize ~/ 1024}KB');

    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/compressed_event_${DateTime.now().millisecondsSinceEpoch}.webp';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 1080,
      format: CompressFormat.webp,
    );

    if (compressed == null) {
      Logger.w('PostEvent', 'Compression failed, using original');
      return imageFile;
    }

    final compressedSize = await File(compressed.path).length();
    Logger.success(
      'PostEvent',
      'Compressed: ${fileSize ~/ 1024}KB → ${compressedSize ~/ 1024}KB',
    );

    return compressed;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      SnackbarUtils.error(context, 'Please select event date');
      return;
    }

    if (_profile == null) {
      SnackbarUtils.error(context, 'Profile not loaded. Please try again.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });

    try {
      final eventDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
      );

      String? posterUrl;

      if (_selectedImage != null) {
        setState(() => _uploadProgress = 0.3);
        posterUrl = await _uploadPoster();
      }

      setState(() => _uploadProgress = 0.7);

      final event = Event(
        id: '',
        source: 'user',
        userId: _profile!.registerNumber,
        userNameRegno: '${_profile!.name} (${_profile!.registerNumber})',
        userEmail: _profile!.vitEmail,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        venue: _venueController.text.trim(),
        category: _selectedCategory,
        eventDate: eventDateTime,
        entryFee:
            _entryFeeController.text.trim().isEmpty
                ? 0
                : int.tryParse(_entryFeeController.text.trim()) ?? 0,
        teamSize:
            _teamSizeController.text.trim().isEmpty
                ? '1'
                : _teamSizeController.text.trim(),
        posterUrl: posterUrl,
        contactInfo: _contactInfoController.text.trim(),
        eventLink:
            _eventLinkController.text.trim().isEmpty
                ? null
                : _eventLinkController.text.trim(),
        likesCount: 0,
        commentsCount: 0,
        isLikedByMe: false,
      );

      await _repository.createEvent(event);

      setState(() => _uploadProgress = 0.9);

      if (_notifyAll) {
        await _sendEventNotification(event);
      }

      setState(() => _uploadProgress = 1.0);

      if (mounted) {
        SnackbarUtils.success(context, 'Event posted successfully!');
        Navigator.pop(context, true);
      }
    } catch (e) {
      Logger.e('PostEvent', 'Error submitting event', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to post event');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _sendEventNotification(Event event) async {
    try {
      final url = Uri.parse(
        'https://us-central1-vit-connect-app.cloudfunctions.net/sendEventNotification',
      );

      final notificationTitle =
          event.title.trim().isEmpty
              ? 'New Event'
              : '${event.title} | ${event.category.isEmpty ? 'General' : event.category}';

      final notificationMessage =
          '📅 ${event.formattedDate} | 📍 ${event.venue.isEmpty ? 'TBA' : event.venue}';

      final eventId =
          event.id.trim().isEmpty
              ? 'event_${DateTime.now().millisecondsSinceEpoch}'
              : event.id;

      final description =
          event.description.trim().isEmpty
              ? 'No description available'
              : event.description;

      Logger.d(
        'PostEvent',
        'Sending notification: title=$notificationTitle, message=$notificationMessage, eventId=$eventId',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'x-secret-header': EnvConfig.eventsSecretHeader,
        },
        body: jsonEncode({
          'title': notificationTitle,
          'message': notificationMessage,
          'eventId': eventId,
          'description': description,
          'category': event.category.isEmpty ? 'General' : event.category,
          'venue': event.venue.isEmpty ? 'TBA' : event.venue,
          'date': event.formattedDate,
          'eventLink': event.eventLink ?? '',
          'participantType': event.participantType,
          'entryFee': event.entryFee,
          'teamSize': event.teamSize,
        }),
      );

      if (response.statusCode == 200) {
        Logger.success('PostEvent', 'FCM notification sent successfully');
      } else {
        Logger.e(
          'PostEvent',
          'FCM notification failed: ${response.statusCode} - ${response.body}',
        );
        Logger.d(
          'PostEvent',
          'Sent payload: title=$notificationTitle, message=$notificationMessage, eventId=$eventId, description=$description',
        );
      }
    } catch (e, stack) {
      Logger.e('PostEvent', 'Error sending FCM notification', e, stack);
    }
  }

  Future<String> _uploadPoster() async {
    if (_selectedImage == null || _profile == null) {
      throw Exception('No image or profile');
    }

    try {
      final file = File(_selectedImage!.path);
      final extension = _selectedImage!.path.split('.').last;

      final sanitizedTitle = _titleController.text.trim().replaceAll(
        RegExp(r'[^a-zA-Z0-9]'),
        '_',
      );
      final finalTitle =
          sanitizedTitle.isEmpty
              ? 'event'
              : (sanitizedTitle.length > 30
                  ? sanitizedTitle.substring(0, 30)
                  : sanitizedTitle);

      final sanitizedName = _profile!.name.replaceAll(
        RegExp(r'[^a-zA-Z0-9]'),
        '_',
      );
      final finalName =
          sanitizedName.isEmpty
              ? 'user'
              : (sanitizedName.length > 20
                  ? sanitizedName.substring(0, 20)
                  : sanitizedName);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${finalTitle}_$timestamp.$extension';
      final folderPath = '${_profile!.registerNumber}_$finalName';
      final filePath = 'events/user-events/$folderPath/$fileName';

      await SupabaseEventsClient.client.storage
          .from('events')
          .uploadBinary(filePath, await file.readAsBytes());

      final publicUrl = SupabaseEventsClient.client.storage
          .from('events')
          .getPublicUrl(filePath);

      Logger.success('PostEvent', 'Poster uploaded: $filePath');
      return publicUrl;
    } catch (e) {
      Logger.e('PostEvent', 'Error uploading poster', e);
      throw Exception('Failed to upload poster');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = themeProvider.currentTheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeProvider.systemOverlayStyle,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: const Text('Post Event'),
          backgroundColor: theme.surface,
        ),
        body:
            _profile == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                  children: [
                    Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildVerifiedInfoCard(theme),
                          const SizedBox(height: 20),
                          _buildImagePicker(theme),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _titleController,
                            label: 'Event Title',
                            hint: 'Enter event name',
                            icon: Icons.title,
                            theme: theme,
                            validator:
                                (val) =>
                                    val == null || val.trim().isEmpty
                                        ? 'Required'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Description',
                            hint:
                                'Describe your event (include time details here)',
                            icon: Icons.description,
                            theme: theme,
                            maxLines: 4,
                            validator:
                                (val) =>
                                    val == null || val.trim().isEmpty
                                        ? 'Required'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          _buildCategoryDropdown(theme),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _venueController,
                            label: 'Venue',
                            hint: 'Event location',
                            icon: Icons.location_on,
                            theme: theme,
                            validator:
                                (val) =>
                                    val == null || val.trim().isEmpty
                                        ? 'Required'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          _buildDatePicker(theme),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTextField(
                                  controller: _entryFeeController,
                                  label: 'Entry Fee',
                                  hint: 'Free/₹100',
                                  icon: Icons.currency_rupee,
                                  theme: theme,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTextField(
                                  controller: _teamSizeController,
                                  label: 'Team Size',
                                  hint: '1-5',
                                  icon: Icons.group,
                                  theme: theme,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _contactInfoController,
                            label: 'Contact Info',
                            hint: 'Email/Phone',
                            icon: Icons.contact_mail,
                            theme: theme,
                            validator:
                                (val) =>
                                    val == null || val.trim().isEmpty
                                        ? 'Required'
                                        : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _eventLinkController,
                            label: 'Event Link (Optional)',
                            hint: 'https://...',
                            icon: Icons.link,
                            theme: theme,
                          ),
                          const SizedBox(height: 24),
                          _buildNotifyToggle(theme),
                          const SizedBox(height: 24),
                          _buildSubmitButton(theme),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                    if (_isSubmitting) _buildLoadingOverlay(theme),
                  ],
                ),
      ),
    );
  }

  Widget _buildVerifiedInfoCard(theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user, color: theme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile?.name ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.text,
                  ),
                ),
                Text(
                  _profile?.registerNumber ?? '',
                  style: TextStyle(fontSize: 14, color: theme.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(theme) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
        ),
        child:
            _selectedImage == null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 48,
                      color: theme.muted,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add Event Poster (Optional)',
                      style: TextStyle(color: theme.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Max 1MB',
                      style: TextStyle(fontSize: 12, color: theme.muted),
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
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.image,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _selectedImageSize ?? 'Unknown size',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap:
                            () => setState(() {
                              _selectedImage = null;
                              _selectedImageSize = null;
                            }),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
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
    required theme,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: theme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: theme.surface,
      ),
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown(theme) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category, color: theme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: theme.surface,
      ),
      items:
          _categories
              .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
              .toList(),
      onChanged: (val) => setState(() => _selectedCategory = val!),
    );
  }

  Widget _buildDatePicker(theme) {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: theme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDate == null
                    ? 'Select Date'
                    : DateFormat('dd MMM yyyy').format(_selectedDate!),
                style: TextStyle(
                  color: _selectedDate == null ? theme.muted : theme.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(theme) {
    return GestureDetector(
      onTap: _selectTime,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: theme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedTime == null
                    ? 'Select Time'
                    : _selectedTime!.format(context),
                style: TextStyle(
                  color: _selectedTime == null ? theme.muted : theme.text,
                ),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildSubmitButton(theme) {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitEvent,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.primary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        'Post Event',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(theme) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 16),
              Text(
                'Posting event...',
                style: TextStyle(color: theme.text, fontSize: 16),
              ),
              Text(
                '${(_uploadProgress * 100).toInt()}%',
                style: TextStyle(color: theme.muted, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
