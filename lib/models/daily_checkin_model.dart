class DailyCheckinModel {
  final String id;
  final String plantId;
  final DateTime checkinDate;
  final bool watered;
  final int sunlightHours;
  final String environmentCondition; // e.g. "Direct Sun", "Bright Indirect", "Partial Shade", "Indoors"
  final String? photoPath;
  final String? notes;
  final String? aiDiagnosis;
  final DateTime createdAt;

  DailyCheckinModel({
    required this.id,
    required this.plantId,
    required this.checkinDate,
    required this.watered,
    this.sunlightHours = 4,
    this.environmentCondition = 'Bright Indirect',
    this.photoPath,
    this.notes,
    this.aiDiagnosis,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plantId': plantId,
      'checkinDate': checkinDate.toIso8601String(),
      'watered': watered,
      'sunlightHours': sunlightHours,
      'environmentCondition': environmentCondition,
      'photoPath': photoPath,
      'notes': notes,
      'aiDiagnosis': aiDiagnosis,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory DailyCheckinModel.fromJson(Map<String, dynamic> json) {
    return DailyCheckinModel(
      id: json['id'] as String,
      plantId: json['plantId'] as String,
      checkinDate: DateTime.parse(json['checkinDate'] as String),
      watered: json['watered'] as bool? ?? false,
      sunlightHours: (json['sunlightHours'] as num?)?.toInt() ?? 4,
      environmentCondition: json['environmentCondition'] as String? ?? 'Bright Indirect',
      photoPath: json['photoPath'] as String?,
      notes: json['notes'] as String?,
      aiDiagnosis: json['aiDiagnosis'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }
}
