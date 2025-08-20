import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/game_controller.dart';
import '../../domain/entities.dart';
import '../negotiation/negotiation_screen.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    
    if (game.league == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Offres')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final league = game.league!;
    final clientIds = league.agent.clients.toSet();
    final clientOffers = league.offers
        .where((o) => clientIds.contains(o.playerId))
        .where((o) => o.expiresWeek > league.week - 1)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Offres – Mes clients')),
      body: clientOffers.isEmpty
          ? const Center(child: Text('Aucune offre pour tes clients.'))
          : ListView.separated(
        itemCount: clientOffers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final o = clientOffers[i];
          final p = league.players.firstWhere((x) => x.id == o.playerId);
          final t = league.teams.firstWhere((x) => x.id == o.teamId);

          return ListTile(
            leading: const Icon(Icons.mark_chat_read_outlined),
            title: Text('${p.name} (${p.pos.name})'),
            subtitle: Text(
              '${t.city} ${t.name} • ${o.salary ~/ 1000}k€/an x${o.years} • exp. S${o.expiresWeek}',
            ),
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
