// Licensed to the .NET Foundation under one or more agreements.
//
// MIL 通道：命令流状态机 + 批处理缓冲 + 资源句柄表。
//
// 托管层写入模式（handoff §3.2）：
//     BeginCommand → (AppendCommandData)* → EndCommand → … → CommitChannel
// 另一条路径是 MilResource_SendCommand（整条命令一次给全）。
//
// 命令在 Commit 之前不执行；Commit 是原子的。

using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using WpfGfx.Linux.Contracts;
using WpfGfx.Linux.Interop;

namespace WpfGfx.Linux.Resources
{
    /// <summary>
    /// 分区（partition）。同一分区内的通道可以互相 DuplicateHandle；
    /// 上游 Channel 语义：以 null referenceChannel 创建的是分区的第一个通道。
    /// </summary>
    internal sealed class MilPartition
    {
        private static int _nextId;

        public readonly int Id = ++_nextId;

        public bool RegisterForNotifications;          // MilCmdPartitionRegisterForNotifications
        public bool VBlankSyncMode;                    // MilCmdPartitionSetVBlankSyncMode
        public bool ReturnCommonMinimum;               // MilCmdChannelRequestTier
        public ulong LastPresentFrameTime;             // MilCmdPartitionNotifyPresent
        public bool RenderEvenWhenNoDisplayDevices;    // MilCmdPartitionNotifyPolicyChangeForNonInteractiveMode
    }

    internal sealed class MilChannel : IMilChannel
    {
        private static int _nextId;

        public readonly int Id = ++_nextId;
        public readonly MilPartition Partition;

        /// <summary>命令解码器。缺省实现由 Commands/MilCommandDispatcher 提供。</summary>
        public IMilCommandDispatcher Dispatcher { get; set; }

        /// <summary>本通道的资源句柄表。</summary>
        public readonly MilResourceTable Resources = new MilResourceTable();

        public ChannelMarshalType MarshalType = ChannelMarshalType.ChannelMarshalTypeSameThread;

        public bool IsOutOfBandChannel;
        public bool IsSynchronous;

        /// <summary>所属连接（MilConnection_CreateChannel 的 pTransport）。</summary>
        public IntPtr Connection;

        /// <summary>本通道的句柄值，即托管层持有的 IntPtr。由 MilChannelRegistry 下发，进程内唯一不复用。</summary>
        public IntPtr Handle;

        // ---------------- 批处理状态 ----------------

        private byte[] _batch = new byte[8192];
        private int _batchLength;
        private readonly List<int> _commandLengths = new List<int>();

        private int _openStart = -1;          // <0 表示当前没有打开的 BeginCommand
        private int _openExtra;               // BeginCommand 声明的 cbExtra
        private int _openAppended;            // 实际 Append 的字节数

        // ---------------- 统计 / 诊断 ----------------

        /// <summary>已提交并成功解码的命令数。</summary>
        public long CommittedCommands;

        /// <summary>提交时返回 E_NOTIMPL 的命令数。</summary>
        public long NotImplCommands;

        /// <summary>E_NOTIMPL 命令登记表：命令字 → 出现次数。</summary>
        public readonly Dictionary<MilCmd, long> NotImplRegistry = new Dictionary<MilCmd, long>();

        /// <summary>被 Dispatch 返回失败码的命令数。</summary>
        public long FailedCommands;

        /// <summary>EndCommand 时 Append 字节数少于 cbExtra 的次数（诊断用）。</summary>
        public long ShortCommands;

        public MilChannel(MilPartition partition)
        {
            Partition = partition ?? new MilPartition();
        }

        // ==================================================================
        //  批处理状态机
        // ==================================================================

        public bool IsCommandOpen => _openStart >= 0;

        /// <summary>当前批次中已完整入队的命令条数。</summary>
        public int PendingCommandCount => _commandLengths.Count;

        /// <summary>当前批次缓冲字节数。</summary>
        public int BatchByteCount => _batchLength;

