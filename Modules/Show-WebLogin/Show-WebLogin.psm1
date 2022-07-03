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
    - Module designed for EZT-MediaPlayer

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>


#########################################################################
#                        Add shared_assemblies
#########################################################################
using namespace System.Windows.Data
using namespace System.Windows.Markup
Add-Type -AssemblyName WindowsFormsIntegration
#---------------------------------------------- 
#region close-WebLogin Function
#----------------------------------------------
function close-WebLogin (){
  Param (
    [switch]$Force
  )
  try{
    if($MahDialog_hash.Window.isVisible -or $Force){
      $MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{ 
          $MahDialog_hash.window.close()
          $MahDialog_hash.Dialog_WebView2.Dispose() 
      })        
    }
  }catch{
    write-ezlogs "An exception occurred in close-weblogin" -showtime -catcherror $_
  }

}
#---------------------------------------------- 
#region close-WebLogin Function
#----------------------------------------------

#---------------------------------------------- 
#region Wait-Task Function
#----------------------------------------------
function Wait-Task {
  # await replacement
  param (
    [Parameter(ValueFromPipeline = $true, Mandatory = $true)] $Task
  )
  # https://stackoverflow.com/questions/51218257/await-async-c-sharp-method-from-powershell
  process {
    while (-not $Task.AsyncWaitHandle.WaitOne(200)) { }
    $Task.GetAwaiter() #.GetResult()
  }
}
#---------------------------------------------- 
#endregion Wait-Task Function
#----------------------------------------------

#---------------------------------------------- 
#region Show-WebLogin Function
#----------------------------------------------

