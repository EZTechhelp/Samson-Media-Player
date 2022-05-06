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
# Mahapps Library
Add-Type -AssemblyName WindowsFormsIntegration

#---------------------------------------------- 
#region close-WebLogin Function
#----------------------------------------------
function close-WebLogin (){
  # $MahDialog_hash.window.Dispatcher.Invoke("Normal",[action]{ $MahDialog_hash.window.close() })
  
  try{
    $null = $MahDialog_hash.window.close() 
    $MahDialog_hash.Dialog_WebView2.Dispose()
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
$global:MahDialog_hash = [hashtable]::Synchronized(@{})
function Show-WebLogin{
  Param (
    [string]$SplashTitle,
    [string]$Splash_More_Info,
    $WebView2_URL,
    [string]$SplashLogo,
    [string]$Message,
    [switch]$First_Run,
    $Listener,
    [string]$Message_2,
    [switch]$Verboselog,
    $thisApp,
    $thisScript
  )  
  
  #Create session state for runspace
  $Global:Current_Folder = $($thisScript.path | Split-path -Parent)
  if(!(Test-Path "$Current_Folder\\Views")){
    $Global:Current_Folder = $($thisScript.path | Split-path -Parent | Split-Path -Parent)
  }
  
  $Splash_Pwshell = {
    try{  
      [void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
      Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration
      [void][reflection.assembly]::Load('System.Drawing, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a')
      [void][reflection.assembly]::Load('System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089')
      
    }catch{
      write-ezlogs "An exception occurred loading assemblines" -showtime -catcherror $_
    }

    $MahDialog_Window_XML = "$($Current_Folder)\\Views\\WebDialog.xaml"
    if(!(Test-Path $MahDialog_Window_XML)){
      $Current_Folder = $($thisScript.path | Split-path -Parent | Split-Path -Parent)
      $MahDialog_Window_XML = "$($Current_Folder)\\Views\\WebDialog.xaml"
    }
    [xml]$xaml = Get-content $MahDialog_Window_XML -Force
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
    
    $MahDialog_hash.Window=[Windows.Markup.XamlReader]::Load($reader)

    [xml]$XAML = $xaml
    $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {   
      $MahDialog_hash."$($_.Name)" =  $MahDialog_hash.Window.FindName($_.Name)  
    }        
    $MahDialog_hash.window.title =$SplashTitle
    $MahDialog_hash.Logo.Source=$splashlogo 
    $MahDialog_hash.SplashTitle.Content=$SplashTitle
    $MahDialog_hash.Dialog_WebView2.Visibility = 'Visible'
    write-ezlogs " | Opening URL $($WebView2_URL) - Webview2 folder $($thisScript.TempFolder)\Webview2" -showtime
    try{
      #$MahDialog_hash.Dialog_WebView2.CreationProperties = New-Object 'Microsoft.Web.WebView2.Wpf.CoreWebView2CreationProperties'     
      #$MahDialog_hash.Dialog_WebView2.CreationProperties = New-Object 'Microsoft.Web.WebView2.WinForms.CoreWebView2CreationProperties' 
      #$MahDialog_hash.Dialog_WebView2.CreationProperties.UserDataFolder = "$($thisScript.TempFolder)\\Webview2"    
      $WebView2Options = [Microsoft.Web.WebView2.Core.CoreWebView2EnvironmentOptions]::new()
      $WebView2Options.AdditionalBrowserArguments = 'edge-webview-enable-builtin-background-extensions'
      $WebView2Env = [Microsoft.Web.WebView2.Core.CoreWebView2Environment]::CreateAsync(
        [String]::Empty, [IO.Path]::Combine( [String[]]($($thisScript.TempFolder), 'Webview2') ), $WebView2Options
      )
      $WebView2Env.GetAwaiter().OnCompleted(
        [Action]{$MahDialog_hash.Dialog_WebView2.EnsureCoreWebView2Async( $WebView2Env.Result )}
      )
      #$null = $MahDialog_hash.Dialog_WebView2.EnsureCoreWebView2Async($WebView2Env.Result ).GetAwaiter()
      $MahDialog_hash.Dialog_WebView2.Add_NavigationCompleted(
        [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs]]{
          #write-ezlogs "Navigation completed: $($synchash.WebView2.source | out-string)" -showtime
          $MahDialog_hash.Dialog_WebView2.ExecuteScriptAsync(
            @"
document.addEventListener('click', function (event)
{
    let elem = event.target;
    let jsonObject =
    {
        Key: 'click',
        Value: elem.outerHTML || "Unkown" 
    };
    window.chrome.webview.postMessage(jsonObject);
});
"@)  
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
          $Listener.Stop()
          return 
        }catch{
          write-ezlogs "An exception occurred in Cancel_Button click event" -showtime -catcherror $_
        } 
    })      
    
    $MahDialog_hash.Window.Add_Closed({     
        param($Sender)    
        if($sender -eq $MahDialog_hash.Window){        
          try{          
            #$MahDialog_hashContext.ExitThread()
            #$MahDialog_hash = $Null
            write-ezlogs "Show-Weblogin Closed" -showtime
            return        
          }catch{
            write-ezlogs "An exception occurred closing Show-Weblogin window" -showtime -catcherror $_
            return
          }
        }
    }.GetNewClosure())    

    [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($MahDialog_hash.Window)
    [void][System.Windows.Forms.Application]::EnableVisualStyles()   
    try{

      $null = $MahDialog_hash.window.ShowDialog()
      $window_active = $MahDialog_hash.Window.Activate() 

      $MahDialog_hashContext = New-Object System.Windows.Forms.ApplicationContext 
      [void][System.Windows.Forms.Application]::Run($MahDialog_hashContext)   

       
    }catch{
      write-ezlogs "An exception occurred when opening main Show-WebLogin window" -showtime -CatchError $_
    }    

  }
  $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}
  Start-Runspace $Splash_Pwshell -Variable_list $Variable_list -StartRunspaceJobHandler -runspace_name 'Show_WebLogin' -logfile $thisApp.Config.Log_File -Script_Modules $thisApp.Config.Script_Modules  
}
#---------------------------------------------- 
#endregion Show-WebLogin Function
#----------------------------------------------
#Show-MahDialog -SplashTitle "EPIC Account Login" -SplashMessage "Splash Message" -SplashLogo "C:\Users\DopaDodge\OneDrive - EZTechhelp Company\Development\Repositories\EZT-GameManager\Resources\Platforms\EPIC.ico" -WebView2_URL 'https://www.epicgames.com/id/login?redirectUrl=https://www.epicgames.com/id/api/redirect'
Export-ModuleMember -Function @('Show-WebLogin','Close-WebLogin')



  