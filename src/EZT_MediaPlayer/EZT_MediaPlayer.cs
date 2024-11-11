using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media.Animation;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Data;
using System.Windows.Shapes;
using System.Runtime.InteropServices;
using System.Windows.Interop;
using System.Collections;
using System.Collections.Generic;
using System.Xml.Serialization;
using System.Net;
using System.Net.Http;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.ComponentModel;
using System.Collections.Specialized;
using System.Runtime.CompilerServices;
using System.Xml.Linq;
using MahApps.Metro.Controls;
using ControlzEx.Native;
using ControlzEx.Standard;
using System.Diagnostics;
using System.Windows.Threading;
using System.Windows.Documents;
using System.Runtime.Serialization;
using System.Globalization;
using static ControlzEx.Standard.NativeMethods;
using System.Text;

namespace ScrollAnimateBehavior.AttachedBehaviors
{
    public static class ScrollAnimationBehavior
    {
        public static double intendedLocation = 0;

        #region Private ScrollViewer for ListBox

        private static ScrollViewer _listBoxScroller = new ScrollViewer();

        #endregion

        #region VerticalOffset Property

        public static DependencyProperty VerticalOffsetProperty =
            DependencyProperty.RegisterAttached("VerticalOffset",
                                                typeof(double),
                                                typeof(ScrollAnimationBehavior),
                                                new UIPropertyMetadata(0.0, OnVerticalOffsetChanged));

        public static void SetVerticalOffset(FrameworkElement target, double value)
        {
            target.SetValue(VerticalOffsetProperty, value);
        }

        public static double GetVerticalOffset(FrameworkElement target)
        {
            return (double)target.GetValue(VerticalOffsetProperty);
        }

        #endregion

        #region TimeDuration Property

        public static DependencyProperty TimeDurationProperty =
            DependencyProperty.RegisterAttached("TimeDuration",
                                                typeof(TimeSpan),
                                                typeof(ScrollAnimationBehavior),
                                                new PropertyMetadata(new TimeSpan(0, 0, 0, 0, 0)));

        public static void SetTimeDuration(FrameworkElement target, TimeSpan value)
        {
            target.SetValue(TimeDurationProperty, value);
        }

        public static TimeSpan GetTimeDuration(FrameworkElement target)
        {
            return (TimeSpan)target.GetValue(TimeDurationProperty);
        }

        #endregion

        #region PointsToScroll Property

        public static DependencyProperty PointsToScrollProperty =
            DependencyProperty.RegisterAttached("PointsToScroll",
                                                typeof(double),
                                                typeof(ScrollAnimationBehavior),
                                                new PropertyMetadata(0.0));

        public static void SetPointsToScroll(FrameworkElement target, double value)
        {
            target.SetValue(PointsToScrollProperty, value);
        }

        public static double GetPointsToScroll(FrameworkElement target)
        {
            return (double)target.GetValue(PointsToScrollProperty);
        }

        #endregion

        #region OnVerticalOffset Changed

        private static void OnVerticalOffsetChanged(DependencyObject target, DependencyPropertyChangedEventArgs e)
        {
            ScrollViewer scrollViewer = target as ScrollViewer;
            if (scrollViewer != null)
            {
                scrollViewer.ScrollToVerticalOffset((double)e.NewValue);
            }
        }

        #endregion

        #region IsEnabled Property

        public static DependencyProperty IsEnabledProperty =
                                                DependencyProperty.RegisterAttached("IsEnabled",
                                                typeof(bool),
                                                typeof(ScrollAnimationBehavior),
                                                new UIPropertyMetadata(false, OnIsEnabledChanged));

        public static void SetIsEnabled(FrameworkElement target, bool value)
        {
            target.SetValue(IsEnabledProperty, value);
        }

        public static bool GetIsEnabled(FrameworkElement target)
        {
            return (bool)target.GetValue(IsEnabledProperty);
        }

        #endregion

        #region OnIsEnabledChanged Changed

        private static void OnIsEnabledChanged(DependencyObject sender, DependencyPropertyChangedEventArgs e)
        {
            var target = sender;

            if (target != null && target is ScrollViewer)
            {
                ScrollViewer scroller = target as ScrollViewer;
                scroller.Loaded += new RoutedEventHandler(scrollerLoaded);
            }

            if (target != null && target is ListBox)
            {
                ListBox listbox = target as ListBox;
                listbox.Loaded += new RoutedEventHandler(listboxLoaded);
            }
        }

        #endregion

        #region AnimateScroll Helper

        private static void AnimateScroll(ScrollViewer scrollViewer, double ToValue)
        {
            scrollViewer.BeginAnimation(VerticalOffsetProperty, null);
            DoubleAnimation verticalAnimation = new DoubleAnimation();
            verticalAnimation.From = scrollViewer.VerticalOffset;
            verticalAnimation.To = ToValue;
            verticalAnimation.Duration = new Duration(GetTimeDuration(scrollViewer));
            scrollViewer.BeginAnimation(VerticalOffsetProperty, verticalAnimation);
        }

        #endregion

        #region NormalizeScrollPos Helper

        private static double NormalizeScrollPos(ScrollViewer scroll, double scrollChange, Orientation o)
        {
            double returnValue = scrollChange;

            if (scrollChange < 0)
            {
                returnValue = 0;
            }

            if (o == Orientation.Vertical && scrollChange > scroll.ScrollableHeight)
            {
                returnValue = scroll.ScrollableHeight;
            }
            else if (o == Orientation.Horizontal && scrollChange > scroll.ScrollableWidth)
            {
                returnValue = scroll.ScrollableWidth;
            }

            return returnValue;
        }

        #endregion

        #region UpdateScrollPosition Helper

        private static void UpdateScrollPosition(object sender)
        {
            ListBox listbox = sender as ListBox;

            if (listbox != null)
            {
                double scrollTo = 0;

                for (int i = 0; i < (listbox.SelectedIndex); i++)
                {
                    ListBoxItem tempItem = listbox.ItemContainerGenerator.ContainerFromItem(listbox.Items[i]) as ListBoxItem;

                    if (tempItem != null)
                    {
                        scrollTo += tempItem.ActualHeight;
                    }
                }

                AnimateScroll(_listBoxScroller, scrollTo);
            }
        }

        #endregion

        #region SetEventHandlersForScrollViewer Helper

        private static void SetEventHandlersForScrollViewer(ScrollViewer scroller)
        {
            scroller.PreviewMouseWheel += new MouseWheelEventHandler(ScrollViewerPreviewMouseWheel);
            scroller.PreviewKeyDown += new KeyEventHandler(ScrollViewerPreviewKeyDown);
            scroller.PreviewMouseLeftButtonUp += Scroller_PreviewMouseLeftButtonUp;
            scroller.MouseEnter += ScrollViewerMouseEnter;

        }

        private static void Scroller_PreviewMouseLeftButtonUp(object sender, MouseButtonEventArgs e)
        {
            intendedLocation = ((ScrollViewer)sender).VerticalOffset;
        }

        #endregion

        #region scrollerLoaded Event Handler

        private static void scrollerLoaded(object sender, RoutedEventArgs e)
        {
            ScrollViewer scroller = sender as ScrollViewer;

            SetEventHandlersForScrollViewer(scroller);
        }

        #endregion

        #region listboxLoaded Event Handler

        private static void listboxLoaded(object sender, RoutedEventArgs e)
        {
            ListBox listbox = sender as ListBox;

            _listBoxScroller = FindVisualChildHelper.GetFirstChildOfType<ScrollViewer>(listbox);
            SetEventHandlersForScrollViewer(_listBoxScroller);

            SetTimeDuration(_listBoxScroller, new TimeSpan(0, 0, 0, 0, 200));
            SetPointsToScroll(_listBoxScroller, 16.0);

            listbox.SelectionChanged += new SelectionChangedEventHandler(ListBoxSelectionChanged);
            listbox.Loaded += new RoutedEventHandler(ListBoxLoaded);
            listbox.LayoutUpdated += new EventHandler(ListBoxLayoutUpdated);
        }

        #endregion

        #region ScrollViewerPreviewMouseWheel Event Handler

        private static void ScrollViewerPreviewMouseWheel(object sender, MouseWheelEventArgs e)
        {
            double mouseWheelChange = (double)e.Delta;
            ScrollViewer scroller = (ScrollViewer)sender;
            double newVOffset = intendedLocation - (mouseWheelChange + GetPointsToScroll(scroller)); 
            //We got hit by the mouse again. jump to the offset.
            scroller.ScrollToVerticalOffset(intendedLocation);
            if (newVOffset < 0)
            {
                newVOffset = 0;
            }
            if (newVOffset > scroller.ScrollableHeight)
            {
                newVOffset = scroller.ScrollableHeight;
            }
            intendedLocation = newVOffset;
            AnimateScroll(scroller, newVOffset);           
            e.Handled = true;
        }
        private static void ScrollViewerMouseEnter(object sender, MouseEventArgs e)
        {
            ScrollViewer scroller = (ScrollViewer)sender;
            if (GetVerticalOffset(scroller) > 0)
            {
                intendedLocation = GetVerticalOffset(scroller);
                e.Handled = true;
            }
        }
        #endregion

        #region ScrollViewerPreviewKeyDown Handler

        private static void ScrollViewerPreviewKeyDown(object sender, KeyEventArgs e)
        {
            ScrollViewer scroller = (ScrollViewer)sender;

            Key keyPressed = e.Key;
            double newVerticalPos = GetVerticalOffset(scroller);
            bool isKeyHandled = false;

            if (keyPressed == Key.Down)
            {
                newVerticalPos = NormalizeScrollPos(scroller, (newVerticalPos + GetPointsToScroll(scroller)), Orientation.Vertical);
                intendedLocation = newVerticalPos;
                isKeyHandled = true;
            }
            else if (keyPressed == Key.PageDown)
            {
                newVerticalPos = NormalizeScrollPos(scroller, (newVerticalPos + scroller.ViewportHeight), Orientation.Vertical);
                intendedLocation = newVerticalPos;
                isKeyHandled = true;
            }
            else if (keyPressed == Key.Up)
            {
                newVerticalPos = NormalizeScrollPos(scroller, (newVerticalPos - GetPointsToScroll(scroller)), Orientation.Vertical);
                intendedLocation = newVerticalPos;
                isKeyHandled = true;
            }
            else if (keyPressed == Key.PageUp)
            {
                newVerticalPos = NormalizeScrollPos(scroller, (newVerticalPos - scroller.ViewportHeight), Orientation.Vertical);
                intendedLocation = newVerticalPos;
                isKeyHandled = true;
            }

            if (newVerticalPos != GetVerticalOffset(scroller))
            {
                intendedLocation = newVerticalPos;
                AnimateScroll(scroller, newVerticalPos);
            }

            e.Handled = isKeyHandled;
        }

        #endregion

        #region ListBox Event Handlers

        private static void ListBoxLayoutUpdated(object sender, EventArgs e)
        {
            UpdateScrollPosition(sender);
        }

        private static void ListBoxLoaded(object sender, RoutedEventArgs e)
        {
            UpdateScrollPosition(sender);
        }

        private static void ListBoxSelectionChanged(object sender, SelectionChangedEventArgs e)
        {
            UpdateScrollPosition(sender);
        }

