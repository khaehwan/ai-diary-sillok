"""
Diary AI Backend - FastAPI Server
"""

import sys
from pathlib import Path
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.openapi.docs import get_redoc_html

# .env로드
load_dotenv(Path(__file__).parent.parent / ".env")
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

sys.path.insert(0, str(Path(__file__).parent.parent))

from routes import router

# 서버 저장소 경로
STORAGE_DIR = Path(__file__).parent.parent / "storage"


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler"""
    # 서버 저장소 유효성 검사
    STORAGE_DIR.mkdir(parents=True, exist_ok=True)
    (STORAGE_DIR / "images").mkdir(parents=True, exist_ok=True)
    (STORAGE_DIR / "music").mkdir(parents=True, exist_ok=True)

    yield

    # Shutdown: Cleanup if needed
    pass


app = FastAPI(
    title="Diary AI Backend",
    description="Timeline and Diary generation API using GPT-4.1",
    version="1.0.0",
    lifespan=lifespan,
    redoc_url=None,
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# api 접두사
app.include_router(router, prefix="/api/v1")

app.mount("/static", StaticFiles(directory=str(STORAGE_DIR)), name="static")


@app.get("/")
async def root():
    """Root endpoint with API information"""
    return {
        "message": "Diary AI Backend API",
        "version": "1.0.0",
        "docs": "/docs",
        "redoc": "/redoc",
        "endpoints": {
            "timeline": "/api/v1/timeline",
            "diary": "/api/v1/diary",
            "upload": "/api/v1/upload",
            "upload_image": "/api/v1/upload/image",
            "upload_music": "/api/v1/upload/music",
            "files": "/api/v1/files/{category}/{filename}",
            "static": "/static/{category}/{filename}",
            "health": "/api/v1/health",
        },
    }


@app.get("/api/v1/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy"}


@app.get("/redoc", include_in_schema=False)
async def redoc_html():
    """ReDoc with unpkg CDN (jsdelivr is blocked in some networks)"""
    return get_redoc_html(
        openapi_url="/openapi.json",
        title=app.title + " - ReDoc",
        redoc_js_url="https://unpkg.com/redoc@latest/bundles/redoc.standalone.js",
    )
