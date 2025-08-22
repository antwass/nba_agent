class CommissionRates {
  static const double freeAgent = 0.07;      // 7% pour les free agents
  static const double extension = 0.05;      // 5% pour les extensions
  static const double trade = 0.03;          // 3% pour les trades
  static const double buyout = 0.02;         // 2% pour les buyouts
  
  static double getRate(CommissionType type) {
    switch (type) {
      case CommissionType.freeAgent:
        return freeAgent;
      case CommissionType.extension:
        return extension;
      case CommissionType.trade:
        return trade;
      case CommissionType.buyout:
        return buyout;
    }
  }
}

enum CommissionType {
  freeAgent,
  extension,
  trade,
  buyout,
}