// ⚠️ 本文件由 build/PresentationFramework.Linux/reapply-patches.py **生成**，不要手改。
//
// 内容 = 上游 `upstream/wpf/src/Microsoft.DotNet.Wpf/src/PresentationFramework/MS/Internal/documents/DocumentPageHost.cs` 逐字复制 + 4 处 W86A（`TASK-0304`/`TASK-0305`）改动。
// 每次运行该脚本都会从上游重读重生成；needle 找不到 / 命中数不符时**报错退出**
// （不会静默产出未打补丁的副本）。改动逐处见：
//   E1 ／ E2 ／ E3 ／ E4
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

//
// Description: Provides a view port for a page of content for a DocumentPage.
//

using System.Windows;           // UIElement
using System.Windows.Media;     // Visual

namespace MS.Internal.Documents
{
    /// <summary> 
    /// Provides a view port for a page of content for a DocumentPage.
    /// </summary>
    internal class DocumentPageHost : FrameworkElement
    {
        //-------------------------------------------------------------------
        //
        //  Constructors
        //
        //-------------------------------------------------------------------

        #region Constructors

        /// <summary> 
        /// Create an instance of a DocumentPageHost.
        /// </summary>
        internal DocumentPageHost()
            : base()
        {
        }

        #endregion Constructors

        //-------------------------------------------------------------------
        //
        //  Internal Methods
        //
        //-------------------------------------------------------------------

        #region Internal Methods

        internal static void DisconnectPageVisual(Visual pageVisual)
        {
            // There might be a case where a visual associated with a page was 
            // inserted to a visual tree before. It got removed later, but GC did not
            // destroy its parent yet. To workaround this case always check for the parent
            // of page visual and disconnect it, when necessary.
            Visual currentParent = VisualTreeHelper.GetParent(pageVisual) as Visual;
            if (currentParent != null)
            {
                // ── `T-B11`（`PAGEVIEW-ONSCREEN`）：直接挂载形态下，页视觉的父**就是**宿主 ──────
                //  打开驱动时 `PageVisual` setter 把页视觉**本身**挂到宿主（照 `FlowDocumentView`
                //  范式，不经 `ContainerVisual` 包壳）⇒ 必须先认这一形态，否则下游
                //  `currentParent as ContainerVisual == null` 会误判成"父不是 DocumentPageHost"
                //  而**响亮抛错**（那是一处**新缺陷**，不是本增量要的）。关 ⇒ 逐字回上游。
                DocumentPageHost directHost = currentParent as DocumentPageHost;
                if (directHost != null)
                {
                    directHost.PageVisual = null;
                    return;
                }
                ContainerVisual pageVisualHost = currentParent as ContainerVisual;
                if (pageVisualHost == null)
                    throw new ArgumentException(SR.DocumentPageView_ParentNotDocumentPageHost, nameof(pageVisual));
                DocumentPageHost docPageHost = VisualTreeHelper.GetParent(pageVisualHost) as DocumentPageHost;
                if (docPageHost == null)
                    throw new ArgumentException(SR.DocumentPageView_ParentNotDocumentPageHost, nameof(pageVisual));
                docPageHost.PageVisual = null;
            }
        }

        #endregion Internal Methods

        //-------------------------------------------------------------------
        //
        //  Internal Properties
        //
        //-------------------------------------------------------------------

        #region Internal Properties

