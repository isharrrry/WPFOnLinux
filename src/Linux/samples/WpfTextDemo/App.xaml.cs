using System;
using System.Windows;

namespace WpfTextDemo
{
    /// <summary>
    /// 应用入口。XAML 侧由 App.xaml 经 MarkupCompilePass1 编译成 App.baml，
    /// 运行期通过 BAML 建树；StartupUri 拉起 MainWindow。
    /// </summary>
    public partial class App : Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            Console.WriteLine("[wptd] App.OnStartup：默认配置门禁样例启动");
            base.OnStartup(e);
        }
    }
}
