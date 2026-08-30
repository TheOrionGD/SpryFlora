class PlantSpecies {
  final String name;
  final int lifespanDays;
  final int wateringIntervalDays;
  final String sunlight;
  final int targetSunlightHours;
  final String description;
  final String idealTemp;
  final String careTip;

  const PlantSpecies({
    required this.name,
    required this.lifespanDays,
    required this.wateringIntervalDays,
    this.sunlight = 'Moderate Sun',
    this.targetSunlightHours = 4,
    this.description = 'Beautiful indoor/outdoor plant.',
    this.idealTemp = '18°C - 28°C',
    this.careTip = 'Keep soil lightly moist and place in well-ventilated location.',
  });

  factory PlantSpecies.fromJson(Map<String, dynamic> json) {
    // Determine reasonable default target hours based on sunlight text
    final sunlightStr = json['sunlight'] as String? ?? 'Moderate Sun';
    int defaultHours = 4;
    final lower = sunlightStr.toLowerCase();
    if (lower.contains('indirect') || lower.contains('bright')) {
      defaultHours = 4;
    } else if (lower.contains('full') || lower.contains('direct')) {
      defaultHours = 6;
    } else if (lower.contains('low') || lower.contains('shade')) {
      defaultHours = 2;
    }

    return PlantSpecies(
      name: json['name'] as String? ?? 'Plant',
      lifespanDays: (json['lifespanDays'] as num?)?.toInt() ?? 150,
      wateringIntervalDays: (json['wateringIntervalDays'] as num?)?.toInt() ?? 3,
      sunlight: sunlightStr,
      targetSunlightHours: (json['targetSunlightHours'] as num?)?.toInt() ?? defaultHours,
      description: json['description'] as String? ?? 'Beautiful plant',
      idealTemp: json['idealTemp'] as String? ?? '18°C - 28°C',
      careTip: json['careTip'] as String? ??
          'Ensure regular hydration and adequate light exposure according to species needs.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lifespanDays': lifespanDays,
      'wateringIntervalDays': wateringIntervalDays,
      'sunlight': sunlight,
      'targetSunlightHours': targetSunlightHours,
      'description': description,
      'idealTemp': idealTemp,
      'careTip': careTip,
    };
  }

  @override
  String toString() => '$name (Lifespan: ${lifespanDays}d, Water: every ${wateringIntervalDays}d, Sun: ${targetSunlightHours}h)';
}
