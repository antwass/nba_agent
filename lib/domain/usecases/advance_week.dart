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

/// Résout automatiquement les offres pour les joueurs non-clients
void _resolveNonClientOffers(LeagueState leagueCopy, Random rng) {
  // Identifier les offres expirantes pour les non-clients
  final nonClientExpiringOffers = leagueCopy.offers
      .where((o) => o.expiresWeek <= leagueCopy.week)
      .where((o) => !leagueCopy.agent.clients.contains(o.playerId))
      .toList();

  for (final offer in nonClientExpiringOffers) {
    final player = leagueCopy.players.firstWhere((p) => p.id == offer.playerId);
    
    // Logique de décision du joueur
    if (_playerAcceptsOffer(player, offer, rng)) {
      _signPlayerAutomatically(leagueCopy, offer, player);
      leagueCopy.marketNews.add(MarketNewsEntry(
        week: leagueCopy.week,
        message: '✍️ ${player.name} signe avec une équipe'
      ));
    } else {
      leagueCopy.marketNews.add(MarketNewsEntry(
        week: leagueCopy.week,
        message: '❌ ${player.name} refuse une offre'
      ));
    }
  }
}

/// Détermine si un joueur accepte une offre
bool _playerAcceptsOffer(Player player, Offer offer, Random rng) {
  // Calculer si l'offre est attractive pour le joueur
  final playerAsk = _salaryAsk(player);
  final offerRatio = offer.salary / playerAsk;
  
  // Probabilité d'acceptation basée sur l'attrait de l'offre
  double acceptanceProb = 0.3; // Base 30%
  
  if (offerRatio >= 1.2) acceptanceProb = 0.8;      // Très généreuse
  else if (offerRatio >= 1.0) acceptanceProb = 0.6; // Correcte
  else if (offerRatio >= 0.8) acceptanceProb = 0.4; // Acceptable
  else acceptanceProb = 0.2;                        // Faible
  
  // Facteur d'âge et cupidité
  if (player.age > 30) acceptanceProb += 0.1; // Vétérans moins difficiles
  acceptanceProb -= (player.greed * 0.2);     // Cupidité réduit l'acceptation
  
  return rng.nextDouble() < acceptanceProb.clamp(0.1, 0.9);
}

/// Vérifie et traite les expirations de contrats
void _checkContractExpirations(LeagueState league) {
  final contractsToExpire = <Contract>[];
  
  for (final contract in league.contracts) {
    // Calculer la fin du contrat : startWeek + (durée * 52 semaines)
    final contractEndWeek = contract.startWeek + (contract.salaryPerYear.length * 52);
    
    if (league.week >= contractEndWeek) {
      contractsToExpire.add(contract);
    }
  }
  
  for (final contract in contractsToExpire) {
    final player = league.players.firstWhere((p) => p.id == contract.playerId);
    final team = league.teams.firstWhere((t) => t.id == contract.teamId);
    
    // Libérer le joueur
    player.teamId = null;
    team.roster.remove(player.id);
    team.capUsed -= contract.salaryPerYear.isNotEmpty ? contract.salaryPerYear.first : 0;
    
    // News du marché pour les joueurs notables (75+ OVR)
    if (player.overall >= 75) {
      league.marketNews.add(MarketNewsEntry(
        week: league.week,
        message: '🆓 ${player.name} devient Free Agent (contrat expiré)'
      ));
    }
    
    // Notification si c'est un client de l'agent
    if (league.agent.clients.contains(player.id)) {
      league.notifications.add(GameNotification(
        id: 'contract_expired_${player.id}_${league.week}',
        type: NotificationType.contractExpired,
        title: 'Contrat expiré : ${player.name}',
        message: 'Le contrat avec ${team.name} a expiré. ${player.name} devient Free Agent.',
        week: league.week,
        relatedPlayerId: player.id,
      ));
    }
  }
  
  // Supprimer les contrats expirés
  league.contracts.removeWhere((c) => contractsToExpire.contains(c));
  
  if (contractsToExpire.isNotEmpty) {
    print('✅ ${contractsToExpire.length} contrats expirés à la semaine ${league.week}');
  }
}

/// Signe automatiquement un joueur avec une équipe
void _signPlayerAutomatically(LeagueState league, Offer offer, Player player) {
  final team = league.teams.firstWhere((t) => t.id == offer.teamId);
  
  // Créer le contrat
  final contract = Contract(
    playerId: offer.playerId,
    teamId: offer.teamId,
    salaryPerYear: List.filled(offer.years, offer.salary),
    signingBonus: offer.bonus,
    startWeek: league.week,
  );
  league.contracts.add(contract);
  
  // Assigner à l'équipe
  player.teamId = team.id;
  if (!team.roster.contains(player.id)) {
    team.roster.add(player.id);
  }
  team.capUsed += offer.salary;
  
  // Supprimer TOUTES les offres pour ce joueur (il n'est plus disponible)
  league.offers.removeWhere((o) => o.playerId == player.id);
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

  // 2) Vérifier l'expiration des contrats (mensuellement)
  if (leagueCopy.week % 4 == 0) {
    _checkContractExpirations(leagueCopy);
  }

  // 3) Résoudre automatiquement les offres pour les joueurs non-clients
  _resolveNonClientOffers(leagueCopy, r);
  
  // 4) Expirer les offres arrivées à terme (maintenant seulement celles des clients)
  leagueCopy.offers.removeWhere((o) => o.expiresWeek <= leagueCopy.week);

  // 5) Générer de nouvelles offres
  //    Boost pendant la fenêtre FA (semaines 1..12)
  final faBoost = (leagueCopy.week >= 1 && leagueCopy.week <= 12) ? 5 : 2;
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

  // 7) Avancer le temps + publier les events
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
