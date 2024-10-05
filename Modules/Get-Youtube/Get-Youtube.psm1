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
    - Module designed for Samson Media Player

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
    $synchash = $synchash,
    [switch]$refresh,
    $all_installed_apps,
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
    [switch]$Verboselog,
    $PlaylistInfo
  )

  $GetYoutube_stopwatch = [diagnostics.stopwatch]::StartNew() 
  $illegal =[Regex]::Escape(-join [Io.Path]::GetInvalidFileNameChars())
  $pattern = "[™$illegal]"
  #$pattern2 = "[:$illegal]"
  $AllYoutube_Media_Profile_Directory_Path = [IO.Path]::Combine($Media_Profile_Directory,"All-Youtube_MediaProfile")
  if (!([IO.Directory]::Exists($AllYoutube_Media_Profile_Directory_Path))){
    $Null = New-Item -Path $AllYoutube_Media_Profile_Directory_Path -ItemType directory -Force
  } 
  $AllYoutube_Media_Profile_File_Path = [IO.Path]::Combine($AllYoutube_Media_Profile_Directory_Path,"All-Youtube_Media-Profile.xml")
   
  if($Import_Profile -and ([IO.File]::Exists($AllYoutube_Media_Profile_File_Path))){ 
    if($Verboselog){write-ezlogs "[Get-Youtube] | Importing Youtube Media Profile: $AllYoutube_Media_Profile_File_Path" -showtime -enablelogs -logtype Youtube}
    $synchash.All_Youtube_Media = Import-SerializedXML -Path $AllYoutube_Media_Profile_File_Path
    if($Startup -and !$refresh){ 
      if($GetYoutube_stopwatch){$GetYoutube_stopwatch.stop()}
      return
    }    
  }else{
    write-ezlogs "[Get-Youtube] | Youtube Media Profile to import not found at $AllYoutube_Media_Profile_File_Path....Attempting to build new profile" -showtime -enablelogs -logtype Youtube 
  }   
  $youtubedl_path = "$($thisApp.config.Current_folder)\Resources\Youtube-dl" 
  if(!(Get-command Get-AccessToken -ErrorAction SilentlyContinue)){
    Import-Module "$($thisApp.Config.Current_folder)\Modules\Youtube\Youtube.psm1" -Force -NoClobber -DisableNameChecking -Scope Local
  }
  #$envpaths = [Environment]::GetEnvironmentVariable('Path') -split ';'
  $envpaths2 = $env:path -split ';'
  if($youtubedl_path -notin $envpaths2){
    write-ezlogs "[Get-Youtube] >>>> Adding ytdlp to user enviroment path $youtubedl_path"
    $env:path += ";$youtubedl_path"
    <#    if($youtubedl_path -notin $envpaths){
        [Environment]::SetEnvironmentVariable("Path",[Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";$youtubedl_path",[EnvironmentVariableTarget]::User)
    }#>
  }
  $yt_dl_urls = $Null
  if($Youtube_URL){
    $yt_dl_urls = $Youtube_URL
    if($Import_Profile -and ([IO.File]::Exists($AllYoutube_Media_Profile_File_Path))){ 
      write-ezlogs "[Get-Youtube] | Importing Youtube Media Profile: $AllYoutube_Media_Profile_File_Path" -showtime -enablelogs -logtype Youtube
      $synchash.All_Youtube_Media = Import-SerializedXML -Path $AllYoutube_Media_Profile_File_Path
    }
  }else{
    $yt_dl_urls = $Youtube_playlists
    if(!$synchash.All_Youtube_Media){
      write-ezlogs "[Get-Youtube] | Creating new youtube media collection list" -showtime -logtype Youtube
      $synchash.All_Youtube_Media = [Collections.Generic.List[Media]]::new()
    }
  } 
  if($synchash.All_Youtube_Media){
    if($refresh -and $synchash.Youtube_Playlist_Update.count -gt 0){
      $yt_dl_urls = $yt_dl_urls | Where-Object {$synchash.All_Youtube_Media.playlist_url -notcontains $_ -or $thisApp.Config.Youtube_Playlists -notcontains $_ -or $synchash.Youtube_Playlist_Update -contains $_}
    }else{
      $yt_dl_urls = $yt_dl_urls | Where-Object {$synchash.All_Youtube_Media.playlist_url -notcontains $_ -or $thisApp.Config.Youtube_Playlists -notcontains $_}
    }   
    write-ezlogs "[Get-Youtube] | Number of Youtube playlist urls to process $(@($yt_dl_urls).count)" -showtime -logtype Youtube 
  }  

  try{
    $synchash.Videos_toProcess = [Collections.Generic.List[Object]]::new()
    $synchash.processed_Youtube_tracks = [Collections.Generic.List[Object]]::new()
    $synchash.processed_Youtube_playlists = 0
  }catch{
    write-ezlogs "An exception occurred initializing list collections for Get-Youtube" -catcherror $_
    return
  }
  $total_playlists = @($yt_dl_urls).count 
  try{
    $access_Token = (Get-AccessToken -Name $thisApp.Config.App_name)
  }catch{
    write-ezlogs "[Get-YouTube]  An exception occurred executing Get-AccessToken" -showtime -catcherror $_
  }
  while($MahDialog_hash.Window.isVisible){
    write-ezlogs "[Get-Youtube] >>>> Waiting for WebLogin window to close..." -showtime -LogLevel 2 -logtype Youtube
    start-sleep -Milliseconds 500
  }
  if(!$access_Token){
    write-ezlogs "[Get-Youtube] Unable to retrieve Youtube Authentication! Check logs for more details or try reauthenticating Youtube under Settings - Youtube" -warning -AlertUI
    return
  }
  if(($yt_dl_urls).count -gt 1 -and ($yt_dl_urls).count -lt 128){
    $throttle = $yt_dl_urls.count + 1
  }elseif(($yt_dl_urls).count -ge 128){
    $throttle = 128
  }else{
    $throttle = 2
  }
  write-ezlogs "[Get-Youtube] >>>> Processing $(($yt_dl_urls).count) youtube urls with throttle limit: $throttle" -showtime  -logtype Youtube
  $yt_dl_urls | Where-Object {(Test-ValidPath $_ -Type URL)} | Invoke-Parallel -NoProgress -ThrottleLimit $throttle {
    try{
      $yt_dlp = $null
      $youtube_vp = $null
      if($_ -match '&t='){
        $playlist = ([regex]::matches($_, "(?<value>.*)&t=" ) | %{$_.groups[1].value})
      }else{
        $playlist = $_
      }
      if($thisApp.Config.Youtube_Playlists -notcontains $playlist){
        write-ezlogs "[Get-Youtube] | Adding url to Youtube sources : $playlist" -showtime  -logtype Youtube
        $null = $thisApp.Config.Youtube_Playlists.add($playlist)
      }
      write-ezlogs "[Get-Youtube] >>>> Processsing playlist $($playlist)" -logtype Youtube
      if($playlist -match 'youtube\.com' -or $playlist -match 'youtu\.be'){
        $yt_dlp = [Collections.Generic.List[Object]]::new()
        if($playlist -match '\/tv\.youtube\.com\/'){
          if($playlist -match '\%3D\%3D'){
            $playlist = $playlist -replace '\%3D\%3D'
          }
          if($playlist -match '\?vp='){
            $youtube_vp = ($($playlist) -split('\?vp='))[1].trim()
            $youtube_id = [regex]::matches($playlist, "tv.youtube.com\/watch\/(?<value>.*)\?vp\=")| %{$_.groups[1].value}
          }elseif($playlist -match '\?v='){
            $youtube_id = [regex]::matches($playlist, "tv.youtube.com\/watch\?v=(?<value>.*)")| %{$_.groups[1].value}
          }else{
            $youtube_id = [regex]::matches($playlist, "tv.youtube.com\/watch\/(?<value>.*)")| %{$_.groups[1].value}
          }
          $youtube_type = 'YoutubeTV'   
        }elseif($playlist -match "v="){
          $youtube_id = ($($playlist) -split('v='))[1].trim()  
          $youtube_type = 'YoutubeVideo'                 
        }elseif($playlist -match 'list='){
          $youtube_id = ($($playlist) -split('list='))[1].trim()    
          $youtube_type = 'YoutubePlaylist'                      
        }elseif($playlist -match '\/channel\/'){
          if($playlist -match '\/videos'){
            $playlist = $playlist -replace '\/videos'
          }
          $youtube_id = ($($playlist) -split('\/channel\/'))[1].trim() 
          $youtube_type = 'YoutubeChannel'   
        }elseif($playlist -match "\/watch\/"){
          $youtube_id = [regex]::matches($playlist, "\/watch\/(?<value>.*)")| %{$_.groups[1].value}
          $youtube_type = 'YoutubeVideo'   
        }elseif($playlist -notmatch "v=" -and $playlist -notmatch '\?' -and $playlist -notmatch '\&'){
          $youtube_id = ([uri]$playlist).segments | Select-Object -last 1
          $youtube_type = 'YoutubeVideo'
        }
        write-ezlogs " | Youtube type: $youtube_type" -showtime -logtype Youtube -loglevel 3
        if($youtube_id){
          try{
            if($youtube_type -eq 'YoutubePlaylist'){
              write-ezlogs "Getting info for playlist $playlist - $youtube_id" -showtime -logtype Youtube -loglevel 3
              $youtubePlaylistitems = $(Get-YouTubePlaylistItems -ID $youtube_id)    
              if($youtubePlaylistitems -eq 'Not Found'){
                try{
                  if($thisApp.Config.Youtube_Playlists -contains $playlist){
                    write-ezlogs "[Get-Youtube] | Removing bad playlist url from Youtube sources : $playlist" -showtime  -logtype Youtube
                    $null = $thisApp.Config.Youtube_Playlists.Remove($playlist)
                  }
                }catch{
                  write-ezlogs "An exception occurred Removing bad playlist url from Youtube sources" -catcherror $_
                }   
              }elseif($youtubePlaylistitems){
                Get-YouTubeVideo -Id ($($youtubePlaylistitems).contentDetails.videoid) | & { process {
                    try{ 
                      if($_.id){
                        $item = $_  
                        Add-Member -InputObject $item -Name "youtube_type" -Value $youtube_type -MemberType NoteProperty -Force
                        $playlistinfoindex = $youtubePlaylistitems.contentDetails.videoid.IndexOf($item.id)
                        if($playlistinfoindex -ne -1){
                          $playlistinfo = $youtubePlaylistitems[$playlistinfoindex]
                        }
                        #$playlistinfo = $youtubePlaylistitems | Where-Object {$_.contentDetails.videoid -eq $($item.id)}                  
                        if($playlistinfo.Playlist_info){
                          Add-Member -InputObject $item -Name "Playlist_info" -Value $playlistinfo.Playlist_info -MemberType NoteProperty -Force 
                        }elseif($playlistinfo.snippet){
                          Add-Member -InputObject $item -Name "Playlist_info" -Value $playlistinfo.snippet -MemberType NoteProperty -Force 
                        }
                        if($playlistinfo.snippet.position){
                          Add-Member -InputObject $item -Name "playlist_position" -Value $playlistinfo.snippet.position -MemberType NoteProperty -Force
                        }    
                        if($playlistinfo.id){
                          Add-Member -InputObject $item -Name "playlist_item_id" -Value $playlistinfo.id -MemberType NoteProperty -Force
                        }                                                      
                        lock-object -InputObject $synchash.Videos_toProcess.SyncRoot -ScriptBlock {
                          [void]$synchash.Videos_toProcess.add($item)
                        }                  
                        $playlistinfo = $Null
                        $item = $null
                      }
                    }catch{
                      write-ezlogs "An exception occurred processing Youtube playlist video $($_)" -catcherror $_
                    }
                }}
              }else{
                write-ezlogs "Unable to get playlist items for playlist $playlist - $youtube_id" -showtime -logtype Youtube -warning
              }             
            }elseif($youtube_type -eq 'YoutubeChannel' -or $youtube_type -eq 'YoutubeVideo' -or $youtube_type -eq 'YoutubeTV'){
              write-ezlogs "Getting info for video $playlist - $youtube_id" -showtime -logtype Youtube -loglevel 3
              (Get-YouTubeVideo -Id $youtube_id) | & { process {
                  Add-Member -InputObject $_ -Name "youtube_type" -Value $youtube_type -MemberType NoteProperty -Force
                  lock-object -InputObject $synchash.Videos_toProcess.SyncRoot -ScriptBlock {
                    [void]$synchash.Videos_toProcess.add($_)
                  }                 
              }}
            }           
          }catch{
            write-ezlogs "An exception occurred executing Get-YoutubeVideo" -showtime -catcherror $_
          }        
        }     
      }else{
        write-ezlogs ">>>> Using yt-dlp to get info for playlist $playlist - $youtube_id" -showtime -logtype Youtube -loglevel 2
        if($import_browser_auth){
          (yt-dlp -f bestvideo+bestaudio/best -g $playlist --rm-cache-dir -o '*' -j --cookies-from-browser $import_browser_auth)  | foreach {
            try{
              if(!(Test-URL $_)){
                lock-object -InputObject $synchash.Videos_toProcess.SyncRoot -ScriptBlock {
                  [void]$synchash.Videos_toProcess.add(($_ | Convertfrom-json -ErrorAction SilentlyContinue))
                }                
              }
            }catch{
              write-ezlogs "An exception occurred processing item from yt-dlp: $($_ | out-string)" -catcherror $_
            }
          }
        }else{
          (yt-dlp -f b* -g $playlist --rm-cache-dir -o '*' -j) | foreach {
            try{
              if(!(Test-URL $_)){
                lock-object -InputObject $synchash.Videos_toProcess.SyncRoot -ScriptBlock {
                  [void]$synchash.Videos_toProcess.add(($_ | Convertfrom-json -ErrorAction SilentlyContinue))
                }   
              }
            }catch{
              write-ezlogs "An exception occurred processing item from yt-dlp: $($_ | out-string)" -catcherror $_
            }
          }
        }
      }
      $synchash.processed_Youtube_playlists++
      #$count = @($synchash.processed_Youtube_playlists).count
      try{
        $Controls_to_Update = [Collections.Generic.List[Object]]::new(3) 
        $null = $Controls_to_Update.Add([PSCustomObject]::new(@{
              'Control' = 'YoutubeMedia_Progress_Label'
              'Property' = 'Text'
              'Value' = "Imported ($($synchash.processed_Youtube_playlists) of $($total_playlists)) Youtube Playlists"
        })) 
        $null = $Controls_to_Update.Add([PSCustomObject]::new(@{
              'Control' = 'YoutubeMedia_Progress2_Label'
              'Property' = 'Text'
              'Value' = "Current Playlist: $playlist"
        })) 
        $null = $Controls_to_Update.Add([PSCustomObject]::new(@{
              'Control' = 'YoutubeMedia_Progress2_Label'
              'Property' = 'Visibility'
              'Value' = "Visible"
        }))
        Update-MainWindow -synchash $synchash -thisApp $thisApp -controls $Controls_to_Update
      }catch{
        write-ezlogs "An exception occurred updating YoutubeMedia_Progress_Ring" -showtime -catcherror $_
      }                      
    }catch{
      write-ezlogs "An exception occurred processing $($playlist) with yt-dl" -showtime -catcherror $_
    }
  }
  $youtubePlaylistitems = $Null
  $soundcloud = 'soundcloud'
  if($synchash.Videos_toProcess){
    $synchash.Videos_toProcess | & { process {
        #$video = $_      
        $title = $Null
        $artist = $Null
        $description = $Null
        $channel_id = $Null
        $channel_title = $Null
        $channel_info = $Null
        $url = $Null
        $images = $Null
        $playlist_index = $Null
        $upload_date = $null
        $thumbnail = $null
        $TimeValues = $null
        $video_moreinfo = $null
        $duration = $null
        $hr = $Null
        $mins = $Null
        $secs = $null
        $id = $Null
        $categories = $Null
        $playlist_url = $null
        $playlist_id = $Null
        $playlist_name = $null
        $format_note = $Null
        $likeCount = $Null
        $licensedcontent = $Null
        $type = $Null
        $definition = $Null
        $encodedBytes = $Null
        $encodedid = $Null
        #Type
        if($_.kind -match 'playlistItem' -or $_.youtube_type -eq 'YoutubePlaylist'){
          $type = 'YoutubePlaylistItem'
        }elseif($_.kind -match 'channel' -or $_.youtube_type -eq 'YoutubeChannel'){
          $type = 'YoutubeChannel'
        }elseif($_.kind -match '#subscription' -or $_.youtube_type -eq 'YoutubeSubscription'){
          $type = 'YoutubeSubscription'
        }elseif($_.youtube_type -eq 'YoutubeTV'){
          $type = 'YoutubeTV'
        }elseif($_.kind -match 'video' -or $_.youtube_type -eq 'YoutubeVideo'){
          $type = 'YoutubeVideo'
        }elseif($_.extractor -eq $soundcloud){
          $type = $soundcloud
        }
        #Title
        if(-not [string]::IsNullOrEmpty($_.snippet.title)){
          $title = $_.snippet.title
        }elseif(-not [string]::IsNullOrEmpty($_.title)){
          $title = $_.title
        }
        #Description
        if(-not [string]::IsNullOrEmpty($_.snippet.description)){
          $description =  $_.snippet.description
        }elseif(-not [string]::IsNullOrEmpty($_.description)){
          $description =  $_.description
        } 
        if($type -ne $soundcloud){
          #Channel Info                 
          if(-not [string]::IsNullOrEmpty($_.snippet.videoOwnerChannelId)){
            $channel_id = $_.snippet.videoOwnerChannelId
            $channel_title = $_.snippet.videoOwnerChannelTitle               
          }elseif(-not [string]::IsNullOrEmpty($_.snippet.channelId)){
            $channel_id = $_.snippet.channelId
            $channel_title = $_.snippet.channelTitle  
          }elseif(-not [string]::IsNullOrEmpty($_.channel_id)){
            $channel_id = $_.channel_id
            $channel_title = $_.channel 
          }      
          #TODO: Maybe get channel info at some point, if getting subscriptions
          #if($channel_id){
          #$channel_info = Get-YouTubeChannel -Id $channel_id -raw
          #} 
          #ID, URLs and Playlist
          if(-not [string]::IsNullOrEmpty($_.playlist_info.snippet.title) -or -not [string]::IsNullOrEmpty($_.playlist_info.id)){        
            $playlist_name = $_.playlist_info.snippet.title
            $playlist_id = $_.playlist_info.id
            if(-not [string]::IsNullOrEmpty($_.contentDetails.videoId)){
              $id = $($_.contentDetails.videoId)
            }else{
              $id = $($_.Id)
            }       
            [uri]$playlist_url = "https://www.youtube.com/playlist?list=$playlist_id"
            [uri]$url = "https://www.youtube.com/watch?v=$id"
          }elseif($youtube_type -eq 'YoutubeTV' -and -not [string]::IsNullOrEmpty($_.snippet.title)){
            $playlist_name = $_.snippet.title
            $id = $_.id
            [uri]$url = "https://tv.youtube.com/watch/$id" 
          }elseif(-not [string]::IsNullOrEmpty($_.playlist_info.playlistId)){
            $playlist_name = $channel_title
            $playlist_id = $_.playlist_info.playlistId
            if(-not [string]::IsNullOrEmpty($_.contentDetails.videoId)){
              $id = $($_.contentDetails.videoId)
            }else{
              $id = $($_.Id)
            } 
            [uri]$url = "https://www.youtube.com/watch?v=$id"
            [uri]$playlist_url = "https://www.youtube.com/playlist?list=$playlist_id"
          }elseif(-not [string]::IsNullOrEmpty($_.id)){
            $playlist_name = $channel_title
            $id = $_.id
            [uri]$url = "https://www.youtube.com/watch?v=$id"
          }elseif(-not [string]::IsNullOrEmpty($_.playlist)){
            $playlist_name = $_.playlist
            $id = $_.id
            [uri]$url = "https://www.youtube.com/watch?v=$id"  
          }else{
            $playlist_name = $type
          }                          
          #Images
          if($_.snippet.thumbnails){
            $images = $_.snippet.thumbnails
          }elseif($_.playlist_info.snippet.thumbnails){
            $images = $_.playlist_info.snippet.thumbnails
          }else{
            $images = $Null
          }
          if(-not [string]::IsNullOrEmpty($channel_info.items.BrandingSettings.image.bannerExternalUrl)){
            $thumbnail = $channel_info.items.BrandingSettings.image.bannerExternalUrl
          }elseif(-not [string]::IsNullOrEmpty($_.snippet.thumbnails.standard.url)){
            $thumbnail = $_.snippet.thumbnails.standard.url
          }else{
            $thumbnail = $_.snippet.thumbnails.maxres.url
          }
          #Track Number
          if(-not [string]::IsNullOrEmpty($_.playlist_position)){
            [int]$playlist_index = $_.playlist_position
          }elseif(-not [string]::IsNullOrEmpty($_.snippet.position)){
            [int]$playlist_index = $_.snippet.position
          }else{
            [int]$playlist_index = 1
          }           
          #Duration and other info              
          if(-not [string]::IsNullOrEmpty($_.contentDetails.duration)){
            $TimeValues = $_.contentDetails.duration
            $viewcount = $_.statistics.viewCount 
            #$commentCount = $_.statistics.commentCount
            #$likeCount = $_.statistics.likeCount
            #$format_note = $_.contentDetails.format_note
            #$categories = $_.topicDetails.topicCategories
          }elseif(-not [string]::IsNullOrEmpty($_.contentDetails.videoId)){
            write-ezlogs ">>>> Getting additional video info for video $($_.contentDetails.videoId)" -logtype Youtube -loglevel 2
            $video_moreinfo = Get-YouTubeVideo -Id $_.contentDetails.videoId
            if($video_moreinfo){
              $TimeValues = $video_moreinfo.contentDetails.duration
              $viewcount = $video_moreinfo.statistics.viewCount 
              #$categories = $video_moreinfo.topicDetails.topicCategories 
              #$commentCount = $video_moreinfo.statistics.commentCount
              #$likeCount = $video_moreinfo.statistics.likeCount
              #$format_note = $video_moreinfo.contentDetails.format_note
              $licensedcontent = $video_moreinfo.contentdetails.licensedContent
              $definition = $video_moreinfo.contentdetails.definition
            }
          } 
          if($TimeValues){
            try{         
              $duration =[TimeSpan]::FromHours((Convert-TimespanToInt -Timespan $TimeValues))
              if($duration){
                $duration = "$(([string]$duration.hours).PadLeft(2,'0')):$(([string]$duration.Minutes).PadLeft(2,'0')):$(([string]$duration.Seconds).PadLeft(2,'0'))"
              }             
            }catch{
              write-ezlogs "An exception occurred parsing duration for $($title) from ($hr`:$mins`:$secs)" -showtime -catcherror $_
            }
          }   
        }else{
          write-ezlogs ">>>> Media type is Soundcloud" -logtype Youtube -loglevel 2
          $id = $_.id
          [uri]$url = $_.webpage_url 
          $thumbnail = $_.snippet.thumbnail
          [int]$playlist_index = $_.playlist_index
          $images = $_.thumbnails
          $viewcount = $_.view_count
          if($_.duration){
            try{         
              $duration =[TimeSpan]::FromSeconds($_.duration)       
              if($duration){
                $duration = "$(([string]$duration.hours).PadLeft(2,'0')):$(([string]$duration.Minutes).PadLeft(2,'0')):$(([string]$duration.Seconds).PadLeft(2,'0'))"
              }             
            }catch{
              write-ezlogs "An exception occurred parsing duration for $($title) from $($_.duration)" -showtime -catcherror $_
            }
          }
        }   
        if(-not [string]::IsNullOrEmpty($channel_title)){
          $artist = $channel_title
        }elseif(-not [string]::IsNullOrEmpty($_.uploader)){
          $artist = $_.uploader                
        }else{
          $artist = $playlist_name
        }
        if(-not [string]::IsNullOrEmpty($_.snippet.publishedAt)){
          $upload_date = $_.snippet.publishedAt
        }elseif(-not [string]::IsNullOrEmpty($_.upload_date)){
          $upload_date = $_.upload_date               
        }else{
          $upload_date = $null
        } 
        $encodedBytes = [Text.Encoding]::UTF8.GetBytes("$($id)-$($Playlist_ID)")
        $encodedid = [Convert]::ToBase64String($encodedBytes)  
        if(-not [string]::IsNullOrEmpty($thisApp.Config.YoutubeMedia_Display_Syntax)){
          $DisplayName = $thisApp.Config.YoutubeMedia_Display_Syntax -replace '%artist%',$artist -replace '%title%',$title -replace '%track%',$playlist_index -replace '%playlist%',$playlist_name
        }else{
          $DisplayName = $Null
        }  
        $newRow = [Media]@{
          'Id' = $id
          'Artist' = [string]$artist
          'Album' = ''
          'Title' = [string]$title
          'Playlist' = [string]$playlist_name
          'Playlist_ID' = $playlist_id
          'Playlist_Item_ID' = $_.playlist_item_id
          'Playlist_url' = $playlist_URL
          'Channel_ID' = $channel_id
          'Description' = [string]$description
          'Cached_Image_Path' = $thumbnail
          'Source' = 'Youtube'
          'Profile_Date_Added' = [Datetime]::Now.ToString()
          'url' = $url
          'type' = [string]$type
          'Track' = $playlist_index
          'Duration' = $duration
          'Display_Name' = $DisplayName
        }                 
        lock-object -InputObject $synchash.All_Youtube_Media.SyncRoot -ScriptBlock {
          if($synchash.processed_Youtube_tracks -notcontains $encodedid){
            write-ezlogs ">>>> Adding Youtube Video to All_Youtube_Media: URL: $($url) - ID: $($id) - Title: $($title)" -logtype Youtube -loglevel 3
            [void]$synchash.processed_Youtube_tracks.add($encodedid)
            [void]$synchash.All_Youtube_Media.add($newRow)  
          }else{
            write-ezlogs "Duplicate Youtube media found $($title) - ID $($id) - Playlist $($Playlist_name)" -showtime -warning -logtype Youtube
          }
        }        
      }               
  }}
  if($export_profile -and $AllYoutube_Media_Profile_File_Path -and $synchash.All_Youtube_Media){
    write-ezlogs ">>>> Saving Available Youtube Media profile to $AllYoutube_Media_Profile_File_Path" -showtime -logtype Youtube
    Export-SerializedXML -InputObject $synchash.All_Youtube_Media -path $AllYoutube_Media_Profile_File_Path
  }  
  #$synchash.Youtube_FirstRun = $false
  if($synchash.Videos_toProcess){
    $null = $synchash.Videos_toProcess.clear()
    $synchash.Videos_toProcess = $null
  }
  if($yt_dl_urls){
    $yt_dl_urls = $Null
  } 
  if($synchash.processed_Youtube_playlists){
    #$synchash.processed_Youtube_playlists.clear()
    $synchash.processed_Youtube_playlists = $null
  }
  if($synchash.processed_Youtube_tracks){
    $synchash.processed_Youtube_tracks.clear()
    $synchash.processed_Youtube_tracks = $null
  }
  if($Verboselog){write-ezlogs " | Number of Youtube Playlists found: $($synchash.All_Youtube_Media.Count)" -showtime -enablelogs -logtype Youtube}      
  if($GetYoutube_stopwatch){
    $GetYoutube_stopwatch.stop()
    write-ezlogs "###### Get-Youtube Finished" -PerfTimer $GetYoutube_stopwatch -Perf -logtype Youtube -GetMemoryUsage -forceCollection
  }
}
#---------------------------------------------- 
#endregion Get-Youtube Function
#----------------------------------------------

