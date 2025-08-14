import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities.dart';
import '../../domain/usecases/advance_week.dart';
import '../../domain/services/world_generator.dart';


class GameState {
  final LeagueState league;
  final String lastSummary;
  const GameState({required this.league, this.lastSummary = ''});

  GameState copyWith({LeagueState? league, String? lastSummary}) =>
      GameState(league: league ?? this.league,
          lastSummary: lastSummary ?? this.lastSummary);
}

class GameController extends StateNotifier<GameState> {
  GameController() : super(GameState(league: WorldGenerator(Random(42)).generate()));

  void newGame({String agentName = 'Agent'}) {
    final world = WorldGenerator(Random()).generate();
    world.agent.reputation = 10;
    state = GameState(league: world, lastSummary: 'Nouvelle partie pour $agentName');
  }

  void nextWeek() {
    final res = advanceWeek(state.league, rng: Random(state.league.week));
    state = state.copyWith(lastSummary: 'Offres générées: ${res.offersGenerated}');
  }

  // (utilisé par NegotiationScreen)
  void refreshAfterSign(String summary) {
    state = state.copyWith(lastSummary: summary);
  }
}

final gameControllerProvider =
StateNotifierProvider<GameController, GameState>((ref) => GameController());