        /// <summary>
        /// Root of visual subtree hosted by this DocumentPageHost.
        /// </summary>
        internal Visual PageVisual
        {
            get
            {
                return _pageVisual;
            }
            set
            {
                ContainerVisual pageVisualHost;
                // ── `T-B11`（`PAGEVIEW-ONSCREEN`）：照 `FlowDocumentView` 范式挂载页视觉 ──────────
                //  `FlowDocumentView` 那条**可用**接线是"宿主**自己**把页视觉对象 `AddVisualChild`
                //  进自己的视觉树 ＋ 显式定位"（`FlowDocumentView.Linux.cs:247-254`），**不**经内层
                //  元素的隐式 `Measure/Arrange`。上游 `DocumentPageHost` 则是把页视觉塞进一个
                //  **新建的 `ContainerVisual` 包壳**、再把包壳 `AddVisualChild`（`:95-98`）。
                //  两种形态在**本移植的成帧面上不等价**：现取（腿 `b11visit`）渲染遍历**确已**走到
                //  `DPV → DPH → 页视觉`（`[PAGEVIEW] site=DPV.GetVisualChild` ＝ `DPH.GetVisualChild`
                //  ＝ 246 次、尺寸/可见性全对），却**一像素也上不了屏** ⇒ 断点在"页视觉子树在本移植的
                //  成帧面上没被合成"。本块把挂载改成与 `FlowDocumentView` **同形**。
                //  ⚠️ **不删**上游任何一步（关闸时逐字保留包壳形态）；**不删／不放宽**任何断言。
                //  零假值／默认关：`WPF_PAGEVIEW_ONSCREEN=1` 才启用；未设 ⇒ **逐字回上游**（反极性腿）。
                if (_pageVisual != null)
                {
                    if (WpfLinuxPageViewProbe.Enabled)
                    {
                        this.RemoveVisualChild(_pageVisual);
                    }
                    else
                    {
                        pageVisualHost = VisualTreeHelper.GetParent(_pageVisual) as ContainerVisual;
                        Invariant.Assert(pageVisualHost != null);
                        pageVisualHost.Children.Clear();
                        this.RemoveVisualChild(pageVisualHost);
                    }
                }
                _pageVisual = value;
                if (_pageVisual != null)
                {
                    if (WpfLinuxPageViewProbe.Enabled)
                    {
                        this.AddVisualChild(_pageVisual);
                        WpfLinuxPageViewProbe.ReportAttach(this, _pageVisual, true);
                    }
                    else
                    {
                        pageVisualHost = new ContainerVisual();
                        this.AddVisualChild(pageVisualHost);
                        pageVisualHost.Children.Add(_pageVisual);
                        pageVisualHost.SetValue(FlowDirectionProperty, FlowDirection.LeftToRight);
                        WpfLinuxPageViewProbe.ReportAttach(this, _pageVisual, false);
                    }
                }
            }
        }

        /// <summary>
        /// Internal cached offset.
        /// </summary>
        internal Point CachedOffset;

        #endregion Internal Properties

        #region VisualChildren
        /// <summary>
        ///   Derived class must implement to support Visual children. The method must return
        ///    the child at the specified index. Index must be between 0 and GetVisualChildrenCount-1.
        ///
        ///    By default a Visual does not have any children.
        ///
        ///  Remark: 
        ///       During this virtual call it is not valid to modify the Visual tree. 
        /// </summary>
        protected override Visual GetVisualChild(int index)
        {
            WpfLinuxPageViewProbe.ReportVisit("DPH.GetVisualChild", this, _pageVisual, index);
            WpfLinuxPageViewProbe.ReportRenderSub(this, _pageVisual);
            if (index != 0 || _pageVisual == null)
            {
                throw new ArgumentOutOfRangeException(nameof(index), index, SR.Visual_ArgumentOutOfRange);
            }
            // T-B11：直接挂载形态下页视觉的父**就是**宿主 ⇒ 子必须是页视觉**本身**
            // （与 `FlowDocumentView` 的 `GetVisualChild` 返回被 `AddVisualChild` 的同一对象**同源**）。
            if (WpfLinuxPageViewProbe.Enabled)
            {
                return _pageVisual;
            }
            return VisualTreeHelper.GetParent(_pageVisual) as Visual;
        }

        /// <summary>
        ///  Derived classes override this property to enable the Visual code to enumerate 
        ///  the Visual children. Derived classes need to return the number of children
        ///  from this method.
        ///
        ///    By default a Visual does not have any children.
        ///
        ///  Remark: During this virtual method the Visual tree must not be modified.
        /// </summary>        
        protected override int VisualChildrenCount
        {
            get { return _pageVisual != null ? 1 : 0; }
        }

        #endregion VisualChildren

        private Visual _pageVisual;
    }

