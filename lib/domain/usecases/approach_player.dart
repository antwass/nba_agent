import 'dart:math';
import '../entities.dart';

class ApproachResult {
  final LeagueState league;
  final bool success;
  final String message;
  final int reputationChange;
  
  ApproachResult({
    required this.league,
    required this.success,
    required this.message,
    this.reputationChange = 0,
  });
}

ApproachResult approachPlayer({
  required LeagueState league,
  required int playerId,
}) {
  final leagueCopy = league.deepCopy();
  final player = leagueCopy.players.firstWhere((p) => p.id == playerId);
  final agent = leagueCopy.agent;
  
  // Vérifications
  if (player.representativeId != null) {
    return ApproachResult(
      league: leagueCopy,
      success: false,
      message: '${player.name} a déjà un agent.',
    );
  }
  
  if (agent.clients.length >= 10) {
    return ApproachResult(
      league: leagueCopy,
      success: false,
      message: 'Vous avez atteint la limite de 10 clients.',
    );
  }
  
  // Calcul de probabilité amélioré
  final probability = calculateApproachProbability(
    reputation: agent.reputation,
    playerOverall: player.overall,
    playerPotential: player.potential,
  );
  
  // Bonus/Malus selon le nombre de clients actuels
  double clientBonus = 0;
  if (agent.clients.isEmpty) {
    clientBonus = 0.10; // Premier client plus facile
  } else if (agent.clients.length >= 8) {
    clientBonus = -0.10; // Plus dur quand presque plein
  }
  
  final finalProbability = (probability + clientBonus).clamp(0.05, 0.95);
  
  // Lancer de dés
  final roll = Random().nextDouble();
  
  if (roll < finalProbability) {
    // Succès !
    player.representativeId = 1; // ID de l'agent (simplifié)
    agent.clients.add(player.id);
    agent.reputation = (agent.reputation + 1).clamp(0, 100);
    
    return ApproachResult(
      league: leagueCopy,
      success: true,
      message: '${player.name} accepte de devenir votre client !',
      reputationChange: 1,
    );
  } else {
    // Échec
    agent.reputation = (agent.reputation - 0).clamp(0, 100);
    
    return ApproachResult(
      league: leagueCopy,
      success: false,
      message: '${player.name} refuse votre offre.',
      reputationChange: 0,
    );
  }
}

double calculateApproachProbability({
  required int reputation,
  required int playerOverall,
  int? playerPotential,
}) {
  // Facteur de réputation (0.1 à 1.0)
  final reputationFactor = (reputation / 100.0).clamp(0.1, 1.0);
  
  // Difficulté basée sur l'overall du joueur
  // 60-69 OVR : très facile (0.9)
  // 70-79 OVR : facile (0.7)
  // 80-84 OVR : moyen (0.5)
  // 85-89 OVR : difficile (0.3)
  // 90+ OVR : très difficile (0.15)
  
  double difficultyFactor;
  if (playerOverall < 70) {
    difficultyFactor = 0.9;
  } else if (playerOverall < 80) {
    difficultyFactor = 0.7;
  } else if (playerOverall < 85) {
    difficultyFactor = 0.5;
  } else if (playerOverall < 90) {
    difficultyFactor = 0.3;
  } else {
    difficultyFactor = 0.15;
  }
  
  // Bonus si le potentiel est élevé par rapport à l'overall (joueur en devenir)
  double potentialBonus = 0;
  if (playerPotential != null && playerPotential > playerOverall) {
    final gap = playerPotential - playerOverall;
    if (gap > 10) {
      potentialBonus = 0.15; // Jeune talent avec gros potentiel
    } else if (gap > 5) {
      potentialBonus = 0.10;
    } else {
      potentialBonus = 0.05;
    }
  }
  
  // Calcul final
  final probability = (reputationFactor * difficultyFactor + potentialBonus).clamp(0.05, 0.95);
  
  return probability;
}