<#
    .Name
    Get-Youtube

    .Version 
    0.1.0

    .SYNOPSIS
    Retrieves Youtube tracks, albums, playlists..etc 

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
#region Get-Youtube Function
#----------------------------------------------
function Get-Youtube
{
  Param (
    [string]$Youtube_URL,
    [switch]$Import_Profile,
    $thisApp,
    $log,
    $all_installed_apps,
    [switch]$Refresh_Global_Profile,
    [switch]$Startup,
    [switch]$update_global,
    [switch]$Export_Profile,
    $import_browser_auth,
    [switch]$Get_Playlists,
    [switch]$Export_AllMedia_Profile,
    [string]$Media_Profile_Directory,
    $Youtube_playlists,
    [string]$youtube_playlist_Url,
    [string]$PlayerData_Profile_Directory,
    [switch]$Verboselog
  )
  
  $illegal =[Regex]::Escape(-join [System.Io.Path]::GetInvalidPathChars())
  $pattern = "[™$illegal]"
  $pattern2 = "[:$illegal]"
  $AllYoutube_Media_Profile_Directory_Path = [System.IO.Path]::Combine($Media_Profile_Directory,"All-Youtube_MediaProfile")
  if (!([System.IO.Directory]::Exists($AllYoutube_Media_Profile_Directory_Path))){
    $Null = New-Item -Path $AllYoutube_Media_Profile_Directory_Path -ItemType directory -Force
  } 
  $AllYoutube_Media_Profile_File_Path = [System.IO.Path]::Combine($AllYoutube_Media_Profile_Directory_Path,"All-Youtube_Media-Profile.xml")
  
  #Twitch Profile Path
  $AllTwitch_Media_Profile_Directory_Path = [System.IO.Path]::Combine($Media_Profile_Directory,"All-Twitch_MediaProfile")
  if (!([System.IO.Directory]::Exists($AllTwitch_Media_Profile_Directory_Path))){
    $Null = New-Item -Path $AllTwitch_Media_Profile_Directory_Path -ItemType directory -Force
  }
  $AllTwitch_Media_Profile_File_Path = [System.IO.Path]::Combine($AllTwitch_Media_Profile_Directory_Path,"All-Twitch_Media-Profile.xml")  
  if($startup -and $Import_Profile -and ([System.IO.File]::Exists($AllYoutube_Media_Profile_File_Path))){ 
    if($Verboselog){write-ezlogs " | Importing Youtube Media Profile: $AllYoutube_Media_Profile_File_Path" -showtime -enablelogs -logfile:$log}
    [System.Collections.ArrayList]$Available_Youtube_Media = Import-CliXml -Path $AllYoutube_Media_Profile_File_Path
    $Available_Twitch_Media = $Available_Youtube_Media | where {$_.Source -eq 'TwitchChannel'}
    if(@($Available_Twitch_Media).count -gt 1 -and !([System.IO.File]::Exists($AllTwitch_Media_Profile_File_Path))){
      write-ezlogs ">>>> Saving Available Twitch Media profile to $AllTwitch_Media_Profile_File_Path" -showtime -logfile:$log
      [System.Collections.ArrayList]$Available_Twitch_Media | Export-Clixml $AllTwitch_Media_Profile_File_Path -Force     
    }    
    return $Available_Youtube_Media    
  }else{
    if($Verboselog){write-ezlogs " | Youtube Media Profile to import not found at $AllYoutube_Media_Profile_File_Path....Attempting to build new profile" -showtime -enablelogs -logfile:$log} 
  }   
  $youtubedl_path = "$($thisApp.config.Current_folder)\\Resources\\Youtube-dl" 
  $env:Path += ";$youtubedl_path" 
  $yt_dl_urls = $Null
  if($Youtube_URL){
    $yt_dl_urls = $Youtube_URL
    if($Import_Profile -and ([System.IO.File]::Exists($AllYoutube_Media_Profile_File_Path))){ 
      write-ezlogs " | Importing Youtube Media Profile: $AllYoutube_Media_Profile_File_Path" -showtime -enablelogs -logfile:$log
      [System.Collections.ArrayList]$Available_Youtube_Media = Import-CliXml -Path $AllYoutube_Media_Profile_File_Path 
    }
  }else{
    $yt_dl_urls = $Youtube_playlists
    $Available_Youtube_Media = New-Object -TypeName 'System.Collections.ArrayList'
  }  
  foreach($playlist in $yt_dl_urls){
    try{
      $yt_dlp = $null
      if($playlist -match '&t='){
        $playlist = ([regex]::matches($playlist, "(?<value>.*)&t=" ) | %{$_.groups[1].value} )
      }
      #$youtubedl_path = "C:\Users\DopaDodge\OneDrive - EZTechhelp Company\Development\Repositories\EZT-MediaPlayer\Resources\Youtube-dl"
      if($playlist -match 'twitch.tv'){
        #$streamlink_fetchjson = streamlink $playlist --json\
        $twitch_channel = $((Get-Culture).textinfo.totitlecase(($playlist | split-path -leaf).tolower()))        
        $TwitchAPI = Get-TwitchAPI -StreamName $twitch_channel -thisApp $thisApp -startup -verboselog:$thisApp.Config.Verbose_logging
        $id = $Null  
        $idbytes = [System.Text.Encoding]::UTF8.GetBytes("$($twitch_channel)-TwitchChannel")
        $id = [System.Convert]::ToBase64String($idbytes)      
        if(!$TwitchAPI.type){          
          $title = "Twitch Stream: $($twitch_channel)"
          $Live_status = 'Offline'
          $Status_msg = ''
          $Stream_title = ''
        }elseif($TwitchAPI.type -match 'live'){
          $title = "Twitch Stream: $($TwitchAPI.user_name)"
          $Live_status = 'Live'
          $Status_msg = "- $($TwitchAPI.game_name)"
          $Stream_title = $TwitchApi.title
        }elseif($TwitchAPI.type){
          $title = "Twitch Stream: $($TwitchAPI.user_name)"
          $Live_status = $TwitchAPI.type
          $Status_msg = "- $($TwitchAPI.game_name)"    
          $Stream_title = $TwitchApi.title
        }else{
          $title = "Twitch Stream: $($twitch_channel)"
          $Live_status = 'Offline'
          $Status_msg = ''
          $Stream_title = ''
        }           
        if($TwitchAPI.thumbnail_url){
          $thumbnail = "$($TwitchAPI.thumbnail_url -replace '{width}x{height}','500x500')"
        }else{
          $thumbnail = $null
        }
        if($TwitchAPI.profile_image_url){
          $profile_image_url = $TwitchAPI.profile_image_url
          $offline_image_url = $TwitchAPI.offline_image_url
          $description = $TwitchAPI.description
        }else{
          $profile_image_url = $Null
          $offline_image_url = $Null  
          $description = $Null   
        }        
        $yt_dlp = New-Object -TypeName 'System.Collections.ArrayList'
        $twitch_item = New-Object PsObject -Property @{
          'title' = $title
          'id' = $id
          'url' = $playlist
          'Live_status' = $Live_status
          'Stream_title' = $Stream_title
          'Status_msg' = $Status_msg
          'webpage_url' = $playlist
          'thumbnail' = $thumbnail
          'description' = $description
          'profile_image_url' = $profile_image_url
          'offline_image_url' = $offline_image_url          
          'uploader' = $twitch_channel
          'is_not_json' = $true
          'extractor' = 'Twitch'
          'Playlist' = $twitch_channel
          'Source' = 'YoutubePlaylist_item'
        }
        write-ezlogs " | Adding Twitch stream channel: $twitch_channel - Status: $Live_status" -showtime -logfile:$log
        $null = $yt_dlp.add($twitch_item)      
      }elseif($import_browser_auth){
        #$yt_dlp = yt-dlp -f b* -g $playlist --rm-cache-dir -o '*' -j --cookies-from-browser $import_browser_auth
        $yt_dlp = yt-dlp -f bestvideo+bestaudio/best -g $playlist --rm-cache-dir -o '*' -j --cookies-from-browser $import_browser_auth       
      }else{
        $yt_dlp = yt-dlp -f b* -g $playlist --rm-cache-dir -o '*' -j
      }    
      #--flat-playlist    
    }catch{
      write-ezlogs "An exception occurred processing $($playlist) with yt-dl" -showtime -catcherror $_ -logfile:$log
    }
    if($yt_dlp){
      #Get all playlists
      $playlist_items = New-Object -TypeName 'System.Collections.ArrayList'
      #Get Playlists
      foreach($item in $yt_dlp)
      { 
        $newRow = $null
        $track = $Null
        $youtube_Media_output = New-Object -TypeName 'System.Collections.ArrayList'
        if(Test-url $item){
          $track = $Null
        }else{               
          if(!$item.is_not_json){
            $track = $item | convertfrom-json -ErrorAction SilentlyContinue
          }else{
            $track = $item
          }     
          if($track.title){
            $name = $null
            $name = $track.playlist      
            write-ezlogs " | Found Playlist item $($track.title)" -showtime -logfile:$log
            $url = $null
            $type = $null
            $type = $track.ie_key
            $Tracks_Total = $null
            $Tracks_Total = $track.playlist_count
            $images = $null
            $images = $track.thumbnails
            $href = $Null
            $duration = $Null
            $duration = $track.duration 
            if($track.playlist_id){
              $href = "https://www.youtube.com/playlist?list=$($track.playlist_id)"
            }
            $playlist_id = $track.playlist_id
            $encodedTitle = $Null  
            $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($name)-YoutubePlaylist")
            $encodedTitle = [System.Convert]::ToBase64String($encodedBytes)      
            $track_encodedTitle = $Null  
            $track_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($track.title)-YoutubePlaylist")
            $track_encodedTitle = [System.Convert]::ToBase64String($track_encodedBytes)     
            write-ezlogs " | Type $($type)" -showtime -logfile:$log
            write-ezlogs " | Playlist ID $($playlist_id)" -showtime -logfile:$log
            write-ezlogs " | ID $($track.id)" -showtime -logfile:$log
            write-ezlogs " | Track Total $($Tracks_Total)" -showtime -logfile:$log
            write-ezlogs " | Track URL $($track.url)" -showtime -logfile:$log
            write-ezlogs " | Description $($track.description)" -showtime -logfile:$log
            if($track.urls){
              $url_streams = $track.urls -split "`n"
            }else{
              $url_streams = $track.url
            }
            if(($url_streams).count -gt 1){
              $video_url = $url_streams[0]
              $audio_url = $url_streams[1]
            }else{
              #$url = $track.urls
              $video_url = $Null
              $audio_url = $null
            }
            if($track.url){
              $url = $track.url
            }else{
              $url = $track.webpage_url
            }           
            if($url){ 
              if($track.extractor -match 'twitch'){
                $title = "Twitch Stream: $($track.uploader)"
                $Group = 'Twitch'
                if($track.live_status){
                  $live_status = $track.live_status
                }elseif($track.title -match '\(live\)'){
                  $live_status = 'Online'
                }else{
                  $live_status = 'Offline'
                }
                if($track.status_msg){
                  $status_msg = $track.status_msg
                }else{
                  $status_msg = $null
                } 
                if($track.Stream_title){
                  $Stream_title = $track.Stream_title
                }else{
                  $Stream_title = $Null
                }                              
              }else{
                $title = $track.title
                $thumbnail = $null
                $live_status = $null
                $status_msg = $null
                $Stream_title = $Null
                $Group = 'Youtube'
                if($track.duration){
                  [int]$hrs = $($([timespan]::Fromseconds($Track.Duration)).Hours)
                  [int]$mins = $($([timespan]::Fromseconds($Track.Duration)).Minutes)
                  [int]$secs = $($([timespan]::Fromseconds($Track.Duration)).Seconds) 
                  [int]$milsecs = $($([timespan]::Fromseconds($Track.Duration)).TotalMilliseconds)
                  $duration = $milsecs
                }
              }              
              #write-ezlogs " | Title: $($title)" -showtime          
              $newRow = New-Object PsObject -Property @{
                'title' = $title
                'description' = $track.description
                'playlist_index' = $track.playlist_index
                'channel_id' = $track.channel_id
                'id' = $track.id
                'duration' = $duration
                'encodedTitle' = $track_encodedTitle
                'url' = $url
                'video_url' = $video_url
                'audio_url' = $audio_url
                'urls' = $track.urls
                'upload_date' = $track.upload_date
                'categories' = $track.categories
                'like_count' = $track.like_count
                'resolution' = $track.resolution
                'Live_status' = $live_status
                'Status_Msg' = $Status_msg
                'Stream_title' = $Stream_title
                'format_id' = $track.format_id
                'format_note'= $track.format_note
                'duration_string' = $track.duration_string
                'tags' = $track.tags
                'webpage_url' = $track.webpage_url
                'thumbnail' = $track.thumbnail
                'filesize_approx' = $track.filesize_approx
                'width' = $track.width
                'profile_image_url' = $track.profile_image_url
                'offline_image_url' = $track.offline_image_url                 
                'full_title' = $track.fulltitle
                'height' = $track.height
                'video_ext' = $track.video_ext
                'ext' = $track.ext
                'formats' = $track.formats
                'view_count' = $track.view_count
                'manifest_url' = $track.manifest_url
                'uploader' = $track.uploader
                'webpage_url_domain' = $track.webpage_url_domain
                'type' = ''
                'availability' = $track.availability
                'Tracks_Total' = $Tracks_Total
                'images' = $images
                'Playlist_url' = $href
                'playlist_id' = $playlist_id
                'Profile_Path' = $AllYoutube_Media_Profile_File_Path
                'Profile_Date_Added' = $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss:tt')
                'Source' = 'YoutubePlaylist_item'
                'Group' = $Group
              }
              $null = $playlist_items.Add($newRow)           
            }else{
              write-ezlogs "Found Playlist item ($name) but unable to get its URL" -showtime -enablelogs -warning -logfile:$log
            } 
            if($track.playlist_id){ 
              if($Available_Youtube_Media.id -notcontains $track.playlist_id){
                write-ezlogs ">>>> Found Youtube Playlist $($track.playlist)" -showtime -logfile:$log
                $encodedTitle = $Null  
                $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($track.playlist)-YoutubePlaylist")
                $encodedTitle = [System.Convert]::ToBase64String($encodedBytes)       
                $newRow = New-Object PsObject -Property @{
                  'name' = $track.playlist
                  'id' = $track.playlist_id
                  'encodedTitle' = $encodedTitle
                  'url' = "https://www.youtube.com/playlist?list=$($track.playlist_id)"
                  'type' = 'Youtube_playlist'
                  'Tracks_Total' = $track.playlist_count
                  'Live_Status' = $live_status
                  'description' = ''
                  'playlist_tracks' = $playlist_items
                  'images' = $track.thumbnails
                  'Profile_Path' = $AllYoutube_Media_Profile_File_Path
                  'Profile_Date_Added' = $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss:tt')
                  'Source' = 'YoutubePlaylist'
                  'Group' = $Group
                }
                $null = $youtube_Media_output.Add($newRow)
                #$null = $Available_Youtube_Media.Add($newRow)        
              }else{
                write-ezlogs "Youtube Playlist $($track.playlist) has already been added" -showtime -warning -logfile:$log
                $encodedTitle = $Null
              }                    
            }elseif($track.channel_id){
              if($track.channel_id -and $Available_Youtube_Media.playlist_tracks.id -notcontains $track.id){
                write-ezlogs ">>>> Found Youtube Channel $($track.channel)" -showtime -logfile:$log
                $encodedTitle = $Null  
                $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($track.channel)-YoutubeChannel")
                $encodedTitle = [System.Convert]::ToBase64String($encodedBytes)       
                $newRow = New-Object PsObject -Property @{
                  'name' = $track.channel
                  'id' = $track.channel_id
                  'encodedTitle' = $encodedTitle
                  'url' = $track.channel_url
                  'type' = 'Youtube_channel'
                  'Tracks_Total' = ''
                  'Live_Status' = $live_status
                  'description' = ''
                  'playlist_tracks' = $playlist_items
                  'images' = $track.thumbnails
                  'Profile_Path' = $AllYoutube_Media_Profile_File_Path
                  'Profile_Date_Added' = $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss:tt')
                  'Source' = 'YoutubeChannel'
                  'Group' = $Group
                }
                $null = $youtube_Media_output.Add($newRow)
                #$null = $Available_Youtube_Media.Add($newRow)        
              }else{
                write-ezlogs "Youtube track $($track.title) has already been added" -showtime -warning -logfile:$log
                $encodedTitle = $Null
              }           
            }elseif($track.extractor -match 'twitch'){
              if($Available_Youtube_Media.id -notcontains $track.id){
                write-ezlogs ">>>> Found Twitch Channel $($track.uploader)" -showtime -logfile:$log
                $encodedTitle = $Null  
                $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($track.uploader)-TwitchChannel")
                $encodedTitle = [System.Convert]::ToBase64String($encodedBytes)                      
                $newRow = New-Object PsObject -Property @{
                  'name' = $track.uploader
                  'id' = $track.id
                  'encodedTitle' = $encodedTitle
                  'url' = $track.webpage_url
                  'type' = 'Twitch_channel'
                  'Tracks_Total' = ''
                  'Live_Status' = $live_status
                  'description' = $track.description
                  'playlist_tracks' = $playlist_items
                  'chat_url' = "https://twitch.tv/$($track.uploader)/chat"
                  'images' = $track.thumbnail
                  'Profile_Path' = $AllYoutube_Media_Profile_File_Path
                  'Profile_Date_Added' = $(Get-Date -Format 'MM-dd-yyyy hh:mm:ss:tt')
                  'Source' = 'TwitchChannel'
                  'Group' = $Group
                }
                $null = $youtube_Media_output.Add($newRow)
                #$null = $Available_Youtube_Media.Add($newRow)        
              }          
            }else{
              write-ezlogs "Twitch Channel $($track.uploader) has already been added" -showtime -warning -logfile:$log
              $encodedTitle = $Null
            }
            if($encodedTitle -ne $Null){
              $null = $Available_Youtube_Media.Add($youtube_Media_output)
            }                          
          }else{
            write-ezlogs "Unable to parse a title from $($track | out-string)" -showtime -warning -logfile:$log
          }           
        }       
      }          
    }else{
      write-ezlogs "Unable to get Youtube playlist $($playlist)" -showtime -warning -logfile:$log
    }
  }
  $Available_Twitch_Media = $Available_Youtube_Media | where {$_.Source -eq 'TwitchChannel'}
  if(@($Available_Twitch_Media).count -gt 1){
    write-ezlogs ">>>> Saving Available Twitch Media profile to $AllTwitch_Media_Profile_File_Path" -showtime -logfile:$log
    [System.Collections.ArrayList]$Available_Twitch_Media | Export-Clixml $AllTwitch_Media_Profile_File_Path -Force     
  }
  if($export_profile -and $AllYoutube_Media_Profile_File_Path -and $Available_Youtube_Media){
    write-ezlogs ">>>> Saving Available Youtube Media profile to $AllYoutube_Media_Profile_File_Path" -showtime -logfile:$log
    [System.Collections.ArrayList]$Available_Youtube_Media | Export-Clixml $AllYoutube_Media_Profile_File_Path -Force
  }  
  #$synchash.Youtube_FirstRun = $false
  if($Verboselog){write-ezlogs " | Number of Youtube Playlists found: $($Available_Youtube_Media.Count)" -showtime -enablelogs -logfile:$log}      
  return [System.Collections.ArrayList]$Available_Youtube_Media  
}
#---------------------------------------------- 
#endregion Get-Youtube Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-Youtube')

