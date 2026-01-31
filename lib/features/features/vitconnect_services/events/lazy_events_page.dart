import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/events_page.dart';
import 'logic/events_provider.dart';
import 'data/events_repository.dart';
import 'data/events_vitverse_service.dart';
import '../../../../supabase/core/supabase_events_client.dart';
import '../../../../core/database_vitverse/database.dart';

class LazyEventsPage extends StatelessWidget {
  const LazyEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) => EventsProvider(
            EventsRepository(
              SupabaseEventsClient.client,
              EventsVitverseService(VitVerseDatabase.instance),
            ),
          ),
      child: const EventsPage(),
    );
  }
}