        // ── 波46 · D-G54 只读仪器：命令层台账（env `WPF_LINUX_CMDLOG=1`，只打印）──
        //   为什么要有：managed 侧**确实**发了两次 `MilCmdTargetSetRoot`（`HwndTarget` 侧插桩证明），
        //   而桥的 preflight 里只出现**一条** ⇒ 要问"第二条是没进缓冲，还是进了没被派发"。
        //
        //   【为什么还要 id 过滤（`WPF_LINUX_CMDLOG_ID=0x35`）】`SendCommand` 是**每条命令**的入口，
        //   启动期几千条 ⇒ 固定 400 行预算在弹窗打开（t=25 s）**之前**就烧光，
        //   而"仪器把自己的读数吃掉"正是本项目反复踩过的自伤。给了 ID 列表就只记这些 id，
        //   预算提到 5000；不给则行为与原来一致（全记、400 行）。
        private static int _cmdLogOn = -1;
        private static int _cmdLogN;
        private static string _cmdLogIds;
        private static int _cmdLogBudget = 400;
        private static void CmdLogInit()
        {
            if (_cmdLogOn >= 0) return;
            _cmdLogOn = Environment.GetEnvironmentVariable("WPF_LINUX_CMDLOG") == "1" ? 1 : 0;
            _cmdLogIds = Environment.GetEnvironmentVariable("WPF_LINUX_CMDLOG_ID");
            _cmdLogBudget = string.IsNullOrEmpty(_cmdLogIds) ? 400 : 5000;
        }
        internal static void CmdLog(string msg)
        {
            CmdLogInit();
            if (_cmdLogOn != 1 || _cmdLogN++ >= _cmdLogBudget) return;
            Console.Error.WriteLine("[CMD] " + msg);
            Console.Error.Flush();
        }

        /// <summary>该命令 id 是否在过滤清单里（清单为空 ⇒ 全要）。</summary>
        internal static bool CmdLogWanted(int id)
        {
            CmdLogInit();
            if (string.IsNullOrEmpty(_cmdLogIds)) return true;
            string hex = (id & 0xffffffff).ToString("x");
            foreach (string tok in _cmdLogIds.Split(new[] { ',', ' ', ';' }, StringSplitOptions.RemoveEmptyEntries))
            {
                string s = tok.StartsWith("0x", StringComparison.OrdinalIgnoreCase) ? tok.Substring(2) : tok;
                if (string.Equals(s, hex, StringComparison.OrdinalIgnoreCase)) return true;
            }
            return false;
        }

        private static void CmdLogId(int id, string msg) { if (CmdLogWanted(id)) CmdLog(msg); }

        /// <summary>
        /// 是否设了 `WPF_LINUX_CMDLOG_ID` 白名单。预检据此决定"只明细打印关心的命令"
        /// （见 `PreflightPendingCommands()` 的预算注释）—— 与 `[CMD]` 台账**共用同一个**开关，
        /// 不新增环境变量。
        /// </summary>
        internal static bool CmdLogWhitelistSet { get { CmdLogInit(); return !string.IsNullOrEmpty(_cmdLogIds); } }
        private int CmdIdAt(int off) { return off + 4 <= _batchLength ? BitConverter.ToInt32(_batch, off) : -1; }
        private uint CmdHandleAt(int off) { return off + 8 <= _batchLength ? BitConverter.ToUInt32(_batch, off + 4) : 0u; }

        public int BeginCommand(ReadOnlySpan<byte> data, uint cbExtra)
        {
            if (_openStart >= 0) { CmdLog($"ch={Id} BeginCommand **被拒**（上一个命令未关闭，E_UNEXPECTED）size={data.Length}"); return HResult.E_UNEXPECTED; }   // 嵌套 BeginCommand
            if (data.Length == 0) return HResult.E_INVALIDARG;

            _openStart = _batchLength;
            _openExtra = (int)cbExtra;
            _openAppended = 0;
            Append(data);
            return HResult.S_OK;
        }

        public int AppendCommandData(ReadOnlySpan<byte> data)
        {
            if (_openStart < 0) { CmdLog($"ch={Id} AppendCommandData **被拒**（没有打开的 BeginCommand，E_UNEXPECTED）size={data.Length}"); return HResult.E_UNEXPECTED; }    // 没有打开的 BeginCommand
            if (data.Length == 0) return HResult.E_INVALIDARG;
            if (_openAppended + data.Length > _openExtra) return HResult.E_INVALIDARG;  // 超出预留

            Append(data);
            _openAppended += data.Length;
            return HResult.S_OK;
        }

