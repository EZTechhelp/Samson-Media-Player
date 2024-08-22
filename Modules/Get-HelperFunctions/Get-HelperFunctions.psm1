<#
    .Name
    Get-HelperFunctions

    .Version 
    0.1.2

    .SYNOPSIS
    Collection of various helper functions for tasks like conversions, matching...etc

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
#region ConvertTo-OrderedDictionary Function
#----------------------------------------------
Function ConvertTo-OrderedDictionary {
  <#
      .SYNOPSIS
      Converts a HashTable, Array, or an OrderedDictionary to an OrderedDictionary.
 
      .DESCRIPTION
      ConvertTo-OrderedDictionary takes a HashTable, Array, or an OrderedDictionary
      and returns an ordered dictionary.
 
      If you enter a hash table, the keys in the hash table are ordered
      alphanumerically in the dictionary. If you enter an array, the keys
      are integers 0 - n.
      .PARAMETER $Hash
      Specifies a hash table or an array. Enter the hash table or array,
      or enter a variable that contains a hash table or array. If the input
      is an OrderedDictionary the key order is the same in the copy.
      .INPUTS
      System.Collections.Hashtable
      System.Array
      System.Collections.Specialized.OrderedDictionary
      .OUTPUTS
      System.Collections.Specialized.OrderedDictionary
      .NOTES
      source: https://gallery.technet.microsoft.com/scriptcenter/ConvertTo-OrderedDictionary-cf2404ba
      converted to function and added ability to copy OrderedDictionary
 
      .EXAMPLE
      PS C:\> $myHash = @{a=1; b=2; c=3}
      PS C:\> .\ConvertTo-OrderedDictionary.ps1 -Hash $myHash

 
  #>

  #Requires -Version 3

  [CmdletBinding(ConfirmImpact='None')]
  [OutputType('System.Collections.Specialized.OrderedDictionary')]
  Param (
    [parameter(Mandatory,HelpMessage='Add help message for user', ValueFromPipeline)]
    $Hash
  )

  begin {
    $dictionary = [ordered] @{}
  } #close begin block

  process {
    if ($Hash -is [System.Collections.Hashtable]) {
      foreach ($key in $Hash.keys | sort-object) {
        $dictionary.add($key, $Hash[$key])
      }
    }elseif ($Hash -is [System.Array] -or $Hash -is [System.Collections.ArrayList]) {
      for ($i = 0; $i -lt $hash.count; $i++) {
        $dictionary.add($i, $hash[$i])
      }
    }elseif ($Hash -is [System.Collections.Specialized.OrderedDictionary]) {
      $keys = $Hash.keys
      foreach ($key in $keys) {
        $dictionary.add($key, $Hash[$key])
      }
    }elseif ($Hash -is [System.Collections.SortedList]) {
      $keys = $Hash.keys
      foreach ($key in $keys) {
        $dictionary.add($key, $Hash[$key])
      }
    }else {
      write-ezlogs "No hash table, array, or ordered dictionary was provided to convert" -warning
    }
  }

  end {
    $dictionary
    #write-ezlogs ">>>> Ending: $($MyInvocation.Mycommand)" -Dev_mode
  } #close end block

} 
#---------------------------------------------- 
#endregion ConvertTo-OrderedDictionary Function
#----------------------------------------------

#---------------------------------------------- 
#region Convert-Color Function
#----------------------------------------------
function Convert-Color {
  <#
      .Synopsis
      This color converter gives you the hexadecimal values of your RGB colors and vice versa (RGB to HEX)
      .Description
      This color converter gives you the hexadecimal values of your RGB colors and vice versa (RGB to HEX). Use it to convert your colors and prepare your graphics and HTML web pages.
      .Parameter RBG
      Enter the Red Green Blue value comma separated. Red: 51 Green: 51 Blue: 204 for example needs to be entered as 51,51,204
      .Parameter HEX
      Enter the Hex value to be converted. Do not use the '#' symbol. (Ex: 3333CC converts to Red: 51 Green: 51 Blue: 204)
      .Example
      .\convert-color -hex FFFFFF
      Converts hex value FFFFFF to RGB
 
      .Example
      .\convert-color -RGB 123,200,255
      Converts Red = 123 Green = 200 Blue = 255 to Hex value
 
  #>
  param(
    [Parameter(ParameterSetName = "RGB", Position = 0)]
    [ValidateScript( {$_ -match '^([01]?[0-9]?[0-9]|2[0-4][0-9]|25[0-5])$'})]
    $RGB,
    [Parameter(ParameterSetName = "HEX", Position = 0)]
    [ValidateScript( {$_ -match '[A-Fa-f0-9]{6}'})]
    [string]
    $HEX
  )
  switch ($PsCmdlet.ParameterSetName) {
    "RGB" {
      if ($RGB[2] -eq $null) {
        Write-error "Value missing. Please enter all three values seperated by comma."
      }
      $red = [convert]::Tostring($RGB[0], 16)
      $green = [convert]::Tostring($RGB[1], 16)
      $blue = [convert]::Tostring($RGB[2], 16)
      if ($red.Length -eq 1) {
        $red = '0' + $red
      }
      if ($green.Length -eq 1) {
        $green = '0' + $green
      }
      if ($blue.Length -eq 1) {
        $blue = '0' + $blue
      }
      Write-Output $red$green$blue
    }
    "HEX" {
      $red = $HEX.Remove(2, 4)
      $Green = $HEX.Remove(4, 2)
      $Green = $Green.remove(0, 2)
      $Blue = $hex.Remove(0, 4)
      $Red = [convert]::ToInt32($red, 16)
      $Green = [convert]::ToInt32($green, 16)
      $Blue = [convert]::ToInt32($blue, 16)
      Write-Output $red, $Green, $blue
    }
  }
}
#---------------------------------------------- 
#endregion Convert-Color Function
#----------------------------------------------

#---------------------------------------------- 
#region Test-URL Function
#----------------------------------------------
function Test-URL
{
  Param(
    $address,
    [switch]$TestConnection,
    [int]$timeout_milsec
  )
  $uri = $address -as [System.URI]
  if($uri.AbsoluteURI -ne $null -and $uri.Scheme -match 'http|https'){
    if($TestConnection){
      Try{
        $HTTPRequest = [System.Net.WebRequest]::Create($address)
        if($timeout_milsec){
          $HTTPRequest.Timeout = $timeout_milsec
        }
        $HTTPResponse = $HTTPRequest.GetResponse()
        $HTTPStatus = [Int]$HTTPResponse.StatusCode
        
        If($HTTPStatus -ne 200 -and $HTTPStatus -ne 401) {
          Return $False
        }
        $HTTPResponse.Close()
      }
      Catch{
        if($_ -match '\(401\) Unauthorized'){
          return $true
        }else{
          Return $False
        }
      }	
      Return $True    
    }
    else{
      Return $true
    }    
  }
  else{
    return $false
  }
}
#---------------------------------------------- 
#endregion Test-URL Function
#----------------------------------------------

#---------------------------------------------- 
#region Test-ValidPath Function
#----------------------------------------------
function Test-ValidPath
{
  Param(
    $path,
    [ValidateNotNullOrEmpty()] [ValidateSet("File", "Directory", "URL", "Any", "URLorFile")] [string]$Type = "Any", 
    [switch]$ReturnType,
    [switch]$IncludeSpecialFolders,
    [switch]$TestConnection,
    [switch]$PingConnection,
    [int]$timeout_milsec = 100
  )
  if($type -eq 'File' -or $type -eq 'Any' -or $type -eq "URLorFile"){
    $isValidFile = [system.io.file]::Exists($path)
  }
  if($type -eq 'Directory' -or $type -eq 'Any'){
    if($IncludeSpecialFolders){
      $isValidDirectory = [system.io.Directory]::Exists($path)
    }else{
      $isValidDirectory = [system.io.Directory]::Exists($path) -and ![System.environment+SpecialFolder]::"$path"
    }    
  }
  if($type -eq 'URL' -or $type -eq 'Any' -or $type -eq "URLorFile"){
    #$urlpattern = "(http|ftp|https):\/\/([\w_-]+(?:(?:\.[\w_-]+)+))([\w.,@?^=%&:\/~+#-]*[\w@?^=%&\/~+#-])"
    $uri = $path -as [System.URI]
    if($PingConnection){
      try{
        $ping = [System.Net.NetworkInformation.Ping]::new()
        $internet_Connectivity = $ping.Send($path,$timeout_milsec)
      }catch{
        $isValidURL =  $False
      }finally{
        if($internet_Connectivity.Status -eq 'Success'){
          $isValidURL = $true
        }
        if($ping -is [System.IDisposable]){
          $ping.Dispose()
          $ping = $Null
        }
      }
    }elseif($uri.AbsoluteURI -ne $null -and $uri.Scheme -match 'http|https|ftp|ftps'){
      if($TestConnection){
        Try{
          $HTTPRequest = [System.Net.WebRequest]::Create($path)
          if($timeout_milsec){
            $HTTPRequest.Timeout = $timeout_milsec
          }
          $HTTPResponse = $HTTPRequest.GetResponse()
          $HTTPStatus = [Int]$HTTPResponse.StatusCode
        
          If($HTTPStatus -ne 200 -and $HTTPStatus -ne 401) {
            $isValidURL =  $False
          }
          $HTTPResponse.Close()
          $isValidURL =  $True    
        }Catch{
          if($_ -match '\(401\) Unauthorized'){
            $isValidURL =  $true
          }else{
            $isValidURL =  $False
          }
          if($HTTPResponse -is [System.IDisposable]){
            $HTTPResponse.Dispose()
          }
        }
      }else{
        $isValidURL =  $true
      }    
    }else{
      $isValidURL =  $false
    }
  }
  switch ($Type){
    'File'{
      if($ReturnType -and $isValidFile){        
        return 'File'
      }else{
        return $isValidFile
      } 
    }
    'Directory'{
      if($ReturnType -and $isValidDirectory){        
        return 'Directory'
      }else{
        return $isValidDirectory
      }     
    }
    'URL'{
      if($ReturnType -and $isValidURL){        
        return 'URL'
      }else{
        return $isValidURL
      }
    }
    'URLorFile'{
      if($isValidFile -or $isValidURL){
        if($ReturnType -and $isValidFile){        
          return 'File'
        }elseif($ReturnType -and $isValidURL){
          return 'URL'
        }else{
          return $true
        }      
      }else{
        return $false
      }
    }
    'Any'{
      if($isValidFile -or $isValidDirectory -or $isValidURL){
        if($ReturnType -and $isValidFile){        
          return 'File'
        }elseif($ReturnType -and $isValidDirectory){
          return 'Directory'
        }elseif($ReturnType -and $isValidURL){
          return 'URL'
        }else{
          return $true
        }      
      }else{
        return $false
      }
    }
  }
}
#---------------------------------------------- 
#endregion Test-ValidPath Function
#----------------------------------------------