#---------------------------------------------- 
#region Add-YoutubePlaylist Function
#----------------------------------------------
function Add-YoutubePlaylist
{
  Param (
    $thisApp,
    $synchash,
    $media,
    $Sender,
    [switch]$Verboselog
  )
  try{
    $illegal =[Regex]::Escape(-join [Io.Path]::GetInvalidPathChars())
    $pattern = "[™`�$illegal]"   
    $AllYoutube_Profile_File_Path = [IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Youtube_MediaProfile','All-Youtube_Media-Profile.xml')  
    if($sender.header -eq 'Add to New Playlist..'){
      if($synchash.MediaLibrary_Viewer.isVisible){
        $Playlist = [Microsoft.VisualBasic.Interaction]::InputBox('Add New Youtube Playlist', 'Enter the name of the new Youtube playlist')
      }else{
        $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new() 
        $Playlist = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalInputExternal($synchash.Window,'Add New Youtube Playlist','Enter the name of the new Youtube playlist',$Button_Settings)
      }
      if(-not [string]::IsNullOrEmpty($Playlist)){  
        write-ezlogs ">>>> Verifying new Youtube playlist name to add: $Playlist" -logtype Youtube
        $Playlist = ([Regex]::Replace($Playlist, $pattern, '')).trim() 
        [int]$character_Count = ($Playlist | measure-object -Character -ErrorAction SilentlyContinue).Characters
        if([int]$character_Count -ge 100){
          write-ezlogs "Playlist name too long! ($character_Count characters). Please choose a name 100 characters or less " -showtime -warning -logtype Youtube
          if($synchash.MediaLibrary_Viewer.isVisible){
            $result=[Windows.Forms.MessageBox]::Show("Please choose a name for the playlist that is 100 characters or less","Playlist name too long! ($character_Count)",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning) 
          }else{
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Playlist name too long! ($character_Count)","Please choose a name for the playlist that is 100 characters or less",$okandCancel,$Button_Settings)
          }
          return
        }
        $playlist_check = $synchash.All_Youtube_Media | Where-Object {$_.Playlist -eq $Playlist} | Select-Object Playlist_ID,Playlist -Unique
        if(-not [string]::IsNullOrEmpty($playlist_check)){ 
          write-ezlogs "An existing Playlist with the name $Playlist already exists!" -warning -logtype Youtube
          if($synchash.MediaLibrary_Viewer.isVisible){
            $result=[Windows.Forms.MessageBox]::Show("Please choose a unique name for the new playlist","An existing Playlist with the name $Playlist already exists!",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning) 
          }else{
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"An existing Playlist with the name $Playlist already exists!","Please choose a unique name for the new playlist",$okandCancel,$Button_Settings)
          }
          return
        }
        write-ezlogs "| Creating new Youtube playlist with name $Playlist" -loglevel 2 -logtype Youtube
        $target_playlist = New-YoutubePlaylist -synchash $synchash -thisApp $thisApp -PlaylistName $Playlist -PrivacyStatus private
        if($target_playlist.id){
          write-ezlogs "Created new Youtube Playlist $($target_playlist.snippet.title) with ID $($target_playlist.id)" -LogLevel 2 -Success -logtype Youtube
          $targetplaylist_Name = $target_playlist.snippet.title
          $target_Url = "https://www.youtube.com/playlist?list=$($target_playlist.id)"
          $target_PlaylistID = $target_playlist.id
        }else{
          write-ezlogs "Youtube did not return results creating new playlist $($Playlist). Check the logs for errors/details or try again later" -warning -logtype Youtube
          if($synchash.MediaLibrary_Viewer.isVisible){
            $result=[Windows.Forms.MessageBox]::Show("Youtube did not return results when creating new playlist $($Playlist). Check the logs for errors/details or try again later","Youtube Playlist not successfully created!",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning) 
          }else{
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Youtube did not return results when creating new playlist $($Playlist). Check the logs for errors/details or try again later","Youtube Playlist not successfully created!",$okandCancel,$Button_Settings)
          }
          return
        }    
      }
    }elseif($sender.header){
      $Playlist = $sender.header
      $target_playlist = $synchash.All_Youtube_Media | Where-Object {$_.Playlist -eq $Playlist} | Select-Object Playlist_ID,Playlist,Playlist_Url,Type -Unique
      if(@($target_playlist).count -gt 1){
        write-ezlogs "Found multiple ($(@($target_playlist).count)) playlists with the name $Playlist" -warning -logtype Youtube
        #TODO: Need to add handling for multipole Youtube lists with same name since they allow it. Need to pass playlist ID
        $target_playlist = $target_playlist | Select-Object -last 1
      }
      $targetplaylist_Name = $target_playlist.Playlist
      $target_Url = $target_playlist.Playlist_Url
      $target_PlaylistID = $target_playlist.Playlist_ID
    }else{
      write-ezlogs "Unable to determine action to perform or was not passed a valid playlist name, cannot continue!" -warning -logtype Youtube
      return
    }
    if($Media.type -match 'Youtube' -or $Media.url -match 'youtube\.com' -or $Media.Source -eq 'Youtube'){   
      #$source_playlist = $synchash.SpotifyTable.Itemssource.SourceCollection | where {$_.PlayList_tracks.id -eq $Media.id}    
      #$synchash.All_Youtube_Media | where {$_.id -eq $Media.id} | select Playlist_ID,Playlist,Playlist_Url -Unique
      if($target_PlaylistID -and $Media.id){      
        $add = Add-YoutubePlaylistItem -thisApp $thisApp -synchash $synchash -PlaylistID $target_PlaylistID -VideoID $Media.id
        if($add.contentDetails.videoId){
          write-ezlogs "Added video $($Media.title) to Youtube Playlist $($targetplaylist_Name)" -logtype Youtube -Success
          if($thisApp.Config.Youtube_Playlists -notcontains $target_Url){
            try{
              write-ezlogs " | Adding new Youtube Playlist URL to config: $($target_Url) - Playlist Name: $($targetplaylist_Name)" -showtime -logtype Youtube -loglevel 3
              $null = $thisApp.Config.Youtube_Playlists.add($target_Url)
              if(![IO.Directory]::Exists("$($thisapp.config.Playlist_Profile_Directory)\Youtube_Playlists")){
                try{
                  $Null = New-item -Path "$($thisapp.config.Playlist_Profile_Directory)\Youtube_Playlists" -ItemType Directory -Force
                }catch{
                  write-ezlogs "An exception occurred creating new directory $($thisapp.config.Playlist_Profile_Directory)\Youtube_Playlists" -showtime -catcherror $_
                }             
              }
              if([IO.File]::Exists("$($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml")){
                try{
                  $Playlist_Profile = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText("$($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml"))
                }catch{
                  write-ezlogs "An exception occurred importing playlist template $($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml" -showtime -catcherror $_
                }             
              }
              if($Playlist_Profile -and $target_Url){ 
                if($hashsetup.Youtube_Playlists_Import){
                  $hashsetup.window.Dispatcher.Invoke("Normal",[action]{ 
                      if($hashsetup.Youtube_Playlists_Import.isEnabled){
                        $hashsetup.Youtube_Playlists_Import.RaiseEvent([Windows.RoutedEventArgs]::New([Windows.Controls.Button]::ClickEvent)) 
                      }                                                         
                  })
                }                
                #$playlistName_Cleaned = ([Regex]::Replace($targetplaylist_Name, $pattern, '')).trim()             
                $Playlist_Profile_path = "$($thisapp.config.Playlist_Profile_Directory)\Youtube_Playlists\$($target_PlaylistID).xml"
                write-ezlogs " | Saving new Youtube Playlist profile to $Playlist_Profile_path" -showtime -logtype Youtube -loglevel 3
                $Playlist_Profile.name = $targetplaylist_Name
                #$Playlist_Profile.NameCleaned = $playlistName_Cleaned
                $Playlist_Profile.Playlist_ID = $target_PlaylistID
                $Playlist_Profile.Playlist_URL = $target_Url
                $Playlist_Profile.type = 'YoutubePlaylist'
                $Playlist_Profile.Playlist_Path = $Playlist_Profile_path
                $Playlist_Profile.PlayList_Info = $target_playlist
                $Playlist_Profile.Playlist_Date_Added = $([DateTime]::Now.ToString())
                $Playlist_Profile.Source = 'Youtube'
                Export-Clixml -InputObject $Playlist_Profile -path $Playlist_Profile_path -Force -Encoding Default
                try{
                  if($synchash.all_playlists){
                    foreach($customplaylist in $synchash.all_playlists){
                      $custom_playlists = $playlist_Profile.PlayList_tracks.values | Where-Object {$_.Playlist_URL -match 'youtu\.be' -or $_ -match 'youtube\.com'}
                      foreach($item in $custom_playlists){      
                        $customplaylist_Name = $Null       
                        if($item.id -eq $Media.id){
                          write-ezlogs " | Updating media from custom playlist id: $($item.playlist_id) to new playlist id: $($target_PlaylistID) - playlist profile path: $($customplaylist)" -logtype Youtube
                          $PlaylistUpdate = $true
                          $item.playlist_id = $target_PlaylistID
                          $item.Playlist_url = $target_Url
                          $playlist_Profile.Playlist_ID = $target_PlaylistID
                          $playlist_Profile.Playlist_url = $target_Url
                          if($item.cached_image_path){
                            $item.cached_image_path = $null
                          }
                        }
                      }
                    }
                    if($PlaylistUpdate){
                      write-ezlogs ">>>> Saving all_playlists library to: $($thisApp.Config.Playlists_Profile_Path)" -logtype Youtube
                      Export-SerializedXML -InputObject $synchash.All_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist
                    }
                  }
                }catch{
                  write-ezlogs "An exception occurred parsing or updating custom playlists in $($thisApp.config.Playlist_Profile_Directory)" -showtime -catcherror $_
                }
                Get-YoutubeStatus -thisApp $thisApp -synchash $Synchash -verboselog:$thisApp.Config.Verbose_logging -checkall -Use_runspace
                #Import-Youtube -Youtube_playlists $thisapp.Config.Youtube_Playlists -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -thisApp $thisapp -use_runspace -refresh                                
              }
            }catch{
              write-ezlogs "An exception occurred adding path $($target_Url) to Youtube_Playlists" -showtime -catcherror $_
            }
          }else{    
            try{
              $index = $synchash.All_Youtube_Media.id.IndexOf($media.id)
              if($index -ne -1){
                $track_to_add = $synchash.All_Youtube_Media.Item($index)
              }else{
                $track_to_add = $media
              }             
            }catch{
              $track_to_add = $null
            }
            write-ezlogs ">>>> Adding media with id: $($track_to_add.id) to All_Youtube_Media playlist $($playlist)" -logtype Youtube
            $target_playlistitems = $synchash.All_Youtube_Media | Where-Object {$_.Playlist -eq $Playlist}

            <#            $CustomPlaylist_pattern = [regex]::new('$(?<=((?i)CustomPlaylist.xml))')
                if([system.io.directory]::Exists($thisApp.config.Playlist_Profile_Directory)){
                $existing_CustomPlaylist = [System.IO.Directory]::EnumerateFiles($thisApp.config.Playlist_Profile_Directory,'*','AllDirectories') | where {$_ -match $CustomPlaylist_pattern} 
            }#>
            try{
              if($synchash.all_playlists){
                foreach($customplaylist in $synchash.all_playlists){
                  $custom_playlists = $playlist_Profile.PlayList_tracks.values | Where-Object {$_.Playlist_URL -match 'youtu\.be' -or $_ -match 'youtube\.com'}
                  foreach($item in $custom_playlists){      
                    $customplaylist_Name = $Null       
                    if($item.id -eq $track_to_add.id){
                      write-ezlogs " | Updating media from custom playlist id: $($item.playlist_id) to new playlist id: $($target_PlaylistID) - playlist profile path: $($customplaylist)" -logtype Youtube
                      $PlaylistUpdate = $true
                      $item.playlist_id = $target_PlaylistID
                      $item.Playlist_url = $target_Url
                      $playlist_Profile.Playlist_ID = $target_PlaylistID
                      $playlist_Profile.Playlist_url = $target_Url
                      if($item.cached_image_path){
                        $item.cached_image_path = $null
                      } 
                    }
                  }
                }
                if($PlaylistUpdate){
                  write-ezlogs ">>>> Saving all_playlists library to: $($thisApp.Config.Playlists_Profile_Path)" -logtype Youtube
                  Export-SerializedXML -InputObject $synchash.All_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist
                }
              }
            }catch{
              write-ezlogs "An exception occurred parsing or updating custom playlists in $($thisApp.config.Playlist_Profile_Directory)" -showtime -catcherror $_
            }
            if($track_to_add -and $target_playlistitems.id -notcontains $media.id){
              write-ezlogs " | Changing media $($track_to_add.title) with ID $($track_to_add.id) from playlist: $($track_to_add.Playlist) to playlist: $Playlist" -logtype Youtube
              $track_to_add.playlist_id = $target_PlaylistID
              $track_to_add.Playlist_url = $target_Url
              $track_to_add.Playlist = $Playlist
              if($track_to_add.cached_image_path){
                $track_to_add.cached_image_path = $null
              }                           
              #$null = $synchash.All_Youtube_Media.Remove($track_to_add)  
              if([IO.File]::Exists($AllYoutube_Profile_File_Path)){               
                write-ezlogs " | Updating All Youtube profile cache at $AllYoutube_Profile_File_Path" -showtime -logtype Youtube    
                try{  
                  Export-SerializedXML -InputObject $synchash.All_Youtube_Media -path $AllYoutube_Profile_File_Path
                }catch{
                  write-ezlogs "An exception occurred saving All Youtube Profile Cache to $AllYoutube_Profile_File_Path" -showtime -catcherror $_
                }                        
              }
            }else{
              write-ezlogs "Target playlist $Playlist already contains media $($media.title) with ID $($media.id) - Doing refresh of Youtube library" -showtime -warning -logtype Youtube           
            }
            Get-YoutubeStatus -thisApp $thisApp -synchash $Synchash -verboselog:$thisApp.Config.Verbose_logging -checkall -Use_runspace
          }
        }else{
          write-ezlogs "Unable to add track $($Media.title) - ID: $($Media.id) - uri: $($Media.Url) to playlist $($Playlist)- id: $($target_PlaylistID)" -showtime -warning -logtype Youtube
          if($synchash.MediaLibrary_Viewer.isVisible){
            $result=[Windows.Forms.MessageBox]::Show("Unable to add track $($Media.title) to $($Playlist). Check the logs for errors/details or try again later","Youtube video not added to Playlist!",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning) 
          }else{
            $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
            $Button_Settings.AffirmativeButtonText = 'Ok'
            $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
            $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Unable to add video $($Media.title) to $($Playlist). Check the logs for errors/details or try again later","Youtube video not added to Playlist!",$okandCancel,$Button_Settings)
          }
          return
        }
      }                 
    }
  }catch{
    write-ezlogs "An exception occurred in Add-YoutubePlaylist - Media: $($media | out-string)" -showtime -catcherror $_
  }  
}
#---------------------------------------------- 
#endregion Add-YoutubePlaylist Function
#----------------------------------------------

