class PlantModel {
  final String id;
  final String plantName;
  final String speciesName;
  final DateTime plantingDate;
  final int lifespanDays;
  final int wateringIntervalDays;
  final int targetSunlightHours;
  final int sunlightHoursToday;
  final DateTime? lastSunlightDate;
  final String? initialPhotoPath;
  final String location;
  final DateTime lastWateredDate;
  final DateTime nextWateringDate;
  final int health; // 0 to 100 overall health
  final int hydrationScore; // 0 to 100
  final int sunlightScore; // 0 to 100
  final int consistencyScore; // 0 to 100
  final String healthStatus; // 'Thriving', 'Optimal', 'Needs Sunlight', 'Under-watered', 'Stressed'
  final DateTime createdAt;
  final DateTime updatedAt;

  PlantModel({
    required this.id,
    required this.plantName,
    required this.speciesName,
    required this.plantingDate,
    required this.lifespanDays,
    required this.wateringIntervalDays,
    this.targetSunlightHours = 4,
    this.sunlightHoursToday = 0,
    this.lastSunlightDate,
    this.initialPhotoPath,
    this.location = 'Living Room',
    DateTime? lastWateredDate,
    DateTime? nextWateringDate,
    this.health = 96,
    this.hydrationScore = 95,
    this.sunlightScore = 95,
    this.consistencyScore = 95,
    this.healthStatus = 'Optimal',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : lastWateredDate = lastWateredDate ?? plantingDate,
        nextWateringDate = nextWateringDate ??
            plantingDate.add(Duration(days: wateringIntervalDays)),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Calculates dynamic plant age in days: Current Date - Planting Date
  int get ageInDays {
    final now = DateTime.now();
    final cleanNow = DateTime(now.year, now.month, now.day);
    final cleanPlanting = DateTime(plantingDate.year, plantingDate.month, plantingDate.day);
    final difference = cleanNow.difference(cleanPlanting).inDays;
    return difference < 0 ? 0 : difference;
  }

  /// Calculates Growth Progress strictly as: (Plant Age / Lifespan Days) clamped 0.0 -> 1.0
  double get growthProgress {
    if (lifespanDays <= 0) return 1.0;
    return (ageInDays / lifespanDays).clamp(0.0, 1.0);
  }

  /// Human-friendly Growth Stage Name based on progress
  String get growthStageName {
    final progress = growthProgress;
    if (progress < 0.20) {
      return 'Seed';
    } else if (progress < 0.50) {
      return 'Sprout';
    } else if (progress < 0.90) {
      return 'Growing Plant';
    } else {
      return 'Fully Grown Plant';
    }
  }

  /// Growth Stage Roman/Number or short badge
  String get stageBadge => growthStageName.toUpperCase();

  /// Whether the plant has completed its full lifecycle lifespan
  bool get isCompleted => lifespanDays > 0 && ageInDays >= lifespanDays;

  /// Calculates dynamic animation frame index given total frame count (e.g. 150)
  /// Frame Index = floor(Growth Progress * (totalFrames - 1))
  int calculateFrameIndex(int totalFrames) {
    if (totalFrames <= 1) return 0;
    final progress = (ageInDays / lifespanDays).clamp(0.0, 1.0);
    return (progress * (totalFrames - 1)).floor();
  }

  /// Checks if watering task is currently due or overdue
  bool get isWateringDue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextWateringDate.year, nextWateringDate.month, nextWateringDate.day);
    return today.isAtSameMomentAs(due) || today.isAfter(due);
  }

