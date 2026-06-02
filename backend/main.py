from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
import shutil
import os
import time
from pathlib import Path
from typing import Optional

from app.services.gemini_service import analyze_plant_with_gemini

# 1. Configuración Básica
app = FastAPI(title="AgroVision AI Backend")
BASE_DIR = Path(__file__).resolve().parent

# 2. CORS (Permitir conexión desde Flutter)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 3. Cargar modelo YOLO (El código del equipo)
# Wrap en try-except por si no tienes el archivo best.pt descargado localmente
try:
    model = YOLO(str(BASE_DIR / "models_jet" / "best.pt"))
    print("✅ Modelo YOLO cargado correctamente.")
except Exception as e:
    print(f"⚠️ Aviso: No se pudo cargar el modelo YOLO local. Error: {e}")
    model = None

# Carpetas temporales
UPLOAD_FOLDER = BASE_DIR / "temp"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
temp_dir_gemini = BASE_DIR / "temp_scans"
os.makedirs(temp_dir_gemini, exist_ok=True)


# --- ENDPOINTS ---

# Ruta inicial (Health Check)
@app.get("/")
def health_check():
    return {"status": "AgroVision backend activo ✅", "message": "API funcionando 🚀"}


# Endpoint 1: Predicción con YOLO (Código del equipo)
@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    if model is None:
        return {"success": False, "message": "Modelo YOLO no disponible en el servidor."}

    # Guardar imagen temporalmente
    file_path = UPLOAD_FOLDER / file.filename
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Ejecutar predicción
    results = model(file_path)
    detections = []

    for result in results:
        boxes = result.boxes
        for box in boxes:
            class_id = int(box.cls[0])
            confidence = float(box.conf[0])
            disease_name = model.names[class_id]

            detections.append({
                "disease": disease_name,
                "confidence": round(confidence * 100, 2)
            })

    # Eliminar imagen temporal
    os.remove(file_path)

    if len(detections) == 0:
        return {"success": False, "message": "No se detectaron enfermedades"}

    return {"success": True, "detections": detections}


# Endpoint 2: Análisis con Gemini (Tu código protegido)
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
        temp_file_path = os.path.join(
            temp_dir_gemini, f"{scan_id or int(time.time())}_{image.filename}"
        )

        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)

        ia_result = analyze_plant_with_gemini(temp_file_path)

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