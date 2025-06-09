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
import 'dart:math' as math;

class Bullet extends SpriteComponent with HasGameRef<ArcheroGame>, CollisionCallbacks {
  late Vector2 direction;
  double speed = 400.0;
  double damage = 25.0;
  bool isPlayerBullet = true;
  bool hasPiercing = false;
  final Set<Component> hitTargets = <Component>{};
  int maxPiercing = 2;
  int currentPierces = 0;
  
  // Trail efekti için
  final List<Vector2> _trailPositions = [];
  final int _maxTrailLength = 8;
  late final Timer _trailTimer;

  Bullet() : super(anchor: Anchor.center);

  void initialize(Vector2 pos, Vector2 dir, bool playerBullet, String spritePath) {
    position = pos;
    direction = dir.normalized();
    isPlayerBullet = playerBullet;
    
    // Bullet'ları daha büyük yap
    size = isPlayerBullet ? Vector2.all(24) : Vector2.all(20); // Büyütüldü
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    try {
      // Sprite yükle
      final spritePath = isPlayerBullet ? 'bullet.png' : 'enemy_bullet.png';
      sprite = await gameRef.loadSprite(spritePath);
    } catch (e) {
      print('Bullet sprite yükleme hatası: $e');
      // Fallback görsel - daha büyük ve etkileyici
      final paint = Paint()..color = isPlayerBullet ? 
          const Color(0xFF00FFFF) : // Cyan for player
          const Color(0xFFFF4444);  // Red for enemy
      
      add(CircleComponent(
        radius: isPlayerBullet ? 12 : 10,
        paint: paint,
        anchor: Anchor.center,
      ));
      
      // Parlama efekti ekle
      add(CircleComponent(
        radius: isPlayerBullet ? 8 : 6,
        paint: Paint()..color = Colors.white.withOpacity(0.7),
        anchor: Anchor.center,
      ));
    }
    
    // Collision hitbox - daha büyük
    add(CircleHitbox(radius: isPlayerBullet ? 10 : 8));
    
    // Trail timer
    _trailTimer = Timer(0.02, onTick: _addTrailPosition, repeat: true);
    _trailTimer.start();
    
    // Bullet rotation
    angle = math.atan2(direction.y, direction.x);
    
    // Bullet glow efekti
    if (isPlayerBullet) {
      add(
        ScaleEffect.by(
          Vector2.all(1.2),
          EffectController(
            duration: 0.3,
            reverseDuration: 0.3,
            infinite: true,
            curve: Curves.easeInOut,
          ),
        ),
      );
    }
    
    // Auto-remove timer
    add(TimerComponent(
      period: 3.0,
      removeOnFinish: true,
      onTick: () => removeFromParent(),
    ));
  }

  void _addTrailPosition() {
    _trailPositions.add(position.clone());
    if (_trailPositions.length > _maxTrailLength) {
      _trailPositions.removeAt(0);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.add(direction * speed * dt);
    
    // Ekran dışına çıktıysa kaldır
    if (position.x < -100 || position.x > gameRef.size.x + 100 ||
        position.y < -100 || position.y > gameRef.size.y + 100) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Trail efekti çiz
    if (_trailPositions.length > 1) {
      final paint = Paint()
        ..color = (isPlayerBullet ? Colors.cyan : Colors.red).withOpacity(0.3)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      
      final path = Path();
      for (int i = 0; i < _trailPositions.length; i++) {
        final trailPos = _trailPositions[i] - position; // Relative to bullet
        if (i == 0) {
          path.moveTo(trailPos.x, trailPos.y);
        } else {
          path.lineTo(trailPos.x, trailPos.y);
        }
      }
      
      canvas.drawPath(path, paint);
    }
  }

  void handleHit(Component target) {
    hitTargets.add(target);
    
    if (hasPiercing && currentPierces < maxPiercing) {
      currentPierces++;
      // Piercing efekti - bullet biraz yavaşlar
      speed *= 0.8;
      
      // Küçük hit efekti
      gameRef.world.add(
        CircleComponent(
          radius: 8,
          paint: Paint()..color = Colors.yellow.withOpacity(0.8),
          position: position.clone(),
          anchor: Anchor.center,
        )..add(
          SequenceEffect([
            ScaleEffect.by(Vector2.all(2), EffectController(duration: 0.2)),
            OpacityEffect.fadeOut(EffectController(duration: 0.3)),
            RemoveEffect(),
          ]),
        ),
      );
    } else {
      // Hit efekti ve bullet yok et
      _createHitEffect();
      removeFromParent();
    }
  }

  void _createHitEffect() {
    // Hit patlaması efekti
    final hitEffect = CircleComponent(
      radius: 6,
      paint: Paint()..color = (isPlayerBullet ? Colors.cyan : Colors.red).withOpacity(0.9),
      position: position.clone(),
      anchor: Anchor.center,
    );
    
    hitEffect.add(
      SequenceEffect([
        ScaleEffect.by(Vector2.all(3), EffectController(duration: 0.15, curve: Curves.easeOut)),
        OpacityEffect.fadeOut(EffectController(duration: 0.2)),
        RemoveEffect(),
      ]),
    );
    
    gameRef.world.add(hitEffect);
    
    // Parçacık efekti
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi * 2) / 6;
      final particle = CircleComponent(
        radius: 2,
        paint: Paint()..color = Colors.white.withOpacity(0.8),
        position: position.clone(),
        anchor: Anchor.center,
      );
      
      final direction = Vector2(math.cos(angle), math.sin(angle));
      particle.add(
        SequenceEffect([
          MoveEffect.by(direction * 30, EffectController(duration: 0.3)),
          OpacityEffect.fadeOut(EffectController(duration: 0.2)),
          RemoveEffect(),
        ]),
      );
      
      gameRef.world.add(particle);
    }
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (hitTargets.contains(other)) return;
    
    if (isPlayerBullet && other is Enemy && !other.isDying) {
      other.takeDamage(damage);
      handleHit(other);
    } else if (!isPlayerBullet && other is Player && !other.isDying) {
      other.takeDamage(damage);
      handleHit(other);
    }
  }

  @override
  void onRemove() {
    _trailTimer.stop();
    super.onRemove();
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