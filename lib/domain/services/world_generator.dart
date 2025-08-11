import 'dart:math';
import '../entities.dart';

class WorldGenerator {
  final Random rng;
  WorldGenerator(this.rng);

  LeagueState generate() {
    final teams = List.generate(20, (i) => Team(
      id: i+1,
      name: 'Club ${i+1}',
      city: 'City ${i+1}',
    ));

    final positions = Pos.values;
    int nextId = 1;
    final players = List.generate(220, (i) {
      final pos = positions[rng.nextInt(positions.length)];
      final ov = 60 + rng.nextInt(30); // 60..89
      final pot = ov + rng.nextInt(10); // léger potentiel
      return Player(
        id: nextId++,
        name: 'P$nextId',
        age: 19 + rng.nextInt(16),
        pos: pos,
        overall: ov,
        potential: pot.clamp(60, 99),
        form: rng.nextInt(5) - 2,
        greed: rng.nextDouble(),
        marketability: rng.nextInt(100),
      );
    });

    final agent = AgentProfile(cash: 0, reputation: 10, clients: players.take(5).map((p)=>p.id).toList());

    return LeagueState(week: 1, players: players, teams: teams, agent: agent);
  }
}
