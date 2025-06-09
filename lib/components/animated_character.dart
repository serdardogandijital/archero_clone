import 'package:flame/components.dart';
import '../game/archero_game.dart';

enum PlayerState { idle, walking, shooting }

class AnimatedPlayer extends SpriteAnimationGroupComponent<PlayerState>
    with HasGameRef<ArcheroGame> {
  
  @override
  Future<void> onLoad() async {
    animations = {
      PlayerState.idle: await _loadAnimation('player_idle.png', 4),
      PlayerState.walking: await _loadAnimation('player_walk.png', 6),
      PlayerState.shooting: await _loadAnimation('player_shoot.png', 3),
    };
    
    current = PlayerState.idle;
    size = Vector2(64, 64);
    anchor = Anchor.center;
  }
  
  Future<SpriteAnimation> _loadAnimation(String imagePath, int frameCount) async {
    return await gameRef.loadSpriteAnimation(
      imagePath,
      SpriteAnimationData.sequenced(
        amount: frameCount,
        stepTime: 0.1,
        textureSize: Vector2(32, 48),
        loop: true,
      ),
    );
  }
  
  void updateAnimation(PlayerState newState) {
    if (current != newState) {
      current = newState;
    }
  }
} 