<#
    .Name
    Update-MediaTimer

    .Version 
    0.1.0

    .SYNOPSIS
    Provides progress monitoring, UI/Playlist updates and tracks media during playback. Executes under a dispatcher timer

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
#region Update-MediaTimer Function
#----------------------------------------------
function Update-MediaTimer{

  param (
    $synchashWeak,
    $thisApp,
    [switch]$Show_notification,
    [switch]$Verboselog
  )
  try{
    if($synchashWeak.Target.Timer.isEnabled -and (!$([string]$synchashWeak.Target.vlc.media.Mrl).StartsWith("dshow://") -or ($thisApp.Config.Use_Spicetify -and ($synchashWeak.Target.Spicetify.is_playing -or $synchashWeak.Target.Spicetify.is_paused))) -and !$([string]$synchashWeak.Target.vlc.media.Mrl).StartsWith("imem://")){
      $timer_maxretry = 0
      if($thisApp.Config.Log_Level -ge 3){
        $Media_Timer_Measure = [system.diagnostics.stopwatch]::StartNew()
      }
      $Current_playlist_items = $synchashWeak.Target.PlayQueue_TreeView.Items 
      if($Current_playlist_items){
        $queue_index = $Current_playlist_items.id.indexof($synchashWeak.Target.Current_playing_media.id)
        if($queue_index -ne -1){
          $Current_playing = $Current_playlist_items[$queue_index]
        }else{
          $Current_playing = $Current_playlist_items.where({$_.id -eq $synchashWeak.Target.Current_playing_media.id}) | select -Unique
        }
      }      
      if(!$Current_playing){
        #write-ezlogs "Couldnt find current playing media using id (Title: $($synchashWeak.Target.Current_playing_media.title) | ID: $($synchashWeak.Target.Current_playing_media.id)" -showtime -warning
        $Current_playing = $Current_playlist_items | where {$_.tag.Media.id -eq $synchashWeak.Target.Current_playing_media.id} | select -Unique
      }     
      if($synchashWeak.Target.VideoView_Mute_Icon){
        if(($synchashWeak.Target.vlc.mute -or $synchashWeak.Target.vlc.Volume -le 0)){
          if($synchashWeak.Target.VideoView_Mute_Icon.kind -ne 'Volumeoff'){
            $synchashWeak.Target.VideoView_Mute_Icon.kind = 'Volumeoff'
          }
        }elseif($synchashWeak.Target.vlc.Volume -ge 75){
          if($synchashWeak.Target.VideoView_Mute_Icon.kind -ne 'VolumeHigh'){
            $synchashWeak.Target.VideoView_Mute_Icon.kind = 'VolumeHigh'
          }
        }elseif($synchashWeak.Target.vlc.Volume -gt 25 -and $synchashWeak.Target.vlc.Volume -lt 75){
          if($synchashWeak.Target.VideoView_Mute_Icon.kind -ne 'VolumeMedium'){
            $synchashWeak.Target.VideoView_Mute_Icon.kind = 'VolumeMedium'
          }
        }elseif($synchashWeak.Target.vlc.Volume -le 25 -and $synchashWeak.Target.vlc.Volume -gt 0){
          if($synchashWeak.Target.VideoView_Mute_Icon.kind -ne 'VolumeLow'){
            $synchashWeak.Target.VideoView_Mute_Icon.kind = 'VolumeLow'
          }
        }
      }
      if($Current_playing){
        $synchashWeak.Target.Last_Played = $synchashWeak.Target.Current_playing_media.id
      }
      if(!$Current_playing -and $timer_maxretry -lt 25){    
        try{
          $timer_maxretry++
          $Current_playlist_items = $synchashWeak.Target.PlayQueue_TreeView.Items  
          if($Current_playlist_items){
            $queue_index = $Current_playlist_items.id.indexof($synchashWeak.Target.Current_playing_media.id)
            if($queue_index -ne -1){
              $Current_playing = $Current_playlist_items[$queue_index]
            }else{
              $Current_playing = $Current_playlist_items.where({$_.id -eq $synchashWeak.Target.Current_playing_media.id}) | select -Unique
            }            
          }                               
          if(!$Current_playing){
            write-ezlogs "| Couldnt get current playing item with id $($synchashWeak.Target.Current_playing_media.id) from queue! Executing Get-PlayQueue" -showtime -warning  
            if($thisapp.config.Current_Playlist.values -notcontains $synchashWeak.Target.Current_playing_media.id){
              write-ezlogs "| Item does not seem to be in the queue | Adding $($synchashWeak.Target.Current_playing_media.id) to Play Queue" -showtime -warning
              Update-PlayQueue -synchash $synchashWeak.Target -thisApp $thisApp -Add -ID $synchashWeak.Target.Current_playing_media.id -RefreshQueue  
            }else{
              write-ezlogs "| Play queue already contains $($synchashWeak.Target.Current_playing_media.id), refreshing" -showtime -warning
              Get-PlayQueue -verboselog:$false -synchashWeak $synchashWeak -thisApp $thisapp -use_Runspace 
            }                       
            $Current_playlist_items = $synchashWeak.Target.PlayQueue_TreeView.Items  
            if($Current_playlist_items){
              $queue_index = $Current_playlist_items.id.indexof($synchashWeak.Target.Current_playing_media.id)
              if($queue_index -ne -1){
                $Current_playing = $Current_playlist_items[$queue_index]
              }else{
                $Current_playing = $Current_playlist_items.where({$_.id -eq $synchashWeak.Target.Current_playing_media.id}) | select -Unique
              }            
            }   
            if(!$Current_playing){
              write-ezlogs "| Still couldnt find (Title: $($synchashWeak.Target.Current_playing_media.title) | ID: $($synchashWeak.Target.Current_playing_media.id)) in the play queue, looping!" -showtime -warning
              return
            }else{
              write-ezlogs '| Found current playing item after adding it to the play queue and refreshing Get-PlayQueue!' -showtime -warning
            }                      
          }else{
            write-ezlogs '| Found current playing item after refreshing Get-PlayQueue' -showtime
          }   
        }catch{
          write-ezlogs "An exception occurred in Tick_Timer while trying to update/get current playing items" -showtime -catcherror $_
        }  
      }elseif($timer_maxretry -ge 25){
        write-ezlogs "[ERROR] | Timed out trying to find current playing item $($synchashWeak.Target.Current_playing_media.id) in the play queue, aborting!" -showtime
        Update-Notifications -id 1 -Level 'ERROR' -Message "Timed out trying to find $($synchashWeak.Target.Current_playing_media.id) in the play queue, aborting progress timer!" -VerboseLog -Message_color 'Tomato' -thisApp $thisapp -synchash $synchashWeak.Target
        if($synchashWeak.Target.Main_TaskbarItemInfo.ProgressState -ne 'None'){
          $synchashWeak.Target.Main_TaskbarItemInfo.ProgressState = 'None'
        }
        $synchashWeak.Target.MediaPlayer_Slider.Value = 0
        $synchashWeak.Target.timer.Stop()    
      }      
      if(!$synchashWeak.Target.vlc.IsPlaying -or ($synchashWeak.Target.is_playing -and $synchashWeak.Target.Spotify_Status -ne 'Stopped')){
        #Must be spotify track
        $current_track = $synchashWeak.Target.current_track_playing
        if($thisapp.Config.Use_Spicetify){
          #write-ezlogs "Spicetify current playing status: $($synchashWeak.Target.Spicetify | out-string)" -Dev_mode
          $Name = $synchashWeak.Target.Spicetify.title
          $Artist = $synchashWeak.Target.Spicetify.ARTIST
          try{
            if($synchashWeak.Target.Spicetify.POSITION -ne $null){
              $progress = [timespan]::ParseExact($synchashWeak.Target.Spicetify.POSITION, "%m\:%s",[System.Globalization.CultureInfo]::InvariantCulture).TotalMilliseconds
              #$progress = [timespan]::Parse($synchashWeak.Target.Spicetify.POSITION).TotalMilliseconds
            }else{
              $progress = $($([timespan]::FromMilliseconds(0)).TotalMilliseconds)
            }
          }catch{
            write-ezlogs 'An exception occurred parsing Spicetify position timespan' -showtime -catcherror $_
          }        
          $duration = $synchashWeak.Target.Spicetify.duration_ms
        }else{
          $Name = $current_track.item.name
          $Artist = $current_track.item.artists.name
          $progress = $current_track.progress_ms
          $duration = $current_track.item.duration_ms
        }      
      }           
      if(($synchashWeak.Target.vlc.IsPlaying -and $synchashWeak.Target.VLC.Time -ne -1 -and $synchashWeak.Target.Spotify_Status -in 'Stopped',$null,'')){
        try{           
          [int]$hrs = $($([timespan]::FromMilliseconds($synchashWeak.Target.VLC.Time)).Hours)
          [int]$mins = $($([timespan]::FromMilliseconds($synchashWeak.Target.VLC.Time)).Minutes)
          [int]$secs = $($([timespan]::FromMilliseconds($synchashWeak.Target.VLC.Time)).Seconds)     
          $total_time = $synchashWeak.Target.MediaPlayer_CurrentDuration
          if($hrs -lt 1){
            $hrs = '0'
          }
          $current_Length = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
          #$synchashWeak.Target.Media_Length_Label.text = $current_Length + ' / ' +  "$($total_time)"
          if($synchashWeak.Target.VideoView_Current_Length_TextBox){
            $synchashWeak.Target.VideoView_Current_Length_TextBox.text = $current_Length
          }
          if($synchashWeak.Target.VideoView_Total_Length_TextBox -and $synchashWeak.Target.VideoView_Total_Length_TextBox.text -ne $total_time){
            $synchashWeak.Target.VideoView_Total_Length_TextBox.text = $total_time
          }
          if($synchashWeak.Target.Media_Current_Length_TextBox){
            $synchashWeak.Target.Media_Current_Length_TextBox.DataContext = $current_Length
          }
          if($synchashWeak.Target.Media_Total_Length_TextBox -and $synchashWeak.Target.Media_Total_Length_TextBox.DataContext -ne $total_time){
            $synchashWeak.Target.Media_Total_Length_TextBox.DataContext = $total_time
          }
          if($synchashWeak.Target.MiniPlayer_Media_Length_Label){
            $synchashWeak.Target.MiniPlayer_Media_Length_Label.Content = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
          }          
          if(-not [string]::IsNullOrEmpty($synchashWeak.Target.MediaPlayer_TotalDuration) -and $synchashWeak.Target.MediaPlayer_TotalDuration -ne "0:0:0"){
            if(!$synchashWeak.Target.MediaPlayer_Slider.isEnabled){
              write-ezlogs " | Enabling MediaPlayer_slider" -showtime
              $synchashWeak.Target.MediaPlayer_Slider.isEnabled = $true
            }
          }elseif($synchashWeak.Target.MediaPlayer_Slider.isEnabled){
            write-ezlogs " | Disabling MediaPlayer_slider" -showtime -color cyan
            $synchashWeak.Target.MediaPlayer_Slider.isEnabled = $false
          }  
          if($synchashWeak.Target.MediaPlayer_TotalDuration -and $synchashWeak.Target.MediaPlayer_Slider.Maximum -ne $synchashWeak.Target.MediaPlayer_TotalDuration){
            write-ezlogs " | Setting MediaPlayer_Slider max to $($synchashWeak.Target.MediaPlayer_TotalDuration)" -showtime
            $synchashWeak.Target.MediaPlayer_Slider.Maximum = $synchashWeak.Target.MediaPlayer_TotalDuration
          } 
          if($synchashWeak.Target.MediaPlayer_Slider.isEnabled){
            if($thisApp.Config.Remember_Playback_Progress){
              $synchashWeak.Target.Current_playing_media.Current_Progress_Secs = $synchashWeak.Target.VLC.Time
              $thisApp.Config.Current_Playing_Media = $synchashWeak.Target.Current_playing_media
              #$thisApp.Config.Current_playing_media.Current_Progress_Secs = $synchashWeak.Target.VLC.Time
            }
            if(!$synchashWeak.Target.MediaPlayer_Slider.IsMouseOver -and !$synchashWeak.Target.VideoView_Progress_Slider.IsMouseOver -and !$synchashWeak.Target.Mini_Progress_Slider.IsMouseOver){
              $synchashWeak.Target.MediaPlayer_Slider.Value = $([timespan]::FromMilliseconds($synchashWeak.Target.VLC.Time)).TotalSeconds
              if($synchashWeak.Target.Main_TaskbarItemInfo.ProgressState -ne 'Normal'){
                $synchashWeak.Target.Main_TaskbarItemInfo.ProgressState = 'Normal'
              }       
            }else{
              if($synchashWeak.Target.MediaPlayer_Slider){
                #$synchashWeak.Target.MediaPlayer_Slider.ToolTip = $synchashWeak.Target.Media_Length_Label.content
                $synchashWeak.Target.MediaPlayer_Slider.ToolTip = $current_Length + ' / ' +  "$($total_time)"
              }
              if($synchashWeak.Target.VideoView_Progress_Slider){
                $synchashWeak.Target.VideoView_Progress_Slider.ToolTip = $synchashWeak.Target.MediaPlayer_Slider.ToolTip
              }
              if($synchashWeak.Target.Mini_Progress_Slider){
                $synchashWeak.Target.Mini_Progress_Slider.ToolTip = $synchashWeak.Target.MediaPlayer_Slider.ToolTip
              }
            }      
          }
          <#          if($synchashWeak.Target.systemmediaplayer.SystemMediaTransportControls.IsEnabled -and $synchashWeak.Target.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus -ne 'Playing'){
              $synchashWeak.Target.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus = 'Playing'
              $synchashWeak.Target.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
          } #>               
          if(@($Current_playing).count -gt 1){
            $Current_playing = $Current_playing | select -first 1
          }  
          if(!$synchashWeak.Target.PlayButton_ToggleButton.isChecked){
            $synchashWeak.Target.PlayButton_ToggleButton.isChecked = $true
          } 
          if($thisApp.Config.Libvlc_Version -eq '4'){
            $VideoMarque_Enabled = $synchashWeak.Target.VLC.MarqueeInt([LibVLCSharp.VideoMarqueeOption]::Enable)
          }else{
            $VideoMarque_Enabled = $synchashWeak.Target.VLC.MarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Enable)
          }
          if(-not [string]::IsNullOrEmpty($synchashWeak.Target.streamlink.viewer_count)){
            if($synchashWeak.Target.VideoView_ViewCount_Label.text -ne $synchashWeak.Target.streamlink.viewer_count){
              $synchashWeak.Target.VideoView_ViewCount_Label.text = $synchashWeak.Target.streamlink.viewer_count
              $synchashWeak.Target.VideoView_ViewCount_Label.Visibility = 'Visible'
              $synchashWeak.Target.VideoView_Sep3_Label.Text = ' || Viewers: '
            }
          }elseif(-not [string]::IsNullOrEmpty($synchashWeak.Target.VideoView_ViewCount_Label.text)){
            $synchashWeak.Target.VideoView_ViewCount_Label.text = $null 
            $synchashWeak.Target.VideoView_Sep3_Label.Text = $Null
            $synchashWeak.Target.VideoView_ViewCount_Label.Visibility = 'Hidden'         
          }       
          if($thisApp.Config.Enable_Marquee){
            #if($thisApp.Config.Verbose_logging){write-ezlogs " | Twitch Viewer count: $($synchashWeak.Target.streamlink.viewer_count)" -showtime -color cyan}
            if($synchashWeak.Target.streamlink.viewer_count){
              #TODO: Temp hack, need to refactor or remove
              if($synchashWeak.Target.vlc_Marquee_viewcount_set -ne $synchashWeak.Target.streamlink.viewer_count){
                if($thisApp.Config.Verbose_logging){write-ezlogs "| Setting Margquee to Twitch Viewer count: $($synchashWeak.Target.streamlink.viewer_count)" -showtime -color cyan}
                if($thisApp.Config.Libvlc_Version -eq '4'){
                  $synchashWeak.Target.VLC.SetMarqueeInt([LibVLCSharp.VideoMarqueeOption]::Enable, 1) #enable marquee option
                  $synchashWeak.Target.VLC.SetMarqueeInt([LibVLCSharp.VideoMarqueeOption]::Size, 24) #set the font size 
                  $synchashWeak.Target.VLC.SetMarqueeInt([LibVLCSharp.VideoMarqueeOption]::Position, 8) #set the position of text
                  $synchashWeak.Target.VLC.SetMarqueeString([LibVLCSharp.VideoMarqueeOption]::Text, "Viewers: $($synchashWeak.Target.streamlink.viewer_count)")
                }else{
                  $synchashWeak.Target.VLC.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Enable, 1) #enable marquee option
                  $synchashWeak.Target.VLC.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Size, 24) #set the font size 
                  $synchashWeak.Target.VLC.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Position, 8) #set the position of text
                  $synchashWeak.Target.VLC.SetMarqueeString([LibVLCSharp.Shared.VideoMarqueeOption]::Text, "Viewers: $($synchashWeak.Target.streamlink.viewer_count)")
                }
                $synchashWeak.Target.vlc_Marquee_viewcount_set = $synchashWeak.Target.streamlink.viewer_count
              }
            }else{
              if($synchashWeak.Target.vlc_Marquee_defaultset -ne "$($synchashWeak.Target.Now_Playing_Title_Label.DataContext) - $($current_Length + ' / ' +  "$($total_time)")"){
                if($thisApp.Config.Verbose_logging){write-ezlogs "| Setting Margquee to default label: $($synchashWeak.Target.Now_Playing_Title_Label.DataContext) - $($current_Length + ' / ' +  "$($total_time)")" -showtime -color cyan}
                if($thisApp.Config.Libvlc_Version -eq '4'){
                  $synchashWeak.Target.VLC.SetMarqueeInt([LibVLCSharp.VideoMarqueeOption]::Enable, 1) #enable marquee option
                  $synchashWeak.Target.VLC.SetMarqueeInt([LibVLCSharp.VideoMarqueeOption]::Size, 24) #set the font size 
                  $synchashWeak.Target.VLC.SetMarqueeInt([LibVLCSharp.VideoMarqueeOption]::Position, 8) #set the position of text
                  $synchashWeak.Target.VLC.SetMarqueeString([LibVLCSharp.VideoMarqueeOption]::Text, "$($synchashWeak.Target.Now_Playing_Title_Label.DataContext) - $($current_Length + ' / ' +  "$($total_time)")")
                }else{
                  $synchashWeak.Target.VLC.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Enable, 1) #enable marquee option
                  $synchashWeak.Target.VLC.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Size, 24) #set the font size 
                  $synchashWeak.Target.VLC.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Position, 8) #set the position of text
                  $synchashWeak.Target.VLC.SetMarqueeString([LibVLCSharp.Shared.VideoMarqueeOption]::Text, "$($synchashWeak.Target.Now_Playing_Title_Label.DataContext) - $($current_Length + ' / ' +  "$($total_time)")")
                }
                $synchashWeak.Target.vlc_Marquee_defaultset = "$($synchashWeak.Target.Now_Playing_Title_Label.DataContext) - $($current_Length + ' / ' +  "$($total_time)")"
              }
            }      
            #to set subtitle or any other text                                          
          }elseif($VideoMarque_Enabled){
            if($thisApp.Config.Verbose_logging){write-ezlogs "| Disabling Marquee label" -showtime -color cyan}
            if($thisApp.Config.Libvlc_Version -eq '4'){
              $synchashWeak.Target.VLC.SetMarqueeInt([LibVLCSharp.VideoMarqueeOption]::Enable, 0) #disable marquee option 
            }else{
              $synchashWeak.Target.VLC.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Enable, 0) #disable marquee option
            }                              
          }  
          if($synchashWeak.Target.streamlink.type -and  -not [string]::IsNullOrEmpty($Current_playing.Status) -and $Current_playing.Status -notmatch $synchashWeak.Target.streamlink.type){
            $Current_playing.Status = "$($synchashWeak.Target.streamlink.type)"
            if($synchashWeak.Target.streamlink.Title){$Current_playing.Status_Msg = "$($synchashWeak.Target.streamlink.game_name)"}
            if($synchashWeak.Target.PlayQueue_TreeView.itemssource){
              $synchashWeak.Target.PlayQueue_TreeView.itemssource.refresh()
            }elseif($synchashWeak.Target.PlayQueue_TreeView.items){
              $synchashWeak.Target.PlayQueue_TreeView.items.refresh()
            }
          }
          #TODO: Set current video quality if available -- create DisplayPanel_VideoQuality_TextBlock UI control
          if(-not [string]::IsNullOrEmpty($synchashWeak.Target.Current_playing_media.Bitrate) -and $synchashWeak.Target.DisplayPanel_VideoQuality_TextBlock -and $synchashWeak.Target.Current_playing_media.Bitrate -ne '0'){
            $synchashWeak.Target.DisplayPanel_VideoQuality_TextBlock.text = "$($synchashWeak.Target.Current_playing_media.Bitrate) Kbps"
          }elseif(-not [string]::IsNullOrEmpty($synchashWeak.Target.Current_Video_Quality) -and $synchashWeak.Target.DisplayPanel_VideoQuality_TextBlock -and $synchashWeak.Target.DisplayPanel_VideoQuality_TextBlock.text -ne $synchashWeak.Target.Current_Video_Quality){
            $synchashWeak.Target.DisplayPanel_VideoQuality_TextBlock.text = $synchashWeak.Target.Current_Video_Quality
          }elseif([string]::IsNullOrEmpty($synchashWeak.Target.Current_Video_Quality) -and $synchashWeak.Target.DisplayPanel_VideoQuality_TextBlock -and -not [string]::IsNullOrEmpty($synchashWeak.Target.DisplayPanel_VideoQuality_TextBlock.text)){
            $synchashWeak.Target.DisplayPanel_VideoQuality_TextBlock.text = $Null
          }
          if($synchashWeak.Target.Current_playing_media -and ($synchashWeak.Target.Now_Playing_Title_Label.DataContext -in 'LOADING...','','OPENING...' -or ($synchashWeak.Target.streamlink.title -and $synchashWeak.Target.Now_Playing_Title_Label.DataContext -ne "$($synchashWeak.Target.streamlink.title)" -and $synchashWeak.Target.Now_Playing_Title_Label.DataContext -ne 'SKIPPING ADS...'))){
            if($synchashWeak.Target.streamlink.title){
              if($synchashWeak.Target.streamlink.User_Name){
                $synchashWeak.Target.Now_Playing_Artist_Label.DataContext = "$($synchashWeak.Target.streamlink.User_Name)"
                $synchashWeak.Target.Now_Playing_Title_Label.DataContext = "$($synchashWeak.Target.streamlink.title)"
              }else{
                $synchashWeak.Target.Now_Playing_Title_Label.DataContext = "$($synchashWeak.Target.streamlink.User_Name): $($synchashWeak.Target.streamlink.title)"
                $synchashWeak.Target.Now_Playing_Artist_Label.DataContext = ""
              }
            }elseif($synchashWeak.Target.Current_playing_media.title){
              $synchashWeak.Target.Now_Playing_Title_Label.DataContext = "$($synchashWeak.Target.Current_playing_media.title)"
              if(-not [string]::IsNullOrEmpty($synchashWeak.Target.Current_playing_media.Artist)){
                $synchashWeak.Target.Now_Playing_artist_Label.DataContext = "$($synchashWeak.Target.Current_playing_media.Artist)"
              }elseif($synchashWeak.Target.Now_Playing_artist_Label.DataContext){
                $synchashWeak.Target.Now_Playing_artist_Label.DataContext = ""
              }
            }
            <#            if(-not [string]::IsNullOrEmpty($synchashWeak.Target.Current_playing_media.Bitrate)){
                $synchashWeak.Target.DisplayPanel_Bitrate_TextBlock.text = "$($synchashWeak.Target.Current_playing_media.Bitrate) Kbps"
                $synchashWeak.Target.DisplayPanel_Sep3_Label.Visibility = 'Visible'
                }else{
                $synchashWeak.Target.DisplayPanel_Bitrate_TextBlock.text = ""
                $synchashWeak.Target.DisplayPanel_Sep3_Label.Visibility = 'Hidden'
            }#>
          }
          #Chapters
          if($synchashWeak.Target.vlc.ChapterCount -gt 1){
            $currentChapter = $synchashWeak.Target.vlc.Chapter
            if($synchashWeak.Target.Current_playing_Media_Chapter -ne $currentChapter){
              $synchashWeak.Target.Current_playing_Media_Chapter = $currentChapter
              if($thisApp.Config.Libvlc_Version -eq '4'){
                #TODO: LIBVLC 4
              }else{
                $currentChapter_description = $synchashWeak.Target.vlc.ChapterDescription(0)| where {$_.id -eq $currentChapter}
                $newtitle = "$($synchashWeak.Target.Current_playing_media.title) | Chapter $currentChapter`: $($currentChapter_description.Name)"
              }
              if($currentChapter_description.Name -and $synchashWeak.Target.Now_Playing_Title_Label.DataContext -ne $newtitle){
                $synchashWeak.Target.Now_Playing_Title_Label.DataContext = $newtitle
              }
            }
          }                 
          if($Current_playing -and $Current_playing.FontWeight -ne 'Bold'){
            if(-not [string]::IsNullOrEmpty($Current_playing.title)){
              #$Current_playing.title = "---> $($Current_playing.title)"
              $Current_playing.FontWeight = 'Bold'
              #$Current_playing.BorderBrush = 'LightGreen'
              #$Current_playing.BorderThickness = '1'
              $Current_playing.FontSize = [Double]'13' 
              $Current_playing.FontStyle = 'Italic'          
              if($synchashWeak.Target.AudioRecorder.isRecording){
                $current_playing.PlayIconRecord = "RecordRec"
                $current_playing.PlayIconRecordVisibility = "Visible"
                $current_playing.PlayIconRecordRepeat = "Forever"
                $current_playing.PlayIconVisibility = "Hidden"
                $current_playing.PlayIconRepeat = "1x"
              }else{
                #$current_playing.PlayIconRecord = ""            
                $current_playing.PlayIconRecordVisibility = "Hidden"
                $current_playing.PlayIconRecordRepeat = "1x"
                if(!$thisApp.Config.Enable_Performance_Mode -and !$thisApp.Force_Performance_Mode){
                  $current_playing.PlayIconRepeat = "Forever"
                }
                $current_playing.PlayIconVisibility = "Visible"
                $current_playing.PlayIcon = "CompactDiscSolid"
              }
              if($synchashWeak.Target.PlayIcon.Source -ne "$($thisApp.Config.Current_Folder)\Resources\Skins\CassetteWheelRight.png"){
                $synchashWeak.Target.PlayIcon.Source = "$($thisApp.Config.Current_Folder)\Resources\Skins\CassetteWheelRight.png"
                $synchashWeak.Target.PlayIcon.Source.Freeze()
              }
              $synchashWeak.Target.Playicon.Visibility = "Visible"
              if($synchashWeak.Target.PlayIcon1_Storyboard.Storyboard -and !($thisApp.Config.Enable_Performance_Mode -or $thisApp.Force_Performance_Mode)){
                Get-WPFAnimation -thisApp $thisApp -synchash $synchashWeak.Target -Action Begin
              }
              $current_playing.PlayIconButtonHeight = "25"
              $current_playing.PlayIconButtonWidth = "25"
              $current_playing.NumberVisibility = "Hidden"
              $current_playing.NumberFontSize = [Double]'0.1'
              $current_playing.PlayIconEnabled = $true      
              if($thisApp.Config.Verbose_logging){write-ezlogs "Current : $($Current_playing | Select * | out-string)" -showtime}
            }
            if($synchashWeak.Target.PlayQueue_TreeView.itemssource){
              $synchashWeak.Target.PlayQueue_TreeView.itemssource.refresh()
            }elseif($synchashWeak.Target.PlayQueue_TreeView.items){
              $synchashWeak.Target.PlayQueue_TreeView.items.refresh()
            } 
            if($synchashWeak.Target.Update_Playing_Playlist_Timer){
              $synchashWeak.Target.Update_Playing_Playlist_Timer.tag = $Current_playing
              $synchashWeak.Target.Update_Playing_Playlist_Timer.start()       
            }                          
          }                          
        }catch{
          write-ezlogs "An exception occurred processing VLC playback in tick_timer for (Current Playing: $($Current_playing | out-string)) - (Current Playing Playlist: $($current_Playing_Playlist | out-string))" -showtime -catcherror $_
        }  
      }elseif(($current_track.is_playing -or ($synchashWeak.Target.Spicetify.is_playing)) -and $progress -ne $null -and $Name -match $synchashWeak.Target.Last_Played_title -and $synchashWeak.Target.Spotify_Status -ne 'Stopped'){  
        try{         
          #write-ezlogs "Found spotify track playing $($thisapp.config.Last_Played_title)"
          if(($synchashWeak.Target.Now_Playing_Title_Label.DataContext -in 'LOADING...','','OPENING...')){
            write-ezlogs "Updating Now Playing Title with Spotify track name: $($name)" -showtime
            $synchashWeak.Target.Now_Playing_Title_Label.DataContext = $Name
          }
          if(!$synchashWeak.Target.MediaPlayer_Slider.isEnabled){
            $synchashWeak.Target.MediaPlayer_Slider.isEnabled = $true
            #$synchashWeak.Target.VLC_Grid_Row3.Height="40"
          }
          $maxduration = $([timespan]::FromMilliseconds($duration)).TotalSeconds
          if($synchashWeak.Target.MediaPlayer_Slider.Maximum -ne $maxduration){
            #$synchashWeak.Target.MediaPlayer_Slider.Maximum = $([timespan]::FromMilliseconds($duration)).TotalSeconds
            $synchashWeak.Target.MediaPlayer_Slider.Maximum = $maxduration
          }
          [int]$hrs = $($([timespan]::FromMilliseconds($progress)).Hours)
          [int]$mins = $($([timespan]::FromMilliseconds($progress)).Minutes)
          [int]$secs = $($([timespan]::FromMilliseconds($progress)).Seconds)  
          [int]$totalhrs = $([timespan]::FromMilliseconds($duration)).Hours
          [int]$totalmins = $([timespan]::FromMilliseconds($duration)).Minutes
          [int]$totalsecs = $([timespan]::FromMilliseconds($duration)).Seconds
          #$total_time = "$totalhrs`:$totalmins`:$totalsecs"
          if($totalhrs -lt 1){
            $hrs = '0'
            $totalhrs = '0'
          }
          $total_time =  "$(([string]$totalhrs).PadLeft(2,'0')):$(([string]$totalmins).PadLeft(2,'0')):$(([string]$totalsecs).PadLeft(2,'0'))" 
          $current_Length = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"               
          if(!$synchashWeak.Target.MediaPlayer_Slider.IsMouseOver -and !$synchashWeak.Target.VideoView_Progress_Slider.IsMouseOver -and !$synchashWeak.Target.Mini_Progress_Slider.IsMouseOver){            
            $synchashWeak.Target.MediaPlayer_Slider.Value = $([timespan]::FromMilliseconds($progress)).TotalSeconds   
            write-ezlogs ">>>> Current Progress_ms: $progress" -Dev_mode        
            if($synchashWeak.Target.Main_TaskbarItemInfo.ProgressState -ne 'Normal'){
              $synchashWeak.Target.Main_TaskbarItemInfo.ProgressState = 'Normal'
            }
            if($thisApp.Config.Remember_Playback_Progress){
              $synchashWeak.Target.Current_playing_media.Current_Progress_Secs = $progress
              $thisApp.Config.Current_Playing_Media = $synchashWeak.Target.Current_playing_media
            }
          }else{
            #$synchashWeak.Target.MediaPlayer_Slider.ToolTip = $synchashWeak.Target.Media_Length_Label.content
            $synchashWeak.Target.MediaPlayer_Slider.ToolTip = $current_Length + ' / ' +  "$($total_time)"
            $synchashWeak.Target.VideoView_Progress_Slider.ToolTip = $synchashWeak.Target.MediaPlayer_Slider.ToolTip
            $synchashWeak.Target.Mini_Progress_Slider.ToolTip = $synchashWeak.Target.MediaPlayer_Slider.ToolTip
          }     
 
          #$synchashWeak.Target.Media_Length_Label.text = $current_Length + ' / ' +  "$($total_time)"
          if($synchashWeak.Target.VideoView_Current_Length_TextBox){
            $synchashWeak.Target.VideoView_Current_Length_TextBox.text = $current_Length
          }
          if($synchashWeak.Target.VideoView_Total_Length_TextBox -and $synchashWeak.Target.VideoView_Total_Length_TextBox.text -ne $total_time){
            $synchashWeak.Target.VideoView_Total_Length_TextBox.text = $total_time
          }  

          if($synchashWeak.Target.Media_Current_Length_TextBox){
            $synchashWeak.Target.Media_Current_Length_TextBox.DataContext = $current_Length
          }
          if($synchashWeak.Target.Media_Total_Length_TextBox -and $synchashWeak.Target.Media_Total_Length_TextBox.DataContext -ne $total_time){
            $synchashWeak.Target.Media_Total_Length_TextBox.DataContext = $total_time
          }
          if($synchashWeak.Target.MiniPlayer_Media_Length_Label){
            $synchashWeak.Target.MiniPlayer_Media_Length_Label.Content = "$(([string]$hrs).PadLeft(2,'0')):$(([string]$mins).PadLeft(2,'0')):$(([string]$secs).PadLeft(2,'0'))"
          }    
          if($synchashWeak.Target.systemmediaplayer.SystemMediaTransportControls.IsEnabled -and $synchashWeak.Target.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus -ne 'Playing'){
            #$synchashWeak.Target.systemmediaplayer.SystemMediaTransportControls.PlaybackStatus = 'Playing'
            #$synchashWeak.Target.systemmediaplayer.SystemMediaTransportControls.DisplayUpdater.Update()
          }   
          if(!$synchashWeak.Target.PlayButton_ToggleButton.isChecked){
            $synchashWeak.Target.PlayButton_ToggleButton.isChecked = $true
          }  
          if($Current_playlist_items){
            $queue_index = $Current_playlist_items.id.indexof($synchashWeak.Target.Current_playing_media.id)
            if($queue_index -ne -1){
              $Current_playing = $Current_playlist_items[$queue_index]
            }else{
              $Current_playing = $Current_playlist_items.where({$_.id -eq $synchashWeak.Target.Current_playing_media.id}) | select -Unique
            }            
          }
          if($Current_playing -and $Current_playing.FontWeight -ne 'Bold'){
            if($synchashWeak.Target.PlayQueue_TreeView.itemssource.NeedsRefresh){
              $synchashWeak.Target.PlayQueue_TreeView.itemssource.refresh()
            }elseif($synchashWeak.Target.PlayQueue_TreeView.items.NeedsRefresh){
              $synchashWeak.Target.PlayQueue_TreeView.items.refresh()
            }
            #$Current_playing = $Current_playlist_items | where  {$_.id -eq $synchashWeak.Target.Current_playing_media.id} | select -Unique      
            if(-not [string]::IsNullOrEmpty($Current_playing.title)){
              #$Current_playing.title = "---> $($Current_playing.title)"
              $Current_playing.FontWeight = 'Bold'
              #$Current_playing.BorderBrush = 'LightGreen'
              #$Current_playing.BorderThickness = '1'
              $Current_playing.FontSize = [Double]'13' 
              if($synchashWeak.Target.AudioRecorder.isRecording){
                $current_playing.PlayIconRecord = "RecordRec"
                $current_playing.PlayIconRecordVisibility = "Visible"
                $current_playing.PlayIconRecordRepeat = "Forever"
                $current_playing.PlayIconVisibility = "Hidden"
                $current_playing.PlayIconRepeat = "1x"
              }else{
                #$current_playing.PlayIconRecord = ""
                $current_playing.PlayIconRecordVisibility = "Hidden"
                $current_playing.PlayIconRecordRepeat = "1x"
                if(!$thisApp.Config.Enable_Performance_Mode -and !$thisApp.Force_Performance_Mode){
                  $current_playing.PlayIconRepeat = "Forever"
                }               
                $current_playing.PlayIconVisibility = "Visible"
                $current_playing.PlayIcon = "CompactDiscSolid"
              }
              $current_playing.PlayIconButtonHeight = "25"
              $current_playing.PlayIconButtonWidth = "25"
              $current_playing.NumberVisibility = "Hidden"
              $current_playing.NumberFontSize = [Double]'0.1'
              $current_playing.PlayIconEnabled = $true     
              if($synchashWeak.Target.PlayIcon1_Storyboard.Storyboard){
                Get-WPFAnimation -thisApp $thisApp -synchash $synchashWeak.Target -Action Begin
              }                 
            }elseif(-not [string]::IsNullOrEmpty($Current_playing.Header)){
              #$Current_playing.Header = "---> $($Current_playing.Header)"
            }
            if($synchashWeak.Target.PlayQueue_TreeView.itemssource){
              $synchashWeak.Target.PlayQueue_TreeView.itemssource.refresh()
            }elseif($synchashWeak.Target.PlayQueue_TreeView.items){
              $synchashWeak.Target.PlayQueue_TreeView.items.refresh()
            }
            if($synchashWeak.Target.Update_Playing_Playlist_Timer){
              $synchashWeak.Target.Update_Playing_Playlist_Timer.tag = $Current_playing
              $synchashWeak.Target.Update_Playing_Playlist_Timer.start()   
            }                                                    
          }                  
        }catch{
          write-ezlogs 'An exception occurred processing Spotify playback in tick_timer' -showtime -catcherror $_
        }    
      }elseif((!$synchashWeak.Target.vlc.IsPlaying) -and ($synchashWeak.Target.vlc.media.State -notin 'Playing','Opening') -and $synchashWeak.Target.Spotify_Status -eq 'Stopped' -and !$synchashWeak.Target.Webview2.CoreWebView2.IsDocumentPlayingAudio -and !$synchashWeak.Target.YoutubeWebView2.CoreWebView2.IsDocumentPlayingAudio){  
        write-ezlogs "Unable to find any media currently playing, cleaning up media timer and moving on -- vlc.IsPlaying: $($synchashWeak.Target.vlc.IsPlaying) -- libvlc_media.State: $($synchashWeak.Target.vlc.media.State)" -Warning
        if($thisApp.Config.Dev_mode){
          write-ezlogs "VLC: $($synchashWeak.Target.vlc | out-string)" -Warning -Dev_mode
          write-ezlogs "VLC Media: $($synchashWeak.Target.vlc.media | out-string)" -Warning -Dev_mode
        }
        if(Get-Process -Name 'Spotify*' -ErrorAction SilentlyContinue){
          if($thisapp.config.Use_Spicetify -and ((NETSTAT.EXE -an) | where {$_ -match '127.0.0.1:8974' -or $_ -match '0.0.0.0:8974'})){
            try{
              #start-sleep 1
              write-ezlogs ">>>> Stopping Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -color cyan
              Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing  
            }catch{
              write-ezlogs "An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -catcherror $_
              Get-Process -Name 'Spotify*' | Stop-Process -Force -ErrorAction SilentlyContinue            
            }
          }else{
            try{
              $devices = Get-AvailableDevices -ApplicationName $thisapp.config.App_Name
              $device = $devices | where {$_.is_active -eq $true}
              if($device -and $synchashWeak.Target.current_track_playing.is_playing){
                write-ezlogs '>>>> Stopping Spotify playback with Suspend-Playback' -showtime
                Suspend-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $device.id
              }else{
                write-ezlogs 'Spotify is not currently playing' -showtime          
              }           
            }catch{
              write-ezlogs 'An exception occurred executing Suspend-Playback' -showtime -catcherror $_
              Get-Process -Name 'Spotify*' | Stop-Process -Force -ErrorAction SilentlyContinue            
            }           
          }
        }       
        if($thisapp.config.Current_Playlist.values -contains $synchashWeak.Target.Current_playing_media.id){
          $index_toremove = $thisapp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $synchashWeak.Target.Current_playing_media.id} | select * -ExpandProperty key
          $null = $thisapp.config.Current_Playlist.Remove($index_toremove)                         
        }      
        try{
          #Disable ChatView
          Update-ChatView -synchash $synchashWeak.Target -thisApp $thisApp -Disable -Hide
        
          #Get next item to play if Auto Play/Repeat enabled
          if($thisApp.Config.Auto_Repeat){
            write-ezlogs '| Repeat is enabled, restarting current media' -showtime
            if($synchashWeak.Target.Current_playing_media.source -eq 'Spotify' -or $synchashWeak.Target.Current_playing_media.url -match 'spotify\:'){
              Start-SpotifyMedia -Media $synchashWeak.Target.Current_playing_media -thisApp $thisapp -synchash $synchashWeak -use_WebPlayer:$thisapp.config.Spotify_WebPlayer -Show_notifications:$thisApp.config.Show_notifications -RestrictedRunspace:$thisapp.config.Spotify_WebPlayer
            }else{
              Start-Media -Media $synchashWeak.Target.Current_playing_media -thisApp $thisapp -synchashWeak $synchashWeak -Show_notification -restart
            }
          }elseif($thisapp.config.Auto_Playback){
            Skip-Media -thisApp $thisApp -synchash $synchashWeak.Target
          }else{
            Get-PlayQueue -verboselog:$false -synchashWeak $synchashWeak -thisApp $thisapp -use_Runspace
            Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchashWeak $synchashWeak -thisApp $thisapp -use_Runspace
            write-ezlogs '| No other media is queued to play due to Auto Playback disabled' -showtime
            if(Get-Process -Name 'Spotify*' -ErrorAction SilentlyContinue){Get-Process -Name 'Spotify*' | Stop-Process -Force -ErrorAction SilentlyContinue} 
            $synchashWeak.Target.Spotify_Status = 'Stopped'
            <#            if($synchashWeak.Target.Media_Length_Label){
                $synchashWeak.Target.Media_Length_Label.content = ''
            }#>
            if($synchashWeak.Target.Media_Current_Length_TextBox){
              $synchashWeak.Target.Media_Current_Length_TextBox.DataContext = '00:00:00'
            }
            if($synchashWeak.Target.Media_Total_Length_TextBox){
              $synchashWeak.Target.Media_Total_Length_TextBox.DataContext = ""
            }                           
            if($synchashWeak.Target.MiniPlayer_Media_Length_Label){
              $synchashWeak.Target.MiniPlayer_Media_Length_Label.Content = "00:00:00"
            }
            if($synchashWeak.Target.Now_Playing_Label){
              $synchashWeak.Target.Now_Playing_Label.Visibility = 'Hidden'
              $synchashWeak.Target.Now_Playing_Label.DataContext = 'PLAYING'
            } 
            if($synchashWeak.Target.Now_Playing_Title_Label){
              $synchashWeak.Target.Now_Playing_Title_Label.DataContext = ""
            }                       
            if($synchashWeak.Target.StopButton_Button){
              $peer = [System.Windows.Automation.Peers.ButtonAutomationPeer]($synchashWeak.Target.StopButton_Button)
              $invokeProv = $peer.GetPattern([System.Windows.Automation.Peers.PatternInterface]::Invoke)
              $invokeProv.Invoke()
            }
            if($synchashWeak.Target.timer){
              $synchashWeak.Target.timer.stop()
            }                      
          }  
        }catch{        
          write-ezlogs 'An exception occurred executing getting next item to play' -showtime -catcherror $_
          if($synchashWeak.Target.timer){
            $synchashWeak.Target.timer.stop()
          }
        }    
      }else{
        write-ezlogs '| Unsure what to do! Looping...' -showtime -warning
        write-ezlogs "| Spotify_Status: $($synchashWeak.Target.Spotify_Status) - Vlc status: $($synchashWeak.Target.vlc.isPlaying) - Vlc media state: $($synchashWeak.Target.vlc.media.State)" -showtime
      }   
    }elseif($([string]$synchashWeak.Target.vlc.media.Mrl).StartsWith("dshow://")){
      write-ezlogs "Vlc is currently playing dshow which is for webplayers, stopping this timer" -showtime -warning
      if($synchashWeak.Target.timer){
        $synchashWeak.Target.timer.stop()
      }
    }elseif($([string]$synchashWeak.Target.vlc.media.Mrl).StartsWith("imem://")){
      write-ezlogs "Vlc is currently playing memory streamed media, (which isn't processed properly for the queue yet), stopping this timer" -showtime -warning
      if($synchashWeak.Target.timer){
        $synchashWeak.Target.timer.stop()
      }
    }else{
      write-ezlogs "Media Timer is not enabled/running, aborting update-mediatimer" -showtime -warning
    } 
  }catch{
    write-ezlogs "An exception occurred in update-mediatimer" -catcherror $_
  }finally{
    if($Media_Timer_Measure){
      $Media_Timer_Measure.stop()
      write-ezlogs "Media_Timer_Measure" -PerfTimer $Media_Timer_Measure
      $Media_Timer_Measure = $Null
    }
  }       
}
#---------------------------------------------- 
#endregion Update-MediaTimer Function
#----------------------------------------------
Export-ModuleMember -Function @('Update-MediaTimer')