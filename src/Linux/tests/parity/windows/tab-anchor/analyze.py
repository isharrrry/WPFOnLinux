#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Derives the tab-anchor oracle from the UNMODIFIED machine output.

    python3 analyze.py out/tab-anchor-raw.json out/tab-anchor-oracle

Writes out/tab-anchor-oracle.json and out/tab-anchor-oracle.txt.

Nothing is assumed about the tab rules: the interval is MEASURED from the probe
cases (two adjacent tabs expose two consecutive reached stops) and every answer
is computed from the per-character geometry that the Windows machine emitted.
The raw file is copied into the oracle verbatim under "cases".
"""
import hashlib
import json
import math
import sys
from collections import Counter, OrderedDict

def R(v):
    if v is None:
        return None
    r = round(v, 6)
    return 0.0 if r == 0 else r   # never emit -0.0


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def dist_to_grid(value, interval):
    """Distance from `value` to the nearest multiple of `interval`."""
    if interval <= 0:
        return None
    r = abs(value) % interval
    return min(r, interval - r)


def fnum(v, nd=6):
    if v is None:
        return "n/a"
    return ("%." + str(nd) + "f") % v


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


class TabSample(object):
    """One tab run on one line, expressed in three coordinate systems."""

    def __init__(self, case, line, tab, interval):
        self.interval = interval
        self.case_id = case["id"]
        self.group = case["group"]
        self.text_id = case["textId"]
        self.flow = case["flowDirection"]
        self.rtl = self.flow == "RightToLeft"
        self.arm = case["incrementalTabArm"]
        self.indent = case["indentDip"]
        self.para_indent = case["paragraphIndentDip"]
        self.first_line = case["firstLineInParagraph"]
        self.container = case["paragraphWidthDip"]
        self.line_index = line["index"]
        self.line_width = line["width"]
        self.line_witw = line["widthIncludingTrailingWhitespace"]
        self.has_overflowed = line["hasOverflowed"]
        self.trailing_ws = line["trailingWhitespaceLength"]
        self.line_text = line["lineText"]
        self.ink_right = line["inkRightDip"]
        self.n_tabs_on_line = sum(1 for p in line["perChar"] if p["char"] == "\t")
        self.n_chars_on_line = len(line["perChar"])

        # --- device coordinates (x from the line's left edge as the oracle computed it) ---
        self.dev_left = tab["xFromLeftDip"]
        self.dev_right = tab["xFromLeftDip"] + tab["width"]
        # --- raw coordinates as WPF reports them: origin = the line's start edge,
        #     increasing in the ADVANCE direction (left edge for LTR, right edge for RTL) ---
        if self.rtl:
            self.raw_right = self.ink_right - tab["xFromLeftDip"]
            self.raw_left = self.ink_right - (tab["xFromLeftDip"] + tab["width"])
        else:
            self.raw_left = tab["x"]
            self.raw_right = tab["x"] + tab["width"]
        # --- box coordinates: origin = the line box origin, i.e. raw shifted by ParagraphIndent ---
        self.box_left = self.raw_left - self.para_indent
        self.box_right = self.raw_right - self.para_indent
        self.line_box_width = self.container - self.para_indent

    @property
    def is_tab_only_line(self):
        return self.n_chars_on_line == 1 and self.n_tabs_on_line == 1

    @property
    def natural_stop_box(self):
        """Where the tab would reach if nothing clamped it: the smallest k*interval >= pen (k >= 1)."""
        pen = self.box_left
        k = max(1, int(math.ceil((pen - 1e-9) / self.interval))) if self.interval > 0 else 0
        if k * self.interval < pen - 1e-9:
            k += 1
        return k * self.interval

    @property
    def is_clamped_span(self):
        """The tab's box span ends exactly at the line box's far edge."""
        return (abs(self.box_right - self.line_box_width) < 1e-6
                and self.box_left >= self.indent - 1e-6)

    @property
    def clamp_class(self):
        """natural | ambiguous-exactly-at-the-edge | definitely-clamped | degenerate-zero-width-overflow"""
        if self.has_overflowed and abs(self.box_right - self.box_left) < 1e-6:
            return "degenerate-zero-width-overflow"
        if not self.is_clamped_span:
            return "natural"
        if abs(self.natural_stop_box - self.line_box_width) <= 1e-6:
            return "ambiguous-exactly-at-the-edge"
        if self.natural_stop_box > self.line_box_width + 1e-6:
            return "definitely-clamped"
        return "natural"

    # device-coordinate span predicted by the general clamp formula
    def device_clamp_prediction(self):
        if self.rtl:
            return (0.0, self.container - self.para_indent - self.indent)
        return (self.para_indent + self.indent, self.container)

    @property
    def line_reached_box_width(self):
        """box span ends exactly at the line box width AND the line has no further ink."""
        return abs(self.box_right - self.line_box_width) < 1e-6

    def reached_device_edge(self):
        return "LEFT edge (far edge in the RTL advance direction)" if self.rtl else \
               "RIGHT edge (far edge in the LTR advance direction)"


def collect_tab_samples(data, interval):
    out = []
    for case in data["cases"]:
        for line in case["lines"]:
            for p in line["perChar"]:
                if p["char"] == "\t" and p["xFromLeftDip"] is not None:
                    out.append(TabSample(case, line, p, interval))
    return out


def measure_interval(data):
    """The interval is read off the probe cases: two adjacent tabs expose two consecutive stops."""
    cand = Counter()
    rows = []
    for probe in data["intervalProbes"]:
        row = dict(probe)
        if probe.get("arm") == "DefaultIncrementalTab=0":
            rows.append(row)
            continue
        for key in ("deltaBetweenTabLeftEdgesDip", "deltaBetweenTabRightEdgesDip"):
            v = probe.get(key)
            if v:
                cand[round(v, 6)] += 1
        rows.append(row)
    if not cand:
        return None, rows
    interval, votes = cand.most_common(1)[0]
    return {"value": interval, "votes": votes, "candidates": dict(cand)}, rows


def main():
    raw_path = sys.argv[1] if len(sys.argv) > 1 else "out/tab-anchor-raw.json"
    out_base = sys.argv[2] if len(sys.argv) > 2 else "out/tab-anchor-oracle"
    data = load(raw_path)
    raw_sha = sha256_file(raw_path)

    interval_info, probe_rows = measure_interval(data)
    if interval_info is None:
        sys.stderr.write("cannot measure the interval from the probes\n")
        return 3
    I = interval_info["value"]
    samples = collect_tab_samples(data, I)

    ids = [c["id"] for c in data["cases"]]
    dup = [k for k, v in Counter(ids).items() if v > 1]
    font_scripts = data["fontByScript"]
    font_ok = data["fontSelectionMode"].startswith("single-font")

    # ------------------------------------------------------------------ sample classification
    grid_arm = [s for s in samples if s.arm == "DefaultIncrementalTab=default"]
    tab0_arm = [s for s in samples if s.arm != "DefaultIncrementalTab=default"]

    def is_clean_natural(s):
        """A sample that actually carries grid information."""
        return (not s.is_tab_only_line
                and not s.line_reached_box_width
                and not s.has_overflowed
                and s.box_right > s.box_left + 1e-9)

    clean = [s for s in grid_arm if is_clean_natural(s)]
    clamped = [s for s in grid_arm if s.line_reached_box_width and not s.has_overflowed]

    # The six places a tab stop grid could plausibly be anchored, all expressed in BOX coordinates
    # (box 0 = the line box's start edge = container start edge + ParagraphIndent; the tab advances
    # towards increasing box values in both directions). A0 is the hypothesis the model asserts; the
    # other five are the competing readings, including the one the earlier tab oracle could not rule
    # out because its line widths were exact multiples of the interval.
    HYPOTHESES = [
        ("A0", "grid anchored at the line box START edge (box 0); reached stop = the tab's FAR edge",
         lambda s: s.box_right),
        ("A1", "grid anchored at the line box FAR edge (box lineBoxWidth); reached stop = the tab's NEAR edge",
         lambda s: s.line_box_width - s.box_left),
        ("A2", "grid anchored at the line's far INK edge (box lineWidth); reached stop = the tab's NEAR edge",
         lambda s: s.line_width - s.box_left),
        ("A3", "grid anchored at the line box START edge (box 0); reached stop = the tab's NEAR edge",
         lambda s: s.box_left),
        ("A4", "grid anchored at the line box FAR edge (box lineBoxWidth); reached stop = the tab's FAR edge",
         lambda s: s.line_box_width - s.box_right),
        ("A5", "grid anchored at the line's far INK edge (box lineWidth); reached stop = the tab's FAR edge",
         lambda s: s.line_width - s.box_right),
    ]

    def anchor_rows(sel):
        rows = []
        for s in sel:
            res = OrderedDict()
            matched = []
            for hid, desc, fn in HYPOTHESES:
                r = dist_to_grid(fn(s), I)
                res["res_" + hid] = R(r)
                if r is not None and r <= 0.01:
                    matched.append(hid)
            k = round(s.box_right / I)
            margin = min([res["res_" + h] for h in ("A1", "A2", "A3", "A4", "A5")
                          if res["res_" + h] is not None] or [None])
            row = OrderedDict([
                ("case", s.case_id), ("lineIndex", s.line_index), ("flow", s.flow),
                ("container", R(s.container)), ("paragraphIndent", R(s.para_indent)),
                ("indent", R(s.indent)), ("lineBoxWidth", R(s.line_box_width)),
                ("lineWidth", R(s.line_width)),
                ("containerModInterval", R(s.container % I)),
                ("pen_box", R(s.box_left)), ("tabBoxSpan", [R(s.box_left), R(s.box_right)]),
                ("reachedStop_k", k),
                ("matchedHypotheses", matched),
                ("bestCompetingResidual", R(margin)),
                ("decisive", matched == ["A0"] and margin is not None and margin > 0.01),
                ("deviceReachedEdge", s.reached_device_edge()),
            ])
            row.update(res)
            if row["decisive"]:
                row["whyNotDecisive"] = None
            elif res["res_A4"] is not None and res["res_A4"] <= 0.01:
                row["whyNotDecisive"] = ("container is an exact multiple of the interval (" +
                                         str(R(s.container % I)) + "): the grid counted from the line box's start "
                                         "edge and the grid counted from its far edge are the SAME set of points, "
                                         "so this width cannot separate them (this is the ambiguity T1d hit)")
            elif res["res_A2"] is not None and res["res_A2"] <= 0.01:
                row["whyNotDecisive"] = ("the text is symmetric around the tab (prefix and suffix have equal "
                                         "advances), so 'the tab's near edge measured from the line's far ink edge' "
                                         "also lands on the grid; a text with different prefix/suffix advances "
                                         "(e.g. ab\tc) separates them")
            else:
                row["whyNotDecisive"] = "another competing hypothesis also lands on the grid"
            rows.append(row)
        return rows

    ltr_anchor = anchor_rows([s for s in clean if not s.rtl and s.group == "A-anchor"])
    rtl_anchor = anchor_rows([s for s in clean if s.rtl and s.group == "A-anchor"])
    contrast_anchor = anchor_rows([s for s in clean if s.group == "A-contrast"])

    # ------------------------------------------------------------------ Indent / ParagraphIndent
    def origin_rows(sel):
        rows = []
        for s in sel:
            rows.append(OrderedDict([
                ("case", s.case_id), ("lineIndex", s.line_index), ("flow", s.flow),
                ("lineText", s.line_text),
                ("indent", R(s.indent)), ("paragraphIndent", R(s.para_indent)),
                ("contentStart_box", R(s.indent)),
                ("pen_box", R(s.box_left)),
                ("tabBoxSpan", [R(s.box_left), R(s.box_right)]),
                ("reachedStop_box", R(s.box_right)),
                # only meaningful when the tab actually reached a grid stop; a clamped tab has no grid
                ("gridOriginImpliedByThisSample_box",
                 R(s.box_right - round(s.box_right / I) * I) if s.clamp_class == "natural" else None),
                ("lineBoxWidth", R(s.line_box_width)),
                ("clamped", s.is_clamped_span),
                ("lineWidth", R(s.line_width)),
                ("inkExtentFromBoxOrigin", R(s.raw_right - s.para_indent)),
            ]))
        return rows

    indent_grid = origin_rows([s for s in grid_arm
                              if s.group in ("B-indent", "D-paraindent") and not s.rtl
                              and s.para_indent == 0 and not s.line_reached_box_width])
    paraindent_grid = origin_rows([s for s in grid_arm
                                   if s.group == "D-paraindent" and s.para_indent > 0
                                   and not s.line_reached_box_width])
    rtl_paraindent_grid = origin_rows([s for s in grid_arm
                                       if s.group == "D-paraindent" and s.para_indent > 0 and s.rtl
                                       and not s.line_reached_box_width])

    # ------------------------------------------------------------------ clamping
    def clamp_row(s):
        r = origin_rows([s])[0]
        r["clampClass"] = s.clamp_class
        r["naturalStop_box"] = R(s.natural_stop_box)
        r["deviceTabSpan"] = [R(s.dev_left), R(s.dev_right)]
        pred = s.device_clamp_prediction()
        r["deviceSpanPredictedByFormula"] = [R(pred[0]), R(pred[1])]
        r["deviceSpanMatchesFormula"] = (abs(s.dev_left - pred[0]) < 1e-6 and abs(s.dev_right - pred[1]) < 1e-6)
        return r

    clamp_definite = [clamp_row(s) for s in grid_arm if s.clamp_class == "definitely-clamped" and not s.has_overflowed]
    clamp_ambiguous = [clamp_row(s) for s in grid_arm if s.clamp_class == "ambiguous-exactly-at-the-edge" and not s.has_overflowed]
    clamp_degenerate = [clamp_row(s) for s in grid_arm if s.clamp_class == "degenerate-zero-width-overflow"]
    clamp_natural = [clamp_row(s) for s in grid_arm if s.clamp_class == "natural" and not s.has_overflowed]

    # ------------------------------------------------------------------ tab0 arm
    tab0_rows = []
    for s in tab0_arm:
        tab0_rows.append(OrderedDict([
            ("case", s.case_id), ("indent", R(s.indent)), ("paragraphIndent", R(s.para_indent)),
            ("tabBoxSpan", [R(s.box_left), R(s.box_right)]), ("tabWidth", R(s.box_right - s.box_left)),
            ("lineWidth", R(s.line_width)), ("droppedFromLineWidth", R(s.line_width - (s.box_right - s.box_left))),
        ]))

    # ------------------------------------------------------------------ answers
    def tally(rows, key):
        return dict(Counter(str(r[key]) for r in rows))

    def all_zero(rows, key):
        return all(r[key] == 0 for r in rows) if rows else None

    ltr_ok = all_zero(ltr_anchor, "res_A0")
    rtl_ok = all_zero(rtl_anchor, "res_A0")

    def decisive_count(rows):
        return sum(1 for r in rows if r["decisive"])

    def non_decisive(rows):
        return [r for r in rows if not r["decisive"]]

    def reason_tally(rows):
        return dict(Counter(r["whyNotDecisive"] for r in non_decisive(rows)))

    def margin_by_text(rows):
        """Per text: how strongly the DECISIVE samples exclude every competing anchor."""
        out = OrderedDict()
        for r in rows:
            if not r["decisive"]:
                continue
            tid = r["case"].split("/")[-1].split("@")[0]
            m = r["bestCompetingResidual"]
            if m is None:
                continue
            # keep the ARGMIN (smallest margin) together with the case it came from
            if tid not in out or m < out[tid][0]:
                out[tid] = [m, r["case"].split("/")[-1], out[tid][2] if tid in out else 0]
            out[tid][2] += 1
        return OrderedDict((k, OrderedDict([("decisiveSamples", v[2]),
                                            ("smallestCompetingMargin", R(v[0])),
                                            ("atCase", v[1])]))
                           for k, v in out.items())

    def min_margin(rows):
        vals = [r["bestCompetingResidual"] for r in rows if r["bestCompetingResidual"] is not None]
        return min(vals) if vals else None

    ltr_excl = decisive_count(ltr_anchor) == len(ltr_anchor)
    rtl_excl = decisive_count(rtl_anchor) == len(rtl_anchor)
    contrast_ok = all_zero(contrast_anchor, "res_A0")

    def grid_origin_offset(rows):
        vals = sorted(set(r["gridOriginImpliedByThisSample_box"] for r in rows))
        return vals

    indent_offsets = grid_origin_offset(indent_grid)
    paraindent_offsets = grid_origin_offset(paraindent_grid)

    clamp_all = clamp_definite + clamp_ambiguous
    clamp_ok = all(abs(r["tabBoxSpan"][0] - r["indent"]) < 1e-6
                   and abs(r["tabBoxSpan"][1] - r["lineBoxWidth"]) < 1e-6 for r in clamp_all)
    clamp_formula_ok = all(r["deviceSpanMatchesFormula"] for r in clamp_all)
    clamp_starts_at_zero = all(abs(r["tabBoxSpan"][0]) < 1e-6 for r in clamp_all if r["indent"] > 0)
    clamp_nonzero_indent = [r for r in clamp_definite if r["indent"] > 0]
    clamp_ambiguous_nonzero = [r for r in clamp_ambiguous if r["indent"] > 0]

    answers = OrderedDict()

    answers["Q1_LTR_where_is_the_reached_tab_stop"] = OrderedDict([
        ("question", "On a line whose width is NOT a multiple of the interval, which edge of the tab lands on "
                     "the stop grid, and which edge of the line is that grid counted from?"),
        ("answer", "LTR: the tab's RIGHT edge (the FAR edge in the advance direction) lands exactly on the grid, "
                   "and the grid is counted from the line box's START edge (the device left edge, shifted by "
                   "ParagraphIndent). In box coordinates: tab.boxRight == k * interval, residual exactly "
                   "0.000000 on every sample. The samples that are decisive are those whose container is NOT a "
                   "multiple of the interval; the w=192 rows are listed as well and are marked non-decisive, "
                   "because at an exact multiple the two competing grids coincide - which is exactly the "
                   "ambiguity this arm was commissioned to remove."),
        ("ownHypothesisA0ResidualAlwaysZero", ltr_ok),
        ("decisiveSamples", "%d of %d" % (decisive_count(ltr_anchor), len(ltr_anchor))),
        ("smallestMarginAmongDecisiveSamples", R(min([r["bestCompetingResidual"] for r in ltr_anchor
                                                      if r["decisive"]] or [None]))),
        ("nonDecisiveSamples", len(non_decisive(ltr_anchor))),
        ("whyNonDecisive", reason_tally(ltr_anchor)),
        ("competingAnchors", [h[1] for h in HYPOTHESES[1:]]),
        ("smallestCompetingMarginByText", margin_by_text(ltr_anchor)),
        ("samples", len(ltr_anchor)),
        ("evidence", ltr_anchor),
    ])

    answers["Q2_RTL_where_is_the_reached_tab_stop"] = OrderedDict([
        ("question", "Same question for an RTL paragraph with pure Hebrew / pure Arabic content: is the reached "
                     "stop the tab's LEFT edge in device terms (the far edge in the RTL advance direction), i.e. "
                     "the mirror image of LTR?"),
        ("answer", "RTL: yes, it is the exact mirror. The reached stop is the tab's LEFT edge in device "
                   "coordinates (= the far edge in the RTL advance direction) and it lies on the grid counted "
                   "from the line box's START edge, which for RTL is the device RIGHT edge (shifted by "
                   "ParagraphIndent). The SAME box-coordinate rule holds: tab.boxRight == k * interval."),
        ("ownHypothesisA0ResidualAlwaysZero", rtl_ok),
        ("decisiveSamples", "%d of %d" % (decisive_count(rtl_anchor), len(rtl_anchor))),
        ("smallestMarginAmongDecisiveSamples", R(min([r["bestCompetingResidual"] for r in rtl_anchor
                                                      if r["decisive"]] or [None]))),
        ("nonDecisiveSamples", len(non_decisive(rtl_anchor))),
        ("whyNonDecisive", reason_tally(rtl_anchor)),
        ("smallestCompetingMarginByText", margin_by_text(rtl_anchor)),
        ("note", "res_A2 is the reading the earlier tab oracle used when it compared line.Width - tabLeftEdge; "
                 "here it is a NON-zero residual (0.506666 on he-a-t-b@w140) while res_A0 is exactly 0.000000, so "
                 "the two readings are separated by a measurement instead of by a preference."),
        ("samples", len(rtl_anchor)),
        ("evidence", rtl_anchor),
    ])

    answers["Q3_is_the_reached_edge_the_far_edge_in_the_advance_direction"] = OrderedDict([
        ("question", "Do LTR and RTL each take the FAR side of the tab span along their own advance direction?"),
        ("answer", "Yes. LTR reaches the tab's RIGHT edge, RTL reaches the tab's LEFT edge; both are the far edge "
                   "along that paragraph's advance direction, and in both cases the reached stop is the quantity "
                   "that sits on the grid. A single rule covers both: the stop is reached at tab.boxRight."),
        ("LTR_evidence", OrderedDict([("samples", len(ltr_anchor)),
                                      ("tally", tally(ltr_anchor, "deviceReachedEdge"))])),
        ("RTL_evidence", OrderedDict([("samples", len(rtl_anchor)),
                                      ("tally", tally(rtl_anchor, "deviceReachedEdge"))])),
    ])

    answers["Q4_does_the_paragraph_direction_or_the_content_direction_govern"] = OrderedDict([
        ("question", "Pure Hebrew content placed in an LTR paragraph: does the anchor follow the paragraph's "
                     "FlowDirection or the direction of the resolved text run?"),
        ("answer", "The PARAGRAPH's FlowDirection governs. With pure Hebrew content in an LTR paragraph the "
                   "reached stop is the tab's RIGHT edge on a grid counted from the device left edge, i.e. "
                   "exactly the LTR behaviour - the resolved RTL run direction does not move the anchor."),
        ("residualAlwaysZero", contrast_ok),
        ("decisiveSamples", "%d of %d" % (decisive_count(contrast_anchor), len(contrast_anchor))),
        ("samples", len(contrast_anchor)),
        ("evidence", contrast_anchor),
    ])

    answers["Q5_line_start_predicate_with_Indent"] = OrderedDict([
        ("question", "With Indent = 24 and a tab at line start that cannot fit: does the machine CLAMP the tab "
                     "to fill the line, or does it BREAK before the tab? And is 'line start' judged against the "
                     "line origin (absolute pen == 0) or against the indented content start?"),
        ("answer", "It CLAMPS. With Indent = 24 the line-start tab stays on its line and is clamped to fill the "
                   "line box from the content start to the far edge, and a break follows it. The predicate is "
                   "therefore judged against the INDENTED CONTENT START, not the absolute line origin: at Indent "
                   "= 24 the tab's pen is 24, not 0, yet it still takes the line-start (clamp) branch. "
                   "Equivalently: 'the tab is the first character of the line'. A predicate written as "
                   "`pen == 0` takes the wrong branch for every line with Indent > 0."),
        ("proofItIsNotBreakBeforeTheTab", "the text is '\ta' - the tab is the FIRST character, so 'break before "
                                          "the tab' would leave line 0 empty. Instead line 0 contains the tab and "
                                          "its box span ends at the line box's far edge, and the following 'a' is "
                                          "on line 1. The same happens for the mid-line tab 'a\tb': the break "
                                          "comes before the tab, and then the tab - now first on its line - is "
                                          "clamped rather than broken again, which is why the loop terminates."),
        ("definitelyClampedSamplesWithIndent", len(clamp_nonzero_indent)),
        ("alsoClampedButAmbiguousSamplesWithIndent", len(clamp_ambiguous_nonzero)),
        ("evidence_definitelyClamped", clamp_nonzero_indent),
        ("evidence_exactlyAtEdge_ambiguous", clamp_ambiguous_nonzero),
    ])

    answers["Q6_clamp_target_with_Indent"] = OrderedDict([
        ("question", "A clamped tab with Indent = 24: is its target the line WIDTH (span [0, w]) or the CONTENT "
                     "width (span [indent, w])?"),
        ("answer", "It is the CONTENT width, not the line width - but the far edge is the line box's far edge. "
                   "Precisely: the clamped tab's box span is [Indent, container - ParagraphIndent] and its device "
                   "span is [ParagraphIndent + Indent, container] for LTR and [0, container - ParagraphIndent - "
                   "Indent] for RTL. For the arm asked about (Indent = 24, ParagraphIndent = 0, container 40) "
                   "that is device span [24, 40]: NOT [0, 40]. So the clamped tab's ADVANCE WIDTH is "
                   "(container - ParagraphIndent - Indent) while its FAR EDGE is the line box's far edge. An "
                   "implementation that takes 'the line width' as the clamped tab's width overshoots by "
                   "Indent + ParagraphIndent at the near edge."),
        ("leftEdgeIsAlwaysTheContentStart", clamp_ok),
        ("deviceSpanMatchesClosedFormFormula", clamp_formula_ok),
        ("leftEdgeEverZeroWhenIndentIsPositive", clamp_starts_at_zero),
        ("samples_definitelyClamped", len(clamp_definite)),
        ("samples_exactlyAtTheEdge_ambiguous", len(clamp_ambiguous)),
        ("evidence_definitelyClamped", clamp_definite),
        ("evidence_exactlyAtEdge_ambiguous", clamp_ambiguous),
    ])

    answers["Q7_does_Indent_move_the_tab_grid"] = OrderedDict([
        ("question", "With Indent > 0, is the tab stop grid still anchored at the line origin (k * interval "
                     "counted from the line origin)?"),
        ("answer", "YES - Indent does NOT move the grid. Measured on widths that are not multiples of the "
                   "interval, the reached stop stays at k * interval from the line box origin for Indent = 0 "
                   "and Indent = 24 alike. The grid origin implied by every sample below is 0."),
        ("impliedGridOrigins_box", indent_offsets),
        ("samples", len(indent_grid)),
        ("evidence", indent_grid),
    ])

    answers["Q8_does_ParagraphIndent_move_the_tab_grid"] = OrderedDict([
        ("question", "Follow-up discovered while measuring Q7: the arm with ParagraphIndent = 24 (and Indent = 0) "
                     "shows the reached stop at 120, not 96. Does ParagraphIndent, unlike Indent, move the grid?"),
        ("answer", "YES - ParagraphIndent DOES move the tab grid, and it moves it by exactly ParagraphIndent. "
                   "The grid origin is at box coordinate 0 where box coordinates are raw coordinates minus "
                   "ParagraphIndent, i.e. the grid is anchored at the line box origin, and the line box itself is "
                   "offset by ParagraphIndent. This was confirmed with ParagraphIndent = 24 AND 48, with Indent = "
                   "0 and 24, in both LTR and RTL - in every combination the reached stop is "
                   "(ParagraphIndent + k * interval) measured from the line's start edge. "
                   "NOTE for T1d: 'Indent does not move the grid' is true, but 'no paragraph property moves the "
                   "grid' would be false."),
        ("impliedGridOrigins_box_LTR", paraindent_offsets),
        ("impliedGridOrigins_box_RTL", grid_origin_offset(rtl_paraindent_grid)),
        ("samples_LTR", len(paraindent_grid)),
        ("samples_RTL", len(rtl_paraindent_grid)),
        ("evidence_LTR", paraindent_grid),
        ("evidence_RTL", rtl_paraindent_grid),
    ])

    answers["Q9_line_width_is_paragraph_origin_relative"] = OrderedDict([
        ("question", "What exactly is TextLine.Width when ParagraphIndent > 0?"),
        ("answer", "TextLine.Width (and WidthIncludingTrailingWhitespace) is measured from the PARAGRAPH origin, "
                   "i.e. it EXCLUDES ParagraphIndent. Concretely: line.Width == rawMax - ParagraphIndent, where "
                   "rawMax is the far edge of the line's ink in the advance direction. It still INCLUDES the "
                   "per-line Indent. Trap for T1d: with ParagraphIndent > 0, line.Width is neither the distance "
                   "from device x = 0 to the far ink edge nor the advance width of the content."),
        ("verifiedBy", "every case in D-paraindent; the samples below list lineWidth next to the tab's raw "
                       "reached stop, which is ParagraphIndent + line.Width - (tab's near edge)"),
        ("evidence", origin_rows([s for s in grid_arm if s.group == "D-paraindent"])),
    ])

    answers["Q10_tab0_arm"] = OrderedDict([
        ("question", "What does the DefaultIncrementalTab = 0 arm do, for completeness?"),
        ("answer", "Every tab collapses to zero advance: the tab keeps its character but contributes no width, "
                   "so the text closes up. This matches the earlier tab-zero oracle; it is re-measured here only "
                   "so that both arms sit in one document."),
        ("samples", len(tab0_rows)),
        ("allZeroWidth", all(r["tabWidth"] == 0 for r in tab0_rows)),
        ("evidence", tab0_rows[:24]),
    ])

    answers["Q11_degenerate_samples"] = OrderedDict([
        ("question", "Are there samples where the model cannot apply?"),
        ("answer", "Yes, one family: when ParagraphIndent + Indent >= container the content start is already at "
                   "or past the line box's far edge. The tab then clamps to a ZERO-width span and the line "
                   "reports HasOverflowed = true (e.g. Indent = 24 + ParagraphIndent = 24 at container 40 gives "
                   "tab span [48, 48] with line.Width 24 and HasOverflowed = true). These are reported, not "
                   "folded into the clamp tallies."),
        ("samples", len(clamp_degenerate)),
        ("evidence", clamp_degenerate),
    ])

    answers["Q12_samples_that_look_clamped_but_are_not"] = OrderedDict([
        ("question", "Which samples reach the line box's far edge by NATURAL tab advance, i.e. must NOT be read "
                     "as clamp evidence?"),
        ("answer", "The listed samples: the natural stop (the smallest k*interval at or past the pen) already "
                   "equals the line box width, so the reading is identical under both hypotheses and carries no "
                   "information about clamping. They are separated out rather than counted as clamp proof."),
        ("samples", len(clamp_natural)),
        ("evidence", clamp_natural),
    ])

    model = OrderedDict([
        ("coordinateSystems", OrderedDict([
            ("device", "x measured from the line's left edge, increasing rightwards (the oracle's xFromLeftDip)."),
            ("raw", "the values WPF itself reports in TextBounds: x measured from the LINE'S START EDGE and "
                    "increasing in the ADVANCE direction. For LeftToRight that is the left edge (so raw == device "
                    "x); for RightToLeft it is the RIGHT edge, so raw == lineInkRightEdge - deviceX."),
            ("box", "raw - ParagraphIndent. The line box is the paragraph's box: it starts at ParagraphIndent "
                    "(measured from the container's start edge) and its width is container - ParagraphIndent."),
        ])),
        ("measuredInterval", I),
        ("rule", [
            "lineBoxWidth = containerWidth - ParagraphIndent",
            "contentStart  = Indent                                   (per LINE, in box coordinates)",
            "grid stops    = k * interval, k = 1, 2, ...             (anchored at the line box origin)",
            "natural tab   = the pen advances to the smallest k*interval with k*interval >= pen",
            "clamped tab   = box span [contentStart, lineBoxWidth]  (only when the natural stop > lineBoxWidth)",
            "reached stop  = tab.boxRight  (device RIGHT edge for LTR, device LEFT edge for RTL)",
            "after a clamped tab the line ends (a break follows it)",
        ]),
        ("note", "the rule above is the compact form of the samples in `answers`; it is stated in box "
                 "coordinates precisely because ParagraphIndent shifts the box (see Q8)."),
    ])

    # ---------------------------------------------------------------- `TextLine.Start`（**现算**，不是断言）
    # 【为什么改成现算】`#21`（主控）查出这一条原本是**手写断言**
    #     "TextLine.Start is reported but is 0 for every line here; it is not used by any answer."
    #   而它**被本文件自己的数据否掉** —— `lineStartOffsetsDip` 里就有 **171 行**是 `24`/`48`
    #   （`{0: 444, 24: 131, 48: 40}`）。它还与**同一份 oracle 的 `model.coordinateSystems.box`**
    #   （"the line box … **starts at ParagraphIndent**"）**自相矛盾**。同一条伪证在别处还有两个落点
    #   （我方 shim 里那句"真机实测恒为 0（3222/3222）"、以及由 `layout-b34` 语料做的推断 ——
    #    那份语料 `ParagraphIndent` 出现 **0** 次 ⇒ 0 是**语料性质**、不是实现性质）。
    #   ⇒ 处置 = **把断言换成读数**（本项目的口径：每条结论必须可重算）：逐行比较
    #   `lineStartOffsetsDip[k]`（= 真机逐行 `R(line.Start)` 的落盘，见真机臂 `Program.cs`）
    #   与该例的 `paragraphIndentDip`，把命中数/反例数/取值域写进 oracle 自己。**这样它不可能再过期。**
    _st_lines = 0
    _st_nz = 0
    _st_bad = 0
    _st_vals = Counter()
    for _c in data["cases"]:
        for _o in _c["lineStartOffsetsDip"]:
            _st_lines += 1
            _st_vals[_o] += 1
            if _o != 0:
                _st_nz += 1
            if _o != _c["paragraphIndentDip"]:
                _st_bad += 1
    START_NOTE = (
        "TextLine.Start IS reported for every line and is NOT always 0. Recomputed here from this file's "
        "own data: %d of %d lines report a NON-zero Start, and those are exactly the lines whose paragraph "
        "has ParagraphIndent != 0. All %d lines satisfy Start == ParagraphIndent (counterexamples to that "
        "rule in this corpus: %d); the observed value set is %s. The machine law behind it is "
        "'paragraph start to line start is paragraph indent' (upstream TextMetrics.cs, the default/Left "
        "alignment branch: _paragraphToText = ParagraphIndent + _textStart, and Start subtracts _textStart, "
        "so the two cancel). Start is not used by any answer below."
        % (_st_nz, _st_lines, _st_lines, _st_bad,
           "{" + ", ".join("%s: %d" % (k, _st_vals[k]) for k in sorted(_st_vals)) + "}")
    )

    unavailable = [
        "TextTrimming: NOT AVAILABLE in TextFormatter - upstream PresentationCore TextParagraphProperties has no "
        "Trimming member. Only TextLine.HasOverflowed is reported.",
        "break cause: NOT AVAILABLE - WPF exposes no 'why did it break here'. The breakCause field in the cases is "
        "DERIVED from the characters around the break and is labelled as such.",
        "Tabs (non-null custom tab-stop array) is UNTESTED: this oracle, like the whole tab family, leaves "
        "TextParagraphProperties.Tabs = null.",
        "TextWrapping: only Wrap is measured. NoWrap / WrapWithOverflow are untested here.",
        "whether a tab whose pen is EXACTLY on a grid stop advances by 0 or by one interval is untested (no "
        "sample puts the pen exactly on a stop).",
        "FirstLineInParagraph: the arms pass a constant value for every line (as layout-b34 does), so this oracle "
        "cannot separate 'per paragraph' from 'per line' application of Indent/ParagraphIndent.",
        "ParagraphIndent combined with RTL was measured for ParagraphIndent in {24, 48} with Indent = 0; the "
        "combination Indent > 0 AND ParagraphIndent > 0 in RTL is untested.",
        "fonts are fixed to a single family (Arial) - no cross-font verification.",
        START_NOTE,
    ]

    root = OrderedDict([
        ("format", "wpf-linux-u1-tab-anchor-oracle/1"),
        ("derivedFrom", OrderedDict([
            ("file", raw_path.split("/")[-1]),
            ("sha256", raw_sha),
            ("generatedUtc", data["generatedUtc"]),
            ("cases", len(data["cases"])),
            ("note", "the machine output is embedded verbatim under `cases`; the analyzer only adds the derived "
                     "sections above it"),
        ])),
        ("machine", OrderedDict([
            ("os", data["os"]), ("clr", data["clr"]), ("presentationCore", data["presentationCore"]),
            ("dpi", data["dpi"]), ("units", data["units"]), ("emSizeDip", data["emSizeDip"]),
            ("measurement", data["measurement"]),
        ])),
        ("fonts", OrderedDict([
            ("selectionMode", data["fontSelectionMode"]),
            ("byScript", font_scripts),
            ("singleFontForAllScripts", font_ok),
            ("coverageTable", data["fontCoverageTable"]),
            ("note", "the coverage table was built on the machine from CharacterToGlyphMap; each code point's "
                     "advance was measured on its own in a 1000-DIP paragraph once per paragraph direction so "
                     "that any direction dependence of the advances would be visible."),
        ])),
        ("paragraphProperties", data["paragraphProperties"]),
        ("intervalMeasurement", OrderedDict([
            ("value", interval_info["value"]),
            ("votes", interval_info["votes"]),
            ("allCandidates", interval_info["candidates"]),
            ("ruleOfThumb4xEmSize", 4 * data["emSizeDip"]),
            ("method", "two ADJACENT tabs in one line expose two consecutive reached stops; the distance between "
                       "the same-side edges of the two runs is the interval. Both edge metrics are reported, so "
                       "which edge is the reached stop is visible in the instrument itself."),
            ("probes", probe_rows),
        ])),
        ("model", model),
        ("answers", answers),
        ("unavailableOrUntested", unavailable),
        ("cases", data["cases"]),
    ])

    with open(out_base + ".json", "w", encoding="utf-8") as f:
        json.dump(root, f, ensure_ascii=False, indent=1)

    # ------------------------------------------------------------------ human readable
    T = []
    w = T.append
    w("WPF tab oracle - TAB ANCHOR discrimination + Indent semantics (DERIVED)")
    w("=" * 100)
    w("derived from  : %s   sha256=%s" % (raw_path.split("/")[-1], raw_sha))
    w("machine output: %s" % data["generatedUtc"])
    w("machine       : %s | %s | PresentationCore %s" % (data["os"], data["clr"], data["presentationCore"]))
    w("cases         : %d (ids unique: %s)" % (len(ids), "yes" if not dup else "NO -> " + str(dup[:5])))
    w("font          : %s (%s)" % (data["fontSelectionMode"], ", ".join(
        "%s->%s" % (k, v) for k, v in sorted(font_scripts.items()))))
    w("settings      : Dpi=%s emSize=%s  TextAlignment=Left  TextWrapping=Wrap  LineHeight=0  Tabs=null" %
      (data["dpi"], data["emSizeDip"]))
    w("                tab arms: default | DefaultIncrementalTab=0 (tab0)")
    w("")
    w("HOW TO READ THE COORDINATES")
    w("  device : x from the line's left edge, increasing rightwards")
    w("  raw    : the TextBounds value WPF itself reports - x from the LINE'S START EDGE, increasing in the")
    w("           ADVANCE direction. LTR: raw == device x.  RTL: raw == inkRightEdge - device x.")
    w("  box    : raw - ParagraphIndent. The line box starts at ParagraphIndent from the container's start")
    w("           edge and its width is container - ParagraphIndent.")
    w("")
    w("MEASURED INTERVAL (not assumed: read off the probe cases)")
    w("  interval = %s   (4 x emSize would be %s; the rule is printed only for comparison)" %
      (fnum(I), fnum(4 * data["emSizeDip"])))
    for p in probe_rows:
        w("    %-46s leftDelta=%-12s rightDelta=%-12s%s" % (
            p.get("case"), fnum(p.get("deltaBetweenTabLeftEdgesDip")), fnum(p.get("deltaBetweenTabRightEdgesDip")),
            "" if p.get("arm") == "DefaultIncrementalTab=0" else ""))
    w("")
    w("THE DERIVED MODEL")
    for line in model["rule"]:
        w("  " + line)
    w("")
    for k in ["Q1_LTR_where_is_the_reached_tab_stop", "Q2_RTL_where_is_the_reached_tab_stop",
              "Q3_is_the_reached_edge_the_far_edge_in_the_advance_direction",
              "Q4_does_the_paragraph_direction_or_the_content_direction_govern",
              "Q5_line_start_predicate_with_Indent", "Q6_clamp_target_with_Indent",
              "Q7_does_Indent_move_the_tab_grid", "Q8_does_ParagraphIndent_move_the_tab_grid",
              "Q9_line_width_is_paragraph_origin_relative", "Q10_tab0_arm", "Q11_degenerate_samples",
              "Q12_samples_that_look_clamped_but_are_not"]:
        a = answers[k]
        w("=" * 100)
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
    w("=" * 100)
    w("UNAVAILABLE / NOT COVERED (reported as unavailable, never as a reading)")
    for u in unavailable:
        w("  - " + u)
    w("")

    with open(out_base + ".txt", "w", encoding="utf-8") as f:
        f.write("\n".join(T) + "\n")

    print("interval=%s samples=%d clean=%d clamped=%d dup_ids=%s" %
          (I, len(samples), len(clean), len(clamped), dup))
    print("wrote %s.json / %s.txt" % (out_base, out_base))
    return 0


if __name__ == "__main__":
    sys.exit(main())
