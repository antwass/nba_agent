import '../entities.dart';

class SignResult {
  final LeagueState league;
  final Contract contract;
  final String summary;
  SignResult(this.league, this.contract, this.summary);
}

SignResult signContract({
  required LeagueState league,
  required Offer offer,
  required int agreedSalary,
  required int agreedYears,
  required int agreedBonus,
  required double commissionRate, // ex: 0.07
}) {
  // 1) Créer le contrat
  final c = Contract(
    playerId: offer.playerId,
    teamId: offer.teamId,
    salaryPerYear: List.filled(agreedYears, agreedSalary),
    signingBonus: agreedBonus,
    startWeek: league.week,
  );
  league.contracts.add(c);

  // 2) Mettre à jour team & player
  final team = league.teams.firstWhere((t) => t.id == offer.teamId);
  final player = league.players.firstWhere((p) => p.id == offer.playerId);
  player.teamId = team.id;
  team.roster.add(player.id);
  team.capUsed += agreedSalary; // MVP: année 1

  // 3) Commission
  final commission = (agreedSalary * commissionRate).round();
  league.agent.cash += commission;

  // 3bis) ✨ Ledger (journal)
  league.ledger.add(FinanceEntry(
    week: league.week,
    label: 'Commission: ${player.name} (${agreedYears} an${agreedYears > 1 ? "s" : ""})',
    amount: commission,
  ));

  // 4) Nettoyer les offres de ce joueur
  league.offers.removeWhere((o) => o.playerId == player.id);

  // 5) Résumé
  final summary =
      '${player.name} signe ${agreedYears} ans à ${agreedSalary ~/ 1000}k€ (bonus ${agreedBonus ~/ 1000}k). '
      'Commission +$commission€';
  league.recentEvents = [summary];

  return SignResult(league, c, summary);
}
