using System;
using System.Windows;
using System.Windows.Controls;

namespace WpfLinuxSdkProbe
{
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            Status.Text = "XAML 已编译进 BAML 并成功装载：" + typeof(MainWindow).Assembly.GetName().Name;
            Console.WriteLine("SDKPROBE_WINDOW=PASS");
        }
    }

    internal class InternalBadge : ContentControl
    {
        public InternalBadge()
        {
            Content = "internal 类型（BAML 引用 ⇒ XamlAccessLevel）";
        }
    }
}