#---------------------------------------------- 
#region Open-FolderDialog Function
#----------------------------------------------
function Open-FolderDialog
{
  param (
    [string]$Title,
    [switch]$MultiSelect,
    [string]$message,
    [string]$InitialDirectory
  )
  try{
    $Result =[FileSystemHelpers.FolderSelectDialog]::new($InitialDirectory,$title,$message,$MultiSelect).getPath()
    if ($Result) {
      return $Result
    }
  }catch{
    write-ezlogs "An exception occurred displaying Open-FolderDialog" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Open-FolderDialog Function
#----------------------------------------------

#---------------------------------------------- 
#region Open-FileDialog Function
#----------------------------------------------
function Open-FileDialog
{
  param (
    [string]$Title = "Select file",
    [string]$filter = "All Files (*.*)|*.*",
    [switch]$MultiSelect,
    [switch]$Overwrite = $true,
    [switch]$SaveDialog,
    [string]$InitialDirectory,
    [switch]$CheckPathExists
  )  
  $AssemblyFullName = 'System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'
  $Assembly = [System.Reflection.Assembly]::Load($AssemblyFullName)
  if($SaveDialog){
    $OpenFileDialog = [System.Windows.Forms.SaveFileDialog]::new()
    $OpenFileDialog.CheckFileExists = $false
    $OpenFileDialog.OverwritePrompt = $Overwrite
    $openFileDialog.SupportMultiDottedExtensions = $false
  }else{
    $OpenFileDialog = [System.Windows.Forms.OpenFileDialog]::new()
    $OpenFileDialog.CheckFileExists = $true
    $OpenFileDialog.Multiselect = $MultiSelect
    $OpenFileDialog.CheckPathExists = $CheckPathExists
  }
  $OpenFileDialog.AddExtension = $true
  #$OpenFileDialog.InitialDirectory = [environment]::getfolderpath('mydocuments')  
  $OpenFileDialog.InitialDirectory = $InitialDirectory
  $OpenFileDialog.Filter = $filter 
  $OpenFileDialog.Title = $Title
  $results = $OpenFileDialog.ShowDialog()
  if ($results -eq [System.Windows.Forms.DialogResult]::OK) 
  {
    $OpenFileDialog.FileNames
  }
}
#---------------------------------------------- 
#endregion Open-FileDialog Function
#----------------------------------------------

#--------------------------------------------- 
#region Get-CurrentWindows Function
#---------------------------------------------
function Get-CurrentWindows {
  <#
      .LINK
      https://stackoverflow.com/questions/46351885/how-to-grab-the-currently-active-foreground-window-in-powershell
  #>
  [CmdletBinding()]
  param(
    [switch]$GetForegroundOnly
  )
  Process {
    try{
      if($GetForegroundOnly){
        return [User32Wrapper.WindowHelper]::GetCurrentForegroundWindow()
      }
      return $([User32Wrapper.WindowHelper]::GetOpenWindows())
    }catch{
      write-ezlogs "An exception occurred getting open windows" -showtime -catcherror $_
    }

  }
}
#--------------------------------------------- 
#endregion Get-CurrentWindows Function
#---------------------------------------------

#--------------------------------------------- 
#region Set-DrawingControl Function
#---------------------------------------------
function Set-DrawingControl {
  <#
      .LINK
      https://stackoverflow.com/questions/487661/how-do-i-suspend-painting-for-a-control-and-its-children
  #>

  param(
    $SuspendDrawing,
    $ResumeDrawing
  )

  Begin {
    if(-not [bool]('DrawingControls' -as [Type])){
      Add-Type  @"
 using System;
 using System.Runtime.InteropServices;
 using System.Text;
 using System.Windows.Forms;
 using System.Collections.Generic; 

public class DrawingControls
{
    [DllImport("user32.dll")]
    public static extern int SendMessage(IntPtr hWnd, Int32 wMsg, bool wParam, Int32 lParam);

    private const int WM_SETREDRAW = 11; 
    
    public static void SuspendDrawing( Control parent )
    {
        SendMessage(parent.Handle, WM_SETREDRAW, false, 0);
    }

    public static void ResumeDrawing( Control parent )
    {
        SendMessage(parent.Handle, WM_SETREDRAW, true, 0);
        parent.Refresh();
    }
}
"@ -ReferencedAssemblies ("System.Windows.Forms", "System.ComponentModel.Primitives")
    }
  }
  Process {
    try{
      if($SuspendDrawing){
        return [DrawingControls]::SuspendDrawing($SuspendDrawing)
      }elseif($ResumeDrawing){
        return $([DrawingControls]::ResumeDrawing($ResumeDrawing))
      }      
    }catch{
      write-ezlogs "An exception occurred in Set-DrawingControl" -showtime -catcherror $_
    }

  }
}
#--------------------------------------------- 
#endregion Set-DrawingControl Function
#---------------------------------------------

#--------------------------------------------- 
#region Set-ChildWindow Function
#---------------------------------------------
function Set-ChildWindow {
  <#
      .LINK
      https://stackoverflow.com/questions/46351885/how-to-grab-the-currently-active-foreground-window-in-powershell
  #>
  [CmdletBinding()]
  param(
    [int]
    $MainWindowHandle,
    [switch]$GetParent,
    [int]
    $ChildWindowHandle
  )

  Process {
    if([string]::IsNullOrEmpty($mainWindowHandle)){
      $mainwindowHandle = [User32Wrapper.WindowHelper]::GetForegroundWindow()
    }
    if($GetParent){
      return [User32Wrapper.WindowHelper]::GetParent($MainWindowHandle)
    }
    if($MainWindowHandle -and $ChildWindowHandle){
      try{
        [User32Wrapper.WindowHelper]::SetParent($ChildWindowHandle,$MainWindowHandle)
      }catch{
        write-ezlogs "An exception occurred attempting to dock window $childwindowhandle to main window $mainwindowhandle" -showtime -catcherror $_
      }
    }
  }
}
#--------------------------------------------- 
#endregion Set-ChildWindow Function
#---------------------------------------------

#--------------------------------------------- 
#region Set-WindowState Function
#---------------------------------------------
function Set-WindowState {
  <#
      .LINK
      https://gist.github.com/Nora-Ballard/11240204
  #>

  [CmdletBinding(DefaultParameterSetName = 'InputObject')]
  param(
    [Parameter(Position = 0, ValueFromPipeline = $true)]
    [Object[]] $InputObject,
    [Object[]] $WindowHandle,
    [Parameter(Position = 1)]
    [ValidateSet('FORCEMINIMIZE', 'HIDE', 'MAXIMIZE', 'MINIMIZE', 'RESTORE',
        'SHOW', 'SHOWDEFAULT', 'SHOWMAXIMIZED', 'SHOWMINIMIZED',
    'SHOWMINNOACTIVE', 'SHOWNA', 'SHOWNOACTIVATE', 'SHOWNORMAL')]
    [string] $State = 'SHOW',
    [string] $logfile = $logfile,
    [switch] $SuppressErrors = $false,
    [switch] $SetForegroundWindow = $false
  )

  Begin {
    $WindowStates = @{
      'FORCEMINIMIZE'         = 11
      'HIDE'              = 0
      'MAXIMIZE'          = 3
      'MINIMIZE'          = 6
      'RESTORE'           = 9
      'SHOW'              = 5
      'SHOWDEFAULT'       = 10
      'SHOWMAXIMIZED'     = 3
      'SHOWMINIMIZED'     = 2
      'SHOWMINNOACTIVE'   = 7
      'SHOWNA'            = 8
      'SHOWNOACTIVATE'    = 4
      'SHOWNORMAL'        = 1
    }


    if (!$global:MainWindowHandles) {
      $global:MainWindowHandles = @{ }
    }
  }

  Process {
    if($WindowHandle){
      foreach ($Handle in $WindowHandle | Where-Object {($_ -ne 0 -and $_ -ne $Null)}) {
        try{
          if ($handle -eq 0 -and $global:MainWindowHandles.ContainsKey($handle)) {
            $handle = $global:MainWindowHandles[$handle]
          }
          if ($handle -eq 0) {
            if (-not $SuppressErrors) {
              Write-ezlogs "Main Window handle is '0'...ignoring"
            }
            continue
          }elseif($WindowStates[$State] -ne $Null){
            $global:MainWindowHandles[$handle] = $handle
            [void][User32Wrapper.WindowHelper]::ShowWindowAsync($handle, $WindowStates[$State])
            if ($SetForegroundWindow) {
              [void][User32Wrapper.WindowHelper]::SetForegroundWindow($handle)
            }
            Write-ezlogs $("Set Window State '{1} on '{0}'" -f $handle, $State)
            return
          }
        }catch{
          Write-ezlogs "An exception occurred processing WindowHandle states for handle $($handle | out-string)" -CatchError $_
        }
      }
    }else{
      foreach ($process in $InputObject | Where-Object {($_.MainWindowHandle -ne 0 -and $_.MainWindowHandle -ne $Null)}) {
        try{
          $handle = $process.MainWindowHandle
          if ($handle -eq 0 -and $global:MainWindowHandles.ContainsKey($process.Id)) {
            $handle = $global:MainWindowHandles[$process.Id]
          }
          if ($handle -eq 0) {
            if (-not $SuppressErrors) {
              Write-ezlogs "Main Window handle is '0'...ignoring"
            }
            continue
          }elseif($WindowStates[$State] -ne $Null){
            $global:MainWindowHandles[$process.Id] = $handle
            [void][User32Wrapper.WindowHelper]::ShowWindowAsync($handle, $WindowStates[$State])
            if ($SetForegroundWindow) {
              [void][User32Wrapper.WindowHelper]::SetForegroundWindow($handle)
            }
            Write-ezlogs $("Set Window State '{1} on '{0}'" -f $handle, $State)
            return
          }
        }catch{
          Write-ezlogs "An exception occurred processing WindowHandle states for process $($process | out-string)" -CatchError $_
        }
      }
    }
  }
}
#--------------------------------------------- 
#endregion Set-WindowState Function
#---------------------------------------------

#---------------------------------------------- 
#region Get-IniFile
#----------------------------------------------
Function Get-IniFile ($file) {
  $ini = @{}
  # Create a default section if none exist in the file. Like a java prop file.
  try{
    if([system.io.file]::Exists($file)){
      $section = "NO_SECTION"
      $ini[$section] = @{}
      switch -regex -file $file {
        "^\[(.+)\]$" {
          $section = $matches[1].Trim()
          $ini[$section] = @{}
        }
        "^\s*([^#].+?)\s*=\s*(.*)" {
          $name,$value = $matches[1..2]
          # skip comments that start with semicolon:
          if (!($name.StartsWith(";"))) {
            $ini[$section][$name] = $value.Trim()
          }
        }
      }
      $ini
    }else{
      write-ezlogs "Unable to find ini file: $file -- cannot continue" -warning
    }
  }catch{
    write-ezlogs "An exception occurred in Get-IniFile for file: $file" -catcherror $_
  }

}
#---------------------------------------------- 
#endregion Get-IniFile
#----------------------------------------------

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
    $ScriptPath = $((Get-PSCallStack).ScriptName | where {$_ -notmatch '.psm1'} | select -First 1)
  }  
  write-ezlogs "[USE-RUNAS] >>>> Checking if running as administrator"
  if([System.IO.File]::Exists($ScriptPath)) 
  {  
    if (-not $IsAdmin -or $ForceReboot -or $RestartAsUser)  
    {  
      try 
      {                
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
          #close-splashscreen
        }
        if($RestartAsUser){
          $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default')
          $Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\").GetSubKeyNames() | foreach {
            if($Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$_").GetValue('DisplayName') -match $($thisApp.Config.App_Name)){
              $install_folder = $Registry.OpenSubKey("SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$_").GetValue('InstallLocation')
            }
          }  
          if(!$install_folder){
            $Registry = [Microsoft.Win32.RegistryKey]::OpenBaseKey('CurrentUser', 'Default')
            $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\").GetSubKeyNames() | foreach {  
              if($Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$_").GetValue('DisplayName') -match $($thisApp.Config.App_Name)){
                $install_folder = $Registry.OpenSubKey("SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$_").GetValue('InstallLocation')
              }
            }
          } 
          $null = $Registry.Dispose()
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
            [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
            $oReturn=[System.Windows.Forms.MessageBox]::Show("Cant find exe path to restart as user: $($ExePath) - ($($appname) Media Player - $($thisScript.Version) - PID: $($process.id))`n`nIt is likely that this installation is corrupt!`n`nThe app will close and you will need to launch it manually again, making sure not to run as administrator","[ERROR] - $($thisScript.name)",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) 
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
      } 
      catch 
      { 
        write-ezlogs "[USE-RUNAS] An exception occurred attempting to restart script" -catcherror $_
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
    write-ezlogs "[USE-RUNAS] Could not find Scriptpath: $ScriptPath -- MyInvocation: $($MyInvocation | out-string)" -warning
    break  
  }  
}
#---------------------------------------------- 
#endregion Use Run-As Function
#----------------------------------------------

#---------------------------------------------- 
#region Confirm Requirements
#----------------------------------------------
function confirm-requirements
{
  param (
    [switch]$FirstRun,
    $thisApp = $thisApp,
    [string]$logfile = $logfile,
    $required_appnames,
    [switch]$noRestart,
    [switch]$test_mode,
    [switch]$Verboselog,
    [switch]$enablelogs
  )
  if($test_mode){
    write-ezlogs "TEST_MODE ENABLED -- Skipping Confirm-Requirements!" -warning -Dev_mode
  }else{
    try{
      #region Install Chocolatey
      $env:ChocolateyInstall = "$env:SystemDrive\Users\Public\chocolatey"
      if (!$env:ChocolateyInstall -or (!([System.IO.File]::Exists("$env:ChocolateyInstall\redirects\Choco.exe")))){
        if($hash.Window){
          Update-SplashScreen -hash $hash -SplashMessage 'Installing/Upgrading Components' -More_Info_Visibility 'Visible' -Splash_More_Info 'Installing Required App: Chocolatey'
        }
        try{   
          write-ezlogs "[Confirm-Requirements] Chocolatey is not installed, installing...." -showtime -warning
          Set-ExecutionPolicy Bypass -Scope Process -Force
          [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
          iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex *>&1 | write-ezlogs 
          if([System.IO.File]::Exists("$env:ChocolateyInstall\redirects\Choco.exe")){
            write-ezlogs "[Confirm-Requirements] Successfully installed Chocolatey -- restarting app" -showtime -Success
            if(!$noRestart){
              Use-RunAs -RestartAsUser -logfile $logfile
            }        
          }else{
            if($(get-command choco*)){
              choco upgrade chocolatey --confirm --force *>&1 | write-ezlogs
              if([System.IO.File]::Exists("$env:ChocolateyInstall\redirects\Choco.exe")){
                write-ezlogs "[Confirm-Requirements] Successfully installed Chocolatey" -showtime -Success        
                if(!$noRestart){
                  Use-RunAs -RestartAsUser -logfile $logfile
                } 
              }
            }else{
              write-ezlogs "Unable to verify successfully installation of chocolatey -- see logs for details!" -showtime -warning
            }        
          }
        }catch{
          write-ezlogs "[Confirm-Requirements] An exception occurred installing Chocolatey" -showtime -catcherror $_
          if($_ -match 'installed|a reboot is required' -and $hash.Window){
            $null = [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
            $resultmessage=[System.Windows.Forms.MessageBox]::Show("A reboot is required to finish setup or installation of $($thisApp.Config.App_Name) or one of its components. Would you like to reboot your computer now?",'REBOOT REQUIRED - CANNOT CONTINUE',[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning)
            if($resultmessage -eq 'Yes'){
              Restart-Computer -Force -ErrorAction SilentlyContinue
            }
            Stop-Process $PID -Force
          }
        }
      }
      else
      {   
        $testchoco = [System.IO.FileInfo]::new("$env:ChocolateyInstall\redirects\Choco.exe").VersionInfo.ProductVersion
        write-ezlogs "[Confirm-Requirements] >>>> Chocolatey is installed. Version $testchoco" -showtime
      }
      #endregion Install Chocolatey

      #region Update Powershell
      if($($PSVersionTable.PSVersion.Major) -lt 3)
      {
        $MinimumNet4Version = 378389
        $Net4Version = (get-itemproperty "hklm:software\microsoft\net framework setup\ndp\v4\full" -ea silentlycontinue | Select -Expand Release -ea silentlycontinue)
        if ($Net4Version -lt $MinimumNet4Version)
        {
          write-ezlogs "[Confirm-Requirements] .NET Framework 4.5.2 or later required.  Use package named `"dotnet4.5` to upgrade. Your .NET Release is `"$MinimumNet4Version`" but needs to be at least `"$MinimumNet4Version`"." -warning -LogLevel 2 
        }
        else
        {
          if(!$noRestart){
            Use-RunAs -logfile $logfile
          }
          write-ezlogs "[Confirm-Requirements] This machine does not meet the minimum requirements to use this script. Your Powershell version is $($PSVersionTable.psversion) and the minimum required is 3`n | Attempting to update Powershell via Chocolatey...." -warning -LogLevel 2
          if($hash.Window){
            Update-SplashScreen -hash $hash -SplashMessage 'Attempting to update Powershell' -More_Info_Visibility 'Visible' -Splash_More_Info 'Installing Required App: Chocolatey'
          } 
          choco upgrade powershell -confirm -force 
          if($($PSVersionTable.PSVersion.Major) -ge 3)
          {
            write-ezlogs "[Confirm-Requirements] | Powershell was updated successfully" -Success -LogLevel 2
          }
          else
          {
            write-ezlogs "[Confirm-Requirements] | Powershell was either not updated successfully, or the system may require a restart. Restart and try again, otherwise update Powershell manually on this system" -warning -LogLevel 2
          }
     
        }
      }
      #endregion Update Powershell

      #region install/update required apps
      if(-not [string]::IsNullOrEmpty($required_appnames) -and $firstRun){
        foreach ($app in $required_appnames)
        {
          $appinstalled = $null
          if($app -eq 'Spotify'){
            if($thisApp.Config.Import_Spotify_Media -and (!$thisApp.Config.Spotify_WebPlayer -or $thisApp.Config.Install_Spotify)){
              if([System.IO.File]::Exists("$($env:APPDATA)\Spotify\Spotify.exe")){
                $appinstalled = [System.IO.FileInfo]::new("$($env:APPDATA)\Spotify\Spotify.exe").VersionInfo.ProductVersion
              }else{
                if($psversiontable.PSVersion.Major -gt 5){
                  try{
                    write-ezlogs "Running PowerShell $($psversiontable.PSVersion.Major), Importing Module Appx with parameter -usewindowspowershell" -showtime -warning
                    Import-module Appx -usewindowspowershell
                  }catch{
                    write-ezlogs "An exception occurred executing import-module appx -usewindowspowershell" -CatchError $_
                  }
                }
                if((Get-appxpackage 'Spotify*')){
                  write-ezlogs ">>>> Spotify installed as appx" -showtime
                  $appinstalled = (Get-ItemProperty "$((Get-appxpackage 'Spotify*').InstallLocation)\Spotify.exe" -ErrorAction SilentlyContinue).VersionInfo.ProductVersion
                }else{
                  $appinstalled = ''
                }
              }
              $Do_Install = $thisApp.Config.Install_Spotify  
            }else{
              $Do_Install = $false
              write-ezlogs ">>>> Skipping install check for Spotify" -loglevel 3 -logtype Setup
            }          
            write-ezlogs ">>>> Auto Install $app`: $($thisApp.Config.Install_Spotify)" -showtime -loglevel 3 -logtype Setup
          }elseif($app -eq 'Spicetify'){             
            if($thisApp.Config.Import_Spotify_Media -and $thisApp.Config.use_Spicetify -and !$thisApp.Config.Spotify_WebPlayer){
              if([System.IO.File]::Exists("$($env:USERPROFILE)\spicetify-cli\spicetify.exe") -and [System.IO.File]::Exists("$($env:USERPROFILE)\.spicetify\config-xpui.ini")){
                $Spicetify_Install_Dir = "$($env:USERPROFILE)\spicetify-cli\"
                $Spicetify_Config_Dir = "$($env:USERPROFILE)\.spicetify"
                $appinstalled = (Get-iniFile "$Spicetify_Config_Dir\config-xpui.ini").Backup.with
                if(!$appinstalled){
                  $appinstalled = "$($env:USERPROFILE)\spicetify-cli\spicetify.exe"
                }
              }elseif([System.IO.File]::Exists("$($env:LOCALAPPDATA)\spicetify\spicetify.exe") -and [System.IO.File]::Exists("$($env:APPDATA)\spicetify\config-xpui.ini")){    
                $Spicetify_Install_Dir = "$($env:LOCALAPPDATA)\spicetify"
                $Spicetify_Config_Dir = "$($env:APPDATA)\spicetify"  
                $appinstalled = (Get-iniFile "$Spicetify_Config_Dir\config-xpui.ini").Backup.with
                if(!$appinstalled){
                  $appinstalled = "$($env:LOCALAPPDATA)\spicetify\spicetify.exe"
                }    
              }else{
                $Do_Install = $true
              }        
            }else{
              $Do_Install = $false
            }                           
          }elseif($app -eq 'Streamlink'){
            $latestversion = ([system.io.fileinfo]::new("$($thisApp.Config.Current_Folder)\Resources\Streamlink\streamlink-installer.exe")).VersionInfo.FileVersion
            if([System.IO.File]::Exists("${env:ProgramFiles(x86)}\Streamlink\uninstall.exe")){
              #$appinstalled = streamlink --version-check
              $appinstalled = ([system.io.fileinfo]::new("${env:ProgramFiles(x86)}\Streamlink\uninstall.exe")).VersionInfo.FileVersion
              #$appinstalled = "Streamlink is installed at $("${env:ProgramFiles(x86)}\Streamlink\bin\streamlink.exe")"
            }elseif([System.IO.File]::Exists("$env:ProgramW6432\Streamlink\uninstall.exe")){
              $appinstalled = ([system.io.fileinfo]::new("$env:ProgramW6432\Streamlink\uninstall.exe")).VersionInfo.FileVersion
              #$appinstalled = "Streamlink is installed at $("${env:ProgramFiles}\Streamlink\bin\streamlink.exe")"
            }else{
              $Do_Install = $true
            }
            if($appinstalled -and $latestversion -gt $appinstalled){
              write-ezlogs ">>>> Found existing version of Streamlink ($($appinstalled)) but is lower version than the version included with this build ($($latestversion)) -- executing silent install/update" -warning
              $Do_Install = $true
              $Do_Update = $true
            }elseif($appinstalled -and $latestversion -lt $appinstalled){
              write-ezlogs ">>>> Found existing version of Streamlink ($($appinstalled)) that is a newer version than the version included with this build ($($latestversion))" -warning
              $Do_Install = $false
              $Do_Update = $false
            }
          }elseif($app -eq 'vb-cable'){
            if([System.IO.File]::Exists("${env:ProgramFiles(x86)}\VB\CABLE\VBCABLE_ControlPanel.exe")){
              $appinstalled = [System.IO.FileInfo]::new("$("${env:ProgramFiles(x86)}\VB\CABLE\VBCABLE_Setup.exe")").versioninfo.fileversion -replace ', ','.'
            }elseif([System.IO.File]::Exists("$env:ProgramW6432\VB\CABLE\VBCABLE_ControlPanel.exe")){
              $appinstalled = [System.IO.FileInfo]::new("$env:ProgramW6432\VB\CABLE\VBCABLE_Setup_x64.exe").versioninfo.fileversion -replace ', ','.'
            }elseif($thisapp.config.Enable_WebEQSupport){
              write-ezlogs ">>>> Enable Web EQ Support is enabled - unable to find VBCable install files" -Warning
              $Do_Install = $true
            }else{
              write-ezlogs ">>>> Enable Web EQ Support is disabled -- skipping install of VB-Audio" -Warning
              $Do_Install = $false
            }
          }else{        
            $chocoappmatch = choco list $app
            $appinstalled = $($chocoappmatch | Select-String $app | out-string).trim()
            $Do_Install = $true       
          }     
          if($appinstalled -and !$Do_Update){
            write-ezlogs ">>>> $app is installed. Version $appinstalled" -showtime
          }elseif(!$Do_Install){
            write-ezlogs ">>>> $app is not installed! Auto installation skipped!" -showtime -warning      
          }else{        
            try{
              if(!$noRestart){
                #Use-RunAs
              }
              if($Do_Update){
                $splashmessage = "Updating: $app"
              }else{
                $splashmessage = "Installing: $app"
              }
              $app_install_scriptblock = {
                if($hash.Window){
                  Update-SplashScreen -hash $hash -SplashMessage $splashmessage -More_Info_Visibility 'Visible'
                } 
                if($app -eq 'Spicetify'){
                  try{
                    write-ezlogs ">>>> Installing Spicetify" -showtime -loglevel 2          
                    Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.ps1" | Invoke-Expression -Verbose
                    #Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/spicetify/spicetify-marketplace/master/install.ps1" | Invoke-Expression -Verbose
                    Invoke-WebRequest -UseBasicParsing "https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.ps1" | Invoke-Expression -Verbose
                    if([System.IO.File]::Exists("$($env:USERPROFILE)\spicetify-cli\spicetify.exe") -and [System.IO.File]::Exists("$($env:USERPROFILE)\.spicetify\config-xpui.ini")){
                      $Spicetify_Install_Dir = "$($env:USERPROFILE)\spicetify-cli\"
                      $Spicetify_Config_Dir = "$($env:USERPROFILE)\.spicetify"
                      $appinstalled = (Get-iniFile "$Spicetify_Config_Dir\config-xpui.ini").Backup.with
                      if(!$appinstalled){
                        $appinstalled = "$($env:USERPROFILE)\spicetify-cli\spicetify.exe"
                      }
                    }elseif([System.IO.File]::Exists("$($env:LOCALAPPDATA)\spicetify\spicetify.exe") -and [System.IO.File]::Exists("$($env:APPDATA)\spicetify\config-xpui.ini")){    
                      $Spicetify_Install_Dir = "$($env:LOCALAPPDATA)\spicetify"
                      $Spicetify_Config_Dir = "$($env:APPDATA)\spicetify"  
                      $appinstalled = (Get-iniFile "$Spicetify_Config_Dir\config-xpui.ini").Backup.with
                      if(!$appinstalled){
                        $appinstalled = "$($env:LOCALAPPDATA)\spicetify\spicetify.exe"
                      }    
                    }
                  }catch{
                    write-ezlogs "An exception occurred attempting to install Spicetify" -showtime -catcherror $_
                  }
                }elseif($app -eq 'Streamlink'){ 
                  if([system.io.file]::Exists("$($thisApp.Config.Current_Folder)\Resources\Streamlink\streamlink-installer.exe")){
                    write-ezlogs "$app is not installed or out of date! Attempting to install from $($thisApp.Config.Current_Folder)\Resources\Streamlink\streamlink-installer.exe" -showtime -warning  
                    Start-Process "$($thisApp.Config.Current_Folder)\Resources\Streamlink\streamlink-installer.exe" -ArgumentList '/S' -Wait
                    if([System.IO.File]::Exists("$("${env:ProgramFiles(x86)}\Streamlink\uninstall.exee")")){
                      $appinstalled = [System.IO.FileInfo]::new("$("${env:ProgramFiles(x86)}\Streamlink\uninstall.exee")").versioninfo.fileversion
                    }elseif([System.IO.File]::Exists("$("$env:ProgramW6432\Streamlink\uninstall.exe")")){
                      $appinstalled = [System.IO.FileInfo]::new("$env:ProgramW6432\Streamlink\uninstall.exe").versioninfo.fileversion
                    }
                  }else{
                    write-ezlogs "$app is not installed! Attempting to install from chocolatey" -showtime -warning  
                    if(!$env:ChocolateyInstall -or (!([System.IO.File]::Exists("$env:ChocolateyInstall\redirects\Choco.exe")))){
                      try{   
                        write-ezlogs "[Confirm-Requirements] Chocolatey is not installed, installing...." -showtime -warning
                        Set-ExecutionPolicy Bypass -Scope Process -Force
                        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                        iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex *>&1 | write-ezlogs 
                        if([System.IO.File]::Exists("$env:ChocolateyInstall\redirects\Choco.exe")){
                          write-ezlogs "[Confirm-Requirements] Successfully installed Chocolatey -- restarting app" -showtime -Success        
                        }else{
                          if($(get-command choco*)){
                            choco upgrade chocolatey --confirm --force *>&1 | write-ezlogs
                            if([System.IO.File]::Exists("$env:ChocolateyInstall\redirects\Choco.exe")){
                              write-ezlogs "[Confirm-Requirements] Successfully installed Chocolatey" -showtime -Success         
                            }
                          }else{
                            write-ezlogs "Unable to verify successfully installation of chocolatey -- see logs for details!" -showtime -warning
                          }        
                        }
                      }catch{
                        write-ezlogs "[Confirm-Requirements] An exception occurred installeding Chocolatey" -showtime -catcherror $_
                      }
                    }
                    $choco_install = choco upgrade $app --confirm --force --acceptlicense
                    write-ezlogs ">>>> Verifying if $app was installed successfully...." -showtime -loglevel 2
                    $chocoappmatch = choco list $app
                    if($chocoappmatch){
                      $appinstalled = $($chocoappmatch | Select-String $app | out-string).trim()
                    } 
                  }
                }elseif($app -eq 'vb-cable'){ 
                  #uninstall: Start-Process "$($thisApp.Config.Current_Folder)\Resources\Audio\VBCABLE_Driver_Pack\VBCABLE_Setup_x64.exe" -ArgumentList '-u -h' -Wait
                  $Vbsetup_path = "$($thisApp.Config.Current_Folder)\Resources\Audio\VBCABLE_Driver_Pack\VBCABLE_Setup_x64.exe"
                  if([system.io.file]::Exists($Vbsetup_path)){
                    try{
                      write-ezlogs "$app is not installed or out of date! Attempting to install from $Vbsetup_path" -showtime -warning  
                      $default_output_Device = [CSCore.CoreAudioAPI.MMDeviceEnumerator]::DefaultAudioEndpoint([CSCore.CoreAudioAPI.DataFlow]::Render,[CSCore.CoreAudioAPI.Role]::Multimedia)   
                      write-ezlogs " | Current Default Audio Device: $($default_output_Device | out-string)"            
                      #Start-Process "$($thisApp.Config.Current_Folder)\Resources\Audio\VBCABLE_Driver_Pack\VBCABLE_Setup_x64.exe" -ArgumentList '-i -h' -Wait
                      Start-Process "$($thisApp.Config.Current_Folder)\Resources\Audio\VBCABLE_Driver_Pack\VBCABLE_Setup_x64.exe" -ArgumentList '-i -h' -Wait -Verb RunAs
                      write-ezlogs " | Resetting Default Audio Device to: $($default_output_Device.FriendlyName)"
                      $set_AudioDevice = Get-AudioDevice -ID "$($default_output_Device.DeviceID)" -ErrorAction SilentlyContinue | Set-AudioDevice -DefaultOnly -ErrorAction SilentlyContinue
                      if($set_AudioDevice){
                        write-ezlogs " | New Default Audio Device (should be same as previous): $($set_AudioDevice | out-string)" -logtype setup
                      }
                      write-ezlogs " | New Default Audio Device (should be same as previous): $($default_output_Device.FriendlyName)"
                      if([System.IO.File]::Exists("${env:ProgramFiles(x86)}\VB\CABLE\VBCABLE_ControlPanel.exe")){
                        $appinstalled = [System.IO.FileInfo]::new("${env:ProgramFiles(x86)}\VB\CABLE\VBCABLE_Setup.exe").versioninfo.fileversion -replace ', ','.'
                      }elseif([System.IO.File]::Exists("$env:ProgramW6432\VB\CABLE\VBCABLE_ControlPanel.exe")){
                        $appinstalled = [System.IO.FileInfo]::new("$env:ProgramW6432\VB\CABLE\VBCABLE_Setup_x64.exe").versioninfo.fileversion -replace ', ','.'
                      }else{
                        write-ezlogs "$app may not have installed correctly, unable to find VBCABLE_ControlPanel.exe" -warning
                        $appinstalled = ''
                      }
                    }catch{
                      write-ezlogs "An exception occured attempting to install VBCable" -catcherror $_
                    }finally{
                      if($default_output_Device){
                        $default_output_Device.dispose()
                        $default_output_Device = $Null
                      }
                    }
                  }else{
                    if($(get-command choco*)){
                      write-ezlogs "$app is not installed! Attempting to install from chocolatey" -showtime -warning  
                      $choco_install = choco upgrade $app --confirm --force --acceptlicense
                      write-ezlogs ">>>> Verifying if $app was installed successfully...." -showtime -loglevel 2
                      $chocoappmatch = choco list $app
                      if($chocoappmatch){
                        $appinstalled = $($chocoappmatch | Select-String $app | out-string).trim()
                      } 
                    }else{
                      write-ezlogs "Unable to verify successfully installation of chocolatey -- cannot continue with install of app: $app!" -showtime -warning
                    }       
                  }
                }else{
                  if($(get-command choco*)){
                    write-ezlogs "$app is not installed! Attempting to install via chocolatey" -showtime -warning   
                    $choco_install = choco upgrade $app --confirm --force --acceptlicense
                    write-ezlogs ">>>> Verifying if $app was installed successfully...." -showtime -loglevel 2
                    $chocoappmatch = choco list $app
                    if($chocoappmatch){
                      $appinstalled = $($chocoappmatch | Select-String $app | out-string).trim()
                    }
                  }else{
                    write-ezlogs "Unable to verify successfully installation of chocolatey -- cannot continue with install of app: $app!" -showtime -warning
                  } 
                }        
                if($appinstalled){
                  write-ezlogs "$app was successfully installed. Version: $appinstalled" -showtime -Success -loglevel 2
                }else{
                  write-ezlogs "Unable to verify if $app installed successfully! Choco output: $($choco_install | out-string)" -showtime -warning 
                }
              }
              if($app -match 'streamlink'){
                $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
                #$Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"} 
                Start-Runspace -scriptblock $app_install_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'App_install__RUNSPACE' -thisApp $thisApp -synchash $synchash
                Remove-Variable Variable_list
                Remove-Variable app_install_scriptblock
              }else{
                Invoke-Command -ScriptBlock $app_install_scriptblock
              }
            }catch{
              write-ezlogs "An exception occurred attempting to install app $app via chocolatey" -showtime -catcherror $_
            }
          }
        }
      }
      #endregion install/update required apps
    }catch{
      write-ezlogs "An exception occurred in Confirm-Requirements" -CatchError $_
    }
  }
}
#---------------------------------------------- 
#endregion Confirm Requirements
#----------------------------------------------

#---------------------------------------------- 
#region Convert-TimespanToInt Function
#----------------------------------------------
function Convert-TimespanToInt {
  <#
      .SYNOPSIS
      Converts ISO Duration only to Time Int
	
      .PARAMETER Timespan
      Example "P1Y2M10DT2H30M"
	
      .EXAMPLE
      Convert-TimepanToInt -Timespan $time
	
      .NOTES
      Please see for standards https://en.m.wikipedia.org/wiki/ISO_8601

      .Credit
      Woody
  #>
	
  [OutputType([int64])]
  param
  (
    [string]$Timespan
  )
  if([bool]($Timespan -as [TimeSpan])){
    Return ($Timespan -as [TimeSpan]).TotalHours
  }else{
    if ($Timespan -eq "PT0S") { $results = 0 } else {
      try{
        $TDays = ($Timespan.split("T")[0]).trimstart("P")
        $TTime = $Timespan.split("T")[1]
			
        #region Days
        if (-not [string]::IsNullOrEmpty($TDays)) {
          # Checking for Year
          [int64]$Year = If ($TDays -like "*Y*") { $TDays.split("Y")[0] }
          # Checking for Month
          [int64]$Month = If ($TDays -like "*M*") {
            if ($TDays -like "*Y*" -and $TDays -like "*D*") {
              $TDays.Split("Y").Split("M")[1]
            } Else {
              if ($TDays -like "*Y*") { $TDays.split("M")[0] } Else {
                $TDays.trimstart("Y").split("M")[0]
              }
            }
          }
          # Checking for Days
          [int64]$Days = If ($TDays -like "*D*") {
            if ($TDays -like "*Y*" -and $TDays -like "*M*") {
              $TDays.Split("M").Split("D")[1]
            } else {
              if ($TDays -like "*Y*") { $TDays.split("Y").split("D")[1] } Else {
                if ($TDays -like "*M*") { $TDays.split("M").split("D")[1] } Else {
                  ($TDays.TrimEnd("T")).Trim("D")
                }
              }
            }
          }
        }
        #endregion
			
        #region Time
        if (-not [string]::IsNullOrEmpty($TTime)) {
          # Checking for Hours
          [int64]$Hours = If ($TTime -like "*H*") { $TTime.split("H")[0] }
          # Checking for Minutes
          [int64]$Minutes = If ($TTime -like "*M*") {
            if ($TTime -like "*H*" -and $TTime -like "*S*") {
              $TTime.Split("H").split("M")[1]
            } else {
              if ($TTime -like "*H*") { $TTime.split("H").split("M")[1] } Else {
                if ($TTime -like "*S*") { $TTime.split("H").split("M")[0] } Else {
                  $TTime.split("M")[0]
                }
              }
            }
          }
          # Checking for Seconds
          [int64]$Seconds = If ($TTime -like "*S*") {
            if ($TTime -like "*H*" -and $TTime -like "*M*") {
              $TTime.Split("M").split("S")[1]
            } else {
              if ($TTime -like "*H*") { $TTime.Split("H").split("S")[1] } Else {
                if ($TTime -like "*M*") { $TTime.split("M").split("S")[1] } Else {
                  $TTime.Split("S")[0]
                }
              }
            }
          }
          #endregion
          $results = ($Year * 8760) + ($Month * 8760/12) + ($Days * 24) + ($Hours) + ($Minutes / 60) + ($Seconds / 60 / 60)
        }
      }catch{
        Write-ezlogs "An exception occurred converting duration: $Timespan" -showtime -catcherror $_
      }
    }
  }
  Return $Results
}
#---------------------------------------------- 
#endregion Convert-TimespanToInt Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-DDGSearchQuery Function
#----------------------------------------------
function Get-DDGSearchQuery {
    
  param([string[]] $Query)
  if(-not [string]::IsNullOrEmpty($Query)){
    try{
      Add-Type -AssemblyName System.Web # To get UrlEncode()
      $QueryString = ($Query | %{ [Web.HttpUtility]::UrlEncode($_)}) -join '+'
    
      # Return the query string
      $urlQuery =  "https://api.duckduckgo.com/?q=$QueryString&format=json"
    
      $search = Invoke-restmethod $urlQuery -UseBasicParsing
      if(-not [string]::IsNullOrEmpty($search.Heading)){
        return $search
      }else{
        write-ezlogs "No results found matching query: $QueryString" -showtime -warning
      }      
    }catch{
      Write-ezlogs "An exception occurred processing DDG Search query url: $urlQuery" -showtime -catcherror $_
    }
  }
}
#---------------------------------------------- 
#endregion Get-DDGSearchQuery Function
#----------------------------------------------

#---------------------------------------------- 
#region Optimize-Assemblies Function
#----------------------------------------------
function Optimize-Assemblies {
    
  param(
    [switch]$UpdateGAC,
    $thisApp,
    $hashsetup
  )
  $Optimize_Assemblines_Scriptblock = {
    param(
      [switch]$UpdateGAC = $UpdateGAC,
      $thisApp = $thisApp,
      $hashsetup = $hashsetup
    )
    try{
      if($psversiontable.psversion.Major -le 5){
        Add-Type -AssemblyName System.EnterpriseServices
        if($UpdateGAC){
          write-ezlogs ">>>> Installing Assemblies into the GAC" -showtime -color cyan
          if($hash.window.isVisible){
            Update-SplashScreen -hash $hash -SplashMessage "Installing Assemblies into the GAC..."
          } 
          $Assemblies = [System.IO.Directory]::EnumerateFiles("$($thisApp.config.Current_Folder)\Assembly",'*.dll','AllDirectories')   
          foreach ($a in $Assemblies)
          {
            if($a -notmatch 'WebView2' -and $a -notmatch 'XInputInterface'){
              try{
                write-ezlogs " | Installing $a into the GAC" -showtime
                $objPublish = [System.EnterpriseServices.Internal.Publish]::new()
                $null = $objPublish.GacInstall($a)
              }catch{
                write-ezlogs "Exception occurred installing assembly $a into the GAC" -showtime -catcherror $_
              }
            }
          }
        }
        $ngen_path = $([Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory())
      }else{
        $ngen_path = (get-childitem "$env:windir\Microsoft.NET\Framework64\*" -Filter 'ngen.exe' -Recurse).DirectoryName | select -last 1
      }
      write-ezlogs ">>>> Optimizing Powershell Assemblies and Native Images Cache..." -showtime -color cyan
      if($hash.window.isVisible){
        Update-SplashScreen -hash $hash -SplashMessage "Optimizing Powershell Assemblies and Native Images Cache..."
      }
      if(!(use-runas -Check)){
        write-ezlogs "$($thisApp.Config.App_name) Media Player must be run as administrator in order to optimize Powershell Assemblies, cannot continue" -showtime -warning
        if($hashsetup.Window.isVisible -and $hashsetup.Update_Optimize_Timer){        
          $hashsetup.Update_Optimize_Timer.tag = "Requires Reboot"
          $hashsetup.Update_Optimize_Timer.start()
        }elseif($synchash.Window.isVisible){
          write-ezlogs "Optimization of Assemblies has finished! It is recommended to close and restart the app" -showtime -Success -AlertUI
        }
        return
      } 
      $ngen_Measure = [system.diagnostics.stopwatch]::StartNew()
      $env:PATH += ";$ngen_path"
      $CurrentDomain_Assemblies = [AppDomain]::CurrentDomain.GetAssemblies()
      $CurrentDomain_Assemblies | ForEach {
        $path = $_.Location
        if ([system.io.file]::Exists($path)) { 
          $name = [system.io.path]::GetFileName($path)
          write-ezlogs ">>>> Running ngen.exe on '$name'" -showtime
          try{
            if(get-command ngen.exe*){
              ngen install $path /nologo
            }elseif([System.IO.Directory]::Exists($ngen_path)){
              $env:PATH += ";$ngen_path"
              ngen install $path /nologo
            }
          }catch{
            write-ezlogs "An exception occurred running ngen install for assembly path $path" -showtime -catcherror $_
          }      
        }
      }
      $ngen_Measure.stop()
      write-ezlogs "[FINISHED] >>>> ngen.exe execution time for ($(@($CurrentDomain_Assemblies).count)) assemblies: $($ngen_Measure.elapsed | out-string)" -showtime -color Green
    }catch{
      write-ezlogs "Exception occurred compiling assemblies with ngen.exe - Current ENVPath: $($env:PATH | out-string)" -showtime -catcherror $_
    }
    if($hashsetup.Window -and $hashsetup.Update_Optimize_Timer){
      $hashsetup.Update_Optimize_Timer.tag = "Optimization of Assemblies has finished! It is recommended to close and restart the app"
      $hashsetup.Update_Optimize_Timer.start()
    }elseif($synchash.Window.isVisible){
      write-ezlogs "Optimization of Assemblies has finished! It is recommended to close and restart the app" -showtime -Success -AlertUI
    }
  }
  try{
    #$Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"} 
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
    Start-Runspace -scriptblock $Optimize_Assemblines_Scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'Optimize_Assemblies_RUNSPACE' -thisApp $thisApp
    Remove-Variable Variable_list
    Remove-Variable Optimize_Assemblines_Scriptblock
  }catch{
    write-ezlogs "An exception occurred executing Optimize_Assemblies_RUNSPACE" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Optimize-Assemblies Function
#----------------------------------------------

#---------------------------------------------- 
#region Lock-Object Function
#----------------------------------------------
function Lock-Object
{
  <#
      .Synopsis
      Locks an object to prevent simultaneous access from another thread.
      .DESCRIPTION
      PowerShell implementation of C#'s "lock" statement.  Code executed in the script block does not have to worry about simultaneous modification of the object by code in another thread.
      .PARAMETER InputObject
      The object which is to be locked.  This does not necessarily need to be the actual object you want to access; it's common for an object to expose a property which is used for this purpose, such as the ICollection.SyncRoot property.
      .PARAMETER ScriptBlock
      The script block that is to be executed while you have a lock on the object.
      Note:  This script block is "dot-sourced" to run in the same scope as the caller.  This allows you to assign variables inside the script block and have them be available to your script or function after the end of the lock block, if desired.
      .EXAMPLE
      $hashTable = @{}
      lock $hashTable.SyncRoot {
      $hashTable.Add("Key", "Value")
      }
 
      This is an example of using the "lock" alias to Lock-Object, in a manner that most closely resembles the similar C# syntax with positional parameters.
      .EXAMPLE
      $hashTable = @{}
      Lock-Object -InputObject $hashTable.SyncRoot -ScriptBlock {
      $hashTable.Add("Key", "Value")
      }
 
      This is the same as Example 1, but using the full PowerShell command and parameter names.
      .INPUTS
      None.  This command does not accept pipeline input.
      .OUTPUTS
      System.Object (depends on what's in the script block.)
      .NOTES
      Most of the time, PowerShell code runs in a single thread.  You have to go through several steps to create a situation in which multiple threads can try to access the same .NET object.  In the Links section of this help topic, there is a blog post by Boe Prox which demonstrates this.
      .LINK
      http://learn-powershell.net/2013/04/19/sharing-variables-and-live-objects-between-powershell-runspaces/
  #>
 
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true, Position = 0)]
    [AllowEmptyString()]
    [AllowEmptyCollection()]
    [object]
    $InputObject,
 
    [Parameter(Mandatory = $true, Position = 1)]
    [scriptblock]
    $ScriptBlock
  )
  
  if([string]::IsNullOrEmpty($ScriptBlock)){
    Write-ezlogs 'Lock-Object: Scriptblock was null or empty! Cannot continue' -isError
    return
  }
  try{
    if ($InputObject.GetType().IsValueType)
    {
      Write-ezlogs 'Lock-Object: InputObject cannot be a value type.' -isError
      return
    } 
    $lockTaken = $false
    [System.Threading.Monitor]::Enter($InputObject)
    $lockTaken = $true
    . $ScriptBlock
  }catch{
    Write-ezlogs 'An exception occurred in Lock-Object' -CatchError $_
  }finally{
    if($lockTaken){
      [System.Threading.Monitor]::Exit($InputObject)
    }
  }
}
 
#---------------------------------------------- 
#endregion Lock-Object Function
#----------------------------------------------

#--------------------------------------------- 
#region Clear-WorkingMemory Function
#---------------------------------------------
function Clear-WorkingMemory {
  <#
      .LINK
      https://www.codeproject.com/questions/1064200/wpf-increasing-memory-usage-in-time
  #>

  param(
    [int]
    $MainWindowHandle
  )

  Begin {
    if(-not [bool]('ProcessTools' -as [Type])){
      Add-Type  @"
 using System;
 using System.Runtime.InteropServices;
 using System.Text;
public class ProcessTools
   {
[DllImport("KERNEL32.DLL", EntryPoint = "GetCurrentProcess", SetLastError = true, CallingConvention = CallingConvention.StdCall)]
public static extern bool SetProcessWorkingSetSize(IntPtr pProcess, int dwMinimumWorkingSetSize, int dwMaximumWorkingSetSize);

[DllImport("KERNEL32.DLL", EntryPoint = "GetCurrentProcess", SetLastError = true, CallingConvention = CallingConvention.StdCall)]
public static extern IntPtr GetCurrentProcess();


    }
"@
    }

  }
  Process {
    try{
      return [ProcessTools]::SetProcessWorkingSetSize($([ProcessTools]::GetCurrentProcess()), -1, -1)
    }catch{
      write-ezlogs "An exception occurred attempting to SetProcessWorkingSetSize for handle: $mainwindowhandle" -showtime -catcherror $_
    }
  }
}
#--------------------------------------------- 
#endregion Clear-WorkingMemory Function
#---------------------------------------------

#--------------------------------------------- 
#region Get-MemoryUsage Function
#---------------------------------------------
$Global:last_memory_usage_byte = 0

function Get-MemoryUsage
{
  <#
      .LINK
      https://web.archive.org/web/20160602012231/http://powershell.com/cs/blogs/tips/archive/2015/05/15/get-memory-consumption.aspx
  #>
  param(
    [switch]
    $forceCollection,
    [switch]$WaitForPendingFinalizers
  )
  if($WaitForPendingFinalizers){
    [System.GC]::Collect()
    [gc]::WaitForPendingFinalizers()
    [System.GC]::Collect()
    [gc]::WaitForPendingFinalizers()
  }
  $memusagebyte = [System.GC]::GetTotalMemory($forceCollection)
  $memusageMB = $memusagebyte / 1MB
  $diffbytes = $memusagebyte - $Global:last_memory_usage_byte
  $difftext = ''
  $sign = ''
  if ( $Global:last_memory_usage_byte -ne 0 )
  {
    if ( $diffbytes -ge 0 )
    {
      $sign = '+'
    }
    $difftext = ", $sign$([math]::Round($diffbytes / 1MB,3)) MB"
  }
  if($forceCollection){
    $Collectiontext = " (forceCollection)"
  }
  # save last value in script global variable
  $Global:last_memory_usage_byte = $memusagebyte
  return ('Memory: {0:n1} MB ({1:n0} Bytes{2}){3}' -f  $memusageMB, $memusagebyte, $difftext, $Collectiontext)

}
#--------------------------------------------- 
#endregion Get-MemoryUsage Function
#---------------------------------------------

#--------------------------------------------- 
#region Get-AllStartApps Function
#---------------------------------------------
function Get-AllStartApps
{
  <#
      .Notes
      Adapted from the (sometimes broken) Windows startlayout/Getstartapps module
  #>
  param(
    [switch]
    $All,
    [string]$Name
  )
  try{   
    $com= (New-Object -ComObject Shell.Application).NameSpace("shell:::{4234d49b-0245-4df3-b780-3893943456e1}") # FOLDERID_AppsFolder
    if($All -or [string]::IsNullOrEmpty($Name)){
      foreach($c in $com.Items()){
        [PSCustomObject]::new(@{
            'Name'=$c.Name
            'AppID'=$c.Path
        })
      }
    }elseif($Name){
      foreach($c in $com.Items()){
        if($c.Name -like "*$Name*"){
          return [PSCustomObject]::new(@{
              'Name'=$c.Name
              'AppID'=$c.Path
          })
        }
      }
    }
  }catch{
    write-ezlogs "An exception occurred in Get-AllStartApps" -catcherror $_
  }finally{
    if($com){
      $null = [System.Runtime.Interopservices.Marshal]::ReleaseComObject($com)
    }
  }
}
#--------------------------------------------- 
#endregion Get-AllStartApps Function
#---------------------------------------------

#--------------------------------------------- 
#region Get-VisualParent Function
#---------------------------------------------
function Get-VisualParentUp {

  param(
    [Windows.DependencyObject]$source,
    [System.Reflection.TypeInfo]$type
  )
    
  process {
    while ($source -ne $Null -and !($source -is $type)) {
      $source = [Windows.Media.VisualTreeHelper]::GetParent($source)         
    }  
    return $source -as $type  
  }
}
#--------------------------------------------- 
#endregion Get-VisualParent Function
#---------------------------------------------

#--------------------------------------------- 
#region Use-Object Function
#---------------------------------------------
function Use-Object
{
  param (
    [Parameter(Mandatory = $true)]
    [AllowEmptyString()]
    [AllowEmptyCollection()]
    [AllowNull()]
    [Object]
    $InputObject,
    [Parameter(Mandatory = $true)]
    [scriptblock]
    $ScriptBlock
  )

  try
  {
    . $ScriptBlock
  }
  finally
  {
    if ($InputObject -is [System.IDisposable])
    {
      $InputObject.Dispose()
    }
  }
}
#--------------------------------------------- 
#endregion Use-Object Function
#---------------------------------------------

#--------------------------------------------- 
#region Get-ChildProcesses Function
#---------------------------------------------
function Get-ChildProcesses {
  [OutputType([System.Management.ManagementObject])]
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [string]$ParentProcessId,
    [string]$filter,
    [switch]$Full
  )
  try{
    if($filter){
      $Processfilter = "parentprocessid = '$($ParentProcessId)' AND $filter"
    }else{
      $Processfilter = "parentprocessid = '$($ParentProcessId)'"
    }   
    if($Full){
      Get-CIMInstance -ClassName win32_process -filter $Processfilter | & { process {
        $_
        if ($_.ParentProcessId -ne $_.ProcessId) {
          Get-ChildProcesses $_.ProcessId
        }
      }}
    }else{
      Get-CIMInstance -Class Win32_Process -Filter $Processfilter
    }
  }catch{
    write-ezlogs "An exception occurred in Get-ChildProcesses" -CatchError $_
  }
}
#--------------------------------------------- 
#endregion Get-ChildProcesses Function
#---------------------------------------------

#--------------------------------------------- 
#region Await Function
#---------------------------------------------  
function Wait-Task { 
  [cmdletbinding()]
  Param (
    [parameter(ValuefromPipeline=$True)]
    $Task
  )
  process {
    while (-not $task.AsyncWaitHandle.WaitOne(200)) { }
    return $task.GetAwaiter().GetResult()
  } 
}
#--------------------------------------------- 
#endregion Await Function
#---------------------------------------------  

#--------------------------------------------- 
#region Set-Window Function
#---------------------------------------------  
Function Set-Window {
  <#
      .SYNOPSIS
      Sets the window size (height,width) and coordinates (x,y) of
      a process window.
      .DESCRIPTION
      Sets the window size (height,width) and coordinates (x,y) of
      a process window.

      .PARAMETER ProcessName
      Name of the process to determine the window characteristics

      .PARAMETER X
      Set the position of the window in pixels from the top.

      .PARAMETER Y
      Set the position of the window in pixels from the left.

      .PARAMETER Width
      Set the width of the window.

      .PARAMETER Height
      Set the height of the window.

      .PARAMETER Passthru
      Display the output object of the window.

      .NOTES
      Name: Set-Window
      Author: Boe Prox
      Version History
      1.0//Boe Prox - 11/24/2015
      - Initial build

      .OUTPUT
      System.Automation.WindowInfo

      .EXAMPLE
      Get-Process powershell | Set-Window -X 2040 -Y 142 -Passthru

      ProcessName Size     TopLeft  BottomRight
      ----------- ----     -------  -----------
      powershell  1262,642 2040,142 3302,784   

      Description
      -----------
      Set the coordinates on the window for the process PowerShell.exe

  #>
  [OutputType('System.Automation.WindowInfo')]
  [cmdletbinding()]
  Param (
    [parameter(ValueFromPipelineByPropertyName=$True)]
    $ProcessName,
    $WindowHandle,
    [int]$X,
    [int]$Y,
    [int]$Width,
    [int]$Height,
    [switch]$Passthru
  )
  Begin {
    Try{
      if(-not [bool]('Window' -as [Type])){
        Add-Type @"
              using System;
              using System.Runtime.InteropServices;
              public class Window {
                [DllImport("user32.dll")]
                [return: MarshalAs(UnmanagedType.Bool)]
                public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

                [DllImport("User32.dll")]
                public extern static bool MoveWindow(IntPtr handle, int x, int y, int width, int height, bool redraw);
              }
              public struct RECT
              {
                public int Left;        // x position of upper-left corner
                public int Top;         // y position of upper-left corner
                public int Right;       // x position of lower-right corner
                public int Bottom;      // y position of lower-right corner
              }
"@
      }
    }Catch{
      write-ezlogs "An exception occurred adding new type 'Window'" -catcherror $_
    }
  }
  Process {
    $Rectangle = New-Object RECT
    if($WindowHandle){
      $Handle = $WindowHandle
    }else{
      $Handle = (Get-Process -id $ProcessName).MainWindowHandle
    }            
    $Return = [Window]::GetWindowRect($Handle,[ref]$Rectangle)
    If (-NOT $PSBoundParameters.ContainsKey('Width')) {            
      $Width = $Rectangle.Right - $Rectangle.Left            
    }
    If (-NOT $PSBoundParameters.ContainsKey('Height')) {
      $Height = $Rectangle.Bottom - $Rectangle.Top
    }
    If ($Return) {
      $Return = [Window]::MoveWindow($Handle, $x, $y, $Width, $Height,$True)
    }
    If ($PSBoundParameters.ContainsKey('Passthru')) {
      $Rectangle = New-Object RECT
      $Return = [Window]::GetWindowRect($Handle,[ref]$Rectangle)
      If ($Return) {
        $Height = $Rectangle.Bottom - $Rectangle.Top
        $Width = $Rectangle.Right - $Rectangle.Left
        $Size = New-Object System.Management.Automation.Host.Size -ArgumentList $Width, $Height
        $TopLeft = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Left, $Rectangle.Top
        $BottomRight = New-Object System.Management.Automation.Host.Coordinates -ArgumentList $Rectangle.Right, $Rectangle.Bottom
        If ($Rectangle.Top -lt 0 -AND $Rectangle.LEft -lt 0) {
          Write-warning "Window is minimized! Coordinates will not be accurate."
        }
        $Object = [PSCustomObject]@{
            ProcessName = $ProcessName
            Size = $Size
            TopLeft = $TopLeft
            BottomRight = $BottomRight
        }
        $Object.PSTypeNames.insert(0,'System.Automation.WindowInfo')
        $Object            
      }
    }
  }
}
#--------------------------------------------- 
#endregion Set-Window Function
#--------------------------------------------- 

#---------------------------------------------- 
#region Get-AllIndexesOf Function
#----------------------------------------------
function Get-AllIndexesOf
{
  [CmdletBinding()]
  param (
    [string]$SearchString,
    $InputObject,
    $synchash,
    $thisApp
  )

  if($InputObject){
    try{
      return [Linq.Enumerable]::Where(
        [Linq.Enumerable]::Range(0, $InputObject.Length), 
        [Func[int, bool]] { param($i) $InputObject[$i] -eq $SearchString }
      )
    }catch{
      write-ezlogs "An exception occured in Get-AllIndexesOf" -catcherror $_
    }
  }
}
#---------------------------------------------- 
#endregion Get-AllIndexesOf Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-IndexesOf Function
#----------------------------------------------
function Get-IndexesOf($Array, $Value) {
  $i = 0
  foreach ($el in $Array) { 
    if ($el -eq $Value) { $i } 
    ++$i
  }
}
#---------------------------------------------- 
#endregion Get-IndexesOf Function
#----------------------------------------------

#--------------------------------------------- 
#region Convert-Size Function
#---------------------------------------------
function Convert-Size {            
  [cmdletbinding()]            
  param(            
    [validateset("Bytes","KB","MB","GB","TB")]            
    [string]$From,            
    [validateset("Bytes","KB","MB","GB","TB")]            
    [string]$To,            
    [Parameter(Mandatory=$true)]            
    [double]$Value,            
    [int]$Precision = 4            
  )         
  try{
   
    switch($From) {            
      "Bytes" {$value = $Value }            
      "KB" {$value = $Value * 1024 }            
      "MB" {$value = $Value * 1024 * 1024}            
      "GB" {$value = $Value * 1024 * 1024 * 1024}            
      "TB" {$value = $Value * 1024 * 1024 * 1024 * 1024}            
    }            
            
    switch ($To) {            
      "Bytes" {return $value}            
      "KB" {$Value = $Value/1KB}            
      "MB" {$Value = $Value/1MB}            
      "GB" {$Value = $Value/1GB}            
      "TB" {$Value = $Value/1TB}            
            
    }            
            
    return [Math]::Round($value,$Precision,[MidPointRounding]::AwayFromZero)            
  }catch{
    write-ezlogs "An exception occurred in Convert-Size" -catcherror $_
  }           
}      
#--------------------------------------------- 
#endregion Convert-Size Function
#--------------------------------------------- 

#--------------------------------------------- 
#region Convertto-RelativeTime Function
#---------------------------------------------
function Convertto-RelativeTime {            
  [cmdletbinding()]            
  param(                      
    [DateTime]$Time            
  )         
  try{   
    if($Time){
      $SECOND = 1;
      $MINUTE = 60 * $SECOND;
      $HOUR = 60 * $MINUTE;
      $DAY = 24 * $HOUR;
      $MONTH = 30 * $DAY;
      $ts = [timespan]::new([Datetime]::UtcNow.Ticks - $Time.ticks)
      $delta = [Math]::Abs($ts.TotalSeconds);
      if($delta -lt 1 * $MINUTE){
        $RelativeTime = "$($ts.Seconds) seconds ago"
      }elseif($delta -lt 2 * $MINUTE){
        $RelativeTime = "a minute ago"
      }elseif($delta -lt 45 * $MINUTE){
        $RelativeTime = "$($ts.Minutes) minutes ago"
      }elseif($delta -lt 90 * $MINUTE){
        $RelativeTime = "an hour ago"
      }elseif($delta -lt 24 * $HOUR){
        $RelativeTime = "$($ts.Hours) hours ago"
      }elseif($delta -lt 48 * $HOUR){
        $RelativeTime = "yesterday"
      }elseif($delta -lt 30 * $DAY){
        if($ts.Days -eq 1){
          $RelativeTime = "$($ts.Days) day ago"
        }else{
          $RelativeTime = "$($ts.Days) days ago"
        }        
      }elseif($delta -lt 12 * $Month){
        $months = [Convert]::ToInt32([Math]::Floor([double]$ts.Days / 30));
        if($months -eq 1){
          $RelativeTime = "$($months) month ago"
        }else{
          $RelativeTime = "$($months) months ago"
        }
      }else{
        $years = [Convert]::ToInt32([Math]::Floor([double]$ts.Days / 365));
        if($years -eq 1){
          $RelativeTime = "$($years) year ago"
        }else{
          $RelativeTime = "$($years) years ago"
        }
      }
    }       
    return $RelativeTime            
  }catch{
    write-ezlogs "An exception occurred in Convertto-RelativeTime" -catcherror $_
  }           
}      
#--------------------------------------------- 
#endregion Convertto-RelativeTime Function
#--------------------------------------------- 

#---------------------------------------------
#region Wait-OnMutex Function
#---------------------------------------------
function Wait-OnMutex
{
  <#
      .SYNOPSIS
      Process/thread locking using Named Mutex
    
      .PARAMETER MutexId
      The string of mutex ID to assign/retrieve
    
      .EXAMPLE
      $MutexInstance = Wait-OnMutex -MutexId 'SomeMutexId12345'
    
      .NOTES
      Objects will be returned as Hashtables and not as pscustomobjects
  #>
  param(
    [parameter(Mandatory = $true)][string] $MutexId
  )

  try
  {
    $MutexInstance = [System.Threading.Mutex]::new($false, $MutexId)

    while (-not $MutexInstance.WaitOne(1000))
    {
      Start-Sleep -m 500;
    }

    return $MutexInstance
  } 
  catch [System.Threading.AbandonedMutexException] 
  {
    $MutexInstance = [System.Threading.Mutex]::new($false, $MutexId)
    return Wait-OnMutex -MutexId $MutexId
  }
}
#---------------------------------------------
#endregion Wait-OnMutex Function
#---------------------------------------------

#---------------------------------------------- 
#region ConvertFrom-Roman Function
#----------------------------------------------
function ConvertFrom-Roman {
  <#
      .EXAMPLE
      ConvertFrom-Roman XLVII # 47
      .EXAMPLE
      'dlxxvii' | ConvertFrom-Roman # 577
      .EXAMPLE
      ('mmxx', 'cdxxix', 'di').ForEach{ConvertFrom-Roman $_} # 2020, 429, 501
  #>
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)]
    [ValidatePattern('^(?=[MDCLXVI])M*(C[MD]|D?C{0,3})(X[CL]|L?X{0,3})(I[XV]|V?I{0,3})$')]
    [ValidateNotNullOrEmpty()]
    [String]$Number,
    [string]$String_With_Number,
    [switch]$Verboselog
  )
  process {
    if($verboselog){write-ezlogs ">>>> Checking and converting Roman Numerals in $String_With_Number" -showtime -enablelogs -color cyan}
    if($String_With_Number -match '\b(?=[MDCLXVI]+\b)M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})\b'){
      $number = $($matches[0])
      if($verboselog){write-ezlogs "Found Roman Numeral $number" -showtime -enablelogs}
      $map = @{I = 1; V = 5; X = 10; L = 50; C = 100; D = 500; M = 1000}
      for ($i, $a = 0, [Char[]]$Number; $i -lt $a.Length; $i++) {
        ${<}, ${>} = "$($a[$i])", "$($a[$i + 1])"
        $dec += [Int64]"$('+-'[$i + 1 -lt $a.Length -and $map[${<}] -lt $map[${>}]])$($map[${<}])"
      }
      if($verboselog){write-ezlogs " | Converted Roman Numeral $number to $dec" -showtime -enablelogs}
      $Coverted_String_With_Number = if($String_With_Number -match '\b(?=[MDCLXVI]+\b)M{0,4}(CM|CD|D?C{0,3})(XC|XL|L?X{0,3})(IX|IV|V?I{0,3})\b'){$String_With_Number -replace $matches[0],$dec}
      if($verboselog){write-ezlogs " | Converted string $String_With_Number to $Coverted_String_With_Number" -showtime -enablelogs}
      return $Coverted_String_With_Number
    }
    else{
      if($verboselog){write-ezlogs "No Roman Numerals found in string" -showtime -enablelogs -warning}
      return $String_With_Number
    }

  }
}
#---------------------------------------------- 
#endregion ConvertFrom-Roman Function
#----------------------------------------------

Export-ModuleMember -Function @(
  'Test-URL',
  'Test-Folder',
  'Open-FileDialog',
  'Open-FolderDialog',
  'Set-WindowState',
  'Get-IniFile',
  'Set-DrawingControl',
  'confirm-requirements',
  'ConvertTo-OrderedDictionary',
  'Convert-Color',
  'Convert-TimespanToInt',
  'Use-Runas',
  'Set-ChildWindow',
  'Get-CurrentWindows',
  'Optimize-Assemblies',
  'Test-ValidPath',
  'Lock-Object',
  'Clear-WorkingMemory',
  'Get-MemoryUsage',
  'Get-AllStartApps',
  'Get-VisualParentUp',
  'Use-Object',
  'Get-ChildProcesses',
  'Wait-Task',
  'Set-Window',
  'Get-IndexesOf',
  'Convert-Size',
  'Convertto-RelativeTime',
  'ConvertFrom-Roman'
) #-Alias 'Use'