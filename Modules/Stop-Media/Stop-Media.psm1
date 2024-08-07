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
    - Module designed for Samson Media Player

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
    $synchashWeak,
    [switch]$UpdateQueue,
    [switch]$Startup,
    [switch]$StopMonitor,
    [switch]$Verboselog
  )
  try{
    $stop_media_Measure = [system.diagnostics.stopwatch]::StartNew()
    write-ezlogs "#### Executing Stop Media" -showtime -linesbefore 1
    if($synchashWeak.Target.Timer.isEnabled){
      write-ezlogs "| Stopping Media Timer" -showtime
      $synchashWeak.Target.Timer.stop()
    }
    if($synchashWeak.Target.Update_Playing_Playlist_Timer.isEnabled){
      write-ezlogs "| Stopping Update_Playing_Playlist_Timer" -showtime
      $synchashWeak.Target.Update_Playing_Playlist_Timer.stop()
    }          
    $synchashWeak.Target.VLC_PlaybackCancel = $true
    if($synchashWeak.Target.AudioRecorder.isRecording){
      $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
      $Button_Settings.AffirmativeButtonText = 'Yes'
      $Button_Settings.NegativeButtonText = 'No'  
      $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
      $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchashWeak.Target.Window,"Stop Recording?","A recording for media $($synchashWeak.Target.AudioRecorder.RecordingMedia.title) is in progress, stopping will cancel the recording.`nAre you sure?",$okandCancel,$Button_Settings)
      if($result -eq 'Affirmative'){
        write-ezlogs "User wished to cancel recording process and stop media" -showtime -warning
        $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
        $Button_Settings.AffirmativeButtonText = 'Yes'
        $Button_Settings.NegativeButtonText = 'No'  
        $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::AffirmativeAndNegative 
        $result = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchashWeak.Target.Window,"Keep Partial Recording?","Do you wish to keep the partial recording?",$okandCancel,$Button_Settings)
        if($result -eq 'Affirmative'){
          write-ezlogs "User wished to keep partial recording" -showtime -warning
        }else{
          write-ezlogs "User did not wish to keep partial recording" -showtime -warning
          $synchashWeak.Target.AudioRecorder.Dispose = $true
        }
        $synchashWeak.Target.AudioRecorder.isRecording = $false
      }else{
        write-ezlogs "User did not wish to cancel recording process and stop media, aborting stop-media" -showtime -warning
        return
      }
    }
    Set-DiscordPresense -synchash $synchashWeak.Target -thisapp $thisApp -stop
    <#    try{
        $existing_Runspace = Stop-Runspace -thisApp $thisApp -runspace_name 'Spotify_Play_media' -force
        }catch{
        write-ezlogs " An exception occurred stopping existing runspace 'Spotify_Play_media'" -showtime -catcherror $_
    } #>
    if($synchashWeak.Target.systemmediaplayer.SystemMediaTransportControls.IsEnabled){
      write-ezlogs "| Setting SystemMediaTransportControls status to Stopped" -LogLevel 2
      $synchashWeak.Target.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus = 'Stopped'
      $synchashWeak.Target.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.ClearAll()
      $synchashWeak.Target.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Type = 'Music'
      $synchashWeak.Target.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.MusicProperties.artist = "$($thisApp.Config.App_name) Media Player"
      $file = New-StorageFile -path "$($thisApp.Config.Current_folder)\Resources\Samson_Icon_NoText1.png"
      $synchashWeak.Target.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Thumbnail = [Windows.Storage.Streams.RandomAccessStreamReference]::CreateFromFile($file)
      $synchashWeak.Target.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
    }
    if($synchashWeak.Target.PlayIcon1_Storyboard.Storyboard){
      Get-WPFAnimation -thisApp $thisApp -synchash $synchashWeak.Target -Action Stop
    }
    if($synchashWeak.Target.PlayButton_ToggleButton.isChecked){
      $synchashWeak.Target.PlayButton_ToggleButton.isChecked = $false
    }     
    if($synchashWeak.Target.WebPlayer_Playing_timer.isEnabled){
      $synchashWeak.Target.WebPlayer_Playing_timer.stop()
    } 
    if($UpdateQueue -and -not [string]::IsNullOrEmpty($synchashWeak.Target.Current_playing_media.id)){
      write-ezlogs "| Removing current_playing_media from queue with id: $($synchashWeak.Target.Current_playing_media.id)"
      Update-PlayQueue -Remove -ID $synchashWeak.Target.Current_playing_media.id -thisApp $thisApp -synchash $synchashWeak.Target -Use_RunSpace -UpdateHistory
    }
    $synchashWeak.Target.Current_playing_media = $Null
    $synchashWeak.Target.Current_playing_Media_Chapter = $Null
    $synchashWeak.Target.Current_Video_Quality = $Null
    $synchashWeak.Target.Current_Audio_Quality = $Null
    $synchashWeak.Target.Youtube_webplayer_current_Media = $Null
    $thisApp.Config.Current_Playing_Media = $null
    $synchashWeak.Target.Last_Played = ''
    if($synchashWeak.Target.VideoView_Play_Icon.kind){
      $synchashWeak.Target.VideoView_Play_Icon.kind = 'PlayCircleOutline'
    }
    <#    if($synchashWeak.Target.Media_Length_Label){
        $synchashWeak.Target.Media_Length_Label.text = "00:00:00"
    }#>
    if($synchashWeak.Target.DisplayPanel_VideoQuality_TextBlock){
      $synchashWeak.Target.DisplayPanel_VideoQuality_TextBlock.text = $Null
    }
    if($synchashWeak.Target.VideoView_Current_Length_TextBox){
      $synchashWeak.Target.VideoView_Current_Length_TextBox.text = ""
    }
    if($synchashWeak.Target.VideoView_Total_Length_TextBox){
      $synchashWeak.Target.VideoView_Total_Length_TextBox.text = ""
    }
    if($synchashWeak.Target.Media_Current_Length_TextBox){
      $synchashWeak.Target.Media_Current_Length_TextBox.DataContext = '00:00:00'
    }
    if($synchashWeak.Target.Media_Total_Length_TextBox){
      $synchashWeak.Target.Media_Total_Length_TextBox.DataContext = ''
    }
    if($synchashWeak.Target.MiniPlayer_Media_Length_Label){
      $synchashWeak.Target.MiniPlayer_Media_Length_Label.Content = "00:00:00"
    } 
    if(-not [string]::IsNullOrEmpty($synchashWeak.Target.Spotify_WebPlayer_State.playbackstate)){
      $synchashWeak.Target.Spotify_WebPlayer_State.playbackstate = 0
    }
    $synchashWeak.Target.streamlink = $Null
    $synchashWeak.Target.WebPlayer_State = $Null
    Add-VLCRegisteredEvents -synchash $synchashWeak.Target -thisApp $thisApp -UnregisterOnly
    if($synchashWeak.Target.vlc.IsPlaying -or $synchashWeak.Target.Vlc.state -match 'Paused' -and !$([string]$synchashWeak.Target.vlc.media.Mrl).StartsWith("dshow://")){
      write-ezlogs "| Disposing vlc.media and stopping playback" -Warning
      $synchashWeak.Target.vlc.media = $Null
      $synchashWeak.Target.VLC_IsPlaying_State = $false
      $synchashWeak.Target.VLC.stop()
      $current_track = $null
      <#      if((Get-Process streamlink*) -and !$thisApp.Config.Dev_mode){
          write-ezlogs ">>>> Closing Streamlink Processs" -loglevel 2
          Get-Process streamlink* | Stop-Process -Force
      }#>
    }
    if($synchashWeak.Target.Youtube_WebPlayer_title -and $synchashWeak.Target.Youtube_WebPlayer_URL){
      $synchashWeak.Target.Youtube_WebPlayer_URL = $null
      $synchashWeak.Target.Youtube_WebPlayer_title = $null     
    }
    #Set-YoutubeWebPlayerTimer -synchash $synchashWeak.Target -thisApp $thisApp -Stop
    if($synchashWeak.Target.Spotify_WebPlayer_title -and $synchashWeak.Target.Spotify_WebPlayer_URL){
      $synchashWeak.Target.Spotify_WebPlayer_URL = $null
      $synchashWeak.Target.Spotify_WebPlayer_title = $null     
    }
    #Set-SpotifyWebPlayerTimer -synchash $synchashWeak.Target -thisApp $thisApp -Stop

    if($thisApp.Config.Import_Spotify_Media -and (($thisapp.config.Spotify_WebPlayer -and $synchashWeak.Target.Spotify_WebPlayer_State.current_track.id) -or (Get-Process 'Spotify*'))){
      if($thisApp.Config.Use_Spicetify){
        $current_track = $synchashWeak.Target.Spicetify
      }else{
        $current_track = (Get-CurrentTrack -ApplicationName $thisapp.config.App_Name)
      }  
    }

    Reset-MainPlayer -synchash $synchashWeak.Target -thisApp $thisApp -SkipDiscord

    Set-ApplicationAudioDevice -thisApp $thisApp -synchash $synchashWeak.Target -stop

    if($synchashWeak.Target.vlc -is [System.IDisposable]){
      $null = $synchashWeak.Target.VLC.stop()
      $synchashWeak.Target.VLC_IsPlaying_State = $false
      write-ezlogs "| Disposing vlc" -Warning
      $synchashWeak.Target.vlc.dispose()
      $synchashWeak.Target.vlc = $Null
      if($synchashWeak.Target.VideoView.MediaPlayer -is [System.IDisposable]){
        write-ezlogs "| Disposing VideoView.MediaPlayer" -Warning
        $synchashWeak.Target.VideoView.MediaPlayer.Dispose()
        $synchashWeak.Target.VideoView.MediaPlayer = $Null
      }      
    }
    try{
      if($synchashWeak.Target.libvlc -is [System.IDisposable]){
        write-ezlogs "| Disposing Libvlc instance" -showtime -warning
        $synchashWeak.Target.libvlc.dispose()
        $synchashWeak.Target.libvlc = $Null
      }      
    }catch{
      write-ezlogs "An exception occurred An exception occurred Dispose libvlc" -showtime -catcherror $_
    }
    if($synchashWeak.Target.Equalizer -is [System.IDisposable]){
      write-ezlogs "| Disposing Equalizer" -Warning
      $synchashWeak.Target.Equalizer.Dispose()
      $synchashWeak.Target.Equalizer = $Null
    }
    if($StopMonitor -and $thisApp.Config.Enable_AudioMonitor){
      try{          
        Get-SpectrumAnalyzer -thisApp $thisApp -synchash $synchashWeak.Target -Action Begin
      }catch{
        write-ezlogs "An exception occurred in Get-SpectrumAnalyzer" -CatchError $_ -showtime
      }
    }          
    if($current_track.is_playing){
      if($thisApp.Config.Use_Spicetify){
        $device = $thisApp.Config.Use_Spicetify
      }else{
        $devices = Get-AvailableDevices -ApplicationName $thisapp.config.App_Name
        $device = $devices | Where-Object {$_.is_active -eq $true}
      }      
      if($device){
        write-ezlogs ">>>> Stoping Spotify playback" -showtime
        if($thisapp.config.Use_Spicetify){
          try{
            if((NETSTAT.EXE -an) | Where-Object {$_ -match '127.0.0.1:8974' -or $_ -match '0.0.0.0:8974'}){
              write-ezlogs "| Stopping Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime
              Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing
            }elseif($device.id){
              write-ezlogs 'PODE doesnt not seem to be running on 127.0.0.1:8974 - falling back to try Suspend-Playback' -showtime -warning
              Suspend-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $device.id
            }
          }catch{
            write-ezlogs "An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -catcherror $_ 
          }
        }else{
          write-ezlogs "Stopping Spotify playback with Suspend-Playback -ApplicationName $($thisapp.config.App_Name) -DeviceId $($device.id)" -showtime
          Suspend-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $device.id
        }          
      }  
    }
    $synchashWeak.Target.Spotify_Status = 'Stopped'
    
    #Disable ChatView
    Update-ChatView -synchash $synchashWeak.Target -thisApp $thisApp -Disable -Hide

    #Clear Any Temporary Media
    $synchashWeak.Target.Temporary_Playback_Media = $null

    #Refresh Playlists and Queue
    Get-Playlists -verboselog:$false -synchashWeak $synchashWeak -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -use_Runspace -Quick_Refresh
    Get-PlayQueue -verboselog:$false -synchashWeak $synchashWeak -thisApp $thisapp -use_Runspace

    #Reset Main UI controls to blank/default 
    if($synchashWeak.Target.PauseButton_ToggleButton.isChecked){
      $synchashWeak.Target.PauseButton_ToggleButton.isChecked = $false
    } 
    if($synchashWeak.Target.PlayButton_ToggleButton.Uid -eq 'IsPaused'){
      $synchashWeak.Target.PlayButton_ToggleButton.Uid = $null
    }
    if($synchashWeak.Target.MiniPlayButton_ToggleButton){
      $synchashWeak.Target.MiniPlayButton_ToggleButton.uid = $false
    }
    if($synchashWeak.Target.MediaPlayer_Slider){
      $synchashWeak.Target.MediaPlayer_Slider.value = 0
    }
    if($synchashWeak.Target.Main_TaskbarItemInfo -and $synchashWeak.Target.Main_TaskbarItemInfo.ProgressState -ne 'None'){
      $synchashWeak.Target.Main_TaskbarItemInfo.ProgressState = 'None'
    }
    if(-not [string]::IsNullOrEmpty($synchashWeak.Target.VideoView_ViewCount_Label.text)){
      $synchashWeak.Target.VideoView_ViewCount_Label.Visibility = 'Hidden'
      $synchashWeak.Target.VideoView_ViewCount_Label.text = $null
      $synchashWeak.Target.VideoView_Sep3_Label.Text = $Null
    }
    ######
    #TODO: Setting video view to visible here potentially contributes towards Layout measurement override crash if video view is currently collapsed
    #Mostly only occurs if miniplayer is open but can still occur even if not
    #Does not occur if video view is hidden. If collapsed, it basically sets the height/width to 0 (and any controls inside it, specifically airhack and those used to get around wpf airspace issues)
    #When its set to visible, various layout measurement events trigger but if the height and width is 0 (due to being collapsed) we get the crash
    #There some cases where video view may be collapsed on purpose (so it doesnt take up layout space like hidden does) and we still want to set back to visible so we need this check
    #See related code/comments for window closing event in Set-Avalondock
    #This likely needs a thorough refactor or rethinking to avoid this situation
    if($synchashWeak.Target.VideoView.Visibility -in 'Hidden','Collapsed'){
      $synchashWeak.Target.VideoView.Visibility = 'Visible'
    }
    ######
    if($synchashWeak.Target.MediaPlayer_Slider.isEnabled){
      $synchashWeak.Target.MediaPlayer_Slider.isEnabled = $false
    }
    if($synchashWeak.Target.MediaView_Image.Source){
      $synchashWeak.Target.MediaView_Image.Source = $null
    }
    if($synchashWeak.Target.Now_Playing_Label.Visibility -eq 'Visible'){
      $synchashWeak.Target.Now_Playing_Label.Visibility = 'Hidden'
    }
    if($synchashWeak.Target.Now_Playing_Label){
      $synchashWeak.Target.Now_Playing_Label.DataContext = "PLAYING"
    }
    if($synchashWeak.Target.Now_Playing_Title_Label){
      $synchashWeak.Target.Now_Playing_Title_Label.DataContext = ""
    }
    if($synchashWeak.Target.Now_Playing_Artist_Label){
      $synchashWeak.Target.Now_Playing_Artist_Label.DataContext = ""
    }
    if($synchashWeak.Target.DisplayPanel_Bitrate_TextBlock.text){
      $synchashWeak.Target.DisplayPanel_Bitrate_TextBlock.text = ""
    }
    if($synchashWeak.Target.DisplayPanel_Sep3_Label.Visibility -eq 'Visible'){
      $synchashWeak.Target.DisplayPanel_Sep3_Label.Visibility = 'Hidden' 
    }
    if($thisApp.Config.Enable_Subtitles){
      Update-Subtitles -synchash $synchashWeak.Target -thisApp $thisApp -clear
    }  
  }catch{
    write-ezlogs 'An exception occurred in Stop-Media' -showtime -catcherror $_
  }finally{
    [void][ScriptBlock].GetMethod('ClearScriptBlockCache', [System.Reflection.BindingFlags]'Static,NonPublic').Invoke($Null, $Null)
    if($stop_media_Measure){
      $stop_media_Measure.stop()
      write-ezlogs ">>>> Stop_Media_Measure" -showtime -loglevel 2 -Perf -PerfTimer $stop_media_Measure -GetMemoryUsage
      $stop_media_Measure = $Null   
    }
  }
}
#---------------------------------------------- 
#endregion Stop-Media Function
#----------------------------------------------
Export-ModuleMember -Function @('Stop-Media')