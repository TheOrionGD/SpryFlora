import 'package:flutter/material.dart';

/// Data model representing a milestone stage in the SpryFlora Mascot Journey.
class MilestoneStage {
  final int id;
  final int stageNumber;
  final String title;
  final String description;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrent;
  final String assetPath;
  final IconData fallbackIcon;
  final int xpReward;
  final String topic;

  const MilestoneStage({
    required this.id,
    required this.stageNumber,
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.isCompleted,
    required this.isCurrent,
    required this.assetPath,
    required this.fallbackIcon,
    required this.xpReward,
    required this.topic,
  });

  MilestoneStage copyWith({
    int? id,
    int? stageNumber,
    String? title,
    String? description,
    bool? isUnlocked,
    bool? isCompleted,
    bool? isCurrent,
    String? assetPath,
    IconData? fallbackIcon,
    int? xpReward,
    String? topic,
  }) {
    return MilestoneStage(
      id: id ?? this.id,
      stageNumber: stageNumber ?? this.stageNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
      isCurrent: isCurrent ?? this.isCurrent,
      assetPath: assetPath ?? this.assetPath,
      fallbackIcon: fallbackIcon ?? this.fallbackIcon,
      xpReward: xpReward ?? this.xpReward,
      topic: topic ?? this.topic,
    );
  }

  /// Generates a default list of 16 sequential botanical growth journey milestones.
  /// Sets stages 1 to 4 as completed, stage 5 as current/active, and remaining as locked.
  static List<MilestoneStage> getDummyStages({int activeIndex = 4}) {
    final rawData = [
      {
        'id': 1,
        'title': 'Seed Awakening',
        'description': 'Plant your first sprout seed in nutrient-rich soil.',
        'assetPath': 'assets/sprites/boy_planting.png',
        'fallbackIcon': Icons.grass,
        'xp': 50,
        'topic': 'Soil & Seeds',
      },
      {
        'id': 2,
        'title': 'First Sprout',
        'description': 'Witness the tiny green shoot break through the earth.',
        'assetPath': 'assets/sprites/mascot_pot_happy.png',
        'fallbackIcon': Icons.eco,
        'xp': 75,
        'topic': 'Germination',
      },
      {
        'id': 3,
        'title': 'Sunlight Booster',
        'description': 'Give your baby plant optimal indirect sunlight hours.',
        'assetPath': 'assets/sprites/boy_phone_scanning.png',
        'fallbackIcon': Icons.wb_sunny,
        'xp': 100,
        'topic': 'Photosynthesis',
      },
      {
        'id': 4,
        'title': 'Hydration Haven',
        'description': 'Master moisture balance and root hydration routine.',
        'assetPath': 'assets/sprites/mascot_pot_winking.png',
        'fallbackIcon': Icons.water_drop,
        'xp': 125,
        'topic': 'Watering Basics',
      },
      {
        'id': 5,
        'title': 'Potted Potency',
        'description': 'Repot your thriving plant into a spacious ceramic home.',
        'assetPath': 'assets/sprites/plant_potted.png',
        'fallbackIcon': Icons.local_florist,
        'xp': 150,
        'topic': 'Repotting',
      },
      {
        'id': 6,
        'title': 'Nutrient Shield',
        'description': 'Feed natural bio-organic fertilizer for steady stem growth.',
        'assetPath': 'assets/sprites/mascot_pot_happy.png',
        'fallbackIcon': Icons.science,
        'xp': 175,
        'topic': 'Fertilization',
      },
      {
        'id': 7,
        'title': 'Leaf Pruning',
        'description': 'Trim yellowing fronds to redirect energy into fresh foliage.',
        'assetPath': 'assets/sprites/boy_planting.png',
        'fallbackIcon': Icons.content_cut,
        'xp': 200,
        'topic': 'Pruning Art',
      },
      {
        'id': 8,
        'title': 'Root Explorer',
        'description': 'Check root health and avoid root-bound stagnation.',
        'assetPath': 'assets/sprites/certificate_spryflora_icon.png',
        'fallbackIcon': Icons.nature_people,
        'xp': 225,
        'topic': 'Root Health',
      },
      {
        'id': 9,
        'title': 'Humidity Oasis',
        'description': 'Create a tropical misting microclimate for lush leaves.',
        'assetPath': 'assets/sprites/mascot_pot_winking.png',
        'fallbackIcon': Icons.opacity,
        'xp': 250,
        'topic': 'Humidity',
      },
      {
        'id': 10,
        'title': 'Floral Buds',
        'description': 'Nurture delicate flower buds as they prepare to open.',
        'assetPath': 'assets/sprites/plant_potted.png',
        'fallbackIcon': Icons.filter_vintage,
        'xp': 275,
        'topic': 'Budding Phase',
      },
      {
        'id': 11,
        'title': 'Sweet Bloom',
        'description': 'Celebrate your first full vibrant blossom opening.',
        'assetPath': 'assets/sprites/mascot_celebrating_confetti.png',
        'fallbackIcon': Icons.nature,
        'xp': 300,
        'topic': 'Blooming',
      },
      {
        'id': 12,
        'title': 'Pollinator Haven',
        'description': 'Attract friendly bees and butterflies to garden haven.',
        'assetPath': 'assets/sprites/avatar_boy_hero.png',
        'fallbackIcon': Icons.emoji_nature,
        'xp': 350,
        'topic': 'Ecology',
      },
      {
        'id': 13,
        'title': 'Fruit Seedling',
        'description': 'Observe successful pollination forming small fruits.',
        'assetPath': 'assets/sprites/scroll_diploma.png',
        'fallbackIcon': Icons.yard,
        'xp': 400,
        'topic': 'Harvesting',
      },
      {
        'id': 14,
        'title': 'Canopy Growth',
        'description': 'Develop a thick lush canopy protecting small flora.',
        'assetPath': 'assets/sprites/mascot_graduate_logo.png',
        'fallbackIcon': Icons.park,
        'xp': 450,
        'topic': 'Canopy Management',
      },
      {
        'id': 15,
        'title': 'Guardian Tree',
        'description': 'Become a sanctuary tree providing shade and clean air.',
        'assetPath': 'assets/sprites/certificate_approved_stamp.png',
        'fallbackIcon': Icons.forest,
        'xp': 500,
        'topic': 'Spry Conservation',
      },
      {
        'id': 16,
        'title': 'Spry Master Blossom',
        'description': 'Achieve ultimate master botanical status in SpryFlora!',
        'assetPath': 'assets/sprites/trophy_champion.png',
        'fallbackIcon': Icons.emoji_events,
        'xp': 1000,
        'topic': 'Grand Mastery',
      },
    ];

    return List.generate(rawData.length, (index) {
      final item = rawData[index];
      final isCompleted = index < activeIndex;
      final isCurrent = index == activeIndex;
      final isUnlocked = index <= activeIndex;

      return MilestoneStage(
        id: item['id'] as int,
        stageNumber: index + 1,
        title: item['title'] as String,
        description: item['description'] as String,
        isUnlocked: isUnlocked,
        isCompleted: isCompleted,
        isCurrent: isCurrent,
        assetPath: item['assetPath'] as String,
        fallbackIcon: item['fallbackIcon'] as IconData,
        xpReward: item['xp'] as int,
        topic: item['topic'] as String,
      );
    });
  }
}
