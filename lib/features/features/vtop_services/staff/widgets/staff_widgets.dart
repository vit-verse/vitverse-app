import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../logic/staff_logic.dart';

class StaffTypeTabs extends StatelessWidget {
  final List<String> staffTypes;
  final String selectedType;
  final Function(String) onTypeSelected;
  final ThemeProvider themeProvider;

  const StaffTypeTabs({
    super.key,
    required this.staffTypes,
    required this.selectedType,
    required this.onTypeSelected,
    required this.themeProvider,
  });

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'proctor':
        return Icons.person_pin_outlined;
      case 'hod':
        return Icons.school_outlined;
      case 'dean':
        return Icons.account_balance_outlined;
      default:
        return Icons.person_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (staffTypes.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          itemCount: staffTypes.length,
          itemBuilder: (context, index) {
            final type = staffTypes[index];
            final isSelected = type == selectedType;

            return Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 16 : 6,
                right: index == staffTypes.length - 1 ? 16 : 6,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTypeSelected(type),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? themeProvider.currentTheme.primary
                              : themeProvider.currentTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? themeProvider.currentTheme.primary
                                : themeProvider.currentTheme.muted.withValues(
                                  alpha: 0.2,
                                ),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForType(type),
                          size: 18,
                          color:
                              isSelected
                                  ? Colors.white
                                  : themeProvider.currentTheme.text,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : themeProvider.currentTheme.text,
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class StaffCard extends StatelessWidget {
  final Map<String, String> staffData;
  final String staffType;
  final ThemeProvider themeProvider;
  final StaffLogic logic;

  const StaffCard({
    super.key,
    required this.staffData,
    required this.staffType,
    required this.themeProvider,
    required this.logic,
  });

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    try {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Silently fail
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = logic.getFacultyName(staffData);
    final designation = logic.getDesignation(staffData);
    final department = logic.getDepartment(staffData);
    final email = logic.getEmail(staffData);
    final phone = logic.getPhone(staffData);
    final office = logic.getOfficeLocation(staffData);
    final employeeId = logic.getEmployeeId(staffData);
    final additionalDetails = logic.getAdditionalDetails(staffData);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.currentTheme.muted.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: themeProvider.currentTheme.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeProvider.currentTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForType(staffType),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staffType.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.currentTheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.currentTheme.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (designation != 'N/A')
                  _buildDetailRow(
                    icon: Icons.badge_outlined,
                    label: 'Designation',
                    value: designation,
                  ),
                if (department != 'N/A')
                  _buildDetailRow(
                    icon: Icons.business_outlined,
                    label: 'Department',
                    value: department,
                  ),
                if (employeeId != null && employeeId.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.badge_outlined,
                    label: 'Employee ID',
                    value: employeeId,
                  ),
                if (office != null && office.isNotEmpty)
                  _buildDetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Office',
                    value: office,
                  ),
                if (email != null && email.isNotEmpty)
                  _buildContactRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: email,
                    onTap: () => _launchEmail(email),
                  ),
                if (phone != null && phone.isNotEmpty)
                  _buildContactRow(
                    icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: logic.formatPhoneNumber(phone),
                    onTap: () => _launchPhone(phone),
                  ),
                if (additionalDetails.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Divider(
                    color: themeProvider.currentTheme.muted.withValues(
                      alpha: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...additionalDetails.entries.map((entry) {
                    return _buildDetailRow(
                      icon: Icons.info_outline,
                      label: entry.key,
                      value: entry.value,
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: themeProvider.currentTheme.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.currentTheme.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: themeProvider.currentTheme.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: themeProvider.currentTheme.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.currentTheme.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: themeProvider.currentTheme.text,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.currentTheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: themeProvider.currentTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'proctor':
        return Icons.person_pin;
      case 'hod':
        return Icons.school;
      case 'dean':
        return Icons.account_balance;
      default:
        return Icons.person;
    }
  }
}

class EmptyStaffState extends StatelessWidget {
  final String staffType;
  final ThemeProvider themeProvider;

  const EmptyStaffState({
    super.key,
    required this.staffType,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: themeProvider.currentTheme.muted.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_off_outlined,
                size: 64,
                color: themeProvider.currentTheme.muted.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No $staffType Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: themeProvider.currentTheme.text,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Staff contact details are not available yet.\nPlease check back later.',
              style: TextStyle(
                fontSize: 14,
                color: themeProvider.currentTheme.muted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