        public int EndCommand()
        {
            if (_openStart < 0) return HResult.E_UNEXPECTED;

            int length = _batchLength - _openStart;
            if (_openAppended < _openExtra) ShortCommands++;

            CmdLogId(CmdIdAt(_openStart), $"ch={Id} EndCommand id=0x{CmdIdAt(_openStart):x} handle=0x{CmdHandleAt(_openStart):x8} len={length} extra={_openExtra} appended={_openAppended}");
            _commandLengths.Add(length);
            _openStart = -1;
            _openExtra = 0;
            _openAppended = 0;
            return HResult.S_OK;
        }

        /// <summary>
        /// 整条命令一次写入。sendInSeparateBatch=true 时立即提交（不影响当前批次）。
        /// </summary>
        public int SendCommand(ReadOnlySpan<byte> data, bool sendInSeparateBatch)
        {
            // 波46 · D-G54：`SetRoot` 走的就是这条路（`DUCE.CompositionTarget.SetRoot` →
            //   `Channel.SendCommand(p,cSize)` 两参重载 ⇒ `MilResource_SendCommand`），
            //   **不经过 Begin/Append/End** ⇒ 没有这一行就无法区分"命令没到桥"与"没被派发"。
            int cmdId = data.Length >= 4 ? BitConverter.ToInt32(data) : -1;
            uint cmdHandle = data.Length >= 8 ? BitConverter.ToUInt32(data.Slice(4)) : 0u;
            CmdLogId(cmdId, $"ch={Id} SendCommand 入口 id=0x{cmdId:x} handle=0x{cmdHandle:x8} len={data.Length} 独立批={sendInSeparateBatch} openStart={_openStart} 批次内已有={_commandLengths.Count}");

            if (_openStart >= 0) { CmdLog($"ch={Id} SendCommand **被拒**（BeginCommand 未关闭，E_UNEXPECTED）id=0x{cmdId:x}"); return HResult.E_UNEXPECTED; }   // BeginCommand 未关闭
            if (data.Length == 0) return HResult.E_INVALIDARG;

            int start = _batchLength;
            Append(data);
            _commandLengths.Add(_batchLength - start);

            if (sendInSeparateBatch)
            {
                // 只提交刚加入的这一条：临时摘走其余长度记录。
                int last = _commandLengths[_commandLengths.Count - 1];
                int prefixBytes = start;
                ReadOnlySpan<byte> only = _batch.AsSpan(prefixBytes, last);
                CmdLogId(cmdId, $"ch={Id} SendCommand **立即派发**（独立批）id=0x{cmdId:x} handle=0x{cmdHandle:x8} len={last}");
                int hr = Dispatcher != null ? Dispatcher.Dispatch(only, this) : HResult.S_OK;
                AccountDispatchResult(hr, only);
                CmdLogId(cmdId, $"ch={Id} SendCommand 立即派发结果 id=0x{cmdId:x} hr=0x{hr:x8}");
                // 回滚缓冲，保持当前批次不受影响
                _batchLength = prefixBytes;
                _commandLengths.RemoveAt(_commandLengths.Count - 1);
                return hr;
            }

            CmdLogId(cmdId, $"ch={Id} SendCommand **已入批**（等 Commit）id=0x{cmdId:x} handle=0x{cmdHandle:x8} 批次内共={_commandLengths.Count} 字节={_batchLength}");
            return HResult.S_OK;
        }

        /// <summary>关闭当前批次。本实现里批次边界不产生副作用，仅校验没有未闭合的命令。</summary>
        public int CloseBatch()
        {
            if (_openStart >= 0) { CmdLog($"ch={Id} CloseBatch **被拒**（命令未关闭，E_UNEXPECTED）"); return HResult.E_UNEXPECTED; }
            return HResult.S_OK;
        }

