import 'package:hive_flutter/hive_flutter.dart';
import '../systems/character_stats.dart';

class GameStorage {
  static late Box<Map> _gameBox;
  
  static Future<void> initialize() async {
    await Hive.initFlutter();
    _gameBox = await Hive.openBox<Map>('game_data');
  }
  
  static Future<void> savePlayerData(CharacterStats stats) async {
    await _gameBox.put('player_stats', stats.toJson());
  }
  
  static CharacterStats? loadPlayerData() {
    final data = _gameBox.get('player_stats');
    if (data != null) {
      return CharacterStats.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }
  
  static Future<void> saveHighScore(int score) async {
    await _gameBox.put('high_score', score);
  }
  
  static int getHighScore() {
    return _gameBox.get('high_score', defaultValue: 0);
  }
} 