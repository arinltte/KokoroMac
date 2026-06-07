import Foundation

let pythonServerScript = #"""
import os
import re
import gc
import time
import asyncio
import warnings
import uvicorn
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from kokoro import KPipeline
import soundfile as sf
import torch
import numpy as np

warnings.filterwarnings("ignore", category=UserWarning)
warnings.filterwarnings("ignore", category=FutureWarning)

pipelines = {}
last_request_time = time.time()
COOLDOWN_SECONDS = 300
cooldown_task = None

# Modern FastAPI Lifespan Context Manager (Replaces deprecated on_event)
@asynccontextmanager
async def lifespan(app: FastAPI):
    global cooldown_task
    # Startup: Start the memory cooldown background task
    cooldown_task = asyncio.create_task(memory_cooldown_task())
    yield
    # Shutdown: Cancel the task and clear memory when app quits
    if cooldown_task:
        cooldown_task.cancel()
    pipelines.clear()
    gc.collect()
    if torch.backends.mps.is_available():
        torch.mps.empty_cache()

app = FastAPI(lifespan=lifespan)

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
        
        # 1. Normalize smart quotes
        text = text.replace("“", "\"").replace("”", "\"").replace("‘", "'").replace("’", "'")
        
        # 2. Fix apostrophe 's' pronunciation
        text = re.sub(r"([a-zA-Z])'s\b", r"\1z", text)
        
        # 3. Ensure phoneme overrides have proper spacing
        text = re.sub(r'(?<![\s\[])(\[.*?\]\(/.*?/\))', r' \1', text)
        text = re.sub(r'(\[.*?\]\(/.*?/\))(?![\s\.\,\!\?\:\;\)])', r'\1 ', text)
        
        # 4. Failsafe for plain-text pasted \u{FFFC} (Defaults to 1.0s Medium Pause)
        text = text.replace(chr(0xFFFC), "<PAUSE:1.0>")
        
        # Split text by <PAUSE:X> markers while keeping the delimiters
        parts = re.split(r'(<PAUSE:\d+(?:\.\d+)?>)', text)
        
        if os.path.exists(output_path):
            os.remove(output_path)
            
        # Stream directly to disk to avoid RAM duplication
        with sf.SoundFile(output_path, mode='w', samplerate=24000, channels=1, subtype='PCM_16') as f:
            with torch.inference_mode():
                for part in parts:
                    if part.startswith("<PAUSE:"):
                        duration = float(part[7:-1])
                        silence_samples = int(24000 * duration)
                        chunk_size = 24000 
                        for i in range(0, silence_samples, chunk_size):
                            f.write(np.zeros(min(chunk_size, silence_samples - i), dtype=np.float32))
                    else:
                        if not part.strip():
                            continue
                        
                        # Collect audio to trim natural AI trailing silence
                        part_audio_chunks = []
                        generator = pipeline(part, voice=req.voice, speed=req.speed)
                        for gs, ps, audio in generator:
                            if audio is not None and len(audio) > 0:
                                part_audio_chunks.append(audio)
                                del gs, ps, audio
                        
                        if part_audio_chunks:
                            full_part_audio = np.concatenate(part_audio_chunks)
                            
                            # Trim leading and trailing silence to prevent "double pauses"
                            threshold = 0.005
                            above_thresh = np.where(np.abs(full_part_audio) > threshold)[0]
                            
                            if len(above_thresh) > 0:
                                start_idx = above_thresh[0]
                                end_idx = above_thresh[-1] + 1
                                
                                # Add 50ms padding to prevent harsh cuts on fricatives/plosives
                                padding = int(24000 * 0.05)
                                start_idx = max(0, start_idx - padding)
                                end_idx = min(len(full_part_audio), end_idx + padding)
                                
                                trimmed_audio = full_part_audio[start_idx:end_idx]
                            else:
                                trimmed_audio = full_part_audio
                                
                            f.write(trimmed_audio)
                            del part_audio_chunks, full_part_audio, trimmed_audio
                                
        gc.collect()
        if torch.backends.mps.is_available():
            torch.mps.empty_cache()
            
        return {"status": "success", "file": output_path}
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

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