function Show-WebLogin{
  Param (
    [string]$SplashTitle,
    [string]$Splash_More_Info,
    $WebView2_URL,
    [string]$SplashLogo,
    [string]$Message,
    [switch]$First_Run,
    $Listener,
    $Global:MahDialog_hash = [hashtable]::Synchronized(@{}),
    [string]$Message_2,
    [switch]$Verboselog,
    $thisApp,
    $thisScript
  )  

  #Create session state for runspace
  $Global:Current_Folder = "$($thisApp.Config.Current_Folder)"
  if(!([System.IO.Directory]::Exists("$Current_Folder\\Views"))){
    $Global:Current_Folder = $($thisScript.path | Split-path -Parent)
  }
  $Splash_Pwshell = {
    try{  
      [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
      Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration
      [void][reflection.assembly]::Load('System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
      [void][reflection.assembly]::Load('System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')     
      $MahDialog_Window_XML = "$($Current_Folder)\\Views\\WebDialog.xaml"
      try{
        if($thisApp.Config.Current_Theme -ne $null -and $thisApp.Config.Current_Theme.Name){
          $theme = [MahApps.Metro.Theming.MahAppsLibraryThemeProvider]::new()
          $themes = $theme.GetLibraryThemes()
          $themeManager = [ControlzEx.Theming.ThemeManager]::new()
          if($synchash.Window.isLoaded){
            $detectTheme = $thememanager.DetectTheme($synchash.Window)
            if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> Current Theme: $($detectTheme | out-string)" -showtime}
            $newtheme = $themes | where {$_.Name -eq $detectTheme.Name}
          }else{
            $newtheme = $themes | where {$_.Name -eq $thisApp.Config.Current_Theme.Name}
          } 
        }
      }catch{
        write-ezlogs "An exception occurred changing theme for Get-loadScreen" -showtime -catcherror $_
      }      
      #[xml]$xaml = Get-content $MahDialog_Window_XML -Force
      [xml]$xaml = [System.IO.File]::ReadAllText($MahDialog_Window_XML).replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml").Replace("{StaticResource MahApps.Brushes.Accent}","$($newTheme.PrimaryAccentColor)")
      $reader=(New-Object System.Xml.XmlNodeReader $xaml)   
      $MahDialog_hash.Window=[Windows.Markup.XamlReader]::Load($reader)
      [xml]$XAML = $xaml
      $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {   
        $MahDialog_hash."$($_.Name)" =  $MahDialog_hash.Window.FindName($_.Name)  
      }        
      $MahDialog_hash.window.title =$SplashTitle
      $MahDialog_hash.Logo.Source=$splashlogo 
      $MahDialog_hash.SplashTitle.Content=$SplashTitle
      $MahDialog_hash.Title_menu_Image.width = "18"  
      $MahDialog_hash.Title_menu_Image.Height = "18" 
      $MahDialog_hash.window.TaskbarItemInfo.Description = "$SplashTitle - $($thisApp.Config.App_Name) - Version: $($thisApp.Config.Version)"
      $MahDialog_hash.Window.icon = $MahDialog_hash.Title_menu_Image.Source
      $MahDialog_hash.Window.IsWindowDraggable="True" 
      $MahDialog_hash.Window.LeftWindowCommandsOverlayBehavior="HiddenTitleBar" 
      $MahDialog_hash.Window.RightWindowCommandsOverlayBehavior="HiddenTitleBar"
      $MahDialog_hash.Window.ShowTitleBar=$true
      $MahDialog_hash.Window.UseNoneWindowStyle = $false
      $MahDialog_hash.Window.WindowStyle = 'none'  
      if($newtheme){    
        try{
          $thememanager.RegisterLibraryThemeProvider($newtheme.LibraryThemeProvider)
          $thememanager.ChangeTheme($MahDialog_hash.Window,$newtheme.Name,$false)      
          if($synchash.GameDetails_Flyout.Background){ 
            $MahDialog_hash.Window.Background = $synchash.GameDetails_Flyout.Background
          }else{
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
            $MahDialog_hash.Window.Background = $gradientbrush  
          }
        }
        catch{
          write-ezlogs "An exception occurred setting theme to $($newtheme | out-string)" -CatchError $_
        } 
      }         
      if($Message){
        $MahDialog_hash.Dialog_Input_texblock.text = $Message
      }
      if($Message_2){
        $MahDialog_hash.Dialog_Input_texblock2.text = $Message_2
      }
      $MahDialog_hash.Dialog_WebView2.Visibility = 'Visible'     
    }catch{
      write-ezlogs "An exception occurred loading assemblines" -showtime -catcherror $_
    }
    write-ezlogs " | Opening URL $($WebView2_URL) - Webview2 folder $env:temp\$($thisApp.Config.App_Name)\Webview2" -showtime
    try{
      #$MahDialog_hash.Dialog_WebView2.CreationProperties = New-Object 'Microsoft.Web.WebView2.Wpf.CoreWebView2CreationProperties'     
      #$MahDialog_hash.Dialog_WebView2.CreationProperties = New-Object 'Microsoft.Web.WebView2.WinForms.CoreWebView2CreationProperties' 
      #$MahDialog_hash.Dialog_WebView2.CreationProperties.UserDataFolder = "$($thisScript.TempFolder)\\Webview2"    
      $WebView2Options = [Microsoft.Web.WebView2.Core.CoreWebView2EnvironmentOptions]::new()
      $WebView2Options.AdditionalBrowserArguments = 'edge-webview-enable-builtin-background-extensions'
      $WebView2Env = [Microsoft.Web.WebView2.Core.CoreWebView2Environment]::CreateAsync(
        [String]::Empty, [IO.Path]::Combine( [String[]]($("$env:temp\$($thisApp.Config.App_Name)"), 'Spotify_Webview2') ), $WebView2Options
      )
      $WebView2Env.GetAwaiter().OnCompleted(
        [Action]{$MahDialog_hash.Dialog_WebView2.EnsureCoreWebView2Async( $WebView2Env.Result )}
      )
      #$null = $MahDialog_hash.Dialog_WebView2.EnsureCoreWebView2Async($WebView2Env.Result ).GetAwaiter()
      $MahDialog_hash.Dialog_WebView2.Add_NavigationCompleted(
        [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs]]{
          write-ezlogs "Navigation completed: $($MahDialog_hash.Dialog_WebView2.source | out-string)" -showtime 
          if($MahDialog_hash.Dialog_WebView2.source.host -eq 'localhost' -and $MahDialog_hash.Dialog_WebView2.source.LocalPath -match '/auth/complete'){
           close-WebLogin
          }
          #$synchash.WebView2.CoreWebView2.PostWebMessageAsString("copy");  
        }
      )    
      $MahDialog_hash.Dialog_WebView2.Add_CoreWebView2InitializationCompleted(
        [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2InitializationCompletedEventArgs]]{
          #$WebView.CoreWebView2.Settings | gm | out-host
          #$MainForm.Add_Activated([EventHandler]{ If ( 0 -cne $MODE_FULLSCREEN ) { $MainForm.Add_FormClosing($CloseHandler) } })
          #$MainForm.Add_Deactivate([EventHandler]{ $MainForm.Remove_FormClosing($CloseHandler) })
          #& $ProcessNoDevTools
          [Microsoft.Web.WebView2.Core.CoreWebView2Settings]$Settings = $MahDialog_hash.Dialog_WebView2.CoreWebView2.Settings
          $Settings.AreDefaultContextMenusEnabled  = $true
          $Settings.AreDefaultScriptDialogsEnabled = $true
          $Settings.AreDevToolsEnabled             = $true
          $Settings.AreHostObjectsAllowed          = $true
          $Settings.IsBuiltInErrorPageEnabled      = $false
          $Settings.IsScriptEnabled                = $true
          $Settings.IsStatusBarEnabled             = $true
          $Settings.IsWebMessageEnabled            = $true
          $Settings.IsZoomControlEnabled           = $false      
          if($WebView2_URL -match 'youtube.com' -or $WebView2_URL -match 'google.com'){
            $Settings.UserAgent = "Chrome"
            $Settings.UserAgent = "Andriod"
          }else{
            $Settings.UserAgent = ""
          }         
          $MahDialog_hash.Dialog_WebView2.CoreWebView2.Navigate($WebView2_URL)
        }
      )
      <#      $MahDialog_hash.Dialog_WebView2.CreationProperties = New-Object 'Microsoft.Web.WebView2.Wpf.CoreWebView2CreationProperties'
          $MahDialog_hash.Dialog_WebView2.CreationProperties.UserDataFolder = "$($thisScript.TempFolder)\\Webview2"
          if($thisApp.Config.Verbose_logging){write-ezlogs "[Show-WebLogin - Webview2] $($MahDialog_hash.Dialog_WebView2.CreationProperties | out-string)"}
          $null = $MahDialog_hash.Dialog_WebView2.EnsureCoreWebView2Async()
          $MahDialog_hash.Dialog_WebView2.Add_CoreWebView2InitializationCompleted({        
          try{        
          if($MahDialog_hash.Dialog_WebView2 -ne $null -and $MahDialog_hash.Dialog_WebView2.CoreWebView2 -ne $null){
          write-ezlogs "[Show-WebLogin - CoreWebView2InitializationCompleted] Navigating with CoreWebView2.Navigate: $($WebView2_URL)" -enablelogs -Color cyan -showtime
          $MahDialog_hash.Dialog_WebView2.CoreWebView2.Navigate($WebView2_URL)
          }
          else{
          write-ezlogs "[Show-WebLogin - CoreWebView2InitializationCompleted] Navigating with Source: $($WebView2_URL)" -enablelogs -Color cyan -showtime
          $MahDialog_hash.Dialog_WebView2.source = $WebView2_URL
          }   
          }catch{
          write-ezlogs "[Show-WebLogin - CoreWebView2InitializationCompleted] An exception occurred initializing the Webview2 controls" -showtime -catcherror $_
          } 
      })#>  
    }catch{
      write-ezlogs "An exeception occurred initializing webview2 in Show-WebLogin" -showtime -catcherror $_
    }    
    <#    $mahdialog_hash.Window.Add_loaded({       
        try{
        }catch{
        write-ezlogs "[Show-WebLogin - Add_loaded] An exception occurred initializing the Webview2 controls" -showtime -catcherror $_
        }

    })#>

    $MahDialog_hash.Cancel_Button.add_click({
        try{
          close-WebLogin
          if($Listener){
            $Listener.Stop()
          }
          return 
        }catch{
          write-ezlogs "An exception occurred in Cancel_Button click event" -showtime -catcherror $_
        } 
    })      
    
    $MahDialog_hash.Window.Add_Closed({     
        param($Sender)    
        if($sender -eq $MahDialog_hash.Window){        
          try{          
            if((Get-Job 'youtubetempwebserver' -ErrorAction SilentlyContinue)){
              write-ezlogs "Stopping youtubetempwebserver job" -showtime
              Stop-Job -Name 'youtubetempwebserver'
            }                        
            write-ezlogs "Show-Weblogin Closed" -showtime            
            return        
          }catch{
            write-ezlogs "An exception occurred closing Show-Weblogin window" -showtime -catcherror $_
            return
          }
        }
    }.GetNewClosure())    
    try{
      <#      if($hashsetup.Window.isVisible){
          $hashsetup.Window.Dispatcher.Invoke("Normal",[action]{ $hashsetup.Window.close() })
      }#>
      if($synchash){
        $synchash.MahDialog_hash = $MahDialog_hash
      }
      [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($MahDialog_hash.Window)
      [void][System.Windows.Forms.Application]::EnableVisualStyles()  
      $null = $MahDialog_hash.window.ShowDialog()
      $window_active = $MahDialog_hash.Window.Activate() 
      $MahDialog_hashContext = New-Object System.Windows.Forms.ApplicationContext 
      [void][System.Windows.Forms.Application]::Run($MahDialog_hashContext)     
    }catch{
      write-ezlogs "An exception occurred when opening main Show-WebLogin window" -showtime -CatchError $_
    }    
  }
  $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}
  Start-Runspace $Splash_Pwshell -Variable_list $Variable_list -StartRunspaceJobHandler -runspace_name 'Show_WebLogin' -logfile $thisApp.Config.Log_File -Script_Modules $thisApp.Config.Script_Modules -thisApp $thisApp -synchash $synchash -verboselog
}
#---------------------------------------------- 
#endregion Show-WebLogin Function
#----------------------------------------------
Export-ModuleMember -Function @('Show-WebLogin','Close-WebLogin')



  