        #endregion
    }

    public class MouseDoubleClick
    {
        public static DependencyProperty CommandProperty =
            DependencyProperty.RegisterAttached("Command",
            typeof(ICommand),
            typeof(MouseDoubleClick),
            new UIPropertyMetadata(CommandChanged));

        public static DependencyProperty CommandParameterProperty =
            DependencyProperty.RegisterAttached("CommandParameter",
                                                typeof(object),
                                                typeof(MouseDoubleClick),
                                                new UIPropertyMetadata(null));
        public static ICommand GetCommand(DependencyObject target) 
        { 
            return (ICommand)target.GetValue(CommandProperty); 
        }

        public static void SetCommand(DependencyObject target, ICommand value)
        {
            target.SetValue(CommandProperty, value);
        }

        public static void SetCommandParameter(DependencyObject target, object value)
        {
            target.SetValue(CommandParameterProperty, value);
        }
        public static object GetCommandParameter(DependencyObject target)
        {
            return target.GetValue(CommandParameterProperty);
        }

        private static void CommandChanged(DependencyObject target, DependencyPropertyChangedEventArgs e)
        {
            Control control = target as Control;
            if (control != null)
            {
                if ((e.NewValue != null) && (e.OldValue == null))
                {
                    control.MouseDoubleClick += OnMouseDoubleClick;
                }
                else if ((e.NewValue == null) && (e.OldValue != null))
                {
                    control.MouseDoubleClick -= OnMouseDoubleClick;
                }
            }
        }

        private static void OnMouseDoubleClick(object sender, RoutedEventArgs e)
        {           
            Control control = sender as Control;
            ICommand command = (ICommand)control.GetValue(CommandProperty);
            object commandParameter = control.GetValue(CommandParameterProperty);
            if (sender is TreeViewItem treeViewItem && !treeViewItem.IsSelected) return;
            if (command.CanExecute(commandParameter))
                command.Execute(commandParameter);
        }
    }
    public class PreviewMouseRightButtonDown
    {
        public static DependencyProperty CommandProperty =
            DependencyProperty.RegisterAttached("Command",
            typeof(ICommand),
            typeof(PreviewMouseRightButtonDown),
            new UIPropertyMetadata(CommandChanged));

        public static DependencyProperty CommandParameterProperty =
            DependencyProperty.RegisterAttached("CommandParameter",
                                                typeof(object),
                                                typeof(PreviewMouseRightButtonDown),
                                                new UIPropertyMetadata(null));
        public static ICommand GetCommand(DependencyObject target)
        {
            return (ICommand)target.GetValue(CommandProperty);
        }

        public static void SetCommand(DependencyObject target, ICommand value)
        {
            target.SetValue(CommandProperty, value);
        }

        public static void SetCommandParameter(DependencyObject target, object value)
        {
            target.SetValue(CommandParameterProperty, value);
        }
        public static object GetCommandParameter(DependencyObject target)
        {
            return target.GetValue(CommandParameterProperty);
        }

        private static void CommandChanged(DependencyObject target, DependencyPropertyChangedEventArgs e)
        {
            Control control = target as Control;
            if (control != null)
            {
                if ((e.NewValue != null) && (e.OldValue == null))
                {
                    control.PreviewMouseRightButtonDown += OnPreviewMouseRightButtonDown;
                }
                else if ((e.NewValue == null) && (e.OldValue != null))
                {
                    control.PreviewMouseRightButtonDown -= OnPreviewMouseRightButtonDown;
                }
            }
        }

        private static void OnPreviewMouseRightButtonDown(object sender, RoutedEventArgs e)
        {
            Control control = sender as Control;
            ICommand command = (ICommand)control.GetValue(CommandProperty);
            object commandParameter = control.GetValue(CommandParameterProperty);
            if (sender is TreeViewItem treeViewItem && !treeViewItem.IsSelected) return;
            if (command.CanExecute(commandParameter))
                command.Execute(commandParameter);
        }
    }
    public class NegatingConverter : IValueConverter
    {

        public object Convert(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            if (value is double)
            {
                return -((double)value);
            }
            return value;
        }

        public object ConvertBack(object value, Type targetType, object parameter, System.Globalization.CultureInfo culture)
        {
            if (value is double)
            {
                return +(double)value;
            }
            return value;
        }
    }
    public class EnableDragHelper
    {
        public static readonly DependencyProperty EnableDragProperty = DependencyProperty.RegisterAttached(
            "EnableDrag",
            typeof(bool),
            typeof(EnableDragHelper),
            new PropertyMetadata(default(bool), OnLoaded));

        private static void OnLoaded(DependencyObject dependencyObject, DependencyPropertyChangedEventArgs dependencyPropertyChangedEventArgs)
        {
            var uiElement = dependencyObject as UIElement;
            if (uiElement == null || (dependencyPropertyChangedEventArgs.NewValue is bool) == false)
            {
                return;
            }
            if ((bool)dependencyPropertyChangedEventArgs.NewValue == true)
            {
                uiElement.MouseLeftButtonDown += UIElementOnLeftButtonDown;
            }
            else
            {
                uiElement.MouseLeftButtonDown -= UIElementOnLeftButtonDown;
            }

        }

        private static void UIElementOnLeftButtonDown(object sender, MouseButtonEventArgs mouseEventArgs)
        {
            var uiElement = sender as UIElement;

            if (uiElement != null)
            {
                if (mouseEventArgs.ButtonState == MouseButtonState.Pressed && mouseEventArgs.ChangedButton == MouseButton.Left && mouseEventArgs.RoutedEvent.Name == "MouseLeftButtonDown")
                {
                    DependencyObject parent = uiElement;
                    int avoidInfiniteLoop = 0;
                    // Search up the visual tree to find the first parent window.
                    while ((parent is Window) == false)
                    {
                        parent = VisualTreeHelper.GetParent(parent);
                        avoidInfiniteLoop++;
                        if (avoidInfiniteLoop == 1000)
                        {
                            // Something is wrong - we could not find the parent window.
                            return;
                        }
                    }
                    var window = parent as Window;
                    window.DragMove();
                }
            }
        }

        public static void SetEnableDrag(DependencyObject element, bool value)
        {
            element.SetValue(EnableDragProperty, value);
        }

        public static bool GetEnableDrag(DependencyObject element)
        {
            return (bool)element.GetValue(EnableDragProperty);
        }
    }
}

namespace WpfExtensions
{
    using System;
    using System.Diagnostics;
    using System.Windows;
    using System.Windows.Controls;
    using System.Windows.Media;
    using System.Reflection;
    using System.Windows.Controls.Primitives;
    using System.Globalization;
    using System.ComponentModel;
    using System.Windows.Input;
    using System.Windows.Markup;
    using static System.Net.Mime.MediaTypeNames;

