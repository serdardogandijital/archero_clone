import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import '../game/archero_game.dart';
import 'player.dart';

class ExperienceOrb extends SpriteComponent with HasGameRef<ArcheroGame>, CollisionCallbacks {
  final double experienceValue;
  final double attractionSpeed;
  bool isAttracted = false;
  Player? targetPlayer;
  double lifeTime = 0.0;

  ExperienceOrb({
    required Vector2 position,
    this.experienceValue = 10.0,
    this.attractionSpeed = 200.0,
  }) : super(
    position: position,
    size: Vector2.all(24),
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    try {
      // XP orb sprite'ı düzgün yükle
      sprite = await gameRef.loadSprite('xp_orb.png');
    } catch (e) {
      print('XP orb sprite yükleme hatası: $e');
      // Fallback: Altın rengi circle
      sprite = null;
      add(CircleComponent(
        radius: 12,
        paint: Paint()..color = const Color(0xFFFFD700), // Altın rengi
      ));
    }
    
    // Sadece hafif parıldama efekti - beyaz renk yerine opaklık
    add(
      OpacityEffect.to(
        0.7,
        EffectController(
          duration: 0.8,
          reverseDuration: 0.8,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
    
    // Yumuşak yüzen hareket
    add(
      MoveEffect.by(
        Vector2(0, -6),
        EffectController(
          duration: 1.5,
          reverseDuration: 1.5,
          infinite: true,
          curve: Curves.easeInOut,
        ),
      ),
    );
    
    // Çarpışma hitbox'ı
    add(CircleHitbox()..collisionType = CollisionType.passive);
    
    // Oyuncu komponentini bul
    final players = gameRef.world.children.whereType<Player>();
    if (players.isNotEmpty) {
      targetPlayer = players.first;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    lifeTime += dt;
    
    if (targetPlayer == null || targetPlayer!.isRemoved) {
      return;
    }
    
    // Oyuncuya olan mesafeyi hesapla
    final distance = position.distanceTo(targetPlayer!.position);
    
    // Eğer oyuncu yeterince yakınsa XP'yi çekmeye başla
    if (distance < 150 || isAttracted) {
      isAttracted = true;
      final direction = (targetPlayer!.position - position).normalized();
      final moveSpeed = isAttracted ? attractionSpeed : attractionSpeed * 0.5;
      position += direction * moveSpeed * dt;
      
      // Oyuncuya yeterince yakınsa ve oyuncu yaşıyorsa deneyim ekle
      if (distance < 20 && !targetPlayer!.isDying) {
        targetPlayer!.gainExperience(experienceValue);
        gameRef.addScore(experienceValue.toInt());
        removeFromParent();
      }
    }
    
    // 10 saniye sonra otomatik çekilmeye başla
    if (lifeTime > 10 && !isAttracted && targetPlayer != null && !targetPlayer!.isDying) {
      isAttracted = true;
    }
  }
  
  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);
    
    if (other is Player && !other.isDying) {
      other.gainExperience(experienceValue);
      gameRef.addScore(experienceValue.toInt());
      removeFromParent();
    }
  }
} 