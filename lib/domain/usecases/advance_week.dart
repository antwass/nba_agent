// lib/domain/usecases/advance_week.dart
import 'dart:math';
import '../entities.dart';
import '../../core/game_calendar.dart';
import 'generate_client_offers.dart';
import '../../core/id_generator.dart';

class AdvanceWeekResult {
  final LeagueState league;
  final int newWeek;
  final int offersGenerated;
  final List<String> events;
  AdvanceWeekResult(this.league, this.newWeek, this.offersGenerated, this.events);
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
  final leagueCopy = s.deepCopy();
  final r = rng ?? Random(leagueCopy.week);
  final events = <String>[];

  // 1) Progression légère (placeholder)
  for (final p in leagueCopy.players) {
    final delta = ((p.potential - p.overall) / 200.0) + (p.form * 0.02);
    p.overall = (p.overall + delta).clamp(40, 99).round();
  }

  // 2) Expirer les offres arrivées à terme
  leagueCopy.offers.removeWhere((o) => o.expiresWeek <= leagueCopy.week);

  // 3) Générer de nouvelles offres
  //    Boost pendant la fenêtre FA (semaines 18..28)
  final faBoost = (leagueCopy.week >= 18 && leagueCopy.week <= 28) ? 5 : 2;
  int generated = 0;

  final teamsShuffled = [...leagueCopy.teams]..shuffle(r);
  final freeAgents = leagueCopy.players.where((p) => p.teamId == null).toList()
    ..sort((a, b) => b.overall.compareTo(a.overall));

  for (final team in teamsShuffled.take(faBoost)) {
    // Poste le moins fourni
    final depth = _teamDepth(leagueCopy, team);
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

    leagueCopy.offers.add(Offer(
      id: IdGenerator.nextOfferId(),
      teamId: team.id,
      playerId: candidate.id,
      salary: salary,
      years: years,
      bonus: bonus,
      createdWeek: leagueCopy.week,
      expiresWeek: leagueCopy.week + 2,
    ));
    generated++;
  }

  // 4) Expiration automatique des news après 4 semaines
  leagueCopy.marketNews.removeWhere((news) => leagueCopy.week - news.week >= 4);
  
  // 5) Événements du marché
  if (generated > 0) {
    leagueCopy.marketNews.add(MarketNewsEntry(
      week: leagueCopy.week,
      message: '📊 $generated nouvelles offres sur le marché cette semaine'
    ));
  }
  if (r.nextDouble() < 0.20) {
    leagueCopy.marketNews.add(MarketNewsEntry(
      week: leagueCopy.week,
      message: '💬 Rumeur: Les équipes cherchent des meneurs cette semaine'
    ));
  }

  // Générer des offres pour les clients de l'agent
  generateOffersForClients(leagueCopy, r);

  // 6) Avancer le temps + publier les events
  leagueCopy.week += 1;
  
  // Vérifier les événements spéciaux
  final specialEvent = GameCalendar.getSpecialEvent(leagueCopy.week);
  if (specialEvent != null) {
    leagueCopy.marketNews.insert(0, MarketNewsEntry(
      week: leagueCopy.week,
      message: specialEvent
    ));  // Mettre en premier
  }
  
  // Événement spécial nouvelle année
  if (GameCalendar.isNewYear(leagueCopy.week)) {
    leagueCopy.marketNews.add(MarketNewsEntry(
      week: leagueCopy.week,
      message: "🎊 Bonne année ${GameCalendar.getYear(leagueCopy.week)} !"
    ));
  }
  
  // Événement nouvelle saison
  if (GameCalendar.isNewSeason(leagueCopy.week)) {
    leagueCopy.marketNews.add(MarketNewsEntry(
      week: leagueCopy.week,
      message: "📅 Nouvelle saison NBA ${GameCalendar.getSeason(leagueCopy.week)} commence !"
    ));
  }
  
  // Faire vieillir les joueurs une fois par an (semaine 52)
  if ((leagueCopy.week - 1) % 52 == 51) {
    for (final p in leagueCopy.players) {
      p.age += 1;
      // Décliner les vieux joueurs
      if (p.age >= 34) {
        p.overall = (p.overall - 2).clamp(60, 99);
      }
    }
    leagueCopy.marketNews.add(MarketNewsEntry(
      week: leagueCopy.week,
      message: "📆 Les joueurs ont vieilli d'un an"
    ));
  }
  
  // Adapter la génération d'offres selon la phase
  if (GameCalendar.getPhase(leagueCopy.week) == "Intersaison") {
    // Pas d'offres pendant l'intersaison
    generated = 0;
  }
  
  leagueCopy.recentEvents = events;

  return AdvanceWeekResult(leagueCopy, leagueCopy.week, generated, events);
}
