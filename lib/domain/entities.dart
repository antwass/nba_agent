enum Pos { PG, SG, SF, PF, C }

class Player {
  int id;
  String name;
  int age;
  Pos pos;
  int overall;
  int potential;
  int form;        // -10..+10
  double greed;    // 0..1
  int marketability; // 0..100
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
  int salary;
  int years;
  int bonus;
  Offer({
    required this.teamId,
    required this.playerId,
    required this.salary,
    required this.years,
    this.bonus = 0,
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
  LeagueState({
    required this.week,
    required this.players,
    required this.teams,
    required this.agent,
  });
}
