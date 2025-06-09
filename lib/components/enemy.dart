import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flame/sprite.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../game/archero_game.dart';
import 'bullet.dart';
import 'player.dart';
import 'experience_orb.dart';
import '../effects/explosion_effect.dart';

enum EnemyState { seeking, attacking, dying, circling }

class Enemy extends SpriteAnimationComponent with HasGameRef<ArcheroGame>, CollisionCallbacks {
  double speed = 50.0;
  double health = 80.0;
  double maxHealth = 80.0;
  bool isDying = false;
  EnemyState currentState = EnemyState.seeking;
  
  late final Player player;
  late final Timer _shootTimer;
  late final Timer _stateChangeTimer;
  Vector2 _separationForce = Vector2.zero();
  double _lastShootTime = 0;

  Enemy({required super.position}) : super(size: Vector2.all(64), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    player = gameRef.player;
    // Daha dinamik ateş aralığı (1.8-2.5 saniye arası)
    final shootInterval = 1.8 + (math.Random().nextDouble() * 0.7);
    _shootTimer = Timer(shootInterval, onTick: _shootAtPlayer, repeat: true);
    
    // Durum değişikliği timer'ı
    _stateChangeTimer = Timer(2.0 + math.Random().nextDouble() * 3.0, onTick: _changeState, repeat: true);

    animation = await gameRef.loadSpriteAnimation(
      'enemy.png',
      SpriteAnimationData.sequenced(amount: 1, stepTime: 0.2, textureSize: Vector2(64, 64)),
    );
    
    add(RectangleHitbox(isSolid: true, size: size * 0.6)); // Hitbox biraz küçültüldü
    _shootTimer.start();
    _stateChangeTimer.start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDying || !player.isMounted || player.isDying) {
      return;
    }
    
    _shootTimer.update(dt);
    _stateChangeTimer.update(dt);
    _lastShootTime += dt;
    
    // Düşman ayrılma sistemi - diğer düşmanlarla iç içe geçmeyi engelle
    _calculateSeparationForce();
    
    final distanceToPlayer = position.distanceTo(player.position);
    Vector2 moveDirection = Vector2.zero();
    
    // Geliştirilmiş AI davranışı - state machine
    switch (currentState) {
      case EnemyState.seeking:
        if (distanceToPlayer > 200) {
          // Oyuncuya doğru hareket et
          moveDirection = (player.position - position).normalized();
        } else {
          currentState = EnemyState.attacking;
        }
        break;
        
      case EnemyState.attacking:
        if (distanceToPlayer < 80) {
          // Çok yakınsa geri çekil
          moveDirection = (position - player.position).normalized() * 0.7;
        } else if (distanceToPlayer > 250) {
          // Çok uzaksa tekrar yaklaş
          currentState = EnemyState.seeking;
        } else {
          // Optimal mesafede yan hareket yap
          final toPlayer = (player.position - position).normalized();
          final sideDirection = Vector2(-toPlayer.y, toPlayer.x);
          final randomFactor = (math.Random().nextDouble() - 0.5) * 2;
          moveDirection = sideDirection * randomFactor * 0.8;
        }
        break;
        
      case EnemyState.circling:
        // Oyuncu etrafında çember çiz
        final toPlayer = (player.position - position).normalized();
        final tangent = Vector2(-toPlayer.y, toPlayer.x);
        moveDirection = tangent;
        
        // Mesafeyi kontrol et
        if (distanceToPlayer < 120) {
          moveDirection += (position - player.position).normalized() * 0.5;
        } else if (distanceToPlayer > 200) {
          moveDirection += (player.position - position).normalized() * 0.3;
        }
        break;
        
      case EnemyState.dying:
        // Ölüyor, hareket etme
        return;
    }
    
    // Ayrılma kuvveti ekle
    moveDirection += _separationForce;
    
    // Hareket uygula
    if (!moveDirection.isZero()) {
      position.add(moveDirection.normalized() * speed * dt);
    }
  }

  void _calculateSeparationForce() {
    _separationForce.setZero();
    final nearbyEnemies = gameRef.world.children.whereType<Enemy>()
        .where((enemy) => enemy != this && !enemy.isDying)
        .where((enemy) => position.distanceTo(enemy.position) < 100);
    
    for (final enemy in nearbyEnemies) {
      final distance = position.distanceTo(enemy.position);
      if (distance > 0 && distance < 80) {
        final force = (position - enemy.position).normalized() * (80 - distance) / 80;
        _separationForce += force;
      }
    }
    
    if (!_separationForce.isZero()) {
      _separationForce.normalize();
      _separationForce *= 0.5; // Ayrılma kuvveti şiddeti
    }
  }

  void _changeState() {
    if (isDying) return;
    
    final distanceToPlayer = position.distanceTo(player.position);
    final random = math.Random();
    
    // Durum değişikliği mantığı
    if (distanceToPlayer > 300) {
      currentState = EnemyState.seeking;
    } else if (distanceToPlayer < 100) {
      currentState = random.nextBool() ? EnemyState.attacking : EnemyState.circling;
    } else {
      // Rastgele durum seç
      final states = [EnemyState.attacking, EnemyState.circling];
      currentState = states[random.nextInt(states.length)];
    }
  }

  void _shootAtPlayer() {
    if (!isMounted || isDying || !player.isMounted || player.isDying) return;
    
    final distanceToPlayer = position.distanceTo(player.position);
    if (distanceToPlayer > 350) return; // Ateş menzili
    
    // Çok sık ateş etmeyi engelle
    if (_lastShootTime < 0.8) return;
    _lastShootTime = 0;

    // Oyuncunun hareketini tahmin et - daha gelişmiş tahmin
    final playerVelocity = player.isMoving ? player.joystick.relativeDelta * player.speed : Vector2.zero();
    final timeToReach = distanceToPlayer / 400; // Bullet speed
    final predictedPosition = player.position + playerVelocity * timeToReach * 0.7; // Daha iyi tahmin
    
    final direction = (predictedPosition - position).normalized();
    
    final bullet = Bullet();
    bullet.initialize(
      position + direction * 32,
      direction,
      false,
      'enemy_bullet.png',
    );
    
    bullet.damage = 12; // Enemy bullet hasarı
    gameRef.world.add(bullet);
  }

  void takeDamage(double amount) {
    if (isDying) return;
    
    health -= amount;
    
    add(ScaleEffect.by(Vector2.all(1.2), EffectController(duration: 0.1, reverseDuration: 0.1)));
    
    if (health <= 0) {
      isDying = true;
      currentState = EnemyState.dying;
      _die();
    }
  }
  
  void _die() {
    _shootTimer.stop();
    _stateChangeTimer.stop();
    
    add(
      ScaleEffect.to(Vector2.zero(), EffectController(duration: 0.4),
        onComplete: () {
          gameRef.addScore(10);
          gameRef.world.add(ExperienceOrb(position: position));
          removeFromParent();
        },
      ),
    );
    gameRef.world.add(ExplosionEffect(position: position));
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    if (isDying) return;

    if (other is Bullet && other.isPlayerBullet) {
      if (!other.hitTargets.contains(this)) {
        takeDamage(other.damage);
        other.handleHit(this);
      }
    } else if (other is Player) {
      other.takeDamage(8); // Daha da azaltıldı (10'dan 8'e)
    }
  }

  @override
  void onRemove() {
    _shootTimer.stop();
    _stateChangeTimer.stop();
    super.onRemove();
  }
} 