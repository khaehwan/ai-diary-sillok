"""
Data model
"""

from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel, Field


class Photo(BaseModel):
    """사진"""

    url: str  # 이미지 url(baseurl 제외) (ex. /api/v1/files/images/photo.jpg)
    timestamp: Optional[datetime] = None


class Location(BaseModel):
    """위치"""

    lat: float
    lng: float
    timestamp: datetime
    place_name: Optional[str] = None  # 장소 이름 (선택)


class Notification(BaseModel):
    """앱 알림(noti)"""

    appname: str
    text: str
    timestamp: datetime


class DailyData(BaseModel):
    """일상 수집 데이터"""

    gallery: list[Photo] = Field(default_factory=list)
    location: list[Location] = Field(default_factory=list)
    appnoti: list[Notification] = Field(default_factory=list)


class Selfsurvey(BaseModel):
    """사용자 입력 데이터"""

    mood: str = ""  # 기분
    draft: str = ""  # 일기 초안


class Event(BaseModel):
    """이벤트"""

    id: str
    timestamp: datetime
    title: str
    content: str
    feeling: Optional[str] = None  # "good" or "bad" or None
    dailydata: DailyData = Field(default_factory=DailyData)


class Timeline(BaseModel):
    """타임라인"""

    id: str
    title: str
    date: date
    events: list[Event] = Field(default_factory=list)
    selfsurvey: Selfsurvey = Field(default_factory=Selfsurvey)


class GeneratedImage(BaseModel):
    """생성된 이미지"""

    url: str  # 이미지 url(baseurl 제외)
    prompt: str = ""  # 이미지 생성 프롬프트


class GeneratedMusic(BaseModel):
    """생성된 음악"""

    url: str  # 음악 url(baseurl 제외)
    prompt: str = ""  # 음악 생성 프롬프트
    duration_seconds: int = 0


class DiaryContent(BaseModel):
    """일기 콘텐츠 (text, images, music)"""

    text: str = ""
    images: list[str] = Field(default_factory=list)  # 이미지url 리스트(여러개 대비)
    music: list[str] = Field(default_factory=list)  # 음악url 리스트(여러개 대비)
    image_prompts: list[str] = Field(default_factory=list)
    music_prompts: list[str] = Field(default_factory=list)


class Diary(BaseModel):
    """일기"""

    id: str
    timeline: Timeline
    title: str
    content: DiaryContent = Field(default_factory=DiaryContent)
    tag: list[str] = Field(default_factory=list)
