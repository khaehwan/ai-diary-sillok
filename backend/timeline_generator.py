"""타임라인 생성기 - 일일 데이터를 분석하여 이벤트 타임라인 생성"""

import io
import os
import uuid
import json
import base64
import aiohttp
from datetime import datetime, date, timedelta
from pathlib import Path
from typing import Optional

from openai import AsyncOpenAI
from PIL import Image

try:
    from pillow_heif import register_heif_opener

    register_heif_opener()
except ImportError:
    pass

from models import DailyData, Event, Timeline, Selfsurvey, Photo, Location, Notification

LOG_DIR = Path(__file__).parent / "log"


def extract_exif_data(image_data: bytes) -> dict:
    """이미지에서 EXIF 메타데이터 추출 (timestamp, gps)"""
    result = {"timestamp": None, "gps": None}

    try:
        image = Image.open(io.BytesIO(image_data))
        exif_data = image.getexif()

        if not exif_data:
            return result

        exif_ifd = exif_data.get_ifd(0x8769) if hasattr(exif_data, "get_ifd") else {}

        datetime_original = exif_ifd.get(36867)
        if datetime_original:
            try:
                result["timestamp"] = datetime.strptime(
                    datetime_original, "%Y:%m:%d %H:%M:%S"
                )
            except (ValueError, TypeError):
                pass

        if result["timestamp"] is None:
            datetime_tag = exif_data.get(306)
            if datetime_tag:
                try:
                    result["timestamp"] = datetime.strptime(
                        datetime_tag, "%Y:%m:%d %H:%M:%S"
                    )
                except (ValueError, TypeError):
                    pass

        gps_ifd = exif_data.get_ifd(0x8825) if hasattr(exif_data, "get_ifd") else {}

        if gps_ifd:
            lat_ref = gps_ifd.get(1)
            lat_data = gps_ifd.get(2)
            lng_ref = gps_ifd.get(3)
            lng_data = gps_ifd.get(4)

            if lat_data and lng_data:
                lat = _convert_to_degrees(lat_data)
                lng = _convert_to_degrees(lng_data)

                if lat_ref == "S":
                    lat = -lat
                if lng_ref == "W":
                    lng = -lng

                result["gps"] = {"lat": lat, "lng": lng}

    except Exception as e:
        print(f"EXIF 추출 실패: {e}")

    return result


def _convert_to_degrees(value) -> float:
    """GPS 좌표를 DMS에서 십진수로 변환"""
    try:
        if hasattr(value[0], "numerator"):
            d = float(value[0].numerator) / float(value[0].denominator)
            m = float(value[1].numerator) / float(value[1].denominator)
            s = float(value[2].numerator) / float(value[2].denominator)
        else:
            d, m, s = float(value[0]), float(value[1]), float(value[2])

        return d + (m / 60.0) + (s / 3600.0)
    except (TypeError, ZeroDivisionError, IndexError):
        return 0.0


