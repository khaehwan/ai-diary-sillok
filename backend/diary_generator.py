"""DiaryGenerator - 텍스트, 이미지, 음악"""

import os
import uuid
import json
import base64
import asyncio
from datetime import datetime
from pathlib import Path
from typing import Optional

from openai import AsyncOpenAI, OpenAI

from models import Timeline, Diary, DiaryContent

STORAGE_DIR = Path(__file__).parent / "storage"
LOG_DIR = Path(__file__).parent / "log"


class DiaryTextGenerator:
    """타임라인 -> 일기 본문 생성 (gpt)"""

    def __init__(self, client: AsyncOpenAI):
        self.client = client
        self.model = "gpt-4.1"

    async def generate(self, timeline: Timeline) -> str:
        print("  [텍스트] 일기 본문 생성 중...")
        prompt = self._build_prompt(timeline)

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": self._get_system_prompt()},
                {"role": "user", "content": prompt},
            ],
            temperature=0.8,
            max_tokens=2000,
        )

        result = response.choices[0].message.content.strip()
        print("  [텍스트] 일기 본문 생성 완료")
        return result

    def _get_system_prompt(self) -> str:
        return """당신은 감성적인 일기 작가입니다.
사용자의 하루 타임라인을 바탕으로 따뜻하고 진솔한 일기를 작성합니다.

규칙:
1. 1인칭 시점으로 작성
2. 자연스럽고 감성적인 한국어 사용
3. 이벤트들을 시간 순서대로 자연스럽게 연결
4. 사용자의 기분(mood)과 초안(draft)이 있다면 반영
5. 300-500자 정도의 적당한 길이
6. 하루를 마무리하는 느낌으로 작성"""

    def _build_prompt(self, timeline: Timeline) -> str:
        lines = [
            f"# {timeline.date.strftime('%Y년 %m월 %d일')} 일기 작성",
            "",
        ]

        if timeline.selfsurvey.mood:
            lines.append(f"오늘의 기분: {timeline.selfsurvey.mood}")
        if timeline.selfsurvey.draft:
            lines.append(f"사용자 메모: {timeline.selfsurvey.draft}")
        lines.append("")
        lines.append("## 오늘의 이벤트")
        for event in timeline.events:
            time_str = event.timestamp.strftime("%H:%M")
            feeling = f" ({event.feeling})" if event.feeling else ""
            lines.append(f"- [{time_str}] {event.title}: {event.content}{feeling}")

        lines.append("")
        lines.append("위 정보를 바탕으로 오늘 하루를 정리하는 일기를 작성해주세요.")

        return "\n".join(lines)


class DiaryTitleGenerator:
    """일기 본문 -> 제목 생성 (gpt)"""

    def __init__(self, client: AsyncOpenAI):
        self.client = client
        self.model = "gpt-4.1"

    async def generate(self, diary_text: str, timeline: Timeline) -> str:
        print("  [제목] 일기 제목 생성 중...")
        prompt = f"""다음 일기 내용을 요약하여 제목을 만들어주세요.
제목은 15자 이내로 감성적이고 간결하게 작성해주세요.

일기 내용:
{diary_text[:500]}

제목만 반환해주세요 (따옴표 없이)."""

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.8,
            max_tokens=50,
        )

        title = response.choices[0].message.content.strip().strip("\"'")
        title = title or f"{timeline.date.strftime('%m월 %d일')}의 일기"
        print(f"  [제목] 생성 완료: {title}")
        return title


class DiaryTagGenerator:
    """일기 본문 -> 해시태그 생성 (gpt)"""

    def __init__(self, client: AsyncOpenAI):
        self.client = client
        self.model = "gpt-4.1"

    async def generate(self, diary_text: str, max_tags: int = 5) -> list[str]:
        print("  [태그] 해시태그 생성 중...")
        prompt = f"""다음 일기 내용에서 핵심 키워드를 추출하여 해시태그를 만들어주세요.

일기 내용:
{diary_text[:500]}

규칙:
1. {max_tags}개 이내의 태그
2. 각 태그는 1-2단어
3. # 없이 단어만
4. 쉼표로 구분

예시: 일상, 카페, 친구, 행복, 산책"""

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.7,
            max_tokens=100,
        )

        tags_str = response.choices[0].message.content.strip()
        tags = [tag.strip().strip("#") for tag in tags_str.split(",")]
        tags = tags[:max_tags]
        print(f"  [태그] 생성 완료: {', '.join(tags)}")
        return tags