    public class WidthConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            int columnsCount = System.Convert.ToInt32(parameter);
            double width = (double)value;
            return width / columnsCount;
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }
    public class MultiplyConverter : IMultiValueConverter
    {
        public object Convert(object[] values, Type targetType, object parameter, CultureInfo culture)
        {
            double result = 1.0;
            for (int i = 0; i < values.Length; i++)
            {
                if (values[i] is double)
                    result *= (double)values[i];
            }

            return result;
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter, CultureInfo culture)
        {
            throw new Exception("Not implemented");
        }
    }

    public class TopConverter : IValueConverter
    {
        public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
        {
            int TopValue = System.Convert.ToInt32(parameter);
            int TopValueConverted = TopValue - 432;
            if (TopValueConverted >= 0)
            {
                return TopValueConverted;
            }
            else
            {
                return TopValue;
            }            
        }

        public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
        {
            throw new NotImplementedException();
        }
    }

    /// <summary>
    /// Provides extended support for drag drop operation
    /// </summary>
    public static class DragDropExtension
    {
        #region ScrollOnDragDropProperty

        public static readonly DependencyProperty ScrollOnDragDropProperty =
            DependencyProperty.RegisterAttached("ScrollOnDragDrop",
                typeof(bool),
                typeof(DragDropExtension),
                new PropertyMetadata(false, HandleScrollOnDragDropChanged));

        public static bool GetScrollOnDragDrop(DependencyObject element)
        {
            if (element == null)
            {
                throw new ArgumentNullException("element");
            }

            return (bool)element.GetValue(ScrollOnDragDropProperty);
        }

        public static void SetScrollOnDragDrop(DependencyObject element, bool value)
        {
            if (element == null)
            {
                throw new ArgumentNullException("element");
            }

            element.SetValue(ScrollOnDragDropProperty, value);
        }

        private static void HandleScrollOnDragDropChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
        {
            FrameworkElement container = d as FrameworkElement;

            if (d == null)
            {
                Debug.Fail("Invalid type!");
                return;
            }

            Unsubscribe(container);

            if (true.Equals(e.NewValue))
            {
                Subscribe(container);
            }
        }

        private static void Subscribe(FrameworkElement container)
        {
            container.PreviewDragOver += OnContainerPreviewDragOver;
        }

        private static void OnContainerPreviewDragOver(object sender, DragEventArgs e)
        {
            FrameworkElement container = sender as FrameworkElement;

            if (container == null)
            {
                return;
            }
            ScrollViewer scrollViewer = container as ScrollViewer;
            if (scrollViewer == null)
            {
                GetFirstVisualChild<ScrollViewer>(container);
            }
            else
            {
                _ = GetFirstVisualChild<ScrollViewer>(container);
            }
            
            if (scrollViewer == null)
            {
                return;
            }

            double tolerance = 20;
            double verticalPos = e.GetPosition(container).Y;
            double offset = 20;

            if (verticalPos < tolerance) // Top of visible list? 
            {
                scrollViewer.ScrollToVerticalOffset(scrollViewer.VerticalOffset - offset); //Scroll up. 
            }
            else if (verticalPos > container.ActualHeight - tolerance) //Bottom of visible list? 
            {
                scrollViewer.ScrollToVerticalOffset(scrollViewer.VerticalOffset + offset); //Scroll down.     
            }
        }

        private static void Unsubscribe(FrameworkElement container)
        {
            container.PreviewDragOver -= OnContainerPreviewDragOver;
        }

        public static T GetFirstVisualChild<T>(DependencyObject depObj) where T : DependencyObject
        {
            if (depObj != null)
            {
                for (int i = 0; i < VisualTreeHelper.GetChildrenCount(depObj); i++)
                {
                    DependencyObject child = VisualTreeHelper.GetChild(depObj, i);
                    if (child != null && child is T)
                    {
                        return (T)child;
                    }

                    T childItem = GetFirstVisualChild<T>(child);
                    if (childItem != null)
                    {
                        return childItem;
                    }
                }
            }

            return null;
        }

        #endregion
    }
    public class GridLengthAnimation : AnimationTimeline
    {
        /// <summary>
        /// Returns the type of object to animate
        /// </summary>
        public override Type TargetPropertyType
        {
            get
            {
                return typeof(GridLength);
            }
        }

        /// <summary>
        /// Creates an instance of the animation object
        /// </summary>
        /// <returns>Returns the instance of the GridLengthAnimation</returns>
        protected override System.Windows.Freezable CreateInstanceCore()
        {
            return new GridLengthAnimation();
        }

        /// <summary>
        /// Dependency property for the From property
        /// </summary>
        public static readonly DependencyProperty FromProperty = DependencyProperty.Register("From", typeof(GridLength),
                typeof(GridLengthAnimation));

        /// <summary>
        /// CLR Wrapper for the From depenendency property
        /// </summary>
        public GridLength From
        {
            get
            {
                return (GridLength)GetValue(GridLengthAnimation.FromProperty);
            }
            set
            {
                SetValue(GridLengthAnimation.FromProperty, value);
            }
        }

        /// <summary>
        /// Dependency property for the To property
        /// </summary>
        public static readonly DependencyProperty ToProperty = DependencyProperty.Register("To", typeof(GridLength),
                typeof(GridLengthAnimation));

        /// <summary>
        /// CLR Wrapper for the To property
        /// </summary>
        public GridLength To
        {
            get
            {
                return (GridLength)GetValue(GridLengthAnimation.ToProperty);
            }
            set
            {
                SetValue(GridLengthAnimation.ToProperty, value);
            }
        }

        /// <summary>
        /// Animates the grid let set
        /// </summary>
        /// <param name="defaultOriginValue">The original value to animate</param>
        /// <param name="defaultDestinationValue">The final value</param>
        /// <param name="animationClock">The animation clock (timer)</param>
        /// <returns>Returns the new grid length to set</returns>
        public override object GetCurrentValue(object defaultOriginValue,
            object defaultDestinationValue, AnimationClock animationClock)
        {
            double fromVal = ((GridLength)GetValue(GridLengthAnimation.FromProperty)).Value;
            //check that from was set from the caller
            if (fromVal == 1)
                //set the from as the actual value
                fromVal = ((GridLength)defaultOriginValue).Value;

            double toVal = ((GridLength)GetValue(GridLengthAnimation.ToProperty)).Value;

            if (fromVal > toVal)
                return new GridLength((1 - animationClock.CurrentProgress.Value) * (fromVal - toVal) + toVal, GridUnitType.Star);
            else
                return new GridLength(animationClock.CurrentProgress.Value * (toVal - fromVal) + fromVal, GridUnitType.Star);
        }
    }
    public class FormattedSlider : Slider
    {
        private ToolTip _autoToolTip;
        private string _autoToolTipFormat;
        private bool _autoToolTipasTimeSpan;

        /// <summary>
        /// Gets/sets a format string used to modify the auto tooltip's content.
        /// Note: This format string must contain exactly one placeholder value,
        /// which is used to hold the tooltip's original content.
        /// </summary>
        public string AutoToolTipFormat
        {
            get { return _autoToolTipFormat; }
            set { _autoToolTipFormat = value; }
        }
        public bool AutoToolTipasTimeSpan
        {
            get { return _autoToolTipasTimeSpan; }
            set { _autoToolTipasTimeSpan = value; }
        }
        protected override void OnThumbDragStarted(DragStartedEventArgs e)
        {
            base.OnThumbDragStarted(e);
            this.FormatAutoToolTipContent();
        }

        protected override void OnThumbDragDelta(DragDeltaEventArgs e)
        {
            base.OnThumbDragDelta(e);
            this.FormatAutoToolTipContent();
        }
        public void FormatAutoToolTipContent()
        {
            if (!string.IsNullOrEmpty(this.AutoToolTipFormat))
            {
                string text = this.AutoToolTip.Content as string;
                double number;
                if (double.TryParse(text, out number) && this.AutoToolTipasTimeSpan)
                {
                    this.AutoToolTip.Content = TimeSpan.FromSeconds(number).ToString();
                    this.ToolTip = TimeSpan.FromSeconds(number).ToString();
                }
                else
                {
                    if (text.Contains("-"))
                    {
                        this.AutoToolTip.Content = string.Format(
                        this.AutoToolTipFormat,
                        this.AutoToolTip.Content);
                        this.ToolTip = string.Format(
                        this.AutoToolTipFormat,
                        this.AutoToolTip.Content);

                    }
                    else
                    {
                        this.AutoToolTip.Content = string.Format(
                        this.AutoToolTipFormat,
                        "+" + (this.AutoToolTip.Content));
                        this.ToolTip = string.Format(
                        this.AutoToolTipFormat,
                        "+" + (this.AutoToolTip.Content));
                    }

                }
            }
        }

        public ToolTip AutoToolTip
        {
            get
            {
                if (_autoToolTip == null)
                {
                    FieldInfo field = typeof(Slider).GetField(
                        "_autoToolTip",
                        BindingFlags.NonPublic | BindingFlags.Instance);

                    _autoToolTip = field.GetValue(this) as ToolTip;
                }

                return _autoToolTip;
            }
        }
    }
    /// <summary>
    /// Interop Enabled TextBox : This TextBox will properly handle WM_GETDLGCODE Messages allowing Key Input
    /// </summary>
    public class IOTextBox : TextBox
    {
        private const UInt32 DLGC_WANTARROWS = 0x0001;
        private const UInt32 DLGC_WANTTAB = 0x0002;
        private const UInt32 DLGC_WANTALLKEYS = 0x0004;
        private const UInt32 DLGC_HASSETSEL = 0x0008;
        private const UInt32 DLGC_WANTCHARS = 0x0080;
        private const UInt32 WM_GETDLGCODE = 0x0087;

        public IOTextBox() : base()
        {
            Loaded += delegate
            {
                HwndSource s = HwndSource.FromVisual(this) as HwndSource;
                if (s != null)
                    s.AddHook(new HwndSourceHook(ChildHwndSourceHook));
            };
        }

        IntPtr ChildHwndSourceHook(IntPtr hwnd, int msg, IntPtr wParam, IntPtr lParam, ref bool handled)
        {
            const UInt32 WM_CHAR = 0x0102;

            if (msg == WM_CHAR)
            {
                // avoid duplicated spaces when parent window is a native window
                if (wParam.ToInt32() == 32)
                    handled = true;
            }

            if (msg == WM_GETDLGCODE)
            {
                handled = true;
                return new IntPtr(DLGC_WANTCHARS | DLGC_WANTARROWS | DLGC_HASSETSEL);
            }
            return IntPtr.Zero;
        }
    }

    [ContentProperty("Text")]
    public class OutlinedTextBlock : FrameworkElement
    {
        private void UpdatePen()
        {
            _Pen = new Pen(Stroke, StrokeThickness)
            {
                DashCap = PenLineCap.Round,
                EndLineCap = PenLineCap.Round,
                LineJoin = PenLineJoin.Round,
                StartLineCap = PenLineCap.Round
            };

            InvalidateVisual();
        }

        public static readonly DependencyProperty FillProperty = DependencyProperty.Register(
          "Fill",
          typeof(Brush),
          typeof(OutlinedTextBlock),
          new FrameworkPropertyMetadata(Brushes.Black, FrameworkPropertyMetadataOptions.AffectsRender));

        public static readonly DependencyProperty StrokeProperty = DependencyProperty.Register(
          "Stroke",
          typeof(Brush),
          typeof(OutlinedTextBlock),
          new FrameworkPropertyMetadata(Brushes.Black, FrameworkPropertyMetadataOptions.AffectsRender, StrokePropertyChangedCallback));

        private static void StrokePropertyChangedCallback(DependencyObject dependencyObject, DependencyPropertyChangedEventArgs dependencyPropertyChangedEventArgs)
        {
            (dependencyObject as OutlinedTextBlock)?.UpdatePen();
        }

        public static readonly DependencyProperty StrokeThicknessProperty = DependencyProperty.Register(
          "StrokeThickness",
          typeof(double),
          typeof(OutlinedTextBlock),
          new FrameworkPropertyMetadata(1d, FrameworkPropertyMetadataOptions.AffectsRender, StrokePropertyChangedCallback));

        public static readonly DependencyProperty FontFamilyProperty = TextElement.FontFamilyProperty.AddOwner(
          typeof(OutlinedTextBlock),
          new FrameworkPropertyMetadata(OnFormattedTextUpdated));

        public static readonly DependencyProperty FontSizeProperty = TextElement.FontSizeProperty.AddOwner(
          typeof(OutlinedTextBlock),
          new FrameworkPropertyMetadata(OnFormattedTextUpdated));

        public static readonly DependencyProperty FontStretchProperty = TextElement.FontStretchProperty.AddOwner(
          typeof(OutlinedTextBlock),
          new FrameworkPropertyMetadata(OnFormattedTextUpdated));

        public static readonly DependencyProperty FontStyleProperty = TextElement.FontStyleProperty.AddOwner(
          typeof(OutlinedTextBlock),
          new FrameworkPropertyMetadata(OnFormattedTextUpdated));

        public static readonly DependencyProperty FontWeightProperty = TextElement.FontWeightProperty.AddOwner(
          typeof(OutlinedTextBlock),
          new FrameworkPropertyMetadata(OnFormattedTextUpdated));

        public static readonly DependencyProperty TextProperty = DependencyProperty.Register(
          "Text",
          typeof(string),
          typeof(OutlinedTextBlock),
          new FrameworkPropertyMetadata(OnFormattedTextInvalidated));

        public static readonly DependencyProperty TextAlignmentProperty = DependencyProperty.Register(
          "TextAlignment",
          typeof(TextAlignment),
          typeof(OutlinedTextBlock),
          new FrameworkPropertyMetadata(OnFormattedTextUpdated));

        public static readonly DependencyProperty TextDecorationsProperty = DependencyProperty.Register(
          "TextDecorations",
          typeof(TextDecorationCollection),
          typeof(OutlinedTextBlock),
          new FrameworkPropertyMetadata(OnFormattedTextUpdated));

        public static readonly DependencyProperty TextTrimmingProperty = DependencyProperty.Register(
          "TextTrimming",
          typeof(TextTrimming),
          typeof(OutlinedTextBlock),
          new FrameworkPropertyMetadata(OnFormattedTextUpdated));

        public static readonly DependencyProperty TextWrappingProperty = DependencyProperty.Register(
          "TextWrapping",
          typeof(TextWrapping),
          typeof(OutlinedTextBlock),
          new FrameworkPropertyMetadata(TextWrapping.NoWrap, OnFormattedTextUpdated));

        private FormattedText _FormattedText;
        private Geometry _TextGeometry;
        private Pen _Pen;

        public Brush Fill
        {
            get { return (Brush)GetValue(FillProperty); }
            set { SetValue(FillProperty, value); }
        }

        public FontFamily FontFamily
        {
            get { return (FontFamily)GetValue(FontFamilyProperty); }
            set { SetValue(FontFamilyProperty, value); }
        }

        [TypeConverter(typeof(FontSizeConverter))]
        public double FontSize
        {
            get { return (double)GetValue(FontSizeProperty); }
            set { SetValue(FontSizeProperty, value); }
        }

        public FontStretch FontStretch
        {
            get { return (FontStretch)GetValue(FontStretchProperty); }
            set { SetValue(FontStretchProperty, value); }
        }

        public FontStyle FontStyle
        {
            get { return (FontStyle)GetValue(FontStyleProperty); }
            set { SetValue(FontStyleProperty, value); }
        }

        public FontWeight FontWeight
        {
            get { return (FontWeight)GetValue(FontWeightProperty); }
            set { SetValue(FontWeightProperty, value); }
        }

        public Brush Stroke
        {
            get { return (Brush)GetValue(StrokeProperty); }
            set { SetValue(StrokeProperty, value); }
        }

        public double StrokeThickness
        {
            get { return (double)GetValue(StrokeThicknessProperty); }
            set { SetValue(StrokeThicknessProperty, value); }
        }

        public string Text
        {
            get { return (string)GetValue(TextProperty); }
            set { SetValue(TextProperty, value); }
        }

        public TextAlignment TextAlignment
        {
            get { return (TextAlignment)GetValue(TextAlignmentProperty); }
            set { SetValue(TextAlignmentProperty, value); }
        }

        public TextDecorationCollection TextDecorations
        {
            get { return (TextDecorationCollection)GetValue(TextDecorationsProperty); }
            set { SetValue(TextDecorationsProperty, value); }
        }

        public TextTrimming TextTrimming
        {
            get { return (TextTrimming)GetValue(TextTrimmingProperty); }
            set { SetValue(TextTrimmingProperty, value); }
        }

        public TextWrapping TextWrapping
        {
            get { return (TextWrapping)GetValue(TextWrappingProperty); }
            set { SetValue(TextWrappingProperty, value); }
        }

        public OutlinedTextBlock()
        {
            UpdatePen();
            TextDecorations = new TextDecorationCollection();
        }

        protected override void OnRender(DrawingContext drawingContext)
        {
            EnsureGeometry();

            drawingContext.DrawGeometry(null, _Pen, _TextGeometry);
            drawingContext.DrawGeometry(Fill, null, _TextGeometry);
        }

        protected override Size MeasureOverride(Size availableSize)
        {
            EnsureFormattedText();

            // constrain the formatted text according to the available size

            double w = availableSize.Width;
            double h = availableSize.Height;

            // the Math.Min call is important - without this constraint (which seems arbitrary, but is the maximum allowable text width), things blow up when availableSize is infinite in both directions
            // the Math.Max call is to ensure we don't hit zero, which will cause MaxTextHeight to throw
            _FormattedText.MaxTextWidth = Math.Min(3579139, w);
            _FormattedText.MaxTextHeight = Math.Max(0.0001d, h);

            // return the desired size
            return new Size(Math.Ceiling(_FormattedText.Width), Math.Ceiling(_FormattedText.Height));
        }

        protected override Size ArrangeOverride(Size finalSize)
        {
            EnsureFormattedText();

            // update the formatted text with the final size
            _FormattedText.MaxTextWidth = finalSize.Width;
            _FormattedText.MaxTextHeight = Math.Max(0.0001d, finalSize.Height);

            // need to re-generate the geometry now that the dimensions have changed
            _TextGeometry = null;

            return finalSize;
        }

        private static void OnFormattedTextInvalidated(DependencyObject dependencyObject,
          DependencyPropertyChangedEventArgs e)
        {
            var outlinedTextBlock = (OutlinedTextBlock)dependencyObject;
            outlinedTextBlock._FormattedText = null;
            outlinedTextBlock._TextGeometry = null;

            outlinedTextBlock.InvalidateMeasure();
            outlinedTextBlock.InvalidateVisual();
        }

        private static void OnFormattedTextUpdated(DependencyObject dependencyObject, DependencyPropertyChangedEventArgs e)
        {
            var outlinedTextBlock = (OutlinedTextBlock)dependencyObject;
            outlinedTextBlock.UpdateFormattedText();
            outlinedTextBlock._TextGeometry = null;

            outlinedTextBlock.InvalidateMeasure();
            outlinedTextBlock.InvalidateVisual();
        }

        private void EnsureFormattedText()
        {
            if (_FormattedText != null)
            {
                return;
            }
            _FormattedText = new FormattedText(Text ?? "", CultureInfo.CurrentUICulture,FlowDirection.LeftToRight, new Typeface(FontFamily, FontStyle, FontWeight, FontStretch), FontSize, Brushes.Black,VisualTreeHelper.GetDpi(this).PixelsPerDip);

            UpdateFormattedText();
        }

        private void UpdateFormattedText()
        {
            if (_FormattedText == null)
            {
                return;
            }

            _FormattedText.MaxLineCount = TextWrapping == TextWrapping.NoWrap ? 1 : int.MaxValue;
            _FormattedText.TextAlignment = TextAlignment;
            _FormattedText.Trimming = TextTrimming;

            _FormattedText.SetFontSize(FontSize);
            _FormattedText.SetFontStyle(FontStyle);
            _FormattedText.SetFontWeight(FontWeight);
            _FormattedText.SetFontFamily(FontFamily);
            _FormattedText.SetFontStretch(FontStretch);
            _FormattedText.SetTextDecorations(TextDecorations);
        }

        private void EnsureGeometry()
        {
            if (_TextGeometry != null)
            {
                return;
            }

            EnsureFormattedText();
            _TextGeometry = _FormattedText.BuildGeometry(new Point(0, 0));
        }
    }
}

