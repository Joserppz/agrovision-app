from __future__ import annotations

from pathlib import Path
import importlib.util
import sys


ROOT = Path(__file__).resolve().parent
MODEL_PATH = ROOT / "models_jet" / "best.pt"
MAIN_PATH = ROOT / "main.py"


def ok(message: str) -> None:
    print(f"✅ {message}")


def fail(message: str) -> None:
    print(f"❌ {message}")


def check_models_folder() -> bool:
    models_dir = ROOT / "models_jet"
    if not models_dir.is_dir():
        fail("La carpeta models_jet/ no existe")
        return False

    ok("La carpeta models_jet/ existe")
    return True


def check_model_file() -> bool:
    if not MODEL_PATH.is_file():
        fail("No se encontró models_jet/best.pt")
        return False

    size_mb = MODEL_PATH.stat().st_size / (1024 * 1024)
    ok(f"best.pt existe ({size_mb:.2f} MB)")
    return True


def check_ultralytics() -> bool:
    if importlib.util.find_spec("ultralytics") is None:
        fail("ultralytics no está instalado")
        return False

    try:
        from ultralytics import YOLO
    except Exception as error:  # pragma: no cover - diagnostic only
        fail(f"No se pudo importar ultralytics: {error}")
        return False

    try:
        YOLO(str(MODEL_PATH))
    except Exception as error:  # pragma: no cover - diagnostic only
        fail(f"El modelo no carga correctamente: {error}")
        return False

    ok("ultralytics está instalado y el modelo carga sin errores")
    return True


def check_main_configuration() -> bool:
    if not MAIN_PATH.is_file():
        fail("No se encontró main.py")
        return False

    content = MAIN_PATH.read_text(encoding="utf-8")
    required_fragments = [
        'BASE_DIR = Path(__file__).resolve().parent',
        'YOLO(str(BASE_DIR / "models_jet" / "best.pt"))',
        '@app.post("/predict")',
        '@app.get("/")',
    ]

    missing = [fragment for fragment in required_fragments if fragment not in content]
    if missing:
        fail("main.py no parece estar configurado como se espera")
        for fragment in missing:
            print(f"   - Falta: {fragment}")
        return False

    ok("main.py está configurado para cargar y exponer el modelo")
    return True


def main() -> int:
    print("Verificando integración del modelo AgroVision...\n")

    checks = [
        check_models_folder,
        check_model_file,
        check_ultralytics,
        check_main_configuration,
    ]

    passed = 0
    for check in checks:
        if check():
            passed += 1

    print(f"\nResultado: {passed}/{len(checks)} verificaciones correctas")

    if passed == len(checks):
        print("Todo está listo. Puedes ejecutar: uvicorn main:app --reload")
        return 0

    print("Revisa los errores anteriores antes de continuar.")
    return 1


if __name__ == "__main__":
    sys.exit(main())