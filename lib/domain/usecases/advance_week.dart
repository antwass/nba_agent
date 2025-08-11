import '../entities.dart';
import 'dart:math';

class AdvanceWeekResult {
  final int newWeek;
  final int offersGenerated;
  AdvanceWeekResult(this.newWeek, this.offersGenerated);
}

/// MVP: progression très simple + génère des “offres fantômes” (compte)
AdvanceWeekResult advanceWeek(LeagueState s, {Random? rng}) {
  final r = rng ?? Random(s.week);
  for (final p in s.players) {
    final delta = ((p.potential - p.overall) / 200.0) + (p.form * 0.02);
    p.overall = (p.overall + delta).clamp(40, 99).round();
  }
  // “offres” simulées : nb en fonction de la semaine
  final offers = r.nextInt(3) + (s.week % 2 == 0 ? 1 : 0);
  s.week += 1;
  return AdvanceWeekResult(s.week, offers);
}