#---------------------------------------------- 
#region Remove-YoutubePlaylist Function
#----------------------------------------------
function Remove-YoutubePlaylist
{
  Param (
    $thisApp,
    $synchash,
    $media,
    $Sender,
    [switch]$Use_runspace,
    [switch]$Verboselog
  )

  $Remove_YoutubePlaylist_Scriptblock = {
    Param (
      $thisApp = $thisApp,
      $synchash = $synchash,
      $media = $media,
      [switch]$Use_runspace = $Use_runspace,
      $Sender = $Sender,
      [switch]$Verboselog = $Verboselog
    )
    try{
      $illegal =[Regex]::Escape(-join [Io.Path]::GetInvalidPathChars())
      $pattern = "[™`�$illegal]"   
      $Playlist = $sender.header
      $Removeerrors = 0
      $RemovedSuccess = 0
      foreach($media in $media){
        #Get media from main profile in case missing playlist_item_id, media object could have been passed from old playlist without this property
        if([string]::IsNullOrEmpty($media.playlist_item_id)){
          $media = Get-mediaprofile -thisApp $thisApp -synchash $synchash -Media_ID $Media.id
        }
        if($Media.type -match 'YoutubePlaylistItem' -or $Media.url -match 'youtube' -or $Media.Source -eq 'Youtube'){ 
          $target_playlist = $synchash.All_Youtube_Media.where({$_.type -eq 'YoutubePlaylistItem' -and $_.playlist -eq $Playlist}) | Select-Object Playlist_ID,Playlist,Playlist_URL -Unique
          if([string]::IsNullOrEmpty($target_playlist.playlist_id)){
            write-ezlogs ">>>> Unable to remove video '$($Media.title)' from Youtube Playlist '$($Playlist)', playlist not found" -logtype Youtube -warning
            $Removeerrors++
            continue
          }else{
            $target_playlist | foreach {
              $PlaylistID = $_.playlist_id
              write-ezlogs ">>>> Removing video '$($Media.title)' from Youtube Playlist '$($target_playlist.name)'" -logtype Youtube
              if($PlaylistID -and $media.playlist_item_id){      
                $remove = Remove-YoutubePlaylistItem -thisApp $thisApp -synchash $synchash -PlaylistID $PlaylistID -VideoID $media.playlist_item_id
                if($remove){
                  $RemovedSuccess++
                  write-ezlogs "Removed track $($Media.title) from Youtube Playlist $($_.Playlist)" -logtype Youtube -Success
                }else{
                  $Removeerrors++
                }
              }else{
                write-ezlogs "Unable to remove track $($Media.title) - ID: $($Media.id) - uri: $($Media.Url) from playlist $($target_playlist.name)- id: $($target_playlist.id)" -showtime -warning  -logtype Spotify
                $Removeerrors++
              }      
            }
          }          
        }                 
      }
      if($Removeerrors -gt 0){
        if($synchash.MediaLibrary_Viewer.isVisible){
          $result=[Windows.Forms.MessageBox]::Show("Unable to remove some videos from playlsist '$($Playlist)'. Check the logs for errors/details or try again later","Youtube Videos not Removed from Playlist!",[Windows.Forms.MessageBoxButtons]::OK,[Windows.Forms.MessageBoxIcon]::Warning) 
        }else{
          $Button_Settings = [MahApps.Metro.Controls.Dialogs.MetroDialogSettings]::new()       
          $Button_Settings.AffirmativeButtonText = 'Ok'
          $okandCancel = [MahApps.Metro.Controls.Dialogs.MessageDialogStyle]::Affirmative
          $dialogresult = [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowModalMessageExternal($synchash.Window,"Unable to remove some videos from playlist '$($Playlist)'. Check the logs for errors/details or try again later","Youtube Videos not Removed from Playlist!",$okandCancel,$Button_Settings)
        }
      }
      if($RemovedSuccess -gt 0){
        write-ezlogs ">>>> Executing Get-YoutubeStatus to refresh Youtube library"-logtype Youtube
        Get-YoutubeStatus -thisApp $thisApp -synchash $synchash -Use_runspace:($Use_runspace -eq $false)
        #Import-Youtube -Youtube_playlists $thisapp.Config.Youtube_Playlists -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -thisApp $thisapp -use_runspace -refresh
      }
    }catch{
      write-ezlogs "An exception occurred in Remove-YoutubePlaylist - Media: $($media | out-string)" -showtime -catcherror $_
    }
  }  
  if($Use_runspace){
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
    Start-Runspace -scriptblock $Remove_YoutubePlaylist_Scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'Remove_YoutubePlaylist_RUNSPACE' -thisApp $thisApp -synchash $synchash
    Remove-Variable Variable_list
  }else{
    Invoke-Command -ScriptBlock $Remove_YoutubePlaylist_Scriptblock
  }
}
#---------------------------------------------- 
#endregion Remove-YoutubePlaylist Function
#----------------------------------------------

#---------------------------------------------- 
#region Start-YoutubeMonitor Function
#----------------------------------------------
function Start-YoutubeMonitor
{
  Param (
    $Interval,
    $thisApp,
    $synchash,
    [switch]$Startup,
    [switch]$Stop,
    [switch]$Verboselog = $thisApp.Config.Verbose_logging
  ) 
  write-ezlogs "#### Starting Youtube Monitor ####" -enablelogs -color yellow -linesbefore 1 -logtype Youtube -LogLevel 2
  if($thisApp.config.Youtube_Update_Interval -eq 'On Startup'){
    $thisApp.YoutubeMonitorEnabled = $false
    write-ezlogs "Cannot start Youtube monitor, Youtube_Update_Interval is set to 'On Startup'" -logtype Youtube -warning   
    return
  }  
  $Sleep_Value = [TimeSpan]::Parse($Interval).TotalSeconds
  $Youtube_Status_Monitor_Scriptblock = {
    Param (
      $Interval,
      $thisApp,
      $synchash,
      [switch]$Startup,
      [switch]$Stop,
      [switch]$Verboselog
    )
    $ProgressPreference = 'SilentlyContinue'
    $Youtube_Monitor_Timer = 0    
    try{      
      $Sleep_Value = [TimeSpan]::Parse($Interval).TotalSeconds
      write-ezlogs " | Interval Seconds: $sleep_value" -showtime -logtype Youtube -LogLevel 2
      $LastUpdate_Youtube_Monitor_Timer = [datetime]::Now
      if($thisApp.YoutubeMonitorEnabled){
        $thisApp.YoutubeMonitorEnabled = $false
        start-sleep 1
      }
      $thisApp.YoutubeMonitorEnabled = $true
      $HasRunYet = $false
      while($thisApp.config.Youtube_Update -and $thisApp.config.Youtube_Update_Interval -ne $null -and $thisApp.YoutubeMonitorEnabled){            
        $Sleep_Value = [TimeSpan]::Parse($thisApp.config.Youtube_Update_Interval).TotalSeconds
        if([datetime]::Now -ge $LastUpdate_Youtube_Monitor_Timer.AddSeconds($Sleep_Value) -or !$HasRunYet){
          try{
            $HasRunYet = $true
            $checkupdate_timer = [diagnostics.stopwatch]::StartNew()
            Get-YoutubeStatus -thisApp $thisApp -synchash $Synchash -verboselog:$thisApp.Config.Verbose_logging -checkall -Use_runspace:$false
            Write-ezlogs "[Start-YoutubeMonitor] Ran for: $($checkupdate_timer.Elapsed.TotalSeconds) seconds" -showtime -logtype Youtube -LogLevel 2
          }catch{
            write-ezlogs "An exception occurred executing Get-YoutubeStatus" -showtime -catcherror $_
          }finally{
            $LastUpdate_Youtube_Monitor_Timer = [datetime]::Now
            $checkupdate_timer.Restart()
          }
        }
        $Youtube_Monitor_Timer++
        start-sleep -Seconds 1
        #start-sleep -Seconds $Sleep_Value
      }
      if(!$thisApp.config.Youtube_Update){
        write-ezlogs "Youtube Monitor ended due to Youtube_Update option being disabled - It ran for $($Youtube_Monitor_Timer) seconds" -showtime -warning -logtype Youtube -LogLevel 2
      }else{
        write-ezlogs "Youtube Monitor has ended - It ran for $($Youtube_Monitor_Timer) seconds" -showtime -warning -logtype Youtube -LogLevel 2
      }
    }catch{
      write-ezlogs "An exception occurred in Youtube_status_Monitor_Scriptblock" -showtime -catcherror $_
    }
  }
  if($thisApp.config.Youtube_Update -and $Sleep_Value -ne $null){
    $keys = $PSBoundParameters.keys
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant" -and $_.Name -in $keys){$_}}}
    Start-Runspace $Youtube_Status_Monitor_Scriptblock -arguments $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "Youtube_Monitor_Runspace" -thisApp $thisApp
    Remove-Variable Variable_list
    Remove-Variable Youtube_Status_Monitor_Scriptblock
  }else{
    write-ezlogs "No sleep value was provided or found, cannot continue" -showtime -warning -logtype Youtube -LogLevel 2
  }
}
#---------------------------------------------- 
#endregion Start-YoutubeMonitor Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-YoutubeStatus Function
#----------------------------------------------
function Get-YoutubeStatus
{
  Param (
    [switch]$Use_runspace,
    $thisApp,
    $synchash,
    $log = $thisApp.Config.YoutubeMedia_logfile,
    [switch]$Startup,
    [switch]$Export_Profile,
    [string]$Media_Profile_Directory,
    [switch]$Verboselog
  )  
  write-ezlogs "#### Checking for new Youtube playlists" -showtime -logtype Youtube -LogLevel 2 -linesbefore 1    
  try{      
    if($thisApp.Config.Import_Youtube_Media){       
      $checkYoutube_scriptblock = {   
        Param(
          $thisApp = $thisApp,
          $synchash = $synchash,
          [string]$log = $log
        ) 
        try{
          $checkYoutube_stopwatch = [diagnostics.stopwatch]::StartNew() 
          $illegal =[Regex]::Escape(-join [Io.Path]::GetInvalidFileNameChars())
          $pattern = "[™$illegal]"
          $pattern2 = "[:$illegal]"
          $pattern3 = "[`?�™:$illegal]"    
          try{
            $internet_Connectivity = Test-ValidPath -path 'www.youtube.com' -PingConnection -timeout_milsec 1000
          }catch{
            write-ezlogs "Ping test failed for: www.youtube.com - trying 1.1.1.1" -Warning -logtype youtube
          }finally{
            try{
              if(!$internet_Connectivity){
                $internet_Connectivity = Test-ValidPath -path '1.1.1.1' -PingConnection -timeout_milsec 2000
              }
            }catch{
              write-ezlogs "Secondary ping test failed for: 1.1.1.1" -Warning -logtype youtube
              $internet_Connectivity = $null
            }
          }
          if($internet_Connectivity){
            try{
              $youtube_playlists = Get-YouTubePlaylists -mine
            }catch{
              write-ezlogs "An exception occurred retrieving youtube playlists with Get-YoutubePlaylists" -showtime -catcherror $_
            } 
            $newplaylists = 0
            $newvideos = 0
            $removedvideos = 0
            $newchannels = 0   
            $YoutubePlaylists_itemsArray = [Collections.Generic.List[Object]]::new()
            $synchash.Youtube_Playlist_Update = [Collections.Generic.List[Object]]::new()
            if($youtube_playlists){        
              $youtube_playlists | & { Process {
                  $playlist = $_
                  $existingplaylistcount = $Null     
                  $playlistcount = $null             
                  $playlisturl = "https://www.youtube.com/playlist?list=$($playlist.id)"
                  $playlistName = $playlist.snippet.title
                  $playlistcount = $playlist.contentdetails.itemCount
                  try{
                    $existingplaylistcount = ($synchash.All_Youtube_Media.where({$_.Playlist_id -eq $playlist.id})).count
                  }catch{
                    $existingplaylistcount = $Null
                    $playlistcount = $Null
                    write-ezlogs "An exception occurred enumerating All_Youtube_Media for playlist_id $($playlist.id)" -catcherror $_
                  }                          
                  if($YoutubePlaylists_itemsArray.path -notcontains $playlisturl){
                    #write-ezlogs "Adding Youtube Playlist URL $playlisturl" -showtime -logtype Youtube -loglevel 3
                    if(!$YoutubePlaylists_itemsArray.Number){ 
                      $Number = 1
                    }else{
                      $Number = $YoutubePlaylists_itemsArray.Number | Select-Object -last 1
                      $Number++
                    }
                    $null = $YoutubePlaylists_itemsArray.add([PSCustomObject]@{
                        Number=$Number
                        ID = $playlist.id
                        Name=$playlistName
                        Path=$playlisturl
                        Type='YoutubePlaylist'
                        Playlist_Info = $playlist
                    })
                  }
                  if($thisApp.Config.Youtube_Playlists -notcontains $playlisturl){
                    $newplaylists++
                  }elseif($playlistcount -gt $existingplaylistcount){
                    $newvideos += ($playlistcount - $existingplaylistcount)
                    if($synchash.Youtube_Playlist_Update -notcontains $playlisturl){
                      $Null = $synchash.Youtube_Playlist_Update.add($playlisturl)
                      write-ezlogs ">>>> Playlist $($playlistName) has new videos - New Count: $playlistcount - Existing: $existingplaylistcount - Playlist URL: $($playlisturl)" -logtype Youtube
                    }                
                  }elseif($existingplaylistcount -gt $playlistcount){
                    $removedvideos += ($existingplaylistcount - $playlistcount)
                    if($synchash.Youtube_Playlist_Update -notcontains $playlisturl){
                      $Null = $synchash.Youtube_Playlist_Update.add($playlisturl)
                      write-ezlogs ">>>> Playlist $($playlistName) has removed videos - New Count: $playlistcount - Existing: $existingplaylistcount - Playlist URL: $($playlisturl)" -logtype Youtube
                    }
                  }
              }}
            }
            try{
              if($thisApp.Config.Import_My_Youtube_Media){
                $channel = Get-YouTubeChannel -mine -Raw
                if($channel.items.contentdetails.relatedPlaylists.uploads){
                  $playlistid = $($channel.items.contentdetails.relatedPlaylists.uploads)
                  #$channelurl = "https://www.youtube.com/channel/$($channel.items.id)/videos"
                  $playlisturl = "https://www.youtube.com/playlist?list=$($playlistid)"
                  $channelName = $channel.items.snippet.title
                  if($YoutubePlaylists_itemsArray.path -notcontains $playlisturl){
                    #write-ezlogs "Adding Youtube Channel URL $playlisturl" -showtime -logtype Youtube -loglevel 3
                    if(!$YoutubePlaylists_itemsArray.Number){ 
                      $Number = 1
                    }else{
                      $Number = $YoutubePlaylists_itemsArray.Number | Select-Object -last 1
                      $Number++
                    }
                    $null = $YoutubePlaylists_itemsArray.add([PSCustomObject]::new(@{
                          Number=$Number;       
                          ID = $playlistid
                          Name=$channelName
                          Path=$playlisturl
                          Type='YoutubePlaylist'
                          Playlist_Info = $channel.items
                    }))
                    if($thisApp.Config.Youtube_Playlists -notcontains $playlisturl){
                      $newplaylists++
                    }
                  }else{
                    write-ezlogs "The Youtube Channel URL $playlisturl has already been added!" -showtime -warning -logtype Youtube
                  }           
                }
              }
              if($thisApp.Config.Import_My_Youtube_Subscriptions){
                try{
                  $ytsubs = Get-YouTubeSubscription -Raw
                  if($ytsubs.snippet.resourceId.channelId){
                    foreach($sub in $ytsubs){
                      $channelid = $($sub.snippet.resourceId.channelId)
                      $channelName = $sub.snippet.title                 
                      $channel = Get-YouTubeChannel -Id $channelid -Raw
                      if($channel.items.contentdetails.relatedPlaylists.uploads){
                        $playlisturl = "https://www.youtube.com/playlist?list=$($channel.items.contentdetails.relatedPlaylists.uploads)"
                      }else{
                        $playlisturl = "https://www.youtube.com/channel/$($channelid)"  
                      }                   
                      if($YoutubePlaylists_itemsArray.path -notcontains $playlisturl){
                        write-ezlogs "Adding Youtube Subscription Channel URL $playlisturl" -showtime -logtype Youtube -loglevel 3
                        if(!$YoutubePlaylists_itemsArray.Number){ 
                          $Number = 1
                        }else{
                          $Number = $YoutubePlaylists_itemsArray.Number | Select-Object -last 1
                          $Number++
                        }
                        $null = $YoutubePlaylists_itemsArray.add([PSCustomObject]::new(@{
                              Number=$Number;       
                              ID = $channelid
                              Name=$channelName
                              Path=$playlisturl
                              Type='YoutubeSubscription'
                              Playlist_Info = $channel.items
                        }))
                        if($thisApp.Config.Youtube_Playlists -notcontains $playlisturl){
                          $newchannels++
                        }                        
                      }else{
                        write-ezlogs "The Youtube Subscription Channel URL $playlisturl has already been added!" -showtime -warning -logtype Youtube
                      }
                    }                          
                  }
                }catch{
                  write-ezlogs "An exception occurred getting personal Youtube subscriptions" -showtime -catcherror $_
                }
              }
            }catch{
              write-ezlogs "An exception occurred retrieving owner youtube channel id" -showtime -catcherror $_
            } 
            #Custom/Imported Playlists
            try{
              if($synchash.all_playlists){
                foreach($customplaylist in $synchash.all_playlists){
                  #$custom_playlists = $playlist_Profile.PlayList_tracks.values | where {$_.Playlist_URL -match 'youtu\.be' -or $_ -match 'youtube\.com'}
                  foreach($list in $customplaylist){      
                    $customplaylist_Name = $Null
                    if($list.Playlist_URL){
                      $customplaylist_Name = $YoutubePlaylists_itemsArray | Where-Object {$_.path -eq $list.Playlist_URL}
                      if($list.Playlist -and $customplaylist_Name.name -and $customplaylist_Name.name -ne $list.Playlist){
                        write-ezlogs "| Updating youtube playlist table name from: $($customplaylist_Name.name) - to: $($list.Playlist) - playlist_id: $($list.playlist_id)" -showtime -logtype youtube -loglevel 2
                        $PlaylistUpdate = $true
                        $customplaylist_Name.Name = $list.Playlist
                      }
                    }
                  }
                }
                if($PlaylistUpdate){
                  write-ezlogs ">>>> Saving all_playlists library to: $($thisApp.Config.Playlists_Profile_Path)" -logtype Youtube
                  Export-SerializedXML -InputObject $synchash.All_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist
                }
              }
            }catch{
              write-ezlogs "An exception occurred parsing or updating custom playlists in $($thisApp.config.Playlist_Profile_Directory)" -showtime -catcherror $_
            }
            #Check for playlists that no longer exist   
            $playlists_toRemove = $thisApp.Config.Youtube_Playlists | Where-Object {$YoutubePlaylists_itemsArray.path -notcontains $_}                          
            if($newplaylists -le 0 -and $newchannels -le 0 -and $playlists_toRemove.count -le 0 -and $newvideos -le 0 -and $removedvideos -le 0){
              write-ezlogs "No changes to Youtube playlists were found" -showtime -warning -logtype Youtube
              return
            }else{
              write-ezlogs "Found $newplaylists playlists, $newchannels new channels, $($newvideos) new playlists videos, $removedvideos removed playlist videos -- found $($playlists_toRemove.count) playlists to remove" -showtime -logtype Youtube 
              if($hashsetup.Update_YoutubePlaylists_Timer){
                $hashsetup.Update_YoutubePlaylists_Timer.tag = $YoutubePlaylists_itemsArray
                write-ezlogs ">>>> Starting Update_YoutubePlaylists_Timer" -showtime -logtype Youtube
                $hashsetup.Update_YoutubePlaylists_Timer.start() 
              }                            
            }           
            $newYoutubeMediaCount = 0
            if([IO.File]::Exists("$($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml")){
              try{
                $Playlist_Profile = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText("$($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml"))
              }catch{
                write-ezlogs "An exception occurred importing playlist template $($thisapp.config.Current_Folder)\Resources\Templates\Playlists_Template.xml" -showtime -catcherror $_
              }             
            } 
            foreach($playlist in $YoutubePlaylists_itemsArray){
              if(Test-URL $playlist.path){
                if($thisApp.Config.Youtube_Playlists -notcontains $playlist.path){
                  try{
                    write-ezlogs " | Adding new Youtube Playlist URL: $($playlist.path) - Name: $($playlist.Name)" -showtime -logtype Youtube -LogLevel 2
                    $null = $thisApp.Config.Youtube_Playlists.add($playlist.path)
                    if($Playlist_Profile -and $playlist.path -notmatch 'Twitch.tv'){  
                      if($playlist.Name){
                        $playlist_Name = $playlist.name
                      }else{
                        $playlist_Name = "Custom_$($playlist.id)"
                      }    
                      #$playlistName_Cleaned = ([Regex]::Replace($playlist_Name, $pattern3, '')).trim()            
                      $Playlist_Profile_path = "$($thisapp.config.Playlist_Profile_Directory)\Youtube_Playlists\$($playlist.id).xml"
                      write-ezlogs " | Saving new Youtube Playlist profile to $Playlist_Profile_path" -showtime -logtype Youtube -LogLevel 2
                      $Playlist_Profile.name = $playlist_Name
                      #$Playlist_Profile.NameCleaned = $playlistName_Cleaned
                      $Playlist_Profile.Playlist_ID = $playlist.id
                      $Playlist_Profile.Playlist_URL = $playlist.path
                      $Playlist_Profile.type = $playlist.type
                      $Playlist_Profile.Playlist_Path = $Playlist_Profile_path
                      $Playlist_Profile.Playlist_Date_Added = [DateTime]::Now.ToString()
                      if($playlist.playlist_info.id){
                        $Playlist_Profile.Source = 'YoutubeAPI'
                        Add-Member -InputObject $Playlist_Profile -Name 'Playlist_Info' -Value $playlist.playlist_info -MemberType NoteProperty -Force
                      }else{
                        $Playlist_Profile.Source = 'Custom'
                      }  
                      Export-Clixml -InputObject $Playlist_Profile -path $Playlist_Profile_path -Force -Encoding Default               
                    }
                    $newYoutubeMediaCount++  
                  }catch{
                    write-ezlogs "An exception occurred adding path $($playlist.path) to Youtube_Playlists" -showtime -catcherror $_
                  }
                }            
              }else{        
                write-ezlogs "The provided Youtube playlist URL $($playlist.path) is invalid!" -showtime -warning -logtype Youtube
              } 
            }
            #Remove playlists that no longer exist
            $AllYoutube_Media_Profile_File_Path = [IO.Path]::Combine($thisApp.config.Media_Profile_Directory,"All-Youtube_MediaProfile","All-Youtube_Media-Profile.xml")  
            if($playlists_toRemove){
              if([IO.File]::Exists($AllYoutube_Media_Profile_File_Path)){
                write-ezlogs " | Importing All Youtube Media profile cache at $AllYoutube_Media_Profile_File_Path" -showtime -logtype Youtube
                $all_youtubemedia_profile = Import-SerializedXML -Path $AllYoutube_Media_Profile_File_Path
              }              
              foreach($playlist_path in $playlists_toRemove){
                write-ezlogs " | Removing Youtube Playlist $($playlist_path)" -showtime -logtype Youtube -LogLevel 2
                $null = $thisApp.Config.Youtube_Playlists.Remove($playlist_path)
              }
              try{
                Export-SerializedXML -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -isConfig
              }catch{
                write-ezlogs "[Get-YoutubeStatus] An exception occurred saving config file to path $($thisApp.Config.Config_Path)" -showtime -catcherror $_
              }            
              [Collections.ArrayList]$all_youtubemedia_profile = $all_youtubemedia_profile | Where-Object {$YoutubePlaylists_itemsArray.id -contains $_.playlist_id}
              write-ezlogs "Updating All Youtube Media profile cache at $AllYoutube_Media_Profile_File_Path" -showtime -logtype Youtube
              Export-SerializedXML -InputObject $all_youtubemedia_profile -path $AllYoutube_Media_Profile_File_Path      
            }
            if($newYoutubeMediaCount -gt 0 -or $playlists_toRemove -or $newvideos -gt 0 -or $removedvideos -gt 0){
              write-ezlogs ">>>> Executing Import-Youtube to refresh Youtube library" -showtime -logtype Youtube
              if($synchash.All_Youtube_Media){
                if([io.file]::Exists("$($thisApp.Config.Media_Profile_Directory)\All-Youtube_MediaProfile\All-Youtube_Media-Profile.xml") -and $newvideos -gt 0 -or $removedvideos -gt 0){
                  write-ezlogs ">>>> Removing existing Youtube Media Profile at: $($thisApp.Config.Media_Profile_Directory)\All-Youtube_MediaProfile\All-Youtube_Media-Profile.xml" -loglevel 2 -logtype Youtube 
                  try{
                    $null = Remove-item "$($thisApp.Config.Media_Profile_Directory)\All-Youtube_MediaProfile\All-Youtube_Media-Profile.xml" -Force
                  }catch{
                    write-ezlogs "An exception occurred removing existing Youtube Media Profile at: $($thisApp.Config.Media_Profile_Directory)\All-Youtube_MediaProfile\All-Youtube_Media-Profile.xml" -catcherror $_
                  }
                }
                $synchash.All_Youtube_Media = [Collections.Generic.List[Media]]::new()
              }
              #Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'YoutubeTable' -Property 'itemssource' -value $Null -ClearValue
              Import-Youtube -Youtube_playlists $thisapp.Config.Youtube_Playlists -verboselog:$thisapp.Config.Verbose_Logging -synchash $synchash -Media_Profile_Directory $thisapp.config.Media_Profile_Directory -thisApp $thisapp -use_runspace -refresh
            }elseif($thisApp.Config.Youtube_Playlists.count -eq 0){
              write-ezlogs ">>>> Youtube Playlists count is 0 - clearing Youtube library table itemssource" -showtime -logtype Youtube
              Update-MainWindow -synchash $synchash -thisApp $thisApp -Control 'YoutubeTable' -Property 'itemssource' -value $Null -ClearValue
            }  
          }else{
            write-ezlogs "Cannot check for updates of Youtube playlists, unable to connect to 'www.youtube.com'" -warning -AlertUI
          }                                                        
        }catch{
          write-ezlogs "An exception occurred in checkYoutube_scriptblock" -showtime -catcherror $_
        }finally{
          if($checkyoutube_stopwatch){
            $checkyoutube_stopwatch.stop()
            write-ezlogs ">>>> Get-YoutubeStatus Measure" -PerfTimer $checkyoutube_stopwatch -Perf -logtype Youtube
            $checkyoutube_stopwatch = $Null
          }
          if($internet_Connectivity){
            $internet_Connectivity = $Null
          }
        }                                                         
      } 
      if($Use_runspace){
        $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
        Start-Runspace $checkYoutube_scriptblock -Variable_list $Variable_list -StartRunspaceJobHandler -synchash $synchash -logfile $thisApp.Config.Log_file -runspace_name "checkYoutube_runspace" -thisApp $thisApp
        $Variable_list = $Null
      }else{
        Invoke-Command -ScriptBlock $checkYoutube_scriptblock
      }
      $checkYoutube_scriptblock = $Null                       
    }else{
      write-ezlogs "Unable to refresh Youtube playlists, Youtube importing is not enabled!" -showtime -warning -logtype Youtube -LogLevel 2
    }
  }catch{
    write-ezlogs "An exception occurred getting Youtube playlists and channels!" -showtime -catcherror $_
  }  
}
#---------------------------------------------- 
#endregion Get-YoutubeStatus Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-YoutubeURL Function
#----------------------------------------------
function Get-YoutubeURL
{
  [CmdletBinding(DefaultParameterSetName = 'URL')]
  Param (
    $URL,
    $thisApp,
    [switch]$APILookup,
    [switch]$Verboselog
  )   
  begin {
    try{
      if($URL -match 'yewtu\.be|youtu\.be|youtube\.com'){
        $Process = $true
      }
    }catch{
      write-ezlogs "An exception occurred in Get-YoutubeURL" -showtime -catcherror $_
    }
  }
  process {
    try{
      if(!$Process){return}
      write-ezlogs ">>>> Parsing Youtube ID from link: $URL" -showtime -color cyan
      if($URL -match '%3D%3D'){
        $URL = $URL -replace '%3D%3D'
      }
      if($URL -match '\&t='){
        $TimeIndex = [regex]::matches($URL, "\&t=(?<value>.*)") | & { process { $_.groups[1].value}}
        $URL = ($($URL) -split('&t='))[0].trim()
      }
      if($URL -match '\/tv\.youtube\.com\/'){
        if($URL -match '\?vp='){
          $youtube_id = [regex]::matches($URL, "tv.youtube.com\/watch\/(?<value>.*)\?vp\=") | & { process { $_.groups[1].value}}
        }elseif($URL -match '\?v='){
          $youtube_id = [regex]::matches($URL, "tv.youtube.com\/watch\?v=(?<value>.*)") | & { process { $_.groups[1].value}}
        }else{
          $youtube_id = [regex]::matches($URL, "tv.youtube.com\/watch\/(?<value>.*)") | & { process { $_.groups[1].value}}
        }
        $youtube_type = 'YoutubeTV'
      }elseif($URL -match 'list='){
        if($URL -match "\&index="){
          $PlaylistIndex = [regex]::matches($URL, "\&index=(?<value>.*)") | & { process { $_.groups[1].value}}
        }
        $playlist_id = ($($URL) -split('list='))[1]
        #PP seems to be 'playerParams' and something to do with telling the browser whether the video has been watched
        if($URL -match "\&pp="){
          $pp = [regex]::matches($URL, "\&pp=(?<value>.*)") | & { process { $_.groups[1].value}}
          $playlist_id = ($($playlist_id) -split('\&pp='))[0]
          if($PlaylistIndex){
            $PlaylistIndex = ($($PlaylistIndex) -split('\&pp='))[0]
          }
          $URL = ($($URL) -split('\&pp='))[0]
        }
        $URL = ($($URL) -split('\&index='))[0]
        $playlist_id = ($($playlist_id) -split('\&index='))[0]
        $youtube_type = 'YoutubePlaylist'
      }
      if($URL -match "v="){
        $youtube_id = ($($URL) -split('v='))[1]
        $youtube_type = 'YoutubeVideo' 
      }elseif($URL -match "\/watch\/"){
        $youtube_id = [regex]::matches($URL, "\/watch\/(?<value>.*)") | & { process { $_.groups[1].value}}
        $youtube_type = 'YoutubeVideo' 
      }elseif($URL -match "\/v\/(?<value>.*)\?|\/v\/(?<value>.*)"){
        $youtube_id = [regex]::matches($URL, "\/v\/(?<value>.*)\?|\/v\/(?<value>.*)") | & { process { $_.groups[1].value}}
        $youtube_type = 'YoutubeVideo' 
      }elseif($URL -notmatch "v=" -and $URL -notmatch '\?' -and $URL -notmatch '\&'){
        $youtube_id = (([uri]$URL).segments | Select-Object -last 1) -replace '/',''
        $youtube_type = 'YoutubeVideo' 
      }elseif($URL -match "youtu\.be\/(?<value>.*)"){
        $youtube_id = [regex]::matches($URL, "youtu\.be\/(?<value>.*)") | & { process { $_.groups[1].value}}
      }elseif($URL -match "\/embed\/"){
        $youtube_id = ($($URL) -split('\/embed\/'))[1].trim()
      }elseif($URL -match '\/channel\/'){
        if($URL -match '\/videos'){
          $playlist = $playlist -replace '\/videos'
        }
        if($playlist){
          $youtube_id = ($($playlist) -split('\/channel\/'))[1].trim()
        }
        $youtube_type = 'YoutubeChannel' 
      }
      if($youtube_id -match '\?si='){
        $youtube_id = ($youtube_id -split '\?si=')[0]
      }  
      if($youtube_id -match '\&pp='){
        $youtube_id = ($youtube_id -split '\&pp=')[0]
      }
      if($PlaylistIndex -match '\&pp='){
        $PlaylistIndex = ($PlaylistIndex -split '\&pp=')[0]
      }
      if(!$youtube_id -and $playlist_id -and $APILookup){
        $Playlist_items = Get-YouTubePlaylistItems -Id $playlist_id
        if($PlaylistIndex){
          $Index = $PlaylistIndex -1
        }else{
          $Index = 0
        }
        if($Playlist_items){
          $Playlistitem = $Playlist_items[$Index]
        }
        if($Playlistitem.contentDetails.videoId){
          $youtube_id = $Playlistitem.contentDetails.videoId
        }
      }elseif($youtube_id -match '\&list='){
        $youtube_id = ($youtube_id -split '\&list=')[0]
      }
      if($url -match '\?&autoplay=1'){
        $url = $url -replace '\?&autoplay=1'
        $autoplay = $true
      }
      if($url -match '\?&enablejsapi=1'){
        $url = $url -replace '\?&enablejsapi=1'
        $enablejsapi = $true
      }
      if($url -match '\?listType='){
        $listType = (([regex]::matches($url, "\?listType=(?<value>.*)") | & { process { $_.groups[1].value}}) -split '\&')[0]
      }
      if($URL -match "\&pp="){
        $pp = [regex]::matches($URL, "\&pp=(?<value>.*)") | & { process { $_.groups[1].value}}
        $URL = ($($URL) -split('\&pp='))[0]
      }
      if($youtube_id){
        if($url -notmatch 'tv\.youtube\.com'){
          #$InvidiousUrl = "https://yewtu.be/embed/$youtube_id"
          #$InvidiousUrl = "https://invidious.nerdvpn.de/embed/$youtube_id"          
          $InvidiousUrl = "https://invidious.jing.rocks/embed/$youtube_id" 
          $embedurl = "https://www.youtube.com/embed/$youtube_id`?autoplay=1&enablejsapi=1"
          if($playlist_id){
            $PlaylistUrl = "https://www.youtube.com/watch?v=$($youtube_id)&list=$($playlist_id)`&autoplay=1&enablejsapi=1"
          }
        }elseif($url -match 'tv\.youtube\.com'){
          $YTVUrl = "https://tv.youtube.com/watch/$youtube_id"
        }
      }elseif($playlist_id){
        $PlaylistUrl = "https://www.youtube.com/watch/videoseries?list=$($playlist_id)`&autoplay=1&enablejsapi=1"
        $PlaylistEmbedUrl = "https://www.youtube.com/embed/videoseries?list=$($playlist_id)`&autoplay=1&enablejsapi=1"
      }
    }catch{
      write-ezlogs "An exception occurred in Get-YoutubeURL" -showtime -catcherror $_
    }
  }
  end {
    if(!$Process){return}
    $Output = [PSCustomObject]@{
      'id' = $youtube_id
      'url' = $url
      'YTVUrl' = $YTVUrl
      'Type' = $youtube_type
      'InvidiousUrl' = $InvidiousUrl
      'PlaylistUrl' = $PlaylistUrl
      'PlaylistEmbedUrl' = $PlaylistEmbedUrl
      'embedUrl' = $embedurl
      'listType' = $listType
      'enablejsapi' = $enablejsapi
      'autoplay' = $autoplay
      'PlayerParams' = $pp
      'PlaylistIndex' = $PlaylistIndex
      'TimeIndex' = $TimeIndex
      'playlist_id' = $playlist_id
    }
    return $Output
  }
}
#---------------------------------------------- 
#endregion Get-YoutubeURL Function
#----------------------------------------------

