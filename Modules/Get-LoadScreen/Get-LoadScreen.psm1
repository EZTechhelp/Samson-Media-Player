<#
    .Name
    Get-LoadScreen 

    .Version 
    0.1.2

    .SYNOPSIS
    Displays simple graphic splash screen while app is loading or waiting for tasks to complete  

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
#region Update-SplashScreen Function
#----------------------------------------------
function Update-SplashScreen {
  Param (
    [string]$SplashTitle,
    $hash,
    [switch]$Show,
    [switch]$Hide,
    [switch]$NewDialog,
    [string]$DialogMessage,
    [string]$DialogTitle,
    [switch]$close,
    [switch]$wait,
    [switch]$NoConfigSave,
    [switch]$screenshot,
    [string]$Current_folder,
    [string]$Splash_More_Info,
    [string]$More_Info_Visibility = 'Hidden',
    [string]$SplashLogo,
    [string]$Visibility = 'Visible',
    [switch]$verboselog = $true,
    [switch]$Startup,
    [ValidateSet('CloseApp','CloseSplash')]
    [string]$DialogAction,
    [ValidateSet('CloseApp','CloseSplash')]
    [string]$Action,
    [string]$SplashMessage
  )
  try{
    if($Startup){
      $hash.Splash_Update_Timer = [System.Windows.Threading.DispatcherTimer]::new()
      [System.EventHandler]$hash.Splash_Update_Event = {
        try{
          if(-not [string]::IsNullOrEmpty($this.tag.SplashTitle) -and $hash.SplashTitle){
            $hash.SplashTitle.Content=$this.tag.SplashTitle
          }
          if(-not [string]::IsNullOrEmpty($this.tag.SplashMessage) -and $hash.LoadingLabel){
            $hash.LoadingLabel.text = $this.tag.SplashMessage 
          } 
          if(-not [string]::IsNullOrEmpty($this.tag.Splash_More_Info) -and $hash.More_Info_Msg){
            $hash.More_Info_Msg.text = $this.tag.Splash_More_Info 
          }   
          if(-not [string]::IsNullOrEmpty($this.tag.Visibility) -and $hash.Window){
            $hash.Window.Visibility = $this.tag.Visibility 
          }   
          if(-not [string]::IsNullOrEmpty($this.tag.More_Info_Visibility) -and $hash.More_Info_Msg){
            $hash.More_Info_Msg.Visibility = $this.tag.More_Info_Visibility 
          }
          if($this.tag.Show -and $hash.Window){
            [void]$hash.Window.show() 
          }
          if($this.tag.Hide -and $hash.Window){
            [void]$hash.Window.Hide() 
          } 
          if($this.tag.NoConfigSave){
            $hash.NoConfigSave = $true
          }             
          if($this.tag.Close){
            if($this.tag.Wait){
              $waitmax = 0
              while(!$hash.Window -and $waitmax -lt 6){
                $waitmax++
                Start-Sleep -Milliseconds 500
              }
              if($waitmax -ge 6){
                write-ezlogs "Timed out waiting for splash screen" -warning
              }
            }
            if($hash.Window){
              $hash.ClosedbyApp = $true
              [void]$hash.Window.Close() 
            }else{
              write-ezlogs "No splash screen was found to close" -Warning
            }
          } 
          if($this.tag.NewDialog -and $this.tag.DialogMessage){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($hash.Window,"$($this.tag.DialogTitle)","$($this.tag.DialogMessage)",$okandCancel,$Button_Settings)
            if($this.Tag.DialogAction -eq 'CloseApp'){
              write-ezlogs ">>>> Forcing app to close after splash dialog!" -warning
              $hash.Window.Close()
            }elseif($this.Tag.DialogAction -eq 'CloseSplash'){
              write-ezlogs ">>>> Forcing splashscreen to close after splash dialog!" -warning
              $hash.ClosedbyApp = $true
              $hash.Window.Close() 
            }
          }
          if($this.Tag.Action -eq 'CloseApp'){
            write-ezlogs ">>>> Forcing app to close after splash dialog!" -warning
            $hash.Window.Close()
          }elseif($this.Tag.Action -eq 'CloseSplash'){
            write-ezlogs ">>>> Forcing splashscreen to close after splash dialog!" -warning
            $hash.ClosedbyApp = $true
            $hash.Window.Close() 
          }
          if($this.tag.screenshot){
            $hash.Window.Topmost = $true
            [void]$hash.Window.Activate() 
            start-sleep -Milliseconds 500
            write-ezlogs ">>>> Taking Snapshot of Splash window" -showtime
            $translatepoint = $hash.Window.TranslatePoint([system.windows.point]::new(0,0),$this)
            $locationfromscreen = $hash.Window.PointToScreen($translatepoint)
            $synchash.SnapshotPoint = [System.Drawing.Point]::new($locationfromscreen.x,$locationfromscreen.y)           
          }                              
          $this.Stop()
        }catch{
          write-ezlogs "An exception occurred in Splash_Update_Timer.add_tick" -showtime -catcherror $_
        }finally{
          $this.Stop()
          $this.tag = $null
        }
      }
      [void]$hash.Splash_Update_Timer.add_tick($hash.Splash_Update_Event)
    }elseif($hash.Window){
      $hash.Splash_Update_Timer.tag = [PSCustomObject]::new(@{
          'SplashTitle' = $SplashTitle
          'SplashMessage' = $SplashMessage
          'Splash_More_Info' = $Splash_More_Info
          'NewDialog' = $NewDialog
          'Action' = $Action
          'DialogMessage' = $DialogMessage
          'DialogTitle' = $DialogTitle
          'DialogAction' = $DialogAction
          'Visibility' = $Visibility
          'screenshot' = $screenshot
          'NoConfigSave' = $NoConfigSave
          'Show' = $Show
          'Hide' = $hide
          'Close' = $close
          'wait' = $wait
      })
      [void]$hash.Splash_Update_Timer.start()        
    }
  }catch{
    write-ezlogs "An exception occurred in Update-SplashScreen" -showtime -catcherror $_
  }   
}
#---------------------------------------------- 
#endregion Update-SplashScreen Function
#----------------------------------------------

