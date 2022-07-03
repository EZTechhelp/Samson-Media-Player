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
    - Module designed for EZT-MediaPlayer

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
    $next_selected = $Null
    $next_selected = [hashtable]::Synchronized(@{}) 
    $last_played = [hashtable]::Synchronized(@{})  
    $last_played.mediaid = $thisApp.config.Last_Played    
    if(!$last_played.mediaid){
      $last_played.mediaid = $synchash.Current_playing_media.id
    }    
    $synchash.Youtube_WebPlayer_URL = $null
    $synchash.Youtube_WebPlayer_title = $null
    $synchash.Spotify_WebPlayer_title = $null
    $synchash.Spotify_WebPlayer_URL = $null
    $synchash.Start_media = $null 
    $synchash.Current_playing_media = $null           
    write-ezlogs ">>>> Skip-Media received" -showtime -color cyan
    write-ezlogs ">>>> Stopping play timers" -showtime
    #$synchash.Window.Dispatcher.invoke([action]{     
    #$synchash.Youtube_WebPlayer_timer.start()           
    $Synchash.Timer.stop()
    $synchash.Start_media_timer.stop()  
    $synchash.WebPlayer_Playing_timer.stop()  
    $synchash.update_status_timer.start() 
    #})            
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
                write-ezlogs ">>>> Stopping Spotify playback with Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE'" -showtime -color cyan
                Invoke-RestMethod -Uri 'http://127.0.0.1:8974/PAUSE' -UseBasicParsing  
                $thisApp.Config.Spicetify = ''
              }catch{
                write-ezlogs "An exception occurred executing Invoke-RestMethod to 'http://127.0.0.1:8974/PAUSE' -- forcing Spotify to close (Nuclear option I know)" -showtime -catcherror $_
                if(Get-Process -Name 'Spotify*' -ErrorAction SilentlyContinue){
                  Get-Process -Name 'Spotify*' | Stop-Process -Force -ErrorAction SilentlyContinue
                } 
                $thisApp.Config.Spicetify = ''            
              }
            }else{
              write-ezlogs ">>>> Stopping Spotify playback with Suspend-Playback -ApplicationName $($thisApp.config.App_Name) -DeviceId $($devices.id) " -showtime -color cyan
              $thisApp.Config.Spicetify = ''
              Suspend-Playback -ApplicationName $thisApp.config.App_Name -DeviceId $devices.id   
            }
          }          
          $synchash.Spotify_Status = 'Stopped'  
        }
      }catch{
        write-ezlogs "An exception occurred stopped Spotify" -showtime -catcherror $_
      }               
    }      
    try{                                                         
      if([System.IO.File]::Exists($thisApp.Config.Config_Path)){
        $thisApp.config = Import-Clixml -Path $thisApp.Config.Config_Path
        if($thisApp.Config.Verbose_logging){write-ezlogs " | Importing config file $($thisApp.Config.Config_Path)" -showtime}
        if(($thisApp.config.Current_Playlist.GetType()).name -notmatch 'OrderedDictionary'){$thisApp.config.Current_Playlist = ConvertTo-OrderedDictionary -hash ($thisApp.config.Current_Playlist)}
      }       
      if($last_played.mediaid -and $thisApp.config.Current_Playlist.values -contains $last_played.mediaid){
        try{
          $index_toremove = $thisApp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $last_played.mediaid} | select * -ExpandProperty key 
          if(($index_toremove).count -gt 1){
            if($thisApp.Config.Verbose_logging){write-ezlogs " | Found multiple items in Play Queue matching id $($last_played.mediaid) - $($index_toremove | out-string)" -showtime -warning}
            foreach($index in $index_toremove){
              $null = $thisApp.config.Current_Playlist.Remove($index) 
            }  
          }else{
            write-ezlogs " | Removing $($last_played.mediaid) from Play Queue" -showtime
            $null = $thisApp.config.Current_Playlist.Remove($index_toremove)
          }                               
        }catch{
          write-ezlogs "An exception occurred updating current config queue playlist" -showtime -catcherror $_
        }                          
        $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8
      }  
      if($thisApp.config.Shuffle_Playback){
        write-ezlogs " | Getting random item from queue" -showtime
        $next_item = $thisApp.config.Current_Playlist.values | Get-Random -Count 1        
      }else{
        $index_toget = ($thisApp.config.Current_Playlist.keys | measure -Minimum).Minimum 
        write-ezlogs " | Getting next item with index $($index_toget)" -showtime
        $next_item = (($thisApp.config.Current_Playlist.GetEnumerator()) | where {$_.name -eq $index_toget}).value              
      }  
      if(!$next_item){
        if($thisApp.Config.Verbose_logging){write-ezlogs "Attempting to get next item from current_playlist using select -first 1" -showtime -warning}
        $next_item = $thisApp.config.Current_Playlist.values | select -first 1
      }                           
      if($next_item){
        write-ezlogs " | Next queued item is $($next_item)" -showtime
        #Look for local media 
        $All_Playlists_Cache_File_Path = [System.IO.Path]::Combine($thisApp.config.Playlist_Profile_Directory,"All-Playlists-Cache.xml")
        if($synchash.All_local_Media){
          $next_selected.media = $synchash.All_local_Media | where {$_.id -eq $next_item} | select -Unique
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
            $next_selected.media = $synchash.All_Youtube_Media.playlist_tracks | where {$_.id -eq $next_item} | select -Unique
            if(!$next_selected.media){
              $next_selected.media = $synchash.All_Youtube_Media.playlist_tracks | where {$_.encodedtitle -eq $next_item} | select -Unique
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
          $next_selected.media = $Spotify_Datatable.datatable | where {$_.id -eq $next_item} | select -Unique
          if(!$next_selected.media -and $synchash.All_Spotify_Media.playlist_tracks){
            $next_selected.media = $synchash.All_Spotify_Media.playlist_tracks | where {$_.id -eq $next_item} | select -Unique
          }              
        } 
        #Look for in playlist cache
        if(!$next_selected.media){
          if([System.IO.File]::Exists($All_Playlists_Cache_File_Path)){
            if($thisApp.Config.Verbose_logging){write-ezlogs " | Importing All Playlist Cache: $All_Playlists_Cache_File_Path" -showtime -enablelogs}
            $Available_Playlists = Import-CliXml -Path $All_Playlists_Cache_File_Path
          }
          if($Available_Playlists.PlayList_tracks | where {$_.id -eq $next_item}){                     
            $next_selected.media = $Available_Playlists.PlayList_tracks | where {$_.id -eq $next_item} | select -First 1
            write-ezlogs " | Found next media in Playlist cache ($($next_selected.media.playlist)) - meaning its missing from primary media profiles!" -showtime -warning
            if($next_selected.media.Source -eq 'YoutubePlaylist_item'){
              try{  
                write-ezlogs " | Adding next media to Youtube media profiles" -showtime
                $Link = $next_selected.media.webpage_url 
                if(-not [string]::IsNullOrEmpty($Link) -and (Test-url $Link)){
                  if($Link -match 'twitch.tv'){
                    $twitch_channel = $((Get-Culture).textinfo.totitlecase(($Link | split-path -leaf).tolower()))
                    write-ezlogs ">>>> Adding Twitch channel $twitch_channel - $Link" -showtime -color cyan                       
                  }elseif($Link -match 'youtube.com' -or $Link -match 'youtu.be'){
                    write-ezlogs ">>>> Adding Youtube link $Link" -showtime -color cyan
                  }
                  Import-Youtube -Youtube_URL $Link -verboselog:$thisApp.Config.Verbose_Logging -synchash $synchash -thisScript $thisScript -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -PlayMedia_Command $Synchash.PlayMedia_Command -thisApp $thisApp -use_runspace       
                }else{
                  write-ezlogs "The provided URL is not valid or was not provided! -- $Link" -showtime -warning
                }                        
              }catch{
                write-ezlogs "An exception occurred adding media $($next_selected.media.title) with Import-Youtube" -showtime -catcherror $_
              }
            } 
          }            
        }                                        
      }else{
        write-ezlogs " | No other media is queued to play" -showtime
        $synchash.Spotify_Status = 'Stopped'
        #$synchash.Window.Dispatcher.invoke([action]{ 
        $synchash.update_status_timer.start()
        #})                     
        return            
      }               
    }catch{
      write-ezlogs "An exception occurred executing Next item events" -showtime -catcherror $_
    }  
    if(!$next_selected.media){
      write-ezlogs " | Unable to get media information about next item $next_item!" -showtime -warning             
      return
    }else{
      if($next_selected.media.SongInfo.title){
        $title = $next_selected.media.SongInfo.title
      }else{
        $title = $next_selected.media.title
      }
      write-ezlogs " | Next to play is $($title) - ID $($next_selected.media.id)" -showtime
      Add-Member -InputObject $thisApp.config -Name 'Last_Played' -Value ($next_selected.media.id) -MemberType NoteProperty -Force
      $synchash.Current_playing_media = $next_selected.media
      if($next_selected.media.Spotify_Path -or $next_selected.media.Spotify_Launch_Path -or $next_selected.media.Source -match 'Spotify'){
        Add-Member -InputObject $thisApp.config -Name 'Spicetify' -Value $true -MemberType NoteProperty -Force
        Start-SpotifyMedia -Media $next_selected.media -thisApp $thisApp -synchash $synchash                                       
      }elseif($next_selected.media.id){
        if(Get-Process -Name 'Spotify*' -ErrorAction SilentlyContinue){
          Get-Process -Name 'Spotify*' | Stop-Process -Force -ErrorAction SilentlyContinue
        }                   
        Start-Media -Media $next_selected.media -thisApp $thisapp -synchash $synchash -Show_notification -Script_Modules $Script_Modules -media_contextMenu $Synchash.Media_ContextMenu -PlayMedia_Command $Synchash.PlayMedia_Command -all_playlists $all_playlists
      }
    }  
    $next_selected = $null     
  }catch{
    write-ezlogs 'An exception occurred in Skip-Media' -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Skip-Media Function
#----------------------------------------------
Export-ModuleMember -Function @('Skip-Media')