class DiaryImageGenerator:
    """일기 본문 -> 이미지 생성 (gpt-image-1)"""

    def __init__(
        self, client: AsyncOpenAI, api_key: str, output_dir: Path, base_url: str = ""
    ):
        self.async_client = client
        self.sync_client = OpenAI(api_key=api_key)
        self.output_dir = output_dir
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.base_url = base_url or os.getenv("API_BASE_URL", "http://localhost:8000")

    async def generate(
        self,
        diary_text: str,
        timeline: Timeline,
        style: str = "watercolor illustration",
    ) -> tuple[str, str]:
        """이미지 생성 후 (image_url, prompt) 반환"""
        print("  [이미지] 이미지 프롬프트 생성 중...")
        image_prompt = await self._generate_image_prompt(diary_text, timeline, style)
        print(f"  [이미지] 프롬프트: {image_prompt[:80]}...")

        print("  [이미지] gpt-image-1으로 이미지 생성 중...")
        response = await asyncio.to_thread(
            self.sync_client.responses.create,
            model="gpt-4.1",
            input=image_prompt,
            tools=[{"type": "image_generation"}],
        )

        image_data = [
            output.result
            for output in response.output
            if output.type == "image_generation_call"
        ]

        if not image_data:
            raise Exception("No image generated from API response")

        filename = f"diary_{timeline.date.isoformat()}_{uuid.uuid4().hex[:8]}.png"
        filepath = self.output_dir / filename

        with open(filepath, "wb") as f:
            f.write(base64.b64decode(image_data[0]))

        image_url = f"/api/v1/files/images/{filename}"
        print(f"  [이미지] 생성 완료: {image_url}")
        return image_url, image_prompt

    async def _generate_image_prompt(
        self, diary_text: str, timeline: Timeline, style: str
    ) -> str:
        prompt = f"""다음 일기 내용을 바탕으로 이미지 생성 프롬프트를 만들어주세요.

일기 내용:
{diary_text[:300]}

오늘의 기분: {timeline.selfsurvey.mood or '평온'}

규칙:
1. 영어로 작성
2. 스타일: {style}
3. 일기의 분위기와 감정을 시각적으로 표현
4. 추상적이고 예술적인 표현
5. 100단어 이내

프롬프트만 반환해주세요."""

        response = await self.async_client.chat.completions.create(
            model="gpt-4.1",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.9,
            max_tokens=200,
        )

        return response.choices[0].message.content.strip()


