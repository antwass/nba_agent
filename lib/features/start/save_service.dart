import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'save_game_meta.dart';
import '../../domain/entities.dart';
import '../../core/id_generator.dart';

class SaveService {
  static const _kKey = 'save_slots'; // liste des métadonnées
  static const _kGamePrefix = 'game_state_'; // préfixe pour l'état complet
  static const maxSlots = 3;

  // --- MÉTADONNÉES (existant) ---

  Future<List<SaveGameMeta>> loadSlots() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kKey);
    if (raw == null) return [];
    final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    return list.map(SaveGameMeta.fromJson).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> _persist(List<SaveGameMeta> slots) async {
    final sp = await SharedPreferences.getInstance();
    final jsonList = slots.map((e) => e.toJson()).toList();
    await sp.setString(_kKey, json.encode(jsonList));
  }

  Future<void> upsertSlot(SaveGameMeta slot) async {
    final slots = await loadSlots();
    final i = slots.indexWhere((s) => s.id == slot.id);
    if (i >= 0) {
      slots[i] = slot;
    } else {
      if (slots.length >= maxSlots) slots.removeLast();
      slots.add(slot);
    }
    await _persist(slots);
  }

  Future<void> deleteSlot(String id) async {
    final slots = await loadSlots();
    slots.removeWhere((s) => s.id == id);
    await _persist(slots);
    
    // Supprimer aussi l'état du jeu
    final sp = await SharedPreferences.getInstance();
    await sp.remove('$_kGamePrefix$id');
  }
  
  // --- ÉTAT COMPLET DU JEU (nouveau) ---
  
  Future<void> saveGameState(String slotId, LeagueState state) async {
    try {
      final sp = await SharedPreferences.getInstance();
      
      // Convertir l'état en JSON (version simplifiée pour SharedPreferences)
      final stateJson = {
        'week': state.week,
        'agent': {
          'cash': state.agent.cash,
          'reputation': state.agent.reputation,
          'clients': state.agent.clients,
        },
        'players': state.players.map((p) => {
          'id': p.id,
          'name': p.name,
          'age': p.age,
          'pos': p.pos.index,
          'overall': p.overall,
          'potential': p.potential,
          'form': p.form,
          'greed': p.greed,
          'marketability': p.marketability,
          'teamId': p.teamId,
          'extId': p.extId,
          'representativeId': p.representativeId,
        }).toList(),
        'teams': state.teams.map((t) => {
          'id': t.id,
          'name': t.name,
          'city': t.city,
          'capUsed': t.capUsed,
          'roster': t.roster,
        }).toList(),
        'offers': state.offers.map((o) => {
          'id': o.id,
          'teamId': o.teamId,
          'playerId': o.playerId,
          'salary': o.salary,
          'years': o.years,
          'bonus': o.bonus,
          'createdWeek': o.createdWeek,
          'expiresWeek': o.expiresWeek,
        }).toList(),
        'contracts': state.contracts.map((c) => {
          'playerId': c.playerId,
          'teamId': c.teamId,
          'salaryPerYear': c.salaryPerYear,
          'signingBonus': c.signingBonus,
          'startWeek': c.startWeek,
        }).toList(),
        'ledger': state.ledger.map((e) => {
          'week': e.week,
          'label': e.label,
          'amount': e.amount,
        }).toList(),
        'notifications': state.notifications.map((n) => {
          'id': n.id,
          'type': n.type.index,
          'title': n.title,
          'message': n.message,
          'week': n.week,
          'isRead': n.isRead,
          'relatedPlayerId': n.relatedPlayerId,
          'relatedOfferId': n.relatedOfferId,
        }).toList(),
        'marketNews': state.marketNews,
      };
      
      final jsonString = json.encode(stateJson);
      await sp.setString('$_kGamePrefix$slotId', jsonString);
      
      // Mettre à jour les métadonnées
      final meta = SaveGameMeta(
        id: slotId,
        name: 'Agent', // TODO: récupérer le vrai nom
        week: state.week,
        updatedAt: DateTime.now(),
      );
      await upsertSlot(meta);
      
    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
      rethrow;
    }
  }
  
  Future<LeagueState?> loadGameState(String slotId) async {
    try {
      final sp = await SharedPreferences.getInstance();
      final jsonString = sp.getString('$_kGamePrefix$slotId');
      
      if (jsonString == null) return null;
      
      final stateJson = json.decode(jsonString);
      
      // Reconstruire l'état depuis le JSON
      final players = (stateJson['players'] as List).map((p) => Player(
        id: p['id'],
        name: p['name'],
        age: p['age'],
        pos: Pos.values[p['pos']],
        overall: p['overall'],
        potential: p['potential'],
        form: p['form'],
        greed: p['greed'].toDouble(),
        marketability: p['marketability'],
        teamId: p['teamId'],
        extId: p['extId'],
        representativeId: p['representativeId'],
      )).toList();
      
      final teams = (stateJson['teams'] as List).map((t) => Team(
        id: t['id'],
        name: t['name'],
        city: t['city'],
        capUsed: t['capUsed'],
        roster: List<int>.from(t['roster']),
      )).toList();
      
      final agent = AgentProfile(
        cash: stateJson['agent']['cash'],
        reputation: stateJson['agent']['reputation'],
        clients: List<int>.from(stateJson['agent']['clients']),
      );
      
      final offers = (stateJson['offers'] as List).map((o) => Offer(
        id: (o as Map).containsKey('id') ? o['id'] : IdGenerator.nextOfferId(),
        teamId: o['teamId'],
        playerId: o['playerId'],
        salary: o['salary'],
        years: o['years'],
        bonus: o['bonus'],
        createdWeek: o['createdWeek'],
        expiresWeek: o['expiresWeek'],
      )).toList();
      
      final contracts = (stateJson['contracts'] as List).map((c) => Contract(
        playerId: c['playerId'],
        teamId: c['teamId'],
        salaryPerYear: List<int>.from(c['salaryPerYear']),
        signingBonus: c['signingBonus'],
        startWeek: c['startWeek'],
      )).toList();
      
      final ledger = (stateJson['ledger'] as List).map((e) => FinanceEntry(
        week: e['week'],
        label: e['label'],
        amount: e['amount'],
      )).toList();
      
      final notifications = (stateJson['notifications'] as List).map((n) => GameNotification(
        id: n['id'],
        type: NotificationType.values[n['type']],
        title: n['title'],
        message: n['message'],
        week: n['week'],
        isRead: n['isRead'],
        relatedPlayerId: n['relatedPlayerId'],
        relatedOfferId: n['relatedOfferId'],
      )).toList();
      
      return LeagueState(
        week: stateJson['week'],
        players: players,
        teams: teams,
        agent: agent,
        offers: offers,
        contracts: contracts,
        ledger: ledger,
        notifications: notifications,
        marketNews: List<String>.from(stateJson['marketNews']),
      );
      
    } catch (e) {
      print('❌ Erreur chargement: $e');
      return null;
    }
  }
}
