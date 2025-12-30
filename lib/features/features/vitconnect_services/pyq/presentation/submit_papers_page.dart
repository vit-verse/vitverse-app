import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/theme/app_card_styles.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../core/database/entities/student_profile.dart';
import '../../../vtop_services/examination_schedule/data/examination_data_provider.dart';
import '../../lost_and_found/widgets/verified_info_card.dart';
import '../data/pyq_api.dart';

/// Submit Papers Page - allows students to upload PYQ papers
class SubmitPapersPage extends StatefulWidget {
  const SubmitPapersPage({super.key});

  @override
  State<SubmitPapersPage> createState() => _SubmitPapersPageState();
}

class _SubmitPapersPageState extends State<SubmitPapersPage> {
  static const _tag = 'SubmitPapersPage';

  final ExaminationDataProvider _examProvider = ExaminationDataProvider();

  Map<String, List<Map<String, dynamic>>> _examsByType = {};
  List<String> _examTypes = [];
  String? _selectedExamType;
  Map<String, dynamic>? _selectedExam;
  File? _selectedFile;
  List<File> _selectedImages = [];
  bool _isLoadingExams = true;
  bool _isUploading = false;
  String? _error;
  StudentProfile? _profile;

  // Additional metadata fields for filename
  List<String> _availableSemesters = [];
  String? _selectedSemester;
  final TextEditingController _facultyController = TextEditingController();
  final TextEditingController _classNoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSemesterData();
    _loadProfile();
  }

  @override
  void dispose() {
    _facultyController.dispose();
    _classNoController.dispose();
    super.dispose();
  }

  Future<void> _loadSemesterData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load available semesters from SharedPreferences
      final semestersJson = prefs.getString('available_semesters');
      if (semestersJson != null && semestersJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(semestersJson);
        setState(() {
          _availableSemesters = decoded.map((e) => e.toString()).toList();
        });
      }

      // Load currently selected semester
      final currentSemester = prefs.getString('semester');
      if (currentSemester != null &&
          _availableSemesters.contains(currentSemester)) {
        setState(() {
          _selectedSemester = currentSemester;
        });
      } else if (_availableSemesters.isNotEmpty) {
        setState(() {
          _selectedSemester = _availableSemesters.first;
        });
      }

      Logger.d(
        _tag,
        'Loaded ${_availableSemesters.length} semesters, selected: $_selectedSemester',
      );
    } catch (e) {
      Logger.e(_tag, 'Failed to load semester data', e);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('student_profile');

      if (profileJson == null || profileJson.isEmpty) {
        // Don't redirect, just set profile as null
        setState(() {
          _profile = null;
        });
        await _loadExams();
        return;
      }

      final profile = StudentProfile.fromJson(jsonDecode(profileJson));
      setState(() {
        _profile = profile;
      });

      await _loadExams();
    } catch (e) {
      Logger.e(_tag, 'Error loading profile', e);
      setState(() {
        _profile = null;
      });
      await _loadExams();
    }
  }

  Future<void> _loadExams() async {
    try {
      setState(() {
        _isLoadingExams = true;
        _error = null;
      });

      final examsByType = await _examProvider.getExamsByType();

      setState(() {
        _examsByType = examsByType;
        _examTypes = examsByType.keys.toList()..sort();
        _isLoadingExams = false;
      });

      Logger.i(_tag, 'Loaded ${_examTypes.length} exam types');

      // Auto-select most recent exam
      _autoSelectRecentExam();
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Failed to load exams', e, stackTrace);
      setState(() {
        _error = 'Failed to load exams. Please try again.';
        _isLoadingExams = false;
      });
    }
  }

  void _autoSelectRecentExam() {
    try {
      // Find the most recent exam across all types
      Map<String, dynamic>? mostRecentExam;
      int latestTimestamp = 0;
      String? recentExamType;

      for (final examType in _examsByType.keys) {
        final exams = _examsByType[examType] ?? [];
        for (final exam in exams) {
          final startTime = exam['start_time'] as int? ?? 0;
          if (startTime > latestTimestamp) {
            latestTimestamp = startTime;
            mostRecentExam = exam;
            recentExamType = examType;
          }
        }
      }

      if (mostRecentExam != null && recentExamType != null) {
        setState(() {
          _selectedExamType = recentExamType;
          _selectedExam = mostRecentExam;
        });
        _onExamSelected(mostRecentExam);
        Logger.d(_tag, 'Auto-selected recent exam: $recentExamType');
      }
    } catch (e) {
      Logger.w(_tag, 'Failed to auto-select recent exam');
    }
  }

  void _onExamSelected(Map<String, dynamic> exam) {
    setState(() {
      _selectedExam = exam;
    });

    // Auto-populate faculty and class number from course data
    final course = exam['course'] as Map<String, dynamic>?;
    if (course != null) {
      final faculty = course['faculty']?.toString() ?? '';
      final classId = course['class_id']?.toString() ?? '';

      // Always update the controllers when a course is selected
      if (faculty.isNotEmpty) {
        _facultyController.text = faculty;
      }
      if (classId.isNotEmpty) {
        _classNoController.text = classId;
      }
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSizeInBytes = await file.length();
        final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB >= 2) {
          if (mounted) {
            SnackbarUtils.error(
              context,
              'File size (${fileSizeInMB.toStringAsFixed(2)}MB) must be less than 2MB.',
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
          _selectedImages = [];
        });
      }
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error picking PDF', e, stackTrace);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to select PDF');
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((xFile) => File(xFile.path)).toList();
          _selectedFile = null;
        });
      }
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error picking images', e, stackTrace);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to select images');
      }
    }
  }

  Future<File?> _convertImagesToPdf() async {
    try {
      Logger.d(_tag, 'Converting ${_selectedImages.length} images to PDF');

      final pdf = pw.Document();

      for (int i = 0; i < _selectedImages.length; i++) {
        final imageFile = _selectedImages[i];
        final imageBytes = await imageFile.readAsBytes();

        // Decode image to ensure it's valid
        final decodedImage = img.decodeImage(imageBytes);
        if (decodedImage == null) {
          Logger.w(_tag, 'Failed to decode image ${i + 1}');
          continue;
        }

        // Compress image for OCR-friendly quality (85% quality)
        // Resize if too large while maintaining aspect ratio
        img.Image processedImage = decodedImage;

        // Max dimensions for A4 at 300 DPI (OCR-friendly)
        const maxWidth = 2480; // A4 width at 300 DPI
        const maxHeight = 3508; // A4 height at 300 DPI

        if (decodedImage.width > maxWidth || decodedImage.height > maxHeight) {
          final widthRatio = maxWidth / decodedImage.width;
          final heightRatio = maxHeight / decodedImage.height;
          final ratio = widthRatio < heightRatio ? widthRatio : heightRatio;

          final newWidth = (decodedImage.width * ratio).round();
          final newHeight = (decodedImage.height * ratio).round();

          processedImage = img.copyResize(
            decodedImage,
            width: newWidth,
            height: newHeight,
            interpolation: img.Interpolation.linear,
          );
        }

        // Encode with high quality JPEG (85%) for OCR-friendly compression
        final compressedBytes = img.encodeJpg(processedImage, quality: 85);
        final image = pw.MemoryImage(compressedBytes);

        // Get image dimensions to determine page orientation
        final imgWidth = processedImage.width;
        final imgHeight = processedImage.height;
        final isLandscape = imgWidth > imgHeight;

        pdf.addPage(
          pw.Page(
            pageFormat:
                isLandscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
            build:
                (context) => pw.Image(
                  image,
                  fit: pw.BoxFit.contain,
                  alignment: pw.Alignment.center,
                ),
          ),
        );

        // Update progress if mounted
        if (mounted) {
          setState(() {});
        }
      }

      final tempDir = await getTemporaryDirectory();
      final pdfFile = File(
        '${tempDir.path}/pyq_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await pdfFile.writeAsBytes(await pdf.save());

      // Check file size
      final fileSizeInBytes = await pdfFile.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      Logger.i(
        _tag,
        'PDF created: ${pdfFile.path}, Size: ${fileSizeInMB.toStringAsFixed(2)}MB',
      );

      // Validate size is under 2MB
      if (fileSizeInMB >= 2.0) {
        await pdfFile.delete();
        if (mounted) {
          SnackbarUtils.error(
            context,
            'PDF size (${fileSizeInMB.toStringAsFixed(2)}MB) exceeds 2MB limit. Please use fewer/smaller images.',
          );
        }
        return null;
      }

      return pdfFile;
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error converting images to PDF', e, stackTrace);
      return null;
    }
  }

  Future<void> _uploadPaper() async {
    if (_profile == null) {
      SnackbarUtils.error(
        context,
        'Please verify your profile before uploading',
      );
      return;
    }

    if (_selectedExam == null) {
      SnackbarUtils.warning(context, 'Please select an exam and course');
      return;
    }

    if (_selectedFile == null && _selectedImages.isEmpty) {
      SnackbarUtils.warning(context, 'Please select a PDF or images');
      return;
    }

    try {
      setState(() => _isUploading = true);

      File? fileToUpload = _selectedFile;

      // Convert images to PDF if needed
      if (_selectedImages.isNotEmpty && _selectedFile == null) {
        if (mounted) {
          SnackbarUtils.info(context, 'Converting images to PDF...');
        }
        fileToUpload = await _convertImagesToPdf();

        if (fileToUpload == null) {
          if (mounted) {
            SnackbarUtils.error(context, 'Failed to convert images to PDF');
          }
          setState(() => _isUploading = false);
          return;
        }

        if (mounted) {
          SnackbarUtils.success(context, 'Conversion complete!');
        }
      }

      if (fileToUpload == null) {
        if (mounted) {
          SnackbarUtils.error(context, 'No file to upload');
        }
        setState(() => _isUploading = false);
        return;
      }

      // Get course details
      final course = _selectedExam!['course'] as Map<String, dynamic>?;
      final courseCode = course?['code']?.toString() ?? '';
      final courseTitle = course?['title']?.toString() ?? '';
      final faculty = course?['faculty']?.toString() ?? '';
      final classNo = course?['class_id']?.toString() ?? '';
      final slots = _selectedExam!['slots'] as List<dynamic>? ?? [];
      final examType = _selectedExamType ?? 'Other';
      final startTime = _selectedExam!['start_time'] as int?;
      final examDate =
          startTime != null
              ? DateTime.fromMillisecondsSinceEpoch(startTime)
              : DateTime.now();

      // Validate required fields
      if (_selectedSemester == null || _selectedSemester!.isEmpty) {
        SnackbarUtils.warning(context, 'Please select a semester');
        setState(() => _isUploading = false);
        return;
      }
      if (faculty.isEmpty) {
        SnackbarUtils.warning(context, 'Faculty information missing');
        setState(() => _isUploading = false);
        return;
      }
      if (classNo.isEmpty) {
        SnackbarUtils.warning(context, 'Class number missing');
        setState(() => _isUploading = false);
        return;
      }

      // Generate proper filename with metadata
      // Format: <courseCode>-<courseTitle>-<exam>-<slot>-<semester>-<faculty>-<classNo>-<examDate>.pdf
      final sanitizedCourseCode = _sanitize(courseCode);
      final sanitizedCourseTitle = _sanitize(courseTitle);
      final sanitizedExam = _sanitize(examType);
      final sanitizedSlot =
          slots.isNotEmpty ? _sanitize(slots.join('+')) : 'NA';
      final sanitizedSemester = _sanitize(_selectedSemester ?? 'NA');
      final sanitizedFaculty = _sanitize(faculty.split(',')[0].trim());
      final sanitizedClassNo = _sanitize(classNo.split(',')[0].trim());
      final dateStr =
          '${examDate.year.toString().padLeft(4, '0')}-${examDate.month.toString().padLeft(2, '0')}-${examDate.day.toString().padLeft(2, '0')}';
      final newFilename =
          '$sanitizedCourseCode-$sanitizedCourseTitle-$sanitizedExam-$sanitizedSlot-$sanitizedSemester-$sanitizedFaculty-$sanitizedClassNo-$dateStr.pdf';

      final result = await PyqApi.uploadPaper(
        file: fileToUpload,
        courseCode: courseCode,
        courseTitle: courseTitle,
        examType: examType,
        examDate: dateStr,
        slot: slots.isNotEmpty ? slots.join('+') : 'NA',
        semester: _selectedSemester ?? 'NA',
        faculty: faculty,
        classNo: classNo,
      );

      setState(() => _isUploading = false);

      if (mounted) {
        if (result['success'] == true) {
          SnackbarUtils.success(
            context,
            'Paper uploaded successfully! It will be available after review.',
          );
          _resetForm();
        } else {
          SnackbarUtils.error(context, result['message'] ?? 'Upload failed');
        }
      }
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Error uploading paper', e, stackTrace);
      setState(() => _isUploading = false);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to upload paper');
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedExamType = null;
      _selectedExam = null;
      _selectedFile = null;
      _selectedImages = [];
      _facultyController.clear();
      _classNoController.clear();
      // Don't clear _selectedSemester - keep it for next upload
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// Sanitize field value for filename (remove spaces and special chars)
  String _sanitize(String value) {
    return value
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9+_.\-]'), '');
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _selectedImages.removeAt(oldIndex);
      _selectedImages.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoadingExams) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: themeProvider.currentTheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(color: themeProvider.currentTheme.muted),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: themeProvider.currentTheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: themeProvider.currentTheme.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => _error = null);
                _loadProfile();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_examTypes.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(themeProvider),
            const SizedBox(height: 16),
            if (_profile != null) ...[
              VerifiedInfoCard(
                name: _profile!.name,
                regNumber: _profile!.registerNumber,
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.school_outlined,
                      size: 48,
                      color: themeProvider.currentTheme.muted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No examinations schedule found',
                      style: TextStyle(color: themeProvider.currentTheme.muted),
                    ),
                  ],
                ),
              ),
            ] else
              _buildNotVerifiedCard(themeProvider),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoCard(themeProvider),
          const SizedBox(height: 16),
          // Show verification status
          if (_profile != null)
            VerifiedInfoCard(
              name: _profile!.name,
              regNumber: _profile!.registerNumber,
            )
          else
            _buildNotVerifiedCard(themeProvider),
          const SizedBox(height: 16),
          _buildExamTypeSelector(themeProvider),
          if (_selectedExamType != null) ...[
            const SizedBox(height: 16),
            _buildCourseSelector(themeProvider),
          ],
          if (_selectedExam != null && _profile != null) ...[
            const SizedBox(height: 16),
            _buildExamDetails(themeProvider),
            const SizedBox(height: 16),
            _buildMetadataFields(themeProvider),
            const SizedBox(height: 16),
            _buildFileSelector(themeProvider),
          ],
          if ((_selectedFile != null || _selectedImages.isNotEmpty) &&
              _profile != null) ...[
            const SizedBox(height: 16),
            _buildFilePreview(themeProvider),
            const SizedBox(height: 24),
            _buildUploadButton(themeProvider),
          ],
        ],
      ),
    );
  }

  Widget _buildNotVerifiedCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.error.withOpacity(
          0.1,
        ),
        customBorderColor: themeProvider.currentTheme.error.withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_outlined,
            color: themeProvider.currentTheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Not Verified',
                  style: TextStyle(
                    color: themeProvider.currentTheme.error,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please login to verify your student profile',
                  style: TextStyle(
                    color: themeProvider.currentTheme.muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.surface,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: themeProvider.currentTheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select an exam and course, then upload a PDF (max 2MB) or images to convert',
              style: TextStyle(
                color: themeProvider.currentTheme.text,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamTypeSelector(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Exam Type',
            style: TextStyle(
              color: themeProvider.currentTheme.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _examTypes.map((examType) {
                  final isSelected = _selectedExamType == examType;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedExamType = examType;
                        _selectedExam = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? themeProvider.currentTheme.primary
                                : themeProvider.currentTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              isSelected
                                  ? themeProvider.currentTheme.primary
                                  : themeProvider.currentTheme.border,
                        ),
                      ),
                      child: Text(
                        examType,
                        style: TextStyle(
                          color:
                              isSelected
                                  ? Colors.white
                                  : themeProvider.currentTheme.text,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseSelector(ThemeProvider themeProvider) {
    final exams = _examsByType[_selectedExamType] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Course',
            style: TextStyle(
              color: themeProvider.currentTheme.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...exams.map((exam) {
            final course = exam['course'] as Map<String, dynamic>?;
            final courseCode = course?['code']?.toString() ?? 'N/A';
            final courseTitle = course?['title']?.toString() ?? 'Unknown';
            final isSelected = _selectedExam == exam;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _onExamSelected(exam),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? themeProvider.currentTheme.primary.withOpacity(
                              0.1,
                            )
                            : themeProvider.currentTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isSelected
                              ? themeProvider.currentTheme.primary
                              : themeProvider.currentTheme.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: themeProvider.currentTheme.primary.withOpacity(
                            0.15,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          courseCode,
                          style: TextStyle(
                            color: themeProvider.currentTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          courseTitle,
                          style: TextStyle(
                            color: themeProvider.currentTheme.text,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: themeProvider.currentTheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildExamDetails(ThemeProvider themeProvider) {
    final course = _selectedExam!['course'] as Map<String, dynamic>?;
    final courseCode = course?['code']?.toString() ?? 'N/A';
    final courseTitle = course?['title']?.toString() ?? 'N/A';
    final faculty =
        _facultyController.text.isNotEmpty
            ? _facultyController.text
            : course?['faculty']?.toString() ?? 'N/A';
    final classNo =
        _classNoController.text.isNotEmpty
            ? _classNoController.text
            : course?['class_id']?.toString() ?? 'N/A';
    final slots = _selectedExam!['slots'] as List<dynamic>? ?? [];
    final startTime = _selectedExam!['start_time'] as int?;
    final examDate = startTime != null ? _formatDate(startTime) : 'N/A';

    // Generate filename preview with proper format and sanitization
    // Format: <courseCode>-<courseTitle>-<exam>-<slot>-<semester>-<faculty>-<classNo>-<examDate>.pdf
    final sanitizedCourseCode = _sanitize(courseCode);
    final sanitizedCourseTitle = _sanitize(courseTitle);
    final sanitizedExam = _sanitize(_selectedExamType ?? 'Other');
    final sanitizedSlot = slots.isNotEmpty ? _sanitize(slots.join('+')) : 'NA';
    final sanitizedSemester = _sanitize(_selectedSemester ?? 'NA');
    final sanitizedFaculty = _sanitize(faculty.split(',')[0].trim());
    final sanitizedClassNo = _sanitize(classNo.split(',')[0].trim());
    final dateStr =
        startTime != null
            ? (() {
              final date = DateTime.fromMillisecondsSinceEpoch(startTime);
              return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            })()
            : 'NA';
    final filename =
        '$sanitizedCourseCode-$sanitizedCourseTitle-$sanitizedExam-$sanitizedSlot-$sanitizedSemester-$sanitizedFaculty-$sanitizedClassNo-$dateStr.pdf';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: themeProvider.currentTheme.success,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Selected Details',
                style: TextStyle(
                  color: themeProvider.currentTheme.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Exam Type', _selectedExamType!, themeProvider),
          _buildDetailRow('Course Code', courseCode, themeProvider),
          _buildDetailRow('Course Title', courseTitle, themeProvider),
          if (slots.isNotEmpty)
            _buildDetailRow('Slot', slots.join(', '), themeProvider),
          _buildDetailRow('Exam Date', examDate, themeProvider),
          _buildDetailRow('Faculty', faculty, themeProvider),
          _buildDetailRow('Class Number', classNo, themeProvider),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeProvider.currentTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: themeProvider.currentTheme.border,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.drive_file_rename_outline,
                  size: 14,
                  color: themeProvider.currentTheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Filename: $filename',
                    style: TextStyle(
                      color: themeProvider.currentTheme.text,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    ThemeProvider themeProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                color: themeProvider.currentTheme.muted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: themeProvider.currentTheme.text,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSelector(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload File',
            style: TextStyle(
              color: themeProvider.currentTheme.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Select PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.currentTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.image),
                  label: const Text('Select Images'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: themeProvider.currentTheme.primary,
                    side: BorderSide(color: themeProvider.currentTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataFields(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppCardStyles.compactCardDecoration(
        isDark: themeProvider.currentTheme.isDark,
        customBackgroundColor: themeProvider.currentTheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Semester',
            style: TextStyle(
              color: themeProvider.currentTheme.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedSemester,
            decoration: InputDecoration(
              labelText: 'Semester',
              prefixIcon: const Icon(Icons.calendar_today, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            style: TextStyle(
              color: themeProvider.currentTheme.text,
              fontSize: 14,
            ),
            dropdownColor: themeProvider.currentTheme.surface,
            items:
                _availableSemesters.isEmpty
                    ? [
                      DropdownMenuItem(
                        value: 'No semesters available',
                        child: Text(
                          'No semesters available',
                          style: TextStyle(
                            color: themeProvider.currentTheme.muted,
                          ),
                        ),
                      ),
                    ]
                    : _availableSemesters.map((semester) {
                      return DropdownMenuItem<String>(
                        value: semester,
                        child: Text(semester),
                      );
                    }).toList(),
            onChanged:
                _availableSemesters.isEmpty
                    ? null
                    : (value) {
                      setState(() {
                        _selectedSemester = value;
                      });
                    },
            hint: Text(
              'Select semester',
              style: TextStyle(color: themeProvider.currentTheme.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(ThemeProvider themeProvider) {
    if (_selectedFile != null) {
      final fileSizeBytes = _selectedFile!.lengthSync();
      final fileSizeMB = (fileSizeBytes / (1024 * 1024)).toStringAsFixed(2);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: AppCardStyles.compactCardDecoration(
          isDark: themeProvider.currentTheme.isDark,
          customBackgroundColor: themeProvider.currentTheme.surface,
        ),
        child: Row(
          children: [
            Icon(
              Icons.picture_as_pdf,
              color: themeProvider.currentTheme.primary,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedFile!.path.split('/').last,
                    style: TextStyle(
                      color: themeProvider.currentTheme.text,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'PDF • $fileSizeMB MB',
                    style: TextStyle(
                      color: themeProvider.currentTheme.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _selectedFile = null),
              icon: Icon(Icons.close, color: themeProvider.currentTheme.error),
            ),
          ],
        ),
      );
    }

    if (_selectedImages.isNotEmpty) {
      int totalBytes = 0;
      for (final image in _selectedImages) {
        totalBytes += image.lengthSync();
      }
      final totalSizeMB = (totalBytes / (1024 * 1024)).toStringAsFixed(2);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: AppCardStyles.compactCardDecoration(
          isDark: themeProvider.currentTheme.isDark,
          customBackgroundColor: themeProvider.currentTheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedImages.length} images selected',
                      style: TextStyle(
                        color: themeProvider.currentTheme.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Total size: $totalSizeMB MB',
                      style: TextStyle(
                        color: themeProvider.currentTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Drag to reorder',
                  style: TextStyle(
                    color: themeProvider.currentTheme.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ReorderableListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                onReorder: _reorderImages,
                itemBuilder: (context, index) {
                  return Container(
                    key: ValueKey(_selectedImages[index].path),
                    margin: const EdgeInsets.only(right: 8),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _selectedImages[index],
                            width: 80,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: themeProvider.currentTheme.error,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildUploadButton(ThemeProvider themeProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _uploadPaper,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeProvider.currentTheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          disabledBackgroundColor: themeProvider.currentTheme.muted.withOpacity(
            0.3,
          ),
        ),
        child:
            _isUploading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Text(
                  'Upload Paper',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }
}
