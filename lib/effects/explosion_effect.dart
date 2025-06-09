import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../game/archero_game.dart';

class ExplosionEffect extends PositionComponent with HasGameRef<ArcheroGame> {
  final double duration;
  final int particleCount;
  final double spreadRadius;
  final Color baseColor;

  ExplosionEffect({
    required Vector2 position,
    this.duration = 0.8,
    this.particleCount = 15,
    this.spreadRadius = 40.0,
    this.baseColor = Colors.orange,
  }) : super(position: position, anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Ana patlama çemberi
    final explosionRing = CircleComponent(
      radius: 5,
      paint: Paint()..color = Colors.yellow.withOpacity(0.9),
      anchor: Anchor.center,
    );
    
    explosionRing.add(
      SequenceEffect([
        ScaleEffect.by(
          Vector2.all(6), 
          EffectController(duration: 0.2, curve: Curves.easeOut),
        ),
        OpacityEffect.fadeOut(EffectController(duration: 0.3)),
        RemoveEffect(),
      ]),
    );
    add(explosionRing);
    
    // İç parlak çember
    final innerFlash = CircleComponent(
      radius: 8,
      paint: Paint()..color = Colors.white.withOpacity(0.8),
      anchor: Anchor.center,
    );
    
    innerFlash.add(
      SequenceEffect([
        ScaleEffect.by(
          Vector2.all(3), 
          EffectController(duration: 0.15, curve: Curves.easeOut),
        ),
        OpacityEffect.fadeOut(EffectController(duration: 0.2)),
        RemoveEffect(),
      ]),
    );
    add(innerFlash);
    
    // Parçacık sistemi - ateş efekti
    add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: particleCount,
          lifespan: duration,
          generator: (i) {
            final angle = math.Random().nextDouble() * 2 * math.pi;
            final speed = math.Random().nextDouble() * spreadRadius + 20;
            final velocity = Vector2(
              math.cos(angle) * speed,
              math.sin(angle) * speed,
            );
            
            // Ateş renkleri: sarı, turuncu, kırmızı
            final colors = [
              Colors.yellow,
              Colors.orange,
              Colors.red,
              Colors.deepOrange,
            ];
            final color = colors[math.Random().nextInt(colors.length)];
            
            return AcceleratedParticle(
              acceleration: Vector2(0, 25), // Yerçekimi
              position: Vector2.zero(),
              speed: velocity,
              child: CircleParticle(
                radius: math.Random().nextDouble() * 4 + 2,
                paint: Paint()..color = color.withOpacity(
                  math.Random().nextDouble() * 0.6 + 0.4
                ),
              ),
            );
          },
        ),
      ),
    );
    
    // Kıvılcım efekti - CircleParticle ile değiştirdim
    add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 8,
          lifespan: duration * 0.6,
          generator: (i) {
            final angle = math.Random().nextDouble() * 2 * math.pi;
            final speed = math.Random().nextDouble() * 80 + 40;
            final velocity = Vector2(
              math.cos(angle) * speed,
              math.sin(angle) * speed,
            );
            
            return AcceleratedParticle(
              acceleration: Vector2(0, 20),
              position: Vector2.zero(),
              speed: velocity,
              child: CircleParticle(
                radius: 1.5,
                paint: Paint()..color = Colors.white.withOpacity(0.9),
              ),
            );
          },
        ),
      ),
    );
    
    // Otomatik temizlik
    add(
      TimerComponent(
        period: duration + 0.5,
        onTick: () => removeFromParent(),
        removeOnFinish: true,
      ),
    );
  }
} 