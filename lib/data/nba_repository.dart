import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../domain/entities.dart';

class NbaRepository {
  final String assetPath;
  const NbaRepository({this.assetPath = 'assets/data/nba_players_active_2025.json'});

  Future<List<Player>> loadPlayers() async {
    final raw = await rootBundle.loadString(assetPath);
    final List data = jsonDecode(raw) as List;

    int nextId = 200000; // évite collision avec tes ids internes
    Pos _mapPos(String s) {
      switch (s) {
        case 'C': return Pos.C;
        case 'SF': return Pos.SF;
        case 'PG': return Pos.PG;
        default:   return Pos.SG;
      }
    }

    return data.map((e) {
      final String first = (e['first_name'] ?? '') as String;
      final String last  = (e['last_name']  ?? '') as String;
      final name = (first + ' ' + last).trim();
      final pos  = _mapPos((e['position'] ?? 'SG') as String);

      // Placeholders : tu pourras raffiner avec de vraies stats
      final ov  = 65 + (name.hashCode % 25);   // 65..89
      final pot = (ov + 5).clamp(60, 98);

      return Player(
        id: nextId++,
        name: name,
        age: 24,                    // l’API /players ne donne pas l’âge. Tu pourras l’estimer plus tard
        pos: pos,
        overall: ov,
        potential: pot,
        form: 0,
        greed: 0.5,
        marketability: 60,
        teamId: null,              // on ne relie pas à tes équipes fictives pour l’instant
        extId: e['extId'] as String?,
        representativeId: null,    // => “sans agent” par défaut
      );
    }).toList();
  }
}
