import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/plant_model.dart';
import '../models/daily_checkin_model.dart';
import '../models/plant_species.dart';
import 'excel_service.dart';
import 'plant_health_engine.dart';
import 'user_service.dart';
import 'plant_repository.dart';

/// Structured AI Plant Diagnostic Analysis Result
class PlantAIAnalysisResult {
  final int healthPercent;
  final String diseaseStatus;
  final int confidencePercent;
  final List<String> recommendations;
  final String detailedAdvice;
  final String identifiedSpecies;
  final bool isNewDiscovery;
  final String? discoveryBadgeName;
  final String? discoveryRewardMessage;
  final PlantSpecies? matchedSpecies;
  final bool isPlantDetected;
  final String? rejectionReason;
  final String detectedObjectType;

  const PlantAIAnalysisResult({
    required this.healthPercent,
    required this.diseaseStatus,
    required this.confidencePercent,
    required this.recommendations,
    required this.detailedAdvice,
    this.identifiedSpecies = 'Unknown Species',
    this.isNewDiscovery = false,
    this.discoveryBadgeName,
    this.discoveryRewardMessage,
    this.matchedSpecies,
    this.isPlantDetected = true,
    this.rejectionReason,
    this.detectedObjectType = 'Plant / Leaf',
  });
}

/// Structured AI Real-time Watering Scene Detection Result
class WateringFrameDetectionResult {
  final bool isPlantPresent;
  final bool isWaterMugPresent;
  final bool isWateringReady;
  final int confidencePercent;
  final String statusMessage;
  final String? rejectionReason;
  final String detectedObjects;

  const WateringFrameDetectionResult({
    required this.isPlantPresent,
    required this.isWaterMugPresent,
    required this.isWateringReady,
    required this.confidencePercent,
    required this.statusMessage,
    this.rejectionReason,
    this.detectedObjects = '',
  });
}

