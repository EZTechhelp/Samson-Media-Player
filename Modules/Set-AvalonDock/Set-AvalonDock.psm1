<#
    .Name
    Set-AvalonDock

    .Version 
    0.1.1

    .SYNOPSIS
    Creates and updates AvalonDock content, context menus..etc

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for Samson Media Player

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>

#---------------------------------------------- 
#region Set-AvalonDock Function
#----------------------------------------------
function Set-AvalonDock {
  Param (
    $thisApp = $thisApp,
    $synchash = $synchash,
    [switch]$Startup,
    [switch]$Float_Topmost,
    [switch]$set_ContextMenu,
    [string]$Playlist_Profile_Directory = $thisApp.config.Playlist_Profile_Directory,
    [switch]$Verboselog
  )
  if($synchash.MediaViewAnchorable){
    try{
      $Synchash.Docking_Command_Scriptblock = {
        param($sender)
        try{ 
          $synchash = $synchash
          if($thisApp.Config.Dev_mode){write-ezlogs "Docking_Command_Sendertag $($sender.tag | out-string)" -showtime -Dev_mode}
          if($synchash.VideoView_Grid.Parent.Parent -and $synchash.Window.IsLoaded){
            $synchash.VideoView_Grid.Parent.Parent.Owner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($synchash.Window)
          }
          if($synchash.MediaViewAnchorable.isFloating -and ($sender.tag -eq 'VideoView' -or $sender.Uid -eq 'VideoView')){              
            $synchash.MediaViewAnchorable.Dock()
            $synchash.MediaViewAnchorable.Title = "Video Player"
            if($sender.Header){
              $sender.Header = 'UnDock'
            }
          }elseif($synchash.WebBrowserAnchorable.isFloating -and ($sender.tag -eq 'WebBrowser' -or $sender.Uid -eq 'WebBrowser')){
            write-ezlogs "[AVALONDOCK] >>>> Docking WebBrowserAnchorable"
            $Bookmarks_FlyoutControlWindow = Get-VisualParentUp -source $synchash.Bookmarks_FlyoutControl -type ([System.Windows.Window])
            if($Bookmarks_FlyoutControlWindow.Owner -and $synchash.Window.IsLoaded){
              write-ezlogs "| Setting Bookmarks_FlyoutControlWindow.Owner to main window"
              $Bookmarks_FlyoutControlWindow.Owner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($synchash.Window)
            }
            $synchash.WebBrowserAnchorable.Dock()
            if($sender.Header){
              $sender.Header = 'UnDock'
            }
          }elseif(($sender.tag -eq 'WebBrowser' -or $sender.Uid -match "WebBrowser_TabWindow_") -and $synchash."$($sender.Uid)".isFloating){
            $synchash."$($sender.Uid)".Dock()
            if($sender.Header){
              $sender.Header = 'UnDock'
            }
          }elseif($synchash.MediaLibraryAnchorable.isFloating -and ($sender.tag -eq 'MediaLibrary' -or $sender.Uid -eq 'MediaLibrary')){
            write-ezlogs "[AVALONDOCK] >>>> Docking MediaLibraryAnchorable"
            $synchash.MediaLibraryAnchorable.DockAsDocument()
            $synchash.LibraryButton_ToggleButton.isChecked = $false
            if($sender.Header){
              $sender.Header = 'UnDock'
            }
          }elseif($synchash.TorBrowserAnchorable.isFloating -and ($sender.tag -eq 'TorBrowser' -or $sender.Uid -eq 'TorBrowser')){
            write-ezlogs "[AVALONDOCK] >>>> Docking TorBrowserAnchorable"
            $synchash.TorBrowserAnchorable.DockAsDocument()
            if($sender.Header){
              $sender.Header = 'UnDock'
            }
          }elseif(($sender.tag -eq 'VideoView' -or $sender.Uid -eq 'VideoView')){
            if($sender.Header){
              $sender.Header = 'Dock'
            }
          }elseif(($sender.tag -eq 'WebBrowser' -or $sender.Uid -eq 'WebBrowser')){
            if($sender.Header){
              $sender.Header = 'Dock'
            }
          }elseif(($sender.tag -eq 'MediaLibrary' -or $sender.Uid -eq 'MediaLibrary')){
            if($sender.Header){
              $sender.Header = 'Dock'
            }
          }
          if($synchash.VideoView.Visibility -eq 'Visible' -and $synchash.MediaViewAnchorable){
            $synchash.MediaViewAnchorable.isSelected = $true
          }
          if(!$synchash.MiniPlayer_Viewer.isVisible){
            write-ezlogs ">>>> $($sender.Uid) floating window has closed, showing main window"
            $synchash.window.Opacity = 1
            $synchash.window.ShowActivated = $true
            $synchash.window.ShowInTaskbar = $true
            $synchash.Window.Show()
            $synchash.Window.Activate()
            if($SyncHash.Window.WindowState -eq 'Minimized'){
              $SyncHash.Window.WindowState = 'Normal'
            }
            if(!$synchash.VideoButton_ToggleButton.isChecked -and $synchash.VideoViewAirControl){
              write-ezlogs "| Video Viewer is closed, miniplayer is not open, hiding VideoViewAirControl"
              $synchash.VideoViewAirControl.Visibility = 'Collapsed'
            }
          }else{
            write-ezlogs ">>>> $($sender.Uid) floating window has closed, Miniplayer is loaded, not showing main player"
            $null = $synchash.MiniPlayer_Viewer.Activate()
            if((!$synchash.MediaViewAnchorable.isFloating -and !$synchash.Window.isVisible)  -and $synchash.VideoView -and !$synchash.MainWindow_IsClosing){
              write-ezlogs "| Hiding video view as video player is not floating and main player is not visible due to miniplayer being open"
              $synchash.VideoView.Visibility = 'Hidden'
              if($synchash.VideoViewAirControl){
                $synchash.VideoViewAirControl.Visibility = 'Collapsed'
              }             
            }
          }
        }catch{
          write-ezlogs "An exception occurred in Docking_Command routed event" -showtime -catcherror $_
        }
      }

      [System.Windows.RoutedEventHandler]$Synchash.Docking_Command = $Synchash.Docking_Command_Scriptblock

      [System.Windows.RoutedEventHandler]$Synchash.StayOnTop_Command = {
        param($sender)
        try{
          $synchash = $synchash
          if($synchash.VideoViewFloat.isVisible -and ($sender.tag -eq 'VideoView' -or $sender.Uid -eq 'VideoView')){
            if($synchash.VideoViewFloat.Topmost){
              $synchash.VideoViewFloat.Topmost = $false
            }else{
              $synchash.VideoViewFloat.Topmost = $true
            }
          }elseif($synchash.WebBrowserFloat.isVisible -and ($sender.tag -eq 'WebBrowser' -or $sender.Uid -eq 'WebBrowser')){
            if($synchash.WebBrowserFloat.Topmost){
              $synchash.WebBrowserFloat.Topmost = $false
            }else{
              $synchash.WebBrowserFloat.Topmost = $true
            }
          }elseif($synchash.MediaLibraryFloat.isVisible -and ($sender.tag -eq 'MediaLibrary' -or $sender.Uid -eq 'MediaLibrary')){
            if($synchash.MediaLibraryFloat.Topmost){
              $synchash.MediaLibraryFloat.Topmost = $false
            }else{
              $synchash.MediaLibraryFloat.Topmost = $true
            }
          }elseif($synchash.TorBrowserFloat.isVisible -and ($sender.tag -eq 'TorBrowser' -or $sender.Uid -eq 'TorBrowser')){
            if($synchash.TorBrowserFloat.Topmost){
              $synchash.TorBrowserFloat.Topmost = $false
            }else{
              $synchash.TorBrowserFloat.Topmost = $true
            }
          }
        }catch{
          write-ezlogs "An exception occurred in StayOnTop_Command event" -showtime -catcherror $_
        }
      }
      
      [System.Windows.RoutedEventHandler]$synchash.Docking_Close_Command = {
        param($sender)
        $synchash = $synchash
        try{
          if($synchash.MediaViewAnchorable.isFloating){
            $synchash.MediaViewAnchorable.Dock()
            $synchash.MediaViewAnchorable.Title = "Video Player"
          }
          if($synchash.WebBrowserAnchorable.isFloating){
            $synchash.WebBrowserAnchorable.Dock()
          }
          if($synchash.MediaLibraryAnchorable.isFloating){
            $synchash.MediaLibraryAnchorable.DockAsDocument()
            if($synchash.VideoView.Visibility -eq 'Visible' -and $synchash.MediaViewAnchorable){
              $synchash.MediaViewAnchorable.isSelected = $true
            }
          }                            
          if($synchash.VideoButton_ToggleButton.isChecked -and $thisApp.Config.Open_VideoPlayer){
            write-ezlogs ">>>> Docking Close command, closing Video Player" -showtime
            Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action Close
          }
          if($synchash."$($sender.Uid)".isFloating){
            $synchash."$($sender.Uid)".Dock()
          }            
        }catch{
          write-ezlogs 'An exception occurred in Docking_Close_Command event' -showtime -catcherror $_
        }
      }
      [System.Windows.RoutedEventHandler]$Synchash.Minimize_VideoView_Command = {
        param($sender)
        $synchash = $synchash
        try{
          if($synchash.VideoViewFloat.isVisible -and $sender.tag -eq 'VideoView' -and $synchash.VideoViewFloat.WindowState -ne 'Minimized'){
            $synchash.VideoViewFloat.WindowState = 'Minimized'
            $sender.Header = "Restore"
          }elseif($synchash.WebBrowserFloat.isVisible -and $sender.tag -eq 'WebBrowser' -and $synchash.WebBrowserFloat.WindowState -ne 'Minimized'){
            $synchash.WebBrowserFloat.WindowState = 'Minimized'
            $sender.Header = "Restore"
          }elseif($synchash."$($sender.uid)Float".isVisible -and $sender.Uid -match "WebBrowser_TabWindow_" -and $synchash."$($sender.uid)Float".WindowState -ne 'Minimized'){
            $synchash."$($sender.uid)Float".WindowState = 'Minimized'
            $sender.Header = "Restore"
          }elseif($sender.tag -eq 'VideoView' -and $synchash.VideoViewFloat.WindowState -eq 'Minimized'){     
            $sender.Header = "Minimize"
          }elseif($sender.tag -eq 'WebBrowserFloat' -and $synchash.WebBrowserFloat.WindowState -eq 'Minimized'){
            $synchash.WebBrowserFloat.WindowState = 'Normal'
            $sender.Header = "Minimize"
          }elseif($sender.tag -eq 'MediaLibrary' -and $synchash.MediaLibraryFloat.WindowState -ne 'Minimized'){
            $synchash.MediaLibraryFloat.WindowState = 'Minimized'
            $sender.Header = "Restore"
          }elseif($sender.tag -eq 'MediaLibrary' -and $synchash.MediaLibraryFloat.WindowState -eq 'Minimized'){
            $synchash.MediaLibraryFloat.WindowState = 'Normal'
            $sender.Header = "Restore"
          }elseif($sender.tag -eq 'TorBrowser' -and $synchash.TorBrowserFloat.WindowState -ne 'Minimized'){
            $synchash.TorBrowserFloat.WindowState = 'Minimized'
            $sender.Header = "Restore"
          }elseif($sender.tag -eq 'TorBrowser' -and $synchash.TorBrowserFloat.WindowState -eq 'Minimized'){
            $synchash.TorBrowserFloat.WindowState = 'Normal'
            $sender.Header = "Restore"
          }       
        }catch{
          write-ezlogs 'An exception occurred in Minimize_VideoView_Command' -showtime -catcherror $_
        }
      }
      $Synchash.FloatingWindow_LoadedScriptblock = {
        param($sender)
        try{
          $synchash = $synchash
          write-ezlogs ">>>> $($sender.name) window has loaded" -showtime -loglevel 2
          if($sender.name -eq 'VideoViewWindow'){
            if($sender.icon -ne $synchash.Window.icon){
              $sender.icon = $synchash.Window.icon
              $sender.icon.freeze()
            }
            if($synchash.VideoButton_ToggleButton.isChecked -and $thisApp.Config.Open_VideoPlayer -and !$synchash.MiniPlayer_Viewer.isVisible){
              write-ezlogs ">>>> Video player has been undocked to new window, closing Docking Manager View" -showtime
              Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action Close
            }elseif($synchash.MiniPlayer_Viewer.isVisible){
              #write-ezlogs ">>>> Video player has been undocked to new window, miniplayer is open, taking no action" -showtime
              write-ezlogs ">>>> Video player has been undocked to new window, miniplayer is open, calling show/hide to on main window to update visual tree" -showtime -warning
              #Trick to prerender window without showing it - Set opacity to 0, show to render, then hide
              $synchash.window.ShowActivated = $false #Prevent window from activating/taking focus while rendering
              $synchash.window.ShowInTaskbar = $false
              $synchash.window.Opacity = 0
              [void]$synchash.window.Show()
              #$synchash.window.Hide()
              #$synchash.window.Opacity = 1
              #$synchash.window.ShowActivated = $true
              #$synchash.window.ShowInTaskbar = $true
            }
          }
        }catch{
          write-ezlogs "An exception occurred in FloatingWindow_LoadedCommand event" -showtime -catcherror $_
        }
      }
      $Synchash.FloatingWindow_StateChangedScriptblock = {
        param($sender)
        try{
          $synchash = $synchash
          if($sender.name -eq 'VideoViewWindow'){
            if(!$synchash.VideoViewFloat.IsHitTestVisible){
              write-ezlogs ">>>> Setting videoviewfloat IsHitTestVisible to true"
              $synchash.VideoViewFloat.IsHitTestVisible = $true
            }
            if($synchash.VideoViewFloat.WindowState -eq 'Maximized'){
              $style =  $synchash.DockingManager.TryFindResource('LayoutAnchorableFloatingWindowControl')
              if($synchash.VideoViewFloat.style -ne $style){
                write-ezlogs "| Setting videoviewfloat style"
                $synchash.VideoViewFloat.style = $style
              }
              if($synchash.VideoViewFloat.ResizeMode -ne 'CanResize'){
                write-ezlogs ">>>> videoviewfloat is Maximized - Setting videoviewfloat ResizeMode to CanResize"
                $synchash.VideoViewFloat.Visibility = 'Collapsed'
                $synchash.VideoViewFloat.WindowStyle = 'none'
                $synchash.VideoViewFloat.ResizeMode = 'CanResize'
                $synchash.VideoViewFloat.Visibility = 'Visible'
                $synchash.VideoViewFloat.WindowState = 'Maximized'
              }
              if($synchash.VideoView_LargePlayer_Icon.Kind -ne 'ScreenNormal'){
                $synchash.VideoView_LargePlayer_Icon.Kind = 'ScreenNormal'
              }
            }elseif($synchash.VideoViewFloat.WindowState -ne 'Maximized'){
              $style =  $synchash.DockingManager.TryFindResource('LayoutAnchorableFloatingWindowControl')
              if($synchash.VideoViewFloat.style -ne $style){
                write-ezlogs "| Setting videoviewfloat style"
                $synchash.VideoViewFloat.style = $style
              }
              if($synchash.VideoView_LargePlayer_Icon.Kind -ne 'ScreenFull'){
                $synchash.VideoView_LargePlayer_Icon.Kind = 'ScreenFull'
              }
              if($synchash.VideoViewFloat.ResizeMode -ne 'CanResize'){
                write-ezlogs ">>>> Setting videoviewfloat ResizeMode to CanResize"
                #$synchash.VideoViewFloat.WindowStyle = 'SingleBorderWindow'
                $synchash.VideoViewFloat.ResizeMode = 'CanResize'
                #$synchash.VideoViewFloat.Visibility = 'Visible'
              }
            }
            $LibVLCSharpWPFForegroundWindow = Get-VisualParentUp -source $synchash.VideoView_Grid -type ([System.Windows.Window])
            if($synchash.MediaViewAnchorable.isFloating -and $LibVLCSharpWPFForegroundWindow){
              $FloatingWindowOwner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($sender)
              if($LibVLCSharpWPFForegroundWindow -and $FloatingWindowOwner){
                write-ezlogs ">>>> Setting Libvlcsharp.Wpf.ForegroundWindow.Owner to VideoView floating window" -Dev_mode
                $LibVLCSharpWPFForegroundWindow.Owner = $FloatingWindowOwner
              }
            }
            if($synchash.VideoViewAirControl.front -and $synchash.MediaViewAnchorable.isFloating){
              $VideoViewAirControl = Get-VisualParentUp -source $synchash.VideoViewAirControl.front -type ([System.Windows.Window])
              if($VideoViewAirControl){
                $FloatingWindowOwner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($sender)
                if($VideoViewAirControl -and $FloatingWindowOwner){
                  write-ezlogs ">>>> Setting VideoViewAirControl.front.parent.parent.Owner to VideoView floating window" -Dev_mode
                  $VideoViewAirControl.Owner = $FloatingWindowOwner
                }
              }
            }
          }elseif($sender.name -eq "$($sender.Uid)Float"){
            write-ezlogs ">>>> StateChanged Event for: $($sender.name) -- State: $($sender.WindowState)"
            if(!$sender.IsHitTestVisible){
              write-ezlogs ">>>> Setting $($sender.Name) IsHitTestVisible to true"
              $sender.IsHitTestVisible = $true
            }                         
            if($sender.WindowState -eq 'Maximized'){
              $style =  $synchash.DockingManager.TryFindResource('LayoutAnchorableFloatingWindowControl')
              if($sender.style -ne $style){
                write-ezlogs "| Setting $($sender.Name) style"
                $sender.style = $style
              }
              if($Sender.Name -eq 'WebBrowserFloat' -and $synchash.WebBrowser.CoreWebView2 -and !$synchash.WebBrowser.IsVisible){
                Write-EZLogs "| WebBrowser window is now maximized, unhiding WebBrowser: - isSupsended: $($synchash.WebBrowser.CoreWebview2.IsSuspended)" -logtype Webview2
                $synchash.WebBrowser.Visibility = 'Visible'  
              }
              if($Sender.Name -eq 'WebBrowserFloat' -and $synchash.WebBrowser.CoreWebView2.ContainsFullScreenElement){
                if($sender.ResizeMode -ne 'NoResize' -and $synchash.WebBrowser.CoreWebView2.ContainsFullScreenElement){
                  write-ezlogs ">>>> $($sender.Name) is Maximized - Setting $($sender.Name) ResizeMode to CanResize"
                  $sender.Visibility = 'Collapsed'
                  $sender.WindowStyle = 'none'
                  $sender.ResizeMode = 'NoResize'
                  $sender.Visibility = 'Visible'
                  $sender.WindowState = 'Maximized'
                }
              }
            }elseif($sender.WindowState -ne 'Maximized'){   
              $synchash.WebBrowserGrid.Tag = $true
              $style =  $synchash.DockingManager.TryFindResource('LayoutAnchorableFloatingWindowControl')     
              if($sender.style -ne $style){
                write-ezlogs "| Setting $($sender.Name) style"
                $sender.style = $style
              }
              if($sender.ResizeMode -ne 'CanResize'){
                write-ezlogs ">>>> Setting $($sender.Name) ResizeMode to CanResize"
                $sender.ResizeMode = 'CanResize'
              }
              if(!$synchash.MainWindow_IsClosing -and $Sender.Name -eq 'WebBrowserFloat' -and $synchash.WebBrowser.CoreWebView2){
                if($sender.WindowState -eq 'Minimized' -and $synchash.WebBrowser.IsVisible){
                  Write-EZLogs "| WebBrowser is minimized, hiding and executing TrySuspendAsync()" -logtype Webview2
                  $synchash.WebBrowser.Visibility = 'Hidden'
                  $synchash.WebBrowser.CoreWebView2.TrySuspendAsync()
                }elseif($sender.WindowState -eq 'Normal'){
                  Write-EZLogs "| WebBrowser window is now visible, unhiding WebBrowser: - isSupsended: $($synchash.WebBrowser.CoreWebview2.IsSuspended)" -logtype Webview2
                  $synchash.WebBrowser.Visibility = 'Visible'
                }
              }
            }
          }else{
            $style = $synchash.DockingManager.TryFindResource('LayoutAnchorableFloatingWindowControl')     
            if($sender.style -ne $style){
              write-ezlogs "| Setting floating window style for: $($sender.Name)"
              $sender.style = $style
            }
          }
        }catch{
          write-ezlogs "An exception occurred in $($sender.name) StateChanged event" -showtime -catcherror $_
        }
      }
      $synchash.FloatingWindow_KeyboardFocusScriptblock = {
        Param($sender,[System.Windows.DependencyPropertyChangedEventArgs]$e)
        try{
          if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Window with name: $($sender.Name) -- and title: $($sender.Title) -- keyboard focus changed -- OldValue: $($e.OldValue) -- NewValue: $($e.NewValue)" -Dev_mode}
          if($sender.name -eq 'VideoViewWindow' -and $synchash.MediaViewAnchorable.isFloating -and $synchash.VideoViewFloat.isVisible){
            $LibVLCSharpWPFForegroundWindow = Get-VisualParentUp -source $synchash.VideoView_Grid -type ([System.Windows.Window])
            if($synchash.MediaViewAnchorable.isFloating -and $LibVLCSharpWPFForegroundWindow){
              $FloatingWindowOwner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($sender)
              if($LibVLCSharpWPFForegroundWindow -and $FloatingWindowOwner){
                write-ezlogs ">>>> Setting Libvlcsharp.Wpf.ForegroundWindow.Owner to VideoView floating window" -Dev_mode
                $LibVLCSharpWPFForegroundWindow.Owner = $FloatingWindowOwner
              }
            }
            if($synchash.VideoViewAirControl.front){
              $VideoViewAirControl = Get-VisualParentUp -source $synchash.VideoViewAirControl.front -type ([System.Windows.Window])
              if($VideoViewAirControl){
                if($synchash.MediaViewAnchorable.isFloating -and $synchash.VideoViewFloat.isVisible){
                  $FloatingWindowOwner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($synchash.VideoViewFloat)
                }elseif($synchash.Window.isLoaded){
                  $FloatingWindowOwner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($synchash.Window)
                }
                if($VideoViewAirControl -and $FloatingWindowOwner){
                  write-ezlogs "| Setting VideoViewAirControl window owner to $($FloatingWindowOwner.Name)" -showtime -Dev_mode
                  $VideoViewAirControl.Owner = $FloatingWindowOwner
                }
              }
            }
          }
        }catch{
          write-ezlogs "An exception occurred in $($sender.name) PreviewGotKeyboardFocus event" -showtime -catcherror $_
        }
      }
      $Synchash.FloatingWindow_ClosingScriptblock = {
        param($sender)
        try{
          if($sender.name -eq 'VideoViewWindow'){
            if($synchash.VideoView_Grid.Parent.Parent -and $synchash.Window.IsLoaded){
              write-ezlogs ">>>> Clearing focus for VideoView_Grid.Parent.Parent and clearing window owner"
              [void][System.Windows.Input.FocusManager]::SetFocusedElement([System.Windows.Input.FocusManager]::GetFocusScope($synchash.VideoView_Grid.Parent.Parent),$Null)
              $synchash.VideoView_Grid.Parent.Parent.Owner = $null
              <#              if(!$synchash.VideoButton_ToggleButton.isChecked -and $thisApp.Config.Open_VideoPlayer -and !$synchash.MiniPlayer_Viewer.isVisible){
                  write-ezlogs ">>>> Floating Video player has been docked, opening Docking Manager View" -showtime
                  Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action Open
              }#>
            }
            ######
            #TODO: Setting video view to visible here potentially contributes towards Layout measurement override crash if video view set to collapsed
            #Mostly only occurs if miniplayer is open but can still occur even if not
            #Does not occur if video view is hidden. If collapsed, it basically sets the height/width to 0 (and any controls inside it, specifically airhack and those used to get around wpf airspace issues)
            #If set to collapsed then set back to visible, various layout measurement events trigger but if the height and width is 0 (due to being collapsed) we get the crash
            #See related code/comments in Stop-Media and/or Set-WPFControls - Reset-MainPlayer
            #This likely needs a thorough refactor or rethinking to avoid this situation
            if(!$synchash.MainWindow_IsClosing -and $synchash.MiniPlayer_Viewer.isVisible -and $synchash.VideoView.Visibility -ne 'Hidden'){
              write-ezlogs ">>>> Videoview floating window is closing, miniplayer is open, videoview visibility is: $($synchash.VideoView.Visibility) -- hiding VideoView" -showtime -loglevel 2
              $synchash.VideoView.Visibility = 'Hidden'
            }
            ######
            if($synchash.VideoViewAirControl.front.parent.parent -is [System.Windows.Window] -and $synchash.Window.IsLoaded){
              write-ezlogs ">>>> Clearing focus for VideoViewAirControl.front.parent.parent and setting owner to main window"
              [void][System.Windows.Input.FocusManager]::SetFocusedElement([System.Windows.Input.FocusManager]::GetFocusScope($synchash.VideoViewAirControl.front.parent.parent),$Null)
              $synchash.VideoViewAirControl.front.parent.parent.Owner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($synchash.Window)
              if($synchash.VideoViewAirControl -and $synchash.VLC_Grid.Children -contains $synchash.VideoViewAirControl){
                Write-EZLogs '| Temporarily Removing VideoViewAirControl from VLC_Grid while VideoViewWindow is closing'
                [void]$synchash.VLC_Grid.children.Remove($synchash.VideoViewAirControl)
              }
            }
            [void][System.Windows.Input.Keyboard]::ClearFocus()
          }                                                                   
        }catch{
          write-ezlogs "An exception occurred in $($sender.name) Closing event" -showtime -catcherror $_
        }
      }
      $Synchash.FloatingWindow_UnLoadedScriptblock = {
        param($sender)
        try{
          #$element = [System.WeakReference]::new($sender).Target
          write-ezlogs ">>>> Floating window $($sender.Name) has unloaded - Top: $($Sender.Top) - Left: $($Sender.Left)" -showtime -loglevel 2
          $sender.Remove_StateChanged($Synchash.FloatingWindow_StateChangedScriptblock)
          $null = Get-EventHandlers -Element $sender -RoutedEvent ([System.Windows.Window]::PreviewGotKeyboardFocusEvent) -RemoveHandlers -VerboseLog
          $null = Get-EventHandlers -Element $sender -RoutedEvent ([System.Windows.Window]::SizeChangedEvent) -RemoveHandlers -VerboseLog
          $null = Get-EventHandlers -Element $sender -RoutedEvent ([System.Windows.Window]::PreviewGotKeyboardFocusEvent) -RemoveHandlers -VerboseLog
          $null = Get-EventHandlers -Element $sender -RoutedEvent ([System.Windows.Window]::loadedEvent) -RemoveHandlers
          $null = Get-EventHandlers -Element $sender -RoutedEvent ([System.Windows.Window]::UnloadedEvent) -RemoveHandlers
          if($sender.name -eq 'VideoViewWindow'){
            $sender.Remove_Closing($Synchash.FloatingWindow_ClosingScriptblock)
            if(!$synchash.MainWindow_IsClosing -and $synchash.VideoViewAirControl -and $synchash.VLC_Grid.Children -notcontains $synchash.VideoViewAirControl){
              Write-EZLogs '| Re-adding VideoViewAirControl to VLC_Grid'
              [void]$synchash.VLC_Grid.AddChild($synchash.VideoViewAirControl)
            }
            if(!$synchash.MainWindow_IsClosing -and $synchash.VideoView_Grid.Parent.Parent -and $synchash.Window.IsLoaded){
              write-ezlogs "| Setting videoview parent window Owner to main window"
              $synchash.VideoView_Grid.Parent.Parent.Owner = $Null
              $synchash.VideoView_Grid.Parent.Parent.Owner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($synchash.Window)
            }
            if(!$synchash.MainWindow_IsClosing -and $synchash.MiniPlayer_Viewer.isVisible -and $synchash.VideoView.Visibility -notin 'Hidden','Collapsed'){
              write-ezlogs ">>>> Miniplayer is visible, hiding VideoView and VideoViewAirControl" -showtime -loglevel 2
              $synchash.VideoView.Visibility = 'Collapsed'
              if($synchash.VideoViewAirControl){
                $synchash.VideoViewAirControl.Visibility = 'Collapsed'
              }
            }
            $synchash.VideoViewFloat = $Null
            $synchash.Remove('VideoViewFloat')
            if($thisApp.Config.Remember_Window_Positions){
              $thisapp.config.VideoWindow_Top = $Sender.Top
              $thisapp.config.VideoWindow_Left = $Sender.Left
            }
          }elseif($sender.name){
            $webview2 = $($sender.Uid) -replace 'TabWindow','Webview2'
            if($sender.name -ne 'WebBrowserFloat' -and $synchash."$webview2" -and $synchash."$webview2".isVisible -eq $false){    
              if($synchash."$webview2".CoreWebview2 -and $synchash."$webview2" -is [System.IDisposable]){
                write-ezlogs " | Disposing Webview2 instance $($webview2)" -loglevel 2
                $synchash."$webview2".dispose()
              }
            }
            if($Sender.Name -eq 'WebBrowserFloat'){
              if($thisApp.Config.Remember_Window_Positions){
                $thisapp.config.BrowserWindow_Top = $Sender.Top
                $thisapp.config.BrowserWindow_Left = $Sender.Left
              }
            }
            if($Sender.Name -eq 'MediaLibraryFloat'){
              if($thisApp.Config.Remember_Window_Positions){
                $thisapp.config.LibraryWindow_Top = $Sender.Top
                $thisapp.config.LibraryWindow_Left = $Sender.Left
              }
              if($synchash.LibraryButton_ToggleButton.isChecked){
                $synchash.LibraryButton_ToggleButton.isChecked = $false
              }
            }
          }
          if($synchash.MiniPlayer_Viewer.isVisible -and $synchash.VideoButton_ToggleButton.isChecked){
            write-ezlogs "| Miniplayer is open, closing main window video tray"
            Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action Close
          }                                                                 
        }catch{
          write-ezlogs "An exception occurred in VideoViewFloat.add_loaded" -showtime -catcherror $_
        }
      }

      #For use with Avalondock context menu playlist open/close commands
      [System.Windows.RoutedEventHandler]$synchash.PlaylistsView_Command = {
        param($sender)
        try{
          if($synchash.VideoView_Playlists_Button.isChecked){
            $synchash.VideoView_Playlists_Button.isChecked = $false
            if($sender.Header){
              $sender.Header = 'Open Playlists'
            }
          }else{
            $synchash.VideoView_Playlists_Button.isChecked = $true
            if($sender.Header){
              $sender.Header = 'Close Playlists'
            }
          } 
        }catch{
          write-ezlogs "An exception occurred in PlaylistsView_Command" -showtime -catcherror $_
        }
      }

      if($synchash.DockingManager.AnchorableContextMenu){
        [System.Windows.RoutedEventHandler]$synchash.AnchorableContextMenu = {
          param($sender,[System.Windows.Input.MouseButtonEventArgs]$e)
          $synchash = $synchash
          try{
            if($thisApp.Config.Dev_mode){
              write-ezlogs "AnchorableContextMenu e.OriginalSource.name: $($e.OriginalSource.name | out-string)" -Dev_mode
              write-ezlogs "AnchorableContextMenu e.OriginalSource: $($e.OriginalSource | out-string)" -Dev_mode
              write-ezlogs "AnchorableContextMenu synchash.Comments_Grid: $($synchash.Comments_Grid | out-string)" -Dev_mode
              write-ezlogs "chat_column.width: $($synchash.chat_column.width)" -Dev_mode
            }
            $items = [System.Collections.Generic.List[object]]::new()
            if(($e.OriginalSource.Name -eq 'MediaPlayer_Grid' -or $e.OriginalSource.Name -eq 'VideoViewTransparentBackground' -or $e.OriginalSource.Name -eq 'VideoViewOverlayStackpanel' -or $e.OriginalSource.Name -eq 'VideoViewOverlayStackpanelRight'  -or $e.OriginalSource.Name -eq 'VideoViewOverlayStackpanelLeft' -or $e.OriginalSource.Name -eq 'VideoView_Overlay_Grid') -and $synchash.MediaViewAnchorable.isFloating){
              $e.handled = $true
              $Open_App = @{
                'Header' = 'Dock'
                'Color' = 'White'
                'Icon_Color' = 'White'
                'Command' = $Synchash.Docking_Command
                'tag' = $synchash.MediaViewAnchorable.contentid
                'Icon_kind' = 'DockWindow'
                'Enabled' = $true
                'IsCheckable' = $false
              }
              $null = $items.Add($Open_App)
              $StayOnTop = @{
                'Header' = "Stay On Top"
                'Color' = 'White'
                'Icon_Color' = 'White'
                'tag' = $synchash.MediaViewAnchorable.contentid
                'Command' = $Synchash.StayOnTop_Command
                'Icon_kind' = 'PinOutline'
                'Enabled' = $true
                'IsCheckable' = $true
                'IsChecked' = $synchash.VideoViewFloat.Topmost
              }
              $null = $items.Add($StayOnTop)
              if($synchash.VideoViewFloat){
                if($synchash.VideoViewFloat.WindowState -eq 'Maximized'){
                  $iconkind = 'FullscreenExit'
                  $Header = 'Exit Fullscreen'
                }else{
                  $Header = 'Fullscreen'
                  $iconkind = 'FullscreenExit'
                }
                $Maximize_VideoView = @{
                  'Header' = "FullScreen"
                  'Color' = 'White'
                  'tag' = $synchash.MediaViewAnchorable.contentid
                  'Icon_Color' = 'White'
                  'Command' = $synchash.FloatFullScreen_Command
                  'Icon_kind' = $iconkind
                  'Enabled' = $true
                  'IsCheckable' = $false
                }
                $null = $items.Add($Maximize_VideoView)
              }
              $Minimize_VideoView = @{
                'Header' = "Minimize"
                'Color' = 'White'
                'tag' = $synchash.MediaViewAnchorable.contentid
                'Icon_Color' = 'White'
                'Command' = $Synchash.Minimize_VideoView_Command
                'Icon_kind' = 'WindowMinimize'
                'Enabled' = $true
                'IsCheckable' = $false
              }
              $null = $items.Add($Minimize_VideoView)
              if($synchash.TrayPlayerQueueFlyout.IsOpen){
                $Header = 'Close Playlists'
                $icon = 'AnimationPlay'
              }else{
                $Header = 'Open Playlists'
                $icon = 'AnimationPlayOutline'
              }
              $Playlists_View = @{
                'Header' = $Header
                'Color' = 'White'
                'Icon_Color' = 'White'
                'Command' = $synchash.PlaylistsView_Command
                'Icon_kind' = $icon
                'Enabled' = $true
                'IsCheckable' = $false
              }
              $null = $items.Add($Playlists_View)
              if($synchash.chat_WebView2.Visibility -eq 'Visible' -or $synchash.Comments_Grid.Visibility -eq 'Visible'){
                $chatHeader = 'Close Chat View'
                $chaticon = 'ChatRemove'
              }else{
                $chatHeader = 'Open Chat View'
                $chaticon = 'Chat'
              }
              $Chat_View = @{
                'Header' = $chatHeader
                'Color' = 'White'
                'tag' = $synchash.MediaViewAnchorable.contentid
                'Icon_Color' = 'White'
                'Command' = $synchash.ChatView_Command
                'Icon_kind' = $chaticon
                'Enabled' = $synchash.Chat_View_Button.isEnabled
                'IsCheckable' = $false
              }
              $null = $items.Add($Chat_View)
            }elseif($e.OriginalSource.Name -eq 'MediaPlayer_Grid' -or $e.OriginalSource.Name -eq 'MediaLibrary_Grid' -or $e.OriginalSource.Text -eq 'Video Player' -or $e.OriginalSource.Text -eq 'Media Library' -or $e.OriginalSource.Text -eq 'Web Browser' -or ($e.OriginalSource.Text -and [string]($e.OriginalSource.Text).StartsWith('Web Browser - ')) -or $e.OriginalSource.Text -eq 'Tor Browser' -or $e.OriginalSource.Name -eq 'VideoViewTransparentBackground' -or $e.OriginalSource.Name -eq 'VideoViewOverlayStackpanel' -or $e.OriginalSource.Name -eq 'VideoViewOverlayStackpanelRight'  -or $e.OriginalSource.Name -eq 'VideoViewOverlayStackpanelLeft' -or $e.OriginalSource.Name -eq 'VideoView_Overlay_Grid'){
              switch($e.OriginalSource.Name,$e.OriginalSource.Text)
              {
                { @('Media Library','MediaLibrary_Grid') -contains $_ } {
                  $VideoPlayer = $false
                  $tag = $synchash.MediaLibraryAnchorable.contentid
                  if($synchash.MediaLibraryAnchorable.isFloating){
                    $DockHeader = 'Dock'
                  }else{
                    $Dockheader = 'Undock'
                  }
                }
                { @('Tor Browser') -contains $_ } {
                  $VideoPlayer = $false
                  $tag = $synchash.TorBrowserAnchorable.contentid
                  if($synchash.TorBrowserAnchorable.isFloating){
                    $DockHeader = 'Dock'
                  }else{
                    $Dockheader = 'Undock'
                  }
                }
                { $_ -eq 'Web Browser' -or ($_ -and $_.startswith('Web Browser -')) } {
                  $VideoPlayer = $false
                  $tag = $synchash.WebBrowserAnchorable.contentid          
                  if($synchash.WebBrowserAnchorable.isFloating){
                    $DockHeader = 'Dock'
                  }else{
                    $Dockheader = 'Undock'
                  }
                }
                default {
                  $tag = $synchash.MediaViewAnchorable.contentid
                  $VideoPlayer = $true
                  if($synchash.MediaViewAnchorable.isFloating){
                    $DockHeader = 'Dock'
                  }else{
                    $Dockheader = 'Undock'
                  }
                }
              }
              $Open_App = @{
                'Header' = $DockHeader
                'Color' = 'White'
                'Icon_Color' = 'White'
                'Command' = $synchash.Float_Command
                'tag' = $tag
                'Icon_kind' = 'DockWindow'
                'Enabled' = $true
                'IsCheckable' = $false
              }
              $null = $items.Add($Open_App)
              if($VideoPlayer){
                $Maximize_VideoView = @{
                  'Header' = "FullScreen"
                  'Color' = 'White'
                  'tag' = $tag
                  'Icon_Color' = 'White'
                  'Command' = $synchash.FloatFullScreen_Command
                  'Icon_kind' = 'Fullscreen'
                  'Enabled' = $true
                  'IsCheckable' = $false
                }
                $null = $items.Add($Maximize_VideoView)
                if($synchash.TrayPlayerQueueFlyout.IsOpen){
                  $Header = 'Close Playlists'
                  $icon = 'AnimationPlay'
                }else{
                  $Header = 'Open Playlists'
                  $icon = 'AnimationPlayOutline'
                }
                $Playlists_View = @{
                  'Header' = $Header
                  'Color' = 'White'
                  'Icon_Color' = 'White'
                  'Command' = $synchash.PlaylistsView_Command
                  'Icon_kind' = $icon
                  'Enabled' = $true
                  'IsCheckable' = $false
                }
                $null = $items.Add($Playlists_View)
                if($synchash.chat_WebView2.Visibility -eq 'Visible' -or $synchash.Comments_Grid.Visibility -eq 'Visible'){
                  $chatHeader = 'Close Chat View'
                  $chaticon = 'ChatRemove'
                }else{
                  $chatHeader = 'Open Chat View'
                  $chaticon = 'Chat'
                }
                $Chat_View = @{
                  'Header' = $chatHeader
                  'Color' = 'White'
                  'tag' = $synchash.MediaViewAnchorable.contentid
                  'Icon_Color' = 'White'
                  'Command' = $synchash.ChatView_Command
                  'Icon_kind' = $chaticon
                  'Enabled' = $synchash.Chat_View_Button.isEnabled
                  'IsCheckable' = $false
                }
                $null = $items.Add($Chat_View)
              }
            }else{
              $e.handled = $false
              return
            }
            $synchash.DockingManager.AnchorableContextMenu = $Null
            $synchash.DockingManager.ContextMenu = $Null
            if($VideoPlayer){
              if($synchash.VideoViewTransparentBackground.ContextMenu -eq $null){
                Add-WPFMenu -control $synchash.VideoViewTransparentBackground -items $items -AddContextMenu -sourceWindow $synchash
              }
              if($synchash.VideoViewOverlayStackpanel.ContextMenu -eq $null){
                Add-WPFMenu -control $synchash.VideoViewOverlayStackpanel -items $items -AddContextMenu -sourceWindow $synchash
              }
              if($synchash.VideoViewOverlayStackpanelRight.ContextMenu -eq $null){
                Add-WPFMenu -control $synchash.VideoViewOverlayStackpanelRight -items $items -AddContextMenu -sourceWindow $synchash
              }
              if($synchash.VideoViewOverlayStackpanelLeft.ContextMenu -eq $null){
                Add-WPFMenu -control $synchash.VideoViewOverlayStackpanelLeft -items $items -AddContextMenu -sourceWindow $synchash
              }
              if($synchash.VideoView_Overlay_Grid.ContextMenu -eq $null){
                Add-WPFMenu -control $synchash.VideoView_Overlay_Grid -items $items -AddContextMenu -sourceWindow $synchash
              }
            }
            Add-WPFMenu -control $synchash.DockingManager -items $items -AddContextMenu -sourceWindow $synchash
          }catch{
            write-ezlogs "An exception occurred executing AnchorableContextMenu" -showtime -catcherror $_
          }
        }
        $AnchorableContextMenu_Timer = [System.Windows.Threading.DispatcherTimer]::new([System.Windows.Threading.DispatcherPriority]::ApplicationIdle)
        $AnchorableContextMenu_Timer_ScriptBlock = {
          try{
            $null =  $synchash.DockingManager.RemoveHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.AnchorableContextMenu)
            $synchash.DockingManager.AnchorableContextMenu = $Null
            $synchash.DockingManager.DocumentContextMenu = $Null
            $null = $synchash.DockingManager.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.AnchorableContextMenu)
            $null = $synchash.VideoViewOverlayStackpanel.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.AnchorableContextMenu)
            $null = $synchash.VideoViewTransparentBackground.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.AnchorableContextMenu)
            $null = $synchash.VideoViewOverlayStackpanelRight.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.AnchorableContextMenu)
            $null = $synchash.VideoViewOverlayStackpanelLeft.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.AnchorableContextMenu)
            $null = $synchash.VideoView_Overlay_Grid.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.AnchorableContextMenu)
            $null = $synchash.VideoViewTransparentBackground.AddHandler([System.Windows.Controls.Button]::PreviewMouseLeftButtonDownEvent,$synchash.VideoViewMouseLeftButtonDown_command)
            $null = $synchash.VideoView_Queue.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
            $null = $synchash.VideoView_Queue.RemoveHandler([System.Windows.Controls.Button]::MouseDoubleClickEvent,$synchash.PlayMedia_Command)
            $null = $synchash.VideoView_Queue.AddHandler([System.Windows.Controls.Button]::MouseDoubleClickEvent,$synchash.PlayMedia_Command)    
          }catch{
            write-ezlogs "An exception occurred executing AnchorableContextMenu" -showtime -catcherror $_
          }finally{
            $this.stop()
            $this.Remove_Tick($AnchorableContextMenu_Timer_ScriptBlock)
            $AnchorableContextMenu_Timer = $Null
          }     
        }
        $AnchorableContextMenu_Timer.add_tick($AnchorableContextMenu_Timer_ScriptBlock)
        $AnchorableContextMenu_Timer.start()
      }

      [System.EventHandler]$Synchash.FloatingPropertiesUpdated_Command = {
        param($sender)
        try{
          $synchash = $synchash
          $windowstyle = $synchash.DockingManager.TryFindResource('LayoutAnchorableFloatingWindowControl')
          $floatingwindow = $synchash.DockingManager.FloatingWindows.GetEnumerator() | Where-Object {$_.content.content.children.items.contentid -eq $sender.contentid}
          $FloatingWindow_title = $floatingwindow.content.content.children.items.title
          $FloatingWindow_contentid = $floatingwindow.content.content.children.items.contentid
          if($FloatingWindow_contentid -eq 'VideoView'){
            try{
              if($floatingwindow.OwnedByDockingManagerWindow){
                $floatingwindow.OwnedByDockingManagerWindow = $false
              }                          
              if(!$floatingwindow.ShowInTaskbar){
                $floatingwindow.ShowInTaskbar = $true
              }
              if(!$floatingwindow.AllowMinimize){
                $floatingwindow.AllowMinimize = $true
              }
              $tag = [PSCustomObject]@{
                'Now_Playing_Label' = $synchash.Now_Playing_Label.DataContext
                'Now_Playing_Label_Visibility' = $synchash.Now_Playing_Label.Visibility
                'Now_Playing_Sep1_Label' = $synchash.Now_Playing_Sep1_Label.content
                'Now_Playing_Sep2_Label' = $synchash.Now_Playing_Sep2_Label.content 
                'Now_Playing_Title_Label' = $synchash.Now_Playing_Title_Label.DataContext
                'Now_Playing_Artist_Label' = $synchash.Now_Playing_Artist_Label.DataContext
                'Name' = 'VideoView'
              }
              if($synchash.MediaViewAnchorable.ToolTip -ne $tag){
                $synchash.MediaViewAnchorable.ToolTip = $tag
                if(-not [string]::IsNullOrEmpty($synchash.Now_Playing_Label.DataContext) -and $synchash.Now_Playing_Label.Visibility -eq 'Visible'){
                  $PlayingStatus = $synchash.Now_Playing_Label.DataContext
                  $PlayingSep = ' - '
                }else{
                  $PlayingStatus = ''
                  $PlayingSep = ''
                }
                if(-not [string]::IsNullOrEmpty($synchash.Now_Playing_Title_Label.DataContext)){
                  $title = $synchash.Now_Playing_Title_Label.DataContext
                }else{
                  $title = 'Video Player'
                }
                if(-not [string]::IsNullOrEmpty($synchash.Now_Playing_Artist_Label.DataContext)){
                  $artist = $synchash.Now_Playing_Artist_Label.DataContext
                  $sep = ' - '
                }else{
                  $artist = ''
                  $sep = ''
                }
                $floatingwindow.Title = "$PlayingStatus$PlayingSep$($title)$sep$($artist) - $($thisApp.Config.App_Name) Media Player"
              }
              <#              if($floatingwindow.Owner -ne $Null){
                  if($thisApp.Config.Dev_mode){write-ezlogs ">>> Setting floating window owner to null" -Dev_mode}
                  $floatingwindow.Owner = $Null
              }#>
              $LibVLCSharpWPFForegroundWindow = Get-VisualParentUp -source $synchash.VideoView_Grid -type ([System.Windows.Window])
              if($synchash.MediaViewAnchorable.isFloating -and $LibVLCSharpWPFForegroundWindow){
                $FloatingWindowOwner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($floatingwindow)
                if($LibVLCSharpWPFForegroundWindow.Owner -ne $FloatingWindowOwner){
                  write-ezlogs ">>>> Setting Libvlcsharp.Wpf.ForegroundWindow.Owner to VideoView floating window"
                  $LibVLCSharpWPFForegroundWindow.Owner = $FloatingWindowOwner
                }
              }
              if($synchash.VideoViewAirControl.front -and $synchash.MediaViewAnchorable.isFloating){
                $VideoViewAirControl = Get-VisualParentUp -source $synchash.VideoViewAirControl.front -type ([System.Windows.Window])
                if($VideoViewAirControl){
                  $FloatingWindowOwner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($floatingwindow)
                  if($VideoViewAirControl.Owner -ne $FloatingWindowOwner){
                    write-ezlogs ">>>> Setting VideoViewAirControl.front.parent.parent.Owner to VideoView floating window"
                    $VideoViewAirControl.Owner = $FloatingWindowOwner
                  }
                }
              }
              if($floatingwindow.icon -ne $synchash.Window.icon){
                $floatingwindow.icon = $synchash.Window.icon
              }
              #$style =  $synchash.Window.TryFindResource('LayoutAnchorableFloatingWindowControl')
              if($floatingwindow.style -ne $windowstyle){
                $floatingwindow.style = $windowstyle
              }
              if($floatingWindow.WindowStyle -ne 'None'){
                $floatingWindow.WindowStyle = 'None' 
              }                             
              if($synchash.vlc.isPlaying -and ($synchash.videoView.Visibility -in 'Hidden','Collapsed') -and !$synchash.Webview2.CoreWebView2.IsDocumentPlayingAudio -and !$synchash.YoutubeWebView2.CoreWebView2.IsDocumentPlayingAudio -and -not [string]($synchash.vlc.media.Mrl).StartsWith("dshow://")){
                write-ezlogs "Vlc is playing, Youtube/Spotify webplayer not playing and videoView.Visibility is hidden, setting to visible" -warning
                $synchash.videoView.Visibility = 'Visible'
              }
              if($floatingwindow.MinHeight -ne '400' -or $floatingwindow.MinWidth -ne "600"){
                $floatingwindow.MinHeight="400"
                $floatingwindow.MinWidth="600"
              }                       
              if($floatingWindow.Topmost -ne $synchash.VideoViewFloat.Topmost){
                $floatingWindow.Topmost = $synchash.VideoViewFloat.Topmost
              }
              #Context Menu
              if($synchash.DockingManager){
                $header = 'Dock'
                $items = [System.Collections.Generic.List[object]]::new()
                $Open_App = @{
                  'Header' = $Header
                  'Color' = 'White'
                  'Icon_Color' = 'White'
                  'Command' = $Synchash.Docking_Command
                  'tag' = $FloatingWindow_contentid
                  'Icon_kind' = 'DockWindow'
                  'Enabled' = $true
                  'IsCheckable' = $false
                }
                $null = $items.Add($Open_App)
                if($floatingwindow.isVisible){
                  $StayOnTop = @{
                    'Header' = "Stay On Top"
                    'Color' = 'White'
                    'Icon_Color' = 'White'
                    'tag' = $FloatingWindow_contentid
                    'Command' = $Synchash.StayOnTop_Command
                    'Icon_kind' = 'PinOutline'
                    'Enabled' = $true
                    'IsCheckable' = $true
                    'IsChecked' = $floatingWindow.Topmost
                  }
                  $null = $items.Add($StayOnTop)
                  if($floatingWindow.WindowState -eq 'Maximized'){
                    $iconkind = 'FullscreenExit'
                    $Header = 'Exit Fullscreen'
                  }else{
                    $Header = 'Fullscreen'
                    $iconkind = 'FullscreenExit'
                  }
                  $Maximize_VideoView = @{
                    'Header' = "FullScreen"
                    'Color' = 'White'
                    'tag' = $FloatingWindow_contentid
                    'Icon_Color' = 'White'
                    'Command' = $synchash.FloatFullScreen_Command
                    'Icon_kind' = $iconkind
                    'Enabled' = $true
                    'IsCheckable' = $false
                  }
                  $null = $items.Add($Maximize_VideoView)
                  $Minimize_VideoView = @{
                    'Header' = "Minimize"
                    'Color' = 'White'
                    'tag' = $FloatingWindow_contentid
                    'Icon_Color' = 'White'
                    'Command' = $Synchash.Minimize_VideoView_Command
                    'Icon_kind' = 'WindowMinimize'
                    'Enabled' = $true
                    'IsCheckable' = $false
                  }
                  $null = $items.Add($Minimize_VideoView)
                  if($synchash.TrayPlayerQueueFlyout.IsOpen){
                    $Header = 'Close Playlists'
                    $icon = 'AnimationPlay'
                  }else{
                    $Header = 'Open Playlists'
                    $icon = 'AnimationPlayOutline'
                  }
                  $Playlists_View = @{
                    'Header' = $Header
                    'Color' = 'White'
                    'Icon_Color' = 'White'
                    'Command' = $synchash.PlaylistsView_Command
                    'Icon_kind' = $icon
                    'Enabled' = $true
                    'IsCheckable' = $false
                  }
                  $null = $items.Add($Playlists_View)
                  if($synchash.chat_WebView2.Visibility -eq 'Visible' -or $synchash.Comments_Grid.Visibility -eq 'Visible'){
                    $chatHeader = 'Close Chat View'
                    $chaticon = 'ChatRemove'
                  }else{
                    $chatHeader = 'Open Chat View'
                    $chaticon = 'Chat'
                  }
                  $Chat_View = @{
                    'Header' = $chatHeader
                    'Color' = 'White'
                    'tag' = $FloatingWindow_contentid
                    'Icon_Color' = 'White'
                    'Command' = $synchash.ChatView_Command
                    'Icon_kind' = $chaticon
                    'Enabled' = $synchash.Chat_View_Button.isEnabled
                    'IsCheckable' = $false
                  }
                  $null = $items.Add($Chat_View)
                }
                $separator = @{
                  'Separator' = $true
                  'Style' = 'SeparatorGradient'
                }            
                $null = $items.Add($separator) 
                $Exit_App = @{
                  'Header' = "Close Video View"
                  'Color' = 'White'
                  'Icon_Color' = 'White'
                  'tag' = $FloatingWindow_contentid
                  'Command' = $synchash.Docking_Close_Command
                  'Icon_kind' = 'Close'
                  'Enabled' = $true
                  'IsCheckable' = $false
                }
                $null = $items.Add($Exit_App)
                Add-WPFMenu -control $floatingwindow -items $items -AddContextMenu -sourceWindow $synchash
              }
              $synchash.VideoViewFloat = $floatingwindow 
              $synchash.VideoViewFloat.Add_StateChanged($Synchash.FloatingWindow_StateChangedScriptblock)
              $synchash.VideoViewFloat.Uid = $FloatingWindow_contentid
              if(!$synchash.VideoViewFloat.TryFindResource('DockWindowCommand')){
                $Dockingrelaycommand = New-RelayCommand -synchash $synchash -thisApp $thisApp -scriptblock $Synchash.Docking_Command_Scriptblock -target $synchash.VideoViewFloat
                $synchash.VideoViewFloat.Resources.add('DockWindowCommand',$Dockingrelaycommand)
                $synchash.VideoViewFloat.tag = $Dockingrelaycommand
                [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($synchash.VideoViewFloat)

                #Register window to installed application ID
                $Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($synchash.VideoViewFloat)
                if($thisApp.Config.Installed_AppID){
                  $appid = $thisApp.Config.Installed_AppID
                }else{
                  $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
                }
                if($Window_Helper.Handle -and $appid){
                  $taskbarinstance = [Microsoft.WindowsAPICodePack.Taskbar.TaskbarManager]::Instance
                  write-ezlogs ">>>> Registering floating window: $FloatingWindow_contentid -- with handle: $($Window_Helper.Handle) -- to appid: $appid" -Dev_mode
                  $taskbarinstance.SetApplicationIdForSpecificWindow($Window_Helper.Handle,$appid)
                  if($thisapp.config.Installed_AppID -ne $appid){
                    $thisapp.config.Installed_AppID = $appid
                  } 
                }
                $synchash.VideoViewFloat.Add_Closing($Synchash.FloatingWindow_ClosingScriptblock)
              }
              if($synchash.MediaViewAnchorable_FloatMaximized -and $synchash.VideoViewFloat.WindowState -ne 'Maximized' -and $synchash.VideoView_LargePlayer_Icon.Kind -ne 'ScreenFull'){
                $synchash.VideoView_LargePlayer_Icon.Kind = 'ScreenFull'                                  
              }else{
                $synchash.MediaViewAnchorable_FloatMaximized = $false
              }                                                    
            }catch{
              write-ezlogs "An exception occurred in MediaViewAnchorable.add_FloatingPropertiesUpdated" -showtime -catcherror $_
            }
          }elseif($FloatingWindow_contentid -eq 'Webbrowser' -or $FloatingWindow_contentid -match "WebBrowser_TabWindow_"){                
            $floatingwindow.OwnedByDockingManagerWindow = $false
            $floatingwindow.AllowMinimize = $true
            $floatingwindow.ShowInTaskbar = $true
            $floatingWindow.Topmost = $synchash."$($FloatingWindow_contentid)Float".Topmost
            $webview2 = $($FloatingWindow_contentid) -replace 'TabWindow','Webview2'
            if($FloatingWindow_contentid -ne 'Webbrowser' -and $synchash."$FloatingWindow_contentid"){
              $floatingWindow.title = "$($synchash."$webview2".CoreWebview2.DocumentTitle) - $($thisApp.Config.App_Name) Media Player"
            }elseif($FloatingWindow_contentid -eq 'Webbrowser' -and $synchash.Webbrowser.CoreWebview2.DocumentTitle -and $floatingwindow.Title -ne $synchash.Webbrowser.CoreWebview2.DocumentTitle){
              $floatingwindow.Title = "$($synchash.Webbrowser.CoreWebview2.DocumentTitle) - $($thisApp.Config.App_Name) Media Player"
              $synchash.WebBrowserAnchorable.Title = "Web Browser - $($synchash.Webbrowser.CoreWebview2.DocumentTitle)"
            }elseif($floatingwindow.Title -ne "$($FloatingWindow_title) - $($thisApp.Config.App_Name) Media Player"){
              $floatingwindow.Title = "$($FloatingWindow_title) - $($thisApp.Config.App_Name) Media Player"
              $synchash.WebBrowserAnchorable.Title = "Web Browser"
            }
            if($floatingwindow.MinHeight -ne '400'){
              $floatingwindow.MinHeight="400"
            }
            if(!$synchash.MicrosoftEdgeicon -or $floatingwindow.icon -ne $synchash.MicrosoftEdgeicon){
              $icon = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
              if($thisApp.Config.Current_Theme.PrimaryAccentColor){
                $icon.Foreground = [System.Windows.Media.SolidColorBrush]::new($thisApp.Config.Current_Theme.PrimaryAccentColor.ToString())
              }else{
                $icon.Foreground = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
              }
              $icon.Kind = 'MicrosoftEdge'
              $icon.Height = '15'
              $icon.Width = '15'
              $geo = [System.Windows.Media.Geometry]::Parse($icon.Data)
              $gd = [System.Windows.Media.GeometryDrawing]::new()
              $gd.Geometry = $geo
              $gd.Brush = $icon.Foreground
              $gd.pen = [System.Windows.Media.Pen]::new("Black",0.2)
              $synchash.MicrosoftEdgeicon = [System.Windows.Media.DrawingImage]::new($gd)
              $synchash.MicrosoftEdgeicon.Drawing.Bounds.Width = '15'
              $synchash.MicrosoftEdgeicon.Drawing.Bounds.Height = '15'
              $floatingwindow.icon = $synchash.MicrosoftEdgeicon
              $synchash.MicrosoftEdgeicon.Freeze()    
            }
            if($FloatingWindow_contentid -eq 'Webbrowser'){
              $floatingwindow.MinWidth="500"
            }else{
              $floatingwindow.MinWidth="100"
            }
            $synchash."$($FloatingWindow_contentid)Float" = $floatingwindow
            $synchash."$($FloatingWindow_contentid)Float".Uid = $FloatingWindow_contentid
            if($synchash."$($FloatingWindow_contentid)Float".style -ne $windowstyle){
              $synchash."$($FloatingWindow_contentid)Float".style = $windowstyle
              $synchash."$($FloatingWindow_contentid)Float".Name = "$($FloatingWindow_contentid)Float"
              $synchash."$($FloatingWindow_contentid)Float".Add_StateChanged($Synchash.FloatingWindow_StateChangedScriptblock)
            }           
            if(!$synchash."$($FloatingWindow_contentid)Float".TryFindResource('DockWindowCommand')){
              $Dockingrelaycommand = New-RelayCommand -synchash $synchash -thisApp $thisApp -scriptblock $Synchash.Docking_Command_Scriptblock -target $synchash."$($FloatingWindow_contentid)Float"
              $synchash."$($FloatingWindow_contentid)Float".Resources.add('DockWindowCommand',$Dockingrelaycommand) 
              $synchash."$($FloatingWindow_contentid)Float".Tag = $Dockingrelaycommand
              [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($synchash."$($FloatingWindow_contentid)Float")
                      
              #Register window to installed application ID 
              $Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($synchash."$($FloatingWindow_contentid)Float")  
              if($thisApp.Config.Installed_AppID){
                $appid = $thisApp.Config.Installed_AppID
              }else{
                $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
              }
              if($Window_Helper.Handle -and $appid){
                $taskbarinstance = [Microsoft.WindowsAPICodePack.Taskbar.TaskbarManager]::Instance
                write-ezlogs ">>>> Registering floating window: $FloatingWindow_contentid -- with handle: $($Window_Helper.Handle) -- to appid: $appid" -Dev_mode
                $taskbarinstance.SetApplicationIdForSpecificWindow($Window_Helper.Handle,$appid)
                if($thisapp.config.Installed_AppID -ne $appid){
                  $thisapp.config.Installed_AppID = $appid
                } 
              }
            }                           
          }elseif($FloatingWindow_contentid -in 'MediaLibrary','TorBrowser'){ 
            $floatingwindow.OwnedByDockingManagerWindow = $false
            $floatingwindow.AllowMinimize = $true
            $floatingwindow.ShowInTaskbar = $true
            $floatingwindow.Title = "$($FloatingWindow_title) - $($thisApp.Config.App_Name) Media Player"
            if($floatingwindow.ResizeMode -ne "CanResizeWithGrip"){
              $floatingwindow.ResizeMode="CanResizeWithGrip"
            }
            $floatingwindow.MinWidth="1100"
            if($floatingwindow.MinHeight -ne '400'){
              $floatingwindow.MinHeight="400"
            }
            #$floatingwindow.Owner = $null
            if(!$synchash.Libraryicon -or $floatingwindow.icon -ne $synchash.Libraryicon){
              $icon = [MahApps.Metro.IconPacks.PackIconCodicons]::new()
              if($thisApp.Config.Current_Theme.PrimaryAccentColor){
                $icon.Foreground = [System.Windows.Media.SolidColorBrush]::new($thisApp.Config.Current_Theme.PrimaryAccentColor.ToString())
              }else{
                $icon.Foreground = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
              }
              $icon.Kind = 'Library'
              $icon.Height = '15'
              $icon.Width = '15'
              $geo = [System.Windows.Media.Geometry]::Parse($icon.Data)
              $gd = [System.Windows.Media.GeometryDrawing]::new()
              $gd.Geometry = $geo
              $gd.Brush = $icon.Foreground
              $gd.pen = [System.Windows.Media.Pen]::new("Black",1)
              $synchash.Libraryicon = [System.Windows.Media.DrawingImage]::new($gd)
              $synchash.Libraryicon.Drawing.Bounds.Width = '15'
              $synchash.Libraryicon.Drawing.Bounds.Height = '15'
              $floatingwindow.icon = $synchash.Libraryicon
              $synchash.Libraryicon.Freeze()               
            }
            $floatingWindow.Topmost= $synchash."$($FloatingWindow_contentid)Float".Topmost
            #Context Menu
            if($synchash.DockingManager){
              $header = 'Dock'
              $items = [System.Collections.Generic.List[object]]::new()
              $Open_App = @{
                'Header' = $Header
                'Color' = 'White'
                'Icon_Color' = 'White'
                'Command' = $Synchash.Docking_Command
                'tag' = $FloatingWindow_contentid
                'Icon_kind' = 'DockWindow'
                'Enabled' = $true
                'IsCheckable' = $false
              }
              $null = $items.Add($Open_App)
              if($floatingwindow.isVisible){
                $StayOnTop = @{
                  'Header' = "Stay On Top"
                  'Color' = 'White'
                  'Icon_Color' = 'White'
                  'tag' = $FloatingWindow_contentid
                  'Command' = $Synchash.StayOnTop_Command
                  'Icon_kind' = 'Pin'
                  'Enabled' = $true
                  'IsCheckable' = $true
                  'IsChecked' = $floatingWindow.Topmost
                }
                $null = $items.Add($StayOnTop)
                $Minimize_VideoView = @{
                  'Header' = "Minimize"
                  'Color' = 'White'
                  'tag' = $FloatingWindow_contentid
                  'Icon_Color' = 'White'
                  'Command' = $Synchash.Minimize_VideoView_Command
                  'Icon_kind' = 'WindowMinimize'
                  'Enabled' = $true
                  'IsCheckable' = $false                  
                }
                $null = $items.Add($Minimize_VideoView)
              }
              $separator = @{
                'Separator' = $true
                'Style' = 'SeparatorGradient'
              }            
              $null = $items.Add($separator) 
              $Exit_App = @{
                'Header' = "Close Video View"
                'Color' = 'White'
                'tag' = $FloatingWindow_contentid
                'Icon_Color' = 'White'
                'Command' = $synchash.Docking_Close_Command
                'Icon_kind' = 'Close'
                'Enabled' = $true
                'IsCheckable' = $false
              }
              $null = $items.Add($Exit_App)
              Add-WPFMenu -control $floatingwindow -items $items -AddContextMenu -sourceWindow $synchash
            }               
            $synchash."$($FloatingWindow_contentid)Float" = $floatingwindow
            if($synchash."$($FloatingWindow_contentid)Float".style -ne $windowstyle){
              $synchash."$($FloatingWindow_contentid)Float".style = $windowstyle
              $synchash."$($FloatingWindow_contentid)Float".Name = "$($FloatingWindow_contentid)Float"
            } 
            $synchash."$($FloatingWindow_contentid)Float".Uid = $FloatingWindow_contentid
            if(!$synchash."$($FloatingWindow_contentid)Float".TryFindResource('DockWindowCommand')){
              $Dockingrelaycommand = New-RelayCommand -synchash $synchash -thisApp $thisApp -scriptblock $Synchash.Docking_Command_Scriptblock -target $synchash."$($FloatingWindow_contentid)Float"
              $synchash."$($FloatingWindow_contentid)Float".Resources.add('DockWindowCommand',$Dockingrelaycommand) 
              $synchash."$($FloatingWindow_contentid)Float".Tag = $Dockingrelaycommand
              [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($synchash."$($FloatingWindow_contentid)Float")
                       
              #Register window to installed application ID 
              $Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($synchash."$($FloatingWindow_contentid)Float") 
              if($thisApp.Config.Installed_AppID){
                $appid = $thisApp.Config.Installed_AppID
              }else{
                $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
              }
              if($Window_Helper.Handle -and $appid){
                $taskbarinstance = [Microsoft.WindowsAPICodePack.Taskbar.TaskbarManager]::Instance
                write-ezlogs ">>>> Registering $($FloatingWindow_contentid)Float window handle: $($Window_Helper.Handle) -- to appid: $appid" -Dev_mode
                $taskbarinstance.SetApplicationIdForSpecificWindow($Window_Helper.Handle,$appid)    
                if($thisapp.config.Installed_AppID -ne $appid){
                  $thisapp.config.Installed_AppID = $appid
                }
              }
            }                      
          }elseif($FloatingWindow_contentid){
            write-ezlogs ">>>> Floating properties updated for floating window contentid: $($FloatingWindow_contentid) -- Name: $($sender.Name)"
          }                
        }catch{
          write-ezlogs 'An exception occurred in FloatingPropertiesUpdated_Command' -showtime -catcherror $_
        }
      }

      $synchash.DockingManager.add_LayoutFloatingWindowControlCreated({
          param([Parameter(Mandatory)][Object]$sender,[Parameter(Mandatory)][AvalonDock.LayoutFloatingWindowControlCreatedEventArgs]$e)
          try{
            $FloatingAnchorable = $e.LayoutFloatingWindowControl.Model.SinglePane.SelectedContent
            $FloatingWindowControl = $e.LayoutFloatingWindowControl
            #$null = Get-EventHandlers -Element $FloatingWindowControl -RoutedEvent ([System.Windows.Window]::LoadedEvent) -RemoveHandlers -VerboseLog
            #$null = Get-EventHandlers -Element $FloatingWindowControl -RoutedEvent ([System.Windows.Window]::UnloadedEvent) -RemoveHandlers -VerboseLog
            write-ezlogs ">>>> Undocking and creating floating window for control with contentid: $($FloatingAnchorable.ContentId)" -showtime
            #$null = Get-EventHandlers -Element $FloatingWindowControl -RoutedEvent ([System.Windows.Window]::SizeChangedEvent) -RemoveHandlers -VerboseLog:($thisApp.Config.Dev_mode)
            if($FloatingAnchorable.ContentId -eq 'VideoView'){
              #TODO: Setting floating window AllowsTransparency to true fixes the issue where libvlc video player window background sometimes becomes solid white or flashes white
              #https://code.videolan.org/videolan/LibVLCSharp/-/issues/555
              #Has to be false in order for sftreeview control that holds youtube comments to display, otherwise its just black.
              #Need to find a fix that allows AllowsTransparency to always stay true (until libvlcsharp fixes the core issue). Maybe use another airhackcontrol?
              if($thisApp.Config.Enable_YoutubeComments){
                $FloatingWindowControl.AllowsTransparency = $false
              }else{
                $FloatingWindowControl.AllowsTransparency = $true
              }
              $FloatingWindowControl.WindowStyle = 'None'
              $FloatingWindowControl.Name = "VideoViewWindow"
              $FloatingWindowControl.add_loaded($Synchash.FloatingWindow_LoadedScriptblock)
              #$FloatingWindowControl.add_PreviewGotKeyboardFocus($synchash.FloatingWindow_KeyboardFocusScriptblock)
              $FloatingWindowControl.add_IsKeyboardFocusedChanged($synchash.FloatingWindow_KeyboardFocusScriptblock)
              if($synchash.VideoViewAirControl.front.parent.parent -is [System.Windows.Window]){
                $FloatingWindowOwner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($FloatingWindowControl)
                if($synchash.VideoViewAirControl.front.parent.parent.Owner -ne $FloatingWindowOwner){
                  write-ezlogs "| Setting VideoViewAirControl.front.parent.parent.Owner to VideoView floating window" -warning
                  $synchash.VideoViewAirControl.front.parent.parent.Owner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($FloatingWindowControl)
                  if($synchash.VideoViewAirControl.Visibility -in 'Hidden','Collapsed'){
                    write-ezlogs "| Unhiding VideoViewAirControl"
                    $synchash.VideoViewAirControl.Visibility = 'Visible'
                  }
                }
              }
              $LibVLCSharpWPFForegroundWindow = Get-VisualParentUp -source $synchash.VideoView_Grid -type ([System.Windows.Window])
              if($synchash.MediaViewAnchorable.isFloating -and $LibVLCSharpWPFForegroundWindow){
                $FloatingWindowOwner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($FloatingWindowControl)
                if($LibVLCSharpWPFForegroundWindow.Owner -ne $FloatingWindowOwner){
                  write-ezlogs "| Setting Libvlcsharp.Wpf.ForegroundWindow.Owner to VideoView floating window"
                  $LibVLCSharpWPFForegroundWindow.Owner = $FloatingWindowOwner
                }
              }
              if($thisApp.Config.Remember_Window_Positions){
                if(-not [string]::IsNullOrEmpty($thisApp.Config.VideoWindow_Top) -and $thisApp.Config.VideoWindow_Top -ge 0 -and -not [string]::IsNullOrEmpty($thisApp.Config.VideoWindow_Left)){
                  $FloatingWindowControl.Top = $thisApp.Config.VideoWindow_Top
                  $FloatingWindowControl.Left = $thisApp.Config.VideoWindow_Left
                }
              }
            }elseif($FloatingAnchorable.ContentId -eq 'WebBrowser'){
              $Bookmarks_FlyoutControlWindowElement = [System.WeakReference]::new($synchash.Bookmarks_FlyoutControl).Target
              $Bookmarks_FlyoutControlWindow = Get-VisualParentUp -source $Bookmarks_FlyoutControlWindowElement -type ([System.Windows.Window])
              if($Bookmarks_FlyoutControlWindow.Owner){              
                $FloatingWindowOwner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($FloatingWindowControl)
                if($Bookmarks_FlyoutControlWindow.Owner -ne $FloatingWindowOwner){
                  write-ezlogs "| Setting Bookmarks_FlyoutControl.parent.parent.Owner to floating window" -Dev_mode
                  $Bookmarks_FlyoutControlWindow.Owner = [MahApps.Metro.Controls.MetroWindow]::GetWindow($FloatingWindowControl)   
                }
              }
              #Context Menu
              if($synchash.DockingManager){
                $header = 'Dock'
                $items = [System.Collections.Generic.List[object]]::new()
                $Open_App = @{
                  'Header' = $Header
                  'Color' = 'White'
                  'Icon_Color' = 'White'
                  'Command' = $Synchash.Docking_Command
                  'tag' = $FloatingAnchorable.ContentId
                  'Icon_kind' = 'DockWindow'
                  'Enabled' = $true
                  'IsCheckable' = $false
                }
                $null = $items.Add($Open_App)
                if($FloatingWindowControl.isVisible){
                  $StayOnTop = @{
                    'Header' = "Stay On Top"
                    'Color' = 'White'
                    'Icon_Color' = 'White'
                    'tag' = $FloatingAnchorable.ContentId
                    'Command' = $Synchash.StayOnTop_Command
                    'Icon_kind' = 'Pin'
                    'Enabled' = $true
                    'IsCheckable' = $true
                    'IsChecked' = $FloatingWindowControl.Topmost
                  }
                  $null = $items.Add($StayOnTop)
                  $Minimize_VideoView = @{
                    'Header' = "Minimize"
                    'Color' = 'White'
                    'tag' = $FloatingAnchorable.ContentId
                    'Icon_Color' = 'White'
                    'Command' = $Synchash.Minimize_VideoView_Command
                    'Icon_kind' = 'WindowMinimize'
                    'Enabled' = $true
                    'IsCheckable' = $false
                  }
                  $null = $items.Add($Minimize_VideoView)
                }
                $separator = @{
                  'Separator' = $true
                  'Style' = 'SeparatorGradient'
                }            
                $null = $items.Add($separator) 
                $Exit_App = @{
                  'Header' = "Close Video View"
                  'Color' = 'White'
                  'tag' = $FloatingAnchorable.ContentId
                  'Icon_Color' = 'White'
                  'Command' = $synchash.Docking_Close_Command
                  'Icon_kind' = 'Close'
                  'Enabled' = $true
                  'IsCheckable' = $false
                }
                $null = $items.Add($Exit_App)
                Add-WPFMenu -control $FloatingWindowControl -items $items -AddContextMenu -sourceWindow $synchash
              }
              if($thisApp.Config.Remember_Window_Positions){
                if(-not [string]::IsNullOrEmpty($thisApp.Config.BrowserWindow_Top) -and $thisApp.Config.BrowserWindow_Top -ge 0 -and -not [string]::IsNullOrEmpty($thisApp.Config.BrowserWindow_Left)){
                  $FloatingWindowControl.Top = $thisApp.Config.BrowserWindow_Top
                  $FloatingWindowControl.Left = $thisApp.Config.BrowserWindow_Left
                }
              }
            }elseif($FloatingAnchorable.ContentId -eq 'MediaLibrary'){
              if($thisApp.Config.Remember_Window_Positions){
                if(-not [string]::IsNullOrEmpty($thisApp.Config.LibraryWindow_Top) -and $thisApp.Config.LibraryWindow_Top -ge 0 -and -not [string]::IsNullOrEmpty($thisApp.Config.LibraryWindow_Left)){
                  $FloatingWindowControl.Top = $thisApp.Config.LibraryWindow_Top
                  $FloatingWindowControl.Left = $thisApp.Config.LibraryWindow_Left
                }
              }
              #$FloatingWindowControl.add_PreviewGotKeyboardFocus($synchash.FloatingWindow_KeyboardFocusScriptblock)
            }
            $FloatingWindowControl.add_Unloaded($Synchash.FloatingWindow_UnLoadedScriptblock)
          }catch{
            write-ezlogs "An exception occurred in LayoutFloatingWindowControlCreated" -catcherror $_
          }
      })
      $synchash.MediaViewAnchorable.Remove_FloatingPropertiesUpdated($Synchash.FloatingPropertiesUpdated_Command)
      $synchash.MediaViewAnchorable.add_FloatingPropertiesUpdated($Synchash.FloatingPropertiesUpdated_Command)
      $synchash.WebBrowserAnchorable.Remove_FloatingPropertiesUpdated($Synchash.FloatingPropertiesUpdated_Command)
      $synchash.WebBrowserAnchorable.add_FloatingPropertiesUpdated($Synchash.FloatingPropertiesUpdated_Command)
      $synchash.MediaLibraryAnchorable.Remove_FloatingPropertiesUpdated($Synchash.FloatingPropertiesUpdated_Command)
      $synchash.MediaLibraryAnchorable.add_FloatingPropertiesUpdated($Synchash.FloatingPropertiesUpdated_Command)
      $synchash.MediaLibraryAnchorable.add_Hiding({
          param([Parameter(Mandatory)][Object]$sender,[Parameter(Mandatory)][System.ComponentModel.CancelEventArgs]$e)
          try{
            write-ezlogs ">>>> MediaLibraryAnchorable hidden - redocking to docking manager"
            $synchash.MediaLibraryAnchorable.dock()
            if($synchash.LibraryButton_ToggleButton.isChecked){
              $synchash.LibraryButton_ToggleButton.isChecked = $false
            }
            if($synchash.VideoView.Visibility -eq 'Visible' -and $synchash.MediaViewAnchorable){
              $synchash.MediaViewAnchorable.isSelected = $true
            }
          }catch{
            write-ezlogs "An exception occurred in MediaLibraryAnchorable.add_Hiding" -showtime -catcherror $_
          }
      })
      $synchash.WebBrowserAnchorable.add_closed({
          param($sender)
          try{
            write-ezlogs ">>>> $($sender.ContentId) has closed" -loglevel 2
            $webview2 = $($sender.ContentId) -replace 'TabWindow','Webview2'
            if($synchash."$webview2".CoreWebview2){
              write-ezlogs " | Disposing Webview2 instance $($webview2)" -loglevel 2
              $synchash."$webview2".dispose()
            }
          }catch{
            write-ezlogs "An exception occurred in $($sender.ContentId) closed event" -catcherror $_
          }
      })
      if($synchash.TorBrowserAnchorable){
        $synchash.TorBrowserAnchorable.add_FloatingPropertiesUpdated($Synchash.FloatingPropertiesUpdated_Command)
      } 
    }catch{
      write-ezlogs "An exception occurred setting add_FloatingPropertiesUpdated for MediaViewAnchorable" -showtime -catcherror $_
    }
  }
}
#---------------------------------------------- 
#endregion Set-AvalonDock Function
#----------------------------------------------
Export-ModuleMember -Function @('Set-AvalonDock')