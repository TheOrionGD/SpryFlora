import { env } from '../../config/env.js';

export class GroqService {
  static async generateContent(prompt) {
    if (!env.groqApiKey) return null;

    const modelsToTry = [
      'groq/compound-mini',
      'qwen/qwen3.8-27b',
      'groq/compound',
      'openai/gpt-oss-120b',
    ];

    for (const model of modelsToTry) {
      try {
        const url = 'https://api.groq.com/openai/v1/chat/completions';
        const response = await fetch(url, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${env.groqApiKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            model: model,
            messages: [{ role: 'user', content: prompt }],
            temperature: 0.5,
            max_tokens: 600,
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
