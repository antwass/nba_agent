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
  // 1. CRÉER UNE COPIE PROFONDE DE L'ÉTAT
  final leagueCopy = league.deepCopy();

  // 2. APPLIQUER LES MODIFICATIONS SUR LA COPIE
  final c = Contract(
    playerId: offer.playerId,
    teamId: offer.teamId,
    salaryPerYear: List.filled(agreedYears, agreedSalary),
    signingBonus: agreedBonus,
    startWeek: leagueCopy.week,
  );
  leagueCopy.contracts.add(c);

  final team = leagueCopy.teams.firstWhere((t) => t.id == offer.teamId);
  final player = leagueCopy.players.firstWhere((p) => p.id == offer.playerId);
  player.teamId = team.id;
  team.roster.add(player.id);
  team.capUsed += agreedSalary; // MVP: année 1

  final commission = (agreedSalary * commissionRate).round();
  leagueCopy.agent.cash += commission;

  leagueCopy.ledger.add(FinanceEntry(
    week: leagueCopy.week,
    label: 'Commission: ${player.name} (${agreedYears} an${agreedYears > 1 ? "s" : ""})',
    amount: commission,
  ));

  leagueCopy.offers.removeWhere((o) => o.playerId == player.id);

  final summary =
      '${player.name} signe ${agreedYears} ans à ${agreedSalary ~/ 1000}k€ (bonus ${agreedBonus ~/ 1000}k). '
      'Commission +$commission€';
  leagueCopy.recentEvents = [summary];

  // 3. RETOURNER LA COPIE MODIFIÉE
  return SignResult(leagueCopy, c, summary);
}
