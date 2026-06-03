from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
import shutil
import os
import time
from pathlib import Path
from typing import Optional

from app.services.groq_service import analyze_plant_with_groq

app = FastAPI(title="AgroVision AI Backend")
BASE_DIR = Path(__file__).resolve().parent

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

temp_dir_groq = BASE_DIR / "temp_scans"
os.makedirs(temp_dir_groq, exist_ok=True)

@app.get("/")
def health_check():
    return {"status": "AgroVision backend activo ✅", "message": "API Ligera funcionando sin PyTorch 🚀"}

# ELIMINAMOS EL ENDPOINT /predict. Todo pasa directo por /analyze.

@app.post("/analyze")
async def analyze_image(
    image: UploadFile = File(...),
    latitude: Optional[float] = Form(None),
    longitude: Optional[float] = Form(None),
    location_name: Optional[str] = Form(None),
    scan_id: Optional[str] = Form(None),
    yolo_disease: Optional[str] = Form(None), 
    yolo_plant: Optional[str] = Form(None), # NUEVO: Recibe el tipo de planta del celular
):
    temp_file_path = None
    try:
        temp_file_path = os.path.join(temp_dir_groq, f"{scan_id or int(time.time())}_{image.filename}")
        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)

        # Pasamos ambos datos locales a Groq
        ia_result = analyze_plant_with_groq(temp_file_path, yolo_disease, yolo_plant)

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
        print(f"🚨 ERROR EN MAIN: {e}")
        return {
            "id": "error", "disease_class": "Unknown", "diseaseName": "Error",
            "confidence": 0.0, "description": "Error conectando con la IA.",
            "treatment": "Verifica tu conexión y tokens.", "is_plant": True,
        }
    finally:
        if temp_file_path and os.path.exists(temp_file_path):
            os.remove(temp_file_path)