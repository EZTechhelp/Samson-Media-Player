<#
    .Name
    EZT-MediaPlayer

    .Version 
    0.3.1

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

    .NOTES
    Author: EZTechhelp
    Site  : https://www.eztechhelp.com
#> 

#############################################################################
#region Configurable Script Parameters
#############################################################################
$script:startup_stopwatch = [system.diagnostics.stopwatch]::StartNew()
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName WindowsFormsIntegration
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
#using namespace System
#using namespace System.Globalization
#using namespace System.Windows.Data
#using namespace System.Windows.Markup;

#---------------------------------------------- 
#region Log Variables
#----------------------------------------------
$logdateformat = 'MM/dd/yyyy h:mm:ss tt' # sets the date/time appearance format for log file and console messages
$enablelogs = 1 # enables creating a log file of executed actions, run history and errors. 1 = Enable, 0 (or anything else) = Disable
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
$Required_Remote_Modules = 'BurntToast','Microsoft.PowerShell.SecretManagement','Microsoft.PowerShell.SecretStore','pode' #these modules are automatically installed and imported if not already
$Required_modules = 'Write-EZLogs',
'Start-RunSpace',
'Import-Media',
'Get-HelperFunctions',
'Get-LocalMedia',
'Start-Media',
'Get-Spotify',
'Play-SpotifyMedia',
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
'Add-EQPreset' #these modules are automatically installed and imported if not already
$update_modules = $false # enables checking for and updating all required modules for this script. Potentially adds a few seconds to total runtime but ensures all modules are the latest
$force_modules = $false # enables installing and importing of a module even if it is already. Should not be used unless troubleshooting module issues 