        /// <summary>提交：按入队顺序解码执行整批命令，然后清空缓冲。</summary>
        public int Commit()
        {
            if (_openStart >= 0) { CmdLog($"ch={Id} Commit **被拒**（命令未关闭，E_UNEXPECTED）"); return HResult.E_UNEXPECTED; }

            // 波46 · `D-G54`：**这里是提交的唯一汇聚点**（四条调用路径全经过它）⇒ 预检放这里
            // 才不会漏路径（详见 `PreflightPendingCommands()` 顶部注释）。默认零开销。
            if (MilPresentation.DiagnosticSinkEnabled) PreflightPendingCommands();

            int hr = HResult.S_OK;
            int offset = 0;
            foreach (int length in _commandLengths)
            {
                ReadOnlySpan<byte> cmd = _batch.AsSpan(offset, length);
                CmdLogId(System.Buffers.Binary.BinaryPrimitives.ReadInt32LittleEndian(cmd), $"ch={Id} 派发 id=0x{System.Buffers.Binary.BinaryPrimitives.ReadInt32LittleEndian(cmd):x} handle=0x{System.Buffers.Binary.BinaryPrimitives.ReadUInt32LittleEndian(cmd.Slice(4)):x8} len={length}");
                int one = Dispatcher != null ? Dispatcher.Dispatch(cmd, this) : HResult.S_OK;
                AccountDispatchResult(one, cmd);
                if (HResult.Failed(one) && hr == HResult.S_OK) hr = one;
                offset += length;
            }

            _batchLength = 0;
            _commandLengths.Clear();
            return hr;
        }

        private void AccountDispatchResult(int hr, ReadOnlySpan<byte> cmd)
        {
            if (hr == HResult.E_NOTIMPL)
            {
                NotImplCommands++;
                MilCmd id = cmd.Length >= 4 ? (MilCmd)System.Buffers.Binary.BinaryPrimitives.ReadInt32LittleEndian(cmd) : MilCmd.MilCmdInvalid;
                NotImplRegistry.TryGetValue(id, out long n);
                NotImplRegistry[id] = n + 1;
            }
            else if (HResult.Failed(hr))
            {
                FailedCommands++;
            }
            else
            {
                CommittedCommands++;
            }
        }

        private void Append(ReadOnlySpan<byte> data)
        {
            int required = _batchLength + data.Length;
            if (required > _batch.Length)
            {
                int cap = _batch.Length;
                while (cap < required) cap *= 2;
                Array.Resize(ref _batch, cap);
            }
            data.CopyTo(_batch.AsSpan(_batchLength));
            _batchLength += data.Length;
        }

        // ==================================================================
        //  资源访问便捷方法
        // ==================================================================

        public MilResource Lookup(DUCE.ResourceHandle h) => Resources.Lookup(h);

        public T Lookup<T>(DUCE.ResourceHandle h) where T : MilResource => Resources.Lookup<T>(h);

        /// <summary>取 Visual 句柄对应的 MilVisualNode；句柄为空或类型不符时返回 null。</summary>
        public MilVisualNode GetVisual(DUCE.ResourceHandle h) => (Resources.Lookup(h) as MilVisualResource)?.Visual;

        /// <summary>把 Visual 的子句柄序列解析为 MilVisualNode 序列（跳过无效句柄）。</summary>
        public List<MilVisualNode> ResolveChildren(IEnumerable<DUCE.ResourceHandle> handles)
        {
            var list = new List<MilVisualNode>();
            foreach (DUCE.ResourceHandle h in handles)
            {
                MilVisualNode v = GetVisual(h);
                if (v != null) list.Add(v);
            }
            return list;
        }

        public override string ToString() =>
            $"MilChannel#{Id}(partition={Partition.Id}, resources={Resources.Count}, pending={PendingCommandCount})";

        // ==================================================================
        //  契约 IMilChannel 实现（Contracts/Interfaces.cs，只读）
        //
        //  契约的四个写入方法返回 void，无法回传 HRESULT。本实现的处理是：
        //  正常路径静默；违反状态机（例如未 Begin 就 Append、未 End 就 Commit）
        //  属于调用方 bug，直接抛异常——比悄悄丢命令更容易定位。
        // ==================================================================

        private Contracts.MilVisual _root;

        /// <summary>契约错误计数：void 接口上被拒绝的调用次数（诊断用）。</summary>
        public int ContractErrors;

        nint IMilChannel.Handle => Handle;

        MilChannelMarshalType IMilChannel.MarshalType => (MilChannelMarshalType)MarshalType;

        void IMilChannel.BeginCommand(ReadOnlySpan<byte> header, uint cbExtra)
        {
            int hr = BeginCommand(header, cbExtra);
            if (HResult.Failed(hr))
            {
                ContractErrors++;
                throw new InvalidOperationException(
                    $"BeginCommand 失败：{HResult.Name(hr)}（当前 {(IsCommandOpen ? "有" : "无")}未闭合命令）");
            }
        }

