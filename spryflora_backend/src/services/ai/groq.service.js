import { env } from '../../config/env.js';

export class GroqService {
  static async generateVisionContent(prompt, base64Image) {
    if (!env.groqApiKey || !base64Image) return null;

    let cleanBase64 = base64Image.trim();
    if (cleanBase64.includes(',')) {
      cleanBase64 = cleanBase64.split(',')[1].trim();
    }
    const imageUrl = `data:image/jpeg;base64,${cleanBase64}`;

    const modelsToTry = [
      'llama-3.2-11b-vision-preview',
      'llama-3.2-90b-vision-preview',
    ];

    for (const model of modelsToTry) {
      try {
        const url = 'https://api.groq.com/openai/v1/chat/completions';
        const response = await fetch(url, {
          method: 'POST',
          signal: AbortSignal.timeout(10000),
          headers: {
            Authorization: `Bearer ${env.groqApiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            model: model,
            messages: [
              {
                role: 'user',
                content: [
                  { type: 'text', text: prompt },
                  { type: 'image_url', image_url: { url: imageUrl } },
                ],
              },
            ],
            temperature: 0.2,
            max_tokens: 1024,
          }),
        });

        if (response.ok) {
          const data = await response.json();
          const text = data.choices?.[0]?.message?.content;
          if (text) return text.trim();
        }
      } catch (error) {
        console.error(`[GroqService] Vision model ${model} failed:`, error.message);
      }
    }

    return null;
  }

  static async generateContent(prompt) {
    if (!env.groqApiKey) return null;

    const modelsToTry = [
      'llama-3.3-70b-versatile',
      'llama-3.1-8b-instant',
      'llama-3.3-70b-specdec',
      'openai/gpt-oss-120b',
      'groq/compound-mini',
    ];

    for (const model of modelsToTry) {
      try {
        const url = 'https://api.groq.com/openai/v1/chat/completions';
        const response = await fetch(url, {
          method: 'POST',
          signal: AbortSignal.timeout(8000),
          headers: {
            Authorization: `Bearer ${env.groqApiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            model: model,
            messages: [{ role: 'user', content: prompt }],
            temperature: 0.7,
            max_tokens: 800,
          }),
        });

        if (response.ok) {
          const data = await response.json();
          const text = data.choices?.[0]?.message?.content;
          if (text) return text.trim();
        }
      } catch (error) {
        console.error(`[GroqService] Model ${model} request failed:`, error.message);
      }
    }

    return null;
  }
}
