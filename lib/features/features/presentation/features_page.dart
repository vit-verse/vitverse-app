import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_provider.dart';
import '../logic/feature_provider.dart';
import '../models/feature_model.dart';
import '../data/feature_catalogue.dart';
import '../constants/feature_colors.dart';
import '../data/feature_repository.dart';
import '../widgets/feature_tile.dart';
import '../widgets/section_headers.dart';
import 'features_settings_page.dart';

class FeaturesPage extends StatefulWidget {
  const FeaturesPage({super.key});

  @override
  State<FeaturesPage> createState() => _FeaturesPageState();
}

class _FeaturesPageState extends State<FeaturesPage> {
  bool _vtopAcademicExpanded = true;
  bool _vtopFacultyExpanded = true;
  bool _vtopFinanceExpanded = true;

  bool _vitconnectSocialExpanded = true;
  bool _vitconnectAcademicsExpanded = true;
  bool _vitconnectUtilitiesExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadExpandedStates();
  }

  Future<void> _loadExpandedStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _vtopAcademicExpanded = prefs.getBool('vtop_academic_expanded') ?? true;
        _vtopFacultyExpanded = prefs.getBool('vtop_faculty_expanded') ?? true;
        _vtopFinanceExpanded = prefs.getBool('vtop_finance_expanded') ?? true;
        _vitconnectSocialExpanded =
            prefs.getBool('vitconnect_social_expanded') ?? true;
        _vitconnectAcademicsExpanded =
            prefs.getBool('vitconnect_academics_expanded') ?? true;
        _vitconnectUtilitiesExpanded =
            prefs.getBool('vitconnect_utilities_expanded') ?? true;
      });
    } catch (e) {
      // Use defaults if loading fails
    }
  }

  Future<void> _saveExpandedStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vtop_academic_expanded', _vtopAcademicExpanded);
      await prefs.setBool('vtop_faculty_expanded', _vtopFacultyExpanded);
      await prefs.setBool('vtop_finance_expanded', _vtopFinanceExpanded);
      await prefs.setBool(
        'vitconnect_social_expanded',
        _vitconnectSocialExpanded,
      );
      await prefs.setBool(
        'vitconnect_academics_expanded',
        _vitconnectAcademicsExpanded,
      );
      await prefs.setBool(
        'vitconnect_utilities_expanded',
        _vitconnectUtilitiesExpanded,
      );
    } catch (e) {
      // Ignore save errors
    }
  }

  void _expandAll() {
    setState(() {
      _vtopAcademicExpanded = true;
      _vtopFacultyExpanded = true;
      _vtopFinanceExpanded = true;
      _vitconnectSocialExpanded = true;
      _vitconnectAcademicsExpanded = true;
      _vitconnectUtilitiesExpanded = true;
    });
    _saveExpandedStates();
  }

  void _collapseAll() {
    setState(() {
      _vtopAcademicExpanded = false;
      _vtopFacultyExpanded = false;
      _vtopFinanceExpanded = false;
      _vitconnectSocialExpanded = false;
      _vitconnectAcademicsExpanded = false;
      _vitconnectUtilitiesExpanded = false;
    });
    _saveExpandedStates();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;
    final featureProvider = Provider.of<FeatureProvider>(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: themeProvider.systemOverlayStyle,
      child: Scaffold(
        backgroundColor: theme.background,
        appBar: AppBar(
          title: const Text('Features'),
          centerTitle: false,
          automaticallyImplyLeading: false,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: _buildExpandCollapseButton(theme),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: _buildActionButton(
                icon: Icons.settings_outlined,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              ChangeNotifierProvider<FeatureProvider>.value(
                                value: featureProvider,
                                child: const FeaturesSettingsPage(),
                              ),
                    ),
                  );
                },
                theme: theme,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (featureProvider.pinnedFeatures.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SimpleSectionHeader(
                      title: 'Quick Access',
                      count: featureProvider.pinnedFeatures.length,
                    ),
                    _buildFeatureGrid(
                      featureProvider.pinnedFeatures,
                      featureProvider.viewMode,
                    ),
                  ],
                )
              else if (featureProvider.hasCustomizedPins)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SimpleSectionHeader(title: 'Quick Access', count: 0),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.muted.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.push_pin_outlined,
                            size: 48,
                            color: theme.muted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Pin your favorite features for quick access',
                            style: TextStyle(
                              color: theme.muted,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MainSectionHeader(
                    title: 'VTOP Services',
                    gradientColors: FeatureColors.vtopHeaderGradient,
                  ),
                  _buildVtopSection(featureProvider.viewMode),
                ],
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MainSectionHeader(
                    title: 'VIT Verse',
                    gradientColors: FeatureColors.vitConnectHeaderGradient,
                  ),
                  _buildVitConnectSection(featureProvider.viewMode),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required dynamic theme,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.muted.withValues(alpha: 0.2)),
        ),
        child: Icon(icon, size: 20, color: theme.text),
      ),
    );
  }

  Widget _buildExpandCollapseButton(dynamic theme) {
    final anyCollapsed =
        !_vtopAcademicExpanded ||
        !_vtopFacultyExpanded ||
        !_vtopFinanceExpanded ||
        !_vitconnectSocialExpanded ||
        !_vitconnectAcademicsExpanded ||
        !_vitconnectUtilitiesExpanded;

    return GestureDetector(
      onTap: anyCollapsed ? _expandAll : _collapseAll,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.muted.withValues(alpha: 0.2)),
        ),
        child: Icon(
          anyCollapsed ? Icons.unfold_more : Icons.unfold_less,
          size: 20,
          color: theme.text,
        ),
      ),
    );
  }

  Widget _buildVtopSection(ViewMode viewMode) {
    final vtopFeaturesByCategory = FeatureCatalogue.getVtopFeaturesByCategory();
    final academic = vtopFeaturesByCategory[FeatureCategory.academic] ?? [];
    final faculty = vtopFeaturesByCategory[FeatureCategory.faculty] ?? [];
    final finance = vtopFeaturesByCategory[FeatureCategory.finance] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (academic.isNotEmpty) ...[
          SubSectionHeader(
            title: 'Academic',
            count: academic.length,
            isExpanded: _vtopAcademicExpanded,
            onTap: () {
              setState(() {
                _vtopAcademicExpanded = !_vtopAcademicExpanded;
              });
              _saveExpandedStates();
            },
          ),
          if (_vtopAcademicExpanded) _buildFeatureGrid(academic, viewMode),
        ],

        if (faculty.isNotEmpty) ...[
          SubSectionHeader(
            title: 'Faculty & Admin',
            count: faculty.length,
            isExpanded: _vtopFacultyExpanded,
            onTap: () {
              setState(() {
                _vtopFacultyExpanded = !_vtopFacultyExpanded;
              });
              _saveExpandedStates();
            },
          ),
          if (_vtopFacultyExpanded) _buildFeatureGrid(faculty, viewMode),
        ],

        if (finance.isNotEmpty) ...[
          SubSectionHeader(
            title: 'Finance',
            count: finance.length,
            isExpanded: _vtopFinanceExpanded,
            onTap: () {
              setState(() {
                _vtopFinanceExpanded = !_vtopFinanceExpanded;
              });
              _saveExpandedStates();
            },
          ),
          if (_vtopFinanceExpanded) _buildFeatureGrid(finance, viewMode),
        ],
      ],
    );
  }

  Widget _buildVitConnectSection(ViewMode viewMode) {
    final vitConnectFeatures = FeatureCatalogue.getVitConnectFeatures();

    final social =
        vitConnectFeatures
            .where((f) => f.category == FeatureCategory.social)
            .toList();
    final academics =
        vitConnectFeatures
            .where((f) => f.category == FeatureCategory.academics)
            .toList();
    final utilities =
        vitConnectFeatures
            .where((f) => f.category == FeatureCategory.utilities)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (social.isNotEmpty) ...[
          SubSectionHeader(
            title: 'Social',
            count: social.length,
            isExpanded: _vitconnectSocialExpanded,
            onTap: () {
              setState(() {
                _vitconnectSocialExpanded = !_vitconnectSocialExpanded;
              });
              _saveExpandedStates();
            },
          ),
          if (_vitconnectSocialExpanded) _buildFeatureGrid(social, viewMode),
        ],

        if (academics.isNotEmpty) ...[
          SubSectionHeader(
            title: 'Academics',
            count: academics.length,
            isExpanded: _vitconnectAcademicsExpanded,
            onTap: () {
              setState(() {
                _vitconnectAcademicsExpanded = !_vitconnectAcademicsExpanded;
              });
              _saveExpandedStates();
            },
          ),
          if (_vitconnectAcademicsExpanded)
            _buildFeatureGrid(academics, viewMode),
        ],

        if (utilities.isNotEmpty) ...[
          SubSectionHeader(
            title: 'Utilities',
            count: utilities.length,
            isExpanded: _vitconnectUtilitiesExpanded,
            onTap: () {
              setState(() {
                _vitconnectUtilitiesExpanded = !_vitconnectUtilitiesExpanded;
              });
              _saveExpandedStates();
            },
          ),
          if (_vitconnectUtilitiesExpanded)
            _buildFeatureGrid(utilities, viewMode),
        ],
        // Add bottom padding to prevent last item from hiding under navbar
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildFeatureGrid(List<Feature> features, ViewMode viewMode) {
    if (viewMode == ViewMode.list) {
      return Column(
        children:
            features.map((feature) {
              return FeatureTile(feature: feature, viewMode: viewMode);
            }).toList(),
      );
    }

    final columnCount = viewMode == ViewMode.grid2Column ? 2 : 3;
    final crossAxisSpacing = viewMode == ViewMode.grid2Column ? 12.0 : 8.0;
    final mainAxisSpacing = viewMode == ViewMode.grid2Column ? 12.0 : 8.0;
    final childAspectRatio = viewMode == ViewMode.grid2Column ? 2.3 : 1.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        return FeatureTile(feature: features[index], viewMode: viewMode);
      },
    );
  }
}