#---------------------------------------------- 
#region Start-SplashScreen Function
#----------------------------------------------
function Start-SplashScreen{
  Param (
    [string]$SplashTitle,
    [switch]$ShowDialog,
    [string]$Runspace_name,
    $thisScript,
    [string]$Current_folder,
    [string]$Splash_More_Info,
    [string]$SplashLogo,
    [switch]$verboselog,
    [switch]$firstRun,
    [switch]$start_hidden,
    [switch]$Startup,
    [switch]$Setup,
    [switch]$Launcher,
    [switch]$NoSplashUI,
    [switch]$MainStartup,
    [switch]$Debug_verboselog,
    [string]$log_file,
    [string]$perf_log,
    $threading_Log_file,
    [switch]$FreshStart,
    [switch]$startup_perf_timer,
    $startup_stopwatch,
    [switch]$PlayAudio,
    [switch]$UseDll = $true,
    [string]$PlayAudio_FilePath,
    [string]$SplashMessage
  )     
  $global:hash = [hashtable]::Synchronized(@{}) 
  if($Startup){
    try{   
      $Splash_dll_load_Measure = [system.diagnostics.stopwatch]::StartNew()
      $splash_Screen_Assemblies = @(        
        "$Current_Folder\Assembly\EZT-MediaPlayer\ControlzEx.dll",
        "$Current_Folder\Assembly\EZT-MediaPlayer\MahApps.Metro.dll",
        "$Current_Folder\Assembly\EZT-MediaPlayer\MahApps.Metro.IconPacks.Material.dll",
        "$Current_Folder\Assembly\EZT-MediaPlayer\MahApps.Metro.IconPacks.dll",
        "$Current_Folder\Assembly\WindowsAPICodecPack\Microsoft.WindowsAPICodePack.dll",
        "$Current_Folder\Assembly\WindowsAPICodecPack\Microsoft.WindowsAPICodePack.Shell.dll",
        "$Current_Folder\Assembly\EZT-MediaPlayer\EZT-MediaPlayer-Control.dll"
        "$Current_Folder\Assembly\EZT-MediaPlayer\Microsoft.Xaml.Behaviors.dll" 
      ) 
      foreach($a in $splash_Screen_Assemblies){
        if($verboselog){write-ezlogs ">>>> Loading assembly $a"}
        [void][System.Reflection.Assembly]::LoadFrom($a)        
      }
      $Splash_dll_load_Measure.stop()   
    }catch{
      write-ezlogs "An exception occurred loading assemblies" -CatchError $_
      [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
      [void][System.Windows.Forms.MessageBox]::Show("[ERROR]`nAn exception occurred starting ($($thisApp.Config.App_Name) Media Player - Version: $($thisApp.Config.App_Version) - PID: $($pid)) An exception occurred loading assemblines.`n$($_ | out-string)`n`nThis app will close","$($thisApp.Config.App_Name)",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
    }
  }
  $Splash_Scriptblock = {
    Param (
      [string]$SplashTitle = $SplashTitle,
      [switch]$ShowDialog = $ShowDialog,
      [string]$Runspace_name = $Runspace_name,
      $thisScript = $thisScript,
      [string]$Current_folder = $Current_folder,
      [string]$Splash_More_Info = $Splash_More_Info,
      [string]$SplashLogo = $SplashLogo,
      [switch]$verboselog = $verboselog,
      [switch]$firstRun = $firstRun,
      [switch]$start_hidden = $start_hidden,
      [switch]$Startup = $Startup,
      [switch]$Setup = $Setup,
      [switch]$Launcher = $Launcher,
      [switch]$NoSplashUI = $NoSplashUI,
      [switch]$MainStartup = $MainStartup,
      [switch]$Debug_verboselog = $Debug_verboselog,
      [string]$log_file = $log_file,
      [string]$perf_log = $perf_log,
      $threading_Log_file = $threading_Log_file,
      [switch]$FreshStart = $FreshStart,
      [switch]$startup_perf_timer = $startup_perf_timer,
      $startup_stopwatch = $startup_stopwatch,
      [switch]$PlayAudio = $PlayAudio,
      [string]$PlayAudio_FilePath = $PlayAudio_FilePath,
      [string]$SplashMessage = $SplashMessage,
      [switch]$UseDll = $UseDll,
      $thisApp = $thisApp,
      $hash = $hash,
      $synchash = $synchash
    )
    $splash_load_measure = [system.diagnostics.stopwatch]::StartNew()
    try{
      if([string]::IsNullOrEmpty($log_file) -and -not [string]::IsNullOrEmpty($thisApp.Config.Log_File)){
        $log_file = $thisApp.Config.Log_File
      }
      if([string]::IsNullOrEmpty($perf_log) -and -not [string]::IsNullOrEmpty($thisApp.Config.Perf_Log_File)){
        $perf_log = $thisApp.Config.Perf_Log_File
      }
      $dplayer = $true
      $splash_logo = "$($current_folder)\Resources\Samson_Icon_NoText1.ico"
      $splash_Update_SplashScreen = [system.diagnostics.stopwatch]::StartNew()
      Update-SplashScreen -hash $hash -Startup
      $splash_Update_SplashScreen.stop()
      if(($MainStartup -and !$Launcher) -or ($thisApp.config.Start_Tray_only -and !$FreshStart)){
        return
      }
      $splash_load_Xaml = [system.diagnostics.stopwatch]::StartNew()
      if([bool]('EZT_MediaPlayer_Controls.SplashWindow' -as [type])){
        $hash.Window = [System.WeakReference]::new(([EZT_MediaPlayer_Controls.SplashWindow]::new())).Target
        $hash.SplashProgressStackpanel = [System.WeakReference]::new($hash.Window.FindName('SplashProgressStackpanel')).Target
        $hash.SplashPawStackPanel = [System.WeakReference]::new($hash.Window.FindName('SplashPawStackPanel')).Target
        $hash.SplashTitle = [System.WeakReference]::new($hash.Window.FindName('SplashTitle')).Target
        $hash.LoadingLabel = [System.WeakReference]::new($hash.Window.FindName('LoadingLabel')).Target
        $hash.Background_Image = [System.WeakReference]::new($hash.Window.FindName('Background_Image')).Target
        $hash.SplashRichText = [System.WeakReference]::new($hash.Window.FindName('SplashRichText')).Target
        $hash.More_Info_Msg = [System.WeakReference]::new($hash.Window.FindName('More_Info_Msg')).Target
      }else{
        $Splash_Window_XML = "$($Current_Folder)\Views\Splash.xaml"
        $xaml = [System.IO.File]::ReadAllText($Splash_Window_XML)
        $hash.Window = [Windows.Markup.XAMLReader]::Parse($XAML)
        $reader = [XML.XMLReader]::Create([IO.StringReader]$XAML)
        while ($reader.Read())
        {
          $name=$reader.GetAttribute('Name')
          if($name -and $hash.Window){           
            $hash."$($name)" = [System.WeakReference]::new($hash.Window.FindName($name)).Target
          }
        }
        [void]$reader.Dispose()
      }
      [void]$splash_load_Xaml.stop()
    }catch{
      write-ezlogs "An exception occurred creating a new SplashWindow instance" -CatchError $_
    }

    try{  
      $Splash_Load_Controls = [system.diagnostics.stopwatch]::StartNew()
      if($splash_logo -and $hash.Window){
        $hash.Window.icon = $splash_logo
      }
      if($SplashTitle -and $hash.window){
        $hash.window.title =$SplashTitle
      }   
      if($SplashMessage -and $hash.LoadingLabel){   
        $hash.LoadingLabel.Text= $SplashMessage
      }
      if(!$dplayer -and $synchash.Window.isloaded -and $thisApp.Config.Current_Theme -ne $null -and $thisApp.Config.Current_Theme.Name){
        $theme = [MahApps.Metro.Theming.MahAppsLibraryThemeProvider]::new()
        $themes = $theme.GetLibraryThemes()
        $themeManager = [ControlzEx.Theming.ThemeManager]::new()
        $detectTheme = $thememanager.DetectTheme($hash.Window)
        if($detectTheme.Name){
          $newtheme = $themes | where {$_.Name -eq $detectTheme.Name}
        }else{
          $newtheme = $themes | where {$_.Name -eq $thisApp.Config.Current_Theme.Name}
        }
        if($themes){
          [void]$themes.Dispose()
        }
      }
      if(!$dplayer -and $newtheme){
        $thememanager.RegisterLibraryThemeProvider($newtheme.LibraryThemeProvider)
        $thememanager.ChangeTheme($hash.Window,$newtheme.Name,$false)
        $gradientbrush = New-object System.Windows.Media.LinearGradientBrush
        $gradientbrush.StartPoint = "0.5,0"
        $gradientbrush.EndPoint = "0.5,1"
        $gradientstop1 = New-object System.Windows.Media.GradientStop
        $gradientstop1.Color = $thisApp.Config.Current_Theme.GridGradientColor1
        $gradientstop1.Offset= "0.0"
        $gradientstop2 = New-object System.Windows.Media.GradientStop
        $gradientstop2.Color = $thisApp.Config.Current_Theme.GridGradientColor2
        $gradientstop2.Offset= "0.7"
        $gradientstop_Collection = New-object System.Windows.Media.GradientStopCollection
        $null = $gradientstop_Collection.Add($gradientstop1)
        $null = $gradientstop_Collection.Add($gradientstop2)
        $gradientbrush.GradientStops = $gradientstop_Collection
        $hash.Window.Background = $gradientbrush
      }

      if($dplayer){
        $splashimage = "$($Current_Folder)\Resources\Images\SplashScreen\Samson_Logo_Splash.png"
        if($splashimage -and $hash.Background_Image){
          $hash.Background_Image.source = $splashimage
          if($splashimage -match 'Bitty_Speaker_Right_Small' -or $splashimage -match 'Samson_Bitty_Speaker_Small'){
            $hash.SplashProgressStackpanel.Margin = "0,0,0,212"
            $hash.SplashProgressStackpanel.Width="313"
            $hash.Window.Height="510"
            $hash.Window.Width="313"
            $hash.Background_Image.Height="510"
            $hash.Background_Image.Width="313"
          }elseif($splashimage -match 'Samson_Speaker_Left_Small' -or $splashimage -match 'Squanch_Speaker_Left_Small'){
            $hash.SplashProgressStackpanel.Margin = "0,0,0,212"
            $hash.SplashProgressStackpanel.Width="313"
            $hash.Window.Height="381"
            $hash.Window.Width="313"
            $hash.Background_Image.Height="381"
            $hash.Background_Image.Width="313"
          }elseif($splashimage -match 'Samson_2'){
            $hash.SplashPawStackPanel.Tag="White"
            $hash.SplashProgressStackpanel.Margin = "0,0,0,90"
            $hash.SplashProgressStackpanel.Width="440"
            $hash.Window.Width="432"
            $hash.Window.Height="450"
            $hash.Background_Image.Width="432"
            $hash.Background_Image.Height="450"
          }elseif($splashimage -match 'Samson_Logo_Splash.png'){
            $hash.SplashPawStackPanel.Tag="Black"
            $hash.SplashProgressStackpanel.Margin = "0,0,10,35"
            $hash.SplashProgressStackpanel.Width="250"
            $hash.SplashProgressStackpanel.Background="#7C000000"
          }
        }

        #Set Splash Location based on remembered coordinates
        if(-not [string]::IsNullOrEmpty($thisApp.Config.Splash_Top) -and -not [string]::IsNullOrEmpty($thisApp.Config.Splash_Left) -and ($thisApp.Config.Remember_Window_Positions -or $FreshStart)){
          $hash.Window.Top = $thisApp.Config.Splash_Top
          $hash.Window.Left = $thisApp.Config.Splash_Left
        }
      }else{
        if($hash.Logo -and $splash_logo){
          $hash.Logo.Source=$splash_logo
        }
        if($hash.SplashTitle -and $SplashTitle){
          $hash.SplashTitle.Content=$SplashTitle
        }
      }
    }catch{
      write-ezlogs "An exception occurred changing theme for Get-loadScreen" -showtime -catcherror $_
    }
    #region MouseLeftButtonDown Event
    [System.Windows.RoutedEventHandler]$hash.MouseLeftButtonDown_Event = {
      param($sender,[System.Windows.Input.MouseButtonEventArgs]$e)
      try{
        if($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed -and $e.RoutedEvent.Name -eq 'MouseLeftButtonDown'){
          $hash.Window.DragMove()
          $e.handled = $true
        }
      }catch{
        write-ezlogs "An exception occurred in Window MouseLeftButtonDown event" -showtime -catcherror $_
      }
    }
    $Null = $hash.Window.AddHandler([MahApps.Metro.Controls.MetroWindow]::MouseLeftButtonDownEvent,$hash.MouseLeftButtonDown_Event)
    #endregion MouseLeftButtonDown Event

    #region Closed Event
    $hash.Closed_Event = {
      param($sender)
      try{ 
        if($hash.ClosedbyApp){
          if($verboselog){write-ezlogs ">>>> Splash Screen Closed"}
          $hash.Background_Image.Source = $null
          if([System.IO.File]::Exists($thisApp.Config.Config_Path) -and ($thisApp.Config.Remember_Window_Positions -or $FreshStart) -and !$hash.NoConfigSave){
            Add-Member -InputObject $thisapp.config -Name 'Splash_Top' -Value $hash.Window.Top -MemberType NoteProperty -Force
            Add-Member -InputObject $thisapp.config -Name 'Splash_Left' -Value $hash.Window.Left -MemberType NoteProperty -Force
            Export-SerializedXML -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -isConfig
            #Export-Clixml -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -Force -Encoding UTF8
          }
        }else{
          write-ezlogs ">>>> Splash Screen Closed by user or crashed...cleaning up app processes" 
          $sprocess = [System.Diagnostics.Process]::GetProcessesByName('streamlink')
          if($sprocess){
            foreach($p in $sprocess){
              $p.kill()
              $p.dispose()
            }
          }
          $yprocess = [System.Diagnostics.Process]::GetProcessesByName('yt-dlp')
          if($yprocess){
            foreach($p in $yprocess){
              $p.kill()
              $p.dispose()
            }
          }                       
          if($pid){
            Stop-Process $pid -Force
          } 
        }
      }catch{
        write-ezlogs "An exception occurred closing Splash window" -CatchError $_
      }
    }
    [void]$hash.Window.Add_Closed($hash.Closed_Event)
    #endregion Closed Event

    #region Loaded Event 
    [System.Windows.RoutedEventHandler]$hash.Loaded_Event = {
      param($sender,[System.Windows.RoutedEventArgs]$e)
      try{    
        $current_Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($hash.Window) 
        if(-not [string]::IsNullOrEmpty($thisApp.Config.Installed_AppID)){
          $appid = $thisApp.Config.Installed_AppID
        }elseif(-not [string]::IsNullOrEmpty($thisScript.Name)){
          $appid = (Get-AllStartApps -Name $thisScript.Name).AppID
        }
        if($appid -and $current_Window_Helper.Handle){
          $taskbarinstance = [Microsoft.WindowsAPICodePack.Taskbar.TaskbarManager]::Instance
          $taskbarinstance.SetApplicationIdForSpecificWindow($current_Window_Helper.Handle,$appid)
          if($thisapp.config){
            Add-Member -InputObject $thisapp.config -Name 'Installed_AppID' -Value $appid -MemberType NoteProperty -Force
          }
        }           
        if($PlayAudio -and $hash.SplashRichText -and $PlayAudio_FilePath){  
          if([system.io.file]::Exists($PlayAudio_FilePath)){
            if($verboselog){write-ezlogs ">>>> Playing Startup Media file: $($PlayAudio_FilePath) - $($hash.SplashRichText)"}  
            $Paragraph = New-Object System.Windows.Documents.Paragraph
            $BlockUIContainer = New-Object System.Windows.Documents.BlockUIContainer  
            $Floater = New-Object System.Windows.Documents.Floater
            $Floater.HorizontalAlignment = "Center" 
            $Floater.Name = "Media_Floater"
            if($PlayAudio_FilePath -match '.gif' -or $PlayAudio_FilePath -match '.mp3' -or $PlayAudio_FilePath -match '.mp4'){ 
              $Media_Element = New-object System.Windows.Controls.MediaElement 
              $Media_Element.UnloadedBehavior = 'Close'  
              $Media_Element.LoadedBehavior="Manual"  
              $Media_Element.Name = 'Media_Element'     
              $Media_Element.Source = $PlayAudio_FilePath   
              $Media_Element.Play()   
              $Media_Element.Add_MediaEnded({
                  param($Sender) 
                  try{
                    $hash.SplashRichText.Visibility = 'Hidden'  
                    $this.Stop()
                    $this.tag = $Null
                    $this.close()
                  }catch{
                    write-ezlogs "An exception occurred in splash Media_Element ended event" -CatchError $_
                  }
              })
              $Media_Element.add_MediaFailed({
                  param($Sender) 
                  try{
                    write-ezlogs "MediaFailed event occurred for splash media element: $($sender | out-string)" -Warning
                    $this.Stop()
                    $this.tag = $Null
                    $this.close()   
                  }catch{
                    write-ezlogs "An exception occurred in splash Media_Element.add_MediaFailed" -CatchError $_
                  }               
              })                    
              $BlockUIContainer.AddChild($Media_Element) 
            }   
            $floater.AddChild($BlockUIContainer)   
            $Paragraph.addChild($floater)
            $hash.SplashRichText.Visibility = 'Visible'
            [void]$hash.SplashRichText.Document.Blocks.Add($Paragraph)
          }else{        
            write-ezlogs "Unable to find media file for splash window playback: '$($PlayAudio_FilePath)'" -Warning
          }
        }
      }catch{
        write-ezlogs "An exception occurred in splash loaded event" -CatchError $_
      }
    } 
    [void]$hash.Window.AddHandler([MahApps.Metro.Controls.MetroWindow]::LoadedEvent,$hash.Loaded_Event)
    #endregion Loaded Event 
        
    #region Unloaded Event
    [System.Windows.RoutedEventHandler]$hash.Unloaded_Event = {
      param($sender,[System.Windows.RoutedEventArgs]$e)
      try{
        [void](Get-EventHandlers -Element $sender -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::MouseLeftButtonDownEvent) -RemoveHandlers)
        [void](Get-EventHandlers -Element $sender -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::LoadedEvent) -RemoveHandlers)
        [void](Get-EventHandlers -Element $sender -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::UnloadedEvent) -RemoveHandlers)
        [void]$sender.Remove_Closed($hash.Closed_Event)
        $hashkeys = [System.Collections.ArrayList]::new($hash.keys)
        $hashkeys | & { process {
            if($hash.window.FindName($_)){
              if($thisApp.Config.Dev_mode){write-ezlogs -text ">>>> Unregistering Splash UI name: $_" -Dev_mode}
              [void]$sender.UnRegisterName($_)
              [void]$hash.Remove($_)
            }
        }}
        if($sender.Window.Content){
          if($thisApp.Config.Dev_mode){write-ezlogs " | Clearing window content"} 
          $sender.Window.Content = $Null   
        }
        [void]$hash.Remove('Window')
        if($hash.Splash_Update_Timer){
          $hash.Splash_Update_Timer.Remove_tick($hash.Splash_Update_Event)
        }
        $hash = $Null
        $hashkeys = $Null
        [void][System.Windows.Threading.Dispatcher]::ExitAllFrames()
        [void][System.Windows.Threading.Dispatcher]::CurrentDispatcher.InvokeShutdown()
        if($thisApp.Config.Dev_mode){
          $memusagebyte = "$([System.GC]::GetTotalMemory($true) / 1MB) MB"
          write-ezlogs -text "Splash Screen Unloaded: $($memusagebyte)" -Dev_mode
        }
      }catch{
        write-ezlogs "An exception occurred in splash unloaded event" -CatchError $_
      }
    }
    $Null = $hash.Window.AddHandler([MahApps.Metro.Controls.MetroWindow]::UnloadedEvent,$hash.Unloaded_Event)
    #endregion Unloaded Event
    
    if($Splash_Load_Controls){
      $Splash_Load_Controls.stop()
    }     
    try{           
      $splash_show_UI = [system.diagnostics.stopwatch]::StartNew()
      if(!$start_hidden){
        [void]$hash.window.Show()
        [void]$hash.Window.Activate()
      }
      $splash_show_UI.stop()              
    }catch{
      write-ezlogs "An exception occurred when opening main splash window" -CatchError $_
    }  
    $splash_load_measure.stop()
    if($perf_log){
      if($Splash_dll_load_Measure.Elapsed.Seconds -ge 1){
        $Splash_dll_load_Status = " [WARNING]"
      }
      if($splash_load_measure.Elapsed.Seconds -ge 1){
        $splash_load_Status = " [WARNING]"
      }
      if($splash_show_UI.Elapsed.Seconds -ge 1){
        $splash_show_UI_Status = " [WARNING]"
      }
      if($splash_load_Xaml.Elapsed.Seconds -ge 1){
        $splash_load_Xaml_Status = " [WARNING]"
      }
      if($Splash_Load_Controls.Elapsed.Seconds -ge 1){
        $Splash_Load_Controls_Status = " [WARNING]"
      }
      $datetime = "[$([datetime]::Now.ToString())]"
      $message = @"
####################### SPLASH SCREEN STARTUP #######################
$datetime$Splash_dll_load_Status [PERF] Load Splash Assembly: | Time: $($Splash_dll_load_Measure.Elapsed.hours):$($Splash_dll_load_Measure.Elapsed.Minutes):$($Splash_dll_load_Measure.Elapsed.Seconds):$(([string]$Splash_dll_load_Measure.Elapsed.Milliseconds).PadLeft(3,'0'))
$datetime$splash_load_Status [PERF] Splash UI load Total: | Time: $($splash_load_measure.Elapsed.hours):$($splash_load_measure.Elapsed.Minutes):$($splash_load_measure.Elapsed.Seconds):$(([string]$splash_load_measure.Elapsed.Milliseconds).PadLeft(3,'0'))
$datetime [PERF] Splash_Update: | Time: $($splash_Update_SplashScreen.Elapsed.hours):$($splash_Update_SplashScreen.Elapsed.Minutes):$($splash_Update_SplashScreen.Elapsed.Seconds):$(([string]$splash_Update_SplashScreen.Elapsed.Milliseconds).PadLeft(3,'0'))
$datetime$splash_load_Xaml_Status [PERF] splash_load_Xaml: | Time: $($splash_load_Xaml.Elapsed.hours):$($splash_load_Xaml.Elapsed.Minutes):$($splash_load_Xaml.Elapsed.Seconds):$(([string]$splash_load_Xaml.Elapsed.Milliseconds).PadLeft(3,'0'))
$datetime$splash_show_UI_Status [PERF] splash_show_UI: | Time: $($splash_show_UI.Elapsed.hours):$($splash_show_UI.Elapsed.Minutes):$($splash_show_UI.Elapsed.Seconds):$(([string]$splash_show_UI.Elapsed.Milliseconds).PadLeft(3,'0'))
$datetime$Splash_Load_Controls_Status [PERF] Splash_Load_Controls: | Time: $($Splash_Load_Controls.Elapsed.hours):$($Splash_Load_Controls.Elapsed.Minutes):$($Splash_Load_Controls.Elapsed.Seconds):$(([string]$Splash_Load_Controls.Elapsed.Milliseconds).PadLeft(3,'0'))
"@
      write-ezlogs -text $message -linesbefore 1 -logfile $perf_log -Perf
    }  
    try{     
      [void][System.Windows.Threading.Dispatcher]::Run()
    }catch{
      write-ezlogs -text "An exception occurred running Threading.Dispatcher" -CatchError $_
    } 
  }
  try{ 
    if(!$NoSplashUI){
      $Variable_list = Get-Variable | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
      $Start_RunSpace_Measure = [system.diagnostics.stopwatch]::StartNew()
      $Runspace_Args = @{
        'scriptblock' = $Splash_Scriptblock
        'Variable_list' = $Variable_list
        'StartRunspaceJobHandler' = $true
        'thisApp' = $thisApp
        'synchash' = $synchash
        'runspace_name' = 'Start_SplashScreen_Runspace'
        'logfile' = $threading_Log_file
        'startup_stopwatch' = $startup_stopwatch
        'RestrictedRunspace' = $true
        'function_list' = 'write-ezlogs','Import-SerializedXML','Export-SerializedXML','Get-EventHandlers','Get-AllStartApps','Update-SplashScreen'
        'verboselog' = $verboselog
        'startup_perf_timer' = $startup_perf_timer
      }
      [void](Start-Runspace @Runspace_Args)
      $Start_RunSpace_Measure.stop()
    }
    if($Launcher){
      return
    }
    $dll_load_Measure = [system.diagnostics.stopwatch]::StartNew()
    foreach($a in [System.IO.Directory]::EnumerateFiles("$Current_Folder\Assembly",'*.dll','AllDirectories')){
      try{
        if($splash_Screen_Assemblies -notcontains $a -and $a -notmatch 'WebView2Loader|LibVLCSharp\.dll|Microsoft\.Windows\.SDK\.NET|PoshWinRT|WinRT.Runtime|FindFilesFast|MonoTorrent'){
          if($Debug_verboselog){write-ezlogs ">>>> Loading assembly $a" -Dev_mode}
          if($PSVersionTable.PSVersion.Major -le 5){
            [void][System.Reflection.Assembly]::LoadFrom($a)
          }elseif($a -notmatch 'System\.Text\.Json|System\.Memory|System\.Numerics\.Vectors|System\.Buffers'){
            [void][System.Reflection.Assembly]::LoadFrom($a)
          }
        }
      }catch{
        write-ezlogs "An exception occurred loading assembly file: $a" -catcherror $_
      }
    }  
    $dll_load_Measure.stop()  
    if($dll_load_Measure.Elapsed.Seconds -ge 1){
      $perfstatus = ' [WARNING]'
    }   
    $Start_SplashScreen_Perf = "[$([datetime]::Now.ToString())]$perfstatus [PERF] [Start-SplashScreen:432] >>>> Load Assembly Startup: | Time: $($dll_load_Measure.Elapsed.Minutes):$($dll_load_Measure.Elapsed.Seconds):$($dll_load_Measure.Elapsed.Milliseconds)"
    if($startup_perf_timer){ 
      $perfstatus = $null
      if($Start_RunSpace_Measure.Elapsed.Seconds -ge 1){
        $perfstatus = ' [WARNING]'
      }
      return "[$([datetime]::Now.ToString())]$perfstatus [PERF] [Start-SplashScreen:540] Start_RunSpace Total: | Time: $($Start_RunSpace_Measure.Elapsed.Minutes):$($Start_RunSpace_Measure.Elapsed.Seconds):$($Start_RunSpace_Measure.Elapsed.Milliseconds)`n$Start_SplashScreen_Perf"
    }            
  }catch{
    write-ezlogs "An exception occurred in Get-LoadScreen" -catcherror $_
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void][System.Windows.Forms.MessageBox]::Show("[ERROR]`nAn exception occurred starting ($($thisApp.Config.App_Name) Media Player - Version: $($thisApp.Config.App_Version) - PID: $($pid)). See logs for details.`n$($_ | out-string)`n`nThis app will now close","$($thisApp.Config.App_Name)",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    Stop-EZlogs -ErrorSummary $error -clearErrors -stoptimer -logOnly -enablelogs -thisapp $thisApp -globalstopwatch $startup_stopwatch
    Stop-Process $pid -Force      
  }   
}
#---------------------------------------------- 
#endregion Start-SplashScreen Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-SplashScreen','close-SplashScreen','Update-SplashScreen')