public static class FindVisualChildHelper
{
    public static T GetFirstChildOfType<T>(DependencyObject dependencyObject) where T : DependencyObject
    {
        if (dependencyObject == null)
        {
            return null;
        }

        for (var i = 0; i < VisualTreeHelper.GetChildrenCount(dependencyObject); i++)
        {
            var child = VisualTreeHelper.GetChild(dependencyObject, i);

            var result = (child as T) ?? GetFirstChildOfType<T>(child);

            if (result != null)
            {
                return result;
            }
        }

        return null;
    }
}

namespace WPFCircleSlider
{
    /// <summary>
    /// Interaction logic for WPF Circle Slider
    /// </summary>
    public partial class Window1 : Window
    {
        private bool _isPressed = false;
        private Canvas _templateCanvas = null;

        private void Ellipse_MouseLeftButtonDown(object sender, MouseButtonEventArgs e)
        {
            //Enable moving mouse to change the value.
            _isPressed = true;
        }

        private void Ellipse_MouseLeftButtonUp(object sender, MouseButtonEventArgs e)
        {
            //Disable moving mouse to change the value.
            _isPressed = false;
        }

        private void Ellipse_MouseMove(object sender, MouseEventArgs e)
        {
            if (_isPressed)
            {
                //Find the parent canvas.
                if (_templateCanvas == null)
                {
                    _templateCanvas = MyHelper.FindParent<Canvas>(e.Source as Ellipse);
                    if (_templateCanvas == null) return;
                }
                //Canculate the current rotation angle and set the value.
                const double RADIUS = 150;
                Point newPos = e.GetPosition(_templateCanvas);
                double angle = MyHelper.GetAngleR(newPos, RADIUS);
                //knob.Value = (knob.Maximum - knob.Minimum) * angle / (2 * Math.PI);
            }
        }
    }

    //The converter used to convert the value to the rotation angle.
    public class ValueAngleConverter : IMultiValueConverter
    {
        #region IMultiValueConverter Members

        public object Convert(object[] values, Type targetType, object parameter,
                      System.Globalization.CultureInfo culture)
        {
            double value = (double)values[0];
            double minimum = (double)values[1];
            double maximum = (double)values[2];

            return MyHelper.GetAngle(value, maximum, minimum);
        }

        public object[] ConvertBack(object value, Type[] targetTypes, object parameter,
              System.Globalization.CultureInfo culture)
        {
            throw new NotImplementedException();
        }

        #endregion
    }

    //Convert the value to text.
    public class ValueTextConverter : IValueConverter
    {

        #region IValueConverter Members

        public object Convert(object value, Type targetType, object parameter,
                  System.Globalization.CultureInfo culture)
        {
            double v = (double)value;
            return String.Format("{0:F2}", v);
        }

        public object ConvertBack(object value, Type targetType, object parameter,
            System.Globalization.CultureInfo culture)
        {
            throw new NotImplementedException();
        }

        #endregion
    }

    public static class MyHelper
    {
        //Get the parent of an item.
        public static T FindParent<T>(FrameworkElement current)
          where T : FrameworkElement
        {
            do
            {
                current = VisualTreeHelper.GetParent(current) as FrameworkElement;
                if (current is T)
                {
                    return (T)current;
                }
            }
            while (current != null);
            return null;
        }

        //Get the rotation angle from the value
        public static double GetAngle(double value, double maximum, double minimum)
        {
            double current = (value / (maximum - minimum)) * 300 + 25;
            if (current == 360)
                current = 359.999;

            return current;
        }

        //Get the rotation angle from the position of the mouse
        public static double GetAngleR(Point pos, double radius)
        {
            //Calculate out the distance(r) between the center and the position
            Point center = new Point(radius, radius);
            double xDiff = center.Y - pos.Y;
            double yDiff = center.X - pos.X;
            double r = Math.Sqrt(xDiff * xDiff + yDiff * yDiff);

            //Calculate the angle
            double angle = Math.Acos((center.X - pos.X) / r);
            if (pos.Y < radius)
                angle = 2 * Math.PI - angle;
            if (Double.IsNaN(angle))
                return 0.0;
            else
                return angle;
        }
    }
}

namespace KeyStates
{
    public static class MyHelper
    {
        [DllImport("user32.dll", CharSet = CharSet.Auto, ExactSpelling = true)]
        public static extern short GetAsyncKeyState(int key);
    }
}

namespace User32Wrapper
{
    public static class WindowHelper
    {
        [DllImport("user32.dll")]
        public static extern bool DestroyWindow(IntPtr hwnd);
        [DllImport("user32.dll")]
        public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        [DllImport("USER32.DLL")]
        static extern bool EnumWindows(EnumWindowsProc enumFunc, int lParam);
        [DllImport("USER32.DLL")]
        static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
        [DllImport("USER32.DLL")]
        static extern int GetWindowTextLength(IntPtr hWnd);
        [DllImport("USER32.DLL")]
        static extern bool IsWindowVisible(IntPtr hWnd);
        [DllImport("USER32.DLL")]
        static extern IntPtr GetShellWindow();
        [DllImport("User32.dll")]
        static extern bool IsIconic(IntPtr hwnd);
        [DllImport("user32.dll")]
        public static extern IntPtr SetParent(IntPtr hWndChild, IntPtr hWndNewParent);
        [DllImport("user32.dll")]
        public static extern IntPtr GetParent(IntPtr hWndChild);
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern Int32 GetWindowThreadProcessId(IntPtr hWnd, out Int32 lpdwProcessId);


        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        public static extern IntPtr GetForegroundWindow();
        public static IDictionary<IntPtr, string> GetCurrentForegroundWindow()
        {
            IntPtr lShellWindow = GetForegroundWindow();
            Dictionary<IntPtr, string> lWindows = new Dictionary<IntPtr, string>();
            int lLength = GetWindowTextLength(lShellWindow);
            StringBuilder lBuilder = new StringBuilder(lLength);
            GetWindowText(lShellWindow, lBuilder, lLength + 1);
            lWindows[lShellWindow] = lBuilder.ToString();
            return lWindows;
        }
        public delegate bool EnumWindowsProc(IntPtr hWnd, int lParam);
        /// <summary>Returns a dictionary that contains the handle and title of all opened windows.</summary>
        /// <returns>A dictionary that contains the handle and title of all opened windows.</returns>
        public static IDictionary<IntPtr, string> GetOpenWindows()
        {
            IntPtr lShellWindow = GetShellWindow();
            Dictionary<IntPtr, string> lWindows = new Dictionary<IntPtr, string>();

            EnumWindows(delegate (IntPtr hWnd, int lParam)
            {
                if (hWnd == lShellWindow) return true;
                if (!IsWindowVisible(hWnd)) return true;
                if (IsIconic(hWnd)) return true;

                int lLength = GetWindowTextLength(hWnd);
                if (lLength == 0) return true;

                StringBuilder lBuilder = new StringBuilder(lLength);
                GetWindowText(hWnd, lBuilder, lLength + 1);

                lWindows[hWnd] = lBuilder.ToString();
                return true;

            }, 0);

            return lWindows;
        }

    }
    public class DPIAware
    {
        public static readonly IntPtr UNAWARE = (IntPtr)(-1);
        public static readonly IntPtr SYSTEM_AWARE = (IntPtr)(-2);
        public static readonly IntPtr PER_MONITOR_AWARE = (IntPtr)(-3);
        public static readonly IntPtr PER_MONITOR_AWARE_V2 = (IntPtr)(-4);
        public static readonly IntPtr UNAWARE_GDISCALED = (IntPtr)(-5);

