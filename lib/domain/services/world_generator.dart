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

    // 5. Générer les contrats initiaux et créer des Free Agents
    final contracts = <Contract>[];
    final playersWithTeams = players.where((p) => p.teamId != null).toList();
    
    // 10% des joueurs moyens (<80 OVR) deviennent Free Agents immédiatement
    final playersToRelease = playersWithTeams
        .where((p) => p.overall < 80 && rng.nextDouble() < 0.10)
        .toList();
    
    for (final player in playersToRelease) {
      final team = teams.firstWhere((t) => t.id == player.teamId);
      player.teamId = null;
      team.roster.remove(player.id);
    }
    
    // Générer des contrats pour les joueurs restants
    for (final player in players.where((p) => p.teamId != null)) {
      final team = teams.firstWhere((t) => t.id == player.teamId);
      final contract = _generateInitialContract(player, rng);
      contracts.add(contract);
      team.capUsed += contract.salaryPerYear.isNotEmpty ? contract.salaryPerYear.first : 0;
    }
    
    print('✅ ${contracts.length} contrats initiaux générés');
    print('✅ ${players.where((p) => p.teamId == null).length} Free Agents disponibles');

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
      contracts: contracts,
      recentEvents: [],
    );
  }

  /// Génère un contrat initial pour un joueur
  Contract _generateInitialContract(Player player, Random rng) {
    // Calculer le salaire basé sur l'OVR
    int salary;
    if (player.overall >= 90) {
      salary = 35000000 + rng.nextInt(15000000); // 35-50M (Superstars)
    } else if (player.overall >= 85) {
      salary = 25000000 + rng.nextInt(10000000); // 25-35M (Stars)  
    } else if (player.overall >= 80) {
      salary = 15000000 + rng.nextInt(10000000); // 15-25M (Bons)
    } else if (player.overall >= 75) {
      salary = 8000000 + rng.nextInt(7000000);   // 8-15M (Moyens)
    } else if (player.overall >= 70) {
      salary = 3000000 + rng.nextInt(5000000);   // 3-8M (Role players)
    } else {
      salary = 1000000 + rng.nextInt(2000000);   // 1-3M (Bench)
    }
    
    // Durée basée sur l'âge et l'OVR
    int years;
    if (player.age <= 25 && player.overall >= 80) {
      years = 4 + rng.nextInt(2); // 4-5 ans pour jeunes talents
    } else if (player.age <= 28 && player.overall >= 85) {
      years = 3 + rng.nextInt(2); // 3-4 ans pour stars dans la force de l'âge
    } else if (player.age <= 30) {
      years = 2 + rng.nextInt(2); // 2-3 ans pour joueurs établis
    } else {
      years = 1 + rng.nextInt(2); // 1-2 ans pour vétérans
    }
    
    // 20% des joueurs en dernière année de contrat
    if (rng.nextDouble() < 0.20) {
      years = 1; // Expire cette année
    }
    
    // Calculer startWeek rétroactivement
    final yearsAlreadyPassed = years - 1;
    final startWeek = 1 - (yearsAlreadyPassed * 52);
    
    return Contract(
      playerId: player.id,
      teamId: player.teamId!,
      salaryPerYear: List.filled(years, salary),
      signingBonus: (salary * 0.1 * rng.nextDouble()).round(),
      startWeek: startWeek,
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
