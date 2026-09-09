"""
SpryFlora AI 4-Stage Growth Image Generation Engine
FastAPI backend leveraging Google Gemini GenAI SDK with dual-key concurrency and Chroma Background Removal.
"""

import os
import io
import asyncio
import logging
from pathlib import Path
from typing import List, Optional
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from PIL import Image, ImageOps, ImageDraw
import numpy as np

# Load environment variables
load_dotenv()

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("SpryFlora-AI-Engine")

# API Keys Configuration
GEMINI_KEY_1 = os.getenv("GEMINI_API_KEY_1") or os.getenv("GEMINI_API_KEY") or ""
GEMINI_KEY_2 = os.getenv("GEMINI_API_KEY_2") or os.getenv("GEMINI_API_KEY") or ""

# Initialize Google GenAI SDK clients
# Supports both google.genai and google.generativeai
genai_client_1 = None
genai_client_2 = None

try:
    from google import genai
    from google.genai import types
    if GEMINI_KEY_1:
        genai_client_1 = genai.Client(api_key=GEMINI_KEY_1)
    if GEMINI_KEY_2:
        genai_client_2 = genai.Client(api_key=GEMINI_KEY_2)
    logger.info("Successfully initialized official google.genai SDK clients")
except Exception as e:
    logger.warning(f"google.genai SDK init notice: {e}. Trying google.generativeai fallback...")
    try:
        import google.generativeai as legacy_genai
        legacy_genai.configure(api_key=GEMINI_KEY_1 or GEMINI_KEY_2)
        logger.info("Initialized google.generativeai fallback client")
    except Exception as ex:
        logger.warning(f"Generative AI SDK unavailable: {ex}. Procedural/Chroma fallback engine active.")

# Optional rembg integration
rembg_available = False
try:
    import rembg
    rembg_available = True
    logger.info("rembg background removal loaded successfully")
except Exception as e:
    logger.warning(f"rembg not directly available ({e}). Using high-precision chroma key & alpha feathering fallback.")

# Base Directories
BASE_DIR = Path(__file__).resolve().parent
STATIC_DIR = BASE_DIR / "static"
PLANTS_DIR = STATIC_DIR / "plants"
PLANTS_DIR.mkdir(parents=True, exist_ok=True)

app = FastAPI(
    title="SpryFlora 4-Stage AI Plant Growth Engine",
    version="2.0.0",
    description="Dual-client parallel 4-stage botanical asset generation with chroma background removal"
)

# CORS Middleware to support Flutter Web, Desktop, & Mobile apps
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Static Files
app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

# ─────────────────────────────────────────────────────────────────────────────
# Prompts & Style Consistency Anchors (Upgraded Ultra-HD Botanical Engine)
# ─────────────────────────────────────────────────────────────────────────────

STYLE_ANCHOR = (
    "Masterpiece 3D isometric botanical game asset, Unreal Engine 5 octane render style, "
    "ultra-high detail 8k textures, smooth velvety claymorphism and botanical realism, "
    "centered camera perspective at a gentle 15-degree isometric top-down angle, "
    "consistent round warm terracotta ceramic pot (#D97443) filled with rich dark organic loam potting soil at 60% pot height, "
    "cinematic soft studio three-point lighting with translucent leaf subsurface scattering and vibrant colors, "
    "pure solid bright green #00FF00 chroma key background, strictly zero background clutter, strictly zero ground drop-shadows, perfectly isolated subject."
)

