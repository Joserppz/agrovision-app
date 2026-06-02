import os
import base64
import json
from groq import Groq
from dotenv import load_dotenv

# Cargar variables de entorno
load_dotenv()

# Instanciar el cliente usando la variable de entorno GROQ_API_KEY
client = Groq(api_key=os.environ.get("GROQ_API_KEY"))

def encode_image(image_path):
    """Convierte la imagen a Base64 para que Groq pueda leerla"""
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode('utf-8')

def analyze_plant_with_groq(image_path: str) -> dict:
    try:
        base64_image = encode_image(image_path)
        
        # Prompt maestro para forzar un JSON estricto
        prompt = """
        Eres un experto botánico y fitopatólogo. Analiza esta imagen.
        Devuelve ÚNICAMENTE un objeto JSON válido con esta estructura exacta, sin texto adicional ni bloques de código markdown:
        {
            "isPlant": true,
            "diseaseClass": "Nombre de la plaga en inglés (ej. Late-Blight) o 'Healthy'",
            "diseaseName": "Nombre común en español",
            "confidence": 0.90,
            "description": "Breve descripción de los síntomas",
            "treatmentSteps": ["Paso 1 del tratamiento", "Paso 2", "Paso 3"]
        }
        Si en la imagen NO hay una planta evidente, devuelve:
        {"isPlant": false}
        """

        # Petición a Groq Cloud
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
            temperature=0.1, # Temperatura baja para que sea muy preciso y estructurado
        )
        
        # Limpiar la respuesta por si la IA le pone ```json ... ```
        response_text = chat_completion.choices[0].message.content.strip()
        if response_text.startswith("```json"):
            response_text = response_text[7:]
        if response_text.endswith("```"):
            response_text = response_text[:-3]
            
        result_json = json.loads(response_text.strip())
        return result_json

    except Exception as e:
        print(f"🚨 Error en Groq Service: {e}")
        # Respuesta de emergencia si falla la API
        return {
            "isPlant": True,
            "diseaseClass": "Unknown",
            "diseaseName": "Error de Análisis",
            "confidence": 0.0,
            "description": "El servidor de inteligencia artificial está ocupado.",
            "treatmentSteps": ["Intenta tomar la foto nuevamente en unos segundos."]
        }