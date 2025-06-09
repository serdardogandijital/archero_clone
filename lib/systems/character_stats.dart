class CharacterStats {
  int level = 1;
  int experience = 0;
  int health = 100;
  int maxHealth = 100;
  int attack = 10;
  int defense = 5;
  double speed = 200.0;
  double fireRate = 0.3;
  
  int get experienceToNextLevel => level * 100;
  
  bool addExperience(int xp) {
    experience += xp;
    if (experience >= experienceToNextLevel) {
      levelUp();
      return true;
    }
    return false;
  }
  
  void levelUp() {
    level++;
    experience = 0;
    maxHealth += 20;
    health = maxHealth;
    attack += 5;
    defense += 3;
    speed += 10;
  }
  
  Map<String, dynamic> toJson() => {
    'level': level,
    'experience': experience,
    'health': health,
    'maxHealth': maxHealth,
    'attack': attack,
    'defense': defense,
    'speed': speed,
    'fireRate': fireRate,
  };
  
  CharacterStats.fromJson(Map<String, dynamic> json)
      : level = json['level'] ?? 1,
        experience = json['experience'] ?? 0,
        health = json['health'] ?? 100,
        maxHealth = json['maxHealth'] ?? 100,
        attack = json['attack'] ?? 10,
        defense = json['defense'] ?? 5,
        speed = json['speed']?.toDouble() ?? 200.0,
        fireRate = json['fireRate']?.toDouble() ?? 0.3;
} 