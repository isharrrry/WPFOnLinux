// ⚠️ 本文件由 build/PresentationFramework.Linux/reapply-patches.py **生成**，不要手改。
//
// 内容 = 上游 `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/PtsHost/PtsCache.cs` 逐字复制 + 5 处 W86A（`TASK-0304`/`TASK-0305`）改动。
// 每次运行该脚本都会从上游重读重生成；needle 找不到 / 命中数不符时**报错退出**
// （不会静默产出未打补丁的副本）。改动逐处见：
//   E1 ／ E2 ／ E3 ／ E4 ／ E5
//
// 背景（`D-G70`/`D-G78`）：本移植没有 PTS/原生 LineServices ⇒ 切「富文本」/「流文档」页
// 曾**整进程 `rc=134`**。本件把它变成「**具名、可判、可见的能力边界**」：
//   · native 侧新增 `src/WpfGfx.Linux.Native/src/win32_pts.c`（6 个入口导出、**如实返回非零 LsErr**、
//     打具名台账 `PTS_GAP entry=… seq=… err=-10000`）；
//   · 本文件（托管侧）负责：**拆掉毒池项**（`D-G78` 的根因）＋ **具名能力闩** ＋ **页级可见降级**。
// ⚠️ `Invariant.Assert` **一个都没删、没放宽** —— 目标是让它们**不再被走到**；
//    若仍被走到，断言照旧响亮（那是新缺陷）。
// Licensed to the .NET Foundation under one or more agreements.
// The .NET Foundation licenses this file to you under the MIT license.

/* SSS_DROP_BEGIN */

/*************************************************************************
* 11/17/07 - bartde
*
* NOTICE: Code excluded from Developer Reference Sources.
*         Don't remove the SSS_DROP_BEGIN directive on top of the file.
*
* Reason for exclusion: obscure PTLS interface
*
**************************************************************************/


//
// Description: Definition of class responsible for PTS Context lifetime
//              management.
//

using System.Runtime.InteropServices;           // DllImport / 具名缺口台账（W86A）
using System.Threading;                         // Interlocked

using DllImport = MS.Internal.PresentationFramework.DllImport;
using System.Windows;                           // WrapDirection
using System.Windows.Media.TextFormatting;      // TextFormatter
using System.Windows.Threading;                 // Dispatcher
using System.Windows.Media;
using MS.Internal.Text;                         // TextDpi
using MS.Internal.TextFormatting;               // UnsafeTextPenaltyModule
using MS.Internal.PtsHost.UnsafeNativeMethods;  // PTS

namespace MS.Internal.PtsHost
{
    /// <summary>
    /// PtsCache class encapsulates lifetime management of PTS Context.
    /// Internally provides caching mechanism, which enables reusing PTS Context.
    /// </summary>
    /// <remarks>
    /// Instead of using static instance of PtsCache, instance of PtsCache
    /// could be stored in the current Dispatcher as context data. That
    /// would be much cleaner design. But there is one problem:
    /// Thread.GetData() is a static method that accesses the current
    /// thread's Dispatcher. Since DependencyObject may be created using
    /// different Dispatcher then the current one, incorrect PtsCache
    /// could be retrieved.
    /// For this reason there is only one PtsCache instance that stores
    /// mapping between Dispatcher and PTS context pool.
    /// </remarks>
    internal sealed class PtsCache
    {
        //-------------------------------------------------------------------
        //
        //  Internal Methods
        //
        //-------------------------------------------------------------------

        #region Internal Methods

        /// <summary>
        /// Acquires new PTS Context and associates it with new owner.
        /// </summary>
        /// <param name="ptsContext">Context used to communicate with PTS component.</param>
        internal static PtsHost AcquireContext(PtsContext ptsContext, TextFormattingMode textFormattingMode)
        {
            PtsCache ptsCache = ptsContext.Dispatcher.PtsCache as PtsCache;
            if (ptsCache == null)
            {
                ptsCache = new PtsCache(ptsContext.Dispatcher);
                ptsContext.Dispatcher.PtsCache = ptsCache;
            }
            return ptsCache.AcquireContextCore(ptsContext, textFormattingMode);
        }

        /// <summary>
        /// Notifies PtsCache about destruction of a PtsContext.
        /// </summary>
        /// <param name="ptsContext">Context used to communicate with PTS component.</param>
        internal static void ReleaseContext(PtsContext ptsContext)
        {
            PtsCache ptsCache = ptsContext.Dispatcher.PtsCache as PtsCache;
            Invariant.Assert(ptsCache != null, "Cannot retrieve PtsCache from PtsContext object.");
            ptsCache.ReleaseContextCore(ptsContext);
        }

        /// <summary>
        /// Retrieves floater handler callbacks.
        /// </summary>
        /// <param name="ptsHost">Host of the PTS component.</param>
        /// <param name="pobjectinfo">Struct with callbacks to fill in.</param>
        internal static void GetFloaterHandlerInfo(PtsHost ptsHost, IntPtr pobjectinfo)
        {
            PtsCache ptsCache = Dispatcher.CurrentDispatcher.PtsCache as PtsCache;
            Invariant.Assert(ptsCache != null, "Cannot retrieve PtsCache from the current Dispatcher.");
            ptsCache.GetFloaterHandlerInfoCore(ptsHost, pobjectinfo);
        }

        /// <summary>
        /// Retrieves table handler callbacks.
        /// </summary>
        /// <param name="ptsHost">Host of the PTS component.</param>
        /// <param name="pobjectinfo">Struct with callbacks to fill in.</param>
        internal static void GetTableObjHandlerInfo(PtsHost ptsHost, IntPtr pobjectinfo)
        {
            PtsCache ptsCache = Dispatcher.CurrentDispatcher.PtsCache as PtsCache;
            Invariant.Assert(ptsCache != null, "Cannot retrieve PtsCache from the current Dispatcher.");
            ptsCache.GetTableObjHandlerInfoCore(ptsHost, pobjectinfo);
        }

        /// <summary>
        /// Checks whether PtsCache is already diposed.
        /// </summary>
        internal static bool IsDisposed()
        {
            bool disposed = true;
            Dispatcher dispatcher = Dispatcher.CurrentDispatcher;
            if (dispatcher != null)
            {
                PtsCache ptsCache = Dispatcher.CurrentDispatcher.PtsCache as PtsCache;
                if (ptsCache != null)
                {
                    disposed = ptsCache._disposed;
                }
            }
            return disposed;
        }

        #endregion Internal Methods

        //-------------------------------------------------------------------
        //
        //  Private Methods
        //
        //-------------------------------------------------------------------

        #region Private Methods

        /// <summary>
        /// Constructor - private to protect agains initialization.
        /// </summary>
        /// <param name="dispatcher">Dispatcher associated with PtsCache.</param>
        private PtsCache(Dispatcher dispatcher)
        {
            // Initially allocate just one entry. The constructor gets called
            // when acquiring the first PTS Context, so it guarantees at least
            // one element in the collection.
            _contextPool = new List<ContextDesc>(1);

            // Register for ShutdownFinished event for the Dispatcher. When Dispatcher
            // finishes the shutdown process, all associated resources stored in its
            // PTS context pool need to be disposed as well.
            // NOTE: Cannot do this work during ShutdownStarted, because after this
            //       event is fired, layout process may still be executed.

            // Add an event handler for AppDomain unload. If Dispatcher is not running
            // we are not going to receive ShutdownFinished to do appropriate cleanup.
            // When an AppDomain is unloaded, we'll be called back on a worker thread.
            PtsCacheShutDownListener listener = new PtsCacheShutDownListener(this);
        }

        /// <summary>
        /// PtsCache finalizer.
        /// </summary>
        ~PtsCache()
        {
            // After shutdown is initiated, do not allow Finalizer thread to the cleanup.
            if (!Interlocked.CompareExchange(ref _disposed, true, false))
            {
                // Destroy all PTS contexts
                DestroyPTSContexts();
            }
        }

