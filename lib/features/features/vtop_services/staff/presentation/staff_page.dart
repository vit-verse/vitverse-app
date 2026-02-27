import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../core/loading/loading_messages.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../data/staff_data_provider.dart';
import '../logic/staff_logic.dart';
import '../widgets/staff_widgets.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> with TickerProviderStateMixin {
  final StaffDataProvider _dataProvider = StaffDataProvider();
  final StaffLogic _logic = StaffLogic();
  Map<String, List<Map<String, String>>> _staffByType = {};
  List<String> _staffTypes = ['Proctor', 'HOD', 'Dean'];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    AnalyticsService.instance.logScreenView(
      screenName: 'Staff',
      screenClass: 'StaffPage',
    );
    _loadStaffData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStaffData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final staffByType = await _dataProvider.getStaffByType();
      Logger.d('StaffPage', 'Loaded: ${staffByType.keys.join(", ")}');
      if (staffByType.isEmpty) {
        final proctor = await _dataProvider.getProctor();
        final hod = await _dataProvider.getHOD();
        final dean = await _dataProvider.getDean();
        if (proctor.isNotEmpty) staffByType['Proctor'] = [proctor];
        if (hod.isNotEmpty) staffByType['HOD'] = [hod];
        if (dean.isNotEmpty) staffByType['Dean'] = [dean];
      }
      final availableTypes =
          _staffTypes.where((type) => staffByType.containsKey(type)).toList();
      setState(() {
        _staffByType = staffByType;
        if (availableTypes.isNotEmpty) {
          _staffTypes = availableTypes;
          _tabController.dispose();
          _tabController = TabController(
            length: availableTypes.length,
            vsync: this,
          );
          _tabController.addListener(() {
            if (!_tabController.indexIsChanging) {
              setState(() {});
            }
          });
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load staff contacts';
        _isLoading = false;
      });
      Logger.e('StaffPage', 'Error loading staff data', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to load staff contacts');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeProvider.currentTheme.background,
      appBar: AppBar(
        backgroundColor: themeProvider.currentTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: themeProvider.currentTheme.text,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Staff',
          style: TextStyle(
            color: themeProvider.currentTheme.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(themeProvider),
    );
  }

  Widget _buildBody(ThemeProvider themeProvider) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: themeProvider.currentTheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              LoadingMessages.getMessage('staff'),
              style: TextStyle(
                color: themeProvider.currentTheme.muted,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
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
              Icons.error_outline_rounded,
              size: 64,
              color: themeProvider.currentTheme.muted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: themeProvider.currentTheme.text),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadStaffData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeProvider.currentTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    if (_staffByType.isEmpty) {
      return EmptyStaffState(staffType: 'Staff', themeProvider: themeProvider);
    }
    return RefreshIndicator(
      onRefresh: _loadStaffData,
      color: themeProvider.currentTheme.primary,
      child: Column(
        children: [
          _buildTabBar(themeProvider),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children:
                  _staffTypes.map((type) {
                    return _buildStaffListForType(type, themeProvider);
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: themeProvider.currentTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(_staffTypes.length, (index) {
          return Expanded(
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, child) {
                final isSelected = _tabController.index == index;
                final animValue = _tabController.animation?.value ?? 0.0;
                final progress = (animValue - index).abs().clamp(0.0, 1.0);
                final colorValue = 1.0 - progress;

                return GestureDetector(
                  onTap: () {
                    _tabController.animateTo(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        Colors.transparent,
                        themeProvider.currentTheme.primary,
                        colorValue,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _staffTypes[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: Color.lerp(
                          themeProvider.currentTheme.muted,
                          themeProvider.currentTheme.isDark
                              ? Colors.black
                              : Colors.white,
                          colorValue,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStaffListForType(String type, ThemeProvider themeProvider) {
    final staffList = _staffByType[type] ?? [];
    if (staffList.isEmpty) {
      return EmptyStaffState(staffType: type, themeProvider: themeProvider);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: staffList.length,
      itemBuilder:
          (context, index) => StaffCard(
            staffData: staffList[index],
            staffType: type,
            themeProvider: themeProvider,
            logic: _logic,
          ),
    );
  }
}
