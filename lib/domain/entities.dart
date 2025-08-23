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
  List<String> recentEvents;  // Garde pour compatibilité

  // 👇 nouveau : journal de mouvements financiers
  List<FinanceEntry> ledger;
  
  // 👇 nouveau : système de notifications séparées
  List<GameNotification> notifications;  // Notifications personnelles
  List<String> marketNews;          // News globales du marché

  LeagueState({
    required this.week,
    required this.players,
    required this.teams,
    required this.agent,
    List<Offer>? offers,
    List<Contract>? contracts,
    List<String>? recentEvents,  // Garde pour compatibilité
    List<GameNotification>? notifications,
    List<String>? marketNews,
    List<FinanceEntry>? ledger,
  })  : offers = offers ?? [],
        contracts = contracts ?? [],
        recentEvents = recentEvents ?? [],  // Garde pour compatibilité
        notifications = notifications ?? [],
        marketNews = marketNews ?? [],
        ledger = ledger ?? [];
}

class FinanceEntry {
  final int week;      // semaine où l'évènement a eu lieu
  final String label;  // ex: "Commission: J. Doe (2 ans)"
  final int amount;    // en € (positif = revenu, négatif = dépense)
  const FinanceEntry({required this.week, required this.label, required this.amount});
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
}