        /// <summary>
        /// Acquires new PTS Context and associate it with new owner.
        /// </summary>
        /// <param name="ptsContext">Context used to communicate with PTS component.</param>
        /// <returns>PtsHost associated with new owner.</returns>
        private PtsHost AcquireContextCore(PtsContext ptsContext, TextFormattingMode textFormattingMode)
        {
            int index;

            // ── W86A `A2`：具名能力闩（**只对"PTS 能力不可用"这一个条件生效**）──────────
            //   第一次失败之后，后续布局**不再进 native、不再扫池**：
            //   否则每次 Measure 都抛一次 ⇒ 布局重入 / CPU 打转（W78A §3.4 风险 2）。
            //   ⚠️ 这里**不吞**任何东西：抛的是**具名**异常，谁都能按类型接住并计数。
            if (_ptsUnavailable != null)
            {
                // 每次抛**新的**实例（Stack 指向"这次是谁来问的"），首次失败挂在 InnerException 上
                // —— 抛同一个旧实例会让栈指向**第一次**的调用点，那是误导性读数。
                throw new PtsUnavailableException(
                    _ptsUnavailable.Entry, _ptsUnavailable.ErrorCode,
                    "PTS 能力已在本进程内判定不可用（首次失败见 InnerException）—— 本闩只覆盖这一个具名条件",
                    _ptsUnavailable);
            }

            // Look for the first free PTS Context.
            for (index = 0; index < _contextPool.Count; index++)
            {
                if (!_contextPool[index].InUse &&
                    _contextPool[index].IsOptimalParagraphEnabled == ptsContext.IsOptimalParagraphEnabled)
                {
                    break;
                }
            }

#pragma warning disable IDE0017
            // Create new PTS Context, if cannot find free one.
            if (index == _contextPool.Count)
            {
                // W86A `A2`：native 侧**累计入口调用数**的快照（判缺口是不是 native 亲口说的，见 catch）
                int ptsCallsBefore = WpfLinuxPtsGap.NativeCalls();
                ContextDesc created = null;      // 本次新建的池项（**按引用**认，不读它的状态）
                try
                {
                    created = new ContextDesc();
                    _contextPool.Add(created);
                    _contextPool[index].IsOptimalParagraphEnabled = ptsContext.IsOptimalParagraphEnabled;
                    _contextPool[index].PtsHost = new PtsHost();
                    _contextPool[index].PtsHost.Context = CreatePTSContext(index, textFormattingMode);
                }
                catch (Exception e)
                {
                    // ── W86A `A2` ①：**毒池项必须离开池**（`D-G78` 的根因）────────────────
                    //   上游把池项加进去（`:195`）、再把 `CreatePTSContext` 的返回值塞进
                    //   `PtsHost.Context`（`:198`）。中间任何一步抛异常 ⇒ 池里留下一条
                    //   `InUse == false` / `PtsHost.Context == IntPtr.Zero` 的半初始化项；
                    //   下一趟布局在 `:182-189` 的循环里把它当**空闲项**复用（跳过创建），
                    //   于是后面第一次问 `PtsHost.Context` 就撞
                    //   `Invariant.Assert(_context != IntPtr.Zero)` ⇒ `Invariant.FailFast`
                    //   ⇒ **`Environment.FailFast` 不可捕获 ⇒ rc=134**。
                    //
                    //   ⚠️⚠️ **判据只许用"对象身份"，一个字都不许读 `PtsHost.Context`**：
                    //       `PtsHost.Context` 的 **getter 自己就在断言** `_context != IntPtr.Zero`
                    //       （`PtsHost.cs:62-66`）—— 半初始化项**恰好**违反它 ⇒
                    //       用 `xxx.PtsHost.Context == IntPtr.Zero` 当"是不是半初始化"的判据，
                    //       **等于让修复自己在原地触发 `FailFast`**。
                    //       【本车道实测踩到】W86A 第一版就是这么写的，实测栈：
                    //         Invariant.FailFast ← PtsHost.get_Context ← PtsCache.AcquireContextCore
                    //       即 `D-G78` 那条链**被"修法"原样复现了一遍**（读数见 W86A 报告 §3）。
                    //   ⇒ 正确判据：`created` 是**本次刚 new 出来、刚 Add 进去的那一个对象引用**
                    //       （引用相等，`List<T>.Remove(T)` 就是按引用找），根本不需要读它的状态。
                    //       若 `_contextPool.Add` 自己抛（OOM）⇒ `created == null` ⇒ 不删（安全）。
                    if (created != null)
                    {
                        // 半初始化项若已建了 LS 罚分模块，它**已被 SuppressFinalize**
                        // ⇒ 必须在这里显式释放，否则泄漏（上游只在正常拆卸路径 Dispose）。
                        // ⚠️ `TextPenaltyModule` 是**字段**（不是属性）⇒ 读它不会触发任何断言。
                        created.TextPenaltyModule?.Dispose();
                        _contextPool.Remove(created);
                    }

                    // ── W86A `A2` ②：**具名能力闩**（失败**只**对"PTS 缺口"这一族立闩）──────
                    if (WpfLinuxPtsGap.IsPtsUnavailable(e, ptsCallsBefore))
                    {
                        _ptsUnavailable = WpfLinuxPtsGap.Describe(e);
                        throw _ptsUnavailable;
                    }
                    throw;          // 其它异常**原样传播**（不吞、不改名、不立闩）
                }
            }
#pragma warning restore IDE0017

            // Initialize TextFormatter, if optimal paragraph is enabled.
            // Optimal paragraph requires new TextFormatter for every PTS Context.
            if (_contextPool[index].IsOptimalParagraphEnabled)
            {
                ptsContext.TextFormatter = _contextPool[index].TextFormatter;
            }

            // Assign PTS Context to new owner.
            _contextPool[index].InUse = true;
            _contextPool[index].Owner = new WeakReference(ptsContext);

            return _contextPool[index].PtsHost;
        }

        /// <summary>
        /// Notifies PtsCache about destruction of a PtsContext.
        /// </summary>
        /// <param name="ptsContext">Context used to communicate with PTS component.</param>
        private void ReleaseContextCore(PtsContext ptsContext)
        {
            // _releaseQueue may be accessed from Finalizer thread or Dispatcher thread.
            lock (_lock)
            {
                // After shutdown is initiated, do not allow Finalizer thread to add any
                // items to _releaseQueue.
                if (!_disposed)
                {
                    // Add PtsContext to collection of released PtsContexts.
                    // If the queue is empty, schedule Dispatcher time to dispose
                    // PtsContexts in the Dispatcher thread.
                    // If the queue is not empty, there is already pending Dispatcher request.
                    if (_releaseQueue == null)
                    {
                        _releaseQueue = new List<PtsContext>();
                        ptsContext.Dispatcher.BeginInvoke(DispatcherPriority.Background, new DispatcherOperationCallback(OnPtsContextReleased), null);
                    }
                    _releaseQueue.Add(ptsContext);
                }
            }
        }

        /// <summary>
        /// Retrieves floater handler callbacks.
        /// </summary>
        /// <param name="ptsHost">Host of the PTS component.</param>
        /// <param name="pobjectinfo">Struct with callbacks to fill in.</param>
        private void GetFloaterHandlerInfoCore(PtsHost ptsHost, IntPtr pobjectinfo)
        {
            int index;
            for (index = 0; index < _contextPool.Count; index++)
            {
                if (_contextPool[index].PtsHost == ptsHost)
                {
                    break;
                }
            }
            Invariant.Assert(index < _contextPool.Count, "Cannot find matching PtsHost in the Context pool.");
            PTS.Validate(PTS.GetFloaterHandlerInfo(ref _contextPool[index].FloaterInit, pobjectinfo));
        }

        /// <summary>
        /// Retrieves table handler callbacks.
        /// </summary>
        /// <param name="ptsHost">Host of the PTS component.</param>
        /// <param name="pobjectinfo">Struct with callbacks to fill in.</param>
        private void GetTableObjHandlerInfoCore(PtsHost ptsHost, IntPtr pobjectinfo)
        {
            int index;
            for (index = 0; index < _contextPool.Count; index++)
            {
                if (_contextPool[index].PtsHost == ptsHost)
                {
                    break;
                }
            }
            Invariant.Assert(index < _contextPool.Count, "Cannot find matching PtsHost in the context pool.");
            PTS.Validate(PTS.GetTableObjHandlerInfo(ref _contextPool[index].TableobjInit, pobjectinfo));
        }