        void IMilChannel.AppendCommandData(ReadOnlySpan<byte> data)
        {
            int hr = AppendCommandData(data);
            if (HResult.Failed(hr))
            {
                ContractErrors++;
                throw new InvalidOperationException($"AppendCommandData 失败：{HResult.Name(hr)}");
            }
        }

        void IMilChannel.EndCommand()
        {
            int hr = EndCommand();
            if (HResult.Failed(hr))
            {
                ContractErrors++;
                throw new InvalidOperationException($"EndCommand 失败：{HResult.Name(hr)}");
            }
        }

        IMilResourceTable IMilChannel.Resources => Resources;

        Contracts.MilVisual IMilChannel.Root
        {
            get => _root;
            set => _root = value;
        }

        /// <summary>
        /// 由 TargetSetRoot 调用：把句柄指向的 Visual 子图投影成契约 MilVisual
        /// （渲染层消费的模型），并记为通道根。
        /// </summary>
        public Contracts.MilVisual SetRootFromHandle(DUCE.ResourceHandle handle)
        {
            _root = VisualProjection.Project(this, handle);
            return _root;
        }

        // ── 波46 · `D-G54` 判定点之二：**根属于哪个窗口目标 / 哪条通道** ──────────────
        //   【为什么需要这一笔】`MilTarget.Root` 是**每目标**的，可 `DuplicateHandle` 会让
        //   两个通道的资源表指向**同一个 `MilTarget` 实例**（见 `MilResourceTable.Duplicate`）。
        //   于是"这个目标有根"并不等于"**本通道**有能力投影这棵树"：句柄的命名空间是**每通道**的
        //   （各通道各自从 1 开始下发），out-of-band 通道 3 里根本没有那棵子树 —— 在通道 3 上
        //   投影要么得到 null，要么（句柄号恰好撞上它自己表里的某个 visual）把**别人的树**画出去。
        //   ⇒ 呈现侧要问的**唯一**问题是"这个目标的根**是不是在本通道上**设定的"，
        //     而这件事只能由**执行那条 `MilCmdTargetSetRoot` 的通道**自己记下来。
        //
        //   并发口径与同文件的 `_root` **完全一致**：写入只发生在命令派发（UI/呈现线程，
        //   DUCE SameThread 通道语义），读取只发生在呈现路径；不为它新增锁、也不改变时序。
        private readonly HashSet<MilTarget> _rootedTargets = new HashSet<MilTarget>();

        /// <summary>由 `MilCmdTargetSetRoot` 的派发点调用：记下"该目标的根属于本通道"。</summary>
        public void MarkTargetRooted(MilTarget target)
        {
            if (target != null) _rootedTargets.Add(target);
        }

        /// <summary>该目标的根**是不是在本通道上**设定的（呈现侧据此决定能不能在本通道投影）。</summary>
        public bool IsTargetRooted(MilTarget target) => target != null && _rootedTargets.Contains(target);

