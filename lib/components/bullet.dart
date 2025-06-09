import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:flame/sprite.dart';
import 'package:flame/effects.dart';
import '../game/archero_game.dart';
import 'enemy.dart';
import 'player.dart';
import '../effects/explosion_effect.dart';

class Bullet extends SpriteComponent with HasGameRef<ArcheroGame>, CollisionCallbacks {
  Vector2 direction = Vector2.zero();
  bool isPlayerBullet = true;
  String spritePath = '';
  double speed = 500;
  double damage = 25;
  bool hitSomething = false;
  bool hasPiercing = false;
  int pierceCount = 0;
  int maxPierceCount = 3;
  final List<Component> hitTargets = [];

  Bullet() : super(size: Vector2.all(20), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Varsayılan sprite ayarla
    sprite = await gameRef.loadSprite('bullet.png');
    
    add(RectangleHitbox(isSolid: true));
    
    // Trail efekti ekle
    add(
      TrailEffect(
        isPlayerBullet
            ? Colors.blue.withOpacity(0.6)
            : Colors.red.withOpacity(0.6),
      ),
    );
  }

  void initialize(Vector2 position, Vector2 direction, bool isPlayerBullet, String spritePath) {
    this.position.setFrom(position);
    this.direction.setFrom(direction);
    this.isPlayerBullet = isPlayerBullet;
    this.spritePath = spritePath;
    
    speed = isPlayerBullet ? 700 : 500;
    
    // Bullet boyutunu ayarla
    size = isPlayerBullet ? Vector2.all(20) : Vector2.all(18);
    
    // Bullet rotasyonu
    angle = direction.angleToSigned(Vector2(0, -1));
    
    // Renk ayarı
    add(ColorEffect(
      isPlayerBullet ? Colors.cyan : Colors.red,
      EffectController(duration: 0.1),
      opacityFrom: 0.8,
      opacityTo: 1.0,
    ));
  }

  void reset() {
    hitSomething = false;
    pierceCount = 0;
    hitTargets.clear();
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(direction * speed * dt);

    // Geniş alan için büyük sınırlar
    if (position.y < -500 ||
        position.y > gameRef.size.y + 500 ||
        position.x < -500 ||
        position.x > gameRef.size.x + 500) {
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    if ((hitSomething && !hasPiercing) ||
        (isPlayerBullet && other is Enemy && hitTargets.contains(other)) ||
        (!isPlayerBullet && other is Player && hitSomething)) {
      return;
    }

    if (isPlayerBullet && other is Enemy && !other.isDying) {
      handleHit(other);
    } else if (!isPlayerBullet && other is Player && !other.isDying) {
      hitSomething = true;
      other.takeDamage(15);
      showExplosion();
      removeFromParent();
    }
  }
  
  void handleHit(Enemy enemy) {
    if (hasPiercing) {
      hitTargets.add(enemy);
      pierceCount++;
      hitSomething = pierceCount >= maxPierceCount;
    } else {
      hitSomething = true;
    }

    enemy.takeDamage(damage);
    showExplosion();

    if (!hasPiercing || pierceCount >= maxPierceCount) {
      removeFromParent();
    }
  }

  void showExplosion() {
    try {
      gameRef.world.add(ExplosionEffect(position: position));
    } catch (e) {
      print('Explosion efekti oluşturma hatası: $e');
    }
  }
}

class TrailEffect extends Component {
  final Color color;
  final List<Vector2> trail = [];
  final int maxTrailPoints = 8;
  late Paint trailPaint;
  
  TrailEffect(this.color) {
    trailPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (parent == null) return;
    
    if (parent is PositionComponent) {
      trail.add((parent as PositionComponent).position.clone());
      
      if (trail.length > maxTrailPoints) {
        trail.removeAt(0);
      }
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    if (trail.length < 2) return;
    
    for (int i = 1; i < trail.length; i++) {
      final opacity = (i / trail.length) * 0.8;
      final strokeWidth = (i / trail.length) * 4;
      
      trailPaint
        ..color = color.withOpacity(opacity)
        ..strokeWidth = strokeWidth;
      
      canvas.drawLine(
        trail[i - 1].toOffset(),
        trail[i].toOffset(),
        trailPaint,
      );
    }
  }
} 