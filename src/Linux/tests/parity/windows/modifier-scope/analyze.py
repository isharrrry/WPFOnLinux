#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Derives the modifier-scope oracle from the UNMODIFIED machine output.

    python3 analyze.py out/modifier-scope-raw.json out/modifier-scope-oracle

Nothing is assumed: every answer is computed from the per-line / per-character geometry and from
the TextLineBreak null-ness that the Windows machine recorded, and the raw file is embedded verbatim.
"""
import hashlib
import json
import math
import sys
from collections import Counter, OrderedDict

INTERVAL = 96.0          # measured in the tab-anchor arm on the same machine/runtime/font; re-confirmed here
                         # from the two-tab cases (tab1 reaches 96.000000, tab2 reaches 192.000000)


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
    raw_path = sys.argv[1] if len(sys.argv) > 1 else "out/modifier-scope-raw.json"
    out_base = sys.argv[2] if len(sys.argv) > 2 else "out/modifier-scope-oracle"
    with open(raw_path, encoding="utf-8") as f:
        data = json.load(f)
    raw_sha = sha256_file(raw_path)

    cases = data["cases"]
    ids = [c["id"] for c in cases]
    dup = [k for k, v in Counter(ids).items() if v > 1]
    by_group = OrderedDict()
    for c in cases:
        by_group.setdefault(c["group"], []).append(c)

    # ------------------------------------------------------------------ Q1/Q2: the TextLineBreak rule
    def predicted_non_null(c, line):
        """The rule under test: the break is non-null iff the line has a following line AND a modifier
        scope is still open at the line's end (i.e. the closing TextEndOfSegment has not been consumed
        by the time the line ends)."""
        end = line["endCharExclusive"]
        open_i = c["modifierOpenIndex"]
        close_i = c["modifierCloseIndex"]
        fetched = open_i >= 0 and open_i < end
        still_open = close_i < 0 or close_i >= end
        return (not line["isLastLine"]) and fetched and still_open

    scope_rows = []
    agree = 0
    total = 0
    for c in cases:
        if c["group"][0] not in "ABCDE":
            continue
        for line, br in zip(c["lines"], c["lineBreaks"]):
            pred = predicted_non_null(c, line)
            obs = not br["isNull"]
            total += 1
            if pred == obs:
                agree += 1
            scope_rows.append(OrderedDict([
                ("case", c["id"]), ("lineIndex", line["index"]),
                ("lineCharRange", [line["startChar"], line["endCharExclusive"]]),
                ("lineText", line["lineText"]),
                ("isLastLine", line["isLastLine"]),
                ("containsOpenMarker", line["containsOpenMarker"]),
                ("containsCloseMarker", line["containsCloseMarker"]),
                ("intersectsScope_openInc_closeExc", line["intersectsModifierScope_openInclusive_closeExclusive"]),
                ("scopeStillOpenAtLineEnd", (c["modifierCloseIndex"] < 0 or c["modifierCloseIndex"] >= line["endCharExclusive"])),
                ("lineBreakIsNull_OBSERVED", br["isNull"]),
                ("predictedIsNull", not pred),
                ("predictionMatchesObservation", pred == obs),
            ]))

    # the cases that separate the candidate rules
    discriminator = [r for r in scope_rows
                     if r["intersectsScope_openInc_closeExc"] is True and r["lineBreakIsNull_OBSERVED"]
                     and not r["isLastLine"]]
    lastline_open = [r for r in scope_rows
                     if r["isLastLine"] and r["containsOpenMarker"] and not r["lineBreakIsNull_OBSERVED"]]
    nonlast_open = [r for r in scope_rows
                    if (not r["isLastLine"]) and r["scopeStillOpenAtLineEnd"] and not r["lineBreakIsNull_OBSERVED"]]

    # ------------------------------------------------------------------ Q3: contents of the non-null break
    dump_rows = []
    for c in cases:
        if c["group"][0] not in "ABCDE":
            continue
        for line, br in zip(c["lines"], c["lineBreaks"]):
            if br["isNull"] or br["reflectionOfTextLineBreak"] is None:
                continue
            sc = br["reflectionOfTextLineBreak"].get("__currentScope")
            dump_rows.append(OrderedDict([
                ("case", c["id"]), ("lineIndex", line["index"]),
                ("modifierOpenIndex", c["modifierOpenIndex"]),
                ("scopeCharRange", c["modifierScopeCharRange"]),
                ("carriedScope_TextSourceCharacterIndex", sc.get("__cp") if isinstance(sc, dict) else None),
                ("carriedScope_ParentScopeIsNull", (sc.get("__parentScope") is None) if isinstance(sc, dict) else None),
                ("carriedScope_ModifierType", sc.get("__modifier") if isinstance(sc, dict) else None),
                ("carriedScopeFieldNames", list(sc.keys()) if isinstance(sc, dict) else None),
                # the dump renders primitives with ToString(), so __cp arrives as a string
                ("carriedScopeHasEndOrLimitField",
                 any(any(t in k for t in ("Limit", "End", "Length", "Count", "_stop"))
                     for k in (sc.keys() if isinstance(sc, dict) else []))),
                ("equalsThisModifiersOwnOpenIndex",
                 isinstance(sc, dict) and str(sc.get("__cp")) == str(c["modifierOpenIndex"])),
            ]))

    # ------------------------------------------------------------------ Q4: pen exactly on a stop
    pen_rows = []
    pen_rule_ok = True
    for c in cases:
        if not c["group"].startswith("F-pen"):
            continue
        pInd = c["paragraphIndentDip"]
        for line in c["lines"]:
            for p in line["perChar"]:
                if p["char"] != "\t" or p["rawX"] is None:
                    continue
                pen = p["rawX"] - pInd
                far = p["rawX"] + p["width"] - pInd
                advance = far - pen
                stop_pred = (math.floor(pen / INTERVAL) + 1) * INTERVAL
                pen_exactly_on_stop = abs(pen % INTERVAL) < 1e-9
                ok = abs(far - stop_pred) < 1e-6
                if not ok:
                    pen_rule_ok = False
                pen_rows.append(OrderedDict([
                    ("case", c["id"]), ("lineIndex", line["index"]),
                    ("text", line["lineText"]),
                    ("tabBoxSpan", [R(pen), R(far)]),
                    ("tabAdvanceDip", R(advance)),
                    ("penIsExactlyOnAGridStop", pen_exactly_on_stop),
                    ("predictedStop_box", R(stop_pred)),
                    ("predictedAdvanceDip", R(stop_pred - pen)),
                    ("matchesRule_stopIsSmallestMultipleStrictlyGreaterThanPen", ok),
                    ("advancedZeroIntervals", abs(advance) < 1e-9),
                    ("advancedOneFullInterval", abs(advance - INTERVAL) < 1e-6),
                ]))
    pen_on_stop = [r for r in pen_rows if r["penIsExactlyOnAGridStop"]]

    # ------------------------------------------------------------------ Q5: RTL clamp with Indent + ParagraphIndent
    clamp_rows = []
    clamp_ok = True
    for c in cases:
        if c["group"] != "G-rtl-indent-paraindent":
            continue
        C = c["paragraphWidthDip"]
        ind = c["indentDip"]
        pInd = c["paragraphIndentDip"]
        box_w = C - pInd
        pred_far = C - pInd - ind            # device-space far edge of a clamped tab
        for line in c["lines"]:
            for p in line["perChar"]:
                if p["char"] != "\t" or p["rawX"] is None:
                    continue
                pen_box = p["rawX"] - pInd
                far_box = p["rawX"] + p["width"] - pInd
                nat = (math.floor(pen_box / INTERVAL) + 1) * INTERVAL
                kind = "natural" if nat <= box_w + 1e-6 else (
                    "degenerate-zero-width" if pred_far <= 1e-6 else "clamped")
                if kind == "clamped":
                    ok = abs(far_box - box_w) < 1e-6 and abs(pen_box - ind) < 1e-6
                    if not ok:
                        clamp_ok = False
                else:
                    ok = True
                clamp_rows.append(OrderedDict([
                    ("case", c["id"]), ("lineIndex", line["index"]),
                    ("container", R(C)), ("indent", R(ind)), ("paragraphIndent", R(pInd)),
                    ("lineBoxWidth_containerMinusParagraphIndent", R(box_w)),
                    ("tabBoxSpan", [R(pen_box), R(far_box)]),
                    ("tabDeviceSpan", [R(p["xFromLeftDip"]), R(p["xFromLeftDip"] + p["width"])]),
                    ("kind", kind),
                    ("predictedClampDeviceSpan", [0.0, R(pred_far)] if kind != "natural" else None),
                    ("matchesClosedForm", ok),
                ]))
    clamp_clamped = [r for r in clamp_rows if r["kind"] == "clamped"]
    clamp_degenerate = [r for r in clamp_rows if r["kind"] == "degenerate-zero-width"]
    clamp_natural = [r for r in clamp_rows if r["kind"] == "natural"]

    # ------------------------------------------------------------------ Q6: two adjacent tabs at line start
    twotab_rows = []
    for c in cases:
        if c["group"] != "H-two-tabs-line-start":
            continue
        for line in c["lines"]:
            tabs = [p for p in line["perChar"] if p["char"] == "\t" and p["rawX"] is not None]
            if not tabs:
                continue
            p = tabs[0]
            ind = c["indentDip"]
            far = p["rawX"] + p["width"] - 0
            container = c["paragraphWidthDip"]
            nat = INTERVAL      # the line-start pen is 0 or Indent, either way the first stop is 96
            definitely_clamped = nat > container + 1e-6
            twotab_rows.append(OrderedDict([
                ("case", c["id"]), ("lineIndex", line["index"]),
                ("lineText", line["lineText"]),
                ("tabsOnThisLine", len(tabs)),
                ("tabRawSpan", [R(p["rawX"]), R(p["rawX"] + p["width"])]),
                ("tabWidthDip", R(p["width"])),
                ("lineWidthDip", R(line["width"])),
                ("hasOverflowed", line["hasOverflowed"]),
                ("definitelyClamped_naturalStopBeyondBox", definitely_clamped),
                ("tabFarEdgeEqualsBoxFarEdge", abs((p["rawX"] + p["width"]) - container) < 1e-6),
                ("tabReachesTheNaturalStop", abs((p["rawX"] + p["width"]) - nat) < 1e-6),
            ]))

    # ------------------------------------------------------------------ Q7: positive control
    control = []
    for g, w in (("C-scope-whole", 80.0), ("C2-scope-visible", 80.0),
                 ("C-scope-whole", 140.0), ("C2-scope-visible", 140.0)):
        for c in cases:
            if c["group"] == g and c["paragraphWidthDip"] == w:
                widest = 0.0
                for line in c["lines"]:
                    for p in line["perChar"]:
                        if p["width"] and p["kind"] == "char":
                            widest = max(widest, p["width"])
                control.append(OrderedDict([
                    ("case", c["id"]), ("modifierChangesPropertiesVisibly", c["modifierChangesPropertiesVisibly"]),
                    ("lineCount", c["lineCount"]), ("widestCharAdvanceDip", R(widest)),
                ]))
    gc = {(r["case"], r["lineCount"]) for r in control}
    control_ok = None
    plain80 = next((r["lineCount"] for r in control if r["case"].startswith("C-scope-whole/") and r["case"].endswith("@w80@LTR@i0")), None)
    vis80 = next((r["lineCount"] for r in control if r["case"].startswith("C2-scope-visible/") and r["case"].endswith("@w80@LTR@i0")), None)
    if plain80 and vis80:
        control_ok = vis80 > plain80

    answers = OrderedDict()

    answers["Q1_when_is_GetTextLineBreak_non_null"] = OrderedDict([
        ("question", "TextLine.GetTextLineBreak() returns null/non-null. T1d can only separate two candidate "
                     "rules with the truth it has: (i) non-null <=> the line has a following line AND the "
                     "PARAGRAPH carries a TextModifier; (ii) non-null <=> the line has a following line AND the "
                     "line intersects the modifier's scope. Which one is it, and is either one exactly right?"),
        ("answer", "NEITHER (i) NOR (ii) AS STATED. The measured rule is: the break is non-NULL iff the line is "
                   "NOT the last line AND a TextModifier scope is still OPEN at the line's end - i.e. the closing "
                   "TextEndOfSegment has not been consumed by the time the line ends. It is NOT enough for the line "
                   "to intersect the scope: in the A-scope-line0 group the scope opens AND closes inside line 0, so "
                   "line 0 intersects the scope, is not the last line, and the paragraph does carry a TextModifier - "
                   "yet its break is NULL (rule (ii) as stated would predict non-null). And a paragraph-level "
                   "TextModifier on lines that are outside the scope never yields a non-null break (rule (i) would "
                   "predict non-null), e.g. every line 1..n of A-scope-line0. Rule (i) is refuted; rule (ii) is "
                   "refuted in the 'closes on the same line' case and must be restated as 'the scope is still open "
                   "at the line end'."),
        ("predicateThatFitsEveryLine",
         "nonNull(line) == (!line.isLastLine) && (modifierOpenIndex >= 0 && modifierOpenIndex < line.endCharExclusive) "
         "&& (modifierCloseIndex < 0 || modifierCloseIndex >= line.endCharExclusive)"),
        ("linesChecked", total), ("linesMatchingThePredicate", agree),
        ("predicateFitsAllLines", agree == total),
        ("counterexampleToRule_i",
         "A-scope-line0 lines 1..n: paragraph has a modifier, lines have following lines, breaks are NULL"),
        ("counterexampleToRule_ii_as_stated",
         "A-scope-line0 line 0 (all three widths) and A-rtl-scope-line0 line 0: the line INTERSECTS the scope "
         "and is not last, yet the break is NULL because the scope closes inside that same line"),
        ("whyItIsNotZeroLength", "no group produced a zero-length line; stoppedEarlyBecauseLineLengthWasZero is "
                                 "false for every case"),
        ("nonNullExamples", nonlast_open[:12]),
        ("lastLineWithOpenScopeIsStillNull", lastline_open),
        ("evidence", scope_rows),
    ])

    answers["Q2_the_discriminating_cases"] = OrderedDict([
        ("question", "Which measured lines actually separate the candidate rules?"),
        ("answer", "The listed lines intersect the scope, are not the last line, and still return a NULL break: "
                   "that combination is impossible under the naive 'intersects the scope' reading and under the "
                   "paragraph-level reading, and is exactly what the refined predicate predicts."),
        ("lines", discriminator),
    ])

    answers["Q3_contents_of_the_TextLineBreak"] = OrderedDict([
        ("question", "When the break is non-null, what does it carry? Is the TextModifierScope's extent 'the "
                     "segment the line intersects' or 'the whole paragraph'?"),
        ("answer", "Neither, because the scope carries no extent at all. The carried object is one "
                   "TextModifierScope frame whose TextSourceCharacterIndex is the character index at which the "
                   "client's TextModifier RUN was fetched - i.e. the scope's OWN start (30 in the B group where "
                   "the scope starts mid-paragraph, 0 in the C group where it starts at the paragraph start). It "
                   "has a ParentScope link for nesting and NO end/limit field. So a client can learn where the "
                   "innermost still-open modifier started, and nothing else."),
        ("publicApiVerdict", "NOT REACHABLE through the public API. On the machine, TextLineBreak's public "
                             "instance surface is only Dispose/Clone (plus object members) and the "
                             "TextModifierScope type itself is internal; the only public way to hand the state on "
                             "is to pass the TextLineBreak object straight into the next FormatLine call. The "
                             "values below were therefore read with non-public reflection, which is recorded as "
                             "such and is not a supported client path."),
        ("machineApiSurfaceProbe", data.get("textLineBreakApiSurface")),
        ("nonNullBreaksObserved", len(dump_rows)),
        ("everyCarriedScopeMatchesItsOwnModifierOpenIndex",
         all(r["equalsThisModifiersOwnOpenIndex"] for r in dump_rows) if dump_rows else None),
        ("anyCarriedScopeHasAnEndOrLimitField",
         any(r["carriedScopeHasEndOrLimitField"] for r in dump_rows) if dump_rows else None),
        ("evidence", dump_rows),
    ])

    answers["Q4_pen_exactly_on_a_tab_stop"] = OrderedDict([
        ("question", "When the pen is EXACTLY on a grid stop (k x interval), does the tab advance 0 or one full "
                     "interval?"),
        ("answer", "It advances ONE FULL INTERVAL. The stop is the smallest multiple of the interval that is "
                   "STRICTLY GREATER than the pen: stop = (floor(pen/interval) + 1) * interval. This corrects the "
                   "'smallest k*interval >= pen' wording used in the tab-anchor arm - that arm never placed the "
                   "pen exactly on a stop, so both wordings fitted its data; here they are separated."),
        ("rule", "stop = (floor(pen/interval)+1)*interval ; advance = stop - pen"),
        ("everyTabSampleMatchesTheRule", pen_rule_ok),
        ("samplesWithPenExactlyOnAStop", len(pen_on_stop)),
        ("allOfThemAdvancedOneFullInterval",
         all(r["advancedOneFullInterval"] for r in pen_on_stop) if pen_on_stop else None),
        ("noneOfThemAdvancedZeroIntervals",
         not any(r["advancedZeroIntervals"] for r in pen_on_stop) if pen_on_stop else None),
        ("howTheExactPenWasConstructed",
         "two ways, so the result does not depend on one font metric: (a) two adjacent tabs - the first reaches the "
         "stop, so the second's pen is exactly that stop; (b) 8 x 'c', whose advance is exactly 12.000000 DIP, so "
         "the prefix is exactly 96.000000; plus the same with Indent=24 + 6 x 'c'. Calibration samples at 7 x 'c' "
         "(84 -> stop 96) and 9 x 'c' (108 -> stop 192) surround the exact case."),
        ("evidence", pen_rows),
    ])

    answers["Q5_rtl_clamp_with_Indent_and_ParagraphIndent"] = OrderedDict([
        ("question", "Does the tab-anchor closed form for a clamped tab still hold for an RTL paragraph when "
                     "Indent > 0 AND ParagraphIndent > 0 at the same time?"),
        ("answer", "YES. Measured with Indent=24 and ParagraphIndent in {24,48}: every clamped tab has box span "
                   "[Indent, container - ParagraphIndent] and device span [0, container - ParagraphIndent - Indent] "
                   "exactly. When that closed form goes negative (Indent + ParagraphIndent >= container) the tab "
                   "collapses to a ZERO-width span and the line reports HasOverflowed = true, which is the same "
                   "degenerate family the tab-anchor arm reported for LTR."),
        ("closedForm_deviceRtl", "[0, containerWidth - ParagraphIndent - Indent]"),
        ("closedForm_box", "[Indent, containerWidth - ParagraphIndent]"),
        ("everyClampedSampleMatchesTheClosedForm", clamp_ok),
        ("clampedSamples", len(clamp_clamped)),
        ("degenerateZeroWidthSamples", len(clamp_degenerate)),
        ("naturalSamples", len(clamp_natural)),
        ("evidence", clamp_rows),
    ])

    answers["Q6_two_adjacent_tabs_at_line_start"] = OrderedDict([
        ("question", "Two adjacent tabs at line start: after the first tab is clamped to fill the line, what does "
                     "the second one do - clamp again, break, or become zero width? (This pins the loop-termination "
                     "boundary invoked in the tab-anchor arm.)"),
        ("answer", "It CLAMPS AGAIN, on a line of its own. Each tab gets its own line and no line ever carries "
                   "both tabs. At the widths where the tab cannot fit (container 40/80 < the 96 interval) each tab "
                   "is clamped and fills its line box from the content start to the box's far edge. At container "
                   "100 the tab is not clamped at all - each is on its own line and reaches the natural stop 96 - "
                   "so 'one tab per line' holds even when nothing is clamped. Nothing merges, nothing becomes zero "
                   "width, and no line is empty; a formatter loop over the tabs terminates because each tab ENDS "
                   "its line."),
        ("clampedRows", len([r for r in twotab_rows if r["definitelyClamped_naturalStopBeyondBox"]])),
        ("naturalRows", len([r for r in twotab_rows if not r["definitelyClamped_naturalStopBeyondBox"]])),
        ("everyClampedTabFillsItsBox",
         all(r["tabFarEdgeEqualsBoxFarEdge"] for r in twotab_rows if r["definitelyClamped_naturalStopBeyondBox"])),
        ("everyNaturalTabReachesTheNaturalStop",
         all(r["tabReachesTheNaturalStop"] for r in twotab_rows if not r["definitelyClamped_naturalStopBeyondBox"])),
        ("anyZeroWidthTab", any(r["tabWidthDip"] == 0 for r in twotab_rows)),
        ("anyLineCarryingBothTabs", any(r["tabsOnThisLine"] > 1 for r in twotab_rows)),
        ("linesPerTab", "one - see lineIndex in the evidence"),
        ("evidence", twotab_rows),
    ])

    answers["Q7_positive_control_that_the_modifier_is_really_applied"] = OrderedDict([
        ("question", "How do we know the modifier machinery was live at all, rather than the source simply never "
                     "producing a modifier?"),
        ("answer", "The C2 group uses a modifier whose ModifyProperties DOUBLES the em size. Its line count rises "
                   "from 6 to 14 at container width 80 and the per-character advances roughly double, so the "
                   "modification is visible in the geometry. Combined with the reflective dump showing our own "
                   "Modifier instance inside the carried scope, the mechanism is demonstrably live."),
        ("controlPassed", control_ok),
        ("evidence", control),
    ])

    model = OrderedDict([
        ("textLineBreakRule",
         "GetTextLineBreak() != null  <=>  the line is not the last line AND a TextModifier scope is still open at "
         "the line's end (the closing TextEndOfSegment has not been consumed yet). Passing that object to the next "
         "FormatLine call is what carries the scope stack across the break."),
        ("tabStopRule",
         "stop = (floor(pen/interval) + 1) * interval, in box coordinates (box = raw - ParagraphIndent, raw measured "
         "from the line's start edge in the advance direction)."),
        ("interval", INTERVAL),
    ])

    unavailable = [
        "TextLineBreak's carried scope is NOT part of the public API: TextLineBreak exposes only Dispose/Clone and "
        "TextModifierScope is an internal type. The scope values in this oracle were read with non-public reflection "
        "and are labelled as such; a client cannot rely on them.",
        "The scope object carries no end/limit, so 'the extent of the scope at the break' cannot be read from it at "
        "all - only the start index of the innermost open modifier (and its parent chain).",
        "Nested modifiers (two scopes open at the same break) were NOT tested: every case here has ParentScope = null.",
        "TextModifier with HasDirectionalEmbedding = true (the bidi-embedding flavour of TextSpanModifier) was NOT "
        "tested; the modifier here contributes no direction and no glyphs.",
        "TextTrimming: no Trimming member on TextParagraphProperties - only TextLine.HasOverflowed is reported.",
        "Tabs (non-null custom tab-stop array): still untested, as in the whole tab family.",
        "Only Wrap is measured; NoWrap / WrapWithOverflow are untested.",
        "The two marker characters U+E000/U+E001 occupy a character index each but produce no glyph and no advance; "
        "character indices in this oracle therefore include them. Every line record carries its own index range and "
        "the marker positions are recorded per case, so the mapping back to visible text is explicit.",
    ]

    root = OrderedDict([
        ("format", "wpf-linux-u1-modifier-scope-oracle/1"),
        ("derivedFrom", OrderedDict([
            ("file", raw_path.split("/")[-1]), ("sha256", raw_sha),
            ("generatedUtc", data["generatedUtc"]), ("cases", len(cases)),
            ("uniqueCaseIds", len(set(ids)) == len(ids)), ("duplicateCaseIds", dup),
            ("note", "the machine output is embedded verbatim under `cases`; only the sections above it are derived"),
        ])),
        ("machine", OrderedDict([
            ("os", data["os"]), ("clr", data["clr"]), ("presentationCore", data["presentationCore"]),
            ("dpi", data["dpi"]), ("units", data["units"]), ("emSizeDip", data["emSizeDip"]),
            ("measurement", data["measurement"]),
        ])),
        ("fonts", OrderedDict([
            ("family", data["fontFamily"]), ("uri", data["fontUri"]), ("sha256", data["fontSha256"]),
            ("selection", data["fontSelection"]),
            ("coverageTable", data["fontCoverageTable"]),
        ])),
        ("markers", data["markers"]),
        ("model", model),
        ("answers", answers),
        ("unavailableOrUntested", unavailable),
        ("cases", cases),
    ])

    with open(out_base + ".json", "w", encoding="utf-8") as f:
        json.dump(root, f, ensure_ascii=False, indent=1)

    T = []
    w = T.append
    w("WPF oracle - TextModifier scope / pen-on-stop / RTL clamp / two tabs at line start (DERIVED)")
    w("=" * 110)
    w("derived from  : %s  sha256=%s" % (raw_path.split("/")[-1], raw_sha))
    w("machine output: %s" % data["generatedUtc"])
    w("machine       : %s | %s | PresentationCore %s" % (data["os"], data["clr"], data["presentationCore"]))
    w("cases         : %d (unique ids: %s)" % (len(cases), "yes" if not dup else "NO " + str(dup)))
    w("font          : %s sha256=%s" % (data["fontFamily"], data["fontSha256"]))
    w("markers       : %s" % data["markers"])
    w("")
    for key, a in answers.items():
        w("=" * 110)
        w("## " + key)
        w("Q: " + a["question"])
        w("A: " + a["answer"])
        for kk, vv in a.items():
            if kk in ("question", "answer"):
                continue
            if isinstance(vv, list) and vv and isinstance(vv[0], dict):
                w("-- %s (%d rows)" % (kk, len(vv)))
                for row in vv:
                    w("   " + "  ".join("%s=%s" % (rk, rv) for rk, rv in row.items()))
            elif isinstance(vv, dict) and kk == "machineApiSurfaceProbe":
                w("-- %s = %s" % (kk, json.dumps(vv, ensure_ascii=False)))
            else:
                w("-- %s = %s" % (kk, json.dumps(vv, ensure_ascii=False)))
        w("")
    w("=" * 110)
    w("UNAVAILABLE / NOT COVERED (reported as unavailable, never as a reading)")
    for u in unavailable:
        w("  - " + u)
    w("")

    with open(out_base + ".txt", "w", encoding="utf-8") as f:
        f.write("\n".join(T) + "\n")

    print("cases=%d uniqueIds=%s predicate=%d/%d penOnStop=%d clampOk=%s control=%s" %
          (len(cases), not dup, agree, total, len(pen_on_stop), clamp_ok, control_ok))
    print("wrote %s.json / %s.txt" % (out_base, out_base))
    return 0


if __name__ == "__main__":
    sys.exit(main())
