"""타임라인/일기 생성 API 라우트"""

import sys
import json
import aiofiles
from pathlib import Path
from datetime import date
from typing import Optional

from fastapi import APIRouter, HTTPException, UploadFile, File
from fastapi.responses import FileResponse
from pydantic import BaseModel, Field

sys.path.insert(0, str(Path(__file__).parent.parent))

STORAGE_DIR = Path(__file__).parent.parent / "storage"

from models import DailyData, Timeline, Diary
from timeline_generator import generate_timeline
from diary_generator import generate_diary

router = APIRouter()


class TimelineRequest(BaseModel):
    """타임라인 생성 요청"""

    daily_data: DailyData
    target_date: Optional[date] = None

    class Config:
        json_schema_extra = {
            "example": {
                "daily_data": {
                    "gallery": [
                        {
                            "url": "/api/v1/files/images/coffee.jpg",
                            "timestamp": "2025-11-28T08:30:00+09:00",
                        },
                        {
                            "url": "/api/v1/files/images/sushi.heic",
                            "timestamp": "2025-11-28T17:04:16+09:00",
                        },
                        {
                            "url": "/api/v1/files/images/sunset.jpg",
                            "timestamp": "2025-11-28T18:00:00+09:00",
                        },
                    ],
                    "location": [
                        {
                            "lat": 37.5665,
                            "lng": 126.978,
                            "timestamp": "2025-11-28T09:00:00+09:00",
                        },
                        {
                            "lat": 37.57,
                            "lng": 126.985,
                            "timestamp": "2025-11-28T12:30:00+09:00",
                        },
                        {
                            "lat": 37.558,
                            "lng": 126.977,
                            "timestamp": "2025-11-28T18:00:00+09:00",
                        },
                    ],
                    "appnoti": [
                        {
                            "appname": "카카오톡",
                            "text": "친구: 오늘 점심 같이 먹을래?",
                            "timestamp": "2025-11-28T11:30:00+09:00",
                        },
                        {
                            "appname": "배달의민족",
                            "text": "주문하신 음식이 배달 완료되었습니다",
                            "timestamp": "2025-11-28T12:45:00+09:00",
                        },
                        {
                            "appname": "캘린더",
                            "text": "오후 3시 팀 미팅 알림",
                            "timestamp": "2025-11-28T14:50:00+09:00",
                        },
                    ],
                },
                "target_date": "2025-11-28",
            }
        }


class TimelineResponse(BaseModel):
    """타임라인 생성 응답"""

    success: bool
    data: Optional[Timeline] = None
    error: Optional[str] = None


class DiaryRequest(BaseModel):
    """일기 생성 요청"""

    timeline: Timeline
    generate_image: bool = False
    generate_music: bool = False
    image_style: str = "watercolor illustration"
    music_genre: str = "ambient"
    music_duration: int = 60

    class Config:
        json_schema_extra = {
            "example": {
                "timeline": {
                    "id": "timeline-2025-11-28",
                    "title": "노을빛 하루의 기록",
                    "date": "2025-11-28",
                    "events": [
                        {
                            "id": "evt-52124f7a",
                            "timestamp": "2025-11-28T08:30:00",
                            "title": "아침 커피",
                            "content": "아침 일찍 카페에서 아이스커피를 준비했습니다.",
                            "feeling": None,
                            "dailydata": {
                                "gallery": [
                                    {
                                        "url": "/api/v1/files/images/coffee.jpg",
                                        "timestamp": "2025-11-28T08:30:00+09:00",
                                    }
                                ],
                                "location": [
                                    {
                                        "lat": 37.5665,
                                        "lng": 126.978,
                                        "timestamp": "2025-11-28T09:00:00+09:00",
                                    }
                                ],
                                "appnoti": [],
                            },
                        },
                        {
                            "id": "evt-2acfd4c7",
                            "timestamp": "2025-11-28T12:45:00",
                            "title": "점심 배달",
                            "content": "점심시간에 배달음식을 주문했고, 음식이 도착했다는 알림을 받았습니다.",
                            "feeling": None,
                            "dailydata": {
                                "gallery": [],
                                "location": [
                                    {
                                        "lat": 37.57,
                                        "lng": 126.985,
                                        "timestamp": "2025-11-28T12:30:00+09:00",
                                    }
                                ],
                                "appnoti": [
                                    {
                                        "appname": "배달의민족",
                                        "text": "주문하신 음식이 배달 완료되었습니다",
                                        "timestamp": "2025-11-28T12:45:00+09:00",
                                    }
                                ],
                            },
                        },
                    ],
                    "selfsurvey": {"mood": "happy", "draft": "오늘은 생일"},
                },
                "generate_image": True,
                "generate_music": True,
            }
        }


