#!/usr/bin/env python3
# T1 / MilBridge Phase 2 —— 从 MilNative 的 public 签名机械生成 108 个
# [UnmanagedCallersOnly(EntryPoint=...)] AOT 导出包装。
#
# 【为什么以内层 MilNative 签名为准，而不是以上游 exports.cs 签名为准】
#   M7a 已保证：108 个**导出名**在 MilNative 上都有同名 public static 方法
#   （MilNative.MissingExports() 返回空，是本脚本的前置断言）。
#   上游声明与 MilNative 声明的**托管类型**不同（SafeMILHandle→IntPtr、
#   MilMatrix3x2D*→double*、out bool→out int…），但**ABI 形状逐字段一致** ——
#   这正是 docs/unimplemented.md §2.5 那张表的作用。
#   所以：ABI 签名从 MilNative 的签名 + 类型映射表推导，转发也直接调 MilNative。
#
# 【生成的东西】
#   build/MilBridge/src/MilBridge.Linux/Exports.g.cs        —— 108 个包装
#   build/MilBridge/gen/export-symbols.txt                  —— 符号清单（nm 对拍用）
#   build/MilBridge/gen/landing-table.md                    —— 落地方式表
#
# 用法：python3 build/MilBridge/tools/gen-exports.py

import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
MB = os.path.abspath(os.path.join(HERE, ".."))
REPO = os.path.abspath(os.path.join(MB, "..", ".."))
SRC = os.path.join(REPO, "src", "WpfGfx.Linux", "Interop")

OUT_CS = os.path.join(MB, "src", "MilBridge.Linux", "Exports.g.cs")
OUT_SYMS = os.path.join(MB, "gen", "export-symbols.txt")
OUT_TABLE = os.path.join(MB, "gen", "landing-table.md")

# ======================================================================
#  1. 解析 MilNative 的全部 public static 方法签名
# ======================================================================
DECL_RE = re.compile(r"public static (?:unsafe )?([\w\.\<\>\*\[\]\?]+)\s+(\w+)\s*\(")


def parse_milnative():
    methods = {}
    for name in sorted(os.listdir(SRC)):
        if not name.startswith("MilNative") or not name.endswith(".cs"):
            continue
        text = open(os.path.join(SRC, name), encoding="utf-8-sig").read()
        for m in DECL_RE.finditer(text):
            ret, mname = m.group(1), m.group(2)
            i = m.end() - 1
            depth = 0
            j = i
            while j < len(text):
                if text[j] == "(":
                    depth += 1
                elif text[j] == ")":
                    depth -= 1
                    if depth == 0:
                        break
                j += 1
            raw = " ".join(text[i + 1:j].split())
            params = []
            if raw:
                for p in raw.split(","):
                    p = p.strip()
                    mm = re.match(r"^(?:(out|ref|in|params)\s+)?(.+?)\s+(\w+)$", p)
                    if not mm:
                        raise SystemExit(f"无法解析参数: {name}: {mname}({raw}) -> '{p}'")
                    params.append({"mod": mm.group(1) or "", "type": mm.group(2).strip(),
                                   "name": mm.group(3)})
            methods[mname] = {"file": name, "return": ret, "params": params}
    return methods


# ======================================================================
#  2. ABI 类型映射表
#     key = MilNative 里的托管类型；value = (ABI 类型, 需要几个 '*')
#     abi_base 为 None 表示"同名直通"。
# ======================================================================
ENUM_TO_ABI = {
    "DUCE.ResourceType": "int",
    "ChannelMarshalType": "int",
    "MilFillRule": "int",
    "MilSweepDirection": "int",
    "MilStretch": "int",
    "MilAlignmentX": "int",
    "MilAlignmentY": "int",
    "MilBrushMappingMode": "int",
    "MilGeometryCombineMode": "int",
    "MilPixelFormatEnum": "int",
    "MILRTInitializationFlags": "int",
    "MilIntersectionDetail": "int",
    "MilWicColorContextType": "uint",
}

