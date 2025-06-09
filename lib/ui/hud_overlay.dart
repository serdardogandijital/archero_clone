import 'package:flutter/material.dart';
import '../game/archero_game.dart';

class HudOverlay extends StatelessWidget {
  final ArcheroGame game;

  const HudOverlay({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<int>(
        valueListenable: game.scoreNotifier,
        builder: (context, score, child) {
          return ValueListenableBuilder<int>(
            valueListenable: game.waveNotifier,
            builder: (context, wave, child) {
              return ValueListenableBuilder<double>(
                valueListenable: game.player.healthNotifier,
                builder: (context, health, child) {
                  return Material(
                    color: Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Skor: $score', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('Dalga: $wave', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Spacer(),
                          if (game.player.isMounted)
                            Row(
                              children: [
                                const Icon(Icons.favorite, color: Colors.red, size: 30),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: health / game.player.maxHealth,
                                    backgroundColor: Colors.grey[800],
                                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                                    minHeight: 15,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text('${health.toInt()} / ${game.player.maxHealth.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
} 