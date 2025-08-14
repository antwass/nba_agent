// lib/domain/entities.dart
enum Pos { PG, SG, SF, PF, C }

class Player {
  int id;
  String name;
  int age;
  Pos pos;
  int overall;        // 40..99
  int potential;      // 40..99
  int form;           // -10..+10
  double greed;       // 0..1
  int marketability;  // 0..100
  int? teamId;        // null => free agent

  Player({
    required this.id,
    required this.name,
    required this.age,
    required this.pos,
    required this.overall,
    required this.potential,
    this.form = 0,
    this.greed = 0.5,
    this.marketability = 50,
    this.teamId,
  });
}

class Team {
  int id;
  String name;
  String city;
  int capUsed;
  List<int> roster; // player ids

  Team({
    required this.id,
    required this.name,
    required this.city,
    this.capUsed = 0,
    List<int>? roster,
  }) : roster = roster ?? [];
}

class Offer {
  int teamId;
  int playerId;
  int salary;        // /an
  int years;         // 1..4
  int bonus;         // prime signature
  int createdWeek;
  int expiresWeek;

  Offer({
    required this.teamId,
    required this.playerId,
    required this.salary,
    required this.years,
    this.bonus = 0,
    required this.createdWeek,
    required this.expiresWeek,
  });
}

class Contract {
  int playerId;
  int teamId;
  List<int> salaryPerYear;
  int signingBonus;
  int startWeek;

  Contract({
    required this.playerId,
    required this.teamId,
    required this.salaryPerYear,
    required this.signingBonus,
    required this.startWeek,
  });
}

class AgentProfile {
  int cash;
  int reputation; // 0..100
  List<int> clients; // player ids
  AgentProfile({this.cash = 0, this.reputation = 10, List<int>? clients})
      : clients = clients ?? [];
}
class LeagueState {
  int week;
  List<Player> players;
  List<Team> teams;
  AgentProfile agent;

  List<Offer> offers;
  List<Contract> contracts;
  List<String> recentEvents;

  // 👇 nouveau : journal de mouvements financiers
  List<FinanceEntry> ledger;

  LeagueState({
    required this.week,
    required this.players,
    required this.teams,
    required this.agent,
    List<Offer>? offers,
    List<Contract>? contracts,
    List<String>? recentEvents,
    List<FinanceEntry>? ledger,
  })  : offers = offers ?? [],
        contracts = contracts ?? [],
        recentEvents = recentEvents ?? [],
        ledger = ledger ?? [];
}

class FinanceEntry {
  final int week;      // semaine où l’évènement a eu lieu
  final String label;  // ex: "Commission: J. Doe (2 ans)"
  final int amount;    // en € (positif = revenu, négatif = dépense)
  const FinanceEntry({required this.week, required this.label, required this.amount});
}
