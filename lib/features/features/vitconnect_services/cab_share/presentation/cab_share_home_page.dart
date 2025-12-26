import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../../../../../supabase/core/supabase_client.dart';
import '../logic/cab_ride_provider.dart';
import 'tabs/explore_tab.dart';
import 'tabs/my_rides_tab.dart';
import 'add_cab_ride_page.dart';

/// Cab Share home page with 2 tabs
class CabShareHomePage extends StatefulWidget {
  const CabShareHomePage({super.key});

  @override
  State<CabShareHomePage> createState() => _CabShareHomePageState();
}

class _CabShareHomePageState extends State<CabShareHomePage> {
  CabRideProvider? _provider;
  bool _isSupabaseConfigured = false;
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, String> _filters = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
    _checkSupabaseAndInit();

    AnalyticsService.instance.logScreenView(
      screenName: 'CabShare',
      screenClass: 'CabShareHomePage',
    );
  }

  void _checkSupabaseAndInit() {
    if (!SupabaseClientService.isInitialized) {
      setState(() => _isSupabaseConfigured = false);
      return;
    }

    setState(() => _isSupabaseConfigured = true);
    _provider = CabRideProvider();
    _loadData();
  }

  Future<void> _loadData() async {
    if (_provider == null) return;
    await _provider!.loadRides();
    if (mounted && _provider!.errorMessage != null) {
      SnackbarUtils.error(context, _provider!.errorMessage!);
    }
  }

  Future<void> _onRefresh() async {
    if (_provider == null) return;
    await _provider!.refresh();
    if (mounted && _provider!.errorMessage != null) {
      SnackbarUtils.error(context, _provider!.errorMessage!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    if (!_isSupabaseConfigured) {
      return Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: Text(
            'Cab Share',
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
        body: _buildSupabaseNotConfiguredUI(theme),
      );
    }

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: Text(
            'Cab Share',
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
        body: Column(
          children: [
            _buildTabBar(theme),
            _buildSearchAndFilterBar(theme),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: theme.primary,
                child: _buildCurrentTab(),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddPage,
          backgroundColor: theme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
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
              label: 'Explore',
              icon: Icons.explore_outlined,
              index: 0,
              theme: theme,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              label: 'My Rides',
              icon: Icons.person_outline,
              index: 1,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar(dynamic theme) {
    return Column(
      children: [
        // Search bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: theme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.border),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: theme.muted, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: theme.text, fontSize: 14),
                  enableInteractiveSelection: false,
                  decoration: InputDecoration(
                    hintText: 'Search rides...',
                    hintStyle: TextStyle(color: theme.muted, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, color: theme.muted, size: 18),
                  onPressed: () => _searchController.clear(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              // Filter button
              IconButton(
                icon: Icon(
                  _filters.isNotEmpty
                      ? Icons.filter_alt
                      : Icons.filter_alt_outlined,
                  color: _filters.isNotEmpty ? theme.primary : theme.muted,
                  size: 20,
                ),
                onPressed: _showFilterDialog,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        // Active filters chips
        if (_filters.isNotEmpty)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (_filters['from'] != null && _filters['from']!.isNotEmpty)
                  _buildFilterChip(
                    theme,
                    'From: ${_filters['from']}',
                    () => _removeFilter('from'),
                  ),
                if (_filters['to'] != null && _filters['to']!.isNotEmpty)
                  _buildFilterChip(
                    theme,
                    'To: ${_filters['to']}',
                    () => _removeFilter('to'),
                  ),
                if (_filters['date'] != null && _filters['date']!.isNotEmpty)
                  _buildFilterChip(
                    theme,
                    'Date: ${_filters['date']}',
                    () => _removeFilter('date'),
                  ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => setState(() => _filters.clear()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'Clear all',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(dynamic theme, String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onRemove,
            child: Icon(Icons.close, size: 16, color: theme.primary),
          ),
        ],
      ),
    );
  }

  void _removeFilter(String key) {
    setState(() {
      _filters.remove(key);
    });
  }

  void _showFilterDialog() {
    final theme =
        Provider.of<ThemeProvider>(context, listen: false).currentTheme;
    final fromController = TextEditingController(text: _filters['from'] ?? '');
    final toController = TextEditingController(text: _filters['to'] ?? '');
    DateTime? selectedDate;

    if (_filters['date'] != null && _filters['date']!.isNotEmpty) {
      try {
        selectedDate = DateTime.parse(_filters['date']!);
      } catch (e) {
        // Ignore parse errors
      }
    }

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  backgroundColor: theme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Row(
                    children: [
                      Icon(Icons.filter_alt, color: theme.primary),
                      const SizedBox(width: 12),
                      Text('Filter Rides', style: TextStyle(color: theme.text)),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // From location
                        Text(
                          'From Location (Optional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.text.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: fromController,
                          style: TextStyle(color: theme.text),
                          decoration: InputDecoration(
                            hintText: 'Enter location',
                            hintStyle: TextStyle(color: theme.muted),
                            filled: true,
                            fillColor: theme.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: theme.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: theme.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: theme.primary),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // To location
                        Text(
                          'To Location (Optional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.text.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: toController,
                          style: TextStyle(color: theme.text),
                          decoration: InputDecoration(
                            hintText: 'Enter location',
                            hintStyle: TextStyle(color: theme.muted),
                            filled: true,
                            fillColor: theme.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: theme.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: theme.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: theme.primary),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Date
                        Text(
                          'Travel Date (Optional)',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.text.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 90),
                              ),
                            );
                            if (date != null) {
                              setDialogState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.background,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: theme.border),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: theme.muted,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    selectedDate != null
                                        ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                        : 'Select date',
                                    style: TextStyle(
                                      color:
                                          selectedDate != null
                                              ? theme.text
                                              : theme.muted,
                                    ),
                                  ),
                                ),
                                if (selectedDate != null)
                                  InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        selectedDate = null;
                                      });
                                    },
                                    child: Icon(
                                      Icons.clear,
                                      color: theme.muted,
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filters.clear();
                        });
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(color: theme.error),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: theme.text),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _filters = {};
                          if (fromController.text.isNotEmpty) {
                            _filters['from'] = fromController.text;
                          }
                          if (toController.text.isNotEmpty) {
                            _filters['to'] = toController.text;
                          }
                          if (selectedDate != null) {
                            final dateKey =
                                '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
                            _filters['date'] = dateKey;
                          }
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
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

    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
              color:
                  isSelected ? Colors.white : theme.text.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color:
                    isSelected
                        ? Colors.white
                        : theme.text.withValues(alpha: 0.6),
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
        return ExploreTab(
          searchQuery: _searchQuery,
          filters: _filters.isNotEmpty ? _filters : null,
        );
      case 1:
        return const MyRidesTab();
      default:
        return ExploreTab(
          searchQuery: _searchQuery,
          filters: _filters.isNotEmpty ? _filters : null,
        );
    }
  }

  void _openAddPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddCabRidePage()),
    );

    if (result == true && mounted) {
      SnackbarUtils.success(context, 'Ride posted successfully!');
      _onRefresh();
    }
  }

  Widget _buildSupabaseNotConfiguredUI(theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 80,
                color: theme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Configuration Incomplete',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: theme.text,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
