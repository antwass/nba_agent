import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/game_controller.dart';
import '../../domain/entities.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final league = ref.watch(gameControllerProvider).league;

    final entries = [...league.ledger]
      ..sort((a, b) => b.week.compareTo(a.week)); // plus récents en haut

    final total = entries.fold<int>(0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Finances')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    label: 'Trésorerie',
                    value: _fmtMoney(league.agent.cash),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    label: 'Total commissions',
                    value: _fmtMoney(total),
                    icon: Icons.trending_up_outlined,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('Aucun mouvement pour l’instant.'))
                : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = entries[i];
                return ListTile(
                  leading: Icon(
                    e.amount >= 0 ? Icons.add_circle_outline : Icons.remove_circle_outline,
                  ),
                  title: Text(e.label),
                  subtitle: Text('Semaine ${e.week}'),
                  trailing: Text(
                    (e.amount >= 0 ? '+ ' : '- ') + _fmtMoney(e.amount.abs()),
                    style: TextStyle(
                      color: e.amount >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ],
        ),
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
