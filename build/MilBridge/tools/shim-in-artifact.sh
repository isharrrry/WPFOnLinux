#!/usr/bin/env bash
# shim-in-artifact.sh — lane T17A (item #17)
#
#   Does the compiled PresentationCore.dll actually contain the code of the
#   CURRENT build/shims/PresentationCore.HbTextLine.cs ?
#
# Reads the COMPILED ARTIFACT (managed metadata heaps of the DLL), never the source
# tree, for its verdict. The source tree is only used to (a) NAME the tokens and
# (b) PROVE the uniqueness/history claim behind each token.
#
# verdict line (stable, byte-identical across runs on an unchanged tree):
#   SHIM_IN_ARTIFACT=<PASS|WEAK-PASS|MISMATCH|NOINFO> artifact=<sha16> shim=<sha16> ...
#
# exit codes:  0 = all NEW and all STABLE tokens found
#              1 = at least one expected token (NEW or STABLE) is MISSING  -> artifact is not this revision
#              2 = NOINFO (artifact missing/unreadable/not a managed PE, or root unspecified)
#              3 = WEAK-PASS (nothing NEW could be established; STABLE-only => weak evidence)
#
# READ-ONLY: opens files with O_RDONLY, writes nothing outside stdout/stderr,
# never touches any bin/obj directory. Safe to run any number of times.
set -u

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'
options:
  --artifact <dll>   artifact to test (default: first existing of
                     build/PresentationCore.Linux/bin/Debug/PresentationCore.dll
                     build/PresentationCore.Linux/bin/Release/PresentationCore.dll)
  --shim <file>      shim source naming the tokens (default build/shims/PresentationCore.HbTextLine.cs)
  --backups <dir>    directory of older shim revisions named *<sha16>.cs (default $HOME/t1d-backups)
  --root <dir>       repo root (else $WPF_LINUX_ROOT, else resolved from script location, then cwd)
  --detail           also print per-token rows (default: summary + verdict only)
  -h | --help        this text
EOF
}

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${WPF_LINUX_ROOT:-}"
ARTIFACT=""
SHIM=""
BACKUPS="${HOME}/t1d-backups"
DETAIL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --artifact) ARTIFACT="${2:-}"; shift 2 ;;
    --shim)     SHIM="${2:-}";     shift 2 ;;
    --backups)  BACKUPS="${2:-}";  shift 2 ;;
    --root)     ROOT="${2:-}";     shift 2 ;;
    --detail)   DETAIL=1;          shift 1 ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "shim-in-artifact.sh: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

# --- root resolution: script location -> --root -> $WPF_LINUX_ROOT -> $PWD -----------------
# (same failure mode as tline-gate.sh: a silently wrong ROOT must become NOINFO, not a fake verdict)
resolve_root() {
  local d
  for d in "$SELF_DIR" "$ROOT" "$PWD"; do
    [ -n "$d" ] || continue
    d="$(cd "$d" 2>/dev/null && pwd)" || continue
    while [ "$d" != "/" ]; do
      if [ -f "$d/build/shims/PresentationCore.HbTextLine.cs" ] && [ -d "$d/build/PresentationCore.Linux" ]; then
        printf '%s\n' "$d"; return 0
      fi
      d="$(dirname "$d")"
    done
  done
  return 1
}
if ! ROOTDIR="$(resolve_root)"; then
  echo "SHIM_IN_ARTIFACT=NOINFO reason=root-unresolved (script=$SELF_DIR --root='$ROOT' cwd=$PWD)"
  exit 2
fi
[ -n "$SHIM" ]     || SHIM="$ROOTDIR/build/shims/PresentationCore.HbTextLine.cs"
[ -n "$ARTIFACT" ] || for c in \
      "$ROOTDIR/build/PresentationCore.Linux/bin/Debug/PresentationCore.dll" \
      "$ROOTDIR/build/PresentationCore.Linux/bin/Release/PresentationCore.dll"; do
  if [ -f "$c" ]; then ARTIFACT="$c"; break; fi
done

[ -n "$ARTIFACT" ] || { echo "SHIM_IN_ARTIFACT=NOINFO reason=artifact-not-found under $ROOTDIR/build/PresentationCore.Linux"; exit 2; }
[ -f "$SHIM" ]     || { echo "SHIM_IN_ARTIFACT=NOINFO reason=shim-not-found path=$SHIM"; exit 2; }

export T17_SHIM="$SHIM" T17_ARTIFACT="$ARTIFACT" T17_BACKUPS="$BACKUPS" T17_DETAIL="$DETAIL" T17_ROOT="$ROOTDIR"

