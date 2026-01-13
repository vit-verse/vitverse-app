import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/color_utils.dart';
import '../../../../core/utils/logger.dart';
import '../../logic/home_logic.dart';
import 'attendance_widget.dart';
import 'secondary_widgets.dart';

/// Section containing the two main widgets on the home page
class HomeWidgetsSection extends StatelessWidget {
  static const String _tag = 'HomeWidgetsSection';

  final HomeLogic homeLogic;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const HomeWidgetsSection({
    super.key,
    required this.homeLogic,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(child: AttendanceWidget(homeLogic: homeLogic)),
            const SizedBox(width: 16),
            Expanded(child: SecondaryWidgets(homeLogic: homeLogic)),
          ],
        );
      },
    );
  }
}
