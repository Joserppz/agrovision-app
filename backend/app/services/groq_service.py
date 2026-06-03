import os
import base64
import json
import re
from groq import Groq
from dotenv import load_dotenv

load_dotenv()
client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

def encode_image(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

def analyze_plant_with_groq(image_path: str, yolo_disease: str = None) -> dict:
    try:
        base64_image = encode_image(image_path)
        
        prompt = "Eres una Inteligencia Artificial experta en botánica y fitopatología capaz de reconocer CUALQUIER especie del reino Plantae. Analiza esta imagen minuciosamente.\n"
        
        if yolo_disease and yolo_disease not in ["Desconocido", "Other"]:
            prompt += f"NOTA: El modelo matemático del sistema detectó: '{yolo_disease}'. Evalúa la imagen de forma independiente. Si NO coincide, descarta la sugerencia e identifica la ESPECIE REAL.\n"
        
        prompt += """
        Tu tarea es:
        1. Identificar EXACTAMENTE qué especie es.
        2. Clasificarla estrictamente en UNA de estas categorías: 'Fruta', 'Verdura', 'Flor', 'Planta'. (Si es un árbol o hierba usa 'Planta').
        3. Determinar su estado de salud.

        Devuelve ÚNICAMENTE un objeto JSON válido con esta estructura exacta (sin texto previo ni posterior):
        {
            "isPlant": true,
            "plantCategory": "Fruta", 
            "diseaseClass": "Nombre de la plaga en inglés o 'Healthy'",
            "diseaseName": "Nombre de la Especie - Estado (ej. Manzano - Sano)",
            "confidence": 0.95,
            "description": "Explica brevemente qué especie has identificado y por qué está sana o enferma.",
            "treatmentSteps": [
                "✂️ Acción Inmediata: [Qué hacer con la planta ahora mismo]",
                "🌱 Tratamiento Orgánico: [Solución casera o ecológica]",
                "🧪 Tratamiento Químico: [Fungicida recomendado]",
                "💧 Prevención: [Cómo ajustar el riego, luz o humedad]"
            ]
        }
        Si en la imagen NO hay absolutamente nada de vegetación, devuelve:
        {"isPlant": false}
        """

        chat_completion = client.chat.completions.create(
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}",
                            },
                        },
                    ],
                }
            ],
            model="meta-llama/llama-4-scout-17b-16e-instruct",
            temperature=0.0, 
        )
        
        response_text = chat_completion.choices[0].message.content.strip()
        match = re.search(r'\{.*\}', response_text, re.DOTALL)
        if match:
            json_str = match.group(0)
            return json.loads(json_str)
        else:
            raise ValueError(f"No se encontró un JSON válido. Respuesta IA: {response_text}")

    except Exception as e:
        print(f"🚨 Error en Groq Service: {e}")
        return {
            "isPlant": True,
            "plantCategory": "Planta",
            "diseaseClass": "Unknown",
            "diseaseName": "Error de Análisis IA",
            "confidence": 0.0,
            "description": "Hubo un problema procesando el diagnóstico con Inteligencia Artificial.",
            "treatmentSteps": ["Verifica la conexión a internet."]
        }