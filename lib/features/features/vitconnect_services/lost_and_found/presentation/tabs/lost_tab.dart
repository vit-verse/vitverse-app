import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/lost_found_provider.dart';
import '../../widgets/lost_found_grid_card.dart';
import '../../widgets/lost_found_detail_dialog.dart';
import '../../widgets/empty_state.dart';

/// Lost items tab
class LostTab extends StatelessWidget {
  final String searchQuery;

  const LostTab({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    return Consumer<LostFoundProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var lostItems = provider.lostItems;

        // Filter by search query
        if (searchQuery.isNotEmpty) {
          lostItems =
              lostItems.where((item) {
                return item.itemName.toLowerCase().contains(searchQuery) ||
                    item.place.toLowerCase().contains(searchQuery) ||
                    (item.description?.toLowerCase().contains(searchQuery) ??
                        false);
              }).toList();
        }

        if (lostItems.isEmpty) {
          return LostFoundEmptyState(
            message:
                searchQuery.isEmpty
                    ? 'No lost items reported yet'
                    : 'No items match your search',
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: lostItems.length,
          itemBuilder: (context, index) {
            final item = lostItems[index];
            return LostFoundGridCard(
              item: item,
              onTap: () => LostFoundDetailDialog.show(context, item),
            );
          },
        );
      },
    );
  }
}
