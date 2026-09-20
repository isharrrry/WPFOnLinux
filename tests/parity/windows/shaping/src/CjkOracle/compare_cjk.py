#!/usr/bin/env python3
"""Compare the CJK DirectWrite oracle against HarfBuzz, and measure the `locl` effect.

usage: PYTHONPATH=/tmp/u1/hb python3 compare_cjk.py <oracle.json> <ttcpath> <out.json>
"""
import json, sys
import uharfbuzz as hb

oracle_path, ttc, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
oracle = json.load(open(oracle_path, encoding="utf-8"))

blob = hb.Blob(open(ttc, "rb").read())
faces = {}
def shape(text, face_index, size_dip, language=None):
    if face_index not in faces:
        faces[face_index] = hb.Face(blob, face_index)
    face = faces[face_index]
    upem = face.upem
    font = hb.Font(face)
    font.scale = (upem, upem)
    buf = hb.Buffer()
    buf.add_str(text)
    buf.guess_segment_properties()
    if language:
        buf.language = language
    hb.shape(font, buf)
    scale = size_dip / upem
    return {
        "glyphs": [i.codepoint for i in buf.glyph_infos],
        "clusters": [i.cluster for i in buf.glyph_infos],
        "advances": [round(p.x_advance * scale, 6) for p in buf.glyph_positions],
        "total": round(sum(p.x_advance * scale for p in buf.glyph_positions), 6),
        "script": str(buf.script), "language": str(buf.language),
    }

# Noto Sans CJK faces carry language-specific default glyph forms; HarfBuzz only applies the
# `locl` feature when a language is set, so shape both ways.
LANG = {"JP": "ja", "KR": "ko", "SC": "zh-Hans", "TC": "zh-Hant", "HK": "zh-Hant-HK"}

rows, match_nolang, match_lang, total = [], 0, 0, 0
for c in oracle["cases"]:
    face_name = c["ttcFace"]
    fi = c["ttcFaceIndex"]
    size = c["emSizeDip"]
    a = shape(c["text"], fi, size)                       # no explicit language (guessed)
    b = shape(c["text"], fi, size, LANG.get(face_name))  # language set -> locl applies
    total += 1
    g_ok_a = c["glyphIds"] == a["glyphs"]
    g_ok_b = c["glyphIds"] == b["glyphs"]
    adv_ok = len(c["advancesDip"]) == len(b["advances"]) and \
             max([abs(x - y) for x, y in zip(c["advancesDip"], b["advances"])], default=0) < 0.01
    if g_ok_a: match_nolang += 1
    if g_ok_b: match_lang += 1
    rows.append({
        "id": c["id"], "face": face_name, "emSizeDip": size, "text": c["text"],
        "dwriteGlyphs": c["glyphIds"], "hbGlyphsNoLang": a["glyphs"], "hbGlyphsWithLang": b["glyphs"],
        "dwriteTotal": c["totalAdvanceDip"], "hbTotalNoLang": a["total"], "hbTotalWithLang": b["total"],
        "glyphsMatchNoLang": g_ok_a, "glyphsMatchWithLang": g_ok_b, "advancesMatchWithLang": adv_ok,
        "hbLanguageGuessed": a["language"], "hbLanguageForced": b["language"],
        "hbScript": a["script"],
    })

summary = {
    "format": "wpf-linux-u1-cjk-comparison/1",
    "oracle": oracle_path.split("/")[-1], "harfbuzzVersion": hb.version_string(),
    "cases": total, "glyphMatchNoLanguage": match_nolang, "glyphMatchWithLanguage": match_lang,
    "results": rows,
}
json.dump(summary, open(out_path, "w", encoding="utf-8"), indent=1)

print(f"cases={total}  glyph-sequence match: without language={match_nolang}  with language={match_lang}")
print()
print(f"{'case':<26}{'face':<5}{'px':>4}  {'noLang':<8}{'withLang':<10}{'advOk':<6}{'hbLang(guessed)':<18}")
for r in rows:
    print(f"{r['id']:<26}{r['face']:<5}{r['emSizeDip']:>4.0f}  "
          f"{('same' if r['glyphsMatchNoLang'] else 'DIFFER'):<8}"
          f"{('same' if r['glyphsMatchWithLang'] else 'DIFFER'):<10}"
          f"{('ok' if r['advancesMatchWithLang'] else 'DIFF'):<6}{r['hbLanguageGuessed']:<18}")