        public enum DPI_AWARENESS
        {
            DPI_AWARENESS_INVALID = -1,
            DPI_AWARENESS_UNAWARE = 0,
            DPI_AWARENESS_SYSTEM_AWARE = 1,
            DPI_AWARENESS_PER_MONITOR_AWARE = 2,
        }

        [DllImport("user32.dll", EntryPoint = "SetProcessDpiAwarenessContext", SetLastError = true)]
        private static extern bool NativeSetProcessDpiAwarenessContext(IntPtr Value);

        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SetProcessDPIAware();

        [DllImport("Shcore.dll", SetLastError = true)]
        public static extern int SetProcessDpiAwareness(int PROCESS_DPI_AWARENESS);

        [DllImport("user32.dll", ExactSpelling = true)]
        public static extern bool IsProcessDPIAware();

        public static void SetProcessDpiAwarenessContext(IntPtr Value)
        {
            if (!NativeSetProcessDpiAwarenessContext(Value))
            {
                throw new Win32Exception();
            }
        }
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr GetThreadDpiAwarenessContext();

        [DllImport("user32.dll", SetLastError = true)]
        public static extern int GetAwarenessFromDpiAwarenessContext(IntPtr dpiAwarenessContext);

        [DllImport("user32.dll", ExactSpelling = true, EntryPoint = "SetThreadDpiAwarenessContext", SetLastError = true)]
        public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr dpiContext);
    }
}


namespace FileSystemHelpers
{
    using System;
    using System.Runtime.InteropServices;
    using System.Collections.Generic;
    using System.Diagnostics;
    using System.Reflection;
    using System.Windows.Forms;
    using System.Security.Cryptography;

    /// <summary>
    /// Present the Windows Vista-style open file dialog to select a folder. Fall back for older Windows Versions
    /// </summary>

#pragma warning disable 0219, 0414, 0162
    public class FolderSelectDialog
    {
        private string _initialDirectory;
        private string _title;
        private string _message;
        private bool _multiSelect;
        private string[] _fileName;

        public string InitialDirectory
        {
            get { return _initialDirectory; }
            set { _initialDirectory = value; }
        }
        public string Title
        {
            get { return _title ?? "Select a folder"; }
            set { _title = value; }
        }
        public string Message
        {
            get { return _message ?? _title ?? "Select a folder"; }
            set { _message = value; }
        }
        public string[] FileName { get { return _fileName; } }

        public bool MultiSelect
        { 
            get { return _multiSelect; }
            set { _multiSelect = value; }
        }


        public FolderSelectDialog(string defaultPath = "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}", string title = "Select a folder", string message = "",bool multiSelect = false)
        {
            InitialDirectory = defaultPath;
            Title = title;
            Message = message;
            MultiSelect = multiSelect;
        }

        public bool Show() { return Show(IntPtr.Zero); }

        /// <param name="hWndOwner">Handle of the control or window to be the parent of the file dialog</param>
        /// <returns>true if the user clicks OK</returns>
        public bool Show(IntPtr? hWndOwnerNullable = null)
        {
            IntPtr hWndOwner = IntPtr.Zero;
            if (hWndOwnerNullable != null)
                hWndOwner = (IntPtr)hWndOwnerNullable;
            if (Environment.OSVersion.Version.Major >= 6)
            {
                try
                {
                    var resulta = VistaDialog.Show(hWndOwner, InitialDirectory, Title, Message, MultiSelect);
                    _fileName = resulta.FileName;
                    return resulta.Result;
                }
                catch (Exception)
                {
                    var resultb = ShowXpDialog(hWndOwner, InitialDirectory, Title, Message);
                    _fileName = resultb.FileName;
                    return resultb.Result;
                }
            }
            var result = ShowXpDialog(hWndOwner, InitialDirectory, Title, Message);
            _fileName = result.FileName;
            return result.Result;
        }

        private struct ShowDialogResult
        {
            public bool Result { get; set; }
            public string[] FileName { get; set; }
        }

        private static ShowDialogResult ShowXpDialog(IntPtr ownerHandle, string initialDirectory, string title, string message)
        {
            var folderBrowserDialog = new FolderBrowserDialog
            {
                Description = message,
                SelectedPath = initialDirectory,
                ShowNewFolderButton = true
            };
            var dialogResult = new ShowDialogResult();
            if (folderBrowserDialog.ShowDialog(new WindowWrapper(ownerHandle)) == DialogResult.OK)
            {
                dialogResult.Result = true;
                dialogResult.FileName = new string[] { folderBrowserDialog.SelectedPath };
            }
            return dialogResult;
        }

        private static class VistaDialog
        {
            private const string c_foldersFilter = "Folders|\n";

            private const BindingFlags c_flags = BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic;
            private readonly static Assembly s_windowsFormsAssembly = typeof(FileDialog).Assembly;
            private readonly static Type s_iFileDialogType = s_windowsFormsAssembly.GetType("System.Windows.Forms.FileDialogNative+IFileDialog");
            private readonly static MethodInfo s_createVistaDialogMethodInfo = typeof(OpenFileDialog).GetMethod("CreateVistaDialog", c_flags);
            private readonly static MethodInfo s_onBeforeVistaDialogMethodInfo = typeof(OpenFileDialog).GetMethod("OnBeforeVistaDialog", c_flags);
            private readonly static MethodInfo s_getOptionsMethodInfo = typeof(FileDialog).GetMethod("GetOptions", c_flags);
            private readonly static MethodInfo s_setOptionsMethodInfo = s_iFileDialogType.GetMethod("SetOptions", c_flags);
            private readonly static uint s_fosPickFoldersBitFlag = (uint)s_windowsFormsAssembly
                .GetType("System.Windows.Forms.FileDialogNative+FOS")
                .GetField("FOS_PICKFOLDERS")
                .GetValue(null);
            private readonly static ConstructorInfo s_vistaDialogEventsConstructorInfo = s_windowsFormsAssembly
                .GetType("System.Windows.Forms.FileDialog+VistaDialogEvents")
                .GetConstructor(c_flags, null, new[] { typeof(FileDialog) }, null);
            private readonly static MethodInfo s_adviseMethodInfo = s_iFileDialogType.GetMethod("Advise");
            private readonly static MethodInfo s_unAdviseMethodInfo = s_iFileDialogType.GetMethod("Unadvise");
            private readonly static MethodInfo s_showMethodInfo = s_iFileDialogType.GetMethod("Show");

            public static ShowDialogResult Show(IntPtr ownerHandle, string initialDirectory, string title, string description, bool multiSelect)
            {
                var openFileDialog = new OpenFileDialog
                {
                    AddExtension = false,
                    CheckFileExists = false,
                    DereferenceLinks = true,
                    Filter = c_foldersFilter,
                    InitialDirectory = initialDirectory,
                    Multiselect = multiSelect,
                    Title = title
                };

                var iFileDialog = s_createVistaDialogMethodInfo.Invoke(openFileDialog, new object[] { });
                s_onBeforeVistaDialogMethodInfo.Invoke(openFileDialog, new[] { iFileDialog });
                s_setOptionsMethodInfo.Invoke(iFileDialog, new object[] { (uint)s_getOptionsMethodInfo.Invoke(openFileDialog, new object[] { }) | s_fosPickFoldersBitFlag });
                var adviseParametersWithOutputConnectionToken = new[] { s_vistaDialogEventsConstructorInfo.Invoke(new object[] { openFileDialog }), 0U };
                s_adviseMethodInfo.Invoke(iFileDialog, adviseParametersWithOutputConnectionToken);

                try
                {
                    int retVal = (int)s_showMethodInfo.Invoke(iFileDialog, new object[] { ownerHandle });
                    return new ShowDialogResult
                    {
                        Result = retVal == 0,
                        FileName = openFileDialog.FileNames,
                    };
                }
                finally
                {
                    s_unAdviseMethodInfo.Invoke(iFileDialog, new[] { adviseParametersWithOutputConnectionToken[1] });
                }
            }
        }

        // Wrap an IWin32Window around an IntPtr
        private class WindowWrapper : IWin32Window
        {
            private readonly IntPtr _handle;
            public WindowWrapper(IntPtr handle) { _handle = handle; }
            public IntPtr Handle { get { return _handle; } }
        }

        public string[] getPath()
        {
            if (Show())
            {
                return FileName;
            }
            return new string[] { "" };
        }
    }
}

namespace HighlightText
{
    using System;
    using System.Text.RegularExpressions;
    using System.Windows;
    using System.Windows.Controls;
    using System.Windows.Documents;
    using System.Windows.Media;
    using System.Collections.Generic;

    public class SearchableTextBlock : TextBlock
    {
        #region Constructors
        // Summary:
        //     Initializes a new instance of the System.Windows.Controls.TextBlock class.
        public SearchableTextBlock()
        {
            //Binding binding = new Binding("HighlightableText");
            //binding.Source = this;
            //binding.Mode = BindingMode.TwoWay;
            //SetBinding(TextProperty, binding);
        }

        public SearchableTextBlock(Inline inline)
            : base(inline)
        {
        }
        #endregion

        #region Properties
        new private string Text
        {
            set
            {
                if (string.IsNullOrWhiteSpace(RegularExpression) || !IsValidRegex(RegularExpression))
                {
                    base.Text = value;
                    return;
                }

                Inlines.Clear();
                string[] split = Regex.Split(value, RegularExpression, RegexOptions.IgnoreCase);
                foreach (var str in split)
                {
                    Run run = new Run(str);
                    if (Regex.IsMatch(str, RegularExpression, RegexOptions.IgnoreCase))
                    {
                        run.Background = HighlightBackground;
                        run.Foreground = HighlightForeground;
                    }
                    Inlines.Add(run);
                }
            }
        }

        public string RegularExpression
        {
            get { return _RegularExpression; }
            set
            {
                _RegularExpression = value;
                Text = base.Text;
            }
        }
        private string _RegularExpression;

        #endregion

        #region Dependency Properties

        #region Search Words
        public List<string> SearchWords
        {
            get
            {
                if (null == (List<string>)GetValue(SearchWordsProperty))
                    SetValue(SearchWordsProperty, new List<string>());
                return (List<string>)GetValue(SearchWordsProperty);
            }
            set
            {
                SetValue(SearchWordsProperty, value);
                UpdateRegex();
            }
        }

