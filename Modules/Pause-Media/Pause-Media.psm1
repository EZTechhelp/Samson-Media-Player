<#
    .Name
    Pause-Media

    .Version 
    0.1.0

    .SYNOPSIS
    Pauses playback of all media  

    .DESCRIPTION
       
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
#region Pause-Media Function
#----------------------------------------------
function Pause-Media
{
  Param (
    $thisApp,
    $synchash,
    [switch]$Startup,
    [switch]$Verboselog
  )
  try{  
    if($synchash.VLC.state -match 'Playing'){
      write-ezlogs 'Pausing Vlc playback' -showtime -color cyan 
      $synchash.Now_Playing_Label.content = ($synchash.Now_Playing_Label.content) -replace 'Now Playing', 'Paused'
      $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\Material-PlayCircle.png")
      $image =  [System.Drawing.Image]::FromStream($stream_image)
      $Synchash.Menu_Pause.image = $image    
      $Synchash.Menu_Pause.Header = 'Resume Playback'  
      $synchash.VideoView_Play_Icon.kind = 'PlayCircleOutline'
      $synchash.VLC.pause()
      $synchash.Timer.stop()
      if($synchash.chat_WebView2.Visibility -ne 'Hidden'){
        $synchash.chat_WebView2.stop()        
      }  
      return  
    }elseif($synchash.VLC.state -match 'Paused'){
      #$current_track = (Get-CurrentTrack -ApplicationName $thisapp.config.App_Name) 
      write-ezlogs 'Resuming Vlc playback' -showtime -color cyan 
      $synchash.Now_Playing_Label.content = ($synchash.Now_Playing_Label.content) -replace 'Paused', 'Now Playing'
      $synchash.VLC.pause()
      $stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\Material-PauseCircle.png")
      $image =  [System.Drawing.Image]::FromStream($stream_image)
      $Synchash.Menu_Pause.image = $image
      $Synchash.Menu_Pause.Header = 'Pause Playback'
      $synchash.VideoView_Play_Icon.kind = 'PauseCircleOutline'
      $synchash.Timer.Start()
      if($synchash.chat_WebView2.Visibility -ne 'Hidden'){$synchash.chat_WebView2.Reload()}      
      return
    }else{
      $current_track = (Get-CurrentTrack -ApplicationName $thisapp.config.App_Name)
    }        
    if($current_track.is_playing -or $synchash.Spotify_Status -eq 'Playing'){     
      $devices = Get-AvailableDevices -ApplicationName $thisapp.config.App_Name
      if($devices){
        write-ezlogs 'Pausing Spotify playback' -showtime -color cyan        
        $synchash.Timer.stop()
        $synchash.Spotify_Status = 'Paused'
        if($thisapp.config.Use_Spicetify){
          try{
            if((NETSTAT.EXE -n) | where {$_ -match '127.0.0.1:8974'}){
              write-ezlogs "[Pause_media] Pausing Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -color cyan
              Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing 
            }else{
              write-ezlogs '[Pause_media] PODE does not seem to be running on 127.0.0.1:8974 -- attempting fallback to Suspend-Playback' -showtime -warning
              Suspend-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $devices.id
            } 
          }catch{
            write-ezlogs "[Pause_media] An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE' -- attempting Suspend-Playback" -showtime -catcherror $_ 
            #Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id            
          }
        }else{
          write-ezlogs "[Pause_media] Stopping Spotify playback with Suspend-Playback -ApplicationName $($thisapp.config.App_Name) -DeviceId $($devices.id)" -showtime -color cyan
          Suspend-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $devices.id
        }               
      } 
      return 
    }elseif($current_track.currently_playing_type -ne $null -or $synchash.Spotify_Status -eq 'Paused'){
      $devices = Get-AvailableDevices -ApplicationName $thisapp.config.App_Name
      $synchash.Spotify_Status = 'Playing'
      if($thisapp.config.Use_Spicetify){
        try{
          if((NETSTAT.EXE -n) | where {$_ -match '127.0.0.1:8974'}){
            write-ezlogs "[Pause_media] Resuming Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PLAY'" -showtime -color cyan
            Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PLAY' -UseBasicParsing 
          }else{
            write-ezlogs '[Pause_media] PODE does not seem to be running on 127.0.0.1:8974 -- attempting fallback to Resume-Playback' -showtime -warning
            Resume-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $devices.id
          }        
        }catch{
          write-ezlogs "[Pause_media] An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PLAY' -- attempting Resume-Playback" -showtime -catcherror $_   
          #Resume-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id         
        }
      }else{
        write-ezlogs "[Pause_media] Resuming Spotify playback with Resume-Playback -ApplicationName $($thisapp.config.App_Name) -DeviceId $($devices.id)" -showtime -color cyan
        Resume-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $devices.id      
      }      
      $synchash.Timer.Start()
      return
    }     
  }catch{
    write-ezlogs 'An exception occurred in Pause-Media' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Pause-Media Function
#----------------------------------------------
Export-ModuleMember -Function @('Pause-Media')