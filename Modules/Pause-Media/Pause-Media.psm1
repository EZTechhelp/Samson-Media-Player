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
    - Module designed for Samson Media Player

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
    [switch]$start_Paused,
    [switch]$Startup,
    [switch]$Update_MediaTransportControls,
    [switch]$Verboselog
  )
  try{ 
    if($thisApp.Config.Libvlc_Version -eq '4'){
      $libvlc_mediastate = ($synchash.vlc.state -and $synchash.vlc.state -notmatch 'Playing')
    }else{
      $libvlc_mediastate = ($synchash.vlc.media.state -and $synchash.vlc.media.state -notmatch 'Playing')
    }    
    if(($synchash.VLC.state -match 'Playing' -or $start_Paused) -and !$([string]$synchash.vlc.media.Mrl).StartsWith("dshow://")){
      write-ezlogs 'Pausing Vlc playback' -showtime -color cyan 
      $synchash.Now_Playing_Label.Visibility = 'Visible'
      $synchash.Now_Playing_Label.DataContext = ($synchash.Now_Playing_Label.DataContext) -replace 'PLAYING', 'PAUSED'
      #$stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\Material-PlayCircle.png")
      #$image =  [System.Drawing.Image]::FromStream($stream_image)
      #$Synchash.Menu_Pause.image = $image    
      #$Synchash.Menu_Pause.Text = 'Resume Playback'  
      if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled -and $Update_MediaTransportControls){
        $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus = 'Paused'
        $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
      }    
      if($synchash.PauseButton_ToggleButton){
        $synchash.PauseButton_ToggleButton.isChecked = $true
      }
      if($synchash.PlayButton_ToggleButton.Uid -ne 'IsPaused'){
        $synchash.PlayButton_ToggleButton.Uid = 'IsPaused'
      }
      if($synchash.MiniPlayButton_ToggleButton -and $synchash.MiniPlayButton_ToggleButton.Uid -ne 'IsPaused'){
        $synchash.MiniPlayButton_ToggleButton.uid = 'IsPaused'
      }
      if($synchash.PlayButton_ToggleButton.isChecked){
        $synchash.PlayButton_ToggleButton.isChecked = $false
      }
      $synchash.VideoView_Play_Icon.kind     = 'PlayCircleOutline'
      $synchash.VLC.pause()
      $synchash.Timer.stop()
      if($synchash.PlayIcon_PackIcon -and $synchash.TaskbarItem_PlayButton){
        $synchash.TaskbarItem_PlayButton.ImageSource = $synchash.PlayIcon_PackIcon
      }
      if($synchash.PlayQueue_TreeView.Items.id){
        $Current_playing_index = $synchash.PlayQueue_TreeView.Items.id.indexof($synchash.Current_playing_media.id)
        if($Current_playing_index -ne -1){
          $Current_playing = $synchash.PlayQueue_TreeView.Items[$Current_playing_index]
        }
        #$Current_playing = $synchash.PlayQueue_TreeView.Items.where({$_.id -eq $synchash.Current_playing_media.id}) | Select-Object -Unique
      }
      if($start_Paused){
        if($synchash.Current_playing_media -and ($synchash.Now_Playing_Title_Label.DataContext -in 'LOADING...','OPENING...','')){
          if($synchash.streamlink.title){
            if($synchash.streamlink.User_Name){
              $synchash.Now_Playing_Artist_Label.DataContext = "$($synchash.streamlink.User_Name)"
              $synchash.Now_Playing_Title_Label.DataContext  = "$($synchash.streamlink.title)"
            }else{
              $synchash.Now_Playing_Title_Label.DataContext  = "$($synchash.streamlink.User_Name): $($synchash.streamlink.title)"
              $synchash.Now_Playing_Artist_Label.DataContext = ""
            }
          }elseif($synchash.Current_playing_media.title){
            $synchash.Now_Playing_Title_Label.DataContext = "$($synchash.Current_playing_media.title)"
          } 
          if(-not [string]::IsNullOrEmpty($synchash.Current_playing_media.Bitrate) -and $synchash.DisplayPanel_VideoQuality_TextBlock){
            $synchash.DisplayPanel_VideoQuality_TextBlock.text = "$($synchash.Current_playing_media.Bitrate) Kbps"
          }elseif(-not [string]::IsNullOrEmpty($synchash.Current_Video_Quality) -and $synchash.DisplayPanel_VideoQuality_TextBlock -and $synchash.DisplayPanel_VideoQuality_TextBlock.text -ne $synchash.Current_Video_Quality){
            $synchash.DisplayPanel_VideoQuality_TextBlock.text = $synchash.Current_Video_Quality
          }elseif([string]::IsNullOrEmpty($synchash.Current_Video_Quality) -and $synchash.DisplayPanel_VideoQuality_TextBlock -and -not [string]::IsNullOrEmpty($synchash.DisplayPanel_VideoQuality_TextBlock.text)){
            $synchash.DisplayPanel_VideoQuality_TextBlock.text = $Null
          }
          <#          if(-not [string]::IsNullOrEmpty($synchash.Current_playing_media.Bitrate)){
              $synchash.DisplayPanel_Bitrate_TextBlock.text = "$($synchash.Current_playing_media.Bitrate) Kbps"
              $synchash.DisplayPanel_Sep3_Label.Visibility  = 'Visible'
              }else{
              $synchash.DisplayPanel_Bitrate_TextBlock.text = ""
              $synchash.DisplayPanel_Sep3_Label.Visibility  = 'Hidden'
          }#>
          #Chapters
          if($synchash.vlc.ChapterCount -gt 1){
            $currentChapter = $synchash.vlc.Chapter
            if($synchash.Current_playing_Media_Chapter -ne $currentChapter){
              $synchash.Current_playing_Media_Chapter = $currentChapter
              $currentChapter_description             = $synchash.vlc.ChapterDescription(0)| where {$_.id -eq $currentChapter}
              $newtitle                               = "$($synchash.Current_playing_media.title) | Chapter $currentChapter`: $($currentChapter_description.Name)"
              if($currentChapter_description.Name -and $synchash.Now_Playing_Title_Label.DataContext -ne $newtitle){
                $synchash.Now_Playing_Title_Label.DataContext = $newtitle
              }
            }
          } 
        }

        #Set Volume
        if(-not [string]::IsNullOrEmpty($thisapp.Config.Media_Volume) -and $synchash.vlc -and $synchash.vlc.Volume -ne $thisapp.Config.Media_Volume){
          write-ezlogs " | Setting vlc volume: $($thisapp.Config.Media_Volume)" -loglevel 2 -logtype Libvlc
          $synchash.Volume_Slider.value = $thisapp.Config.Media_Volume
          if($thisApp.Config.Libvlc_Version -eq '4'){
            $synchash.vlc.SetVolume($thisapp.Config.Media_Volume)
          }else{
            $synchash.vlc.Volume = $thisapp.Config.Media_Volume
          }
        }elseif(-not [string]::IsNullOrEmpty($synchash.Volume_Slider.value)){
          $thisapp.Config.Media_Volume = $synchash.Volume_Slider.value
          if($synchash.vlc -and $synchash.vlc.Volume -ne $synchash.Volume_Slider.value){
            write-ezlogs " | Setting vlc volume: $($synchash.Volume_Slider.value)" -loglevel 2 -logtype Libvlc
            if($thisApp.Config.Libvlc_Version -eq '4'){
              $synchash.vlc.SetVolume($synchash.Volume_Slider.value)
            }else{
              $synchash.vlc.Volume = $synchash.Volume_Slider.value
            }
          }         
        }else{
          write-ezlogs " | Volume level unknown??: $($synchash.Volume_Slider.value)" -loglevel 2 -Warning
          $thisapp.Config.Media_Volume = 100
        }
        if(-not [string]::IsNullOrEmpty($synchash.Current_playing_media.Current_Progress_Secs)){
          if($thisApp.Config.Libvlc_Version -eq '4'){
            $synchash.VLC.setTime($synchash.Current_playing_media.Current_Progress_Secs)
          }else{
            $synchash.VLC.Time = $synchash.Current_playing_media.Current_Progress_Secs
          }

          if(-not [string]::IsNullOrEmpty($synchash.Current_playing_media.Duration)){
            if($synchash.Current_playing_media.Duration -match '\:'){
              $total_Seconds = [timespan]::Parse($synchash.Current_playing_media.Duration).TotalSeconds
              [int]$hrs      = $($([timespan]::Parse($synchash.Current_playing_media.Duration)).Hours)
              [int]$mins     = $($([timespan]::Parse($synchash.Current_playing_media.Duration)).Minutes)
              [int]$secs     = $($([timespan]::Parse($synchash.Current_playing_media.Duration)).Seconds)
            }else{
              $total_Seconds = $([timespan]::FromMilliseconds($synchash.Current_playing_media.Duration)).TotalSeconds
              [int]$a        = $($synchash.Current_playing_media.Duration / 1000);
              [int]$c        = $($([timespan]::FromSeconds($a)).TotalMinutes)     
              [int]$hrs      = $($([timespan]::FromSeconds($a)).Hours)
              [int]$mins     = $($([timespan]::FromSeconds($a)).Minutes)
              [int]$secs     = $($([timespan]::FromSeconds($a)).Seconds)
              [int]$milsecs  = $($([timespan]::FromSeconds($a)).Milliseconds)
            }
            $synchash.MediaPlayer_TotalDuration   = $total_seconds             
            if($hrs -lt 1){
              $hrs = '0'
            }
            $total_time = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
            $synchash.MediaPlayer_CurrentDuration = $total_time
          }else{
            $total_time = $synchash.MediaPlayer_CurrentDuration       
          } 
          [int]$hrs  = $($([timespan]::FromMilliseconds($synchash.Current_playing_media.Current_Progress_Secs)).Hours)
          [int]$mins = $($([timespan]::FromMilliseconds($synchash.Current_playing_media.Current_Progress_Secs)).Minutes)
          [int]$secs = $($([timespan]::FromMilliseconds($synchash.Current_playing_media.Current_Progress_Secs)).Seconds)                        
          if($hrs -lt 1){
            $hrs = '0'
          }
          $current_length = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
          #$synchash.Media_Length_Label.text = $current_length + ' / ' +  "$($total_time)" 
          if($synchash.VideoView_Current_Length_TextBox){
            $synchash.VideoView_Current_Length_TextBox.text = $current_Length
          }
          if($synchash.VideoView_Total_Length_TextBox -and $synchash.VideoView_Total_Length_TextBox.text -ne $total_time){
            $synchash.VideoView_Total_Length_TextBox.text = $total_time
          }
          if($synchash.Media_Current_Length_TextBox){
            $synchash.Media_Current_Length_TextBox.DataContext = $current_Length
          }
          if($synchash.Media_Total_Length_TextBox -and $synchash.Media_Total_Length_TextBox.DataContext -ne $total_time){
            $synchash.Media_Total_Length_TextBox.DataContext = $total_time
          }
          if($synchash.MiniPlayer_Media_Length_Label){
            $synchash.MiniPlayer_Media_Length_Label.Content = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
          } 
        }  
        if(-not [string]::IsNullOrEmpty($synchash.MediaPlayer_TotalDuration) -and $synchash.MediaPlayer_TotalDuration -ne "0:0:0"){
          if(!$synchash.MediaPlayer_Slider.isEnabled){
            if($thisApp.Config.Verbose_logging){write-ezlogs " | Enabling MediaPlayer_slider" -showtime -color cyan}
            $synchash.MediaPlayer_Slider.isEnabled = $true
            #$synchash.VLC_Grid_Row3.Height="40"
          }
        }elseif($synchash.MediaPlayer_Slider.isEnabled){
          if($thisApp.Config.Verbose_logging){write-ezlogs " | Disabling MediaPlayer_slider" -showtime -color cyan}
          $synchash.MediaPlayer_Slider.isEnabled = $false
          #$synchash.VLC_Grid_Row3.Height="0"
        }  
        if($synchash.MediaPlayer_TotalDuration -and $synchash.MediaPlayer_Slider.Maximum -ne $synchash.MediaPlayer_TotalDuration){
          if($thisApp.Config.Verbose_logging){write-ezlogs " | Setting MediaPlayer_Slider max to $($synchash.MediaPlayer_TotalDuration)" -showtime -color cyan}
          $synchash.MediaPlayer_Slider.Maximum = $synchash.MediaPlayer_TotalDuration
        } 
        if($synchash.MediaPlayer_Slider.isEnabled){
          if($synchash.Main_TaskbarItemInfo.ProgressState -ne 'Normal'){
            $synchash.Main_TaskbarItemInfo.ProgressState = 'Normal'
          }
          if(!$synchash.MediaPlayer_Slider.IsMouseOver){
            $synchash.MediaPlayer_Slider.Value = $([timespan]::FromMilliseconds($synchash.Current_playing_media.Current_Progress_Secs)).TotalSeconds
            if($synchash.Main_TaskbarItemInfo.ProgressState -ne 'Normal'){
              $synchash.Main_TaskbarItemInfo.ProgressState = 'Normal'
            }
          }else{
            #$synchash.MediaPlayer_Slider.ToolTip = $synchash.Media_Length_Label.content
            $synchash.MediaPlayer_Slider.ToolTip = $current_length + ' / ' +  "$($total_time)" 
          }      
        }
        if($Current_playing -and $Current_playing.FontWeight -ne 'Bold'){             
          if(-not [string]::IsNullOrEmpty($Current_playing.title)){
            #$Current_playing.title = "---> $($Current_playing.title)"
            $Current_playing.FontWeight           = 'Bold'
            #$Current_playing.BorderBrush = 'LightGreen'
            #$Current_playing.BorderThickness = '1'
            $Current_playing.FontSize             = '16' 
            $Current_playing.FontStyle            = 'Italic'          
            if($synchash.AudioRecorder.isRecording){
              $current_playing.PlayIconRecord           = "RecordRec"
              $current_playing.PlayIconRecordVisibility = "Visible"
              $current_playing.PlayIconRecordRepeat     = "Forever"
              $current_playing.PlayIconVisibility       = "Hidden"
              $current_playing.PlayIconRepeat           = "1x"
            }else{
              #$current_playing.PlayIconRecord = ""            
              $current_playing.PlayIconRecordVisibility = "Hidden"
              $current_playing.PlayIconRecordRepeat     = "1x"
              if(!$thisApp.Config.Enable_Performance_Mode -and !$thisApp.Force_Performance_Mode){
                $current_playing.PlayIconRepeat = "Forever"
              }else{
                $current_playing.PlayIconRepeat = "1x"
              }
              $current_playing.PlayIconVisibility       = "Visible"
              $current_playing.PlayIcon                 = "CompactDiscSolid"
            }
            $synchash.PlayIcon.Source             = "$($thisApp.Config.Current_Folder)\Resources\Skins\CassetteWheelRight.png"
            $synchash.PlayIcon.Source.Freeze()
            $synchash.Playicon.Visibility         = "Visible"
            if($synchash.PlayIcon1_Storyboard.Storyboard){
              Get-WPFAnimation -thisApp $thisApp -synchash $synchash -Action Begin
            }
            $current_playing.PlayIconButtonHeight = "25"
            $current_playing.PlayIconButtonWidth  = "25"
            $current_playing.NumberVisibility     = "Hidden"
            $current_playing.NumberFontSize       = 0
            $current_playing.PlayIconEnabled      = $true
            if($thisApp.Config.Verbose_logging){write-ezlogs "Current : $($Current_playing | Select * | out-string)" -showtime}
          }elseif(-not [string]::IsNullOrEmpty($Current_playing.header)){
            #$Current_playing.Header = "---> $($Current_playing.Header)"
          }
          if($synchash.PlayQueue_TreeView.itemssource){
            $synchash.PlayQueue_TreeView.itemssource.refresh()
          }elseif($synchash.PlayQueue_TreeView.items){
            $synchash.PlayQueue_TreeView.items.refresh()
          }
          try{
            $synchash.Update_Playing_Playlist_Timer.tag = $Current_playing
            $synchash.Update_Playing_Playlist_Timer.start()          
          }catch{
            write-ezlogs "An exception occurred updating properties for current_playing $($current_playing | out-string)" -showtime -catcherror $_
          }          
        }
      }elseif($thisApp.Config.Remember_Playback_Progress -and $synchash.Current_playing_media){
        $thisApp.Config.Current_Playing_Media = $synchash.Current_playing_media
      }
      if($current_playing.PlayIconVisibility -eq 'Visible' -and $current_playing.PlayIconRepeat -eq 'Forever' -or ($current_playing.PlayIconRecordVisibility -eq "Visible" -and $current_playing.PlayIconRecordRepeat -eq 'Forever')){  
        #$Current_playing = $synchash.PlayQueue_TreeView.Items | where  {$_.id -eq $synchash.Current_playing_media.id} | select -Unique         
        $Current_playing.FontWeight       = 'Bold'
        #$Current_playing.FontSize = '16' 
        if($synchash.AudioRecorder.isRecording){
          $current_playing.PlayIconRecord           = "RecordRec"
          $current_playing.PlayIconRecordVisibility = "Visible"
          $current_playing.PlayIconRecordRepeat     = "1x"
          $current_playing.PlayIconVisibility       = "Hidden"
          $current_playing.PlayIconRepeat           = "1x"
        }else{
          #$current_playing.PlayIconRecord = ""
          $current_playing.PlayIconRecordVisibility = "Hidden"
          $current_playing.PlayIconRecordRepeat     = "1x"
          $current_playing.PlayIconRepeat           = "1x"
          $current_playing.PlayIconVisibility       = "Visible"
          $current_playing.PlayIcon                 = "CompactDiscSolid"
        }
        if($synchash.PlayIcon1_Storyboard.Storyboard){
          Get-WPFAnimation -thisApp $thisApp -synchash $synchash -Action Pause
        }
        $current_playing.NumberVisibility = "Hidden"
        $current_playing.NumberFontSize   = '0'
        #write-ezlogs ">>> Setting current playing queued item state to paused (Play icon: $($current_playing.PlayIconRepeat) | Visibility: ($($current_playing.PlayIconVisibility))" -showtime
        if($synchash.Playlists_TreeView.Nodes.ChildNodes.Content.id){
          $current_Playing_Playlist = ($synchash.Playlists_TreeView.Nodes | where {$_.ChildNodes.Content.id -eq $synchash.Current_playing_media.id}).Content | select -Unique 
        }elseif($synchash.Playlists_TreeView.Itemssource.sourcecollection.items){
          $current_Playing_Playlist = $synchash.Playlists_TreeView.Itemssource.sourcecollection.items | where {$_.id -eq $synchash.Current_playing_media.id} | select -Unique
        }
        foreach($playlist in $current_Playing_Playlist){ 
          if($synchash.AudioRecorder.isRecording -and $playlist.PlayIconRecord){
            $playlist.PlayIconRecord           = "RecordRec"
            $playlist.PlayIconRecordVisibility = "Visible"
            $playlist.PlayIconRecordRepeat     = "1x"
            $playlist.PlayIconVisibility       = "Hidden"
            $playlist.PlayIconRepeat           = "1x"
          }elseif($playlist.PlayIconRecordVisibility){
            $playlist.PlayIconRecordVisibility = "Hidden"
            $playlist.PlayIconRecordRepeat     = "1x"
            $playlist.PlayIconRepeat           = "1x"
            $playlist.PlayIconVisibility       = "Visible"
            $playlist.PlayIcon                 = "CompactDiscSolid"
          }
        }
        if($synchash.Playlists_TreeView.items.NeedsRefresh){
          $Null = $synchash.Playlists_TreeView.items.refresh()
        }
        if($synchash.PlayQueue_TreeView.itemssource){
          $synchash.PlayQueue_TreeView.itemssource.refresh()
        }elseif($synchash.PlayQueue_TreeView.items){
          $synchash.PlayQueue_TreeView.items.refresh()
        }
      }        
      return  
    }elseif(($synchash.VLC.state -match 'Paused' -or $synchash.VLC.state -match 'NothingSpecial' -or (($synchash.vlc.Media.State -eq 'Stopped' -or $synchash.VLC.state -eq 'Stopped') -and ($synchash.vlc.Media.IsParsed -or $synchash.vlc.Media.ParsedStatus -eq 'Done') -and -not [string]::IsNullOrEmpty($synchash.Current_playing_media.id) -and $synchash.Current_playing_media.Source -eq 'Local' -and $thisApp.Config.Remember_Playback_Progress)) -and ($libvlc_mediastate) -and !$([string]$synchash.vlc.media.Mrl).StartsWith("dshow://")){
      #$current_track = (Get-CurrentTrack -ApplicationName $thisapp.config.App_Name) 
      write-ezlogs 'Resuming Vlc playback' -showtime -color cyan 
      $synchash.Now_Playing_Label.Visibility = 'Visible'
      $synchash.Now_Playing_Label.DataContext = ($synchash.Now_Playing_Label.DataContext) -replace 'PAUSED', 'PLAYING'
      if($synchash.VLC.Time -ne -1){
        $currenttime = $synchash.VLC.Time
      }else{
        $currenttime = $synchash.MediaPlayer_Slider.Value * 1000
      }     
      $synchash.VLC.Play()
      if($synchash.VLC.time -ne $currenttime){
        if($thisApp.Config.Libvlc_Version -eq '4'){
          $synchash.VLC.setTime($currenttime)
        }else{
          $synchash.VLC.time = $currenttime
        }
      }
      #Set Volume
      if(-not [string]::IsNullOrEmpty($thisapp.Config.Media_Volume) -and $synchash.vlc -and $synchash.vlc.Volume -ne $thisapp.Config.Media_Volume){
        write-ezlogs " | Setting vlc volume: $($thisapp.Config.Media_Volume)" -loglevel 2 -logtype Libvlc
        $synchash.Volume_Slider.value = $thisapp.Config.Media_Volume
        if($thisApp.Config.Libvlc_Version -eq '4'){
          $synchash.vlc.SetVolume($thisapp.Config.Media_Volume)
        }else{
          $synchash.vlc.Volume = $thisapp.Config.Media_Volume
        }
      }elseif(-not [string]::IsNullOrEmpty($synchash.Volume_Slider.value)){
        $thisapp.Config.Media_Volume = $synchash.Volume_Slider.value
        if($synchash.vlc -and $synchash.vlc.Volume -ne $synchash.Volume_Slider.value){
          write-ezlogs " | Setting vlc volume: $($synchash.Volume_Slider.value)" -loglevel 2 -logtype Libvlc
          if($thisApp.Config.Libvlc_Version -eq '4'){
            $synchash.vlc.SetVolume($synchash.Volume_Slider.value)
          }else{
            $synchash.vlc.Volume = $synchash.Volume_Slider.value
          }
        }         
      }else{
        write-ezlogs " | Volume level unknown??: $($synchash.Volume_Slider.value)" -loglevel 2 -Warning
        $thisapp.Config.Media_Volume = 100
      }  
             
      <#      if($synchash.vlc -and $synchash.vlc.Volume -ne $synchash.Volume_Slider.value){
          write-ezlogs " | Setting vlc volume: $($synchash.Volume_Slider.value)" -loglevel 2 -logtype Libvlc
          if($thisApp.Config.Libvlc_Version -eq '4'){
          $synchash.vlc.SetVolume($synchash.Volume_Slider.value)
          }else{
          $synchash.vlc.Volume = $synchash.Volume_Slider.value
          }
      }#>
      #$thisapp.Config.Media_Volume = $synchash.vlc.Volume
      if($synchash.Volume_Slider.value -ge 75){
        $synchash.VideoView_Mute_Icon.kind = 'VolumeHigh'
      }elseif($synchash.Volume_Slider.value -gt 25 -and $synchash.Volume_Slider.value -lt 75){
        $synchash.VideoView_Mute_Icon.kind = 'VolumeMedium'
      }elseif($synchash.Volume_Slider.value -le 25 -and $synchash.Volume_Slider.value -gt 0){
        $synchash.VideoView_Mute_Icon.kind = 'VolumeLow'
      }elseif($synchash.Volume_Slider.value -le 0){
        $synchash.VideoView_Mute_Icon.kind = 'Volumeoff'
      }        
      #$stream_image = [System.IO.File]::OpenRead("$($thisApp.Config.current_folder)\\Resources\\Material-PauseCircle.png")
      #$image =  [System.Drawing.Image]::FromStream($stream_image)
      #$Synchash.Menu_Pause.image = $image
      #$Synchash.Menu_Pause.Text = 'Pause Playback'
      if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled -and $Update_MediaTransportControls){
        $synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus = 'Playing'
        $synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
      }
      if($synchash.PauseButton_ToggleButton.isChecked){
        $synchash.PauseButton_ToggleButton.isChecked = $false
      }
      if($synchash.PlayButton_ToggleButton.Uid -eq 'IsPaused'){
        $synchash.PlayButton_ToggleButton.Uid = $Null
      }
      if($synchash.MiniPlayButton_ToggleButton.Uid -eq 'IsPaused'){
        $synchash.MiniPlayButton_ToggleButton.uid = $Null
      }
      if($synchash.PlayButton_ToggleButton){
        $synchash.PlayButton_ToggleButton.isChecked = $true
      }             
      $synchash.VideoView_Play_Icon.kind  = 'PauseCircleOutline'      
      if($synchash.PauseIcon_PackIcon -and $synchash.TaskbarItem_PlayButton){
        $synchash.TaskbarItem_PlayButton.ImageSource = $synchash.PauseIcon_PackIcon
      }
      <#      if($synchash.chat_WebView2 -and $synchash.chat_WebView2.Visibility -ne 'Hidden'){
          $synchash.chat_WebView2.Reload()
      }#>      
      $Current_playing                       = $synchash.PlayQueue_TreeView.Items | where  {$_.id -eq $synchash.Current_playing_media.id} | select -Unique 
      if($current_playing.PlayIconRepeat -eq '1x' -or ($current_playing.PlayIconRecordRepeat -eq '1x' -and $synchash.AudioRecorder.isRecording)){
        #Get-Playlists -verboselog:$false -synchash $synchash -thisApp $thisapp -all_playlists $all_playlists  
        $Current_playing                  = $synchash.PlayQueue_TreeView.Items | where  {$_.id -eq $synchash.Current_playing_media.id} | select -Unique         
        $Current_playing.FontWeight       = 'Bold'
        #$Current_playing.FontSize = '16' 
        if($synchash.AudioRecorder.isRecording){
          $current_playing.PlayIconRecord           = "RecordRec"
          $current_playing.PlayIconRecordVisibility = "Visible"
          $current_playing.PlayIconRecordRepeat     = "Forever"
          $current_playing.PlayIconVisibility       = "Hidden"
          $current_playing.PlayIconRepeat           = "1x"
        }else{
          #$current_playing.PlayIconRecord = ""
          $current_playing.PlayIconRecordVisibility = "Hidden"
          $current_playing.PlayIconRecordRepeat     = "1x"
          if(!$thisApp.Config.Enable_Performance_Mode -and !$thisApp.Force_Performance_Mode){
            $current_playing.PlayIconRepeat = "Forever"
          }          
          $current_playing.PlayIconVisibility       = "Visible"
          $current_playing.PlayIcon                 = "CompactDiscSolid"
        }
        if($synchash.PlayIcon1_Storyboard.Storyboard){
          Get-WPFAnimation -thisApp $thisApp -synchash $synchash -Action Resume
        }
        $current_playing.NumberVisibility = "Hidden"
        $current_playing.NumberFontSize   = '0'
        $current_playing.PlayIconEnabled  = $true  
        if($synchash.PlayQueue_TreeView.itemssource){
          $synchash.PlayQueue_TreeView.itemssource.refresh()
        }elseif($synchash.PlayQueue_TreeView.items){
          $synchash.PlayQueue_TreeView.items.refresh()
        }
        if($synchash.Playlists_TreeView.Nodes.ChildNodes.Content.id){
          $current_Playing_Playlist = ($synchash.Playlists_TreeView.Nodes | where {$_.ChildNodes.Content.id -eq $synchash.Current_playing_media.id}).Content | select -Unique
        }elseif($synchash.Playlists_TreeView.Itemssource.sourcecollection.items){
          $current_Playing_Playlist = $synchash.Playlists_TreeView.Itemssource.sourcecollection.items | where {$_.id -eq $synchash.Current_playing_media.id} | select -Unique 
        }
        if($current_Playing_Playlist){
          foreach($playlist in $current_Playing_Playlist){
            if($synchash.AudioRecorder.isRecording -and $playlist.PlayIconRecord){
              $playlist.PlayIconRecord           = "RecordRec"
              $playlist.PlayIconRecordVisibility = "Visible"
              $playlist.PlayIconRecordRepeat     = "Forever"
              $playlist.PlayIconVisibility       = "Hidden"
              $playlist.PlayIconRepeat           = "1x"
            }elseif($playlist.PlayIconRecord){
              #$playlist.PlayIconRecord = ""
              $playlist.PlayIconRecordVisibility = "Hidden"
              $playlist.PlayIconRecordRepeat     = "1x"
              if(!$thisApp.Config.Enable_Performance_Mode -and !$thisApp.Force_Performance_Mode){
                $playlist.PlayIconRepeat = "Forever"
              }
              $playlist.PlayIconVisibility       = "Visible"
              $playlist.PlayIcon                 = "CompactDiscSolid"
            }
          }
        }
      }
      if($synchash.Timer){
        $Null = $synchash.Timer.Start()  
      }              
      return
    }elseif($synchash.WebPlayer_State -ne 0 -and $synchash.Youtube_WebPlayer_title){
      write-ezlogs ">>>> Toggling pause of Youtube Webplayer video" -showtime
      if($thisApp.Config.Use_invidious -or $synchash.Youtube_WebPlayer_URL -match 'yewtu.be|invidious'){
        $synchash.YoutubeWebView2_PauseScript = @"
try {
  var state = player.paused();
if (state) {
  console.log('Resuming');
  player.play();
} else {
   console.log('Pausing');
   player.pause();
}
} catch (error) {
  console.error('An exception occurred toggling player', error);
  var ErrorObject =
  {
    Key: 'Error',
    Value: Error
  };
  window.chrome.webview.postMessage(ErrorObject);
}

"@             
        $synchash.YoutubeWebView2.ExecuteScriptAsync($synchash.YoutubeWebView2_PauseScript)
      }else{
        $synchash.YoutubeWebView2_PauseScript = @"
try {
  var player = document.getElementById('movie_player');
  var state = player.getPlayerState();
if (state == 2) {
  console.log('Resuming');
  player.playVideo();
} else if (state == 1) {
   console.log('Pausing');
   player.pauseVideo();
}
} catch (error) {
  console.error('An exception occurred toggling player', error);
  var ErrorObject =
  {
    Key: 'Error',
    Value: Error
  };
  window.chrome.webview.postMessage(ErrorObject);
}

"@             
        $synchash.YoutubeWebView2.ExecuteScriptAsync($synchash.YoutubeWebView2_PauseScript)
      }          
    }elseif($synchash.Spotify_WebPlayer_title -and $thisApp.Config.Spotify_WebPlayer){
      if($synchash.Spotify_WebPlayer_State){
        $synchash.Spotify_Webview2_PauseScript = @"
try {
  console.log('Pausing/Resuming Spotify Playback');
  SpotifyWeb.player.togglePlay();
} catch (error) {
  console.error('An exception occurred toggling Spotify player', error);
  var ErrorObject =
  {
    Key: 'Error',
    Value: Error
  };
  window.chrome.webview.postMessage(ErrorObject);
}

"@
        write-ezlogs ">>>> Toggling pause of Spotify Webplayer" -showtime
        $synchash.WebView2.ExecuteScriptAsync($synchash.Spotify_Webview2_PauseScript)
      }                        
    }elseif($thisapp.Config.Import_Spotify_Media -and -not [string]::IsNullOrEmpty($synchash.Spotify_Status) -and $synchash.Spotify_Status -ne 'Stopped'){ 
      write-ezlogs ">>>> Checking Spotify Current Track Status: $($synchash.Spotify_Status)" -showtime     
      if($thisApp.Config.Use_Spicetify){
        $current_track = $synchash.Spicetify
      }else{
        $current_track = (Get-CurrentTrack -ApplicationName $thisapp.config.App_Name)
      }     
    }else{
      write-ezlogs "No media found to pause or resume" -loglevel 2
      if($synchash.PlayButton_ToggleButton.isChecked){
        $synchash.PlayButton_ToggleButton.isChecked = $false
      } 
      if($synchash.PlayButton_ToggleButton.Uid -eq 'IsPaused'){
        $synchash.PlayButton_ToggleButton.Uid = $null
      } 
      if($synchash.MiniPlayButton_ToggleButton.Uid -eq 'IsPaused'){
        $synchash.MiniPlayButton_ToggleButton.uid = $null
      }         
    }        
    if(($current_track.is_playing -or $synchash.Spotify_Status -eq 'Playing') -and $synchash.Spotify_Status -ne 'Paused'){     
      if($thisApp.Config.Use_Spicetify){
        $device = $thisApp.Config.Use_Spicetify
      }else{
        $devices = Get-AvailableDevices -ApplicationName $thisapp.config.App_Name
        $device  = $devices | where {$_.is_active -eq $true}
      }
      if($device){
        write-ezlogs 'Pausing Spotify playback' -showtime -color cyan 
        if($synchash.PauseButton_ToggleButton){
          $synchash.PauseButton_ToggleButton.isChecked = $true
        } 
        if($synchash.PlayButton_ToggleButton.Uid -ne 'IsPaused'){
          $synchash.PlayButton_ToggleButton.Uid = 'IsPaused'
        } 
        if($synchash.MiniPlayButton_ToggleButton -and $synchash.MiniPlayButton_ToggleButton.Uid -ne 'IsPaused'){
          $synchash.MiniPlayButton_ToggleButton.uid = 'IsPaused'
        }                             
        if($synchash.PlayButton_ToggleButton.isChecked){
          $synchash.PlayButton_ToggleButton.isChecked = $false
        }
        $synchash.VideoView_Play_Icon.kind  = 'PlayCircleOutline'
        if($synchash.PlayIcon_PackIcon -and $synchash.TaskbarItem_PlayButton){
          $synchash.TaskbarItem_PlayButton.ImageSource = $synchash.PlayIcon_PackIcon
        }
        $synchash.Timer.stop()
        $synchash.Spotify_Status            = 'Paused'
        if($thisapp.config.Use_Spicetify){
          try{
            if((NETSTAT.EXE -an) | where {$_ -match '127.0.0.1:8974' -or $_ -match '0.0.0.0:8974'}){
              write-ezlogs "[Pause_media] Pausing Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -color cyan
              Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing 
            }elseif($device.id){
              write-ezlogs '[Pause_media] PODE does not seem to be running on 127.0.0.1:8974 -- attempting fallback to Suspend-Playback' -showtime -warning
              Suspend-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $device.id
            } 
          }catch{
            write-ezlogs "[Pause_media] An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE' -- attempting Suspend-Playback" -showtime -catcherror $_ 
            #Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $device.id            
          }
        }else{
          write-ezlogs "[Pause_media] Stopping Spotify playback with Suspend-Playback -ApplicationName $($thisapp.config.App_Name) -DeviceId $($device.id)" -showtime -color cyan
          Suspend-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $device.id
        }
        if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled -and $Update_MediaTransportControls){
          #$synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus = 'Paused'
          #$synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
        }
        $synchash.Now_Playing_Label.DataContext = ($synchash.Now_Playing_Label.DataContext) -replace 'PLAYING', 'PAUSED'         
        $Current_playing  = $synchash.PlayQueue_TreeView.Items | where {$_.id -eq $synchash.Current_playing_media.id} | select -Unique       
        if($current_playing.PlayIconVisibility -eq 'Visible' -and $current_playing.PlayIconRepeat -eq 'Forever' -or ($current_playing.PlayIconRecordVisibility -eq "Visible" -and $current_playing.PlayIconRecordRepeat -eq 'Forever')){         
          $Current_playing.FontWeight       = 'Bold'
          #$Current_playing.FontSize = '16' 
          if($synchash.AudioRecorder.isRecording){
            $current_playing.PlayIconRecord           = "RecordRec"
            $current_playing.PlayIconRecordVisibility = "Visible"
            $current_playing.PlayIconRecordRepeat     = "1x"
            $current_playing.PlayIconVisibility       = "Hidden"
            $current_playing.PlayIconRepeat           = "1x"
          }else{
            $current_playing.PlayIconRecord           = ""
            $current_playing.PlayIconRecordVisibility = "Hidden"
            $current_playing.PlayIconRecordRepeat     = "1x"
            $current_playing.PlayIconRepeat           = "1x"
            $current_playing.PlayIconVisibility       = "Visible"
            $current_playing.PlayIcon                 = "CompactDiscSolid"
          }
          if($synchash.PlayIcon1_Storyboard.Storyboard){
            Get-WPFAnimation -thisApp $thisApp -synchash $synchash -Action Pause
          }
          $current_playing.NumberVisibility = "Hidden"
          $current_playing.NumberFontSize   = '0'
          if($synchash.PlayQueue_TreeView.itemssource){
            $synchash.PlayQueue_TreeView.itemssource.refresh()
          }elseif($synchash.PlayQueue_TreeView.items){
            $synchash.PlayQueue_TreeView.items.refresh()
          }
          try{
            $synchash.Update_Playing_Playlist_Timer.tag = $Current_playing
            $synchash.Update_Playing_Playlist_Timer.start()             
          }catch{
            write-ezlogs "An exception occurred updating properties for current_playing $($current_playing | out-string)" -showtime -catcherror $_
          }
        }                       
      } 
      return 
    }elseif($current_track.currently_playing_type -ne $null -or $current_track.is_paused -or $synchash.Spotify_Status -eq 'Paused'){
      if($thisApp.Config.Use_Spicetify){
        $device = $thisApp.Config.Use_Spicetify
      }else{
        $devices = Get-AvailableDevices -ApplicationName $thisapp.config.App_Name
        $device  = $devices | where {$_.is_active -eq $true}
      }
      if($synchash.PauseButton_ToggleButton.isChecked){
        $synchash.PauseButton_ToggleButton.isChecked = $false
      }
      if($synchash.PlayButton_ToggleButton.Uid -eq 'IsPaused'){
        $synchash.PlayButton_ToggleButton.Uid = $null
      } 
      if($synchash.MiniPlayButton_ToggleButton.Uid -eq 'IsPaused'){
        $synchash.MiniPlayButton_ToggleButton.uid = $null
      }            
      if($synchash.PlayButton_ToggleButton){
        $synchash.PlayButton_ToggleButton.isChecked = $true
      }          
      $synchash.Spotify_Status            = 'Playing'
      $synchash.VideoView_Play_Icon.kind  = 'PauseCircleOutline'
      if($synchash.PauseIcon_PackIcon -and $synchash.TaskbarItem_PlayButton){
        $synchash.TaskbarItem_PlayButton.ImageSource = $synchash.PauseIcon_PackIcon
      }
      if($thisapp.config.Use_Spicetify){
        try{
          if((NETSTAT.EXE -n) | where {$_ -match '127.0.0.1:8974' -or $_ -match '0.0.0.0:8974'}){
            write-ezlogs "[Pause_media] Resuming Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PLAY'" -showtime -color cyan
            Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PLAY' -UseBasicParsing 
          }elseif($device.id){
            write-ezlogs '[Pause_media] PODE does not seem to be running on 127.0.0.1:8974 -- attempting fallback to Resume-Playback' -showtime -warning
            Resume-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $device.id
          }        
        }catch{
          write-ezlogs "[Pause_media] An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PLAY' -- attempting Resume-Playback" -showtime -catcherror $_   
          #Resume-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $device.id         
        }
      }else{
        write-ezlogs "[Pause_media] Resuming Spotify playback with Resume-Playback -ApplicationName $($thisapp.config.App_Name) -DeviceId $($device.id)" -showtime -color cyan
        Resume-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $device.id      
      } 
      if($synchash.systemmediaplayer.SystemMediaTransportControls.IsEnabled -and $Update_MediaTransportControls){
        #$synchash.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus = 'Playing'
        #$synchash.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
      }
      $synchash.Now_Playing_Label.DataContext = ($synchash.Now_Playing_Label.DataContext) -replace 'PAUSED', 'PLAYING'
      $Current_playing                    = $synchash.PlayQueue_TreeView.Items | where  {$_.id -eq $synchash.Current_playing_media.id} | select -Unique 
      if($current_playing.PlayIconRepeat -eq '1x' -or ($current_playing.PlayIconRecordRepeat -eq '1x' -and $synchash.AudioRecorder.isRecording)){
        #Get-Playlists -verboselog:$false -synchash $synchash -thisApp $thisapp -all_playlists $all_playlists  
        $Current_playing                  = $synchash.PlayQueue_TreeView.Items | where  {$_.id -eq $synchash.Current_playing_media.id} | select -Unique         
        $Current_playing.FontWeight       = 'Bold'
        #$Current_playing.FontSize = '16' 
        if($synchash.AudioRecorder.isRecording){
          $current_playing.PlayIconRecord           = "RecordRec"
          $current_playing.PlayIconRecordVisibility = "Visible"
          $current_playing.PlayIconRecordRepeat     = "Forever"
          $current_playing.PlayIconVisibility       = "Hidden"
          $current_playing.PlayIconRepeat           = "1x"
        }else{
          $current_playing.PlayIconRecord           = ""
          $current_playing.PlayIconRecordVisibility = "Hidden"
          $current_playing.PlayIconRecordRepeat     = "1x"
          if(!$thisApp.Config.Enable_Performance_Mode -and !$thisApp.Force_Performance_Mode){
            $current_playing.PlayIconRepeat = "Forever"
            $current_playing.PlayIconEnabled  = $true
          }else{
            write-ezlogs "| Performance_Mode enabled - Disabling playicon animation" -Warning -Dev_mode
            $current_playing.PlayIconRepeat = "1x"
            $current_playing.PlayIconEnabled  = $false
          }          
          $current_playing.PlayIconVisibility       = "Visible"
          $current_playing.PlayIcon                 = "CompactDiscSolid"
        }
        if($synchash.PlayIcon1_Storyboard.Storyboard){
          Get-WPFAnimation -thisApp $thisApp -synchash $synchash -Action Resume
        }
        $current_playing.NumberVisibility = "Hidden"
        $current_playing.NumberFontSize   = '0'
          
        if($synchash.PlayQueue_TreeView.itemssource){
          $synchash.PlayQueue_TreeView.itemssource.refresh()
        }elseif($synchash.PlayQueue_TreeView.items){
          $synchash.PlayQueue_TreeView.items.refresh()
        }
        try{
          $synchash.Update_Playing_Playlist_Timer.tag = $Current_playing
          $synchash.Update_Playing_Playlist_Timer.start()             
        }catch{
          write-ezlogs "An exception occurred updating properties for current_playing $($current_playing | out-string)" -showtime -catcherror $_
        }
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