        /// <summary>
        /// Delete all resources associated with PtsCache (PTS Contexts)
        /// </summary>
        private void Shutdown()
        {
            // WeakReference.Target is NULL when object is in the finalization queue.
            // Hence there is possibility to destroy PTS Context before all pages are
            // destroyed from the finalizer of PtsContext.
            // Workaround: wait for all finalizers to run before destroying any PTS contexts.
            GC.WaitForPendingFinalizers();

            // After shutdown is initiated, do not allow Finalizer thread to add any
            // items to _releaseQueue.
            if (!Interlocked.CompareExchange(ref _disposed, true, false))
            {
                // Dispose any pending PtsContexts stored in _releaseQueue
                OnPtsContextReleased(false);

                // Destroy all PTS contexts
                DestroyPTSContexts();
            }
        }

        /// <summary>
        /// Destroy all PTS contexts.
        /// </summary>
        private void DestroyPTSContexts()
        {
            // Destroy all unused PTS Contexts.
            int index = 0;
            while (index < _contextPool.Count)
            {
                PtsContext ptsContext = _contextPool[index].Owner.Target as PtsContext;
                if (ptsContext != null)
                {
                    Invariant.Assert(_contextPool[index].PtsHost.Context == ptsContext.Context, "PTS Context mismatch.");
                    _contextPool[index].Owner = new WeakReference(null);
                    _contextPool[index].InUse = false;

                    Invariant.Assert(!ptsContext.Disposed, "PtsContext has been already disposed.");
                    ptsContext.Dispose();
                }

                if (!_contextPool[index].InUse)
                {
                    // Ignore any errors during shutdown. Reason:
                    // * make sure that loop continues and all contexts have a chance to be destroyed.
                    // * this is shutdown case, so even if memory is not disposed, the system will reclaim it.
                    Invariant.Assert(_contextPool[index].PtsHost.Context != IntPtr.Zero, "PTS Context handle is not valid.");
                    PTS.IgnoreError(PTS.DestroyDocContext(_contextPool[index].PtsHost.Context));
                    Invariant.Assert(_contextPool[index].InstalledObjects != IntPtr.Zero, "Installed Objects handle is not valid.");
                    PTS.IgnoreError(PTS.DestroyInstalledObjectsInfo(_contextPool[index].InstalledObjects));
                    // Explicitly dispose the penalty module object to ensure proper destruction
                    // order of PTSContext  and the penalty module (PTS context must be destroyed first).
                    _contextPool[index].TextPenaltyModule?.Dispose();

                    _contextPool.RemoveAt(index);
                }
                else
                {
                    index++;
                }
            }
        }

        /// <summary>
        /// Cleans up PTS Context pool.
        /// </summary>
        /// <param name="args">Not used.</param>
        private object OnPtsContextReleased(object args)
        {
            OnPtsContextReleased(true);
            return null;
        }

        /// <summary>
        /// Cleans up PTS Context pool.
        /// </summary>
        /// <param name="cleanContextPool">Whether needs to clean context pool.</param>
        private void OnPtsContextReleased(bool cleanContextPool)
        {
            int index;

            // _releaseQueue may be accessed from Finalizer thread or Dispatcher thread.
            lock (_lock)
            {
                // Dispose any pending PtsContexts
                if (_releaseQueue != null)
                {
                    foreach (PtsContext ptsContext in _releaseQueue)
                    {
                        // Find the PtsContext in the context pool and detach it from PtsHost.
                        for (index = 0; index < _contextPool.Count; index++)
                        {
                            if (_contextPool[index].PtsHost.Context == ptsContext.Context)
                            {
                                _contextPool[index].Owner = new WeakReference(null);
                                _contextPool[index].InUse = false;
                                break;
                            }
                        }
                        Invariant.Assert(index < _contextPool.Count, "PtsContext not found in the context pool.");

                        // Dispose PtsContext.
                        Invariant.Assert(!ptsContext.Disposed, "PtsContext has been already disposed.");
                        ptsContext.Dispose();
                    }
                    _releaseQueue = null;
                }
            }

            // Remove all unused PTS Contexts. Leave at least 4 entries for future use.
            if (cleanContextPool && _contextPool.Count > 4)
            {
                // Destroy all unused PTS Contexts.
                index = 4;
                while (index < _contextPool.Count)
                {
                    if (!_contextPool[index].InUse)
                    {
                        Invariant.Assert(_contextPool[index].PtsHost.Context != IntPtr.Zero, "PTS Context handle is not valid.");
                        PTS.Validate(PTS.DestroyDocContext(_contextPool[index].PtsHost.Context));
                        Invariant.Assert(_contextPool[index].InstalledObjects != IntPtr.Zero, "Installed Objects handle is not valid.");
                        PTS.Validate(PTS.DestroyInstalledObjectsInfo(_contextPool[index].InstalledObjects));
                        // Explicitly dispose the penalty module object to ensure proper destruction
                        // order of PTSContext  and the penalty module (PTS context must be destroyed first).
                        _contextPool[index].TextPenaltyModule?.Dispose();
                        _contextPool.RemoveAt(index);
                        continue;
                    }
                    index++;
                }
            }
        }

        /// <summary>
        /// Creates a new PTS context using PTSWrapper APIs.
        /// </summary>
        /// <param name="index">Index to free entry in the PTS Context pool.</param>
        /// <returns>PTS Context ID.</returns>
        private IntPtr CreatePTSContext(int index, TextFormattingMode textFormattingMode)
        {
            PtsHost ptsHost;
            IntPtr installedObjects;
            int installedObjectsCount;
            TextFormatterContext textFormatterContext;
            IntPtr context;

            ptsHost = _contextPool[index].PtsHost;
            Invariant.Assert(ptsHost != null);

            // Create installed object info.
            InitInstalledObjectsInfo(ptsHost, ref _contextPool[index].SubtrackParaInfo, ref _contextPool[index].SubpageParaInfo, out installedObjects, out installedObjectsCount);
            _contextPool[index].InstalledObjects = installedObjects;

            // Create generic callbacks info.
            InitGenericInfo(ptsHost, (IntPtr)(index + 1), installedObjects, installedObjectsCount, ref _contextPool[index].ContextInfo);

            // Preallocated floater and table info.
            InitFloaterObjInfo(ptsHost, ref _contextPool[index].FloaterInit);
            InitTableObjInfo(ptsHost, ref _contextPool[index].TableobjInit);

            // Setup for optimal paragraph
            if (_contextPool[index].IsOptimalParagraphEnabled)
            {
                textFormatterContext = new TextFormatterContext();
                TextPenaltyModule penaltyModule = textFormatterContext.GetTextPenaltyModule();
                IntPtr ptsPenaltyModule = penaltyModule.DangerousGetHandle();

                _contextPool[index].TextPenaltyModule = penaltyModule;
                _contextPool[index].ContextInfo.ptsPenaltyModule = ptsPenaltyModule;
                _contextPool[index].TextFormatter = TextFormatter.CreateFromContext(textFormatterContext, textFormattingMode);

                // Explicitly take the penalty module object out of finalization queue;
                // PTSCache must manage lifetime of the penalty module explicitly by calling
                // TextPenaltyModule.Dispose to ensure proper destruction order of PTSContext
                // and the penalty module (PTS context must be destroyed first).
                GC.SuppressFinalize(_contextPool[index].TextPenaltyModule);
            }

            // Create PTS Context
            PTS.Validate(PTS.CreateDocContext(ref _contextPool[index].ContextInfo, out context));

            return context;
        }

