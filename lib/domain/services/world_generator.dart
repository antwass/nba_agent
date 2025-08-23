import 'dart:math';
import '../entities.dart';
import '../../data/nba_repository.dart';
import '../../core/id_generator.dart';

class WorldGenerator {
  final Random rng;
  WorldGenerator(this.rng);

  Future<LeagueState> generate() async {
    // --- NOUVELLE LOGIQUE ---

    // 1. Charger tous les joueurs depuis la BDD NBA
    final repo = NbaRepository();
    List<Player> nbaPlayers = [];
    try {
      nbaPlayers = await repo.loadPlayers();
      print('✅ NBA: ${nbaPlayers.length} joueurs chargés depuis la BDD');
    } catch (e) {
      print('❌ ERREUR CHARGEMENT NBA: $e');
    }

    // 2. Créer les équipes réelles à partir des données des joueurs
    final teamsMap = <String, Team>{};
    int nextTeamId = 1;
    for (final player in nbaPlayers) {
      final teamName = player.teamNameFromJson;
      if (teamName != null && !teamsMap.containsKey(teamName)) {
        teamsMap[teamName] = Team(
          id: nextTeamId++,
          name: teamName,
          city: '', // Le JSON ne fournit pas la ville, on laisse vide
        );
      }
    }
    final teams = teamsMap.values.toList();
    print('✅ ${teams.length} équipes uniques créées.');

    // 3. Associer chaque joueur à son équipe réelle
    for (final player in nbaPlayers) {
      final teamName = player.teamNameFromJson;
      if (teamName != null && teamsMap.containsKey(teamName)) {
        final team = teamsMap[teamName]!;
        player.teamId = team.id;
        team.roster.add(player.id);
      }
      // On peut maintenant supprimer le nom temporaire
      player.teamNameFromJson = null;
    }
    print('✅ Joueurs NBA associés à leurs équipes respectives.');

    // 4. Gérer les joueurs générés (si nécessaire)
    List<Player> players = [...nbaPlayers];
    if (players.length < 320) {
      final needed = 320 - players.length;
      print('➕ Ajout de $needed joueurs générés');
      final generated = _generateFallbackPlayers(needed);
      
      // Répartir les joueurs générés dans les équipes existantes
      for (final p in generated) {
        final team = teams[rng.nextInt(teams.length)];
        p.teamId = team.id;
        team.roster.add(p.id);
      }
      players.addAll(generated);
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
