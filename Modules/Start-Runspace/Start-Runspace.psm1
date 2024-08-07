<#
    .Name
    Start-Runspace

    .Version 
    0.2.0

    .SYNOPSIS
    Allows executing new runspaces

    .DESCRIPTION
    Helps easily create new powershell runspaces when providing scriptblocks to execute, variables/functions to pass to them and other options. Manages the full lifecycle of powershell runspaces, from properly cleaning up and disposing when completed, to canceling and removing existing

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
#---------------------------------------------- 
#region New-OutOfProcRunspace Function
#----------------------------------------------
function New-OutOfProcRunspace {
  [CmdletBinding()]
  param (   
    $ApartmentState
  )
  try{
    $Process = Start-Process powershell -ArgumentList @("-NoProfile","-ExecutionPolicy Bypass","-windowstyle hidden","-NoLogo") -PassThru -WindowStyle Hidden
    $ci = New-Object -TypeName System.Management.Automation.Runspaces.NamedPipeConnectionInfo -ArgumentList @($Process.Id)
    $tt = [System.Management.Automation.Runspaces.TypeTable]::LoadDefaultTypeFiles()

    $Runspace = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace($ci, $Host, $tt)
    #$Runspace.ApartmentState = $ApartmentState
    $Null = $Runspace.Open()
    $Runspace
  }catch{
    write-ezlogs "An exception occurred creating new OutofProcess Runspace" -catcherror $_
  }
}
#---------------------------------------------- 
#endregion New-OutOfProcRunspace Function
#----------------------------------------------

