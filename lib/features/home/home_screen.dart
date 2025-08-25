import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/game_calendar.dart';
import '../../domain/entities.dart' show NotificationType, GameNotification;
import 'game_controller.dart';
import '../start/start_screen.dart' show currentSlotIdProvider, saveServiceProvider;
import '../start/save_game_meta.dart';
import '../clients/clients_screen.dart';
import '../market/market_screen.dart';
import '../negotiation/offers_screen.dart';
import '../finance/finance_screen.dart';

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
        week: ref.read(gameControllerProvider).league?.week ?? 1,
        updatedAt: DateTime.now(),
      );
      await svc.upsertSlot(meta);
    }

    // 3) sauvegarde automatique
    try {
      await ref.read(gameControllerProvider.notifier).saveGame();
      // Feedback avec mention de la sauvegarde
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semaine suivante... ✅ Sauvegarde auto'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Erreur sauvegarde auto: $e');
      // Fallback sans sauvegarde
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Semaine suivante...')));
      }
    }
  }

  Future<void> nextMonthWithAutosave(BuildContext context, WidgetRef ref) async {
    // Avancer 4 semaines d'un coup
    for (int i = 0; i < 4; i++) {
      ref.read(gameControllerProvider.notifier).nextWeek();
    }

    // Autosave meta du slot courant
    final slotId = ref.read(currentSlotIdProvider);
    if (slotId != null) {
      final svc = ref.read(saveServiceProvider);
      final meta = SaveGameMeta(
        id: slotId,
        name: 'Agent',
        week: ref.read(gameControllerProvider).league?.week ?? 1,
        updatedAt: DateTime.now(),
      );
      await svc.upsertSlot(meta);
    }

    // Sauvegarde automatique
    try {
      await ref.read(gameControllerProvider.notifier).saveGame();
      if (context.mounted) {
        final week = ref.read(gameControllerProvider).league?.week ?? 1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Un mois s\'est écoulé – ${GameCalendar.weekToDisplay(week)} ✅ Sauvegarde auto')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final week = ref.read(gameControllerProvider).league?.week ?? 1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Un mois s\'est écoulé – ${GameCalendar.weekToDisplay(week)}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final game = ref.watch(gameControllerProvider);
    
    // Écran de chargement si league n'est pas encore initialisé
    if (game.isLoading || game.league == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(game.lastSummary.isNotEmpty ? game.lastSummary : 'Chargement...'),
            ],
          ),
        ),
      );
    }
    
    final league = game.league!;
    final isFAWindow = GameCalendar.getPhase(league.week) == "Free Agency";

    return Scaffold(
      appBar: AppBar(
        title: const Text('NBA Agent - Accueil'),
        centerTitle: true,
        actions: [
          // Bouton de sauvegarde
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Sauvegarder',
            onPressed: () async {
              try {
                await ref.read(gameControllerProvider.notifier).saveGame();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('✅ Partie sauvegardée'),
                      backgroundColor: Colors.green[700],
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Erreur sauvegarde: $e'),
                      backgroundColor: Colors.red[700],
                    ),
                  );
                }
              }
            },
          ),
          // Bouton paramètres (optionnel pour plus tard)
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Paramètres',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paramètres à venir')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Contenu principal avec padding bottom pour les boutons
          Positioned.fill(
            child: Column(
              children: [
                if (isFAWindow)
                  const _BannerInfo(
                    text: 'Fenêtre Free Agency ouverte - attendez plus d\'offres !',
                    icon: Icons.campaign_outlined,
                  ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Padding bottom pour les boutons
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header stats
                        _HeaderStats(
                          week: league.week,
                          cash: league.agent.cash,
                          reputation: league.agent.reputation,
                          clients: league.agent.clients.length,
                        ),
                        const SizedBox(height: 16),
                        
                        // Notifications collapsibles
                        _CompactNotifications(
                          notifications: league.notifications
                              .where((n) => n.week >= league.week - 4)
                              .toList()
                            ..sort((a, b) => b.week.compareTo(a.week)),
                          onNotificationTap: (notification) {
                            if (notification.type == NotificationType.offerReceived && 
                                notification.relatedOfferId != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const OffersScreen()),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Grille des 4 boutons d'action
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.6,
                          children: [
                            _ActionCard(
                              icon: Icons.people_alt_outlined,
                              title: 'Mes clients',
                              subtitle: 'Statut, humeur, contrats',
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientsScreen())),
                            ),
                            _ActionCard(
                              icon: Icons.store_mall_directory_outlined,
                              title: 'Marché',
                              subtitle: 'Free agents & intérêts',
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketScreen())),
                            ),
                            _ActionCard(
                              icon: Icons.mark_chat_read_outlined,
                              title: 'Offres',
                              subtitle: 'Négocier et signer',
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersScreen())),
                              badgeCount: league.notifications.where((n) => 
                                n.type == NotificationType.offerReceived && !n.isRead).length,
                            ),
                            _ActionCard(
                              icon: Icons.stacked_line_chart_outlined,
                              title: 'Finances',
                              subtitle: 'Commissions & dépenses',
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FinanceScreen())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // News du marché collapsibles
                        _CompactMarketNews(
                          marketNews: league.marketNews.take(10).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Boutons flottants positionnés en bas
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FilledButton.tonalIcon(
                      onPressed: () => nextMonthWithAutosave(context, ref),
                      icon: const Icon(Icons.fast_forward),
                      label: const Text('Mois suivant'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: FilledButton.icon(
                      onPressed: () => nextWeekWithAutosave(context, ref),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Semaine suivante'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

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
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OffersScreen()),
            );
          } else if (i == 4) {
            Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FinanceScreen()),
            );
          } else {
            // i == 0 => Accueil (déjà dessus)
          }
        },
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Accueil'),
          const NavigationDestination(icon: Icon(Icons.people_outline), label: 'Clients'),
          const NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Marché'),
          NavigationDestination(
            icon: Badge(
              label: Text('${league.notifications.where((n) => 
                n.type == NotificationType.offerReceived && !n.isRead).length}'),
              isLabelVisible: league.notifications.any((n) => 
                n.type == NotificationType.offerReceived && !n.isRead),
              child: const Icon(Icons.mark_chat_read_outlined),
            ),
            label: 'Offres',
          ),
          const NavigationDestination(icon: Icon(Icons.attach_money_outlined), label: 'Finances'),
        ],
      ),
    );
  }
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  GameCalendar.weekToDisplay(week),
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(width: 8),
                Text(
                  '${GameCalendar.getYear(week)}',
                  style: textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    GameCalendar.getPhase(week),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Saison ${GameCalendar.getSeason(week)}',
                  style: textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
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


class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badgeCount;

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
              Stack(
                children: [
                  Icon(icon, size: 28),
                  if (badgeCount > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
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



class _CompactNotifications extends StatefulWidget {
  const _CompactNotifications({
    required this.notifications,
    required this.onNotificationTap,
  });
  
  final List<GameNotification> notifications;
  final Function(GameNotification) onNotificationTap;
  
  @override
  State<_CompactNotifications> createState() => _CompactNotificationsState();
}

class _CompactNotificationsState extends State<_CompactNotifications> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    final unreadCount = widget.notifications.where((n) => !n.isRead).length;
    
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (!_isExpanded && widget.notifications.isNotEmpty)
                    Text(
                      '${widget.notifications.length} total',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Contenu collapsible vers le BAS
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1),
                Container(
                  constraints: const BoxConstraints(maxHeight: 150),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.notifications.length,
                    itemBuilder: (context, i) {
                      final notif = widget.notifications[i];
                      return InkWell(
                        onTap: () => widget.onNotificationTap(notif),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.mail_outline,
                                color: notif.isRead ? Colors.grey : Colors.blue,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  notif.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: notif.isRead ? FontWeight.normal : FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (!notif.isRead)
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(left: 4),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            crossFadeState: _isExpanded 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

class _CompactMarketNews extends StatefulWidget {
  const _CompactMarketNews({required this.marketNews});
  final List<String> marketNews;
  
  @override
  State<_CompactMarketNews> createState() => _CompactMarketNewsState();
}

class _CompactMarketNewsState extends State<_CompactMarketNews> {
  bool _isExpanded = false;
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'News du marché',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600
                    ),
                  ),
                  const Spacer(),
                  if (!_isExpanded && widget.marketNews.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${widget.marketNews.length}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Contenu collapsible
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.marketNews.isEmpty)
                        Text(
                          'Aucune actualité du marché',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        ...widget.marketNews.take(5).map((news) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.fiber_manual_record, size: 6),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  news,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        )),
                      if (widget.marketNews.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '... et ${widget.marketNews.length - 5} autres',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            crossFadeState: _isExpanded 
              ? CrossFadeState.showSecond 
              : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
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
