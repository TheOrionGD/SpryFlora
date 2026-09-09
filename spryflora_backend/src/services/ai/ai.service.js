import { GeminiService } from './gemini.service.js';
import { HuggingFaceService } from './huggingface.service.js';
import { GroqService } from './groq.service.js';
import { ERROR_CODES } from '../../constants/index.js';

export class AIService {
  static parseJSONResponse(rawText) {
    if (!rawText || typeof rawText !== 'string') return null;
    try {
      const cleaned = rawText.replace(/```json/gi, '').replace(/```/g, '').trim();
      return JSON.parse(cleaned);
    } catch (_) {
      return null;
    }
  }

  static async identifyPlant({ image, prompt }) {
    if (!image) {
      const err = new Error('Image data required for plant identification.');
      err.statusCode = 400;
      err.code = ERROR_CODES.BAD_REQUEST;
      throw err;
    }

    const hfResult = await HuggingFaceService.classifyImage(image);

    const defaultPrompt = `
You are an expert AI computer vision botanist. Analyze this plant photo carefully.
Verify if this image contains a real plant, leaf, flower, seedling, or sprout.
If a real botanical plant is present, identify the specific botanical species (e.g. Rose, Sunflower, Marigold, Tulsi, Money Plant, Aloe Vera, Snake Plant, Peace Lily, Tomato, Hibiscus, etc.).
If NO plant, flower, leaf, or seedling is present, set "isPlantDetected" to false, "identifiedSpecies" to "No Plant Found", "confidencePercent" to 0, and describe the non-plant object in "detectedObjectType".

Return a JSON object in this exact format:
{
  "isPlantDetected": true,
  "detectedObjectType": "Plant / Leaf",
  "rejectionReason": null,
  "identifiedSpecies": "${hfResult ? hfResult.label : '<Exact species name or No Plant Found>'}",
  "confidencePercent": ${hfResult ? hfResult.confidence : 95},
  "healthPercent": 95,
  "diseaseStatus": "Healthy",
  "recommendations": ["Ensure 4-6 hours of bright light", "Water regularly according to species needs"],
  "detailedAdvice": "Plant foliage appears vibrant and healthy."
}
Do not wrap in markdown. Return pure JSON only.
`;

    const aiPrompt = prompt || defaultPrompt;
    let responseText = await GroqService.generateVisionContent(aiPrompt, image);

    if (!responseText) {
      responseText = await GeminiService.generateContent(aiPrompt, image);
    }

    if (!responseText) {
      responseText = await GroqService.generateContent(aiPrompt);
    }

    if (!responseText) {
      const err = new Error('AI provider unavailable or timed out.');
      err.statusCode = 503;
      err.code = ERROR_CODES.AI_ANALYSIS_FAILED;
      throw err;
    }

    const parsed = this.parseJSONResponse(responseText);
    if (!parsed || typeof parsed.isPlantDetected !== 'boolean') {
      const err = new Error('AI provider returned malformed analysis JSON.');
      err.statusCode = 502;
      err.code = ERROR_CODES.AI_ANALYSIS_FAILED;
      throw err;
    }

    return parsed;
  }

  static async analyzePlant({ plant, image, prompt }) {
    const defaultPrompt = `
You are an expert AI plant pathologist. Analyze this photo of plant "${plant ? plant.plantName : 'Garden Plant'}".
Return JSON:
{
  "isPlantDetected": true,
  "healthPercent": 92,
  "diseaseStatus": "Healthy",
  "confidencePercent": 94,
  "recommendations": ["Maintain current watering cycle"],
  "detailedAdvice": "Optimal leaf development observed."
}
`;

    const aiPrompt = prompt || defaultPrompt;
    let responseText = null;

    if (image) {
      responseText = await GroqService.generateVisionContent(aiPrompt, image);
      if (!responseText) {
        responseText = await GeminiService.generateContent(aiPrompt, image);
      }
    } else {
      responseText = await GroqService.generateContent(aiPrompt);
      if (!responseText) {
        responseText = await GeminiService.generateContent(aiPrompt);
      }
    }

    if (!responseText) {
      const err = new Error('AI analysis service unavailable.');
      err.statusCode = 503;
      err.code = ERROR_CODES.AI_ANALYSIS_FAILED;
      throw err;
    }

    const parsed = this.parseJSONResponse(responseText);
    if (!parsed) {
      return {
        result: responseText,
        text: responseText,
      };
    }

    return parsed;
  }

  static async verifyWateringPhoto({ plant, image }) {
    if (!image) {
      return {
        isVerified: false,
        confidence: 0,
        message: 'No photo provided for verification.',
        rejectionReason: 'Photo evidence required for watering verification.',
      };
    }

    const prompt = `
Analyze this image submitted as proof of watering a plant named "${plant ? plant.plantName : 'Plant'}".
Determine if the photo shows a real plant/leaf and signs of watering/care activity.
Return pure JSON only:
{
  "isWateringVerified": true,
  "confidencePercent": 94,
  "userFeedback": "Great job watering your plant!"
}
`;

    let responseText = await GroqService.generateVisionContent(prompt, image);
    if (!responseText) {
      responseText = await GeminiService.generateContent(prompt, image);
    }

    if (!responseText) {
      // Rule: NO fake success when AI provider fails
      return {
        isVerified: false,
        confidence: 0,
        message: 'AI verification service unavailable.',
        rejectionReason: 'AI provider failed to process image evidence.',
      };
    }

    const parsed = this.parseJSONResponse(responseText);
    if (!parsed || typeof parsed.isWateringVerified !== 'boolean') {
      return {
        isVerified: false,
        confidence: 0,
        message: 'AI verification failed.',
        rejectionReason: 'AI provider returned invalid schema response.',
      };
    }

    return {
      isVerified: parsed.isWateringVerified === true,
      confidence: parsed.confidencePercent || 90,
      message: parsed.userFeedback || 'Watering photo verified!',
      rejectionReason: parsed.isWateringVerified ? null : parsed.userFeedback,
    };
  }

  static async askBuddy({ prompt, plant }) {
    const fullPrompt = `
You are Flora AI, a friendly botanical expert mentor for children in the SpryFlora plant app.
User prompt: "${prompt}"
Context: Caring for plant "${plant ? plant.plantName : 'Companion'}".
Reply in 2-4 encouraging, educational sentences with emojis.
`;

    let responseText = await GroqService.generateContent(fullPrompt);
    if (!responseText) {
      responseText = await GeminiService.generateContent(fullPrompt);
    }

    if (!responseText) {
      const err = new Error('AI assistant service is currently unavailable.');
      err.statusCode = 503;
      err.code = ERROR_CODES.AI_ANALYSIS_FAILED;
      throw err;
    }

    return {
      result: responseText,
      text: responseText,
    };
  }
}
