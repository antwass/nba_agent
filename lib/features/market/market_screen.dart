import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/game_controller.dart';
import '../negotiation/negotiation_screen.dart';
import '../../domain/entities.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final league = ref.watch(gameControllerProvider).league;
    final currentWeekOffers = league.offers.where((o) => o.createdWeek >= league.week - 1).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Marché')),
      body: currentWeekOffers.isEmpty
          ? const Center(child: Text('Aucune offre récente. Avance la semaine.'))
          : ListView.separated(
        itemCount: currentWeekOffers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final o = currentWeekOffers[i];
          final p = league.players.firstWhere((x) => x.id == o.playerId);
          final t = league.teams.firstWhere((x) => x.id == o.teamId);
          return ListTile(
            leading: const Icon(Icons.local_offer_outlined),
            title: Text('${p.name} (${p.pos.name}) • ${o.salary ~/ 1000}k€/an x${o.years}'),
            subtitle: Text('De: ${t.city} ${t.name} • expire S${o.expiresWeek}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NegotiationScreen(offer: o)),
              );
            },
          );
        },
      ),
    );
  }
}
