class IdGenerator {
  static int _nextPlayerId = 300000;
  static int _nextOfferId = 400000;
  static int _nextContractId = 500000;
  
  static int nextPlayerId() => _nextPlayerId++;
  static int nextOfferId() => _nextOfferId++;
  static int nextContractId() => _nextContractId++;
  
  // Reset pour les tests si nécessaire
  static void reset() {
    _nextPlayerId = 300000;
    _nextOfferId = 400000;
    _nextContractId = 500000;
  }
}