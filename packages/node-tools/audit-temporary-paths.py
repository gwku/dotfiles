"""Reject references to a writable build directory in installed executables."""

from pathlib import Path
import sys


def audit(directory: Path, temporary_directory: str) -> list[Path]:
    prefix = temporary_directory.rstrip("/").encode() + b"/"
    failures = []
    for path in directory.rglob("*"):
        if path.is_symlink() or not path.is_file():
            continue
        with path.open("rb") as source:
            header = source.read(4)
            if not (header.startswith(b"#!") or header == b"\x7fELF"):
                continue
            if prefix in header + source.read():
                failures.append(path)
    return failures


if __name__ == "__main__":
    directory = Path(sys.argv[1])
    failures = audit(directory, sys.argv[2])
    if failures:
        for path in failures:
            print(f"Forbidden temporary build-path reference: {path}", file=sys.stderr)
        raise SystemExit(1)
    print("Installed executable temporary-path audit passed")
