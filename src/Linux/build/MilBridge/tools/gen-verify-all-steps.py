#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""`gen-verify-all-steps.py` —— `Guide.Linux/verify-all.sh` **步表**的生成器（`TASK-口径与生成式步表` ②）。

【要消掉的"手改"】`verify-all.sh` 里的 `run_step "…"` 行原先**手写**；本波起它们由**唯一来源**生成
   ⇒ 「从脚本字面量读表」的门禁自指牙（`verify-all-step-check.sh` 的 `^run_step "` 锚）**不再被绕开**
     （该牙的口径就是"看脚本字面量"，所以**不是**改成"脚本读表执行" —— 那会把牙弄瞎、名字数到 0）。

【唯一来源】`src/Linux/build/MilBridge/verify-all-steps.tsv`
   列（TAB 分隔）：`seq  name  cmd  needs_x  bare_tooth`（首行表头 ＋ `#` 注释行）。
   · `cmd` = 该步 `run_step "name"` 之后的**逐字**文本（**含对齐空格**）⇒ `run_step "name"` ＋ `cmd` **逐字重建**原行。
   · `needs_x`／`bare_tooth` 是**人读元数据**（判据见 tsv 头注释）；本器**只读入、不判**（不引入第二来源）。

【生成块】`Guide.Linux/verify-all.sh` 里被哨兵夹住的一段：
   `# >>> GENERATED-BY: gen-verify-all-steps.py >>>` … `# <<< END GENERATED <<<`
   · 块内**只有 `run_step "…"` 行**是生成物；块内其余行（注释／`echo`／赋值／`if`）**原样保留**
     —— 那 67 条 `run_step` 行**夹在**这些代码之间（中间有 `ARM_LOGS=`／`GEOM_CORPUS=`／`if [ -x … ]` 等
     **先于**对应步执行的语句），把它们整体搬走会**改控制流/门禁外形**。⇒ 哨兵界定"哪些 `run_step` 行受管"。

【口径】
   · `--check`：**只读、不写盘**。对拍「块内 `^run_step "` 行序列 ⇔ tsv 生成的行序列」，并顺带核
     `# VERIFYALL-STEPS-DECL` 的 `N` 与 `# VERIFYALL-STEP-NAMES` 的名字序列与 tsv 自洽；分叉 ⇒ rc=1 并**逐条点名**。
   · `--write`：**就地**按序替换块内的 `^run_step "` 行（幂等；块内非 `run_step` 行一字不动）。
   · 三态：`VSTEPS=PASS`（rc 0）／`VSTEPS=FAIL`（rc 1，逐条点名）／`VSTEPS=NOINFO`（rc 3，算不出来 ⇒ **不许当绿**）。
