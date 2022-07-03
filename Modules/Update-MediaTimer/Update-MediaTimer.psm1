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
    - Module designed for EZT-MediaPlayer

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
    $synchash,
    $thisScript,
    $Media_ContextMenu,
    $PlayMedia_Command,
    $thisApp,
    $all_playlists,
    [switch]$Show_notification,
    $Script_Modules,
    [switch]$Verboselog
  )
  
  $timer_maxretry = 0
  $last_played = $synchash.Last_played
  #$spotify_last_played = $thisapp.config.Spotify_Last_Played
  #$Current_playlist_items = $synchash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}
  $Current_playing = $synchash.PlayQueue_TreeView.Items | where {$_.header.id -eq $synchash.Current_playing_media.id} | select -Unique 
  if(!$Current_playing){$Current_playing = $synchash.PlayQueue_TreeView.Items | where {$_.tag.Media.id -eq $synchash.Current_playing_media.id} | select -Unique}  
  if($synchash.vlc.mute){
    $synchash.Volume_icon.kind = 'Volumeoff' 
  }elseif($synchash.vlc.Volume -ge 75){
    $synchash.Volume_icon.kind = 'VolumeHigh'
  }elseif($synchash.vlc.Volume -gt 25 -and $synchash.vlc.Volume -lt 75){
    $synchash.Volume_icon.kind = 'VolumeMedium'
  }elseif($synchash.vlc.Volume -le 25 -and $synchash.vlc.Volume -gt 0 ){
    $synchash.Volume_icon.kind = 'VolumeLow'
  }elseif($synchash.vlc.Volume -le 0 ){
    $synchash.Volume_icon.kind = 'Volumeoff'
  }       

  if($Current_playing){
    $thisapp.Config.Last_Played = $synchash.Current_playing_media.id
    $last_played = $synchash.Current_playing_media.id
  }
  if($Current_playing){

  }
  #write-ezlogs "Current playing items: $($Current_playing | out-string)"
  #write-ezlogs "Current tag media: $($Current_playing.tag.Media | out-string)"
  if(!$Current_playing -and $timer_maxretry -lt 25){    
    try{
      write-ezlogs "| Couldnt get current playing item with id $($synchash.Current_playing_media.id) from queue! Executing Get-Playlists" -showtime -warning
      #Get-Playlists -verboselog:$false -synchash $synchash -thisApp $thisapp
      Get-PlayQueue -verboselog:$false -synchash $synchash -thisApp $thisapp        
      $timer_maxretry++    
      #$Current_playlist_items = $synchash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}    
      $Current_playing = $synchash.PlayQueue_TreeView.Items | where {$_.header.id -eq $synchash.Current_playing_media.id} | select -Unique           
      if(!$Current_playing){
        write-ezlogs '| Item does not seem to be in the queue' -showtime -warning
        if($thisapp.config.Current_Playlist.values -notcontains $synchash.Current_playing_media.id){
          write-ezlogs "| Adding $($synchash.Current_playing_media.id) to Play Queue" -showtime
          $index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
          $index++
          $null = $thisapp.config.Current_Playlist.add($index,$synchash.Current_playing_media.id)         
        }else{
          write-ezlogs "| Play queue already contains $($synchash.Current_playing_media.id), refreshing one more time then I'm done here" -showtime -warning
        }
        $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8
        #Get-Playlists -verboselog:$false -synchash $synchash -thisApp $thisapp
        Get-PlayQueue -verboselog:$false -synchash $synchash -thisApp $thisapp
        #$Current_playlist_items = $synchash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}    
        $Current_playing = $synchash.PlayQueue_TreeView.Items | where {$_.header.id -eq $synchash.Current_playing_media.id} | select -Unique         
        if(!$Current_playing){
          write-ezlogs "[ERROR] | Still couldnt find $($synchash.Current_playing_media.id) in the play queue, aborting!" -showtime -color red
          #Update-Notifications -id 1 -Level 'ERROR' -Message "Couldnt find $($thisapp.Config.Last_Played) in the play queue, aborting progress timer!" -VerboseLog -Message_color 'Tomato' -thisApp $thisapp -synchash $synchash
          $synchash.MediaPlayer_Slider.Value = 0
          $synchash.timer.Stop()
        }else{
          write-ezlogs '| Found current playing item after adding it to the play queue and refreshing Get-Playlists, but this shouldnt have been needed!' -showtime -warning
        }                      
      }else{
        write-ezlogs '| Found current playing item after refreshing Get-Playlists' -showtime
      }   
    }catch{
      write-ezlogs "An exception occurred in Tick_Timer while trying to update/get current playing items" -showtime -catcherror $_
    }  
  }elseif($timer_maxretry -ge 25){
    write-ezlogs "[ERROR] | Timed out trying to find current playing item $($synchash.Current_playing_media.id) in the play queue, aborting!" -showtime -color red
    Update-Notifications -id 1 -Level 'ERROR' -Message "Timed out trying to find $($synchash.Current_playing_media.id) in the play queue, aborting progress timer!" -VerboseLog -Message_color 'Tomato' -thisApp $thisapp -synchash $synchash
    $synchash.MediaPlayer_Slider.Value = 0
    $synchash.timer.Stop()    
  }else{
    #write-ezlogs "Found Current playing item $($Current_playing.header | out-string)"
  }        
  if(!$synchash.vlc.IsPlaying){
    #$current_track = (Get-CurrentTrack -ApplicationName $thisApp.config.App_Name) 
    $current_track = $synchash.current_track_playing
    if($thisapp.Config.Use_Spicetify){
      $Name = $thisapp.config.Spicetify.title
      $Artist = $thisapp.config.Spicetify.ARTIST
      try{
        if($thisapp.config.Spicetify.POSITION -ne $null){
          $progress = [timespan]::Parse($thisapp.config.Spicetify.POSITION).TotalMilliseconds
        }else{
          $progress = $($([timespan]::FromMilliseconds(0)).TotalMilliseconds)
        }
      }catch{
        write-ezlogs 'An exception occurred parsing Spicetify position timespan' -showtime -catcherror $_
      }        
      $duration = $thisapp.config.Spicetify.duration_ms
    }else{
      $Name = $current_track.item.name
      $Artist = $current_track.item.artists.name
      $progress = $current_track.progress_ms
      $duration = $current_track.item.duration_ms
    }       
    #write-ezlogs "Last played title: $($thisApp.config.Last_Played_title) -- Current name : $($name)" -showtime
  }           
  if($synchash.vlc.IsPlaying -and $synchash.VLC.Time -ne -1){
    try{ 
      if($synchash.MediaPlayer_slider.Visibility -eq 'Hidden'){
        $synchash.MediaPlayer_slider.Visibility  = 'Visible'
      }  
      if($synchash.MediaPlayer_TotalDuration -ne $synchash.MediaPlayer_Slider.Maximum){
        $synchash.MediaPlayer_Slider.Maximum = $synchash.MediaPlayer_TotalDuration
      
      }    
      if(!$synchash.MediaPlayer_Slider.IsMouseOver){$synchash.MediaPlayer_Slider.Value = $([timespan]::FromMilliseconds($synchash.VLC.Time)).TotalSeconds}      
      [int]$hrs = $($([timespan]::FromMilliseconds($synchash.VLC.Time)).Hours)
      [int]$mins = $($([timespan]::FromMilliseconds($synchash.VLC.Time)).Minutes)
      [int]$secs = $($([timespan]::FromMilliseconds($synchash.VLC.Time)).Seconds)     
      $total_time = $synchash.MediaPlayer_CurrentDuration      
      $synchash.Media_Length_Label.content = "$hrs" + ':' + "$mins" + ':' + "$secs" + '/' + "$($total_time)"   
      if(@($Current_playing.header).count -gt 1){
        $Current_playing = $Current_playing | select -first 1
      }       
      if($thisApp.Config.Enable_Marquee -and $synchash.streamlink.viewer_count){
        if($thisApp.Config.Verbose_logging){write-ezlogs " | Twitch Viewer count: $($synchash.streamlink.viewer_count)" -showtime -color cyan}
        $synchash.VLC.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Enable, 1) #enable marquee option
        $synchash.VLC.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Size, 24) #set the font size 
        $synchash.VLC.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Position, 8) #set the position of text
        if($synchash.streamlink.viewer_count){
          $synchash.VLC.SetMarqueeString([LibVLCSharp.Shared.VideoMarqueeOption]::Text, "Viewers: $($synchash.streamlink.viewer_count)")
        }else{
          $synchash.VLC.SetMarqueeString([LibVLCSharp.Shared.VideoMarqueeOption]::Text, "$($Current_playing.Header.title) - $($synchash.Media_Length_Label.content)")
        }      
        #to set subtitle or any other text                                          
      }else{
        $synchash.VLC.SetMarqueeInt([LibVLCSharp.Shared.VideoMarqueeOption]::Enable, 0) #disable marquee option                                   
      }     
      if($Current_playing -and $Current_playing.Header.title -notmatch '---> '){   
        $synchash.PlayQueue_TreeView.items.refresh()           
        #$Current_playlist_items = $synchash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}
        $Current_playing = $synchash.PlayQueue_TreeView.Items | where  {$_.header.id -eq $synchash.Current_playing_media.id} | select -Unique    
        if($synchash.streamlink.type -and  -not [string]::IsNullOrEmpty($Current_playing.Header.Status) -and $Current_playing.Header.Status -notmatch $synchash.streamlink.type){
          #write-ezlogs "Header: $($Current_playing.Header | out-string)"
          $Current_playing.Header.Status = "$($synchash.streamlink.type)"
          if($synchash.streamlink.Title){$Current_playing.Header.Status_Msg = "$($synchash.streamlink.game_name)"}
        } 
        #(($syncHash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}).items | where {$_.tag.Media.id -eq $thisApp.Config.Last_Played}).Header = "---> $($Current_playing.Header)"
        if(-not [string]::IsNullOrEmpty($Current_playing.Header.title)){
          #write-ezlogs "current header: $($Current_playing.Header.title)" -showtime
          $Current_playing.Header.title = "---> $($Current_playing.Header.title)"
          $Current_playing.Header.FontWeight = 'Bold'
          #$Current_playing.Header.BorderBrush = 'LightGreen'
          #$Current_playing.Header.BorderThickness = '1'
          $Current_playing.Header.FontSize = 16 
          $Current_playing.Header.FontStyle = 'Italic'          
          #$current_playing.Header.PlayIcon = "$($thisApp.Config.Current_Folder)\\Resources\\Material-MotionPlayOutline.png"
          $current_playing.Header.PlayIcon = "CompactDiscSolid"
          $current_playing.Header.PlayIconRepeat = "Forever"
          $current_playing.Header.NumberVisibility = "Hidden"
          $current_playing.Header.NumberFontSize = 0
          $current_playing.Header.PlayIconVisibility = "Visibile"   
          $current_playing.Header.PlayIconEnabled = $true          
          write-ezlogs "Current header : $($Current_playing.Header | Select * | out-string)"
        }else{
          $Current_playing.Header = "---> $($Current_playing.Header)"
        }
        $synchash.PlayQueue_TreeView.items.refresh()       
      }    
    }catch{
      write-ezlogs "An exception occurred processing VLC playback in tick_timer for $($Current_playing.Header | out-string)" -showtime -catcherror $_
    }  
  }elseif(($current_track.is_playing -or ($thisapp.Config.Spicetify.is_playing)) -and $progress -and $Name -match $thisapp.config.Last_Played_title -and $synchash.Spotify_Status -ne 'Stopped'){  
    try{
      #write-ezlogs "Found spotify track playing $($thisapp.config.Last_Played_title)"
      if($synchash.MediaPlayer_slider.Visibility -eq 'Hidden'){
        $synchash.MediaPlayer_slider.Visibility  = 'Visible'
      }
      $synchash.MediaPlayer_Slider.Maximum = $([timespan]::FromMilliseconds($duration)).TotalSeconds
      if(!$synchash.MediaPlayer_Slider.IsMouseOver){$synchash.MediaPlayer_Slider.Value = $([timespan]::FromMilliseconds($current_track.progress_ms)).TotalSeconds}     
      [int]$hrs = $($([timespan]::FromMilliseconds($progress)).Hours)
      [int]$mins = $($([timespan]::FromMilliseconds($progress)).Minutes)
      [int]$secs = $($([timespan]::FromMilliseconds($progress)).Seconds)  
      [int]$totalhrs = $([timespan]::FromMilliseconds($duration)).Hours
      [int]$totalmins = $([timespan]::FromMilliseconds($duration)).Minutes
      [int]$totalsecs = $([timespan]::FromMilliseconds($duration)).Seconds
      $total_time = "$totalhrs`:$totalmins`:$totalsecs"    
      $synchash.Media_Length_Label.content = "$hrs" + ':' + "$mins" + ':' + "$secs" + '/' + "$($total_time)"              
      #$Current_playing = $Current_playlist_items.items | where {$_.header.id -eq $thisapp.Config.Last_Played} | select -Unique 
      $Current_playing = $synchash.PlayQueue_TreeView.Items | where {$_.header.id -eq $synchash.Current_playing_media.id} | select -Unique 
      #write-ezlogs "playing $($Current_playing.header | out-string)"
      if($Current_playing -and $Current_playing.Header -notmatch '---> '){
        $synchash.PlayQueue_TreeView.items.refresh()
        $Current_playing = $synchash.PlayQueue_TreeView.Items | where  {$_.header.id -eq $synchash.Current_playing_media.id} | select -Unique      
        if(-not [string]::IsNullOrEmpty($Current_playing.Header.title)){
          $Current_playing.Header.title = "---> $($Current_playing.Header.title)"
          $Current_playing.Header.FontWeight = 'Bold'
          #$Current_playing.Header.BorderBrush = 'LightGreen'
          #$Current_playing.Header.BorderThickness = '1'
          $Current_playing.Header.FontSize = 16 
          $current_playing.Header.PlayIcon = "CompactDiscSolid"
          $current_playing.Header.PlayIconRepeat = "Forever"
          #$peer = [System.Windows.Automation.Peers.ButtonAutomationPeer]($syncHash.btnSearch)
          #$invokeProv = $peer.GetPattern([System.Windows.Automation.Peers.PatternInterface]::Invoke)
          #$invokeProv.Invoke()
          $current_playing.Header.NumberVisibility = "Hidden"
          $current_playing.Header.NumberFontSize = 0
          $current_playing.Header.PlayIconVisibility = "Visibile"   
          $current_playing.Header.PlayIconEnabled = $true          
        }else{
          $Current_playing.Header = "---> $($Current_playing.Header)"
        }
        $synchash.PlayQueue_TreeView.items.refresh()              
      }    
    }catch{
      write-ezlogs 'An exception occurred processing Spotify playback in tick_timer' -showtime -catcherror $_
    }    
  }elseif((!$synchash.vlc.IsPlaying) -and $synchash.Spotify_Status -eq 'Stopped' -and !$synchash.Webview2.CoreWebView2.IsDocumentPlayingAudio){   
    if($thisapp.Config.Verbose_Logging){
      if($synchash.Spotify_Status -eq 'Stopped' -and !$synchash.vlc.IsPlaying){
        write-ezlogs "Spotify_Status now equals 'Stopped'" -showtime
      }elseif(!$synchash.vlc.IsPlaying){
        write-ezlogs "VLC is_Playing is now false - '$($synchash.vlc.IsPlaying)'" -showtime
      }
    }
    if(Get-Process -Name 'Spotify*' -ErrorAction SilentlyContinue){
      if($thisapp.config.Use_Spicetify){
        try{
          #start-sleep 1
          write-ezlogs "Stopping Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -color cyan
          Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing  
        }catch{
          write-ezlogs "An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -catcherror $_
          Get-Process -Name 'Spotify*' | Stop-Process -Force -ErrorAction SilentlyContinue            
        }
      }else{
        try{
          $devices = Get-AvailableDevices -ApplicationName $thisapp.config.App_Name
          if($devices -and $synchash.current_track_playing.is_playing){
            write-ezlogs 'Stopping Spotify playback with Suspend-Playback' -showtime -color cyan
            Suspend-Playback -ApplicationName $thisapp.config.App_Name -DeviceId $devices.id
          }else{
            write-ezlogs 'Spotify is not currently playing' -showtime          
          }           
        }catch{
          write-ezlogs 'An exception occurred executing Suspend-Playback' -showtime -catcherror $_
          Get-Process -Name 'Spotify*' | Stop-Process -Force -ErrorAction SilentlyContinue            
        }           
      }
    }       
    if($thisapp.config.Current_Playlist.values -contains $synchash.Current_playing_media.id){
      $index_toremove = $thisapp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $synchash.Current_playing_media.id} | select * -ExpandProperty key
      $null = $thisapp.config.Current_Playlist.Remove($index_toremove)                         
    }      
    try{  
      $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8   
      if($thisApp.config.Chat_View -and $synchash.chat_WebView2.CoreWebView2){
        $synchash.Chat_View_Button.IsEnabled = $false    
        $synchash.chat_column.Width = "*"
        $synchash.Chat_Icon.Kind="ChatRemove"
        $synchash.Chat_View_Button.Opacity=0.7
        $synchash.Chat_View_Button.ToolTip="Chat View Not Available"
        $synchash.chat_WebView2.Visibility = 'Hidden'
        $synchash.chat_WebView2.stop()        
      }     
      if($thisapp.config.Shuffle_Playback){
        $next_item = $thisapp.config.Current_Playlist.values | where {$_} | Get-Random -Count 1
      }else{
        #$next_item = $thisApp.config.Current_Playlist.values | where {$_} | Select -First 1 
        $index_toget = ($thisapp.config.Current_Playlist.keys | measure -Minimum).Minimum 
        $next_item = (($thisapp.config.Current_Playlist.GetEnumerator()) | where {$_.name -eq $index_toget}).value
      }                   
      if($thisapp.Config.Verbose_Logging){write-ezlogs "Next to play from Play Queue is $($next_item) which should not eq last played $($synchash.Current_playing_media.id)" -showtime}
      Get-PlayQueue -verboselog:$false -synchash $synchash -thisApp $thisapp
      #Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -thisApp $thisapp          
      if($next_item){
        write-ezlogs "| Next queued item is $($next_item)" -showtime
        $next_selected_media = $synchash.all_playlists.Playlist_tracks | where {$_.id -eq $next_item} | select -Unique 
        if(!$next_selected_media){$next_selected_media = $Datatable.datatable | where {$_.ID -eq $next_item} | select -Unique}              
        if(!$next_selected_media){$next_selected_media = $Youtube_Datatable.datatable | where {$_.id -eq $next_item} | select -Unique}
        if(!$next_selected_media){$next_selected_media = $Spotify_Datatable.datatable | where {$_.id -eq $next_item} | select -Unique}
        if(!$next_selected_media){
          write-ezlogs "Unable to find next media to play with id $next_item! Cannot continue" -showtime -warning
          Update-Notifications -id 1 -Level 'WARNING' -Message "Unable to find next media to play with id $next_item! Cannot continue" -VerboseLog -Message_color 'Orange' -thisApp $thisapp -synchash $synchash -open_flyout
          $syncHash.MainGrid_Background_Image_Source_transition.content = ''
          $syncHash.MainGrid_Background_Image_Source.Source = $null
          #$syncHash.MainGrid.Background = $synchash.Window.TryFindResource('MainGridBackGradient')
        }else{
          write-ezlogs "| Next to play is $($next_selected_media.title)" -showtime         
          if($next_selected_media.Spotify_Path){
            Start-SpotifyMedia -Media $next_selected_media -thisApp $thisapp -synchash $synchash -Script_Modules $Script_Modules -Show_notification -media_contextMenu $synchash.Media_ContextMenu -PlayMedia_Command $synchash.PlayMedia_Command
          }elseif($next_selected_media.id){
            if(Get-Process -Name 'Spotify*' -ErrorAction SilentlyContinue){
              Get-Process -Name 'Spotify*' | Stop-Process -Force -ErrorAction SilentlyContinue
            } 
            $synchash.Spotify_Status = 'Stopped'           
            Start-Media -media $next_selected_media -thisApp $thisapp -synchash $synchash -Show_notification -Script_Modules $Script_Modules
          }          
        }          
        $synchash.timer.stop()     
      }else{
        #Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -thisApp $thisapp
        Get-PlayQueue -verboselog:$false -synchash $synchash -thisApp $thisapp
        write-ezlogs '| No other media is queued to play' -showtime
        if(Get-Process -Name 'Spotify*' -ErrorAction SilentlyContinue){Get-Process -Name 'Spotify*' | Stop-Process -Force -ErrorAction SilentlyContinue} 
        $synchash.Spotify_Status = 'Stopped'   
        $synchash.Media_Length_Label.content = ''
        $synchash.Now_Playing_Label.content = '' 
        $Synchash.Main_Tool_Icon.Text = $synchash.Window.Title
        $syncHash.MainGrid_Background_Image_Source_transition.content = ''
        $syncHash.MainGrid_Background_Image_Source.Source = $null
        $synchash.Background_cached_image = $Null
        $synchash.update_background_timer.start()
        #$syncHash.MainGrid.Background = $synchash.Window.TryFindResource('MainGridBackGradient')               
        $synchash.timer.stop()
      }   
    }catch{        
      write-ezlogs 'An exception occurred executing Start-Media for next item' -showtime -catcherror $_
      $synchash.timer.stop()
    }    
  }else{
    write-ezlogs '| Unsure what to do! Looping...' -showtime -warning
  }          
}
#---------------------------------------------- 
#endregion Update-MediaTimer Function
#----------------------------------------------
Export-ModuleMember -Function @('Update-MediaTimer')