        // Using a DependencyProperty as the backing store for SearchStringList.  This enables animation, styling, binding, etc...
        public static readonly DependencyProperty SearchWordsProperty =
            DependencyProperty.Register("SearchWords", typeof(List<string>), typeof(SearchableTextBlock), new PropertyMetadata(new PropertyChangedCallback(SearchWordsPropertyChanged)));

        public static void SearchWordsPropertyChanged(DependencyObject inDO, DependencyPropertyChangedEventArgs inArgs)
        {
            SearchableTextBlock stb = inDO as SearchableTextBlock;
            if (stb == null)
                return;

            stb.UpdateRegex();
        }
        #endregion

        #region HighlightableText
        public event EventHandler OnHighlightableTextChanged;

        public string HighlightableText
        {
            get { return (string)GetValue(HighlightableTextProperty); }
            set { SetValue(HighlightableTextProperty, value); }
        }

        // Using a DependencyProperty as the backing store for HighlightableText.  This enables animation, styling, binding, etc...
        public static readonly DependencyProperty HighlightableTextProperty =
            DependencyProperty.Register("HighlightableText", typeof(string), typeof(SearchableTextBlock), new PropertyMetadata(new PropertyChangedCallback(HighlightableTextChanged)));

        public static void HighlightableTextChanged(DependencyObject inDO, DependencyPropertyChangedEventArgs inArgs)
        {
            SearchableTextBlock stb = inDO as SearchableTextBlock;
            stb.Text = stb.HighlightableText;

            // Raise the event by using the () operator.
            if (stb.OnHighlightableTextChanged != null)
                stb.OnHighlightableTextChanged(stb, null);
        }
        #endregion

        #region HighlightForeground
        public event EventHandler OnHighlightForegroundChanged;

        public Brush HighlightForeground
        {
            get
            {
                if ((Brush)GetValue(HighlightForegroundProperty) == null)
                    SetValue(HighlightForegroundProperty, Brushes.Black);
                return (Brush)GetValue(HighlightForegroundProperty);
            }
            set { SetValue(HighlightForegroundProperty, value); }
        }

        // Using a DependencyProperty as the backing store for HighlightForeground.  This enables animation, styling, binding, etc...
        public static readonly DependencyProperty HighlightForegroundProperty =
            DependencyProperty.Register("HighlightForeground", typeof(Brush), typeof(SearchableTextBlock), new PropertyMetadata(new PropertyChangedCallback(HighlightableForegroundChanged)));

        public static void HighlightableForegroundChanged(DependencyObject inDO, DependencyPropertyChangedEventArgs inArgs)
        {
            SearchableTextBlock stb = inDO as SearchableTextBlock;
            // Raise the event by using the () operator.
            if (stb.OnHighlightForegroundChanged != null)
                stb.OnHighlightForegroundChanged(stb, null);
        }
        #endregion

        #region HighlightBackground
        public event EventHandler OnHighlightBackgroundChanged;

        public Brush HighlightBackground
        {
            get
            {
                if ((Brush)GetValue(HighlightBackgroundProperty) == null)
                    SetValue(HighlightBackgroundProperty, Brushes.Yellow);
                return (Brush)GetValue(HighlightBackgroundProperty);
            }
            set { SetValue(HighlightBackgroundProperty, value); }
        }

        // Using a DependencyProperty as the backing store for HighlightBackground.  This enables animation, styling, binding, etc...
        public static readonly DependencyProperty HighlightBackgroundProperty =
            DependencyProperty.Register("HighlightBackground", typeof(Brush), typeof(SearchableTextBlock), new PropertyMetadata(new PropertyChangedCallback(HighlightableBackgroundChanged)));

        public static void HighlightableBackgroundChanged(DependencyObject inDO, DependencyPropertyChangedEventArgs inArgs)
        {
            SearchableTextBlock stb = inDO as SearchableTextBlock;
            // Raise the event by using the () operator.
            if (stb.OnHighlightBackgroundChanged != null)
                stb.OnHighlightBackgroundChanged(stb, null);
        }
        #endregion

        #endregion

        #region Methods
        public void AddSearchString(String inString)
        {
            SearchWords.Add(inString);
            Update();
        }

        public void Update()
        {
            UpdateRegex();
        }

        public void RefreshHighlightedText()
        {
            Text = base.Text;
        }

        private void UpdateRegex()
        {
            string newRegularExpression = string.Empty;
            foreach (string s in SearchWords)
            {
                if (newRegularExpression.Length > 0)
                    newRegularExpression += "|";
                newRegularExpression += RegexWrap(s);
            }

            if (RegularExpression != newRegularExpression)
                RegularExpression = newRegularExpression;
        }

        public bool IsValidRegex(string inRegex)
        {
            if (string.IsNullOrEmpty(inRegex))
                return false;

            try
            {
                Regex.Match("", inRegex);
            }
            catch (ArgumentException)
            {
                return false;
            }

            return true;
        }

        private string RegexWrap(string inString)
        {
            // Use positive look ahead and positive look behind tags
            // so the break is before and after each word, so the
            // actual word is not removed by Regex.Split()
            return String.Format("(?={0})|(?<={0})", inString);
        }
        #endregion
    }
}

[XmlRoot("dictionary")]
public class SerializableDictionary<TKey, TValue>
    : Dictionary<TKey, TValue>, IXmlSerializable, INotifyCollectionChanged, INotifyPropertyChanged
{
    public event NotifyCollectionChangedEventHandler CollectionChanged;
    public event PropertyChangedEventHandler PropertyChanged;
    protected void OnCollectionChanged(NotifyCollectionChangedEventArgs e)
    {
        // Use BlockReentrancy
            var eventHandler = CollectionChanged;
            if (eventHandler == null) return;

            // Only proceed if handler exists.
            Delegate[] delegates = eventHandler.GetInvocationList();

            // Walk through invocation list.
            foreach (var @delegate in delegates)
            {
                var handler = (NotifyCollectionChangedEventHandler)@delegate;
                var currentDispatcher = handler.Target as DispatcherObject;

                // If the subscriber is a DispatcherObject and different thread.
                if ((currentDispatcher != null) && (!currentDispatcher.CheckAccess()))
                {
                    // Invoke handler in the target dispatcher's thread.
                    currentDispatcher.Dispatcher.Invoke(
                        DispatcherPriority.DataBind, handler, this, e);
                }


                else
                {
                    // Execute as-is
                    handler(this, e);
                }
            }
    }

    public new void Add(TKey key, TValue value)
    {
        base.Add(key, value);
        OnCollectionChanged(new NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction.Add, value));
    }
    public new void Remove(TKey key)
    {
        TValue value;
        if (base.TryGetValue(key, out value))
        {
            base.Remove(key);
            OnCollectionChanged(new NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction.Remove, value));
        }
    }
    public new void Clear()
    {
        if (Count > 0)
        {
            base.Clear();
            OnCollectionChanged(new NotifyCollectionChangedEventArgs(NotifyCollectionChangedAction.Reset));
        }
    }
    public SerializableDictionary() { }
    public SerializableDictionary(IDictionary<TKey, TValue> dictionary) : base(dictionary) { }
    public SerializableDictionary(IDictionary<TKey, TValue> dictionary, IEqualityComparer<TKey> comparer) : base(dictionary, comparer) { }
    public SerializableDictionary(IEqualityComparer<TKey> comparer) : base(comparer) { }
    public SerializableDictionary(int capacity) : base(capacity) { }
    public SerializableDictionary(int capacity, IEqualityComparer<TKey> comparer) : base(capacity, comparer) { }

    #region IXmlSerializable Members
    public System.Xml.Schema.XmlSchema GetSchema()
    {
        return null;
    }

    public void ReadXml(System.Xml.XmlReader reader)
    {
        XmlSerializer keySerializer = new XmlSerializer(typeof(TKey));
        XmlSerializer valueSerializer = new XmlSerializer(typeof(TValue));

        bool wasEmpty = reader.IsEmptyElement;
        reader.Read();

        if (wasEmpty)
            return;

        while (reader.NodeType != System.Xml.XmlNodeType.EndElement)
        {
            reader.ReadStartElement("item");

            reader.ReadStartElement("key");
            TKey key = (TKey)keySerializer.Deserialize(reader);
            reader.ReadEndElement();

            reader.ReadStartElement("value");
            TValue value = (TValue)valueSerializer.Deserialize(reader);
            reader.ReadEndElement();

            this.Add(key, value);

            reader.ReadEndElement();
            reader.MoveToContent();
        }
        reader.ReadEndElement();
    }

    public void WriteXml(System.Xml.XmlWriter writer)
    {
        XmlSerializer keySerializer = new XmlSerializer(typeof(TKey));
        XmlSerializer valueSerializer = new XmlSerializer(typeof(TValue));

        foreach (TKey key in this.Keys)
        {
            writer.WriteStartElement("item");

            writer.WriteStartElement("key");
            keySerializer.Serialize(writer, key);
            writer.WriteEndElement();

            writer.WriteStartElement("value");
            TValue value = this[key];
            valueSerializer.Serialize(writer, value);
            writer.WriteEndElement();

            writer.WriteEndElement();
        }
    }
    #endregion
}
public class Media : INotifyPropertyChanged
{
    public event PropertyChangedEventHandler PropertyChanged;