    /// <summary>
    /// `T-B11`（`PAGEVIEW-ONSCREEN`）：分页视觉宿主（`DocumentPageView`＋`DocumentPageHost`）的
    /// **只读台账** ＋ **「上屏」驱动闸**。照 `FlowDocumentView` 那条**可用**接线（把页视觉对象本身
    /// `AddVisualChild` 到本控件 ＋ 显式定位）做最小对齐；见本块在 `reapply-patches.py` 内的说明。
    ///
    /// ⚠️ 它**只**做两件事：① 只读打印（身份／尺寸／子树包围盒／父链）；② 在 `WPF_PAGEVIEW_ONSCREEN`
    /// `=1`（**默认关**）下把"页视觉 → 宿主"的挂载／定位按 `FlowDocumentView` 的同形做法补上。
    /// **不删上游任何一步**、**不删不放宽任何 `Invariant.Assert`**、**不碰 native 几何**。
    /// </summary>
    internal static class WpfLinuxPageViewProbe
    {
        private const int TraceMax = 600;
        private static int _trace;
        // ⏪ `T-B13`：渲染遍历读数（`DPV.GetVisualChild`／`DPH.GetVisualChild`，每趟渲染数百行）
        //   **单独记账**（不再吃 `TraceMax` 的共享预算），且**按元素**各记一份 —— 否则先出现的
        //   宿主会把全局额度吃光，把**后面的**宿主（tab3 的 `ReaderPageViewer` 那一份）整片吞掉
        //   （`T-B13` 第一次现取即栽在这里）。
        private const int VisitPerSelfMax = 200;
        private static readonly System.Collections.Generic.Dictionary<int, int> _visitPerSelf
            = new System.Collections.Generic.Dictionary<int, int>();
        private static int _enabled = -1;

        internal static bool Enabled
        {
            get
            {
                if (_enabled < 0)
                {
                    string s = null;
                    try { s = System.Environment.GetEnvironmentVariable("WPF_PAGEVIEW_ONSCREEN"); }
                    catch (System.Exception) { s = null; }
                    // ⚠️ `T-B11` **默认关**（只有显式 "1" 才开）：本条接线已被现取**证伪**
                    //   （开/关两腿 `tab2` 帧逐字节相同、具名色同为 0，见载体报告 §4）⇒ 不默认启用，
                    //   不把"零效果"的改动当成"修好了"。保持可复现（`=1` 即开）以备后续复核。
                    _enabled = (s == "1") ? 1 : 0;
                }
                return _enabled == 1;
            }
        }

        internal static bool ProbeOn
        {
            get
            {
                string s = null;
                try { s = System.Environment.GetEnvironmentVariable("WPF_PAGEVIEW_PROBE"); }
                catch (System.Exception) { s = null; }
                return (s != "0");
            }
        }

        private static void Emit(string line)
        {
            try { System.Console.Error.WriteLine(line); System.Console.Error.Flush(); }
            catch (System.Exception) { }
        }

        internal static string Id(object o)
        {
            if (o == null) { return "null"; }
            int h;
            try { h = System.Runtime.CompilerServices.RuntimeHelpers.GetHashCode(o); }
            catch (System.Exception) { return "NA"; }
            return "0x" + h.ToString("x", System.Globalization.CultureInfo.InvariantCulture);
        }

        internal static string N(double v)
        {
            return v.ToString("0.###", System.Globalization.CultureInfo.InvariantCulture);
        }

        internal static string S(Size sz)
        {
            return N(sz.Width) + "x" + N(sz.Height);
        }

        internal static string Bounds(Visual v)
        {
            if (v == null) { return "null"; }
            try
            {
                Rect r = VisualTreeHelper.GetDescendantBounds(v);
                if (r.IsEmpty) { return "empty"; }
                return N(r.X) + "," + N(r.Y) + "," + N(r.Width) + "," + N(r.Height);
            }
            catch (System.Exception) { return "NA"; }
        }

        internal static int Kids(Visual v)
        {
            if (v == null) { return -1; }
            try { return VisualTreeHelper.GetChildrenCount(v); }
            catch (System.Exception) { return -2; }
        }

        internal static string ParentId(Visual v)
        {
            if (v == null) { return "null"; }
            try { return Id(VisualTreeHelper.GetParent(v)); }
            catch (System.Exception) { return "NA"; }
        }

        internal static string Pt(UIElement e, UIElement relativeTo)
        {
            if (e == null || relativeTo == null) { return "null"; }
            try
            {
                Point p = e.TranslatePoint(new Point(0, 0), relativeTo);
                return N(p.X) + "," + N(p.Y);
            }
            catch (System.Exception) { return "NA"; }
        }

        internal static string Off(Visual v)
        {
            if (v == null) { return "null"; }
            try
            {
                Vector o = VisualTreeHelper.GetOffset(v);
                return N(o.X) + "," + N(o.Y);
            }
            catch (System.Exception) { return "NA"; }
        }

