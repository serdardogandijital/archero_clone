import 'dart:async';
import 'dart:math' as math;
import 'package:archero_clone/components/weapon_system.dart';
import 'package:archero_clone/game/archero_game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/sprite.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'bullet.dart';
import 'enemy.dart';
import 'experience_orb.dart';

class Player extends SpriteAnimationComponent with HasGameRef<ArcheroGame>, CollisionCallbacks {
  final JoystickComponent joystick;
  final Vector2 _moveDirection = Vector2.zero();
  bool isMoving = false;
  
  // STATS
  double speed = 180.0;
  double maxHealth = 250.0;
  int level = 1;
  double experience = 0.0;
  double maxExperience = 100.0;

  // NOTIFIERS FOR UI
  late final ValueNotifier<double> healthNotifier;
  late final ValueNotifier<int> levelNotifier;
  late final ValueNotifier<double> experienceNotifier;

  // STATE
  bool isDying = false;
  final math.Random random = math.Random();
  Timer? _shootTimer;
  Timer? _regenTimer;
  int _debugCounter = 0; // Debug counter

  // UPGRADES
  double baseDamage = 30.0;
  double damageMultiplier = 1.0;
  double baseAttackInterval = 0.45;
  bool hasDoubleShot = false;
  bool hasPiercing = false;
  double criticalChance = 0.0;
  double regenAmount = 0.0;

  Player({required this.joystick}) : super(size: Vector2.all(64), anchor: Anchor.center) {
    healthNotifier = ValueNotifier(maxHealth);
    levelNotifier = ValueNotifier(level);
    experienceNotifier = ValueNotifier(experience);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    animation = await gameRef.loadSpriteAnimation(
      'player.png',
      SpriteAnimationData.sequenced(amount: 1, stepTime: 1, textureSize: Vector2(64, 64)),
    );
    
    add(RectangleHitbox(isSolid: true, size: size * 0.8));
    
    _shootTimer = Timer(baseAttackInterval, onTick: _shoot, repeat: true)..start();
    _regenTimer = Timer(5.0, onTick: _regenerateHealth, repeat: true)..start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDying) return;

    _shootTimer?.update(dt);
    _regenTimer?.update(dt);

    // Joystick hareketi - daha hassas hareket algılama
    if (joystick.intensity > 0.1) { // Düşük threshold
      final movement = joystick.relativeDelta * speed * dt * 3.0; // 3x hassasiyet
      position.add(movement);
      isMoving = true;
    } else if (!_moveDirection.isZero()) {
      position.add(_moveDirection.normalized() * speed * dt);
      _moveDirection.setZero();
      isMoving = true;
    } else {
      isMoving = false;
    }
    