    public void RaisedOnPropertyChanged(string propertyName)
    {
        var handler = PropertyChanged;
        if (handler != null)
        {
            var e = new PropertyChangedEventArgs(propertyName);
            foreach (PropertyChangedEventHandler h in handler.GetInvocationList())
            {
                var synch = h.Target as ISynchronizeInvoke;
                if (synch != null && synch.InvokeRequired)
                    synch.Invoke(h, new object[] { this, e });
                else
                    h(this, e);
            }
        }
    }
    public string id { get; set; }
    public string User_id { get; set; }
    public string Spotify_id { get; set; }
    public string Artist { get; set; }
    public string Artist_ID { get; set; }
    public string Album { get; set; }
    public string Album_id { get; set; }
    public string title { get; set; }
    public string Name { get; set; }
    public string Playlist { get; set; }
    public string playlist_id { get; set; }
    public string playlist_item_id { get; set; }
    public string Playlist_url { get; set; }
    public string Channel_Name { get; set; }
    public string Channel_ID { get; set; }
    public string description { get; set; }
    private string livestatus;
    public string Live_Status
    {
        get
        {
            return livestatus;
        }
        set
        {
            livestatus = value;
            RaisedOnPropertyChanged("Live_Status");
        }
    }
    public string Stream_title { get; set; }
    private string number;
    public string Number
    {
        get
        {
            return number;
        }
        set
        {
            number = value;
            RaisedOnPropertyChanged("Number");
        }
    }
    private string statusmsg;
    public string Status_Msg
    {
        get
        {
            return statusmsg;
        }
        set
        {
            statusmsg = value;
            RaisedOnPropertyChanged("Status_Msg");
        }
    }
    private string status;
    public string Status
    {
        get
        {
            return status;
        }
        set
        {
            status = value;
            RaisedOnPropertyChanged("Status");
        }
    }
    public int Viewer_Count { get; set; }
    public string Image { get; set; }
    private string fontstyle;
    public string FontStyle
    {
        get
        {
            return fontstyle;
        }
        set
        {
            fontstyle = value;
            RaisedOnPropertyChanged("FontStyle");
        }
    }
    private string fontcolor;
    public string FontColor
    {
        get
        {
            return fontcolor;
        }
        set
        {
            fontcolor = value;
            RaisedOnPropertyChanged("FontColor");
        }
    }
    private string fontweight;
    public string FontWeight
    {
        get
        {
            return fontweight;
        }
        set
        {
            fontweight = value;
            RaisedOnPropertyChanged("FontWeight");
        }
    }
    private string fontsize;
    public string FontSize
    {
        get
        {
            return fontsize;
        }
        set
        {
            fontsize = value;
            RaisedOnPropertyChanged("FontSize");
        }
    }
    public string Margin { get; set; }
    private string tooltip;
    public string ToolTip
    {
        get
        {
            return tooltip;
        }
        set
        {
            tooltip = value;
            RaisedOnPropertyChanged("ToolTip");
        }
    }
    private string statusfontStyle;
    public string Status_FontStyle
    {
        get
        {
            return statusfontStyle;
        }
        set
        {
            statusfontStyle = value;
            RaisedOnPropertyChanged("Status_FontStyle");
        }
    }
    private string statusfontcolor;
    public string Status_FontColor
    {
        get
        {
            return statusfontcolor;
        }
        set
        {
            statusfontcolor = value;
            RaisedOnPropertyChanged("Status_FontColor");
        }
    }
    private string statusfontweight;
    public string Status_FontWeight
    {
        get
        {
            return statusfontweight;
        }
        set
        {
            statusfontweight = value;
            RaisedOnPropertyChanged("Status_FontWeight");
        }
    }
    private string statusfontsize;
    public string Status_FontSize
    {
        get
        {
            return statusfontsize;
        }
        set
        {
            statusfontsize = value;
            RaisedOnPropertyChanged("Status_FontSize");
        }
    }
    private string borderbrush;
    public string BorderBrush
    {
        get
        {
            return borderbrush;
        }
        set
        {
            borderbrush = value;
            RaisedOnPropertyChanged("BorderBrush");
        }
    }
    private string borderthickness;
    public string BorderThickness
    {
        get
        {
            return borderthickness;
        }
        set
        {
            borderthickness = value;
            RaisedOnPropertyChanged("BorderThickness");
        }
    }
    private string numbervisibility;
    public string NumberVisibility
    {
        get
        {
            return numbervisibility;
        }
        set
        {
            numbervisibility = value;
            RaisedOnPropertyChanged("NumberVisibility");
        }
    }
    private string numberfontsize;
    public string NumberFontSize
    {
        get
        {
            return numberfontsize;
        }
        set
        {
            numberfontsize = value;
            RaisedOnPropertyChanged("NumberFontSize");
        }
    }
    public bool AllowDrop { get; set; }
    public bool IsExpanded { get; set; }
    public string directory { get; set; }
    public string SourceDirectory { get; set; }
    public bool PictureData { get; set; }
    public string thumbnail { get; set; }
    public string cached_image_path { get; set; }
    public string Profile_Image_Url { get; set; }
    public string Offline_Image_Url { get; set; }
    public string Bitrate { get; set; }
    public string Chat_Url { get; set; }
    public bool Enable_LiveAlert { get; set; }
    public string Source { get; set; }
    public string Followed { get; set; }
    public string Profile_Date_Added { get; set; }
    public string url { get; set; }
    public string type { get; set; }
    public bool hasVideo { get; set; }
    public string Current_Progress_Secs { get; set; }
    public int Track { get; set; }
    private string duration;
    public string Duration
    {
        get
        {
            return duration;
        }
        set
        {
            duration = value;
            RaisedOnPropertyChanged("Duration");
        }
    }
    public string Size { get; set; }
    public string Subtitles_Path { get; set; }
    private string displayname;
    public string Display_Name
    {
        get
        {
            return displayname;
        }
        set
        {
            displayname = value;
            RaisedOnPropertyChanged("Display_Name");
        }
    }
    public int TimesPlayed { get; set; }
}

public class EQ_Band
{
    public float Band { get; set; }
    public int Band_ID { get; set; }
    public string Band_Name { get; set; }
    public double Band_Value { get; set; }
}

public class EQ_Preset
{
    public int Preset_ID { get; set; }
    public string Preset_Name { get; set; }
}

public class Custom_EQ_Preset
{
    public string Preset_ID { get; set; }
    public string Preset_Name { get; set; }
    public double EQ_Preamp { get; set; }
    public List<EQ_Band> EQ_Bands { get; set; }
    public string Preset_Path { get; set; }
}

public class Twitch_Playlist
{
    public string ID { get; set; }
    public int Number { get; set; }
    public string Name { get; set; }
    public string Path { get; set; }
    public string Type { get; set; }
    public string Followed { get; set; }
    public bool Enable_LiveAlert { get; set; }
}

public class Cookie
{
    public string Name { get; set; }
    public string cookiedurldomain { get; set; }
    public string Value { get; set; }
    public bool isSecure { get; set; }
}

public class WebExtension
{
    public string Name { get; set; }
    public string ID { get; set; }
    public bool IsEnabled { get; set; }
    public string Icon { get; set; }
    public string path { get; set; }
}
public class ColorTheme
{
    public string Name { get; set; }
    public string Menu_item { get; set; }
    public string PrimaryAccentColor { get; set; }
}

public class GlobalHotKey
{
    public string Name { get; set; }
    public string Modifier { get; set; }
    public string Key { get; set; }
}
public class Config
{
    public string Media_Profile_Directory { get; set; }
    public string Bookmarks_Profile_Directory { get; set; }
    public bool Use_Profile_Cache { get; set; }
    public string Log_Level { get; set; }
    public string Streamlink_HTTP_Port { get; set; }
    public string TwitchMedia_Log_File { get; set; }
    public string YoutubeMedia_Log_File { get; set; }
    public string SpotifyMedia_Log_File { get; set; }
    public string Launcher_Log_File { get; set; }
    public string VLC_Arguments { get; set; }
    public bool Auto_UpdateInstall { get; set; }
    public bool LocalMedia_FastImporting { get; set; }
    public bool Enablelinkedconnections { get; set; }
    public bool Found_Hell { get; set; }
    public bool Profile_Write_IDTags { get; set; }
    public bool Mute_Twitch_Ads { get; set; }
    public bool Always_On_Top { get; set; }
    public bool Verbose_logging { get; set; }
    public bool Toggle_FullScreen { get; set; }
    public bool PlayLink_OnDrop { get; set; }
    public bool SplashScreenAudio { get; set; }
    public bool Enable_Marquee { get; set; }
    public bool ForceUse_YTDLP { get; set; }
    public double Media_Volume { get; set; }
    public string Spotify_SP_DC { get; set; }
    public string Youtube_1PSID { get; set; }
    public string Youtube_1PAPISID { get; set; }
    public string Youtube_3PAPISID { get; set; }
    public string Chat_WebView2_Cookie { get; set; }
    public string Twitch_auth_Cookie { get; set; }
    public ArrayList Local_Group_By { get; set; }
    public ArrayList Spotify_Group_By { get; set; }
    public ArrayList Youtube_Group_By { get; set; }
    public ArrayList Twitch_Group_By { get; set; }
    public int SpotifyBrowser_Paging { get; set; }
    public int YoutubeBrowser_Paging { get; set; }
    public int MediaBrowser_Paging { get; set; }
    public int TwitchBrowser_Paging { get; set; }
    public ArrayList Media_Directories { get; set; }
    public List<Custom_EQ_Preset> Custom_EQ_Presets { get; set; }
    public ArrayList Playlists_SortBy { get; set; }
    public ArrayList Spotify_Playlists { get; set; }
    public ArrayList Youtube_Playlists { get; set; }
    public SerializableDictionary<int, string> Current_Playlist { get; set; }
    public SerializableDictionary<int, string> History_Playlist { get; set; }
    public string Snapshots_Path { get; set; }
    public string LocalMedia_ImportMode { get; set; }
    public bool Use_Twitch_TTVLOL { get; set; }
    public bool Use_Twitch_luminous { get; set; }
    public string Streamlink_Arguments { get; set; }
    public bool Minimize_To_Tray { get; set; }
    public bool Disable_Tray { get; set; }
    public string LocalMedia_MonitorMode { get; set; }
    public string App_UniqueID { get; set; }
    public string Twitch_Quality { get; set; }
    public List<Cookie> Youtube_Cookies { get; set; }
    public bool Verbose_perf_measure { get; set; }
    public bool PODE_SERVER_ACTIVE { get; set; }
    public bool YoutubeMedia_Library_CollapseAllGroups { get; set; }
    public ArrayList YoutubeMedia_Library_Columns { get; set; }
    public ArrayList TwitchMedia_Library_Columns { get; set; }
    public bool IsRead_AboutFirstRun { get; set; }
    public bool IsRead_SpecialFirstRun { get; set; }
    public bool IsRead_TestFeatures { get; set; }
    public bool SpotifyMedia_Library_CollapseAllGroups { get; set; }
    public bool TwitchMedia_Library_CollapseAllGroups { get; set; }
    public bool Use_Preferred_VPN { get; set; }
    public string Preferred_VPN { get; set; }
    public bool Show_Notifications { get; set; }
    public List<WebExtension> Webview2_Extensions { get; set; }
    public bool Use_invidious { get; set; }
    public string Audio_OutputModule { get; set; }
    public bool Notification_Audio { get; set; }
    public ArrayList LocalMedia_Library_Columns { get; set; }
    public ColorTheme Current_Theme { get; set; }
    public bool Enable_EQ2Pass { get; set; }
    public List<Twitch_Playlist> Twitch_Playlists { get; set; }
    public ArrayList TwitchProxies { get; set; }
    public bool UseTwitchCustom { get; set; }
    public bool Remember_Window_Positions { get; set; }
    public bool Mini_Always_On_Top { get; set; }
    public bool Start_Tray_only { get; set; }
    public bool Start_Mini_only { get; set; }
    public bool LocalMedia_Library_CollapseAllGroups { get; set; }
    public bool Shuffle_Playback { get; set; }
    public bool Enable_AudioMonitor { get; set; }
    public bool Auto_UpdateCheck { get; set; }
    public string Last_SpeakerLeft_Image { get; set; }
    public string Vlc_Verbose_logging { get; set; }
    public ArrayList SpotifyMedia_Library_Columns { get; set; }
    public bool Auto_Playback { get; set; }
    public bool Auto_Repeat { get; set; }
    public bool Enable_EQ { get; set; }
    public bool ShowTitleBar { get; set; }
    public string Last_Splash_Image { get; set; }
    public string EQ_Selected_Preset { get; set; }
    public string Libvlc_Version { get; set; }
    public string Current_Audio_Output { get; set; }
    public bool Enable_YoutubeComments { get; set; }
    public bool Enable_Subtitles { get; set; }
    public string LocalMedia_Display_Syntax { get; set; }
    public bool Chat_View { get; set; }
    public bool Video_Snapshots { get; set; }
    public bool App_Snapshots { get; set; }
    public bool Enable_Performance_Mode { get; set; }
    public bool Use_HardwareAcceleration { get; set; }
    public bool Enable_WebEQSupport { get; set; }
    public bool Open_VideoPlayer { get; set; }
    public bool Remember_Playback_Progress { get; set; }
    public bool Start_Paused { get; set; }
    public string Current_Visualization { get; set; }
    public bool Use_Visualizations { get; set; }
    public bool Use_MediaCasting { get; set; }
    public bool LocalMedia_SkipDuplicates { get; set; }
    public bool Enable_LocalMedia_Monitor { get; set; }
    public bool Spotify_WebPlayer { get; set; }
    public bool Spotify_Update { get; set; }
    public string Spotify_Update_Interval { get; set; }
    public bool Youtube_WebPlayer { get; set; }
    public string Youtube_Update_Interval { get; set; }
    public bool Enable_Sponsorblock { get; set; }
    public string Youtube_Quality { get; set; }
    public bool Import_My_Youtube_Media { get; set; }
    public string Twitch_Update_Interval { get; set; }
    public bool Enable_Twitch_Notifications { get; set; }
    public bool Skip_Twitch_Ads { get; set; }
    public string Streamlink_Interface { get; set; }
    public string Streamlink_Verbose_logging { get; set; }
    public bool Twitch_Update { get; set; }
    public bool Start_On_Windows_Login { get; set; }
    public bool Import_Local_Media { get; set; }
    public bool Import_Youtube_Media { get; set; }
    public string Youtube_Browser { get; set; }
    public bool Youtube_Update { get; set; }
    public string Youtube_Download_Path { get; set; }
    public string Sponsorblock_ActionType { get; set; }
    public bool Import_Twitch_Media { get; set; }
    public bool Use_Spicetify { get; set; }
    public bool Import_Spotify_Media { get; set; }
    public bool Install_Spotify { get; set; }
    public bool Import_Youtube_Browser_Auth { get; set; }
    public bool Discord_Integration { get; set; }
    public bool Media_Muted { get; set; }
    public Media Current_Playing_Media { get; set; }
    public string Last_Played { get; set; }
    public double EQ_Preamp { get; set; }
    public string Libvlc_Global_Gain { get; set; }
    public string Log_file { get; set; }
    public string Config_Path { get; set; }
    public string Playlists_Profile_Path { get; set; }
    public string Current_Folder { get; set; }
    public string image_Cache_path { get; set; }
    public string App_Name { get; set; }
    public string Templates_Directory { get; set; }
    public string Playlist_Profile_Directory { get; set; }
    public string EQPreset_Profile_Directory { get; set; }
    public string VLC_Log_File { get; set; }
    public string LibVLC_Log_File { get; set; }
    public string Streamlink_Log_File { get; set; }
    public string Startup_Log_File { get; set; }
    public string Error_Log_File { get; set; }
    public string LocalMedia_Log_File { get; set; }
    public string Discord_Log_File { get; set; }
    public string Perf_Log_File { get; set; }
    public string Webview2_Log_File { get; set; }
    public string Setup_Log_File { get; set; }
    public string Threading_Log_File { get; set; }
    public string Uninstall_Log_File { get; set; }
    public string Friends_Profile_Directory { get; set; }
    public string App_Version { get; set; }
    public string App_Exe_Path { get; set; }
    public string App_Build { get; set; }
    public string logfile_directory { get; set; }
    public string SpotifyMedia_logfile { get; set; }
    public string YoutubeMedia_logfile { get; set; }
    public string TwitchMedia_logfile { get; set; }
    public string Tor_Log_File { get; set; }
    public string Download_logfile { get; set; }
    public bool Startup_perf_timer { get; set; }
    public string Temp_Folder { get; set; }
    public bool Dev_mode { get; set; }
    public bool Debug_mode { get; set; }
    public double Splash_Top { get; set; }
    public double Splash_Left { get; set; }
    public List<EQ_Preset> EQ_Presets { get; set; }
    public List<EQ_Band> EQ_Bands { get; set; }
    public string Installed_AppID { get; set; }
    public double MainWindow_Top { get; set; }
    public double MainWindow_Left { get; set; }
    public double MiniWindow_Top { get; set; }
    public double MiniWindow_Left { get; set; }
    public double VideoWindow_Top { get; set; }
    public double VideoWindow_Left { get; set; }
    public double LibraryWindow_Top { get; set; }
    public double LibraryWindow_Left { get; set; }
    public double BrowserWindow_Top { get; set; }
    public double BrowserWindow_Left { get; set; }
    public List<GlobalHotKey> GlobalHotKeys { get; set; }
    public bool EnableGlobalHotKeys { get; set; }
    public bool Enable_HighDPI { get; set; }
}
public class API
{
    public string Provider { get; set; }
    public string Redirect_URLs { get; set; }
    public string Auth_URLs { get; set; }
    public string ClientSecret { get; set; }
    public string ClientID { get; set; }
    public string ClientToken { get; set; }
}

