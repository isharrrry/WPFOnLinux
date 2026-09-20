#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""T1c · **调用点实参作用域审计**（机械，只读）—— 防 CS0103 那一族。

用法
----
    python3 build/MilBridge/tools/t1c-trace-args-scope.py <生成物.cs> [<生成物.cs> ...]
    python3 build/MilBridge/tools/t1c-trace-args-scope.py --auto /tmp/t1c/b3 /tmp/t1c/b5 /tmp/t1c/b7 ...

为什么有这个东西
----------------
第 5 批的 `W3d` 探针把 `referenceFromExpression` 传给了 helper，而那个变量是在**修改值分支的
内部作用域**里声明的（上游 `DependencyObject.cs:348-350`）⇒ 探针落在块外 ⇒ **CS0103**，
由集成波的构建步骤抓住。`--prove`（逆代后与上游逐字节相同）与"预测 sha"**都证明不了能编过**：
前者只证"插入是纯插入"，后者只证"生成器确定"。

所以这里补一把**机械尺子**：对每个 `WpfLinux*Trace.X(args)` 调用点，检查每个**裸标识符实参**
是否在**调用点可见的作用域**里声明过 ——
  · 方法形参 ⇒ 整个方法体可见；
  · 局部变量 ⇒ 声明处的大括号深度必须 **≤ 调用处的深度**（声明在更深的块里 ⇒ **不可见** ⇒ 报 SUSPECT）。
