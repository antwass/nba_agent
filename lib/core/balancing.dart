import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class Balancing {
  final int cap;
  final double luxuryTaxFactor;
  final double offerAggressiveness;
  const Balancing({
    required this.cap,
    required this.luxuryTaxFactor,
    required this.offerAggressiveness,
  });
  factory Balancing.fromJson(Map<String, dynamic> j) => Balancing(
    cap: j['cap'] as int,
    luxuryTaxFactor: (j['luxuryTaxFactor'] as num).toDouble(),
    offerAggressiveness: (j['offerAggressiveness'] as num).toDouble(),
  );
}

Future<Balancing> loadBalancing() async {
  final raw = await rootBundle.loadString('assets/config/balancing.json');
  return Balancing.fromJson(json.decode(raw) as Map<String, dynamic>);
}
