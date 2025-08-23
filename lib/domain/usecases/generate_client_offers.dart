import 'dart:math';
import '../entities.dart';
import '../../core/game_calendar.dart';

// Génère des offres pour les clients de l'agent selon la phase de la saison
void generateOffersForClients(LeagueState league, Random rng) {
  final phase = GameCalendar.getPhase(league.week);
  
  // Pas d'offres pendant les playoffs ou l'intersaison
  if (phase == "Playoffs" || phase == "Intersaison") return;
  
  if (phase == "Free Agency") {
    _generateFAOffersForClients(league, rng);
  } else if (phase == "Saison régulière" || phase == "Pré-saison") {
    _generateExtensionOffers(league, rng);
    _generateTradeRumors(league, rng);
  }
}

// Génère des offres pour les clients Free Agents
void _generateFAOffersForClients(LeagueState league, Random rng) {
  for (final clientId in league.agent.clients) {
    final player = league.players.firstWhere((p) => p.id == clientId);
    
    // Skip si le joueur est déjà sous contrat
    if (player.teamId != null) continue;
    
    // Nombre d'offres basé sur l'OVR du joueur
    int offerCount = 0;
    double offerChance = 0;
    
    if (player.overall >= 90) {
      offerCount = 2 + rng.nextInt(2);  // 2-3 offres
      offerChance = 0.9;
    } else if (player.overall >= 85) {
      offerCount = 1 + rng.nextInt(2);  // 1-2 offres
      offerChance = 0.7;
    } else if (player.overall >= 80) {
      offerCount = rng.nextInt(2);      // 0-1 offre
      offerChance = 0.5;
    } else if (player.overall >= 75) {
      offerCount = rng.nextInt(2);      // 0-1 offre
      offerChance = 0.3;
    } else {
      offerChance = 0.15;
      if (rng.nextDouble() < offerChance) offerCount = 1;
    }
    
    // Sélectionner des équipes intéressées
    final interestedTeams = league.teams
        .where((t) => t.roster.length < 15)
        .toList()
      ..shuffle(rng);
    
    for (int i = 0; i < offerCount && i < interestedTeams.length; i++) {
      final team = interestedTeams[i];

      // VÉRIFICATION : L'équipe a-t-elle déjà une offre pour ce joueur ?
      final bool alreadyHasOffer = league.offers.any(
        (existingOffer) => 
            existingOffer.teamId == team.id && 
            existingOffer.playerId == player.id
      );

      if (alreadyHasOffer) continue; // Passe à l'équipe suivante si une offre existe déjà
      
      // Calculer l'offre basée sur l'OVR
      final baseSalary = player.overall * player.overall * 4000;
      final variance = 0.85 + (rng.nextDouble() * 0.3);  // 85% à 115%
      final salary = (baseSalary * variance).round();
      
      // Durée du contrat selon l'âge
      int years;
      if (player.age <= 25) {
        years = 3 + rng.nextInt(2);  // 3-4 ans pour les jeunes
      } else if (player.age <= 30) {
        years = 2 + rng.nextInt(2);  // 2-3 ans
      } else {
        years = 1 + rng.nextInt(2);  // 1-2 ans pour les vétérans
      }
      
      final bonus = (salary * 0.1 * rng.nextDouble()).round();
      
      league.offers.add(Offer(
        teamId: team.id,
        playerId: player.id,
        salary: salary,
        years: years,
        bonus: bonus,
        createdWeek: league.week,
        expiresWeek: league.week + 2,
      ));
      
      // Notification personnelle
      league.notifications.add(GameNotification(
        id: 'offer_${player.id}_${team.id}_${league.week}',
        type: NotificationType.offerReceived,
        title: 'Nouvelle offre pour ${player.name}',
        message: '${team.city} ${team.name} propose ${salary ~/ 1000000}M€/an sur $years ans',
        week: league.week,
        relatedPlayerId: player.id,
        relatedOfferId: league.offers.length - 1,
      ));
      
      // News globale du marché (visible par tous)
      league.marketNews.add(
        '💼 ${team.name} fait une offre à ${player.name}'
      );
    }
  }
}

