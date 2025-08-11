import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'balancing.dart';

final balancingProvider = FutureProvider<Balancing>((ref) async {
  return loadBalancing();
});