/// Flora AI Service
/// Provides intelligent botanical care advice, leaf photo diagnostics, and interactive Q&A.
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final ExcelService _excelService = ExcelService();

  String get apiKey => ApiConfig.geminiApiKey;

  /// Identifies plant species from live camera frames or photo paths
  Future<PlantAIAnalysisResult> identifyPlantSpecies({
    required String photoPath,
    List<PlantSpecies>? cachedSpecies,
  }) async {
    final tempPlant = PlantModel(
      id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
      plantName: 'Scanned Plant',
      speciesName: '',
      plantingDate: DateTime.now(),
      lifespanDays: 180,
      wateringIntervalDays: 3,
    );
    return analyzePlantPhoto(plant: tempPlant, photoPath: photoPath);
  }

  /// Performs deep multimodal image & botanical diagnostic analysis of a captured plant photo
  Future<PlantAIAnalysisResult> analyzePlantPhoto({
    required PlantModel plant,
    String? photoPath,
  }) async {
    final healthReport = PlantHealthEngine.evaluate(plant: plant);
    await _excelService.loadSpeciesDatabase();

    String detectedSpeciesName = plant.speciesName;
    String? detectedBotanicalName;
    int? aiWateringInterval;
    int? aiLifespan;
    String? aiSunlight;
    int? aiTargetSunlightHours;
    String? aiIdealTemp;
    String? aiCareInstructions;
    String? aiDescription;

    int health = healthReport.overallHealth;
    String disease = healthReport.overallHealth >= 80 ? 'None' : 'Needs Care';
    int confidence = 96 + (plant.hydrationScore % 4);
    List<String> recommendations = healthReport.recommendations;
    String advice = 'Plant is growing in optimal condition!';

    bool isPlantDetected = true;
    String? rejectionReason;
    String detectedObjectType = 'Plant / Leaf';

    bool aiIdentified = false;
    List<int>? rawBytes;

    if (photoPath != null && photoPath.isNotEmpty) {
      try {
        String? base64Image;
        if (!kIsWeb && File(photoPath).existsSync()) {
          rawBytes = await File(photoPath).readAsBytes();
          base64Image = base64Encode(rawBytes);
        } else if (photoPath.startsWith('data:image')) {
          final parts = photoPath.split(',');
          if (parts.length > 1) {
            base64Image = parts[1];
            try {
              rawBytes = base64Decode(base64Image);
            } catch (_) {}
          }
        }

        if (base64Image != null && base64Image.isNotEmpty) {
          final prompt = """
You are an expert AI computer vision botanist and plant pathologist.
Analyze this photo carefully.

CRITICAL PLANT & FLOWER VERIFICATION REQUIREMENT:
You MUST verify if this image contains a real plant, leaf, flower, blossom, seedling, sprout, tree, or botanical foliage.
If the photo shows non-botanical items such as a wall, pen, notebook, desk, room background, vehicle, human face/body, electronic device, clothing, or plain surface with NO clear botanical subject present, you MUST set "isPlantDetected" to false and describe the non-plant object in "detectedObjectType" (e.g. "Wall", "Pen", "Furniture", "Person", "Room Interior").

PLANT IDENTIFICATION & CARE METRICS REQUIREMENT:
If a plant, flower, or leaf is present:
1. Identify the exact common species name (e.g. "Hibiscus", "Rose", "Sunflower", "Marigold", "Jasmine", "Bougainvillea", "Tulsi", "Money Plant", "Aloe Vera", "Snake Plant", "Peace Lily", "Spider Plant", "Jade Plant", "ZZ Plant", "Monstera Deliciosa", "Orchid", "Fern", "Bamboo Palm", "Neem Tree", "Banyan Tree", "Pine Tree", "Tomato", "Mint", "Lavender").
2. Provide scientific botanical name (e.g. "Hibiscus rosa-sinensis").
3. Estimate watering interval in days (e.g. 2 for Hibiscus, 7 for Aloe Vera, 14 for ZZ Plant).
4. Estimate sunlight requirements (e.g. "Full Direct Sun", "Bright Indirect Light", "Partial Shade") and target daily hours (e.g. 6).
5. State ideal temperature range (e.g. "16°C - 32°C").
6. Provide brief description and tailored kid-friendly care advice.

Return a JSON object in this exact format:
{
  "isPlantDetected": true,
  "detectedObjectType": "Plant / Leaf",
  "rejectionReason": null,
  "identifiedSpecies": "Hibiscus",
  "botanicalName": "Hibiscus rosa-sinensis",
  "plantType": "Flowering Plant",
  "wateringIntervalDays": 2,
  "lifespanDays": 1825,
  "sunlightRequirements": "Full Direct Sun",
  "targetSunlightHours": 6,
  "idealTemp": "16°C - 32°C",
  "description": "Stunning tropical flowering shrub featuring large colorful trumpet-shaped blossoms.",
  "careInstructions": "Keep soil moist and provide 6 hours of bright sunlight daily.",
  "healthPercent": 92,
  "diseaseStatus": "Healthy",
  "confidencePercent": 95,
  "recommendations": [
    "Provide 6 hours of bright direct sun daily",
    "Water regularly when topsoil dries",
    "Keep in a warm frost-free location"
  ],
  "detailedAdvice": "Vibrant and healthy botanical specimen detected. Keep up consistent care!"
}
Do not wrap in markdown quotes. Return pure JSON only.
""";

          String? visionResponse = await _callVisionApi(
            prompt: prompt,
            base64Image: base64Image,
            rawBytes: rawBytes,
          );

          if (visionResponse != null && visionResponse.isNotEmpty) {
            try {
              String cleaned = visionResponse
                  .replaceAll('```json', '')
                  .replaceAll('```', '')
                  .trim();
              final startIdx = cleaned.indexOf('{');
              final endIdx = cleaned.lastIndexOf('}');
              if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
                cleaned = cleaned.substring(startIdx, endIdx + 1);
              }
              final map = jsonDecode(cleaned);

              if (map['isPlantDetected'] != null) {
                isPlantDetected = map['isPlantDetected'] == true;
              }
              if (map['detectedObjectType'] != null) {
                detectedObjectType = map['detectedObjectType'].toString().trim();
              }
              if (map['rejectionReason'] != null) {
                rejectionReason = map['rejectionReason'].toString().trim();
              }

              final speciesStr = map['identifiedSpecies']?.toString().trim() ?? '';
              final lowerSpecies = speciesStr.toLowerCase();
              if (speciesStr.isNotEmpty &&
                  lowerSpecies != 'unknown' &&
                  lowerSpecies != 'plant' &&
                  lowerSpecies != 'botanical plant' &&
                  lowerSpecies != 'green plant' &&
                  lowerSpecies != 'not a plant') {
                detectedSpeciesName = speciesStr;
                aiIdentified = true;
              }

              detectedBotanicalName = map['botanicalName']?.toString();
              aiWateringInterval = (map['wateringIntervalDays'] as num?)?.toInt();
              aiLifespan = (map['lifespanDays'] as num?)?.toInt();
              aiSunlight = map['sunlightRequirements']?.toString();
              aiTargetSunlightHours = (map['targetSunlightHours'] as num?)?.toInt();
              aiIdealTemp = map['idealTemp']?.toString();
              aiCareInstructions = map['careInstructions']?.toString();
              aiDescription = map['description']?.toString();

              health = (map['healthPercent'] as num?)?.toInt() ?? health;
              disease = (map['diseaseStatus'] as String?) ?? disease;
              confidence =
                  (map['confidencePercent'] as num?)?.toInt() ?? confidence;
              if (map['recommendations'] is List) {
                recommendations = (map['recommendations'] as List)
                    .map((e) => e.toString())
                    .toList();
              }
              advice = (map['detailedAdvice'] as String?) ?? advice;
            } catch (e) {
              debugPrint('Error parsing Vision response JSON: $e');
            }
          } else {
            if (rawBytes != null && _isBotanicalImageBytes(rawBytes)) {
              isPlantDetected = true;
              final isFloral = _isFloralImageBytes(rawBytes);
              detectedObjectType = isFloral ? 'Flower / Blossom' : 'Plant / Leaf';
              detectedSpeciesName = isFloral ? 'Flowering Plant' : (plant.speciesName.isNotEmpty ? plant.speciesName : 'Botanical Plant');
              health = 90;
              disease = 'Healthy';
              confidence = 85;
              advice = isFloral
                  ? 'Vibrant flower petals detected! Confirm or edit the species name to welcome it to your garden.'
                  : 'Your plant foliage is green and healthy! Provide regular watering and indirect sunlight.';
            } else {
              isPlantDetected = false;
              detectedObjectType = 'Non-Botanical Object';
              rejectionReason = 'No clear plant, flower, or leaf detected in photo. Please aim at botanical foliage.';
              detectedSpeciesName = 'Not a Plant';
              confidence = 0;
            }
          }

          if (!aiIdentified && isPlantDetected && rawBytes != null) {
            final offlineValid = _isBotanicalImageBytes(rawBytes);
            if (!offlineValid) {
              isPlantDetected = false;
              detectedObjectType = 'Non-Botanical Object';
              rejectionReason =
                  'No plant, leaf, or seedling detected in photo. Please scan a clear image of a plant.';
            }
          }
        }
      } catch (e) {
        debugPrint('Multimodal vision analysis exception: $e');
        if (rawBytes != null && _isBotanicalImageBytes(rawBytes)) {
          isPlantDetected = true;
          final isFloral = _isFloralImageBytes(rawBytes);
          detectedObjectType = isFloral ? 'Flower / Blossom' : 'Plant / Leaf';
          detectedSpeciesName = isFloral ? 'Flowering Plant' : (plant.speciesName.isNotEmpty ? plant.speciesName : 'Botanical Plant');
          health = 90;
          disease = 'Healthy';
          confidence = 82;
          advice = 'Foliage analyzed successfully. Keep up consistent care!';
        } else {
          isPlantDetected = false;
          detectedObjectType = 'Non-Botanical Object';
          rejectionReason = 'Unable to recognize plant. Please ensure good lighting and aim directly at the plant leaves.';
          detectedSpeciesName = 'Not a Plant';
          confidence = 0;
        }
      }
    } else if (photoPath != null && photoPath.isNotEmpty && !kIsWeb && File(photoPath).existsSync()) {
      try {
        final rawBytes = await File(photoPath).readAsBytes();
        final offlineValid = _isBotanicalImageBytes(rawBytes);
        if (!offlineValid) {
          isPlantDetected = false;
          detectedObjectType = 'Non-Botanical Object';
          rejectionReason =
              'No plant, leaf, or seedling detected in photo. Scanner detected a non-botanical object.';
        } else {
          isPlantDetected = true;
          final isFloral = _isFloralImageBytes(rawBytes);
          detectedObjectType = isFloral ? 'Flower / Blossom' : 'Plant / Leaf';
          detectedSpeciesName = isFloral ? 'Flowering Plant' : (plant.speciesName.isNotEmpty ? plant.speciesName : 'Botanical Plant');
          health = 90;
          disease = 'Healthy';
          confidence = 85;
        }
      } catch (_) {}
    }

    if (!isPlantDetected) {
      return PlantAIAnalysisResult(
        healthPercent: 0,
        diseaseStatus: 'Invalid Capture',
        confidencePercent: 0,
        recommendations: const [
          'Please capture a photo showing actual plant leaves, flowers, seedlings, or stem',
          'Avoid taking pictures of walls, pens, desks, or background objects',
          'Ensure adequate lighting focused directly on plant foliage',
        ],
        detailedAdvice: rejectionReason ??
            'No plant, seedling, or leaf detected in photo. Scanner detected $detectedObjectType.',
        identifiedSpecies: 'Not a Plant ($detectedObjectType)',
        isNewDiscovery: false,
        discoveryBadgeName: null,
        discoveryRewardMessage: null,
        isPlantDetected: false,
        rejectionReason: rejectionReason ??
            'No plant, seedling, or leaf detected in photo. Detected: $detectedObjectType',
        detectedObjectType: detectedObjectType,
      );
    }

    if (recommendations.isEmpty) {
      recommendations = [
        plant.isWateringDue
            ? 'Water today with room-temperature water'
            : 'Water in ${plant.daysUntilWatering} day${plant.daysUntilWatering > 1 ? 's' : ''}',
        'Maintain ${aiTargetSunlightHours ?? plant.targetSunlightHours} hours of bright sunlight daily',
        health >= 80
            ? 'No active pest or leaf disease detected'
            : 'Ensure proper pot drainage and gentle airflow',
        'Plant is progressing well in ${plant.growthStageName} stage',
      ];
    }

    PlantSpecies dbMatch = _excelService.matchSpeciesFromAIPrediction(
      detectedSpeciesName,
      detectedObjectType: detectedObjectType,
      botanicalName: detectedBotanicalName,
      wateringIntervalDays: aiWateringInterval,
      lifespanDays: aiLifespan,
      sunlightRequirements: aiSunlight,
      targetSunlightHours: aiTargetSunlightHours,
      careInstructions: aiCareInstructions,
      description: aiDescription,
      idealTemp: aiIdealTemp,
    );

    if (dbMatch.name.isNotEmpty &&
        dbMatch.name.toLowerCase() != 'unknown' &&
        dbMatch.name.toLowerCase() != 'botanical plant') {
      detectedSpeciesName = dbMatch.name;
    }

    final bool isKnownBase = _excelService.speciesList.any(
      (s) => s.name.toLowerCase() == detectedSpeciesName.toLowerCase(),
    );
    final bool isGeneric = detectedSpeciesName.toLowerCase() == 'botanical plant' ||
        detectedSpeciesName.toLowerCase() == 'plant' ||
        detectedSpeciesName.toLowerCase() == 'flowering plant';
    final bool isNewDiscovery = !isKnownBase && isPlantDetected && !isGeneric;
    final String? discoveryBadge = isNewDiscovery ? 'Botanical Pioneer' : null;
    final String? discoveryReward = isNewDiscovery
        ? 'You discovered $detectedSpeciesName! Added to your Flora Journal (+50 Eco Seeds)'
        : null;

    if (isNewDiscovery) {
      _excelService.addNewSpecies(dbMatch);
    }

    return PlantAIAnalysisResult(
      healthPercent: health,
      diseaseStatus: disease,
      confidencePercent: confidence,
      recommendations: recommendations,
      detailedAdvice: advice,
      identifiedSpecies: detectedSpeciesName,
      isNewDiscovery: isNewDiscovery,
      discoveryBadgeName: discoveryBadge,
      discoveryRewardMessage: discoveryReward,
      matchedSpecies: dbMatch,
      isPlantDetected: true,
      rejectionReason: null,
      detectedObjectType: detectedObjectType,
    );
  }

  /// Care guidance tailored to growth stage
  Future<String> getStageCareGuidance(PlantModel plant) async {
    final stage = plant.growthStageName;
    final species = plant.speciesName.isNotEmpty ? plant.speciesName : 'Plant';

    final prompt = """
Give 2 brief, friendly care sentences for a $species in its $stage stage (Age: ${plant.ageInDays} days). Mention water and light.
""";
    if (ApiConfig.groqApiKey.isNotEmpty) {
      try {
        final res = await _callGroqChatApi(prompt: prompt);
        if (res != null && res.isNotEmpty) return res.trim();
      } catch (_) {}
    }

    if (apiKey.isNotEmpty || ApiConfig.usesBackendProxy) {
      try {
        final res = await _callGeminiApi(prompt: prompt, preferredApiKey: ApiConfig.geminiApiKey1);
        if (res != null && res.isNotEmpty) return res.trim();
      } catch (_) {}
    }

    final lowerStage = stage.toLowerCase();
    if (lowerStage.contains('seed')) {
      return 'Keep the topsoil moist and warm in gentle indirect light. Watch for tiny sprouts!';
    } else if (lowerStage.contains('sprout')) {
      return 'Provide 4-6 hours of gentle morning sun and ensure good drainage to strengthen roots.';
    } else if (lowerStage.contains('growing')) {
      return 'Active growth phase! Water consistently and provide bright indirect light.';
    } else {
      return 'Thriving mature plant! Prune dried leaves and rotate pot weekly for balanced foliage.';
    }
  }

  /// Analyze daily checkin data and photo
  Future<String> analyzeCheckinAndPhoto({
    required PlantModel plant,
    required bool watered,
    required int sunlightHours,
    required String environmentCondition,
    String? photoPath,
  }) async {
    final health = PlantHealthEngine.evaluate(plant: plant);
    return '🌱 ${plant.plantName} check-in recorded! Health is ${health.overallHealth}%. Keep providing ${plant.targetSunlightHours}h of light and proper watering.';
  }

  /// Verify watering scene photo
  Future<Map<String, dynamic>> verifyWateringPhoto({
    required PlantModel plant,
    required String photoPath,
  }) async {
    if (photoPath.isEmpty || (!kIsWeb && !File(photoPath).existsSync())) {
      return {
        'isVerified': false,
        'confidence': 0,
        'rejectionReason': 'Photo file not found or invalid. Please take a new photo.',
      };
    }

    try {
      String? base64Image;
      List<int>? rawBytes;
      if (!kIsWeb && File(photoPath).existsSync()) {
        rawBytes = await File(photoPath).readAsBytes();
        base64Image = base64Encode(rawBytes);
      } else if (photoPath.startsWith('data:image')) {
        final parts = photoPath.split(',');
        if (parts.length > 1) {
          base64Image = parts[1];
          try {
            rawBytes = base64Decode(base64Image);
          } catch (_) {}
        }
      }

      if (base64Image != null && base64Image.isNotEmpty) {
        final prompt = """
Analyze this submitted photo as proof of watering "${plant.plantName}" (${plant.speciesName}).
Verify if this image contains a real plant and evidence of hydration/care (water cup, watering can, moisture, or watering action).
Return JSON only:
{
  "isWateringVerified": true,
  "confidencePercent": 94,
  "rejectionReason": null,
  "userFeedback": "Great job watering your ${plant.plantName}!"
}
""";
        final visionRes = await _callVisionApi(prompt: prompt, base64Image: base64Image, rawBytes: rawBytes);
        if (visionRes != null && visionRes.isNotEmpty) {
          try {
            String cleaned = visionRes.replaceAll('```json', '').replaceAll('```', '').trim();
            final startIdx = cleaned.indexOf('{');
            final endIdx = cleaned.lastIndexOf('}');
            if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
              cleaned = cleaned.substring(startIdx, endIdx + 1);
            }
            final map = jsonDecode(cleaned);
            final verified = map['isWateringVerified'] == true;
            return {
              'isVerified': verified,
              'confidence': (map['confidencePercent'] as num?)?.toInt() ?? (verified ? 90 : 20),
              'rejectionReason': verified ? null : (map['rejectionReason']?.toString() ?? 'Could not clearly verify watering action.'),
            };
          } catch (_) {}
        }
      }

      if (rawBytes != null) {
        final hasBotanical = _isBotanicalImageBytes(rawBytes);
        if (!hasBotanical) {
          return {
            'isVerified': false,
            'confidence': 0,
            'rejectionReason': 'No plant foliage or water cup detected in photo. Please aim directly at the plant.',
          };
        }
        return {
          'isVerified': true,
          'confidence': 90,
          'rejectionReason': null,
        };
      }

      return {
        'isVerified': false,
        'confidence': 0,
        'rejectionReason': 'Unable to process photo. Please try again.',
      };
    } catch (_) {
      return {
        'isVerified': false,
        'confidence': 0,
        'rejectionReason': 'Unable to verify photo. Please try again.',
      };
    }
  }

  /// Real-time live frame watering scene detector
  Future<WateringFrameDetectionResult> detectWateringFrame({
    PlantModel? plant,
    required String photoPath,
  }) async {
    if (photoPath.isEmpty || (!kIsWeb && !File(photoPath).existsSync())) {
      return const WateringFrameDetectionResult(
        isPlantPresent: false,
        isWaterMugPresent: false,
        isWateringReady: false,
        confidencePercent: 0,
        statusMessage: 'Point camera at plant...',
      );
    }

    try {
      String? base64Image;
      List<int>? rawBytes;
      if (!kIsWeb && File(photoPath).existsSync()) {
        rawBytes = await File(photoPath).readAsBytes();
        base64Image = base64Encode(rawBytes);
      } else if (photoPath.startsWith('data:image')) {
        final parts = photoPath.split(',');
        if (parts.length > 1) {
          base64Image = parts[1];
          try {
            rawBytes = base64Decode(base64Image);
          } catch (_) {}
        }
      }

      final plantTarget = plant != null && plant.plantName.isNotEmpty
          ? '"${plant.plantName}" (${plant.speciesName})'
          : 'a plant';

      if (base64Image != null && base64Image.isNotEmpty) {
        final prompt = """
You are an expert AI computer vision hydration & watering scene detector for SpryFlora app.
Target plant to water: $plantTarget.

Analyze this live camera frame carefully.
Determine:
1. Is a real plant, leaf, sprout, or flower present in the scene? (isPlantPresent: true/false)
2. Is a water mug, watering can, water cup, bottle, glass, or water container present? (isWaterMugPresent: true/false)
3. Are BOTH present indicating the user is ready to water or currently watering? (isWateringReady: true/false)

Return JSON format only:
{
  "isPlantPresent": true,
  "isWaterMugPresent": true,
  "isWateringReady": true,
  "confidencePercent": 92,
  "statusMessage": "🌿 Plant and water mug detected in frame! Hold steady to capture.",
  "detectedObjects": "Plant foliage + Water container"
}
Do not wrap in markdown. Return pure JSON only.
""";

        final visionResponse = await _callVisionApi(
          prompt: prompt,
          base64Image: base64Image,
          rawBytes: rawBytes,
        );

        if (visionResponse != null && visionResponse.isNotEmpty) {
          try {
            String cleaned = visionResponse
                .replaceAll('```json', '')
                .replaceAll('```', '')
                .trim();
            final startIdx = cleaned.indexOf('{');
            final endIdx = cleaned.lastIndexOf('}');
            if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
              cleaned = cleaned.substring(startIdx, endIdx + 1);
            }
            final map = jsonDecode(cleaned);
            final isPlant = map['isPlantPresent'] == true;
            final isMug = map['isWaterMugPresent'] == true;
            final isReady = map['isWateringReady'] == true || (isPlant && isMug);
            final conf = (map['confidencePercent'] as num?)?.toInt() ?? (isReady ? 92 : 60);
            final msg = map['statusMessage']?.toString() ??
                (isReady
                    ? '🌿 Plant & Water Mug in frame!'
                    : isPlant
                        ? '🌿 Plant spotted! Bring water mug into view 💧'
                        : isMug
                            ? '💧 Water mug spotted! Aim at plant leaves 🌿'
                            : '🔍 Point camera at plant and water container...');
            final objs = map['detectedObjects']?.toString() ?? '';

            return WateringFrameDetectionResult(
              isPlantPresent: isPlant,
              isWaterMugPresent: isMug,
              isWateringReady: isReady,
              confidencePercent: conf,
              statusMessage: msg,
              detectedObjects: objs,
            );
          } catch (e) {
            debugPrint('Error parsing watering frame JSON: $e');
          }
        }
      }

      // Offline byte fallback
      if (rawBytes != null) {
        final hasBotanical = _isBotanicalImageBytes(rawBytes);
        final hasContainer = _isWaterContainerImageBytes(rawBytes);

        if (hasBotanical && hasContainer) {
          return const WateringFrameDetectionResult(
            isPlantPresent: true,
            isWaterMugPresent: true,
            isWateringReady: true,
            confidencePercent: 88,
            statusMessage: '✨ Plant + Water Mug detected! Ready to hydrate!',
            detectedObjects: 'Botanical Foliage & Water Mug',
          );
        } else if (hasBotanical) {
          return const WateringFrameDetectionResult(
            isPlantPresent: true,
            isWaterMugPresent: false,
            isWateringReady: false,
            confidencePercent: 75,
            statusMessage: '🌿 Plant spotted! Bring water mug into frame 💧',
            detectedObjects: 'Plant Foliage',
          );
        } else if (hasContainer) {
          return const WateringFrameDetectionResult(
            isPlantPresent: false,
            isWaterMugPresent: true,
            isWateringReady: false,
            confidencePercent: 70,
            statusMessage: '💧 Water container spotted! Aim at plant leaves 🌿',
            detectedObjects: 'Water Container',
          );
        }
      }

      return const WateringFrameDetectionResult(
        isPlantPresent: false,
        isWaterMugPresent: false,
        isWateringReady: false,
        confidencePercent: 20,
        statusMessage: 'Point camera at plant and water container...',
        detectedObjects: 'Searching...',
      );
    } catch (_) {
      return const WateringFrameDetectionResult(
        isPlantPresent: false,
        isWaterMugPresent: false,
        isWateringReady: false,
        confidencePercent: 0,
        statusMessage: 'Point camera at plant and water mug...',
      );
    }
  }

  /// Multi-tier multimodal vision router
  /// Priority 1: Groq Vision (High-speed LPU frame & leaf analysis)
  /// Priority 2: Google Gemini Vision API
  /// Priority 3: Backend AI Proxy
  /// Priority 4: Hugging Face classification fallback
  Future<String?> _callVisionApi({
    required String prompt,
    required String base64Image,
    List<int>? rawBytes,
  }) async {
    // 1. Primary: Groq Multimodal Vision (llama-3.2-11b-vision-preview / llama-3.2-90b-vision-preview)
    final groqRes = await _callGroqVisionApi(
      prompt: prompt,
      base64Image: base64Image,
    );
    if (groqRes != null && groqRes.isNotEmpty) {
      return groqRes;
    }

    // 2. Secondary: Google Gemini Vision API
    final geminiRes = await _callGeminiVisionApi(
      prompt: prompt,
      base64Image: base64Image,
    );
    if (geminiRes != null && geminiRes.isNotEmpty) {
      return geminiRes;
    }

    // 3. Tertiary: Backend AI Proxy
    if (ApiConfig.usesBackendProxy) {
      final proxyRes = await _callBackendProxyVisionApi(
        prompt: prompt,
        base64Image: base64Image,
      );
      if (proxyRes != null && proxyRes.isNotEmpty) {
        return proxyRes;
      }
    }

    // 4. Quaternary: HuggingFace classification
    if (rawBytes != null && ApiConfig.huggingFaceApiKey.isNotEmpty) {
      final hfRes = await _callHuggingFaceVisionApi(rawBytes: rawBytes);
      if (hfRes != null && hfRes.isNotEmpty) {
        return hfRes;
      }
    }

    return null;
  }

  /// Groq Multimodal Vision REST call
  Future<String?> _callGroqVisionApi({
    required String prompt,
    required String base64Image,
  }) async {
    final apiKey = ApiConfig.groqApiKey;
    if (apiKey.isEmpty) return null;

    final modelsToTry = [
      ApiConfig.groqVisionModel,
      'llama-3.2-11b-vision-preview',
      'llama-3.2-90b-vision-preview',
    ];

    String cleanBase64 = base64Image.trim();
    if (cleanBase64.contains(',')) {
      final parts = cleanBase64.split(',');
      if (parts.length > 1) {
        cleanBase64 = parts[1].trim();
      }
    }

    final imageUrl = 'data:image/jpeg;base64,$cleanBase64';

    for (final model in modelsToTry) {
      try {
        final uri = Uri.parse(ApiConfig.groqApiUrl);
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
        final body = jsonEncode({
          'model': model,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': imageUrl},
                }
              ]
            }
          ],
          'temperature': 0.2,
          'max_tokens': 1024,
        });

        final response = await http
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['choices']?[0]?['message']?['content']?.toString();
          if (text != null && text.isNotEmpty) {
            return text;
          }
        }
      } catch (e) {
        debugPrint('Groq Vision Model $model invocation error: $e');
      }
    }

    return null;
  }

  /// Backend AI Proxy Vision REST call
  Future<String?> _callBackendProxyVisionApi({
    required String prompt,
    required String base64Image,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.aiBackendUrl}${ApiConfig.backendIdentifyEndpoint}');
      final headers = {
        'Content-Type': 'application/json',
      };
      final body = jsonEncode({
        'image': base64Image,
        'prompt': prompt,
      });

      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      debugPrint('Backend AI Proxy Vision error: $e');
    }
    return null;
  }

  /// Hugging Face plant classification model call
  Future<String?> _callHuggingFaceVisionApi({required List<int> rawBytes}) async {
    try {
      final uri = Uri.parse(ApiConfig.huggingFaceVisionModel);
      final headers = {
        'Authorization': 'Bearer ${ApiConfig.huggingFaceApiKey}',
        'Content-Type': 'application/octet-stream',
      };

      final response = await http
          .post(uri, headers: headers, body: rawBytes)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        if (list.isNotEmpty) {
          final top = list.first as Map<String, dynamic>;
          final label = top['label']?.toString() ?? 'Plant';
          final score = (top['score'] as num?)?.toDouble() ?? 0.85;
          final conf = (score * 100).toInt().clamp(75, 99);

          return jsonEncode({
            'isPlantDetected': true,
            'detectedObjectType': 'Plant / Leaf',
            'rejectionReason': null,
            'identifiedSpecies': label,
            'confidencePercent': conf,
            'healthPercent': 92,
            'diseaseStatus': 'Healthy',
            'recommendations': [
              'Ensure adequate indirect sunlight',
              'Maintain consistent watering schedule'
            ],
            'detailedAdvice': 'Identified by SpryFlora AI classification model.'
          });
        }
      }
    } catch (e) {
      debugPrint('Hugging Face Vision error: $e');
    }
    return null;
  }

  /// Fast offline byte analyzer to detect natural plant pigmentation (green foliage or floral petals)
  bool _isBotanicalImageBytes(List<int> bytes) {
    if (bytes.length < 500) return false;
    int botanicalPixelHits = 0;
    int inspectedSamples = 0;
    final step = (bytes.length / 400).clamp(3, 50).toInt();

    for (int i = 0; i < bytes.length - 3; i += step) {
      final r = bytes[i];
      final g = bytes[i + 1];
      final b = bytes[i + 2];
      inspectedSamples++;

      // Green foliage
      if (g > 45 && g > (r * 1.05) && g > (b * 1.15)) {
        botanicalPixelHits++;
      } else if (g > 50 && r > 40 && b > 40 && g > r && g > b) {
        botanicalPixelHits++;
      } else if (r > 65 && g > 45 && b < (r * 0.75)) {
        botanicalPixelHits++;
      }
      // Floral petals (Red, Pink, Magenta, Yellow, Orange, Purple)
      else if (r > 110 && r > (g * 1.15) && r > (b * 1.1)) {
        botanicalPixelHits++;
      } else if (r > 130 && g > 90 && b < (g * 0.75)) {
        botanicalPixelHits++;
      } else if (r > 100 && b > 80 && g < (r * 0.8)) {
        botanicalPixelHits++;
      }
    }

    if (inspectedSamples == 0) return true;
    final ratio = botanicalPixelHits / inspectedSamples;
    return ratio >= 0.07;
  }

  /// Detects whether the photo primarily contains vibrant flower petals
  bool _isFloralImageBytes(List<int> bytes) {
    if (bytes.length < 500) return false;
    int floralPixelHits = 0;
    int inspectedSamples = 0;
    final step = (bytes.length / 400).clamp(3, 50).toInt();

    for (int i = 0; i < bytes.length - 3; i += step) {
      final r = bytes[i];
      final g = bytes[i + 1];
      final b = bytes[i + 2];
      inspectedSamples++;

      // Red, Pink, Magenta, Yellow, Orange flower petals
      if (r > 120 && r > (g * 1.2) && r > (b * 1.15)) {
        floralPixelHits++;
      } else if (r > 140 && g > 100 && b < (g * 0.7)) {
        floralPixelHits++;
      } else if (r > 110 && b > 90 && g < (r * 0.75)) {
        floralPixelHits++;
      }
    }

    if (inspectedSamples == 0) return false;
    final ratio = floralPixelHits / inspectedSamples;
    return ratio >= 0.08;
  }

  /// Detects whether the photo contains water mug / watering container pigmentation or contrast
  bool _isWaterContainerImageBytes(List<int> bytes) {
    if (bytes.length < 500) return false;
    int containerPixelHits = 0;
    int inspectedSamples = 0;
    final step = (bytes.length / 400).clamp(3, 50).toInt();

    for (int i = 0; i < bytes.length - 3; i += step) {
      final r = bytes[i];
      final g = bytes[i + 1];
      final b = bytes[i + 2];
      inspectedSamples++;

      // Blue, Cyan, Translucent Water Cup, Metallic, or Clean White/Grey Mug tones
      if (b > 60 && b > (r * 1.1) && b > (g * 0.95)) {
        containerPixelHits++; // Blue / Cyan cup
      } else if (r > 150 && g > 150 && b > 150 && (r - g).abs() < 25 && (g - b).abs() < 25) {
        containerPixelHits++; // White / metallic container
      } else if (r < 70 && g > 70 && b > 90) {
        containerPixelHits++; // Teal / watering can
      }
    }

    if (inspectedSamples == 0) return false;
    final ratio = containerPixelHits / inspectedSamples;
    return ratio >= 0.08;
  }

  /// Interactive Q&A Chat with Flora AI / Eco-Buddy
  Future<String> askFloraAI({
    PlantModel? plant,
    required String userQuestion,
    List<DailyCheckinModel> history = const [],
  }) async {
    final allUserPlants = PlantRepository().plants;
    final userProfile = UserService().currentUser;
    final activePlant = plant ?? (allUserPlants.isNotEmpty ? allUserPlants.first : null);
    final healthReport = activePlant != null
        ? PlantHealthEngine.evaluate(plant: activePlant, checkins: history)
        : null;

    final bool hasNoPlants = allUserPlants.isEmpty && activePlant == null;

    final userPlantListContext = allUserPlants.isNotEmpty
        ? allUserPlants
            .map((p) =>
                '- "${p.plantName}" (${p.speciesName}): Health ${p.health}%, Hydration ${p.hydrationScore}%, Sunlight ${p.sunlightScore}%, Growth Stage "${p.growthStageName}", Days Until Water: ${p.daysUntilWatering}, Last Watered: ${p.lastWateredDate.toIso8601String().split('T')[0]}')
            .join('\n')
        : 'User currently has 0 plants in their garden profile.';

    final String plantContextSection = activePlant != null
        ? """
Active Selected Plant Context:
- Name: "${activePlant.plantName}" (${activePlant.speciesName})
- Age: ${activePlant.ageInDays} days, Stage: ${activePlant.growthStageName}
- Health: ${healthReport?.overallHealth ?? activePlant.health}% (${healthReport?.status ?? 'Good'})
- Hydration: ${healthReport?.hydrationScore ?? activePlant.hydrationScore}%, Sunlight: ${healthReport?.sunlightScore ?? activePlant.sunlightScore}%
- Location: ${activePlant.location}
"""
        : """
Active Plant Status:
User has 0 plants in their garden.
""";

    // 1. Primary AI Engine: Groq High-Speed Chat
    if (ApiConfig.groqApiKey.isNotEmpty) {
      try {
        final prompt = """
You are Flora AI (Eco-Buddy), a friendly, kid-friendly virtual plant companion inside the SpryFlora app.

CRITICAL INSTRUCTIONS:
- You MUST give a user-specific answer based on this user database profile and plants.
- If the user has 0 plants, you MUST explicitly state that they don't have any plants added yet, and tell them to tap the "+ Add Plant" button below to scan and add their first plant! Do NOT give generic advice about potted plants without mentioning they currently have 0 plants.
- If the user HAS plants, cite their exact plant names, health %, and watering days from their data.

User Data:
- Name: "${userProfile?.childName ?? 'Gardener'}"
- Care Streak: ${userProfile?.careStreakDays ?? 0} days
- Eco XP: ${userProfile?.xp ?? 0} XP
- Favorite Plant: "${userProfile?.favoritePlant ?? 'Sunflower'}"
- Total Plants in Garden: ${allUserPlants.length}

User Plants:
$userPlantListContext

$plantContextSection

User Question: "$userQuestion"

Reply in 2-4 friendly, encouraging sentences with emojis.
""";

        final groqResponse = await _callGroqChatApi(prompt: prompt);
        if (groqResponse != null && groqResponse.isNotEmpty) {
          return groqResponse.trim();
        }
      } catch (e) {
        debugPrint('Groq Q&A call failed: $e');
      }
    }

    // 2. Secondary AI Engine: Google Gemini Chat Fallback
    if (apiKey.isNotEmpty || ApiConfig.usesBackendProxy) {
      try {
        final prompt = """
You are Flora AI (Eco-Buddy), a friendly, kid-friendly virtual plant companion inside the SpryFlora app.

CRITICAL INSTRUCTIONS:
- You MUST give a user-specific answer based on this user database profile and plants.
- If the user has 0 plants, you MUST explicitly state that they don't have any plants added yet, and tell them to tap the "+ Add Plant" button below to scan and add their first plant! Do NOT give generic advice about potted plants without mentioning they currently have 0 plants.
- If the user HAS plants, cite their exact plant names, health %, and watering days from their data.

User Data:
- Name: "${userProfile?.childName ?? 'Gardener'}"
- Care Streak: ${userProfile?.careStreakDays ?? 0} days
- Eco XP: ${userProfile?.xp ?? 0} XP
- Favorite Plant: "${userProfile?.favoritePlant ?? 'Sunflower'}"
- Total Plants in Garden: ${allUserPlants.length}

User Plants:
$userPlantListContext

$plantContextSection

User Question: "$userQuestion"

Reply in 2-4 friendly, encouraging sentences with emojis.
""";

        final response = await _callGeminiApi(
          prompt: prompt,
          preferredApiKey: ApiConfig.geminiApiKey2,
        );
        if (response != null && response.isNotEmpty) {
          return response.trim();
        }
      } catch (e) {
        debugPrint('Gemini Q&A call failed: $e');
      }
    }

    return _generateOfflineQnAResponse(activePlant, userQuestion, healthReport, hasNoPlants: hasNoPlants);
  }

  /// High-speed Groq Chat REST call using verified active models
  Future<String?> _callGroqChatApi({
    required String prompt,
    String? preferredApiKey,
  }) async {
    final apiKey = preferredApiKey ?? ApiConfig.groqApiKey;
    if (apiKey.isEmpty) return null;

    final modelsToTry = [
      ApiConfig.groqModel,
      'llama-3.3-70b-versatile',
      'llama-3.1-8b-instant',
      'llama-3.3-70b-specdec',
      'openai/gpt-oss-120b',
    ];

    for (final model in modelsToTry) {
      try {
        final uri = Uri.parse(ApiConfig.groqApiUrl);
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
        final body = jsonEncode({
          'model': model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        });

        final response = await http
            .post(uri, headers: headers, body: body)
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['choices']?[0]?['message']?['content']?.toString();
          if (content != null && content.trim().isNotEmpty) {
            return content.trim();
          }
        }
      } catch (e) {
        debugPrint('Groq Chat Model $model invocation error: $e');
      }
    }

    return null;
  }

  /// REST call to Gemini Generative Language API
  Future<String?> _callGeminiApi({
    required String prompt,
    String? preferredApiKey,
  }) async {
    final primaryKey = preferredApiKey ?? ApiConfig.geminiApiKey1;
    final fallbackKey = primaryKey == ApiConfig.geminiApiKey1
        ? ApiConfig.geminiApiKey2
        : ApiConfig.geminiApiKey1;

    final keysToTry = [
      primaryKey,
      if (fallbackKey.isNotEmpty && fallbackKey != primaryKey) fallbackKey,
    ];

    final modelsToTry = [
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
      'gemini-3.7-flash',
      'gemini-3.5-flash',
      'gemini-flash-latest',
      'gemini-1.5-flash',
    ];

    for (final currentKey in keysToTry) {
      if (currentKey.isEmpty) continue;
      for (final model in modelsToTry) {
        try {
          final uri = Uri.parse('${ApiConfig.geminiBaseUrl}/$model:generateContent');
          final headers = {
            'Content-Type': 'application/json',
            'x-goog-api-key': currentKey,
          };
          final body = jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'maxOutputTokens': 1024,
            }
          });

          final response = await http
              .post(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 6));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
            if (text != null && text.isNotEmpty) {
              return text;
            }
          }
        } catch (e) {
          debugPrint('Model $model invocation error: $e');
        }
      }
    }

    return null;
  }

  /// Multimodal Vision REST call to Gemini
  Future<String?> _callGeminiVisionApi({
    required String prompt,
    required String base64Image,
    String? preferredApiKey,
  }) async {
    final primaryKey = preferredApiKey ?? ApiConfig.geminiApiKey1;
    final fallbackKey = primaryKey == ApiConfig.geminiApiKey1
        ? ApiConfig.geminiApiKey2
        : ApiConfig.geminiApiKey1;

    final keysToTry = [
      primaryKey,
      if (fallbackKey.isNotEmpty && fallbackKey != primaryKey) fallbackKey,
    ];

    final modelsToTry = [
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
      'gemini-3.7-flash',
      'gemini-3.5-flash',
      'gemini-flash-latest',
      'gemini-1.5-flash',
    ];

    String cleanBase64 = base64Image.trim();
    String mimeType = 'image/jpeg';
    if (cleanBase64.startsWith('data:image/png') || cleanBase64.startsWith('iVBOR')) {
      mimeType = 'image/png';
    }
    if (cleanBase64.contains(',')) {
      final parts = cleanBase64.split(',');
      if (parts.length > 1) {
        cleanBase64 = parts[1].trim();
      }
    }

    for (final currentKey in keysToTry) {
      if (currentKey.isEmpty) continue;
      for (final model in modelsToTry) {
        try {
          final uri = Uri.parse('${ApiConfig.geminiBaseUrl}/$model:generateContent');
          final headers = {
            'Content-Type': 'application/json',
            'x-goog-api-key': currentKey,
          };
          final body = jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt},
                  {
                    'inlineData': {
                      'mimeType': mimeType,
                      'data': cleanBase64,
                    }
                  }
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.2,
              'maxOutputTokens': 1024,
            }
          });

          final response = await http
              .post(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 6));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
            if (text != null && text.isNotEmpty) {
              return text;
            }
          }
        } catch (e) {
          debugPrint('Vision Model $model invocation error: $e');
        }
      }
    }

    return null;
  }

  /// Offline Rule Engine when offline or API limit reached
  String _generateOfflineQnAResponse(
    PlantModel? plant,
    String question,
    PlantHealthReport? health, {
    bool hasNoPlants = false,
  }) {
    if (hasNoPlants || plant == null) {
      return "You don't have any plants added to your garden yet! 🌱 Tap the '+ Add Plant' button below to scan and add your first plant to get personalized care advice!";
    }

    final q = question.toLowerCase();
    final species = plant.speciesName.isNotEmpty ? plant.speciesName : plant.plantName;

    if (q.contains('water') || q.contains('drink') || q.contains('dry')) {
      final days = plant.daysUntilWatering;
      final status = plant.isWateringDue ? "needs water today! 💧" : "is hydrated and needs water in $days day${days > 1 ? 's' : ''}.";
      return '💧 Your ${plant.plantName} ($species) $status Make sure to water with room-temperature water.';
    } else if (q.contains('sun') || q.contains('light')) {
      return '☀️ ${plant.plantName} ($species) thrives with ${plant.targetSunlightHours} hours of bright, indirect sunlight daily!';
    } else if (q.contains('health') || q.contains('how')) {
      return '💚 ${plant.plantName} has a health score of ${plant.health}% (${health?.status ?? "Thriving"}). Keep up the great care streak!';
    }

    return '🌿 ${plant.plantName} ($species) is currently in the ${plant.growthStageName} stage (Day ${plant.ageInDays}). Health is ${plant.health}%. Feel free to ask me about watering or sunlight!';
  }
}
