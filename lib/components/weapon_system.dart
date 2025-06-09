import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import '../game/archero_game.dart';
import 'player.dart';
import 'enemy.dart';
import 'bullet.dart';

class WeaponSystem extends Component with HasGameRef<ArcheroGame> {
  final Player player;
  late Timer _shootTimer;
  bool _isShooting = false;
  double _shootInterval = 0.5;

  WeaponSystem(this.player) {
    _shootTimer = Timer(
      _shootInterval,
      onTick: _shoot,
      repeat: true,
    );
  }

  void startShooting() {
    _isShooting = true;
    _shootTimer.start();
  }

  void stopShooting() {
    _isShooting = false;
    _shootTimer.stop();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isShooting) {
      _shootTimer.update(dt);
    }
  }

  void _shoot() {
    if (!player.isMounted) return;

    // En yakın düşmanı bul
    Enemy? nearestEnemy;
    double nearestDistance = double.infinity;

    for (final component in gameRef.world.children) {
      if (component is Enemy) {
        final distance = player.position.distanceTo(component.position);
        if (distance < nearestDistance) {
          nearestDistance = distance;
          nearestEnemy = component;
        }
      }
    }

    if (nearestEnemy != null) {
      final direction = (nearestEnemy.position - player.position).normalized();
      
      final bullet = Bullet();
      bullet.initialize(
        player.position.clone(),
        direction,
        true,
        'bullet.png',
      );
      
      gameRef.world.add(bullet);
    }
  }

  void upgradeFireRate() {
    _shootInterval *= 0.9; // 10% daha hızlı ateş
    _shootTimer = Timer(
      _shootInterval,
      onTick: _shoot,
      repeat: true,
    );
    if (_isShooting) {
      _shootTimer.start();
    }
  }
} 