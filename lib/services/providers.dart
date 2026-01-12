import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../configs/config.dart';
import '../models/game.dart';
import 'notifiers.dart';

final boardOfflineProvider = StateNotifierProvider.family<OfflineGameNotifier, GameState, OfflineConfig>((ref, config) {
  return OfflineGameNotifier(config);
});
final boardOnlineProvider = StateNotifierProvider.family<OnlineGameNotifier, GameState, OnlineConfig>((ref, config) {
  return OnlineGameNotifier(config);
});

final offlineConfigProvider = StateProvider<OfflineConfig>((ref) {
  return OfflineConfig();
});

