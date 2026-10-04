#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ADDENDUM to the modifier-scope arm - answers the follow-up question
"which value of `closeIndex` did the 99/99 fit actually use?", WITHOUT re-running anything and
WITHOUT touching the delivered artifacts (their sha256 must stay valid).

    python3 closeindex-check.py out/modifier-scope-raw.json

Reads only the already-delivered raw machine output.
"""
import json
import sys
from collections import OrderedDict

INTERVAL = 96.0


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else "out/modifier-scope-raw.json"
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    cases = [c for c in data["cases"] if c["group"][0] in "ABCDE"]

    # ---------------------------------------------------------------- 1. the two indices, per group
    print("=" * 108)
    print("1. WHERE openIndex AND closeIndex COME FROM, AND THEIR VALUE PER GROUP")
    print("=" * 108)
    print("""
Both are properties of the CLIENT's run sequence, recorded verbatim in the raw machine output:
  openIndex  = c['modifierOpenIndex']  = the BUFFER INDEX at which the client's TextSource.GetTextRun
               returns a TextModifier run (the run's own Length is 1: one synthetic marker character).
  closeIndex = c['modifierCloseIndex'] = the BUFFER INDEX at which GetTextRun returns the matching
               TextEndOfSegment(1), or -1 when the client never closes the scope.
Neither is read out of WPF: they are the positions the client itself declared, and the oracle's `markers`
field documents the two synthetic characters (U+E000 / U+E001) that occupy them.
""")
    by_group = OrderedDict()
    for c in cases:
        by_group.setdefault(c["group"], []).append(c)
    print("%-22s %-34s %-9s %-11s %-9s %-11s %s" %
          ("group", "case", "openIndex", "closeMarker", "Length", "closeMark+1", "bufferLen"))
    for g, cs in sorted(by_group.items()):
        for c in cs:
            cm = c["modifierCloseIndex"]
            print("%-22s %-34s %-9s %-11s %-9s %-11s %s" %
                  (g, c["id"].split("/")[-1], c["modifierOpenIndex"], cm, 1,
                   (cm + 1) if cm >= 0 else -1, c["bufferLength"]))

    # ---------------------------------------------------------------- 2. fit both candidate definitions
    def close_index_repr(fn, c):
        return fn(c)

    def fits(c, line, close_index):
        end = line["endCharExclusive"]
        open_i = c["modifierOpenIndex"]
        fetched = open_i >= 0 and open_i < end
        still_open = close_index < 0 or close_index >= end
        return (not line["isLastLine"]) and fetched and still_open

    defs = OrderedDict([
        ("D_client_closeMarker      (the one that was used)",
         lambda c: c["modifierCloseIndex"]),
        ("D_i  = open + TextModifier.Length   (candidate i)",
         lambda c: (c["modifierOpenIndex"] + 1) if c["modifierOpenIndex"] >= 0 else -1),
        ("D_ii = paragraph end                 (candidate ii)",
         lambda c: c["bufferLength"]),
        ("D_client_closeMarker + 1   (pop after consuming the marker)",
         lambda c: (c["modifierCloseIndex"] + 1) if c["modifierCloseIndex"] >= 0 else -1),
    ])

    print()
    print("=" * 108)
    print("2. FIT OF EACH DEFINITION OVER ALL %d LINES OF THE SIX TEXTMODIFIER GROUPS" % sum(len(c["lines"]) for c in cases))
    print("=" * 108)
    results = OrderedDict()
    for name, fn in defs.items():
        agree = 0
        total = 0
        bad = []
        for c in cases:
            ci = fn(c)
            for line, br in zip(c["lines"], c["lineBreaks"]):
                total += 1
                obs_nonnull = not br["isNull"]
                pred = fits(c, line, ci)
                if pred == obs_nonnull:
                    agree += 1
                else:
                    bad.append((c["id"], line["index"], [line["startChar"], line["endCharExclusive"]],
                                line["isLastLine"], close_index_repr(fn, c), "predicted " +
                                ("non-null" if pred else "NULL"), "observed " +
                                ("non-null" if obs_nonnull else "NULL")))
        results[name] = (agree, total, bad)
        print("%-58s  %d/%d" % (name, agree, total))

    for name, (agree, total, bad) in results.items():
        if not bad:
            continue
        print()
        print("   mismatches for %s (%d):" % (name, len(bad)))
        for b in bad[:12]:
            print("     %-46s line%-2d range=%-9s isLast=%-5s closeIndex=%-4s %s, %s" %
                  (b[0], b[1], str(b[2]), b[3], b[4], b[5], b[6]))

    # ---------------------------------------------------------------- 3. which group separates them
    print()
    print("=" * 108)
    print("3. WHICH SAMPLES SEPARATE THE DEFINITIONS")
    print("=" * 108)
    sep_i = []
    sep_ii = []
    for c in cases:
        for line, br in zip(c["lines"], c["lineBreaks"]):
            obs = not br["isNull"]
            p_i = fits(c, line, (c["modifierOpenIndex"] + 1) if c["modifierOpenIndex"] >= 0 else -1)
            p_ii = fits(c, line, c["bufferLength"])
            p_true = fits(c, line, c["modifierCloseIndex"])
            if p_i != p_ii and p_true == obs:
                entry = (c["id"], line["index"], [line["startChar"], line["endCharExclusive"]],
                         line["isLastLine"], "clientClose=%s" % c["modifierCloseIndex"],
                         "D_i=%s D_ii=%s observed=%s" % (p_i, p_ii, obs))
                (sep_i if p_i != obs else sep_ii).append(entry)
    print("samples where candidate (i) and (ii) predict OPPOSITE things (and the client's own close marker tells the truth):")
    for e in sep_i + sep_ii:
        print("   %-46s line%-2d range=%-9s isLast=%-5s %-18s %s" % e)

    # ---------------------------------------------------------------- 4. Length vs real extent
    print()
    print("=" * 108)
    print("4. IS TextModifier.Length THE SCOPE EXTENT?")
    print("=" * 108)
    for c in cases:
        if c["modifierOpenIndex"] < 0:
            continue
        if c["id"].split("/")[-1].startswith(("scope-whole", "scope-visible")) and c["paragraphWidthDip"] == 80.0:
            lengths = set()
            for br in c["lineBreaks"]:
                r = br.get("reflectionOfTextLineBreak")
                if isinstance(r, dict):
                    sc = r.get("__currentScope")
                    if isinstance(sc, dict):
                        lengths.add(str(sc.get("__modifier")))
            print("   %-46s client TextModifier.Length=1  declared scope = [%s,%s)  -> %d characters" %
                  (c["id"], c["modifierOpenIndex"], c["modifierCloseIndex"] if c["modifierCloseIndex"] >= 0 else c["bufferLength"],
                   (c["modifierCloseIndex"] if c["modifierCloseIndex"] >= 0 else c["bufferLength"]) - c["modifierOpenIndex"]))
            print("        carried scope objects seen in the dumps: %s" % sorted(lengths))
    print("""
   The em-size-doubling control (C2-scope-visible) proves the scope really did cover the whole paragraph
   (line count 6 -> 14 at container width 80, every advance roughly doubled), while the TextModifier run
   that opened it declares Length = 1. So in this API the run's Length is the length of the MARKER RUN,
   not the extent of the scope; the extent is fixed by where the matching TextEndOfSegment is fetched.
""")
    return 0


if __name__ == "__main__":
    sys.exit(main())
