// lib/features/start/start_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/game_calendar.dart';
import '../home/game_controller.dart';
import '../home/home_screen.dart';

import 'save_service.dart';
import 'save_game_meta.dart';

/// Slot de sauvegarde courant
final currentSlotIdProvider = StateProvider<String?>((ref) => null);

/// Services & liste des slots
final saveServiceProvider = Provider((ref) => SaveService());
final slotsProvider = FutureProvider<List<SaveGameMeta>>(
      (ref) => ref.read(saveServiceProvider).loadSlots(),
);

class StartScreen extends ConsumerWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(slotsProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Arrière-plan doux (gradient) – pas d'asset requis
          const _BackgroundGradient(),

          // Contenu
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Titre/logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_basketball,
                          size: 36,
                          color: Theme.of(context).colorScheme.onPrimary),
                      const SizedBox(width: 10),
                      Text(
                        'NBA Agent',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Menu',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onPrimary
                            .withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const Spacer(),

                  // CTA principaux
                  slots.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                        child: Text('Erreur: $e',
                            style: const TextStyle(color: Colors.white))),
                    data: (list) => Column(
                      children: [
                        _PrimaryButton(
                          label: 'Nouvelle partie',
                          icon: Icons.add,
                          onPressed: () => _createNewGame(context, ref),
                          filled: true,
                        ),
                        const SizedBox(height: 12),
                        _PrimaryButton(
                          label: 'Continuer',
                          icon: Icons.play_arrow,
                          onPressed:
                          list.isNotEmpty ? () => _enterGame(context, ref, list.first) : null,
                          filled: false,
                        ),
                        const SizedBox(height: 24),

                        // Feuille "Mes parties"
                        _SavesSheet(slots: list, onPlay: (slot) {
                          _enterGame(context, ref, slot);
                        }, onDelete: (slot) async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Supprimer cette partie ?'),
                              content: Text(slot.name),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Annuler'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await ref.read(saveServiceProvider).deleteSlot(slot.id);
                            ref.invalidate(slotsProvider);
                          }
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createNewGame(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController(text: 'Agent');
    final slotId = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nouvelle partie'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: "Nom de l'agent"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              'slot-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999)}',
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    if (slotId == null) return;

    // 1) créer le monde
    await ref.read(gameControllerProvider.notifier)
        .newGame(agentName: nameCtrl.text.trim().isEmpty ? 'Agent' : nameCtrl.text.trim());

    // 2) meta initiale
    final gameState = ref.read(gameControllerProvider);
    final meta = SaveGameMeta(
      id: slotId,
      name: nameCtrl.text.trim().isEmpty ? 'Agent' : nameCtrl.text.trim(),
      week: gameState.league?.week ?? 1,
      updatedAt: DateTime.now(),
    );
    await ref.read(saveServiceProvider).upsertSlot(meta);
    ref.invalidate(slotsProvider);

    // 3) mémoriser le slot + naviguer
    ref.read(currentSlotIdProvider.notifier).state = slotId;
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  void _enterGame(BuildContext context, WidgetRef ref, SaveGameMeta slot) async {
    // Essayer de charger la sauvegarde
    await ref.read(gameControllerProvider.notifier).loadGame(slot.id);
    
    // Si pas de sauvegarde trouvée, créer une nouvelle partie
    if (ref.read(gameControllerProvider).league == null) {
      await ref.read(gameControllerProvider.notifier).newGame(agentName: slot.name);
    }
    
    ref.read(currentSlotIdProvider.notifier).state = slot.id;
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }
}

/// --- Widgets de présentation ---

class _BackgroundGradient extends StatelessWidget {
  const _BackgroundGradient();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.primary, c.primary.withValues(alpha: 0.6), c.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.filled,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final bg = filled ? c.primaryContainer : Colors.white.withValues(alpha: 0.85);
    final fg = filled ? c.onPrimaryContainer : Colors.black87;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: fg),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(label, style: TextStyle(color: fg, fontSize: 18)),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: filled ? 2 : 0,
        ),
      ),
    );
  }
}

class _SavesSheet extends StatelessWidget {
  const _SavesSheet({
    required this.slots,
    required this.onPlay,
    required this.onDelete,
  });

  final List<SaveGameMeta> slots;
  final void Function(SaveGameMeta slot) onPlay;
  final void Function(SaveGameMeta slot) onDelete;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: c.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mes parties', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (slots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(child: Text('Aucune partie. Crée ta première !')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: slots.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final s = slots[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.save_outlined),
                    title: Text(s.name),
                    subtitle: Text('${GameCalendar.weekToDisplay(s.week)} • ${_fmtDate(s.updatedAt)}'),
                    trailing: Wrap(
                      spacing: 6,
                      children: [
                        TextButton(onPressed: () => onPlay(s), child: const Text('Jouer')),
                        IconButton(
                          onPressed: () => onDelete(s),
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Supprimer',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
    // (on branchera intl ensuite si tu veux un format localisé)
  }
}