#---------------------------------------------- 
#region Update-YoutubeMedia Function
#----------------------------------------------
function Update-YoutubeMedia
{
  param (
    $InputObject,
    [switch]$Clear,
    [switch]$Startup,
    $synchash,
    [string]$TotalCount,
    [switch]$Refresh_All_Media,
    [switch]$update_Library,
    [switch]$UpdatePlaylists,
    $thisApp,
    $all_Playlists,
    $UpdateMedia,
    [switch]$SkipGetMedia
  )
  $update_YoutubeMedia_scriptblock = {
    $update_YoutubeMedia_Measure = [system.diagnostics.stopwatch]::StartNew()
    $synchash = $synchash
    $thisApp = $thisApp
    $update_Library = $update_Library
    $UpdateMedia = $UpdateMedia
    $UpdatePlaylists = $UpdatePlaylists
    try{
      Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Write-EZLogs\Write-EZLogs.psm1" -NoClobber -DisableNameChecking -Scope Local
      Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Set-WPFControls\Set-WPFControls.psm1" -NoClobber -DisableNameChecking -Scope Local
      Import-module -Name "$($thisApp.Config.Current_Folder)\Modules\Get-HelperFunctions\Get-HelperFunctions.psm1" -NoClobber -DisableNameChecking -Scope Local
      Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\PSSerializedXML\PSSerializedXML.psm1" -NoClobber -DisableNameChecking -Scope Local
      if($synchash.All_Youtube_Media.count -gt 0){
        $AllYoutube_Profile_Directory_Path = [System.IO.Path]::Combine($thisApp.Config.Media_Profile_Directory,"All-Youtube_Profile")
        $AllYoutube_Profile_File_Path = [System.IO.Path]::Combine($AllYoutube_Profile_Directory_Path,"All-Youtube_Media-Profile.xml")
        if($UpdateMedia.id){
          write-ezlogs ">>>> Updating Youtube media with id: $($UpdateMedia.id)"  
          $media_to_Update = foreach($Media in $UpdateMedia){
            Get-IndexesOf $synchash.All_v_Media.id -Value $Media.id | & { process {
                $synchash.All_Youtube_Media[$_]
            }}   
          }
        }else{
          write-ezlogs ">>>> Updating all Youtube media" -logtype Youtube
          $media_to_Update = $synchash.All_Youtube_Media
        }
        $TotalCount = @($media_to_Update).count
        write-ezlogs "####################### Executing Update-YoutubeMedia for $($TotalCount) media" -linesbefore 1 -logtype Youtube
        if(!([System.IO.Directory]::Exists($AllYoutube_Profile_Directory_Path))){
          [void][System.IO.Directory]::CreateDirectory($AllYoutube_Profile_Directory_Path)
        } 
        if($media_to_Update){
          if($UpdatePlaylists -and $synchash.all_playlists){
            if($synchash.all_playlists -isnot [System.Collections.Generic.List[Playlist]]){
              $all_Playlists = $synchash.all_playlists | ConvertTo-Playlists -List
            }else{
              $all_Playlists = [System.Collections.Generic.List[Playlist]]::new($synchash.all_playlists)
            }
            $media_to_Update | & { process {
                if($_.url){
                  try{
                    $Media = $_
                    $all_Playlists | & { process {
                        $playlist = $_
                        $Changes = $false
                        $track_index = $Null
                        $track = $null
                        try{
                          $urls = [System.Collections.Generic.list[object]]$playlist.PlayList_tracks.values.url
                          if($urls){
                            $track_index = $urls.indexof($Media.url)
                          }
                          if($track_index -ne -1 -and $track_index -ne $null){
                            #$track = $playlist.PlayList_tracks[$track_index]
                            $track = $playlist.PlayList_tracks.Values | Where-Object {$_.url -eq $Media.url}
                            if($track){
                              foreach ($property in $Media.psobject.properties.name){
                                if([bool]$track.PSObject.Properties[$property] -and $track.$property -ne $Media.$property){
                                  if($thisApp.Config.Dev_mode){write-ezlogs " | Updating track property: '$($property)' from value: '$($track.$property)' - to: '$($Media.$property)'"  -Dev_mode -logtype Youtube}
                                  $track.$property = $Media.$property
                                  $Changes = $true
                                }elseif(-not [bool]$track.PSObject.Properties[$property]){
                                  write-ezlogs " | Adding track property: '$($property)' with value: $($Media.$property)" -logtype Youtube
                                  $Changes = $true
                                  $track.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new($property,$Media.$property))
                                }
                              }
                              if($Changes){
                                $UpdatePlaylists = $true
                              }
                            }
                          }
                        }catch{
                          write-ezlogs "[Update-YoutubeMedia] An exception occurred processing playlist: $($playlist | out-string)" -CatchError $_
                        }finally{
                          $track = $Null
                        }
                    }}
                  }catch{
                    write-ezlogs "[Update-YoutubeMedia] An exception occurred attempting to lookup and update playlist tracks with url: $($Media.url)" -CatchError $_
                  } 
                }
            }} 
          }
          if($AllYoutube_Profile_File_Path){
            write-ezlogs ">>>> Exporting All Youtube Profile cache to file $($AllYoutube_Profile_File_Path)" -showtime -color cyan -logtype Youtube -LogLevel 3
            Export-SerializedXML -Path $AllYoutube_Profile_File_Path -InputObject $synchash.All_Youtube_Media
          }
          if($UpdatePlaylists -and $all_Playlists){
            Export-SerializedXML -InputObject $all_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist -Force
            Import-Module -Name "$($thisApp.Config.Current_Folder)\Modules\Get-Playlists\Get-Playlists.psm1" -NoClobber -DisableNameChecking -Scope Local
            Get-Playlists -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace -Import_Playlists_Cache -Quick_Refresh
            [void]$all_Playlists.clear()
            $all_Playlists = $Null
          }
          if($update_YoutubeMedia_Measure){
            $update_YoutubeMedia_Measure.stop()
            write-ezlogs "####################### Update-YoutubeMedia Processing Finished #######################" -PerfTimer $update_YoutubeMedia_Measure -Perf -GetMemoryUsage -forceCollection -PriorityLevel 3
            $update_YoutubeMedia_Measure = $null
          }
        }else{
          write-ezlogs "No Youtube Media was found to process!" -logtype Youtube -LogLevel 2 -warning
        }
      }else{
        write-ezlogs "No Youtube Media was found to process!" -logtype Youtube -LogLevel 2 -warning
      }
    }catch{
      write-ezlogs "An exception occurred in update-Youtubemedia scriptblock" -catcherror $_
    }finally{
      if($synchash.Refresh_YoutubeMedia_timer -and $update_Library){
        write-ezlogs ">>>> Executing Refresh_YoutubeMedia_timer for Update-YoutubeMedia"
        $synchash.Refresh_YoutubeMedia_timer.tag = 'QuickRefresh_YoutubeMedia_Button'
        $synchash.Refresh_YoutubeMedia_timer.start()
      }
      Remove-Module -Name "Write-EZLogs" -Force -ErrorAction SilentlyContinue
      Remove-Module -Name "Set-WPFControls" -Force -ErrorAction SilentlyContinue
      Remove-module -Name "Get-HelperFunctions" -Force -ErrorAction SilentlyContinue
      Remove-Module -Name "PSSerializedXML" -Force -ErrorAction SilentlyContinue
    }
  }
  try{
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
    Start-Runspace -scriptblock $update_YoutubeMedia_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'Update_YoutubeMedia_Runspace' -thisApp $thisApp -synchash $synchash -CheckforExisting -RestrictedRunspace -PSProviders 'Function','Registry','Environment','FileSystem','Variable'
  }catch{
    write-ezlogs "An exception occurred in Update-YoutubeMedia" -CatchError $_
  }
}
#---------------------------------------------- 
#endregion Update-YoutubeMedia Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-Youtube','Start-YoutubeMonitor','Get-YoutubeStatus','Add-YoutubePlaylist','Remove-YoutubePlaylist','Get-YoutubeURL','Update-YoutubeMedia')