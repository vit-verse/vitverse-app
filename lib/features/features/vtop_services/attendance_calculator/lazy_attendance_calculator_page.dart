import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/loading/loading_messages.dart';
import 'logic/attendance_calculator_provider.dart';
import 'presentation/attendance_calculator_page.dart';

class LazyAttendanceCalculatorPage extends StatefulWidget {
  const LazyAttendanceCalculatorPage({super.key});

  @override
  State<LazyAttendanceCalculatorPage> createState() =>
      _LazyAttendanceCalculatorPageState();
}

class _LazyAttendanceCalculatorPageState
    extends State<LazyAttendanceCalculatorPage> {
  late Future<AttendanceCalculatorProvider> _providerFuture;

  @override
  void initState() {
    super.initState();
    _providerFuture = _initializeProvider();
  }

  Future<AttendanceCalculatorProvider> _initializeProvider() async {
    final provider = AttendanceCalculatorProvider();
    await provider.initialize();
    return provider;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AttendanceCalculatorProvider>(
      future: _providerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    LoadingMessages.getMessage('attendance_calculator'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }

        return ChangeNotifierProvider<AttendanceCalculatorProvider>.value(
          value: snapshot.data!,
          child: const AttendanceCalculatorPage(),
        );
      },
    );
  }
}
