# 构建（building）

[English](building.md) | **中文** | [Español](building.es.md)

> 本文属于 **docs.Linux** —— 回 [移植侧文档总线](../README.zh-CN.md)（[English](../README.md) · [Español](../README.es.md)）。
> 本文只讲"怎么编出来"。跑起来见 [running-samples.zh-CN.md](running-samples.zh-CN.md)；逐工程落点见 [`../upstream/layout.zh-CN.md`](../upstream/layout.zh-CN.md)。

**一条命令**（唯一入口）：

```bash
WAVE_OWNER=$(whoami) bash build/integration-wave.sh
```

`WAVE_OWNER` 是**结构约束**而不是礼貌：没有它脚本**直接退出**；每趟都往 `build/wave-audit.log` 追加一条可追溯记录（时间/pid/ppid/tty/命令行/owner）。

---

## 1. 依赖与环境

```bash
sudo apt-get install -y gcc libc6-dev libx11-dev zlib1g-dev clang          # 原生 shim 与 AOT
sudo apt-get install -y xvfb x11-apps x11-utils imagemagick fontconfig libfontconfig1  # 验收与样本
dotnet --version                                                           # 仓内 global.json 锁 10.0.111
bash build/setup-env.sh && bash build/verify-env.sh                        # 一键装环境 + 逐项自检
```

## 2. 构建模型：**生成式**（这是本仓最容易踩的坑）

```
upstream/wpf/**（只读上游源，构建的唯一输入）
      │  build/port-lib.py  ：剔除 Windows-only 源 + 纳入生成的 *.Linux.cs；**整体重写** csproj
      ▼
build/<工程>.Linux/<工程>.Linux.csproj  ──dotnet build──▶  六个托管程序集
      │  应用器重放（src/WpfGfx.Linux.Native/tools/patch-*.py：补丁式接线，幂等 + --check + 锚点数断言）
      ▼
原生三件：libwpfwin32.so ／ libwpfwic.so ／ wpfgfx_cor3.so
```

- ⚠️ **手工改 `build/*.Linux/*.csproj` 会在下一次 `port-lib.py` 时被抹掉，而且不报错** ⇒ 接线必须落在**应用器**里。
- ⚠️ **预应用器改的是 port-lib 的输入**（例：`wire-uiautomation-resolver` 写 `build/shims/*.shims.txt`，而"清单 → csproj"是 port-lib 干的）⇒ 顺序必须是「预应用器 → 定向 port-lib → 其余应用器 → 构建」。
- **手写工程**（不参与 port-lib 重生成）：`DirectWriteForwarder.Linux`、`System.Printing.Linux`、`System.Windows.Extensions.Linux`、`CycleStub.*`、`build/DirectWrite.Linux/Provider/`、`src/WpfGfx.Linux/`。

## 3. `integration-wave.sh` 的九段（现读步名）

| 段 | 做什么 |
|---|---|
| `1/4` | 用当前 `port-lib.py` **重新生成**八个工程的 csproj（统一签名 + 资源管线 + 身份文件） |
| `2/4` | 重放各工程应用器（幂等；漏放会被静默丢弃 ⇒ 这里全部重放） |
| `2.5/5` | **应用器审计**：注册了但没生效 ⇒ 红 |
| `3/4` | 按依赖序重建（每工程一次 `-m:1`；序见脚本内 `ORDER`） |
| `3.5/5` | app-local 副本刷新（权威件 → 落后的加载源副本） |
| `3.6/5` | 生成物身份指纹（PC/WindowsBase/PF 的源身份） |
| `3.7/5` | 判据件自检（app-local 校验器 `--selftest`） |
| `4/4` | 身份自检（每个自产程序集：按项目名精确取件 + 是否带公钥） |
| `5/5` | 输入稳定性（波期间手写输入有没有被改动） |

## 4. 配置：只有一处声明

- 权威件配置 = **`Release`**，唯一声明 = `build/SelfBuiltConfig.props`，唯一 shell 读取器 = `build/selfbuilt-config.sh`。
- 自检：`bash build/selfbuilt-config.sh --check`。改消费点而漏改声明 = 门禁会咬。

## 5. 原生三件（各自可单独重建）

```bash
bash src/WpfGfx.Linux.Native/build-shim.sh                    # libwpfwin32.so（+ exports.txt）
bash build/DirectWrite.Linux/wic-shim/build-wic-shim.sh       # libwpfwic.so
bash build/MilBridge/run.sh build                             # wpfgfx_cor3.so（AOT milcore）
```

⚠️ 三者**不进 git**（`src/WpfGfx.Linux.Native/bin/` 被 `.gitignore` 忽略）⇒ 干净克隆取不回，**必须重建**。

## 6. 验收（门禁本体）

```bash
bash verify-all.sh          # 64 步；自己用 :99
```

- **步数口径**：一律引**现行** `verify-all.sh` 的 `VERIFYALL-STEPS-DECL` —— 现读 **`64 gen=#82`**（**别写死旧数**：历史上它从 55 → 58 → 61 → 62 → 64 变过）。
- 门禁包含构建、测试、**五臂对拍**、应用门禁、冻结基线核对，以及一堆"看仪器的仪器"（引号陷阱、`pipefail` SIGPIPE 普查、覆盖面自检……）。
- 相关牙（可单独跑）：

```bash
bash build/MilBridge/tools/verify-all-step-check.sh     # 步名/步数/口径句三方对拍
bash build/MilBridge/tools/baseline-sha-check.sh        # 冻结基线机器行
bash build/MilBridge/tools/defect-registry-check.sh     # 缺陷登记（DEFREG）
bash build/MilBridge/tools/root-entries-allowlist-check.sh  # 根级条目 ⊆ 允许清单
bash build/MilBridge/tools/pts-gap-count-check.sh       # PTS 缺口现值位
```

## 7. 失败时先看什么

- `build/wave-audit.log` 末行：这一趟是谁、什么时候发起的（`owner=` / `ppid_cmd=`）。
- `build/<工程>.Linux/PORT-CHANGES.md`：该工程的移植改了哪些处（逐条）。
- `build/MilBridge/<车道>-report.md`：历史同类问题的读数与处置。
- 三态纪律：**取不到 ≠ 通过**（`NOINFO` 必须人看）。

---

[English](building.md) | **中文** | [Español](building.es.md) · [移植侧文档总线](../README.zh-CN.md) · [入门](getting-started.zh-CN.md) · [跑样本](running-samples.zh-CN.md)