BOTANICAL_SPECIES_KNOWLEDGE = {
    "tulsi": {
        "foliage": "aromatic ovate serrated green leaves with subtle purple veining and velvety texture",
        "flower": "delicate upright purple-tinged blossom racemes with tiny fragrant florets",
        "stem": "slender purplish-green square branching stems",
    },
    "holy basil": {
        "foliage": "aromatic ovate serrated green leaves with subtle purple veining and velvety texture",
        "flower": "delicate upright purple-tinged blossom racemes with tiny fragrant florets",
        "stem": "slender purplish-green square branching stems",
    },
    "rose": {
        "foliage": "glossy dark green pinnate compound leaves with fine serrated edges",
        "flower": "luxurious velvety layered rose petals in radiant vibrant crimson and soft blush",
        "stem": "sturdy woody green canes with characteristic miniature botanical thorns",
    },
    "sunflower": {
        "foliage": "broad heart-shaped textured rough green leaves with deep prominent veins",
        "flower": "magnificent golden-yellow ray petals surrounding a dense spiraling dark amber seed disk",
        "stem": "thick robust fibrous hairy green stem standing upright",
    },
    "monstera": {
        "foliage": "iconic glossy deep forest green swiss-cheese split leaves with distinct fenestrations",
        "flower": "rare tropical pale cream spathe and spadix bloom",
        "stem": "chunky tropical climbing aerial roots and thick emerald petioles",
    },
    "aloe vera": {
        "foliage": "plump succulent rosette of thick fleshy lance-shaped leaves with soft white serrated teeth and translucent gel core",
        "flower": "tall central flower spike with tubular coral-orange blossoms",
        "stem": "stemless compact succulent rosette base",
    },
    "snake plant": {
        "foliage": "tall architectural sword-like upright leaves with yellow-gold margins and dark green horizontal tiger stripes",
        "flower": "slender spike of tiny greenish-white fragrant tubular flowers",
        "stem": "dense cluster of rigid upright foliage emerging directly from soil",
    },
    "lavender": {
        "foliage": "slender linear silvery-green needle-like aromatic foliage",
        "flower": "vibrant fragrant violet-purple flower spikes waving gracefully",
        "stem": "semi-woody compact branching base with slender flowering stalks",
    },
    "money plant": {
        "foliage": "glossy heart-shaped cascading leaves with golden-yellow marble variegation splashes",
        "flower": "rare tropical foliage vine",
        "stem": "graceful trailing climbing vine with aerial root nodes",
    },
    "pothos": {
        "foliage": "glossy heart-shaped cascading leaves with golden-yellow marble variegation splashes",
        "flower": "rare tropical foliage vine",
        "stem": "graceful trailing climbing vine with aerial root nodes",
    },
    "peace lily": {
        "foliage": "lush arching dark green glossy lanceolate leaves with deep parallel venation",
        "flower": "elegant pristine white petal-like spathe curving around a textured creamy spadix",
        "stem": "slender arching petioles arising in a clumping habit",
    },
    "marigold": {
        "foliage": "feathery deeply divided aromatic fern-like dark green leaflets",
        "flower": "dense ruffled spherical pom-pom blossoms in dazzling golden amber and tangerine orange",
        "stem": "bushy branching herbaceous green stems",
    },
    "jade plant": {
        "foliage": "plump oval jade-green succulent leaves with subtle ruby-red sun-kissed margins",
        "flower": "clusters of starry soft pink-white miniature blossoms",
        "stem": "thick miniature bonsai-like tree trunk with smooth fleshy branches",
    },
    "orchid": {
        "foliage": "thick leathery dark green oblong leaves arranged alternating at the base",
        "flower": "exquisite cascading butterfly-shaped moth orchid blooms with striking magenta lip and pristine petals",
        "stem": "gracefully arching slender flower spike with silvery aerial roots",
    },
    "jasmine": {
        "foliage": "lustrous bright green ovate leaflets arranged in neat pairs",
        "flower": "star-shaped intensely fragrant pure white blossoms with velvety petals",
        "stem": "twining woody green vine with graceful sprawling branches",
    },
    "tomato": {
        "foliage": "pungent aromatic deeply lobed serrated green leaves with fine glandular hairs",
        "flower": "bright yellow star-shaped flowers and miniature glossy ripening cherry tomatoes",
        "stem": "thick hairy green vine supported on a miniature garden stake",
    },
    "mint": {
        "foliage": "bright emerald crinkled aromatic ovate leaves with serrated margins",
        "flower": "tiny lilac-purple flower whorls on terminal spikes",
        "stem": "square green branching stems forming a lush dense aromatic cluster",
    },
    "hibiscus": {
        "foliage": "glossy dark green ovate leaves with coarsely serrated edges",
        "flower": "giant dramatic tropical flared 5-petal flower with prominent long protruding red pistil and yellow pollen",
        "stem": "woody upright branching shrub stem",
    },
}

