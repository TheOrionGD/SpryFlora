import 'package:flutter/material.dart';

/// Data model representing a single stage in the 16-stage SpryFlora Mascot Journey.
class MilestoneStage {
  final int id;
  final int stageNumber;
  final String title;
  final String description;
  final bool isUnlocked;
  final bool isCompleted;
  final bool isCurrent;
  final String badgeSymbol;
  final String landName;
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
    required this.badgeSymbol,
    required this.landName,
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
    String? badgeSymbol,
    String? landName,
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
      badgeSymbol: badgeSymbol ?? this.badgeSymbol,
      landName: landName ?? this.landName,
      assetPath: assetPath ?? this.assetPath,
      fallbackIcon: fallbackIcon ?? this.fallbackIcon,
      xpReward: xpReward ?? this.xpReward,
      topic: topic ?? this.topic,
    );
  }

  /// Generates the list of 16 predefined botanical growth journey milestones.
  static List<MilestoneStage> getDummyStages({int activeIndex = 0}) {
    final rawData = [
      {
        'id': 1,
        'title': 'Seed Awakening',
        'badgeSymbol': 'SEED',
        'landName': 'Sprout Hollow',
        'description': 'Plant your first seed in nutrient-rich soil and begin your SpryFlora journey.',
        'assetPath': 'assets/sprites/boy_planting.png',
        'fallbackIcon': Icons.grass,
        'xp': 50,
        'topic': 'Soil & Seeds',
      },
      {
        'id': 2,
        'title': 'First Sprout',
        'badgeSymbol': 'SPROUT',
        'landName': 'Sprout Hollow',
        'description': 'Witness the tiny green shoot break through the earth with joy.',
        'assetPath': 'assets/sprites/mascot_pot_happy.png',
        'fallbackIcon': Icons.eco,
        'xp': 75,
        'topic': 'Germination',
      },
      {
        'id': 3,
        'title': 'Sunlight',
        'badgeSymbol': 'SUNLIGHT',
        'landName': 'Sunlit Meadow',
        'description': 'Provide optimal indirect sunlight hours for natural leaf development.',
        'assetPath': 'assets/sprites/boy_phone_scanning.png',
        'fallbackIcon': Icons.wb_sunny,
        'xp': 100,
        'topic': 'Photosynthesis',
      },
      {
        'id': 4,
        'title': 'Oasis',
        'badgeSymbol': 'OASIS',
        'landName': 'Dewdrop Springs',
        'description': 'Master moisture balance and root hydration routine for steady growth.',
        'assetPath': 'assets/sprites/mascot_pot_winking.png',
        'fallbackIcon': Icons.water_drop,
        'xp': 125,
        'topic': 'Watering Basics',
      },
      {
        'id': 5,
        'title': 'Potted Potency',
        'badgeSymbol': 'CURRENT',
        'landName': 'Dewdrop Springs',
        'description': 'Explore your sprout as it matures in a spacious ceramic pot.',
        'assetPath': 'assets/sprites/plant_potted.png',
        'fallbackIcon': Icons.local_florist,
        'xp': 150,
        'topic': 'Repotting',
      },
      {
        'id': 6,
        'title': 'Nutrient Shield',
        'badgeSymbol': 'CANOPY',
        'landName': 'Terra Haven',
        'description': 'Feed bio-organic fertilizer for strong stems and vibrant green leaves.',
        'assetPath': 'assets/sprites/mascot_pot_happy.png',
        'fallbackIcon': Icons.science,
        'xp': 175,
        'topic': 'Fertilization',
      },
      {
        'id': 7,
        'title': 'Leaf Pruning',
        'badgeSymbol': 'CANOPY',
        'landName': 'Verdant Vale',
        'description': 'Trim aging fronds to redirect nutrients into fresh young foliage.',
        'assetPath': 'assets/sprites/boy_planting.png',
        'fallbackIcon': Icons.content_cut,
        'xp': 200,
        'topic': 'Pruning Art',
      },
      {
        'id': 8,
        'title': 'Root Explorer',
        'badgeSymbol': 'CANOPY',
        'landName': 'Whisper Grove',
        'description': 'Inspect root health and prevent root-bound stagnation in soil.',
        'assetPath': 'assets/sprites/certificate_spryflora_icon.png',
        'fallbackIcon': Icons.nature_people,
        'xp': 225,
        'topic': 'Root Health',
      },
      {
        'id': 9,
        'title': 'Humidity Oasis',
        'badgeSymbol': 'CANOPY',
        'landName': 'Terora Haven',
        'description': 'Create a soothing tropical misting microclimate for lush fronds.',
        'assetPath': 'assets/sprites/mascot_pot_winking.png',
        'fallbackIcon': Icons.opacity,
        'xp': 250,
        'topic': 'Humidity',
      },
      {
        'id': 10,
        'title': 'Branch',
        'badgeSymbol': 'BRANCH',
        'landName': 'Terra Haven',
        'description': 'Excellent progress! Your SpryFlora is reaching out with new growth.',
        'assetPath': 'assets/sprites/plant_potted.png',
        'fallbackIcon': Icons.nature,
        'xp': 275,
        'topic': 'Branching Phase',
      },
      {
        'id': 11,
        'title': 'Sweet Bloom',
        'badgeSymbol': 'BLOOM',
        'landName': 'Rarama Convey',
        'description': 'Celebrate your first full vibrant blossom opening in the garden.',
        'assetPath': 'assets/sprites/mascot_celebrating_confetti.png',
        'fallbackIcon': Icons.filter_vintage,
        'xp': 300,
        'topic': 'Blooming',
      },
      {
        'id': 12,
        'title': 'Pollinator Haven',
        'badgeSymbol': 'HAVEN',
        'landName': 'Terra Sovings',
        'description': 'Attract friendly bees and butterflies to your thriving garden sanctuary.',
        'assetPath': 'assets/sprites/avatar_boy_hero.png',
        'fallbackIcon': Icons.emoji_nature,
        'xp': 350,
        'topic': 'Ecology',
      },
      {
        'id': 13,
        'title': 'Fruit Seedling',
        'badgeSymbol': 'HARVEST',
        'landName': 'Dewdrop Springs',
        'description': 'Observe successful pollination forming healthy small fruits.',
        'assetPath': 'assets/sprites/scroll_diploma.png',
        'fallbackIcon': Icons.yard,
        'xp': 400,
        'topic': 'Harvesting',
      },
      {
        'id': 14,
        'title': 'Canopy Growth',
        'badgeSymbol': 'CANOPY',
        'landName': 'Emerald Arbor',
        'description': 'Develop a thick canopy protecting delicate lower botanical life.',
        'assetPath': 'assets/sprites/mascot_graduate_logo.png',
        'fallbackIcon': Icons.park,
        'xp': 450,
        'topic': 'Canopy Management',
      },
      {
        'id': 15,
        'title': 'Guardian Tree',
        'badgeSymbol': 'GUARDIAN',
        'landName': 'Elderwood Sanctuary',
        'description': 'Become an environmental guardian providing shade and clean oxygen.',
        'assetPath': 'assets/sprites/certificate_approved_stamp.png',
        'fallbackIcon': Icons.forest,
        'xp': 500,
        'topic': 'Spry Conservation',
      },
      {
        'id': 16,
        'title': 'Spry Master',
        'badgeSymbol': 'MASTER',
        'landName': 'Celestia Flora',
        'description': 'Achieve ultimate master botanical status in the world of SpryFlora!',
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
        badgeSymbol: item['badgeSymbol'] as String,
        landName: item['landName'] as String,
        assetPath: item['assetPath'] as String,
        fallbackIcon: item['fallbackIcon'] as IconData,
        xpReward: item['xp'] as int,
        topic: item['topic'] as String,
      );
    });
  }
}
