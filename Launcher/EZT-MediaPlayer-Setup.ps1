<#
    .Name
    EZT-MediaPlayer-Setup

    .Version 
    0.3.9

    .SYNOPSIS
    Launcher Script for EZT-MediaPlayer

    .DESCRIPTION
       
    .Configurable Variables:

    .Requirements
    - Powershell v3.0 or higher

    .EXAMPLE
    \EZT-MediaPlayer-Setup.ps1

    .OUTPUTS
    System.Management.Automation.PSObject

    .Credits

    .NOTES
    .Author
    EZTechhelp - https://www.eztechhelp.com

#> 
#############################################################################
#region Configurable Script Parameters
#############################################################################

#---------------------------------------------- 
#region Global Variables - DO NOT CHANGE UNLESS YOU KNOW WHAT YOU'R DOING
#----------------------------------------------
$script:setup_startup_stopwatch = [system.diagnostics.stopwatch]::StartNew()
$app_name = 'EZT-MediaPlayer'
$App_Settings_Directory = "$env:APPDATA\\$app_name"
#$Required_modules = 'Get-LoadScreen','Start-Runspace','Write-EZLogs','Get-HelperFunctions'
$DateTimeFormat = 'MM/dd/yyyy h:mm:ss tt'
$enablelogs = 1 # enables creating a log file of executed actions, run history and errors. 1 = Enable, 0 (or anything else) = Disable
$logfile_directory = "$env:appdata\$app_name\Logs" # directory where log file should be created if enabled
$hide_Console = $false
$use_runas = $false
$temp_log = "$logfile_directory\$app_name-Launcher.log"
#---------------------------------------------- 
#endregion Global Variables - DO NOT CHANGE UNLESS YOU KNOW WHAT YOU'R DOING
#----------------------------------------------

#############################################################################
#endregion Configurable Script Parameters
#############################################################################  

#############################################################################
#region global functions
#############################################################################
#---------------------------------------------- 
#region Test-RegistryValue Function
#----------------------------------------------
function Test-RegistryValue {
  <#
      .SYNOPSIS
      Function to test if registry value exists
		
      .Example
      Test-RegistryValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System" -Value "EnableLinkedConnections"

  #>
  param (

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]$Path,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]$Value
  )

  try {

    Get-ItemProperty -Path $Path | Select-Object -ExpandProperty $Value -ErrorAction Stop | Out-Null
    return $true
  }

  catch {

    return $false

  }

}
#---------------------------------------------- 
#endregion Test-RegistryValue Function
#----------------------------------------------

