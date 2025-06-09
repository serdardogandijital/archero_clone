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
  hpRegen,
  tripleShot,
  explosiveShot,
  magneticField,
  shield,
  frostBullets,
  fireBullets,
  lightningStrike,
  rapidFire,
  ricochet,
  vampiric,
  berserker,
  timeWarp,
  multiTarget,
  bouncyBullets
}

class Upgrade {
  final UpgradeType type;
  final String name;
  final String description;
  final double value;
  final IconData icon;
  final Color color;
  final bool isRare;
  final bool isLegendary;

  const Upgrade({
    required this.type,
    required this.name,
    required this.description,
    required this.value,
    required this.icon,
    required this.color,
    this.isRare = false,
    this.isLegendary = false,
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
      // TEMEL YÜKSELTMELER
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
        type: UpgradeType.hpRegen,
        name: 'Can Yenileme',
        description: 'Her 3 saniyede 1 can yeniler',
        value: 1.0,
        icon: Icons.healing,
        color: Colors.teal,
      ),
      
      // NADİR YÜKSELTMELER
      const Upgrade(
        type: UpgradeType.doubleShot,
        name: 'Çift Atış',
        description: 'Her atışta 2 mermi fırlatır',
        value: 1.0,
        icon: Icons.filter_2,
        color: Colors.purple,
        isRare: true,
      ),
      const Upgrade(
        type: UpgradeType.piercing,
        name: 'Delici Atış',
        description: 'Mermiler 2 düşmanı delerek geçer',
        value: 2.0,
        icon: Icons.arrow_forward,
        color: Colors.amber,
        isRare: true,
      ),
      const Upgrade(
        type: UpgradeType.criticalHit,
        name: 'Kritik Vuruş',
        description: '%20 şansla %150 hasar verir',
        value: 20.0,
        icon: Icons.auto_awesome,
        color: Colors.orange,
        isRare: true,
      ),
      const Upgrade(
        type: UpgradeType.magneticField,
        name: 'Manyetik Alan',
        description: 'XP küreleri otomatik çekilir',
        value: 150.0, // Çekim mesafesi
        icon: Icons.grain,
        color: Colors.indigo,
        isRare: true,
      ),
      const Upgrade(
        type: UpgradeType.shield,
        name: 'Enerji Kalkanı',
        description: '5 hit\'e kadar koruma sağlar',
        value: 5.0,
        icon: Icons.shield,
        color: Colors.cyan,
        isRare: true,
      ),
      const Upgrade(
        type: UpgradeType.rapidFire,
        name: 'Hızlı Ateş',
        description: 'Ateş hızını %50 artırır',
        value: 50.0,
        icon: Icons.whatshot,
        color: Colors.deepOrange,
        isRare: true,
      ),
      const Upgrade(
        type: UpgradeType.vampiric,
        name: 'Vampirik Atış',
        description: 'Her öldürme 2 can yeniler',
        value: 2.0,
        icon: Icons.bloodtype,
        color: Colors.red,
        isRare: true,
      ),
      
      // EPİK YÜKSELTMELER
      const Upgrade(
        type: UpgradeType.tripleShot,
        name: 'Üçlü Atış',
        description: 'Her atışta 3 mermi fırlatır',
        value: 1.0,
        icon: Icons.filter_3,
        color: Colors.deepPurple,
        isLegendary: true,
      ),
      const Upgrade(
        type: UpgradeType.explosiveShot,
        name: 'Patlayıcı Mermi',
        description: 'Mermiler çevreye hasar verir',
        value: 60.0, // Patlama yarıçapı
        icon: Icons.burst_mode,
        color: Colors.red,
        isLegendary: true,
      ),
      const Upgrade(
        type: UpgradeType.frostBullets,
        name: 'Buzlu Mermiler',
        description: 'Düşmanları %30 yavaşlatır',
        value: 30.0,
        icon: Icons.ac_unit,
        color: Colors.lightBlue,
        isLegendary: true,
      ),
      const Upgrade(
        type: UpgradeType.fireBullets,
        name: 'Ateşli Mermiler',
        description: 'Sürekli hasar verir (3 sn)',
        value: 3.0,
        icon: Icons.local_fire_department,
        color: Colors.orange,
        isLegendary: true,
      ),
      const Upgrade(
        type: UpgradeType.lightningStrike,
        name: 'Şimşek Çarpması',
        description: 'Rastgele düşmanlara şimşek düşer',
        value: 80.0, // Şimşek hasarı
        icon: Icons.flash_on,
        color: Colors.yellow,
        isLegendary: true,
      ),
      const Upgrade(
        type: UpgradeType.ricochet,
        name: 'Sekme Atışı',
        description: 'Mermiler 3 kez sekmeler',
        value: 3.0,
        icon: Icons.compare_arrows,
        color: Colors.green,
        isLegendary: true,
      ),
      const Upgrade(
        type: UpgradeType.berserker,
        name: 'Berserker Modu',
        description: 'Düşük canda %100 hasar artışı',
        value: 100.0,
        icon: Icons.sports_mma,
        color: Colors.red,
        isLegendary: true,
      ),
      const Upgrade(
        type: UpgradeType.timeWarp,
        name: 'Zaman Büküm',
        description: 'Her 10 saniyede tüm düşmanlar durur',
        value: 10.0,
        icon: Icons.schedule,
        color: Colors.purple,
        isLegendary: true,
      ),
      const Upgrade(
        type: UpgradeType.multiTarget,
        name: 'Çoklu Hedef',
        description: 'En yakın 3 düşmana aynı anda ateş',
        value: 3.0,
        icon: Icons.my_location,
        color: Colors.pink,
        isLegendary: true,
      ),
      const Upgrade(
        type: UpgradeType.bouncyBullets,
        name: 'Zıplayan Mermiler',
        description: 'Mermiler duvarlarda sekmeler',
        value: 5.0, // Sekme sayısı
        icon: Icons.sports_baseball,
        color: Colors.brown,
        isLegendary: true,
      ),
    ]);
  }

  List<Upgrade> getRandomUpgrades(int count) {
    if (availableUpgrades.isEmpty) {
      return [];
    }

    final List<Upgrade> selectedUpgrades = [];
    final rng = math.Random();
    
    // Yükseltme havuzu oluştur - rariteye göre ağırlıklı
    final List<Upgrade> upgradePool = [];
    
    for (final upgrade in availableUpgrades) {
      // Zaten sahip olunan yükseltmeleri filtrele (bazıları hariç)
      if (_shouldSkipUpgrade(upgrade)) continue;
      
      // Nadir yükseltmeler - daha az şans
      if (upgrade.isLegendary) {
        // %10 şans
        if (rng.nextDouble() < 0.1) upgradePool.add(upgrade);
      } else if (upgrade.isRare) {
        // %25 şans
        if (rng.nextDouble() < 0.25) upgradePool.add(upgrade);
      } else {
        // %80 şans - temel yükseltmeler
        if (rng.nextDouble() < 0.8) upgradePool.add(upgrade);
      }
    }
    
    // En az 1 yükseltme garanti et
    if (upgradePool.isEmpty) {
      upgradePool.addAll(availableUpgrades.where((u) => !u.isLegendary && !u.isRare).take(3));
    }
    
    upgradePool.shuffle(rng);
    return upgradePool.take(count).toList();
  }

  bool _shouldSkipUpgrade(Upgrade upgrade) {
    // Bazı yükseltmeler sadece bir kez alınabilir
    final uniqueUpgrades = {
      UpgradeType.doubleShot,
      UpgradeType.tripleShot,
      UpgradeType.piercing,
      UpgradeType.magneticField,
      UpgradeType.shield,
      UpgradeType.explosiveShot,
      UpgradeType.vampiric,
      UpgradeType.berserker,
      UpgradeType.timeWarp,
      UpgradeType.multiTarget,
      UpgradeType.ricochet,
      UpgradeType.bouncyBullets,
    };
    
    if (uniqueUpgrades.contains(upgrade.type)) {
      return hasUpgrade(upgrade.type);
    }
    
    // Stackable yükseltmeler için limit
    final stackLimits = {
      UpgradeType.damage: 5,
      UpgradeType.attackSpeed: 4,
      UpgradeType.health: 3,
      UpgradeType.speed: 4,
      UpgradeType.criticalHit: 3,
      UpgradeType.hpRegen: 3,
      UpgradeType.rapidFire: 2,
      UpgradeType.frostBullets: 2,
      UpgradeType.fireBullets: 2,
      UpgradeType.lightningStrike: 3,
    };
    
    if (stackLimits.containsKey(upgrade.type)) {
      return getUpgradeLevel(upgrade.type) >= stackLimits[upgrade.type]!;
    }
    
    return false;
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
      case UpgradeType.tripleShot:
        player.enableTripleShot();
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
      case UpgradeType.explosiveShot:
        player.enableExplosiveShot(upgrade.value);
        break;
      case UpgradeType.magneticField:
        player.enableMagneticField(upgrade.value);
        break;
      case UpgradeType.shield:
        player.enableShield(upgrade.value.toInt());
        break;
      case UpgradeType.frostBullets:
        player.enableFrostBullets(upgrade.value / 100);
        break;
      case UpgradeType.fireBullets:
        player.enableFireBullets(upgrade.value);
        break;
      case UpgradeType.lightningStrike:
        player.enableLightningStrike(upgrade.value);
        break;
      case UpgradeType.rapidFire:
        player.increaseAttackSpeed(upgrade.value / 100);
        break;
      case UpgradeType.ricochet:
        player.enableRicochet(upgrade.value.toInt());
        break;
      case UpgradeType.vampiric:
        player.enableVampiric(upgrade.value);
        break;
      case UpgradeType.berserker:
        player.enableBerserker(upgrade.value / 100);
        break;
      case UpgradeType.timeWarp:
        player.enableTimeWarp(upgrade.value);
        break;
      case UpgradeType.multiTarget:
        player.enableMultiTarget(upgrade.value.toInt());
        break;
      case UpgradeType.bouncyBullets:
        player.enableBouncyBullets(upgrade.value.toInt());
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