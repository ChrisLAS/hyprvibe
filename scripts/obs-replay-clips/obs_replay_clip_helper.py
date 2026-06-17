#!/usr/bin/env python3
"""Local helper for OBS replay-buffer clipping and marker notes."""

from __future__ import annotations

import argparse
import datetime as dt
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path


VIDEO_EXTENSIONS = {".mkv", ".mp4", ".mov", ".flv", ".ts"}


def expand_path(value: str) -> Path:
    return Path(os.path.expandvars(os.path.expanduser(value))).resolve()


def now_local() -> dt.datetime:
    return dt.datetime.now().astimezone()


def ensure_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)


def log(logs_dir: Path, message: str) -> None:
    ensure_dir(logs_dir)
    stamp = now_local()
    line = f"{stamp.isoformat(timespec='seconds')} {message}\n"
    log_file = logs_dir / f"obs-replay-clips-{stamp:%Y%m%d}.log"
    with log_file.open("a", encoding="utf-8") as handle:
        handle.write(line)
    print(line, end="")


def wait_for_stable_file(path: Path, timeout: float, interval: float, logs_dir: Path) -> None:
    deadline = time.monotonic() + timeout
    last_size = -1
    stable_count = 0

    while time.monotonic() < deadline:
        if path.exists() and path.is_file():
            size = path.stat().st_size
            if size > 0 and size == last_size:
                stable_count += 1
                if stable_count >= 2:
                    return
            else:
                stable_count = 0
                last_size = size
        time.sleep(interval)

    raise RuntimeError(f"replay file did not become stable within {timeout:.0f}s: {path}")


def newest_video_file(directory: Path) -> Path | None:
    if not directory.exists():
        return None
    candidates = [
        path
        for path in directory.iterdir()
        if path.is_file() and path.suffix.lower() in VIDEO_EXTENSIONS
    ]
    if not candidates:
        return None
    return max(candidates, key=lambda path: path.stat().st_mtime)


def unique_path(directory: Path, stem: str, suffix: str) -> Path:
    candidate = directory / f"{stem}{suffix}"
    if not candidate.exists():
        return candidate
    for index in range(1, 1000):
        candidate = directory / f"{stem}-{index:02d}{suffix}"
        if not candidate.exists():
            return candidate
    raise RuntimeError(f"could not create unique output path for {stem}{suffix}")


def duration_label(seconds: int) -> str:
    if seconds % 60 == 0 and seconds >= 60:
        minutes = seconds // 60
        return f"{minutes}m"
    return f"{seconds}s"


def clip_output_path(clips_dir: Path, seconds: int, source: Path) -> Path:
    ensure_dir(clips_dir)
    stamp = now_local().strftime("%Y%m%d-%H%M%S")
    suffix = source.suffix if source.suffix else ".mkv"
    return unique_path(clips_dir, f"clip-{stamp}-{duration_label(seconds)}", suffix)


def require_ffmpeg() -> str:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        raise RuntimeError("ffmpeg is missing from PATH")
    return ffmpeg


def trim_clip(source: Path, output: Path, seconds: int, logs_dir: Path) -> None:
    ffmpeg = require_ffmpeg()
    command = [
        ffmpeg,
        "-hide_banner",
        "-loglevel",
        "warning",
        "-sseof",
        f"-{seconds}",
        "-i",
        str(source),
        "-map",
        "0",
        "-c",
        "copy",
        "-avoid_negative_ts",
        "make_zero",
        "-n",
        str(output),
    ]
    log(logs_dir, "running: " + " ".join(command))
    completed = subprocess.run(command, text=True, capture_output=True, check=False)
    if completed.stdout:
        log(logs_dir, completed.stdout.rstrip())
    if completed.stderr:
        log(logs_dir, completed.stderr.rstrip())
    if completed.returncode != 0:
        raise RuntimeError(f"ffmpeg failed with exit code {completed.returncode}")
    if not output.exists() or output.stat().st_size == 0:
        raise RuntimeError(f"ffmpeg did not create a usable output file: {output}")


def copy_clip(source: Path, output: Path, logs_dir: Path) -> None:
    log(logs_dir, f"copying replay to clip: {source} -> {output}")
    shutil.copy2(source, output)
    if not output.exists() or output.stat().st_size == 0:
        raise RuntimeError(f"copy did not create a usable output file: {output}")


def handle_clip(args: argparse.Namespace) -> int:
    logs_dir = expand_path(args.logs_dir)
    clips_dir = expand_path(args.clips_dir)
    source = expand_path(args.replay_file) if args.replay_file else None

    try:
        if source is None:
            replay_dir = expand_path(args.replay_dir)
            source = newest_video_file(replay_dir)
            if source is None:
                raise RuntimeError(f"no replay video found in {replay_dir}")

        if not source.exists():
            raise RuntimeError(f"replay file does not exist: {source}")

        wait_for_stable_file(source, args.wait_timeout, args.wait_interval, logs_dir)
        output = clip_output_path(clips_dir, args.duration, source)

        if args.copy:
            copy_clip(source, output, logs_dir)
        else:
            trim_clip(source, output, args.duration, logs_dir)

        log(logs_dir, f"created clip: {output}")
        return 0
    except Exception as exc:
        log(logs_dir, f"ERROR: {exc}")
        return 1


def marker_file(markers_dir: Path, stamp: dt.datetime) -> Path:
    ensure_dir(markers_dir)
    path = markers_dir / f"markers-{stamp:%Y%m%d}.md"
    if not path.exists():
        with path.open("w", encoding="utf-8") as handle:
            handle.write(f"# OBS Markers - {stamp:%Y-%m-%d}\n\n")
    return path


def handle_marker(args: argparse.Namespace) -> int:
    logs_dir = expand_path(args.logs_dir)
    markers_dir = expand_path(args.markers_dir)
    stamp = now_local()
    note = args.note.strip() if args.note else "Marker added"

    try:
        path = marker_file(markers_dir, stamp)
        with path.open("a", encoding="utf-8") as handle:
            handle.write(f"- {stamp:%H:%M:%S} - {note}\n")
        log(logs_dir, f"wrote marker: {path}: {note}")
        return 0
    except Exception as exc:
        log(logs_dir, f"ERROR: {exc}")
        return 1


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="OBS replay-buffer clipping helper")
    subparsers = parser.add_subparsers(dest="command", required=True)

    clip = subparsers.add_parser("clip", help="create a clip from a saved replay")
    clip.add_argument("--duration", type=int, required=True, help="clip length in seconds")
    clip.add_argument("--replay-file", help="saved replay file path")
    clip.add_argument("--replay-dir", default="~/obs", help="fallback replay directory")
    clip.add_argument("--clips-dir", default="~/obs/Clips", help="clip output directory")
    clip.add_argument("--logs-dir", default="~/obs/Logs", help="log directory")
    clip.add_argument("--wait-timeout", type=float, default=20.0)
    clip.add_argument("--wait-interval", type=float, default=0.5)
    clip.add_argument("--copy", action="store_true", help="copy the replay instead of trimming")
    clip.set_defaults(func=handle_clip)

    marker = subparsers.add_parser("marker", help="append a timestamped marker")
    marker.add_argument("--markers-dir", default="~/obs/Markers", help="marker directory")
    marker.add_argument("--logs-dir", default="~/obs/Logs", help="log directory")
    marker.add_argument("--note", default="Marker added", help="marker text")
    marker.set_defaults(func=handle_marker)

    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
