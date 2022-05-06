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
    $logfile,
    $thisScript,
    $runspace_name,
    [switch]$cancel_runspace,
    $synchash,
    $modules_list,
    $Script_Modules,
    [switch]$debug_verbose
  )
  if($Variable_list){

    $Function_list = (dir function:).Name
  }else{
    $Function_list = (dir function:).Name
  }
 
  if($StartRunspaceJobHandler -and !$JobCleanup)
  {
    #$modules_list = $($variable_list) | where {$_.Name -eq 'Script_Modules'}
    if($Script_Modules){
      foreach($m in $Script_Modules){
        try{
          if($debug_verbose){
            Write-Ezlogs ">>>> Importing Module $m for runspace" -showtime
          }
          Import-module $m
          $PSModuleAutoLoadingPreference = 'All'
        }
        catch{
          Write-Ezlogs "An exception occurred loading modules" -showtime -catcherror $_
        } 
      }
    }
    $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    foreach($f in $function_list)
    {
      #Pass to runspace
      
      $FunctionLogWindow = Get-Content Function:\$f
      $DefinitionLogWindow = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $f, $FunctionLogWindow
      $null = $InitialSessionState.Commands.Add($DefinitionLogWindow)
    } 
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
    $jobCleanup_newRunspace.SessionStateProxy.SetVariable("debug_verbose",$debug_verbose)
    $Jobcleanup_Timer = 0    
    $jobCleanup.PowerShell = [PowerShell]::Create().AddScript({
        #Routine to handle completed runspaces
        Do 
        {    
          Foreach($runspace in $jobs) 
          {            
            If ($runspace.Runspace.isCompleted) 
            {
              if($thisApp.Config.Log_File){$logfile = $thisApp.Config.Log_File}elseif($thisScript){$logfile = "$env:SystemDrive\\Logs\\$($thisScript.Name)-$($thisScript.Version).log"}
              #$logfile = 'c:\logs\EZT-MediaPlayer-0.1.5.log'
              $debug_Verbose = $false              
              try{
                #$debug_verbose = $true
                $endinvoke = $runspace.powershell.EndInvoke($runspace.Runspace)
                if($debug_Verbose){write-output "[$(Get-date -format $logdateformat)] >>>> Runspace '$($runspace.powershell.runspace.name)' Completed" | out-file $logfile -Force -Append -Encoding unicode}
                #if($debug_Verbose){write-output "[$(Get-date -format $logdateformat)] Runspace '$($runspace.runspace | out-string)'" | out-file $logfile -Force -Append}              
                if($runspace.powershell.HadErrors){
                  Write-ezlogs "`n[-----RUNSPACE $($runspace.powershell.runspace.name) HAD ERRORS------]" 
                  $e_index = 0
                  foreach ($e in $error)
                  {
                    $e_index++
                    Write-ezlogs "[ERROR $e_index Message] =========================================================================" -CatchError $e
                  }                 
                  Write-ezlogs '-----------------'
                  #$error.Clear()
                }
                $runspace.powershell.Runspace.Dispose()
                $runspace.powershell.dispose()
                if($debug_Verbose){write-output "[$(Get-date -format $logdateformat)] | Status: $($runspace.powershell.runspace | out-string)" | out-file $logfile -Force -Append -Encoding unicode}
                $runspace.Runspace = $null
                $runspace.powershell = $null 
              }catch{
                write-ezlogs "An exception occurred performing cleanup of runspace: $($runspace.powershell.runspace | out-string)" -showtime -catcherror $_              
              }             
            } 
          }
          #Clean out unused runspace jobs
          $temphash = $jobs.clone()
          $temphash | where {$_.runspace -eq $Null} | foreach {
            $jobs.remove($_)
          } 
          $Jobcleanup_Timer++                     
          Start-Sleep -Milliseconds 500  
        }
        while ($jobCleanup.Flag)
    })
    $jobCleanup.PowerShell.Runspace = $jobCleanup_newRunspace
    if($debug_Verbose){write-output "Starting Jobcleanup Runspace: $($jobCleanup | out-string)" | out-file $logfile -Force -Append}
    $jobCleanup.Thread = $jobCleanup.PowerShell.BeginInvoke()
    #return $jobCleanup
  }
  if($cancel_runspace -and $runspace_name){
    $existingjob_check = $Jobs | where {$_.powershell.runspace.name -eq $Runspace_Name}
    if($existingjob_check){
      try{
        if(($existingjob_check.powershell.runspace) -and $existingjob_check.runspace.isCompleted -eq $false -and $Runspace_Name -ne 'Start_SplashScreen'){
          write-ezlogs "Existing Runspace '$Runspace_Name' found, attempting to cancel" -showtime -warning 
          $existingjob_check.powershell.stop()      
          $existingjob_check.powershell.Runspace.Dispose()
          $existingjob_check.powershell.dispose()
          $jobs.remove($existingjob_check)      
        }
      }catch{
        write-ezlogs "An exception occurred stopping existing runspace $runspace_name" -showtime -catcherror $_
      }
    }
    return
  }
  $existingjob_check = $Jobs | where {$_.powershell.runspace.name -eq $Runspace_Name}
  if($existingjob_check){
    try{
      if(($existingjob_check.powershell.runspace) -and $existingjob_check.runspace.isCompleted -eq $false -and $Runspace_Name -ne 'Start_SplashScreen' -and $Runspace_Name -ne 'Show_WebLogin'){
        write-ezlogs "Existing Runspace '$Runspace_Name' found as busy, stopping before starting new" -showtime -warning
        <#        foreach($job in $jobs){
            write-ezlogs "Before Runspace Job $($job.powershell.runspace | select * | out-string)"
        } #>  
        $existingjob_check.powershell.stop()      
        $existingjob_check.powershell.Runspace.Dispose()
        $existingjob_check.powershell.dispose()
        $jobs.remove($existingjob_check)      
        <#        foreach($job in $jobs){
            write-ezlogs "After removal Runspace Job $($job.powershell.runspace | select * | out-string)"
        }#>       
        #$null = $existingjob_check.powershell.EndInvoke($existingjob_check.Runspace)
      }
    }catch{
      write-ezlogs "An exception occurred stopping existing runspace $runspace_name" -showtime -catcherror $_
    }
  } 

  #Create session state for runspace
  $InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
  
  #list of Functions that will be passed to runspace
  $Function_list = (dir function:).Name
  foreach($f in $function_list)
  {
    #Pass to runspace
    $FunctionLogWindow = Get-Content Function:\$f
    $DefinitionLogWindow = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $f, $FunctionLogWindow
    $null = $InitialSessionState.Commands.Add($DefinitionLogWindow)
  }
  
  #Create the runspace
  $new_Runspace =[runspacefactory]::CreateRunspace($InitialSessionState)
  $new_Runspace.ApartmentState = "STA"
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
  
  $InputObject = New-Object 'System.Management.Automation.PSDataCollection[psobject]'
  $OutputObject = New-Object 'System.Management.Automation.PSDataCollection[psobject]'
  $psCmd = [PowerShell]::Create().AddScript($ScriptBlock)
  $psCmd.Runspace = $new_Runspace
  $null = $Jobs.Add((
      [pscustomobject]@{
        PowerShell = $psCmd
        Runspace = $psCmd.BeginInvoke($InputObject,$OutputObject)
        OutputObject = $OutputObject
      }
  ))
  #Register-EngineEvent -SourceIdentifier "TestEvent" -Action {write-output " | Runspace TestEvent Happened! $($_ | out-string)" | out-file 'c:\logs\EventRegisterTest.log' -Force -Append}
}
#---------------------------------------------- 
#endregion Start Runspace Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-Runspace')

