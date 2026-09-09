import { env } from '../../config/env.js';

export class GeminiService {
  static async generateContent(prompt, base64Image = null) {
    const keysToTry = [env.geminiApiKey1, env.geminiApiKey, env.geminiApiKey2].filter((k) => k && k.length > 0);

    if (keysToTry.length === 0) {
      console.warn('[GeminiService] No API keys configured in environment.');
      return null;
    }

    const modelsToTry = [
      'gemini-2.5-flash',
      'gemini-2.5-flash-lite',
      'gemini-3.7-flash',
      'gemini-3.5-flash',
      'gemini-flash-latest',
      'gemini-1.5-flash',
    ];

    for (const key of keysToTry) {
      for (const model of modelsToTry) {
        try {
          const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
          const parts = [{ text: prompt }];

          if (base64Image) {
            let cleanBase64 = base64Image;
            if (base64Image.includes(',')) {
              cleanBase64 = base64Image.split(',')[1];
            }
            parts.push({
              inlineData: {
                mimeType: 'image/jpeg',
                data: cleanBase64,
              },
            });
          }

          const response = await fetch(url, {
            method: 'POST',
            signal: AbortSignal.timeout(8000),
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': key,
            },
            body: JSON.stringify({
              contents: [{ parts }],
              generationConfig: {
                temperature: 0.2,
                maxOutputTokens: 1024,
                thinkingConfig: {
                  thinkingBudget: 0,
                },
              },
            }),
          });

          if (response.ok) {
            const data = await response.json();
            const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
            if (text) return text;
          }
        } catch (error) {
          console.error(`[GeminiService] Model ${model} request failed:`, error.message);
        }
      }
    }

    return null;
  }
}