        // ── 波46 · `D-G54` 台账盲区：把「提交前预检」**下沉到 `Commit()`** ──────────────
        //   【为什么必须下沉】预检原本长在 `MilNative.MilConnection_CommitChannel` 里，于是只有
        //   **那一条**提交路径会打印。而 `Commit()` 今天有**四条**调用路径：
        //     ① `MilConnection_CommitChannel`（MilNative.cs）
        //     ② `MilNative.WgxConnection_SameThreadPresent`（每个通道一次）
        //     ③ `FlushPendingCommandsBeforeInvalidation`（收尾 flush）
        //     ④ `MilComposition_SyncFlush`（MilNative.Window.cs）
        //   实测后果：弹窗那次 `SetRoot`（`id=0x35 handle=0x00000894`）**被派发了、却没进预检**
        //   ⇒ 预检里 `id=0x35` 只有 **1** 条，看起来像"第二条没进缓冲"（`W46C` 报告 §2 的假象）。
        //   ⇒ 把打印点放到 `Commit()` 上：**所有**路径（含将来新增的）自动被覆盖，只加打印、不改语义。
        //   输出**逐字沿用**原 `MilNative.PreflightPendingCommands` 的格式（既有判据按它匹配）。
        //   仍然只在诊断汇开启时做（`WPF_LINUX_MIL_LOG` 指向文件），默认零开销。
        //
        // ── 预算与 id 白名单（设计稿 §9-G7：**不能让仪器把被测对象拖死**）──────────────
        //   【问题】下沉之后**四条路径都打印**，而这是"逐条待提交命令"级别的输出；真应用
        //   通道 2 `committed=3621` ⇒ 不设限的话日志会涨到几十 MB，而且**慢**。
        //   【为什么不能只用"行数预算"】弹出下拉弹窗（t=25 s）那两条命令**很晚**才来 ——
        //   一个小的固定预算在它们到达之前就烧光了 ⇒ 会把本轮最关键的读数吃掉（本项目
        //   反复踩过"仪器把自己的读数吃掉"，`W46C` 报告 §3.1）。所以：
        //     · **id 白名单优先**：设了 `WPF_LINUX_CMDLOG_ID`（与 `[CMD]` 台账**同一个**开关）
        //       时，逐条明细**只打 id 命中白名单的命令**（其余命令只计数、不打行）
        //       ⇒ 只关心的那几条命令**永远不会被预算吃掉**，日志也小；
        //     · **兜底预算** `WPF_LINUX_PREFLIGHT_BUDGET`（默认 20000 行）：没设白名单时
        //       仍然给一个上限，用尽打一行"预算用尽"（**不静默**）。
        //   两条都**只影响打印**，不影响任何判定语义。
        private static int _preflightDetails;
        private static int _preflightSuppressed;
        private static int _preflightBudget = -1;

        private static int PreflightBudget()
        {
            if (_preflightBudget >= 0) return _preflightBudget;
            string s = Environment.GetEnvironmentVariable("WPF_LINUX_PREFLIGHT_BUDGET");
            int v = 20000;
            if (!string.IsNullOrEmpty(s) && int.TryParse(s, out int parsed) && parsed >= 0) v = parsed;
            _preflightBudget = v;
            return _preflightBudget;
        }

        internal void PreflightPendingCommands()
        {
            try
            {
                if (_commandLengths.Count == 0)
                {
                    if (MilPresentation.DiagnosticSinkEnabled)
                        MilPresentation.Trace($"[preflight] 通道 {Id} 无待提交命令");
                    return;
                }
                // 白名单非空 ⇒ 只明细打印命中 id 的命令；此时**不再套预算**（白名单自己就限了量，
                // 而"关心的命令"绝不能被预算吃掉 —— 弹窗那两条很晚才来）。无白名单 ⇒ 套预算。
                bool whitelist = CmdLogWhitelistSet;
                int budget = PreflightBudget();
                int off = 0;
                for (int i = 0; i < _commandLengths.Count; i++)
                {
                    int len = _commandLengths[i];
                    if (len < 4 || off + 4 > _batchLength) { MilPresentation.Trace($"[preflight] #{i} 长度异常 {len}"); break; }
                    int id = System.Buffers.Binary.BinaryPrimitives.ReadInt32LittleEndian(_batch.AsSpan(off, 4));
                    uint handle = len >= 8 ? System.Buffers.Binary.BinaryPrimitives.ReadUInt32LittleEndian(_batch.AsSpan(off + 4, 4)) : 0u;
                    bool known = handle == 0 || Resources.Lookup(new DUCE.ResourceHandle(handle)) != null;
                    bool wanted = !whitelist || CmdLogWanted(id);
                    bool within = wanted && (whitelist || budget == 0 || _preflightDetails < budget);
                    if (within)
                    {
                        _preflightDetails++;
                        MilPresentation.Trace(
                            $"[preflight] 通道 {Id} 待提交 #{i}: id=0x{id:x} ({(MilCmd)id}) " +
                            $"len={len} handle=0x{handle:x8} 在资源表里={known}");
                        if (!whitelist && budget > 0 && _preflightDetails == budget)
                            MilPresentation.Trace(
                                $"[preflight] …明细预算用尽（已打 {_preflightDetails} 条，此后只计数、不打行；" +
                                "要看指定命令请设 WPF_LINUX_CMDLOG_ID 白名单，或调 WPF_LINUX_PREFLIGHT_BUDGET）。");
                    }
                    else
                    {
                        _preflightSuppressed++;
                    }
                    off += len;
                }
            }
            catch (Exception ex) { MilPresentation.Trace($"[preflight] 失败：{ex.GetType().Name}: {ex.Message}"); }
        }
    }

