import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/game_controller.dart';
import '../../domain/entities.dart';
import '../negotiation/negotiation_screen.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  Pos? filterPos;

  @override
  Widget build(BuildContext context) {
    final league = ref.watch(gameControllerProvider).league;

    // Offres récentes (non expirées)
    final offers = league.offers
        .where((o) => o.expiresWeek > league.week - 1)
        .where((o) => filterPos == null
        ? true
        : league.players.firstWhere((p) => p.id == o.playerId).pos == filterPos)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marché'),
        actions: [
          PopupMenuButton<Pos?>(
            initialValue: filterPos,
            onSelected: (v) => setState(() => filterPos = v),
            itemBuilder: (_) => <PopupMenuEntry<Pos?>>[
              const PopupMenuItem(value: null, child: Text('Tous les postes')),
              ...Pos.values.map((p) => PopupMenuItem(value: p, child: Text(p.name))),
            ],
            icon: const Icon(Icons.filter_list),
          )
        ],
      ),
      body: offers.isEmpty
          ? const Center(
        child: Text('Aucune offre. Avance la semaine pour en générer.'),
      )
          : ListView.separated(
        itemCount: offers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final o = offers[i];
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
