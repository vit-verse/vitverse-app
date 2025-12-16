import 'package:flutter/material.dart';
import '../../../../core/database/entities/student_profile.dart';
import '../../../../core/theme/theme_constants.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../firebase/analytics/analytics_service.dart';
import '../widgets/edit_nickname_dialog.dart';
import '../widgets/avatar_picker_dialog.dart';
import 'package:provider/provider.dart';

class ProfileDetailPage extends StatefulWidget {
  final StudentProfile profile;

  const ProfileDetailPage({super.key, required this.profile});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfileDetail',
      screenClass: 'ProfileDetailPage',
    );
  }

  void _showEditNicknameDialog() {
    showDialog(
      context: context,
      builder:
          (context) => EditNicknameDialog(
            currentNickname: widget.profile.nickname ?? '',
            onNicknameUpdated: () {
              setState(() {});
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
    );
  }

  Future<void> _showAvatarPickerDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const AvatarPickerDialog(),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Scaffold(
      appBar: AppBar(title: Text('Profile Details')),
      backgroundColor: theme.background,
      body: ListView(
        padding: const EdgeInsets.all(ThemeConstants.spacingMd),
        children: [
          // Customization Options Card
          _sectionCard(
            context,
            title: 'Customize Profile',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.face, color: theme.primary),
                title: const Text('Add Nickname'),
                subtitle:
                    widget.profile.nickname?.isNotEmpty == true
                        ? Text(
                          'Current: ${widget.profile.nickname}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                        : const Text('Set a custom nickname'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showEditNicknameDialog,
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.account_circle, color: theme.primary),
                title: const Text('Add Avatar'),
                subtitle: const Text('Choose from random avatars'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showAvatarPickerDialog,
              ),
            ],
          ),

          const SizedBox(height: ThemeConstants.spacingMd),
          // Basic Information Section
          _sectionCard(
            context,
            title: 'Basic Information',
            children: [
              _row('Name', widget.profile.name),
              _row('Registration Number', widget.profile.registerNumber),
              _row('VIT Email', widget.profile.vitEmail),
              if (widget.profile.gender != null)
                _row('Gender', widget.profile.gender!),
              if (widget.profile.dateOfBirth != null)
                _row('Date of Birth', widget.profile.dateOfBirth!),
            ],
          ),

          const SizedBox(height: ThemeConstants.spacingMd),

          // Academic Profile Section
          _sectionCard(
            context,
            title: 'Academic Profile',
            children: [
              _row('Program', widget.profile.program),
              _row('Branch', widget.profile.branch),
              _row('School', widget.profile.schoolName),
              if (widget.profile.yearJoined != null)
                _row('Year Joined', widget.profile.yearJoined!),
              if (widget.profile.studySystem != null)
                _row('Study System', widget.profile.studySystem!),
              if (widget.profile.eduStatus != null)
                _row('Educational Status', widget.profile.eduStatus!),
              if (widget.profile.campus != null)
                _row('Campus', widget.profile.campus!),
              if (widget.profile.programmeMode != null)
                _row('Programme Mode', widget.profile.programmeMode!),
            ],
          ),

          const SizedBox(height: ThemeConstants.spacingMd),

          // Hostel Information Section (if available)
          if (widget.profile.hostelBlock != null)
            _sectionCard(
              context,
              title: 'Hostel Information',
              children: [
                _row('Block', widget.profile.hostelBlock!),
                if (widget.profile.roomNumber != null)
                  _row('Room Number', widget.profile.roomNumber!),
                if (widget.profile.bedType != null)
                  _row('Bed Type', widget.profile.bedType!),
                if (widget.profile.messName != null)
                  _row('Mess Name', widget.profile.messName!),
              ],
            ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final themeProv = Provider.of<ThemeProvider>(context);
    return Container(
      decoration: BoxDecoration(
        color: themeProv.currentTheme.surface,
        borderRadius: BorderRadius.circular(ThemeConstants.radiusMd),
      ),
      padding: const EdgeInsets.all(ThemeConstants.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: themeProv.currentTheme.primary,
            ),
          ),
          const SizedBox(height: ThemeConstants.spacingSm),
          const Divider(height: 1),
          const SizedBox(height: ThemeConstants.spacingSm),
          ...children,
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ThemeConstants.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
