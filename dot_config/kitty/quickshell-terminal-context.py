"""Publish only terminal context already reported by Kitty shell integration."""
import atexit
import json
import os
from pathlib import Path
import re
import shlex
from urllib.parse import unquote, urlsplit

_directory = Path(os.environ.get("XDG_RUNTIME_DIR", "/tmp")) / "quickshell-de-terminal"
_path = _directory / f"{os.getpid()}.json"
_start = Path(f"/proc/{os.getpid()}/stat").read_text().rsplit(")", 1)[1].split()[19]
_previous = None


def command_name(text):
    try:
        args = shlex.split(text)
    except ValueError:
        return ""
    while args and (re.match(r"^[A-Za-z_][A-Za-z_0-9]*=", args[0]) or args[0] in {"command", "exec", "builtin"}):
        args.pop(0)
    return Path(args[0]).name[:128] if args else ""


def publish(boss, window=None, data=None):
    global _previous
    records = []
    for manager in boss.os_window_map.values():
        current = manager.active_window
        if current is None:
            continue
        try:
            raw = current.screen.last_reported_cwd or ""
            if isinstance(raw, bytes):
                raw = raw.decode("utf-8", errors="replace")
            url = urlsplit(raw)
            cwd = unquote(url.path) if url.scheme == "file" else url.path if url.scheme == "kitty-shell-cwd" else ""
            if not cwd.startswith("/") or any(ord(c) < 32 for c in cwd):
                continue
            records.append({
                "title": re.sub(r"^[\u2800-\u28ff]\s*", "", current.title),
                "host": url.hostname or "",
                "cwd": cwd,
                "remote": bool(current.child_is_remote),
                "command": "fish" if current.at_prompt and current.child_is_remote
                    else command_name(current.last_cmd_cmdline) if not current.at_prompt else "",
            })
        except (AttributeError, ValueError):
            continue
    payload = json.dumps({"start": _start, "windows": records}, ensure_ascii=False)
    if payload == _previous:
        return
    try:
        _directory.mkdir(mode=0o700, exist_ok=True)
        temporary = _path.with_suffix(".tmp")
        fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
        with os.fdopen(fd, "w") as output:
            output.write(payload)
        temporary.replace(_path)
        _previous = payload
    except OSError:
        pass


def on_load(boss, data):
    # Config reload normally attaches watchers only to new windows. Register
    # these callbacks once on existing windows so active SSH jobs keep running.
    for window in tuple(boss.window_id_map.values()):
        for event in ("on_title_change", "on_focus_change", "on_cmd_startstop"):
            callbacks = getattr(window.watchers, event)
            callbacks[:] = [callback for callback in callbacks
                if Path(getattr(getattr(callback, "__code__", None), "co_filename", "")).name != "quickshell-context.py"]
            if publish not in callbacks:
                callbacks.append(publish)
    publish(boss)


on_title_change = publish
on_focus_change = publish
on_cmd_startstop = publish
on_tab_bar_dirty = publish
atexit.register(lambda: _path.unlink(missing_ok=True))
