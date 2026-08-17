#!/usr/bin/env python3
"""Persistent local NeuTTS server and its small command-line client.

The model and reference data stay in the user's private state/cache.  Nix
packages the launcher and service, while this process keeps the model warm so
each Hermes turn does not pay the 15-20 second model-load cost again.
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import sys
import tempfile
import threading
import urllib.error
import urllib.request
import wave
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


LOG = logging.getLogger("voice-pe-neutts")


def env(name: str, default: str) -> str:
    return os.environ.get(name, default)


def read_secret(path: str) -> str:
    if not path:
        return ""
    value = Path(path).read_text(encoding="utf-8").strip()
    if value:
        return value
    return ""


class Synthesizer:
    def __init__(self) -> None:
        # These imports are intentionally delayed until the persistent service
        # starts.  The bridge itself remains lightweight and Nix-native.
        import numpy as np
        import soundfile as sf
        import torch
        from neutts import NeuTTS

        self.np = np
        self.sf = sf
        self.torch = torch
        reference_codes_path = Path(
            env(
                "VOICE_PE_NEUTTS_REFERENCE_CODES",
                "/home/chrisf/.local/state/voice-pe/voice-reference/"
                "lore-data-log-2-0-12s-neutts-codes.pt",
            )
        )
        reference_text_path = Path(
            env(
                "VOICE_PE_NEUTTS_REFERENCE_TEXT",
                "/home/chrisf/.local/state/voice-pe/voice-reference/"
                "lore-data-log-2-0-12s.txt",
            )
        )
        model_path = env(
            "VOICE_PE_NEUTTS_BACKBONE",
            "/home/chrisf/.cache/huggingface/hub/models--neuphonic--"
            "neutts-nano-q4-gguf/snapshots/8ae1694877fdf9d7c4a7bee2cc9775ba7eab3923/"
            "neutts-nano-Q4_0.gguf",
        )
        codec_path = env(
            "VOICE_PE_NEUTTS_CODEC",
            "/home/chrisf/.cache/huggingface/hub/models--neuphonic--"
            "neucodec-onnx-decoder-int8/snapshots/706f4bd5fcc39b039c333d5407f58b0075dcee07/"
            "model.onnx",
        )
        if not reference_codes_path.is_file():
            raise RuntimeError(f"NeuTTS reference codes are missing: {reference_codes_path}")
        if not reference_text_path.is_file():
            raise RuntimeError(f"NeuTTS reference text is missing: {reference_text_path}")
        if not Path(model_path).is_file():
            raise RuntimeError(f"NeuTTS backbone is missing: {model_path}")
        if not Path(codec_path).is_file():
            raise RuntimeError(f"NeuCodec decoder is missing: {codec_path}")

        token_file = env("VOICE_PE_NEUTTS_HF_TOKEN_FILE", "")
        if token_file:
            token = read_secret(token_file)
            if token:
                os.environ["HF_TOKEN"] = token

        LOG.info("loading NeuTTS backbone and codec")
        self.model = NeuTTS(
            backbone_repo=model_path,
            backbone_device="cpu",
            codec_repo=codec_path,
            codec_device="cpu",
            language=env("VOICE_PE_NEUTTS_LANGUAGE", "en-us"),
            seed=int(env("VOICE_PE_NEUTTS_SEED", "42")),
        )
        self.reference_codes = torch.load(
            reference_codes_path, map_location="cpu", weights_only=True
        )
        self.reference_text = reference_text_path.read_text(encoding="utf-8").strip()
        self.lock = threading.Lock()
        LOG.info("NeuTTS ready at %d Hz using %s", self.model.sample_rate, model_path)

    def synthesize(self, text: str, output: Path) -> None:
        with self.lock:
            chunks = [
                self.np.asarray(chunk, dtype=self.np.float32)
                for chunk in self.model.infer_stream(
                    text, self.reference_codes, self.reference_text
                )
            ]
            if not chunks:
                raise RuntimeError("NeuTTS returned no audio chunks")
            audio = self.np.concatenate(chunks)
            self.sf.write(output, audio, self.model.sample_rate, subtype="PCM_16")
        output.chmod(0o600)


class Handler(BaseHTTPRequestHandler):
    synthesizer: Synthesizer

    def do_POST(self) -> None:  # noqa: N802
        if self.path != "/synthesize":
            self.send_error(404)
            return
        try:
            length = int(self.headers.get("Content-Length", "0"))
            payload = json.loads(self.rfile.read(length))
            text = str(payload.get("text") or "").strip()
            if not text:
                raise ValueError("text is empty")
            with tempfile.NamedTemporaryFile(prefix="voice-pe-neutts-", suffix=".wav", delete=False) as file:
                output = Path(file.name)
            try:
                self.synthesizer.synthesize(text, output)
                data = output.read_bytes()
            finally:
                output.unlink(missing_ok=True)
            self.send_response(200)
            self.send_header("Content-Type", "audio/wav")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)
            LOG.info("synthesized %d characters into %d bytes", len(text), len(data))
        except Exception as error:  # keep the daemon alive for the next turn
            LOG.exception("NeuTTS request failed")
            body = f"{type(error).__name__}: {error}\n".encode()
            self.send_response(500)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    def log_message(self, _format: str, *_args: object) -> None:
        return


def run_server() -> int:
    logging.basicConfig(
        level=env("VOICE_PE_NEUTTS_LOG_LEVEL", "INFO"),
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
    )
    synthesizer = Synthesizer()
    Handler.synthesizer = synthesizer
    server = ThreadingHTTPServer(
        (env("VOICE_PE_NEUTTS_BIND", "127.0.0.1"), int(env("VOICE_PE_NEUTTS_PORT", "8799"))),
        Handler,
    )
    LOG.info("NeuTTS server listening on %s", server.server_address)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        return 0
    finally:
        server.server_close()
    return 0


def run_client(output: str, text: str) -> int:
    request = urllib.request.Request(
        f"{env('VOICE_PE_NEUTTS_URL', 'http://127.0.0.1:8799')}/synthesize",
        data=json.dumps({"text": text}).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            data = response.read()
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", "replace")
        raise RuntimeError(f"NeuTTS server returned HTTP {error.code}: {detail}") from error
    Path(output).write_bytes(data)
    Path(output).chmod(0o600)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--server", action="store_true")
    mode.add_argument("--client", action="store_true")
    parser.add_argument("--output")
    parser.add_argument("text", nargs="?")
    args = parser.parse_args()
    if args.server:
        return run_server()
    if args.output is None or args.text is None:
        parser.error("--client requires --output PATH TEXT")
    return run_client(args.output, args.text)


if __name__ == "__main__":
    raise SystemExit(main())
