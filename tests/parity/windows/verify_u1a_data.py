#!/usr/bin/env python3
"""U1a parity-data self-check.

Verifies that the PNGs in this directory are intact and that every probe point
recorded in scenes.json still has the exact RGBA the Windows box measured:

  1. size + SHA256 of every PNG against probe.json (transfer integrity)
  2. probe RGBA re-sampled from the PNG against scenes.json (content integrity)
  3. a short digest of the semantics the probes were designed to pin down

Run:  python3 verify_u1a_data.py            (from this directory)
Exit: 0 = all checks pass, 1 = something drifted.
"""
import hashlib
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def main() -> int:
    try:
        from PIL import Image
    except ImportError:
        print("FAIL: Pillow is required (pip install pillow)")
        return 1

    with open(os.path.join(HERE, "probe.json"), encoding="utf-8") as f:
        probe = json.load(f)
    with open(os.path.join(HERE, "scenes.json"), encoding="utf-8") as f:
        scenes = json.load(f)

    problems = []
    n_png = 0
    for entry in probe.get("pngs", []):
        path = os.path.join(HERE, entry["file"])
        if not os.path.exists(path):
            problems.append(f"missing PNG {entry['file']}")
            continue
        n_png += 1
        blob = open(path, "rb").read()
        if len(blob) != entry["sizeBytes"]:
            problems.append(f"{entry['file']}: size {len(blob)} != recorded {entry['sizeBytes']}")
        digest = hashlib.sha256(blob).hexdigest()
        if digest != entry["sha256"]:
            problems.append(f"{entry['file']}: sha256 {digest} != recorded {entry['sha256']}")

    n_probe = 0
    n_mismatch = 0
    for scene in scenes["scenes"]:
        path = os.path.join(HERE, scene["png"])
        if not os.path.exists(path):
            problems.append(f"missing PNG {scene['png']}")
            continue
        img = Image.open(path).convert("RGBA")
        if img.size != (scenes["conventions"]["canvas"]["width"],
                        scenes["conventions"]["canvas"]["height"]):
            problems.append(f"{scene['png']}: size {img.size} unexpected")
        px = img.load()
        for pr in scene["probes"]:
            n_probe += 1
            got = px[int(pr["x"]), int(pr["y"])]
            want = tuple(int(v) for v in pr["rgba"])
            if got != want:
                n_mismatch += 1
                problems.append(
                    f"{scene['id']} probe ({pr['x']},{pr['y']}): png={got} scenes.json={want}")

    print(f"PNG files verified : {n_png}/{len(probe.get('pngs', []))}")
    print(f"probes re-sampled : {n_probe}")
    print(f"probe mismatches   : {n_mismatch}")
    print(f"scene count        : {scenes.get('sceneCount')}")

    if problems:
        print("\nPROBLEMS:")
        for p in problems[:40]:
            print("  -", p)
        return 1
    print("\nOK: every PNG hash and every probe RGBA matches the Windows measurement.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
