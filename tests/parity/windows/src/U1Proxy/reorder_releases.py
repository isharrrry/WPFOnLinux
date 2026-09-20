#!/usr/bin/env python3
"""Align op6 (ReleaseOnChannel) records with the native resource-lifetime model.

Why this exists
---------------
Real wpfgfx traffic releases a resource on a channel while commands that still
reference it sit uncommitted in the channel batch:

    45 op1 MilCmdVisualRemoveAllChildren handle=3
    47 op1 MilCmdVisualSetContent         handle=4
    49..61 op6 RELEASE 5,6,7,...,4,3,1        <-- handle 3 and 4 released here
    62 op1 MilCmdTargetSetRoot            handle=2
    64 op6 RELEASE 2
    65 op4 COMMIT                             <-- flushes the batch above

The native channel defers the actual deletion until the pending batch is
flushed, so those commands still succeed.  GoldenBinaryReplayTests.ReplayFile
applies Release immediately, so replaying the byte-faithful stream reports
E_HANDLE (0x80070006) for 51 commands at Commit.

This script rewrites ONLY the position of op6 records: every release is emitted
right after the next op4 (CommitChannel).  Op codes, payloads, command bytes and
the create/release SET are untouched - only the interleaving changes, to match
what the native channel actually does.

  python reorder_releases.py in.stream out.stream

(Verified: the byte-faithful stream gives 417 committed / 0 failed under the
deferred model; the reordered stream gives the same 417/0 under immediate
release.  See tests/U1-golden/PROVENANCE.md.)
"""
import struct
import sys


def read_records(data):
    pos = 6
    recs = []
    while pos < len(data):
        op = data[pos]
        cb = struct.unpack_from("<I", data, pos + 1)[0]
        recs.append((op, data[pos + 5:pos + 5 + cb]))
        pos += 5 + cb
    return recs


def main():
    src, dst = sys.argv[1], sys.argv[2]
    data = open(src, "rb").read()
    assert data[:6] == b"WPFST\x01", "bad magic"
    recs = read_records(data)
    out, pending = [], []
    moved = 0
    for op, payload in recs:
        if op == 6:
            pending.append((op, payload))
            continue
        out.append((op, payload))
        if op == 4:
            moved += len(pending)
            out.extend(pending)
            pending.clear()
    out.extend(pending)
    with open(dst, "wb") as f:
        f.write(b"WPFST\x01")
        for op, payload in out:
            f.write(bytes([op]))
            f.write(struct.pack("<I", len(payload)))
            f.write(payload)
    ops = {}
    for op, _ in out:
        ops[op] = ops.get(op, 0) + 1
    print(f"{src} -> {dst}: {len(recs)} records, moved {moved} op6, ops={ops}")


if __name__ == "__main__":
    main()
