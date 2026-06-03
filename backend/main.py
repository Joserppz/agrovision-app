from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
import shutil
import os
import time
from pathlib import Path
from typing import Optional

from app.services.groq_service import analyze_plant_with_groq

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
try:
    model = YOLO(str(BASE_DIR / "models_jet" / "best.pt"))
    print("✅ Modelo YOLO cargado correctamente.")
except Exception as e:
    print(f"⚠️ Aviso: No se pudo cargar el modelo YOLO local. Error: {e}")
    model = None

# Carpetas temporales
UPLOAD_FOLDER = BASE_DIR / "temp"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

temp_dir_groq = BASE_DIR / "temp_scans"
os.makedirs(temp_dir_groq, exist_ok=True)


# --- ENDPOINTS ---

# Ruta inicial (Health Check)
@app.get("/")
def health_check():
    return {"status": "AgroVision backend activo ✅", "message": "API funcionando 🚀"}


# Endpoint 1: Predicción con YOLO
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

    # Diccionario oficial extraído de Roboflow
    YOLO_CLASSES = {
        0: "Mancha Bacteriana (Bacterial Spot)",
        1: "Tizón Temprano (Early Blight)",
        2: "Sano (Healthy)",
        3: "Tizón Tardío (Late Blight)",
        4: "Moho de la Hoja (Leaf Mold)",
        5: "Mancha Foliar por Septoria (Septoria Leaf Spot)",
        6: "Mancha Blanca (Target Spot)",
        7: "Virus del Mosaico (Tomato Mosaic Virus)",
        8: "Araña Roja (Two Spotted Spider Mite)"
    }

    for result in results:
        boxes = result.boxes
        for box in boxes:
            class_id = int(box.cls[0])
            confidence = float(box.conf[0])
            
            disease_name = YOLO_CLASSES.get(class_id, "Desconocido")

            detections.append({
                "disease": disease_name,
                "confidence": round(confidence * 100, 2)
            })

    # Eliminar imagen temporal
    os.remove(file_path)

    if len(detections) == 0:
        return {"success": False, "message": "No se detectaron enfermedades"}

    return {"success": True, "detections": detections}


# Endpoint 2: Análisis con Groq
@app.post("/analyze")
async def analyze_image(
    image: UploadFile = File(...),
    latitude: Optional[float] = Form(None),
    longitude: Optional[float] = Form(None),
    location_name: Optional[str] = Form(None),
    scan_id: Optional[str] = Form(None),
    yolo_disease: Optional[str] = Form(None), # <-- NUEVO: Recibe el diagnóstico de YOLO
):
    temp_file_path = None
    try:
        temp_file_path = os.path.join(
            temp_dir_groq, f"{scan_id or int(time.time())}_{image.filename}"
        )

        with open(temp_file_path, "wb") as buffer:
            shutil.copyfileobj(image.file, buffer)

        # Pasamos yolo_disease a Groq para que evalúe si el modelo matemático tuvo razón
        ia_result = analyze_plant_with_groq(temp_file_path, yolo_disease)

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