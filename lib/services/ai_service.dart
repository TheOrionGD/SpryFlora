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

    // Multimodal AI Vision Diagnosis with Gemini
    if (apiKey.isNotEmpty && photoPath != null && photoPath.isNotEmpty) {
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

          final visionResponse = await _callGeminiVisionApi(
            prompt: prompt,
            base64Image: base64Image,
            preferredApiKey: ApiConfig.geminiApiKey1,
          );

          if (visionResponse != null && visionResponse.isNotEmpty) {
            try {
              final cleaned = visionResponse
                  .replaceAll('```json', '')
                  .replaceAll('```', '')
                  .trim();
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
                  map['identifiedSpecies'].toString().trim().isNotEmpty) {
                detectedSpeciesName =
                    map['identifiedSpecies'].toString().trim();
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
              debugPrint('Error parsing Gemini Vision response JSON: $e');
            }
          } else if (rawBytes != null) {
            final offlineValid = _isBotanicalImageBytes(rawBytes);
            if (!offlineValid) {
              isPlantDetected = false;
              detectedObjectType = 'Wall / Non-Botanical Object';
              rejectionReason =
                  'No plant, leaf, or seedling detected in photo. Please scan a clear image of a plant.';
            }
          }
        }
      } catch (e) {
        debugPrint('Multimodal Gemini vision analysis failed: $e');
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
        }
      } catch (_) {}
    }

    if (!isPlantDetected) {
      return PlantAIAnalysisResult(
        healthPercent: 0,
        diseaseStatus: 'Invalid Capture',
        confidencePercent: 0,
        recommendations: [
          'Please capture a photo showing actual plant leaves, seedlings, or stem',
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
        'Maintain ${plant.targetSunlightHours} hours of bright indirect sunlight daily',
        health >= 80
            ? 'No active pest or leaf disease detected'
            : 'Ensure proper pot drainage and gentle airflow',
        'Plant is progressing well in ${plant.growthStageName} stage',
      ];
    }

    // ── Cross-reference with local Plant Species Database ──
    PlantSpecies? dbMatch = _excelService.getSpeciesByName(detectedSpeciesName);
    bool isNewDiscovery = false;
    String? discoveryBadge;
    String? discoveryReward;

    if (dbMatch == null) {
      // New plant species discovered not previously in database!
      isNewDiscovery = true;
      final newSpecies = PlantSpecies(
        name: detectedSpeciesName,
        lifespanDays: 180,
        wateringIntervalDays: 3,
        sunlight: 'Bright Indirect Light',
        targetSunlightHours: 4,
        description: 'Newly discovered botanical species identified by SpryFlora AI.',
      );
      await _excelService.addNewSpecies(newSpecies);
      dbMatch = newSpecies;

      discoveryBadge = '🌱 Botanical Explorer Badge';
      discoveryReward =
          '🎉 Congratulations! You discovered a new species "$detectedSpeciesName" and added it to the SpryFlora catalogue! (+150 Garden Points)';
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

    if (apiKey.isNotEmpty) {
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
    if (apiKey.isNotEmpty) {
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
  Future<String> askFloraAI({
    PlantModel? plant,
    required String userQuestion,
    List<DailyCheckinModel> history = const [],
  }) async {
    final activePlant = plant ??
        PlantModel(
          id: 'default_companion',
          plantName: 'My Plant Buddy',
          speciesName: 'Tulsi',
          plantingDate: DateTime.now().subtract(const Duration(days: 7)),
          lifespanDays: 120,
          wateringIntervalDays: 3,
        );
    final healthReport = PlantHealthEngine.evaluate(plant: activePlant, checkins: history);

    if (apiKey.isNotEmpty) {
      try {
        final prompt = '''
You are Flora AI, a warm, knowledgeable, and encouraging virtual plant doctor inside the SPR Flora app.
Target Audience: Children / Kids caring for virtual & real plants.

Plant context:
- Name: "${activePlant.plantName}" (${activePlant.speciesName})
- Age: ${activePlant.ageInDays} days, Stage: ${activePlant.growthStageName}
- Health: ${healthReport.overallHealth}% (${healthReport.status})
- Hydration: ${healthReport.hydrationScore}%, Sunlight: ${healthReport.sunlightScore}%
- Location: ${activePlant.location}

User Question: "$userQuestion"

Answer the child directly in 2-4 friendly, educational sentences with clear, actionable botanical tips.
If the question is in Tamil (தமிழ்) or Tanglish, reply in kid-friendly Tamil with English keywords (or bilingual English/Tamil) so it is very easy for children to understand. Include emojis! Keep it upbeat and encouraging.
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
              'maxOutputTokens': 250,
            }
          });

          final response = await http
              .post(uri, headers: headers, body: body)
              .timeout(const Duration(seconds: 7));

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
    final primaryKey = preferredApiKey ?? ApiConfig.geminiApiKey1;
    final fallbackKey = primaryKey == ApiConfig.geminiApiKey1
        ? ApiConfig.geminiApiKey2
        : ApiConfig.geminiApiKey1;

    final keysToTry = [
      primaryKey,
      if (fallbackKey.isNotEmpty && fallbackKey != primaryKey) fallbackKey,
    ];

    final modelsToTry = [
      'gemini-flash-latest',
      'gemini-1.5-flash',
      'gemini-2.0-flash',
      'gemini-1.5-pro',
      ApiConfig.primaryModel,
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
                  {'text': prompt},
                  {
                    'inlineData': {
                      'mimeType': 'image/jpeg',
                      'data': base64Image,
                    }
                  }
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.4,
              'maxOutputTokens': 500,
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
        q.contains('ஊற்ற')) {
      return '💧 உங்கள் $species செடிக்கு ${plant.wateringIntervalDays} நாட்களுக்கு ஒருமுறை தண்ணீர் ஊற்ற வேண்டும். ($species needs watering every ${plant.wateringIntervalDays} days). Always make sure soil has good drainage!';
    }
    // Check for sunlight queries
    else if (q.contains('sun') ||
        q.contains('light') ||
        q.contains('dark') ||
        q.contains('window') ||
        q.contains('சூரிய') ||
        q.contains('வெளிச்சம்')) {
      return '☀️ $species செடிக்கு தினமும் ${plant.targetSunlightHours} மணிநேரம் மிதமான சூரிய வெளிச்சம் தேவை. ($species prefers ${plant.targetSunlightHours}h of daily bright light near window).';
    }
    // Check for yellow leaf queries
    else if (q.contains('yellow') ||
        q.contains('brown') ||
        q.contains('leaf') ||
        q.contains('leaves') ||
        q.contains('மஞ்சள்') ||
        q.contains('இலை')) {
      return '🍃 இலை மஞ்சள் நிறமாக மாறினால் அதிக தண்ணீர் அல்லது நேரடி வெயில் காரணமாக இருக்கலாம். (Yellow leaves are caused by over-watering or scorching sun). Move pot to bright indirect light!';
    }
    // Growth stage queries
    else if (q.contains('grow') ||
        q.contains('stage') ||
        q.contains('fast') ||
        q.contains('tall') ||
        q.contains('வளர') ||
        q.contains('செடி')) {
      return '📈 உங்கள் ${plant.plantName} தற்போது ${(plant.growthProgress * 100).toInt()}% வளர்ந்துள்ளது! (${plant.growthStageName} stage). Daily check-in செய்து தொடர்ந்து பராமரியுங்கள்! 🌱';
    }
    // Health report queries
    else if (q.contains('health') ||
        q.contains('how is') ||
        q.contains('status') ||
        q.contains('சுகாதாரம்')) {
      return '🩺 Health Report: Overall ${health.overallHealth}% (${health.status}). Hydration is at ${health.hydrationScore}% and Sunlight is at ${health.sunlightScore}%. Keep up the fantastic care!';
    } else {
      return '🌿 Eco Buddy Advice for ${plant.plantName} ($species): ${plant.targetSunlightHours} மணிநேரம் சூரிய ஒளி, ${plant.wateringIntervalDays} நாட்களுக்கு ஒருமுறை தண்ணீர் வழங்கி நன்றாக வளருங்கள்! 🎉';
    }
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

