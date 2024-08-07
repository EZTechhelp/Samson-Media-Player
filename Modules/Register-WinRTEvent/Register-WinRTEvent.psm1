<#
    .Name
    Register-WinRTEvent

    .Version 
    0.1.0

    .SYNOPSIS
    Creates WinRT events by wrapping them into .NET events (via PoshWinRT) that can then be used with Register-ObjectEvent

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher
    - PoshWinRT - https://github.com/david-risney/PoshWinRT

    .RequiredModules

    .EXAMPLE

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES
    
#>


#----------------------------------------------
#region New-EventWrapper Function
#----------------------------------------------
function New-EventWrapper
{
  param(
    $target, 
    $eventName,
    $control = 'Windows.Media.SystemMediaTransportControls',
    $controlType = 'Windows.Media.SystemMediaTransportControlsButtonPressedEventArgs'
  )
  try{
    $wrapper = new-object "PoshWinRT.EventWrapper[$control,$controlType]"
    $wrapper.Register($target, $eventName)
  }catch{
    write-ezlogs "An exception occurred creating a new EventWrapper $eventName" -showtime -catcherror $_
  } 
}
#---------------------------------------------- 
#endregion New-EventWrapper Function
#----------------------------------------------


#----------------------------------------------
#region Await Function
#----------------------------------------------
Function Await($WinRtTask, $ResultType) {
  $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
  $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
  $netTask = $asTask.Invoke($null, @($WinRtTask))
  try{
    $null = $netTask.Wait(-1)
    if($netTask.IsCompleted){
      return $netTask.Result
    }elseif($netTask.IsFaulted){
      write-ezlogs "An exception occurred in await task" -showtime -catcherror $netTask.Exception
    }
  }catch{
    write-ezlogs "An exception occurred in await task" -showtime -catcherror $_
  }finally{
    if($netTask -is [System.IDisposable]){
      $null = $netTask.Dispose()
    }
  }       
}
#----------------------------------------------
#endregion Await Function
#----------------------------------------------


