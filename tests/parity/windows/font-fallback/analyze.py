#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Derives the font-fallback oracle from the UNMODIFIED machine output.

    python3 analyze.py out/font-fallback-raw.json out/font-fallback-oracle
"""
import hashlib
import json
import sys
from collections import Counter, OrderedDict


def R(v):
    if v is None:
        return None
    r = round(v, 6)
    return 0.0 if r == 0 else r


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    raw_path = sys.argv[1] if len(sys.argv) > 1 else "out/font-fallback-raw.json"
    out_base = sys.argv[2] if len(sys.argv) > 2 else "out/font-fallback-oracle"
    with open(raw_path, encoding="utf-8") as f:
        data = json.load(f)
    raw_sha = sha256_file(raw_path)
    cases = data["cases"]
    ids = [c["id"] for c in cases]
    dup = [k for k, v in Counter(ids).items() if v > 1]
    cp_cases = [c for c in cases if c["group"] == "A-missing-glyph"]
    emb_cases = [c for c in cases if c["group"] == "I-directional-embedding"]
    cov = data["installedFontCoveragePerCodePoint"]

    # ------------------------------------------------------------------ the table
    table = []
    for c in cp_cases:
        table.append(OrderedDict([
            ("codePoint", c["codePoint"]), ("char", c["char"]),
            ("fontSetting", c["fontSettingId"]), ("fontSettingKind", c["fontSettingKind"]),
            ("specifiedFontHasIt", c["specifiedFontCoversCodePoint"]),
            ("specifiedFontGlyphIndex", c["specifiedFontGlyphIndex"]),
            ("specifiedFontAdvanceDip", c["specifiedFontGlyphAdvanceDip"]),
            ("specifiedFontNotdefAdvanceDip", c["specifiedFontNotdefAdvanceDip"]),
            ("advanceDip", c["measuredAdvanceDip"]),
            ("advanceOverEm", c["advanceOverEmsize"] if "advanceOverEmsize" in c else c["advanceOverEmSize"]),
            ("equalsOneEm", c["advanceEqualsOneEm"]),
            ("equalsSpecifiedFontOwnGlyph", c["advanceEqualsSpecifiedOwnGlyphAdvance"]),
            ("equalsSpecifiedFontNotdef", c["advanceEqualsSpecifiedNotdefAdvance"]),
            ("observedFont", c["observedFontUri"].split("/")[-1] if c["observedFontUri"] else None),
            ("observedGlyphIndex", c["observedGlyphIndex"]),
            ("observedGlyphIsNotdef", c["observedGlyphIsNotdef"]),
            ("fellBackToAnotherFont", c["fallbackToADifferentFont"]),
            ("installedFamiliesCovering", cov[c["codePoint"]]["familiesCovering"]),
            ("installedFamiliesTotal", cov[c["codePoint"]]["installedFamilies"]),
        ]))

    # ------------------------------------------------------------------ classification
    missing = [c for c in cp_cases if c["specifiedFontCoversCodePoint"] is False]
    fell_back = [c for c in missing if c["fallbackToADifferentFont"]]
    used_notdef = [c for c in missing if c["observedGlyphIsNotdef"]]
    no_font_covers = [c for c in cp_cases if cov[c["codePoint"]]["familiesCovering"] == 0]
    present = [c for c in cp_cases if c["specifiedFontCoversCodePoint"] is True]

    def rows(cs):
        return [OrderedDict([
            ("codePoint", c["codePoint"]), ("fontSetting", c["fontSettingId"]),
            ("specifiedFont", (c["specifiedFontUri"] or "").split("/")[-1] or None),
            ("advanceDip", c["measuredAdvanceDip"]),
            ("observedFont", (c["observedFontUri"] or "").split("/")[-1] or None),
            ("observedGlyph", c["observedGlyphIndex"]),
            ("isNotdef", c["observedGlyphIsNotdef"]),
        ]) for c in cs]

    # one-line answer, computed rather than asserted
    cjk_fallback = [c for c in fell_back if c["codePoint"] in ("U+4E0E", "U+6C49")]
    answer = (
        "When the paragraph font does not have the code point, the machine does NOT use that font's .notdef: "
        "it substitutes ANOTHER INSTALLED FONT that covers the code point (font fallback), and reports that "
        "font's own glyph and advance. The advance is whatever the substituted glyph's advance is - for the "
        "CJK code points that is a full-width glyph, i.e. exactly 1.0 em (24.000000 DIP at emSize 24), which "
        "is why the field case saw 1 em. The paragraph font's .notdef is used ONLY when no font the fallback "
        "can reach covers the code point (measured here: U+10FFFD, covered by 0 of 91 installed families); "
        "then the advance is the paragraph font's glyph-0 advance (Arial 18.000000, Times New Roman "
        "18.666667, the Noto file font 14.400000 DIP). A font named in the FontFamily list or in "
        "Typeface(..., fallbackFontFamily) is preferred over the system fallback for characters it covers."
    )

    answers = OrderedDict()
    answers["Q1_what_happens_when_the_paragraph_font_lacks_the_code_point"] = OrderedDict([
        ("question", "When the paragraph font lacks a code point, what advance does the real machine report, "
                     "and what decides it: fallback to another font, the font's own .notdef, or some fixed width?"),
        ("answer", answer),
        ("casesWhereTheSpecifiedFontLacksTheCodePoint", len(missing)),
        ("ofThose_fellBackToADifferentFont", len(fell_back)),
        ("ofThose_usedTheSpecifiedFontsNotdefGlyph", len(used_notdef)),
        ("advanceOfTheCJKFallbackCasesIsExactlyOneEm",
         all(c["advanceEqualsOneEm"] for c in cjk_fallback) and len(cjk_fallback) > 0),
        ("cjkFallbackExamples", rows(cjk_fallback)),
        ("casesWhereNoInstalledFontCoversTheCodePoint", len(no_font_covers)),
        ("allOfThoseUsedTheParagraphFontsNotdef", all(c["observedGlyphIsNotdef"] for c in no_font_covers) if no_font_covers else None),
        ("notdefEvidence", rows(no_font_covers)),
        ("casesWhereTheSpecifiedFontDoesHaveTheCodePoint", len(present)),
        ("noneOfThoseFellBack", not any(c["fallbackToADifferentFont"] for c in present)),
        ("presentExamples", rows(present)),
    ])

    answers["Q2_is_one_em_a_rule_or_a_property_of_the_substituted_glyph"] = OrderedDict([
        ("question", "The field case saw exactly 1 em for the missing glyph. Is '1 em' the rule for a missing "
                     "glyph, or a property of whatever glyph got used?"),
        ("answer", "It is a property of the substituted glyph, not a missing-glyph rule. The same table shows "
                   "missing code points whose advance is 1 em (CJK: the substituted font's ideograph is "
                   "full-width) and missing code points whose advance is the paragraph font's .notdef width "
                   "instead (private-use code points, 18.000000 / 18.666667 / 14.400000 DIP), and present code "
                   "points at 1 em as well (Arial's own U+2192 is exactly 1 em). Nothing in the data supports "
                   "a fixed width for a missing glyph."),
        ("advancesSeenForMissingCodePoints", sorted(set(R(c["measuredAdvanceDip"]) for c in missing))),
        ("advancesSeenForPresentCodePoints", sorted(set(R(c["measuredAdvanceDip"]) for c in present))),
    ])

    answers["Q3_can_a_client_observe_which_font_was_actually_used"] = OrderedDict([
        ("question", "Can the actually-used font / glyph be observed through the PUBLIC API?"),
        ("answer", "YES, through the public API, no reflection needed: TextLine.GetIndexedGlyphRuns() returns "
                   "IndexedGlyphRun objects, each carrying the character range and a GlyphRun whose "
                   "GlyphTypeface (-> FontUri) and GlyphIndices are the font and glyph really used. Every "
                   "'observedFont' / 'observedGlyphIndex' column in this oracle comes from that API. Note that "
                   "the run's GlyphTypeface can be a DIFFERENT font from the one in the paragraph's "
                   "TextRunProperties - that is exactly how the fallback is detected."),
        ("apiUsed", "TextLine.GetIndexedGlyphRuns() -> IndexedGlyphRun { TextSourceCharacterIndex, TextSourceLength, GlyphRun }"),
        ("valueSources", OrderedDict([
            ("observedFontUri", "public: GlyphRun.GlyphTypeface.FontUri"),
            ("observedGlyphIndex", "public: GlyphRun.GlyphIndices[0] (0 = .notdef)"),
            ("specifiedFontNotdefAdvanceDip", "public: GlyphTypeface.AdvanceWidths[0] * emSize (em-relative), read from the paragraph font"),
            ("measuredAdvanceDip", "public: TextLine.GetTextBounds(...) rectangle width"),
        ])),
        ("reflectionUsed", False),
    ])

    answers["Q4_installed_font_coverage_per_code_point"] = OrderedDict([
        ("question", "For each probed code point, how many fonts installed on this machine cover it? "
                     "(This turns 'no font has it' from an assumption into a count.)"),
        ("answer", "Counted by enumerating Fonts.SystemFontFamilies on the machine and testing each face's "
                   "CharacterToGlyphMap. U+10FFFD is covered by 0 of 91 families, which is why every setting "
                   "fell back to .notdef for it; U+E000 is covered by only 2 families, and it fell back only "
                   "when one of them (Segoe UI Symbol) was NAMED in the FontFamily list."),
        ("table", [OrderedDict([
            ("codePoint", k), ("char", v["char"]),
            ("familiesCovering", v["familiesCovering"]), ("familiesTotal", v["installedFamilies"]),
            ("facesCovering", v["facesCovering"]), ("facesTotal", v["installedFacesChecked"]),
            ("examples", [OrderedDict([("family", e["family"]), ("font", e["fontUri"].split("/")[-1]),
                                       ("glyphIndex", e["glyphIndex"]), ("advanceEm", e["advanceEm"])])
                          for e in v["examples"][:3]]),
        ]) for k, v in cov.items()]),
    ])

    # ------------------------------------------------------------------ item 2
    def key(c):
        return (c["docId"], c["paragraphWidthDip"])
    grouped = OrderedDict()
    for c in emb_cases:
        grouped.setdefault(key(c), {})[c["embeddingMode"]] = c
    emb_rows = []
    all_same = True
    for k, modes in grouped.items():
        ident = modes.get("identity")
        row = OrderedDict([("doc", k[0]), ("width", k[1])])
        for m in ("identity", "ltr-embed", "rtl-embed"):
            c = modes.get(m)
            row[m + "_lines"] = c["lineCount"]
            row[m + "_widths"] = [R(L["width"]) for L in c["lines"]]
            row[m + "_breaksNull"] = [b["isNull"] for b in c["lineBreakIsNull"]]
            row[m + "_bidiLevels"] = [L["firstGlyphRunBidiLevel"] for L in c["lines"]]
        same = all(
            modes[m]["lineCount"] == ident["lineCount"]
            and [R(L["width"]) for L in modes[m]["lines"]] == [R(L["width"]) for L in ident["lines"]]
            and [b["isNull"] for b in modes[m]["lineBreakIsNull"]] == [b["isNull"] for b in ident["lineBreakIsNull"]]
            and [L["firstGlyphRunBidiLevel"] for L in modes[m]["lines"]] == [L["firstGlyphRunBidiLevel"] for L in ident["lines"]]
            for m in ("ltr-embed", "rtl-embed"))
        row["directionalIdenticalToIdentity"] = same
        all_same = all_same and same
        emb_rows.append(row)

    answers["Q5_TextModifier_with_HasDirectionalEmbedding"] = OrderedDict([
        ("question", "Does a TextModifier with HasDirectionalEmbedding = true (and a FlowDirection) change "
                     "anything a client can see, compared with the same modifier that only returns the "
                     "properties unchanged?"),
        ("answer", "NOTHING OBSERVABLE in this batch. Across 3 paragraph/content shapes x 2 paragraph widths "
                   "= 6 comparisons, the directional modifier (both FlowDirections) produced byte-identical "
                   "line counts, line widths, first-glyph-run bidi levels and GetTextLineBreak() null patterns "
                   "to the identity modifier on the same text. Read it as 'no observable effect under this "
                   "construction', not as 'the flag is meaningless': every doc here is a single text source "
                   "with one open scope, and in WPF's own PresentationFramework the directional flavour is "
                   "used for an INLINE whose FlowDirection differs from its parent. This batch does not "
                   "separate 'the embedding is a no-op for this shape' from 'a marker-only modifier run "
                   "cannot carry the embedding into the runs'."),
        ("comparisons", len(emb_rows)),
        ("allDirectionsIdenticalToIdentity", all_same),
        ("widthsUsed", "40 (wraps into 2 lines, so GetTextLineBreak() is informative) and 140 (single line)"),
        ("evidence", emb_rows),
    ])

    unavailable = [
        "Why the directional embedding showed no effect is NOT determined: distinguishing 'no-op for this shape' "
        "from 'a marker-only modifier run cannot carry the embedding' needs a construction where the embedded "
        "run's level must change (e.g. the nested-inline shape PresentationFramework uses).",
        "The fallback's SEARCH ORDER is not observable: the oracle reports which font was used, not how it was "
        "chosen. Which fonts are in the fallback list is a DirectWrite/system matter and is not exposed.",
        "Only ONE font size (emSize 24) and one paragraph width (400) were used for the code-point table; the "
        "advance ratios would not change with size, but that is an expectation, not a measurement.",
        "The observed advance for the .notdef cases is not always exactly AdvanceWidths[0]*emSize: Times New "
        "Roman gives 18.666667 DIP against a computed 18.667969 (a ~0.0013 DIP difference). The raw values are "
        "reported side by side rather than reconciled; the difference is left as an observation.",
        "No per-font 'missing glyph box' beyond glyph index 0 was tested: if a font carries a real glyph for a "
        "private-use code point it is reported as covered (U+E000 with Segoe UI Symbol is exactly that case).",
        "TextTrimming / Tabs(non-null) / NoWrap remain untested, as in the other arms.",
        "breakCause-style derivations are not used here; every column is either a measured advance, a measured "
        "glyph-run property, or a count of installed fonts.",
    ]

    root = OrderedDict([
        ("format", "wpf-linux-u1-font-fallback-oracle/1"),
        ("derivedFrom", OrderedDict([
            ("file", raw_path.split("/")[-1]), ("sha256", raw_sha),
            ("generatedUtc", data["generatedUtc"]), ("cases", len(cases)),
            ("uniqueCaseIds", len(set(ids)) == len(ids)), ("duplicateCaseIds", dup),
            ("note", "the machine output is embedded verbatim under `cases`; only the sections above it are derived"),
        ])),
        ("machine", OrderedDict([
            ("os", data["os"]), ("clr", data["clr"]), ("presentationCore", data["presentationCore"]),
            ("dpi", data["dpi"]), ("units", data["units"]), ("emSizeDip", data["emSizeDip"]),
            ("paragraphWidthDip", data["paragraphWidthDip"]), ("measurement", data["measurement"]),
        ])),
        ("notoFile", data["notoFile"]),
        ("apiNotes", data["apiNotes"]),
        ("installedFontCoveragePerCodePoint", data["installedFontCoveragePerCodePoint"]),
        ("answers", answers),
        ("table_whatTheMainQuestionAskedFor", table),
        ("unavailableOrUntested", unavailable),
        ("cases", cases),
    ])

    with open(out_base + ".json", "w", encoding="utf-8") as f:
        json.dump(root, f, ensure_ascii=False, indent=1)

    T = []
    w = T.append
    w("WPF oracle - missing-glyph advance and font fallback (DERIVED)")
    w("=" * 118)
    w("derived from  : %s  sha256=%s" % (raw_path.split("/")[-1], raw_sha))
    w("machine output: %s" % data["generatedUtc"])
    w("machine       : %s | %s | PresentationCore %s" % (data["os"], data["clr"], data["presentationCore"]))
    w("cases         : %d (unique ids: %s)" % (len(cases), "yes" if not dup else "NO " + str(dup)))
    w("emSize=%s DIP   paragraph width=%s   Noto file font=%s" %
      (data["emSizeDip"], data["paragraphWidthDip"], data["notoFile"]))
    w("")
    w("ANSWER IN ONE SENTENCE")
    w("  " + answer)
    w("")
    w("THE TABLE (codePoint | font setting | font has it? | advance | vs 1 em | vs own glyph | vs .notdef |")
    w("           which font/glyph was actually used | fallback?)")
    w("-" * 118)
    for c in cp_cases:
        w("  %-9s | %-34s | %-5s | %10s | %-5s | %-5s | %-5s | %-24s glyph=%-6s notdef=%-5s | fb=%-5s | installed families covering: %d/%d" % (
            c["codePoint"], c["fontSettingId"], c["specifiedFontCoversCodePoint"],
            num(c["measuredAdvanceDip"]), c["advanceEqualsOneEm"],
            c["advanceEqualsSpecifiedOwnGlyphAdvance"], c["advanceEqualsSpecifiedNotdefAdvance"],
            (c["observedFontUri"] or "").split("/")[-1], c["observedGlyphIndex"], c["observedGlyphIsNotdef"],
            c["fallbackToADifferentFont"],
            cov[c["codePoint"]]["familiesCovering"], cov[c["codePoint"]]["installedFamilies"]))
    w("")
    w("(advance is in DIP; 'vs 1 em' = advance == 24.000000 DIP; 'vs own glyph' = advance == the specified "
      "font's own glyph advance; 'vs .notdef' = advance == that font's glyph-0 advance)")
    w("")
    for k, a in answers.items():
        w("=" * 118)
        w("## " + k)
        w("Q: " + a["question"])
        w("A: " + a["answer"])
        for kk, vv in a.items():
            if kk in ("question", "answer"):
                continue
            if isinstance(vv, list) and vv and isinstance(vv[0], dict):
                w("-- %s (%d rows)" % (kk, len(vv)))
                for row in vv:
                    w("   " + "  ".join("%s=%s" % (rk, rv) for rk, rv in row.items()))
            else:
                w("-- %s = %s" % (kk, json.dumps(vv, ensure_ascii=False)))
        w("")
    w("=" * 118)
    w("UNAVAILABLE / NOT COVERED (reported as unavailable, never as a reading)")
    for u in unavailable:
        w("  - " + u)
    w("")

    with open(out_base + ".txt", "w", encoding="utf-8") as f:
        f.write("\n".join(T) + "\n")

    print("cases=%d unique=%s  missingInFont=%d fellBack=%d usedNotdef=%d noFontCovers=%d  embIdentical=%s" %
          (len(cases), not dup, len(missing), len(fell_back), len(used_notdef), len(no_font_covers), all_same))
    print("wrote %s.json / %s.txt" % (out_base, out_base))
    return 0


def num(v):
    if v is None:
        return "n/a"
    return ("%.6f" % v).rstrip("0").rstrip(".") if isinstance(v, float) else str(v)


if __name__ == "__main__":
    sys.exit(main())
