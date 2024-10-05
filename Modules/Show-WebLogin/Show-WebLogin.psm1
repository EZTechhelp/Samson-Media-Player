<#
    .Name
    Show-WebLogin 

    .Version 
    0.2.1

    .SYNOPSIS
    Displays simple graphic dialog window with webview2 control for capturing user results from web content 

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
    #TODO: This module needs full rebuild/refactor
#>

#---------------------------------------------- 
#region Show-WebLogin Function
#----------------------------------------------

function Show-WebLogin{
  Param (
    [string]$SplashTitle,
    [string]$Splash_More_Info,
    [string]$WebView2_URL,
    [string]$SplashLogo,
    [string]$Message,
    [switch]$First_Run,
    [switch]$SaveCookiesConfig,
    [string]$MarkDownFile,
    $Listener,
    $Script:MahDialog_hash = [hashtable]::Synchronized(@{}),
    [string]$Message_2,
    [switch]$Verboselog,
    $thisApp
  )  

  #Create session state for runspace
  $Script:MahDialog_hash = [hashtable]::Synchronized(@{})
  $Splash_Pwshell = {
    Param (
      [string]$SplashTitle = $SplashTitle,
      [string]$Splash_More_Info = $Splash_More_Info,
      [string]$WebView2_URL = $WebView2_URL,
      [string]$SplashLogo = $SplashLogo,
      [string]$Message = $Message,
      [switch]$First_Run = $First_Run,
      [switch]$SaveCookiesConfig = $SaveCookiesConfig,
      [string]$MarkDownFile = $MarkDownFile,
      $Listener = $Listener,
      $MahDialog_hash = $MahDialog_hash,
      [string]$Message_2 = $Message_2,
      [switch]$Verboselog =$Verboselog,
      $thisApp = $thisApp
    )
    try{
      $Current_Folder = "$($thisApp.Config.Current_Folder)"
      $MahDialog_Window_XML = "$($Current_Folder)\Views\WebAuth.xaml"
      $xaml = [System.IO.File]::ReadAllText($MahDialog_Window_XML).replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml")
      $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
      $MahDialog_hash.Window = [System.WeakReference]::new(([Windows.Markup.XAMLReader]::Parse($XAML))).Target
      while ($reader.Read())
      {
        $name=$reader.GetAttribute('Name')
        if(!$name){ 
          $name=$reader.GetAttribute('x:Name')
        }
        if($name -and $MahDialog_hash.Window){
          $MahDialog_hash."$($name)" = [System.WeakReference]::new(($MahDialog_hash.Window.FindName($name))).Target
        }
      }
      $reader.Dispose()
      $PrimaryMonitor = [System.Windows.Forms.Screen]::PrimaryScreen
      if($PrimaryMonitor.Bounds.Height -lt '1080'){
        $MahDialog_hash.window.MaxHeight=$PrimaryMonitor.WorkingArea.Height
      }
      $MahDialog_hash.window.title =$SplashTitle
      $MahDialog_hash.Logo.Source = "$($thisapp.Config.Current_Folder)\Resources\Skins\Samson_Logo_Title.png"
      $MahDialog_hash.HeaderLogo.Source = $splashlogo
      $MahDialog_hash.window.TaskbarItemInfo.Description = "$SplashTitle - $($thisApp.Config.App_Name) Media Player - Version: $($thisApp.Config.App_Version)"
      $MahDialog_hash.Window.icon = "$($thisapp.Config.Current_folder)\Resources\Samson_Icon_NoText1.ico"
      $MahDialog_hash.Window.icon.freeze()
      $MahDialog_hash.Window.IsWindowDraggable="True" 
      $MahDialog_hash.Window.LeftWindowCommandsOverlayBehavior="HiddenTitleBar" 
      $MahDialog_hash.Window.RightWindowCommandsOverlayBehavior="HiddenTitleBar"
      $MahDialog_hash.Window.ShowTitleBar=$true
      $MahDialog_hash.Window.UseNoneWindowStyle = $false
      $MahDialog_hash.Window.WindowStyle = 'none'           
      $SettingsBackground = [System.Windows.Media.ImageBrush]::new()
      $settingsBackground.ImageSource = "$($thisapp.Config.Current_Folder)\Resources\Skins\Settings\SubWindowTop.png"
      $settingsBackground.ViewportUnits = "Absolute"
      $settingsBackground.Viewport = "0,0,600,263"
      $settingsBackground.TileMode = 'Tile'
      $SettingsBackground.Freeze()
      $MahDialog_hash.Window.Background = $SettingsBackground
      $MahDialog_hash.Background_Image_Bottom.Source = "$($thisapp.Config.Current_Folder)\Resources\Skins\Settings\SubWindowBottom.png"
      $MahDialog_hash.Background_Image_Bottom.Source.Freeze()                  
      $imagebrush = [System.Windows.Media.ImageBrush]::new()
      $ImageBrush.ImageSource = "$($thisapp.Config.Current_Folder)\Resources\Skins\Settings\SubWindowTile.png"
      $imagebrush.TileMode = 'Tile'
      $imagebrush.ViewportUnits = "Absolute"
      $imagebrush.Viewport = "0,0,600,283"
      $imagebrush.ImageSource.freeze()
      $MahDialog_hash.Background_TileGrid.Background = $imagebrush     
      $MahDialog_hash.Window.Style = $MahDialog_hash.Window.TryFindResource('WindowChromeStyle')
      $MahDialog_hash.Window.UpdateDefaultStyle()
      if($SplashTitle -match 'Twitch'){
        $MahDialog_hash.Background_Grid_Row_1.Height = '400'
        $MahDialog_hash.Window.MinHeight="550"
      }
      if($Message_2){
        $message = "$message`n`n$Message_2"
      }    
      if([system.io.file]::Exists($MarkDownFile)){
        write-ezlogs ">>>> Opening Markdown Help File: $MarkDownFile" -loglevel 2 -logtype Setup
        $Message += "`n`n" + ([system.io.file]::ReadAllText($MarkDownFile) -replace '\[USERNAME\]',$env:USERNAME -replace '\[appname\]',$thisApp.Config.App_Name -replace '\[appversion\]',$thisApp.Config.App_Version -replace '\[CURRENTFOLDER\]',$thisApp.Config.Current_Folder)
      }
      if($Message){
        try{
          $MahDialog_hash.MarkdownScrollViewer.Markdown = $Message
        }catch{
          write-ezlogs "An exception occurred updating MarkdownScrollViewer" -showtime -catcherror $_
        }
      }
      #region Cancel_Button    
      $MahDialog_hash.Cancel_Button_Image.source = "$($thisapp.Config.Current_Folder)\Resources\Skins\Audio\EQ_ToggleButton.png"
      $MahDialog_hash.Cancel_Button.add_click({
          try{
            $MahDialog_hash.window.close()
          }catch{
            write-ezlogs "An exception occurred in Cancel_Button click event" -showtime -catcherror $_
          } 
      })    
      #endregion Cancel_Button 
    }catch{
      write-ezlogs "An exception occurred Show-WebLogin Xaml" -showtime -catcherror $_
    }
    $Webview2_Path = 'WebView2'
    write-ezlogs " | Opening URL $($WebView2_URL) - Webview2 folder: $($thisApp.config.Temp_Folder)\$Webview2_Path" -showtime -logtype Setup -loglevel 2
    try{  
      #region Create Webview2 
      if($MahDialog_hash.Dialog_WebView2_Grid.Children -contains $MahDialog_hash.Dialog_WebView2){
        $null = $MahDialog_hash.Dialog_WebView2_Grid.Children.Remove($MahDialog_hash.Dialog_WebView2)
      }
      if(!$MahDialog_hash.Dialog_WebView2 -or !$MahDialog_hash.Dialog_WebView2.CoreWebView2){
        Write-EZLogs '#### Creating new Dialog_Webview2 instance' -showtime -logtype Webview2 -linesbefore 1
        $MahDialog_hash.Dialog_WebView2 = [Microsoft.Web.WebView2.Wpf.WebView2]::new()
        $MahDialog_hash.Dialog_WebView2.Visibility = 'Visible'
        $MahDialog_hash.Dialog_WebView2.Name = 'Dialog_WebView2'
        $MahDialog_hash.Dialog_WebView2.DefaultBackgroundColor = [System.Drawing.Color]::Transparent
      }
      $null = $MahDialog_hash.Dialog_WebView2_Grid.AddChild($MahDialog_hash.Dialog_WebView2)
      #endregion Create Webview2

      #region Initialize Webview2
      if($MahDialog_hash.WebView2Env.IsCompleted -and $MahDialog_hash.Dialog_WebView2.CoreWebView2){
        write-ezlogs ">>>> WebView2Env already initialized: $($MahDialog_hash.WebView2Env.Result)" -showtime -logtype Webview2
        $MahDialog_hash.Dialog_WebView2.EnsureCoreWebView2Async($MahDialog_hash.WebView2Env.Result)
      }else{
        write-ezlogs ">>>> Initializing Dialog_WebView2" -showtime -logtype Webview2
        $WebView2Options = [Microsoft.Web.WebView2.Core.CoreWebView2EnvironmentOptions]::new()
        $WebView2Options.AdditionalBrowserArguments = '--autoplay-policy=no-user-gesture-required --Disable-features=HardwareMediaKeyHandling,OverscrollHistoryNavigation,msExperimentalScrolling'
        $WebView2Options.IsCustomCrashReportingEnabled = $true
        $MahDialog_hash.WebView2Env = [Microsoft.Web.WebView2.Core.CoreWebView2Environment]::CreateAsync(
          [String]::Empty, [IO.Path]::Combine( [String[]]($($thisApp.config.Temp_Folder), $Webview2_Path) ), $WebView2Options
        )
        $MahDialog_hash.WebView2Env.GetAwaiter().OnCompleted(
          [Action]{$MahDialog_hash.Dialog_WebView2.EnsureCoreWebView2Async( $MahDialog_hash.WebView2Env.Result )}
        )      
      }
      #endregion Initialize Webview2  

      #region NavigationCompleted Event
      $MahDialog_hash.Dialog_WebView2_NavigationCompleted_Scriptblock = [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs]]{
        param($sender,[Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs]$e)
        try{
          write-ezlogs "Navigation completed: $($sender.source)" -showtime -logtype Webview2
          if($sender.source.host -eq 'localhost' -and ($sender.source.LocalPath -match '/auth/complete' -or $sender.source.LocalPath -match '/oauth2/authorize')){
            write-ezlogs "[Show-Weblogin_Dialog_WebView2.NavigationCompleted] >>>> Closing Show-Weblogin" -showtime -logtype Webview2
            $MahDialog_hash.window.close()
          }
        }catch{
          write-ezlogs "An exception occurred in Dialog_WebView2.Add_NavigationCompleted" -catcherror $_
        }
      }
      $MahDialog_hash.Dialog_WebView2.Add_NavigationCompleted($MahDialog_hash.Dialog_WebView2_NavigationCompleted_Scriptblock)
      #endregion NavigationCompleted Event

      #region WebResourceRequested Event
      if($SaveCookiesConfig){
        $MahDialog_hash.Dialog_WebView2_WebResourceRequested_Scriptblock = [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2WebResourceRequestedEventArgs]]{
          param([Object]$sender,[Microsoft.Web.WebView2.Core.CoreWebView2WebResourceRequestedEventArgs]$e)
          try{
            $Cookies = ($e.Request.Headers | Where-Object {$_.key -eq 'cookie'}).value
            #write-ezlogs "CoreWebView2Cookie: $($MahDialog_hash.Dialog_WebView2.CoreWebView2.CoreWebView2Cookie | out-string)" -logtype Setup 
            if($sender.Source -match 'spotify\.com'){
              $cookiedurldomain = '.spotify.com'
            }elseif($sender.Source -match 'google\.com'){
              $cookiedurldomain = '.google.com'
            }elseif($sender.Source -match 'youtube\.com' -or $sender.Source -match 'youtu\.be'){
              $cookiedurldomain = '.youtube.com'
            }
            if($Cookies){
              if($Cookies -notmatch 'OptanonAlertBoxClosed'){
                if($thisApp.Config.Dev_mode){write-ezlogs ">>> Adding WebBrowser OptanonAlertBoxClosed cookie for URL domain: $($cookiedurldomain)" -logtype Webview2 -Dev_mode}  
                $OptanonAlertBoxClosed = $sender.CookieManager.CreateCookie('OptanonAlertBoxClosed', $(Get-date -Format 'yyy-MM-ddTHH:mm:ss.192Z'), $cookiedurldomain, "/")
                $sender.CookieManager.AddOrUpdateCookie($OptanonAlertBoxClosed)
              }
              $Cookies = $cookies -split ';'
              $sp_dc = $cookies | Where-Object {$_ -match 'sp_dc=(?<value>.*)'}
              if($sp_dc -and $thisApp.Config.Spotify_SP_DC -ne $sp_dc){
                $existin_sp_dc = ([regex]::matches($sp_dc,  'sp_dc=(?<value>.*)')| %{$_.groups[1].value})
                $thisApp.Config.Spotify_SP_DC = $existin_sp_dc
                if($thisApp.Config.Dev_mode){write-ezlogs "Found SP_DC $($existin_sp_dc)" -showtime -logtype Webview2 -Dev_mode}                         
              } 
              $Youtube_1PSID = $cookies | Where-Object {$_ -match '__Secure-1PSID=(?<value>.*)'}         
              if($Youtube_1PSID -and $thisApp.Config.Youtube_1PSID -ne $Youtube_1PSID){
                $existin_Youtube_1PSID = ([regex]::matches($Youtube_1PSID,  '__Secure-1PSID=(?<value>.*)')| %{$_.groups[1].value} )
                $thisApp.Config.Youtube_1PSID = $existin_Youtube_1PSID
                if($thisApp.Config.Dev_mode){write-ezlogs "Found and updating Youtube 1PSID: $($existin_Youtube_1PSID)" -showtime -logtype Webview2 -Dev_mode}                          
              }
              $Youtube_1PAPISID = $cookies | Where-Object {$_ -match '__Secure-1PAPISID=(?<value>.*)'}   
              if($Youtube_1PAPISID -and $thisApp.Config.Youtube_1PAPISID -ne $Youtube_1PAPISID){
                $existin_Youtube_1PAPISID = ([regex]::matches($Youtube_1PAPISID,  '__Secure-1PAPISID=(?<value>.*)')| %{$_.groups[1].value} )
                $thisApp.Config.Youtube_1PAPISID = $existin_Youtube_1PAPISID
                if($thisApp.Config.Dev_mode){write-ezlogs "Found and updating Youtube 1PAPISID: $($existin_Youtube_1PAPISID)" -showtime -logtype Webview2 -Dev_mode}                       
              }
              $Youtube_3PAPISID = $cookies | Where-Object {$_ -match '__Secure-3PAPISID=(?<value>.*)'}         
              if($Youtube_3PAPISID -and $thisApp.Config.Youtube_3PAPISID -ne $Youtube_3PAPISID){
                $existin_Youtube_3PAPISID = ([regex]::matches($Youtube_3PAPISID,  '__Secure-3PAPISID=(?<value>.*)')| %{$_.groups[1].value} )
                $thisApp.Config.Youtube_3PAPISID = $existin_Youtube_3PAPISID
                if($thisApp.Config.Dev_mode){write-ezlogs "Found and updating Youtube 3PAPISID: $($existin_Youtube_3PAPISID)" -showtime -logtype Webview2 -Dev_mode}                           
              }                                          
            }
          }catch{e
            write-ezlogs "An exception occurred in Dialog_WebView2 CoreWebView2InitializationCompleted Event" -showtime -catcherror $_
          }
        }
      }
      #endregion WebResourceRequested Event

      #region InitializationCompleted Event
      $MahDialog_hash.Dialog_WebView2_InitializationCompleted_Scriptblock = [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2InitializationCompletedEventArgs]]{
        Param($sender,[Microsoft.Web.WebView2.Core.CoreWebView2InitializationCompletedEventArgs]$event)
        try{
          write-ezlogs ">>>> Dialog_WebView2 CoreWebView2InitializationCompleted" -showtime -logtype Webview2 -loglevel 2
          if($event.IsSuccess){ 
            #& $ProcessNoDevTools
            [Microsoft.Web.WebView2.Core.CoreWebView2Settings]$Settings = $sender.CoreWebView2.Settings
            $Settings.AreDefaultContextMenusEnabled  = $true
            $Settings.AreDefaultScriptDialogsEnabled = $true
            $Settings.AreDevToolsEnabled             = $thisApp.Config.Dev_mode
            $Settings.AreHostObjectsAllowed          = $true
            $Settings.IsBuiltInErrorPageEnabled      = $false
            $Settings.IsScriptEnabled                = $true
            $Settings.IsStatusBarEnabled             = $true
            $Settings.IsWebMessageEnabled            = $true
            $Settings.IsZoomControlEnabled           = $false      
            $Settings.IsGeneralAutofillEnabled       = $false
            $Settings.IsPasswordAutosaveEnabled      = $false
            $Settings.IsSwipeNavigationEnabled = $false
            $Settings.AreBrowserAcceleratorKeysEnabled = $thisApp.Config.Dev_mode
            if($WebView2_URL -match 'youtube\.com' -or $WebView2_URL -match 'google\.com'){
              $Settings.UserAgent = "Chrome"
              $Settings.UserAgent = "Android"
            }else{
              $Settings.UserAgent = ""
            }         
            $sender.CoreWebView2.AddWebResourceRequestedFilter("*", [Microsoft.Web.WebView2.Core.CoreWebView2WebResourceContext]::All)
            if($MahDialog_hash.Dialog_WebView2_WebResourceRequested_Scriptblock){
              $sender.CoreWebView2.Remove_WebResourceRequested($MahDialog_hash.Dialog_WebView2_WebResourceRequested_Scriptblock)
              $sender.CoreWebView2.add_WebResourceRequested($MahDialog_hash.Dialog_WebView2_WebResourceRequested_Scriptblock)
            }
            $Null = $sender.CoreWebView2.Navigate($WebView2_URL)
          }else{
            write-ezlogs "Dialog_WebView2 CoreWebView2 Initialization Completed but without success $($event.InitializationException | out-string)" -showtime -warning -logtype Webview2 -loglevel 2
          }
        }catch{
          write-ezlogs "An exception occurred in Dialog_WebView2.Add_InitializationCompleted" -catcherror $_
        }
      }
      $MahDialog_hash.Dialog_WebView2.Add_CoreWebView2InitializationCompleted($MahDialog_hash.Dialog_WebView2_InitializationCompleted_Scriptblock)
      #endregion InitializationCompleted Event
    }catch{
      write-ezlogs "An exeception occurred initializing webview2 in Show-WebLogin" -showtime -catcherror $_
    }
    try{
      #region Closed Event
      $MahDialog_hash.Closed_Event = {
        param($sender)
        try{                                  
          write-ezlogs ">>>> Show-Weblogin Closed" -showtime
          try{  
            if($Listener -is [System.IDisposable]){
              write-ezlogs "| Disposing HTTP Listener" -showtime
              $Listener.close()
              $Listener.dispose()
              $Listener = $Null
            }
          }catch{
            write-ezlogs "An exception occurred disposing HTTP Listener on Weblogin close" -showtime -catcherror $_
          } 
          try{  
            #Clean up webview2 - remove event handlers then dispose
            if($MahDialog_hash.Dialog_WebView2 -is [System.IDisposable]){
              write-ezlogs " | Disposing Dialog_WebView2" -showtime -logtype Setup -loglevel 2
              if($MahDialog_hash.Dialog_WebView2.CoreWebView2){
                $MahDialog_hash.Dialog_WebView2.CoreWebView2.Remove_WebResourceRequested($MahDialog_hash.Dialog_WebView2_WebResourceRequested_Scriptblock)
              }
              $Null = $MahDialog_hash.Dialog_WebView2.Remove_NavigationCompleted($MahDialog_hash.Dialog_WebView2_NavigationCompleted_Scriptblock)
              $Null = $MahDialog_hash.Dialog_WebView2.Remove_CoreWebView2InitializationCompleted($MahDialog_hash.Dialog_WebView2_InitializationCompleted_Scriptblock)
              $MahDialog_hash.Dialog_WebView2.dispose()
              $MahDialog_hash.Dialog_WebView2 = $Null
            }          
          }catch{
            write-ezlogs "An exception occurred disposing Dialog_WebView2 on Weblogin close" -showtime -catcherror $_
          }                               
        }catch{
          write-ezlogs "An exception occurred closing Show-Weblogin window" -showtime -catcherror $_
        }
      }
      $Null = $MahDialog_hash.Window.Add_Closed($MahDialog_hash.Closed_Event)
      #endregion Closed Event

      #region Loaded Event 
      [System.Windows.RoutedEventHandler]$MahDialog_hash.Loaded_Event = {
        param($sender,[System.Windows.RoutedEventArgs]$e)
        try{
          #Register window to installed application ID 
          $Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($sender)
          if($thisApp.Config.Installed_AppID){
            $appid = $thisApp.Config.Installed_AppID
          }else{
            $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
          }
          if($Window_Helper.Handle -and $appid){
            $taskbarinstance = [Microsoft.WindowsAPICodePack.Taskbar.TaskbarManager]::Instance
            write-ezlogs ">>>> Registering Miniplayer window handle: $($Window_Helper.Handle) -- to appid: $appid" -Dev_mode
            $taskbarinstance.SetApplicationIdForSpecificWindow($Window_Helper.Handle,$appid)  
            Add-Member -InputObject $thisapp.config -Name 'Installed_AppID' -Value $appid -MemberType NoteProperty -Force
          }               
        }catch{
          write-ezlogs "An exception occurred in MahDialog_hash.Window.Add_Loaded" -showtime -catcherror $_
        } 
      } 
      $Null = $MahDialog_hash.Window.AddHandler([MahApps.Metro.Controls.MetroWindow]::LoadedEvent,$MahDialog_hash.Loaded_Event)
      #endregion Loaded Event 
        
      #region Unloaded Event
      [System.Windows.RoutedEventHandler]$MahDialog_hash.Unloaded_Event = {
        param($sender,[System.Windows.RoutedEventArgs]$e)
        try{                           
          #$null = Get-EventHandlers -Element $sender -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::MouseLeftButtonDownEvent) -RemoveHandlers -VerboseLog
          $null = Get-EventHandlers -Element $sender -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::LoadedEvent) -RemoveHandlers -VerboseLog
          $null = Get-EventHandlers -Element $sender -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::UnloadedEvent) -RemoveHandlers -VerboseLog
          $null = Get-EventHandlers -Element $MahDialog_hash.Cancel_Button -RoutedEvent ([System.Windows.Controls.Button]::ClickEvent) -RemoveHandlers -VerboseLog
          $Null = $sender.Remove_Closed($MahDialog_hash.Closed_Event)
          $hashkeys = [System.Collections.ArrayList]::new($MahDialog_hash.keys)
          $hashkeys | & { process {
              if($MahDialog_hash.Window.FindName($_)){
                if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Unregistering MahDialog_hash UI name: $_" -Dev_mode}
                $null = $MahDialog_hash.Window.UnRegisterName($_)
                $MahDialog_hash.$_ = $Null
              }        
          }}
          $MahDialog_hash.Window = $Null
          $MahDialog_hash = $null
          $hashkeys = $Null
          [System.Windows.Threading.Dispatcher]::ExitAllFrames()
          [System.Windows.Threading.Dispatcher]::CurrentDispatcher.InvokeShutdown()
          write-ezlogs "Web Authentication Window Unloaded - disposed appcontext thread" -logtype Setup -loglevel 2 -GetMemoryUsage -forceCollection
        }catch{
          write-ezlogs "An exception occurred in MahDialog_hash Window unloaded event" -catcherror $_
        }
      }
      $Null = $MahDialog_hash.Window.AddHandler([MahApps.Metro.Controls.MetroWindow]::UnloadedEvent,$MahDialog_hash.Unloaded_Event)
      #endregion Unloaded Event
    }catch{
      write-ezlogs "An exception occurred adding MahDialog_hash.Window routed events" -showtime -CatchError $_
    } 

    #endregion Show Window
    try{
      $null = [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($MahDialog_hash.Window)
      $null = $MahDialog_hash.window.Show()
      $null = $MahDialog_hash.Window.Activate()
      [System.Windows.Threading.Dispatcher]::Run()
    }catch{
      write-ezlogs "An exception occurred when opening main Show-WebLogin window" -showtime -CatchError $_
    } 
    #endregion Show Window  
  }
  $Variable_list = Get-Variable | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
  Start-Runspace $Splash_Pwshell -Variable_list $Variable_list -StartRunspaceJobHandler -runspace_name 'Show_WebLogin' -logfile $thisApp.Config.Log_File -thisApp $thisApp -synchash $synchash -verboselog
  $Variable_list = $Null
  return $MahDialog_hash
}
#---------------------------------------------- 
#endregion Show-WebLogin Function
#----------------------------------------------
Export-ModuleMember -Function @('Show-WebLogin')