        /// <summary>
        /// Initializes generic PTS callbacks.
        /// </summary>
        /// <param name="ptsHost">PtsHost that defines all PTS callbacks.</param>
        /// <param name="clientData">Unique PTS Client ID.</param>
        /// <param name="installedObjects">PTS Installed objects.</param>
        /// <param name="installedObjectsCount">Count of PTS Installed objects.</param>
        /// <param name="contextInfo">PTS Context Info to be initialized.</param>
        private unsafe void InitGenericInfo(PtsHost ptsHost, IntPtr clientData, IntPtr installedObjects, int installedObjectsCount, ref PTS.FSCONTEXTINFO contextInfo)
        {
            // Validation
            Invariant.Assert(((int)PTS.FSKREF.fskrefPage) == 0);
            Invariant.Assert(((int)PTS.FSKREF.fskrefMargin) == 1);
            Invariant.Assert(((int)PTS.FSKREF.fskrefParagraph) == 2);
            Invariant.Assert(((int)PTS.FSKREF.fskrefChar) == 3);
            Invariant.Assert(((int)PTS.FSKALIGNFIG.fskalfMin) == 0);
            Invariant.Assert(((int)PTS.FSKALIGNFIG.fskalfCenter) == 1);
            Invariant.Assert(((int)PTS.FSKALIGNFIG.fskalfMax) == 2);
            Invariant.Assert(((int)PTS.FSKWRAP.fskwrNone) == ((int)WrapDirection.None));
            Invariant.Assert(((int)PTS.FSKWRAP.fskwrLeft) == ((int)WrapDirection.Left));
            Invariant.Assert(((int)PTS.FSKWRAP.fskwrRight) == ((int)WrapDirection.Right));
            Invariant.Assert(((int)PTS.FSKWRAP.fskwrBoth) == ((int)WrapDirection.Both));
            Invariant.Assert(((int)PTS.FSKWRAP.fskwrLargest) == 4);
            Invariant.Assert(((int)PTS.FSKCLEAR.fskclearNone) == 0);
            Invariant.Assert(((int)PTS.FSKCLEAR.fskclearLeft) == 1);
            Invariant.Assert(((int)PTS.FSKCLEAR.fskclearRight) == 2);
            Invariant.Assert(((int)PTS.FSKCLEAR.fskclearBoth) == 3);

            // Initialize context info
            contextInfo.version = 0;
            contextInfo.fsffi = PTS.fsffiUseTextQuickLoop
                // This flag is added toward the end of WPF V1 project.
                // PTS requires that break record is present in ReconstructLineVariant call,
                // unfortunately TextFormatter can't give them that as it breaks single-line
                // mode in Bidi scenario. Since break record is never a requirement before,
                // PTS agrees to address this issue in the next version. The current solution
                // for V1 is to temporary disable optimal formatting of the paragraph when
                // figire is fully embedded within the paragraph with text on both sides of the
                // figure. [Windows bug #1506821; WChao, 5/18/2006]
                | PTS.fsffiAvalonDisableOptimalInChains;
            contextInfo.drMinColumnBalancingStep = TextDpi.ToTextDpi(10.0);  // Assume 10px as minimal step
            contextInfo.cInstalledObjects = installedObjectsCount;
            contextInfo.pInstalledObjects = installedObjects;
            contextInfo.pfsclient = clientData;
            contextInfo.pfnAssertFailed = new PTS.AssertFailed(ptsHost.AssertFailed);
            // Initialize figure callbacks
            contextInfo.fscbk.cbkfig.pfnGetFigureProperties = new PTS.GetFigureProperties(ptsHost.GetFigureProperties);
            contextInfo.fscbk.cbkfig.pfnGetFigurePolygons = new PTS.GetFigurePolygons(ptsHost.GetFigurePolygons);
            contextInfo.fscbk.cbkfig.pfnCalcFigurePosition = new PTS.CalcFigurePosition(ptsHost.CalcFigurePosition);
            // Initialize generic callbacks
            contextInfo.fscbk.cbkgen.pfnFSkipPage = new PTS.FSkipPage(ptsHost.FSkipPage);
            contextInfo.fscbk.cbkgen.pfnGetPageDimensions = new PTS.GetPageDimensions(ptsHost.GetPageDimensions);
            contextInfo.fscbk.cbkgen.pfnGetNextSection = new PTS.GetNextSection(ptsHost.GetNextSection);
            contextInfo.fscbk.cbkgen.pfnGetSectionProperties = new PTS.GetSectionProperties(ptsHost.GetSectionProperties);
            contextInfo.fscbk.cbkgen.pfnGetJustificationProperties = new PTS.GetJustificationProperties(ptsHost.GetJustificationProperties);
            contextInfo.fscbk.cbkgen.pfnGetMainTextSegment = new PTS.GetMainTextSegment(ptsHost.GetMainTextSegment);
            contextInfo.fscbk.cbkgen.pfnGetHeaderSegment = new PTS.GetHeaderSegment(ptsHost.GetHeaderSegment);
            contextInfo.fscbk.cbkgen.pfnGetFooterSegment = new PTS.GetFooterSegment(ptsHost.GetFooterSegment);
            contextInfo.fscbk.cbkgen.pfnUpdGetSegmentChange = new PTS.UpdGetSegmentChange(ptsHost.UpdGetSegmentChange);
            contextInfo.fscbk.cbkgen.pfnGetSectionColumnInfo = new PTS.GetSectionColumnInfo(ptsHost.GetSectionColumnInfo);
            contextInfo.fscbk.cbkgen.pfnGetSegmentDefinedColumnSpanAreaInfo = new PTS.GetSegmentDefinedColumnSpanAreaInfo(ptsHost.GetSegmentDefinedColumnSpanAreaInfo);
            contextInfo.fscbk.cbkgen.pfnGetHeightDefinedColumnSpanAreaInfo = new PTS.GetHeightDefinedColumnSpanAreaInfo(ptsHost.GetHeightDefinedColumnSpanAreaInfo);
            contextInfo.fscbk.cbkgen.pfnGetFirstPara = new PTS.GetFirstPara(ptsHost.GetFirstPara);
            contextInfo.fscbk.cbkgen.pfnGetNextPara = new PTS.GetNextPara(ptsHost.GetNextPara);
            contextInfo.fscbk.cbkgen.pfnUpdGetFirstChangeInSegment = new PTS.UpdGetFirstChangeInSegment(ptsHost.UpdGetFirstChangeInSegment);
            contextInfo.fscbk.cbkgen.pfnUpdGetParaChange = new PTS.UpdGetParaChange(ptsHost.UpdGetParaChange);
            contextInfo.fscbk.cbkgen.pfnGetParaProperties = new PTS.GetParaProperties(ptsHost.GetParaProperties);
            contextInfo.fscbk.cbkgen.pfnCreateParaclient = new PTS.CreateParaclient(ptsHost.CreateParaclient);
            contextInfo.fscbk.cbkgen.pfnTransferDisplayInfo = new PTS.TransferDisplayInfo(ptsHost.TransferDisplayInfo);
            contextInfo.fscbk.cbkgen.pfnDestroyParaclient = new PTS.DestroyParaclient(ptsHost.DestroyParaclient);
            contextInfo.fscbk.cbkgen.pfnFInterruptFormattingAfterPara = new PTS.FInterruptFormattingAfterPara(ptsHost.FInterruptFormattingAfterPara);
            contextInfo.fscbk.cbkgen.pfnGetEndnoteSeparators = new PTS.GetEndnoteSeparators(ptsHost.GetEndnoteSeparators);
            contextInfo.fscbk.cbkgen.pfnGetEndnoteSegment = new PTS.GetEndnoteSegment(ptsHost.GetEndnoteSegment);
            contextInfo.fscbk.cbkgen.pfnGetNumberEndnoteColumns = new PTS.GetNumberEndnoteColumns(ptsHost.GetNumberEndnoteColumns);
            contextInfo.fscbk.cbkgen.pfnGetEndnoteColumnInfo = new PTS.GetEndnoteColumnInfo(ptsHost.GetEndnoteColumnInfo);
            contextInfo.fscbk.cbkgen.pfnGetFootnoteSeparators = new PTS.GetFootnoteSeparators(ptsHost.GetFootnoteSeparators);
            contextInfo.fscbk.cbkgen.pfnFFootnoteBeneathText = new PTS.FFootnoteBeneathText(ptsHost.FFootnoteBeneathText);
            contextInfo.fscbk.cbkgen.pfnGetNumberFootnoteColumns = new PTS.GetNumberFootnoteColumns(ptsHost.GetNumberFootnoteColumns);
            contextInfo.fscbk.cbkgen.pfnGetFootnoteColumnInfo = new PTS.GetFootnoteColumnInfo(ptsHost.GetFootnoteColumnInfo);
            contextInfo.fscbk.cbkgen.pfnGetFootnoteSegment = new PTS.GetFootnoteSegment(ptsHost.GetFootnoteSegment);
            contextInfo.fscbk.cbkgen.pfnGetFootnotePresentationAndRejectionOrder = new PTS.GetFootnotePresentationAndRejectionOrder(ptsHost.GetFootnotePresentationAndRejectionOrder);
            contextInfo.fscbk.cbkgen.pfnFAllowFootnoteSeparation = new PTS.FAllowFootnoteSeparation(ptsHost.FAllowFootnoteSeparation);
            //Initialize object callbacks
            //contextInfo.fscbk.cbkobj.pfnNewPtr                Handled by PTSWrapper
            //contextInfo.fscbk.cbkobj.pfnDisposePtr            Handled by PTSWrapper
            //contextInfo.fscbk.cbkobj.pfnReallocPtr            Handled by PTSWrapper
            contextInfo.fscbk.cbkobj.pfnDuplicateMcsclient = new PTS.DuplicateMcsclient(ptsHost.DuplicateMcsclient);
            contextInfo.fscbk.cbkobj.pfnDestroyMcsclient = new PTS.DestroyMcsclient(ptsHost.DestroyMcsclient);
            contextInfo.fscbk.cbkobj.pfnFEqualMcsclient = new PTS.FEqualMcsclient(ptsHost.FEqualMcsclient);
            contextInfo.fscbk.cbkobj.pfnConvertMcsclient = new PTS.ConvertMcsclient(ptsHost.ConvertMcsclient);
            contextInfo.fscbk.cbkobj.pfnGetObjectHandlerInfo = new PTS.GetObjectHandlerInfo(ptsHost.GetObjectHandlerInfo);
            // Initialize text callbacks
            contextInfo.fscbk.cbktxt.pfnCreateParaBreakingSession = new PTS.CreateParaBreakingSession(ptsHost.CreateParaBreakingSession);
            contextInfo.fscbk.cbktxt.pfnDestroyParaBreakingSession = new PTS.DestroyParaBreakingSession(ptsHost.DestroyParaBreakingSession);
            contextInfo.fscbk.cbktxt.pfnGetTextProperties = new PTS.GetTextProperties(ptsHost.GetTextProperties);
            contextInfo.fscbk.cbktxt.pfnGetNumberFootnotes = new PTS.GetNumberFootnotes(ptsHost.GetNumberFootnotes);
            contextInfo.fscbk.cbktxt.pfnGetFootnotes = new PTS.GetFootnotes(ptsHost.GetFootnotes);
            contextInfo.fscbk.cbktxt.pfnFormatDropCap = new PTS.FormatDropCap(ptsHost.FormatDropCap);
            contextInfo.fscbk.cbktxt.pfnGetDropCapPolygons = new PTS.GetDropCapPolygons(ptsHost.GetDropCapPolygons);
            contextInfo.fscbk.cbktxt.pfnDestroyDropCap = new PTS.DestroyDropCap(ptsHost.DestroyDropCap);
            contextInfo.fscbk.cbktxt.pfnFormatBottomText = new PTS.FormatBottomText(ptsHost.FormatBottomText);
            contextInfo.fscbk.cbktxt.pfnFormatLine = new PTS.FormatLine(ptsHost.FormatLine);
            contextInfo.fscbk.cbktxt.pfnFormatLineForced = new PTS.FormatLineForced(ptsHost.FormatLineForced);
            contextInfo.fscbk.cbktxt.pfnFormatLineVariants = new PTS.FormatLineVariants(ptsHost.FormatLineVariants);
            contextInfo.fscbk.cbktxt.pfnReconstructLineVariant = new PTS.ReconstructLineVariant(ptsHost.ReconstructLineVariant);
            contextInfo.fscbk.cbktxt.pfnDestroyLine = new PTS.DestroyLine(ptsHost.DestroyLine);
            contextInfo.fscbk.cbktxt.pfnDuplicateLineBreakRecord = new PTS.DuplicateLineBreakRecord(ptsHost.DuplicateLineBreakRecord);
            contextInfo.fscbk.cbktxt.pfnDestroyLineBreakRecord = new PTS.DestroyLineBreakRecord(ptsHost.DestroyLineBreakRecord);
            contextInfo.fscbk.cbktxt.pfnSnapGridVertical = new PTS.SnapGridVertical(ptsHost.SnapGridVertical);
            contextInfo.fscbk.cbktxt.pfnGetDvrSuppressibleBottomSpace = new PTS.GetDvrSuppressibleBottomSpace(ptsHost.GetDvrSuppressibleBottomSpace);
            contextInfo.fscbk.cbktxt.pfnGetDvrAdvance = new PTS.GetDvrAdvance(ptsHost.GetDvrAdvance);
            contextInfo.fscbk.cbktxt.pfnUpdGetChangeInText = new PTS.UpdGetChangeInText(ptsHost.UpdGetChangeInText);
            contextInfo.fscbk.cbktxt.pfnUpdGetDropCapChange = new PTS.UpdGetDropCapChange(ptsHost.UpdGetDropCapChange);
            contextInfo.fscbk.cbktxt.pfnFInterruptFormattingText = new PTS.FInterruptFormattingText(ptsHost.FInterruptFormattingText);
            contextInfo.fscbk.cbktxt.pfnGetTextParaCache = new PTS.GetTextParaCache(ptsHost.GetTextParaCache);
            contextInfo.fscbk.cbktxt.pfnSetTextParaCache = new PTS.SetTextParaCache(ptsHost.SetTextParaCache);
            contextInfo.fscbk.cbktxt.pfnGetOptimalLineDcpCache = new PTS.GetOptimalLineDcpCache(ptsHost.GetOptimalLineDcpCache);
            contextInfo.fscbk.cbktxt.pfnGetNumberAttachedObjectsBeforeTextLine = new PTS.GetNumberAttachedObjectsBeforeTextLine(ptsHost.GetNumberAttachedObjectsBeforeTextLine);
            contextInfo.fscbk.cbktxt.pfnGetAttachedObjectsBeforeTextLine = new PTS.GetAttachedObjectsBeforeTextLine(ptsHost.GetAttachedObjectsBeforeTextLine);
            contextInfo.fscbk.cbktxt.pfnGetNumberAttachedObjectsInTextLine = new PTS.GetNumberAttachedObjectsInTextLine(ptsHost.GetNumberAttachedObjectsInTextLine);
            contextInfo.fscbk.cbktxt.pfnGetAttachedObjectsInTextLine = new PTS.GetAttachedObjectsInTextLine(ptsHost.GetAttachedObjectsInTextLine);
            contextInfo.fscbk.cbktxt.pfnUpdGetAttachedObjectChange = new PTS.UpdGetAttachedObjectChange(ptsHost.UpdGetAttachedObjectChange);
            contextInfo.fscbk.cbktxt.pfnGetDurFigureAnchor = new PTS.GetDurFigureAnchor(ptsHost.GetDurFigureAnchor);
        }

