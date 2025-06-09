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

enum EnemyState { seeking, attacking, dying }

class Enemy extends SpriteAnimationComponent with HasGameRef<ArcheroGame>, CollisionCallbacks {
  double speed = 50.0;
  double health = 80.0;
  double maxHealth = 80.0;
  bool isDying = false;
  
  late final Player player;
  late final Timer _shootTimer;

  Enemy({required super.position}) : super(size: Vector2.all(64), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    player = gameRef.player;
    // Daha dinamik ateş aralığı (1.8-2.5 saniye arası)
    final shootInterval = 1.8 + (math.Random().nextDouble() * 0.7);
    _shootTimer = Timer(shootInterval, onTick: _shootAtPlayer, repeat: true);

    animation = await gameRef.loadSpriteAnimation(
      'enemy.png',
      SpriteAnimationData.sequenced(amount: 1, stepTime: 0.2, textureSize: Vector2(64, 64)),
    );
    
    add(RectangleHitbox(isSolid: true, size: size * 0.8));
    _shootTimer.start();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDying || !player.isMounted || player.isDying) {
      return;
    }
    
    _shootTimer.update(dt);
    
    final distanceToPlayer = position.distanceTo(player.position);
    
    // Geliştirilmiş AI davranışı
    if (distanceToPlayer > 180) {
      // Uzaktaysa yaklaş
      final direction = (player.position - position).normalized();
      position.add(direction * speed * dt);
    } else if (distanceToPlayer < 120) {
      // Çok yakınsa geri çekil ve yan hareket yap
      final direction = (position - player.position).normalized();
      // Sağa-sola hareket de ekle
      final sideMovement = Vector2(-direction.y, direction.x) * 0.5;
      final finalDirection = (direction + sideMovement).normalized();
      position.add(finalDirection * speed * dt * 0.6);
    } else {
      // Optimal mesafede yan hareket yap
      final toPlayer = (player.position - position).normalized();
      final sideDirection = Vector2(-toPlayer.y, toPlayer.x);
      // Rastgele yan hareket
      final sideMovement = sideDirection * (math.Random().nextBool() ? 1 : -1);
      position.add(sideMovement * speed * dt * 0.3);
    }
  }

  void _shootAtPlayer() {
    if (!isMounted || isDying || !player.isMounted || player.isDying) return;
    
    final distanceToPlayer = position.distanceTo(player.position);
    if (distanceToPlayer > 350) return; // Ateş menzili

    // Oyuncunun hareketini tahmin et
    final playerVelocity = player.isMoving ? player.joystick.relativeDelta * player.speed : Vector2.zero();
    final timeToReach = distanceToPlayer / 400; // Bullet speed
    final predictedPosition = player.position + playerVelocity * timeToReach * 0.5;
    
    final direction = (predictedPosition - position).normalized();
    
    final bullet = Bullet();
    bullet.initialize(
      position + direction * 32,
      direction,
      false,
      'enemy_bullet.png',
    );
    
    bullet.damage = 12; // Enemy bullet hasarı azaltıldı (15'ten 12'ye)
    gameRef.world.add(bullet);
  }

  void takeDamage(double amount) {
    if (isDying) return;
    
    health -= amount;
    
    add(ScaleEffect.by(Vector2.all(1.2), EffectController(duration: 0.1, reverseDuration: 0.1)));
    
    if (health <= 0) {
      isDying = true;
      _die();
    }
  }
  
  void _die() {
    _shootTimer.stop();
    
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
      other.takeDamage(10); // Azaltıldı (20'den 10'a)
    }
  }
} 