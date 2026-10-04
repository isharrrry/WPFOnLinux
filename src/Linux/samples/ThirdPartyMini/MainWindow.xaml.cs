// ThirdPartyMini · MainWindow —— 第三方形态的代码后置
//
// 这里刻意只用**公开 API**（第三方也只能用公开 API）：
//   · `BitmapImage` + `UriSource` → 走 WIC 解码链（我们的 libwpfwic.so → Skia）
//   · 数据绑定到一个普通的 CLR 对象集合（不是仓内任何私有类型）
//   · 窗口用 `WindowChrome` 自定义 chrome（在 XAML 里）
//
// ⚠️ 判据相关的两件事：
//   ① 图片**必须真的解码出来**才把状态写成 OK（`ImageStatus` 的文案会进截图，人眼可核）；
//   ② 失败要**如实打印**（不许静默吞掉），这样 runner 与人都能看出是哪一步没走通。
using System;
using System.Collections.ObjectModel;
using System.IO;
using System.Windows;
using System.Windows.Media.Imaging;

namespace ThirdPartyMini
{
    public class Item
    {
        public int Id { get; set; }
        public string Name { get; set; }
    }

    public partial class MainWindow : Window
    {
        public ObservableCollection<Item> Items { get; } = new ObservableCollection<Item>();

        public MainWindow()
        {
            InitializeComponent();

            for (int i = 1; i <= 24; i++)
                Items.Add(new Item { Id = i, Name = "第三方条目 " + i.ToString("00") + " —— 绑定出来的" });

            DataContext = this;
            BindStatus.Text = "绑定项数 = " + Items.Count;

            LoadImage();
            Loaded += (_, __) => Footer.Text =
                "窗口已渲染 · 判据 = runner 在采样窗口内数窗口矩形内的颜色数（≥ 阈值才算过）";
        }

        private void LoadImage()
        {
            // runner 会在输出目录放一张 test-image.png（由 ImageMagick 生成，不入库）
            string path = Path.Combine(AppContext.BaseDirectory, "test-image.png");
            try
            {
                if (!File.Exists(path))
                {
                    ImageStatus.Text = "图片缺失（runner 应生成 " + path + "）⇒ 如实报告，不假装成功";
                    Console.WriteLine("THIRDPARTY_IMAGE=NOINFO reason=file-absent path=" + path);
                    return;
                }

                var bmp = new BitmapImage();
                bmp.BeginInit();
                bmp.UriSource = new Uri(path, UriKind.Absolute);
                bmp.CacheOption = BitmapCacheOption.OnLoad;
                bmp.EndInit();

                DecodedImage.Source = bmp;
                ImageStatus.Text = string.Format("解码成功：{0}×{1} px，格式 {2}",
                    bmp.PixelWidth, bmp.PixelHeight, bmp.Format);
                Console.WriteLine(string.Format("THIRDPARTY_IMAGE=PASS {0}x{1} format={2} path={3}",
                    bmp.PixelWidth, bmp.PixelHeight, bmp.Format, path));
            }
            catch (Exception ex)
            {
                ImageStatus.Text = "解码失败（如实报告）：" + ex.GetType().Name + ": " + ex.Message;
                Console.WriteLine("THIRDPARTY_IMAGE=FAIL " + ex.GetType().Name + " " + ex.Message);
            }
        }
    }
}

namespace ThirdPartyMini
{
    /// <summary>`#38` B4 的探针类型：**internal**（不是 public）。
    /// 只要 XAML 里引用它，PBT 就会给本程序集生成 `GeneratedInternalTypeHelper`，
    /// 而 `XamlReader.LoadBaml` 一见这个 helper 就**必然**调
    /// `XamlAccessLevel.AssemblyAccessTo(...)` ⇒ 正好踩在官方包"非 Windows 必抛"的那条路上。
    /// 用官方包 ⇒ BAML 装载当场崩；用替身 ⇒ 正常装载（这就是 `D-G45` 的判据）。</summary>
    internal class InternalBadge : System.Windows.Controls.ContentControl
    {
        public InternalBadge()
        {
            Content = "internal 类型（BAML 里引用 ⇒ 触发 XamlAccessLevel）";
        }
    }
}
