import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:munch_or_dump/core/widgets/async_states.dart';
import 'package:munch_or_dump/core/widgets/editorial.dart';
import 'package:munch_or_dump/features/cart/cart_controller.dart';
import 'package:munch_or_dump/features/cart/cart_widgets.dart';

/// Past shopping trips: the score trajectory plus every saved trip (expandable
/// to its verdict breakdown and item list, deletable).
class CartHistoryScreen extends ConsumerWidget {
  const CartHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trips = ref.watch(cartControllerProvider).savedTrips;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: GridBackground(
        child: SafeArea(
          top: false,
          child: trips.isEmpty
              ? const EmptyState(
                  icon: Icons.history,
                  message: 'No saved trips yet.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  children: <Widget>[
                    const Eyebrow('Past trips', spacing: 3.6),
                    const SizedBox(height: 16),
                    CartTrajectory(trips: trips),
                    const SizedBox(height: 20),
                    for (final trip in trips)
                      SavedTripCard(key: ValueKey<String>(trip.id), trip: trip),
                  ],
                ),
        ),
      ),
    );
  }
}