// Génère des offres d'extension pour les clients en dernière année
void _generateExtensionOffers(LeagueState league, Random rng) {
  for (final clientId in league.agent.clients) {
    final player = league.players.firstWhere((p) => p.id == clientId);
    
    // Skip si pas sous contrat
    if (player.teamId == null) continue;
    
    // Vérifier si c'est sa dernière année (simplifié pour le MVP)
    // Pour le MVP, on fait une extension random avec 20% de chance
    if (rng.nextDouble() < 0.20) {
      final team = league.teams.firstWhere((t) => t.id == player.teamId);

      // VÉRIFICATION : L'équipe a-t-elle déjà une offre pour ce joueur ?
      final bool alreadyHasOffer = league.offers.any(
        (existingOffer) => 
            existingOffer.teamId == team.id && 
            existingOffer.playerId == player.id
      );

      if (alreadyHasOffer) return; // Ne pas créer d'offre d'extension si une existe déjà
      
      // Extension généralement moins que la valeur marché
      final marketValue = player.overall * player.overall * 4000;
      final extensionSalary = (marketValue * 0.9).round();  // 90% de la valeur
      final years = 2 + rng.nextInt(2);  // 2-3 ans
      
      league.offers.add(Offer(
        teamId: team.id,
        playerId: player.id,
        salary: extensionSalary,
        years: years,
        bonus: 0,  // Pas de bonus sur les extensions généralement
        createdWeek: league.week,
        expiresWeek: league.week + 4,  // Plus de temps pour décider
      ));
      
      // Notification personnelle pour extension
      league.notifications.add(GameNotification(
        id: 'extension_${player.id}_${team.id}_${league.week}',
        type: NotificationType.extensionOffer,
        title: 'Offre d\'extension pour ${player.name}',
        message: '${team.name} propose une extension de ${extensionSalary ~/ 1000000}M€/an sur $years ans',
        week: league.week,
        relatedPlayerId: player.id,
        relatedOfferId: league.offers.length - 1,
      ));
      
      // News du marché
      league.marketNews.add(
        '📝 ${team.name} négocie une extension avec ${player.name}'
      );
    }
  }
}

// Génère des RUMEURS de trade (pas des trades effectifs)
void _generateTradeRumors(LeagueState league, Random rng) {
  // 10% de chance d'avoir une rumeur par semaine
  if (rng.nextDouble() > 0.10) return;
  
  // Sélectionner un client sous contrat au hasard
  final clientsUnderContract = league.agent.clients
      .map((id) => league.players.firstWhere((p) => p.id == id))
      .where((p) => p.teamId != null)
      .toList();
      
  if (clientsUnderContract.isEmpty) return;
  
  final player = clientsUnderContract[rng.nextInt(clientsUnderContract.length)];
  final currentTeam = league.teams.firstWhere((t) => t.id == player.teamId);
  
  // Choisir une équipe destination potentielle
  final otherTeams = league.teams.where((t) => t.id != player.teamId).toList();
  final targetTeam = otherTeams[rng.nextInt(otherTeams.length)];
  
  // Créer la rumeur (1 à 4 semaines avant un potentiel trade)
  final weeksBeforeTrade = 1 + rng.nextInt(4);
  
  // Notification personnelle pour rumeur de trade
  league.notifications.add(GameNotification(
    id: 'trade_rumor_${player.id}_${targetTeam.id}_${league.week}',
    type: NotificationType.tradeRumor,
    title: 'Rumeur de trade : ${player.name}',
    message: '${currentTeam.name} discuteraient avec ${targetTeam.name}',
    week: league.week,
    relatedPlayerId: player.id,
  ));
  
  // News du marché
  league.marketNews.add(
    '🔄 Rumeur: ${currentTeam.name} et ${targetTeam.name} discutent d\'un échange'
  );
  
  // Note: Pour le MVP, on ne fait pas le trade réel, juste la rumeur
  // Dans une V2, on pourrait stocker cette rumeur et la concrétiser plus tard
}