$enable_Marquee = $false #enables display of Marquee text over video player
$hide_Console = $false
$Visible_Fields = @( #Allowed fields/columns to be displayed in Media Browser tables
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
  'Play'
  'Select'
) 
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
#---------------------------------------------- 
#region Load-Modules Function
#----------------------------------------------
function Load-Modules {
  
  param
  (
    $modules,

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
  if($local_import){
    
    foreach($m in $modules){
      if([System.IO.File]::exists("$PSScriptRoot\Modules\$m\$m.psm1")){$module_path = "$PSScriptRoot\Modules\$m\$m.psm1"}
      elseif([System.IO.File]::exists("$($PSScriptRoot | Split-Path -parent)\Modules\$m\$m.psm1"))
      {$module_path = "$($PSScriptRoot | Split-Path -parent)\Modules\$m\$m.psm1"}elseif( [System.IO.File]::exists(".\Modules\$m\$m.psm1")){$module_path = ".\Modules\$m\$m.psm1"}else{"[$(Get-Date -format $logdateformat)] [Load-Module ERROR] Unable to find module $m -- PSScriptRoot: $PSScriptRoot" | Out-File -FilePath $logfile -Encoding unicode -Append}
      try{
        $module_root_path = Split-Path $module_path -Parent
        
        $null = $Script_Modules.Add($module_path)
        if($PSVersionTable.psversion.Major -gt 5){#import-module $module_path -Force
        }        
        if($ExistingPaths -notcontains $module_root_path) {$Env:PSModulePath = $module_root_path + ';' + $Env:PSModulePath}
        if($m -eq 'Spotishell'){Import-Module $module_path #-Force
        }
        $PSModuleAutoLoadingPreference = 'All'
        
        #Import-Module $module_path -Verbose -force -Scope Global
      }
      catch{
        "[$(Get-Date -format $logdateformat)] [Load-Module ERROR] An exception occurred importing module $m $($_ | Out-String)" | Out-File -FilePath $logfile -Encoding unicode -Append
        exit
      }      
    }
    return $Script_Modules
  }else{
    $PackageXML = Get-ChildItem "$env:ProgramFiles\WindowsPowershell\Modules\PackageManagement\*\*" -Filter 'PSGetModuleInfo.xml' -Recurse -force | select -Last 1
    if($PackageXML -and ([System.IO.File]::Exists($PackageXML.FullName))){
      $nugetxml = Import-Clixml $PackageXML.FullName
      $PackageProvider = $nugetxml.PackageManagementProvider
    }
    if($PackageProvider -eq 'NuGet') {
      if($enablelogs){Write-Verbose -Message "[$(Get-Date -format $logdateformat)] | Required PackageProvider Nuget is installed."
      "[$(Get-Date -format $logdateformat)] | Required PackageProvider Nuget is installed." | Out-File -FilePath $logfile -Encoding unicode -Append -Force}
    }
    else{
      try{  
        if($hash.Window){
          $hash.Window.Dispatcher.invoke([action]{
              $hash.More_Info_Msg.Visibility = 'Visible'
              $hash.More_info_Msg.text = 'Installing and Registering Package Provider Nuget'
          },'Normal')
        }
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
        Register-PackageSource -Name nuget.org -Location https://www.nuget.org/api/v2 -ProviderName NuGet -Trusted -Force
      }
      catch{"[$(Get-Date -format $logdateformat)] [Load-Module ERROR] An exception occurred Installing and Registering Package Provider Nuget $($_ | Out-String)" | Out-File -FilePath $logfile -Encoding unicode -Append}
    }
    #Install latest version of PowerShellGet
    if(Get-Module 'PowershellGet' | Where-Object {$_.Version -lt '2.2.5'})
    {
      if($hash.Window.Dispatcher){
        $hash.Window.Dispatcher.invoke([action]{
            $hash.More_Info_Msg.Visibility = 'Visible'
            $hash.More_info_Msg.text = 'Installing Module PowershellGet v2.2.5'
        },'Normal')  
      }
      Write-Verbose -Message "[$(Get-Date -format $logdateformat)] | PowershellGet version too low, updating to 2.2.5"
      if($enablelogs){"[$(Get-Date -format $logdateformat)] | PowershellGet version too low, updating to 2.2.5" | Out-File -FilePath $logfile -Encoding unicode -Append -Force}
      Install-Module -Name 'PowershellGet' -MinimumVersion '2.2.5' -Force     
    }  
    $module_list = New-Object System.Collections.ArrayList
    foreach ($m in $modules){  
      if(Get-Module | Where-Object {$_.Name -eq $m}){
        if($enablelogs){Write-Verbose -Message "[$(Get-Date -format $logdateformat)] | Required Module $m is imported."
        "[$(Get-Date -format $logdateformat)] | Required Module $m is imported." | Out-File -FilePath $logfile -Encoding unicode -Append -Force}
        if($force){
          Write-Verbose -Message "[$(Get-Date -format $logdateformat)] | Force parameter applied - Installing $m"
          if($enablelogs){"[$(Get-Date -format $logdateformat)] | Force parameter applied - Installing $m" | Out-File -FilePath $logfile -Encoding unicode -Append -Force}
          Install-Module -Name $m -Scope AllUsers -Force -Verbose 
        }
      }
      else {
        #If module is not imported, but available on disk set module autoloading when needed/called 
        foreach($path in $Env:PSModulePath -split ';'){
          if( [System.IO.Directory]::Exists($path)){
            $null = $module_list.add($([System.IO.Directory]::GetDirectories($path)))
            #$module_list += Get-ChildItem $path #using get-childitem against PSModulePath is much faster thant using Get-Module -ListAvailable. Potential downside is it doesnt verify module is valid only that it exists
          }
        }      
        if($module_list -match $m){       
          $PSModuleAutoLoadingPreference = 'ModuleQualified'
          if($PSVersionTable.PSVersion.Major -gt 5){
            if($enablelogs){Write-Verbose -Message "[$(Get-Date -format $logdateformat)] | Required Module $m is available on disk."
            "[$(Get-Date -format $logdateformat)] | Required Module $m is available on disk." | Out-File -FilePath $logfile -Encoding unicode -Append -Force}
            #Write-Host -Object "[$(Get-date -format $logdateformat)] | Importing Module $m";if($enablelogs){"[$(Get-date -format $logdateformat)] | Importing Module $m" | Out-File -FilePath $logfile -Encoding unicode -Append -Force}
            #Import-module $m
          }else{
            if($enablelogs){Write-Verbose -Message "[$(Get-Date -format $logdateformat)] | Required Module $m is available on disk."
            "[$(Get-Date -format $logdateformat)] | Required Module $m is available on disk." | Out-File -FilePath $logfile -Encoding unicode -Append -Force}
          }
          if($update){
            Write-Verbose -Message "[$(Get-Date -format $logdateformat)] | Updating module: $m"
            if($enablelogs){"[$(Get-Date -format $logdateformat)] | Updating module: $m" | Out-File -FilePath $logfile -Encoding unicode -Append -Force}
            Update-Module -Name $m -Force -ErrorAction Continue
          }
          if($force){
            Write-Verbose -Message "[$(Get-Date -format $logdateformat)] | Force parameter applied - Importing $m"
            if($enablelogs){"[$(Get-Date -format $logdateformat)] | Force parameter applied - Importing $m" | Out-File -FilePath $logfile -Encoding unicode -Append -Force}
            Import-Module $m -Verbose -force -Scope Global
          }
        }
        else {
          #If module is not imported, not available on disk, but is in online gallery then install and import
          if (Find-Module -Name $m | Where-Object {$_.Name -eq $m}) {
            if($hash.Window.Dispatcher){
              $hash.Window.Dispatcher.invoke([action]{
                  $hash.More_Info_Msg.Visibility = 'Visible'
                  $hash.More_info_Msg.text = "Installing Module $m"
              },'Normal')  
            }      
            try{
              Install-Module -Name $m -Force -Verbose -AllowClobber -Scope CurrentUser
              Import-Module $m -Verbose -force -Scope Global
            }
            catch{"[$(Get-Date -format $logdateformat)] [Load-Module ERROR] An exception occurred Installing module $m $($_ | Out-String)" | Out-File -FilePath $logfile -Encoding unicode -Append}      
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
}
#---------------------------------------------- 
#endregion Load-Modules Function
#----------------------------------------------

#---------------------------------------------- 
#region Use Run-As Function
#----------------------------------------------
function Use-RunAs 
{    
  # Check if script is running as Adminstrator and if not use RunAs 
  # Use Check Switch to check if admin 
  # http://gallery.technet.microsoft.com/scriptcenter/63fd1c0d-da57-4fb4-9645-ea52fc4f1dfb
    
  param([Switch]$Check) 
  $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator') 
  if ($Check) { return $IsAdmin }     
  if ($MyInvocation.ScriptName -ne '') 
  {  
    if (-not $IsAdmin)  
    {  
      try 
      {  
        $arg = "-file `"$($MyInvocation.ScriptName)`"" 
        Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction 'stop'  
      } 
      catch 
      { 
        Write-Warning 'Error - Failed to restart script with runas'  
        break               
      } 
      exit # Quit this session of powershell 
    }  
  }  
  else  
  {  
    Write-EZLogs 'Script must be saved as a .ps1 file first' -showtime -LogFile $logfile -LinesAfter 1 -Warning  
    break  
  }  
}
#---------------------------------------------- 
#endregion Use Run-As Function
#----------------------------------------------
#---------------------------------------------- 
#region Show/Hide Console Functions
#----------------------------------------------
# .Net methods for hiding/showing the console in the background
Add-Type -Name Window -Namespace Console -MemberDefinition '
  [DllImport("Kernel32.dll")]
  public static extern IntPtr GetConsoleWindow();

  [DllImport("user32.dll")]
  public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
'
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
    [string]$Current_folder
  )
  
  $Main_Window_XML = "$($Current_folder)\\views\\MainWindow.xaml"  
  [xml]$xaml = [System.IO.File]::ReadAllText($Main_Window_XML).replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml")
  $synchash = [hashtable]::Synchronized(@{})
  $reader = (New-Object System.Xml.XmlNodeReader $xaml) 
  $synchash.Window = [Windows.Markup.XamlReader]::Load($reader)

  [xml]$xaml = $xaml
  $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | foreach {$synchash."$($_.Name)" = $synchash.window.FindName($_.Name)}
  #Web Browser
  [xml]$XamlWebWindow = [System.IO.File]::ReadAllText("$($Current_folder)\\Views\\WebBrowser.xaml").replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml")
  $Childreader     = (New-Object System.Xml.XmlNodeReader $XamlWebWindow)
  $WebBrowserXaml   = [Windows.Markup.XamlReader]::Load($Childreader)  
  $null = $synchash.MainGrid_Top_TabControl.items.add($WebBrowserXaml)
  $XamlWebWindow.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | foreach {   
    if(!$synchash."$($_.Name)"){$synchash."$($_.Name)" = $WebBrowserXaml.FindName($_.Name)}
  }
  [xml]$xaml = $xaml
  $xaml.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | foreach {$synchash."$($_.Name)" = $synchash.window.FindName($_.Name)}
  #Settings
  [xml]$XamlSettings = [System.IO.File]::ReadAllText("$($Current_folder)\\Views\\Settings.xaml").replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml")
  $Childreader     = (New-Object System.Xml.XmlNodeReader $XamlSettings)
  $SettingsXaml   = [Windows.Markup.XamlReader]::Load($Childreader)  
  $null = $synchash.MainGrid_Top_TabControl.items.add($SettingsXaml)
  $XamlSettings.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | foreach {   
    if(!$synchash."$($_.Name)"){$synchash."$($_.Name)" = $SettingsXaml.FindName($_.Name)}
  }  

  #spotify browser
  [xml]$XamlSpotifyBrowser = [System.IO.File]::ReadAllText("$($Current_folder)\\Views\\SpotifyBrowser.xaml").replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml")
  $Childreader     = (New-Object System.Xml.XmlNodeReader $XamlSpotifyBrowser)
  $SpotifyBrowserXaml   = [Windows.Markup.XamlReader]::Load($Childreader)  
  $null = $synchash.MainGrid_Bottom_TabControl.items.add($SpotifyBrowserXaml)
  $XamlSpotifyBrowser.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | foreach {   
    if(!$synchash."$($_.Name)"){$synchash."$($_.Name)" = $SpotifyBrowserXaml.FindName($_.Name)}
  }  
  
  #youtube browser
  [xml]$XamlyoutubeBrowser = [System.IO.File]::ReadAllText("$($Current_folder)\\Views\\YoutubeBrowser.xaml").replace('Views/Styles.xaml',"$($Current_folder)`\Views`\Styles.xaml")
  $Childreader     = (New-Object System.Xml.XmlNodeReader $XamlyoutubeBrowser)
  $YoutubeBrowserXaml   = [Windows.Markup.XamlReader]::Load($Childreader)  
  $null = $synchash.MainGrid_Bottom_TabControl.items.add($YoutubeBrowserXaml)
  $XamlyoutubeBrowser.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | foreach {   
    if(!$synchash."$($_.Name)"){$synchash."$($_.Name)" = $YoutubeBrowserXaml.FindName($_.Name)}
  }      
  return $synchash
}
#---------------------------------------------- 
#endregion Process XAML
#----------------------------------------------


#############################################################################
#endregion Core Functions
#############################################################################

#############################################################################
#region Form Button Logic
#############################################################################
#---------------------------------------------- 
#region Script Onload Events
#----------------------------------------------
 
try
{  
  if($hide_Console){Hide-Console}
  $Script_Modules = Load-Modules -modules $Required_modules -force:$force_modules -update:$update_modules -local_import:$true -logfile "$env:temp\\EZT-MediaPlayer.log"  
  if($startup_perf_timer){Write-Output " | Seconds to local Load-Modules: $($startup_stopwatch.Elapsed.TotalSeconds)" }
  $thisapp = [hashtable]::Synchronized(@{})
  $thisScript = Get-ThisScriptInfo -ScriptPath $PSCommandPath
  $logfile_directory = "$logfile_directory\$($thisScript.Name)\Logs"
  if(!([System.IO.File]::Exists("$logfile_directory\\$($thisScript.Name)-$($thisScript.version).log"))){
    $FreshStart = $true
    $force_modules = $true
  }
  else{
    $FreshStart = $false
    $force_modules = $false
  }    
  if($startup_perf_timer){Write-Output " | Seconds to Get-thisscriptinfo: $($startup_stopwatch.Elapsed.TotalSeconds)" }
  $script:Current_Folder = $($thisScript.path | Split-Path -Parent)
  $Global:logfile = Start-EZLogs -logfile_directory $logfile_directory -ScriptPath $PSCommandPath -thisScript $thisScript
  if($startup_perf_timer){write-ezlogs " | Seconds to Start-ezlogs: $($startup_stopwatch.Elapsed.TotalSeconds)" -showtime}
  if(!$hash.window.IsVisible){Start-SplashScreen -SplashTitle $thisScript.Name -SplashMessage 'Starting Up...' -thisScript $thisScript -current_folder $Current_folder -startup -log_file $logfile -Script_modules $Script_Modules -Verboselog:$verboselogs}else{
    $hash.Window.Dispatcher.invoke([action]{$hash.LoadingLabel.Content = 'Starting Up...'},'Normal')
  }
    
  $Remote_load_module_msg = Load-Modules -modules $Required_Remote_Modules -force:$force_modules -update:$update_modules -local_import:$false -logfile $logfile -Verboselog:$verboselogs -enablelogs:$verboselogs   
  if($startup_perf_timer){write-ezlogs " | Seconds to Remote Load-Modules: $($startup_stopwatch.Elapsed.TotalSeconds)" -showtime}
  $synchash = Initialize-XAML -Current_folder $Current_folder
  if($startup_perf_timer){write-ezlogs " | Seconds to  Initialize-Xaml: $($startup_stopwatch.Elapsed.TotalSeconds)" -showtime}
  $synchash.Window.Title = "$($thisScript.Name) - Version: $($thisScript.Version)"
  $synchash.leftwindow_button.tooltip = "$($thisScript.Name) - Version: $($thisScript.Version)"
  $synchash.window.TaskbarItemInfo.Description = "$($thisScript.Name) - Version: $($thisScript.Version)"
  $synchash.Window.ShowTitleBar = $true
  $synchash.Window.UseNoneWindowStyle = $false
  $synchash.Window.IgnoreTaskbarOnMaximize = $false
  $synchash.Window.WindowState = 'Normal'  
  $synchash.Title_bar_Image.Source = "$($Current_folder)\\Resources\\MusicPlayerFilltest.ico"
  $synchash.Title_bar_Image.width = '18'  
  $synchash.Title_bar_Image.Height = '18'
  $synchash.Window.icon = "$($Current_folder)\\Resources\\MusicPlayerFilltest.ico"
}
catch
{
  write-ezlogs '[ERROR] An exception occured during script initialization' -showtime -catcherror $_
  exit
}
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
  $thisapp.config.Media_Profile_Directory = "$($thisScript.TempFolder)\\MediaProfiles"
  $thisapp.config.image_Cache_path = "$($thisScript.TempFolder)\\Images"
  $thisapp.config.Playlist_Profile_Directory = "$($thisScript.TempFolder)\\PlaylistProfiles"
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
Add-Member -InputObject $thisapp.config -Name 'SpotifyBrowser_Paging' -Value 50 -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'YoutubeBrowser_Paging' -Value 50 -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'MediaBrowser_Paging' -Value 50 -MemberType NoteProperty -Force
$thisapp.config.App_Version = $($thisScript.Version)
Add-Member -InputObject $thisapp.config -Name 'logfile_directory' -Value $logfile_directory -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'Spicetify' -Value '' -MemberType NoteProperty -Force
$Media_Profile_Directory = $thisapp.config.Media_Profile_Directory
try{$thisapp.config | Export-Clixml -Path $App_Settings_File_Path -Force -Encoding UTF8}catch{write-ezlogs "An exception occurred when saving config file to path $App_Settings_File_Path" -showtime -catcherror $_}

if(([System.IO.Directory]::Exists($thisapp.config.Media_Profile_Directory)) -and $FreshStart){
  write-ezlogs " | Clearing profile cache ($($thisapp.config.Media_Profile_Directory))for first time run" -showtime -enablelogs -color cyan
  $null = Remove-Item $thisapp.config.Media_Profile_Directory -Force -Recurse
} 

if(![System.IO.Directory]::Exists($Media_Profile_Directory) -or $FreshStart){
  #close-splashscreen
  #$hash.window.Dispatcher.Invoke("Normal",[action]{ $hash.window.WindowState = 'minimized' }) 
  if([System.IO.File]::Exists("$env:localappdata\spotishell\EZT-MediaPlayer.json")){
    try{
      write-ezlogs ">>>> Removing existing Spotify application json at $env:localappdata\spotishell\EZT-MediaPlayer.json" -showtime -color cyan
      $null = Remove-Item "$env:localappdata\spotishell\EZT-MediaPlayer.json" -Force
    }catch{write-ezlogs "An exception occurred attempting to remove $env:localappdata\spotishell\EZT-MediaPlayer.json" -showtime -catcherror $_}
  }
  if([System.IO.Directory]::Exists("$($thisScript.TempFolder)\Webview2")){   
    try{
      write-ezlogs ">>>> Removing existing Spotify application json at $($thisScript.TempFolder)\Webview2" -showtime -color cyan
      $null = Remove-Item "$($thisScript.TempFolder)\Webview2" -Force -Recurse
    }catch{write-ezlogs "An exception occurred attempting to remove $env:localappdata\spotishell\EZT-MediaPlayer.json" -showtime -catcherror $_}
  }
  #Webview2
  $WebView2_Install_Check = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}").pv
  if(-not [string]::IsNullOrEmpty($WebView2_Install_Check)){
    write-ezlogs "[FIRST-RUN] Webview2 is installed with version $WebView2_Install_Check" -showtime
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
    $WebView2_PostInstall_Check = (Get-ItemProperty "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}").pv
    if(-not [string]::IsNullOrEmpty( $WebView2_PostInstall_Check)){
      write-ezlogs "[FIRST-RUN] [SUCCESS] Webview2 Runtime installed succesfully!" -showtime
    }else{
      write-ezlogs "[WARNING] Unable to verify if Webview2 installed successfully. Features that use Webview2 (webbrowsers and others) may not work correctly" -showtime -warning
    }
  }    
  $hash.window.Dispatcher.Invoke('Normal',[action]{ $hash.window.hide() }) 
  #close-splashscreen
  try{
    Show-FirstRun -PageTitle "$($thisScript.name) - First Run Setup" -PageHeader 'First Run Setup' -Logo "$($thisapp.Config.Current_Folder)\\Resources\\MusicPlayerFilltest.ico" -thisScript $thisScript -thisApp $thisapp -Verboselog $thisapp.config.Verbose_Logging -First_Run
  }catch{
    write-ezlogs 'An exception occurred executing Show-firstrun' -showtime -catcherror $_
    exit
  }
  $null = New-Item $thisapp.config.Media_Profile_Directory -ItemType Directory -Force
  #Start-SplashScreen -SplashTitle $thisScript.Name -SplashMessage "Starting Up..." -thisScript $thisScript -current_folder $Current_Folder -startup -log_file $logfile -Script_modules $Script_Modules 
  #$hash.window.Dispatcher.Invoke("Normal",[action]{ $hash.window.WindowState = 'Normal' }) 
  $hash.window.Dispatcher.Invoke('Normal',[action]{ $hash.window.show() })
  #Start-SplashScreen -SplashTitle $thisScript.Name -SplashMessage 'Starting Up...' -thisScript $thisScript -current_folder $Current_folder -startup -log_file $logfile -Script_modules $Script_Modules -Verboselog:$verboselogs
}
try{
  $confirm_requirements_msg = confirm-requirements -required_appnames $required_appnames -FirstRun -Verboselog:$thisapp.Config.Verbose_logging -thisApp $thisapp -logfile $logfile
  if($startup_perf_timer){write-ezlogs " | Seconds to confirm-requirements: $($startup_stopwatch.Elapsed.TotalSeconds)" -showtime}
  $youtubedl_path = "$($thisapp.config.Current_folder)\\Resources\\Youtube-dl" 
  $env:Path += ";$youtubedl_path"
  #$load_module_msg = Load-Modules -modules $Required_modules -force:$force_modules -update:$update_modules
  #TODO: TEST
  #$null = Invoke-FileDownload -DownloadURL "https://go.microsoft.com/fwlink/p/?LinkId=2124703" -Destination_File_Path "C:\Test\webview2.exe"
  #$null = Start-Process "C:\Test\webview2.exe" -WindowStyle Hidden
  #TODO: This is no longer needed probably since we are not running under admin context by default anymore
  <#      foreach ($reg in $regkeyproperty)
      {
      if(-not (Test-RegistryValue -Path $regpath -Value $reg))
      {
      #if path does exist, create it with desired value
      write-output " | Reg Value does not exist, creating..."
      New-ItemProperty -Path $regpath -Name $reg -Value $regkeypropertyvalue -PropertyType $regkeypropertyvaluetype -Force
      write-output " | Reg property and value created"
      }      
      #$null = Set-SingleRegEntry -regpath $regpath -regkeyproperty $reg -regkeypropertyvalue $regkeypropertyvalue -regkeypropertyvaluetype $regkeypropertyvaluetype
  }#>
}catch{write-ezlogs 'An exception occurred in script_onload_scripblock' -showtime -catcherror $_}
<#$script_onload_scriptblock = ({

    })
    $Variable_list = Get-Variable | where {$_.Options -notmatch 'ReadOnly' -and $_.Options -notmatch 'Constant'}
    Start-Runspace -scriptblock $script_onload_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -Load_Modules -Script_Modules $Script_Modules -runspace_name 'Script_onload_Runspace'
#>
if(!([System.IO.Directory]::Exists($thisapp.config.Playlist_Profile_Directory))){
  write-ezlogs ' | Creating Playlist Profile Directory' -showtime -enablelogs -color cyan
  $null = New-Item $thisapp.config.Playlist_Profile_Directory -ItemType Directory -Force
}
$Media_directories = $thisapp.config.Media_Directories
$Youtube_playlists = $thisapp.Config.Youtube_Playlists

[System.Windows.RoutedEventHandler]$PlayMedia_Command = {
  param($sender)
  $Media = $_.OriginalSource.DataContext
  if(!$Media.url){$Media = $sender.tag}
  if(!$Media.url){$Media = $sender.tag.Media} 
  if($Media.Spotify_Path){Play-SpotifyMedia -Media $Media -thisApp $thisapp -synchash $synchash -Script_Modules $Script_Modules -Show_notification -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -PlaySpotify_Media_Command $PlaySpotify_Media_Command}else{Start-Media -Media $Media -thisApp $thisapp -synchash $synchash -Show_notification -Script_Modules $Script_Modules -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists}   
}
$synchash.PlayMedia_Command = $PlayMedia_Command
[System.Windows.RoutedEventHandler]$PlaySpotify_Media_Command = {
  param($sender)
  $Media = $_.OriginalSource.DataContext
  if($Media.Spotify_Path){$Media = $synchash.SpotifyTable.items | where {$_.id -eq $Media.id} | select -Unique}   
  Play-SpotifyMedia -Media $Media -thisApp $thisapp -synchash $synchash -Script_Modules $Script_Modules -Show_notification -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -PlaySpotify_Media_Command $PlaySpotify_Media_Command
  Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command
}
$synchash.PlaySpotify_Media_Command = $PlaySpotify_Media_Command

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

$hash.Window.Dispatcher.invoke([action]{$hash.LoadingLabel.Content = 'Importing Local Media'},'Normal')

#region Import-Media----------------------------------------------
if($thisapp.Config.Import_Local_Media){
  $synchash.MediaTable.add_AutoGeneratedColumns({
      $columns = ($args[0]).columns
      foreach($column in $columns){
        if($Visible_Fields -notcontains $column.header){$column.visibility = 'hidden'}
      }     
  }) 
  $Global:Datatable = [hashtable]::Synchronized(@{})
  [System.Windows.RoutedEventHandler]$LocalMedia_Btnnext_Scriptblock = {
    try{
      if($thisapp.Config.Verbose_logging){
        write-ezlogs "Current view group: $($synchash.LocalMedia_CurrentView_Group)"  
        write-ezlogs "Total view group: $($synchash.LocalMedia_TotalView_Groups)"
      }   
      if($synchash.LocalMedia_CurrentView_Group -eq $synchash.LocalMedia_TotalView_Groups){if($thisapp.Config.Verbose_logging){write-ezlogs "Last page of $($synchash.LocalMedia_TotalView_Groups) reached" -showtime -warning}}else{
        $itemsource = ($synchash.LocalMedia_View_Groups.GetEnumerator() | select * | where {$_.Name -gt $synchash.LocalMedia_CurrentView_Group -and $_.Name -le $synchash.LocalMedia_TotalView_Groups} | select -Last 1).value | Sort-Object -Property {$_.Artist},{[int]$_.Track}
        $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)           
        if($synchash.LocalMedia_GroupName){
          $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
          $groupdescription.PropertyName = $synchash.LocalMedia_GroupName
          $view.GroupDescriptions.Clear()
          $null = $view.GroupDescriptions.Add($groupdescription)
          if($Sub_GroupName){
            $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
            $sub_groupdescription.PropertyName = $Sub_GroupName
            $null = $view.GroupDescriptions.Add($sub_groupdescription)
          }
        }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}                  
        $synchash.MediaTable.ItemsSource = $view
        $synchash.LocalMedia_CurrentView_Group = ($synchash.LocalMedia_View_Groups.GetEnumerator() | select * | where {$_.Name -gt $synchash.LocalMedia_CurrentView_Group -and $_.Name -le $synchash.LocalMedia_TotalView_Groups} | select -last 1).Name
        $synchash.LocalMedia_lblpageInformation.content = "$($($synchash.LocalMedia_CurrentView_Group)) of $($synchash.LocalMedia_TotalView_Groups)"    
        $synchash.Media_Table_Total_Media.content = "$(@($synchash.MediaTable.ItemsSource).count) of $(@(($synchash.LocalMedia_View_Groups | select *).value).count) | Total $(@($Datatable.datatable).count)"      
      }   
      if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.LocalMedia_CurrentView_Group)"}
    }catch{write-ezlogs 'An exception occurred in LocalMedia-BtnPrev click event' -showtime -catcherror $_}      
  }
  [System.Windows.RoutedEventHandler]$LocalMedia_cbNumberOfRecords_Scriptblock = {
    try{
      if($thisapp.Config.Verbose_logging){
        write-ezlogs "Current view group: $($synchash.LocalMedia_CurrentView_Group)"  
        write-ezlogs "Total view group: $($synchash.LocalMedia_TotalView_Groups)"
      }          
      if($synchash.LocalMedia_cbNumberOfRecords.SelectedIndex -ne -1){
        $selecteditem = ($synchash.LocalMedia_cbNumberOfRecords.Selecteditem -replace 'Page ').trim()
        if($thisapp.Config.Verbose_logging){write-ezlogs "Selected item $($selecteditem)"}
        if($synchash.LocalMedia_cbNumberOfRecords.Selecteditem -ne $synchash.LocalMedia_CurrentView_Group){
          $itemsource = ($synchash.LocalMedia_View_Groups.GetEnumerator() | select * | where {$_.Name -eq $selecteditem} | select -Last 1).value | Sort-Object -Property {$_.Artist},{[int]$_.Track}
          $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)              
          if($synchash.LocalMedia_GroupName -and $view){
            $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
            $groupdescription.PropertyName = $synchash.LocalMedia_GroupName
            $view.GroupDescriptions.Clear()
            $null = $view.GroupDescriptions.Add($groupdescription)
            if($Sub_GroupName){
              $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $sub_groupdescription.PropertyName = $Sub_GroupName
              $null = $view.GroupDescriptions.Add($sub_groupdescription)
            }
          }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}                    
          $synchash.MediaTable.ItemsSource = $view
          $synchash.LocalMedia_CurrentView_Group = ($synchash.LocalMedia_View_Groups.GetEnumerator() | select * | where {$_.Name -eq $selecteditem} | select -last 1).Name
          $synchash.LocalMedia_lblpageInformation.content = "$($($synchash.LocalMedia_CurrentView_Group)) of $($synchash.LocalMedia_TotalView_Groups)"
          $synchash.Media_Table_Total_Media.content = "$(@($synchash.MediaTable.ItemsSource).count) of $(@(($synchash.LocalMedia_View_Groups | select *).value).count) | Total $(@($Datatable.datatable).count)"
          if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.LocalMedia_CurrentView_Group)"}
        }
      }          
    }catch{write-ezlogs 'An exception occurred in LocalMedia_cbNumberOfRecords selectionchanged event' -showtime -catcherror $_}   
  }     
  [System.Windows.RoutedEventHandler]$LocalMedia_btnPrev_Scriptblock = {
    try{
      if($thisapp.Config.Verbose_logging){
        write-ezlogs "Current view group: $($synchash.LocalMedia_CurrentView_Group)"  
        write-ezlogs "Total view group: $($synchash.LocalMedia_TotalView_Groups)"
      }   
      if($synchash.LocalMedia_CurrentView_Group -le 1){if($thisapp.Config.Verbose_logging){write-ezlogs "Last page of $($synchash.LocalMedia_TotalView_Groups) reached" -showtime -warning}}else{
        $itemsource = ($synchash.LocalMedia_View_Groups.GetEnumerator() | select * | where {$_.Name -lt $synchash.LocalMedia_CurrentView_Group -and $_.Name -ge 0} | select -Last 1).value | Sort-Object -Property {$_.Artist},{[int]$_.Track}
        $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)          
        if($synchash.LocalMedia_GroupName){
          $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
          $groupdescription.PropertyName = $synchash.LocalMedia_GroupName
          $view.GroupDescriptions.Clear()
          $null = $view.GroupDescriptions.Add($groupdescription)
          if($Sub_GroupName){
            $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
            $sub_groupdescription.PropertyName = $Sub_GroupName
            $null = $view.GroupDescriptions.Add($sub_groupdescription)
          }
        }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}                   
        $synchash.MediaTable.ItemsSource = $view
        $synchash.LocalMedia_CurrentView_Group = ($synchash.LocalMedia_View_Groups.GetEnumerator() | select * | where {$_.Name -lt $synchash.LocalMedia_CurrentView_Group -and $_.Name -ge 0} | select -last 1).Name
        $synchash.LocalMedia_lblpageInformation.content = "$($($synchash.LocalMedia_CurrentView_Group)) of $($synchash.LocalMedia_TotalView_Groups)"  
        $synchash.Media_Table_Total_Media.content = "$(@($synchash.MediaTable.ItemsSource).count) of $(@(($synchash.LocalMedia_View_Groups | select *).value).count) | Total $(@($Datatable.datatable).count)"       
      }   
      if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.LocalMedia_CurrentView_Group)"}
    }catch{write-ezlogs 'An exception occurred in LocalMedia-BtnNext click event' -showtime -catcherror $_}    
  }  
  Import-Media -Media_directories $Media_directories -use_runspace -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $Media_Profile_Directory -PlayMedia_Command $PlayMedia_Command -startup -thisApp $thisapp -LocalMedia_Btnnext_Scriptblock $LocalMedia_Btnnext_Scriptblock -LocalMedia_cbNumberOfRecords_Scriptblock $LocalMedia_cbNumberOfRecords_Scriptblock -LocalMedia_btnPrev_Scriptblock $LocalMedia_btnPrev_Scriptblock 
  $synchash.FilterTextBox.Add_TextChanged({
      try{
        $InputText = $synchash.FilterTextBox.Text
        $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView((($synchash.LocalMedia_FilterView_Groups.GetEnumerator() | select *).Value | Sort-Object -Property {$_.Artist},{[int]$_.Track}))
        if($view.CanFilter){
          $view.Filter = {
            param ($item) 
            $output = $($item.Title) -match $("$($InputText)") -or $($item.Artist) -match $("$($InputText)")
            $output        
          }
        }else{$view.CustomFilter = "Title LIKE '$InputText%' OR Artist like '%$InputText%'"}
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
            #$mostEmpty = (($groupSizes.GetEnumerator() | Sort-Object -Property "Name") | Select-Object -First 1).name
            if($groupMembers.$mostEmpty -notcontains $item){
              $null = $groupMembers.$mostEmpty.Add($item)
              $groupSizes.$mostEmpty += @($item).count
            }
          }     
          $synchash.LocalMedia_View_Groups = $groupMembers.GetEnumerator() | select *
          $synchash.LocalMedia_TotalView_Groups = @($groupMembers.GetEnumerator() | select *).count
          $synchash.LocalMedia_CurrentView_Group = ($groupMembers.GetEnumerator() | select * | select -last 1).Name 
          if(@($view).count -gt 1){
            $itemsource = ($groupMembers.GetEnumerator() | select * | select -last 1).Value | Sort-Object -Property {$_.Artist},{[int]$_.Track}
            $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)
          }          
        }else{#$view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($Youtube_Datatable.datatable) 
        }       
        if($view -and $synchash.LocalMedia_GroupName){
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
        $synchash.Media_Table_Total_Media.content = "$(@($synchash.MediaTable.ItemsSource).count) of $(@(($synchash.LocalMedia_View_Groups | select *).value).count) | Total $(@($Datatable.datatable).count)"
        $synchash.LocalMedia_lblpageInformation.content = "$($synchash.LocalMedia_CurrentView_Group) of $($synchash.LocalMedia_TotalView_Groups)"
      }catch{write-ezlogs 'An exception occurred in FilterTextBox' -showtime -catcherror $_}
  })
}else{write-ezlogs 'Importing of Local Media is not enabled' -showtime -Warning}
#endregion Import-Media----------------------------------------------


#region Import-Spotify----------------------------------------------
if($thisapp.Config.Import_Spotify_Media){
  $hash.Window.Dispatcher.invoke([action]{$hash.LoadingLabel.Content = 'Importing Spotify Media'},'Normal')
  $synchash.SpotifyTable.add_AutoGeneratedColumns({
      $columns = ($args[0]).columns
      foreach($column in $columns){
        if($Visible_Fields -notcontains $column.header){$column.visibility = 'hidden'}
      }     
  })
  $Global:Spotify_Datatable = [hashtable]::Synchronized(@{})
  [System.Windows.RoutedEventHandler]$Spotify_Btnnext_Scriptblock = {
    try{
      if($thisapp.Config.Verbose_logging){
        write-ezlogs "Current view group: $($synchash.Spotify_CurrentView_Group)"  
        write-ezlogs "Total view group: $($synchash.Spotify_TotalView_Groups)"
      }   
      if($synchash.Spotify_CurrentView_Group -eq $synchash.Spotify_TotalView_Groups){if($thisapp.Config.Verbose_logging){write-ezlogs "Last page of $($synchash.Spotify_TotalView_Groups) reached" -showtime -warning}}else{
        $itemsource = ($synchash.Spotify_View_Groups.GetEnumerator() | select * | where {$_.Name -gt $synchash.Spotify_CurrentView_Group -and $_.Name -le $synchash.Spotify_TotalView_Groups} | select -Last 1).value | Sort-Object -Property {$_.Playlist},{[int]$_.Track_Number}
        $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)           
        if($synchash.Spotify_GroupName){
          $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
          $groupdescription.PropertyName = $synchash.Spotify_GroupName
          $view.GroupDescriptions.Clear()
          $null = $view.GroupDescriptions.Add($groupdescription)
          if($Sub_GroupName){
            $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
            $sub_groupdescription.PropertyName = $Sub_GroupName
            $null = $view.GroupDescriptions.Add($sub_groupdescription)
          }
        }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}                  
        $synchash.SpotifyTable.ItemsSource = $view
        $synchash.Spotify_CurrentView_Group = ($synchash.Spotify_View_Groups.GetEnumerator() | select * | where {$_.Name -gt $synchash.Spotify_CurrentView_Group -and $_.Name -le $synchash.Spotify_TotalView_Groups} | select -last 1).Name
        $synchash.Spotify_lblpageInformation.content = "$($($synchash.Spotify_CurrentView_Group)) of $($synchash.Spotify_TotalView_Groups)"    
        $synchash.Spotify_Table_Total_Media.content = "$(@($synchash.SpotifyTable.ItemsSource).count) of $(@(($synchash.Spotify_View_Groups | select *).value).count) | Total $(@($Spotify_Datatable.datatable).count)"    
      }   
      if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.Spotify_CurrentView_Group)"}
    }catch{write-ezlogs 'An exception occurred in Spotify-BtnPrev click event' -showtime -catcherror $_}      
  }
  [System.Windows.RoutedEventHandler]$Spotify_cbNumberOfRecords_Scriptblock = {
    try{
      if($thisapp.Config.Verbose_logging){
        write-ezlogs "Current view group: $($synchash.Spotify_CurrentView_Group)"  
        write-ezlogs "Total view group: $($synchash.Spotify_TotalView_Groups)"
      }          
      if($synchash.Spotify_cbNumberOfRecords.SelectedIndex -ne -1){
        $selecteditem = ($synchash.Spotify_cbNumberOfRecords.Selecteditem -replace 'Page ').trim()
        if($thisapp.Config.Verbose_logging){write-ezlogs "Selected item $($selecteditem)"}
        if($synchash.Spotify_cbNumberOfRecords.Selecteditem -ne $synchash.Spotify_CurrentView_Group){
          $itemsource = ($synchash.Spotify_View_Groups.GetEnumerator() | select * | where {$_.Name -eq $selecteditem} | select -Last 1).value | Sort-Object -Property {$_.Playlist},{[int]$_.Track_Number}
          $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)              
          if($synchash.Spotify_GroupName -and $view){
            $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
            $groupdescription.PropertyName = $synchash.Spotify_GroupName
            $view.GroupDescriptions.Clear()
            $null = $view.GroupDescriptions.Add($groupdescription)
            if($Sub_GroupName){
              $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $sub_groupdescription.PropertyName = $Sub_GroupName
              $null = $view.GroupDescriptions.Add($sub_groupdescription)
            }
          }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}                    
          $synchash.SpotifyTable.ItemsSource = $view
          $synchash.Spotify_CurrentView_Group = ($synchash.Spotify_View_Groups.GetEnumerator() | select * | where {$_.Name -eq $selecteditem} | select -last 1).Name
          $synchash.Spotify_lblpageInformation.content = "$($($synchash.Spotify_CurrentView_Group)) of $($synchash.Spotify_TotalView_Groups)"
          $synchash.Spotify_Table_Total_Media.content = "$(@($synchash.SpotifyTable.ItemsSource).count) of $(@(($synchash.Spotify_View_Groups | select *).value).count) | Total $(@($Spotify_Datatable.datatable).count)"
          if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.Spotify_CurrentView_Group)"}
        }
      }          
    }catch{write-ezlogs 'An exception occurred in Spotify_cbNumberOfRecords selectionchanged event' -showtime -catcherror $_}   
  }     
  [System.Windows.RoutedEventHandler]$Spotify_btnPrev_Scriptblock = {
    try{
      if($thisapp.Config.Verbose_logging){
        write-ezlogs "Current view group: $($synchash.Spotify_CurrentView_Group)"  
        write-ezlogs "Total view group: $($synchash.Spotify_TotalView_Groups)"
      }   
      if($synchash.Spotify_CurrentView_Group -le 1){if($thisapp.Config.Verbose_logging){write-ezlogs "Last page of $($synchash.Spotify_TotalView_Groups) reached" -showtime -warning}}else{
        $itemsource = ($synchash.Spotify_View_Groups.GetEnumerator() | select * | where {$_.Name -lt $synchash.Spotify_CurrentView_Group -and $_.Name -ge 0} | select -Last 1).value | Sort-Object -Property {$_.Playlist},{[int]$_.Track_Number}
        $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)          
        if($synchash.Spotify_GroupName){
          $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
          $groupdescription.PropertyName = $synchash.Spotify_GroupName
          $view.GroupDescriptions.Clear()
          $null = $view.GroupDescriptions.Add($groupdescription)
          if($Sub_GroupName){
            $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
            $sub_groupdescription.PropertyName = $Sub_GroupName
            $null = $view.GroupDescriptions.Add($sub_groupdescription)
          }
        }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}                   
        $synchash.SpotifyTable.ItemsSource = $view
        $synchash.Spotify_CurrentView_Group = ($synchash.Spotify_View_Groups.GetEnumerator() | select * | where {$_.Name -lt $synchash.Spotify_CurrentView_Group -and $_.Name -ge 0} | select -last 1).Name
        $synchash.Spotify_lblpageInformation.content = "$($($synchash.Spotify_CurrentView_Group)) of $($synchash.Spotify_TotalView_Groups)"     
        $synchash.Spotify_Table_Total_Media.content = "$(@($synchash.SpotifyTable.ItemsSource).count) of $(@(($synchash.Spotify_View_Groups | select *).value).count) | Total $(@($Spotify_Datatable.datatable).count)"  
      }   
      if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.Spotify_CurrentView_Group)"}
    }catch{write-ezlogs 'An exception occurred in Spotify-BtnNext click event' -showtime -catcherror $_}    
  }
  $import_Spotify_scriptblock = ({
      try{
        Import-Spotify -Media_directories $Media_directories -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $Media_Profile_Directory -PlayMedia_Command $PlaySpotify_Media_Command -startup -thisApp $thisapp -use_runspace -Spotify_Btnnext_Scriptblock $Spotify_Btnnext_Scriptblock -Spotify_btnPrev_Scriptblock $Spotify_btnPrev_Scriptblock -Spotify_cbNumberOfRecords_Scriptblock $Spotify_cbNumberOfRecords_Scriptblock
      }catch{
        write-ezlogs 'An exception occurred in import_Spotify_scriptblock' -showtime -catcherror $_
      }
  })
  $Variable_list = Get-Variable | where {$_.Options -notmatch 'ReadOnly' -and $_.Options -notmatch 'Constant'}
  Start-Runspace -scriptblock $import_Spotify_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -Load_Modules -Script_Modules $Script_Modules -runspace_name 'import_Spotify_scriptblock'  
  
  $synchash.SpotifyFilterTextBox.Add_TextChanged({
      try{
        $InputText = $synchash.SpotifyFilterTextBox.Text             
        $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView((($synchash.Spotify_FilterView_Groups.GetEnumerator() | select *).Value | Sort-Object -Property {$_.Playlist},{[int]$_.Track_Number}))
        if($view.CanFilter){
          $view.Filter = {
            param ($item) 
            $output = $($item.Title) -match $("$($InputText)") -or $($item.Track_name) -match $("$($InputText)") -or $($item.Artist_Name) -match $("$($InputText)")
            $output        
          }
        }else{$view.CustomFilter = "Title LIKE '$InputText%' OR Track_name like '%$InputText%' OR Artist_Name like '%$InputText%'"}
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
            #$mostEmpty = (($groupSizes.GetEnumerator() | Sort-Object -Property "Name") | Select-Object -First 1).name
            if($groupMembers.$mostEmpty -notcontains $item){
              $null = $groupMembers.$mostEmpty.Add($item)
              $groupSizes.$mostEmpty += @($item).count
            }
          }     
          $synchash.Spotify_View_Groups = $groupMembers.GetEnumerator() | select *
          $synchash.Spotify_TotalView_Groups = @($groupMembers.GetEnumerator() | select *).count
          $synchash.Spotify_CurrentView_Group = ($groupMembers.GetEnumerator() | select * | select -last 1).Name            
          if(@($view).count -gt 1){
            $itemsource = ($groupMembers.GetEnumerator() | select * | select -last 1).Value | Sort-Object -Property {$_.Playlist},{[int]$_.Track_Number}
            $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)
          }              
        }else{#$view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($Youtube_Datatable.datatable) 
        }       
        if($view -and $synchash.Spotify_GroupName){
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
        $synchash.Spotify_Table_Total_Media.content = "$(@($synchash.SpotifyTable.ItemsSource).count) of $(@(($synchash.Spotify_View_Groups | select *).value).count) | Total $(@($Spotify_Datatable.datatable).count)"
        $synchash.Spotify_lblpageInformation.content = "$($synchash.Spotify_CurrentView_Group) of $($synchash.Spotify_TotalView_Groups)"
      }catch{write-ezlogs 'An exception occurred in SpotifyFilterTextbox' -showtime -catcherror $_}
  })
}else{write-ezlogs 'Importing of Spotify Media is not enabled' -showtime -Warning}

#endregion Import-Spotify----------------------------------------------

#region Import-Youtube----------------------------------------------
if($thisapp.Config.Import_Youtube_Media){
  $hash.Window.Dispatcher.invoke([action]{$hash.LoadingLabel.Content = 'Importing Youtube Media'},'Normal')


  $synchash.YoutubeTable.add_AutoGeneratedColumns({
      try{
        $columns = ($args[0]).columns
        foreach($column in $columns){
          if($Visible_Fields -notcontains $column.header){$column.visibility = 'hidden'}
        }
      }catch{write-ezlogs 'An exception occurred in autogeneratedcolumns event for YoutubeTable' -showtime -catcherror $_}   
  })
  $Global:Youtube_Datatable = [hashtable]::Synchronized(@{})
  [System.Windows.RoutedEventHandler]$Youtube_Btnnext_Scriptblock = {
    try{
      if($thisapp.Config.Verbose_logging){
        write-ezlogs "Current view group: $($synchash.Youtube_CurrentView_Group)"  
        write-ezlogs "Total view group: $($synchash.Youtube_TotalView_Groups)"
      }   
      if($synchash.Youtube_CurrentView_Group -eq $synchash.Youtube_TotalView_Groups){if($thisapp.Config.Verbose_logging){write-ezlogs "Last page of $($synchash.Youtube_TotalView_Groups) reached" -showtime -warning}}else{
        $itemsource = ($synchash.Youtube_View_Groups.GetEnumerator() | select * | where {$_.Name -gt $synchash.Youtube_CurrentView_Group -and $_.Name -le $synchash.Youtube_TotalView_Groups} | select -Last 1).value | Sort-Object -Property {$_.Playlist},{$_.Track_Name}
        $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)           
        if($view){
          if($synchash.Youtube_GroupName){
            $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
            $groupdescription.PropertyName = $synchash.Youtube_GroupName
            $view.GroupDescriptions.Clear()
            $null = $view.GroupDescriptions.Add($groupdescription)
            if($Sub_GroupName){
              $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $sub_groupdescription.PropertyName = $Sub_GroupName
              $null = $view.GroupDescriptions.Add($sub_groupdescription)
            }
          }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}       
        }                  
        $synchash.YoutubeTable.ItemsSource = $view
        $synchash.Youtube_CurrentView_Group = ($synchash.Youtube_View_Groups.GetEnumerator() | select * | where {$_.Name -gt $synchash.Youtube_CurrentView_Group -and $_.Name -le $synchash.Youtube_TotalView_Groups} | select -last 1).Name
        $synchash.Youtube_lblpageInformation.content = "$($($synchash.Youtube_CurrentView_Group)) of $($synchash.Youtube_TotalView_Groups)"    
        $synchash.Youtube_Table_Total_Media.content = "$(@($synchash.YoutubeTable.ItemsSource).count) of $(@(($synchash.Youtube_View_Groups | select *).value).count) | Total $(@($Youtube_Datatable.datatable).count)"      
      }   
      if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.Youtube_CurrentView_Group)"}
    }catch{write-ezlogs 'An exception occurred in Youtube-BtnPrev click event' -showtime -catcherror $_}      
  }
  [System.Windows.RoutedEventHandler]$Youtube_cbNumberOfRecords_Scriptblock = {
    try{
      if($thisapp.Config.Verbose_logging){
        write-ezlogs "Current view group: $($synchash.Youtube_CurrentView_Group)"  
        write-ezlogs "Total view group: $($synchash.Youtube_TotalView_Groups)"
      }          
      if($synchash.Youtube_cbNumberOfRecords.SelectedIndex -ne -1){
        $selecteditem = ($synchash.Youtube_cbNumberOfRecords.Selecteditem -replace 'Page ').trim()
        if($thisapp.Config.Verbose_logging){write-ezlogs "Selected item $($selecteditem)"}
        if($synchash.Youtube_cbNumberOfRecords.Selecteditem -ne $synchash.Youtube_CurrentView_Group){
          $itemsource = ($synchash.Youtube_View_Groups.GetEnumerator() | select * | where {$_.Name -eq $selecteditem} | select -Last 1).value | Sort-Object -Property {$_.Playlist},{$_.Track_Name}
          $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource)   
          if($view){
            if($synchash.Youtube_GroupName){
              $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $groupdescription.PropertyName = $synchash.Youtube_GroupName
              $view.GroupDescriptions.Clear()
              $null = $view.GroupDescriptions.Add($groupdescription)
              if($Sub_GroupName){
                $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
                $sub_groupdescription.PropertyName = $Sub_GroupName
                $null = $view.GroupDescriptions.Add($sub_groupdescription)
              }
            }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}       
          }                                        
          $synchash.YoutubeTable.ItemsSource = $view
          $synchash.Youtube_CurrentView_Group = ($synchash.Youtube_View_Groups.GetEnumerator() | select * | where {$_.Name -eq $selecteditem} | select -last 1).Name
          $synchash.Youtube_lblpageInformation.content = "$($($synchash.Youtube_CurrentView_Group)) of $($synchash.Youtube_TotalView_Groups)"
          $synchash.Youtube_Table_Total_Media.content = "$(@($synchash.YoutubeTable.ItemsSource).count) of $(@(($synchash.Youtube_View_Groups | select *).value).count) | Total $(@($Youtube_Datatable.datatable).count)"
          if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.Youtube_CurrentView_Group)"}
        }
      }          
    }catch{write-ezlogs 'An exception occurred in Youtube_cbNumberOfRecords selectionchanged event' -showtime -catcherror $_}   
  }     
  [System.Windows.RoutedEventHandler]$Youtube_btnPrev_Scriptblock = {
    try{
      if($thisapp.Config.Verbose_logging){
        write-ezlogs "Current view group: $($synchash.Youtube_CurrentView_Group)"  
        write-ezlogs "Total view group: $($synchash.Youtube_TotalView_Groups)"
      }   
      if($synchash.Youtube_CurrentView_Group -le 1){if($thisapp.Config.Verbose_logging){write-ezlogs "Last page of $($synchash.Youtube_TotalView_Groups) reached" -showtime -warning}}else{
        $itemsource = ($synchash.Youtube_View_Groups.GetEnumerator() | select * | where {$_.Name -lt $synchash.Youtube_CurrentView_Group -and $_.Name -ge 0} | select -Last 1).value | Sort-Object -Property {$_.Playlist},{$_.Track_Name}
        $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($itemsource) 
        if($view){
          if($synchash.Youtube_GroupName){
            $groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
            $groupdescription.PropertyName = $synchash.Youtube_GroupName
            $view.GroupDescriptions.Clear()
            $null = $view.GroupDescriptions.Add($groupdescription)
            if($Sub_GroupName){
              $sub_groupdescription = New-Object  System.Windows.Data.PropertyGroupDescription
              $sub_groupdescription.PropertyName = $Sub_GroupName
              $null = $view.GroupDescriptions.Add($sub_groupdescription)
            }
          }elseif($view.GroupDescriptions){$view.GroupDescriptions.Clear()}       
        }                   
        $synchash.YoutubeTable.ItemsSource = $view
        $synchash.Youtube_CurrentView_Group = ($synchash.Youtube_View_Groups.GetEnumerator() | select * | where {$_.Name -lt $synchash.Youtube_CurrentView_Group -and $_.Name -ge 0} | select -last 1).Name
        $synchash.Youtube_lblpageInformation.content = "$($($synchash.Youtube_CurrentView_Group)) of $($synchash.Youtube_TotalView_Groups)"        
        $synchash.Youtube_Table_Total_Media.content = "$(@($synchash.YoutubeTable.ItemsSource).count) of $(@(($synchash.Youtube_View_Groups | select *).value).count) | Total $(@($Youtube_Datatable.datatable).count)" 
      }   
      if($thisapp.Config.Verbose_logging){write-ezlogs "Current view group after: $($synchash.Youtube_CurrentView_Group)"}
    }catch{write-ezlogs 'An exception occurred in Youtube-BtnNext click event' -showtime -catcherror $_}    
  }
  <#  $synchash.import_youtube_timer = new-object System.Windows.Threading.DispatcherTimer
      $synchash.import_youtube_timer.Add_Tick({
      try{                                                     
      if($synchash.Youtube_View -and $synchash){
      if($synchash.Youtube_GroupName){
      $groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
      $groupdescription.PropertyName = $synchash.Youtube_GroupName
      $synchash.Youtube_View.GroupDescriptions.Clear()
      $null = $synchash.Youtube_View.GroupDescriptions.Add($groupdescription)
      if($Sub_GroupName){
      $sub_groupdescription = New-object  System.Windows.Data.PropertyGroupDescription
      $sub_groupdescription.PropertyName = $Sub_GroupName
      $null = $synchash.Youtube_View.GroupDescriptions.Add($sub_groupdescription)
      }
      }elseif($synchash.Youtube_View.GroupDescriptions){
      $synchash.Youtube_View.GroupDescriptions.Clear()
      }  
      $syncHash.YoutubeTable.ItemsSource = $synchash.Youtube_View
      $synchash.Youtube_lblpageInformation.content = "$($synchash.Youtube_CurrentView_Group) of $($synchash.Youtube_TotalView_Groups)" 
      $synchash.Youtube_Table_Total_Media.content = "$(@($syncHash.YoutubeTable.ItemsSource).count) of Total | $(@(($synchash.Youtube_View_Groups.GetEnumerator() | select *).value).count)"
      }else{
      write-ezlogs "Something went wrong View: $($synchash.Youtube_View) -- synchash $($synchash)" -showtime -warning
      }
      if($thisApp.Config.YoutubeBrowser_Paging -ne $Null){
      1..($synchash.Youtube_TotalView_Groups) | foreach{
      if($synchash.Youtube_cbNumberOfRecords.items -notcontains "Page $_" -and $_ -gt 0){
      $null = $synchash.Youtube_cbNumberOfRecords.items.add("Page $_")
      }
      }   
      }
      if($startup_perf_timer){write-ezlogs " | Seconds to  Import-Youtube: $($startup_stopwatch.Elapsed.TotalSeconds)" -showtime}                                               
      }catch{
      write-ezlogs "An exception occurred executing import_youtube_timer" -showtime -catcherror $_
      $this.Stop()
      }
      $this.Stop()     
  }.GetNewClosure())#> 
  $synchash.Youtube_Progress_Ring.isActive = $true
  $import_Youtube_scriptblock = ({
      try{Import-Youtube -Youtube_playlists $Youtube_playlists -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $Media_Profile_Directory -PlayMedia_Command $PlayMedia_Command -startup -thisApp $thisapp -use_runspace -Youtube_Btnnext_Scriptblock $Youtube_Btnnext_Scriptblock -Youtube_btnPrev_Scriptblock $Youtube_btnPrev_Scriptblock -Youtube_cbNumberOfRecords_Scriptblock $Youtube_cbNumberOfRecords_Scriptblock}catch{write-ezlogs 'An exception occurred in import_Youtube_scriptblock' -showtime -catcherror $_}
  }.GetNewClosure())
  $Variable_list = Get-Variable | where {$_.Options -notmatch 'ReadOnly' -and $_.Options -notmatch 'Constant'}
  Start-Runspace -scriptblock $import_Youtube_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -Load_Modules -Script_Modules $Script_Modules -runspace_name 'import_Youtube_scriptblock' 
  $synchash.YoutubeFilterTextBox.Add_TextChanged({
      try{
        $InputText = $synchash.YoutubeFilterTextBox.Text              
        $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView((($synchash.Youtube_FilterView_Groups.GetEnumerator() | select *).Value | Sort-Object -Property {$_.Playlist},{$_.Track_Name}))
        if($view.CanFilter){
          $view.Filter = {
            param ($item) 
            $output = $($item.Title) -like $("*$($InputText)*") -or $($item.Track_name) -like $("*$($InputText)*") -or $($item.Live_Status) -match $("$($InputText)")
            $output
          }
        }else{$view.CustomFilter = "Title LIKE '%$InputText%' OR Track_name like '%$InputText%' OR Artist_Name like '%$InputText%'"}
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
          if($view -and $synchash.Youtube_GroupName){         
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
        $synchash.Youtube_Table_Total_Media.content = "$(@($synchash.YoutubeTable.ItemsSource).count) of $(@(($synchash.Youtube_View_Groups | select *).value).count) | Total $(@($Youtube_Datatable.datatable).count)"
        $synchash.Youtube_lblpageInformation.content = "$($synchash.Youtube_CurrentView_Group) of $($synchash.Youtube_TotalView_Groups)" 
      }catch{write-ezlogs 'An exception occurred in YoutubeFilterTextBox' -showtime -catcherror $_}
  })
}else{write-ezlogs 'Importing of Youtube Media is not enabled' -showtime -Warning}
#endregion Import-Youtube----------------------------------------------

#region Routed Event Handlers----------------------------------------------
$all_playlists = [hashtable]::Synchronized(@{})
$all_playlists.playlists = New-Object -TypeName 'System.Collections.ArrayList'

$synchash.MediaTable.tag = @{        
  synchash = $synchash;
  thisScript = $thisScript;
  thisApp = $thisapp
  PlayMedia_Command = $PlayMedia_Command
  PlaySpotify_Media_Command = $PlaySpotify_Media_Command
}
$synchash.SpotifyTable.tag = $synchash.MediaTable.tag
$synchash.YoutubeTable.tag = $synchash.MediaTable.tag

[System.Windows.RoutedEventHandler]$Add_to_PlaylistCommand = {
  param($sender)
  $synchash = $sender.tag.synchash
  $thisapp = $sender.tag.thisapp
  $thisScript = $sender.tag.thisScript 
  $Playlist = $sender.header
  $PlayMedia_Command = $synchash.PlayMedia_Command
  #write-ezlogs "Source: $($args.Source.Name | out-string)" 
  #write-ezlogs "Source2: $($args.OriginalSource | out-string)" 
  if($sender.tag.source.Name -eq 'YoutubeTable'){$Selected_Media = $synchash.YoutubeTable.selecteditems}elseif($sender.tag.source.Name -eq 'SpotifyTable'){$Selected_Media = $synchash.SpotifyTable.selecteditems}elseif($sender.tag.source.Name -eq 'MediaTable'){$Selected_Media = $synchash.MediaTable.selecteditems}else{$Selected_Media = $sender.tag.Media}          
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
      if($sender.tag.source.Name -eq 'Play_Queue'){$playlist_items = ($synchash.PlayQueue_TreeView.Items | where {$_.Header -eq $sender.tag.datacontext}).items.tag.media}else{$playlist_items = ($synchash.Playlists_TreeView.Items | where {$_.Header -eq $sender.tag.datacontext}).items.tag.media}
      if(!$playlist_items){
        $playlist_items = $sender.tag.datacontext.items
        $Playlist_source = $sender.tag.datacontext.items.playlist | select -First 1
      }else{$Playlist_source = $sender.tag.datacontext}
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
      if($start_media.Spotify_path){Play-SpotifyMedia -Media $start_media -thisApp $thisapp -synchash $synchash -Script_Modules $Script_Modules -Show_notification -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -PlaySpotify_Media_Command $PlaySpotify_Media_Command}else{Start-Media -media $start_media -thisApp $thisapp -synchash $synchash -Show_notification -Script_Modules $Script_Modules -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists}
      return                   
    }elseif($Playlist -eq 'Add Playlist to Play Queue'){
      $playlist_items = ($synchash.Playlists_TreeView.Items | where {$_.Header -eq $sender.tag.datacontext}).items.tag.media
      if(!$playlist_items){
        $playlist_items = $sender.tag.datacontext.items
        $Playlist_source = $sender.tag.datacontext.items.playlist | select -First 1
      }else{$Playlist_source = $sender.tag.datacontext}
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
      write-ezlogs " | Adding $($Selected_Media.encodedtitle) to Play Queue" -showtime
      Add-Playlist -Media $Selected_Media -Playlist $Playlist -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging
    }else{write-ezlogs 'Selected media was null! Unable to do anything!' -showtime -warning} 
    $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
    Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -startup -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command
  }catch{write-ezlogs "An exception occurred adding $($Media.title | Out-String) to Playlist $($Playlist)" -showtime -catcherror $_}
} 
[System.Windows.RoutedEventHandler]$Add_to_New_PlaylistCommand = {
  param($sender)
  $synchash = $sender.tag.synchash
  $thisapp = $sender.tag.thisapp
  $thisScript = $sender.tag.thisScript 
  $Playlist = $sender.header
  $PlayMedia_Command = $synchash.PlayMedia_Command   
  $Media = $sender.tag.Media 
  $all_playlists = $sender.tag.all_playlists
  write-ezlogs 'Prompting for new playlist name...' -showtime
  try{
    $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($synchash.Window,'Add New Playlist','Enter the name of the new playlist',$Button_Settings)
    if(-not [string]::IsNullOrEmpty($result)){
      if($Playlist -eq 'Create Playlist from Queue'){
        write-ezlogs "Creating new playlist $result from Play Queue " -showtime -warning  
        $Current_playlist_items = $synchash.PlayQueue_TreeView.Items.items.tag.media  
        write-ezlogs "Playlist items $($Current_playlist_items | Out-String)" -showtime    
        Add-Playlist -Media $Current_playlist_items -Playlist $result -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging
        $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
        Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists
      }elseif($Playlist -eq 'Save as New Playlist'){
        write-ezlogs "Creating new playlist $result from $($sender.tag.datacontext.name | Out-String) " -showtime -warning  
        $playlist_items = $sender.tag.datacontext.items    
        Add-Playlist -Media $playlist_items -Playlist $result -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging
        $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
        Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists
      }elseif($Playlist -eq 'Add all Selected to New Playlist'){ 
        if($sender.tag.source.Name -eq 'YoutubeTable'){$playlist_items = $synchash.YoutubeTable.selecteditems}elseif($sender.tag.source.Name -eq 'SpotifyTable'){$playlist_items = $synchash.SpotifyTable.selecteditems}elseif($sender.tag.source.Name -eq 'MediaTable'){$playlist_items = $synchash.MediaTable.selecteditems}           
        #write-ezlogs "Playlist items: $($playlist_items| out-string) " -showtime
        Add-Playlist -Media $playlist_items -Playlist $result -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging
        $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
        Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists
      }else{          
        Add-Playlist -Media $Media -Playlist $result -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging
        Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists    
      }    
    }else{write-ezlogs 'No valid playlist name was provided' -showtime -warning}
  }catch{write-ezlogs "An exception occurred adding $($Media.title | Out-String) to new Playlist $($Playlist)" -showtime -catcherror $_}
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
    $all_playlists.playlists = Import-Clixml "$($thisapp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml" 
    write-ezlogs "Prompting for to confirm playlist deletion for $Playlist..." -showtime    
    $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
    $Button_Settings.AffirmativeButtonText = 'Yes'
    $Button_Settings.NegativeButtonText = 'No'  
    $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
    $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Delete Playlist $Playlist","Are you sure you wish to remove the $Playlist Playlist? This will not remove the media items in the playlist",$okandCancel,$Button_Settings)
    if($result -eq 'Affirmative'){
      $playlist_to_remove = $all_playlists.playlists | where {$_.name -eq $Playlist}
      #write-ezlogs "Playlist Name: $($playlist_to_remove.name)" -showtime
      $playlist_to_remove_path = $playlist_to_remove.Playlist_Path
      if([System.IO.File]::Exists($playlist_to_remove_path)){
        write-ezlogs "Removing playlist path $($playlist_to_remove_path)" -showtime -warning
        $null = [System.IO.File]::Delete($playlist_to_remove_path)
        write-ezlogs "Removing playlist $Playlist" -showtime -warning
        #write-ezlogs "Playlist to remove $($playlist_to_remove | out-string)" -showtime -warning
        #$Null = [System.Collections.ArrayList]$all_playlists.playlists.remove($playlist_to_remove)
        Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists         
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
  $all_playlists = $sender.tag.all_playlists
  $Playlist = $sender.header
  try{
    $playlist_to_modify = $all_playlists.playlists | where {$_.name -eq $Playlist}
    if($Playlist -eq 'Play Queue'){ 
      if($Media.Spotify_Path){
        $Spotify = $true
        <#        if($thisApp.config.Current_Spotify_Playlist -contains $Media.encodedtitle){
            write-ezlogs " | Removing $($Media.encodedtitle) from Play Queue" -showtime
            $null = $thisApp.config.Current_Spotify_Playlist.Remove($Media.encodedtitle)
        }#>
        if($thisapp.config.Current_Playlist.values -contains $Media.encodedtitle){
          write-ezlogs " | Removing $($Media.encodedtitle) from Play Queue" -showtime
          $index_toremove = $thisapp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.encodedtitle} | select * -ExpandProperty key
          foreach($index in $index_toremove){$null = $thisapp.config.Current_Playlist.Remove($index)}            
        }      
      }elseif($thisapp.config.Current_Playlist.values -contains $Media.id){
        $Spotify = $false
        write-ezlogs " | Removing $($Media.id) from Play Queue" -showtime
        $index_toremove = $thisapp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.id} | select * -ExpandProperty key
        foreach($index in $index_toremove){$null = $thisapp.config.Current_Playlist.Remove($index)}                         
      }
    }elseif($playlist_to_modify){
      try{
        $Track_To_Remove = $playlist_to_modify.Playlist_tracks | where {$_.id -eq $Media.id}
        if($Track_To_Remove){
          write-ezlogs " | Removing $($Track_To_Remove.id) from Playlist $($Playlist)" -showtime
          $null = $playlist_to_modify.Playlist_tracks.Remove($Track_To_Remove)
          $playlist_to_modify | Export-Clixml $playlist_to_modify.Playlist_Path -Force
        }
      }catch{write-ezlogs "An exception occurred removing $($Media.id) from Playlist $($Playlist)" -showtime -catcherror $_}    
    } 
    $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8  
    Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists
  }catch{write-ezlogs "An exception occurred removing $($Media.id) from Playlist $($Playlist)" -showtime -catcherror $_}
}   
[System.Windows.RoutedEventHandler]$OpenWeb_Command  = {
  param($sender)
  $Media = $_.OriginalSource.DataContext
  #write-ezlogs "Media $($Media | out-string)"
  if(!$Media.url){$Media = $sender.tag}
  if(!$Media.url){$Media = $sender.tag.Media}  
  if($Media.Source -eq 'YoutubePlaylist_item'){
    if(Test-URL $Media.url){
      if($Media.url -match 'youtube.com' -or $Media.url -match 'youtu.be'){
        $youtube_id = $($Media.url).split('v=')[2].trim() 
        $url = "https://yewtu.be/watch?v=$youtube_id"
      }else{$url = $Media.url}
      write-ezlogs "Opening URL $($url)" -showtime
      start $url
    }else{write-ezlogs "URL $($url) is invalid!" -showtime -warning}
  }   
} 

[System.Windows.RoutedEventHandler]$OpenFolder_Command  = {
  param($sender)
  $Media = $_.OriginalSource.DataContext
  #write-ezlogs "Media $($Media | out-string)"
  if(!$Media.url){$Media = $sender.tag}
  if(!$Media.url){$Media = $sender.tag.Media} 
  $path = [regex]::Unescape($Media.directory)
   
  if([System.IO.Directory]::Exists($path)){
    write-ezlogs "Opening Direcotry path $($path)" -showtime
    start $path
  }else{write-ezlogs "Directory Path $($path) is invalid!" -showtime -warning}   
} 

[System.Windows.RoutedEventHandler]$Clear_Playlist  = {
  param($sender)
  $Media = $_.OriginalSource.DataContext
  write-ezlogs '>>>> Clearing Current Play Queue' -showtime -color cyan
  try{$thisapp.config.Current_Playlist.Clear()}catch{write-ezlogs 'An exception occurred clearing the play queue' -showtime -warning}    
  $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
  Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists
}

[System.Windows.RoutedEventHandler]$Remove_MediaCommand  = {
  param($sender)
  $Media_info = $_.OriginalSource.DataContext
  if(!$Media_info.url){$Media_info = $sender.tag}
  if(!$Media_info.url){$Media_info = $sender.tag.Media}  
  if($sender.tag.source.Name -eq 'YoutubeTable'){$playlist_items = $synchash.YoutubeTable.selecteditems}elseif($sender.tag.source.Name -eq 'SpotifyTable'){$playlist_items = $synchash.SpotifyTable.selecteditems}elseif($sender.tag.source.Name -eq 'MediaTable'){$playlist_items = $synchash.MediaTable.selecteditems}
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
      foreach($Media in $Selected_Media){
        $Media_id = $Media.id
        write-ezlogs ">>>> Removing Media $($Media.title) - $($Media.id)" -showtime -color cyan
        if($thisapp.config.Current_Playlist.values -contains $Media.id){
          write-ezlogs " | Removing $($Media.id) from Play Queue" -showtime
          $index_toremove = $thisapp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.id} | select * -ExpandProperty key
          $null = $thisapp.config.Current_Playlist.Remove($index_toremove)                  
        }
        $playlist_to_modify = $all_playlists.playlists | where {$_.playlist_tracks.id -eq $Media.id}
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
          $all_playlists.playlists | Export-Clixml "$($thisapp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml" -Force -Encoding UTF8   
        }    
        #$localmedia_toremove = $all_local_media.media | where {$_.id -eq $Media.id}\
        if($Media.Source -eq 'Local'){
          $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-MediaProfile','All-Media-Profile.xml')
          $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($synchash.MediaTable.ItemsSource)       
          $localmedia_toremove = $view | where {$_.id -eq $Media_id}
          if($localmedia_toremove){
            write-ezlogs "Removing $($localmedia_toremove.id) from local media table" -showtime
            $null = $view.Remove($localmedia_toremove)
            $synchash.MediaTable.ItemsSource = $view
          }
          if([System.IO.File]::Exists($AllMedia_Profile_File_Path)){
            write-ezlogs "Updating All media profile cache at $AllMedia_Profile_File_Path" -showtime 
            $all_media_profile = Import-Clixml $AllMedia_Profile_File_Path
            $all_media_profile = $all_media_profile | where {$_.encodedTitle -ne $Media_id}
            write-ezlogs $($all_media_profile | where {$_.encodedTitle -eq $Media_id} | Out-String)
            $all_media_profile | Export-Clixml $AllMedia_Profile_File_Path -Force
          }        
        }      
        if($Media.Spotify_path -or $Media.Source -eq 'SpotifyPlaylist'){
          $Track_ID = $Media.Track_ID
          $AllSpotify_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Spotify_MediaProfile','All-Spotify_Media-Profile.xml')
          if([System.IO.File]::Exists($AllSpotify_Profile_File_Path)){
            write-ezlogs "Updating All Spotify profile cache at $AllSpotify_Profile_File_Path" -showtime 
            $all_Spotify_profile = Import-Clixml $AllSpotify_Profile_File_Path
            #$Spotify_profile_to_modify = $all_Spotify_profile | where {$_.playlist_tracks.id -eq $Track_ID}
            if($all_Spotify_profile){
              foreach($Playlist in $all_Spotify_profile){
                $tracks_to_remove = $Playlist.playlist_tracks | where {$_.id -eq $Track_ID}
                if($tracks_to_remove){
                  write-ezlogs " | Removing track $($tracks_to_remove | Out-String) from playlist $($Playlist.name)" -showtime
                  $Playlist.playlist_tracks = $Playlist.playlist_tracks  | where {$tracks_to_remove.id -notcontains $_.id}
                }
              }  
              $all_Spotify_profile | Export-Clixml $AllSpotify_Profile_File_Path -Force        
            }       
          }        
          $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($synchash.SpotifyTable.ItemsSource)       
          $spotifymedia_toremove = $view | where {$_.id -eq $Media_id}
          if($spotifymedia_toremove){
            foreach($Media in $spotifymedia_toremove){
              write-ezlogs "Removing $($Media.title) $($Media.Track_ID) from Spotify media table" -showtime
              $null = $view.Remove($Media)
            }
            $synchash.SpotifyTable.ItemsSource = $view
          }                          
        }  
        if($Media.Source -eq 'YoutubePlaylist_item'){
          $AllYoutube_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Youtube_MediaProfile','All-Youtube_Media-Profile.xml')      
          $view = [System.Windows.Data.CollectionViewSource]::GetDefaultView($synchash.YoutubeTable.ItemsSource)       
          $localmedia_toremove = $view | where {$_.id -eq $Media_id}
          if($localmedia_toremove){
            write-ezlogs "Removing $($localmedia_toremove.id) from Youtube media table" -showtime
            $null = $view.Remove($localmedia_toremove)
            $synchash.YoutubeTable.ItemsSource = $view
          }
          if([System.IO.File]::Exists($AllYoutube_Profile_File_Path)){
            write-ezlogs "Updating All Youtube profile cache at $AllYoutube_Profile_File_Path" -showtime 
            $all_youtube_profile = Import-Clixml $AllYoutube_Profile_File_Path
            $all_youtube_profile = $all_youtube_profile | where {$_.Playlist_tracks.encodedTitle -ne $Media_id}
            $all_youtube_profile | Export-Clixml $AllYoutube_Profile_File_Path -Force
          }                  
        }
      }                         
      #$media_toremove = $synchash.SpotifyTable.Items | where {$_.encodedtitle -eq $Media.id}    
      #$media_toremove = $synchash.YoutubeTable.Items | where {$_.encodedtitle -eq $Media.id}     
      $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
      Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists        
    }else{write-ezlogs "User declined to delete media $($Media.title)" -showtime -warning}        
  }catch{write-ezlogs "An exception occurred removing $($Media | Out-String)" -showtime -catcherror $_}    
}


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
      #[xml]$Xamlxcloud_window =  (Get-content "$($Current_Folder)\\Views\\XCloudViewer.xaml" -Force -ReadCount 0).replace('Views/Styles.xaml',"$($Current_Folder)`\Views`\Styles.xaml") 
      $Childreader = (New-Object System.Xml.XmlNodeReader $Xamlfullscreen_window)
      $FullScreen_windowXaml   = [Windows.Markup.XamlReader]::Load($Childreader)  
      $Xamlfullscreen_window.SelectNodes("//*[@*[contains(translate(name(.),'n','N'),'Name')]]") | ForEach-Object {$synchash."$($_.Name)" = $FullScreen_windowXaml.FindName($_.Name)}
      #[Microsoft.Web.WebView2.wpf.WebView2] $webview = New-Object 'Microsoft.Web.WebView2.wpf.WebView2'
      #$new_window.Content = $webview
      #$VideoViewtoCopy = $synchash.VideoView
      $synchash.VLC_Grid.children.Remove($synchash.VideoView)
      $synchash.FullScreen_VLC_Grid.AddChild($synchash.VideoView)
      #$synchash.FullScreenVideoView = $synchash.VideoView
      #$synchash.VLC = $VideoViewtoCopy.MediaPlayer
      #$synchash.VideoView.MediaPlayer = $Null
      #$synchash.FullScreen_Viewer.content = $synchash.VideoView
      #$synchash.VideoView = $null
      
      #$webview.CreationProperties = New-Object 'Microsoft.Web.WebView2.Wpf.CoreWebView2CreationProperties'
      #$webview.CreationProperties.UserDataFolder = $synchash.WebView2.CreationProperties.UserDataFolder
      #$webview.Source = $url  
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
          $MediaPlayertoCopyBack = $synchash.VideoView
          $synchash.FullScreen_VLC_Grid.children.Remove($synchash.VideoView)
          #$videoView = [LibVLCSharp.WPF.VideoView]::new()
          #$VideoView.Name = 'VideoView'
          #$VideoView.MediaPlayer = $synchash.VideoView.MediaPlayer             
          $synchash.VLC_Grid.Children.Add($MediaPlayertoCopyBack)  
          $synchash.VLC = $MediaPlayertoCopyBack.MediaPlayer
          $synchash.VideoView.updatelayout()    
          $synchash.VLC_Grid.updatelayout() 
          $null = $synchash.Remove($this)
      })      
      $synchash.FullScreen_Viewer.Show()   
    }else{$synchash.FullScreen_Viewer.close()}
  }catch{write-ezlogs 'Exception occurred opening new webview2 window for FullScreen View' -showtime -catcherror $_}                            
}.GetNewClosure()

$synchash.update_status_timer = New-Object System.Windows.Threading.DispatcherTimer
$synchash.update_status_timer.Add_Tick({
    try{       
      #write-ezlogs ">>>> Calling function $($((Get-PSCallStack)[0].FunctionName))" -showtime                                      
      Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -PlayMedia_Command $synchash.PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $synchash.PlaySpotify_Media_Command -Import_Playlists_Cache                                     
    }catch{
      write-ezlogs 'An exception occurred executing update_status_timer' -showtime -catcherror $_
      $this.Stop()
    }
    $this.Stop()     
}.GetNewClosure())
[System.Windows.RoutedEventHandler]$CheckTwitch_Command  = {
  param($sender)
  $datacontext = $_.OriginalSource.DataContext
  $synchash = $sender.tag.synchash
  $thisapp = $sender.tag.thisApp
  $Media = $_.OriginalSource.DataContext
  $PlayMedia_Command = $synchash.PlayMedia_Command
  $PlaySpotify_Media_Command = $synchash.PlaySpotify_Media_Command
  $all_playlists = $sender.tag.all_playlists
  if(!$Media.url){$Media = $sender.tag}
  if(!$Media.url){$Media = $sender.tag.Media} 
  if($Media.webpage_url -match 'twitch.tv'){Get-TwitchStatus -Media $Media -thisApp $thisapp -synchash $synchash -all_playlists $all_playlists -verboselog -checkall -Use_runspace}else{write-ezlogs 'No valid Twitch URL was provided' -showtime -warning}
}.GetNewClosure()

[System.Windows.RoutedEventHandler]$Media_ContextMenu = {
  $sender = $args[0]
  [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]  
  $Media = $e.OriginalSource.datacontext

  if(!$Media.url){$Media = $sender.tag.Media} 
  $PlayMedia_Command = $sender.tag.PlayMedia_Command 
  $synchash = $sender.tag.synchash
  $thisapp = $sender.tag.thisapp
  $thisScript = $sender.tag.thisScript  
  $PlaySpotify_Media_Command = $sender.tag.PlaySpotify_Media_Command
  $Media_Tag = @{        
    synchash = $synchash;
    thisScript = $thisScript;
    thisApp = $thisapp
    PlayMedia_Command = $PlayMedia_Command
    PlaySpotify_Media_Command = $PlaySpotify_Media_Command
    Media = $Media
    Datacontext = $e.OriginalSource.datacontext
    all_playlists = $all_playlists
    source = $e.Source
    Media_ContextMenu = $Media_ContextMenu
  }        
 
  $items = New-Object System.Collections.ArrayList 
  #write-ezlogs "Datacontext $($e.Source | out-string)"
  if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Right -and ($Media.ID -or $Media.encodedtitle))
  {            
    if($e.Source.Name -ne 'YoutubeTable' -and $e.Source.Name -ne 'SpotifyTable' -and $e.Source.Name -ne 'MediaTable'){$sender.isSelected = $true}    
    $Play_Media = @{
      'Header' = 'Play'
      'Color' = 'White'
      'Icon_Color' = 'White'
      'Tag' = $Media_Tag
      'Command' = $PlayMedia_Command
      'Icon_kind' = 'Play'
      'Enabled' = $true
      'IsCheckable' = $false
    }
    $null = $items.Add($Play_Media)  
    if($e.Source.Name -eq 'YoutubeTable' -or $Media.type -match 'Youtube'){
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
    $Sub_items = New-Object System.Collections.ArrayList
    $Current_Playlist_Add = @{
      'Header' = 'Play Queue'
      'Tag' = $Media_Tag
      'Command' = $Add_to_PlaylistCommand
      'Enabled' = $true
      'IsCheckable' = $false
      'Icon_kind' = $null
      'Color' = 'White'
    }
    $null = $Sub_items.Add($Current_Playlist_Add)
    $all_playlists.playlists = Import-Clixml "$($thisapp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml"
    foreach ($Playlist in $all_playlists.playlists | where {-not [string]::IsNullOrEmpty($_.name) -and $_.Playlist_tracks.id -notcontains $Media.ID })
    {
      $Playlist_name = $Playlist.name
      $Playlist_tracks = $Playlist.Playlist_tracks
      $Custom_Playlist_Add = @{
        'Header' = $Playlist_name
        'Tag' = $Media_Tag
        'Command' = $Add_to_PlaylistCommand
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
      'Command' = $Add_to_New_PlaylistCommand
      'Enabled' = $true
      'IsCheckable' = $false
      'Icon_Color' = 'LightGreen'
      'Icon_kind' = 'PlaylistPlus'
      'Icon_Margin' = '3,0,0,0'
      'Color' = 'White'
    }
    $null = $Sub_items.Add($Add_New_Playlist)  
    $Add_Selected_New_Playlist = @{
      'Header' = 'Add all Selected to New Playlist'
      'Tag' = $Media_Tag
      'Command' = $Add_to_New_PlaylistCommand
      'Enabled' = $true
      'IsCheckable' = $false
      'Icon_Color' = 'LightGreen'
      'Icon_kind' = 'PlaylistPlus'
      'Icon_Margin' = '3,0,0,0'
      'Color' = 'White'
    }
    $null = $Sub_items.Add($Add_Selected_New_Playlist)         
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
    if($all_playlists.playlists.Playlist_tracks.id -contains $Media.ID){
      foreach ($Playlist in $all_playlists.playlists | where {-not [string]::IsNullOrEmpty($_.name) -and $_.Playlist_tracks.id -contains $Media.ID })
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
  }elseif($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Right -and -not [string]::IsNullOrEmpty($e.OriginalSource.datacontext) -and ($e.OriginalSource.GetType()).Name  -match 'Textblock' -and $e.OriginalSource.datacontext.title -ne 'Play Queue' -and (-not [string]::IsNullOrEmpty($e.OriginalSource.datacontext.title))){
    if($e.Source.Name -ne 'YoutubeTable' -and $e.Source.Name -ne 'SpotifyTable' -and $e.Source.Name -ne 'MediaTable'){$sender.isSelected = $true}
    $Playlist_PlayAll = @{
      'Header' = 'Play All'
      'FontWeight' = 'Bold'
      'Color' = 'White'
      'Icon_Color' = 'White'
      'Tag' = $Media_Tag
      'Command' = $Add_to_PlaylistCommand
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
      'Command' = $Add_to_PlaylistCommand
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
      'Command' = $Add_to_New_PlaylistCommand
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
  }elseif($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Right -and $e.OriginalSource.datacontext.title -eq 'Play Queue'){
    if($e.Source.Name -ne 'YoutubeTable' -and $e.Source.Name -ne 'SpotifyTable' -and $e.Source.Name -ne 'MediaTable'){$sender.isSelected = $true}
    $Playlist_Save = @{
      'Header' = 'Create Playlist from Queue'
      'Color' = 'White'
      'Icon_Color' = 'LightGreen'
      'Tag' = $Media_Tag
      'Command' = $Add_to_New_PlaylistCommand
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
  }elseif($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Right -and ($Media.ID -or $Media.encodedtitle)){}  
  if($items){ 
    $e.OriginalSource.tag = $Media_Tag      
    Add-WPFMenu -control $e.OriginalSource -items $items -AddContextMenu -synchash $synchash
  }          
}    
$synchash.Media_ContextMenu = $Media_ContextMenu
    
Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -startup -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists
if($startup_perf_timer){write-ezlogs " | Seconds to  Get-Playlists: $($startup_stopwatch.Elapsed.TotalSeconds)" -showtime}
$null = $synchash.MediaTable.AddHandler([System.Windows.Controls.Button]::MouseRightButtonDownEvent,$Media_ContextMenu)
$null = $synchash.SpotifyTable.AddHandler([System.Windows.Controls.Button]::MouseRightButtonDownEvent,$Media_ContextMenu)
$null = $synchash.YoutubeTable.AddHandler([System.Windows.Controls.Button]::MouseRightButtonDownEvent,$Media_ContextMenu)

#endregion Routed Event Handlers----------------------------------------------

#---------------------------------------------- 
#region Webview2 Events
#----------------------------------------------
$synchash.Web_Tab.Visibility = 'Visible'
$WebView2Options = [Microsoft.Web.WebView2.Core.CoreWebView2EnvironmentOptions]::new()
$WebView2Options.AdditionalBrowserArguments = 'edge-webview-enable-builtin-background-extensions'
$WebView2Env = [Microsoft.Web.WebView2.Core.CoreWebView2Environment]::CreateAsync(
  [String]::Empty, [IO.Path]::Combine( [String[]]($($thisScript.TempFolder), 'Webview2') ), $WebView2Options
)
$WebView2Env.GetAwaiter().OnCompleted(
  [Action]{$synchash.WebView2.EnsureCoreWebView2Async( $WebView2Env.Result )}
) 
$synchash.WebView2.Add_NavigationCompleted(
  [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs]]{
    #write-ezlogs "Navigation completed: $($synchash.WebView2.source | out-string)" -showtime
    $synchash.WebView2.ExecuteScriptAsync(
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
$synchash.WebView2.Add_CoreWebView2InitializationCompleted(
  [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2InitializationCompletedEventArgs]]{
    #$WebView.CoreWebView2.Settings | gm | out-host
    #$MainForm.Add_Activated([EventHandler]{ If ( 0 -cne $MODE_FULLSCREEN ) { $MainForm.Add_FormClosing($CloseHandler) } })
    #$MainForm.Add_Deactivate([EventHandler]{ $MainForm.Remove_FormClosing($CloseHandler) })
    #& $ProcessNoDevTools

    [Microsoft.Web.WebView2.Core.CoreWebView2Settings]$Settings = $synchash.WebView2.CoreWebView2.Settings
    $Settings.AreDefaultContextMenusEnabled  = $true
    $Settings.AreDefaultScriptDialogsEnabled = $true
    $Settings.AreDevToolsEnabled             = $true
    $Settings.AreHostObjectsAllowed          = $true
    $Settings.IsBuiltInErrorPageEnabled      = $false
    $Settings.IsScriptEnabled                = $true
    $Settings.IsStatusBarEnabled             = $true
    $Settings.IsWebMessageEnabled            = $true
    $Settings.IsZoomControlEnabled           = $false
    $synchash.WebView2.CoreWebView2.Navigate('https://yewtu.be')
  }
)

$synchash.WebView2.Visibility = 'Visible'
  
$synchash.GoToPage.Add_click({
    try{Start-WebNavigation -uri $synchash.txtUrl.text -synchash $synchash -WebView2 $synchash.Webview2}catch{write-ezlogs 'An exception occurred in GoToPage Click event' -showtime -catcherror $_}
    #$syncHash.WebView2.source=$synchash.txtUrl.text
}.GetNewClosure())

$synchash.txturl.Add_KeyDown({
    [System.Windows.Input.KeyEventArgs]$e = $args[1] 
    try{
      if($e.key -eq 'Return'){Start-WebNavigation -uri $synchash.txtUrl.text -synchash $synchash -WebView2 $synchash.Webview2}  
    }catch{write-ezlogs 'An exception occurred in texturl keydown event' -showtime -catcherror $_}    
})

$synchash.Webview2.Add_SourceChanged({        
    try{$synchash.txtUrl.text = $synchash.WebView2.Source}catch{write-ezlogs 'An exception occurred in Webview2 Source changed event' -showtime -catcherror $_} 
}) 

$synchash.BrowseBack.Add_click({
    try{$synchash.WebView2.GoBack()}catch{write-ezlogs 'An exception occurred in BrowseBack Click event' -showtime -catcherror $_}
})
$synchash.BrowseForward.Add_click({$synchash.WebView2.GoForward()})
$synchash.BrowseRefresh.Add_click({$synchash.WebView2.Reload()})  
  
$synchash.WebView2.add_WebMessageReceived({
    $result = $args.WebMessageAsJson | ConvertFrom-Json
    write-ezlogs "Web message received: $($result.value | Out-String)" -showtime
})


#chat_webview2
$chatWebView2Options = [Microsoft.Web.WebView2.Core.CoreWebView2EnvironmentOptions]::new()
$chatWebView2Options.AdditionalBrowserArguments = 'edge-webview-enable-builtin-background-extensions'
$chatWebView2Env = [Microsoft.Web.WebView2.Core.CoreWebView2Environment]::CreateAsync(
  [String]::Empty, [IO.Path]::Combine( [String[]]($($thisScript.TempFolder), $($thisScript.Name), 'Webview2') ), $chatWebView2Options
)
$chatWebView2Env.GetAwaiter().OnCompleted(
  [Action]{$synchash.chat_WebView2.EnsureCoreWebView2Async( $chatWebView2Env.Result )}
) 
$synchash.chat_WebView2.Add_NavigationCompleted(
  [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2NavigationCompletedEventArgs]]{
    #write-ezlogs "Navigation completed: $($synchash.WebView2.source | out-string)" -showtime
    $synchash.chat_WebView2.ExecuteScriptAsync(
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
$synchash.chat_WebView2.Add_CoreWebView2InitializationCompleted(
  [EventHandler[Microsoft.Web.WebView2.Core.CoreWebView2InitializationCompletedEventArgs]]{
    [Microsoft.Web.WebView2.Core.CoreWebView2Settings]$Settings = $synchash.chat_WebView2.CoreWebView2.Settings
    $Settings.AreDefaultContextMenusEnabled  = $true
    $Settings.AreDefaultScriptDialogsEnabled = $false
    $Settings.AreDevToolsEnabled             = $true
    $Settings.AreHostObjectsAllowed          = $true
    $Settings.IsBuiltInErrorPageEnabled      = $false
    $Settings.IsScriptEnabled                = $true
    $Settings.IsStatusBarEnabled             = $false
    $Settings.IsWebMessageEnabled            = $true
    $Settings.IsZoomControlEnabled           = $false
  }
)
$synchash.chat_WebView2.add_WebMessageReceived({
    $result = $args.WebMessageAsJson | ConvertFrom-Json
    #write-ezlogs "chat_WebView2 message received: $($result.value | out-string)" -showtime
})
if($startup_perf_timer){write-ezlogs " | Seconds to Webview2: $($startup_stopwatch.Elapsed.TotalSeconds)" -showtime}
#---------------------------------------------- 
#endregion Webview2 Events
#----------------------------------------------

#---------------------------------------------- 
#endregion Script Onload Events
#----------------------------------------------

#---------------------------------------------- 
#region Manage Sources Button
#----------------------------------------------
$synchash.Add_Media_Button.Add_Click({ 
    $synchash.Window.hide()
    try{
      Show-FirstRun -PageTitle "$($thisScript.name) - Update Media Sources" -PageHeader 'Update Media Sources' -Logo "$($thisapp.Config.Current_Folder)\\Resources\\MusicPlayerFilltest.ico" -thisScript $thisScript -synchash $synchash -thisApp $thisapp -PlayMedia_Command $PlayMedia_Command -PlaySpotify_Media_Command $PlaySpotify_Media_Command -Update -First_Run:$false
      if($hashsetup.Update_Media_Sources){
        Start-SplashScreen -SplashTitle $thisScript.Name -SplashMessage 'Updating Media library...' -thisScript $thisScript -current_folder $Current_folder -log_file $thisapp.Config.Log_file -Script_modules $Script_Modules
        Start-Sleep 1
        if($thisapp.config.Import_Local_Media){
          $hash.Window.Dispatcher.invoke([action]{$hash.LoadingLabel.Content = 'Importing Local Media'},'Normal')         
          Import-Media -Media_directories $thisapp.Config.Media_Directories -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -PlayMedia_Command $PlayMedia_Command -thisApp $thisapp 
        }else{$synchash.MediaTable.ItemsSource = $null}        
        if($thisapp.Config.Import_Spotify_Media){
          $hash.Window.Dispatcher.invoke([action]{$hash.LoadingLabel.Content = 'Importing Spotify Media'},'Normal')        
          Import-Spotify -Media_directories $thisapp.Config.Media_Directories -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -PlayMedia_Command $PlaySpotify_Media_Command -thisApp $thisapp 
        }else{
          $AllSpotify_Media_Profile_Directory_Path = [System.IO.Path]::Combine($Media_Profile_Directory,'All-Spotify_MediaProfile','All-Spotify_Media-Profile.xml')        
          if([System.IO.File]::exists($AllSpotify_Media_Profile_Directory_Path)){$null = Remove-Item $AllSpotify_Media_Profile_Directory_Path -Force}
          $synchash.SpotifyTable.ItemsSource = $null
        }
        if($thisapp.Config.Import_Youtube_Media){
          $hash.Window.Dispatcher.invoke([action]{$hash.LoadingLabel.Content = 'Importing Youtube Media'},'Normal')
          $synchash.Youtube_Progress_Ring.isActive = $true
          Import-Youtube -Youtube_playlists $Youtube_playlists -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $Media_Profile_Directory -PlayMedia_Command $PlayMedia_Command -thisApp $thisapp
          $synchash.Youtube_Progress_Ring.isActive = $false
        }else{
          $AllYoutube_Media_Profile_Directory_Path = [System.IO.Path]::Combine($Media_Profile_Directory,'All-Youtube_MediaProfile','All-Youtube_Media-Profile.xml')        
          if([System.IO.File]::exists($AllYoutube_Media_Profile_Directory_Path)){$null = Remove-Item $AllYoutube_Media_Profile_Directory_Path -Force}
          $synchash.YoutubeTable.ItemsSource = $null
        }        
        close-splashscreen    
      }              
    }catch{
      write-ezlogs 'An exception occurred in Show-FirstRun' -showtime -catcherror $_
      close-splashscreen
      $synchash.Window.Show()
    }
    $synchash.Window.Show()
}.GetNewClosure())

#---------------------------------------------- 
#endregion Manage Sources Button
#----------------------------------------------

#---------------------------------------------- 
#region Add Local Media Button
#----------------------------------------------
$synchash.Add_LocalMedia_Button.Add_Click({ 
    try{  
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()        
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($synchash.Window,'Add Media','Enter/Paste the path of the Media file or Directory you wish to add',$Button_Settings)
      if(-not [string]::IsNullOrEmpty($result) -and ([System.IO.FIle]::Exists($result) -or [System.IO.Directory]::Exists($result))){
        $synchash.Window.hide()
        Start-SplashScreen -SplashTitle $thisScript.Name -SplashMessage 'Updating Media library...' -thisScript $thisScript -current_folder $Current_folder -log_file $thisapp.Config.Log_file -Script_modules $Script_Modules
        Start-Sleep 1        
        write-ezlogs ">>>> Adding Local Media $result" -showtime -color cyan
        Import-Media -Media_Path $result -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $Media_Profile_Directory -PlayMedia_Command $PlayMedia_Command -thisApp $thisapp
        close-splashscreen
        $synchash.Window.Show()        
      }else{write-ezlogs "The provided Path is not valid or was not provided! -- $result" -showtime -warning}                
    }catch{
      write-ezlogs 'An exception occurred in Show-FirstRun' -showtime -catcherror $_
      #close-splashscreen
      #$synchash.Window.Show()
    }
    #$synchash.Window.Show() 
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
        $synchash.Window.hide()
        Start-SplashScreen -SplashTitle $thisScript.Name -SplashMessage 'Updating Media library...' -thisScript $thisScript -current_folder $Current_folder -log_file $thisapp.Config.Log_file -Script_modules $Script_Modules
        Start-Sleep 1        
        write-ezlogs ">>>> Adding Youtube video $result" -showtime -color cyan
        $synchash.Youtube_Progress_Ring.isActive = $true
        Import-Youtube -Youtube_URL $result -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $Media_Profile_Directory -PlayMedia_Command $PlayMedia_Command -thisApp $thisapp
        $synchash.Youtube_Progress_Ring.isActive = $false
        close-splashscreen
        $synchash.Window.Show()        
      }else{write-ezlogs "The provided URL is not valid or was not provided! -- $result" -showtime -warning}                
    }catch{
      write-ezlogs 'An exception occurred in Show-FirstRun' -showtime -catcherror $_
      #close-splashscreen
      #$synchash.Window.Show()
    }
    #$synchash.Window.Show()  
}.GetNewClosure())

#---------------------------------------------- 
#endregion Add Youtube Media Button
#----------------------------------------------

#---------------------------------------------- 
#region Feedback
#----------------------------------------------
$synchash.Submit_Feedback.Add_Click({Show-FeedbackForm -PageTitle 'Submit Feedback/Issues' -Logo $splash_logo -thisScript $thisScript -thisApp $thisapp -Verboselog:$thisapp.Config.Verbose_logging -synchash $synchash})
#---------------------------------------------- 
#endregion Feedback
#----------------------------------------------

#---------------------------------------------- 
#region FullScreen Button
#----------------------------------------------
$null = $synchash.FullScreen_Player_Button.AddHandler([Windows.Controls.Button]::ClickEvent,$FullScreen_Command)
#---------------------------------------------- 
#region FullScreen Button
#----------------------------------------------

#----------------------------------------------
#region Vlc Controls
#----------------------------------------------
$Current_folder = $($thisScript.path | Split-Path -Parent)
try{
  $vlc = [LibVLCSharp.Shared.Core]::Initialize("$Current_folder\Resources\Libvlc")
  #$videoView = [LibVLCSharp.WPF.VideoView]::new()  
  $libvlc_options = '--file-logging',"--logfile=$($logfile_directory)\$($thisScript.Name)-$($thisapp.config.App_Version)-VLC.log",'--log-verbose=3'
  Add-Member -InputObject $thisapp.config -Name 'libvlc_options' -Value $libvlc_options -MemberType NoteProperty -Force
  $libvlc = [LibVLCSharp.Shared.LibVLC]::new('--file-logging',"--logfile=$($logfile_directory)\$($thisScript.Name)-$($thisapp.config.App_Version)-VLC.log",'--log-verbose=3')
  #$libvlc.SetLogFile("$($logfile_directory)\$($thisScript.Name)-$($thisApp.config.App_Version)-VLC.log")
  $synchash.VideoView.MediaPlayer = [LibVLCSharp.Shared.MediaPlayer]::new($libvlc)  
  if($enable_Marquee){
    $synchash.VideoView.MediaPlayer.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Enable, 1) #enable marquee option
    $synchash.VideoView.MediaPlayer.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Size, 32) #set the font size 
    $synchash.VideoView.MediaPlayer.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Position, 8) #set the position of text
    $synchash.VideoView.MediaPlayer.SetMarqueeString([LibVLCSharp.Shared.VideoMarqueeOption]::Text, "EZT-MediaPlayer - $($thisScrip.Version) - Pre-Alpha")
    #to set subtitle or any other text
  }
  $synchash.VLC = $synchash.VideoView.MediaPlayer
  Add-Member -InputObject $thisapp.config -Name 'libvlc' -Value $libvlc -MemberType NoteProperty -Force

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
              }catch{write-ezlogs "An exception occurred changing value in $($synchash."EQ_$($_)") to $($this.Value)" -showtime -catcherror $_}
            }
        }.GetNewClosure())
        if($Configured_Band.Band_Value -ne $null){$synchash."EQ_$($_)".Value = $Configured_Band.Band_Value}else{$synchash."EQ_$($_)".Value = 0}        
      }
      $newRow
    } 
  }
  Add-Member -InputObject $thisapp.config -Name 'EQ_Bands' -Value $eq_bands -MemberType NoteProperty -Force
  if($thisapp.config.Enable_EQ){
    $synchash.Enable_EQ_Toggle.isOn = $true
    if(!$synchash.Equalizer){$synchash.Equalizer = [LibVLCSharp.Shared.Equalizer]::new()}
  }else{$synchash.Enable_EQ_Toggle.isOn  = $false}
  $synchash.Enable_EQ_Toggle.Add_Toggled({
      if($synchash.Enable_EQ_Toggle.isOn -and $synchash.Equalizer -ne $null){
        $null = $synchash.vlc.SetEqualizer($synchash.Equalizer)
        write-ezlogs " | Preamp: $($synchash.Equalizer.preamp)" -showtime
        Add-Member -InputObject $thisapp.config -Name 'Enable_EQ' -Value $true -MemberType NoteProperty -Force
      }else{
        $null = $synchash.vlc.UnsetEqualizer()
        Add-Member -InputObject $thisapp.config -Name 'Enable_EQ' -Value $false -MemberType NoteProperty -Force
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
            if($synchash.EQ_Preset_ComboBox.items -notcontains $preset.Preset_Name){$null = $synchash.EQ_Preset_ComboBox.items.add($preset.Preset_Name)}else{write-ezlogs "An existing preset with name $result already exists -- updated to current values" -showtime -warning}                                 
          }else{write-ezlogs 'Unable to add Preset as no preset profile was returned when adding!' -showtime -warning}          
        }else{write-ezlogs "The provided name is not valid or was not provided! -- $result" -showtime -warning}
      }catch{write-ezlogs 'An exception occurred in Save_CustomEQ_Button click event' -showtime -catcherror $_}
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
      }catch{write-ezlogs "An exception occurred setting the EQ preamp to $($this.value)" -showtime -catcherror $_}
  })

  $synchash.EQ_Timer = New-Object System.Windows.Threading.DispatcherTimer
  $synchash.EQ_Timer.Add_tick({
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
            if($thisapp.Config.EQ_Preamp -ne $null){$synchash.Equalizer.SetPreamp($thisapp.Config.EQ_Preamp)}else{Add-Member -InputObject $thisapp.config -Name 'EQ_Preamp' -Value 0 -MemberType NoteProperty -Force}          
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
      $this.Stop()
  })

  $synchash.EQ_Preset_ComboBox.add_SelectionChanged({$synchash.EQ_Timer.start()})


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
}catch{write-ezlogs 'An exception occurred attempting to load vlc' -showtime -catcherror $_}
$synchash.Window.Add_loaded({$this.clip.Rect = "0,0,$($this.Width),$($this.Height)"})
$synchash.Window.add_SizeChanged({    
    try{
      if($this.WindowState -eq 'Maximized'){
        $PrimaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
        $PrimaryScreen.WorkingArea.Height
        $synchash.Window.clip.Rect = "0,0,$($PrimaryScreen.WorkingArea.Width),$($PrimaryScreen.WorkingArea.Height)"
        Write-ezlogs "Width: $($synchash.Window.clip | Out-String)"
        Write-ezlogs "Width: $($PrimaryScreen | Out-String)"
      }else{$this.clip.Rect = "0,0,$($this.Width),$($this.Height)"}        
    }catch{write-zlogs 'An exception occurred in window sizechanged event' -showtime -catcherror $_}
})
#Window Resize Event
<#$synchash.Window.Add_StateChanged({
    try{     
    if($this.WindowState -eq 'Maximized'){
    $PrimaryScreen = [System.Windows.Forms.Screen]::PrimaryScreen
    $PrimaryScreen.WorkingArea.Height
    $synchash.Window.clip.Rect = "0,0,$($PrimaryScreen.WorkingArea.Width),$($PrimaryScreen.WorkingArea.Height)"
    Write-ezlogs "Width: $($synchash.Window.clip | out-string)"
    Write-ezlogs "Width: $($PrimaryScreen | out-string)"
    }
    }catch{
    write-zlogs "An exception occurred in window sizechanged event" -showtime -catcherror $_
    }      
})#> 
$synchash.Window.add_MouseDown({
    $sender = $args[0]
    [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]
    if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and [System.Windows.Input.MouseButtonState]::Pressed)
    {$this.DragMove()}
})
$synchash.Window_Title_DockPanel.add_MouseDown({
    $sender = $args[0]
    [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]
    if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and [System.Windows.Input.MouseButtonState]::Pressed)
    {$synchash.Window.DragMove()}
})
<#$synchash.Media_URL.add_PreviewMouseDown({
    $sender = $args[0]
    [System.Windows.Input.MouseButtonEventArgs]$e= $args[1]
    if ($e.ChangedButton -eq  [System.Windows.Input.MouseButton]::Left -and [System.Windows.Input.MouseButtonState]::Pressed)
    { 
    $synchash.Window.DragMove()
    }

    })
#>
$synchash.Options_button.add_Click({
    if($synchash.Audio_Flyout.IsOpen){$synchash.Audio_Flyout.IsOpen = $false}else{$synchash.Audio_Flyout.IsOpen = $true}
})

$synchash.MediaPlayer_Slider.Add_ValueChanged({
    if($synchash.MediaPlayer_Slider.IsMouseOver -and $synchash.MediaPlayer_Slider.IsFocused -and $synchash.vlc.IsPlaying -and $([timespan]::FromMilliseconds($synchash.VLC.Time)).TotalSeconds -ne $synchash.MediaPlayer_Slider.Value){
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
      #TODO: This is gross and needs refactoring
      <#      $current_track = (Get-CurrentTrack -ApplicationName $thisApp.config.App_Name)
          if($current_track.is_playing -and $([timespan]::FromMilliseconds($current_track.progress_ms)).TotalSeconds -ne $synchash.MediaPlayer_Slider.Value){
          $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
          Invoke-SeekPositionCurrentTrack -PositionMs ($synchash.MediaPlayer_Slider.Value * 1000) -DeviceId $devices.id -ApplicationName $thisApp.config.App_Name
          #Set-SpotifyPlayer -DeviceId ($devices | where {$_.is_active}).id -Shuffle:$false -Repeat off -TrackPosition ($synchash.MediaPlayer_Slider.Value * 1000)
      }#>
    }
})

$synchash.MediaPlayer_Slider.add_PreviewMouseUp({
    $sender = $args[0]
    [System.Windows.Input.MouseButtonEventArgs]$e = $args[1]
    
    if ($e.ChangedButton -eq [System.Windows.Input.MouseButton]::Left -and $e.ButtonState -eq [System.Windows.Input.MouseButtonState]::Released)
    {    
      write-ezlogs "Slider mouse up event $($thisapp.config.Spicetify | Out-String)"
      $newvalue = $e.Source.value
      if(!$synchash.vlc.IsPlaying){
        if($thisapp.config.Use_Spicetify){
          $current_track = $thisapp.config.Spicetify
          $progress = [timespan]::Parse($thisapp.config.Spicetify.POSITION).TotalSeconds
        }else{
          $current_track = (Get-CurrentTrack -ApplicationName $thisapp.config.App_Name)
          $progress = [timespan]::FromMilliseconds($current_track.progress_ms).TotalSeconds
        } 
        #TODO: Need to add Spicetify commands for this             
        if($current_track.is_playing -and $progress -ne $e.Source.value){
          $synchash.MediaPlayer_Slider.Value = $e.Source.value
          $devices = Get-AvailableDevices -ApplicationName $thisapp.config.App_Name
          Invoke-SeekPositionCurrentTrack -PositionMs ($newvalue * 1000) -DeviceId $devices.id -ApplicationName $thisapp.config.App_Name
          #Set-SpotifyPlayer -DeviceId ($devices | where {$_.is_active}).id -Shuffle:$false -Repeat off -TrackPosition ($synchash.MediaPlayer_Slider.Value * 1000)
        }
      }
    }
})



#Volume controls
if($thisapp.Config.Media_Volume){$synchash.vlc.Volume = $thisapp.Config.Media_Volume}else{$synchash.vlc.Volume = 100}
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
      if($synchash.vlc.Volume -ge 75){$synchash.Volume_icon.kind = 'VolumeHigh'}elseif($synchash.vlc.Volume -gt 25 -and $synchash.vlc.Volume -lt 75){$synchash.Volume_icon.kind = 'VolumeMedium'}elseif($synchash.vlc.Volume -le 25 -and $synchash.vlc.Volume -gt 0){$synchash.Volume_icon.kind = 'VolumeLow'}elseif($synchash.vlc.Volume -le 0){$synchash.Volume_icon.kind = 'Volumeoff'}      
    }
})
$synchash.Volume_button.Add_Click({
    if($synchash.vlc){
      $synchash.vlc.ToggleMute()
      if($synchash.vlc.mute){$synchash.Volume_icon.kind = 'Volumeoff'}elseif($synchash.vlc.Volume -ge 75){$synchash.Volume_icon.kind = 'VolumeHigh'}elseif($synchash.vlc.Volume -gt 25 -and $synchash.vlc.Volume -lt 75){$synchash.Volume_icon.kind = 'VolumeMedium'}elseif($synchash.vlc.Volume -le 25 -and $synchash.vlc.Volume -gt 0){$synchash.Volume_icon.kind = 'VolumeLow'}elseif($synchash.vlc.Volume -le 0){$synchash.Volume_icon.kind = 'Volumeoff'}      
    }
})

$null = $synchash.Play_Media.AddHandler([System.Windows.Controls.Button]::ClickEvent,$PlayMedia_Command)

$synchash.vlc.add_MediaChanged({
    #Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -startup -thisApp $thisApp -PlayMedia_Command $PlayMedia_Command -media_contextMenu $Media_ContextMenu 
})

#TODO: These handlers always crash vlc on event trigger?
<#$synchash.vlc.add_EndReached({
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
    Start-Media -media $next_selected -thisApp $thisApp -synchash $synchash -PlayMedia_Command $PlayMedia_Command                                         
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
$synchash.Restart_media.Add_click({
    try{
      $synchash.timer.stop()
      $synchash.VLC.stop()
      $synchash.Vlc.Play()
      $synchash.timer.start()
    }catch{write-ezlogs 'An exception occurred in Restart_Media click event' -showtime -catcherror $_}
})
$synchash.stop_media.Add_click({
    try{
      $synchash.Timer.stop()
      if($synchash.vlc.IsPlaying){
        $synchash.VLC.stop()    
        $synchash.chat_WebView2.stop()  
        $synchash.chat_column.Width = '*'
        $synchash.chat_WebView2.Visibility = 'Hidden'
        $current_track = $null 
        if(Get-Process streamlink*){Get-Process streamlink* | Stop-Process -Force}   
      }else{$current_track = (Get-CurrentTrack -ApplicationName $thisapp.config.App_Name)}      
      if($current_track.is_playing){
        $devices = Get-AvailableDevices -ApplicationName $thisapp.config.App_Name
        $synchash.Spotify_Status = 'Stopped'
        if($devices){
          write-ezlogs 'Stoping Spotify playback' -showtime -color cyan
          if($thisapp.config.Use_Spicetify){
            try{
              if((NETSTAT.EXE -n) | where {$_ -match '127.0.0.1:8974'}){
                write-ezlogs "[Stop_media] Stopping Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -color cyan
                Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing 
              }else{
                write-ezlogs '[Stop_media] PODE doesnt not seem to be running on 127.0.0.1:8974 - falling back to try Suspend-Playback' -showtime -warning
                Suspend-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $devices.id
              }
            }catch{
              write-ezlogs "[Stop_media] An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE' -- attempting Suspend-Playback" -showtime -catcherror $_ 
              #Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id            
            }
          }else{
            write-ezlogs "[Stop_media] Stopping Spotify playback with Suspend-Playback -ApplicationName $($thisapp.config.App_Name) -DeviceId $($devices.id)" -showtime -color cyan
            Suspend-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $devices.id
          }          
        }  
      }
      Get-Playlists -verboselog:$false -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists         
    }catch{write-ezlogs 'An exception occurred in stop_media click event' -showtime -catcherror $_}
})
$synchash.Pause_media.Add_click({
    if($synchash.VLC.state -match 'Playing'){
      $synchash.Now_Playing_Label.content = ($synchash.Now_Playing_Label.content) -replace 'Now Playing', 'Paused'
      $synchash.VLC.pause()
      $synchash.Timer.stop()
    }elseif($synchash.VLC.state -match 'Paused'){
      $current_track = (Get-CurrentTrack -ApplicationName $thisapp.config.App_Name) 
      $synchash.Now_Playing_Label.content = ($synchash.Now_Playing_Label.content) -replace 'Paused', 'Now Playing'
      $synchash.VLC.pause()
      $synchash.Timer.Start()
      if($synchash.chat_WebView2.Visibility -ne 'Hidden'){$synchash.chat_WebView2.Reload()}      
    }else{$current_track = (Get-CurrentTrack -ApplicationName $thisapp.config.App_Name)}        
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
    }    
})

$timer_maxretry = 0
$Timer = New-Object System.Windows.Threading.DispatcherTimer
$Timer.Interval = [timespan]::FromMilliseconds(600) #(New-TimeSpan -Seconds 1)
$synchash.current_track_playing = ''
$synchash.Spotify_Status = 'Stopped'
$Timer.add_tick({    
    $last_played = $thisapp.config.Last_Played
    $spotify_last_played = $thisapp.config.Spotify_Last_Played
    $Current_playlist_items = $synchash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}
    $Current_playing = $Current_playlist_items.items | where {$_.header.id -eq $thisapp.Config.Last_Played}
    if(!$Current_playing){$Current_playing = $Current_playlist_items.items | where {$_.tag.Media.id -eq $thisapp.Config.Last_Played}}  
    #write-ezlogs "Current playing items: $($Current_playing.header | out-string)"
    if(!$Current_playing -and $timer_maxretry -lt 25){    
      try{
        write-ezlogs "[TICK_TIMER] | Couldnt get current playing item with id $($thisapp.Config.Last_Played) from queue! Executing Get-Playlists" -showtime -warning
        Get-Playlists -verboselog:$false -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists           
        $timer_maxretry++    
        $Current_playlist_items = $synchash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}    
        $Current_playing = $Current_playlist_items.items | where {$_.header.id -eq $thisapp.Config.Last_Played}          
        if(!$Current_playing){
          write-ezlogs '[TICK_TIMER] | Item does not seem to be in the queue' -showtime -warning
          if($thisapp.config.Current_Playlist.values -notcontains $thisapp.Config.Last_Played){
            write-ezlogs "[TICK_TIMER] | Adding $($thisapp.Config.Last_Played) to Play Queue" -showtime
            $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
            $index++
            $null = $thisapp.config.Current_Playlist.add($index,$thisapp.Config.Last_Played)         
          }else{write-ezlogs "[TICK_TIMER] | Play queue already contains $($thisapp.Config.Last_Played), refreshing one more time then I'm done here" -showtime -warning}
          $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
          Get-Playlists -verboselog:$false -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists 
          $Current_playlist_items = $synchash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}    
          $Current_playing = $Current_playlist_items.items | where {$_.header.id -eq $thisapp.Config.Last_Played}         
          if(!$Current_playing){
            write-ezlogs "[ERROR] [TICK_TIMER] | Still couldnt find $($thisapp.Config.Last_Played) in the play queue, aborting!" -showtime -color red
            Update-Notifications -id 1 -Level 'ERROR' -Message "Couldnt find $($thisapp.Config.Last_Played) in the play queue, aborting progress timer!" -VerboseLog -Message_color 'Red' -thisApp $thisapp -synchash $synchash
            $synchash.MediaPlayer_Slider.Value = 0
            $this.Stop()
          }else{write-ezlogs '[TICK_TIMER] | Found current playing item after adding it to the play queue and refreshing Get-Playlists, but this shouldnt have been needed!' -showtime -warning}                      
        }else{write-ezlogs '[TICK_TIMER] | Found current playing item after refreshing Get-Playlists' -showtime}   
      }catch{
        write-ezlogs "An exception occurred in Tick_Timer while trying to update/get current playing items" -showtime -catcherror $_
      }  
    }elseif($timer_maxretry -ge 25){
      write-ezlogs "[ERROR] [TICK_TIMER] | Timed out trying to find current playing item $($thisapp.Config.Last_Played) in the play queue, aborting!" -showtime -color red
      Update-Notifications -id 1 -Level 'ERROR' -Message "Timed out trying to find $($thisapp.Config.Last_Played) in the play queue, aborting progress timer!" -VerboseLog -Message_color 'Red' -thisApp $thisapp -synchash $synchash
      $synchash.MediaPlayer_Slider.Value = 0
      $this.Stop()    
    }else{
      #write-ezlogs "Found Current playing item $($Current_playing.header | out-string)"
    }        
    if(!$synchash.vlc.IsPlaying){
      #$current_track = (Get-CurrentTrack -ApplicationName $thisApp.config.App_Name) 
      $current_track = $synchash.current_track_playing
      if($thisapp.Config.Use_Spicetify){
        $Name = $thisapp.config.Spicetify.title
        $Artist = $thisapp.config.Spicetify.ARTIST
        try{
          if($thisapp.config.Spicetify.POSITION -ne $null){
            $progress = [timespan]::Parse($thisapp.config.Spicetify.POSITION).TotalMilliseconds
          }else{
            $progress = $($([timespan]::FromMilliseconds(0)).TotalMilliseconds)
          }
        }catch{
          write-ezlogs '[TICK_TIMER] An exception occurred parsing Spicetify position timespan' -showtime -catcherror $_
        }        
        $duration = $thisapp.config.Spicetify.duration_ms
      }else{
        $Name = $current_track.item.name
        $Artist = $current_track.item.artists.name
        $progress = $current_track.progress_ms
        $duration = $current_track.item.duration_ms
      }       
      #write-ezlogs "Last played title: $($thisApp.config.Last_Played_title) -- Current name : $($name)" -showtime
    }          
    if($synchash.vlc.IsPlaying -and $synchash.VLC.Time -ne -1){
      if(!$synchash.MediaPlayer_Slider.IsMouseOver){$synchash.MediaPlayer_Slider.Value = $([timespan]::FromMilliseconds($synchash.VLC.Time)).TotalSeconds}      
      [int]$hrs = $($([timespan]::FromMilliseconds($synchash.VLC.Time)).Hours)
      [int]$mins = $($([timespan]::FromMilliseconds($synchash.VLC.Time)).Minutes)
      [int]$secs = $($([timespan]::FromMilliseconds($synchash.VLC.Time)).Seconds)     
      $total_time = $synchash.MediaPlayer_CurrentDuration      
      $synchash.Media_Length_Label.content = "$hrs" + ':' + "$mins" + ':' + "$secs" + '/' + "$($total_time)"   
      if($thisapp.Config.streamlink.viewer_count -and $enable_Marquee){
        if($thisapp.Config.Verbose_Logging){write-ezlogs " | Twitch Viewer count: $($thisapp.Config.streamlink.viewer_count)" -showtime -color cyan}
        $synchash.VLC.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Enable, 1) #enable marquee option
        $synchash.VLC.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Size, 24) #set the font size 
        $synchash.VLC.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Position, 8) #set the position of text
        $synchash.VLC.SetMarqueeString([LibVLCSharp.Shared.VideoMarqueeOption]::Text, "Viewers: $($thisapp.Config.streamlink.viewer_count)")
        #to set subtitle or any other text                                          
      }else{
        $synchash.VLC.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Enable, 0) #disable marquee option                                   
      }      
      if($Current_playing -and $Current_playing.Header.title -notmatch '---> '){       
        Get-Playlists -verboselog:$false -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists
        #Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -startup -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists        
        $Current_playlist_items = $synchash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}
        $Current_playing = $Current_playlist_items.items | where {$_.tag.Media.id -eq $thisapp.Config.Last_Played}      
        #(($syncHash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}).items | where {$_.tag.Media.id -eq $thisApp.Config.Last_Played}).Header = "---> $($Current_playing.Header)"
        $Current_playing.Header.title = "---> $($Current_playing.Header.title)"
        if($thisapp.Config.streamlink.type){$Current_playing.Header.Status = "$($thisapp.Config.streamlink.type)"} 
        if($thisapp.Config.streamlink.Title){$Current_playing.Header.Status_Msg = "$($thisapp.Config.streamlink.game_name)"}               
        $Current_playing.BorderBrush = 'LightGreen'
        $Current_playing.BorderThickness = '1'
        $Current_playing.FontWeight = 'Bold'
        $Current_playing.FontSize = 14
      }
    }elseif(($current_track.is_playing -or ($thisapp.Config.Spicetify.is_playing)) -and $progress -and $Name -match $thisapp.config.Last_Played_title -and $synchash.Spotify_Status -ne 'Stopped'){  
      try{
        $synchash.MediaPlayer_Slider.Maximum = $([timespan]::FromMilliseconds($duration)).TotalSeconds
        if(!$synchash.MediaPlayer_Slider.IsMouseOver){$synchash.MediaPlayer_Slider.Value = $([timespan]::FromMilliseconds($current_track.progress_ms)).TotalSeconds}     
        [int]$hrs = $($([timespan]::FromMilliseconds($progress)).Hours)
        [int]$mins = $($([timespan]::FromMilliseconds($progress)).Minutes)
        [int]$secs = $($([timespan]::FromMilliseconds($progress)).Seconds)  
        [int]$totalhrs = $([timespan]::FromMilliseconds($duration)).Hours
        [int]$totalmins = $([timespan]::FromMilliseconds($duration)).Minutes
        [int]$totalsecs = $([timespan]::FromMilliseconds($duration)).Seconds
        $total_time = "$totalhrs`:$totalmins`:$totalsecs"    
        $synchash.Media_Length_Label.content = "$hrs" + ':' + "$mins" + ':' + "$secs" + '/' + "$($total_time)"              
        $Current_playing = $Current_playlist_items.items | where {$_.tag.Media.encodedtitle -eq $thisapp.Config.Last_Played}
        if($Current_playing -and $Current_playing.Header -notmatch '---> '){
          Get-Playlists -verboselog:$false -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists
          $Current_playlist_items = $synchash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}    
          $Current_playing = $Current_playlist_items.items | where {$_.header.id -eq $thisapp.Config.Last_Played}        
          #(($syncHash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}).items | where {$_.tag.Media.encodedtitle -eq $thisApp.Config.Last_Played}).Header = "---> $($Current_playing.Header)"
          $Current_playing.Header.FontWeight = 'Bold'
          $Current_playing.Header.FontSize = 14
          $Current_playing.Header.title = "---> $($Current_playing.Header.title)"
          $Current_playing.BorderBrush = 'LightGreen'
          $Current_playing.BorderThickness = '1'
          $Current_playing.FontWeight = 'Bold'
          $Current_playing.FontSize = 14  
          #write-ezlogs "Header: $($Current_playing.Header | out-string)"
          #write-ezlogs "Header: $($Current_playing.UID | out-string)"              
        }    
      }catch{write-ezlogs '[Tick_Timer] An exception occurred processing Spotify playback in tick_timer' -showtime -catcherror $_}    
    }elseif((!$synchash.vlc.IsPlaying) -and $synchash.Spotify_Status -eq 'Stopped'){   
      if($thisapp.Config.Verbose_Logging){
        if($synchash.Spotify_Status -eq 'Stopped'){write-ezlogs "[Tick_Timer] Spotify_Status now equals 'Stopped'" -showtime}elseif(!$synchash.vlc.IsPlaying){write-ezlogs "[Tick_Timer] VLC is_Playing is now false - '$($synchash.vlc.IsPlaying)'" -showtime}
      }
      if($thisapp.config.Use_Spicetify){
        try{
          #start-sleep 1
          write-ezlogs "[Tick_Timer] Stopping Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -color cyan
          Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing  
        }catch{
          write-ezlogs "[Tick_Timer] An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -catcherror $_
          if(Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue){Get-Process -Name 'Spotify' | Stop-Process -Force -ErrorAction SilentlyContinue}             
        }
      }else{
        try{
          $devices = Get-AvailableDevices -ApplicationName $thisapp.config.App_Name
          if($devices){
            write-ezlogs '[Tick_Timer] Stopping Spotify playback with Suspend-Playback' -showtime -color cyan
            Suspend-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $devices.id
          }else{
            write-ezlogs '[Tick_Timer] Couldnt get Spotify Device id, using nuclear option and force stopping Spotify process' -showtime -warning
            if(Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue){Get-Process -Name 'Spotify' | Stop-Process -Force -ErrorAction SilentlyContinue}            
          }           
        }catch{
          write-ezlogs '[Tick_Timer] An exception occurred executing Suspend-Playback' -showtime -catcherror $_
          if(Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue){Get-Process -Name 'Spotify' | Stop-Process -Force -ErrorAction SilentlyContinue}             
        }           
      }       
      if($thisapp.config.Current_Playlist.values -contains $last_played){
        $index_toremove = $thisapp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $last_played} | select * -ExpandProperty key
        $null = $thisapp.config.Current_Playlist.Remove($index_toremove)                         
      }     
      $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
      try{   
        if($thisapp.config.Shuffle_Playback){$next_item = $thisapp.config.Current_Playlist.values | where {$_} | Get-Random -Count 1}else{
          #$next_item = $thisApp.config.Current_Playlist.values | where {$_} | Select -First 1 
          $index_toget = ($thisapp.config.Current_Playlist.keys | measure -Minimum).Minimum 
          $next_item = (($thisapp.config.Current_Playlist.GetEnumerator()) | where {$_.name -eq $index_toget}).value
        }                   
        if($thisapp.Config.Verbose_Logging){write-ezlogs "[Tick_Timer] Next to play from Play Queue is $($next_item) which should not eq last played $($last_played)" -showtime}
        Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -PlayMedia_Command $PlayMedia_Command -media_contextMenu $Media_ContextMenu            
        if($next_item){
          write-ezlogs "[Tick_Timer] | Next queued item is $($next_item)" -showtime
          $next_selected_media = $all_playlists.playlists.Playlist_tracks | where {$_.id -eq $next_item} | select -Unique 
          if(!$next_selected_media){$next_selected_media = $Datatable.datatable | where {$_.ID -eq $next_item} | select -Unique}              
          if(!$next_selected_media){$next_selected_media = $Youtube_Datatable.datatable | where {$_.id -eq $next_item} | select -Unique}
          if(!$next_selected_media){$next_selected_media = $Spotify_Datatable.datatable | where {$_.id -eq $next_item} | select -Unique}
          if(!$next_selected_media){
            write-ezlogs "Unable to find next media to play with id $next_item! Cannot continue" -showtime -warning
            Update-Notifications -id 1 -Level 'WARNING' -Message "Unable to find next media to play with id $next_item! Cannot continue" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -open_flyout
          }else{
            write-ezlogs "[Tick_Timer] | Next to play is $($next_selected_media.title)" -showtime         
            if($next_selected_media.Spotify_Path){Play-SpotifyMedia -Media $next_selected_media -thisApp $thisapp -synchash $synchash -Script_Modules $Script_Modules -Show_notification -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -PlaySpotify_Media_Command $PlaySpotify_Media_Command}elseif($next_selected_media.id){
              if(Get-Process -Name 'Spotify*' -ErrorAction SilentlyContinue){Get-Process -Name 'Spotify*' | Stop-Process -Force -ErrorAction SilentlyContinue} 
              $synchash.Spotify_Status = 'Stopped'           
              Start-Media -media $next_selected_media -thisApp $thisapp -synchash $synchash -Show_notification -Script_Modules $Script_Modules -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists
            }          
          }          
          $this.stop()     
        }else{
          Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -PlayMedia_Command $PlayMedia_Command -media_contextMenu $Media_ContextMenu
          write-ezlogs '[Tick_Timer] | No other media is queued to play' -showtime
          if(Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue){Get-Process -Name 'Spotify' | Stop-Process -Force -ErrorAction SilentlyContinue} 
          $synchash.Spotify_Status = 'Stopped'   
          $synchash.Media_Length_Label.content = ''
          $synchash.Now_Playing_Label.content = ''      
          $this.stop()
        }   
      }catch{        
        write-ezlogs '[Tick_Timer] An exception occurred executing Start-Media for next item' -showtime -catcherror $_
        $this.stop()
      }    
    }else{write-ezlogs '[Tick_Timer] | Unsure what to do! Looping...' -showtime -warning}          
}.GetNewClosure())
$synchash.Timer = $Timer

Add-Member -InputObject $thisapp.config -Name 'Download_Status' -Value $false -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'Download_Message' -Value '' -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'Download_logfile' -Value '' -MemberType NoteProperty -Force
Add-Member -InputObject $thisapp.config -Name 'Download_UID' -Value '' -MemberType NoteProperty -Force
$downloadTimer = New-Object System.Windows.Threading.DispatcherTimer
$downloadTimer.Interval = (New-TimeSpan -Seconds 1)
$downloadTimer.add_tick({
    if($thisapp.config.Download_status -and -not [string]::IsNullOrEmpty($thisapp.config.Download_message) -and $thisapp.config.Download_UID){
      $download_notification = $synchash.Notifications_Grid.items | where {$_.id -eq $thisapp.config.Download_UID}        
      if($download_notification){Update-Notifications -id $thisapp.config.Download_UID -Level 'Info' -Message $thisapp.config.Download_message -VerboseLog -Message_color 'Red' -thisApp $thisapp -synchash $synchash  -clear}         
    } 
}.GetNewClosure())
$synchash.downloadTimer = $downloadTimer
#$Synchash.Timer1 = $timer1
#$synchash.vlc.add_MediaChanged({
#if(!$synchash.vlc.IsPlaying){
#  write-ezlogs "[VLC_MEDIA_CHANGED] >>>> Starting VLC Media Playback" -showtime -color cyan
#  $synchash.vlc.play()
#$Synchash.Timer.start()
# }
#}) 


#$synchash.vlc.Add_PositionChanged({

# write-ezlogs "[PositionChanged] $($this | out-string)"
#$synchash.MediaPlayer_Slider.Value = [int]$synchash.vlc.VlcMediaPlayer.Time / 1000

#})


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
<#$synchash.vlc.add_Stopped({

    })
#>
if($startup_perf_timer){write-ezlogs " | Seconds to VLC: $($startup_stopwatch.Elapsed.TotalSeconds)" -showtime}
#----------------------------------------------
#endregion Vlc Controls
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
$synchash.Shuffle_Playback_Button.add_Click({
    if($thisapp.config.Shuffle_Playback){
      $synchash.Shuffle_Icon.Kind = 'ShuffleDisabled'
      $synchash.Shuffle_Playback_Button.ToolTip = 'Shuffle Disabled'
      Add-Member -InputObject $thisapp.config -Name 'Shuffle_Playback' -Value $false -MemberType NoteProperty -Force
    }else{
      $synchash.Shuffle_Icon.Kind = 'ShuffleVariant'
      $synchash.Shuffle_Playback_Button.ToolTip = 'Shuffle Enabled'
      Add-Member -InputObject $thisapp.config -Name 'Shuffle_Playback' -Value $true -MemberType NoteProperty -Force
    }
})

#---------------------------------------------- 
#endregion Shuffle Options
#----------------------------------------------

#---------------------------------------------- 
#region Chat View
#----------------------------------------------
if($thisapp.config.Chat_View){$synchash.Chat_Icon.Kind = 'Chat'}else{$synchash.Chat_Icon.Kind = 'ChatRemove'}
$synchash.Chat_View_Button.add_Click({
    if($thisapp.config.Chat_View){
      $synchash.Chat_Icon.Kind = 'ChatRemove'
      $synchash.chat_WebView2.Visibility = 'Hidden'
      $synchash.chat_column.Width = '*'
      Add-Member -InputObject $thisapp.config -Name 'Chat_View' -Value $false -MemberType NoteProperty -Force
    }else{
      $synchash.Chat_Icon.Kind = 'Chat'
      $synchash.chat_WebView2.Visibility = 'Visible'
      $synchash.chat_column.Width = '400'
      Add-Member -InputObject $thisapp.config -Name 'Chat_View' -Value $true -MemberType NoteProperty -Force
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
      Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -startup -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists
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
    if((NETSTAT.EXE -n) | where {$_ -match '127.0.0.1:8974'}){Invoke-RestMethod -Uri 'http://127.0.0.1:8974/CLOSEPODE' -UseBasicParsing -ErrorAction SilentlyContinue}
    Import-Module pode -Force
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
}
if($thisapp.config.Use_Spicetify){
  $synchash.Spicetify_Toggle.ison = $true
  $thisapp.Config.Spicetify = ''
  Add-Member -InputObject $thisapp.config -Name 'PODE_SERVER_ACTIVE' -Value $true -MemberType NoteProperty -Force
  $Variable_list = Get-Variable | where {$_.Options -notmatch 'ReadOnly' -and $_.Options -notmatch 'Constant'}
  Start-Runspace -scriptblock $pode_server_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -Load_Modules -Script_Modules $Script_Modules -runspace_name 'PODE_SERVER_RUNSPACE'
}else{
  Add-Member -InputObject $thisapp.config -Name 'PODE_SERVER_ACTIVE' -Value $false -MemberType NoteProperty -Force
  $synchash.Spicetify_Toggle.ison = $false
}

$synchash.Spicetify_Toggle.Add_Toggled({ 
    $synchash.Spicetify_textblock.text = ''
    $synchash.Spicetify_transitioningControl.content = '' 
    if($synchash.Spicetify_Toggle.isOn){$synchash.Spicetify_textblock.text = 'You must Save/Apply Settings to complete Spicetify setup and customizations'}else{$synchash.Spicetify_textblock.text = 'You must Save/Apply Settings to complete removal of Spicetify setup and customizations'}
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
  #$synchash = $($Sender.tag.synchash)  
  #$thisScript = $($Sender.tag.thisScript) 
  #$all_installed_games = $($Sender.tag.all_installed_games)
  #$Game_Profile_Directory = $($Sender.tag.Game_Profile_Directory)
  #$Save_GameSessions = $($Sender.tag.Save_GameSessions)
  #$all_games_profile_path = $($Sender.tag.all_games_profile_path)
  try{
    $null = $synchash.Notifications_Grid.Items.Remove($synchash.Notifications_Grid.SelectedItem)
    if([int]$synchash.Notifications_Badge.badge -gt 0){
      [int]$synchash.Notifications_Badge.badge = [int]$synchash.Notifications_Grid.items.count
      if([int]$synchash.Notifications_Badge.badge -eq 0){$synchash.Notifications_Badge.badge = ''}
    }elseif([int]$synchash.Notifications_Badge.badge -eq 0){$synchash.Notifications_Badge.badge = ''}
  }catch{write-ezlogs 'An exception occurred for dismissclickevent' -showtime -catcherror $_}
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
  $null = $buttonFactory.SetValue([System.Windows.Controls.Button]::StyleProperty, $synchash.Window.TryFindResource('ToolsButtonStyle'))
  $null = $buttonFactory.SetValue([System.Windows.Controls.Button]::NameProperty, 'Notification_dismiss_button')
  $null = $buttonFactory.AddHandler([System.Windows.Controls.Button]::ClickEvent,$DismissclickEvent)
  $null = $buttonFactory.SetValue([System.Windows.Controls.Button]::TagProperty,$buttontag)    
  $dataTemplate = New-Object System.Windows.DataTemplate
  $dataTemplate.VisualTree = $buttonFactory
  $buttonColumn.CellTemplate = $dataTemplate
  $buttonColumn.DisplayIndex = 0  
  $null = $synchash.Notifications_Grid.Columns.add($buttonColumn)

  <#  $messageColumn = New-Object System.Windows.Controls.DataGridTemplateColumn
      $headerTextblock = [System.Windows.Controls.TextBlock]::new()
      $headerTextblock.Text = "Message"
      $headerTextblock.FontWeight = "Bold"
      $messageColumn.Header = $headerTextblock
      $MessageFactory = New-Object System.Windows.FrameworkElementFactory([System.Windows.Controls.TextBlock])
      $Binding = New-Object System.Windows.Data.Binding
      $binding.Path = 'Message' 
      $Null = $MessageFactory.SetValue([System.Windows.Controls.TextBlock]::TextProperty, $binding)    
      #$Null = $MessageFactory.SetValue([System.Windows.Controls.TextBlock]::StyleProperty, $synchash.Window.TryFindResource("ToolsButtonStyle"))
      $Null = $MessageFactory.SetValue([System.Windows.Controls.TextBlock]::NameProperty, "Notification_message_textblock")
      $null = $MessageFactory.SetValue([System.Windows.Controls.TextBlock]::TextWrappingProperty,'Wrap')
      #$null = $MessageFactory.SetValue([System.Windows.Controls.TextBlock]::TagProperty,$buttontag)    
      $dataTemplate = New-Object System.Windows.DataTemplate
      $dataTemplate.VisualTree = $messageFactory
      $messageColumn.CellTemplate = $dataTemplate  
  $null = $synchash.Notifications_Grid.Columns.add($messageColumn) #>
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
      $synchash.App_Exe_Path_Textbox_transitioningControl.content = $App_Exe_Path_Textbox_transitioningControl
      $synchash.App_Exe_Path_Button_transitioningControl.content = $App_Exe_Path_Button_transitioningControl
      $synchash.App_Exe_Path_Label.IsEnabled = $true 
      $synchash.App_Exe_Path_textbox.text = $thisapp.config.App_EXE_Path     
      $synchash.App_Exe_Path_textbox.IsEnabled = $true      
      $synchash.App_Exe_Path_Browse.IsEnabled = $true  
      Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $true -MemberType NoteProperty -Force
    }
    else{
      $synchash.App_Exe_Path_label_transitioningControl.content = ''
      $synchash.App_Exe_Path_Textbox_transitioningControl.content = ''
      $synchash.App_Exe_Path_Button_transitioningControl.content = ''
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
  $synchash.App_Exe_Path_textbox.IsEnabled = $true      
  $synchash.App_Exe_Path_Browse.IsEnabled = $true  
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
    Update-HelpFlyout -content 'IMPORTANT: The app creates a Windows Scheduled task when enabled. It then removes the task when disabled. If you remove the app without disabling this option first, the scheduled task will remain (and fail if the exe is gone)' -linebefore -FontWeight bold -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$verboselogging -synchash $synchash
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
    $result = Open-FolderDialog -Title 'Select the directory path where media will be downloaded to'
    if(-not [string]::IsNullOrEmpty($result)){$synchash.Log_Path_textbox.text = $result}  
}) 


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
#region Use Hardware Acceleration Toggle
#----------------------------------------------
if($thisapp.config.Use_HardwareAcceleration){$synchash.Use_HardwareAcceleration_Toggle.isOn = $true}else{$synchash.Use_HardwareAcceleration_Toggle.isOn = $false}
$synchash.Use_HardwareAcceleration_transitioningControl.content = ''
$synchash.Use_HardwareAcceleration_textblock.text = ''
$synchash.Use_HardwareAcceleration_Toggle.add_Toggled({
    if($synchash.Use_HardwareAcceleration_Toggle.isOn -eq $true){Add-Member -InputObject $thisapp.config -Name 'Use_HardwareAcceleration' -Value $true -MemberType NoteProperty -Force}
    else{Add-Member -InputObject $thisapp.config -Name 'Use_HardwareAcceleration' -Value $false -MemberType NoteProperty -Force}
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
    Update-HelpFlyout -content 'If experiencing video playback issues, try disabling or enabling to see if playback improves. The load on the CPU/GPU varies depending on the quality/bitrate of the video. In some cases, disabling Hardware Acceleration can lower total GPU usage at very minimal increase to the CPU'  -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$verboselogging -synchash $synchash    
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
    Update-HelpFlyout -content 'Can be useful when playing through large playlists or when using shuffle to identify a song thats playing without needing to bring the app back into focus'  -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$verboselogging -synchash $synchash    
    Update-HelpFlyout -content 'IMPORTANT' -FontWeight bold -TextDecorations Underline -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'Notifications may contain Artist/Album thumbnail images if available, otherwise will display a default image based on the type of media (Twitch, Youtube, or VLC for local media)' -FontWeight bold -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
})
#---------------------------------------------- 
#endregion Show Notifications Help
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
    if($synchash.Twitch_Update_Toggle.isOn -eq $true){       
      Add-Member -InputObject $thisapp.config -Name 'Twitch_Update' -Value $true -MemberType NoteProperty -Force
      $synchash.Twitch_Update_Interval_ComboBox.IsEnabled = $true
    }
    else{          
      Add-Member -InputObject $thisapp.config -Name 'Twitch_Update' -Value $false -MemberType NoteProperty -Force
      $synchash.Twitch_Update_Interval_ComboBox.IsEnabled = $false      
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
    if($synchash.Twitch_Update_Interval_ComboBox.SelectedIndex -ne -1){    
      $synchash.Twitch_Update_Interval_Label.BorderBrush = 'Green'
      if($synchash.Twitch_Update_Interval_ComboBox.Selecteditem.Content -match 'Minutes'){$interval = [TimeSpan]::FromMinutes("$(($synchash.Twitch_Update_Interval_ComboBox.Selecteditem.Content -replace 'Minutes', '').trim())")}elseif($synchash.Twitch_Update_Interval_ComboBox.Selecteditem.Content -match 'Hour'){$interval = [TimeSpan]::FromHours("$(($synchash.Twitch_Update_Interval_ComboBox.Selecteditem.Content -replace 'Hour', '').trim())")}
      Add-Member -InputObject $thisapp.config -Name 'Twitch_Update_Interval' -Value $interval -MemberType NoteProperty -Force
      $synchash.Twitch_Update_textblock.text = ''
      $synchash.Twitch_Update_transitioningControl.content = ''      
    }
    else{          
      $synchash.Twitch_Update_Interval_Label.BorderBrush = 'Red'
      Add-Member -InputObject $thisapp.config -Name 'Twitch_Update_Interval' -Value '' -MemberType NoteProperty -Force      
    }
}) 

if($thisapp.config.Twitch_Update -and $thisapp.config.Twitch_Update_Interval){
  try{Start-TwitchMonitor -Interval $thisapp.config.Twitch_Update_Interval -thisApp $thisapp -all_playlists $all_playlists -synchash $synchash -Verboselog}catch{write-ezlogs 'An exception occurred in Start-TwitchMonitor' -showtime -catcherror $_}
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
    Update-HelpFlyout -content 'Refreshing gets the broadcasting status (Live, Hosting, Offline..etc), current category and title of each Twitch channel that has been added to the app.'  -FontWeight bold -color cyan -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$verboselogging -synchash $synchash    
    Update-HelpFlyout -content 'IMPORTANT' -FontWeight bold -TextDecorations Underline -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
    Update-HelpFlyout -content 'Naturally, this requires having added at least 1 Twitch Channel/Stream to the app, otherwise this does nothing' -FontWeight bold -color orange -RichTextBoxControl $synchash.HelpFlyout -thisApp $thisapp -enablelogs:$thisapp.Config.Verbose_logging -synchash $synchash
})
#---------------------------------------------- 
#endregion Twitch Updates Help
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
      $synchash.window.hide()
      Start-SplashScreen -SplashTitle $thisScript.Name -SplashMessage 'Applying Settings...' -Splash_More_Info 'Please Wait' -thisScript $thisScript -current_folder $Current_folder -startup -log_file $logfile -Script_modules $Script_Modules 
      #$Dialog_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new() 
      #$progress_dialog = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowProgressAsync($synchash.Window,'Applying Settings','Please wait while settings are applied...',$true,$Dialog_Settings)
      #$progress_dialog.Wait(10)
      #$progress_dialog.ConfigureAwait($false)
      #$progress_dialog.GetAwaiter()     
    }
    catch
    {write-ezlogs 'An error occurred while displaying Mahapps progress dialog' -showtime -catcherror $_}
    if([System.IO.File]::Exists($thisapp.Config.Log_file) -and -not [string]::IsNullOrEmpty($synchash.Log_Path_textbox.text)){
      try{
        if([System.IO.Directory]::Exists($synchash.Log_Path_textbox.text)){       
          $logname = $thisapp.Config.Log_file | Split-Path -leaf
          $logfile_test = "$($synchash.Log_Path_textbox.text)\$($logname)"
          write-ezlogs "[TEST] >>>> Copying existing log file to new location $logfile_test" -showtime 
          #$null = Copy-item $thisApp.Config.Log_file -Destination $logfile -Force
          #$thisApp.Config.Log_file = $logfile
        }else{write-ezlogs "The provided directory path for the log file is invalid $($synchash.Log_Path_textbox.text)" -showtime -warning}
      }catch{write-ezlogs 'An exception occurred attempting to copy/move the log file' -showtime -catcherror $_}
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
      Add-Member -InputObject $thisapp.config -Name 'Use_Spicetify' -Value $true -MemberType NoteProperty -Force
      $custom_webnowplaying = "$($thisapp.config.Current_Folder)\\Resources\\Spicetify\\webnowplaying.js"
      $webnowplaying_file = "$($env:userprofile)\\spicetify-cli\Extensions\\webnowplaying.js"
      $webnowplaying_file_backup = "$($env:userprofile)\\spicetify-cli\Extensions\\webnowplaying.js.bak"
      $custom_webnowplaying_content = Get-Content $custom_webnowplaying -ReadCount 0 -Force -Encoding UTF8 -Verbose:$thisapp.Config.Verbose_logging
      try{
        $Spotify_pref = (Get-iniFile "$($env:userprofile)\\.spicetify\\config-xpui.ini").Setting.prefs_path      
        if(!(Test-Path $Spotify_pref)){
          write-ezlogs "Spicetify spotify pref path not valid at $Spotify_pref" -showtime
          if(Test-Path "$($env:userprofile)\AppData\Roaming\Spotify\prefs"){
            write-ezlogs "Updating spotify pref with path $($env:userprofile)\AppData\Roaming\Spotify\prefs"
            $pref_content = Get-Content "$($env:userprofile)\\.spicetify\\config-xpui.ini" -Force
            $pref_content = $pref_content -replace [regex]::escape($Spotify_pref),"$($env:userprofile)\AppData\Roaming\Spotify\prefs"
            $pref_content | Out-File "$($env:userprofile)\\.spicetify\\config-xpui.ini" -Force          
          }
        }
      }catch{write-ezlogs "An exception occurred checking spicetify spotify pref path $Spotify_pref" -showtime -catcherror $_}
      if(![System.IO.File]::Exists($webnowplaying_file)){
        write-ezlogs '>>>> Webnowplaying extension not found, forcing install of Spicetify and Spicetify marketplace' -showtime -color cyan
        Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1' | Invoke-Expression
        Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/spicetify/spicetify-marketplace/master/install.ps1' | Invoke-Expression        
        spicetify.exe backup 
        spicetify.exe config inject_css 0 replace_colors 0
        spicetify.exe config extensions webnowplaying.js
        if(Get-Process *Spotify* -ErrorAction SilentlyContinue){Get-Process *Spotify* | Stop-Process -Force -ErrorAction SilentlyContinue}
      }
      $webnowplaying_file_content = Get-Content $webnowplaying_file -ReadCount 0 -Force -Verbose:$thisapp.Config.Verbose_logging
      $webnowplaying_compare = Compare-Object $custom_webnowplaying_content -DifferenceObject $webnowplaying_file_content -Verbose:$thisapp.Config.Verbose_logging
      if (!$webnowplaying_compare)
      {Write-ezlogs '>>>> Webnowplaying extension already patched, skipping...' -color cyan -showtime}
      else
      {
        try
        {         
          write-ezlogs '>>>> Executing Spicetify backup' -showtime -color cyan
          spicetify.exe backup          
          write-ezlogs '>>>> Creating Backup of existing webnowplaying.js' -Color cyan -showtime
          $null = Copy-Item $webnowplaying_file -Destination ([System.IO.Path]::Combine("$($env:userprofile)\\spicetify-cli\Extensions", 'backup_webnowplaying.js')) -Force -ErrorAction stop -Verbose:$thisapp.Config.Verbose_logging  
          #backup js file within directory
          if(![System.IO.File]::Exists($webnowplaying_file_backup)){$null = Rename-Item -Path $webnowplaying_file -NewName 'webnowplaying.js.bak' -Force -ErrorAction Continue -Verbose:$thisapp.Config.Verbose_logging}
          write-ezlogs ' | Adding patched webnowplaying.js' -showtime 
          $null = Set-Content $webnowplaying_file -value $custom_webnowplaying_content -Force -Encoding UTF8 -ErrorAction stop -Verbose:$thisapp.Config.Verbose_logging    
          Write-ezlogs '[SUCCESS] Successfully patched webnowplaying.js' -Color Green -showtime                   
        }
        catch
        {write-ezlogs 'An error occurred while applying customized webnowplaying.js' -showtime -catcherror $_}
      } 
      try
      {              
        write-ezlogs '>>>> Applying Spicetify customizations' -Color cyan -showtime
        if($hash.Window){
          $hash.Window.Dispatcher.invoke([action]{
              $hash.More_Info_Msg.Visibility = 'Visible'
              $hash.More_info_Msg.text = 'Applying Spicetify customizations to Spotify'
          },'Normal')
        }
        #spicetify apply        
        $spicetifyupgrade_logfile = "$env:temp\\spicetify_upgrade.log"
        if([System.IO.FIle]::Exists($spicetifyupgrade_logfile)){$null = Remove-Item $spicetifyupgrade_logfile -Force}
        $command = "& `"spicetify`" upgrade *>$spicetifyupgrade_logfile"   
        $block = 
        {
          Param
          (
            $command
      
          )
          $console_output_array = Invoke-Expression $command -ErrorAction SilentlyContinue     
        }   
        #Remove all jobs and set max threads
        Get-Job | Remove-Job -Force
        $MaxThreads = 3
  
        #Start the jobs. Max 4 jobs running simultaneously.
        While ($(Get-Job -state running).count -ge $MaxThreads)
        {Start-Sleep -Milliseconds 3}
        Write-EZLogs ">>>> Executing Spicetify`n" -showtime -color cyan
        $null = Start-Job -Scriptblock $block -ArgumentList $command -ErrorAction SilentlyContinue -Verbose
        Write-EZLogs '-----------Spicetify Log Entries-----------'            
        #Wait for all jobs to finish.
        $break = $false
        While ($(Get-Job -State Running).count -gt 0 -or (Get-Process Spicetify* -ErrorAction SilentlyContinue))
        {
          #Check last line of the log, if it matches our exit trigger text, sleep until it changes indicating new log entries are being added
          if (!([System.IO.FIle]::Exists($spicetifyupgrade_logfile)))
          {Start-Sleep -Milliseconds 3}
          else
          {
            #$last_line = Get-Content -Path $legendary_logfile -force -Tail 1 2> $Null
            #Watch the log file and output all new lines. If the new line matches our exit trigger text, break out of wait
            $count = 0
            Get-Content -Path $spicetifyupgrade_logfile -force -Tail 1 -wait -Encoding utf8 | ForEach-Object {
              $count++
              Write-EZLogs "$($_)" -showtime
              $pattern1 = 'Download	- (?<value>.*) MiB\/s \(raw\)'
              $pattern2 = 'Install size: (?<value>.*) MiB'               
              if($_ -match 'Spotify is spiced up!'){
                $spicetifyexit_code = $_ 
              break}  
              #if($_ -match 'Number of applicable updates for the current system configuration:'){ $dellupdates_code = $_.Substring(($_.IndexOf('configuration: ')+15))}
              if($break){break}
              if($(Get-Job -State Running).count -eq 0){write-ezlogs 'Ended due to job ending, loop once more then break'
                $break = $true
              }
            }
          }      
        }  
        #Get information from each job.
        foreach($job in Get-Job)
        {$info = Receive-Job -Id ($job.Id)}
  
        #Remove all jobs created.
        Get-Job | Remove-Job -Force 
        Write-EZLogs '---------------END Log Entries---------------' -enablelogs
        Write-EZLogs ">>>> Spicetify. Final loop count: $count" -showtime  -color Cyan              
        write-ezlogs " | Spicetify result: $spicetifyexit_code" -showtime
       
        #spicetify restore backup apply
        $spicetifyrestorebackup_logfile = "$env:temp\\spicetify_restorebackup.log"
        if([System.IO.FIle]::Exists($spicetifyrestorebackup_logfile)){$null = Remove-Item $spicetifyrestorebackup_logfile -Force}
        $command = "& `"spicetify`" restore backup *>$spicetifyrestorebackup_logfile"   
        $block = 
        {
          Param
          (
            $command
      
          )
          $console_output_array = Invoke-Expression $command -ErrorAction SilentlyContinue     
        }   
        #Remove all jobs and set max threads
        Get-Job | Remove-Job -Force
        $MaxThreads = 3
  
        #Start the jobs. Max 4 jobs running simultaneously.
        While ($(Get-Job -state running).count -ge $MaxThreads)
        {Start-Sleep -Milliseconds 3}
        Write-EZLogs ">>>> Executing Spicetify`n" -showtime -color cyan
        $null = Start-Job -Scriptblock $block -ArgumentList $command -ErrorAction SilentlyContinue -Verbose
        Write-EZLogs '-----------Spicetify Log Entries-----------'            
        #Wait for all jobs to finish.
        $break = $false
        While ($(Get-Job -State Running).count -gt 0 -or (Get-Process Spicetify* -ErrorAction SilentlyContinue))
        {
          #Check last line of the log, if it matches our exit trigger text, sleep until it changes indicating new log entries are being added
          if (!([System.IO.FIle]::Exists($spicetifyrestorebackup_logfile)))
          {Start-Sleep -Milliseconds 3}
          else
          {
            #$last_line = Get-Content -Path $legendary_logfile -force -Tail 1 2> $Null
            #Watch the log file and output all new lines. If the new line matches our exit trigger text, break out of wait
            $count = 0
            Get-Content -Path $spicetifyrestorebackup_logfile -force -Tail 1 -wait -Encoding utf8 | ForEach-Object {
              $count++
              Write-EZLogs "$($_)" -showtime
              $pattern1 = 'Download	- (?<value>.*) MiB\/s \(raw\)'
              $pattern2 = 'Install size: (?<value>.*) MiB'               
              if($_ -match 'Spotify is spiced up!'){
                $spicetifyexit_code = $_ 
              break}  
              #if($_ -match 'Number of applicable updates for the current system configuration:'){ $dellupdates_code = $_.Substring(($_.IndexOf('configuration: ')+15))}
              if($break){break}
              if($(Get-Job -State Running).count -eq 0){write-ezlogs 'Ended due to job ending, loop once more then break'
                $break = $true
              }
            }
          }      
        }  
        #Get information from each job.
        foreach($job in Get-Job)
        {$info = Receive-Job -Id ($job.Id)}
  
        #Remove all jobs created.
        Get-Job | Remove-Job -Force 
        Write-EZLogs '---------------END Log Entries---------------' -enablelogs
        Write-EZLogs ">>>> Spicetify. Final loop count: $count" -showtime  -color Cyan              
        write-ezlogs " | Spicetify result: $spicetifyexit_code" -showtime        
        
        try{
          write-ezlogs '>>>> Launching Spotify and letting it check for updates with argument --allow-upgrades --update-immediately'
          if([System.IO.File]::Exists("$($env:appdata)\\Spotify\\Spotify.exe")){
            $spotifyprocess = Start-Process "$($env:appdata)\\Spotify\\Spotify.exe" -ArgumentList '--allow-upgrades --minimized --update-immediately'
            Start-Sleep 1
          }else{write-ezlogs "Unable to find Spotify exe at path $($env:appdata)\\Spotify\\Spotify.exe" -showtime -warning}
          if(Get-Process Spotify* -ErrorAction SilentlyContinue){
            write-ezlogs ' | Waiting for Spotify to open and run...' -showtime
            Start-Sleep 5
            write-ezlogs ' | Closing and reopening Spotify' -showtime 
            Get-Process Spotify* -ErrorAction SilentlyContinue | Stop-Process -Force
            Start-Sleep 1
            $spotifyprocess = Start-Process "$($env:appdata)\\Spotify\\Spotify.exe" -ArgumentList '--allow-upgrades --minimized --update-immediately'
            Start-Sleep 2
          }
        }catch{write-ezlogs 'An exception occurred launching Spotify' -showtime -catcherror $_}

        #spicetify backup apply
        write-ezlogs ' | Executing Spicetify backup apply' -showtime        
        $spicetifybackupapply_logfile = "$env:temp\\spicetify_backupapply.log"
        if([System.IO.FIle]::Exists($spicetifybackupapply_logfile)){$null = Remove-Item $spicetifybackupapply_logfile -Force}
        $command = "& `"spicetify`" backup apply *>$spicetifybackupapply_logfile"   
        $block = 
        {
          Param
          (
            $command
      
          )
          $console_output_array = Invoke-Expression $command -ErrorAction SilentlyContinue     
        }   
        #Remove all jobs and set max threads
        Get-Job | Remove-Job -Force
        $MaxThreads = 3
  
        #Start the jobs. Max 4 jobs running simultaneously.
        While ($(Get-Job -state running).count -ge $MaxThreads)
        {Start-Sleep -Milliseconds 3}
        Write-EZLogs ">>>> Executing Spicetify`n" -showtime -color cyan
        $null = Start-Job -Scriptblock $block -ArgumentList $command -ErrorAction SilentlyContinue -Verbose
        Write-EZLogs '-----------Spicetify Log Entries-----------'            
        #Wait for all jobs to finish.
        $break = $false
        While ($(Get-Job -State Running).count -gt 0 -or (Get-Process Spicetify* -ErrorAction SilentlyContinue))
        {
          #Check last line of the log, if it matches our exit trigger text, sleep until it changes indicating new log entries are being added
          if (!([System.IO.FIle]::Exists($spicetifybackupapply_logfile)))
          {Start-Sleep -Milliseconds 3}
          else
          {
            #$last_line = Get-Content -Path $legendary_logfile -force -Tail 1 2> $Null
            #Watch the log file and output all new lines. If the new line matches our exit trigger text, break out of wait
            $count = 0
            Get-Content -Path $spicetifybackupapply_logfile -force -Tail 1 -wait -Encoding utf8 | ForEach-Object {
              $count++
              Write-EZLogs "$($_)" -showtime
              $pattern1 = 'Download	- (?<value>.*) MiB\/s \(raw\)'
              $pattern2 = 'Install size: (?<value>.*) MiB'               
              if($_ -match 'Spotify is spiced up!'){
                $spicetifyexit_code = $_ 
              break}  
              #if($_ -match 'Number of applicable updates for the current system configuration:'){ $dellupdates_code = $_.Substring(($_.IndexOf('configuration: ')+15))}
              if($break){break}
              if($(Get-Job -State Running).count -eq 0){write-ezlogs 'Ended due to job ending, loop once more then break'
                $break = $true
              }
            }
          }      
        }  
        #Get information from each job.
        foreach($job in Get-Job)
        {$info = Receive-Job -Id ($job.Id)}
  
        #Remove all jobs created.
        Get-Job | Remove-Job -Force 
        Write-EZLogs '---------------END Log Entries---------------' -enablelogs
        Write-EZLogs ">>>> Spicetify. Final loop count: $count" -showtime  -color Cyan              
        write-ezlogs " | Spicetify result: $spicetifyexit_code" -showtime

        write-ezlogs ' | Applying Spicetify customizations' -showtime
        spicetify.exe config inject_css 0 replace_colors 0
        spicetify.exe config extensions webnowplaying.js     
        
        $spicetifyapply_logfile = "$env:temp\\spicetify_apply.log"
        if([System.IO.FIle]::Exists($spicetifyapply_logfile)){$null = Remove-Item $spicetifyapply_logfile -Force}
        $command = "& `"spicetify`" apply *>$spicetifyapply_logfile"   
        $block = 
        {
          Param
          (
            $command
      
          )
          $console_output_array = Invoke-Expression $command -ErrorAction SilentlyContinue     
        }   
        #Remove all jobs and set max threads
        Get-Job | Remove-Job -Force
        $MaxThreads = 3
  
        #Start the jobs. Max 4 jobs running simultaneously.
        While ($(Get-Job -state running).count -ge $MaxThreads)
        {Start-Sleep -Milliseconds 3}
        Write-EZLogs ">>>> Executing Spicetify`n" -showtime -color cyan
        $null = Start-Job -Scriptblock $block -ArgumentList $command -ErrorAction SilentlyContinue -Verbose
        Write-EZLogs '-----------Spicetify Log Entries-----------'            
        #Wait for all jobs to finish.
        $break = $false
        While ($(Get-Job -State Running).count -gt 0 -or (Get-Process Spicetify* -ErrorAction SilentlyContinue))
        {
          #Check last line of the log, if it matches our exit trigger text, sleep until it changes indicating new log entries are being added
          if (!([System.IO.FIle]::Exists($spicetifyapply_logfile)))
          {Start-Sleep -Milliseconds 3}
          else
          {
            #$last_line = Get-Content -Path $legendary_logfile -force -Tail 1 2> $Null
            #Watch the log file and output all new lines. If the new line matches our exit trigger text, break out of wait
            $count = 0
            Get-Content -Path $spicetifyapply_logfile -force -Tail 1 -wait -Encoding utf8 | ForEach-Object {
              $count++
              Write-EZLogs "$($_)" -showtime
              $pattern1 = 'Download	- (?<value>.*) MiB\/s \(raw\)'
              $pattern2 = 'Install size: (?<value>.*) MiB'               
              if($_ -match 'Spotify is spiced up!'){
                $spicetifyexit_code = $_ 
              break}  
              #if($_ -match 'Number of applicable updates for the current system configuration:'){ $dellupdates_code = $_.Substring(($_.IndexOf('configuration: ')+15))}
              if($break){break}
              if($(Get-Job -State Running).count -eq 0){write-ezlogs 'Ended due to job ending, loop once more then break'
                $break = $true
              }
            }
          }      
        }  
        #Get information from each job.
        foreach($job in Get-Job)
        {$info = Receive-Job -Id ($job.Id)}
  
        #Remove all jobs created.
        Get-Job | Remove-Job -Force 
        Write-EZLogs '---------------END Log Entries---------------' -enablelogs
        Write-EZLogs ">>>> Spicetify. Final loop count: $count" -showtime  -color Cyan              
        write-ezlogs " | Spicetify result: $spicetifyexit_code" -showtime

        Add-Member -InputObject $thisapp.config -Name 'PODE_SERVER_ACTIVE' -Value $true -MemberType NoteProperty -Force      
        $Variable_list = Get-Variable | where {$_.Options -notmatch 'ReadOnly' -and $_.Options -notmatch 'Constant'}
        Start-Runspace -scriptblock $pode_server_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -Load_Modules -Script_Modules $Script_Modules -runspace_name 'PODE_SERVER_RUNSPACE'       
        $synchash.Spicetify_textblock.text = '[SUCCESS] Successfully applied Spicetify customizations to Spotify! The Spotify app should have launched' 
        $synchash.Spicetify_textblock.foreground = 'LightGreen'
        $synchash.Spicetify_textblock.FontSize = 14
        $synchash.Spicetify_transitioningControl.content = $synchash.Spicetify_textblock                        
      }
      catch
      {write-ezlogs 'An error occurred while applying Spicetify customizations' -showtime -catcherror $_}                   
    }else{
      Add-Member -InputObject $thisapp.config -Name 'Use_Spicetify' -Value $false -MemberType NoteProperty -Force
      try
      {                     
        write-ezlogs '>>>> Removing Spicetify customizations' -Color cyan -showtime
        #spicetify restore backup
        #spicetify apply    
        $spicetifyrestorebackup_logfile = "$env:temp\\spicetify_restorebackup.log"
        if([System.IO.FIle]::Exists($spicetifyrestorebackup_logfile)){$null = Remove-Item $spicetifyrestorebackup_logfile -Force}
        $command = "& `"spicetify`" restore backup *>$spicetifyrestorebackup_logfile"   
        $block = 
        {
          Param
          (
            $command
      
          )
          $console_output_array = Invoke-Expression $command -ErrorAction SilentlyContinue     
        }   
        #Remove all jobs and set max threads
        Get-Job | Remove-Job -Force
        $MaxThreads = 3
  
        #Start the jobs. Max 4 jobs running simultaneously.
        While ($(Get-Job -state running).count -ge $MaxThreads)
        {Start-Sleep -Milliseconds 3}
        Write-EZLogs ">>>> Executing Spicetify`n" -showtime -color cyan
        $null = Start-Job -Scriptblock $block -ArgumentList $command -ErrorAction SilentlyContinue -Verbose
        Write-EZLogs '-----------Spicetify Log Entries-----------'            
        #Wait for all jobs to finish.
        $break = $false
        While ($(Get-Job -State Running).count -gt 0 -or (Get-Process Spicetify* -ErrorAction SilentlyContinue))
        {
          #Check last line of the log, if it matches our exit trigger text, sleep until it changes indicating new log entries are being added
          if (!([System.IO.FIle]::Exists($spicetifyrestorebackup_logfile)))
          {Start-Sleep -Milliseconds 3}
          else
          {
            #$last_line = Get-Content -Path $legendary_logfile -force -Tail 1 2> $Null
            #Watch the log file and output all new lines. If the new line matches our exit trigger text, break out of wait
            $count = 0
            Get-Content -Path $spicetifyrestorebackup_logfile -force -Tail 1 -wait -Encoding utf8 | ForEach-Object {
              $count++
              Write-EZLogs "$($_)" -showtime
              $pattern1 = 'Download	- (?<value>.*) MiB\/s \(raw\)'
              $pattern2 = 'Install size: (?<value>.*) MiB'               
              if($_ -match 'Spotify is spiced up!'){
                $spicetifyexit_code = $_ 
              break}  
              #if($_ -match 'Number of applicable updates for the current system configuration:'){ $dellupdates_code = $_.Substring(($_.IndexOf('configuration: ')+15))}
              if($break){break}
              if($(Get-Job -State Running).count -eq 0){write-ezlogs 'Ended due to job ending, loop once more then break'
                $break = $true
              }
            }
          }      
        }  
        #Get information from each job.
        foreach($job in Get-Job)
        {$info = Receive-Job -Id ($job.Id)}
  
        #Remove all jobs created.
        Get-Job | Remove-Job -Force 
        Write-EZLogs '---------------END Log Entries---------------' -enablelogs
        Write-EZLogs ">>>> Spicetify. Final loop count: $count" -showtime  -color Cyan              
        write-ezlogs " | Spicetify result: $spicetifyexit_code" -showtime 

        Add-Member -InputObject $thisapp.config -Name 'PODE_SERVER_ACTIVE' -Value $false -MemberType NoteProperty -Force
        if((NETSTAT.EXE -n) | where {$_ -match '127.0.0.1:8974'}){Invoke-RestMethod -Uri 'http://127.0.0.1:8974/CLOSEPODE' -UseBasicParsing -ErrorAction SilentlyContinue}       
        $synchash.Spicetify_textblock.text = '[SUCCESS] Successfully removed Spicetify customizations to Spotify! The Spotify app should have launched' 
        $synchash.Spicetify_textblock.foreground = 'LightGreen'
        $synchash.Spicetify_textblock.FontSize = 14
        $synchash.Spicetify_transitioningControl.content = $synchash.Spicetify_textblock                        
      }
      catch
      {write-ezlogs 'An error occurred while applying Spicetify customizations' -showtime -catcherror $_}
    }   
    if(Get-Process *Spotify* -ErrorAction SilentlyContinue){Get-Process *Spotify* | Stop-Process -Force -ErrorAction SilentlyContinue}     
    #Start on windows logon
    $synchash.Start_On_Windows_transitioningControl.content = ''
    if($synchash.Start_On_Windows_Login_Toggle.isOn){
      if(-not [string]::IsNullOrEmpty($synchash.App_Exe_Path_textbox.text) -and [System.IO.File]::Exists($synchash.App_Exe_Path_textbox.text)){
        if(($synchash.App_Exe_Path_textbox.text | Split-Path -Leaf) -match $thisScript.Name){
          Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $true -MemberType NoteProperty -Force
          Add-Member -InputObject $thisapp.config -Name 'App_Exe_Path' -Value $synchash.App_Exe_Path_textbox.text -MemberType NoteProperty -Force
          if((Get-ScheduledTask -TaskName "$($thisScript.name) - Startup" -ErrorAction SilentlyContinue).actions.execute -eq "$($thisapp.config.App_Exe_Path)"){
            write-ezlogs "The app $($thisScript.name) is already configured to start on Windows logon." -Warning -showtime           
            if((Get-ScheduledTask -TaskName "$($thisScript.name) - Startup" -ErrorAction SilentlyContinue).State -eq 'Disabled'){
              write-ezlogs 'Scheduled task is currently disabled -- Enabling' -showtime
              $null = Enable-ScheduledTask -TaskName "$($thisScript.name) - Startup" -ErrorAction SilentlyContinue
              $synchash.Start_On_Windows_textblock.text = "[Info] The app $($thisScript.name) is already configured to start on Windows logon, but was disabled. Now has been enabled!"
            }else{$synchash.Start_On_Windows_textblock.text = "[Info] The app $($thisScript.name) is already configured to start on Windows logon."}
            $synchash.Start_On_Windows_textblock.foreground = 'Cyan'
            $synchash.Start_On_Windows_textblock.FontSize = 14
            $synchash.Start_On_Windows_transitioningControl.content = $synchash.Start_On_Windows_textblock            
          }
          else
          {
            try
            {
              Register-ScheduledTask -TaskName "$($thisScript.name) - Startup" -Trigger (New-ScheduledTaskTrigger -AtLogOn) -Action (New-ScheduledTaskAction -Execute $thisapp.config.App_Exe_Path) -RunLevel Highest -Force -Verbose:$thisapp.Config.Verbose_logging
              $synchash.Start_On_Windows_textblock.text = "[SUCCESS] The app $($thisScript.name) has been successfully configured to start automatically upon logon to Windows (any user)"
              $synchash.Start_On_Windows_textblock.foreground = 'LightGreen'
              $synchash.Start_On_Windows_textblock.FontSize = 14
              $synchash.Start_On_Windows_transitioningControl.content = $synchash.Start_On_Windows_textblock              
            }
            catch
            {
              write-ezlogs "An exception occurred attempting to configure a new scheduled task at logon for $($thisapp.config.App_Exe_Path)" -CatchError $_ -showtime -enablelogs
              Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $false -MemberType NoteProperty -Force
              $synchash.Start_On_Windows_Login_Toggle.isOn = $false
              $synchash.Start_On_Windows_textblock.text = "[ERROR] An exception occurred attempting to configure a new scheduled task at logon for $($thisapp.config.App_Exe_Path) -- Please check log for more details"
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
          write-ezlogs "The App Exe path entered does not appear to be for $($thisScript.name). Please choose a valid exe file for $($thisScript.name) that you have full access to." -Warning  -showtime
          $synchash.Start_On_Windows_textblock.text = "[Warning] The App Exe path entered does not appear to be for $($thisScript.name). Please choose a valid exe file for $($thisScript.name) that you have full access to."
          $synchash.Start_On_Windows_textblock.foreground = 'Orange'
          $synchash.Start_On_Windows_textblock.FontSize = 14
          $synchash.Start_On_Windows_transitioningControl.content = $synchash.Start_On_Windows_textblock
          if((Get-ScheduledTask -TaskName "$($thisScript.name) - Startup" -ErrorAction SilentlyContinue)){
            try
            {
              Unregister-ScheduledTask -TaskName "$($thisScript.name) - Startup" -Confirm:$false -Verbose:$thisapp.Config.Verbose_logging 
              Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $false -MemberType NoteProperty -Force
              write-ezlogs "Removed app $($thisScript.name) from starting on Windows logon." -color cyan  -showtime          
            }
            catch
            {
              write-ezlogs "An exception occurred attempting to unregister startup task for task name: $($thisScript.name) - Startup" -CatchError $_ -showtime -enablelogs
              $synchash.Start_On_Windows_Login_Toggle.isOn = $false       
            }
          }                    
        }
        write-ezlogs ">>>> Saving App Exe Path setting $($thisapp.config.App_Exe_Path)" -color cyan -showtime
        write-ezlogs ">>>> Saving setting '$($synchash.Start_On_Windows_Login_Toggle.content) - $($thisapp.config.Start_On_Windows_Login)' " -color cyan -showtime
      }
      else{
        write-ezlogs "The App Exe path entered is not valid. Please choose a valid exe file for $($thisScript.name) that you have full access to." -Warning  -showtime 
        Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $false -MemberType NoteProperty -Force
        $synchash.Start_On_Windows_textblock.text = "[Warning] The App Exe path entered is not valid. Please choose a valid exe file for $($thisScript.name) that you have full access to."
        $synchash.Start_On_Windows_textblock.foreground = 'Orange'
        $synchash.Start_On_Windows_textblock.FontSize = 14
        $synchash.Start_On_Windows_transitioningControl.content = $synchash.Start_On_Windows_textblock        
        if((Get-ScheduledTask -TaskName "$($thisScript.name) - Startup" -ErrorAction SilentlyContinue)){
          try
          {
            Unregister-ScheduledTask -TaskName "$($thisScript.name) - Startup" -Confirm:$false -Verbose:$thisapp.Config.Verbose_logging 
            Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $false -MemberType NoteProperty -Force
            write-ezlogs "Removed app $($thisScript.name) from starting on Windows logon." -color cyan  -showtime          
          }
          catch
          {
            write-ezlogs "An exception occurred attempting to unregister startup task for task name: $($thisScript.name) - Startup" -CatchError $_ -showtime -enablelogs
            $synchash.Start_On_Windows_Login_Toggle.isOn = $false       
          }
        }        
      }
    }
    else
    {
      if((Get-ScheduledTask -TaskName "$($thisScript.name) - Startup" -ErrorAction SilentlyContinue)){
        try
        {
          Unregister-ScheduledTask -TaskName "$($thisScript.name) - Startup" -Confirm:$false -Verbose:$thisapp.Config.Verbose_logging 
          Add-Member -InputObject $thisapp.config -Name 'Start_On_Windows_Login' -Value $false -MemberType NoteProperty -Force
          write-ezlogs "Removed app $($thisScript.name) from starting on Windows logon." -color cyan  -showtime
          $synchash.Start_On_Windows_textblock.text = "[SUCCESS] Removed app $($thisScript.name) from starting on Windows logon."
          $synchash.Start_On_Windows_textblock.foreground = 'LightGreen'
          $synchash.Start_On_Windows_textblock.FontSize = 14
          $synchash.Start_On_Windows_transitioningControl.content = $synchash.Start_On_Windows_textblock           
        }
        catch
        {
          write-ezlogs "An exception occurred attempting to unregister startup task for task name: $($thisScript.name) - Startup" -CatchError $_ -showtime -enablelogs
          $synchash.Start_On_Windows_Login_Toggle.isOn = $false
          $synchash.Start_On_Windows_textblock.text = "[ERROR] An exception occurred attempting to unregister startup task for task name: $($thisScript.name) - Startup -- Please check log for more details"
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
      try{Start-TwitchMonitor -Interval $thisapp.config.Twitch_Update_Interval -thisApp $thisapp -all_playlists $all_playlists -synchash $synchash -Verboselog}catch{write-ezlogs 'An exception occurred starting Start-TwitchMonitor' -showtime -catcherror $_}
    }else{Add-Member -InputObject $thisapp.config -Name 'Twitch_Update' -Value $false -MemberType NoteProperty -Force} 
    try{$thisapp.config | Export-Clixml -Path $App_Settings_File_Path -Force -Encoding UTF8}catch{write-ezlogs "An exception occurred saving settings to config file: $($App_Settings_File_Path)" -CatchError $_ -showtime}   
    close-splashscreen
    $synchash.Window.show()
    #if(!$thisApp.Config.Spicetify.is_paused){
    #  $synchash.timer.start()
    #}
    #$progress_dialog.ContinueWith()
    #$progress_dialog.ConfigureAwait($false)
})

#---------------------------------------------- 
#endregion Apply Settings
#----------------------------------------------
if($startup_perf_timer){write-ezlogs " | Seconds to UI Controls: $($startup_stopwatch.Elapsed.TotalSeconds)" -showtime}
#############################################################################
#endregion Form Button Logic
#############################################################################

#############################################################################
#region Execution and Output 
############################################################################# 
#---------------------------------------------- 
#region Window Close
#----------------------------------------------
$synchash.Window.Add_Closed({
    try
    {
      $synchash.VLC.stop()
      $synchash.VLC.Dispose()
      #$libvlc.CloseLogFile()
      #$libvlc.dispose()    
      #$synchash.VLC.stop()
      $thisapp.Config.Spicetify = ''
      $Spotify_process = Get-Process 'Spotify*' -ErrorAction SilentlyContinue
      if($Spotify_process){Stop-Process $Spotify_process -Force}
      $streamlink_process = Get-Process '*streamlink*' -ErrorAction SilentlyContinue
      if($streamlink_process){Stop-Process $streamlink_process -Force}         
    }
    catch
    {
      Write-Output "[$(Get-Date -Format $logdateformat)]: [ERROR] An exception occurred during add_closed cleanup. $($_ | Out-String)"
      if($enablelogs){"[$(Get-Date -Format $logdateformat)]: [ERROR] An exception occurred during add_closed cleanup. $($_ | Out-String)" | Out-File -FilePath $logfile -Append -Encoding unicode}
    }
    try
    {
      $thisapp.config | Export-Clixml -Path $App_Settings_File_Path -Force -Encoding UTF8    
      if($thisapp.Config.Verbose_logging){
        Write-Output "[$(Get-Date -Format $logdateformat)]: Halting runspace cleanup job processing" -OutVariable message
        if($enablelogs){$Message | Out-File -FilePath $logfile -Encoding unicode -Append}
        Write-Output "[$(Get-Date -Format $logdateformat)]: Calling garbage collector" -OutVariable message
        if($enablelogs){$Message | Out-File -FilePath $logfile -Encoding unicode -Append}  
      }
      $jobCleanup.Flag = $false      
      #Stop all runspaces
      $jobCleanup.PowerShell.Dispose() 
      [GC]::Collect()    
      
      #close podeserver
      if((NETSTAT.EXE -n) | where {$_ -match '127.0.0.1:8974'}){Invoke-RestMethod -Uri 'http://127.0.0.1:8974/CLOSEPODE' -UseBasicParsing -ErrorAction SilentlyContinue}       
    }
    catch
    {
      Write-Output "[$(Get-Date -Format $logdateformat)]: [ERROR] An exception occurred during add_closed cleanup. $($_ | Out-String)"
      "[$(Get-Date -Format $logdateformat)]: [ERROR] An exception occurred during add_closed cleanup. $($_ | Out-String)" | Out-File -FilePath $logfile -Append -Encoding unicode
    }
    #---------------------------------------------- 
    #region Stop Logging
    #----------------------------------------------
    Stop-EZlogs -ErrorSummary $error -clearErrors -stoptimer -logOnly -logfile $logfile -enablelogs
    #---------------------------------------------- 
    #endregion Stop Logging
    #----------------------------------------------     
    exit
})
#Add Exit
$synchash.Window.Add_Closing({
    $synchash.timer.stop()
    [System.Windows.Forms.Application]::Exit()   
    if(!$PSCommandPath)
    {Stop-Process $pid}
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
  $ErrorProvider = New-Object -TypeName System.Windows.Forms.ErrorProvider

  # Allow input to window for TextBoxes, etc
  [System.Windows.Forms.Integration.ElementHost]::EnableModelessKeyboardInterop($synchash.Window)
  [void][System.Windows.Forms.Application]::EnableVisualStyles()
  $synchash.Window.Show()
  $window_active = $synchash.Window.Activate()
  #Start Keywatcher
  Start-KeyWatcher -synchash $synchash -thisApp $thisapp -PlayMedia_Command $PlayMedia_Command -Script_Modules $Script_Modules -all_playlists $all_playlists


  close-splashscreen
  $startup_timer_msg = " | Total Seconds to startup: $($startup_stopwatch.Elapsed.TotalSeconds)`n----------------------------------------------------------"
  write-ezlogs "$($confirm_requirements_msg | Out-String)$($load_module_msg | Out-String)$startup_timer_msg" -Color cyan -enablelogs
  $synchash.Error = $error
}catch{
  Write-Verbose -Message "[$(Get-Date -Format $logdateformat)]: [ERROR] An exception occurred. : $($_ | Out-String)"
  "[$(Get-Date -Format $logdateformat)]: [ERROR] An exception occurred. : $($_ | Out-String)" | Out-File -FilePath $logfile -Encoding unicode -Append -Force
}
try{
  $appContext = New-Object System.Windows.Forms.ApplicationContext 
  [void][System.Windows.Forms.Application]::Run($appContext)
}catch{
  Write-Verbose -Message "[$(Get-Date -Format $logdateformat)]: [ERROR] An exception occurred and main ApplicationContext ended : $($_ | Out-String)"
  "[$(Get-Date -Format $logdateformat)]: [ERROR] An exception occurred and main ApplicationContext ended. : $($_ | Out-String)" | Out-File -FilePath $logfile -Encoding unicode -Append -Force
  Write-Verbose -Message "[$(Get-Date -Format $logdateformat)]: | Trying to recover by starting another ApplicationContext"
  "[$(Get-Date -Format $logdateformat)]: | Trying to recover by starting another ApplicationContext" | Out-File -FilePath $logfile -Encoding unicode -Append -Force
  [void][System.Windows.Forms.Application]::Run($appContext)
}

#---------------------------------------------- 
#endregion Display Main Window
#----------------------------------------------


#############################################################################
#endregion Execution and Output Functions
#############################################################################