        /// <summary>
        /// 只读：**页视觉的第一层子（＝ PTS 页的 `ContainerVisual`）自身的读数** —— 子数/包围盒/自身
        /// 绘制内容。它把"页视觉**壳**已建"与"页视觉**里真的有内容视觉**"分开：若 `kids=0 ∧ content=empty`，
        /// 那"上不了屏"的成因在**壳之内空**（在分页器造页那一段），而**不在** `DocumentPageView`／
        /// `DocumentPageHost` 的挂载线上。
        /// </summary>
        internal static string ChildInfo(Visual v)
        {
            if (v == null) { return "null"; }
            try
            {
                int n = VisualTreeHelper.GetChildrenCount(v);
                if (n == 0) { return "nokids"; }
                Visual c = VisualTreeHelper.GetChild(v, 0) as Visual;
                return "c=" + Id(c) + ",kids=" + Kids(c) + ",bounds=" + Bounds(c) + ",content=" + Content(c);
            }
            catch (System.Exception) { return "NA"; }
        }

        private static void SubRec(Visual v, int depth, int lvl, System.Text.StringBuilder sb, ref int budget)
        {
            if (v == null || lvl > depth || budget <= 0) { return; }
            budget--;
            int k;
            try { k = VisualTreeHelper.GetChildrenCount(v); } catch (System.Exception) { k = -2; }
            sb.Append("L").Append(lvl).Append(':').Append(Id(v)).Append(",k=").Append(k)
              .Append(",b=").Append(Bounds(v)).Append(",c=").Append(Content(v)).Append(" | ");
            for (int i = 0; i < k && i < 6; i++)
            {
                Visual c;
                try { c = VisualTreeHelper.GetChild(v, i) as Visual; } catch (System.Exception) { c = null; }
                SubRec(c, depth, lvl + 1, sb, ref budget);
            }
        }

        /// <summary>只读：页视觉子树**逐层**读数（层号／身份／子数／包围盒／自身绘制内容），有界。</summary>
        internal static string Sub(Visual v, int depth)
        {
            if (v == null) { return "null"; }
            var sb = new System.Text.StringBuilder();
            int budget = 24;
            try { SubRec(v, depth, 0, sb, ref budget); }
            catch (System.Exception) { return "NA"; }
            return sb.ToString();
        }

        private static bool Gate(string tag)
        {
            if (!ProbeOn) { return false; }
            if (_trace >= TraceMax)
            {
                if (_trace == TraceMax)
                {
                    _trace++;
                    Emit("[PAGEVIEW] trace=suppressed-after-" + TraceMax + "lines tag=" + tag);
                }
                return false;
            }
            _trace++;
            return true;
        }

        internal static void ReportMeasure(FrameworkElement view, Size available, object paginator, object page)
        {
            if (!Gate("DPV.Measure")) { return; }
            Emit("[DPV] site=MeasureOverride id=" + Id(view) + " avail=" + S(available)
                 + " pag=" + Id(paginator) + " page=" + Id(page)
                 + " desired=" + S(view.DesiredSize) + " render=" + S(view.RenderSize)
                 + " NOINFO=dpv-measure-readonly");
        }

        internal static void ReportArrange(FrameworkElement view, Size finalSize, object page, Visual pageVisual, FrameworkElement host)
        {
            if (!Gate("DPV.Arrange")) { return; }
            Emit("[DPV] site=ArrangeOverride id=" + Id(view) + " final=" + S(finalSize)
                 + " page=" + Id(page) + " pv=" + Id(pageVisual)
                 + " pvKids=" + Kids(pageVisual) + " pvBounds=" + Bounds(pageVisual)
                 + " host=" + Id(host) + " hostKids=" + Kids(host)
                 + " viewPS=" + PS(view) + " pvPS=" + PS(pageVisual)
                 + " NOINFO=dpv-arrange-readonly");
        }

        internal static void ReportArranged(FrameworkElement view, FrameworkElement host, object page)
        {
            if (!Gate("DPV.Arranged")) { return; }
            Emit("[DPV] site=HostArranged view=" + Id(view)
                 + " host=" + Id(host)
                 + " hostRender=" + ((host == null) ? "null" : S(host.RenderSize))
                 + " hostAt=" + Pt(host, view)
                 + " hostOff=" + Off(host) + " hostXf=" + Xf(host)
                 + " hostKids=" + Kids(host)
                 + " page=" + Id(page)
                 + " NOINFO=dpv-hostarranged-readonly");
        }

        internal static void ReportArrangeEnd(FrameworkElement view, Size finalSize, FrameworkElement host, object page)
        {
            if (!Gate("DPV.ArrangeEnd")) { return; }
            Emit("[DPV] site=ArrangeEnd id=" + Id(view) + " final=" + S(finalSize)
                 + " render=" + S(view.RenderSize)
                 + " host=" + Id(host)
                 + " hostRender=" + ((host == null) ? "null" : S(host.RenderSize))
                 + " page=" + Id(page)
                 + " NOINFO=dpv-arrangeend-readonly");
        }

