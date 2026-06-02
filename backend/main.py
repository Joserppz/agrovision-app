from fastapi import FastAPI, File, UploadFile, Form
from fastapi.middleware.cors import CORSMiddleware
import shutil
import os
import time
from typing import Optional

from app.services.gemini_service import analyze_plant_with_gemini

app = FastAPI(title="AgroVision AI Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def health_check():
    return {"status": "AgroVision backend activo ✅"}

@app.post("/analyze")
async def analyze_image(
    image: UploadFile = File(...),
    latitude: Optional[float] = Form(None),
    longitude: Optional[float] = Form(None),
    location_name: Optional[str] = Form(None),
    scan_id: Optional[str] = Form(None),
):
    temp_file_path = None
    try:
        # 1. Guardar imagen temporalmente
        temp_dir = "temp_scans"
        os.makedirs(temp_dir, exist_ok=True)
        temp_file_path = os.path.join(
            temp_dir, f"{scan_id or int(time.time())}_{image.filename}"
        )

        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)

        # 2. Analizar con Gemini
        ia_result = analyze_plant_with_gemini(temp_file_path)

        # 3. Respuesta — mapea al formato que espera scan_service.dart
        return {
            "id":            scan_id or f"scan_{int(time.time())}",
            "disease_class": ia_result.get("diseaseClass", "Other"),
            "diseaseName":   ia_result.get("diseaseName", "Desconocido"),
            "confidence":    ia_result.get("confidence", 0.0),
            "description":   ia_result.get("description", ""),
            "treatment":     "\n".join(ia_result.get("treatmentSteps", [])),
            "is_plant":      ia_result.get("isPlant", True),
            "timestamp":     time.strftime("%Y-%m-%dT%H:%M:%S"),
            "latitude":      latitude,
            "longitude":     longitude,
            "location_name": location_name or "Ubicación de campo",
        }

    except Exception as e:
        print(f"🚨 ERROR CRÍTICO EN MAIN: {e}")
        return {
            "id":            "error",
            "disease_class": "Unknown",
            "diseaseName":   "Servicio sobrecargado",
            "confidence":    0.0,
            "description":   "Estamos teniendo problemas. Intenta en 30 segundos.",
            "treatment":     "Verifica tu conexión\nEspera un momento\nIntenta de nuevo",
            "is_plant":      True,
            "timestamp":     time.strftime("%Y-%m-%dT%H:%M:%S"),
            "latitude":      latitude,
            "longitude":     longitude,
            "location_name": location_name or "Ubicación de campo",
        }

    finally:
        if temp_file_path and os.path.exists(temp_file_path):
            os.remove(temp_file_path)