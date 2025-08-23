import 'dart:math';
import '../entities.dart';
import '../../data/nba_repository.dart';
import '../../core/id_generator.dart';

class WorldGenerator {
  final Random rng;
  WorldGenerator(this.rng);

  Future<LeagueState> generate() async {
    // Équipes
    final teams = List.generate(
      20,
      (i) => Team(id: i + 1, name: 'Club ${i + 1}', city: 'City ${i + 1}'),
    );

    // FORCER le chargement des joueurs NBA
    final repo = NbaRepository();
    List<Player> nbaPlayers = [];
    
    try {
      nbaPlayers = await repo.loadPlayers();
      print('✅ NBA: ${nbaPlayers.length} joueurs chargés depuis la BDD');
    } catch (e) {
      print('❌ ERREUR NBA: $e');
    }
    
    // Si on n'a pas assez de joueurs NBA, on complète
    List<Player> players = [...nbaPlayers];
    
    if (players.length < 320) {
      final needed = 320 - players.length;
      print('➕ Ajout de $needed joueurs générés (total NBA: ${players.length})');
      
      // Générer SEULEMENT le complément
      final generated = _generateFallbackPlayers(needed);
      players.addAll(generated);
    }
    
    print('📊 TOTAL: ${nbaPlayers.length} NBA + ${players.length - nbaPlayers.length} générés');

    // Mélanger et répartir
    final shuffled = [...players]..shuffle(rng);
    int cursor = 0;
    for (final team in teams) {
      final slice = shuffled.skip(cursor).take(12);
      for (final p in slice) {
        p.teamId = team.id;
        team.roster.add(p.id);
      }
      cursor += 12;
    }

    final agent = AgentProfile(
      cash: 0,
      reputation: 10,
      clients: [],
    );

    return LeagueState(
      week: 1,
      players: players,
      teams: teams,
      agent: agent,
      offers: [],
      contracts: [],
      recentEvents: [],
    );
  }

  List<Player> _generateFallbackPlayers(int count) {
    final positions = Pos.values;
    return List.generate(count, (i) {
      final pos = positions[rng.nextInt(positions.length)];
      final ov = 58 + rng.nextInt(35);
      final pot = (ov + rng.nextInt(10)).clamp(60, 99);
      return Player(
        id: IdGenerator.nextPlayerId(),
        name: 'Joueur Généré ${i + 1}',
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
