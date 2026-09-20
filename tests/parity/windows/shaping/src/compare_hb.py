#!/usr/bin/env python3
"""Compare the DirectWrite shaping oracle against HarfBuzz on the same fonts/texts.

usage: PYTHONPATH=/tmp/u1/hb python3 compare_hb.py <oracle.json> <fontdir> <out.json>
"""
import json, sys, os
import uharfbuzz as hb

oracle_path, fontdir, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
oracle = json.load(open(oracle_path, encoding="utf-8"))

faces = {}
def hb_shape(fontfile, text, size_dip):
    path = os.path.join(fontdir, fontfile)
    if path not in faces:
        blob = hb.Blob(open(path, "rb").read())
        faces[path] = (hb.Face(blob), )
    face = faces[path][0]
    upem = face.upem
    font = hb.Font(face)
    font.scale = (upem, upem)              # advances in font design units
    buf = hb.Buffer()
    buf.add_str(text)
    buf.guess_segment_properties()
    hb.shape(font, buf)                     # default features (kern/liga/clig on)
    infos = list(buf.glyph_infos)
    poss = list(buf.glyph_positions)
    scale = size_dip / upem
    glyphs = [i.codepoint for i in infos]
    clusters = [i.cluster for i in infos]
    advances = [round(p.x_advance * scale, 6) for p in poss]
    offsets = [{"x": round(p.x_offset * scale, 6), "y": round(-p.y_offset * scale, 6)} for p in poss]
    return {
        "glyphs": glyphs, "clusters": clusters, "advances": advances, "offsets": offsets,
        "total": round(sum(advances), 6), "upem": upem,
        "script": str(buf.script), "language": str(buf.language), "direction": str(buf.direction),
    }

results, mismatches, matches = [], 0, 0
for c in oracle["cases"]:
    h = hb_shape(c["font"], c["text"], c["emSizeDip"])
    dw_glyphs = c["glyphIds"]
    dw_adv = c["advancesDip"]
    # invert DWrite's text->glyph map into glyph->first text index, like HarfBuzz reports
    t2g = c["textToGlyphMap"]
    inv = []
    for g in range(len(dw_glyphs)):
        inv.append(next((i for i, gg in enumerate(t2g) if gg == g), -1))
    same_glyphs = dw_glyphs == h["glyphs"]
    same_clusters = inv == h["clusters"]
    n = min(len(dw_glyphs), len(h["glyphs"]))
    adv_delta = [round(dw_adv[i] - h["advances"][i], 6) for i in range(n)] if len(dw_adv) == len(h["advances"]) else None
    total_delta = round(c["totalAdvanceDip"] - h["total"], 6)
    match = same_glyphs and adv_delta is not None and max([abs(x) for x in adv_delta], default=0) < 0.01
    if match: matches += 1
    else: mismatches += 1
    results.append({
        "id": c["id"], "font": c["font"], "emSizeDip": c["emSizeDip"], "text": c["text"],
        "dwriteGlyphs": dw_glyphs, "harfbuzzGlyphs": h["glyphs"],
        "dwriteAdvances": dw_adv, "harfbuzzAdvances": h["advances"],
        "dwriteTotal": c["totalAdvanceDip"], "harfbuzzTotal": h["total"],
        "totalDeltaDip": total_delta, "maxAdvanceDeltaDip": round(max([abs(x) for x in adv_delta], default=0), 6) if adv_delta else None,
        "glyphSequenceIdentical": same_glyphs, "clusterSequenceIdentical": same_clusters,
        "advanceDeltasDip": adv_delta,
        "match": match,
        "hbScript": h["script"], "hbLanguage": h["language"], "hbDirection": h["direction"],
        "dwriteNotdef": c["notdefGlyphs"],
    })

summary = {
    "format": "wpf-linux-u1-shaping-comparison/1",
    "oracle": os.path.basename(oracle_path),
    "harfbuzzVersion": hb.version_string(),
    "cases": len(results), "match": matches, "mismatch": mismatches,
    "results": results,
}
json.dump(summary, open(out_path, "w", encoding="utf-8"), indent=1)

print(f"cases={len(results)} exact-match={matches} differ={mismatches}")
print()
print(f"{'case':<14}{'font':<24}{'px':>4}{'dw':>5}{'hb':>5}  {'glyphs':<8}{'maxAdvDelta':>12}{'totalDelta':>12}")
for r in results:
    print(f"{r['id']:<14}{r['font'].replace('NotoSans-','').replace('.ttf',''):<24}{r['emSizeDip']:>4.0f}"
          f"{len(r['dwriteGlyphs']):>5}{len(r['harfbuzzGlyphs']):>5}  "
          f"{'same' if r['glyphSequenceIdentical'] else 'DIFFER':<8}"
          f"{(r['maxAdvanceDeltaDip'] if r['maxAdvanceDeltaDip'] is not None else -1):>12.4f}{r['totalDeltaDip']:>12.4f}")