#---------------------------------------------- 
#region Start-RunspaceJobHandler Function
#----------------------------------------------
function Start-RunspaceJobHandler {
  <#
      .Name
      Start-RunspaceJobHandler

      .SYNOPSIS
      Creates a runspace dedicated for managing all other runspaces

      .DESCRIPTION
      Manages the full lifecycle of powershell runspaces, from properly cleaning up and disposing when completed, to canceling and removing existing
      
      .PARAMETER

      .EXAMPLE
      
      .OUTPUTS
      System.Management.Automation.PSObject

      .NOTES
      Author: EZTechhelp
      Site  : https://www.eztechhelp.com
  #>
  [CmdletBinding()]
  param (
    $thisApp,
    $Function_list,
    [switch]$PassCallPath,
    [switch]$UseTimer,
    [switch]$UseRestrictedRunspace,
    [string]$SourceRunspace,
    $logfile,
    $verboselog
  )
  try{
    try{
      #write-ezlogs "#### Creating new JobCleanup Synchronized Hashtable" -logtype Threading -linesbefore 1
      $thisApp.JobCleanup = [hashtable]::Synchronized(@{})
      $thisApp.Jobs = [system.collections.arraylist]::Synchronized(([System.Collections.ArrayList]::new()))
      $thisApp.JobCleanup.Flag = $True
      if($thisApp.Config.Threading_Log_File){
        $logfile = $thisApp.Config.Threading_Log_File
      }
      if($UseTimer){
        [void][System.Reflection.Assembly]::LoadWithPartialName("WindowsBase")
        $JobCleanupTimer = [System.Windows.Threading.DispatcherTimer]::new([System.Windows.Threading.DispatcherPriority]::Background)
        $JobCleanupTimer.Interval = [TimeSpan]::FromMilliseconds(500)
        $JobCleanupTimer.Add_Tick({
            try {
              #Clone jobs to prevent enumeration errors
              $thisApp.Jobs.clone() | & { process {
                  If ($_.Runspace.isCompleted){
                    try{
                      #If the log writer runspace ended when it shouldnt, attempt to restart
                      if($($_.powershell.runspace.name) -eq 'log_Writer_runspace' -and $thisApp.LogWriterEnabled){
                        try{
                          Get-LogWriter -logfile $logfile -Startup -thisApp $thisApp
                          [System.IO.File]::AppendAllText($Logfile, "[$([datetime]::Now.ToString())] [WARNING] Log Writer stopped unexpectedly (LogWriterEnabled: $($thisApp.LogWriterEnabled))...attempting to restart - Logfile: $($thisApp.Config.Log_file)`n[$([datetime]::Now.ToString())] ERRORS: $($_.powershell.Streams.Error)",[System.Text.Encoding]::Unicode)                         
                        }catch{
                          if($logfile){
                            [System.IO.File]::AppendAllText($logfile, "[$([datetime]::Now.ToString())] [$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber):$($_.powershell.runspace.name)] [ERROR] An exception occurred restarting the log writer: $($_)",[System.Text.Encoding]::Unicode)
                          }else{
                            throw "[$([datetime]::Now.ToString())] [$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber):$($_.powershell.runspace.name)] [ERROR] An exception occurred restarting the log writer: $($_ | out-string)"
                          }
                        }
                      }
                      if($thisApp.Config.Dev_mode -or $thisApp.Config.Log_Level -ge 3){
                        $e_index = 0
                        if($_.powershell.Streams.Information){
                          write-ezlogs "[========= RUNSPACE $($_.powershell.runspace.name) Information =========]" -logtype Threading
                          foreach ($e in $_.powershell.Streams.Information) {
                            $e_index++
                            write-ezlogs "[Information $e_index Message:$($_.powershell.runspace.name)] =========================================================================`n$($e.toString())" -logtype Threading
                          }
                          write-ezlogs "=========================================================================" -logtype Threading
                        }
                        $e_index = 0
                        if($_.powershell.Streams.Progress){
                          write-ezlogs "[========= RUNSPACE $($_.powershell.runspace.name) Progress =========]" -logtype Threading
                          foreach ($e in $_.powershell.Streams.Progress) {
                            $e_index++
                            write-ezlogs "[DEBUG] [Progress $e_index Message:$($_.powershell.runspace.name)] =========================================================================`n$($e.toString())" -logtype Threading
                          }
                          write-ezlogs "=========================================================================" -logtype Threading
                        }
                        $e_index = 0
                        if($_.powershell.Streams.Verbose){
                          write-ezlogs "[========= RUNSPACE $($_.powershell.runspace.name) Verbose =========]" -logtype Threading
                          foreach ($e in $_.powershell.Streams.Verbose) {
                            $e_index++
                            write-ezlogs "[DEBUG] [Verbose $e_index Message:$($_.powershell.runspace.name)] =========================================================================`n$($e.toString())" -logtype Threading
                          }
                          write-ezlogs "=========================================================================" -logtype Threading    
                        }           
                        $e_index = 0
                        if($_.powershell.Streams.Debug){
                          write-ezlogs "[========= RUNSPACE $($_.powershell.runspace.name) Debug =========]" -logtype Threading
                          foreach ($e in $_.powershell.Streams.Debug) {
                            $e_index++
                            write-ezlogs "[DEBUG] [Debug $e_index Message:$($_.powershell.runspace.name)] =========================================================================`n$($e.toString())" -logtype Threading
                          }
                          write-ezlogs "=========================================================================" -logtype Threading
                        }
                      }
                      if(-not [string]::IsNullOrEmpty($_.powershell.Streams.Warning)){
                        write-ezlogs "[========= RUNSPACE $($_.powershell.runspace.name) HAD $($_.powershell.Streams.Warning.count) WARNINGS =========]" -logtype Threading
                        $e_index = 0
                        foreach ($e in $_.powershell.Streams.Warning) {
                          $e_index++
                          write-ezlogs "[Warning $e_index Message:$($_.powershell.runspace.name)] =========================================================================`n$($e.toString())" -logtype Threading -Warning
                        }
                      }
                      if($_.powershell.HadErrors -and -not [string]::IsNullOrEmpty($_.powershell.Streams.Error)){
                        write-ezlogs "[========= RUNSPACE $($_.powershell.runspace.name) HAD ($($_.powershell.Streams.Error.count)) ERRORS =========]" -logtype Error
                        $e_index = 0
                        foreach ($e in $_.powershell.Streams.Error) {
                          $e_index++
                          write-ezlogs "[ERROR $e_index Runspace:$($_.powershell.runspace.name)] =========================================================================" -logtype Error -CatchError $e
                        }
                        if($_.powershell.InvocationStateInfo.State -and $_.powershell.InvocationStateInfo.State -ne 'Completed'){
                          write-ezlogs "[InvocationStateInfo Message:$($_.powershell.runspace.name)] =========================================================================`n[State]: $($_.powershell.InvocationStateInfo.State)`n[Reason]: $($_.powershell.InvocationStateInfo.Reason)" -logtype Error
                        }
                        if($e_index -gt 0){
                          write-ezlogs "=========================================================================" -logtype Error
                        }
                      }             
                      $_.Runspace.AsyncWaitHandle.dispose()
                      $_.powershell.Runspace.Dispose()
                      $_.powershell.dispose()
                      #Cleanup for OutOfProcRunspace
                      if($_.powershell.Runspace.RunspaceIsRemote -and $_.powershell.Runspace.ConnectionInfo.ProcessId){
                        write-ezlogs ">>>> Stopping runspace remote process with ID: '$($_.powershell.Runspace.ConnectionInfo.ProcessId)'" -logtype Threading
                        Stop-Process -Id $_.powershell.Runspace.ConnectionInfo.ProcessId -Force -ErrorAction SilentlyContinue
                      }
                      $_.Runspace = $null
                      $_.powershell = $null
                    }catch{
                      write-ezlogs "An exception occurred performing cleanup of runspace: $($_.name)" -catcherror $_
                    }finally{
                      #Clean out unused runspace jobs
                      if($_.runspace -eq $null){
                        [void]$thisApp.Jobs.remove($_)
                        write-ezlogs "| Runspace '$($_.Name)' Completed" -logtype Threading
                        if($_.Name -eq 'test_runspace'){
                          #[void]$waithandle.WaitOne(1000)
                          write-ezlogs "After Test_Runspace cleanup: $(Get-MemoryUsage -forceCollection)"
                        }
                        $_ = $Null
                        #ClearScriptBlockCache to reclaim memory
                        [void][ScriptBlock].GetMethod('ClearScriptBlockCache', [System.Reflection.BindingFlags]'Static,NonPublic').Invoke($Null, $Null)
                      }
                    }
                  }
              }}
            }catch{
              write-ezlogs "An exception occurred in runspace cleanup while loop" -catcherror $_
            }finally{            
              if($error){
                $e_index = 0
                foreach($e in $error){
                  write-ezlogs "[ERROR $e_index in JobCleanup Runspace] =========================================================================" -logtype Error -CatchError $e
                }
              }
              if(!$thisApp.JobCleanup.Flag){
                write-ezlogs ">>>> JobCleanup flag is false, disabling Jobcleanuptimer" -warning
                $this.Stop()
              }
              #[void]$waithandle.WaitOne(500)
              #[void][System.Threading.WaitHandle]::WaitAny($waithandle,100)
              #[System.Threading.Thread]::Sleep(100)
            }
        })
        if($SourceRunspace){
          write-ezlogs "#### Starting new JobCleanup Timer - SourceRunspace: $SourceRunspace" -logtype Threading -linesbefore 1
        }else{
          write-ezlogs "#### Starting new JobCleanup Timer from unknown Runspace! Callstack: $((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber)" -logtype Threading -linesbefore 1 -warning
          write-ezlogs "Full Get-PSCallStack: $(Get-PSCallStack | out-string):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber)" -logtype Threading -warning
          write-ezlogs "Full InvocationInfo: $((Get-PSCallStack).InvocationInfo | out-string)" -logtype Threading -warning
        }        
        $JobCleanupTimer.Start()
      }else{
        if($UseRestrictedRunspace){
          $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::Create()
          $InitialSessionState.LanguageMode = [System.Management.Automation.PSLanguageMode]::FullLanguage
          $Commands = 'Write-Output',
          'Add-Member',
          'Add-Type',
          'Where-Object',
          'Get-Command',
          'Get-PSCallStack',
          'Out-String',
          'Get-Random',
          'Select-Object',
          'Get-Variable',
          'Remove-Variable',
          'Get-Process',
          'Stop-Process',
          'ForEach-Object',
          'Start-Sleep',
          'Write-Error',
          'Get-Culture',
          'Copy-item',
          'New-item',
          'Import-module',
          'Remove-Module'
          'Export-ModuleMember'
          foreach($cmd in $commands){
            $command = Get-command $cmd
            $CmdletEntry = [System.Management.Automation.Runspaces.SessionStateCmdletEntry]::new($cmd, $command.ImplementingType,$null)
            $null = $InitialSessionState.Commands.Add($CmdletEntry)
          }
          if($Function_list){
            foreach($f in $function_list){
              #Pass to runspace
              $FunctionEntry = [System.Management.Automation.Runspaces.SessionStateFunctionEntry]::new($f,[string]::Intern(($ExecutionContext.InvokeCommand.GetCommand($f, [System.Management.Automation.CommandTypes]::Function)).Definition))
              $null = $InitialSessionState.Commands.Add($FunctionEntry)
            }
          }
        }else{
          $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault2()
        }
        $jobCleanup_newRunspace =[runspacefactory]::CreateRunspace($InitialSessionState)
        $jobCleanup_newRunspace.ApartmentState = "STA"
        $jobCleanup_newRunspace.ThreadOptions = "ReuseThread"
        $jobCleanup_newRunspace.Open()
        $jobCleanup_newRunspace.name = 'JobCleanup_Runspace'
        $jobCleanup_newRunspace.SessionStateProxy.SetVariable('PSModulePath',$env:PSModulePath)
        $jobCleanup_newRunspace.SessionStateProxy.SetVariable("logfile",$logfile)
        $jobCleanup_newRunspace.SessionStateProxy.SetVariable("thisApp",$thisApp)
        if($PassCallPath){
          $Callpath = "$($MyInvocation.MyCommand)|JobCleanup_Runspace"
          $jobCleanup_newRunspace.SessionStateProxy.SetVariable("Callpath",$Callpath)
        }
        $thisApp.JobCleanup.PowerShell = [PowerShell]::Create().AddScript({
            #Routine to handle completed runspaces
            #Import-module Microsoft.PowerShell.Utility
            $waithandle = $thisApp.JobCleanup.thread.AsyncWaitHandle
            Do {
              try {
                #Clone jobs to prevent enumeration errors
                $thisApp.Jobs.clone() | & { process {
                    If ($_.Runspace.isCompleted)  {
                      try{
                        #If the log writer runspace ended when it shouldnt, attempt to restart
                        if($($_.powershell.runspace.name) -eq 'log_Writer_runspace' -and $thisApp.LogWriterEnabled){
                          try{
                            [System.IO.File]::AppendAllText($Logfile, "[$([datetime]::Now.ToString())] [WARNING] Log Writer stopped unexpectedly (LogWriterEnabled: $($thisApp.LogWriterEnabled))...attempting to restart - Logfile: $($thisApp.Config.Log_file)`n[$([datetime]::Now.ToString())] ERRORS: $($_.powershell.Streams.Error)",[System.Text.Encoding]::Unicode)
                            Get-LogWriter -logfile $logfile -Startup -thisApp $thisApp
                          }catch{
                            [System.IO.File]::AppendAllText($logfile, "[$([datetime]::Now.ToString())] [$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber):$($_.powershell.runspace.name)] [ERROR] An exception occurred restarting the log writer: $($_)",[System.Text.Encoding]::Unicode)
                          }
                        }
                        if($_.powershell.HadErrors){
                          write-ezlogs "[========= RUNSPACE $($_.powershell.runspace.name) HAD ERRORS =========]" -logtype Error
                          $e_index = 0
                          foreach ($e in $_.powershell.Streams.Warning) {
                            $e_index++
                            write-ezlogs "[Warning $e_index Message:$($_.powershell.runspace.name)] =========================================================================`n$($e.toString())" -logtype Error -Warning
                          }
                          if($thisApp.Config.Dev_mode -or $thisApp.Config.Log_Level -ge 3){
                            $e_index = 0
                            foreach ($e in $_.powershell.Streams.Information) {
                              $e_index++
                              write-ezlogs "[Information $e_index Message:$($_.powershell.runspace.name)] =========================================================================`n$($e.toString())" -logtype Error
                            }
                            $e_index = 0
                            foreach ($e in $_.powershell.Streams.Progress) {
                              $e_index++
                              write-ezlogs "[DEBUG] [Progress $e_index Message:$($_.powershell.runspace.name)] =========================================================================`n$($e.toString())" -logtype Error
                            }
                            $e_index = 0
                            foreach ($e in $_.powershell.Streams.Verbose) {
                              $e_index++
                              write-ezlogs "[DEBUG] [Verbose $e_index Message:$($_.powershell.runspace.name)] =========================================================================`n$($e.toString())" -logtype Error
                            }               
                            $e_index = 0
                            foreach ($e in $_.powershell.Streams.Debug) {
                              $e_index++
                              write-ezlogs "[DEBUG] [Debug $e_index Message:$($_.powershell.runspace.name)] =========================================================================`n$($e.toString())" -logtype Error
                            }
                          }
                          $e_index = 0
                          foreach ($e in $_.powershell.Streams.Error) {
                            $e_index++
                            write-ezlogs "[ERROR $e_index Runspace:$($_.powershell.runspace.name)] =========================================================================" -logtype Error -CatchError $e
                          }
                          if($_.powershell.InvocationStateInfo.State -and $_.powershell.InvocationStateInfo.State -ne 'Completed'){
                            write-ezlogs "[InvocationStateInfo Message:$($_.powershell.runspace.name)] =========================================================================`n[State]: $($_.powershell.InvocationStateInfo.State)`n[Reason]: $($_.powershell.InvocationStateInfo.Reason)" -logtype Error
                          }
                          if($e_index -gt 0){
                            write-ezlogs "=========================================================================" -logtype Error
                          }
                        }
                        $_.Runspace.AsyncWaitHandle.close()
                        $_.Runspace.AsyncWaitHandle.dispose()
                        $_.powershell.Runspace.Dispose()
                        $_.powershell.Runspace = $Null
                        $_.PowerShell.Stop()
                        #$_.powershell.dispose()
                        #Cleanup for OutOfProcRunspace
                        if($_.powershell.Runspace.RunspaceIsRemote -and $_.powershell.Runspace.ConnectionInfo.ProcessId){
                          write-ezlogs ">>>> Stopping runspace remote process with ID: '$($_.powershell.Runspace.ConnectionInfo.ProcessId)'" -logtype Threading
                          Stop-Process -Id $_.powershell.Runspace.ConnectionInfo.ProcessId -Force -ErrorAction SilentlyContinue
                        }
                        $_.Runspace = $null
                        $_.powershell = $null
                      }catch{
                        write-ezlogs "An exception occurred performing cleanup of runspace: $($_.name)" -catcherror $_
                      }finally{
                        #Clean out unused runspace jobs
                        $Name = $_.Name
                        if($_.runspace -eq $null){
                          $Null = $thisApp.Jobs.remove($_)
                          write-ezlogs "| Runspace '$($Name)' Completed" -logtype Threading
                          $_ = $Null
                          if($Name -eq 'test_runspace'){
                            [void]$waithandle.WaitOne(1000)
                            write-ezlogs "After Test_Runspace cleanup: $(Get-MemoryUsage -forceCollection)"
                          }
                        }
                      }
                    }
                }}
              }catch{
                write-ezlogs "An exception occurred in runspace cleanup while loop" -catcherror $_
              }finally{            
                if($error){
                  $e_index = 0
                  foreach($e in $error){
                    write-ezlogs "[ERROR $e_index in JobCleanup Runspace] =========================================================================" -logtype Error -CatchError $e
                  }
                }
                [void]$waithandle.WaitOne(500)
                #[void][System.Threading.WaitHandle]::WaitAny($waithandle,100)
                #[System.Threading.Thread]::Sleep(100)
              }
            }
            while ($thisApp.JobCleanup.Flag)
            [System.IO.File]::AppendAllText($thisApp.Config.Log_File, "[WARNING] Jobcleanup Runspace has ended!",[System.Text.Encoding]::Unicode)
        })
        $thisApp.JobCleanup.PowerShell.Runspace = $jobCleanup_newRunspace
        write-ezlogs "#### Starting new JobCleanup Runspace - SourceRunspace: $SourceRunspace" -logtype Threading -linesbefore 1
        $thisApp.JobCleanup.Thread = $thisApp.JobCleanup.PowerShell.BeginInvoke()      
      }
    }catch{
      write-ezlogs  "An exception occurred creating or invoking Jobcleanup runspace" -catcherror $_
    }
  }catch{
    write-ezlogs "An exception occurred in Start-RunspaceJobHandler" -catcherror $_
  }
}
#----------------------------------------------
#endregion Start-RunspaceJobHandler Function
#----------------------------------------------

