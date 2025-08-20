import 'dart:math';
import '../entities.dart';

class NegotiationRound {
  final int salary;
  final int years;
  final int bonus;
  final bool isPlayerOffer;
  final String message;
  
  NegotiationRound({
    required this.salary,
    required this.years,
    required this.bonus,
    required this.isPlayerOffer,
    required this.message,
  });
}

class NegotiationState {
  final List<NegotiationRound> rounds;
  final bool isComplete;
  final bool dealAccepted;
  final int? finalSalary;
  final int? finalYears;
  final int? finalBonus;
  
  NegotiationState({
    this.rounds = const [],
    this.isComplete = false,
    this.dealAccepted = false,
    this.finalSalary,
    this.finalYears,
    this.finalBonus,
  });
}

class NegotiationEngine {
  final Player player;
  final Team team;
  final Random rng;
  
  NegotiationEngine({
    required this.player,
    required this.team,
    Random? random,
  }) : rng = random ?? Random();
  
  // Calcul de l'ask salarial du joueur
  int getPlayerSalaryDemand() {
    final base = (player.overall * player.overall * 4000);
    final formFactor = 1 + (player.form * 0.02);
    final marketFactor = 1 + (player.marketability * 0.004);
    final greedFactor = 1 + (player.greed * 0.3);
    
    return (base * formFactor * marketFactor * greedFactor).toInt();
  }
  
  // Le joueur évalue une offre
  double evaluateOffer(int salary, int years, int bonus) {
    final demand = getPlayerSalaryDemand();
    final salaryRatio = salary / demand;
    
    // Facteurs d'évaluation
    double score = 0;
    
    // Salaire (40% du score)
    score += salaryRatio * 0.4;
    
    // Durée (20% du score) - certains préfèrent long, d'autres court
    if (player.age < 28) {
      // Jeunes préfèrent contrats longs
      score += (years / 4.0) * 0.2;
    } else {
      // Vétérans préfèrent flexibilité
      score += ((5 - years) / 4.0) * 0.2;
    }
    
    // Bonus (20% du score)
    final bonusRatio = bonus / (salary * 0.2);
    score += bonusRatio * 0.2;
    
    // Situation de l'équipe (20% du score)
    final teamFactor = player.greed < 0.5 ? 0.2 : 0.1; // Moins cupides valorisent l'équipe
    score += teamFactor;
    
    // Ajustement selon la cupidité
    score = score * (1 - player.greed * 0.2);
    
    return score.clamp(0.0, 1.0);
  }
  
  // Génère une contre-offre du joueur
  NegotiationRound generateCounterOffer(int lastSalary, int lastYears, int lastBonus) {
    final demand = getPlayerSalaryDemand();
    
    // Le joueur ajuste ses demandes
    final salaryGap = demand - lastSalary;
    final newSalary = lastSalary + (salaryGap * 0.5).round(); // Rencontre à mi-chemin
    
    final newYears = player.age < 28 
      ? min(4, lastYears + 1)  // Jeunes veulent plus long
      : max(1, lastYears - 1);  // Vieux veulent plus court
      
    final newBonus = (newSalary * 0.15).round();
    
    return NegotiationRound(
      salary: newSalary,
      years: newYears,
      bonus: newBonus,
      isPlayerOffer: true,
      message: _generatePlayerMessage(lastSalary, newSalary),
    );
  }
  
  String _generatePlayerMessage(int lastOffer, int newDemand) {
    final gap = ((newDemand - lastOffer) / lastOffer * 100).round();
    
    if (gap > 30) {
      return "Cette offre est loin de mes attentes. Je vaux au moins ${newDemand ~/ 1000}k€/an.";
    } else if (gap > 15) {
      return "On se rapproche, mais j'espérais plutôt ${newDemand ~/ 1000}k€/an.";
    } else if (gap > 5) {
      return "C'est presque ça. ${newDemand ~/ 1000}k€/an et on a un deal.";
    } else {
      return "Très bien, acceptons ${newDemand ~/ 1000}k€/an.";
    }
  }
}