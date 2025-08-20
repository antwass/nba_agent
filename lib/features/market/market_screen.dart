// lib/features/market/market_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

class MarketScreen extends StatefulWidget {
  const MarketScreen({Key? key}) : super(key: key);

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  List<Map<String, dynamic>> _allPlayers = [];
  List<Map<String, dynamic>> _visible = [];

  // Filtres
  String _query = '';
  String _pos = 'Tous';
  String _team = 'Toutes';
  String _sort = 'OVR ↓';

  // Options construites depuis la BDD
  final List<String> _posOptions = ['Tous', 'PG', 'SG', 'SF', 'PF', 'C'];
  List<String> _teamOptions = ['Toutes'];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    final raw = await rootBundle.loadString('assets/data/nba_database_final.json');
    final List data = json.decode(raw);

    // cast sûr
    _allPlayers = data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();

    // équipes uniques triées
    final teams = {
      for (final p in _allPlayers)
        (((p['team'] ?? const {}) as Map)['team_name'] ?? 'Sans équipe') as String
    }.toList()
      ..sort();
    _teamOptions = ['Toutes', ...teams];

    _applyFilters();
  }

  void _applyFilters() {
    Iterable<Map<String, dynamic>> res = _allPlayers;

    if (_query.trim().isNotEmpty) {
      final q = _query.toLowerCase();
      res = res.where((p) => (p['full_name'] ?? '').toString().toLowerCase().contains(q));
    }

    if (_pos != 'Tous') {
      res = res.where((p) {
        final prim = (p['position_primary'] ?? '').toString().toUpperCase();
        final sec  = (p['position_secondary'] ?? '').toString().toUpperCase();
        return prim == _pos || sec == _pos;
      });
    }

    if (_team != 'Toutes') {
      res = res.where((p) {
        final team = (((p['team'] ?? const {}) as Map)['team_name'] ?? 'Sans équipe').toString();
        return team == _team;
      });
    }

    final list = res.toList();

    int ovr(Map<String, dynamic> p) => ((p['ratings'] ?? {})['overall'] ?? 0) as int;
    int pot(Map<String, dynamic> p) => ((p['ratings'] ?? {})['potential'] ?? 0) as int;
    int age(Map<String, dynamic> p) {
      final bio = (p['bio'] ?? const {}) as Map;
      final a = bio['age'];
      if (a is num) return a.toInt();
      return 0;
    }

    switch (_sort) {
      case 'OVR ↓':
        list.sort((a, b) => ovr(b).compareTo(ovr(a)));
        break;
      case 'OVR ↑':
        list.sort((a, b) => ovr(a).compareTo(ovr(b)));
        break;
      case 'POT ↓':
        list.sort((a, b) => pot(b).compareTo(pot(a)));
        break;
      case 'Âge ↓':
        list.sort((a, b) => age(b).compareTo(age(a)));
        break;
      case 'Âge ↑':
        list.sort((a, b) => age(a).compareTo(age(b)));
        break;
    }

    setState(() => _visible = list);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Marché')),
      body: _allPlayers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Barre filtres
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Column(
              children: [
                // Première ligne : Recherche
                TextField(
                  onChanged: (v) {
                    _query = v;
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher un joueur…',
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                // Deuxième ligne : Filtres en Row
                Row(
                  children: [
                    // Poste
                    Expanded(
                      flex: 1,
                      child: _Dropdown(
                        value: _pos,
                        items: _posOptions,
                        onChanged: (v) {
                          _pos = v!;
                          _applyFilters();
                        },
                        label: 'Poste',
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Équipe (plus de place)
                    Expanded(
                      flex: 2,
                      child: _Dropdown(
                        value: _team,
                        items: _teamOptions,
                        onChanged: (v) {
                          _team = v!;
                          _applyFilters();
                        },
                        label: 'Équipe',
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Tri
                    Expanded(
                      flex: 1,
                      child: _Dropdown(
                        value: _sort,
                        items: const ['OVR ↓', 'OVR ↑', 'POT ↓', 'Âge ↓', 'Âge ↑'],
                        onChanged: (v) {
                          _sort = v!;
                          _applyFilters();
                        },
                        label: 'Tri',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Compteur
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_visible.length} joueurs',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          const Divider(height: 1),
          // Liste
          Expanded(
            child: ListView.separated(
              itemCount: _visible.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _PlayerTile(player: _visible[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.label,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isDense: true,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      items: items.map((e) => DropdownMenuItem(
        value: e, 
        child: Text(
          e, 
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      )).toList(),
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player});
  final Map<String, dynamic> player;

  @override
  Widget build(BuildContext context) {
    final ratings = (player['ratings'] ?? const {}) as Map;
    final bio = (player['bio'] ?? const {}) as Map;
    final team = (player['team'] ?? const {}) as Map;

    final ovr = (ratings['overall'] ?? 0).toString();
    final pot = (ratings['potential'] ?? 0).toString();
    final age = (bio['age'] is num) ? (bio['age'] as num).toInt() : null;

    final name = (player['full_name'] ?? 'Inconnu').toString();
    final pos = (player['position_primary'] ?? '??').toString();
    final tName = (team['team_name'] ?? 'Sans équipe').toString();

    return ListTile(
      leading: CircleAvatar(child: Text(pos)),
      title: Text('$name  •  OVR $ovr'),
      subtitle: Text('Âge ${age ?? '-'}  •  POT $pot  •  $tName'),
      trailing: TextButton(
        child: const Text('Approcher'),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Approcher $name — à venir')),
          );
        },
      ),
    );
  }
}