        /// <summary>
        /// Initializes formatting callbacks for PTS Installed objects.
        /// </summary>
        /// <param name="ptsHost">PtsHost that defines all PTS callbacks.</param>
        /// <param name="subtrackParaInfo">Subtrack formatting callbacks.</param>
        /// <param name="subpageParaInfo">Subpage formatting callbacks.</param>
        /// <param name="installedObjects">PTS Installed objects.</param>
        /// <param name="installedObjectsCount">Count of PTS Installed objects.</param>
        private unsafe void InitInstalledObjectsInfo(PtsHost ptsHost, ref PTS.FSIMETHODS subtrackParaInfo, ref PTS.FSIMETHODS subpageParaInfo, out IntPtr installedObjects, out int installedObjectsCount)
        {
            // Initialize subtrack para info
            subtrackParaInfo.pfnCreateContext = new PTS.ObjCreateContext(ptsHost.SubtrackCreateContext);
            subtrackParaInfo.pfnDestroyContext = new PTS.ObjDestroyContext(ptsHost.SubtrackDestroyContext);
            subtrackParaInfo.pfnFormatParaFinite = new PTS.ObjFormatParaFinite(ptsHost.SubtrackFormatParaFinite);
            subtrackParaInfo.pfnFormatParaBottomless = new PTS.ObjFormatParaBottomless(ptsHost.SubtrackFormatParaBottomless);
            subtrackParaInfo.pfnUpdateBottomlessPara = new PTS.ObjUpdateBottomlessPara(ptsHost.SubtrackUpdateBottomlessPara);
            subtrackParaInfo.pfnSynchronizeBottomlessPara = new PTS.ObjSynchronizeBottomlessPara(ptsHost.SubtrackSynchronizeBottomlessPara);
            subtrackParaInfo.pfnComparePara = new PTS.ObjComparePara(ptsHost.SubtrackComparePara);
            subtrackParaInfo.pfnClearUpdateInfoInPara = new PTS.ObjClearUpdateInfoInPara(ptsHost.SubtrackClearUpdateInfoInPara);
            subtrackParaInfo.pfnDestroyPara = new PTS.ObjDestroyPara(ptsHost.SubtrackDestroyPara);
            subtrackParaInfo.pfnDuplicateBreakRecord = new PTS.ObjDuplicateBreakRecord(ptsHost.SubtrackDuplicateBreakRecord);
            subtrackParaInfo.pfnDestroyBreakRecord = new PTS.ObjDestroyBreakRecord(ptsHost.SubtrackDestroyBreakRecord);
            subtrackParaInfo.pfnGetColumnBalancingInfo = new PTS.ObjGetColumnBalancingInfo(ptsHost.SubtrackGetColumnBalancingInfo);
            subtrackParaInfo.pfnGetNumberFootnotes = new PTS.ObjGetNumberFootnotes(ptsHost.SubtrackGetNumberFootnotes);
            subtrackParaInfo.pfnGetFootnoteInfo = new PTS.ObjGetFootnoteInfo(ptsHost.SubtrackGetFootnoteInfo);
            subtrackParaInfo.pfnGetFootnoteInfoWord = IntPtr.Zero;
            subtrackParaInfo.pfnShiftVertical = new PTS.ObjShiftVertical(ptsHost.SubtrackShiftVertical);
            subtrackParaInfo.pfnTransferDisplayInfoPara = new PTS.ObjTransferDisplayInfoPara(ptsHost.SubtrackTransferDisplayInfoPara);

            // Initialize subpage para info
            subpageParaInfo.pfnCreateContext = new PTS.ObjCreateContext(ptsHost.SubpageCreateContext);
            subpageParaInfo.pfnDestroyContext = new PTS.ObjDestroyContext(ptsHost.SubpageDestroyContext);
            subpageParaInfo.pfnFormatParaFinite = new PTS.ObjFormatParaFinite(ptsHost.SubpageFormatParaFinite);
            subpageParaInfo.pfnFormatParaBottomless = new PTS.ObjFormatParaBottomless(ptsHost.SubpageFormatParaBottomless);
            subpageParaInfo.pfnUpdateBottomlessPara = new PTS.ObjUpdateBottomlessPara(ptsHost.SubpageUpdateBottomlessPara);
            subpageParaInfo.pfnSynchronizeBottomlessPara = new PTS.ObjSynchronizeBottomlessPara(ptsHost.SubpageSynchronizeBottomlessPara);
            subpageParaInfo.pfnComparePara = new PTS.ObjComparePara(ptsHost.SubpageComparePara);
            subpageParaInfo.pfnClearUpdateInfoInPara = new PTS.ObjClearUpdateInfoInPara(ptsHost.SubpageClearUpdateInfoInPara);
            subpageParaInfo.pfnDestroyPara = new PTS.ObjDestroyPara(ptsHost.SubpageDestroyPara);
            subpageParaInfo.pfnDuplicateBreakRecord = new PTS.ObjDuplicateBreakRecord(ptsHost.SubpageDuplicateBreakRecord);
            subpageParaInfo.pfnDestroyBreakRecord = new PTS.ObjDestroyBreakRecord(ptsHost.SubpageDestroyBreakRecord);
            subpageParaInfo.pfnGetColumnBalancingInfo = new PTS.ObjGetColumnBalancingInfo(ptsHost.SubpageGetColumnBalancingInfo);
            subpageParaInfo.pfnGetNumberFootnotes = new PTS.ObjGetNumberFootnotes(ptsHost.SubpageGetNumberFootnotes);
            subpageParaInfo.pfnGetFootnoteInfo = new PTS.ObjGetFootnoteInfo(ptsHost.SubpageGetFootnoteInfo);
            subpageParaInfo.pfnShiftVertical = new PTS.ObjShiftVertical(ptsHost.SubpageShiftVertical);
            subpageParaInfo.pfnTransferDisplayInfoPara = new PTS.ObjTransferDisplayInfoPara(ptsHost.SubpageTransferDisplayInfoPara);

            // Create installed objects info
            PTS.Validate(PTS.CreateInstalledObjectsInfo(ref subtrackParaInfo, ref subpageParaInfo, out installedObjects, out installedObjectsCount));
        }

