import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../entities.dart';

class WorldGenerator {
  final Random rng;
  WorldGenerator(this.rng);

  Future<LeagueState> generate() async {
    // Équipes
    final teams = List.generate(
      20,
          (i) => Team(id: i + 1, name: 'Club ${i + 1}', city: 'City ${i + 1}'),
    );

    // Charger les joueurs NBA depuis la BDD
    final players = await _loadNBAPlayers();

    // Répartition simple : 12 joueurs / équipe, le reste FA
    final shuffled = [...players]..shuffle(rng);
    int cursor = 0;
    for (final team in teams) {
      final slice = shuffled.skip(cursor).take(12);
      for (final p in slice) {
        p.teamId = team.id;     // ✅ évite l’erreur setter teamId
        team.roster.add(p.id);
      }
      cursor += 12;
    }

    final agent = AgentProfile(
      cash: 0,
      reputation: 10,
      clients: [], // Démarre sans clients
    );

    return LeagueState(
      week: 1,
      players: players,
      teams: teams,
      agent: agent,
      offers: [],        // ✅ présents pour la sim/market
      contracts: [],
      recentEvents: [],
    );
  }

  Future<List<Player>> _loadNBAPlayers() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/nba_database_final.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      return jsonData.map((playerJson) => _parsePlayer(playerJson)).toList();
    } catch (e) {
      // En cas d'erreur, retourne des joueurs générés
      return _generateFallbackPlayers();
    }
  }

  Player _parsePlayer(Map<String, dynamic> json) {
    final ratings = json['ratings'] as Map<String, dynamic>? ?? {};
    final bio = json['bio'] as Map<String, dynamic>? ?? {};
    
    // Conversion des positions NBA vers notre enum
    Pos parsePosition(String? pos) {
      switch (pos?.toUpperCase()) {
        case 'PG': return Pos.PG;
        case 'SG': return Pos.SG;
        case 'SF': return Pos.SF;
        case 'PF': return Pos.PF;
        case 'C': return Pos.C;
        case 'G': return Pos.SG; // Guard générique -> SG
        case 'F': return Pos.SF; // Forward générique -> SF
        default: return Pos.SF; // Par défaut
      }
    }
    
    return Player(
      id: json['player_id'] as int? ?? 0,
      name: json['full_name'] as String? ?? 'Joueur Inconnu',
      age: bio['age'] as int? ?? 25,
      pos: parsePosition(json['position_primary'] as String?),
      overall: ratings['overall'] as int? ?? 70,
      potential: ratings['potential'] as int? ?? 75,
      form: rng.nextInt(5) - 2, // Forme aléatoire
      greed: rng.nextDouble(), // Cupidité aléatoire
      marketability: rng.nextInt(100), // Marketabilité aléatoire
      extId: json['player_id']?.toString(), // ID externe pour référence
    );
  }
  
  List<Player> _generateFallbackPlayers() {
    // Joueurs de secours si le chargement échoue
    int nextId = 1;
    final positions = Pos.values;
    return List.generate(320, (i) {
      final pos = positions[rng.nextInt(positions.length)];
      final ov = 58 + rng.nextInt(35);
      final pot = (ov + rng.nextInt(10)).clamp(60, 99);
      return Player(
        id: nextId++,
        name: 'Joueur $nextId',
        age: 19 + rng.nextInt(16),
        pos: pos,
        overall: ov,
        potential: pot,
        form: rng.nextInt(5) - 2,
        greed: rng.nextDouble(),
        marketability: rng.nextInt(100),
      );
    });
  }
}
