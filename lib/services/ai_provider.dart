import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

enum AIResultStatus {
  success,
  rejected,
  providerError,
  networkError,
  timeout,
  invalidImage,
  lowConfidence,
  unsupportedImage,
  authenticationError,
}

class PlantIdentificationResult {
  final AIResultStatus status;
  final String identifiedSpecies;
  final int confidencePercent;
  final bool isPlantDetected;
  final String detectedObjectType;
  final String? rejectionReason;
  final String? errorMessage;

  const PlantIdentificationResult({
    required this.status,
    this.identifiedSpecies = 'Unknown Species',
    this.confidencePercent = 0,
    this.isPlantDetected = false,
    this.detectedObjectType = 'Unknown Object',
    this.rejectionReason,
    this.errorMessage,
  });
}

class WateringVerificationResult {
  final AIResultStatus status;
  final bool isVerified;
  final int confidencePercent;
  final String userFeedback;
  final String? rejectionReason;
  final String? errorMessage;

  const WateringVerificationResult({
    required this.status,
    required this.isVerified,
    this.confidencePercent = 0,
    this.userFeedback = 'Watering verification incomplete.',
    this.rejectionReason,
    this.errorMessage,
  });
}

class PlantObservationResult {
  final AIResultStatus status;
  final int healthPercent;
  final String diseaseStatus;
  final List<String> recommendations;
  final String detailedAdvice;

  const PlantObservationResult({
    required this.status,
    this.healthPercent = 0,
    this.diseaseStatus = 'Unknown',
    this.recommendations = const [],
    this.detailedAdvice = '',
  });
}

class BuddyResponse {
  final AIResultStatus status;
  final String answerText;

  const BuddyResponse({
    required this.status,
    required this.answerText,
  });
}

abstract class AIProvider {
  Future<PlantIdentificationResult> identifyPlant({
    required String base64Image,
    List<int>? rawBytes,
  });

  Future<WateringVerificationResult> verifyWatering({
    required String plantName,
    required String speciesName,
    required String base64Image,
    List<int>? rawBytes,
  });

  Future<BuddyResponse> askBuddy({
    required String prompt,
  });
}

class GeminiProvider implements AIProvider {
  final String? _explicitKey;
  GeminiProvider({String? apiKey}) : _explicitKey = apiKey;

  String get apiKey => _explicitKey ?? ApiConfig.geminiApiKey;
  String get _effectiveKey => apiKey;