        internal static void ReportHostSet(Visual host, Visual pageVisual, Visual newValue)
        {
            if (!Gate("DPH.Set")) { return; }
            Emit("[DPH] site=PageVisual.set host=" + Id(host)
                 + " newValue=" + Id(newValue) + " pv=" + Id(pageVisual)
                 + " pvParent=" + ParentId(pageVisual)
                 + " pvKids=" + Kids(pageVisual) + " pvBounds=" + Bounds(pageVisual)
                 + " NOINFO=dph-pageset-readonly");
        }

        internal static string Content(Visual v)
        {
            if (v == null) { return "null"; }
            try
            {
                Rect r = VisualTreeHelper.GetContentBounds(v);
                if (r.IsEmpty) { return "empty"; }
                return N(r.X) + "," + N(r.Y) + "," + N(r.Width) + "," + N(r.Height);
            }
            catch (System.Exception) { return "NA"; }
        }

        /// <summary>
        /// 只读：**该视觉是否连在某个 `PresentationSource`（＝成帧根）上**。`null` ＝ 它所在的视觉树
        /// **没有**接到任何呈现源（也就是说它**不进成帧**——不论树内尺寸算得多对）。
        /// </summary>
        internal static string PS(Visual v)
        {
            if (v == null) { return "null"; }
            try
            {
                PresentationSource ps = PresentationSource.FromVisual(v);
                return Id(ps);
            }
            catch (System.Exception) { return "NA"; }
        }

        /// <summary>只读：到视觉树根的**父链深度**（`-1` ＝ 走不动/异常）。</summary>
        internal static int Depth(Visual v)
        {
            if (v == null) { return -1; }
            try
            {
                int d = 0;
                Visual cur = v;
                while (cur != null)
                {
                    cur = VisualTreeHelper.GetParent(cur) as Visual;
                    d++;
                    if (d > 4096) { break; }
                }
                return d;
            }
            catch (System.Exception) { return -2; }
        }

        /// <summary>
        /// 只读：**该视觉到呈现源根视觉的完整变换矩阵**（`M11,M12,M21,M22,OX,OY`）。
        /// 它把"树里尺寸算得对不对"与"**画到屏上落在哪、多大**"两件事分开：矩阵若把页面映射到
        /// 零面积/界外/非有限值，那"内容已建"与"上不了屏"就同时成立且**可证**。
        /// </summary>
        internal static string Xf(Visual v)
        {
            if (v == null) { return "null"; }
            try
            {
                PresentationSource ps = PresentationSource.FromVisual(v);
                if (ps == null) { return "nops"; }
                Visual root = ps.RootVisual;
                if (root == null) { return "noroot"; }
                GeneralTransform gt = v.TransformToAncestor(root);
                if (gt == null) { return "noxf"; }
                Rect rb = gt.TransformBounds(new Rect(0, 0, 1, 1));
                return N(rb.X) + "," + N(rb.Y) + "," + N(rb.Width) + "," + N(rb.Height);
            }
            catch (System.Exception) { return "NA"; }
        }

        internal static void ReportAttach(Visual host, Visual pageVisual, bool direct)
        {
            if (!Gate("DPH.Attach")) { return; }
            Emit("[DPH] site=Attach host=" + Id(host) + " pv=" + Id(pageVisual)
                 + " mode=" + (direct ? "direct" : "container")
                 + " pvParent=" + ParentId(pageVisual)
                 + " pvContent=" + Content(pageVisual)
                 + " pvKids=" + Kids(pageVisual)
                 + " pvBound=" + Bounds(pageVisual)
                 + " hostPS=" + PS(host) + " pvPS=" + PS(pageVisual) + " pvDepth=" + Depth(pageVisual)
                 + " hostOff=" + Off(host) + " pvXf=" + Xf(pageVisual)
                 + " pvChild=" + ChildInfo(pageVisual)
                 + " SUB=" + Sub(pageVisual, 3)
                 + " NOINFO=dph-attach-readonly");
        }

