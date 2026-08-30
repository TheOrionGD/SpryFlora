class UserProfile {
  final String childName;
  final int age;
  final String school;
  final String favoritePlant;
  final String? profilePhotoPath;
  final DateTime createdAt;

  UserProfile({
    required this.childName,
    required this.age,
    required this.school,
    required this.favoritePlant,
    this.profilePhotoPath,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'childName': childName,
      'age': age,
      'school': school,
      'favoritePlant': favoritePlant,
      'profilePhotoPath': profilePhotoPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      childName: json['childName'] as String,
      age: json['age'] as int,
      school: json['school'] as String,
      favoritePlant: json['favoritePlant'] as String,
      profilePhotoPath: json['profilePhotoPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Create a copy with modifications
  UserProfile copyWith({
    String? childName,
    int? age,
    String? school,
    String? favoritePlant,
    String? profilePhotoPath,
  }) {
    return UserProfile(
      childName: childName ?? this.childName,
      age: age ?? this.age,
      school: school ?? this.school,
      favoritePlant: favoritePlant ?? this.favoritePlant,
      profilePhotoPath: profilePhotoPath ?? this.profilePhotoPath,
      createdAt: createdAt,
    );
  }
}

class VirtualPlant {
  final String name;
  final int health; // 0-100
  final int level;
  final int wateringsCount;
  final DateTime lastWatered;

  VirtualPlant({
    required this.name,
    this.health = 50,
    this.level = 1,
    this.wateringsCount = 0,
    DateTime? lastWatered,
  }) : lastWatered = lastWatered ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'health': health,
      'level': level,
      'wateringsCount': wateringsCount,
      'lastWatered': lastWatered.toIso8601String(),
    };
  }

  factory VirtualPlant.fromJson(Map<String, dynamic> json) {
    return VirtualPlant(
      name: json['name'] as String,
      health: json['health'] as int? ?? 50,
      level: json['level'] as int? ?? 1,
      wateringsCount: json['wateringsCount'] as int? ?? 0,
      lastWatered: json['lastWatered'] != null
          ? DateTime.parse(json['lastWatered'] as String)
          : DateTime.now(),
    );
  }

  VirtualPlant copyWith({
    String? name,
    int? health,
    int? level,
    int? wateringsCount,
    DateTime? lastWatered,
  }) {
    return VirtualPlant(
      name: name ?? this.name,
      health: health ?? this.health,
      level: level ?? this.level,
      wateringsCount: wateringsCount ?? this.wateringsCount,
      lastWatered: lastWatered ?? this.lastWatered,
    );
  }
}
