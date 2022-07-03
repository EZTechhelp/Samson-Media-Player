<#
    .Name
    Start-Runspace

    .Version 
    0.1.0

    .SYNOPSIS
    Allows Invoking new runspaces

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - Module designed for EZT-GameManager

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES

#>
#---------------------------------------------- 
#region Start Runspace Function
#----------------------------------------------
function Start-Runspace
{
  param (   
    $scriptblock,
    $thisApp,
    [switch]$StartRunspaceJobHandler, 
    $Variable_list,
    $logfile = $thisApp.Config.Log_File,
    $thisScript,
    [string]$runspace_name,
    [switch]$cancel_runspace,
    $synchash,
    [switch]$startup_perf_timer,
    $modules_list,
    [int]$maxRunspaces = [int]$env:NUMBER_OF_PROCESSORS + 1,
    $Script_Modules,
    $startup_stopwatch,
    [switch]$Wait,
    [switch]$verboselog
  )
  if($StartRunspaceJobHandler -and !$JobCleanup)
  {
    <#    if($Script_Modules){
        foreach($m in $Script_Modules){
        try{
        if($verboselog){write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber):$Runspace_Name] >>>> Importing Module $m for runspace" | out-file $logfile -Force -Append -Encoding unicode}
        Import-module $m
        $PSModuleAutoLoadingPreference = 'All'
        }
        catch{
        write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber):$Runspace_Name] An exception occurred loading modules $($_ | out-string)" | out-file $logfile -Force -Append -Encoding unicode
        } 
        }
    }#>
    $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    <#    $Function_list = (dir function:).Name
        foreach($f in $function_list)
        {
        #Pass to runspace
      
        $FunctionLogWindow = Get-Content Function:\$f
        $DefinitionLogWindow = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $f, $FunctionLogWindow
        $null = $InitialSessionState.Commands.Add($DefinitionLogWindow)
    }#> 
    $Global:JobCleanup = [hashtable]::Synchronized(@{})
    $Global:Jobs = [system.collections.arraylist]::Synchronized((New-Object System.Collections.ArrayList))
    
    $jobCleanup.Flag = $True   
    $jobCleanup_newRunspace =[runspacefactory]::CreateRunspace($InitialSessionState)
    $jobCleanup_newRunspace.ApartmentState = "STA"
    $jobCleanup_newRunspace.ThreadOptions = "ReuseThread"          
    $jobCleanup_newRunspace.Open()  
    $jobCleanup_newRunspace.name = 'JobCleanup_Runspace'      
    $jobCleanup_newRunspace.SessionStateProxy.SetVariable("jobCleanup",$jobCleanup)     
    $jobCleanup_newRunspace.SessionStateProxy.SetVariable("jobs",$jobs) 
    $jobCleanup_newRunspace.SessionStateProxy.SetVariable("logfile",$logfile) 
    $jobCleanup_newRunspace.SessionStateProxy.SetVariable("thisScript",$thisScript) 
    $jobCleanup_newRunspace.SessionStateProxy.SetVariable("thisApp",$thisApp)
    $jobCleanup_newRunspace.SessionStateProxy.SetVariable("verboselog",$verboselog)
    $Jobcleanup_Timer = 0    
    $jobCleanup.PowerShell = [PowerShell]::Create().AddScript({
        #Routine to handle completed runspaces
        Do 
        {  
          try
          {  
            $temphash = $jobs.clone() 
            Foreach($runspace in $temphash) 
            {            
              If ($runspace.Runspace.isCompleted) 
              {
                if(!$logfile){
                  if($thisApp.Config.Log_File){$logfile = $thisApp.Config.Log_File}elseif($thisScript){$logfile = "$env:appdata\\$($thisScript.Name)\\Logs\\$($thisScript.Name)-$($thisScript.Version).log"}
                }
                #$logfile = 'c:\logs\EZT-MediaPlayer-0.1.5.log'
                #$verboselog = $false              
             
                #$endinvoke = $runspace.powershell.EndInvoke($runspace.Runspace)
                if($verboselog){write-output "[$(Get-date -format $logdateformat)] >>>> Runspace '$($runspace.powershell.runspace.name)' Completed" | out-file $logfile -Force -Append -Encoding unicode}            
                if($runspace.powershell.HadErrors){
                  write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber):$($runspace.powershell.runspace.name)] [-----RUNSPACE $($runspace.powershell.runspace.name) HAD ERRORS------]" | out-file $logfile -Force -Append -Encoding unicode                  
                  $e_index = 0
                  foreach ($e in $runspace.powershell.Streams.Error)
                  {
                    $e_index++
                    write-output "[$(Get-date -format $logdateformat)] [ERROR $e_index Message] ========================================================================= $($e | out-string)" | out-file $logfile -Force -Append -Encoding unicode
                  }
                  write-output "[$(Get-date -format $logdateformat)] Information: $($runspace.powershell.Streams.information | out-string)" | out-file $logfile -Force -Append -Encoding unicode                 
                  write-output "[$(Get-date -format $logdateformat)] -----------------" | out-file $logfile -Force -Append -Encoding unicode
                  #$error.Clear()
                }
                $runspace.powershell.Runspace.Dispose()
                $runspace.powershell.dispose()
                #if($verboselog){write-output "[$(Get-date -format $logdateformat)] | Status: $($runspace.powershell.runspace | out-string)" | out-file $logfile -Force -Append -Encoding unicode}
                $runspace.Runspace = $null
                $runspace.powershell = $null 
              } 
            }
            #Clean out unused runspace jobs

            $temphash | where {$_.runspace -eq $Null} | foreach {
              $jobs.remove($_)
            } 
          }catch{
            write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber):$($runspace.powershell.runspace.name)] An exception occurred performing cleanup of runspace: $($runspace.powershell.runspace | out-string)`n $($_ | out-string)" | out-file $logfile -Force -Append -Encoding unicode             
          } 
          $Jobcleanup_Timer++                     
          Start-Sleep -Milliseconds 500  
        }
        while ($jobCleanup.Flag)
    })
    $jobCleanup.PowerShell.Runspace = $jobCleanup_newRunspace
    if($verboselog){write-output "Starting Jobcleanup Runspace: $($jobCleanup_newRunspace | out-string)" | out-file $logfile -Force  -Encoding unicode -Append}
    $jobCleanup.Thread = $jobCleanup.PowerShell.BeginInvoke()
    #return $jobCleanup
  }
  if(![system.io.file]::Exists($logfile)){
    if([system.io.file]::Exists($thisApp.Config.Log_File)){$logfile = $thisApp.Config.Log_File}elseif($thisScript.Name){$logfile = "$env:appdata\\$($thisScript.Name)\\Logs\\$($thisScript.Name)-$($thisScript.Version).log"}else{$logfile = ($Variable_list | where {$_.name -eq 'Logfile'}).value}
  }
  if($cancel_runspace -and $runspace_name){
    $existingjob_check = $Jobs | where {$_.powershell.runspace.name -eq $Runspace_Name}
    if($existingjob_check){
      try{
        if(($existingjob_check.powershell.runspace) -and $existingjob_check.runspace.isCompleted -eq $false -and $Runspace_Name -ne 'Start_SplashScreen' -and $Runspace_Name -notmatch 'Show_'){
          write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber):$Runspace_Name] [WARNING] Existing Runspace '$Runspace_Name' found, attempting to cancel" | out-file $logfile -Force -Append -Encoding unicode 
          write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber):$Runspace_Name] [WARNING] Runspace Output: $($existingjob_check.powershell.Streams | out-string)" | out-file $logfile -Force -Append -Encoding unicode
          $existingjob_check.powershell.stop()      
          $existingjob_check.powershell.Runspace.Dispose()
          $existingjob_check.powershell.dispose()
          $jobs.remove($existingjob_check)      
        }
      }catch{
        write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber):$Runspace_Name] An exception occurred stopping existing runspace $runspace_name $($_ | out-string)" | out-file $logfile -Force -Append -Encoding unicode 
      }
    }
    return
  }
  $existingjobs = $jobs.clone()
  $existingjob_check = $existingjobs | where {$_.powershell.runspace.name -eq $Runspace_Name -or $_.Name -eq $Runspace_Name}
  if($existingjob_check){
    try{
      if(($existingjob_check.powershell.runspace) -and $existingjob_check.runspace.isCompleted -eq $false -and $Runspace_Name -notmatch 'Start_SplashScreen' -and $Runspace_Name -ne 'Show_WebLogin' -and $Runspace_Name -notmatch 'Show_'){
        write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber):$Runspace_Name] [WARNING] Existing Runspace '$Runspace_Name' found as busy, stopping before starting new" | out-file $logfile -Force -Append -Encoding unicode  
        start-sleep -Milliseconds 100
        write-ezlogs "Streams: $($existingjob_check.powershell.Streams.Information  | out-string)" -Warning
        $existingjob_check.powershell.stop()      
        $existingjob_check.powershell.Runspace.Dispose()
        $existingjob_check.powershell.dispose()        
        $jobs.remove($existingjob_check)            
        #$null = $existingjob_check.powershell.EndInvoke($existingjob_check.Runspace)
      }
    }catch{
      write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber):$Runspace_Name] An exception occurred stopping existing runspace $runspace_name $($_ | out-string)" | out-file $logfile -Force -Append -Encoding unicode
    }
  } 

  #Create session state for runspace
  $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
  $Function_list = (dir function:).Name
  #list of Functions that will be passed to runspace
  foreach($f in $function_list)
  {
    #Pass to runspace
    $FunctionLogWindow = Get-Content Function:\$f
    $DefinitionLogWindow = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $f, $FunctionLogWindow
    $null = $InitialSessionState.Commands.Add($DefinitionLogWindow)
  } 
  #Create the runspace
  $new_Runspace =[runspacefactory]::CreateRunspace($InitialSessionState)
  write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber):$((Get-PSCallStack)[0].Command):$((Get-PSCallStack)[0].InvocationInfo.ScriptLineNumber)] Starting new runspace: $Runspace_Name" | out-file $logfile -Force -Append -Encoding unicode
  if($Runspace_Name -notmatch 'Start_SplashScreen' -and $Runspace_Name -notmatch 'Show_WebLogin' -and $runspace_name -notmatch 'ProfileEditor_Runspace' -and $runspace_name -notmatch 'Show_'){
    $new_Runspace.ApartmentState = "MTA"
  }else{
    $new_Runspace.ApartmentState = "STA"
  }
  $new_Runspace.ThreadOptions = "ReuseThread"         
  $new_Runspace.Open()
  if($Runspace_Name){
    $new_Runspace.name = $Runspace_Name
  }
  $new_Runspace.SessionStateProxy.SetVariable('env:PSModulePath',$env:PSModulePath)
  $new_Runspace.SessionStateProxy.SetVariable("jobCleanup",$jobCleanup)     
  $new_Runspace.SessionStateProxy.SetVariable("jobs",$jobs)
  $new_Runspace.SessionStateProxy.SetVariable("synchash",$synchash)
  if($Variable_list){
    foreach($v in $Variable_list)
    {
      $new_Runspace.SessionStateProxy.SetVariable($v.Name,$v.Value)
    } 
  }
  $callpath = "$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber):$Runspace_Name"
  $new_Runspace.SessionStateProxy.SetVariable('callpath',$callpath)
  $InputObject = New-Object 'System.Management.Automation.PSDataCollection[psobject]'
  $OutputObject = New-Object 'System.Management.Automation.PSDataCollection[psobject]'
  $psCmd = [PowerShell]::Create().AddScript($ScriptBlock)
  $psCmd.Runspace = $new_Runspace
  $null = $Jobs.Add((
      [pscustomobject]@{
        PowerShell = $psCmd
        Name = $Runspace_Name
        Runspace = $psCmd.BeginInvoke($InputObject,$OutputObject)
        OutputObject = $OutputObject
      }
  ))
  if($startup_perf_timer){return "[$(Get-date -format 'MM/dd/yyyy h:mm:ss tt')] [$($MyInvocation.MyCommand -replace ".ps1",''):$((Get-PSCallStack)[0].ScriptLineNumber)] >>>> Start-RunSpace:          $($startup_stopwatch.Elapsed.Seconds) seconds - $($startup_stopwatch.Elapsed.Milliseconds) Milliseconds"}
  
  #write-output "[$(Get-date -format $logdateformat)] [$((Get-PSCallStack)[1].FunctionName) - $((Get-PSCallStack).Position.StartLineNumber)] Seconds to Start-RunSpace: $($startup_stopwatch.Elapsed.TotalSeconds)" | out-file $logfile -Force -Append -Encoding unicode} 
  #Register-EngineEvent -SourceIdentifier "TestEvent" -Action {write-output " | Runspace TestEvent Happened! $($_ | out-string)" | out-file 'c:\logs\EventRegisterTest.log' -Force -Append}
}
#---------------------------------------------- 
#endregion Start Runspace Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-Runspace')