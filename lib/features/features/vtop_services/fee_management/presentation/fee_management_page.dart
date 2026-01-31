import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/database/entities/receipt.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../core/loading/loading_messages.dart';
import '../../../../../firebase/analytics/analytics_service.dart';
import '../logic/fee_logic.dart';
import '../widgets/fee_management_widgets.dart';

class FeeManagementPage extends StatefulWidget {
  const FeeManagementPage({super.key});

  @override
  State<FeeManagementPage> createState() => _FeeManagementPageState();
}

class _FeeManagementPageState extends State<FeeManagementPage> {
  final FeeLogic _logic = FeeLogic();

  List<Receipt> _receipts = [];
  FeeSummary? _feeSummary;

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'Fee Management',
      screenClass: 'FeeManagementPage',
    );
    _loadFeeData();
  }

  Future<void> _loadFeeData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final receipts = await _logic.loadAllReceipts(sortByDateDesc: true);
      final summary = await _logic.calculateFeeSummary();

      setState(() {
        _receipts = receipts;
        _feeSummary = summary;
        _isLoading = false;
      });

      Logger.d('FeeManagementPage', 'Loaded ${receipts.length} receipts');
    } catch (e) {
      setState(() {
        _error = 'Failed to load fee data';
        _isLoading = false;
      });
      Logger.e('FeeManagementPage', 'Error loading fee data', e);
      if (mounted) {
        SnackbarUtils.error(context, 'Failed to load fee data');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.text,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Fee Management',
          style: TextStyle(
            color: theme.text,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(dynamic theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.primary),
            const SizedBox(height: 16),
            Text(
              LoadingMessages.getMessage('fees'),
              style: TextStyle(color: theme.muted, fontSize: 14),
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
              color: theme.muted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: theme.text, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadFeeData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_receipts.isEmpty) {
      return const EmptyReceiptsState();
    }

    return RefreshIndicator(
      onRefresh: _loadFeeData,
      color: theme.primary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FeeSummaryCard(summary: _feeSummary!, logic: _logic),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Receipts',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${_receipts.length} ${_receipts.length == 1 ? 'receipt' : 'receipts'}',
                    style: TextStyle(color: theme.muted, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final receipt = _receipts[index];
                return ReceiptCard(receipt: receipt, logic: _logic);
              }, childCount: _receipts.length),
            ),
          ),
        ],
      ),
    );
  }
}