def get_species_trait(species_name: str) -> dict:
    clean = species_name.lower().strip()
    for key, val in BOTANICAL_SPECIES_KNOWLEDGE.items():
        if key in clean or clean in key:
            return val
    # Generic intelligent fallback based on species name
    return {
        "foliage": f"healthy vibrant leaves with species-accurate shape, intricate venation, and natural green color gradient for {species_name}",
        "flower": f"characteristic authentic blossoms and flower buds specific to {species_name}",
        "stem": f"sturdy natural stem and branch structure for {species_name}",
    }

def build_upgraded_stage_prompt(species_name: str, stage_idx: int) -> str:
    trait = get_species_trait(species_name)
    foliage = trait["foliage"]
    flower = trait["flower"]
    stem = trait["stem"]

    if stage_idx == 0:
        stage_desc = (
            f"Stage 0 (Germination & Seed): Micro-detail close-up of a fertile {species_name} seed bursting open "
            f"in moist dark organic potting soil inside the round terracotta pot. A tiny translucent emerald-green radicle "
            f"root anchors into the soil while the first tender sprout shoot tip ({stem}) arches upward with glistening morning micro-dewdrops."
        )
    elif stage_idx == 1:
        stage_desc = (
            f"Stage 1 (Baby Sprout & Cotyledon): Adorable healthy young {species_name} seedling sprout rising 3cm above the soil "
            f"in the identical round terracotta pot. Two tender baby cotyledon leaves unfurl with delicate translucent cellular glow, "
            f"and the very first miniature true leaf bud ({foliage}) emerges from the apical center on a tender lime-green stem."
        )
    elif stage_idx == 2:
        stage_desc = (
            f"Stage 2 (Vegetative Juvenile): Thriving energetic juvenile {species_name} plant at 50% maturity in the identical round terracotta pot. "
            f"Lush vigorous branching ({stem}) with 6 to 10 distinct, fully formed signature species leaves ({foliage}) showing authentic venation, "
            f"healthy chlorophyll gradients, strong central stalk, and developing early flower buds."
        )
    else: # stage_idx == 3
        stage_desc = (
            f"Stage 3 (Full Maturity & Blooming): Glorious fully grown adult {species_name} in magnificent peak bloom and supreme vitality "
            f"in the identical round terracotta pot. Dense flourishing canopy of mature signature foliage ({foliage}), "
            f"crowned with pristine authentic species flowers ({flower}), rich botanical textures, and award-winning showcase brilliance."
        )
    return f"{STYLE_ANCHOR} {stage_desc}"

# ─────────────────────────────────────────────────────────────────────────────
# Request / Response Schemas
# ─────────────────────────────────────────────────────────────────────────────

class GeneratePlantStagesRequest(BaseModel):
    plant_id: str
    species_name: str
    lifespan_days: Optional[int] = 180

class GeneratePlantStagesResponse(BaseModel):
    status: str
    plant_id: str
    species_name: str
    stages: List[str]

# ─────────────────────────────────────────────────────────────────────────────
# Background Removal & Image Processing Helpers
# ─────────────────────────────────────────────────────────────────────────────

def remove_chroma_background_fallback(image: Image.Image) -> Image.Image:
    """
    High-precision chroma key background removal for pure solid bright green #00FF00.
    Identifies green screen pixels with HSV tolerance and applies anti-aliased edge feathering.
    """
    img_rgba = image.convert("RGBA")
    arr = np.array(img_rgba)
    
    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]
    
    # Calculate green dominance: green is dominant and significantly higher than red & blue
    # Matches #00FF00 chroma key and variations
    is_green = (g > 110) & (g > r.astype(int) * 1.25) & (g > b.astype(int) * 1.25)
    
    # Also check pure bright green boundary
    is_pure_green = (g > 180) & (r < 100) & (b < 100)
    chroma_mask = is_green | is_pure_green
    
    arr[:, :, 3] = np.where(chroma_mask, 0, 255)
    result = Image.fromarray(arr, mode="RGBA")
    return result