局限（必须说清）：它是**启发式**，不是编译器 —— 不查类型、不查 `using`、不查 `out/ref`、不查同名遮蔽。
它**能**抓住"变量在更深的块里声明"这一族（就是这次的坑）。
"""

import argparse
import glob
import os
import re
import sys


# ══════════════════════════════════════════════════════════════════════════════
#  类型-lite：形参类型 vs 实参表达式（**一眼可判**的那部分）
#    · 判不了的一律**列出来**（不许静默放过）
#    · 已知成员类型：`EntryIndex.Index` = uint、`DependencyProperty.GlobalIndex` = int …
#    · 隐式转换表很小、很保守（uint→int / long→int 这类**必须**报）
# ══════════════════════════════════════════════════════════════════════════════
KNOWN_MEMBER_TYPES = {
    "Index": "uint",          # EntryIndex.Index
    "GlobalIndex": "int",     # DependencyProperty.GlobalIndex
    "Length": "int",          # string/array .Length
    "Count": "int",
    "Handled": "bool",
    "Text": "string",
    "Offset": "int",
}

PRIMITIVES = ("bool", "byte", "sbyte", "short", "ushort", "int", "uint", "long", "ulong",
              "float", "double", "decimal", "char", "string", "object")

# 允许的隐式转换（保守；**不含** uint→int、long→int）
IMPLICIT_OK = {
    ("short", "int"), ("byte", "int"), ("sbyte", "int"), ("ushort", "int"), ("char", "int"),
    ("int", "long"), ("uint", "long"), ("short", "long"), ("byte", "long"),
    ("int", "double"), ("uint", "double"), ("long", "double"), ("float", "double"),
    ("uint", "ulong"),
}


def normalize_type(t):
    t = (t or "").strip()
    if t.endswith("[]"):
        return "array"
    base = t.split("<")[0].strip()
    if base in PRIMITIVES:
        return base
    if base in ("", "var"):
        return None
    return "ref:" + base          # 引用/结构体类型 ⇒ 只做"两边同名才算对"



# ══════════════════════════════════════════════════════════════════════════════
#  实参形态（ARGSHAPE）：调用点**不许**做下标 / 属性链 / 分配 —— 因为"探针关着"时实参**照样求值**。
#  （第 6 批运行期崩因：`W6BeforeUpdate(..., _effectiveValues[entryIndex.Index])` 在静态初始化期 NRE。）
#  允许：裸标识符、`this`、字面量、强制转换、**结构体局部字段**（`msgdata.msg.message`）。
# ══════════════════════════════════════════════════════════════════════════════
ARGSHAPE_ALLOW = (
    r"^msgdata\.msg\.(message|hwnd|wParam|lParam)$",   # 局部结构体字段（不会抛）
)


def argshape(a):
    """返回问题说明；没问题返回 None。"""
    e = a.strip()
    if e == "":
        return "空实参"
    if e.startswith('"') or e.startswith('@"') or e.startswith("$"):
        return None                                        # 字符串字面量（标签）⇒ 允许（里面的括号不是调用）
    for pat in ARGSHAPE_ALLOW:
        if re.match(pat, e):
            return None
    if "[" in e:
        return "**实参里有下标 `[]`** ⇒ 挪进 helper（探针关着也会求值）"
    if re.search(r"\bnew\s", e):
        return "**实参里有 `new`**（分配）⇒ 挪进 helper"
    if re.match(r"^\([A-Za-z_][\w\.<>]*\)[A-Za-z_]\w*$", e) or re.match(r"^\((object|int|long|uint)\)", e):
        return None                                        # 纯强制转换 ⇒ 允许
    if "(" in e:
        return "**实参里有方法调用**⇒ 挪进 helper"
    if e.count(".") >= 2 and not e.startswith("this."):
        return "**实参里是属性链（≥2 个 `.`）**⇒ 挪进 helper"
    return None

def arg_type(expr, ptypes, ltypes):
    """返回实参的**已知**类型；判不了返回 None。"""
    e = (expr or "").strip()
    if e == "":
        return None
    if e in ("null",):
        return "object"
    if e in ("true", "false"):
        return "bool"
    if e.startswith('"') or e.startswith('@"') or e.startswith("$"):
        return "string"
    if re.match(r"^\d+[uU]$", e):
        return "uint"
    if re.match(r"^-?\d+[lL]$", e):
        return "long"
    if re.match(r"^-?\d+$", e):
        return "int"
    if re.match(r"^\d+\.\d", e):
        return "double"
    m = re.match(r"^\((\w+)\)", e)          # 强制转换 ⇒ 以转换后的类型为准
    if m:
        return normalize_type(m.group(1))
    m = re.match(r"^[A-Za-z_]\w*\.([A-Za-z_]\w*)$", e)   # x.Member
    if m:
        return normalize_type(KNOWN_MEMBER_TYPES.get(m.group(1)))
    if re.match(r"^[A-Za-z_]\w*$", e):          # 裸标识符 ⇒ 查形参/局部
        if e in ptypes:
            return normalize_type(ptypes[e])
        if e in ltypes:
            return normalize_type(ltypes[e])
        return None
    return None


def params_of(sig_params):
    """把 `object a, int b, EffectiveValueEntry[] c` 解析成 {名字: 类型}。"""
    out = {}
    for p in sig_params:
        p = re.sub(r"\b(ref|out|params|this)\b", " ", p).strip()
        if not p:
            continue
        m = re.match(r"^(.*?)\s+([A-Za-z_]\w*)$", p)
        if m:
            out[m.group(2)] = m.group(1).strip()
    return out


def collect_helpers(lines):
    """从生成物里抽 helper 签名：返回 {名字: {形参名: 类型}}（支持多行形参）。"""
    helpers = {}
    i = 0
    while i < len(lines):
        code = strip_noise(lines[i])
        t = code.strip()
        m = re.match(r"^(?:internal|private|public|protected)\s+static\s+[\w\.<>\[\]]+\s+([A-Za-z_]\w*)\s*\(", t)
        if m:
            buf = t
            bal = t.count("(") - t.count(")")
            j = i
            while bal > 0 and j + 1 < len(lines):
                j += 1
                nxt = strip_noise(lines[j])
                buf += " " + nxt.strip()
                bal += nxt.count("(") - nxt.count(")")
            mm = re.match(r"^.*?\(", buf)
            if mm:
                inner = buf[mm.end():]
                depth = 1
                k = 0
                while k < len(inner) and depth > 0:
                    if inner[k] == "(":
                        depth += 1
                    elif inner[k] == ")":
                        depth -= 1
                    k += 1
                helpers[m.group(1)] = params_of(split_args(inner[:k - 1]))
            i = j
        i += 1
    return helpers

CALL_RE = re.compile(r"WpfLinux[A-Za-z]*Trace\.([A-Za-z_]\w*)\((.*)\)\s*;")
# 声明识别：**线性正则**（不能有嵌套量词 —— 那个会在长行上指数回溯，实测把审计脚本挂死）
DECL_RES = (
    # 允许**修饰符前缀**（`private bool _f;` 这种：第一版只认"一个类型 token"⇒ 字段全被判成"找不到声明"）
    ("local", re.compile(r"^\s*(?:(?:public|private|protected|internal|static|readonly|const|volatile|sealed|override|new|unsafe|extern|partial)\s+)*"
                         r"([A-Za-z_][\w\.<>\[\]\?]*)\s+([A-Za-z_]\w*)\s*([=;\)])")),
    ("for",   re.compile(r"^\s*for\s*\(\s*([A-Za-z_][\w\.<>\[\]\?]*)\s+([A-Za-z_]\w*)\s*=")),
    ("catch", re.compile(r"catch\s*\(\s*([A-Za-z_][\w\.<>\[\]\?]*)\s+([A-Za-z_]\w*)\s*\)")),
    # 属性/无初值字段：`public KeyboardDevice PrimaryKeyboardDevice`（行尾就是名字，没有 `= ; )`）
    ("member", re.compile(r"^\s*(?:(?:public|private|protected|internal|static|readonly|const|volatile|sealed|override|virtual|abstract|new|unsafe|extern|partial)\s+)*"
                          r"([A-Za-z_][\w\.<>\[\]\?]*)\s+([A-Za-z_]\w*)\s*$")),
)


def find_decl(code):
    """返回 (类型, 变量名)（线性、无回溯），没有则 None。"""
    m = DECL_RES[0][1].match(code)
    if m:
        return (m.group(1), m.group(2))
    # for/catch/member：两个捕获组 = (类型, 名字) —— 第一版把 `kind`（"for"/"catch"）当类型，
    #   结果 `for (int i = …)` 里的 `i` 被当成 `ref:for` ⇒ 与形参 int 比对时报假阳性（TextEditorTyping Q2Item）
    for _kind, rx in DECL_RES[1:]:
        m = rx.search(code)
        if m:
            return (m.group(1), m.group(2))
    if code.strip().startswith(("return", "case", "else", "using", "throw", "break", "continue")):
        return None
    return None
MODIFIERS = ("public", "private", "internal", "protected", "static", "override",
             "virtual", "sealed", "abstract", "unsafe", "partial", "new", "extern")


def looks_like_signature(code):
    """线性判定"这行是不是方法/构造签名"（**不用回溯正则**）。返回 (名字, 形参串) 或 None。"""
    t = code.strip()
    if not t.endswith(")") or "(" not in t or t.endswith(";"):
        return None
    head, _, rest = t.partition("(")
    if head.startswith(MODIFIERS) is False and not any(head.startswith(m + " ") for m in MODIFIERS):
        return None
    name = head.split()[-1] if head.split() else ""
    if name.startswith(".") or not name:
        return None
    # rest 里要有配对的右括号（去掉最后一个 ')'）
    return (name, rest[:-1])


def strip_noise(line):
    """去掉 `//` 注释与字符串字面量内容，避免数错大括号。"""
    out = []
    i, n = 0, len(line)
    in_str = False
    in_chr = False
    while i < n:
        ch = line[i]
        if in_str:
            if ch == "\\":
                i += 2
                continue
            if ch == '"':
                in_str = False
            i += 1
            continue
        if in_chr:
            if ch == "\\":
                i += 2
                continue
            if ch == "'":
                in_chr = False
            i += 1
            continue
        if ch == '"':
            in_str = True
            i += 1
            continue
        if ch == "'":
            in_chr = True
            i += 1
            continue
        if ch == "/" and i + 1 < n and line[i + 1] == "/":
            break
        out.append(ch)
        i += 1
    return "".join(out)


def parse_params(raw):
    names = []
    depth = 0
    cur = ""
    for ch in raw:
        if ch in "(<[":
            depth += 1
        elif ch in ")>]":
            depth -= 1
        if ch == "," and depth == 0:
            names.append(cur)
            cur = ""
            continue
        cur += ch
    if cur.strip():
        names.append(cur)
    out = []
    for p in names:
        p = p.strip()
        if not p:
            continue
        if p in ("params",):
            continue
        # 去掉修饰符与类型，取最后一个标识符
        m = re.search(r"([A-Za-z_]\w*)\s*(?:=[^,]*)?$", p)
        if m:
            out.append(m.group(1))
    return out


def split_args(raw):
    args, depth, cur = [], 0, ""
    for ch in raw:
        if ch in "([{<":
            depth += 1
        elif ch in ")]}>":
            depth -= 1
        if ch == "," and depth == 0:
            args.append(cur.strip())
            cur = ""
            continue
        cur += ch
    if cur.strip():
        args.append(cur.strip())
    return args


# 派生/基类带来的成员（**不在本文件声明**）：显式登记，避免假阳性。
#   `TextEditor` = `InputItem` 基类的属性（TextEditorTyping.cs 里 `TextInputItem.Do()` 用的是它）。
INHERITED_ALLOW = {
    "TextEditor",
}

CLASS_RE = re.compile(r"^\s*(?:(?:public|private|internal|protected|static|sealed|abstract|partial|unsafe|new|readonly|ref)\s+)*(?:class|struct)\s+([A-Za-z_]\w*)")


def audit(path, helpers=None):
    with open(path, encoding="utf-8", errors="replace") as f:
        lines = f.read().split("\n")

    depth = 0
    class_body_depths = set()  # 类体所处的深度（其成员在**整个类内**都可见 ⇒ 深度无关）
    field_names = set()        # 在这些深度上声明的成员
    pending_class = False
    cur_method = None          # (name, params, body_depth)
    decls = []                 # (name, depth, lineno)
    calls = []                 # (lineno, helper, args, depth)
    pending_sig = None
    sig_buf = None
    sig_bal = 0

    for idx, raw in enumerate(lines, 1):
        code = strip_noise(raw)
        stripped = code.strip()

        # 方法签名：支持**多行形参**（上游 `GetEffectiveValue`/`SetValueCommon` 都是多行的，
        #   第一版只认单行 ⇒ 把形参当"找不到声明"，出了 7 条假阳性）
        if pending_sig is not None:
            if stripped == "{":
                mdict = (params_of(split_args(pending_sig[1]))
                         if isinstance(pending_sig[1], str) else pending_sig[1])
                cur_method = (pending_sig[0], mdict, depth + 1)
                pending_sig = None
            elif stripped:
                pending_sig = None
                sig_buf = None
        if sig_buf is not None:
            sig_buf.append(code)
            sig_bal += code.count("(") - code.count(")")
            if sig_bal <= 0:
                sig = looks_like_signature(" ".join(sig_buf))
                if sig is not None:
                    pending_sig = (sig[0], sig[1])       # **原始形参串**（类型信息在这里）
                sig_buf = None
        if pending_sig is None and sig_buf is None and "(" in code and not stripped.endswith(";"):
            bal = code.count("(") - code.count(")")
            if bal <= 0:
                sig = looks_like_signature(code)
                if sig is not None:
                    pending_sig = (sig[0], sig[1])       # **原始形参串**（类型信息在这里）
            else:
                sig_buf = [code]
                sig_bal = bal

        # 调用点（快路径：只扫含 WpfLinux 的行）
        # ⚠️ 用**原始行**匹配：`strip_noise` 会把字符串字面量抹掉 ⇒ 首个实参（通常是标签串）会变成空串（假阳性）
        if "WpfLinux" in code:
            for cm in CALL_RE.finditer(raw):
                # ⚠️ 必须把**调用点当时**的 enclosing method 一起存下来：
                #    第一版在循环外用 cur_method ⇒ 拿到的是"最后一个方法"，于是形参全判成"找不到声明"（7 条假阳性）
                calls.append((idx, cm.group(1), split_args(cm.group(2)), depth, cur_method))

        # 类声明（其 `{` 在下一行 ⇒ 记下类体深度）
        if CLASS_RE.match(code) and stripped.endswith((")", "class", "struct")) is False and ("class" in code or "struct" in code):
            pending_class = True
        elif pending_class and stripped == "{":
            class_body_depths.add(depth + 1)
            pending_class = False

        # 声明
        if stripped and not stripped.startswith(("return", "if", "else", "while", "}", "//")):
            nm = find_decl(code)
            if nm:
                decls.append((nm[1], depth, idx, nm[0]))   # (名字, 深度, 行, 类型)
                if depth in class_body_depths:
                    field_names.add(nm[1])     # 字段/属性 ⇒ 类内任意深度可见

        depth += code.count("{") - code.count("}")
        if depth == 0:
            cur_method = None
            sig_buf = None

    problems = []
    type_problems = []
    shape_problems = []
    unknown = []
    helpers = helpers or {}
    for lineno, helper, args, cdepth, enclosing in calls:
        params = set(enclosing[1]) if enclosing else set()
        ptypes = dict(enclosing[1]) if enclosing and isinstance(enclosing[1], dict) else {}
        # 可见局部的类型表（同作用域规则：深度 ≤ 调用点）
        ltypes = {}
        for (nm, d, ln, ty) in decls:
            if ln < lineno and d <= cdepth:
                ltypes[nm] = ty
        for a in args:
            if not re.match(r"^[A-Za-z_]\w*$", a):
                continue                      # 非裸标识符（字段访问/字面量/表达式）⇒ 不查作用域
            if a in params or a in field_names or a in INHERITED_ALLOW:
                continue
            if a in ("this", "null", "true", "false"):
                continue
            vis = [d for (nm, d, ln, ty) in decls if nm == a and ln < lineno and d <= cdepth]
            if not vis:
                deeper = [(nm, d, ln, ty) for (nm, d, ln, ty) in decls if nm == a and ln < lineno]
                why = ("**声明在更深的块里（深度 %d > 调用点 %d）⇒ CS0103**"
                       % (deeper[-1][1], cdepth)) if deeper else "**找不到声明**"
                problems.append((lineno, helper, a, why))

        # ── 实参形态（ARGSHAPE）：下标 / 属性链 / 分配 一律不许留在调用点 ──
        for a in args:
            why = argshape(a)
            if why:
                shape_problems.append((lineno, helper, a, why))

        # ── 类型-lite：形参类型 vs 实参表达式 ──
        sig = helpers.get(helper)
        if not sig:
            unknown.append((lineno, helper, "-", "没有该 helper 的签名（无法做类型比对）"))
            continue
        ptype_list = list(sig.values())
        for i, a in enumerate(args):
            if i >= len(ptype_list):
                type_problems.append((lineno, helper, a, "实参个数多于形参（%d > %d）" % (len(args), len(ptype_list))))
                break
            dst = normalize_type(ptype_list[i])
            src = arg_type(a, ptypes, ltypes)
            if src is None or dst is None:
                unknown.append((lineno, helper, a, "判不了（实参类型=%s，形参类型=%s）" % (src or "?", ptype_list[i])))
                continue
            if src == dst or dst == "object":
                continue
            if dst == "array":
                continue                      # 数组实参不细判
            if src.startswith("ref:") or dst.startswith("ref:"):
                if src != dst:
                    type_problems.append((lineno, helper, a, "引用类型不同：实参 %s vs 形参 %s" % (src, dst)))
                continue
            if (src, dst) in IMPLICIT_OK:
                continue
            type_problems.append((lineno, helper, a,
                                  "**类型不匹配：实参 `%s`（%s）→ 形参 %s ⇒ 需要显式转换（CS1503 那一族）**"
                                  % (a, src, dst)))
    return len(calls), problems, type_problems, unknown, shape_problems


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="*", help="生成物 .cs")
    ap.add_argument("--auto", nargs="*", default=None, help="在这些目录下自动找 *.Linux.cs")
    args = ap.parse_args()

    targets = list(args.files)
    if args.auto is not None:
        for d in args.auto:
            targets += sorted(glob.glob(os.path.join(d, "**", "*.Linux.cs"), recursive=True))
    targets = [t for t in targets if os.path.exists(t)]
    if not targets:
        print("[失败] 没有可审计的文件")
        return 1

    # 第 1 遍：把所有文件里的 helper 签名收齐（tracer 类可能与调用点**不在同一个文件**）
    helpers = {}
    for t in sorted(set(targets)):
        with open(t, encoding="utf-8", errors="replace") as f:
            helpers.update(collect_helpers(f.read().split("\n")))
    print(f"[签名] 收到 {len(helpers)} 个 helper 的形参类型表：{', '.join(sorted(helpers)[:6])}"
          + (" …" if len(helpers) > 6 else ""))

    total_calls, total_problems, total_types, total_unknown, total_shape = 0, 0, 0, 0, 0
    for t in sorted(set(targets)):
        calls, problems, type_problems, unknown, shape_problems = audit(t, helpers)
        total_calls += calls
        total_problems += len(problems)
        total_types += len(type_problems)
        total_unknown += len(unknown)
        total_shape += len(shape_problems)
        flag = "OK " if (not problems and not type_problems and not shape_problems) else "!! "
        print(f"{flag}{os.path.basename(t):34s} 调用点 {calls:3d}  "
              f"作用域 {len(problems)}  类型 {len(type_problems)}  实参形态 {len(shape_problems)}  判不了 {len(unknown)}")
        for lineno, helper, a, why in problems:
            print(f"     :{lineno} {helper}(…) 实参 `{a}` {why}")
        for lineno, helper, a, why in type_problems:
            print(f"     :{lineno} {helper}(…) 实参 `{a}` {why}")
        for lineno, helper, a, why in shape_problems:
            print(f"     :{lineno} {helper}(…) 实参 `{a}` {why}")
        for lineno, helper, a, why in unknown:
            print(f"     ~ :{lineno} {helper}(…) 实参 `{a}` {why}（**列出，不静默放过**）")
    print(f"[汇总] 调用点 {total_calls} 个；作用域 {total_problems} 个；类型 {total_types} 个；"
          f"实参形态 {total_shape} 个；判不了 {total_unknown} 条（已列出）")
    return 1 if (total_problems or total_types or total_shape) else 0


if __name__ == "__main__":
    sys.exit(main())