#---------------------------------------------- 
#region Start Runspace Function
#----------------------------------------------
function Start-Runspace
{
  <#
      .Name
      Start-Runspace

      .SYNOPSIS
      Creates and executes new runspaces

      .DESCRIPTION
      Helps easily create new powershell runspaces when providing scriptblocks to execute, variables/functions to pass to them and other options
      
      .PARAMETER

      .EXAMPLE
      
      .OUTPUTS
      System.Management.Automation.PSObject

      .NOTES
      Author: EZTechhelp
      Site  : https://www.eztechhelp.com
  #> 
  [CmdletBinding()]
  param (
    $scriptblock,
    $thisApp = $thisApp,
    [switch]$StartRunspaceJobHandler,
    [switch]$PassCallPath = $true,
    $Variable_list,
    $PSProviders,
    $logfile = $thisApp.Config.threading_Log_File,
    $thisScript,
    [string]$runspace_name,
    [switch]$cancel_runspace,
    [switch]$Dev,
    [switch]$CheckforExisting,
    [switch]$AlertUIWarnings,
    [switch]$JobCleanup_Startonly,
    $synchash,
    [switch]$RestrictedRunspace,
    [switch]$Set_stateChangeEvent,
    [switch]$startup_perf_timer,
    $arguments,
    $modules_list,
    $function_list,
    $Command_list,
    [int]$maxRunspaces = [int]$env:NUMBER_OF_PROCESSORS + 1,
    $startup_stopwatch,
    [ValidateSet('STA','MTA')]
    $ApartmentState = 'STA',
    [switch]$Wait,
    [switch]$OutofProcess_Runspace,
    [switch]$JobHandlerUseTimer = $true,
    [switch]$verboselog
  )
  #Start a new Runspace JobHandler if one is not already running
  if($StartRunspaceJobHandler -and !$thisApp.JobCleanup) {
    try{
      $Null = Start-RunspaceJobHandler -thisApp $thisApp -Function_list write-ezlogs -PassCallPath:$PassCallPath -logfile $logfile -UseRestrictedRunspace:$Dev -UseTimer:$JobHandlerUseTimer -SourceRunspace $runspace_name
      if($JobCleanup_Startonly){
        return
      }
    }catch{
      write-ezlogs  "An exception occurred creating or invoking Jobcleanup runspace" -catcherror $_
    } 
  }

  try{
    #If no log file provided directly, first check if one is set on the thisapp hash, then check if one is available within the variablie list. Otherwise, no logging will occur!
    if(!$logfile){
      if($thisApp.Log_File){
        $logfile = $thisApp.Config.Log_File
      }else{
        $logfile = ($Variable_list | & { process {if($_.name -eq 'Logfile'){$_}}}).value
      }
    }

    #If enabled, check for existing runspaces with the same name, and hault executing a new one if found
    if($Runspace_Name -and $CheckforExisting){
      try{
        $existing_Runspace = Stop-Runspace -thisApp $thisApp -runspace_name $Runspace_Name -check
        if($existing_Runspace){
          write-ezlogs "Runspace ($Runspace_Name) already exists and is busy, please wait before trying this action again" -warning -logtype Threading -AlertUI:$AlertUIWarnings
          return
        }
      }catch{
        write-ezlogs " An exception occurred checking for existing runspace '$Runspace_Name'" -showtime -catcherror $_
      }
    }

    #If enabled, check for existing runspaces with the same name and if found, force close/stop them
    #WARNING: Caution should be taken when force closing executing runspaces depending on what they are doing. Runspaces executing UI for example should never be force closed and it will freeze/crash the whole app
    if($cancel_runspace -and $runspace_name){
      $existing_Runspace = Stop-Runspace -thisApp $thisApp -runspace_name $Runspace_Name
    }

    #Set Apartment State making sure STA is used for runspaces containing UI
    #TODO: Clean this up and use better way to detect if runspace is UI related
    if($ApartmentState -eq 'MTA' -and $Runspace_Name -notmatch 'Start_SplashScreen' -and $Runspace_Name -notmatch 'Show_WebLogin' -and $runspace_name -notmatch 'ProfileEditor_Runspace' -and $runspace_name -notmatch 'Show_' -and $runspace_name -notmatch 'Vlc_Play_media'){
      $ApartmentState = $ApartmentState
    }else{
      $ApartmentState = "STA"
    } 

    #Create the runspace
    if($OutofProcess_Runspace){
      $new_Runspace = New-OutOfProcRunspace -ApartmentState $ApartmentState
    }else{
      #Create session state for runspace
      if($RestrictedRunspace){
        #Restricted runspace requires manually adding various PS Commands needed
        $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::Create()
        $InitialSessionState.LanguageMode = [System.Management.Automation.PSLanguageMode]::FullLanguage
        $Commands = 'Write-Output',
        'Add-Member',
        'Add-Type',
        'ConvertFrom-Json',
        'Where-Object',
        'Get-Command',
        'Get-PSCallStack',
        'Out-String',
        'Get-Random',
        'Select-Object',
        'Sort-Object',
        'Get-Variable',
        'Remove-Variable',
        'ForEach-Object',
        'Register-ObjectEvent',
        'Get-Variable',
        'Get-EventSubscriber',
        'Unregister-Event',
        'Start-Sleep',
        'Invoke-Command',
        'Write-Error',
        'Import-module',
        'Remove-module',
        'Export-ModuleMember',
        'Invoke-RestMethod',
        'Measure-Object',
        'Get-CimInstance',
        'Select-String'
        $Commands | & { process {
            $command = $ExecutionContext.InvokeCommand.GetCmdlet($_)
            $CmdletEntry = [System.Management.Automation.Runspaces.SessionStateCmdletEntry]::new($_, $command.ImplementingType,$null)
            $null = $InitialSessionState.Commands.Add($CmdletEntry)
        }}
        if($Command_list){
          $Command_list | & { process {
              $command = $ExecutionContext.InvokeCommand.GetCmdlet($_)
              $CmdletEntry = [System.Management.Automation.Runspaces.SessionStateCmdletEntry]::new($_, $command.ImplementingType,$null)
              $null = $InitialSessionState.Commands.Add($CmdletEntry)
          }}
        }
        if(!$PSProviders){
          $PSProviders = 'Function','Registry','Environment','FileSystem'
        }
        $PSProviders | & { process {
            $provider = Get-PSProvider $_
            $providerentry = [System.Management.Automation.Runspaces.SessionStateProviderEntry]::new($_,$provider.ImplementingType,$provider.HelpFile)
            $null = $InitialSessionState.Providers.Add($providerentry)
        }}
      }else{
        #$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault2()
        $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault2()
      }

      #$Function_list = (dir function:).Name
      #list of Functions that will be passed to runspace
      if($Function_list){
        $function_list | & { process {
            #Pass to runspace
            $SessionStateFunctionEntry = [System.Management.Automation.Runspaces.SessionStateFunctionEntry]::new($_, [string]::Intern(($ExecutionContext.InvokeCommand.GetCommand($_, [System.Management.Automation.CommandTypes]::Function)).Definition))
            $null = $InitialSessionState.Commands.Add($SessionStateFunctionEntry)
        }}
      }
      if($modules_list){
        foreach($m in $modules_list)
        {
          #Pass to runspace
          $null = $InitialSessionState.ImportPSModule($m)
        } 
      }
      $new_Runspace =[runspacefactory]::CreateRunspace($InitialSessionState)
      $new_Runspace.ApartmentState = $ApartmentState
      $new_Runspace.ThreadOptions = "ReuseThread"
      #Open runspace, set name and add variables needed
      $null = $new_Runspace.Open()
    }  
    if($Runspace_Name){
      $new_Runspace.name = $Runspace_Name
    }
    $PSModuleAutoLoadingPreference = [System.Management.Automation.PSModuleAutoLoadingPreference]::All
    $new_Runspace.SessionStateProxy.SetVariable('PSModulePath',$env:PSModulePath)
    $new_Runspace.SessionStateProxy.SetVariable('PSModuleAutoLoadingPreference',$PSModuleAutoLoadingPreference)
    #$new_Runspace.SessionStateProxy.SetVariable("logfile",$logfile)
    $new_Runspace.SessionStateProxy.SetVariable("thisApp",$thisApp)
    if($PassCallPath){
      $CallStack = $((Get-PSCallStack)[1].Command)
      if($CallStack -match "(?<value>.*).ps"){
        $CallStack = "$($matches.Value)"
      }
      $Callpath = "$CallStack|$Runspace_Name"
      $new_Runspace.SessionStateProxy.SetVariable("Callpath",$Callpath)
    }
    $InvalidVariables = 'MyInvocation','PSBoundParameters','HOME','Host','$','profile','StackTrace','Variable_list','jobCleanup'
    if($Variable_list){
      if($Variable_list -is [System.Collections.Generic.Dictionary`2[System.String,System.Object]]){
        $Variable_list = $Variable_list.GetEnumerator()
        $KeyName = 'Key'
      }else{
        $KeyName = 'Name'
      }
      $Variable_list | & { process {
          try{
            $name = $_.$KeyName
            if($name -notin $InvalidVariables){
              $new_Runspace.SessionStateProxy.SetVariable($name,$_.Value)
            }      
          }catch{
            write-ezlogs "An exception occurred setting variable $($_.$KeyName) for runspace: $Runspace_name" -CatchError $_  
          }      
      }}
    }elseif(!$arguments){
      $new_Runspace.SessionStateProxy.SetVariable("synchash",$synchash)
    }
   
    #Add scriptblock to run
    $psCmd = [PowerShell]::Create().AddScript($ScriptBlock)
    #$psCmd.Runspace.Dispose()
    if($arguments){
      #$parameters = $scriptblock.Ast.ParamBlock.Parameters.where({$_.Name.VariablePath -in $arguments.Key})
      if($arguments -is [System.Collections.Generic.Dictionary`2[System.String,System.Object]]){
        $arguments = $arguments.GetEnumerator()
        $KeyName = 'Key'
      }else{
        $KeyName = 'Name'
      }
      $arguments | & { process {
          try{
            $name = $_.$KeyName
            if($name -notin $InvalidVariables -and $name -in $ScriptBlock.Ast.ParamBlock.Parameters.name.VariablePath.userpath){
              $null = $psCmd.AddParameter($name,$_.Value)
            }
          }catch{
            write-ezlogs "An exception occurred setting variable $($name) for runspace: $Runspace_name" -CatchError $_
          }      
      }}
    }

    #Register state changed events
    if($Set_stateChangeEvent){
      #While this seems like a nice clean way to cleanup a runspace, there are gotchas. 
      #This overall still uses more memory than a dedicated job cleanup timer
      #The event wont fire/register properly if a new runspace is created from within another runspace. Once that parent runspace is done, any events are gone
      $null = Register-ObjectEvent -InputObject $psCmd -EventName InvocationStateChanged -Action {
        param([System.Management.Automation.PowerShell] $ps)
        try{
          # NOTE: Use $EventArgs.InvocationStateInfo, not $ps.InvocationStateInfo, 
          #       as the latter is updated in real-time, so for a short-running script
          #       the state may already have changed since the event fired.
          $state = $EventArgs.InvocationStateInfo.State
          $RunSpaceName = $ps.runspace.name
          if ($state -eq 'Failed') {
            write-ezlogs "[ERROR] Runspace $($RunSpaceName) changed state to: $($state)" -loglevel 2 -logtype Threading
          }elseif($state){
            #write-ezlogs ">>>> Runspace $($ps.Runspace.Name) changed state to: $($state)" -loglevel 2 -logtype Threading
          }
          $EventID = $Event.SourceIdentifier
          if($EventArgs.InvocationStateInfo.Reason){
            write-ezlogs "| Runspace '$($RunSpaceName)' InvocationStateChanged Reason: $($EventArgs.InvocationStateInfo.Reason)" -loglevel 2 -logtype Threading
          }
          If ($State -eq 'Completed')  {
            try{
              #If the log writer runspace ended when it shouldnt, attempt to restart
              if($($RunSpaceName) -eq 'log_Writer_runspace' -and $thisApp.LogWriterEnabled){
                try{
                  [System.IO.File]::AppendAllText($Logfile, "[$([datetime]::Now.ToString())] [WARNING] Log Writer stopped unexpectedly (LogWriterEnabled: $($thisApp.LogWriterEnabled))...attempting to restart - Logfile: $($thisApp.Config.Log_file)`n[$([datetime]::Now.ToString())] ERRORS: $($ps.Streams.Error)",[System.Text.Encoding]::Unicode)
                  Get-LogWriter -logfile $logfile -Startup -thisApp $thisApp
                }catch{
                  [System.IO.File]::AppendAllText($logfile, "[$([datetime]::Now.ToString())] [$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber):$($RunSpaceName)] [ERROR] An exception occurred restarting the log writer: $($_)",[System.Text.Encoding]::Unicode)
                }
              }
              if($thisApp.Config.Dev_mode -or $thisApp.Config.Log_Level -ge 3){
                $e_index = 0
                if($ps.Streams.Information){
                  write-ezlogs "[========= RUNSPACE $($RunSpaceName) Information =========]" -logtype Threading
                  foreach ($e in $ps.Streams.Information) {
                    $e_index++
                    write-ezlogs "[Information $e_index Message:$($RunSpaceName)] =========================================================================`n$($e.toString())" -logtype Error
                  }
                  write-ezlogs "=========================================================================" -logtype Threading
                }
                $e_index = 0
                if($ps.Streams.Progress){
                  write-ezlogs "[========= RUNSPACE $($RunSpaceName) Progress =========]" -logtype Threading
                  foreach ($e in $ps.Streams.Progress) {
                    $e_index++
                    write-ezlogs "[DEBUG] [Progress $e_index Message:$($RunSpaceName)] =========================================================================`n$($e.toString())" -logtype Error
                  }
                  write-ezlogs "=========================================================================" -logtype Threading
                }
                $e_index = 0
                if($ps.Streams.Verbose){
                  write-ezlogs "[========= RUNSPACE $($RunSpaceName) Verbose =========]" -logtype Threading
                  foreach ($e in $ps.Streams.Verbose) {
                    $e_index++
                    write-ezlogs "[DEBUG] [Verbose $e_index Message:$($RunSpaceName)] =========================================================================`n$($e.toString())" -logtype Error
                  }
                  write-ezlogs "=========================================================================" -logtype Threading    
                }           
                $e_index = 0
                if($ps.Streams.Debug){
                  write-ezlogs "[========= RUNSPACE $($RunSpaceName) Debug =========]" -logtype Threading
                  foreach ($e in $ps.Streams.Debug) {
                    $e_index++
                    write-ezlogs "[DEBUG] [Debug $e_index Message:$($RunSpaceName)] =========================================================================`n$($e.toString())" -logtype Error
                  }
                  write-ezlogs "=========================================================================" -logtype Threading
                }
              }
              if($ps.Streams.Warning){
                write-ezlogs "[========= RUNSPACE $($RunSpaceName) HAD Warnings =========]" -logtype Error
                $e_index = 0
                foreach ($e in $ps.Streams.Warning) {
                  $e_index++
                  write-ezlogs "[Warning $e_index Message:$($RunSpaceName)] =========================================================================`n$($e.toString())" -logtype Threading -Warning
                }
              }
              if($ps.HadErrors -and -not [string]::IsNullOrEmpty($ps.Streams.Error)){
                write-ezlogs "[========= RUNSPACE $($RunSpaceName) HAD ($($ps.Streams.Error.count)) ERRORS =========]" -logtype Error
                write-ezlogs "ERRORS: $($ps.Streams.Error | out-string)" -logtype Error
                $e_index = 0
                foreach ($e in $ps.Streams.Error) {
                  $e_index++
                  write-ezlogs "[ERROR $e_index Runspace:$($RunSpaceName)] =========================================================================" -logtype Error -CatchError $e
                }
                if($ps.InvocationStateInfo.State -and $ps.InvocationStateInfo.State -ne 'Completed'){
                  write-ezlogs "[InvocationStateInfo Message:$($RunSpaceName)] =========================================================================`n[State]: $($ps.InvocationStateInfo.State)`n[Reason]: $($ps.InvocationStateInfo.Reason)" -logtype Error
                }
                if($e_index -gt 0){
                  write-ezlogs "=========================================================================" -logtype Error
                }
              }
              #Cleanup for OutOfProcRunspace
              if($ps.Runspace.RunspaceIsRemote -and $ps.Runspace.ConnectionInfo.ProcessId){
                write-ezlogs ">>>> Stopping runspace remote process with ID: '$($ps.Runspace.ConnectionInfo.ProcessId)'" -logtype Threading
                Stop-Process -Id $ps.Runspace.ConnectionInfo.ProcessId -Force -ErrorAction SilentlyContinue
              }
            }catch{
              write-ezlogs "An exception occurred performing cleanup of runspace: $($_.name)" -catcherror $_
            }finally{
              #Clean out unused runspace jobs
              $Job = $thisApp.Jobs[$($thisApp.Jobs.Name.IndexOf($RunSpaceName))]
              if($Job){
                write-ezlogs "| Runspace '$($RunSpaceName)' Completed" -logtype Threading
                if($Job.Runspace.AsyncWaitHandle -is [System.IDisposable]){
                  write-ezlogs "| Disposing Runspace.AsyncWaitHandle" -logtype Threading
                  $Job.Runspace.AsyncWaitHandle.close()
                  $Job.Runspace.AsyncWaitHandle.dispose()
                }
                if($Job.powershell.Runspace -is [System.IDisposable]){
                  write-ezlogs "| Disposing powershell.runspace instance" -logtype Threading
                  if($Job.powershell.Runspace.Events.Subscribers.EventName){
                    write-ezlogs "| Events: $($Job.powershell.Runspace.Events.Subscribers | out-string)" -logtype Threading
                  }
                  $Job.powershell.Runspace.Dispose()
                  $Job.powershell.Runspace = $Null
                }
                if($Job.PowerShell -is [System.IDisposable]){
                  write-ezlogs "| Disposing Powershell instance" -logtype Threading
                  $Job.PowerShell.Stop()
                  $Job.PowerShell.dispose()
                }
                $Null = $thisApp.Jobs.remove($Job)
                $ps = $Null
                $Job = $Null
              }
            }
          }elseif($thisApp.Config.Dev_mode){
            write-ezlogs "| Runspace '$($RunSpaceName)' InvocationStateChanged: $($State) - InvocationStateInfo: $($EventArgs.InvocationStateInfo)" -loglevel 2 -logtype Threading -Dev_mode
          }
        }catch{
          write-ezlogs "An exception occurred in InvocationStateChanged for runspace $($ps.Runspace.Name)" -CatchError $_           
        } 
      }
    }
    #Add runspace to jobs monitor hashtable and execute
    write-ezlogs ">>>> Starting new runspace: $Runspace_Name" -loglevel 2 -logtype Threading
    $psCmd.Runspace = $new_Runspace
    [void]$thisApp.Jobs.Add([PSCustomObject]@{
        PowerShell = $psCmd
        Name = $Runspace_Name
        Runspace = $psCmd.BeginInvoke()
    })
  }catch{
    write-ezlogs "An exception occurred attempting to create and start runspace: $Runspace_Name" -CatchError $_
  }
}
#---------------------------------------------- 
#endregion Start Runspace Function
#----------------------------------------------

