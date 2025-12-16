import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/database/entities/student_profile.dart';

/// Simple greeting widget that shows:
/// - Formatted date (Friday, October 31)
/// - Time-based greeting
/// - Student name
class GreetingWidget extends StatefulWidget {
  const GreetingWidget({super.key});

  @override
  State<GreetingWidget> createState() => _GreetingWidgetState();
}

class _GreetingWidgetState extends State<GreetingWidget> {
  static const String _tag = 'GreetingWidget';

  String _formattedDate = '';
  String _greetingText = '';
  String _displayName = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGreetingData();
  }

  Future<void> _loadGreetingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('student_profile');

      String name = 'Student';

      if (profileJson != null && profileJson.isNotEmpty) {
        try {
          final profile = StudentProfile.fromJson(
            jsonDecode(profileJson) as Map<String, dynamic>,
          );

          // Use nickname if available, otherwise use full name
          if (profile.nickname != null && profile.nickname!.isNotEmpty) {
            name = profile.nickname!;
          } else {
            name = profile.name;
          }
        } catch (e) {
          Logger.e(_tag, 'Error parsing student profile', e);
        }
      }

      // Format date
      final now = DateTime.now();
      final formattedDate = DateFormat('EEEE, MMMM dd').format(now);

      // Time-based greeting
      final hour = now.hour;
      String greeting = 'Hey';
      if (hour >= 5 && hour < 12) {
        greeting = 'Good Morning';
      } else if (hour >= 12 && hour < 17) {
        greeting = 'Good Afternoon';
      } else if (hour >= 17 && hour < 21) {
        greeting = 'Good Evening';
      } else {
        greeting = 'Good Night';
      }

      if (mounted) {
        setState(() {
          _displayName = name;
          _formattedDate = formattedDate;
          _greetingText = greeting;
          _isLoading = false;
        });
      }

      Logger.i(_tag, 'Greeting data loaded for: $name');
    } catch (e) {
      Logger.e(_tag, 'Error loading greeting data', e);

      if (mounted) {
        setState(() {
          _displayName = 'Student';
          _formattedDate = DateFormat('EEEE, MMMM dd').format(DateTime.now());
          _greetingText = 'Hey';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 11,
              width: 120,
              decoration: BoxDecoration(
                color: themeProvider.currentTheme.muted.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 28,
              width: 180,
              decoration: BoxDecoration(
                color: themeProvider.currentTheme.muted.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 14,
              width: double.infinity,
              decoration: BoxDecoration(
                color: themeProvider.currentTheme.muted.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date
          Text(
            _formattedDate,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF888888),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),

          // Greeting
          Text(
            _greetingText.toUpperCase(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFFAAAAAA),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),

          // Student Name
          Text(
            _displayName,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color:
                  themeProvider.currentTheme.isDark
                      ? Colors.white
                      : themeProvider.currentTheme.primary,
              height: 1.2,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