        /// <summary>
        /// Initializes floater formatting callbacks.
        /// </summary>
        /// <param name="ptsHost">PtsHost that defines all PTS callbacks.</param>
        /// <param name="floaterInit">Floater formatting callbacks.</param>
        private unsafe void InitFloaterObjInfo(PtsHost ptsHost, ref PTS.FSFLOATERINIT floaterInit)
        {
            floaterInit.fsfloatercbk.pfnGetFloaterProperties = new PTS.GetFloaterProperties(ptsHost.GetFloaterProperties);
            floaterInit.fsfloatercbk.pfnFormatFloaterContentFinite = new PTS.FormatFloaterContentFinite(ptsHost.FormatFloaterContentFinite);
            floaterInit.fsfloatercbk.pfnFormatFloaterContentBottomless = new PTS.FormatFloaterContentBottomless(ptsHost.FormatFloaterContentBottomless);
            floaterInit.fsfloatercbk.pfnUpdateBottomlessFloaterContent = new PTS.UpdateBottomlessFloaterContent(ptsHost.UpdateBottomlessFloaterContent);
            floaterInit.fsfloatercbk.pfnGetFloaterPolygons = new PTS.GetFloaterPolygons(ptsHost.GetFloaterPolygons);
            floaterInit.fsfloatercbk.pfnClearUpdateInfoInFloaterContent = new PTS.ClearUpdateInfoInFloaterContent(ptsHost.ClearUpdateInfoInFloaterContent);
            floaterInit.fsfloatercbk.pfnCompareFloaterContents = new PTS.CompareFloaterContents(ptsHost.CompareFloaterContents);
            floaterInit.fsfloatercbk.pfnDestroyFloaterContent = new PTS.DestroyFloaterContent(ptsHost.DestroyFloaterContent);
            floaterInit.fsfloatercbk.pfnDuplicateFloaterContentBreakRecord = new PTS.DuplicateFloaterContentBreakRecord(ptsHost.DuplicateFloaterContentBreakRecord);
            floaterInit.fsfloatercbk.pfnDestroyFloaterContentBreakRecord = new PTS.DestroyFloaterContentBreakRecord(ptsHost.DestroyFloaterContentBreakRecord);
            floaterInit.fsfloatercbk.pfnGetFloaterContentColumnBalancingInfo = new PTS.GetFloaterContentColumnBalancingInfo(ptsHost.GetFloaterContentColumnBalancingInfo);
            floaterInit.fsfloatercbk.pfnGetFloaterContentNumberFootnotes = new PTS.GetFloaterContentNumberFootnotes(ptsHost.GetFloaterContentNumberFootnotes);
            floaterInit.fsfloatercbk.pfnGetFloaterContentFootnoteInfo = new PTS.GetFloaterContentFootnoteInfo(ptsHost.GetFloaterContentFootnoteInfo);
            floaterInit.fsfloatercbk.pfnTransferDisplayInfoInFloaterContent = new PTS.TransferDisplayInfoInFloaterContent(ptsHost.TransferDisplayInfoInFloaterContent);
            floaterInit.fsfloatercbk.pfnGetMCSClientAfterFloater = new PTS.GetMCSClientAfterFloater(ptsHost.GetMCSClientAfterFloater);
            floaterInit.fsfloatercbk.pfnGetDvrUsedForFloater = new PTS.GetDvrUsedForFloater(ptsHost.GetDvrUsedForFloater);
        }

