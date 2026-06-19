@echo off
start "Backend AgroVision" cmd /k "cd backend && uvicorn main:app --host 0.0.0.0 --port 8000"
start "Frontend AgroVision" cmd /k "cd frontend && flutter run"

