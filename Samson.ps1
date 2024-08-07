<#
    .Name
    Samson

    .Version
    0.9.9

    .Build 
    BETA-001

    .SYNOPSIS
    Universal Media Player built in Powershell

    .DESCRIPTION
    Samson Media Player is a universal media player built in PowerShell that allows management and playback of media from multiple sources including local, Spotify, YouTube, Twitch and more. Powered by LibVLCSharp
       
    .Requirements
    - Powershell v3.0 or higher

    .PARAMETER MediaFile
    Path to valid local media file that will be added to library on startup or optionally to begin playing (if PlayMedia is true)

    .PARAMETER PlayMedia
    Immediately load and begin playback of valid media file provided by the MediaFile parameter

    .PARAMETER NoExit
    Prevent the main powershell process from closing when all primary UI threads have exited

    .PARAMETER FreshStart
    Force first time setup to run on startup. DESTRUCTIVE: removes all media profiles

    .PARAMETER OpentoPrimaryScreen
    Attempts to display main UI or move existing (if open) to the current primary monitor

    .PARAMETER StartMini
    Force the app to launch using the mini-player skin

    .PARAMETER NotrayMenu
    Skips creating and initializing the system tray menu and icon on startup

    .PARAMETER OptmizeAssemblies
    Forces execution of Optimize-Assemblies for rebuilding the GAC and Native Images Cache

    .PARAMETER dev_mode
    Force enables the dev_mode option as available within Settings - General Tab - Advanced Options

    .PARAMETER debug_mode
    Forces enables dev_mode and verbose logging mode only for the current session. Like dev_mode, also skips checking for existing Samson processes already running

    .PARAMETER test_mode
    Enables debug_mode and executes app in a temporary test enviroment. Default directories for logs, profiles and settings and temp files are changed to $env:temp\Samson_TestMode. Use parameter test_mode_path to customize

    .PARAMETER test_mode_path
    When used with test_mode, sets the custom directory where the Samson_TestMode folder will be created.

    .PARAMETER NoSplashUI
    Skips loading and displaying the splash screen on startup

    .PARAMETER No_SettingsPreload
    Skips preloading the settings UI and controls in the background on startup

    .PARAMETER force_modules
    Force's any required powershell modules and related packages to be installed/reinstalled

    .PARAMETER ResetPluginCache
    Forces libvlc to delete and recreate its plugin cache file

    .PARAMETER ForceSoftwareRender
    Forces all UI windows to use software rendering

    .PARAMETER Enable_Tor_Features
    Enables ability to use TOR and related VPN features if required resources are available. TOR features are only included in specific private builds

    .PARAMETER startup_perf_timer
    Enables startup and performance benchmarking timers. Default true. Does not negatively effect startup performance, or at worst extremely minor.

    .PARAMETER ForceHighDPI
    Forces the app to be Per Monitor DPI aware. This can help fix issues with blurry UI elements especially when using multiple monitors (EXPERIMENTAL - HAS ISSUES)

    .EXAMPLE
    \Samson.ps1

    .OUTPUTS
    Mahapps.Metro.Controls.MetroWindow

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
    Avalondock                 - https://github.com/Dirkster99/AvalonDock

    .NOTES
    Author: EZTechhelp
    Site  : https://www.eztechhelp.com
#> 

#############################################################################
#region Configurable Script Parameters
#############################################################################
Param(
  [string]$MediaFile,
  [switch]$PlayMedia,
  [switch]$NoExit,
  [switch]$FreshStart,
  [switch]$OpentoPrimaryScreen,
  [switch]$StartMini,
  [switch]$NotrayMenu,
  [switch]$NoMediaLibrary,
  [switch]$OptmizeAssemblies,
  [switch]$dev_mode,
  [switch]$test_mode,
  [string]$test_mode_path = $env:temp,
  [switch]$NoSplashUI,
  [switch]$debug_mode,
  [switch]$No_SettingsPreload = $true,
  [switch]$force_modules,
  [switch]$ResetPluginCache,
  [switch]$ForceSoftwareRender,
  [switch]$Uninstall,
  [switch]$Enable_Tor_Features,
  [switch]$startup_perf_timer = $true,
  [switch]$Enable_Test_Features,
  [switch]$ForceHighDPI
)

$startup_stopwatch = [system.diagnostics.stopwatch]::StartNew() #startup performance timer
$FreshStart_Required = $false #Does this version have changes that require triggering first run setup (and rebuild all profiles) for existing installs?
$PlaylistRebuild_Required = $false #Does this version have changes that require rebuilding custom playlist profiles?
if($test_mode){
  $test_mode_path = [system.io.path]::Combine($test_mode_path,'Samson_TestMode') #Path to be used when test_mode is enabled. Forces app to use this folder for all locations outside app install/root directory
  $debug_mode = $true
  $Enable_Test_Features = $true
  $env:appdata = $test_mode_path
  $env:temp = [system.io.path]::Combine($test_mode_path,'Temp')
  if(!([System.IO.Directory]::Exists($test_mode_path))){
    $null = New-item $test_mode_path -ItemType Directory -Force -ErrorAction SilentlyContinue
  }
}
#----------------------------------------------
#region Log Variables
#----------------------------------------------
$logdateformat = 'MM/dd/yyyy h:mm:ss tt' # sets the date/time appearance format for log file and console messages
$verboselog = $false #Enables extra verbose output to logs and console, meant for dev/troubleshooting - Outdated and no longer used
$logfile_directory = "$env:appdata\" # directory where log file should be created if enabled
#----------------------------------------------
#endregion Log Variables
#----------------------------------------------

#---------------------------------------------- 
#region Global Variables - DO NOT CHANGE UNLESS YOU KNOW WHAT YOU'R DOING
#----------------------------------------------
$required_appnames = 'Spotify','Spicetify','streamlink','vb-cable'
if(!$notrayMenu){
  $trayMenu = $true #Enables system tray icon, menu and mini-tray player
}
#---------------------------------------------- 
#endregion Global Variables - DO NOT CHANGE UNLESS YOU KNOW WHAT YOU'R DOING
#----------------------------------------------
#############################################################################
#endregion Configurable Script Parameters
#############################################################################

#############################################################################
#region global functions - Must be run first and/or are script agnostic
#############################################################################
$PSModuleAutoLoadingPreference = 'All'
$ProgressPreference = 'SilentlyContinue'
#---------------------------------------------- 
#region Use Run-As Function
#----------------------------------------------
function Use-RunAs
{    
  # Check if script is running as Adminstrator and if not use RunAs 
  # Use Check Switch to check if admin 
  # http://gallery.technet.microsoft.com/scriptcenter/63fd1c0d-da57-4fb4-9645-ea52fc4f1dfb

  param([Switch]$Check,[Switch]$ForceReboot,[Switch]$uninstall_Module,[switch]$FreshStart,[string]$logfile = $logfile,[switch]$RestartAsUser) 
  $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator') 
  if ($Check) { return $IsAdmin }    
  $ScriptPath = [System.IO.Path]::Combine($thisApp.Config.Current_folder,"$($thisApp.Config.App_Name).ps1")
  if(![System.IO.File]::Exists($ScriptPath)){
    $ScriptPath = $((Get-PSCallStack).ScriptName | Where-Object {$_ -notmatch '.psm1'} | Select-Object -First 1)
  }  
  write-ezlogs "[USE-RUNAS] >>>> Checking if running as administrator"
  if([System.IO.File]::Exists($ScriptPath)){  
    if (-not $IsAdmin -or $ForceReboot -or $RestartAsUser){  
      try{                
        if($uninstall_Module){
          $arg = "-NoProfile -NoLogo -ExecutionPolicy Bypass -file `"$($ScriptPath)`" -NonInteractive"
        }else{
          $arg = "-NoProfile -NoLogo -ExecutionPolicy Bypass -file `"$($ScriptPath)`""
        }
        if($freshstart){
          $arg += " -Freshstart"
        }
        if($dev_mode){
          $arg += " -dev_mode"
        }
        if($debug_mode){
          $arg += " -debug_mode"
        }
        if($hash.Window.IsVisible){
          Update-SplashScreen -hash $hash -Close
        }
        if($RestartAsUser){
          $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default') 
          foreach ($keyName in $Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\").GetSubKeyNames()) {
            if($Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$keyName").GetValue('DisplayName') -match $($thisApp.Config.App_Name)){
              $install_folder = $Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$keyName").GetValue('InstallLocation')
            }
          }  
          if(!$install_folder){
            $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('CurrentUser', 'Default')
            foreach ($keyName in $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\").GetSubKeyNames()) {  
              if($Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$keyName").GetValue('DisplayName') -match $($thisApp.Config.App_Name)){
                $install_folder = $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$keyName").GetValue('InstallLocation')
              }
            }
          } 
          [void]$Registry.Dispose()
          $ExePath = [System.IO.Path]::Combine($install_folder,"$($thisApp.Config.App_Name).exe")
          if([System.IO.File]::Exists($ExePath)){
            #runas /trustlevel:0x20000 $processpath
            #$arg = $Null
            if($freshstart){
              $arg = " -Freshstart"
            }
            if($dev_mode){
              $arg += " -dev_mode"
            }
            if($debug_mode){
              $arg += " -debug_mode"
            }
            #runas /trustlevel:0x20000 "$ExePath $arg"
            if([System.IO.File]::Exists("$env:ProgramW6432\PowerShell\7\pwsh.exe")){
              $processpath = "$env:ProgramW6432\PowerShell\7\pwsh.exe"
            }else{         
              $processpath = "$psHome\powershell.exe"
            }
            write-ezlogs "Restarting as user with Path: $($processpath)" -warning 
            #runas /trustlevel:0x20000 "$processpath $arg"
            $newProc = new-object System.Diagnostics.ProcessStartInfo "PowerShell"
            # Specify what to run, you need the full path after explorer.exe
            $newProc.WindowStyle = 'Hidden'
            $newProc.Arguments = "explorer.exe '$ExePath'"
            $newProc.UseShellExecute = $false
            $newProc.CreateNoWindow = $true
            $Process = [System.Diagnostics.Process]::Start($newProc)
          }else{
            write-ezlogs "[USE-RUNAS] Cant find exe path to restart as user: $($ExePath) - Args: $($arg)" -warning
            [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
            [void][System.Windows.Forms.MessageBox]::Show("Cant find exe path to restart as user: $($ExePath) - ($($thisScript.name) Media Player - $($thisScript.Version) - PID: $($process.id))`n`nIt is likely that this installation is corrupt!`n`nThe app will close and you will need to launch it manually again, making sure not to run as administrator","[ERROR] - $($thisScript.name)",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
            exit
          }
        }else{
          write-ezlogs "[USE-RUNAS] Restarting as admin with Path: $($ScriptPath) - Args: $($arg)" -warning
          $verb = 'RunAs'
          if([System.IO.File]::Exists("$env:ProgramW6432\PowerShell\7\pwsh.exe")){
            $process = Start-Process "$env:ProgramW6432\PowerShell\7\pwsh.exe" -Verb $verb -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden
          }else{         
            Start-Process "$psHome\powershell.exe" -Verb $verb -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden
          }
        }
      }catch { 
        write-ezlogs "[USE-RUNAS] An exception occurred attempting to restart script" -catcherror $_
        break               
      } 
      if($pid){
        stop-process $pid -Force -ErrorAction SilentlyContinue
      }      
      exit # Quit this session of powershell 
    }  
  }else{   
    write-ezlogs "[USE-RUNAS] Could not find Scriptpath: $ScriptPath -- MyInvocation: $($MyInvocation | out-string)" -warning
    break  
  }  
}
#---------------------------------------------- 
#endregion Use Run-As Function
#----------------------------------------------

#----------------------------------------------
#region Get-ThisScriptInfo Function
#----------------------------------------------
function Get-thisScriptInfo
{
  param (
    [switch]$VerboseDebug,
    [string]$logfile_directory,
    [string]$ScriptPath = $PSCommandPath,
    [string]$Scriptblock,
    [string]$Script_Temp_Folder,
    [switch]$No_Script_Temp_Folder
  )
  $thisScript = @{
    Path = $ScriptPath
    Folder = $PSScriptRoot
  }
  $Contents = [RegEx]::Matches($Scriptblock, '^\s*\<#([\s\S]*?)#\>').value
  [RegEx]::Matches($Contents, "(^|[`r`n])\s*\.(.+)\s*[`r`n]|$") | & { process {
      If ($Caption -in 'Version','Name','Build','Temp_Folder'){
        $thisScript.$Caption = $Contents.SubString($Start, $_.Index - $Start).Trim()
      }
      $Caption = $_.Groups[2].ToString().Trim()
      $Start = $_.Index + $_.Length
  }}
  $Contents = $Null
  if(!$No_Script_Temp_Folder){
    if(!$Script_Temp_Folder){
      $Script_Temp_Folder = [System.IO.Path]::Combine($env:TEMP, $($thisScript.Name))
    }else{
      $Script_Temp_Folder = [System.IO.Path]::Combine($Script_Temp_Folder, $($thisScript.Name))
    }
    if(!([System.IO.Directory]::Exists($Script_Temp_Folder))){
      try{
        [void][System.IO.Directory]::CreateDirectory($Script_Temp_Folder)
      }catch{
        Write-error "[ERROR] Exception creating script temp directory: $Script_Temp_Folder - $($_ | out-string)"
      }
    }
    $thisScript.TempFolder = $Script_Temp_Folder
  }
  return $thisScript
}
#---------------------------------------------- 
#endregion Get-ThisScriptInfo Function
#----------------------------------------------

#---------------------------------------------- 
#region Initialize-Modules Function
#TODO: Not likely needed anymore - to review
#----------------------------------------------
function Initialize-Modules {
  param
  (
    $local_modules,
    $Remote_modules,
    [switch]$force,
    [switch]$update,
    [switch]$enablelogs,
    [switch]$Verboselog,
    [switch]$InstallPSGet,
    [switch]$local_import,
    [string]$Current_folder,
    [switch]$use_Runspace,
    [string]$logfile
  )
  $ExistingPaths = $Env:PSModulePath -split ';' -replace '\\$',''
  if($local_import -and $local_modules){
    if([System.IO.directory]::exists("$current_Folder\Modules\")){
      $module_folder = "$current_Folder\Modules\"
    }else{
      $module_folder = "$PSScriptRoot\Modules\"
    }
    foreach($m in  $local_modules){
      $module_dir = $null
      if($m -eq  'Microsoft.PowerShell.SecretStore.Extension'){
        $module_dir = "$module_folder\Microsoft.PowerShell.SecretStore\"
      }else{
        $module_dir = $module_folder
      }    
      if([System.IO.File]::exists("$module_dir\$m\$m.psd1")){
        $module_path = "$module_dir\$m\$m.psd1"
      }elseif([System.IO.File]::exists("$module_dir\$m\$m.psm1")){
        $module_path = "$module_dir\$m\$m.psm1"
      }elseif([System.IO.File]::exists("$([System.IO.Directory]::GetParent($module_dir))\$m\$m.psm1")){
        $module_path = "$([System.IO.Directory]::GetParent($module_dir))\$m\$m.psm1"
      }elseif([System.IO.File]::exists(".\Modules\$m\$m.psm1")){
        $module_path = ".\Modules\$m\$m.psm1"
      }elseif([System.IO.File]::exists(".\Modules\$m\$m.psd1")){
        $module_path = ".\Modules\$m\$m.psd1"
      }elseif([System.IO.directory]::exists("$module_dir\$m")){
        $module_file = [System.IO.directory]::EnumerateFiles("$module_dir\$m","$m.psd1",'AllDirectories')
        if([System.IO.File]::exists($module_file)){
          $module_path = $module_file
        }else{
          "[$([datetime]::Now)] [Initialize-Modules ERROR] Unable to find module $m -- module_dir: $module_dir" | Out-File -FilePath $logfile -Encoding unicode -Append
        }
      }else{
        "[$([datetime]::Now)] [Initialize-Modules ERROR] Unable to find module $m -- module_dir: $module_dir" | Out-File -FilePath $logfile -Encoding unicode -Append
      }     
      try{
        $module_root_path = [System.IO.Directory]::GetParent($module_path).fullname
        if($ExistingPaths -notcontains $module_root_path) {
          $Env:PSModulePath = $module_root_path + ';' + $Env:PSModulePath
        }
        $PSModuleAutoLoadingPreference = 'All'
      }catch{
        "[$([datetime]::Now)] [Initialize-Modules ERROR] An exception occurred importing module $m from path  $module_path $($_ | out-string)" | Out-File -FilePath $logfile -Encoding unicode -Append
        exit
      }      
    }
    return
  }
}
#---------------------------------------------- 
#endregion Initialize-Modules Function
#----------------------------------------------
#############################################################################
#endregion global Functions
#############################################################################

#############################################################################
#region Initialization Events
#############################################################################
#----------------------------------------------
#region Script initialization
#----------------------------------------------
try{ 
  if($startup_perf_timer){
    $thisScript_Measure = [system.diagnostics.stopwatch]::StartNew() 
  } 
  $Global:thisapp = [hashtable]::Synchronized(@{})
  $hashsetup = [hashtable]::Synchronized(@{})
  #Set startup logging and variable paths
  $thisScript = Get-ThisScriptInfo -Scriptblock $MyInvocation.MyCommand.ScriptBlock
  $logfile_directory = "$logfile_directory\$($thisScript.name)\Logs"
  if(!([System.IO.Directory]::Exists($logfile_directory))){
    [void][System.IO.Directory]::CreateDirectory($logfile_directory)
  }   
  $current_folder = $thisScript.Folder
  $startup_log = "$logfile_directory\$($thisScript.name)-$($thisScript.Version)-Startup.log"
  $perf_log = "$logfile_directory\$($thisScript.name)-$($thisScript.Version)-Perf.log"
  $Threading_log_file = "$logfile_directory\$($thisScript.name)-$($thisScript.Version)-Threading.log"
  $Error_log_file = "$logfile_directory\$($thisScript.name)-$($thisScript.Version)-Errors.log"
  $App_Settings_Directory = "$env:appdata\$($thisScript.name)"
  $App_Settings_File_Path = "$App_Settings_Directory\$($thisScript.name)-SConfig.xml"

  #Current session only global variables
  if($Enable_Tor_Features -and [system.io.file]::Exists("$Current_Folder\Modules\EZT-TorrentManager\EZT-TorrentManager.psm1")){
    [bool]$thisApp.Enable_Tor_Features = $true
  }
  if([system.io.file]::Exists("$Current_Folder\Modules\Get-Updates\Get-Updates.psm1")){
    [bool]$thisApp.Enable_Update_Features = $true
  }
  if([system.io.file]::Exists("$Current_Folder\Modules\Show-FeedbackForm\Show-FeedbackForm.psm1")){
    [bool]$thisApp.Enable_Feedback_Features = $true
  } 

  #Add Main Module path to env modules
  $ExistingPaths = $Env:PSModulePath -split ';' -replace '\\$',''
  if($ExistingPaths -notcontains "$Current_Folder\Modules"){
    $Env:PSModulePath = "$Current_Folder\Modules" + ';' + $Env:PSModulePath
  } 
  #Add Secret Store module to env path
  $secret_store = "$Current_Folder\Modules\Microsoft.PowerShell.SecretStore\" 
  if($ExistingPaths -notcontains $secret_store){
    $Env:PSModulePath = $secret_store + ';' + $Env:PSModulePath
  }
  if($thisScript_Measure){
    $thisScript_Measure.stop()
  }
  #Check to ensure our enviroment is as expected
  if(!$thisScript.Version){
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $PSCallStack = Get-PSCallStack | Select-Object *
    $oReturn=[System.Windows.Forms.MessageBox]::Show("!!FATAL!!`nUnable to determine current version! The app cannot continue to load.`n`nThisScript: $($thisScript | out-string)`n`nCurrent_folder: $($current_folder)`n`nPSCallStack: $(Get-PSCallStack | out-string)`n`nPSCallStack.InvocationInfo: $($PSCallStack.InvocationInfo | out-string)`n`nPSCommandPath: $($PSCommandPath)","$($thisScript.name)",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
    exit
  }

  if($startup_perf_timer -or $thisApp.Config.Startup_perf_timer){
    $Check_Version_Measure = [system.diagnostics.stopwatch]::StartNew()
  }
    
  #Get install folder from registry if exits
  $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default')
  foreach($key in $Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\").GetSubKeyNames()){
    if($Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$key").GetValue('DisplayName') -match $thisScript.Name){
      $install_folder = $Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$key").GetValue('InstallLocation')
    }
  }
  [void]$Registry.Dispose()
  if(!$install_folder){
    $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('CurrentUser', 'Default')
    if($Registry){
      foreach($key in $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\").GetSubKeyNames()){
        if($Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$key").GetValue('DisplayName') -match $thisScript.Name){
          $install_folder = $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$key").GetValue('InstallLocation')
        }
      }
      [void]$Registry.Dispose()
    }
  }
  $Registry = $Null
  $key = $Null
  if(!([System.IO.File]::Exists("$logfile_directory\$($thisScript.Name)-$($thisScript.version).log"))){
    #No log file for this version, is there a version installed?
    if($install_folder -and !$FreshStart_Required){
      $Message = "[$([datetime]::Now)] [$($thisScript.name):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> No log found for this version $($thisScript.version)..Existing install found at $install_folder...FreshStart_Required not set for this version...continuing startup"
      write-output $Message
      [System.IO.File]::AppendAllText($startup_log, $Message,[System.Text.Encoding]::Unicode)
    }else{
      $Message = "[$([datetime]::Now)] [$($thisScript.name):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> No log found for this version $($thisScript.version) and no existing install found or FreshStart_Required: $($FreshStart_Required) -- will execute first time setup..."
      write-output $Message
      [System.IO.File]::AppendAllText($startup_log, $Message,[System.Text.Encoding]::Unicode)
      $FreshStart = $true
    }
  }elseif(![System.IO.Directory]::Exists("$env:appdata\$($thisScript.Name)\MediaProfiles")){
    $message = "[$([datetime]::Now)] [$($thisScript.name):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> MediaProfiles directory not found, executing first time setup..."
    write-output $Message
    [System.IO.File]::AppendAllText($startup_log, $Message,[System.Text.Encoding]::Unicode)
    $FreshStart = $true
  }elseif($FreshStart){
    $message = "[$([datetime]::Now)] [$($thisScript.name):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> FreshStart parameter applied, executing first time setup..."
    write-output $Message
    [System.IO.File]::AppendAllText($startup_log, $Message,[System.Text.Encoding]::Unicode)
  }else{
    $FreshStart = $false
  } 

  #Load helper assembly, contains primary data classes and many other helpers
  if(-not [bool]('Media' -as [Type])){
    [void][System.Reflection.Assembly]::LoadFrom("$current_folder\Assembly\EZT-MediaPlayer\EZT_MediaPlayer.dll")
  }
  #Convert old config to new format if exists
  Import-Module -Name "$Current_Folder\Modules\PSSerializedXML\PSSerializedXML.psm1" -NoClobber -DisableNameChecking
  if(-not [System.IO.File]::Exists($App_Settings_File_Path) -and [System.IO.File]::Exists("$App_Settings_Directory\$($thisScript.name)-Config.xml")){
    try{
      $thisapp.Config = Import-Clixml "$App_Settings_Directory\$($thisScript.name)-Config.xml" -ErrorAction SilentlyContinue
      Export-SerializedXML -InputObject $thisApp.Config -Path $App_Settings_File_Path -isConfig
    }catch{
      [System.IO.File]::AppendAllText($startup_log, "[$([datetime]::Now)] [$($thisScript.name):$((Get-PSCallStack)[0].ScriptLineNumber)] [ERROR] Converting config file '$App_Settings_Directory\$($thisScript.name)-Config.xml' to '$App_Settings_File_Path': $($_ | out-string)",[System.Text.Encoding]::Unicode)
    }
  }
  #Check Version and Start Splash Screen 
  if(!$thisapp.Config -and [System.IO.File]::Exists($App_Settings_File_Path)){
    $thisapp.Config = Import-SerializedXML -Path $App_Settings_File_Path -isConfig
    if($FreshStart_Required -and $thisApp.Config.App_Version -lt $($thisScript.version)){
      $FreshStart = $true
      $message = "[$([datetime]::Now)] [$($thisScript.name):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Older Existing version '$($thisApp.Config.App_Version)' detected and FreshStart_Required for this version '$($thisScript.version)', starting first time setup for new version $($thisScript.version)"
      write-output $message
      [System.IO.File]::AppendAllText($startup_log, $message,[System.Text.Encoding]::Unicode)
    }elseif(-not [string]::IsNullOrEmpty($thisScript.Build) -and $thisApp.Config.App_Build -lt $thisScript.Build){
      $message = "[$([datetime]::Now)] [$($thisScript.name):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Older Existing build $($thisApp.Config.App_Build) detected, checking use-runas permissions after install of new build $($thisScript.Build)"
      write-output $message
      [System.IO.File]::AppendAllText($startup_log, $message,[System.Text.Encoding]::Unicode)
      $thisApp.Config.App_Build = $thisScript.Build
      if((Use-RunAs -Check) -and $thisApp.Config.Import_Local_Media){
        foreach ($path in $thisApp.Config.Media_Directories){
          if(($Path).StartsWith("\\")){
            $isNetworkPath = $true
            break
          }elseif([system.io.driveinfo]::new($Path).DriveType -eq 'Network'){
            $isNetworkPath = $true
            break
          }
        }
        if($isNetworkPath){
          $message = "[$([datetime]::Now)] [$($thisScript.name):$((Get-PSCallStack)[0].ScriptLineNumber)] | Running as admin and found network paths configured for local media directories, restarting under user context"
          write-output $message
          [System.IO.File]::AppendAllText($startup_log, $Message,[System.Text.Encoding]::Unicode)
          Use-RunAs -RestartAsUser -logfile $startup_log
          exit       
        }
      }
      if($FreshStart_Required){
        $message = "[$([datetime]::Now)] [$($thisScript.name):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Freshstart_Required is set for new build $($thisScript.Build) - starting first time setup"
        write-output $message
        [System.IO.File]::AppendAllText($startup_log, $Message,[System.Text.Encoding]::Unicode)
        $FreshStart = $true
      }
    }
  }
  if($Check_Version_Measure){
    $Check_Version_Measure.Stop()
  } 
  #Dev Mode
  if(!$Dev_mode -and !$debug_mode){
    $dev_mode = $thisApp.Config.Dev_mode
  }elseif($debug_mode){
    $dev_mode = $true
  }

  #Start Logging  
  if($startup_perf_timer -or $thisApp.Config.Startup_perf_timer){
    $Global:Start_EZLogs_Measure = [system.diagnostics.stopwatch]::StartNew()
  }
  Import-Module -Name "$Current_Folder\Modules\Write-EZLogs\Write-EZLogs.psm1" -NoClobber -DisableNameChecking -Scope Local
  Import-Module -Name "$Current_Folder\Modules\Start-Runspace\Start-Runspace.psm1" -NoClobber -DisableNameChecking
  $Script:logfile = Start-EZLogs -logfile_directory $logfile_directory -ScriptPath $PSCommandPath -Global_Log_Level $thisApp.Config.Log_Level -thisApp $thisApp -Logfile_Name "$($thisScript.Name)-$($thisScript.version).log" -StartLogWriter -logdateformat $logdateformat
  write-ezlogs "####################### MAIN STARTUP BEGIN #######################"  -Perf -linesbefore 1
  if($Start_EZLogs_Measure){
    $Start_EZLogs_Measure.Stop()
  }

  #Uninstall
  if($Uninstall){
    Import-Module -Name "$Current_Folder\Modules\Uninstall-Application\Uninstall-Application.psm1" -NoClobber -DisableNameChecking -Scope Local
    Uninstall-Application -thisApp $thisApp -globalstopwatch $startup_stopwatch
  }

  #Verify app not already running
  if($startup_perf_timer -or $thisApp.Config.Startup_perf_timer){
    $Check_Existing_Process_Measure = [system.diagnostics.stopwatch]::StartNew()
  } 

  #Set DPI per-monitor v2 awareness for Win10 1607 or higher or per monitor for Win8.1 or higher
  #This needs to be set as early as possible, before any UI at all is displayed, thus why its here
  #Potentially check registery to see if powershell process has already manually been set to high dpi
  #TODO: Put this under settings to allow users to choose to enable 'High DPI Mode'
  try{
    if($thisApp.Config.Enable_HighDPI -or $ForceHighDPI){
      $DPIAware = [User32Wrapper.DPIAware]::IsProcessDPIAware()
      if([System.Environment]::OSVersion.Version.Major -ge 10 -and [System.Environment]::OSVersion.Version.Build -ge 14393){       
        if($DPIAware){         
          $CurrentAwarness = [User32Wrapper.DPIAware]::GetAwarenessFromDpiAwarenessContext([User32Wrapper.DPIAware]::GetThreadDpiAwarenessContext())   
          if($CurrentAwarness -ne 2){
            if($install_folder){
              $App_Exe_Path = [System.IO.Path]::Combine("$install_folder","$($thisScript.Name).exe")
            }else{
              $App_Exe_Path = [System.IO.Path]::Combine("$current_folder","$($thisScript.Name).exe")
            }  
            $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('CurrentUser', 'Default')
            $keys = $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers\")
            $HighDPIReg = $keys.GetValueNames() | & { process {
                if($_ -eq $App_Exe_Path -or $_ -match "$($thisScript.Name).exe"){
                  $keys.GetValue($_)
                }
            }}
            write-ezlogs "Cannot set prcoess DPI awareness as its already been set (Current: $CurrentAwarness) -- HighDPIReg: $HighDPIReg" -warning
            if(!$HighDPIReg -and [system.io.file]::Exists($App_Exe_Path)){
              write-ezlogs "| Forcing by setting registry HIGHDPIAWARE for process: $($App_Exe_Path)"
              #TODO: If keeping this, make sure to add a removal process for this in the uninstaller
              $null = New-ItemProperty -Path 'Registry::\HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers\' -Name $App_Exe_Path -Value '~ HIGHDPIAWARE' -PropertyType 'String' -Force -ErrorAction SilentlyContinue
            }
            #[void][User32Wrapper.DPIAware]::SetProcessDpiAwarenessContext([User32Wrapper.DPIAware]::PER_MONITOR_AWARE_V2)
            #[void][User32Wrapper.DPIAware]::SetThreadDpiAwarenessContext([User32Wrapper.DPIAware]::PER_MONITOR_AWARE_V2)
            #[void][User32Wrapper.DPIAware]::SetProcessDpiAwareness(2)
          }else{
            write-ezlogs ">>>> Process has already been set to be DPI aware -- CurrentAwarness: $CurrentAwarness"
          }
        }else{
          write-ezlogs ">>>> Enabling Per-Monitor v2 DPI awareness for current process"
          [void][User32Wrapper.DPIAware]::SetProcessDpiAwarenessContext([User32Wrapper.DPIAware]::PER_MONITOR_AWARE_V2)
        }       
      }elseif(([System.Environment]::OSVersion.Version.Major -eq 6 -and [System.Environment]::OSVersion.Version.Minor -eq 3) -or [System.Environment]::OSVersion.Version.Major -gt 6 ){
        write-ezlogs ">>>> Enabling Per-Monitor DPI awareness for current process"
        [void][User32Wrapper.DPIAware]::SetProcessDpiAwareness(2)
      }else{
        write-ezlogs "Unable to configure high DPI for current process, OS not supported!" -warning
      }
    }   
  }catch{
    write-ezlogs "An exception occurred attempting to set DPI awareness" -catcherror $_
  }finally{
    if($Registry -is [System.IDisposable]){
      $Registry.dispose()
    }
    if($keys -is [System.IDisposable]){
      $keys.dispose()
    }
  }

  if($dev_mode){
    write-ezlogs "###################### !!DEV OVERRIDE MODE ENABLED!! ######################" -Warning -linesbefore 1 -logfile $startup_log
  }elseif(($Process = [System.Management.ManagementObjectSearcher]::new([System.Management.ObjectQuery]::new("SELECT * FROM Win32_Process WHERE Name LIKE 'p%w%s%h%' AND CommandLine LIKE '%$($thisScript.name).ps1%' AND ProcessID != '$PID'")).get()) -ne $Null){
    try{   
      if($OpentoPrimaryScreen){
        [void][System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
        Import-Module -Name "$Current_Folder\Modules\Get-HelperFunctions\Get-HelperFunctions.psm1" -NoClobber -DisableNameChecking
        write-ezlogs "Existing Process with PID $($process.ProcessId) for ($($thisScript.name) Media Player - $($thisScript.Version)) already running!`n[$([datetime]::Now.ToString($logdateformat))] | CommandLine: $($process.commandline)" -Warning -logfile $startup_log
        $CurrentMonitor = [System.Windows.Forms.Screen]::FromPoint([System.Windows.Forms.Cursor]::Position)
        write-ezlogs "| OpentoPrimaryScreen parameter applied, attempting to move existing process main window to primary screen: $($CurrentMonitor.DeviceName)" -logfile $startup_log
        $Current_windows = (Get-CurrentWindows).GetEnumerator() | Where-Object {($_.Value -match "$($thisScript.name) Media Player" -and $_.Value -match $thisScript.Version) -or $_.Value -like "* - $($thisScript.name) Media Player"}
        if($CurrentMonitor.workingarea.Width -le 1920){
          $X = ($CurrentMonitor.workingarea.Left + 100)
        }else{
          $x = ($CurrentMonitor.workingarea.Left + 460)
        }
        $Current_windows | & { process {
            Set-Window -WindowHandle $_.key -X $x -Y ($CurrentMonitor.WorkingArea.Top + 100)
            Set-WindowState -WindowHandle $_.key -State HIDE -logfile $startup_log
            Set-WindowState -WindowHandle $_.key -State SHOW -logfile $startup_log
        }}
      }else{
        $message = @"
`n[$([datetime]::Now.ToString($logdateformat))] ###################### Startup ERROR: $($thisScript.name) - $($thisScript.Version) ######################
[$([datetime]::Now.ToString($logdateformat))] [WARNING] Existing Process with PID $($process.ProcessId) for ($($thisScript.name) Media Player - $($thisScript.Version)) already running!`n[$([datetime]::Now.ToString($logdateformat))] | Process.CommandLine: $($Process.CommandLine)
"@
        write-output $message
        [System.IO.File]::AppendAllText($startup_log, $Message,[System.Text.Encoding]::Unicode)
        [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        $oReturn=[System.Windows.Forms.MessageBox]::Show("[WARNING]`nExisting Process with PID '$($process.ProcessId)' started at '$($Process.CreationDate)' for ($($thisScript.name) Media Player - $($thisScript.Version)) already running!`n`nDo you wish to force close the existing process and continue startup? Selecting no will cancel this startup session.","$($thisScript.name)",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning)
      }
    }catch{
      write-output "[$([datetime]::Now.ToString($logdateformat))] [STARTUP-ERROR] An exception occurred showing warning about existing process $($process.id) $($_ | out-string)" | out-file $startup_log -Force -Append -Encoding unicode
    }finally{
      if($oReturn -eq 'Yes' -and $process.ProcessId){
        Stop-Process -Id $process.ProcessId -Force -ErrorAction SilentlyContinue
      }else{
        exit
      }     
    }       
  }
  if($process -is [System.IDisposable]){
    $process.dispose()
    $process = $Null
  }
  if($Check_Existing_Process_Measure){
    $Check_Existing_Process_Measure.Stop()
  }
  if($startup_perf_timer -or $thisApp.Config.Startup_perf_timer){
    $Start_SplashScreen_Measure = [system.diagnostics.stopwatch]::StartNew() 
  } 
  $Start_SplashScreen = Start-SplashScreen -SplashTitle $($thisScript.name) -SplashMessage 'Starting Up...' -current_folder $($current_folder) -startup -perf_log $perf_log -log_file $startup_log -threading_Log_file $Threading_log_file -Verboselog:$dev_mode -startup_stopwatch $startup_stopwatch -startup_perf_timer $startup_perf_timer -PlayAudio:$thisapp.config.SplashScreenAudio -FreshStart:$FreshStart -NoSplashUI:$NoSplashUI -thisScript $thisScript
  if($Start_SplashScreen_Measure){
    $Start_SplashScreen_Measure.Stop()
  }
  if($thisScript_Measure){
    write-ezlogs "Get-thisscriptinfo and Basic Startup Measure" -PerfTimer $thisScript_Measure
    $thisScript_Measure = $Null
  }
  if($Check_Version_Measure){
    write-ezlogs "Check Version Measure" -PerfTimer $Check_Version_Measure
    $Check_Version_Measure = $Null
  }
  if($Start_EZLogs_Measure){
    write-ezlogs "Start-EZLogs Measure" -PerfTimer $Start_EZLogs_Measure
    $Start_EZLogs_Measure = $Null
  }
  if($Check_Existing_Process_Measure){
    write-ezlogs "Check Existing Process Measure" -PerfTimer $Check_Existing_Process_Measure
    $Check_Existing_Process_Measure = $Null
  }
  if($Start_SplashScreen){
    write-ezlogs $Start_SplashScreen -Perf -showtime:$false -CallBack:$false -NoTypeHeader
    $Start_SplashScreen = $Null
  }
  if($Start_SplashScreen_Measure){
    write-ezlogs "Start-SplashScreen Launch" -PerfTimer $Start_SplashScreen_Measure
    $Start_SplashScreen_Measure = $Null
  }
}catch{
  write-ezlogs 'An exception occured during script initialization' -showtime -catcherror $_
  [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
  [void][System.Windows.Forms.MessageBox]::Show("An exception occured during script initialization for ($($thisScript.name) Media Player - $($thisScript.Version) - PID: $($process.id))`n`nERROR: $($_ | out-string)`n`nRecommened reviewing logs for details.`n`nThis app will now close","[ERROR] - $($thisScript.name)",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
  Stop-Process $pid -Force
}
#---------------------------------------------- 
#endregion Script initialization
#----------------------------------------------

#----------------------------------------------
#region Initialize-XAML
#----------------------------------------------
try{
  #Load and Initialize UI XAML
  if($startup_perf_timer -or $thisApp.Config.Startup_perf_timer){
    $Initialize_Xaml_Measure = [system.diagnostics.stopwatch]::StartNew()
  }   
  #Primary Syncronized hashtable
  $Global:synchash = [hashtable]::Synchronized([hashtable]::new(800,1, [StringComparer]::CurrentCultureIgnoreCase))
  Import-Module -Name "$Current_Folder\Modules\Initialize-XAML\Initialize-Xaml.psm1" -NoClobber -DisableNameChecking -Scope Local
  Initialize-XAML -Current_folder $Current_folder -thisApp $thisApp -synchash $synchash
  if($synchash.Window){   
    $synchash.Window.Title = "$($thisScript.Name) Media Player - $($thisScript.Version)"
    if($synchash.window.TaskbarItemInfo){
      $synchash.window.TaskbarItemInfo.Description = $synchash.Window.Title
    }
    $synchash.window.WindowTitleBrush = "Black"
    $synchash.window.NonActiveWindowTitleBrush = '#FF242424'
    $synchash.Window.icon = "$($Current_folder)\Resources\Samson_Icon_NoText1.ico"
  }
}catch{
  write-ezlogs 'An exception occured during XAML initialization' -showtime -catcherror $_
  [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
  [void][System.Windows.Forms.MessageBox]::Show("An exception occured during XAML initialization for ($($thisScript.name) Media Player - $($thisScript.Version) - PID: $($process.id))`n`nERROR: $($_ | out-string)`n`nRecommened reviewing logs for details.`n`nThis app will now close","[ERROR] - $($thisScript.name)",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
  Stop-Process $pid -Force
}finally{
  Remove-Module -Name Initialize-Xaml -Force -ErrorAction SilentlyContinue
  if($Initialize_Xaml_Measure){
    $Initialize_Xaml_Measure.stop()
    write-ezlogs "Initialize-Xaml" -PerfTimer $Initialize_Xaml_Measure -GetMemoryUsage:$thisApp.Config.Memory_perf_measure
    $Initialize_Xaml_Measure = $Null
  }
  if(!$synchash -or !$synchash.Window){
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void][System.Windows.Forms.MessageBox]::Show("An issue occured during XAML initialization for ($($thisScript.name) Media Player - $($thisScript.Version) - PID: $($process.id))`n`nRecommened reviewing logs for details.`n`nThis app will now close","[ERROR] - $($thisScript.name)",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
    Stop-Process $pid -Force
  }
}
#----------------------------------------------
#endregion Initialize-XAML
#----------------------------------------------

#----------------------------------------------
#region App Configuration
#----------------------------------------------
#Load App Configs
try{
  $AppConfig_Load_Measure = [system.diagnostics.stopwatch]::StartNew()
  $App_Settings_Directory = "$env:appdata\$($thisScript.Name)"
  if(!([System.IO.Directory]::Exists($App_Settings_Directory))){
    write-ezlogs ">>>> Creating App Settings Directory $App_Settings_Directory" -showtime -color cyan
    [void][System.IO.Directory]::CreateDirectory($App_Settings_Directory)
  }
  if(-not [System.IO.File]::Exists($App_Settings_File_Path)){
    $FreshStart = $true
    write-ezlogs ">>> This version $($thisScript.version) has not been run on this system before, App settings file not found..creating default $App_Settings_File_Path, wiping caches and initiating first time setup" -showtime
    $thisapp.Config = [Config]@{
      App_Name = $($thisScript.Name)
      App_Version = $($thisScript.Version)
      Media_Profile_Directory = "$env:appdata\$($thisScript.Name)\MediaProfiles"
      image_Cache_path = "$($thisScript.TempFolder)\Images"
      Playlist_Profile_Directory = "$env:appdata\$($thisScript.Name)\PlaylistProfiles"
      EQPreset_Profile_Directory = "$env:appdata\$($thisScript.Name)\EQPresets"
      Bookmarks_Profile_Directory = "$env:appdata\$($thisScript.Name)\Bookmarks"
      Friends_Profile_Directory = "$env:appdata\$($thisScript.Name)\Friends"
      Config_Path = $App_Settings_File_Path
      Playlists_Profile_Path = "$env:appdata\$($thisScript.Name)\PlaylistProfiles\All-Playlists-Profile.xml"
      Templates_Directory = "$($Current_folder)\Resources\Templates"
      Current_Folder = "$($Current_folder)"
      Log_file = $logfile
      Streamlink_HTTP_Port = "53888"
      ShowTitleBar = $true
      LocalMedia_FastImporting = $true
      LocalMedia_ImportMode = 'Fast'
      LocalMedia_SkipDuplicates = $true
      Skip_Twitch_Ads = $true
      Auto_Playback = $true
      Open_VideoPlayer = $true
      Youtube_WebPlayer = $true
      Use_HardwareAcceleration = $true
      Spotify_WebPlayer = $true
      Current_Playlist = [SerializableDictionary[int,string]]::new()
      History_Playlist = [SerializableDictionary[int,string]]::new()
      Custom_EQ_Presets = [System.Collections.Generic.List[Custom_EQ_Preset]]::new()
      Twitch_Playlists = [System.Collections.Generic.List[Twitch_Playlist]]::new()
      Webview2_Extensions = [System.Collections.Generic.List[WebExtension]]::new()
      Youtube_Cookies = [System.Collections.Generic.List[Cookie]]::new()
      EQ_Presets = [System.Collections.Generic.List[EQ_Preset]]::new()
      EQ_Bands = [System.Collections.Generic.List[EQ_Band]]::new()
      GlobalHotKeys = [System.Collections.Generic.List[GlobalHotKey]]::new()
      VLC_Log_File = "$($logfile_directory)\$($thisScript.Name)-$($thisScript.Version)-VLC.log"
      Streamlink_Log_File = "$($logfile_directory)\$($thisScript.Name)-$($thisScript.Version)-Streamlink.log"
      Startup_Log_File = $startup_log
      Launcher_Log_File = "$($logfile_directory)\$($thisScript.Name)-Launcher.log"
      Error_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Errors.log"
      LocalMedia_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Local.log"
      Discord_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Discord.log"
      Libvlc_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Libvlc.log"
      Perf_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Perf.log"
      Webview2_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Webview2.log"
      Setup_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Setup.log"
      Threading_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Threading.log"
    }
  }else{   
    if(!$thisapp.config){
      write-ezlogs ">>>> Loading main app config: $App_Settings_File_Path" -showtime
      $thisapp.Config = Import-SerializedXML -Path $App_Settings_File_Path -isConfig
    }
    $thisapp.Config.Log_file = $logfile
    $thisapp.Config.Config_Path = $App_Settings_File_Path
    $thisapp.Config.Playlists_Profile_Path = "$env:appdata\$($thisScript.Name)\PlaylistProfiles\All-Playlists-Profile.xml"
    $thisapp.Config.Current_Folder = $Current_folder
    $thisapp.Config.image_Cache_path = "$($thisScript.TempFolder)\Images"
    $thisapp.Config.App_Name = $($thisScript.Name)
    $thisapp.Config.Templates_Directory = "$($Current_folder)\Resources\Templates"
    $thisapp.Config.Playlist_Profile_Directory = "$env:appdata\$($thisScript.Name)\PlaylistProfiles"
    $thisapp.Config.EQPreset_Profile_Directory = "$env:appdata\$($thisScript.Name)\EQPresets"
    $thisapp.Config.VLC_Log_File = "$($logfile_directory)\$($thisScript.Name)-$($thisScript.Version)-VLC.log"
    $thisapp.Config.LibVLC_Log_File = "$($logfile_directory)\$($thisScript.Name)-$($thisScript.Version)-LibVLC.log"    
    $thisapp.Config.Streamlink_Log_File = "$($logfile_directory)\$($thisScript.Name)-$($thisScript.Version)-Streamlink.log"
    $thisapp.Config.Startup_Log_File = $startup_log
    $thisapp.Config.Error_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Errors.log"
    $thisapp.Config.LocalMedia_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Local.log"
    $thisapp.Config.Discord_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Discord.log"
    $thisapp.Config.Perf_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Perf.log"
    $thisapp.Config.Webview2_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Webview2.log"
    $thisapp.Config.Setup_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Setup.log"
    $thisapp.Config.Threading_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Threading.log"
    $thisapp.Config.Friends_Profile_Directory = "$env:appdata\$($thisScript.Name)\Friends"
  }
  $thisapp.config.App_Version = $($thisScript.Version)
  $thisapp.config.App_Exe_Path = ([System.IO.Path]::Combine($install_folder,"$($thisApp.Config.App_Name).exe"))
  $thisapp.config.App_Build = $thisScript.Build
  $thisapp.config.logfile_directory = $logfile_directory
  $thisapp.config.SpotifyMedia_logfile = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Spotify.log"
  $thisapp.config.YoutubeMedia_logfile = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Youtube.log"
  $thisapp.config.TwitchMedia_logfile = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Twitch.log"
  $thisapp.config.Tor_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-TOR.log"
  $thisapp.config.Uninstall_Log_File = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version)-Uninstall.log"
  $thisapp.config.Startup_perf_timer = $Startup_perf_timer
  $thisapp.config.Temp_Folder = $thisScript.TempFolder
  $thisapp.config.Dev_mode = [bool]$dev_mode
  $thisapp.config.Debug_mode = [bool]$debug_mode

  #Create config properties only if they dont already exist (no overwrite)
  if(!$thisApp.Config.Youtube_Cookies.SyncRoot){
    $thisApp.Config.Youtube_Cookies = [System.Collections.Generic.List[Cookie]]::new()
  }
  if(![bool]($thisApp.Config.psobject.Properties['Webview2_Extensions'])){
    $thisApp.Config.Webview2_Extensions = [System.Collections.Generic.List[WebExtension]]::new()
  }
  if([string]::IsNullOrEmpty($thisApp.Config.LocalMedia_SkipDuplicates)){
    $thisApp.Config.LocalMedia_SkipDuplicates = $true
  }
  if([string]::IsNullOrEmpty($thisApp.Config.LocalMedia_ImportMode)){
    $thisApp.Config.LocalMedia_ImportMode = 'Fast'
  }
  #TODO: Need to finish adding into settings - allow picking from list of approved VPNs
  if([string]::IsNullOrEmpty($thisApp.Config.Use_Preferred_VPN)){
    $thisApp.Config.Use_Preferred_VPN = $true   
  }
  if([string]::IsNullOrEmpty($thisApp.Config.Preferred_VPN)){
    $thisApp.Config.Preferred_VPN = 'ProtonVPN'
  }
  #TODO: Check if these still needed, move ones that are
  #Create state tracking properties
  $synchash.Streamlink = ''
  $synchash.Last_Played = ''
  $synchash.WebPlayer_State = 0

  #Create blank Spotify Playlist collection if no existing
  if(!$thisApp.Config.Spotify_Playlists.SyncRoot){
    $thisapp.config.Spotify_Playlists = [System.Collections.Generic.List[object]]::new()
  }

  #Set various verbose logging values
  if($thisApp.Config.Dev_mode){
    $thisApp.Config.Vlc_Verbose_logging = '3'
    $thisApp.Config.Streamlink_Verbose_logging = 'debug'
  }else{ 
    #TODO: Implement setting UI option for: $thisapp.config.Vlc_Verbose_logging  
    $thisApp.Config.Vlc_Verbose_logging = '1'
    if([string]::IsNullOrEmpty($thisApp.Config.Streamlink_Verbose_logging)){
      $thisApp.Config.Streamlink_Verbose_logging = 'info'
    }
  }
  #Object for thread locking playlists
  $synchash.all_playlists_ListLock = [PSCustomObject]::new()

  #Save App Settings
  if($FreshStart){
    try{
      write-ezlogs "| Saving app config: $App_Settings_File_Path" -showtime
      Export-SerializedXML -InputObject $thisApp.Config -Path $thisapp.Config.Config_Path -isConfig
    }catch{
      write-ezlogs "An exception occurred when saving config file to path $App_Settings_File_Path" -showtime -catcherror $_
    }
  }
  #Disable IPv6, can cause timeout and other issues
  if(![System.AppContext]::TryGetSwitch("System.Net.DisableIPv6",[ref]$true)){
    write-ezlogs "Disabling IPv6 via System.Net.DisableIPv6" -Warning
    [void][System.AppContext]::SetSwitch("System.Net.DisableIPv6", $true)
  }
}catch{
  write-ezlogs '[ERROR] An exception occured loading or processing App configurations' -showtime -catcherror $_
  [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
  $oReturn=[System.Windows.Forms.MessageBox]::Show("An exception occured loading or processing App configurations for ($($thisScript.name) Media Player - $($thisScript.Version)- PID: $($process.id))`n`nERROR: $($_ | out-string)`n`nRecommened reviewing logs for details.`n`nThis app will now close","[ERROR] - $($thisScript.name) Media Player",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
  Stop-Process $pid -Force
}finally{
  if($startup_perf_timer){
    [void]$AppConfig_Load_Measure.stop()
    write-ezlogs "AppConfig_Load" -PerfTimer $AppConfig_Load_Measure -GetMemoryUsage
    $AppConfig_Load_Measure = $Null
  }
}
#----------------------------------------------
#endregion App Configuration
#----------------------------------------------
#############################################################################
#endregion Initialization Events
#############################################################################

###############################################
#region Startup Dispatcher Timers
###############################################
if($thisApp.Config.Startup_perf_timer){
  $Update_Timers_Startup_Measure =[system.diagnostics.stopwatch]::StartNew()
}
#---------------------------------------------- 
#region Update-MainWindow Startup
#----------------------------------------------
try{
  Import-Module -Name "$Current_Folder\Modules\Set-WPFControls\Set-WPFControls.psm1" -NoClobber -DisableNameChecking -Scope Local
  Update-MainWindow -synchash $synchash -thisApp $thisApp -Startup
}catch{
  write-ezlogs "An exception occurred in Update-MainWindow startup" -catcherror $_
}
#---------------------------------------------- 
#endregion Update-MainWindow Startup
#----------------------------------------------

#---------------------------------------------- 
#region Playlist, Queue Timer Startup
#----------------------------------------------
Import-Module -Name "$Current_Folder\Modules\Get-Playlists\Get-Playlists.psm1" -NoClobber -DisableNameChecking -Scope Local
Import-Module -Name "$Current_Folder\Modules\Get-PlayQueue\Get-PlayQueue.psm1" -NoClobber -DisableNameChecking -Scope Local
Update-Playlists -thisApp $thisApp -synchash $synchash -Startup
Update-PlayQueue -thisApp $thisApp -synchash $synchash -Startup
#---------------------------------------------- 
#endregion Playlist, Queue Timer Startup
#----------------------------------------------

#---------------------------------------------- 
#region Initialize-ChatView/CommentsView
#----------------------------------------------
Import-Module -Name "$Current_Folder\Modules\Update-ChatView\Update-ChatView.psm1" -NoClobber -DisableNameChecking -Scope Local
Import-Module -Name "$Current_Folder\Modules\Get-YoutubeComments\Get-YoutubeComments.psm1" -NoClobber -DisableNameChecking -Scope Local
Update-ChatView -synchash $synchash -thisApp $thisApp -startup
Update-YoutubeComments -thisApp $thisApp -synchash $synchash -Startup
#---------------------------------------------- 
#endregion Initialize-ChatView/CommentsView
#----------------------------------------------

#---------------------------------------------- 
#region Update-MediaState
#----------------------------------------------
Update-MediaState -thisApp $thisApp -synchash $synchash -Startup
#---------------------------------------------- 
#endregion Update-MediaState
#----------------------------------------------

#----------------------------------------------
#region Reset Media Player Timer
#----------------------------------------------
Reset-MainPlayer -synchash $synchash -thisApp $thisApp -Startup
#---------------------------------------------- 
#endregion  Reset Media Player Timer
#----------------------------------------------

#--------------------------------------------- 
#region New-DialogNotification Timer
#---------------------------------------------
Import-Module -Name "$Current_Folder\Modules\Update-Notifications\Update-Notifications.psm1" -NoClobber -DisableNameChecking -Scope Local
New-DialogNotification -thisApp $thisApp -synchash $synchash -Startup
#--------------------------------------------- 
#endregion New-DialogNotification Timer
#---------------------------------------------

#---------------------------------------------- 
#region Update-MainPlayer
#----------------------------------------------
Update-MainPlayer -synchash $synchash -thisApp $thisApp -startup
#---------------------------------------------- 
#endregion Update-MainPlayer
#----------------------------------------------

#---------------------------------------------- 
#region Get-SpectrumAnalyzer
#----------------------------------------------
Import-Module -Name "$Current_Folder\Modules\Get-WPFAnimation\Get-WPFAnimation.psm1" -NoClobber -DisableNameChecking -Scope Local
Get-SpectrumAnalyzer -synchash $synchash -thisApp $thisApp -startup
#---------------------------------------------- 
#endregion Get-SpectrumAnalyzer
#----------------------------------------------

#---------------------------------------------- 
#region Update_TrayMenu Timer
#----------------------------------------------
$Update_TrayMenu_timer = [System.Windows.Threading.DispatcherTimer]::new()
$Update_TrayMenu_timer_Event = {
  try{
    $Update_TrayMenu_Measure = [system.diagnostics.stopwatch]::StartNew() 
    Import-Module -Name "$Current_Folder\Modules\Add-TrayMenu\Add-TrayMenu.psm1" -NoClobber -DisableNameChecking -Scope Local
    Add-TrayMenu -synchash $synchash -thisApp $thisApp -addJumplist -StartMini:$StartMini
    $this.Stop()
  }catch{
    write-ezlogs "An exception occurred in Update_TrayMenu_timer Tick event" -showtime -catcherror $_
    $this.Stop()
  }finally{
    if($Update_TrayMenu_Measure){
      $Update_TrayMenu_Measure.stop()
      write-ezlogs "Add-TrayMenu Startup" -PerfTimer $Update_TrayMenu_Measure
      $Update_TrayMenu_Measure = $Null
    }
    $this.Stop()
    $this.Remove_Tick($Update_TrayMenu_timer_Event)
  }
}
$Update_TrayMenu_timer.Add_Tick($Update_TrayMenu_timer_Event)
#---------------------------------------------- 
#endregion Update_TrayMenu Timer
#----------------------------------------------

#---------------------------------------------- 
#region update_queue_timer Timer
#----------------------------------------------
$synchash.update_Queue_timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.update_Queue_timer.Add_Tick({
    try{
      if($this.Tag -in 'FullRefresh','UpdateQueue'){
        Get-PlayQueue -verboselog:$false -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace
      }
      if($this.Tag -in 'FullRefresh','UpdatePlaylists'){
        Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace -Full_Refresh:$($this.Tag -eq 'FullRefresh')
      }
    }catch{
      write-ezlogs 'An exception occurred executing update_Queue_timer' -showtime -catcherror $_
      $this.Stop()
    }finally{
      $this.tag = $null
      $this.Stop()   
    }  
})
#---------------------------------------------- 
#endregion update_Queue_timer Timer
#----------------------------------------------

#---------------------------------------------- 
#region update_status_timer Timer
#----------------------------------------------
#TODO: This is really pointless/redundant - refactor/remove
$synchash.update_status_timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.update_status_timer.Add_Tick({
    try{        
      if($this.tag -eq 'Twitch' -and $syncHash.TwitchTable.ItemsSource.IsEmpty -ne $true){
        if($syncHash.TwitchTable.ItemsSource -is [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView] -and !$syncHash.TwitchTable.ItemsSource.IsInDeferRefresh){
          write-ezlogs " | Refreshing TwitchTable" -showtime -logtype Twitch
          $syncHash.TwitchTable.ItemsSource.refresh()
        }
      }
      if($this.tag -eq 'Local' -and $syncHash.MediaTable.ItemsSource.IsEmpty -ne $true){         
        if($syncHash.MediaTable.ItemsSource -is [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView] -and !$syncHash.MediaTable.ItemsSource.IsInDeferRefresh){
          write-ezlogs ">>>> Refreshing MediaTable ItemsSource" -showtime -logtype LocalMedia
          $syncHash.MediaTable.ItemsSource.refresh()
        }         
      } 
      if($this.tag -eq 'Spotify' -and $syncHash.SpotifyTable.ItemsSource.IsEmpty -ne $true){
        if($syncHash.SpotifyTable.ItemsSource -is [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView] -and !$syncHash.SpotifyTable.ItemsSource.IsInDeferRefresh){
          write-ezlogs ">>>> Refreshing SpotifyTable ItemsSource" -showtime -logtype Spotify
          $syncHash.SpotifyTable.ItemsSource.refresh()
        }
      }
      if($this.tag -eq 'Youtube' -and $syncHash.YoutubeTable.ItemsSource.IsEmpty -ne $true){         
        if($syncHash.YoutubeTable.ItemsSource -is [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView] -and !$syncHash.YoutubeTable.ItemsSource.IsInDeferRefresh){
          write-ezlogs ">>>> Refreshing YoutubeTable ItemsSource" -showtime -logtype Youtube
          $syncHash.YoutubeTable.ItemsSource.refresh()
        }         
      }      
    }catch{
      write-ezlogs 'An exception occurred executing update_status_timer' -showtime -catcherror $_
    }finally{
      $this.tag = $null
      $this.Stop()
    }   
})
#---------------------------------------------- 
#endregion update_status_timer Timer
#----------------------------------------------

#---------------------------------------------- 
#region Initialize-Vlc Timer
#----------------------------------------------
$synchash.Initialize_Vlc_timer = [System.Windows.Threading.DispatcherTimer]::new()
$Initialize_Vlc_timer_Event = {
  try{
    $Initialize_VLC_Measure = [system.diagnostics.stopwatch]::StartNew()
    $Startup_Playback = [bool]($thisApp.Config.Current_playing_media.id -and $thisApp.Config.Current_playing_media.Source -eq 'Local' -and $thisApp.Config.Remember_Playback_Progress) -or $PlayMedia -or $MediaFile
    Initialize-VLC -synchash $synchash -thisApp $thisApp -Initalize_EQ -VideoView $synchash.VideoView -Startup -Startup_Playback:$Startup_Playback
    if($PlayMedia -or $MediaFile){
      try{
        write-ezlogs "#### Play Media switch provided: $Startup_Playback ####" -showtime -color yellow -linesbefore 1
        $media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)mp4|(?i)flac|(?i)wav|(?i)avi|(?i)wmv|(?i)h264|(?i)mkv|(?i)webm|(?i)h265|(?i)mov|(?i)h264|(?i)mpeg|(?i)mpg4|(?i)movie|(?i)mpgx|(?i)vob|(?i)3gp|(?i)m2ts|(?i)aac))')
        if(([system.io.file]::Exists($MediaFile) -and $MediaFile -match $media_pattern) -or [system.io.directory]::Exists($MediaFile)){      
          $media = Get-MediaProfile -thisApp $thisapp -synchash $synchash -Media_URL $MediaFile
          if($media){
            $synchash.Temporary_Playback_Media = $media
            Start-Media -Media $media -thisApp $thisApp -synchashWeak ([System.WeakReference]::new($synchash)) -Startup
          }elseif($MediaFile -or [system.io.directory]::Exists($MediaFile)){
            write-ezlogs "| Importing media file: $MediaFile" -showtime
            Import-Media -Media_Path $MediaFile -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory  -thisApp $thisapp -StartPlayback
          }
        }elseif((Test-ValidPath $MediaFile -Type URL) -and $MediaFile -match 'yewtu\.be|youtu\.be|youtube\.com|twitch\.tv|spotify\.com'){
          if($MediaFile -match 'yewtu\.be|youtu\.be|youtube\.com'){
            $type = 'Youtube'
          }elseif($MediaFile -match 'twitch\.tv'){
            $type = 'Twitch'
          }elseif($MediaFile -match 'spotify\.com'){
            $type = 'Spotify'
          }
          write-ezlogs "| Executing Start-NewMedia for type: $type" -showtime
          Start-NewMedia -synchash $synchash -thisApp $thisApp -Mediaurl $MediaFile -Use_Runspace -MediaType $type
        }else{
          write-ezlogs "Provided media from command line is not valid or supported!" -showtime -warning
        }
      }catch{
        write-ezlogs "An exception occurred importing provided media from command line on startup: $MediaFile" -showtime -catcherror $_
      }
    }elseif($Startup_Playback -and $thisApp.Config.Current_playing_media.id){    
      $synchash.Now_Playing_Title_Label.DataContext = 'LOADING...'
      write-ezlogs ">>>> Resuming previously playing media on startup for: $($thisApp.Config.Current_playing_media.title)"
      Start-Media -Media $thisApp.Config.Current_playing_media -thisApp $thisapp -synchashWeak ([System.WeakReference]::new($synchash)) -start_Paused:$thisApp.Config.Start_Paused -Startup
    }
    $Initialize_VLC_Measure.stop()
    write-ezlogs "Initialize_VLC Startup" -PerfTimer $Initialize_VLC_Measure
    write-ezlogs "####################### MAIN STARTUP FINISHED #######################"  -Perf -linesafter 1
    $Initialize_VLC_Measure = $Null
    $this.Stop()
  }catch{
    write-ezlogs "An exception occurred in Initialize_Vlc_timer" -showtime -catcherror $_
  }finally{
    $this.Stop()
    $this.Remove_Tick($Initialize_Vlc_timer_Event)
    $Initialize_Vlc_timer_Event = $Null
    $synchash.Initialize_Vlc_timer = $null
  }
}
$synchash.Initialize_Vlc_timer.add_tick($Initialize_Vlc_timer_Event)
#---------------------------------------------- 
#endregion Initialize-Vlc Timer
#----------------------------------------------

#---------------------------------------------- 
#region Initialize-EQ Timer
#----------------------------------------------
$synchash.Initialize_EQ_timer = [System.Windows.Threading.DispatcherTimer]::new()
$EQ_Timer_ScriptBlock = {
  Param($sender,[System.EventArgs]$e)
  try{
    if($thisApp.Config.startup_perf_timer){
      $Initialize_EQ_Measure = [system.diagnostics.stopwatch]::StartNew()
    }
    #$Startup_Playback = [bool]($thisApp.Config.Current_playing_media.id -and $thisApp.Config.Current_playing_media.Source -eq 'Local' -and $thisApp.Config.Remember_Playback_Progress) -or $PlayMedia -or $MediaFile
    Initialize-EQ -synchash $synchash -thisApp $thisApp -Startup_Playback:$this.tag
    $this.Stop()
  }catch{
    write-ezlogs "An exception occurred in Initialize_EQ_timer" -showtime -catcherror $_ -thisApp $thisApp
    $this.Stop()
  }finally{
    if($Initialize_EQ_Measure){
      $Initialize_EQ_Measure.Stop()
      write-ezlogs "Initialize_EQ_Measure" -PerfTimer $Initialize_EQ_Measure -thisApp $thisApp
      $Initialize_EQ_Measure = $Null
    }
    $this.Stop()
    $this.Remove_Tick($EQ_Timer_ScriptBlock)
    $EQ_Timer_ScriptBlock = $Null
    $synchash.Initialize_EQ_timer = $Null
  }
}
$synchash.Initialize_EQ_timer.add_tick($EQ_Timer_ScriptBlock)
#---------------------------------------------- 
#endregion Initialize-EQ Timer
#----------------------------------------------

#----------------------------------------------
#TODO: Audio Track Processing
#region Libvlc AudioTrack Timer
#----------------------------------------------
<#$synchash.vlc_audiotrack_timer = [System.Windows.Threading.DispatcherTimer]::new()
    $synchash.vlc_audiotrack_timer.Add_tick({
    try{      
    if($thisApp.Config.Libvlc_Version -eq '4'){
    $synchash.Vlc_Current_audiotrack = $synchash.vlc.tracks('Audio') | Where-Object {$_.Language -eq 'eng'}
    }else{
    $synchash.Vlc_Current_audiotrack = $synchash.vlc.media.tracks | Where-Object {$_.TrackType -eq 'Audio' -and $_.Language -eq 'eng'}
    }        
    write-ezlogs ">>>> Setting Audio Track to $($synchash.vlc.audiotrack | out-string)" -showtime
    if(-not [string]::IsNullOrEmpty($synchash.Vlc_Current_audiotrack.id)){       
    try{                       
    if($thisApp.Config.Libvlc_Version -eq '4'){
    $synchash.VLC.Select($synchash.Vlc_Current_audiotrack)
    }else{
    $synchash.VLC.SetAudioTrack($synchash.Vlc_Current_audiotrack.id)
    }            
    $synchash.Vlc_Current_audiotrack = $Null
    }catch{
    write-ezlogs "An exception occurred Setting Audio Track" -showtime -catcherror $_
    }                                                                                 
    }
    $this.Stop()
    }catch{
    write-ezlogs "An exception occurred in vlc_audiotrack_timer" -showtime -catcherror $_
    $this.Stop()
    }
    })
#>#----------------------------------------------
#endregion Libvlc AudioTrack Timer
#----------------------------------------------

#---------------------------------------------- 
#region Initialize-WebPlayer Timer
#----------------------------------------------
$synchash.Initialize_WebPlayer_timer = [System.Windows.Threading.DispatcherTimer]::new()
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
#region Initialize-YoutubeWebPlayer Timer
#----------------------------------------------
$synchash.Initialize_YoutubeWebPlayer_timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.Initialize_YoutubeWebPlayer_timer.add_tick({
    try{
      Initialize-YoutubeWebPlayer -synchash $synchash -thisApp $thisApp -thisScript $thisScript
      $this.Stop()
    }catch{
      write-ezlogs "An exception occurred in Initialize_YoutubeWebPlayer_timer" -showtime -catcherror $_
      $this.Stop()
    }  
})
#---------------------------------------------- 
#endregion Initialize-YoutubeWebPlayer Timer
#----------------------------------------------

#---------------------------------------------- 
#region Initialize-WebBrowser Timer
#----------------------------------------------
$Initialize_WebBrowser_timer = [System.Windows.Threading.DispatcherTimer]::new([System.Windows.Threading.DispatcherPriority]::Background)
[System.EventHandler]$WebBrowserTimer_Event = {
  try{
    Import-Module -Name "$Current_Folder\Modules\Initialize-WebView2\Initialize-WebView2.psm1" -NoClobber -DisableNameChecking -Scope Local
    Import-Module -Name "$Current_Folder\Modules\EZT-Bookmarks\EZT-Bookmarks.psm1" -NoClobber -DisableNameChecking -Scope Local
    Initialize-WebBrowser -synchash $synchash -thisApp $thisApp -thisScript $thisScript
    Get-Bookmarks -synchash $synchash -thisApp $thisApp -Startup
  }catch{
    write-ezlogs "An exception occurred in Initialize_WebBrowser_timer" -showtime -catcherror $_
  }finally{
    $this.Stop()
    $this.Remove_tick($WebBrowserTimer_Event)
  }
}
$Initialize_WebBrowser_timer.add_tick($WebBrowserTimer_Event)
#---------------------------------------------- 
#endregion Initialize-WebBrowser Timer
#----------------------------------------------

#---------------------------------------------- 
#region Update Media Progress Timer
#----------------------------------------------
$synchash.Timer = [System.Windows.Threading.DispatcherTimer]::new([System.Windows.Threading.DispatcherPriority]::Normal)
$synchash.Timer.Interval = [timespan]::FromMilliseconds(100)
$synchash.current_track_playing = ''
$synchash.Spotify_Status = 'Stopped'
$synchash.Timer.add_tick({
    try{
      Update-MediaTimer -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisApp
    }catch{
      write-ezlogs "An exception occurred executing Update-MediaTimer" -showtime -catcherror $_
    }
})

$synchash.Update_Playing_Playlist_Timer = [System.Windows.Threading.DispatcherTimer]::New([System.Windows.Threading.DispatcherPriority]::Background)
$synchash.Update_Playing_Playlist_Timer.add_tick({    
    try{
      if($synchash.All_Playlists.Playlist_Tracks){
        $current_Playing_Playlist = Get-IndexesOf $synchash.All_Playlists.Playlist_Tracks.values.id -Value $this.tag.id | & { process {
            $synchash.All_Playlists.Playlist_Tracks.values[$_]
        }}
      }elseif($synchash.Playlists_TreeView.Nodes.ChildNodes.Content.id){
        $current_Playing_Playlist = Get-IndexesOf $synchash.Playlists_TreeView.Nodes.ChildNodes.Content.id -Value $this.tag.id | & { process { 
            $synchash.Playlists_TreeView.Nodes.ChildNodes.Content[$_]
        }}
      }elseif($synchash.Playlists_TreeView.Itemssource.Playlist_Tracks){
        $current_Playing_Playlist = Get-IndexesOf $synchash.Playlists_TreeView.Itemssource.Playlist_Tracks.values.id -Value $this.tag.id | & { process {
            $synchash.Playlists_TreeView.Itemssource.Playlist_Tracks.values[$_]
        }}
      }
      if(-not [string]::IsNullOrEmpty($current_Playing_Playlist)){
        $current_Playing_Playlist | & { process {
            if($_.title -and ($_.title -ne $this.tag.title -or $_.BorderBrush -ne "LightGreen")){
              write-ezlogs ">>>> Updating playlist item to current playing item: $($this.tag.title)" -Dev_mode
              $_.title = $this.tag.title
              $_.FontWeight = $this.tag.FontWeight
              $_.FontSize = [Double]$this.tag.FontSize
              $_.BorderBrush = "LightGreen"
              $_.BorderThickness ="1,1,1,1"
              if($synchash.Playlists_TreeView.Itemssource.IsInUse){
                write-ezlogs ">>>> Refreshing Playlists_TreeView.Itemssource"
                $synchash.Playlists_TreeView.Itemssource.Refresh()
              }
            }
        }}
      }
    }catch{
      write-ezlogs "An exception occurred executing Update_Playing_Playlist_Timer for current_playing_playlist: $($current_Playing_Playlist | out-string)" -showtime -catcherror $_
    }finally{
      $this.tag = $Null
      $this.stop()
    }       
})
#---------------------------------------------- 
#endregion Update Media Progress Timer
#----------------------------------------------

#---------------------------------------------- 
#region Torrent Select Timer
#TODO: Need to Finish
#----------------------------------------------
$synchash.Torrent_Select_Timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.Torrent_Select_Timer.add_tick({    
    try{
      $CustomDialog_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new() 
      $CustomDialog_Settings.ColorScheme = [MahApps.Metro.Controls.Dialogs.MetroDialogColorScheme]::Theme
      $CustomDialog_Settings.OwnerCanCloseWithDialog = $true
      $synchash.TorDialog = [MahApps.Metro.Controls.Dialogs.CustomDialog]::new($synchash.Window)
      [xml]$xaml = [System.IO.File]::ReadAllText("$($thisApp.config.Current_folder)\Views\TorDialog.xaml").replace('Views/Styles.xaml',"$($thisApp.config.Current_folder)`\Views`\Styles.xaml")
      $reader = [System.Xml.XmlNodeReader]::new($xaml) 
      $synchash.TorDialogWindow = [Windows.Markup.XamlReader]::Load($reader)
      $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]")| & { process {$synchash."$($_.Name)" = $synchash.TorDialogWindow.FindName($_.Name)}}    
      [void]$reader.Dispose()
      $synchash.TorDialog.AddChild($synchash.TorDialogWindow)
      if($synchash.TorDialogButtonClose){
        $synchash.TorDialogButtonClose.add_click({
            try{                         
              $synchash.TorDialog.RequestCloseAsync()
              $synchash.TorDialog = $null
              $synchash.TorDialogWindow = $null
            }catch{
              write-ezlogs "An exception occurred in Dialog_Remote_URL_Textbox.add_TextChanged" -catcherror $_
            }
        })
      }
      if($synchash.TorDialog_Add_Button){
        $synchash.TorDialog_Add_Button.add_click({
            try{                         
              $synchash.TorSelected = $synchash.TorItems_Grid.Selecteditems
              $synchash.TorDialog.RequestCloseAsync()
              $synchash.TorDialog = $null
              $synchash.TorDialogWindow = $null
            }catch{
              write-ezlogs "An exception occurred in Dialog_Remote_URL_Textbox.add_TextChanged" -catcherror $_
            }
        })
      }
      if($synchash.TorDialog_Remote_URL_Textbox){
        $torrentPaths = ""
        $this.tag | & { process {
            write-ezlogs "Adding Tor selection: $($_ | out-string)"
            $torrentPaths += "Torrent: $($_.FullPath) ||"
        }}
        $synchash.TorDialog_Remote_URL_Textbox.text = $torrentPaths
        <#        $synchash.TorDialog_Remote_URL_Textbox.add_TextChanged({
            try{

            }catch{
            write-ezlogs "An exception occurred in Dialog_Remote_URL_Textbox.add_TextChanged" -catcherror $_
            }
        })#>
      }
      if($synchash.TorItems_Grid){
        $synchash.TorItems_Grid.Itemssource = $this.tag
      }
      [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMetroDialogAsync($synchash.Window, $synchash.TorDialog, $CustomDialog_Settings) 
    }catch{
      write-ezlogs "An exception occurred executing Torrent_Select_Timer" -showtime -catcherror $_
    }finally{
      $this.tag = $Null
      $this.stop()   
    }       
})
#--------------------------------------------- 
#endregion Torrent Select Timer
#---------------------------------------------
if($Update_Timers_Startup_Measure){
  $Update_Timers_Startup_Measure.stop()
  write-ezlogs "Update_Timers_Startup_Measure" -PerfTimer $Update_Timers_Startup_Measure -GetMemoryUsage:$thisApp.Config.Memory_perf_measure
  $Update_Timers_Startup_Measure = $Null
}
###############################################
#endregion Startup Dispatcher Timers
###############################################

#---------------------------------------------- 
#region First Run
#----------------------------------------------
#Run First Run Setup if new version or fresh install
if($thisApp.Config.Startup_perf_timer){
  $FirstRunCheck_Measure =[system.diagnostics.stopwatch]::StartNew()
}

#Load Special Message for Special Build
$Today = [DateTime]::Now
$Month = $Today.Month
$Day = $Today.day
$isSpecialDay = $($Month -eq '09' -and $Day -eq '22' -and !$thisApp.Config.IsRead_SpecialFirstRun)
if([system.io.file]::Exists("$($Current_Folder)\Resources\Docs\About\About_FirstRun.md") -and (!$thisApp.Config.IsRead_AboutFirstRun -or $isSpecialDay)){
  if($hash.Window.isVisible){
    Update-SplashScreen -hash $hash -Hide
  }
  $markdownfile = "$($Current_Folder)\Resources\Docs\About\About_FirstRun.md"
  Show-ChildWindow -synchash $synchash -thisApp $thisApp -WindowTitle "Dedication - $($thisApp.Config.App_Name) Media Player - $($thisApp.Config.App_Version)" -Logo "$($Current_Folder)\Resources\Skins\Samson_Logo_Title.png" -MarkDownFile $markdownfile -sendername 'Dedication_Menu' -use_runspace:$false -isSpecialDay:$isSpecialDay
}

$MediaProfileDir_Exists = [System.IO.Directory]::Exists($thisapp.config.Media_Profile_Directory)
if($FreshStart -or -not $MediaProfileDir_Exists){
  if($MediaProfileDir_Exists){
    try{
      write-ezlogs " | Clearing profile cache ($($thisapp.config.Media_Profile_Directory)) for first time run" -showtime
      [void][System.IO.Directory]::Delete($thisapp.config.Media_Profile_Directory,$true)
    }catch{
      write-ezlogs "An exception occurred Clearing profile cache ($($thisapp.config.Media_Profile_Directory))" -showtime -catcherror $_
    }
  }else{
    write-ezlogs ">>>> No Media_Profile_Directory found, starting first run setup" -showtime
  }  
  if([System.IO.File]::Exists("$env:localappdata\spotishell\$($thisApp.Config.App_Name).json")){
    try{
      write-ezlogs ">>>> Removing existing Spotify application json at $env:localappdata\spotishell\$($thisApp.Config.App_Name).json" -showtime
      [void][System.IO.File]::Delete("$env:localappdata\spotishell\$($thisApp.Config.App_Name).json")
    }catch{
      write-ezlogs "An exception occurred attempting to remove $env:localappdata\spotishell\$($thisApp.Config.App_Name).json" -showtime -catcherror $_
    }
  }
  if([System.IO.Directory]::Exists("$($thisApp.config.Temp_Folder)\Webview2")){   
    try{
      write-ezlogs ">>>> Removing existing Webview2 data folder at $($thisApp.config.Temp_Folder)\Webview2" -showtime
      [void][System.IO.Directory]::Delete("$($thisApp.config.Temp_Folder)\Webview2",$true)
    }catch{
      write-ezlogs "An exception occurred attempting to remove $($thisApp.config.Temp_Folder)\Webview2" -showtime -catcherror $_
    }
  }
  if([System.IO.Directory]::Exists("$($thisApp.config.Temp_Folder)\Setup_Webview2")){   
    try{
      write-ezlogs ">>>> Removing existing Setup_Webview2 folder at $($thisApp.config.Temp_Folder)\Setup_Webview2" -showtime
      [void][System.IO.Directory]::Delete("$($thisApp.config.Temp_Folder)\Setup_Webview2",$true)
    }catch{
      write-ezlogs "An exception occurred attempting to remove $($thisApp.config.Temp_Folder)\Setup_Webview2" -showtime -catcherror $_
    }
  }
  if([System.IO.Directory]::Exists("$($thisApp.config.Temp_Folder)\Images")){   
    try{
      write-ezlogs ">>>> Removing existing cached images folder at $($thisApp.config.Temp_Folder)\Images" -showtime
      [void][System.IO.Directory]::Delete("$($thisApp.config.Temp_Folder)\Images",$true)
    }catch{
      write-ezlogs "An exception occurred attempting to remove $($thisApp.config.Temp_Folder)\Images" -showtime -catcherror $_
    }
  }
  if([System.IO.Directory]::Exists("$($thisApp.config.Temp_Folder)\Tor")){   
    try{
      write-ezlogs ">>>> Removing existing Tor temp data folder at $($thisApp.config.Temp_Folder)\Tor" -showtime
      [void][System.IO.Directory]::Delete("$($thisApp.config.Temp_Folder)\Tor",$true)
    }catch{
      write-ezlogs "An exception occurred attempting to remove $($thisApp.config.Temp_Folder)\Tor" -showtime -catcherror $_
    }
  }   
  #Verify Webview2 Installed
  try{
    $WebView2_Install_Check = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\*" -ErrorAction SilentlyContinue) | Where-Object {$_.name -match 'WebView2 Runtime'}
    $WebView2_version = $WebView2_Install_Check.pv
    if(!$WebView2_Install_Check){
      $user_sid = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
      $WebView2_Install_Check = (Get-ItemProperty "Registry::\HKEY_USERS\$user_sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue) | Where-Object {$_.Displayname -match 'WebView2 Runtime'}
      $WebView2_version = $WebView2_Install_Check.Version
    }  
    if(-not [string]::IsNullOrEmpty($WebView2_Install_Check)){
      write-ezlogs "[FIRST-RUN] Webview2 is installed with version $($WebView2_version)" -showtime
    }else{
      Update-SplashScreen -hash $hash -SplashMessage "Installing Webview2 Runtime"   
      if(![System.IO.file]::Exists("$($thisApp.config.current_folder)\Resources\WebView2\MicrosoftEdgeWebview2Setup.exe")){   
        try{
          $webview2_Link = "https://go.microsoft.com/fwlink/p/?LinkId=2124703"
          $webview_exe = "MicrosoftEdgeWebview2Setup.exe"
          $webview2_download_location = "$env:temp\$webview_exe"
          write-ezlogs "[FIRST-RUN] | Downloading Webview2 to $webview2_download_location" -showtime
          [void]([System.Net.WebClient]::new()).DownloadFile($webview2_Link,$webview2_download_location)
        }catch{
          write-ezlogs "An exception occurred attempting to download $webview2_Link" -showtime -catcherror $_
        }
      }else{
        $webview2_download_location = "$($thisApp.config.current_folder)\Resources\WebView2\MicrosoftEdgeWebview2Setup.exe"
      }
      #Installing Webview2 runtime
      try{
        write-ezlogs "[FIRST-RUN]  | Installing Webview2 from $webview2_download_location with arguments 'silent /install'" -showtime
        $webview2_setup = Start-process $webview2_download_location -ArgumentList '/silent /install' -Wait
        write-ezlogs "[FIRST-RUN]  | Verifying installation was sucessfull..." -showtime
        $WebView2_PostInstall_Check = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\*" -ErrorAction SilentlyContinue) | Where-Object {$_.name -match 'WebView2 Runtime'}
        if(!$WebView2_PostInstall_Check){
          $user_sid = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value
          $WebView2_PostInstall_Check = (Get-ItemProperty "Registry::\HKEY_USERS\$user_sid\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -ErrorAction SilentlyContinue) | Where-Object {$_.Displayname -match 'WebView2 Runtime'}
        }
      }catch{
        write-ezlogs "An exception occurred Installing Webview2 from $webview2_download_location with arguments 'silent /install'" -showtime -catcherror $_
      }
      if(-not [string]::IsNullOrEmpty($WebView2_PostInstall_Check)){
        write-ezlogs "[FIRST-RUN] [SUCCESS] Webview2 Runtime installed succesfully!" -showtime         
      }else{
        write-ezlogs "[WARNING] Unable to verify if Webview2 installed successfully. Features that use Webview2 (webbrowsers and others) may not work correctly: Regpath checked: $($WebView2_PostInstall_Check | out-string)" -showtime -warning
      }
    }
  }catch{
    write-ezlogs "An exception occurred verifying Webview2 Installation" -showtime -catcherror $_
  }

  #Assembly Optimization
  if($FreshStart -and $OptmizeAssemblies){
    Optimize-Assemblies -thisApp $thisApp
  }  
  try{
    if((Use-RunAs -Check)){
      $PageTitle = "Administrator: First Run Setup - $($thisScript.name) Media Player"
      if(!$FreshStart){
        write-ezlogs "[FIRST-RUN] App is curently running as admin, attempting to restart under user context" -showtime -warning
        if(([System.IO.Directory]::Exists($thisapp.config.Media_Profile_Directory))){
          try{
            write-ezlogs " | Clearing profile cache ($($thisapp.config.Media_Profile_Directory)) for restart of first run" -showtime
            [void][System.IO.Directory]::Delete($thisapp.config.Media_Profile_Directory,$true)
          }catch{
            write-ezlogs "An exception occurred Clearing profile cache ($($thisapp.config.Media_Profile_Directory))" -showtime -catcherror $_
          }
        }      
        Use-RunAs -RestartAsUser
        exit
      }
    }else{
      $PageTitle = "First Run Setup - $($thisScript.name) Media Player"
    }
    Show-SettingsWindow -PageTitle $PageTitle -PageHeader 'First Run Setup' -Logo "$($thisapp.Config.Current_Folder)\Resources\Skins\Samson_Logo.png" -thisApp $thisapp -Verboselog $thisapp.config.Verbose_Logging -hash $hash -First_Run -synchash $synchash -hashsetup $hashsetup -PlaylistRebuild_Required:$PlaylistRebuild_Required -globalstopwatch $startup_stopwatch
    [void][System.IO.Directory]::CreateDirectory($thisapp.config.Media_Profile_Directory)
    if([system.io.file]::Exists("$($thisApp.Config.Current_Folder)\Resources\Docs\About\About_FirstRun.md") -and (!$thisApp.Config.IsRead_AboutFirstRun)){
      write-ezlogs "Dont show splash screen just yet....load special first run"
    }else{
      if(!$hash.Window.IsVisible){
        Update-SplashScreen -hash $hash -show 
      }
    }      
  }catch{
    write-ezlogs 'An exception occurred executing Show-SettingsWindow' -showtime -catcherror $_
    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    $oReturn=[System.Windows.Forms.MessageBox]::Show("An exception occurred executing Show-SettingsWindow ($($thisScript.name) Media Player - Version: $($thisScript.Version) - PID: $($process.id))`n`nERROR: $($_ | out-string)`n`nRecommened reviewing logs for details.`n`nThis app will now close","[ERROR] - $($thisScript.name) Media Player",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
    Stop-Process $pid -Force
  }
}
#Create Playlist Directory if needed
if(!([System.IO.Directory]::Exists($thisapp.config.Playlist_Profile_Directory))){
  try{
    write-ezlogs " | Creating Playlist Profile Directory at $($thisapp.config.Playlist_Profile_Directory)" -showtime
    [void][System.IO.Directory]::CreateDirectory($thisapp.config.Playlist_Profile_Directory)
  }catch{
    write-ezlogs "An exception occurred creating playlist profile directory at $($thisapp.config.Playlist_Profile_Directory)" -showtime -catcherror $_
  }
}

if($FirstRunCheck_Measure){
  $FirstRunCheck_Measure.Stop()
  write-ezlogs "FirstRunCheck_Measure" -PerfTimer $FirstRunCheck_Measure
  $FirstRunCheck_Measure = $Null
}
#---------------------------------------------- 
#endregion First Run
#----------------------------------------------

#---------------------------------------------- 
#region confirm-requirements
#----------------------------------------------
#Verify and Install Required Apps/Components
try{
  if($thisApp.Config.startup_perf_timer){
    $confirm_Requirements_Measure = [system.diagnostics.stopwatch]::StartNew()
  }
  Import-Module -Name "$Current_Folder\Modules\Get-HelperFunctions\Get-HelperFunctions.psm1" -NoClobber -DisableNameChecking
  [Void](Confirm-Requirements -required_appnames $required_appnames -FirstRun -Verboselog:$thisapp.Config.Verbose_logging -thisApp $thisapp -logfile $logfile)
  if($confirm_Requirements_Measure){
    $confirm_Requirements_Measure.Stop()
    write-ezlogs "Confirm-Requirements" -PerfTimer $confirm_Requirements_Measure
  }
  $confirm_Requirements_Measure = $Null
}catch{
  write-ezlogs 'An exception occurred in script_onload_scripblock' -showtime -catcherror $_
}
#---------------------------------------------- 
#endregion confirm-requirements
#----------------------------------------------

#---------------------------------------------- 
#region Play Media Handlers
#----------------------------------------------
$synchash.PlayMedia_Scriptblock = {
  param($sender,[System.Windows.RoutedEventArgs]$item)
  try{
    #TODO: Temp hack to try and skip play event if the source came from library media edit control
    if($_.OriginalSource.Name -in 'Mediatable_Editbutton','MediaEdit_border','MediaEdit_Grid','MediaEdit_icon','Spotifytable_Editbutton','Youtubetable_Editbutton','Twitchtable_Editbutton'){
      write-ezlogs "Button Event came from media table edit button or element ($($_.OriginalSource.Name)), canceling play media event" -warning
      $item.Handled = $false
      return
    }
    $item.Handled = $true

    #For impatient clickers...
    if($synchash.Now_Playing_Title_Label.DataContext -match 'LOADING...' -and $synchash.PlayButton_ToggleButton.isChecked){
      write-ezlogs "[PLAYMEDIA] Whoa there! Slow down mister clicky-d-click, wait until the current media has loaded before starting another. If you can't wait, hit stop first!" -warning -AlertUI
      $synchash.PlayButton_ToggleButton.isChecked = $true
      return
    }

    #Get media ID passed from the many possible source event controls..
    if(-not [string]::IsNullOrEmpty($item.OriginalSource.DataContext.id)){
      $Media_ID = $item.OriginalSource.DataContext.id
      $Media = $item.OriginalSource.DataContext
    }elseif(-not [string]::IsNullOrEmpty($item.OriginalSource.DataContext.Content.ID)){
      $Media_ID = $item.OriginalSource.DataContext.Content.ID
      $Media = $item.OriginalSource.DataContext.Content
    }elseif(-not [string]::IsNullOrEmpty($item.OriginalSource.DataContext.Record.id)){
      $Media_ID = $item.OriginalSource.DataContext.Record.id
      $Media = $item.OriginalSource.DataContext.Record
    }elseif(-not [string]::IsNullOrEmpty($item.Source.DataContext.id)){
      $Media_ID = $item.Source.DataContext.id
      $Media = $item.Source.DataContext
    }elseif(-not [string]::IsNullOrEmpty($item.OriginalSource.DataContext.tag.Media.id)){
      $Media_ID = $item.OriginalSource.DataContext.tag.Media.id
      $Media = $item.OriginalSource.DataContext.tag.Media
    }elseif(-not [string]::IsNullOrEmpty($sender.tag.Media.id)){
      $Media_ID = $sender.tag.Media.id
      $Media = $sender.tag.Media
    }elseif(-not [string]::IsNullOrEmpty($sender.tag.id)){
      $Media_ID = $sender.tag.id
      $Media = $sender.tag
    }elseif(-not [string]::IsNullOrEmpty($sender.tag)){
      $Media_ID = $sender.tag
    }

    #Get playlist_id passed from the many possible source event controls..
    if(-not [string]::IsNullOrEmpty($item.OriginalSource.datacontext.Record.Playlist_ID)){
      $Playlist_ID = $item.OriginalSource.datacontext.Record.Playlist_ID
    }elseif(-not [string]::IsNullOrEmpty($item.OriginalSource.datacontext.Content.Playlist_ID)){
      $Playlist_ID = $item.OriginalSource.datacontext.Content.Playlist_ID
    }elseif(-not [string]::IsNullOrEmpty($item.Source.DataContext.Playlist_ID)){
      $Playlist_ID = $item.Source.DataContext.Playlist_ID
    }elseif(-not [string]::IsNullOrEmpty($sender.DataContext.Playlist_ID)){
      $Playlist_ID = $sender.DataContext.Playlist_ID
    }elseif(-not [string]::IsNullOrEmpty($item.Source.DataContext.Content.Playlist_ID)){
      $Playlist_ID = $item.Source.DataContext.Content.Playlist_ID
    }else{
      $Playlist_ID = $item.OriginalSource.datacontext.Playlist_ID
    } 

    #Look up media profile if we have one
    if(-not [string]::IsNullOrEmpty($Media_ID)){
      $Media = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_ID $Media_ID
    }

    if(($_.OriginalSource.Name -notmatch 'Toggle' -or $_.OriginalSource.Name -match 'Play' -or $sender.Header -eq 'Play') -and $_.OriginalSource.Name -notmatch 'Vertical|Horizontal' -and -not ($item.ChangedButton -eq 'Right' -and $item.RoutedEvent -match 'DoubleClick')){
      #See if there are multiple selected items, and if so add them to queue and play the first one
      if($sender.Header -eq 'Play'){
        if($sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.Content.id){
          $MediaItems = $sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.Content
        }elseif($sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.id){
          $MediaItems = $sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems
        }elseif($Media.Source -eq 'Local' -and $synchash.MediaTable.isVisible -and $synchash.MediaTable.selecteditems){
          $MediaItems = $synchash.MediaTable.selecteditems
          $Media = $MediaItems | Select-Object -first 1
          write-ezlogs "[PLAYMEDIA] | Selected $($MediaItems.count) media items from Mediatable - First item to play: $($Media.title)" -Dev_mode
        }elseif($Media.Source -eq 'Spotify' -and $synchash.SpotifyTable.isVisible -and $synchash.SpotifyTable.selecteditems){
          $MediaItems = $synchash.SpotifyTable.selecteditems
          $Media = $MediaItems | Select-Object -first 1
          write-ezlogs "[PLAYMEDIA] | Selected $($MediaItems.count) media items from Spotifytable - First item to play: $($Media.title)" -Dev_mode
        }elseif($Media.Source -eq 'Youtube' -and $synchash.YoutubeTable.isVisible -and $synchash.YoutubeTable.selecteditems){
          $MediaItems = $synchash.YoutubeTable.selecteditems
          $Media = $MediaItems | Select-Object -first 1
          write-ezlogs "[PLAYMEDIA] | Selected $($MediaItems.count) media items from Youtubetable - First item to play: $($Media.title)" -Dev_mode
        }elseif($Media.Source -eq 'Twitch' -and $synchash.TwitchTable.isVisible -and $synchash.TwitchTable.selecteditems){
          $MediaItems = $synchash.TwitchTable.selecteditems
          $Media = $MediaItems | Select-Object -first 1
          write-ezlogs "[PLAYMEDIA] | Selected $($MediaItems.count) media items from Twitchetable - First item to play: $($Media.title)" -Dev_mode
        }
        if($MediaItems){
          Update-PlayQueue -synchash $synchash -thisApp $thisApp -Add -media $MediaItems -Add_First $media.id -Use_RunSpace
        }      
      }
      #If no new media has been selected to play, restart the current playing media if any, unless if event is a doubleclick.
      #Otherwise, check what type of media it is and pass it to its respective start playback function
      if($synchash.Current_playing_media.id -and $item.RoutedEvent.Name -notmatch 'DoubleClick' -and $item.RoutedEvent -notmatch 'DoubleClick' -and ([string]::IsNullOrEmpty($Media.url) -and [string]::IsNullOrEmpty($Media.uri))){
        write-ezlogs "[PLAYMEDIA] >>>> Restarting current playing media: $($synchash.Current_playing_media)" -showtime -warning
        if($synchash.Current_playing_media.url -match 'spotify:' -or $synchash.Current_playing_media.Source -eq 'Spotify'){
          Start-SpotifyMedia -Media $synchash.Current_playing_media -thisApp $thisApp -synchash $synchash -use_WebPlayer:$thisapp.config.Spotify_WebPlayer -Show_notifications:$thisApp.config.Show_notifications -RestrictedRunspace:$thisapp.config.Spotify_WebPlayer
        }else{
          Start-Media -Media $synchash.Current_playing_media -thisApp $thisapp -synchashWeak ([System.WeakReference]::new($synchash))
        }
      }elseif($Media.url -match 'spotify\:' -or $Media.Source -eq 'Spotify'){
        write-ezlogs "[PLAYMEDIA] >>>> Playing Spotify Media: $($Media.title) -- URL: $($media.url)" -showtime
        Start-SpotifyMedia -Media $Media -thisApp $thisapp -synchash $synchash -use_WebPlayer:$thisapp.config.Spotify_WebPlayer -Show_notifications:$thisApp.config.Show_notifications -RestrictedRunspace:$thisapp.config.Spotify_WebPlayer
      }elseif($Media.Source -eq 'TOR'){
        #TODO: TOR MEDIA PLAYBACK
        write-ezlogs "[NOT_IMPLENTED_YET] >>>> Playing TOR Media: $($Media | out-string)" -showtime -warning
        #Start-SpotifyMedia -Media $Media -thisApp $thisapp -synchash $synchash
      }elseif($media){
        write-ezlogs ">>>> Playing MediaL $($Media.title) -- Playlist_ID: $($Playlist_ID)" -showtime
        Start-Media -Media $Media -thisApp $thisapp -synchashWeak ([System.WeakReference]::new($synchash))
      }elseif($thisapp.config.Auto_Playback -and $item.RoutedEvent.Name -notmatch 'DoubleClick' -and $item.RoutedEvent -notmatch 'DoubleClick'){
        #If no media selected to play, none is currently playing, and Auto playback is enabled, and event is not a doubleclick, then skip to next
        write-ezlogs "[PLAYMEDIA] Playing next media in queue" -showtime -warning
        Skip-Media -synchash $synchash -thisApp $thisApp
      }else{
        #No media or action found to continue, act like this never happened!
        if($synchash.PlayButton_ToggleButton.isChecked){
          $synchash.PlayButton_ToggleButton.isChecked = $false
        } 
        if($synchash.PlayButton_ToggleButton.Uid -eq 'IsPaused'){
          $synchash.PlayButton_ToggleButton.Uid = $null
        }
        if($synchash.MiniPlayButton_ToggleButton.Uid -eq 'IsPaused'){
          $synchash.MiniPlayButton_ToggleButton.Uid = $null
        }
        $NoPlaylistUpdate = $true
        write-ezlogs "[PLAYMEDIA] Could not find media to play from routed event! - $($item.RoutedEvent) - originalsource: $($item.OriginalSource)" -showtime -warning 
      }  
    }
  }catch{
    write-ezlogs "An exception has occurred attempting to execute playback for media $($Media.url)" -catcherror $_ -AlertUI
  }finally{
    #Set the current playing playlist
    if(-not [string]::IsNullOrEmpty($Playlist_ID) -and !$NoPlaylistUpdate){
      write-ezlogs "[PLAYMEDIA] >>>> Current Playlist_ID: $($Playlist_ID)" -showtime
      $Synchash.Current_Playing_Playlist = $Playlist_ID
      if($_.Source.Name -in 'SpotifyTable','YoutubeTable','MediaTable','TwitchTable' -or $_.source -is [System.Windows.Controls.Primitives.ToggleButton] -or $_.Source.tag.source.Name -in 'SpotifyTable','YoutubeTable','MediaTable','TwitchTable'){ 
        $Synchash.Current_Playing_Playlist_Source = 'Library'
      }elseif($_.Source.Name -in 'Track','Playlists_TreeView','LocalMedia_TreeView','TrayPlayer_TreeView' -or $_.Source.tag.source.Name -in 'Track','Playlists_TreeView','LocalMedia_TreeView','TrayPlayer_TreeView'){
        $Synchash.Current_Playing_Playlist_Source = 'Playlist'
      }else{
        $Synchash.Current_Playing_Playlist_Source = $null
      }
    }elseif(!$NoPlaylistUpdate){
      #Clear tracking of any current playing playlists
      $Synchash.Current_Playing_Playlist = $null
      $Synchash.Current_Playing_Playlist_Source = $null
    } 
    if($thisApp.Config.Dev_mode){
      write-ezlogs "[PLAYMEDIA] item: $($item | out-string)" -Dev_mode
      write-ezlogs "[PLAYMEDIA] item.Source: $($item.Source | out-string)" -Dev_mode
      write-ezlogs "[PLAYMEDIA] sender: $($sender | out-string)" -Dev_mode
      write-ezlogs "[PLAYMEDIA] OriginalSource: $($_.OriginalSource | out-string)" -Dev_mode
      write-ezlogs "[PLAYMEDIA] OriginalSource.datacontext: $($_.OriginalSource.datacontext | out-string)" -showtime -warning -Dev_mode
      write-ezlogs "[PLAYMEDIA] Media_ID: $($Media_ID | out-string)" -Dev_mode
      write-ezlogs "[PLAYMEDIA] Playlist_ID: $($Playlist_ID)" -Dev_mode
      write-ezlogs "[PLAYMEDIA] Media Profile: $($Media)" -Dev_mode
    }
  }
}
[System.Windows.RoutedEventHandler]$synchash.PlayMedia_Command = $synchash.PlayMedia_Scriptblock
#---------------------------------------------- 
#endregion Play Media Handlers
#----------------------------------------------

#---------------------------------------------- 
#region Edit Cell Handlers
#----------------------------------------------
$synchash.EditCell_Scriptblock = {
  param($sender,[System.Windows.RoutedEventArgs]$item)
  try{
    if($thisApp.Config.Dev_mode){
      write-ezlogs "[EditCell] e.RoutedEvent.Name $($item | out-string)" -Dev_mode
      write-ezlogs "[EditCell] sender.DataContext $($sender.DataContext | out-string)" -Dev_mode
      write-ezlogs "[EditCell] Sender.tag: $($sender.tag)" -Dev_mode
    }
    switch($Sender.Name)
    {
      'Mediatable_Editbutton' {
        $synchash.MediaTable.AllowEditing = $true
        if($thisApp.Config.Dev_mode){
          write-ezlogs "[EditCell] SelectionController.CurrentCellManager : $($synchash.MediaTable.SelectionController.CurrentCellManager | out-string)" -Dev_mode -logtype LocalMedia
          write-ezlogs "[EditCell] CurrentRowColumnIndex: $($synchash.MediaTable.SelectionController.CurrentCellManager.CurrentRowColumnIndex | out-string)" -Dev_mode -logtype LocalMedia
          write-ezlogs "[EditCell] CurrentCell: $($synchash.MediaTable.SelectionController.CurrentCellManager.CurrentCell | out-string)" -Dev_mode -logtype LocalMedia
        }
        $synchash.MediaTable.MoveCurrentCell($synchash.MediaTable.SelectionController.CurrentCellManager.CurrentRowColumnIndex)   
        $synchash.MediaTable.SelectionController.CurrentCellManager.BeginEdit()
        $item.Handled = $true
      }
      'Spotifytable_Editbutton' {
        $synchash.Spotifytable.AllowEditing = $true
        if($thisApp.Config.Dev_mode){
          write-ezlogs "[EditCell] SelectionController.CurrentCellManager : $($synchash.Spotifytable.SelectionController.CurrentCellManager | out-string)" -Dev_mode
          write-ezlogs "[EditCell] CurrentRowColumnIndex: $($synchash.Spotifytable.SelectionController.CurrentCellManager.CurrentRowColumnIndex | out-string)" -Dev_mode
          write-ezlogs "[EditCell] CurrentCell: $($synchash.Spotifytable.SelectionController.CurrentCellManager.CurrentCell | out-string)" -Dev_mode
        }
        $synchash.Spotifytable.MoveCurrentCell($synchash.Spotifytable.SelectionController.CurrentCellManager.CurrentRowColumnIndex)
        $synchash.Spotifytable.SelectionController.CurrentCellManager.BeginEdit()
        $item.Handled = $true
        write-ezlogs "[SpotifyEditCell] SelectionController.CurrentCellManager : $($synchash.Spotifytable.SelectionController.CurrentCellManager | out-string)" -logtype Spotify
      }
      'Youtubetable_Editbutton' {
        $synchash.Youtubetable.AllowEditing = $true
        if($thisApp.Config.Dev_mode){
          write-ezlogs "[EditCell] SelectionController.CurrentCellManager : $($synchash.Youtubetable.SelectionController.CurrentCellManager | out-string)" -Dev_mode
          write-ezlogs "[EditCell] CurrentRowColumnIndex: $($synchash.Youtubetable.SelectionController.CurrentCellManager.CurrentRowColumnIndex | out-string)" -Dev_mode
          write-ezlogs "[EditCell] CurrentCell: $($synchash.Youtubetable.SelectionController.CurrentCellManager.CurrentCell | out-string)" -Dev_mode
        }
        $synchash.Youtubetable.MoveCurrentCell($synchash.Youtubetable.SelectionController.CurrentCellManager.CurrentRowColumnIndex)
        $synchash.Youtubetable.SelectionController.CurrentCellManager.BeginEdit()
        $item.Handled = $true
        write-ezlogs "[YoutubeEditCell] SelectionController.CurrentCellManager : $($synchash.Youtubetable.SelectionController.CurrentCellManager | out-string)" -logtype Youtube
      }
      'Twitchtable_Editbutton' { 
        $synchash.Twitchtable.AllowEditing = $true
        if($thisApp.Config.Dev_mode){
          write-ezlogs "[EditCell] SelectionController.CurrentCellManager : $($synchash.Twitchtable.SelectionController.CurrentCellManager | out-string)" -Dev_mode
          write-ezlogs "[EditCell] CurrentRowColumnIndex: $($synchash.Twitchtable.SelectionController.CurrentCellManager.CurrentRowColumnIndex | out-string)" -Dev_mode
          write-ezlogs "[EditCell] CurrentCell: $($synchash.Twitchtable.SelectionController.CurrentCellManager.CurrentCell | out-string)" -Dev_mode
        }
        $synchash.Twitchtable.MoveCurrentCell($synchash.Twitchtable.SelectionController.CurrentCellManager.CurrentRowColumnIndex)
        $synchash.Twitchtable.SelectionController.CurrentCellManager.BeginEdit()
        $item.Handled = $true
        write-ezlogs "[TwitchEditCell] SelectionController.CurrentCellManager : $($synchash.Twitchtable.SelectionController.CurrentCellManager | out-string)" -logtype Twitch
      }
    }  
  }catch{
    write-ezlogs "An exception has occurred attempting to edit media library cell" -catcherror $_
  }
}
[System.Windows.RoutedEventHandler]$synchash.EditCell_Command = $synchash.EditCell_Scriptblock
#---------------------------------------------- 
#endregion Edit Cell Handlers
#----------------------------------------------

#---------------------------------------------- 
#region DeleteEnter Handler
#TODO: Review - this hasn't been touched in a while, probably needs refactor
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.KeyDown_Command = {
  param([Parameter(Mandatory)][Object]$sender,[Parameter(Mandatory)][Windows.Input.KeyEventArgs]$e)
  $Media = $_.OriginalSource.DataContext
  if(!$Media.url){$Media = $sender.tag}
  if(!$Media.url){$Media = $sender.tag.Media} 
  if(!$Media.url){$Media = $sender.selecteditem.tag.Media}
  write-ezlogs "Keydown Pressed (Key: $($e.Key)) - OriginalSource: $($_.OriginalSource | Select-Object *)" -loglevel 3
  if($e.Key -eq 'Enter' -and $Media.url){
    try{
      #If we got an ID, lets see if we have a profile for it
      if($media.source -eq 'Spotify' -or $media.url -match 'spotify\:' -and -not [string]::IsNullOrEmpty($Media.id)){
        $Media = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_ID $Media.id
        Start-SpotifyMedia -Media $Media -thisApp $thisApp -synchash $synchash -use_WebPlayer:$thisapp.config.Spotify_WebPlayer -Show_notifications:$thisApp.config.Show_notifications -RestrictedRunspace:$thisapp.config.Spotify_WebPlayer
      }else{
        Start-Media -Media $Media -thisApp $thisApp -synchashWeak ([System.WeakReference]::new($synchash)) -Show_notification 
      }  
    }catch{
      write-ezlogs "An exception occurred attempting to play media using keyboard event $($e.Key | out-string) for media $($Media.id)" -showtime -catcherror $_
    }    
  }elseif($e.Key -eq 'Delete'-and $Media.url){
    try{
      if($thisApp.config.Current_Playlist.values -contains $Media.id){
        write-ezlogs " | Removing $($Media.id) from Play Queue" -showtime
        #$index_toremove = $thisApp.config.Current_Playlist.GetEnumerator() | Where-Object {$_.value -eq $Media.id} | select * -ExpandProperty key
        $index_toremove = Get-IndexesOf $thisApp.config.Current_Playlist.values -Value $Media.id
        if(-not [string]::IsNullOrEmpty($index_toremove)){
          [Void]$thisApp.config.Current_Playlist.Remove($index_toremove)
        }
      }
      write-ezlogs ">>>> Saving app config: $($thisapp.Config.Config_Path)" -showtime
      Export-SerializedXML -InputObject $thisApp.Config -Path $thisapp.Config.Config_Path -isConfig
      Get-PlayQueue -verboselog:$false -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace
      Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisApp -use_Runspace
    }catch{
      write-ezlogs "An exception occurred removing media $($Media.id) using keyboard event $($e.Key | out-string)" -showtime -catcherror $_
    } 
  }   
}
#---------------------------------------------- 
#endregion DeleteEnter Handler
#----------------------------------------------

#---------------------------------------------- 
#region Download Media Handler
#----------------------------------------------
[System.Windows.RoutedEventHandler]$Synchash.DownloadMedia_Command = {
  param($sender)
  $Media = $_.OriginalSource.DataContext
  if(!$Media.url){$Media = $sender.tag}
  if(!$Media.url){$Media = $sender.tag.Media} 
  if(!$Media.url){$Media = $_.OriginalSource.tag.media} 
  if(($Media.url -match 'youtube\.com' -or $Media.url -match 'youtu\.be' -or $Media.url -match 'soundcloud\.com') -and $Media.url -notmatch 'tv\.youtube\.com'){ 
    if([System.IO.Directory]::Exists($thisApp.Config.Youtube_Download_Path)){
      $DownloadPath = $thisApp.Config.Youtube_Download_Path
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
      $Button_Settings.AffirmativeButtonText = 'Yes'
      $Button_Settings.NegativeButtonText = 'No'  
      $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Download Media","Are you sure you wish to download $($media.title) to $DownloadPath`?",$okandCancel,$Button_Settings)
      if($result -eq 'Affirmative'){
        write-ezlogs ">>>> User wished to download $($media.title)" -showtime
      }else{
        write-ezlogs "User did not wish to download $($media.title)" -showtime -warning
        return
      }
    }else{
      $DownloadPath = Open-FolderDialog -Title 'Select the directory path where media will be downloaded to'
    }  
    if([System.IO.Directory]::Exists($DownloadPath)){
      write-ezlogs ">>>> Downloading: $($Media.title) -- to: $DownloadPath" -showtime
      Invoke-DownloadMedia -Media $Media -Download_Path $DownloadPath -synchash $synchash -thisapp $thisapp -Show_notification -thisScript $thisScript 
    }
  }elseif($Media.Source -eq 'TOR'){
    if($sender.header -eq 'Stream'){
      $StreamPlayback = $true
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
      $Button_Settings.AffirmativeButtonText = 'Yes'
      $Button_Settings.NegativeButtonText = 'No'  
      $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Stream Torrent","Are you sure you wish to stream torrent $($media.title)`?",$okandCancel,$Button_Settings)
      if($result -eq 'Affirmative'){
        write-ezlogs ">>>> User wished to stream $($media.title)" -showtime
        $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
        $Button_Settings.AffirmativeButtonText = 'Yes'
        $Button_Settings.NegativeButtonText = 'No'  
        $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
        $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Save Torrent","Do you also wish to save/download the torrent media to a local path`?",$okandCancel,$Button_Settings)
        if($result -eq 'Affirmative'){
          write-ezlogs ">>>> User wished to download $($media.title)" -showtime
          $DownloadPath = Open-FolderDialog -Title 'Select the directory path where the torrent will be downloaded to' 
          $SaveTorrent = $true
        }else{
          write-ezlogs "User did not wish to download $($media.title)" -showtime -warning
          $DownloadPath = "$($thisApp.Config.Temp_Folder)"
          $SaveTorrent = $false
        }
        $synchash.Now_Playing_Title_Label.DataContext = 'LOADING...'
      }else{
        write-ezlogs "User did not wish to stream: $($media.title)" -showtime -warning
        return
      }       
    }else{
      $StreamPlayback = $false
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
      $Button_Settings.AffirmativeButtonText = 'Yes'
      $Button_Settings.NegativeButtonText = 'No'  
      $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Download Torrent","Are you sure you wish to download $($media.title)`?",$okandCancel,$Button_Settings)
      if($result -eq 'Affirmative'){
        write-ezlogs ">>>> User wished to download: $($media.title)" -showtime
        $SaveTorrent = $true

      }else{
        write-ezlogs "User did not wish to download: $($media.title)" -showtime -warning
        return
      }
      $DownloadPath = Open-FolderDialog -Title 'Select the directory path where the torrent will be downloaded to'   
    }
    if([System.IO.Directory]::Exists($DownloadPath)){
      write-ezlogs ">>>> Downloading $($Media.title) to $DownloadPath" -showtime -logtype Tor
      Save-Torrent -synchash $synchash -thisapp $thisapp -DownloadPath $DownloadPath -Torrent $Media -CheckVPN -StreamPlayback:$StreamPlayback -SaveTorrent:$SaveTorrent
    }
  }else{
    write-ezlogs "Selected media is not currently supported for download! Sorry!" -warning -AlertUI
  }   
}
#---------------------------------------------- 
#endregion Download Media Handler
#----------------------------------------------

#---------------------------------------------- 
#region Record Media Handler
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.RecordMedia_Command = {
  param($sender)
  $Media = $_.OriginalSource.DataContext
  if(!$Media.url){$Media = $sender.tag}
  if(!$Media.url){$Media = $sender.tag.Media} 
  if(!$Media.url){$Media = $_.OriginalSource.tag.media}  
  if(!$Media.url){
    write-ezlogs "To Record, first select the media you wish to record from a playlist or library, then right-click and select 'Record'.`nTo learn more, see help topic for 'Enable Spotify Integration' under Spotify settings to learn how to use" -loglevel 2 -AlertUI
    $synchash.RecordButton_ToggleButton.isChecked = $false
    return
  }
  if(($media.Source -eq 'Spotify') -or $media.url -match 'spotify\:'){
    $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
    $Button_Settings.AffirmativeButtonText = 'Yes'
    $Button_Settings.NegativeButtonText = 'No'  
    $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Record Media","Do you wish to start recording media $($media.title)`?`n`nYou will be prompted for a location to save the recording",$okandCancel,$Button_Settings)
    if($result -eq 'Affirmative'){
      write-ezlogs ">>>> User wished to record $($media.title)" -showtime
    }else{
      write-ezlogs "User did not wish to record $($media.title)" -showtime -warning
      $synchash.RecordButton_ToggleButton.isChecked = $false
      return
    }
    $result = Open-FolderDialog -Title 'Select the directory path where media recording will be saved to'
    if([System.IO.Directory]::Exists($result)){
      write-ezlogs ">>>> Recording $($Media.title) and saving to $result" -showtime
      if($Media.duration){
        $record_duration = [timespan]::Parse($Media.duration)
      }
      Start-SpotifyMedia -Media $Media -thisApp $thisapp -synchash $synchash -use_WebPlayer:$thisapp.config.Spotify_WebPlayer -Show_notifications:$thisApp.config.Show_notifications -RestrictedRunspace:$thisapp.config.Spotify_WebPlayer
      $record_media_scriptblock = {
        param
        (
          [string]$result = $result,
          $Media = $media,
          [timespan]$record_duration = $record_duration
        )
        Start-AudioRecorder -Savepath $result -Output_Type flac -filename $($Media.title) -media $media -duration $record_duration -Overwrite -synchash $synchash -thisApp $thisApp -write_tags $media  
      }
      $Variable_list = (Get-Variable) | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
      Start-Runspace -scriptblock $record_media_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'record_media_scriptblock'
    }else{
      write-ezlogs "The provided directory path is invalid! Cannot continue" -showtime -warning -AlertUI
    }
  }else{
    write-ezlogs "Provided media is not valid to use with the recorder -- Media: $($media.url)" -warning -AlertUI
  }  
}
#---------------------------------------------- 
#endregion Download Media Handler
#----------------------------------------------

#---------------------------------------------- 
#region Download Timer
#----------------------------------------------
$synchash.downloadTimer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.downloadTimer.Interval = [timespan]::FromSeconds(1)
$synchash.Download_Notification_Action = {
  try{
    write-ezlogs ">>>> Attempting to cancel and hault youtube video downloads" -warning
    $synchash.Download_Cancel = $true
    if(Get-Process 'yt-dlp*'){
      write-ezlogs "| Closing yt-dlp process" -warning
      Get-Process 'yt-dlp*' | Stop-Process -Force
    }
    $synchash.downloadTimer.stop()
  }catch{
    write-ezlogs "An exception occurred in Download_Notification_Action" -catcherror $_
  }
}
$synchash.downloadTimer.add_tick({
    try{
      if($synchash.Download_status -and -not [string]::IsNullOrEmpty($synchash.Download_message) -and $synchash.Download_UID -and !$synchash.Download_Cancel){
        $download_notification = $synchash.Notifications_Grid.items | Where-Object {$_.id -eq $synchash.Download_UID}        
        if($download_notification){
          if($synchash.Download_message -match '\[SUCCESS\]'){
            $level = 'SUCCESS'
          }elseif($synchash.Download_message -match '\[WARNING\]'){
            $level = 'WARNING'
          }elseif($synchash.Download_message -match '\[ERROR\]'){
            $level = 'ERROR'
          }else{
            $level = 'INFO'
          }
          [int]$id = $($synchash.Download_UID)
          write-ezlogs "Updating download notification with ID $($id)" -Dev_mode
          Update-Notifications -id $id -Level $level -Message $synchash.Download_message -VerboseLog -thisApp $thisapp -synchash $synchash -EnableAudio:$false -ActionName 'Cancel' -ActionScriptBlock $synchash.Download_Notification_Action
        }          
      }else{
        write-ezlogs "Stopping download timer -- Download_status: $($synchash.Download_status) -- Download_message: $($synchash.Download_message) -- Download_UID: $($synchash.Download_UID)"
        $this.Stop()
      }
    }catch{
      write-ezlogs "An exception occurred in downloadTimer" -catcherror $_
      $this.Stop()
    }
})
#---------------------------------------------- 
#endregion Download Timer
#----------------------------------------------

#---------------------------------------------- 
#region Start Media Timer
#----------------------------------------------
$synchash.start_media_timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.start_media_timer.add_tick({
    try{
      if($synchash.Start_media){
        write-ezlogs "Attempting restart of media: $($synchash.ForceUseYTDLP)" -warning
        if($synchash.Youtube_WebPlayer_retry -eq 'NoEmbed'){
          $use_Invidious = $false
          $No_YT_Embed = $true
        }elseif($synchash.Youtube_WebPlayer_retry -eq 'Invidious'){
          $use_Invidious = $true
          $No_YT_Embed = $false
        }
        if($this.tag -eq 'EnableCasting'){
          $EnableCasting = $true
        }else{
          $EnableCasting = $false
        }
        Start-Media -Media $synchash.Start_media -thisApp $thisapp -synchashWeak ([System.WeakReference]::new($synchash)) -ForceUseYTDLP:$synchash.ForceUseYTDLP -Use_invidious:$use_Invidious -No_YT_Embed:$No_YT_Embed -EnableCasting:$EnableCasting
      }
    }catch{
      write-ezlogs "An exception occurred relaunching Start-Media" -showtime -catcherror $_
    }finally{
      $this.tag = $null
      $this.Stop()
    }  
})
#---------------------------------------------- 
#endregion Start Media Timer
#----------------------------------------------

#---------------------------------------------- 
#region Stop Media Timer
#----------------------------------------------
$synchash.Stop_media_timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.Stop_media_timer.add_tick({
    try{
      write-ezlogs "Attempting to cancel/stop media playback" -showtime -warning
      Stop-Media -synchash ([System.WeakReference]::new($synchash)) -thisApp $thisApp -UpdateQueue -StopMonitor
    }catch{
      write-ezlogs "An exception occurred in Stop_media_timer" -showtime -catcherror $_
    }finally{
      $this.Stop()
    }  
})
#---------------------------------------------- 
#endregion Stop Media Timer
#----------------------------------------------

#---------------------------------------------- 
#region Mute Media Timer
#----------------------------------------------
$synchash.Mute_media_timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.Mute_media_timer.add_tick({
    try{
      write-ezlogs "Attempting to Mute playback" -showtime -warning
      Set-Mute -synchash $synchash -thisApp $thisApp 
    }catch{
      write-ezlogs "An exception occurred in Mute_media_timer" -showtime -catcherror $_
    }finally{
      $this.Stop()
    }  
})
#---------------------------------------------- 
#endregion Mute Media Timer
#----------------------------------------------

$EndEditCurrentCellScripblock = {
  param([Parameter(Mandatory)][Object]$Sender,[Parameter(Mandatory)][Syncfusion.UI.Xaml.Grid.CurrentCellEndEditEventArgs]$e)
  try{
    #TODO: For updating multiple items - has issues when using custom object type from serializedxml
    <#        $selectedCells = $sender.GetSelectedCells()
        $propertyAccessProvider= $sender.View.GetPropertyAccessProvider()
        $itemProperties = $sender.View.GetItemProperties()
        $newValue = $propertyAccessProvider.GetValue($sender.CurrentItem, $sender.CurrentColumn.MappingName)
        write-ezlogs ">>>> MediaTable cell edit completed for Column Mapping Name: $($sender.CurrentColumn.MappingName) -- newValue: $($newValue)"
        if($selectedCells.Count -gt 0){
        try{
        $selectedCells | Foreach {
        $cellinfo = $_
        write-ezlogs "Updating Selected Cell: $($cellinfo)" -warning
        $propInfo = $itemProperties.Find($cellinfo.column.MappingName,$true)
        if($propInfo -and $propInfo.PropertyType -eq $newValue.Gettype()){
        $propertyAccessProvider.SetValue($cellinfo.RowData, $cellinfo.Column.MappingName, $newValue);
        }elseif($propInfo){
        $value = [convert]::ChangeType($newValue, $propInfo.PropertyType)
        $propertyAccessProvider.SetValue($cellinfo.RowData, $cellinfo.Column.MappingName, $Value);
        }
        }
        }catch{
        write-ezlogs "An exception occurred updating properties for selected cells" -catcherror $_
        }
    }#>
    $RowColumnIndex = $e.RowColumnIndex
    $RowGenerator = $sender.RowGenerator
    $dataRow = $RowGenerator.Items.where({$_.rowindex -eq $RowColumnIndex.RowIndex})
    $RowData = $dataRow.RowData
    if($sender.name -eq 'MediaTable' -and $RowData){
      write-ezlogs "| Updated RowData: $($RowData | out-string)"
      Update-LocalMedia -synchash $synchash -UpdateMedia $RowData -UpdatePlaylists -thisapp $thisApp -use_runspace -NoTagScan
    }elseif($sender.name -eq 'SpotifyTable' -and $RowData){
      write-ezlogs "| Updated Spotify RowData: $($RowData | out-string)"
      Update-SpotifyMedia -synchash $synchash -UpdateMedia $RowData -UpdatePlaylists -thisapp $thisApp -use_runspace
    }elseif($sender.name -eq 'YoutubeTable' -and $RowData){
      write-ezlogs "| Updated Youtube RowData: $($RowData | out-string)"
      Update-YoutubeMedia -synchash $synchash -UpdateMedia $RowData -UpdatePlaylists -thisapp $thisApp -use_runspace
    }elseif($sender.name -eq 'TwitchTable' -and $RowData){
      #TODO: Finish for Twitch library
      write-ezlogs "[NOT_IMPLEMENTED] | Updated RowData for $($sender.name): $($RowData | out-string)" -warning
    }
  }catch{
    write-ezlogs "An exception occurred in $($sender.name).add_CurrentCellValueChanged for current item: $($sender.CurrentItem)" -catcherror $_
  }finally{
    $sender.AllowEditing = $false
  }
}

#---------------------------------------------- 
#region Import-Media
#----------------------------------------------
if($thisApp.Config.Startup_perf_timer){
  $import_media_measure = [system.diagnostics.stopwatch]::StartNew()
}
#region LocalMedia_Startup_Timers
$synchash.LocalMedia_TableStartup_timer = [System.Windows.Threading.DispatcherTimer]::new()
$LocalMedia_Startup_Timer_Tick = {
  try{         
    $LocalMedia_TableStartup_timer_measure = [system.diagnostics.stopwatch]::StartNew()
    #Default Library Columns
    if([string]::IsNullOrEmpty($thisApp.Config.LocalMedia_Library_Columns)){
      $thisApp.Config.LocalMedia_Library_Columns = 'Display_Name','Title','Artist','Album'
    }
    if($synchash.MediaTable){       
      if(!$NoMediaLibrary){
        if($thisApp.Config.Dev_mode){
          $synchash.MediaTable.add_Loaded({
              try{
                $sender = ($args[0])
                $e = ($args[1])          
                write-ezlogs "##### MediaTable Loaded event: $($e | out-string)" -Dev_mode           
              }catch{
                write-ezlogs "An exception occurred in MediaTable.add_Loaded" -catcherror $_
              }
          })
        }         
        #[Syncfusion.SfSkinManager.SfSkinManager]::SetTheme($synchash.MediaTable,[Syncfusion.SfSkinManager.Theme]::new('MaterialDark',[string[]]{'ComboBoxAdv','DropDownButtonAdv','Windows11Dark'}))
        if($synchash.Mediatable.Columns -and $this.tag){
          $synchash.Mediatable.Columns.Suspend()
          $synchash.MediaTable.Columns | & { process {
              if($_.Headertext -eq 'Play'){
                if($thisApp.Config.Dev_mode){write-ezlogs " | Adding Mediatable play button" -showtime -logtype LocalMedia -Dev_mode}
                $StackPanelFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.VirtualizingStackPanel])
                [Void]$StackPanelFactory.SetValue([System.Windows.Controls.VirtualizingStackPanel]::OrientationProperty, ([System.Windows.Controls.Orientation]::Horizontal))
                [Void]$StackPanelFactory.SetValue([System.Windows.Controls.VirtualizingStackPanel]::IsVirtualizingProperty, $true)
                [Void]$StackPanelFactory.SetValue([System.Windows.Controls.VirtualizingStackPanel]::VirtualizationModeProperty, [System.Windows.Controls.VirtualizationMode]::Recycling)
                $buttonFactory = [System.Windows.FrameworkElementFactory]::new([Windows.Controls.Primitives.ToggleButton])
                $buttonFactory.Name = 'Mediatable_Playbutton'
                $Binding = [System.Windows.Data.Binding]::new("Value")
                [Void]$buttonFactory.SetBinding([Windows.Controls.Primitives.ToggleButton]::TagProperty,$Binding)
                [Void]$buttonFactory.SetValue([Windows.Controls.Primitives.ToggleButton]::BackgroundProperty, $synchash.Window.TryFindResource('TransparentBackgroundStyle'))
                [Void]$buttonFactory.SetValue([Windows.Controls.Primitives.ToggleButton]::StyleProperty, $synchash.Window.TryFindResource('PlayGridButtonStyle') )
                if($thisApp.Config.Dev_mode){write-ezlogs " | Setting Mediatable Play button click event" -showtime -logtype LocalMedia -Dev_mode}
                [Void]$buttonFactory.RemoveHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.PlayMedia_Command)
                [Void]$buttonFactory.AddHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.PlayMedia_Command)
                [Void]$StackPanelFactory.AppendChild($buttonFactory)
                $dataTemplate = [System.Windows.DataTemplate]::new()
                $dataTemplate.VisualTree = $StackPanelFactory
                $_.CellTemplate = $dataTemplate
              }elseif($_.Headertext -in 'Display Name','Title','Artist','Album','Track'){                  
                $GridFactory =[System.Windows.FrameworkElementFactory]::new([Windows.Controls.Grid])
                $TextBlockFactory = [System.Windows.FrameworkElementFactory]::new([Windows.Controls.TextBlock])
                $Binding = [System.Windows.Data.Binding]::new("Value")
                [Void]$TextBlockFactory.SetBinding([Windows.Controls.TextBlock]::TextProperty,$Binding)
                [Void]$TextBlockFactory.SetValue([Windows.Controls.Button]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)
                $buttonFactory = [System.Windows.FrameworkElementFactory]::new([Windows.Controls.Button])
                $buttonFactory.Name = 'Mediatable_EditbuttonFactory'
                [Void]$buttonFactory.SetValue([Windows.Controls.Button]::NameProperty, 'Mediatable_Editbutton')
                [Void]$buttonFactory.RemoveHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.EditCell_Command)
                [Void]$buttonFactory.AddHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.EditCell_Command)
                [Void]$buttonFactory.SetValue([Windows.Controls.Button]::BackgroundProperty, $synchash.Window.TryFindResource('TransparentBackgroundStyle'))
                [Void]$buttonFactory.SetValue([Windows.Controls.Button]::StyleProperty, $synchash.Window.TryFindResource('EditButtonStyle'))
                [Void]$buttonFactory.SetValue([Windows.Controls.Button]::TagProperty, $_.MappingName)
                [Void]$GridFactory.AppendChild($TextBlockFactory)
                [Void]$GridFactory.AppendChild($buttonFactory)
                $dataTemplate = [System.Windows.DataTemplate]::new()
                $dataTemplate.VisualTree = $GridFactory
                $_.CellTemplate = $dataTemplate
                if($_.Headertext -notin $thisApp.Config.LocalMedia_Library_Columns){
                  $_.isHidden = $true
                }
              }elseif($_.Headertext -notin $thisApp.Config.LocalMedia_Library_Columns){
                $_.isHidden = $true 
              }                     
          }}
          $synchash.Mediatable.Columns.Resume()
        }
        if($synchash.Media_ContextMenu){
          [Void]$synchash.Mediatable.RemoveHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
          [Void]$synchash.Mediatable.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
        }
        if($synchash.All_local_Media.count -gt 0){
          $synchash.MediaTable.BeginInit()
          write-ezlogs ">>>> Creating GridVirtualizingCollectionView for All_local_Media and binding to Mediatable itemssource" -showtime -loglevel 2 -logtype LocalMedia
          $syncHash.MediaTable.Itemssource = [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new($synchash.All_local_Media)
          if($syncHash.MediaTable.Itemssource.SourceCollection.Capacity){
            $syncHash.MediaTable.Itemssource.SourceCollection.Capacity = $synchash.All_local_Media.count
          }
          $syncHash.MediaTable.Itemssource.UsePLINQ = $true
          <#          # Create a binding to pair the datagrid to the observable collection
              $MediaTableBinding = [System.Windows.Data.Binding]::new()
              $MediaTableBinding.Source = $synchash.LocalMedia_View.Target
              $MediaTableBinding.Mode = [System.Windows.Data.BindingMode]::OneWay
          [void][System.Windows.Data.BindingOperations]::SetBinding($syncHash.MediaTable,[Syncfusion.UI.Xaml.Grid.SfDataGrid]::ItemsSourceProperty, $MediaTableBinding)#>
          $synchash.MediaTable.EndInit()
          $Binding = [System.Windows.Data.Binding]::new('Count')
          $Binding.Source = $syncHash.MediaTable.ItemsSource.records.View
          $Binding.Mode = [System.Windows.Data.BindingMode]::OneTime
          [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.Media_Table_Total_Media,[System.Windows.Controls.TextBlock]::TextProperty, $Binding)
          if($syncHash.MediaTable.ItemsSource){
            $syncHash.Mediatable.isEnabled = $true 
          }
          #Apply user groupings
          if(($syncHash.MediaTable) -and $thisApp.Config.Local_Group_By){
            try{   
              #TODO: Temporary to cleanup issue from old configs
              if($thisApp.Config.Local_Group_By -eq 'Syncfusion.UI.Xaml.Grid.GroupColumnDescription'){
                $Groups = 'Artist'
              }else{
                $Groups = $thisApp.Config.Local_Group_By
              }
              if($syncHash.MediaTable.GroupColumnDescriptions -is [Syncfusion.UI.Xaml.Grid.GroupColumnDescriptions]){
                [Void]$syncHash.MediaTable.GroupColumnDescriptions.clear()
                foreach($group in $groups){
                  if($group -and $syncHash.MediaTable.GroupColumnDescriptions.ColumnName -notcontains $group){
                    write-ezlogs " | Adding groupdescription to LocalMedia_View for property: $($group)" -logtype LocalMedia -LogLevel 2
                    $groupdescription = [Syncfusion.UI.Xaml.Grid.GroupColumnDescription]::new()
                    $groupdescription.ColumnName = $group
                    [Void]$syncHash.MediaTable.GroupColumnDescriptions.Add($groupdescription)             
                  }
                }
              }             
            }catch{
              write-ezlogs "An exception occurred attempting to set group descriptions" -showtime -catcherror $_
            }              
          }
          if($thisApp.Config.Enable_LocalMedia_Monitor -and $thisApp.Config.Media_Directories -and !$thisApp.LocalMedia_Monitor_Enabled){
            $thisApp.Config.Media_Directories | & { process {
                Start-FileWatcher -FolderPath $_ -MonitorSubFolders -use_Runspace -Start_ProfileManager:$(!$thisApp.ProfileManagerEnabled) -synchash $synchash -thisapp $thisApp -Runspace_Guid (New-GUID).Guid
            }}
          }        
        }else{
          write-ezlogs "No Local Media was found in LocalMedia_View to bind to MediaTable itemssource! Disabling Local Media Library" -showtime -warning -logtype LocalMedia
          if($syncHash.Mediatable.isEnabled){
            $syncHash.Mediatable.isEnabled = $false
          }
          if($syncHash.Mediatable.Itemssource -is [System.IDisposable]){
            $syncHash.Mediatable.Itemssource.dispose()
            $syncHash.Mediatable.Itemssource = $Null
          }
          if($syncHash.LocalMedia_Browser_Tab.isEnabled){
            $syncHash.LocalMedia_Browser_Tab.isEnabled = $false
          }
        }        
      } 
      if($synchash.LocalMedia_Progress_Ring){
        Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'LocalMedia_Progress_Ring' -Property 'isActive' -value $false
      }                                  
      if($synchash.LocalMedia_Progress_Label){
        $synchash.LocalMedia_Progress_Label.Visibility = 'Hidden'
      }
      if($synchash.LocalMedia_Progress2_Label){
        $synchash.LocalMedia_Progress2_Label.Visibility = 'Hidden'
      } 
      Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MediaTable' -Property 'isEnabled' -value $true    
      Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'MediaTable' -Property 'Visibility' -value 'Visible' 
      Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'LocalMedia_Browser_Tab' -Property 'Visibility' -value 'Visible'    
      if($syncHash.LocalMedia_Browser_Tab -and $syncHash.MainGrid_Bottom_TabControl.items -notcontains $syncHash.LocalMedia_Browser_Tab){
        write-ezlogs ">>>> Adding Local Media tab to media library" -showtime -logtype LocalMedia
        [Void]$syncHash.MainGrid_Bottom_TabControl.items.Add($syncHash.LocalMedia_Browser_Tab) 
      }
    }else{
      write-ezlogs "No Mediatable UI is available" -warning
    }                                                     
  }catch{
    write-ezlogs "[ERROR] An exception occurred attempting to set itemsource for MediaTable" -showtime -color red -CatchError $_
  }finally{
    $this.Stop()
    $this.tag = $Null
    if($LocalMedia_TableStartup_timer_measure){
      [Void]$LocalMedia_TableStartup_timer_measure.stop()
      write-ezlogs "LocalMedia_TableStartup_Timer Measure" -PerfTimer $LocalMedia_TableStartup_timer_measure
      $LocalMedia_TableStartup_timer_measure = $Null
    }
  }    
}
$synchash.LocalMedia_TableStartup_timer.add_Tick($LocalMedia_Startup_Timer_Tick)

$synchash.LocalMediaUpdate_timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.LocalMediaUpdate_timer.add_Tick({
    try{
      if($thisapp.config.LocalMedia_ImportMode -eq 'Fast'){
        if($synchash.LocalMedia_RefreshProgress_Ring){
          $synchash.LocalMedia_RefreshProgress_Ring.isActive = $true
        }
        if($synchash.MediaTable_RefreshLabel){
          $synchash.MediaTable_RefreshLabel.Visibility = 'Visible'
        }       
        if($synchash.Refresh_LocalMedia_Button){
          $synchash.Refresh_LocalMedia_Button.isEnabled = $false 
        }
        if($this.tag -ne $Null){
          Update-LocalMedia -synchash $synchash -thisApp $thisApp -UpdatePlaylists -UpdateDirectory $this.tag -update_Library
        }else{
          Update-LocalMedia -synchash $synchash -thisApp $thisApp -UpdatePlaylists -update_Library
        }        
      }                                   
    }catch{
      write-ezlogs 'An exception occurred in LocalMediaUpdate_timer' -showtime -catcherror $_
    }finally{
      $this.tag = $null
      $this.Stop()
    }   
})
#endregion LocalMedia_Startup_Timers

if($thisapp.Config.Import_Local_Media){
  Import-Module -Name "$Current_Folder\Modules\Import-Media\Import-Media.psm1" -NoClobber -DisableNameChecking -Scope Local
  Update-SplashScreen -hash $hash -SplashMessage 'Importing Local Media'
  Import-Media -Media_directories $thisapp.config.Media_Directories -use_runspace -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -startup -thisApp $thisapp -Refresh_All_Media -NoMediaLibrary:$NoMediaLibrary -RestrictedRunspace
}elseif($synchash.Window){
  write-ezlogs 'Importing of Local Media is not enabled' -showtime -Warning -logtype LocalMedia
  if($syncHash.Mediatable){
    $syncHash.Mediatable.isEnabled = $false
  }
  if($syncHash.LocalMedia_Browser_Tab){
    $syncHash.LocalMedia_Browser_Tab.isEnabled = $false
  }
  if($syncHash.MainGrid_Bottom_TabControl.items -contains $syncHash.LocalMedia_Browser_Tab){
    [Void]$syncHash.MainGrid_Bottom_TabControl.items.Remove($syncHash.LocalMedia_Browser_Tab) 
  }
}

#Column Chooser
if($synchash.LocalMedia_Column_Button){
  $synchash.LocalMedia_Column_Button.add_Loaded({
      try{
        $synchash.LocalMedia_Column_Button.items.clear()
        $synchash.MediaTable.Columns | & { process {
            $Header = $_.Headertext
            if($Header -notin 'Play' -and $synchash.LocalMedia_Column_Button.items -notcontains $Header){
              $MenuItem = [System.Windows.Controls.MenuItem]::new()
              $MenuItem.IsCheckable = $true     
              $MenuItem.Header = $Header
              if($_.isHidden){      
                $MenuItem.IsChecked = $false                 
              }else{
                $MenuItem.IsChecked = $true
              }
              $MenuItem.Add_Checked({
                  try{
                    $Column = Get-IndexesOf $synchash.Mediatable.Columns.HeaderText -Value $this.Header | & { process {
                        $synchash.Mediatable.Columns[$_]
                    }}
                    if($Column){
                      write-ezlogs ">>>> UnHiding column: $($Column.HeaderText)"
                      $Column.isHidden = $false
                    }
                    $ActiveColumns = Get-IndexesOf $synchash.Mediatable.Columns.isHidden -Value $false | & { process {
                        $c = $synchash.Mediatable.Columns[$_]
                        if($c -notin 'Play'){
                          $c.HeaderText
                        }
                    }}
                    $thisApp.Config.LocalMedia_Library_Columns = $ActiveColumns
                  }catch{
                    write-ezlogs "An exception occurred in add_checked for menuitem: $($this.Header)" -catcherror $_
                  }
              })
              $MenuItem.Add_UnChecked({
                  try{
                    $Column = Get-IndexesOf $synchash.Mediatable.Columns.HeaderText -Value $this.Header | & { process {
                        $synchash.Mediatable.Columns[$_]
                    }}
                    if($Column){
                      write-ezlogs ">>>> Hiding column: $($Column.HeaderText)"
                      $Column.isHidden = $true
                    }
                    $ActiveColumns = Get-IndexesOf $synchash.Mediatable.Columns.isHidden -Value $false | & { process {
                        $c = $synchash.Mediatable.Columns[$_]
                        if($c -notin 'Play'){
                          $c.HeaderText
                        }
                    }}
                    $thisApp.Config.LocalMedia_Library_Columns = $ActiveColumns
                  }catch{
                    write-ezlogs "An exception occurred in add_Unchecked for menuitem: $($this.Header)" -catcherror $_
                  }
              })
              [Void]$synchash.LocalMedia_Column_Button.items.add($MenuItem)
            }                    
        }}
      }catch{
        write-ezlogs "An exception occurred in LocalMedia_ColumnComboBox.add_Loaded" -catcherror $_
      }
  })
}

if($syncHash.MediaTable){
  #MediaTable Dragging
  $synchash.MediaTable.add_PreviewDragOver({
      param([Parameter(Mandatory)][Object]$Sender,[Parameter(Mandatory)][System.Windows.DragEventArgs]$e)
      try{
        if($e.Data.GetDataPresent("ListViewRecords")){
          $draggingRecords = $e.Data.GetData("ListViewRecords") -as [System.Collections.ObjectModel.ObservableCollection[object]]
        }else{ 
          $draggingRecords = $e.Data.GetData("Records") -as [System.Collections.ObjectModel.ObservableCollection[object]]
        }
        if($draggingRecords -eq $null){
          return
        }
        #To get the dropping position of the record 
        #$dropPosition = GetDropPosition(args, rowColumnIndex, draggingRecords); 
 
        #To Show the draggable popup with the DropAbove/DropBelow message 
        #ShowDragDropPopup(dropPosition, draggingRecords, args); 
 
        #To Show the up and down indicators while dragging the row 
        #if($this.AllowDrop){ 
        #  ShowDragIndicators($dropPosition, $rowColumnIndex, $args); 
        #}
        $e.Handled = $true
      }catch{
        write-ezlogs "An exception occurred in MediaTable.add_PreviewDragOver" -catcherror $_
      }
  })
  #MediaTable Editing
  $synchash.MediaTable.add_CurrentCellEndEdit($EndEditCurrentCellScripblock)
  $synchash.MediaTable.add_CurrentCellValueChanged({
      param([Parameter(Mandatory)][Object]$Sender,[Parameter(Mandatory)][Syncfusion.UI.Xaml.Grid.CurrentCellValueChangedEventArgs]$e)
      try{
        $RowColumnIndex = $e.RowColumnIndex
        $RowGenerator = $sender.RowGenerator
        $dataRow = $RowGenerator.Items.where({$_.rowindex -eq $RowColumnIndex.RowIndex})
        if(-not [string]::IsNullOrEmpty($dataRow.RowData) -and 'Display_Name' -notin $dataRow.RowData.psobject.properties.name){
          write-ezlogs ">>>> Adding missing propery 'Display_Name' to local media profile id: $($dataRow.RowData.id)" -warning
          $dataRow.RowData.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new('Display_Name',''))
        }
      }catch{
        write-ezlogs "An exception occurred in MediaTable.add_CurrentCellValueChanged" -catcherror $_
      }
  })

  #MediaTable Grouping
  $syncHash.MediaTable.GroupColumnDescriptions.add_CollectionChanged({
      param([Parameter(Mandatory)][Object]$sender,[Parameter(Mandatory)][System.Collections.Specialized.NotifyCollectionChangedEventArgs]$e)
      try{
        if($thisApp.Config.Dev_mode){write-ezlogs ">>>> LocalMedia GroupDescriptions Changed -- Action: $($e.action) - NewItems: $($e.newItems.ColumnName) - OldItems: $($e.OldItems.ColumnName) - OldStartingIndex: $($e.OldStartingIndex) - NewStartingIndex: $($e.NewStartingIndex)" -Dev_mode}
        if($e.action -eq 'Add' -and $e.newItems.ColumnName -notin $thisApp.Config.Local_Group_By){
          [Void]$thisApp.Config.Local_Group_By.add($e.newItems.ColumnName)
        }elseif($e.action -eq 'Remove' -and $e.OldItems.ColumnName -in $thisApp.Config.Local_Group_By){
          write-ezlogs ">>>> Removing group '$($e.OldItems.ColumnName)' from Local_Group_By"
          [Void]$thisApp.Config.Local_Group_By.Remove($e.OldItems.ColumnName)
        }
        if($thisApp.Config.LocalMedia_Library_CollapseAllGroups -and $e.action -eq 'Add'){
          try{
            $syncHash.MediaTable.AutoExpandGroups = $false
            write-ezlogs ">>>> Collapsing all groups for MediaTable - Column: $($e.newItems.ColumnName)"
            $synchash.MediaTable.CollapseAllGroup()
          }catch{
            write-ezlogs "An exception occurred calling MediaTable.CollapseAllGroup()" -catcherror $_
          }
        }                
      }catch{
        write-ezlogs "An exception occurred in LocalMedia_View.GroupDescriptions.add_CollectionChanged" -showtime -catcherror $_
      }
  })
}
if($synchash.LocalMediaCollapseGroups){
  $synchash.LocalMediaCollapseGroups.isChecked = $thisApp.Config.LocalMedia_Library_CollapseAllGroups
  $synchash.LocalMediaCollapseGroups.Add_Checked({
      param([Parameter(Mandatory)][Object]$Sender)
      try{
        if($synchash.MediaTable.GroupColumnDescriptions){
          write-ezlogs ">>>> Collapsing all groups for MediaTable"
          $syncHash.MediaTable.AutoExpandGroups = $false
          $synchash.MediaTable.CollapseAllGroup()
          $thisApp.Config.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new('LocalMedia_Library_CollapseAllGroups',$true))
        }else{
          write-ezlogs "No groups available to collapse for Mediatable" -warning
          $sender.isChecked = $false
          $thisApp.Config.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new('LocalMedia_Library_CollapseAllGroups',$false))
        }       
      }catch{
        write-ezlogs "An exception occurred in LocalMediaCollapseGroups.Add_Checked" -catcherror $_
      }
  })
  $synchash.LocalMediaCollapseGroups.Add_UnChecked({
      param([Parameter(Mandatory)][Object]$Sender)
      try{
        if($synchash.MediaTable.GroupColumnDescriptions){
          $syncHash.MediaTable.AutoExpandGroups = $true
          write-ezlogs ">>>> Expanding all groups for MediaTable"
          $synchash.MediaTable.ExpandAllGroup()
        }else{
          write-ezlogs "No groups available to expand for Mediatable" -warning
        } 
        $thisApp.Config.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new('LocalMedia_Library_CollapseAllGroups',$false))      
      }catch{
        write-ezlogs "An exception occurred in LocalMediaCollapseGroups.Add_Checked" -catcherror $_
      }
  })
}

#TODO: OLD FILTERS
if($synchash.FilterTextBox){
  $synchash.LocalMediaFilter_timer = [System.Windows.Threading.DispatcherTimer]::New([System.Windows.Threading.DispatcherPriority]::DataBind)
  $synchash.LocalMediaFilter_timer.add_Tick({
      try{
        $LocalMediaFilter_measure = [system.diagnostics.stopwatch]::StartNew()
        if($synchash.MediaTable.itemssource -and !$synchash.MediaTable.Itemssource.isInDeferRefresh -and $synchash.MediaTable.View){
          #$synchash.MediaTable.View.BeginInit()
          $synchash.MediaTable.View.Filter = {
            param ($item) 
            if(-not [string]::IsNullOrEmpty($synchash.FilterTextBox.Text)){
              $text = $(($synchash.FilterTextBox.Text)).trim()
            }
            $SearchPattern = "$([regex]::Escape($Text))"
            $($item.Title) -match $SearchPattern -or $($item.Display_Name) -match $SearchPattern -or $($item.Artist) -match $SearchPattern -or $($item.Album) -match $SearchPattern
          }                       
          #$synchash.MediaTable.View.EndInit()
          if($synchash.MediaTable.View){
            $synchash.MediaTable.View.RefreshFilter()
          }
          if($synchash.Media_Table_Total_Media.Text -ne "$($synchash.MediaTable.View.records.Count)"){
            $synchash.Media_Table_Total_Media.Text = "$($synchash.MediaTable.View.records.Count)"
          }
        }
      }catch{
        write-ezlogs "An exception occurred in LocalMediaFilter_timer" -catcherror $_
      }finally{
        $this.stop()
        $LocalMediaFilter_measure.stop()
        write-ezlogs "LocalMediaFilter_timer Measure" -PerfTimer $LocalMediaFilter_measure
      }
  })

  $synchash.FilterTextBox.Add_PreviewLostKeyboardFocus({
      param([Parameter(Mandatory)][Object]$sender,[Parameter(Mandatory)][System.Windows.Input.KeyboardFocusChangedEventArgs]$e)
      try{
        $newFocus = $e.NewFocus
        if($newFocus -is [Syncfusion.UI.Xaml.Grid.SfDataGrid] -or $newFocus -is [Syncfusion.UI.Xaml.Grid.GridCell]){
          write-ezlogs "Preventing new focus from: $($newFocus)" -warning
          $e.Handled = $true
        }       
      }catch{
        write-ezlogs "An exception occurrred in Add_PreviewLostKeyboardFocus event" -showtime -catcherror $_
      }
  })

  $synchash.FilterTextBox.Add_TextChanged({
      try{
        if(!$synchash.LocalMediaFilter_timer.isEnabled){
          $synchash.LocalMediaFilter_timer.start()
        }        
      }catch{
        write-ezlogs "An exception occurrred in FilterTextBox.Add_TextChanged event" -showtime -catcherror $_
      }
  }) 

  $synchash.MediaTable.Add_FilterChanged({
      param([Parameter(Mandatory)][Object]$sender,[Parameter(Mandatory)][Object][Syncfusion.UI.Xaml.Grid.GridFilterEventArgs]$e)
      try{
        $total = "$($synchash.MediaTable.View.records.Count)"
        if($synchash.Media_Table_Total_Media.Text -ne $total){
          $synchash.Media_Table_Total_Media.Text = $total
        }      
      }catch{
        write-ezlogs "An exception occurred in MediaTableFilterChanged" -showtime -catcherror $_
      }   
  })

  if($synchash.LocalSearch_Button){
    $synchash.LocalSearch_Button.Add_Click({
        try{
          if(!$synchash.LocalMediaFilter_timer.isEnabled){
            $synchash.LocalMediaFilter_timer.start()
          }          
        }catch{
          write-ezlogs "An exception occurred in LocalSearch_Button" -showtime -catcherror $_
        }   
    }) 
    $synchash.FilterTextBox.Add_PreviewKeyDown({
        param([Parameter(Mandatory)][Object]$sender,[Parameter(Mandatory)][Windows.Input.KeyEventArgs]$e)
        try{
          if($e.Key -eq 'Enter' -and !$synchash.LocalMediaFilter_timer.isEnabled){
            $synchash.LocalMediaFilter_timer.start()
          }
        }catch{
          write-ezlogs "An exception occurred in FilterTextBox.Add_PreviewKeyDown" -catcherror $_
        }
    })
  }
  #TODO: SfGrid FilterRow Test
  if($synchash.LocalMediaRowFilter){
    $synchash.LocalMediaRowFilter.Add_Checked({
        param($sender)
        try{
          if($synchash.MediaTable){
            $synchash.MediaTable.FilterRowPosition = 'FixedTop'
          }         
        }catch{
          write-ezlogs "An exception occurred in LocalMediaRowFilter.Add_Checked" -catcherror $_
        }
    })
    $synchash.LocalMediaRowFilter.Add_UnChecked({
        param($sender)
        try{
          if($synchash.MediaTable){
            $synchash.MediaTable.FilterRowPosition = 'None'
          }          
        }catch{
          write-ezlogs "An exception occurred in LocalMediaRowFilter.Add_Checked" -catcherror $_
        }
    })
  }
}
#---------------------------------------------- 
#endregion Import-Media
#----------------------------------------------

#---------------------------------------------- 
#region Refresh Local Media Button
#----------------------------------------------
$synchash.Refresh_LocalMedia_timer = [System.Windows.Threading.DispatcherTimer]::New([System.Windows.Threading.DispatcherPriority]::ApplicationIdle)
$synchash.Refresh_LocalMedia_timer.add_Tick({
    param([Parameter(Mandatory)][Object]$sender,[Parameter(Mandatory)][System.EventArgs]$e)
    try{  
      $AllMedia_Profile_Directory_Path = [System.IO.Path]::Combine($thisApp.Config.Media_Profile_Directory,"All-MediaProfile")
      $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($AllMedia_Profile_Directory_Path,"All-Media-Profile.xml")
      if($this.tag -eq 'Refresh_LocalMedia_Button'){
        $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
        $Button_Settings.AffirmativeButtonText = 'Yes'
        $Button_Settings.NegativeButtonText = 'No'
        $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
        $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Refresh Local Media Library","This will reimport all of your Local Media as configured under the Local Media tab in Settings. This can take a few minutes depending on the number of media to process.`n`nAre you sure you wish to continue?",$okandCancel,$Button_Settings)
        if($result -eq 'Affirmative'){
          write-ezlogs ">>>> User wished to refresh the Local Media Library" -showtime
          $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-MediaProfile','All-Media-Profile.xml')
          if([System.IO.File]::Exists($AllMedia_Profile_File_Path)){
            write-ezlogs " Removing All LocalMedia profile cache at $AllMedia_Profile_File_Path" -showtime
            [Void][System.IO.File]::Delete($AllMedia_Profile_File_Path)
          }
          $Count = $synchash.All_local_Media.count
          $synchash.All_local_Media = $Null
          $synchash.All_local_Media = [System.Collections.Generic.List[object]]::new($Count)
        }else{
          write-ezlogs "User did not wish to refresh the Local Media Library" -showtime -warning
          $this.tag = $null
          $this.stop()
          return
        }
      }elseif($this.tag -in 'QuickRefresh_LocalMedia_Button','WatcherLocalRefresh','WatcherLocalRefresh_RefreshOnly'){
        if($synchash.Mediatable.itemssource -and ($synchash.ProfileManager_Queue.IsEmpty -or !$synchash.ProfileManager_Queue)){
          write-ezlogs ">>>> Manually refreshing Mediatable itemssource"
          if($this.tag -in 'WatcherLocalRefresh_RefreshOnly' -and $synchash.Mediatable.Itemssource){
            $synchash.Mediatable.Itemssource.Refresh()
          }else{
            if(!$synchash.MediaTable.Itemssource.isInDeferRefresh){
              if($synchash.Mediatable.View){
                $synchash.Mediatable.View.BeginInit()
              }
              Use-Object ($synchash.MediaTable.Itemssource.DeferRefresh()){
                if($syncHash.MediaTable.Itemssource -is [System.IDisposable]){
                  write-ezlogs "| Disposing existing MediaTable.Itemssource"
                  $syncHash.MediaTable.Itemssource = $Null
                }
                [Void][System.Windows.Data.BindingOperations]::ClearBinding($syncHash.MediaTable,[Syncfusion.UI.Xaml.Grid.SfDataGrid]::ItemsSourceProperty)
                #$syncHash.MediaTable.Itemssource = $Null
                #$synchash.LocalMedia_View = $Null
                if($synchash.All_local_Media.count -gt 0){
                  write-ezlogs "| Creating GridVirtualizingCollectionView for All_local_Media and binding to Mediatable itemssource"
                  #$synchash.LocalMedia_View = [System.WeakReference]::new([Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new($synchash.All_local_Media))
                  $syncHash.MediaTable.Itemssource = [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new($synchash.All_local_Media)
                  if($syncHash.MediaTable.Itemssource.SourceCollection.Capacity){
                    $syncHash.MediaTable.Itemssource.SourceCollection.Capacity = $synchash.All_local_Media.count
                  }
                }else{
                  write-ezlogs "| All_local_Media is empty - creating blank collectionview" -warning
                  #$synchash.LocalMedia_View = [System.WeakReference]::new([Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new())
                  $syncHash.MediaTable.Itemssource = [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new()
                }          
                $syncHash.MediaTable.Itemssource.UsePLINQ = $true
                #$synchash.LocalMedia_View.Target.UsePLINQ = $true
                # Create a binding to pair the datagrid to the observable collection
                #$MediaTableBinding = [System.Windows.Data.Binding]::new()
                #$MediaTableBinding.Source = $synchash.LocalMedia_View.Target
                #$MediaTableBinding.Mode = [System.Windows.Data.BindingMode]::OneWay
                #[void][System.Windows.Data.BindingOperations]::SetBinding($syncHash.MediaTable,[Syncfusion.UI.Xaml.Grid.SfDataGrid]::ItemsSourceProperty, $MediaTableBinding)
                if($this.tag -in 'QuickRefresh_LocalMedia_Button'){
                  $synchash.Mediatable.ClearFilters()
                }elseif($synchash.MediaTable.View){
                  $synchash.MediaTable.View.Filter = {
                    param ($item) 
                    if(-not [string]::IsNullOrEmpty($synchash.FilterTextBox.Text)){
                      $text = $(($synchash.FilterTextBox.Text).tolower()).trim()
                    }
                    $($item.Title) -match $([regex]::Escape($Text)) -or $($item.Display_Name) -match $([regex]::Escape($Text))-or $($item.Artist) -match $([regex]::Escape($Text)) -or $($item.Album) -match $([regex]::Escape($Text))           
                  } 
                }
              }
              $synchash.Mediatable.Itemssource.Refresh()
              if($synchash.Mediatable.View){
                $synchash.Mediatable.View.EndInit()
              }
            }
          }
          #Apply user groupings
          if($thisApp.Config.Local_Group_By){
            try{   
              $Groups = $thisApp.Config.Local_Group_By
              if($syncHash.MediaTable.GroupColumnDescriptions){
                [Void]$syncHash.MediaTable.GroupColumnDescriptions.clear()
                $Groups | & { process {
                    if($_ -and $syncHash.MediaTable.GroupColumnDescriptions.ColumnName -notcontains $_){
                      write-ezlogs " | Adding groupdescription to LocalMedia_View for property: $($_)" -logtype LocalMedia -LogLevel 2
                      $groupdescription = [Syncfusion.UI.Xaml.Grid.GroupColumnDescription]::new()
                      $groupdescription.ColumnName = $_
                      [Void]$syncHash.MediaTable.GroupColumnDescriptions.Add($groupdescription)
                    }
                }} 
              }             
            }catch{
              write-ezlogs "An exception occurred attempting to set group descriptions" -showtime -catcherror $_
            }              
          }
          [Void][System.Windows.Data.BindingOperations]::ClearAllBindings($synchash.Media_Table_Total_Media)
          $synchash.Mediatable.Itemssource.Refresh()
          $Binding = [System.Windows.Data.Binding]::new('Count')
          $Binding.Source = $syncHash.MediaTable.ItemsSource
          $Binding.Mode = [System.Windows.Data.BindingMode]::OneTime
          [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.Media_Table_Total_Media,[System.Windows.Controls.TextBox]::TextProperty, $Binding)
          Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'Media_Table_Total_Media' -Property 'Text' -value $syncHash.MediaTable.ItemsSource.count
          Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'LocalMedia_RefreshProgress_Ring' -Property 'isActive' -value $false
          Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'MediaTable_RefreshLabel' -Property 'Visibility' -value 'Collapsed'         
          Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'Refresh_LocalMedia_Button' -Property 'isEnabled' -value $true                 
        }
        $this.tag = $null
        $this.stop()
        return
      }elseif($this.tag -eq 'Update-LocalMedia'){
        if($synchash.Mediatable.itemssource){
          write-ezlogs ">>>> Manually refreshing Mediatable itemssource"
          $synchash.Mediatable.BeginInit()
          #$synchash.Mediatable.ClearFilters() 
          if($synchash.Mediatable.Itemssource -is [System.IDisposable]){
            write-ezlogs "| Disposing Mediatable.Itemssource"
            $synchash.Mediatable.Itemssource = $Null
          }
          if($synchash.All_local_Media){
            write-ezlogs "| Creating new GridVirtualizingCollectionView for $($synchash.All_local_Media.count) items"
            $synchash.Mediatable.Itemssource = [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new($synchash.All_local_Media)
            if($syncHash.MediaTable.Itemssource.SourceCollection.Capacity){
              $syncHash.MediaTable.Itemssource.SourceCollection.Capacity = $synchash.All_local_Media.count
            }
          }else{
            write-ezlogs "| Creating new GridVirtualizingCollectionView" 
            $synchash.Mediatable.Itemssource = [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new()
          }         
          $synchash.Mediatable.Itemssource.UsePLINQ = $true
          write-ezlogs "| Binding GridVirtualizingCollectionView to MediaTable itemssource"         
          # Create a binding to pair the datagrid to the observable collection
          <#          $MediaTableBinding = [System.Windows.Data.Binding]::new()
              $MediaTableBinding.Source = $synchash.LocalMedia_View.Target
              $MediaTableBinding.Mode = [System.Windows.Data.BindingMode]::OneWay
          [void][System.Windows.Data.BindingOperations]::SetBinding($syncHash.MediaTable,[Syncfusion.UI.Xaml.Grid.SfDataGrid]::ItemsSourceProperty, $MediaTableBinding)#>
          #$synchash.Mediatable.Itemssource = $synchash.LocalMedia_View
          $synchash.Mediatable.Itemssource.Refresh()
          #Apply user groupings
          if($thisApp.Config.Local_Group_By){
            try{   
              $Groups = $thisApp.Config.Local_Group_By
              if($syncHash.MediaTable.GroupColumnDescriptions -is [Syncfusion.UI.Xaml.Grid.GroupColumnDescriptions]){
                [Void]$syncHash.MediaTable.GroupColumnDescriptions.clear()
                $Groups | & { process {
                    if($_ -and $syncHash.MediaTable.GroupColumnDescriptions.ColumnName -notcontains $_){
                      write-ezlogs " | Adding groupdescription to LocalMedia_View for property: $($_)" -logtype LocalMedia -LogLevel 2
                      $groupdescription = [Syncfusion.UI.Xaml.Grid.GroupColumnDescription]::new()
                      $groupdescription.ColumnName = $_
                      [Void]$syncHash.MediaTable.GroupColumnDescriptions.Add($groupdescription)
                    }
                }}
              }              
            }catch{
              write-ezlogs "An exception occurred attempting to set group descriptions" -showtime -catcherror $_
            }              
          }
          $synchash.Mediatable.EndInit()
          $synchash.MediaTable.isEnabled = $true
        }
        if($synchash.LocalMedia_Progress_Ring){
          $synchash.LocalMedia_Progress_Ring.isActive = $false        
        }                                  
        if($synchash.LocalMedia_Progress_Label){
          $synchash.LocalMedia_Progress_Label.Visibility = 'Hidden'
        }
        if($synchash.LocalMedia_Progress2_Label){
          $synchash.LocalMedia_Progress2_Label.Visibility = 'Hidden'
        }
        if($synchash.Refresh_LocalMedia_Button){
          $synchash.Refresh_LocalMedia_Button.isEnabled = $true
        } 
        if($synchash.LocalMedia_RefreshProgress_Ring){
          $synchash.LocalMedia_RefreshProgress_Ring.isActive = $false
          $synchash.MediaTable_RefreshLabel.Visibility = 'Collapsed'
        } 
        $this.tag = $null
        $this.stop()
        return
      }
      if($this.tag -eq 'Import'){
        $import = $true
        $skipGetMedia = $true
        $ClearTable = $true
        $AddNewOnly = $false
      }elseif($this.tag -eq 'AddNewOnly'){
        $AddNewOnly = $true
        $ClearTable = $false
        $import = $false
        $skipGetMedia = $false
      }else{
        $AddNewOnly = $false
        $import = $false
        $ClearTable = $true
        $skipGetMedia = $false
      }
      if($ClearTable){
        if($synchash.MediaTable.Itemssource -is [System.IDisposable]){
          $synchash.MediaTable.Itemssource = $Null
        }
        $synchash.Media_Table_Total_Media.text = ''
      }
      $synchash.LocalMedia_Progress_Ring.isActive = $true
      $synchash.MediaTable.isEnabled = $false
      Import-Media -Media_directories $thisapp.config.Media_Directories -use_runspace -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -startup:$import -thisApp $thisapp -Refresh_All_Media -NoMediaLibrary:$NoMediaLibrary -SkipGetMedia:$skipGetMedia -AddNewOnly:$AddNewOnly   
    }catch{
      write-ezlogs 'An exception occurred in Refresh_LocalMedia_Button.Add_Click' -showtime -catcherror $_
    }finally{
      $this.stop()
      $this.tag = $Null
    }
})
#---------------------------------------------- 
#endregion Refresh Local Media Button
#----------------------------------------------
if($import_media_measure){
  $import_media_measure.stop()
  write-ezlogs "Import-Media Startup" -PerfTimer $import_media_measure
  $import_media_measure = $Null
}
#---------------------------------------------- 
#region Import-Spotify
#----------------------------------------------
if($thisApp.Config.Startup_perf_timer){
  $import_Spotify_measure = [system.diagnostics.stopwatch]::StartNew()
}
#region Spotify_Startup_Timers
$synchash.SpotifyMedia_TableStartup_timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.SpotifyMedia_TableStartup_timer.add_Tick({
    try{
      $SpotifyMedia_Startup_measure = [system.diagnostics.stopwatch]::StartNew()
      #Default Library Columns
      if([string]::IsNullOrEmpty($thisApp.Config.SpotifyMedia_Library_Columns)){
        $thisApp.Config.SpotifyMedia_Library_Columns = 'Display_Name','Title','Artist','Album','Playlist'
      }
      if($thisApp.Config.SpotifyBrowser_Paging -ne $Null){
        $synchash.SpotifyFilter_Handler = $Null
      }
      if($synchash.SpotifyTable){
        if($thisApp.Config.Dev_mode){
          $synchash.SpotifyTable.add_Loaded({
              try{
                $sender = ($args[0])
                $e = ($args[1])            
                write-ezlogs "##### SpotifyTable Loaded event: $($e | out-string)" -Dev_mode             
              }catch{
                write-ezlogs "An exception occurred in SpotifyTable.add_Loaded" -catcherror $_
              }
          })
        }
        $synchash.SpotifyTable.add_PreviewDragOver({
            try{
              $sender = ($args[0])
              $e = ($args[1])
              if ($e.Data.GetDataPresent("ListViewRecords")){ 
                $draggingRecords = $e.Data.GetData("ListViewRecords") -as [System.Collections.ObjectModel.ObservableCollection[object]]  
              }else{ 
                $draggingRecords = $e.Data.GetData("Records") -as [System.Collections.ObjectModel.ObservableCollection[object]] 
              }
              if($draggingRecords -eq $null){
                return  
              }         
              $e.Handled = $true; 
            }catch{
              write-ezlogs "An exception occurred in SpotifyTable.add_PreviewDragOver" -catcherror $_
            }
        })
        if(!$NoMediaLibrary){
          #$synchash.SpotifyTable.SetValue([Syncfusion.UI.Xaml.Grid.BusyDecorator]::BackgroundProperty,[System.Windows.Media.Brush]'#00FF0000')
          #$synchash.SpotifyTable.SetValue([Syncfusion.UI.Xaml.Grid.ProgressRing]::ForegroundProperty,[System.Windows.Media.SolidColorBrush]::new($thisapp.config.Current_Theme.PrimaryAccentColor.ToString()))
          [Void]$synchash.SpotifyTable.RemoveHandler([System.Windows.Controls.Button]::PreviewMouseDoubleClickEvent,$synchash.PlayMedia_Command)
          [Void]$synchash.SpotifyTable.AddHandler([System.Windows.Controls.Button]::PreviewMouseDoubleClickEvent,$synchash.PlayMedia_Command)
          if($synchash.SpotifyTable.Columns.HeaderText -contains 'Play'){ 
            $synchash.SpotifyTable.columns| & { process {
                if($_.Headertext -eq 'Play'){
                  if($thisApp.Config.Dev_mode){write-ezlogs " | Adding SpotifyTable play button" -showtime -Dev_mode}
                  $StackPanelFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.VirtualizingStackPanel])
                  [Void]$StackPanelFactory.SetValue([System.Windows.Controls.VirtualizingStackPanel]::OrientationProperty, ([System.Windows.Controls.Orientation]::Horizontal))
                  [Void]$StackPanelFactory.SetValue([System.Windows.Controls.VirtualizingStackPanel]::IsVirtualizingProperty, $true)
                  [Void]$StackPanelFactory.SetValue([System.Windows.Controls.VirtualizingStackPanel]::VirtualizationModeProperty, [System.Windows.Controls.VirtualizationMode]::Recycling)
                  $buttonFactory = [System.Windows.FrameworkElementFactory]::new([Windows.Controls.Primitives.ToggleButton])
                  $buttonFactory.Name = 'Spotifytable_Playbutton'
                  $Binding = [System.Windows.Data.Binding]::new("Value")
                  [Void]$buttonFactory.SetBinding([Windows.Controls.Primitives.ToggleButton]::TagProperty,$Binding)
                  [Void]$buttonFactory.SetValue([Windows.Controls.Primitives.ToggleButton]::BackgroundProperty, $synchash.Window.TryFindResource('TransparentBackgroundStyle'))
                  [Void]$buttonFactory.SetValue([Windows.Controls.Primitives.ToggleButton]::StyleProperty, $synchash.Window.TryFindResource('PlayGridButtonStyle') )
                  if($thisApp.Config.Dev_mode){write-ezlogs " | Setting SpotifyTable Play button click event" -showtime -logtype Spotify -Dev_mode}
                  [Void]$buttonFactory.RemoveHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.PlayMedia_Command)
                  [Void]$buttonFactory.AddHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.PlayMedia_Command)
                  [Void]$StackPanelFactory.AppendChild($buttonFactory)
                  $dataTemplate = [System.Windows.DataTemplate]::new()
                  $dataTemplate.VisualTree = $StackPanelFactory
                  $_.CellTemplate = $dataTemplate
                }elseif($_.Headertext -in 'Display Name','Title','Artist','Album','Track'){                  
                  $GridFactory = [System.Windows.FrameworkElementFactory]::new([Windows.Controls.Grid])
                  $TextBlockFactory = [System.Windows.FrameworkElementFactory]::new([Windows.Controls.TextBlock])
                  $Binding = [System.Windows.Data.Binding]::new("Value")
                  [Void]$TextBlockFactory.SetBinding([Windows.Controls.TextBlock]::TextProperty,$Binding)
                  [Void]$TextBlockFactory.SetValue([Windows.Controls.Button]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)
                  $buttonFactory = [System.Windows.FrameworkElementFactory]::new([Windows.Controls.Button])
                  $buttonFactory.Name = 'Spotifytable_EditbuttonFactory'
                  [Void]$buttonFactory.SetValue([Windows.Controls.Button]::NameProperty, 'Spotifytable_Editbutton')
                  [Void]$buttonFactory.RemoveHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.EditCell_Command)
                  [Void]$buttonFactory.AddHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.EditCell_Command)
                  [Void]$buttonFactory.SetValue([Windows.Controls.Button]::BackgroundProperty, $synchash.Window.TryFindResource('TransparentBackgroundStyle'))
                  [Void]$buttonFactory.SetValue([Windows.Controls.Button]::StyleProperty, $synchash.Window.TryFindResource('EditButtonStyle'))
                  [Void]$buttonFactory.SetValue([Windows.Controls.Button]::TagProperty, $_.MappingName)
                  [Void]$GridFactory.AppendChild($TextBlockFactory)
                  [Void]$GridFactory.AppendChild($buttonFactory)
                  $dataTemplate = [System.Windows.DataTemplate]::new()
                  $dataTemplate.VisualTree = $GridFactory
                  $_.CellTemplate = $dataTemplate              
                  if($_.Headertext -notin $thisApp.Config.SpotifyMedia_Library_Columns){
                    $_.isHidden = $true
                  } 
                }elseif($_.Headertext -notin $thisApp.Config.SpotifyMedia_Library_Columns){
                  $_.isHidden = $true                
                }
            }}
          }else{
            [Void]$syncHash.SpotifyTable.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.PlayMedia_Command)
            [Void]$syncHash.SpotifyTable.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.PlayMedia_Command)
          } 

          if($synchash.SpotifyMedia_Column_Button){
            $synchash.SpotifyMedia_Column_Button.add_Loaded({
                try{
                  $synchash.SpotifyMedia_Column_Button.items.clear()
                  $synchash.SpotifyTable.Columns | & { process {
                      $Header = $_.Headertext
                      if($Header -notin 'Play' -and $synchash.SpotifyMedia_Column_Button.items -notcontains $Header){
                        $MenuItem = [System.Windows.Controls.MenuItem]::new()
                        $MenuItem.IsCheckable = $true     
                        $MenuItem.Header = $Header
                        if($_.isHidden){      
                          $MenuItem.IsChecked = $false                 
                        }else{
                          $MenuItem.IsChecked = $true
                        }
                        $MenuItem.Add_Checked({
                            try{
                              $Column = Get-IndexesOf $synchash.Spotifytable.Columns.HeaderText -Value $this.Header | & { process {
                                  $synchash.Spotifytable.Columns[$_]
                              }}
                              if($Column){
                                write-ezlogs ">>>> UnHiding column: $($Column.HeaderText)"
                                $Column.isHidden = $false
                              }
                              $ActiveColumns = Get-IndexesOf $synchash.Spotifytable.Columns.isHidden -Value $false | & { process {
                                  $c = $synchash.Spotifytable.Columns[$_]
                                  if($c -notin 'Play'){
                                    $c.HeaderText
                                  }
                              }}
                              $thisApp.Config.SpotifyMedia_Library_Columns = $ActiveColumns
                            }catch{
                              write-ezlogs "An exception occurred in add_checked for menuitem: $($this.Header)" -catcherror $_
                            }
                        })
                        $MenuItem.Add_UnChecked({
                            try{
                              $Column = Get-IndexesOf $synchash.Spotifytable.Columns.HeaderText -Value $this.Header | & { process {
                                  $synchash.Spotifytable.Columns[$_]
                              }}
                              if($Column){
                                write-ezlogs ">>>> Hiding column: $($Column.HeaderText)"
                                $Column.isHidden = $true
                              }
                              $ActiveColumns = Get-IndexesOf $synchash.Spotifytable.Columns.isHidden -Value $false | & { process {
                                  $c = $synchash.Spotifytable.Columns[$_]
                                  if($c -notin 'Play'){
                                    $c.HeaderText
                                  }
                              }}
                              $thisApp.Config.SpotifyMedia_Library_Columns = $ActiveColumns
                            }catch{
                              write-ezlogs "An exception occurred in add_Unchecked for menuitem: $($this.Header)" -catcherror $_
                            }
                        })                                                    
                        [Void]$synchash.SpotifyMedia_Column_Button.items.add($MenuItem)
                      }                    
                  }}
                }catch{
                  write-ezlogs "An exception occurred in SpotifyMedia_ColumnComboBox.add_Loaded" -catcherror $_
                }
            })
          }
          if($synchash.Media_ContextMenu){
            [Void]$synchash.SpotifyTable.RemoveHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
            [Void]$synchash.SpotifyTable.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
          }
          if($syncHash.SpotifyTable -and $synchash.All_Spotify_Media.count -gt 0){
            try{
              write-ezlogs ">>>> Creating GridVirtualizingCollectionView for All_Spotify_Media and binding to SpotifyTable itemssource" -showtime -loglevel 2 -logtype Spotify
              $syncHash.SpotifyTable.BeginInit()
              $syncHash.SpotifyTable.Itemssource = [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new($synchash.All_Spotify_Media)
              if($syncHash.SpotifyTable.Itemssource.SourceCollection.Capacity){
                $syncHash.SpotifyTable.Itemssource.SourceCollection.Capacity = $synchash.All_Spotify_Media.count
              }
              $syncHash.SpotifyTable.Itemssource.UsePLINQ = $true
              $synchash.SpotifyTable.EndInit()
              $Binding = [System.Windows.Data.Binding]::new('Count')
              $Binding.Source = $syncHash.SpotifyTable.ItemsSource.records.View
              $Binding.Mode = [System.Windows.Data.BindingMode]::OneTime
              [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.Spotify_Table_Total_Media,[System.Windows.Controls.TextBlock]::TextProperty, $Binding)
              if($syncHash.SpotifyTable.ItemsSource){
                $syncHash.Spotifytable.isEnabled = $true
              }
              #TODO: Temporary to cleanup issue from old configs
              if($thisApp.Config.Spotify_Group_By -eq 'Syncfusion.UI.Xaml.Grid.GroupColumnDescription'){
                $Groups = 'Playlist'
              }else{
                $Groups = $thisApp.Config.Spotify_Group_By
              }            
              if($syncHash.SpotifyTable.GroupColumnDescriptions  -is [Syncfusion.UI.Xaml.Grid.GroupColumnDescriptions]){
                [Void]$syncHash.SpotifyTable.GroupColumnDescriptions.clear()
                if(($syncHash.SpotifyTable.ItemsSource) -and $Groups){                  
                  $Groups | & { process {
                      if($_ -and $syncHash.SpotifyTable.GroupColumnDescriptions.ColumnName -notcontains $_){
                        write-ezlogs " | Adding groupdescription to SpotifyMedia_View for property: $($_)" -logtype Spotify -LogLevel 2
                        $groupdescription = [Syncfusion.UI.Xaml.Grid.GroupColumnDescription]::new()
                        $groupdescription.ColumnName = $_
                        [Void]$syncHash.SpotifyTable.GroupColumnDescriptions.Add($groupdescription);
                      }
                  }}                           
                }
              }                              
            }catch{
              write-ezlogs "An exception occurred in syncHash.SpotifyTable.add_Loaded" -catcherror $_
            }
            #---------------------------------------------- 
            #region Spotify Monitor
            #----------------------------------------------
            if($thisapp.Config.Spotify_update -and $thisapp.Config.Spotify_Update_Interval -eq 'On Startup' -and $this.tag -eq 'Startup'){
              write-ezlogs ">>>> Executing Get-SpotifyStatus" -logtype Spotify
              Get-SpotifyStatus -thisApp $thisApp -synchash $synchash -Use_runspace
            }elseif($thisapp.config.Spotify_Update -and -not [string]::IsNullOrEmpty($thisapp.config.Spotify_Update_Interval) -and $thisapp.config.Spotify_Update_Interval -ne 'On Startup' -and $this.tag -eq 'Startup'){
              try{
                Start-SpotifyMonitor -Interval $thisapp.config.Spotify_Update_Interval -thisApp $thisapp -synchash $synchash -Verboselog
              }catch{
                write-ezlogs 'An exception occurred in Start-SpotifyMonitor' -showtime -catcherror $_
              }
            }
            #---------------------------------------------- 
            #endregion Spotify Monitor
            #---------------------------------------------- 
          }                              
          $synchash.Spotify_Table_Total_Media.Text = "$($syncHash.SpotifyTable.ItemsSource.Count)" 
        }
        $Controls_to_Update = [System.Collections.Generic.List[object]]::new(5)
        $newRow = [PSCustomObject]::new(@{
            'Control' = 'SpotifyMedia_Progress_Ring'
            'Property' = 'isActive'
            'Value' = $false
        })          
        [Void]$Controls_to_Update.Add($newRow)
        $newRow = [PSCustomObject]::new(@{
            'Control' =  'SpotifyMedia_Progress_Label'
            'Property' = 'Visibility'
            'Value' =  'Hidden'
        })     
        [Void]$Controls_to_Update.Add($newRow)
        $newRow = [PSCustomObject]::new(@{
            'Control' = 'SpotifyMedia_Progress2_Label'
            'Property' = 'Visibility'
            'Value' = 'Hidden'
        })          
        [Void]$Controls_to_Update.Add($newRow)
        $newRow = [PSCustomObject]::new(@{
            'Control' =  'SpotifyTable'
            'Property' = 'isEnabled'
            'Value' =  $true
        })            
        [Void]$Controls_to_Update.Add($newRow)
        $newRow = [PSCustomObject]::new(@{
            'Control' =  'SpotifyTable'
            'Property' = 'Visibility'
            'Value' =  'Visible'
        })
        [Void]$Controls_to_Update.Add($newRow)
        Update-MainWindow -synchash $synchash -thisApp $thisApp -controls $Controls_to_Update
      }else{
        write-ezlogs "No SpotifyTable UI is available" -warning
      }        
    }catch{      
      write-ezlogs "An exception occurred attempting to set itemsource for SpotifyTable" -showtime -catcherror $_
    }finally{
      $this.Stop()
      if($SpotifyMedia_Startup_measure){
        $SpotifyMedia_Startup_measure.stop()
        write-ezlogs "Total SpotifyMedia_Startup" -PerfTimer $SpotifyMedia_Startup_measure -Perf #-GetMemoryUsage -forceCollection
      }
    }    
}) 
#endregion Spotify_Startup_Timers
try{
  if($thisapp.Config.Import_Spotify_Media){ 
    Update-SplashScreen -hash $hash -SplashMessage 'Importing Spotify Media'
    Import-Module -Name "$Current_Folder\Modules\Import-Spotify\Import-Spotify.psm1" -NoClobber -DisableNameChecking -Scope Local
    Import-Spotify -Media_directories $thisapp.config.Media_Directories -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -startup -thisApp $thisapp -NoMediaLibrary:$NoMediaLibrary -Import_Cache_Profile -RestrictedRunspace
  }elseif($synchash.Window -and $syncHash.MainGrid_Bottom_TabControl){
    write-ezlogs 'Importing of Spotify Media is not enabled' -showtime -Warning -logtype Spotify
    if($syncHash.SpotifyTable){
      $syncHash.SpotifyTable.isEnabled = $false
    }
    if($syncHash.Spotify_Tabitem){
      $syncHash.Spotify_Tabitem.isEnabled = $false
    }
    if($syncHash.MainGrid_Bottom_TabControl.items -contains $syncHash.Spotify_Tabitem){
      [Void]$syncHash.MainGrid_Bottom_TabControl.items.Remove($syncHash.Spotify_Tabitem) 
    }
  }   
}catch{
  write-ezlogs "An exception occurred Importing Spotify Media" -catcherror $_
}

#---------------------------------------------- 
#region Spotify Groups
#----------------------------------------------
if($syncHash.SpotifyTable){
  #Cell Editing
  $synchash.SpotifyTable.add_CurrentCellEndEdit($EndEditCurrentCellScripblock)
  #Library Grouping
  $syncHash.SpotifyTable.GroupColumnDescriptions.add_CollectionChanged({
      try{
        $Groups = $args[0]
        $e = $args[1]
        if($thisApp.Config.Dev_mode){write-ezlogs ">>>> SpotifyMedia GroupDescriptions Changed -- Action: $($e.action) - NewItems: $($e.newItems.ColumnName) - OldItems: $($e.OldItems.ColumnName) - OldStartingIndex: $($e.OldStartingIndex) - NewStartingIndex: $($e.NewStartingIndex)" -Dev_mode}
        if($e.action -eq 'Add' -and $e.newItems.ColumnName -notin $thisApp.Config.Spotify_Group_By){
          [Void]$thisApp.Config.Spotify_Group_By.add($e.newItems.ColumnName)
        }elseif($e.action -eq 'Remove' -and $e.OldItems.ColumnName -in $thisApp.Config.Spotify_Group_By){
          write-ezlogs ">>>> Removing group '$($e.OldItems.ColumnName)' from Spotify_Group_By"
          [Void]$thisApp.Config.Spotify_Group_By.Remove($e.OldItems.ColumnName)
        }
        if($thisApp.Config.SpotifyMedia_Library_CollapseAllGroups -and $e.action -eq 'Add'){
          try{
            $syncHash.SpotifyTable.AutoExpandGroups = $false           
            write-ezlogs ">>>> Collapsing all groups for SpotifyTable - Spotify_Group_By: $($thisApp.Config.Spotify_Group_By)"
            $synchash.SpotifyTable.CollapseAllGroup()
          }catch{
            write-ezlogs "An exception occurred calling SpotifyTable.CollapseAllGroup()" -catcherror $_
          }
        }                
      }catch{
        write-ezlogs "An exception occurred in SpotifyMedia_View.GroupDescriptions.add_CollectionChanged" -showtime -catcherror $_
      }
  })
}
if($synchash.SpotifyMediaCollapseGroups){
  $synchash.SpotifyMediaCollapseGroups.isChecked = $thisApp.Config.SpotifyMedia_Library_CollapseAllGroups                
  $synchash.SpotifyMediaCollapseGroups.Add_Checked({
      param($sender)
      try{
        if($synchash.SpotifyTable.GroupColumnDescriptions -is [Syncfusion.UI.Xaml.Grid.GroupColumnDescriptions]){
          write-ezlogs ">>>> Collapsing all groups for SpotifyTable"
          $syncHash.SpotifyTable.AutoExpandGroups = $false
          $synchash.SpotifyTable.CollapseAllGroup()
          $thisApp.Config.SpotifyMedia_Library_CollapseAllGroups = $true
        }else{
          write-ezlogs "No groups available to collapse for Spotifytable" -warning
          $sender.isChecked = $false
          $thisApp.Config.SpotifyMedia_Library_CollapseAllGroups = $false
        }       
      }catch{
        write-ezlogs "An exception occurred in SpotifyMediaCollapseGroups.Add_Checked" -catcherror $_
      }
  })
  $synchash.SpotifyMediaCollapseGroups.Add_UnChecked({
      param($sender)
      try{
        if($synchash.SpotifyTable.GroupColumnDescriptions -is [Syncfusion.UI.Xaml.Grid.GroupColumnDescriptions]){
          $syncHash.SpotifyTable.AutoExpandGroups = $true
          write-ezlogs ">>>> Expanding all groups for SpotifyTable"
          $synchash.SpotifyTable.ExpandAllGroup() 
        }else{
          write-ezlogs "No groups available to expand for Spotifytable" -warning
        } 
        $thisApp.Config.SpotifyMedia_Library_CollapseAllGroups = $false       
      }catch{
        write-ezlogs "An exception occurred in SpotifyMediaCollapseGroups.Add_Checked" -catcherror $_
      }
  })
}
#---------------------------------------------- 
#endregion Spotify Groups
#----------------------------------------------

#---------------------------------------------- 
#region Spotify Filters
#----------------------------------------------
if($synchash.SpotifyFilterTextBox){
  $synchash.SpotifyFilter_timer = [System.Windows.Threading.DispatcherTimer]::New([System.Windows.Threading.DispatcherPriority]::Background)
  $synchash.SpotifyFilter_timer.add_Tick({
      try{
        $SpotifyFilter_measure = [system.diagnostics.stopwatch]::StartNew()
        if($synchash.SpotifyTable.Itemssource -and !$synchash.SpotifyTable.Itemssource.IsInDeferRefresh){
          #$synchash.SpotifyTable.View.BeginInit()
          $synchash.SpotifyTable.View.Filter = {
            param ($item) 
            if(-not [string]::IsNullOrEmpty($synchash.SpotifyFilterTextBox.Text)){
              $text = $(($synchash.SpotifyFilterTextBox.Text).tolower()).trim()
            }
            $SearchPattern = "$([regex]::Escape($Text))"
            $($item.Title) -match $SearchPattern -or $($item.Display_Name) -match $SearchPattern -or $($item.Artist) -match $SearchPattern -or $($item.Album) -match $SearchPattern -or $($item.Playlist) -match $SearchPattern       
          }
          #$synchash.SpotifyTable.View.EndInit()
          if($synchash.SpotifyTable.View){
            $synchash.SpotifyTable.View.RefreshFilter()
          }
        }
      }catch{
        write-ezlogs "An exception occurred in SpotifyFilterTextBox.Add_TextChanged" -catcherror $_
      }finally{
        $this.stop()
        $SpotifyFilter_measure.Stop()
        write-ezlogs "SpotifyFilter_timer" -PerfTimer $SpotifyFilter_measure -Perf
      }
  })

  $synchash.SpotifyTable.add_FilterChanged({
      param($sender,[Syncfusion.UI.Xaml.Grid.GridFilterEventArgs]$e)
      try{
        $synchash.Spotify_Table_Total_Media.Text = "$($synchash.SpotifyTable.View.Records.Count)"
      }catch{
        write-ezlogs "An exception occurred in SpotifyFilterTextBox.Add_TextChanged" -catcherror $_
      }
  })
  $synchash.SpotifyFilterTextBox.Add_PreviewLostKeyboardFocus({
      try{
        $newFocus = $args[1].NewFocus
        if($newFocus -is [Syncfusion.UI.Xaml.Grid.SfDataGrid] -or $newFocus -is [Syncfusion.UI.Xaml.Grid.GridCell]){
          write-ezlogs "[SpotifyFilterTextBox] Preventing new focus from: $($newFocus)" -warning
          $args[1].Handled = $true
        }       
      }catch{
        write-ezlogs "An exception occurrred in SpotifyFilterTextBox Add_PreviewLostKeyboardFocus event" -showtime -catcherror $_
      }
  })

  $synchash.SpotifyFilterTextBox.Add_TextChanged({
      try{
        if(!$synchash.SpotifyFilter_timer.isEnabled){
          $synchash.SpotifyFilter_timer.start()
        }        
      }catch{
        write-ezlogs "An exception occurred in SpotifyFilterTextBox.Add_TextChanged" -catcherror $_
      }
  }) 
  if($synchash.SpotifySearch_Button){
    $synchash.SpotifySearch_Button.Add_Click({
        try{
          if(!$synchash.SpotifyFilter_timer.isEnabled){
            $synchash.SpotifyFilter_timer.start()
          }
        }catch{
          write-ezlogs "An exception occurred in SpotifySearch_Button" -showtime -catcherror $_
        }   
    }) 
    $synchash.SpotifyFilterTextBox.Add_PreviewKeyDown({
        param
        ([Parameter(Mandatory)][Object]$sender,[Parameter(Mandatory)][Windows.Input.KeyEventArgs]$e)
        try{
          if($e.Key -eq 'Enter' -and !$synchash.SpotifyFilter_timer.isEnabled){
            $synchash.SpotifyFilter_timer.start()
          }
        }catch{
          write-ezlogs "An exception occurred in SpotifyFilterTextBox.Add_PreviewKeyDown" -catcherror $_
        }
    })
  }
}
#---------------------------------------------- 
#endregion Spotify Filters
#----------------------------------------------
 
#---------------------------------------------- 
#endregion Import-Spotify
#----------------------------------------------

#---------------------------------------------- 
#region Spotify Actions Button
#----------------------------------------------
$synchash.Refresh_SpotifyMedia_timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.Refresh_SpotifyMedia_timer.add_Tick({
    try{  
      if($this.tag -in 'Refresh_SpotifyMedia_Button','Get-SpotifyStatus'){
        if($this.tag -eq 'Refresh_SpotifyMedia_Button'){
          $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
          $Button_Settings.AffirmativeButtonText = 'Yes'
          $Button_Settings.NegativeButtonText = 'No'  
          $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
          $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Refresh Spotify Media Library","This will reimport all of your Spotify tracks and playlists as configured under the Spotify tab in Settings. This can take a few minutes depending on the number of media to process.`n`nAre you sure you wish to continue?",$okandCancel,$Button_Settings)         
        }elseif($this.tag -eq 'Get-SpotifyStatus'){
          $result = 'Affirmative'
        }
        if($result -eq 'Affirmative'){
          write-ezlogs ">>>> User wished to refresh the Spotify Library" -showtime
          $synchash.SpotifyTable.Itemssource = $null
          if([system.io.file]::Exists("$($thisApp.Config.Media_Profile_Directory)\All-Spotify_MediaProfile\All-Spotify_Media-Profile.xml")){
            write-ezlogs ">>>> Removing existing Spotify Media Profile at: $($thisApp.Config.Media_Profile_Directory)\All-Spotify_MediaProfile\All-Spotify_Media-Profile.xml" -loglevel 2
            try{
              [Void][system.io.file]::Delete("$($thisApp.Config.Media_Profile_Directory)\All-Spotify_MediaProfile\All-Spotify_Media-Profile.xml")
            }catch{
              write-ezlogs "An exception occurred removing existing Spotify Media Profile at: $($thisApp.Config.Media_Profile_Directory)\All-Spotify_MediaProfile\All-Spotify_Media-Profile.xml" -catcherror $_
            }
          }
          $synchash.SpotifyTable.Itemssource = $null
          Import-Spotify -Media_directories $thisapp.config.Media_Directories -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -startup:$false -thisApp $thisapp
        }else{
          write-ezlogs "User did not wish to refresh the Spotify Library" -showtime -warning
          return
        }
      }elseif($this.tag -eq 'QuickRefresh_SpotifyMedia_Button'){
        if($synchash.Spotifytable.itemssource){
          write-ezlogs ">>>> Manually refreshing Spotifytable itemssource"
          $synchash.SpotifyTable.View.BeginInit()
          $synchash.SpotifyTable.ClearFilters()
          $synchash.SpotifyTable.Itemssource = [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new($synchash.All_Spotify_Media)
          if($synchash.SpotifyTable.Itemssource.SourceCollection.Capacity){
            $synchash.SpotifyTable.Itemssource.SourceCollection.Capacity = $synchash.All_Spotify_Media.count
          }
          $synchash.SpotifyTable.Itemssource.UsePLINQ = $true
          $synchash.SpotifyTable.Itemssource.Refresh() 
          $synchash.SpotifyTable.View.EndInit() 
          if($thisApp.Config.Import_Spotify_Media){
            Get-SpotifyStatus -thisApp $thisApp -synchash $synchash -Use_runspace
          }                  
          return
        }
      }
    }catch{
      write-ezlogs 'An exception occurred in Refresh_SpotifyMedia_Button.Add_Click' -showtime -catcherror $_
    }finally{
      $this.stop()
      $this.tag = $Null
    }
})

#SpotifyMedia Actions Button
if($synchash.SpotifyMedia_Actions_Button){
  $synchash.SpotifyMedia_Actions_Button.add_Loaded({
      try{
        $synchash.SpotifyMedia_Actions_Button.items.clear() 
        $Header = 'Quick Refresh'
        if($synchash.SpotifyMedia_Actions_Button.items -notcontains $Header){
          $synchash.QuickRefresh_SpotifyMedia_Button = [System.Windows.Controls.MenuItem]::new()
          $synchash.QuickRefresh_SpotifyMedia_Button.IsCheckable = $false    
          $synchash.QuickRefresh_SpotifyMedia_Button.Header = $Header 
          $synchash.QuickRefresh_SpotifyMedia_Button.ToolTip = 'Refreshes the library view with existing records'
          $synchash.QuickRefresh_SpotifyMedia_Button.Name = 'QuickRefresh_SpotifyMedia_Button'
          $menuItem_imagecontrol = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
          $menuItem_imagecontrol.width = "14"
          $menuItem_imagecontrol.Height = "14"
          $menuItem_imagecontrol.Kind = 'Refresh'        
          $synchash.QuickRefresh_SpotifyMedia_Button.Icon = $menuItem_imagecontrol
          $synchash.QuickRefresh_SpotifyMedia_Button.Add_Click({   
              try{  
                $synchash.Refresh_SpotifyMedia_timer.tag = 'QuickRefresh_SpotifyMedia_Button'  
                $synchash.Refresh_SpotifyMedia_timer.start()              
              }catch{
                write-ezlogs 'An exception occurred in QuickRefresh_SpotifyMedia_Button_menuitem.Add_Click' -showtime -catcherror $_
              }
          })                                               
          [Void]$synchash.SpotifyMedia_Actions_Button.items.add($synchash.QuickRefresh_SpotifyMedia_Button)
        }
        $Header = 'Rescan Library'
        if($synchash.SpotifyMedia_Actions_Button.items -notcontains $Header){
          $synchash.Refresh_SpotifyMedia_Button = [System.Windows.Controls.MenuItem]::new()
          $synchash.Refresh_SpotifyMedia_Button.IsCheckable = $false    
          $synchash.Refresh_SpotifyMedia_Button.Header = $Header
          $synchash.Refresh_SpotifyMedia_Button.ToolTip = 'Performs full rescan of media and rebuild of library'
          $synchash.Refresh_SpotifyMedia_Button.Name = 'Refresh_SpotifyMedia_Button'
          $menuItem_imagecontrol = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
          $menuItem_imagecontrol.width = "14"
          $menuItem_imagecontrol.Height = "14"
          $menuItem_imagecontrol.Kind = 'DatabaseRefreshOutline'        
          $synchash.Refresh_SpotifyMedia_Button.Icon = $menuItem_imagecontrol
          $synchash.Refresh_SpotifyMedia_Button.Add_Click({   
              try{  
                $synchash.Refresh_SpotifyMedia_timer.tag = 'Refresh_SpotifyMedia_Button'  
                $synchash.Refresh_SpotifyMedia_timer.start()           
              }catch{
                write-ezlogs 'An exception occurred in Refresh_SpotifyMedia_Button.Add_Click' -showtime -catcherror $_
              }
          })                                               
          [Void]$synchash.SpotifyMedia_Actions_Button.items.add($synchash.Refresh_SpotifyMedia_Button)
        }                     
      }catch{
        write-ezlogs "An exception occurred in SpotifyMedia_Actions_Button.add_Loaded" -catcherror $_
      }
  })
}
#---------------------------------------------- 
#endregion Spotify Actions Button
#----------------------------------------------
if($import_Spotify_measure){
  $import_Spotify_measure.stop()
  write-ezlogs "Import-Spotify Startup" -PerfTimer $import_Spotify_measure
  $import_Spotify_measure = $Null
}
#---------------------------------------------- 
#region Import-Youtube
#----------------------------------------------
if($thisApp.Config.Startup_perf_timer){
  $import_Youtube_measure = [system.diagnostics.stopwatch]::StartNew()
}
$synchash.YoutubeMedia_TableStartup_timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.YoutubeMedia_TableStartup_timer.add_Tick({
    try{
      if($thisApp.Config.YoutubeBrowser_Paging -ne $Null -and $synchash.YoutubeMedia_View.PageIndex -ne $Null){           
        $synchash.YoutubeFilter_Handler = $Null
      }
      if([string]::IsNullOrEmpty($thisApp.Config.YoutubeMedia_Library_Columns)){
        $thisapp.config.YoutubeMedia_Library_Columns = 'Display_Name','Title','Artist','Playlist'
      }
      if($synchash.YoutubeTable){
        [Void]$synchash.YoutubeTable.RemoveHandler([System.Windows.Controls.Button]::PreviewMouseDoubleClickEvent,$synchash.PlayMedia_Command)
        [Void]$synchash.YoutubeTable.AddHandler([System.Windows.Controls.Button]::PreviewMouseDoubleClickEvent,$synchash.PlayMedia_Command)
        $synchash.YoutubeTable.add_PreviewDragOver({
            Param([Parameter(Mandatory)]$sender,[Parameter(Mandatory)][Windows.DragEventArgs]$e)
            try{
              if ($e.Data.GetDataPresent("ListViewRecords")){ 
                $draggingRecords = $e.Data.GetData("ListViewRecords") -as [System.Collections.ObjectModel.ObservableCollection[object]]  
              }else{ 
                $draggingRecords = $e.Data.GetData("Records") -as [System.Collections.ObjectModel.ObservableCollection[object]] 
              }
              if($draggingRecords -eq $null){
                return  
              }
              $e.Handled = $true
            }catch{
              write-ezlogs "An exception occurred in YoutubeTable.add_PreviewDragOver" -catcherror $_
            }
        })
        if($synchash.YoutubeTable.Columns.HeaderText -contains 'Play'){        
          $synchash.YoutubeTable.columns| & { process {
              if($_.HeaderText -eq 'Play'){
                write-ezlogs " | Adding YoutubeTable play button" -showtime -logtype youtube -loglevel 3
                $StackPanelFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.VirtualizingStackPanel])
                [Void]$StackPanelFactory.SetValue([System.Windows.Controls.VirtualizingStackPanel]::OrientationProperty, ([System.Windows.Controls.Orientation]::Horizontal))
                [Void]$StackPanelFactory.SetValue([System.Windows.Controls.VirtualizingStackPanel]::IsVirtualizingProperty, $true)
                [Void]$StackPanelFactory.SetValue([System.Windows.Controls.VirtualizingStackPanel]::VirtualizationModeProperty, [System.Windows.Controls.VirtualizationMode]::Recycling)
                $buttonFactory = [System.Windows.FrameworkElementFactory]::new([Windows.Controls.Primitives.ToggleButton])
                $buttonFactory.Name = 'Youtubtable_Playbutton'
                $Binding = [System.Windows.Data.Binding]::new("Value")
                [Void]$buttonFactory.SetBinding([Windows.Controls.Primitives.ToggleButton]::TagProperty,$Binding)
                [Void]$buttonFactory.SetValue([Windows.Controls.Primitives.ToggleButton]::BackgroundProperty, $synchash.Window.TryFindResource('TransparentBackgroundStyle'))
                [Void]$buttonFactory.SetValue([Windows.Controls.Primitives.ToggleButton]::StyleProperty, $synchash.Window.TryFindResource('PlayGridButtonStyle') )
                write-ezlogs " | Setting YoutubeTable Play button click event" -showtime -logtype youtube -loglevel 3
                [Void]$buttonFactory.RemoveHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.PlayMedia_Command)
                [Void]$buttonFactory.AddHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.PlayMedia_Command)
                [Void]$StackPanelFactory.AppendChild($buttonFactory)
                $dataTemplate = [System.Windows.DataTemplate]::new()
                $dataTemplate.VisualTree = $StackPanelFactory
                $_.CellTemplate = $dataTemplate
              }elseif($_.Headertext -in 'Display Name','Title','Artist','Album','Track'){                  
                $GridFactory = [System.Windows.FrameworkElementFactory]::new([Windows.Controls.Grid])
                $TextBlockFactory = [System.Windows.FrameworkElementFactory]::new([Windows.Controls.TextBlock])
                $Binding = [System.Windows.Data.Binding]::new("Value")
                [Void]$TextBlockFactory.SetBinding([Windows.Controls.TextBlock]::TextProperty,$Binding)
                [Void]$TextBlockFactory.SetValue([Windows.Controls.Button]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)
                $buttonFactory = [System.Windows.FrameworkElementFactory]::new([Windows.Controls.Button])
                $buttonFactory.Name = 'Youtubetable_EditbuttonFactory'
                [Void]$buttonFactory.SetValue([Windows.Controls.Button]::NameProperty, 'Youtubetable_Editbutton')
                [Void]$buttonFactory.RemoveHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.EditCell_Command)
                [Void]$buttonFactory.AddHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.EditCell_Command)
                [Void]$buttonFactory.SetValue([Windows.Controls.Button]::BackgroundProperty, $synchash.Window.TryFindResource('TransparentBackgroundStyle'))
                [Void]$buttonFactory.SetValue([Windows.Controls.Button]::StyleProperty, $synchash.Window.TryFindResource('EditButtonStyle'))
                [Void]$buttonFactory.SetValue([Windows.Controls.Button]::TagProperty, $_.MappingName)
                [Void]$GridFactory.AppendChild($TextBlockFactory)
                [Void]$GridFactory.AppendChild($buttonFactory)
                $dataTemplate = [System.Windows.DataTemplate]::new()
                $dataTemplate.VisualTree = $GridFactory
                $_.CellTemplate = $dataTemplate
                if($_.Headertext -notin $thisApp.Config.YoutubeMedia_Library_Columns){
                  $_.isHidden = $true
                }                              
              }elseif($_.HeaderText -notin $thisApp.Config.YoutubeMedia_Library_Columns){
                $_.IsHidden = $true
              }
          }}
        }else{
          [Void]$syncHash.YoutubeTable.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.PlayMedia_Command)
          [Void]$syncHash.YoutubeTable.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.PlayMedia_Command)
        } 
        if($synchash.YoutubeMedia_Column_Button){
          $synchash.YoutubeMedia_Column_Button.add_Loaded({
              try{
                $synchash.YoutubeMedia_Column_Button.items.clear()
                $synchash.YoutubeTable.Columns | & { process {
                    $Header = $_.Headertext
                    if($Header -notin 'Play' -and $synchash.YoutubeMedia_Column_Button.items -notcontains $Header){
                      $MenuItem = [System.Windows.Controls.MenuItem]::new()
                      $MenuItem.IsCheckable = $true     
                      $MenuItem.Header = $Header
                      if($_.isHidden){      
                        $MenuItem.IsChecked = $false                 
                      }else{
                        $MenuItem.IsChecked = $true
                      }
                      $MenuItem.Add_Checked({
                          try{
                            $Column = Get-IndexesOf $synchash.Youtubetable.Columns.HeaderText -Value $this.Header | & { process {
                                $synchash.Youtubetable.Columns[$_]
                            }}
                            if($Column){
                              write-ezlogs ">>>> UnHiding column: $($Column.HeaderText)"
                              $Column.isHidden = $false
                            }
                            $ActiveColumns = Get-IndexesOf $synchash.Youtubetable.Columns.isHidden -Value $false | & { process {
                                $c = $synchash.Youtubetable.Columns[$_]
                                if($c -notin 'Play'){
                                  $c.HeaderText
                                }
                            }}
                            $thisApp.Config.YoutubeMedia_Library_Columns = $ActiveColumns
                          }catch{
                            write-ezlogs "An exception occurred in add_checked for menuitem: $($this.Header)" -catcherror $_
                          }
                      })
                      $MenuItem.Add_UnChecked({
                          try{
                            $Column = Get-IndexesOf $synchash.Youtubetable.Columns.HeaderText -Value $this.Header | & { process {
                                $synchash.Youtubetable.Columns[$_]
                            }}
                            if($Column){
                              write-ezlogs ">>>> Hiding column: $($Column.HeaderText)"
                              $Column.isHidden = $true
                            }
                            $ActiveColumns = Get-IndexesOf $synchash.Youtubetable.Columns.isHidden -Value $false | & { process {
                                $c = $synchash.Youtubetable.Columns[$_]
                                if($c -notin 'Play'){
                                  $c.HeaderText
                                }
                            }}
                            $thisApp.Config.YoutubeMedia_Library_Columns = $ActiveColumns
                          }catch{
                            write-ezlogs "An exception occurred in add_Unchecked for menuitem: $($this.Header)" -catcherror $_
                          }
                      })                                                    
                      [Void]$synchash.YoutubeMedia_Column_Button.items.add($MenuItem)
                    }                    
                }}
              }catch{
                write-ezlogs "An exception occurred in YoutubeMedia_ColumnComboBox.add_Loaded" -catcherror $_
              }
          })
        }
        if($synchash.YoutubeMedia_View.NeedsRefresh){
          $synchash.YoutubeMedia_View.refresh()
          write-ezlogs ">>>> Refreshing YoutubeMedia_View" -showtime -logtype youtube -loglevel 2
        }
        if($synchash.Media_ContextMenu){
          [Void]$synchash.YoutubeTable.RemoveHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
          [Void]$synchash.YoutubeTable.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
        }                   
        if($synchash.YoutubeMedia_View -ne $Null){
          try{
            write-ezlogs ">>>> Setting Youtube itemssource" -showtime -logtype youtube -loglevel 3   
            # Create a binding to pair the listbox to the observable collection
            $synchash.YoutubeMedia_ListLock = [PSCustomObject]::new()
            $MediaTableBinding = [System.Windows.Data.Binding]::new()
            #$MediaTableBinding.IsAsync = $true
            $MediaTableBinding.Source = $synchash.YoutubeMedia_View
            $MediaTableBinding.Mode = [System.Windows.Data.BindingMode]::OneTime
            [void][System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($synchash.YoutubeMedia_View,$synchash.YoutubeMedia_ListLock)
            [void][System.Windows.Data.BindingOperations]::SetBinding($syncHash.YoutubeTable,[Syncfusion.UI.Xaml.Grid.SfDataGrid]::ItemsSourceProperty, $MediaTableBinding)    
          }catch{
            write-ezlogs "An exception occurred binding Youtube itemssource" -catcherror $_
          }                                                                                  
        }
        $Controls_to_Update = [System.Collections.Generic.List[object]]::new(5) 
        $newRow = [PSCustomObject]::new(@{
            'Control' = 'Youtube_Progress_Ring'
            'Property' = 'isActive'
            'Value' = $false
        })             
        [Void]$Controls_to_Update.Add($newRow) 
        $newRow = [PSCustomObject]::new(@{
            'Control' =  'YoutubeMedia_Progress_Label'
            'Property' = 'Visibility'
            'Value' =  'Hidden'
        })         
        [Void]$Controls_to_Update.Add($newRow)
        $newRow = [PSCustomObject]::new(@{
            'Control' = 'YoutubeMedia_Progress2_Label'
            'Property' = 'Visibility'
            'Value' = 'Hidden'
        })             
        [Void]$Controls_to_Update.Add($newRow)
        $newRow = [PSCustomObject]::new(@{
            'Control' =  'YoutubeTable'
            'Property' = 'isEnabled'
            'Value' =  $true
        })             
        [Void]$Controls_to_Update.Add($newRow)
        $newRow = [PSCustomObject]::new(@{
            'Control' =  'YoutubeTable'
            'Property' = 'Visibility'
            'Value' =  'Visible'
        })
        [Void]$Controls_to_Update.Add($newRow)
        Update-MainWindow -synchash $synchash -thisApp $thisApp -controls $Controls_to_Update
        if($syncHash.YoutubeTable -and $synchash.YoutubeMedia_View){ 
          try{
            $synchash.Youtube_Table_Total_Media.Text = "$($syncHash.YoutubeTable.ItemsSource.Count)"                  
            if($thisApp.Config.Youtube_Group_By){        
              #TODO: Temporary to cleanup issue from old configs
              if($thisApp.Config.Youtube_Group_By -eq 'Syncfusion.UI.Xaml.Grid.GroupColumnDescription'){
                $Groups = 'Playlist'
              }else{
                $Groups = $thisApp.Config.Youtube_Group_By
              }
              if($syncHash.YoutubeTable.GroupColumnDescriptions -is [Syncfusion.UI.Xaml.Grid.GroupColumnDescriptions]){
                [Void]$syncHash.YoutubeTable.GroupColumnDescriptions.clear()
                $Groups | & { process {
                    write-ezlogs ">>>> Checking YoutubeMedia_View for group property: $($_)" -logtype youtube -LogLevel 2
                    if($_ -and $syncHash.YoutubeTable.GroupColumnDescriptions.ColumnName -notcontains $_){
                      write-ezlogs " | Adding groupdescription to YoutubeMedia_View for property: $($_)" -logtype youtube -LogLevel 2
                      $groupdescription = [Syncfusion.UI.Xaml.Grid.GroupColumnDescription]::new()
                      $groupdescription.ColumnName = $_
                      [Void]$syncHash.YoutubeTable.GroupColumnDescriptions.Add($groupdescription);
                    }
                }} 
              }                          
            }
            write-ezlogs ">>>> Refreshing Youtubetable ItemsSource - Total: $($syncHash.YoutubeTable.ItemsSource.Count)" -showtime -logtype youtube -loglevel 2
            $syncHash.YoutubeTable.ItemsSource.refresh()    
          }catch{
            write-ezlogs "An exception occurred setting YoutubeTable" -catcherror $_
          } 
          #---------------------------------------------- 
          #region Youtube Monitor
          #----------------------------------------------
          if($thisapp.Config.youtube_update -and $thisapp.Config.Youtube_Update_Interval -eq 'On Startup' -and $this.tag -eq 'Startup'){
            write-ezlogs ">>>> Executing Get-YoutubeStatus" -logtype youtube
            Get-YoutubeStatus -thisApp $thisApp -synchash $synchash -Use_runspace
          }elseif($thisapp.config.Youtube_Update -and -not [string]::IsNullOrEmpty($thisapp.config.Youtube_Update_Interval) -and $thisapp.config.Youtube_Update_Interval -ne 'On Startup' -and $this.tag -eq 'Startup'){
            try{
              Start-YoutubeMonitor -Interval $thisapp.config.Youtube_Update_Interval -thisApp $thisapp -synchash $synchash -Verboselog
            }catch{
              write-ezlogs 'An exception occurred in Start-YoutubeMonitor' -showtime -catcherror $_
            }
          }
          #---------------------------------------------- 
          #endregion Youtube Monitor
          #----------------------------------------------                      
        }                   
      }else{
        write-ezlogs "No YoutubeTable UI is available" -warning 
      } 
      $this.tag = $Null                                     
      $this.Stop()
    }catch{
      $this.Stop()
      write-ezlogs "An exception occurred attempting to set itemsource for YoutubeTable" -showtime -catcherror $_
    }finally{
      $this.tag = $Null
      $this.Stop()
    }    
})

#---------------------------------------------- 
#region Youtube Filters
#----------------------------------------------
if($synchash.YoutubeFilterTextBox){
  $synchash.YoutubeMediaFilter_timer = [System.Windows.Threading.DispatcherTimer]::New([System.Windows.Threading.DispatcherPriority]::Background)
  $synchash.YoutubeMediaFilter_timer.add_Tick({
      try{
        $YoutubeFilter_measure = [system.diagnostics.stopwatch]::StartNew()
        if($synchash.YoutubeTable.Itemssource -and !$synchash.YoutubeTable.Itemssource.IsInDeferRefresh){
          #$synchash.YoutubeTable.View.BeginInit()
          $synchash.YoutubeTable.View.Filter = {
            param ($item) 
            if(-not [string]::IsNullOrEmpty($synchash.YoutubeFilterTextBox.Text)){
              $text = $(($synchash.YoutubeFilterTextBox.Text).tolower()).trim()
            }
            $SearchPattern = "$([regex]::Escape($Text))"
            $($item.title) -match $SearchPattern -or $($item.Display_Name) -match $SearchPattern -or $($item.Artist) -match $SearchPattern -or $($item.Album) -match $SearchPattern -or $($item.Playlist) -match $SearchPattern                               
          }
          #$synchash.YoutubeTable.View.EndInit()
          if($synchash.YoutubeTable.View){
            $synchash.YoutubeTable.View.RefreshFilter()
          }
        }
      }catch{
        write-ezlogs "An exception occurred in YoutubeMediaFilter_timer" -catcherror $_
      }finally{
        $this.stop()
        $YoutubeFilter_measure.stop()
        write-ezlogs "YoutubeFilter_timer" -PerfTimer $YoutubeFilter_measure -Perf
      }
  })
  $synchash.YoutubeFilterTextBox.Add_TextChanged({
      try{
        if(!$synchash.YoutubeMediaFilter_timer.isEnabled){
          $synchash.YoutubeMediaFilter_timer.start()
        }  
      }catch{
        write-ezlogs "An exception occurred in YoutubeFilterTextBox.Add_TextChanged" -catcherror $_
      }      
  })  

  $synchash.YoutubeTable.add_FilterChanged({
      param($sender,[Syncfusion.UI.Xaml.Grid.GridFilterEventArgs]$e)
      try{
        $synchash.Youtube_Table_Total_Media.Text = "$($synchash.YoutubeTable.View.Records.Count)"
      }catch{
        write-ezlogs "An exception occurred in YoutubeFilterTextBox.Add_TextChanged" -catcherror $_
      }
  })

  $synchash.YoutubeFilterTextBox.Add_PreviewLostKeyboardFocus({
      try{
        $newFocus = $args[1].NewFocus
        if($newFocus -is [Syncfusion.UI.Xaml.Grid.SfDataGrid] -or $newFocus -is [Syncfusion.UI.Xaml.Grid.GridCell]){
          write-ezlogs "[YoutubeFilterTextBox] Preventing new focus from: $($newFocus)" -warning
          $args[1].Handled = $true
        }       
      }catch{
        write-ezlogs "An exception occurrred in YoutubeFilterTextBox Add_PreviewLostKeyboardFocus event" -showtime -catcherror $_
      }
  })

  if($synchash.YoutubeSearch_Button){
    $synchash.YoutubeSearch_Button.Add_Click({
        try{
          if(!$synchash.YoutubeMediaFilter_timer.isEnabled){
            $synchash.YoutubeMediaFilter_timer.start()
          }
        }catch{
          write-ezlogs "An exception occurred in YoutubeSearch_Button" -showtime -catcherror $_
        }   
    }) 
    $synchash.YoutubeFilterTextBox.Add_KeyDown({
        [System.Windows.Input.KeyEventArgs]$e = $args[1] 
        try{
          write-ezlogs "Youtubefiltertextbox $($e | out-string)"
          if($e.key -eq 'Return' -and !$synchash.YoutubeMediaFilter_timer.isEnabled){
            $synchash.YoutubeMediaFilter_timer.start()
          }  
        }catch{
          write-ezlogs 'An exception occurred inYoutubeFilterTextBox.Add_KeyDowt' -showtime -catcherror $_
        }    
    })
  }
}
#---------------------------------------------- 
#endregion Youtube Filters
#----------------------------------------------
if($thisapp.Config.Import_Youtube_Media){  
  if($hash.Window.isVisible){
    Update-SplashScreen -hash $hash -SplashMessage 'Importing Youtube Media'
  }
  Import-Module -Name "$Current_Folder\Modules\Import-Youtube\Import-Youtube.psm1" -NoClobber -DisableNameChecking -Scope Local
  Import-Youtube -Youtube_playlists $thisapp.Config.Youtube_Playlists -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -PlayMedia_Command $synchash.PlayMedia_Command -startup -thisApp $thisapp -use_runspace 
}elseif($synchash.Window -and $syncHash.MainGrid_Bottom_TabControl){
  write-ezlogs 'Importing of Youtube Media is not enabled' -showtime -Warning -logtype Youtube
  if($syncHash.YoutubeTable){
    $syncHash.YoutubeTable.isEnabled = $false
  }
  if($syncHash.Youtube_Tabitem){
    $syncHash.Youtube_Tabitem.isEnabled = $false
  }
  if($syncHash.MainGrid_Bottom_TabControl.items -contains $syncHash.Youtube_Tabitem){
    [Void]$syncHash.MainGrid_Bottom_TabControl.items.Remove($syncHash.Youtube_Tabitem) 
  }
}
#---------------------------------------------- 
#endregion Import-Youtube
#----------------------------------------------

#---------------------------------------------- 
#region Youtube Groups
#----------------------------------------------
if($syncHash.YoutubeTable){
  #Cell Editing
  $synchash.YoutubeTable.add_CurrentCellEndEdit($EndEditCurrentCellScripblock)
  $syncHash.YoutubeTable.GroupColumnDescriptions.add_CollectionChanged({
      try{
        $Groups = $args[0]
        $e = $args[1]
        if($thisApp.Config.Dev_mode){write-ezlogs ">>>> YoutubeMedia GroupDescriptions Changed -- Action: $($e.action) - NewItems: $($e.newItems.ColumnName) - OldItems: $($e.OldItems.ColumnName) - OldStartingIndex: $($e.OldStartingIndex) - NewStartingIndex: $($e.NewStartingIndex)" -Dev_mode}
        if($e.action -eq 'Add' -and $e.newItems.ColumnName -notin $thisApp.Config.Youtube_Group_By){
          [Void]$thisApp.Config.Youtube_Group_By.add($e.newItems.ColumnName)
        }elseif($e.action -eq 'Remove' -and $e.OldItems.ColumnName -in $thisApp.Config.Youtube_Group_By){
          write-ezlogs ">>>> Removing group '$($e.OldItems.ColumnName)' from Youtube_Group_By"
          [Void]$thisApp.Config.Youtube_Group_By.Remove($e.OldItems.ColumnName)
        }
        if($thisApp.Config.YoutubeMedia_Library_CollapseAllGroups -and $e.action -eq 'Add'){
          try{
            $syncHash.YoutubeTable.AutoExpandGroups = $false                      
            write-ezlogs ">>>> Collapsing all groups for YoutubeTable - Youtube_Group_By: $($thisApp.Config.Youtube_Group_By)"
            $synchash.YoutubeTable.CollapseAllGroup()
          }catch{
            write-ezlogs "An exception occurred calling YoutubeTable.CollapseAllGroup()" -catcherror $_
          }
        }                
      }catch{
        write-ezlogs "An exception occurred in YoutubeMedia_View.GroupDescriptions.add_CollectionChanged" -showtime -catcherror $_
      }
  })
}
if($synchash.YoutubeMediaCollapseGroups){
  $synchash.YoutubeMediaCollapseGroups.isChecked = $thisApp.Config.YoutubeMedia_Library_CollapseAllGroups                
  $synchash.YoutubeMediaCollapseGroups.Add_Checked({
      param($sender)
      try{
        if($synchash.YoutubeTable.GroupColumnDescriptions -is [Syncfusion.UI.Xaml.Grid.GroupColumnDescriptions]){
          write-ezlogs ">>>> Collapsing all groups for YoutubeTable"
          $syncHash.YoutubeTable.AutoExpandGroups = $false
          $synchash.YoutubeTable.CollapseAllGroup()
          $thisApp.Config.YoutubeMedia_Library_CollapseAllGroups = $true
        }else{
          write-ezlogs "No groups available to collapse for Youtubetable" -warning
          $sender.isChecked = $false
          $thisApp.Config.YoutubeMedia_Library_CollapseAllGroups = $false
        }       
      }catch{
        write-ezlogs "An exception occurred in YoutubeMediaCollapseGroups.Add_Checked" -catcherror $_
      }
  })
  $synchash.YoutubeMediaCollapseGroups.Add_UnChecked({
      param($sender)
      try{
        if($synchash.YoutubeTable.GroupColumnDescriptions -is [Syncfusion.UI.Xaml.Grid.GroupColumnDescriptions]){
          $syncHash.YoutubeTable.AutoExpandGroups = $true
          write-ezlogs ">>>> Expanding all groups for YoutubeTable"
          $synchash.YoutubeTable.ExpandAllGroup()
        }else{
          write-ezlogs "No groups available to expand for Youtubetable" -warning
        } 
        $thisApp.Config.YoutubeMedia_Library_CollapseAllGroups = $false         
      }catch{
        write-ezlogs "An exception occurred in YoutubeMediaCollapseGroups.Add_Checked" -catcherror $_
      }
  })
}
#---------------------------------------------- 
#endregion Youtube Groups
#----------------------------------------------

#---------------------------------------------- 
#region Youtube Actions Button
#----------------------------------------------
$synchash.Refresh_youtubeMedia_timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.Refresh_youtubeMedia_timer.add_Tick({
    try{  
      if($this.tag -eq 'QuickRefresh_youtubeMedia_Button'){
        if($synchash.YoutubeTable.Itemssource){
          $synchash.YoutubeTable.View.BeginInit()
          $synchash.YoutubeTable.ClearFilters()
          if($synchash.All_Youtube_Media){
            $synchash.YoutubeMedia_View = [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new($synchash.All_Youtube_Media)
          }else{
            $synchash.YoutubeMedia_View = [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new()
          }          
          $synchash.YoutubeMedia_View.UsePLINQ = $true
          $synchash.YoutubeTable.Itemssource = $synchash.YoutubeMedia_View
          $synchash.YoutubeTable.Itemssource.Refresh()       
          $synchash.YoutubeTable.View.EndInit()
        }
        if($thisApp.Config.Import_Youtube_Media){
          Get-YoutubeStatus -thisApp $thisApp -synchash $Synchash -verboselog:$thisApp.Config.Verbose_logging -checkall -Use_runspace
        }
      }
    }catch{
      write-ezlogs 'An exception occurred in Refresh_youtubeMedia_Button.Add_Click' -showtime -catcherror $_
    }finally{
      $this.stop()
      $this.tag = $Null
    }
})

#Youtube Full Refresh Command
[System.Windows.RoutedEventHandler]$Refresh_YoutubeMedia_Command = {
  param($sender)
  try{  
    if($thisApp.Config.Import_Youtube_Media){
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
      $Button_Settings.AffirmativeButtonText = 'Yes'
      $Button_Settings.NegativeButtonText = 'No'  
      $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Refresh Youtube Media Library","This will reimport all of your Youtube Videos and playlists as configured under the Youtube tab in Settings. This can take a few minutes depending on the number of media to process.`n`nAre you sure you wish to continue?",$okandCancel,$Button_Settings)
      if($result -eq 'Affirmative'){
        write-ezlogs ">>>> User wished to refresh the Youtube Library" -showtime
        Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'YoutubeTable' -Property 'isEnabled' -value $false
        Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'Youtube_Progress_Ring' -Property 'isActive' -value $true
        if($synchash.YoutubeTable.Itemssource){
          $synchash.YoutubeTable.Itemssource = $Null
        }                
        if([system.io.file]::Exists("$($thisApp.Config.Media_Profile_Directory)\All-Youtube_MediaProfile\All-Youtube_Media-Profile.xml")){
          write-ezlogs ">>>> Removing existing Youtube Media Profile at: $($thisApp.Config.Media_Profile_Directory)\All-Youtube_MediaProfile\All-Youtube_Media-Profile.xml" -loglevel 2
          try{
            [Void][system.io.file]::Delete("$($thisApp.Config.Media_Profile_Directory)\All-Youtube_MediaProfile\All-Youtube_Media-Profile.xml")
          }catch{
            write-ezlogs "An exception occurred removing existing Youtube Media Profile at: $($thisApp.Config.Media_Profile_Directory)\All-Youtube_MediaProfile\All-Youtube_Media-Profile.xml" -catcherror $_
          }
        }
        $synchash.All_Youtube_Media = [System.Collections.Generic.List[object]]::new()
        Import-Youtube -Youtube_playlists $thisapp.Config.Youtube_Playlists -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -thisApp $thisapp -use_runspace
      }else{
        write-ezlogs "User did not wish to refresh the Youtube Library" -showtime -warning
        return
      }
    }else{
      write-ezlogs "Cannot refresh Youtube library as Youtube Integration is disabled!" -warning -AlertUI
    }               
  }catch{
    write-ezlogs 'An exception occurred in Refresh_YoutubeMedia_Command' -showtime -catcherror $_
    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'YoutubeTable' -Property 'isEnabled' -value $true
    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'Youtube_Progress_Ring' -Property 'isActive' -value $false
  }
}

if($synchash.YoutubeMedia_Actions_Button){
  $synchash.YoutubeMedia_Actions_Button.add_Loaded({
      try{
        $synchash.YoutubeMedia_Actions_Button.items.clear()
        #Add Media 
        $Header = 'Add Video'
        if($synchash.YoutubeMedia_Actions_Button.items -notcontains $Header){
          $synchash.Add_YoutubeMedia_Button = [System.Windows.Controls.MenuItem]::new()
          $synchash.Add_YoutubeMedia_Button.IsCheckable = $false    
          $synchash.Add_YoutubeMedia_Button.Header = $Header 
          $synchash.Add_YoutubeMedia_Button.ToolTip = 'Add Youtube videos or playlists to library'
          $synchash.Add_YoutubeMedia_Button.Name = 'Add_YoutubeMedia_Button'
          $menuItem_imagecontrol = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
          $menuItem_imagecontrol.width = "14"
          $menuItem_imagecontrol.Height = "14"
          $menuItem_imagecontrol.Kind = 'PlusCircleOutline'        
          $synchash.Add_YoutubeMedia_Button.Icon = $menuItem_imagecontrol
          $synchash.Add_YoutubeMedia_Button.Add_Click({   
              try{  
                $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
                $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($synchash.Window,'Add Youtube Video','Enter/Paste the URL of the Youtube Video or Playlist',$Button_Settings)
                if(-not [string]::IsNullOrEmpty($result) -and (Test-url $result)){       
                  write-ezlogs ">>>> Adding Youtube video $result" -showtime -color cyan -logtype Youtube
                  Import-Youtube -Youtube_URL $result -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -thisApp $thisapp      
                }else{
                  write-ezlogs "The provided URL is not valid or was not provided! -- $result" -showtime -warning -logtype Youtube
                }                
              }catch{
                write-ezlogs 'An exception occurred in Add_YoutubeMedia_Button.Add_Click' -showtime -catcherror $_
              }
          })                                               
          [Void]$synchash.YoutubeMedia_Actions_Button.items.add($synchash.Add_YoutubeMedia_Button)
        }
        $Header = 'Quick Refresh'
        if($synchash.YoutubeMedia_Actions_Button.items -notcontains $Header){
          $synchash.QuickRefresh_YoutubeMedia_Button = [System.Windows.Controls.MenuItem]::new()
          $synchash.QuickRefresh_YoutubeMedia_Button.IsCheckable = $false    
          $synchash.QuickRefresh_YoutubeMedia_Button.Header = $Header 
          $synchash.QuickRefresh_YoutubeMedia_Button.ToolTip = 'Refreshes the library view with existing records'
          $synchash.QuickRefresh_YoutubeMedia_Button.Name = 'QuickRefresh_YoutubeMedia_Button'
          $menuItem_imagecontrol = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
          $menuItem_imagecontrol.width = "14"
          $menuItem_imagecontrol.Height = "14"
          $menuItem_imagecontrol.Kind = 'Refresh'        
          $synchash.QuickRefresh_YoutubeMedia_Button.Icon = $menuItem_imagecontrol
          $synchash.QuickRefresh_YoutubeMedia_Button.Add_Click({   
              try{  
                $synchash.Refresh_youtubeMedia_timer.tag = 'QuickRefresh_youtubeMedia_Button'
                $synchash.Refresh_youtubeMedia_timer.start()             
              }catch{
                write-ezlogs 'An exception occurred in QuickRefresh_YoutubeMedia_Button_menuitem.Add_Click' -showtime -catcherror $_
              }
          })                                               
          [Void]$synchash.YoutubeMedia_Actions_Button.items.add($synchash.QuickRefresh_YoutubeMedia_Button)
        }
        $Header = 'Rescan Library'
        if($synchash.YoutubeMedia_Actions_Button.items -notcontains $Header){
          $synchash.Refresh_YoutubeMedia_Button = [System.Windows.Controls.MenuItem]::new()
          $synchash.Refresh_YoutubeMedia_Button.IsCheckable = $false    
          $synchash.Refresh_YoutubeMedia_Button.Header = $Header
          $synchash.Refresh_YoutubeMedia_Button.ToolTip = 'Performs full rescan of media and rebuild of library'
          $synchash.Refresh_YoutubeMedia_Button.Name = 'Refresh_YoutubeMedia_Button'
          $menuItem_imagecontrol = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
          $menuItem_imagecontrol.width = "14"
          $menuItem_imagecontrol.Height = "14"
          $menuItem_imagecontrol.Kind = 'DatabaseRefreshOutline'        
          $synchash.Refresh_YoutubeMedia_Button.Icon = $menuItem_imagecontrol
          [Void]$synchash.Refresh_YoutubeMedia_Button.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Refresh_YoutubeMedia_Command)                                            
          [Void]$synchash.YoutubeMedia_Actions_Button.items.add($synchash.Refresh_YoutubeMedia_Button)
        }                     
      }catch{
        write-ezlogs "An exception occurred in YoutubeMedia_Actions_Button.add_Loaded" -catcherror $_
      }
  })
}
#---------------------------------------------- 
#endregion Youtube Actions Button
#----------------------------------------------
if($import_Youtube_measure){
  $import_Youtube_measure.stop()
  write-ezlogs "Import_Youtube_measure" -perf -PerfTimer $import_Youtube_measure
  $import_Youtube_measure = $Null
}
#---------------------------------------------- 
#region Import-Twitch
#----------------------------------------------
if($thisApp.Config.Startup_perf_timer){
  $import_Twitch_measure = [system.diagnostics.stopwatch]::StartNew()
}
#region Twitch Startup Timers
$synchash.TwitchMedia_TableStartup_timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.TwitchMedia_TableStartup_timer.add_Tick({
    try{
      if([string]::IsNullOrEmpty($thisApp.Config.TwitchMedia_Library_Columns)){
        $thisapp.config.TwitchMedia_Library_Columns = 'Display_Name','Channel','Status','Stream Title'
      }
      if($syncHash.TwitchTable){
        if($synchash.TwitchTable.Columns.HeaderText -contains 'Play'){
          $synchash.TwitchTable.columns| & { process {
              if($_.HeaderText -eq 'Play'){
                write-ezlogs " | Configuring TwitchTable play button" -showtime -logtype Twitch -loglevel 3
                $StackPanelFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.VirtualizingStackPanel])
                [Void]$StackPanelFactory.SetValue([System.Windows.Controls.VirtualizingStackPanel]::OrientationProperty, ([System.Windows.Controls.Orientation]::Horizontal))
                [Void]$StackPanelFactory.SetValue([System.Windows.Controls.VirtualizingStackPanel]::IsVirtualizingProperty, $true)
                [Void]$StackPanelFactory.SetValue([System.Windows.Controls.VirtualizingStackPanel]::VirtualizationModeProperty, [System.Windows.Controls.VirtualizationMode]::Recycling)
                $buttonFactory = [System.Windows.FrameworkElementFactory]::new([Windows.Controls.Primitives.ToggleButton])
                $buttonFactory.Name = 'Twitchtable_Playbutton'
                $Binding = [System.Windows.Data.Binding]::new("Value")
                [Void]$buttonFactory.SetBinding([Windows.Controls.Primitives.ToggleButton]::TagProperty,$Binding)
                [Void]$buttonFactory.SetValue([Windows.Controls.Primitives.ToggleButton]::BackgroundProperty, $synchash.Window.TryFindResource('TransparentBackgroundStyle'))
                [Void]$buttonFactory.SetValue([Windows.Controls.Primitives.ToggleButton]::StyleProperty, $synchash.Window.TryFindResource('PlayGridButtonStyle') )
                write-ezlogs " | Setting TwitchTable Play button click event" -showtime -logtype Twitch -loglevel 3
                [Void]$buttonFactory.RemoveHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.PlayMedia_Command)
                [Void]$buttonFactory.AddHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.PlayMedia_Command)
                [Void]$StackPanelFactory.AppendChild($buttonFactory)
                $dataTemplate = [System.Windows.DataTemplate]::new()
                $dataTemplate.VisualTree = $StackPanelFactory
                $_.CellTemplate = $dataTemplate
              }elseif($_.Headertext -eq 'Display Name'){                  
                $GridFactory =[System.Windows.FrameworkElementFactory]::new([Windows.Controls.Grid])
                $TextBlockFactory = [System.Windows.FrameworkElementFactory]::new([Windows.Controls.TextBlock])
                $Binding = [System.Windows.Data.Binding]::new("Value")
                [Void]$TextBlockFactory.SetBinding([Windows.Controls.TextBlock]::TextProperty,$Binding)
                [Void]$TextBlockFactory.SetValue([Windows.Controls.Button]::VerticalAlignmentProperty, [System.Windows.VerticalAlignment]::Center)
                $buttonFactory =[System.Windows.FrameworkElementFactory]::new([Windows.Controls.Button])
                $buttonFactory.Name = 'Twitchtable_EditbuttonFactory'
                [Void]$buttonFactory.SetValue([Windows.Controls.Button]::NameProperty, 'Twitchtable_Editbutton')
                [Void]$buttonFactory.RemoveHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.EditCell_Command)
                [Void]$buttonFactory.AddHandler([Windows.Controls.Primitives.ToggleButton]::ClickEvent,$synchash.EditCell_Command)
                [Void]$buttonFactory.SetValue([Windows.Controls.Button]::BackgroundProperty, $synchash.Window.TryFindResource('TransparentBackgroundStyle'))
                [Void]$buttonFactory.SetValue([Windows.Controls.Button]::StyleProperty, $synchash.Window.TryFindResource('EditButtonStyle'))
                [Void]$buttonFactory.SetValue([Windows.Controls.Button]::TagProperty, $_.MappingName)
                [Void]$GridFactory.AppendChild($TextBlockFactory)
                [Void]$GridFactory.AppendChild($buttonFactory)
                $dataTemplate = [System.Windows.DataTemplate]::new()
                $dataTemplate.VisualTree = $GridFactory
                $_.CellTemplate = $dataTemplate              
              }elseif($_.HeaderText -notin $thisApp.Config.TwitchMedia_Library_Columns){
                $_.IsHidden = $true
              }
          }}
        }elseif($syncHash.TwitchTable){
          [Void]$syncHash.TwitchTable.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.PlayMedia_Command)
          [Void]$syncHash.TwitchTable.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.PlayMedia_Command)
        }
        if(-not [string]::IsNullOrEmpty($synchash.TwitchMedia_View) -and $syncHash.TwitchTable){
          write-ezlogs ">>>> Setting Twitch itemssource" -showtime
          # Create a binding to pair the listbox to the observable collection
          $synchash.TwitchMedia_ListLock = [PSCustomObject]::new()
          $MediaTableBinding = [System.Windows.Data.Binding]::new()
          #$MediaTableBinding.IsAsync = $true
          $MediaTableBinding.Source = $synchash.TwitchMedia_View
          $MediaTableBinding.Mode = [System.Windows.Data.BindingMode]::OneTime
          [void][System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($synchash.TwitchMedia_View,$synchash.TwitchMedia_ListLock)
          [void][System.Windows.Data.BindingOperations]::SetBinding($syncHash.TwitchTable,[Syncfusion.UI.Xaml.Grid.SfDataGrid]::ItemsSourceProperty, $MediaTableBinding)
        }                           
        $synchash.Twitch_Table_Total_Media.text = "$($syncHash.TwitchMedia_View.Count)"
        $Controls_to_Update = [System.Collections.Generic.list[Object]]::new(5)
        $newRow = [PSCustomObject]::new(@{
            'Control' = 'Twitch_Progress_Ring'
            'Property' = 'isActive'
            'Value' = $false
        })         
        [Void]$Controls_to_Update.Add($newRow) 
        $newRow = [PSCustomObject]::new(@{
            'Control' =  'TwitchMedia_Progress_Label'
            'Property' = 'Visibility'
            'Value' =  'Hidden'
        })           
        [Void]$Controls_to_Update.Add($newRow)
        $newRow = [PSCustomObject]::new(@{
            'Control' = 'TwitchMedia_Progress2_Label'
            'Property' = 'Visibility'
            'Value' = 'Hidden'
        })         
        [Void]$Controls_to_Update.Add($newRow)
        $newRow = [PSCustomObject]::new(@{
            'Control' =  'TwitchTable'
            'Property' = 'isEnabled'
            'Value' =  $true
        })       
        [Void]$Controls_to_Update.Add($newRow)
        $newRow = [PSCustomObject]::new(@{
            'Control' =  'TwitchTable'
            'Property' = 'Visibility'
            'Value' =  'Visible'
        })
        [Void]$Controls_to_Update.Add($newRow)
        Update-MainWindow -synchash $synchash -thisApp $thisApp -controls $Controls_to_Update
        if($syncHash.MainGrid_Bottom_TabControl.items -notcontains $syncHash.Twitch_Tabitem){
          [Void]$syncHash.MainGrid_Bottom_TabControl.items.Add($syncHash.Twitch_Tabitem) 
        }
        try{                  
          if(($syncHash.TwitchTable.ItemsSource) -and $thisApp.Config.Twitch_Group_By){   
            #TODO: Temporary to cleanup issue from old configs
            if($thisApp.Config.Twitch_Group_By -eq 'Syncfusion.UI.Xaml.Grid.GroupColumnDescription'){
              $Groups = 'Live_Status'
            }else{
              $Groups = $thisApp.Config.Twitch_Group_By
            }                      
            if($syncHash.TwitchTable.GroupColumnDescriptions -is [Syncfusion.UI.Xaml.Grid.GroupColumnDescriptions]){
              [Void]$syncHash.TwitchTable.GroupColumnDescriptions.clear()
              $Groups | & { process {
                  if($_ -and $syncHash.TwitchTable.GroupColumnDescriptions.ColumnName -notcontains $_){
                    write-ezlogs " | Adding groupdescription to TwitchMedia_View for property: $($_)" -logtype Twitch -LogLevel 2
                    $groupdescription = [Syncfusion.UI.Xaml.Grid.GroupColumnDescription]::new()
                    $groupdescription.ColumnName = $_
                    [Void]$syncHash.TwitchTable.GroupColumnDescriptions.Add($groupdescription)
                  }
              }} 
            }                        
          }
        }catch{
          write-ezlogs "An exception occurred setting groups for TwitchTable" -catcherror $_
        }
        #---------------------------------------------- 
        #region Twitch Monitor
        #----------------------------------------------
        if($thisapp.config.Twitch_Update -and $thisapp.config.Twitch_Update_Interval){
          try{
            Start-TwitchMonitor -Interval $thisapp.config.Twitch_Update_Interval -thisApp $thisapp -synchash $synchash -Verboselog
          }catch{
            write-ezlogs 'An exception occurred in Start-TwitchMonitor' -showtime -catcherror $_
          }
        }
        #---------------------------------------------- 
        #endregion Twitch Monitor
        #----------------------------------------------        
      }else{
        write-ezlogs "No Twitchtable UI is available" -warning
      }                       
    }catch{
      $this.Stop()
      write-ezlogs "An exception occurred attempting to set itemsource for TwitchTable" -showtime -catcherror $_
    }finally{
      $this.Stop()  
    }  
})
#endregion Twitch Startup Timers

if($thisapp.Config.Import_Twitch_Media){
  if($hash.Window.isVisible){
    Update-SplashScreen -hash $hash -SplashMessage 'Importing Twitch Media'
  }
  Import-Module -Name "$Current_Folder\Modules\Import-Twitch\Import-Twitch.psm1" -NoClobber -DisableNameChecking -Scope Local
  Import-Twitch -Twitch_playlists $thisapp.Config.Twitch_Playlists -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -startup -thisApp $thisapp -use_runspace  
}elseif($synchash.Window -and $syncHash.MainGrid_Bottom_TabControl){
  write-ezlogs 'Importing of Twitch Media is not enabled' -showtime -Warning -logtype Twitch
  if($syncHash.TwitchTable){
    $syncHash.TwitchTable.isEnabled = $false
  }
  if($syncHash.MainGrid_Bottom_TabControl.items -contains $syncHash.Twitch_Tabitem){
    [Void]$syncHash.MainGrid_Bottom_TabControl.items.Remove($syncHash.Twitch_Tabitem) 
  }
}
#---------------------------------------------- 
#endregion Import-Twitch
#----------------------------------------------

#---------------------------------------------- 
#region Twitch Dragging
#----------------------------------------------
if($synchash.TwitchTable){
  $synchash.TwitchTable.add_PreviewDragOver({
      try{
        $sender = ($args[0])
        $e = ($args[1])
        if ($e.Data.GetDataPresent("ListViewRecords")){ 
          $draggingRecords = $e.Data.GetData("ListViewRecords") -as [System.Collections.ObjectModel.ObservableCollection[object]]  
        }else{ 
          $draggingRecords = $e.Data.GetData("Records") -as [System.Collections.ObjectModel.ObservableCollection[object]] 
        }
        if($draggingRecords -eq $null){
          return  
        }         
        $e.Handled = $true
      }catch{
        write-ezlogs "An exception occurred in TwitchTable.add_PreviewDragOver" -catcherror $_
      }
  })
}
#---------------------------------------------- 
#endregion Twitch Dragging
#----------------------------------------------

#---------------------------------------------- 
#region Twitch Filters
#----------------------------------------------
$synchash.TwitchFilter_timer = [System.Windows.Threading.DispatcherTimer]::New([System.Windows.Threading.DispatcherPriority]::Background)
$synchash.TwitchFilter_timer.add_Tick({
    try{
      $TwitchFilter_measure = [system.diagnostics.stopwatch]::StartNew()
      if($synchash.TwitchTable.itemssource -and !$synchash.TwitchTable.Itemssource.isInDeferRefresh){
        #$synchash.TwitchTable.View.BeginInit()
        $synchash.TwitchTable.View.Filter = {
          param ($item) 
          if(-not [string]::IsNullOrEmpty($synchash.TwitchFilterTextBox.Text)){
            $text = $(($synchash.TwitchFilterTextBox.Text).tolower()).trim()
          }
          $SearchPattern = "$([regex]::Escape($Text))"
          $($item.Title) -match $SearchPattern -or $($item.Display_Name) -match $SearchPattern -or $($item.Channel_Name) -match $SearchPattern -or $($item.Live_Status) -match $SearchPattern -or $($item.Status_Msg) -match $SearchPattern        
        }
        #$synchash.TwitchTable.View.EndInit()
        if($synchash.TwitchTable.View){
          $synchash.TwitchTable.View.RefreshFilter()
        }
      }                             
    }catch{
      write-ezlogs 'An exception occurred in TwitchFilterTextBox' -showtime -catcherror $_
    }finally{
      $this.Stop()
      $TwitchFilter_measure.stop()
      write-ezlogs "TwitchFilter_timer" -PerfTimer $TwitchFilter_measure -Perf
    }
})
 
if($synchash.TwitchFilterTextBox){
  $synchash.TwitchFilterTextBox.Add_TextChanged({
      try{
        if(!$synchash.TwitchFilter_timer.isEnabled){
          $synchash.TwitchFilter_timer.start()
        }        
      }catch{
        write-ezlogs "An exception occurred in TwitchFilterTextBox.Add_TextChanged" -showtime -catcherror $_
      }   
  }) 

  $synchash.TwitchFilterTextBox.Add_PreviewLostKeyboardFocus({
      try{
        $newFocus = $args[1].NewFocus
        if($newFocus -is [Syncfusion.UI.Xaml.Grid.SfDataGrid] -or $newFocus -is [Syncfusion.UI.Xaml.Grid.GridCell]){
          write-ezlogs "[TwitchFilterTextBox] Preventing new focus from: $($newFocus)" -warning
          $args[1].Handled = $true
        }       
      }catch{
        write-ezlogs "An exception occurrred in TwitchFilterTextBox Add_PreviewLostKeyboardFocus event" -showtime -catcherror $_
      }
  })

  $synchash.TwitchTable.Add_FilterChanged({
      param([Parameter(Mandatory)][Object]$sender,[Parameter(Mandatory)][Syncfusion.UI.Xaml.Grid.GridFilterEventArgs]$e)
      try{
        $synchash.Twitch_Table_Total_Media.text = "$($synchash.TwitchTable.View.records.Count)"
      }catch{
        write-ezlogs "An exception occurred in TwitchFilterChanged" -showtime -catcherror $_
      }   
  })  
}

if($synchash.TwitchSearch_Button){
  $synchash.TwitchSearch_Button.Add_Click({
      try{
        if(!$synchash.TwitchFilter_timer.isEnabled){
          $synchash.TwitchFilter_timer.start()
        }
      }catch{
        write-ezlogs "An exception occurred in TwitchSearch_Button" -showtime -catcherror $_
      }   
  }) 
  $synchash.TwitchFilterTextBox.Add_PreviewKeyDown({
      param([Parameter(Mandatory)][Object]$sender,[Parameter(Mandatory)][Windows.Input.KeyEventArgs]$e)
      try{
        if($e.Key -eq 'Enter' -and !$synchash.TwitchFilter_timer.isEnabled){
          $synchash.TwitchFilter_timer.start()
        }
      }catch{
        write-ezlogs "An exception occurred in TwitchFilterTextBox.Add_PreviewKeyDown" -catcherror $_
      }
  })
}
#---------------------------------------------- 
#endregion Twitch Filters
#----------------------------------------------

#---------------------------------------------- 
#region Twitch Groups
#----------------------------------------------
if($synchash.TwitchMedia_Column_Button){
  $synchash.TwitchMedia_Column_Button.add_Loaded({
      try{
        $synchash.TwitchMedia_Column_Button.items.clear()
        $synchash.TwitchTable.Columns | & { process {
            $Header = $_.Headertext
            if($Header -notin 'Play' -and $synchash.TwitchMedia_Column_Button.items -notcontains $Header){
              $MenuItem = [System.Windows.Controls.MenuItem]::new()
              $MenuItem.IsCheckable = $true     
              $MenuItem.Header = $Header
              if($_.isHidden){      
                $MenuItem.IsChecked = $false                 
              }else{
                $MenuItem.IsChecked = $true
              }
              $MenuItem.Add_Checked({
                  try{
                    $Column = Get-IndexesOf $synchash.Twitchtable.Columns.HeaderText -Value $this.Header | & { process {
                        $synchash.Twitchtable.Columns[$_]
                    }}
                    if($Column){
                      write-ezlogs ">>>> UnHiding column: $($Column.HeaderText)"
                      $Column.isHidden = $false
                    }
                    $ActiveColumns = Get-IndexesOf $synchash.Twitchtable.Columns.isHidden -Value $false | & { process {
                        $c = $synchash.Twitchtable.Columns[$_]
                        if($c -notin 'Play'){
                          $c.HeaderText
                        }
                    }}
                    $thisApp.Config.TwitchMedia_Library_Columns = $ActiveColumns
                  }catch{
                    write-ezlogs "An exception occurred in add_checked for menuitem: $($this.Header)" -catcherror $_
                  }
              })
              $MenuItem.Add_UnChecked({
                  try{
                    $Column = Get-IndexesOf $synchash.Twitchtable.Columns.HeaderText -Value $this.Header | & { process {
                        $synchash.Twitchtable.Columns[$_]
                    }}
                    if($Column){
                      write-ezlogs ">>>> Hiding column: $($Column.HeaderText)"
                      $Column.isHidden = $true
                    }
                    $ActiveColumns = Get-IndexesOf $synchash.Twitchtable.Columns.isHidden -Value $false | & { process {
                        $c = $synchash.Twitchtable.Columns[$_]
                        if($c -notin 'Play'){
                          $c.HeaderText
                        }
                    }}
                    $thisApp.Config.TwitchMedia_Library_Columns = $ActiveColumns
                  }catch{
                    write-ezlogs "An exception occurred in add_Unchecked for menuitem: $($this.Header)" -catcherror $_
                  }
              })                                                    
              [Void]$synchash.TwitchMedia_Column_Button.items.add($MenuItem)
            }                    
        }}
      }catch{
        write-ezlogs "An exception occurred in TwitchMedia_ColumnComboBox.add_Loaded" -catcherror $_
      }
  })
}
if($syncHash.TwitchTable){
  #Cell Editing
  $synchash.TwitchTable.add_CurrentCellEndEdit($EndEditCurrentCellScripblock)
  $syncHash.TwitchTable.GroupColumnDescriptions.add_CollectionChanged({
      try{
        $Groups = $args[0]
        $e = $args[1]
        if($thisApp.Config.Dev_mode){write-ezlogs ">>>> TwitchMedia GroupDescriptions Changed -- Action: $($e.action) - NewItems: $($e.newItems.ColumnName) - OldItems: $($e.OldItems.ColumnName) - OldStartingIndex: $($e.OldStartingIndex) - NewStartingIndex: $($e.NewStartingIndex)" -Dev_mode}
        if($e.action -eq 'Add' -and $e.newItems.ColumnName -notin $thisApp.Config.Twitch_Group_By){
          [Void]$thisApp.Config.Twitch_Group_By.add($e.newItems.ColumnName)
        }elseif($e.action -eq 'Remove' -and $e.OldItems.ColumnName -in $thisApp.Config.Twitch_Group_By){
          write-ezlogs ">>>> Removing group '$($e.OldItems.ColumnName)' from Twitch_Group_By"
          [Void]$thisApp.Config.Twitch_Group_By.Remove($e.OldItems.ColumnName)
        }
        if($thisApp.Config.TwitchMedia_Library_CollapseAllGroups -and $e.action -eq 'Add'){
          try{
            $syncHash.TwitchTable.AutoExpandGroups = $false                      
            write-ezlogs ">>>> Collapsing all groups for TwitchTable - Twitch_Group_By: $($thisApp.Config.Twitch_Group_By)"
            $synchash.TwitchTable.CollapseAllGroup()
          }catch{
            write-ezlogs "An exception occurred calling TwitchTable.CollapseAllGroup()" -catcherror $_
          }
        }                
      }catch{
        write-ezlogs "An exception occurred in TwitchMedia_View.GroupDescriptions.add_CollectionChanged" -showtime -catcherror $_
      }
  })
}
if($synchash.TwitchMediaCollapseGroups){
  $synchash.TwitchMediaCollapseGroups.isChecked = $thisApp.Config.TwitchMedia_Library_CollapseAllGroups                
  $synchash.TwitchMediaCollapseGroups.Add_Checked({
      param($sender)
      try{
        if($synchash.TwitchTable.GroupColumnDescriptions -is [Syncfusion.UI.Xaml.Grid.GroupColumnDescriptions]){
          write-ezlogs ">>>> Collapsing all groups for TwitchTable"
          $syncHash.TwitchTable.AutoExpandGroups = $false
          $synchash.TwitchTable.CollapseAllGroup()
          $thisApp.Config.TwitchMedia_Library_CollapseAllGroups = $true
        }else{
          write-ezlogs "No groups available to collapse for Twitchtable" -warning
          $sender.isChecked = $false
          $thisApp.Config.TwitchMedia_Library_CollapseAllGroups = $false
        }       
      }catch{
        write-ezlogs "An exception occurred in TwitchMediaCollapseGroups.Add_Checked" -catcherror $_
      }
  })
  $synchash.TwitchMediaCollapseGroups.Add_UnChecked({
      param($sender)
      try{
        if($synchash.TwitchTable.GroupColumnDescriptions -is [Syncfusion.UI.Xaml.Grid.GroupColumnDescriptions]){
          $syncHash.TwitchTable.AutoExpandGroups = $true
          write-ezlogs ">>>> Expanding all groups for TwitchTable"
          $synchash.TwitchTable.ExpandAllGroup()
        }else{
          write-ezlogs "No groups available to expand for Twitchtable" -warning
        } 
        $thisApp.Config.TwitchMedia_Library_CollapseAllGroups = $false        
      }catch{
        write-ezlogs "An exception occurred in TwitchMediaCollapseGroups.Add_Checked" -catcherror $_
      }
  })
}
#---------------------------------------------- 
#endregion Twitch Groups
#----------------------------------------------

#---------------------------------------------- 
#region Twitch Action Button
#----------------------------------------------
$synchash.Refresh_TwitchMedia_timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.Refresh_TwitchMedia_timer.add_Tick({
    try{  
      if($this.tag -eq 'QuickRefresh_TwitchMedia_Button'){
        if($synchash.TwitchTable.Itemssource){
          if($synchash.TwitchTable.View){
            $synchash.TwitchTable.View.BeginInit()
          }
          write-ezlogs ">>>> Performing quick refresh of TwitchTable.Itemssource"
          $synchash.TwitchTable.ClearFilters()
          if($synchash.All_Twitch_Media){
            $synchash.TwitchMedia_View = [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new($synchash.All_Twitch_Media)
          }else{
            $synchash.TwitchMedia_View = [Syncfusion.UI.Xaml.Grid.GridVirtualizingCollectionView]::new()
          }
          $synchash.TwitchMedia_View.UsePLINQ = $true
          $synchash.TwitchTable.Itemssource = $synchash.TwitchMedia_View
          $synchash.TwitchTable.Itemssource.Refresh()
          if($synchash.TwitchTable.View){
            $synchash.TwitchTable.View.EndInit()
          }
        }
      }
    }catch{
      write-ezlogs 'An exception occurred in Refresh_TwitchMedia_Button.Add_Click' -showtime -catcherror $_
    }finally{
      $this.stop()
      $this.tag = $Null
    }
})
#Twitch Full Refresh Command
[System.Windows.RoutedEventHandler]$Refresh_TwitchMedia_Command = {
  param($sender)
  try{  
    $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
    $Button_Settings.AffirmativeButtonText = 'Yes'
    $Button_Settings.NegativeButtonText = 'No'  
    $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Refresh Twitch Media Library","This will re-import all of your Twitch channels as configured under the Twitch tab in Settings. This can take a few minutes depending on the number of media to process.`n`nAre you sure you wish to continue?",$okandCancel,$Button_Settings)
    if($result -eq 'Affirmative'){
      write-ezlogs ">>>> User wished to refresh the Twitch Library" -showtime
      if($synchash.TwitchTable.Itemssource){
        $synchash.TwitchTable.Itemssource = $Null
      } 
      $All_Twitch_MediaProfile = "$($thisApp.Config.Media_Profile_Directory)\All-Twitch_MediaProfile\All-Twitch_Media-Profile.xml"
      if([system.io.file]::Exists($All_Twitch_MediaProfile)){
        write-ezlogs ">>>> Removing existing Twitch Media Profile at: $All_Twitch_MediaProfile" -loglevel 2
        try{
          [Void][system.io.file]::Delete($All_Twitch_MediaProfile)
        }catch{
          write-ezlogs "An exception occurred removing existing Twitch Media Profile at: $All_Twitch_MediaProfile" -catcherror $_
        }
      }
      $synchash.All_Twitch_Media = [System.Collections.Generic.List[object]]::new()
      Import-Twitch -Twitch_playlists $thisapp.Config.Twitch_Playlists -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -thisApp $thisapp -use_runspace -refresh
    }else{
      write-ezlogs "User did not wish to refresh the Twitch Library" -showtime -warning
      return
    }               
  }catch{
    write-ezlogs 'An exception occurred in Refresh_TwitchMedia_Command' -showtime -catcherror $_
    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'TwitchTable' -Property 'isEnabled' -value $true
    Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'Twitch_Progress_Ring' -Property 'isActive' -value $false
  }
}

if($synchash.TwitchMedia_Actions_Button){
  $synchash.TwitchMedia_Actions_Button.add_Loaded({
      try{
        $synchash.TwitchMedia_Actions_Button.items.clear()
        #Add Media 
        $Header = 'Add Stream'
        if($synchash.TwitchMedia_Actions_Button.items -notcontains $Header){
          $synchash.Add_TwitchMedia_Button = [System.Windows.Controls.MenuItem]::new()
          $synchash.Add_TwitchMedia_Button.IsCheckable = $false    
          $synchash.Add_TwitchMedia_Button.Header = $Header 
          $synchash.Add_TwitchMedia_Button.ToolTip = 'Add Twitch streams and channels to library'
          $synchash.Add_TwitchMedia_Button.Name = 'Add_TwitchMedia_Button'
          $menuItem_imagecontrol = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
          $menuItem_imagecontrol.width = "14"
          $menuItem_imagecontrol.Height = "14"
          $menuItem_imagecontrol.Kind = 'PlusCircleOutline'        
          $synchash.Add_TwitchMedia_Button.Icon = $menuItem_imagecontrol
          $synchash.Add_TwitchMedia_Button.Add_Click({ 
              try{  
                $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
                $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($synchash.Window,'Add Twitch Channel','Enter/Paste the URL of the Twitch Channel or Stream',$Button_Settings)
                if(-not [string]::IsNullOrEmpty($result) -and (Test-url $result)){       
                  write-ezlogs ">>>> Adding Twitch channel $result" -showtime -color cyan -logtype Youtube
                  Import-Twitch -Twitch_URL $result -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory  -thisApp $thisapp      
                }else{
                  write-ezlogs "The provided URL is not valid or was not provided! -- $result" -showtime -warning -logtype Youtube
                }                
              }catch{
                write-ezlogs 'An exception occurred in Add_TwitchMedia_Button.Add_Click' -showtime -catcherror $_
              }
          })                                               
          [Void]$synchash.TwitchMedia_Actions_Button.items.add($synchash.Add_TwitchMedia_Button)
        }
        $Header = 'Quick Refresh'
        if($synchash.TwitchMedia_Actions_Button.items -notcontains $Header){
          $synchash.QuickRefresh_TwitchMedia_Button = [System.Windows.Controls.MenuItem]::new()
          $synchash.QuickRefresh_TwitchMedia_Button.IsCheckable = $false    
          $synchash.QuickRefresh_TwitchMedia_Button.Header = $Header 
          $synchash.QuickRefresh_TwitchMedia_Button.ToolTip = 'Refreshes the library view with existing records'
          $synchash.QuickRefresh_TwitchMedia_Button.Name = 'QuickRefresh_TwitchMedia_Button'
          $menuItem_imagecontrol = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
          $menuItem_imagecontrol.width = "14"
          $menuItem_imagecontrol.Height = "14"
          $menuItem_imagecontrol.Kind = 'Refresh'        
          $synchash.QuickRefresh_TwitchMedia_Button.Icon = $menuItem_imagecontrol
          $synchash.QuickRefresh_TwitchMedia_Button.Add_Click({   
              try{  
                $synchash.Refresh_TwitchMedia_timer.tag = 'QuickRefresh_TwitchMedia_Button'
                $synchash.Refresh_TwitchMedia_timer.start()             
              }catch{
                write-ezlogs 'An exception occurred in QuickRefresh_TwitchMedia_Button_menuitem.Add_Click' -showtime -catcherror $_
              }
          })                                               
          [Void]$synchash.TwitchMedia_Actions_Button.items.add($synchash.QuickRefresh_TwitchMedia_Button)
        }
        $Header = 'Rescan Library'
        if($synchash.TwitchMedia_Actions_Button.items -notcontains $Header){
          $synchash.Refresh_TwitchMedia_Button = [System.Windows.Controls.MenuItem]::new()
          $synchash.Refresh_TwitchMedia_Button.IsCheckable = $false    
          $synchash.Refresh_TwitchMedia_Button.Header = $Header
          $synchash.Refresh_TwitchMedia_Button.ToolTip = 'Performs full rescan of media and rebuild of library'
          $synchash.Refresh_TwitchMedia_Button.Name = 'Refresh_TwitchMedia_Button'
          $menuItem_imagecontrol = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
          $menuItem_imagecontrol.width = "14"
          $menuItem_imagecontrol.Height = "14"
          $menuItem_imagecontrol.Kind = 'DatabaseRefreshOutline'        
          $synchash.Refresh_TwitchMedia_Button.Icon = $menuItem_imagecontrol
          [Void]$synchash.Refresh_TwitchMedia_Button.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Refresh_TwitchMedia_Command)                                            
          [Void]$synchash.TwitchMedia_Actions_Button.items.add($synchash.Refresh_TwitchMedia_Button)
        }                     
      }catch{
        write-ezlogs "An exception occurred in TwitchMedia_Actions_Button.add_Loaded" -catcherror $_
      }
  })
}
#---------------------------------------------- 
#endregion Twitch Action Button
#----------------------------------------------
if($import_Twitch_measure){
  $import_Twitch_measure.stop()
  write-ezlogs "Import-Twitch Startup" -PerfTimer $import_Twitch_measure
  $import_Twitch_measure = $Null
}
#---------------------------------------------- 
#region DragDrop Handlers
#----------------------------------------------
#TODO: All DragDrop stuff needs to be redone from scratch
$synchash.PreviewDrop_command = {
  Param(
    [System.Object]$sender,
    [System.Windows.DragEventArgs]$d
  )
  try{
    #$d.Handled = $true
    #write-ezlogs ">>>> d formats $($d.data.GetFormats() | out-string)" -showtime -color cyan
    #write-ezlogs ">>>> GetData dataformat name $($d.data.GetData([GongSolutions.Wpf.DragDrop.DragDrop]::DataFormat.Name) | out-string)" -showtime -Dev_mode
    #write-ezlogs ">>>> GetSelectDroppedItems $([GongSolutions.Wpf.DragDrop.DragDrop]::GetSelectDroppedItems($d) | out-string)" -showtime -Dev_mode
    #write-ezlogs ">>>> GetDataPresent d.data.name $($d.data.GetDataPresent([GongSolutions.Wpf.DragDrop.DragDrop]::GetSelectDroppedItems($d)) | out-string)" -showtime -Dev_mode
    #write-ezlogs ">>>> OG Source $($d.OriginalSource | out-string)" -showtime -Dev_mode
    write-ezlogs ">>>> d.data $($d.Data.GetDataPresent([Windows.Forms.DataFormats]::Text) | out-string)" -showtime -Dev_mode
    write-ezlogs ">>>> d.data GetFormats $($($d.Data.GetData('Records')) | out-string)" -showtime -Dev_mode  
    write-ezlogs ">>>> d $($d | out-string)" -showtime -Dev_mode
    if($d.Data.GetDataPresent([Windows.Forms.DataFormats]::Text)){
      try{  
        $LinkDrop = $d.data.GetData([Windows.Forms.DataFormats]::Text)
        if(-not [string]::IsNullOrEmpty($LinkDrop) -and (Test-url $LinkDrop)){
          if($LinkDrop -match 'twitch\.tv'){
            $d.Handled = $true
            $twitch_channel = $((Get-Culture).textinfo.totitlecase(($LinkDrop | split-path -leaf).tolower()))
            write-ezlogs ">>>> Adding Twitch channel $twitch_channel - $LinkDrop" -showtime -color cyan    
            $Group = 'Twitch'                   
          }elseif($LinkDrop -match 'youtube\.com' -or $LinkDrop -match 'youtu\.be'){
            if($LinkDrop -match '&t='){
              $LinkDrop = ($($LinkDrop) -split('&t='))[0].trim()
            }          
            write-ezlogs ">>>> Adding Youtube link $LinkDrop" -showtime -color cyan
            $url = [uri]$linkDrop
            $Group = 'Youtube'
            if($LinkDrop -match '\/tv\.youtube\.com\/'){
              if($LinkDrop -match '\%3D\%3D'){
                $LinkDrop = $LinkDrop -replace '\%3D\%3D'
              }
              if($LinkDrop -match '\?vp='){
                $youtube_id = [regex]::matches($LinkDrop, "tv.youtube.com\/watch\/(?<value>.*)\?vp\=")| %{$_.groups[1].value}
              }elseif($LinkDrop -match '\?v='){
                $youtube_id = [regex]::matches($LinkDrop, "tv.youtube.com\/watch\?v=(?<value>.*)")| %{$_.groups[1].value}
              }else{
                $youtube_id = [regex]::matches($LinkDrop, "tv.youtube.com\/watch\/(?<value>.*)")| %{$_.groups[1].value}
              }
              $type = 'YoutubeTV'   
            }elseif($LinkDrop -match "v="){
              $youtube_id = ($($LinkDrop) -split('v='))[1].trim()    
            }elseif($LinkDrop -match 'list='){
              $youtube_id = ($($LinkDrop) -split('list='))[1].trim()                  
            }elseif($LinkDrop -match "\/watch\/"){
              $youtube_id = [regex]::matches($LinkDrop, "\/watch\/(?<value>.*)")| %{$_.groups[1].value}
            }elseif($LinkDrop -notmatch "v=" -and $LinkDrop -notmatch '\?' -and $LinkDrop -notmatch '\&'){
              $youtube_id = (([uri]$LinkDrop).segments | select -last 1) -replace '/',''
            }
            if($youtube_id -match '\&pp='){
              $youtube_id = ($youtube_id -split '\&pp=')[0]
            }                                 
            $d.Handled = $true          
          }
          if($d.Handled){         
            if($thisApp.Config.PlayLink_OnDrop){
              if($Group -eq 'Youtube'){
                $synchash.Youtube_Progress_Ring.isActive = $true
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
                    if($video_info.contentDetails.duration){
                      $TimeValues = $video_info.contentDetails.duration
                      if($TimeValues){
                        try{         
                          $duration =[TimeSpan]::FromHours((Convert-TimespanToInt -Timespan $TimeValues))       
                          if($duration){
                            $duration = "$(([string]$duration.hours).PadLeft(2,'0')):$(([string]$duration.Minutes).PadLeft(2,'0')):$(([string]$duration.Seconds).PadLeft(2,'0'))"
                          }             
                        }catch{
                          write-ezlogs "An exception occurred parsing duration for $($title)" -showtime -catcherror $_
                        }
                      }           
                    }
                    $viewcount = $video_info.statistics.viewCount              
                  }else{
                    $title = "Youtube Video - $youtube_id"
                  }                
                }
                $media = [PSCustomObject]::new(@{
                    'title' =  $title
                    'description' = $description
                    'channel_id' = $channel_id
                    'id' = $youtube_id
                    'duration' = $duration
                    'url' = $url           
                    'thumbnail' = $thumbnail
                    'type' = ''
                    'images' = $images
                    'Playlist_url' = ''
                    'playlist_id' = $youtube_id
                    'Profile_Date_Added' = [DateTime]::Now
                    'Source' = 'Youtube'
                    'Group' = $Group
                })
              }elseif($Group -eq 'Twitch'){
                $TwitchAPI = Get-TwitchAPI -StreamName $twitch_channel -thisApp $thisApp
                if($TwitchAPI.user_id){
                  $id = $TwitchAPI.user_id
                }elseif($twitch_channel){
                  $idbytes = [System.Text.Encoding]::UTF8.GetBytes("$($twitch_channel)-TwitchChannel")
                  $id = [System.Convert]::ToBase64String($idbytes)     
                }
                if($TwitchAPI.thumbnail_url){
                  $thumbnail = "$($TwitchAPI.thumbnail_url -replace '{width}x{height}','500x500')"
                }else{
                  $thumbnail = $null
                }
                if($TwitchAPI.profile_image_url){
                  $profile_image_url = $TwitchAPI.profile_image_url
                  $offline_image_url = $TwitchAPI.offline_image_url
                  $description = $TwitchAPI.description
                }else{
                  $profile_image_url = $Null
                  $offline_image_url = $Null  
                  $description = $Null   
                } 
                $channel_url = "https://twitch.tv/$($twitch_channel)"
                $media = [PSCustomObject]::new(@{
                    'title' = $title
                    'artist' = $twitch_channel
                    'id' = $id
                    'Name' = $twitch_channel
                    'User_id' = $TwitchAPI.user_id
                    'url' = $channel_url
                    'Duration' = ''
                    'Followed' = ''
                    'Playlist_ID' = $id
                    'Playlist_URL' = $channel_url
                    'Live_Status' = ''
                    'Stream_title' = ''
                    'Status_Msg' = ''
                    'thumbnail' = $thumbnail
                    'description' = $description
                    'profile_image_url' = $profile_image_url
                    'offline_image_url' = $offline_image_url          
                    'Channel_Name' = $twitch_channel
                    'chat_url' = "https://twitch.tv/$($twitch_channel)/chat"
                    'Playlist' = $twitch_channel
                    'type' = 'TwitchChannel'
                    'Source' = 'Twitch'
                    'Group' = 'Twitch'
                    'Profile_Date_Added' = $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss:tt')
                })
              }
              Start-Media -Media $media -thisApp $thisApp -synchashWeak ([System.WeakReference]::new($synchash)) -Show_notification  -use_WebPlayer:$thisapp.config.Youtube_WebPlayer
            }
            try{
              if($Group -eq 'Youtube'){
                Import-Youtube -Youtube_URL $LinkDrop -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -thisApp $thisapp -use_runspace
              }elseif($Group -eq 'Twitch'){
                Import-Twitch -Twitch_URL $LinkDrop -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -thisApp $thisapp -use_runspace
              }           
              if($thisApp.Config.PlayLink_OnDrop){
                write-ezlogs ">>>> Starting update_status_timer" -showtime
                try{
                  $synchash.update_status_timer.start()
                  if($synchash.update_Queue_timer -and !$synchash.update_Queue_timer.isEnabled){
                    $synchash.update_Queue_timer.Tag = 'UpdatePlaylists'
                    $synchash.update_Queue_timer.start()
                  }
                }catch{
                  write-ezlogs "An exception occurred executing update_status_timer and WebPlayer_Playing_timer" -showtime -catcherror $_
                }
              }
            }catch{
              write-ezlogs "An exception occurred importing media for $linkDrop" -showtime -catcherror $_
            }     
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
          Import-Media -Media_Path $FileDrop -verboselog:$thisApp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -use_runspace -AddNewOnly      
        }else{
          write-ezlogs "The provided Path is not valid or was not provided! -- $FileDrop" -showtime -warning
        }                        
      }catch{
        write-ezlogs "An exception occurred in PreviewDrop" -showtime -catcherror $_
      }    
    }elseif($d.data.GetDataPresent([GongSolutions.Wpf.DragDrop.DragDrop]::DataFormat.Name) -or $d.Data.GetData('Records')){       
      $item = $d.data.GetData([GongSolutions.Wpf.DragDrop.DragDrop]::DataFormat.Name)
      if(!$item){
        $item = $d.Data.GetData('Records')
      }
      write-ezlogs "[DragDrop] item $($item | out-string)" -Dev_mode
      $Media = $item.tag.Media    
      if($item.Name -eq 'Playlist'){
        $From_Playlist_Name = $item.title
        if($syncHash.Playlists_TreeView.Items){
          $media = ($syncHash.Playlists_TreeView.Items | Where-Object {$_.Title -eq $From_Playlist_Name}).items.tag.media
        }else{
          $media = ($syncHash.Playlists_TreeView.Nodes | Where-Object {$_.Content.Title -eq $From_Playlist_Name}).ChildNodes.content.tag.media
        }        
      }elseif($item.parent.Header.title){
        $From_Playlist_Name = $item.parent.Header.title 
      }elseif($sender.Name -eq 'PlayQueue_TreeView'){      
        $From_Playlist_Name = 'Play Queue'
      }elseif($item.source -eq 'Local' -or $item.source -eq 'Spotify' -or $item.source -eq 'Youtube' -or $item.source -eq 'Twitch'){
        $From_Playlist_Name = 'MediaLibrary'
        $Media = $item
      }elseif($item.Playlist_Name){
        $From_Playlist_Name = $item.Playlist_Name
      }
      if($thisApp.Config.Verbose_logging -or $thisApp.Config.Log_Level -ge 3){
        write-ezlogs "d.source $($d.source | Select-Object *)" -showtime -Dev_mode
        write-ezlogs "d.source.parent $($d.source.parent | Select-Object *)" -showtime -Dev_mode
      }
      write-ezlogs "[DragDrop] originalsource $($d.originalsource | out-string)" -Dev_mode
      if($d.originalsource.datacontext.Name -eq 'Play_Queue' -or $d.originalsource.TemplatedParent.Name -eq 'PlayQueue_TreeView' -or $d.Source.Name -in 'PlayQueue_TreeView_Library','PlayQueue_TreeView'){
        $to_Playlist_Name = 'Play Queue'
      }elseif($d.originalsource.datacontext.Playlist_name){
        $to_Playlist_Name = $d.originalsource.datacontext.Playlist_name    
      }elseif($d.source.parent.Header.title){
        $to_Playlist_Name = $d.source.parent.Header.title
      }elseif($d.originalsource.TemplatedParent.Parent.header.title){
        $to_Playlist_Name = $d.originalsource.TemplatedParent.Parent.header.title
      }

      #write-ezlogs "d.header $($item.header | out-string)" -showtime
      #write-ezlogs "d.parent.header $($item.parent.header| out-string)" -showtime
      #write-ezlogs "d.source.SelectedItem.parent $($d.source.SelectedItem.parent | out-string)" -showtime
      #write-ezlogs "d.source.SelectedItem.parent $($d.source.SelectedItem.parent.header | out-string)" -showtime
      #write-ezlogs "d.source.parent $($d.source.parent | out-string)" -showtime
      #write-ezlogs "d.originalsource $( $d.originalsource | out-string)" -showtime
      #write-ezlogs "d.originalsource.parent $( $d.originalsource.parent | out-string)" -showtime
      #write-ezlogs "d.originalsource.TemplatedParent $( $d.originalsource.TemplatedParent | out-string)" -showtime
      #write-ezlogs "d.originalsource.parent.TemplatedParent $( $d.originalsource.parent.TemplatedParent | out-string)" -showtime
      #write-ezlogs "d.originalsource.TemplatedParent.TemplatedParent.SelectedItem $( $d.originalsource.TemplatedParent.TemplatedParent.SelectedItem | out-string)" -showtime
      #write-ezlogs "d.originalsource.TemplatedParent.TemplatedParent.SelectedItem.parent.header $( $d.originalsource.TemplatedParent.TemplatedParent.SelectedItem.parent.header | out-string)" -showtime
      $from_Playlist = $item.parent.Header
      $to_PlayList = $d.originalsource.datacontext
      <#      if(!$to_playlist -and $d.originalsource.TemplatedParent.Parent.header.Playlist_ID){
          $to_playlist = $d.originalsource.TemplatedParent.Parent.header.Playlist_ID
      }#>
      #write-ezlogs "sender.items.Name $($sender.items.Name)"
      write-ezlogs ">>>> Drag/Drop From Playlist Name: $($From_Playlist_Name)" -showtime
      write-ezlogs ">>>> Drag/Drop To Playlist Name $($to_Playlist_Name)" -showtime
      write-ezlogs ">>>> to_playlist $($to_playlist)" -showtime
      if($to_Playlist_Name -eq 'Play Queue'){      
        Write-EZLogs "[DragDrop] Adding Media: $($media.title) to queue" -warning  
        if($from_Playlist_Name -eq $to_Playlist_Name){
          $d.Handled = $false 
          $d.Effects = [System.Windows.DragDropEffects]::Move 
          $synchash.Playqueuedrop_update_timer = [System.Windows.Threading.DispatcherTimer]::new()         
          $synchash.Playqueuedrop_update_timer.add_tick({
              try{               
                $Play_Queue = $syncHash.PlayQueue_TreeView.items                
                [Void]$thisApp.config.Current_Playlist.clear()
                Update-PlayQueue -synchash $synchash -thisApp $thisApp -Add -media $Play_Queue -Use_RunSpace -RefreshQueue
                $this.Stop()
              }catch{
                $this.Stop()
                write-ezlogs "An exception occurred in Playqueuedrop_update_timer" -showtime -catcherror $_
              }
          })
          $synchash.Playqueuedrop_update_timer.start() 
        }else{
          Update-PlayQueue -synchash $synchash -thisApp $thisApp -Add -media @($media) -Use_RunSpace -RefreshQueue
          $d.Handled = $true
          #$d.Handled = $true
          #$synchash.update_Queue_timer.start() 
        }                  
        #$synchash.PlayQueue_TreeView.items.refresh()             
        #
        #$synchash.update_status_timer.start()                           
      }elseif($From_Playlist_Name -eq 'MediaLibrary' -and $to_Playlist_Name){
        try{
          $d.Effects = [System.Windows.DragDropEffects]::Copy
          $d.Handled = $false
          write-ezlogs "[Drag/Drop] >>>> Adding $($media.title) to playlist $($to_Playlist_Name)" -showtime
          $Playlist_To_Add = Get-IndexesOf $synchash.all_playlists.name -Value $to_Playlist_Name | & { process {
              if($synchash.all_playlists -is [System.Windows.Data.CollectionView]){
                $synchash.all_playlists.GetItemAt($_)
              }else{
                $synchash.all_playlists[$_]
              }
          }}
          if($Playlist_To_Add){               
            Add-Playlist -Media $media -Playlist $to_Playlist_Name -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging -Use_RunSpace -Update_UI -Export_PlaylistsCache
            $d.Handled = $true
          }
        }catch{
          $d.Handled = $true
          write-ezlogs "An exception occurred adding $($Media.id) from $($media.source) to Playlist $to_Playlist_Name" -showtime -catcherror $_
          $error.clear()
        }    
      }elseif($synchash.all_playlists -and $to_Playlist_Name -and $to_Playlist_Name -ne $From_Playlist_Name){
        try{
          $d.Effects = [System.Windows.DragDropEffects]::Move
          foreach($m in $media){
            write-ezlogs ">>>> Updating playlists for media $($m.title) - $($m.id)" -loglevel 3
            Update-Playlist -Playlist $From_Playlist_Name -media $Media -synchash $synchash -thisApp $thisApp -Remove -no_UIRefresh      
          }
          Add-Playlist -Media $media -Playlist $to_Playlist_Name -thisApp $thisapp -synchash $synchash
          Get-Playlists -verboselog:$thisApp.Config.Verbose_Logging -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -Startup -use_Runspace
          $d.Handled = $true
        }catch{
          $d.Handled = $true
          write-ezlogs "An exception occurred moving $($Media.id) from Playlist $($from_Playlist_Name) to Playlist $to_Playlist_Name" -showtime -catcherror $_
          $error.clear()
        }    
      }elseif($From_Playlist_Name -eq $to_Playlist_Name){
        try{
          $d.Effects = [System.Windows.DragDropEffects]::Move 
          $d.Handled = $false                  
          #write-ezlogs ">>>> Reordering track $($Media.title) in playlist $($From_Playlist_Name)" -showtime
          if($syncHash.Playlists_TreeView.itemssource.SourceCollection){
            $Playlist_items = Get-IndexesOf $syncHash.Playlists_TreeView.itemssource.SourceCollection.Title -Value $From_Playlist_Name | & { process {
                $syncHash.Playlists_TreeView.itemssource.SourceCollection[$_].items
            }}
            #$Playlist_items = ($syncHash.Playlists_TreeView.itemssource.SourceCollection | Where-Object {$_.Title -eq $From_Playlist_Name}).items
          }else{
            $Playlist_items = Get-IndexesOf $syncHash.Playlists_TreeView.itemssource.Title -Value $From_Playlist_Name | & { process {
                $syncHash.Playlists_TreeView.itemssource[$_]
            }}
            #$Playlist_items = ($syncHash.Playlists_TreeView.itemssource | Where-Object {$_.Title -eq $From_Playlist_Name})
          }
          $Playlist_To_Update = $synchash.all_playlists | Where-Object {$_.Playlist_tracks.values.id -eq $Media.id -and $_.Name -eq $From_Playlist_Name} 
          <#          if($Playlist_To_Update){
              if(($Playlist_To_Update.PlayList_tracks.GetType()).name -notmatch 'OrderedDictionary'){$Playlist_To_Update.PlayList_tracks = ConvertTo-OrderedDictionary -hash ($Playlist_To_Update.PlayList_tracks)}
          }#>
          write-ezlogs "Playlist_To_Update: $($Playlist_To_Update | out-string)" -Dev_mode
          $Playlist_update_timer = [System.Windows.Threading.DispatcherTimer]::new()         
          $Playlist_update_timer.add_tick({
              try{               
                #write-ezlogs "Playlist to update before: $($Playlist_To_Update.Playlist_tracks.Title | out-string)"                        
                if($Playlist_To_Update.Playlist_tracks.values -and $Playlist_items.tag.media){
                  $Playlist_to_Update.PlayList_tracks.clear()
                  $indextoAdd = 0
                  foreach($item in $Playlist_items.tag.media){
                    if($Verboselog){write-ezlogs " | Adding $($item.title) - index: $($indextoAdd) to playlist $($Playlist_to_Update.name)" -showtime}
                    if($Playlist_to_Update.PlayList_tracks.values.id -notcontains $item.id){
                      [Void]$Playlist_to_Update.PlayList_tracks.add($indextoAdd,$item)
                      $indextoAdd++
                    }
                    #[Void]$Updated_Playlist.add($item)
                  }
                  $d.Handled = $false                
                }else{
                  write-ezlogs "Unable to find Playlist($playlist_to_update) to update for media $($Media.title) - $($Media.id)" -showtime -warning
                  $d.Handled = $true
                }                           
                $this.Stop()
              }catch{
                $this.Stop()
                write-ezlogs "An exception occurred in playlist_update_timer" -showtime -catcherror $_
              }
          })                   
          $Playlist_update_timer.start()
          Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace
          #$syncHash.Playlists_TreeView.itemssource.refresh()
          return                                              
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
  }catch{
    write-ezlogs "An exception occurred in PreviewDrop_command" -catcherror $_
  }     
}


$synchash.TreeViewDropped_command = {
  Param(
    [System.Object]$sender,
    [Syncfusion.UI.Xaml.TreeView.TreeViewItemDroppedEventArgs]$e
  )
  try{
    #write-ezlogs "[TreeViewDropped] >>>> e.TargetNode $($e.TargetNode | out-string)" -showtime 
    #write-ezlogs "[TreeViewDropped] >>>> e.DraggingNodes $($e.DraggingNodes | out-string)" -showtime 
    #$SourceNode = $e.data.GetData('Nodes')
    #write-ezlogs "[TreeViewDropped] >>>> e.data formats: $($e.data.GetFormats() | out-string)" -showtime
    #write-ezlogs "[TreeViewDropped] >>>> e.TargetNode $($e.TargetNode | out-string)" -showtime 
    #write-ezlogs "[TreeViewDropped] >>>> e $($e | out-string)" -showtime 
    #write-ezlogs "[TreeViewDropped] >>>> e.data formats: $($e.data.GetFormats() | out-string)" -showtime
    $SourceNode = $e.data.GetData('Records')
    #write-ezlogs "[TreeViewDropped] >>>> Records: $($SourceNode | out-string)" -showtime
    $SourceDataGrid = $e.data.GetData('SourceDataGrid')
    #write-ezlogs "[TreeViewDropped] >>>> SourceDataGrid: $($SourceDataGrid | out-string)" -showtime
    $Target_PlaylistNode = $e.TargetNode.ParentNode
    $Target_Node = $e.TargetNode.Content
    if($SourceDataGrid -and $SourceNode.ID){
      $Nodes = $SourceNode
    }elseif($e.DraggingNodes.Content){
      $Nodes = $e.DraggingNodes.Content
    }
    if($e.DropPosition -eq [Syncfusion.UI.Xaml.TreeView.DropPosition]::DropAsChild -and $e.TargetNode.Content.Name -ne 'Playlist'){
      write-ezlogs "[TreeViewDropped] Cannot drop item as child as target is not playlist -- Target Name: $($e.TargetNode.Content.Name)" -warning
      return
    }elseif($e.TargetNode.Content.Name -eq 'Playlist' -and $Nodes.ID){
      write-ezlogs "[TreeViewDropped] >>>> New dragdrop for node ID: $($Nodes.ID) -- from playlist: $($e.TargetNode.Content.title) -- To playlist: $($Target_PlaylistNode.Content.Title) -- DropPosition: $($e.DropPosition)" -showtime
      Add-Playlist -Media $Nodes.ID -Playlist $e.TargetNode.Content.title -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging -Use_RunSpace -Export_PlaylistsCache -Update_UI
      return
    }elseif($e.DropPosition -ne [Syncfusion.UI.Xaml.TreeView.DropPosition]::None){
      if($Nodes.Playlist_ID){
        if($Target_PlaylistNode.ChildNodes.Content -and $Target_PlaylistNode.Content.title){
          $Position = $e.DropPosition
          if($Target_PlaylistNode.Content.id -notcontains $Nodes.id){
            $Media = $nodes
            $clearplaylist = $false
          }else{
            $media = $Target_PlaylistNode.ChildNodes.Content
            $clearplaylist = $true
          }
          write-ezlogs "[TreeViewDropped] | Updating existing playlist: $($Target_PlaylistNode.Content.title) -- Nodes: $($Nodes | out-string)"
          Add-Playlist -Media $media -Playlist $Target_PlaylistNode.Content.title -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging -Use_RunSpace -Export_PlaylistsCache -Update_UI -position $Position -PositionTargetMedia $Target_Node -ClearPlaylist:$clearplaylist
          #Add-Playlist -Media $Target_PlaylistNode.ChildNodes.Content -Playlist $Target_PlaylistNode.Content.title -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging -Use_RunSpace -Export_PlaylistsCache -ClearPlaylist -Update_UI -position $Position -PositionTargetMedia $Target_Node
        } 
      }      
    }else{
      write-ezlogs "[TreeViewDropped] Unable to determine what to do with drag dropped event: $($e | out-string)" -warning
    }
  }catch{
    write-ezlogs "An exception occurred in TreeViewDropped_command" -catcherror $_
  }     
}
$synchash.TreeViewDropping_command = {
  Param(
    [System.Object]$sender,
    [Syncfusion.UI.Xaml.TreeView.TreeViewItemDroppingEventArgs]$e
  )
  try{     
    if($e.TargetNode.Content.Name -eq 'Playlist'){
      $Target_PlaylistNode = $e.TargetNode     
    }else{
      $Target_PlaylistNode = $e.TargetNode.ParentNode
    } 
    $SourceDataGrid = $e.data.GetData('SourceDataGrid')
    if($SourceDataGrid.SelectedItems){
      $SourceNode = $SourceDataGrid.SelectedItems
    }else{
      $SourceNode = $e.data.GetData('Records')
    }
    if($e.DropPosition -eq [Syncfusion.UI.Xaml.TreeView.DropPosition]::DropAsChild -and $Target_PlaylistNode.Content.Name -ne 'Playlist'){
      $e.Handled = $true
      write-ezlogs "[TreeViewDropping] Cannot drop item as child as target is not playlist -- Target Name: $($e.TargetNode.Content.Name)" -warning
      return
    }elseif($SourceDataGrid -and $SourceNode.ID -and $e.DropPosition -ne [Syncfusion.UI.Xaml.TreeView.DropPosition]::None){           
      if($SourceNode.Playlist_ID -and ('Track' -in $SourceNode.Name -or 'Playlist' -in $SourceNode.Name)){
        if($Target_PlaylistNode.ChildNodes.Content -and $Target_PlaylistNode.Content.title){    
          write-ezlogs "[TreeViewDropping] | Adding to playlist: $($Target_PlaylistNode.Content.title) with content: $($Target_PlaylistNode.ChildNodes.Content.Title)"             
          Add-Playlist -Media $Target_PlaylistNode.ChildNodes.Content -Playlist $Target_PlaylistNode.Content.title -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging -Use_RunSpace -Export_PlaylistsCache -ClearPlaylist -Update_UI
        } 
      }elseif($SourceNode.ID -and $Target_PlaylistNode.Content.Title){
        write-ezlogs "[TreeViewDropping] >>>> New dragdrop for node IDs: $($SourceNode.ID) -- Title: $($SourceNode.Title) -- from datagrid: $($SourceDataGrid.Name) -- To playlist: $($Target_PlaylistNode.Content.Title) -- DropPosition: $($e.DropPosition)" -showtime
        Add-Playlist -Media $SourceNode.ID -Playlist $Target_PlaylistNode.Content.Title -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging -Use_RunSpace -Export_PlaylistsCache -Update_UI            
      }else{
        write-ezlogs "[TreeViewDropping] Unable to determine what to do with drag dropped node: $($SourceNode | out-string) -- TargetNode: $($Target_PlaylistNode | out-string)" -warning
        $e.Handled = $true
      }      
    }  
  }catch{
    write-ezlogs "An exception occurred in TreeViewDropping_command" -catcherror $_
  }     
}
$synchash.TreeViewDragStarting_command = {
  Param(
    [System.Object]$sender,
    [Syncfusion.UI.Xaml.TreeView.TreeViewItemDragStartingEventArgs]$e
  )
  try{
    if('Playlist' -in $e.DraggingNodes.Content.Name){
      write-ezlogs "[TreeViewDragStarting] Cannot drag item as it is a playlist -- Title: $($e.DraggingNodes.Content.Title)" -warning
      $e.Cancel = $true      
      return
    }   
  }catch{
    write-ezlogs "An exception occurred in TreeViewDropping_command" -catcherror $_
  }     
}
if($syncHash.Playlists_TreeView){
  [Void]$syncHash.Playlists_TreeView.add_ItemDropped($synchash.TreeViewDropped_command)
  [Void]$syncHash.Playlists_TreeView.add_ItemDropping($synchash.TreeViewDropping_command)
  [Void]$syncHash.Playlists_TreeView.add_ItemDragStarting($synchash.TreeViewDragStarting_command)
}
if($syncHash.LocalMedia_TreeView){
  [Void]$syncHash.LocalMedia_TreeView.add_ItemDropped($synchash.TreeViewDropped_command)
  [Void]$syncHash.LocalMedia_TreeView.add_ItemDropping($synchash.TreeViewDropping_command)
  [Void]$syncHash.LocalMedia_TreeView.add_ItemDragStarting($synchash.TreeViewDragStarting_command)
}
if($syncHash.TrayPlayer_TreeView){
  [Void]$syncHash.TrayPlayer_TreeView.add_ItemDropped($synchash.TreeViewDropped_command)
  [Void]$syncHash.TrayPlayer_TreeView.add_ItemDropping($synchash.TreeViewDropping_command)
  [Void]$syncHash.TrayPlayer_TreeView.add_ItemDragStarting($synchash.TreeViewDragStarting_command)
}

#Drag/Drop Commands
if($syncHash.PlayQueue_TreeView){
  [Void]$syncHash.PlayQueue_TreeView.add_PreviewDrop($synchash.PreviewDrop_Command)
}
if($syncHash.PlayQueue_TreeView_Library){
  [Void]$syncHash.PlayQueue_TreeView_Library.add_PreviewDrop($synchash.PreviewDrop_Command)
}
if($syncHash.MediaTable){
  $syncHash.MediaTable.add_PreviewDrop($synchash.PreviewDrop_Command)
}
if($syncHash.YoutubeTable){
  $syncHash.YoutubeTable.add_PreviewDrop($synchash.PreviewDrop_Command)
}
if($syncHash.TwitchTable){
  $syncHash.TwitchTable.add_PreviewDrop($synchash.PreviewDrop_Command)
}
if($syncHash.SpotifyTable){
  $syncHash.SpotifyTable.add_PreviewDrop($synchash.PreviewDrop_Command)
}

#---------------------------------------------- 
#endregion DragDrop Handlers
#----------------------------------------------

#---------------------------------------------- 
#region Add to Playlist
#----------------------------------------------
$synchash.Add_to_Playlist_timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.Add_to_Playlist_timer.add_Tick({
    try{
      $Playlist = $this.tag.Add_to_Playlist
      $Selected_Media = $this.tag.Selected_Media
      $sender = $this.tag.sender
      #$playlist_items = $this.tag.playlist_items
      write-ezlogs ">>>> Adding to playlist: $($Playlist) - Number of media: $($Selected_Media.count)" -showtime
      #write-ezlogs " | Selected media $($Selected_Media | out-string)" -showtime
      #write-ezlogs " | Sender $($sender.tag.Datacontext | out-string)" -showtime
      if($Playlist -in 'Play Queue','Add to Play Queue','Add Playlist to Play Queue' -and $Selected_Media){   
        Update-PlayQueue -synchash $synchash -thisApp $thisApp -Add -media @($Selected_Media) -Use_RunSpace -RefreshQueue
        return   
      }elseif($Playlist -eq 'Play'){     
        if($sender.tag.source.Name -eq 'Play_Queue'){
          $Selected_Media = $synchash.PlayQueue_TreeView.Items.tag.media
        }
        if(!$Selected_Media){
          $Selected_Media = $sender.tag.datacontext.items
        }
        if($sender.tag.source.Name -ne 'Play_Queue'){       
          if($Selected_Media){
            Update-PlayQueue -synchash $synchash -thisApp $thisApp -Add -media @($Selected_Media) -Use_RunSpace -RefreshQueue
          }
        }else{
          write-ezlogs ">>>> Saving app config: $($thisapp.Config.Config_Path)" -showtime
          Export-SerializedXML -InputObject $thisApp.Config -Path $thisapp.Config.Config_Path -isConfig
          Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchashWeak ([System.WeakReference]::new($synchash)) -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -use_Runspace #-Full_Refresh   
          Get-PlayQueue -verboselog:$false -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace
        }
        $start_media = $Selected_Media | Select-Object -first 1
        if(!$start_media.url -and $start_media.tag.media){
          $start_media = $start_media.tag.media
        }
        if(!$start_media.url){
          write-ezlogs "Unable to find media to start from selected media! See logs for details" -warning -AlertUI
          write-ezlogs "Selected media: $($Selected_Media | out-string)" -warning
          return
        }
        write-ezlogs ">>>> Starting playback of $($start_media.title)" -showtime
        $synchash.Current_Playing_Playlist_Source = 'Playlist'
        if($start_media.source -eq 'Spotify' -or $start_media.url -match 'spotify\:'){
          Start-SpotifyMedia -Media $start_media -thisApp $thisapp -synchash $synchash -use_WebPlayer:$thisapp.config.Spotify_WebPlayer -Show_notifications:$thisApp.config.Show_notifications -RestrictedRunspace:$thisapp.config.Spotify_WebPlayer
        }else{
          Start-Media -media $start_media -thisApp $thisapp -synchashWeak ([System.WeakReference]::new($synchash)) -Show_notification 
        }
        return                   
      }elseif($Selected_Media){
        write-ezlogs "| Adding $($Selected_Media.count) items to Playlist $Playlist" -showtime
        Add-Playlist -Media $Selected_Media -Playlist $Playlist -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging -Use_RunSpace -Update_UI
        return
      }else{
        write-ezlogs 'Selected media was null! Unable to do anything!' -showtime -warning
      }
      #Export-SerializedXML -InputObject $thisApp.Config -Path $thisapp.Config.Config_Path -isConfig
      #Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchashWeak ([System.WeakReference]::new($synchash)) -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -use_Runspace #-Full_Refresh
      #Get-PlayQueue -verboselog:$false -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace
    }catch{
      write-ezlogs "An exception occurred in Add_to_Playlist_timer " -showtime -catcherror $_
      $this.Stop()
    }finally{
      $this.tag = $Null
      $this.Stop()
    } 
})

[System.Windows.RoutedEventHandler]$synchash.Add_to_PlaylistCommand = {
  param($sender)
  try{
    #write-ezlogs "sender.header: $($sender.header | out-string)"
    #write-ezlogs "sender.parent.header: $($sender.parent.header | out-string)"
    #write-ezlogs "sender.tag.Datacontext: $($sender.tag.Datacontext | out-string)"
    if($sender.datacontext.Playlist_ID){
      $PlaylistID = $sender.datacontext.Playlist_ID
      $Playlist = $sender.datacontext.title
    }elseif($sender.tag.Source.Selecteditem.Playlist_ID){
      $Playlist = $sender.tag.Source.Selecteditem.title
      $PlaylistID = $sender.tag.Source.Selecteditem.Playlist_ID
    }elseif($sender.tag.datacontext.Playlist_ID){
      $Playlist = $sender.tag.datacontext.title
      $PlaylistID = $sender.tag.datacontext.Playlist_ID
    }elseif($sender.datacontext.content.Playlist_ID){
      $Playlist = $sender.datacontext.content.title
      $PlaylistID = $sender.datacontext.content.Playlist_ID
    }
    if($sender.datacontext.id){
      $Media = $sender.datacontext
    }elseif($sender.datacontext.record.id){
      $Media = $sender.datacontext.record
    }elseif($sender.datacontext.content.id){
      $Media = $sender.datacontext.content
    }
    if($sender.parent.header -eq 'Add Artist to...' -and $Media.Artist){
      $Selected_Media = foreach($artist in $Media.Artist){
        Get-IndexesOf $synchash.All_local_Media.artist -Value $artist | & { process {
            $synchash.All_local_Media[$_]
        }}
        Get-IndexesOf $synchash.All_Spotify_Media.artist -Value $artist | & { process {
            $synchash.All_Spotify_Media[$_]
        }}
        Get-IndexesOf $synchash.All_Youtube_Media.artist -Value $artist | & { process {
            $synchash.All_Youtube_Media[$_]
        }}
        Get-IndexesOf $synchash.All_Twitch_Media.artist -Value $artist | & { process {
            $synchash.All_Twitch_Media[$_]
        }}
      }
      write-ezlogs "Found $($Selected_Media.count) media of artist: $($Media.Artist)"
    }elseif($sender.parent.header -eq 'Add Album to...' -and $Media.Album){
      $Selected_Media = foreach($album in $Media.Album){
        Get-IndexesOf $synchash.All_local_Media.Album -Value $album | & { process {          
            if($synchash.All_local_Media[$_].Artist -in $Media.Artist){
              $synchash.All_local_Media[$_]
            }
        }}
        Get-IndexesOf $synchash.All_Spotify_Media.Album -Value $album | & { process {
            if($synchash.All_Spotify_Media[$_].Artist -in $Media.Artist){
              $synchash.All_Spotify_Media[$_]
            }  
        }}
        Get-IndexesOf $synchash.All_Youtube_Media.Album -Value $album | & { process {
            if($synchash.All_Youtube_Media[$_].Artist -in $Media.Artist){
              $synchash.All_Youtube_Media[$_]
            }
        }}
      }
      write-ezlogs "Found $($Selected_Media.count) media of album: $($Media.Album)"
    }elseif($sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.Content){
      $Selected_Media = $sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.Content
      write-ezlogs "Found $($Selected_Media.count) media from sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.Content"
    }elseif($sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.id){
      $Selected_Media = $sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems
      write-ezlogs "Found $($Selected_Media.count) media from sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems"
    }elseif($sender.tag.source.selecteditems.content.id){
      $Selected_Media = $sender.tag.source.selecteditems.content
      write-ezlogs "Found $($Selected_Media.count) media from sender.tag.source.selecteditems.content"
    }elseif($sender.tag.source.Name -eq 'YoutubeTable'){
      $Selected_Media = $synchash.YoutubeTable.selecteditems
      write-ezlogs "Found $($Selected_Media.count) media from YoutubeTable.selecteditems"
    }elseif($sender.tag.source.Name -eq 'SpotifyTable'){
      $Selected_Media = $synchash.SpotifyTable.selecteditems
      write-ezlogs "Found $($Selected_Media.count) media from SpotifyTable.selecteditems"
    }elseif($sender.tag.source.Name -eq 'MediaTable'){
      $Selected_Media = $synchash.MediaTable.selecteditems
      write-ezlogs "Found $($Selected_Media.count) media from MediaTable.selecteditems"
    }elseif($sender.tag.source.Name -eq 'TwitchTable'){
      $Selected_Media = $synchash.TwitchTable.selecteditems
      write-ezlogs "Found $($Selected_Media.count) media from TwitchTable.selecteditems"
    }elseif($sender.tag.Media.id){
      $Selected_Media = $sender.tag.Media
      write-ezlogs "Found $($Selected_Media.count) media from sender.tag.Media"
    }elseif($sender.datacontext.id){
      $Selected_Media = $sender.datacontext
      write-ezlogs "Found $($Selected_Media.count) media from sender.datacontext"
    }elseif($sender.header -in 'Add Playlist to Play Queue','Add to Play Queue','Play','Play Queue'){
      if($PlaylistID  -and $synchash.all_playlists.Playlist_ID){
        $Selected_Media = lock-object -InputObject $synchash.all_playlists_ListLock -ScriptBlock {
          $index = $synchash.all_playlists.Playlist_ID.IndexOf($PlaylistID )
          if($index -ne -1){    
            if($synchash.all_playlists -is [System.Windows.Data.CollectionView]){
              $synchash.all_playlists.GetItemAt($index).PlayList_tracks.values
            }else{
              $synchash.all_playlists[$index].PlayList_tracks.values
            }
          }
        }
        write-ezlogs "Found $($Selected_Media.count) media from playlist id: $($PlaylistID)"
      }
    }else{
      $Selected_Media = $Null
    } 
    $AddToPlaylist_Items = @{
      'sender' = $sender
      'Add_to_Playlist' = $sender.header
      'Selected_Media' = $Selected_Media
    }   
    $synchash.Add_to_Playlist_timer.tag = $AddToPlaylist_Items
    $synchash.Add_to_Playlist_timer.start()
  }catch{
    write-ezlogs "An exception occurred in Add_to_PlaylistCommand" -showtime -catcherror $_
  }
}
[System.Windows.RoutedEventHandler]$synchash.Add_to_New_PlaylistCommand = {
  param($sender) 
  #$playlist_id = $sender.tag.Source.Selecteditem.playlist_id
  #$Playlist = $sender.DataContext.title
  if($sender.datacontext.Playlist_ID){
    $playlist_id = $sender.datacontext.Playlist_ID
    $Playlist = $sender.datacontext.title
  }elseif($sender.tag.Source.Selecteditem.Playlist_ID){
    $Playlist = $sender.tag.Source.Selecteditem.title
    $playlist_id = $sender.tag.Source.Selecteditem.Playlist_ID
  }elseif($sender.tag.datacontext.Playlist_ID){
    $Playlist = $sender.tag.datacontext.title
    $playlist_id = $sender.tag.datacontext.Playlist_ID
  }elseif($sender.datacontext.content.Playlist_ID){
    $Playlist = $sender.datacontext.content.title
    $playlist_id = $sender.datacontext.content.Playlist_ID
  }
  write-ezlogs ">>>> Rename Playlist Name: $($Playlist)" -showtime -Dev_mode
  $Media = $sender.tag.Media 
  $mediaid = $Media.id
  if(!$mediaid){
    $mediaid = $sender.tag.Source.Selecteditem.id
  }
  if(!$media.url -and $playlist_id -and $synchash.all_playlists.Playlist_ID){
    $pindex = $synchash.all_playlists.Playlist_ID.IndexOf($playlist_id)
    if($pindex -ne -1){               
      if($synchash.all_playlists -is [System.Windows.Data.CollectionView]){
        $playlist_lookup = $synchash.all_playlists.GetItemAt($pindex)
      }else{
        $playlist_lookup = $synchash.all_playlists[$pindex]
      }
    }
    if($mediaid -and $playlist_lookup.playlist_tracks.values.id){
      $mindex = $playlist_lookup.playlist_tracks.values.id.IndexOf($mediaid)
      if($mindex -ne -1){
        $media = $playlist_lookup.playlist_tracks[$mindex]
      }
    }
    #$playlist_lookup = $synchash.All_playlists.where({$_.playlist_id -eq $playlist_id})
    #$media = $playlist_lookup.playlist_tracks.values | Where-Object {$_.id -eq $mediaid}
    #$media = $sender.datacontext
  }
  #write-ezlogs "Media: $($media | out-string)" -showtime -dev_mode
  $Playlist_Directory_Path = [System.IO.Path]::Combine($thisApp.config.Playlist_Profile_Directory,'Custom-Playlists')
  write-ezlogs "Prompting for new playlist name for ($Playlist)..." -showtime
  try{
    $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()    
    #$customdialog = [MahApps.Metro.Controls.Dialogs.CustomDialog]::new($synchash.Window,$Button_Settings)
    #$resource = [System.Windows.ResourceDictionary]::new()
    #$theme = [MahApps.Metro.Theming.MahAppsLibraryThemeProvider]::new()
    #$newtheme = $theme.GetLibraryThemes() | Where-Object {$_.Name -eq 'Dark.Blue'}
    #$themeManager = [ControlzEx.Theming.ThemeManager]::Current.GetTheme('Dark.Blue')
    #$resource.Source = "$($thisApp.Config.Current_Folder)`\Views`\InputDialog.xaml"
    #$button_settings.CustomResourceDictionary = $newtheme.Resources
    #$buttonStyle = $button_settings.CustomResourceDictionary
    #write-ezlogs "styel $($buttonStyle | out-string)"
    if($synchash.MediaLibrary_Viewer.isVisible){
      $DialogWindow = $synchash.MediaLibrary_Viewer
    }else{
      $DialogWindow = $synchash.Window
    }
    if($sender.header -eq 'Rename Playlist'){
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($DialogWindow,"Rename Playlist $Playlist",'Enter the new name of the playlist',$Button_Settings)
    }else{
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($DialogWindow,'Add New Playlist','Enter the name of the new playlist',$Button_Settings)
    }
    if(-not [string]::IsNullOrEmpty($result)){   
      $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars())
      $pattern = "[™`�$illegal]"
      $result = ([Regex]::Replace($result, $pattern, '')).trim() 
      [int]$character_Count = ($result | measure-object -Character -ErrorAction SilentlyContinue).Characters
      if([int]$character_Count -ge 100){
        write-ezlogs "Playlist name too long! ($character_Count characters). Please choose a name 100 characters or less " -showtime -warning
        $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
        $Button_Settings.AffirmativeButtonText = 'Ok'
        $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
        $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Playlist name too long! ($character_Count)","Please choose a name for the playlist that is 100 characters or less",$okandCancel,$Button_Settings)
        return
      }
    }
    if(-not [string]::IsNullOrEmpty($result)){ 
      if($sender.header -eq 'Create Playlist from Queue'){
        write-ezlogs "Creating new playlist $result from Play Queue " -showtime -warning    
        Add-Playlist -Media $synchash.PlayQueue_TreeView.Items -Playlist $result -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging -Use_RunSpace -Update_UI -Export_PlaylistsCache
        return
      }elseif($sender.header -eq 'Save as New Playlist'){  
        if($sender.datacontext.Playlist_ID){
          $playlist_id = $sender.datacontext.Playlist_ID
        }elseif($sender.tag.Source.Selecteditem.Playlist_ID){
          $playlist_id = $sender.tag.Source.Selecteditem.Playlist_ID
        }elseif($sender.tag.datacontext.Playlist_ID){
          $playlist_id = $sender.tag.datacontext.Playlist_ID
        }     
        if($playlist_id -and $synchash.all_playlists.Playlist_ID){
          $playlist_items = lock-object -InputObject $synchash.all_playlists_ListLock -ScriptBlock { 
            if($synchash.all_playlists.Playlist_ID){               
              $index = $synchash.all_playlists.Playlist_ID.IndexOf($playlist_id)
              if($index -ne -1){    
                if($synchash.all_playlists -is [System.Windows.Data.CollectionView]){
                  $playlist = $synchash.all_playlists.GetItemAt($index).PlayList_tracks.values
                }else{
                  $playlist = $synchash.all_playlists[$index].PlayList_tracks.values
                }
              }  
            }
          }
        }else{
          write-ezlogs "Unable to find playlist to copy! -- Sender: $($sender | out-string) - Sender.datacontext: $($Sender.datacontext | out-string)" -warning
        }
        #$sourceplaylist = $synchash.All_playlists | Where-Object {$_.playlist_id -eq $playlist_id}
        write-ezlogs "Creating new playlist $result from playlist: $($playlist | Out-String) " -showtime -warning
        #$playlist_items = $sourceplaylist.playlist_tracks.values           
        if(!$playlist_items -and (Test-URL $Media.uri) -or (Test-URL $Media.url)){
          $playlist_items = $Media
        }  
        Add-Playlist -Media $playlist_items -Playlist $result -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging -Use_RunSpace -Update_UI -Export_PlaylistsCache
        return
      }elseif($sender.parent.header -in 'Add Artist to...','Add Album to...' -or $sender.header -in 'Add Artist to...','Add Album to...','New Playlist'){ 
        write-ezlogs "Adding media to new playlist $($result)" -showtime -warning
        if($sender.header -eq 'Add Artist to...' -or $sender.parent.header -eq 'Add Artist to...'){
          $playlist_items = foreach($artist in $Media.artist){
            Get-IndexesOf $synchash.All_local_Media.artist -Value $artist | & { process {
                $synchash.All_local_Media[$_]
            }}
            Get-IndexesOf $synchash.All_Spotify_Media.artist -Value $artist | & { process {
                $synchash.All_Spotify_Media[$_]
            }}
            Get-IndexesOf $synchash.All_Youtube_Media.artist -Value $artist | & { process {
                $synchash.All_Youtube_Media[$_]
            }}
            Get-IndexesOf $synchash.All_Twitch_Media.artist -Value $artist | & { process {
                $synchash.All_Twitch_Media[$_]
            }}
          }
        }elseif($sender.header -eq 'Add Album to...' -or $sender.parent.header -eq 'Add Album to...'){
          $playlist_items = foreach($album in $Media.album){
            Get-IndexesOf $synchash.All_local_Media.album -Value $album | & { process {
                if($synchash.All_local_Media[$_].Artist -in $Media.Artist){
                  $synchash.All_local_Media[$_]
                }
            }}
            Get-IndexesOf $synchash.All_Spotify_Media.album -Value $album | & { process {
                if($synchash.All_Spotify_Media[$_].Artist -in $Media.Artist){
                  $synchash.All_Spotify_Media[$_]
                }
            }}
            Get-IndexesOf $synchash.All_Youtube_Media.album -Value $album | & { process {
                if($synchash.All_Youtube_Media[$_].Artist -in $Media.Artist){
                  $synchash.All_Youtube_Media[$_]
                }
            }}
          }
        }elseif($sender.tag.source.Name -eq 'YoutubeTable'){
          write-ezlogs " | Getting media from Youtube selected items" -loglevel 2
          $playlist_items = $synchash.YoutubeTable.selecteditems
        }elseif($sender.tag.source.Name -eq 'SpotifyTable'){
          write-ezlogs " | Getting media from SpotifyTable selected items" -loglevel 2
          $playlist_items = $synchash.SpotifyTable.selecteditems
        }elseif($sender.tag.source.Name -eq 'MediaTable'){
          write-ezlogs " | Getting media from local Media selected items" -loglevel 2
          $playlist_items = $synchash.MediaTable.selecteditems
        }elseif($sender.tag.source.Name -eq 'TwitchTable'){
          write-ezlogs " | Getting media from Twitch  selected items" -loglevel 2
          $playlist_items = $synchash.TwitchTable.selecteditems
        }elseif($sender.tag.source.TreeViewItemInfo.TreeView -is [Syncfusion.UI.Xaml.TreeView.SfTreeView]){
          $playlist_items = $sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.Content
        }elseif((Test-ValidPath $Media.uri -Type URLorFile) -or (Test-ValidPath $Media.url -Type URLorFile)){
          write-ezlogs " | Getting single media passed to routed event" -loglevel 2
          $playlist_items = $Media
        } 
        write-ezlogs "| Playlist items to add: $(($playlist_items).count)" -showtime -warning          
        Add-Playlist -Media $playlist_items -Playlist $result -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging -Use_RunSpace -Update_UI -Export_PlaylistsCache
        return
      }elseif($sender.header -eq 'Rename Playlist'){
        write-ezlogs ">>>> Renaming Playlist $($Playlist) to $($result)" -showtime -warning
        if($sender.datacontext.Playlist_ID){
          $playlist_id = $sender.datacontext.Playlist_ID
        }elseif($sender.tag.Source.Selecteditem.Playlist_ID){
          $playlist_id = $sender.tag.Source.Selecteditem.Playlist_ID
        }elseif($sender.tag.datacontext.Playlist_ID){
          $playlist_id = $sender.tag.datacontext.Playlist_ID
        } 
        $sourceplaylist = Get-IndexesOf $synchash.All_playlists.playlist_id -Value $playlist_id | & { process {
            if($synchash.all_playlists -is [System.Windows.Data.CollectionView]){
              $synchash.all_playlists.GetItemAt($_)
            }else{
              $synchash.All_Playlists[$_]
            }
        }}
        #$sourceplaylist = $synchash.All_playlists | Where-Object {$_.playlist_id -eq $playlist_id}
        if($result -eq $sourceplaylist.Name){
          write-ezlogs "Playlist name provided is the same, no action will be taken for playlist $($result)" -showtime -warning
          $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
          $Button_Settings.AffirmativeButtonText = 'Ok'
          $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
          $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Playlist name is the same","The Playlist name you provided is the same as the existing name $($result), no action will be taken",$okandCancel,$Button_Settings)
          return
        }
        if($sourceplaylist.Name -and $sourceplaylist.Name -ne $result){
          write-ezlogs "Renaming playlist from: $($sourceplaylist.Name) - to: $($result)"
          $sourceplaylist.Name = $result
        }else{
          write-ezlogs "Unable to find existing playlist profile to rename to: $($result)" -showtime -warning
          return
        }
      }elseif($media){   
        write-ezlogs "creating new empty playlist $result for media $($media.title)" -showtime -warning        
        Add-Playlist -Media $Media -Playlist $result -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging -Use_RunSpace -Update_UI -Export_PlaylistsCache
        return       
      }else{
        write-ezlogs "No media selected, creating new empty playlist $result" -showtime -warning    
        Add-Playlist -Media $Media -Playlist $result -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging -Use_RunSpace -Update_UI -Export_PlaylistsCache
        return             
      }
      write-ezlogs ">>>> Saving app config: $($thisapp.Config.Config_Path)" -showtime
      Export-SerializedXML -InputObject $thisApp.Config -Path $thisapp.Config.Config_Path -isConfig
      Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace #-Full_Refresh
    }else{
      write-ezlogs 'No valid playlist name was provided' -showtime -warning
    }
  }catch{
    write-ezlogs "An exception occurred adding $($Media.title | Out-String) to new Playlist $($Playlist)" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Add to Playlist
#----------------------------------------------

#---------------------------------------------- 
#region Export Playlists
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.Export_PlaylistCommand = {
  param($sender)
  try{
    <#    $Playlist = $sender.DataContext.title
        if(!$Playlist){
        $Playlist = $sender.tag.Source.Selecteditem.title
        }
        $PlaylistID = $sender.DataContext.Playlist_ID
        if($sender.datacontext.Playlist_ID){
        $PlaylistID = $sender.datacontext.Playlist_ID
        }elseif($sender.tag.Source.Selecteditem.Playlist_ID){
        $PlaylistID = $sender.tag.Source.Selecteditem.Playlist_ID
        }elseif($sender.tag.datacontext.Playlist_ID){
        $PlaylistID = $sender.tag.datacontext.Playlist_ID
    }#>
    if($sender.datacontext.Playlist_ID){
      $PlaylistID = $sender.datacontext.Playlist_ID
      $Playlist = $sender.datacontext.title
    }elseif($sender.tag.Source.Selecteditem.Playlist_ID){
      $Playlist = $sender.tag.Source.Selecteditem.title
      $PlaylistID = $sender.tag.Source.Selecteditem.Playlist_ID
    }elseif($sender.tag.datacontext.Playlist_ID){
      $Playlist = $sender.tag.datacontext.title
      $PlaylistID = $sender.tag.datacontext.Playlist_ID
    }elseif($sender.datacontext.content.Playlist_ID){
      $Playlist = $sender.datacontext.content.title
      $PlaylistID = $sender.datacontext.content.Playlist_ID
    }

    if($synchash.all_playlists.playlist_ID){
      $pindex = $synchash.all_playlists.playlist_ID.indexof($PlaylistID)
      if($pindex -ne -1){
        if($synchash.all_playlists -is [System.Windows.Data.CollectionView]){
          $Playlist_to_Export = $synchash.all_playlists.GetItemAt($pindex)
        }else{
          $Playlist_to_Export = $synchash.all_playlists[$pindex]
        }
      }
    }  
    if(!$Playlist_to_Export){     
      $Playlist_Path_Name = "$($Playlist)-CustomPlaylist.xml"
      $Playlist_Directory_Path = [System.IO.Path]::Combine($thisApp.config.Playlist_Profile_Directory,'Custom-Playlists')
      $Playlist_File_Path = [System.IO.Path]::Combine($Playlist_Directory_Path,$Playlist_Path_Name)  
      write-ezlogs "Cant find playlist from all_playlists cache with ID $($PlaylistID), looking for playlist at path: $Playlist_File_Path" -showtime -warning 
      if([System.IO.File]::Exists($Playlist_File_Path)){
        write-ezlogs " | Importing Playlist Profile: $Playlist_File_Path" -showtime 
        $Playlist_to_Export = Import-CliXml -Path $Playlist_File_Path
      }else{
        write-ezlogs "Unable to find playlist $($Playlist) to export at path $($Playlist_File_Path), cannot continue!" -showtime -warning
        return
      }
    }
    if($sender.header -eq 'Export Playlist' -and $Playlist_to_Export){  
      $result = Open-FileDialog -Title "Select the name and location of the export file for Playlist $($Playlist_to_Export.Name)"  -filter "XML Files (*.xml)|*.xml" -SaveDialog
      $folder = [system.IO.Path]::GetDirectoryName($result)
      if([System.IO.Directory]::Exists($folder)){
        write-ezlogs ">>>> Exporting Playlist $($Playlist_to_Export.Name) to path $result" -showtime
        Export-Clixml -InputObject $Playlist_to_Export -Path $result -Force -Encoding UTF8
      }else{
        write-ezlogs "The provided save folder $($folder) is not valid" -showtime -warning
      }
    }
  }catch{
    write-ezlogs "An exception occurred in Export_PlaylistCommand" -showtime -catcherror $_
  }
}

[System.Windows.RoutedEventHandler]$synchash.Export_AllPlaylists_Command = {
  param($sender)
  try{
    if(($synchash.all_playlists.count -lt 1)){
      write-ezlogs "Cant find playlists from all_playlists cache, looking for any playlist profiles" -showtime -warning 
      $synchash.all_playlists = [System.Collections.Generic.List[Object]]::new()     
      $playlist_pattern = [regex]::new('$(?<=((?i)Playlist.xml))')
      [System.IO.Directory]::EnumerateFiles($thisApp.config.Playlist_Profile_Directory,'*','AllDirectories').where({$_ -match $playlist_pattern}) | & { process {
          $profile_path = $null
          if([System.IO.File]::Exists($_)){
            $profile_path = $_
            if($VerboseLog){write-ezlogs ">>>> Importing Playlist profile $profile_path" -showtime -enablelogs -color cyan}
            try{
              if([System.IO.File]::Exists($profile_path)){
                $Playlist_profile = Import-CliXml -Path $profile_path
              }          
            }catch{
              write-ezlogs "An exception occurred importing Playlist profile path ($profile_path)" -showtime -catcherror $_
            }             
            $Playlist_encodedTitle = $Playlist_profile.Playlist_ID
            if($Playlist_encodedTitle -and $synchash.all_playlists.Playlist_ID -notcontains $Playlist_encodedTitle){
              try{
                [Void]$synchash.all_playlists.Add($Playlist_profile)
              }catch{
                write-ezlogs "An exception occurred adding playlist ($Playlist_encodedTitle) from path $profile_path" -showtime -catcherror $_
              }  
            }               
          }
      }}
    }
    if($synchash.all_playlists.count -gt 0){  
      $folder = Open-FolderDialog -Title "Select the directory where all playlists will exported to"
      if([System.IO.Directory]::Exists($folder)){
        write-ezlogs ">>>> Exporting All Playlists to path $folder" -showtime
        $synchash.all_playlists | & { process {
            try{
              write-ezlogs " | Exporting Playlist $($_.name) to $($folder)\$($_.name)"
              Export-Clixml -InputObject $_ -Path "$($folder)\$($_.name).xml" -Force -Encoding UTF8
            }catch{
              write-ezlogs "An exception occurred exporting Playlist $($_.name) to $($folder)\$($_.name)" -catcherror $_
            }                   
        }}
      }else{
        write-ezlogs "The provided save folder $($folder) is not valid or none was provided" -showtime -warning
      }
    }else{
      write-ezlogs "Cannot export playlists, no playlists were found!" -showtime -warning -AlertUI
    }
  }catch{
    write-ezlogs "An exception occurred in Export_PlaylistCommand" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Export Playlists
#----------------------------------------------

#---------------------------------------------- 
#region Import Playlists
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.Import_PlaylistCommand = {
  param($sender) 
  write-ezlogs 'Opening file select dialog...' -showtime
  try{
    $Playlist_Directory_Path = [System.IO.Path]::Combine($thisApp.config.Playlist_Profile_Directory,'Custom-Playlists')
    if(![System.IO.Directory]::Exists($Playlist_Directory_Path)){
      [Void][System.IO.Directory]::CreateDirectory($Playlist_Directory_Path)
    }
    $results = Open-FileDialog -Title "Select the Playlist file(s) you wish to import"  -filter "XML Files (*.xml)|*.xml" -CheckPathExists -MultiSelect
    if($results.count -gt 1){
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
      $Button_Settings.AffirmativeButtonText = 'Yes'
      $Button_Settings.NegativeButtonText = 'No'  
      $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Overwrite Playlists`?","You are importing multiple playlists. Do you wish to automatically overwrite any existing playlists found? Selecting no means you will be prompted to overwrite for each existing playlist found",$okandCancel,$Button_Settings)
      if($result -eq 'Affirmative'){
        write-ezlogs "User wished to overwrite any existing playlists found" -showtime
        $Overwrite_All = $true
      }else{
        $Overwrite_All = $false
        write-ezlogs "User did not wish to overwrite any existing playlists found" -showtime
      }
    }
    $results | & { process {
        if([system.io.file]::Exists($_)){ 
          write-ezlogs ">>>> Importing playlist profile to $_" -showtime
          #$Import_playlist_filename = [System.io.path]::GetFileName($result)
          $playlist_profile = Import-Clixml $_
          $Playlist_Path_Name = "$($playlist_profile.Name)-CustomPlaylist.xml"
          $Import_playlist_Destination_path =  [System.IO.Path]::Combine($Playlist_Directory_Path,$Playlist_Path_Name)
          if([string]::IsNullOrEmpty($playlist_profile.Playlist_ID)){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid Playlist!","The file ($($_)) does not appear to be a valid playlist profile that can be imported",$okandCancel,$Button_Settings)
            return
          }elseif($synchash.All_Playlists.id -contains $playlist_profile.Playlist_ID -and !$Overwrite_All){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Playlist Already Exists!","The playlist ($($playlist_profile.Name)) already exists with id $($($playlist_profile.ID))",$okandCancel,$Button_Settings)
            return
          }elseif($synchash.All_Playlists.Name -contains $playlist_profile.Name -and !$Overwrite_All){       
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Yes'
            $Button_Settings.NegativeButtonText = 'No'  
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
            $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Overwrite Playlist $($playlist_profile.Name)`?","A playlist with name ($($playlist_profile.Name)) already exists. Do you wish to overwrite the existing with the imported playlist?",$okandCancel,$Button_Settings)
            if($result -eq 'Affirmative'){
              write-ezlogs "User wished to overwrite playlist $($playlist_profile.Name)" -showtime
            }else{
              write-ezlogs "User did not wish to overwrite playlist $($playlist_profile.Name)" -showtime
              return
            }
          }elseif([system.io.file]::Exists($Import_playlist_Destination_path) -and !$Overwrite_All){       
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Yes'
            $Button_Settings.NegativeButtonText = 'No'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
            $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Overwrite Playlist $($playlist_profile.Name)`?","A playlist profile at ($($Import_playlist_Destination_path)) already exists. Do you wish to overwrite the existing with the imported playlist?",$okandCancel,$Button_Settings)
            if($result -eq 'Affirmative'){
              write-ezlogs "User wished to overwrite playlist $($playlist_profile.Name)" -showtime
            }else{
              write-ezlogs "User did not wish to overwrite playlist $($playlist_profile.Name)" -showtime
              return
            }
          }
          write-ezlogs ">>>> Adding playlist $($playlist_profile.name) to all_playlists library" -showtime
          foreach($item in $playlist_profile.PlayList_tracks){
            if('cached_image_path' -in $item.psobject.properties.name){
              $item.PSObject.Properties.Remove('cached_image_path')
            }
          }
          #$playlist_profile = $playlist_profile | ConvertTo-Playlists -List:$false -Force
          Add-Playlist -thisApp $thisApp -synchash $synchash -Playlist $playlist_profile.name -Media $playlist_profile.PlayList_tracks.values -ClearPlaylist -Update_UI
          #[Void]$synchash.All_Playlists.add($playlist_profile)
        }else{
          write-ezlogs "No valid playlist to import was found at $($result)" -showtime -warning
        }   
    }}
    #write-ezlogs ">>>> Saving playlist library to: $($thisApp.Config.Playlists_Profile_Path)" -showtime
    #Export-SerializedXML -InputObject $synchash.All_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist -Force
    #Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -Import_Playlists_Cache:$false -Full_Refresh -use_Runspace
  }catch{
    write-ezlogs "An exception occurred in Import_PlaylistCommand" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Import Playlists
#----------------------------------------------

#---------------------------------------------- 
#region Refresh Playlists
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.Refresh_PlaylistCommand = {
  param($sender) 
  write-ezlogs '>>>> Manually refreshing all playlists' -showtime
  try{
    #$syncHash.Playlists_TreeView.Itemssource.Refresh()
    #Update-Playlists -synchash $synchash -thisApp $thisApp -UpdateItemssource -Quick_Refresh
    Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace -Quick_Refresh
  }catch{
    write-ezlogs "An exception occurred in Refresh_PlaylistCommand" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Refresh Playlists
#----------------------------------------------

#---------------------------------------------- 
#region Delete Playlists
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.DeletePlaylist_Command = {
  param($sender)
  try{
    if($sender.Parent.DataContext.title){
      $Playlist = $sender.Parent.DataContext.title 
      $Playlist_ID = $sender.Parent.DataContext.Playlist_ID
    }elseif($sender.tag.Source.Selecteditem.title){
      $Playlist = $sender.tag.Source.Selecteditem.title
      $Playlist_ID = $sender.tag.Source.Selecteditem.Playlist_ID
    }elseif($sender.tag.DataContext.title){
      $Playlist = $sender.tag.DataContext.title
      $Playlist_ID = $sender.tag.DataContext.Playlist_ID
    }elseif($sender.DataContext.Content.Playlist_ID){
      $Playlist = $sender.DataContext.Content.Name
      $Playlist_ID = $sender.DataContext.Content.Playlist_ID
    }
    #write-ezlogs ">>>> Selected playlist to delete: $($Playlist) - sender.tag: $($sender.tag | out-string) - sender.DataContext: $($sender.DataContext | out-string)"
    if($Playlist){
      write-ezlogs "[DeletePlaylist_Command] Prompting for to confirm playlist deletion for $Playlist..." -showtime    
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
      $Button_Settings.AffirmativeButtonText = 'Yes'
      $Button_Settings.NegativeButtonText = 'No'  
      $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Delete Playlist $Playlist","Are you sure you wish to remove the $Playlist Playlist? This will not remove the media items in the playlist",$okandCancel,$Button_Settings)
      if($result -eq 'Affirmative'){
        if($Playlist_ID){
          if($synchash.all_playlists.playlist_ID){
            $index = $synchash.all_playlists.playlist_ID.indexof($Playlist_ID)
            if($index -ne -1){
              if($synchash.all_playlists -is [System.Windows.Data.CollectionView]){
                $playlist_to_remove = $synchash.all_playlists.GetItemAt($index)
              }else{
                $playlist_to_remove = $synchash.all_playlists[$index]
              }
            }
          }else{
            $playlist_to_remove = Get-IndexesOf $synchash.All_playlists.playlist_id -Value $playlist_id | & { process {
                if($synchash.all_playlists -is [System.Windows.Data.CollectionView]){
                  $synchash.all_playlists.GetItemAt($_)
                }else{
                  $synchash.All_Playlists[$_]
                }
            }}
          }
        }elseif($Playlist -and $synchash.all_playlists.name){
          $index = $synchash.all_playlists.name.indexof($Playlist)
          if($index -ne -1){
            if($synchash.all_playlists -is [System.Windows.Data.CollectionView]){
              $playlist_to_remove = $synchash.all_playlists.GetItemAt($index)
            }else{
              $playlist_to_remove = $synchash.all_playlists[$index]
            }
          }
        }
        #$playlist_to_remove_path = $playlist_to_remove.Playlist_Path
        if($playlist_to_remove){
          write-ezlogs "Removing playlist $Playlist" -showtime -warning
          [Void]$synchash.all_playlists.Remove($playlist_to_remove)
          write-ezlogs "Saving updated playlist library to: $($thisApp.config.Playlist_Profile_Directory)\All-Playlists-Cache.xml" -showtime -warning
          Export-SerializedXML -InputObject $synchash.All_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist
          Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -Full_Refresh -use_Runspace
        }else{
          write-ezlogs "Unable to find playlist to remove: $Playlist" -showtime -warning -AlertUI
        }
      }else{
        write-ezlogs 'User wish to cancel the operation' -showtime -warning
      }
      write-ezlogs ">>>> Saving app config: $($thisapp.Config.Config_Path)" -showtime
      Export-SerializedXML -InputObject $thisApp.Config -Path $thisapp.Config.Config_Path -isConfig
    }else{
      write-ezlogs "[DeletePlaylist_Command] Unable to find the playlist $playlist" -warning
    }
  }catch{
    write-ezlogs "An exception occurred deleting Playlist $($Playlist)" -showtime -catcherror $_
  }
}  
#---------------------------------------------- 
#endregion Delete Playlists
#---------------------------------------------- 
            
#---------------------------------------------- 
#region Remove From/Clear Playlists
#----------------------------------------------                  
[System.Windows.RoutedEventHandler]$synchash.Remove_from_PlaylistCommand = {
  param($sender)
  try{
    #$Media = $sender.tag.Media  
    <#    if($sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.Content -and $sender.tag.source.TreeViewItemInfo.TreeView -is [Syncfusion.UI.Xaml.TreeView.SfTreeView]){
        $media = $sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.Content
        }elseif($sender.tag.source.selecteditems.content.id){
        $Media = $sender.tag.source.selecteditems.content
        }elseif($sender.tag.source.selecteditems.Record.id){
        $Media = $sender.tag.source.selecteditems.Record
        }elseif($sender.datacontext.Record.id){
        $Media = $sender.datacontext.Record
        }elseif($sender.datacontext.content.id){
        $Media = $sender.datacontext.content
    }#>
    if($sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.Content -and $sender.tag.source.TreeViewItemInfo.TreeView -is [Syncfusion.UI.Xaml.TreeView.SfTreeView]){
      $Media = $sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.Content
      write-ezlogs "Found $($Media.count) media to remove from sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.Content"
    }elseif($sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.id){
      $Media = $sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems
      write-ezlogs "Found $($Media.count) media to remove from sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems"
    }elseif($sender.tag.source.selecteditems.content.id){
      $Media = $sender.tag.source.selecteditems.content
      write-ezlogs "Found $($Media.count) media to remove from sender.tag.source.selecteditems.content"
    }elseif($sender.tag.source.selecteditems.Record.id){
      $Media = $sender.tag.source.selecteditems.Record
      write-ezlogs "Found $($Media.count) media to remove from sender.tag.source.selecteditems.Record"
    }elseif($sender.tag.source.Name -eq 'YoutubeTable'){
      $Media = $synchash.YoutubeTable.selecteditems
      write-ezlogs "Found $($Media.count) media to remove from YoutubeTable.selecteditems"
    }elseif($sender.tag.source.Name -eq 'SpotifyTable'){
      $Media = $synchash.SpotifyTable.selecteditems
      write-ezlogs "Found $($Media.count) media to remove from SpotifyTable.selecteditems"
    }elseif($sender.tag.source.Name -eq 'MediaTable'){
      $Media = $synchash.MediaTable.selecteditems
      write-ezlogs "Found $($Media.count) media to remove from MediaTable.selecteditems"
    }elseif($sender.tag.source.Name -eq 'TwitchTable'){
      $Media = $synchash.TwitchTable.selecteditems
      write-ezlogs "Found $($Media.count) media to remove from TwitchTable.selecteditems"
    }elseif($sender.datacontext.Record.id){
      $Media = $sender.datacontext.Record
      write-ezlogs "Found $($Media.count) media to remove from sender.datacontext.Record"
    }elseif($sender.datacontext.content.id){
      $Media = $sender.datacontext.content
      write-ezlogs "Found $($Media.count) media to remove from sender.datacontext.content"
    }elseif($sender.tag.Media.id){
      $Media = $sender.tag.Media 
      write-ezlogs "Found $($Media.count) media to remove from sender.tag.Media"
    }
    if($sender.header -eq 'Remove Artist From...' -or $sender.parent.header -eq 'Remove Artist From...' -and $Media.artist){
      $Media = foreach($artist in $Media.Artist){
        Get-IndexesOf $synchash.All_local_Media.artist -Value $artist | & { process {
            $synchash.All_local_Media[$_]
        }}
        Get-IndexesOf $synchash.All_Spotify_Media.artist -Value $artist | & { process {
            $synchash.All_Spotify_Media[$_]
        }}
        Get-IndexesOf $synchash.All_Youtube_Media.artist -Value $artist | & { process {
            $synchash.All_Youtube_Media[$_]
        }}
      }
    }elseif($sender.header -eq 'Remove Album From...' -or $sender.parent.header -eq 'Remove Album From...' -and $Media.album){
      $Media = foreach($album in $Media.album){
        Get-IndexesOf $synchash.All_local_Media.album -Value $album | & { process {
            $synchash.All_local_Media[$_]
        }}
        Get-IndexesOf $synchash.All_Spotify_Media.album -Value $album | & { process {
            $synchash.All_Spotify_Media[$_]
        }}
        Get-IndexesOf $synchash.All_Youtube_Media.album -Value $album | & { process {
            $synchash.All_Youtube_Media[$_]
        }}
      }
    }
    if($sender.header -eq 'All Playlists'){
      write-ezlogs ">>>> Removing $($Media.count) tracks from all playlists" 
      Update-Playlist -Playlist $sender.header -media $Media -synchash $synchash -thisApp $thisApp -RemoveFromAll -use_Runspace
      return
    }
    if($Sender.tag.Media.Name -eq 'Playlist'){
      $Playlist = $Sender.Tag.Media.Playlist_name
    }elseif($sender.tag.Source.Selecteditem.title){
      $Playlist = $sender.tag.Source.Selecteditem.title
    }elseif($sender.header -ne 'Remove From Play Queue' -and $sender.header -ne 'Play Queue' -and $sender.header -ne 'Remove Selected From...'){
      $Playlist = $sender.header
    }
    if(($sender.header -eq 'Remove From Play Queue' -or $sender.header -eq 'Play Queue') -and $Media.id){
      write-ezlogs ">>>> Removing $($Media.count) tracks from Play Queue"
      Update-PlayQueue -Remove -ID $Media.id -thisApp $thisApp -synchash $synchash -Use_RunSpace -RefreshQueue
    }elseif($playlist){
      write-ezlogs ">>>> Removing $($Media.count) tracks from Playlist: $($playlist)"
      Update-Playlist -Playlist $Playlist -media $Media -synchash $synchash -thisApp $thisApp -Remove -use_Runspace -Update_Playlist_Order
    }else{
      write-ezlogs "Couldnt find name of playlist to remove from!" -warning
    }
  }catch{
    write-ezlogs "An exception occurred updating playlist $($Playlist)" -showtime -catcherror $_
  }
}   

[System.Windows.RoutedEventHandler]$synchash.Clear_PlaylistCommand = {
  param($sender)
  try{
    #TODO: Cleanup
    $Media = $sender.tag.Media  
    $Playlist = $sender.DataContext.title
    $PlaylistID = $sender.DataContext.Playlist_ID
    if(!$Playlist){
      $Playlist = $sender.tag.Source.Selecteditem.title
      $PlaylistID = $sender.Tag.Source.Selecteditem.Playlist_ID
    }
    if(!$Playlist){
      $Playlist = $sender.Tag.datacontext.title
      $PlaylistID = $sender.Tag.datacontext.Playlist_ID
    }
    if(!$PlaylistID -and $Sender.tag.Media.Name -eq 'Playlist'){
      $PlaylistID = $Sender.tag.Media.Playlist_ID
      $Playlist = $Sender.Tag.Media.Playlist_name
    }
    if($PlaylistID){
      write-ezlogs ">>>> Prompting to confirm clear of playlist: $Playlist..." -showtime    
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
      $Button_Settings.AffirmativeButtonText = 'Yes'
      $Button_Settings.NegativeButtonText = 'No'  
      $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Clear Playlist $Playlist","Are you sure you wish to clear and remove all tracks from the '$Playlist' Playlist? This will not remove the media items in the playlist",$okandCancel,$Button_Settings)
      if($result -eq 'Affirmative'){
        write-ezlogs " | The user wishes to clear the playlist: $($Playlist) - id: $PlaylistID" 
        Update-Playlist -Playlist $Playlist -media $Media -synchash $synchash -thisApp $thisApp -Clear -playlist_id $PlaylistID
      }else{
        write-ezlogs " | The user did not wish to clear the playlist: $($Playlist)" -warning
      }
    }else{
      write-ezlogs "Unable to find playlist ID $($Playlist) - aborting" -warning -AlertUI
      write-ezlogs "sender - $($sender | out-string)" -warning
      write-ezlogs "sender.tag - $($sender.tag | out-string)" -warning
      write-ezlogs "sender.DataContext - $($sender.DataContext | out-string)" -warning
    }
  }catch{
    write-ezlogs "An exception occurred clearing playlist $($Playlist)" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Remove From/Clear Playlists
#----------------------------------------------

#---------------------------------------------- 
#region Add to Spotify Playlist
#----------------------------------------------
[System.Windows.RoutedEventHandler]$Synchash.Add_Spotify_Playlist_Command = {
  param($sender)
  try{
    $Media = $_.OriginalSource.DataContext
    if(!$Media.url){$Media = $sender.tag}
    if(!$Media.url){$Media = $sender.tag.Media}  
    Add-SpotifyPlaylist -thisApp $thisApp -synchash $synchash -media $media -Sender $sender  
  }catch{
    write-ezlogs "An exception occurred in Add_Spotify_Playlist_Command - Media: $($media | out-string)" -showtime -catcherror $_
  } 
} 
#---------------------------------------------- 
#endregion Add to Spotify Playlist
#----------------------------------------------

#---------------------------------------------- 
#region Remove From Spotify Playlist
#----------------------------------------------
[System.Windows.RoutedEventHandler]$Synchash.Remove_Spotify_Playlist_Command  = {
  param($sender)
  try{
    $Media = $_.OriginalSource.DataContext
    if(!$Media.url){$Media = $sender.tag}
    if(!$Media.url){$Media = $sender.tag.Media}  
    Remove-SpotifyPlaylist -thisApp $thisApp -synchash $synchash -media $media -Sender $sender  
  }catch{
    write-ezlogs "An exception occurred in Remove_Spotify_Playlist_Command - Media: $($media | out-string)" -showtime -catcherror $_
  } 
}
#---------------------------------------------- 
#endregion Remove From Spotify Playlist
#----------------------------------------------

#---------------------------------------------- 
#region Open Web URL
#----------------------------------------------
[System.Windows.RoutedEventHandler]$Synchash.OpenWeb_Command  = {
  param($sender)
  try{
    $Media = $_.OriginalSource.DataContext
    if(!$Media.url){$Media = $sender.tag}
    if(!$Media.url){$Media = $sender.tag.Media}  
    if($Media.url -match 'youtube\.com' -or $Media.Source -eq 'Youtube' -or $Media.Source -eq 'Twitch'  -or $Media.url -eq 'Twitch\.tv'){
      if(Test-URL $Media.url){
        if($Media.url -match 'youtube\.com' -or $Media.url -match 'youtu\.be'){
          if($Media.url -match "v="){
            $youtube_id = ($($Media.url) -split('v='))[1].trim()
            if($youtube_id -match '\&pp='){
              $youtube_id = ($youtube_id -split '\&pp=')[0]
            } 
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
    }elseif($Media.type -match 'Spotify' -or $Media.uri -match 'spotify\:' -or $Media.Source -eq 'SpotifyPlaylist'){
      if($Media.url){
        write-ezlogs "Opening Spotify URL $($Media.url)" -showtime
        start $Media.url
      }else{
        write-ezlogs "Spotify URL $($Media.url) is invalid!" -showtime -warning
      }
    }else{
      write-ezlogs "Could not find valid Media URL! $($Media | out-string)" -showtime -warning
    }
  }catch{
    write-ezlogs "An exception occurred in OpenWeb command - URL: $url" -showtime -catcherror $_
  }
   
} 
#---------------------------------------------- 
#endregion Open Web URL
#----------------------------------------------

#---------------------------------------------- 
#region Open Local Path
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.OpenFolder_Command  = {
  param($sender)
  $Media = $_.OriginalSource.DataContext
  if(!$Media.url){$Media = $sender.tag}
  if(!$Media.url){$Media = $sender.tag.Media} 
  $Path = $media.directory
  if($thisApp.Config.Verbose_logging){write-ezlogs "Opening Directory path $($path)" -showtime} 
  if([System.IO.Directory]::Exists($path)){
    Start-Process $path
  }elseif([System.IO.Directory]::Exists([regex]::unescape($path))){
    Start-Process $([regex]::unescape($path))
  }elseif([System.IO.Directory]::Exists([regex]::escape($path))){
    Start-Process $([regex]::escape($path))
  }else{
    write-ezlogs "Directory Path $($path) is invalid!" -showtime -warning  
    Update-Notifications  -Level 'WARNING' -Message "Unable to find path $($path) to open!" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
  }   
} 
#---------------------------------------------- 
#endregion Open Local Path
#----------------------------------------------

#---------------------------------------------- 
#region Clear/Refresh Queue
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.Clear_Queue_Command  = {
  param($sender)
  try{
    if($syncHash.PlayQueue_TreeView){
      $syncHash.PlayQueue_TreeView.itemssource = $null
    }
    if($syncHash.Temporary_media){
      $synchash.Temporary_Media.clear()
    }
    if($thisapp.Config.Current_Playlist.count -gt 0){
      $thisapp.config.Current_Playlist.Clear()
      Get-PlayQueue -verboselog:$false -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace -Export_Config
    }
    if($Error){
      $Error.clear()
    }
    if($synchash.error){
      $synchash.error = $null
    }
    write-ezlogs ">>>> Clearing Current Play Queue | $(Get-MemoryUsage -forceCollection)" -showtime
    if($thisApp.Config.Dev_mode){     
      $Runspaces = Get-Runspace | Where-Object {$_.RunspaceAvailability -notin 'Busy' -and $_.RunspaceStateInfo -notin 'closing','opening' -and $_.ApartmentState -eq 'MTA'}
      write-ezlogs " | Current open runspaces: $($Runspaces | select * | out-string)" -showtime -Dev_mode
      $Runspaces = $Null
    }
  }catch{
    write-ezlogs 'An exception occurred clearing the play queue' -showtime -warning
  }    
}

[System.Windows.RoutedEventHandler]$synchash.Refresh_Queue_Command  = {
  param($sender)
  write-ezlogs '>>>> Refreshing Current Play Queue' -showtime -color cyan
  try{
    Get-PlayQueue -verboselog:$false -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace
  }catch{
    write-ezlogs 'An exception occurred refreshing the play queue' -showtime -warning
  }    
}
#---------------------------------------------- 
#endregion Clear/Refresh Queue
#----------------------------------------------

#---------------------------------------------- 
#region Remove Media
#----------------------------------------------
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
  }elseif($sender.tag.source.Name -eq 'TwitchTable'){
    $playlist_items = $synchash.TwitchTable.selecteditems
  }
  $Count = @($playlist_items).count
  $Selected_Media = [System.Collections.Generic.List[object]]::new($Count)  
  if($Count -gt 1){  
    $playlist_items | & { process {[Void]$Selected_Media.add($_)}}
    $title = 'Remove Selected Media'
    $Message = "Are you sure you wish to remove the $(@($playlist_items).count) selected media?"
  }else{
    [Void]$Selected_Media.add($Media_info)
    $title = "Remove Media $($Media_info.title)"
    $Message = "Are you sure you wish to remove `"$($Media_info.title)`"?"
  }
  try{
    if($synchash.MediaLibraryAnchorable.isFloating){
      $result=[System.Windows.Forms.MessageBox]::Show("$Message`n`nThis will remove the media from all playlists and Media Libraries. It will NOT delete the media itself","$title",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question) 
    }else{
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
      $Button_Settings.AffirmativeButtonText = 'Yes'
      $Button_Settings.NegativeButtonText = 'No'  
      $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"$title","$Message`n`nThis will remove the media from all playlists and browsers. It will NOT delete the media itself",$okandCancel,$Button_Settings)
    }
    if($result -eq 'Affirmative' -or $result -eq 'Yes'){
      #TODO: PUT THIS INTO REMOVE-MEDIA RUNSPACE
      $AllMedia_Profile_Directory_Path = [System.IO.Path]::Combine($thisApp.Config.Media_Profile_Directory,"All-MediaProfile")
      $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($AllMedia_Profile_Directory_Path,"All-Media-Profile.xml")
      if($Selected_Media.count -gt 0){
        Remove-Media -synchash $synchash -media_toRemove $Selected_Media -thisapp $thisApp -update_Library
      }                                                       
    }else{
      write-ezlogs "User declined to delete media $($Selected_Media.title)" -showtime -warning
    }        
  }catch{
    write-ezlogs "An exception occurred removing $($Selected_Media | Out-String)" -showtime -catcherror $_
  }    
}
#---------------------------------------------- 
#endregion Remove Media
#----------------------------------------------

#---------------------------------------------- 
#region Video View Overlay Pause
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.VideoViewMouseLeftButtonDown_command = {
  param($sender,[System.Windows.Input.MouseButtonEventArgs]$e )
  try{
    if ($e.OriginalSource.name -in 'VideoViewTransparentBackground' -and $e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed -and $e.RoutedEvent.Name -in 'MouseLeftButtonDown','PreviewMouseLeftButtonDown'){
      $e.Handled = $true
      Pause-Media -synchash $synchash -thisApp $thisApp -Update_MediaTransportControls
    }
  }catch{
    write-ezlogs "An exception occurred in Window VideoViewMouseLeftButtonDown_command event" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Video View Overlay Pause
#----------------------------------------------

#---------------------------------------------- 
#region Playlists Expand/Collapsed Events
#----------------------------------------------
[System.EventHandler`1[Syncfusion.UI.Xaml.TreeView.NodeExpandedCollapsedEventArgs]]$synchash.ExpandTreeView_Command  = {
  param($sender,[Syncfusion.UI.Xaml.TreeView.NodeExpandedCollapsedEventArgs]$item)
  try{
    $playlistitem = $item.originalsource.DataContext
    if($sender.isMouseOver){
      if(!$playlistitem){
        $playlistitem = $item.node.content
      }
      if($playlistitem.Playlist_ID -and $synchash.all_playlists.Playlist_ID){       
        if($synchash.all_playlists -is [System.Windows.Data.CollectionView]){
          $Pindex = $synchash.all_playlists.playlist_id.indexof($playlistitem.Playlist_ID)
          if($Pindex -ne -1){
            $Playlist = $synchash.all_playlists.GetItemAt($Pindex)  
          }
        }else{
          $Playlist = $synchash.all_playlists.where({$_.Playlist_ID -eq $playlistitem.Playlist_ID})
        }
      }
      if($item.node){
        $isExpanded = $item.node.IsExpanded
      }else{
        $isExpanded = $item.originalsource.IsExpanded
      }
      write-ezlogs ">>>> [ExpandTreeView_Command] $($sender.name) - Playlist $($Playlist.name) - Playlist.isExpanded: $($Playlist.isExpanded) -- item.node.IsExpanded: $($isExpanded)" -showtime
      if($Playlist -and $Playlist.isExpanded -ne $isExpanded){
        foreach($list in $Playlist){
          write-ezlogs ">>>> Updating playlist $($list.name) expanded state: $($list.isExpanded) to: $($isExpanded)" -showtime
          if(-not [string]::IsNullOrEmpty($list.isExpanded)){
            $list.isExpanded = $isExpanded
          }
        }      
      }
      if($sender.name -ne 'TrayPlayer_TreeView' -and $syncHash.TrayPlayer_TreeView.IsLoaded -and $item.node){
        if($isExpanded){
          $syncHash.TrayPlayer_TreeView.ExpandNode($item.node)
        }else{
          $syncHash.TrayPlayer_TreeView.CollapseNode($item.node)
        }
      }
      if($sender.name -ne 'LocalMedia_TreeView' -and $syncHash.LocalMedia_TreeView.IsLoaded -and $item.node){
        if($isExpanded){
          $syncHash.LocalMedia_TreeView.ExpandNode($item.node)
        }else{
          $syncHash.LocalMedia_TreeView.CollapseNode($item.node)
        }
      }
      if($sender.name -ne 'Playlists_TreeView' -and $syncHash.Playlists_TreeView.IsLoaded -and $item.node){
        if($isExpanded){
          $syncHash.Playlists_TreeView.ExpandNode($item.node)
        }else{
          $syncHash.Playlists_TreeView.CollapseNode($item.node)
        }
      }
    }
  }catch{
    write-ezlogs "An exception occurred in add_Expanded event for $($playlistitem) Playlist -- $($Playlist | out-string) -- Typename: $($Playlist.gettype())" -showtime -catcherror $_
  }
}
if($syncHash.Playlists_TreeView){
  if($syncHash.Playlists_TreeView -is [Syncfusion.UI.Xaml.TreeView.SfTreeView]){
    $syncHash.Playlists_TreeView.add_NodeExpanded($synchash.ExpandTreeView_Command)
    $syncHash.Playlists_TreeView.add_NodeCollapsed($synchash.ExpandTreeView_Command)
    $syncHash.Playlists_TreeView.HierarchyPropertyDescriptors.Clear()
    $descriptor = [Syncfusion.UI.Xaml.TreeView.Engine.HierarchyPropertyDescriptor]::new()
    $descriptor.IsExpandedPropertyName = 'IsExpanded'
    $descriptor.TargetType = [Playlist]
    $descriptor.ChildPropertyName = $syncHash.Playlists_TreeView.ChildPropertyName
    [Void]$syncHash.Playlists_TreeView.HierarchyPropertyDescriptors.add($descriptor)
  }else{
    [Void]$syncHash.Playlists_TreeView.AddHandler([System.Windows.Controls.TreeViewItem]::ExpandedEvent,$synchash.ExpandTreeView_Command)
    [Void]$syncHash.Playlists_TreeView.AddHandler([System.Windows.Controls.TreeViewItem]::CollapsedEvent,$synchash.ExpandTreeView_Command)  
  }
}
#Video Player
if($syncHash.TrayPlayer_TreeView){
  if($syncHash.TrayPlayer_TreeView -is [Syncfusion.UI.Xaml.TreeView.SfTreeView]){
    $syncHash.TrayPlayer_TreeView.add_NodeExpanded($synchash.ExpandTreeView_Command)
    $syncHash.TrayPlayer_TreeView.add_NodeCollapsed($synchash.ExpandTreeView_Command)
  }else{
    [Void]$syncHash.TrayPlayer_TreeView.AddHandler([System.Windows.Controls.TreeViewItem]::ExpandedEvent,$synchash.ExpandTreeView_Command)
    [Void]$syncHash.TrayPlayer_TreeView.AddHandler([System.Windows.Controls.TreeViewItem]::CollapsedEvent,$synchash.ExpandTreeView_Command)  
  }
}
#Library
if($syncHash.LocalMedia_TreeView){
  if($syncHash.LocalMedia_TreeView -is [Syncfusion.UI.Xaml.TreeView.SfTreeView]){
    $syncHash.LocalMedia_TreeView.add_NodeExpanded($synchash.ExpandTreeView_Command)
    $syncHash.LocalMedia_TreeView.add_NodeCollapsed($synchash.ExpandTreeView_Command)     
  }else{
    [Void]$syncHash.LocalMedia_TreeView.AddHandler([System.Windows.Controls.TreeViewItem]::ExpandedEvent,$synchash.ExpandTreeView_Command)
    [Void]$syncHash.LocalMedia_TreeView.AddHandler([System.Windows.Controls.TreeViewItem]::CollapsedEvent,$synchash.ExpandTreeView_Command)  
  }
}
#---------------------------------------------- 
#endregion Playlists Expand/Collapsed Events
#----------------------------------------------

#---------------------------------------------- 
#region Check Twitch Command
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.CheckTwitch_Command  = {
  param($sender)
  try{
    $Media = $_.OriginalSource.DataContext
    if(!$Media.url){$Media = $sender.tag}
    if(!$Media.url){$Media = $sender.tag.Media} 
    if([string]::IsNullOrEmpty($Media.url)){$Media = $sender.selecteditem.tag.Media}
    if($Media.url -match 'twitch\.tv'){
      Get-TwitchStatus -thisApp $thisApp -synchash $Synchash -verboselog:$thisApp.Config.Verbose_logging -checkall -Use_runspace -Refresh_Follows
    }else{
      write-ezlogs 'No valid Twitch URL was provided' -showtime -warning
    }
  }catch{
    write-ezlogs "An exception occurred in CheckTwitch_Command" -CatchError $_
  }
}
#---------------------------------------------- 
#endregion Check Twitch Command
#----------------------------------------------

#---------------------------------------------- 
#region TwitchLiveAlert Command
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.TwitchLiveAlert_Command  = {
  param($sender,$e)
  try{
    $Media = $_.OriginalSource.DataContext
    if(!$Media.url){$Media = $sender.tag}
    if(!$Media.url){$Media = $sender.tag.Media}
    if([string]::IsNullOrEmpty($Media.url)){$Media = $sender.selecteditem.tag.Media}
    if($Media.url -match 'twitch\.tv'){
      if($this.isChecked -eq $true){
        $Enable_liveAlert = $false
      }else{
        $Enable_liveAlert = $true
      }
      $this.isChecked = $false 
      if($sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.Content.id){
        $MediaItems = $sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.Content
      }elseif($sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems.id){
        $MediaItems = $sender.tag.source.TreeViewItemInfo.TreeView.SelectedItems
      }elseif($Media.Source -eq 'Local' -and $synchash.MediaTable.isVisible -and $synchash.MediaTable.selecteditems){
        $MediaItems = $synchash.MediaTable.selecteditems
      }elseif($Media.Source -eq 'Spotify' -and $synchash.SpotifyTable.isVisible -and $synchash.SpotifyTable.selecteditems){
        $MediaItems = $synchash.SpotifyTable.selecteditems
      }elseif($Media.Source -eq 'Youtube' -and $synchash.YoutubeTable.isVisible -and $synchash.YoutubeTable.selecteditems){
        $MediaItems = $synchash.YoutubeTable.selecteditems
      }elseif($Media.Source -eq 'Twitch' -and $synchash.TwitchTable.isVisible -and $synchash.TwitchTable.selecteditems){
        $MediaItems = $synchash.TwitchTable.selecteditems
      }
      if($MediaItems.count -eq 1 -and $media.Enable_LiveAlert -ne $Enable_liveAlert){
        $media.Enable_LiveAlert = $Enable_liveAlert
        $ExportProfile = $true
        $MediaItems = $media
      }
      write-ezlogs ">>>> Updating ($($MediaItems.count)) Twitch Live notifications to: $($Enable_liveAlert) -- for channels: $($MediaItems.title)"
      Get-TwitchStatus -thisApp $thisApp -synchash $Synchash -Update_Twitch_Profile -media $MediaItems -Use_runspace -Export_Profile:$ExportProfile -Enable_liveAlert:$Enable_liveAlert
    }else{
      write-ezlogs 'No valid Twitch URL was provided' -showtime -warning
    }
  }catch{
    write-ezlogs "An exception occurred in TwitchLiveAlert_Command" -CatchError $_
  }
}
#---------------------------------------------- 
#endregion TwitchLiveAlert Command
#----------------------------------------------

#---------------------------------------------- 
#region Edit Profile Command
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.EditProfile_Command  = {
  param($sender)
  $Media = $_.OriginalSource.DataContext
  if(!$Media.url){$Media = $sender.tag}
  if(!$Media.url){$Media = $sender.tag.Media} 
  if([string]::IsNullOrEmpty($Media.url)){$Media = $sender.selecteditem.tag.Media}
  write-ezlogs "[EditProfile_Command] Media to Edit: $($args | out-string)" -Dev_mode
  if($Media.id -and $media.url){
    try{ 
      #TODO: Warn users this is not complete and shouldnt be used!   
      if($synchash.MediaLibrary_Viewer.isVisible){
        $DialogWindow = $synchash.MediaLibrary_Viewer
      }elseif($synchash.MiniPlayer_Viewer.isVisible){
        $DialogWindow = $synchash.MiniPlayer_Viewer
      }else{
        $DialogWindow = $synchash.Window
      }
      if(!$thisapp.config.IsRead_TestFeatures){
        $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()
        $Button_settings.AffirmativeButtonText = "Yes"
        $Button_settings.NegativeButtonText = "No"  
        $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
        $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($DialogWindow,"Use WIP feature?","The profile/media properties editor is not complete and has known issues in its current state. It is not recommended to use so you do so at your own risk!!`n`nAre you sure you wish to continue? (This message will not be displayed again)",$okAndCancel,$button_settings)
        $thisapp.config.IsRead_TestFeatures = $true
        if($result -eq 'Affirmative'){
          write-ezlogs "User indicated they wish to continue and use the profile editor despite warnings" -showtime -warning 
        }else{
          write-ezlogs "User indicated they did not wish to continue, smart move" -showtime -warning  
          return
        }
      }
      Show-ProfileEditor -synchash $synchash -thisApp $thisApp -thisScript $thisScript -PageTitle "Edit Profile for $($Media.title) - $($thisApp.Config.App_Name) Media Player" -Media_to_edit $media -logo "$($thisapp.Config.Current_Folder)\Resources\Skins\Samson_Logo_Title.png"
    }catch{
      write-ezlogs "An exception occurred in EditProfile_Command routed event" -showtime -catcherror $_
    }
  }else{
    write-ezlogs 'No valid Media was provided' -showtime -warning
  }
}
#---------------------------------------------- 
#endregion Edit Profile Command
#----------------------------------------------

#---------------------------------------------- 
#region Find Youtube Command
#----------------------------------------------
[System.Windows.RoutedEventHandler]$Synchash.FindYoutube_Command = {
  param($sender)
  $datacontext = $_.OriginalSource.DataContext
  $Media = $_.OriginalSource.DataContext
  if(!$Media.url){$Media = $sender.tag}
  if(!$Media.url){$Media = $sender.tag.Media} 
  if([string]::IsNullOrEmpty($Media.url)){$Media = $sender.selecteditem.tag.Media}
  write-ezlogs "[FindYoutube_Command] Media to find on Youtube: $($media | out-string)" -Dev_mode
  if($Media.id -and ($media.title -or $media.name)){
    try{    
      if(!$media.title){
        $query = "`"$($media.name)`""
      }else{
        $query = "`"$($media.title)`""
      }
      if($media.artist){
        $query += " `"$($media.artist)`""
      }elseif($media.artist_name){
        $query += " `"$($media.artist_name)`""
      }
      if($synchash.WebBrowserAnchorable){
        $synchash.WebBrowserAnchorable.isSelected = $true
      }
      if($synchash.MainGrid_Top_TabControl){
        $synchash.MainGrid_Top_TabControl.SelectedIndex = 1
      }
      $url = "https://www.youtube.com/results?search_query=$([System.Web.HttpUtility]::UrlEncode($query))"
      $synchash.WebBrowser_url = $url
      if($synchash.MiniPlayer_Viewer.isVisible){
        if(!$synchash.WebBrowserAnchorable.isFloating){
          $synchash.WebBrowserAnchorable.float()
        }elseif($synchash.WebBrowserFloat){
          $synchash.WebBrowserFloat.Activate()
        }
      }else{
        $synchash.window.ShowActivated = $true
        $synchash.window.Opacity = 1
        $synchash.window.ShowInTaskbar = $true
        $synchash.Window.Show()
        $synchash.Window.Activate()
        if($SyncHash.Window.WindowState -eq 'Minimized'){
          $SyncHash.Window.WindowState = 'Normal'
        }
        Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action Open
      }
      Start-WebNavigation -uri $url -synchash $synchash -WebView2 $synchash.WebBrowser -thisScript $thisScript -thisApp $thisApp      
      $synchash.Webbrowseranchorable.isselected = $true
    }catch{
      write-ezlogs "An exception occurred in FindYoutube_Command routed event" -showtime -catcherror $_
    }
  }else{
    write-ezlogs 'No valid Media was provided or found' -showtime -warning
  }
}
#---------------------------------------------- 
#endregion Find Youtube Command
#----------------------------------------------

#---------------------------------------------- 
#region Add to Youtube Playlist Command
#----------------------------------------------
[System.Windows.RoutedEventHandler]$Synchash.Add_Youtube_Playlist_Command  = {
  param($sender)
  try{
    $Media = $_.OriginalSource.DataContext
    if(!$Media.url){$Media = $sender.tag}
    if(!$Media.url){$Media = $sender.tag.Media}  
    Add-YoutubePlaylist -thisApp $thisApp -synchash $synchash -media $media -Sender $sender  
  }catch{
    write-ezlogs "An exception occurred in Add_Youtube_Playlist_Command - Media: $($media | out-string)" -showtime -catcherror $_
  } 
} 
#---------------------------------------------- 
#endregion Add to Youtube Playlist Command
#----------------------------------------------

#---------------------------------------------- 
#region Remove from Youtube Playlist Command
#----------------------------------------------
[System.Windows.RoutedEventHandler]$Synchash.Remove_Youtube_Playlist_Command  = {
  param($sender)
  try{
    $Media = $_.OriginalSource.DataContext
    if(!$Media.url){$Media = $sender.tag}
    if(!$Media.url){$Media = $sender.tag.Media}  
    if($sender.Header -and $media.id){
      write-ezlogs ">>>> Removing $($media.title) from playlist $($sender.header)" 
      Remove-YoutubePlaylist -thisApp $thisApp -synchash $synchash -media $media -Sender $sender  
    }else{
      write-ezlogs "Unable to find media or playlist to remove! Check logs for details" -warning -AlertUI
      write-ezlogs " | Couldn't find media id or playlist name from sender.header -- Media: $($media | out-stdring) -- Sender: $($Sender | out-string)" -warning      
    }
  }catch{
    write-ezlogs "An exception occurred in Remove_Youtube_Playlist_Command - Media: $($media | out-string)" -showtime -catcherror $_
  } 
}
#---------------------------------------------- 
#endregion Remove from Youtube Playlist Command
#----------------------------------------------

#---------------------------------------------- 
#region ContextMenu Routed Event Handlers
#----------------------------------------------
$synchash.Media_ContextMenu_ScriptBlock = {
  Param($sender,[System.Windows.Input.MouseButtonEventArgs]$e)
  try{
    $OriginalSource = [System.WeakReference]::new($e.OriginalSource)
    #write-ezlogs "[ContextMenu] e.source: $($e.source | out-string)" -Dev_mode
    #write-ezlogs "[ContextMenu] e.Source.Name: $($e.Source.Name | out-string)" -Dev_mode
    #write-ezlogs "[ContextMenu] e.OriginalSource: $($e.OriginalSource | out-string)" 
    #write-ezlogs "[ContextMenu] e.source.gettype().Name: $($e.source.gettype().Name)" 
    #write-ezlogs "[ContextMenu] e.OriginalSource.gettype(): $($e.OriginalSource.gettype())" 
    $RemovefromQueue = $false
    if($OriginalSource.IsAlive){ 
      $Media = $OriginalSource.target.datacontext
      if($OriginalSource.target.datacontext.Name -eq 'Track' -and $OriginalSource.target.datacontext.id){
        try{
          $index = $synchash.All_playlists.playlist_tracks.values.id.IndexOf($OriginalSource.target.datacontext.id)
          if($index -ne -1){
            $media = $synchash.All_playlists.playlist_tracks.values.Item($index)
          }
        }catch{
          $media = $null
        }
      }elseif(($OriginalSource.target.datacontext.Type -eq 'CustomPlaylist' -and $OriginalSource.target.datacontext.playlist_id) -or ($OriginalSource.target.datacontext.Content.Type -eq 'CustomPlaylist' -and $OriginalSource.target.datacontext.Content.playlist_id)){
        $isPlaylist = $true
      }
      if(!$Media.id){
        $Media = $OriginalSource.target.datacontext.Record
      }
      if(!$Media.id -and $OriginalSource.target.datacontext.Content.id){
        $media = $OriginalSource.target.datacontext.Content
      }
      #TODO: Test reduce sparse array
      $items = [System.Collections.Generic.List[object]]::new(30)
      if(!$synchash.all_playlists -and [system.io.file]::Exists($thisApp.Config.Playlists_Profile_Path)){
        $synchash.all_playlists = Import-SerializedXML -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist
      }
      if(!$e.source){
        $source = [System.WeakReference]::new($sender)
      }else{
        $source = [System.WeakReference]::new($e.source)
      }
      if($e.Source -and $e.source.gettype().Name -match 'TreeView' -and $OriginalSource.target -and $OriginalSource.target.gettype() -notmatch 'Run'){
        if($e.Source -is [Syncfusion.UI.Xaml.TreeView.SfTreeView]){
          if($e.Source.SelectedItems -eq $null){
            $e.Source.SelectedItems = [System.Collections.ObjectModel.ObservableCollection[object]]::new()
          }elseif($e.Source.SelectedItems.count -le 1){
            $e.Source.SelectedItems.clear()
          }          
          $treeViewNode = $e.Source.GetNodeAt($e.GetPosition($e.source))
          #TODO: Multi-Selection on Right-click is fucked                 
          $treeviewitem = Get-VisualParentUp -source $OriginalSource.target -type ([Syncfusion.UI.Xaml.TreeView.TreeViewItem])
        }elseif($e.Source -is [System.Windows.Controls.TreeView]){
          $treeviewitem = Get-VisualParentUp -source $OriginalSource.target -type ([System.Windows.Controls.TreeViewItem])
        }
        if($treeviewitem){
          if($treeViewNode){
            $itemInfo = [Syncfusion.UI.Xaml.TreeView.Helpers.TreeViewHelper]::GetItemInfo($e.Source,$treeViewNode.Content)
            $itemPoint = $e.GetPosition($itemInfo.Element)
            if($itemInfo.Element.TreeViewItemInfo.TreeView.ExpanderPosition -eq 'Start'){
              $IsMouseOverOnExpander = $itemPoint.X -lt ($itemInfo.Element.IndentationWidth + $itemInfo.Element.ExpanderWidth)
            }else{
              $IsMouseOverOnExpander = $itemPoint.X -gt ($itemInfo.Element.ActualWidth - $itemInfo.Element.ExpanderWidth)
            }
            if($e.Source.FullRowSelect -and !$IsMouseOverOnExpander){
              if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Adding treeviewnode content to selected items: $($treeViewNode.Content)" -Dev_mode}
              $e.Source.SelectedItems.Add($treeViewNode.Content)
            }
            if($thisApp.Config.Dev_mode){write-ezlogs "| IsMouseOverOnExpander: $($IsMouseOverOnExpander) -- ItemPoint: $($itemPoint.x),$($itemPoint.y)" -Dev_mode}
          }
          $Source = [System.WeakReference]::new($treeviewitem)
          if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Found selected treeview item via Get-VisualParentUp -- $($treeViewNode | out-string)" -Dev_mode}
        }
      }
      if($treeviewitem.header.Name -eq 'Playlist' -and $treeviewitem.isMouseOver){
        $isPlaylist = $true
      }
      if($Media.Name -in 'Track','Play_Queue' -and $Media.id){
        $media = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_ID $Media.id
      }
      $Media_Tag = @{        
        Media = $Media
        Datacontext = $OriginalSource.target.datacontext
        source = $source.Target
      }
      if (($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Right) -and $Media.ID) { 
        if($thisApp.Config.Dev_mode){write-ezlogs " [ContextMenu] Creating context menu for a media item -- media: $($media | out-string)" -dev_mode}
        if($Media.ID -eq $synchash.Current_playing_media.id){
          if($synchash.PlayButton_ToggleButton.isChecked){
            $header = 'Pause'
            $Icon = 'Pause'
          }else{
            $header = 'Play'
            $Icon = 'Play'
          }
          $Command = [System.Windows.RoutedEventHandler]$synchash.PauseMedia_Command
        }else{
          $header = 'Play'
          $Icon = 'Play'
          $Command = $synchash.PlayMedia_Command
        }
        $Play_Media = @{
          'Header' = $header
          'Color' = 'White'
          'Icon_Color' = 'White'
          'Tag' = $Media_Tag
          'Command' = $Command
          'Icon_kind' = $Icon
          'Enabled' = $true
          'IsCheckable' = $false
        }
        [Void]$items.Add($Play_Media)  
        if(($e.Source.Name -eq 'YoutubeTable' -or $Media.type -match 'Youtube' -or $Media.url -match 'Youtube\.com' -or $Media.url -match 'youtu\.be' -or $Media.url -match 'soundcloud\.com') -and ($media.type -notmatch 'Twitch' -and $Media.url -notmatch 'twitch\.tv')){
          $Download_Media = @{
            'Header' = 'Download'
            'ToolTip' = 'Download as Local Media File'
            'Color' = 'White'
            'Icon_Color' = 'White'
            'Tag' = $Media_Tag
            'Command' = $Synchash.DownloadMedia_Command
            'Icon_kind' = 'Download'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          [Void]$items.Add($Download_Media)
          if($Media.url -notmatch 'soundcloud\.com'){  
            $Youtube_playlists_match = Get-IndexesOf $synchash.All_Youtube_Media.type -Value 'YoutubePlaylistItem' | & { process {
                $p = $synchash.All_Youtube_Media[$_]
                if($p.playlist_id -ne $Media.playlist_id){
                  [PSCustomObject]@{
                    'Playlist_Id' = $p.playlist_id
                    'Playlist' = $p.Playlist
                    'Playlist_URL' = $p.Playlist_URL
                  }
                }
            }} | Select-Object Playlist_ID,Playlist,Playlist_URL -Unique
            #$Youtube_playlists_match = $synchash.All_Youtube_Media | Where-Object {$_.type -eq 'YoutubePlaylistItem' -and $_.playlist_id -ne $Media.playlist_id} | select Playlist_ID,Playlist,Playlist_URL -Unique
            $Count = $Youtube_playlists_match.count
            if($Count -gt 0){
              $Youtube_Addplaylist_items = [System.Collections.Generic.List[object]]::new($Count)
            }else{
              $Youtube_Addplaylist_items = [System.Collections.Generic.List[object]]::new()
            }
            $Youtube_Sub_items = [System.Collections.Generic.List[object]]::new()
            $Youtube_Removeplaylist_items = [System.Collections.Generic.List[object]]::new()
            $Youtube_playlists_match | & { process { 
                $playlist_header = $Null
                if($_.Playlist_ID){
                  $Youtube_id = $_.Playlist_ID
                }elseif($_.url -match 'list='){
                  $youtube_id = ($($_.url) -split('list='))[1].trim()                         
                } 
                if($youtube_id -match '\&pp='){
                  $youtube_id = ($youtube_id -split '\&pp=')[0]
                }               
                if($_.Playlist){
                  $playlist_header = $_.Playlist
                }else{
                  $playlist_header = $Media.Playlist_URL
                }
                $Youtube_Playlist = @{
                  'Header' = $playlist_header
                  'Tag' = $Media_Tag
                  'Command' = $Synchash.Add_Youtube_Playlist_Command
                  'Enabled' = $true
                  'IsCheckable' = $false
                  'Icon_Color' = '#FFFF0000'
                  'Icon_kind' = $null
                  'Color' = 'White'
                }
                [Void]$Youtube_Addplaylist_items.Add($Youtube_Playlist)                      
            }}
            $separator = @{
              'Separator' = $true
              'Style' = 'SeparatorGradient'
            }            
            [Void]$Youtube_Addplaylist_items.Add($separator) 
            $Add_New_Youtube_Playlist = @{
              'Header' = 'Add to New Playlist..'
              'Tag' = $Media_Tag
              'Command' = $synchash.Add_Youtube_Playlist_Command
              'Enabled' = $true
              'IsCheckable' = $false
              'Icon_Color' = 'LightGreen'
              'Icon_kind' = 'PlaylistPlus'
              #'Icon_Margin' = '3,0,0,0'
              'Color' = 'White'
            }
            [Void]$Youtube_Addplaylist_items.Add($Add_New_Youtube_Playlist) 
            if(@($Youtube_Addplaylist_items).count -gt 0){
              $Add_to_Youtube_Playlist = @{
                'Header' = 'Add to Youtube Playlist'
                'Color' = 'White'
                'Icon_Color' = 'LightGreen'
                'Icon_kind' = 'PlaylistPlus'
                'Enabled' = $true
                #'Icon_Margin' = '3,0,0,0' 
                'Sub_items' = $Youtube_Addplaylist_items
              }
              [Void]$Youtube_Sub_items.Add($Add_to_Youtube_Playlist)
            }
            $Youtube_playlists_remove_match = Get-IndexesOf $synchash.All_Youtube_Media.type -Value 'YoutubePlaylistItem' | & { process {
                $p = $synchash.All_Youtube_Media[$_]
                if($p.playlist_id -eq $Media.playlist_id){
                  [PSCustomObject]::new(@{
                      'Playlist_Id' = $p.playlist_id
                      'Playlist' = $p.Playlist
                      'Playlist_URL' = $p.Playlist_URL
                  })
                }
            }} | Select-Object Playlist_ID,Playlist,Playlist_URL -Unique
            #$Youtube_playlists_remove_match = $synchash.All_Youtube_Media | Where-Object {$_.type -eq 'YoutubePlaylistItem' -and $_.playlist_id -eq $Media.playlist_id} | Select-Object Playlist_ID,Playlist,Playlist_URL -Unique
            foreach($playlist in $Youtube_playlists_remove_match){
              $playlist_header = $Null
              if($playlist.Playlist_ID){
                $Youtube_id = $playlist.Playlist_ID
              }elseif($playlist.url -match 'list='){
                $youtube_id = ($($playlist.url) -split('list='))[1].trim()                         
              }         
              if($playlist.Playlist){
                $playlist_header = $playlist.Playlist
              }else{
                $playlist_header = $Media.Playlist_URL
              }
              $Youtube_RemovePlaylist = @{
                'Header' = $playlist_header
                'Tag' = $Media_Tag
                'Command' = $Synchash.Remove_Youtube_Playlist_Command
                'Enabled' = $true
                'IsCheckable' = $false
                'Icon_Color' = '#FFFF0000'
                'Icon_kind' = $null
                'Color' = 'White'
              }
              [Void]$Youtube_Removeplaylist_items.Add($Youtube_RemovePlaylist)
            }
            if(@($Youtube_Removeplaylist_items).count -gt 0){
              $Remove_from_Youtube_Playlist = @{
                'Header' = 'Remove From Youtube Playlist'
                'Color' = 'White'
                'Icon_Color' = 'Red'
                'Icon_kind' = 'PlaylistMinus'
                'Enabled' = $true
                #'Icon_Margin' = '3,0,0,0' 
                'Sub_items' = $Youtube_Removeplaylist_items
              }
              [Void]$Youtube_Sub_items.Add($Remove_from_Youtube_Playlist)
            }
            $Youtube_Actions = @{
              'Header' = 'Youtube Actions'
              'Color' = 'White'
              'Icon_Color' = '#FFFF0000'
              'Icon_kind' = 'Youtube'
              'Enabled' = $true
              #'Icon_Margin' = '3,0,0,0' 
              'Sub_items' = $Youtube_Sub_items
            }
            [Void]$items.Add($Youtube_Actions)     
          }        
        }
        if((($e.Source.Name -eq 'SpotifyTable' -or $Media.source -eq 'Spotify') -or $Media.url -match 'spotify\:')){
          $Record_Media = @{
            'Header' = 'Record Media'
            'ToolTip' = 'Record Audio to Local File while Playing'
            'Color' = 'White'
            'Icon_Color' = 'Red'
            'Tag' = $Media_Tag
            'Command' = $synchash.RecordMedia_Command
            'Icon_kind' = 'RecordRec'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          [Void]$items.Add($Record_Media)     
          $Spotify_Sub_items = [System.Collections.Generic.List[object]]::new()
          if([string]::IsNullOrEmpty($synchash.Spotify_install_status)){
            if([System.IO.File]::Exists("$($env:APPDATA)\Spotify\Spotify.exe")){
              $synchash.Spotify_install_status = 'Installed'
              $synchash.Spotify_install_Path = "$($env:APPDATA)\Spotify\Spotify.exe"
            }else{
              $synchash.Spotify_install_status = 'NotInstalled'
              $synchash.Spotify_install_Path = $Null
            } 
            <#            elseif((Get-appxpackage 'Spotify*')){
                $synchash.Spotify_install_Path = "$((Get-appxpackage 'Spotify*').InstallLocation)\Spotify.exe"
                $synchash.Spotify_install_status = 'StoreVersion'     
            }#>
          }
          if(-not [string]::IsNullOrEmpty($synchash.Spotify_install_status) -and $synchash.Spotify_install_status -ne 'NotInstalled'){
            $Open_in_Spotify = @{
              'Header' = 'Open in Spotify'
              'Tag' = $Media_Tag
              'Command' = $Synchash.OpenWeb_Command
              'Enabled' = $true
              'IsCheckable' = $false
              'Icon_Color' = '#FF1ED760'
              'Icon_kind' = 'Spotify'
              'Color' = 'White'
            }
            [Void]$Spotify_Sub_items.Add($Open_in_Spotify)
          }
          if($Media.playlist_id){
            $playlist_id = $Media.playlist_id
          }elseif($Media.Playlist_URL -match "playlist\:"){
            $playlist_id = ($($Media.Playlist_URL) -split('playlist:'))[1].trim()
          }elseif($Media.uri -match "playlist\:"){
            $playlist_id = ($($Media.uri) -split('playlist\:'))[1].trim()                     
          }     
          if($thisApp.Config.Dev_Mode){
            $spotify_playlists_match = ($synchash.All_Spotify_Media.where({$_.playlist_id -ne $playlist_id -and $_.id -ne $media.id -and $_.playlist -ne $media.playlist})).playlist | sort -Unique
            $sCount = $spotify_playlists_match.count
            $Spotify_playlist_items = [System.Collections.Generic.List[object]]::new($sCount)
            $Spotify_Removeplaylist_items = [System.Collections.Generic.List[object]]::new()
            foreach($playlist in $spotify_playlists_match){
              $playlist_header = $Null
              $Spotify_Playlist = @{
                'Header' = $playlist
                'Tag' = $Media_Tag
                'Command' = $Synchash.Add_Spotify_Playlist_Command
                'Enabled' = $true
                'IsCheckable' = $false
                'Icon_Color' = '#FF1ED760'
                'Icon_kind' = $null
                'Color' = 'White'
              }
              [Void]$Spotify_playlist_items.Add($Spotify_Playlist)
            }
            $separator = @{
              'Separator' = $true
              'Style' = 'SeparatorGradient'
            }            
            [Void]$Spotify_playlist_items.Add($separator) 
            $Add_New_Spotify_Playlist = @{
              'Header' = 'Add to New Playlist..'
              'Tag' = $Media_Tag
              'Command' = $Synchash.Add_Spotify_Playlist_Command
              'Enabled' = $true
              'IsCheckable' = $false
              'Icon_Color' = 'LightGreen'
              'Icon_kind' = 'PlaylistPlus'
              #'Icon_Margin' = '3,0,0,0'
              'Color' = 'White'
            }
            [Void]$Spotify_playlist_items.Add($Add_New_Spotify_Playlist)
            if(@($Spotify_playlist_items).count -gt 0){
              $Add_to_Spotify_Playlist = @{
                'Header' = 'Add to Spotify Playlist'
                'Color' = 'White'
                'Icon_Color' = 'LightGreen'
                'Icon_kind' = 'PlaylistPlus'
                'Enabled' = $true
                #'Icon_Margin' = '3,0,0,0' 
                'Sub_items' = $Spotify_playlist_items
              }
              [Void]$Spotify_Sub_items.Add($Add_to_Spotify_Playlist)
            }
            $Spotify_playlists_remove_match = Get-IndexesOf $synchash.All_Spotify_Media.id -Value $media.id | & { process {
                $p = $synchash.All_Spotify_Media[$_]
                if($p.playlist_id -eq $playlist_id){
                  $p
                }
            }} | Select-Object -Unique
            #$Spotify_playlists_remove_match = $synchash.All_Spotify_Media.where({$_.playlist_id -eq $playlist_id -and $_.id -eq $media.id}) | select -Unique
            #$Spotify_playlists_remove_match = ($synchash.All_Spotify_Media[$media.id]) | Where-Object {$_.playlist_id -eq $playlist_id}
            foreach($playlist in $Spotify_playlists_remove_match){
              $playlist_header = $Null
              if($playlist.playlist){
                $playlist_header = $playlist.playlist
              }else{
                $playlist_header = $Media.Playlist_URL
              }
              $Spotify_RemovePlaylist = @{
                'Header' = $playlist_header
                'Tag' = $Media_Tag
                'Command' = $Synchash.Remove_Spotify_Playlist_Command
                'Enabled' = $true
                'IsCheckable' = $false
                'Icon_Color' = '#FFFF0000'
                'Icon_kind' = $null
                'Color' = 'White'
              }
              [Void]$Spotify_Removeplaylist_items.Add($Spotify_RemovePlaylist)
            }
            if(@($Spotify_Removeplaylist_items).count -gt 0){
              $Remove_from_Spotify_Playlist = @{
                'Header' = 'Remove From Spotify Playlist'
                'Color' = 'White'
                'Icon_Color' = 'Red'
                'Icon_kind' = 'PlaylistMinus'
                'Enabled' = $true
                #'Icon_Margin' = '3,0,0,0' 
                'Sub_items' = $Spotify_Removeplaylist_items
              }
              [Void]$Spotify_Sub_items.Add($Remove_from_Spotify_Playlist)
            }
          }
          $Spotify_Actions = @{
            'Header' = 'Spotify Actions'
            'Color' = 'White'
            'Icon_Color' = '#FF1ED760'
            'Icon_kind' = 'Spotify'
            'Enabled' = $true
            #'Icon_Margin' = '3,0,0,0' 
            'Sub_items' = $Spotify_Sub_items
          }
          [Void]$items.Add($Spotify_Actions) 
        }    
        if(($e.Source.Name -ne 'YoutubeTable' -and $Media.type -notmatch 'Youtube') -and ($media.url -notmatch 'Youtube\.com' -and $media.web_url -notmatch 'youtube\.com' -and $media.url -notmatch 'youtu\.be')){
          $Find_on_Youtube = @{
            'Header' = 'Find on Youtube'
            'ToolTip' = 'Opens the in-app Web Browser to search Youtube.com for selected media'
            'Color' = 'White'
            'Icon_Color' = '#FFFF3737'
            'Tag' = $Media_Tag
            'Command' = $Synchash.FindYoutube_Command
            'Icon_kind' = 'Youtube'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          [Void]$items.Add($Find_on_Youtube)     
        }
        if((Test-URL $Media.url) -or (Test-URL $Media.uri)){
          $Open_Web = @{
            'Header' = 'Open in Web Browser'
            'Color' = 'White'
            'ToolTip' = 'Opens the media URL directly in your Web Browser'
            'Icon_Color' = 'White'
            'Tag' = $Media_Tag
            'Command' = $Synchash.OpenWeb_Command
            'Icon_kind' = 'Web'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          [Void]$items.Add($Open_Web) 
        }
        if($Media.url -match 'twitch\.tv'){
          if($thisapp.config.Twitch_Playlists){
            $Config_index = $thisapp.config.Twitch_Playlists.id.indexof($Media.id)
            if($Config_index -ne -1){
              $Config_Twitch = $thisapp.config.Twitch_Playlists[$Config_index]
            }
          }
          $Twitch_Sub_items = [System.Collections.Generic.List[object]]::new()   
          $CheckTwitch_Media = @{
            'Header' = 'Refresh Status'
            'ToolTip' = 'Refreshes all Twitch Media'
            'Color' = 'White'
            'Icon_Color' = '#FFDA70D6'
            'Tag' = $Media_Tag
            'Command' = $synchash.CheckTwitch_Command
            'Icon_kind' = 'Twitch'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          [Void]$Twitch_Sub_items.Add($CheckTwitch_Media)     
          if($thisapp.config.Enable_Twitch_Notifications){
            $tooltip = 'Receive an in-app notification when this channel goes live'
            $color = 'White'
            $checkable = $true
          }else{
            $tooltip = 'In-app Twitch notifications are currently disabled'
            $color = 'Gray'
            $checkable = $false
          }
          $TwitchLiveAlert = @{
            'Header' = 'Enable Live Notifications'
            'ToolTip' = $tooltip
            'Color' = $color
            'Icon_Color' = '#FFDA70D6'
            'Tag' = $Media_Tag
            'CommandType' = 'Checked'
            'CommandType2' = 'UnChecked'
            'Command' = $synchash.TwitchLiveAlert_Command
            'Icon_kind' = 'Twitch'
            'Enabled' = $($thisapp.config.Enable_Twitch_Notifications -eq $true)
            'IsChecked' = $($media.Enable_LiveAlert -eq $true -or $Config_Twitch.Enable_LiveAlert -eq $true)
            'IsCheckable' = $checkable
          }
          [Void]$Twitch_Sub_items.Add($TwitchLiveAlert)
          $Twitch_Actions = @{
            'Header' = 'Twitch Actions'
            'Color' = 'White'
            'Icon_Color' = '#FFDA70D6'
            'Icon_kind' = 'Twitch'
            'Enabled' = $true
            #'Icon_Margin' = '3,0,0,0' 
            'Sub_items' = $Twitch_Sub_items
          }
          [Void]$items.Add($Twitch_Actions)  
        } 
        if($e.Source.Name -eq 'MediaTable' -or $Media.Directory){
          $Open_MediaLocation = @{
            'Header' = 'Open File Location'
            'ToolTip' = 'Opens File Explorer to the media directory'
            'Color' = 'White'
            'Icon_Color' = 'Orange'
            'Tag' = $Media_Tag
            'Command' = $synchash.OpenFolder_Command
            'Icon_kind' = 'FolderOpen'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          [Void]$items.Add($Open_MediaLocation)    
        }                      
        $Playlists = $synchash.all_playlists | & { process {
            if(-not [string]::IsNullOrEmpty($_.name) -and $_.Playlist_tracks.values.id -notcontains $Media.ID){
              $_
            }
        }}
        #$Playlists = $synchash.all_playlists | Where-Object {-not [string]::IsNullOrEmpty($_.name) -and $_.Playlist_tracks.values.id -notcontains $Media.ID}
        $Sub_items = [System.Collections.Generic.List[object]]::new($Playlists.count)
        foreach ($Playlist in $playlists)
        {
          $Playlist_name = $Playlist.name
          #$Playlist_tracks = $Playlist.Playlist_tracks.values
          $Custom_Playlist_Add = @{
            'Header' = $Playlist_name
            'Tag' = $Media_Tag
            'Command' = $synchash.Add_to_PlaylistCommand
            'Enabled' = $true
            'IsCheckable' = $false
            'Icon_kind' = $null
            'Color' = 'White'
          }
          [Void]$Sub_items.Add($Custom_Playlist_Add)
        }     
        $separator = @{
          'Separator' = $true
          'Style' = 'SeparatorGradient'
        }            
        [Void]$Sub_items.Add($separator)
        if($thisApp.config.Current_Playlist.values -notcontains $media.id){
          $RemovefromQueue = $false
          $Add_to_PlayQueue = @{
            'Header' = 'Play Queue'
            'ToolTip' = 'Add this media to the Play Queue'
            'Color' = 'White'
            'Icon_Color' = 'LightGreen'
            'Icon_kind' = 'AddToQueue'
            'IconPack' = 'PackIconCoolicons'
            'Enabled' = $true
            'Tag' = $Media_Tag
            #'Icon_Margin' = '3,0,0,0' 
            'Command' = $synchash.Add_to_PlaylistCommand
          }
          [Void]$Sub_items.Add($Add_to_PlayQueue)
        }else{
          $RemovefromQueue = $true
        }            
        $Add_New_Playlist = @{
          'Header' = 'New Playlist'
          'Tag' = $Media_Tag
          'Command' = $synchash.Add_to_New_PlaylistCommand
          'Enabled' = $true
          'IsCheckable' = $false
          'Icon_Color' = 'LightGreen'
          'Icon_kind' = 'PlaylistPlus'
          #'Icon_Margin' = '3,0,0,0'
          'Color' = 'White'
        }
        [Void]$Sub_items.Add($Add_New_Playlist)  
        <#        if($Media.Artist){
            $Add_Selected_New_Playlist = @{
            'Header' = 'Add Artist to Playlist'
            'Tag' = $Media_Tag
            'Command' = $synchash.Add_to_New_PlaylistCommand
            'Enabled' = $true
            'IsCheckable' = $false
            'Icon_Color' = 'LightGreen'
            'Icon_kind' = 'PlaylistPlus'
            'Icon_Margin' = '3,0,0,0'
            'Color' = 'White'
            }
            [Void]$Sub_items.Add($Add_Selected_New_Playlist) 
        }#>
        $Add_to_Playlist = @{
          'Header' = 'Add Selected to...'
          'Color' = 'White'
          'Icon_Color' = 'LightGreen'
          'Icon_kind' = 'PlaylistPlus'
          'Enabled' = $true
          #'Icon_Margin' = '3,0,0,0' 
          'Sub_items' = $Sub_items
        }
        [Void]$items.Add($Add_to_Playlist)   
        if($Media.Artist){
          $Add_Artist_to_Playlist = @{
            'Header' = 'Add Artist to...'
            'Color' = 'White'
            'Icon_Color' = 'LightGreen'
            'Icon_kind' = 'PlaylistPlus'
            'Enabled' = $true
            #'Icon_Margin' = '3,0,0,0' 
            'Sub_items' = $Sub_items
          }
          [Void]$items.Add($Add_Artist_to_Playlist)
        }
        if($Media.Album){
          $Add_Album_to_Playlist = @{
            'Header' = 'Add Album to...'
            'Color' = 'White'
            'Icon_Color' = 'LightGreen'
            'Icon_kind' = 'PlaylistPlus'
            'Enabled' = $true
            #'Icon_Margin' = '3,0,0,0' 
            'Sub_items' = $Sub_items
          }
          [Void]$items.Add($Add_Album_to_Playlist)
        }
        #Remove from Playlist
        $Remove_Sub_items = [System.Collections.Generic.List[object]]::new()
        if($Media.ID -in $synchash.all_playlists.Playlist_tracks.values.id -or $media.artist -in $synchash.All_Playlists.Playlist_tracks.values.artist){
          $RemoveArtistFrom = $true
          $RemoveFromPlaylists = $synchash.all_playlists | & { process {
              if(-not [string]::IsNullOrEmpty($_.name) -and $_.Playlist_tracks.values.id -contains $Media.ID){
                $_
              }
          }}
          foreach ($Playlist in $RemoveFromPlaylists)
          {
            $Playlist_name = $Playlist.name
            #$Playlist_tracks = $Playlist.Playlist_tracks.values
            $Custom_Playlist_Remove = @{
              'Header' = $Playlist_name
              'Tag' = $Media_Tag
              'Command' = $synchash.Remove_from_PlaylistCommand
              'Enabled' = $true
              'IsCheckable' = $false
              'Icon_kind' = $null
              'Color' = 'White'
            }
            [Void]$Remove_Sub_items.Add($Custom_Playlist_Remove)      
          }
          $separator = @{
            'Separator' = $true
            'Style' = 'SeparatorGradient'
          }            
          [Void]$Remove_Sub_items.Add($separator)  
          $RemoveFromAll_Playlists = @{
            'Header' = 'All Playlists'
            'Tag' = $Media_Tag
            'Command' = $synchash.Remove_from_PlaylistCommand
            'Enabled' = $true
            'IsCheckable' = $false
            'Icon_kind' = $null
            'Color' = 'White'
          }
          [Void]$Remove_Sub_items.Add($RemoveFromAll_Playlists)   
        }
        $separator = @{
          'Separator' = $true
          'Style' = 'SeparatorGradient'
        }            
        [Void]$items.Add($separator) 
        if($thisApp.config.Current_Playlist.values){
          $QueueArtists = foreach($value in $thisApp.config.Current_Playlist.values){
            Get-IndexesOf $synchash.All_local_Media.id -Value $value | & { process {
                if($synchash.All_local_Media[$_].Artist){
                  $synchash.All_local_Media[$_].Artist
                  break
                }
            }}
            Get-IndexesOf $synchash.All_Spotify_Media.id -Value $value | & { process {
                if($synchash.All_Spotify_Media[$_].Artist){
                  $synchash.All_Spotify_Media[$_].Artist
                  break
                }   
            }}
            Get-IndexesOf $synchash.All_Youtube_Media.id -Value $value | & { process {
                if($synchash.All_Youtube_Media[$_].Artist){
                  $synchash.All_Youtube_Media[$_].Artist
                  break
                } 
            }}
            Get-IndexesOf $synchash.All_Twitch_Media.id -Value $value | & { process {
                if($synchash.All_Twitch_Media[$_].Artist){
                  $synchash.All_Twitch_Media[$_].Artist
                  break
                }
            }}
          }
        }
        if($RemovefromQueue){        
          #write-ezlogs "[ContextMenu] Adding Remove from Play Queue: $($e.Source.Name | out-string)" 
          $Remove_From_PlayQueue = @{
            'Header' = 'Remove from Play Queue'
            'ToolTip' = 'Remove this media from the Play Queue'
            'Color' = 'White'
            'Icon_Color' = 'Red'
            'Icon_kind' = 'TrayRemove'
            'Enabled' = $true
            'Tag' = $Media_Tag
            #'Icon_Margin' = '3,0,0,0' 
            'Command' = $synchash.Remove_from_PlaylistCommand
          }
          [Void]$items.Add($Remove_From_PlayQueue)
        }
        if($media.Artist -in $QueueArtists){
          $RemoveArtistFromQueue = @{
            'Header' = 'Play Queue'
            'Tag' = $Media_Tag
            'Command' = $synchash.Remove_from_PlaylistCommand
            'Enabled' = $true
            'IsCheckable' = $false
            'Icon_kind' = $null
            'Color' = 'White'
          }
          [Void]$Remove_Sub_items.Add($RemoveArtistFromQueue)
        }
        if($Remove_Sub_items.count -gt 0){
          $Remove_From_Playlist = @{
            'Header' = 'Remove Selected From...'
            'ToolTip' = 'Remove this media from a playlist'
            'Color' = 'White'
            'Icon_Color' = 'Red'
            'Icon_kind' = 'PlaylistMinus'
            'Enabled' = $true
            #'Icon_Margin' = '3,0,0,0' 
            'Sub_items' = $Remove_Sub_items
          }
          [Void]$items.Add($Remove_From_Playlist)
        }
        if($media.Artist -in $QueueArtists -or $RemoveArtistFrom){
          $Remove_Artist_from_Playlist = @{
            'Header' = 'Remove Artist From...'
            'ToolTip' = "Removes all media of artist: $($Media.Artist)"
            'Color' = 'White'
            'Icon_Color' = 'Red'
            'Icon_kind' = 'PlaylistMinus'
            'Enabled' = $true
            #'Icon_Margin' = '3,0,0,0' 
            'Sub_items' = $Remove_Sub_items
          }
          [Void]$items.Add($Remove_Artist_from_Playlist)
        }
        $Remove_Media = @{
          'Header' = 'Remove from Library'
          'ToolTip' = 'Removes selected media from this app'
          'Color' = 'White'
          'Icon_Color' = 'White'
          'Icon_kind' = 'TrashCanOutline'
          'Tag' = $Media_Tag
          'Command' = $Remove_MediaCommand
          'Enabled' = $true
          #'Icon_Margin' = '3,0,0,0' 
        }
        [Void]$items.Add($Remove_Media)   
        $separator = @{
          'Separator' = $true
          'Style' = 'SeparatorGradient'
        }            
        [Void]$items.Add($separator) 
        $Edit_Profile = @{
          'Header' = 'Media Properties'
          'ToolTip' = 'View or Edit Media properties'
          'Color' = 'White'
          'Icon_Color' = 'White'
          'Tag' = $Media_Tag
          'Command' = $synchash.EditProfile_Command
          'Icon_kind' = 'FileDocumentEditOutline'
          'Enabled' = $true
          'IsCheckable' = $false
        }
        [Void]$items.Add($Edit_Profile)                                
      }elseif(($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Right -and -not [string]::IsNullOrEmpty($OriginalSource.target.datacontext) -and ($OriginalSource.target.GetType()).Name -match 'Textblock' -and $e.Source.Name -ne 'PlayQueue_TreeView' -and (-not [string]::IsNullOrEmpty($e.OriginalSource.datacontext.title))) -or ($isPlaylist -and (!$Media -or $media.Name -eq 'Playlist'))){
        #if($e.Source.Name -ne 'YoutubeTable' -and $e.Source.Name -ne 'SpotifyTable' -and $e.Source.Name -ne 'MediaTable'){$sender.isSelected = $true}
        write-ezlogs " [ContextMenu] Creating context menu for a Playlist -- e.OriginalSource.datacontext: $($OriginalSource.target.datacontext)" -dev_mode
        $e.Handled = $true
        $Playlist_PlayAll = @{
          'Header' = 'Play'
          'FontWeight' = 'Bold'
          'Color' = 'White'
          'Icon_Color' = 'White'
          'Tag' = $Media_Tag
          'Command' = $synchash.Add_to_PlaylistCommand
          'Icon_kind' = 'AnimationPlayOutline'
          'Enabled' = $true
          'IsCheckable' = $false
        }
        [Void]$items.Add($Playlist_PlayAll)    
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
        [Void]$items.Add($Playlist_toQueue)    
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
        [Void]$items.Add($Playlist_Save) 
        $Playlist_Rename = @{
          'Header' = 'Rename Playlist'
          'Color' = 'White'
          'Icon_Color' = 'LightBlue'
          'Tag' = $Media_Tag
          'Command' = $synchash.Add_to_New_PlaylistCommand
          'Icon_kind' = 'FormTextbox'
          'Enabled' = $true
          'IsCheckable' = $false
        }
        [Void]$items.Add($Playlist_Rename)
        $Playlist_Export = @{
          'Header' = 'Export Playlist'
          'ToolTip' = 'Backup, Save or Share Playlists'
          'Color' = 'White'
          'Icon_Color' = 'WhiteSmoke'
          'Tag' = $Media_Tag
          'Command' = $synchash.Export_PlaylistCommand
          'Icon_kind' = 'Export'
          'Enabled' = $true
          'IsCheckable' = $false
        }
        [Void]$items.Add($Playlist_Export)       
        if($e.Source.Name -ne 'YoutubeTable' -and $e.Source.Name -ne 'SpotifyTable' -and $e.Source.Name -ne 'MediaTable'){
          $separator = @{
            'Separator' = $true
            'Style' = 'SeparatorGradient'
          }            
          [Void]$items.Add($separator)   
          $Playlist_clear = @{
            'Header' = 'Clear Playlist'
            'Color' = 'White'
            'Icon_Color' = 'White'
            'Tag' = $Media_Tag
            'Command' = $synchash.Clear_PlaylistCommand
            'Icon_kind' = 'PlaylistMinus'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          [Void]$items.Add($Playlist_clear)             
          $Playlist_Delete = @{
            'Header' = 'Delete Playlist'
            'Color' = 'White'
            'Icon_Color' = 'Red'
            'Tag' = $Media_Tag
            'Command' = $synchash.DeletePlaylist_Command
            'Icon_kind' = 'PlaylistRemove'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          [Void]$items.Add($Playlist_Delete) 
        }    
      }elseif($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Right -and $e.Source.Name -eq 'PlayQueue_TreeView'){
        write-ezlogs " [ContextMenu] Creating context menu for PlayQueue" -dev_mode
        $e.Handled = $true
        $Playlist_Save = @{
          'Header' = 'Create Playlist from Queue'
          'ToolTip' = 'Saves all media currently in the queue to a new playlist'
          'Color' = 'White'
          'Icon_Color' = 'LightGreen'
          'Tag' = $Media_Tag
          'Command' = $synchash.Add_to_New_PlaylistCommand
          'Icon_kind' = 'PlaylistPlus'
          'Enabled' = $true
          'IsCheckable' = $false
        }
        [Void]$items.Add($Playlist_Save)
        $Playlist_Clear = @{
          'Header' = 'Clear Queue'
          'Color' = 'White'
          'Icon_Color' = 'Gray'
          'Tag' = $Media_Tag
          'Command' = $synchash.Clear_Queue_Command
          'Icon_kind' = 'PlaylistMinus'
          'Enabled' = $true
          'IsCheckable' = $false
        }
        [Void]$items.Add($Playlist_Clear)         
      }
      if($e.Source.Name -in 'TrayPlayerQueue_TreeView','TrayPlayer_TreeView','VideoView_Queue'){
        $WPFtraymenu = $true
      }else{
        $WPFtraymenu  = $false
      }
      if($items -and $OriginalSource.target){ 
        if($OriginalSource.target){
          $OriginalSource.target.tag = $Media_Tag
        }  
        if($isPlaylist -or $isPlaylistitem){
          #write-ezlogs "Adding new contextmenu for - isPlaylist: $isPlaylist - source: $($Source)" -warning
          Add-WPFMenu -control $Source.target -items $items -AddContextMenu -sourceWindow $synchash -TrayMenu:$WPFtraymenu
        }else{
          #write-ezlogs "Adding new contextmenu for OriginalSource: $($e.OriginalSource)" -warning
          Add-WPFMenu -control $OriginalSource.target -items $items -AddContextMenu -sourceWindow $synchash -TrayMenu:$WPFtraymenu
        }     
      }else{
        write-ezlogs "No items generated or no originalsource to add contextmenu to - isPlaylist: $isPlaylist -- Source.Name: - $($e.Source.Name) - Media: $($Media | out-string) - DataContext: $($OriginalSource.target.DataContext | out-string) - items: $($items | out-string)" -warning
        $e.Handled = $false
      }
    }else{
      write-ezlogs "Contextmenu already set for $($OriginalSource.target)" -warning
    }      
  }catch{
    write-ezlogs "An exception occurred creating contextmenu for $($e.Source.Name)" -showtime -catcherror $_
  }  
}
[System.Windows.RoutedEventHandler]$synchash.Media_ContextMenu = $synchash.Media_ContextMenu_ScriptBlock

if($synchash.MediaTable){
  [Void]$synchash.MediaTable.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
  [Void]$synchash.MediaTable.AddHandler([System.Windows.Controls.Button]::PreviewMouseDoubleClickEvent,$synchash.PlayMedia_Command)
}
if($synchash.PlayQueue_TreeView){
  [Void]$synchash.PlayQueue_TreeView.AddHandler([System.Windows.Controls.Button]::PreviewMouseDoubleClickEvent,$synchash.PlayMedia_Command)
  [Void]$synchash.PlayQueue_TreeView.AddHandler([System.Windows.Controls.DataGrid]::PreviewKeyDownEvent,$synchash.KeyDown_Command)
  [Void]$synchash.PlayQueue_TreeView.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
}

if($synchash.PlayQueue_TreeView_Library){
  [Void]$synchash.PlayQueue_TreeView_Library.AddHandler([System.Windows.Controls.Button]::PreviewMouseDoubleClickEvent,$synchash.PlayMedia_Command)
  [Void]$synchash.PlayQueue_TreeView_Library.AddHandler([System.Windows.Controls.DataGrid]::PreviewKeyDownEvent,$synchash.KeyDown_Command)
  [Void]$synchash.PlayQueue_TreeView_Library.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
}

if($synchash.Playlists_TreeView){
  [Void]$synchash.Playlists_TreeView.AddHandler([System.Windows.Controls.Button]::PreviewMouseDoubleClickEvent,$synchash.PlayMedia_Command)
  [Void]$synchash.Playlists_TreeView.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
}

if($synchash.LocalMedia_TreeView){
  [Void]$synchash.LocalMedia_TreeView.AddHandler([System.Windows.Controls.Button]::PreviewMouseDoubleClickEvent,$synchash.PlayMedia_Command)
  [Void]$synchash.LocalMedia_TreeView.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
}
if($synchash.TrayPlayer_TreeView){
  [Void]$synchash.TrayPlayer_TreeView.AddHandler([System.Windows.Controls.Button]::PreviewMouseDoubleClickEvent,$synchash.PlayMedia_Command)
  [Void]$synchash.TrayPlayer_TreeView.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
}
if($synchash.SpotifyTable){
  [Void]$synchash.SpotifyTable.AddHandler([System.Windows.Controls.Button]::PreviewMouseDoubleClickEvent,$synchash.PlayMedia_Command)
  [Void]$synchash.SpotifyTable.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
}
if($synchash.YoutubeTable){
  [Void]$synchash.YoutubeTable.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
  [Void]$synchash.YoutubeTable.AddHandler([System.Windows.Controls.Button]::PreviewMouseDoubleClickEvent,$synchash.PlayMedia_Command)
}
if($synchash.TwitchTable){
  [Void]$synchash.TwitchTable.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
  [Void]$synchash.TwitchTable.AddHandler([System.Windows.Controls.Button]::PreviewMouseDoubleClickEvent,$synchash.PlayMedia_Command)
}
#---------------------------------------------- 
#endregion ContextMenu Routed Event Handlers
#----------------------------------------------

#---------------------------------------------- 
#region Initialize Vlc Startup
#----------------------------------------------
$initialize_VLC_Runspace = {
  try{
    if($thisApp.Config.startup_perf_timer){
      $Initialize_VLC_Runspace_Measure = [system.diagnostics.stopwatch]::StartNew()
    }
    $libvlc_Assemblies = @(
      "$($thisApp.Config.Current_Folder)\Assembly\Libvlc\LibVLCSharp.dll"
    ) 
    foreach($a in $libvlc_Assemblies){
      if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Loading Libvlc assembly: $a" -Dev_mode}
      [Void][System.Reflection.Assembly]::LoadFrom($a)
    }     
    if([bool]('LibVLCSharp.Core' -as [Type])){
      $libvlc_Version = 4
    }elseif([bool]('LibVLCSharp.Shared.Core' -as [Type])){
      $libvlc_Version = 3
    }
    write-ezlogs "#### STARTUP - Initializing new Libvlc - $($libvlc_Version)" -showtime -logtype Libvlc -loglevel 2 -linesbefore 1
    if($libvlc_Version -ge 4 -and $thisapp.config.Libvlc_Version -ne '4'){
      $thisapp.config.Libvlc_Version = '4'
    }elseif($thisapp.config.Libvlc_Version -ne '3'){
      $thisapp.config.Libvlc_Version = '3'
    }
    if($thisApp.Config.Libvlc_Version -eq '4'){
      [void][LibVLCSharp.Core]::Initialize("$($thisApp.Config.Current_folder)\Resources\Libvlc")
      if(![System.IO.File]::Exists("$($thisApp.Config.Current_folder)\Resources\Libvlc\plugins\plugins.dat") -or $ResetPluginCache){
        $synchash.libvlc = [LibVLCSharp.LibVLC]::new('--file-logging',"--logfile=$($thisapp.config.Vlc_Log_file)","--log-verbose=$($thisapp.config.Vlc_Verbose_logging)","--reset-plugins-cache")
      }else{
        $synchash.libvlc = [LibVLCSharp.LibVLC]::new('--file-logging',"--logfile=$($thisapp.config.Vlc_Log_file)","--log-verbose=$($thisapp.config.Vlc_Verbose_logging)")
      }     
    }else{
      [void][LibVLCSharp.Shared.Core]::Initialize("$($thisApp.Config.Current_folder)\Resources\Libvlc")
      if(![System.IO.File]::Exists("$($thisApp.Config.Current_folder)\Resources\Libvlc\plugins\plugins.dat") -or $ResetPluginCache){
        $synchash.libvlc = [LibVLCSharp.Shared.LibVLC]::new('--file-logging',"--logfile=$($thisapp.config.Vlc_Log_file)","--log-verbose=$($thisapp.config.Vlc_Verbose_logging)","--reset-plugins-cache")
      }else{
        $synchash.libvlc = [LibVLCSharp.Shared.LibVLC]::new('--file-logging',"--logfile=$($thisapp.config.Vlc_Log_file)","--log-verbose=$($thisapp.config.Vlc_Verbose_logging)")
      }      
    }
    if($thisApp.Config.Installed_AppID -and !$freshStart){
      $appid = $thisApp.Config.Installed_AppID
    }else{
      $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
      $thisApp.Config.Installed_AppID = $appid
    } 
    if($appid){
      [void]$synchash.libvlc.SetAppId($appid,"$($thisApp.Config.App_Version)","$($thisapp.Config.Current_folder)\Resources\Samson_Icon_NoText1.ico")
    }
    [void]$synchash.libvlc.SetUserAgent("$($thisApp.Config.App_Name) Media Player","HTTP/User/Agent")
    #TODO: Is it really needed to save config here?
    <#    try{     
        write-ezlogs ">>>> Saving app config: $($thisapp.Config.Config_Path)" -showtime
        Export-SerializedXML -InputObject $thisApp.Config -Path $thisapp.Config.Config_Path -isConfig
        }catch{
        write-ezlogs "An exception occurred when saving config file to path $App_Settings_File_Path" -showtime -catcherror $_
    }#>
    $synchash.Initialize_Vlc_timer.start()
  }catch{
    write-ezlogs 'An exception occurred An exception occurred initializing libvlc' -showtime -catcherror $_
  }finally{
    if($Initialize_VLC_Runspace_Measure){
      $Initialize_VLC_Runspace_Measure.Stop()
      write-ezlogs "initialize_VLC_Runspace" -PerfTimer $Initialize_VLC_Runspace_Measure -GetMemoryUsage:$thisApp.Config.Memory_perf_measure
      $Initialize_VLC_Runspace_Measure = $Null
    }
  }
}
Start-Runspace -scriptblock $initialize_VLC_Runspace -StartRunspaceJobHandler -runspace_name 'initialize_VLC_Runspace' -thisApp $thisApp -synchash $synchash -RestrictedRunspace -function_list Write-EZLogs,Get-AllStartApps,Export-SerializedXML
#---------------------------------------------- 
#endregion Initialize Vlc Startup
#----------------------------------------------

#---------------------------------------------- 
#region Playlists/Queue Startup
#----------------------------------------------
if($thisApp.Config.Startup_perf_timer){
  $get_playlists_Startup_Measure =[system.diagnostics.stopwatch]::StartNew()
}
$synchashWeak = ([System.WeakReference]::new($synchash))
Get-Playlists -verboselog:$thisApp.Config.Verbose_Logging -synchashWeak $synchashWeak -thisApp $thisapp -Startup -use_Runspace
Get-PlayQueue -verboselog:$false -synchashWeak $synchashWeak -thisApp $thisapp -use_Runspace -Import_Playlists_Cache
if($get_playlists_Startup_Measure){
  $get_playlists_Startup_Measure.Stop()
  write-ezlogs "Get-Playlists/Queue Startup" -PerfTimer $get_playlists_Startup_Measure
  $get_playlists_Startup_Measure = $Null
}
#---------------------------------------------- 
#endregion Playlists/Queue Startup
#----------------------------------------------

#############################################################################
#region Button And Event Hanlders
#############################################################################
if($thisApp.Config.startup_perf_timer){
  $Button_Event_Handler_Measure = [system.diagnostics.stopwatch]::StartNew()
}
#---------------------------------------------- 
#region TinyDesk Button
#----------------------------------------------
if($synchash.TinyDesk_Button){
  [System.Windows.RoutedEventHandler]$synchash.TinyDesk_button_Command = {
    param($sender)
    try{
      Get-TinyDesk -thisApp $thisApp -synchash $synchash -Verboselog
    }catch{
      write-ezlogs 'An exception occurred in TinyDesk_button_Command click event' -showtime -catcherror $_
    }
  }
  [Void]$synchash.TinyDesk_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.TinyDesk_button_Command)
}
#---------------------------------------------- 
#endregion TinyDesk Button
#----------------------------------------------

#---------------------------------------------- 
#region Test_Notification Button
#----------------------------------------------
if(($dev_mode -or $debug_mode) -and $synchash.ChatBot_Button -and [system.io.file]::Exists("$($thisApp.Config.Current_Folder)\Resources\API\OPENAI-API-Config.xml")){
  $synchash.ChatBot_Button.Visibility='Visible'
  $synchash.ChatBot_Button.isEnabled=$true
  $synchash.ChatBot_Button_Icon.Source = "$($thisApp.Config.Current_Folder)\Resources\Samson_Icon_NoText1.ico"
  [System.Windows.RoutedEventHandler]$synchash.Test_Notification_Command  = {
    param($sender)
    try{
      $sendername = 'OpenAI'
      $WindowHash = Get-Variable -Name 'hashOpenAIWindow' -ValueOnly -ErrorAction SilentlyContinue
      if($WindowHash.Window.isVisible){
        write-ezlogs "OpenAI Window is already open" -loglevel 2
        Update-ChildWindow -synchash $synchash -thisApp $thisApp -Control 'Window' -Method 'Activate' -sendername 'OpenAI'
        Update-ChildWindow -synchash $synchash -thisApp $thisApp -sendername 'OpenAI'-NewDialog
      }else{
        $windowtitle = "Chat with Samson -  $($thisApp.Config.App_Name) Media Player - $($thisApp.Config.App_Version)"    
        Show-ChildWindow -synchash $synchash -thisApp $thisApp -WindowTitle $windowtitle -Logo "$($thisapp.Config.Current_Folder)\Resources\Skins\Samson_Logo_Title.png" -sendername $sendername -Message "Ask me a question..." -Prompt
      }
    }catch{
      write-ezlogs 'An exception occurred in Hell_button_Command click event' -showtime -catcherror $_
    }
  }
  [Void]$synchash.ChatBot_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Test_Notification_Command)
}
#---------------------------------------------- 
#endregion Test_Notification Button
#----------------------------------------------

#---------------------------------------------- 
#region Hell Button
#----------------------------------------------
if([system.io.file]::Exists("$($thisApp.Config.Current_Folder)\Resources\Fun\devilutionx\devilutionx.exe") -and [system.io.file]::Exists("$($thisApp.Config.Current_Folder)\Resources\Fun\devilutionx\diabdat.mpq") -and $synchash.Hell_Button){
  [System.Windows.RoutedEventHandler]$synchash.Hell_button_Command = {
    param($sender)
    try{
      $Devilutionx = "$($thisApp.Config.Current_Folder)\Resources\Fun\devilutionx\devilutionx.exe"
      $process = Get-Process devilutionx*
      if($process){
        write-ezlogs ">>>> Devilutionx is already running" -loglevel 2
      }elseif([system.io.file]::Exists($Devilutionx)){
        write-ezlogs ">>>> Launching Devilutionx: $($Devilutionx)" -loglevel 2
        $Process = Start-Process $Devilutionx -PassThru      
        $frame = [System.Windows.Threading.DispatcherFrame]::new()
        $frame.Dispatcher.BeginInvoke([Action]{
            write-ezlogs ">>>> Waiting for process to start" -loglevel 2
            [System.Threading.Thread]::Sleep(1000)
            $frame.Continue = $false;
        })
        $push = [System.Windows.Threading.Dispatcher]::PushFrame($frame)
      }
      $process = Get-Process devilutionx*

      #Register window to installed application ID
      if($process.MainWindowHandle){
        if($thisApp.Config.Installed_AppID){
          $appid = $thisApp.Config.Installed_AppID
        }else{
          $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
        }
        if($process.MainWindowHandle -and $appid){
          $taskbarinstance = [Microsoft.WindowsAPICodePack.Taskbar.TaskbarManager]::Instance
          write-ezlogs ">>>> Registering Devilutionx window handle: $($process.MainWindowHandle) -- to appid: $appid" -Dev_mode
          $taskbarinstance.SetApplicationIdForSpecificWindow($process.MainWindowHandle,$appid)
          $thisapp.config.Installed_AppID = $appid
        }
      }
    }catch{
      write-ezlogs 'An exception occurred in Hell_button_Command click event' -showtime -catcherror $_
    }
  }
  $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\Hell1.png")
  $image = [System.Windows.Media.Imaging.BitmapImage]::new()
  [void]$image.BeginInit()
  $image.CacheOption = "OnLoad"
  $image.DecodePixelWidth = "128"
  $image.StreamSource = $stream_image
  [void]$image.EndInit()
  [void]$stream_image.Close()
  [void]$stream_image.Dispose()
  $stream_image = $Null
  [void]$image.Freeze()
  $synchash.Hell_Button_Icon.Source = $image
  $image = $Null
  [void]$synchash.Hell_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Hell_button_Command)
}elseif($synchash.Hell_Button){
  $synchash.Hell_Button.isEnabled = $false
  $synchash.Hell_Button.Visibility = 'Collapsed'
}
#---------------------------------------------- 
#endregion Hell Button
#----------------------------------------------

#---------------------------------------------- 
#region Dispose Button (Dev)
#----------------------------------------------
if($synchash.Dispose_Button -and ($thisApp.Config.Dev_mode -or $Enable_Test_Features)){
  $synchash.Dispose_Button.Visibility = 'Visible'
  $synchash.Dispose_Button.isEnabled = $true
  [System.Windows.RoutedEventHandler]$Tree_Dispose_button_Command = {
    param($sender)
    try{
      #[void](Clear-WorkingMemory)
      [void][ScriptBlock].GetMethod('ClearScriptBlockCache', [System.Reflection.BindingFlags]'Static,NonPublic').Invoke($Null, $Null)
      write-ezlogs "Runspaces: | $($thisApp.Jobs.name)`n | $(Get-MemoryUsage -forceCollection)" -showtime
    }catch{
      write-ezlogs 'An exception occurred in Dispose_Button click event' -showtime -catcherror $_
    }
  }
  [Void]$synchash.Dispose_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Tree_Dispose_Button_Command)
}elseif($synchash.Dispose_Button){
  $synchash.Dispose_Button.isEnabled = $false
  $synchash.Dispose_Button.visibility = 'Collapsed'
}
#---------------------------------------------- 
#endregion Dispose Button (Dev)
#----------------------------------------------

#---------------------------------------------- 
#region Hotkeys_Button (Dev)
#TODO: WIP
#----------------------------------------------
if($synchash.Hotkeys_Button){
  $synchash.Hotkeys_Button.Visibility = 'Visible'
  $synchash.Hotkeys_Button.isEnabled = $true
  [System.Windows.RoutedEventHandler]$Hotkeys_Button_Command = {
    param($sender)
    try{
      Get-GlobalHotKeys -thisApp $thisApp -synchash $synchash -UnRegister -Register:$sender.isChecked
    }catch{
      write-ezlogs 'An exception occurred in Dispose_button click event' -showtime -catcherror $_
    }
  }
  [Void]$synchash.Hotkeys_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$Hotkeys_Button_Command)
}
#---------------------------------------------- 
#endregion Hotkeys_Button (Dev)
#----------------------------------------------

#---------------------------------------------- 
#region Screenshot Button
#----------------------------------------------
if($synchash.ScreenShot_Button){
  $synchash.ScreenShot_Button.isEnabled = $thisApp.Config.Video_Snapshots
  [System.Windows.RoutedEventHandler]$synchash.Screenshot_button_Command  = {
    param($sender)
    try{
      if($thisApp.Config.Video_Snapshots){
        if([System.io.Directory]::Exists($thisApp.Config.Snapshots_Path)){
          $outputDir = $thisApp.Config.Snapshots_Path
        }else{
          $outputDir = $thisApp.Config.Temp_Folder
          if($thisApp.Config.Snapshots_Path){
            write-ezlogs "The existing snapshots path is not valid $($thisApp.Config.Snapshots_Path) - defaulting to $($thisApp.Config.Temp_Folder)" -showtime -warning
            Update-Notifications  -Level 'WARNING' -Message "The existing snapshots path ($($thisApp.Config.Snapshots_Path)) is not valid - defaulting to $($thisApp.Config.Temp_Folder)" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
          }
        }
        if($synchash.PlayQueue_TreeView.Nodes){
          $Current_playing = $synchash.PlayQueue_TreeView.Nodes.content | where  {$_.id -eq $synchash.Current_playing_media.id} | select -Unique
        }else{
          $Current_playing = $synchash.PlayQueue_TreeView.Items | where  {$_.id -eq $synchash.Current_playing_media.id} | select -Unique
        }
        if($Current_playing.title){
          $title = "$($Current_playing.title)_$(Get-date -Format 'MM-dd-yyyy_hh-mm-ss_tt')" -replace '---> ' -replace ':'
        }else{
          $title = "$($thisApp.Config.App_Name)_$(Get-date -Format 'MM-dd-yyyy_hh-mm-ss_tt')"
        }
        $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
        $pattern = "[$illegal]"
        $title = ([Regex]::Replace($title, $pattern, '')).trim()
        if($synchash.vlc){
          $Script:Output_Snapshot_File = "$($outputDir)\$title.png"
          $snapshot = $synchash.vlc.TakeSnapshot(0,$Output_Snapshot_File,0,0)
          if($snapshot){
            write-ezlogs "Video Snapshot: $Output_Snapshot_File" -showtime
            if([system.io.file]::Exists($Output_Snapshot_File)){
              $ActionScriptBlock = {
                #IDE needs this declaration as it apparently doesnt understand variable scoping!
                $Output_Snapshot_File = $Output_Snapshot_File
                write-ezlogs ">>>> Opening file: $($Output_Snapshot_File)"
                start-process $Output_Snapshot_File -ErrorAction SilentlyContinue
                $Output_Snapshot_File = $Null
              }
            }
            Update-Notifications  -Level 'INFO' -Message "Saved video screenshot: $Output_Snapshot_File" -VerboseLog -Message_color 'Cyan' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace -ActionScriptBlock $ActionScriptBlock -ActionName 'Open'
          }else{
            write-ezlogs "No Video snapshot was generated" -showtime -warning
            Update-Notifications  -Level 'WARNING' -Message "No Video snapshot generated, verify a video is playing and viewable. Check logs for details" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
          }
        }else{
          write-ezlogs "Unable to take video snapshot, Libvlc is not initialized!" -showtime -warning
        }
        if($thisApp.Config.App_Snapshots){
          #$synchash.vlc.ToggleFullscreen()
          $topmost_before =  $synchash.Window.Topmost
          $synchash.Window.Topmost = $true
          $synchash.Window.Activate()
          $screenshot = New-ScreenShot -outFolder $outputDir -tempPath $outputDir -fps 60 -screen_Capture_Duration 1 -captureCursor 1 -Verbose
          if($screenshot){
            write-ezlogs "App Snapshot: $screenshot" -showtime
            if([system.io.file]::Exists($screenshot)){
              $Script:Output_screenshot_File = $screenshot
              $ActionScriptBlock2 = {
                #IDE needs this declaration as it apparently doesnt understand variable scoping!
                $Output_screenshot_File = $Output_screenshot_File
                write-ezlogs ">>>> Opening file: $($Output_screenshot_File)"
                start-process $Output_screenshot_File -ErrorAction SilentlyContinue
                $Output_screenshot_File = $Null     
              }
            }
            Update-Notifications  -Level 'INFO' -Message "Saved App Snapshot: $screenshot" -VerboseLog -Message_color 'Cyan' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace -ActionScriptBlock $ActionScriptBlock2 -ActionName 'Open'
          }else{
            write-ezlogs "No Screenshot was generated" -showtime -warning
            Update-Notifications  -Level 'WARNING' -Message "Something went wrong, no App Snapshot generated! See logs" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -No_runspace
          }
          $synchash.Window.Topmost = $topmost_before
        }
      }
      #start $thisApp.Config.Temp_Folder
    }catch{
      write-ezlogs 'An exception occurred in Screenshot_button_Command' -showtime -catcherror $_
    }
  }
  [Void]$synchash.ScreenShot_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Screenshot_button_Command)
}
#---------------------------------------------- 
#endregion Screenshot Button
#----------------------------------------------

#---------------------------------------------- 
#region Show_Library_button Button
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.Show_Video_Button_CLick_Command = {
  param($sender)
  try{   
    if($synchash.VideoButton_ToggleButton.isChecked){
      $Action = 'Open'
    }else{
      $Action = 'Close'
    }
    Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action $Action
  }catch{
    write-ezlogs 'An exception occurred in Show_Video_Button_Checked_Command event' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Show_Library_button Button
#----------------------------------------------

#---------------------------------------------- 
#region Detach Media Player Button
#----------------------------------------------
#Fullscreen Window
[System.Windows.RoutedEventHandler]$synchash.Detach_Library_button_Command = {
  param($sender)
  try{
    if($synchash.MediaLibraryAnchorable.IsHidden){
      $synchash.MediaLibraryAnchorable.Show()
    }
    if($synchash.MediaLibraryAnchorable.isFloating){
      $synchash.MediaLibraryAnchorable.dock()
      if($synchash.VideoView.Visibility -eq 'Visible' -and $synchash.MediaViewAnchorable){
        $synchash.MediaViewAnchorable.isSelected = $true
      }
      $synchash.LibraryButton_ToggleButton.isChecked = $false
    }else{
      #$synchash.MediaLibrary_Grid.MinHeight="300"
      if($synchash.MediaLibraryFloat.Height){
        $synchash.MediaLibraryAnchorable.FloatingHeight = $synchash.MediaLibraryFloat.Height
      }else{
        $synchash.MediaLibraryAnchorable.FloatingHeight = '400'
      }
      $ScreenBounds = [Windows.Forms.SystemInformation]::VirtualScreen
      if($synchash.Window.isVisible -and [int]$synchash.Window.Left -ge $ScreenBounds.left){
        $synchash.MediaLibraryAnchorable.FloatingLeft = $synchash.Window.Left
      }else{
        $synchash.MediaLibraryAnchorable.FloatingLeft = '0'
      }
      if($synchash.Window -and !$synchash.Window.IsLoaded -and $synchash.MiniPlayer_Viewer.isVisible){
        [Void]$synchash.Window.Dispatcher.InvokeAsync{
          $synchash.Window.Opacity = 0
          $synchash.window.ShowActivated = $false
          $synchash.window.ShowInTaskbar = $false
          $synchash.Window.show()
          $synchash.Window.Activate()
          $synchash.MediaLibraryAnchorable.float()
          #$synchash.Window.hide()
          #$synchash.Window.Opacity = 1
        }
      }else{
        $synchash.MediaLibraryAnchorable.float()  
      }
      $synchash.MediaLibraryAnchorable.isSelected = $true
      $synchash.LibraryButton_ToggleButton.isChecked = $true  
      #$synchash.MediaLibrary_Flyout.isOpen = $true 
    }
    if($synchash.MediaLibraryFloat.isVisible){
      $synchash.MediaLibraryFloat.Activate()
    }   
  }catch{
    write-ezlogs 'Exception occurred opening new webview2 window for MediaLibrary_Viewer' -showtime -catcherror $_
  }                            
}
#---------------------------------------------- 
#endregion Detach Media Player Button
#----------------------------------------------

#---------------------------------------------- 
#region Show Audio Options
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.Audio_Options_Command = {
  param($sender)
  try{
    if(!$synchash.AudioOptions_Viewer.isVisible){
      $synchash.AudioButton_ToggleButton.isChecked = $true
      write-ezlogs '[AudioOptions_Viewer_Command] >>>> Attempting to open AudioOptions_Viewer' -showtime
      $XamlAudioOptions_Viewer = [System.IO.File]::ReadAllText("$($Current_folder)\Views\AudioOptionsViewer.xaml").replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml") 
      $AudioOptions_windowXaml = [Windows.Markup.XAMLReader]::Parse($XamlAudioOptions_Viewer)
      $reader = [XML.XMLReader]::Create([IO.StringReader]$XamlAudioOptions_Viewer)
      while ($reader.Read())
      {
        $name=$reader.GetAttribute('Name')
        if($name -and $AudioOptions_windowXaml){
          $synchash."$($name)" = $AudioOptions_windowXaml.FindName($name)
        }
      }
      $reader.Dispose()
      if($synchash.RootGrid.children -contains $synchash.AudioOptions_Grid){
        [Void]$synchash.RootGrid.children.Remove($synchash.AudioOptions_Grid)
      }      
      if($synchash.AudioOptions_Viewer.content -notcontains $synchash.AudioOptions_Grid){
        [Void]$synchash.AudioOptions_Viewer.addChild($synchash.AudioOptions_Grid)
      }

      if($thisApp.Config.Current_Theme -ne $null -and $thisApp.Config.Current_Theme.Name){
        $theme = [MahApps.Metro.Theming.MahAppsLibraryThemeProvider]::new()
        $themes = $theme.GetLibraryThemes()
        $themeManager = [ControlzEx.Theming.ThemeManager]::new()
        $detectTheme = $thememanager.DetectTheme($synchash.Window)
        if($thisApp.Config.Verbose_logging){write-ezlogs "[AudioOptions_Viewer_Command] >>>> Setting Current Theme: $($detectTheme | out-string)" -showtime}
        $newtheme = $themes | & { process {
            if($_.Name -eq $thisApp.Config.Current_Theme.Name){
              $_
            }
        }}
        #$newtheme = $themes | Where-Object {$_.Name -eq $thisApp.Config.Current_Theme.Name}
        if($newtheme){
          $thememanager.RegisterLibraryThemeProvider($newtheme.LibraryThemeProvider)
          if($synchash.AudioOptions_Viewer){
            $thememanager.ChangeTheme($synchash.AudioOptions_Viewer,$newtheme.Name,$false)
          }
          if($synchash.Audio_Flyout_Control){
            $thememanager.ChangeTheme($synchash.Audio_Flyout_Control,$newtheme.Name,$false)
          }
        }
        if($themes){
          [Void]$themes.Dispose() 
        } 
        $themeManager.ClearThemes()
        $thememanager = $Null
      }
      $gradientbrush = [System.Windows.Media.LinearGradientBrush]::new()
      $gradientbrush.StartPoint = '0.5,0'
      $gradientbrush.EndPoint = '0.5,1'
      $gradientstop1 = [System.Windows.Media.GradientStop]::new()
      $gradientstop1.Color = 'Black'
      $gradientstop1.Offset= '0.4'
      $gradientstop2 = [System.Windows.Media.GradientStop]::new()
      $gradientstop2.Color = 'Transparent'
      $gradientstop2.Offset= '0.6'
      $gradientstop_Collection = [System.Windows.Media.GradientStopCollection]::new()
      [Void]$gradientstop_Collection.Add($gradientstop1)
      [Void]$gradientstop_Collection.Add($gradientstop2)
      $gradientbrush.GradientStops = $gradientstop_Collection  
      $synchash.AudioOptions_Viewer.Background = $gradientbrush
      $synchash.AudioOptions_Viewer.style = $synchash.Window.TryFindResource('WindowChromeStyle')
      $synchash.AudioOptions_Viewer.icon = "$($thisapp.Config.Current_folder)\Resources\Samson_Icon_NoText1.ico"
      $synchash.AudioOptions_Viewer.icon.Freeze()
      $synchash.AudioOptions_Title_menu_Image.Source = "$($thisapp.Config.Current_folder)\Resources\Samson_Icon_NoText1.ico"
      $synchash.AudioOptions_Title_menu_Image.width = '18'
      $synchash.AudioOptions_Title_menu_Image.Height = '18'
      $synchash.AudioOptions_Viewer.Title = "Audio Options - $($thisApp.Config.App_Name) Media Player"
      $synchash.AudioOptions_DockPanel_Label.Content = "Audio Options - $($thisApp.Config.App_Name)"
      $synchash.AudioOptions_Viewer.TaskbarItemInfo.Description = "Audio Options - $($thisApp.Config.App_Name) Media Player - $($thisApp.Config.App_Version)"      
      $synchash.AudioOptions_Viewer.IsWindowDraggable = 'True'
      $synchash.AudioOptions_Viewer.ShowTitleBar = $true
      $synchash.AudioOptions_Viewer.UseNoneWindowStyle = $false
      $synchash.AudioOptions_Viewer.WindowStyle = 'none'
      $synchash.AudioOptions_Viewer.IgnoreTaskbarOnMaximize = $true
      if($syncHash.AudioOptions_Background_Image_Source -and [system.io.file]::Exists("$($Current_Folder)\Resources\Skins\Audio\EQ_SkinThin_Main.png")){
        $stream_image = [System.IO.File]::OpenRead("$($Current_Folder)\Resources\Skins\Audio\EQ_SkinThin_Main.png")
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        [void]$image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "1630"
        $image.StreamSource = $stream_image
        [void]$image.EndInit()
        [void]$stream_image.Close()
        [void]$stream_image.Dispose()
        $stream_image = $Null
        [void]$image.Freeze()
        $syncHash.AudioOptions_Background_Image_Source.Source = $image
        $syncHash.AudioOptions_Background_Image_Source.Height="270"
        $image = $Null
      }
      if($syncHash.AudioOptions_Background_Image_Source2 -and [system.io.file]::Exists("$($Current_Folder)\Resources\Skins\Audio\EQ_SkinThin_Feet.png")){
        $stream_image = [System.IO.File]::OpenRead("$($Current_Folder)\Resources\Skins\Audio\EQ_SkinThin_Feet.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        [void]$image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "1546"
        $image.StreamSource = $stream_image
        [void]$image.EndInit()
        [void]$stream_image.Close()
        [void]$stream_image.Dispose()
        $stream_image = $Null
        [void]$image.Freeze()
        $syncHash.AudioOptions_Background_Image_Source2.Source = $image
        $syncHash.AudioOptions_Background_Image_Source2.Width="1630"
        $syncHash.AudioOptions_Background_Image_Source2.Height="58"
        $image = $Null
      }
      if($syncHash.EQButton -and [system.io.file]::Exists("$($Current_Folder)\Resources\Skins\Audio\EQ_ToggleButton.png")){
        $stream_image = [System.IO.File]::OpenRead("$($Current_Folder)\Resources\Skins\Audio\EQ_ToggleButton.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        [void]$image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "86"
        $image.StreamSource = $stream_image
        [void]$image.EndInit()
        [void]$stream_image.Close()
        [void]$stream_image.Dispose()
        $stream_image = $Null
        [void]$image.Freeze()
        $syncHash.EQButton.Source = $image
        $image = $Null
      } 
      if($syncHash.EQPowerPowerButton -and [system.io.file]::Exists("$($Current_Folder)\Resources\Skins\Audio\EQ_PowerToggleButton.png")){
        $stream_image = [System.IO.File]::OpenRead("$($Current_Folder)\Resources\Skins\Audio\EQ_PowerToggleButton.png") 
        $image = [System.Windows.Media.Imaging.BitmapImage]::new()
        [void]$image.BeginInit()
        $image.CacheOption = "OnLoad"
        $image.DecodePixelWidth = "86"
        $image.StreamSource = $stream_image
        [void]$image.EndInit()
        [void]$stream_image.Close()
        [void]$stream_image.Dispose()
        $stream_image = $Null
        [void]$image.Freeze()
        $syncHash.EQPowerPowerButton.Source = $image      
        $synchash.EQPower_ToggleButton.isChecked = $true
        $image = $Null
      } 
      [System.Windows.RoutedEventHandler]$synchash.AudioOptions_LeftButtonDownCommand = {
        param($sender,[System.Windows.Input.MouseButtonEventArgs]$e)
        try{
          if($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Pressed -and $e.RoutedEvent.Name -eq 'MouseLeftButtonDown')
          {
            $synchash.AudioOptions_Viewer.DragMove()
            $e.handled = $true
          }
        }catch{
          write-ezlogs "An exception occurred in AudioOptions_Viewer MouseLeftButtonDown event" -showtime -catcherror $_
        }
      } 
      
      [System.Windows.RoutedEventHandler]$synchash.PreviewGotKeyboardFocus_Event = {
        Param($sender,[System.Windows.Input.KeyboardFocusChangedEventArgs]$e)
        try{
          write-ezlogs ">>>> $($sender.Title) got keyboard focus event: oldfocus: $($e.oldfocus.name) - NewFocus: $($e.newFocus.name)" -Dev_mode
          if($sender.isVisible -and !$e.oldFocus -and $e.newFocus){  
            $e.handled = $false
            if($hashsetup.Window.isVisible -and !$hashsetup.Window.Topmost){
              write-ezlogs " | Activating settings window: $($hashsetup.Window.isVisible)" -Dev_mode
              Update-SettingsWindow -hashsetup $hashSetup -thisApp $thisApp -BringToFront
            }                   
            if(!$sender.Topmost){
              $isNotTopMost = $true
              $sender.Topmost = $true
            }                   
            if($synchash.Window.isVisible -and !$synchash.Window.Topmost){
              write-ezlogs " | Activating Main window" -Dev_mode
              $synchash.Window.Topmost = $true
              $synchash.Window.Topmost = $false
            }
            if($synchash.MediaLibraryFloat.isVisible -and !$synchash.MediaLibraryFloat.Topmost){
              write-ezlogs " | Activating MediaLibraryFloat window" -Dev_mode
              $synchash.MediaLibraryFloat.Topmost = $true
              $synchash.MediaLibraryFloat.Topmost = $false
            }  
            if($isNotTopMost){
              $sender.Topmost = $false
              $sender.Activate()
            }                                                  
          }
        }catch{
          write-ezlogs "An exception occurred in Window.add_PreviewGotKeyboardFocus" -showtime -catcherror $_
        }
      }     
      [System.Windows.RoutedEventHandler]$synchash.AudioOptions_Loaded_Event = {
        try{
          if($synchash.Audio_Flyout){
            $synchash.Audio_Flyout.IsOpen = $true
          } 
          #Register window to installed application ID 
          $Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($synchash.AudioOptions_Viewer)     
          if($thisApp.Config.Installed_AppID){
            $appid = $thisApp.Config.Installed_AppID
          }else{
            $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
          }
          if($Window_Helper.Handle -and $appid){
            $taskbarinstance = [Microsoft.WindowsAPICodePack.Taskbar.TaskbarManager]::Instance
            write-ezlogs ">>>> Registering AudioOptions_Viewer window handle: $($Window_Helper.Handle) -- to appid: $appid" -Dev_mode
            $taskbarinstance.SetApplicationIdForSpecificWindow($Window_Helper.Handle,$appid)    
            Add-Member -InputObject $thisapp.config -Name 'Installed_AppID' -Value $appid -MemberType NoteProperty -Force
          }                
        }catch{
          write-ezlogs "An exception occurred in AudioOptions_Viewer.add_loaded" -catcherror $_
        } 
      }  
      $synchash.AudioOptions_Closing_Event = {
        try{
          $synchash.Audio_Flyout.IsOpen = $false
          $EQ_Preamp = $synchash.Preamp_Slider.Value
          $current_EQ_Bands = $thisapp.Config.EQ_Bands             
          if(-not [string]::IsNullOrEmpty($thisapp.Config.EQ_Selected_Preset)){
            $preset_name = $thisapp.Config.EQ_Selected_Preset 
            $preset = Add-EQPreset -PresetName $preset_name -EQ_Bands $current_EQ_Bands -EQ_Preamp $EQ_Preamp -thisApp $thisapp -synchash $synchash -verboselog
          }                           
          if($preset.Preset_Name){
            if($synchash.LoadPreset_Button.items.header -notcontains $preset.Preset_Name -and $preset.Preset_Name -ne 'Memory 1' -and $preset.Preset_Name -ne 'Memory 2' -and $thisapp.config.EQ_Presets.Preset_Name -notcontains $preset.Preset_Name){
              $Menuitem = [System.Windows.Controls.MenuItem]::new()
              $Menuitem.IsCheckable = $true
              $Menuitem.Header = $preset.Preset_Name
              if($thisapp.config.EQ_Selected_Preset -eq $Menuitem.Header){
                $Menuitem.isChecked = $true
              }
              [Void](Get-EventHandlers -Element $Menuitem -RoutedEvent ([System.Windows.Controls.MenuItem]::ClickEvent) -RemoveHandlers)
              #[Void]$Menuitem.RemoveHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.EQPreset_Menuitem_Command) 
              [Void]$Menuitem.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$Synchash.EQPreset_Menuitem_Command)
              [Void]$synchash.LoadPreset_Button.items.add($Menuitem)      
            }else{
              write-ezlogs "An existing preset with name $preset_name already exists -- updated to current values" -showtime -warning
            }                                
          }
          if($synchash.AudioOptions_Viewer.content -contains $synchash.AudioOptions_Grid){
            $synchash.AudioOptions_Viewer.content = $null
          } 
          if($synchash.RootGrid.children -notcontains $synchash.AudioOptions_Grid){
            [Void]$synchash.RootGrid.children.Add($synchash.AudioOptions_Grid)
          }
          $thisapp.Config.EQ_Preamp = $EQ_Preamp
        }catch{
          write-ezlogs "An exception occurred in AudioOptions_Viewer.add_closing" -showtime -catcherror $_
        }
      } 
      $synchash.AudioOptions_Closed_Event = {
        try{
          $synchash.EQ_Timer.start()               
          write-ezlogs ">>>> Audio Options Closed" -loglevel 2
        }catch{
          write-ezlogs "An exception occurred in AudioOptions_Viewer.add_closed" -showtime -catcherror $_
        }
      } 
      [System.Windows.RoutedEventHandler]$synchash.AudioOptions_UnLoaded_Event = {
        Param($sender)    
        try{         
          $Element = [System.WeakReference]::new($sender).Target
          [Void](Get-EventHandlers -Element $Element -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::MouseLeftButtonDownEvent) -RemoveHandlers)
          #$synchash.AudioOptions_Viewer.RemoveHandler([MahApps.Metro.Controls.MetroWindow]::MouseLeftButtonDownEvent,$synchash.AudioOptions_LeftButtonDownCommand)
          $synchash.AudioOptions_LeftButtonDownCommand = $Null
          $synchash.Remove('AudioOptions_LeftButtonDownCommand')
          [Void](Get-EventHandlers -Element $Element -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::PreviewGotKeyboardFocusEvent) -RemoveHandlers)
          #$synchash.AudioOptions_Viewer.RemoveHandler([MahApps.Metro.Controls.MetroWindow]::PreviewGotKeyboardFocusEvent,$synchash.PreviewGotKeyboardFocus_Event)
          $synchash.PreviewGotKeyboardFocus_Event = $null
          $synchash.Remove('PreviewGotKeyboardFocus_Event')
          [Void](Get-EventHandlers -Element $Element -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::LoadedEvent) -RemoveHandlers)
          #$synchash.AudioOptions_Viewer.RemoveHandler([MahApps.Metro.Controls.MetroWindow]::LoadedEvent,$synchash.AudioOptions_Loaded_Event)
          $synchash.AudioOptions_Loaded_Event = $Null
          $synchash.Remove('AudioOptions_Loaded_Event')
          $Element.Remove_closing($synchash.AudioOptions_Closing_Event)
          $synchash.AudioOptions_Closing_Event = $Null
          $synchash.Remove('AudioOptions_Closing_Event')
          $Element.Remove_closed($synchash.AudioOptions_Closed_Event)
          $synchash.AudioOptions_Closed_Event = $null
          $synchash.Remove('AudioOptions_Closed_Event')
          [Void](Get-EventHandlers -Element $Element -RoutedEvent ([MahApps.Metro.Controls.MetroWindow]::UnloadedEvent) -RemoveHandlers)
          #$synchash.AudioOptions_Viewer.RemoveHandler([MahApps.Metro.Controls.MetroWindow]::UnloadedEvent,$synchash.AudioOptions_UnLoaded_Event)
          $synchash.AudioOptions_UnLoaded_Event = $null
          $synchash.Remove('AudioOptions_UnLoaded_Event')
          $hashkeys = [System.Collections.ArrayList]::new($synchash.keys)
          $hashkeys | & { process {
              if($sender.FindName($_)){
                if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Unregistering AudioOptions_Viewer UI name: $_" -Dev_mode}
                [void]$sender.UnRegisterName($_)
                [void]$synchash.Remove($_)
              }        
          }}
          write-ezlogs ">>>> AudioOptions_Viewer window $($sender.Name) has unloaded" -showtime -loglevel 2 -GetMemoryUsage -forceCollection
          $sender = $Null
          $hashkeys = $Null
        }catch{
          write-ezlogs "An exception occurred in AudioOptions_Viewer.add_unloaded" -showtime -catcherror $_
        }
      }
      $element = [System.WeakReference]::new($synchash.AudioOptions_Viewer).Target
      #[Void](Get-EventHandlers -Element $element -RoutedEvent ([System.Windows.Controls.MenuItem]::LoadedEvent) -RemoveHandlers)
      [Void](Get-EventHandlers -Element $element -RoutedEvent ([System.Windows.Controls.MenuItem]::UnloadedEvent) -RemoveHandlers)
      $element.AddHandler([MahApps.Metro.Controls.MetroWindow]::PreviewGotKeyboardFocusEvent,$synchash.PreviewGotKeyboardFocus_Event)      
      $element.AddHandler([MahApps.Metro.Controls.MetroWindow]::MouseLeftButtonDownEvent,$synchash.AudioOptions_LeftButtonDownCommand)
      $element.add_closing($synchash.AudioOptions_Closing_Event)
      $element.add_closed($synchash.AudioOptions_Closed_Event)
      $element.AddHandler([MahApps.Metro.Controls.MetroWindow]::loadedEvent,$synchash.AudioOptions_Loaded_Event)
      $element.AddHandler([MahApps.Metro.Controls.MetroWindow]::UnloadedEvent,$synchash.AudioOptions_UnLoaded_Event)
      [void][System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($synchash.AudioOptions_Viewer)
      [Void]$element.Show()
      [Void]$element.Activate()
    }else{
      $synchash.AudioButton_ToggleButton.isChecked = $false
      $synchash.AudioOptions_Viewer.close()
    }
  }catch{
    write-ezlogs 'Exception occurred opening new window for AudioOptions_Viewer' -showtime -catcherror $_
  }                            
}
#---------------------------------------------- 
#endregion Show Audio Options
#----------------------------------------------

#---------------------------------------------- 
#region PlayQueueFlyout
#----------------------------------------------
if($synchash.PlayQueueFlyout){
  try{
    if($thisApp.Config.startup_perf_timer){
      $PlayQueueFlyout_Measure = [system.diagnostics.stopwatch]::StartNew()
    }   
    $PlayQueueFlyoutbrush = [System.Windows.Media.ImageBrush]::new()
    $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\Cassette Door - Blank.png") 
    $image = [System.Windows.Media.Imaging.BitmapImage]::new()
    [void]$image.BeginInit()
    $image.CacheOption = "OnLoad"
    $image.DecodePixelWidth = "735"
    $image.StreamSource = $stream_image
    [void]$image.EndInit()
    [void]$stream_image.Close()
    [void]$stream_image.Dispose()
    $stream_image = $Null
    [void]$image.Freeze()
    $PlayQueueFlyoutbrush.ImageSource = $image 
    $synchash.PlayQueueFlyout.Background=$PlayQueueFlyoutbrush
    $image = $Null
    $PlayQueueFlyoutbrush = $Null
  }catch{
    write-ezlogs "An exception occurred applying images for PlayQueueFlyout" -catcherror $_
  }finally{
    if($PlayQueueFlyout_Measure){
      $PlayQueueFlyout_Measure.stop()
      write-ezlogs "PlayQueueFlyout ImageSource Measure:" -loglevel 2 -logtype Perf -PerfTimer $PlayQueueFlyout_Measure
      $PlayQueueFlyout_Measure = $Null
    }
  }
}
#---------------------------------------------- 
#endregion PlayQueueFlyout
#----------------------------------------------

#---------------------------------------------- 
#region Add/Open Media Button
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $OpenButton_Measure = [system.diagnostics.stopwatch]::StartNew()
}
[System.Windows.RoutedEventHandler]$Synchash.BrowseMedia_Command  = {
  param($sender)
  try{
    $media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)mp4|(?i)flac|(?i)wav|(?i)avi|(?i)wmv|(?i)h264|(?i)mkv|(?i)webm|(?i)h265|(?i)mov|(?i)h264|(?i)mpeg|(?i)mpg4|(?i)movie|(?i)mpgx|(?i)vob|(?i)3gp|(?i)m2ts|(?i)aac))',[System.Text.RegularExpressions.RegexOptions]::Compiled)
    $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
    $pattern = "[$illegal]"
    $ValidPaths = [System.Collections.Generic.List[string]]::new()
    $DuplicatePaths = [System.Collections.Generic.List[string]]::new()
    if($sender.name -eq 'Dialog_BrowseFolders_Button'){
      $synchash.Dialog_StartPlayback_Toggle.isOn = $false
      $synchash.Dialog_StartPlayback_Toggle.isEnabled = $false
      $synchash.Dialog_Add_Button.Content = 'Add Media'
      $results = Open-FolderDialog -Title 'Select the folders you wish to add' -MultiSelect
    }else{
      $synchash.Dialog_StartPlayback_Toggle.isEnabled = $true
      if($synchash.Dialog_StartPlayback_Toggle.isOn){
        $synchash.Dialog_Add_Button.Content = 'Open Media'
      }else{
        $synchash.Dialog_Add_Button.Content = 'Add Media'
      }
      $results = Open-FileDialog -Title 'Select the Media file you wish to Add or Open' -CheckPathExists
    }
    if($results){
      $results | & { process {
          $result_cleaned = $Null
          if([system.io.file]::Exists($_) -or [system.io.directory]::Exists($_)){
            if([system.io.file]::Exists($_) -and ([System.IO.FileInfo]::new($_) | Where-Object {$_.Extension -notmatch $media_pattern})){
              $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
              $Button_Settings.AffirmativeButtonText = 'Ok'
              $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
              $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid Media!","The media file you selected is invalid or unsupported - $_ - halthing further actions",$okandCancel,$Button_Settings)
              write-ezlogs "The media file selected is invalid or unsupported - $_" -showtime -warning -LogLevel 2
              return
            }elseif([system.io.file]::Exists($_) -and ([System.IO.FileInfo]::new($_) | Where-Object {$_.Extension -match $media_pattern})){
              $result_cleaned = ([Regex]::Replace($_, $pattern, '')).trim() 
              if(-not [string]::IsNullOrEmpty($result_cleaned)){  
                write-ezlogs " | Adding Selected Media file Path $_ to Dialog_Local_File_Textbox"          
                [Void]$ValidPaths.add($result_cleaned)   
              }else{
                write-ezlogs "The provided Path is not valid! -- $_" -showtime -warning -LogLevel 2
              }          
            }elseif([system.io.directory]::Exists($_)){
              $Pathroot = [system.io.path]::GetPathRoot($_)
              if($thisApp.Config.Media_Directories -contains $Pathroot){
                write-ezlogs "The provided path ($_) is already included in root path: $Pathroot" -warning
                [Void]$DuplicatePaths.add($_)
              }elseif($thisApp.Config.Media_Directories -notcontains $_){
                $result_cleaned = ([Regex]::Replace($_, $pattern, '')).trim() 
                if(-not [string]::IsNullOrEmpty($result_cleaned)){  
                  write-ezlogs " | Adding Selected Media Path $_ to Dialog_Local_File_Textbox"           
                  [Void]$ValidPaths.add($result_cleaned)   
                }else{
                  write-ezlogs "The provided Path is not valid! -- $_" -showtime -warning -LogLevel 2 
                } 
              }else{
                write-ezlogs "The provided path $_ has already been added" -warning
                [Void]$DuplicatePaths.add($_)
              }
            }            
          }else{
            write-ezlogs "No Path was provided! - $($_)" -showtime -warning
          }      
      }}
      if($DuplicatePaths.count -gt 0){             
        $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
        $Button_Settings.AffirmativeButtonText = 'Ok'
        $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
        $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Duplicate Media!","The following media paths will be skipped as they have already been added or are included in existing root paths:`n$($DuplicatePaths | out-string) ",$okandCancel,$Button_Settings)       
      }
      if($ValidPaths.count -gt 0){             
        $synchash.Dialog_Local_File_Textbox.text = $ValidPaths -join ','    
      }else{
        write-ezlogs "No valid Paths were provided!" -showtime -warning -LogLevel 2
      }  
    }
  }catch{
    write-ezlogs 'An exception occurred in BrowseMedia_Command click event' -showtime -catcherror $_
  }
}

[System.Windows.RoutedEventHandler]$Synchash.Add_Media_Apply_Command  = {
  param($sender)
  try{
    $media_pattern = [regex]::new('$(?<=\.((?i)mp3|(?i)mp4|(?i)flac|(?i)wav|(?i)avi|(?i)wmv|(?i)h264|(?i)mkv|(?i)webm|(?i)h265|(?i)mov|(?i)h264|(?i)mpeg|(?i)mpg4|(?i)movie|(?i)mpgx|(?i)vob|(?i)3gp|(?i)m2ts|(?i)aac))',[System.Text.RegularExpressions.RegexOptions]::Compiled)
    $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
    $pattern = "[$illegal]"
    if(-not [string]::IsNullOrEmpty($synchash.Dialog_Local_File_Textbox.text) -and $synchash.Dialog_Local_File_Textbox.isEnabled){      
      $result = $synchash.Dialog_Local_File_Textbox.text -split ','
      if($result.count -gt 1 -or [system.io.directory]::Exists($result)){     
        $result | & { process {
            if([system.io.directory]::Exists($_)){
              if($thisApp.Config.Media_Directories -notcontains $_){
                $result_cleaned = ([Regex]::Replace($_, $pattern, '')).trim() 
                if(-not [string]::IsNullOrEmpty($result_cleaned)){  
                  write-ezlogs " | Adding Selected Media Path $_ to Media_Directories sources"           
                  [Void]$thisApp.Config.Media_Directories.add($result_cleaned)   
                }else{
                  write-ezlogs "The provided Path is not valid! -- $_" -showtime -warning -LogLevel 2 
                } 
              }else{
                write-ezlogs "The provided path $_ has already been added" -warning
              }
            }      
        }} 
        Update-SettingsWindow -hashsetup $hashsetup -thisApp $thisApp -UpdateMediaDirectories -RefreshLibrary Local 
      }else{
        if([system.io.file]::Exists($result) -or [system.io.directory]::Exists($result)){
          if([system.io.file]::Exists($result) -and ([System.IO.FileInfo]::new($result) | Where{$_.Extension -notmatch $media_pattern})){
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid Media!","The media file you provided is invalid or unsupported - $result",$okandCancel,$Button_Settings)
            write-ezlogs "The media file provided is invalid or unsupported - $result" -showtime -warning -LogLevel 2
            return
          }
          $result_cleaned = ([Regex]::Replace($result, $pattern, '')).trim()      
          if(-not [string]::IsNullOrEmpty($result_cleaned)){             
            write-ezlogs ">>>> Adding Local Media $result_cleaned" -showtime -color cyan -LogLevel 2 -logtype LocalMedia
            Import-Media -Media_Path $result_cleaned -verboselog:$false -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -thisApp $thisapp -StartPlayback:$synchash.Dialog_StartPlayback_Toggle.isOn     
          }else{
            write-ezlogs "The provided Path is not valid! -- $result" -showtime -warning -LogLevel 2 -logtype LocalMedia
          }  
        }else{
          write-ezlogs "No Path was provided! - $($result)" -showtime -warning -LogLevel 2
          $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
          $Button_Settings.AffirmativeButtonText = 'Ok'
          $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
          $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid Media!","The media file you provided is invalid or unsupported - $result",$okandCancel,$Button_Settings)
        }
      }
    }elseif(-not [string]::IsNullOrEmpty($synchash.Dialog_Remote_URL_Textbox.text) -and $synchash.Dialog_Remote_URL_Textbox.isEnabled){
      $result = ($synchash.Dialog_Remote_URL_Textbox.text).trim()
      if((Test-url $result) -and ($result -match 'youtube\.com|yewtu\.be|soundcloud\.com|youtu.be')){       
        if($thisApp.Config.Import_Youtube_Media){
          write-ezlogs ">>>> Adding Youtube video $result" -showtime -color cyan -logtype Youtube
          Import-Youtube -Youtube_URL $result -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -thisApp $thisapp -StartPlayback:$synchash.Dialog_StartPlayback_Toggle.isOn 
        }else{
          write-ezlogs ">>>> Starting temporary Youtube video $result" -showtime -color cyan
          Start-NewMedia -synchash $synchash -thisApp $thisApp -Mediaurl $result -Use_Runspace -MediaType Youtube
          return
        }
      }elseif((Test-url $result)){
        if($result -match 'twitch\.tv'){
          write-ezlogs "The provided URL is twitch - $result" -showtime
          $type = 'Twitch'
        }else{
          write-ezlogs "The provided URL is unknown - $result" -showtime -warning
          $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
          $Button_Settings.AffirmativeButtonText = 'Yes'
          $Button_Settings.NegativeButtonText = 'No'
          $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative
          $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Unknown URL!","The URL you provided does not appear to be an officially supported media type. Playback might or might not work.`n`nDo you wish to continue? - $result",$okandCancel,$Button_Settings)
          $type = 'Other'
        }
        Start-NewMedia -synchash $synchash -thisApp $thisApp -Mediaurl $result -Use_Runspace -MediaType $type
        return
      }else{
        write-ezlogs "The provided URL is invalid or unsupported - $result" -showtime -warning
        $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
        $Button_Settings.AffirmativeButtonText = 'Ok'
        $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
        $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Invalid URL!","The URL you provided is invalid or unsupported - $result",$okandCancel,$Button_Settings)
        return
      } 
    }else{
      write-ezlogs "No URL or file path was provided!" -showtime -warning
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
      $Button_Settings.AffirmativeButtonText = 'Ok'
      $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
      $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Did you forget something?","No URL or file path was provided!",$okandCancel,$Button_Settings)
      return
    }
  }catch{
    write-ezlogs 'An exception occurred in BrowseMedia_Command click event' -showtime -catcherror $_
  }finally{
    if($synchash.YoutubeWebview2_Visibility -and $synchash.YoutubeWebView2){
      $synchash.YoutubeWebView2.Visibility = 'Visible'    
    }    
    if($synchash.VideoView_Visibility  -and $synchash.VideoView){
      $synchash.VideoView.Visibility = 'Visible'    
    }  
    if($synchash.chat_WebView2_Visibility -and $synchash.chat_WebView2){
      $synchash.chat_WebView2.Visibility = 'Visible'    
    }
    if($synchash.Comments_Grid_Visibility -and $synchash.Comments_Grid){
      $synchash.Comments_Grid.Visibility = 'Visible'    
    }
    $synchash.CustomDialog.RequestCloseAsync()
    $synchash.CustomDialog = $null
    $synchash.DialogWindow = $Null
    if($synchash.MiniPlayer_Viewer.isVisible -and $synchash.Window){
      [Void]$synchash.Window.hide()
    }
  }
}

[System.Windows.RoutedEventHandler]$synchash.Add_Media_Command = {
  param($sender)
  try{
    if($synchash.CustomDialog -or $synchash.DialogWindow.IsVisible){
      write-ezlogs "A custom dialog is already open, cannot create another -- args: $($args | out-string)" -Warning
      return
    }elseif($synchash.MiniPlayer_Viewer.isVisible -and $synchash.Window){
      write-ezlogs "Add/Open media request while MiniPlayer is open, temporarily unhiding main window to show dialog" -warning
      $synchash.window.Opacity = 1
      $synchash.window.ShowActivated = $true
      [Void]$synchash.Window.Show()
      [Void]$synchash.Window.Activate()
    }
    $CustomDialog_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new() 
    $CustomDialog_Settings.ColorScheme = [MahApps.Metro.Controls.Dialogs.MetroDialogColorScheme]::Theme
    $CustomDialog_Settings.OwnerCanCloseWithDialog = $true
    $synchash.CustomDialog = [MahApps.Metro.Controls.Dialogs.CustomDialog]::new($synchash.Window)
    [xml]$xaml = [System.IO.File]::ReadAllText("$($thisApp.Config.Current_folder)\Views\Dialog.xaml").replace('Views/Styles.xaml',"$($thisApp.Config.Current_folder)`\Views`\Styles.xaml")
    $reader = ([System.Xml.XmlNodeReader]::new($xaml)) 
    $synchash.DialogWindow = [Windows.Markup.XamlReader]::Load($reader)
    $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | & { process {$synchash."$($_.Name)" = $synchash.DialogWindow.FindName($_.Name)}}    
    [Void]$reader.Dispose()
    $xaml = $Null
    $reader = $Null
    $synchash.CustomDialog.AddChild($synchash.DialogWindow)
    $synchash.DialogButtonClose.add_click({
        try{
          if($synchash.YoutubeWebview2_Visibility -and $synchash.YoutubeWebView2){
            $synchash.YoutubeWebView2.Visibility = 'Visible'    
          }    
          if($synchash.VideoView_Visibility -and $synchash.VideoView){
            $synchash.VideoView.Visibility = 'Visible'    
          }  
          if($synchash.chat_WebView2_Visibility -and $synchash.chat_WebView2){
            $synchash.chat_WebView2.Visibility = 'Visible'    
          }
          if($synchash.Comments_Grid_Visibility -and $synchash.Comments_Grid){
            $synchash.Comments_Grid.Visibility = 'Visible'    
          }     
          if($synchash.WebView2_Visibility -and $synchash.WebView2){
            $synchash.WebView2.Visibility = 'Visible'    
          }                          
          $synchash.CustomDialog.RequestCloseAsync()
          $synchash.CustomDialog = $null
          $synchash.DialogWindow = $Null
          if($synchash.MiniPlayer_Viewer.isVisible -and $synchash.Window){
            [Void]$synchash.Window.hide()
          }
        }catch{
          write-ezlogs "An exception occurred in Dialog_Remote_URL_Textbox.add_TextChanged" -catcherror $_
        }
    })
    $synchash.Dialog_Remote_URL_Textbox.add_TextChanged({
        try{
          if(-not [string]::IsNullOrEmpty($synchash.Dialog_Remote_URL_Textbox.text)){
            $synchash.Dialog_Local_File_Textbox.IsEnabled = $false
          }else{
            $synchash.Dialog_Local_File_Textbox.IsEnabled = $true
          }
        }catch{
          write-ezlogs "An exception occurred in Dialog_Remote_URL_Textbox.add_TextChanged" -catcherror $_
        }
    })
    $synchash.Dialog_Local_File_Textbox.add_TextChanged({
        try{
          if(-not [string]::IsNullOrEmpty($synchash.Dialog_Local_File_Textbox.text)){
            $synchash.Dialog_Remote_URL_Textbox.IsEnabled = $false
          }else{
            $synchash.Dialog_Remote_URL_Textbox.IsEnabled = $true
          }
        }catch{
          write-ezlogs "An exception occurred in Dialog_Local_File_Textbox.add_TextChanged" -catcherror $_
        }
    })
    if($synchash.Dialog_StartPlayback_Toggle){
      $synchash.Dialog_StartPlayback_Toggle.add_Toggled({
          try{
            if($synchash.Dialog_StartPlayback_Toggle.isOn){
              $synchash.Dialog_Add_Button.Content = 'Open Media'
            }else{
              $synchash.Dialog_Add_Button.Content = 'Add Media'
            }
          }catch{
            write-ezlogs "An exception occurred in Dialog_Local_File_Textbox.add_TextChanged" -catcherror $_
          }
      })
    }
    $synchash.YoutubeWebview2_Visibility = $synchash.YoutubeWebView2.isVisible -and !$synchash.MediaViewAnchorable.isFloating
    $synchash.VideoView_Visibility = $synchash.VideoView.isVisible -and !$synchash.MediaViewAnchorable.isFloating
    $synchash.chat_WebView2_Visibility = ($synchash.chat_WebView2.isVisible) -and !$synchash.MediaViewAnchorable.isFloating
    $synchash.Comments_Grid_Visibility = ($synchash.Comments_Grid.isVisible) -and !$synchash.MediaViewAnchorable.isFloating
    $synchash.WebView2_Visibility = $synchash.WebView2.isVisible -and !$synchash.MediaViewAnchorable.isFloating

    if($synchash.YoutubeWebview2_Visibility -and $synchash.YoutubeWebView2){
      $synchash.YoutubeWebView2.Visibility = 'Collapsed'    
    }
    if($synchash.VideoView_Visibility -and $synchash.VideoView){
      $synchash.VideoView.Visibility = 'Collapsed'   
    }
    if($synchash.chat_WebView2_Visibility -and $synchash.chat_WebView2){
      $synchash.chat_WebView2.Visibility = 'Collapsed'    
    }
    if($synchash.Comments_Grid_Visibility -and $synchash.Comments_Grid){
      $synchash.Comments_Grid.Visibility = 'Collapsed'    
    }
    if($synchash.WebView2_Visibility -and $synchash.WebView2){
      $synchash.WebView2.Visibility = 'Collapsed'    
    }
    $synchash.Dialog_Browse_Button.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.BrowseMedia_Command)
    $synchash.Dialog_Browse_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.BrowseMedia_Command)
    $synchash.Dialog_BrowseFolders_Button.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.BrowseMedia_Command)
    $synchash.Dialog_BrowseFolders_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.BrowseMedia_Command)
    $synchash.Dialog_Add_Button.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Add_Media_Apply_Command) 
    $synchash.Dialog_Add_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Add_Media_Apply_Command)   
    [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMetroDialogAsync($synchash.Window, $synchash.CustomDialog, $CustomDialog_Settings)
  }catch{
    write-ezlogs 'An exception occurred in Add_Media_Command click event' -showtime -catcherror $_
  }
}

#LocalMedia Actions Button
if($synchash.LocalMedia_Actions_Button){
  $synchash.LocalMedia_Actions_Button.add_Loaded({
      try{
        $synchash.LocalMedia_Actions_Button.items.clear()
        $Header = 'Add Media'
        if($synchash.LocalMedia_Actions_Button.items -notcontains $Header){
          $synchash.Add_localMedia_Button = [System.Windows.Controls.MenuItem]::new()
          $synchash.Add_localMedia_Button.IsCheckable = $false    
          $synchash.Add_localMedia_Button.ToolTip = 'Add new media paths to library'
          $synchash.Add_localMedia_Button.Header = $Header
          $menuItem_imagecontrol = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
          $menuItem_imagecontrol.width = "14"
          $menuItem_imagecontrol.Height = "14"
          $menuItem_imagecontrol.Kind = 'PlusCircleOutline'
          $synchash.Add_localMedia_Button.Icon = $menuItem_imagecontrol
          $synchash.Add_localMedia_Button.AddHandler([System.Windows.Controls.MenuItem]::ClickEvent,$synchash.Add_Media_Command)                                                
          [Void]$synchash.LocalMedia_Actions_Button.items.add($synchash.Add_localMedia_Button)
        } 
        $Header = 'Quick Refresh'
        if($synchash.LocalMedia_Actions_Button.items -notcontains $Header){
          $synchash.QuickRefresh_LocalMedia_Button = [System.Windows.Controls.MenuItem]::new()
          $synchash.QuickRefresh_LocalMedia_Button.IsCheckable = $false    
          $synchash.QuickRefresh_LocalMedia_Button.Header = $Header 
          $synchash.QuickRefresh_LocalMedia_Button.ToolTip = 'Refreshes the library view with existing records'
          $synchash.QuickRefresh_LocalMedia_Button.Name = 'QuickRefresh_LocalMedia_Button'
          $menuItem_imagecontrol = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
          $menuItem_imagecontrol.width = "14"
          $menuItem_imagecontrol.Height = "14"
          $menuItem_imagecontrol.Kind = 'Refresh'        
          $synchash.QuickRefresh_LocalMedia_Button.Icon = $menuItem_imagecontrol
          $synchash.QuickRefresh_LocalMedia_Button.Add_Click({   
              try{  
                $synchash.Refresh_LocalMedia_timer.tag = 'QuickRefresh_LocalMedia_Button'  
                $synchash.Refresh_LocalMedia_timer.start()            
              }catch{
                write-ezlogs 'An exception occurred in LocalMedia_Actions_Button_menuitem.Add_Click' -showtime -catcherror $_
              }
          })                                               
          [Void]$synchash.LocalMedia_Actions_Button.items.add($synchash.QuickRefresh_LocalMedia_Button)
        }
        $Header = 'Rescan Library'
        if($synchash.LocalMedia_Actions_Button.items -notcontains $Header){
          $synchash.Refresh_LocalMedia_Button = [System.Windows.Controls.MenuItem]::new()
          $synchash.Refresh_LocalMedia_Button.IsCheckable = $false    
          $synchash.Refresh_LocalMedia_Button.Header = $Header
          $synchash.Refresh_LocalMedia_Button.ToolTip = 'Performs full rescan of media and rebuild of library'
          $synchash.Refresh_LocalMedia_Button.Name = 'Refresh_LocalMedia_Button'
          $menuItem_imagecontrol = [MahApps.Metro.IconPacks.PackIconMaterial]::new()
          $menuItem_imagecontrol.width = "14"
          $menuItem_imagecontrol.Height = "14"
          $menuItem_imagecontrol.Kind = 'DatabaseRefreshOutline'        
          $synchash.Refresh_LocalMedia_Button.Icon = $menuItem_imagecontrol
          $synchash.Refresh_LocalMedia_Button.Add_Click({   
              try{  
                $synchash.Refresh_LocalMedia_timer.tag = 'Refresh_LocalMedia_Button'  
                $synchash.Refresh_LocalMedia_timer.start()             
              }catch{
                write-ezlogs 'An exception occurred in LocalMedia_Actions_Button_menuitem.Add_Click' -showtime -catcherror $_
              }
          })                                               
          [Void]$synchash.LocalMedia_Actions_Button.items.add($synchash.Refresh_LocalMedia_Button)
        }                     
      }catch{
        write-ezlogs "An exception occurred in LocalMedia_Actions_Button.add_Loaded" -catcherror $_
      }
  })
}

if($synchash.OpenButton_Button){
  try{
    $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.Current_Folder)\Resources\Skins\OpenButton.png") 
    $image = [System.Windows.Media.Imaging.BitmapImage]::new()
    [void]$image.BeginInit()
    $image.CacheOption = "OnLoad"
    $image.DecodePixelWidth = "86"
    $image.StreamSource = $stream_image
    [void]$image.EndInit() 
    [void]$stream_image.Close()
    [void]$stream_image.Dispose()
    $stream_image = $Null
    [void]$image.Freeze()
    $synchash.OpenButton.Source = $image
    $image = $Null
    [Void]$synchash.OpenButton_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Add_Media_Command)
  }catch{
    write-ezlogs "An exception occurred applying images for OpenButton_Button" -catcherror $_
  }finally{
    if($OpenButton_Measure){
      $OpenButton_Measure.stop()
      write-ezlogs "Buttons And Event Handlers - Add OpenButton Image" -PerfTimer $OpenButton_Measure
      $OpenButton_Measure = $Null
    }
  }
}
#---------------------------------------------- 
#endregion Add/Open Media Button
#----------------------------------------------

#---------------------------------------------- 
#region Progress Slider Controls
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $Slider_Controls_Measure = [system.diagnostics.stopwatch]::StartNew()
}
[System.Windows.RoutedEventHandler]$synchash.MediaPlayer_SliderValueChanged_Command = {
  param($sender,[System.Windows.RoutedPropertyChangedEventArgs[Double]]$e)
  try{  
    $CurrentValue = $sender.Value
    $LeftMouseButtonState = ([KeyStates.MyHelper]::GetAsyncKeyState(1) -eq -32767)
    $MediaPlayer_SliderMouseOver = ($synchash.MediaPlayer_Slider.IsMouseOver -and $LeftMouseButtonState)
    $Mini_Progress_SliderMouseOver = ($synchash.Mini_Progress_Slider.IsMouseOver -and $LeftMouseButtonState)
    $VideoView_Progress_SliderMouseOver = ($synchash.VideoView_Progress_Slider.IsMouseOver -and $LeftMouseButtonState)
    if(($MediaPlayer_SliderMouseOver -or $Mini_Progress_SliderMouseOver -or $VideoView_Progress_SliderMouseOver) -and $synchash.vlc.IsPlaying -and $([timespan]::FromMilliseconds($synchash.VLC.Time)).TotalSeconds -ne $synchash.MediaPlayer_Slider.Value){
      if($thisApp.Config.Dev_mode){write-ezlogs "Updating vlc time: $($synchash.MediaPlayer_Slider.Value * 1000)" -Dev_mode}    
      if($thisApp.Config.Libvlc_Version -eq '4'){
        $synchash.VLC.setTime($synchash.MediaPlayer_Slider.Value * 1000)
      }else{
        $synchash.VLC.Time = $synchash.MediaPlayer_Slider.Value * 1000
      }
      $total_time = $synchash.MediaPlayer_CurrentDuration
      [int]$b = [int]$synchash.MediaPlayer_Slider.Value
      [int]$d = $b / 60
      #min 
      [int]$hrs = $($([timespan]::FromSeconds($b)).Hours)
      [int]$mins = $($([timespan]::FromSeconds($b)).Minutes)
      [int]$secs = $($([timespan]::FromSeconds($b)).Seconds)
      if($hrs -ge 1){
        $current_Length = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
      }else{
        $hrs = '0'
        $current_Length = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
      }
      if($synchash.VideoView_Current_Length_TextBox){
        $synchash.VideoView_Current_Length_TextBox.text = $current_Length
      }
      if($synchash.VideoView_Total_Length_TextBox -and $synchash.VideoView_Total_Length_TextBox.text -ne $total_time){
        $synchash.VideoView_Total_Length_TextBox.text = $total_time
      }
      if($synchash.Media_Current_Length_TextBox){
        $synchash.Media_Current_Length_TextBox.DataContext = $current_Length
      }
      if($synchash.Media_Total_Length_TextBox -and $synchash.Media_Total_Length_TextBox.text -ne $total_time){
        $synchash.Media_Total_Length_TextBox.text = $total_time
      }
      if($synchash.MiniPlayer_Media_Length_Label){
        $synchash.MiniPlayer_Media_Length_Label.Content = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
      }               
    }elseif($synchash.MediaPlayer_Slider.IsMouseOver -and !$synchash.vlc.IsPlaying -and $synchash.MediaPlayer_Slider.IsFocused){
      #do nothing?
    }
    if([int]$synchash.MediaPlayer_Slider.Maximum -ne 0){
      $synchash.Main_TaskbarItemInfo.ProgressValue = [int]$synchash.MediaPlayer_Slider.Value / [int]$synchash.MediaPlayer_Slider.Maximum
    }            
  }catch{
    write-ezlogs 'An exception occurred in MediaPlayer_SliderValueChanged_Command' -showtime -catcherror $_
  }
}

[System.Windows.RoutedEventHandler]$synchash.MediaPlayer_SliderMouseUp_Command = {
  param($sender,[System.Windows.Input.MouseButtonEventArgs]$e)
  try{   
    if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Released){    
      $newvalue = $e.Source.value
      $e.Handled = $true
      $MediaPlayer_SliderMouseOver = ($synchash.MediaPlayer_Slider.IsMouseOver)
      $Mini_Progress_SliderMouseOver = ($synchash.Mini_Progress_Slider.IsMouseOver)
      $VideoView_Progress_SliderMouseOver = ($synchash.VideoView_Progress_Slider.IsMouseOver)
      if(!$synchash.vlc.IsPlaying -or $([string]$synchash.vlc.media.Mrl).StartsWith("dshow://")){
        write-ezlogs ">>>> Slider mouse up event: $($newvalue)"
        if($thisapp.config.Use_Spicetify -and $synchash.Spicetify -and $synchash.Spotify_Status -ne 'Stopped'){
          $current_track = $synchash.Spicetify
          $progress = [timespan]::Parse($synchash.Spicetify.POSITION).TotalSeconds
        }elseif($synchash.Spotify_WebPlayer_State.current_track.id -and $synchash.Spotify_WebPlayer_State.playbackstate -ne 0){
          Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -stop
          $newvalue = $([timespan]::FromSeconds($($newvalue))).TotalMilliseconds
          #write-ezlogs "Seeking to $($newvalue)"
          $synchash.Spotify_Webview2_SeekScript = @"
  console.log('Seeking Spotify Track to $($newvalue)');
  SpotifyWeb.player.seek($($newvalue));
   console.log('New Position',SpotifyWeb.currState.position);
"@
          $synchash.WebView2.ExecuteScriptAsync(
            $synchash.Spotify_Webview2_SeekScript      
          ) 
          $synchash.MediaPlayer_CurrentDuration = $newvalue
          Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -start
        }elseif($synchash.Spotify_Status -ne 'Stopped' -and $synchash.current_playing_media.url -match 'spotify\:'){
          $current_track = (Get-CurrentTrack -ApplicationName $thisapp.config.App_Name)
          $progress = [timespan]::FromMilliseconds($current_track.progress_ms).TotalSeconds
        } 
        #TODO: Need to add Spicetify commands for this
        if(!$synchash.Spotify_WebPlayer_State.current_track.id -and $current_track.is_playing -and $progress -ne $e.Source.value){
          $synchash.MediaPlayer_Slider.Value = $e.Source.value
          if($synchash.Main_TaskbarItemInfo.ProgressState -ne 'Normal'){
            $synchash.Main_TaskbarItemInfo.ProgressState = 'Normal'
          }
          if($thisapp.config.Use_Spicetify -and ((NETSTAT.EXE -an) | Where-Object {$_ -match '127.0.0.1:8974' -or $_ -match '0.0.0.0:8974'})){
            Invoke-RestMethod -Uri "http://127.0.0.1:8974/SETPOSITION?$($e.Source.value)" -UseBasicParsing  
          }else{
            $devices = Get-AvailableDevices -ApplicationName $thisapp.config.App_Name
            $device = $devices | Where-Object {$_.is_active -eq $true}
            if(!$device){
              $device = $devices | Select-Object -last 1
            }
            Invoke-SeekPositionCurrentTrack -PositionMs ($newvalue * 1000) -DeviceId $device.id -ApplicationName $thisapp.config.App_Name
          }
        }elseif($synchash.WebPlayer_State -ne 0 -and $synchash.Youtube_WebPlayer_title){
          #TODO: Youtube webplayer seeking
          Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -stop
          $newvalue = $([timespan]::FromSeconds($($synchash.MediaPlayer_Slider.Value))).TotalSeconds
          write-ezlogs ">>>> Seeking Youtube webplayer to: $newvalue" -dev_mode
          if($thisApp.Config.Use_invidious -or $synchash.Youtube_WebPlayer_URL -match 'yewtu.be'){
            $synchash.YoutubeWebView2_SeekScript =  @"
try {
  //var state = player.paused();
if (state) {
  //console.log('Resuming');
  //player.play();
} else {
   //console.log('Pausing');
  // player.pause();
}
} catch (error) {
  console.error('An exception occurred toggling player', error);
  var ErrorObject =
  {
    Key: 'Error',
    Value: Error
  };
  window.chrome.webview.postMessage(ErrorObject);
}

"@             
          }else{
            
            $synchash.YoutubeWebView2_SeekScript =  @"
try {
  var player = document.getElementById('movie_player');
  //var state = player.getPlayerState();
  console.log('Seeking Youtube player to $newvalue');
  player.seekTo($newvalue);
} catch (error) {
  console.error('An exception occurred seeking player to $($newvalue)', error);
  var ErrorObject =
  {
    Key: 'Error',
    Value: Error
  };
  window.chrome.webview.postMessage(ErrorObject);
}

"@         
            $synchash.YoutubeWebView2.ExecuteScriptAsync(
              $synchash.YoutubeWebView2_SeekScript      
            )
          }
          $synchash.MediaPlayer_CurrentDuration = $newvalue
          Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -start
          $synchash.MediaPlayer_Slider.Value = $e.Source.value
          if($synchash.Main_TaskbarItemInfo.ProgressState -ne 'Normal'){
            $synchash.Main_TaskbarItemInfo.ProgressState = 'Normal'
          }
        }
      }elseif($synchash.vlc.IsPlaying -and $([timespan]::FromMilliseconds($synchash.VLC.Time)).TotalSeconds -ne $newvalue){
        if($thisApp.Config.Verbose_logging){write-ezlogs "Updating vlc time: $($synchash.MediaPlayer_Slider.Value * 1000)" -showtime}   
        if($thisApp.Config.Libvlc_Version -eq '4'){
          $synchash.VLC.setTime($newvalue * 1000)
        }else{
          $synchash.VLC.Time = ($newvalue * 1000)
          $synchash.VLC.SeekTo([timespan]::FromSeconds($newvalue))
        }         
        $total_time = $synchash.MediaPlayer_CurrentDuration
        [int]$b = [int]$newvalue
        [int]$d = $b / 60
        #min 
        [int]$hrs = $($([timespan]::FromSeconds($b)).Hours)
        [int]$mins = $($([timespan]::FromSeconds($b)).Minutes)
        [int]$secs = $($([timespan]::FromSeconds($b)).Seconds)
        if($hrs -ge 1){
          $current_length = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
        }else{
          $hrs = '0'
          $current_length = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
        }
        if($synchash.VideoView_Current_Length_TextBox){
          $synchash.VideoView_Current_Length_TextBox.text = $current_Length
        }
        if($synchash.VideoView_Total_Length_TextBox -and $synchash.VideoView_Total_Length_TextBox.text -ne $total_time){
          $synchash.VideoView_Total_Length_TextBox.text = $total_time
        }
        if($synchash.Media_Current_Length_TextBox){
          $synchash.Media_Current_Length_TextBox.DataContext = $current_Length
        }
        if($synchash.Media_Total_Length_TextBox -and $synchash.Media_Total_Length_TextBox.text -ne $total_time){
          $synchash.Media_Total_Length_TextBox.text = $total_time
        }
        if($synchash.MiniPlayer_Media_Length_Label){
          $synchash.MiniPlayer_Media_Length_Label.Content =  "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
        }              
      }
    }            
  }catch{
    write-ezlogs 'An exception occurred in MediaPlayer_SliderMouseUp_Command' -showtime -catcherror $_
  }
}

if($synchash.MediaPlayer_Slider){
  $synchash.MediaPlayer_Slider.Maximum = 100
  [Void]$synchash.MediaPlayer_Slider.AddHandler([System.Windows.Controls.Slider]::ValueChangedEvent,$synchash.MediaPlayer_SliderValueChanged_Command)
  [Void]$synchash.MediaPlayer_Slider.AddHandler([System.Windows.Controls.Slider]::PreviewMouseUpEvent,$synchash.MediaPlayer_SliderMouseUp_Command)
}
if($synchash.VideoView_Progress_Slider){
  [Void]$synchash.VideoView_Progress_Slider.AddHandler([System.Windows.Controls.Slider]::PreviewMouseUpEvent,$synchash.MediaPlayer_SliderMouseUp_Command)
}
if($synchash.Mini_Progress_Slider){
  [Void]$synchash.Mini_Progress_Slider.AddHandler([System.Windows.Controls.Slider]::PreviewMouseUpEvent,$synchash.MediaPlayer_SliderMouseUp_Command)
}
#---------------------------------------------- 
#endregion Progress Slider Controls
#----------------------------------------------

#---------------------------------------------- 
#region Volume Controls
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.MediaPlayer_Volume_SliderMouseUp_Command = {
  param([Parameter(Mandatory)]$sender,[Parameter(Mandatory)][System.Windows.Input.MouseButtonEventArgs]$e)
  try{     
    #When playing with Spotify Client, only update on mouse up
    if ((Get-Process Spotify*) -and $e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Released -and $thisApp.Config.Import_Spotify_Media -and -not [string]::IsNullOrEmpty($synchash.Spotify_Status) -and $synchash.Spotify_Status -ne 'Stopped'){      
      if($thisapp.config.Use_Spicetify -and ((NETSTAT.EXE -an) | Where-Object {$_ -match '127.0.0.1:8974' -or $_ -match '0.0.0.0:8974'})){
        Invoke-RestMethod -Uri "http://127.0.0.1:8974/SETVOLUME?$($synchash.Volume_Slider.Value)" -UseBasicParsing  
      }else{
        Set-PlaybackVolume -VolumePercent $($synchash.Volume_Slider.Value) -ApplicationName $thisapp.config.App_Name
      }   
    }            
  }catch{
    write-ezlogs 'An exception occurred in MediaPlayer_SliderMouseUp_Command' -showtime -catcherror $_
  }
}

[System.Windows.RoutedEventHandler]$synchash.Volume_Changed_Command = {
  param([Parameter(Mandatory)][Object]$sender,[Parameter(Mandatory)][System.Windows.RoutedPropertyChangedEventArgs[double]]$e)
  try{
    $NewValue = $e.newvalue
    #Set config to current volume value
    $thisapp.Config.Media_Volume = $NewValue
    if($synchash.Vlc.isPlaying -or $synchash.Vlc.state -match 'Paused'){ 
      if($synchash.vlc.Volume -ne $NewValue){
        if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Setting vlc volume: $($NewValue)" -Dev_mode}
        if($thisApp.Config.Libvlc_Version -eq '4'){
          $synchash.vlc.SetVolume($NewValue)
        }else{
          $synchash.vlc.Volume = $NewValue
        }
      }
    }
    if(($synchash.YoutubeWebView2.CoreWebView2.IsDocumentPlayingAudio -or $synchash.Webview2.CoreWebView2.IsDocumentPlayingAudio) -or ($synchash.WebPlayer_State -ne 0 -and $synchash.Youtube_WebPlayer_title) -or ($synchash.Spotify_WebPlayer_State.current_track -and $synchash.Spotify_WebPlayer_State.playbackstate -ne 0)){
      if($synchash.Spotify_WebPlayer_State -and $synchash.Spotify_WebPlayer_State.playbackstate -ne 0 -and $synchash.Spotify_WebPlayer_State.current_track.id){
        $synchash.Webview2_VolumeScript =  @"
   console.log('Setting Spotify Volume to $($NewValue / 100)');
  SpotifyWeb.player.setVolume($($NewValue / 100))
"@             
        $synchash.WebView2.ExecuteScriptAsync(
          $synchash.Webview2_VolumeScript      
        )
      }else{
        if($thisApp.Config.Use_invidious -or $synchash.Youtube_WebPlayer_URL -match 'yewtu.be'){
          $synchash.YoutubeWebView2_VolumeScript =  @"       
        var volume = player.volume();
        console.log('Invidious volume',volume)
        if(volume !== $($NewValue / 100)){
          console.log('Setting Invidious volume',$($NewValue / 100))
          player.volume($($NewValue / 100));
        }       
"@             
          $synchash.YoutubeWebView2.ExecuteScriptAsync(
            $synchash.YoutubeWebView2_VolumeScript      
          )
        }elseif($synchash.Youtube_WebPlayer_URL -match 'youtube\.com' -or $synchash.Youtube_WebPlayer_URL -match 'youtu\.be' -or $synchash.WebBrowser_Youtube_URL -match 'youtube\.com' -or $synchash.WebBrowser_Youtube_URL -match 'youtu\.be'){
          $synchash.YoutubeWebView2_VolumeScript =  @"
  var player = document.getElementById('movie_player');
  console.log('Setting volume',$($NewValue))
  player.setVolume($($NewValue));
"@             

          if(($synchash.WebBrowser_Youtube_URL -match 'youtube\.com' -or $synchash.WebBrowser_Youtube_URL -match 'youtu\.be') -and $synchash.WebBrowser){
            $synchash.WebBrowser.ExecuteScriptAsync(
              $synchash.YoutubeWebView2_VolumeScript      
            )
          }
          if($synchash.YoutubeWebView2){
            $synchash.YoutubeWebView2.ExecuteScriptAsync(
              $synchash.YoutubeWebView2_VolumeScript      
            )
          }
        }
      }
    }elseif($($synchash.WebBrowser.CoreWebView2.IsDocumentPlayingAudio -or $synchash.WebBrowser.CoreWebView2.IsMuted -or -not [string]::IsNullOrEmpty($synchash.Youtube_webplayer_current_Media)) -and ($synchash.WebBrowser_Youtube_URL -match 'youtube\.com' -or $synchash.WebBrowser_Youtube_URL -match 'youtu\.be')){
      $synchash.YoutubeWebView2_VolumeScript =  @"
  var player = document.getElementById('movie_player');
  console.log('Setting volume',$($NewValue))
  player.setVolume($($NewValue));
"@ 
      $synchash.WebBrowser.ExecuteScriptAsync(
        $synchash.YoutubeWebView2_VolumeScript      
      )
    }
    if($sender.value -ge 75){
      $synchash.VideoView_Mute_Icon.kind = 'VolumeHigh'
    }elseif($sender.value -gt 25 -and $NewValue -lt 75){
      $synchash.VideoView_Mute_Icon.kind = 'VolumeMedium'
    }elseif($sender.value -le 25 -and $NewValue -gt 0){
      $synchash.VideoView_Mute_Icon.kind = 'VolumeLow'
    }elseif($sender.value -le 0){
      $synchash.VideoView_Mute_Icon.kind = 'Volumeoff'
    }        
  }catch{
    write-ezlogs "An exception occurred in Volume_Slider.Add_ValueChanged" -catcherror $_
  }
}

if($synchash.Volume_Slider){
  [Void]$synchash.Volume_Slider.AddHandler([System.Windows.Controls.Slider]::ValueChangedEvent,$synchash.Volume_Changed_Command)
  [Void]$synchash.Volume_Slider.AddHandler([System.Windows.Controls.Slider]::PreviewMouseUpEvent,$synchash.MediaPlayer_Volume_SliderMouseUp_Command)
}
if($synchash.VideoView_Volume_Slider){
  [Void]$synchash.VideoView_Volume_Slider.AddHandler([System.Windows.Controls.Slider]::PreviewMouseUpEvent,$synchash.MediaPlayer_Volume_SliderMouseUp_Command)
}

[System.Windows.RoutedEventHandler]$Synchash.Mute_Command = {
  param([Parameter(Mandatory)]$sender)
  try{
    Set-Mute -thisApp $thisApp -synchash $synchash
  }catch{
    write-ezlogs "An exception occurred in Mute_Command" -showtime -catcherror $_
  }
}

if($thisApp.Config.startup_perf_timer){
  $Slider_Controls_Measure.stop()
  write-ezlogs "Buttons And Event Handlers - Slider Controls Startup" -PerfTimer $Slider_Controls_Measure
  $Slider_Controls_Measure = $Null
}

#---------------------------------------------- 
#endregion Volume Controls
#----------------------------------------------

############################################### 
#region VLC Routed Event Handlers
###############################################

#---------------------------------------------- 
#region Restart Media
#----------------------------------------------
[System.Windows.RoutedEventHandler]$synchash.RestartMedia_Command = {
  param([Parameter(Mandatory)]$sender)
  try{
    write-ezlogs ">>>> Received Restart Command" -showtime
    $mediatorestart = $synchash.current_playing_Media
    if($mediatorestart.id){
      if($mediatorestart.source -eq 'Spotify' -or $mediatorestart.url -match 'spotify\:'){
        Start-SpotifyMedia -Media $mediatorestart -thisApp $thisapp -synchash $synchash -use_WebPlayer:$thisapp.config.Spotify_WebPlayer -Show_notifications:$thisApp.config.Show_notifications -RestrictedRunspace:$thisapp.config.Spotify_WebPlayer
      }else{
        Start-Media -Media $mediatorestart -thisApp $thisapp -synchashWeak ([System.WeakReference]::new($synchash)) -Show_notification -restart
      }
    }else{
      write-ezlogs "Didnt find any current playing media to restart" -AlertUI -warning
    }
  }catch{
    write-ezlogs 'An exception occurred in Restart_Media click event' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Restart Media
#----------------------------------------------

#---------------------------------------------- 
#region Prev Media
#----------------------------------------------
$synchash.PrevMedia_Command = {
  param([Parameter(Mandatory)]$sender)
  try{
    write-ezlogs ">>>> Received Prev Command" -showtime
    $PrevMedia_Measure = [system.diagnostics.stopwatch]::StartNew()
    if($synchash.vlc.IsPlaying -or $synchash.Vlc.state -match 'Paused'){
      write-ezlogs ">>>> Stopping VLC Playback" -showtime 
      if($synchash.vlc.media){
        write-ezlogs " | Disposing vlc.media" -showtime
        $synchash.vlc.media = $Null
        #$synchash.libvlc_media = $Null
        #$synchash.Remove('libvlc_media')
      }
      [Void]$synchash.VLC.stop()
      $synchash.VLC_IsPlaying_State = $synchash.Vlc.isPlaying
    }
    if($thisApp.config.History_Playlist.values){ 
      $HistoryList = [SerializableDictionary[int,string]]::new($thisApp.config.History_Playlist)
      if($synchash.timer.isEnabled){
        $synchash.timer.stop()
      }
      $index_toget = ($HistoryList.keys | Measure-Object -Maximum).Maximum
      write-ezlogs ">>>> Looking for last played media from history playlist with index $($index_toget)" -showtime
      $Last_played = (($HistoryList.GetEnumerator()) | Where-Object {$_.key -eq $index_toget})
      if($Last_played.key -and !$Last_played.value){
        write-ezlogs "Found history playlist item with index $($Last_played.name) but does not have a valid value - removing from history" -warning
        [Void]$thisApp.config.History_Playlist.Remove($Last_played.name)
      } 
      if(!$Last_played.value){
        $index_toget = $HistoryList.keys | sort | select -last 1
        write-ezlogs ">>>> Looking again for last played media from history playlist with new index $($index_toget)" -showtime
        $Last_played = (($HistoryList.GetEnumerator()) | Where-Object {$_.name -eq $index_toget}) 
      }
      if(!$Last_played){
        write-ezlogs "Unable to find any valid items in playlist history" -showtime -warning -AlertUI -AlertAudio:$false
        Stop-Media -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisApp -UpdateQueue -StopMonitor
        return
      }else{
        $last_Played_ID = $Last_played.value
      }
      write-ezlogs ">>>> Looking for last played media from history playlist with id $($last_Played_ID)" -showtime
      #$All_Playlists_Cache_File_Path = [System.IO.Path]::Combine($thisApp.config.Playlist_Profile_Directory,"All-Playlists-Cache.xml")

      #Get Media Profile
      $last_media = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_ID $last_Played_ID
      #Look for in playlist cache
      if(!$last_media){
        write-ezlogs "Unable to find media $($last_Played_ID) in libraries, checking playlist profiles" -showtime -warning -LogLevel 2
        if([System.IO.File]::Exists($thisApp.Config.Playlists_Profile_Path)){
          if($thisApp.Config.Verbose_logging){write-ezlogs " | Importing All Playlist Cache: $($thisApp.Config.Playlists_Profile_Path)" -showtime}
          $Available_Playlists = Import-SerializedXML -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist
        }
        if($Available_Playlists.PlayList_tracks.values | Where-Object {$_.id -eq  $last_Played_ID}){                     
          $last_media = $Available_Playlists.PlayList_tracks.values | Where-Object {$_.id -eq $last_Played_ID} | select -First 1
          write-ezlogs " | Found last media in Playlist cache ($($last_media.playlist)) - meaning its missing from primary media profiles!" -showtime -warning -LogLevel 2
          if($last_media.Source -match 'Youtube'){
            try{  
              write-ezlogs " | Adding last media to Youtube media profiles" -showtime -LogLevel 2 -logtype Youtube
              $Link = $last_media.url 
              if(-not [string]::IsNullOrEmpty($Link) -and (Test-url $Link)){
                if($Link -match 'twitch.tv'){
                  $twitch_channel = $((Get-Culture).textinfo.totitlecase(($Link | split-path -leaf).tolower()))
                  write-ezlogs ">>>> Adding Twitch channel $twitch_channel - $Link" -showtime -color cyan -LogLevel 2 -logtype Twitch  
                  Import-Twitch -Twitch_URL $Link -verboselog:$thisApp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -use_runspace                  
                }elseif($Link -match 'youtube\.com' -or $Link -match 'youtu\.be'){
                  write-ezlogs ">>>> Adding Youtube link $Link" -showtime -color cyan -LogLevel 2 -logtype Youtube
                  Import-Youtube -Youtube_URL $Link -verboselog:$thisApp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -use_runspace 
                }                      
              }else{
                write-ezlogs "The provided URL is not valid or was not provided! -- $Link" -showtime -warning -LogLevel 2 -logtype Youtube
              }                        
            }catch{
              write-ezlogs "An exception occurred adding media $($last_media.title) with Import-Youtube" -showtime -catcherror $_
            }
          } 
        }elseif($last_media.Source -eq 'Twitch'){
          try{  
            write-ezlogs " | Adding last media to Twitch media profiles" -showtime -LogLevel 2 -logtype Twitch
            $Link = $last_media.url 
            if(-not [string]::IsNullOrEmpty($Link) -and (Test-url $Link)){
              if($last_media.Channel_Name){
                $twitch_channel = $last_media.Channel_Name
              }elseif($Link -match 'twitch.tv'){
                $twitch_channel = $((Get-Culture).textinfo.totitlecase(($Link | split-path -leaf).tolower()))
                write-ezlogs ">>>> Adding Twitch channel $twitch_channel - $Link" -showtime -color cyan -LogLevel 2 -logtype Twitch                     
              }
              Import-Twitch -Twitch_URL $Link -verboselog:$thisApp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -use_runspace       
            }else{
              write-ezlogs "The provided URL is not valid or was not provided! -- $Link" -showtime -warning -LogLevel 2 -logtype Twitch
            }                        
          }catch{
            write-ezlogs "An exception occurred adding media $($last_media) with Import-Twitch" -showtime -catcherror $_
          }
        }            
      } 
      if(!$last_media){
        write-ezlogs " | Unable to get media information about the last media item $($last_Played_ID)! - Removing from history" -showtime -warning -LogLevel 2    
        [Void]$thisApp.config.History_Playlist.Remove($Last_played.name)       
        return
      }elseif(@($last_media).count -eq 1){
        if(-not [string]::IsNullOrEmpty($last_media.title)){
          $title = $last_media.title
        }elseif(-not [string]::IsNullOrEmpty($last_media.SongInfo.title)){
          $title = $last_media.SongInfo.title
        }
        write-ezlogs " | Last media to play is $($title) - ID $($last_media.id)" -showtime -LogLevel 2
        $synchash.Current_playing_media = $last_media
        if($thisApp.config.History_Playlist.values -contains $last_media.id){
          try{
            $index_toremove = $thisApp.config.History_Playlist.GetEnumerator() | Where-Object {$_.value -eq $last_media.id} | select * -ExpandProperty key 
            if(($index_toremove).count -gt 1){
              write-ezlogs " | Found multiple items in History Playlist matching id $($last_media.id) - $($index_toremove | out-string)" -showtime -warning -LogLevel 2
              foreach($index in $index_toremove){
                [Void]$thisApp.config.History_Playlist.Remove($index) 
              }  
            }else{
              write-ezlogs " | Removing $($last_media.id) from Play Queue" -showtime -LogLevel 2
              [Void]$thisApp.config.History_Playlist.Remove($index_toremove)
            }                              
          }catch{
            write-ezlogs "An exception occurred updating History playlist" -showtime -catcherror $_
          }                          
        }
        if($last_media.source -eq 'Spotify' -or $last_media.url -match 'spotify\:'){
          Start-SpotifyMedia -Media $last_media -thisApp $thisApp -synchash $synchash -use_WebPlayer:$thisapp.config.Spotify_WebPlayer -Show_notifications:$thisApp.config.Show_notifications -RestrictedRunspace:$thisapp.config.Spotify_WebPlayer                                      
        }elseif($last_media.id){
          if(Get-Process -Name 'Spotify*' -ErrorAction SilentlyContinue){
            write-ezlogs "Spotify is running, closing it" -showtime -warning -LogLevel 2 -logtype Spotify
            Get-Process -Name 'Spotify*' | Stop-Process -Force -ErrorAction SilentlyContinue
          }                   
          Start-Media -Media $last_media -thisApp $thisapp -synchashWeak ([System.WeakReference]::new($synchash)) -Show_notification
        }
      }else{
        write-ezlogs "Found multiple ($(@($last_media).count)) media when attempting to lookup previous played for id $($synchash.last_played)" -AlertUI -warning
      }
    }else{
      write-ezlogs "Didnt find any previous media to play" -AlertUI -warning
    }
    if($PrevMedia_Measure){
      write-ezlogs "PrevMedia_Measure" -Perf -PerfTimer $PrevMedia_Measure
    }
  }catch{
    write-ezlogs 'An exception occurred in PrevMedia_command event' -showtime -catcherror $_
  }finally{
    if($this -is [System.Windows.Threading.DispatcherTimer]){
      [Void]$this.stop()
    }
    if($HistoryList){
      $HistoryList = $Null
    }
    $Available_Playlists = $Null
  }
}
#---------------------------------------------- 
#endregion Prev Media
#----------------------------------------------

#---------------------------------------------- 
#region Stop-Media
#----------------------------------------------
$Synchash.StopMedia_Command = {
  param($sender)
  try{  
    if($synchash.Stop_media_timer -and !$synchash.Stop_media_timer.isEnabled){
      $synchash.Stop_media_timer.start()
    }
  }catch{
    write-ezlogs 'An exception occurred in StopMedia_Command event' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Stop-Media
#----------------------------------------------

#---------------------------------------------- 
#region Pause-Media
#----------------------------------------------
$Synchash.PauseMedia_Command = {
  param($sender)
  try{  
    Pause-Media -synchash $synchash -thisApp $thisApp -Update_MediaTransportControls
  }catch{
    write-ezlogs 'An exception occurred in Pause_media click event' -showtime -catcherror $_
  }
}
$synchash.PauseMedia_Timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.PauseMedia_Timer.add_tick({    
    try{
      Pause-Media -synchash $synchash -thisApp $thisApp
    }catch{
      write-ezlogs "An exception occurred executing PauseMedia_Timer" -showtime -catcherror $_
    }finally{
      $this.stop()
    }       
})
#---------------------------------------------- 
#endregion Pause-Media
#----------------------------------------------

#---------------------------------------------- 
#region Next-Media
#----------------------------------------------
$synchash.SkipMedia_Timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.SkipMedia_Timer.add_tick({    
    try{
      Skip-Media -synchash $synchash -thisApp $thisApp
    }catch{
      write-ezlogs "An exception occurred executing SkipMedia_Timer" -showtime -catcherror $_
    }finally{
      $this.stop()  
    }
})

$synchash.PrevMedia_Timer = [System.Windows.Threading.DispatcherTimer]::new()
$synchash.PrevMedia_Timer.add_tick($synchash.PrevMedia_Command)

$Synchash.NextMedia_Command = {
  param($sender)
  try{  
    $synchash.SkipMedia_Timer.start()        
  }catch{
    write-ezlogs 'An exception occurred in Skip_media click event' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Next-Media
#----------------------------------------------
############################################### 
#endregion VLC Routed Event Handlers
###############################################
                  
#---------------------------------------------- 
#region Media Control Handlers
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $MediaControl_Handlers_Measure = [system.diagnostics.stopwatch]::StartNew()
}

if($synchash.New_Playlist_Button){
  [Void]$synchash.New_Playlist_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Add_to_New_PlaylistCommand)
}
if($synchash.New_Playlist_VideoView_Button){
  [Void]$synchash.New_Playlist_VideoView_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Add_to_New_PlaylistCommand)
}
if($synchash.New_Playlist_Button_Library){
  [Void]$synchash.New_Playlist_Button_Library.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Add_to_New_PlaylistCommand)
}
if($synchash.Import_Playlist_Button_Library){
  [Void]$synchash.Import_Playlist_Button_Library.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Import_PlaylistCommand)
}
if($synchash.Import_Playlist_VideoView_Button){
  [Void]$synchash.Import_Playlist_VideoView_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Import_PlaylistCommand)
}
if($synchash.Import_Playlist_Button){
  [Void]$synchash.Import_Playlist_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Import_PlaylistCommand)
}
if($synchash.Export_Playlists_VideoView_Button){
  [Void]$synchash.Export_Playlists_VideoView_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Export_AllPlaylists_Command)
}
if($synchash.Export_Playlists_Button_Library){
  [Void]$synchash.Export_Playlists_Button_Library.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Export_AllPlaylists_Command)
}
if($synchash.Export_Playlists_Button){
  [Void]$synchash.Export_Playlists_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Export_AllPlaylists_Command)
}
if($synchash.Refresh_Playlist_VideoView_Button){
  [Void]$synchash.Refresh_Playlist_VideoView_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Refresh_PlaylistCommand)
}
if($synchash.Refresh_Playlist_Button){
  [Void]$synchash.Refresh_Playlist_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Refresh_PlaylistCommand)
}
if($synchash.Refresh_Playlist_Button_Library){
  [Void]$synchash.Refresh_Playlist_Button_Library.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.Refresh_PlaylistCommand)
}

#videoview controls
if($synchash.VideoView_Play_Button){
  [Void]$synchash.VideoView_Play_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,[System.Windows.RoutedEventHandler]$Synchash.PauseMedia_Command)
}
if($synchash.VideoView_Stop_Button){
  [Void]$synchash.VideoView_Stop_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,[System.Windows.RoutedEventHandler]$Synchash.StopMedia_Command)
}

if($synchash.VideoView_Restart_Button){
  [Void]$synchash.VideoView_Restart_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,[System.Windows.RoutedEventHandler]$Synchash.RestartMedia_Command)
}

if($synchash.VideoView_Next_Button){
  [Void]$synchash.VideoView_Next_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,[System.Windows.RoutedEventHandler]$Synchash.NextMedia_Command)
}
if($synchash.VideoView_Back_Button){
  [Void]$synchash.VideoView_Back_Button.AddHandler([System.Windows.Controls.Button]::ClickEvent,[System.Windows.RoutedEventHandler]$Synchash.PrevMedia_Command)
}
#Volume binding
if($synchash.VideoView_Mute_Button){
  [Void]$synchash.VideoView_Mute_Button.AddHandler([Windows.Controls.Button]::ClickEvent,$Synchash.Mute_Command)
}

if($synchash.Volume_Slider -and $synchash.VideoView_Volume_Slider){
  #Volume slider binding
  $VideoView_Volume_Slider_Binding = [System.Windows.Data.Binding]::new()
  $VideoView_Volume_Slider_Binding.Source = $synchash.Volume_Slider
  $VideoView_Volume_Slider_Binding.Path = "Value"
  $VideoView_Volume_Slider_Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.VideoView_Volume_Slider,[System.Windows.Controls.Slider]::ValueProperty, $VideoView_Volume_Slider_Binding)

  #Volume slider tooltip binding
  $VideoView_Volume_Slider_Binding = [System.Windows.Data.Binding]::new()
  $VideoView_Volume_Slider_Binding.Source = $synchash.Volume_Slider
  $VideoView_Volume_Slider_Binding.Path = "ToolTip"
  $VideoView_Volume_Slider_Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.VideoView_Volume_Slider,[System.Windows.Controls.Slider]::ToolTipProperty, $VideoView_Volume_Slider_Binding)  
} 

if($synchash.VideoView_Overlay_Grid){
  #VideoView_Overlay_Grid binding
  $VideoView_Overlay_Grid_Binding = [System.Windows.Data.Binding]::new()
  $VideoView_Overlay_Grid_Binding.Source = $synchash.VideoView
  $VideoView_Overlay_Grid_Binding.Path = "Visibility"
  $VideoView_Overlay_Grid_Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.VideoView_Overlay_Grid,[System.Windows.Controls.Grid]::VisibilityProperty, $VideoView_Overlay_Grid_Binding)  
}

#Progress Slider binding
if($synchash.VideoView_Progress_Slider){
  #VideoView_Progress_Slider Value binding
  $ProgressSlider_Binding = [System.Windows.Data.Binding]::new()
  $ProgressSlider_Binding.Source = $synchash.MediaPlayer_Slider
  $ProgressSlider_Binding.Path = "Value"
  $ProgressSlider_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.VideoView_Progress_Slider,[System.Windows.Controls.Slider]::ValueProperty, $ProgressSlider_Binding) 

  #VideoView_Progress_Slider Tooltip binding
  $ProgressSliderTooltip_Binding = [System.Windows.Data.Binding]::new()
  $ProgressSliderTooltip_Binding.Source = $synchash.MediaPlayer_Slider
  $ProgressSliderTooltip_Binding.Path = "ToolTip"
  $ProgressSliderTooltip_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.VideoView_Progress_Slider,[System.Windows.Controls.Slider]::ToolTipProperty, $ProgressSliderTooltip_Binding) 

  #MediaPlayer_Slider Ticks binding
  $ProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
  $ProgressSliderTick_Binding.Source = $synchash.MediaPlayer_Slider
  $ProgressSliderTick_Binding.Path = "Ticks"
  $ProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.VideoView_Progress_Slider,[System.Windows.Controls.Slider]::TicksProperty, $ProgressSliderTick_Binding) 

  #MediaPlayer_Slider Maximum binding
  $ProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
  $ProgressSliderTick_Binding.Source = $synchash.MediaPlayer_Slider
  $ProgressSliderTick_Binding.Path = "Maximum"
  $ProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.VideoView_Progress_Slider,[System.Windows.Controls.Slider]::MaximumProperty, $ProgressSliderTick_Binding)

  #VideoView_Grid ActualWidth binding
  $ProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
  $ProgressSliderTick_Binding.Source = $synchash.VideoView_Grid
  $ProgressSliderTick_Binding.Path = "ActualWidth"
  $ProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.VideoView_Progress_Slider,[System.Windows.Controls.Slider]::WidthProperty, $ProgressSliderTick_Binding)

  #MediaPlayer_Slider IsEnabled binding
  $ProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
  $ProgressSliderTick_Binding.Source = $synchash.MediaPlayer_Slider
  $ProgressSliderTick_Binding.Path = "IsEnabled"
  $ProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.VideoView_Progress_Slider,[System.Windows.Controls.Slider]::IsEnabledProperty, $ProgressSliderTick_Binding)
} 
if($synchash.Volume_Slider_Toolip){
  #Volume_Slider Value binding
  $ProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
  $ProgressSliderTick_Binding.Source = $synchash.Volume_Slider
  $ProgressSliderTick_Binding.Path = "Value"
  $ProgressSliderTick_Binding.Converter = $synchash.Window.TryFindResource('valueTextConverter') 
  $ProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.Volume_Slider_Toolip,[System.Windows.Controls.ToolTip]::ContentProperty, $ProgressSliderTick_Binding)
}
if($synchash.VideoView_Playlists_Button -and $synchash.TrayPlayerQueueFlyout){
  #VideoView_Playlists_Button IsChecked binding
  $ProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
  $ProgressSliderTick_Binding.Source = $synchash.VideoView_Playlists_Button
  $ProgressSliderTick_Binding.Path = "IsChecked"
  $ProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.TrayPlayerQueueFlyout,[MahApps.Metro.Controls.Flyout]::IsOpenProperty, $ProgressSliderTick_Binding)

  if($synchash.Overlay_Playlists_Button){
    $ProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
    $ProgressSliderTick_Binding.Source = $synchash.VideoView_Playlists_Button
    $ProgressSliderTick_Binding.Path = "IsChecked"
    $ProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::TwoWay
    [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.Overlay_Playlists_Button,[Windows.Controls.Primitives.ToggleButton]::IsCheckedProperty, $ProgressSliderTick_Binding)
  }

  $ProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
  $ProgressSliderTick_Binding.Source = $synchash.PlayQueue_TreeView
  $ProgressSliderTick_Binding.Path = "Items"
  $ProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.VideoView_Queue,[System.Windows.Controls.DataGrid]::ItemsSourceProperty, $ProgressSliderTick_Binding)

  $MinWidth_Binding = [System.Windows.Data.Binding]::new()
  $MinWidth_Binding.Source = $synchash.Playlist_Grid_TrayPlayer
  $MinWidth_Binding.Path = "ActualWidth"
  $MinWidth_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.PlayQueue_Grid_TrayPlayer,[System.Windows.Controls.Grid]::MinWidthProperty, $MinWidth_Binding)

}

if($synchash.PlayLists_VideoView_Progress_Ring){
  $ProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
  $ProgressSliderTick_Binding.Source = $synchash.PlayLists_Progress_Ring
  $ProgressSliderTick_Binding.Path = "IsActive"
  $ProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.PlayLists_VideoView_Progress_Ring,[MahApps.Metro.Controls.ProgressRing]::IsActiveProperty, $ProgressSliderTick_Binding)
}
if($synchash.PlayQueue_VideoView_Progress_Ring){
  $ProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
  $ProgressSliderTick_Binding.Source = $synchash.PlayQueue_Progress_Ring
  $ProgressSliderTick_Binding.Path = "IsActive"
  $ProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.PlayQueue_VideoView_Progress_Ring,[MahApps.Metro.Controls.ProgressRing]::IsActiveProperty, $ProgressSliderTick_Binding)
}

if($synchash.VideoView_Title_Label -and $synchash.VideoView_Artist_Label){
  #ProgressSlider Visibility binding
  $ProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
  $ProgressSliderTick_Binding.Source = $synchash.Now_Playing_Title_Label
  $ProgressSliderTick_Binding.Path = "DataContext"
  $ProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.VideoView_Title_Label,[System.Windows.Controls.TextBlock]::TextProperty, $ProgressSliderTick_Binding)

  $ProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
  $ProgressSliderTick_Binding.Source = $synchash.Now_Playing_Artist_Label
  $ProgressSliderTick_Binding.Path = "DataContext"
  $ProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.VideoView_Artist_Label,[System.Windows.Controls.TextBlock]::TextProperty, $ProgressSliderTick_Binding)

  $ProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
  $ProgressSliderTick_Binding.Source = $synchash.DisplayPanel_Sep2_Label
  $ProgressSliderTick_Binding.Path = "Visibility"
  $ProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.VideoView_Sep2_Label,[System.Windows.Controls.TextBox]::VisibilityProperty, $ProgressSliderTick_Binding)
  
  $ProgressSliderTick_Binding = [System.Windows.Data.Binding]::new()
  $ProgressSliderTick_Binding.Source = $synchash.VideoView_ViewCount_Label
  $ProgressSliderTick_Binding.Path = "Visibility"
  $ProgressSliderTick_Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
  [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.VideoView_Sep3_Label,[System.Windows.Controls.TextBox]::VisibilityProperty, $ProgressSliderTick_Binding)
}

#VideoView Cast Events
[System.Windows.RoutedEventHandler]$Synchash.CastMedia_Command  = {
  param($sender)
  try{  
    if($thisApp.Config.Use_MediaCasting){
      if($($sender.header) -and $(Test-URL $sender.tag) -and $($sender.isChecked)){
        write-ezlogs "##### Staring Cast to device: $($sender.header) - $($sender.tag)" -linesbefore 1       
        if($synchash.vlc.isPlaying){
          Update-LibVLC -thisApp $thisApp -synchash $synchash -EnableCasting -force
          $mediaurl = "$($synchash.vlc.media.mrl)"
          if([system.io.file]::Exists($(([uri]$mediaurl).LocalPath))){            
            Start-MediaCast -synchash $synchash -thisApp $thisApp -devicename $sender.header -deviceurl $sender.tag -launch -Use_Runspace -RunspaceName "$((New-Guid).Guid)_MediaCastRunspace" -LocalMediaURL ([uri]$mediaurl).LocalPath
          }else{
            Start-MediaCast -synchash $synchash -thisApp $thisApp -devicename $sender.header -deviceurl $sender.tag -launch -Use_Runspace -RunspaceName "$((New-Guid).Guid)_MediaCastRunspace"
          }          
        }else{
          write-ezlogs "Cannot start Media Casting - no media is currently playing!" -warning -AlertUI 
        }
      }elseif($($sender.header) -and $(Test-URL $sender.tag) -and !$($sender.isChecked)){
        write-ezlogs ">>>> Disable casting for device: $($sender.header) - $($sender.tag)"
        Start-MediaCast -synchash $synchash -thisApp $thisApp -devicename $sender.header -deviceurl $sender.tag -Close -Use_Runspace
        if($synchash.vlc.isPlaying){
          Update-LibVLC -thisApp $thisApp -synchash $synchash -force
        }
      }else{
        write-ezlogs "No valid casting device was selected" -warning
      }
    }else{
      write-ezlogs "Media Casting Support is not enabled! Cannot continue" -warning -AlertUI
    }      
  }catch{
    write-ezlogs 'An exception occurred in CastMedia_Command' -showtime -catcherror $_
  }
}

[System.Windows.RoutedEventHandler]$Synchash.ScanMediaRenderers_Command  = {
  param($sender)
  try{  
 
    if($thisApp.Config.Use_MediaCasting -and $synchash.VideoView_Cast_Button.IsExpanded){
      if($synchash.MediaRenderStatus_TextBox){
        $synchash.MediaRenderStatus_TextBox.Header = 'Scanning..........'
      }
      if($synchash.VideoView_Cast_rescan){
        $synchash.VideoView_Cast_rescan.isEnabled = $false
      }      
      if($synchash.PackIconFontAwesome_Spinner){
        $synchash.PackIconFontAwesome_Spinner.Spin = $true 
      }              
      Start-MediaCast -synchash $synchash -thisApp $thisApp -scan -Use_Runspace
    }else{
      write-ezlogs "Media Casting Support is not enabled! Cannot continue" -warning
    }     
  }catch{
    write-ezlogs 'An exception occurred in CastMedia_Command' -showtime -catcherror $_
    if($synchash.VideoView_Cast_rescan){
      $synchash.VideoView_Cast_rescan.isEnabled = $true
    }  
    if($synchash.PackIconFontAwesome_Spinner){
      $synchash.PackIconFontAwesome_Spinner.Spin = $false 
    }
    if($synchash.MediaRenderStatus_TextBox){
      $synchash.MediaRenderStatus_TextBox.Header = 'Scanning Error!!!!'
    }
  }
}


#region Subtitle Handlers
[System.Windows.RoutedEventHandler]$Synchash.FetchSubtitles_Command = {
  param($sender)
  try{   
    #Update-Subtitles -synchash $synchash -thisApp $thisApp -UpdateSubtitles
    if($thisApp.Config.Enable_Subtitles -and $synchash.Current_playing_media.source -eq 'Local' -and $synchash.vlc.media.state -in 'Playing','Paused'){
      if($synchash.MediaSubtitles_TextBox){
        $synchash.MediaSubtitles_TextBox.Header = 'Fetching..........'
      }
      if($sender.isEnabled){
        $sender.isEnabled = $false
      }      
      if($synchash.PackIconFontAwesome_Subtitle_Spinner){
        $synchash.PackIconFontAwesome_Subtitle_Spinner.Spin = $true 
      } 
      $Subtitles_Path = Get-OpenSubtitles -synchash $synchash -mediafile $synchash.Current_playing_media.url -thisApp $thisApp -Use_Runspace            
    }else{
      write-ezlogs "[FetchSubtitles_Command] Enable_Subtitles is not enabled or no valid media is playing! Cannot continue" -warning
    }     
  }catch{
    write-ezlogs '[FetchSubtitles_Command] An exception occurred in FetchSubtitles_Command' -showtime -catcherror $_
    $sender.isEnabled = $true  
    if($synchash.PackIconFontAwesome_Subtitle_Spinner){
      $synchash.PackIconFontAwesome_Subtitle_Spinner.Spin = $false 
    }
    if($synchash.MediaSubtitles_TextBox){
      $synchash.MediaSubtitles_TextBox.Header = 'Fetching Error!!!!'
    }
  }
}

[System.Windows.RoutedEventHandler]$Synchash.DelaySubtitles_Command = {
  param($sender)
  try{   
    if($thisApp.Config.Enable_Subtitles -and $synchash.Current_playing_media.source -eq 'Local' -and $synchash.vlc.media.state -in 'Playing','Paused'){
      #$subtitleID = $this.Tag
      #$isEnabled = $this.isChecked
      $existing = $synchash.vlc.SpuDelay
      if(-not [string]::IsNullOrEmpty($existing)){      
        if($this.Header -eq 'Increase Delay'){
          #increase by .5 seconds
          $existing = $existing + 500000
          $setSPU = $synchash.vlc.SetSpuDelay($existing)
          if($setSPU){
            write-ezlogs "[DelaySubtitles_Command] >>>> Increased Delay to: $($existing)"
          }else{
            write-ezlogs "[DelaySubtitles_Command] >>>> Unable to confirm increase of delay to $existing" -warning
          }
        }elseif($this.Header -eq 'Decrease Delay'){
          $existing = $existing - 500000
          #decrease by .5 seconds
          $setSPU = $synchash.vlc.SetSpuDelay($existing)
          if($setSPU){
            write-ezlogs "[DelaySubtitles_Command] >>>> Decreased delay to: $($existing)"
          }else{
            write-ezlogs "[DelaySubtitles_Command] >>>>  >>>> Unable to confirm decrease of delay to $existing" -warning
          }   
        }
        #Update-Subtitles -synchash $synchash -thisApp $thisApp -UpdateSubtitles
      }else{
        write-ezlogs "[DelaySubtitles_Command] Unable to find SPU delay in loaded vlc session -- Cannot continue!" -warning
      }
    }else{
      write-ezlogs "[DelaySubtitles_Command] Enable_Subtitles is not enabled or no valid media is playing! - Enable_Subtitles: $($thisApp.Config.Enable_Subtitles) - Vlc.media.state is playing or paused: $($synchash.vlc.media.state -in 'Playing','Paused') - Current_playing_media.source: $($synchash.Current_playing_media.source -eq 'Local')" -warning
    }     
  }catch{
    write-ezlogs '[EnableSubtitles_Command] An exception occurred in DelaySubtitles_Command' -showtime -catcherror $_
    if($synchash.VideoView_Subtitles_Fetch){
      $synchash.VideoView_Subtitles_Fetch.isEnabled = $true
    }  
    if($synchash.PackIconFontAwesome_Subtitle_Spinner){
      $synchash.PackIconFontAwesome_Subtitle_Spinner.Spin = $false 
    }
    if($synchash.MediaSubtitles_TextBox){
      $synchash.MediaSubtitles_TextBox.Header = 'Subtitle Error!!!!'
    }
  }finally{
    if($synchash.VideoView_Subtitles_Fetch){
      $synchash.VideoView_Subtitles_Fetch.isEnabled = $true
    }
  }
}


[System.Windows.RoutedEventHandler]$Synchash.EnableSubtitles_Command = {
  param($sender)
  try{   
    if($thisApp.Config.Enable_Subtitles -and $synchash.Current_playing_media.source -eq 'Local' -and $synchash.vlc.media.state -in 'Playing','Paused'){
      $subtitleID = $this.Tag
      $isEnabled = $this.isChecked
      if($synchash.vlc.SpuDescription.id -contains $subtitleID){
        $existing = $synchash.vlc.Spu
        #$description = $synchash.vlc.SpuDescription | Where-Object {$_.id -eq $subtitleID}
        #[Void]$synchash.vlc.pause()
        if($existing -eq $subtitleID -and !$isEnabled){
          $setSPU = $synchash.vlc.SetSpu(-1)
          if($setSPU){
            write-ezlogs "[EnableSubtitles_Command] >>>> Disabled Subtitles - Description: $($this.header)"
          }else{
            write-ezlogs "[EnableSubtitles_Command] >>>> Unable to confirm disabling of subtitles - Description: $($this.header)" -warning
          }
        }elseif($existing -ne $subtitleID -and $isEnabled){
          $setSPU = $synchash.vlc.SetSpu($subtitleID)
          if($setSPU){
            write-ezlogs "[EnableSubtitles_Command] >>>> Enabled subtitle track with ID: $subtitleID - Description: $($this.header)"
          }else{
            write-ezlogs "[EnableSubtitles_Command] >>>> Unable to confirm enabling of subtitles with ID: $subtitleID  - Description: $($this.header) -- existing ID: $existing" -warning
          }   
        }
        Update-Subtitles -synchash $synchash -thisApp $thisApp -UpdateSubtitles
      }else{
        write-ezlogs "[EnableSubtitles_Command] Unable to find subtitle track in current loaded vlc session with ID $($subtitleID) -- Cannot continue!" -warning
      }
      #[Void]$synchash.vlc.pause()
    }else{
      write-ezlogs "[EnableSubtitles_Command] Enable_Subtitles is not enabled or no valid media is playing! - Enable_Subtitles: $($thisApp.Config.Enable_Subtitles) - Vlc.media.state is playing or paused: $($synchash.vlc.media.state -in 'Playing','Paused') - Current_playing_media.source: $($synchash.Current_playing_media.source -eq 'Local')" -warning
    }     
  }catch{
    write-ezlogs '[EnableSubtitles_Command] An exception occurred in EnableSubtitles_Command' -showtime -catcherror $_
    if($synchash.VideoView_Subtitles_Fetch){
      $synchash.VideoView_Subtitles_Fetch.isEnabled = $true
    }  
    if($synchash.PackIconFontAwesome_Subtitle_Spinner){
      $synchash.PackIconFontAwesome_Subtitle_Spinner.Spin = $false 
    }
    if($synchash.MediaSubtitles_TextBox){
      $synchash.MediaSubtitles_TextBox.Header = 'Subtitle Error!!!!'
    }
  }finally{
    if($synchash.VideoView_Subtitles_Fetch){
      $synchash.VideoView_Subtitles_Fetch.isEnabled = $true
    }  
    if($synchash.PackIconFontAwesome_Subtitle_Spinner){
      $synchash.PackIconFontAwesome_Subtitle_Spinner.Spin = $false 
    }
  }
}
#endregion Subtitle Handlers
if($MediaControl_Handlers_Measure){
  $MediaControl_Handlers_Measure.stop()
  write-ezlogs "Buttons And Event Handlers - Media Control Handlers Startup" -PerfTimer $MediaControl_Handlers_Measure
  $MediaControl_Handlers_Measure = $Null
}
#---------------------------------------------- 
#endregion Media Control Handlers
#----------------------------------------------

if($thisApp.Config.startup_perf_timer){
  $Button_Event_Handler_Measure.stop()
  write-ezlogs "Total - Buttons And Event Handlers Startup" -PerfTimer $Button_Event_Handler_Measure
  $Button_Event_Handler_Measure = $Null
}
#############################################################################
#endregion Button And Event Hanlders
#############################################################################

#############################################################################
#region UI Event Handlers 
#############################################################################
if($thisApp.Config.startup_perf_timer){
  $UI_EventHandler_Measure = [system.diagnostics.stopwatch]::StartNew()
}

#---------------------------------------------- 
#region Set-WPFButtons
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $Set_WPFButtons_Measure = [system.diagnostics.stopwatch]::StartNew()
}
if($synchash.Window){
  $synchash.No_SettingsPreload = $No_SettingsPreload
  Set-WPFButtons -synchash $synchash -thisApp $thisApp -No_SettingsPreload $synchash.No_SettingsPreload -hashsetup $hashsetup
}
if($Set_WPFButtons_Measure){
  $Set_WPFButtons_Measure.stop()
  write-ezlogs ">>>> UI and Event Handlers - Set_WPFButtons Startup" -PerfTimer $Set_WPFButtons_Measure
  $Set_WPFButtons_Measure = $Null
}
#---------------------------------------------- 
#endregion Set-WPFButtons
#----------------------------------------------

#---------------------------------------------- 
#region Main Window Event Handlers
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $Main_Window_Events_Measure = [system.diagnostics.stopwatch]::StartNew()
}

if($synchash.Window){
  $synchash.Window.Add_loaded({
      try{
        if($thisApp.Config.startup_perf_timer){
          $Window_Loaded_measure = [system.diagnostics.stopwatch]::StartNew() 
        }          
        #Register window to installed application ID 
        try{
          $current_Window_Helper = [System.Windows.Interop.WindowInteropHelper]::new($synchash.Window)   
          if($thisApp.Config.Installed_AppID -and !$freshStart){
            $appid = $thisApp.Config.Installed_AppID
          }else{
            $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
          }
          if($current_Window_Helper.Handle -and $appid){        
            $taskbarinstance = [Microsoft.WindowsAPICodePack.Taskbar.TaskbarManager]::Instance
            write-ezlogs ">>>> Registering main window handle: $($current_Window_Helper.Handle) -- to appid: $appid" -Dev_mode
            $taskbarinstance.SetApplicationIdForSpecificWindow($current_Window_Helper.Handle,$appid)
            if($thisApp.Config.Installed_AppID -ne $appid){
              $thisApp.Config.Installed_AppID = $appid
            }
          }  
        }catch{
          write-ezlogs "An exception occurred registering main window handle: $($current_Window_Helper.Handle) -- to appid: $appid" -catcherror $_
        }             
        #Auto Updates
        if($thisapp.config.Auto_UpdateCheck -and $thisApp.Enable_Update_Features){
          Get-Updates -thisApp $thisapp -synchash $synchash -AutoCheck -AutoInstall:$thisApp.Config.Auto_UpdateInstall
        }
                 
        #Load Main Window Color Theme        
        if($thisApp.Config.startup_perf_timer){
          $Themes_Measure = [system.diagnostics.stopwatch]::StartNew() 
        }  
        Import-Module -Name "$Current_Folder\Modules\Set-WPFSkin\Set-WPFSkin.psm1" -NoClobber -DisableNameChecking -Scope Local
        Set-WPFTheme -thisApp $thisApp -synchash $synchash -DPlayer
        if($Themes_Measure){
          $Themes_Measure.stop()
          write-ezlogs "Main Window Add_Loaded - Load Themes Startup" -PerfTimer $Themes_Measure
          $Themes_Measure = $Null
        }

        #Set Main UI Skin
        if($thisApp.Config.startup_perf_timer){
          $WPFSkin_Measure = [system.diagnostics.stopwatch]::StartNew() 
        }
        Set-WPFSkin -thisApp $thisApp -synchash $synchash -DPlayer
        if($WPFSkin_Measure){
          $WPFSkin_Measure.stop()
          write-ezlogs "Main Window Add_Loaded - Load WPFSkin Startup" -PerfTimer $WPFSkin_Measure
          $WPFSkin_Measure = $Null
        }
        if($synchash.Remember_Window_Pos_MenuItem){
          if($thisApp.Config.Remember_Window_Positions){
            $synchash.Remember_Window_Pos_MenuItem.isChecked = $true
            $synchash.window.SaveWindowPosition = $true
          }
          $synchash.Remember_Window_Pos_MenuItem.add_click({
              try{
                $thisApp.Config.Remember_Window_Positions = [bool]($synchash.Remember_Window_Pos_MenuItem.isChecked)
                if($synchash.window.isLoaded){
                  $synchash.window.SaveWindowPosition = [bool]($synchash.Remember_Window_Pos_MenuItem.isChecked)
                }
              }catch{
                write-ezlogs "An exception occurred in Remember_Window_Pos_MenuItem.add_click" -catcherror $_
              }
          })
        }
        #Show/Hide Title Bar
        if($synchash.ShowTitleBar_MenuItem){
          $synchash.ShowTitleBar_MenuItem.add_click({
              try{
                if($synchash.ShowTitleBar_MenuItem.isChecked){
                  $thisApp.Config.ShowTitleBar = $true
                  if($synchash.window.isLoaded){
                    $synchash.window.ShowTitleBar = $true
                  }
                  if($synchash.RootGrid.children -contains $synchash.LeftWindow_Button){
                    write-ezlogs "Removing Leftwindow button from rootgrid"
                    $synchash.RootGrid.Children.Remove($synchash.LeftWindow_Button)
                  }
                  if($synchash.TitleMenuGrid.children -notcontains $synchash.LeftWindow_Button){
                    write-ezlogs "Adding Leftwindow button to TitleMenuGrid"
                    $synchash.TitleMenuGrid.addChild($synchash.LeftWindow_Button)
                  } 
                  $synchash.MainGrid_Background_Image_Source2.Visibility="Visible"           
                }else{
                  $thisApp.Config.ShowTitleBar = $false
                  if($synchash.window){
                    $synchash.window.ShowTitleBar = $false
                  }    
                  if($synchash.TitleMenuGrid.children -contains $synchash.LeftWindow_Button){
                    write-ezlogs "Removing Leftwindow button from TitleMenuGrid"
                    $synchash.TitleMenuGrid.Children.Remove($synchash.LeftWindow_Button)
                  }
                  if($synchash.RootGrid.children -notcontains $synchash.LeftWindow_Button){
                    write-ezlogs "Adding Leftwindow button to RootGrid"
                    $synchash.RootGrid.AddChild($synchash.LeftWindow_Button)
                  }
                  $synchash.MainGrid_Background_Image_Source2.Visibility="Collapsed"
                }
              }catch{
                write-ezlogs "An exception occurred in ShowTitleBar_MenuItem.add_click" -catcherror $_
              }
          })
          if($thisApp.Config.ShowTitleBar){
            $synchash.ShowTitleBar_MenuItem.isChecked = $true
            $synchash.window.ShowTitleBar = $true
            if($synchash.RootGrid.children -contains $synchash.LeftWindow_Button){
              $synchash.RootGrid.Children.Remove($synchash.LeftWindow_Button)
            }
            if($synchash.TitleMenuGrid.children -notcontains $synchash.LeftWindow_Button){
              $synchash.TitleMenuGrid.addChild($synchash.LeftWindow_Button)
            }
          }else{
            $synchash.ShowTitleBar_MenuItem.isChecked = $false
            $synchash.window.ShowTitleBar = $false
            if($synchash.TitleMenuGrid.children -contains $synchash.LeftWindow_Button){
              $synchash.TitleMenuGrid.Children.Remove($synchash.LeftWindow_Button)
            }
            if($synchash.RootGrid.children -notcontains $synchash.LeftWindow_Button){
              $synchash.RootGrid.AddChild($synchash.LeftWindow_Button)
            }
          }
        }
        #PlayIcon Storyboard           
        $synchash.PlayIcon1_Storyboard = $synchash.PlayIcon.TryFindResource('PlayIcon1_Storyboard')
        if($synchash.PlayIcon1_Storyboard){
          [void][System.Windows.Media.Animation.Storyboard]::SetTargetProperty($synchash.PlayIcon1_Storyboard,"(RotateTransform.Angle)")
        }
        $synchash.PlayIcon2_Storyboard = $synchash.PlayIcon2.TryFindResource('PlayIcon2_Storyboard')
        if($synchash.PlayIcon2_Storyboard){
          [void][System.Windows.Media.Animation.Storyboard]::SetTargetProperty($synchash.PlayIcon2_Storyboard,"(RotateTransform.Angle)")
        }               
        if($synchash.MediaPlayer_Slider){
          $Slider1_Style = $synchash.Window.TryFindResource('Slider1')
          if($Slider1_Style){
            $Slider1_ImageControl = $Slider1_Style.FindName('Slider1_ImageControl',$synchash.MediaPlayer_Slider)
            $MainProgressSlider_Back = "$($thisApp.Config.Current_folder)\Resources\Skins\MainProgressSlider_Back.png"
            if([system.io.file]::Exists($MainProgressSlider_Back)){
              $stream_image = [System.IO.File]::OpenRead($MainProgressSlider_Back) 
              $image = [System.Windows.Media.Imaging.BitmapImage]::new()
              [void]$image.BeginInit()
              $image.CacheOption = "OnLoad"
              $image.DecodePixelWidth = "594"
              $image.StreamSource = $stream_image
              [void]$image.EndInit()
              [void]$stream_image.Close()
              [void]$stream_image.Dispose()
              $stream_image = $Null
              [void]$image.Freeze()
              $Slider1_ImageControl.Source = $image
              $image = $Null
            }
          }
        }
        if($synchash.VideoView_Cast_Button){
          $synchash.VideoView_Cast_Button.ArrowVisibility = 'Visible'
          Update-MediaRenderers -synchash $synchash -thisApp $thisApp -Startup
          if($thisApp.Config.Use_MediaCasting){
            $synchash.VideoView_Cast_Button.isEnabled = $true
            $synchash.VideoView_Cast_Button.Tooltip = 'Cast Media to other Device'
          }else{
            $synchash.VideoView_Cast_Button.isEnabled = $false
            $synchash.VideoView_Cast_Button.Tooltip = 'Media Casting Support is currently disabled'
          }
        }
        if($synchash.VideoView_Subtitles_Button){
          $synchash.VideoView_Subtitles_Button.ArrowVisibility = 'Visible'
          Update-Subtitles -synchash $synchash -thisApp $thisApp -Startup
        }
        #TODO: APP UI SOFTWARE RENDER MODE
        $RenderTier = [System.Windows.Media.RenderCapability]::Tier -shr 16
        if($thisApp.Config.ForceSoftwareRender -or $ForceSoftwareRender -or $RenderTier -eq 0){
          write-ezlogs ">>>> Setting ProcessRenderMode to SoftwareOnly and force enabling performance mode - current rendertier: $RenderTier" -warning
          [System.Windows.Media.RenderOptions]::ProcessRenderMode = [System.Windows.Interop.RenderMode]::SoftwareOnly      
          $thisApp.Force_Performance_Mode = $true
        }
        Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\PSGlobalHotKeys\PSGlobalHotKeys.psm1" -Force
        if($thisApp.Config.EnableGlobalHotKeys){
          Get-GlobalHotKeys -thisApp $thisApp -synchash $synchash -UnRegister -Register
        }
      }catch{
        write-ezlogs "An exception occurred in Window Add_Loaded event" -showtime -catcherror $_
      }finally{
        if($Window_Loaded_measure){
          $Window_Loaded_measure.stop()
          write-ezlogs "Main Window Add_Loaded Total" -PerfTimer $Window_Loaded_measure
          $Window_Loaded_measure = $Null
        }
      }
  })

  #VideoView Open Animation
  $synchash.VideoViewstoryboard = $synchash.Window.TryFindResource('VideoViewstoryboard')
  $synchash.VideoViewDoubleAnimation = $synchash.VideoViewstoryboard.Children[0]
  $synchash.VideoViewHeightstoryboard = $synchash.Window.TryFindResource('VideoViewHeightstoryboard')
  $synchash.VideoViewHeightDoubleAnimation = $synchash.VideoViewHeightstoryboard.Children[0]
 
  $synchash.VideoViewstoryboard.add_Completed({
      param($sender)
      try{
        if($thisApp.Config.Dev_mode){write-ezlogs ">>>> VideoViewstoryboard Completed -- Window Final Top: $($synchash.Window.Top)" -Dev_mode}
        $sender.Controller.Stop()
        if([Double]::IsNaN($synchash.Window.Top)){
          $synchash.Window_Top_OnVideoOpen = 1
        }else{
          $synchash.Window_Top_OnVideoOpen = $synchash.Window.Top
        }
      }catch{
        write-ezlogs "An exception occurred in VideoViewstoryboard" -catcherror $_
      }
  })
  if($thisApp.Config.Dev_mode){
    $synchash.VideoViewHeightstoryboard.add_Completed({
        param($sender)
        try{
          if($thisApp.Config.Dev_mode){write-ezlogs ">>>> VideoViewHeightstoryboard Completed" -Dev_mode}
          $sender.Controller.Stop()
        }catch{
          write-ezlogs "An exception occurred in VideoViewstoryboard" -catcherror $_
        }
    })
  }
  $synchash.WindowChromeStyle = $synchash.Window.TryFindResource('WindowChromeStyle')
  $synchash.Window.add_SizeChanged({    
      try{
        if($synchash.Window.WindowState -ne 'Maximized' -and $synchash.Window.Style -ne $synchash.WindowChromeStyle){            
          $synchash.Window.Style = $synchash.WindowChromeStyle
        }           
      }catch{
        write-ezlogs 'An exception occurred in window sizechanged event' -showtime -catcherror $_
      }
  })

  #DPI Changed Event
  $synchash.Window.Add_DpiChanged({
      param($sender,[System.Windows.DpiChangedEventArgs]$e)
      try{     
        if($e.OldDpi.PixelsPerInchX -ne $e.NewDpi.PixelsPerInchX -or $e.OldDpi.PixelsPerInchY -ne $e.NewDpi.PixelsPerInchY -or $e.OldDpi.PixelsPerDip -ne $e.NewDpi.PixelsPerDip){
          if($e.OriginalSource.Name){
            $OGSourceName = $e.OriginalSource.Name
          }else{
            $OGSourceName = $e.OriginalSource
          }
          if($e.Source.Name){
            $SourceName = $e.Source.Name
          }else{
            $SourceName = $e.Source
          }
          write-ezlogs "Main Window DPI changed -- OldDpi (Dip: $($e.OldDpi.PixelsPerDip) x: $($e.OldDpi.PixelsPerInchX) y: $($e.OldDpi.PixelsPerInchY)) -- NewDPI: (Dip: $($e.NewDpi.PixelsPerDip) x: $($e.NewDpi.PixelsPerInchX) y: $($e.NewDpi.PixelsPerInchY)) -- Source: $($SourceName) -- OriginalSource: $($OGSourceName)" -showtime
        }
      }catch{
        write-zlogs "An exception occurred in window DpiChanged event" -showtime -catcherror $_
      }      
  }) 

  #Window Resize Event
  $synchash.Window.Add_StateChanged({
      try{     
        if($thisApp.config.Minimize_To_Tray){    
          if($synchash.Window.WindowState -eq 'Minimized'){
            $synchash.window.Hide()                
            if($thisApp.Config.Dev_mode){
              write-ezlogs "Window state $($synchash.Window.WindowState)" -showtime -dev_mode
              write-ezlogs "Window is Active: $($synchash.window.IsActive)" -showtime -dev_mode
            }   
          }
          if($thisApp.Config.Dev_mode){
            write-ezlogs ">>>> Window State changed: $($args[1] | out-string)" -logtype Perf -GetMemoryUsage -forceCollection -PriorityLevel 3
          }         
        }
      }catch{
        write-zlogs "An exception occurred in window sizechanged event" -showtime -catcherror $_
      }      
  }) 
}
if($Main_Window_Events_Measure){
  $Main_Window_Events_Measure.stop()
  write-ezlogs ">>>> UI and Event Handlers - Main Window Events Startup" -PerfTimer $Main_Window_Events_Measure
  $Main_Window_Events_Measure = $Null
}
#---------------------------------------------- 
#endregion Main Window Event Handlers
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $Title_Menu_Events_Measure = [system.diagnostics.stopwatch]::StartNew()
}
#---------------------------------------------- 
#region Feedback
#----------------------------------------------
if($synchash.Submit_Feedback -and $thisApp.Enable_Feedback_Features){
  $synchash.Submit_Feedback.Add_Click({
      try{
        Show-FeedbackForm -PageTitle "Submit Feedback/Issues - $($thisApp.Config.App_Name) Media Player" -Logo "$($thisapp.Config.Current_Folder)\Resources\Skins\Samson_Logo.png"  -thisScript $thisScript -thisApp $thisapp -Verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -GetKnownIssues
      }catch{
        write-ezlogs "An exception occurred in Submit_Feedback Click event" -showtime -catcherror $_
      }
  })
}elseif($synchash.Submit_Feedback){
  $synchash.Submit_Feedback.isEnabled = $false
  $synchash.Submit_Feedback.Visibility = 'Collapsed'
}
#---------------------------------------------- 
#endregion Feedback
#----------------------------------------------

#---------------------------------------------- 
#region Check_Updates
#----------------------------------------------
if($synchash.Check_Updates -and $thisApp.Enable_Update_Features){
  $synchash.Check_Updates.Add_Click({
      param($sender)
      try{
        if($hashUpdatesWindow.Window.isVisible){
          write-ezlogs "Child Window is already open" -loglevel 2
          $hashUpdatesWindow.Window.Dispatcher.Invoke([Action]{$hashUpdatesWindow.Window.Activate()},"Normal")
        }else{
          Get-Updates -thisApp $thisapp -synchash $synchash -sendername $Sender.name
        }
      }catch{
        write-ezlogs "An exception occurred in Check_Updates Click event" -showtime -catcherror $_
      }
  })
}elseif($synchash.Check_Updates){
  $synchash.Check_Updates.isEnabled = $false
  $synchash.Check_Updates.Visibility = 'Collapsed'
}
#---------------------------------------------- 
#endregion Check_Updates
#----------------------------------------------

#---------------------------------------------- 
#region About_Menu
#----------------------------------------------
if($synchash.About_Menu){
  $synchash.About_Menu.Add_Click({
      param($sender)
      try{
        $sendername = $Sender.name
        if($hashAboutWindow.Window.isVisible){
          write-ezlogs "Child Window is already open" -loglevel 2
          $hashAboutWindow.Window.Dispatcher.Invoke([Action]{$hashAboutWindow.Window.Activate()},"Normal")
        }elseif([system.io.file]::Exists("$($thisApp.Config.Current_Folder)\Resources\Docs\About\About.md")){
          $markdownfile = "$($thisApp.Config.Current_Folder)\Resources\Docs\About\About.md"
          $windowtitle = "About $($thisApp.Config.App_Name) Media Player - $($thisApp.Config.App_Version) - Build: $($thisApp.Config.App_Build)"
          Show-ChildWindow -synchash $synchash -thisApp $thisApp -WindowTitle $windowtitle -Logo "$($thisapp.Config.Current_Folder)\Resources\Skins\Samson_Logo_Title.png" -MarkDownFile $markdownfile -sendername $sendername
        }
      }catch{
        write-ezlogs "An exception occurred in About_Menu Click event" -showtime -catcherror $_
      }
  })
}
#---------------------------------------------- 
#endregion About_Menu
#----------------------------------------------

#---------------------------------------------- 
#region Dedication_Menu
#----------------------------------------------
if([system.io.file]::Exists("$($Current_Folder)\Resources\Docs\About\About_FirstRun.md") -and $synchash.dedication_menu){
  $synchash.Dedication_Menu.Add_Click({
      param($sender)
      try{
        $sendername = $Sender.name
        if($hashDedicationWindow.Window.isVisible){
          write-ezlogs "Dedication Window is already open" -loglevel 2
          $hashDedicationWindow.Window.Dispatcher.Invoke([Action]{$hashDedicationWindow.Window.Activate()},"Normal")
        }else{
          if([system.io.file]::Exists("$($thisApp.Config.Current_Folder)\Resources\Docs\About\About_FirstRun.md")){
            $markdownfile = "$($thisApp.Config.Current_Folder)\Resources\Docs\About\About_FirstRun.md"
            $windowtitle = "Dedication -  $($thisApp.Config.App_Name) Media Player - $($thisApp.Config.App_Version)"
          }   
          Show-ChildWindow -synchash $synchash -thisApp $thisApp -WindowTitle $windowtitle -Logo "$($thisapp.Config.Current_Folder)\Resources\Skins\Samson_Logo_Title.png" -MarkDownFile $markdownfile -sendername $sendername
        }
      }catch{
        write-ezlogs "An exception occurred in About_Menu Click event" -showtime -catcherror $_
      }
  })
}elseif($synchash.Dedication_Menu){
  [Void]$synchash.Title_menu_title.items.Remove($synchash.Dedication_Menu)
}
#---------------------------------------------- 
#endregion About_Menu
#----------------------------------------------
if($Title_Menu_Events_Measure){
  $Title_Menu_Events_Measure.stop()
  write-ezlogs ">>>> UI and Event Handlers - Title Menu Events Startup" -PerfTimer $Title_Menu_Events_Measure
  $Title_Menu_Events_Measure = $Null
}

if($thisApp.Config.startup_perf_timer){
  $VolumeScreen_Events_Measure = [system.diagnostics.stopwatch]::StartNew()
}
#---------------------------------------------- 
#region Circle Volume Knob
#----------------------------------------------
if($synchash.Volumeknob){
  $synchash.Volumeknob.add_MouseEnter({
      $sender = $args[0]
      [System.Windows.Input.MouseEventArgs]$e = $args[1]
      try{
        $e.handled = $true
        $synchash.VerticalSlider_Storyboard.Storyboard.Begin()
      }catch{
        write-ezlogs "An exception occurred in Volumeknob.add_MouseEnter event" -showtime -catcherror $_
      }
  })
  $synchash.Volumeknob.add_MouseLeave({
      $sender = $args[0]
      [System.Windows.Input.MouseEventArgs]$e = $args[1]
      try{
        $e.handled = $true
        $synchash.VerticalSlider_StoryboardLeave.Storyboard.Begin()
      }catch{
        write-ezlogs "An exception occurred in Volumeknob.add_MouseLeave event" -showtime -catcherror $_
      }
  })
}
#---------------------------------------------- 
#endregion Circle Volume Knob
#----------------------------------------------

#---------------------------------------------- 
#region FullScreen Button
#----------------------------------------------
#Fullscreen Window
[System.Windows.RoutedEventHandler]$synchash.Float_Command = {
  param($sender)
  try{
    if(($sender.tag -eq 'VideoView' -or $sender.Uid -eq 'VideoView' -or $sender.Name -eq 'VideoView_Dock_Button')){
      if($synchash.MediaViewAnchorable -and !$synchash.MediaViewAnchorable.isFloating){
        if($synchash.Window.isVisible){
          $synchash.MediaViewAnchorable.FloatingLeft = $synchash.Window.Left
        }
        if($synchash.Window.isVisible -and $synchash.Window.Top -ge 0){
          $synchash.MediaViewAnchorable.FloatingTop = $synchash.Window.Top
        }else{
          $synchash.MediaViewAnchorable.FloatingTop = 0
        }
        $synchash.MediaViewAnchorable.float()
        if($sender.tooltip){
          $sender.tooltip = 'Dock Video Player'
        }      
      }elseif($synchash.MediaViewAnchorable.isFloating){
        if($sender.tooltip){
          $sender.tooltip = 'UnDock Video Player'
        }
        $synchash.MediaViewAnchorable.dock()
        $synchash.MediaViewAnchorable.Title = "Video Player"
      }
    }elseif(($sender.tag -eq 'MediaLibrary' -or $sender.Uid -eq 'MediaLibrary')){
      if($synchash.MediaLibraryAnchorable -and !$synchash.MediaLibraryAnchorable.isFloating){
        if($synchash.Window.isVisible){
          $synchash.MediaLibraryAnchorable.FloatingLeft = $synchash.Window.Left
        }
        if($synchash.Window.isVisible -and $synchash.Window.Top -ge 0){
          $synchash.MediaLibraryAnchorable.FloatingTop = $synchash.Window.Top
        }else{
          $synchash.MediaLibraryAnchorable.FloatingTop = 0
        }
        $synchash.MediaLibraryAnchorable.float()
        if($sender.tooltip){
          $sender.tooltip = 'Dock Media Library'
        }      
      }elseif($synchash.MediaLibraryAnchorable.isFloating){
        if($sender.tooltip){
          $sender.tooltip = 'UnDock Media Library'
        }
        $synchash.MediaLibraryAnchorable.dock()
      }
    }elseif(($sender.tag -eq 'TorBrowser' -or $sender.Uid -eq 'TorBrowser')){
      if($synchash.TorBrowserAnchorable -and !$synchash.TorBrowserAnchorable.isFloating -and $synchash.TorBrowserAnchorable.CanFloat){
        if($synchash.Window.isVisible){
          $synchash.TorBrowserAnchorable.FloatingLeft = $synchash.Window.Left
        }
        if($synchash.Window.isVisible -and $synchash.Window.Top -ge 0){
          $synchash.TorBrowserAnchorable.FloatingTop = $synchash.Window.Top
        }else{
          $synchash.TorBrowserAnchorable.FloatingTop = 0
        }
        $synchash.TorBrowserAnchorable.float()
        if($sender.tooltip){
          $sender.tooltip = 'Dock Tor Browser'
        }      
      }elseif($synchash.TorBrowserAnchorable.isFloating){
        if($sender.tooltip){
          $sender.tooltip = 'UnDock Tor Browser'
        }
        $synchash.TorBrowserAnchorable.dock()
      }
    }elseif(($sender.tag -eq 'WebBrowser' -or $sender.Uid -eq 'WebBrowser')){
      if($synchash.WebBrowserAnchorable -and !$synchash.WebBrowserAnchorable.isFloating){
        if($synchash.Window.isVisible){
          $synchash.WebBrowserAnchorable.FloatingLeft = $synchash.Window.Left
        }
        if($synchash.Window.isVisible -and $synchash.Window.Top -ge 0){
          $synchash.WebBrowserAnchorable.FloatingTop = $synchash.Window.Top
        }else{
          $synchash.WebBrowserAnchorable.FloatingTop = 0
        }    
        $synchash.WebBrowserAnchorable.float()
        if($sender.tooltip){
          $sender.tooltip = 'Dock Web Browser'
        }      
      }elseif($synchash.WebBrowserAnchorable.isFloating){
        if($sender.tooltip){
          $sender.tooltip = 'UnDock Web Browser'
        }
        $synchash.WebBrowserAnchorable.dock()
      }
    }
  }catch{
    write-ezlogs "An exception occurred in Float_Command" -showtime -catcherror $_
  }
}
[System.Windows.RoutedEventHandler]$synchash.FloatFullScreen_Command = {
  param($sender)
  try{  
    if(($sender.tag -eq 'VideoView' -or $sender.Uid -eq 'VideoView' -or $sender.name -eq 'VideoView_LargePlayer_Button')){
      if($synchash.MediaViewAnchorable -and !$synchash.MediaViewAnchorable.isFloating){
        if($thisApp.Config.Dev_mode){write-ezlogs "Not floating, floating then fullscreen" -Dev_mode}
        Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action FullScreen
      }elseif($synchash.MediaViewAnchorable.isFloating -and $synchash.VideoViewFloat.WindowState -eq 'Maximized'){
        write-ezlogs "Floating, maximized, setting to normal"
        Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action Normal
      }elseif($synchash.MediaViewAnchorable.isFloating -and $synchash.VideoViewFloat.WindowState -ne 'Maximized'){
        write-ezlogs "Floating, maximized, setting to normal"
        Set-VideoPlayer -thisApp $thisApp -synchash $synchash -Action Maximized
      } 
    }elseif(($sender.tag -eq 'MediaLibrary' -or $sender.Uid -eq 'MediaLibrary')){
      if($synchash.MediaLibraryAnchorable -and !$synchash.MediaLibraryAnchorable.isFloating){
        if($thisApp.Config.Dev_mode){write-ezlogs "MediaLibrary Not floating, floating then fullscreen" -dev_mode}
        $synchash.MediaLibraryAnchorable.IsMaximized = $true
        $synchash.MediaLibraryAnchorable.float()
      }elseif($synchash.MediaLibraryAnchorable.isFloating -and $synchash.MediaLibraryFloat.WindowState -eq 'Maximized'){
        if($thisApp.Config.Dev_mode){write-ezlogs "MediaLibrary Floating, maximized, setting to normal" -dev_mode}
        $synchash.MediaLibraryFloat.WindowState -eq 'Normal'
      }elseif($synchash.MediaLibraryAnchorable.isFloating -and $synchash.MediaLibraryFloat.WindowState -ne 'Maximized'){
        if($thisApp.Config.Dev_mode){write-ezlogs "MediaLibrary Floating, maximized, setting to normal" -dev_mode}
        $synchash.MediaLibraryFloat.WindowState -eq 'Maximized'
      }
    }elseif(($sender.tag -eq 'WebBrowser' -or $sender.Uid -eq 'WebBrowser')){
      if($synchash.WebBrowserAnchorable -and !$synchash.WebBrowserAnchorable.isFloating){
        if($thisApp.Config.Dev_mode){write-ezlogs "WebBrowser Not floating, floating then fullscreen" -dev_mode}
        $synchash.WebBrowserAnchorable.IsMaximized = $true
        $synchash.WebBrowserAnchorable.float()
      }elseif($synchash.WebBrowserAnchorable.isFloating -and $synchash.WebBrowserFloat.WindowState -eq 'Maximized'){
        if($thisApp.Config.Dev_mode){write-ezlogs "WebBrowser Floating, maximized, setting to normal"-dev_mode}
        $synchash.WebBrowserFloat.WindowState -eq 'Normal'
      }elseif($synchash.WebBrowserAnchorable.isFloating -and $synchash.WebBrowserFloat.WindowState -ne 'Maximized'){
        if($thisApp.Config.Dev_mode){write-ezlogs "WebBrowser Floating, maximized, setting to normal"-dev_mode}
        $synchash.WebBrowserFloat.WindowState -eq 'Maximized'
      }
    }  
  }catch{
    write-ezlogs "An exception occurred in FloatFullScreen_Command" -showtime -catcherror $_
  }
}

if($synchash.VideoView_LargePlayer_Button){
  [Void]$synchash.VideoView_LargePlayer_Button.AddHandler([Windows.Controls.Button]::ClickEvent,$synchash.FloatFullScreen_Command) 
}

if($synchash.VideoView_Dock_Button){
  [Void]$synchash.VideoView_Dock_Button.AddHandler([Windows.Controls.Button]::ClickEvent,$synchash.Float_Command)
}
if($synchash.Web_Button){
  [Void]$synchash.Web_Button.AddHandler([Windows.Controls.Button]::ClickEvent,$synchash.Float_Command)
}
#---------------------------------------------- 
#endregion FullScreen Button
#----------------------------------------------
if($VolumeScreen_Events_Measure){
  $VolumeScreen_Events_Measure.stop()
  write-ezlogs ">>>> UI and Event Handlers - Volume and Screen/Docking Events Startup" -PerfTimer $VolumeScreen_Events_Measure
  $VolumeScreen_Events_Measure = $Null
}

#---------------------------------------------- 
#region Chat View
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $ChatView_Events_Measure = [system.diagnostics.stopwatch]::StartNew()
}
[System.Windows.RoutedEventHandler]$synchash.ChatView_Command = {
  param($sender)
  try{
    if($synchash.chat_WebView2.isVisible -or $synchash.Comments_Grid.Visibility -ne 'Collapsed'){
      Update-ChatView -synchash $synchash -thisApp $thisApp -sender $sender -hide
      Add-Member -InputObject $thisapp.config -Name 'Chat_View' -Value $false -MemberType NoteProperty -Force
    }else{
      Update-ChatView -synchash $synchash -thisApp $thisApp -sender $sender -show
    } 
    #write-ezlogs "Comments_Grid.Visibility: $($synchash.Comments_Grid.Visibility)" -Dev_mode
    #write-ezlogs "chat_WebView2.isVisible: $($synchash.chat_WebView2.isVisible)" -Dev_mode
  }catch{
    write-ezlogs "An exception occurred in ChatView_Command" -showtime -catcherror $_
  }
}

if($synchash.Chat_View_Button){
  [Void]$synchash.Chat_View_Button.AddHandler([Windows.Controls.Button]::ClickEvent,$synchash.ChatView_Command)
}
if($synchash.Comments_Button){
  [Void]$synchash.Comments_Button.AddHandler([Windows.Controls.Button]::ClickEvent,$synchash.ChatView_Command)
}
if($synchash.Chat_GridSplitter){
  #Calculate width of chatview after manually resizing with gridsplitter
  $synchash.Chat_GridSplitter.add_DragCompleted({
      Param($sender,[System.Windows.Controls.Primitives.DragCompletedEventArgs]$e)
      try{      
        if($e.HorizontalChange -lt 0){
          $Change = [int]($synchash.chat_column.ActualWidth + ($e.HorizontalChange * -1))         
        }else{
          $Change = $synchash.chat_column.ActualWidth - $e.HorizontalChange 
        }
        if($synchash.chat_column.Width.Value){
          $synchash.Chat_Splitter_Value = $Change
        }elseif($synchash.chat_column.Width -is [int] -or $synchash.chat_column.Width -is [double]){
          $synchash.Chat_Splitter_Value = $synchash.chat_column.Width
        }      
        #$synchash.Chat_Splitter_Value = $synchash.chat_column.Width
        #$e.Handled = $true
        write-ezlogs "Chat_GridSplitter HorizontalChange: $($e.HorizontalChange) - chat_column.Width: $($synchash.chat_column.Width) -  Change: $($Change) - Chat_Splitter_Value: $($synchash.Chat_Splitter_Value)" -warning -dev_mode
      }catch{
        write-ezlogs "An exception occurred in PowerButton_ToggleButton.add_Checked  event" -CatchError $_ -showtime
      }  
  })
}
if($ChatView_Events_Measure){
  $ChatView_Events_Measure.stop()
  write-ezlogs ">>>> UI and Event Handlers - Chat View Events Startup" -PerfTimer $ChatView_Events_Measure
  $ChatView_Events_Measure = $Null
}
#---------------------------------------------- 
#endregion Chat View
#----------------------------------------------

#---------------------------------------------- 
#region Spicetify Options
#----------------------------------------------
$synchash.pode_server_scriptblock = {
  try{
    if(!(Get-command -Module Pode)){         
      try{  
        write-ezlogs ">>> Importing Module PODE" -showtime
        Import-Module "$($thisApp.Config.Current_folder)\Modules\Pode\Pode.psm1" -Force -NoClobber -DisableNameChecking
      }catch{
        write-ezlogs "An exception occurred Importing required module Pode" -showtime -catcherror $_
      }     
    }  
    try{  
      $podestate = Get-PodeServerPath  -ErrorAction SilentlyContinue
      if($podestate){
        write-ezlogs ">>>> Current PODE Server state: $($podestate | out-string)"
        if((NETSTAT.EXE -an) | Where-Object {$_ -match '127.0.0.1:8974' -or $_ -match '0.0.0.0:8974'}){Invoke-RestMethod -Uri 'http://127.0.0.1:8974/CLOSEPODE' -UseBasicParsing -ErrorAction SilentlyContinue} 
      }       
    }catch{
      write-ezlogs "An exception occurred closing existing pode server" -showtime -catcherror $_
    }          
    Start-PodeServer -Name "$($thisApp.Config.App_Name)_PODE" -Threads 2 {
      write-ezlogs "[Start-PodeServer] >>>> Starting PodeServer $($thisApp.Config.App_Name)_PODE on http://127.0.0.1:8974" -thisApp $thisApp   
      Add-PodeEndpoint -Address 127.0.0.1 -Port 8974 -Protocol Ws -PassThru -Force
      Add-PodeEndpoint -Address 127.0.0.1 -Port 8974 -Protocol Http -PassThru -Force
      Add-PodeRoute -Method Get -Path '/PLAY' -PassThru -ScriptBlock {
        $logfile = $using:logfile
        $thisapp = $using:thisapp
        $synchash = $using:synchash
        Send-PodeSignal -Value 'PLAY'
        write-ezlogs ">>>> Spotify PODE webevent sent [PLAY]" -showtime -logtype Spotify -LogLevel 2 -thisApp $thisApp
      }    
      Add-PodeRoute -Method Get -Path '/PAUSE' -PassThru -ScriptBlock {
        $logfile = $using:logfile
        $thisapp = $using:thisapp
        $synchash = $using:synchash
        Send-PodeSignal -Value 'PAUSE'
        write-ezlogs ">>>> Spotify PODE webevent sent [PAUSE]" -showtime -logtype Spotify -LogLevel 2 -thisApp $thisApp
      }
      Add-PodeRoute -Method Get -Path '/SETVOLUME' -PassThru -ScriptBlock {
        $logfile = $using:logfile
        $thisapp = $using:thisapp
        $synchash = $using:synchash
        $Volume = ($WebEvent.Request.URL -split '\?')[1]
        Send-PodeSignal -Value "SETVOLUME $($Volume)"
        write-ezlogs ">>>> Spotify PODE webevent sent [SETVOLUME $($Volume)]" -showtime -logtype Spotify -LogLevel 2 -thisApp $thisApp
      }
      Add-PodeRoute -Method Get -Path '/TOGGLEMUTE' -PassThru -ScriptBlock {
        $logfile = $using:logfile
        $thisapp = $using:thisapp
        $synchash = $using:synchash
        Send-PodeSignal -Value "TOGGLEMUTE"
        write-ezlogs ">>>> Spotify PODE webevent sent [TOGGLEMUTE]" -showtime -logtype Spotify -LogLevel 2 -thisApp $thisApp
      }
      Add-PodeRoute -Method Get -Path '/SETPOSITION' -PassThru -ScriptBlock {
        $logfile = $using:logfile
        $thisapp = $using:thisapp
        $synchash = $using:synchash
        $Position = ($WebEvent.Request.URL -split '\?')[1]
        Send-PodeSignal -Value "SETPOSITION $($Position)"
        write-ezlogs ">>>> Spotify PODE webevent sent [SETPOSITION $($Position)]" -showtime -logtype Spotify -LogLevel 2 -thisApp $thisApp
      }
      Add-PodeRoute -Method Get -Path '/PLAYURI' -PassThru -ScriptBlock {
        $logfile = $using:logfile
        $thisapp = $using:thisapp
        $synchash = $using:synchash
        $URI = ($WebEvent.Request.URL -split '\?')[1]
        if($URI -match 'spotify:'){Send-PodeSignal -Value $URI}
        write-ezlogs ">>>> Spotify PODE webevent sent [PLAYURI]: $($URI)" -showtime -logtype Spotify -LogLevel 2 -thisApp $thisApp
      }    
      Add-PodeRoute -Method Get -Path '/CLOSEPODE' -PassThru -ScriptBlock {
        $logfile = $using:logfile
        $thisapp = $using:thisapp
        $synchash = $using:synchash
        write-ezlogs ">>>> Spotify PODE webevent sent [CLOSEPODE]: Close-PodeServer" -showtime -logtype Spotify -LogLevel 2 -thisApp $thisApp
        Close-PodeServer
      }    
      Add-PodeSignalRoute -Path '/' -ScriptBlock {        
        $spicetify = ($SignalEvent.data.message | ConvertFrom-Json)
        $logfile = $using:logfile
        $thisapp = $using:thisapp
        $synchash = $using:synchash
        $synchash.Spicetify = $spicetify
        #write-ezlogs ">>>> Spotify Playing: $($synchash.Spicetify)" -showtime -logtype Spotify -LogLevel 3
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
if($thisapp.config.Use_Spicetify -and $thisApp.Config.Import_Spotify_Media){
  if($thisApp.Config.startup_perf_timer){
    $Spicetify_Startup_Measure = [system.diagnostics.stopwatch]::StartNew()
  }
  $synchash.Spicetify = ''
  $Variable_list = (Get-Variable -Scope Local) | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
  Start-Runspace -scriptblock $synchash.pode_server_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'PODE_SERVER_RUNSPACE' -thisApp $thisApp -synchash $synchash
  $Variable_list = $Null
  if($Spicetify_Startup_Measure){
    $Spicetify_Startup_Measure.stop()
    write-ezlogs ">>>> UI and Event Handlers - Spicetify/Pode Startup" -PerfTimer $Spicetify_Startup_Measure
    $Spicetify_Startup_Measure = $Null
  }
}
#---------------------------------------------- 
#endregion Spicetify Options
#----------------------------------------------

#---------------------------------------------- 
#TODO: REFACTOR AND FINISH
#region Friends Button
#----------------------------------------------
if($synchash.FriendsFlyout -and $thisApp.Config.Dev_mode){
  if($thisApp.Config.Startup_perf_timer){
    $Get_Friends_Measure = [system.diagnostics.stopwatch]::StartNew() 
  } 
  $synchash.Friends_FlyoutControl.isEnabled = $true
  $synchash.Friends_FlyoutControl.Visibility = 'Visible'
  $synchash.Friends_ToggleButton.Visibility = 'Visible'
  Get-Friends -synchash $synchash -thisApp $thisApp -Startup
  $synchash.FriendsFlyout.add_IsOpenChanged({
      try{
        if($synchash.FriendsFlyout.isOpen){
          $synchash.YoutubeWebview2_Visibility = $synchash.YoutubeWebView2.isVisible -and !$synchash.MediaViewAnchorable.isFloating
          $synchash.VideoView_Visibility = $synchash.VideoView.isVisible -and !$synchash.MediaViewAnchorable.isFloating
          $synchash.chat_WebView2_Visibility = $synchash.chat_WebView2.isVisible -and !$synchash.MediaViewAnchorable.isFloating
          $synchash.Comments_Grid_Visibility = $synchash.Comments_Grid.isVisible -and !$synchash.MediaViewAnchorable.isFloating         
          $synchash.WebView2_Visibility = $synchash.WebView2.isVisible -and !$synchash.MediaViewAnchorable.isFloating
          $synchash.WebBrowser_Visibility = $synchash.WebBrowser.isVisible -and !$synchash.WebBrowserAnchorable.isFloating
          $synchash.VideoView_Overlay_Visibility = $synchash.VideoView_Overlay_Grid.isVisible -and !$synchash.MediaViewAnchorable.isFloating
          if($synchash.YoutubeWebview2_Visibility -and $synchash.YoutubeWebView2){
            $synchash.YoutubeWebView2.Visibility = 'Collapsed'    
          }
          if($synchash.VideoView_Visibility -and $synchash.VideoView){
            $synchash.VideoView.Visibility = 'Collapsed'    
          }
          if($synchash.VideoView_Overlay_Visibility -and $synchash.VideoView_Overlay_Grid){
            $synchash.VideoView_Overlay_Grid.Visibility = 'Collapsed'
          }
          if($synchash.chat_WebView2_Visibility -and $synchash.chat_WebView2){
            $synchash.chat_WebView2.Visibility = 'Collapsed'    
          }
          if($synchash.Comments_Grid_Visibility -and $synchash.Comments_Grid){
            $synchash.Comments_Grid.Visibility = 'Collapsed'    
          }
          if($synchash.WebView2_Visibility -and $synchash.WebView2){
            $synchash.WebView2.Visibility = 'Collapsed'    
          }
          if($synchash.WebBrowser_Visibility -and $synchash.WebBrowser){
            $synchash.WebBrowser.Visibility = 'Collapsed'    
          }
        }else{
          if($synchash.YoutubeWebview2_Visibility -and $synchash.YoutubeWebView2){
            $synchash.YoutubeWebView2.Visibility = 'Visible'    
          }    
          if($synchash.VideoView_Visibility -and $synchash.VideoView){
            $synchash.VideoView.Visibility = 'Visible'    
          } 
          if($synchash.VideoView_Overlay_Visibility -and $synchash.VideoView_Overlay_Grid){
            $synchash.VideoView_Overlay_Grid.Visibility = 'Visible'
          }           
          if($synchash.chat_WebView2_Visibility -and $synchash.chat_WebView2){
            $synchash.chat_WebView2.Visibility = 'Visible'    
          } 
          if($synchash.Comments_Grid_Visibility -and $synchash.Comments_Grid){
            $synchash.Comments_Grid.Visibility = 'Visible'    
          }
          if($synchash.WebView2_Visibility -and $synchash.WebView2){
            $synchash.WebView2.Visibility = 'Visible'    
          }
          if($synchash.WebBrowser_Visibility -and $synchash.WebBrowser){
            $synchash.WebBrowser.Visibility = 'Visible'    
          }
        }
      }catch{
        write-ezlogs "An exception occurred in FriendsFlyout.add_IsOpenChanged" -catcherror $_
      }
  })
  if($Get_Friends_Measure){
    $Get_Friends_Measure.stop()
    write-ezlogs "Get-Friends Measure" -PerfTimer $Get_Friends_Measure
    $Get_Friends_Measure = $Null
  }
}
#---------------------------------------------- 
#endregion Friends Button
#----------------------------------------------

#---------------------------------------------- 
#TODO: REFACTOR TO MODULE
#region Dismiss Notifications Button
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $Notifications_Grid_Measure =[system.diagnostics.stopwatch]::StartNew()
}
#---------------------------------------------- 
#region Notification Button
#----------------------------------------------
if($synchash.NotificationFlyout){
  $synchash.NotificationFlyout.add_IsOpenChanged({
      try{
        if($synchash.NotificationFlyout.isOpen){
          $synchash.YoutubeWebview2_Visibility = $synchash.YoutubeWebView2.isVisible -and !$synchash.MediaViewAnchorable.isFloating
          $synchash.VideoView_Visibility = $synchash.VideoView.isVisible -and !$synchash.MediaViewAnchorable.isFloating
          $synchash.chat_WebView2_Visibility = $synchash.chat_WebView2.isVisible -and !$synchash.MediaViewAnchorable.isFloating
          $synchash.Comments_Grid_Visibility = ($synchash.Comments_Grid.isVisible) -and !$synchash.MediaViewAnchorable.isFloating
          $synchash.WebView2_Visibility = $synchash.WebView2.isVisible -and !$synchash.MediaViewAnchorable.isFloating
          $synchash.WebBrowser_Visibility = $synchash.WebBrowser.isVisible -and !$synchash.WebBrowserAnchorable.isFloating
          if($synchash.YoutubeWebview2_Visibility -and $synchash.YoutubeWebView2){
            $synchash.YoutubeWebView2.Visibility = 'Collapsed'    
          }
          if($synchash.VideoView_Visibility -and $synchash.VideoView){
            $synchash.VideoView.Visibility = 'Collapsed'    
          }
          if($synchash.chat_WebView2_Visibility -and $synchash.chat_WebView2){
            $synchash.chat_WebView2.Visibility = 'Collapsed'   
          }
          if($synchash.Comments_Grid_Visibility -and $synchash.Comments_Grid){
            $synchash.Comments_Grid.Visibility = 'Collapsed'     
          }
          if($synchash.WebView2_Visibility -and $synchash.WebView2){
            $synchash.WebView2.Visibility = 'Collapsed'    
          }
          if($synchash.WebBrowser_Visibility -and $synchash.WebBrowser){
            $synchash.WebBrowser.Visibility = 'Collapsed'    
          }
        }else{
          if($synchash.YoutubeWebview2_Visibility -and $synchash.YoutubeWebView2){
            $synchash.YoutubeWebView2.Visibility = 'Visible'    
          }    
          if($synchash.VideoView_Visibility -and $synchash.VideoView){
            $synchash.VideoView.Visibility = 'Visible'    
          }  
          if($synchash.chat_WebView2_Visibility -and $synchash.chat_WebView2){
            $synchash.chat_WebView2.Visibility = 'Visible'  
          } 
          if($synchash.Comments_Grid_Visibilityy -and $synchash.Comments_Grid){
            $synchash.Comments_Grid.Visibility = 'Visible'     
          } 
          if($synchash.WebView2_Visibility -and $synchash.WebView2){
            $synchash.WebView2.Visibility = 'Visible'    
          }
          if($synchash.WebBrowser_Visibility -and $synchash.WebBrowser){
            $synchash.WebBrowser.Visibility = 'Visible'    
          }
        }
      }catch{
        write-ezlogs "An exception occurred in NotificationFlyout.add_IsOpenChanged" -catcherror $_
      }
  })


  $synchash.NotificationFlyout.add_MouseEnter({
      try{
        if($synchash.NotificationFlyout.isOpen){
          $synchash.NotificationFlyout.IsAutoCloseEnabled = $false
        }else{
          $synchash.NotificationFlyout.IsAutoCloseEnabled = $true
        }
      }catch{
        write-ezlogs "An exception occurred in NotificationFlyout.add_MouseEnter"
      }
  })

  $synchash.NotificationFlyout.add_MouseLeave({
      try{
        $synchash.NotificationFlyout.IsAutoCloseEnabled = $true
      }catch{
        write-ezlogs "An exception occurred in NotificationFlyout.add_MouseLeave"
      }
  })
}

if($synchash.Notifications_Button){
  $synchash.Notifications_Button.Add_Click({
      if($synchash.NotificationFlyout.isOpen -eq $true){
        $synchash.NotificationFlyout.isOpen = $false
      }else{
        $synchash.NotificationFlyout.isOpen = $true
      }
  })
}
#---------------------------------------------- 
#endregion Notification Button
#----------------------------------------------
[System.Windows.RoutedEventHandler]$DismissclickEvent = {
  param ($sender,$e)
  try{
    [Void]$synchash.Notifications_Grid.Items.Remove($synchash.Notifications_Grid.SelectedItem)
    if([int]$synchash.Notifications_Badge.badge -gt 0){
      [int]$synchash.Notifications_Badge.badge = [int]$synchash.Notifications_Grid.items.count
      if([int]$synchash.Notifications_Badge.badge -eq 0){
        $synchash.Notifications_Badge.badge = ''
      }
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
    [Void]$synchash.Notifications_Grid.items.clear()
    $synchash.Notifications_Badge.badge = ''
    $synchash.NotificationFlyout.isOpen = $false
  }catch{
    write-ezlogs "An exception occurred for notifications DismissclickEvent" -showtime -catcherror $_
  }
}  
if($synchash.Notifications_Grid -and $synchash.Notifications_Grid.Columns.count -lt 6){
  try{  
    $buttonColumn = [System.Windows.Controls.DataGridTemplateColumn]::new()
    $buttonFactory = [System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.Button])
    [Void]$buttonFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, 'Dismiss')
    [Void]$buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $synchash.Window.TryFindResource('GridButtonStyle'))
    [Void]$buttonFactory.SetValue([System.Windows.Controls.Button]::NameProperty, 'Notification_dismiss_button')
    [Void]$buttonFactory.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$DismissclickEvent)
    [Void]$buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$DismissclickEvent)  
    $dataTemplate = [System.Windows.DataTemplate]::new()
    $dataTemplate.VisualTree = $buttonFactory
    $buttonHeaderFactory =[System.Windows.FrameworkElementFactory]::new([System.Windows.Controls.Button])
    [Void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::ContentProperty, "Dismiss All")
    [Void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $synchash.Window.TryFindResource("DetailButtonStyle"))
    [Void]$buttonHeaderFactory.SetValue([System.Windows.Controls.Button]::NameProperty, "Notification_dismissAll_button")
    [Void]$buttonHeaderFactory.RemoveHandler([System.Windows.Controls.Button]::ClickEvent,$DismissAllclickEvent)
    [Void]$buttonHeaderFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$DismissAllclickEvent)   
    $headerdataTemplate = [System.Windows.DataTemplate]::new()
    $headerdataTemplate.VisualTree = $buttonheaderFactory 
    $buttonColumn.HeaderTemplate = $headerdataTemplate
    $buttonColumn.CellTemplate = $dataTemplate
    $buttonColumn.Width="SizeToHeader"
    $buttonColumn.DisplayIndex = 0  
    [Void]$synchash.Notifications_Grid.Columns.add($buttonColumn)     
  }catch{
    write-ezlogs "An exception occurred configuring notification grid columns" -catcherror $_
  }
}
if($Notifications_Grid_Measure){
  $Notifications_Grid_Measure.stop()
  write-ezlogs ">>>> UI and Event Handlers - Notifications Grid Startup" -PerfTimer $Notifications_Grid_Measure
  $Notifications_Grid_Measure = $Null
}
#---------------------------------------------- 
#endregion Dismiss Notifications Button
#----------------------------------------------

#---------------------------------------------- 
#region Set-WebPlayerTimer
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $WebPlayerTimer_Measure =[system.diagnostics.stopwatch]::StartNew()
}
Import-Module -Name "$Current_Folder\Modules\Set-WebPlayerTimers\Set-WebPlayerTimers.psm1" -NoClobber -DisableNameChecking
Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -startup
Set-YoutubeWebPlayerTimer -synchash $synchash -thisApp $thisApp -startup
Set-SpotifyWebPlayerTimer -synchash $synchash -thisApp $thisApp -startup
if($Initialize_WebBrowser_timer){
  $Initialize_WebBrowser_timer.start()
}
if($WebPlayerTimer_Measure){
  $WebPlayerTimer_Measure.stop()
  write-ezlogs ">>>> UI and Event Handlers - WebPlayerTimer/WebBrowser Startup" -PerfTimer $WebPlayerTimer_Measure
  $WebPlayerTimer_Measure = $Null
}
#---------------------------------------------- 
#endregion Set-WebPlayerTimer
#----------------------------------------------

#---------------------------------------------- 
#region SlideText_StackPanel
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $SlideText_Measure =[system.diagnostics.stopwatch]::StartNew()
}
if($synchash.DisplayPanel_Storyboard.Storyboard -and $thisApp.Config.Dev_mode){
  write-ezlogs "[STARTUP] >>>> Registering Storyboard completed event for DisplayPanel_Storyboard.Storyboard" -dev_mode
  $synchash.DisplayPanel_Storyboard.Storyboard.add_Completed({
      try{
        write-ezlogs ">>>> DisplayPanel_Storyboard.Storyboard Completed" -dev_mode
      }catch{
        write-ezlogs "An exception occurred in DisplayPanel_Storyboard.Storyboard.add_Completed" -catcherror $_
      }
  })
}

if($synchash.SlideText_StackPanel){
  $synchash.SlideText_StackPanel.Add_SizeChanged({
      try{                 
        if($synchash.DisplayPanel_Storyboard -and $synchash.SlideText_StackPanel.ActualWidth -gt 500){
          $synchash.DisplayPanel_Slide_Animation.To = 0
          $synchash.DisplayPanel_Slide_Animation.From = $($synchash.SlideText_StackPanel.ActualWidth + 30)
          $synchash.SlideText_StackPanel2.SetValue([System.Windows.Controls.Canvas]::LeftProperty,$(-($synchash.SlideText_StackPanel.ActualWidth) - 30)) 
          $synchash.SlideText_StackPanel2.Visibility = 'Visible'
          $synchash.DisplayPanel_Storyboard.Storyboard.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
          $synchash.DisplayPanel_Storyboard.Storyboard.AutoReverse = $false
          if($thisApp.Config.Enable_Performance_Mode -or $thisApp.Force_Performance_Mode){
            $synchash.DisplayPanel_Storyboard.Storyboard.SetValue([System.Windows.Media.MediaTimeline]::DesiredFrameRateProperty,5)
          }else{
            $synchash.DisplayPanel_Storyboard.Storyboard.SetValue([System.Windows.Media.MediaTimeline]::DesiredFrameRateProperty,$null)
          }         
          $synchash.DisplayPanel_Storyboard.Storyboard.Begin($synchash.DisplayPanel_Text_StackPanel,[System.Windows.Media.Animation.HandoffBehavior]::SnapshotAndReplace,$true)
          #$synchash.DisplayPanel_Storyboard.Storyboard.Begin()
        }elseif($synchash.DisplayPanel_Storyboard){
          $synchash.SlideText_StackPanel2.Visibility = 'Hidden'
          $synchash.DisplayPanel_Storyboard.Storyboard.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::new(0)
          $synchash.DisplayPanel_Storyboard.Storyboard.Stop($synchash.DisplayPanel_Text_StackPanel)
        }
      }catch{
        write-ezlogs "An exception occurred in SlideText_StackPanel.Add_SizeChanged event" -CatchError $_ -showtime
      }  
  })
}

$NowPlayingDataContext = {
  Param($Sender)
  try{
    if(-not [string]::IsNullOrEmpty($synchash.Now_Playing_Artist_Label.DataContext)){
      $Artist = " - $($synchash.Now_Playing_Artist_Label.DataContext)"
      $AnchorArtist = "$($synchash.Now_Playing_Artist_Label.DataContext)"
    }else{
      $Artist = ''
      $AnchorArtist = ""
    }
    if(-not [string]::IsNullOrEmpty($synchash.Now_Playing_Title_Label.DataContext)){
      $Playstate = "$($synchash.Now_Playing_Label.DataContext) - "
      $FloatTitle = "$($synchash.Now_Playing_Title_Label.DataContext)"
      $TrayTitle = "$($synchash.Now_Playing_Title_Label.DataContext)"
    }else{
      $Playstate = ""
      $TrayTitle = ""
      $FloatTitle = "Video Player"
    }
    $FloatText = "$Playstate$($FloatTitle)$($Artist) - $($thisApp.Config.App_Name) Media Player"
    if($synchash.VideoViewFloat.isVisible){
      $synchash.VideoViewFloat.Title = $FloatText
    }
    $tag = [PSCustomObject]@{
      'Now_Playing_Label' = $synchash.Now_Playing_Label.DataContext
      'Now_Playing_Label_Visibility' = $synchash.Now_Playing_Label.Visibility
      'Now_Playing_Sep1_Label' = $synchash.Now_Playing_Sep1_Label.content
      'Now_Playing_Sep2_Label' = $synchash.Now_Playing_Sep2_Label.content
      'Now_Playing_Title_Label' = $FloatTitle
      'Now_Playing_Artist_Label' = $AnchorArtist
      'Name' = 'VideoView'
    }
    if($synchash.MediaViewAnchorable.ToolTip -ne $tag){
      $synchash.MediaViewAnchorable.ToolTip = $tag
    }
    if($synchash.TrayPlayer){
      $TrayText = "$Playstate$($TrayTitle)$($Artist) - $($thisApp.Config.App_Name) Media Player"
      if($TrayTitle){
        $synchash.TrayPlayer.ToolTipText = $TrayText
      }else{
        $synchash.TrayPlayer.ToolTipText = $synchash.Window.Title
      }
    } 
  }catch{
    write-ezlogs "An exception occurred in $($Sender.Name).Add_DataContextChanged event" -CatchError $_ -showtime
  }
}

#Kind of a wonky hack to bind Main window now playing label to floating windows
if($synchash.Now_Playing_Label){
  $synchash.Now_Playing_Label.Add_DataContextChanged($NowPlayingDataContext)
}

if($synchash.Now_Playing_Title_Label){
  $synchash.Now_Playing_Title_Label.Add_DataContextChanged($NowPlayingDataContext)
}
if($synchash.Now_Playing_Artist_Label){
  $synchash.Now_Playing_Artist_Label.Add_DataContextChanged($NowPlayingDataContext)
}

if($synchash.DisplayPanel_Title_TextBlock){
  $synchash.DisplayPanel_Title_TextBlock.Add_TargetUpdated({
      try{
        if($synchash.Now_Playing_Title_Label.DataContext -in 'LOADING...','SKIPPING ADS...','OPENING...','LOADING...Waiting for Pre-Roll ADs to Finish...' -and !$thisApp.Config.Enable_Performance_Mode -and !$thisApp.Force_Performance_Mode){        
          $synchash.TextBlockLoading_Storyboard.Storyboard.Pause()  
          $synchash.TextBlockLoading_Storyboard.Storyboard.RepeatBehavior = [System.Windows.Media.Animation.RepeatBehavior]::Forever
          $synchash.TextBlockLoading_Storyboard.Storyboard.Begin()
        }else{
          $synchash.TextBlockLoading_Storyboard.Storyboard.RepeatBehavior = '1x'
          $synchash.TextBlockLoading_Storyboard.Storyboard.Stop()    
        } 
        if($thisApp.Config.Current_Theme.PrimaryAccentColor){
          $color = [System.Windows.Media.SolidColorBrush]::new($thisApp.Config.Current_Theme.PrimaryAccentColor.ToString())
        }else{
          $color = $synchash.Window.TryFindResource('MahApps.Brushes.AccentBase')
        }
        if(-not [string]::IsNullOrEmpty($synchash.DisplayPanel_Title_TextBlock.Text)){
          $synchash.DisplayPanel_Status_Border.BorderBrush = $color
          $synchash.DisplayPanel_Status_TextBlock.Foreground = $color
          $synchash.DisplayPanel_Status_TextBlock.Opacity="1"
          $synchash.DisplayPanel_Status_Border.Opacity="1"
          $synchash.DisplayPanel_STOP_Border.Opacity="0.9"
          $synchash.DisplayPanel_STOP_Border.BorderBrush="#FF252525"
          $synchash.DisplayPanel_STOP_TextBlock.Foreground="#FF252525"
        }else{
          $synchash.DisplayPanel_Status_TextBlock.Foreground="#FF252525"
          $synchash.DisplayPanel_Status_Border.Opacity="0.9"
          $synchash.DisplayPanel_Status_Border.BorderBrush="#FF252525"
          $synchash.DisplayPanel_STOP_Border.BorderBrush = $color
          $synchash.DisplayPanel_STOP_TextBlock.Foreground = $color
          $synchash.DisplayPanel_STOP_Border.Opacity="1"
        }   
        $color = $Null
      }catch{
        write-ezlogs "An exception occurred in DisplayPanel_Title_TextBlock.Add_TargetUpdated event" -CatchError $_ -showtime
      }  
  })
}
#Get MiniDisplayPanel Storyboard Animation
$MiniDisplayPanel_Slide_Storyboard = $synchash.Window.TryFindResource('minislide')
if($MiniDisplayPanel_Slide_Storyboard){
  $synchash.MiniDisplayPanel_Slide_Storyboard = $MiniDisplayPanel_Slide_Storyboard.Children[0]
}
$MiniDisplayPanel_Slide_Storyboard = $Null
if($synchash.DisplayPanel_Artist_TextBlock){
  $synchash.DisplayPanel_Artist_TextBlock.Add_TargetUpdated({
      try{
        if(-not [string]::IsNullOrEmpty($synchash.DisplayPanel_Artist_TextBlock.Text)){
          $synchash.DisplayPanel_Sep2_Label.Visibility="Visible"
          if($synchash.MiniDisplayPanel_Sep2_Label -and $synchash.MiniDisplayPanel_Sep2_Label.Visibility -ne 'Visible'){
            $synchash.MiniDisplayPanel_Sep2_Label.Visibility="Visible"
          }
        }else{
          if($synchash.DisplayPanel_Sep2_Label -and $synchash.DisplayPanel_Sep2_Label.Visibility -ne "Hidden"){
            $synchash.DisplayPanel_Sep2_Label.Visibility="Hidden"
          }          
          if($synchash.MiniDisplayPanel_Sep2_Label -and $synchash.MiniDisplayPanel_Sep2_Label.Visibility -ne 'Hidden'){
            $synchash.MiniDisplayPanel_Sep2_Label.Visibility="Hidden"
          }
        }      
      }catch{
        write-ezlogs "An exception occurred in DisplayPanel_Title_TextBlock.Add_TargetUpdated event" -CatchError $_ -showtime
      }  
  })
}

if($synchash.DisplayPanel_Bitrate_TextBlock){
  $synchash.DisplayPanel_Bitrate_TextBlock.Add_TargetUpdated({
      try{
        if(-not [string]::IsNullOrEmpty($synchash.DisplayPanel_Bitrate_TextBlock.Text)){
          $synchash.DisplayPanel_Sep3_Label.Visibility="Visible"
          if($synchash.MiniDisplayPanel_Sep3_Label){
            $synchash.MiniDisplayPanel_Sep3_Label.Visibility="Visible"
          }
        }else{
          $synchash.DisplayPanel_Sep3_Label.Visibility="Hidden"
          if($synchash.MiniDisplayPanel_Sep3_Label){
            $synchash.MiniDisplayPanel_Sep3_Label.Visibility="Hidden"
          }
        }         
      }catch{
        write-ezlogs "An exception occurred in DisplayPanel_Bitrate_TextBlock.Add_TargetUpdated event" -CatchError $_ -showtime
      }  
  })
}
if($SlideText_Measure){
  $SlideText_Measure.stop()
  write-ezlogs ">>>> UI and Event Handlers - SlideText/Display Event Startup" -PerfTimer $SlideText_Measure
  $SlideText_Measure = $Null
}
#---------------------------------------------- 
#endregion SlideText_StackPanel
#----------------------------------------------

#---------------------------------------------- 
#region AvalonDock
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $Avalondock_Measure =[system.diagnostics.stopwatch]::StartNew()
}
Import-Module -Name "$Current_Folder\Modules\Set-AvalonDock\Set-AvalonDock.psm1" -NoClobber -DisableNameChecking -Scope Local
Set-AvalonDock -synchash $synchash -thisApp $thisApp -set_ContextMenu
if($Avalondock_Measure){
  $Avalondock_Measure.stop()
  write-ezlogs ">>>> UI and Event Handlers - Avalondock Startup" -PerfTimer $Avalondock_Measure
  $Avalondock_Measure = $Null
}
#---------------------------------------------- 
#endregion AvalonDock
#----------------------------------------------

#---------------------------------------------- 
#region Set-DiscordPresense
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $Set_DiscordPresense_Measure = [system.diagnostics.stopwatch]::StartNew()
}
Import-Module -Name "$Current_Folder\Modules\Set-DiscordPresense\Set-DiscordPresense.psm1" -NoClobber -DisableNameChecking
Set-DiscordPresense -synchash $synchash -thisapp $thisApp -startup
if($Set_DiscordPresense_Measure){
  $Set_DiscordPresense_Measure.stop()
  write-ezlogs ">>>> UI and Event Handlers - Set_DiscordPresense Startup" -PerfTimer $Set_DiscordPresense_Measure
  $Set_DiscordPresense_Measure = $Null
}
#---------------------------------------------- 
#endregion Set-DiscordPresense
#----------------------------------------------

#---------------------------------------------- 
#region TorManager
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $TorBrowser_Measure = [system.diagnostics.stopwatch]::StartNew()
}
if($synchash.TorBrowserAnchorable -and $synchash.TorTable -and $synchash.Tor_Search_Go_Button -and [System.IO.Directory]::Exists("$($thisApp.Config.Current_Folder)\Resources\winpython") -and $Enable_Tor_Features){
  [System.Windows.RoutedEventHandler]$Synchash.StopTorrent_Command = {
    param($sender)
    $Media = $_.OriginalSource.DataContext
    if(!$Media.url){$Media = $sender.tag}
    if(!$Media.url){$Media = $sender.tag.Media} 
    if(!$Media.url){$Media = $_.OriginalSource.tag.media}  
    try{
      write-ezlogs ">>>> Stopping torrent for $($media | out-string)" -warning
      $thisApp.Cancel_Tor_Download = $true
    }catch{
      write-ezlogs "An exception occurred in stoptorrent_command" -catcherror $_
    }
  }

  [System.Windows.RoutedEventHandler]$synchash.Tor_ContextMenu = {
    $sender = $args[0]
    [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]  
    $Torrent = $e.OriginalSource.datacontext.Record
    write-ezlogs "[ContextMenu] Torrent: $($Torrent | out-string)" -dev_mode
    try{
      if($e.OriginalSource){    
        $items = [System.Collections.Generic.List[object]]::new()
        if(($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Right) -and ($Torrent.ID)){                    
          write-ezlogs "[ContextMenu] Creating context menu for a media item -- e.OriginalSource.datacontext: $($e.OriginalSource | out-string)" -dev_mode
          if($e.OriginalSource){
            $e.OriginalSource.focus()
          }
          if($torrent.State -eq 'Complete' -and [system.io.file]::Exists($torrent.LocalURL)){
            $Play_Media = @{
              'Header' = 'Play'
              'Color' = 'White'
              'Icon_Color' = 'White'
              'Tag' = $Torrent
              'Command' = $synchash.PlayMedia_Command
              'Icon_kind' = 'Play'
              'Enabled' = $true
              'IsCheckable' = $false
            }
            [Void]$items.Add($Play_Media) 
          }
          $Stream_Torrent = @{
            'Header' = 'Stream'
            'ToolTip' = 'Attempt to play/stream torrent while downloading'
            'Color' = 'White'
            'IconPack' = 'PackIconModern'
            'Icon_Color' = 'White'
            'Tag' = $Torrent
            'Command' = $Synchash.DownloadMedia_Command
            'Icon_kind' = 'stream'
            'Enabled' = $true
            'IsCheckable' = $false
          }
          [Void]$items.Add($Stream_Torrent) 
          if($torrent.State -in 'Downloading','Started' ){
            $Stop_Torrent = @{
              'Header' = 'Stop Download'
              'ToolTip' = 'Stop Downloading Torrent'
              'Color' = 'White'
              'Icon_Color' = 'White'
              'Tag' = $Torrent
              'Command' = $Synchash.StopTorrent_Command
              'Icon_kind' = 'WebCancel'
              'Enabled' = $true
              'IsCheckable' = $false
            }
            [Void]$items.Add($Stop_Torrent) 
          }else{
            $Download_Torrent = @{
              'Header' = 'Download'
              'ToolTip' = 'Download Torrent to Local Disk'
              'Color' = 'White'
              'Icon_Color' = 'White'
              'Tag' = $Torrent
              'Command' = $Synchash.DownloadMedia_Command
              'Icon_kind' = 'Download'
              'Enabled' = $true
              'IsCheckable' = $false
            }
            [Void]$items.Add($Download_Torrent)
          }                          
          if($items -and $e.OriginalSource){   
            Add-WPFMenu -control $e.OriginalSource -items $items -AddContextMenu -sourceWindow $synchash
          }else{
            $e.Handled = $false
          }                                        
        }
      }else{
        write-ezlogs "Contextmenu already set for $($e.OriginalSource)" -warning
      }      
    }catch{
      write-ezlogs "An exception occurred creating contextmenu for $($e.Source.Name)" -showtime -catcherror $_
    }  
  }
  [Void]$synchash.TorTable.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Tor_ContextMenu)
  #[Void]$syncHash.TorTable.AddHandler([System.Windows.Controls.Button]::ClickEvent,$synchash.PlayMedia_Command)
  $synchash.Tor_Search_Go_Button.Add_Click({
      try{
        if(-not [string]::IsNullOrEmpty($synchash.Tor_Search_Textbox.text)){
          $synchash.TorBrowser_Progress_Ring.isActive = $true
          $synchash.TorTable.isEnabled = $false
          Get-Torrents -thisApp $thisApp -synchash $synchash -CheckVPN -SearchQuery $synchash.Tor_Search_Textbox.text #-Filter '1080p'
        }
      }catch{
        write-ezlogs "An exception occurred in Tor_Search_Go_Button.Add_Click" -CatchError $_ -showtime
      }  
  })
  $synchash.Tor_Search_Textbox.Add_PreviewKeyDown({
      param([Parameter(Mandatory)][Object]$sender,[Parameter(Mandatory)][Windows.Input.KeyEventArgs]$e)
      try{
        if($e.Key -eq 'Enter'){
          $synchash.Tor_Search_Go_Button.RaiseEvent([System.Windows.RoutedEventArgs]::New([System.Windows.Controls.Button]::ClickEvent)) 
        }
      }catch{
        write-ezlogs "An exception occurred in Tor_Search_Textbox.Add_PreviewKeyDown" -catcherror $_
      }
  })
}elseif($synchash.DockingDocumentPane.children -contains $synchash.TorBrowserAnchorable){
  $synchash.TorBrowserAnchorable.isEnabled = $false
  $synchash.TorTable.isEnabled = $false
  [Void]$synchash.DockingDocumentPane.children.Remove($synchash.TorBrowserAnchorable)
  $synchash.TorBrowserAnchorable = $null
}
if($TorBrowser_Measure){
  $TorBrowser_Measure.stop()
  write-ezlogs ">>>> UI and Event Handlers - TorBrowser Startup" -PerfTimer $TorBrowser_Measure
  $TorBrowser_Measure = $Null
}
#---------------------------------------------- 
#endregion TorManager
#----------------------------------------------

#---------------------------------------------- 
#region Fonts
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $LoadFonts_Startup_Measure = [system.diagnostics.stopwatch]::StartNew()
}
$DigitalDreams_Italic_Font = "$(([uri]"$($thisApp.Config.Current_Folder)\Resources\Fonts\digital-7 (italic).ttf").AbsoluteUri)#Digital-7"
$DigitalDreams_Font = "$(([uri]"$($thisApp.Config.Current_Folder)\Resources\Fonts\digital-7.ttf").AbsoluteUri)#Digital-7"
if($synchash.Media_Length_Label){
  $synchash.Media_Length_Label.FontFamily = $DigitalDreams_Italic_Font
}
if($synchash.Media_Current_Length_TextBox){
  $synchash.Media_Current_Length_TextBox.FontFamily = $DigitalDreams_Italic_Font
  <#  $Media_Current_LengthDataContext = {
      Param($Sender)
      try{
      if($Sender.DataContext -eq '' -or $synchash.Media_Total_Length_TextBox.DataContext -eq '00:00:00' -or $synchash.Media_Total_Length_TextBox.DataContext -eq ''){
      $synchash.Media_Length_Sep.Text = ''
      if($synchash.Media_Total_Length_TextBox.DataContext){
      $synchash.Media_Total_Length_TextBox.DataContext = ''
      }
      #$synchash.Media_Current_Length_TextBox.MinWidth = 0
      #$synchash.Media_Current_Length_TextBox.MaxWidth = $synchash.Media_Length_Stackpanel.ActualWidth
      }else{
      $synchash.Media_Length_Sep.Text = ' / '
      $Width = $synchash.Media_Total_Length_TextBox.ActualWidth + 6
      if($synchash.Media_Current_Length_TextBox.MinWidth -ne $Width){
      $synchash.Media_Current_Length_TextBox.MinWidth = $Width
      $synchash.Media_Current_Length_TextBox.MaxWidth = $Width
      }
      }
      }catch{
      write-ezlogs "An exception occurred in $($Sender.Name).Add_DataContextChanged event" -CatchError $_ -showtime
      }
      }
  $synchash.Media_Current_Length_TextBox.Add_DataContextChanged($Media_Current_LengthDataContext)#>
}
if($synchash.Media_Length_Sep){
  $synchash.Media_Length_Sep.FontFamily = $DigitalDreams_Italic_Font
}
if($synchash.Media_Total_Length_TextBox){
  $synchash.Media_Total_Length_TextBox.FontFamily = $DigitalDreams_Italic_Font
  $Media_Total_LengthDataContext = {
    Param($Sender)
    try{
      if($synchash.Media_Total_Length_TextBox.DataContext -eq '00:00:00' -or $synchash.Media_Total_Length_TextBox.DataContext -eq '0:0:0'){
        $synchash.Media_Length_Sep.Text = ''
        $synchash.Media_Total_Length_TextBox.DataContext = ''      
      }
    }catch{
      write-ezlogs "An exception occurred in $($Sender.Name).Add_DataContextChanged event" -CatchError $_ -showtime
    }
  }
  $synchash.Media_Total_Length_TextBox.Add_DataContextChanged($Media_Total_LengthDataContext)
}
if($synchash.DisplayPanel_Title_TextBlock){
  $synchash.DisplayPanel_Title_TextBlock.FontFamily = $DigitalDreams_Font
}
if($LoadFonts_Startup_Measure){
  $LoadFonts_Startup_Measure.stop()
  write-ezlogs ">>>> UI and Event Handlers - LoadFonts Startup" -PerfTimer $LoadFonts_Startup_Measure
  $LoadFonts_Startup_Measure = $Null
}
#---------------------------------------------- 
#endregion Fonts
#----------------------------------------------

#---------------------------------------------- 
#region New-RelayCommand
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $New_RelayCommand_Measure = [system.diagnostics.stopwatch]::StartNew()
}
New-RelayCommand -synchash $synchash -thisApp $thisApp -startup
if($New_RelayCommand_Measure){
  $New_RelayCommand_Measure.stop()
  write-ezlogs ">>>> UI and Event Handlers - New-RelayCommand Startup" -PerfTimer $New_RelayCommand_Measure
  $New_RelayCommand_Measure = $Null
}
#---------------------------------------------- 
#endregion New-RelayCommand
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $UI_EventHandler_Measure.stop()
  write-ezlogs "#### UI Event Handlers (and others) Total" -PerfTimer $UI_EventHandler_Measure
  $UI_EventHandler_Measure = $Null
}
#############################################################################
#endregion UI Event Handlers 
#############################################################################

#############################################################################
#region Execute and Display Output 
############################################################################# 

#---------------------------------------------- 
#region Start MediaTransportControls
#----------------------------------------------
if($thisApp.Config.startup_perf_timer){
  $Set_MediaTransportControls_Measure = [system.diagnostics.stopwatch]::StartNew()
}
Import-Module -Name "$Current_Folder\Modules\Start-MediaTransportControls\Start-MediaTransportControls.psm1" -NoClobber -DisableNameChecking -Scope Local
Start-MediaTransportControls -synchash $synchash -thisApp $thisapp -use_Runspace
if($Set_MediaTransportControls_Measure){
  $Set_MediaTransportControls_Measure.stop()
  write-ezlogs "Set_MediaTransportControls" -PerfTimer $Set_MediaTransportControls_Measure
  $Set_MediaTransportControls_Measure = $Null
}
#---------------------------------------------- 
#endregion Start MediaTransportControls
#----------------------------------------------

#---------------------------------------------- 
#region Window Focus
#----------------------------------------------
if($synchash.Window){
  $synchash.Window.add_PreviewGotKeyboardFocus({
      Param($sender,[System.Windows.Input.KeyboardFocusChangedEventArgs]$e)
      try{
        if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Main Window got keyboard focus event: oldfocus: [$($e.oldfocus)]:$($e.oldfocus.name) - NewFocus: [$($e.newFocus)]:$($e.newFocus.name)" -Dev_mode}
        if($sender.isVisible -and !$e.oldFocus -and $e.newFocus -and $e.Source.Parent -isnot [AvalonDock.DockingManager] -and $e.Source -isnot [AvalonDock.DockingManager]){   
          $e.Handled = $false 
          if(!$sender.Topmost){
            $isNotTopMost = $true
            $sender.Topmost = $true
          }
          if($synchash.MediaLibraryFloat.isVisible -and !$synchash.MediaLibraryFloat.Topmost){
            write-ezlogs " | Activating MediaLibraryFloat window" -Dev_mode
            $synchash.MediaLibraryFloat.Topmost = $true
            $synchash.MediaLibraryFloat.Topmost = $false
          }
          if($synchash.AudioOptions_Viewer.isVisible -and !$synchash.AudioOptions_Viewer.Topmost){
            write-ezlogs " | Activating AudioOptions_Viewer window" -Dev_mode
            $synchash.AudioOptions_Viewer.Topmost = $true
            $synchash.AudioOptions_Viewer.Topmost = $false
          } 
          if($hashsetup.Window){
            write-ezlogs " | Activating settings window: $($hashsetup.Window.isVisible) - $($hashsetup.Window.Visibility)" -Dev_mode
            Update-SettingsWindow -hashsetup $hashSetup -thisApp $thisApp -BringToFront
          } 
          if($isNotTopMost){
            $sender.Topmost = $false
          }                             
        }
      }catch{
        write-ezlogs "An exception occurred in Window.add_PreviewGotKeyboardFocus" -showtime -catcherror $_
      }
  })
}
#----------------------------------------------
#endregion Window Focus
#----------------------------------------------

#---------------------------------------------- 
#region Window Close
#----------------------------------------------
if($synchash.Window){
  $synchash.Window.Add_Closing({
      Param($sender,[System.ComponentModel.CancelEventArgs]$e)
      try{
        write-ezlogs "#### App is Shutting Down" -loglevel 2 -linesbefore 1
        $synchash.MainWindow_IsClosing = $true
        [Void]$synchash.timer.stop()
        if($synchash.VLC){
          [Void]$synchash.VLC.stop()
        }
        if($synchash.YoutubeWebview2.coreWebview2){
          try{
            write-ezlogs "| Disposing YoutubeWebview2 Session" -loglevel 2
            [Void]$synchash.YoutubeWebview2.dispose()
          }catch{
            write-ezlogs "An exception occurred disposing YoutubeWebview2" -catcherror $_
          }
        }
        if($synchash.Webview2.coreWebview2){       
          try{
            write-ezlogs "| Disposing Spotify Webview2 Session" -loglevel 2
            [Void]$synchash.Webview2.dispose()
          }catch{
            write-ezlogs "An exception occurred disposing Spotify Webview2" -catcherror $_
          }
        }
        if($synchash.WebBrowser.coreWebview2){
          try{
            write-ezlogs "| Disposing WebBrowser Webview2 Session" -loglevel 2
            [Void]$synchash.WebBrowser.dispose()
          }catch{
            write-ezlogs "An exception occurred disposing WebBrowser Webview2" -catcherror $_
          }             
        }
        try{
          #Close Anchorables to collapse all window owners - Prevents exceptions caused when exiting dispatcher thread
          if($synchash.MediaViewAnchorable.isFloating){
            write-ezlogs " | Docking MediaViewAnchorable" -loglevel 2
            [Void]$synchash.MediaViewAnchorable.Dock()
          } 
          if($synchash.WebBrowserAnchorable.isFloating){
            write-ezlogs " | Docking WebBrowserAnchorable" -loglevel 2
            [Void]$synchash.WebBrowserAnchorable.Dock()
          }
          if($synchash.MediaLibraryAnchorable.isFloating){
            write-ezlogs " | Docking MediaLibraryAnchorable" -loglevel 2
            [Void]$synchash.MediaLibraryAnchorable.Dock()
          }
        }catch{
          write-ezlogs 'An exception occurred closing anchorables event' -showtime -catcherror $_
        } 
        if($synchash.TrayPlayer){
          try{
            [Void]$synchash.TrayPlayer.dispose()
          }catch{
            write-ezlogs "An exception occurred disposing TrayPlayer" -catcherror $_
          }   
        } 
        if($synchash.VLC){
          try{
            Close-LibVLC -synchash $synchash -thisApp $thisApp
          }catch{
            write-ezlogs "An exception occurred when disposing and unregistering events for libvlc" -catcherror $_
          }
        }
        if($synchash.WebBrowserGrid.Children -contains $synchash.AirControl){
          write-ezlogs "| Removing Aircontrol from WebBrowserGrid" -loglevel 2
          [Void]$synchash.WebBrowserGrid.children.Remove($synchash.AirControl)
        }
        if($synchash.VLC_Grid.Children -contains $synchash.VideoViewAirControl){
          Write-EZLogs '| Removing VideoViewAirControl from VLC_Grid' -loglevel 2
          [Void]$synchash.VLC_Grid.children.Remove($synchash.VideoViewAirControl)
          $synchash.VideoViewAirControl.Front = $null
          $synchash.VideoViewAirControl.Back = $null
          $synchash.VideoViewAirControl = $null
        }
        #close podeserver
        if((NETSTAT.EXE -an) | Where-Object {$_ -match '127.0.0.1:8974' -or $_ -match '0.0.0.0:8974'}){
          write-ezlogs "| Closing PODE Server with 'http://127.0.0.1:8974/CLOSEPODE'" -loglevel 2
          Invoke-RestMethod -Uri 'http://127.0.0.1:8974/CLOSEPODE' -UseBasicParsing -ErrorAction SilentlyContinue
        }
        Get-GlobalHotKeys -thisApp $thisApp -synchash $synchash -UnRegister -Shutdown
        if($thisApp.Config.Remember_Window_Positions){
          $thisapp.config.MainWindow_Top = $synchash.Window.Top
          $thisapp.config.MainWindow_Left = $synchash.Window.Left
          if($synchash.WebBrowserFloat){
            $thisapp.config.BrowserWindow_Top = $synchash.WebBrowserFloat.Top
            $thisapp.config.BrowserWindow_Left = $synchash.WebBrowserFloat.Left
          }
          if($synchash.MediaLibraryFloat){
            $thisapp.config.LibraryWindow_Top = $synchash.MediaLibraryFloat.Top
            $thisapp.config.LibraryWindow_Left = $synchash.MediaLibraryFloat.Left
          }
          if($synchash.VideoViewFloat){
            $thisapp.config.VideoWindow_Top = $synchash.VideoViewFloat.Top
            $thisapp.config.VideoWindow_Left = $synchash.VideoViewFloat.Left
          }
        }
      }catch{
        write-ezlogs "An exception occurred in Add_Closing event" -showtime -catcherror $_
      }
  })

  $synchash.Window.Add_Closed({
      try{
        $synchash.Spicetify = ''
        if([System.IO.File]::Exists($thisApp.Config.Config_Path)){
          if($debug_mode){
            $thisapp.config.Dev_mode = $false
          }
          write-ezlogs "| Saving config file to: $($thisapp.Config.Config_Path)"
          Export-SerializedXML -InputObject $thisApp.Config -Path $thisapp.Config.Config_Path -isConfig
        }
        if($synchash.all_playlists){
          Export-SerializedXML -InputObject $synchash.All_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist -Force
        }
        #Close thirdparty processes but only if they are ours
        if(-not ((get-process *p*) | Where-Object {$_.MainWindowTitle -match "$($thisApp.Config.App_name) Media Player - $($thisApp.Config.App_version)" -or $_.MainWindowTitle -match "Video Player - $($thisApp.Config.App_name)"})){
          if((Get-Process Spotify*) -and !$thisApp.Config.Spotify_WebPlayer){
            write-ezlogs " | Closing Spotify" -loglevel 2
            Get-Process Spotify* | Stop-Process -Force
          }
          if((Get-Process streamlink*) -and !($dev_mode)){           
            write-ezlogs " | Closing Streamlink process" -loglevel 2
            Get-Process streamlink* | Stop-Process -Force
          }
        }  
        if($synchash.Current_Audio_Session -and !$synchash.Current_Audio_Session.IsDisposed){
          write-ezlogs " | Disposing Main App Audio Session" -loglevel 2
          [Void]$synchash.Current_Audio_Session.Dispose()
        }      
        if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled){
          $synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled = $false
        }
        if($synchash.DSClient.IsInitialized){
          try{
            write-ezlogs " | Stopping existing DSClient $($synchash.DSClient.CurrentPresence)" -showtime -logtype Discord -LogLevel 2
            Stop-DSClient     
            $synchash.DsClient = $null
          }catch{
            write-ezlogs "An exception occurred diposing dsclient $($synchash.DSClient | out-string)" -showtime -catcherror $_
          }
        } 
        if($thisApp.Config.Enable_LocalMedia_Monitor -and ($thisApp.ProfileManagerEnabled -or $thisApp.LocalMedia_Monitor_Enabled)){
          Stop-FileWatcher -thisApp $thisApp -synchash $synchash -use_Runspace -Stop_ProfileManager -force 
        }                    
        [Void][System.Windows.Threading.Dispatcher]::ExitAllFrames()
        [Void][System.Windows.Threading.Dispatcher]::CurrentDispatcher.InvokeShutdown()
        Write-ezlogs ">>>> Exited app CurrentDispatcher threading" -showtime -loglevel 2
      }catch{
        Write-ezlogs "An exception occurred during add_closed cleanup" -showtime -catcherror $_
      } 
  })
}
#----------------------------------------------
#endregion Window Close
#----------------------------------------------

#----------------------------------------------
#region Display Main Window
#----------------------------------------------
try{
  #Add Validation Control
  if($thisApp.Config.startup_perf_timer){
    $Synchash.Show_UI_Measure = [system.diagnostics.stopwatch]::StartNew()
  } 


  if($synchash.Window){
    $synchash.Window.add_IsVisibleChanged({
        try{
          if(!$synchash.Window.isVisible -and !$synchash.MediaViewAnchorable.isfloating -and $synchash.MiniPlayer_Viewer.isVisible -and $synchash.VideoView.Visibility -eq 'Visible'){ 
            write-ezlogs ">>>> Miniplayer window is visible, mediaviewanchorable is not floating and main window is not visible, hiding video view" -Warning
            $synchash.VideoView.Visibility='Collapsed'
          }else{
            if(!$synchash.MiniPlayer_Viewer.isVisible -and $synchash.VideoView.Visibility -in 'Hidden','Collapsed' -and (!$synchash.YoutubeWebView2.CoreWebView2.IsDocumentPlayingAudio) -and $synchash.WebPlayer_State -eq 0 -and !$synchash.Youtube_WebPlayer_title){
              write-ezlogs ">>>> Video view is visible and Main window is not hidden, Youtube webplayer not playing, unhiding video view" -Warning
              $synchash.VideoView.Visibility = 'Visible'
            }      
          }
        }catch{
          write-ezlogs "An exception occurred in Window.add_IsVisibleChanged" -showtime -catcherror $_
        }
    })
    $synchash.Window.add_ContentRendered({
        try{                      
          if($Synchash.Show_UI_Measure){
            $Synchash.Show_UI_Measure.stop()
            write-ezlogs "Show_UI" -PerfTimer $Synchash.Show_UI_Measure
            $synchash.Remove('Show_UI_Measure')
            write-ezlogs "----------------------------------------------------------`n    | Total UI startup: $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds | `n----------------------------------------------------------" -CallBack:$false -showtime:$false -GetMemoryUsage -logfile $thisApp.Config.Perf_Log_File
          }
        }catch{
          write-ezlogs "An exception occurred in window add_contentRendered" -catcherror $_
        }
    })
    # Allow input to window for TextBoxes, etc
    [Void][System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($synchash.Window)
    if(!$thisApp.config.Start_Tray_only -and !$hashDedicationWindow.Window.isVisible){
      if($thisApp.config.Start_Mini_only -or $StartMini){
        try{             
          Open-MiniPlayer -thisApp $thisApp -synchash $synchash -Startup
          #Trick to prerender window without showing it - Set opacity to 0, show to render, then hide
          $synchash.window.ShowActivated = $false #Prevent window from activating/taking focus while rendering
          $synchash.window.Opacity = 0
          $synchash.window.ShowInTaskbar = $false
          [void]$synchash.window.Show()
          #$synchash.window.Hide()
          #$synchash.window.Opacity = 1
          #$synchash.window.ShowActivated = $true
          if($Synchash.Show_UI_Measure){   
            $Synchash.Show_UI_Measure.stop()
            write-ezlogs "Show_UI" -PerfTimer $Synchash.Show_UI_Measure
            write-ezlogs "`n----------------------------------------------------------`n    | Total UI startup: $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds |`n----------------------------------------------------------" -CallBack:$false -showtime:$false -GetMemoryUsage -logfile $thisApp.Config.Perf_Log_File
            $synchash.Remove('Show_UI_Measure')
          }
        }catch{
          write-ezlogs 'An exception occurred in MiniPlayer_button_Command click event' -showtime -catcherror $_
        }
      }else{
        if(-not [string]::IsNullOrEmpty($thisApp.Config.MainWindow_Top) -and -not [string]::IsNullOrEmpty($thisApp.Config.MainWindow_Left) -and $thisApp.Config.Remember_Window_Positions -and !$OpentoPrimaryScreen){
          $synchash.Window.Top = $thisApp.Config.MainWindow_Top
          $synchash.Window.Left = $thisApp.Config.MainWindow_Left
        }elseif($OpentoPrimaryScreen){
          $PrimaryMonitor = [System.Windows.Forms.Screen]::PrimaryScreen
          $synchash.Window.WindowStartupLocation = 'Manual'
          $synchash.Window.Top = $PrimaryMonitor.WorkingArea.top + 100
          $synchash.Window.Left = $PrimaryMonitor.WorkingArea.left + 100
        }
        #[Void]$synchash.Window.Dispatcher.InvokeAsync{}
        [Void]$synchash.Window.Show()
        #[Void]$synchash.Window.Activate()
      }
    }
  }elseif($Synchash.Show_UI_Measure){   
    $Synchash.Show_UI_Measure.stop()
    write-ezlogs "Show_UI" -PerfTimer $Synchash.Show_UI_Measure
    write-ezlogs "`n----------------------------------------------------------`n    | Total UI startup: $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds |`n----------------------------------------------------------" -CallBack:$false -showtime:$false -GetMemoryUsage -logfile $thisApp.Config.Perf_Log_File
    $synchash.Remove('Show_UI_Measure')
  }
  if($trayMenu -and $Update_TrayMenu_timer -and !$thisApp.Config.Disable_Tray){
    $Update_TrayMenu_timer.start()
  }
  #Close Splash Screen
  Update-SplashScreen -hash $hash -Close

  #----------------------------------------------
  #region Show-SettingsWindow hidden
  #----------------------------------------------
  if(!$No_SettingsPreload -and $synchash.Window){   
    Show-SettingsWindow -PageTitle "Settings - $($thisApp.Config.App_Name) Media Player" -PageHeader 'Settings' -Logo "$($thisapp.Config.Current_Folder)\Resources\Skins\Samson_Logo_Title.png" -synchash $synchash -thisApp $thisapp -hashsetup $hashsetup -Update -First_Run:$false -use_runspace -startHidden -globalstopwatch $startup_stopwatch
  }  
  #----------------------------------------------
  #endregion Show-SettingsWindow hidden
  #----------------------------------------------
  $synchash.Error = $error
}catch{
  $appcrash = $true
  write-ezlogs "An uncaught exception occurred and main ApplicationContext ended - Innerexeption: $($_.Exception.InnerException)" -showtime -catcherror $_ -callpath "$((Get-PSCallStack)[1].Command):$((Get-PSCallStack).InvocationInfo.ScriptLineNumber)"
  if($error){
    write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
  }
}
try{
  #This helps with responsiveness and threading.
  [void][System.Windows.Threading.Dispatcher]::Run()
}catch{
  $appcrash = $true
  if([system.io.file]::Exists($thisApp.Config.Log_file)){
    [System.IO.File]::AppendAllText($thisApp.Config.Log_file, "[$([datetime]::Now)] [ERROR] An uncaught exception occurred and main dispatcher thread ended: $($_ | out-string)" + ([Environment]::NewLine),[System.Text.Encoding]::Unicode)
  }
  write-ezlogs "An uncaught exception occurred and main dispatcher thread ended: $([System.Windows.Threading.Dispatcher]::CurrentDispatcher | out-string)" -showtime -catcherror $_
  if($synchash.Error){
    write-ezlogs -showtime -PrintErrors -ErrorsToPrint $synchash.Error
  }elseif($error){
    write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
  }
}finally{
  #if dispatcher crashed once, lets retry in case it was something stupid
  if($appcrash){
    try{
      write-ezlogs ">>> Launching new ApplicationContext" -showtime -warning
      [void][System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($synchash.Window)
      [void][System.Windows.Threading.Dispatcher]::Run()
    }catch{
      write-ezlogs "An uncaught exception occurred and main dispatcher thread ended: $($synchash.appContext | out-string)" -showtime -catcherror $_
      if($error -and $thisApp.Config.Log_file){
        try{
          foreach($e in $error){
            $text = $Null
            $text = "`:`n|+ [Exception]: $($e.Exception)`n`n|+ [PositionMessage]: $($e.InvocationInfo.PositionMessage | out-string)`n`n|+ [ScriptStackTrace]: $($e.ScriptStackTrace  | out-string)`n$(`
              if(-not [string]::IsNullOrEmpty(($e.InvocationInfo.PSCommandPath))){"|+ [PSCommandPath]: $($e.InvocationInfo.PSCommandPath | out-string)`n"})$(`
              if(-not [string]::IsNullOrEmpty(($e.InvocationInfo.InvocationName))){"|+ [InvocationName]: $($e.InvocationInfo.InvocationName | out-string)`n"})$(`
              if($e.InvocationInfo.MyCommand){"|+ [MyCommand]: $($e.InvocationInfo.MyCommand)`n"})$(`
              if(-not [string]::IsNullOrEmpty(($e.InvocationInfo.BoundParameters))){"|+ [BoundParameters]: $($e.InvocationInfo.BoundParameters | out-string)`n"})$(`
            if(-not [string]::IsNullOrEmpty(($e.InvocationInfo.UnboundArguments))){"|+ [UnboundArguments]: $($e.InvocationInfo.UnboundArguments | out-string)`n"})=========================================================================`n"
            [System.IO.File]::AppendAllText($thisApp.Config.Log_file, "[$([datetime]::Now)] [ERROR] $text" + ([Environment]::NewLine),[System.Text.Encoding]::Unicode)
          }
        }catch{
          $error.clear()
        }  
      }
      #Ok it apparently wasnt something stupid, let the user know and try and restart
      [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
      $oReturn=[System.Windows.Forms.MessageBox]::Show("An exception occurred and the primary Dispatcher thread ended for ($($thisApp.Config.App_Name) Media Player - $($thisApp.Config.App_Version) - PID: $($pid)). Recommend reviewing logs for details.`n`nERROR: $($_ | out-string)`n`nDo you wish to try and restart the app?","CRITICAL ERROR - $($thisApp.Config.App_Name) Media Player",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Error)  
      if($oReturn -eq 'Yes'){
        use-runas -ForceReboot -RestartAsUser
      }
    }
  }else{
    try{
      #----------------------------------------------
      #region Stop Logging
      #----------------------------------------------
      write-ezlogs ">>>> Stopping Write-ezlogs..." -loglevel 2
      Stop-EZlogs -ErrorSummary $error -clearErrors -PrintErrors:$thisApp.Config.Dev_mode -stoptimer -logOnly -logfile $logfile -enablelogs -thisApp $thisApp -globalstopwatch $startup_stopwatch
      #----------------------------------------------
      #endregion Stop Logging
      #----------------------------------------------
      if($thisApp.JobCleanup.Flag){
        $thisApp.JobCleanup.Flag = $false
      }         
    }catch{
      [System.IO.File]::AppendAllText($thisApp.Config.Log_file, "[$([datetime]::Now)] [ERROR] An exception occurred during final cleanup: $($_ | out-string)" + ([Environment]::NewLine),[System.Text.Encoding]::Unicode)
    }finally{
      #While I dont condone suicide powershell, we need to make sure your console/process is closed
      if($pid -and !$NoExit){ 
        Stop-Process $pid -Force
      }
    }
  }
}
#---------------------------------------------- 
#endregion Display Main Window
#----------------------------------------------
#############################################################################
#endregion Execute and Display Output 
#############################################################################