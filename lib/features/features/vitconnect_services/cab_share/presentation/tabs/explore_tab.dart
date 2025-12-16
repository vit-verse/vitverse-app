import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../../core/theme/theme_provider.dart';
import '../../../../../../core/widgets/themed_lottie_widget.dart';
import '../../logic/cab_ride_provider.dart';
import '../../models/cab_ride.dart';
import '../../widgets/cab_ride_card.dart';

/// Explore tab - shows all available rides grouped by date
class ExploreTab extends StatelessWidget {
  final String searchQuery;
  final Map<String, String>? filters;

  const ExploreTab({super.key, required this.searchQuery, this.filters});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;
    final provider = Provider.of<CabRideProvider>(context);

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Apply filters and search
    List<CabRide> rides = provider.allRides;

    // Apply search query
    if (searchQuery.isNotEmpty) {
      rides =
          rides.where((ride) {
            return ride.fromLocation.toLowerCase().contains(searchQuery) ||
                ride.toLocation.toLowerCase().contains(searchQuery) ||
                ride.postedByName.toLowerCase().contains(searchQuery) ||
                ride.cabType.toLowerCase().contains(searchQuery);
          }).toList();
    }

    // Apply filters
    if (filters != null) {
      if (filters!['from'] != null && filters!['from']!.isNotEmpty) {
        rides =
            rides.where((ride) {
              return ride.fromLocation.toLowerCase().contains(
                filters!['from']!.toLowerCase(),
              );
            }).toList();
      }
      if (filters!['to'] != null && filters!['to']!.isNotEmpty) {
        rides =
            rides.where((ride) {
              return ride.toLocation.toLowerCase().contains(
                filters!['to']!.toLowerCase(),
              );
            }).toList();
      }
      if (filters!['date'] != null && filters!['date']!.isNotEmpty) {
        rides =
            rides.where((ride) {
              return ride.dateKey == filters!['date'];
            }).toList();
      }
    }

    if (rides.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ThemedLottieWidget(
              assetPath: 'assets/lottie/cabshare.lottie',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty || (filters != null && filters!.isNotEmpty)
                  ? 'No rides found matching your filters'
                  : 'No rides available',
              style: TextStyle(
                fontSize: 16,
                color: theme.text.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Group rides by date
    final groupedRides = <String, List<CabRide>>{};
    for (final ride in rides) {
      final dateKey = ride.dateKey;
      if (!groupedRides.containsKey(dateKey)) {
        groupedRides[dateKey] = [];
      }
      groupedRides[dateKey]!.add(ride);
    }

    // Sort date keys
    final sortedDateKeys = groupedRides.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: sortedDateKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDateKeys[index];
        final dateRides = groupedRides[dateKey]!;
        final sampleRide = dateRides.first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: theme.primary),
                  const SizedBox(width: 8),
                  Text(
                    sampleRide.formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.primary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${dateRides.length} ${dateRides.length == 1 ? 'ride' : 'rides'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Rides grid (2 per row)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.35,
                crossAxisSpacing: 0,
                mainAxisSpacing: 0,
              ),
              itemCount: dateRides.length,
              itemBuilder: (context, rideIndex) {
                return CabRideCard(ride: dateRides[rideIndex]);
              },
            ),
          ],
        );
      },
    );
  }
}
