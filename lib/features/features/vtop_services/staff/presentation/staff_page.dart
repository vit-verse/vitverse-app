import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../core/loading/loading_messages.dart';
import '../data/staff_data_provider.dart';
import '../logic/staff_logic.dart';
import '../widgets/staff_widgets.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  final StaffDataProvider _dataProvider = StaffDataProvider();
  final StaffLogic _logic = StaffLogic();
  Map<String, List<Map<String, String>>> _staffByType = {};
  List<String> _staffTypes = ['Proctor', 'HOD', 'Dean'];
  String _selectedType = 'Proctor';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    FirebaseAnalytics.instance.logScreenView(
      screenName: 'Staff',
      screenClass: 'StaffPage',
    );
    _loadStaffData();
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
          _selectedType = availableTypes.first;
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
              color: themeProvider.currentTheme.muted.withOpacity(0.5),
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
          StaffTypeTabs(
            staffTypes: _staffTypes,
            selectedType: _selectedType,
            onTypeSelected: (type) => setState(() => _selectedType = type),
            themeProvider: themeProvider,
          ),
          Expanded(child: _buildStaffList(themeProvider)),
        ],
      ),
    );
  }

  Widget _buildStaffList(ThemeProvider themeProvider) {
    final staffList = _staffByType[_selectedType] ?? [];
    if (staffList.isEmpty) {
      return EmptyStaffState(
        staffType: _selectedType,
        themeProvider: themeProvider,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: staffList.length,
      itemBuilder:
          (context, index) => StaffCard(
            staffData: staffList[index],
            staffType: _selectedType,
            themeProvider: themeProvider,
            logic: _logic,
          ),
    );
  }
}
