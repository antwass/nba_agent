import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities.dart';
import '../../domain/usecases/advance_week.dart';
import '../../domain/usecases/approach_player.dart';
import '../../domain/services/world_generator.dart';


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
  GameController() : super(const GameState(isLoading: true)) {
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      final world = await WorldGenerator(Random(42)).generate();
      state = GameState(league: world, lastSummary: 'Jeu initialisé');
    } catch (e) {
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
    state = state.copyWith(lastSummary: 'Offres générées: ${res.offersGenerated}');
  }

  // (utilisé par NegotiationScreen)
  void refreshAfterSign(String summary) {
    state = state.copyWith(lastSummary: summary);
  }

  void approachPlayer(int playerId, ApproachResult result) {
    state = state.copyWith(lastSummary: result.message);
  }
}

final gameControllerProvider =
StateNotifierProvider<GameController, GameState>((ref) => GameController());