    // Ekran sınırları kaldırıldı - oyuncu özgürce hareket edebilir
  }

  void _shoot() {
    if (!isMounted || isDying) return;

    final nearestEnemy = game.world.children.whereType<Enemy>().fold<Enemy?>(
      null,
      (previous, enemy) {
        if (enemy.isDying) return previous;
        final distance = position.distanceTo(enemy.position);
        if (previous == null || distance < position.distanceTo(previous.position)) {
          return enemy;
        }
        return previous;
      },
    );

    if (nearestEnemy != null && position.distanceTo(nearestEnemy.position) < 800) {
      final direction = (nearestEnemy.position - position).normalized();
      _createMuzzleFlash(direction);
      _createBullet(direction);
      if (hasDoubleShot) {
        final secondDirection = Vector2(direction.x * math.cos(0.15) - direction.y * math.sin(0.15), direction.x * math.sin(0.15) + direction.y * math.cos(0.15));
        _createBullet(secondDirection);
      }
    }
  }

  void _createBullet(Vector2 direction) {
    final bullet = Bullet();
    
    bullet.initialize(
      position + direction * 30,
      direction,
      true,
      'bullet.png',
    );

    bullet.damage = baseDamage * damageMultiplier;
    bullet.hasPiercing = hasPiercing;
    gameRef.world.add(bullet);
  }

  void _createMuzzleFlash(Vector2 direction) {
    try {
      // Muzzle flash animasyonu
      final flash = SpriteAnimationComponent(
        animation: SpriteAnimation.fromFrameData(
          gameRef.images.fromCache('muzzle_flash.png'),
          SpriteAnimationData.sequenced(
            amount: 4, 
            stepTime: 0.08, // Biraz daha yavaş
            textureSize: Vector2.all(32), 
            loop: false
          ),
        ),
        position: position + direction * 32,
        angle: math.atan2(direction.y, direction.x),
        size: Vector2.all(48), // Daha büyük
        anchor: Anchor.center,
        removeOnFinish: true,
      );
      
      // Parlama efekti ekle
      flash.add(
        ScaleEffect.by(
          Vector2.all(1.3),
          EffectController(duration: 0.1, reverseDuration: 0.1),
        ),
      );
      
      gameRef.world.add(flash);
    } catch (e) {
      print('Muzzle flash yükleme hatası: $e');
      // Fallback: Basit parlama efekti
      final flashEffect = CircleComponent(
        radius: 16,
        paint: Paint()..color = Colors.orange.withOpacity(0.8),
        position: position + direction * 32,
        anchor: Anchor.center,
      );
      
      flashEffect.add(
        SequenceEffect([
          ScaleEffect.by(Vector2.all(1.5), EffectController(duration: 0.1)),
          OpacityEffect.fadeOut(EffectController(duration: 0.2)),
          RemoveEffect(),
        ]),
      );
      
      gameRef.world.add(flashEffect);
    }
  }

  void takeDamage(double damage) {
    if (isDying) return;
    healthNotifier.value -= damage;
    add(ScaleEffect.by(Vector2.all(1.2), EffectController(duration: 0.1, reverseDuration: 0.1)));
    if (healthNotifier.value <= 0) {
      _die();
    }
  }

  void _die() {
    isDying = true;
    _shootTimer?.stop();
    _regenTimer?.stop();
    add(ScaleEffect.to(Vector2.zero(), EffectController(duration: 1.5), onComplete: () {
      removeFromParent();
    }));
    gameRef.showGameOver();
  }

  void gainExperience(double amount) {
    experience += amount;
    if (experience >= maxExperience) {
      levelUp();
    }
    experienceNotifier.value = experience;
  }

  void levelUp() {
    level++;
    experience = 0;
    maxExperience *= 1.5;
    
    levelNotifier.value = level;
    experienceNotifier.value = experience;
    
    maxHealth *= 1.1;
    healthNotifier.value = maxHealth;
    
    gameRef.showLevelUpScreen();
  }

  void _regenerateHealth() {
    if (isDying || regenAmount == 0) return;
    if (healthNotifier.value < maxHealth) {
      healthNotifier.value = math.min(maxHealth, healthNotifier.value + regenAmount);
    }
  }

  // UPGRADE METHODS
  void increaseDamage(double percentage) => damageMultiplier += percentage;
  void increaseAttackSpeed(double percentage) {
    final newInterval = baseAttackInterval / (1 + percentage);
    _shootTimer?.stop();
    _shootTimer = Timer(newInterval, onTick: _shoot, repeat: true)..start();
  }
  void increaseMaxHealth(double percentage) {
    maxHealth *= (1 + percentage);
    healthNotifier.value = maxHealth;
  }
  void increaseSpeed(double percentage) => speed *= (1 + percentage);
  void enableDoubleShot() => hasDoubleShot = true;
  void enablePiercing() => hasPiercing = true;
  void enableCriticalHit(double chance) => criticalChance += chance;
  void enableHpRegen(double amount) => regenAmount += amount;

  @override
  void onRemove() {
    healthNotifier.dispose();
    levelNotifier.dispose();
    experienceNotifier.dispose();
    super.onRemove();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (other is ExperienceOrb) {
      gainExperience(other.experienceValue);
      other.removeFromParent();
    }
  }

  void move(Vector2 delta) {
    _moveDirection.add(delta);
  }

  void stopMovement() {
    _moveDirection.setZero();
  }
}