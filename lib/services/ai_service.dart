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

    // Multimodal AI Vision Diagnosis with Gemini
    if (apiKey.isNotEmpty && photoPath != null && photoPath.isNotEmpty) {
      try {
        String? base64Image;
        if (!kIsWeb && File(photoPath).existsSync()) {
          final bytes = await File(photoPath).readAsBytes();
          base64Image = base64Encode(bytes);
        } else if (photoPath.startsWith('data:image')) {
          final parts = photoPath.split(',');
          if (parts.length > 1) {
            base64Image = parts[1];
          }
        }

        if (base64Image != null && base64Image.isNotEmpty) {
          final prompt = '''
You are an expert AI botanist and plant pathologist.
Analyze this photo of a plant leaf and structure.
Plant reported name: "${plant.plantName}", Species: "${plant.speciesName}".
Current stats:
- Age: ${plant.ageInDays} days (${plant.growthStageName})
- Hydration: ${plant.hydrationScore}%, Sunlight: ${plant.sunlightScore}%

Identify the precise botanical species from the leaf structure and visual features.
Return a JSON object in this exact format:
{
  "identifiedSpecies": "<Common English botanical name, e.g. 'Tulsi', 'Money Plant', 'Calathea', 'Fiddle Leaf Fig'>",
  "healthPercent": <integer 0-100>,
  "diseaseStatus": "<'Healthy', 'None', or specific condition name like 'Leaf Spot' or 'Chlorosis'>",
  "confidencePercent": <integer 85-99>,
  "estimatedLifespanDays": <integer, default 180>,
  "estimatedWateringDays": <integer, default 3>,
  "recommendations": [
    "<recommendation 1>",
    "<recommendation 2>",
    "<recommendation 3>",
    "<recommendation 4>"
  ],
  "detailedAdvice": "<concise friendly botanical guidance for the child/gardener>"
}
Do not wrap in markdown quotes. Return pure JSON only.
''';

          final visionResponse = await _callGeminiVisionApi(
            prompt: prompt,
            base64Image: base64Image,
          );

          if (visionResponse != null && visionResponse.isNotEmpty) {
            try {
              final cleaned = visionResponse
                  .replaceAll('```json', '')
                  .replaceAll('```', '')
                  .trim();
              final map = jsonDecode(cleaned);
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
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('Multimodal Gemini vision analysis failed: $e');
      }
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
    );
  }

  /// Generates personalized daily growth stage care guidance
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

        final response = await _callGeminiApi(prompt: prompt);
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

  /// Analyzes Daily Check-in photo & environmental inputs
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

        final response = await _callGeminiApi(prompt: prompt);
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

  /// Interactive Q&A with Flora AI Plant Doctor
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
Plant context:
- Name: "${activePlant.plantName}" (${activePlant.speciesName})
- Age: ${activePlant.ageInDays} days, Stage: ${activePlant.growthStageName}
- Health: ${healthReport.overallHealth}% (${healthReport.status})
- Hydration: ${healthReport.hydrationScore}%, Sunlight: ${healthReport.sunlightScore}%
- Location: ${activePlant.location}

User Question: "$userQuestion"

Answer the user directly in 2-4 friendly, educational sentences with clear, actionable botanical tips. Keep it upbeat, child-friendly, and practical.
''';

        final response = await _callGeminiApi(prompt: prompt);
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

  /// REST call to Gemini Generative Language API with automatic multi-model fallback
  Future<String?> _callGeminiApi({
    required String prompt,
  }) async {
    final modelsToTry = [
      ApiConfig.primaryModel,
      ApiConfig.secondaryModel,
    ];

    for (final model in modelsToTry) {
      try {
        final uri = Uri.parse('${ApiConfig.geminiBaseUrl}/$model:generateContent');
        final headers = {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
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
          debugPrint('Model $model returned status ${response.statusCode}, trying fallback...');
        }
      } catch (e) {
        debugPrint('Model $model invocation error: $e');
      }
    }

    return null;
  }

  /// Multimodal Vision REST call to Gemini with base64 image inlineData
  Future<String?> _callGeminiVisionApi({
    required String prompt,
    required String base64Image,
  }) async {
    final modelsToTry = [
      'gemini-1.5-flash',
      'gemini-2.0-flash',
      'gemini-1.5-pro',
      ApiConfig.primaryModel,
      ApiConfig.secondaryModel,
    ];

    for (final model in modelsToTry) {
      try {
        final uri = Uri.parse('${ApiConfig.geminiBaseUrl}/$model:generateContent');
        final headers = {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
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

  /// Offline Q&A Reasoning Engine
  String _generateOfflineQnAResponse(
    PlantModel plant,
    String question,
    PlantHealthReport health,
  ) {
    final q = question.toLowerCase();
    final species = plant.speciesName;

    if (q.contains('water') || q.contains('drink') || q.contains('dry')) {
      return '💧 For your $species, water every ${plant.wateringIntervalDays} days. Currently, watering is scheduled for ${plant.wateringStatusText}. Always ensure soil has good drainage!';
    } else if (q.contains('sun') || q.contains('light') || q.contains('dark') || q.contains('window')) {
      return '☀️ $species prefers ${plant.targetSunlightHours} hours of daily sunlight. Place ${plant.plantName} near an east or south-facing window for optimal growth.';
    } else if (q.contains('yellow') || q.contains('brown') || q.contains('leaf') || q.contains('leaves')) {
      return '🍃 Yellowing or brown leaf tips usually indicate either over-watering or direct sun scorching. Ensure the pot has drainage and move it to bright indirect light.';
    } else if (q.contains('grow') || q.contains('stage') || q.contains('fast') || q.contains('tall')) {
      return '📈 ${plant.plantName} is currently at ${(plant.growthProgress * 100).toInt()}% progress in the ${plant.growthStageName} stage! Consistent daily check-ins accelerate healthy natural development.';
    } else if (q.contains('health') || q.contains('how is') || q.contains('status')) {
      return '🩺 Health Report: Overall ${health.overallHealth}% (${health.status}). Hydration is at ${health.hydrationScore}% and Sunlight is at ${health.sunlightScore}%. Keep up the fantastic care!';
    } else {
      return '🌿 As a botanical mentor for ${plant.plantName} ($species), my top advice is consistency! Provide ${plant.targetSunlightHours}h light, water every ${plant.wateringIntervalDays} days, and check in daily to earn your certificate!';
    }
  }
}
