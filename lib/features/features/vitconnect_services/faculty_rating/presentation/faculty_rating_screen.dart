import 'package:flutter/material.dart';
import '../../../../../../core/loading/loading_messages.dart';
import '../../../../../../core/utils/logger.dart';
import '../../../../../../core/utils/snackbar_utils.dart';
import '../bloc/faculty_rating_bloc.dart';
import '../bloc/faculty_rating_state.dart';
import '../models/faculty_model.dart';
import '../widgets/faculty_card.dart';
import 'rate_faculty_screen.dart';

class FacultyRatingScreen extends StatefulWidget {
  const FacultyRatingScreen({super.key});

  @override
  State<FacultyRatingScreen> createState() => _FacultyRatingScreenState();
}

class _FacultyRatingScreenState extends State<FacultyRatingScreen> {
  static const String _tag = 'FacultyRatingScreen';
  late FacultyRatingBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = FacultyRatingBloc();
    _bloc.addListener(_onBlocStateChanged);
    _loadFaculties();
  }

  @override
  void dispose() {
    _bloc.removeListener(_onBlocStateChanged);
    _bloc.dispose();
    super.dispose();
  }

  void _onBlocStateChanged() {
    if (!mounted) return;
    final state = _bloc.state;

    if (state is RatingSubmissionSuccess) {
      SnackbarUtils.success(context, state.message);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _bloc.loadFaculties(forceRefresh: true);
      });
    } else if (state is RatingSubmissionFailure) {
      SnackbarUtils.error(context, state.message);
    }
  }

  Future<void> _loadFaculties() async {
    try {
      await _bloc.loadFaculties(forceRefresh: false);
    } catch (e) {
      Logger.e(_tag, 'Error loading faculties', e);
    }
  }

  Future<void> _refreshFaculties() async {
    try {
      await _bloc.refreshRatings(forceRefresh: true);
    } catch (e) {
      Logger.e(_tag, 'Error refreshing faculties', e);
    }
  }

  void _navigateToRateFaculty(Faculty faculty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RateFacultyScreen(faculty: faculty, bloc: _bloc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faculty Ratings'),
        centerTitle: false,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _bloc,
        builder: (context, _) {
          final state = _bloc.state;

          if (state is FacultyRatingLoading) {
            return _buildLoadingView();
          }

          if (state is FacultyRatingError) {
            return _buildErrorView(state);
          }

          if (state is FacultyRatingLoaded) {
            return _buildLoadedView(state);
          }

          return _buildLoadingView();
        },
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            LoadingMessages.getMessage('faculty_rating'),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(FacultyRatingError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (state.error != null) ...[
              const SizedBox(height: 8),
              Text(
                state.error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadFaculties,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedView(FacultyRatingLoaded state) {
    if (state.faculties.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No Faculties Found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Make sure you have courses added in your timetable',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadFaculties,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshFaculties,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.faculties.length,
        itemBuilder: (context, index) {
          final faculty = state.faculties[index];
          final isRefreshingThis =
              state.refreshingFacultyId == faculty.facultyId;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: FacultyCard(
              faculty: faculty,
              onRatePressed: () => _navigateToRateFaculty(faculty),
              isRefreshing: isRefreshingThis,
            ),
          );
        },
      ),
    );
  }
}
