import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/game_controller.dart';
import '../../domain/entities.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final league = ref.watch(gameControllerProvider).league;

    // Récupère les joueurs clients de l'agent
    final clientPlayers = league.players
        .where((p) => league.agent.clients.contains(p.id))
        .toList()
      ..sort((a, b) => b.overall.compareTo(a.overall));

    return Scaffold(
      appBar: AppBar(title: const Text('Mes clients')),
      body: clientPlayers.isEmpty
          ? const Center(child: Text('Aucun client pour le moment.'))
          : ListView.separated(
        itemCount: clientPlayers.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final p = clientPlayers[i];
          final teamLabel = () {
            if (p.teamId == null) return 'FA (Libre)';
            final t = league.teams.firstWhere((t) => t.id == p.teamId);
            return '${t.city} ${t.name}';
          }();

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: _PosBadge(p.pos),
              title: Text('${p.name} • OVR ${p.overall}'),
              subtitle: Text('$teamLabel • ${p.age} ans'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PlayerDetailsScreen(playerId: p.id)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class PlayerDetailsScreen extends ConsumerWidget {
  const PlayerDetailsScreen({super.key, required this.playerId});
  final int playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final league = ref.watch(gameControllerProvider).league;
    final p = league.players.firstWhere((x) => x.id == playerId);
    final teamLabel = () {
      if (p.teamId == null) return 'FA (Libre)';
      final t = league.teams.firstWhere((t) => t.id == p.teamId);
      return '${t.city} ${t.name}';
    }();

    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              _PosBadge(p.pos, big: true),
              const SizedBox(width: 12),
              Text('OVR ${p.overall}',
                  style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 12),
          Text('Âge : ${p.age}'),
          Text('Équipe : $teamLabel'),
          Text('Potentiel : ${p.potential}'),
          Text('Forme : ${p.form >= 0 ? '+${p.form}' : p.form}'),
          Text('Exigence salariale (est.) : ${_fmtMoney(_salaryAsk(p))}/an'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctions à venir (offres, objectifs...)')),
              );
            },
            icon: const Icon(Icons.work_outline),
            label: const Text('Actions à venir'),
          ),
        ],
      ),
    );
  }
}

class _PosBadge extends StatelessWidget {
  const _PosBadge(this.pos, {this.big = false});
  final Pos pos;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final size = big ? 44.0 : 32.0;
    return CircleAvatar(
      radius: size / 2,
      child: Text(
        pos.name,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: big ? 14 : 12),
      ),
    );
  }
}

// helpers minimalistes (mêmes formules que dans advance_week)
int _salaryAsk(Player p) {
  final base = (p.overall * p.overall * 4000);
  final formFactor = 1 + (p.form * 0.02);
  final market = 1 + (p.marketability * 0.004);
  return (base * formFactor * market).toInt();
}

String _fmtMoney(int n) {
  final s = n.abs().toString();
  final withSpaces =
  s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  return (n < 0 ? '-€' : '€') + withSpaces;
}