class DiaryResponse(BaseModel):
    """일기 생성 응답"""

    success: bool
    data: Optional[Diary] = None
    error: Optional[str] = None


@router.post("/timeline", response_model=TimelineResponse)
async def create_timeline(request: TimelineRequest):
    """DailyData로 Timeline 생성"""
    print("#################### Timeline Request ####################")
    print(json.dumps(request.model_dump(), indent=2, ensure_ascii=False, default=str))
    print("############################################################")
    try:
        timeline = await generate_timeline(
            daily_data=request.daily_data, target_date=request.target_date
        )
        response = TimelineResponse(success=True, data=timeline)
        print("#################### Timeline Response ####################")
        print(
            json.dumps(response.model_dump(), indent=2, ensure_ascii=False, default=str)
        )
        print("############################################################")
        return response
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        return TimelineResponse(success=False, error=str(e))


@router.post("/diary", response_model=DiaryResponse)
async def create_diary(request: DiaryRequest):
    """Timeline으로 Diary 생성"""
    print("#################### Diary Request ####################")
    print(json.dumps(request.model_dump(), indent=2, ensure_ascii=False, default=str))
    print("############################################################")
    try:
        diary = await generate_diary(
            timeline=request.timeline,
            generate_image=request.generate_image,
            generate_music=request.generate_music,
        )
        response = DiaryResponse(success=True, data=diary)
        print("#################### Diary Response ####################")
        print(
            json.dumps(response.model_dump(), indent=2, ensure_ascii=False, default=str)
        )
        print("############################################################")
        return response
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        return DiaryResponse(success=False, error=str(e))


class FileUploadResponse(BaseModel):
    """파일 업로드 응답"""

    success: bool
    filename: str = ""
    url: str = ""
    error: Optional[str] = None


def get_unique_filename(directory: Path, original_filename: str) -> str:
    """중복 시 고유 파일명 생성"""
    stem = Path(original_filename).stem
    suffix = Path(original_filename).suffix

    if not (directory / original_filename).exists():
        return original_filename

    counter = 1
    while True:
        new_filename = f"{stem}_{counter}{suffix}"
        if not (directory / new_filename).exists():
            return new_filename
        counter += 1


def get_file_category(content_type: str, filename: str) -> str:
    """content type 또는 확장자로 파일 카테고리 결정"""
    if content_type:
        if content_type.startswith("image/"):
            return "images"
        elif content_type.startswith("audio/"):
            return "music"

    ext = Path(filename).suffix.lower()
    image_exts = {
        ".jpg",
        ".jpeg",
        ".png",
        ".gif",
        ".webp",
        ".bmp",
        ".svg",
        ".heic",
        ".heif",
    }
    audio_exts = {".mp3", ".wav", ".ogg", ".m4a", ".flac", ".aac"}

    if ext in image_exts:
        return "images"
    elif ext in audio_exts:
        return "music"

    return "files"


@router.post("/upload", response_model=FileUploadResponse)
async def upload_file(file: UploadFile = File(...)):
    """이미지 또는 오디오 파일 업로드"""
    try:
        category = get_file_category(file.content_type, file.filename)
        target_dir = STORAGE_DIR / category
        target_dir.mkdir(parents=True, exist_ok=True)

        unique_filename = get_unique_filename(target_dir, file.filename)
        filepath = target_dir / unique_filename

        async with aiofiles.open(filepath, "wb") as f:
            content = await file.read()
            await f.write(content)

        file_url = f"/api/v1/files/{category}/{unique_filename}"

        return FileUploadResponse(success=True, filename=unique_filename, url=file_url)
    except Exception as e:
        return FileUploadResponse(success=False, error=str(e))


