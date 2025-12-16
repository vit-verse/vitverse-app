import 'package:flutter/material.dart';
import '../models/models.dart';
import '../logic/attendance_logic.dart';

class AttendanceMatrixGrid extends StatelessWidget {
  final List<List<AttendanceMatrixCell>> matrix;
  final Function(AttendanceMatrixCell) onCellTap;
  final bool isDark;

  const AttendanceMatrixGrid({
    super.key,
    required this.matrix,
    required this.onCellTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final totalGaps = 7 * 2.5;
        final labelWidth = 24.0;
        final cellWidth = (availableWidth - totalGaps - labelWidth - 8) / 6;
        final cellSize = cellWidth.clamp(30.0, 46.0);

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildColumnHeaders(cellSize, labelWidth),
              const SizedBox(height: 3),
              ...List.generate(6, (rowIndex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: _buildMatrixRow(
                    rowIndex: rowIndex,
                    cellSize: cellSize,
                    labelWidth: labelWidth,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColumnHeaders(double cellSize, double labelWidth) {
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Center(
            child: Text(
              '',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(6, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 2.5),
            child: SizedBox(
              width: cellSize,
              child: Center(
                child: Text(
                  '+$index',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMatrixRow({
    required int rowIndex,
    required double cellSize,
    required double labelWidth,
  }) {
    return Row(
      children: [
        SizedBox(
          width: labelWidth,
          child: Center(
            child: Text(
              '+$rowIndex',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
        const SizedBox(width: 2.5),
        ...List.generate(6, (colIndex) {
          final cell = matrix[rowIndex][colIndex];
          return Padding(
            padding: const EdgeInsets.only(right: 2.5),
            child: _buildMatrixCell(cell, cellSize),
          );
        }),
      ],
    );
  }

  Widget _buildMatrixCell(AttendanceMatrixCell cell, double cellSize) {
    final backgroundColor = AttendanceMatrixLogic.getCellBackgroundColor(
      cell.status,
      isDark,
    );
    final textColor = AttendanceMatrixLogic.getCellTextColor(
      cell.status,
      isDark,
    );

    final isCurrentCell =
        cell.futureAttendances == 0 && cell.futureAbsences == 0;

    return GestureDetector(
      onTap: () => onCellTap(cell),
      child: Container(
        width: cellSize,
        height: cellSize,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: cell.status.color.withOpacity(0.3),
            width: 1.0,
          ),
        ),
        child: Stack(
          children: [
            if (isCurrentCell)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: cell.status.color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Now',
                    style: TextStyle(
                      fontSize: cellSize > 45 ? 6 : 5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${cell.formattedPercentage}%',
                    style: TextStyle(
                      fontSize: cellSize > 45 ? 10 : 9,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    cell.bufferIndicator,
                    style: TextStyle(
                      fontSize: cellSize > 45 ? 8 : 7,
                      fontWeight: FontWeight.w500,
                      color: textColor.withOpacity(0.8),
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ColorLegendWidget extends StatelessWidget {
  final Color textColor;
  final Color mutedColor;
  final bool isDark;

  const ColorLegendWidget({
    super.key,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: mutedColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: mutedColor.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: mutedColor),
              const SizedBox(width: 8),
              Text(
                'COLOR GUIDE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: mutedColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildLegendItem(
                  color: AttendanceStatus.safe.color,
                  label: 'Excellent',
                  subtitle: '≥80%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLegendItem(
                  color: AttendanceStatus.caution.color,
                  label: 'Safe',
                  subtitle: '75-79%',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLegendItem(
                  color: AttendanceStatus.atRisk.color,
                  label: 'At Risk',
                  subtitle: '<75%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  height: 1.2,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: mutedColor, height: 1.2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AttendanceCellDetailModal extends StatelessWidget {
  final AttendanceMatrixCell cell;
  final Color primaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color mutedColor;
  final bool isDark;

  const AttendanceCellDetailModal({
    super.key,
    required this.cell,
    required this.primaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.mutedColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: mutedColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Attendance Projection',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Overall Course Analysis',
            style: TextStyle(fontSize: 14, color: mutedColor),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cell.status.color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'PROJECTED ATTENDANCE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${cell.formattedPercentage}%',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: cell.status.color,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cell.status.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cell.status.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cell.status.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildScenarioCard(
                  title: 'Future Attendances',
                  value: '+${cell.futureAttendances}',
                  color: Colors.green,
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScenarioCard(
                  title: 'Future Absences',
                  value: '+${cell.futureAbsences}',
                  color: Colors.red,
                  icon: Icons.cancel_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT STATUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: mutedColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Attendance:',
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                    Text(
                      '${cell.currentAttended} / ${cell.currentTotal}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total After Change:',
                      style: TextStyle(fontSize: 14, color: textColor),
                    ),
                    Text(
                      '${cell.attendedAfterScenario} / ${cell.totalAfterScenario}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cell.status.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cell.status.color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: cell.status.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'INTERPRETATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cell.status.color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  cell.interpretation,
                  style: TextStyle(fontSize: 14, height: 1.5, color: textColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildScenarioCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: mutedColor, height: 1.2),
          ),
        ],
      ),
    );
  }

  static void show(
    BuildContext context, {
    required AttendanceMatrixCell cell,
    required Color primaryColor,
    required Color backgroundColor,
    required Color surfaceColor,
    required Color textColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => AttendanceCellDetailModal(
            cell: cell,
            primaryColor: primaryColor,
            backgroundColor: backgroundColor,
            surfaceColor: surfaceColor,
            textColor: textColor,
            mutedColor: mutedColor,
            isDark: isDark,
          ),
    );
  }
}
