<#
    .Name
    Stop-Media

    .Version 
    0.1.0

    .SYNOPSIS
    Stops playback of all media and resets various controls and UI properties  

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
#region Stop-Media Function
#----------------------------------------------
function Stop-Media
{
  Param (
    $thisApp,
    $synchash,
    [switch]$Startup,
    [switch]$Verboselog
  )
  try{  
    $callpath = "$((Get-PSCallStack)[1].Command):$((Get-PSCallStack)[1].InvocationInfo.ScriptLineNumber):Stop-Media"
    $synchash.Timer.stop()
    $synchash.Media_URL.text = ''
    if($synchash.vlc.IsPlaying){
      if($thisApp.config.Verbose_Logging){write-ezlogs 'Stoping vlc playback' -showtime}
      $synchash.VLC.stop()    
      $synchash.chat_WebView2.stop()  
      $synchash.chat_column.Width = '*'
      $synchash.chat_WebView2.Visibility = 'Hidden'
      $current_track = $null 
      if(Get-Process streamlink*){Get-Process streamlink* | Stop-Process -Force}   
    }elseif($synchash.Youtube_WebPlayer_title -and $synchash.Youtube_WebPlayer_URL){
      $synchash.Youtube_WebPlayer_URL = $null
      $synchash.Youtube_WebPlayer_title = $null  
      $synchash.Youtube_WebPlayer_timer.start()
    }elseif($synchash.Spotify_WebPlayer_title -and $synchash.Spotify_WebPlayer_URL){
      $synchash.Spotify_WebPlayer_URL = $null
      $synchash.Spotify_WebPlayer_title = $null  
      $synchash.Spotify_WebPlayer_timer.start()
    }else{
      $current_track = (Get-CurrentTrack -ApplicationName $thisapp.config.App_Name)
    }      
    if($current_track.is_playing){
      $devices = Get-AvailableDevices -ApplicationName $thisapp.config.App_Name
      $synchash.Spotify_Status = 'Stopped'
      if($devices){
        write-ezlogs 'Stoping Spotify playback' -showtime
        if($thisapp.config.Use_Spicetify){
          try{
            if((NETSTAT.EXE -n) | where {$_ -match '127.0.0.1:8974'}){
              write-ezlogs "[Stop_media] Stopping Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -color cyan
              Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing 
            }else{
              write-ezlogs '[Stop_media] PODE doesnt not seem to be running on 127.0.0.1:8974 - falling back to try Suspend-Playback' -showtime -warning
              Suspend-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $devices.id
            }
          }catch{
            write-ezlogs "[Stop_media] An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE' -- attempting Suspend-Playback" -showtime -catcherror $_ 
            #Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id            
          }
        }else{
          write-ezlogs "[Stop_media] Stopping Spotify playback with Suspend-Playback -ApplicationName $($thisapp.config.App_Name) -DeviceId $($devices.id)" -showtime -color cyan
          Suspend-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $devices.id
        }          
      }  
    }
    if($thisApp.config.Chat_View){
      $synchash.Chat_View_Button.IsEnabled = $false    
      $synchash.chat_column.Width = "*"
      $synchash.Chat_Icon.Kind="ChatRemove"
      $synchash.Chat_View_Button.Opacity=0.7
      $synchash.Chat_View_Button.ToolTip="Chat View Not Available"
      $synchash.chat_WebView2.Visibility = 'Hidden'
      $synchash.chat_WebView2.stop()        
    }   
    Get-Playlists -verboselog:$false -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -Refresh_Spotify_Playlists    
    if($thisApp.config.Verbose_Logging){write-ezlogs 'Resetting background/UI' -showtime}
    $syncHash.MainGrid_Background_Image_Source_transition.content = ''
    $syncHash.MainGrid_Background_Image_Source.Source = $null
    $syncHash.MainGrid.Background = $synchash.Window.TryFindResource('MainGridBackGradient')          
  }catch{
    write-ezlogs 'An exception occurred in Stop-Media' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Stop-Media Function
#----------------------------------------------
Export-ModuleMember -Function @('Stop-Media')