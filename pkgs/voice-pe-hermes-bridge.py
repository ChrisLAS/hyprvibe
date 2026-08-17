#!/usr/bin/env python3
"""Bridge the Voice PE ESPHome API to a remote Hermes agent.

The device sends API-audio PCM (16 kHz, 16-bit, mono).  We transcribe it on
the studio workstation, send the text to Hermes over its authenticated
OpenAI-compatible API, synthesize the reply with a local command, and expose
the resulting 48 kHz mono FLAC briefly over the studio LAN for announcement
playback.
"""

from __future__ import annotations

import argparse
import asyncio
import json
import logging
import os
import re
import shlex
import tempfile
import uuid
import wave
from contextlib import suppress
from pathlib import Path
from typing import Any, AsyncIterator

import aioesphomeapi
import httpx
from aioesphomeapi import VoiceAssistantEventType
from faster_whisper import WhisperModel


LOG = logging.getLogger("voice-pe-hermes")
VOICE_CHUNK_MIN_CHARS = 24
PROTECTED_DOT = "\x00"
VOICE_ABBREVIATIONS = ("e.g.", "i.e.", "Mr.", "Mrs.", "Ms.", "Dr.")
VOICE_BOUNDARY = re.compile(
    rf"(?<=[.!?])\s+|(?=\n\s*\d+{re.escape(PROTECTED_DOT)}\s)"
)


def env(name: str, default: str) -> str:
    return os.environ.get(name, default)


def read_secret(path: str) -> str:
    if not path:
        raise RuntimeError("required secret-file path is not configured")
    value = Path(path).read_text(encoding="utf-8").strip()
    if not value:
        raise RuntimeError(f"secret is empty: {path}")
    return value


def write_pcm_wav(path: Path, pcm: bytes) -> None:
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(16_000)
        output.writeframes(pcm)


def extract_voice_chunks(text: str, *, flush: bool = False) -> tuple[list[str], str]:
    """Extract speakable chunks without breaking abbreviations or list markers."""
    protected = text
    for abbreviation in VOICE_ABBREVIATIONS:
        protected = protected.replace(
            abbreviation, abbreviation.replace(".", PROTECTED_DOT)
        )
    protected = re.sub(
        rf"(?m)(^|\n)(\s*\d+)\.",
        rf"\1\2{PROTECTED_DOT}",
        protected,
    )
    matches = list(VOICE_BOUNDARY.finditer(protected))
    if not matches:
        if flush and protected.strip():
            return [protected.replace(PROTECTED_DOT, ".").strip()], ""
        return [], text

    chunks: list[str] = []
    start = 0
    for match in matches:
        chunk = protected[start : match.start()].replace(PROTECTED_DOT, ".").strip()
        if chunk:
            chunks.append(chunk)
        start = match.end()
    remainder = protected[start:].replace(PROTECTED_DOT, ".")
    if flush and remainder.strip():
        chunks.append(remainder.strip())
        remainder = ""
    return chunks, remainder


