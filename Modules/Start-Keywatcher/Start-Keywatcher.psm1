<#
    .Name
    Start-KeyWatcher

    .Version 
    0.1.0

    .SYNOPSIS
    Monitors and captures keyboard events for next,prev,stop,play/pause for media player controls. Runs in a background runspace  

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
    try{
      if(!(Get-command -Module Spotishell)){
        Import-Module "$($thisApp.Config.Current_folder)\Modules\Spotishell\Spotishell.psm1"
      } 
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
        try{
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
            $last_played.mediaid = $thisApp.config.Last_Played        
            $synchash.Youtube_WebPlayer_URL = $null
            $synchash.Youtube_WebPlayer_title = $null
            $synchash.Spotify_WebPlayer_title = $null
            $synchash.Spotify_WebPlayer_URL = $null
            $synchash.Start_media = $null                
            write-ezlogs "[NEXT_KEYPRESS] >>>> Next keypress received" -showtime -color cyan
            write-ezlogs "[NEXT_KEYPRESS] >>>> Stopping play timers" -showtime
            $synchash.Window.Dispatcher.invoke([action]{                
                $Synchash.Timer.stop()
                $synchash.Start_media_timer.stop()  
                $synchash.WebPlayer_Playing_timer.stop()  
            })            
            if($synchash.vlc.IsPlaying){
              $synchash.VLC.stop()
            }else{
              try{   
                $current_track = (Get-CurrentTrack -ApplicationName $thisApp.config.App_Name) 
                if($current_track){
                  $devices = Get-AvailableDevices -ApplicationName $thisApp.config.App_Name
                }              
                if($current_track.is_playing){
                  #$last_played.mediaid = $thisApp.config.Last_Played
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
            }      
            try{                                                         
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
                #Look for local media 
                $All_Playlists_Cache_File_Path = [System.IO.Path]::Combine($thisApp.config.Playlist_Profile_Directory,"All-Playlists-Cache.xml")
                if($synchash.All_local_Media){
                  $next_selected.media = $synchash.All_local_Media | where {$_.id -eq $next_item}
                  <#                  foreach($item in $synchash.All_local_Media){
                      if($item.id -eq $next_item){
                      $next_selected.media = $item
                      }
                  }#>
                }else{
                  foreach($item in $Datatable.datatable){
                    if($item.id -eq $next_item){
                      $next_selected.media = $item
                    }
                  }
                } 
                #look for youtube media                              
                if(!$next_selected.media){
                  if($synchash.All_Youtube_Media.Playlist_tracks){
                    $next_selected.media = $synchash.All_Youtube_Media.playlist_tracks | where {$_.id -eq $next_item} 
                    if(!$next_selected.media){
                      $next_selected.media = $synchash.All_Youtube_Media.playlist_tracks | where {$_.encodedtitle -eq $next_item} 
                    }                    
                  }else{
                    foreach($item in $Youtube_Datatable.datatable){
                      if($item.id -eq $next_item){
                        $next_selected.media = $item
                      }
                    }
                  }
                }                
                #look for spotify media
                if(!$next_selected.media){
                  if($synchash.All_Spotify_Media.playlist_tracks){
                    $next_selected.media = $synchash.All_Spotify_Media.playlist_tracks | where {$_.id -eq $next_item} 
                  }else{
                    foreach($item in $Spotify_Datatable.datatable){
                      if($item.id -eq $next_item){
                        $next_selected.media = $item
                      }
                    }
                  }              
                } 
                #Look for in playlist cache
                if(!$next_selected.media){
                  if([System.IO.File]::Exists($All_Playlists_Cache_File_Path)){
                    if($thisApp.Config.Verbose_logging){write-ezlogs "[NEXT_KEYPRESS] | Importing All Playlist Cache: $All_Playlists_Cache_File_Path" -showtime -enablelogs}
                    $Available_Playlists = Import-CliXml -Path $All_Playlists_Cache_File_Path
                  }
                  if($Available_Playlists.PlayList_tracks | where {$_.id -eq $next_item}){                     
                    $next_selected.media = $Available_Playlists.PlayList_tracks | where {$_.id -eq $next_item} | select -First 1
                    write-ezlogs "[NEXT_KEYPRESS] | Found next media in Playlist cache ($($next_selected.media.playlist)) - meaning its missing from primary media profiles!" -showtime -warning
                    if($next_selected.media.Source -eq 'YoutubePlaylist_item'){
                      try{  
                        write-ezlogs "[NEXT_KEYPRESS] Adding next media to Youtube media profiles" -showtime
                        $Link = $next_selected.media.webpage_url 
                        if(-not [string]::IsNullOrEmpty($Link) -and (Test-url $Link)){
                          if($Link -match 'twitch.tv'){
                            $twitch_channel = $((Get-Culture).textinfo.totitlecase(($Link | split-path -leaf).tolower()))
                            write-ezlogs "[NEXT_KEYPRESS] >>>> Adding Twitch channel $twitch_channel - $Link" -showtime -color cyan                       
                          }elseif($Link -match 'youtube.com' -or $Link -match 'youtu.be'){
                            write-ezlogs "[NEXT_KEYPRESS] >>>> Adding Youtube link $Link" -showtime -color cyan
                          }
                          Import-Youtube -Youtube_URL $Link -verboselog:$thisApp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -PlayMedia_Command $PlayMedia_Command -thisApp $thisApp -use_runspace       
                        }else{
                          write-ezlogs "[NEXT_KEYPRESS] The provided URL is not valid or was not provided! -- $Link" -showtime -warning
                        }                        
                      }catch{
                        write-ezlogs "[NEXT_KEYPRESS] An exception occurred adding media $($next_selected.media.title) with Import-Youtube" -showtime -catcherror $_
                      }
                    } 
                  }            
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
              if($next_selected.media.SongInfo.title){
                $title = $next_selected.media.SongInfo.title
              }else{
                $title = $next_selected.media.title
              }
              write-ezlogs "[NEXT_KEYPRESS] | Next to play is $($title) - ID $($next_selected.media.id)" -showtime
              #write-ezlogs "[NEXT_KEYPRESS] | Media: $($next_selected.media | out-string)" -showtime
              Add-Member -InputObject $thisApp.config -Name 'Last_Played' -Value ($next_selected.media.id) -MemberType NoteProperty -Force
              if($next_selected.media.Spotify_Path -or $next_selected.media.Spotify_Launch_Path -or $next_selected.media.Source -match 'Spotify'){
                Add-Member -InputObject $thisApp.config -Name 'Spicetify' -Value $true -MemberType NoteProperty -Force
                Start-SpotifyMedia -Media $next_selected.media -thisApp $thisApp -synchash $synchash                                       
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
                  }elseif($synchash.Youtube_WebPlayer_title -and $synchash.Youtube_WebPlayer_URL){
                    $synchash.Youtube_WebPlayer_URL = $null
                    $synchash.Youtube_WebPlayer_title = $null  
                    $synchash.Youtube_WebPlayer_timer.start()
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
                $Synchash.Timer.stop()
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
                      $Synchash.Timer.stop()
                      write-ezlogs "[PLAYPAUSE_KEYPRESS] >>>> Pausing Vlc playback" -showtime -color cyan
                      $synchash.Now_Playing_Label.content = ($synchash.Now_Playing_Label.content) -replace 'Now Playing', 'Paused'                    
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
        }catch{
          write-ezlogs "An exception occurred in keyboard_Watcher_ScriptBlock while loop" -showtime -catcherror $_
        } 
      } while($true)  
      write-ezlogs "Keywatcher has ended!" -showtime -warning
    }catch{
      write-ezlogs "An exception occurred in keyboard_watcher_scriptblock" -showtime -catcherror $_
    }
    if($error){
      write-ezlogs -showtime -PrintErrors -ErrorsToPrint $error
    }    
  }.GetNewClosure()
  $Variable_list = Get-Variable | where {$_.Options -notmatch "ReadOnly" -and $_.Options -notmatch "Constant"}  
  Start-Runspace $keyboard_Watcher_ScriptBlock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Keyboard Watcher" -thisApp $thisapp -No_Cancel_Existing -Script_Modules $Script_Modules
}
#---------------------------------------------- 
#endregion Start-Keywatcher Function
#----------------------------------------------
Export-ModuleMember -Function @('Start-KeyWatcher')