python3 - <<'PY'
import glob, hashlib, os, re, struct, sys

SHIM     = os.environ["T17_SHIM"]
ARTIFACT = os.environ["T17_ARTIFACT"]
BACKUPS  = os.environ["T17_BACKUPS"]
DETAIL   = os.environ["T17_DETAIL"] == "1"
NAME     = "SHIM_IN_ARTIFACT"
rows     = []          # (bucket, token, enc, hits, where)

def sha16(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()[:16]

# ---------------------------------------------------------------------------------------
# Token table.  Every entry must be justified by an argument the script re-checks:
#   NEW     : present in the current shim source, ABSENT from every older shim revision
#             we physically hold -> introduced at this revision (missing prefix argument)
#   STABLE  : present in the current shim source AND in every older shim revision
#             -> long-lived name; presence alone is weak evidence (stated in the report)
#   RECENT  : present in current, absent from SOME older revisions (reported, not gating)
#   UNEMITTED: source-only (comment / method-local) token -- control proving that
#             comments and locals are NOT in the assembly; must have 0 heap hits
# ---------------------------------------------------------------------------------------
TOKENS = [
    # token                  bucket     enc        why
    ("_boxOriginX",          "NEW",     "utf8",    "private readonly double field introduced by D-O1 (last shim change of #16)"),
    ("boxOriginX",           "NEW",     "utf8",    "ctor parameter / argument name introduced by D-O1; all 5 occurrences added then"),
    ("HbTextLineScaffold",   "STABLE",  "utf8",    "public static helper class name; present since 09-14"),
    ("HbShaper",             "STABLE",  "utf8",    "internal static shaper class name"),
    ("HasOverflowed",        "STABLE",  "utf8",    "public override property name (re-implemented by D-O1)"),
    ("HbShapedRun",          "STABLE",  "utf8",    "internal sealed class name"),
    ("HbFontPlan",           "STABLE",  "utf8",    "internal sealed class name"),
    ("HbRunProperties",      "STABLE",  "utf8",    "internal sealed class name"),
    ("GetTextBounds",        "STABLE",  "utf8",    "method + counter property name"),
    ("GetTextRunSpans",      "STABLE",  "utf8",    "method + counter property name"),
    ("_paragraphWidth",      "STABLE",  "utf8",    "private readonly field name read by the D-O1 branch"),
    ("_width",               "STABLE",  "utf8",    "private readonly field name read by the D-O1 branch"),
    ("_keepState",           "STABLE",  "utf8",    "private readonly field name (collapse gate)"),
    ("_hasEop",              "STABLE",  "utf8",    "private readonly field name"),
    ("GlyphCount",           "STABLE",  "utf8",    "identifier; also a struct field of a test case, so hits>1 expected"),
    ("TryGetGlyphTypeface",  "STABLE",  "utf8",    "identifier (also occurs inside a literal -> hits>1 expected)"),
    ("[LIVEBLOBS] ",         "RECENT",  "utf16",   "string literal added at ac4104d67687c2c9; MUST be searched as UTF-16LE"),
    ("TryGetGlyphTypeface 失败（族 ", "RECENT", "utf16", "string literal added by D-F1b; non-ASCII -> UTF-16LE only"),
    ("行盒远缘",               "UNEMITTED", "utf16","comment-only phrase: hard control that comments are absent"),
    ("penLine",              "UNEMITTED", "utf8",  "method-local variable name: locals live in the PDB, not in assembly metadata"),
]

# ---------------------------------------------------------------------------------------
# 1. artifact must exist / be a managed PE  (NOINFO, never PASS, otherwise)
# ---------------------------------------------------------------------------------------
def noinfo(reason, extra=""):
    print(("%s=NOINFO reason=%s %s" % (NAME, reason, extra)).rstrip())
    sys.exit(2)

if not os.path.isfile(ARTIFACT):
    noinfo("artifact-not-found", "path=%s" % ARTIFACT)
try:
    with open(ARTIFACT, "rb") as f:
        blob = f.read()
except OSError as e:
    noinfo("artifact-unreadable", "path=%s err=%s" % (ARTIFACT, e.__class__.__name__))

def parse_heaps(blob):
    root = blob.find(b"BSJB")
    if root < 0:
        return None
    vlen = struct.unpack_from("<I", blob, root + 12)[0]
    if not (0 < vlen <= 256):
        return None
    o = root + 16 + vlen
    flags, n = struct.unpack_from("<HH", blob, o)
    o += 4
    heaps = {}
    for _ in range(n):
        off, size = struct.unpack_from("<II", blob, o)
        o += 8
        end = blob.index(b"\0", o)
        nm = blob[o:end].decode("ascii", "replace")
        o = (end + 1 + 3) & ~3
        if root + off + size <= len(blob):
            heaps[nm] = (root + off, size)
    return root, heaps

parsed = parse_heaps(blob)
if parsed is None:
    noinfo("not-a-managed-pe", "path=%s (no usable BSJB metadata root)" % ARTIFACT)
root, heaps = parsed
for need in ("#Strings", "#US", "#~"):
    if need not in heaps:
        noinfo("heap-missing", "heap=%s path=%s" % (need, ARTIFACT))
str_off, str_size = heaps["#Strings"]
us_off, us_size = heaps["#US"]
STR = blob[str_off:str_off + str_size]
US = blob[us_off:us_off + us_size]

# ---------------------------------------------------------------------------------------
# 2. source side: the tokens must really be in the current shim, with the stated history
# ---------------------------------------------------------------------------------------
try:
    with open(SHIM, "rb") as f:
        src = f.read().decode("utf-8", "replace")
except OSError as e:
    noinfo("shim-unreadable", "path=%s err=%s" % (SHIM, e.__class__.__name__))

# Reference revisions: only files that really are revisions of THIS shim count.
# The backup directory also holds probe snapshots (much smaller, different class), and a
# non-shim file in the reference set would corrupt every uniqueness count silently.
SHIM_MARKER = "class HbTextLine"
refs, refs_skipped = [], []
for p in sorted(glob.glob(os.path.join(BACKUPS, "*.cs"))):
    try:
        with open(p, "rb") as f:
            raw = f.read()
    except OSError:
        refs_skipped.append((os.path.basename(p), "unreadable"))
        continue
    text = raw.decode("utf-8", "replace")
    if len(raw) < 100000 or SHIM_MARKER not in text:
        refs_skipped.append((os.path.basename(p), "not-this-shim (%d B)" % len(raw)))
        continue
    refs.append((os.path.basename(p), text))

def occurrences(text, tok):
    """count exact-ish occurrences: word-bounded for identifiers, substring for phrases."""
    if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", tok):
        return len(re.findall(r"(?<![A-Za-z0-9_])%s(?![A-Za-z0-9_])" % re.escape(tok), text))
    return text.count(tok)

bad_src = [tok for tok, _, _, _ in TOKENS if occurrences(src, tok) == 0]
if bad_src:
    print("%s=NOINFO reason=token-not-in-current-shim tokens=%s path=%s" % (NAME, ",".join(bad_src), SHIM))
    sys.exit(2)

def absent_refs(tok):
    return sum(1 for _, t in refs if occurrences(t, tok) == 0)

# ---------------------------------------------------------------------------------------
# 3. decode the artifact: #Strings = UTF-8 NUL blobs, #US = UTF-16LE encoded literals
# ---------------------------------------------------------------------------------------
class StringsHit:
    def __init__(self, raw): self.raw = raw
    def count(self, tok):
        return self.raw.count(tok.encode("utf-8"))
    def where(self, tok):
        i = self.raw.find(tok.encode("utf-8"))
        return None if i < 0 else str_off + i

class UsHit:
    def __init__(self, raw): self.raw = raw
    def count(self, tok):
        return self.raw.count(tok.encode("utf-16-le"))
    def where(self, tok):
        i = self.raw.find(tok.encode("utf-16-le"))
        return None if i < 0 else us_off + i

class FileHit:                      # what an ASCII `grep -a` / `strings` sees
    def __init__(self, blob): self.raw = blob
    def count(self, tok):
        return self.raw.count(tok.encode("utf-8"))
    def where(self, tok):
        i = self.raw.find(tok.encode("utf-8"))
        return None if i < 0 else i

STRH, USH, FILEH = StringsHit(STR), UsHit(US), FileHit(blob)

def probe(tok):
    """Return (heap_hits, file_ascii_hits, heap_name, heap_offset) for a token."""
    if enc_of[tok] == "utf16":
        h = USH.count(tok); off = USH.where(tok); heap = "#US"
    else:
        h = STRH.count(tok); off = STRH.where(tok); heap = "#Strings"
    return h, FILEH.count(tok), heap, off

enc_of = {t: e for t, _, e, _ in TOKENS}

missing, found = [], []
for tok, bucket, enc, why in TOKENS:
    a = absent_refs(tok)
    h, f, heap, off = probe(tok)
    total = len(refs)
    rows.append(dict(tok=tok, bucket=bucket, enc=enc, why=why, src=occurrences(src, tok),
                     absent=a, refs=total, heap=heap, hits=h, file=f, off=off))
    if bucket in ("NEW", "STABLE"):
        (found if h > 0 else missing).append(tok)

# ---------------------------------------------------------------------------------------
# 4. self-check: the uniqueness claims must hold against the revisions we actually hold.
#    If they stop holding, the tool must refuse to print a verdict it cannot support.
# ---------------------------------------------------------------------------------------
bad_claims = []
for r in rows:
    if r["bucket"] == "NEW" and r["refs"] > 0 and r["absent"] != r["refs"]:
        bad_claims.append("%s(NEW but present in %d/%d refs)" % (r["tok"], r["refs"] - r["absent"], r["refs"]))
    if r["bucket"] == "STABLE" and r["refs"] > 0 and r["absent"] != 0:
        bad_claims.append("%s(STABLE but absent from %d/%d refs)" % (r["tok"], r["absent"], r["refs"]))
    if r["bucket"] == "UNEMITTED" and r["hits"] != 0:
        bad_claims.append("%s(declared UNEMITTED but heap hits=%d)" % (r["tok"], r["hits"]))

n_new = sum(1 for r in rows if r["bucket"] == "NEW")
n_stable = sum(1 for r in rows if r["bucket"] == "STABLE")
n_recent = sum(1 for r in rows if r["bucket"] == "RECENT")

art_sha, shim_sha = sha16(ARTIFACT), sha16(SHIM)

if bad_claims:
    print("%s=NOINFO reason=token-claim-invalid %s" % (NAME, "; ".join(bad_claims)))
    sys.exit(2)

# ---------------------------------------------------------------------------------------
# 5. verdict
# ---------------------------------------------------------------------------------------
weak = (n_new == 0)
if missing:
    verdict, rc = "MISMATCH", 1
elif weak:
    verdict, rc = "WEAK-PASS", 3
else:
    verdict, rc = "PASS", 0

recent_missing = [r["tok"] for r in rows if r["bucket"] == "RECENT" and r["hits"] == 0]
recent_found   = [r["tok"] for r in rows if r["bucket"] == "RECENT" and r["hits"] > 0]

bucket_of = {r["tok"]: r["bucket"] for r in rows}
new_ok = n_new - len([m for m in missing if bucket_of[m] == "NEW"])
stable_ok = n_stable - len([m for m in missing if bucket_of[m] == "STABLE"])

line = ("%s=%s artifact=%s artifact_bytes=%d shim=%s new=%d/%d stable=%d/%d "
        "missing=%s recent=%d/%d refs=%d") % (
    NAME, verdict, art_sha, len(blob), shim_sha,
    new_ok, n_new, stable_ok, n_stable,
    ",".join(missing) if missing else "-",
    len(recent_found), n_recent, len(refs))
print(line)

if DETAIL:
    if len(refs) < 5:
        print("# NOTE: only %d reference revision(s) found under %s -- the uniqueness argument is"
              " correspondingly weak; point --backups at the full revision set." % (len(refs), BACKUPS))
    print("# token                               bucket     enc    src_occ  absent_in_refs  heap        heap_hits  file_ascii_hits  file_off")
    for r in rows:
        print("# %-35s %-10s %-6s %-8d %-15s %-11s %-10d %-16d %s" % (
            r["tok"][:35], r["bucket"], r["enc"], r["src"],
            "%d/%d" % (r["absent"], r["refs"]), r["heap"], r["hits"], r["file"],
            ("0x%x" % r["off"]) if r["off"] is not None else "-"))
    print("# artifact=%s bytes=%d mtime=%d" % (ARTIFACT, len(blob), int(os.stat(ARTIFACT).st_mtime)))
    print("# shim=%s bytes=%d" % (SHIM, os.path.getsize(SHIM)))
    print("# reference revisions used for the uniqueness argument: %d (skipped: %d %s)" % (
        len(refs), len(refs_skipped), "; ".join("%s=%s" % x for x in refs_skipped) if refs_skipped else "-"))
    print("# heaps: #Strings@0x%x(%d) #US@0x%x(%d)" % (str_off, str_size, us_off, us_size))
    if missing:
        print("# MISSING (artifact does not contain the current revision's code): %s" % ", ".join(missing))
    if recent_missing:
        print("# recent-but-absent (informational, not gating): %s" % ", ".join(recent_missing))
    for r in rows:
        if r["bucket"] == "UNEMITTED":
            print("# control: %r heap_hits=%d file_ascii_hits=%d  (%s)" % (r["tok"], r["hits"], r["file"], r["why"]))

sys.exit(rc)
PY