# 直通（ABI 类型 == 托管类型，值按位复制）
PASSTHROUGH_PREFIX = ("byte*", "double*", "float*", "int*", "uint*", "long*", "short*", "ushort*")
PASSTHROUGH_EXACT = {
    "byte", "sbyte", "short", "ushort", "int", "uint", "long", "ulong", "float", "double",
    "MilPointD", "MilSizeD", "MilPointAndSizeD", "MilInt32Rect",
    "Guid", "DUCE.ResourceHandle", "MilMessage",
    "MIL_PEN_DATA*", "D3DMATRIX*", "MILRect3D*", "MilRectD*", "MilRectF*", "MilPointD*",
    "MilInt32Rect*", "byte**", "MilIntersectionDetail*", "D3DMATRIX", "MILRect3D", "MilRectF",
    "MilPointAndSizeD*", "MilSizeD*", "MilWicColorContextType*",
}


def abi_of(t, mod):
    """返回 (abi_type, kind)。kind ∈ handle/bool/enum/passthrough/array/string/delegate"""
    base = t
    if t == "IntPtr":
        return "void*", "handle"
    if t == "bool":
        return "int", "bool"
    if t in ENUM_TO_ABI:
        return ENUM_TO_ABI[t], "enum"
    if t == "byte[]":
        return "byte*", "bytearray"
    if t == "IntPtr[]":
        return "void**", "intptrarray"
    if t == "string":
        return "char*", "string"
    if t == "MilAddFigureCallback":
        return "void*", "delegate"
    if base in PASSTHROUGH_EXACT or base.startswith(PASSTHROUGH_PREFIX):
        return base, "passthrough"
    raise SystemExit(f"未映射的托管类型: {t}")


# ======================================================================
#  3. 手工覆盖（ABI 形状与返回值上必须偏离机械规则的地方，逐条给理由）
# ======================================================================
#   name -> dict(abi_return=..., body=..., note=...)
OVERRIDES = {}

OVERRIDES["MILSwDoubleBufferedBitmapGetBackBuffer"] = dict(
    abi_return="int",
    # 下面这些 out 句柄由本 override 自己的 body 处理，交给自动生成会产生
    # "赋值但未使用"的临时变量（CS0219）；显式给出 ABI 类型即可绕过。
    abi_param_types={"pBackBuffer": "void**", "pBackBufferSize": "uint*"},
    body="""            IntPtr back; uint size;
            MilNative.MILSwDoubleBufferedBitmapGetBackBuffer((nint)THIS_PTR, out back, out size);
            if (pBackBuffer != null) *pBackBuffer = (void*)back;
            if (pBackBufferSize != null) *pBackBufferSize = size;
            return 0;   // S_OK""",
    note="上游 PreserveSig=false（托管声明 void，原生必须返回 HRESULT）；MilNative 返回 void，故包装补 S_OK",
)
OVERRIDES["MILSwDoubleBufferedBitmapAddDirtyRect"] = dict(
    abi_return="int",
    body="""            MilInt32Rect rect = dirtyRect != null ? *dirtyRect : default;
            MilNative.MILSwDoubleBufferedBitmapAddDirtyRect((nint)THIS_PTR, ref rect);
            if (dirtyRect != null) *dirtyRect = rect;
            return 0;   // S_OK""",
    note="同上：PreserveSig=false → 原生必须返回 HRESULT",
)
OVERRIDES["MILMediaOpen"] = dict(
    note="上游 [MarshalAs(UnmanagedType.BStr)] string → ABI 是 wchar_t*（UTF-16），不是 char*",
    abi_param_types={"src": "ushort*"},
    body="""            string s = src == null ? null : new string((char*)src);
            return MilNative.MILMediaOpen((nint)THIS_PTR, s);""",
)
OVERRIDES["MILIStreamWrite"] = dict(
    note="上游 byte[] 是 LPArray：ABI 是裸指针，需要按 cb 建临时数组并回写",
    body="""            byte[] tmp = cb == 0 ? Array.Empty<byte>() : new byte[cb];
            if (buffer != null && cb > 0)
                new ReadOnlySpan<byte>(buffer, (int)cb).CopyTo(tmp);
            int hr = MilNative.MILIStreamWrite((nint)pStream, tmp, cb, out uint written);
            if (cbWritten != null) *cbWritten = written;
            if (buffer != null && cb > 0)
                new ReadOnlySpan<byte>(tmp, 0, (int)cb).CopyTo(new Span<byte>(buffer, (int)cb));
            return hr;""",
)
OVERRIDES["IWICColorContext_GetProfileBytes_Proxy"] = dict(
    note="上游 byte[] 是 LPArray（GetProfileBytes 的出参缓冲）：需要回写",
    body="""            byte[] tmp = pbBuffer == null || cbBuffer == 0 ? null : new byte[cbBuffer];
            int hr = MilNative.IWICColorContext_GetProfileBytes_Proxy((nint)THIS_PTR, cbBuffer, tmp, out uint actual);
            if (pcbActual != null) *pcbActual = actual;
            if (pbBuffer != null && tmp != null && actual > 0)
                new ReadOnlySpan<byte>(tmp, 0, (int)Math.Min(actual, cbBuffer))
                    .CopyTo(new Span<byte>(pbBuffer, (int)cbBuffer));
            return hr;""",
)
OVERRIDES["MilComposition_WaitForNextMessage"] = dict(
    note="上游 IntPtr[] handles 是 LPArray：ABI 是 void**，包装里重建托管数组",
    body="""            nint[] arr = null;
            if (handles != null && nCount > 0)
            {
                arr = new nint[nCount];
                for (int i = 0; i < nCount; i++) arr[i] = (nint)handles[i];
            }
            int hr = MilNative.MilComposition_WaitForNextMessage((nint)pChannel, nCount, arr, bWaitAll, waitTimeout, out int ret);
            if (waitReturn != null) *waitReturn = ret;
            return hr;""",
)

