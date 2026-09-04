import { env } from '../../config/env.js';

export class HuggingFaceService {
  static async classifyImage(base64Image) {
    if (!env.huggingFaceApiKey) return null;

    try {
      let cleanBase64 = base64Image;
      if (base64Image.includes(',')) {
        cleanBase64 = base64Image.split(',')[1];
      }
      const buffer = Buffer.from(cleanBase64, 'base64');

      const modelsToTry = [
        env.huggingFaceModel || 'foduucom/plant-leaf-detection-and-classification',
        'spignelon/plant_leaf_classifier',
        'google/vit-base-patch16-224',
      ];

      for (const model of modelsToTry) {
        const url = `https://api-inference.huggingface.co/models/${model}`;
        const response = await fetch(url, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${env.huggingFaceApiKey}`,
            'Content-Type': 'application/octet-stream',
          },
          body: buffer,
        });

        if (response.ok) {
          const results = await response.json();
          if (Array.isArray(results) && results.length > 0) {
            const top = results[0];
            return {
              label: top.label || 'Plant Leaf',
              confidence: Math.round((top.score || 0.85) * 100),
              modelUsed: model,
            };
          }
        }
      }
    } catch (error) {
      console.error('[HuggingFaceService] Classification failed:', error.message);
    }
    return null;
  }
}
