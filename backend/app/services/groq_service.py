import os
import base64
import json
import re
from groq import Groq
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

# Instanciar el cliente
client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

def encode_image(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

def analyze_plant_with_groq(image_path: str, yolo_disease: str = None) -> dict:
    try:
        base64_image = encode_image(image_path)
        
        # PROMPT UNIVERSAL PLANTAE
        prompt = "Eres una Inteligencia Artificial experta en botánica y fitopatología capaz de reconocer CUALQUIER especie del reino Plantae (frutas, verduras, árboles, suculentas, flores, hojas, etc.). Analiza esta imagen minuciosamente.\n"
        
        if yolo_disease and yolo_disease not in ["Desconocido", "Other"]:
            prompt += f"NOTA: El modelo matemático del sistema (enfocado en tomates) detectó: '{yolo_disease}'. Evalúa la imagen de forma independiente. Si la imagen NO es un tomate o NO coincide con esta enfermedad, descarta la sugerencia e identifica la ESPECIE REAL y su ESTADO REAL.\n"
        
        prompt += """
        Tu tarea es:
        1. Identificar EXACTAMENTE qué especie o cultivo es (ej. Manzana, Rosa, Lechuga, Monstera, Papa).
        2. Determinar si la planta está 'Sana' o si presenta alguna enfermedad/plaga.

        Devuelve ÚNICAMENTE un objeto JSON válido con esta estructura exacta (sin texto previo ni posterior):
        {
            "isPlant": true,
            "diseaseClass": "Nombre de la plaga en inglés o 'Healthy'",
            "diseaseName": "Nombre de la Especie - Estado (ej. Manzano - Sano, Rosal - Oídio, Tomate - Sano)",
            "confidence": 0.95,
            "description": "Explica brevemente qué especie has identificado y por qué está sana o enferma, detallando los signos visuales.",
            "treatmentSteps": [
                "✂️ Acción Inmediata: [Qué hacer con la planta ahora mismo]",
                "🌱 Tratamiento Orgánico: [Solución casera o ecológica]",
                "🧪 Tratamiento Químico: [Fungicida o fertilizante recomendado]",
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
        
        # EXTRACCIÓN BLINDADA
        match = re.search(r'\{.*\}', response_text, re.DOTALL)
        if match:
            json_str = match.group(0)
            result_json = json.loads(json_str)
            return result_json
        else:
            raise ValueError(f"No se encontró un JSON válido. Respuesta IA: {response_text}")

    except Exception as e:
        print(f"🚨 Error en Groq Service: {e}")
        return {
            "isPlant": True,
            "diseaseClass": "Unknown",
            "diseaseName": "Error de Análisis IA",
            "confidence": 0.0,
            "description": "Hubo un problema procesando el diagnóstico con Inteligencia Artificial.",
            "treatmentSteps": ["Verifica la conexión a internet.", "Intenta tomar la foto nuevamente."]
        }