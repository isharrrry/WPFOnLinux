#!/usr/bin/env python3
"""Minimal PE/COFF export-table reader for wpfgfx_cor3.dll (no dependencies).

Prints the exports and writes a machine readable list so gen_proxy.py can build
the app-local forwarding proxy.  Read-only: never modifies the inspected file.
"""
import json
import struct
import sys


def u16(b, o):
    return struct.unpack_from("<H", b, o)[0]


def u32(b, o):
    return struct.unpack_from("<I", b, o)[0]


def parse(path):
    data = open(path, "rb").read()
    if data[:2] != b"MZ":
        raise SystemExit("not a PE file")
    pe = u32(data, 0x3C)
    if data[pe:pe + 4] != b"PE\0\0":
        raise SystemExit("no PE signature")
    coff = pe + 4
    machine = u16(data, coff)
    nsec = u16(data, coff + 2)
    size_opt = u16(data, coff + 16)
    opt = coff + 20
    magic = u16(data, opt)
    pe32plus = magic == 0x20B
    dd = opt + (112 if pe32plus else 96)
    exp_rva, exp_size = u32(data, dd), u32(data, dd + 4)

    secs = []
    sh = opt + size_opt
    for i in range(nsec):
        base = sh + i * 40
        name = data[base:base + 8].rstrip(b"\0").decode("latin1")
        vsize = u32(data, base + 8)
        vaddr = u32(data, base + 12)
        rawsize = u32(data, base + 16)
        rawptr = u32(data, base + 20)
        chars = u32(data, base + 36)
        secs.append((name, vaddr, vsize, rawptr, rawsize, chars))

    def rva2off(rva):
        for name, vaddr, vsize, rawptr, rawsize, chars in secs:
            if vaddr <= rva < vaddr + max(vsize, rawsize):
                return rawptr + (rva - vaddr)
        return None

    def section_of(rva):
        for name, vaddr, vsize, rawptr, rawsize, chars in secs:
            if vaddr <= rva < vaddr + max(vsize, rawsize):
                return name, chars
        return None, 0

    if exp_rva == 0:
        raise SystemExit("no export directory")

    eo = rva2off(exp_rva)
    nfunc = u32(data, eo + 20)
    nnames = u32(data, eo + 24)
    addr_funcs = u32(data, eo + 28)
    addr_names = u32(data, eo + 32)
    addr_ords = u32(data, eo + 36)
    base_ord = u32(data, eo + 16)
    dllname_off = rva2off(u32(data, eo + 12))
    dllname = data[dllname_off:data.index(b"\0", dllname_off)].decode("latin1")

    fo = rva2off(addr_funcs)
    no = rva2off(addr_names)
    oo = rva2off(addr_ords)

    out = []
    for i in range(nnames):
        name_off = rva2off(u32(data, no + 4 * i))
        name = data[name_off:data.index(b"\0", name_off)].decode("latin1")
        ordidx = u16(data, oo + 2 * i)
        rva = u32(data, fo + 4 * ordidx)
        if exp_rva <= rva < exp_rva + exp_size:
            kind = "forwarder"
        else:
            secname, chars = section_of(rva)
            kind = "code" if (chars & 0x20000000) else "data"
        out.append({"name": name, "ordinal": base_ord + ordidx, "rva": rva, "kind": kind})

    out.sort(key=lambda x: x["name"])
    return {
        "path": path,
        "machine": hex(machine),
        "dllName": dllname,
        "numberOfFunctions": nfunc,
        "numberOfNames": nnames,
        "baseOrdinal": base_ord,
        "exports": out,
    }


def main():
    path = sys.argv[1]
    dest = sys.argv[2] if len(sys.argv) > 2 else None
    info = parse(path)
    ex = info["exports"]
    kinds = {}
    for e in ex:
        kinds[e["kind"]] = kinds.get(e["kind"], 0) + 1
    print(f"file        : {info['path']}")
    print(f"machine     : {info['machine']}   internal name: {info['dllName']}")
    print(f"functions   : {info['numberOfFunctions']}   named: {info['numberOfNames']}   base ordinal: {info['baseOrdinal']}")
    print(f"kinds       : {kinds}")
    print(f"total named : {len(ex)}")
    interest = [n for n in ("MilChannel_BeginCommand", "MilChannel_AppendCommandData", "MilChannel_EndCommand",
                            "MilChannel_CommitChannel", "MilConnection_CommitChannel", "MilResource_SendCommand",
                            "MilChannel_SendCommand", "MilResource_CreateOrAddRefOnChannel",
                            "MilResource_ReleaseOnChannel", "MilConnection_CreateChannel")]
    have = {e["name"] for e in ex}
    print("key exports :")
    for n in interest:
        print(f"   {n:42s} {'PRESENT' if n in have else 'absent'}")
    if dest:
        with open(dest, "w", encoding="utf-8") as f:
            json.dump(info, f, indent=1)
        print(f"wrote {dest}")


if __name__ == "__main__":
    main()
