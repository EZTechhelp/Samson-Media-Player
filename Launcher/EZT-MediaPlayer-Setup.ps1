<#
    .Name
    EZT-MediaPlayer-Setup

    .Version 
    0.3.4

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
$App_Settings_Directory = "$env:APPDATA\\EZT-MediaPlayer"
#$Required_modules = 'Get-LoadScreen','Start-Runspace','Write-EZLogs','Get-HelperFunctions'
$DateTimeFormat = 'MM/dd/yyyy h:mm:ss tt'
#$logfile = "$env:temp\\EZT-MediaPlayer-SETUP.log"
$enablelogs = 1 # enables creating a log file of executed actions, run history and errors. 1 = Enable, 0 (or anything else) = Disable
$logfile_directory = 'C:\Logs\' # directory where log file should be created if enabled
$hide_Console = $true
$use_runas = $false
$temp_log = "$env:temp\\EZT-MediaPlayer-SETUP.log"
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
        Write-output "[$([datetime]::Now.ToString($DateTimeFormat))] Script not running as admin, relaunching with elevated permissions" | out-file $temp_log -Append -Encoding utf8
        $arg = "-NoProfile -ExecutionPolicy Bypass -file `"$($PSCommandPath)`"" 
        if([System.IO.File]::Exists("$env:programfiles\PowerShell\7\pwsh.exe")){
          Write-Host -Object "[$(Get-date -format $DateTimeFormat)] >>>> Relaunching setup using Powershell 7 (Path: $env:programfiles\PowerShell\7\pwsh.exe) with arguments: $($arg | out-string)";if($enablelogs){"[$(Get-date -format $DateTimeFormat)] >>>> Relaunching setup using Powershell 7 (Path: $env:programfiles\PowerShell\7\pwsh.exe) with arguments: $($arg | out-string)" | Out-File -FilePath $temp_log -Encoding utf8 -Append -Force}
          $process = Start-Process "$env:programfiles\PowerShell\7\pwsh.exe" -Verb Runas -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden     
          Write-Host -Object "[$(Get-date -format $DateTimeFormat)] | Process started: $($process | out-string)";if($enablelogs){"[$(Get-date -format $DateTimeFormat)] | Process started: $($process | out-string)" | Out-File -FilePath $temp_log -Encoding utf8 -Append -Force}
          while([system.io.file]::Exists("$Current_Folder\\EZT-MediaPlayer.zip")){
            start-sleep 1
          }
          exit
        }else{          
          write-output "[$([datetime]::Now.ToString($DateTimeFormat))] >>>> Relaunching setup using Powershell (Path: $psHome\powershell.exe) with arguments: $($arg | out-string)" | out-file $temp_log -Force -Append -Encoding utf8
          Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden  
          write-output "[$([datetime]::Now.ToString($DateTimeFormat))] | Process started: $($process | out-string)" | out-file $temp_log -Force -Append -Encoding utf8
          while([system.io.file]::Exists("$Current_Folder\\EZT-MediaPlayer.zip")){
            start-sleep 1
          }
          exit                     
        }       
        #Write-output "[$([datetime]::Now.ToString($DateTimeFormat))] Executing $psHome\powershell.exe with args ($arg) " | out-file $temp_log -Append
        #Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction Continue -Wait -WindowStyle Hidden
      } 
      catch { 
        Write-output "[$([datetime]::Now.ToString($DateTimeFormat))] Error - Failed to restart script with runas - $_" | out-file $temp_log -Append -Encoding utf8
        #exit               
      } 
      exit # Quit this session of powershell 
    }  
  }  
  else  {  
    Write-output "[$([datetime]::Now.ToString($DateTimeFormat))] Script must be saved as a .ps1 file first" | out-file $temp_log -Append -Encoding utf8
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
if($hide_Console){
  Hide-Console
}
$Global:logfile = $temp_log
write-output "#### Starting Setup for EZT-MediaPlayer ####`n" | out-file $temp_log -Force -Append -Encoding utf8
$Global:Current_Folder = $PSCommandPath | Split-path -Parent

