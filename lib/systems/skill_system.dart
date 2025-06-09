import 'package:flutter/material.dart';
import '../components/player.dart';

abstract class Skill {
  String get name;
  String get description;
  IconData get icon;
  
  void apply(Player player);
}

class MultiShotSkill extends Skill {
  @override
  String get name => 'Multi Shot';
  @override
  String get description => '+1 mermi ateşle';
  @override
  IconData get icon => Icons.scatter_plot;
  
  @override
  void apply(Player player) {
    player.weaponSystem.bulletCount++;
  }
}

class FireRateSkill extends Skill {
  @override
  String get name => 'Fire Rate';
  @override
  String get description => 'Ateş hızı %20 artar';
  @override
  IconData get icon => Icons.speed;
  
  @override
  void apply(Player player) {
    player.weaponSystem.updateFireRate(player.weaponSystem.fireRate * 0.8);
  }
}

class DamageBoostSkill extends Skill {
  @override
  String get name => 'Damage Boost';
  @override
  String get description => 'Placeholder';
  @override
  IconData get icon => Icons.add;
  
  @override
  void apply(Player player) {
    // Placeholder
  }
}

class HealthBoostSkill extends Skill {
  @override
  String get name => 'Health Boost';
  @override
  String get description => 'Placeholder';
  @override
  IconData get icon => Icons.add;
  
  @override
  void apply(Player player) {
    // Placeholder
  }
}

class SpeedBoostSkill extends Skill {
  @override
  String get name => 'Speed Boost';
  @override
  String get description => 'Placeholder';
  @override
  IconData get icon => Icons.add;
  
  @override
  void apply(Player player) {
    // Placeholder
  }
}

class SkillManager {
  final List<Skill> availableSkills = [
    MultiShotSkill(),
    FireRateSkill(),
    DamageBoostSkill(),
    HealthBoostSkill(),
    SpeedBoostSkill(),
  ];
  
  List<Skill> getRandomSkills({int count = 3}) {
    final shuffled = List<Skill>.from(availableSkills)..shuffle();
    return shuffled.take(count).toList();
  }
} 