_DELEGATE_NOTE = ("上游 PathGeometry.AddFigureToListDelegate 是委托 → ABI 是函数指针；"
                  "包装里用 Marshal.GetDelegateForFunctionPointer 适配到 MilAddFigureCallback")
for _n in ("MilUtility_PathGeometryFlatten", "MilUtility_PathGeometryOutline",
           "MilUtility_PathGeometryWiden", "MilUtility_PathGeometryCombine"):
    OVERRIDES.setdefault(_n, {})["note"] = _DELEGATE_NOTE

# ======================================================================
#  3b. **不在上游清单里**的本工程自有导出（也必须进 .so）
# ======================================================================
#   这些名字不在 gen/milcore-dllimports.json 里（那份是上游 [DllImport] 的实测扫描），
#   但同样需要一个 [UnmanagedCallersOnly] 包装才可能被托管侧 GetExport 找到。
EXTRA_EXPORTS = [
    # T2 的 FontHandleTable.PathTokenAllocator 会 NativeLibrary.GetExport 这个名字。
    # 契约：intptr_t MilFontFace_RegisterFromFile(const char* utf8Path, int32 faceIndex,
    #                                              int32 simFlags);  0 = 失败。
    # 背景见 src/WpfGfx.Linux/Interop/MilNative.FontFace.cs 顶部。
    "MilFontFace_RegisterFromFile",
]


