using System;
using System.Windows;

namespace WpfFeatureProbe
{
    /// <summary>
    /// 功能广度样例的入口。
    ///
    /// 【这个样例是干什么的】`HelloWpf` / `WpfTextDemo` 覆盖的是**我们自己挑的功能**；
    /// 本样例用来**用更宽的真 WPF 功能面去撞**已知薄弱处（独立 HWND 的 Popup/ContextMenu、
    /// 动画命令族、OpacityMask、未验证的 Effect、虚拟化、编辑态输入…）。
    ///
    /// 【判定形状】每个功能块**自报一行台账**：
    ///     `[feat] &lt;名称&gt; OK|FAIL|INCONCLUSIVE &lt;一句证据&gt;`
    /// runner 按块 grep、汇总 `WFP_SUMMARY blocks=N ok=… fail=… inconclusive=…`，
    /// 并对每块的**测试色**做像素核对（"没抛异常" ≠ "画出来了"）。
    /// </summary>
    public partial class App : Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            Console.WriteLine("[wfp] App.OnStartup：功能广度样例启动");
            base.OnStartup(e);
        }
    }
}
