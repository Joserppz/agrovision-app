import os
import json
import time
from PIL import Image
from google import genai
from dotenv import load_dotenv
load_dotenv()


GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "REEMPLAZA_CON_TU_KEY")

client = genai.Client(api_key=GEMINI_API_KEY)

SYSTEM_PROMPT = """Eres un agrónomo experto. Analiza la imagen que te envío.

Responde ÚNICAMENTE con un objeto JSON válido, sin texto adicional, sin bloques de código, sin explicaciones fuera del JSON.

Si es una planta (sana o enferma), usa este formato:
{
  "isPlant": true,
  "diseaseName": "nombre común de la enfermedad o 'Planta Sana'",
  "diseaseClass": "Late-Blight | Septoria-Leaf-Spot | Spider-Mites | Healthy | Other",
  "confidence": 0.85,
  "description": "descripción del estado de la planta en español",
  "treatmentSteps": ["paso 1", "paso 2", "paso 3"]
}

Si NO es una planta (objeto, persona, etc), usa:
{
  "isPlant": false,
  "diseaseName": "No es una planta",
  "diseaseClass": "Unknown",
  "confidence": 0.0,
  "description": "La imagen no corresponde a una planta.",
  "treatmentSteps": []
}

Reglas:
- Si la imagen es borrosa u oscura, haz tu mejor esfuerzo
- confidence entre 0.0 y 1.0
- treatmentSteps vacío si la planta está sana o no es planta
- Responde siempre en español excepto diseaseClass
- SOLO el JSON, nada más"""


def analyze_plant_with_gemini(image_path: str, retries: int = 3) -> dict:
    img = Image.open(image_path)

    for attempt in range(retries):
        try:
            response = client.models.generate_content(
                model='gemini-2.0-flash-lite',
                contents=[SYSTEM_PROMPT, img]
            )

            raw = response.text.strip()
            raw = raw.removeprefix('```json').removeprefix('```').removesuffix('```').strip()

            result = json.loads(raw)

            # Asegurar campos mínimos
            result.setdefault('isPlant', True)
            result.setdefault('diseaseName', 'Desconocido')
            result.setdefault('diseaseClass', 'Other')
            result.setdefault('confidence', 0.5)
            result.setdefault('description', '')
            result.setdefault('treatmentSteps', [])

            print(f"✅ Gemini respondió: {result['diseaseName']} ({result['confidence']})")
            return result

        except json.JSONDecodeError as e:
            print(f"⚠️ JSON inválido (intento {attempt+1}): {e}")
            if attempt < retries - 1:
                time.sleep(2)
                continue

        except Exception as e:
            error_str = str(e)
            if '429' in error_str and attempt < retries - 1:
                wait = (attempt + 1) * 15
                print(f"⏳ Rate limit — esperando {wait}s (intento {attempt+1})")
                time.sleep(wait)
                continue
            print(f"🚨 ERROR EN GEMINI: {e}")
            break

    return {
        "isPlant": True,
        "diseaseName": "Servidor en mantenimiento",
        "diseaseClass": "Unknown",
        "confidence": 0.0,
        "description": "El servidor está saturado. Intenta en unos segundos.",
        "treatmentSteps": ["Espera 30 segundos", "Verifica tu conexión", "Intenta otra vez"]
    }