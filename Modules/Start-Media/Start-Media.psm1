<#
    .Name
    Start-Media

    .Version 
    0.1.0

    .SYNOPSIS
    Plays provided media files within vlc controls  

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
#region Start-Keywatcher Function
#----------------------------------------------
function Start-KeyWatcher{
  param (
    $Media,
    $synchash,
    $all_playlists,
    $Script_Modules,
    $PlayMedia_Command,
    $thisApp
  )
  
  $keyboard_Watcher_ScriptBlock = {
    $volumeup_key = [Byte]175    
    $volumedown_key = [Byte]174
    $volumeMute = [Byte]173
    $nexttrack = [Byte]176
    $previoustrack = [Byte]177
    $mediastop = [Byte]178
    $mediaplaypause = [Byte]179
    $Signature = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
    public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@
    Add-Type -MemberDefinition $Signature -Name Keyboard -Namespace PsOneApi
    do
    {
      $volumeup = [bool]([PsOneApi.Keyboard]::GetAsyncKeyState($volumeup_key) -eq -32767)
      if($volumeup){
        write-ezlogs "Volume Up received" -showtime
        write-ezlogs " | Volume: $($synchash.vlc.volume)" -showtime     
      }
      $volumedown =[bool]([PsOneApi.Keyboard]::GetAsyncKeyState($volumedown_key) -eq -32767)
      if($volumedown){
        write-ezlogs "Volume Down received" -showtime
        write-ezlogs " | Volume: $($synchash.vlc.volume)" -showtime       
      }  
      $mute = [bool]([PsOneApi.Keyboard]::GetAsyncKeyState($volumeMute) -eq -32767)
      if($mute){
        write-ezlogs "Mute received" -showtime
        $synchash.Window.Dispatcher.invoke([action]{  
            $synchash.vlc.ToggleMute()
        })         
      }      
      $next = [bool]([PsOneApi.Keyboard]::GetAsyncKeyState($nexttrack) -eq -32767)
      if($next){
        $next_selected = $Null
        $next_selected = [hashtable]::Synchronized(@{}) 
        $last_played = [hashtable]::Synchronized(@{})     
        write-ezlogs "[Start-KeyWatcher] >>>> Next keypress received" -showtime -color cyan
        $current_track = (Get-CurrentTrack -ApplicationName $thisApp.config.App_Name) 
        if($current_track){
          $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
        }
        try{     
          if($current_track.is_playing){
            $last_played.mediaid = $thisApp.config.Last_Played
            if($devices){
              if($thisApp.config.Use_Spicetify){
                try{
                  write-ezlogs "[NEXT_KEYPRESS] Stopping Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -color cyan
                  Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing  
                  $thisApp.Config.Spicetify = ''
                }catch{
                  write-ezlogs "[NEXT_KEYPRESS] An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE' -- forcing Spotify to close (Nuclear option I know)" -showtime -catcherror $_
                  if(Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue){
                    Get-Process -Name 'Spotify' | Stop-Process -Force -ErrorAction SilentlyContinue
                  } 
                  $thisApp.Config.Spicetify = ''            
                }
              }else{
                write-ezlogs "[NEXT_KEYPRESS] Stopping Spotify playback with Suspend-Playback -ApplicationName $($thisApp.config.App_Name) -DeviceId $($devices.id) " -showtime -color cyan
                $thisApp.Config.Spicetify = ''
                Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id   
              }
            }          
            $synchash.Spotify_Status = 'Stopped'  
          }
        }catch{
          write-ezlogs "[NEXT_KEYPRESS] An exception occurred stopped Spotify" -showtime -catcherror $_
        }      
        try{                          
          write-ezlogs "[NEXT_KEYPRESS] >>>> Stopping tick timer" -showtime
          $synchash.Window.Dispatcher.invoke([action]{ 
              $Synchash.Timer.stop()
          })                  
          if($synchash.vlc.IsPlaying){
            $last_played.mediaid = $thisApp.config.Last_Played
            $synchash.VLC.stop()
          }             
          if([System.IO.File]::Exists($thisApp.Config.Config_Path)){
            $thisApp.config = Import-Clixml -Path $thisApp.Config.Config_Path
            if($thisApp.Config.Verbose_logging){write-ezlogs "[NEXT_KEYPRESS] | Importing config file $($thisApp.Config.Config_Path)" -showtime}
            if(($thisApp.config.Current_Playlist.GetType()).name -notmatch 'OrderedDictionary'){$thisApp.config.Current_Playlist = ConvertTo-OrderedDictionary -hash ($thisApp.config.Current_Playlist)}
          }       
          if($last_played.mediaid -and $thisApp.config.Current_Playlist.values -contains $last_played.mediaid){
            try{
              $index_toremove = $thisApp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $last_played.mediaid} | select * -ExpandProperty key 
              if(($index_toremove).count -gt 1){
                if($thisApp.Config.Verbose_logging){write-ezlogs "[NEXT_KEYPRESS] | Found multiple items in Play Queue matching id $($last_played.mediaid) - $($index_toremove | out-string)" -showtime -warning}
                foreach($index in $index_toremove){
                  $null = $thisApp.config.Current_Playlist.Remove($index) 
                }  
              }else{
                write-ezlogs "[NEXT_KEYPRESS] | Removing $($last_played.mediaid) from Play Queue" -showtime
                $null = $thisApp.config.Current_Playlist.Remove($index_toremove)
              }                               
            }catch{
              write-ezlogs "[NEXT_KEYPRESS] An exception occurred updating current config queue playlist" -showtime -catcherror $_
            }                          
            $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8
          }  
          if($thisApp.config.Shuffle_Playback){
            write-ezlogs "[NEXT_KEYPRESS] Getting random item from queue" -showtime
            $next_item = $thisApp.config.Current_Playlist.values | Get-Random -Count 1        
          }else{
            $index_toget = ($thisApp.config.Current_Playlist.keys | measure -Minimum).Minimum 
            write-ezlogs "[NEXT_KEYPRESS] Getting next item with index $($index_toget)" -showtime
            $next_item = (($thisApp.config.Current_Playlist.GetEnumerator()) | where {$_.name -eq $index_toget}).value              
          }  
          if(!$next_item){
            if($thisApp.Config.Verbose_logging){write-ezlogs "[NEXT_KEYPRESS] Attempting to get next item from current_playlist using select -first 1" -showtime -warning}
            $next_item = $thisApp.config.Current_Playlist.values | select -first 1
          }                           
          if($next_item){
            write-ezlogs "[NEXT_KEYPRESS] | Next queued item is $($next_item)" -showtime
            foreach($item in $Datatable.datatable){
              if($item.id -eq $next_item){
                $next_selected.media = $item
              }
            }
            if(!$next_selected.media){
              foreach($item in $Youtube_Datatable.datatable){
                if($item.id -eq $next_item){
                  $next_selected.media = $item
                }
              }               
              #$next_selected = $synchash.SpotifyTable.Items | where {$_.encodedtitle -eq $next_item}
            }                
            #$next_selected = $synchash.MediaTable.items | where {$_.id -eq $next_item}
            if(!$next_selected.media){
              foreach($item in $Spotify_Datatable.datatable){
                if($item.id -eq $next_item){
                  $next_selected.media = $item
                }
              }               
              #$next_selected = $synchash.SpotifyTable.Items | where {$_.encodedtitle -eq $next_item}
            }          
          }else{
            write-ezlogs "[NEXT_KEYPRESS] | No other media is queued to play" -showtime
            $synchash.Spotify_Status = 'Stopped'
            $synchash.Window.Dispatcher.invoke([action]{ 
                $synchash.update_status_timer.start()
            })                     
            return            
          }               
        }catch{
          write-ezlogs "[NEXT_KEYPRESS] An exception occurred executing Next item events" -showtime -catcherror $_
        }  
        if(!$next_selected.media){
          write-ezlogs "[NEXT_KEYPRESS] | Unable to get media information about next item $next_item!" -showtime -warning
          return
        }else{
          write-ezlogs "[NEXT_KEYPRESS] | Next to play is $($next_selected.media.title) - ID $($next_selected.media.id)" -showtime
          Add-Member -InputObject $thisApp.config -Name 'Last_Played' -Value ($next_selected.media.id) -MemberType NoteProperty -Force
          if($next_selected.media.Spotify_Path){
            $thisApp.Config.Spicetify.is_paused = $true
            Play-SpotifyMedia -Media $next_selected.media -thisApp $thisApp -synchash $synchash                                       
          }elseif($next_selected.media.id){
            if(Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue){
              Get-Process -Name 'Spotify' | Stop-Process -Force -ErrorAction SilentlyContinue
            }                   
            Start-Media -media $next_selected.media -thisApp $thisApp -synchash $synchash -PlayMedia_Command $PlayMedia_Command -Show_notification -all_playlists $all_playlists
          }
        }  
        $next_selected = $null                   
      }         
      $previous = [bool]([PsOneApi.Keyboard]::GetAsyncKeyState($previoustrack) -eq -32767)
      $stop =  [bool]([PsOneApi.Keyboard]::GetAsyncKeyState($mediastop) -eq -32767)
      if($stop){
        write-ezlogs "Stop received" -showtime
        $synchash.Window.Dispatcher.invoke([action]{     
            try{
              if($synchash.vlc.IsPlaying){
                $synchash.VLC.stop()
              }else{
                $current_track = (Get-CurrentTrack -ApplicationName $thisApp.config.App_Name) 
              }
              if($current_track.is_playing){
                $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
                if($devices){
                  write-ezlogs "[STOP_KEYPRESS] Stoping Spotify playback" -showtime -color cyan
                  Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id   
                }  
              }  
              if($synchash.timer.Enabled){
                $Synchash.Timer.stop()
              }
            }catch{
              write-ezlogs "[STOP_KEYPRESS] An exception occurred executing Stop events" -showtime -catcherror $_
            }             
        })        
      }   
      $playpause = [bool]([PsOneApi.Keyboard]::GetAsyncKeyState($mediaplaypause) -eq -32767)
      if($playpause){
        write-ezlogs "[PLAYPAUSE_KEYPRESS] Play Pause received" -showtime
        $synchash.Window.Dispatcher.invoke([action]{ 
            if($synchash.timer.Enabled){
              $Synchash.Timer.stop()
            }
        })         
        $current_track = (Get-CurrentTrack -ApplicationName $thisApp.config.App_Name) 
        try{     
          if($current_track.is_playing){
            $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
            if($devices){
              write-ezlogs "[PLAYPAUSE_KEYPRESS] >>>> Stoping Spotify playback" -showtime -color cyan 
              $synchash.Window.Dispatcher.invoke([action]{ 
                  if($synchash.timer.Enabled){
                    $Synchash.Timer.stop()
                  }
              }) 
              Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id                              
            }  
          }elseif($null -ne $current_track.currently_playing_type){
            $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
            if($devices){
              write-ezlogs "[PLAYPAUSE_KEYPRESS] >>>> Resuming Spotify playback" -showtime -color cyan
              Resume-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id 
              $synchash.Window.Dispatcher.invoke([action]{ 
                  $Synchash.Timer.Start()
              })  
            }
          }
          $synchash.Window.Dispatcher.invoke([action]{ 
              try{
                if($synchash.VLC.state -match 'Playing' -and !$current_track.is_playing -and !$current_track.currently_playing_type){
                  write-ezlogs "[PLAYPAUSE_KEYPRESS] >>>> Pausing Vlc playback" -showtime -color cyan
                  $synchash.Now_Playing_Label.content = ($synchash.Now_Playing_Label.content) -replace 'Now Playing', 'Paused'
                  if($synchash.timer.Enabled){
                    $Synchash.Timer.stop()
                  }
                  $synchash.VLC.pause()
                }elseif(!$current_track.is_playing -and !$current_track.currently_playing_type){      
                  write-ezlogs "[PLAYPAUSE_KEYPRESS] >>>> Resuming Vlc playback" -showtime -color cyan        
                  $synchash.Now_Playing_Label.content = ($synchash.Now_Playing_Label.content) -replace 'Paused', 'Now Playing'
                  $Synchash.Timer.Start()
                  $synchash.VLC.pause()
                }     
              }catch{
                write-ezlogs "[PLAYPAUSE_KEYPRESS] An exception occurred executing Play/Pause events" -showtime -catcherror $_
              } 
          })                   
        }catch{
          write-ezlogs "[PLAYPAUSE_KEYPRESS] An exception occurred in play/pause" -showtime -catcherror $_
        }       
      }   
      Start-Sleep -Milliseconds 10 
    } while($true)  
    write-ezlogs "Keywatcher has ended!" -showtime -warning
  }
  $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
  Start-Runspace $keyboard_Watcher_ScriptBlock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Keyboard Watcher" -thisApp $thisapp -No_Cancel_Existing -Script_Modules $Script_Modules

}
#---------------------------------------------- 
#endregion Start-Keywatcher Function
#----------------------------------------------