  /// Days until or overdue for next watering
  int get daysUntilWatering {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextWateringDate.year, nextWateringDate.month, nextWateringDate.day);
    return due.difference(today).inDays;
  }

  /// Checks if sunlight was logged today
  bool get isSunlightLoggedToday {
    if (lastSunlightDate == null) return false;
    final now = DateTime.now();
    return lastSunlightDate!.year == now.year &&
        lastSunlightDate!.month == now.month &&
        lastSunlightDate!.day == now.day &&
        sunlightHoursToday > 0;
  }

  /// Human-readable watering schedule status
  String get wateringStatusText {
    final days = daysUntilWatering;
    if (days < 0) {
      return 'Overdue by ${-days} ${-days == 1 ? 'day' : 'days'}';
    } else if (days == 0) {
      return 'Watering Due Today';
    } else if (days == 1) {
      return 'Water Tomorrow';
    } else {
      return 'Water in $days days';
    }
  }

  /// Human-readable sunlight schedule status
  String get sunlightStatusText {
    if (isSunlightLoggedToday) {
      return '$sunlightHoursToday / $targetSunlightHours hrs logged';
    }
    return '$targetSunlightHours hrs needed today';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plantName': plantName,
      'speciesName': speciesName,
      'plantingDate': plantingDate.toIso8601String(),
      'lifespanDays': lifespanDays,
      'wateringIntervalDays': wateringIntervalDays,
      'targetSunlightHours': targetSunlightHours,
      'sunlightHoursToday': sunlightHoursToday,
      'lastSunlightDate': lastSunlightDate?.toIso8601String(),
      'initialPhotoPath': initialPhotoPath,
      'location': location,
      'lastWateredDate': lastWateredDate.toIso8601String(),
      'nextWateringDate': nextWateringDate.toIso8601String(),
      'health': health,
      'hydrationScore': hydrationScore,
      'sunlightScore': sunlightScore,
      'consistencyScore': consistencyScore,
      'healthStatus': healthStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PlantModel.fromJson(Map<String, dynamic> json) {
    return PlantModel(
      id: json['id'] as String,
      plantName: json['plantName'] as String,
      speciesName: json['speciesName'] as String,
      plantingDate: DateTime.parse(json['plantingDate'] as String),
      lifespanDays: (json['lifespanDays'] as num).toInt(),
      wateringIntervalDays: (json['wateringIntervalDays'] as num).toInt(),
      targetSunlightHours: (json['targetSunlightHours'] as num?)?.toInt() ?? 4,
      sunlightHoursToday: (json['sunlightHoursToday'] as num?)?.toInt() ?? 0,
      lastSunlightDate: json['lastSunlightDate'] != null
          ? DateTime.parse(json['lastSunlightDate'] as String)
          : null,
      initialPhotoPath: json['initialPhotoPath'] as String?,
      location: json['location'] as String? ?? 'Indoor Garden',
      lastWateredDate: json['lastWateredDate'] != null
          ? DateTime.parse(json['lastWateredDate'] as String)
          : null,
      nextWateringDate: json['nextWateringDate'] != null
          ? DateTime.parse(json['nextWateringDate'] as String)
          : null,
      health: (json['health'] as num?)?.toInt() ?? 95,
      hydrationScore: (json['hydrationScore'] as num?)?.toInt() ?? 95,
      sunlightScore: (json['sunlightScore'] as num?)?.toInt() ?? 95,
      consistencyScore: (json['consistencyScore'] as num?)?.toInt() ?? 95,
      healthStatus: json['healthStatus'] as String? ?? 'Optimal',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  PlantModel copyWith({
    String? plantName,
    String? speciesName,
    DateTime? plantingDate,
    int? lifespanDays,
    int? wateringIntervalDays,
    int? targetSunlightHours,
    int? sunlightHoursToday,
    DateTime? lastSunlightDate,
    String? initialPhotoPath,
    String? location,
    DateTime? lastWateredDate,
    DateTime? nextWateringDate,
    int? health,
    int? hydrationScore,
    int? sunlightScore,
    int? consistencyScore,
    String? healthStatus,
    DateTime? updatedAt,
  }) {
    return PlantModel(
      id: id,
      plantName: plantName ?? this.plantName,
      speciesName: speciesName ?? this.speciesName,
      plantingDate: plantingDate ?? this.plantingDate,
      lifespanDays: lifespanDays ?? this.lifespanDays,
      wateringIntervalDays: wateringIntervalDays ?? this.wateringIntervalDays,
      targetSunlightHours: targetSunlightHours ?? this.targetSunlightHours,
      sunlightHoursToday: sunlightHoursToday ?? this.sunlightHoursToday,
      lastSunlightDate: lastSunlightDate ?? this.lastSunlightDate,
      initialPhotoPath: initialPhotoPath ?? this.initialPhotoPath,
      location: location ?? this.location,
      lastWateredDate: lastWateredDate ?? this.lastWateredDate,
      nextWateringDate: nextWateringDate ?? this.nextWateringDate,
      health: health ?? this.health,
      hydrationScore: hydrationScore ?? this.hydrationScore,
      sunlightScore: sunlightScore ?? this.sunlightScore,
      consistencyScore: consistencyScore ?? this.consistencyScore,
      healthStatus: healthStatus ?? this.healthStatus,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
