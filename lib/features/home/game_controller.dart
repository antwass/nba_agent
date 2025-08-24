import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities.dart';
import '../../domain/usecases/advance_week.dart';
import '../../domain/usecases/approach_player.dart';
import '../../domain/services/world_generator.dart';
import '../start/save_service.dart';
import '../start/start_screen.dart';


class GameState {
  final LeagueState? league;
  final String lastSummary;
  final bool isLoading;
  
  const GameState({
    this.league, 
    this.lastSummary = '', 
    this.isLoading = false
  });

  GameState copyWith({
    LeagueState? league, 
    String? lastSummary, 
    bool? isLoading
  }) =>
      GameState(
        league: league ?? this.league,
        lastSummary: lastSummary ?? this.lastSummary,
        isLoading: isLoading ?? this.isLoading,
      );
}

class GameController extends StateNotifier<GameState> {
  final Ref ref;
  
  GameController(this.ref) : super(const GameState(isLoading: true)) {
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      // TEST: Vérifier si le fichier JSON existe
      print('🧪 TEST: Vérification du fichier JSON...');
      try {
        final content = await rootBundle.loadString('assets/data/nba_database_final.json');
        print('✅ Fichier JSON trouvé, taille: ${content.length} caractères');
        if (content.length < 100) {
          print('❌ PROBLÈME: Fichier trop petit!');
        }
      } catch (e) {
        print('❌ ERREUR: Fichier JSON introuvable: $e');
      }
      
      final world = await WorldGenerator(Random(42)).generate();
      // Vérifier qu'on a des joueurs NBA
      final nbaPlayers = world.players.where((p) => p.extId != null).length;
      print('🎮 Partie initialisée avec $nbaPlayers joueurs NBA');
      state = GameState(league: world, lastSummary: 'Jeu initialisé');
    } catch (e) {
      print('❌ ERREUR INIT: $e');
      state = GameState(lastSummary: 'Erreur lors du chargement: $e');
    }
  }

  Future<void> newGame({String agentName = 'Agent'}) async {
    state = state.copyWith(isLoading: true);
    try {
      final world = await WorldGenerator(Random()).generate();
      world.agent.reputation = 10;
      state = GameState(league: world, lastSummary: 'Nouvelle partie pour $agentName');
    } catch (e) {
      state = state.copyWith(isLoading: false, lastSummary: 'Erreur: $e');
    }
  }

  void nextWeek() {
    if (state.league == null) return;
    final res = advanceWeek(state.league!, rng: Random(state.league!.week));
    // Il faut passer la ligue MISE À JOUR au nouvel état
    state = state.copyWith(
      league: res.league,
      lastSummary: 'Offres générées: ${res.offersGenerated}',
    );
  }

  // (utilisé par NegotiationScreen)
  void refreshAfterSign(LeagueState newLeagueState, String summary) {
    state = state.copyWith(league: newLeagueState, lastSummary: summary);
  }

  void approachPlayer(LeagueState newLeagueState, ApproachResult result) {
    state = state.copyWith(league: newLeagueState, lastSummary: result.message);
  }

  void markOfferNotificationsRead() {
    final league = state.league;
    if (league == null) return;
    final copy = league.deepCopy();
    for (int i = 0; i < copy.notifications.length; i++) {
      final n = copy.notifications[i];
      if (n.type == NotificationType.offerReceived && !n.isRead) {
        copy.notifications[i] = n.copyWith(isRead: true);
      }
    }
    state = state.copyWith(league: copy);
  }

  Future<void> saveGame() async {
    if (state.league == null) return;
    
    final slotId = ref.read(currentSlotIdProvider);
    if (slotId == null) {
      // Créer un nouveau slot si nécessaire
      final newSlotId = 'slot-${DateTime.now().millisecondsSinceEpoch}';
      ref.read(currentSlotIdProvider.notifier).state = newSlotId;
    }
    
    final saveService = ref.read(saveServiceProvider);
    await saveService.saveGameState(
      ref.read(currentSlotIdProvider)!,
      state.league!,
    );
  }
  
  Future<void> loadGame(String slotId) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final saveService = ref.read(saveServiceProvider);
      final loadedState = await saveService.loadGameState(slotId);
      
      if (loadedState != null) {
        state = GameState(league: loadedState, lastSummary: 'Partie chargée');
      } else {
        state = GameState(lastSummary: 'Erreur: sauvegarde introuvable');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, lastSummary: 'Erreur chargement: $e');
    }
  }
}

final gameControllerProvider =
StateNotifierProvider<GameController, GameState>((ref) => GameController(ref));
