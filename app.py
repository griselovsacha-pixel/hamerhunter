from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect, BackgroundTasks
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
import threading
import uuid
import asyncio
from scanner import ScannerEngine
from knowledge_base import FIXES

app = FastAPI(title="Hamer Hunter Web")
app.mount("/static", StaticFiles(directory="static"), name="static")
templates = Jinja2Templates(directory="templates")

# Хранилище задач в памяти
tasks = {}
results = {}

@app.on_event("startup")
def start_worker():
    engine = ScannerEngine()
    def worker_loop():
        while True:
            # Простая очередь на основе списка (для демонстрации)
            if tasks:
                task_id, url = list(tasks.items())[0]
                del tasks[task_id]
                results[task_id] = {"status": "running"}
                # Выполняем сканирование
                findings = engine.full_scan(url)
                # Добавляем рекомендации
                for f in findings:
                    f["fix"] = FIXES.get(f.get("type", ""), "Следуйте лучшим практикам безопасности")
                results[task_id] = {"status": "completed", "findings": findings}
            else:
                threading.Event().wait(1)  # ждём, чтобы не грузить CPU
    t = threading.Thread(target=worker_loop, daemon=True)
    t.start()

@app.get("/", response_class=HTMLResponse)
async def index(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

@app.post("/scan")
async def start_scan(url: str):
    if not url.startswith(("http://", "https://")):
        raise HTTPException(400, "Invalid URL")
    task_id = str(uuid.uuid4())
    tasks[task_id] = url
    results[task_id] = {"status": "queued"}
    return {"task_id": task_id}

@app.get("/scan/{task_id}")
async def get_status(task_id: str):
    if task_id not in results:
        raise HTTPException(404, "Task not found")
    return results[task_id]

@app.websocket("/ws/{task_id}")
async def websocket_endpoint(websocket: WebSocket, task_id: str):
    await websocket.accept()
    try:
        while True:
            if task_id in results:
                data = results[task_id]
                await websocket.send_json(data)
                if data["status"] == "completed":
                    break
            await asyncio.sleep(1)
    except WebSocketDisconnect:
        pass