@router.post("/upload/image", response_model=FileUploadResponse)
async def upload_image(file: UploadFile = File(...)):
    """이미지 파일 업로드"""
    valid_types = {
        "image/jpeg",
        "image/png",
        "image/gif",
        "image/webp",
        "image/bmp",
        "image/svg+xml",
        "image/heic",
        "image/heif",
    }
    valid_exts = {
        ".jpg",
        ".jpeg",
        ".png",
        ".gif",
        ".webp",
        ".bmp",
        ".svg",
        ".heic",
        ".heif",
    }

    ext = Path(file.filename).suffix.lower()
    if file.content_type not in valid_types and ext not in valid_exts:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid image format. Supported: {', '.join(valid_exts)}",
        )

    try:
        target_dir = STORAGE_DIR / "images"
        target_dir.mkdir(parents=True, exist_ok=True)

        unique_filename = get_unique_filename(target_dir, file.filename)
        filepath = target_dir / unique_filename

        async with aiofiles.open(filepath, "wb") as f:
            content = await file.read()
            await f.write(content)

        file_url = f"/api/v1/files/images/{unique_filename}"

        return FileUploadResponse(success=True, filename=unique_filename, url=file_url)
    except Exception as e:
        return FileUploadResponse(success=False, error=str(e))


@router.post("/upload/music", response_model=FileUploadResponse)
async def upload_music(file: UploadFile = File(...)):
    """오디오 파일 업로드"""
    valid_types = {
        "audio/mpeg",
        "audio/wav",
        "audio/ogg",
        "audio/mp4",
        "audio/flac",
        "audio/aac",
    }
    valid_exts = {".mp3", ".wav", ".ogg", ".m4a", ".flac", ".aac"}

    ext = Path(file.filename).suffix.lower()
    if file.content_type not in valid_types and ext not in valid_exts:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid audio format. Supported: {', '.join(valid_exts)}",
        )

    try:
        target_dir = STORAGE_DIR / "music"
        target_dir.mkdir(parents=True, exist_ok=True)

        unique_filename = get_unique_filename(target_dir, file.filename)
        filepath = target_dir / unique_filename

        async with aiofiles.open(filepath, "wb") as f:
            content = await file.read()
            await f.write(content)

        file_url = f"/api/v1/files/music/{unique_filename}"

        return FileUploadResponse(success=True, filename=unique_filename, url=file_url)
    except Exception as e:
        return FileUploadResponse(success=False, error=str(e))


@router.get("/files/{category}/{filename}")
async def get_file(category: str, filename: str):
    """파일 다운로드"""
    if category not in {"images", "music", "files"}:
        raise HTTPException(status_code=400, detail="Invalid category")

    filepath = STORAGE_DIR / category / filename
    print(filepath)
    if not filepath.exists():
        raise HTTPException(status_code=404, detail="File not found")

    ext = Path(filename).suffix.lower()
    media_types = {
        ".jpg": "image/jpeg",
        ".jpeg": "image/jpeg",
        ".png": "image/png",
        ".gif": "image/gif",
        ".webp": "image/webp",
        ".bmp": "image/bmp",
        ".svg": "image/svg+xml",
        ".heic": "image/heic",
        ".heif": "image/heif",
        ".mp3": "audio/mpeg",
        ".wav": "audio/wav",
        ".ogg": "audio/ogg",
        ".m4a": "audio/mp4",
        ".flac": "audio/flac",
        ".aac": "audio/aac",
    }

    media_type = media_types.get(ext, "application/octet-stream")

    return FileResponse(filepath, media_type=media_type, filename=filename)


@router.delete("/files/{category}/{filename}")
async def delete_file(category: str, filename: str):
    """파일 삭제"""
    if category not in {"images", "music", "files"}:
        raise HTTPException(status_code=400, detail="Invalid category")

    filepath = STORAGE_DIR / category / filename

    if not filepath.exists():
        raise HTTPException(status_code=404, detail="File not found")

    try:
        filepath.unlink()
        return {"success": True, "message": f"File {filename} deleted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