if($use_runas){
  Use-RunAs
  $Verb = 'Verb Runas'
}
#$global:thisScript = Get-ThisScriptInfo -ScriptPath $PSCommandPath
if([System.IO.File]::Exists("$Current_Folder\\Version.txt")){
  try{
    $setup_version = [System.IO.File]::ReadAllLines("$Current_Folder\\Version.txt")
    write-output " | Setup Version: $setup_version" | out-file $temp_log -Force -Append -Encoding utf8
  }catch{
    write-output "[$([datetime]::Now.ToString($DateTimeFormat))] [LAUNCH-ERROR] An exception occurred reading $Current_Folder\\Version.txt $($_ | out-string)" | out-file $temp_log -Force -Append -Encoding utf8
  }
}

#$Assemblies = (Get-childitem "$Current_Folder" -Filter "*.dll" -Force -Recurse)
write-output "[$([datetime]::Now.ToString($DateTimeFormat))] | Current folder: $Current_Folder" | out-file $temp_log -Force -Append -Encoding utf8

try{
  #Detect install
  $install_properties = (Get-ItemProperty "Registry::\HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*") | where {$_.DisplayName -match 'EZT-MediaPlayer'}
  if($install_properties){
    $install_folder = $install_properties.InstallLocation
    $Main_Script = [System.IO.Path]::Combine($install_folder,'EZT-MediaPlayer.ps1')
    if([System.IO.File]::Exists($Main_Script)){
      $arg = "-NoProfile -ExecutionPolicy Bypass -windowstyle hidden -NonInteractive -NoLogo -file `"$Main_Script`""
      if([System.IO.File]::Exists("$env:programfiles\PowerShell\7\pwsh.exe")){
        if($use_runas){
          write-output "[$([datetime]::Now.ToString($DateTimeFormat))] >>>> Launching main script using Powershell 7 (Path: $env:programfiles\PowerShell\7\pwsh.exe) with arguments: -verb runas $($arg | out-string)" | out-file $temp_log -Force -Append -Encoding utf8
          Start-Process "$env:programfiles\PowerShell\7\pwsh.exe" -Verb Runas -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden
        }else{
          write-output "[$([datetime]::Now.ToString($DateTimeFormat))] >>>> Launching main script using Powershell 7 (Path: $env:programfiles\PowerShell\7\pwsh.exe) with arguments: $($arg | out-string)" | out-file $temp_log -Force -Append -Encoding utf8
          Start-Process "$env:programfiles\PowerShell\7\pwsh.exe" -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden
        }     
      }else{    
        if($use_runas){
          write-output "[$([datetime]::Now.ToString($DateTimeFormat))] >>>> Launching main script using Powershell (Path: $psHome\powershell.exe) with arguments: -verb Runas $($arg | out-string)" | out-file $temp_log -Force -Append -Encoding utf8
          Start-Process "$psHome\powershell.exe" -Verb Runas -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden
        }else{
          write-output "[$([datetime]::Now.ToString($DateTimeFormat))] >>>> Launching main script using Powershell (Path: $psHome\powershell.exe) with arguments: $($arg | out-string)" | out-file $temp_log -Force -Append -Encoding utf8
          Start-Process "$psHome\powershell.exe" -ArgumentList $arg -ErrorAction SilentlyContinue -WindowStyle Hidden
        }             
      }     
    }else{
      write-output "[$([datetime]::Now.ToString($DateTimeFormat))] [WARNING] >>>> Unable to find installed launcher or directory: $Main_Script" | out-file $temp_log -Force -Append -Encoding utf8
    }
  }
  foreach ($e in $error){
    write-output "[$([datetime]::Now.ToString($DateTimeFormat))] Error: $($e | out-string)" | out-file $temp_log -Force -Append -Encoding utf8
  }
  write-output "[$([datetime]::Now.ToString($DateTimeFormat))] Setup Execution Time: $($script:setup_startup_stopwatch.Elapsed.Minutes):$($script:setup_startup_stopwatch.Elapsed.Seconds):$($script:setup_startup_stopwatch.Elapsed.Milliseconds)" | out-file $temp_log -Force -Append -Encoding utf8 
  write-output "######## Exiting Setup ########" | out-file $temp_log -Force -Append -Encoding utf8
  if($pid){
    stop-process $pid -Force -ErrorAction SilentlyContinue
  }
  exit   
}
catch
{
  write-output "[$([datetime]::Now.ToString($DateTimeFormat))] [LAUNCH-ERROR] $($_ | out-string)" | out-file $temp_log -Force -Append -Encoding utf8
}
#############################################################################
#endregion Execution and Output 
#############################################################################