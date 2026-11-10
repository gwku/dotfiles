#!/usr/bin/env python3
"""Seed private Espanso configuration from public defaults without overwriting edits."""

import argparse
from datetime import datetime, timezone
import os
from pathlib import Path
import shutil
import sys


def default_target():
    if sys.platform == "darwin":
        return Path.home() / "Library/Application Support/espanso"
    if sys.platform == "win32":
        return Path(os.environ["APPDATA"]) / "espanso"
    return Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "espanso"


def default_private_root():
    if sys.platform == "win32":
        return Path(os.environ["APPDATA"]) / "espanso-private"
    return Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "espanso-private"


def prepare_runtime(source, runtime):
    source = source.expanduser().resolve(strict=True)
    runtime = runtime.expanduser().resolve()
    public_root = next((p for p in (source, *source.parents) if (p / ".git").exists()), source)
    if runtime == public_root or public_root in runtime.parents:
        raise ValueError("Private runtime must be outside the public repository")
    if source == runtime or source in runtime.parents or runtime in source.parents:
        raise ValueError("Private runtime and public defaults must be separate directories")
    if not (source / "config/default.yml").is_file() or not (source / "match").is_dir():
        raise ValueError(f"Not an Espanso defaults directory: {source}")
    runtime.mkdir(mode=0o700, parents=True, exist_ok=True)
    runtime.chmod(0o700)
    for section in ("config", "match"):
        folder = runtime / section
        folder.mkdir(mode=0o700, exist_ok=True)
        folder.chmod(0o700)
        for path in (source / section).glob("*.y*ml"):
            # Ignored local files and external links are never public seeds.
            if path.is_symlink() or ".local." in path.name or not path.is_file():
                continue
            destination = folder / path.name
            try:
                fd = os.open(destination, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            except FileExistsError:
                continue
            with os.fdopen(fd, "wb") as handle, path.open("rb") as original:
                shutil.copyfileobj(original, handle)
    return runtime


def connect(source, target):
    source = source.expanduser().resolve(strict=True)
    target = target.expanduser().absolute()
    if not (source / "config/default.yml").is_file() or not (source / "match").is_dir():
        raise ValueError(f"Not an Espanso configuration directory: {source}")
    # Refuse a target that contains the source: moving it would move dotfiles.
    if target == source or target in source.parents:
        raise ValueError("The Espanso destination must not contain the source directory")
    if target.resolve() == source:
        print(f"Espanso already linked: {target}")
        return
    if source in target.resolve().parents:
        raise ValueError("The Espanso destination must not be inside the source directory")

    target.parent.mkdir(parents=True, exist_ok=True)
    # Create the new link first, so a permissions failure (notably Windows
    # without Developer Mode) cannot displace a working configuration.
    temporary = target.with_name(f".{target.name}.link-{os.getpid()}")
    temporary.symlink_to(source, target_is_directory=True)
    backup = None
    try:
        if target.exists() or target.is_symlink():
            stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
            backup = target.with_name(f"{target.name}.backup-{stamp}")
            target.rename(backup)
        try:
            temporary.rename(target)
        except OSError:
            if backup is not None:
                backup.rename(target)
            raise
    finally:
        if temporary.is_symlink():
            temporary.unlink()
    if backup is not None:
        print(f"Previous configuration retained at: {backup}")
    print(f"Espanso linked: {target} -> {source}")


def link_personal(runtime):
    personal = runtime.parent / "personal.yml"
    link = runtime / "match/personal.yml"
    if not personal.is_file():
        return
    if link.is_symlink():
        # Preserve an intentionally configured link to a different, existing
        # private file. Repair stale absolute links restored from another home.
        if link.exists() and link.resolve() != personal.resolve():
            return
    elif link.exists():
        return
    relative = os.path.relpath(personal, link.parent)
    if link.is_symlink() and os.readlink(link) == relative:
        return
    temporary = link.with_name(f".personal.link-{os.getpid()}")
    temporary.symlink_to(relative, target_is_directory=False)
    try:
        temporary.replace(link)
    finally:
        if temporary.is_symlink():
            temporary.unlink()


def install_emoji(runtime, source):
    source = source.expanduser().resolve(strict=True)
    if not (source / "_manifest.yml").is_file() or not (source / "package.yml").is_file():
        raise ValueError("The emoji package is missing its manifest or matches")
    parent = runtime / "match/packages"
    parent.mkdir(mode=0o700, exist_ok=True)
    target = parent / "all-emojis"
    # Preserve installed packages, including any deliberate local edits.
    if target.exists() or target.is_symlink():
        return
    temporary = parent / f".all-emojis-{os.getpid()}"
    try:
        shutil.copytree(source, temporary)
        for path in temporary.rglob("*"):
            path.chmod(0o700 if path.is_dir() else 0o600)
        temporary.chmod(0o700)
        temporary.rename(target)
    finally:
        if temporary.exists():
            shutil.rmtree(temporary)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, default=Path(__file__).resolve().parent.parent / "modules/home/espanso/files")
    parser.add_argument("--target", type=Path, default=default_target())
    parser.add_argument("--runtime", type=Path, default=default_private_root() / "runtime")
    parser.add_argument("--emoji-package", type=Path, help="Verified all-emojis package directory")
    args = parser.parse_args()
    try:
        runtime = prepare_runtime(args.source, args.runtime)
        # Reuse the previous private personal file, without linking anything
        # personal back into the public checkout.
        link_personal(runtime)
        if args.emoji_package is not None:
            install_emoji(runtime, args.emoji_package)
        connect(runtime, args.target)
    except (OSError, ValueError) as error:
        parser.exit(1, f"Espanso setup failed: {error}\n")


if __name__ == "__main__":
    main()
