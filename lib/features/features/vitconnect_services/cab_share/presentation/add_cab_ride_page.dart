import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/database/entities/student_profile.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../config/cab_share_config.dart';
import '../data/cab_ride_repository.dart';
import '../widgets/cab_verified_info_card.dart';

/// Add Cab Ride page
class AddCabRidePage extends StatefulWidget {
  const AddCabRidePage({super.key});

  @override
  State<AddCabRidePage> createState() => _AddCabRidePageState();
}

class _AddCabRidePageState extends State<AddCabRidePage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = CabRideRepository();

  String _fromLocation = CabShareConfig.predefinedLocations[0];
  String _toLocation = CabShareConfig.predefinedLocations[1];
  bool _fromIsCustom = false;
  bool _toIsCustom = false;

  final _fromCustomController = TextEditingController();
  final _toCustomController = TextEditingController();
  final _cabTypeController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _travelDate;
  TimeOfDay? _travelTime;
  int _seatsAvailable = 1;
  bool _notifyAll = false;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;

  StudentProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _fromCustomController.dispose();
    _toCustomController.dispose();
    _cabTypeController.dispose();
    _contactNumberController.dispose();
    _descriptionController.dispose();
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
      });
    } catch (e) {
      Logger.e('AddCabRide', 'Error loading profile', e);
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
          title: const Text('Post Ride'),
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
          'Post Ride',
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
              // Verified info card
              CabVerifiedInfoCard(
                name: _profile!.name,
                regNumber: _profile!.registerNumber,
              ),

              // Form fields
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // From Location
                    Text(
                      'From Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLocationSelector(
                      value: _fromLocation,
                      customController: _fromCustomController,
                      isCustom: _fromIsCustom,
                      icon: Icons.trip_origin,
                      iconColor: theme.success,
                      onChanged: (value) {
                        setState(() {
                          _fromLocation = value;
                          _fromIsCustom = value == 'Other';
                        });
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),

                    // To Location
                    Text(
                      'To Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildLocationSelector(
                      value: _toLocation,
                      customController: _toCustomController,
                      isCustom: _toIsCustom,
                      icon: Icons.location_on,
                      iconColor: theme.error,
                      onChanged: (value) {
                        setState(() {
                          _toLocation = value;
                          _toIsCustom = value == 'Other';
                        });
                      },
                      theme: theme,
                    ),
                    const SizedBox(height: 16),

                    // Travel Date
                    Text(
                      'Travel Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
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
                            Icon(Icons.calendar_today, color: theme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _travelDate != null
                                    ? '${_travelDate!.day}/${_travelDate!.month}/${_travelDate!.year}'
                                    : 'Select travel date',
                                style: TextStyle(
                                  color:
                                      _travelDate != null
                                          ? theme.text
                                          : theme.muted,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: theme.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Travel Time
                    Text(
                      'Travel Time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
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
                            Icon(Icons.access_time, color: theme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _travelTime != null
                                    ? _travelTime!.format(context)
                                    : 'Select travel time',
                                style: TextStyle(
                                  color:
                                      _travelTime != null
                                          ? theme.text
                                          : theme.muted,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: theme.muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Cab Type
                    TextFormField(
                      controller: _cabTypeController,
                      decoration: InputDecoration(
                        labelText: 'Cab Type',
                        hintText: 'e.g., Sedan, SUV, Mini, Auto, or any other',
                        prefixIcon: const Icon(Icons.directions_car_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter cab type';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Seats Available
                    Text(
                      'Seats Available',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.border),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed:
                                _seatsAvailable > CabShareConfig.minSeats
                                    ? () => setState(() => _seatsAvailable--)
                                    : null,
                            icon: const Icon(Icons.remove),
                            color: theme.primary,
                          ),
                          Expanded(
                            child: Text(
                              '$_seatsAvailable ${_seatsAvailable == 1 ? 'seat' : 'seats'}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.text,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed:
                                _seatsAvailable < CabShareConfig.maxSeats
                                    ? () => setState(() => _seatsAvailable++)
                                    : null,
                            icon: const Icon(Icons.add),
                            color: theme.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Contact Number
                    TextFormField(
                      controller: _contactNumberController,
                      decoration: InputDecoration(
                        labelText: 'Contact Number',
                        hintText: 'Your phone number',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                    const SizedBox(height: 16),

                    // Description (Optional)
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Description (Optional)',
                        hintText: 'Additional details about the ride',
                        prefixIcon: const Icon(Icons.description_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                    ),
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
                                    const Text(
                                      'Posting...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                                : const Text(
                                  'Post Ride',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector({
    required String value,
    required TextEditingController customController,
    required bool isCustom,
    required IconData icon,
    required Color iconColor,
    required Function(String) onChanged,
    required dynamic theme,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items:
                      CabShareConfig.predefinedLocations.map((location) {
                        return DropdownMenuItem(
                          value: location,
                          child: Text(location),
                        );
                      }).toList(),
                  onChanged: (newValue) {
                    if (newValue != null) {
                      onChanged(newValue);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        if (isCustom) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: customController,
            decoration: InputDecoration(
              labelText: 'Enter custom location',
              hintText: 'e.g., Moon, Venus',
              prefixIcon: Icon(icon, color: iconColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter location';
              }
              return null;
            },
          ),
        ],
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

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = await showDatePicker(
      context: context,
      initialDate: _travelDate ?? today,
      firstDate: today,
      lastDate: today.add(Duration(days: CabShareConfig.maxFutureDays)),
    );

    if (date != null) {
      setState(() => _travelDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _travelTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() => _travelTime = time);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_travelDate == null) {
      SnackbarUtils.error(context, 'Please select travel date');
      return;
    }

    if (_travelTime == null) {
      SnackbarUtils.error(context, 'Please select travel time');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.0;
    });

    try {
      // Get final locations
      String fromLoc =
          _fromIsCustom ? _fromCustomController.text.trim() : _fromLocation;
      String toLoc =
          _toIsCustom ? _toCustomController.text.trim() : _toLocation;

      await _repository.addRide(
        fromLocation: fromLoc,
        toLocation: toLoc,
        travelDate: _travelDate!,
        travelTime: _travelTime!.format(context),
        cabType: _cabTypeController.text.trim(),
        seatsAvailable: _seatsAvailable,
        contactNumber: _contactNumberController.text.trim(),
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        postedByName: _profile!.name,
        postedByRegno: _profile!.registerNumber,
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
      Logger.e('AddCabRide', 'Error submitting ride', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to post ride. Please try again.');
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