async def run_command(argv: list[str], timeout: float) -> None:
    process = await asyncio.create_subprocess_exec(
        *argv,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    try:
        _stdout, stderr = await asyncio.wait_for(process.communicate(), timeout=timeout)
    except asyncio.CancelledError:
        process.terminate()
        with suppress(ProcessLookupError):
            await process.wait()
        raise
    if process.returncode != 0:
        detail = stderr.decode("utf-8", "replace").strip()
        raise RuntimeError(f"command failed ({process.returncode}): {detail}")


async def run_tts(command: str, text: str, output: Path) -> None:
    argv = [*shlex.split(command), "--output", str(output), text]
    LOG.info("synthesizing %d characters with %s", len(text), argv[0])
    await run_command(argv, timeout=180)
    if not output.is_file() or output.stat().st_size == 0:
        raise RuntimeError(f"TTS command did not create audio: {output}")


async def convert_to_flac(source: Path, output: Path) -> None:
    await run_command(
        [
            env("VOICE_PE_FFMPEG", "ffmpeg"),
            "-nostdin",
            "-hide_banner",
            "-loglevel",
            "error",
            "-y",
            "-i",
            str(source),
            "-ac",
            "1",
            "-ar",
            "48000",
            "-c:a",
            "flac",
            str(output),
        ],
        timeout=180,
    )


class AnnouncementServer:
    """Serve one random, short-lived FLAC path at a time."""

    def __init__(self, bind: str, port: int, public_base: str) -> None:
        self.bind = bind
        self.port = port
        self.public_base = public_base.rstrip("/")
        self.server: asyncio.AbstractServer | None = None
        self.media: dict[str, bytes] = {}

    async def start(self) -> None:
        self.server = await asyncio.start_server(self._handle, self.bind, self.port)
        LOG.info("announcement server listening on %s:%d", self.bind, self.port)

    async def close(self) -> None:
        if self.server is not None:
            self.server.close()
            await self.server.wait_closed()

    def add(self, data: bytes) -> tuple[str, str]:
        token = uuid.uuid4().hex
        path = f"/{token}.flac"
        self.media[path] = data
        return path, f"{self.public_base}{path}"

    def remove(self, path: str) -> None:
        self.media.pop(path, None)

    async def _handle(
        self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter
    ) -> None:
        try:
            request = await asyncio.wait_for(reader.readline(), timeout=5)
            target = request.decode("ascii", "replace").split(" ")[1]
            data = self.media.get(target)
            if data is None:
                writer.write(b"HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n")
            else:
                writer.write(
                    b"HTTP/1.1 200 OK\r\n"
                    + f"Content-Type: audio/flac\r\nContent-Length: {len(data)}\r\n".encode()
                    + b"Cache-Control: no-store\r\nConnection: close\r\n\r\n"
                    + data
                )
            await writer.drain()
        except (asyncio.TimeoutError, IndexError, UnicodeError):
            LOG.debug("invalid announcement HTTP request", exc_info=True)
        finally:
            writer.close()
            await writer.wait_closed()


class VoiceHermesBridge:
    def __init__(self, args: argparse.Namespace) -> None:
        self.args = args
        self.client: aioesphomeapi.APIClient | None = None
        self.unsubscribe: Any = None
        self.recording = bytearray()
        self.recording_lock = asyncio.Lock()
        self.http = httpx.AsyncClient(timeout=httpx.Timeout(300.0, connect=15.0))
        self.session_id = env("VOICE_PE_HERMES_SESSION_ID", str(uuid.uuid4()))
        self.active_turn: asyncio.Task[None] | None = None
        self.active_run_id: str | None = None
        self.active_run_lock = asyncio.Lock()
        self.announcement = AnnouncementServer(
            args.http_bind, args.http_port, args.http_base
        )
        self.whisper: WhisperModel | None = None
        self.disconnected = asyncio.Event()

    def event(self, event: VoiceAssistantEventType, **data: str) -> None:
        if self.client is not None:
            self.client.send_voice_assistant_event(event, data or None)

    async def handle_start(
        self,
        conversation_id: str,
        flags: int,
        audio_settings: Any,
        wake_word: str | None,
    ) -> int:
        del conversation_id, flags, audio_settings, wake_word
        await self.interrupt_active_turn()
        async with self.recording_lock:
            self.recording.clear()
        self.event(VoiceAssistantEventType.VOICE_ASSISTANT_RUN_START)
        self.event(VoiceAssistantEventType.VOICE_ASSISTANT_STT_START)
        # Port zero tells ESPHome to use the encrypted API-audio stream.
        return 0

    async def handle_audio(self, data: bytes, data2: bytes | None) -> None:
        del data2
        async with self.recording_lock:
            self.recording.extend(data)

    async def handle_stop(self, _aborted: bool) -> None:
        self.event(VoiceAssistantEventType.VOICE_ASSISTANT_STT_END)
        async with self.recording_lock:
            pcm = bytes(self.recording)
            self.recording.clear()
        if not pcm:
            self.fail("empty-audio")
            return
        self.active_turn = asyncio.create_task(self.process_recording(pcm))

    async def handle_disconnect(self, _expected: bool) -> None:
        self.disconnected.set()

    async def process_recording(self, pcm: bytes) -> None:
        try:
            text = await asyncio.to_thread(self.transcribe, pcm)
            if not text:
                self.fail("no-speech")
                return
            LOG.info("transcript: %s", text)
            self.event(VoiceAssistantEventType.VOICE_ASSISTANT_INTENT_START)
            spoken = False
            async for sentence in self.stream_hermes(text):
                spoken = True
                await self.speak(sentence)
            self.event(VoiceAssistantEventType.VOICE_ASSISTANT_INTENT_END)
            if not spoken:
                self.fail("empty-hermes-response")
                return
            self.event(VoiceAssistantEventType.VOICE_ASSISTANT_RUN_END)
        except asyncio.CancelledError:
            LOG.info("voice turn interrupted")
        except Exception:
            LOG.exception("voice turn failed")
            self.fail("bridge-error")

    def transcribe(self, pcm: bytes) -> str:
        if self.whisper is None:
            LOG.info("loading Faster Whisper model %s", self.args.whisper_model)
            whisper_options: dict[str, Any] = {
                "device": "cpu",
                "compute_type": "int8",
            }
            if cache := os.environ.get("VOICE_PE_WHISPER_CACHE"):
                whisper_options["download_root"] = cache
            self.whisper = WhisperModel(self.args.whisper_model, **whisper_options)
        with tempfile.TemporaryDirectory(prefix="voice-pe-stt-") as directory:
            path = Path(directory) / "input.wav"
            write_pcm_wav(path, pcm)
            segments, _ = self.whisper.transcribe(
                str(path), language="en", vad_filter=True, beam_size=5
            )
            return " ".join(segment.text.strip() for segment in segments).strip()

    async def stream_hermes(self, text: str) -> AsyncIterator[str]:
        response = await self.http.post(
            f"{self.args.hermes_url.rstrip('/')}/v1/runs",
            headers={
                "Authorization": f"Bearer {self.args.hermes_key}",
                "Content-Type": "application/json",
                "X-Hermes-Session-Id": self.session_id,
            },
            json={
                "input": f"{self.args.voice_instruction}\n\nUser request: {text}",
                "session_id": self.session_id,
            },
        )
        response.raise_for_status()
        run_id = str(response.json()["run_id"])
        async with self.active_run_lock:
            self.active_run_id = run_id
        LOG.info("Hermes run started: %s", run_id)

        buffer = ""
        pending = ""
        output = ""
        try:
            async with self.http.stream(
                "GET",
                f"{self.args.hermes_url.rstrip('/')}/v1/runs/{run_id}/events",
                headers={
                    "Authorization": f"Bearer {self.args.hermes_key}",
                    "Accept": "text/event-stream",
                    "X-Hermes-Session-Id": self.session_id,
                },
            ) as events:
                events.raise_for_status()
                async for line in events.aiter_lines():
                    if not line.startswith("data: "):
                        continue
                    payload = json.loads(line[6:])
                    event = payload.get("event")
                    if event == "message.delta":
                        delta = str(payload.get("delta") or "")
                        output += delta
                        buffer += delta
                        chunks, buffer = extract_voice_chunks(buffer)
                        for chunk in chunks:
                            pending = f"{pending} {chunk}".strip()
                            if len(pending) >= VOICE_CHUNK_MIN_CHARS:
                                yield pending
                                pending = ""
                    elif event == "run.completed":
                        completed = str(payload.get("output") or "")
                        if completed and not output:
                            buffer = completed
                        chunks, buffer = extract_voice_chunks(buffer, flush=True)
                        for chunk in chunks:
                            pending = f"{pending} {chunk}".strip()
                        break
        finally:
            async with self.active_run_lock:
                if self.active_run_id == run_id:
                    self.active_run_id = None
        if buffer.strip():
            pending = f"{pending} {buffer.strip()}".strip()
        if pending:
            yield pending

    async def interrupt_active_turn(self) -> None:
        task = self.active_turn
        if task is None or task.done():
            self.active_turn = None
            return
        async with self.active_run_lock:
            run_id = self.active_run_id
        if run_id:
            try:
                response = await self.http.post(
                    f"{self.args.hermes_url.rstrip('/')}/v1/runs/{run_id}/stop",
                    headers={
                        "Authorization": f"Bearer {self.args.hermes_key}",
                        "X-Hermes-Session-Id": self.session_id,
                    },
                    timeout=httpx.Timeout(15.0, connect=5.0),
                )
                response.raise_for_status()
                LOG.info("stopped Hermes run %s", run_id)
            except Exception:
                LOG.warning("could not stop Hermes run %s", run_id, exc_info=True)
        task.cancel()
        with suppress(asyncio.CancelledError):
            await task
        self.active_turn = None

    async def speak(self, text: str) -> None:
        with tempfile.TemporaryDirectory(prefix="voice-pe-tts-") as directory:
            root = Path(directory)
            wav_path = root / "reply.wav"
            flac_path = root / "reply.flac"
            await run_tts(self.args.tts_command, text, wav_path)
            await convert_to_flac(wav_path, flac_path)
            media_path, media_url = self.announcement.add(flac_path.read_bytes())
            try:
                LOG.info("requesting Voice PE announcement: %d bytes", flac_path.stat().st_size)
                result = await self.client.send_voice_assistant_announcement_await_response(
                    media_url, timeout=300, text=""
                )
                if not result.success:
                    raise RuntimeError("Voice PE reported announcement failure")
                LOG.info("Voice PE announcement completed successfully")
            finally:
                self.announcement.remove(media_path)

    def fail(self, reason: str) -> None:
        LOG.warning("voice turn failed: %s", reason)
        self.event(VoiceAssistantEventType.VOICE_ASSISTANT_ERROR, code=reason)
        self.event(VoiceAssistantEventType.VOICE_ASSISTANT_RUN_END)

    async def run(self) -> None:
        await self.announcement.start()
        while True:
            try:
                self.client = aioesphomeapi.APIClient(
                    self.args.device,
                    6053,
                    noise_psk=self.args.voice_pe_key,
                    client_info="nixstation voice-pe-hermes-bridge",
                )
                self.disconnected.clear()
                await self.client.connect(on_stop=self.handle_disconnect, login=True)
                LOG.info("connected to Voice PE %s", self.args.device)
                self.unsubscribe = self.client.subscribe_voice_assistant(
                    handle_start=self.handle_start,
                    handle_stop=self.handle_stop,
                    handle_audio=self.handle_audio,
                )
                await self.disconnected.wait()
            except asyncio.CancelledError:
                raise
            except Exception:
                LOG.exception("Voice PE connection failed; retrying")
            finally:
                if self.unsubscribe is not None:
                    self.unsubscribe()
                    self.unsubscribe = None
                if self.client is not None:
                    await self.client.disconnect(force=True)
                    self.client = None
            await asyncio.sleep(5)

    async def close(self) -> None:
        await self.interrupt_active_turn()
        if self.unsubscribe is not None:
            self.unsubscribe()
        if self.client is not None:
            await self.client.disconnect(force=True)
        await self.http.aclose()
        await self.announcement.close()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--device", default=env("VOICE_PE_DEVICE", "lore-voice-pe.local"))
    parser.add_argument("--voice-pe-key")
    parser.add_argument(
        "--hermes-url", default=env("VOICE_PE_HERMES_URL", "http://nomad.coin-noodlefish.ts.net:8643")
    )
    parser.add_argument("--hermes-key")
    parser.add_argument("--whisper-model", default=env("VOICE_PE_WHISPER_MODEL", "base"))
    parser.add_argument(
        "--voice-instruction",
        default=env(
            "VOICE_PE_HERMES_VOICE_INSTRUCTION",
            "Answer for spoken playback in two or three concise sentences. "
            "Avoid markdown, numbered lists, menus, and internal reasoning unless "
            "the user explicitly asks for them.",
        ),
        help="instruction prepended to each voice request",
    )
    parser.add_argument(
        "--tts-command",
        default=env("VOICE_PE_TTS_COMMAND", "voice-pe-espeak-tts"),
        help="executable plus optional args; it receives --output PATH TEXT",
    )
    parser.add_argument("--http-bind", default=env("VOICE_PE_HTTP_BIND", "0.0.0.0"))
    parser.add_argument("--http-port", type=int, default=int(env("VOICE_PE_HTTP_PORT", "8798")))
    parser.add_argument(
        "--http-base", default=env("VOICE_PE_HTTP_BASE", "http://192.168.7.29:8798")
    )
    args = parser.parse_args()
    if args.voice_pe_key is None:
        args.voice_pe_key = read_secret(env("VOICE_PE_KEY_FILE", ""))
    if args.hermes_key is None:
        args.hermes_key = read_secret(env("VOICE_PE_HERMES_KEY_FILE", ""))
    return args


async def main() -> None:
    logging.basicConfig(
        level=env("VOICE_PE_LOG_LEVEL", "INFO"),
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    args = parse_args()
    bridge = VoiceHermesBridge(args)
    try:
        await bridge.run()
    finally:
        await bridge.close()


if __name__ == "__main__":
    asyncio.run(main())
