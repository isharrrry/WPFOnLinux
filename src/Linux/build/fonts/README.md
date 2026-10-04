# `build/fonts/` —— 测试字体（第三方资源，随仓发布）

| 文件 | sha256 |
|---|---|
| `NotoSans-Regular.ttf` | `f3961a9cde016d41a4879aecda1474d3a36d6bf54fa0e4643de029cc2248b0e8` |
| `NotoSans-Bold.ttf` | `87cb2d84472a7d66da659ee47b6cdb9552326e8c128245231f191b6ac72529d9` |
| `NotoSans-Italic.ttf` | `678288f868807d4d64a6f3b51466871d117d915780381ce9d0ed4b3bcbd06d37` |
| `NotoSans-BoldItalic.ttf` | `3d367743f371f28671d2764e911a53d7c20ec9b6aa8791d059e7090389fc52a5` |

- **来源**：Noto Sans（unhinted, ttf），`github.com/notofonts/notofonts.github.io`
  （`fonts/NotoSans/unhinted/ttf/`）—— 由 `build/setup-env.sh` 拉取并校验。
- **许可**：**SIL Open Font License 1.1**，全文见同目录 `LICENSE-OFL.txt`（OFL 要求随附）。
- **为什么随仓**：golden/对拍测试**禁止依赖系统字体**（系统升级换字体 ⇒ 真值静默失效）。
  两侧（Windows 记录侧与 Linux 侧）用的是**同一份文件**、sha256 逐字节一致，
  见 `tests/parity/windows/shaping/PROVENANCE.md`。
- `SHA256SUMS` 是机器校验清单：`cd build/fonts && sha256sum -c --quiet SHA256SUMS`。
- ⚠️ 仓库**不含** CJK 字体（`NotoSansCJK-Regular.ttc` 是系统包 `fonts-noto-cjk`，
  19.5 MB，只在需要 CJK 真值时按 §`PROVENANCE.md` 追加 2 的方式在场使用）。
