import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../domain/entities.dart';
import '../../domain/usecases/approach_player.dart';
import '../home/game_controller.dart';

class ApproachEmailScreen extends ConsumerStatefulWidget {
  final Player player;
  final int probability;

  const ApproachEmailScreen({
    super.key,
    required this.player,
    required this.probability,
  });

  @override
  ConsumerState<ApproachEmailScreen> createState() => _ApproachEmailScreenState();
}

class _ApproachEmailScreenState extends ConsumerState<ApproachEmailScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? _playerResponse;
  bool _hasApproached = false;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _messageController.text = _generateDefaultMessage();
  }

  String _generateDefaultMessage() {
    return '''Bonjour ${widget.player.name},

Je suis un agent sportif spécialisé dans le basketball professionnel et je suis impressionné par vos performances cette saison.

Je serais honoré de discuter avec vous de la possibilité de vous représenter. Mon expertise et mon réseau peuvent vous aider à :
- Négocier les meilleurs contrats
- Développer votre image de marque
- Gérer vos intérêts commerciaux
- Planifier votre carrière à long terme

Seriez-vous disponible pour un entretien ?

Cordialement,
Agent''';
  }

  void _sendApproach() {
    final game = ref.read(gameControllerProvider);
    if (game.league == null) return;

    final result = approachPlayer(
      league: game.league!,
      playerId: widget.player.id,
    );

    ref.read(gameControllerProvider.notifier).approachPlayer(
      result.league, // On passe la ligue mise à jour depuis le résultat
      result,
    );

    setState(() {
      _hasApproached = true;
      _success = result.success;

      if (result.success) {
        _playerResponse = _generatePositiveResponse();
      } else {
        _playerResponse = _generateNegativeResponse();
      }
    });
  }

  String _generatePositiveResponse() {
    final responses = [
      "Bonjour Agent,\n\nVotre proposition m'intéresse beaucoup. J'ai entendu de bonnes choses sur votre travail.\n\nAcceptons de travailler ensemble !\n\nCordialement,\n${widget.player.name}",
      "Salut,\n\nParfait timing ! Je cherchais justement un nouvel agent.\n\nJe suis partant pour qu'on travaille ensemble.\n\n${widget.player.name}",
      "Bonjour,\n\nVos références sont impressionnantes. Je pense qu'on peut faire de grandes choses ensemble.\n\nC'est d'accord pour moi.\n\nBien à vous,\n${widget.player.name}",
    ];
    return responses[Random().nextInt(responses.length)];
  }

  String _generateNegativeResponse() {
    final responses = [
      "Bonjour,\n\nMerci pour votre intérêt, mais je ne cherche pas d'agent actuellement.\n\nBonne continuation.\n\n${widget.player.name}",
      "Salut,\n\nJ'apprécie votre offre mais je préfère gérer ma carrière seul pour le moment.\n\nCordialement,\n${widget.player.name}",
      "Bonjour Agent,\n\nJe ne pense pas que ce soit le bon moment pour moi. Peut-être une prochaine fois.\n\nMerci quand même.\n\n${widget.player.name}",
    ];
    return responses[Random().nextInt(responses.length)];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau message'),
        actions: [
          if (!_hasApproached)
            TextButton.icon(
              onPressed: _sendApproach,
              icon: const Icon(Icons.send),
              label: const Text('Envoyer'),
            ),
        ],
      ),
      body: Container(
        color: Colors.grey[50],
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // En-tête email
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('À: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            '${widget.player.name} <${widget.player.name.toLowerCase().replaceAll(' ', '.')}@basketball.com>',
                            style: const TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Objet: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Expanded(
                          child: Text('Proposition de représentation'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.amber[800]),
                          const SizedBox(width: 8),
                          Text(
                            'Probabilité de succès: ${widget.probability}%',
                            style: TextStyle(color: Colors.amber[800], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Zone de message
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!_hasApproached) ...[
                      TextField(
                        controller: _messageController,
                        maxLines: 15,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Écrivez votre message...',
                        ),
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ] else ...[
                      // Message envoyé
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 16),
                                const SizedBox(width: 8),
                                const Text('Vous', style: TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text(
                                  'Envoyé',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _messageController.text,
                              style: TextStyle(color: Colors.grey[700], height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Réponse du joueur
                      if (_playerResponse != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _success ? Colors.green[50] : Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _success ? Colors.green[200]! : Colors.orange[200]!,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    child: Text(widget.player.pos.name.substring(0, 1)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.player.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    _success ? Icons.check_circle : Icons.cancel,
                                    size: 20,
                                    color: _success ? Colors.green : Colors.orange,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _playerResponse!,
                                style: const TextStyle(height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            // Infos du joueur
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profil du joueur',
                      style: theme.textTheme.titleSmall,
                    ),
                    const Divider(),
                    _InfoRow('Nom', widget.player.name),
                    _InfoRow('Position', widget.player.pos.name),
                    _InfoRow('Âge', '${widget.player.age} ans'),
                    _InfoRow('Overall', widget.player.overall.toString()),
                    _InfoRow('Forme', widget.player.form >= 0 ? '+${widget.player.form}' : '${widget.player.form}'),
                  ],
                ),
              ),
            ),

            // Actions
            if (_hasApproached) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_success)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context); // Retour au market
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Retour au marché'),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Retour'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}