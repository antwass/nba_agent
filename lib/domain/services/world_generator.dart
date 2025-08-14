import 'dart:math';
import '../entities.dart';

class WorldGenerator {
  final Random rng;
  WorldGenerator(this.rng);

  LeagueState generate() {
    // Équipes
    final teams = List.generate(
      20,
          (i) => Team(id: i + 1, name: 'Club ${i + 1}', city: 'City ${i + 1}'),
    );

    // Joueurs
    int nextId = 1;
    final positions = Pos.values;
    final players = List.generate(320, (i) {
      final pos = positions[rng.nextInt(positions.length)];
      final ov = 58 + rng.nextInt(35); // 58..92
      final pot = (ov + rng.nextInt(10)).clamp(60, 99);
      return Player(
        id: nextId++,
        name: 'P$nextId',
        age: 19 + rng.nextInt(16),
        pos: pos,
        overall: ov,
        potential: pot,
        form: rng.nextInt(5) - 2,
        greed: rng.nextDouble(),
        marketability: rng.nextInt(100),
      );
    });

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
      clients: players.take(5).map((p) => p.id).toList(),
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
}