  @override
  Future<PlantIdentificationResult> identifyPlant({
    required String base64Image,
    List<int>? rawBytes,
  }) async {
    if (_effectiveKey.isEmpty) {
      return const PlantIdentificationResult(
        status: AIResultStatus.authenticationError,
        errorMessage: 'Gemini API key is unconfigured.',
      );
    }
    if (ApiConfig.usesBackendProxy) {
      try {
        final uri = Uri.parse('${ApiConfig.aiBackendUrl}${ApiConfig.backendIdentifyEndpoint}');
        final response = await http.post(
          uri,
          headers: AuthService().getAuthorizationHeaders(),
          body: jsonEncode({'image': base64Image}),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final map = jsonDecode(response.body);
          final isPlant = map['isPlantDetected'] == true;
          final objectType = map['detectedObjectType']?.toString() ?? 'Object';
          final rejection = map['rejectionReason']?.toString();
          final species = map['identifiedSpecies']?.toString() ?? 'Unknown Species';
          final confidence = (map['confidencePercent'] as num?)?.toInt() ?? 0;

          if (!isPlant) {
            return PlantIdentificationResult(
              status: AIResultStatus.rejected,
              isPlantDetected: false,
              detectedObjectType: objectType,
              rejectionReason: rejection ?? 'No plant detected. Photo showed $objectType.',
              identifiedSpecies: 'Not a Plant',
              confidencePercent: 0,
            );
          }

          return PlantIdentificationResult(
            status: AIResultStatus.success,
            isPlantDetected: true,
            detectedObjectType: 'Plant / Leaf',
            identifiedSpecies: species,
            confidencePercent: confidence,
          );
        }
      } catch (e) {
        return PlantIdentificationResult(
          status: AIResultStatus.networkError,
          errorMessage: e.toString(),
        );
      }
    }

    if (_effectiveKey.isEmpty) {
      return const PlantIdentificationResult(
        status: AIResultStatus.authenticationError,
        errorMessage: 'Gemini API key is not configured.',
      );
    }

    try {
      final prompt = '''
You are an expert AI computer vision botanist.
Analyze this photo and determine:
1. Is a real plant/leaf/seedling present? (isPlantDetected: true/false)
2. If non-plant (e.g. wall, pen, furniture, desk, person), describe in detectedObjectType.
3. Identified common species name in identifiedSpecies.
4. Confidence percent integer (85-99).

Return JSON only:
{
  "isPlantDetected": true,
  "detectedObjectType": "Plant / Leaf",
  "rejectionReason": null,
  "identifiedSpecies": "<Identified botanical species name e.g. Tulsi, ZZ Plant, Money Plant>",
  "confidencePercent": 95
}
''';

      final mimeType = (base64Image.startsWith('iVBOR') || base64Image.startsWith('data:image/png'))
          ? 'image/png'
          : 'image/jpeg';

      final uri = Uri.parse('${ApiConfig.geminiBaseUrl}/${ApiConfig.primaryModel}:generateContent');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _effectiveKey,
        },
        body: jsonEncode({
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
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null) {
          String cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
          final startIdx = cleaned.indexOf('{');
          final endIdx = cleaned.lastIndexOf('}');
          if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
            cleaned = cleaned.substring(startIdx, endIdx + 1);
          }
          final map = jsonDecode(cleaned);

          final isPlant = map['isPlantDetected'] == true;
          final objectType = map['detectedObjectType']?.toString() ?? 'Object';
          final rejection = map['rejectionReason']?.toString();
          final species = map['identifiedSpecies']?.toString() ?? 'Unknown Species';
          final confidence = (map['confidencePercent'] as num?)?.toInt() ?? 0;

          if (!isPlant) {
            return PlantIdentificationResult(
              status: AIResultStatus.rejected,
              isPlantDetected: false,
              detectedObjectType: objectType,
              rejectionReason: rejection ?? 'No plant detected. Photo showed $objectType.',
              identifiedSpecies: 'Not a Plant',
              confidencePercent: 0,
            );
          }

          return PlantIdentificationResult(
            status: AIResultStatus.success,
            isPlantDetected: true,
            detectedObjectType: 'Plant / Leaf',
            identifiedSpecies: species,
            confidencePercent: confidence,
          );
        }
      }
      return const PlantIdentificationResult(
        status: AIResultStatus.providerError,
        isPlantDetected: false,
        detectedObjectType: 'Non-Botanical Object',
        rejectionReason: 'Unable to recognize plant species. Please try capturing with clear lighting on plant foliage.',
        identifiedSpecies: 'Not a Plant',
        errorMessage: 'Gemini provider returned non-200 status code.',
      );
    } catch (e) {
      return PlantIdentificationResult(
        status: AIResultStatus.networkError,
        isPlantDetected: false,
        detectedObjectType: 'Non-Botanical Object',
        rejectionReason: 'Unable to recognize plant: $e',
        identifiedSpecies: 'Not a Plant',
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<WateringVerificationResult> verifyWatering({
    required String plantName,
    required String speciesName,
    required String base64Image,
    List<int>? rawBytes,
  }) async {
    if (_effectiveKey.isEmpty) {
      return const WateringVerificationResult(
        status: AIResultStatus.authenticationError,
        isVerified: false,
        userFeedback: 'Gemini API key is unconfigured.',
      );
    }
    if (ApiConfig.usesBackendProxy) {
      try {
        final uri = Uri.parse('${ApiConfig.aiBackendUrl}${ApiConfig.backendWateringEndpoint}');
        final response = await http.post(
          uri,
          headers: AuthService().getAuthorizationHeaders(),
          body: jsonEncode({
            'plantName': plantName,
            'speciesName': speciesName,
            'image': base64Image,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final map = jsonDecode(response.body);
          final isVerified = map['isWateringVerified'] == true;
          final confidence = (map['confidencePercent'] as num?)?.toInt() ?? 0;
          final feedback = map['userFeedback']?.toString() ?? 'Watering check complete.';

          return WateringVerificationResult(
            status: isVerified ? AIResultStatus.success : AIResultStatus.rejected,
            isVerified: isVerified,
            confidencePercent: confidence,
            userFeedback: feedback,
            rejectionReason: isVerified ? null : feedback,
          );
        }
      } catch (e) {
        return WateringVerificationResult(
          status: AIResultStatus.networkError,
          isVerified: false,
          errorMessage: e.toString(),
        );
      }
    }

    if (_effectiveKey.isEmpty) {
      return const WateringVerificationResult(
        status: AIResultStatus.authenticationError,
        isVerified: false,
        errorMessage: 'Gemini API Key missing.',
      );
    }

    try {
      final prompt = '''
Analyze this image as proof of watering plant "$plantName" ($speciesName).
Verify if a plant and watering action (water droplets, watering can, wet soil) are clearly present.

Return JSON only:
{
  "isWateringVerified": true,
  "confidencePercent": 92,
  "userFeedback": "Watering verified!"
}
''';

      final uri = Uri.parse('${ApiConfig.geminiBaseUrl}/${ApiConfig.primaryModel}:generateContent');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _effectiveKey,
        },
        body: jsonEncode({
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
            'temperature': 0.2,
            'maxOutputTokens': 1024,
            'thinkingConfig': {
              'thinkingBudget': 0,
            },
          }
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null) {
          String cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
          final startIdx = cleaned.indexOf('{');
          final endIdx = cleaned.lastIndexOf('}');
          if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
            cleaned = cleaned.substring(startIdx, endIdx + 1);
          }
          final map = jsonDecode(cleaned);
          final isVerified = map['isWateringVerified'] == true;
          final confidence = (map['confidencePercent'] as num?)?.toInt() ?? 0;
          final feedback = map['userFeedback']?.toString() ?? 'Watering check complete.';

          return WateringVerificationResult(
            status: isVerified ? AIResultStatus.success : AIResultStatus.rejected,
            isVerified: isVerified,
            confidencePercent: confidence,
            userFeedback: feedback,
            rejectionReason: isVerified ? null : feedback,
          );
        }
      }
      return const WateringVerificationResult(
        status: AIResultStatus.providerError,
        isVerified: false,
        errorMessage: 'Provider returned error status.',
      );
    } catch (e) {
      return WateringVerificationResult(
        status: AIResultStatus.networkError,
        isVerified: false,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<BuddyResponse> askBuddy({required String prompt}) async {
    if (ApiConfig.usesBackendProxy) {
      try {
        final uri = Uri.parse('${ApiConfig.aiBackendUrl}${ApiConfig.backendBuddyEndpoint}');
        final response = await http.post(
          uri,
          headers: AuthService().getAuthorizationHeaders(),
          body: jsonEncode({'prompt': prompt}),
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final text = data['answerText'] ?? data['result'] ?? data['text'];
          if (text != null && text.toString().isNotEmpty) {
            return BuddyResponse(
              status: AIResultStatus.success,
              answerText: text.toString().trim(),
            );
          }
        }
      } catch (e) {
        return BuddyResponse(
          status: AIResultStatus.networkError,
          answerText: 'Network connection issue.',
        );
      }
    }

    if (_effectiveKey.isEmpty) {
      return const BuddyResponse(
        status: AIResultStatus.authenticationError,
        answerText: 'Live AI unavailable.',
      );
    }

    try {
      final uri = Uri.parse('${ApiConfig.geminiBaseUrl}/${ApiConfig.primaryModel}:generateContent');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _effectiveKey,
        },
        body: jsonEncode({
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
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
        if (text != null && text.isNotEmpty) {
          return BuddyResponse(
            status: AIResultStatus.success,
            answerText: text.trim(),
          );
        }
      }
      return const BuddyResponse(
        status: AIResultStatus.providerError,
        answerText: 'Provider returned error status.',
      );
    } catch (e) {
      return BuddyResponse(
        status: AIResultStatus.networkError,
        answerText: 'Network connection issue.',
      );
    }
  }
}

class HuggingFaceProvider implements AIProvider {
  final String apiKey;
  HuggingFaceProvider({this.apiKey = ''});

  @override
  Future<PlantIdentificationResult> identifyPlant({
    required String base64Image,
    List<int>? rawBytes,
  }) async {
    if (apiKey.isEmpty || rawBytes == null) {
      return const PlantIdentificationResult(
        status: AIResultStatus.authenticationError,
        errorMessage: 'Hugging Face API key or raw bytes missing.',
      );
    }
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.huggingFaceVisionModel),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/octet-stream',
        },
        body: rawBytes,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        if (list.isNotEmpty) {
          final topMatch = list.first as Map<String, dynamic>;
          final label = topMatch['label']?.toString() ?? 'Plant';
          final score = (topMatch['score'] as num?)?.toDouble() ?? 0.0;
          final confidenceInt = (score * 100).toInt();

          return PlantIdentificationResult(
            status: AIResultStatus.success,
            isPlantDetected: true,
            identifiedSpecies: label,
            confidencePercent: confidenceInt,
          );
        }
      }
      return const PlantIdentificationResult(
        status: AIResultStatus.providerError,
        errorMessage: 'Hugging Face response invalid.',
      );
    } catch (e) {
      return PlantIdentificationResult(
        status: AIResultStatus.networkError,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<WateringVerificationResult> verifyWatering({
    required String plantName,
    required String speciesName,
    required String base64Image,
    List<int>? rawBytes,
  }) async {
    return const WateringVerificationResult(
      status: AIResultStatus.providerError,
      isVerified: false,
      errorMessage: 'Hugging Face does not support direct watering action verification.',
    );
  }

  @override
  Future<BuddyResponse> askBuddy({required String prompt}) async {
    return const BuddyResponse(
      status: AIResultStatus.providerError,
      answerText: 'Hugging Face vision model does not support text Q&A.',
    );
  }
}

class GroqProvider implements AIProvider {
  final String apiKey;
  GroqProvider({this.apiKey = ''});

  @override
  Future<PlantIdentificationResult> identifyPlant({
    required String base64Image,
    List<int>? rawBytes,
  }) async {
    final effectiveKey = apiKey.isNotEmpty ? apiKey : ApiConfig.groqApiKey;
    if (effectiveKey.isEmpty) {
      return const PlantIdentificationResult(
        status: AIResultStatus.authenticationError,
        errorMessage: 'Groq API key is missing.',
      );
    }

    try {
      final prompt = '''
You are an expert AI vision botanist.
Analyze this photo carefully.
Return a JSON object in this exact format:
{
  "isPlantDetected": true or false,
  "detectedObjectType": "<'Plant / Leaf' if plant/seedling/leaf detected, or specific non-plant object name>",
  "rejectionReason": "<If false, explain why>",
  "identifiedSpecies": "<Common English species name e.g. Tulsi, Rose, Aloe Vera, Money Plant, Tomato>",
  "confidencePercent": <integer 80-99>
}
Return JSON only without markdown formatting.
''';

      final imageUrl = base64Image.startsWith('data:image')
          ? base64Image
          : 'data:image/jpeg;base64,$base64Image';

      final response = await http.post(
        Uri.parse(ApiConfig.groqApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $effectiveKey',
        },
        body: jsonEncode({
          'model': ApiConfig.groqVisionModel,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': imageUrl}
                }
              ]
            }
          ],
          'temperature': 0.2,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content']?.toString();
        if (content != null) {
          final cleaned = content.replaceAll('```json', '').replaceAll('```', '').trim();
          final map = jsonDecode(cleaned);
          final isPlant = map['isPlantDetected'] == true;
          final objectType = map['detectedObjectType']?.toString() ?? 'Object';
          final rejection = map['rejectionReason']?.toString();
          final species = map['identifiedSpecies']?.toString() ?? 'Unknown Species';
          final confidence = (map['confidencePercent'] as num?)?.toInt() ?? 85;

          if (!isPlant) {
            return PlantIdentificationResult(
              status: AIResultStatus.rejected,
              isPlantDetected: false,
              detectedObjectType: objectType,
              rejectionReason: rejection ?? 'No plant detected in photo.',
              identifiedSpecies: 'Not a Plant',
              confidencePercent: 0,
            );
          }

          return PlantIdentificationResult(
            status: AIResultStatus.success,
            isPlantDetected: true,
            detectedObjectType: 'Plant / Leaf',
            identifiedSpecies: species,
            confidencePercent: confidence,
          );
        }
      }
      return const PlantIdentificationResult(
        status: AIResultStatus.providerError,
        errorMessage: 'Groq vision API returned unexpected status.',
      );
    } catch (e) {
      return PlantIdentificationResult(
        status: AIResultStatus.networkError,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  Future<WateringVerificationResult> verifyWatering({
    required String plantName,
    required String speciesName,
    required String base64Image,
    List<int>? rawBytes,
  }) async {
    return const WateringVerificationResult(
      status: AIResultStatus.providerError,
      isVerified: false,
      errorMessage: 'Groq vision is unconfigured.',
    );
  }

  @override
  Future<BuddyResponse> askBuddy({required String prompt}) async {
    if (apiKey.isEmpty) {
      return const BuddyResponse(
        status: AIResultStatus.authenticationError,
        answerText: 'Groq API key is missing.',
      );
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.groqApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
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
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content']?.toString();
        if (content != null) {
          return BuddyResponse(
            status: AIResultStatus.success,
            answerText: content.trim(),
          );
        }
      }
      return const BuddyResponse(
        status: AIResultStatus.providerError,
        answerText: 'Groq returned error response.',
      );
    } catch (e) {
      return BuddyResponse(
        status: AIResultStatus.networkError,
        answerText: e.toString(),
      );
    }
  }
}
