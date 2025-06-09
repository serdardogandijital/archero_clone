import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../game/archero_game.dart';
import 'player.dart';

enum UpgradeType {
  damage,
  attackSpeed,
  health,
  speed,
  doubleShot,
  piercing,
  criticalHit,
  hpRegen
}

class Upgrade {
  final UpgradeType type;
  final String name;
  final String description;
  final double value;
  final IconData icon;
  final Color color;

  const Upgrade({
    required this.type,
    required this.name,
    required this.description,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class UpgradeSystem extends Component with HasGameRef<ArcheroGame> {
  final Player player;
  final List<Upgrade> availableUpgrades = [];
  final List<Upgrade> activeUpgrades = [];
  final math.Random random = math.Random();

  UpgradeSystem({required this.player});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _initializeUpgrades();
  }

  void _initializeUpgrades() {
    availableUpgrades.addAll([
      const Upgrade(
        type: UpgradeType.damage,
        name: 'Hasar Artışı',
        description: 'Mermi hasarını %20 artırır',
        value: 20.0,
        icon: Icons.flash_on,
        color: Colors.red,
      ),
      const Upgrade(
        type: UpgradeType.attackSpeed,
        name: 'Ateş Hızı',
        description: 'Ateş hızını %15 artırır',
        value: 15.0,
        icon: Icons.speed,
        color: Colors.blue,
      ),
      const Upgrade(
        type: UpgradeType.health,
        name: 'Can Artışı',
        description: 'Maksimum canı %25 artırır',
        value: 25.0,
        icon: Icons.favorite,
        color: Colors.pink,
      ),
      const Upgrade(
        type: UpgradeType.speed,
        name: 'Hareket Hızı',
        description: 'Hareket hızını %15 artırır',
        value: 15.0,
        icon: Icons.directions_run,
        color: Colors.green,
      ),
      const Upgrade(
        type: UpgradeType.doubleShot,
        name: 'Çift Atış',
        description: 'Her atışta 2 mermi fırlatır',
        value: 1.0,
        icon: Icons.filter_2,
        color: Colors.purple,
      ),
      const Upgrade(
        type: UpgradeType.piercing,
        name: 'Delici Atış',
        description: 'Mermiler düşmanları delerek geçer',
        value: 1.0,
        icon: Icons.arrow_forward,
        color: Colors.amber,
      ),
      const Upgrade(
        type: UpgradeType.criticalHit,
        name: 'Kritik Vuruş',
        description: '%15 şansla çift hasar verir',
        value: 15.0,
        icon: Icons.auto_awesome,
        color: Colors.orange,
      ),
      const Upgrade(
        type: UpgradeType.hpRegen,
        name: 'Can Yenileme',
        description: 'Her 5 saniyede 1 can yeniler',
        value: 1.0,
        icon: Icons.healing,
        color: Colors.teal,
      ),
    ]);
  }

  List<Upgrade> getRandomUpgrades(int count) {
    if (availableUpgrades.isEmpty) {
      return [];
    }

    // Mevcut yükseltmeleri listeden kopyala ve karıştır
    final upgrades = List<Upgrade>.from(availableUpgrades)..shuffle(random);
    
    // Maksimum kaç tane yükseltme verebileceğimizi hesapla
    final actualCount = math.min(count, upgrades.length);
    
    // Rastgele yükseltmeleri seç
    return upgrades.take(actualCount).toList();
  }

  void applyUpgrade(Upgrade upgrade) {
    // Yükseltmeyi aktif yükseltmelere ekle
    activeUpgrades.add(upgrade);
    
    // Yükseltme tipine göre oyuncuya uygula
    switch (upgrade.type) {
      case UpgradeType.damage:
        player.increaseDamage(upgrade.value / 100);
        break;
      case UpgradeType.attackSpeed:
        player.increaseAttackSpeed(upgrade.value / 100);
        break;
      case UpgradeType.health:
        player.increaseMaxHealth(upgrade.value / 100);
        break;
      case UpgradeType.speed:
        player.increaseSpeed(upgrade.value / 100);
        break;
      case UpgradeType.doubleShot:
        player.enableDoubleShot();
        break;
      case UpgradeType.piercing:
        player.enablePiercing();
        break;
      case UpgradeType.criticalHit:
        player.enableCriticalHit(upgrade.value / 100);
        break;
      case UpgradeType.hpRegen:
        player.enableHpRegen(upgrade.value);
        break;
    }

    // Yükseltme uygulandıktan sonra oyuncuya bildir
    gameRef.showMessage(upgrade.name);
  }

  bool hasUpgrade(UpgradeType type) {
    return activeUpgrades.any((upgrade) => upgrade.type == type);
  }

  int getUpgradeLevel(UpgradeType type) {
    return activeUpgrades.where((upgrade) => upgrade.type == type).length;
  }
} 