"""
import argparse, io, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
# src/Linux/build/MilBridge/tools → 仓根（上溯 5 层；与 `wave-freeze-consistency-check.py` 的 SELF_ROOT 同款）
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(HERE)))))
TSV_DEFAULT = os.path.join(ROOT, 'src', 'Linux', 'build', 'MilBridge', 'verify-all-steps.tsv')
VA_DEFAULT = os.path.join(ROOT, 'Guide.Linux', 'verify-all.sh')

BEGIN = '# >>> GENERATED-BY: gen-verify-all-steps.py >>>'
END = '# <<< END GENERATED <<<'

RUNSTEP_RE = re.compile(r'^run_step "([^"]*)"(.*)$', re.M)
DECL_RE = re.compile(r'^#[ \t]*VERIFYALL-STEPS-DECL:[ \t]*([0-9]+)', re.M)
NAMES_RE = re.compile(r'^#[ \t]*VERIFYALL-STEP-NAMES:[ \t]*(.*)$', re.M)


def read_tsv(path):
    """读 tsv ⇒ [(seq, name, cmd, needs_x, bare_tooth)]。畸形（列数≠5）⇒ 响亮退出（NOINFO）。"""
    steps = []
    text = io.open(path, encoding='utf-8').read()
    for ln, line in enumerate(text.split('\n'), 1):
        s = line.strip()
        if not s or s.startswith('#'):
            continue
        cols = line.split('\t')
        if cols[0] == 'seq':            # 表头
            continue
        if len(cols) != 5:
            print('VSTEPS=NOINFO reason=tsv-bad-ncol line=%d ncol=%d path=%s' % (ln, len(cols), path))
            return None
        try:
            seq = int(cols[0])
        except ValueError:
            print('VSTEPS=NOINFO reason=tsv-bad-seq line=%d val=%r' % (ln, cols[0]))
            return None
        steps.append((seq, cols[1], cols[2], cols[3], cols[4]))
    if not steps:
        print('VSTEPS=NOINFO reason=tsv-empty path=%s' % path)
        return None
    return steps


def gen_lines(steps):
    """tsv ⇒ 逐字的 `run_step "name"<cmd>` 行（`cmd` 已含对齐空格 ⇒ 与现脚本逐字同形）。"""
    return ['run_step "%s"%s' % (name, cmd) for _, name, cmd, _, _ in steps]


def block_bounds(text):
    i = text.find(BEGIN)
    if i < 0:
        return None
    # ⚠️ 从 BEGIN **之后**找 END：BEGIN 附近的注释里可能**提到**结束哨兵字样 ⇒ 不能从头找（本器首版踩过）
    j = text.find(END, i + len(BEGIN))
    if j < 0:
        return None
    return i, j


def do_check(va, tsv):
    steps = read_tsv(tsv)
    if steps is None:
        return 3
    want = gen_lines(steps)
    text = io.open(va, encoding='utf-8').read()
    b = block_bounds(text)
    if b is None:
        print('VSTEPS=NOINFO reason=sentinel-absent va=%s（生成块哨兵缺失 ⇒ 无从对拍）' % va)
        return 3
    i, j = b
    got = RUNSTEP_RE.findall(text[i:j])
    got_lines = ['run_step "%s"%s' % (n, r) for n, r in got]

    fails = []
    if len(got_lines) != len(want):
        fails.append('count-mismatch(块内 %d ≠ tsv %d)' % (len(got_lines), len(want)))
    for k in range(min(len(want), len(got_lines))):
        if want[k] != got_lines[k]:
            fails.append('step-changed(seq=%d name=%s in-repo=%r tsv=%r)'
                         % (k + 1, steps[k][1], got_lines[k], want[k]))
    for k in range(len(got_lines), len(want)):
        fails.append('tsv-extra(seq=%d name=%s：该步在 tsv 里、未进块)' % (k + 1, steps[k][1]))
    for k in range(len(want), len(got_lines)):
        fails.append('block-extra(块内多出第 %d 条 name?=%r)' % (k + 1, got[k][0]))

    d = DECL_RE.search(text)
    if not d:
        fails.append('decl-absent')
    elif int(d.group(1)) != len(steps):
        fails.append('decl-count(现场 DECL N=%s ≠ tsv %d)' % (d.group(1), len(steps)))

    m = NAMES_RE.search(text)
    if not m:
        fails.append('names-absent')
    else:
        onames = [t.strip() for t in m.group(1).split('|') if t.strip()]
        tnames = [n for _, n, _, _, _ in steps]
        if onames != tnames:
            diff = ''
            for k in range(max(len(onames), len(tnames))):
                o = onames[k] if k < len(onames) else '<缺>'
                t = tnames[k] if k < len(tnames) else '<缺>'
                if o != t:
                    diff = '第 %d 位 现场=%r tsv=%r' % (k + 1, o, t); break
            fails.append('names-differ(现场 %d 名 ≠ tsv %d 名；%s)' % (len(onames), len(tnames), diff))

    if fails:
        print('VSTEPS=FAIL n_tsv=%d n_block=%d tsv=%s' % (len(want), len(got_lines), tsv))
        for f in fails:
            print('VSTEPS_HIT %s' % f)
        return 1
    print('VSTEPS=PASS n=%d decl=%d names=%d tsv=%s' % (len(want), len(steps), len(steps), tsv))
    return 0


def do_write(va, tsv):
    steps = read_tsv(tsv)
    if steps is None:
        return 3
    want = gen_lines(steps)
    text = io.open(va, encoding='utf-8').read()
    b = block_bounds(text)
    if b is None:
        print('VSTEPS=NOINFO reason=sentinel-absent va=%s（先手工把哨兵夹住 run_step 区间）' % va, file=sys.stderr)
        return 3
    i, j = b
    head, block, tail = text[:i], text[i:j], text[j:]
    out = []; k = 0; last_rs = None; over = False
    for l in block.split('\n'):
        if l.startswith('run_step "'):
            if k < len(want):
                out.append(want[k]); k += 1; last_rs = len(out) - 1
            else:
                over = True; out.append(l)
        else:
            out.append(l)
    if over:
        print('VSTEPS=FAIL reason=block-has-more-run_step-than-tsv', file=sys.stderr)
        return 1
    added = 0
    if k < len(want):
        # tsv 多出的步（新增步骤）⇒ 追加到**块内最后一条 run_step 行之后**（"新步加在末尾"的语义）
        if last_rs is None:
            print('VSTEPS=FAIL reason=block-has-no-run_step-but-tsv-nonempty', file=sys.stderr)
            return 1
        out[last_rs + 1:last_rs + 1] = want[k:]
        added = len(want) - k
    new = head + '\n'.join(out) + tail
    if new == text:
        print('VSTEPS=WRITE unchanged n=%d' % k)
        return 0
    tmp = va + '.gen.tmp'
    io.open(tmp, 'w', encoding='utf-8').write(new)
    os.replace(tmp, va)
    print('VSTEPS=WRITE updated n=%d added=%d' % (k + added, added))
    return 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--check', action='store_true')
    ap.add_argument('--write', action='store_true')
    ap.add_argument('--tsv', default=TSV_DEFAULT)
    ap.add_argument('--va', default=VA_DEFAULT)
    a = ap.parse_args()
    if a.check and a.write:
        print('VSTEPS=NOINFO reason=both-check-and-write'); return 2
    if a.check:
        return do_check(a.va, a.tsv)
    if a.write:
        return do_write(a.va, a.tsv)
    ap.print_help(); return 2


if __name__ == '__main__':
    sys.exit(main())
