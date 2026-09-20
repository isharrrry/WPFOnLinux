# history —— 历史归档（**只放零引用的孤立文档**）

## 为什么这里只有 3 件

本仓的 md 大多是**证据链**：老波预登记、车道报告、冻结记录之间**逐条互相引用**
（例：`repin-generation.py --check` 会读 `build/MilBridge/W47A-report.md` 这类"证据日志"）。
⇒ **大搬家会让引用失效、甚至打穿冻结记录的判据**，所以本仓的政策是：

1. **规范/现状**（`README.md`、`PORT-SPEC.md`、`ROUTES.md`、`INDEX.md`、`CURRENT-STATE.md`、`handoff.md`、`KNOWN-DEFECTS.md`、`ACCEPTANCE-BASELINE.md`）**留在原位**；
2. **波与车道的证据件留在原位**（它们是"改动为什么被允许"的凭据，`INDEX.md` §3 说明它们是什么）；
3. **只有"零引用且已被取代"的文档**才移到这里。

## 本目录内容（移动时现场实测：在 `docs/**` 与 `build/**` 里对文件名的引用数 = 0）

| 文件 | 原位置 | 为什么可以移动 |
|---|---|---|
| `U2-resource-pipeline-audit.md` | `docs/` | 早期（M7 之前）资源管线审计；结论已被 `docs/ARCHITECTURE.md` 与后续波取代，无任何引用 |
| `WAVE32-PREREGISTRATION.md` | `docs/` | `#32` 波预登记；该波已收官并冻结，其结论已进 `CURRENT-STATE.md` 的历史段，无引用 |
| `WAVE45-PREREGISTRATION.md` | `docs/` | `#45` 波预登记；同上（`#45` 的工作已并入 `#46`） |

> 复算"零引用"（在本仓根跑）：
> ```bash
> for b in U2-resource-pipeline-audit.md WAVE32-PREREGISTRATION.md WAVE45-PREREGISTRATION.md; do
>   printf '%s -> %s\n' "$b" "$(grep -rl --include=*.sh --include=*.py --include=*.md -- "$b" . | grep -v '^./upstream' | wc -l)"
> done
> ```
