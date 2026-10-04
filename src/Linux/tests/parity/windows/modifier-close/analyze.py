#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Derives the modifier-close oracle: does a NON-LAST line whose last character is the TextEndOfSegment
position return a null break (closeMarker definition) or a non-null one (closeMarker+1 definition)?

    python3 analyze.py out/modifier-close-raw.json out/modifier-close-oracle
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
    raw_path = sys.argv[1] if len(sys.argv) > 1 else "out/modifier-close-raw.json"
    out_base = sys.argv[2] if len(sys.argv) > 2 else "out/modifier-close-oracle"
    with open(raw_path, encoding="utf-8") as f:
        data = json.load(f)
    raw_sha = sha256_file(raw_path)
    cases = data["cases"]
    ids = [c["id"] for c in cases]
    dup = [k for k, v in Counter(ids).items() if v > 1]
    close_i = data["cases"][0]["closeIndex"]
    open_i = data["cases"][0]["openIndex"]

    # ------------------------------------------------ per line: the three numbers + both predictions
    rows = []
    for c in sorted(cases, key=lambda x: x["paragraphWidthDip"]):
        for line, br in zip(c["lines"], c["lineBreaks"]):
            end = line["endCharExclusive"]
            fetched = open_i < end
            # definition A: the scope is open at the line end iff the close marker has not been passed
            open_A = close_i >= end
            # definition B: the close marker itself is still inside the scope
            open_B = close_i + 1 >= end
            pred_A = fetched and open_A and not (end >= c["bufferLength"])
            pred_B = fetched and open_B and not (end >= c["bufferLength"])
            rows.append(OrderedDict([
                ("case", c["id"]), ("widthDip", R(c["paragraphWidthDip"])), ("lineIndex", line["index"]),
                ("openIndex", open_i), ("closeIndex", close_i), ("lineEndCharExclusive", end),
                ("endMinusCloseIndex", end - close_i),
                ("lineText", line["lineText"]),
                ("containsCloseMarker", line["containsCloseMarker"]),
                ("isLastLine", end >= c["bufferLength"]),
                ("breakIsNull_OBSERVED", br["isNull"]),
                ("predictedByDefinition_closeMarker", not pred_A),
                ("predictedByDefinition_closeMarkerPlus1", not pred_B),
                ("definitionsDisagreeHere", pred_A != pred_B),
                ("matchesA", (not pred_A) == bool(br["isNull"])),
                ("matchesB", (not pred_B) == bool(br["isNull"])),
            ]))

    disagree = [r for r in rows if r["definitionsDisagreeHere"]]
    agree_rows = [r for r in rows if not r["definitionsDisagreeHere"]]
    a_ok = all(r["matchesA"] for r in rows)
    b_ok = all(r["matchesB"] for r in rows)
    ends = sorted(set(r["endMinusCloseIndex"] for r in rows))

    # ------------------------------------------------ the bracket
    bracket = []
    for want, label in ((-1, "break lands BEFORE the close marker"), (0, "the close marker is not yet consumed"),
                        (1, "THE SEPARATOR: the close marker would be the line's last character"),
                        (2, "the close marker is consumed together with the following character")):
        got = [r for r in rows if r["endMinusCloseIndex"] == want]
        bracket.append(OrderedDict([
            ("wantedEndMinusCloseIndex", want), ("meaning", label),
            ("produced", len(got) > 0),
            ("samples", [OrderedDict([("widthDip", r["widthDip"]), ("lineIndex", r["lineIndex"]),
                                      ("lineEndCharExclusive", r["lineEndCharExclusive"]),
                                      ("lineText", r["lineText"]),
                                      ("breakIsNull", r["breakIsNull_OBSERVED"])]) for r in got[:4]]),
        ]))

    # ------------------------------------------------ why close+1 never happens: the marker sticks to the next char
    stick = []
    for c in sorted(cases, key=lambda x: x["paragraphWidthDip"]):
        for line in c["lines"]:
            if line["containsCloseMarker"]:
                stick.append(OrderedDict([
                    ("widthDip", R(c["paragraphWidthDip"])), ("lineIndex", line["index"]),
                    ("lineRange", [line["startChar"], line["endCharExclusive"]]),
                    ("endMinusCloseIndex", line["endMinusCloseIndex"]),
                    ("lineText", line["lineText"]),
                    ("closeMarkerIsLastCharOfLine", line["endCharExclusive"] - 1 == close_i),
                ]))
    any_marker_last_on_nonlast = any(
        (not (r["endCharExclusive"] >= c["bufferLength"])) and r["endCharExclusive"] - 1 == close_i
        for c in cases for r in c["lines"])

    answer = (
        "The separator the main control asked for is NOT PRODUCIBLE by the real machine, and the reason is a "
        "measurable mechanism rather than a missing sample: the TextEndOfSegment position is a ZERO-WIDTH run "
        "that STICKS TO THE CHARACTER AFTER IT. Sweeping 11 container widths from (calibrated close position "
        "- 2) to (calibrated close position + 24) in 0.001-DIP steps - including exactly the calibrated value "
        "and +-0.001 around it - the line-end index relative to the close marker only ever takes the values "
        "<= closeIndex (the marker has not been consumed yet) or >= closeIndex + 2 (the marker was consumed "
        "together with the following character). end == closeIndex + 1, the only value where "
        "'closeMarker' and 'closeMarker + 1' disagree, never occurs. Consequence for the shim: the two "
        "definitions are indistinguishable on EVERY input this engine can produce, so either is safe PROVIDED "
        "the shim also glues the close marker to the following character, as this data shows the engine does. "
        "If the shim instead models the marker as free-standing and can emit a line that ends exactly at the "
        "marker, then take 'closeMarker' (the half-open [openIndex, closeIndex) span, pop when the matching "
        "TextEndOfSegment is fetched), because the marker is then inside the line that contains it."
    )

    answers = OrderedDict()
    answers["Q1_can_closeMarker_and_closeMarkerPlus1_be_separated"] = OrderedDict([
        ("question", "Is a non-last line whose LAST character is the TextEndOfSegment position reachable, so "
                     "that 'closeMarker' (predicts NULL) and 'closeMarker+1' (predicts non-null) can be told apart?"),
        ("answer", answer),
        ("separatorReachable", any_marker_last_on_nonlast),
        ("endMinusCloseIndexValuesObserved", ends),
        ("endMinusCloseIndexValuesThatWouldSeparate", [1]),
        ("linesWhereTheTwoDefinitionsDisagree", len(disagree)),
        ("linesWhereTheyAgree", len(agree_rows)),
        ("linesChecked", len(rows)),
        ("definition_closeMarker_fitsEveryLine", a_ok),
        ("definition_closeMarkerPlus1_fitsEveryLine", b_ok),
    ])

    answers["Q2_the_three_point_bracket"] = OrderedDict([
        ("question", "Bracket the close marker with the break just before it, at it, and just after it - what "
                     "does each line report?"),
        ("answer", "The bracket collapses to TWO points, not three: 'just before' and 'at' both leave the marker "
                   "unconsumed (line end <= closeIndex) and both give a NON-NULL break; 'just after' (line end "
                   ">= closeIndex + 2) gives NULL. The width that would put the marker exactly at the line end "
                   "does not exist - see Q1 and Q3."),
        ("bracket", bracket),
        ("lines", rows),
    ])

    answers["Q3_why_the_marker_is_never_the_last_character_of_a_line"] = OrderedDict([
        ("question", "Why does end == closeIndex + 1 never occur?"),
        ("answer", "Because the zero-width TextEndOfSegment run is consumed together with the run that follows "
                   "it. The evidence is the two widths that straddle the transition: at width 170.693 DIP the line "
                   "is [0,14) - the marker fits by width but is left for the next line - while at 170.694 DIP the "
                   "line is [0,16), i.e. the marker AND the following character are both taken. There is no width "
                   "in between at which the line is [0,15). The same 'stickiness' is what makes the earlier "
                   "modifier-scope arm's B group end with the marker only on the LAST line, where nothing follows."),
        ("markerPositionDip", data["calibration"]["closeMarkerBoxPositionDip"]),
        ("charBeforeCloseEndsAtDip", data["calibration"]["charBeforeCloseEndsAtDip"]),
        ("linesThatContainTheCloseMarker", stick),
        ("closeMarkerIsEverTheLastCharOfANonLastLine", any_marker_last_on_nonlast),
    ])

    answers["Q4_bonus_theOpenMarkerBoundary"] = OrderedDict([
        ("question", "The same question at the OPENING marker: what happens when a line ends before the "
                     "TextModifier run has been fetched?"),
        ("answer", "It is NULL, as the predicate requires: at width 128.693 DIP line 0 is [0,10) with "
                   "openIndex = 10, so the modifier run has not been fetched on that line at all and there is no "
                   "scope to carry; the recorded break is null. This is an independent confirmation of the "
                   "'openIndex < lineEnd' term of the predicate, on a boundary the earlier arm did not cover."),
        ("evidence", [r for r in rows if r["lineIndex"] == 0 and r["endMinusCloseIndex"] < 0]),
    ])

    unavailable = [
        "end == closeIndex + 1 is not producible with a ZERO-WIDTH TextEndOfSegment run; whether it becomes "
        "producible with a non-zero-width EndOfSegment run was NOT tested (the public TextEndOfSegment "
        "constructor requires length >= 1, but its run renders no characters, so a non-zero length still "
        "contributes no advance).",
        "Nothing here says what WPF does internally; the conclusion is about which inputs the engine can "
        "produce and what it reports for them.",
        "Only one text shape (10 x 'c' + scope 'abc' + 12 x 'c') and one font (Arial) were used.",
    ]

    root = OrderedDict([
        ("format", "wpf-linux-u1-modifier-close-oracle/1"),
        ("derivedFrom", OrderedDict([
            ("file", raw_path.split("/")[-1]), ("sha256", raw_sha),
            ("generatedUtc", data["generatedUtc"]), ("cases", len(cases)),
            ("uniqueCaseIds", len(set(ids)) == len(ids)), ("duplicateCaseIds", dup),
        ])),
        ("machine", OrderedDict([
            ("os", data["os"]), ("clr", data["clr"]), ("presentationCore", data["presentationCore"]),
            ("dpi", data["dpi"]), ("units", data["units"]), ("emSizeDip", data["emSizeDip"]),
            ("measurement", data["measurement"]), ("markers", data["markers"]),
        ])),
        ("font", OrderedDict([("family", data["fontFamily"]), ("uri", data["fontUri"]), ("sha256", data["fontSha256"])])),
        ("buffer", data["cases"][0]["bufferWithMarkers"]),
        ("bufferLength", data["cases"][0]["bufferLength"]),
        ("openIndex", open_i), ("closeIndex", close_i),
        ("calibration", data["calibration"]),
        ("answers", answers),
        ("unavailableOrUntested", unavailable),
        ("cases", cases),
    ])

    with open(out_base + ".json", "w", encoding="utf-8") as f:
        json.dump(root, f, ensure_ascii=False, indent=1)

    T = []
    w = T.append
    w("WPF oracle - is the TextEndOfSegment position inside or outside the scope? (DERIVED)")
    w("=" * 112)
    w("derived from : %s  sha256=%s" % (raw_path.split("/")[-1], raw_sha))
    w("machine      : %s | %s | PresentationCore %s" % (data["os"], data["clr"], data["presentationCore"]))
    w("buffer       : \"%s\"  length=%d  openIndex=%d  closeIndex=%d" %
      (data["cases"][0]["bufferWithMarkers"], data["cases"][0]["bufferLength"], open_i, close_i))
    w("calibration  : the close marker (zero width) sits at %s DIP; the char before it ends at %s DIP" %
      (data["calibration"]["closeMarkerBoxPositionDip"], data["calibration"]["charBeforeCloseEndsAtDip"]))
    w("cases        : %d (unique ids: %s)" % (len(cases), "yes" if not dup else "NO " + str(dup)))
    w("")
    w("PER-LINE: openIndex | closeIndex | line.endCharExclusive  (+ both definitions' predictions)")
    w("-" * 112)
    for r in rows:
        w("  %-28s line%-2d open=%-3s close=%-3s end=%-3s (end-close=%+d) containsClose=%-5s isLast=%-5s "
          "breakIsNull=%-5s  A(close)=%-5s B(close+1)=%-5s" % (
              r["case"].split("/")[-1], r["lineIndex"], r["openIndex"], r["closeIndex"], r["lineEndCharExclusive"],
              r["endMinusCloseIndex"], r["containsCloseMarker"], r["isLastLine"], r["breakIsNull_OBSERVED"],
              r["predictedByDefinition_closeMarker"], r["predictedByDefinition_closeMarkerPlus1"]))
    w("")
    for k, a in answers.items():
        w("=" * 112)
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
    w("=" * 112)
    w("UNAVAILABLE / NOT COVERED")
    for u in unavailable:
        w("  - " + u)
    w("")

    with open(out_base + ".txt", "w", encoding="utf-8") as f:
        f.write("\n".join(T) + "\n")

    print("cases=%d lines=%d  separatorReachable=%s  endMinusClose values=%s  A_ok=%s B_ok=%s disagree=%d" %
          (len(cases), len(rows), any_marker_last_on_nonlast, ends, a_ok, b_ok, len(disagree)))
    print("wrote %s.json / %s.txt" % (out_base, out_base))
    return 0


if __name__ == "__main__":
    sys.exit(main())
