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
import 'auth_service.dart';
import 'user_service.dart';
import 'plant_repository.dart';

/// Structured AI Plant Diagnostic Analysis Result
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

/// Flora AI Service
/// Provides intelligent botanical care advice, leaf photo diagnostics, and interactive Q&A.
/// Connects to Google Gemini API with seamless multi-model fallback and an offline expert botanical engine.
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

  /// Performs deep multimodal image & botanical diagnostic analysis of a captured plant photo,
  /// cross-referencing against the species database and rewarding new discoveries.
  Future<PlantAIAnalysisResult> analyzePlantPhoto({
    required PlantModel plant,
    String? photoPath,
  }) async {
    final healthReport = PlantHealthEngine.evaluate(plant: plant);
    await _excelService.loadSpeciesDatabase();

    String detectedSpeciesName = plant.speciesName;
    int health = healthReport.overallHealth;
    String disease = healthReport.overallHealth >= 80 ? 'None' : 'Needs Care';
    int confidence = 96 + (plant.hydrationScore % 4);
    List<String> recommendations = healthReport.recommendations;
    String advice = 'Plant is growing in optimal condition!';

    bool isPlantDetected = true;
    String? rejectionReason;
    String detectedObjectType = 'Plant / Leaf';

    bool aiIdentified = false;

    // Multimodal AI Vision Diagnosis with Gemini
    if ((apiKey.isNotEmpty || ApiConfig.usesBackendProxy) && photoPath != null && photoPath.isNotEmpty) {
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
          // Tier 1: Specialized Hugging Face Computer Vision Classification if configured
          if (rawBytes != null && ApiConfig.huggingFaceApiKey.isNotEmpty) {
            final hfResult = await _callHuggingFaceVisionApi(rawBytes);
            if (hfResult != null && hfResult['label'] != null) {
              detectedSpeciesName = hfResult['label'].toString();
              confidence = (hfResult['confidence'] as int?) ?? confidence;
              aiIdentified = true;
            }
          }

          final prompt = '''
You are an expert AI computer vision botanist and plant pathologist.
Analyze this photo carefully.

CRITICAL PLANT VERIFICATION REQUIREMENT:
You MUST verify if this image contains a real plant, leaf, seedling, sprout, tree, flower, or botanical foliage.
If the photo shows non-botanical items such as a wall, pen, notebook, desk, room background, vehicle, human face/body, electronic device, clothing, or plain surface with NO clear plant/leaf/seedling present, you MUST set "isPlantDetected" to false and describe the non-plant object in "detectedObjectType" (e.g. "Wall", "Pen", "Furniture", "Person", "Room Interior").

Plant reported name: "${plant.plantName}", Species: "${plant.speciesName}".

Return a JSON object in this exact format:
{
  "isPlantDetected": true or false,
  "detectedObjectType": "<'Plant / Leaf' if plant/seedling/leaf detected, or specific non-plant object name like 'Wall', 'Pen', 'Furniture', 'Person', 'Desk'>",
  "rejectionReason": "<If isPlantDetected is false, provide concise user message e.g. 'No plant or leaf detected in photo. Scanner detected a wall/pen/object instead.' Otherwise null>",
  "identifiedSpecies": "<Common English botanical name if plant, e.g. 'Tulsi', 'Money Plant', 'Calathea', 'Fiddle Leaf Fig'>",
  "healthPercent": <integer 0-100>,
  "diseaseStatus": "<'Healthy', 'None', or specific condition name like 'Leaf Spot' or 'Chlorosis'>",
  "confidencePercent": <integer 85-99>,
  "recommendations": [
    "<recommendation 1>",
    "<recommendation 2>",
    "<recommendation 3>",
    "<recommendation 4>"
  ],
  "detailedAdvice": "<concise friendly botanical guidance for the gardener>"
}
Do not wrap in markdown quotes. Return pure JSON only.
''';

          String? visionResponse = await _callGeminiVisionApi(
            prompt: prompt,
            base64Image: base64Image,
            preferredApiKey: ApiConfig.geminiApiKey1,
          );

          // Tier 3: Groq Failover AI Reasoning Provider if Gemini is unavailable
          if ((visionResponse == null || visionResponse.isEmpty) && ApiConfig.groqApiKey.isNotEmpty) {
            visionResponse = await _callGroqApi(prompt);
          }

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

              if (map['identifiedSpecies'] != null &&
                  map['identifiedSpecies'].toString().trim().isNotEmpty &&
                  map['identifiedSpecies'].toString().trim().toLowerCase() != 'unknown' &&
                  map['identifiedSpecies'].toString().trim().toLowerCase() != 'plant') {
                detectedSpeciesName =
                    map['identifiedSpecies'].toString().trim();
                aiIdentified = true;
              }
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
            detectedObjectType = 'Problem on SpryFlora feature';
            rejectionReason =
                'There is a problem on the SpryFlora plant recognition feature. Unable to recognize plant. Please try again.';
            detectedSpeciesName = 'Problem on SpryFlora feature';
            confidence = 0;
          }

          if (!aiIdentified && isPlantDetected && rawBytes != null) {
            final offlineValid = _isBotanicalImageBytes(rawBytes);
            if (!offlineValid) {
              isPlantDetected = false;
              detectedObjectType = 'Wall / Non-Botanical Object';
              rejectionReason =
                  'No plant, leaf, or seedling detected in photo. Please scan a clear image of a plant.';
            } else {
              isPlantDetected = false;
              detectedObjectType = 'Problem on SpryFlora feature';
              rejectionReason =
                  'There is a problem on the SpryFlora plant recognition feature. Unable to identify species.';
              detectedSpeciesName = 'Problem on SpryFlora feature';
              confidence = 0;
            }
          }
        }
      } catch (e) {
        debugPrint('Multimodal vision analysis failed: $e');
        isPlantDetected = false;
        detectedObjectType = 'Problem on SpryFlora feature';
        rejectionReason =
            'There is a problem on the SpryFlora plant recognition feature: ${e.toString().replaceAll('Exception: ', '')}';
        detectedSpeciesName = 'Problem on SpryFlora feature';
        confidence = 0;
      }
    } else if (photoPath != null && photoPath.isNotEmpty && !kIsWeb && File(photoPath).existsSync()) {
      try {
        final rawBytes = await File(photoPath).readAsBytes();
        final offlineValid = _isBotanicalImageBytes(rawBytes);
        if (!offlineValid) {
          isPlantDetected = false;
          detectedObjectType = 'Wall / Non-Botanical Object';
          rejectionReason =
              'No plant, leaf, or seedling detected in photo. Scanner detected a wall, pen, or plain surface.';
        } else {
          isPlantDetected = false;
          detectedObjectType = 'Problem on SpryFlora feature';
          rejectionReason =
              'There is a problem on the SpryFlora plant recognition feature. Offline AI vision service unavailable.';
          detectedSpeciesName = 'Problem on SpryFlora feature';
          confidence = 0;
        }
      } catch (_) {}
    }

    if (!isPlantDetected) {
      final isFeatureIssue = detectedObjectType.contains('SpryFlora') ||
          (rejectionReason?.contains('SpryFlora') ?? false);
      return PlantAIAnalysisResult(
        healthPercent: 0,
        diseaseStatus: isFeatureIssue ? 'Feature Issue' : 'Invalid Capture',
        confidencePercent: 0,
        recommendations: isFeatureIssue
            ? [
                'There is a problem on the SpryFlora plant recognition feature',
                'Please check your internet connection and try again',
                'Or choose your plant species directly from the botanical catalog',
              ]
            : [
                'Please capture a photo showing actual plant leaves, seedlings, or stem',
                'Avoid taking pictures of walls, pens, desks, or background objects',
                'Ensure adequate lighting focused directly on plant foliage',
              ],
        detailedAdvice: rejectionReason ??
            (isFeatureIssue
                ? 'There is a problem on the SpryFlora plant recognition feature. Please try again.'
                : 'No plant, seedling, or leaf detected in photo. Scanner detected $detectedObjectType.'),
        identifiedSpecies: isFeatureIssue
            ? 'Problem on SpryFlora feature'
            : 'Not a Plant ($detectedObjectType)',
        isNewDiscovery: false,
        discoveryBadgeName: null,
        discoveryRewardMessage: null,
        isPlantDetected: false,
        rejectionReason: rejectionReason ??
            (isFeatureIssue
                ? 'There is a problem on the SpryFlora plant recognition feature.'
                : 'No plant, seedling, or leaf detected in photo. Detected: $detectedObjectType'),
        detectedObjectType: detectedObjectType,
      );
    }

    if (recommendations.isEmpty) {
      recommendations = [
        plant.isWateringDue
            ? 'Water today with room-temperature water'
            : 'Water in ${plant.daysUntilWatering} day${plant.daysUntilWatering > 1 ? 's' : ''}',
        'Maintain ${plant.targetSunlightHours} hours of bright indirect sunlight daily',
        health >= 80
            ? 'No active pest or leaf disease detected'
            : 'Ensure proper pot drainage and gentle airflow',
        'Plant is progressing well in ${plant.growthStageName} stage',
      ];
    }

    // ── Cross-reference with local Plant Species Database ──
    PlantSpecies dbMatch = _excelService.matchSpeciesFromAIPrediction(
      detectedSpeciesName,
      detectedObjectType: detectedObjectType,
    );

    if (dbMatch.name.isNotEmpty && dbMatch.name.toLowerCase() != 'unknown') {
      detectedSpeciesName = dbMatch.name;
    }

    final bool isKnownBase = _excelService.speciesList.any(
      (s) => s.name.toLowerCase() == detectedSpeciesName.toLowerCase(),
    );
    final bool isNewDiscovery = !isKnownBase && isPlantDetected;
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
      detectedObjectType: 'Plant / Leaf',
    );
  }

  /// Generates personalized daily growth stage care guidance (Segment 1 AI Feature -> Key 1)
  Future<String> getStageCareGuidance(PlantModel plant) async {
    final healthReport = PlantHealthEngine.evaluate(plant: plant);

    if (apiKey.isNotEmpty || ApiConfig.usesBackendProxy) {
      try {
        final prompt = '''
You are Flora AI, a friendly botanical expert mentor for children and plant lovers in the SPR Flora virtual plant care app.
The user is caring for a plant:
- Name: "${plant.plantName}"
- Species: "${plant.speciesName}"
- Age: ${plant.ageInDays} days (Lifespan: ${plant.lifespanDays} days)
- Growth Stage: ${plant.growthStageName} (${(plant.growthProgress * 100).toInt()}%)
- Overall Health: ${plant.health}% (${healthReport.status})
- Hydration: ${plant.hydrationScore}%, Sunlight: ${plant.sunlightScore}%
- Location: ${plant.location}

Write a short, engaging, 2-3 sentence personalized botanical guidance tip for today. Focus on what this plant needs in its current "${plant.growthStageName}" stage. Include an emoji. Do not use markdown headers.
''';

        final response = await _callGeminiApi(
          prompt: prompt,
          preferredApiKey: ApiConfig.geminiApiKey1,
        );
        if (response != null && response.isNotEmpty) {
          return response.trim();
        }
      } catch (e) {
        debugPrint('Gemini API call failed, falling back to expert engine: $e');
      }
    }

    // Offline Botanical Expert Rule Engine Fallback
    return _generateOfflineStageGuidance(plant, healthReport);
  }

  /// Analyzes Daily Check-in photo & environmental inputs (Segment 2 AI Feature -> Key 2)
  Future<String> analyzeCheckinAndPhoto({
    required PlantModel plant,
    required bool watered,
    required int sunlightHours,
    required String environmentCondition,
    String? photoPath,
  }) async {
    if (apiKey.isNotEmpty || ApiConfig.usesBackendProxy) {
      try {
        final prompt = '''
You are Flora AI, a virtual plant doctor in SPR Flora app.
The user just completed a daily check-in for "${plant.plantName}" (${plant.speciesName}):
- Plant Stage: ${plant.growthStageName}
- Watered today: ${watered ? "YES" : "NO"}
- Sunlight logged: $sunlightHours hours in "$environmentCondition" condition
- Target Sunlight: ${plant.targetSunlightHours} hours
- Next watering interval: every ${plant.wateringIntervalDays} days
- Has photo: ${photoPath != null ? "Yes" : "No"}

Provide a concise 2-sentence diagnostic assessment of today's care. Praise good care, or gently advise on sunlight/watering balance. Include emojis.
''';

        final response = await _callGeminiApi(
          prompt: prompt,
          preferredApiKey: ApiConfig.geminiApiKey2,
        );
        if (response != null && response.isNotEmpty) {
          return response.trim();
        }
      } catch (e) {
        debugPrint('Gemini checkin analysis failed: $e');
      }
    }

    // Offline Diagnostic Analysis
    return _generateOfflineCheckinDiagnosis(
      plant: plant,
      watered: watered,
      sunlightHours: sunlightHours,
      environmentCondition: environmentCondition,
    );
  }

  /// Interactive Q&A with Flora AI Plant Doctor (Segment 2 AI Feature -> Key 2)
  /// Interactive Q&A with Flora AI Plant Doctor (Segment 2 AI Feature -> Key 2)
  /// Strictly references user specific profile data and logged database records.
  Future<String> askFloraAI({
    PlantModel? plant,
    required String userQuestion,
    List<DailyCheckinModel> history = const [],
  }) async {
    final activePlant = plant ??
        (PlantRepository().plants.isNotEmpty
            ? PlantRepository().plants.first
            : PlantModel(
                id: 'default_companion',
                plantName: 'My Plant Buddy',
                speciesName: 'Tulsi',
                plantingDate: DateTime.now().subtract(const Duration(days: 7)),
                lifespanDays: 120,
                wateringIntervalDays: 3,
              ));
    final healthReport = PlantHealthEngine.evaluate(plant: activePlant, checkins: history);

    // User-specific database records & profile context
    final userProfile = UserService().currentUser;
    final allUserPlants = PlantRepository().plants;
    final userPlantListContext = allUserPlants.isNotEmpty
        ? allUserPlants
            .map((p) =>
                '- "${p.plantName}" (${p.speciesName}): Health ${p.health}%, Hydration ${p.hydrationScore}%, Sunlight ${p.sunlightScore}%, Growth Stage "${p.growthStageName}", Days Until Water: ${p.daysUntilWatering}, Last Watered: ${p.lastWateredDate.toIso8601String().split('T')[0]}')
            .join('\n')
        : '- "${activePlant.plantName}" (${activePlant.speciesName}): Health ${activePlant.health}%';

    if (apiKey.isNotEmpty || ApiConfig.usesBackendProxy) {
      try {
        final prompt = '''
You are Flora AI, a warm, knowledgeable, and encouraging virtual plant doctor inside the SpryFlora app.

CRITICAL MANDATE:
You MUST answer strictly using the data of THIS PARTICULAR USER and their specific database records.
Do NOT provide generic or global answers unrelated to this user when asked about their plants, status, or progress.

User Specific Profile Data:
- User Name: "${userProfile?.childName ?? 'Young Gardener'}"
- Care Streak: ${userProfile?.careStreakDays ?? 0} days
- Eco XP / Level: ${userProfile?.xp ?? 0} XP
- Favorite Plant: "${userProfile?.favoritePlant ?? activePlant.plantName}"
- Total Completed Plants: ${userProfile?.completedPlantsCount ?? 0}

User's Logged Database Plants (${allUserPlants.length} total):
$userPlantListContext

Active Selected Plant Context:
- Name: "${activePlant.plantName}" (${activePlant.speciesName})
- Age: ${activePlant.ageInDays} days, Stage: ${activePlant.growthStageName}
- Health: ${healthReport.overallHealth}% (${healthReport.status})
- Hydration: ${healthReport.hydrationScore}%, Sunlight: ${healthReport.sunlightScore}%
- Location: ${activePlant.location}

User Question: "$userQuestion"

Answer the user directly in 2-4 friendly, educational sentences using their specific name, specific plant names, and database statistics.
If the question is in Tamil (தமிழ்) or Tanglish, reply in kid-friendly Tamil/Tanglish with English keywords. Include emojis! Keep it upbeat, user-specific, and highly encouraging.
''';

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

    // Offline Botanical Q&A Reasoning Engine
    return _generateOfflineQnAResponse(activePlant, userQuestion, healthReport);
  }

  /// REST call to Gemini Generative Language API with segmented key routing & automatic failover
  Future<String?> _callGeminiApi({
    required String prompt,
    String? preferredApiKey,
  }) async {
    if (ApiConfig.usesBackendProxy) {
      try {
        final uri = Uri.parse('${ApiConfig.aiBackendUrl}${ApiConfig.backendBuddyEndpoint}');
        final response = await http.post(
          uri,
          headers: AuthService().getAuthorizationHeaders(),
          body: jsonEncode({'prompt': prompt}),
        ).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['result'] != null) return data['result'].toString();
          if (data['text'] != null) return data['text'].toString();
        }
      } catch (e) {
        debugPrint('Backend proxy AI call failed: $e');
      }
    }

    final primaryKey = preferredApiKey ?? ApiConfig.geminiApiKey1;
    final fallbackKey = primaryKey == ApiConfig.geminiApiKey1
        ? ApiConfig.geminiApiKey2
        : ApiConfig.geminiApiKey1;

    final keysToTry = [
      primaryKey,
      if (fallbackKey.isNotEmpty && fallbackKey != primaryKey) fallbackKey,
    ];

    final modelsToTry = [
      ApiConfig.primaryModel,
      ApiConfig.secondaryModel,
      'gemini-3.6-flash',
      'gemini-flash-latest',
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
              'thinkingConfig': {
                'thinkingBudget': 0,
              },
            }
          });

          final response = await http
              .post(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 8));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
            if (text != null && text.isNotEmpty) {
              return text;
            }
          } else {
            debugPrint('Model $model with key returned status ${response.statusCode}, trying fallback...');
          }
        } catch (e) {
          debugPrint('Model $model invocation error: $e');
        }
      }
    }

    return null;
  }

  /// Multimodal Vision REST call to Gemini with base64 image inlineData, key segmentation & failover
  Future<String?> _callGeminiVisionApi({
    required String prompt,
    required String base64Image,
    String? preferredApiKey,
  }) async {
    if (ApiConfig.usesBackendProxy) {
      try {
        final uri = Uri.parse('${ApiConfig.aiBackendUrl}${ApiConfig.backendAnalysisEndpoint}');
        final response = await http.post(
          uri,
          headers: AuthService().getAuthorizationHeaders(),
          body: jsonEncode({'prompt': prompt, 'image': base64Image}),
        ).timeout(const Duration(seconds: 4));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['result'] != null) return data['result'].toString();
          if (data['text'] != null) return data['text'].toString();
          if (data is Map && data.containsKey('isPlantDetected')) {
            return response.body;
          }
        }
      } catch (e) {
        debugPrint('Backend proxy vision AI call failed: $e');
      }
    }

    final primaryKey = preferredApiKey ?? ApiConfig.geminiApiKey1;
    final fallbackKey = primaryKey == ApiConfig.geminiApiKey1
        ? ApiConfig.geminiApiKey2
        : ApiConfig.geminiApiKey1;

    final keysToTry = [
      primaryKey,
      if (fallbackKey.isNotEmpty && fallbackKey != primaryKey) fallbackKey,
    ];

    final modelsToTry = [
      ApiConfig.primaryModel,
      ApiConfig.secondaryModel,
      'gemini-3.6-flash',
      'gemini-flash-latest',
    ];

    final mimeType = (base64Image.startsWith('iVBOR') || base64Image.startsWith('data:image/png'))
        ? 'image/png'
        : 'image/jpeg';

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
                      'data': base64Image,
                    }
                  }
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.2,
              'maxOutputTokens': 2048,
              'thinkingConfig': {
                'thinkingBudget': 0,
              },
            }
          });

          final response = await http
              .post(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
            if (text != null && text.isNotEmpty) {
              return text;
            }
          } else {
            debugPrint('Vision Model $model returned status ${response.statusCode}, trying fallback...');
          }
        } catch (e) {
          debugPrint('Vision Model $model invocation error: $e');
        }
      }
    }

    return null;
  }

  /// Offline Rule-Based Botanical Guidance Engine
  String _generateOfflineStageGuidance(PlantModel plant, PlantHealthReport health) {
    final species = plant.speciesName.toLowerCase();
    final stage = plant.growthStageName;

    if (stage == 'Seed') {
      return '🌱 Your ${plant.plantName} is germinating! Keep the soil damp like a wrung-out sponge and place it in warm indirect light.';
    } else if (stage == 'Sprout') {
      if (species.contains('rose') || species.contains('tulsi')) {
        return '🌿 Delicate first leaves are unfolding! Ensure 4-5 hours of morning sunlight so stems grow strong and upright.';
      } else if (species.contains('aloe') || species.contains('snake') || species.contains('jade')) {
        return '🌿 Baby succulent shoots are forming! Allow topsoil to dry slightly between waterings to prevent root damping.';
      } else {
        return '🌿 Tender green shoots are emerging! Maintain steady ambient warmth and gentle morning light exposure.';
      }
    } else if (stage == 'Growing Plant') {
      if (health.sunlightScore < 60) {
        return '☀️ ${plant.plantName} is growing actively, but needs more sunshine (${plant.targetSunlightHours}h daily target) for vibrant photosynthesis!';
      } else if (health.hydrationScore < 60) {
        return '💧 Active foliage growth requires consistent hydration. Check soil moisture and give it a refreshing drink!';
      } else {
        return '🌿 Thriving vegetative phase! Rotate the pot once a week so all leaves absorb uniform sunlight and grow symmetrically.';
      }
    } else {
      // Fully Grown
      return '🌸 Master gardener achievement! Your ${plant.plantName} has completed its full growth journey in peak health. Claim your certificate in the achievements screen!';
    }
  }

  /// Offline Check-in Diagnostic Generator
  String _generateOfflineCheckinDiagnosis({
    required PlantModel plant,
    required bool watered,
    required int sunlightHours,
    required String environmentCondition,
  }) {
    final target = plant.targetSunlightHours;
    final isSunGood = sunlightHours >= (target * 0.75);

    if (watered && isSunGood) {
      return '✨ Excellent care! Both hydration and photoperiod targets met today. ${plant.plantName} is in high-vitality mode!';
    } else if (watered && !isSunGood) {
      return '💧 Hydration recorded successfully! Consider giving ${plant.plantName} a bit more bright light ($target hrs recommended) tomorrow.';
    } else if (!watered && isSunGood) {
      return '☀️ Great sunshine logged ($sunlightHours hrs)! Soil moisture is holding steady for the current watering interval.';
    } else {
      return '🌿 Daily check-in logged! Remember to keep track of ${plant.plantName}\'s hydration schedule and provide gentle sunlight.';
    }
  }

  /// Offline Q&A Reasoning Engine supporting English, Tamil, and Tanglish queries
  String _generateOfflineQnAResponse(
    PlantModel plant,
    String question,
    PlantHealthReport health,
  ) {
    final q = question.toLowerCase();
    final species = plant.speciesName;

    // Check for Tamil / Tanglish / English watering queries
    if (q.contains('water') ||
        q.contains('drink') ||
        q.contains('dry') ||
        q.contains('தண்ணீர்') ||
        q.contains('thanneer') ||
        q.contains('thanni') ||
        q.contains('ஊற்ற') ||
        q.contains('oothanum')) {
      return '💧 உங்கள் $species செடிக்கு ${plant.wateringIntervalDays} நாட்களுக்கு ஒருமுறை தண்ணீர் ஊற்ற வேண்டும். ($species needs watering every ${plant.wateringIntervalDays} days). Soil dry-ஆனதும் தண்ணீர் ஊற்றுங்கள்! Always ensure good drainage!';
    }
    // Check for sunlight queries
    else if (q.contains('sun') ||
        q.contains('light') ||
        q.contains('dark') ||
        q.contains('window') ||
        q.contains('சூரிய') ||
        q.contains('வெளிச்சம்') ||
        q.contains('வெயில்') ||
        q.contains('velicham') ||
        q.contains('veyil') ||
        q.contains('sunlight')) {
      return '☀️ $species செடிக்கு தினமும் ${plant.targetSunlightHours} மணிநேரம் மிதமான சூரிய வெளிச்சம் தேவை. ($species prefers ${plant.targetSunlightHours}h of daily bright indirect light near a window). Direct scorching sun தவிர்க்கவும்!';
    }
    // Check for yellow leaf queries
    else if (q.contains('yellow') ||
        q.contains('brown') ||
        q.contains('leaf') ||
        q.contains('leaves') ||
        q.contains('மஞ்சள்') ||
        q.contains('இலை') ||
        q.contains('manjal') ||
        q.contains('manjala') ||
        q.contains('ilai')) {
      return '🍃 இலை மஞ்சள் நிறமாக மாறினால் அதிக தண்ணீர் அல்லது நேரடி வெயில் காரணமாக இருக்கலாம். (Yellow leaves are caused by over-watering or scorching sun). Move pot to bright indirect light!';
    }
    // Check for bugs / insect / pest queries
    else if (q.contains('bug') ||
        q.contains('pest') ||
        q.contains('insect') ||
        q.contains('பூச்சி') ||
        q.contains('poochi')) {
      return '🐛 பூச்சிகள் வராமல் தடுக்க வேப்ப எண்ணெய் தெளிக்கலாம் அல்லது சோப்பு நீரால் இலைகளைத் துடைக்கலாம். (Spray diluted neem oil or wipe leaves with mild soapy water to deter insects naturally).';
    }
    // Growth stage queries
    else if (q.contains('grow') ||
        q.contains('stage') ||
        q.contains('fast') ||
        q.contains('tall') ||
        q.contains('வளர') ||
        q.contains('செடி') ||
        q.contains('valarudhu') ||
        q.contains('valara')) {
      return '📈 உங்கள் ${plant.plantName} தற்போது ${(plant.growthProgress * 100).toInt()}% வளர்ந்துள்ளது! (${plant.growthStageName} stage). Daily check-in செய்து தொடர்ந்து பராமரியுங்கள்! 🌱';
    }
    // Health report queries
    else if (q.contains('health') ||
        q.contains('how is') ||
        q.contains('status') ||
        q.contains('சுகாதாரம்') ||
        q.contains('aarokkiyam') ||
        q.contains('aarokkiyama') ||
        q.contains('nalla')) {
      return '🩺 Health Report: Overall ${health.overallHealth}% (${health.status}). Hydration is at ${health.hydrationScore}% and Sunlight is at ${health.sunlightScore}%. செடி நல்ல ஆரோக்கியமாக இருக்கிறது! Keep up the fantastic care! ✨';
    } else {
      return '🌿 Eco Buddy Advice for ${plant.plantName} ($species): ${plant.targetSunlightHours} மணிநேரம் சூரிய ஒளி, ${plant.wateringIntervalDays} நாட்களுக்கு ஒருமுறை தண்ணீர் வழங்கி நன்றாக வளருங்கள்! 🎉';
    }
  }

  /// Verifies user-uploaded photo evidence of watering activity
  Future<Map<String, dynamic>> verifyWateringPhoto({
    required PlantModel plant,
    required String photoPath,
  }) async {
    bool isVerified = false;
    int confidence = 0;
    String message = 'Watering photo verified!';
    String? rejectionReason;

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

      if (rawBytes != null && !_isBotanicalImageBytes(rawBytes)) {
        return {
          'isVerified': false,
          'confidence': 0,
          'message': 'Buddy couldn\'t detect your plant 💧',
          'rejectionReason': 'No plant or watering action detected in photo. Scanner detected a non-botanical object. Please take a photo of your plant and water.',
        };
      }

      if ((apiKey.isNotEmpty || ApiConfig.usesBackendProxy) && base64Image != null && base64Image.isNotEmpty) {
        final prompt = '''
Analyze this real-time camera photo submitted as proof of watering a plant named "${plant.plantName}" (${plant.speciesName}).
Requirements for verification:
1. The image MUST show a plant or foliage.
2. The image MUST show clear evidence of watering:
   - A watering jug, watering can, mug, bottle, cup, sprayer, or watering container, AND/OR
   - Fresh water droplets, water stream, or freshly soaked soil/leaves on the plant.

If the photo shows a dry plant with NO watering container or water droplets, or if it is not a plant, reject it!

Return JSON only:
{
  "isWateringVerified": true,
  "wateringToolDetected": true,
  "waterDropletsDetected": true,
  "confidencePercent": 92,
  "userFeedback": "Watering verified! Watering container or fresh water detected. 💧"
}

If not verified, set isWateringVerified to false and provide userFeedback explaining what is missing (e.g. "Watering jug/can or water on plant not detected. Please capture with your watering tool or fresh water droplets on the plant.").
''';

        final response = await _callGeminiVisionApi(
          prompt: prompt,
          base64Image: base64Image,
          preferredApiKey: ApiConfig.geminiApiKey1,
        );

        if (response != null && response.isNotEmpty) {
          try {
            final cleaned = response.replaceAll('```json', '').replaceAll('```', '').trim();
            final map = jsonDecode(cleaned);
            isVerified = map['isWateringVerified'] == true;
            confidence = (map['confidencePercent'] as num?)?.toInt() ?? 90;
            message = map['userFeedback']?.toString() ?? message;
            if (!isVerified) {
              rejectionReason = message;
            }
          } catch (e) {
            isVerified = false;
            confidence = 0;
            rejectionReason = 'AI verification service encountered a parsing error. Please try again.';
          }
        } else {
          isVerified = false;
          confidence = 0;
          rejectionReason = 'AI verification service unavailable or timed out. Please check network connection.';
        }
      } else {
        isVerified = false;
        confidence = 0;
        rejectionReason = 'AI verification requires an active connection to AI Service.';
      }
    } catch (e) {
      debugPrint('Watering verification error: $e');
      isVerified = false;
      confidence = 0;
      rejectionReason = 'An error occurred while analyzing your watering photo. Please try again.';
    }

    return {
      'isVerified': isVerified,
      'confidence': confidence,
      'message': message,
      'rejectionReason': rejectionReason,
    };
  }

  /// Hugging Face Inference API for specialized vision classification
  Future<Map<String, dynamic>?> _callHuggingFaceVisionApi(List<int> imageBytes) async {
    if (ApiConfig.huggingFaceApiKey.isEmpty) return null;
    try {
      final uri = Uri.parse(ApiConfig.huggingFaceVisionModel);
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${ApiConfig.huggingFaceApiKey}',
          'Content-Type': 'application/octet-stream',
        },
        body: imageBytes,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        if (results.isNotEmpty && results[0] is Map) {
          final top = results[0] as Map<String, dynamic>;
          final label = top['label'] as String? ?? 'Plant';
          final score = (top['score'] as num?)?.toDouble() ?? 0.8;
          return {
            'label': label,
            'confidence': (score * 100).toInt(),
          };
        }
      }
    } catch (e) {
      debugPrint('Hugging Face Vision API error: $e');
    }
    return null;
  }

  /// Groq API for fallback reasoning
  Future<String?> _callGroqApi(String prompt) async {
    if (ApiConfig.groqApiKey.isEmpty) return null;
    try {
      final uri = Uri.parse(ApiConfig.groqApiUrl);
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${ApiConfig.groqApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': ApiConfig.groqModel,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final map = jsonDecode(response.body);
        return map['choices']?[0]?['message']?['content'] as String?;
      }
    } catch (e) {
      debugPrint('Groq API error: $e');
    }
    return null;
  }

  /// Heuristic offline analyzer to verify if photo bytes contain botanical/foliage color characteristics
  /// Rejects plain walls, pens, monochrome backgrounds, or plain office items.
  bool _isBotanicalImageBytes(List<int> bytes) {
    if (bytes.length < 500) return true; // Can't sample very small byte streams

    int totalSamples = 0;
    int botanicalGreenSamples = 0;
    int plainSurfaceSamples = 0;

    // Sample across the image byte stream
    final int step = (bytes.length / 400).floor().clamp(1, 1000);
    for (int i = 0; i < bytes.length - 2; i += step) {
      totalSamples++;
      final b1 = bytes[i];
      final b2 = bytes[i + 1];
      final b3 = bytes[i + 2];

      // Check for plain white / grey / cream wall (high RGB similarity, high brightness)
      final diff1 = (b1 - b2).abs();
      final diff2 = (b2 - b3).abs();
      if (b1 > 140 && b2 > 140 && b3 > 140 && diff1 < 18 && diff2 < 18) {
        plainSurfaceSamples++;
      }

      // Check for green foliage spectrum (Green channel elevated over Red & Blue)
      if (b2 > 40 && b2 > (b1 * 0.85) && b2 > (b3 * 0.85)) {
        botanicalGreenSamples++;
      }
    }

    if (totalSamples == 0) return true;

    final double wallRatio = plainSurfaceSamples / totalSamples;
    final double greenRatio = botanicalGreenSamples / totalSamples;

    // If over 65% of samples are plain wall surface and green foliage ratio is low (< 10%), reject
    if (wallRatio > 0.65 && greenRatio < 0.10) {
      return false;
    }
    // If green/foliage ratio is virtually zero (< 3%) and plain samples > 40%, reject non-plant
    if (greenRatio < 0.03 && plainSurfaceSamples > 0.40 * totalSamples) {
      return false;
    }

    return true;
  }
}