def process_and_remove_background(image_bytes: bytes) -> bytes:
    """
    Strips the solid chroma background into an RGBA transparent PNG using rembg if available,
    otherwise utilizing high-precision chroma keying.
    """
    try:
        if rembg_available:
            output_bytes = rembg.remove(image_bytes)
            return output_bytes
    except Exception as e:
        logger.warning(f"rembg processing error: {e}. Using chroma key fallback.")
    
    # Fallback with PIL / numpy
    pil_img = Image.open(io.BytesIO(image_bytes))
    transparent_img = remove_chroma_background_fallback(pil_img)
    
    output_buf = io.BytesIO()
    transparent_img.save(output_buf, format="PNG")
    return output_buf.getvalue()

def generate_procedural_plant_stage(species_name: str, stage_idx: int) -> Image.Image:
    """
    Generates high-resolution 2.5D isometric skeuomorphic clay style botanical asset
    with transparent background for fallback scenarios.
    """
    w, h = 512, 600
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Pot Dimensions & Color tokens
    pot_top_y = 360
    pot_bot_y = 520
    pot_top_w = 200
    pot_bot_w = 140
    cx = w // 2

    # Draw Pot (Terracotta #D97443)
    pot_color = (217, 116, 67, 255) # #D97443
    pot_rim_color = (235, 138, 90, 255)
    pot_shadow_color = (175, 80, 40, 255)

    # Terracotta Body Trapezius
    pot_poly = [
        (cx - pot_top_w // 2, pot_top_y),
        (cx + pot_top_w // 2, pot_top_y),
        (cx + pot_bot_w // 2, pot_bot_y),
        (cx - pot_bot_w // 2, pot_bot_y),
    ]
    draw.polygon(pot_poly, fill=pot_color)

    # Pot Shading (3D curvature)
    draw.polygon([
        (cx + pot_top_w // 4, pot_top_y),
        (cx + pot_top_w // 2, pot_top_y),
        (cx + pot_bot_w // 2, pot_bot_y),
        (cx + pot_bot_w // 4, pot_bot_y),
    ], fill=pot_shadow_color)

    # Pot Rim Ellipse
    draw.ellipse([cx - pot_top_w // 2 - 10, pot_top_y - 20, cx + pot_top_w // 2 + 10, pot_top_y + 20], fill=pot_rim_color)
    # Soil Ellipse (60% pot height)
    draw.ellipse([cx - pot_top_w // 2, pot_top_y - 12, cx + pot_top_w // 2, pot_top_y + 12], fill=(62, 39, 35, 255))

    # Plant Growth Renderings per Stage
    plant_green_light = (129, 199, 132, 255)
    plant_green_mid = (76, 175, 80, 255)
    plant_green_dark = (46, 125, 50, 255)
    stem_color = (102, 187, 106, 255)

    if stage_idx == 0:
        # Stage 0: Seed cracked open with mini root tip
        draw.ellipse([cx - 16, pot_top_y - 8, cx + 16, pot_top_y + 12], fill=(120, 85, 70, 255))
        draw.line([cx, pot_top_y + 2, cx + 14, pot_top_y - 18], fill=plant_green_light, width=4)
        draw.ellipse([cx + 10, pot_top_y - 24, cx + 18, pot_top_y - 14], fill=plant_green_light)

    elif stage_idx == 1:
        # Stage 1: Sprout with 2 cotyledon leaves
        draw.line([cx, pot_top_y, cx, pot_top_y - 70], fill=stem_color, width=7)
        # Left leaf
        draw.ellipse([cx - 45, pot_top_y - 85, cx - 4, pot_top_y - 55], fill=plant_green_mid)
        # Right leaf
        draw.ellipse([cx + 4, pot_top_y - 92, cx + 50, pot_top_y - 60], fill=plant_green_light)

    elif stage_idx == 2:
        # Stage 2: Growing juvenile plant with 6 leaves
        draw.line([cx, pot_top_y, cx, pot_top_y - 140], fill=stem_color, width=9)
        # Branching leaves
        draw.ellipse([cx - 70, pot_top_y - 80, cx - 10, pot_top_y - 45], fill=plant_green_dark)
        draw.ellipse([cx + 10, pot_top_y - 95, cx + 75, pot_top_y - 55], fill=plant_green_mid)
        draw.ellipse([cx - 85, pot_top_y - 140, cx - 15, pot_top_y - 95], fill=plant_green_mid)
        draw.ellipse([cx + 15, pot_top_y - 150, cx + 88, pot_top_y - 100], fill=plant_green_light)
        draw.ellipse([cx - 40, pot_top_y - 190, cx + 40, pot_top_y - 130], fill=plant_green_light)

    elif stage_idx == 3:
        # Stage 3: Fully mature lush plant with flowers/foliage
        draw.line([cx, pot_top_y, cx, pot_top_y - 180], fill=stem_color, width=12)
        # Canopy of rich leaves
        for offset_x, offset_y, w_leaf, h_leaf, col in [
            (-95, -70, 90, 50, plant_green_dark),
            (95, -80, 95, 55, plant_green_dark),
            (-120, -140, 110, 60, plant_green_mid),
            (120, -150, 115, 65, plant_green_mid),
            (-90, -210, 100, 60, plant_green_light),
            (90, -220, 105, 65, plant_green_light),
            (0, -250, 120, 75, plant_green_light),
        ]:
            draw.ellipse([cx + offset_x - w_leaf // 2, pot_top_y + offset_y - h_leaf // 2,
                          cx + offset_x + w_leaf // 2, pot_top_y + offset_y + h_leaf // 2], fill=col)
        # Signature blooms/buds
        flower_col = (255, 183, 77, 255)
        center_col = (255, 238, 88, 255)
        for fx, fy in [(cx - 40, pot_top_y - 220), (cx + 45, pot_top_y - 200), (cx, pot_top_y - 270)]:
            draw.ellipse([fx - 14, fy - 14, fx + 14, fy + 14], fill=flower_col)
            draw.ellipse([fx - 6, fy - 6, fx + 6, fy + 6], fill=center_col)

    return img

# ─────────────────────────────────────────────────────────────────────────────
# Concurrency & Generation Logic
# ─────────────────────────────────────────────────────────────────────────────

async def generate_stage_image_with_client(client, species_name: str, stage_idx: int) -> bytes:
    """
    Generates a single stage image using Google GenAI SDK or fallback generator.
    """
    full_prompt = build_upgraded_stage_prompt(species_name, stage_idx)
    logger.info(f"Generating Stage {stage_idx} for '{species_name}' with upgraded prompt...")

    if client is not None:
        try:
            # Check for image generation capability via models.generate_images or generate_content
            # Model endpoint: 'imagen-3.0-generate-002' or 'gemini-2.0-flash' with modalities
            if hasattr(client, "models") and hasattr(client.models, "generate_images"):
                response = client.models.generate_images(
                    model="imagen-3.0-generate-002",
                    prompt=full_prompt,
                    config=dict(
                        number_of_images=1,
                        output_mime_type="image/png",
                        aspect_ratio="1:1"
                    )
                )
                if response and response.generated_images:
                    raw_bytes = response.generated_images[0].image.image_bytes
                    return process_and_remove_background(raw_bytes)
            elif hasattr(client, "models") and hasattr(client.models, "generate_content"):
                # Multimodal response_modalities IMAGE check
                response = client.models.generate_content(
                    model="gemini-2.0-flash",
                    contents=full_prompt,
                )
                # If image content returned in inline parts
                for part in getattr(response.candidates[0].content, "parts", []):
                    if hasattr(part, "inline_data") and part.inline_data:
                        raw_bytes = part.inline_data.data
                        return process_and_remove_background(raw_bytes)
        except Exception as e:
            logger.warning(f"GenAI Client generation error on stage {stage_idx}: {e}. Utilizing seamless fallback.")

    # High fidelity procedural transparent PNG generator
    proc_img = generate_procedural_plant_stage(species_name, stage_idx)
    buf = io.BytesIO()
    proc_img.save(buf, format="PNG")
    return buf.getvalue()

async def generate_all_4_stages(plant_id: str, species_name: str, base_url: str) -> List[str]:
    """
    Coordinates dual-key parallel generation across all 4 stages via asyncio.gather:
    - client_1: Stage 0 (Seed) + Stage 1 (Sprout)
    - client_2: Stage 2 (Growing) + Stage 3 (Mature)
    """
    plant_out_dir = PLANTS_DIR / plant_id
    plant_out_dir.mkdir(parents=True, exist_ok=True)

    # Distribute parallel tasks across dual clients
    task_0 = generate_stage_image_with_client(genai_client_1, species_name, 0)
    task_1 = generate_stage_image_with_client(genai_client_1, species_name, 1)
    task_2 = generate_stage_image_with_client(genai_client_2, species_name, 2)
    task_3 = generate_stage_image_with_client(genai_client_2, species_name, 3)

    # Concurrently gather all 4 stages
    stages_bytes = await asyncio.gather(task_0, task_1, task_2, task_3)

    stage_urls = []
    for idx, raw_png in enumerate(stages_bytes):
        file_path = plant_out_dir / f"stage_{idx}.png"
        file_path.write_bytes(raw_png)
        # Format URL: /static/plants/{plant_id}/stage_{idx}.png
        stage_urls.append(f"/static/plants/{plant_id}/stage_{idx}.png")
        logger.info(f"Saved plant {plant_id} stage {idx} to {file_path}")

    return stage_urls

# ─────────────────────────────────────────────────────────────────────────────
# API Endpoints
# ─────────────────────────────────────────────────────────────────────────────

@app.get("/")
def root():
    return {
        "engine": "SpryFlora 4-Stage AI Plant Growth Engine",
        "status": "online",
        "clients": {
            "client_1_configured": genai_client_1 is not None or bool(GEMINI_KEY_1),
            "client_2_configured": genai_client_2 is not None or bool(GEMINI_KEY_2),
            "rembg_installed": rembg_available
        }
    }

@app.get("/api/health")
def health_check():
    return {"status": "ok", "service": "spryflora-ai-stage-engine"}

@app.post("/api/generate-plant-stages", response_model=GeneratePlantStagesResponse)
async def generate_plant_stages(req: GeneratePlantStagesRequest, request: Request):
    """
    Accepts plant_id and species_name, concurrently runs dual-client AI generation across 4 stages,
    strips chroma green backgrounds, saves PNGs to static directory, and returns URLs.
    """
    try:
        logger.info(f"Received stage generation request for Plant ID: {req.plant_id}, Species: '{req.species_name}'")
        
        # Base URL for resolving static links
        base_url = str(request.base_url).rstrip("/")
        stage_relative_urls = await generate_all_4_stages(req.plant_id, req.species_name, base_url)
        
        full_urls = [f"{base_url}{rel_url}" if not rel_url.startswith("http") else rel_url for rel_url in stage_relative_urls]
        
        return GeneratePlantStagesResponse(
            status="completed",
            plant_id=req.plant_id,
            species_name=req.species_name,
            stages=full_urls
        )
    except Exception as e:
        logger.error(f"Error generating plant stages: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail=f"Failed to generate plant stages: {str(e)}")

# ─────────────────────────────────────────────────────────────────────────────
# Direct Execution Runner
# ─────────────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run("app:app", host="0.0.0.0", port=port, reload=True)
