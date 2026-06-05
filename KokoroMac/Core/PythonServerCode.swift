import Foundation

let pythonServerScript = #"""
import os
import re
import gc
import time
import asyncio
import warnings
import uvicorn
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from kokoro import KPipeline
import soundfile as sf
import torch

warnings.filterwarnings("ignore", category=UserWarning)
warnings.filterwarnings("ignore", category=FutureWarning)

app = FastAPI()
pipelines = {}
last_request_time = time.time()
COOLDOWN_SECONDS = 300  # 5 minutes

class TTSRequest(BaseModel):
    text: str
    voice: str
    lang_code: str
    file_id: str
    speed: float = 1.0

@app.get("/health")
def health():
    return {"status": "ok"}

@app.post("/generate")
def generate_audio(req: TTSRequest):
    global last_request_time
    last_request_time = time.time()
    
    try:
        if req.lang_code not in pipelines:
            pipelines[req.lang_code] = KPipeline(lang_code=req.lang_code, repo_id='hexgrad/Kokoro-82M')
        
        pipeline = pipelines[req.lang_code]
        output_path = os.path.join(os.path.expanduser("~"), ".KokoroMac", "Temp", f"{req.file_id}.wav")
        
        text = req.text
        
        # Fix apostrophe 's' pronunciation (e.g., father's -> fatherz)
        text = re.sub(r"(\w)'s\b", r"\1z", text)
        
        # Ensure phoneme overrides [word](/ipa/) have proper spacing for Kokoro's parser
        text = re.sub(r'(?<![\s\[])(\[.*?\]\(/.*?/\))', r' \1', text)
        text = re.sub(r'(\[.*?\]\(/.*?/\))(?![\s\.\,\!\?\:\;\)])', r'\1 ', text)
        
        if os.path.exists(output_path):
            os.remove(output_path)
            
        with torch.inference_mode():
            generator = pipeline(text, voice=req.voice, speed=req.speed)
            
            with sf.SoundFile(output_path, mode='w', samplerate=24000, channels=1, subtype='PCM_16') as f:
                for gs, ps, audio in generator:
                    if audio is not None and len(audio) > 0:
                        f.write(audio)
                        del gs, ps, audio
                        
        gc.collect()
        if torch.backends.mps.is_available():
            torch.mps.empty_cache()
            
        return {"status": "success", "file": output_path}
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(memory_cooldown_task())

async def memory_cooldown_task():
    global pipelines, last_request_time
    while True:
        await asyncio.sleep(60)
        if time.time() - last_request_time > COOLDOWN_SECONDS and pipelines:
            print("🧹 [Server] No requests for 5 minutes. Unloading models to free memory...")
            pipelines.clear()
            gc.collect()
            if torch.backends.mps.is_available():
                torch.mps.empty_cache()
            print("✅ [Server] Models unloaded. Memory freed.")

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8080)
"""#