#---------------------------------------------- 
#region Stop Runspace Function
#----------------------------------------------
function Stop-Runspace
{
  [CmdletBinding()]
  param (   
    $thisApp = $thisApp,
    [string]$runspace_name,
    [switch]$force,
    [switch]$Check,
    [switch]$StopAsync,
    [switch]$ReturnOutput,
    [switch]$Wait
  )
  try{
    $temphash = $Null
    $Job_toRemove = $Null
    if($runspace_name){
      if($thisApp.Jobs.count -gt 0){
        #$temphash = [System.WeakReference]::new($thisApp.Jobs,$false).Target
        $temphash = $thisApp.Jobs.clone()
        $JobIndex = $temphash.name.indexof($Runspace_Name)
        if($JobIndex -ne -1){
          $Job_toRemove = $temphash[$JobIndex]
          #$Job_toRemove = $temphash | & { process {if($_.powershell.runspace.name -eq $Runspace_Name -or $_.Name -eq $Runspace_Name){$_}}}
        }
      }
      $existingjob_check = Get-runspace -name $Runspace_Name
      if($existingjob_check){
        try{
          if(($existingjob_check.RunspaceAvailability -eq 'Busy') -and $existingjob_check.RunspaceStateInfo.state -eq 'Opened' -and $Runspace_Name -ne 'Start_SplashScreen' -and $Runspace_Name -notmatch 'Show_'){   
            if($Check){
              write-ezlogs "[Stop-Runspace] >>>> Existing Runspace '$Runspace_Name' found. Taking no further actions" -logtype Threading
              return $true
            }elseif($force){
              write-ezlogs "Existing Runspace '$Runspace_Name' found, force closing" -warning -logtype Threading
              $null = $existingjob_check.Dispose()   
              write-ezlogs "| Runspace disposed" -warning -logtype Threading
              if($ReturnOutput){
                $Job_toOutput = $thisApp.Jobs | where {$_.powershell.runspace.name -eq $Runspace_Name -or $_.Name -eq $Runspace_Name}
                if($Job_toOutput){
                  if($Job_toOutput.OutputObject){
                    write-ezlogs "| Returning Runspace job output" -warning -logtype Threading
                    return $Job_toOutput.OutputObject 
                  }                                               
                }else{
                  write-ezlogs "Unable to find Runspace job with name $Runspace_Name within Jobs synchash" -Warning -logtype Threading
                }
              }
            }else{
              write-ezlogs "Existing Runspace '$Runspace_Name' found, attempting to stop" -warning -logtype Threading  
              if($Job_toRemove){
                $output = $Job_toRemove | & { process {
                    $null = write-ezlogs "| Calling Stop on Runspace job" -warning -logtype Threading
                    $null = $_.powershell.stop()
                    if($ReturnOutput){
                      if($_.OutputObject){
                        $_.OutputObject
                        $null = write-ezlogs "| Returning Runspace job output" -warning -logtype Threading      
                      }                                       
                    }          
                }}
                if($ReturnOutput){return $output}                   
              }else{
                write-ezlogs "Unable to find Runspace job with name $Runspace_Name within Jobs synchash" -Warning -logtype Threading
              } 
            }           
          }else{
            if($Check){
              write-ezlogs "[Stop-Runspace] Existing Runspace '$Runspace_Name' found, but is not busy or its state is: $($existingjob_check.RunspaceStateInfo.state). Availability: $($existingjob_check.RunspaceAvailability)" -warning -logtype Threading
              return $true
            }else{
              write-ezlogs "[Stop-Runspace] Existing Runspace '$Runspace_Name' found, but is not busy or its state is not opened. Disposing.." -warning -logtype Threading
              $null = $existingjob_check.Dispose()
              if($Job_toRemove){
                $Job_toRemove | & { process {
                    if($thisApp.Jobs -contains $_){
                      write-ezlogs "| Removing runspace from managed jobs" -warning -logtype Threading
                      $null = $thisApp.Jobs.remove($_)    
                    }
                }}
              }
            }
          }
        }catch{
          write-ezlogs "An exception occurred stopping existing runspace $runspace_name" -catcherror $_
        }
      }elseif($Job_toRemove){
        write-ezlogs "| Unable to find available runspace $runspace_name in any state, but found it still within managed runspace jobs, removing..." -warning -logtype Threading
        if($Job_toRemove){
          $Job_toRemove | & { process {
              if($thisApp.Jobs -contains $_){
                write-ezlogs "| Removing runspace $($_.Name) from managed jobs" -warning -logtype Threading
                if($_.Runspace.AsyncWaitHandle){
                  write-ezlogs "| Disposing Runspace.AsyncWaitHandle" -logtype Threading
                  $_.Runspace.AsyncWaitHandle.close()
                  $_.Runspace.AsyncWaitHandle.dispose()
                }
                if($_.powershell.Runspace){
                  write-ezlogs "| Disposing runspace instance" -logtype Threading
                  $_.powershell.Runspace.Dispose()
                  $_.powershell.Runspace = $Null
                }
                if($_.PowerShell){
                  write-ezlogs "| Disposing Powershell instance" -logtype Threading
                  $_.PowerShell.Stop()
                  $_.powershell.dispose()
                }
                $null = $thisApp.Jobs.remove($_)
              }           
          }}  
        }
      }else{
        write-ezlogs "No Runspace found to stop with name $Runspace_Name" -Dev_mode -logtype Threading
      }
      return
    } 
  }catch{
    write-ezlogs "An exception occurred stopping or checking existing runspace $runspace_name" -catcherror $_
  }finally{
    $temphash = $null
    $Job_toRemove = $Null
  }
}
#---------------------------------------------- 
#endregion Stop Runspace Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-Runspace','Stop-Runspace')