public class Playlist : INotifyPropertyChanged
{
    public event PropertyChangedEventHandler PropertyChanged;

    public void RaisedOnPropertyChanged(string propertyName)
    {
        var handler = PropertyChanged;
        if (handler != null)
        {
            var e = new PropertyChangedEventArgs(propertyName);
            foreach (PropertyChangedEventHandler h in handler.GetInvocationList())
            {
                var synch = h.Target as ISynchronizeInvoke;
                if (synch != null && synch.InvokeRequired)
                    synch.Invoke(h, new object[] { this, e });
                else
                    h(this, e);
            }
        }
    }
    public string Name { get; set; }
    public string Playlist_name { get; set; }
    private int number;
    public int Number
    {
        get
        {
            return number;
        }
        set
        {
            number = value;
            RaisedOnPropertyChanged("Number");
        }
    }
    public string Title { get; set; }
    private string displayname;
    public string Display_Name
    {
        get
        {
            return displayname;
        }
        set
        {
            displayname = value;
            RaisedOnPropertyChanged("Display_Name");
        }
    }
    private string statusmsg;
    public string Status_Msg
    {
        get
        {
            return statusmsg;
        }
        set
        {
            statusmsg = value;
            RaisedOnPropertyChanged("Status_Msg");
        }
    }
    private string status;
    public string Status
    {
        get
        {
            return status;
        }
        set
        {
            status = value;
            RaisedOnPropertyChanged("Status");
        }
    }
    public string Playlist_ID { get; set; }
    public string Description { get; set; }
    public string Playlist_Path { get; set; }
    public string Playlist_URL { get; set; }
    private SerializableDictionary<int, Media> PlaylistTracks;
    public SerializableDictionary<int, Media> Playlist_Tracks
    {
        get
        {
            return PlaylistTracks;
        }
        set
        {
            PlaylistTracks = value;
            RaisedOnPropertyChanged("Playlist_Tracks");
        }
    }
    public string Source { get; set; }
    public string Image { get; set; }
    private string fontstyle;
    public string FontStyle
    {
        get
        {
            return fontstyle;
        }
        set
        {
            fontstyle = value;
            RaisedOnPropertyChanged("FontStyle");
        }
    }
    private string fontcolor;
    public string FontColor
    {
        get
        {
            return fontcolor;
        }
        set
        {
            fontcolor = value;
            RaisedOnPropertyChanged("FontColor");
        }
    }
    private string fontweight;
    public string FontWeight
    {
        get
        {
            return fontweight;
        }
        set
        {
            fontweight = value;
            RaisedOnPropertyChanged("FontWeight");
        }
    }
    private string fontsize;
    public string FontSize
    {
        get
        {
            return fontsize;
        }
        set
        {
            fontsize = value;
            RaisedOnPropertyChanged("FontSize");
        }
    }
    public string Margin { get; set; }
    private string tooltip;
    public string ToolTip
    {
        get
        {
            return tooltip;
        }
        set
        {
            tooltip = value;
            RaisedOnPropertyChanged("ToolTip");
        }
    }
    private string statusfontStyle;
    public string Status_FontStyle
    {
        get
        {
            return statusfontStyle;
        }
        set
        {
            statusfontStyle = value;
            RaisedOnPropertyChanged("Status_FontStyle");
        }
    }
    private string statusfontcolor;
    public string Status_FontColor
    {
        get
        {
            return statusfontcolor;
        }
        set
        {
            statusfontcolor = value;
            RaisedOnPropertyChanged("Status_FontColor");
        }
    }
    private string statusfontweight;
    public string Status_FontWeight
    {
        get
        {
            return statusfontweight;
        }
        set
        {
            statusfontweight = value;
            RaisedOnPropertyChanged("Status_FontWeight");
        }
    }
    private string statusfontsize;
    public string Status_FontSize
    {
        get
        {
            return statusfontsize;
        }
        set
        {
            statusfontsize = value;
            RaisedOnPropertyChanged("Status_FontSize");
        }
    }
    private string borderbrush;
    public string BorderBrush
    {
        get
        {
            return borderbrush;
        }
        set
        {
            borderbrush = value;
            RaisedOnPropertyChanged("BorderBrush");
        }
    }
    private string borderthickness;
    public string BorderThickness
    {
        get
        {
            return borderthickness;
        }
        set
        {
            borderthickness = value;
            RaisedOnPropertyChanged("BorderThickness");
        }
    }
    private string numbervisibility;
    public string NumberVisibility
    {
        get
        {
            return numbervisibility;
        }
        set
        {
            numbervisibility = value;
            RaisedOnPropertyChanged("NumberVisibility");
        }
    }
    private string numberfontsize;
    public string NumberFontSize
    {
        get
        {
            return numberfontsize;
        }
        set
        {
            numberfontsize = value;
            RaisedOnPropertyChanged("NumberFontSize");
        }
    }
    public bool AllowDrop { get; set; }
    public string Type { get; set; }
    public bool Enable_LiveAlert { get; set; }
    public string SortItemsBy { get; set; }
    public string SortItemsDirection { get; set; }
    public string Playlist_Date_Added { get; set; }
    private bool isexpanded;
    public bool IsExpanded
    {
        get
        {
            return isexpanded;
        }
        set
        {
            isexpanded = value;
            RaisedOnPropertyChanged("IsExpanded");
        }
    }
}

public class HotKeys : INotifyPropertyChanged
{

    public event PropertyChangedEventHandler? PropertyChanged;

    protected bool Set<T>(ref T? field, T? newValue = default, [CallerMemberName] string? propertyName = null)
    {
        if (EqualityComparer<T>.Default.Equals(field!, newValue!))
        {
            return false;
        }

        field = newValue;

        this.RaisedOnPropertyChanged(propertyName);

        return true;
    }

    protected virtual void RaisedOnPropertyChanged([CallerMemberName] string? propertyName = null)
    {
        this.PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(propertyName));
    }

    private HotKey? _mute;
    public HotKey Mute
    {
        get
        {
            return _mute;
        }
        set
        {
            _mute = value;
            RaisedOnPropertyChanged("Mute");
        }
    }
    private HotKey? _volup;
    public HotKey VolUp
    {
        get
        {
            return _volup;
        }
        set
        {
            _volup = value;
            RaisedOnPropertyChanged("VolUp");
        }
    }
    private HotKey? _voldown;
    public HotKey VolDown
    {
        get
        {
            return _voldown;
        }
        set
        {
            _voldown = value;
            RaisedOnPropertyChanged("VolDown");
        }
    }
}
