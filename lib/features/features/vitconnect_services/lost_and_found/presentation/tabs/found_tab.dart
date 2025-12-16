import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/lost_found_provider.dart';
import '../../widgets/lost_found_grid_card.dart';
import '../../widgets/lost_found_detail_dialog.dart';
import '../../widgets/empty_state.dart';

/// Found items tab
class FoundTab extends StatelessWidget {
  final String searchQuery;

  const FoundTab({super.key, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    return Consumer<LostFoundProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var foundItems = provider.foundItems;

        // Filter by search query
        if (searchQuery.isNotEmpty) {
          foundItems =
              foundItems.where((item) {
                return item.itemName.toLowerCase().contains(searchQuery) ||
                    item.place.toLowerCase().contains(searchQuery) ||
                    (item.description?.toLowerCase().contains(searchQuery) ??
                        false);
              }).toList();
        }

        if (foundItems.isEmpty) {
          return LostFoundEmptyState(
            message:
                searchQuery.isEmpty
                    ? 'No found items reported yet'
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
          itemCount: foundItems.length,
          itemBuilder: (context, index) {
            final item = foundItems[index];
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