#----------------------------------------------
#region Register-WinRTEvent Function
#----------------------------------------------
function Register-WinRTEvent {
  param(
    $InputObject, 
    [string]$control,
    [string]$controlType,
    [switch]$RegisterSessionChange,
    $eventName,
    $synchash,
    $thisapp,
    $thisScript,  
    [switch]$Verboselog
  )

  if($RegisterSessionChange){
    #$eventname = "CurrentSessionChanged"
    $eventname = 'SessionsChanged'
    $control = "Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager"
    #$controlType = 'Windows.Media.Control.CurrentSessionChangedEventArgs'
    $controlType = 'Windows.Media.Control.SessionsChangedEventArgs'
    $action = { 
      param($sender,[Windows.Media.SystemMediaTransportControlsButtonPressedEventArgs]$e)
      $synchash = $Event.MessageData
      if($psversiontable.PSVersion.Major -gt 5){
        $Result = $e 
      }else{
        $Result = $e.Result
      }     
      try{
        write-ezlogs "SessionsChanged Sender $($sender.GetSessions())" -showtime
      }catch{
        write-ezlogs "An exception occurred Unregistering an event" -showtime -catcherror $_
      }  
    }
  }elseif($eventName -eq 'ButtonPressed'){
    $action = { 
      param($sender,$e)
      $synchash = $Event.MessageData
      $Result = $Null
      try{
        if($psversiontable.PSVersion.Major -gt 5){
          $Result = $e
        }else{
          $Result = $e.Result
        }
        write-ezlogs ">>>> Received command: $($result.Button) -- from SystemMediaTransportControl"
        if($result.Button -eq [Windows.Media.SystemMediaTransportControlsButton]::Play){
          if($synchash.PauseMedia_Timer -and !$synchash.PauseMedia_Timer.isEnabled){
            $synchash.PauseMedia_Timer.start()
          }      
        }elseif($result.Button -eq [Windows.Media.SystemMediaTransportControlsButton]::Pause){
          if($synchash.PauseMedia_Timer -and !$synchash.PauseMedia_Timer.isEnabled){
            $synchash.PauseMedia_Timer.start()
          }
        }elseif($result.Button -eq [Windows.Media.SystemMediaTransportControlsButton]::Stop){
          if($synchash.Stop_media_timer -and !$synchash.Stop_media_timer.isEnabled){
            $synchash.Stop_media_timer.start()
          }
        }elseif($result.Button -eq [Windows.Media.SystemMediaTransportControlsButton]::Next){ 
          if($synchash.SkipMedia_Timer -and !$synchash.SkipMedia_Timer.isEnabled){
            $synchash.SkipMedia_Timer.start()
          }
        }elseif($result.Button -eq [Windows.Media.SystemMediaTransportControlsButton]::Previous){
          if($synchash.PrevMedia_Timer -and !$synchash.PrevMedia_Timer.isEnabled){
            $synchash.PrevMedia_Timer.start()
          }
        }elseif($result.Button -eq [Windows.Media.SystemMediaTransportControlsButton]::ChannelDown){
          write-ezlogs "[NO_ACTION] Received ChannelDown command from SystemMediaTransportControl"
        }elseif($result.Button -eq [Windows.Media.SystemMediaTransportControlsButton]::ChannelUp){
          write-ezlogs "[NO_ACTION] Received ChannelUp command from SystemMediaTransportControl"
        }elseif($result.Button -eq [Windows.Media.SystemMediaTransportControlsButton]::FastForward){
          write-ezlogs "[NO_ACTION] Received FastForward command from SystemMediaTransportControl"
        }elseif($result.Button -eq [Windows.Media.SystemMediaTransportControlsButton]::Rewind){
          write-ezlogs "[NO_ACTION] Received Rewind command from SystemMediaTransportControl"
        }elseif($result.Button -eq [Windows.Media.SystemMediaTransportControlsButton]::Record){
          write-ezlogs "[NO_ACTION] Received Record command from SystemMediaTransportControl"
        }elseif($result.Button -match 'Mute'){
          write-ezlogs "[NO_ACTION] Received Mute command from SystemMediaTransportControl"
        }             
      }catch{
        write-ezlogs "An exception occurred Unregistering an event" -showtime -catcherror $_
      }  
    }
  }elseif($eventName -eq 'PropertyChanged'){
    $action = { 
      param($sender,$e)
      $synchash = $Event.MessageData
      write-ezlogs "Received PropertyChanged Event from SystemMediaTransportControl" -showtime
      #$Result = [Windows.Media.SystemMediaTransportControlsPropertyChangedEventArgs]$args[1].Result
      try{
        write-ezlogs "PropertyChanged Sender $($sender)" -showtime 
        write-ezlogs "PropertyChanged Result received $($e)" -showtime 
      }catch{
        write-ezlogs "An exception occurred Unregistering an event" -showtime -catcherror $_ 
      }  
    }
  }else{
    write-ezlogs "Unrecognized Event name '$eventname', unable to continue!" -showtime -Warning
    return
  }
  #Unregister any existing
  try{
    $existing = (Get-EventSubscriber -force | Where-Object {$_.Action.Command -eq $action -or $_.Action.Name -eq 'FireEvent' -or $_.Action.Name -eq $eventName})
    if($existing){
      write-ezlogs "Unregistering existing event 'FireEvent' for Name: $($existing.Action.Name) | ID: $($existing.Action.ID) | State: $($existing.Action.State)" -showtime -warning
      $existing | unregister-event -force
    }
  }catch{
    write-ezlogs "An exception occurred Unregistering an event" -showtime -catcherror $_
  }  

  if($psversiontable.PSVersion.Major -gt 5){
    try{
      [void](Register-ObjectEvent -InputObject $InputObject -EventName $eventName -MessageData $synchash -Action $action)
    }catch{
      write-ezlogs "An exception occurred Registering WinRT event $eventName" -showtime -catcherror $_
    } 
  }else{
    try{
      [void](Register-ObjectEvent -InputObject (New-EventWrapper -Target $InputObject -eventname $eventName -control $control -controlType $controlType) -EventName FireEvent -MessageData $synchash -Action $action)
    }catch{
      write-ezlogs "An exception occurred Registering WinRT event $eventName" -showtime -catcherror $_
    } 
  }

}
#---------------------------------------------- 
#endregion Register-WinRTEvent Function
#----------------------------------------------

#----------------------------------------------
#region New-StorageFile Function
#----------------------------------------------
function New-StorageFile
{
  param(
    [string]$path
  ); 
  try{
    if([system.io.file]::Exists($path)){
      $Null = [System.Reflection.Assembly]::LoadWithPartialName("System.Runtime.WindowsRuntime")
      if(($psversiontable.PSVersion.Major -le 5)){
        $null = [Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime]
      }    
      return (Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($path)) ([Windows.Storage.StorageFile]))
    }
  }catch{
    write-ezlogs "An exception occurred creating a new Storagefile for $path" -showtime -catcherror $_
  } 
}
#---------------------------------------------- 
#endregion New-StorageFile Function
#----------------------------------------------
Export-ModuleMember -Function @('Register-WinRTEvent','New-StorageFile','Await','New-EventWrapper')