#---------------------------------------------- 
#region Start-Media Function
#----------------------------------------------
function Start-Media{
  [CmdletBinding()]
  param (
    $Media,
    $synchash,
    $Media_ContextMenu,
    $PlayMedia_Command,
    $PlaySpotify_Media_Command,
    $thisApp,
    $all_playlists,
    [switch]$Show_notifications = $thisApp.Config.Show_notifications,
    $Script_Modules,
    [switch]$Verboselog
  )

  $mediatitle = $($Media.title)
  #$encodedtitle = $media.id
  $artist = $Media.Artist
  $url = $($Media.url)
  write-ezlogs "[START_MEDIA] >>>> Selected Media to play $($mediatitle)" -showtime
  if($thisApp.Config.Verbose_logging){
    write-ezlogs "[START_MEDIA] Media to play: $($media | out-string)" -showtime
  }
  $thisapp.Config.streamlink = ''
  Add-Member -InputObject $thisApp.config -Name 'streamlink' -Value '' -MemberType NoteProperty -Force  
  if($synchash.VLC.state -eq 'Playing'){
    $synchash.VLC.stop()
  }
  $Synchash.Timer.stop()
  if($thisApp.config.Use_Spicetify -and (Get-Process -Name 'Spotify*') -and $synchash.Spotify_Status -ne 'Stopped'){
    try{
      #start-sleep 1
      write-ezlogs "[START_MEDIA] Stopping Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -color cyan
      Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing  
      $thisApp.Config.Spicetify = ''
    }catch{
      write-ezlogs "[START_MEDIA] An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -catcherror $_
      if(Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue){
        Get-Process -Name 'Spotify' | Stop-Process -Force -ErrorAction SilentlyContinue
      }  
      $thisApp.Config.Spicetify = ''   
      $synchash.Spotify_Status = 'Stopped'        
    }
  }elseif(($synchash.current_track_playing.is_playing -or $synchash.Spotify_Status -ne 'Stopped' ) -and (Get-Process -Name 'Spotify*')){
    try{
      $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
      if($devices){
        write-ezlogs "[START_MEDIA] Stopping Spotify playback with Suspend-Playback" -showtime -color cyan
        Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id
      }else{
        write-ezlogs "[START_MEDIA] Couldnt get Spotify Device id, using nuclear option and force stopping Spotify process" -showtime -warning
        if(Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue){
          Get-Process -Name 'Spotify' | Stop-Process -Force -ErrorAction SilentlyContinue
        }            
      }           
    }catch{
      write-ezlogs "[START_MEDIA] An exception occurred executing Suspend-Playback" -showtime -catcherror $_
      if(Get-Process -Name 'Spotify' -ErrorAction SilentlyContinue){
        Get-Process -Name 'Spotify' | Stop-Process -Force -ErrorAction SilentlyContinue
      }             
    }
    $synchash.Spotify_Status = 'Stopped'  
    $synchash.current_track_playing = $Null       
  }  
    
  if(!$Media -and $synchash.Media_URL.text){
    $media_link = $($synchash.Media_URL.text).trim()
  }elseif(-not [string]::IsNullOrEmpty($url)){
    $media_link = $($url).trim()
  }
  try{
    $existingitems = $null
    [array]$existingitems = $thisApp.config.Current_Playlist.values
    if($thisApp.config.Current_Playlist){
      if(($thisApp.config.Current_Playlist.GetType()).name -notmatch 'OrderedDictionary'){
        if($thisApp.Config.Verbose_logging){write-ezlogs "[Start-Media] Current_playlist not orderedictionary $(($thisApp.config.Current_Playlist.GetType()).name) - converting"  -showtime -warning}
        $thisApp.config.Current_Playlist = ConvertTo-OrderedDictionary -hash ($thisApp.config.Current_Playlist)
      } 
    }else{
      $thisApp.config.Current_Playlist = [System.Collections.Specialized.OrderedDictionary]::new()
    }           
    if($thisApp.config.Current_Playlist.values -notcontains $media.id){
      $null = $thisApp.config.Current_Playlist.clear()
      $index = 0
      write-ezlogs "[Start-Media] | Adding $($media.id) to Play Queue" -showtime
      $null = $thisApp.config.Current_Playlist.add($index,$media.id)  
      foreach($id in $existingitems){
        $index = ($thisApp.config.Current_Playlist.keys | measure -Maximum).Maximum
        $index++
        $null = $thisApp.config.Current_Playlist.add($index,$id)
      }       
    }   
    if($media.type -eq 'YoutubePlaylist_item' -and @($synchash.YoutubeTable.SelectedItems).count -gt 1){
      foreach($item in $synchash.YoutubeTable.SelectedItems | where {$_.id -ne $media.id}){
        if($thisApp.config.Current_Playlist.values -notcontains $item.id){
          write-ezlogs "[Start-Media] | Adding Youtube selected item $($item.id) to Play Queue" -showtime
          $index = ($thisApp.config.Current_Playlist.keys | measure -Maximum).Maximum
          $index++
          $null = $thisApp.config.Current_Playlist.add($index,$item.id) 
        }
      }   
    }elseif($media.id -and @($synchash.MediaTable.SelectedItems).count -gt 1){
      foreach($item in $synchash.MediaTable.SelectedItems | where {$_.id -ne $media.id}){
        if($thisApp.config.Current_Playlist.values -notcontains $item.id){
          write-ezlogs "[Start-Media] | Adding MediaTable selected item $($item.id) to Play Queue" -showtime
          $index = ($thisApp.config.Current_Playlist.keys | measure -Maximum).Maximum
          $index++
          $null = $thisApp.config.Current_Playlist.add($index,$item.id)        
        }
      }                   
    }  
    $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8
    #$synchash.update_status_timer.start()
    #Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -thisApp $thisApp -media_contextMenu $Media_ContextMenu -PlayMedia_Command $PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists

  }catch{
    write-ezlogs "[START_MEDIA] An exception occurred updating current_playlist" -showtime -catcherror $_
  }
  if($media.webpage_url -match 'twitch'){
  
    if($Media.chat_url){
      $chat_url = $Media.chat_url
    }elseif($media.webpage_url -match 'twitch'){      
      $chat_url = "$($media.webpage_url)/chat"
    }else{
      $chat_url = $null
    }            
  }else{
    #$synchash.Chat_View.Visibility = 'Hidden'
    $synchash.Chat_View_Button.IsEnabled = $false 
    $synchash.Chat_View_Button.Opacity=0.7 
    $synchash.Chat_View_Button.ToolTip="Chat View Not Available"
    $synchash.Chat_Icon.Kind="ChatRemove"  
    $synchash.chat_column.Width = "*"
    $synchash.chat_WebView2.Visibility = 'Hidden'
    $synchash.chat_WebView2.stop()
  }
  $vlc_scriptblock = {  
    $youtubedl_path = "$($thisApp.config.Current_folder)\Resources\youtube-dl"
    $env:Path += ";$youtubedl_path"         
    if($media.type -eq 'YoutubePlaylist_item'){
      $delay = $null
      if($media.webpage_url -match 'twitch.tv'){
        $streamlink_wait_timer = 0
        $twitch_channel = $((Get-Culture).textinfo.totitlecase(($media.webpage_url | split-path -leaf).tolower()))
        #$streamlink_fetchjson = streamlink $media.webpage_url --loglevel info --logfile $streamlink_log --json
        $TwitchAPI = Get-TwitchAPI -StreamName $twitch_channel -thisApp $thisApp
        if($TwitchAPI){
          $thisApp.Config.streamlink = $TwitchAPI #$streamlink_fetchjson | convertfrom-json
        }                
        $streamlink_log = "$env:temp\EZT-MediaPlayer\streamlink.log"
        try{       
          if(!$TwitchAPI.type){
            write-ezlogs "[START_MEDIA] Twitch Channel $twitch_channel`: OFFLINE" -showtime -warning
            Update-Notifications -Level 'WARNING' -Message "Twitch Channel $twitch_channel`: OFFLINE" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
            Add-Member -InputObject $media -Name 'Live_Status' -Value 'Offline' -MemberType NoteProperty -Force
            Add-Member -InputObject $media -Name 'Status_msg' -Value '' -MemberType NoteProperty -Force
            Add-Member -InputObject $media -Name 'Stream_title' -Value "" -MemberType NoteProperty -Force          
            $synchash.Window.Dispatcher.invoke([action]{ 
                $Synchash.Timer.stop() 
                $synchash.Now_Playing_Label.content = ""                     
            }.GetNewClosure())     
            return
          }else{
            write-ezlogs "[START_MEDIA] Starting streamlink $($media.webpage_url)" -showtime
            Add-Member -InputObject $Media -Name 'Live_Status' -Value $TwitchAPI.type -MemberType NoteProperty -Force
            Add-Member -InputObject $media -Name 'Status_msg' -Value "- $($TwitchAPI.game_name)" -MemberType NoteProperty -Force  
            Add-Member -InputObject $media -Name 'Stream_title' -Value "$($TwitchAPI.title)" -MemberType NoteProperty -Force       
            $streamlinkblock = {
              $streamlink = streamlink $media.webpage_url "best,720p,480p" --player-external-http --player-external-http-port 53828 --loglevel info --logfile $streamlink_log --retry-streams 2 --twitch-disable-ads
            }
            $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
            Start-Runspace $streamlinkblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Streamlink HTTP Runspace" -thisApp $thisApp -Script_Modules $Script_Modules            
            
          }
          $Playlist_profile = $all_playlists.playlists | where {$_.Playlist_tracks.id -eq $media.id}         
          foreach($track in $Playlist_profile.Playlist_tracks){
            if($track.id -eq $media.id){
              $track.title = $Media.Title
              $track.Status_msg = $Media.Status_msg
              $track.Live_Status = $Media.Live_Status
              Add-Member -InputObject $track -Name 'Stream_title' -Value "$($Media.Stream_title)" -MemberType NoteProperty -Force 
              if($thisApp.Config.Verbose_logging){write-ezlogs "[START_MEDIA] >>>> Updating track $($track.title) in playlist $($Playlist_profile.name)" -showtime -color cyan}
              if([System.IO.FIle]::Exists($track.Playlist_File_Path)){
                if($thisApp.Config.Verbose_logging){write-ezlogs "[START_MEDIA] >>>> Saving updated playlist profile from track profile: $($track.Playlist_File_Path)" -showtime -color cyan}
                $Playlist_profile | Export-Clixml $track.Playlist_File_Path -Force
              }elseif([System.IO.FIle]::Exists($Playlist_profile.Playlist_Path)){
                if($thisApp.Config.Verbose_logging){write-ezlogs ">>>> Saving updated playlist profile from playlist profile: $($Playlist_profile.Playlist_Path)" -showtime -color cyan}
                $Playlist_profile | Export-Clixml $Playlist_profile.Playlist_Path -Force 
              }         
            }
          }
          $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8                      
        }catch{
          write-ezlogs "[START_MEDIA] An exception occurred starting streamlink" -showtime -catcherror $_
        }        
        if($thisApp.Config.Verbose_logging){write-ezlogs "[START_MEDIA] Twitch API: $($thisApp.Config.streamlink | out-string)"}        
        #start-sleep 1
        while($streamlink_wait_timer -lt 60 -and !$thisApp.Config.streamlink -and !$(Get-Process *streamlink*)){
          $streamlink_wait_timer++
          write-ezlogs "[START_MEDIA] Waiting for streamlink process...." -showtime
          if($streamlink_wait_timer -eq 10){
            write-ezlogs "[START_MEDIA] >>>> Relaunching streamlink as it should have started by now" -showtime -color cyan
            $streamlink = streamlink $media.webpage_url "best,720p,480p" --player-external-http --player-external-http-port 53828 --loglevel info --logfile $streamlink_log --retry-streams 2 --twitch-disable-ads
          }
          start-sleep 1
        }
        if($streamlink_wait_timer -ge 60){
          write-ezlogs "[START_MEDIA] Timed out waiting for streamlink to start, falling back to yt-dlp" -showtime -warning
          $yt_dlp = yt-dlp -f b -g $media.webpage_url -o '*' -j --cookies-from-browser $thisApp.config.Youtube_Browser --add-header "Device-ID: twitch-web-wall-mason" --add-header "Authorization: ''" --sponsorblock-remove all 
          [Uri]$vlcurl = $yt_dlp[0]  
          $media_link = $vlcurl
        }elseif($media.live_status -eq 'Offline'){
          write-ezlogs "[START_MEDIA] Stream offline -- cannot continue" -showtime -warning
          return               
        }else{
          write-ezlogs "[START_MEDIA] >>>> Connecting to streamlink http://127.0.0.1:53828/" -showtime
          [Uri]$vlcurl = 'http://127.0.0.1:53828/'
          $media_link = $vlcurl                  
        }              
      }elseif($media.webpage_url){
        write-ezlogs "[START_MEDIA] | Getting best quality video and audio links from yt_dlp" -showtime 
        if(-not [string]::IsNullOrEmpty($thisApp.config.Youtube_Browser)){
          $yt_dlp = yt-dlp -f bestvideo+bestaudio/best -g $media.webpage_url -o '*' -j --cookies-from-browser $thisApp.config.Youtube_Browser --sponsorblock-remove all  
          #$yt_dlp = yt-dlp -f b -g $media.webpage_url -o '*' -j --cookies-from-browser $thisApp.config.Youtube_Browser
          #$yt_dlp = yt-dlp -f b -g $media.webpage_url -o '*' -j --cookies-from-browser $thisApp.config.Youtube_Browser --add-header "Device-ID: twitch-web-wall-mason" --add-header "Authorization: ''" --sponsorblock-remove all        
        }else{
          $yt_dlp = yt-dlp -f bestvideo+bestaudio/best -g $media.webpage_url -o '*' -j --sponsorblock-remove all  
          #$yt_dlp = yt-dlp -f b -g $media.webpage_url -o '*' -j --add-header "Device-ID: twitch-web-wall-mason" --add-header "Authorization: ''" --sponsorblock-remove all
        }  
        [Uri]$vlcurl = $yt_dlp[0]       
        [Uri]$video_url = $yt_dlp[0]
        [Uri]$audio_url = $yt_dlp[1] 
      }else{
        $vlcurl = $media_link
      }   
      $duration = $media.duration_ms
      $title = $media.title  
      #write-ezlogs "[START_MEDIA] | YoutubePlaylist_item Title: $title" -showtime    
    }elseif(Test-URL $Media_link -and ($media_link -match 'youtube' -or $media_link -match 'yewtu.be')){
      $delay = $null
      $media = yt-dlp -f b -g $media_link --rm-cache-dir -o '*' -j
      [Uri]$vlcurl = $media[0]
      $media_metadata = $media[1] | Convertfrom-json    
      $duration = $($([timespan]::Fromseconds($media_metadata.duration)).TotalMilliseconds)
      $title = $media_metadata.title
      write-ezlogs "[START_MEDIA] | Youtube URL Title: $title" -showtime
    }elseif($media_link -match 'streaming.mediaservices.windows.net'){
      $delay = -2000000
      $media = yt-dlp -f b -g $media_link --rm-cache-dir -o '*' -j
      if($verboselog){write-ezlogs "[START_MEDIA] | Media Metadata: $media" -showtime}     
      if(-not [string]::IsNullOrEmpty($media)){
        [Uri]$vlcurl = $media[0]
        $media_metadata = $media[1] | Convertfrom-json
        $duration = $media_metadata.duration
        $title = $media_metadata.title               
      }else{
        [Uri]$vlcurl = $($media_link)
        $title = $video.caption
        $duration = $media_metadata.duration
      }
    }elseif(Test-path -literalpath $Media_link){
      [int]$length = $([System.TimeSpan]::Parse($media.duration).TotalSeconds)
      $timespan = $([timespan]::FromSeconds($length))
      $duration = $timespan.TotalMilliseconds    
      [Uri]$vlcurl = $($media_link)
      $title = "$mediatitle - $Artist"
      write-ezlogs "[START_MEDIA] | Local Path Title: $title" -showtime
      $delay = $null
    }elseif(Test-URL $Media_link){
      $delay = $null
      [Uri]$vlcurl = $($media_link)
      $duration = $null
      $title = $media.title
      write-ezlogs "[START_MEDIA] | URL Media Title: $title" -showtime
    }else{
      $delay = $null
      [Uri]$vlcurl = $($media_link)
      $duration = $null
      $title = $media.title
      write-ezlogs "[START_MEDIA] | Uknown media type Title: $title" -showtime
      Update-Notifications -Level 'ERROR' -Message "[START_MEDIA] Unknown media or path is not available: $vlcurl" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
      return      
    }    
    try{     
      Import-Module "$($thisApp.Config.Current_Folder)\\Modules\\Get-HelperFunctions\\Get-HelperFunctions.psm1"           
   
      $synchash.Window.Dispatcher.invoke([action]{   
          $a = 0
          $c = 0
          #Import-Module "$($thisApp.Config.Current_Folder)\\Modules\\Get-HelperFunctions\\Get-HelperFunctions.psm1"
          #write-ezlogs " | Media link $($media_link | out-string)" -showtime             
          $synchash.Media_URL.text = $media_link                           
          if($delay){
            $synchash.vlc.SetAudioDelay(-2000000)
          }              
          $synchash.MediaPlayer_Slider.Maximum = $([timespan]::FromMilliseconds($duration)).TotalSeconds 
          [int]$a = $($duration / 1000);
          $synchash.Now_Playing_Label.content = "Now Playing - $title"          
          [int]$c = $($([timespan]::FromSeconds($a)).TotalMinutes)     
          [int]$hrs = $($([timespan]::FromSeconds($a)).Hours)
          [int]$mins = $($([timespan]::FromSeconds($a)).Minutes)
          [int]$secs = $($([timespan]::FromSeconds($a)).Seconds)
          [int]$milsecs = $($([timespan]::FromSeconds($a)).Milliseconds)
          $total_time = "$hrs`:$mins`:$secs"      
          $synchash.Media_Length_Label.content = '0' + "/" + "$total_time"  
          $synchash.MediaPlayer_CurrentDuration = $total_time          
          if($video_url -and $audio_url){
            $libvlc_media = [LibVLCSharp.Shared.Media]::new([LibVLCSharp.Shared.LibVLC]::new(":input-slave=$($audio_url)"),[Uri]($video_url),[LibVLCSharp.Shared.FromType]::FromLocation,":input-slave=$($audio_url)")
          }elseif($vlcurl -or $media_link){
            if($media_link){
              if(Test-url $media_link){
                write-ezlogs "[START_MEDIA] | Medialink is URL link $media_link" -showtime
                $from_path = [LibVLCSharp.Shared.FromType]::FromLocation
              }else{
                write-ezlogs "[START_MEDIA] | Medialink is local path link $media_link" -showtime
                $from_path = [LibVLCSharp.Shared.FromType]::FromPath
              }
              $libvlc_media = [LibVLCSharp.Shared.Media]::new([LibVLCSharp.Shared.LibVLC]::new(),[Uri]($media_link),$from_path,$null)
            }else{
              if(Test-url $vlcurl){
                write-ezlogs "[START_MEDIA] | vlcurl is URL link $vlcurl" -showtime
                $from_path = [LibVLCSharp.Shared.FromType]::FromLocation
              }else{
                write-ezlogs "[START_MEDIA] | vlcurl is local path link $vlcurl" -showtime
                $from_path = [LibVLCSharp.Shared.FromType]::FromPath
              }            
              $libvlc_media = [LibVLCSharp.Shared.Media]::new([LibVLCSharp.Shared.LibVLC]::new(),[Uri]($vlcurl),$from_path,$null)
            }
          } 
          if(!$thisApp.Config.Use_HardwareAcceleration){
            write-ezlogs "[START_MEDIA] | Disabling Hardware Acceleration" -showtime
            $libvlc_media.AddOption(":avcodec-hw=none")
          }           
          $synchash.vlc.media = $libvlc_media 
                             
          $null = $synchash.VLC.Play()  

          Add-Member -InputObject $thisApp.config -Name 'Last_Played_title' -Value $title -MemberType NoteProperty -Force
          Add-Member -InputObject $thisApp.config -Name 'Last_Played' -Value $media.id -MemberType NoteProperty -Force              
          try{
            if(Test-URL $media.chat_url){
              if($thisApp.config.Chat_View){
                $synchash.chat_WebView2.Visibility = 'Visible'
                #$synchash.Chat_View.Visibility = 'Visible'   
                $synchash.Chat_Icon.Kind="Chat"
                $synchash.Chat_View_Button.Opacity=1
                $synchash.Chat_View_Button.ToolTip="Chat View"   
                $synchash.chat_column.Width = "400"        
              } 
              $synchash.Chat_View_Button.IsEnabled = $true   
              if($syncHash.chat_WebView2 -ne $null -and $syncHash.chat_WebView2.CoreWebView2 -ne $null){
                write-ezlogs "[START_MEDIA] Navigating with CoreWebView2.Navigate: $($chat_url)" -enablelogs -Color cyan -showtime
                $syncHash.chat_WebView2.CoreWebView2.Navigate($chat_url)
              }
              else{
                write-ezlogs "[START_MEDIA] Navigating with Source: $($chat_url)" -enablelogs -Color cyan -showtime
                $syncHash.chat_WebView2.source="https://twitch.tv/$($chat_url)/chat"
              }         
            }else{
              $synchash.Chat_View_Button.IsEnabled = $false    
              $synchash.chat_column.Width = "*"
              $synchash.Chat_Icon.Kind="ChatRemove"
              $synchash.Chat_View_Button.Opacity=0.7
              $synchash.Chat_View_Button.ToolTip="Chat View Not Available"
              $synchash.chat_WebView2.Visibility = 'Hidden'
              $synchash.chat_WebView2.stop()
            }                   
            [array]$media_queue = $syncHash.PlayQueue_TreeView.Items.Items.tag.Media
            foreach($id in $media_queue.id){
              if($thisApp.config.Current_Playlist.values -notcontains $id){
                $index = ($thisApp.config.Current_Playlist.keys | measure -Maximum).Maximum
                $index++
                $null = $thisApp.config.Current_Playlist.add($index,$id)               
              }
            }           
            write-ezlogs "[START_MEDIA] >>>> Saving config file to $($thisApp.Config.Config_Path)" -showtime -color cyan
            $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8  
            $synchash.update_status_timer.start()                             
          }catch{
            write-ezlogs "[START_MEDIA] An exception occurred attempting to generate the notification balloon" -showtime -catcherror $_
          }                                                            
      },"Normal")
     
      $play_timeout = 0
      while(!$synchash.vlc.IsPlaying -and $play_timeout -lt 60){
        $play_timeout++
        write-ezlogs "[START_MEDIA] | Waiting for VLC to begin playing..." -showtime
        start-sleep 1
      }

      if(-not [string]::IsNullOrEmpty($Media.cover_art)){
        $image = $($Media.Cover_art | select -First 1)
      }elseif(-not [string]::IsNullOrEmpty($Media.thumbnail)){
        $image = $($Media.thumbnail | select -First 1)
      }else{
        $image = $null
      } 
      $image_Cache_path = $Null
      if($image)
      {
        write-ezlogs "[START_MEDIA] Media Image found: $($image | out-string)" -showtime
        $uri = new-object system.uri($image)
        if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
          $null = New-item ($thisApp.config.image_Cache_path) -ItemType directory -Force
        }
        if([System.IO.File]::Exists($uri)){
          $image_Cache_path = $uri
        }elseif($uri){
          $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),"$($Image | split-path -Leaf)-$($Media.id).png")
          write-ezlogs "[START_MEDIA] | Destination path for cached image: $image_Cache_path" -showtime
          if(!([System.IO.File]::Exists($image_Cache_path))){
            write-ezlogs "[START_MEDIA] | Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -enablelogs -showtime
            try{
              (New-Object System.Net.WebClient).DownloadFile($uri,$image_Cache_path) 
            }catch{
              $image_Cache_path = $Null
              write-ezlogs "[START_MEDIA] An exception occurred attempting to download $uri to path $image_Cache_path" -showtime -catcherror $_
            }
          }
        }else{
          write-ezlogs "[START_MEDIA] Cannot Download image $uri to cache path $image_Cache_path - URL is invalid" -enablelogs -showtime -warning
          $image_Cache_path = $Null        
        }                                      
      }            
      if($synchash.vlc.IsPlaying){
        write-ezlogs ">>>> [START_MEDIA] Starting tick timer" -showtime -color cyan
        $synchash.Window.Dispatcher.invoke([action]{ 
            if($synchash.vlc.VideoTrackCount -le 0){
              if($image_Cache_path){
                $synchash.VLC_Grid_Row1.Height="200*"
                $synchash.MediaView_Image.Source = $image_Cache_path
              }else{
                $synchash.VLC_Grid_Row1.Height="*"
                $synchash.MediaView_Image.Source = $null
              }            
              $synchash.VideoView.Visibility="Hidden"
              $synchash.VLC_Grid_Row2.Height="20*"
              $synchash.VLC_Grid_Row0.Height="*"
              $synchash.MediaView_TextBlock.text = "$title"
            }else{            
              $synchash.VideoView.Visibility="Visible"
              $synchash.VLC_Grid_Row0.Height="200*"
              $synchash.VLC_Grid_Row2.Height="*"
              $synchash.VLC_Grid_Row1.Height="*"
              $synchash.MediaView_Image.Source = $null              
              $synchash.MediaView_TextBlock.text = ""
            }        
            $Synchash.Timer.start() 
            if($thisApp.Config.streamlink.title){
              $synchash.Now_Playing_Label.content = "Now Playing - $($thisApp.Config.streamlink.User_Name): $($thisApp.Config.streamlink.title)"
            }            
        },'Normal')             
      }elseif($play_timeout -ge 60){
        write-ezlogs "[START_MEDIA] Timedout waiting for VLC media to begin playing!" -showtime -warning
        Update-Notifications -Level 'WARNING' -Message "[START_MEDIA] Timedout waiting for VLC media to begin playing!" -VerboseLog -thisApp $thisApp -synchash $synchash -Open_Flyout
        return
      } 
      if($thisApp.config.Show_notifications)
      {
        try{
          $startapp = Get-startapps *vlc
          if($startapp){
            $appid = $startapp.AppID | select -last 1
          }else{
            $startapp = Get-startapps 'Windows Media Player'
            $appid = $startapp.AppID | select -last 1
          } 
          if($image_Cache_path){
            $applogo = $image_Cache_path 
          }else{
            $applogo = "$($thisApp.Config.Current_folder)\\Resources\\MusicPlayerFill.png"
          }
          if($media.webpage_url -match 'twitch.tv'){
            $source = 'Twitch Stream'
            if(!$image_Cache_path){
              $applogo = "$($thisApp.Config.Current_folder)\\Resources\\Material-Twitch48.png"
            }
          }elseif($media.type -eq 'YoutubePlaylist_item'){
            $source = 'Youtube Media'
            if(!$image_Cache_path){
              $applogo = "$($thisApp.Config.Current_folder)\\Resources\\Material-Youtube.png"
            }
          }else{
            $source = 'Local Media'
          } 
          $Message = "Media : $($thisApp.config.Last_Played_title)`nPlay Duration : $($synchash.MediaPlayer_CurrentDuration)`nSource : $source"
          if($psversiontable.PSVersion.Major -gt 5){
            Import-module Burnttoast -Force
          }
          New-BurntToastNotification -AppID $appid -Text $Message -AppLogo $applogo         
        }catch{
          write-ezlogs "[START_MEDIA] An exception occurred attempting to generate the notification balloon - image: $uri" -showtime -catcherror $_
        }
      }       
    }catch{
      write-ezlogs "[START_MEDIA] An exception occurred attempting to play media $($libvlc_media | out-string)" -showtime -catcherror $_
    }    
  }.GetNewClosure()  
  $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
  Start-Runspace $vlc_scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Vlc Play media" -thisApp $thisApp -Script_Modules $Script_Modules
}
#---------------------------------------------- 
#endregion Start-Media Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-Media','Start-KeyWatcher')

