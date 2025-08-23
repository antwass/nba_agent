// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Important : on importe le StartScreen (menu) et on garde GameController
// accessible car son provider est global dans l'app.
import 'features/start/start_screen.dart';
import 'features/home/game_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  print('🚀 DÉMARRAGE NBA AGENT - Version de test');
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NBA Agent (MVP)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
        useMaterial3: true,
      ),
      home: const StartScreen(), // Page d’accueil (créer/sélectionner une partie)
    );
  }
}
