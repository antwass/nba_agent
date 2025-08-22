// lib/data/nba_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../domain/entities.dart';
import '../core/id_generator.dart';
import '../core/position_utils.dart';

/// Charge 'assets/data/nba_database_final.json'
/// et le mappe vers ton modèle Player.
class NbaRepository {
  final String assetPath;
  const NbaRepository({
    this.assetPath = 'assets/data/nba_database_final.json',
  });

  Future<List<Player>> loadPlayers() async {
    final raw = await rootBundle.loadString(assetPath);
    final List list = jsonDecode(raw) as List;



    int _clampInt(num? v, int lo, int hi, {int def = 75}) {
      if (v == null) return def;
      final x = v.toInt();
      if (x < lo) return lo;
      if (x > hi) return hi;
      return x;
    }

    return list.map((e) {
      final bio = (e['bio'] as Map?) ?? const {};
      final ratings = (e['ratings'] as Map?) ?? const {};
      final posPrim = e['position_primary'] as String?;
      final posSec  = e['position_secondary'] as String?;
      final name    = (e['full_name'] as String?)?.trim() ?? 'Unknown';
      final ov      = _clampInt(ratings['overall'], 60, 99, def: 78);
      int pot       = _clampInt(ratings['potential'], ov, 99, def: ov + 4);

      // petite règle: si 33+ ans, on coiffe le potentiel
      final age = (bio['age'] is num) ? (bio['age'] as num).toInt() : 26;
      if (age >= 36) pot = pot.clamp(ov, ov + 1);
      else if (age >= 33) pot = pot.clamp(ov, 85);

      return Player(
        id: IdGenerator.nextPlayerId(),
        name: name,
        age: age,
        pos: PositionUtils.parsePosition(posPrim, posSec),
        overall: ov,
        potential: pot,
        form: 0,
        greed: 0.5,            // la clean v3 n’a pas ces champs → défauts raisonnables
        marketability: 65,
        teamId: null,          // ton monde fictif gère ses teams
        extId: (e['player_id']?.toString()),
        representativeId: null, // par défaut: "sans agent" → onglet 2 fonctionnera
      );
    }).toList();
  }
}
