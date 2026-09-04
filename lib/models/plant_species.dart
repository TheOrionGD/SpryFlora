class PlantSpecies {
  final String speciesId;
  final String commonName;
  final String botanicalName;
  final String image;
  final int growthDurationDays;
  final double initialHeightCm;
  final double matureHeightCm;
  final List<String> growthStages;
  final int wateringIntervalDays;
  final String wateringTolerance;
  final String sunlightRequirements;
  final int targetSunlightHours;
  final String careInstructions;
  final String description;
  final String idealTemp;

  // Backward compatibility getters
  String get name => commonName;
  int get lifespanDays => growthDurationDays;
  String get sunlight => sunlightRequirements;
  String get careTip => careInstructions;

  const PlantSpecies({
    String? speciesId,
    required String commonName,
    String? botanicalName,
    String? image,
    int? growthDurationDays,
    int? lifespanDays,
    required this.wateringIntervalDays,
    String? sunlightRequirements,
    String? sunlight,
    this.targetSunlightHours = 4,
    this.matureHeightCm = 50.0,
    this.initialHeightCm = 2.0,
    this.growthStages = const ['Seed', 'Sprout', 'Seedling', 'Young Plant', 'Growing Plant', 'Fully Grown Plant'],
    this.wateringTolerance = 'Moderate',
    String? careInstructions,
    String? careTip,
    this.description = 'Beautiful indoor/outdoor plant.',
    this.idealTemp = '18°C - 28°C',
  })  : speciesId = speciesId ?? commonName,
        commonName = commonName,
        botanicalName = botanicalName ?? commonName,
        image = image ?? '',
        growthDurationDays = growthDurationDays ?? lifespanDays ?? 150,
        sunlightRequirements = sunlightRequirements ?? sunlight ?? 'Moderate Sun',
        careInstructions = careInstructions ?? careTip ?? 'Keep soil lightly moist and place in well-ventilated location.';

  factory PlantSpecies.fromJson(Map<String, dynamic> json) {
    final cName = (json['commonName'] ?? json['name'] ?? 'Plant') as String;
    final sunlightStr = (json['sunlightRequirements'] ?? json['sunlight'] ?? 'Moderate Sun') as String;
    int defaultHours = 4;
    final lower = sunlightStr.toLowerCase();
    if (lower.contains('indirect') || lower.contains('bright')) {
      defaultHours = 4;
    } else if (lower.contains('full') || lower.contains('direct')) {
      defaultHours = 6;
    } else if (lower.contains('low') || lower.contains('shade')) {
      defaultHours = 2;
    }

    List<String> stages = const ['Seed', 'Sprout', 'Seedling', 'Young Plant', 'Growing Plant', 'Fully Grown Plant'];
    if (json['growthStages'] is List) {
      stages = (json['growthStages'] as List).map((e) => e.toString()).toList();
    }

    return PlantSpecies(
      speciesId: (json['speciesId'] ?? cName.toLowerCase().replaceAll(' ', '_')) as String,
      commonName: cName,
      botanicalName: (json['botanicalName'] ?? cName) as String,
      image: (json['image'] ?? '') as String,
      growthDurationDays: (json['growthDurationDays'] ?? json['lifespanDays'] as num?)?.toInt() ?? 150,
      wateringIntervalDays: (json['wateringIntervalDays'] as num?)?.toInt() ?? 3,
      wateringTolerance: (json['wateringTolerance'] ?? 'Moderate') as String,
      sunlightRequirements: sunlightStr,
      targetSunlightHours: (json['targetSunlightHours'] as num?)?.toInt() ?? defaultHours,
      matureHeightCm: (json['matureHeightCm'] as num?)?.toDouble() ?? 50.0,
      initialHeightCm: (json['initialHeightCm'] as num?)?.toDouble() ?? 2.0,
      growthStages: stages,
      careInstructions: (json['careInstructions'] ?? json['careTip'] ?? 'Ensure regular hydration and adequate light exposure according to species needs.') as String,
      description: (json['description'] ?? 'Beautiful plant') as String,
      idealTemp: (json['idealTemp'] ?? '18°C - 28°C') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'speciesId': speciesId,
      'name': commonName,
      'commonName': commonName,
      'botanicalName': botanicalName,
      'image': image,
      'growthDurationDays': growthDurationDays,
      'lifespanDays': growthDurationDays,
      'wateringIntervalDays': wateringIntervalDays,
      'wateringTolerance': wateringTolerance,
      'sunlightRequirements': sunlightRequirements,
      'sunlight': sunlightRequirements,
      'targetSunlightHours': targetSunlightHours,
      'matureHeightCm': matureHeightCm,
      'initialHeightCm': initialHeightCm,
      'growthStages': growthStages,
      'careInstructions': careInstructions,
      'careTip': careInstructions,
      'description': description,
      'idealTemp': idealTemp,
    };
  }

  @override
  String toString() => '$commonName ($botanicalName, Lifespan: ${growthDurationDays}d, Water: every ${wateringIntervalDays}d, Mature: ${matureHeightCm}cm)';
}