    /// <summary>
    /// 通道句柄（IntPtr）↔ MilChannel 的注册表。
    ///
    /// 【句柄值为什么不再是 GCHandle】
    /// 旧实现用 <c>GCHandle.ToIntPtr(GCHandle.Alloc(channel))</c> 当句柄值。GCHandle 不是内核对象，
    /// 它的 IntPtr 只是 GC 句柄表的槽位下标，<c>Free()</c> 之后槽位会被后来的 <c>Alloc</c> 原样复用。
    /// 于是这条交错序列会误伤无辜：
    ///     A 注销句柄 p → B 建通道拿到同一个 p → A 再注销 p（本该返回 false）→ 删掉的是 B 的通道。
    /// 这就是 xunit 并行下的 flaky 根因：它跟"有没有加锁"无关，锁也拦不住句柄值被回收再用（ABA）。
    /// 现在句柄值由单调计数器下发、进程内永不复用，并用 <see cref="ConcurrentDictionary{TKey,TValue}"/>
    /// 直接索引；注销一个陈旧句柄必然返回 false，ABA 从根上不成立。
    /// </summary>
    internal static class MilChannelRegistry
    {
        /// <summary>
        /// 句柄值起始基数。刻意取一个远大于 0 的值，避免与调用方手写的"假句柄"撞车
        /// （测试里用 <c>new IntPtr(0x1234)</c> 期望 E_HANDLE；从 1 开始计数迟早会撞上）。
        /// 0x1000_0000 在 32 位 IntPtr 的正区间内，64 位同样成立。
        /// </summary>
        private const long HandleBase = 0x1000_0000;

        private static long _nextHandle = HandleBase;

        /// <summary>句柄值 → 通道。强引用，等价于原来的 Normal GCHandle，但不再占用 GC 句柄表。</summary>
        private static readonly ConcurrentDictionary<IntPtr, MilChannel> _channels = new ConcurrentDictionary<IntPtr, MilChannel>();

        /// <summary>
        /// 连接 → 该连接上的通道。<see cref="MilNative.WgxConnection_SameThreadPresent"/> 按连接直接索引，
        /// 不再遍历整张进程级表——遍历快照会把"正在被注销的通道"也卷进本次呈现。
        /// </summary>
        private static readonly ConcurrentDictionary<IntPtr, ConcurrentDictionary<IntPtr, MilChannel>> _byConnection =
            new ConcurrentDictionary<IntPtr, ConcurrentDictionary<IntPtr, MilChannel>>();

        public static IntPtr Register(MilChannel channel)
        {
            // Connection 在 Register 之前已由调用方设好（MilConnection_CreateChannel 的对象初始化器），
            // 之后不再变动，因此连接索引在注册这一刻建立即始终有效。
            IntPtr ptr = (IntPtr)System.Threading.Interlocked.Increment(ref _nextHandle);
            channel.Handle = ptr;
            _channels[ptr] = channel;

            ConcurrentDictionary<IntPtr, MilChannel> bucket = _byConnection.GetOrAdd(
                channel.Connection, _ => new ConcurrentDictionary<IntPtr, MilChannel>());
            bucket[ptr] = channel;
            return ptr;
        }

        public static MilChannel Resolve(IntPtr ptr)
        {
            if (ptr == IntPtr.Zero) return null;
            _channels.TryGetValue(ptr, out MilChannel channel);
            return channel;   // 未命中时 TryGetValue 已置 null
        }

        /// <summary>该句柄值是否仍然存活。比 Count 更适合做并发下的断言（Count 是进程级全局量）。</summary>
        public static bool Contains(IntPtr ptr) =>
            ptr != IntPtr.Zero && _channels.ContainsKey(ptr);

        public static bool Unregister(IntPtr ptr)
        {
            if (ptr == IntPtr.Zero) return false;
            if (!_channels.TryRemove(ptr, out MilChannel channel)) return false;

            if (_byConnection.TryGetValue(channel.Connection, out ConcurrentDictionary<IntPtr, MilChannel> bucket))
            {
                bucket.TryRemove(ptr, out _);
                // 只在 bucket 仍是注册时那一个的前提下摘除，避免删掉别人刚建的新桶。
                if (bucket.IsEmpty)
                {
                    ((ICollection<KeyValuePair<IntPtr, ConcurrentDictionary<IntPtr, MilChannel>>>)_byConnection)
                        .Remove(new KeyValuePair<IntPtr, ConcurrentDictionary<IntPtr, MilChannel>>(
                            channel.Connection, bucket));
                }
            }
            return true;
        }

