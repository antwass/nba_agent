class GameCalendar {
  static const List<String> months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];
  
  // On démarre en Juillet 2025 (début Free Agency NBA)
  static const int startMonth = 7; // Juillet
  static const int startYear = 2025;
  static const int weeksPerYear = 52;
  
  // Convertit un numéro de semaine global en date affichable
  static String weekToDisplay(int week) {
    final yearOffset = (week - 1) ~/ weeksPerYear;
    final weekInYear = ((week - 1) % weeksPerYear) + 1;
    
    // Calcul du mois et de la semaine dans le mois
    final totalWeeks = weekInYear - 1;
    final monthIndex = (startMonth - 1 + (totalWeeks ~/ 4)) % 12;
    final weekInMonth = (totalWeeks % 4) + 1;
    
    final year = startYear + yearOffset;
    
    return '${months[monthIndex]} - Semaine $weekInMonth';
  }
  
  // Version avec année incluse
  static String weekToFullDisplay(int week) {
    final year = getYear(week);
    return '${weekToDisplay(week)} $year';
  }
  
  // Retourne l'année actuelle basée sur la semaine
  static int getYear(int week) {
    final yearOffset = (week - 1) ~/ weeksPerYear;
    final weekInYear = ((week - 1) % weeksPerYear) + 1;
    
    // Si on dépasse décembre (6 mois après juillet = janvier)
    if (weekInYear > 24) {
      return startYear + yearOffset + 1;
    }
    return startYear + yearOffset;
  }
  
  // Retourne la saison NBA (ex: "2025-26")
  static String getSeason(int week) {
    final yearOffset = (week - 1) ~/ weeksPerYear;
    final baseYear = startYear + yearOffset;
    return '$baseYear-${(baseYear + 1).toString().substring(2)}';
  }
  
  // Retourne la phase NBA actuelle (répétée chaque année)
  static String getPhase(int week) {
    final weekInYear = ((week - 1) % weeksPerYear) + 1;
    
    if (weekInYear >= 1 && weekInYear <= 12) return "Free Agency";
    if (weekInYear >= 13 && weekInYear <= 16) return "Pré-saison";
    if (weekInYear >= 17 && weekInYear <= 42) return "Saison régulière";
    if (weekInYear >= 43 && weekInYear <= 48) return "Playoffs";
    return "Intersaison";
  }
  
  // Événements spéciaux par semaine (répétés chaque année)
  static String? getSpecialEvent(int week) {
    final weekInYear = ((week - 1) % weeksPerYear) + 1;
    
    switch (weekInYear) {
      case 1: return "🔥 Ouverture Free Agency ${getSeason(week)} !";
      case 8: return "📝 Fin de la première vague Free Agency";
      case 13: return "🏀 Début du training camp";
      case 17: return "🎯 Début de la saison ${getSeason(week)} !";
      case 30: return "⭐ All-Star Weekend ${getYear(week)}";
      case 35: return "📊 Trade Deadline";
      case 43: return "🏆 Début des Playoffs ${getYear(week)} !";
      case 48: return "🏆 Finales NBA ${getYear(week)}";
      case 52: return "📅 Fin de la saison ${getSeason(week)}";
      default: return null;
    }
  }
  
  // Helper pour savoir si on est en nouvelle année civile
  static bool isNewYear(int week) {
    final weekInYear = ((week - 1) % weeksPerYear) + 1;
    return weekInYear == 25; // Janvier - Semaine 1
  }
  
  // Helper pour savoir si on est en nouvelle saison NBA
  static bool isNewSeason(int week) {
    return (week - 1) % weeksPerYear == 0;
  }
}