        /// <summary>
        /// 只读：`FlowDocumentView`（**画得出**的那条链）的同位对照 —— 页视觉挂在谁身上、
        /// 有没有连到呈现源、子树深度多少。使"两条链的差"有**同口径**读数。
        /// </summary>
        internal static void ReportFdv(FrameworkElement view, Visual pageVisual)
        {
            if (!Gate("FDV.Attach")) { return; }
            Emit("[FDV] site=Attach view=" + Id(view) + " pv=" + Id(pageVisual)
                 + " pvParent=" + ParentId(pageVisual)
                 + " viewPS=" + PS(view) + " pvPS=" + PS(pageVisual) + " pvDepth=" + Depth(pageVisual)
                 + " pvContent=" + Content(pageVisual) + " pvKids=" + Kids(pageVisual)
                 + " pvXf=" + Xf(pageVisual)
                 + " pvChild=" + ChildInfo(pageVisual)
                 + " SUB=" + Sub(pageVisual, 3)
                 + " NOINFO=fdv-attach-readonly");
        }

        /// <summary>
        /// 只读：**渲染遍历（render walk）到底走到了哪一格**。`GetVisualChild` 只由视觉枚举方调用
        /// （渲染／命中测试／变换）⇒ "DPV 有没有被走到"、"DPV→DPH 有没有被走到"这两问因此**有直读面**。
        /// </summary>
        private static int _subOnce;

        /// <summary>只读：**渲染遍历期间**页视觉子树的前若干次逐层读数（确认"壳之内是否真空"）。</summary>
        internal static void ReportRenderSub(FrameworkElement self, Visual pageVisual)
        {
            if (ProbeOn == false) { return; }
            if (_subOnce >= 3) { return; }
            _subOnce++;
            Emit("[DPH] site=RenderSub self=" + Id(self) + " pv=" + Id(pageVisual)
                 + " render=" + S(self.RenderSize)
                 + " SUB=" + Sub(pageVisual, 3)
                 + " NOINFO=dph-rendersub-readonly");
        }

        internal static void ReportPaginator(FrameworkElement view, object paginator)
        {
            if (!Gate("DPV.SetPaginator")) { return; }
            Emit("[DPV] site=SetPaginator id=" + Id(view) + " pag=" + Id(paginator)
                 + " NOINFO=dpv-setpaginator-readonly");
        }

        internal static void ReportCtor(FrameworkElement view)
        {
            if (!Gate("DPV.Ctor")) { return; }
            Emit("[DPV] site=Ctor id=" + Id(view) + " NOINFO=dpv-ctor-readonly");
        }

        /// <summary>
        /// `T-B13`：`DocumentViewerBase.GetPageViewsCollection` 的**只读**读数 —— 直接回答
        /// "这个查看器**有没有页宿主**（`DocumentPageView`）"（＝ tab3 断点的**判决面**）。
        /// </summary>
        internal static void ReportPageViews(object viewer, int n)
        {
            if (!ProbeOn) { return; }
            Emit("[DVBI] site=GetPageViews self=" + Id(viewer) + " selfType=" + TypeName(viewer)
                 + " n=" + n.ToString(System.Globalization.CultureInfo.InvariantCulture)
                 + " NOINFO=dvbi-readonly");
        }

        internal static string TypeName(object o)
        {
            if (o == null) { return "null"; }
            try { return o.GetType().Name; }
            catch (System.Exception) { return "NA"; }
        }

        internal static void ReportVisit(string site, FrameworkElement self, Visual child, int index)
        {
            // `T-B13`：渲染遍历读数**按元素各记一份**（不再吃 `TraceMax` 的共享额度）
            if (!ProbeOn) { return; }
            int vkey;
            try { vkey = System.Runtime.CompilerServices.RuntimeHelpers.GetHashCode(self); }
            catch (System.Exception) { vkey = 0; }
            int vc;
            _visitPerSelf.TryGetValue(vkey, out vc);
            if (vc >= VisitPerSelfMax) { return; }
            _visitPerSelf[vkey] = vc + 1;
            string childRender = "NA";
            try
            {
                FrameworkElement fe = child as FrameworkElement;
                if (fe != null) { childRender = S(fe.RenderSize); }
                else if (child != null) { childRender = "vis"; }
                else { childRender = "null"; }
            }
            catch (System.Exception) { childRender = "NA"; }
            Emit("[PAGEVIEW] site=" + site + " self=" + Id(self) + " idx=" + index
                 + " selfRender=" + S(self.RenderSize) + " selfVis=" + (self.Visibility == Visibility.Visible ? 1 : 0)
                 + " child=" + Id(child) + " childRender=" + childRender
                 + " NOINFO=renderwalk-readonly");
        }
    }
}