class DiaryMusicGenerator:
    """일기 본문 -> 배경음악 생성 (Lyria RealTime)"""

    def __init__(self, client: AsyncOpenAI, gemini_api_key: str, output_dir: Path):
        self.openai_client = client
        self.gemini_api_key = gemini_api_key
        self.output_dir = output_dir
        self.output_dir.mkdir(parents=True, exist_ok=True)
        # 16-bit PCM, 48kHz, 스테레오
        self.sample_rate = 48000
        self.channels = 2
        self.bytes_per_sample = 2

    async def generate(
        self,
        diary_text: str,
        timeline: Timeline,
        duration_seconds: int = 15,
        genre: str = "ambient",
    ) -> tuple[str, str]:
        """음악 생성 후 (music_url, prompt) 반환"""
        print("  [음악] 음악 설정 생성 중...")
        weighted_prompts, bpm = await self._generate_music_config(
            diary_text, timeline, genre
        )
        prompts_text = ", ".join(
            [f"{p['text']}({p.get('weight', 1.0)})" for p in weighted_prompts]
        )
        print(f"  [음악] 프롬프트: {prompts_text}")
        print(f"  [음악] BPM: {bpm}")

        print(f"  [음악] Lyria RealTime으로 {duration_seconds}초 음악 스트리밍 중...")
        audio_data = await self._stream_lyria_realtime(
            weighted_prompts, bpm, duration_seconds
        )

        print(f"  [음악] 스트리밍 완료 ({len(audio_data):,} bytes)")
        filename = f"diary_{timeline.date.isoformat()}_{uuid.uuid4().hex[:8]}.wav"
        filepath = self.output_dir / filename
        self._save_as_wav(audio_data, filepath)

        music_url = f"/api/v1/files/music/{filename}"
        print(f"  [음악] 생성 완료: {music_url}")
        prompt_text = ", ".join([p["text"] for p in weighted_prompts])
        return music_url, prompt_text

    async def _generate_music_config(
        self, diary_text: str, timeline: Timeline, genre: str
    ) -> tuple[list[dict], int]:
        """일기 내용으로 음악 프롬프트] 생성"""
        prompt = f"""다음 일기 내용을 바탕으로 배경음악 설정을 만들어주세요.

일기 내용:
{diary_text[:300]}

오늘의 기분: {timeline.selfsurvey.mood or '평온'}

규칙:
1. 영어로 작성
2. 기본 장르: {genre}
3. 일기의 감정과 분위기를 음악으로 표현

다음 JSON 형식으로 반환해주세요:
{{
  "prompts": [
    {{"text": "장르/분위기 (예: Ambient, Chill)", "weight": 1.0}},
    {{"text": "악기 (예: Piano, Synth Pads)", "weight": 0.8}},
    {{"text": "감정 (예: Dreamy, Emotional)", "weight": 0.6}}
  ],
  "bpm": 80
}}

prompts는 2-4개, weight는 0.1~2.0, bpm은 60~120 사이로 설정해주세요."""

        response = await self.openai_client.chat.completions.create(
            model="gpt-4.1",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.8,
            max_tokens=200,
        )

        content = response.choices[0].message.content.strip()

        try:
            import re

            json_match = re.search(r"```json?\s*([\s\S]*?)\s*```", content)
            if json_match:
                content = json_match.group(1)

            result = json.loads(content)
            prompts = result.get("prompts", [{"text": genre, "weight": 1.0}])
            bpm = result.get("bpm", 80)
            return prompts, bpm
        except json.JSONDecodeError:
            return [{"text": genre, "weight": 1.0}], 80

    async def _stream_lyria_realtime(
        self, weighted_prompts: list[dict], bpm: int, duration_seconds: int
    ) -> bytes:
        """Lyria RealTime에서 오디오 스트리밍"""
        try:
            from google import genai
            from google.genai import types
        except ImportError:
            raise ImportError(
                "google-genai package required. Install with: pip install google-genai"
            )

        target_bytes = (
            self.sample_rate * self.channels * self.bytes_per_sample * duration_seconds
        )
        bytes_per_second = self.sample_rate * self.channels * self.bytes_per_sample
        BUFFER_SECONDS = 1.0
        max_retries = 2
        retry_delay = 2

        for attempt in range(max_retries):
            audio_chunks = []
            total_bytes = 0
            last_reported_second = -1
            chunks_count = 0
            buffered = False

            try:
                client = genai.Client(
                    api_key=self.gemini_api_key, http_options={"api_version": "v1alpha"}
                )

                print(f"  [음악] Lyria RealTime 연결 중...")

                async with client.aio.live.music.connect(
                    model="models/lyria-realtime-exp"
                ) as session:
                    print(f"  [음악] 프롬프트 설정 중...")
                    await session.set_weighted_prompts(
                        prompts=[
                            types.WeightedPrompt(
                                text=p["text"], weight=p.get("weight", 1.0)
                            )
                            for p in weighted_prompts
                        ]
                    )

                    print(f"  [음악] 생성 설정 중 (BPM: {bpm})...")
                    await session.set_music_generation_config(
                        config=types.LiveMusicGenerationConfig(
                            bpm=bpm,
                            temperature=1.0,
                            guidance=3.0,
                            top_k=40,
                        )
                    )

                    print(f"  [음악] 스트리밍 시작...")
                    await session.play()

                    timeout_seconds = duration_seconds + 60
                    start_time = asyncio.get_event_loop().time()

                    async for message in session.receive():
                        elapsed = asyncio.get_event_loop().time() - start_time
                        if elapsed > timeout_seconds:
                            print(f"\n  [음악] 타임아웃 ({timeout_seconds}초)")
                            break

                        if message.server_content:
                            if message.server_content.audio_chunks:
                                chunk = message.server_content.audio_chunks[0]
                                if chunk.data:
                                    audio_data = chunk.data
                                    if isinstance(audio_data, str):
                                        audio_data = base64.b64decode(audio_data)

                                    audio_chunks.append(audio_data)
                                    total_bytes += len(audio_data)
                                    chunks_count += 1

                                    if chunks_count == 1:
                                        print(
                                            f"  [음악] 첫 청크: {len(audio_data)} bytes, type: {type(chunk.data).__name__}"
                                        )

                                    if not buffered and chunks_count == 1:
                                        print(
                                            f"  [음악] 초기 버퍼링 중 ({BUFFER_SECONDS}초)..."
                                        )
                                        await asyncio.sleep(BUFFER_SECONDS)
                                        buffered = True

                                    current_second = total_bytes // bytes_per_second
                                    if current_second > last_reported_second:
                                        last_reported_second = current_second
                                        print(
                                            f"\r  [음악] 스트리밍 진행: {current_second}/{duration_seconds}초 "
                                            f"({total_bytes:,}/{target_bytes:,} bytes)",
                                            end="",
                                            flush=True,
                                        )

                                    if total_bytes >= target_bytes:
                                        print()
                                        break

                            elif hasattr(message.server_content, "generation_complete"):
                                if message.server_content.generation_complete:
                                    print(f"\n  [음악] 생성 완료 신호 수신")
                                    break

                        if hasattr(message, "filtered") and message.filtered:
                            print(
                                f"\n  [음악] 프롬프트가 필터링됨 - 다른 프롬프트로 재시도 필요"
                            )
                            break

                        if total_bytes >= target_bytes:
                            break

                    if last_reported_second >= 0:
                        print()

                    try:
                        await session.stop()
                    except Exception:
                        pass

                if audio_chunks:
                    combined_audio = b"".join(audio_chunks)

                    if len(combined_audio) > target_bytes:
                        combined_audio = combined_audio[:target_bytes]

                    actual_seconds = len(combined_audio) / bytes_per_second
                    print(
                        f"  [음악] 수집된 데이터: {actual_seconds:.1f}초 ({len(combined_audio):,} bytes)"
                    )
                    return combined_audio
                else:
                    print(f"  [음악] 오디오 데이터를 받지 못함")

            except Exception as e:
                import traceback

                print(f"\n  [음악] 스트리밍 오류: {e}")
                traceback.print_exc()

                if audio_chunks:
                    combined_audio = b"".join(audio_chunks)
                    actual_seconds = len(combined_audio) / bytes_per_second
                    print(
                        f"  [음악] 부분 데이터로 계속 진행: {actual_seconds:.1f}초 ({len(combined_audio):,} bytes)"
                    )
                    return combined_audio

            if attempt < max_retries - 1:
                print(
                    f"  [음악] {retry_delay}초 후 재시도... ({attempt + 1}/{max_retries})"
                )
                await asyncio.sleep(retry_delay)
                retry_delay *= 2

        raise Exception("음악 스트리밍 실패: 데이터를 받지 못함")

    def _save_as_wav(self, pcm_data: bytes, filepath: Path) -> None:
        """PCM 데이터를 WAV 파일로 저장"""
        import struct

        byte_rate = self.sample_rate * self.channels * self.bytes_per_sample
        block_align = self.channels * self.bytes_per_sample
        data_size = len(pcm_data)

        with open(filepath, "wb") as f:
            f.write(b"RIFF")
            f.write(struct.pack("<I", 36 + data_size))
            f.write(b"WAVE")
            f.write(b"fmt ")
            f.write(struct.pack("<I", 16))
            f.write(struct.pack("<H", 1))
            f.write(struct.pack("<H", self.channels))
            f.write(struct.pack("<I", self.sample_rate))
            f.write(struct.pack("<I", byte_rate))
            f.write(struct.pack("<H", block_align))
            f.write(struct.pack("<H", self.bytes_per_sample * 8))
            f.write(b"data")
            f.write(struct.pack("<I", data_size))
            f.write(pcm_data)


