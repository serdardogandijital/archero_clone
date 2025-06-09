import 'dart:math' as math;
import 'package:archero_clone/components/experience_orb.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../components/bullet.dart';
import '../components/player.dart';
import '../components/enemy.dart';
import '../components/upgrade_system.dart';
import '../ui/game_over_overlay.dart';
import '../ui/hud_overlay.dart';
import '../ui/level_up_overlay.dart';

class ArcheroGame extends FlameGame with HasCollisionDetection, PanDetector, DragCallbacks {
  late Player player;
  late JoystickComponent joystick;
  late UpgradeSystem upgradeSystem;
  
  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);
  int get score => scoreNotifier.value;
  set score(int value) => scoreNotifier.value = value;

  final ValueNotifier<int> waveNotifier = ValueNotifier(1);
  int get waveNumber => waveNotifier.value;
  set waveNumber(int value) => waveNotifier.value = value;

  int highScore = 0;
  int enemiesKilled = 0;
  int enemiesPerWave = 3;
  double difficultyMultiplier = 1.0;
  
  final math.Random random = math.Random();
  bool isGamePaused = false;
  bool isSpawningWave = false;
  Timer? difficultyTimer;
  Timer? _waveTransitionTimer;
  List<String> messageQueue = [];
  Component? messageText;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    camera.viewfinder.anchor = Anchor.center;
    
    print('Assetler yükleniyor...');
    try {
      await images.loadAll([
        'player.png',
        'enemy.png',
        'bullet.png',
        'enemy_bullet.png',
        'muzzle_flash.png',
        'xp_orb.png',
        'background.png',
        'joystick_background.png',
        'joystick_knob.png',
      ]);
      print('Tüm assetler yüklendi.');
    } catch (e) {
      print('Asset yükleme hatası: $e');
    }
    
    // Büyük tile'lı arka plan oluştur
    try {
      final bgSprite = Sprite(images.fromCache('background.png'));
      // 3x3 = 9 background tile oluştur
      for (int x = -1; x <= 1; x++) {
        for (int y = -1; y <= 1; y++) {
          final backgroundTile = SpriteComponent(
            sprite: bgSprite,
            size: size,
            position: Vector2(x * size.x, y * size.y),
            priority: -10,
          );
          add(backgroundTile);
        }
      }
    } catch (e) {
      print('Arka plan yükleme hatası: $e');
      // Fallback renk
      final background = RectangleComponent(
        size: size * 3, // 3x büyük alan
        position: -size, // Merkezi hizala
        paint: Paint()..color = const Color.fromARGB(255, 30, 30, 60),
        priority: -10,
      );
      add(background);
    }
    
    world = World();
    add(world);
    
    _initializeGameSession();
  }
  
  void _initializeGameSession() {
    // Önceki oturumdan kalan mesajları temizle
    messageQueue.clear();
    messageText?.removeFromParent();
    messageText = null;

    // Daha büyük ve hassas joystick
    joystick = JoystickComponent(
      background: CircleComponent(
        radius: 90, // Büyütüldü
        paint: Paint()..color = Colors.blue.withOpacity(0.4),
      ),
      knob: CircleComponent(
        radius: 40, // Büyütüldü
        paint: Paint()..color = Colors.blue.withOpacity(0.9),
      ),
      margin: EdgeInsets.only(
        left: size.x * 0.05,
        bottom: size.y * 0.08,
      ),
      priority: 1000,
    );
    add(joystick);

    player = Player(joystick: joystick);
    world.add(player);
    player.position = Vector2.zero(); // Dünya merkezinde başla
    
    // Kamerayı serbest hareket için ayarla
    camera.follow(player);
    camera.viewfinder.visibleGameSize = size;
    // Kamera sınırları olmadan serbest hareket
    
    upgradeSystem = UpgradeSystem(player: player);
    add(upgradeSystem);
    
    startSpawners();
  }
  
  void startSpawners() {
    difficultyTimer?.stop();
    difficultyTimer = Timer(30.0, onTick: _increaseDifficulty, repeat: true)..start();
    _checkWaveCompletion();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGamePaused) return;
    
    difficultyTimer?.update(dt);
    _waveTransitionTimer?.update(dt);
    
    _checkWaveCompletion();
    _updateMessageDisplay(dt);
  }
  
  void _spawnEnemies() {
    if (isGamePaused) return;

    final enemiesToSpawn = math.min(enemiesPerWave, 12); // Max 12 enemies (azaltıldı)
    for (int i = 0; i < enemiesToSpawn; i++) {
      final playerPos = player.isMounted ? player.position : Vector2.zero();
      final spawnDistance = 400.0 + (random.nextDouble() * 200.0); // Daha uzak spawn
      final angle = random.nextDouble() * 2 * math.pi;
      
      final position = Vector2(
        playerPos.x + math.cos(angle) * spawnDistance,
        playerPos.y + math.sin(angle) * spawnDistance,
      );
      
      // Ekran sınırı kontrolü kaldırıldı - dünyada herhangi bir yerde spawn olabilir
      
      final enemy = Enemy(position: position);
      // Daha dengeli zorluk artışı
      enemy.maxHealth *= (1.0 + (difficultyMultiplier - 1.0) * 0.6); // Daha az HP artışı
      enemy.health = enemy.maxHealth;
      enemy.speed *= (1.0 + (difficultyMultiplier - 1.0) * 0.3); // Daha az hız artışı
      world.add(enemy);
    }
  }
  
  void _checkWaveCompletion() {
    if (isGamePaused || isSpawningWave || (player.isMounted && player.isDying)) return;

    final enemies = world.children.whereType<Enemy>();
    if (enemies.isEmpty) {
      isSpawningWave = true;
      
      if (waveNumber > 1) { // Don't show for the first wave
        showMessage('Dalga $waveNumber Temizlendi!');
      }

      // Biraz daha uzun ara (2.5 saniye)
      _waveTransitionTimer = Timer(2.5, onTick: _startNextWave)..start();
    }
  }

  void _startNextWave() {
    waveNumber++;
    // Daha yavaş dalga büyümesi
    enemiesPerWave = math.min(enemiesPerWave + 1, 12);
    showMessage('Dalga $waveNumber');
    _spawnEnemies();
    isSpawningWave = false;
    _waveTransitionTimer = null;
  }
  
  void _increaseDifficulty() {
    difficultyMultiplier += 0.08; // Daha yavaş zorluk artışı (0.1'den 0.08'e)
    showMessage('Zorluk arttı! (${(difficultyMultiplier * 100).toStringAsFixed(0)}%)');
  }
  
  void showLevelUpScreen() {
    if (isGamePaused) return;
    pauseGame();
    overlays.add('LevelUp');
  }
  
  void applyUpgrade(Upgrade upgrade) {
    upgradeSystem.applyUpgrade(upgrade);
  }
  
  void showMessage(String message) {
    messageQueue.add(message);
  }
  
  void _updateMessageDisplay(double dt) {
    if (messageQueue.isEmpty || (messageText?.isMounted ?? false)) return;
    
    final textComponent = TextComponent(
      text: messageQueue.removeAt(0),
      anchor: Anchor.center,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white, fontSize: size.x * 0.06, fontWeight: FontWeight.bold,
          shadows: const [Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2))],
        ),
      ),
    );

    final container = PositionComponent(
      position: Vector2(size.x / 2, size.y * 0.25),
      children: [textComponent],
    );
    messageText = container;

    container.add(
      ScaleEffect.by(
        Vector2.all(1.2),
        EffectController(duration: 0.3, reverseDuration: 0.3),
        onComplete: () {
          Future.delayed(const Duration(seconds: 2), () {
            if (container.isMounted) {
              container.add(
                SequenceEffect([
                  ScaleEffect.to(Vector2.zero(), EffectController(duration: 0.5)),
                  RemoveEffect(),
                ])..onComplete = () => messageText = null,
              );
            } else {
              messageText = null;
            }
          });
        },
      ),
    );
    
    add(container);
  }
  
  void addScore(int points) {
    score += points;
    if (score > highScore) {
      highScore = score;
    }
  }
  
  void pauseGame() {
    if (!isGamePaused) {
      isGamePaused = true;
      pauseEngine();
    }
  }
  
  void resumeGame() {
    if (isGamePaused) {
      isGamePaused = false;
      resumeEngine();
    }
  }
  
  void showGameOver() {
    pauseGame();
    overlays.add('GameOver');
  }
  
  void restartGame() {
    // Zamanlayıcıları durdur
    difficultyTimer?.stop();
    _waveTransitionTimer?.stop();
    _waveTransitionTimer = null;

    // Önceki oturumdaki tüm bileşenleri temizle
    world.removeAll(world.children);
    removeWhere((c) => c is UpgradeSystem);
    removeWhere((c) => c is JoystickComponent);
     
    // Oyun durumunu sıfırla
    score = 0;
    waveNumber = 1;
    enemiesPerWave = 3;
    difficultyMultiplier = 1.0;
    isSpawningWave = false;
    
    // Oyunu yeniden başlat
    _initializeGameSession();
    
    // "Game Over" ekranını kaldır ve oyunu devam ettir
    overlays.remove('GameOver');
    resumeGame();
  }
  
  @override
  void onRemove() {
    difficultyTimer?.stop();
    _waveTransitionTimer?.stop();
    scoreNotifier.dispose();
    waveNotifier.dispose();
    super.onRemove();
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    player.move(info.delta.global);
  }

  @override
  void onPanEnd(DragEndInfo info) {
    player.stopMovement();
  }
} 