#---------------------------------------------- 
#region Show/Hide Console Functions
#----------------------------------------------
# .Net methods for hiding/showing the console in the background
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
  if ($MyInvocation.ScriptName -ne '') {  
    if (-not $IsAdmin)  {  
      try {  
        if($enablelogs){Write-output "[$([datetime]::Now.ToString($DateTimeFormat))] Script not running as admin, relaunching with elevated permissions" | out-file $temp_log -Append -Encoding unicode}
        $arg = "-NoProfile -ExecutionPolicy Bypass -file `"$($PSCommandPath)`"" 
        if([System.IO.File]::Exists("$env:programfiles\PowerShell\7\pwsh.exe")){
          Write-Host -Object "[$(Get-date -format $DateTimeFormat)] >>>> Relaunching setup using Powershell 7 (Path: $env:programfiles\PowerShell\7\pwsh.exe) with arguments: $($arg | out-string)";if($enablelogs){"[$(Get-date -format $DateTimeFormat)] >>>> Relaunching setup using Powershell 7 (Path: $env:programfiles\PowerShell\7\pwsh.exe) with arguments: $($arg | out-string)" | Out-File -FilePath $temp_log -Encoding unicode -Append -Force}
          $process = Start-Process "$env:programfiles\PowerShell\7\pwsh.exe" -Verb Runas -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden     
          Write-Host -Object "[$(Get-date -format $DateTimeFormat)] | Process started: $($process | out-string)";if($enablelogs){"[$(Get-date -format $DateTimeFormat)] | Process started: $($process | out-string)" | Out-File -FilePath $temp_log -Encoding unicode -Append -Force}
          exit
        }else{          
          if($enablelogs){write-output "[$([datetime]::Now.ToString($DateTimeFormat))] >>>> Relaunching setup using Powershell (Path: $psHome\powershell.exe) with arguments: $($arg | out-string)" | out-file $temp_log -Force -Append -Encoding unicode}
          Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden  
          if($enablelogs){write-output "[$([datetime]::Now.ToString($DateTimeFormat))] | Process started: $($process | out-string)" | out-file $temp_log -Force -Append -Encoding unicode}
          exit                     
        }       
      } 
      catch { 
        Write-output "[$([datetime]::Now.ToString($DateTimeFormat))] Error - Failed to restart script with runas - $($_ | select *)" | out-file $temp_log -Append -Encoding unicode             
      } 
      exit # Quit this session of powershell 
    }  
  }  
  else  {  
    Write-output "[$([datetime]::Now.ToString($DateTimeFormat))] Script must be saved as a .ps1 file first" | out-file $temp_log -Append -Encoding unicode
    exit  
  }  
}
#---------------------------------------------- 
#endregion Use Run-As Function
#----------------------------------------------
#############################################################################
#endregion global functions
#############################################################################

#############################################################################
#region Execution and Output 
#############################################################################

if(![System.IO.Directory]::Exists($logfile_directory)){
  $Null = New-item $logfile_directory -ItemType Directory -Force
}

if($hide_Console){
  Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
  '
  Hide-Console
}
if($enablelogs){write-output "#### Starting Launcher for $app_name ####" | out-file $temp_log -Force -Append -Encoding unicode}
$Global:Current_Folder = [System.IO.Path]::GetDirectoryName($PSCommandPath)

if($use_runas){
  Use-RunAs
  $Verb = 'Verb Runas'
}
if([System.IO.File]::Exists("$Current_Folder\\Version.txt")){
  try{
    $setup_version = [System.IO.File]::ReadAllLines("$Current_Folder\\Version.txt")
    if($enablelogs){write-output "[$([datetime]::Now.ToString($DateTimeFormat))] | Launcher Version: $setup_version" | out-file $temp_log -Force -Append -Encoding unicode}
  }catch{
    write-output "[$([datetime]::Now.ToString($DateTimeFormat))] [LAUNCH-ERROR] An exception occurred reading $Current_Folder\\Version.txt $($_ | select *)" | out-file $temp_log -Force -Append -Encoding unicode
  }
}
if($enablelogs){write-output "[$([datetime]::Now.ToString($DateTimeFormat))] | Current folder: $Current_Folder" | out-file $temp_log -Force -Append -Encoding unicode}

#---------------------------------------------- 
#region Detect Install and Launch
#----------------------------------------------
try{
  #Detect install
  #$install_properties = (Get-ItemProperty "Registry::\HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" -Filter 'EZT-MediaPlayer') | where {$_.DisplayName -match $app_name}
  $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default')
  $Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\").GetSubKeyNames() | foreach {    
    if($Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$_").GetValue('DisplayName') -match 'EZT-MediaPlayer'){
      $install_folder = $Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$_").GetValue('InstallLocation')
    }
  }   
  if(!$install_folder){
    $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('CurrentUser', 'Default')
    $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\").GetSubKeyNames() | foreach {    
      if($Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$_").GetValue('DisplayName') -match 'EZT-MediaPlayer'){
        $install_folder = $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$_").GetValue('InstallLocation')
      }
    } 
  }  
  if($install_folder){
    $Main_Script = [System.IO.Path]::Combine($install_folder,"$app_name.ps1")
    if([System.IO.File]::Exists($Main_Script)){
      if($process = (get-process *p*) | where {$_.MainWindowTitle -match "$app_name - Version:"}){
        write-output "[$([datetime]::Now.ToString($DateTimeFormat))] [WARNING] Existing Process with PID $($process.id) for ($app_name - Version: $setup_version) already running!`n[$([datetime]::Now.ToString($DateTimeFormat))] | CommandLine: $((Get-CimInstance win32_process | where {$_.ProcessId -eq $($process.id)}).CommandLine) " | out-file $temp_log -Force -Append -Encoding unicode
        [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        $oReturn=[System.Windows.Forms.MessageBox]::Show("[WARNING]`nExisting Process with PID $($process.id) for ($app_name - Version: $setup_version) already running!`n`nThis app will now close","$app_name",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) 
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
      $arg = "-NoProfile -ExecutionPolicy Bypass -windowstyle hidden -NoLogo -file `"$Main_Script`""
      if([System.IO.File]::Exists("$env:programfiles\PowerShell\7\pwsh.exe")){
        if($use_runas){
          if($enablelogs){write-output "[$([datetime]::Now.ToString($DateTimeFormat))] >>>> Launching main script using Powershell 7 (Path: $env:programfiles\PowerShell\7\pwsh.exe) with arguments: -verb runas $($arg | out-string)" | out-file $temp_log -Force -Append -Encoding unicode}
          Start-Process "$env:programfiles\PowerShell\7\pwsh.exe" -Verb Runas -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden
        }else{
          if($enablelogs){write-output "[$([datetime]::Now.ToString($DateTimeFormat))] >>>> Launching main script using Powershell 7 (Path: $env:programfiles\PowerShell\7\pwsh.exe) with arguments: $($arg | out-string)" | out-file $temp_log -Force -Append -Encoding unicode}
          Start-Process "$env:programfiles\PowerShell\7\pwsh.exe" -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden
        }     
      }else{    
        if($use_runas){
          if($enablelogs){write-output "[$([datetime]::Now.ToString($DateTimeFormat))] >>>> Launching main script using Powershell (Path: $psHome\powershell.exe) with arguments: -verb Runas $($arg | out-string)" | out-file $temp_log -Force -Append -Encoding unicode}
          Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden
        }else{
          if($enablelogs){write-output "[$([datetime]::Now.ToString($DateTimeFormat))] >>>> Launching main script using Powershell (Path: $psHome\powershell.exe) with arguments: $($arg | out-string)" | out-file $temp_log -Force -Append -Encoding unicode}
          Start-Process "$psHome\powershell.exe" -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden
        }             
      }     
    }else{
      write-output "[$([datetime]::Now.ToString($DateTimeFormat))] [WARNING] >>>> Unable to find installed launcher or directory: $Main_Script" | out-file $temp_log -Force -Append -Encoding unicode
    }
  }else{
    write-output "[$([datetime]::Now.ToString($DateTimeFormat))] [WARNING] >>>> Unable to find install folder from registry: $install_folder" | out-file $temp_log -Force -Append -Encoding unicode
  }
  if($error){
    write-output "[$([datetime]::Now.ToString($DateTimeFormat))] -----------------ALL ERRORS----------------" | out-file $temp_log -Force -Append -Encoding unicode
    foreach ($e in $error){
      write-output "[$([datetime]::Now.ToString($DateTimeFormat))] Error: $($e | out-string)" | out-file $temp_log -Force -Append -Encoding unicode
    }
  }

  write-output "[$([datetime]::Now.ToString($DateTimeFormat))] Launch Execution Time: $($script:setup_startup_stopwatch.Elapsed.Minutes):$($script:setup_startup_stopwatch.Elapsed.Seconds):$($script:setup_startup_stopwatch.Elapsed.Milliseconds)" | out-file $temp_log -Force -Append -Encoding unicode 
  if($enablelogs){write-output "######## Exiting Launcher ########" | out-file $temp_log -Force -Append -Encoding unicode}
  if($pid){
    stop-process $pid -Force -ErrorAction SilentlyContinue
  }
  exit   
}
catch
{
  write-output "[$([datetime]::Now.ToString($DateTimeFormat))] [LAUNCH-ERROR] $($_ | Select *)" | out-file $temp_log -Force -Append -Encoding unicode
}
#---------------------------------------------- 
#endregion Detect Install and Launch
#----------------------------------------------
#############################################################################
#endregion Execution and Output 
#############################################################################