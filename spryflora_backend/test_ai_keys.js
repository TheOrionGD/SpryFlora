import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const envPath = path.join(__dirname, '.env');
const envContent = fs.readFileSync(envPath, 'utf8');

const env = {};
envContent.split('\n').forEach((line) => {
  const trimmed = line.trim();
  if (trimmed && !trimmed.startsWith('#')) {
    const parts = trimmed.split('=');
    if (parts.length >= 2) {
      const key = parts[0].trim();
      const val = parts.slice(1).join('=').trim();
      env[key] = val;
    }
  }
});

console.log('----------------------------------------------------');
console.log('🚀 TESTING UPDATED MODEL VARIANTS FOR SPRYFLORA');
console.log('----------------------------------------------------\n');

async function testGeminiKey(keyName, keyValue, modelName) {
  if (!keyValue) return;

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent`;
  const prompt = 'Give one short botanical tip for plant care.';

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': keyValue,
      },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig: { maxOutputTokens: 60, temperature: 0.3 },
      }),
    });

    if (res.ok) {
      const data = await res.json();
      const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
      console.log(`✅ [${keyName}] SUCCESS with model '${modelName}':`);
      console.log(`   Response: "${text?.trim()}"\n`);
      return { keyName, modelName, success: true, text: text?.trim() };
    } else {
      const errText = await res.text();
      const errObj = JSON.parse(errText);
      console.log(`❌ [${keyName}] FAILED '${modelName}' (${res.status}): ${errObj.error?.message || errText}`);
      return { keyName, modelName, success: false };
    }
  } catch (err) {
    console.log(`❌ [${keyName}] ERROR '${modelName}': ${err.message}`);
    return { keyName, modelName, success: false };
  }
}

async function testGrokKey(keyValue, modelName) {
  if (!keyValue) return;

  const url = 'https://api.x.ai/v1/chat/completions';
  const prompt = 'State one benefit of sunlight for plants.';

  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${keyValue}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: modelName,
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.5,
        max_tokens: 40,
      }),
    });

    if (res.ok) {
      const data = await res.json();
      const text = data.choices?.[0]?.message?.content;
      console.log(`✅ [GROK_API_KEY] SUCCESS with model '${modelName}':`);
      console.log(`   Response: "${text?.trim()}"\n`);
      return { keyName: 'GROK_API_KEY', modelName, success: true, text: text?.trim() };
    } else {
      const errText = await res.text();
      console.log(`❌ [GROK_API_KEY] FAILED '${modelName}' (${res.status}): ${errText}`);
      return { keyName: 'GROK_API_KEY', modelName, success: false };
    }
  } catch (err) {
    console.log(`❌ [GROK_API_KEY] ERROR '${modelName}': ${err.message}`);
    return { keyName: 'GROK_API_KEY', modelName, success: false };
  }
}

async function listGeminiModels(keyValue) {
  const url = `https://generativelanguage.googleapis.com/v1beta/models?key=${keyValue}`;
  try {
    const res = await fetch(url);
    if (res.ok) {
      const data = await res.json();
      const models = data.models?.map((m) => m.name.replace('models/', '')) || [];
      console.log('📋 Available Gemini Models from API:', models.join(', '), '\n');
      return models;
    } else {
      console.log('❌ Could not list models:', await res.text());
    }
  } catch (err) {
    console.log('❌ List models failed:', err.message);
  }
  return [];
}

async function listGrokModels(keyValue) {
  const url = 'https://api.x.ai/v1/models';
  try {
    const res = await fetch(url, {
      headers: { Authorization: `Bearer ${keyValue}` },
    });
    if (res.ok) {
      const data = await res.json();
      const models = data.data?.map((m) => m.id) || [];
      console.log('📋 Available Grok Models from xAI API:', models.join(', '), '\n');
      return models;
    } else {
      console.log('❌ Could not list Grok models:', await res.text());
    }
  } catch (err) {
    console.log('❌ List Grok models failed:', err.message);
  }
  return [];
}

async function runAllTests() {
  console.log('--- 1. LISTING AVAILABLE GEMINI MODELS ---');
  const availableGemini = await listGeminiModels(env.GEMINI_API_KEY_1);

  console.log('--- 2. TESTING GEMINI KEYS WITH VALIDATED MODELS ---');
  for (const m of availableGemini.slice(0, 8)) {
    await testGeminiKey('GEMINI_API_KEY_1', env.GEMINI_API_KEY_1, m);
  }

  console.log('--- 3. LISTING AVAILABLE GROK MODELS ---');
  const availableGrok = await listGrokModels(env.GROK_API_KEY);

  console.log('--- 4. TESTING GROK MODELS ---');
  for (const m of availableGrok) {
    await testGrokKey(env.GROK_API_KEY, m);
  }
}

runAllTests();
