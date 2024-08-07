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
    [switch]$UnregisterOnly,
    [switch]$Verboselog
  )
  
  #Unregister any existing
  try{
    $EventsList = 'Playing','EncounteredError','EndReached','Muted','UnMuted','Paused','Opening'
    $Registered_Events = Get-EventSubscriber -force
    if($thisApp.Config.Dev_mode){write-ezlogs "Registered Events: $(($Registered_Events) | out-string)" -LogLevel 2 -logtype Libvlc -Dev_mode}
    if($UnregisterOnly){
      $Registered_Events | & { process {
          try{
            if($_.EventName -in $EventsList){
              if($thisApp.Config.Dev_mode){write-ezlogs "Unregistering existing event: $($_.EventName)" -LogLevel 2 -logtype Libvlc -Dev_mode}
              $Nul = Unregister-Event -SourceIdentifier $_.SourceIdentifier -Force
            }
          }catch{
            write-ezlogs "An exception occurred Unregistering an event $($_.EventName)" -showtime -catcherror $_
          } 
      }}
      $Registered_Events = $Null
      return
    }
  }catch{
    write-ezlogs "An exception occurred Unregistering an event" -showtime -catcherror $_
  } 
  
  #VLC Playing Event
  try{
    if('Playing' -in $Registered_Events.EventName){
      $playing = $Registered_Events | where {$_.EventName -eq 'Playing'}
    }   
    if($playing){
      if($thisApp.Config.Dev_mode){write-ezlogs "Unregistering existing event: $($playing.EventName)" -LogLevel 2 -logtype Libvlc -Dev_mode}
      Unregister-Event -SourceIdentifier $playing.SourceIdentifier -Force
    }
    $Null = Register-ObjectEvent -InputObject $synchash.Vlc -EventName Playing -MessageData $synchash -Action { 
      $synchash = $Event.MessageData
      try{
        $synchash.VLC_IsPlaying_State = $true
        try{
          Update-Subtitles -synchash $synchash -thisApp $thisApp -clear
          Update-Subtitles -synchash $synchash -thisApp $thisApp -UpdateSubtitles
        }catch{
          write-ezlogs "An exception occurred in Update-Subtitles -clear" -catcherror $_
        } 
        if($thisApp.Config.Debug_Logging){
          $existingjob_check = $(Get-Runspace) | where {$_.id -eq $Event.RunspaceId -or $_.InstanceId.Guid -eq $Event.RunspaceId} 
          write-ezlogs "[VLC_Playing_EVENT] VLC Playing Event: $($Event | select * | out-string)" -showtime -LogLevel 3 -logtype Libvlc
          write-ezlogs "[VLC_Playing_EVENT] All Runspaces: $($(Get-Runspace) | select * | out-string)" -showtime -LogLevel 3 -logtype Libvlc
          if($existingjob_check){
            write-ezlogs "[VLC_Playing_EVENT] >>>> Found playback Runspace: $($existingjob_check | select * | out-string)" -showtime -LogLevel 3 -logtype Libvlc
            write-ezlogs "[VLC_Playing_EVENT] | InitialSessionState Variables: $($existingjob_check.InitialSessionState.Variables | out-string)" -showtime -LogLevel 3 -logtype Libvlc
            write-ezlogs "[VLC_Playing_EVENT] | GetCallStack: $($existingjob_check.Debugger.GetCallStack() | out-string)" -showtime -LogLevel 3 -logtype Libvlc
          }
        }    
        write-ezlogs "[VLC_Playing_EVENT] >>>> Received VLC Playing Event -- Current Volume $($synchash.vlc.Volume) -- Mute: $($synchash.vlc.mute)" -LogLevel 2 -logtype Libvlc
        write-ezlogs "[VLC_Playing_EVENT] | State: $($synchash.vlc.media.State) -- Mrl: $($synchash.vlc.media.Mrl) -- IsParsed: $($synchash.vlc.media.IsParsed)" -LogLevel 2 -logtype Libvlc                
        #Set Volume
        if(-not [string]::IsNullOrEmpty($synchash.Volume_Slider.value)){
          $thisapp.Config.Media_Volume = $synchash.Volume_Slider.value
          if($synchash.vlc -and $synchash.vlc.Volume -ne $synchash.Volume_Slider.value){
            write-ezlogs "[VLC_Playing_EVENT] | Setting vlc volume to Volume_Slider Value: $($synchash.Volume_Slider.value)" -loglevel 2 -logtype Libvlc
            if($thisApp.Config.Libvlc_Version -eq '4'){
              $synchash.vlc.SetVolume($synchash.Volume_Slider.value)
            }else{
              $synchash.vlc.Volume = $synchash.Volume_Slider.value
            }
          }         
        }elseif(-not [string]::IsNullOrEmpty($thisapp.Config.Media_Volume) -and $synchash.vlc -and $synchash.vlc.Volume -ne $thisapp.Config.Media_Volume){
          write-ezlogs "[VLC_Playing_EVENT] | Setting vlc volume to Config Media Volume: $($thisapp.Config.Media_Volume)" -loglevel 2
          $synchash.Volume_Slider.value = $thisapp.Config.Media_Volume
          if($thisApp.Config.Libvlc_Version -eq '4'){
            $synchash.vlc.SetVolume($thisapp.Config.Media_Volume)
          }else{
            $synchash.vlc.Volume = $thisapp.Config.Media_Volume
          }
        }else{
          write-ezlogs "[VLC_Playing_EVENT] | Volume level unknown??: $($synchash.Volume_Slider.value)" -loglevel 2 -Warning
          $thisapp.Config.Media_Volume = 100
        }
        if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled -and $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus -ne 'Playing'){
          write-ezlogs " | [VLC_Playing_EVENT] Setting SystemMediaPlayer status from '$($synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus)' to 'Playing'" -showtime -LogLevel 2 -logtype Libvlc   
          $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus = 'Playing'
          $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
        }
        if($synchash.PlayButton_ToggleButton -and !$synchash.PlayButton_ToggleButton.isChecked){
          $synchash.PlayButton_ToggleButton.isChecked = $true
        } 
        if($synchash.PauseButton_ToggleButton.isChecked){
          $synchash.PauseButton_ToggleButton.isChecked = $false
        }
        if($synchash.MiniPlayButton_ToggleButton){
          $synchash.MiniPlayButton_ToggleButton.uid = $false
        }
        if($synchash.PlayButton_ToggleButton.Uid -eq 'IsPaused'){
          $synchash.PlayButton_ToggleButton.Uid = $null
        }
        if($synchash.VideoView_Play_Icon.kind -eq 'PlayCircleOutline'){
          $synchash.VideoView_Play_Icon.kind = 'PauseCircleOutline'
        }
        if($synchash.MuteButton_ToggleButton.isChecked -and !$synchash.vlc.mute){
          write-ezlogs "| Mute button is checked but vlc is not muted, muting" -logtype Libvlc -warning
          $synchash.vlc.mute = $true
        }elseif($synchash.vlc.mute -and !$synchash.MuteButton_ToggleButton.isChecked){
          write-ezlogs "| Vlc is muted but mute button is not checked, checking" -logtype Libvlc -warning
          $synchash.MuteButton_ToggleButton.isChecked = $true
        }
        if(-not [string]::IsNullOrEmpty($synchash.Current_Audio_Session.GroupingParam)){
          write-ezlogs "[VLC_Playing_EVENT] Executing Set-AudioSessions -- GroupingParam: $($synchash.Current_Audio_Session.GroupingParam)" -Dev_mode
          Set-AudioSessions -thisApp $thisApp -synchash $synchash
        }
        if($thisApp.Config.Dev_mode){
          $synchash.Vlc_Current_audiotrack = $synchash.vlc.media.tracks | where {$_.TrackType -eq 'Audio'}
          write-ezlogs " | [VLC_Playing_EVENT] Vlc_Current_audiotrack: $($synchash.vlc.media.tracks | out-string)" -loglevel 2 -logtype Libvlc -Dev_mode
        }             
      }catch{
        write-ezlogs "An exception occurred in vlc Playing event" -showtime -catcherror $_ 
      }   
    } 
  }catch{
    write-ezlogs "An exception occurred Registering an event" -showtime -catcherror $_
  }
  

  #VLC Opening Event
  try{
    $Opening = $Registered_Events | where {$_.EventName -eq 'Opening'}
    if($Opening){
      write-ezlogs "Unregistering existing event: $($Opening.EventName)" -LogLevel 2 -logtype Libvlc
      Unregister-Event -SourceIdentifier $Opening.SourceIdentifier -Force
    }
    $Null = Register-ObjectEvent -InputObject $synchash.Vlc -EventName Opening -MessageData $synchash  -Action { 
      $synchash = $Event.MessageData
      try{
        if(-not $([string]$synchash.vlc.media.Mrl).StartsWith("dshow://")){
          $synchash.Now_Playing_Title_Label.DataContext = 'OPENING...'
        }       
        #write-ezlogs ">>>> VLC Opening event: $($event.SourceArgs | out-string)" -logtype Libvlc -Dev_mode
        #$synchash.VideoView.Background = [System.Windows.Media.Brushes]::Black
      }catch{
        write-ezlogs "An exception occurred in vlc Opening event" -showtime -catcherror $_ 
      }   
    }
  }catch{
    write-ezlogs "An exception occurred Registering an event" -showtime -catcherror $_
  }

  #VLC Stopped Event
  <#  try{
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
  }#>
  try{
    $EncounteredError = $Registered_Events | where {$_.EventName -eq 'EncounteredError'}
    if($EncounteredError){
      write-ezlogs "Unregistering existing event: $($EncounteredError.EventName)" -LogLevel 2 -logtype Libvlc
      Unregister-Event -SourceIdentifier $EncounteredError.SourceIdentifier -Force
    }
    $null = Register-ObjectEvent -InputObject $synchash.Vlc -EventName EncounteredError -MessageData $synchash -Action { 
      $synchash = $Event.MessageData
      try{
        write-ezlogs "[VLC_ERROR_EVENT] VLC encountered an error: $($synchash.libvlc.LastLibVLCError | out-string)" -showtime -color red -LogLevel 2 -logtype Libvlc -AlertUI
        if($synchash.libvlc.LastLibVLCError -match 'No active audio output' -and $thisapp.config.Enable_WebEQSupport){
          if([System.IO.File]::Exists("${env:ProgramFiles(x86)}\VB\CABLE\VBCABLE_ControlPanel.exe")){
            $appinstalled = [System.IO.FileInfo]::new("$("${env:ProgramFiles(x86)}\VB\CABLE\VBCABLE_Setup.exe")").versioninfo.fileversion -replace ', ','.'
          }elseif([System.IO.File]::Exists("$env:ProgramW6432\VB\CABLE\VBCABLE_ControlPanel.exe")){
            $appinstalled = [System.IO.FileInfo]::new("$env:ProgramW6432\VB\CABLE\VBCABLE_Setup_x64.exe").versioninfo.fileversion -replace ', ','.'
          }else{
            write-ezlogs "[VLC_ERROR_EVENT] Unable to find install of VB-Cable virtual audio device which is required to use EQ with WebPlayers. Disabling EQ" -logtype Libvlc -AlertUI
            Set-ApplicationAudioDevice -thisApp $thisApp -synchash $synchash -stop -Stoplibvlc
          }
        }
      }catch{
        write-ezlogs "An exception ironicly occurred in vlc EncounteredError event" -showtime -catcherror $_
      }   
    }
  }catch{
    write-ezlogs "An exception occurred Registering an event" -showtime -catcherror $_
  }  
  #AudioDevice
  <#  try{
      $null = Register-ObjectEvent -InputObject $synchash.Vlc -EventName AudioDevice -MessageData $synchash -Action { 
      $synchash = $Event.MessageData
      try{
      write-ezlogs ">>>> [VLC_AudioDevice Changed]: $($($args[1]) | out-string)" -showtime -color cyan -LogLevel 2 -logtype Libvlc
      }catch{
      write-ezlogs "An exception occurred in vlc AudioDevice event" -showtime -catcherror $_
      }   
      }
      }catch{
      write-ezlogs "An exception occurred Registering an event" -showtime -catcherror $_
  }#> 

  #EndReached
  if($thisApp.Config.Libvlc_Version -eq '4'){
    #No endreached event in libvlc 4?
  }else{
    try{
      $EndReached = $Registered_Events | where {$_.EventName -eq 'EndReached'}
      if($EndReached){
        write-ezlogs "Unregistering existing event: $($EndReached.EventName)" -LogLevel 2 -logtype Libvlc
        Unregister-Event -SourceIdentifier $EndReached.SourceIdentifier -Force
      }
      $Null = Register-ObjectEvent -InputObject $synchash.Vlc -EventName EndReached -MessageData $synchash -Action { 
        $synchash = $Event.MessageData
        try{  
          $synchash.VLC_IsPlaying_State = $synchash.Vlc.isPlaying
          if($thisapp.config.Auto_Playback -or $thisapp.config.Auto_Repeat){
            write-ezlogs ">>>> Media playback ended, Auto_Playback enabled: $($thisapp.config.Auto_Playback) - Auto_Repeat enabled: $($thisapp.config.Auto_Repeat), stopping vlc playback" -logtype Libvlc
            if($synchash.vlc.media){
              write-ezlogs " | Disposing Libvlc_media" -logtype Libvlc
              $synchash.vlc.media = $Null
            }
            $null = $synchash.VLC.stop()
          }else{
            write-ezlogs ">>>> Media playback ended, Auto_playback Disabled, stopping mediatimer, executing stop-media" -showtime -LogLevel 2  -logtype Libvlc
            $synchash.timer.stop()
            if($synchash.StopButton_Button){
              write-ezlogs "| invoking Stop-Media" -showtime -LogLevel 2 -logtype Libvlc
              Stop-Media -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisApp -UpdateQueue
            }
          }                
        }catch{
          write-ezlogs "An exception occurred in vlc EndReached event" -showtime -catcherror $_
        }   
      }
    }catch{
      write-ezlogs "An exception occurred Registering EndReached event" -showtime -catcherror $_
    } 
  }

  #Muted
  try{
    $Muted = $Registered_Events | where {$_.EventName -eq 'Muted'}
    if($Muted){
      write-ezlogs "Unregistering existing event: $($Muted.EventName)" -LogLevel 2 -logtype Libvlc
      Unregister-Event -SourceIdentifier $Muted.SourceIdentifier -Force
    }
    $Null = Register-ObjectEvent -InputObject $synchash.Vlc -EventName Muted -MessageData $synchash -Action { 
      $synchash = $Event.MessageData
      try{               
        $synchash.VLC_IsPlaying_State = $synchash.Vlc.isPlaying 
        write-ezlogs ">>>> [VLC_Muted_Event]: Vlc Volume: $($($synchash.vlc.Volume)) - VLC Muted: $($synchash.vlc.mute) - Mute_togglebutton.isChecked: $($synchash.MuteButton_ToggleButton.isChecked)" -showtime -LogLevel 2 -logtype Libvlc
        if($synchash.vlc.Mute -and !$synchash.MuteButton_ToggleButton.isChecked){
          write-ezlogs "[VLC_Muted_Event] | Vlc shouldnt be muted as the mute button is not checked - unmuting" -warning  -logtype Libvlc
          $synchash.vlc.Mute = $false
          $thisApp.Config.Media_Muted = $false
        }else{
          $thisApp.Config.Media_Muted = $true
        }                  
      }catch{
        write-ezlogs "An exception occurred in vlc Muted event" -showtime -catcherror $_
      }   
    }
    
  }catch{
    write-ezlogs "An exception occurred Registering Muted event" -showtime -catcherror $_
  }

  #UnMuted
  try{
    $UnMuted = $Registered_Events | where {$_.EventName -eq 'UnMuted'}
    if($UnMuted){
      write-ezlogs "Unregistering existing event: $($UnMuted.EventName)" -LogLevel 2 -logtype Libvlc
      Unregister-Event -SourceIdentifier $UnMuted.SourceIdentifier -Force
    }
    $Null = Register-ObjectEvent -InputObject $synchash.Vlc -EventName UnMuted -MessageData $synchash -Action { 
      $synchash = $Event.MessageData
      try{   
        $synchash.VLC_IsPlaying_State = $synchash.Vlc.isPlaying             
        write-ezlogs ">>>> [VLC_UnMuted_Event]: Vlc Volume: $($($synchash.vlc.Volume))" -showtime -LogLevel 2 -logtype Libvlc
        $thisApp.Config.Media_Muted = $false        
      }catch{
        write-ezlogs "An exception occurred in vlc UnMuted event" -showtime -catcherror $_
      }   
    }

  }catch{
    write-ezlogs "An exception occurred Registering UnMuted event" -showtime -catcherror $_
  }

  #Paused
  try{
    $Paused = $Registered_Events | where {$_.EventName -eq 'Paused'}
    if($Paused){
      write-ezlogs "Unregistering existing event: $($Paused.EventName)" -LogLevel 2 -logtype Libvlc
      Unregister-Event -SourceIdentifier $Paused.SourceIdentifier -Force
    }
    $null = Register-ObjectEvent -InputObject $synchash.Vlc -EventName Paused -MessageData $synchash -Action { 
      $synchash = $Event.MessageData
      try{       
        $synchash.VLC_IsPlaying_State = $synchash.Vlc.isPlaying         
        write-ezlogs ">>>> [VLC_Paused_Event]" -showtime  -LogLevel 2 -logtype Libvlc            
        if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled -and $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus -ne 'Paused'){
          $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus = 'Paused'
          $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
        }
        if($synchash.VideoView_Play_Icon.kind -eq 'PauseCircleOutline'){
          $synchash.VideoView_Play_Icon.kind = 'PlayCircleOutline'
        }
      }catch{
        write-ezlogs "An exception occurred in vlc Paused event" -showtime -catcherror $_
      }   
    }
  }catch{
    write-ezlogs "An exception occurred Registering Paused event" -showtime -catcherror $_
  }

  #VolumeChanged
  <#  try{
      $null = Register-ObjectEvent -InputObject $synchash.Vlc -EventName VolumeChanged -MessageData $synchash -Action { 
      $synchash = $Event.MessageData
      try{                
      #write-ezlogs ">>>> [VLC_VolumeChanged_Event]: Volume: $($($synchash.vlc.volume) | out-string)" -showtime -logtype Libvlc -LogLevel 2 
      #write-ezlogs " | Event Sender: $($Event.sender | out-string)" -logtype Libvlc -LogLevel 2              
      }catch{
      write-ezlogs "An exception occurred in vlc VolumeChanged event" -showtime -catcherror $_
      }   
      }
      }catch{
      write-ezlogs "An exception occurred Registering VolumeChanged event" -showtime -catcherror $_
  }#>

  #Forward
  <#  try{
      $null = Register-ObjectEvent -InputObject $synchash.Vlc -EventName Forward -MessageData $synchash -Action { 
      $synchash = $Event.MessageData
      try{                
      write-ezlogs ">>>> [VLC_Forward_Event]: $($($synchash.vlc) | out-string)" -showtime -color cyan  -LogLevel 2 -logtype Libvlc           
      }catch{
      write-ezlogs "An exception occurred in vlc Forward event" -showtime -catcherror $_
      }   
      }
      }catch{
      write-ezlogs "An exception occurred Registering Forward event" -showtime -catcherror $_
  }#>

  #Backward
  <#  try{
      $null = Register-ObjectEvent -InputObject $synchash.Vlc -EventName Backward -MessageData $synchash -Action { 
      $synchash = $Event.MessageData
      try{                
      write-ezlogs ">>>> [VLC_Backward_Event]: $($($synchash.vlc) | out-string)" -showtime -color cyan  -LogLevel 2 -logtype Libvlc           
      }catch{
      write-ezlogs "An exception occurred in vlc Backward event" -showtime -catcherror $_
      }   
      }
      }catch{
      write-ezlogs "An exception occurred Registering Backward event" -showtime -catcherror $_
  }#>
  $Registered_Events = $Null
}
#---------------------------------------------- 
#endregion Add-VLCRegisteredEvents Function
#----------------------------------------------
Export-ModuleMember -Function @('Add-VLCRegisteredEvents')