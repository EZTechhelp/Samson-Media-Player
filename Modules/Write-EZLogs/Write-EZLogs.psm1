<#
    .Name
    Write-EZLogs

    .Version 
    0.3.2

    .SYNOPSIS
    Module that provides advanced console output formating and multi-threaded log writing.  

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher

    .RequiredModules
    Start-Runspace

    .EXAMPLE
    - $logfile = Start-EZLogs -logfile_directory "C:\Logs" -- Creates log file and directory (if not exists) and returns path to the log file. Log file name is "ScriptName-ScriptVersion.log"
    - Write-EZLogs "Message text I want output to console (as yellow) and log file, both with a timestamp" -color yellow -showtime

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES
    - Added ability to allow outputting to console only if no log file or directory is given vs trying to create a default log file
    - Added parameter catcherror for write-logs for quick error handling and logging
    - Added parameter verbosedebug to simulate write-verbose formatting
    - Added output of 'hours' for StopWatch timer logging
    - Set default of parameter LogDateFormat for Stop-EZLogs to match Start-EZLogs
#>
if(!$thisApp){
  $Global:thisapp = [hashtable]::Synchronized(@{})
}

#---------------------------------------------- 
#region Start EZLogs Function
#----------------------------------------------
function Start-EZLogs
{
  param (
    [switch]$Verboselog,
    [switch]$DevlogOnly,
    $thisApp = $thisApp,
    [string]$Logfile_Directory,
    [string]$Logfile_Name,
    [string]$Script_Name,
    [string]$logdateformat,
    [switch]$UseRunspacePool,
    [switch]$noheader,
    [switch]$Wait,
    [string]$Script_Description,
    [string]$Script_Version,
    [string]$ScriptPath,
    [switch]$Start_Timer,
    [switch]$StartLogWriter,
    [string]$Global_Log_Level,
    [ValidateSet('ascii','bigendianunicode','default','oem','string','unicode','unknown','utf32','utf7','utf8')]
    [string]$Encoding = 'unicode'
  )

  #Create out logging queue if not already to store all messages to be dequeued and written by the log writing runspace
  if(!$thisApp.LogMessageQueue){
    $thisApp.LogMessageQueue = [System.Collections.Concurrent.ConcurrentQueue`1[object]]::New()
  }
  #If enabled, create a global stopwatch timer. If provided, executing Stop-EZLogs will include total script runtime in the logging footer
  if($Start_Timer){$Global:globalstopwatch = [system.diagnostics.stopwatch]::StartNew()}

  #If no script path was provided, generate from pscommandpath
  if(!$ScriptPath){$ScriptPath = $PSCommandPath} 

  #Set default global log level if provided
  if((-not [string]::IsNullOrEmpty($Global_Log_Level) -and $thisApp.Config.Log_Level -eq $null -and $thisApp) -or ($thisApp.Dev)){
    $thisApp.Log_Level = $Global_Log_Level
  }elseif(-not [string]::IsNullOrEmpty($Global_Log_Level) -and $thisApp.Config){
    $thisApp.Config.Log_Level = $Global_Log_Level
  }elseif($thisApp.Config){
    $thisApp.Config.Log_Level = '2'
  }elseif($thisApp){
    $thisApp.Log_Level = '2'
  }
  #If no log directory provided manually, generate from source script location
  if(!$logfile_directory){
    #If script path was provided manually, use that directory, otherwise get from Myinvocation first, psscriptroot last
    #NOTE: PSScriptroot should not be used first as it will only provide the root path for this (write-ezlogs) script and not the potential source calling script
    if([System.IO.Path]::HasExtension($ScriptPath)){
      $logfile_directory = [System.IO.Directory]::GetParent($ScriptPath).FullName
      if([System.IO.Path]::HasExtension($logfile_directory)){
        $logfile_directory = [System.IO.Directory]::GetParent($logfile_directory).FullName
      }
    }elseif([System.IO.Path]::HasExtension($MyInvocation.ScriptName)){
      $logfile_directory = [System.IO.Directory]::GetParent($MyInvocation.ScriptName)
    }elseif([System.IO.Directory]::Exists($psScriptRoot)){
      $logfile_directory = $psScriptRoot
    }
  }

  #If name for log file not provided, generate from source script name
  if(!$logfile_name){
    $logfile_name = "$([System.IO.Path]::GetFileNameWithoutExtension($MyInvocation.ScriptName)).log"
  } 
  
  #Set full logfile path and create directory if needed 
  if($logfile_directory -and $logfile_name){
    $logfile = [System.IO.Path]::Combine($logfile_directory, $logfile_name)
    if (!([System.IO.Directory]::Exists($logfile_directory))){
      $null = New-Item -Path $logfile_directory -ItemType directory -Force
    }
  }

  #For dev testing only
  if($DevlogOnly){
    $Global:thisApp.Dev = $true
  }

  #If logfile is set and global hash is available, set to log_file key
  if(-not [string]::IsNullOrEmpty($logfile) -and $thisApp){
    $thisApp.Log_File = $logfile
  }

  if($logdateformat){
    $thisApp.LogDateTimeFormat = $logdateformat
  }else{
    $thisApp.LogDateTimeFormat = 'MM/dd/yyyy h:mm:ss tt'
  }

  #Create/Set the logging header if enabled
  if(!$noheader){  
    Write-ezlogs -showtime:$false -CallBack:$false -logOnly -Logheader -logfile $logfile -thisApp $thisApp
  }

  #Start the log writer runspace if logfile is set, otherwise no logging to file will happen and messages will only output to console

  if($StartLogWriter -and $logfile){
    Get-LogWriter -logfile $logfile -Startup -thisApp $thisApp -StartupWait:$Wait -Verboselog:$Verboselog
  }

  #Give the people what they want!
  return $logfile
}
#---------------------------------------------- 
#endregion Start EZLogs Function
#----------------------------------------------

#---------------------------------------------- 
#region Write-EZLogs Function
#----------------------------------------------
function Write-EZLogs 
{
  <#
      
      .CatchError
      Always Output to console/host and log file

      .Log Levels
      0  - No output to host or log file (disable all logging)
      1  - Output to console/host only
      2  - Ouput to log file only (Default)
      3  - Output to host and log file

  #>
  [CmdletBinding(DefaultParameterSetName = 'text')]
  param (
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
    [string]$text,
    $thisApp = $thisApp,
    [switch]$VerboseDebug,
    [switch]$Dev_mode,
    [switch]$enablelogs = $true,
    [string]$logfile,
    [switch]$Warning,
    [switch]$Success,
    [switch]$Perf,
    [switch]$PrintErrors,
    [array]$ErrorsToPrint,    
    [switch]$CallBack = $true,
    [switch]$Logheader,
    [switch]$isError,
    $PerfTimer,
    $CatchError,
    [switch]$ClearErrors = $true,
    $thisScript = $thisScript,
    $callpath = $callpath,
    [switch]$logOnly,
    [string]$DateTimeFormat = $thisApp.LogDateTimeFormat,
    [ValidateSet('Black','Blue','Cyan','Gray','Green','Magenta','Red','White','Yellow','DarkBlue','DarkCyan','DarkGreen','DarkMagenta','DarkRed','DarkYellow')]
    [string]$color = 'white',
    [ValidateSet('Black','Blue','Cyan','Gray','Green','Magenta','Red','White','Yellow','DarkBlue','DarkCyan','DarkGreen','DarkMagenta','DarkRed','DarkYellow')]
    [string]$foregroundcolor,
    [switch]$showtime = $true,
    [switch]$logtime,
    [switch]$AlertUI,
    [switch]$NoLogOutput,
    [switch]$NoNewLine,
    [switch]$GetMemoryUsage,
    [switch]$forceCollection,
    [int]$StartSpaces,
    [ValidateSet('Main','Twitch','Spotify','Youtube','Startup','Launcher','LocalMedia','VLC','Streamlink','Error','Discord','Libvlc','Perf','Webview2','Setup','Threading','Tor','Uninstall')]
    [string]$logtype = 'Main',
    [string]$Separator,
    [ValidateSet('Black','Blue','Cyan','Gray','Green','Magenta','Red','White','Yellow','DarkBlue','DarkCyan','DarkGreen','DarkMagenta','DarkRed','DarkYellow')]
    [string]$BackgroundColor,
    [int]$linesbefore,
    [int]$linesafter,
    [ValidateSet('ascii','bigendianunicode','default','oem','string','unicode','unknown','utf32','utf7','utf8')]
    [string]$Encoding = 'unicode',
    [ValidateSet('0','1','2','3','4')]
    [string]$LogLevel,
    [ValidateSet('0','1','2','3','4')]
    [string]$PriorityLevel = '0',
    [switch]$AlertAudio,
    [switch]$NoTypeHeader,
    $synchash = $synchash
  )
  begin {
    if($GetMemoryUsage -and $PriorityLevel -ge 3){
      $MemoryUsage = " | $(Get-MemoryUsage -forceCollection:$forceCollection)"
    }
    if($thisApp.Log_Level -ne $Null){
      $GlobalLogLevel = $thisApp.Log_Level
    }elseif($thisApp.Config.Log_Level -ne $Null){
      $GlobalLogLevel = $thisApp.Config.Log_Level
    }
    if(!$LogLevel -and $GlobalLogLevel -in '0','1','2','3','4'){
      $LogLevel = $GlobalLogLevel
    }
    if(!$NoLogOutput){
      if($CatchError -or $isError -or $PrintErrors){
        $enablelogs = $true
        $logtype = 'Error'
      }elseif($PerfTimer -or $Perf){
        $enablelogs = $true
        $logtype = 'Perf'
        $logOnly = $true
      }elseif($GlobalLogLevel -eq '0' -or $loglevel -eq '0'){
        $enablelogs = $false
        $done = $true
        return
      }elseif($LogLevel -eq '1' -and $LogLevel -le $GlobalLogLevel){
        $enablelogs = $false
      }elseif($LogLevel -eq '2' -and $logLevel -le $GlobalLogLevel){
        $enablelogs = $true
        $logOnly = $true
      }elseif($LogLevel -eq '3' -and $logLevel -le $GlobalLogLevel){
        $enablelogs = $true
      }elseif($LogLevel -eq '4' -and $logLevel -le $GlobalLogLevel){
        $enablelogs = $true
        $VerboseDebug = $true
      }elseif($LogLevel -gt $GlobalLogLevel -and -not [string]::IsNullOrEmpty($GlobalLogLevel)){
        $enablelogs = $false
        $done = $true
        return
      }elseif([string]::IsNullOrEmpty($GlobalLogLevel) -and -not [string]::IsNullOrEmpty($LogLevel)){
        $enablelogs = $true
      }
      if($Dev_mode -and $thisApp.Config.Dev_mode){
        $enablelogs = $true
        $logOnly = $true
        $VerboseDebug = $true
      }elseif($Dev_mode -and !$thisApp.Dev){
        $enablelogs = $false
        $done = $true
        return
      }
      if(!$thisApp.Dev -and [string]::IsNullOrEmpty($logfile)){
        switch ($logtype) {
          'Main' {
            if(-not [string]::IsNullOrEmpty($thisApp.Config.Log_file)){
              $logfile = $thisApp.Config.Log_file
            }elseif(-not [string]::IsNullOrEmpty($thisApp.Log_file)){
              $logfile = $thisApp.Log_file
            }elseif($thisScript.Name -and -not [string]::IsNullOrEmpty($logfile_directory)){
              $logfile = "$logfile_directory\$($thisScript.Name)-$($thisScript.Version).log"
            }
          }
          'Twitch' {
            $logfile = $thisApp.Config.TwitchMedia_logfile
          }
          'Spotify' {
            $logfile = $thisApp.Config.SpotifyMedia_logfile
          }
          'Youtube' {
            $logfile = $thisApp.Config.YoutubeMedia_logfile
          }
          'Startup' {
            if(-not [string]::IsNullOrEmpty($thisApp.Config.Startup_Log_File)){
              $logfile = $thisApp.Config.Startup_Log_File
            }elseif(-not [string]::IsNullOrEmpty($thisApp.Config.Log_file)){
              $logfile = $thisApp.Config.Log_file
            }
          }
          'Launcher' {
            if(-not [string]::IsNullOrEmpty($thisApp.Config.Launcher_Log_File)){
              $logfile = $thisApp.Config.Launcher_Log_File
            }elseif(-not [string]::IsNullOrEmpty($thisApp.Config.Log_file)){
              $logfile = $thisApp.Config.Log_file
            }
          }
          'LocalMedia' {
            $logfile = $thisApp.Config.LocalMedia_Log_File
          }
          'VLC' {
            $logfile = $thisApp.Config.VLC_Log_File
          }
          'Streamlink' {
            $logfile = $thisApp.Config.Streamlink_Log_File
            $Encoding = 'utf8'
          }
          'Error' {
            if(-not [string]::IsNullOrEmpty($thisApp.Config.Error_Log_File)){
              $logfile = $thisApp.Config.Error_Log_File
            }elseif(-not [string]::IsNullOrEmpty($thisApp.Config.Log_file)){
              $logfile = $thisApp.Config.Log_file
            }
          }
          'Discord' {
            $logfile = $thisApp.Config.Discord_Log_File
          }
          'Libvlc' {
            $logfile = $thisApp.Config.Libvlc_Log_File
          }
          'Perf' {
            if(-not [string]::IsNullOrEmpty($thisApp.Config.Perf_Log_File)){
              $logfile = $thisApp.Config.Perf_Log_File
            }elseif(-not [string]::IsNullOrEmpty($thisApp.Config.Log_file)){
              $logfile = $thisApp.Config.Log_file
            }
            $Perf = $true
          }
          'Webview2' {
            if(-not [string]::IsNullOrEmpty($thisApp.Config.Webview2_Log_File)){
              $logfile = $thisApp.Config.Webview2_Log_File
            }elseif(-not [string]::IsNullOrEmpty($thisApp.Config.Log_file)){
              $logfile = $thisApp.Config.Log_file
            }
          }
          'Setup' {
            if(-not [string]::IsNullOrEmpty($thisApp.Config.Setup_Log_File)){
              $logfile = $thisApp.Config.Setup_Log_File
            }elseif(-not [string]::IsNullOrEmpty($thisApp.Config.Log_file)){
              $logfile = $thisApp.Config.Log_file
            }
          }
          'Threading' {
            if(-not [string]::IsNullOrEmpty($thisApp.Config.Threading_Log_File)){
              $logfile = $thisApp.Config.Threading_Log_File
            }elseif(-not [string]::IsNullOrEmpty($thisApp.Config.Log_file)){
              $logfile = $thisApp.Config.Log_file
            } 
          }
          'Tor' {
            $logfile = $thisApp.Config.Tor_Log_File
          }
          'RDP' {
            $logfile = $thisApp.Config.RDP_Log_File
          }
          'OpenVPN' {
            $logfile = $thisApp.Config.OpenVPN_Log_File
          }
          'Uninstall' {
            $logfile = $thisApp.Config.Uninstall_Log_File
          }
        }
      }
    }
    
    if([string]::IsNullOrEmpty($thisApp.Config.Log_file) -and [string]::IsNullOrEmpty($logfile) -and [string]::IsNullOrEmpty($thisApp.Log_file) -and [string]::IsNullOrEmpty($thisApp)){
      $script:thisapp = [hashtable]::Synchronized(@{})
    }
    if(!$AlertUI){
      switch ($PriorityLevel) {
        '0' {
          $AlertUI = $false
        }
        '4' {
          $AlertUI = $false
        }
        '3' {
          $AlertUI = $false
        }
        '2' {
          $AlertUI = $true
        }
        '1' {
          $AlertUI = $true
        }
      }
    }  
    if([string]::IsNullOrEmpty($logfile) -and -not [string]::IsNullOrEmpty($thisApp.Log_file)){
      $logfile = $thisApp.Log_file
    }elseif([string]::IsNullOrEmpty($logfile) -and -not [string]::IsNullOrEmpty($thisApp.Config.Log_file)){ 
      $logfile = $thisApp.Config.Log_file
    }elseif([string]::IsNullOrEmpty($logfile)){
      $enablelogs = $false
    }
    if($showtime -and !$logtime){$logtime = $true}else{$logtime = $false}
    if($success){
      $color = 'Green'
    }elseif($foregroundcolor){
      $color = $foregroundcolor
    }
    if($showtime){
      $timestamp = "[$([datetime]::Now.ToString($DateTimeFormat))] "
    }else{
      $timestamp = $Null
    }
  }
  process {
    if($done){return}
    if($AlertUI){
      $AlertMessage = $text
      if($Warning){
        $Level = 'WARNING'
        $messagebox = 'Warning'
      }elseif($Success){
        $Level = 'SUCCESS'
        $messagebox = 'Information'
      }elseif($logtype -eq 'Error'){
        $Level = 'ERROR'
        $messagebox = 'Error'
        if($CatchError){
          $PositionMessage = "At line:$($catcherror.InvocationInfo.ScriptLineNumber) char:$($catcherror.InvocationInfo.OffsetInLine)`n$(if($catcherror.InvocationInfo.ScriptName){"at: $($catcherror.InvocationInfo.ScriptName)"}else{$catcherror.ScriptStackTrace})`nat: $($catcherror.InvocationInfo.InvocationName)`n+ $($catcherror.InvocationInfo.Line)"
          $AlertMessage = "$AlertMessage`:`n`n$($catcherror.Exception.Message)`n`n$PositionMessage`n`n$($catcherror.Exception.StackTrace | out-string)"
        }
      }else{
        $Level = 'INFO'
        $messagebox = 'Information'
      }
      try{
        if($synchash.MiniPlayer_Viewer.isVisible){
          try{
            Import-Module "$($thisApp.Config.Current_Folder)\Modules\BurntToast\BurntToast.psm1" -NoClobber -DisableNameChecking -Scope Local
            if($thisApp.Config.Installed_AppID){
              $appid = $thisApp.Config.Installed_AppID
            }else{
              $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID 
              $thisApp.Config.Installed_AppID = $appid
            }
            $Guid = [System.Guid]::NewGuid()
            if($Guid){
              [string]$Id = 'ID' + ($Guid.Guid -Replace'-','').ToUpper()
            }
            $Title = "$Level - $logtype"
            $Header = [Microsoft.Toolkit.Uwp.Notifications.ToastHeader]::new($Id, ($Title -replace '\x01'), $null)
            New-BurntToastNotification -AppID $appid -Text "$AlertMessage" -AppLogo "$($thisApp.Config.Current_Folder)\Resources\Samson_Icon_NoText1.ico" -Header $Header
          }catch{
            $Exception_MSG = $_.Exception
            $PositionMessage = $_.InvocationInfo.PositionMessage | out-string
            $PSCommandPathMSG = $_.InvocationInfo.PSCommandPath | out-string
            $ScriptStackTrace_MSG = $_.ScriptStackTrace  | out-string
            $InvocationName_MSG = $_.InvocationInfo.InvocationName | out-string
            $MyCommand_MSG = $_.InvocationInfo.MyCommand
            $BoundParameters_MSG = $_.InvocationInfo.BoundParameters | out-string
            $UnboundArguments_MSG = $_.InvocationInfo.UnboundArguments | out-string
            $Error_text = @"
[WRITE-EZLOGS-ERROR] An exception occurred processing UI alerts in Write-ezlogs: $($AlertMessage):
|+ [Exception]: $($Exception_MSG)

|+ [PositionMessage]: $PositionMessage

|+ [ScriptStackTrace]: $ScriptStackTrace_MSG

|+ [PSCommandPath]: $PSCommandPathMSG

|+ [InvocationName]: $InvocationName_MSG

|+ [MyCommand]: $MyCommand_MSG

|+ [BoundParameters]: $BoundParameters_MSG

|+ [UnboundArguments]: $UnboundArguments_MSG

=========================================================================
"@
            if($logfile){[System.IO.File]::AppendAllText($logfile, "$Error_text" + ([Environment]::NewLine),[System.Text.Encoding]::$Encoding)}else{throw $_}
          }
        }elseif($synchash.Window.isVisible){
          Update-Notifications -Level $Level -Message "$logtype`: $AlertMessage" -thisApp $thisapp -synchash $synchash -Open_Flyout -MessageFontWeight bold -LevelFontWeight Bold -EnableAudio:$AlertAudio
        }else{
          [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
          [void][System.Windows.Forms.MessageBox]::Show("[$Level - $logtype]: $AlertMessage","$($thisApp.Config.App_Name) Media Player",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::$messagebox)
        }
      }catch{
        if($logfile){[System.IO.File]::AppendAllText($logfile, "An exception occurred calling Update-Notifications in Write-ezlogs: $($_ | out-string)" + ([Environment]::NewLine),[System.Text.Encoding]::$Encoding)}else{throw $_}
      }
    }
    try{
      if($CallBack){  
        if($callpath){
          if($callpath -notmatch "\:"){
            $callpath += ":$((Get-PSCallStack)[1].Position.StartLineNumber -join ':')"
          }
          $invocation = "$callpath"
        }elseif($(Get-PSCallStack)[1].Command -notmatch 'ScriptBlock' -and $MyInvocation.PSCommandPath -notmatch "(?<value>.*)\\(?<value>.*).ps"){
          $invocation = "$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].Position.StartLineNumber -join ':')"
        }elseif($($MyInvocation.PSCommandPath -match "(?<value>.*)\\(?<value>.*).ps")){
          $invocation = "$($matches.Value):$($MyInvocation.ScriptLineNumber)"
        }
        if($invocation){
          $text = "[$($invocation)] $text"
          $callpath = "[$($invocation)]"
        }elseif($text -notmatch "\[$((Get-PSCallStack)[1].FunctionName)\]"){
          if($((Get-PSCallStack)[1].FunctionName) -match 'ScriptBlock'){
            $callpath = "[$((Get-PSCallStack)[1].FunctionName):$((Get-PSCallStack)[1].Position.StartLineNumber)]"
            $text = "$callpath $text"
          }else{
            $callpath = "[$((Get-PSCallStack)[1].FunctionName)]"
            $text = "$callpath $text"
          }    
        } 
      }
    }catch{
      if($logfile){[System.IO.File]::AppendAllText($logfile, "An exception occurred processing callpaths in Write-ezlogs: $($_ | out-string)" + ([Environment]::NewLine),[System.Text.Encoding]::$Encoding)}else{throw $_}
    }
    if(!$NoLogOutput){
      #Log output
      try{
        if(!$thisApp.LogMessageQueue){
          $thisApp.LogMessageQueue = [System.Collections.Concurrent.ConcurrentQueue`1[object]]::New()
        }
        [void]$thisApp.LogMessageQueue.Enqueue([PSCustomObject]::new(@{
              'text' = $text
              'VerboseDebug' = $VerboseDebug
              'enablelogs' = $enablelogs
              'logfile' = $logfile
              'Warning' = $Warning
              'PERF' = $Perf
              'Dev_mode' = $Dev_mode
              'MemoryUsage' = $MemoryUsage
              'PerfTimer' = $Perftimer
              'Success' = $Success
              'iserror' = $iserror
              'PrintErrors' = $PrintErrors
              'ErrorsToPrint' = $ErrorsToPrint
              'CallBack' = $CallBack
              'callpath' = $callpath
              'logOnly' = $logOnly
              'Logheader' = $Logheader
              'timestamp' = $timestamp
              'DateTimeFormat' = $DateTimeFormat
              'color' = $color
              'foregroundcolor' = $foregroundcolor
              'showtime' = $showtime
              'logtime' = $logtime
              'NoNewLine' = $NoNewLine    
              'StartSpaces' = $StartSpaces
              'Separator' = $Separator
              'BackgroundColor' = $BackgroundColor
              'linesbefore' = $linesbefore
              'linesafter' = $linesafter
              'CatchError' = $CatchError
              'ClearErrors' = $ClearErrors
              'Encoding' = $Encoding
              'LogLevel' = $LogLevel
              'GlobalLogLevel' = $GlobalLogLevel
              'ProcessMessage' = $true
              'NoTypeHeader' = $NoTypeHeader
        }))
      }catch{
        $Exception_MSG = $_.Exception
        $PositionMessage = $_.InvocationInfo.PositionMessage | out-string
        $PSCommandPathMSG = $_.InvocationInfo.PSCommandPath | out-string
        $ScriptStackTrace_MSG = $_.ScriptStackTrace  | out-string
        $InvocationName_MSG = $_.InvocationInfo.InvocationName | out-string
        $MyCommand_MSG = $_.InvocationInfo.MyCommand
        $BoundParameters_MSG = $_.InvocationInfo.BoundParameters | out-string
        $UnboundArguments_MSG = $_.InvocationInfo.UnboundArguments | out-string
        $Error_text = @"
[WRITE-EZLOGS-ERROR] An exception occurred trying enqueue new message: $($text):
|+ [Exception]: $($Exception_MSG)

|+ [PositionMessage]: $PositionMessage

|+ [ScriptStackTrace]: $ScriptStackTrace_MSG

|+ [PSCommandPath]: $PSCommandPathMSG

|+ [InvocationName]: $InvocationName_MSG

|+ [MyCommand]: $MyCommand_MSG

|+ [BoundParameters]: $BoundParameters_MSG

|+ [UnboundArguments]: $UnboundArguments_MSG

=========================================================================
"@

        if(-not [string]::IsNullOrEmpty($logfile)){
          write-output "$Error_text" | Out-File -FilePath $logfile -Encoding $Encoding -Append -Force
        }else{
          write-error "$Error_text"
        }
      }
      if(!$logOnly){
        if($LinesBefore -ne 0){ for ($i = 0; $i -lt $LinesBefore; $i++) {
            write-host "`n" -NoNewline
          }
        }
        if($CatchError){
          $text = "[ERROR] $text at: $($CatchError | out-string)`n";$color = "red"
        }
        if($PrintErrors -and $ErrorsToPrint -is [array]){   
          Write-Host -Object "$text$timestamp[PRINT ALL ERRORS]" -ForegroundColor Red
          $e_index = 0
          foreach ($e in $ErrorsToPrint)
          {
            $e_index++
            Write-Host -Object "[$([datetime]::Now)] [ERROR $e_index Message] =========================================================================`n$($e.Exception | out-string)`n |+ $($e.InvocationInfo.PositionMessage)`n |+ $($e.ScriptStackTrace)`n`n" -ForegroundColor Red;        
          }
          return  
        }
        if($Warning -and $VerboseDebug){
          if($showtime){
            Write-Host -Object "[$([datetime]::Now.ToString($DateTimeFormat))] " -NoNewline
          }
          Write-Warning ($wrn = "[DEBUG] $text")
        }elseif($warning){
          if($showtime){
            Write-Host -Object "[$([datetime]::Now.ToString($DateTimeFormat))] " -NoNewline
          }
          Write-Warning ($wrn = "$text")  
        }elseif($Success){
          if($showtime){
            Write-Host -Object "[$([datetime]::Now.ToString($DateTimeFormat))] " -NoNewline
          }
          if($BackGroundColor){
            Write-Host -Object "[SUCCESS] $text" -ForegroundColor:$Color -NoNewline:$NoNewLine -BackgroundColor:$BackGroundColor
          }else{
            Write-Host -Object "[SUCCESS] $text" -ForegroundColor:$Color -NoNewline:$NoNewLine
          }
        }elseif($Perf){
          if($showtime){
            Write-Host -Object "[$([datetime]::Now.ToString($DateTimeFormat))] " -NoNewline
          }
          try{
            if($NoTypeHeader){
              $TypeHeader = $Null
            }else{
              $TypeHeader = '[PERF] '
            }
            if($Perftimer -is [system.diagnostics.stopwatch]){
              Write-Host -Object "$TypeHeader$text`:`n| Mins: $($Perftimer.Elapsed.Minutes)`n| Secs: $($Perftimer.Elapsed.Seconds)`n| Mils: $($Perftimer.Elapsed.Milliseconds)$($MemoryUsage)" -ForegroundColor:$Color -NoNewline:$NoNewLine
            }elseif($Perftimer -is [Timespan]){
              Write-Host -Object "$TypeHeader$text`: | Mins: $($Perftimer.Minutes) Secs: $($Perftimer.Seconds) Ms: $($Perftimer.Milliseconds)$($MemoryUsage)" -ForegroundColor:$Color -NoNewline:$NoNewLine
            }else{
              Write-Host -Object "$TypeHeader$text$($MemoryUsage)" -ForegroundColor:$Color -NoNewline:$NoNewLine
            }
          }catch{
            start-sleep -Milliseconds 100
            Write-Output "$($timestamp)$TypeHeader$text`n[$([datetime]::Now)] [ERROR] [WRITE-EZLOGS-LOGONLY-PERF] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string)" | Out-File -FilePath $logfile -Encoding $Encoding -Append -NoNewline:$NoNewLine
          }
        }else{
          if($showtime){
            Write-Host -Object "[$([datetime]::Now.ToString($DateTimeFormat))] " -NoNewline
          }
          if($BackGroundColor){
            Write-Host -Object $text -ForegroundColor:$Color -NoNewline:$NoNewLine -BackgroundColor:$BackGroundColor
          }else{
            Write-Host -Object $text -ForegroundColor:$Color -NoNewline:$NoNewLine
          }    
        }     
        
        if($LinesAfter -ne 0){
          for ($i = 0; $i -lt $LinesAfter; $i++) {
            write-host "`n" -NoNewline  
          }
        }
      }
    }
    return
  }
}
#---------------------------------------------- 
#endregion Write-EZLogs Function
#----------------------------------------------

