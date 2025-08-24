import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/game_calendar.dart';
import '../home/game_controller.dart';
import '../../domain/entities.dart';
import '../negotiation/negotiation_screen.dart';

class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({super.key});

  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen> {
  @override
  void initState() {
    super.initState();
    // Marquer comme lues les notifications liées aux offres
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gameControllerProvider.notifier).markOfferNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final WidgetRef ref = this.ref;
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
        .where((o) => o.expiresWeek >= league.week)
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${t.city} ${t.name} • ${o.salary ~/ 1000}k€/an x${o.years}'),
                if (p.teamId == null)
                  Text(
                    'Free Agent • Commission: ${(o.salary * 0.07) ~/ 1000}k€',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 12,
                    ),
                  )
                else if (p.teamId == o.teamId)
                  Text(
                    'Extension • Commission: ${(o.salary * 0.05) ~/ 1000}k€',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                Text(
                  'Expire: ${GameCalendar.weekToDisplay(o.expiresWeek)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
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