# ======================================================================
#  4. 生成
# ======================================================================
def build():
    mil = parse_milnative()
    manifest = json.load(open(os.path.join(MB, "gen", "milcore-dllimports.json")))
    exports = sorted({e["entry_point"] for e in manifest["entries"] if e.get("entry_point")})

    depths = {}
    man_src = open(os.path.join(SRC, "MilNative.Exports.cs"), encoding="utf-8-sig").read()
    for m in re.finditer(r'\{\s*"([A-Za-z_]\w*)"\s*,\s*ExportDepth\.(\w+)\s*\}', man_src):
        depths[m.group(1)] = m.group(2)

    missing = [e for e in exports if e not in mil]
    if missing:
        raise SystemExit(f"MilNative 缺方法（不应发生）: {missing}")
    if len(exports) != 108:
        raise SystemExit(f"上游导出名不是 108 个：{len(exports)}")

    # 本工程自有的额外导出（不参与 108 的校验，但必须一起生成符号）
    for extra in EXTRA_EXPORTS:
        if extra not in mil:
            raise SystemExit(f"EXTRA_EXPORTS 里的 {extra} 在 MilNative 上找不到 public static 方法")
        if extra not in exports:
            exports = exports + [extra]
    exports = sorted(exports)

    chunks = []
    symbols = []
    table = []
    for name in exports:
        sig = mil[name]
        ov = OVERRIDES.get(name, {})

        abi_ret = ov.get("abi_return")
        ret_conversion = ""
        if abi_ret is None:
            if sig["return"] == "void":
                abi_ret, ret_conversion = "void", "void"
            elif sig["return"] == "bool":
                abi_ret, ret_conversion = "int", "bool"
            else:
                abi_ret = sig["return"]

        abi_param_types = ov.get("abi_param_types", {})
        decls, call_args, pre, post = [], [], [], []

        for p in sig["params"]:
            nm = p["name"]
            if nm in abi_param_types:
                # 逐参 ABI 类型覆盖（例如 string→BSTR 是 ushort* 而不是 char*）
                decls.append(f"{abi_param_types[nm]} {nm}")
                if p["mod"]:
                    call_args.append(f"{p['mod']} *{nm}")
                else:
                    call_args.append(nm)
                continue
            t, kind = abi_of(p["type"], p["mod"])
            mod = p["mod"]

            if mod == "":
                if kind == "handle":
                    decls.append(f"void* {nm}")
                    call_args.append(f"(nint){nm}")
                elif kind == "bool":
                    decls.append(f"int {nm}")
                    call_args.append(f"{nm} != 0")
                elif kind == "enum":
                    decls.append(f"{t} {nm}")
                    call_args.append(f"({p['type']}){nm}")
                elif kind == "bytearray":
                    decls.append(f"byte* {nm}")
                    call_args.append(nm)           # 由 override body 处理
                elif kind == "intptrarray":
                    decls.append(f"void** {nm}")
                    call_args.append(nm)
                elif kind == "string":
                    decls.append(f"{t} {nm}")
                    call_args.append(nm)
                elif kind == "delegate":
                    decls.append(f"void* {nm}")
                    call_args.append(f"__cb_{nm}")
                    pre.append(
                        f"            MilAddFigureCallback __cb_{nm} = {nm} == null ? null : "
                        f"Marshal.GetDelegateForFunctionPointer<MilAddFigureCallback>((nint){nm});")
                else:
                    decls.append(f"{t} {nm}")
                    call_args.append(nm)
                continue

            # out / ref
            abi_t = t + "*"
            decls.append(f"{abi_t} {nm}")
            local = f"__v_{nm}"
            if kind == "handle":
                pre.append(f"            nint {local} = " +
                           (f"({nm} != null ? (nint)*{nm} : 0);" if mod == "ref" else "0;"))
                call_args.append(f"{mod} {local}")
                post.append(f"            if ({nm} != null) *{nm} = (void*){local};")
            elif kind == "bool":
                pre.append(f"            bool {local} = " +
                           (f"({nm} != null && *{nm} != 0);" if mod == "ref" else "false;"))
                call_args.append(f"{mod} {local}")
                post.append(f"            if ({nm} != null) *{nm} = {local} ? 1 : 0;")
            elif kind == "enum":
                pre.append(f"            {p['type']} {local} = " +
                           (f"({nm} != null ? ({p['type']})(*{nm}) : default);" if mod == "ref" else "default;"))
                call_args.append(f"{mod} {local}")
                post.append(f"            if ({nm} != null) *{nm} = ({t}){local};")
            else:
                call_args.append(f"{mod} *{nm}")

        abi_sig = ", ".join(decls)
        args = ",\n                ".join(call_args)
        call = f"MilNative.{name}({args})"

        body_lines = []
        body_lines.extend(pre)
        if ov.get("body"):
            # 自带 body 的条目自己负责写回与 return（上面已逐条注释理由），
            # 因此**不追加**自动 post —— 否则 return 之后会出现不可达代码（CS0162）。
            body_lines.append(ov["body"])
        else:
            need_local = bool(post)
            if ret_conversion == "void":
                body_lines.append(f"            {call};")
            elif ret_conversion == "bool" and not need_local:
                # 上游 bool 返回 = 4 字节 Win32 BOOL，[UnmanagedCallersOnly] 不允许 bool
                # 出现在 ABI 签名里，所以这里转成 int（0/1）。
                body_lines.append(f"            return {call} ? 1 : 0;")
            elif need_local:
                body_lines.append(f"            int __hr = {call};")
                body_lines.extend(post)
                body_lines.append("            return __hr;")
            else:
                body_lines.append(f"            return {call};")

        note = ov.get("note")
        note_line = f"        // {note}\n" if note else ""
        chunks.append(
            f"        /// <summary>{name} —— 落地方式 AOT 包装；实现深度 {depths.get(name, '?')}。</summary>\n"
            f"{note_line}"
            f'        [UnmanagedCallersOnly(EntryPoint = "{name}")]\n'
            f"        public static {abi_ret} {name}({abi_sig})\n"
            f"        {{\n" + "\n".join(body_lines) + "\n        }\n")

        symbols.append(name)
        table.append((name, depths.get(name, "?"), "AOT 包装" + ("（含类型适配）" if note else ""),
                      mil[name]["file"]))

    header = f'''// <auto-generated>
//   T1 / MilBridge Phase 2 —— 108 个 MilCore 导出的 NativeAOT 包装。
//   生成器：build/MilBridge/tools/gen-exports.py（**不要手改本文件**）
//   数据源：src/WpfGfx.Linux/Interop/MilNative*.cs 的 public static 签名
//           + build/MilBridge/gen/milcore-dllimports.json（上游 110 条 [DllImport] 的实测扫描）
//
//   每条包装的形状 = 上游 [DllImport(DllImport.MilCore)] 声明的 C ABI 形状。
//   三条通用转换规则（详见 docs/T1-report.md）：
//     R1  IntPtr / Safe*Handle → void*
//     R2  bool（P/Invoke 默认 = 4 字节 Win32 BOOL）→ int
//     R3  out T / ref T → T*
//   另有 {len(OVERRIDES)} 条需要类型适配（byte[] / string / 委托 / PreserveSig=false），逐条带注释。
// </auto-generated>

using System;
using System.Runtime.InteropServices;
using WpfGfx.Linux.Interop;

namespace MilBridge
{{
    /// <summary>MilCore 导出面（NativeAOT 共享库 wpfgfx_cor3.so 的全部导出符号）。</summary>
    public static unsafe class Exports
    {{
'''

    with open(OUT_CS, "w", encoding="utf-8") as f:
        f.write(header + "\n".join(chunks) + "    }\n}\n")

    os.makedirs(os.path.dirname(OUT_SYMS), exist_ok=True)
    with open(OUT_SYMS, "w", encoding="utf-8") as f:
        f.write("\n".join(symbols) + "\n")

    with open(OUT_TABLE, "w", encoding="utf-8") as f:
        f.write("# T1 / MilBridge · 每个导出的落地方式（自动生成）\n\n")
        f.write(f"合计 **{len(table)}** 个导出名。\n\n")
        f.write("| 导出名 | MilNative 实现深度 | 落地方式 | 内层实现文件 |\n|---|---|---|---|\n")
        for n, d, how, srcf in table:
            f.write(f"| `{n}` | {d} | {how} | `Interop/{srcf}` |\n")

    print(f"生成 {OUT_CS}：{len(chunks)} 个包装")
    print(f"生成 {OUT_SYMS}：{len(symbols)} 个符号")
    print(f"生成 {OUT_TABLE}：{len(table)} 行")
    from collections import Counter
    print("实现深度分布:", dict(Counter(d for _, d, _, _ in table)))
    print("需要类型适配:", sum(1 for _, _, h, _ in table if "适配" in h))


if __name__ == "__main__":
    build()
