<#
    .Name
    Write-EZLogs

    .Version 
    0.2.9

    .SYNOPSIS
    Module that allows advanced (fancy) console and log message output with error handling along with some other common related 'housekeeping' tasks.  

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher

    .RequiredModules
    PSWriteColor

    .EXAMPLE
    - $logfile = Start-EZLogs -logfile_directory "C:\Logs" -- Creates log file and directory (if not exists) and returns path to the log file. Log file name is "ScriptName-ScriptVersion.log" (requires module Get-thisScriptInfo)
    - Write-EZLogs "Message text I want output to console (as yellow) and log file, both with a timestamp" -color yellow -showtime

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES
    - Added parameter catcherror for write-logs for quick error handling and logging
    - Added parameter verbosedebug to simulate write-verbose formatting
    - Added output of 'hours' for StopWatch timer logging
    - Set default of parameter LogDateFormat for Stop-EZLogs to match Start-EZLogs
#>

#----------------------------------------------
#region Get-ThisScriptInfo Function
#----------------------------------------------
function Get-thisScriptInfo
{
  param (
    [switch]$VerboseDebug,
    [string]$logfile_directory,
    [string]$ScriptPath,
    [string]$Script_Temp_Folder,
    [switch]$GetFunctions,
    [switch]$IncludeDetail,    
    [switch]$No_Script_Temp_Folder
  )
  #$Script_File = $((Get-PSCallStack).ScriptName | where {$_ -notmatch '.psm1'})
  if(!$ScriptPath){$ScriptPath = $((Get-PSCallStack).ScriptName | where {$_ -notmatch '.psm1'} | select -First 1)}
  $thisScript = @{File = [System.IO.FileInfo]::new($ScriptPath); Contents = ([System.IO.FIle]::ReadAllText($ScriptPath))}
  if($thisScript.Contents -Match '^\s*\<#([\s\S]*?)#\>') 
  {
    $thisScript.Help = $Matches[1].Trim()
  }
  [RegEx]::Matches($thisScript.Help, "(^|[`r`n])\s*\.(.+)\s*[`r`n]|$") | ForEach-Object {
    If ($Caption) 
    {$thisScript.$Caption = $thisScript.Help.SubString($Start, $_.Index - $Start)}
    $Caption = $_.Groups[2].ToString().Trim()
    $Start = $_.Index + $_.Length
  }  
  if($IncludeDetail){

    if($thisScript.example){$thisScript.example = $thisScript.example -split("`n") | ForEach-Object {$_.trim()}}else{$thisScript.example = "None"}
    if($thisScript.RequiredModules){$thisScript.RequiredModules = $thisScript.RequiredModules -split("`n") | ForEach-Object {$_.trim()}}else{$thisScript.RequiredModules = "None"}
    if($thisScript.Author){$thisScript.Author = $thisScript.Author.Trim()}else{$thisScript.Author = "Unknown"}
    if($thisScript.credits){$thisScript.credits = $thisScript.credits -split("`n") | ForEach-Object {$_.trim()}}else{$thisScript.credits = "None"}
    if($thisScript.SYNOPSIS){$thisScript.SYNOPSIS = $thisScript.SYNOPSIS -split("`n") | ForEach-Object {$_.trim()}}else{$thisScript.SYNOPSIS = "None"}
    if($thisScript.Description){$thisScript.Description = $thisScript.Description -split("`n") | ForEach-Object {$_.trim()}}else{$thisScript.Description = "None"}
    if($thisScript.Notes){$thisScript.Notes = $thisScript.Notes -split("`n") | ForEach-Object {$_.trim()}}else{$thisScript.Notes = "None"} 
    $thisScript.Arguments = (($Invocation.Line + ' ') -Replace ('^.*\\' + $thisScript.File.Name.Replace('.', '\.') + "['"" ]"), '').Trim() 
    $thisScript.PSCallStack = Get-PSCallStack   
  } 
  if($thisScript.Version){$thisScript.Version = $thisScript.Version.Trim()}
  if($thisScript.Name){$thisScript.Name = $thisScript.Name.Trim()}else{$thisScript.Name = $thisScript.File.BaseName.Trim()}
  $thisScript.Path = $thisScript.File.FullName; $thisScript.Folder = $thisScript.File.DirectoryName; $thisScript.BaseName = $thisScript.File.BaseName  
  if($GetFunctions){
    [System.Collections.Generic.List[String]]$FX_NAMES = New-Object System.Collections.Generic.List[String]
    if(!([System.String]::IsNullOrWhiteSpace($thisScript.file)))
    { 
      Select-String -Path $thisScript.file -Pattern "function" |
      ForEach-Object {
        [System.Text.RegularExpressions.Regex] $regexp = New-Object Regex("(function)( +)([\w-]+)")
        [System.Text.RegularExpressions.Match] $match = $regexp.Match("$_")
        if($match.Success)
        {
          $FX_NAMES.Add("$($match.Groups[3])")
        }  
      }
      $thisScript.functions = $FX_NAMES.ToArray()  
    }
  }
  if(!$No_Script_Temp_Folder)
  {
    if(!$Script_Temp_Folder)
    {
      $Script_Temp_Folder = [System.IO.Path]::Combine($env:TEMP, $($thisScript.Name))
    }
    else
    {
      $Script_Temp_Folder = [System.IO.Path]::Combine($Script_Temp_Folder, $($thisScript.Name))
    }
    if(!([System.IO.Directory]::Exists($Script_Temp_Folder)))
    {
      try
      {
        $null = New-Item $Script_Temp_Folder -ItemType Directory -Force
      }
      catch
      {
        Write-error "[ERROR] Exception creating script temp directory $Script_Temp_Folder - $($_ | out-string)"
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
#region Start EZLogs Function
#----------------------------------------------
function Start-EZLogs
{
  param (
    [switch]$Verboselog,
    [string]$Logfile_Directory,
    [string]$Logfile_Name,
    [string]$Script_Name,
    $thisScript,
    [switch]$noheader,
    [string]$Script_Description,
    [string]$Script_Version,
    [string]$ScriptPath,
    [switch]$Start_Timer = $true,
    [ValidateSet('ascii','bigendianunicode','default','oem','string','unicode','unknown','utf32','utf7','utf8')]
    [string]$Encoding = 'unicode'
  )
  if($Start_Timer -and !$globalstopwatch){$Global:globalstopwatch = [system.diagnostics.stopwatch]::StartNew()}
  if(!$ScriptPath){$ScriptPath = $PSCommandPath} 
  #if(!$ScriptPath){$ScriptPath = $((Get-PSCallStack).ScriptName | where {$_ -notmatch '.psm1'} | select -First 1)}
  if(!$thisScript){$thisScript = Get-thisScriptinfo -ScriptPath $ScriptPath -No_Script_Temp_Folder}
  if(!$Script_Name){$Script_Name = $($thisScript.Name)}
  if(!$Script_Description){$Script_Description = $($thisScript.SYNOPSIS)}
  if(!$Script_Version){$Script_Version = $($thisScript.Version)}
  if(!$logfile_directory){$logfile_directory = $ScriptPath}
  if(!$logfile_name){
    if(!$thisScript.Name){  
      $logfile_name = "$([System.IO.Path]::GetFileNameWithoutExtension($ScriptPath)).log"
    }else{
      $logfile_name = "$($thisScript.Name)-$($thisScript.Version).log"
    }
  }   
  $script:logfile = [System.IO.Path]::Combine($logfile_directory, $logfile_name)
  if (!([System.IO.Directory]::Exists($logfile_directory)))
  {
    $null = New-Item -Path $logfile_directory -ItemType directory -Force
  }
  $OriginalPref = $ProgressPreference
  $ProgressPreference = 'SilentlyContinue'
  if(!$noheader){
    #ManagementObjectSearcher is faster 
    $query = [System.Management.ObjectQuery]::new("SELECT * FROM Win32_OperatingSystem")
    $searcher = [System.Management.ManagementObjectSearcher]::new($query)
    $results = $searcher.get()
  
    #TODO: Cleanup
    #$OS = "$($results.Caption)($($results.Version))"
    #$RAM = "$([Math]::Round([int64]($results.TotalVisibleMemorySize)/1MB,2)) GB (Available: $([Math]::Round([int64]($results.FreePhysicalMemory)/1MB,2)) GB)" 
    #$lastboot = $results.LastBootUpTime
    #$localDateTime = $results.localDateTime
    #$InstallDate =  $results.InstallDate
    #$Computer_Info = Get-CimInstance Win32_ComputerSystem | Select-Object *
    #$OS_Info = Get-CimInstance Win32_OperatingSystem | Select-Object *
    #$serial = $((Get-CimInstance Win32_BIOS | Select-Object SerialNumber).SerialNumber)
    $ProgressPreference = $OriginalPref
    $logheader = @"
`n###################### Logging Enabled ######################
Script Name          : $Script_Name
Synopsis             : $Script_Description
Log File             : $logfile
Version              : $Script_Version
Current Username     : $env:username
Powershell           : $($PSVersionTable.psversion)($($PSVersionTable.psedition))
Computer Name        : $env:computername
Operating System     : $($results.Caption)($($results.Version))
CPU                  : $env:PROCESSOR_IDENTIFIER | Cores: $($env:NUMBER_OF_PROCESSORS)
RAM                  : $([Math]::Round([int64]($results.TotalVisibleMemorySize)/1MB,2)) GB (Available: $([Math]::Round([int64]($results.FreePhysicalMemory)/1MB,2)) GB)
Manufacturer         : $($computer_info.Manufacturer)
Model                : $($computer_info.Model)
Serial Number        :  $serial
Domain               : $env:USERDOMAIN
Install Date         : $InstallDate
Last Boot Up Time    : $lastboot
Local Date/Time      : $localDateTime
Windows Directory    : $env:windir
###################### Logging Started - [$(Get-Date)] ##########################
"@

    Write-Output $logheader | Out-File -FilePath $logfile -Encoding unicode -Append
  }

  write-host "#### Executing $Script_Name - $Script_Version ####" -ForegroundColor Yellow
  Write-host " | Logging is enabled. Log file: $logfile"
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
  [CmdletBinding(DefaultParameterSetName = 'text')]
  param (
    [string]$text,
    [switch]$VerboseDebug,
    [switch]$enablelogs = $true,
    [string]$logfile = $logfile,
    [switch]$Warning,
    [switch]$PrintErrors,
    [array]$ErrorsToPrint,    
    [switch]$CallBack = $true,
    $CatchError,
    $callpath = $callpath,
    [switch]$logOnly,
    [string]$DateTimeFormat = 'MM/dd/yyyy h:mm:ss tt',
    [ValidateSet('Black','Blue','Cyan','Gray','Green','Magenta','Red','White','Yellow','DarkBlue','DarkCyan','DarkGreen','DarkMagenta','DarkRed','DarkYellow')]
    [string]$color = 'white',
    [ValidateSet('Black','Blue','Cyan','Gray','Green','Magenta','Red','White','Yellow','DarkBlue','DarkCyan','DarkGreen','DarkMagenta','DarkRed','DarkYellow')]
    [string]$foregroundcolor,
    [switch]$showtime,
    [switch]$logtime,
    [switch]$NoNewLine,
    [int]$StartSpaces,
    [string]$Separator,
    [ValidateSet('Black','Blue','Cyan','Gray','Green','Magenta','Red','White','Yellow','DarkBlue','DarkCyan','DarkGreen','DarkMagenta','DarkRed','DarkYellow')]
    [string]$BackgroundColor,
    [int]$linesbefore,
    [int]$linesafter,
    [ValidateSet('ascii','bigendianunicode','default','oem','string','unicode','unknown','utf32','utf7','utf8')]
    [string]$Encoding = 'unicode'
  )

  $output = $Null
  if(!$logfile){$logfile = $thisApp.Config.Log_file}
  if(!$logfile){$logfile = Start-EZlogs -noheader}
  if($showtime -and !$logtime){$logtime = $true}else{$logtime = $false}
  if($foregroundcolor){$color = $foregroundcolor}
  try{
    if($CallBack -and $($MyInvocation)){  
      if($callpath){
        $invocation = "$callpath"
      }elseif($($MyInvocation.PSCommandPath -match "(?<value>.*)\\(?<value>.*).ps")){
        $invocation = "$($matches.Value):$($MyInvocation.ScriptLineNumber)"
      }elseif($((Get-PSCallStack)[1].Command) -notmatch 'ScriptBlock'){
        $invocation = "$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber)"
      }
      if($invocation){
        $text = "[$($invocation)] $text"
        $callpath = "[$($invocation)]"
      }elseif($CallBack -and $text -notmatch "\[$((Get-PSCallStack)[1].FunctionName)\]"){
        if($((Get-PSCallStack)[1].FunctionName) -match 'ScriptBlock'){
          $callpath = "[$((Get-PSCallStack)[1].FunctionName) - $((Get-PSCallStack).Position.StartLineNumber)]"
          $text = "$callpath $text"
        }else{
          $callpath = "[$((Get-PSCallStack)[1].FunctionName)]"
          $text = "$callpath $text"
        }    
      } 
    }  
  }catch{
    write-output ($_ | select * | out-string) | Out-File -FilePath $logfile -Encoding $Encoding -Append -Force
  }
  if($showtime){
    $timestamp = "[$(Get-Date -Format $DateTimeFormat)] "
  }else{
    $timestamp = $Null
  }  
  if($LinesBefore -ne 0){ for ($i = 0; $i -lt $LinesBefore; $i++) {
      try{
        write-host "`n" -NoNewline
        if($enablelogs){
          write-output "" | Out-File -FilePath $logfile -Encoding $Encoding -Append -Force
        }
      }catch{
        start-sleep -Milliseconds 1
        if($enablelogs){
          write-output "`n$timestamp[ERROR] [WRITE-EZLOGS-LinesBefore] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string)" | Out-File -FilePath $logfile -Encoding $Encoding -Append -Force
        }
      }       
    }
  }
  if($BackgroundColor){$BackgroundColor_param = $BackgroundColor}else{$BackgroundColor_param = $null}
  if($CatchError){
    try{
      $text = "[ERROR] $text in [$($CatchError.TargetObject):$($CatchError.InvocationInfo.ScriptLineNumber)]`:`n |+ $($CatchError.Exception | out-string)`n |+ $($CatchError.InvocationInfo.PositionMessage)`n |+ $($CatchError.ScriptStackTrace)`n";$color = "red"
    }catch{
      start-sleep -Milliseconds 1
      if($enablelogs){
        write-output "`n$timestamp[ERROR] [WRITE-EZLOGS-CatchError] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string)" | Out-File -FilePath $logfile -Encoding $Encoding -Append -Force
      }
    }  
  } 
  if($PrintErrors -and $ErrorsToPrint -as [array]){
    try{    
      Write-Host -Object "$text$timestamp[PRINT ALL ERRORS]" -ForegroundColor Red;if($enablelogs){"$text$timestamp[PRINT ALL ERRORS]" | Out-File -FilePath $logfile -Encoding $Encoding -Append -Force}
      $e_index = 0
      foreach ($e in $ErrorsToPrint)
      {
        $e_index++
        Write-Host -Object "[ERROR $e_index Message] =========================================================================`n$($e.Exception | out-string)`n |+ $($e.InvocationInfo.PositionMessage)`n |+ $($e.ScriptStackTrace)`n`n" -ForegroundColor Red;if($enablelogs){"[ERROR $e_index Message] =========================================================================`n$($e.Exception | out-string)`n |+ $($e.InvocationInfo.PositionMessage)`n |+ $($e.ScriptStackTrace)`n`n" | Out-File -FilePath $logfile -Encoding $Encoding -Append -Force}        
      }   
    }catch{ 
      start-sleep -Milliseconds 1
      $e_index = 0
      foreach ($e in $ErrorsToPrint)
      {
        $e_index++
        Write-Host -Object "[ERROR $e_index Message] =========================================================================`n$($e.Exception | out-string)`n |+ $($e.InvocationInfo.PositionMessage)`n |+ $($e.ScriptStackTrace)`n`n" -ForegroundColor Red;if($enablelogs){"[ERROR $e_index Message] =========================================================================`n$($e.Exception | select * | out-string)`n |+ $($e.InvocationInfo.PositionMessage)`n |+ $($e.ScriptStackTrace)`n`n" | Out-File -FilePath $logfile -Encoding $Encoding -Append -Force}        
      }      
      Write-host ("$text$timestamp[ERROR] [WRITE-EZLOGS] [$((Get-PSCallStack)[1].FunctionName)] `n $($_.Exception | out-string)`n |+ $($_.InvocationInfo.PositionMessage)`n |+ $($_.ScriptStackTrace)") -ForegroundColor Red
      ("$text$timestamp [ERROR] [WRITE-EZLOGS] [$((Get-PSCallStack)[1].FunctionName)] `n $($_.Exception | out-string)`n |+ $($_.InvocationInfo.PositionMessage)`n |+ $($_.ScriptStackTrace)") | Out-File -FilePath $logfile -Encoding $Encoding -Append -Force
    }
    return  
  }   
  #if($linesAfter){$text = "$text`n"}
  if($enablelogs)
  {
    if($VerboseDebug -and $warning)
    {
      $tmp = [System.IO.Path]::GetTempFileName();
      $result = "[DEBUG] $(Get-Content $tmp)" | Out-File $logfile -Encoding $Encoding -Append -Force;Remove-Item $tmp   
    }
    elseif($Warning)
    {
      if($logOnly)
      { 
        try{
          Write-Output "$timestamp[WARNING]  $text" | Out-File -FilePath $logfile -Encoding $Encoding -Append -NoNewline:$NoNewLine
        }catch{
          start-sleep -Milliseconds 1
          Write-Output "$timestamp[WARNING] $text`n[$(Get-Date -Format $DateTimeFormat)] [ERROR] [WRITE-EZLOGS-LOGONLY-WARNING] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string)" | Out-File -FilePath $logfile -Encoding $Encoding -Append -NoNewline:$NoNewLine
        }
      }
      else
      {        
        try{
          Write-Warning ($wrn = "$text")
          Write-Output "$timestamp[WARNING] $wrn" | Out-File -FilePath $logfile -Encoding $Encoding -Append
        }catch{
          start-sleep -Milliseconds 1
          Write-Output "$timestamp[WARNING] $text`n[$(Get-Date -Format $DateTimeFormat)] [ERROR] [WRITE-EZLOGS-WARNING] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string)" | Out-File -FilePath $logfile -Encoding $Encoding -Append
        }        
      }      
    }
    elseif($VerboseDebug)
    {
      if($BackGroundColor){
        Write-Host -Object "$timestamp[DEBUG] $text" -ForegroundColor:Cyan -NoNewline:$NoNewLine -BackgroundColor:$BackGroundColor;if($enablelogs){"$timestamp[DEBUG] $text" | Out-File -FilePath $logfile -Encoding $Encoding -Append -NoNewline:$NoNewLine -Force}
      }else{
        Write-Host -Object "$timestamp[DEBUG] $text" -ForegroundColor:Cyan -NoNewline:$NoNewLine;if($enablelogs){"$timestamp[DEBUG] $text" | Out-File -FilePath $logfile -Encoding $Encoding -Append -NoNewline:$NoNewLine -Force}
      }    
    }
    else
    {
      if($logOnly)
      {
        Write-Output "$timestamp$text" | Out-File -FilePath $logfile -Encoding $Encoding -Append -NoNewline:$NoNewLine 
      }
      else
      {      
        try{
          if($BackGroundColor){
            Write-Host -Object ($timestamp + $text) -ForegroundColor:$Color -NoNewline:$NoNewLine -BackgroundColor:$BackGroundColor;if($enablelogs){$timestamp + $text | Out-File -FilePath $logfile -Encoding $Encoding -Append -NoNewline:$NoNewLine -Force}
          }else{
            Write-Host -Object ($timestamp + $text) -ForegroundColor:$Color -NoNewline:$NoNewLine;if($enablelogs){$timestamp + $text | Out-File -FilePath $logfile -Encoding $Encoding -Append -NoNewline:$NoNewLine -Force}
          }
        }catch{ 
          start-sleep -Milliseconds 1
          Write-host ("$timestamp[ERROR] [WRITE-EZLOGS] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string)") -ForegroundColor Red
          ($timestamp + $text + "`n[$(Get-Date -Format $DateTimeFormat)] [ERROR] [WRITE-EZLOGS] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string)") | Out-File -FilePath $logfile -Encoding $Encoding -Append -Force
        }      
      }
    }
  }
  else
  {
    if($warning)
    {
      if($showtime){
        Write-Host -Object "[$([datetime]::Now.ToString($DateTimeFormat))] " -NoNewline
      }
      Write-Warning ($wrn = "$text")  
    }
    else
    {
      if($showtime){
        Write-Host -Object "[$([datetime]::Now.ToString($DateTimeFormat))] " -NoNewline
      }
      if($BackGroundColor){
        Write-Host -Object $text -ForegroundColor:$Color -NoNewline:$NoNewLine -BackgroundColor:$BackGroundColor
      }else{
        Write-Host -Object $text -ForegroundColor:$Color -NoNewline:$NoNewLine
      }    
    }     
  }
  if($LinesAfter -ne 0){
    for ($i = 0; $i -lt $LinesAfter; $i++) {
      try{
        write-host "`n" -NoNewline
        if($enablelogs){
          write-output "" | Out-File -FilePath $logfile -Encoding $Encoding -Append -Force
        }
      }catch{
        start-sleep -Milliseconds 1
        write-host "`n" -NoNewline
        if($enablelogs){
          write-output "`n[$(Get-Date -Format $DateTimeFormat)] [ERROR] [WRITE-EZLOGS-LinesAfter] [$((Get-PSCallStack)[1].FunctionName)] `n $($_ | out-string)" | Out-File -FilePath $logfile -Encoding $Encoding -Append -Force
        }
      }    
    }
  }
}
#---------------------------------------------- 
#endregion Write-EZLogs Function
#----------------------------------------------

#---------------------------------------------- 
#region Stop EZLogs
#----------------------------------------------
function Stop-EZLogs
{
  param (
    [array]$ErrorSummary,
    [string]$logdateformat = 'MM/dd/yyyy h:mm:ss tt',
    [string]$logfile = $logfile,
    [switch]$logOnly,
    [switch]$enablelogs = $true,
    [switch]$stoptimer,
    [switch]$clearErrors,
    [ValidateSet('ascii','bigendianunicode','default','oem','string','unicode','unknown','utf32','utf7','utf8')]
    [string]$Encoding = 'unicode'
  )
  if($ErrorSummary)
  {
    Write-Output "`n`n[-----ALL ERRORS------]" | Out-File -FilePath $logfile -Encoding $Encoding -Append
    $e_index = 0
    foreach ($e in $ErrorSummary)
    {
      $e_index++
      Write-Output "[ERROR $e_index Message] =========================================================================`n$($e.exception.message)`n$($e.InvocationInfo.positionmessage)`n$($e.ScriptStackTrace)`n`n" | Out-File -FilePath $logfile -Encoding unicode -Append
    }
    Write-Output '-----------------' | Out-File -FilePath $logfile -Encoding $Encoding -Append
    if($clearErrors)
    {
      $error.Clear()
    }
  }
  if($globalstopwatch.elapsed.Days -gt 0){
    $days = "Days        : $($globalstopwatch.elapsed.days)`n"
  }else{
    $days = $null
  }  
  if($logOnly){
    Write-Output "`n======== Total Script Execution Time ========" | Out-File -FilePath $logfile -Encoding $Encoding -Append
    Write-Output "$days`Hours        : $($globalstopwatch.elapsed.hours)`nMinutes      : $($globalstopwatch.elapsed.Minutes)`nSeconds      : $($globalstopwatch.elapsed.Seconds)`nMilliseconds : $($globalstopwatch.elapsed.Milliseconds)" | Out-File -FilePath $logfile -Encoding $Encoding -Append   
  }else{
    Write-EZLogs "`n======== Total Script Execution Time ========" -enablelogs:$enablelogs -LogTime:$false
    Write-EZLogs "$days`Hours        : $($globalstopwatch.elapsed.hours)`nMinutes      : $($globalstopwatch.elapsed.Minutes)`nSeconds      : $($globalstopwatch.elapsed.Seconds)`nMilliseconds : $($globalstopwatch.elapsed.Milliseconds)" -enablelogs:$enablelogs -LogTime:$false
  }
  if($stoptimer)
  {
    $($globalstopwatch.stop())
    $($globalstopwatch.reset()) 
  }
  Write-Output "###################### Logging Finished - [$(Get-Date -Format $logdateformat)] ######################`n" | Out-File -FilePath $logfile -Encoding $Encoding -Append
}  
#---------------------------------------------- 
#endregion Stop EZLogs
#----------------------------------------------
Export-ModuleMember -Function @('Start-EZLogs','Write-EZLogs','Stop-EZLogs','Get-thisScriptInfo')