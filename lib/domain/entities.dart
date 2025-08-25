// lib/domain/entities.dart

enum Pos { PG, SG, SF, PF, C }

class Player {
  final int id;
  String name;
  int age;
  Pos pos;
  int overall;
  int potential;
  int form;
  double greed;
  int marketability;

  // Champs optionnels utiles au gameplay
  int? teamId;             // équipe actuelle dans ton monde fictif
  String? extId;           // id externe (id BDD NBA)
  int? representativeId;   // null = sans agent, sinon id de l’agent (toi)

  // Champ temporaire pour le world generator
  String? teamNameFromJson;

  Player({
    required this.id,
    required this.name,
    required this.age,
    required this.pos,
    required this.overall,
    required this.potential,
    required this.form,
    required this.greed,
    required this.marketability,
    this.teamId,
    this.extId,
    this.representativeId,
    this.teamNameFromJson,
  });

  Player copyWith({
    int? id,
    String? name,
    int? age,
    Pos? pos,
    int? overall,
    int? potential,
    int? form,
    double? greed,
    int? marketability,
    int? teamId,
    String? extId,
    int? representativeId,
    String? teamNameFromJson,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      pos: pos ?? this.pos,
      overall: overall ?? this.overall,
      potential: potential ?? this.potential,
      form: form ?? this.form,
      greed: greed ?? this.greed,
      marketability: marketability ?? this.marketability,
      teamId: teamId ?? this.teamId,
      extId: extId ?? this.extId,
      representativeId: representativeId ?? this.representativeId,
      teamNameFromJson: teamNameFromJson ?? this.teamNameFromJson,
    );
  }
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

  Team copyWith({
    int? id,
    String? name,
    String? city,
    int? capUsed,
    List<int>? roster,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      city: city ?? this.city,
      capUsed: capUsed ?? this.capUsed,
      roster: roster != null ? List.from(roster) : this.roster,
    );
  }
}

class Offer {
  int id;            // identifiant unique
  int teamId;
  int playerId;
  int salary;        // /an
  int years;         // 1..4
  int bonus;         // prime signature
  int createdWeek;
  int expiresWeek;

  Offer({
    required this.id,
    required this.teamId,
    required this.playerId,
    required this.salary,
    required this.years,
    this.bonus = 0,
    required this.createdWeek,
    required this.expiresWeek,
  });

  Offer copyWith({
    int? id,
    int? teamId,
    int? playerId,
    int? salary,
    int? years,
    int? bonus,
    int? createdWeek,
    int? expiresWeek,
  }) {
    return Offer(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      playerId: playerId ?? this.playerId,
      salary: salary ?? this.salary,
      years: years ?? this.years,
      bonus: bonus ?? this.bonus,
      createdWeek: createdWeek ?? this.createdWeek,
      expiresWeek: expiresWeek ?? this.expiresWeek,
    );
  }
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

  Contract copyWith({
    int? playerId,
    int? teamId,
    List<int>? salaryPerYear,
    int? signingBonus,
    int? startWeek,
  }) {
    return Contract(
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      salaryPerYear: salaryPerYear != null ? List.from(salaryPerYear) : this.salaryPerYear,
      signingBonus: signingBonus ?? this.signingBonus,
      startWeek: startWeek ?? this.startWeek,
    );
  }
}

class AgentProfile {
  int cash;
  int reputation; // 0..100
  List<int> clients; // player ids
  AgentProfile({this.cash = 0, this.reputation = 10, List<int>? clients})
      : clients = clients ?? [];

  AgentProfile copyWith({
    int? cash,
    int? reputation,
    List<int>? clients,
  }) {
    return AgentProfile(
      cash: cash ?? this.cash,
      reputation: reputation ?? this.reputation,
      clients: clients != null ? List.from(clients) : this.clients,
    );
  }
}
class LeagueState {
  int week;
  List<Player> players;
  List<Team> teams;
  AgentProfile agent;

  List<Offer> offers;
  List<Contract> contracts;
  List<String> recentEvents;  // Garde pour compatibilité

  // 👇 nouveau : journal de mouvements financiers
  List<FinanceEntry> ledger;
  
  // 👇 nouveau : système de notifications séparées
  List<GameNotification> notifications;  // Notifications personnelles
  List<MarketNewsEntry> marketNews;      // News globales du marché avec timestamp

  LeagueState({
    required this.week,
    required this.players,
    required this.teams,
    required this.agent,
    List<Offer>? offers,
    List<Contract>? contracts,
    List<String>? recentEvents,  // Garde pour compatibilité
    List<GameNotification>? notifications,
    List<MarketNewsEntry>? marketNews,
    List<FinanceEntry>? ledger,
  })  : offers = offers ?? [],
        contracts = contracts ?? [],
        recentEvents = recentEvents ?? [],  // Garde pour compatibilité
        notifications = notifications ?? [],
        marketNews = marketNews ?? [],
        ledger = ledger ?? [];

  LeagueState deepCopy() {
    return LeagueState(
      week: week,
      players: players.map((p) => p.copyWith()).toList(),
      teams: teams.map((t) => t.copyWith()).toList(),
      agent: agent.copyWith(),
      offers: offers.map((o) => o.copyWith()).toList(),
      contracts: contracts.map((c) => c.copyWith()).toList(),
      ledger: List.from(ledger),
      notifications: notifications.map((n) => n.copyWith()).toList(),
      marketNews: marketNews.map((n) => n.copyWith()).toList(),
    );
  }
}

class FinanceEntry {
  final int week;      // semaine où l'évènement a eu lieu
  final String label;  // ex: "Commission: J. Doe (2 ans)"
  final int amount;    // en € (positif = revenu, négatif = dépense)
  const FinanceEntry({required this.week, required this.label, required this.amount});
}

class MarketNewsEntry {
  final int week;      // semaine où la news a été créée
  final String message; // contenu de la news
  
  const MarketNewsEntry({required this.week, required this.message});
  
  MarketNewsEntry copyWith({
    int? week,
    String? message,
  }) {
    return MarketNewsEntry(
      week: week ?? this.week,
      message: message ?? this.message,
    );
  }
}

enum NotificationType {
  offerReceived,      // Nouvelle offre pour un client
  offerExpiring,      // Offre qui expire bientôt
  contractSigned,     // Contrat signé
  tradeRumor,         // Rumeur de trade
  extensionOffer,     // Offre d'extension
  clientMood,         // Changement d'humeur client
}

// Renommé de Notification à GameNotification pour éviter conflit avec Flutter
class GameNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final int week;
  final bool isRead;
  final int? relatedPlayerId;
  final int? relatedOfferId;
  
  GameNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.week,
    this.isRead = false,
    this.relatedPlayerId,
    this.relatedOfferId,
  });

  GameNotification copyWith({
    String? id,
    NotificationType? type,
    String? title,
    String? message,
    int? week,
    bool? isRead,
    int? relatedPlayerId,
    int? relatedOfferId,
  }) {
    return GameNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      week: week ?? this.week,
      isRead: isRead ?? this.isRead,
      relatedPlayerId: relatedPlayerId ?? this.relatedPlayerId,
      relatedOfferId: relatedOfferId ?? this.relatedOfferId,
    );
  }
}
