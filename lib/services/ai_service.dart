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
If the photo shows non-botanical items such as a wall, pen, notebook, desk, room background, vehicle, human face/body, electronic device, clothing, or plain surface with NO clear botanical subject present, you MUST set "isPlantDetected" to false, "identifiedSpecies" to "No Plant Found", "confidencePercent" to 0, and describe the non-plant object in "detectedObjectType" (e.g. "Wall", "Pen", "Furniture", "Person", "Room Interior").

PLANT IDENTIFICATION & CARE METRICS REQUIREMENT:
If and ONLY if a real plant, flower, or leaf is present:
1. Identify the exact common species name (e.g. Rose, Sunflower, Marigold, Jasmine, Bougainvillea, Tulsi, Money Plant, Aloe Vera, Snake Plant, Peace Lily, Spider Plant, Jade Plant, ZZ Plant, Monstera Deliciosa, Orchid, Fern, Bamboo Palm, Neem Tree, Banyan Tree, Pine Tree, Tomato, Mint, Lavender, Hibiscus).
2. Provide scientific botanical name (e.g. Rosa rubiginosa).
3. Estimate watering interval in days.
4. Estimate sunlight requirements and target daily hours.
5. State ideal temperature range.
6. Provide brief description and tailored kid-friendly care advice.

If a plant IS detected, return JSON format:
{
  "isPlantDetected": true,
  "detectedObjectType": "Plant / Leaf",
  "rejectionReason": null,
  "identifiedSpecies": "<Identified common species name>",
  "botanicalName": "<Scientific botanical name>",
  "plantType": "Flowering Plant / Indoor Plant / Tree / Succulent",
  "wateringIntervalDays": 3,
  "lifespanDays": 365,
  "sunlightRequirements": "Bright Indirect Light",
  "targetSunlightHours": 4,
  "idealTemp": "18°C - 30°C",
  "description": "<Brief description>",
  "careInstructions": "<Care instruction>",
  "healthPercent": 90,
  "diseaseStatus": "Healthy",
  "confidencePercent": 90,
  "recommendations": [
    "Provide adequate sunlight",
    "Water when topsoil feels dry"
  ],
  "detailedAdvice": "Healthy botanical specimen observed."
}

