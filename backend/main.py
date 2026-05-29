from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO
import shutil
import os

# Crear API
app = FastAPI()

# Permitir conexión desde Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Cargar modelo YOLO
model = YOLO("models_jet/best.pt")

# Carpeta temporal para imágenes
UPLOAD_FOLDER = "temp"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)


# Ruta inicial
@app.get("/")
def home():
    return {
        "message": "AgroVision API funcionando 🚀"
    }


# Endpoint de predicción
@app.post("/predict")
async def predict(file: UploadFile = File(...)):

    # Guardar imagen temporalmente
    file_path = f"{UPLOAD_FOLDER}/{file.filename}"

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

    # Si no detecta nada
    if len(detections) == 0:
        return {
            "success": False,
            "message": "No se detectaron enfermedades"
        }

    # Respuesta JSON
    return {
        "success": True,
        "detections": detections
    }