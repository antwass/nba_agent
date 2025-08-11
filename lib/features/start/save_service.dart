import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'save_game_meta.dart';

class SaveService {
  static const _kKey = 'save_slots'; // liste JSON
  static const maxSlots = 3;

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
  }
}
