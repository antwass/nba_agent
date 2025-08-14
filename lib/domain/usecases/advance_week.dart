// lib/domain/usecases/advance_week.dart
import 'dart:math';
import '../entities.dart';

class AdvanceWeekResult {
  final int newWeek;
  final int offersGenerated;
  final List<String> events;
  AdvanceWeekResult(this.newWeek, this.offersGenerated, this.events);
}

/// Estimation simple de l'ask salaire d'un joueur (MVP)
int _salaryAsk(Player p) {
  final base = (p.overall * p.overall * 4000); // courbe convexe
  final formFactor = 1 + (p.form * 0.02);      // -20% .. +20% max
  final market = 1 + (p.marketability * 0.004); // 0..+40% max
  return (base * formFactor * market).toInt();
}

/// Comptage des joueurs par poste dans une équipe
Map<Pos, int> _teamDepth(LeagueState s, Team t) {
  final depth = {for (var pos in Pos.values) pos: 0};
  for (final pid in t.roster) {
    final p = s.players.firstWhere((x) => x.id == pid);
    depth[p.pos] = depth[p.pos]! + 1;
  }
  return depth;
}

/// Choisit un FA pour un poste donné; sinon premier FA; sinon null.
Player? _pickCandidate(List<Player> fa, Pos pos) {
  for (final p in fa) {
    if (p.pos == pos) return p;
  }
  return fa.isNotEmpty ? fa.first : null;
}

AdvanceWeekResult advanceWeek(LeagueState s, {Random? rng}) {
  final r = rng ?? Random(s.week);
  final events = <String>[];

  // 1) Progression légère (placeholder)
  for (final p in s.players) {
    final delta = ((p.potential - p.overall) / 200.0) + (p.form * 0.02);
    p.overall = (p.overall + delta).clamp(40, 99).round();
  }

  // 2) Expirer les offres arrivées à terme
  s.offers.removeWhere((o) => o.expiresWeek <= s.week);

  // 3) Générer de nouvelles offres
  //    Boost pendant la fenêtre FA (semaines 18..28)
  final faBoost = (s.week >= 18 && s.week <= 28) ? 5 : 2;
  int generated = 0;

  final teamsShuffled = [...s.teams]..shuffle(r);
  final freeAgents = s.players.where((p) => p.teamId == null).toList()
    ..sort((a, b) => b.overall.compareTo(a.overall));

  for (final team in teamsShuffled.take(faBoost)) {
    // Poste le moins fourni
    final depth = _teamDepth(s, team);
    final needPos = (Pos.values.toList()
      ..sort((a, b) => (depth[a]!).compareTo(depth[b]!)))
        .first;

    final candidate = _pickCandidate(freeAgents, needPos);
    if (candidate == null) break; // plus de FA disponibles

    final ask = _salaryAsk(candidate);

    // Cap simplifié: 150M; headroom restant pour offrir
    const cap = 150000000;
    final headroom = cap - team.capUsed;
    if (headroom <= 0) continue;

    final salary = min(
      ask,
      max(1_000_000, (headroom * (0.4 + r.nextDouble() * 0.6)).toInt()),
    );
    final years = 1 + r.nextInt(4);
    final bonus = (salary * (0.05 + r.nextDouble() * 0.10)).toInt();

    s.offers.add(Offer(
      teamId: team.id,
      playerId: candidate.id,
      salary: salary,
      years: years,
      bonus: bonus,
      createdWeek: s.week,
      expiresWeek: s.week + 2,
    ));
    generated++;
  }

  // 4) Événements
  if (generated > 0) events.add('$generated nouvelles offres au marché.');
  if (r.nextDouble() < 0.20) {
    events.add('Rumeurs: besoin de meneurs cette semaine.');
  }

  // 5) Avancer le temps + publier les events
  s.week += 1;
  s.recentEvents = events;

  return AdvanceWeekResult(s.week, generated, events);
}
