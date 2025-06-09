import 'package:flutter/material.dart';
import '../components/upgrade_system.dart';
import '../game/archero_game.dart';

class LevelUpOverlay extends StatelessWidget {
  final ArcheroGame game;

  const LevelUpOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final upgrades = game.upgradeSystem.getRandomUpgrades(3);

    return Material(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SEVİYE ATLADIN!',
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bir yetenek seç:',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
            const SizedBox(height: 30),
            ...upgrades.map((upgrade) => UpgradeCard(
              upgrade: upgrade,
              onTap: () {
                game.applyUpgrade(upgrade);
                game.overlays.remove('LevelUp');
                game.resumeGame();
              },
            )),
          ],
        ),
      ),
    );
  }
}

class UpgradeCard extends StatelessWidget {
  final Upgrade upgrade;
  final VoidCallback onTap;

  const UpgradeCard({
    super.key,
    required this.upgrade,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
      child: ListTile(
        leading: Icon(upgrade.icon, color: upgrade.color, size: 40),
        title: Text(upgrade.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(upgrade.description),
        onTap: onTap,
      ),
    );
  }
} 