class DiaryGenerator:
    """일기 생성 총괄 - 텍스트, 이미지, 음악 생성 조율"""

    def __init__(
        self,
        openai_api_key: Optional[str] = None,
        gemini_api_key: Optional[str] = None,
        storage_dir: Optional[Path] = None,
    ):
        self.openai_api_key = openai_api_key or os.getenv("OPENAI_API_KEY")
        self.gemini_api_key = gemini_api_key or os.getenv("GEMINI_API_KEY")

        if not self.openai_api_key:
            raise ValueError("OPENAI_API_KEY is required")

        self.storage_dir = storage_dir or STORAGE_DIR
        self.storage_dir.mkdir(parents=True, exist_ok=True)

        self.client = AsyncOpenAI(api_key=self.openai_api_key)

        self.text_generator = DiaryTextGenerator(self.client)
        self.title_generator = DiaryTitleGenerator(self.client)
        self.tag_generator = DiaryTagGenerator(self.client)
        self.image_generator = DiaryImageGenerator(
            self.client, self.openai_api_key, self.storage_dir / "images"
        )

        if self.gemini_api_key:
            self.music_generator = DiaryMusicGenerator(
                self.client, self.gemini_api_key, self.storage_dir / "music"
            )
        else:
            self.music_generator = None

    async def generate(
        self,
        timeline: Timeline,
        generate_image: bool = False,
        generate_music: bool = False,
        image_style: str = "watercolor illustration",
        music_genre: str = "ambient",
        music_duration: int = 15,
    ) -> Diary:
        """타임라인으로 일기 전체 생성"""
        print("\n" + "=" * 50)
        print("일기 생성 시작")
        print("=" * 50)

        print("\n[1/5] 일기 텍스트 생성")
        diary_text = await self.text_generator.generate(timeline)

        print("\n[2/5] 일기 제목 생성")
        title = await self.title_generator.generate(diary_text, timeline)

        print("\n[3/5] 해시태그 생성")
        tags = await self.tag_generator.generate(diary_text)

        image_urls = []
        image_prompts = []
        if generate_image:
            print("\n[4/5] 이미지 생성")
            image_url, image_prompt = await self.image_generator.generate(
                diary_text, timeline, style=image_style
            )
            image_urls.append(image_url)
            image_prompts.append(image_prompt)
        else:
            print("\n[4/5] 이미지 생성 (건너뜀)")

        music_urls = []
        music_prompts = []
        if generate_music and self.music_generator:
            print("\n[5/5] 음악 생성")
            music_url, music_prompt = await self.music_generator.generate(
                diary_text,
                timeline,
                duration_seconds=music_duration,
                genre=music_genre,
            )
            music_urls.append(music_url)
            music_prompts.append(music_prompt)
        else:
            print("\n[5/5] 음악 생성 (건너뜀)")

        print("\n" + "=" * 50)
        print("일기 생성 완료!")
        print("=" * 50 + "\n")

        diary = Diary(
            id=f"diary-{timeline.date.isoformat()}-{uuid.uuid4().hex[:8]}",
            timeline=timeline,
            title=title,
            content=DiaryContent(
                text=diary_text,
                images=image_urls,
                music=music_urls,
                image_prompts=image_prompts,
                music_prompts=music_prompts,
            ),
            tag=tags,
        )

        self._save_to_log(diary)
        return diary

    def _save_to_log(self, diary: Diary) -> None:
        """일기를 JSON 로그 파일로 저장"""
        LOG_DIR.mkdir(parents=True, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{timestamp}_diary.json"
        filepath = LOG_DIR / filename

        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(diary.model_dump(mode="json"), f, ensure_ascii=False, indent=2)


async def generate_diary(
    timeline: Timeline,
    generate_image: bool = True,
    generate_music: bool = True,
    openai_api_key: Optional[str] = None,
    gemini_api_key: Optional[str] = None,
) -> Diary:
    """타임라인으로 일기 생성 함수"""
    generator = DiaryGenerator(
        openai_api_key=openai_api_key, gemini_api_key=gemini_api_key
    )
    return await generator.generate(
        timeline, generate_image=generate_image, generate_music=generate_music
    )
