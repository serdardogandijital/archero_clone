import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import '../game/archero_game.dart';
import 'enemy.dart';

class EnemySpawner extends Component with HasGameRef<ArcheroGame> {
  double spawnInterval = 2.0;
  int maxEnemies = 10;
  
  @override
  void onMount() {
    super.onMount();
    add(TimerComponent(
      period: spawnInterval,
      repeat: true,
      onTick: _spawnEnemy,
    ));
  }
  
  void _spawnEnemy() {
    final currentEnemies = gameRef.world.children.whereType<Enemy>().length;
    if (currentEnemies < maxEnemies) {
      final spawnPosition = _getRandomSpawnPosition();
      gameRef.world.add(Enemy(position: spawnPosition));
    }
  }
  
  Vector2 _getRandomSpawnPosition() {
    final random = Random();
    final side = random.nextInt(4);
    
    switch (side) {
      case 0: // Top
        return Vector2(random.nextDouble() * gameRef.size.x, -50);
      case 1: // Right
        return Vector2(gameRef.size.x + 50, random.nextDouble() * gameRef.size.y);
      case 2: // Bottom
        return Vector2(random.nextDouble() * gameRef.size.x, gameRef.size.y + 50);
      default: // Left
        return Vector2(-50, random.nextDouble() * gameRef.size.y);
    }
  }
} 