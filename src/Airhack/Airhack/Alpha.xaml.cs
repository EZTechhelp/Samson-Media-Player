using System;
using System.Windows;
using System.Windows.Controls;

namespace Airhack
{
    /// <summary>
    /// Interaction logic for Alpha.xaml
    /// </summary>
    public partial class Alpha : Window
    {
        Window wndhost;
        UserControl bckgnd;
        private readonly Point _zeroPoint = new Point(0.0, 0.0);
        private UIElement _content;
        private double _height;
        private double _width;

        public new UIElement Content
        {
            get { return _content; }
            set
            {
                _content = value;
                gridContent.Children.Clear();
                if (_content != null)
                {
                   gridContent.Children.Add(_content);
                }                
            }
        }

        internal Alpha(UserControl Background)
        {
            InitializeComponent();
            bckgnd = Background;
            bckgnd.MinHeight = 0;
            bckgnd.MinWidth = 0;
            bckgnd.MaxHeight = 4096;
            bckgnd.MaxWidth = 4096;
            bckgnd.DataContextChanged += Background_DataContextChanged;
            bckgnd.Loaded += Bckgnd_Loaded;
            //bckgnd.LayoutUpdated += Bckgnd_LayoutUpdated;
            bckgnd.Unloaded += Bckgnd_Unloaded;
        }


        private void Bckgnd_Unloaded(object sender, RoutedEventArgs e)
        {
            try
            {
                bckgnd.SizeChanged -= this.Bckgnd_SizeChanged;
                bckgnd.LayoutUpdated -= this.Bckgnd_LayoutUpdated;
                if (wndhost != null)
                {
                    wndhost.Closing -= Wndhost_Closing;
                    wndhost.LocationChanged -= Wndhost_LocationChanged;
                }
                this.Hide();
                //this.Close();
            }
            catch
            {
                return;
            }
        }

        private double GetSourceScaleX(PresentationSource source)
        {
            return source != null ? source.CompositionTarget.TransformToDevice.M11 : 1;
        }
        private double GetSourceScaleY(PresentationSource source)
        {
            return source != null ? source.CompositionTarget.TransformToDevice.M22 : 1;
        }

        private void UpdateOwnPosition()
        {
            if (wndhost == null)
            {
                return;
            }
            try
            {
                if (bckgnd.IsVisible && wndhost.IsVisible)
                {
                    Point locationFromScreen = bckgnd.PointToScreen(new Point(0, 0));
                    PresentationSource source = PresentationSource.FromVisual(wndhost);
                    System.Windows.Point targetPoints = source.CompositionTarget.TransformFromDevice.Transform(locationFromScreen);
                    this.Left = targetPoints.X;
                    this.Top = targetPoints.Y;
                }
            }
            catch
            {
                return;
            }

        }

        private void UpdateOwnSize()
        {
            if (wndhost == null)
            {
                return;
            }
            try
            {
                if (bckgnd.IsVisible && wndhost.IsVisible)
                {
                    PresentationSource source = PresentationSource.FromVisual(wndhost);
                    Vector size = bckgnd.PointToScreen(new Point(bckgnd.ActualWidth, bckgnd.ActualHeight)) - bckgnd.PointToScreen(new Point(0, 0));
                    if (source != null)
                    {
                        _height = size.Y / GetSourceScaleY(source);
                        this.Height = _height;
                        _width = size.X / GetSourceScaleX(source);
                        this.Width = _width;
                    }
                }
            }
            catch
            {
                return;
            }

        }

        private void ScaleWindowContent(double scaleX, double scaleY)
        {
            if (this.VisualChildrenCount <= 0)
            {
                return;
            }
            FrameworkElement frameworkElement = (FrameworkElement)this.GetVisualChild(0);
            System.Windows.Media.ScaleTransform scaleTransform = frameworkElement.LayoutTransform as System.Windows.Media.ScaleTransform;
            if (scaleTransform != null && Math.Abs(scaleTransform.ScaleX - scaleX) < 0.01 && Math.Abs(scaleTransform.ScaleY - scaleY) < 0.01)
            {
                return;
            }
            frameworkElement.LayoutTransform = new System.Windows.Media.ScaleTransform(scaleX, scaleY);
        }
        private void AlignWithBackground()
        {
            if (wndhost == null)
            {
                return;
            }
            PresentationSource presentationSource = PresentationSource.FromVisual(wndhost);
            if (presentationSource == null)
            {
                return;
            }
            if (PresentationSource.FromVisual(bckgnd) == null)
            {
                return;
            }
            Point point = bckgnd.PointToScreen(_zeroPoint);
            Point point2 = presentationSource.CompositionTarget.TransformFromDevice.Transform(point);
            Point point3 = bckgnd.PointToScreen(new Point(bckgnd.ActualWidth, bckgnd.ActualHeight));
            Point point4 = presentationSource.CompositionTarget.TransformFromDevice.Transform(point3);
            Left = Math.Min(point2.X, point4.X);
            Top = Math.Min(point2.Y, point4.Y);
            Width = Math.Abs(point4.X - point2.X);
            Height = Math.Abs(point4.Y - point2.Y);
            //Prevents Layout measurement override crash
            if (double.IsNaN(bckgnd.Width) || double.IsNaN(bckgnd.Height) || double.IsNaN(Width) || double.IsNaN(Height) || bckgnd.ActualHeight == 0 || bckgnd.ActualWidth == 0)
            {
                return;
            }
            if (Math.Abs(Width - bckgnd.ActualWidth) + Math.Abs(Height - bckgnd.ActualHeight) > 0.5)
            {
                ScaleWindowContent(Width / bckgnd.ActualWidth, Height / bckgnd.ActualHeight);
            }
        }
        private void Bckgnd_Loaded(object sender, RoutedEventArgs e)
        {
            if (wndhost != null && IsVisible)
            {
                return;
            }
            wndhost = Window.GetWindow(bckgnd);
            System.Diagnostics.Trace.Assert(wndhost != null);
            if (wndhost == null)
            {
                return;
            }
            Owner = wndhost;
            wndhost.Closing += Wndhost_Closing;
            //wndhost.SizeChanged += Wndhost_SizeChanged;
            wndhost.LocationChanged += Wndhost_LocationChanged;
            bckgnd.LayoutUpdated += Bckgnd_LayoutUpdated;
            bckgnd.SizeChanged += Bckgnd_SizeChanged;
            try
            {
                AlignWithBackground();
                Show();
                wndhost.Focus();
            }
            catch
            {
                Hide();
            }
        }
        private void Background_DataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
        {
            base.DataContext = e.NewValue;
        }

        private void Bckgnd_LayoutUpdated(object sender, EventArgs e)
        {
            //UpdateOwnPosition();
            //UpdateOwnSize();
            AlignWithBackground();
        }
        private void Bckgnd_SizeChanged(object sender, EventArgs e)
        {
            AlignWithBackground();
        }
        private void Wndhost_LocationChanged(object sender, EventArgs e)
        {
            //UpdateOwnPosition();
            AlignWithBackground();
        }

        private void Wndhost_SizeChanged(object sender, SizeChangedEventArgs e)
        {
            //UpdateOwnPosition();
            //UpdateOwnSize();
            AlignWithBackground();
        }

        private void Wndhost_Closing(object sender, System.ComponentModel.CancelEventArgs e)
        {
            if (e.Cancel)
            {
                return;
            }
            this.Close();
            bckgnd.DataContextChanged -= Background_DataContextChanged;
            bckgnd.Loaded -= Bckgnd_Loaded;
            bckgnd.Unloaded -= Bckgnd_Unloaded;
        }
    }
}
