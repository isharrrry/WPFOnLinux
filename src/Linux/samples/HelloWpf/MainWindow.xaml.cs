using System.Windows;

namespace HelloWpf
{
    /// <summary>
    /// 主窗口。XAML 侧 MainWindow.xaml 经 MarkupCompilePass1 编译成 MainWindow.baml，
    /// 运行时由 InitializeComponent() 加载 BAML 建立视觉树。
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
        }
    }
}
