<#
    .Name
    Start-InterProcessPipes

    .Version 
    0.1.0

    .SYNOPSIS
    Creates, monitors and manages inter process named pipes

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
#region Start-InterProcessPipes Function
#----------------------------------------------
function Start-InterProcessPipes{
  [CmdletBinding()]
  param (
    $synchash,
    $thisApp,
    [switch]$use_Runspace
  )
  $InterProcessPipes_ScriptBlock = {
    [CmdletBinding()]
    param (
      $synchash,
      $thisApp,
      [switch]$use_Runspace
    )
    try{
      if($thisApp.Config.Installed_AppID){
        $appid = $thisApp.Config.Installed_AppID
      }else{
        Import-Module "$($thisApp.Config.Current_Folder)\Modules\Get-HelperFunctions\Get-HelperFunctions.psm1" -NoClobber -DisableNameChecking
        $appid = (Get-AllStartApps -Name $thisApp.Config.App_name).AppID
        $thisApp.Config.Installed_AppID = $appid
      }
      if($appid){
        write-ezlogs "#### Starting new InterProcessPipes with name: $($appid)"
        $thisApp.InterProcessPipes = $true
        while ($thisApp.InterProcessPipes)
        {        
          try{
            write-ezlogs ">>>> Starting new InterProcessPipes instance"
            $InterProcessPipe = [System.IO.Pipes.NamedPipeServerStream]::new($appid)
            $Wait = $InterProcessPipe.WaitForConnectionAsync()
            do{
              write-ezlogs "....Waiting for Named Pipe Connection"
              Start-Sleep -Milliseconds 500
            }while(!$Wait.IsCanceled -and !$wait.IsCompleted -and $thisApp.InterProcessPipes)
            if($thisApp.InterProcessPipes){
              $sr = [System.IO.StreamReader]::new($InterProcessPipe)
              #$cmd= $sr.ReadLine()              
              while (($cmd= $sr.ReadLine()) -ne 'exit' -and $thisApp.InterProcessPipes -and $InterProcessPipe.IsConnected) 
              {
                #Process each command or line written from client side of pipe
                if($cmd){
                  write-ezlogs ">>>> Received InterProcessPipes message: $($cmd) - IsConnected: $($InterProcessPipe.IsConnected)"
                }
              }
              if($cmd -eq 'Exit' -or !$thisApp.InterProcessPipes){
                write-ezlogs "| Received exit command, shutting down InterProcessPipes" -warning
                $thisApp.InterProcessPipes = $false
                return
              }elseif(!$InterProcessPipe.IsConnected){
                write-ezlogs "| InterProcessPipe is no longer connected, terminating session" -warning
                continue
              }
            }else{
              write-ezlogs "InterProcessPipes has been canceled" -warning
              #TODO: Need to figure out how to properly cancel the pipe manually from the host/sever side
              return
            }
          }catch{
            write-ezlogs "An exception occurred in namedpipeserverstream: $appid" -CatchError $_
            $thisApp.InterProcessPipes = $false
          }finally{
            if($sr -is [System.IDisposable]){
              $sr.Dispose()
            }
            if($InterProcessPipe -is [System.IDisposable]){
              $InterProcessPipe.Dispose()
            }
            if($Wait -is [System.IDisposable] -and ($Wait.IsCanceled -or $wait.IsCompleted -or $Wait.IsFaulted)){
              $Wait.Dispose()
            }
          }
        }
      }else{
        write-ezlogs "Cannot start NamedPipeServerStream - no App ID provided!" -warning
      }
    }catch{
      write-ezlogs "An exception occurred in InterProcessPipes_scriptblock" -showtime -catcherror $_
    }finally{
      write-ezlogs "InterProcessPipes_Runspace has ended!" -warning
    }
  }
  if($use_Runspace){
    Start-Runspace $InterProcessPipes_ScriptBlock -arguments $PSBoundParameters -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "InterProcessPipes_Runspace" -thisApp $thisapp -RestrictedRunspace -function_list 'write-ezlogs' -cancel_runspace
  }else{
    Invoke-Command -ScriptBlock $InterProcessPipes_ScriptBlock -ArgumentList $synchash,$thisApp,$use_Runspace
  }
}
#---------------------------------------------- 
#endregion Start-InterProcessPipes Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-InterProcessPipes')