        /// <summary>
        /// Initializes table formatting callbacks.
        /// </summary>
        /// <param name="ptsHost">PtsHost that defines all PTS callbacks.</param>
        /// <param name="tableobjInit">Table formatting callbacks.</param>
        private unsafe void InitTableObjInfo(PtsHost ptsHost, ref PTS.FSTABLEOBJINIT tableobjInit)
        {
            // FSTABLEOBJCBK
            tableobjInit.tableobjcbk.pfnGetTableProperties = new PTS.GetTableProperties(ptsHost.GetTableProperties);
            tableobjInit.tableobjcbk.pfnAutofitTable = new PTS.AutofitTable(ptsHost.AutofitTable);
            tableobjInit.tableobjcbk.pfnUpdAutofitTable = new PTS.UpdAutofitTable(ptsHost.UpdAutofitTable);
            tableobjInit.tableobjcbk.pfnGetMCSClientAfterTable = new PTS.GetMCSClientAfterTable(ptsHost.GetMCSClientAfterTable);
            tableobjInit.tableobjcbk.pfnGetDvrUsedForFloatTable = IntPtr.Zero;

            // FSTABLECBKFETCH
            tableobjInit.tablecbkfetch.pfnGetFirstHeaderRow = new PTS.GetFirstHeaderRow(ptsHost.GetFirstHeaderRow);
            tableobjInit.tablecbkfetch.pfnGetNextHeaderRow = new PTS.GetNextHeaderRow(ptsHost.GetNextHeaderRow);
            tableobjInit.tablecbkfetch.pfnGetFirstFooterRow = new PTS.GetFirstFooterRow(ptsHost.GetFirstFooterRow);
            tableobjInit.tablecbkfetch.pfnGetNextFooterRow = new PTS.GetNextFooterRow(ptsHost.GetNextFooterRow);
            tableobjInit.tablecbkfetch.pfnGetFirstRow = new PTS.GetFirstRow(ptsHost.GetFirstRow);
            tableobjInit.tablecbkfetch.pfnGetNextRow = new PTS.GetNextRow(ptsHost.GetNextRow);
            tableobjInit.tablecbkfetch.pfnUpdFChangeInHeaderFooter = new PTS.UpdFChangeInHeaderFooter(ptsHost.UpdFChangeInHeaderFooter);
            tableobjInit.tablecbkfetch.pfnUpdGetFirstChangeInTable = new PTS.UpdGetFirstChangeInTable(ptsHost.UpdGetFirstChangeInTable);
            tableobjInit.tablecbkfetch.pfnUpdGetRowChange = new PTS.UpdGetRowChange(ptsHost.UpdGetRowChange);
            tableobjInit.tablecbkfetch.pfnUpdGetCellChange = new PTS.UpdGetCellChange(ptsHost.UpdGetCellChange);
            tableobjInit.tablecbkfetch.pfnGetDistributionKind = new PTS.GetDistributionKind(ptsHost.GetDistributionKind);
            tableobjInit.tablecbkfetch.pfnGetRowProperties = new PTS.GetRowProperties(ptsHost.GetRowProperties);
            tableobjInit.tablecbkfetch.pfnGetCells = new PTS.GetCells(ptsHost.GetCells);
            tableobjInit.tablecbkfetch.pfnFInterruptFormattingTable = new PTS.FInterruptFormattingTable(ptsHost.FInterruptFormattingTable);
            tableobjInit.tablecbkfetch.pfnCalcHorizontalBBoxOfRow = new PTS.CalcHorizontalBBoxOfRow(ptsHost.CalcHorizontalBBoxOfRow);

            // FSTABLECBKCELL
            tableobjInit.tablecbkcell.pfnFormatCellFinite = new PTS.FormatCellFinite(ptsHost.FormatCellFinite);
            tableobjInit.tablecbkcell.pfnFormatCellBottomless = new PTS.FormatCellBottomless(ptsHost.FormatCellBottomless);
            tableobjInit.tablecbkcell.pfnUpdateBottomlessCell = new PTS.UpdateBottomlessCell(ptsHost.UpdateBottomlessCell);
            tableobjInit.tablecbkcell.pfnCompareCells = new PTS.CompareCells(ptsHost.CompareCells);
            tableobjInit.tablecbkcell.pfnClearUpdateInfoInCell = new PTS.ClearUpdateInfoInCell(ptsHost.ClearUpdateInfoInCell);
            tableobjInit.tablecbkcell.pfnSetCellHeight = new PTS.SetCellHeight(ptsHost.SetCellHeight);
            tableobjInit.tablecbkcell.pfnDestroyCell = new PTS.DestroyCell(ptsHost.DestroyCell);
            tableobjInit.tablecbkcell.pfnDuplicateCellBreakRecord = new PTS.DuplicateCellBreakRecord(ptsHost.DuplicateCellBreakRecord);
            tableobjInit.tablecbkcell.pfnDestroyCellBreakRecord = new PTS.DestroyCellBreakRecord(ptsHost.DestroyCellBreakRecord);
            tableobjInit.tablecbkcell.pfnGetCellNumberFootnotes = new PTS.GetCellNumberFootnotes(ptsHost.GetCellNumberFootnotes);
            tableobjInit.tablecbkcell.pfnGetCellFootnoteInfo = IntPtr.Zero;
            tableobjInit.tablecbkcell.pfnGetCellFootnoteInfoWord = IntPtr.Zero;
            tableobjInit.tablecbkcell.pfnGetCellMinColumnBalancingStep = new PTS.GetCellMinColumnBalancingStep(ptsHost.GetCellMinColumnBalancingStep);
            tableobjInit.tablecbkcell.pfnTransferDisplayInfoCell = new PTS.TransferDisplayInfoCell(ptsHost.TransferDisplayInfoCell);

            /*
            // FSTABLECBKFETCHWORD -- lepfnDuplicateCellBreakRecord;gacy =)
            tableobjInit.tablecbkfetchword.pfnGetTablePropertiesWord  = IntPtr.Zero;
            tableobjInit.tablecbkfetchword.pfnGetRowPropertiesWord    = IntPtr.Zero;
            tableobjInit.tablecbkfetchword.pfnGetNumberFiguresForTableRow = IntPtr.Zero;
            tableobjInit.tablecbkfetchword.pfnGetRowWidthWord = IntPtr.Zero;
            tableobjInit.tablecbkfetchword.pfnGetFiguresForTableRow   = IntPtr.Zero;
            tableobjInit.tablecbkfetchword.pfnFStopBeforeTableRowLr   = IntPtr.Zero;
            tableobjInit.tablecbkfetchword.pfnFIgnoreCollisionForTableRow = IntPtr.Zero;
            tableobjInit.tablecbkfetchword.pfnChangeRowHeightRestriction = IntPtr.Zero;
            */
        }

        #endregion Private Methods

        //-------------------------------------------------------------------
        //
        //  Private Fields
        //
        //-------------------------------------------------------------------

        #region Private Fields

        /// <summary>
        /// For each Dispatcher separate PTS context pool is created.
        /// This enables usage from different Dispatchers at the same time.
        /// When Dispatcher is disposed, all associated resources stored in its
        /// PTS context pool are disposed as well.
        /// </summary>
        /// <remarks>
        /// PTS context pool is an array of PTS Context descriptors.
        /// PTS Context is very expensive to create, so once it is created, it
        /// is stored and might be reused. Particular PTS Context is in use,
        /// when WeakReference points to actual object. Otherwise it is free.
        /// </remarks>
        private List<ContextDesc> _contextPool;

        // ==================================================================
        //  W86A `A2`（`D-G78`）：**具名能力闩**
        //  null = "还没失败过"；非 null = "PTS 能力在本进程内已判定不可用"。
        //  只由 AcquireContextCore 的 catch 置位、只被同一个方法的入口读
        //  ⇒ 作用域**刻意收窄**：它**不是**兜底 catch-all，**不**覆盖任何别的失败族
        //    （判据见 `WpfLinuxPtsGap.IsPtsUnavailable`：必须由 native 台账亲口作证）。
        // ==================================================================
        private PtsUnavailableException _ptsUnavailable;

        /// <summary>
        /// Collection of PtsContext ready for disposal.
        /// </summary>
        private List<PtsContext> _releaseQueue;

        /// <summary>
        /// Lock.
        /// </summary>
        private readonly object _lock = new object();

        /// <summary>
        /// Whether object is already disposed.
        /// </summary>
        private bool _disposed;

        #endregion Private Fields

        //-------------------------------------------------------------------
        //
        //  Private Types
        //
        //-------------------------------------------------------------------

        #region Private Types

        /// <summary>
        /// Single item in PTS Context array. It stores created PTS Context
        /// together with its current owner.
        /// PTS Context is in use, when Owner points to actual object.
        /// Otherwise it is free and may be reused.
        /// Created PTS Context is not destroyed, because creation process is
        /// expensive.
        /// </summary>
        private class ContextDesc
        {
            internal PtsHost PtsHost;
            internal PTS.FSCONTEXTINFO ContextInfo;
            internal PTS.FSIMETHODS SubtrackParaInfo;
            internal PTS.FSIMETHODS SubpageParaInfo;
            internal PTS.FSFLOATERINIT FloaterInit;
            internal PTS.FSTABLEOBJINIT TableobjInit;
            internal IntPtr InstalledObjects;
            internal TextFormatter TextFormatter;
            internal TextPenaltyModule TextPenaltyModule;
            internal bool IsOptimalParagraphEnabled;
            internal WeakReference Owner;
            internal bool InUse;
        }

