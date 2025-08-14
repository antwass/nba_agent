import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'game_controller.dart';
import '../start/start_screen.dart' show currentSlotIdProvider, saveServiceProvider;
import '../start/save_game_meta.dart';
import '../clients/clients_screen.dart';
import '../market/market_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  // Méthode de classe (pas de _ pour éviter le warning local)
  Future<void> nextWeekWithAutosave(BuildContext context, WidgetRef ref) async {
    // 1) avancer la semaine
    ref.read(gameControllerProvider.notifier).nextWeek();

    // 2) autosave meta du slot courant (si on vient d'un slot)
    final slotId = ref.read(currentSlotIdProvider);
    if (slotId != null) {
      final svc = ref.read(saveServiceProvider);
      final meta = SaveGameMeta(
        id: slotId,
        name: 'Agent', // TODO: stocker nom dans LeagueState.agent si tu veux l’afficher
        week: ref.read(gameControllerProvider).league.week,
        updatedAt: DateTime.now(),
      );
      await svc.upsertSlot(meta);
    }

    // 3) petit feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Semaine suivante…')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    final isFAWindow = (game.league.week >= 18 && game.league.week <= 28);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NBA Agent — Accueil'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          if (isFAWindow)
            const SliverToBoxAdapter(
              child: _BannerInfo(
                text: 'Fenêtre Free Agency ouverte — attendez plus d’offres !',
                icon: Icons.campaign_outlined,
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderStats(
                    week: game.league.week,
                    cash: game.league.agent.cash,
                    reputation: game.league.agent.reputation,
                    clients: game.league.agent.clients.length,
                  ),
                  const SizedBox(height: 16),
                  if (game.lastSummary.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          game.lastSummary,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _QuickActions(
                    onOpenClients: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ClientsScreen()),
                      );
                    },
                    onOpenMarket: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MarketScreen()),
                      );
                    },
                    onOpenOffers: () => _todo(context, 'Offres'),
                    onOpenFinance: () => _todo(context, 'Finances'),
                  ),
                  const SizedBox(height: 16),
                  Text('Événements récents',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _RecentEvents(items: game.league.recentEvents),
                  const SizedBox(height: 80), // espace pour le FAB
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FilledButton.icon(
        onPressed: () => nextWeekWithAutosave(context, ref),
        icon: const Icon(Icons.fast_forward),
        label: const Text('Semaine suivante'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // ✅ Un SEUL onDestinationSelected qui gère tous les cas
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          if (i == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientsScreen()),
            );
          } else if (i == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MarketScreen()),
            );
          } else if (i == 3) {
            _todo(context, 'Finances');
          } else {
            // i == 0 => Accueil (déjà dessus)
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Clients'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Marché'),
          NavigationDestination(icon: Icon(Icons.attach_money_outlined), label: 'Finances'),
        ],
      ),
    );
  }
}

void _todo(BuildContext ctx, String label) {
  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$label — bientôt')));
}

class _BannerInfo extends StatelessWidget {
  const _BannerInfo({required this.text, required this.icon});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _HeaderStats extends StatelessWidget {
  const _HeaderStats({
    required this.week,
    required this.cash,
    required this.reputation,
    required this.clients,
  });

  final int week;
  final int cash;
  final int reputation;
  final int clients;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Semaine $week', style: textTheme.headlineMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatChip(icon: Icons.account_balance_wallet, label: _fmtMoney(cash)),
            _StatChip(icon: Icons.star_rate_rounded, label: 'Réputation $reputation'),
            _StatChip(icon: Icons.person, label: 'Clients $clients'),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onOpenClients,
    required this.onOpenMarket,
    required this.onOpenOffers,
    required this.onOpenFinance,
  });

  final VoidCallback onOpenClients;
  final VoidCallback onOpenMarket;
  final VoidCallback onOpenOffers;
  final VoidCallback onOpenFinance;

  @override
  Widget build(BuildContext context) {
    return GridView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.6,
      ),
      children: [
        _ActionCard(
          icon: Icons.people_alt_outlined,
          title: 'Mes clients',
          subtitle: 'Statut, humeur, contrats',
          onTap: onOpenClients,
        ),
        _ActionCard(
          icon: Icons.store_mall_directory_outlined,
          title: 'Marché',
          subtitle: 'Free agents & intérêts',
          onTap: onOpenMarket,
        ),
        _ActionCard(
          icon: Icons.mark_chat_read_outlined,
          title: 'Offres',
          subtitle: 'Négocier et signer',
          onTap: onOpenOffers,
        ),
        _ActionCard(
          icon: Icons.stacked_line_chart_outlined,
          title: 'Finances',
          subtitle: 'Commissions & dépenses',
          onTap: onOpenFinance,
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentEvents extends StatelessWidget {
  const _RecentEvents({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Aucun événement récent. Avance la semaine !',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return Card(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemBuilder: (_, i) => ListTile(
          dense: true,
          leading: const Icon(Icons.fiber_manual_record, size: 12),
          title: Text(items[i]),
        ),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: items.length,
      ),
    );
  }
}

String _fmtMoney(int n) {
  final s = n.abs().toString();
  final withSpaces =
  s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');
  return (n < 0 ? '-€' : '€') + withSpaces;
}
