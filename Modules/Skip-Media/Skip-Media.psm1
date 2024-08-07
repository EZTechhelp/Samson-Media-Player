<#
    .Name
    Skip-Media

    .Version 
    0.1.0

    .SYNOPSIS
    Skips to the next media item in the queue

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
#region Skip-Media Function
#----------------------------------------------
function Skip-Media
{
  Param (
    $thisApp,
    $synchash,
    [switch]$Startup,
    [switch]$Verboselog
  )
  try{  
    $synchash.SkipMedia_isExecuting = $true
    $next_selected = $Null
    $next_selected = [hashtable]::Synchronized(@{}) 
    $last_played = [hashtable]::Synchronized(@{})  
    $last_played.mediaid = $synchash.Current_playing_media.id  
    $last_played.media = $synchash.Current_playing_media         
    if(!$last_played.mediaid -and $synchash.Last_Played){
      $last_played.mediaid = $synchash.Last_Played
    }     
    $synchash.Youtube_WebPlayer_URL = $null
    $synchash.Youtube_WebPlayer_title = $null
    $synchash.Spotify_WebPlayer_title = $null
    $synchash.Spotify_WebPlayer_URL = $null
    $synchash.Start_media = $null 

    $synchash.Current_playing_media = $null 
    $synchash.Youtube_webplayer_current_Media = $Null
    write-ezlogs "[Caller: $((Get-PSCallStack)[1].Location -replace '.ps1')] >>>> Skip-Media received" -showtime
    write-ezlogs ">>>> Stopping play timers" -showtime         
    $Synchash.Timer.stop()
    $synchash.Start_media_timer.stop()  
    #$synchash.WebPlayer_Playing_timer.stop()  
    Set-WebPlayerTimer -synchash $synchash -thisApp $thisApp -stop    
    if($synchash.vlc.IsPlaying -or $synchash.Vlc.state -match 'Paused'){
      write-ezlogs ">>>> Stopping VLC Playback" -showtime 
      $Null = $synchash.VLC.stop()
      if($synchash.vlc.media -is [System.IDisposable]){
        write-ezlogs " | Disposing Libvlc_media" -showtime
        #$synchash.libvlc_media.dispose()
        #$synchash.libvlc_media = $Null
        $synchash.vlc.media = $Null
      }      
      #$synchash.vlc.media = $Null   
      $synchash.VLC_IsPlaying_State = $synchash.Vlc.isPlaying
    }
    if($thisApp.Config.Import_Spotify_Media -and (($thisapp.config.Spotify_WebPlayer -and $synchash.Spotify_WebPlayer_State.current_track.id) -or (Get-Process 'Spotify*'))){
      try{   
        write-ezlogs ">>>> Checking for Spotify current track playback" -showtime 
        $current_track = (Get-CurrentTrack -ApplicationName $thisApp.config.App_Name) 
        if($current_track){
          $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
          $device = $devices | where {$_.is_active -eq $true}
          write-ezlogs "| Spotify Current Track $($current_track)" -showtime
        }              
        if($current_track.is_playing){
          if($device){
            if($thisApp.config.Use_Spicetify){
              try{
                write-ezlogs ">>>> Stopping Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'"  -LogLevel 2 
                Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing  
                $synchash.Spicetify = ''
              }catch{
                write-ezlogs "An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE' -- forcing Spotify to close (Nuclear option I know)" -showtime -catcherror $_
                if(Get-Process -Name 'Spotify*' -ErrorAction SilentlyContinue){
                  Get-Process -Name 'Spotify*' | Stop-Process -Force -ErrorAction SilentlyContinue
                } 
                $synchash.Spicetify = ''            
              }
            }else{
              write-ezlogs ">>>> Stopping Spotify playback with Suspend-Playback -ApplicationName $($thisApp.config.App_Name) -DeviceId $($device.id) " -LogLevel 2
              $synchash.Spicetify = ''
              Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $device.id   
            }
          }           
        }elseif($synchash.Webview2.CoreWebView2.IsDocumentPlayingAudio){
          write-ezlogs " | Spotify Webplayer is playing audio: $($synchash.Spotify_WebPlayer_State)" -loglevel 2
        }
        $synchash.Spotify_Status = 'Stopped'
      }catch{
        write-ezlogs "An exception occurred stopped Spotify" -showtime -catcherror $_
      }               
    }      
    try{ 
      if($synchash.Spotify_WebPlayer_State.current_track){
        $synchash.Spotify_WebPlayer_State.current_track = $Null
      }                                                          
      $last_played_index = (($thisApp.config.Current_Playlist.GetEnumerator()) | where-Object {$_.value -eq $last_played.mediaid}).name
      Update-PlayQueue -Remove -ID $last_played.mediaid -thisApp $thisApp -synchash $synchash -UpdateHistory  
      if($thisApp.config.Shuffle_Playback -and $thisApp.config.Current_Playlist.values){
        try{
          write-ezlogs " | Getting random item from queue" -showtime -LogLevel 2
          $next_item = ($thisApp.config.Current_Playlist.values) | where-Object {-not ([string]::IsNullOrEmpty($_)) -and $thisApp.config.History_Playlist.values -notcontains $_} | Get-Random -Count 1
        }catch{
          write-ezlogs "An exception occurred getting random item from queue" -showtime -catcherror $_
        }
      }else{
        if(-not [string]::IsNullOrEmpty($last_played_index)){
          if($last_played_index.count -gt 1){
            write-ezlogs " | Multiple values returned for last played index $($last_played_index) - Selecting last 1" -warning
            $last_played_index = $last_played_index | Select-Object -last 1
          }
          write-ezlogs " | Getting next item after last index $($last_played_index)" -showtime -LogLevel 2
          $index_toget = ($thisApp.config.Current_Playlist.keys | Sort-Object) | Where-Object {$_ -gt $last_played_index} | select-Object -first 1 
          $next_item = (($thisApp.config.Current_Playlist.GetEnumerator()) | Where-Object {$_.name -eq $index_toget}).value   
        }else{
          write-ezlogs " | Getting next item from lowest current index" -showtime -LogLevel 2
          $index_toget = ($thisApp.config.Current_Playlist.keys | Measure-Object -Minimum).Minimum 
        }
        write-ezlogs " | Next item to get with index $($index_toget)" -showtime -LogLevel 2  
        $next_item = (($thisApp.config.Current_Playlist.GetEnumerator()) | Where-Object {$_.name -eq $index_toget}).value          
      }  
      if(!$next_item){
        write-ezlogs "Attempting to get next item from current_playlist using select -first 1" -showtime -warning -LogLevel 3
        $next_item = $thisApp.config.Current_Playlist.values | Select-Object -first 1
      }  
      if(!$next_item -and $Synchash.Current_Playing_Playlist_Source -eq 'Playlist'){
        write-ezlogs ">>>> No more media was found in the Queue, looking for next item in the current playlist: $($Synchash.Current_Playing_Playlist)" -showtime -LogLevel 2
        #Next Playlist Item
        #$current_Playing_Playlist = $synchash.Playlists_TreeView.itemssource.SourceCollection | where {$_.items.id -eq $last_played.mediaid} | select -Unique  
        if(-not [string]::IsNullOrEmpty($Synchash.Current_Playing_Playlist) -and $synchash.all_playlists.playlist_id){
          $pindex = $synchash.all_playlists.playlist_id.indexof($Synchash.Current_Playing_Playlist)
          if($pindex -ne -1){
            $current_playlist = $synchash.all_playlists[$pindex]
          }
        }else{
          $current_playlist = $synchash.all_playlists | Where-Object {$_.playlist_tracks.values.id -eq $last_played.mediaid}
        }             
        if($current_playlist){
          if(@($current_playlist).count -gt 1){
            write-ezlogs "Returned multiple playlists that contain media id $($last_played.mediaid): $($current_playlist.title | out-string)" -warning -showtime -LogLevel 2
            if(-not [string]::IsNullOrEmpty($Synchash.Current_Playing_Playlist)){
              write-ezlogs "| Looking up current playing playlist: $($Synchash.Current_Playing_Playlist)" -showtime -LogLevel 2
              $current_playlist = $synchash.all_playlists | Where-Object {$_.playlist_id -eq $Synchash.Current_Playing_Playlist}
            }else{
              write-ezlogs "| No current playing playlist value exists, cannot determine which playlist $($last_played.mediaid) belongs to...picking the last one" -showtime -Warning -LogLevel 2
              $current_playlist = $current_playlist | Select-Object -last 1
            }            
          }    
          if(@($current_playlist.Playlist_Tracks).count -eq 1){
            $last_Track = (($current_playlist.Playlist_Tracks.GetEnumerator()) | where {$_.value.id -eq $last_played.mediaid})
            <#            $last_track_index = $current_playlist.Playlist_Tracks.values.id.indexof($last_played.mediaid)
                if($last_track_index -ne -1){
                $last_Track = $current_playlist.Playlist_Tracks[$last_track_index]
            }#>
            $last_track_index = $last_Track.key
            if($thisApp.Config.Dev_mode){write-ezlogs ">>>> Last Track key: $($last_track_index)`n| Last Track: $($last_Track.value.title | out-string)" -showtime -Dev_mode}
            if(-not [string]::IsNullOrEmpty($last_Track)){ 
              if($thisApp.config.Shuffle_Playback){
                try{
                  write-ezlogs "| Getting random item from Playlist $($current_playlist.name)" -showtime -LogLevel 2
                  $next_item = ($current_playlist.Playlist_Tracks.GetEnumerator() | Where-Object {$_.key -ne $last_track_index -and $thisApp.config.History_Playlist.values -notcontains $_.value.id} | Get-Random -Count 1).value
                  #$next_item = (($current_playlist.Playlist_Tracks.GetEnumerator()) | where-Object {$_.key -eq $playlist_index_toget -and $thisApp.config.History_Playlist.values -notcontains $_.value.id}).value
                }catch{
                  write-ezlogs "An exception occurred getting random item from Playlist $($current_playlist.name)" -showtime -catcherror $_
                }
              }else{  
                $Maxindex = ($current_playlist.Playlist_Tracks.keys | Measure-Object -Maximum).Maximum
                write-ezlogs "| Looking for next track in playlist - last_track_index: $last_track_index - MaxIndex: $MaxIndex"
                if($last_track_index -ge $Maxindex){
                  write-ezlogs "| No more tracks found in playlist - moving on - Last Track Index: $($last_track_index) - Max index: $($Maxindex)"
                }else{
                  #$last_track_index++
                  #TODO: A while loop especially on main UI thread is likely risky and def a better way to do this. Wouldnt be needed if index/key were always sequential
                  $playlist_index_toget = $Null
                  while($playlist_index_toget -eq $null -and $last_track_index -lt $Maxindex){
                    $last_track_index++
                    $playlist_index_toget = $current_playlist.Playlist_Tracks.keys | where-Object {$_ -eq $last_track_index}
                  }
                  if(-not [string]::IsNullOrEmpty($playlist_index_toget)){ 
                    write-ezlogs "| Getting next playlist item with index $($playlist_index_toget) from Playlist $($current_playlist.name)" -showtime -LogLevel 2
                    $next_item = $current_playlist.Playlist_Tracks[$playlist_index_toget]
                  }     
                }                                                                        
              }
            }         
          }else{
            write-ezlogs "Still Returned multiple playlists that contain media id $($last_played.mediaid)!" -showtime -warning -LogLevel 2
          }
        }else{
          write-ezlogs "| No playlist found containing media with id: $($last_played.mediaid)"
        }
      } 
      
      if(!$next_item -and $Synchash.Current_Playing_Playlist_Source -eq 'Library'){
        write-ezlogs ">>>> No more media was found in the custom playlist, looking for next item in the media library playlists" -showtime -LogLevel 2
        #Next Media Library Item
        if($last_played.media.source -eq 'Spotify'){
          $current_Playing_Library = $synchash.All_Spotify_Media.where({$_.playlist_id -eq $last_played.media.playlist_id -and $_.playlist -eq $last_played.media.playlist})
          if(!$current_Playing_Library -and $Synchash.Current_Playing_Playlist){
            write-ezlogs "Looking for library playlists matching current_playing_Playlist: $($Synchash.Current_Playing_Playlist)" -loglevel 2
            $current_Playing_Library = $synchash.All_Spotify_Media.where({$_.playlist_id -eq $Synchash.Current_Playing_Playlist}) 
          } 
        }elseif($last_played.media.source -eq 'Youtube'){         
          $current_Playing_Library = $synchash.All_Youtube_Media.where({$_.playlist_id -eq $last_played.media.playlist_id -and $_.playlist -eq $last_played.media.playlist})
          if(!$current_Playing_Library -and $Synchash.Current_Playing_Playlist){
            write-ezlogs "Looking for library playlists matching current_playing_Playlist: $($Synchash.Current_Playing_Playlist)" -loglevel 2
            $current_Playing_Library = $synchash.All_Youtube_Media.where({$_.playlist_id -eq $Synchash.Current_Playing_Playlist}) 
          } 
        }      
        if($current_Playing_Library){
          $current_Playing_Library_Playlist = $current_Playing_Library.playlist | Select-Object -unique
          if(@($current_Playing_Library_Playlist).count -gt 1){
            write-ezlogs "Returned multiple playlists that contain media id $($last_played.mediaid) - Playlists: $($current_Playing_Library_Playlist | out-string)" -warning -showtime -LogLevel 2
            #TODO: What to do about it then?           
          }    
          if(@($current_Playing_Library).count -ge 1){
            $last_Track = (($current_Playing_Library.GetEnumerator()) | where-Object {$_.id -eq $last_played.mediaid})
            if($last_Track){
              try{
                $last_track_index = $current_Playing_Library.IndexOf($last_Track)
                $last_track_index++
              }catch{
                write-ezlogs "An exception occurred getting index of last track $($last_Track)" -showtime -catcherror $_
              }
            }
            write-ezlogs ">>>> Last Track Index: $($last_track_index)`n| Last Track: $($last_Track.title | out-string)" -showtime -LogLevel 3
            if(-not [string]::IsNullOrEmpty($last_track_index)){ 
              if($thisApp.config.Shuffle_Playback){
                try{
                  write-ezlogs " | Getting random item from Playlist $($current_Playing_Library_Playlist)" -showtime -LogLevel 2
                  $next_item = $current_Playing_Library | where {$_.id -ne $last_Track.id -and $thisApp.config.History_Playlist.values -notcontains $_.id} | Get-Random -Count 1
                }catch{
                  write-ezlogs "An exception occurred getting random item from Playlist $($current_Playing_Library_Playlist)" -showtime -catcherror $_
                }
              }else{                                                            
                write-ezlogs " | Getting next playlist item with index $($last_track_index) from Playlist $($current_Playing_Library_Playlist)" -showtime -LogLevel 2
                $next_item = $current_Playing_Library[$last_track_index]                     
              }
            }else{
              write-ezlogs "Unable to find last track index, Unable to find any more media within media library playlist $($current_Playing_Library_Playlist)!" -showtime -warning -LogLevel 2
            }         
          }else{
            write-ezlogs "Unable to find any more media within media library playlist $($current_Playing_Library_Playlist)!" -showtime -warning -LogLevel 2
          }
        }       
      }                                   
      if($next_item){
        if(-not [string]::IsNullOrEmpty($next_item.id)){
          $next_selected.media = $next_item
        }else{
          #Look for local media         
          $next_selected.media = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_ID $next_item
        }
        #Look for in playlist cache
        if(!$next_selected.media){
          write-ezlogs "Unable to find media $($next_item) in libraries, checking playlist profiles" -showtime -warning -LogLevel 2
          if(!$synchash.all_playlists -and [System.IO.File]::Exists($thisApp.Config.Playlists_Profile_Path)){
            if($thisApp.Config.Verbose_logging){write-ezlogs " | Importing All Playlist Cache: $($thisApp.Config.Playlists_Profile_Path)" -showtime -enablelogs}
            $Available_Playlists = Import-SerializedXML -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist
          }elseif($synchash.all_playlists){
            $Available_Playlists = [System.Collections.Generic.List[Playlist]]::new($synchash.all_playlists)
          }
          if($Available_Playlists.PlayList_tracks.values | where {$_.id -eq $next_item}){                     
            $next_selected.media = $Available_Playlists.PlayList_tracks.values.where({$_.id -eq $next_item}) | Select-Object -First 1
            write-ezlogs " | Found next media in Playlist cache ($($next_selected.media.playlist)) - meaning its missing from primary media profiles!" -showtime -warning -LogLevel 2
            if($next_selected.media.Source -match 'Youtube'){
              try{  
                write-ezlogs " | Adding next media to Youtube media profiles" -showtime -LogLevel 2 -logtype Youtube
                $Link = $next_selected.media.url 
                if(-not [string]::IsNullOrEmpty($Link) -and (Test-url $Link)){
                  if($Link -match 'twitch.tv'){
                    $twitch_channel = $((Get-Culture).textinfo.totitlecase(($Link | split-path -leaf).tolower()))
                    write-ezlogs ">>>> Adding Twitch channel $twitch_channel - $Link" -showtime -color cyan -LogLevel 2 -logtype Twitch  
                    Import-Twitch -Twitch_URL $Link -verboselog:$thisApp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -use_runspace                  
                  }elseif($Link -match 'youtube\.com' -or $Link -match 'youtu\.be'){
                    write-ezlogs ">>>> Adding Youtube link $Link" -showtime -color cyan -LogLevel 2 -logtype Youtube
                    Import-Youtube -Youtube_URL $Link -verboselog:$thisApp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -use_runspace 
                  }                      
                }else{
                  write-ezlogs "The provided URL is not valid or was not provided! -- $Link" -showtime -warning -LogLevel 2 -logtype Youtube
                }                        
              }catch{
                write-ezlogs "An exception occurred adding media $($next_selected.media.title) with Import-Youtube" -showtime -catcherror $_
              }
            } 
          }elseif($next_selected.media.Source -eq 'Twitch'){
            try{  
              write-ezlogs " | Adding next media to Twitch media profiles" -showtime -LogLevel 2 -logtype Twitch
              $Link = $next_selected.media.url 
              if(-not [string]::IsNullOrEmpty($Link) -and (Test-url $Link)){
                if($next_selected.media.Channel_Name){
                  $twitch_channel = $next_selected.media.Channel_Name
                }elseif($Link -match 'twitch.tv'){
                  $twitch_channel = $((Get-Culture).textinfo.totitlecase(($Link | split-path -leaf).tolower()))
                  write-ezlogs ">>>> Adding Twitch channel $twitch_channel - $Link" -showtime -color cyan -LogLevel 2 -logtype Twitch                     
                }
                Import-Twitch -Twitch_URL $Link -verboselog:$thisApp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -use_runspace       
              }else{
                write-ezlogs "The provided URL is not valid or was not provided! -- $Link" -showtime -warning -LogLevel 2 -logtype Twitch
              }                        
            }catch{
              write-ezlogs "An exception occurred adding media $($next_selected.media) with Import-Twitch" -showtime -catcherror $_
            }
          }            
        }                                        
      }else{
        write-ezlogs " | No other media is queued to play" -showtime -LogLevel 2
        $synchash.Spotify_Status = 'Stopped'
        if($synchash.MiniPlayer_Media_Length_Label){
          $synchash.MiniPlayer_Media_Length_Label.Content = "00:00:00"
        }
        if($Synchash.Timer.isEnabled){
          $Synchash.Timer.stop()
        }
        if($syncHash.StopButton_Button){
          $peer = [System.Windows.Automation.Peers.ButtonAutomationPeer]($syncHash.StopButton_Button)
          $invokeProv = $peer.GetPattern([System.Windows.Automation.Peers.PatternInterface]::Invoke)
          $invokeProv.Invoke()
        }
        $synchash.Now_Playing_Title_Label.DataContext = 'No Media Queued'
        return            
      }               
    }catch{
      write-ezlogs "An exception occurred executing Next item events" -showtime -catcherror $_
    }  
    if(!$next_selected.media){
      write-ezlogs "Unable to get media information about next item $next_item!" -showtime -warning -LogLevel 2 -AlertUI   
      $synchash.Stop_media_timer.start()       
      return
    }else{
      #Look up media profile if we have one then play
      $MediaProfile = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_ID $next_selected.media.id
      if($MediaProfile){
        $Media = $MediaProfile
      }else{
        $Media = $next_selected.media
      }
      write-ezlogs " | Next to play is $($Media.title) - ID $($Media.id)" -showtime -LogLevel 2
      Add-Member -InputObject $thisApp.config -Name 'Last_Played' -Value ($Media.id) -MemberType NoteProperty -Force
      $synchash.Current_playing_media = $Media
      if($Media.source -eq 'Spotify' -or $Media.url -match 'spotify\:'){
        Start-SpotifyMedia -Media $Media -thisApp $thisApp -synchash $synchash -use_WebPlayer:$thisapp.config.Spotify_WebPlayer -Show_notifications:$thisApp.config.Show_notifications -RestrictedRunspace:$thisapp.config.Spotify_WebPlayer     
      }elseif($Media.id){
        if(Get-Process -Name 'Spotify*' -ErrorAction SilentlyContinue){
          write-ezlogs "Spotify is running, closing it" -showtime -warning -LogLevel 2
          Get-Process -Name 'Spotify*' | Stop-Process -Force -ErrorAction SilentlyContinue
        }
        Start-Media -Media $Media -thisApp $thisapp -synchashWeak ([System.WeakReference]::new($synchash)) -Show_notification
      }else{
        write-ezlogs "Unable to determine the type of the next media to play: $($Media | out-string)" -warning
      }
    }
  }catch{
    write-ezlogs 'An exception occurred in Skip-Media' -showtime -catcherror $_    
  }finally{
    $synchash.SkipMedia_isExecuting = $false
  }
}
#---------------------------------------------- 
#endregion Skip-Media Function
#----------------------------------------------
Export-ModuleMember -Function @('Skip-Media')