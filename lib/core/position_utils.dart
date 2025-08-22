import '../domain/entities.dart';

class PositionUtils {
  static Pos parsePosition(String? primary, String? secondary) {
    final pos = (primary ?? secondary ?? '').toUpperCase().replaceAll('-', '').trim();
    
    // Recherche exacte d'abord
    if (pos.contains('PG') || pos == 'POINT') return Pos.PG;
    if (pos.contains('SG') || pos == 'SHOOTING') return Pos.SG;
    if (pos.contains('SF') || pos == 'SMALL') return Pos.SF;
    if (pos.contains('PF') || pos == 'POWER') return Pos.PF;
    if (pos.contains('C') || pos == 'CENTER') return Pos.C;
    
    // Positions génériques
    if (pos == 'G' || pos == 'GUARD') {
      // Si on a le secondary, on peut être plus précis
      if (secondary != null && secondary.toUpperCase().contains('P')) return Pos.PG;
      return Pos.SG;  // Par défaut SG pour Guard
    }
    if (pos == 'F' || pos == 'FORWARD') {
      // Si on a le secondary, on peut être plus précis  
      if (secondary != null && secondary.toUpperCase().contains('P')) return Pos.PF;
      return Pos.SF;  // Par défaut SF pour Forward
    }
    
    // Fallback
    return Pos.SF;
  }
  
  static bool matchesPosition(String playerPos, Pos targetPos) {
    final normalized = playerPos.toUpperCase().replaceAll('-', '').trim();
    
    switch (targetPos) {
      case Pos.PG:
        return normalized.contains('PG') || normalized == 'G' || normalized.contains('POINT');
      case Pos.SG:
        return normalized.contains('SG') || (normalized == 'G' && !normalized.contains('P')) || normalized.contains('SHOOT');
      case Pos.SF:
        return normalized.contains('SF') || normalized == 'F' || normalized.contains('SMALL');
      case Pos.PF:
        return normalized.contains('PF') || (normalized == 'F' && !normalized.contains('S')) || normalized.contains('POWER');
      case Pos.C:
        return normalized.contains('C') || normalized == 'CENTER';
    }
  }
}