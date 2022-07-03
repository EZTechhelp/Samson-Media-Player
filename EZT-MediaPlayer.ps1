<#
    .Name
    EZT-MediaPlayer

    .Version 
    0.4.7

    .SYNOPSIS
    Simple media player built in powershell that allows playback and playlist management from multiple media sources such as local disk, Spotify, Youtube, Twitch and others. Powered by LibVLCSharp

    .DESCRIPTION
       
    .Requirements
    - Powershell v3.0 or higher

    .EXAMPLE
    \EZT-MediaPlayer.ps1

    .OUTPUTS
    System.Management.Automation.PSObject

    .Credits
    yt-dlp                     - https://github.com/yt-dlp/yt-dlp
    LibvlcSharp                - https://github.com/videolan/libvlcsharp
    BetterFolderBrowser        - https://github.com/Willy-Kimura/BetterFolderBrowser
    GongSolutions.WPF.DragDrop - https://github.com/punker76/gong-wpf-dragdrop
    SpotiShell                 - https://github.com/wardbox/spotishell
    Spicetify                  - https://github.com/khanhas/Spicetify
    PODE                       - https://github.com/Badgerati/Pode
    MahApp.Metro               - https://github.com/MahApps/MahApps.Metro
    BurntToast                 - https://github.com/Windos/BurntToast
    Streamlink                 - https://github.com/streamlink/streamlink
    Youtube                    - https://github.com/pcgeek86/youtube/

    .NOTES
    Author: EZTechhelp
    Site  : https://www.eztechhelp.com
#> 

#############################################################################
#region Configurable Script Parameters
#############################################################################
Param(
  [string]$MediaFile,
  [switch]$PlayMedia
)
$script:startup_stopwatch = [system.diagnostics.stopwatch]::StartNew() #startup performance timer

#---------------------------------------------- 
#region Required Assemblies
#----------------------------------------------
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName WindowsFormsIntegration
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
#---------------------------------------------- 
#endregion Required Assemblies
#----------------------------------------------

#---------------------------------------------- 
#region Log Variables
#----------------------------------------------
$logdateformat = 'MM/dd/yyyy h:mm:ss tt' # sets the date/time appearance format for log file and console messages
$enablelogs = 1 # enables creating a log file of executed actions, run history and errors. 1 = Enable, 0 (or anything else) = Disable
$verboselog = $true #Enables extra verbose output to logs and console, meant for dev/troubleshooting
$logfile_directory = "$env:appdata\" # directory where log file should be created if enabled
#---------------------------------------------- 
#endregion Log Variables
#----------------------------------------------

#---------------------------------------------- 
#region Registry Values
#----------------------------------------------
$regpath = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' #The full path to the registry key were the key value is located
$regkeyproperty = 'EnableLinkedConnections' #Name of the the Reg Key Value
$regkeypropertyvalue = '1' #Desired Value to set of the reg key value
$regkeypropertyvaluetype = 'DWORD' #Desired value type of the reg key value
#---------------------------------------------- 
#endregion Registry Values
#----------------------------------------------

#---------------------------------------------- 
#region Global Variables - DO NOT CHANGE UNLESS YOU KNOW WHAT YOU'R DOING
#----------------------------------------------
$required_appnames = 'Spotify','Spicetify','streamlink'
$startup_perf_timer = $true
$Required_Remote_Modules = 'BurntToast','Microsoft.PowerShell.SecretManagement','Microsoft.PowerShell.SecretStore' #these modules are automatically installed and imported if not already

#$Required_Remote_Modules = 'Microsoft.PowerShell.SecretManagement','Microsoft.PowerShell.SecretStore','BurntToast','pode'

$Required_modules = @( #these local only modules are automatically installed and imported if not already
  'Write-EZLogs',
  'Start-RunSpace',
  'Import-Media',
  'Get-HelperFunctions',
  'Get-LocalMedia',
  'Start-Media',
  'Get-Spotify',
  'Start-SpotifyMedia',
  'Import-Spotify',
  'Get-InstalledApplications',
  'Add-Playlist',
  'Get-Playlists',
  'Spotishell',
  'Show-FeedBackForm',
  'Get-LoadScreen',
  'Show-FirstRun',
  'Show-WebLogin',
  'Get-Youtube',
  'Import-Youtube',
  'Invoke-DownloadMedia',
  'Update-LogWindow',
  'Update-Notifications',
  'Get-TwitchAPI',
  'Add-EQPreset',
  'Start-Keywatcher',
  'Update-Playlist',
  'Update-MediaTimer',
  'Invoke-Spicetify',
  'Stop-Media',
  'Add-TrayMenu',
  'Youtube',
  'Get-Trello',
  'Skip-Media',
  'Get-YouTubePlaylists',
  'Initialize-WebView2',
  'Add-YoutubePlayback',
  'Set-Shuffle',
  'Get-PlayQueue',
  'New-ScreenShot',
  'Find-FilesFast',
  'Get-OpenBreweryDB'
)  
$update_modules = $false # enables checking for and updating all required modules for this script. Potentially adds a few seconds to total runtime but ensures all modules are the latest
$force_modules = $false # enables installing and importing of a module even if it is already. Should not be used unless troubleshooting module issues 
$SplashScreenAudio = $false
$enable_Marquee = $false #enables display of Marquee text over video player
$hide_Console = $false # hides the powershell console while app is running. Useful for UI apps and ensuring the UI App's icon displays in taskbar instead of with the Powershell icon
$dev_Override = $true #Used to override certain defaults or settings not available to users
$Visible_Fields = @( #Allowed fields/columns to be displayed in Media datagrids
  'Title'
  'Track_number'
  'Live_Status'
  'Duration'
  'Artist'
  'Live_Status'
  'Album_name'
  'Playlist' 
  'Directory'
  'Size'
  'Type'
  'Play'
  'Select'
) 
$media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)mp4|(?i)flac|(?i)wav|(?i)avi|(?i)wmv|(?i)h264|(?i)mkv|(?i)webm|(?i)h265|(?i)mov|(?i)h264|(?i)mpeg|(?i)mpg4|(?i)movie|(?i)mpgx|(?i)vob|(?i)3gp|(?i)m2ts|(?i)aac))')
$brynePlayer = $true
#---------------------------------------------- 
#endregion Global Variables - DO NOT CHANGE UNLESS YOU KNOW WHAT YOU'R DOING
#----------------------------------------------
#############################################################################
#endregion Configurable Script Parameters
#############################################################################

#############################################################################
#region global functions - Must be run first and/or are script agnostic
#############################################################################
$Global:Script_Modules = New-Object System.Collections.ArrayList
$PSModuleAutoLoadingPreference = 'All'
#---------------------------------------------- 
#region Use Run-As Function
#----------------------------------------------
function Use-RunAs 
{    
  # Check if script is running as Adminstrator and if not use RunAs 
  # Use Check Switch to check if admin 
  # http://gallery.technet.microsoft.com/scriptcenter/63fd1c0d-da57-4fb4-9645-ea52fc4f1dfb
    
  param([Switch]$Check,[Switch]$ForceReboot,[Switch]$uninstall_Module,[string]$logfile = $logfile) 
  $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator') 
  if ($Check) { return $IsAdmin }     
  if ($MyInvocation.ScriptName -ne '') 
  {  
    if (-not $IsAdmin -or $ForceReboot)  
    {  
      try 
      {  
        #$arg = "-file `"$($MyInvocation.ScriptName)`""         
        $ScriptPath = $((Get-PSCallStack).ScriptName | where {$_ -notmatch '.psm1'} | select -First 1)
        "[$(Get-Date -format $logdateformat)] Script requesting Admin Permissions to install requirements, restarting with Path: $($ScriptPath)" | Out-File -FilePath $logfile -Encoding unicode -Append        
        if($uninstall_Module){
          $arg = "-NoProfile -ExecutionPolicy Bypass -file `"$($ScriptPath)`" -NonInteractive"
        }else{
          $arg = "-NoProfile -ExecutionPolicy Bypass -file `"$($ScriptPath)`""
        }
        if($hash.Window.IsVisible){
          close-splashscreen
        }
        if([System.IO.File]::Exists("$env:programfiles\PowerShell\7\pwsh.exe")){
          $process = Start-Process "$env:programfiles\PowerShell\7\pwsh.exe" -Verb Runas -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden
        }else{         
          Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden
        }
      } 
      catch 
      { 
        "[$(Get-Date -format $logdateformat)] Failed to restart script with runas $($_ | select *)" | Out-File -FilePath $logfile -Encoding unicode -Append
        break               
      } 
      if($pid){
        stop-process $pid -Force -ErrorAction SilentlyContinue
      }      
      exit # Quit this session of powershell 
    }  
  }  
  else  
  {   
    "[$(Get-Date -format $logdateformat)] [WARNING] Script must be saved as a .ps1 file first" | Out-File -FilePath $logfile -Encoding unicode -Append
    break  
  }  
}
#---------------------------------------------- 
#endregion Use Run-As Function
#----------------------------------------------

#---------------------------------------------- 
#region Load-Modules Function
#----------------------------------------------
function Load-Modules {
  
  param
  (
    $local_modules,
    $Remote_modules,
    [switch]$force,

    [switch]$update,

    [switch]$enablelogs,

    [switch]
    $Verboselog,

    [switch]
    $local_import,

    $logfile
  )
  $ExistingPaths = $Env:PSModulePath -split ';' -replace '\\$',''
  if($local_import -and $local_modules){
    if($psversiontable.PSVersion.Major -gt 5){
      if ($VerboseLog){"[$(Get-Date -format $logdateformat)] Running PowerShell $($psversiontable.PSVersion.Major), Importing Module Appx with parameter -usewindowspowershell" | Out-File -FilePath $logfile -Encoding unicode -Append}
      Import-module Appx -usewindowspowershell
    }  
    foreach($m in  $local_modules){    
      if([System.IO.File]::exists("$PSScriptRoot\Modules\$m\$m.psm1")){
        $module_path = "$PSScriptRoot\Modules\$m\$m.psm1"
      }elseif([System.IO.File]::exists("$([System.IO.Directory]::GetParent($PSScriptRoot))\Modules\$m\$m.psm1")){
        $module_path = "$([System.IO.Directory]::GetParent($PSScriptRoot))\Modules\$m\$m.psm1"
      }elseif([System.IO.File]::exists(".\Modules\$m\$m.psm1")){
        $module_path = ".\Modules\$m\$m.psm1"
      }else{
        "[$(Get-Date -format $logdateformat)] [Load-Module ERROR] Unable to find module $m -- PSScriptRoot: $PSScriptRoot" | Out-File -FilePath $logfile -Encoding unicode -Append
      }     
      try{
        $module_root_path = [System.IO.Directory]::GetParent($module_path).fullname  
        $null = $Script_Modules.Add($module_path)
        if($PSVersionTable.psversion.Major -gt 5){
          #import-module $module_path -Force
        }        
        if($ExistingPaths -notcontains $module_root_path) {
          $Env:PSModulePath = $module_root_path + ';' + $Env:PSModulePath
        }
        if($m -eq 'Spotishell'){
          #Import-Module $module_path #-Force
        }
        $PSModuleAutoLoadingPreference = 'All'
      }
      catch{
        "[$(Get-Date -format $logdateformat)] [Load-Module ERROR] An exception occurred importing module $m $($_ | Select *)" | Out-File -FilePath $logfile -Encoding unicode -Append
        exit
      }      
    }
    return $Script_Modules
  }else{
    try{  
      #$PackageXML = Get-ChildItem "$env:ProgramFiles\WindowsPowerShell\Modules\PowerShellGet\1.0.0.1\" -Filter 'PSModule.psm1' -Recurse -force | select -Last 1
      if([System.IO.Directory]::Exists("$env:ProgramFiles\PackageManagement\ProviderAssemblies\nuget")){
        $NugetVersion = (Get-ChildItem "$env:ProgramFiles\PackageManagement\ProviderAssemblies\Nuget\*").Name
      }elseif([System.IO.Directory]::Exists("$env:LocalAppdata\PackageManagement\ProviderAssemblies\Nuget\")){
        $NugetVersion = (Get-ChildItem "$env:LocalAppdata\PackageManagement\ProviderAssemblies\Nuget\*").Name
      }
    }
    catch{
      "[$(Get-Date -format $logdateformat)] [Load-Module ERROR] An exception occurred checking for Package Provider Nuget $($_ | Select *)" | Out-File -FilePath $logfile -Encoding unicode -Append
    }  
    if($NugetVersion -ge '2.8.5.201') {
      if($enablelogs){Write-Verbose -Message "[$(Get-Date -format $logdateformat)] | Required PackageProvider Nuget is installed."
      "[$(Get-Date -format $logdateformat)] | Required PackageProvider Nuget is installed." | Out-File -FilePath $logfile -Encoding unicode -Append -Force}
    }
    else{
      try{        
        if(!$hash.Window){
          start-sleep -Milliseconds 500
        }         
        if($hash.Window){
          $hash.Window.Dispatcher.invoke([action]{
              $hash.More_Info_Msg.Visibility = 'Visible'
              $hash.More_info_Msg.text = 'Installing and Registering Package Provider Nuget'
          },'Normal')
        }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
        if((Use-RunAs -Check)){
          Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
        }else{
          Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -Scope CurrentUser
        }        
        Register-PackageSource -Name nuget.org -Location https://www.nuget.org/api/v2 -ProviderName NuGet -Trusted -Force -Confirm:$false
      }
      catch{
        "[$(Get-Date -format $logdateformat)] [Load-Module ERROR] An exception occurred Installing and Registering Package Provider Nuget $($_ | Select *)" | Out-File -FilePath $logfile -Encoding unicode -Append
      }
    }
    #Install latest version of PowerShellGet
    if($PSVersionTable.psversion.Major -gt 5){
      $PowershellGetPath = "$env:ProgramFiles\powershell\7\Modules\PowerShellGet\*"
      $PowerShellGetModule = (Get-ChildItem $PowershellGetPath -Filter "PowerShellGet.psd1").FullName
      $PowershellGet = ([regex]::matches((select-string -literalpath $PowerShellGetModule -Pattern "ModuleVersion     = '(?<value>.*)'" -AllMatches),  "ModuleVersion     = '(?<value>.*)'") | %{$_.groups[1].value} )
    }else{
      $PowershellGetPath = "$env:ProgramFiles\WindowsPowershell\Modules\PowerShellGet\*"
      $PowershellGet = (Get-ChildItem $PowershellGetPath).Name  | Where {$_ -ge '2.2.5'}
    }    
    if(!($PowershellGet | Where {$_ -ge '2.2.5'}))
    {
      try{  
        if($hash.Window.Dispatcher){
          $hash.Window.Dispatcher.invoke([action]{
              $hash.More_Info_Msg.Visibility = 'Visible'
              $hash.More_info_Msg.text = 'Installing Module PowershellGet v2.2.5'
          },'Normal')  
        }
        Write-Verbose -Message "[$(Get-Date -format $logdateformat)] | PowershellGet version too low, updating to 2.2.5"
        if($enablelogs){"[$(Get-Date -format $logdateformat)] | PowershellGet version too low, updating to 2.2.5" | Out-File -FilePath $logfile -Encoding unicode -Append -Force}
        if((Use-RunAs -Check)){
          Install-Module -Name 'PowershellGet' -MinimumVersion '2.2.5' -Force -Confirm:$false
        }else{
          Install-Module -Name 'PowershellGet' -MinimumVersion '2.2.5' -Force -Scope CurrentUser -Confirm:$false
        }     
      }
      catch{
        "[$(Get-Date -format $logdateformat)] [Load-Module ERROR] An exception occurred installing PowerShellGet version 2.2.5 $($_ | Select *)" | Out-File -FilePath $logfile -Encoding unicode -Append
      } 
    }  
    $module_list = New-Object System.Collections.ArrayList
    
 
    foreach($path in $Env:PSModulePath -split ';'){
      if([System.IO.Directory]::Exists($path)){         
        $mod_dirs = [System.IO.Directory]::GetDirectories($path)
        $mod_path = ($mod_dirs | where {$Remote_Modules -contains [System.IO.Path]::GetFileName($_)})        
        $mod_path | foreach{
          $Name = [System.IO.Path]::GetFileName($_)
          if($Name -and $_){
            $module = New-Object PsObject -Property @{
              'Name' = $Name
              'Path' = $_
            }      
            if($module_list -notcontains $module){
              $null = $module_list.add($module)
            }  
          }               
        }
        #$module_list += Get-ChildItem $path #using get-childitem against PSModulePath is much faster thant using Get-Module -ListAvailable. Potential downside is it doesnt verify module is valid only that it exists
      }
    }   
    foreach ($m in $Remote_modules){  
      if($module_list.Name -contains $m -or $module_list.Path -match $m){       
        $PSModuleAutoLoadingPreference = 'ModuleQualified'
        if($PSVersionTable.PSVersion.Major -gt 5){
          if($enablelogs){Write-Verbose -Message "[$(Get-Date -format $logdateformat)] | Required Module $m is available on disk."
          "[$(Get-Date -format $logdateformat)] | Required Module $m is available on disk." | Out-File -FilePath $logfile -Encoding unicode -Append -Force}
          #Import-module $m
        }else{
          if($enablelogs){Write-Verbose -Message "[$(Get-Date -format $logdateformat)] | Required Module $m is available on disk."
          "[$(Get-Date -format $logdateformat)] | Required Module $m is available on disk. $(($module_list | where {$_.Name -eq $m}).path)" | Out-File -FilePath $logfile -Encoding unicode -Append -Force}
        }
        if($update){
          Write-Verbose -Message "[$(Get-Date -format $logdateformat)] | Updating module: $m"
          if($enablelogs){"[$(Get-Date -format $logdateformat)] | Updating module: $m" | Out-File -FilePath $logfile -Encoding unicode -Append -Force}
          Update-Module -Name $m -Force -ErrorAction Continue
        }
        if($force){
          Write-Verbose -Message "[$(Get-Date -format $logdateformat)] | Force parameter applied - Importing $m"
          if($enablelogs){"[$(Get-Date -format $logdateformat)] | Force parameter applied - Importing $m" | Out-File -FilePath $logfile -Encoding unicode -Append -Force}
          if((Use-RunAs -Check)){
            Import-Module $m -Verbose -force -Scope Global
          }else{
            Import-Module $m -Verbose -force -Scope Local
          }                        
        }
      }
      else {
        #If module is not imported, not available on disk, but is in online gallery then install and import
        if (Find-Module -Name $m) {
          if($m -match 'Pode'){
            if($enablelogs){"[$(Get-Date -format $logdateformat)] [WARNING] | PODE Module is not Installed!" | Out-File -FilePath $logfile -Encoding unicode -Append -Force}
          }else{
            if($hash.Window.Dispatcher){
              $hash.Window.Dispatcher.invoke([action]{
                  $hash.More_Info_Msg.Visibility = 'Visible'
                  $hash.More_info_Msg.text = "Installing Module $m"
              },'Normal')  
            }
            Write-Verbose -Message "[$(Get-Date -format $logdateformat)] | Installing Module $m"
            if($enablelogs){"[$(Get-Date -format $logdateformat)] | Installing Module $m" | Out-File -FilePath $logfile -Encoding unicode -Append -Force}      
            try{
              if((Use-RunAs -Check)){
                Install-Module -Name $m -Force -Verbose -AllowClobber -Scope AllUsers
                Import-Module $m -Verbose -force -Scope Global
              }else{
                Install-Module -Name $m -Force -Verbose -AllowClobber -Scope CurrentUser
                Import-Module $m -Verbose -force -Scope Local
              }           
            }
            catch{
              "[$(Get-Date -format $logdateformat)] [Load-Module ERROR] An exception occurred Installing module $m $($_ | Out-String)" | Out-File -FilePath $logfile -Encoding unicode -Append
            }
          }
        }
        else {
          #If module is not imported, not available and not in online gallery then abort
          "[$(Get-Date -format $logdateformat)] [Load-Module ERROR] Required module $m not imported, not available and not in online gallery, exiting." | Out-File -FilePath $logfile -Encoding unicode -Append
          EXIT 1
        }
      }    
    }
  }
}
#---------------------------------------------- 
#endregion Load-Modules Function
#----------------------------------------------

#---------------------------------------------- 
#region Show/Hide Console Functions
#----------------------------------------------

function Show-Console
{
  $consolePtr = [Console.Window]::GetConsoleWindow()

  # Hide = 0,
  # ShowNormal = 1,
  # ShowMinimized = 2,
  # ShowMaximized = 3,
  # Maximize = 3,
  # ShowNormalNoActivate = 4,
  # Show = 5,
  # Minimize = 6,
  # ShowMinNoActivate = 7,
  # ShowNoActivate = 8,
  # Restore = 9,
  # ShowDefault = 10,
  # ForceMinimized = 11

  [Console.Window]::ShowWindow($consolePtr, 4)
}
function Hide-Console
{
  # .Net methods for hiding/showing the console in the background
  Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
  '
  $consolePtr = [Console.Window]::GetConsoleWindow()
  #0 hide
  [Console.Window]::ShowWindow($consolePtr, 0)
}
#---------------------------------------------- 
#endregion Show/Hide Console Functions
#----------------------------------------------
#############################################################################
#endregion global Functions
#############################################################################

#############################################################################
#region Core Functions - The primary Functions specific to this script
#############################################################################

#---------------------------------------------- 
#region Process XAML
#----------------------------------------------
function Initialize-XAML
{
  param (
    [string]$Current_folder,
    $thisApp
  )

  $Main_Window_XML = "$($Current_folder)\\views\\MainWindow.xaml"      
  $XamlSettings = [System.IO.File]::ReadAllText("$($Current_folder)\\Views\\Settings.xaml")
  $XamlWebWindow = [System.IO.File]::ReadAllText("$($Current_folder)\\Views\\WebBrowser.xaml")
  $XamlSpotifyBrowser = [System.IO.File]::ReadAllText("$($Current_folder)\\Views\\SpotifyBrowser.xaml")
  $XamlyoutubeBrowser = [System.IO.File]::ReadAllText("$($Current_folder)\\Views\\YoutubeBrowser.xaml")
  #$XamlTwitchBrowser = [System.IO.File]::ReadAllText("$($Current_folder)\\Views\\TwitchBrowser.xaml")
  if($thisApp.Config.Current_Theme -ne $null -and $thisApp.Config.Current_Theme.PrimaryAccentColor){
    $PrimaryAccentColor = $thisApp.Config.Current_Theme.PrimaryAccentColor
  }else{
    $PrimaryAccentColor = "{StaticResource MahApps.Brushes.Accent}"
  }
  [xml]$xaml = [System.IO.File]::ReadAllText($Main_Window_XML).replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml").Replace("<Tabitem Name=`"SETTINGS_REPLACE_ME`"/>","$XamlSettings").Replace(`
  "<Tabitem Name=`"WebBrowser_REPLACE_ME`"/>","$XamlWebWindow").Replace("<Tabitem Name=`"SPOTIFYBROWSER_REPLACE_ME`"/>","$XamlSpotifyBrowser").Replace("<Tabitem Name=`"YOUTUBEBROWSER_REPLACE_ME`"/>","$XamlYoutubeBrowser").Replace("{StaticResource MahApps.Brushes.Accent}","$($PrimaryAccentColor)")#.Replace("<Tabitem Name=`"TWITCHBROWSER_REPLACE_ME`"/>","$XamlTwitchBrowser")

  $synchash = [hashtable]::Synchronized(@{})
  $reader = (New-Object System.Xml.XmlNodeReader $xaml) 
  $synchash.Window = [Windows.Markup.XamlReader]::Load($reader)
  #$xamlReader = [Windows.Markup.XamlReader]::new()
  #$synchash.Window = $xamlReader.LoadAsync($reader)
  
  [xml]$xaml = $xaml
  $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | foreach {$synchash."$($_.Name)" = $synchash.window.FindName($_.Name)}

  return $synchash
}
#---------------------------------------------- 
#endregion Process XAML
#----------------------------------------------


#############################################################################
#endregion Core Functions
#############################################################################

#############################################################################
#region Initialization Events
#############################################################################
try
{ 
  $Global:thisapp = [hashtable]::Synchronized(@{})
  $Global:MahDialog_hash = [hashtable]::Synchronized(@{}) 
  #$Global:all_playlists = [hashtable]::Synchronized(@{})
  if($hide_Console){
    Hide-Console
    if($startup_perf_timer){ $Hide_Console_Perf = "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Hide Console:           $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds"}
  } 

  #Set startup logging and variable paths
  $AppRoot = ([System.IO.Directory]::GetParent($PSCommandPath))
  $logdirectory = "$logfile_directory\$($AppRoot.Name)\Logs"
  if(!([System.IO.Directory]::Exists($logdirectory))){
    $null = New-item $logdirectory -ItemType Directory -Force
  }    
  $current_folder = $AppRoot.fullname
  $startup_log = "$logdirectory\$($AppRoot.name)-Startup.log"
  $App_Settings_Directory = "$env:appdata\\$($AppRoot.name)"
  $script:App_Settings_File_Path = "$App_Settings_Directory\\$($AppRoot.name)-Config.xml"
  $Env:PSModulePath = "$Current_Folder\Modules" + ';' + $Env:PSModulePath  
  
  #Verify app not already running
  if($dev_Override){
    write-output "[$([datetime]::Now.ToString($logdateformat))] [WARNING] !!DEV OVERRIDE MODE ENABLED!!" | out-file $startup_log -Force -Append -Encoding unicode
  }elseif($process = (get-process *p*) | where {$_.MainWindowTitle -match "$($AppRoot.name) - Version:"}){
    if([System.IO.File]::Exists("$Current_Folder\\Version.txt")){
      try{
        $version = [System.IO.File]::ReadAllLines("$Current_Folder\\Version.txt")
        if($enablelogs){write-output "[$([datetime]::Now.ToString($logdateformat))] | Startup Version: $version" | out-file $startup_log -Force -Append -Encoding unicode}
      }catch{
        write-output "[$([datetime]::Now.ToString($logdateformat))] [STARTUP-ERROR] An exception occurred reading $Current_Folder\\Version.txt $($_ | out-string)" | out-file $startup_log -Force -Append -Encoding unicode
      }
    }
    write-output "[$([datetime]::Now.ToString($logdateformat))] [WARNING] Existing Process with PID $($process.id) for ($($AppRoot.name) - Version: $version) already running!`n[$([datetime]::Now.ToString($logdateformat))] | CommandLine: $((Get-CimInstance win32_process | where {$_.ProcessId -eq $($process.id)}).CommandLine) " | out-file $startup_log -Force -Append -Encoding unicode
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $oReturn=[System.Windows.Forms.MessageBox]::Show("[WARNING]`nExisting Process with PID $($process.id) for ($($AppRoot.name) - Version: $version) already running!`n`nThis app will now close","$($AppRoot.name)",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) 
    switch ($oReturn){
      "OK" {
        write-host "You pressed OK"
        # Enter some code
      } 
      "Cancel" {
        write-host "You pressed Cancel"
        # Enter some code
      } 
    }       
    exit
  }
  
  #Load Splash Screen 
  $Start_SplashScreen_Measure = measure-command{
    if(!$hash.window.IsVisible){   
      if(([System.IO.File]::Exists($App_Settings_File_Path))){
        $thisapp.Config = Import-Clixml $App_Settings_File_Path
      }
      $Start_SplashScreen = Start-SplashScreen -SplashTitle $($AppRoot.name) -SplashMessage 'Starting Up...' -current_folder $($current_folder) -startup -log_file $startup_log -Script_modules $Script_Modules -Verboselog:$verboselog -startup_stopwatch $startup_stopwatch -startup_perf_timer $startup_perf_timer -PlayAudio:$thisapp.config.SplashScreenAudio
    }else{
      $hash.Window.Dispatcher.invoke([action]{$hash.LoadingLabel.Content = 'Starting Up...'},'Normal')
    } 
  }
  if($startup_perf_timer){ $Start_SplashScreen_Perf = "$Start_SplashScreen`n[$(Get-date -format $logdateformat)]     | Start-SplashScreen Total: $($Start_SplashScreen_Measure.Seconds) seconds - $($Start_SplashScreen_Measure.Milliseconds) Milliseconds"}
  #Load Required Modules and Start Logging
  $Local_Load_Modules_Measure = measure-command{
    $Script_Modules = Load-Modules -local_modules $Required_modules -force:$force_modules -update:$update_modules -local_import:$true -logfile $startup_log 
  }
  if($startup_perf_timer){ $Local_Load_Modules_Perf = "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Local Load-Modules: $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds`n[$(Get-date -format $logdateformat)]     | Local Load Modules Total: $($Local_Load_Modules_Measure.Seconds) seconds - $($Local_Load_Modules_Measure.Milliseconds) Milliseconds"}

  $thisScript_Measure = measure-command{
    $thisScript = Get-ThisScriptInfo -ScriptPath $PSCommandPath
  }
  if($startup_perf_timer){$Get_thisScriptInfo_Perf = "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Get-thisscriptinfo:    $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds`n[$(Get-date -format $logdateformat)]     | Get-thisscriptinfo Total: $($thisScript_Measure.Seconds) seconds - $($thisScript_Measure.Milliseconds) Milliseconds"}
  $logfile_directory = "$logfile_directory\$($thisScript.Name)\Logs"
  if(!([System.IO.File]::Exists("$logfile_directory\\$($thisScript.Name)-$($thisScript.version).log"))){
    $FreshStart = $true
    $force_modules = $true
    #$synchash.Youtube_FirstRun = $true
  }
  else{
    $FreshStart = $false
    $force_modules = $false
  }    
 
  #$script:Current_Folder = $($thisScript.path | Split-Path -Parent)
  $Start_EZLogs_Measure = measure-command{
    $Global:logfile = Start-EZLogs -logfile_directory $logfile_directory -ScriptPath $PSCommandPath -thisScript $thisScript
  }

  if($startup_perf_timer){$Start_EZlogs_Perf = "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Start-ezlogs:          $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds`n[$(Get-date -format $logdateformat)]     | Start-EZlogs Total: $($Start_EZLogs_Measure.Seconds) seconds - $($Start_EZLogs_Measure.Milliseconds) Milliseconds"} 
  $Remote_modules = Load-Modules -Remote_modules $Required_Remote_Modules -local_modules $Required_modules -force:$force_modules -update:$update_modules -local_import:$false -logfile $logfile -Verboselog:$verboselog -enablelogs  
  if($startup_perf_timer){$Load_Modules_Perf = "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Load-Modules:          $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds"}
  
  #Load and Initialize UI XAML
  $Initialize_Xaml_Measure = measure-command {
    $Global:synchash = Initialize-XAML -Current_folder $Current_folder -thisApp $thisApp
  } 
  if($startup_perf_timer){$Initialize_Xaml_Perf =  "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Initialize-Xaml:  $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds`n[$(Get-date -format $logdateformat)]     | Initialize-Xaml Total: $($Initialize_Xaml_Measure.Seconds) seconds - $($Initialize_Xaml_Measure.Milliseconds) Milliseconds"}
  
  $synchash.Window.Title = "$($thisScript.Name) - Version: $($thisScript.Version)"
  $synchash.leftwindow_button.tooltip = "$($thisScript.Name) - Version: $($thisScript.Version)"
  $synchash.window.TaskbarItemInfo.Description = "$($thisScript.Name) - Version: $($thisScript.Version)"
  $synchash.Window.ShowTitleBar = $true
  $synchash.Window.UseNoneWindowStyle = $false
  $synchash.Window.IgnoreTaskbarOnMaximize = $false
  $synchash.Window.WindowState = 'Normal'  
  #$synchash.Title_bar_Image.Source = "$($Current_folder)\\Resources\\MusicPlayerFilltest.ico"
  $synchash.Title_bar_Image.width = '18'  
  $synchash.Title_bar_Image.Height = '18'
  $synchash.Window.icon = "$($Current_folder)\\Resources\\MusicPlayerFilltest.ico"
  $syncHash.MainGrid_Background_Image_Source_transition.content = ''
}
catch
{
  write-ezlogs '[ERROR] An exception occured during script initialization' -showtime -catcherror $_
  exit
}
#Load App Configs
$App_Settings_Directory = "$env:appdata\\$($thisScript.Name)"
$script:App_Settings_File_Path = "$App_Settings_Directory\\$($thisScript.Name)-Config.xml"
if(!([System.IO.Directory]::Exists($App_Settings_Directory))){
  write-ezlogs ">>>> Creating App Settings Directory $App_Settings_Directory" -showtime -enablelogs -color cyan
  $null = New-Item $App_Settings_Directory -ItemType Directory -Force
}
if(!([System.IO.File]::Exists($App_Settings_File_Path))){
  $FreshStart = $true
  write-ezlogs ">>> This version $($thisScript.version) has not been run on this system before, wiping caches and initiating first time setup" -showtime -enablelogs -color cyan
  write-ezlogs " | App settings file not found..creating default $App_Settings_File_Path" -showtime -enablelogs -color cyan 
  $thisapp.Config = Import-Clixml "$($Current_folder)\\Resources\\Templates\\App-Config.xml"
  #TODO: Enable Verbose logging on any fresh run, temporary for dev purposes
  $thisapp.Config.Verbose_logging = $true
  $thisapp.config.App_Name = $($thisScript.Name)
  $thisapp.config.App_Version = $($thisScript.Version)
  $thisapp.config.Media_Profile_Directory = "$env:appdata\\$($thisScript.Name)\\MediaProfiles"
  $thisapp.config.image_Cache_path = "$($thisScript.TempFolder)\\Images"
  $thisapp.config.Playlist_Profile_Directory = "$env:appdata\\$($thisScript.Name)\\PlaylistProfiles"
  $thisapp.config.EQPreset_Profile_Directory = "$env:appdata\\$($thisScript.Name)\\EQPresets"
  $thisapp.config.Config_Path = $App_Settings_File_Path
  $thisapp.config.Templates_Directory = "$($Current_folder)\\Resources\\Templates"
  $thisapp.config.Current_Folder = "$($Current_folder)"
  $thisapp.config.Log_file = $logfile
  Add-Member -InputObject $thisapp.config -Name 'Script_Modules' -Value $($Script_Modules) -MemberType NoteProperty -Force
  write-ezlogs " | Saving app config: $App_Settings_File_Path" -showtime -enablelogs
  $thisapp.config | Export-Clixml -Path $App_Settings_File_Path -Force -Encoding UTF8      
}
else{
  write-ezlogs " | Loading app config: $App_Settings_File_Path" -showtime -enablelogs
  $thisapp.config = Import-Clixml -Path $App_Settings_File_Path
  Add-Member -InputObject $thisapp.config -Name 'Log_file' -Value $logfile -MemberType NoteProperty -Force
  Add-Member -InputObject $thisapp.config -Name 'Config_Path' -Value $App_Settings_File_Path -MemberType NoteProperty -Force
  Add-Member -InputObject $thisapp.config -Name 'App_Version' -Value $($thisScript.Version) -MemberType NoteProperty -Force
  Add-Member -InputObject $thisapp.config -Name 'Current_Folder' -Value $($Current_folder) -MemberType NoteProperty -Force
  Add-Member -InputObject $thisapp.config -Name 'image_Cache_path' -Value "$($thisScript.TempFolder)\\Images" -MemberType NoteProperty -Force
  Add-Member -InputObject $thisapp.config -Name 'App_Name' -Value $($thisScript.Name) -MemberType NoteProperty -Force
  Add-Member -InputObject $thisapp.config -Name 'Script_Modules' -Value $($Script_Modules) -MemberType NoteProperty -Force
  Add-Member -InputObject $thisapp.config -Name 'Templates_Directory' -Value "$($Current_folder)\\Resources\\Templates" -MemberType NoteProperty -Force
  Add-Member -InputObject $thisapp.config -Name 'EQPreset_Profile_Directory' -Value "$env:appdata\\$($thisScript.Name)\\EQPresets" -MemberType NoteProperty -Force 
}
$thisapp.config.App_Version = $($thisScript.Version)
Add-Member -InputObject $thisapp.config -Name 'SpotifyBrowser_Paging' -Value 50 -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'YoutubeBrowser_Paging' -Value 50 -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'MediaBrowser_Paging' -Value 50 -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'logfile_directory' -Value $logfile_directory -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'LocalMedia_logfile' -Value "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Local.log" -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'SpotifyMedia_logfile' -Value "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Spotify.log" -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'YoutubeMedia_logfile' -Value "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Youtube.log" -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'TwitchMedia_logfile' -Value "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Twitch.log" -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'Spicetify' -Value '' -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'Download_Status' -Value $false -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'Download_Message' -Value '' -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'Download_logfile' -Value '' -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'Download_UID' -Value '' -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'Startup_perf_timer' -Value $Startup_perf_timer -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'Temp_Folder' -Value $($thisScript.TempFolder) -MemberType NoteProperty -Force
$thisapp.Config.Last_Played = ''
$synchash.Streamlink = ''
$synchash.Last_Played = ''
$synchash.WebPlayer_State = 0
#Set env path for yt-dlp
$env:Path += ";$($thisapp.config.Current_folder)\\Resources\\Youtube-dl"


if($thisapp.config.Use_Spicetify){
  write-ezlogs ">>>> Use Spicetify is enabled, verifying app is running as admin" -showtime
  Use-RunAs
}

#Create new synchronized hastable to hold custom playlists
#$all_playlists = [hashtable]::Synchronized(@{})
#$all_playlists.playlists = New-Object -TypeName 'System.Collections.ArrayList'
$synchash.All_Playlists = New-Object -TypeName 'System.Collections.ArrayList'

#Save App Settings
try{
  $thisapp.config | Export-Clixml -Path $App_Settings_File_Path -Force -Encoding UTF8
}catch{
  write-ezlogs "An exception occurred when saving config file to path $App_Settings_File_Path" -showtime -catcherror $_
}

#Run First Run Setup if new version or fresh install
if(([System.IO.Directory]::Exists($thisapp.config.Media_Profile_Directory)) -and $FreshStart){
  write-ezlogs " | Clearing profile cache ($($thisapp.config.Media_Profile_Directory))for first time run" -showtime -enablelogs -color cyan
  $null = Remove-Item $thisapp.config.Media_Profile_Directory -Force -Recurse
} 

if(![System.IO.Directory]::Exists($thisapp.config.Media_Profile_Directory) -or $FreshStart){
  Use-RunAs -logfile $startup_log
  if([System.IO.File]::Exists("$env:localappdata\spotishell\EZT-MediaPlayer.json")){
    try{
      write-ezlogs ">>>> Removing existing Spotify application json at $env:localappdata\spotishell\EZT-MediaPlayer.json" -showtime -color cyan
      $null = Remove-Item "$env:localappdata\spotishell\EZT-MediaPlayer.json" -Force
    }catch{
      write-ezlogs "An exception occurred attempting to remove $env:localappdata\spotishell\EZT-MediaPlayer.json" -showtime -catcherror $_
    }
  }
  if([System.IO.Directory]::Exists("$($thisApp.config.Temp_Folder)\Webview2")){   
    try{
      write-ezlogs ">>>> Removing existing Spotify application json at $($thisApp.config.Temp_Folder)\Webview2" -showtime -color cyan
      $null = Remove-Item "$($thisApp.config.Temp_Folder)\Webview2" -Force -Recurse
    }catch{write-ezlogs "An exception occurred attempting to remove $env:localappdata\spotishell\EZT-MediaPlayer.json" -showtime -catcherror $_}
  }
  
  #Verify Webview2 Installed
  #$WebView2_Install_Check = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}").pv
  $WebView2_Install_Check = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\*")| where {$_.name -match 'WebView2 Runtime'}
  $WebView2_version = $WebView2_Install_Check.pv
  if(!$WebView2_Install_Check){
    $user_sid = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
    $WebView2_Install_Check = (Get-ItemProperty "Registry::\HKEY_USERS\$user_sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*") | where {$_.Displayname -match 'WebView2 Runtime'}
    $WebView2_version = $WebView2_Install_Check.Version
  }  
  if(-not [string]::IsNullOrEmpty($WebView2_Install_Check)){
    write-ezlogs "[FIRST-RUN] Webview2 is installed with version $($WebView2_version)" -showtime
  }else{
    $hash.Window.Dispatcher.invoke([action]{
        $hash.More_Info_Msg.Visibility= "Visible"
        $hash.More_info_Msg.text="Installing Required App: Webview2 Runtime"      
    },"Normal")    
    $webview2_Link = "https://go.microsoft.com/fwlink/p/?LinkId=2124703"
    $webview_exe = "MicrosoftEdgeWebview2Setup.exe"
    $webview2_download_location = "$env:temp\$webview_exe"
    write-ezlogs "[FIRST-RUN] | Downloading Webview2 to $webview2_download_location" -showtime
    $null =  (New-Object System.Net.WebClient).DownloadFile($webview2_Link,$webview2_download_location)   
    write-ezlogs "[FIRST-RUN]  | Installing Webview2 from $webview2_download_location with arguments 'silent /install'" -showtime
    $webview2_setup = Start-process $webview2_download_location -ArgumentList '/silent /install' -Wait
    write-ezlogs "[FIRST-RUN]  | Verifying installation was sucessfull..." -showtime
    $WebView2_PostInstall_Check = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\*") | where {$_.name -match 'WebView2 Runtime'}
    if(!$WebView2_PostInstall_Check){
      $user_sid = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
      $WebView2_PostInstall_Check = (Get-ItemProperty "Registry::\HKEY_USERS\$user_sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*") | where {$_.Displayname -match 'WebView2 Runtime'}
    }
    if(-not [string]::IsNullOrEmpty($WebView2_PostInstall_Check)){
      write-ezlogs "[FIRST-RUN] [SUCCESS] Webview2 Runtime installed succesfully!" -showtime
      $hash.Window.Dispatcher.invoke([action]{
          $hash.More_Info_Msg.Visibility= "Visible"
          $hash.More_info_Msg.text="Restarting App after installing Webview2 Runtime"      
      },"Normal")   
      try 
      {  
        #$arg = "-file `"$($MyInvocation.ScriptName)`""         
        $ScriptPath = [System.IO.Path]::Combine($thisApp.Config.Current_folder,"$($thisApp.Config.App_Name).ps1")
        if(![System.IO.File]::Exists($ScriptPath)){
          $ScriptPath = $((Get-PSCallStack).ScriptName | where {$_ -notmatch '.psm1'} | select -First 1)
        }
        write-ezlogs "Restarting App after installing Webview2 Runtime, restarting with Path: $($ScriptPath)" -showtime -warning
        $arg = "-NoProfile -ExecutionPolicy Bypass -file `"$($ScriptPath)`""
        if($hash.Window.IsVisible){
          close-splashscreen
        }
        if([System.IO.File]::Exists("$env:programfiles\PowerShell\7\pwsh.exe")){
          $process = Start-Process "$env:programfiles\PowerShell\7\pwsh.exe" -Verb Runas -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden
        }else{         
          Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden
        }
      } 
      catch 
      { 
        Write-ezlogs 'Failed to restart script with runas' -showtime -catcherror $_  
        break             
      } 
      if($pid){
        stop-process $pid -Force -ErrorAction SilentlyContinue
      }      
      exit # Quit this session of powershell           
    }else{
      write-ezlogs "[WARNING] Unable to verify if Webview2 installed successfully. Features that use Webview2 (webbrowsers and others) may not work correctly: Regpath checked: $((Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\*") | out-string)" -showtime -warning
    }
  }
   
  if($hash.Window.IsVisible){
    $hash.window.Dispatcher.Invoke('Normal',[action]{ $hash.window.hide() }) 
  }  
  try{
    if(!(Get-command -Module Spotishell)){
      Import-Module "$($thisApp.Config.Current_folder)\Modules\Spotishell\Spotishell.psm1"
    } 
    Show-FirstRun -PageTitle "$($thisScript.name) - First Run Setup" -PageHeader 'First Run Setup' -Logo "$($thisapp.Config.Current_Folder)\\Resources\\MusicPlayerFilltest.ico" -thisScript $thisScript -thisApp $thisapp -Verboselog $thisapp.config.Verbose_Logging -First_Run #-use_runspace  
  }catch{
    write-ezlogs 'An exception occurred executing Show-firstrun' -showtime -catcherror $_
    exit
  }
  $null = New-Item $thisapp.config.Media_Profile_Directory -ItemType Directory -Force
  if(!$hash.Window.IsVisible){
    $hash.window.Dispatcher.Invoke('Normal',[action]{ $hash.window.show() })
  }  
}

#Create Playlist Directory if needed
if(!([System.IO.Directory]::Exists($thisapp.config.Playlist_Profile_Directory))){
  write-ezlogs ' | Creating Playlist Profile Directory' -showtime -enablelogs -color cyan
  $null = New-Item $thisapp.config.Playlist_Profile_Directory -ItemType Directory -Force
}

#Verify and Install Required Apps/Compontents
try{
  $confirm_Requirements_Measure = measure-command {
    $confirm_requirements_msg = confirm-requirements -required_appnames $required_appnames -FirstRun -Verboselog:$thisapp.Config.Verbose_logging -thisApp $thisapp -logfile $logfile
  } 
  if($thisApp.Config.startup_perf_timer){$Confirm_Requirements_Perf =  "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Confirm-Requirements:  $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds`n[$(Get-date -format $logdateformat)]     | Confirm-Requirements Total: $($confirm_Requirements_Measure.Seconds) seconds - $($confirm_Requirements_Measure.Milliseconds) Milliseconds"}
}catch{
  write-ezlogs 'An exception occurred in script_onload_scripblock' -showtime -catcherror $_
}

#---------------------------------------------- 
#region Play Media Handlers
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.PlayMedia_Command = {
  param($sender)
  $Media = $_.OriginalSource.DataContext
  if(!$Media.url -and !$Media.uri){$Media = $sender.tag}
  if(!$Media.url -and !$Media.uri){$Media = $sender.tag.Media} 
  if(!$Media.url -and !$Media.uri){$Media = $sender.selecteditem.tag.Media}
  #write-ezlogs "Could not find media to play! - $($_.OriginalSource.DataContext.tag.media | out-string)" -showtime -warning
  #write-ezlogs "sender.tag $($sender.tag | out-string)" -showtime -warning
  if($Media.Spotify_Path -or $Media.uri -match 'spotify:' -or $Media.Source -eq 'SpotifyPlaylist'){
    $Spotify_media = $Spotify_Datatable.datatable | where {$_.id -eq $media.id}
    Start-SpotifyMedia -Media $Spotify_media -thisApp $thisapp -synchash $synchash -Script_Modules $Script_Modules -Show_notification
  }elseif($media){
    Start-Media -Media $Media -thisApp $thisapp -synchash $synchash -Show_notification -Script_Modules $Script_Modules -all_playlists $synchash.all_playlists
  }else{
    write-ezlogs "Could not find media to play! - $($media | out-string)" -showtime -warning
  }   
}

[System.Windows.RoutedEventHandler]$PlaySpotify_Media_Command = {
  param($sender)
  $Media = $_.OriginalSource.DataContext
  if($Media.Spotify_Path){$Media = $synchash.SpotifyTable.items | where {$_.id -eq $Media.id} | select -Unique}   
  Start-SpotifyMedia -Media $Media -thisApp $thisapp -synchash $synchash -Script_Modules $Script_Modules -Show_notification -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -PlaySpotify_Media_Command $PlaySpotify_Media_Command
  Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command
}
$synchash.PlaySpotify_Media_Command = $PlaySpotify_Media_Command
#---------------------------------------------- 
#endregion Play Media Handlers
#----------------------------------------------

#---------------------------------------------- 
#region DeleteEnter Handler
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.KeyDown_Command = {
  param
  (
    [Parameter(Mandatory)][Object]$sender,
    [Parameter(Mandatory)][Windows.Input.KeyEventArgs]$e
  )
  $Media = $_.OriginalSource.DataContext
  if(!$Media.url){$Media = $sender.tag}
  if(!$Media.url){$Media = $sender.tag.Media} 
  if(!$Media.url){$Media = $sender.selecteditem.tag.Media}
  #$synchash = $Sender.tag.synchash
  #$thisApp = $using:thisapp
  #$thisScript = $Sender.tag.thisScript 
  #$all_playlists = $sender.tag.all_playlists
  if($e.Key -eq 'Enter' -and $Media.url)
  {

    try{
      if($media.Spotify_Path){
        $media = $syncHash.SpotifyTable.items | where {$_.id -eq $Media.id} | select -Unique
        Start-SpotifyMedia -Media $Media -thisApp $thisApp -synchash $synchash -Script_Modules $Script_Modules -Show_notification
      }else{
        Start-Media -Media $Media -thisApp $thisApp -synchash $synchash -Show_notification -Script_Modules $Script_Modules
      }  
      #Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp  -Refresh_Spotify_Playlists -all_playlists $all_playlists
    }catch{
      write-ezlogs "An exception occurred attempting to play media using keyboard event $($e.Key | out-string) for media $($Media.id) from Playlist $($Playlist)" -showtime -catcherror $_
    }    
  }
  if($e.Key -eq 'Delete'-and $Media.url)
  {
    try{
      if($media.Spotify_Path){
        if($thisApp.config.Current_Playlist.values -contains $Media.encodedtitle){
          write-ezlogs " | Removing $($Media.encodedtitle) from Play Queue" -showtime
          $index_toremove = $thisApp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.encodedtitle} | select * -ExpandProperty key
          $null = $thisApp.config.Current_Playlist.Remove($index_toremove) 
        }      
      }elseif($thisApp.config.Current_Playlist.values -contains $Media.id){
        write-ezlogs " | Removing $($Media.id) from Play Queue" -showtime
        $index_toremove = $thisApp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.id} | select * -ExpandProperty key
        $null = $thisApp.config.Current_Playlist.Remove($index_toremove)                 
      }
      $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8
      Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -synchash $synchash  -startup -thisApp $thisApp 
    }catch{
      write-ezlogs "An exception occurred removing media $($Media.id) using keyboard event $($e.Key | out-string)" -showtime -catcherror $_
    } 
  }   
}
#---------------------------------------------- 
#endregion DeleteEnter Handler
#----------------------------------------------

#---------------------------------------------- 
#region Hyperlink Navigate Handler
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.Hyperlink_RequestNavigate = {
  param ($sender,$e)
  try{
    $uri = $sender.NavigateUri.LocalPath
    write-ezlogs "Navigation to $($uri)" -showtime
    if($uri){
      if([system.io.file]::Exists($uri)){
        $uri = [system.io.directory]::GetParent($uri)
      }
      if(![system.io.directory]::Exists($uri)){
        $uri = $sender.NavigateUri.AbsolutePath
      }
      if(![system.io.directory]::Exists($uri)){
        $uri = $sender.NavigateUri.OriginalString
      }
      if([system.io.directory]::Exists($uri)){
        write-ezlogs "Navigation to $($uri)" -showtime
        start $uri
      }else{
        write-ezlogs "Path $uri is not valid!" -showtime -warning
      }
    }else{
      write-ezlogs "No valid path/URL provided! Sender: $($sender | out-string)" -showtime -warning
    }
  }catch{
    write-ezlogs "An exception occurred in Hyperlink_RequestNavigate" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Hyperlink Navigate Handler
#----------------------------------------------

#---------------------------------------------- 
#region Download Media Handler
#----------------------------------------------
[System.Windows.RoutedEventHandler]$DownloadMedia_Command = {
  param($sender)
  $Media = $_.OriginalSource.DataContext
  if(!$Media.url){$Media = $sender.tag}
  if(!$Media.url){$Media = $sender.tag.Media} 
  if(!$Media.url){$Media = $_.OriginalSource.tag.media}  
  #write-ezlogs "Header: $($sender.header)" -showtime
  if($Media.Source -eq 'YoutubePlaylist_item' -or $Media.type -eq 'YoutubePlaylist_item'){
    write-ezlogs "Downloading Media $($Media | Out-String)" -showtime   
    $result = Open-FolderDialog -Title 'Select the directory path where media will be downloaded to'
    if([System.IO.Directory]::Exists($result)){
      write-ezlogs ">>>> Downloading $($Media.title) to $result" -showtime
      Invoke-DownloadMedia -Media $Media -Download_Path $result -synchash $synchash -thisapp $thisapp -Show_notification -thisScript $thisScript -PlayMedia_Command $PlayMedia_Command
    }
  }   
}
#---------------------------------------------- 
#endregion Download Media Handler
#----------------------------------------------

#---------------------------------------------- 
#region Download Timer
#----------------------------------------------
$synchash.downloadTimer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.downloadTimer.Interval = (New-TimeSpan -Seconds 1)
$synchash.downloadTimer.add_tick({
    if($thisapp.config.Download_status -and -not [string]::IsNullOrEmpty($thisapp.config.Download_message) -and $thisapp.config.Download_UID){
      $download_notification = $synchash.Notifications_Grid.items | where {$_.id -eq $thisapp.config.Download_UID}        
      if($download_notification){
        Update-Notifications -id $download_notification.id -Level 'INFO' -Message $thisapp.config.Download_message -VerboseLog -thisApp $thisapp -synchash $synchash
      }         
    } 
}.GetNewClosure())

#---------------------------------------------- 
#endregion Download Timer
#----------------------------------------------

#---------------------------------------------- 
#region Start Media Timer
#----------------------------------------------
$synchash.start_media_timer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.start_media_timer.add_tick({
    try{
      if($synchash.Start_media){
        Start-Media -Media $synchash.Start_media -thisApp $thisapp -synchash $synchash -Script_Modules $Script_Modules
      }
      $this.Stop
    }catch{
      write-ezlogs "An exception occurred relaunching Start-Media" -showtime -catcherror $_
      $this.Stop
    }  
}.GetNewClosure())
#---------------------------------------------- 
#endregion Start Media Timer
#----------------------------------------------

$hash.Window.Dispatcher.invoke([action]{$hash.LoadingLabel.Content = 'Importing Local Media'},'Normal')

#---------------------------------------------- 
#region Import-Media
#----------------------------------------------
if($thisapp.Config.Import_Local_Media){
  $Global:Datatable = [hashtable]::Synchronized(@{})
  $import_media_measure = Measure-command{
    $synchash.MediaTable.add_AutoGeneratedColumns({
        $columns = ($args[0]).columns      
        foreach($column in $columns){
          #$syncHash.MediaTable.ItemsSource.Sort = $columns.Header.ToString()
          if($Visible_Fields -notcontains $column.header){$column.visibility = 'hidden'}else{$column.CanUserSort = $true}
        }     
    })        
    Import-Media -Media_directories $thisapp.config.Media_Directories -use_runspace -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -PlayMedia_Command $synchash.PlayMedia_Command -startup -thisApp $thisapp -Refresh_All_Media
    $synchash.LocalMedia_TableUpdate_timer = New-Object System.Windows.Threading.DispatcherTimer
    $synchash.LocalMedia_TableUpdate_timer.add_Tick({
        try{
          if($thisApp.Config.MediaBrowser_Paging -ne $Null){
            $synchash.LocalMedia_cbNumberOfRecords.items.clear()
            1..($synchash.LocalMedia_TotalView_Groups) | foreach{
              if($synchash.LocalMedia_cbNumberOfRecords.items -notcontains "Page $_" -and $_ -gt 0){
                $null = $synchash.LocalMedia_cbNumberOfRecords.items.add("Page $_")  
              }
            }
            $synchash.LocalMedia_cbNumberOfRecords.selectedItem = "Page $($synchash.LocalMedia_CurrentView_Group)"
            $synchash.LocalMediaFilter_Handler = $Null
          }
          if($synchash.MediaTable.Columns.Header -notcontains 'Play'){
            $syncHash.MediaTable.CanUserReorderColumns = $true
            $syncHash.MediaTable.FontWeight = "bold"
            $syncHash.MediaTable.AutoGenerateColumns = $false
            $synchash.MediaTable.CanUserSortColumns = $true
            $synchash.MediaTable.HorizontalAlignment = "Stretch"
            $synchash.MediaTable.CanUserAddRows = $False
            $synchash.MediaTable.HorizontalContentAlignment = "left"
            $synchash.MediaTable.IsReadOnly = $True  
            $synchash.MediaTable.ColumnHeaderStyle = $synchash.Window.TryFindResource('MahApps.Styles.DataGridColumnHeader') 
            if($thisApp.Config.Verbose_logging){write-ezlogs " | Adding Media table play button to table" -showtime -color cyan -enablelogs} 
            $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
            $buttonFactory = New-Object System.Windows.FrameworkElementFactory([Windows.Controls.Primitives.ToggleButton])
            <#            $ButtonGrid = New-Object System.Windows.Controls.Grid
                $buttonimagecontrol = New-Object MahApps.Metro.IconPacks.PackIconMaterial
                $buttonimagecontrol.HorizontalAlignment="Left"
                $buttonimagecontrol.Kind = 'Play'
                $buttonimagecontrol.Name = 'Mediatable_Playicon'
            $Null = $buttonGrid.AddChild($buttonimagecontrol)#>
            $Binding = New-Object System.Windows.Data.Binding
            $Relativesource = New-Object System.Windows.Data.RelativeSource
            $Relativesource.AncestorType = [System.Windows.Controls.DataGridRow]
            #$Binding.Source = $synchash.MediaTable.SelectedItem
            $Binding.RelativeSource = $Relativesource
            $Binding.Path = "IsExpanded"
            $Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
            #$null = [System.Windows.Data.BindingOperations]::SetBinding($buttonFactory,[Windows.Controls.Primitives.ToggleButton]::IsCheckedProperty, $Binding)
            $buttonFactory.Name = 'Mediatable_Playbutton'
            $buttonFactory.SetBinding([Windows.Controls.Primitives.ToggleButton]::IsCheckedProperty,$binding)
            $Null = $buttonFactory.SetValue([Windows.Controls.Primitives.ToggleButton]::BackgroundProperty, $synchash.Window.TryFindResource('TransparentBackgroundStyle'))
            $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $synchash.Window.TryFindResource('PlayGridButtonStyle') )
            if($thisApp.Config.Verbose_logging){write-ezlogs " | Setting MediaTable Play button click event" -showtime -color cyan -enablelogs} 
            $Null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.PlayMedia_Command)
            $dataTemplate = New-Object System.Windows.DataTemplate
            $dataTemplate.VisualTree = $buttonFactory
            $buttonColumn.CellTemplate = $dataTemplate
            $buttonColumn.Width="SizeToHeader"
            $buttonColumn.CanUserSort = $false
            $buttonColumn.SetValue([DataGridExtensions.DataGridFilterColumn]::IsFilterVisibleProperty, $false)
            $buttonColumn.Header = 'Play'
            $buttonColumn.DisplayIndex = 0
            $null = $synchash.MediaTable.Columns.add($buttonColumn)  
 
            <#            $SelectColumn = New-Object System.Windows.Controls.DataGridCheckBoxColumn
                #$CheckboxFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Checkbox])
                if($verboselog){write-ezlogs " | Setting MediaTable Select button click event" -showtime -color cyan -enablelogs} 
                $Binding = New-Object System.Windows.Data.Binding
                $Relativesource = New-Object System.Windows.Data.RelativeSource
                $Relativesource.AncestorType = [System.Windows.Controls.DataGridRow]
                #$Binding.Source = $synchash.MediaTable.SelectedItem
                $Binding.RelativeSource = $Relativesource
                $Binding.Path = [System.Windows.Controls.DataGridRow]::IsSelectedProperty
                $Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
                #$Null = $CheckboxFactory.AddHandler([System.Windows.Controls.Checkbox]::CheckedEvent,$synchash.PlayMedia_Command)
                #$dataTemplate = New-Object System.Windows.DataTemplate
                #$dataTemplate.VisualTree = $CheckboxFactory
                #$SelectColumn.CellTemplate = $dataTemplate
                #$SelectColumn.ElementStyle = $synchash.Window.TryFindResource('MetroDataGridCheckBox') 
                $SelectColumn.SetValue([DataGridExtensions.DataGridFilterColumn]::IsFilterVisibleProperty, $false)
                $SelectColumn.Header = 'Select'
                $SelectColumn.Binding = $Binding
                $SelectColumn.DisplayIndex = 1
            $null = $synchash.MediaTable.Columns.add($SelectColumn)#>
          }
          foreach($group in $Datatable.datatable.Group_Name | where {$_} | Sort-Object){
            if($synchash.Show_LocalMediaArtist_ComboBox.items -notcontains $group){
              $null = $synchash.Show_LocalMediaArtist_ComboBox.items.add($group)
            }
          }
          if(@($synchash.LocalMedia_View).count -eq 1){             
            #$syncHash.MediaTable.ItemsSource = [System.Windows.Data.CollectionViewSource]::GetDefaultView($synchash.LocalMedia_View)
            write-ezlogs ">>>> Clearing Itemsource" -showtime
            #write-ezlogs " | View $($synchash.Mediatable.columns | out-string)" -showtime
            $syncHash.MediaTable.ItemsSource = $Null
            foreach($item in $Datatable.datatable){
              write-ezlogs " | Adding item $($item.title) to mediatable items" -showtime
              $syncHash.MediaTable.items.Add($item)
            }
          }else{
            if(@($syncHash.MediaTable.items).count -eq 1){
              write-ezlogs ">>>> Clearing Mediatable items" -showtim
              $null = $syncHash.MediaTable.items.clear()
            }
            $syncHash.MediaTable.ItemsSource = $synchash.LocalMedia_View
          }                          
          $synchash.Media_Table_Total_Media.content = "$(@($synchash.MediaTable.ItemsSource).count) of $(@($Datatable.datatable).count)"
          $synchash.LocalMedia_lblpageInformation.content = "$($synchash.LocalMedia_CurrentView_Group) of $($synchash.LocalMedia_TotalView_Groups)" 
          $synchash.LocalMedia_Progress_Ring.isActive=$false
          $synchash.LocalMedia_Progress_Label.Visibility = 'Hidden'
          $syncHash.MediaTable.isEnabled = $true
          $this.Stop()
        }catch{
          $this.Stop()
          write-ezlogs "[ERROR] An exception occurred attempting to set itemsource for MediaTable" -showtime -color red -CatchError $_
        }    
    }.GetNewClosure())    
    $synchash.LocalMediaFilter_timer = New-Object System.Windows.Threading.DispatcherTimer
    $synchash.LocalMediaFilter_timer.add_Tick({
        try{
          if($synchash.LocalMediaFilter_Handler.name -eq 'FilterTextBox'){
            $InputText = $synchash.FilterTextBox.Text
          }elseif($synchash.LocalMediaFilter_Handler.name -eq 'Show_LocalMediaArtist_ComboBox'){
            $InputText = $synchash.Show_LocalMediaArtist_ComboBox.Selecteditem
          }else{
            write-ezlogs "Unable to determine what control initiated the filter. WHO DONE DID IT?" -showtime -warning
            $this.stop()
          }
          $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView(($Datatable.datatable | Sort-object -Property {$_.Group_Name},{$_.Artist},{[int]$_.Number}))
          if($view.CanFilter){
            write-ezlogs "Using View Filter for query ($InputText)" -showtime
            $view.Filter = {
              param ($item) 
              $output = $($item.Title) -match $("$([regex]::Escape($InputText))") -or $($item.Title) -eq $("$([regex]::Escape($InputText))") -or $($item.Artist) -match $("$([regex]::Escape($InputText))") -or $($item.Album) -match $("$([regex]::Escape($InputText))")
              $output        
            }
          }elseif($view){
            write-ezlogs "Using View CustomFilter for query ($InputText)" -showtime
            $view.CustomFilter = "Title LIKE '$InputText%' OR Artist like '%$InputText%' OR Album like '%$InputText%'"
          }
          #$view = $view | where {$_.id}
          if($thisapp.Config.MediaBrowser_Paging -ne $null){
            $approxGroupSize = (@($view).count | Measure-Object -Sum).Sum / $thisapp.Config.MediaBrowser_Paging     
            $approxGroupSize = [math]::ceiling($approxGroupSize)
            #write-host ('This will create {0} groups which will be approximately {1} in size' -f $approxGroupSize, $page_size)
            # create number of groups requested
            $groupMembers = @{}
            $groupSizes = @{}
            for ($i = 1; $i -le ($approxGroupSize); $i++) {
              $groupMembers.$i = [Collections.Generic.List[Object]]@()
              $groupSizes.$i = 0
            }
            foreach ($item in $view) {
              $mostEmpty = (($groupSizes.GetEnumerator() | Sort-Object -Property 'Name' | where {$_.value -lt $thisapp.Config.MediaBrowser_Paging}) | Select-Object -First 1).name
              if($mostEmpty -ne $Null){
                if($groupMembers.$mostEmpty -notcontains $item){
                  $null = $groupMembers.$mostEmpty.Add($item)
                  $groupSizes.$mostEmpty += @($item).count
                }
              }
            }     
            $synchash.LocalMedia_View_Groups = $groupMembers.GetEnumerator() | select *
            $synchash.LocalMedia_TotalView_Groups = @($groupMembers.GetEnumerator() | select *).count
            $synchash.LocalMedia_CurrentView_Group = ($groupMembers.GetEnumerator() | select * | select -last 1).Name 
            if(@($view).count -gt 1){
              $itemsource = ($groupMembers.GetEnumerator() | select * | select -last 1).Value | Sort-object -Property {$_.Group_Name},{$_.Artist},{[int]$_.Number}
              $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)
            }          
          }else{
            $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($view) 
          }       
          if(($view.psobject.properties.name | where {$_ -eq 'GroupDescriptions'}) -and $synchash.LocalMedia_GroupName){
            $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
            $groupdescription.PropertyName = $synchash.LocalMedia_GroupName
            if($view.GroupDescriptions){
              $view.GroupDescriptions.Clear()            
            }
            $null = $view.GroupDescriptions.Add($groupdescription)
            if($Sub_GroupName){
              $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $sub_groupdescription.PropertyName = $Sub_GroupName
              $null = $view.GroupDescriptions.Add($sub_groupdescription)
            }
          }elseif($view -and $view.GroupDescriptions){
            $view.GroupDescriptions.Clear()
          }
          $synchash.LocalMedia_View = $view        
          $synchash.LocalMedia_TableUpdate_timer.start()
          #$synchash.MediaTable.ItemsSource = $view
          #$synchash.Media_Table_Total_Media.content = "$(@($synchash.MediaTable.ItemsSource).count) of $(@(($synchash.LocalMedia_View_Groups | select *).value).count) | Total $(@($Datatable.datatable).count)"
          #$synchash.LocalMedia_lblpageInformation.content = "$($synchash.LocalMedia_CurrentView_Group) of $($synchash.LocalMedia_TotalView_Groups)" 
        }catch{
          write-ezlogs 'An exception occurred in LocalMediaFilterTextBox' -showtime -catcherror $_
          $this.Stop()
        }
        $this.Stop()
    }.GetNewClosure())
    $synchash.FilterTextBox.Add_TextChanged({
        $synchash.LocalMediaFilter_Handler = $this
        $synchash.LocalMediaFilter_timer.start()
    }.GetNewClosure())  
    $synchash.Show_LocalMediaArtist_ComboBox.Add_SelectionChanged({
        $synchash.LocalMediaFilter_Handler = $this
        $synchash.LocalMediaFilter_timer.start()
    }.GetNewClosure())     
    $syncHash.MediaTable.add_SelectionChanged({ $_.Handled = $true })   
  }
  if($thisApp.Config.startup_perf_timer){$Import_media_Perf = "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Import-Media:          $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds`n[$(Get-date -format $logdateformat)]     | Get-LocalMedia Total: $($get_LocalMedia_Measure.Seconds) seconds - $($get_LocalMedia_Measure.Milliseconds) Milliseconds`n[$(Get-date -format $logdateformat)]     | Media_to_Datatable Total: $($media_to_Datatable_Measure.Seconds) seconds - $($media_to_Datatable_Measure.Milliseconds) Milliseconds`n[$(Get-date -format $logdateformat)]     | Media_Paging_Measure Total: $($Media_Paging_Measure.Seconds) seconds - $($Media_Paging_Measure.Milliseconds) Milliseconds`n[$(Get-date -format $logdateformat)]     | Import-Media Total: $($import_media_measure.Seconds) seconds - $($import_media_measure.Milliseconds) Milliseconds"} 
  
}else{
  write-ezlogs 'Importing of Local Media is not enabled' -showtime -Warning
  $syncHash.MediaTable.isEnabled = $false
  $syncHash.LocalMedia_Browser_Tab.isEnabled = $false
  if($syncHash.MainGrid_Bottom_TabControl.items -contains $syncHash.LocalMedia_Browser_Tab){
    $Null = $syncHash.MainGrid_Bottom_TabControl.items.Remove($syncHash.LocalMedia_Browser_Tab) 
  }
}
#---------------------------------------------- 
#endregion Import-Media
#----------------------------------------------

#---------------------------------------------- 
#region Import-Spotify
#----------------------------------------------
if($thisapp.Config.Import_Spotify_Media){

  $import_Spotify_measure = Measure-command{
    $hash.Window.Dispatcher.invoke([action]{$hash.LoadingLabel.Content = 'Importing Spotify Media'},'Normal')
    $synchash.SpotifyTable.add_AutoGeneratedColumns({
        $columns = ($args[0]).columns
        foreach($column in $columns){
          if($Visible_Fields -notcontains $column.header){$column.visibility = 'hidden'}else{$column.CanUserSort = $true}
        }     
    })
    $Global:Spotify_Datatable = [hashtable]::Synchronized(@{})
    Import-Spotify -Media_directories $thisapp.config.Media_Directories -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -PlayMedia_Command $synchash.PlayMedia_Command -startup -thisApp $thisapp
 
    $synchash.SpotifyMedia_TableUpdate_timer = New-Object System.Windows.Threading.DispatcherTimer
    $synchash.SpotifyMedia_TableUpdate_timer.add_Tick({
        try{
          if($thisApp.Config.SpotifyBrowser_Paging -ne $Null){
            $synchash.Spotify_cbNumberOfRecords.items.clear()
            1..($synchash.Spotify_TotalView_Groups) | foreach{
              if($synchash.Spotify_cbNumberOfRecords.items -notcontains "Page $_" -and $_ -gt 0){
                $null = $synchash.Spotify_cbNumberOfRecords.items.add("Page $_")  
              }
            }
            $synchash.Spotify_cbNumberOfRecords.selectedItem = "Page $($synchash.Spotify_CurrentView_Group)"
            $synchash.SpotifyFilter_Handler = $Null
          }         
          if($synchash.SpotifyTable.Columns.Header -notcontains 'Play'){
            $syncHash.SpotifyTable.CanUserReorderColumns = $true
            $syncHash.SpotifyTable.FontWeight = "bold"
            $syncHash.SpotifyTable.AutoGenerateColumns = $true
            $synchash.SpotifyTable.CanUserSortColumns = $true
            $synchash.SpotifyTable.HorizontalAlignment = "Stretch"
            $synchash.SpotifyTable.CanUserAddRows = $False
            $synchash.SpotifyTable.HorizontalContentAlignment = "left"
            $synchash.SpotifyTable.IsReadOnly = $True  
            $synchash.SpotifyTable.ColumnHeaderStyle = $synchash.Window.TryFindResource('MahApps.Styles.DataGridColumnHeader') 
            if($thisApp.Config.Verbose_logging){write-ezlogs " | Adding Spotify table play button and select checkbox to table" -showtime -color cyan -enablelogs} 
            $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
            $buttonFactory = New-Object System.Windows.FrameworkElementFactory([Windows.Controls.Primitives.ToggleButton])
            #$Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Play")
            if($thisApp.Config.Verbose_logging){write-ezlogs " | Setting SpotifyTable Play button click event" -showtime -color cyan -enablelogs} 
            $Null = $buttonFactory.SetValue([Windows.Controls.Primitives.ToggleButton]::BackgroundProperty, $synchash.Window.TryFindResource('TransparentBackgroundStyle'))
            $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $synchash.Window.TryFindResource('PlayGridButtonStyle') )
            $Null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.PlayMedia_Command)
            $dataTemplate = New-Object System.Windows.DataTemplate
            $dataTemplate.VisualTree = $buttonFactory
            $buttonColumn.CellTemplate = $dataTemplate
            $buttonColumn.Width="SizeToHeader"
            $buttonColumn.CanUserSort = $false
            $buttonColumn.SetValue([DataGridExtensions.DataGridFilterColumn]::IsFilterVisibleProperty, $false)
            $buttonColumn.Header = 'Play'
            $buttonColumn.DisplayIndex = 0
            $null = $synchash.SpotifyTable.Columns.add($buttonColumn)  
          } 
          foreach($group in $Spotify_Datatable.datatable.Group_Name | where {$_} | Sort-Object){
            if($synchash.Show_SpotifyMediaArtist_ComboBox.items -notcontains $group){
              $null = $synchash.Show_SpotifyMediaArtist_ComboBox.items.add($group)
            }
          }
          if(@($synchash.SpotifyMedia_View).count -eq 1){             
            $syncHash.SpotifyTable.ItemsSource = [System.Windows.Data.CollectionViewSource]::GetDefaultView($synchash.SpotifyMedia_View)
          }else{
            $syncHash.SpotifyTable.ItemsSource = $synchash.SpotifyMedia_View
          }
          $synchash.Spotify_Table_Total_Media.content = "$(@($synchash.SpotifyTable.ItemsSource).count) of $(@($Spotify_Datatable.datatable).count)"
          $synchash.Spotify_lblpageInformation.content = "$($synchash.Spotify_CurrentView_Group) of $($synchash.Spotify_TotalView_Groups)" 
          $synchash.SpotifyMedia_Progress_Ring.isActive=$false
          $syncHash.SpotifyTable.isEnabled = $true
          $this.Stop()
        }catch{
          $this.Stop()
          write-ezlogs "An exception occurred attempting to set itemsource for SpotifyTable" -showtime -catcherror $_
        }    
    }.GetNewClosure()) 

    $synchash.SpotifyFilter_timer = New-Object System.Windows.Threading.DispatcherTimer
    $synchash.SpotifyFilter_timer.add_Tick({
        try{
          if($synchash.SpotifyFilter_Handler.name -eq 'SpotifyFilterTextBox'){
            $InputText = $synchash.SpotifyFilterTextBox.Text
          }elseif($synchash.SpotifyFilter_Handler.name -eq 'Show_SpotifyMediaArtist_ComboBox'){
            $InputText = $synchash.Show_SpotifyMediaArtist_ComboBox.Selecteditem
          }else{
            write-ezlogs "Unable to determine what control initiated the filter. WHO DONE DID IT?" -showtime -warning
            $this.stop()
          }            
          $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView(($Spotify_Datatable.datatable | Sort-Object -Property {$_.Group_Name},{$_.Playlist},{[int]$_.Track_Number}))
          if($view.CanFilter){
            $view.Filter = {
              param ($item) 
              $output = $($item.Title) -match $("$([regex]::Escape($InputText))") -or $($item.Track_name) -match $("$([regex]::Escape($InputText))") -or $($item.Artist_Name) -match $("$([regex]::Escape($InputText))") -or $($item.Playlist) -match $("$([regex]::Escape($InputText))")
              $output        
            }
          }else{
            $view.CustomFilter = "Title LIKE '$InputText%' OR Track_name like '%$InputText%' OR Artist_Name like '%$InputText%'"
          }
          #$view = $view | where {$_.id}
          if($thisapp.Config.SpotifyBrowser_Paging -ne $null){
            $approxGroupSize = (@($view).count | Measure-Object -Sum).Sum / $thisapp.Config.SpotifyBrowser_Paging     
            $approxGroupSize = [math]::ceiling($approxGroupSize)
            #write-host ('This will create {0} groups which will be approximately {1} in size' -f $approxGroupSize, $page_size)
            # create number of groups requested
            $groupMembers = @{}
            $groupSizes = @{}
            for ($i = 1; $i -le ($approxGroupSize); $i++) {
              $groupMembers.$i = [Collections.Generic.List[Object]]@()
              $groupSizes.$i = 0
            }
            foreach ($item in $view) {

              $mostEmpty = (($groupSizes.GetEnumerator() | Sort-Object -Property 'Name' | where {$_.value -lt $thisapp.Config.SpotifyBrowser_Paging}) | Select-Object -First 1).name
              if($mostEmpty -ne $Null){
                if($groupMembers.$mostEmpty -notcontains $item){
                  $null = $groupMembers.$mostEmpty.Add($item)
                  $groupSizes.$mostEmpty += @($item).count
                }
              }
            }     
            $synchash.Spotify_View_Groups = $groupMembers.GetEnumerator() | select *
            $synchash.Spotify_TotalView_Groups = @($groupMembers.GetEnumerator() | select *).count
            $synchash.Spotify_CurrentView_Group = ($groupMembers.GetEnumerator() | select * | select -last 1).Name            
            if(@($view).count -gt 1){
              $itemsource = ($groupMembers.GetEnumerator() | select * | select -last 1).Value | Sort-Object -Property {$_.Group_Name},{$_.Playlist},{[int]$_.Track_Number}
              $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)
            }              
          }else{
            $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($view) 
          }       
          if(($view.psobject.properties.name | where {$_ -eq 'GroupDescriptions'}) -and $synchash.Spotify_GroupName){
            $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
            $groupdescription.PropertyName = $synchash.Spotify_GroupName
            if($view.GroupDescriptions){
              $view.GroupDescriptions.Clear()
            }
            $null = $view.GroupDescriptions.Add($groupdescription)
            if($Sub_GroupName){
              $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $sub_groupdescription.PropertyName = $Sub_GroupName
              $null = $view.GroupDescriptions.Add($sub_groupdescription)
            }
          }elseif($view -and $view.GroupDescriptions){$view.GroupDescriptions.Clear()}
          $synchash.SpotifyMedia_View = $view        
          $synchash.SpotifyMedia_TableUpdate_timer.start()

          #$synchash.SpotifyTable.ItemsSource = $synchash.SpotifyMedia_View
          #$synchash.Spotify_Table_Total_Media.content = "$(@($synchash.SpotifyTable.ItemsSource).count) of $(@(($synchash.Spotify_View_Groups | select *).value).count) | Total $(@($Spotify_Datatable.datatable).count)"
          #$synchash.Spotify_lblpageInformation.content = "$($synchash.Spotify_CurrentView_Group) of $($synchash.Spotify_TotalView_Groups)"
        }catch{
          write-ezlogs "An exception occurred in SpotifyFilterTextbox - View $($synchash.SpotifyMedia_View | out-string)" -showtime -catcherror $_ -logfile:$thisApp.Config.SpotifyMedia_logfile
          $this.Stop()
        }
        $this.Stop()
    }.GetNewClosure())

    $synchash.SpotifyFilterTextBox.Add_TextChanged({
        $synchash.SpotifyFilter_Handler = $this
        $synchash.SpotifyFilter_timer.start()
    }.GetNewClosure())  
    $synchash.Show_SpotifyMediaArtist_ComboBox.Add_SelectionChanged({
        $synchash.SpotifyFilter_Handler = $this
        $synchash.SpotifyFilter_timer.start()
    }.GetNewClosure())   
  }
  if($thisApp.Config.startup_perf_timer){$Import_Spotify_Perf = "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Import-Spotify:          $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds`n[$(Get-date -format $logdateformat)]     | Import-Spotify Total: $($import_Spotify_measure.Seconds) seconds - $($import_Spotify_measure.Milliseconds) Milliseconds"} 
}else{
  write-ezlogs 'Importing of Spotify Media is not enabled' -showtime -Warning -logfile:$thisApp.Config.SpotifyMedia_logfile
  $syncHash.SpotifyTable.isEnabled = $false
  $syncHash.Spotify_Tabitem.isEnabled = $false
  if($syncHash.MainGrid_Bottom_TabControl.items -contains $syncHash.Spotify_Tabitem){
    $Null = $syncHash.MainGrid_Bottom_TabControl.items.Remove($syncHash.Spotify_Tabitem) 
  }
}
#---------------------------------------------- 
#endregion Import-Spotify
#----------------------------------------------

#---------------------------------------------- 
#region Import-Youtube
#----------------------------------------------
if($thisapp.Config.Import_Youtube_Media){
  $import_Youtube_measure = Measure-command{
    if($hash.Window.isVisible){
      $hash.Window.Dispatcher.invoke([action]{
          $hash.LoadingLabel.Content = 'Importing Youtube Media'
          $hash.More_info_Msg.text=""
      },"Normal")
    }
    $synchash.YoutubeTable.add_AutoGeneratedColumns({
        try{
          $columns = ($args[0]).columns
          foreach($column in $columns){
            if($Visible_Fields -notcontains $column.header){$column.visibility = 'hidden'}else{$column.CanUserSort = $true}
          }
        }catch{
          write-ezlogs 'An exception occurred in autogeneratedcolumns event for YoutubeTable' -showtime -catcherror $_ -logfile:$thisApp.Config.YoutubeMedia_logfile
        }   
    })
    $Global:Youtube_Datatable = [hashtable]::Synchronized(@{})
    Import-Youtube -Youtube_playlists $thisapp.Config.Youtube_Playlists -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -PlayMedia_Command $synchash.PlayMedia_Command -startup -thisApp $thisapp -use_runspace

    $synchash.YoutubeMedia_TableUpdate_timer = New-Object System.Windows.Threading.DispatcherTimer
    $synchash.YoutubeMedia_TableUpdate_timer.add_Tick({
        try{
          if($thisApp.Config.YoutubeBrowser_Paging -ne $Null){
            $synchash.Youtube_cbNumberOfRecords.items.clear()
            1..($synchash.Youtube_TotalView_Groups) | foreach{
              if($synchash.Youtube_cbNumberOfRecords.items -notcontains "Page $_" -and $_ -gt 0){
                $null = $synchash.Youtube_cbNumberOfRecords.items.add("Page $_")  
              }
            }
            $synchash.Youtube_cbNumberOfRecords.selectedItem = "Page $($synchash.Youtube_CurrentView_Group)"
            $synchash.YoutubeFilter_Handler = $Null
          }
          if($synchash.YoutubeTable.Columns.Header -notcontains 'Play'){
            $syncHash.YoutubeTable.CanUserReorderColumns = $true
            $syncHash.YoutubeTable.FontWeight = "bold"
            $syncHash.YoutubeTable.AutoGenerateColumns = $true
            $synchash.YoutubeTable.CanUserSortColumns = $true
            $synchash.YoutubeTable.HorizontalAlignment = "Stretch"
            $synchash.YoutubeTable.CanUserAddRows = $False
            $synchash.YoutubeTable.HorizontalContentAlignment = "left"
            $synchash.YoutubeTable.IsReadOnly = $True  
            $synchash.YoutubeTable.ColumnHeaderStyle = $synchash.Window.TryFindResource('MahApps.Styles.DataGridColumnHeader') 
            if($thisApp.Config.Verbose_logging){write-ezlogs " | Adding Youtube table play button and select checkbox to table" -showtime -color cyan -enablelogs} 
            $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
            $buttonFactory = New-Object System.Windows.FrameworkElementFactory([Windows.Controls.Primitives.ToggleButton])
            #$Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Play")
            if($thisApp.Config.Verbose_logging){write-ezlogs " | Setting YoutubeTable Play button click event" -showtime -color cyan -enablelogs} 
            $Null = $buttonFactory.SetValue([Windows.Controls.Primitives.ToggleButton]::BackgroundProperty, $synchash.Window.TryFindResource('TransparentBackgroundStyle'))
            $Null = $buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $synchash.Window.TryFindResource('PlayGridButtonStyle') )
            $Null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.PlayMedia_Command)
            $dataTemplate = New-Object System.Windows.DataTemplate
            $dataTemplate.VisualTree = $buttonFactory
            $buttonColumn.CellTemplate = $dataTemplate
            $buttonColumn.SetValue([DataGridExtensions.DataGridFilterColumn]::IsFilterVisibleProperty, $false)
            $buttonColumn.Width="SizeToHeader"
            $buttonColumn.CanUserSort = $false
            $buttonColumn.Header = 'Play'
            $buttonColumn.DisplayIndex = 0
            $null = $synchash.YoutubeTable.Columns.add($buttonColumn)  
          } 
          foreach($group in $Youtube_Datatable.datatable.Group_Name | where {$_} | Sort-Object){
            if($synchash.Show_YoutubeMediaArtist_ComboBox.items -notcontains $group){
              $null = $synchash.Show_YoutubeMediaArtist_ComboBox.items.add($group)
            }
          }         
          if(@($synchash.YoutubeMedia_View).count -eq 1){             
            $syncHash.YoutubeTable.ItemsSource = [System.Windows.Data.CollectionViewSource]::GetDefaultView($synchash.YoutubeMedia_View)
          }else{
            $syncHash.YoutubeTable.ItemsSource = $synchash.YoutubeMedia_View
          }              
          $synchash.Youtube_Table_Total_Media.content = "$(@($synchash.YoutubeTable.ItemsSource).count) of $(@($Youtube_Datatable.datatable).count)"
          $synchash.Youtube_lblpageInformation.content = "$($synchash.Youtube_CurrentView_Group) of $($synchash.Youtube_TotalView_Groups)" 
          $synchash.Youtube_Progress_Ring.isActive=$false
          $syncHash.YoutubeTable.isEnabled = $true 
          if($hash.Window.isVisible){
            $hash.Window.Dispatcher.invoke([action]{
                $hash.LoadingLabel.Content = 'Starting Up...'
                $hash.More_info_Msg.text=""
            },"Normal")
          }
          $this.Stop()
        }catch{
          $this.Stop()
          write-ezlogs "An exception occurred attempting to set itemsource for YoutubeTable" -showtime -catcherror $_
        }    
    }.GetNewClosure()) 
    $synchash.YoutubeFilter_timer = New-Object System.Windows.Threading.DispatcherTimer
    $synchash.YoutubeFilter_timer.add_Tick({
        try{
          if($synchash.YoutubeFilter_Handler.name -eq 'YoutubeFilterTextBox'){
            $InputText = $synchash.YoutubeFilterTextBox.Text
          }elseif($synchash.YoutubeFilter_Handler.name -eq 'Show_YoutubeMediaArtist_ComboBox'){
            $InputText = $synchash.Show_YoutubeMediaArtist_ComboBox.Selecteditem
          }else{
            write-ezlogs "Unable to determine what control initiated the filter. WHO DONE DID IT?" -showtime -warning
            $this.stop()
          }
          $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView(($Youtube_Datatable.datatable | Sort-Object -Property {$_.Group_Name},{$_.Playlist},{$_.Track_Name}))                   
          if($view.CanFilter){
            #$inputText = $InputText -split ' '
            $view.Filter = {
              param ($item) 
              $output = $($item.Title) -like $("*$($InputText)*") -or $($item.Track_name) -like $("*$($InputText)*") -or $($item.Title) -match $("$([regex]::Escape($InputText))") -or $($item.Track_name) -match $("$([regex]::Escape($InputText))") -or $($item.Live_Status) -match $("$([regex]::Escape($InputText))") -or $($item.Playlist) -match $("$([regex]::Escape($InputText))")
              $output
            }
          }else{
            $view.CustomFilter = "Title LIKE '%$InputText%' OR Track_name like '%$InputText%' OR Artist_Name like '%$InputText%' OR Playlist like '%$InputText%'"
          }
          #$view = $view | where {$_.id}
          if($thisapp.Config.YoutubeBrowser_Paging -ne $null){
            $approxGroupSize = (($view).count | Measure-Object -Sum).Sum / $thisapp.Config.YoutubeBrowser_Paging     
            $approxGroupSize = [math]::ceiling($approxGroupSize)
            # create number of groups requested
            $groupMembers = @{}
            $groupSizes = @{}
            for ($i = 1; $i -le ($approxGroupSize); $i++) {
              $groupMembers.$i = [Collections.Generic.List[Object]]@()
              $groupSizes.$i = 0
            }
            foreach ($item in $view) {
              $mostEmpty = (($groupSizes.GetEnumerator() | Sort-Object -Property 'Name' | where {$_.value -lt $thisapp.Config.YoutubeBrowser_Paging}) | Select-Object -First 1).name
              if($mostEmpty -ne $Null){
                if($groupMembers.$mostEmpty -notcontains $item){
                  $null = $groupMembers.$mostEmpty.Add($item)
                  $groupSizes.$mostEmpty += @($item).count
                }
              }
            } 
            $synchash.Youtube_View_Groups = $groupMembers.GetEnumerator() | select *
            $synchash.Youtube_TotalView_Groups = @($groupMembers.GetEnumerator() | select *).count
            $synchash.Youtube_CurrentView_Group = ($groupMembers.GetEnumerator() | select * | select -last 1).Name                          
            if(@($view).count -gt 1){
              $itemsource = ($groupMembers.GetEnumerator() | select * | select -last 1).Value | Sort-Object -Property {$_.Group_Name},{$_.Playlist},{$_.Track_Name}
              $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)
            }                              
          }else{  
            $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($Youtube_Datatable.datatable) 
            #$synchash.YoutubeTable.ItemsSource = $view
          }
          if(($view.psobject.properties.name | where {$_ -eq 'GroupDescriptions'}) -and $synchash.Youtube_GroupName){         
            $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
            $groupdescription.PropertyName = $synchash.Youtube_GroupName
            if($view.GroupDescriptions){
              $view.GroupDescriptions.Clear()
            }
            $null = $view.GroupDescriptions.Add($groupdescription)
            if($Sub_GroupName){
              $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $sub_groupdescription.PropertyName = $Sub_GroupName
              $null = $view.GroupDescriptions.Add($sub_groupdescription)
            }
          }elseif($view -and $view.GroupDescriptions){$view.GroupDescriptions.Clear()}
          $synchash.YoutubeMedia_View = $view        
          $synchash.YoutubeMedia_TableUpdate_timer.start()           
        }catch{
          write-ezlogs 'An exception occurred in YoutubeFilterTextBox' -showtime -catcherror $_ -logfile:$thisApp.Config.YoutubeMedia_logfile
          $this.Stop()
        }
        $this.Stop()
    }.GetNewClosure())
    $synchash.YoutubeFilterTextBox.Add_TextChanged({
        $synchash.YoutubeFilter_Handler = $this
        $synchash.YoutubeFilter_timer.start()
    }.GetNewClosure())  
    $synchash.Show_YoutubeMediaArtist_ComboBox.Add_SelectionChanged({
        $synchash.YoutubeFilter_Handler = $this
        $synchash.YoutubeFilter_timer.start()
    }.GetNewClosure()) 
  }
  if($thisApp.Config.startup_perf_timer){$Import_Youtube_Perf = "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Import-Youtube:          $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds`n[$(Get-date -format $logdateformat)]     | Import-Youtube Total: $($import_Youtube_measure.Seconds) seconds - $($import_Youtube_measure.Milliseconds) Milliseconds"}
}else{
  write-ezlogs 'Importing of Youtube Media is not enabled' -showtime -Warning -logfile:$thisApp.Config.YoutubeMedia_logfile
  $syncHash.YoutubeTable.isEnabled = $false
  $syncHash.Youtube_Tabitem.isEnabled = $false
  if($syncHash.MainGrid_Bottom_TabControl.items -contains $syncHash.Youtube_Tabitem){
    $Null = $syncHash.MainGrid_Bottom_TabControl.items.Remove($syncHash.Youtube_Tabitem) 
  }
}
#---------------------------------------------- 
#endregion Import-Youtube
#----------------------------------------------

#---------------------------------------------- 
#region ContextMenu Routed Event Handlers
#----------------------------------------------

$synchash.MediaTable.tag = @{        
  synchash = $synchash;
  thisScript = $thisScript;
  thisApp = $thisapp
  PlaySpotify_Media_Command = $PlaySpotify_Media_Command
}
$synchash.SpotifyTable.tag = $synchash.MediaTable.tag
$synchash.YoutubeTable.tag = $synchash.MediaTable.tag

$synchash.PreviewDrop_command = {
  [System.Object]$script:sender = $args[0]
  [System.Windows.DragEventArgs]$d = $args[1]  
  #write-ezlogs ">>>> d formats $($d.data.GetFormats() | out-string)" -showtime -color cyan
  #write-ezlogs ">>>> d.data $($d.data.GetData([GongSolutions.Wpf.DragDrop.DragDrop]::DataFormat.Name) | out-string)" -showtime -color cyan
  #write-ezlogs ">>>> d.data.name $([GongSolutions.Wpf.DragDrop.DragDrop]::GetSelectDroppedItems($d) | out-string)" -showtime -color cyan
  #write-ezlogs ">>>> d.data.name $($d.data.GetDataPresent([GongSolutions.Wpf.DragDrop.DragDrop]::GetSelectDroppedItems($d)) | out-string)" -showtime -color cyan
  #write-ezlogs ">>>> OG Source $($d.OriginalSource | out-string)" -showtime -color cyan
  #write-ezlogs ">>>> Source $($d.Source | out-string)" -showtime -color cyan

  if($d.Data.GetDataPresent([Windows.Forms.DataFormats]::Text)){
    try{  
      $LinkDrop = $d.data.GetData([Windows.Forms.DataFormats]::Text) 
        
      if(-not [string]::IsNullOrEmpty($LinkDrop) -and (Test-url $LinkDrop)){
        if($LinkDrop -match 'twitch.tv'){
          $d.Handled = $true
          $twitch_channel = $((Get-Culture).textinfo.totitlecase(($LinkDrop | split-path -leaf).tolower()))
          write-ezlogs ">>>> Adding Twitch channel $twitch_channel - $LinkDrop" -showtime -color cyan    
          $Group = 'Twitch'                   
        }elseif($LinkDrop -match 'youtube.com' -or $LinkDrop -match 'youtu.be'){
          if($LinkDrop -match '&t='){
            $LinkDrop = ($($LinkDrop) -split('&t='))[0].trim()
          }          
          write-ezlogs ">>>> Adding Youtube link $LinkDrop" -showtime -color cyan
          $url = [uri]$linkDrop
          $Group = 'Youtube'
          if($LinkDrop -match "v="){
            $youtube_id = ($($LinkDrop) -split('v='))[1].trim()    
          }elseif($LinkDrop -match 'list='){
            $youtube_id = ($($LinkDrop) -split('list='))[1].trim()                  
          }             
          $d.Handled = $true          
        }
        if($d.Handled){
          $synchash.Youtube_Progress_Ring.isActive = $true
          if($thisApp.Config.PlayLink_OnDrop){
            if($youtube_id){
              try{
                $video_info = Get-YouTubeVideo -Id $youtube_id
              }catch{
                write-ezlogs "An exception occurred executing Get-YoutubeVideo" -showtime -catcherror $_
              }
               
              if($video_info){
 
                if($video_info.snippet.title){
                  $title = $video_info.snippet.title
                }elseif($video_info.localizations.en.title){
                  $title = $video_info.localizations.en.title
                }                                
                $description = $video_info.snippet.description
                $channel_id = $video_info.snippet.channelId
                $channel_title = $video_info.snippet.channelTitle                 
                $images = $video_info.snippet.thumbnails
                $thumbnail = $video_info.snippet.thumbnails.medium.url
                <#                  if($channel_info.items.BrandingSettings.image.bannerExternalUrl){
                    $thumbnail = $channel_info.items.BrandingSettings.image.bannerExternalUrl
                }#>
                if($video_info.contentDetails.duration){
                  $TimeValues = $video_info.contentDetails.duration
                  if($TimeValues -match 'H'){
                    $hr = [regex]::matches($TimeValues, "PT(?<value>.*)H")| %{$_.groups[1].value}
                    $mins = [regex]::matches($TimeValues, "PT(?<value>.*)H(?<value>.*)M")| %{$_.groups[1].value}
                    $Secs = [regex]::matches($TimeValues, "M(?<value>.*)S")| %{$_.groups[1].value}
                  }elseif($TimeValues -match 'M'){
                    $hr = 0
                    $mins = [regex]::matches($TimeValues, "PT(?<value>.*)M")| %{$_.groups[1].value}
                    $Secs = [regex]::matches($TimeValues, "M(?<value>.*)S")| %{$_.groups[1].value}
                  }elseif($TimeValues -match 'S'){
                    $hr = 0
                    $mins = 0
                    $Secs = [regex]::matches($TimeValues, "PT(?<value>.*)S")| %{$_.groups[1].value}
                  }else{
                    $hr = 0
                    $mins = 0
                    $secs = 0
                  }
                  $duration = [TimeSpan]::Parse("$hr`:$mins`:$secs").TotalMilliseconds
                }
                $viewcount = $video_info.statistics.viewCount              
              }else{
                $title = "Youtube Video - $youtube_id"
              }                
            }
            $track_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($LinkDrop)-YoutubeLinkDrop")
            $track_encodedTitle = [System.Convert]::ToBase64String($track_encodedBytes)
            $media = New-Object PsObject -Property @{
              'title' =  $title
              'description' = $description
              'playlist_index' = ''
              'channel_id' = $channel_id
              'id' = $youtube_id
              'duration' = $duration
              'encodedTitle' = $track_encodedTitle
              'url' = $url
              'timeindex' = $timeindex
              'urls' = $LinkDrop                
              'webpage_url' = $LinkDrop
              'thumbnail' = $thumbnail
              'view_count' = $viewcount
              'manifest_url' = ''
              'uploader' = $channel_title
              'webpage_url_domain' = $url.Host
              'type' = ''
              'availability' = ''
              'Tracks_Total' = ''
              'images' = $images
              'Playlist_url' = ''
              'playlist_id' = $youtube_id
              'Profile_Path' =''
              'Profile_Date_Added' = $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss:tt')
              'Source' = 'YoutubePlaylist_item'
              'Group' = $Group
            }            
            Start-Media -Media $media -thisApp $thisApp -synchash $synchash -Show_notification -Script_Modules $Script_Modules -use_WebPlayer:$thisapp.config.Youtube_WebPlayer
          }
          #$synchash.import_Youtube_scriptblock = ({
          try{
            Import-Youtube -Youtube_URL $LinkDrop -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -thisApp $thisapp -use_runspace
            if($thisApp.Config.PlayLink_OnDrop){
              write-ezlogs ">>>> Starting update_status_timer" -showtime
              try{
                $synchash.update_status_timer.start()
                #$synchash.WebPlayer_Playing_timer.Start() 
              }catch{
                write-ezlogs "An exception occurred executing update_status_timer and WebPlayer_Playing_timer" -showtime -catcherror $_
              }
            }
          }catch{
            write-ezlogs 'An exception occurred in import_Youtube_scriptblock' -showtime -catcherror $_ -logfile:$thisApp.Config.YoutubeMedia_logfile
          }
          #}.GetNewClosure())
          #$Variable_list = Get-Variable | where {$_.Options -notmatch 'ReadOnly' -and $_.Options -notmatch 'Constant'}
          #Start-Runspace -scriptblock $synchash.import_Youtube_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -Load_Modules -Script_Modules $Script_Modules -runspace_name 'import_Youtube_scriptblock'          
        }        
      }else{
        write-ezlogs "The provided URL is not valid or was not provided! -- $LinkDrop" -showtime -warning
      }                        
    }catch{
      write-ezlogs "An exception occurred in PreviewDrop" -showtime -catcherror $_
    }    
  }elseif($d.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)){
    try{  
      $FileDrop = $d.Data.GetData([Windows.Forms.DataFormats]::FileDrop)  
      if(([System.IO.FIle]::Exists($FileDrop) -or [System.IO.Directory]::Exists($FileDrop))){     
        $d.Handled = $true  
        write-ezlogs ">>>> Adding Local Media $FileDrop" -showtime -color cyan
        Import-Media -Media_Path $FileDrop -verboselog:$thisApp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -use_runspace       
      }else{
        write-ezlogs "The provided Path is not valid or was not provided! -- $FileDrop" -showtime -warning
      }                        
    }catch{
      write-ezlogs "An exception occurred in PreviewDrop" -showtime -catcherror $_
    }    
  }elseif($d.data.GetDataPresent([GongSolutions.Wpf.DragDrop.DragDrop]::DataFormat.Name)){       
    $item = $d.data.GetData([GongSolutions.Wpf.DragDrop.DragDrop]::DataFormat.Name)
    $Media = $item.tag.Media
    #write-ezlogs "item.tag.Playlist $($item | out-string)"
    if($item.Name -eq 'Playlist'){
      $From_Playlist_Name = $item.Header.title
      $media = ($syncHash.Playlists_TreeView.Items | where {$_.Header.Title -eq $From_Playlist_Name}).items.tag.media
    }elseif($item.parent.Header.title){
      $From_Playlist_Name = $item.parent.Header.title 
    }elseif($sender.Name -eq 'PlayQueue_TreeView'){      
      $From_Playlist_Name = 'Play Queue'
    }elseif($item.source -eq 'Local' -or $item.source -eq 'SpotifyPlaylist' -or $item.source -eq 'YoutubePlaylist_item'){
      $From_Playlist_Name = 'MediaLibrary'
      $Media = $item
    }
    if($d.originalsource.datacontext.Name -eq 'Play_Queue' -or $d.originalsource.TemplatedParent.Name -eq 'PlayQueue_TreeView'){
      $to_Playlist_Name = 'Play Queue'
    }elseif($d.source.parent.Header.title){
      $to_Playlist_Name = $d.source.parent.Header.title
    }else{
      $to_Playlist_Name = $sender.items.Name
    }
    $from_Playlist = $item.parent.Header
    $to_PlayList = $d.originalsource.datacontext
    write-ezlogs ">>>> Drag/Drop From Playlist Name: $($From_Playlist_Name | out-string)" -showtime
    #write-ezlogs "Media $($Media | out-string)" -showtime
    write-ezlogs ">>>> Drag/Drop To Playlist Name $($to_Playlist_Name | out-string)" -showtime
    #write-ezlogs ">>>> Drag/Drop To Playlist $($to_PlayList | out-string)" -showtime
    #write-ezlogs "d.originalsource.Content: $($d.originalsource.Content | out-string)"
    #write-ezlogs ">>>> Drag/Drop source.parent $($d.source.parent | out-string)" -showtime
    #write-ezlogs ">>>> from playlist $($from_Playlist | out-string)" -showtime
    #write-ezlogs "to playlist $($to_PlayList | out-string)" -showtime
    if($to_Playlist_Name -eq 'Play Queue'){       
      foreach($m in $media | where {-not [string]::IsNullOrEmpty("$($_.id)")}){
        if($thisApp.config.Current_Playlist.values -notcontains $m.id)
        {
          if($VerboseLog){write-ezlogs " | Adding $($m.id) to Play Queue from Drag and Drop" -showtime}                  
          $Current_Playlist_ChildItem = New-Object System.Windows.Controls.TreeViewItem
          if($M.Spotify_Path){         
            $Title = "$($m.Artist_Name) - $($m.Track_Name)"
            $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Spotify.png"
            $click_command = $synchash.PlayMedia_Command
          }elseif($M.webpage_url -match 'twitch'){
            $Title = "$($m.Title)"
            if($M.profile_image_url){
              if($thisApp.Config.Verbose_logging){write-ezlogs "Media Image found: $($M.profile_image_url)" -showtime}       
              if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
                if($thisApp.Config.Verbose_logging){write-ezlogs " Creating image cache directory: $($thisApp.config.image_Cache_path)" -showtime}
                $null = New-item ($thisApp.config.image_Cache_path) -ItemType directory -Force
              }           
              $encodeduri = $Null  
              $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$([System.Uri]::new($M.profile_image_url).Segments | select -last 1)-Local")
              $encodeduri = [System.Convert]::ToBase64String($encodedBytes)                     
              $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),"$($encodeduri).png")
              if([System.IO.File]::Exists($image_Cache_path)){
                $cached_image = $image_Cache_path
              }elseif($M.profile_image_url){         
                if($thisApp.Config.Verbose_logging){write-ezlogs "| Destination path for cached image: $image_Cache_path" -showtime}
                if(!([System.IO.File]::Exists($image_Cache_path))){
                  try{
                    if([System.IO.File]::Exists($M.profile_image_url)){
                      if($thisApp.Config.Verbose_logging){write-ezlogs "| Cached Image not found, copying image $($M.profile_image_url) to cache path $image_Cache_path" -enablelogs -showtime}
                      $null = Copy-item -LiteralPath $M.profile_image_url -Destination $image_Cache_path -Force
                    }else{
                      $uri = new-object system.uri($M.profile_image_url)
                      if($thisApp.Config.Verbose_logging){write-ezlogs "| Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -enablelogs -showtime}
                      (New-Object System.Net.WebClient).DownloadFile($uri,$image_Cache_path) 
                    }             
                    if([System.IO.File]::Exists($image_Cache_path)){
                      $stream_image = [System.IO.File]::OpenRead($image_Cache_path) 
                      $image = new-object System.Windows.Media.Imaging.BitmapImage
                      $image.BeginInit();
                      $image.CacheOption = "OnLoad"
                      #$image.CreateOptions = "DelayCreation"
                      #$image.DecodePixelHeight = 229;
                      $image.DecodePixelWidth = 20
                      $image.StreamSource = $stream_image
                      $image.EndInit();        
                      $stream_image.Close()
                      $stream_image.Dispose()
                      $stream_image = $null
                      $image.Freeze();
                      if($thisApp.Config.Verbose_logging){write-ezlogs "Saving decoded media image to path $image_Cache_path" -showtime -enablelogs}
                      $bmp = [System.Windows.Media.Imaging.BitmapImage]$image
                      $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
                      $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bmp))
                      $save_stream = [System.IO.FileStream]::new("$image_Cache_path",'Create')
                      $encoder.Save($save_stream)
                      $save_stream.Dispose()       
                    }  
                    $cached_image = $image_Cache_path            
                  }catch{
                    $cached_image = $Null
                    write-ezlogs "An exception occurred attempting to download $image to path $image_Cache_path" -showtime -catcherror $_
                  }
                }           
              }else{
                write-ezlogs "Cannot Download image $image to cache path $image_Cache_path - URL is invalid" -enablelogs -showtime -warning
                $cached_image = $Null        
              }              
            }
            if($cached_image){
              $icon_path = $cached_image
            }else{
              $icon_path = $cached_image
              $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Twitch.png"
            }
          }elseif($M.type -eq 'YoutubePlaylist_item'){
            $Title = "$($m.Title)"
            $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Youtube.png"
            $click_command = $synchash.PlayMedia_Command         
          }else{
            if($m.Name){
              if(!$m.Artist -and !$m.SongInfo.Artist -and [System.IO.Directory]::Exists($m.directory)){     
                try{
                  $artist = (Get-Culture).TextInfo.ToTitleCase(([System.IO.Path]::GetFileNameWithoutExtension($m.directory))).trim()            
                }catch{
                  write-ezlogs "An exception occurred getting file name without extension for $($m.directory)" -showtime -catcherror $_
                  $artist = ''
                }                
                if($thisApp.Config.Verbose_logging){write-ezlogs "  | Using Directory name for artist: $($artist) " -showtime }
              }elseif($m.Artist){
                $artist = $m.Artist
                if($thisApp.Config.Verbose_logging){write-ezlogs "  | Found Track Name artist: $($artist) " -showtime }
              }elseif($m.SongInfo.Artist){
                $artist = $m.SongInfo.Artist
                if($thisApp.Config.Verbose_logging){write-ezlogs "  | Found Track SongInfo artist: $($artist) " -showtime }
              }
              if(-not [string]::IsNullOrEmpty($artist)){
                $Title = "$($artist) - $($m.Name)"
              }else{
                $Title = "$($m.Name)"
              }                   
            }
            $Title = "$($m.Artist) - $($m.Title)"
            $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Vlc.png"
            $click_command = $synchash.PlayMedia_Command
          }
          if($m.live_status -eq 'Offline'){
            $fontstyle = 'Italic'
            $fontcolor = 'Gray'
            $FontWeight = 'Normal'
            $FontSize = 12          
          }elseif($m.live_status -eq 'Online' -or $m.live_status -eq 'Live'){
            $fontstyle = 'Normal'
            $fontcolor = 'LightGreen'
            $FontWeight = 'Normal'
            $FontSize = 12         
          }else{
            $fontstyle = 'Normal'
            $fontcolor = 'White' 
            $FontWeight = 'Normal'
            $FontSize = 12                     
          }
          if($m.status_msg){
            $status_msg = $m.status_msg
            if($m.live_status -eq 'Offline'){
              $Status_fontcolor = 'Gray'
              $Status_fontstyle = 'Italic'
            }else{
              $Status_fontcolor = 'White'
              $Status_fontstyle = 'Normal'
            }           
            $Status_FontWeight = 'Normal'
            $Status_FontSize = 12
          }else{
            $status_msg = $null
            $Status_fontstyle = 'Normal'
            $Status_fontcolor = 'White' 
            $Status_FontWeight = 'Normal'
            $Status_FontSize = 12          
          }                     
          $header = New-Object PsObject -Property @{
            'title' = $title
            'ID' = $m.id
            'Number' = $number
            'Status' = $m.live_status
            'FontStyle' = $fontstyle
            'FontColor' = $fontcolor
            'FontWeight' = $FontWeight
            'BorderBrush' = 'Transparent'
            'PlayIconVisibility' = 'Hidden'
            'NumberVisibility' = 'Visible'
            'PlayIcon' = ''
            'PlayIconEnabled' = $false
            'PlayIconRepeat' = '1x'
            'BorderThickness' = '0'
            'NumberFontSize' = 12
            'FontSize' = $FontSize          
            'Status_Msg' = $status_msg
            'Status_FontStyle' = $Status_fontstyle
            'Status_FontColor' = $Status_fontcolor
            'Status_FontWeight' = $Status_FontWeight
            'Status_FontSize' = $Status_FontSize          
          }                  
          $Current_Playlist_ChildItem.Header = $header        
          $Current_Playlist_ChildItem.Name = 'Track'
          $Current_Playlist_ChildItem.Uid = $icon_path
          $Current_Playlist_ChildItem.IsSelected = $true
          $Current_Playlist_ChildItem.Tag = @{        
            synchash=$synchash;
            thisScript=$thisScript;
            thisApp=$thisApp
            PlayMedia_Command = $synchash.PlayMedia_Command
            All_Playlists = $synchash.all_playlists
            Media = $M
          }                  
          #$null = $Current_Playlist_ChildItem.AddHandler([System.Windows.Controls.Button]::MouseDoubleClickEvent,$click_command)
          #$null = $Current_Playlist_ChildItem.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$Synchash.Media_ContextMenu)
          #$null = $Current_Playlist_ChildItem.AddHandler([System.Windows.Controls.Button]::PreviewMouseLeftButtonDownEvent,$Drag_MouseDown)        
          $Play_Queue = $syncHash.PlayQueue_TreeView         
          $null = $Play_Queue.items.add($Current_Playlist_ChildItem)                     
          if($from_Playlist -eq 'Play Queue')
          {
            $d.Effects = [System.Windows.DragDropEffects]::Move
            $d.Handled = $false
            
          }else{
            $d.Effects = [System.Windows.DragDropEffects]::Copy
            $d.Handled = $true
          }
          try{
            $null = $thisApp.config.Current_Playlist.clear()
            $index = 0
            foreach($item in $Play_Queue.items.tag.Media.id | where {$_ -ne $M.id}){
              if($thisapp.config.Current_Playlist.values -notcontains $M.id){
                $null = $thisApp.config.Current_Playlist.add($index,$item) 
                $index++
              }                        
              #$null = $thisApp.config.Current_Playlist.add($item)
            }  
            $index = ($thisApp.config.Current_Playlist.keys | measure -Maximum).Maximum
            $index++
            $null = $thisApp.config.Current_Playlist.add($index,$M.id)               
            $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8    
               
          }catch{
            write-ezlogs "An exception occurred updating current config queue playlist" -showtime -catcherror $_
          }
        }
        else
        {
          write-ezlogs " | Play Queue already contains $($M.id)" -showtime
          
          try{
            #$e.Effects = [System.Windows.DragDropEffects]::Move             
            if($from_Playlist -eq 'Play Queue')
            {
              $d.Effects = [System.Windows.DragDropEffects]::Move 
              $d.Handled = $false  
              write-ezlogs " | Reordering Play Queue from Drag and Drop" -showtime
            }else{
              $d.Effects = [System.Windows.DragDropEffects]::Copy
              $d.Handled = $true
            }                                                       
          }catch{
            write-ezlogs "An exception occurred updating current config queue playlist" -showtime -catcherror $_
          }                   
        }  
      }
      if($from_Playlist_Name -eq $to_Playlist_Name){
        $d.Handled = $false 
      }else{
        $d.Handled = $true
      } 
      $synchash.Playqueue_update_timer = New-Object System.Windows.Threading.DispatcherTimer          
      $synchash.Playqueue_update_timer.add_tick({
          try{               
            $Play_Queue = $syncHash.PlayQueue_TreeView                
            #$thisApp.config.Current_Playlist = New-Object -TypeName 'System.Collections.ArrayList'
            $null = $thisApp.config.Current_Playlist.clear()
            $index = 0
            foreach($item in $Play_Queue.items | Select -Unique){   
              $id = $item.tag.Media.id
              #$item.header.Number = $index
              write-ezlogs " | Adding $($id) with index $($index) to play queue" -showtime                         
              $null = $thisApp.config.Current_Playlist.add($index,$id)  
              $index++            
            }  
            if($VerboseLog){write-ezlogs ">>>> Exporting updated play queue to $($thisApp.Config.Config_Path)" -showtime -color cyan}
            $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8                                         
            $this.Stop()
          }catch{
            $this.Stop()
            write-ezlogs "An exception occurred in Playqueue_update_timer" -showtime -catcherror $_
          }
      })                   
      #$synchash.PlayQueue_TreeView.items.refresh()  
           
      $synchash.Playqueue_update_timer.start() 
      $synchash.update_status_timer.start()
      $syncHash.PlayQueue_TreeView.UpdateLayout()   
      #                  
    }elseif($From_Playlist_Name -eq 'MediaLibrary' -and $to_Playlist_Name){
      try{
        $d.Effects = [System.Windows.DragDropEffects]::Copy
        $d.Handled = $false
        write-ezlogs ">>>> Adding $($media.title) to playlist $($to_Playlist_Name)" -showtime
        $Playlist_To_Add = $synchash.all_playlists | where {$_.Name -eq $to_Playlist_Name}
        if($Playlist_To_Add){               
          Add-Playlist -Media $media -Playlist $to_Playlist_Name -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging
        }                         
        $synchash.all_playlists | Export-Clixml "$($thisApp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml" -Force -Encoding UTF8
        $synchash.update_status_timer.start()  
        #$syncHash.Playlists_TreeView.UpdateLayout() 
      }catch{
        $d.Handled = $true
        write-ezlogs "An exception occurred adding $($Media.id) from $($media.source) to Playlist $to_Playlist_Name" -showtime -catcherror $_
      }    
    }   
    elseif($synchash.all_playlists -and $to_PlayList)
    {
      try{
        $d.Effects = [System.Windows.DragDropEffects]::Copy
        foreach($m in $media){
          $Playlist_To_Remove = $synchash.all_playlists | where {$_.Playlist_tracks.id -eq $M.id -and $_.Name -eq $from_Playlist}
          $Playlist_To_Add = $synchash.all_playlists | where {$_.Name -eq $to_Playlist}
          if($Playlist_To_Remove){
            $Playlist_Track_To_Remove = $Playlist_To_Remove.Playlist_tracks | where {$_.id -eq $M.id}
            $null = $Playlist_To_Remove.Playlist_tracks.Remove($Playlist_Track_To_Remove)
          }
          if($Playlist_To_Add){
            $Playlist_Track_To_Add = $synchash.all_playlists.Playlist_tracks | where {$_.id -eq $M.id}
            $null = $Playlist_To_Add.Playlist_tracks.Add($Playlist_Track_To_Add)
          }             
        }
        $d.Handled = $false      
        $synchash.all_playlists | Export-Clixml "$($thisApp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml" -Force -Encoding UTF8 
      }catch{
        $d.Handled = $true
        write-ezlogs "An exception occurred moving $($Media.id) from Playlist $($from_Playlist) to Playlist $to_Playlist" -showtime -catcherror $_
      }    
    }elseif($From_Playlist_Name -eq $to_Playlist_Name){
      try{
        $d.Effects = [System.Windows.DragDropEffects]::Move 
        $d.Handled = $false                  
        $Playlist_items = ($syncHash.Playlists_TreeView.Items | where {$_.Header.Title -eq $From_Playlist_Name}).items
        $Playlist_To_Update = $synchash.all_playlists | where {$_.Playlist_tracks.id -eq $Media.id -and $_.Name -eq $From_Playlist_Name} 
        $synchash.Playlist_update_timer = New-Object System.Windows.Threading.DispatcherTimer          
        $synchash.Playlist_update_timer.add_tick({
            try{               
              #write-ezlogs "Playlist to update before: $($Playlist_To_Update.Playlist_tracks.Title | out-string)"                        
              $Updated_Playlist = New-Object -TypeName 'System.Collections.ArrayList'
              if($Playlist_To_Update.Playlist_tracks -and $Playlist_items.tag.media){
                foreach($item in $Playlist_items.tag.media){
                  $null = $Updated_Playlist.add($item)
                } 
                $Playlist_To_Update.Playlist_tracks = $Updated_Playlist
                #write-ezlogs "Playlist to update after: $($Playlist_To_Update.Playlist_tracks.Title | out-string)"  
                $Playlist_To_Update | Export-Clixml $Playlist_To_Update.Playlist_Path -Force 
                $d.Handled = $false 
              }else{
                write-ezlogs "Unable to find Playlist($playlist_to_update) to update for media $($Media.title - $Media.id)" -showtime -warning
                $d.Handled = $true
              }                           
              $this.Stop()
            }catch{
              $this.Stop()
              write-ezlogs "An exception occurred in playlist_update_timer" -showtime -catcherror $_
            }
        }.GetNewClosure())                   
        $synchash.Playlist_update_timer.start()  
        $syncHash.Playlists_TreeView.UpdateLayout()                                              
      }catch{
        $d.Handled = $true
        write-ezlogs "An exception occurred moving $($Media.id) from Playlist $($from_Playlist) to Playlist $to_Playlist" -showtime -catcherror $_
      }           
    }else{
      $d.Handled = $true
      write-ezlogs "Not sure what to do" -showtime -warning
    }              
  }else{
    $d.Handled = $true
  }        
}.GetNewClosure() 

$synchash.Add_to_Playlist_timer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.Add_to_Playlist_timer.add_Tick({
    try{
      $Playlist = $synchash.Add_to_Playlist_Playlist
      $Selected_Media = $synchash.Add_to_Playlist_Selected_Media
      $playlist_items = $synchash.Add_to_Playlist_playlist_items
      $sender = $synchash.Add_to_Playlist_Sender

      #write-ezlogs " | Playlist $($Playlist)" -showtime
      #write-ezlogs " | Selected media $($Selected_Media | out-string)" -showtime
      #  write-ezlogs " | Sender $( $sender | out-string)" -showtime
      if($Playlist -eq 'Play Queue' -and $Selected_Media){   
        foreach($Media in $Selected_Media){
          if($Media.Spotify_Path){
            $Spotify = $true
            if($thisapp.config.Current_Playlist.values -notcontains $Media.encodedtitle){
              write-ezlogs " | Adding $($Media.encodedtitle) to Play Queue" -showtime
              $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
              $index++
              $null = $thisapp.config.Current_Playlist.add($index,$Media.encodedtitle)
            }   
          }elseif($thisapp.config.Current_Playlist.values -notcontains $Media.id){
            $Spotify = $false
            $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
            $index++
            write-ezlogs " | Adding $($Media.id) to Play Queue" -showtime
            $null = $thisapp.config.Current_Playlist.add($index,$Media.id)          
          }  
        }    
      }elseif($Playlist -eq 'Play All'){     
        if($sender.tag.source.Name -eq 'Play_Queue'){
          #$playlist_items = ($synchash.PlayQueue_TreeView.Items | where {$_.Header -eq $sender.tag.datacontext}).items.tag.media
          $playlist_items = $synchash.PlayQueue_TreeView.Items.tag.media
        }else{
          $playlist_items = ($synchash.Playlists_TreeView.Items | where {$_.Header -eq $sender.tag.datacontext}).items.tag.media
        }
        if(!$playlist_items){
          $playlist_items = $sender.tag.datacontext.items
          $Playlist_source = $sender.tag.datacontext.items.playlist | select -First 1
        }else{
          $Playlist_source = $sender.tag.datacontext
        }
        if($Playlist_source.title){
          $Playlist_source = $Playlist_source.title
        }
        #write-ezlogs "Playlist items: $($playlist_items | out-string)" -showtime
        if($sender.tag.source.Name -ne 'Play_Queue'){       
          #write-ezlogs "Adding all items in Playlist $($Playlist_source) to Play Queue" -showtime
          foreach($Media in $playlist_items){
            if($Media.Spotify_Path){
              if($thisapp.config.Current_Playlist.values -notcontains $Media.encodedtitle){
                #write-ezlogs " | Adding $($Media.encodedtitle) to Play Queue" -showtime
                $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
                $index++
                $null = $thisapp.config.Current_Playlist.add($index,$Media.encodedtitle)
              }   
            }elseif($thisapp.config.Current_Playlist -notcontains $Media.id){
              #write-ezlogs " | Adding $($Media.id) to Play Queue" -showtime
              $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
              $index++
              $null = $thisapp.config.Current_Playlist.add($index,$Media.id)            
            }  
          }
        }
        $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
        Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -startup -thisApp $thisapp    
        Get-PlayQueue -verboselog:$false -synchash $synchash -thisApp $thisapp
        $start_media = $playlist_items | select -first 1
        write-ezlogs ">>>> Starting playback of $($start_media | Out-String)" -showtime -color cyan
        if($start_media.Spotify_path){
          Start-SpotifyMedia -Media $start_media -thisApp $thisapp -synchash $synchash -Script_Modules $Script_Modules -Show_notification
        }else{
          Start-Media -media $start_media -thisApp $thisapp -synchash $synchash -Show_notification -Script_Modules $Script_Modules
        }
        return                   
      }elseif($Playlist -eq 'Add Playlist to Play Queue'){
        $playlist_items = ($synchash.Playlists_TreeView.Items | where {$_.Header -eq $sender.tag.datacontext}).items.tag.media
        if(!$playlist_items){
          $playlist_items = $sender.tag.datacontext.items
          $Playlist_source = $sender.tag.datacontext.items.playlist | select -First 1
        }else{
          $Playlist_source = $sender.tag.datacontext
        }
        #write-ezlogs "Playlist items: $($playlist_items | Out-String)" -showtime
        #write-ezlogs "Adding all items in Playlist $($Playlist_source) to Play Queue" -showtime
        foreach($Media in $playlist_items){
          if($Media.Spotify_Path){
            if($thisapp.config.Current_Playlist.values -notcontains $Media.encodedtitle){
              write-ezlogs " | Adding $($Media.encodedtitle) to Play Queue" -showtime
              $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
              $index++
              $null = $thisapp.config.Current_Playlist.add($index,$Media.encodedtitle)            
            }   
          }elseif($thisapp.config.Current_Playlist.values -notcontains $Media.id){
            write-ezlogs " | Adding $($Media.id) to Play Queue" -showtime
            $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
            $index++
            $null = $thisapp.config.Current_Playlist.add($index,$Media.id)           
          }  
        }              
      }elseif($Selected_Media){
        write-ezlogs " | Adding $($Media.encodedtitle) to Play Queue" -showtime
        Add-Playlist -Media $Selected_Media -Playlist $Playlist -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging
      }else{
        write-ezlogs 'Selected media was null! Unable to do anything!' -showtime -warning
      } 
      $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
      Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -startup -thisApp $thisapp
      Get-PlayQueue -verboselog:$false -synchash $synchash -thisApp $thisapp
      $this.Stop()
    }catch{
      write-ezlogs "An exception occurred in Add_to_Playlist_timer " -showtime -catcherror $_
      $this.Stop()
    }finally{
      $this.Stop()
    } 
})

[System.Windows.RoutedEventHandler]$synchash.Add_to_PlaylistCommand = {
  param($sender)
  try{
    $synchash.Add_to_Playlist_Playlist  = $sender.header
    $synchash.Add_to_Playlist_Sender = $sender
    if($sender.tag.source.Name -eq 'YoutubeTable'){
      $synchash.Add_to_Playlist_Selected_Media = $synchash.YoutubeTable.selecteditems
    }elseif($sender.tag.source.Name -eq 'SpotifyTable'){
      $synchash.Add_to_Playlist_Selected_Media = $synchash.SpotifyTable.selecteditems
    }elseif($sender.tag.source.Name -eq 'MediaTable'){
      $synchash.Add_to_Playlist_Selected_Media = $synchash.MediaTable.selecteditems
    }elseif($sender.tag.Media){
      $synchash.Add_to_Playlist_Selected_Media = $sender.tag.Media
    }elseif($synchash.Add_to_Playlist_Playlist -eq 'Add Playlist to Play Queue' -or $synchash.Add_to_Playlist_Playlist -eq 'Play All'){
      $synchash.Add_to_Playlist_playlist_items = ($synchash.Playlists_TreeView.Items | where {$_.Header -eq $sender.tag.datacontext}).items.tag.media
    }else{
      $synchash.Add_to_Playlist_Selected_Media = $Null
      $synchash.Add_to_Playlist_Playlist = $Null
      $synchash.Add_to_Playlist_items = $Null
      $synchash.Add_to_Playlist_Sender = $Null
    }          
    #write-ezlogs "[Add_to_PlaylistCommand] tag.source: $($sender.tag.source | Out-String)" -showtime
    #write-ezlogs "[Add_to_PlaylistCommand] datacontext: $($sender.datacontext | Out-String)" -showtime 
    $synchash.Add_to_Playlist_timer.start()
  }catch{
    write-ezlogs "An exception occurred in Add_to_PlaylistCommand" -showtime -catcherror $_
  }
}
<#[System.Windows.RoutedEventHandler]$synchash.Add_to_PlaylistCommand = {
    param($sender)
    #$synchash = $sender.tag.synchash
    #$thisapp = $sender.tag.thisapp
    #$thisScript = $sender.tag.thisScript 
    $Playlist = $sender.header
    $PlayMedia_Command = $synchash.PlayMedia_Command
    #write-ezlogs "Playlist: $($sender.header | out-string)" 
    #write-ezlogs "ogsource: $($args.OriginalSource.name | out-string)" 
    #write-ezlogs "sender.datacontext: $($sender.datacontext | out-string)"
    if($sender.tag.source.Name -eq 'YoutubeTable'){
    $Selected_Media = $synchash.YoutubeTable.selecteditems
    }elseif($sender.tag.source.Name -eq 'SpotifyTable'){
    $Selected_Media = $synchash.SpotifyTable.selecteditems
    }elseif($sender.tag.source.Name -eq 'MediaTable'){
    $Selected_Media = $synchash.MediaTable.selecteditems
    }elseif($sender.tag.Media){
    $Selected_Media = $sender.tag.Media
    }elseif($Playlist -eq 'Add Playlist to Play Queue' -or $Playlist -eq 'Play All'){
    $playlist_items = ($synchash.Playlists_TreeView.Items | where {$_.Header -eq $sender.tag.datacontext}).items.tag.media
    }else{
    $Selected_Media = $Null
    $Playlist = $Null
    }          
    if($thisapp.Config.Verbose_logging){
    write-ezlogs "[Add_to_PlaylistCommand] tag.source: $($sender.tag.source | Out-String)" -showtime
    write-ezlogs "[Add_to_PlaylistCommand] datacontext: $($sender.datacontext | Out-String)" -showtime
    }
    try{
    if($Playlist -eq 'Play Queue' -and $Selected_Media){   
    foreach($Media in $Selected_Media){
    if($Media.Spotify_Path){
    $Spotify = $true
    if($thisapp.config.Current_Playlist.values -notcontains $Media.encodedtitle){
    write-ezlogs " | Adding $($Media.encodedtitle) to Play Queue" -showtime
    $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
    $index++
    $null = $thisapp.config.Current_Playlist.add($index,$Media.encodedtitle)
    }   
    }elseif($thisapp.config.Current_Playlist.values -notcontains $Media.id){
    $Spotify = $false
    $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
    $index++
    write-ezlogs " | Adding $($Media.id) to Play Queue" -showtime
    $null = $thisapp.config.Current_Playlist.add($index,$Media.id)          
    }  
    }    
    }elseif($Playlist -eq 'Play All'){     
    if($sender.tag.source.Name -eq 'Play_Queue'){
    #$playlist_items = ($synchash.PlayQueue_TreeView.Items | where {$_.Header -eq $sender.tag.datacontext}).items.tag.media
    $playlist_items = $synchash.PlayQueue_TreeView.Items.tag.media
    }else{
    $playlist_items = ($synchash.Playlists_TreeView.Items | where {$_.Header -eq $sender.tag.datacontext}).items.tag.media
    }
    if(!$playlist_items){
    $playlist_items = $sender.tag.datacontext.items
    $Playlist_source = $sender.tag.datacontext.items.playlist | select -First 1
    }else{
    $Playlist_source = $sender.tag.datacontext
    }
    if($Playlist_source.title){
    $Playlist_source = $Playlist_source.title
    }
    #write-ezlogs "Playlist items: $($playlist_items | out-string)" -showtime
    if($sender.tag.source.Name -ne 'Play_Queue'){       
    write-ezlogs "Adding all items in Playlist $($Playlist_source) to Play Queue" -showtime
    foreach($Media in $playlist_items){
    if($Media.Spotify_Path){
    if($thisapp.config.Current_Playlist.values -notcontains $Media.encodedtitle){
    write-ezlogs " | Adding $($Media.encodedtitle) to Play Queue" -showtime
    $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
    $index++
    $null = $thisapp.config.Current_Playlist.add($index,$Media.encodedtitle)
    }   
    }elseif($thisapp.config.Current_Playlist -notcontains $Media.id){
    write-ezlogs " | Adding $($Media.id) to Play Queue" -showtime
    $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
    $index++
    $null = $thisapp.config.Current_Playlist.add($index,$Media.id)            
    }  
    }
    }
    $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
    Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -startup -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command      
    $start_media = $playlist_items | select -first 1
    write-ezlogs ">>>> Starting playback of $($start_media | Out-String)" -showtime -color cyan
    if($start_media.Spotify_path){
    Start-SpotifyMedia -Media $start_media -thisApp $thisapp -synchash $synchash -Script_Modules $Script_Modules -Show_notification
    }else{
    Start-Media -media $start_media -thisApp $thisapp -synchash $synchash -Show_notification -Script_Modules $Script_Modules
    }
    return                   
    }elseif($Playlist -eq 'Add Playlist to Play Queue'){
    $playlist_items = ($synchash.Playlists_TreeView.Items | where {$_.Header -eq $sender.tag.datacontext}).items.tag.media
    if(!$playlist_items){
    $playlist_items = $sender.tag.datacontext.items
    $Playlist_source = $sender.tag.datacontext.items.playlist | select -First 1
    }else{
    $Playlist_source = $sender.tag.datacontext
    }
    write-ezlogs "Playlist items: $($playlist_items | Out-String)" -showtime
    write-ezlogs "Adding all items in Playlist $($Playlist_source) to Play Queue" -showtime
    foreach($Media in $playlist_items){
    if($Media.Spotify_Path){
    if($thisapp.config.Current_Playlist.values -notcontains $Media.encodedtitle){
    write-ezlogs " | Adding $($Media.encodedtitle) to Play Queue" -showtime
    $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
    $index++
    $null = $thisapp.config.Current_Playlist.add($index,$Media.encodedtitle)            
    }   
    }elseif($thisapp.config.Current_Playlist.values -notcontains $Media.id){
    write-ezlogs " | Adding $($Media.id) to Play Queue" -showtime
    $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
    $index++
    $null = $thisapp.config.Current_Playlist.add($index,$Media.id)           
    }  
    }              
    }elseif($Selected_Media){
    write-ezlogs " | Adding $($Media.encodedtitle) to Play Queue" -showtime
    Add-Playlist -Media $Selected_Media -Playlist $Playlist -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging
    }else{
    write-ezlogs 'Selected media was null! Unable to do anything!' -showtime -warning
    } 
    $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
    Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -startup -thisApp $thisapp
    Get-PlayQueue -verboselog:$false -synchash $synchash -thisApp $thisapp
    }catch{
    write-ezlogs "An exception occurred adding $($Media.title | Out-String) to Playlist $($Playlist)" -showtime -catcherror $_
    }
    }
#>
[System.Windows.RoutedEventHandler]$synchash.Add_to_New_PlaylistCommand = {
  param($sender)
  #$synchash = $sender.tag.synchash
  #$thisapp = $sender.tag.thisapp
  #$thisScript = $sender.tag.thisScript 
  $Playlist = $sender.header
  write-ezlogs "$($sender.header)" -showtime
  write-ezlogs "Sender $($sender | out-string)" -showtime
  $PlayMedia_Command = $synchash.PlayMedia_Command   
  $Media = $sender.tag.Media 
  #$all_playlists = $synchash.all_playlists
  write-ezlogs 'Prompting for new playlist name...' -showtime
  try{
    $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()    
    #$customdialog = [MahApps.Metro.Controls.Dialogs.CustomDialog]::new($synchash.Window,$Button_Settings)
    #$resource = [System.Windows.ResourceDictionary]::new()
    #$theme = [MahApps.Metro.Theming.MahAppsLibraryThemeProvider]::new()
    #$newtheme = $theme.GetLibraryThemes() | where {$_.Name -eq 'Dark.Blue'}
    #$themeManager = [ControlzEx.Theming.ThemeManager]::Current.GetTheme('Dark.Blue')
    #$resource.Source = "$($thisApp.Config.Current_Folder)`\Views`\InputDialog.xaml"
    #$button_settings.CustomResourceDictionary = $newtheme.Resources
    #$buttonStyle = $button_settings.CustomResourceDictionary
    #write-ezlogs "styel $($buttonStyle | out-string)"
    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($synchash.Window,'Add New Playlist','Enter the name of the new playlist',$Button_Settings)
    if(-not [string]::IsNullOrEmpty($result)){   
      $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
      $pattern = "[™`?�:$illegal]"
      $result = ([Regex]::Replace($result, $pattern, '')).trim() 
      [int]$character_Count = ($result | measure-object -Character -ErrorAction SilentlyContinue).Characters
      if([int]$character_Count -ge 100){
        write-ezlogs "Playlist name too long! ($character_Count characters). Please choose a name 100 characters or less " -showtime -warning
        Update-Notifications  -Level 'WARNING' -Message "Playlist name too long! ($character_Count). Please choose a name 100 characters or less" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
        return
      }
    }
    if(-not [string]::IsNullOrEmpty($result)){ 
      if($Playlist -eq 'Create Playlist from Queue'){
        write-ezlogs "Creating new playlist $result from Play Queue " -showtime -warning  
        #$Current_playlist_items = $synchash.PlayQueue_TreeView.Items.items.tag.media  
        #write-ezlogs "Playlist items $($Current_playlist_items | Out-String)" -showtime    
        Add-Playlist -Media $synchash.PlayQueue_TreeView.Items -Playlist $result -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging
      }elseif($Playlist -eq 'Save as New Playlist'){
        write-ezlogs "Creating new playlist $result from $($sender.tag.datacontext.name | Out-String) " -showtime -warning  
        $playlist_items = $sender.tag.datacontext.items    
        Add-Playlist -Media $playlist_items -Playlist $result -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging
      }elseif($Playlist -eq 'Add all Selected to New Playlist' -or $Playlist -eq 'Add to New Playlist..'){ 
        if($sender.tag.source.Name -eq 'YoutubeTable'){
          $playlist_items = $synchash.YoutubeTable.selecteditems
        }elseif($sender.tag.source.Name -eq 'SpotifyTable'){
          $playlist_items = $synchash.SpotifyTable.selecteditems
        }elseif($sender.tag.source.Name -eq 'MediaTable'){
          $playlist_items = $synchash.MediaTable.selecteditems
        }           
        Add-Playlist -Media $playlist_items -Playlist $result -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging
      }elseif($media){   
        write-ezlogs "creating new empty playlist $result for media $($media.title)" -showtime -warning        
        Add-Playlist -Media $Media -Playlist $result -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging            
      }else{
        write-ezlogs "No media selected, creating new empty playlist $result" -showtime -warning        
        Add-Playlist -Media $Media -Playlist $result -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging        
      } 
      $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
      Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -thisApp $thisapp  
    }else{
      write-ezlogs 'No valid playlist name was provided' -showtime -warning
    }
  }catch{
    write-ezlogs "An exception occurred adding $($Media.title | Out-String) to new Playlist $($Playlist)" -showtime -catcherror $_
  }
} 

[System.Windows.RoutedEventHandler]$DeletePlaylist_Command = {
  param($sender)
  #[System.Collections.Hashtable]$all_playlists = $sender.tag.all_playlists 
  try{
    $synchash = $sender.tag.synchash
    $thisapp = $sender.tag.thisapp
    $thisScript = $sender.tag.thisScript 
    $Playlist = ($sender.Parent.DataContext).title
    $PlayMedia_Command = $synchash.PlayMedia_Command   
    $Media = $sender.tag.Media   
    $synchash.all_playlists = Import-Clixml "$($thisapp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml" 
    write-ezlogs "Prompting for to confirm playlist deletion for $Playlist..." -showtime    
    $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
    $Button_Settings.AffirmativeButtonText = 'Yes'
    $Button_Settings.NegativeButtonText = 'No'  
    $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Delete Playlist $Playlist","Are you sure you wish to remove the $Playlist Playlist? This will not remove the media items in the playlist",$okandCancel,$Button_Settings)
    if($result -eq 'Affirmative'){
      $playlist_to_remove = $synchash.all_playlists | where {$_.name -eq $Playlist}
      #write-ezlogs "Playlist Name: $($playlist_to_remove.name)" -showtime
      $playlist_to_remove_path = $playlist_to_remove.Playlist_Path
      if([System.IO.File]::Exists($playlist_to_remove_path)){
        write-ezlogs "Removing playlist path $($playlist_to_remove_path)" -showtime -warning
        $null = [System.IO.File]::Delete($playlist_to_remove_path)
        write-ezlogs "Removing playlist $Playlist" -showtime -warning
        #write-ezlogs "Playlist to remove $($playlist_to_remove | out-string)" -showtime -warning
        #$Null = [System.Collections.ArrayList]$all_playlists.playlists.remove($playlist_to_remove)
        Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -thisApp $thisapp      
      }else{write-ezlogs "Unable to find playlist to remove at  $playlist_to_remove_path" -showtime -warning}

      #Add-Playlist -Media $Media -Playlist $result -thisApp $thisApp -synchash $synchash -verboselog
    }else{write-ezlogs 'User wish to cancel the operation' -showtime -warning}   
    $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
  }catch{write-ezlogs "An exception occurred deleting Playlist $($Playlist)" -showtime -catcherror $_}
}  
                  
[System.Windows.RoutedEventHandler]$Remove_from_PlaylistCommand = {
  param($sender)
  $synchash = $sender.tag.synchash
  $thisapp = $sender.tag.thisapp
  $thisScript = $sender.tag.thisScript 
  $PlayMedia_Command = $synchash.PlayMedia_Command
  $Media = $sender.tag.Media  
  #$all_playlists = $sender.tag.all_playlists
  $Playlist = $sender.header
  Update-Playlist -Playlist $Playlist -media $Media -synchash $synchash -thisApp $thisApp -Remove
}   
[System.Windows.RoutedEventHandler]$OpenWeb_Command  = {
  param($sender)
  try{
    $Media = $_.OriginalSource.DataContext
    #write-ezlogs "Media $($Media | out-string)"
    if(!$Media.url){$Media = $sender.tag}
    if(!$Media.url){$Media = $sender.tag.Media}  
    if($Media.Source -eq 'YoutubePlaylist_item'){
      if(Test-URL $Media.url){
        if($Media.url -match 'youtube.com' -or $Media.url -match 'youtu.be'){
          if($Media.url -match "v="){
            $youtube_id = ($($Media.url) -split('v='))[1].trim()
            if($thisApp.Config.Use_invidious){
              $url = "https://yewtu.be/embed/$youtube_id`?&autoplay=1"
            }else{
              $url = "https://www.youtube.com/embed/$youtube_id`?&autoplay=1"
            }
          }elseif($Media.url -match 'list='){
            $playlist_id = ($($Media.url) -split('list='))[1].trim()
            if($thisApp.Config.Use_invidious){            
              $url = "https://yewtu.be/embed/videoseries?list=$playlist_id`&autoplay=1"       
            }else{
              $url = "https://www.youtube.com/embed/videoseries?list=$youtube_id`&autoplay=1"
            }                   
          }else{
            $url = $Media.url
          }        
        }else{
          $url = $Media.url
        }
        write-ezlogs "Opening URL $($url)" -showtime
        start $url
      }else{
        write-ezlogs "URL $($url) is invalid!" -showtime -warning
      }
    }
  }catch{
    write-ezlogs "An exception occurred in OpenWeb command - URL: $url" -showtime -catcherror $_
  }
   
} 

[System.Windows.RoutedEventHandler]$OpenFolder_Command  = {
  param($sender)
  $Media = $_.OriginalSource.DataContext
  #write-ezlogs "Media $($Media | out-string)"
  if(!$Media.url){$Media = $sender.tag}
  if(!$Media.url){$Media = $sender.tag.Media} 
  $Path = $media.directory
  if($thisApp.Config.Verbose_logging){write-ezlogs "Opening Directory path $($path)" -showtime} 
  if([System.IO.Directory]::Exists($path)){
    start $path
  }elseif([System.IO.Directory]::Exists([regex]::unescape($path))){
    start $([regex]::unescape($path))
  }elseif([System.IO.Directory]::Exists([regex]::escape($path))){
    start $([regex]::escape($path))
  }else{
    write-ezlogs "Directory Path $($path) is invalid!" -showtime -warning  
    Update-Notifications  -Level 'WARNING' -Message "Unable to find path $($path) to open!" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
  }   
} 

[System.Windows.RoutedEventHandler]$Clear_Playlist  = {
  param($sender)
  $Media = $_.OriginalSource.DataContext
  write-ezlogs '>>>> Clearing Current Play Queue' -showtime -color cyan
  try{$thisapp.config.Current_Playlist.Clear()}catch{write-ezlogs 'An exception occurred clearing the play queue' -showtime -warning}    
  $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
  Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -thisApp $thisapp 
}

$synchash.YoutubeMedia_ToRemove = ''
$synchash.Youtuberemove_item_timer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.Youtuberemove_item_timer.add_Tick({
    try{
      $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView((($synchash.Youtube_FilterView_Groups.GetEnumerator() | select *).Value | Sort-Object -Property {$_.Playlist},{$_.Track_Name}))  
      foreach($YoutubeMedia in $synchash.YoutubeMedia_ToRemove){
        $localmedia_toremove = $view | where {$_.id -eq $YoutubeMedia}
        if($localmedia_toremove){
          write-ezlogs "Removing $($localmedia_toremove.id) from Youtube view groups" -showtime
          $view = $view | where {$_.id -ne $YoutubeMedia}
          $datarow_toremove = $Youtube_Datatable.datatable | where {$_.id -eq $YoutubeMedia}
          if($datarow_toremove){
            write-ezlogs "| Removing $($datarow_toremove.id) from YoutubeMedia Datatable" -showtime
            $null = $Youtube_Datatable.datatable.Rows.remove($datarow_toremove)
          }
          #$null = $view.remove($localmedia_toremove)
          if($thisapp.Config.YoutubeBrowser_Paging -ne $null){
            $approxGroupSize = (($view).count | Measure-Object -Sum).Sum / $thisapp.Config.YoutubeBrowser_Paging     
            $approxGroupSize = [math]::ceiling($approxGroupSize)
            # create number of groups requested
            $groupMembers = @{}
            $groupSizes = @{}
            for ($i = 1; $i -le ($approxGroupSize); $i++) {
              $groupMembers.$i = [Collections.Generic.List[Object]]@()
              $groupSizes.$i = 0
            }
            foreach ($item in $view) {
              $mostEmpty = (($groupSizes.GetEnumerator() | Sort-Object -Property 'Name' | where {$_.value -lt $thisapp.Config.YoutubeBrowser_Paging}) | Select-Object -First 1).name
              if($groupMembers.$mostEmpty -notcontains $item){
                $null = $groupMembers.$mostEmpty.Add($item)
                $groupSizes.$mostEmpty += @($item).count
              }
            }                          
            if(@($view).count -gt 1){
              $itemsource = ($groupMembers.GetEnumerator() | select * | select -last 1).Value | Sort-Object -Property {$_.Playlist},{$_.Track_Name}
              $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)
            }              
            if(($view.psobject.properties.name | where {$_ -eq 'GroupDescriptions'}) -and $synchash.Youtube_GroupName){         
              $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $groupdescription.PropertyName = $synchash.Youtube_GroupName
              $view.GroupDescriptions.Clear()
              $null = $view.GroupDescriptions.Add($groupdescription)
              if($Sub_GroupName){
                $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
                $sub_groupdescription.PropertyName = $Sub_GroupName
                $null = $view.GroupDescriptions.Add($sub_groupdescription)
              }
            }elseif($view -and $view.GroupDescriptions){$view.GroupDescriptions.Clear()}
            $synchash.YoutubeTable.ItemsSource = $view                      
            #write-ezlogs "members $($view | out-string)" 
            $synchash.Youtube_View_Groups = $groupMembers.GetEnumerator() | select *
            $synchash.Youtube_TotalView_Groups = @($groupMembers.GetEnumerator() | select *).count
            $synchash.Youtube_CurrentView_Group = ($groupMembers.GetEnumerator() | select * | select -last 1).Name         
          }else{  
            $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($Youtube_Datatable.datatable) 
            $synchash.YoutubeTable.ItemsSource = $view
          } 
          $AllYoutube_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Youtube_MediaProfile','All-Youtube_Media-Profile.xml')    
          if([System.IO.File]::Exists($AllYoutube_Profile_File_Path)){
            $all_youtube_profile = Import-Clixml $AllYoutube_Profile_File_Path                  
            if($all_youtube_profile){
              foreach($Playlist in $all_youtube_profile){
                $Track_To_Remove = $Playlist.playlist_tracks | where {$_.id -eq $YoutubeMedia}
                if($Track_To_Remove){
                  write-ezlogs " | Removing track $($Track_To_Remove.title) with id $($Track_To_Remove.id) from playlist $($Playlist.name)" -showtime
                  Add-Member -InputObject $Playlist -Name 'playlist_tracks' -Value $($Playlist.playlist_tracks | where {$_.id -ne $Track_To_Remove.id}) -MemberType NoteProperty -Force  
                }
              }
              write-ezlogs "Updating All LocalYoutube profile cache at $AllYoutube_Profile_File_Path" -showtime       
              $all_youtube_profile | Export-Clixml $AllYoutube_Profile_File_Path -Force          
            } 
          }                   
          $synchash.Youtube_Table_Total_Media.content = "$(@($synchash.YoutubeTable.ItemsSource).count) of $(@(($synchash.Youtube_View_Groups | select *).value).count) | Total $(@($Youtube_Datatable.datatable).count)"
          $synchash.Youtube_lblpageInformation.content = "$($synchash.Youtube_CurrentView_Group) of $($synchash.Youtube_TotalView_Groups)"
        }     
      } 
      $synchash.YoutubeMedia_ToRemove = ''       
      $this.Stop()
    }catch{
      write-ezlogs "An exception occurred in Youtuberemove_item_timer" -showtime -catcherror $_
      $synchash.YoutubeMedia_ToRemove = ''
      $this.Stop()
    }
})

$synchash.LocalMedia_ToRemove = ''
$synchash.LocalMediaremove_item_timer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.LocalMediaremove_item_timer.add_Tick({
    try{
      if(!$hashsetup.Remove_LocalMedia_Sources -and !$hashsetup.LocalMedia_ViewUpdate){
        $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView((($synchash.LocalMedia_FilterView_Groups.GetEnumerator() | select *).Value | Sort-Object -Property {$_.Artist},{[int]$_.Track}))     
        if($synchash.LocalMedia_ToRemove.id){
          $list = $synchash.LocalMedia_ToRemove.id
        }else{
          $list = $synchash.LocalMedia_ToRemove
        } 
        foreach($localMedia in $list | where {$_}){
          $localmedia_toremove = $view | where {$_.id -eq $localMedia}
          if(!$localmedia_toremove){
            $localmedia_toremove = $Datatable.datatable | where {$_.id -eq $localMedia}
          }
          if($localmedia_toremove){
            write-ezlogs "Removing $($localmedia_toremove.id) from LocalMedia view groups" -showtime
            $view = $view | where {$_ -and $_.id -ne $localMedia}
            $datarow_toremove = $Datatable.datatable | where {$_.id -eq $localMedia}
            if($datarow_toremove){
              write-ezlogs "| Removing $($datarow_toremove.id) from LocalMedia Datatable" -showtime
              $null = $Datatable.datatable.Rows.remove($datarow_toremove)
            }
            $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-MediaProfile','All-Media-Profile.xml')   
            if([System.IO.File]::Exists($AllMedia_Profile_File_Path)){
              write-ezlogs "Updating All LocalMedia profile cache at $AllMedia_Profile_File_Path" -showtime 
              $all_media_profile = Import-Clixml $AllMedia_Profile_File_Path
              $tracks_to_remove = $all_media_profile | where {$_.id -eq $localMedia}
              if($tracks_to_remove){
                write-ezlogs " | Removing track $($tracks_to_remove.Name) from playlists and profiles" -showtime
                $all_media_profile = $all_media_profile | where {$_.id -ne $tracks_to_remove.id} 
                $all_media_profile | Export-Clixml $AllMedia_Profile_File_Path -Force        
              } 
            }                   
          }else{
            write-ezlogs "Unable to find Media with ID $($localMedia) to remove from LocalMedia view groups!" -showtime -warning
          }
        }
      }else{
        $view = $hashsetup.LocalMedia_ViewUpdate        
      }
      if($thisapp.Config.MediaBrowser_Paging -ne $null){
        $approxGroupSize = (($view).count | Measure-Object -Sum).Sum / $thisapp.Config.MediaBrowser_Paging     
        $approxGroupSize = [math]::ceiling($approxGroupSize)
        # create number of groups requested
        $groupMembers = @{}
        $groupSizes = @{}
        for ($i = 1; $i -le ($approxGroupSize); $i++) {
          $groupMembers.$i = [Collections.Generic.List[Object]]@()
          $groupSizes.$i = 0
        }
        foreach ($item in $view) {
          $mostEmpty = (($groupSizes.GetEnumerator() | Sort-Object -Property 'Name' | where {$_.value -lt $thisapp.Config.MediaBrowser_Paging}) | Select-Object -First 1).name
          if($groupMembers.$mostEmpty -notcontains $item){
            $null = $groupMembers.$mostEmpty.Add($item)
            $groupSizes.$mostEmpty += @($item).count
          }
        }                          
        if(@($view).count -gt 1){
          $itemsource = ($groupMembers.GetEnumerator() | select * | select -last 1).Value | Sort-Object -Property {$_.Artist},{[int]$_.Track}
          $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)
        }              
        if(($view.psobject.properties.name | where {$_ -eq 'GroupDescriptions'}) -and $synchash.LocalMedia_GroupName){         
          $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
          $groupdescription.PropertyName = $synchash.LocalMedia_GroupName
          $view.GroupDescriptions.Clear()
          $null = $view.GroupDescriptions.Add($groupdescription)
          if($Sub_GroupName){
            $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
            $sub_groupdescription.PropertyName = $Sub_GroupName
            $null = $view.GroupDescriptions.Add($sub_groupdescription)
          }
        }elseif($view -and $view.GroupDescriptions){$view.GroupDescriptions.Clear()}
        $synchash.MediaTable.ItemsSource = $view                      
        #write-ezlogs "members $($view | out-string)" 
        $synchash.LocalMedia_View_Groups = $groupMembers.GetEnumerator() | select *
        $synchash.LocalMedia_TotalView_Groups = @($groupMembers.GetEnumerator() | select *).count
        $synchash.LocalMedia_CurrentView_Group = ($groupMembers.GetEnumerator() | select * | select -last 1).Name         
      }else{  
        $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($Datatable.datatable) 
        $synchash.MediaTable.ItemsSource = $view
      }
      $synchash.Media_Table_Total_Media.content = "$(@($synchash.MediaTable.ItemsSource).count) of $(@(($synchash.LocalMedia_View_Groups | select *).value).count) | Total $(@($Datatable.datatable).count)"
      $synchash.LocalMedia_lblpageInformation.content = "$($synchash.LocalMedia_CurrentView_Group) of $($synchash.LocalMedia_TotalView_Groups)"
      $synchash.LocalMedia_ToRemove = ''
      $synchash.LocalMedia_Progress_Ring.isActive = $false
      $synchash.LocalMedia_Progress_Label.Visibility = 'Hidden'
      $synchash.MediaTable.isEnabled = $false 
      $this.Stop()
    }catch{
      write-ezlogs "An exception occurred in LocalMediaremove_item_timer" -showtime -catcherror $_
      $synchash.LocalMedia_ToRemove = ''
      $this.Stop()
    }
}.GetNewClosure())

#Remove Spotify Media TODO: Put into function/module
$synchash.SpotifyMedia_ToRemove = ''
$synchash.Spotifyremove_item_timer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.Spotifyremove_item_timer.add_Tick({
    try{
      $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView((($synchash.Spotify_FilterView_Groups.GetEnumerator() | select *).Value | Sort-Object -Property {$_.Playlist},{[int]$_.Track_Number}))          
      foreach($SpotifyMedia in $synchash.SpotifyMedia_ToRemove){
        $Spotifymedia_toremove = $view | where {$_.id -eq $SpotifyMedia}
        if($Spotifymedia_toremove){
          write-ezlogs "Removing $($Spotifymedia_toremove.id) from Spotify view groups" -showtime
          $view = $view | where {$_.id -ne $SpotifyMedia}
          $datarow_toremove = $Spotify_Datatable.datatable | where {$_.id -eq $SpotifyMedia}
          if($datarow_toremove){
            write-ezlogs "| Removing $($datarow_toremove.id) from SpotifyMedia Datatable" -showtime
            $null = $Spotify_Datatable.datatable.Rows.remove($datarow_toremove)
          }
          #$null = $view.remove($localmedia_toremove)
          if($thisapp.Config.SpotifyBrowser_Paging -ne $null){
            $approxGroupSize = (($view).count | Measure-Object -Sum).Sum / $thisapp.Config.SpotifyBrowser_Paging     
            $approxGroupSize = [math]::ceiling($approxGroupSize)
            # create number of groups requested
            $groupMembers = @{}
            $groupSizes = @{}
            for ($i = 1; $i -le ($approxGroupSize); $i++) {
              $groupMembers.$i = [Collections.Generic.List[Object]]@()
              $groupSizes.$i = 0
            }
            foreach ($item in $view) {
              $mostEmpty = (($groupSizes.GetEnumerator() | Sort-Object -Property 'Name' | where {$_.value -lt $thisapp.Config.SpotifyBrowser_Paging}) | Select-Object -First 1).name
              if($groupMembers.$mostEmpty -notcontains $item){
                $null = $groupMembers.$mostEmpty.Add($item)
                $groupSizes.$mostEmpty += @($item).count
              }
            }                          
            if(@($view).count -gt 1){
              $itemsource = ($groupMembers.GetEnumerator() | select * | select -last 1).Value | Sort-Object -Property {$_.Playlist},{[int]$_.Track_Number}
              $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)
            }              
            if(($view.psobject.properties.name | where {$_ -eq 'GroupDescriptions'}) -and $synchash.Spotify_GroupName){         
              $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $groupdescription.PropertyName = $synchash.Spotify_GroupName
              $view.GroupDescriptions.Clear()
              $null = $view.GroupDescriptions.Add($groupdescription)
              if($Sub_GroupName){
                $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
                $sub_groupdescription.PropertyName = $Sub_GroupName
                $null = $view.GroupDescriptions.Add($sub_groupdescription)
              }
            }elseif($view -and $view.GroupDescriptions){$view.GroupDescriptions.Clear()}
            $synchash.SpotifyTable.ItemsSource = $view                      
            #write-ezlogs "members $($view | out-string)" 
            $synchash.Spotify_View_Groups = $groupMembers.GetEnumerator() | select *
            $synchash.Spotify_TotalView_Groups = @($groupMembers.GetEnumerator() | select *).count
            $synchash.Spotify_CurrentView_Group = ($groupMembers.GetEnumerator() | select * | select -last 1).Name         
          }else{  
            $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($Spotify_Datatable.datatable) 
            $synchash.SpotifyTable.ItemsSource = $view
          } 
          $AllSpotify_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Spotify_MediaProfile','All-Spotify_Media-Profile.xml')    
          if([System.IO.File]::Exists($AllSpotify_Profile_File_Path)){
            $all_Spotify_profile = Import-Clixml $AllSpotify_Profile_File_Path                  
            if($all_Spotify_profile){
              foreach($Playlist in $all_Spotify_profile){
                $Track_To_Remove = $Playlist.playlist_tracks | where {$_.id -eq $SpotifyMedia}
                if($Track_To_Remove){
                  write-ezlogs " | Removing track $($Track_To_Remove.name) with id $($Track_To_Remove.id) from playlist $($Playlist.name)" -showtime
                  Add-Member -InputObject $Playlist -Name 'playlist_tracks' -Value $($Playlist.playlist_tracks | where {$_.id -ne $Track_To_Remove.id}) -MemberType NoteProperty -Force  
                }
              }
              write-ezlogs "Updating All Spotify profile cache at $AllSpotify_Profile_File_Path" -showtime       
              $all_Spotify_profile | Export-Clixml $AllSpotify_Profile_File_Path -Force          
            } 
          }                   
          $synchash.Spotify_Table_Total_Media.content = "$(@($synchash.SpotifyTable.ItemsSource).count) of $(@(($synchash.Spotify_View_Groups | select *).value).count) | Total $(@($Spotify_Datatable.datatable).count)"
          $synchash.Spotify_lblpageInformation.content = "$($synchash.Spotify_CurrentView_Group) of $($synchash.Spotify_TotalView_Groups)"
        }
      }
      $synchash.SpotifyMedia_ToRemove = ''      
      $this.Stop()
    }catch{
      write-ezlogs "An exception occurred in Spotifyremove_item_timer" -showtime -catcherror $_
      $synchash.SpotifyMedia_ToRemove = ''
      $this.Stop()
    }
})
$synchash.LocalMedia_ToRemove = New-Object -TypeName 'System.Collections.ArrayList'
[System.Windows.RoutedEventHandler]$Remove_MediaCommand  = {
  param($sender)
  $Media_info = $_.OriginalSource.DataContext
  if(!$Media_info.url){$Media_info = $sender.tag}
  if(!$Media_info.url){$Media_info = $sender.tag.Media}  
  if($sender.tag.source.Name -eq 'YoutubeTable'){
    $playlist_items = $synchash.YoutubeTable.selecteditems
  }elseif($sender.tag.source.Name -eq 'SpotifyTable'){
    $playlist_items = $synchash.SpotifyTable.selecteditems
  }elseif($sender.tag.source.Name -eq 'MediaTable'){
    $playlist_items = $synchash.MediaTable.selecteditems
  }
  $Selected_Media = New-Object -TypeName 'System.Collections.ArrayList'  
  if(@($playlist_items).count -gt 1){  
    $playlist_items | foreach {$null = $Selected_Media.add($_)}
    $title = 'Remove Selected Media'
    $Message = "Are you sure you wish to remove the $(@($playlist_items).count) selected media?"
  }else{
    $null = $Selected_Media.add($Media_info)
    $title = "Remove Media $($Media_info.title)"
    $Message = "Are you sure you wish to remove $($Media_info.title)?"
  }
  try{
    $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
    $Button_Settings.AffirmativeButtonText = 'Yes'
    $Button_Settings.NegativeButtonText = 'No'  
    $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"$title","$Message This will remove the media from all playlists and browsers. It will NOT delete the media itself",$okandCancel,$Button_Settings)
    if($result -eq 'Affirmative'){
      $synchash.LocalMedia_ToRemove = New-Object -TypeName 'System.Collections.ArrayList'
      $synchash.SpotifyMedia_ToRemove = New-Object -TypeName 'System.Collections.ArrayList'
      $synchash.YoutubeMedia_ToRemove = New-Object -TypeName 'System.Collections.ArrayList'
      foreach($Media in $Selected_Media){
        $Media_id = $Media.id
        write-ezlogs "#### Removing Media $($Media.title) - $($Media.id) ####" -showtime -color cyan -linesbefore 1
        if($thisapp.config.Current_Playlist.values -contains $Media.id){
          write-ezlogs " | Removing $($Media.id) from Play Queue" -showtime
          $index_toremove = $thisapp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.id} | select * -ExpandProperty key
          $null = $thisapp.config.Current_Playlist.Remove($index_toremove)                  
        }
        $playlist_to_modify = $synchash.all_playlists | where {$_.playlist_tracks.id -eq $Media.id}
        if($playlist_to_modify){
          foreach($Playlist in $playlist_to_modify){
            $Track_To_Remove = $Playlist.playlist_tracks | where {$_.id -eq $Media_id}
            if($Track_To_Remove){
              write-ezlogs " | Removing track $($Media_id) from playlist $($Playlist.name)" -showtime
              $null = $playlist_to_modify.playlist_tracks.remove($Track_To_Remove)
              write-ezlogs ">>>> Saving Playlist profile to path $($Playlist.Playlist_Path)"
              $Playlist | Export-Clixml $Playlist.Playlist_Path -Force
            }
          }
          write-ezlogs ">>>> Saving all_playlists cache profile to path $($thisapp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml"       
          $synchash.all_playlists | Export-Clixml "$($thisapp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml" -Force -Encoding UTF8   
        }    
        if($Media.Source -eq 'Local'){         
          $Null = $synchash.LocalMedia_ToRemove.add($Media_id)
          #$synchash.LocalMedia_ToRemove = $Media_id  
          write-ezlogs "| Removing track $($Media_id) from Local Media Browser and all media profiles" -showtime                
        }      
        if($Media.Spotify_path -or $Media.Source -eq 'SpotifyPlaylist'){
          $Track_ID = $Media.Track_ID
          $synchash.SpotifyMedia_ToRemove.add($Media_id) 
          write-ezlogs "| Removing track $($Track_ID) from Spotify Media Browser and all media profiles" -showtime
                                   
        }         
        if($Media.Source -eq 'YoutubePlaylist_item'){         
          $synchash.YoutubeMedia_ToRemove.add($Media_id) 
          write-ezlogs "| Removing track $($Media_id) from Youtube Media Browser and all media profiles" -showtime                     
        }
      }
      if(@($synchash.LocalMedia_ToRemove).count -gt 0){
        $synchash.LocalMediaremove_item_timer.start() 
      } 
      if(@($synchash.SpotifyMedia_ToRemove).count -gt 0){
        $synchash.Spotifyremove_item_timer.start() 
      }
      if(@($synchash.YoutubeMedia_ToRemove).count -gt 0){
        $synchash.Youtuberemove_item_timer.start()  
      }                                    
      #$media_toremove = $synchash.SpotifyTable.Items | where {$_.encodedtitle -eq $Media.id}    
      #$media_toremove = $synchash.YoutubeTable.Items | where {$_.encodedtitle -eq $Media.id}     
      $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
      Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -thisApp $thisapp       
    }else{write-ezlogs "User declined to delete media $($Media.title)" -showtime -warning}        
  }catch{write-ezlogs "An exception occurred removing $($Media | Out-String)" -showtime -catcherror $_}    
}

[System.Windows.RoutedEventHandler]$VideoViewMouseEnter = {
  param($sender)
  try{

    #$synchash.childwindow = [MahApps.Metro.SimpleChildWindow.ChildWindow]::new()
    #$synchash.childwindow.Title="TestChild 1"
    #$synchash.childwindow.HorizontalContentAlignment="Stretch"
    #$synchash.childwindow.VerticalContentAlignment="Stretch"
    #$synchash.childwindow.OverlayBrush="Transparent"
    #$synchash.childwindow.Height="400"
    #$synchash.childwindow.Width="400"
    if($synchash.childwindow){
      # $synchash.childwindow.IsOpen = $true
    }

    #$synchash.Dialog_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new() 
    #$synchash.Dialog_Settings.OwnerCanCloseWithDialog = $true
    #$okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative
    #$synchash.progress_dialog = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMessageAsync($synchash.Window,'Applying Settings','Please wait while settings are applied...', $okandCancel,$synchash.Dialog_Settings)
    <#    if(!$synchash.CustomDialog.isVisible){
        [xml]$Xamlfullscreen_window = [System.IO.File]::ReadAllText("$($Current_folder)\\Views\\CustomDialog.xaml").replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml") 
        $Childreader = (New-Object System.Xml.XmlNodeReader $Xamlfullscreen_window)
        $DialogForm   = [Windows.Markup.XamlReader]::Load($Childreader) 
        $Xamlfullscreen_window.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {$synchash."$($_.Name)" = $DialogForm.FindName($_.Name)}
        $synchash.CustomDialog  = [MahApps.Metro.Controls.Dialogs.CustomDialog]::new($synchash.window)
        $synchash.CustomDialogWindow.MaxWidth = $synchash.VLC_Grid.ActualWidth
        $synchash.CustomDialog.HorizontalAlignment="Center"
        write-ezlogs $($synchash.CustomDialog.psobject.methods | where {$_ -match 'add_'} | out-string)

        [System.Windows.RoutedEventHandler]$Mouseleave = {
        param($sender)
        try{
        $synchash.CustomDialog.RequestCloseAsync()

        }
        catch{
        write-ezlogs "An exception occurred in mouseleave event" -showtime -catcherror $_
        }
        }
        $null = $synchash.CustomDialog.AddHandler([System.Windows.Controls.Button]::MouseLeaveEvent,$Mouseleave)
        $null = $synchash.CustomDialogWindow.AddHandler([System.Windows.Controls.Button]::MouseLeaveEvent,$Mouseleave)
        $null = $synchash.CustomDialog.AddChild($synchash.CustomDialogWindow)
        $settings             = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
        $settings.OwnerCanCloseWithDialog = $true
        #$settings.AnimateShow = $false
        #$settings.AnimateHide = $false
        $synchash.CustomDialog.Background = 'Transparent'
        $settings.ColorScheme = [MahApps.Metro.Controls.Dialogs.MetroDialogColorScheme]::Accented
        # dialog error                                               
        #$ok = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative 
        #$Button_Style = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
        #$synchash.CustomDialog.ShowDialogExternally()
        #$Button_Style.AffirmativeButtonText = "OK"
        [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowDialogExternally($synchash.CustomDialog,$synchash.window,$Null)
    }#>
    #$synchash.child01.isOpen = $true
    #[System.Threading.Tasks.Task]::Delay(5000)
    #[MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.window,  $synchash.CustomDialog, $settings)
    # write-ezlogs "$($dialogs | out-string)"
    if($synchash.VideoView_Flyout.Visibility = 'Visible'){
      if($synchash.Vlc.Isplaying){
        $synchash.VideoViewFlyout.IsOpen = $true  
        $synchash.VideoView_Play_Icon.Kind = 'PauseCircleOutline' 

      }elseif($synchash.VLC.state -match 'Paused'){
        $synchash.VideoViewFlyout.IsOpen = $true
        $synchash.VideoView_Play_Icon.Kind = 'PlayCircleOutline'
      }else{
        # $synchash.VideoView_Play_Icon.Kind = 'PauseCircleOutline'
      }
    }
  }catch{
    write-ezlogs "An exception occurred in VideoViewMouseEnter event" -showtime -catcherror $_
  }
}
[System.Windows.RoutedEventHandler]$synchash.VideoViewMouseLeftButtonDown_command = {
  $sender = $args[0]
  [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]
  #MouseLeftButtonDown
  try{
    if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and [System.Windows.Input.MouseButtonState]::Pressed -and $e.RoutedEvent.Name -eq 'MouseLeftButtonDown')
    {
      $Synchash.Timer.stop()
      $peer = [System.Windows.Automation.Peers.ButtonAutomationPeer]($syncHash.Pause_media)
      $invokeProv = $peer.GetPattern([System.Windows.Automation.Peers.PatternInterface]::Invoke)
      $invokeProv.Invoke()
    }
  }catch{
    write-ezlogs "An exception occurred in Window VideoViewMouseLeftButtonDown_command event" -showtime -catcherror $_
  }
}

[System.Windows.RoutedEventHandler]$VideoViewMouseLeave = {
  param($sender)
  try{
    #$synchash.progress_dialog.Wait(1)
    #$progress_dialog.ConfigureAwait($false)
    #$synchash.CustomDialog.RequestCloseAsync()
    #$synchash.progress_dialog.closeAsync()
    #[MahApps.Metro.Controls.Dialogs.DialogManager]:: HideMetroDialogAsync($synchash.Window,[MahApps.Metro.Controls.Dialogs.ProgressDialog],$synchash.Dialog_Settings)
    #$synchash.childwindow.isOpen = $false
    #$synchash.progress_dialog.dispose()
    if($synchash.VideoView_Flyout.Visibility = 'Visible'){
      $synchash.VideoViewFlyout.IsOpen = $false

    }

  }catch{
    write-ezlogs "An exception occurred in VideoViewMouseLeave event" -showtime -catcherror $_
  }   
}

#Expand Video Player Command
[System.Windows.RoutedEventHandler]$ExpandPlayer_Command  = {
  param($sender)
  try{   

    if($synchash.Expand_Player_Icon.Kind -eq 'ScreenFull'){
      $synchash.MediaLibrary_Flyout_History = $synchash.MediaLibrary_Flyout.isOpen
      $synchash.MediaLibrary_Flyout.isOpen = $false
      $synchash.MainGrid_Row3_History = $synchash.MainGrid_Row3.ActualHeight
      if($synchash.MediaLibrary_Viewer.isVisible){
        $synchash.MainGrid_Row3.Height="*"
        $synchash.MainGrid_Row3.MinHeight=$null
      }else{
        $synchash.MainGrid_Row3.Height="50"
        $synchash.MainGrid_Row3.MinHeight="50"
      }
      $synchash.PlayQueueFlyout_History = $synchash.PlayQueueFlyout.isOpen
      $synchash.PlayQueueFlyout.isOpen = $false
      $synchash.playlist_column.Width ="*"
      $synchash.Expand_Player_Icon.Kind = 'ScreenNormal'
      $synchash.VideoView_LargePlayer_Icon.Kind = 'ScreenNormal'
      Add-Member -InputObject $thisapp.config -Name 'VideoView_LargePlayer' -Value $true -MemberType NoteProperty -Force
      $synchash.Window.WindowState = 'Maximized'
    }else{
      if($synchash.FullScreen_Viewer.isVisible){
        $synchash.FullScreen_Viewer.close()
      }
      #$synchash.MainGrid_Row3.Height = $synchash.MainGrid_Row3_History
      #$synchash.MainGrid_Row3.Height="200*"
      if($synchash.PlayQueueFlyout_History){
        $synchash.PlayQueueFlyout.isOpen = $true
      }
      if($synchash.MediaLibrary_Flyout_History){
        $synchash.MediaLibrary_Flyout.isOpen = $true
      }
      $synchash.Expand_Player_Icon.Kind = 'ScreenFull'
      $synchash.VideoView_LargePlayer_Icon.Kind = 'ScreenFull'
      Add-Member -InputObject $thisapp.config -Name 'VideoView_LargePlayer' -Value $false -MemberType NoteProperty -Force
    }
  }catch{
    write-ezlogs "An exception occurred in ExpandPlayer_Command event" -showtime -catcherror $_
  }
}

#---------------------------------------------- 
#region Update_TrayMenu Timer
#----------------------------------------------
$synchash.Update_TrayMenu_timer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.Update_TrayMenu_timer.Add_Tick({
    try{
      $synchash.Main_Tool_Icon = Add-TrayMenu -synchash $synchash -thisApp $thisApp
      $this.Stop()
    }catch{
      write-ezlogs "An exception occurred in Update_TrayMenu_timer Tick event" -showtime -catcherror $_
      $this.Stop()
    }
})
#---------------------------------------------- 
#endregion Update_TrayMenu Timer
#----------------------------------------------

#---------------------------------------------- 
#region update_status_timer Timer
#----------------------------------------------
$synchash.update_status_timer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.Import_Playlists_Cache = $true
$synchash.update_status_timer.Add_Tick({
    try{       
      #write-ezlogs ">>>> Calling function $($((Get-PSCallStack)[0].FunctionName))" -showtime   
      Get-PlayQueue -verboselog:$false -synchash $synchash -thisApp $thisapp                                   
      #Get-Playlists -verboselog:$thisApp.Config.Verbose_Logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -PlayMedia_Command $synchash.PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $synchash.PlaySpotify_Media_Command -Import_Playlists_Cache:$synchash.Import_Playlists_Cache
      $synchash.Import_Playlists_Cache = $true                                 
    }catch{
      write-ezlogs 'An exception occurred executing update_status_timer' -showtime -catcherror $_
      $this.Stop()
    }
    $this.Stop()     
}.GetNewClosure())
#---------------------------------------------- 
#region update_status_timer Timer
#----------------------------------------------

[System.Windows.RoutedEventHandler]$CheckTwitch_Command  = {
  param($sender)
  $datacontext = $_.OriginalSource.DataContext
  $synchash = $sender.tag.synchash
  $thisapp = $sender.tag.thisApp
  $Media = $_.OriginalSource.DataContext
  $PlayMedia_Command = $synchash.PlayMedia_Command
  $PlaySpotify_Media_Command = $synchash.PlaySpotify_Media_Command
  if(!$Media.url){$Media = $sender.tag}
  if(!$Media.url){$Media = $sender.tag.Media} 
  if($Media.webpage_url -match 'twitch.tv'){
    Get-TwitchStatus -thisApp $thisApp -synchash $Synchash -verboselog:$thisApp.Config.Verbose_logging -checkall -Use_runspace
  }else{
    write-ezlogs 'No valid Twitch URL was provided' -showtime -warning
  }
}

[System.Windows.RoutedEventHandler]$EditProfile_Command  = {
  param($sender)
  $datacontext = $_.OriginalSource.DataContext
  $synchash = $sender.tag.synchash
  $thisapp = $sender.tag.thisApp
  $Media = $_.OriginalSource.DataContext
  $PlayMedia_Command = $synchash.PlayMedia_Command
  $PlaySpotify_Media_Command = $synchash.PlaySpotify_Media_Command
  if(!$Media.url){$Media = $sender.tag}
  if(!$Media.url){$Media = $sender.tag.Media} 
  write-ezlogs "[EditProfile_Command] Media to Edit: $($media | out-string)"
  #write-ezlogs "[EditProfile_Command] DataContext: $($_.OriginalSource.DataContext | out-string)"
  if($Media.id -and $media.Profile_Path){
    try{    
      #$synchash.Window.hide()
      Show-ProfileEditor -synchash $synchash -thisApp $thisApp -thisScript $thisScript -PageTitle "Edit Profile for $($Media.title)" -Media_to_edit $media -logo "$($thisapp.Config.Current_Folder)\\Resources\\MusicPlayerFilltest.ico"
      #$synchash.Window.show()
    }catch{
      write-ezlogs "An exception occurred in EditProfile_Command routed event" -showtime -catcherror $_
    }
  }else{
    write-ezlogs 'No valid Media was provided' -showtime -warning
  }
}

[System.Windows.RoutedEventHandler]$Synchash.FindYoutube_Command  = {
  param($sender)
  $datacontext = $_.OriginalSource.DataContext
  $Media = $_.OriginalSource.DataContext
  if(!$Media.url -and !$Media.uri){$Media = $sender.tag}
  if(!$Media.url -and !$Media.uri){$Media = $sender.tag.Media} 
  write-ezlogs "[FindYoutube_Command] Media to find on Youtube: $($media | out-string)"
  if($Media.id -and ($media.title -or $media.name)){
    try{    
      if(!$media.title){
        $query = $media.name
      }else{
        $query = $media.title
      }
      $synchash.MainGrid_Top_TabControl.SelectedIndex = 1
      $url = "https://www.youtube.com/results?search_query=$([System.Web.HttpUtility]::UrlEncode($query))"
      $synchash.WebBrowser_url = $url
      Start-WebNavigation -uri $url -synchash $synchash -WebView2 $synchash.WebBrowser -thisScript $thisScript -thisApp $thisApp 

      #Find-YouTubeVideo -synchash $synchash -thisApp $thisApp
    }catch{
      write-ezlogs "An exception occurred in FindYoutube_Command routed event" -showtime -catcherror $_
    }
  }else{
    write-ezlogs 'No valid Media was provided or found' -showtime -warning
  }
}


[System.Windows.RoutedEventHandler]$Media_ContextMenu = {
  $sender = $args[0]
  [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]  
  $Media = $e.OriginalSource.datacontext

  if(!$Media.url){$Media = $sender.tag.Media} 
  if(!$Media.url){$Media = $e.OriginalSource.datacontext.tag.Media}

  #$synchash = $using:synchash
  #$thisapp = $using:thisApp
  #$thisScript = $using:thisScript  
  #$PlayMedia_Command = $sender.tag.PlayMedia_Command 
  #$PlaySpotify_Media_Command = $sender.tag.PlaySpotify_Media_Command
  $Media_Tag = @{        
    synchash = $synchash;
    thisScript = $thisScript;
    thisApp = $thisapp
    PlayMedia_Command = $synchash.PlayMedia_Command
    Media = $Media
    Datacontext = $e.OriginalSource.datacontext
    source = $e.Source
    Media_ContextMenu = $synchash.Media_ContextMenu
  }        
 
  $items = New-Object System.Collections.ArrayList 
  #write-ezlogs "Media $($media | out-string)"
  #write-ezlogs "tag $($e.OriginalSource.datacontext.tag | out-string)"
  #write-ezlogs "Datacontext $($e.Source | out-string)"
  try{
    if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Right -and ($Media.ID -or $Media.encodedtitle))
    {            
      #if($e.Source.Name -ne 'YoutubeTable' -and $e.Source.Name -ne 'SpotifyTable' -and $e.Source.Name -ne 'MediaTable' -and $e.Source.Name -ne 'PlayQueue_TreeView'){$sender.isSelected = $true}   

      if($e.Source.Name -eq 'Playlists_TreeView'){$sender.isSelected = $true}  
      $Play_Media = @{
        'Header' = 'Play'
        'Color' = 'White'
        'Icon_Color' = 'White'
        'Tag' = $Media_Tag
        'Command' = $synchash.PlayMedia_Command
        'Icon_kind' = 'Play'
        'Enabled' = $true
        'IsCheckable' = $false
      }
      $null = $items.Add($Play_Media)  
      if(($e.Source.Name -eq 'YoutubeTable' -or $Media.type -match 'Youtube') -and ($media.Group -notmatch 'Twitch' -and $media.playlist -notmatch 'Twitch')){
        $Download_Media = @{
          'Header' = 'Download'
          'Color' = 'White'
          'Icon_Color' = 'White'
          'Tag' = $Media_Tag
          'Command' = $DownloadMedia_Command
          'Icon_kind' = 'Download'
          'Enabled' = $true
          'IsCheckable' = $false
        }
        $null = $items.Add($Download_Media)     
      }
      if(($e.Source.Name -ne 'YoutubeTable' -and $Media.type -notmatch 'Youtube') -and ($media.url -notmatch 'Youtube.com' -and $media.web_url -notmatch 'youtube.com')){
        $Find_on_Youtube = @{
          'Header' = 'Find on Youtube'
          'Color' = 'White'
          'Icon_Color' = '#FFFF3737'
          'Tag' = $Media_Tag
          'Command' = $Synchash.FindYoutube_Command
          'Icon_kind' = 'Youtube'
          'Enabled' = $true
          'IsCheckable' = $false
        }
        $null = $items.Add($Find_on_Youtube)     
      }
      if((Test-URL $Media.webpage_url) -or (Test-URL $Media.url) -or (Test-URL $Media.uri)){
        $Open_Web = @{
          'Header' = 'Open in Web Browser'
          'Color' = 'White'
          'Icon_Color' = 'White'
          'Tag' = $Media_Tag
          'Command' = $OpenWeb_Command
          'Icon_kind' = 'Web'
          'Enabled' = $true
          'IsCheckable' = $false
        }
        $null = $items.Add($Open_Web) 
      }
      if($Media.webpage_url -match 'twitch.tv'){
        $CheckTwitch_Media = @{
          'Header' = 'Refresh Status'
          'Color' = 'White'
          'Icon_Color' = '#FFDA70D6'
          'Tag' = $Media_Tag
          'Command' = $CheckTwitch_Command
          'Icon_kind' = 'Broadcast'
          'Enabled' = $true
          'IsCheckable' = $false
        }
        $null = $items.Add($CheckTwitch_Media)     
      } 
      if($e.Source.Name -eq 'MediaTable' -or $Media.Directory){
        $Open_MediaLocation = @{
          'Header' = 'Open File Location'
          'Color' = 'White'
          'Icon_Color' = 'Orange'
          'Tag' = $Media_Tag
          'Command' = $OpenFolder_Command
          'Icon_kind' = 'FolderOpen'
          'Enabled' = $true
          'IsCheckable' = $false
        }
        $null = $items.Add($Open_MediaLocation)    
      } 
    
      $Edit_Profile = @{
        'Header' = 'Edit Media Properties'
        'Color' = 'White'
        'Icon_Color' = 'White'
        'Tag' = $Media_Tag
        'Command' = $EditProfile_Command 
        'Icon_kind' = 'FileDocumentEditOutline'
        'Enabled' = $true
        'IsCheckable' = $false
      }
      $null = $items.Add($Edit_Profile)   
     
      $Sub_items = New-Object System.Collections.ArrayList
      $Current_Playlist_Add = @{
        'Header' = 'Play Queue'
        'Tag' = $Media_Tag
        'Command' = $synchash.Add_to_PlaylistCommand
        'Enabled' = $true
        'IsCheckable' = $false
        'Icon_kind' = $null
        'Color' = 'White'
      }
      $null = $Sub_items.Add($Current_Playlist_Add)
      $synchash.all_playlists = Import-Clixml "$($thisapp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml"
      foreach ($Playlist in $synchash.all_playlists | where {-not [string]::IsNullOrEmpty($_.name) -and $_.Playlist_tracks.id -notcontains $Media.ID })
      {
        $Playlist_name = $Playlist.name
        $Playlist_tracks = $Playlist.Playlist_tracks
        $Custom_Playlist_Add = @{
          'Header' = $Playlist_name
          'Tag' = $Media_Tag
          'Command' = $synchash.Add_to_PlaylistCommand
          'Enabled' = $true
          'IsCheckable' = $false
          'Icon_kind' = $null
          'Color' = 'White'
        }
        $null = $Sub_items.Add($Custom_Playlist_Add)      
      }     
      $separator = @{
        'Separator' = $true
        'Style' = 'SeparatorGradient'
      }            
      $null = $Sub_items.Add($separator)     
      $Add_New_Playlist = @{
        'Header' = 'Add to New Playlist..'
        'Tag' = $Media_Tag
        'Command' = $synchash.Add_to_New_PlaylistCommand
        'Enabled' = $true
        'IsCheckable' = $false
        'Icon_Color' = 'LightGreen'
        'Icon_kind' = 'PlaylistPlus'
        'Icon_Margin' = '3,0,0,0'
        'Color' = 'White'
      }
      $null = $Sub_items.Add($Add_New_Playlist)  
      <#      $Add_Selected_New_Playlist = @{
          'Header' = 'Add all Selected to New Playlist'
          'Tag' = $Media_Tag
          'Command' = $synchash.Add_to_New_PlaylistCommand
          'Enabled' = $true
          'IsCheckable' = $false
          'Icon_Color' = 'LightGreen'
          'Icon_kind' = 'PlaylistPlus'
          'Icon_Margin' = '3,0,0,0'
          'Color' = 'White'
          }
      $null = $Sub_items.Add($Add_Selected_New_Playlist)#>         
      $Add_to_Playlist = @{
        'Header' = 'Add to Playlist'
        'Color' = 'White'
        'Icon_Color' = 'LightGreen'
        'Icon_kind' = 'PlaylistPlus'
        'Enabled' = $true
        'Icon_Margin' = '3,0,0,0' 
        'Sub_items' = $Sub_items
      }
      $null = $items.Add($Add_to_Playlist)        
      #Remove from Playlist
      $Remove_Sub_items = New-Object System.Collections.ArrayList
      $Current_Playlist_Remove = @{
        'Header' = 'Play Queue'
        'Tag' = $Media_Tag
        'Command' = $Remove_from_PlaylistCommand
        'Enabled' = $true
        'IsCheckable' = $false
        'Icon_kind' = $null
        'Color' = 'White'
      }
      $null = $Remove_Sub_items.Add($Current_Playlist_Remove) 
      if($synchash.all_playlists.Playlist_tracks.id -contains $Media.ID){
        foreach ($Playlist in $synchash.all_playlists | where {-not [string]::IsNullOrEmpty($_.name) -and $_.Playlist_tracks.id -contains $Media.ID })
        {
          $Playlist_name = $Playlist.name
          $Playlist_tracks = $Playlist.Playlist_tracks
          $Custom_Playlist_Remove = @{
            'Header' = $Playlist_name
            'Tag' = $Media_Tag
            'Command' = $Remove_from_PlaylistCommand
            'Enabled' = $true
            'IsCheckable' = $false
            'Icon_kind' = $null
            'Color' = 'White'
          }
          $null = $Remove_Sub_items.Add($Custom_Playlist_Remove)      
        }
      }
      $separator = @{
        'Separator' = $true
        'Style' = 'SeparatorGradient'
      }            
      $null = $items.Add($separator)            
      $Remove_From_Playlist = @{
        'Header' = 'Remove From Playlist'
        'Color' = 'White'
        'Icon_Color' = 'Tomato'
        'Icon_kind' = 'PlaylistMinus'
        'Enabled' = $true
        'Icon_Margin' = '3,0,0,0' 
        'Sub_items' = $Remove_Sub_items
      }
      $null = $items.Add($Remove_From_Playlist)  
      $Remove_Media = @{
        'Header' = 'Remove from App'
        'Color' = 'White'
        'IconPack' = 'PackIconForkAwesome'
        'Icon_Color' = 'White'
        'Icon_kind' = 'Trash'
        'Tag' = $Media_Tag
        'Command' = $Remove_MediaCommand
        'Enabled' = $true
        'Icon_Margin' = '3,0,0,0' 
      }
      $null = $items.Add($Remove_Media)                           
    }elseif($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Right -and -not [string]::IsNullOrEmpty($e.OriginalSource.datacontext) -and ($e.OriginalSource.GetType()).Name  -match 'Textblock' -and $e.Source.Name -ne 'PlayQueue_TreeView' -and (-not [string]::IsNullOrEmpty($e.OriginalSource.datacontext.title))){
      #if($e.Source.Name -ne 'YoutubeTable' -and $e.Source.Name -ne 'SpotifyTable' -and $e.Source.Name -ne 'MediaTable'){$sender.isSelected = $true}
      $Playlist_PlayAll = @{
        'Header' = 'Play All'
        'FontWeight' = 'Bold'
        'Color' = 'White'
        'Icon_Color' = 'White'
        'Tag' = $Media_Tag
        'Command' = $synchash.Add_to_PlaylistCommand
        'Icon_kind' = 'AnimationPlayOutline'
        'Enabled' = $true
        'IsCheckable' = $false
      }
      $null = $items.Add($Playlist_PlayAll)    
      $Playlist_toQueue = @{
        'Header' = 'Add Playlist to Play Queue'
        'Color' = 'White'
        'Icon_Color' = 'LightGreen'
        'Tag' = $Media_Tag
        'Command' = $synchash.Add_to_PlaylistCommand
        'Icon_kind' = 'PlaylistPlus'
        'Enabled' = $true
        'IsCheckable' = $false
      }
      $null = $items.Add($Playlist_toQueue)    
      $Playlist_Save = @{
        'Header' = 'Save as New Playlist'
        'Color' = 'White'
        'Icon_Color' = 'Yellow'
        'Tag' = $Media_Tag
        'Command' = $synchash.Add_to_New_PlaylistCommand
        'Icon_kind' = 'PlaylistStar'
        'Enabled' = $true
        'IsCheckable' = $false
      }
      $null = $items.Add($Playlist_Save)  
      if($e.Source.Name -ne 'YoutubeTable' -and $e.Source.Name -ne 'SpotifyTable' -and $e.Source.Name -ne 'MediaTable'){
        $separator = @{
          'Separator' = $true
          'Style' = 'SeparatorGradient'
        }            
        $null = $items.Add($separator)     
        $Playlist_Delete = @{
          'Header' = 'Delete Playlist'
          'Color' = 'White'
          'Icon_Color' = 'Tomato'
          'Tag' = $Media_Tag
          'Command' = $DeletePlaylist_Command
          'Icon_kind' = 'PlaylistRemove'
          'Enabled' = $true
          'IsCheckable' = $false
        }
        $null = $items.Add($Playlist_Delete) 
      }    
    }elseif($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Right -and $e.Source.Name -eq 'PlayQueue_TreeView'){
      #if($e.Source.Name -ne 'YoutubeTable' -and $e.Source.Name -ne 'SpotifyTable' -and $e.Source.Name -ne 'MediaTable'){$sender.isSelected = $true}
      $Playlist_Save = @{
        'Header' = 'Create Playlist from Queue'
        'Color' = 'White'
        'Icon_Color' = 'LightGreen'
        'Tag' = $Media_Tag
        'Command' = $synchash.Add_to_New_PlaylistCommand
        'Icon_kind' = 'PlaylistPlus'
        'Enabled' = $true
        'IsCheckable' = $false
      }
      $null = $items.Add($Playlist_Save)
      $Playlist_Clear = @{
        'Header' = 'Clear Queue'
        'Color' = 'White'
        'Icon_Color' = 'Gray'
        'Tag' = $Media_Tag
        'Command' = $Clear_Playlist
        'Icon_kind' = 'PlaylistMinus'
        'Enabled' = $true
        'IsCheckable' = $false
      }
      $null = $items.Add($Playlist_Clear)         
    }
    if($items){ 
      $e.OriginalSource.tag = $Media_Tag      
      Add-WPFMenu -control $e.OriginalSource -items $items -AddContextMenu -synchash $synchash
    }      
  }catch{
    write-ezlogs "An exception occurred creating contextmenu for $($e.Source.Name)" -showtime -catcherror $_
  }         
}.GetNewClosure()    
$synchash.Media_ContextMenu = $Media_ContextMenu

$get_playlists_Measure = measure-command{
  Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -startup -thisApp $thisapp -Import_Playlists_Cache
  Get-PlayQueue -verboselog:$false -synchash $synchash -thisApp $thisapp  
}
    
if($thisApp.Config.startup_perf_timer){$Get_Playlists_Perf =  "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Get-Playlists:         $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds`n[$(Get-date -format $logdateformat)]     | Get-Playlists Total: $($get_playlists_Measure.Seconds) seconds - $($get_playlists_Measure.Milliseconds) Milliseconds"}
$null = $synchash.MediaTable.AddHandler([System.Windows.Controls.Button]::MouseRightButtonDownEvent,$synchash.Media_ContextMenu)
$null = $synchash.PlayQueue_TreeView.AddHandler([System.Windows.Controls.Button]::MouseRightButtonDownEvent,$synchash.Media_ContextMenu)
$null = $synchash.MediaTable.AddHandler([System.Windows.Controls.Button]::MouseDoubleClickEvent,$synchash.PlayMedia_Command)
$null = $synchash.PlayQueue_TreeView.AddHandler([System.Windows.Controls.Button]::MouseDoubleClickEvent,$synchash.PlayMedia_Command)
$null = $synchash.PlayQueue_TreeView.AddHandler([System.Windows.Controls.DataGrid]::PreviewKeyDownEvent,$synchash.KeyDown_Command)
$null = $synchash.SpotifyTable.AddHandler([System.Windows.Controls.Button]::MouseDoubleClickEvent,$synchash.PlayMedia_Command)
$null = $synchash.SpotifyTable.AddHandler([System.Windows.Controls.Button]::MouseRightButtonDownEvent,$synchash.Media_ContextMenu)
$null = $synchash.YoutubeTable.AddHandler([System.Windows.Controls.Button]::MouseRightButtonDownEvent,$synchash.Media_ContextMenu)
$null = $synchash.YoutubeTable.AddHandler([System.Windows.Controls.Button]::MouseDoubleClickEvent,$synchash.PlayMedia_Command)

#---------------------------------------------- 
#endregion ContextMenu Routed Event Handlers
#----------------------------------------------

#---------------------------------------------- 
#region Initialize-ChatView Timer
#----------------------------------------------
$synchash.Initialize_ChatView_timer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.Initialize_ChatView_timer.add_tick({
    try{
      Initialize-ChatView -synchash $synchash -thisApp $thisApp
      $this.Stop()
    }catch{
      write-ezlogs "An exception occurred in Initialize_ChatView_timer" -showtime -catcherror $_
      $this.Stop()
    }  
})
#---------------------------------------------- 
#endregion Initialize-ChatView Timer
#----------------------------------------------

#---------------------------------------------- 
#region Initialize-WebPlayer Timer
#----------------------------------------------
$synchash.Initialize_WebPlayer_timer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.Initialize_WebPlayer_timer.add_tick({
    try{
      Initialize-WebPlayer -synchash $synchash -thisApp $thisApp -thisScript $thisScript
      $this.Stop()
    }catch{
      write-ezlogs "An exception occurred in Initialize_WebPlayer_timer" -showtime -catcherror $_
      $this.Stop()
    }  
})
#---------------------------------------------- 
#endregion Initialize-WebPlayer Timer
#----------------------------------------------

#---------------------------------------------- 
#region Initialize-WebBrowser Timer
#----------------------------------------------
$synchash.Initialize_WebBrowser_timer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.Initialize_WebBrowser_timer.add_tick({
    try{
      Initialize-WebBrowser -synchash $synchash -thisApp $thisApp -thisScript $thisScript
      $this.Stop()
    }catch{
      write-ezlogs "An exception occurred in Initialize_WebBrowser_timer" -showtime -catcherror $_
      $this.Stop()
    }  
})
#---------------------------------------------- 
#endregion Initialize-WebBrowser Timer
#----------------------------------------------

#---------------------------------------------- 
#region Webview2 Events
#----------------------------------------------
$Webview2_Measure = Measure-command {

  #$synchash.Initialize_WebPlayer_timer.start()
  $synchash.Initialize_WebBrowser_timer.start()
  #Initialize-WebPlayer -synchash $synchash -thisApp $thisApp -thisScript $thisScript
  #Initialize-WebBrowser -synchash $synchash -thisApp $thisApp -thisScript $thisScript
  #Initialize-ChatView -synchash $synchash -thisApp $thisApp
}
if($thisApp.Config.startup_perf_timer){$WebView2_Perf =  "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> WebView2:              $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds`n[$(Get-date -format $logdateformat)]     | WebView2 Total: $($WebView2_Measure.Seconds) seconds - $($WebView2_Measure.Milliseconds) Milliseconds"}
#---------------------------------------------- 
#endregion Webview2 Events
#----------------------------------------------

#----------------------------------------------
#region Initialize libvlc
#----------------------------------------------
$Initialize_VLC_Perf_Measure = measure-command {
  $Current_folder = $($thisScript.path | Split-Path -Parent)
  try{
    <#    $synchash.VLC = [meta.vlc.wpf.VlcPlayer]::new()
        $synchash.VLC.beginInit()
        $synchash.VLC.VlcLibDirectory = "$current_folder\Resources\Libvlc"
        $synchash.VLC.VlcMediaplayerOptions = '--file-logging',"--logfile=$($logfile_directory)\$($thisScript.Name)-$($thisScript.Version)-VLCtest.log","--log-verbose=3",":sout=#rtp{sdp=rtsp://127.0.0.1:5554/2}"
        $synchash.VLC.EndInit()
    $synchash.VLC_Grid.addchild($synchash.VLC)#>
    $vlc = [LibVLCSharp.Shared.Core]::Initialize("$Current_folder\Resources\Libvlc")
    #$videoView = [LibVLCSharp.WPF.VideoView]::new()  
    $libvlc = [LibVLCSharp.Shared.LibVLC]::new('--file-logging',"--logfile=$($logfile_directory)\$($thisScript.Name)-$($thisapp.config.App_Version)-VLC.log",'--log-verbose=3')
    #$libvlc.SetLogFile("$($logfile_directory)\$($thisScript.Name)-$($thisApp.config.App_Version)-VLC.log")
    $synchash.VideoView.MediaPlayer = [LibVLCSharp.Shared.MediaPlayer]::new($libvlc) 
    $synchash.VideoView.MediaPlayer.EnableMouseInput = $true 
    if($thisApp.Config.enable_Marquee){
      $synchash.VideoView.MediaPlayer.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Enable, 1) #enable marquee option
      $synchash.VideoView.MediaPlayer.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Size, 32) #set the font size 
      $synchash.VideoView.MediaPlayer.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Position, 8) #set the position of text
      $synchash.VideoView.MediaPlayer.SetMarqueeString([LibVLCSharp.Shared.VideoMarqueeOption]::Text, "EZT-MediaPlayer - $($thisScript.Version) - Pre-Alpha")
    }
    $synchash.VLC = $synchash.VideoView.MediaPlayer
    $synchash.libvlc = $libvlc
  }catch{
    write-ezlogs "An exception occurred initializing libvlc" -showtime -catcherror $_
  }

  #region------EQ And Audio Settings------
  $EQ_Initialize_measure = measure-command {
    try{
      #EQ Settings
      $EQ = [LibVLCSharp.Shared.Equalizer]::new()
      $bandcount = $EQ.BandCount
      $preset_Count = $EQ.PresetCount

      $eq_presets = 0..$preset_Count | foreach{
        if(-not [string]::IsNullOrEmpty($EQ.PresetName($_))){
          $newRow = New-Object PsObject -Property @{
            'Preset_Name' = $EQ.PresetName($_)
            'Preset_ID' = $_
          }
          if($synchash.EQ_Preset_ComboBox.items -notcontains $EQ.PresetName($_)){$null = $synchash.EQ_Preset_ComboBox.items.add($EQ.PresetName($_))}
          $newRow
        }
      }
      Add-Member -InputObject $thisapp.config -Name 'EQ_Presets' -Value $eq_presets -MemberType NoteProperty -Force
  
      #eq Bands
      $eq_bands = 0..$bandcount | foreach{
        $bandvalue = $null
        $band_id = $null
        if($EQ.BandFrequency($_) -ne -1){
          $band_id = $_    
          $Configured_Band = $thisapp.Config.EQ_Bands | where {$_.Band_ID -eq $band_id}
          if($Configured_Band.Band_Value  -ne $null){$bandvalue = $Configured_Band.Band_Value}else{$bandvalue = 0}
          $newRow = New-Object PsObject -Property @{
            'Band' = $EQ.BandFrequency($_)
            'Band_Name' = "EQ_$($_)"
            'Band_ID' = $_
            'Band_Value' = $bandvalue
          }
          $frequency_name = $null
          if($synchash."EQ_$($_)"){
            #write-ezlogs "Setting band frequency $($eq.BandFrequency($_))" -showtime
            if($($EQ.BandFrequency($_)  / 1000) -lt 1){$frequency_name = "$([math]::Round($EQ.BandFrequency($_),1))Hz"}else{$frequency_name = "$([math]::Round($EQ.BandFrequency($_)/1000,1))kHz"}
            $synchash."EQ_$($_)_Text".text = $frequency_name
            $synchash."EQ_$($_)".Add_ValueChanged({
                $Band_to_modify = $thisapp.config.EQ_Bands | where {$_.Band_Name -eq $this.Name}
                if($Band_to_modify){ 
                  try{
                    $Band_to_modify.Band_Value = $this.Value
                    if($synchash.Equalizer -ne $null){
                      $current_band_value = $synchash.Equalizer.Amp($Band_to_modify.Band_ID)
                      #write-ezlogs "Current band $($Band_to_Modify.Band_ID) Value: $($current_band_value)" -showtime
                      if($current_band_value -ne $this.Value){
                        $null = $synchash.Equalizer.SetAmp($this.Value,$Band_to_modify.Band_ID) 
                        if($thisapp.Config.EQ_Preamp -ne $null){$null = $synchash.Equalizer.SetPreamp($thisapp.Config.EQ_Preamp)}else{Add-Member -InputObject $thisapp.config -Name 'EQ_Preamp' -Value '' -MemberType NoteProperty -Force}                    
                        #write-ezlogs " | Set New value $($this.Value)" -showtime 
                        if($thisapp.config.Enable_EQ){$null = $synchash.vlc.SetEqualizer($synchash.Equalizer)}                     
                      }
                    }else{
                      $synchash.Equalizer = [LibVLCSharp.Shared.Equalizer]::new()
                      $synchash.Equalizer.SetAmp($this.Value,$Band_to_modify.Band_ID)
                      if($thisapp.Config.EQ_Preamp -ne $null){$null = $synchash.Equalizer.SetPreamp($thisapp.Config.EQ_Preamp)}else{Add-Member -InputObject $thisapp.config -Name 'EQ_Preamp' -Value 0 -MemberType NoteProperty -Force}                 
                      if($thisapp.config.Enable_EQ){$null = $synchash.vlc.SetEqualizer($synchash.Equalizer)}                  
                    }
                  }catch{
                    write-ezlogs "An exception occurred changing value in $($synchash."EQ_$($_)") to $($this.Value)" -showtime -catcherror $_
                  }
                }
            })
            if($Configured_Band.Band_Value -ne $null){$synchash."EQ_$($_)".Value = $Configured_Band.Band_Value}else{$synchash."EQ_$($_)".Value = 0}        
          }
          $newRow
        } 
      }
      Add-Member -InputObject $thisapp.config -Name 'EQ_Bands' -Value $eq_bands -MemberType NoteProperty -Force
      if($thisapp.config.Enable_EQ){
        $synchash.Enable_EQ_Toggle.isOn = $true
        if(!$synchash.Equalizer){
          $synchash.Equalizer = [LibVLCSharp.Shared.Equalizer]::new()
        }
      }else{
        $synchash.Enable_EQ_Toggle.isOn  = $false
      }
  
      $synchash.Enable_EQ_Toggle.Add_Toggled({
          try{
            if($synchash.Enable_EQ_Toggle.isOn -and $synchash.Equalizer -ne $null){
              $null = $synchash.vlc.SetEqualizer($synchash.Equalizer)
              write-ezlogs ">>>> EQ Enabled - Preamp: $($synchash.Equalizer.preamp)" -showtime
              Add-Member -InputObject $thisapp.config -Name 'Enable_EQ' -Value $true -MemberType NoteProperty -Force
            }else{
              $null = $synchash.vlc.UnsetEqualizer()
              write-ezlogs ">>>> EQ Disabled" -showtime
              Add-Member -InputObject $thisapp.config -Name 'Enable_EQ' -Value $false -MemberType NoteProperty -Force
            }      
          }catch{
            write-ezlogs "An exception occurred in Enable_EQ_Toggle toggled event" -showtime -catcherror $_
          }
      })
  
      #custom EQ presets
      if($thisapp.config.Custom_EQ_Presets.Preset_Name){
        foreach($preset in $thisapp.config.Custom_EQ_Presets){
          if($synchash.EQ_Preset_ComboBox.items -notcontains $preset.Preset_Name){$null = $synchash.EQ_Preset_ComboBox.items.add($preset.Preset_Name)}
        }
      }
      $synchash.Save_CustomEQ_Button.Add_Click({
          try{
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
            $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($synchash.Window,'Save Preset','Enter the name for the new preset',$Button_Settings)
            if(-not [string]::IsNullOrEmpty($result)){      
              write-ezlogs ">>>> Saving new Preset $result" -showtime -color cyan
              $current_EQ_Bands = $thisapp.Config.EQ_Bands        
              $preset = Add-EQPreset -PresetName $result -EQ_Bands $current_EQ_Bands -thisApp $thisapp -synchash $synchash -verboselog    
              if($preset.Preset_Name){
                if($synchash.EQ_Preset_ComboBox.items -notcontains $preset.Preset_Name){
                  $null = $synchash.EQ_Preset_ComboBox.items.add($preset.Preset_Name)
                  $synchash.EQ_Preset_ComboBox.Selecteditem = $preset.Preset_Name
                }else{
                  write-ezlogs "An existing preset with name $result already exists -- updated to current values" -showtime -warning
                }                                 
              }else{
                write-ezlogs 'Unable to add Preset as no preset profile was returned when adding!' -showtime -warning
              }          
            }else{
              write-ezlogs "The provided name is not valid or was not provided! -- $result" -showtime -warning
            }
          }catch{
            write-ezlogs 'An exception occurred in Save_CustomEQ_Button click event' -showtime -catcherror $_
          }
      })  


      #Preamp
      $synchash.Preamp_Slider.Add_ValueChanged({
          try{
            $thisapp.Config.EQ_Preamp = $this.value
            if($synchash.Equalizer -ne $null){
              $null = $synchash.Equalizer.SetPreamp($this.value)
              #write-ezlogs "Setting EQ Preamp to $($this.value)" -showtime
            }  
            if($thisapp.config.Enable_EQ){$null = $synchash.vlc.SetEqualizer($synchash.Equalizer)}      
          }catch{
            write-ezlogs "An exception occurred setting the EQ preamp to $($this.value)" -showtime -catcherror $_
          }
      })

      $synchash.EQ_Timer = New-Object System.Windows.Threading.DispatcherTimer 
      $synchash.EQ_Timer.Add_tick({
          try{
            if($thisapp.Config.Verbose_logging){write-ezlogs '[EQ_Timer] >>>> Updating EQ settings' -showtime}
            if($synchash.EQ_Preset_ComboBox.SelectedIndex -ne -1){
              $new_preset = ($thisapp.config.EQ_Presets | where {$_.preset_name -eq $synchash.EQ_Preset_ComboBox.SelectedItem})
              if(!$new_preset){$new_preset = ($thisapp.config.Custom_EQ_Presets | where {$_.preset_name -eq $synchash.EQ_Preset_ComboBox.SelectedItem})}
              Add-Member -InputObject $thisapp.config -Name 'EQ_Selected_Preset' -Value $synchash.EQ_Preset_ComboBox.SelectedItem -MemberType NoteProperty -Force
              if($new_preset.Preset_Path){        
                if([System.IO.File]::Exists($new_preset.Preset_Path)){
                  if($thisapp.Config.Verbose_logging){write-ezlogs ">>>> Getting custom EQ Preset profile: $($new_preset.Preset_Path)" -showtime -color cyan}
                  $preset = Import-Clixml $new_preset.Preset_Path 
                }
                if($preset.EQ_Bands){
                  if($thisapp.Config.EQ_Preamp -ne $null){
                    if(!$synchash.Equalizer){
                      $synchash.Equalizer = [LibVLCSharp.Shared.Equalizer]::new()
                    }            
                    $synchash.Equalizer.SetPreamp($thisapp.Config.EQ_Preamp)
                  }else{
                    Add-Member -InputObject $thisapp.config -Name 'EQ_Preamp' -Value 0 -MemberType NoteProperty -Force
                  }          
                  if($thisapp.Config.Verbose_logging){write-ezlogs " | Applying EQ Bands: $($preset.EQ_Bands)" -showtime}
                  foreach($band in $preset.EQ_Bands){
                    if($synchash."$($band.Band_Name)" -and $band.Band_value -ne $null){
                      if($thisapp.Config.Verbose_logging){write-ezlogs " | Applying Band Value $($band.Band_Value) to EQ_$($band.Band_ID)" -showtime}
                      $synchash."$($band.Band_Name)".Value = $band.Band_value
                    }                         
                  }
                }
              }
              elseif($new_preset.preset_id -ne $null){
                if($thisapp.Config.Verbose_logging){write-ezlogs ">>>> Setting Equalizer to preset $($new_preset.preset_name) - ID $($new_preset.preset_id)" -showtime -color cyan}
                try{
                  $synchash.Equalizer = [LibVLCSharp.Shared.Equalizer]::new($new_preset.preset_id)
                  if($thisapp.Config.EQ_Preamp -ne $null){$synchash.Equalizer.SetPreamp($thisapp.Config.EQ_Preamp)}else{Add-Member -InputObject $thisapp.config -Name 'EQ_Preamp' -Value 0 -MemberType NoteProperty -Force}            
                  if($thisapp.Config.Verbose_logging){write-ezlogs " | Preamp: $($synchash.Equalizer.preamp)" -showtime}
                  if($thisapp.config.Enable_EQ){$null = $synchash.vlc.SetEqualizer($synchash.Equalizer)}
                  foreach($band in $thisapp.config.EQ_Bands){
                    $band.Band_value = $synchash.Equalizer.Amp($band.Band_ID)
                    if($synchash."$($band.Band_Name)" -and $band.Band_value -ne $null){$synchash."$($band.Band_Name)".Value = $band.Band_value}
                  }
                }catch{
                  write-ezlogs "An exception occurred attempting to apply new Equalizer preset $($new_preset.preset_name) with id $($new_preset.preset_id)" -showtime -catcherror $_
                  $this.Stop()
                }
              }else{write-ezlogs "Unable to determine eq preset $($new_preset | Out-String)" -showtime -warning}        
            }else{
              Add-Member -InputObject $thisapp.config -Name 'EQ_Selected_Preset' -Value '' -MemberType NoteProperty -Force
              if($thisapp.Config.Verbose_logging){write-ezlogs '>>>> Resetting Equalizer to default 0 values' -showtime -color cyan}
              try{
                #$null = $synchash.vlc.SetEqualizer([LibVLCSharp.Shared.Equalizer]::new())          
                #$null = $synchash.vlc.UnsetEqualizer()        
                foreach($band in $thisapp.config.EQ_Bands){
                  if($synchash."$($band.Band_Name)"){$synchash."$($band.Band_Name)".Value = 0}
                }            
              }catch{
                write-ezlogs 'An exception occurred resetting Equalizer to default 0 values' -showtime -catcherror $_
                $this.Stop()
              }        
            }
            $synchash.Preamp_Slider.Value = $thisapp.Config.EQ_Preamp 
            $this.Stop()
          }catch{
            write-ezlogs "An exception occurred in EQ_Timer" -showtime -catcherror $_
            $this.Stop()
          }
      })

      $synchash.EQ_Preset_ComboBox.add_SelectionChanged({
          $synchash.EQ_Timer.start()
      }.GetNewClosure())
  
      #apply eq
      if($synchash.Equalizer -ne $null -and $thisapp.config.Enable_EQ){$null = $synchash.vlc.SetEqualizer($synchash.Equalizer)}
      #eq Preset
      if(-not [string]::IsNullOrEmpty($thisapp.Config.EQ_Selected_Preset)){$synchash.EQ_Preset_ComboBox.selectedItem = $thisapp.Config.EQ_Selected_Preset}
      #Preamp 
      $synchash.Preamp_Slider.Value = $thisapp.Config.EQ_Preamp     
      $youtubedl_path = "$Current_folder\Resources\youtube-dl"
      $env:Path += ";$youtubedl_path"
      [int]$a = 0 
      $synchash.MediaPlayer_Slider.Maximum = 100
      $synchash.MediaPlayer_CurrentDuration = 0
      #$synchash.trackbar1.Maximum = $a
      [int]$c = $a / 60
      $a = $a - $c * 60        
      $synchash.Media_Length_Label.content = '0' + '/' + "$c" + ':' + "$a"
    }catch{
      write-ezlogs 'An exception while initializing libvlc EQ and audio settings' -showtime -catcherror $_
    }

    $synchash.Options_button.add_Click({
        if($synchash.Audio_Flyout.IsOpen){
          $synchash.Audio_Flyout.IsOpen = $false
        }else{
          $synchash.Audio_Flyout.IsOpen = $true
        }
    })
    $synchash.Audio_Flyout.add_IsOpenChanged({
        if($synchash.Audio_Flyout.isOpen){
          $synchash.Options_button.isChecked = $true
        }else{
          $synchash.Options_button.isChecked = $false
        }
    })
  }
  #endregion------EQ And Audio Settings------

  $synchash.libvlc_No_vis_timer = New-Object System.Windows.Threading.DispatcherTimer 
  $synchash.libvlc_No_vis_timer.Add_tick({
      try{ 
        $synchash.VLC = $synchash.VideoView.MediaPlayer
        if($synchash.Volume_Slider.value){
          $synchash.vlc.Volume = $synchash.Volume_Slider.value
        }else{
          $synchash.vlc.Volume = 100
        }        
        Add-VLCRegisteredEvents -synchash $synchash -thisApp $thisApp            
        $this.Stop()
      }catch{
        write-ezlogs "An exception occurred in libvlc_timer" -showtime -catcherror $_
        $this.Stop()
      }
  }.GetNewClosure())
 
}

#----------------------------------------------
#endregion Initialize libvlc
#----------------------------------------------

if($thisApp.Config.startup_perf_timer){$Initialize_VLC_Perf =  "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Initialize VLC:              $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds`n[$(Get-date -format $logdateformat)]     | EQ_Initialize Total: $($EQ_Initialize_measure.Seconds) seconds - $($EQ_Initialize_measure.Milliseconds) Milliseconds`n[$(Get-date -format $logdateformat)]     | Initialize VLC Total: $($Initialize_VLC_Perf_Measure.Seconds) seconds - $($Initialize_VLC_Perf_Measure.Milliseconds) Milliseconds"}
#############################################################################
#endregion Initialization Events
#############################################################################

#---------------------------------------------- 
#region Play Queue Button
#----------------------------------------------
if($synchash.PlayQueueFlyout.IsOpen){
  #$synchash.PlayQueue_button.Foreground =  "LightGreen"
  $synchash.PlayQueue_button.isChecked = $true
}else{
  #$synchash.PlayQueue_button.Foreground =  "White"
  $synchash.PlayQueue_button.isChecked = $false
}
#$synchash.childwindow.AllowMove = $true
[System.Windows.RoutedEventHandler]$PlayQueue_button_Command  = {
  param($sender)
  try{
    <#    if($synchash.childwindow.isOpen){
        $synchash.childwindow.isOpen = $false
        }else{
        $synchash.childwindow.isOpen = $true
    }#>

    if($synchash.PlayQueueFlyout.IsOpen){
      $synchash.PlayQueueFlyout.IsOpen = $false
      #$synchash.PlayQueue_button.Foreground =  "White"
      #$synchash.playlist_column.Width=0
    }else{
      $synchash.PlayQueueFlyout.IsOpen = $true
      #$synchash.PlayQueue_button.Foreground =  "LightGreen"
      #$synchash.playlist_column.Width= "100*"
    }
  }catch{
    write-ezlogs 'An exception occurred in PlayQueue_button click event' -showtime -catcherror $_
  }
}

$synchash.PlayQueueFlyout.add_IsOpenChanged({

    if($synchash.PlayQueueFlyout.isOpen){
      $synchash.PlayQueue_button.isChecked = $true
    }else{
      $synchash.PlayQueue_button.isChecked = $false
    }

})

$null = $synchash.PlayQueue_button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$PlayQueue_button_Command)
$null = $synchash.PlayQueueFlyout_button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$PlayQueue_button_Command)
#---------------------------------------------- 
#endregion Play Queue Button
#----------------------------------------------

#---------------------------------------------- 
#region Brew Button
#----------------------------------------------

[System.Windows.RoutedEventHandler]$Brew_button_Command  = {
  param($sender)
  try{
    Get-OpenBreweryDB -thisApp $thisApp -synchash $synchash -Verboselog
  }catch{
    write-ezlogs 'An exception occurred in Brew_button click event' -showtime -catcherror $_
  }
}
$null = $synchash.Brew_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Brew_Button_Command)

#---------------------------------------------- 
#endregion Brew Button
#----------------------------------------------


#---------------------------------------------- 
#region Screenshot Button
#----------------------------------------------

[System.Windows.RoutedEventHandler]$Screenshot_button_Command  = {
  param($sender)
  try{
    if([System.io.Directory]::Exists($thisApp.Config.Snapshots_Path)){
      $outputDir = $thisApp.Config.Snapshots_Path
    }else{
      $outputDir = $thisApp.Config.Temp_Folder
      if($thisApp.Config.Snapshots_Path){
        write-ezlogs "The existing snapshots path is not valid $($thisApp.Config.Snapshots_Path) - defaulting to $($thisApp.Config.Temp_Folder)" -showtime -warning
        Update-Notifications  -Level 'WARNING' -Message "The existing snapshots path ($($thisApp.Config.Snapshots_Path)) is not valid - defaulting to $($thisApp.Config.Temp_Folder)" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
      }
    }
    if($thisApp.Config.Video_Snapshots){
      $Current_playing = $synchash.PlayQueue_TreeView.Items | where  {$_.header.id -eq $synchash.Current_playing_media.id} | select -Unique
      if($Current_playing.header.title){
        $title = "$($Current_playing.header.title)_$(Get-date -Format 'MM-dd-yyyy_hh-mm-ss_tt')" -replace '---> ' -replace ':'
      }else{
        $title = "$($thisApp.Config.App_Name)_$(Get-date -Format 'MM-dd-yyyy_hh-mm-ss_tt')"
      }
      $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
      $pattern = "[$illegal]"
      $title = ([Regex]::Replace($title, $pattern, '')).trim()
      $snapshot = $synchash.vlc.TakeSnapshot(0,"$($outputDir)\$title.png",0,0)
      if($snapshot){
        write-ezlogs "Video Snapshot: $($outputDir)\$title.png" -showtime
        Update-Notifications  -Level 'INFO' -Message "Saved video screenshot: $($outputDir)\$title.png" -VerboseLog -Message_color 'Cyan' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
      }else{
        write-ezlogs "No Video snapshot was generated" -showtime -warning
        Update-Notifications  -Level 'WARNING' -Message "No Video snapshot generated, verify a video is playing and viewable. Check logs for details" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
      }
    }
    #$synchash.vlc.ToggleFullscreen()
    $topmost_before =  $synchash.Window.Topmost
    $synchash.Window.Topmost = $true
    $synchash.Window.Activate()
    $screenshot = New-ScreenShot -outFolder $outputDir -tempPath $outputDir -fps 60 -screen_Capture_Duration 1 -captureCursor 1 -Verbose
    if($screenshot){
      write-ezlogs "App Snapshot: $screenshot" -showtime
      Update-Notifications  -Level 'INFO' -Message "Saved App Snapshot: $screenshot" -VerboseLog -Message_color 'Cyan' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
    }else{
      write-ezlogs "No Screenshot was generated" -showtime -warning
      Update-Notifications  -Level 'WARNING' -Message "Something went wrong, no App Snapshot generated! See logs" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
    }
    $synchash.Window.Topmost = $topmost_before
    #start $thisApp.Config.Temp_Folder
  }catch{
    write-ezlogs 'An exception occurred in PlayQueue_button click event' -showtime -catcherror $_
  }
}
$null = $synchash.ScreenShot_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$ScreenShot_Button_Command)

#---------------------------------------------- 
#endregion Screenshot Button
#----------------------------------------------


#---------------------------------------------- 
#region Show_Library_button Button
#----------------------------------------------
if($synchash.MediaLibrary_Flyout.IsOpen){ 
  $synchash.MainGrid_Row3.Height="300*"
  $synchash.MainGrid_Row3.MinHeight="300"
  $synchash.Window.MinHeight="800"
  $synchash.Expand_Library_Icon.Kind = "ArrowCollapseDown"
  $synchash.MainGrid_Row3_History = $synchash.MainGrid_Row3.Height
}else{
  $synchash.MainGrid_Row3.Height="60"
  $synchash.Window.MinHeight="320"
  $synchash.Expand_Library_Icon.Kind = "ArrowCollapseUp"
  $synchash.MainGrid_Row3_History = $synchash.MainGrid_Row3.Height
}
[System.Windows.RoutedEventHandler]$Expand_Library_Button_Command  = {
  param($sender)
  try{
    if($synchash.MediaLibrary_Flyout.IsOpen){
      $synchash.MediaLibrary_Flyout.IsOpen = $false
    }else{
      $synchash.MediaLibrary_Flyout.IsOpen = $true
    }
    $synchash.MediaLibrary_Flyout_History = $synchash.MediaLibrary_Flyout.isOpen
  }catch{
    write-ezlogs 'An exception occurred in Expand_Library_Button click event' -showtime -catcherror $_
  }
}

$null = $synchash.Expand_Library_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Expand_Library_Button_Command)

$synchash.MediaLibrary_Flyout.add_IsOpenChanged({
    try{
      if(!$synchash.MediaLibrary_Viewer.isVisible){
        if($synchash.MediaLibrary_Flyout.IsOpen){       
          $synchash.MainGrid_Row3.Height="300*"
          $synchash.Window.MinHeight="800"
          #$synchash.Window.SizeToContent="Manual"  
          $synchash.MainGrid_Row3.MinHeight="300"
          $synchash.Expand_Library_Icon.Kind = "ArrowCollapseDown"
          $synchash.MainGrid_Row3_History = $synchash.MainGrid_Row3.Height 
          $synchash.Expand_Library_Button.isChecked = $true
        }else{
          $synchash.MainGrid_Row3.Height="50"
          $synchash.MainGrid_Row3.MinHeight="50"     
          #$synchash.Window.SizeToContent="Height" 
          $synchash.Window.MinHeight="320" 
          $synchash.Expand_Library_Icon.Kind = "ArrowCollapseUp"
          $synchash.MainGrid_Row3_History = $synchash.MainGrid_Row3.Height
          $synchash.Expand_Library_Button.isChecked = $false
        }   
      }
    }catch{
      write-ezlogs 'An exception occurred in MediaLibrary_Flyout IsOpenChanged event' -showtime -catcherror $_
    }
})


#---------------------------------------------- 
#region Detach Media Player Button
#----------------------------------------------
#Fullscreen Window
[System.Windows.RoutedEventHandler]$Detach_Library_button_Command = {
  param($sender)
  #$Media = $_.OriginalSource.DataContext
  #write-ezlogs "Media $($Media | out-string)"
  #if(!$Media.url){$Media = $sender.tag}
  #if(!$Media.url){$Media = $sender.tag.Media}
  $ScreenBounds = [Windows.Forms.SystemInformation]::VirtualScreen
  $PrimaryMonitor = [System.Windows.Forms.Screen]::PrimaryScreen
  try{
    if(!$synchash.MediaLibrary_Viewer.isVisible){
      $synchash.Show_Library_Button.isChecked = $true
      write-ezlogs 'Attempting to open Medialibrary_Viewer' -showtime
      #$xcloud_window = New-object MahApps.Metro.Controls.MetroWindow
      [xml]$XamlMediaLibrary_Viewer = [System.IO.File]::ReadAllText("$($Current_folder)\\Views\\MediaLibraryViewer.xaml").replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml") 
      $Childreader = (New-Object System.Xml.XmlNodeReader $XamlMediaLibrary_Viewer)
      $MediaLibrary_windowXaml   = [Windows.Markup.XamlReader]::Load($Childreader)  
      $XamlMediaLibrary_Viewer.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {$synchash."$($_.Name)" = $MediaLibrary_windowXaml.FindName($_.Name)}
      if($synchash.MainGrid.children -contains $synchash.MediaLibrary_FlyoutControl){
        $null = $synchash.MainGrid.children.Remove($synchash.MediaLibrary_FlyoutControl)
      }
      #$synchash.MainGrid.updateLayout() 
      if($synchash.Medialibrary_Viewer_Grid.children -notcontains $synchash.MediaLibrary_FlyoutControl){
        $null = $synchash.Medialibrary_Viewer_Grid.AddChild($synchash.MediaLibrary_FlyoutControl)
      }
      $synchash.MainGrid_Row3_BeforeViewerHistory = $synchash.MainGrid_Row3.Height
      $synchash.MainGrid_Row3.MinHeight=$null
      $synchash.MainGrid_Row3.Height="*"
      $synchash.Window.MinHeight="320"
      $synchash.MediaLibrary_Flyout_history = $synchash.MediaLibrary_Flyout.IsOpen
      $synchash.MediaLibrary_Flyout.IsOpen = $true
      $synchash.Expand_Library_Button.isEnabled = $false
      $synchash.gridsplitter.isEnabled = $false
      $synchash.Window.Height = $synchash.Window.ActualHeight - $synchash.MediaLibrary_FlyoutControl.ActualHeight      
      #$synchash.Window.SizetoContent="Height"
      $synchash.MediaLibrary_Viewer.icon = "$($thisapp.Config.Current_folder)\\Resources\\MusicPlayerFilltest.ico"  
      $synchash.MediaLibrary_Viewer.icon.Freeze()
      $synchash.Medialibrary_Title_menu_Image.Source = "$($thisapp.Config.Current_folder)\\Resources\\MusicPlayerFilltest.ico"
      $synchash.Medialibrary_Title_menu_Image.width = '18'  
      $synchash.Medialibrary_Title_menu_Image.Height = '18'
      $synchash.MediaLibrary_Viewer.Title = "Media Library - $($thisApp.Config.App_Name)"
      $synchash.Medialibrary_Viewer_DockPanel_Label.Content = "Media Library - $($thisApp.Config.App_Name)"
      $synchash.Medialibrary_Viewer.TaskbarItemInfo.Description = "Media Library - $($thisApp.Config.App_Name) - Version: $($thisApp.Config.App_Version)"      
      $synchash.MediaLibrary_Viewer.IsWindowDraggable = 'True'
      $synchash.MediaLibrary_Viewer.LeftWindowCommandsOverlayBehavior = 'HiddenTitleBar' 
      $synchash.MediaLibrary_Viewer.RightWindowCommandsOverlayBehavior = 'HiddenTitleBar'
      $synchash.MediaLibrary_Viewer.ShowTitleBar = $true
      $synchash.MediaLibrary_Viewer.UseNoneWindowStyle = $false
      $synchash.MediaLibrary_Viewer.WindowStyle = 'none'
      $synchash.MediaLibrary_Viewer.IgnoreTaskbarOnMaximize = $true
      #$synchash.MediaLibrary_Viewer.WindowState = 'Maximized' 

      $synchash.MediaLibrary_Viewer.add_closing({
          try{
            if($synchash.MediaLibrary_Viewer_Grid.children -contains $synchash.MediaLibrary_FlyoutControl){
              $null = $synchash.MediaLibrary_Viewer_Grid.children.Remove($synchash.MediaLibrary_FlyoutControl)
            }       
            if($synchash.MainGrid.Children -notcontains $synchash.MediaLibrary_FlyoutControl){
              $null = $synchash.MainGrid.Children.Add($synchash.MediaLibrary_FlyoutControl) 
            }
            if($synchash.MediaLibrary_Flyout_history){  
              $synchash.Window.MinHeight="800"
              $synchash.MediaLibrary_Flyout.isOpen = $true
              $synchash.MainGrid_Row3.MinHeight="300"
              $synchash.MainGrid_Row3.Height = $synchash.MainGrid_Row3_BeforeViewerHistory
              #$synchash.MainGrid_Row3.Height = $synchash.MediaLibrary_FlyoutControl.Height
              $synchash.Window.Height = $synchash.Window.Height + $synchash.MediaLibrary_FlyoutControl.ActualHeight
            }else{
              $synchash.MediaLibrary_Flyout.isOpen = $false
              $synchash.MainGrid_Row3.Height="50"
              $synchash.MainGrid_Row3.MinHeight="50"
              $synchash.Window.MinHeight="320"
            }                               
            #$synchash.MainGrid_Row3.Height="300*"           
            #$synchash.Window.SizetoContent="Height" 
            #$synchash.MediaLibrary_FlyoutControl.updatelayout()   
            #$synchash.MainGrid.updateLayout()      
            #$synchash.Window.SizetoContent="Manual"     
          }catch{
            write-ezlogs "An exception occurred in FullScreen_Viewer.add_closing" -showtime -catcherror $_
          }
      })
      $synchash.MediaLibrary_Viewer.add_closed({
          $synchash.Expand_Library_Button.isEnabled = $true
          $synchash.Show_Library_Button.isChecked = $false
          $synchash.gridsplitter.isEnabled = $true
          $synchash.Expand_Library_Icon.Kind = "ArrowCollapseDown"
          $synchash.Expand_Library_Button.isChecked = $true
          #$synchash.Window.updatelayout()
          $synchash.Window.Activate()     
          #$null = [System.GC]::GetTotalMemory($true)
      }) 
      [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($synchash.MediaLibrary_Viewer)     
      $synchash.MediaLibrary_Viewer.Show()   
    }else{
      $synchash.Show_Library_Button.isChecked = $false
      $synchash.MediaLibrary_Viewer.close()
    }
  }catch{write-ezlogs 'Exception occurred opening new webview2 window for MediaLibrary_Viewer' -showtime -catcherror $_}                            
}.GetNewClosure()
$null = $synchash.Show_Library_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Detach_Library_button_Command)
#$null = $synchash.FullScreen_Player_Button.AddHandler([Windows.Controls.Button]::ClickEvent,$FullScreen_Command)
#---------------------------------------------- 
#endregion Detach Media Player Button
#----------------------------------------------



$synchash.gridsplitter.add_DragCompleted({
    $synchash.MainGrid_Row3_History = $synchash.MainGrid_Row3.ActualHeight
})
#---------------------------------------------- 
#endregion Show_Library_button Button
#----------------------------------------------

#---------------------------------------------- 
#region Show_Playlists_button Button
#----------------------------------------------
[System.Windows.RoutedEventHandler]$Show_Playlists_button_Command  = {
  param($sender)
  try{
    if($synchash.Playlists_Flyout.IsOpen){
      $synchash.Playlists_Flyout.IsOpen = $false
    }else{
      if(!$synchash.MediaLibrary_Flyout.IsOpen){
        $synchash.MediaLibrary_Flyout.IsOpen = $true
      }
      $synchash.Playlists_Flyout.IsOpen = $true
    }
  }catch{
    write-ezlogs 'An exception occurred in Show_Playlists_Button click event' -showtime -catcherror $_
  }
}
$null = $synchash.Show_Playlists_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Show_Playlists_button_Command)

$synchash.Playlists_Flyout.add_IsOpenChanged({
    try{
      if($synchash.Playlists_Flyout.IsOpen){
        $synchash.Show_Playlists_Button.isChecked = $true
      }else{
        $synchash.Show_Playlists_Button.isChecked = $false
      }
    }catch{
      write-ezlogs 'An exception occurred in Playlists_Flyout IsOpenChanged event' -showtime -catcherror $_
    }
})
#---------------------------------------------- 
#endregion Show_Playlists_button Button
#----------------------------------------------

#---------------------------------------------- 
#region Manage Sources Button
#----------------------------------------------
$synchash.Add_Media_Button.Add_Click({ 
    #$synchash.Window.hide()
    try{
      if(!(Get-command -Module Spotishell)){
        Import-Module "$($thisApp.Config.Current_folder)\Modules\Spotishell\Spotishell.psm1"
      } 
      if($hashsetup.Window.isVisible){
        $hashsetup.Window.Dispatcher.invoke([action]{
            $hashsetup.Window.Activate()
        })
      }else{   
        $synchash.Add_Media_Button.isEnabled = $false
        Show-FirstRun -PageTitle "$($thisScript.name) - Update Media Sources" -PageHeader 'Update Media Sources' -Logo "$($thisapp.Config.Current_Folder)\\Resources\\MusicPlayerFilltest.ico" -thisScript $thisScript -synchash $synchash -thisApp $thisapp -PlayMedia_Command $PlayMedia_Command -PlaySpotify_Media_Command $PlaySpotify_Media_Command -Update -First_Run:$false -use_runspace
      }              
    }catch{
      write-ezlogs 'An exception occurred in Add_Media_Button click event' -showtime -catcherror $_
      $synchash.Window.Activate()
    }
    $synchash.Window.Activate()
    #$synchash.Window.Show()
}.GetNewClosure())

#---------------------------------------------- 
#endregion Manage Sources Button
#----------------------------------------------

#---------------------------------------------- 
#region Add Local Media Button
#----------------------------------------------
$synchash.Add_LocalMedia_Button.Add_Click({ 
    try{ 

      $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
      $pattern = "[$illegal]"
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($synchash.Window,'Add Media','Enter/Paste the path of the Media file or Directory you wish to add',$Button_Settings)
      if($result){
        $result_cleaned = ([Regex]::Replace($result, $pattern, '')).trim()      
        if(-not [string]::IsNullOrEmpty($result_cleaned)){          
          #$synchash.Window.hide()
          #Start-SplashScreen -SplashTitle $thisScript.Name -SplashMessage 'Updating Media library...' -thisScript $thisScript -current_folder $Current_folder -log_file $thisapp.Config.Log_file -Script_modules $Script_Modules
          #Start-Sleep 1        
          write-ezlogs ">>>> Adding Local Media $result_cleaned" -showtime -color cyan
          Import-Media -Media_Path $result_cleaned -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory  -thisApp $thisapp
          #close-splashscreen
          #$synchash.Window.Show()        
        }else{
          write-ezlogs "The provided Path is not valid! -- $result" -showtime -warning
        }  
      }else{
        write-ezlogs "No Path was provided!" -showtime -warning
      }              
    }catch{
      write-ezlogs 'An exception occurred in Add_LocalMedia_Button click event' -showtime -catcherror $_
    }
}.GetNewClosure())

#---------------------------------------------- 
#endregion Add Local Media Button
#----------------------------------------------

#---------------------------------------------- 
#region Add Youtube Media Button
#----------------------------------------------
$synchash.Add_YoutubeMedia_Button.Add_Click({   
    try{  
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($synchash.Window,'Add Youtube Video','Enter/Paste the URL of the Youtube Video or Playlist',$Button_Settings)
      if(-not [string]::IsNullOrEmpty($result) -and (Test-url $result)){
        #$synchash.Window.hide()
        #Start-SplashScreen -SplashTitle $thisScript.Name -SplashMessage 'Updating Media library...' -thisScript $thisScript -current_folder $Current_folder -log_file $thisapp.Config.Log_file -Script_modules $Script_Modules
        #Start-Sleep 1        
        write-ezlogs ">>>> Adding Youtube video $result" -showtime -color cyan -logfile:$thisApp.Config.YoutubeMedia_logfile
        #$synchash.Youtube_Progress_Ring.isActive = $true
        Import-Youtube -Youtube_URL $result -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -PlayMedia_Command $Synchash.PlayMedia_Command -thisApp $thisapp
        #$synchash.Youtube_Progress_Ring.isActive = $false
        #close-splashscreen
        #$synchash.Window.Show()        
      }else{
        write-ezlogs "The provided URL is not valid or was not provided! -- $result" -showtime -warning -logfile:$thisApp.Config.YoutubeMedia_logfile
      }                
    }catch{
      write-ezlogs 'An exception occurred in Add_YoutubeMedia_Button.Add_Click' -showtime -catcherror $_ -logfile:$thisApp.Config.YoutubeMedia_logfile
    }
}.GetNewClosure())

#---------------------------------------------- 
#endregion Add Youtube Media Button
#----------------------------------------------

#---------------------------------------------- 
#region Progress Slider Controls
#----------------------------------------------
$synchash.MediaPlayer_Slider.Add_ValueChanged({
    if($synchash.MediaPlayer_Slider.IsMouseOver -and $synchash.MediaPlayer_Slider.IsFocused -and $synchash.vlc.IsPlaying -and $([timespan]::FromMilliseconds($synchash.VLC.Time)).TotalSeconds -ne $synchash.MediaPlayer_Slider.Value){
      write-ezlogs "Updating vlc time: $($synchash.MediaPlayer_Slider.Value * 1000)"
      $synchash.VLC.Time = $synchash.MediaPlayer_Slider.Value * 1000
      [int]$b = [int]$synchash.MediaPlayer_Slider.Value
      [int]$d = $b / 60
      #min 
      [int]$hrs = $($([timespan]::FromSeconds($b)).Hours)
      [int]$mins = $($([timespan]::FromSeconds($b)).Minutes)
      [int]$secs = $($([timespan]::FromSeconds($b)).Seconds)
      $total_time = $synchash.MediaPlayer_CurrentDuration    
      $synchash.Media_Length_Label.content = "$hrs" + "$mins" + ':' + "$secs" + '/' + "$($total_time)"
    }elseif($synchash.MediaPlayer_Slider.IsMouseOver -and !$synchash.vlc.IsPlaying -and $synchash.MediaPlayer_Slider.IsFocused){
      #do nothing?
    }
})

$synchash.MediaPlayer_Slider.add_PreviewMouseUp({
    $sender = $args[0]
    [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]
    
    if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Released)
    {    
      write-ezlogs "Slider mouse up event $($synchash.MediaPlayer_Slider.Value)"
      $newvalue = $e.Source.value
      if(!$synchash.vlc.IsPlaying){
        if($thisapp.config.Use_Spicetify){
          $current_track = $thisapp.config.Spicetify
          $progress = [timespan]::Parse($thisapp.config.Spicetify.POSITION).TotalSeconds
        }elseif($synchash.Spotify_WebPlayer_State.current_track.id -and $synchash.Spotify_WebPlayer_State.playbackstate -ne 0){
          $synchash.WebPlayer_Playing_timer.stop()
          $newvalue = $([timespan]::FromSeconds($($synchash.MediaPlayer_Slider.Value))).TotalMilliseconds
          #write-ezlogs "Seeking to $($newvalue)"
          $synchash.Spotify_Webview2_SeekScript =  @"
  console.log('Seeking Spotify Track to $($newvalue)');
  SpotifyWeb.player.seek($($newvalue));
   console.log('New Position',SpotifyWeb.currState.position);
"@
          $synchash.WebView2.ExecuteScriptAsync(
            $synchash.Spotify_Webview2_SeekScript      
          ) 
          $synchash.MediaPlayer_CurrentDuration = $newvalue
          $synchash.WebPlayer_Playing_timer.start()
          #$synchash.MediaPlayer_Slider.Value = $synchash.MediaPlayer_Slider.Value
          #$current_track = (Get-CurrentTrack -ApplicationName $thisapp.config.App_Name)
          #$progress = [timespan]::FromMilliseconds($current_track.progress_ms).TotalSeconds
        }else{
          $current_track = (Get-CurrentTrack -ApplicationName $thisapp.config.App_Name)
          $progress = [timespan]::FromMilliseconds($current_track.progress_ms).TotalSeconds
        } 
        #TODO: Need to add Spicetify commands for this             
        if(!$synchash.Spotify_WebPlayer_State.current_track.id -and $current_track.is_playing -and $progress -ne $e.Source.value){
          $synchash.MediaPlayer_Slider.Value = $e.Source.value
          $devices = Get-AvailableDevices -ApplicationName $thisapp.config.App_Name
          Invoke-SeekPositionCurrentTrack -PositionMs ($newvalue * 1000) -DeviceId $devices.id -ApplicationName $thisapp.config.App_Name
          #Set-SpotifyPlayer -DeviceId ($devices | where {$_.is_active}).id -Shuffle:$false -Repeat off -TrackPosition ($synchash.MediaPlayer_Slider.Value * 1000)
        }
      }
    }
})
#---------------------------------------------- 
#endregion Progress Slider Controls
#----------------------------------------------

#---------------------------------------------- 
#region Volume Controls
#----------------------------------------------
if($thisapp.Config.Media_Volume){
  $synchash.vlc.Volume = $thisapp.Config.Media_Volume
}else{
  $synchash.vlc.Volume = 100
}
if($synchash.vlc.mute){
  $synchash.Volume_icon.kind = 'Volumeoff'
}elseif($synchash.vlc.Volume -ge 75){
  $synchash.Volume_icon.kind = 'VolumeHigh'
}elseif($synchash.vlc.Volume -gt 25 -and $synchash.vlc.Volume -lt 75){
  $synchash.Volume_icon.kind = 'VolumeMedium'
}elseif($synchash.vlc.Volume -le 25 -and $synchash.vlc.Volume -gt 0){
  $synchash.Volume_icon.kind = 'VolumeLow'
}elseif($synchash.vlc.Volume -le 0){
  $synchash.Volume_icon.kind = 'Volumeoff'
}

$synchash.Volume_Slider.value = $synchash.vlc.Volume
$synchash.Volume_Slider.Add_ValueChanged({
    if($synchash.vlc){
      $synchash.vlc.Volume = $synchash.Volume_Slider.Value
      $thisapp.Config.Media_Volume = $synchash.vlc.Volume
      if($synchash.vlc.Volume -ge 75){
        $synchash.Volume_icon.kind = 'VolumeHigh'
      }elseif($synchash.vlc.Volume -gt 25 -and $synchash.vlc.Volume -lt 75){
        $synchash.Volume_icon.kind = 'VolumeMedium'
      }elseif($synchash.vlc.Volume -le 25 -and $synchash.vlc.Volume -gt 0){
        $synchash.Volume_icon.kind = 'VolumeLow'
      }elseif($synchash.vlc.Volume -le 0){
        $synchash.Volume_icon.kind = 'Volumeoff'
      }      
    }
    if(($synchash.Webview2.CoreWebView2.IsDocumentPlayingAudio) -or ($synchash.WebPlayer_State -ne 0 -and $synchash.Youtube_WebPlayer_title) -or ($synchash.Spotify_WebPlayer_State.current_track -and $synchash.Spotify_WebPlayer_State.playbackstate -ne 0)){
      if($synchash.Spotify_WebPlayer_State -and $synchash.Spotify_WebPlayer_State.playbackstate -ne 0 -and $synchash.Spotify_WebPlayer_State.current_track.id){
        $synchash.Webview2_VolumeScript =  @"
   console.log('Setting Spotify Volume to $($synchash.Volume_Slider.Value / 100)');
  SpotifyWeb.player.setVolume($($synchash.Volume_Slider.Value / 100))
"@             
        $synchash.WebView2.ExecuteScriptAsync(
          $synchash.Webview2_VolumeScript      
        )
      }else{
 
        $synchash.Webview2_VolumeScript =  @"
  var player = document.getElementById('movie_player');
  player.setVolume($($synchash.Volume_Slider.Value))
"@             
        $synchash.WebView2.ExecuteScriptAsync(
          $synchash.Webview2_VolumeScript      
        )
      }
    }
})
$synchash.Volume_button.Add_Click({
    if($synchash.vlc){
      $synchash.vlc.ToggleMute()
      if($synchash.vlc.mute){$synchash.Volume_icon.kind = 'Volumeoff'}elseif($synchash.vlc.Volume -ge 75){$synchash.Volume_icon.kind = 'VolumeHigh'}elseif($synchash.vlc.Volume -gt 25 -and $synchash.vlc.Volume -lt 75){$synchash.Volume_icon.kind = 'VolumeMedium'}elseif($synchash.vlc.Volume -le 25 -and $synchash.vlc.Volume -gt 0){$synchash.Volume_icon.kind = 'VolumeLow'}elseif($synchash.vlc.Volume -le 0){$synchash.Volume_icon.kind = 'Volumeoff'}      
    }
    if(($synchash.Webview2.CoreWebView2.IsDocumentPlayingAudio -and !$synchash.Webview2.CoreWebView2.IsMuted) -or ($synchash.Spotify_WebPlayer_State.current_track.id -and $synchash.Spotify_WebPlayer_State.playbackstate -ne 0) -or ($synchash.WebPlayer_State -ne 0 -and $synchash.Youtube_WebPlayer_title)){
      if($synchash.Spotify_WebPlayer_State -and $synchash.Spotify_WebPlayer_State.playbackstate -ne 0 -and $synchash.Spotify_WebPlayer_State.current_track.id){
        $synchash.Webview2_MuteScript =  @"
 SpotifyWeb.player.getVolume().then(volume => {
  if (volume == 0){
       console.log('Unmuting Spotify Volume to $($synchash.Volume_Slider.Value / 100)');
      SpotifyWeb.player.setVolume($($synchash.Volume_Slider.Value / 100));
  } else {
     console.log('Muting Spotify Volume to 0');
    SpotifyWeb.player.setVolume(0);
  }
});

"@             
        $synchash.WebView2.ExecuteScriptAsync(
          $synchash.Webview2_MuteScript      
        )
      }elseif($thisApp.Config.Use_invidious){
        $synchash.Webview2.CoreWebView2.IsMuted = $true
      }else{
        $synchash.Webview2_MuteScript =  @"
  var player = document.getElementById('movie_player');
  var isMuted = player.isMuted();
  if (isMuted)
     player.unMute();
  else
    player.mute();
"@             
        $synchash.WebView2.ExecuteScriptAsync(
          $synchash.Webview2_MuteScript      
        )
      }      
    }elseif($synchash.Webview2.CoreWebView2.IsDocumentPlayingAudio -and $synchash.Webview2.CoreWebView2.IsMuted){
      $synchash.Webview2.CoreWebView2.IsMuted = $false 
    }    
})

#---------------------------------------------- 
#endregion Volume Controls
#----------------------------------------------

#---------------------------------------------- 
#region VLC Routed Event Handlers
#----------------------------------------------
[System.Windows.RoutedEventHandler]$RestartMedia_Command  = {
  param($sender)
  try{
    if($synchash.Current_playing_media.id){
      if($synchash.Current_playing_media.Spotify_Path -or $synchash.Current_playing_media.uri -match 'spotify:' -or $synchash.Current_playing_media.Source -eq 'SpotifyPlaylist'){
        #$Spotify_media = $Spotify_Datatable.datatable | where {$_.id -eq $synchash.Current_playing_media.id}
        Start-SpotifyMedia -Media $synchash.Current_playing_media -thisApp $thisapp -synchash $synchash -Show_notification
      }else{
        Start-Media -Media $synchash.Current_playing_media -thisApp $thisapp -synchash $synchash -Show_notification -all_playlists $synchash.all_playlists
      }
    }else{
      $last_played = $synchash.Last_played
      $synchash.timer.stop()
      $synchash.Last_played = $last_played
      $synchash.VLC.stop()
      $synchash.Vlc.Play()
      if($synchash.Volume_Slider.Value){
        $synchash.vlc.Volume = $synchash.Volume_Slider.Value
        $thisapp.Config.Media_Volume = $synchash.vlc.Volume
        if($synchash.vlc.Volume -ge 75){
          $synchash.Volume_icon.kind = 'VolumeHigh'
        }elseif($synchash.vlc.Volume -gt 25 -and $synchash.vlc.Volume -lt 75){
          $synchash.Volume_icon.kind = 'VolumeMedium'
        }elseif($synchash.vlc.Volume -le 25 -and $synchash.vlc.Volume -gt 0){
          $synchash.Volume_icon.kind = 'VolumeLow'
        }elseif($synchash.vlc.Volume -le 0){
          $synchash.Volume_icon.kind = 'Volumeoff'
        }      
      }
      $synchash.timer.start()
      if($synchash.chat_WebView2.CoreWebView2 -and $thisApp.config.Chat_View ){
        $synchash.chat_WebView2.Reload()       
      }
    }
  }catch{
    write-ezlogs 'An exception occurred in Restart_Media click event' -showtime -catcherror $_
  }
}

[System.Windows.RoutedEventHandler]$StopMedia_Command  = {
  param($sender)
  try{  
    Stop-Media -synchash $synchash -thisApp $thisApp         
  }catch{
    write-ezlogs 'An exception occurred in stop_media click event' -showtime -catcherror $_
  }
}

[System.EventHandler]$Synchash.Menu_StopMedia_Command  = {
  param($sender)
  try{  
    Stop-Media -synchash $synchash -thisApp $thisApp         
  }catch{
    write-ezlogs 'An exception occurred in Menu_StopMedia_Command click event' -showtime -catcherror $_
  }
}

[System.Windows.RoutedEventHandler]$Synchash.PauseMedia_Command  = {
  param($sender)
  try{  
    Pause-Media -synchash $synchash -thisApp $thisApp         
  }catch{
    write-ezlogs 'An exception occurred in Pause_media click event' -showtime -catcherror $_
  }
}

[System.EventHandler]$synchash.Menu_PauseMedia_Command  = {
  param($sender)
  try{  
    Pause-Media -synchash $synchash -thisApp $thisApp         
  }catch{
    write-ezlogs 'An exception occurred in Pause_media click event' -showtime -catcherror $_
  }
}
[System.Windows.RoutedEventHandler]$Synchash.NextMedia_Command  = {
  param($sender)
  try{  
    Skip-Media -synchash $synchash -thisApp $thisApp         
  }catch{
    write-ezlogs 'An exception occurred in Skip_media click event' -showtime -catcherror $_
  }
}

[System.EventHandler]$synchash.Menu_NextMedia_Command  = {
  param($sender)
  try{  
    Skip-Media -synchash $synchash -thisApp $thisApp         
  }catch{
    write-ezlogs 'An exception occurred in Skip_media click event' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion VLC Routed Event Handlers
#----------------------------------------------

#---------------------------------------------- 
#region Update Media Progress Timer
#----------------------------------------------
$synchash.Timer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.Timer.Interval = [timespan]::FromMilliseconds(600) #(New-TimeSpan -Seconds 1)
$synchash.current_track_playing = ''
$synchash.Spotify_Status = 'Stopped'
$synchash.Timer.add_tick({    
    try{
      Update-MediaTimer -synchash $synchash -thisApp $thisApp 
    }catch{
      write-ezlogs "An exception occurred executing Update-MediaTimer" -showtime -catcherror $_
      $this.stop()
    }       
}.GetNewClosure())
#---------------------------------------------- 
#endregion Update Media Progress Timer
#----------------------------------------------

#---------------------------------------------- 
#region Media Control Handlers
#----------------------------------------------
$synchash.Play_Media.add_click({
    if($synchash.VLC.state -match 'Playing'){
      write-ezlogs 'Pausing Vlc playback' -showtime -color cyan 
      $synchash.Now_Playing_Label.content = ($synchash.Now_Playing_Label.content) -replace 'Now Playing', 'Paused'
      $Synchash.Main_Tool_Icon.Text = $synchash.Now_Playing_Label.content
      $synchash.VideoView_Play_Icon.kind = 'PlayCircleOutline'
      $synchash.VLC.pause()
      $synchash.Timer.stop()
      if($synchash.chat_WebView2.CoreWebView2 -and $synchash.chat_WebView2.Visibility -ne 'Hidden'){
        $synchash.chat_WebView2.stop()        
      }         
      return  
    }elseif($synchash.VLC.state -match 'Paused'){
      #$current_track = (Get-CurrentTrack -ApplicationName $thisapp.config.App_Name) 
      write-ezlogs 'Resuming Vlc playback' -showtime -color cyan 
      $synchash.Now_Playing_Label.content = ($synchash.Now_Playing_Label.content) -replace 'Paused', 'Now Playing'
      $Synchash.Main_Tool_Icon.Text = $synchash.Now_Playing_Label.content
      $synchash.VLC.pause()
      $synchash.VideoView_Play_Icon.kind = 'PauseCircleOutline'
      $synchash.Timer.Start()
      if($synchash.chat_WebView2.CoreWebView2 -and $synchash.chat_WebView2.Visibility -ne 'Hidden'){
        $synchash.chat_WebView2.Reload()
      }            
      return
    }else{
      $current_track = (Get-CurrentTrack -ApplicationName $thisapp.config.App_Name)
    }        
    if($current_track.is_playing -or $synchash.Spotify_Status -eq 'Playing'){     
      $devices = Get-AvailableDevices -ApplicationName $thisapp.config.App_Name
      if($devices){
        write-ezlogs 'Pausing Spotify playback' -showtime -color cyan        
        $synchash.Timer.stop()
        $synchash.Spotify_Status = 'Paused'
        if($thisapp.config.Use_Spicetify){
          try{
            if((NETSTAT.EXE -n) | where {$_ -match '127.0.0.1:8974'}){
              write-ezlogs "[Pause_media] Pausing Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -color cyan
              Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing 
            }else{
              write-ezlogs '[Pause_media] PODE does not seem to be running on 127.0.0.1:8974 -- attempting fallback to Suspend-Playback' -showtime -warning
              Suspend-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $devices.id
            } 
          }catch{
            write-ezlogs "[Pause_media] An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE' -- attempting Suspend-Playback" -showtime -catcherror $_ 
            #Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id            
          }
        }else{
          write-ezlogs "[Pause_media] Stopping Spotify playback with Suspend-Playback -ApplicationName $($thisapp.config.App_Name) -DeviceId $($devices.id)" -showtime -color cyan
          Suspend-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $devices.id
        }               
      } 
      return 
    }elseif($current_track.currently_playing_type -ne $null -or $synchash.Spotify_Status -eq 'Paused'){
      $devices = Get-AvailableDevices -ApplicationName $thisapp.config.App_Name
      $synchash.Spotify_Status = 'Playing'
      if($thisapp.config.Use_Spicetify){
        try{
          if((NETSTAT.EXE -n) | where {$_ -match '127.0.0.1:8974'}){
            write-ezlogs "[Pause_media] Resuming Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PLAY'" -showtime -color cyan
            Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PLAY' -UseBasicParsing 
          }else{
            write-ezlogs '[Pause_media] PODE does not seem to be running on 127.0.0.1:8974 -- attempting fallback to Resume-Playback' -showtime -warning
            Resume-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $devices.id
          }        
        }catch{
          write-ezlogs "[Pause_media] An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PLAY' -- attempting Resume-Playback" -showtime -catcherror $_   
          #Resume-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id         
        }
      }else{
        write-ezlogs "[Pause_media] Resuming Spotify playback with Resume-Playback -ApplicationName $($thisapp.config.App_Name) -DeviceId $($devices.id)" -showtime -color cyan
        Resume-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $devices.id      
      }      
      $synchash.Timer.Start()
      return
    }else{
      $synchash.Current_playing_media = $Null
      $thisApp.Config.Last_Played = ''
      $synchash.timer.start()
    }
})


$null = $synchash.Next_Media.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Synchash.NextMedia_Command)
#$null = $synchash.Play_Media.AddHandler([System.Windows.Controls.Button]::ClickEvent,$PlayMedia_Command)
$null = $synchash.Restart_media.AddHandler([System.Windows.Controls.Button]::ClickEvent,$RestartMedia_Command)
$null = $synchash.stop_media.AddHandler([System.Windows.Controls.Button]::ClickEvent,$StopMedia_Command)
$null = $synchash.Pause_media.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Synchash.PauseMedia_Command)
$null = $synchash.New_Playlist_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Add_to_New_PlaylistCommand)

#videoview controls
$null = $synchash.VideoView_LargePlayer_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$ExpandPlayer_Command)
$null = $synchash.Expand_Player_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$ExpandPlayer_Command)
$null = $synchash.VideoView_Play_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Synchash.PauseMedia_Command)
$null = $synchash.VideoView_Stop_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$StopMedia_Command)
$null = $synchash.VideoView_Flyout.AddHandler([System.Windows.Controls.Button]::MouseEnterEvent,$VideoViewMouseEnter)
$null = $synchash.VideoView_Flyout.AddHandler([System.Windows.Controls.Button]::MouseLeaveEvent,$VideoViewMouseLeave)
$null = $synchash.VideoView_Grid.AddHandler([System.Windows.Controls.DataGrid]::MouseLeftButtonDownEvent,$synchash.VideoViewMouseLeftButtonDown_command)
#---------------------------------------------- 
#endregion Media Control Handlers
#----------------------------------------------

#---------------------------------------------- 
#region VLC Registered Events
#----------------------------------------------
Add-VLCRegisteredEvents -synchash $synchash -thisApp $thisApp

<#$synchash.vlc.VlcMediaPlayer.add_EndReached({
    write-ezlogs "End of media" -showtime
    $last_played = $thisApp.config.Last_Played
    if($thisApp.config.Current_Playlist -contains $last_played){
    write-ezlogs " | Removing $last_played from current playlist" -showtime
    $null = $thisApp.config.Current_Playlist.Remove($last_played)
    $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8
    }        
    $next_item = $thisApp.config.Current_Playlist | select -first 1 
    try{ 
    if($next_item){
    $next_selected = $synchash.MediaTable.Items | where {$_.id -eq $next_item}
    if($next_selected){
    Start-Media -media $next_selected -thisApp $thisApp -synchash $synchash
    }
    write-ezlogs " | Next to play is $($next_selected.title)" -showtime
    }else{
    write-ezlogs " | No other media is queued to play" -showtime
    }   
    }catch{
    write-ezlogs "An exception occurred executing Start-Media for next item" -showtime -catcherror $_
    }  
    })
#>

#---------------------------------------------- 
#endregion VLC Registered Events
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){$vlc_Perf =  "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> VLC:                   $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds"}

#############################################################################
#region UI Event Handlers 
#############################################################################

#---------------------------------------------- 
#region Main Window Event Handlers
#----------------------------------------------
$synchash.Window.Add_loaded({
    try{
      $PrimaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen 
      $synchash.Window.MaxHeight = $PrimaryScreen.WorkingArea.Height
      #$synchash.MainGrid_Row3.MaxHeight = $PrimaryScreen.WorkingArea.Height
      #$synchash.Update_TrayMenu_timer.start()
      if(!(Get-command -Module Spotishell)){
        Import-Module "$($thisApp.Config.Current_folder)\Modules\Spotishell\Spotishell.psm1"
      }      
      $theme = [MahApps.Metro.Theming.MahAppsLibraryThemeProvider]::new()
      $themes = $theme.GetLibraryThemes()     
      foreach($Library_theme in $themes){
        #write-ezlogs ">>>> Found theme: $($Library_theme.DisplayName)"
        $menuitem = New-object System.Windows.Controls.MenuItem
        $menuitem.Name = "Theme_$($Library_theme.BaseColorScheme)"
        <#        if($Library_theme.ColorScheme -eq 'Blues'){
            $gradientColor2 = '#FF0A2347'
            }elseif($Library_theme.ColorScheme -eq 'Reds'){
            $gradientColor2 = "#F9410600"
            }elseif($Library_theme.ColorScheme -eq 'Purple2'){
            $gradientColor2 = "#F823003F"
            }elseif($Library_theme.ColorScheme -eq 'Emerald2'){
            $gradientColor2 = '#F9003200'
        }else{#>
        #$gradientColor2 = "$($Library_theme.ShowcaseBrush)" -replace $("$($Library_theme.ShowcaseBrush)").Substring(0,3),'#EA'
        #$A = $("$($Library_theme.ShowcaseBrush)").Substring(0,3)
        $menuitem.Foreground = "$($Library_theme.PrimaryAccentColor)"
        $color = [MahApps.Metro.Controls.ColorHelper]::new()
        $rgb = $color.ColorFromString("$($Library_theme.ShowcaseBrush)") 
        if($rgb.R -gt 200){
          $R = [math]::Round($rgb.R / 2.5)
        }else{
          $R = [math]::Round($rgb.R / 3)
        }
        if($rgb.G -gt 200){
          $G = [math]::Round($rgb.G / 2.5)
        }else{
          $G = [math]::Round($rgb.G / 3)
        }   
        if($rgb.B -gt 200){
          $B = [math]::Round($rgb.B / 2.5)
        }else{
          $B = [math]::Round($rgb.B / 3)
        }                               
        $darken = (Convert-color -RGB ($R),($G),($b))
        $gradientColor2 = "#9C$($darken)"  
        #write-ezlogs "Gradient after darken for $($Library_theme.ColorScheme): $($gradientColor2)" -showtime    
        #}
        $menuitem.IsCheckable = $true
        $menuitem.Header = "$($Library_theme.DisplayName)"
        $menuitem.Uid = "$($Library_theme.BaseColorScheme),$($Library_theme.ColorScheme),$gradientColor2"
        $menuitem.Add_Click({
            try{
              $menutheme = [MahApps.Metro.Theming.MahAppsLibraryThemeProvider]::new()
              $menuthemes = $menutheme.GetLibraryThemes()
              $themeManager = [ControlzEx.Theming.ThemeManager]::new()
              $detectTheme = $thememanager.DetectTheme($synchash.Window)
              $menuColorTable = $($this.uid -split ',')
              write-ezlogs ">>>> Current Theme: $($detectTheme | out-string)" -showtime
              #write-ezlogs ">>>> Gradient2: $($($menuColorTable[2]))" -showtime
              #write-ezlogs ">>>> Items: $($synchash.Change_Theme.items.items | out-string)" -showtime
              $newtheme = $menuthemes | where {$_.Name -eq "$($menuColorTable[0]).$($menuColorTable[1])"}
              $menu_itemname = "Theme_$($menuColorTable[1])"
              write-ezlogs "Title menu icon source  $($synchash.Title_menu_Image.source | out-string)" -showtime
              #$thememanager.ChangeTheme($this, "Dark.Blue",$false)
              if($newtheme){
                $thememanager.RegisterLibraryThemeProvider($newtheme.LibraryThemeProvider)
                $thememanager.ChangeTheme($synchash.Window,$newtheme.Name,$false)
                $thememanager.ChangeTheme($synchash.Audio_Flyout,$newtheme.Name,$false)
                $thememanager.ChangeTheme($synchash.AppHelp_Flyout,$newtheme.Name,$false)
                $thememanager.ChangeTheme($synchash.PlayQueue_Flyout_Grid,$newtheme.Name,$false)
                #$thememanager.ChangeTheme($synchash.Playlists_Flyout,$newtheme.Name,$false)
                #$thememanager.ChangeTheme($synchash.MediaLibrary_Flyout,$newtheme.Name,$false)
                #$thememanager.ChangeTheme($synchash.Audio_Flyout_Control,$newtheme.Name,$false)
                #$thememanager.ChangeTheme($synchash.MediaLibrary_FlyoutControl,$newtheme.Name,$false)
                #$thememanager.ChangeTheme($synchash.Playlists_FlyoutControl,$newtheme.Name,$false)
                $thememanager.ChangeTheme($synchash.MainGrid_Top_TabControl,$newtheme.Name,$false)    
                $thememanager.ChangeTheme($synchash.MainGrid_Bottom_TabControl,$newtheme.Name,$false)   
                $thememanager.ChangeTheme($synchash.Playlist_TabControl,$newtheme.Name,$false) 
                $thememanager.ChangeTheme($synchash.PlayQueue_TreeView,$newtheme.Name,$false) 
                                 
                #$detectTheme = $thememanager.DetectTheme()
                $gradientbrush = New-object System.Windows.Media.LinearGradientBrush
                $gradientbrush.StartPoint = "0.5,0"
                $gradientbrush.EndPoint = "0.5,1"
                $gradientstop1 = New-object System.Windows.Media.GradientStop
                $gradientstop1.Color = "#FF000000"
                $gradientstop1.Offset= "0.0"
                $gradientstop2 = New-object System.Windows.Media.GradientStop
                $gradientstop2.Color = $($menuColorTable[2])
                $gradientstop2.Offset= "0.5"  
                $gradientstop_Collection = New-object System.Windows.Media.GradientStopCollection
                $null = $gradientstop_Collection.Add($gradientstop1)
                $null = $gradientstop_Collection.Add($gradientstop2)
                $gradientbrush.GradientStops = $gradientstop_Collection  
                $synchash.MainGrid.Background = $gradientbrush
                $flyoutgradientbrush = $gradientbrush.clone()
                $flyoutgradientbrush.GradientStops[1].color = "$($flyoutgradientbrush.GradientStops[1].color)" -replace $("$($flyoutgradientbrush.GradientStops[1].color)").Substring(0,3),'#E9' 
                $flyoutgradientbrush.GradientStops[1].Offset = "0.7"
                $synchash.Audio_Flyout.Background = $flyoutgradientbrush
                $synchash.AppHelp_Flyout.Background = $flyoutgradientbrush
                if($synchash.BrewWindow.isVisible){
                  $synchash.BrewWindow.Background = $flyoutgradientbrush
                  $titlebar =  $synchash.Window.TryFindResource('MahApps.Brushes.Accent') 
                  if($titlebar){
                    $synchash.BrewWindow.TitleBarBackground = $titlebar
                  } 
                  $thememanager.ChangeTheme($synchash.BrewWindow,$newtheme.Name,$false) 
                }
                #$synchash.MainGrid_Top_TabControl.UpdateLayout()
                #$synchash.Playlists_FlyoutControl.UpdateDefaultStyle()
                #$synchash.PlayQueue_Flyout.UpdateDefaultStyle()
                #$synchash.PlayQueueFlyout.UpdateDefaultStyle()
                #$synchash.MainGrid_Top_TabControl.UpdateDefaultStyle()
                #$synchash.PlayQueue_TreeView.UpdateDefaultStyle()

                <#                $newcolor = $synchash.window.Resources["IconStyle"].Clone()
                    $newColor.Color = $($newTheme.PrimaryAccentColor)
                $synchash.window.Resources["IconStyle"] = $newColor#>
                $newRow = New-Object PsObject -Property @{
                  'Name' = "$($menuColorTable[0]).$($menuColorTable[1])"
                  'Menu_item' = "Theme_$($menuColorTable[1])"
                  'GridGradientColor1' = '#FF000000'
                  'GridGradientColor2' = $($menuColorTable[2])
                  'PrimaryAccentColor' = $newTheme.PrimaryAccentColor
                }
                Add-Member -InputObject $thisApp.Config -Name 'Current_Theme' -Value $newRow -MemberType NoteProperty -Force 
                foreach($item in $synchash.Change_Theme.items.items){
                  if($item.Uid -eq $this.uid){
                    $item.isChecked = $true
                  }else{
                    $item.isChecked = $false
                  }
                }    
                try{
                  $thisapp.config | Export-Clixml -Path $thisapp.config.Config_Path -Force -Encoding UTF8
                }catch{
                  write-ezlogs "An exception occurred saving settings to config file: $($thisapp.config.Config_Path)" -CatchError $_ -showtime
                } 
              }else{
                write-ezlogs "Couldnt find new theme - $($Library_theme  | out-string) - $($this | out-string)" -showtime -warning
              }
            }catch{
              write-ezlogs "An exception occurred in $($menuitem.Name) click event" -CatchError $_ -showtime
            } 
        })
        if($Library_theme.BaseColorScheme -eq 'Dark' -and $synchash.Theme_Dark.items -notcontains $menuitem){
          #write-ezlogs " | Adding new theme: $($menuitem.Name)"
          $null = $synchash.Theme_Dark.items.add($menuitem)
        }elseif($Library_theme.BaseColorScheme -eq 'Light' -and $synchash.Theme_Light.items -notcontains $menuitem){
          #write-ezlogs " | Adding new theme: $($menuitem.Name)"
          $null = $synchash.Theme_Light.items.add($menuitem)
        }
      }        
      if($thisApp.Config.Current_Theme -ne $null -and $thisApp.Config.Current_Theme.Name){
        $theme = [MahApps.Metro.Theming.MahAppsLibraryThemeProvider]::new()
        $themes = $theme.GetLibraryThemes()
        $themeManager = [ControlzEx.Theming.ThemeManager]::new()
        $detectTheme = $thememanager.DetectTheme($synchash.Window)
        if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> Current Theme: $($detectTheme | out-string)" -showtime}
        $newtheme = $themes | where {$_.Name -eq $thisApp.Config.Current_Theme.Name}
        if($newtheme){
          #$thememanager.ChangeTheme($this, "Dark.Blue",$false)
          foreach($item in $synchash.Change_Theme.items.items){
            if($item.name -eq $thisApp.Config.Current_Theme.Menu_item){
              $item.isChecked = $true
            }else{
              $item.isChecked = $false
            }
          }
          $thememanager.RegisterLibraryThemeProvider($newtheme.LibraryThemeProvider)
          $thememanager.ChangeTheme($synchash.Window,$newtheme.Name,$false)
          $thememanager.ChangeTheme($synchash.Audio_Flyout,$newtheme.Name,$false)
          $thememanager.ChangeTheme($synchash.AppHelp_Flyout,$newtheme.Name,$false)
          #$detectTheme = $thememanager.DetectTheme()
          $gradientbrush = New-object System.Windows.Media.LinearGradientBrush
          $gradientbrush.StartPoint = "0.5,0"
          $gradientbrush.EndPoint = "0.5,1"
          $gradientstop1 = New-object System.Windows.Media.GradientStop
          $gradientstop1.Color = $thisApp.Config.Current_Theme.GridGradientColor1
          $gradientstop1.Offset= "0.0"
          $gradientstop2 = New-object System.Windows.Media.GradientStop
          $gradientstop2.Color = $thisApp.Config.Current_Theme.GridGradientColor2
          $gradientstop2.Offset= "0.5"  
          $gradientstop_Collection = New-object System.Windows.Media.GradientStopCollection
          $null = $gradientstop_Collection.Add($gradientstop1)
          $null = $gradientstop_Collection.Add($gradientstop2)
          $gradientbrush.GradientStops = $gradientstop_Collection  
          $synchash.MainGrid.Background = $gradientbrush
          $flyoutgradientbrush = $gradientbrush.clone()
          $flyoutgradientbrush.GradientStops[1].color = "$($flyoutgradientbrush.GradientStops[1].color)" -replace $("$($flyoutgradientbrush.GradientStops[1].color)").Substring(0,3),'#E9' 
          $flyoutgradientbrush.GradientStops[1].Offset = "0.7"
          $synchash.Audio_Flyout.Background = $flyoutgradientbrush
          $synchash.AppHelp_Flyout.Background = $flyoutgradientbrush  
          <#          $newcolor = $synchash.window.Resources["IconStyle"].Clone()
              $newColor.Color = $($newTheme.PrimaryAccentColor)
          $synchash.window.Resources["IconStyle"] = $newColor #>      
        }
       
      } 
    }catch{
      write-ezlogs "An exception occurred in Window Add_Loaded event" -showtime -catcherror $_
    }
    if($PlayMedia -or $MediaFile){
      try{
        write-ezlogs "#### Play Media switch provided ####" -showtime -color yellow -linesbefore 1
        write-ezlogs " |  Media file: $MediaFile" -showtime
        if(([system.io.file]::Exists($MediaFile) -and $MediaFile -match $media_pattern) -or [system.io.directory]::Exists($MediaFile)){
          Import-Media -Media_Path $MediaFile -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory  -thisApp $thisapp
        }else{
          write-ezlogs "Provided media from command line is not valid or supported!" -showtime -warning
        } 
      }catch{
        write-ezlogs "An exception occurred importing provided media from command line on startup: $MediaFile" -showtime -catcherror $_
      }
    }
    if($brynePlayer){  
      try{
        $syncHash.MainGrid_Background_Image_Source.Source = "$($Current_Folder)\\ByrnePlayer\DavidByrneTour.png"
        $syncHash.MainGrid_Background_Image_Source.Stretch = "UniformToFill"
        $syncHash.MainGrid_Background_Image_Source.Opacity = 0.25
        $syncHash.MainGrid_Background_Image_Source.Effect.Radius = "5"
        $syncHash.MainGrid_Background_Image_Source_transition.content = $syncHash.MainGrid_Background_Image_Source 
      }catch{
        write-ezlogs "An exception occurred setting main background for Byrne Player: $($Current_Folder)\\ByrnePlayer\DavidByrneTour.png" -showtime -catcherror $_
      }
    }
    #Set-WindowBlur -MainWindowHandle (Get-process -Id $PID).MainWindowHandle -Acrylic -Color 0xFF0000 -Transparency 50
    #$this.clip.Rect = "0,0,$($this.Width),$($this.Height)"
    $null = [System.GC]::GetTotalMemory($true)
})

$synchash.Window.add_SizeChanged({    
    try{
      $PrimaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen    
      if($this.WindowState -eq 'Maximized'){
        #$this.clip.Rect = "0,0,$($PrimaryScreen.WorkingArea.Width),$($PrimaryScreen.WorkingArea.Height)"
      }else{
        #$this.clip.Rect = "0,0,$($this.Width),$($this.Height)"
      }
      if($thisApp.Config.Verbose_Logging){
        Write-ezlogs "Main Window Width: $($synchash.Window.width)" -showtime
        Write-ezlogs "Primary Screen: $($PrimaryScreen | Out-String)" -showtime
      }            
    }catch{
      write-zlogs 'An exception occurred in window sizechanged event' -showtime -catcherror $_
    }
})
#Window Resize Event
$synchash.Window.Add_StateChanged({
    try{     
      if($this.WindowState -eq 'Maximized'){
        #$PrimaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
        #$PrimaryScreen.WorkingArea.Height
        #$synchash.Window.clip.Rect = "0,0,$($PrimaryScreen.WorkingArea.Width),$($PrimaryScreen.WorkingArea.Height)"
        #Write-ezlogs "Width: $($synchash.Window.clip | out-string)"
        #Write-ezlogs "Width: $($PrimaryScreen | out-string)"
      }
    }catch{
      write-zlogs "An exception occurred in window sizechanged event" -showtime -catcherror $_
    }      
}) 
$synchash.Window.add_MouseLeftButtonDown({
    $sender = $args[0]
    [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]
    try{
      #write-ezlogs "$($e | out-string)"
      if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed -and $e.RoutedEvent.Name -eq 'MouseLeftButtonDown')
      {
        $synchash.Window.DragMove()
        $e.handled = $true
      }
    }catch{
      write-ezlogs "An exception occurred in Window MouseLeftButtonDown event" -showtime -catcherror $_
    }
})
$synchash.Window_Title_DockPanel.add_MouseLeftButtonDown({
    $sender = $args[0]
    [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]
    try{
      if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed -and $e.RoutedEvent.Name -eq 'MouseLeftButtonDown')
      {
        $synchash.Window.DragMove()
        $e.handled = $true
      }
    }catch{
      write-ezlogs "An exception occurred in Window_Title_DockPanel MouseLeftButtonDown event" -showtime -catcherror $_
    }
})
#---------------------------------------------- 
#endregion Main Window Event Handlers
#----------------------------------------------



#---------------------------------------------- 
#region Feedback
#----------------------------------------------
$synchash.Submit_Feedback.Add_Click({
    Show-FeedbackForm -PageTitle 'Submit Feedback/Issues' -Logo "$($thisapp.Config.Current_Folder)\\Resources\\MusicPlayerFilltest.ico" -thisScript $thisScript -thisApp $thisapp -Verboselog:$thisapp.Config.Verbose_logging -synchash $synchash
}.GetNewClosure())
#---------------------------------------------- 
#endregion Feedback
#----------------------------------------------


#---------------------------------------------- 
#region FullScreen Button
#----------------------------------------------
#Fullscreen Window
[System.Windows.RoutedEventHandler]$FullScreen_Command = {
  param($sender)
  $Media = $_.OriginalSource.DataContext
  #write-ezlogs "Media $($Media | out-string)"
  if(!$Media.url){$Media = $sender.tag}
  if(!$Media.url){$Media = $sender.tag.Media}
  $ScreenBounds = [Windows.Forms.SystemInformation]::VirtualScreen
  $PrimaryMonitor = [System.Windows.Forms.Screen]::PrimaryScreen
  try{
    if(!$synchash.FullScreen_Viewer.isVisible){
      write-ezlogs 'Attempting to open fullscreen view' -showtime
      #$xcloud_window = New-object MahApps.Metro.Controls.MetroWindow
      [xml]$Xamlfullscreen_window = [System.IO.File]::ReadAllText("$($Current_folder)\\Views\\FullScreenViewer.xaml").replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml") 
      $Childreader = (New-Object System.Xml.XmlNodeReader $Xamlfullscreen_window)
      $FullScreen_windowXaml   = [Windows.Markup.XamlReader]::Load($Childreader)  
      $Xamlfullscreen_window.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {$synchash."$($_.Name)" = $FullScreen_windowXaml.FindName($_.Name)}
      #write-ezlogs "##########BeforeFull: $($synchash.VideoView_Grid | out-string)" 
      #write-ezlogs "Row0 $($synchash.VLC_Grid_Row0 | out-string)"
      #write-ezlogs "Row1 $($synchash.VLC_Grid_Row1 | out-string)" 
      #write-ezlogs "Row2 $($synchash.VLC_Grid_Row2 | out-string)"  
      
      if($synchash.VLC_Grid.children -contains $synchash.VideoView){
        $null = $synchash.VLC_Grid.children.Remove($synchash.VideoView)
      }
      if($synchash.VLC_Grid.children -contains $synchash.VideoView_Flyout){
        $null = $synchash.VLC_Grid.Remove($synchash.VideoView_Flyout)
      }
      #$synchash.VideoView_Grid.InvalidateMeasure() 
      #$synchash.VideoView_Grid.updatelayout()    
      $synchash.MediaPlayer_Grid.updateLayout()  
      if($synchash.FullScreen_VLC_Grid.children -notcontains $synchash.VideoView){
        $null = $synchash.FullScreen_VLC_Grid.AddChild($synchash.VideoView)
      }

      if($synchash.VideoView_Grid.children -notcontains $synchash.VideoView_Flyout){
        $null = $synchash.VideoView_Grid.AddChild($synchash.VideoView_Flyout)
      }
      $synchash.VideoView_Flyout.Visibility = 'Visible'
      $synchash.VideoView_Grid.updateLayout() 
      $synchash.FullScreen_Viewer.icon = "$($thisapp.Config.Current_folder)\\Resources\\MusicPlayerFilltest.ico"  
      $synchash.FullScreen_Viewer.icon.Freeze()
      $synchash.FullScreen_Title_menu_Image.Source = "$($thisapp.Config.Current_folder)\\Resources\\MusicPlayerFilltest.ico"
      $synchash.FullScreen_Title_menu_Image.width = '18'  
      $synchash.FullScreen_Title_menu_Image.Height = '18'
      $synchash.FullScreen_Viewer.Title = "$($thisScript.Name) - Version: $($thisScript.Version) - $($synchash.Now_Playing_Label.Content)"  
      $synchash.FullScreen_Viewer.IsWindowDraggable = 'True'
      $synchash.FullScreen_Viewer.LeftWindowCommandsOverlayBehavior = 'HiddenTitleBar' 
      $synchash.FullScreen_Viewer.RightWindowCommandsOverlayBehavior = 'HiddenTitleBar'
      $synchash.FullScreen_Viewer.ShowTitleBar = $true
      $synchash.FullScreen_Viewer.UseNoneWindowStyle = $false
      $synchash.FullScreen_Viewer.WindowStyle = 'none'
      $synchash.FullScreen_Viewer.IgnoreTaskbarOnMaximize = $true
      $synchash.FullScreen_Viewer.WindowState = 'Maximized' 
      $synchash.FullScreen_Viewer.add_closing({
          try{
            #$mediaGridToCopyBack = $synchash.VideoView_Grid
            #$synchash.VideoView.content = $Null
            #$MediaPlayertoCopyBack = $synchash.VideoView           
            #$MediaPlayerFlyouttoCopyBack = $synchash.VideoView_Flyout
            #$synchash.VideoView_Flyout.items.Remove($synchash.VideoViewFlyout)
            #$synchash.VideoView_Grid.children.Remove($synchash.VideoView_Flyout)
            # $synchash.ChildWindow.close()
            # $synchash.VideoView.content = $null
            if($synchash.VideoView_Grid.children -contains $synchash.VideoView_Flyout){
              $null = $synchash.VideoView_Grid.children.Remove($synchash.VideoView_Flyoutd)
            }

            if($synchash.FullScreen_VLC_Grid.children -contains $synchash.VideoView){
              $null = $synchash.FullScreen_VLC_Grid.children.Remove($synchash.VideoView)
            }
            #$videoView = [LibVLCSharp.WPF.VideoView]::new()
            #$VideoView.Name = 'VideoView'
            #$VideoView.MediaPlayer = $synchash.VideoView.MediaPlayer                      
            $synchash.VLC = $synchash.VideoView.MediaPlayer         
            #$MediaPlayertoCopyBack.AddChild($mediaGridToCopyBack)
            <#            $NewFlyout = New-object MahApps.Metro.Controls.FlyoutsControl
                $newflyout.name = 'VideoView_Flyout'
                $newflyout.HorizontalAlignment="Stretch" 
                $newflyout.Background="#02000000"
                $newflyout.OpacityMask = $synchash.Window.TryFindResource('SeparatorGradient')  
                $newflyout.items.add($synchash.VideoViewFlyout)
                $newflyout.VerticalAlignment="Stretch"
            $synchash.VideoView_Flyout = $newflyout#>           
            #$mediaGridToCopyBack.addChild($synchash.VideoView_Flyout)
            #$mediaGridToCopyBack.AddChild($MediaPlayerFlyouttoCopyBack)
            #$synchash.VideoView_Flyout = $MediaPlayerFlyouttoCopyBack       
            #$MediaPlayertoCopyBack.AddChild($mediaGridToCopyBack)            
            #$null = $synchash.VideoView.AddHandler([System.Windows.Controls.Button]::MouseEnterEvent,$VideoViewMouseEnter)
            #$null = $synchash.VideoView.AddHandler([System.Windows.Controls.Button]::MouseLeaveEvent,$VideoViewMouseLeave)        
       
            if($synchash.VLC_Grid.Children -notcontains $synchash.VideoView_Flyout){
              $null = $synchash.VLC_Grid.Children.Add($synchash.VideoView_Flyout) 
            }   
            if($synchash.VLC_Grid.Children -notcontains $synchash.VideoView){
              $null = $synchash.VLC_Grid.Children.Add($synchash.VideoView) 
            }    
            $synchash.VideoView_Flyout.Visibility = 'Hidden'                   
            $synchash.VLC_Grid.updatelayout()   
            $synchash.MediaPlayer_Grid.updateLayout() 
            #$synchash.VideoView_Grid = $mediaGridToCopyBack
            #$synchash.VideoView_Grid.AddChild($synchash.VideoView_Flyout)                     
            #$null = $mediaGridToCopyBack.AddHandler([System.Windows.Controls.Button]::MouseEnterEvent,$VideoViewMouseEnter)
            #$null = $mediaGridToCopyBack.AddHandler([System.Windows.Controls.Button]::MouseLeaveEvent,$VideoViewMouseLeave)                    
            #$synchash.VideoView_Grid.updatelayout()            
            #$null = $synchash.Remove($this)
          }catch{
            write-ezlogs "An exception occurred in FullScreen_Viewer.add_closing" -showtime -catcherror $_
          }
      })
      $synchash.FullScreen_Viewer.add_closed({

          <#          if($synchash.VLC_Grid.children -contains $synchash.VideoView){
              $null = $synchash.VLC_Grid.children.Remove($synchash.VideoView)
              }
              $videoView = [LibVLCSharp.WPF.VideoView]::new()
              $videoView.MediaPlayer = $synchash.videoview.MediaPlayer
              $videoview.Name = "VideoView"
              $synchash.VideoView = $videoView
              [xml]$XamlChildWindow_window = [System.IO.File]::ReadAllText("$($thisApp.Config.Current_folder)\\Views\\ChildWindow.xaml").replace('Views/Styles.xaml',"$($thisApp.Config.Current_folder)`\Views`\Styles.xaml")
              $Childreader = (New-Object System.Xml.XmlNodeReader $XamlChildWindow_window)
              $DialogForm   = [Windows.Markup.XamlReader]::Load($Childreader) 
              $XamlChildWindow_window.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {$synchash."$($_.Name)" = $DialogForm.FindName($_.Name)}
              $synchash.ChildWindow.AllowMove = $true      
              $synchash.VideoView.addchild($synchash.ChildWindow)
              $synchash.VideoView.Visibility="Visible"
              #$synchash.VideoView.SetValue([System.Windows.Controls.Grid]::RowProperty,'0')
              $synchash.videoview.Background="#01000000"
              $synchash.VideoView.updatelayout() 
          $synchash.vlc = $synchash.VideoView.MediaPlayer#>
            
          $synchash.VLC_Grid.updatelayout()   
          #$synchash.MediaPlayer_Grid.updateLayout()    
          # $synchash.ChildWindow.isOpen = $true
          # $synchash.vlc.Play()
          #$synchash.videoview.Focus()
          $synchash.VideoView_Grid.updatelayout()
          #$synchash.Window.updatelayout()
          $synchash.Window.Activate()
          #$synchash.VideoViewFlyout.Visibility = 'Visible'
          #$synchash.VideoView_Flyout.Visibility = 'Visible'
          #$synchash.VideoView_Flyout.Focus()   
          #$synchash.VLC_Grid.UpdateLayout()
          #$synchash.childwindow.isOpen=$true
          #$synchash.VideoView_Flyout.UpdateLayout()  
          #$synchash.VideoViewFlyout.IsOpen = $true  
          # $synchash.VideoViewFlyout.IsOpen = $true
          #write-ezlogs "Flyout $($synchash.VideoViewFlyout | out-string)"    
          #write-ezlogs "##########AFTER: $($synchash.VideoView_Grid | out-string)"  
          #write-ezlogs "Row0 $($synchash.VLC_Grid_Row0 | out-string)"
          #write-ezlogs "Row1 $($synchash.VLC_Grid_Row1 | out-string)" 
          #write-ezlogs "Row2 $($synchash.VLC_Grid_Row2 | out-string)"   
         
      })      
      $synchash.FullScreen_Viewer.Show()   
    }else{
      $synchash.FullScreen_Viewer.close()
    }
  }catch{write-ezlogs 'Exception occurred opening new webview2 window for FullScreen View' -showtime -catcherror $_}                            
}.GetNewClosure()
$null = $synchash.FullScreen_Player_Button.AddHandler([Windows.Controls.Button]::ClickEvent,$FullScreen_Command)
#---------------------------------------------- 
#endregion FullScreen Button
#----------------------------------------------

#---------------------------------------------- 
#region Shuffle Options
#----------------------------------------------
if($thisapp.config.Shuffle_Playback){
  #$synchash.Shuffle_Playback_Toggle.isOn = $true
  $synchash.Shuffle_Icon.Kind = 'ShuffleVariant'
  $synchash.Shuffle_Playback_Button.ToolTip = 'Shuffle Enabled'
}else{
  $synchash.Shuffle_Icon.Kind = 'ShuffleDisabled'
  $synchash.Shuffle_Playback_Button.ToolTip = 'Shuffle Disabled'
  #$synchash.Shuffle_Playback_Toggle.isOn = $false
}

[System.EventHandler]$synchash.Shuffle_Playback_tray_command = {
  param($sender)
  Set-Shuffle -thisApp $thisApp -synchash $synchash
}
[System.Windows.RoutedEventHandler]$synchash.Shuffle_Playback_Button_command = {
  param($sender)
  Set-Shuffle -thisApp $thisApp -synchash $synchash
}
$null = $synchash.Shuffle_Playback_Button.AddHandler([Windows.Controls.Button]::ClickEvent,$synchash.Shuffle_Playback_Button_command)
#---------------------------------------------- 
#endregion Shuffle Options
#----------------------------------------------

#---------------------------------------------- 
#region Chat View
#----------------------------------------------
Add-Member -InputObject $thisapp.config -Name 'Chat_View' -Value $false -MemberType NoteProperty -Force
$synchash.Chat_Icon.Kind = 'ChatRemove'
#$synchash.chat_WebView2.Visibility = 'Hidden'
$synchash.chat_column.Width = '*'
$synchash.Chat_View_Button.isEnabled = $false
$synchash.Chat_View_Button.add_Click({
    try{
      #TODO: THIS NEEDS REPLACING
      if($synchash.chat_WebView2.Visibility -eq 'Visible'){
        $synchash.Chat_Icon.Kind = 'ChatRemove'
        $synchash.chat_WebView2.Visibility = 'Hidden'
        $synchash.chat_column.Width = '*'
        $synchash.chat_column.MinWidth = ''
        #$synchash.PlayQueue_Flyout_Grid.updatelayout()
        #$synchash.PlayQueue_TreeView.updatelayout()
        #$synchash.PlayQueue_TreeView.width = $synchash.PlayQueue_TreeView.Actualwidth + 140

        #$synchash.playlist_column.Width = '*'
        #$synchash.playlist_column.width = ("$($synchash.PlayQueue_TreeView.Actualwidth)" -replace '\*') + (("$($synchash.chat_column.width)" -replace '\*')/2) 
        #$synchash.playlist_column.width = "100*"
        #write-ezlogs "PlayQueue_Flyout_Grid: $($synchash.PlayQueue_Flyout_Grid.Actualwidth)"
        Add-Member -InputObject $thisapp.config -Name 'Chat_View' -Value $false -MemberType NoteProperty -Force
      }elseif($synchash.chat_WebView2.Visibility -eq 'Hidden'){
        $synchash.Chat_Icon.Kind = 'Chat'
        $synchash.chat_WebView2.Visibility = 'Visible'
        $synchash.chat_column.Width = '400*'
        $synchash.chat_column.MinWidth = '400'
        #$synchash.PlayQueue_Flyout_Grid.updatelayout()
        #$synchash.PlayQueue_TreeView.updatelayout()
        #$synchash.PlayQueue_TreeView.width = $synchash.PlayQueue_TreeView.Actualwidth - 120
        #$synchash.playlist_column.Width = '600*'
        #$synchash.playlist_column.width = "50*"
        #$synchash.PlayQueue_TreeView.width = $synchash.PlayQueue_TreeView.Actualwidth - $($synchash.chat_WebView2.Actualwidth)
        #write-ezlogs "PlayQueue_Flyout_Grid: $($synchash.PlayQueue_Flyout_Grid.Actualwidth)"
        #write-ezlogs "PlayQueue_TreeView actual width: $($synchash.PlayQueue_TreeView.Actualwidth)" -showtime
        #write-ezlogs "playlist_column width: $($synchash.playlist_column.Actualwidth)" -showtime
        #write-ezlogs "cat_column width: $($synchash.chat_column.width)" -showtime        
        #$synchash.playlist_column.width = ("$($synchash.PlayQueue_TreeView.Actualwidth)" -replace '\*') - (("$($synchash.chat_column.width)" -replace '\*')/2) 
        #write-ezlogs "AFTER PlayQueue_TreeView width: $($synchash.PlayQueue_TreeView.Actualwidth)" -showtime
        Add-Member -InputObject $thisapp.config -Name 'Chat_View' -Value $true -MemberType NoteProperty -Force
      }
    }catch{
      write-ezlogs "An exception occurred in Chat_View_Button click event" -showtime -catcherror $_
    }    
})
<#$synchash.Chat_View.add_Checked({
    Add-Member -InputObject $thisApp.config -Name "Chat_View" -Value $true -MemberType NoteProperty -Force
    $synchash.chat_WebView2.Visibility = 'Visible'
    $synchash.chat_column.Width = "400"   
    #$synchash.chat_WebView2.Reload()   
    })
    $synchash.Chat_View.add_UnChecked({
    Add-Member -InputObject $thisApp.config -Name "Chat_View" -Value $false -MemberType NoteProperty -Force
    $synchash.chat_WebView2.Visibility = 'Hidden'
    $synchash.chat_column.Width = "*"   
    })
#>#---------------------------------------------- 
#endregion Chat View
#----------------------------------------------

#---------------------------------------------- 
#region Hidden Refresh Checkbox
#----------------------------------------------
$synchash.Refresh_Playlist_Hidden_Checkbox.add_Checked({
    try{
      Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -startup -synchash $synchash -thisApp $thisapp
      $synchash.Refresh_Playlist_Hidden_Checkbox.IsChecked = $false
    }catch{
      write-ezlogs 'An exception occurred executing Get-playlists from hidden checkbox' -showtime -catcherror $_
      $synchash.Refresh_Playlist_Hidden_Checkbox.IsChecked = $false
    }
}.GetNewClosure())
#---------------------------------------------- 
#endregion Hidden Refresh Checkbox
#----------------------------------------------

#---------------------------------------------- 
#region Spicetify Options
#----------------------------------------------
$synchash.Spicetify_textblock.text = ''
$synchash.Spicetify_transitioningControl.content = ''
$pode_server_scriptblock = { 
  try{
    if(!(Get-command -Module Pode)){         
      try{  
        write-ezlogs ">>> Importing Module PODE" -showtime
        Import-Module "$($thisApp.Config.Current_folder)\Modules\Pode\2.6.2\Pode.psm1" -Force    
      }catch{
        write-ezlogs "An exception occurred Importing required module Pode" -showtime -catcherror $_
      }     
    }   
    if((NETSTAT.EXE -n) | where {$_ -match '127.0.0.1:8974'}){Invoke-RestMethod -Uri 'http://127.0.0.1:8974/CLOSEPODE' -UseBasicParsing -ErrorAction SilentlyContinue}    
    Start-PodeServer -Name 'EZT-MediaPlayer_PODE' -Threads 2  {
      write-ezlogs '[Start-PodeServer] >>>> Starting PodeServer EZT-MediaPlayer_PODE on http://127.0.0.1:8974' -showtime -color cyan
      foreach($module in $Script_Modules){Import-Module $module}    
      Add-PodeEndpoint -Address 127.0.0.1 -Port 8974 -Protocol Ws -PassThru -Force
      Add-PodeEndpoint -Address 127.0.0.1 -Port 8974 -Protocol Http -PassThru -Force
      Add-PodeRoute -Method Get -Path '/PLAY' -PassThru -ScriptBlock {
        Send-PodeSignal -Value 'PLAY'
        #write-ezlogs ">>>> Spotify webevent sent [PLAY]" -showtime -logfile $logfile -enablelogs
      }    
      Add-PodeRoute -Method Get -Path '/PAUSE' -PassThru -ScriptBlock {
        Send-PodeSignal -Value 'PAUSE'
        #write-ezlogs ">>>> Spotify webevent sent [PAUSE]" -showtime -logfile $logfile -enablelogs
      }
      Add-PodeRoute -Method Get -Path '/PLAYURI' -PassThru -ScriptBlock {
        $logfile = $using:logfile
        $thisapp = $using:thisapp
        $synchash = $using:synchash
        $URI = ($WebEvent.Request.URL -split '\?')[1]
        if($URI -match 'spotify:'){Send-PodeSignal -Value $URI}
        #write-ezlogs ">>>> Spotify webevent sent [PLAYURI]: $($URI | out-string)" -showtime -logfile $logfile -enablelogs
      }    
      Add-PodeRoute -Method Get -Path '/CLOSEPODE' -PassThru -ScriptBlock {
        #write-ezlogs ">>>> Spotify webevent sent [CLOSEPODE]: Close-PodeServer" -showtime -logfile $logfile -enablelogs
        Close-PodeServer
      }    
      Add-PodeSignalRoute -Path '/' -ScriptBlock {        
        $spicetify = ($SignalEvent.data.message | ConvertFrom-Json)
        $logfile = $using:logfile
        $thisapp = $using:thisapp
        $synchash = $using:synchash
        $thisapp.Config.Spicetify = $spicetify
        #write-ezlogs ">>>> Spotify Playing: $($thisApp.Config.Spicetify | out-string)" -showtime -logfile $logfile -enablelogs
        # write-ezlogs "Spicetify: $($spicetify | out-string)" -showtime
      }            
    } 
  }catch{
    write-ezlogs 'An exception occurred in pode_server_scriptblock' -showtime -catcherror $_
    $thisapp.config.Use_Spicetify = $false
  }
  if($error){
    write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
  }  
}
if($thisapp.config.Use_Spicetify){
  $synchash.Spicetify_Toggle.ison = $true
  $synchash.Spicetify_Apply_Button.IsEnabled = $true
  $synchash.Spicetify_Remove_Button.IsEnabled = $false
  $thisapp.Config.Spicetify = ''
  Add-Member -InputObject $thisapp.config -Name 'PODE_SERVER_ACTIVE' -Value $true -MemberType NoteProperty -Force
  $Variable_list = Get-Variable | where {$_.Options -notmatch 'ReadOnly' -and $_.Options -notmatch 'Constant'}
  Start-Runspace -scriptblock $pode_server_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -Load_Modules -Script_Modules $Script_Modules -runspace_name 'PODE_SERVER_RUNSPACE' -thisApp $thisApp -synchash $synchash
}else{
  Add-Member -InputObject $thisapp.config -Name 'PODE_SERVER_ACTIVE' -Value $false -MemberType NoteProperty -Force
  $synchash.Spicetify_Toggle.ison = $false
  $synchash.Spicetify_Apply_Button.IsEnabled = $false
  $synchash.Spicetify_Remove_Button.IsEnabled = $true
}

$synchash.Spicetify_Toggle.Add_Toggled({ 
    $synchash.Spicetify_textblock.text = ''
    $synchash.Spicetify_transitioningControl.content = ''     
    if($synchash.Spicetify_Toggle.isOn){
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
      $Button_Settings.AffirmativeButtonText = 'Yes'
      $Button_Settings.NegativeButtonText = 'No'  
      $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Spicetify Requires Admin Permissions","Using the Spicetify option requires this app to be run as administrator. Once enabled, and upon each startup, the app will automatically attempt to restart as admin if it is not currently`n`nDo you wish to continue?",$okandCancel,$Button_Settings)    
      if($result -eq 'Affirmative'){
        $synchash.Spicetify_textblock.text = "IMPORTANT! You must click 'Apply to Spotify' to complete Spicetify setup and customizations"
        $synchash.Spicetify_Apply_Button.IsEnabled = $true
        $synchash.Spicetify_Remove_Button.IsEnabled = $false
      }else{
        write-ezlogs "User did not wish to proceed, disabling Spicetify option" -showtime -warning
        $synchash.Spicetify_Toggle.isOn = $false
      }    
    }else{
      $synchash.Spicetify_textblock.text = "IMPORTANT! You must click 'Remove from Spotify' to complete the removal of Spicetify customizations"
      $synchash.Spicetify_Apply_Button.IsEnabled = $false
      $synchash.Spicetify_Remove_Button.IsEnabled = $true
    }
    $synchash.Spicetify_textblock.foreground = 'Orange'
    $synchash.Spicetify_textblock.FontSize = 14
    $synchash.Spicetify_transitioningControl.content = $synchash.Spicetify_textblock        

})
$synchash.Spicetify_Button.Add_Click({ 
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.Spicetify_Toggle.content
    Update-HelpFlyout -content 'Enabling this will use Spicetify to customize the Spotify client to allow direct control of playback and status' -FontWeight bold -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging  -synchash $synchash
    Update-HelpFlyout -content 'PURPOSE' -FontWeight bold -TextDecorations Underline -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'Using Spicetify allows more consistent, responsive and reliable control of the Spotify client. Without Spicetify, control of Spotify is handled using Spotify Web API calls, since Spotify no longer supports direct control of the Windows app (programmically). While this works, it can be less reliable, as a web API call is needed anytime a command needs to be sent or when getting status. This can result in a delay between issuing a command and Spotify responding or sometimes it can fail alltogether.' -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'IMPORTANT' -FontWeight bold -TextDecorations Underline -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content "Spicetify makes direct modifications to the Spotify client, injecting custom code. Highly recommend visiting https://spicetify.app/ to read more about what Spicetify does. If you are not comfortable with these modifications, leave this option disabled. `nIf you wish to revert these changes, see the option 'Revert/Remove Spicetify changes to Spotify'" -FontWeight bold -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'Updates to the Spotify client may break the customizations made by Spicetify. If this happens, EZT-MediaPlayer will warn you and revert to using the Spotify API. If that happens, you can re-enable this option to reapply the customizations' -FontWeight bold -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'MORE INFO' -FontWeight bold -TextDecorations Underline -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'Spicetify is used to inject a customized version of the Webnowplaying extension which originally was designed to allow Spotify to work with Rainmeter. EZT-MediaPlayer uses the PowerShell module PODE to create a local Websocket server (127.0.0.1) on port 8974. The customized Webnowplaying connects to this Websocket to relay Spotify playback data and accept commands from EZT-Mediaplayer, such as Play/Pause, next, previous, repeat, loop...etc. This allows controlling Spotify without sending commands over the web, which is more reliable and faster.' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
})


$synchash.Spicetify_Apply_Button.Add_Click({ 
    try{
      $synchash.Spicetify_apply_status = $Null
      $synchash.Spotify_install_status = $Null
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
      $Button_Settings.AffirmativeButtonText = 'Yes'
      $Button_Settings.NegativeButtonText = 'No'  
      $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Apply Spicetify?","Are you sure you wish to apply Spicetify customizations to Spotify?`nA backup of Spotify's state is made so you can always restore/remove customizations later",$okandCancel,$Button_Settings)
      if($result -eq 'Affirmative'){
        $synchash.window.hide()
        Start-SplashScreen -SplashTitle $thisScript.Name -SplashMessage 'Applying Spicetify customizations...' -Splash_More_Info 'Please Wait' -thisScript $thisScript -current_folder $Current_folder -log_file $logfile -Script_modules $Script_Modules        
        $Spicetify = Enable-Spicetify -thisApp $thisApp -synchash $synchash
        if($synchash.Spicetify_apply_status){
          $synchash.Spicetify_Toggle.ison = $false
          Add-Member -InputObject $thisapp.config -Name 'Use_Spicetify' -Value $false -MemberType NoteProperty -Force
          $synchash.Spicetify_textblock.text = '[ERROR] An error was encountered when applying Spicetfiy! Spicetify will be disabled. Please refer to the logs! You can attempt to download and install an older version of Spotify as a workaround'
          $synchash.Spicetify_textblock.foreground = 'Tomato'
          $synchash.Spicetify_textblock.FontSize = 14
          $synchash.Spicetify_transitioningControl.content = $synchash.Spicetify_textblock
        }elseif($synchash.Spotify_install_status -eq 'NotInstalled'){
          $synchash.Spicetify_Toggle.ison = $false
          Add-Member -InputObject $thisapp.config -Name 'Use_Spicetify' -Value $false -MemberType NoteProperty -Force
          $synchash.Spicetify_textblock.text = '[ERROR] Unable to find Spotify installation. Spicetify requires installing Spotify, cannot continue!'
          $synchash.Spicetify_textblock.foreground = 'Tomato'
          $synchash.Spicetify_textblock.FontSize = 14
          $synchash.Spicetify_transitioningControl.content = $synchash.Spicetify_textblock              
        }elseif($synchash.Spotify_install_status -eq 'StoreVersion'){
          $synchash.Spicetify_Toggle.ison = $false
          Add-Member -InputObject $thisapp.config -Name 'Use_Spicetify' -Value $false -MemberType NoteProperty -Force
          $synchash.Spicetify_textblock.text = "[ERROR] You are using Spotify Windows Store version, which is not supported with Spicetify.`nYou must remove the Windows Store version and install the normal version!"
          $synchash.Spicetify_textblock.foreground = 'Tomato'
          $synchash.Spicetify_textblock.FontSize = 14
          $synchash.Spicetify_transitioningControl.content = $synchash.Spicetify_textblock              
        }else{
          Add-Member -InputObject $thisapp.config -Name 'Use_Spicetify' -Value $true -MemberType NoteProperty -Force
          Add-Member -InputObject $thisapp.config -Name 'PODE_SERVER_ACTIVE' -Value $true -MemberType NoteProperty -Force     
          $synchash.Spicetify_Toggle.ison = $true       
          $Variable_list = Get-Variable | where {$_.Options -notmatch 'ReadOnly' -and $_.Options -notmatch 'Constant'}
          if(!(NETSTAT.EXE -n) | where {$_ -match '127.0.0.1:8974'}){
            Start-Runspace -scriptblock $pode_server_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -Load_Modules -Script_Modules $Script_Modules -runspace_name 'PODE_SERVER_RUNSPACE' -thisApp $thisApp -synchash $synchash
          }        
          $synchash.Spicetify_textblock.text = '[SUCCESS] Successfully applied Spicetify customizations to Spotify! The Spotify app may have opened. Make sure you are logged in with your Spotify account'
          $synchash.Spicetify_textblock.foreground = 'LightGreen'
          $synchash.Spicetify_textblock.FontSize = 14
          $synchash.Spicetify_transitioningControl.content = $synchash.Spicetify_textblock 
        }
      }else{
        write-ezlogs "User choose not to Apply Spicetify" -showtime -warning
      }
    }catch{
      write-ezlogs "An exception occurred in Spicetify_Apply_Button click event" -showtime -catcherror $_
    }finally{
      try{
        $thisapp.config | Export-Clixml -Path $thisapp.config.Config_Path -Force -Encoding UTF8
      }catch{
        write-ezlogs "An exception occurred saving settings to config file: $($thisapp.config.Config_Path)" -CatchError $_ -showtime
      }     
      close-splashscreen
      $synchash.Window.show()
    }
})

$synchash.Spicetify_Remove_Button.Add_Click({ 
    try{
      $synchash.Spicetify_apply_status = $Null
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
      $Button_Settings.AffirmativeButtonText = 'Yes'
      $Button_Settings.NegativeButtonText = 'No'  
      if(!(Use-RunAs -Check)){
        $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
        $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Restart as Admin Required","In order to fully remove Spicetify components, the app must be run with administrator permissions.`nWould you like to restart the app as admin now?",$okandCancel,$Button_Settings)
        if($result -eq 'Affirmative'){
          write-ezlogs "Restarting app as admin..." -showtime
          Use-RunAs -ForceReboot -uninstall_Module
        }else{
          write-ezlogs "User did not wish to restart as admin, unable to continue" -showtime -warning
        }
      }else{
        $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
        $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Remove Spicetify?","Are you sure you wish to remove Spicetify customizations from Spotify?`nThis will restore the Spotify app to the state it was in before Spicetify was added",$okandCancel,$Button_Settings)
        if($result -eq 'Affirmative'){
          $synchash.window.hide()
          $synchash.Spicetify_Toggle.ison = $false
          Add-Member -InputObject $thisapp.config -Name 'Use_Spicetify' -Value $false -MemberType NoteProperty -Force
          Start-SplashScreen -SplashTitle $thisScript.Name -SplashMessage 'Removing Spicetify customizations...' -Splash_More_Info 'Please Wait' -thisScript $thisScript -current_folder $Current_folder -log_file $logfile -Script_modules $Script_Modules 
          Disable-Spicetify -thisApp $thisApp -synchash $synchash
          Add-Member -InputObject $thisapp.config -Name 'PODE_SERVER_ACTIVE' -Value $false -MemberType NoteProperty -Force
          if((NETSTAT.EXE -n) | where {$_ -match '127.0.0.1:8974'}){Invoke-RestMethod -Uri 'http://127.0.0.1:8974/CLOSEPODE' -UseBasicParsing -ErrorAction SilentlyContinue}   
          if((Get-command -Module Pode)){         
            try{
              #$module_path = (get-module pode -ListAvailable).Path
              #$module_dir = (get-module pode -ListAvailable).ModuleBase | split-path -parent
              write-ezlogs ">>>> Unloading Module PODE" -showtime
              if((Use-RunAs -Check)){                               
                Remove-module 'Pode'
                #Uninstall-Module 'Pode' -AllVersions -Force -ErrorAction Continue
                #if([System.IO.Directory]::Exists($module_dir)){
                # $null = Remove-item $module_dir -force -Recurse
                #}                       
              }           
            }catch{
              write-ezlogs "An exception occurred removing module Pode" -showtime -catcherror $_
            }     
          }    
          $synchash.Spicetify_textblock.text = '[SUCCESS] Successfully removed Spicetify customizations to Spotify! If the Spotify launched, you can safely close it' 
          $synchash.Spicetify_textblock.foreground = 'LightGreen'
          $synchash.Spicetify_textblock.FontSize = 14
          $synchash.Spicetify_transitioningControl.content = $synchash.Spicetify_textblock
        }else{
          write-ezlogs "User choose not to Remove Spicetify" -showtime -warning
        }
      }
    }catch{
      write-ezlogs "An exception occurred in Spicetify_Remove_Button click event" -showtime -catcherror $_
    }finally{
      try{
        $thisapp.config | Export-Clixml -Path $thisapp.config.Config_Path -Force -Encoding UTF8
      }catch{
        write-ezlogs "An exception occurred saving settings to config file: $($thisapp.config.Config_Path)" -CatchError $_ -showtime
      }    
      close-splashscreen
      $synchash.Window.show()
    }
})

#---------------------------------------------- 
#endregion Spicetify Options
#----------------------------------------------

#---------------------------------------------- 
#region Notification Button
#----------------------------------------------
$synchash.Notifications_menu_title.Add_Click({
    if($synchash.NotificationFlyout.isOpen -eq $true){$synchash.NotificationFlyout.isOpen = $false}else{$synchash.NotificationFlyout.isOpen = $true}
})
#---------------------------------------------- 
#endregion Notification Button
#----------------------------------------------

#---------------------------------------------- 
#region Dismiss Notifications Button
#----------------------------------------------
[System.Windows.RoutedEventHandler]$DismissclickEvent = {
  param ($sender,$e)

  try{
    $null = $synchash.Notifications_Grid.Items.Remove($synchash.Notifications_Grid.SelectedItem)
    if([int]$synchash.Notifications_Badge.badge -gt 0){
      [int]$synchash.Notifications_Badge.badge = [int]$synchash.Notifications_Grid.items.count
      if([int]$synchash.Notifications_Badge.badge -eq 0){
      $synchash.Notifications_Badge.badge = ''}
    }elseif([int]$synchash.Notifications_Badge.badge -eq 0){
      $synchash.Notifications_Badge.badge = ''
    }
  }catch{
    write-ezlogs 'An exception occurred for dismissclickevent' -showtime -catcherror $_
  }
}
[System.Windows.RoutedEventHandler]$DismissAllclickEvent = {
  param ($sender,$e)
  try{
    $null = $null = $synchash.Notifications_Grid.items.clear()
    $synchash.Notifications_Badge.badge = ''
  }catch{
    write-ezlogs "An exception occurred for notifications DismissclickEvent" -showtime -catcherror $_
  }
}  
if($synchash.Notifications_Grid.Columns.count -lt 5){
  $buttontag = @{        
    synchash = $synchash;
    thisScript = $thisScript;
    thisApp = $thisapp
  }  
  $buttonColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
  $buttonFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
  $null = $buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, 'Dismiss')
  $null = $buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $synchash.Window.TryFindResource('GridButtonStyle'))
  $null = $buttonFactory.SetValue([System.Windows.Controls.Button]::NameProperty, 'Notification_dismiss_button')
  $null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$DismissclickEvent)
  $null = $buttonFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
  $dataTemplate = New-Object System.Windows.DataTemplate
  $dataTemplate.VisualTree = $buttonFactory
  $buttonHeaderFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
  $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Dismiss All")
  $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $synchash.Window.TryFindResource("DetailButtonStyle"))
  $Null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Notification_dismissAll_button")
  $null = $buttonHeaderFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$DismissAllclickEvent)
  $null = $buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
  $headerdataTemplate = New-Object System.Windows.DataTemplate
  $headerdataTemplate.VisualTree = $buttonheaderFactory 
  $buttonColumn.HeaderTemplate = $headerdataTemplate 
  $buttonColumn.CellTemplate = $dataTemplate
  $buttonColumn.DisplayIndex = 0  
  $null = $synchash.Notifications_Grid.Columns.add($buttonColumn)
  # $linkColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
  #$linkFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.Button])
  #$Null = $linkFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Link")
  #$Null = $linkFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $synchash.Window.TryFindResource("ToolsButtonStyle"))
  #$Null = $linkFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Link")
  #$null = $linkFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$LinkclickEvent)
  #$dataTemplate = New-Object System.Windows.DataTemplate
  #$dataTemplate.VisualTree = $linkFactory
  #$linkColumn.CellTemplate = $dataTemplate
  #$linkColumn.Header = "Link"
    
  # $null = $synchash.Notifications_Grid.Columns.add($linkColumn)

  <#    $synchash.Notifications_Grid.Add_SelectedCellsChanged({
    
      if($this.currentCell.item.view){
      write-ezlogs ($this.currentCell | out-string)
      }

  })#>
}
#---------------------------------------------- 
#endregion Dismiss Notifications Button
#----------------------------------------------

#---------------------------------------------- 
#region Start Tray Only Toggle
#----------------------------------------------
$synchash.Start_Tray_only_Toggle.add_Toggled({
    if($synchash.Start_Tray_only_Toggle.isOn -eq $true){Add-Member -InputObject $thisapp.config -Name 'Start_Tray_only' -Value $true -MemberType NoteProperty -Force}
    else{Add-Member -InputObject $thisapp.config -Name 'Start_Tray_only' -Value $false -MemberType NoteProperty -Force}
})
#---------------------------------------------- 
#endregion Start Tray Only Toggle
#----------------------------------------------

#---------------------------------------------- 
#region Start Tray Only Help
#----------------------------------------------
$synchash.Start_Tray_only_Button.add_Click({
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.Start_Tray_only_Toggle.content
    Update-HelpFlyout -content "Enable to start the app 'Silently'. The main UI window will not be shown, but instead only the system tray icon and menu will load. Use the tray menu to open the app" -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash 
})
#---------------------------------------------- 
#endregion Start Tray Only Help
#----------------------------------------------

#---------------------------------------------- 
#region Minimize To Tray Toggle
#----------------------------------------------
$synchash.Minimize_To_Tray_Toggle.add_Toggled({
    if($synchash.Minimize_To_Tray_Toggle.isOn -eq $true){Add-Member -InputObject $thisapp.config -Name 'Minimize_To_Tray' -Value $true -MemberType NoteProperty -Force}
    else{Add-Member -InputObject $thisapp.config -Name 'Minimize_To_Tray' -Value $false -MemberType NoteProperty -Force}
})
#---------------------------------------------- 
#endregion Minimize To Tray Toggle
#----------------------------------------------

#---------------------------------------------- 
#region Minimize To Tray Help
#----------------------------------------------
$synchash.Minimize_To_Tray_Button.add_Click({
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.Minimize_To_Tray_Toggle.content
    Update-HelpFlyout -content 'Enable to hide the UI window when minimizing. You can reopen the app using the System Tray Menu' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash 
})
#---------------------------------------------- 
#endregion Minimize To Tray Help
#----------------------------------------------

#---------------------------------------------- 
#region Start on Windows Login Toggle
#----------------------------------------------
$App_Exe_Path_label_transitioningControl = $synchash.App_Exe_Path_label_transitioningControl.content
$App_Exe_Path_Textbox_transitioningControl = $synchash.App_Exe_Path_Textbox_transitioningControl.content
$App_Exe_Path_Button_transitioningControl = $synchash.App_Exe_Path_Button_transitioningControl.content
$synchash.Start_On_Windows_transitioningControl.content = ''
$synchash.App_Exe_Path_textbox.text = $thisapp.config.App_EXE_Path
$synchash.Start_On_Windows_Login_Toggle.add_Toggled({
    if($synchash.Start_On_Windows_Login_Toggle.isOn -eq $true){
      $synchash.App_Exe_Path_label_transitioningControl.content = $App_Exe_Path_label_transitioningControl
      $synchash.App_Exe_Path_StackPanel.Height = 40
      $synchash.App_Exe_Path_Textbox_transitioningControl.content = $App_Exe_Path_Textbox_transitioningControl
      $synchash.App_Exe_Path_Button_transitioningControl.content = $App_Exe_Path_Button_transitioningControl
      $synchash.App_Exe_Path_Label.IsEnabled = $true 
      $synchash.App_Exe_Path_textbox.text = $thisapp.config.App_EXE_Path   
      if([system.io.file]::Exists($thisapp.config.App_EXE_Path)){
        $synchash.App_Exe_Path_textbox.IsEnabled = $false     
        $synchash.App_Exe_Path_Browse.IsEnabled = $false     
        $synchash.App_Exe_Path_Label.BorderBrush = 'LightGreen'   
      }else{
        $synchash.App_Exe_Path_textbox.IsEnabled = $true      
        $synchash.App_Exe_Path_Browse.IsEnabled = $true   
        $synchash.App_Exe_Path_Label.BorderBrush = 'Red'    
      }  
      Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $true -MemberType NoteProperty -Force
    }
    else{
      $synchash.App_Exe_Path_label_transitioningControl.content = ''
      $synchash.App_Exe_Path_Textbox_transitioningControl.content = ''
      $synchash.App_Exe_Path_Button_transitioningControl.content = ''
      $synchash.App_Exe_Path_StackPanel.Height = 0
      $synchash.App_Exe_Path_Label.IsEnabled = $false      
      $synchash.App_Exe_Path_textbox.IsEnabled = $false      
      $synchash.App_Exe_Path_Browse.IsEnabled = $false
      Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $false -MemberType NoteProperty -Force      
    }
})
$synchash.App_Exe_Path_Browse.add_Click({
    [array]$App_Exe_Path = Open-FileDialog -Title "Select the exe file for $($thisScript.name) that will be used for startup" -MultiSelect:$false #-InitialDirectory $syncHash.App_Exe_Path_textbox.text
    $App_Exe_Path = $App_Exe_Path -join ','
    if(-not [string]::IsNullOrEmpty($App_Exe_Path)){$synchash.App_Exe_Path_textbox.text = $App_Exe_Path}  
})  

if($thisapp.config.Start_On_Windows_Login -and -not [string]::IsNullOrEmpty($synchash.App_Exe_Path_textbox.text)){
  $synchash.App_Exe_Path_label_transitioningControl.content = $App_Exe_Path_label_transitioningControl
  $synchash.App_Exe_Path_Textbox_transitioningControl.content = $App_Exe_Path_Textbox_transitioningControl
  $synchash.App_Exe_Path_Button_transitioningControl.content = $App_Exe_Path_Button_transitioningControl
  $synchash.Start_On_Windows_Login_Toggle.isOn = $true
  $synchash.App_Exe_Path_Label.IsEnabled = $true 
  $synchash.App_Exe_Path_textbox.text = $thisapp.config.App_EXE_Path     
  if([system.io.file]::Exists($thisapp.config.App_EXE_Path)){
    $synchash.App_Exe_Path_textbox.IsEnabled = $false     
    $synchash.App_Exe_Path_Browse.IsEnabled = $false 
    $synchash.App_Exe_Path_Label.BorderBrush = 'LightGreen'       
  }else{
    $synchash.App_Exe_Path_textbox.IsEnabled = $true      
    $synchash.App_Exe_Path_Browse.IsEnabled = $true 
    $synchash.App_Exe_Path_Label.BorderBrush = 'Red'      
  }   
}
else{
  $synchash.Start_On_Windows_Login_Toggle.isOn = $false
  $synchash.App_Exe_Path_label_transitioningControl.content = ''
  $synchash.App_Exe_Path_Textbox_transitioningControl.content = ''
  $synchash.App_Exe_Path_Button_transitioningControl.content = ''
  $synchash.App_Exe_Path_Label.IsEnabled = $false      
  $synchash.App_Exe_Path_textbox.IsEnabled = $false      
  $synchash.App_Exe_Path_Browse.IsEnabled = $false 
}

#---------------------------------------------- 
#endregion Start on Windows Login Toggle
#----------------------------------------------

#---------------------------------------------- 
#region Start on Windows Login Help
#----------------------------------------------
$synchash.Start_On_Windows_Login_Button.add_Click({
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.Start_On_Windows_Login_Toggle.content
    Update-HelpFlyout -content "Enable to automatically launch the app upon login to Windows. You must specify the location the $($thisScript.Name).exe file" -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash 
    Update-HelpFlyout -content 'IMPORTANT: The app creates a Windows Scheduled task when enabled. It then removes the task when disabled. If you remove the app without disabling this option first, the scheduled task will remain (and fail if the exe is gone)' -linebefore -FontWeight bold -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -synchash $synchash
})
#---------------------------------------------- 
#endregion Start on Windows Login Help
#----------------------------------------------

#---------------------------------------------- 
#region Verbose Logging Control
#----------------------------------------------
$synchash.Verbose_logging_Toggle.IsOn = $thisapp.config.Verbose_logging
$Log_label_transitioningControl = $synchash.Log_label_transitioningControl.content
$Log_Textbox_transitioningControl = $synchash.Log_Textbox_transitioningControl.content
$Log_Button_transitioningControl = $synchash.Log_Button_transitioningControl.content
$synchash.Verbose_logging_Toggle.add_Toggled({
    if($synchash.Verbose_logging_Toggle.isOn -eq $true){
      $script:Verboselogging = $true
      $synchash.Log_label_transitioningControl.content = $Log_label_transitioningControl
      $synchash.Log_Textbox_transitioningControl.content = $Log_Textbox_transitioningControl
      $synchash.Log_Button_transitioningControl.content = $Log_Button_transitioningControl           
      $synchash.Log_Path_Label.IsEnabled = $true 
      $synchash.Log_Path_textbox.text = $thisapp.Config.Log_file      
      $synchash.Log_Path_textbox.IsEnabled = $true    
      $synchash.Log_Path_Browse.IsEnabled = $true      
      Add-Member -InputObject $thisapp.config -Name 'Verbose_logging' -Value $true -MemberType NoteProperty -Force
    }
    else{
      $script:Verboselogging = $false
      $synchash.Log_label_transitioningControl.content = ''
      $synchash.Log_Textbox_transitioningControl.content = ''
      $synchash.Log_Button_transitioningControl.content = ''            
      $synchash.Log_Path_Label.IsEnabled = $false      
      $synchash.Log_Path_textbox.IsEnabled = $false      
      $synchash.Log_Path_Browse.IsEnabled = $false      
      Add-Member -InputObject $thisapp.config -Name 'Verbose_logging' -Value $false -MemberType NoteProperty -Force      
    }
})  

if($thisapp.config.Verbose_logging){
  $synchash.Log_label_transitioningControl.content = $Log_label_transitioningControl
  $synchash.Log_Textbox_transitioningControl.content = $Log_Textbox_transitioningControl
  $synchash.Log_Button_transitioningControl.content = $Log_Button_transitioningControl
  $synchash.Verbose_logging_Toggle.isOn = $true
  $synchash.Log_Path_textbox.text = $thisapp.Config.Log_file  
  $synchash.Log_Path_Label.IsEnabled = $true      
  $synchash.Log_Path_textbox.IsEnabled = $true     
  $synchash.Log_Path_Browse.IsEnabled = $true  
}
else{
  $synchash.Verbose_logging_Toggle.isOn = $false
  $synchash.Log_label_transitioningControl.content = ''
  $synchash.Log_Textbox_transitioningControl.content = ''
  $synchash.Log_Button_transitioningControl.content = ''       
  $synchash.Log_Path_Label.IsEnabled = $false       
  $synchash.Log_Path_textbox.IsEnabled = $false     
  $synchash.Log_Path_Browse.IsEnabled = $false  
}

$synchash.Log_Path_Browse.add_Click({
    $result = Open-FolderDialog -Title 'Select the directory where logs will be stored'
    if(-not [string]::IsNullOrEmpty($result)){$synchash.Log_Path_textbox.text = $result}  
}) 

$synchash.Log_Path_Hyperlink.Inlines.add("$([system.io.path]::GetFileName($thisApp.Config.Log_file))")
$synchash.Log_Path_Hyperlink.NavigateUri = $thisApp.Config.Log_file
$Null = $synchash.Log_Path_Hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$synchash.Hyperlink_RequestNavigate)

#---------------------------------------------- 
#endregion Verbose Logging Control
#----------------------------------------------

#---------------------------------------------- 
#region Verbose Logging Help
#----------------------------------------------
$synchash.Verbose_logging_Button.add_Click({
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.Verbose_logging_Toggle.content
    Update-HelpFlyout -content 'This option will enable extra verbose and debug messages to be displayed in the console and written to the log file' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -synchash $synchash
    Update-HelpFlyout -content 'This is primarily for development, debugging and advanced troubleshooting. Enabling this option will cause performance slow-down and cause the log file to grow in size quickly' -linebefore -FontWeight bold -Warning -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -synchash $synchash
})
#---------------------------------------------- 
#endregion Verbose Logging Help
#----------------------------------------------


#---------------------------------------------- 
#region Snapshots Toggle
#----------------------------------------------
if($thisApp.Config.Video_Snapshots){
  $synchash.SnapShots_Toggle.isOn      
}else{
  $synchash.SnapShots_Toggle.isOn = $false
}

if([system.io.directory]::Exists($thisapp.config.Snapshots_Path)){
  $synchash.SnapShots_textbox.text = $thisapp.config.Snapshots_Path   
  $synchash.SnapShots_Label.BorderBrush = 'LightGreen'   
  $synchash.SnapShots_Hyperlink.Inlines.add("Open Snapshots Folder")
  $synchash.SnapShots_Hyperlink.NavigateUri = [uri]$thisapp.config.Snapshots_Path
}else{
  $synchash.SnapShots_Label.BorderBrush = 'Red'
  $synchash.SnapShots_textbox.text = ''
  $synchash.SnapShots_Hyperlink.inlines.clear()
  $synchash.SnapShots_Hyperlink.NavigateUri = $Null
}

$synchash.SnapShots_Toggle.add_Toggled({
    if($synchash.SnapShots_Toggle.isOn -eq $true){
      #TODO: stuff and things..
      Add-Member -InputObject $thisapp.config -Name 'Video_Snapshots' -Value $true -MemberType NoteProperty -Force
    }
    else{    
      Add-Member -InputObject $thisapp.config -Name 'Video_Snapshots' -Value $false -MemberType NoteProperty -Force
    }
})
$synchash.SnapShots_Browse.add_Click({
    try{
      $SnapShot_Path = Open-FolderDialog -Title 'Select the directory path where Snapshots will be saved to'
      if([system.io.directory]::Exists($SnapShot_Path)){
        $synchash.SnapShots_textbox.text = $SnapShot_Path    
        $synchash.SnapShots_Label.BorderBrush = 'LightGreen'
        Add-Member -InputObject $thisapp.config -Name 'Snapshots_Path' -Value $SnapShot_Path -MemberType NoteProperty -Force   
        $synchash.SnapShots_Hyperlink.Inlines.add("Open Snapshots Folders")
        $synchash.SnapShots_Hyperlink.NavigateUri = [uri]$thisapp.config.Snapshots_Path
        $synchash.SnapShots_Hyperlink.Visibility = 'Visible'
      }else{
        $synchash.SnapShots_Label.BorderBrush = 'Red'
        Add-Member -InputObject $thisapp.config -Name 'Snapshots_Path' -Value '' -MemberType NoteProperty -Force 
        $synchash.SnapShots_Hyperlink.NavigateUri = $Null
        $synchash.SnapShots_Hyperlink.inlines.clear()
      }
    }catch{
      write-ezlogs "An exception occurred in SnapShots_Browse click event" -showtime -catcherror $_
    }
})  

$Null = $synchash.SnapShots_Hyperlink.AddHandler([System.Windows.Documents.Hyperlink]::ClickEvent,$synchash.Hyperlink_RequestNavigate)
#---------------------------------------------- 
#endregion Snapshots Toggle
#----------------------------------------------

#---------------------------------------------- 
#region Snapshots Help
#----------------------------------------------
$synchash.SnapShots_Button.add_Click({
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.SnapShots_Toggle.content
    Update-HelpFlyout -content "When enabled, using the Snapshot button will take a snapshot of any currently playing video in addition to a snapshot of the entire app window" -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash 
    Update-HelpFlyout -content 'IMPORTANT' -TextDecorations Underline -linebefore -FontWeight bold -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -synchash $synchash
    Update-HelpFlyout -content "If you do not provide a snapshot path, all Snapshots by default are saved to $($thisApp.Config.Temp_Folder)" -linebefore -FontWeight bold -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -synchash $synchash
    Update-HelpFlyout -content 'INFO'-TextDecorations Underline -linebefore -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -synchash $synchash
    Update-HelpFlyout -content "Output filenames for snapshots:`nApp Window Snapshots: \$($thisApp.Config.App_name)_*Datetime*.png`nVideo Snapshots: \*title-of-media*_*Datetime*.png - (If title unknown defaults to App Window filename)" -linebefore -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -synchash $synchash
})
#---------------------------------------------- 
#endregion Snapshots Help
#----------------------------------------------


#---------------------------------------------- 
#region Use Hardware Acceleration Toggle
#----------------------------------------------
if($thisapp.config.Use_HardwareAcceleration){$synchash.Use_HardwareAcceleration_Toggle.isOn = $true}else{$synchash.Use_HardwareAcceleration_Toggle.isOn = $false}
$synchash.Use_HardwareAcceleration_transitioningControl.content = ''
$synchash.Use_HardwareAcceleration_textblock.text = ''
$synchash.Use_HardwareAcceleration_Toggle.add_Toggled({
    if($synchash.Use_HardwareAcceleration_Toggle.isOn -eq $true){
      Add-Member -InputObject $thisapp.config -Name 'Use_HardwareAcceleration' -Value $true -MemberType NoteProperty -Force
    }
    else{
      Add-Member -InputObject $thisapp.config -Name 'Use_HardwareAcceleration' -Value $false -MemberType NoteProperty -Force
    }
}) 
#---------------------------------------------- 
#endregion Use Hardware Acceleration Toggle
#----------------------------------------------

#---------------------------------------------- 
#region Use Hardware Acceleration Help
#----------------------------------------------
$synchash.Use_HardwareAcceleration_Button.add_Click({
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.Use_HardwareAcceleration_Toggle.content
    Update-HelpFlyout -content 'Enables use of Hardware Acceleration (GPU) for playback of Video Media, which takes load of the CPU for video decoding tasks' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -FontWeight bold
    Update-HelpFlyout -content 'INFO' -TextDecorations Underline -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'If experiencing video playback issues, try disabling or enabling to see if playback improves. The load on the CPU/GPU varies depending on the quality/bitrate of the video. In some cases, disabling Hardware Acceleration can lower total GPU usage at very minimal increase to the CPU'  -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -synchash $synchash    
    Update-HelpFlyout -content 'IMPORTANT' -FontWeight bold -TextDecorations Underline -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'This setting does not apply to Spotify Media playback, and has little to no impact on playback of media that only has audio.' -FontWeight bold -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
})
#---------------------------------------------- 
#endregion Use Hardware Acceleration Help
#----------------------------------------------

#---------------------------------------------- 
#region Show Notifications Toggle
#----------------------------------------------
if($thisapp.config.Show_Notifications){$synchash.Show_Notifications_Toggle.isOn = $true}else{$synchash.Show_Notifications_Toggle.isOn = $false}
$synchash.Show_Notifications_Toggle.add_Toggled({
    if($synchash.Show_Notifications_Toggle.isOn -eq $true){Add-Member -InputObject $thisapp.config -Name 'Show_Notifications' -Value $true -MemberType NoteProperty -Force}
    else{Add-Member -InputObject $thisapp.config -Name 'Show_Notifications' -Value $false -MemberType NoteProperty -Force}
}) 
#---------------------------------------------- 
#endregion Show Notifications Toggle
#----------------------------------------------

#---------------------------------------------- 
#region Show Notifications Help
#----------------------------------------------
$synchash.Show_Notifications_Button.add_Click({
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.Show_Notifications_Toggle.content
    Update-HelpFlyout -content 'Enables display of toast notifications (Artist, Title, Duration..etc) of media upon starting playback' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -FontWeight bold
    Update-HelpFlyout -content 'INFO' -TextDecorations Underline -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'Can be useful when playing through large playlists or when using shuffle to identify a song thats playing without needing to bring the app back into focus'  -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -synchash $synchash    
    Update-HelpFlyout -content 'IMPORTANT' -FontWeight bold -TextDecorations Underline -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'Notifications may contain Artist/Album thumbnail images if available, otherwise will display a default image based on the type of media (Twitch, Youtube, or VLC for local media)' -FontWeight bold -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
})
#---------------------------------------------- 
#endregion Show Notifications Help
#----------------------------------------------


#---------------------------------------------- 
#region Youtube WebPlayer Toggle
#----------------------------------------------
if($thisapp.config.Youtube_WebPlayer){
  $synchash.Youtube_WebPlayer_Toggle.isOn = $true
  $synchash.Use_invidious_Toggle.IsEnabled = $true
  if($thisApp.Config.Use_invidious){
    $synchash.Use_invidious_Toggle.isOn = $true
  }else{
    $synchash.Use_invidious_Toggle.isOn = $false
  }
}else{
  $synchash.Youtube_WebPlayer_Toggle.isOn = $false
  $synchash.Use_invidious_Toggle.IsEnabled = $false
}
$synchash.Youtube_WebPlayer_transitioningControl.content = ''
$synchash.Youtube_WebPlayer_transitioningControl.Height = 0
$synchash.Youtube_WebPlayer_Toggle.add_Toggled({
    try{
      if($synchash.Youtube_WebPlayer_Toggle.isOn -eq $true){
        if($thisApp.Config.Use_invidious){
          $synchash.Use_invidious_Toggle.IsEnabled = $true
        }else{
          $synchash.Use_invidious_Toggle.IsEnabled = $false
        }    
        Add-Member -InputObject $thisapp.config -Name 'Youtube_WebPlayer' -Value $true -MemberType NoteProperty -Force
      }
      else{  
        $synchash.Use_invidious_Toggle.IsEnabled = $false               
        Add-Member -InputObject $thisapp.config -Name 'Youtube_WebPlayer' -Value $false -MemberType NoteProperty -Force     
      }
      try{
        $thisapp.config | Export-Clixml -Path $thisapp.config.Config_Path -Force -Encoding UTF8
      }catch{
        write-ezlogs "An exception occurred saving settings to config file: $($thisapp.config.Config_Path)" -CatchError $_ -showtime
      }      
    }catch{
      write-ezlogs "An exception occurred in Youtube_WebPlayer_Toggle event" -showtime -catcherror $_
    }
}) 
#---------------------------------------------- 
#endregion Youtube WebPlayer Toggle
#----------------------------------------------

#---------------------------------------------- 
#region Youtube WebPlayer Help
#----------------------------------------------
$synchash.Youtube_WebPlayer_Help_Button.add_Click({
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.Youtube_WebPlayer_Toggle.content
    Update-HelpFlyout -content 'Enables playback of Youtube media using an embedded Web player powered by Microsoft Edge (webview2), vs the native in app player.
    Playback will be similiar to playing youtube media via the Edge webbrowser, with a few differences as listed below' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -FontWeight bold 
    Update-HelpFlyout -content 'IMPORTANT' -FontWeight bold -TextDecorations Underline -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'Using the Web player allows GREATLY improved performance related to the time when you press Play to the time playback starts. 
    
      However, doing so means you lose some functionality of the native player, such as:
      - Automatic play features using the Play Queue is unavailable
      - Pause,next/prev and other playback controls 
      - You can use the native playback controls within the web player
      - EXCEPTION: Stop playback does still work (Using UI or Keyboard buttons)
      - Volume/EQ and other Audio settings. All Audio is output through the web player
    ' -FontWeight bold -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'INFO' -TextDecorations Underline -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content "Playback of Youtube media via the Web Player does not use Youtube.com's interface, but rather Invidious. This provides some benefits such as:
      - Open-Source
      - Ability to fully embed the video without displaying the youtube interface
      - Download (most) videos by right-clicking on the video and selecting 'Download Video'
      - Prevents Google from tracking you or what your watching (if that matters to you)

      For more information, visit https://invidious.io/

    "  -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -synchash $synchash     
})
#---------------------------------------------- 
#endregion Youtube WebPlayer Help
#----------------------------------------------

#---------------------------------------------- 
#region Use_invidious Toggle
#----------------------------------------------
if($thisApp.Config.Use_invidious){
  $synchash.Use_invidious_Toggle.isOn = $true
  $synchash.Use_invidious_grid.BorderBrush = 'LightGreen' 
}else{
  $synchash.Use_invidious_Toggle.isOn = $false
  $synchash.Use_invidious_grid.BorderBrush = 'Red'
}
$synchash.Use_invidious_Toggle.add_Toggled({
    try{
      if($synchash.Use_invidious_Toggle.isOn -eq $true){
        $synchash.Use_invidious_grid.BorderBrush = 'LightGreen'     
        Add-Member -InputObject $thisapp.config -Name 'Use_invidious' -Value $true -MemberType NoteProperty -Force
      }
      else{                 
        Add-Member -InputObject $thisapp.config -Name 'Use_invidious' -Value $false -MemberType NoteProperty -Force  
        $synchash.Use_invidious_grid.BorderBrush = 'Red'   
      }
      try{
        $thisapp.config | Export-Clixml -Path $thisapp.config.Config_Path -Force -Encoding UTF8
      }catch{
        write-ezlogs "An exception occurred saving settings to config file: $($thisapp.config.Config_Path)" -CatchError $_ -showtime
      }      
    }catch{
      write-ezlogs "An exception occurred in Use_invidious_Toggle event" -showtime -catcherror $_
    }
}) 
#---------------------------------------------- 
#endregion Use_invidious Toggle
#----------------------------------------------

#---------------------------------------------- 
#region Use_invidious Help
#----------------------------------------------
$synchash.Use_invidious_Help_Button.add_Click({
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.Use_invidious_Toggle.content
    Update-HelpFlyout -content "Enables using Invidious for playback of Youtube media when using the Web Player" -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -FontWeight bold 
    Update-HelpFlyout -content 'IMPORTANT' -FontWeight bold -TextDecorations Underline -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content "Requires enabling 'Use Web Player' Youtube option" -FontWeight bold -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'INFO' -TextDecorations Underline -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content "Some benefits of using Invidious:
      - Open-Source
      - Ability to fully embed the video without displaying the youtube interface
      - Download (most) videos by right-clicking on the video and selecting 'Download Video'
      - Prevents Google from tracking you or what your watching (if that matters to you)

      For more information, visit https://invidious.io/

    "  -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -synchash $synchash     
})
#---------------------------------------------- 
#endregion Use_invidious Help
#----------------------------------------------

#---------------------------------------------- 
#region Spotify WebPlayer Toggle
#----------------------------------------------
if($thisapp.config.Spotify_WebPlayer){
  $synchash.Spotify_WebPlayer_Toggle.isOn = $true
}else{
  $synchash.Spotify_WebPlayer_Toggle.isOn = $false
}
$synchash.Spotify_WebPlayer_transitioningControl.content = ''
$synchash.Spotify_WebPlayer_transitioningControl.Height = 0
$synchash.Spotify_WebPlayer_Toggle.add_Toggled({
    try{
      if($synchash.Spotify_WebPlayer_Toggle.isOn -eq $true){    
        Add-Member -InputObject $thisapp.config -Name 'Spotify_WebPlayer' -Value $true -MemberType NoteProperty -Force
      }
      else{               
        Add-Member -InputObject $thisapp.config -Name 'Spotify_WebPlayer' -Value $false -MemberType NoteProperty -Force     
      }
      try{
        $thisapp.config | Export-Clixml -Path $thisapp.config.Config_Path -Force -Encoding UTF8
      }catch{
        write-ezlogs "An exception occurred saving settings to config file: $($thisapp.config.Config_Path)" -CatchError $_ -showtime
      }      
    }catch{
      write-ezlogs "An exception occurred in Spotify_WebPlayer_Toggle event" -showtime -catcherror $_
    }
}) 
#---------------------------------------------- 
#endregion Spotify WebPlayer Toggle
#----------------------------------------------

#---------------------------------------------- 
#region Spotify WebPlayer Help
#----------------------------------------------
$synchash.Spotify_WebPlayer_Help_Button.add_Click({
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.Spotify_WebPlayer_Toggle.content
    Update-HelpFlyout -content 'Enables playback of Spotify media using an embedded Web player powered by Microsoft Edge (webview2), vs the native Spotify client.
    Playback will be similiar to playing Spotify media via the Edge webbrowser, with a few differences as listed below' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -FontWeight bold 
    Update-HelpFlyout -content 'IMPORTANT' -FontWeight bold -TextDecorations Underline -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'Using the Web player allows GREATLY improved performance related to the time when you press Play to the time playback starts. 
    
      However, doing so means you lose some functionality of the native player, such as:
      - Automatic play features using the Play Queue is unavailable
      - Pause,next/prev and other playback controls 
      - You can use the native playback controls within the web player
      - EXCEPTION: Stop playback does still work (Using UI or Keyboard buttons)
      - Volume/EQ and other Audio settings. All Audio is output through the web player
    ' -FontWeight bold -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash   
})
#---------------------------------------------- 
#endregion Spotify WebPlayer Help
#----------------------------------------------


#---------------------------------------------- 
#region Twitch Updates Toggle
#----------------------------------------------
if($thisapp.config.Twitch_Update){
  $synchash.Twitch_Update_Toggle.isOn = $true
  $synchash.Twitch_Update_Interval_ComboBox.IsEnabled = $true
}else{
  $synchash.Twitch_Update_Toggle.isOn = $false
  $synchash.Twitch_Update_Interval_ComboBox.IsEnabled = $false
}
$synchash.Twitch_Update_transitioningControl.content = ''
$synchash.Twitch_Update_textblock.text = ''
$synchash.Twitch_Update_Toggle.add_Toggled({
    try{
      if($synchash.Twitch_Update_Toggle.isOn -eq $true){       
        Add-Member -InputObject $thisapp.config -Name 'Twitch_Update' -Value $true -MemberType NoteProperty -Force
        $synchash.Twitch_Update_Interval_ComboBox.IsEnabled = $true
      }
      else{          
        Add-Member -InputObject $thisapp.config -Name 'Twitch_Update' -Value $false -MemberType NoteProperty -Force
        $synchash.Twitch_Update_Interval_ComboBox.IsEnabled = $false      
      }
      $thisapp.config | Export-Clixml -Path $thisapp.config.Config_Path -Force -Encoding UTF8
    }catch{
      write-ezlogs "An exception occurred in Twitch_Update_Toggle event" -CatchError $_ -showtime
    }
}) 
#---------------------------------------------- 
#endregion Twitch Updates Toggle
#----------------------------------------------

#---------------------------------------------- 
#region Twitch Update Interval
#----------------------------------------------
if($thisapp.config.Twitch_Update_Interval){
  try{
    $interval = [TimeSpan]::Parse($thisapp.config.Twitch_Update_Interval).TotalMinutes
    if($interval -ge 60){$content = "$interval Hour"}else{$content = "$interval Minutes"}
    if($content -ne $null){
      $synchash.Twitch_Update_Interval_ComboBox.SelectedItem = $synchash.Twitch_Update_Interval_ComboBox.items | where {$_.content -eq $content}
      $synchash.Twitch_Update_Interval_Label.BorderBrush = 'Green'
    }
  }catch{write-ezlogs 'An exception occurred parsing Twitch Update Interval' -showtime -catcherror $_}
}else{
  $synchash.Twitch_Update_Interval_ComboBox.SelectedIndex = -1
  $synchash.Twitch_Update_Interval_Label.BorderBrush = 'Red'
}
$synchash.Twitch_Update_transitioningControl.content = ''
$synchash.Twitch_Update_textblock.text = ''
$synchash.Twitch_Update_Interval_ComboBox.add_SelectionChanged({
    try{
      if($synchash.Twitch_Update_Interval_ComboBox.SelectedIndex -ne -1){    
        $synchash.Twitch_Update_Interval_Label.BorderBrush = 'Green'
        if($synchash.Twitch_Update_Interval_ComboBox.Selecteditem.Content -match 'Minutes'){
          $interval = [TimeSpan]::FromMinutes("$(($synchash.Twitch_Update_Interval_ComboBox.Selecteditem.Content -replace 'Minutes', '').trim())")
        }elseif($synchash.Twitch_Update_Interval_ComboBox.Selecteditem.Content -match 'Hour'){
          $interval = [TimeSpan]::FromHours("$(($synchash.Twitch_Update_Interval_ComboBox.Selecteditem.Content -replace 'Hour', '').trim())")
        }
        Add-Member -InputObject $thisapp.config -Name 'Twitch_Update_Interval' -Value $interval -MemberType NoteProperty -Force
        $synchash.Twitch_Update_textblock.text = ''
        $synchash.Twitch_Update_transitioningControl.content = ''      
      }
      else{          
        $synchash.Twitch_Update_Interval_Label.BorderBrush = 'Red'
        Add-Member -InputObject $thisapp.config -Name 'Twitch_Update_Interval' -Value '' -MemberType NoteProperty -Force      
      }
      $thisapp.config | Export-Clixml -Path $thisapp.config.Config_Path -Force -Encoding UTF8
    }catch{
      write-ezlogs "An exception occurred in Twitch_Update_Interval_ComboBox event" -CatchError $_ -showtime
    }
}) 

if($thisapp.config.Twitch_Update -and $thisapp.config.Twitch_Update_Interval){
  try{
    Start-TwitchMonitor -Interval $thisapp.config.Twitch_Update_Interval -thisApp $thisapp -synchash $synchash -Verboselog
  }catch{
    write-ezlogs 'An exception occurred in Start-TwitchMonitor' -showtime -catcherror $_
  }
}

#---------------------------------------------- 
#endregion Twitch Update Interval
#----------------------------------------------

#---------------------------------------------- 
#region Twitch Updates Help
#----------------------------------------------
$synchash.Twitch_Update_Button.add_Click({
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.Twitch_Update_Toggle.content
    Update-HelpFlyout -content 'Enable to automatically refresh the status of Twitch Streams at the interval specified in the drop-down.' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -FontWeight bold
    Update-HelpFlyout -content 'INFO' -TextDecorations Underline -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'Refreshing gets the broadcasting status (Live, Hosting, Offline..etc), current category and title of each Twitch channel that has been added to the app.'  -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -synchash $synchash    
    Update-HelpFlyout -content 'IMPORTANT' -FontWeight bold -TextDecorations Underline -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'Naturally, this requires having added at least 1 Twitch Channel/Stream to the app, otherwise this does nothing' -FontWeight bold -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
})
#---------------------------------------------- 
#endregion Twitch Updates Help
#----------------------------------------------


#---------------------------------------------- 
#region Enable_Marquee Toggle
#----------------------------------------------
if($thisapp.config.Enable_Marquee){
  $synchash.Enable_Marquee_Toggle.isOn = $true
}else{
  $synchash.Enable_Marquee_Toggle.isOn = $false
}
$synchash.Enable_Marquee_Toggle.add_Toggled({
    if($synchash.Enable_Marquee_Toggle.isOn -eq $true){       
      Add-Member -InputObject $thisapp.config -Name 'Enable_Marquee' -Value $true -MemberType NoteProperty -Force
    }
    else{          
      Add-Member -InputObject $thisapp.config -Name 'Enable_Marquee' -Value $false -MemberType NoteProperty -Force     
    }
}) 
#---------------------------------------------- 
#endregion Enable_Marquee Toggle
#----------------------------------------------

#---------------------------------------------- 
#region Enable_Marquee Help
#----------------------------------------------
$synchash.Enable_Marquee_Button.add_Click({
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.Enable_Marquee_Toggle.content
    Update-HelpFlyout -content 'Enables display of various media info overlayed the top of the Video Player' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -FontWeight bold
    Update-HelpFlyout -content 'INFO' -TextDecorations Underline -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'If enabled when playing Twitch Streams, the stream viewer count is displayed.
    - NOTE: The view count will only update if the option "Auto Stream Updates" is enabled'  -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -synchash $synchash    
    Update-HelpFlyout -content 'If enabled when playing Non-Twitch video media, the name/title/album is displayed'  -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -synchash $synchash
})
#---------------------------------------------- 
#endregion Enable_Marquee Help
#----------------------------------------------


#---------------------------------------------- 
#region PlayLink_OnDrop Toggle
#----------------------------------------------
if($thisapp.config.PlayLink_OnDrop){
  $synchash.PlayLink_OnDrop_Toggle.isOn = $true
}else{
  $synchash.PlayLink_OnDrop_Toggle.isOn = $false
}
$synchash.PlayLink_OnDrop_Toggle.add_Toggled({
    if($synchash.PlayLink_OnDrop_Toggle.isOn -eq $true){       
      Add-Member -InputObject $thisapp.config -Name 'PlayLink_OnDrop' -Value $true -MemberType NoteProperty -Force
    }
    else{          
      Add-Member -InputObject $thisapp.config -Name 'PlayLink_OnDrop' -Value $false -MemberType NoteProperty -Force     
    }
}) 
#---------------------------------------------- 
#endregion PlayLink_OnDrop Toggle
#----------------------------------------------

#---------------------------------------------- 
#region PlayLink_OnDrop Help
#----------------------------------------------
$synchash.PlayLink_OnDrop_Button.add_Click({
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.PlayLink_OnDrop_Toggle.content
    Update-HelpFlyout -content 'Enables immediately starting playback of Youtube or Twitch URLs' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -FontWeight bold
    Update-HelpFlyout -content 'INFO' -TextDecorations Underline -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'When this option is enabled, the app will always start playback using the Web Player. The video will not show up in the Queue, playlists or Browser tables until the media has been processed. This will continue in the background while the video is being played. Once processing is finished, the media will then show up in the queue and other lists'  -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
})
#---------------------------------------------- 
#endregion PlayLink_OnDrop Help
#----------------------------------------------

#---------------------------------------------- 
#region Splash_Screen_Audio Toggle
#----------------------------------------------
if($thisapp.config.SplashScreenAudio){
  $synchash.Splash_Screen_Audio_Toggle.isOn = $true
}else{
  $synchash.Splash_Screen_Audio_Toggle.isOn = $false
}
$synchash.Splash_Screen_Audio_Toggle.add_Toggled({
    if($synchash.Splash_Screen_Audio_Toggle.isOn -eq $true){       
      Add-Member -InputObject $thisapp.config -Name 'SplashScreenAudio' -Value $true -MemberType NoteProperty -Force
    }
    else{          
      Add-Member -InputObject $thisapp.config -Name 'SplashScreenAudio' -Value $false -MemberType NoteProperty -Force     
    }
}) 
#---------------------------------------------- 
#endregion Splash_Screen_Audio Toggle
#----------------------------------------------

#---------------------------------------------- 
#region Splash_Screen_Audio Help
#----------------------------------------------
$synchash.Splash_Screen_Audio_Button.add_Click({
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.Splash_Screen_Audio_Toggle.content
    Update-HelpFlyout -content 'Enables playback of a small video/audio clip in the Splash Screen during startup ;)' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -FontWeight bold
})
#---------------------------------------------- 
#endregion Splash_Screen_Audio Help
#----------------------------------------------

#---------------------------------------------- 
#region Use_Visualizations Toggle
#----------------------------------------------
if($thisapp.config.Use_Visualizations){
  $synchash.Current_Visualization_ComboBox.isEnabled = $true
  $synchash.Use_Visualizations_Toggle.isOn = $true
}else{
  $synchash.Use_Visualizations_Toggle.isOn = $false
  $synchash.Current_Visualization_ComboBox.isEnabled = $false
}
$synchash.Use_Visualizations_Toggle.add_Toggled({
    if($synchash.Use_Visualizations_Toggle.isOn -eq $true){      
      $synchash.Current_Visualization_ComboBox.isEnabled = $true 
      Add-Member -InputObject $thisapp.config -Name 'Use_Visualizations' -Value $true -MemberType NoteProperty -Force
    }
    else{         
      $synchash.Current_Visualization_ComboBox.isEnabled = $false 
      Add-Member -InputObject $thisapp.config -Name 'Use_Visualizations' -Value $false -MemberType NoteProperty -Force     
    }
}) 
#---------------------------------------------- 
#endregion Use_Visualizations Toggle
#----------------------------------------------

#---------------------------------------------- 
#region Use_Visualizations Help
#----------------------------------------------
$synchash.Use_Visualizations_Button.add_Click({
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.Use_Visualizations_Toggle.content
    Update-HelpFlyout -content 'Enables Audio Visualization in place of the video player, that generates animated imagery based on the audio spectrums of the media' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -FontWeight bold
    Update-HelpFlyout -content 'IMPORTANT' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -FontWeight bold -color orange
    Update-HelpFlyout -content 'Changes to this option will take place on the start of the next media. Visualization cannot be disabled/enabled during playback. Visualizations do not apply to any Spotify Media, or if using Web Players' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -color orange    
    Update-HelpFlyout -content 'INFO' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -FontWeight bold -color cyan
    Update-HelpFlyout -content 'Currently there is only 1 visualization option based on the VLC "Groom" visualization plugin. Enabling this will take effect for media with audio only, Video media will not display visualizations' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -color cyan
})
#---------------------------------------------- 
#endregion Use_Visualizations Help
#----------------------------------------------

#---------------------------------------------- 
#region Current_Visualization Combobox
#----------------------------------------------
$null = $synchash.Current_Visualization_ComboBox.items.add('Goom')
$null = $synchash.Current_Visualization_ComboBox.items.add('Spectrum')
if($thisapp.config.Current_Visualization){
  if($thisapp.config.Current_Visualization -eq 'Visual'){
    $selected_Visualization = 'Spectrum'
  }else{
    $selected_Visualization = $thisapp.config.Current_Visualization
  }
  $synchash.Current_Visualization_ComboBox.selecteditem = $selected_Visualization
}else{
  $synchash.Current_Visualization_ComboBox.Selectedindex = -1
}
$synchash.Current_Visualization_ComboBox.add_SelectionChanged({
    if($synchash.Current_Visualization_ComboBox.Selectedindex -ne -1){ 
      if($synchash.Current_Visualization_ComboBox.selecteditem -eq 'Spectrum'){
        $Visualization = 'Visual'
      }else{
        $Visualization = $synchash.Current_Visualization_ComboBox.selecteditem
      }      
      Add-Member -InputObject $thisapp.config -Name 'Current_Visualization' -Value $Visualization -MemberType NoteProperty -Force
    }
    else{          
      Add-Member -InputObject $thisapp.config -Name 'Current_Visualization' -Value '' -MemberType NoteProperty -Force     
    }
}) 
#---------------------------------------------- 
#endregion Current_Visualization Combobox
#----------------------------------------------

#---------------------------------------------- 
#region Current_Visualization Help
#----------------------------------------------
<#$synchash.Current_Visualization_Button.add_Click({
    $synchash.AppHelp_Flyout.isOpen = $true
    $synchash.HelpFlyout.Document.Blocks.Clear()
    $synchash.AppHelp_Flyout.Header = $synchash.Use_Visualizations_Toggle.content
    Update-HelpFlyout -content 'Enables Audio Visualization in place of the video player, that generates animated imagery based on the audio spectrums of the media' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -FontWeight bold
    Update-HelpFlyout -content 'IMPORTANT' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -FontWeight bold -color orange
    Update-HelpFlyout -content 'Changes to this option will take place on the start of the next media. Visualization cannot be disabled/enabled during playback. Visualizations do not apply to any Spotify Media, or if using Web Players' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -color orange    
    Update-HelpFlyout -content 'INFO' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -FontWeight bold -color cyan
    Update-HelpFlyout -content 'Currently there is only 1 visualization option based on the VLC "Groom" visualization plugin. Enabling this will take effect for media with audio only, Video media will not display visualizations' -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash -color cyan
    })
#>#---------------------------------------------- 
#endregion Current_Visualization Help
#----------------------------------------------

#---------------------------------------------- 
#region Apply Settings
#----------------------------------------------
$synchash.Apply_Settings_Button.Add_Click({ 
    try
    {
      $synchash.Spicetify_textblock.text = ''
      $synchash.Spicetify_transitioningControl.content = '' 
      $synchash.Twitch_Update_textblock.text = ''
      $synchash.Twitch_Update_transitioningControl.content = ''   
      if($synchash.Twitch_Update_Toggle.isOn -and $synchash.Twitch_Update_Interval_ComboBox.SelectedIndex -eq -1){
        Add-Member -InputObject $thisapp.config -Name 'Twitch_Update' -Value $false -MemberType NoteProperty -Force
        write-ezlogs "You must specify an interval when enabling option '$($synchash.Twitch_Update_Toggle.content)'" -showtime -warning
        $synchash.Twitch_Update_textblock.text = "[Warning] You must specify an interval when enabling option '$($synchash.Twitch_Update_Toggle.content)'"
        $synchash.Twitch_Update_textblock.foreground = 'Orange'
        $synchash.Twitch_Update_textblock.FontSize = 14
        $synchash.Twitch_Update_transitioningControl.content = $synchash.Twitch_Update_textblock  
        $synchash.Settings_ScrollViewer.ScrollToBottom()
        $synchash.Settings_ScrollViewer.UpdateLayout()
        return     
      }
      #$synchash.window.hide()
      #Start-SplashScreen -SplashTitle $thisScript.Name -SplashMessage 'Applying Settings...' -Splash_More_Info 'Please Wait' -thisScript $thisScript -current_folder $Current_folder -startup -log_file $logfile -Script_modules $Script_Modules 
      #$Dialog_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new() 
      #$progress_dialog = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowProgressAsync($synchash.Window,'Applying Settings','Please wait while settings are applied...',$true,$Dialog_Settings)
      #$progress_dialog.Wait(10)
      #$progress_dialog.ConfigureAwait($false)
      #$progress_dialog.GetAwaiter()     
    }
    catch{
      write-ezlogs 'An error occurred while displaying Mahapps progress dialog' -showtime -catcherror $_
    }
    if([System.IO.File]::Exists($thisapp.Config.Log_file) -and -not [string]::IsNullOrEmpty($synchash.Log_Path_textbox.text)){
      try{
        if([System.IO.Directory]::Exists($synchash.Log_Path_textbox.text)){       
          $logname = $thisapp.Config.Log_file | Split-Path -leaf
          $logfile_test = "$($synchash.Log_Path_textbox.text)\$($logname)"
          write-ezlogs "[TEST] >>>> Copying existing log file to new location $logfile_test" -showtime 
          #$null = Copy-item $thisApp.Config.Log_file -Destination $logfile -Force
          #$thisApp.Config.Log_file = $logfile
        }else{
          write-ezlogs "The provided directory path for the log file is invalid $($synchash.Log_Path_textbox.text)" -showtime -warning
        }
      }catch{
        write-ezlogs 'An exception occurred attempting to copy/move the log file' -showtime -catcherror $_
      }
    }
    if($synchash.Verbose_logging_Toggle.isOn){
      Add-Member -InputObject $thisapp.config -Name 'Verbose_logging' -Value $true -MemberType NoteProperty -Force
      $thisapp.config.Verbose_logging = $true
      $script:Verboselogging = $true 
    }
    else{
      Add-Member -InputObject $thisapp.config -Name 'Verbose_logging' -Value $false -MemberType NoteProperty -Force
      $thisapp.config.Verbose_logging = $false
      $script:Verboselogging = $false 
    }    
    if($synchash.Spicetify_Toggle.isOn){
      try{
        Add-Member -InputObject $thisapp.config -Name 'Use_Spicetify' -Value $true -MemberType NoteProperty -Force
        Add-Member -InputObject $thisapp.config -Name 'PODE_SERVER_ACTIVE' -Value $true -MemberType NoteProperty -Force            
        $synchash.Spicetify_textblock.text = "IMPORTANT! To apply Spicetify customizations to Spotify, you must click 'Apply to Spotify' to complete the process"       
        $synchash.Spicetify_textblock.foreground = 'Orange'
        $synchash.Spicetify_textblock.FontSize = 14
        $synchash.Spicetify_transitioningControl.content = $synchash.Spicetify_textblock 
      }catch{
        write-ezlogs "An exception occurred applying Spicetify customization" -showtime -catcherror $_
        Add-Member -InputObject $thisapp.config -Name 'PODE_SERVER_ACTIVE' -Value $false -MemberType NoteProperty -Force
        Add-Member -InputObject $thisapp.config -Name 'Use_Spicetify' -Value $false -MemberType NoteProperty -Force
        $synchash.Spicetify_textblock.text = '[ERROR] An exception occurred applying Spicetify customizations! See log' 
        $synchash.Spicetify_textblock.foreground = 'Tomato'
        $synchash.Spicetify_textblock.FontSize = 14
        $synchash.Spicetify_transitioningControl.content = $synchash.Spicetify_textblock        
      }                       
    }else{
      try
      {                     
        if($thisApp.config.Use_Spicetify){
          $synchash.Spicetify_textblock.text = "IMPORTANT! Spicetify is disabled. To remove customizations made to Spotify, you must click 'Remove from Spotify' to complete the process" 
          $synchash.Spicetify_textblock.foreground = 'Orange'
          $synchash.Spicetify_textblock.FontSize = 14
          $synchash.Spicetify_transitioningControl.content = $synchash.Spicetify_textblock                  
        }        
        Add-Member -InputObject $thisapp.config -Name 'Use_Spicetify' -Value $false -MemberType NoteProperty -Force                             
      }
      catch
      {
        write-ezlogs 'An error occurred while Removing Spicetify customizations' -showtime -catcherror $_
        Add-Member -InputObject $thisapp.config -Name 'PODE_SERVER_ACTIVE' -Value $false -MemberType NoteProperty -Force
        Add-Member -InputObject $thisapp.config -Name 'Use_Spicetify' -Value $false -MemberType NoteProperty -Force   
        $synchash.Spicetify_textblock.text = '[ERROR] An exception occurred removing Spicetify customizations! See log' 
        $synchash.Spicetify_textblock.foreground = 'Tomato'
        $synchash.Spicetify_textblock.FontSize = 14
        $synchash.Spicetify_transitioningControl.content = $synchash.Spicetify_textblock             
      }
    }   
    if(Get-Process *Spotify* -ErrorAction SilentlyContinue){Get-Process *Spotify* | Stop-Process -Force -ErrorAction SilentlyContinue}     
    #Start on windows logon
    $synchash.Start_On_Windows_transitioningControl.content = ''
    if($synchash.Start_On_Windows_Login_Toggle.isOn){
      $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default')
      $Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\").GetSubKeyNames() | foreach {    
        if($Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$_").GetValue('DisplayName') -match $($thisScript.name)){
          $install_folder = $Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$_").GetValue('InstallLocation')
        }
      }   
      if(!$install_folder){
        $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('CurrentUser', 'Default')
        $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\").GetSubKeyNames() | foreach {    
          if($Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$_").GetValue('DisplayName') -match $($thisScript.name)){
            $install_folder = $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$_").GetValue('InstallLocation')
          }
        } 
      }  
      $Main_exe = [System.IO.Path]::Combine($install_folder,"$($thisScript.name).exe")  
      if([system.io.file]::Exists($Main_exe)){
        $synchash.App_Exe_Path_textbox.IsEnabled = $false     
        $synchash.App_Exe_Path_Browse.IsEnabled = $false  
        $synchash.App_Exe_Path_Label.BorderBrush = 'LightGreen'      
      }else{
        $Main_exe = $synchash.App_Exe_Path_textbox.text
        $synchash.App_Exe_Path_textbox.IsEnabled = $true      
        $synchash.App_Exe_Path_Browse.IsEnabled = $true
        $synchash.App_Exe_Path_Label.BorderBrush = 'Red'       
      }       
      if([System.IO.Directory]::Exists($install_folder)){
        if([System.IO.File]::Exists($Main_exe)){
          Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $true -MemberType NoteProperty -Force
          Add-Member -InputObject $thisapp.config -Name 'App_Exe_Path' -Value $Main_exe -MemberType NoteProperty -Force         
          if([System.IO.File]::Exists((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')."$($thisScript.name)")){
            write-ezlogs "The app $($thisScript.name) is already configured to start on Windows logon." -Warning -showtime           
            $synchash.Start_On_Windows_textblock.text = "[Info] The app $($thisScript.name) is already configured to start on Windows logon."
            $synchash.Start_On_Windows_textblock.foreground = 'Cyan'
            $synchash.Start_On_Windows_textblock.FontSize = 14
            $synchash.Start_On_Windows_transitioningControl.content = $synchash.Start_On_Windows_textblock            
          }
          else
          {
            try
            {
              #Register-ScheduledTask -TaskName "$($thisScript.name) - Startup" -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Action (New-ScheduledTaskAction -Execute $thisapp.config.App_Exe_Path) -RunLevel Highest -Force -Verbose:$thisapp.Config.Verbose_logging
              New-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $($thisScript.name) -Value $Main_exe -Force
              if([System.IO.File]::Exists((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')."$($thisScript.name)")){
                write-ezlogs "[SUCCESS] The app $($thisScript.name) has been successfully configured to start automatically upon logon to Windows (current user)"
                $synchash.Start_On_Windows_textblock.text = "[SUCCESS] The app $($thisScript.name) has been successfully configured to start automatically upon logon to Windows (current user)"
                $synchash.Start_On_Windows_textblock.foreground = 'LightGreen'
                $synchash.Start_On_Windows_textblock.FontSize = 14
                $synchash.Start_On_Windows_transitioningControl.content = $synchash.Start_On_Windows_textblock                 
              }else{
                write-ezlogs "Unable to verify if $($thisScript.name) was successfully configured to start automatically upon logon to Windows (current user) - List of current user Run reg entries $((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run') | out-string)" -Warning -showtime
                $synchash.Start_On_Windows_textblock.text = "[WARNING] Unable to verify if $($thisScript.name) was successfully configured to start automatically upon logon to Windows (current user) - See log for details"
                $synchash.Start_On_Windows_textblock.foreground = 'Orange'
                $synchash.Start_On_Windows_textblock.FontSize = 14
                $synchash.Start_On_Windows_transitioningControl.content = $synchash.Start_On_Windows_textblock                
              }            
            }
            catch
            {
              write-ezlogs "An exception occurred attempting to create startup entry for exe path $($Main_exe)" -CatchError $_ -showtime -enablelogs
              Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $false -MemberType NoteProperty -Force
              $synchash.Start_On_Windows_Login_Toggle.isOn = $false
              $synchash.Start_On_Windows_textblock.text = "[ERROR] An exception occurred attempting to create startup entry for exe path $($Main_exe) -- Please check log for more details"
              $synchash.Start_On_Windows_textblock.foreground = 'Tomato'
              $synchash.Start_On_Windows_textblock.FontSize = 14
              $synchash.Start_On_Windows_transitioningControl.content = $synchash.Start_On_Windows_textblock              
            }
          }
        }
        else
        {         
          Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $false -MemberType NoteProperty -Force
          $synchash.Start_On_Windows_Login_Toggle.isOn = $false
          write-ezlogs "Could not find main exe file for $($thisScript.name) in folder ($install_folder). Please provide a valid path to the main exe file for $($thisScript.name) that you have full access to." -Warning  -showtime
          $synchash.Start_On_Windows_textblock.text = "[Warning] Could not find main exe file for $($thisScript.name) in folder ($install_folder). Please provide a valid path to the main exe file for $($thisScript.name) that you have full access to."
          $synchash.Start_On_Windows_textblock.foreground = 'Orange'
          $synchash.Start_On_Windows_textblock.FontSize = 14
          $synchash.Start_On_Windows_transitioningControl.content = $synchash.Start_On_Windows_textblock
          if([System.IO.File]::Exists((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')."$($thisScript.name)")){
            try
            {
              #Unregister-ScheduledTask -TaskName "$($thisScript.name) - Startup" -Confirm:$false -Verbose:$thisapp.Config.Verbose_logging 
              Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $($thisScript.name) -Force
              Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $false -MemberType NoteProperty -Force
              write-ezlogs "Removed app $($thisScript.name) from starting on Windows logon." -color cyan  -showtime          
            }
            catch
            {
              write-ezlogs "An exception occurred attempting to remove startup entry for: $($thisScript.name)" -CatchError $_ -showtime -enablelogs
              $synchash.Start_On_Windows_Login_Toggle.isOn = $false       
            }
          }                    
        }
        write-ezlogs ">>>> Saving App Exe Path setting $($thisapp.config.App_Exe_Path)" -color cyan -showtime
        write-ezlogs ">>>> Saving setting '$($synchash.Start_On_Windows_Login_Toggle.content) - $($thisapp.config.Start_On_Windows_Login)' " -color cyan -showtime
      }
      else{
        write-ezlogs "Could not find app install folder ($install_folder). Please provide a valid path to the main exe file for $($thisScript.name) that you have full access to." -Warning  -showtime 
        Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $false -MemberType NoteProperty -Force
        $synchash.Start_On_Windows_textblock.text = "[Warning] Could not find app install folder ($install_folder). Please provide a valid path to the main exe file for $($thisScript.name) that you have full access to."
        $synchash.Start_On_Windows_textblock.foreground = 'Orange'
        $synchash.Start_On_Windows_textblock.FontSize = 14
        $synchash.Start_On_Windows_transitioningControl.content = $synchash.Start_On_Windows_textblock        
        if([System.IO.File]::Exists((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')."$($thisScript.name)")){
          try
          {
            #Unregister-ScheduledTask -TaskName "$($thisScript.name) - Startup" -Confirm:$false -Verbose:$thisapp.Config.Verbose_logging 
            Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $($thisScript.name) -Force
            Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $false -MemberType NoteProperty -Force
            write-ezlogs "Removed app $($thisScript.name) from starting on Windows logon." -color cyan  -showtime          
          }
          catch
          {
            write-ezlogs "An exception occurred attempting to remove startup entry for: $($thisScript.name)" -CatchError $_ -showtime -enablelogs
            $synchash.Start_On_Windows_Login_Toggle.isOn = $false       
          }
        }        
      }
    }
    else
    {
      if([System.IO.File]::Exists((Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run')."$($thisScript.name)")){
        try
        {
          #Unregister-ScheduledTask -TaskName "$($thisScript.name) - Startup" -Confirm:$false -Verbose:$thisapp.Config.Verbose_logging
          Remove-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run' -Name $($thisScript.name) -Force 
          Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $false -MemberType NoteProperty -Force
          write-ezlogs "Removed app $($thisScript.name) from starting on Windows logon." -color cyan  -showtime
          $synchash.Start_On_Windows_textblock.text = "[SUCCESS] Removed app $($thisScript.name) from starting on Windows logon."
          $synchash.Start_On_Windows_textblock.foreground = 'LightGreen'
          $synchash.Start_On_Windows_textblock.FontSize = 14
          $synchash.Start_On_Windows_transitioningControl.content = $synchash.Start_On_Windows_textblock           
        }
        catch
        {
          write-ezlogs "An exception occurred attempting to remove startup entry for: $($thisScript.name)" -CatchError $_ -showtime -enablelogs
          $synchash.Start_On_Windows_Login_Toggle.isOn = $false
          $synchash.Start_On_Windows_textblock.text = "[ERROR] An exception occurred attempting to remove startup entry for: $($thisScript.name) -- Please check log for more details"
          $synchash.Start_On_Windows_textblock.foreground = 'Tomato'
          $synchash.Start_On_Windows_textblock.FontSize = 14
          $synchash.Start_On_Windows_transitioningControl.content = $synchash.Start_On_Windows_textblock          
        }
      }
      else
      {
        write-ezlogs "The app $($thisScript.name) is not configured to start on Windows logon." -enablelogs -showtime 
        $synchash.Start_On_Windows_Login_Toggle.isOn = $false
        $synchash.Start_On_Windows_textblock.text = "[Info] The app $($thisScript.name) is not configured to start on Windows logon."
        $synchash.Start_On_Windows_textblock.foreground = 'Cyan'
        $synchash.Start_On_Windows_textblock.FontSize = 14
        $synchash.Start_On_Windows_transitioningControl.content = $synchash.Start_On_Windows_textblock        
      }        
      Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $false -MemberType NoteProperty -Force
      $thisapp.config.Start_On_Windows_Login = $false
      write-ezlogs ">>>> Saving setting '$($synchash.Start_On_Windows_Login_Toggle.content) - $($thisapp.config.Start_On_Windows_Login)' "  -color cyan -showtime
    } 
    #Hardware Acceleration   
    if($synchash.Use_HardwareAcceleration_Toggle.isOn -eq $true){Add-Member -InputObject $thisapp.config -Name 'Use_HardwareAcceleration' -Value $true -MemberType NoteProperty -Force}
    else{Add-Member -InputObject $thisapp.config -Name 'Use_HardwareAcceleration' -Value $false -MemberType NoteProperty -Force}
    #Show Notifications
    if($synchash.Show_Notifications_Toggle.isOn -eq $true){Add-Member -InputObject $thisapp.config -Name 'Show_Notifications' -Value $true -MemberType NoteProperty -Force}
    else{Add-Member -InputObject $thisapp.config -Name 'Show_Notifications' -Value $false -MemberType NoteProperty -Force}  
    #Twitch Monitor
    if($thisapp.config.Twitch_Update -and $thisapp.config.Twitch_Update_Interval){
      try{
        Start-TwitchMonitor -Interval $thisapp.config.Twitch_Update_Interval -thisApp $thisapp -synchash $synchash -Verboselog
      }catch{
        write-ezlogs 'An exception occurred starting Start-TwitchMonitor' -showtime -catcherror $_
      }
    }else{
      Add-Member -InputObject $thisapp.config -Name 'Twitch_Update' -Value $false -MemberType NoteProperty -Force
    } 
    try{
      $thisapp.config | Export-Clixml -Path $App_Settings_File_Path -Force -Encoding UTF8
    }catch{
      write-ezlogs "An exception occurred saving settings to config file: $($App_Settings_File_Path)" -CatchError $_ -showtime
    }   
    #close-splashscreen
    #$synchash.Window.show()
    #if(!$thisApp.Config.Spicetify.is_paused){
    #  $synchash.timer.start()
    #}
    #$progress_dialog.ContinueWith()
    #$progress_dialog.ConfigureAwait($false)
})

#---------------------------------------------- 
#endregion Apply Settings
#----------------------------------------------

#---------------------------------------------- 
#region Background Update Timer
#----------------------------------------------
$synchash.update_background_timer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.update_background_timer.Add_Tick({
    try{
      #write-ezlogs "before maingrid_row2 Height $($synchash.MainGrid_Row2.Height)" -showtime
      if($synchash.streamlink.title){
        $synchash.Now_Playing_Label.content = "Now Playing - $($synchash.streamlink.User_Name): $($synchash.streamlink.title)"
        $Synchash.Main_Tool_Icon.Text = $synchash.Now_Playing_Label.content
      } 
      if($synchash.Background_cached_image){
        #if($thisApp.Config.Verbose_logging){write-ezlogs "Setting background image to $($synchash.Background_cached_image)" -enablelogs -showtime}                                 
        $syncHash.MainGrid_Background_Image_Source.Source = $synchash.Background_cached_image
        $syncHash.MainGrid_Background_Image_Source.Stretch = "UniformToFill"
        $syncHash.MainGrid_Background_Image_Source.Opacity = 0.25
        $syncHash.MainGrid_Background_Image_Source_transition.content = $syncHash.MainGrid_Background_Image_Source
      }else{
        if($thisApp.Config.Verbose_logging){write-ezlogs "No Background image provided, setting to default" -enablelogs -showtime}
        $syncHash.MainGrid_Background_Image_Source_transition.content = ''
        $syncHash.MainGrid_Background_Image_Source.Source = $null
      }          
      if(($synchash.vlc.VideoTrackCount -le 0 -and $synchash.Media_Current_Title -and !$synchash.Youtube_WebPlayer_URL -and !$thisApp.Config.Use_Visualizations) -or ($synchash.Media_Current_Title -and $synchash.Spotify_Status -eq 'Playing')){         
        $synchash.VideoView.Visibility="Hidden"     
        $synchash.VLC_Grid_Row2.Height="20*"
        $synchash.VLC_Grid_Row0.Height="*"
        $synchash.MediaView_TextBlock.text = $synchash.Media_Current_Title
        if($synchash.Background_cached_image){
          #if($thisApp.Config.Verbose_logging){write-ezlogs "Setting background image to $($synchash.Background_cached_image)" -enablelogs -showtime}
          $synchash.VLC_Grid_Row1.Height="100*" 
          $synchash.VLC_Grid.Visibility="Visible"   
          #write-ezlogs "Setting maingrid_row2 Height $($synchash.MainGrid_Row2.Height)" -showtime
          #$synchash.MainGrid_Row2.Height="220*"
          #write-ezlogs "[update_background_timer] Setting mediaview image: $($synchash.Background_cached_image)" -showtime
          $synchash.MediaView_Image.Source = $synchash.Background_cached_image
        }else{
          write-ezlogs "[update_background_timer] No image, Hiding VLC_Grid" -showtime
          $synchash.VLC_Grid_Row1.Height="*"
          $synchash.VLC_Grid.Visibility="Hidden" 
          $synchash.MediaView_Image.Source = $null
        }        
      }else{  
        if(!$synchash.Youtube_WebPlayer_URL){
          $synchash.VideoView.Visibility="Visible"   
          $synchash.VLC_Grid.Visibility="Visible"               
        } 
        if($synchash.vlc.VideoTrackCount -gt 0 -or $thisApp.Config.Use_Visualizations){
          #write-ezlogs "Setting maingrid_row2 to 200*" -showtime
          #$synchash.MainGrid_Row2.Height="200*"
          $synchash.FullScreen_Player_Button.isEnabled = $true
        }
        if($thisapp.config.Spotify_WebPlayer -and $synchash.Spotify_WebPlayer_URL -and $synchash.Spotify_WebPlayer_title){
          $synchash.VideoView.Visibility="Hidden"     
          $synchash.VLC_Grid_Row2.Height="20*"
          $synchash.VLC_Grid_Row0.Height="*"   
          $synchash.MediaView_TextBlock.text = $synchash.Spotify_WebPlayer_title  
        }else{
          $synchash.VLC_Grid_Row0.Height="100*"
          $synchash.VLC_Grid_Row2.Height="*"
          $synchash.VLC_Grid_Row1.Height="*"
          $synchash.MediaView_Image.Source = $null              
          $synchash.MediaView_TextBlock.text = ""       
        }                             

        #write-ezlogs "maingrid_row2 Height $($synchash.MainGrid_Row2.Height)" -showtime
      } 
      #write-ezlogs "VLC Video size: $($synchash.vlc.fps | out-string)"  
      #write-ezlogs "after maingrid_row2 Height $($synchash.MainGrid_Row2.Height)" -showtime      
      $this.Stop()                                    
    }catch{
      write-ezlogs 'An exception occurred executing update_status_timer' -showtime -catcherror $_
      $this.Stop()
    }
    $this.Stop()     
}.GetNewClosure())

#---------------------------------------------- 
#endregion Background Update Timer
#----------------------------------------------

#---------------------------------------------- 
#region Youtube WebPlayer Timer
#----------------------------------------------
$synchash.Youtube_WebPlayer_timer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.Youtube_WebPlayer_timer.Add_Tick({
    try{    
      $syncHash.MainGrid_Background_Image_Source_transition.content = ''
      $syncHash.MainGrid_Background_Image_Source.Source = $null
      $synchash.MediaView_Image.Source = $Null    
      $synchash.FullScreen_Player_Button.isEnabled = $false
      if($thisapp.config.Youtube_WebPlayer -and $synchash.Youtube_WebPlayer_URL -and $synchash.Youtube_WebPlayer_title){
        write-ezlogs "Replacing Vlc VideoView with Youtube WebPlayer for youtube playback of url $($synchash.Youtube_WebPlayer_URL)" -showtime
        #Start-WebNavigation -uri $synchash.Youtube_WebPlayer_URL -synchash $synchash -WebView2 $synchash.Webview2 -thisScript $thisScript -thisApp $thisApp\
        if($synchash.Webview2_Grid.children -contains $synchash.Webview2){
          $null = $synchash.Webview2_Grid.children.Remove($synchash.Webview2)
        }
        if($synchash.VLC_Grid.children -contains $synchash.VideoView){
          $null = $synchash.VLC_Grid.children.Remove($synchash.VideoView)
        }
        if($synchash.VLC_Grid.children -notcontains $synchash.Webview2){
          $null = $synchash.VLC_Grid.AddChild($synchash.Webview2) 
        }
        $synchash.VLC_Grid.UpdateLayout()             
        $synchash.VideoView.Content = $null   
        $synchash.VideoView.Visibility = 'Hidden'
        $synchash.VLC_Grid.Visibility="Visible"
        #$synchash.MainGrid_Row2.Height="200*"
        $synchash.VideoView.updatelayout() 
        $synchash.Webview2.updatelayout() 
        #$synchash.VideoView_Flyout.IsEnabled = $false
        #$synchash.VideoView_Flyout.Visibility = 'Hidden'   
        $synchash.MediaPlayer_Slider.Visibility = 'Hidden'
        $synchash.Now_Playing_Label.content = "Now Playing - $($synchash.Youtube_WebPlayer_title)" 
        $Synchash.Main_Tool_Icon.Text = $synchash.Now_Playing_Label.content
        if($synchash.MediaPlayer_CurrentDuration){
          if($synchash.MediaPlayer_CurrentDuration -match ":"){
            $total_time = $synchash.MediaPlayer_CurrentDuration        
            #$([timespan]::Parse('0:5:29'))
          }else{
            [int]$a = $($synchash.MediaPlayer_CurrentDuration / 1000);         
            [int]$c = $($([timespan]::FromSeconds($a)).TotalMinutes)     
            [int]$hrs = $($([timespan]::FromSeconds($a)).Hours)
            [int]$mins = $($([timespan]::FromSeconds($a)).Minutes)
            [int]$secs = $($([timespan]::FromSeconds($a)).Seconds)
            [int]$milsecs = $($([timespan]::FromSeconds($a)).Milliseconds)
            $total_time = "$hrs`:$mins`:$secs"
          }
        }
        $synchash.Media_Length_Label.content = "$total_time" + "/" + "$($synchash.MediaPlayer_TotalDuration)"        
        $synchash.Media_URL.text = $synchash.Youtube_WebPlayer_URL 
        $synchash.FullScreen_Player_Button.isEnabled = $true       
        Start-WebNavigation -uri $synchash.Youtube_WebPlayer_URL -synchash $synchash -WebView2 $synchash.Webview2 -thisScript $thisScript -thisApp $thisApp                       
      }elseif($synchash.VLC_Grid.Children.Name -contains 'Webview2'){
        $synchash.WebPlayer_Playing_timer.stop() 
        $synchash.WebPlayer_State = 0
        write-ezlogs "Replacing Youtube WebPlayer with Vlc VideoView" -showtime
        $synchash.VideoView.Content = $synchash.VideoView_Grid
        Start-WebNavigation -uri 'www.youtube.com' -synchash $synchash -WebView2 $synchash.Webview2 -thisScript $thisScript -thisApp $thisApp                        
        $synchash.VLC_Grid.children.Remove($synchash.Webview2)      
        if( $synchash.VLC_Grid.children.name -notcontains 'VideoView'){
          $null = $synchash.VLC_Grid.AddChild($synchash.VideoView)       
        } 
        if($synchash.Webview2_Grid.children -notcontains $synchash.Webview2){
          $null = $synchash.Webview2_Grid.AddChild($synchash.Webview2)         
        }     
        $synchash.Webview2_Grid.updatelayout()
        $synchash.VideoView.Visibility = 'Visible'
        $synchash.VLC_Grid.Visibility="Visible"
        #$synchash.VideoView_Flyout.IsEnabled = $true
        #$synchash.VideoView_Flyout.Visibility = 'Visible'
        #$synchash.MediaPlayer_Slider.Visibility = 'Visible'
        $synchash.Youtube_WebPlayer_title = '' 
        $synchash.Media_URL.text = ''
        $synchash.VLC_Grid.UpdateLayout() 
        $synchash.VideoView.updatelayout()  
        $synchash.Webview2.updatelayout()          
      }         
      $this.Stop()                                    
    }catch{
      write-ezlogs 'An exception occurred executing Youtube_WebPlayer_timer' -showtime -catcherror $_
      $this.Stop()
      $synchash.WebPlayer_Playing_timer.stop() 
    }
    $this.Stop()     
}.GetNewClosure())
#---------------------------------------------- 
#endregion Youtube WebPlayer Timer
#----------------------------------------------

#---------------------------------------------- 
#region Spotify WebPlayer Timer
#----------------------------------------------
$synchash.Spotify_WebPlayer_timer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.Spotify_WebPlayer_timer.Add_Tick({
    try{
      $syncHash.MainGrid_Background_Image_Source_transition.content = ''
      $syncHash.MainGrid_Background_Image_Source.Source = $null
      #$syncHash.MainGrid.Background = $synchash.Window.TryFindResource('MainGridBackGradient')
      $synchash.FullScreen_Player_Button.isEnabled = $false   
      if($thisapp.config.Spotify_WebPlayer -and $synchash.Spotify_WebPlayer_URL -and $synchash.Spotify_WebPlayer_title){
        write-ezlogs "Replacing Vlc VideoView with Spotify WebPlayer for Spotify playback of url $($synchash.Spotify_WebPlayer_URL)" -showtime
        #Start-WebNavigation -uri $synchash.Youtube_WebPlayer_URL -synchash $synchash -WebView2 $synchash.Webview2 -thisScript $thisScript -thisApp $thisApp
        if($synchash.Webview2_Grid.children -contains $synchash.Webview2){
          $Null = $synchash.Webview2_Grid.children.Remove($synchash.Webview2)
        }
        if($synchash.VLC_Grid.children -contains $synchash.VideoView){
          $synchash.VLC_Grid.children.Remove($synchash.VideoView)
        }
        if($synchash.VLC_Grid.children -notcontains $synchash.Webview2){
          $Null = $synchash.VLC_Grid.AddChild($synchash.Webview2) 
        } 
        $synchash.VLC_Grid.UpdateLayout()             
        $synchash.VideoView.Content = $null   
        $synchash.VideoView.Visibility = 'Hidden'
        $synchash.VLC_Grid.Visibility="Visible"
        $synchash.VideoView.updatelayout() 
        $synchash.Webview2.updatelayout()      
        #$synchash.Webview2.MaxHeight="0"   
        #$synchash.Webview2.MaxWidth="0"
        #$synchash.VideoView_Flyout.IsEnabled = $false
        #$synchash.VideoView_Flyout.Visibility = 'Hidden'   
        $synchash.MediaPlayer_Slider.Visibility = 'Visible'
        $synchash.Now_Playing_Label.content = "Now Playing - $($synchash.Spotify_WebPlayer_title)" 
        $Synchash.Main_Tool_Icon.Text = $synchash.Now_Playing_Label.content
        if($synchash.Background_cached_image -and $synchash.MediaView_Image.Source -ne $synchash.Background_cached_image){
          #if($thisApp.Config.Verbose_logging){write-ezlogs "Setting background image to $($synchash.Background_cached_image)" -enablelogs -showtime}   
          write-ezlogs "Setting MediaView_image: $($synchash.Background_cached_image)" -showtime       
          $synchash.MediaView_Image.Source = $synchash.Background_cached_image
          $synchash.VLC_Grid_Row1.Height="100*"
        }else{
          $synchash.MediaView_Image.Source = $null
          $synchash.VLC_Grid_Row1.Height="*"
        }
        if($synchash.MediaPlayer_CurrentDuration){
          if($synchash.MediaPlayer_CurrentDuration -match ":"){
            $total_time = $synchash.MediaPlayer_CurrentDuration        
            #$([timespan]::Parse('0:5:29'))
          }else{
            [int]$a = $($synchash.MediaPlayer_CurrentDuration / 1000);
            [int]$c = $($([timespan]::FromSeconds($a)).TotalMinutes)     
            [int]$hrs = $($([timespan]::FromSeconds($a)).Hours)
            [int]$mins = $($([timespan]::FromSeconds($a)).Minutes)
            [int]$secs = $($([timespan]::FromSeconds($a)).Seconds)
            [int]$milsecs = $($([timespan]::FromSeconds($a)).Milliseconds)
            $total_time = "$hrs`:$mins`:$secs"   
          }
        } 
        $synchash.Media_Length_Label.content = "$total_time"        
        $synchash.Media_URL.text = $synchash.Spotify_WebPlayer_URL         
        Start-WebNavigation -uri $synchash.Spotify_WebPlayer_URL -synchash $synchash -WebView2 $synchash.Webview2 -thisScript $thisScript -thisApp $thisApp                     
      }elseif($synchash.VLC_Grid.Children.Name -contains 'Webview2'){
        $synchash.WebPlayer_Playing_timer.stop() 
        write-ezlogs "Replacing Spotify WebPlayer with Vlc VideoView" -showtime
        $synchash.VideoView.Content = $synchash.VideoView_Grid
        Start-WebNavigation -uri 'www.Spotify.com' -synchash $synchash -WebView2 $synchash.Webview2 -thisScript $thisScript -thisApp $thisApp     
        if($synchash.VLC_Grid.Children.Name -contains 'Webview2'){
          $synchash.VLC_Grid.children.Remove($synchash.Webview2)  
        }                       
        if($synchash.VLC_Grid.children.name -notcontains 'VideoView'){
          $synchash.VLC_Grid.AddChild($synchash.VideoView)       
        }
        if($synchash.Webview2_Grid.children -notcontains $synchash.Webview2){
          $synchash.Webview2_Grid.AddChild($synchash.Webview2)       
        }              
        $synchash.Webview2_Grid.updatelayout()
        $synchash.VideoView.Visibility = 'Visible'
        $synchash.VLC_Grid.Visibility="Visible"
        # $synchash.VideoView_Flyout.Visibility = 'Visible'
        #$synchash.MediaPlayer_Slider.Visibility = 'Visible'
        $synchash.Spotify_WebPlayer_title = '' 
        $synchash.Media_URL.text = ''
        $synchash.MediaPlayer_Slider.Value = 0
        $synchash.MediaPlayer_slider.Visibility = 'Hidden'
        $synchash.VLC_Grid.UpdateLayout() 
        $synchash.VideoView.updatelayout()  
        $synchash.Webview2.updatelayout()          
      }         
      $this.Stop()                                    
    }catch{
      write-ezlogs 'An exception occurred executing Spotify_WebPlayer_timer' -showtime -catcherror $_
      $this.Stop()
      $synchash.WebPlayer_Playing_timer.stop() 
    }
    $this.Stop()     
}.GetNewClosure())
#---------------------------------------------- 
#endregion Spotify WebPlayer Timer
#----------------------------------------------

#---------------------------------------------- 
#region WebPlayer_Playing Timer
#----------------------------------------------
$synchash.WebPlayer_Playing_timer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.WebPlayer_Playing_timer.Interval = [timespan]::new(0,0,0,0,500)
$synchash.WebPlayer_Playing_timer.Add_Tick({
    try{
      $Current_Playing_Id = $null     
      if(($synchash.Youtube_WebPlayer_title -or $synchash.Spotify_WebPlayer_title) -and ($synchash.Webview2.CoreWebView2.IsDocumentPlayingAudio -or $synchash.Webview2.CoreWebView2.IsMuted -or $synchash.WebPlayer_State -ne 0 -or ($synchash.Spotify_WebPlayer_State.current_track.id -and $synchash.Spotify_WebPlayer_State.playbackstate -ne 0))){        
        if($synchash.Youtube_WebPlayer_title){
          #write-ezlogs "Executing Webview2 script..."
          if($thisApp.Config.Use_invidious){
            $synchash.Webview2_Script = @"
`n
var player_data = JSON.parse(document.getElementById('player_data').textContent);
var video_data = JSON.parse(document.getElementById('video_data').textContent);
var time = player.currentTime();
console.log(time);
  var playerdataJson =
  {
    Key: 'player_data',
    Value: player_data 
  };
  var videodataObject =
  {
    Key: 'video_data',
    Value: video_data 
  };
  var playerObject =
  {
    Key: 'player',
    Value: player 
  };
  var timeJson =
  {
    Key: 'time',
    Value: time 
  };
    window.chrome.webview.postMessage(playerdataJson);  
    window.chrome.webview.postMessage(videodataObject);
    window.chrome.webview.postMessage(playerObject);
    window.chrome.webview.postMessage(timeJson);
"@
          }else{
            $synchash.Webview2_Script =  @"
  var player = document.getElementById('movie_player');
  var state = player.getPlayerState();
  var videodata = player.getVideoData();
  var videoUrl = player.getVideoUrl();
  var time = player.getCurrentTime();
  var duration = player.getDuration();
  var volume = player.getVolume();
  var timeJson =
  {
    Key: 'time',
    Value: time 
  };
  var jsonObject =
  {
    Key: 'state',
    Value: state 
  };
  var durationObject =
  {
    Key: 'duration',
    Value: duration 
  };
  var volumeObject =
  {
    Key: 'volume',
    Value: volume 
  };
  var videodataObject =
  {
    Key: 'videodata',
    Value: videodata 
  };
  var videoUrlObject =
  {
    Key: 'videoUrl',
    Value: videoUrl
  };
    window.chrome.webview.postMessage(timeJson);  
    window.chrome.webview.postMessage(jsonObject);
    window.chrome.webview.postMessage(durationObject);
    window.chrome.webview.postMessage(volumeObject);
    window.chrome.webview.postMessage(videodataObject);
    window.chrome.webview.postMessage(videoUrlObject);
"@         
          
          }          
          $synchash.WebView2.ExecuteScriptAsync(
            $synchash.Webview2_Script       
          ) 
         
          if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> Starting WebPlayer_Playing_timer for youtube title: $($synchash.Youtube_WebPlayer_title)" -showtime}
          $synchash.Media_URL.text = $synchash.Youtube_WebPlayer_URL
          $Current_Playing_Id = $synchash.Current_playing_media.id
          if($synchash.Youtube_webplayer_current_Media.video_id -and $synchash.Youtube_webplayer_current_Media.title){
            $current_playing_Title = $synchash.Youtube_webplayer_current_Media.title
          }else{
            $current_playing_Title = $($synchash.Youtube_WebPlayer_title)
          }          
          $synchash.FullScreen_Player_Button.isEnabled = $true
        }elseif($synchash.Spotify_WebPlayer_title){
          if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> Starting WebPlayer_Playing_timer for Spotify title: $($synchash.Spotify_WebPlayer_title)" -showtime} 
          #$synchash.Webview2.Visibility = 'hidden'
          $synchash.Webview2_Script = @"

var state = getStatePosition();
//console.log(state);
	  var Spotify_state =
	  {
		Key: 'Spotify_state',
		Value: state
	  };
		window.chrome.webview.postMessage(Spotify_state);	
 SpotifyWeb.player.getVolume().then(volume => {
  let volume_percentage = volume * 100;
	  var Spotify_volume =
	  {
		Key: 'Spotify_volume',
		Value: volume
	  };
		window.chrome.webview.postMessage(Spotify_volume);	
   //console.log('The volume of the player is', volume_percentage);
});
"@

          $synchash.WebView2.ExecuteScriptAsync(
            $synchash.Webview2_Script       
          )
          $Current_Playing_Id = $synchash.Last_Played
          $current_playing_Title = $($synchash.Spotify_WebPlayer_title)
          $synchash.Media_URL.text = $synchash.Spotify_WebPlayer_URL
          $synchash.FullScreen_Player_Button.isEnabled = $false
        }
        $Current_playing = $synchash.PlayQueue_TreeView.Items | where  {$_.Header.id -eq $Current_Playing_Id} | select -Unique 
        if($synchash.WebPlayer_State -eq 2 -or $synchash.Spotify_WebPlayer_State.Paused){
          $synchash.Now_Playing_Label.content = "Paused - $current_playing_Title"   
          $Synchash.Main_Tool_Icon.Text = $synchash.Now_Playing_Label.content      
          return           
        }else{
          $synchash.Now_Playing_Label.content = "Now Playing - $current_playing_Title" 
          $Synchash.Main_Tool_Icon.Text = $synchash.Now_Playing_Label.content
        }               
        if($synchash.Invidious_webplayer_current_Media -and $thisApp.Config.Use_invidious){
          if($synchash.Invidious_webplayer_current_Media.length_seconds -match ":"){
            $total_time = $synchash.Invidious_webplayer_current_Media.length_seconds        
            #$([timespan]::Parse('0:5:29'))
          }else{
            $a = $synchash.Invidious_webplayer_current_Media.length_seconds
            [int]$hrs = $($([timespan]::FromSeconds($a)).Hours)
            [int]$mins = $($([timespan]::FromSeconds($a)).Minutes)
            [int]$secs = $($([timespan]::FromSeconds($a)).Seconds)
            [int]$milsecs = $($([timespan]::FromSeconds($a)).Milliseconds)
            $total_time = "$hrs`:$mins`:$secs"   
          }         
        }elseif($synchash.MediaPlayer_TotalDuration){
          if($synchash.MediaPlayer_TotalDuration -match ":"){
            $total_time =$synchash.MediaPlayer_TotalDuration       
            #$([timespan]::Parse('0:5:29'))
          }else{
            $a = $($synchash.MediaPlayer_TotalDuration)
            [int]$hrs = $($([timespan]::FromSeconds($a)).Hours)
            [int]$mins = $($([timespan]::FromSeconds($a)).Minutes)
            [int]$secs = $($([timespan]::FromSeconds($a)).Seconds)
            [int]$milsecs = $($([timespan]::FromSeconds($a)).Milliseconds)
            $total_time = "$hrs`:$mins`:$secs"  
          }          
        }
        try{
          if($synchash.MediaPlayer_CurrentDuration -match ":"){
            $total_time = $synchash.MediaPlayer_CurrentDuration       
            #$([timespan]::Parse('0:5:29'))
          }else{
            if($synchash.Spotify_WebPlayer_State.current_track.id){
              $a = $($([timespan]::FromMilliseconds($synchash.MediaPlayer_CurrentDuration)).TotalSeconds)
              #write-ezlogs "Current Duration: $($a)"
              #write-ezlogs "Total Duration: $($synchash.MediaPlayer_TotalDuration)"
              if($synchash.MediaPlayer_slider.Visibility -eq 'Hidden'){
                $synchash.MediaPlayer_slider.Visibility  = 'Visible'
              }
              if($synchash.MediaPlayer_TotalDuration -and $synchash.MediaPlayer_Slider.Maximum -ne $synchash.MediaPlayer_TotalDuration){
                $synchash.MediaPlayer_Slider.Maximum = $synchash.MediaPlayer_TotalDuration
              } 
              if(!$synchash.MediaPlayer_Slider.IsMouseOver){
                $synchash.MediaPlayer_Slider.Value = $a
              }                        
            }else{
              $a = $synchash.MediaPlayer_CurrentDuration
            }          
            #[int]$a = $($synchash.MediaPlayer_CurrentDuration / 1000); 
            #[int]$c = $($([timespan]::FromSeconds($a)).TotalMinutes)     
            [int]$hrs = $($([timespan]::FromSeconds($a)).Hours)
            #write-ezlogs "hrs..$($hrs)"
            [int]$mins = $($([timespan]::FromSeconds($a)).Minutes)
            #write-ezlogs "mins..$($mins)"
            [int]$secs = $($([timespan]::FromSeconds($a)).Seconds)
            #write-ezlogs "secs..$($secs)"
            [int]$milsecs = $($([timespan]::FromSeconds($a)).Milliseconds)
            $current_Progress = "$hrs`:$mins`:$secs"   
          }
          $synchash.Media_Length_Label.content = "$current_Progress" + "/" + "$total_time"                
        }catch{
          write-ezlogs "An exception occurred parsing current play duration for web player" -showtime -catcherror $_
        }                                       
        #$Current_playlist_items = $synchash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}

        if(!$Current_playing){    
          try{
            write-ezlogs "| Couldnt get current playing item with id $($Current_Playing_Id) from queue! Executing Get-Playlists" -showtime -warning
            Get-Playlists -verboselog:$false -synchash $synchash -thisApp $thisapp
            #$Current_playlist_items = $synchash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}    
            $Current_playing = $synchash.PlayQueue_TreeView.Items | where {$_.header.id -eq $Current_Playing_Id} | select -Unique           
            if(!$Current_playing){
              write-ezlogs '| Item does not seem to be in the queue' -showtime -warning
              if($thisapp.config.Current_Playlist.values -notcontains $Current_Playing_Id){
                write-ezlogs "| Adding $($Current_Playing_Id) to Play Queue" -showtime
                $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
                $index++
                $null = $thisapp.config.Current_Playlist.add($index,$Current_Playing_Id)         
              }else{
                write-ezlogs "| Play queue already contains $($Current_Playing_Id), refreshing one more time then I'm done here" -showtime -warning
              }
              $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
              Get-Playlists -verboselog:$false -synchash $synchash -thisApp $thisapp
              #$Current_playlist_items = $synchash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}    
              $Current_playing = $synchash.PlayQueue_TreeView.Items | where {$_.header.id -eq $Current_Playing_Id} | select -Unique         
              if(!$Current_playing){
                write-ezlogs "[ERROR] | Still couldnt find $($Current_Playing_Id) in the play queue, aborting!" -showtime -color red
                write-ezlogs "All Current items in queue: $($synchash.PlayQueue_TreeView.Items.header | out-string)" -showtime -warning
                #Update-Notifications -id 1 -Level 'ERROR' -Message "Couldnt find $($thisapp.Config.Last_Played) in the play queue, aborting WebPlayer_Playing_timer!" -VerboseLog -Message_color 'Tomato' -thisApp $thisapp -synchash $synchash
                $this.Stop()
              }else{write-ezlogs '| Found current playing item after adding it to the play queue and refreshing Get-Playlists, but this shouldnt have been needed!' -showtime -warning}                      
            }else{write-ezlogs '| Found current playing item after refreshing Get-Playlists' -showtime}   
          }catch{
            write-ezlogs "An exception occurred in WebPlayer_Playing_timer while trying to update/get current playing items" -showtime -catcherror $_
          }  
        }elseif($Current_playing.Header.title){   
          if($Current_playing.Header.title -notmatch '---> '){ 
            #$Current_playlist_items = $synchash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}
            $synchash.PlayQueue_TreeView.items.refresh()
            $Current_playing = $synchash.PlayQueue_TreeView.Items | where  {$_.Header.id -eq $Current_Playing_Id} | select -Unique 
            if($synchash.Now_Playing_Label.content -ne "$($Current_playing.Header.title)" ){
              $synchash.Now_Playing_Label.content = "Now Playing - $($Current_playing.Header.title)" 
              $Synchash.Main_Tool_Icon.Text = $synchash.Now_Playing_Label.content
            }
            $Current_playing.Header.title = "---> $($Current_playing.Header.title)"  
            try{           
              $Current_playing.Header.FontWeight = 'Bold'
              $Current_playing.Header.FontSize = 16 
              $current_playing.Header.PlayIcon = "CompactDiscSolid"
              #$peer = [System.Windows.Automation.Peers.ButtonAutomationPeer]($syncHash.btnSearch)
              #$invokeProv = $peer.GetPattern([System.Windows.Automation.Peers.PatternInterface]::Invoke)
              #$invokeProv.Invoke()
              $current_playing.Header.PlayIconRepeat = "Forever"
              $current_playing.Header.NumberVisibility = "Hidden"
              $current_playing.Header.NumberFontSize = 0
              $current_playing.Header.PlayIconVisibility = "Visibile"   
              $current_playing.Header.PlayIconEnabled = $true  
              $synchash.PlayQueue_TreeView.items.refresh()               
            }catch{
              write-ezlogs "An exception occurred updating properties for Current playing item $($Current_playing | out-string)" -showtime -catcherror $_
            }                         
          }                     
        }elseif($Current_playing.Header){
          $Current_playing.Header = "---> $($Current_playing.Header)"
          if($synchash.Now_Playing_Label.content -ne "$($Current_playing.Header)" ){
            $synchash.Now_Playing_Label.content = "Now Playing - $($Current_playing.Header)" 
            $Synchash.Main_Tool_Icon.Text = $synchash.Now_Playing_Label.content
          }
        }       
      }elseif(($synchash.Youtube_WebPlayer_title -or $synchash.Spotify_WebPlayer_title) -and $synchash.WebPlayer_State -eq 0 -and !$synchash.Invidious_webplayer_current_Media){
        write-ezlogs ">>>> WebPlayer finished playing, removing $($synchash.Current_playing_media.id) from queue and checking for and starting next track " -showtime        
        $synchash.WebMessageReceived = $Null
        Update-Playlist -Playlist 'Play Queue' -media $synchash.Current_playing_media -synchash $synchash -thisApp $thisApp -Remove -clear_lastplayed
        $synchash.Last_played = $Null
        $synchash.Youtube_WebPlayer_title = $Null
        $synchash.Spotify_WebPlayer_title = $Null
        $synchash.Temporary_Playback_Media = $null
        $synchash.Timer.start()
        $this.Stop()
      }else{
        write-ezlogs ">>>> Stopping WebPlayer_Playing_timer" -showtime
        $synchash.WebPlayer_State = 0
        $synchash.WebMessageReceived = $Null
        $this.Stop()
      }                                              
    }catch{
      write-ezlogs 'An exception occurred executing WebPlayer_Playing_timer' -showtime -catcherror $_
      $this.Stop()
    }  
}.GetNewClosure())
#---------------------------------------------- 
#endregion WebPlayer_Playing Timer
#----------------------------------------------

#---------------------------------------------- 
#region MainGrid_Top_TabControl
#----------------------------------------------
$synchash.MainGrid_Top_TabControl.add_SelectionChanged({
    try{
      if($synchash.MainGrid_Top_TabControl.SelectedIndex -eq 2 -or $synchash.MainGrid_Top_TabControl.SelectedIndex -eq 1){       
        $synchash.MainGrid_Row2_History = $synchash.MainGrid_Row2.Height
        $synchash.MainGrid_Row2.Height="400*"
      }else{
        if($synchash.MainGrid_Row2_History){
          $synchash.MainGrid_Row2.Height = $synchash.MainGrid_Row2_History
        }
      }        
    }catch{
      write-ezlogs "An exception occurred in MainGrid_Top_TabControl add_SelectionChanged  event" -CatchError $_ -showtime
    }  
})

#---------------------------------------------- 
#endregion MainGrid_Top_TabControl
#----------------------------------------------


if($thisApp.Config.startup_perf_timer){$UI_Controls_Perf = "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> UI Controls:           $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds"}
#############################################################################
#endregion UI Event Handlers 
#############################################################################

#############################################################################
#region Execute and Display Output 
############################################################################# 

#---------------------------------------------- 
#region Start Keywatcher
#----------------------------------------------
Start-KeyWatcher -synchash $synchash -thisApp $thisapp -Script_Modules $Script_Modules
if($thisApp.Config.startup_perf_timer){$Start_Keywatcher_Perf = "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Start-Keywatcher:           $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds"}
#---------------------------------------------- 
#endregion Start Keywatcher
#----------------------------------------------

#---------------------------------------------- 
#region Window Close
#----------------------------------------------
$synchash.Window.Add_Closing({
    try{
      $synchash.timer.stop()
      $synchash.Main_Tool_Icon.Dispose()
      [System.Windows.Forms.Application]::Exit() 
    }catch{
      write-ezlogs "An exception occurred in Add_Closing event" -showtime -catcherror $_
    }
})

$synchash.Window.Add_Closed({
    try
    {
      $synchash.VLC.stop()
      $synchash.VLC.Dispose() 
      $thisapp.Config.Spicetify = ''
      if(-not ((get-process *p*) | where {$_.MainWindowTitle -match "$($thisApp.Config.App_name) - Version:"})){
        $Spotify_process = Get-Process 'Spotify*' -ErrorAction SilentlyContinue
        if($Spotify_process){Stop-Process $Spotify_process -Force}
        $streamlink_process = Get-Process '*streamlink*' -ErrorAction SilentlyContinue
        if($streamlink_process){Stop-Process $streamlink_process -Force}
      } 
    }
    catch
    {
      Write-ezlogs "An exception occurred during add_closed cleanup" -showtime -catcherror $_
    }
    try
    {
      $thisapp.config | Export-Clixml -Path $App_Settings_File_Path -Force -Encoding UTF8    
      if($thisapp.Config.Verbose_logging){
        Write-ezlogs ">>>> Halting runspace cleanup job processing" -showtime
        Write-ezlogs ">>>> Calling garbage collector" -showtime  
      }
      if($jobCleanup.Flag){
        $jobCleanup.Flag = $false      
        #Stop jobcleanup runspace
        $jobCleanup.PowerShell.Dispose() 
        [GC]::Collect()   
      }
      #close podeserver
      if((NETSTAT.EXE -n) | where {$_ -match '127.0.0.1:8974'}){Invoke-RestMethod -Uri 'http://127.0.0.1:8974/CLOSEPODE' -UseBasicParsing -ErrorAction SilentlyContinue}         
      #---------------------------------------------- 
      #region Stop Logging
      #----------------------------------------------
      Stop-EZlogs -ErrorSummary $error -clearErrors -stoptimer -logOnly -logfile $logfile -enablelogs
      #---------------------------------------------- 
      #endregion Stop Logging
      #----------------------------------------------          
    }
    catch
    {
      Write-ezlogs "An exception occurred during add_closed cleanup" -showtime -catcherror $_
    }
    #While I dont condone suicide powershell, we need to make sure your console/process is closed    
    if($pid)
    {
      Stop-Process $pid -Force
    } 
})
#---------------------------------------------- 
#endregion Window Close
#----------------------------------------------

#---------------------------------------------- 
#region Display Main Window
#----------------------------------------------

# Create an application context for it to all run within. 
# This helps with responsiveness and threading.
try{
  #Add Validation Control
  $Show_UI_Measure = measure-command {
    $ErrorProvider = New-Object -TypeName System.Windows.Forms.ErrorProvider
    # Allow input to window for TextBoxes, etc
    [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($synchash.Window)
    [void][System.Windows.Forms.Application]::EnableVisualStyles()
    $synchash.Window.Show()
    $window_active = $synchash.Window.Activate()
    close-splashscreen
  }
  if($thisApp.Config.startup_perf_timer){$Show_UI_Perf =  "[$(Get-date -format $logdateformat)] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Show_UI:              $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds`n[$(Get-date -format $logdateformat)]     | Show_UI Total: $($Show_UI_Measure.Seconds) seconds - $($Show_UI_Measure.Milliseconds) Milliseconds"}

  $startup_timer_msg = "`n$Hide_Console_Perf`n$Start_SplashScreen_Perf`n$Local_Load_Modules_Perf`n$Get_thisScriptInfo_Perf`n$Start_EZlogs_Perf`n$Load_Modules_Perf`n$Initialize_Xaml_Perf`n$Confirm_Requirements_Perf`n$Import_media_Perf`n$Import_Spotify_Perf`n$Import_Youtube_Perf`n$Get_Playlists_Perf`n$Webview2_perf`n$Initialize_VLC_Perf`n$VLC_perf`n$UI_Controls_Perf`n$Start_Keywatcher_Perf`n$Show_UI_Perf`n----------------------------------------------------------`n    | Total UI startup: $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds`n----------------------------------------------------------"
  write-ezlogs "$startup_timer_msg"
  $synchash.Error = $error 
}catch{
  write-ezlogs "An uncaught exception occurred and main ApplicationContext ended" -showtime -catcherror $_
  if($error){
    write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
  }
}
try{
  $appContext = New-Object System.Windows.Forms.ApplicationContext 
  [void][System.Windows.Forms.Application]::Run($appContext)
}catch{
  write-ezlogs "An uncaught exception occurred and main ApplicationContext ended" -showtime -catcherror $_
  if($error){
    write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
  }
}finally{
  try{
    [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($synchash.Window)
    [void][System.Windows.Forms.Application]::EnableVisualStyles()  
    $appContext = New-Object System.Windows.Forms.ApplicationContext 
    [void][System.Windows.Forms.Application]::Run($appContext)
  }catch{
    write-ezlogs "An uncaught exception occurred and main ApplicationContext2 ended" -showtime -catcherror $_
    if($error){
      write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
    }
  }
}

#---------------------------------------------- 
#endregion Display Main Window
#----------------------------------------------

#############################################################################
#endregion Execute and Display Output 
############################################################################# 