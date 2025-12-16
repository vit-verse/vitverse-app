import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../models/calculator_state.dart';
import '../data/calculator_data_provider.dart';
import 'tabs/estimator_tab.dart';
import 'tabs/predictor_tab.dart';
import 'tabs/summary_tab.dart';
import 'widgets/grading_system_info_dialog.dart';
import 'add_courses_page.dart';

class CgpaGpaCalculatorPage extends StatefulWidget {
  const CgpaGpaCalculatorPage({super.key});

  @override
  State<CgpaGpaCalculatorPage> createState() => _CgpaGpaCalculatorPageState();
}

class _CgpaGpaCalculatorPageState extends State<CgpaGpaCalculatorPage> {
  static const String _tag = 'CgpaGpaCalculator';
  final CalculatorDataProvider _dataProvider = CalculatorDataProvider();

  CalculatorState? _calculatorState;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'CgpaGpaCalculator',
      screenClass: 'CgpaGpaCalculatorPage',
    );
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Logger.d(_tag, 'Loading calculator data...');
      final state = await _dataProvider.loadCalculatorState();

      if (!mounted) return;

      if (state.currentCGPA == 0.0) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'No academic data found. Please sync your VTOP data first.';
        });
        Logger.w(_tag, 'No CGPA data available');
        return;
      }

      setState(() {
        _calculatorState = state;
        _isLoading = false;
      });

      Logger.i(_tag, 'Calculator data loaded');
    } catch (e, stackTrace) {
      Logger.e(_tag, 'Failed to load calculator data', e, stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data: ${e.toString()}';
      });
    }
  }

  Future<void> _refreshData() async {
    Logger.d(_tag, 'Refreshing calculator data...');
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        title: Text(
          'CGPA & GPA Tools',
          style: TextStyle(
            color: theme.text,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.text),
        actions: [
          if (_calculatorState != null) ...[
            IconButton(
              icon: Icon(Icons.info_outline, color: theme.primary),
              onPressed: _showGradingSystemInfo,
              tooltip: 'Grading System Guide',
            ),
            IconButton(
              icon: Icon(Icons.add_box_outlined, color: theme.primary),
              onPressed: _showAddCoursesDialog,
              tooltip: 'Add Courses to Categories',
            ),
          ],
        ],
      ),
      body: _buildBody(theme),
    );
  }

  void _showGradingSystemInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GradingSystemInfoDialog()),
    );
  }

  void _showAddCoursesDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCoursesPage(onCoursesUpdated: _refreshData),
      ),
    );
  }

  Widget _buildBody(dynamic theme) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_errorMessage != null) {
      return _buildErrorView(theme);
    }

    if (_calculatorState == null) {
      return _buildNoDataView(theme);
    }

    return Column(
      children: [
        _buildTabBar(theme),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: theme.primary,
            child: _buildCurrentTab(),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(dynamic theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'Estimator',
              icon: Icons.flag,
              index: 0,
              theme: theme,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'Predictor',
              icon: Icons.analytics,
              index: 1,
              theme: theme,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'Summary',
              icon: Icons.insights,
              index: 2,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required int index,
    required dynamic theme,
  }) {
    final isSelected = _selectedTabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : theme.muted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : theme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedTabIndex) {
      case 0:
        return EstimatorTab(
          state: _calculatorState!,
          onStateChanged: (newState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _calculatorState = newState);
              }
            });
          },
        );
      case 1:
        return PredictorTab(
          state: _calculatorState!,
          onStateChanged: (newState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _calculatorState = newState);
              }
            });
          },
        );
      case 2:
        return SummaryTab(state: _calculatorState!);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildErrorView(dynamic theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: TextStyle(fontSize: 14, color: theme.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataView(dynamic theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: theme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Data Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sync your VTOP data to use the calculator',
              style: TextStyle(fontSize: 14, color: theme.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