        private sealed class PtsCacheShutDownListener : ShutDownListener
        {
            public PtsCacheShutDownListener(PtsCache target) : base(target)
            {
            }

            internal override void OnShutDown(object target, object sender, EventArgs e)
            {
                PtsCache ptsCache = (PtsCache)target;
                ptsCache.Shutdown();
            }
        }

        #endregion Private Types
    }

    /// <summary>
    /// W86A（`TASK-0304`/`TASK-0305`）：**PTS 能力不可用**的具名异常。
    ///
    /// 【为什么需要一个新类型】上游把"PTS 建不起来"表达成好几种形态：
    ///   `EntryPointNotFoundException`（今天：符号根本不在 shim 里）、`DllNotFoundException`、
    ///   以及 A1 落地后的私有嵌套类型 `PTS.PtsException`（非零 `LsErr` ⇒ `PTS.Validate` 抛）。
    /// 其中 `PtsException` 是**上游的 private 嵌套类**（`Pts.cs:299`）⇒ 本工程**无法按类型引用它**。
    /// 于是今天**没有任何调用方**能只按类型说"这一页不支持"，只能去匹配消息串（本仓最忌讳）。
    /// 本类型把那个条件**命名**：谁接住 `PtsUnavailableException`，谁就是在处理"PTS 缺口"。
    /// </summary>
    internal sealed class PtsUnavailableException : Exception
    {
        internal PtsUnavailableException(string entry, int errorCode, string message, Exception inner)
            : base(message, inner)
        {
            Entry = entry;
            ErrorCode = errorCode;
        }

        /// <summary>缺口入口名（来自 native 侧的具名台账；取不到时是 "unknown"）。</summary>
        internal string Entry { get; }

        /// <summary>native 交回的 LsErr（A1 的 stub 恒为 -10000 = `tserrNotImplemented`）。</summary>
        internal int ErrorCode { get; }
    }

    /// <summary>
    /// W86A：把 native 侧的**具名缺口台账**接进托管侧的两条判据。
    /// 只做三件事：① 判"这次失败是不是 PTS 缺口"；② 把缺口**具名**；③ 打具名行。
    /// ⚠️ 它**不**决定任何降级动作，也**不**吞异常。
    ///
    /// 【判据为什么不是"异常类型表"】A1 落地后真正的异常是 `PTS.PtsException`（private 嵌套类，
    /// 引用不到）。所以判据改成**native 自己作证**：
    ///   `WpfLinuxWin32_PtsGapCalls()` 是 native 侧的**累计入口调用数**（`win32_pts.c` 的 `g_pts_seq`）。
    ///   在 `CreatePTSContext` 之前取一次快照、在 catch 里再取一次：
    ///     **涨了** ⟺ 这一次尝试真的走到过那 6 个入口 ⟺ 缺口是**原生侧亲口说的**
    ///   （不是我们猜的）。没涨 ⇒ 这个异常**与 PTS 缺口无关** ⇒ 不立闩、不改名、原样传播。
    ///   ⚠️ 旧 shim（没有这两个导出）下本函数返回 0 ⇒ 判据退化成"只认那三个 DllImport 异常族"，
    ///      而那时真正的失败恰好就是 `EntryPointNotFoundException` ⇒ 照样命中（不依赖新 shim）。
    /// </summary>
    internal static class WpfLinuxPtsGap
    {
        // ── 与 native 侧同名同形（`src/WpfGfx.Linux.Native/src/win32_pts.c`）──────────
        // `int WpfLinuxWin32_PtsGapCalls(void);`
        // `int WpfLinuxWin32_PtsGapReport(char *buf, int cap);` —— 写一行机读摘要，返回长度。
        // ⚠️ 形参用 `byte[]`（blittable）：**不用 Marshal**，也就不需要额外的 using；
        //    并且**每一次调用都包在 try 里** —— 旧 shim 没有这些导出 ⇒ `EntryPointNotFoundException`，
        //    绝不能让它盖掉真正的失败（"具名"是锦上添花，不是判据的前提）。
        [DllImport(DllImport.PresentationNative, EntryPoint = "WpfLinuxWin32_PtsGapCalls", ExactSpelling = true)]
        private static extern int PtsGapCallsNative();

        [DllImport(DllImport.PresentationNative, EntryPoint = "WpfLinuxWin32_PtsGapReport",
                   CharSet = CharSet.Ansi, ExactSpelling = true)]
        private static extern int PtsGapReportNative([Out] byte[] buf, int cap);

        /// <summary>native 侧累计入口调用数（快照用）。取不到 ⇒ 0。</summary>
        internal static int NativeCalls()
        {
            try { return PtsGapCallsNative(); }
            catch (Exception) { return 0; }
        }

        /// <summary>native 台账里"最近一条缺口"的入口名；取不到 ⇒ "unknown"（**不抛**）。</summary>
        private static string NativeEntryName()
        {
            string s = NativeReport();
            int i = s.IndexOf("last=", StringComparison.Ordinal);
            if (i < 0) return "unknown";
            i += 5;
            int j = s.IndexOf(' ', i);
            string name = (j < 0) ? s.Substring(i) : s.Substring(i, j - i);
            return string.IsNullOrEmpty(name) || name == "-" ? "unknown" : name;
        }

        /// <summary>native 台账里最近一条缺口的 LsErr；取不到 ⇒ A1 的常量。</summary>
        private static int NativeError()
        {
            string s = NativeReport();
            int i = s.IndexOf("err=", StringComparison.Ordinal);
            if (i < 0) return A1_STUB_ERR;
            i += 4;
            int j = i;
            if (j < s.Length && (s[j] == '-' || s[j] == '+')) j++;
            while (j < s.Length && s[j] >= '0' && s[j] <= '9') j++;
            return (j > i + 1) && int.TryParse(s.Substring(i, j - i), out int v) ? v : A1_STUB_ERR;
        }

        private static string NativeReport()
        {
            try
            {
                byte[] buf = new byte[256];
                if (PtsGapReportNative(buf, buf.Length) <= 0) return string.Empty;
                int n = 0;
                while (n < buf.Length && buf[n] != 0) n++;
                char[] c = new char[n];
                for (int k = 0; k < n; k++) c[k] = (char)buf[k];
                return new string(c);
            }
            catch (Exception) { return string.Empty; }
        }

        /// <summary>判：这次失败是不是"PTS 能力不可用"（**闭集**：DllImport 三族 ∪ native 亲口作证）。</summary>
        internal static bool IsPtsUnavailable(Exception e, int nativeCallsBefore)
        {
            if (e is EntryPointNotFoundException          // 符号不在 shim 里（A1 之前 / 旧 shim）
                || e is DllNotFoundException              // shim 整个没找到
                || e is BadImageFormatException)          // shim 不是可装载的 ELF
            {
                return true;
            }
            // native 侧的累计入口调用数**涨了** ⇒ 这一次尝试真的问过 PTS 上下文族
            return NativeCalls() > nativeCallsBefore;
        }

        // A1 的 stub 唯一取值（= 上游 `Pts.cs:507` `tserrNotImplemented`）
        private const int A1_STUB_ERR = -10000;

        /// <summary>把失败**具名**（入口名/错误码来自 native 台账；读不到就如实写 unknown）。</summary>
        internal static PtsUnavailableException Describe(Exception e)
        {
            string entry = NativeEntryName();
            int err = NativeError();
            string msg = "PTS 能力不可用（PTS / 原生 LineServices 未实现 —— D-G70）：entry=" + entry
                       + " err=" + err.ToString("0")
                       + " ⇒ 本次布局**如实失败**，不假装成功";
            return new PtsUnavailableException(entry, err, msg, e);
        }
    }

    /// <summary>
    /// W86A `A3`：把"这一页不支持"打到日志（**不许静默**）。一行、每个视图一次、带入口名。
    /// </summary>
    internal static class WpfLinuxPtsGapTrace
    {
        internal static void Report(string site, PtsUnavailableException e)
        {
            try
            {
                System.Console.Error.WriteLine(
                    "[PTS-UNAVAILABLE] site=" + site + " entry=" + (e.Entry ?? "unknown")
                    + " err=" + e.ErrorCode.ToString("0")
                    + " action=page-placeholder（已画出页级占位；进程继续）");
                System.Console.Error.Flush();
            }
            catch (Exception)
            {
                // 打印失败不许改变行为（例如 stderr 已关闭）。
            }
        }
    }
}
