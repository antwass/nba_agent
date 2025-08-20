import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities.dart';
import '../../domain/usecases/sign_contract.dart';
import '../../domain/usecases/negotiate_contract.dart';
import '../home/game_controller.dart';

class NegotiationScreen extends ConsumerStatefulWidget {
  const NegotiationScreen({super.key, required this.offer});
  final Offer offer;

  @override
  ConsumerState<NegotiationScreen> createState() => _NegotiationScreenState();
}

class _NegotiationScreenState extends ConsumerState<NegotiationScreen> {
  late double salary;
  late double bonus;
  late int years;
  
  late NegotiationEngine engine;
  List<NegotiationRound> rounds = [];
  int roundCount = 0;
  bool dealClosed = false;

  @override
  void initState() {
    super.initState();
    salary = widget.offer.salary.toDouble();
    bonus  = widget.offer.bonus.toDouble();
    years  = widget.offer.years;
    
    final league = ref.read(gameControllerProvider).league!;
    final player = league.players.firstWhere((x) => x.id == widget.offer.playerId);
    final team = league.teams.firstWhere((x) => x.id == widget.offer.teamId);
    
    engine = NegotiationEngine(player: player, team: team);
    
    // Première offre de l'équipe
    rounds.add(NegotiationRound(
      salary: widget.offer.salary,
      years: widget.offer.years,
      bonus: widget.offer.bonus,
      isPlayerOffer: false,
      message: "Voici notre offre initiale.",
    ));
  }

  double _acceptProb(Player p) {
    // Estimation très simple : mieux que l'offre de base => monte la proba
    final ask = (p.overall * p.overall * 4000);
    final delta = (salary - ask) / ask;
    final base = 0.5 + delta * 0.9 - 0.2 * p.greed; // greed baisse la proba
    return base.clamp(0.05, 0.98);
  }

  void _submitOffer() {
    if (dealClosed || roundCount >= 3) return;
    
    setState(() {
      roundCount++;
      
      // Évaluation de l'offre
      final score = engine.evaluateOffer(salary.round(), years, bonus.round());
      
      if (score > 0.75 || roundCount >= 3) {
        // Offre acceptée !
        dealClosed = true;
        rounds.add(NegotiationRound(
          salary: salary.round(),
          years: years,
          bonus: bonus.round(),
          isPlayerOffer: false,
          message: "Deal accepté ! Félicitations !",
        ));
      } else if (score < 0.4) {
        // Offre refusée, négociation terminée
        dealClosed = true;
        rounds.add(NegotiationRound(
          salary: salary.round(),
          years: years,
          bonus: bonus.round(),
          isPlayerOffer: false,
          message: "L'écart est trop important. Négociation terminée.",
        ));
      } else {
        // Contre-offre
        final counter = engine.generateCounterOffer(
          salary.round(), 
          years, 
          bonus.round()
        );
        rounds.add(counter);
        
        // Mise à jour des sliders avec la contre-offre
        salary = counter.salary.toDouble();
        years = counter.years;
        bonus = counter.bonus.toDouble();
      }
    });
  }

  void _finalizeContract() {
    final res = signContract(
      league: ref.read(gameControllerProvider).league!,
      offer: widget.offer,
      agreedSalary: salary.round(),
      agreedYears: years,
      agreedBonus: bonus.round(),
      commissionRate: 0.07,
    );
    ref.read(gameControllerProvider.notifier).refreshAfterSign(res.summary);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(gameControllerProvider);
    
    if (game.league == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Négociation')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    final league = game.league!;
    final p = league.players.firstWhere((x) => x.id == widget.offer.playerId);
    final prob = _acceptProb(p);

    return Scaffold(
      appBar: AppBar(title: const Text('Négociation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${p.name} (${p.pos.name}) • OVR ${p.overall}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text('Offre initiale: ${widget.offer.salary ~/ 1000}k€/an • ${widget.offer.years} ans'),
          const SizedBox(height: 12),

          // Historique de négociation
          if (rounds.isNotEmpty) ...[
            Card(
              child: Column(
                children: rounds.map((r) => ListTile(
                  leading: Icon(r.isPlayerOffer ? Icons.person : Icons.business),
                  title: Text('${r.salary ~/ 1000}k€/an × ${r.years} ans'),
                  subtitle: Text(r.message),
                  dense: true,
                )).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          _SliderTile(
            label: 'Salaire/an',
            value: salary,
            min: widget.offer.salary * 0.8,
            max: widget.offer.salary * 1.2,
            onChanged: (v) => setState(() => salary = v),
            formatter: (v) => '${v.round()} €',
          ),
          _SliderTile(
            label: 'Bonus signature',
            value: bonus,
            min: 0,
            max: widget.offer.salary * 0.2,
            onChanged: (v) => setState(() => bonus = v),
            formatter: (v) => '${v.round()} €',
          ),
          Row(
            children: [
              const Text('Durée'),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: years,
                items: [1,2,3,4]
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y ans')))
                    .toList(),
                onChanged: (v) => setState(() => years = v ?? years),
              ),
            ],
          ),

          const SizedBox(height: 12),
          LinearProgressIndicator(value: prob),
          const SizedBox(height: 4),
          Text('Probabilité estimée: ${(prob * 100).round()}%'),

          const SizedBox(height: 16),
          if (!dealClosed) ...[
            FilledButton.icon(
              onPressed: roundCount < 3 ? _submitOffer : null,
              icon: const Icon(Icons.send),
              label: Text(roundCount == 0 ? 'Proposer' : 'Contre-proposer (${3-roundCount} restant)'),
            ),
          ] else if (rounds.last.message.contains('accepté')) ...[
            FilledButton.icon(
              onPressed: _finalizeContract,
              icon: const Icon(Icons.check),
              label: const Text('Signer le contrat'),
            ),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Refuser'),
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.formatter,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String Function(double) formatter;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$label : ${formatter(value)}'),
            Slider(value: value, min: min, max: max, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
