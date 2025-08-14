import '../entities.dart';

class SignResult {
  final Contract contract;
  final String summary;
  SignResult(this.contract, this.summary);
}

SignResult signContract({
  required LeagueState league,
  required Offer offer,
  required int agreedSalary,
  required int agreedYears,
  required int agreedBonus,
  required double commissionRate,
}) {
  final c = Contract(
    playerId: offer.playerId,
    teamId: offer.teamId,
    salaryPerYear: List.filled(agreedYears, agreedSalary),
    signingBonus: agreedBonus,
    startWeek: league.week,
  );
  league.contracts.add(c);

  final team = league.teams.firstWhere((t) => t.id == offer.teamId);
  final player = league.players.firstWhere((p) => p.id == offer.playerId);
  player.teamId = team.id;
  team.roster.add(player.id);
  team.capUsed += agreedSalary;

  final commission = (agreedSalary * commissionRate).round();
  league.agent.cash += commission;

  league.offers.removeWhere((o) => o.playerId == player.id);

  final summary =
      '${player.name} signe ${agreedYears} ans à ${agreedSalary ~/ 1000}k€ (bonus ${agreedBonus ~/ 1000}k). '
      'Commission +$commission€';
  league.recentEvents = [summary];

  return SignResult(c, summary);
}
