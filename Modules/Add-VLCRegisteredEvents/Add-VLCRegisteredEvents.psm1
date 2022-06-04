<#
    .Name
    Add-VLCRegisteredEvents

    .Version 
    0.1.0

    .SYNOPSIS
    Allows creating and registering various events for VLC 

    .DESCRIPTION
       
    .Configurable Variables

    .Requirements
    - Powershell v3.0 or higher

    .RequiredModules

    .EXAMPLE

    .OUTPUTS
    System.Management.Automation.PSObject

    .Author
    EZTechhelp - https://www.eztechhelp.com

    .NOTES
#>

#----------------------------------------------
#region Add-VLCRegisteredEvents Function
#----------------------------------------------
function Add-VLCRegisteredEvents
{
  param (
    $synchash,
    $thisapp,
    $thisScript,  
    [switch]$Verboselog
  )
  
  #Unregister any existing
  try{
    #Get-EventSubscriber -force | unregister-event -force
  }catch{
    write-ezlogs "An exception occurred Unregistering an event" -showtime -catcherror $_
  } 
  
  #VLC Playing Event
  try{
    $null = Register-ObjectEvent -InputObject $synchash.Vlc -EventName Playing -MessageData $synchash -Action { 
      $synchash = $Event.MessageData
      try{
        $synchash.Timer.start()  
        if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> [VLC_Playing_EVENT] Starting tick timer" -showtime}
      }catch{
        write-ezlogs "An exception occurred in vlc Playing event" -showtime -catcherror $_
      }   
    }.GetNewClosure()
  }catch{
    write-ezlogs "An exception occurred Registering an event" -showtime -catcherror $_
  }
  
  #VLC Stopped Event
  try{
    $null = Register-ObjectEvent -InputObject $synchash.Vlc -EventName Stopped -MessageData $synchash -Action { 
      $synchash = $Event.MessageData
      try{
        #$synchash.Timer.Stop()
        #if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> [VLC_Stopped_EVENT] Stopping tick timer" -showtime -color cyan}
      }catch{
        write-ezlogs "An exception occurred in vlc TimeChanged event" -showtime -catcherror $_
      }   
    }
  }catch{
    write-ezlogs "An exception occurred Registering an event" -showtime -catcherror $_
  } 
  <#$synchash.Vlc.add_Muted({
      $sender = $args[0]
      [System.EventArgs]$e = $args[1] 
      try{
      $synchash.Volume_icon.kind = 'Volumeoff'
      }catch{
      write-ezlogs "An exception occurred in vlc Add_muted event" -showtime -catcherror $_
      }   
      })
  #>
  <#$synchash.Vlc.add_EncounteredError({
      $sender = $args[0]
      [System.EventArgs]$e = $args[1] 
      try{
      write-ezlogs "add_EncounteredError E: $($e | out-string)"
      write-ezlogs "add_EncounteredError This: $($this | out-string)"
      }catch{
      write-ezlogs "An exception occurred in vlc Add_EncounteredError event" -showtime -catcherror $_
      }   
      })
  #>   
}
#---------------------------------------------- 
#endregion Add-VLCRegisteredEvents Function
#----------------------------------------------
Export-ModuleMember -Function @('Add-VLCRegisteredEvents')