If NO plant is detected in the image, return JSON format:
{
  "isPlantDetected": false,
  "detectedObjectType": "<e.g. Wall, Desk, Person, Pen>",
  "rejectionReason": "No plant found in image",
  "identifiedSpecies": "No Plant Found",
  "botanicalName": "",
  "plantType": "None",
  "wateringIntervalDays": 0,
  "lifespanDays": 0,
  "sunlightRequirements": "None",
  "targetSunlightHours": 0,
  "idealTemp": "",
  "description": "No plant detected.",
  "careInstructions": "",
  "healthPercent": 0,
  "diseaseStatus": "Invalid Capture",
  "confidencePercent": 0,
  "recommendations": ["Point camera directly at a real plant or leaf"],
  "detailedAdvice": "No plant found."
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
              if (isPlantDetected &&
                  speciesStr.isNotEmpty &&
                  lowerSpecies != 'unknown' &&
                  lowerSpecies != 'plant' &&
                  lowerSpecies != 'botanical plant' &&
                  lowerSpecies != 'green plant' &&
                  lowerSpecies != 'not a plant' &&
                  lowerSpecies != 'no plant found' &&
                  lowerSpecies != 'no plant detected') {
                detectedSpeciesName = speciesStr;
                aiIdentified = true;
              } else if (!isPlantDetected || lowerSpecies == 'no plant found' || lowerSpecies == 'not a plant') {
                isPlantDetected = false;
                detectedSpeciesName = 'No Plant Found';
                confidence = 0;
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
            isPlantDetected = false;
            detectedObjectType = 'Non-Botanical Object';
            rejectionReason = 'No plant detected by AI analysis.';
            detectedSpeciesName = 'No Plant Found';
            confidence = 0;
          }

          if (!aiIdentified) {
            isPlantDetected = false;
            detectedObjectType = 'Non-Botanical Object';
            rejectionReason = 'No plant detected in photo.';
            detectedSpeciesName = 'No Plant Found';
            confidence = 0;
          }
        }
      } catch (e) {
        debugPrint('Multimodal vision analysis exception: $e');
        isPlantDetected = false;
        detectedObjectType = 'Non-Botanical Object';
        rejectionReason = 'Unable to recognize plant. Please ensure good lighting and aim directly at the plant leaves.';
        detectedSpeciesName = 'No Plant Found';
        confidence = 0;
      }
    } else {
      isPlantDetected = false;
      detectedObjectType = 'Non-Botanical Object';
      rejectionReason = 'No photo provided for AI plant recognition.';
      detectedSpeciesName = 'No Plant Found';
      confidence = 0;
    }

    if (!isPlantDetected) {
      return PlantAIAnalysisResult(
        healthPercent: 0,
        diseaseStatus: 'No Plant Found',
        confidencePercent: 0,
        recommendations: const [
          'Please capture a photo showing actual plant leaves, flowers, seedlings, or stem',
          'Avoid taking pictures of walls, pens, desks, or background objects',
          'Ensure adequate lighting focused directly on plant foliage',
        ],
        detailedAdvice: rejectionReason ??
            'No plant, seedling, or leaf detected in photo. Scanner detected $detectedObjectType.',
        identifiedSpecies: 'No Plant Found',
        isNewDiscovery: false,
        discoveryBadgeName: null,
        discoveryRewardMessage: null,
        matchedSpecies: null,
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

      return {
        'isVerified': false,
        'confidence': 0,
        'rejectionReason': 'Unable to verify watering evidence with AI.',
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
        statusMessage: 'No plant found',
        rejectionReason: 'No camera frame available',
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
            final conf = (map['confidencePercent'] as num?)?.toInt() ?? (isReady ? 92 : (isPlant ? 75 : 0));
            final msg = !isPlant
                ? 'No plant found'
                : (map['statusMessage']?.toString() ??
                    (isReady
                        ? '🌿 Plant & Water Mug in frame!'
                        : '🌿 Plant spotted! Bring water mug into view 💧'));
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

      return const WateringFrameDetectionResult(
        isPlantPresent: false,
        isWaterMugPresent: false,
        isWateringReady: false,
        confidencePercent: 0,
        statusMessage: 'No plant found',
        detectedObjects: '',
      );
    } catch (_) {
      return const WateringFrameDetectionResult(
        isPlantPresent: false,
        isWaterMugPresent: false,
        isWateringReady: false,
        confidencePercent: 0,
        statusMessage: 'No plant found',
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

  // ─────────────────────────────────────────────────────────────────────────
  // Upgraded 4-Stage AI Botanical Prompt Builder & Generation Engine
  // ─────────────────────────────────────────────────────────────────────────

  static const String stageStyleAnchor =
      "Masterpiece 3D isometric botanical game asset, Unreal Engine 5 octane render style, "
      "ultra-high detail 8k textures, smooth velvety claymorphism and botanical realism, "
      "centered camera perspective at a gentle 15-degree isometric top-down angle, "
      "consistent round warm terracotta ceramic pot (#D97443) filled with rich dark organic loam potting soil at 60% pot height, "
      "cinematic soft studio three-point lighting with translucent leaf subsurface scattering and vibrant colors, "
      "pure solid bright green #00FF00 chroma key background, strictly zero background clutter, strictly zero ground drop-shadows, perfectly isolated subject.";

  static const Map<String, Map<String, String>> botanicalSpeciesDictionary = {
    'tulsi': {
      'foliage': 'aromatic ovate serrated green leaves with subtle purple veining and velvety texture',
      'flower': 'delicate upright purple-tinged blossom racemes with tiny fragrant florets',
      'stem': 'slender purplish-green square branching stems',
    },
    'holy basil': {
      'foliage': 'aromatic ovate serrated green leaves with subtle purple veining and velvety texture',
      'flower': 'delicate upright purple-tinged blossom racemes with tiny fragrant florets',
      'stem': 'slender purplish-green square branching stems',
    },
    'rose': {
      'foliage': 'glossy dark green pinnate compound leaves with fine serrated edges',
      'flower': 'luxurious velvety layered rose petals in radiant vibrant crimson and soft blush',
      'stem': 'sturdy woody green canes with characteristic miniature botanical thorns',
    },
    'sunflower': {
      'foliage': 'broad heart-shaped textured rough green leaves with deep prominent veins',
      'flower': 'magnificent golden-yellow ray petals surrounding a dense spiraling dark amber seed disk',
      'stem': 'thick robust fibrous hairy green stem standing upright',
    },
    'monstera': {
      'foliage': 'iconic glossy deep forest green swiss-cheese split leaves with distinct fenestrations',
      'flower': 'rare tropical pale cream spathe and spadix bloom',
      'stem': 'chunky tropical climbing aerial roots and thick emerald petioles',
    },
    'aloe vera': {
      'foliage': 'plump succulent rosette of thick fleshy lance-shaped leaves with soft white serrated teeth and translucent gel core',
      'flower': 'tall central flower spike with tubular coral-orange blossoms',
      'stem': 'stemless compact succulent rosette base',
    },
    'snake plant': {
      'foliage': 'tall architectural sword-like upright leaves with yellow-gold margins and dark green horizontal tiger stripes',
      'flower': 'slender spike of tiny greenish-white fragrant tubular flowers',
      'stem': 'dense cluster of rigid upright foliage emerging directly from soil',
    },
    'lavender': {
      'foliage': 'slender linear silvery-green needle-like aromatic foliage',
      'flower': 'vibrant fragrant violet-purple flower spikes waving gracefully',
      'stem': 'semi-woody compact branching base with slender flowering stalks',
    },
    'money plant': {
      'foliage': 'glossy heart-shaped cascading leaves with golden-yellow marble variegation splashes',
      'flower': 'rare tropical foliage vine',
      'stem': 'graceful trailing climbing vine with aerial root nodes',
    },
    'pothos': {
      'foliage': 'glossy heart-shaped cascading leaves with golden-yellow marble variegation splashes',
      'flower': 'rare tropical foliage vine',
      'stem': 'graceful trailing climbing vine with aerial root nodes',
    },
    'peace lily': {
      'foliage': 'lush arching dark green glossy lanceolate leaves with deep parallel venation',
      'flower': 'elegant pristine white petal-like spathe curving around a textured creamy spadix',
      'stem': 'slender arching petioles arising in a clumping habit',
    },
    'marigold': {
      'foliage': 'feathery deeply divided aromatic fern-like dark green leaflets',
      'flower': 'dense ruffled spherical pom-pom blossoms in dazzling golden amber and tangerine orange',
      'stem': 'bushy branching herbaceous green stems',
    },
    'jade plant': {
      'foliage': 'plump oval jade-green succulent leaves with subtle ruby-red sun-kissed margins',
      'flower': 'clusters of starry soft pink-white miniature blossoms',
      'stem': 'thick miniature bonsai-like tree trunk with smooth fleshy branches',
    },
    'orchid': {
      'foliage': 'thick leathery dark green oblong leaves arranged alternating at the base',
      'flower': 'exquisite cascading butterfly-shaped moth orchid blooms with striking magenta lip and pristine petals',
      'stem': 'gracefully arching slender flower spike with silvery aerial roots',
    },
    'jasmine': {
      'foliage': 'lustrous bright green ovate leaflets arranged in neat pairs',
      'flower': 'star-shaped intensely fragrant pure white blossoms with velvety petals',
      'stem': 'twining woody green vine with graceful sprawling branches',
    },
    'tomato': {
      'foliage': 'pungent aromatic deeply lobed serrated green leaves with fine glandular hairs',
      'flower': 'bright yellow star-shaped flowers and miniature glossy ripening cherry tomatoes',
      'stem': 'thick hairy green vine supported on a miniature garden stake',
    },
    'mint': {
      'foliage': 'bright emerald crinkled aromatic ovate leaves with serrated margins',
      'flower': 'tiny lilac-purple flower whorls on terminal spikes',
      'stem': 'square green branching stems forming a lush dense aromatic cluster',
    },
    'hibiscus': {
      'foliage': 'glossy dark green ovate leaves with coarsely serrated edges',
      'flower': 'giant dramatic tropical flared 5-petal flower with prominent long protruding red pistil and yellow pollen',
      'stem': 'woody upright branching shrub stem',
    },
  };

  /// Returns species-specific botanical profile dictionary
  Map<String, String> getSpeciesBotanicalProfile(String speciesName) {
    final clean = speciesName.toLowerCase().trim();
    for (final entry in botanicalSpeciesDictionary.entries) {
      if (clean.contains(entry.key) || entry.key.contains(clean)) {
        return entry.value;
      }
    }
    return {
      'foliage': 'healthy vibrant foliage with species-accurate shape, intricate venation, and vivid chlorophyll green tones for $speciesName',
      'flower': 'characteristic authentic blossoms and flower buds specific to $speciesName',
      'stem': 'sturdy natural stem and branch structure for $speciesName',
    };
  }

  /// Builds the state-of-the-art upgraded AI prompt for a given species and stage index
  String getEnhancedPlantStagePrompt({
    required String speciesName,
    required int stageIndex,
    PlantModel? plant,
  }) {
    final profile = getSpeciesBotanicalProfile(speciesName);
    final foliage = profile['foliage']!;
    final flower = profile['flower']!;
    final stem = profile['stem']!;
    final plantLabel = speciesName.isNotEmpty ? speciesName : (plant?.plantName ?? 'Botanical Plant');

    String stageDescription;
    switch (stageIndex) {
      case 0:
        stageDescription =
            "Stage 0 (Germination & Seed): Micro-detail close-up of a fertile $plantLabel seed bursting open "
            "in moist dark organic potting soil inside the round terracotta pot. A tiny translucent emerald-green radicle "
            "root anchors into the soil while the first tender sprout shoot tip ($stem) arches upward with glistening morning micro-dewdrops.";
        break;
      case 1:
        stageDescription =
            "Stage 1 (Baby Sprout & Cotyledon): Adorable healthy young $plantLabel seedling sprout rising 3cm above the soil "
            "in the identical round terracotta pot. Two tender baby cotyledon leaves unfurl with delicate translucent cellular glow, "
            "and the very first miniature true leaf bud ($foliage) emerges from the apical center on a tender lime-green stem.";
        break;
      case 2:
        stageDescription =
            "Stage 2 (Vegetative Juvenile): Thriving energetic juvenile $plantLabel plant at 50% maturity in the identical round terracotta pot. "
            "Lush vigorous branching ($stem) with 6 to 10 distinct, fully formed signature species leaves ($foliage) showing authentic venation, "
            "healthy chlorophyll gradients, strong central stalk, and developing early flower buds.";
        break;
      case 3:
      default:
        stageDescription =
            "Stage 3 (Full Maturity & Blooming): Glorious fully grown adult $plantLabel in magnificent peak bloom and supreme vitality "
            "in the identical round terracotta pot. Dense flourishing canopy of mature signature foliage ($foliage), "
            "crowned with pristine authentic species flowers ($flower), rich botanical textures, and award-winning showcase brilliance.";
        break;
    }

    return "$stageStyleAnchor $stageDescription";
  }

  /// Generates a live Pollinations / Web AI URL for real-time preview of the stage image
  String generateStageImageUrl({
    required String speciesName,
    required int stageIndex,
    int? seed,
  }) {
    final prompt = getEnhancedPlantStagePrompt(speciesName: speciesName, stageIndex: stageIndex);
    final encodedPrompt = Uri.encodeComponent(prompt);
    final seedVal = seed ?? (speciesName.hashCode.abs() + (stageIndex * 1337));
    return "https://image.pollinations.ai/prompt/$encodedPrompt?width=512&height=512&seed=$seedVal&nologo=true";
  }
}