        // ── 债务 #1 的长期仪器：**通道泄漏守卫**（只读、缺省关）──────────────────
        // 【它解决的问题】`MilChannelRegistry` 是**进程级静态表**，而 `ResetProcessStateForTests()`
        //   **刻意不清它**（理由见 MilNative.Exports.cs:266-280）⇒ 一个用例泄漏的通道会活到后面的用例，
        //   而 xunit 的**调度/发现顺序随负载与并行度变化** ⇒ "同一命令有时红"可以完全由顺序引起。
        // 【怎么用】`WPF_LINUX_CHANNEL_LEAK_TRACE=1` ⇒ 每次 `ResetProcessStateForTests()`（即多数用例开头）
        //   打一行"**上一个用例留下了几个通道**"+ 句柄列表 + 峰值 ⇒ 泄漏一眼可见。
        // 【纪律】缺省**零开销、零输出**；不改变任何行为（只读快照）。
        private static long s_peakCount;
        private static long s_reports;

        /// <summary>是否打印泄漏守卫（`WPF_LINUX_CHANNEL_LEAK_TRACE=1`）。</summary>
        public static bool LeakTraceEnabled { get; } =
            Environment.GetEnvironmentVariable("WPF_LINUX_CHANNEL_LEAK_TRACE") == "1";

        /// <summary>存活通道的句柄快照（只读，诊断用）。</summary>
        public static IntPtr[] HandleSnapshot()
        {
            var list = new List<IntPtr>(_channels.Count);
            foreach (IntPtr key in _channels.Keys) list.Add(key);
            return list.ToArray();
        }

        /// <summary>
        /// 打一行泄漏守卫（**只在开关打开时**）。由用例开头（`ResetProcessStateForTests`）调用，
        /// 因此报的是"**上一个用例留下什么**"—— 这正是"谁泄漏给谁"的证据形态。
        /// </summary>
        public static void ReportLeaks(string context)
        {
            if (!LeakTraceEnabled) return;

            int now = _channels.Count;
            long peak = now > s_peakCount ? s_peakCount = now : s_peakCount;
            s_reports++;

            var sb = new System.Text.StringBuilder();
            sb.Append($"[chan-leak] #{s_reports} {context}：当前存活通道 = {now}（峰值 {peak}）");
            if (now > 0)
            {
                sb.Append("；句柄 = ");
                foreach (IntPtr h in HandleSnapshot()) sb.Append($"0x{(long)h:x} ");
                sb.Append("（其中 None 的通道就是**上一个用例留下的**）");
            }
            // 【为什么还要写文件】`dotnet test` 会把**测试宿主**的 stderr 吞掉（只在失败时回放一部分），
            //   实测 `Console.Error` 在通过的那一轮一行都看不到 ⇒ 仪器必须能落到文件里才可用
            //   （`WPF_LINUX_CHANNEL_LEAK_LOG=<path>`；与既有 `WPF_LINUX_MIL_LOG` 同一手法）。
            Console.Error.WriteLine(sb.ToString());
            Console.Error.Flush();

            string sink = Environment.GetEnvironmentVariable("WPF_LINUX_CHANNEL_LEAK_LOG");
            if (!string.IsNullOrEmpty(sink))
            {
                try { System.IO.File.AppendAllText(sink, sb.ToString() + Environment.NewLine); }
                catch { /* 诊断失败不影响任何行为 */ }
            }
        }

        /// <summary>存活通道总数（诊断用）。注意这是进程级全局量，并发下不能拿它做增量断言。</summary>
        public static int Count => _channels.Count;

        /// <summary>某个连接上的通道快照。取代原来的全表遍历。</summary>
        public static IEnumerable<MilChannel> ChannelsOfConnection(IntPtr connection)
        {
            if (!_byConnection.TryGetValue(connection, out ConcurrentDictionary<IntPtr, MilChannel> bucket))
                return Array.Empty<MilChannel>();

            var snapshot = new List<MilChannel>(bucket.Count);
            foreach (MilChannel c in bucket.Values) snapshot.Add(c);
            return snapshot;
        }
    }
}
