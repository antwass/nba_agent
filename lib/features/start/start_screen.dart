import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'save_service.dart';
import 'save_game_meta.dart';
import '../home/game_controller.dart';
import '../home/home_screen.dart';

/// (1) Slot courant choisi
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
      appBar: AppBar(title: const Text('NBA Agent — Menu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: slots.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
          data: (list) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12, runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => _createNewGame(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle partie'),
                  ),
                  OutlinedButton.icon(
                    onPressed: list.isNotEmpty
                        ? () => _enterGame(context, ref, list.first)
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Continuer'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Mes parties', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Expanded(
                child: list.isEmpty
                    ? const Center(child: Text('Aucune partie. Crée ta première !'))
                    : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _SlotTile(
                    slot: list[i],
                    onPlay: () => _enterGame(context, ref, list[i]),
                    onDelete: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Supprimer cette partie ?'),
                          content: Text(list[i].name),
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
                        await ref.read(saveServiceProvider)
                            .deleteSlot(list[i].id);
                        ref.invalidate(slotsProvider);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
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
              context, 'slot-${DateTime.now().millisecondsSinceEpoch}',
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
    if (slotId == null) return;

    // 1) crée un monde neuf
    ref.read(gameControllerProvider.notifier)
        .newGame(agentName: nameCtrl.text.trim().isEmpty ? 'Agent' : nameCtrl.text.trim());

    // 2) enregistre la meta initiale
    final meta = SaveGameMeta(
      id: slotId,
      name: nameCtrl.text.trim().isEmpty ? 'Agent' : nameCtrl.text.trim(),
      week: ref.read(gameControllerProvider).league.week,
      updatedAt: DateTime.now(),
    );
    await ref.read(saveServiceProvider).upsertSlot(meta);
    ref.invalidate(slotsProvider);

    // 3) mémorise le slot courant + navigation vers le jeu
    ref.read(currentSlotIdProvider.notifier).state = slotId;
    if (context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  void _enterGame(BuildContext context, WidgetRef ref, SaveGameMeta slot) {
    ref.read(gameControllerProvider.notifier).newGame(agentName: slot.name);
    ref.read(currentSlotIdProvider.notifier).state = slot.id;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }
}

class _SlotTile extends StatelessWidget {
  const _SlotTile({required this.slot, required this.onPlay, required this.onDelete});
  final SaveGameMeta slot;
  final VoidCallback onPlay;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.save_outlined),
        title: Text(slot.name),
        subtitle: Text('Semaine ${slot.week} • ${slot.updatedAt.toLocal()}'),
        trailing: Wrap(spacing: 8, children: [
          TextButton(onPressed: onPlay, child: const Text('Jouer')),
          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
        ]),
      ),
    );
  }
}