class TimelineGenerator:
    """DailyData -> Timeline 생성 (GPT-4.1 멀티모달)"""

    def __init__(self, api_key: Optional[str] = None, base_url: Optional[str] = None):
        self.api_key = api_key or os.getenv("OPENAI_API_KEY")
        if not self.api_key:
            raise ValueError("OPENAI_API_KEY is required")
        self.client = AsyncOpenAI(api_key=self.api_key)
        self.model = "gpt-4.1"
        self.base_url = base_url or os.getenv("API_BASE_URL", "http://localhost:8000")

    async def generate(
        self, daily_data: DailyData, target_date: Optional[date] = None
    ) -> Timeline:
        """DailyData로 Timeline 생성"""
        target_date = target_date or date.today()

        image_contents, daily_data = await self._fetch_images_with_exif(
            daily_data, target_date
        )
        text_prompt = self._build_prompt(daily_data, target_date)
        raw_events = await self._call_gpt_multimodal(text_prompt, image_contents)
        events = self._parse_events(raw_events, daily_data, target_date)
        timeline_title = await self._generate_title(events, target_date)

        timeline = Timeline(
            id=f"timeline-{target_date.isoformat()}",
            title=timeline_title,
            date=target_date,
            events=events,
            selfsurvey=Selfsurvey(),
        )

        self._save_to_log(timeline)
        return timeline

    def _save_to_log(self, timeline: Timeline) -> None:
        """타임라인을 JSON 로그 파일로 저장"""
        LOG_DIR.mkdir(parents=True, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{timestamp}_timeline.json"
        filepath = LOG_DIR / filename

        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(timeline.model_dump(mode="json"), f, ensure_ascii=False, indent=2)

    async def _fetch_images_with_exif(
        self, daily_data: DailyData, target_date: date  # noqa: ARG002
    ) -> tuple[list[dict], DailyData]:
        """이미지 다운로드, EXIF 추출, DailyData 업데이트"""
        image_contents = []
        updated_photos = []
        new_locations = []

        async with aiohttp.ClientSession() as session:
            for photo in daily_data.gallery:
                try:
                    url = photo.url
                    if url.startswith("/"):
                        url = f"{self.base_url}{url}"

                    async with session.get(url) as response:
                        if response.status == 200:
                            image_data = await response.read()
                            content_type = response.headers.get(
                                "Content-Type", "image/jpeg"
                            )

                            exif_info = extract_exif_data(image_data)

                            photo_timestamp = photo.timestamp
                            if photo_timestamp is None and exif_info["timestamp"]:
                                photo_timestamp = exif_info["timestamp"]
                                print(
                                    f"EXIF에서 timestamp 추출: {photo.url} -> {photo_timestamp}"
                                )

                            updated_photo = Photo(
                                url=photo.url, timestamp=photo_timestamp
                            )
                            updated_photos.append(updated_photo)

                            if exif_info["gps"] and photo_timestamp:
                                new_location = Location(
                                    lat=exif_info["gps"]["lat"],
                                    lng=exif_info["gps"]["lng"],
                                    timestamp=photo_timestamp,
                                    place_name=None,
                                )
                                new_locations.append(new_location)
                                print(
                                    f"EXIF에서 GPS 추출: {photo.url} -> {exif_info['gps']}"
                                )

                            gpt_image_data = image_data
                            gpt_media_type = content_type
                            ext = (
                                photo.url.lower().split(".")[-1]
                                if "." in photo.url
                                else ""
                            )
                            if ext in ("heic", "heif") or content_type in (
                                "image/heic",
                                "image/heif",
                            ):
                                try:
                                    img = Image.open(io.BytesIO(image_data))
                                    if img.mode in ("RGBA", "P"):
                                        img = img.convert("RGB")
                                    output = io.BytesIO()
                                    img.save(output, format="JPEG", quality=90)
                                    gpt_image_data = output.getvalue()
                                    gpt_media_type = "image/jpeg"
                                    print(f"HEIC -> JPEG 변환: {photo.url}")
                                except Exception as conv_err:
                                    print(f"HEIC 변환 실패: {conv_err}")

                            b64_data = base64.b64encode(gpt_image_data).decode("utf-8")

                            image_contents.append(
                                {
                                    "url": photo.url,
                                    "timestamp": photo_timestamp,
                                    "base64": b64_data,
                                    "media_type": gpt_media_type,
                                }
                            )
                        else:
                            updated_photos.append(photo)
                except Exception as e:
                    print(f"이미지 다운로드 실패 {photo.url}: {e}")
                    updated_photos.append(photo)
                    continue

        merged_locations = list(daily_data.location)
        for new_loc in new_locations:
            is_duplicate = False
            for existing_loc in merged_locations:
                new_ts = self._normalize_datetime(new_loc.timestamp)
                existing_ts = self._normalize_datetime(existing_loc.timestamp)
                time_diff = abs((new_ts - existing_ts).total_seconds())
                dist_diff = abs(new_loc.lat - existing_loc.lat) + abs(
                    new_loc.lng - existing_loc.lng
                )
                if time_diff < 300 and dist_diff < 0.001:
                    is_duplicate = True
                    break
            if not is_duplicate:
                merged_locations.append(new_loc)

        merged_locations.sort(key=lambda x: self._normalize_datetime(x.timestamp))

        updated_daily_data = DailyData(
            gallery=updated_photos,
            location=merged_locations,
            appnoti=daily_data.appnoti,
        )

        return image_contents, updated_daily_data

    def _build_prompt(self, daily_data: DailyData, target_date: date) -> str:
        """GPT 분석용 프롬프트 생성"""
        lines = [
            f"# {target_date.strftime('%Y년 %m월 %d일')} 일과 분석",
            "",
            "아래 수집된 데이터를 바탕으로 이 날 있었던 주요 이벤트들을 추론해주세요.",
            "",
        ]

        if daily_data.location:
            lines.append("## 위치 데이터")
            for loc in sorted(
                daily_data.location, key=lambda x: self._normalize_datetime(x.timestamp)
            ):
                time_str = loc.timestamp.strftime("%H:%M")
                place_info = f" ({loc.place_name})" if loc.place_name else ""
                lines.append(
                    f"- [{time_str}] 위도: {loc.lat:.4f}, 경도: {loc.lng:.4f}{place_info}"
                )
            lines.append("")

        if daily_data.appnoti:
            lines.append("## 앱 알림 데이터")
            for noti in sorted(
                daily_data.appnoti, key=lambda x: self._normalize_datetime(x.timestamp)
            ):
                time_str = noti.timestamp.strftime("%H:%M")
                lines.append(f"- [{time_str}] {noti.appname}: {noti.text}")
            lines.append("")

        if daily_data.gallery:
            lines.append("## 사진 데이터")
            lines.append(
                "(사진 이미지는 아래에 첨부되어 있습니다. 각 사진을 분석하여 이벤트를 추론해주세요.)"
            )
            for i, photo in enumerate(daily_data.gallery):
                if photo.timestamp:
                    time_str = photo.timestamp.strftime("%H:%M")
                    lines.append(f"- 사진 {i + 1}: [{time_str}] 촬영")
                else:
                    lines.append(f"- 사진 {i + 1}: 시간 미상")
            lines.append("")

        return "\n".join(lines)

    async def _call_gpt_multimodal(
        self, text_prompt: str, image_contents: list[dict]
    ) -> list[dict]:
        """GPT-4.1 멀티모달 호출 (텍스트 + 이미지)"""
        system_prompt = """당신은 일기 앱의 타임라인 생성 AI입니다.
사용자의 하루 데이터(위치, 알림, 사진)를 분석하여 그 날 있었던 주요 이벤트들을 추론합니다.

사진이 첨부된 경우:
- 사진 내용을 자세히 분석하여 장소, 활동, 음식, 사람 등을 파악하세요
- 사진의 촬영 시간과 내용을 바탕으로 이벤트를 생성하세요
- 사진에서 보이는 구체적인 내용을 이벤트 설명에 반영하세요

다음 JSON 형식으로 이벤트 배열을 반환해주세요:
```json
{
  "events": [
    {
      "timestamp": "2025-01-15T09:00:00",
      "title": "이벤트 제목 (간단명료하게)",
      "content": "이벤트 상세 설명 (2-3문장, 사진 내용 포함)"
    }
  ]
}
```

규칙:
1. 사진 내용을 적극적으로 분석하여 구체적인 이벤트 생성
2. 데이터에서 추론 가능한 이벤트만 생성 (과도한 추측 금지)
3. 시간순으로 정렬
4. 3-7개의 주요 이벤트 추출
5. 제목은 10자 이내로 간결하게
6. 내용은 자연스러운 한국어로
7. feeling 필드는 생성하지 마세요 (사용자가 입력)

반드시 JSON 객체를 반환하세요."""

        user_content = []
        user_content.append({"type": "text", "text": text_prompt})

        for i, img in enumerate(image_contents):
            timestamp_str = ""
            if img["timestamp"]:
                timestamp_str = f" (촬영: {img['timestamp'].strftime('%H:%M')})"

            user_content.append(
                {"type": "text", "text": f"\n[사진 {i + 1}{timestamp_str}]:"}
            )

            user_content.append(
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:{img['media_type']};base64,{img['base64']}",
                        "detail": "auto",
                    },
                }
            )

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_content},
            ],
            temperature=0.7,
            max_tokens=2000,
        )

        content = response.choices[0].message.content

        try:
            result = json.loads(content)
        except json.JSONDecodeError:
            import re

            json_match = re.search(r"```json?\s*([\s\S]*?)\s*```", content)
            if json_match:
                result = json.loads(json_match.group(1))
            else:
                return []

        if isinstance(result, dict) and "events" in result:
            return result["events"]
        elif isinstance(result, list):
            return result
        else:
            return []

    def _parse_events(
        self, raw_events: list[dict], daily_data: DailyData, target_date: date
    ) -> list[Event]:
        """GPT 출력을 Event 객체로 변환"""
        events = []

        for i, raw in enumerate(raw_events):
            timestamp = self._parse_timestamp(
                raw.get("timestamp", ""), target_date, fallback_hour=9 + i * 2
            )
            event_daily_data = self._filter_daily_data_for_event(daily_data, timestamp)

            event = Event(
                id=f"evt-{uuid.uuid4().hex[:8]}",
                timestamp=timestamp,
                title=raw.get("title", f"이벤트 {i + 1}"),
                content=raw.get("content", ""),
                feeling=None,  # User fills this
                dailydata=event_daily_data,
            )
            events.append(event)

        return events

    def _parse_timestamp(
        self, timestamp_str: str, target_date: date, fallback_hour: int
    ) -> datetime:
        """timestamp 문자열을 datetime으로 변환"""
        try:
            dt = datetime.fromisoformat(timestamp_str.replace("Z", "+00:00"))
            return dt
        except (ValueError, AttributeError):
            return datetime.combine(
                target_date, datetime.min.time().replace(hour=min(fallback_hour, 23))
            )

    def _normalize_datetime(self, dt: datetime) -> datetime:
        """timezone 제거 (naive datetime으로 변환)"""
        if dt.tzinfo is not None:
            return dt.replace(tzinfo=None)
        return dt

    def _filter_daily_data_for_event(
        self, daily_data: DailyData, event_time: datetime, window_minutes: int = 30
    ) -> DailyData:
        """이벤트 시간 전후 window 내의 데이터만 필터링"""
        window = timedelta(minutes=window_minutes)
        event_time_naive = self._normalize_datetime(event_time)

        filtered_locations = [
            loc
            for loc in daily_data.location
            if abs(
                (
                    self._normalize_datetime(loc.timestamp) - event_time_naive
                ).total_seconds()
            )
            <= window.total_seconds()
        ][:3]

        filtered_notis = [
            noti
            for noti in daily_data.appnoti
            if abs(
                (
                    self._normalize_datetime(noti.timestamp) - event_time_naive
                ).total_seconds()
            )
            <= window.total_seconds()
        ][:5]

        filtered_photos = [
            photo
            for photo in daily_data.gallery
            if photo.timestamp
            and abs(
                (
                    self._normalize_datetime(photo.timestamp) - event_time_naive
                ).total_seconds()
            )
            <= window.total_seconds()
        ][:2]

        return DailyData(
            gallery=filtered_photos, location=filtered_locations, appnoti=filtered_notis
        )

    async def _generate_title(self, events: list[Event], target_date: date) -> str:
        """타임라인 제목 생성"""
        if not events:
            return f"{target_date.strftime('%Y년 %m월 %d일')}의 하루"

        event_summaries = [f"- {e.title}" for e in events[:5]]
        events_text = "\n".join(event_summaries)

        prompt = f"""다음 이벤트들을 요약하여 일기 제목을 만들어주세요.
제목은 15자 이내로 감성적이고 간결하게 작성해주세요.

이벤트:
{events_text}

제목만 반환해주세요 (따옴표 없이)."""

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.8,
            max_tokens=50,
        )

        title = response.choices[0].message.content.strip().strip("\"'")
        return title or f"{target_date.strftime('%Y년 %m월 %d일')}의 하루"


async def generate_timeline(
    daily_data: DailyData,
    target_date: Optional[date] = None,
    api_key: Optional[str] = None,
) -> Timeline:
    """DailyData로 Timeline 생성 (편의 함수)"""
    generator = TimelineGenerator(api_key=api_key)
    return await generator.generate(daily_data, target_date)