#---------------------------------------------- 
#region Write-LogMessage Function
#----------------------------------------------
function Write-LogMessage {
  param (
    $thisApp,
    [string]$logfile,
    $thisScript,
    [switch]$Startup,
    [switch]$shutdownWait,
    [switch]$StartupWait,
    [switch]$shutdown
  )
  try{
    #TODO: Refactor all of this, most importantly implement StringBuilder to build entire string then only one scripblock needed to actually write to file
    $Message = @{}
    $ProcessMessage = $thisApp.LogMessageQueue.TryDequeue([ref]$message)
    $text = $($message.text)
    if($ProcessMessage -and $Message.ProcessMessage){
      $sb = [System.Text.StringBuilder]::new()
      if($Message.LinesBefore -ne 0){
        try{
          for ($i = 0; $i -lt $Message.LinesBefore; $i++) {
            [void]$sb.AppendLine('')
          }
        }catch{
          start-sleep -Milliseconds 100
          [System.IO.File]::AppendAllText($message.logfile, "[ERROR] [WRITE-EZLOGS-LinesBefore]: $_ -- Original String: $($sb.ToString())" + ([Environment]::NewLine),[System.Text.Encoding]::$($message.Encoding))
        }       
      }
      if($message.Logheader){
        if([string]::IsNullOrEmpty($thisApp.Config.App_Name) -and -not [string]::IsNullOrEmpty($thisScript.Name)){
          $Script_Name = $($thisScript.Name)
        }else{
          $Script_Name = $($thisApp.Config.App_Name)
        }
        if(-not [string]::IsNullOrEmpty($thisScript.SYNOPSIS)){
          $Script_Description = $($thisScript.SYNOPSIS).trim()
        }
        if([string]::IsNullOrEmpty($thisApp.Config.App_Version) -and -not [string]::IsNullOrEmpty($thisScript.Version)){
          $Script_Version = $($thisScript.Version)
        }else{
          $Script_Version = $($thisApp.Config.App_Version)
        }
        if([string]::IsNullOrEmpty($thisApp.Config.App_Build) -and -not [string]::IsNullOrEmpty($thisScript.Build)){
          $Script_Build = $($thisScript.Build)
        }else{
          $Script_Build = $($thisApp.Config.App_Build)
        }
        #ManagementObjectSearcher is faster than Get-CimInstance
        $query = [System.Management.ObjectQuery]::new("SELECT Caption,Version,FreePhysicalMemory,LastBootUpTime FROM Win32_OperatingSystem")
        $searcher = [System.Management.ManagementObjectSearcher]::new($query)
        $results = $searcher.get()    
        $searcher.Dispose()
        $LAST_UP_TIME = [DateTime]::Now.Subtract([Timespan]::FromSeconds([System.Diagnostics.Stopwatch]::GetTimestamp() / [System.Diagnostics.Stopwatch]::Frequency)).ToString()
        #$LAST_UP_TIME = ($results | Select-Object @{LABEL='LastBootUpTime';EXPRESSION={$_.ConverttoDateTime($_.lastbootuptime)}}).LastBootUpTime
        if($LAST_UP_TIME){
          $LAST_UP_TIME = $LAST_UP_TIME.toString()
        }else{
          $LAST_UP_TIME = $results.LastBootUpTime
        }
        if($message.GlobalLogLevel -ge 2){
          $query = [System.Management.ObjectQuery]::new("SELECT Manufacturer,Version FROM Win32_BIOS")
          $searcher = [System.Management.ManagementObjectSearcher]::new($query)
          $bios_info = $searcher.get()
          $searcher.Dispose()    
          $query = [System.Management.ObjectQuery]::new("SELECT name FROM Win32_Processor")
          $searcher = [System.Management.ManagementObjectSearcher]::new($query)
          $cpu_info = $searcher.get()
          $searcher.Dispose()
          $searcher = $null
        }
        if($message.LogHeader_Audio -and [bool]('CSCore.CoreAudioAPI.MMDeviceEnumerator' -as [type])){
          try{
            $default_output_Device = [CSCore.CoreAudioAPI.MMDeviceEnumerator]::DefaultAudioEndpoint([CSCore.CoreAudioAPI.DataFlow]::Render,[CSCore.CoreAudioAPI.Role]::Multimedia)
          }catch{
            [System.IO.File]::AppendAllText($message.logfile, "`n$($message.timestamp)[ERROR] [WRITE-EZLOGS-Logheader] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string)" + ([Environment]::NewLine),[System.Text.Encoding]::$($message.Encoding))
          }
        }
        $text = @"
`n###################### Logging Enabled ######################
Script Name          : $Script_Name
Synopsis             : $Script_Description
Log File             : $($message.logfile)
Log Level            : $($message.GlobalLogLevel)
Version              : $Script_Version
Build                : $Script_Build
Current Username     : $env:username
Powershell           : $($PSVersionTable.psversion)($($PSVersionTable.psedition))
Computer Name        : $env:computername
Operating System     : $($results.Caption)($($results.Version))
CPU                  : $($cpu_info.name) | Cores: $($env:NUMBER_OF_PROCESSORS)
RAM                  : $([Math]::Round([int64]($results.TotalVisibleMemorySize)/1MB,2)) GB (Available: $([Math]::Round([int64]($results.FreePhysicalMemory)/1MB,2)) GB)
Manufacturer         : $($bios_info.Manufacturer)
Model                : $($bios_info.Version)
Serial Number        : NA
Domain               : $env:USERDOMAIN
Install Date         : $([System.IO.FIleInfo]::new("$env:SystemRoot\system.ini").CreationTime.ToString())
Last Boot Up Time    : $LAST_UP_TIME
Windows Directory    : $env:windir
Default Audio Device : $($default_output_Device.FriendlyName)
###################### Logging Started - [$([datetime]::Now)] ##########################
"@          
        if($default_output_Device -is [System.IDisposable]){
          $default_output_Device.dispose()
        }    
      }
      if($message.CatchError){
        try{
          $message.color = "red"
          $text = @"
[ERROR] $text$($message.MemoryUsage):
|+ [Exception]: $($message.CatchError.Exception)

|+ [PositionMessage]: $($message.CatchError.InvocationInfo.PositionMessage)
$(if(-not [string]::IsNullOrEmpty(($message.CatchError.Exception.InnerException.Source))){"
|+ [Source]: $($message.CatchError.Exception.InnerException.Source)`n"})
|+ [ScriptStackTrace]: $($message.CatchError.ScriptStackTrace)
$(if(-not [string]::IsNullOrEmpty(($message.CatchError.Exception.InnerException.BaseUri))){"
|+ [BaseUri]: $($message.CatchError.Exception.InnerException.BaseUri)"})
$(if($message.CatchError.MyInvocation){"
|+ [MyInvocation]: $($message.CatchError.MyInvocation | out-string)"}elseif($message.CatchError.InvocationInfo){"
|+ [InvocationInfo]: $($message.CatchError.InvocationInfo | out-string)"})
$(if($message.CatchError.InvocationInfo.BoundParameters.count){"
|+ [BoundParameters]: $($message.CatchError.InvocationInfo.BoundParameters | out-string)"})
$(if(-not [string]::IsNullOrEmpty(($message.CatchError.InvocationInfo.UnboundArguments))){"
|+ [UnboundArguments]: $($message.CatchError.InvocationInfo.UnboundArguments | out-string)"})
=========================================================================

"@
        }catch{
          start-sleep -Milliseconds 100
          if($message.logfile){[System.IO.File]::AppendAllText($message.logfile, "`n$($message.timestamp)[ERROR] [WRITE-EZLOGS-CatchError] [$((Get-PSCallStack)[0].FunctionName) - $($message.callpath)] `n $($_ | out-string)" + ([Environment]::NewLine),[System.Text.Encoding]::$($message.Encoding))}else{throw "[ERROR] [WRITE-EZLOGS-CatchError] $_"}
        }finally{
          if($message.ClearErrors){
            $error.clear()
          }
        }  
      }
      if($message.PrintErrors -and $message.ErrorsToPrint -is [array]){
        try{
          $e_index = 0
          foreach ($e in $message.ErrorsToPrint)
          {
            $e_index++
            [void]$sb.AppendLine("[$([datetime]::Now)] [PRINT ERROR $e_index Message] =========================================================================`n[Exception]: $($e.Exception)`n`n|+ [PositionMessage]: $($e.InvocationInfo.PositionMessage)`n`n|+ [ScriptStackTrace]: $($e.ScriptStackTrace)`n-------------------------------------------------------------------------`n`n")      
          }
          [System.IO.File]::AppendAllText($message.logfile, "$($sb.ToString())",[System.Text.Encoding]::Unicode) 
        }catch{ 
          start-sleep -Milliseconds 100
          $e_index = 0
          $sb = [System.Text.StringBuilder]::new()
          foreach ($e in $message.ErrorsToPrint)
          {
            $e_index++
            [void]$sb.AppendLine("[$([datetime]::Now)] [PRINT ERROR $e_index Message] =========================================================================`n[Exception]: $($e.Exception)`n`n|+ [PositionMessage]: $($e.InvocationInfo.PositionMessage)`n`n|+ [ScriptStackTrace]: $($e.ScriptStackTrace)`n-------------------------------------------------------------------------`n`n")        
          }
          [System.IO.File]::AppendAllText($message.logfile, ("$text$($message.timestamp) [ERROR] [WRITE-EZLOGS] [$((Get-PSCallStack)[1].FunctionName)] `n $($_.Exception | out-string)`n |+ $($_.InvocationInfo.PositionMessage)`n |+ $($_.ScriptStackTrace)") + "Original String: $($sb.ToString())",[System.Text.Encoding]::Unicode)
        }finally{
          if($message.ClearErrors){
            $error.clear()
          }
        }
        return
      }  
      if($message.enablelogs){
        if($message.VerboseDebug -and $message.warning){
          try{
            [void]$sb.AppendLine("$($message.timestamp)[DEBUG] [WARNING] $text$($message.MemoryUsage)")
          }catch{
            start-sleep -Milliseconds 100
            if($message.logfile){
              [System.IO.File]::AppendAllText($message.logfile, "$($message.timestamp)[DEBUG] [WARNING] $text$($message.MemoryUsage)`n[$([datetime]::Now)] [ERROR] [WRITE-EZLOGS-LOGONLY-WARNING-DEBUG] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string)" + ([Environment]::NewLine),[System.Text.Encoding]::$($message.Encoding))
            }else{
              throw "[ERROR] [WRITE-EZLOGS-LOGONLY-WARNING-DEBUG] [$((Get-PSCallStack)[1].FunctionName)] $_"
            }
          }                    
        }elseif($message.Warning){
          try{
            [void]$sb.AppendLine("$($message.timestamp)[WARNING] $text$($message.MemoryUsage)")
          }catch{
            start-sleep -Milliseconds 100
            if($message.logfile){
              [System.IO.File]::AppendAllText($message.logfile, "$($message.timestamp)[WARNING] $text$($message.MemoryUsage)`n[$([datetime]::Now)] [ERROR] [WRITE-EZLOGS-LOGONLY-WARNING] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string)" + ([Environment]::NewLine),[System.Text.Encoding]::$($message.Encoding))
            }else{
              throw "[ERROR] [WRITE-EZLOGS-LOGONLY-WARNING] [$((Get-PSCallStack)[1].FunctionName)] $_"
            } 
          }    
        }elseif($message.Success){
          try{
            [void]$sb.AppendLine("$($message.timestamp)[SUCCESS] $text$($message.MemoryUsage)")
          }catch{
            start-sleep -Milliseconds 100
            if($message.logfile){
              [System.IO.File]::AppendAllText($message.logfile, "$($message.timestamp)[SUCCESS] $text$($message.MemoryUsage)`n[$([datetime]::Now)] [ERROR] [WRITE-EZLOGS-LOGONLY-SUCCESS] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string)" + ([Environment]::NewLine),[System.Text.Encoding]::$($message.Encoding))
            }else{
              throw "[ERROR] [WRITE-EZLOGS-LOGONLY-SUCCESS] [$((Get-PSCallStack)[1].FunctionName)] $_"
            }  
          }   
        }elseif($message.isError){
          try{
            [void]$sb.AppendLine("$($message.timestamp)[ERROR] $text$($message.MemoryUsage)")
          }catch{
            start-sleep -Milliseconds 100
            if($message.logfile){
              [System.IO.File]::AppendAllText($message.logfile, "$($message.timestamp)[ERROR] $text$($message.MemoryUsage)`n[$([datetime]::Now)] [ERROR] [WRITE-EZLOGS-LOGONLY-SUCCESS] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string)" + ([Environment]::NewLine),[System.Text.Encoding]::$($message.Encoding))
            }else{
              throw "[ERROR] [WRITE-EZLOGS-LOGONLY-SUCCESS] [$((Get-PSCallStack)[1].FunctionName)] $_"
            }
          }      
        }elseif($message.PERF){
          try{
            if($message.NoTypeHeader){
              $TypeHeader = $Null
            }else{
              $TypeHeader = '[PERF] '
            }
            if($message.Perftimer -is [system.diagnostics.stopwatch]){
              if($message.Perftimer.Elapsed.Minutes -gt 0 -or $message.Perftimer.Elapsed.hours -gt 0){
                $perfstate = '[+HIGHLOAD]: '
              }elseif($message.Perftimer.Elapsed.Seconds -gt 0){
                $perfstate = '[WARNING] '
              }else{
                $perfstate = ''
              }    
              [void]$sb.AppendLine("$($message.timestamp)$perfstate$TypeHeader$text | Time: $($message.Perftimer.Elapsed.hours):$($message.Perftimer.Elapsed.Minutes):$($message.Perftimer.Elapsed.Seconds):$(([string]$message.Perftimer.Elapsed.Milliseconds).PadLeft(3,'0'))$($message.MemoryUsage)")                 
            }elseif($message.Perftimer -is [Timespan]){
              if($message.Perftimer.Minutes -gt 0 -or $message.Perftimer.hours -gt 0){
                $perfstate = '[+HIGHLOAD]: '
              }elseif($message.Perftimer.Seconds -gt 0){
                $perfstate = '[WARNING] '
              }else{
                $perfstate = ''
              }
              [void]$sb.AppendLine("$($message.timestamp)$perfstate$TypeHeader$text | Time: $($message.Perftimer.hours):$($message.Perftimer.Minutes):$($message.Perftimer.Seconds):$(([string]$message.Perftimer.Milliseconds).PadLeft(3,'0'))$($message.MemoryUsage)")
            }else{
              [void]$sb.AppendLine("$($message.timestamp)$TypeHeader$text$($message.MemoryUsage)")
            }
          }catch{
            start-sleep -Milliseconds 100
            [System.IO.File]::AppendAllText($message.logfile, "$($message.timestamp)$TypeHeader$text`n[$([datetime]::Now)] [ERROR] [WRITE-EZLOGS-LOGONLY-PERF] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string)" + ([Environment]::NewLine),[System.Text.Encoding]::$($message.Encoding))
          }     
        }elseif($message.VerboseDebug){
          try{
            [void]$sb.AppendLine("$($message.timestamp)[DEBUG] $text$($message.MemoryUsage)")
          }catch{
            start-sleep -Milliseconds 100
            [System.IO.File]::AppendAllText($message.logfile, "$($message.timestamp)[DEBUG] $text`n[$([datetime]::Now)] [ERROR] [WRITE-EZLOGS-LOGONLY-DEBUG] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string)" + ([Environment]::NewLine),[System.Text.Encoding]::$($message.Encoding))
          } 
        }else{
          try{
            [void]$sb.AppendLine("$($message.timestamp)$text$($message.MemoryUsage)")
          }catch{ 
            start-sleep -Milliseconds 100
            [System.IO.File]::AppendAllText($message.logfile, "$($message.timestamp)$text$($message.MemoryUsage)`n[ERROR] [WRITE-EZLOGS] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string)" + ([Environment]::NewLine),[System.Text.Encoding]::$($message.Encoding))
          }        
        }
        if($message.LinesAfter -ne 0){
          try{
            for ($i = 0; $i -lt $message.LinesAfter; $i++){
              [void]$sb.AppendLine('')
            }
          }catch{
            start-sleep -Milliseconds 100
            [System.IO.File]::AppendAllText($message.logfile, "`n[$([datetime]::Now)] [ERROR] [WRITE-EZLOGS-LinesAfter] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string) -- Original String: $($sb.ToString())" + ([Environment]::NewLine),[System.Text.Encoding]::$($message.Encoding))
          }            
        }
        # Finally write built string to log file
        try{
          [System.IO.File]::AppendAllText($message.logfile, "$($sb.ToString())",[System.Text.Encoding]::$($message.Encoding))
        }catch{ 
          start-sleep -Milliseconds 100
          [System.IO.File]::AppendAllText($message.logfile, "`n[$([datetime]::Now)] [ERROR] [WRITE-EZLOGS] [$((Get-PSCallStack).ToString())] `n $($_ | out-string) -- Original String: $($sb.ToString())" + ([Environment]::NewLine),[System.Text.Encoding]::$($message.Encoding))
        }
      }
    }
    Start-Sleep -Milliseconds 50
  }catch{
    Start-Sleep -Milliseconds 500
    $While_loop_error_text = "[ERROR] An exception occurred in log_Writer_ScriptBlock while loop at: $($_ | out-string)`n"
    if($sb){$originalString = $sb.ToString()}else{$originalString = $message | out-string}
    [System.IO.File]::AppendAllText($thisApp.Config.Error_Log_File, "$While_loop_error_text" + "Original string: $($originalString)" + ([Environment]::NewLine),[System.Text.Encoding]::Unicode)
  }finally{
    $Sb = $Null
    $message = $null
    $Text = $Null
  }
}
#---------------------------------------------- 
#endregion Write-LogMessage Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-LogWriter Function
#----------------------------------------------
function Get-LogWriter{
  param (
    $thisApp = $thisApp,
    [string]$logfile = $thisApp.Config.Log_file,
    $thisScript = $thisScript,
    [switch]$Startup,
    [switch]$shutdownWait,
    [int]$WaitSecs = 5,
    [switch]$StartupWait,
    [switch]$shutdown
  )
  if(!$logfile){$logfile = $thisApp.Config.Log_file}
  if(!$logfile){$logfile = $thisApp.Log_file}
  if($startup){
    try{
      $log_Writer_ScriptBlock = {  
        param (
          $thisApp = $thisApp,
          [string]$logfile = $logfile,
          $thisScript = $thisScript,
          [switch]$Startup = $Startup,
          [switch]$shutdownWait = $shutdownWait,
          [switch]$StartupWait = $StartupWait,
          [switch]$shutdown = $shutdown
        )
        try {
          $thisApp.LogWriterEnabled = $true
          do {
            Write-LogMessage -thisApp $thisApp -logfile $logfile -Startup $Startup -shutdownWait:$shutdownWait -StartupWait:$StartupWait -shutdown:$shutdown
          } while($thisApp.LogWriterEnabled)
          [System.IO.File]::AppendAllText($thisApp.Log_File, "[$([datetime]::Now)] [WARNING] LogWriter has ended!" + ([Environment]::NewLine),[System.Text.Encoding]::Unicode)
        }catch{
          Start-Sleep -Milliseconds 500
          $runspace_error_text = "[ERROR] An exception occurred in log_Writer_scriptblock at: $($_ | out-string)`n"
          $originalString = $message | out-string
          [System.IO.File]::AppendAllText($thisApp.Log_File, "$runspace_error_text" + "Original string: $($originalString)" + ([Environment]::NewLine),[System.Text.Encoding]::Unicode)
        }
      }
      #$keys = $PSBoundParameters.keys
      #$Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant" -and $_.Name -in $keys){$_}}}     
      Start-Runspace $log_Writer_ScriptBlock -Variable_list $PSBoundParameters -StartRunspaceJobHandler -logfile $Logfile -runspace_name "Log_Writer_Runspace" -thisApp $thisapp -verboselog:$Verboselog -cancel_runspace -RestrictedRunspace -function_list Write-LogMessage
      if($StartupWait){
        while(!$thisApp.LogMessageQueue -or !$thisApp.LogWriterEnabled){
          start-sleep -Milliseconds 100
        }   
      }
      #$Variable_list = $Null
      $log_Writer_ScriptBlock = $Null
    }catch{
      throw $_
    }
  }elseif($shutdown){
    if($shutdownWait){
      $WaitTimer = 0
      while(!$thisApp.LogMessageQueue.IsEmpty -and $WaitTimer -lt $WaitSecs){
        $WaitTimer++
        start-sleep 1
      }
    }
    $thisApp.LogWriterEnabled = $false
  }
}
#---------------------------------------------- 
#endregion Get-LogWriter Function
#----------------------------------------------

#---------------------------------------------- 
#region Stop EZLogs
#----------------------------------------------
function Stop-EZLogs
{
  param (
    [array]$ErrorSummary,
    $thisApp,
    [system.diagnostics.stopwatch]$globalstopwatch,
    [string]$logdateformat = 'MM/dd/yyyy h:mm:ss tt',
    [string]$logfile = $thisApp.Config.Log_file,
    [switch]$logOnly,
    [switch]$enablelogs = $true,
    [switch]$stoptimer,
    [switch]$clearErrors,
    [switch]$ShutdownWait = $true,
    [int]$WaitSecs = 5,
    [switch]$PrintErrors,
    [ValidateSet('ascii','bigendianunicode','default','oem','string','unicode','unknown','utf32','utf7','utf8')]
    [string]$Encoding = 'unicode'
  )  
  if($ErrorSummary -and $PrintErrors){
    write-ezlogs -PrintErrors:$PrintErrors -ErrorsToPrint $ErrorSummary
    if($clearErrors){
      $error.Clear()
    }
  }  
  Get-LogWriter -shutdown -thisApp $thisApp -shutdownWait:$ShutdownWait -WaitSecs $WaitSecs
  if($stoptimer -and $globalstopwatch)
  {
    if($globalstopwatch.elapsed.Days -gt 0){
      $days = "Days        : $($globalstopwatch.elapsed.days)`n"
    }else{
      $days = $null
    }
    [System.IO.File]::AppendAllText($logfile, "`n======== Total Script Execution Time ========" + ([Environment]::NewLine),[System.Text.Encoding]::Unicode)
    [System.IO.File]::AppendAllText($logfile, "$days`Hours        : $($globalstopwatch.elapsed.hours)`nMinutes      : $($globalstopwatch.elapsed.Minutes)`nSeconds      : $($globalstopwatch.elapsed.Seconds)`nMilliseconds : $($globalstopwatch.elapsed.Milliseconds)" + ([Environment]::NewLine),[System.Text.Encoding]::Unicode)
    $($globalstopwatch.stop())
    $($globalstopwatch.reset()) 
  }
  [System.IO.File]::AppendAllText($logfile, "###################### Logging Finished - [$([datetime]::Now)] ######################`n" + ([Environment]::NewLine),[System.Text.Encoding]::Unicode)  
}  
#---------------------------------------------- 
#endregion Stop EZLogs
#----------------------------------------------
#Export-ModuleMember -Function @('Start-EZLogs','Write-EZLogs','Stop-EZLogs','Get-LogWriter','Write-LogMessage')