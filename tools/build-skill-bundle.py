#!/usr/bin/env python3
"""Build 1c-developer.skill from the working tree and check the release invariants.

    python tools/build-skill-bundle.py

Checks before packing:
  * .claude-plugin/plugin.json and this plugin's marketplace entry carry the same version;
  * SKILL.md has a frontmatter name equal to the plugin name and a description
    of at most 1024 characters (the Agent Skills limit; Claude Code also cuts long ones).
Packing: SKILL.md, references/ and scripts/ at the archive root; .bat/.cmd are written
with CRLF (cmd.exe misparses LF), .sh and .md with LF, whatever the checkout did.
"""
import json
import re
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUNDLE = ROOT / "1c-developer.skill"
INCLUDE = ["SKILL.md", "references", "scripts"]
DESCRIPTION_LIMIT = 1024
FIXED_TIME = (2026, 1, 1, 0, 0, 0)  # reproducible archive


def fail(message):
    print(f"FAIL: {message}")
    sys.exit(1)


def frontmatter_field(text, field):
    match = re.match(r"---\n(.*?)\n---\n", text.replace("\r\n", "\n"), re.S)
    if not match:
        fail("SKILL.md has no YAML frontmatter")
    line = re.search(rf"^{field}:\s*(.*)$", match.group(1), re.M)
    return line.group(1).strip() if line else None


def normalized(path):
    data = path.read_bytes()
    if path.suffix.lower() in (".bat", ".cmd"):
        return data.replace(b"\r\n", b"\n").replace(b"\n", b"\r\n")
    if path.suffix.lower() in (".sh", ".md"):
        return data.replace(b"\r\n", b"\n")
    return data


def main():
    plugin = json.loads((ROOT / ".claude-plugin" / "plugin.json").read_text(encoding="utf-8"))
    market = json.loads((ROOT / ".claude-plugin" / "marketplace.json").read_text(encoding="utf-8"))
    entry = next((p for p in market["plugins"] if p["name"] == plugin["name"]), None)
    if entry is None:
        fail(f"'{plugin['name']}' is missing from marketplace.json")
    if entry.get("version", plugin["version"]) != plugin["version"]:
        fail(f"version mismatch: plugin.json {plugin['version']}, marketplace.json {entry['version']}")

    skill = (ROOT / "SKILL.md").read_text(encoding="utf-8")
    name = frontmatter_field(skill, "name")
    description = frontmatter_field(skill, "description") or ""
    if name != plugin["name"]:
        fail(f"SKILL.md name '{name}' differs from plugin name '{plugin['name']}'")
    if not 0 < len(description) <= DESCRIPTION_LIMIT:
        fail(f"description is {len(description)} characters (limit {DESCRIPTION_LIMIT})")

    files = []
    for item in INCLUDE:
        path = ROOT / item
        files += [path] if path.is_file() else sorted(p for p in path.rglob("*") if p.is_file())

    with zipfile.ZipFile(BUNDLE, "w", zipfile.ZIP_DEFLATED) as bundle:
        for path in files:
            info = zipfile.ZipInfo(path.relative_to(ROOT).as_posix(), FIXED_TIME)
            info.compress_type = zipfile.ZIP_DEFLATED
            bundle.writestr(info, normalized(path))

    with zipfile.ZipFile(BUNDLE) as bundle:
        for member in bundle.namelist():
            data = bundle.read(member)
            if member.endswith((".bat", ".cmd")) and re.search(rb"(?<!\r)\n", data):
                fail(f"{member} has bare LF line endings in the bundle")

    print(f"OK: {BUNDLE.name} v{plugin['version']}, {len(files)} files, "
          f"description {len(description)}/{DESCRIPTION_LIMIT} characters")


if __name__ == "__main__":
    main()
