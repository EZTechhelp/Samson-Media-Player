<#
    .Name
    Get-PlayQueue

    .Version 
    0.1.0

    .SYNOPSIS
    Allows managing the Play Queue for EZT-MediaPlayer

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
#region Get-PlayQueue Function
#----------------------------------------------
function Get-PlayQueue
{
  [CmdletBinding()]
  param (
    [switch]$Clear,
    [switch]$Startup,
    $synchash,
    $thisApp,
    $Group,
    $thisScript,
    [switch]$VerboseLog,
    [switch]$Import_Playlists_Cache
  )
  
  if($Verboselog){write-ezlogs "#### Executing Get-PlayQueue ####" -enablelogs -color yellow -linesbefore 1}
  try{
    $syncHash.PlayQueue_TreeView.items.Clear()
    $syncHash.PlayQueue_TreeView.Background = "Transparent"
    $syncHash.PlayQueue_TreeView.AlternatingRowBackground = "Transparent"
    $syncHash.PlayQueue_TreeView.CanUserReorderColumns = $false
    $syncHash.PlayQueue_TreeView.CanUserDeleteRows = $true
    $syncHash.PlayQueue_TreeView.Foreground = "White"
    $syncHash.PlayQueue_TreeView.RowBackground = "Transparent"
    $syncHash.PlayQueue_TreeView.HorizontalAlignment ="Left"
    $syncHash.PlayQueue_TreeView.CanUserAddRows = $False
    $syncHash.PlayQueue_TreeView.HorizontalContentAlignment = "left"
    $syncHash.PlayQueue_TreeView.IsReadOnly = $True
  }catch{
    write-ezlogs "An exception occurred updating playqueue_treeview" -showtime -catcherror $_
  }

  if($Import_Playlists_Cache){   
    try{
      if(([System.IO.File]::Exists("$($thisApp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml"))){
        $synchash.all_playlists = Import-Clixml "$($thisApp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml"
      }else{
        write-ezlogs "Unable to find All playlists cache, generating new one" -showtime -warning
      } 
    }catch{
      write-ezlogs "An exception occurred importing playlists cache" -showtime -catcherror $_
    }
  }
  
  if($thisApp.config.Current_Playlist.values){
    try{
      if($VerboseLog){
        write-ezlogs ">>>> Updating current play queue" -showtime -color cyan
        write-ezlogs " | Importing config file $($thisApp.Config.Config_Path)" -showtime
      }     
      $thisApp.config = Import-Clixml -Path $thisApp.Config.Config_Path
      if(($thisApp.config.Current_Playlist.GetType()).name -notmatch 'OrderedDictionary'){$thisApp.config.Current_Playlist = ConvertTo-OrderedDictionary -hash ($thisApp.config.Current_Playlist)}
      foreach($key in $thisApp.config.Current_Playlist.GetEnumerator() | where {-not [string]::IsNullOrEmpty($_.value)}){
        #$Track = $synchash.MediaTable.Items | where {$_.id -eq $item} 
        $Title = $Null
        $track = $null
        $artist = $null
        $track_name = $null
        $number = $Null
        $number = $key.key
        $item = $key.value
        if($VerboseLog){write-ezlogs "[Get-Playlists] | Looking for track with ID $($item)" -showtime}
        $Track = $synchash.all_playlists.Playlist_tracks | where {$_.id -and $_.id -eq $item} | select -Unique     
        if(!$Track){
          $Track = $synchash.All_local_Media | where {$_.id -and $_.id -eq $item} | select -Unique 
          
        }            
        if(!$Track){
          $Track = $synchash.All_Spotify_Media.playlist_tracks | where {$_.id -and $_.id -eq $item} | select -Unique
           
        }
        if(!$Track){
          $Track = $synchash.All_Youtube_Media.playlist_tracks | where {$_.id -and $_.id -eq $item} | select -Unique 
          if(!$Track){
            $AllYoutube_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Youtube_MediaProfile','All-Youtube_Media-Profile.xml') 
            if([System.IO.File]::Exists($AllYoutube_Profile_File_Path)){
              $all_youtube_profile = Import-Clixml $AllYoutube_Profile_File_Path
              $Track = $all_youtube_profile.playlist_tracks | where {$_.id -and $_.id -eq $item} | select -Unique
            }
          }
        } 
        if(!$track -and $synchash.Temporary_Playback_Media.id -eq $item){
          $track = $synchash.Temporary_Playback_Media
        }
        $playlist = $synchash.all_playlists | where {$_.Playlist_tracks.id -eq $item} | select -Unique   
        #write-ezlogs ">>>> TRACK: $($track | out-string)"
        if($Track.Spotify_path -or $Track.uri -match 'spotify:' -or $track.Source -eq 'SpotifyPlaylist'){
          if($Track.Artist){
            $artist = $Track.Artist
          }else{
            $artist = $($Track.Artist_Name)
          }
          if($track.title){
            $track_name = $track.title
          }else{
            $track_name = $Track.Track_Name
          }
          $Title = "$($artist) - $($track_name)"
          if($thisApp.Config.Verbose_logging){write-ezlogs "| Found Spotify Track Title: $($Title) " -showtime }
          $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Spotify.png"
        }elseif($Track.webpage_url -match 'twitch'){
          $Title = "$($Track.Title)"
          if($thisApp.Config.Verbose_logging){write-ezlogs "| Found Twitch Track Title: $($Title) " -showtime }
          #$title = "Twitch Stream: $($track.Playlist)"
          if($Track.profile_image_url){
            if($thisApp.Config.Verbose_logging){write-ezlogs "Media Image found: $($Track.profile_image_url)" -showtime}       
            if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
              if($thisApp.Config.Verbose_logging){write-ezlogs " Creating image cache directory: $($thisApp.config.image_Cache_path)" -showtime}
              $null = New-item ($thisApp.config.image_Cache_path) -ItemType directory -Force
            }           
            $encodeduri = $Null  
            $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$([System.Uri]::new($Track.profile_image_url).Segments | select -last 1)-Local")
            $encodeduri = [System.Convert]::ToBase64String($encodedBytes)                     
            $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),"$($encodeduri).png")
            if([System.IO.File]::Exists($image_Cache_path)){
              $cached_image = $image_Cache_path
            }elseif($Track.profile_image_url){         
              if($thisApp.Config.Verbose_logging){write-ezlogs "| Destination path for cached image: $image_Cache_path" -showtime}
              if(!([System.IO.File]::Exists($image_Cache_path))){
                try{
                  if([System.IO.File]::Exists($Track.profile_image_url)){
                    if($thisApp.Config.Verbose_logging){write-ezlogs "| Cached Image not found, copying image $($Track.profile_image_url) to cache path $image_Cache_path" -enablelogs -showtime}
                    $null = Copy-item -LiteralPath $Track.profile_image_url -Destination $image_Cache_path -Force
                  }else{
                    $uri = new-object system.uri($Track.profile_image_url)
                    if($thisApp.Config.Verbose_logging){write-ezlogs "| Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -enablelogs -showtime}
                    (New-Object System.Net.WebClient).DownloadFile($uri,$image_Cache_path) 
                  }             
                  if([System.IO.File]::Exists($image_Cache_path)){
                    $stream_image = [System.IO.File]::OpenRead($image_Cache_path) 
                    $image = new-object System.Windows.Media.Imaging.BitmapImage
                    $image.BeginInit();
                    $image.CacheOption = "OnLoad"
                    #$image.CreateOptions = "DelayCreation"
                    #$image.DecodePixelHeight = 229;
                    $image.DecodePixelWidth = 20
                    $image.StreamSource = $stream_image
                    $image.EndInit();        
                    $stream_image.Close()
                    $stream_image.Dispose()
                    $stream_image = $null
                    $image.Freeze();
                    if($thisApp.Config.Verbose_logging){write-ezlogs "Saving decoded media image to path $image_Cache_path" -showtime -enablelogs}
                    $bmp = [System.Windows.Media.Imaging.BitmapImage]$image
                    $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
                    $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($bmp))
                    $save_stream = [System.IO.FileStream]::new("$image_Cache_path",'Create')
                    $encoder.Save($save_stream)
                    $save_stream.Dispose()       
                  }  
                  $cached_image = $image_Cache_path            
                }catch{
                  $cached_image = $Null
                  write-ezlogs "An exception occurred attempting to download $image to path $image_Cache_path" -showtime -catcherror $_
                }
              }           
            }else{
              write-ezlogs "Cannot Download image $image to cache path $image_Cache_path - URL is invalid" -enablelogs -showtime -warning
              $cached_image = $Null        
            }              
          }
          if($cached_image){
            $icon_path = $cached_image
          }else{
            $icon_path = $cached_image
            $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Twitch.png"
          }         
        }elseif($Track.type -eq 'YoutubePlaylist_item' -or $track.Group -eq 'Youtube'){
          $Title = "$($Track.Title)"
          if($thisApp.Config.Verbose_logging){write-ezlogs "| Found Youtube Track Title: $($Title) " -showtime }
          $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Youtube.png"
        }elseif(($Track.SongInfo.Artist -and $Track.SongInfo.Title)){
          $Title = "$($Track.SongInfo.Artist) - $($Track.SongInfo.Title)"
          if($thisApp.Config.Verbose_logging){write-ezlogs "| Found Track SingInfo Artist and SongInfo Title: $($Title) " -showtime }
          $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Vlc.png"
        }elseif($Track.Artist -and $Track.Title){        
          $Title = "$($Track.Artist) - $($Track.Title)"
          if($thisApp.Config.Verbose_logging){write-ezlogs "| Found Track Artist and Title: $($Title) " -showtime }
          $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Vlc.png"
        }elseif($Track.Title){
          if($thisApp.Config.Verbose_logging){write-ezlogs "| Found Track Title: $($Track.Title) " -showtime }
          $Title = "$($Track.Title)"
          $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Vlc.png"
        }elseif($Track.Name){
          if($thisApp.Config.Verbose_logging){write-ezlogs "| Found Track Name: $($Track.Name) " -showtime }
          if(!$Track.Artist -and !$Track.SongInfo.Artist -and [System.IO.Directory]::Exists($Track.directory)){     
            try{
              $artist = (Get-Culture).TextInfo.ToTitleCase(([System.IO.Path]::GetFileNameWithoutExtension($Track.directory))).trim()            
            }catch{
              write-ezlogs "An exception occurred getting file name without extension for $($Track.directory)" -showtime -catcherror $_
              $artist = ''
            }                
            if($thisApp.Config.Verbose_logging){write-ezlogs "  | Using Directory name for artist: $($artist) " -showtime }
          }elseif($Track.Artist){
            $artist = $Track.Artist
            if($thisApp.Config.Verbose_logging){write-ezlogs "  | Found Track Name artist: $($artist) " -showtime }
          }elseif($Track.SongInfo.Artist){
            $artist = $Track.SongInfo.Artist
            if($thisApp.Config.Verbose_logging){write-ezlogs "  | Found Track SongInfo artist: $($artist) " -showtime }
          }
          if(-not [string]::IsNullOrEmpty($artist)){
            $Title = "$($artist) - $($Track.Name)"
          }else{
            $Title = "$($Track.Name)"
          }                   
          $icon_path = "$($thisApp.Config.Current_Folder)\\Resources\\Material-Vlc.png"
        }else{
          $title = $null
          write-ezlogs "Can't find type or title for track $($track | out-string) - Key: $($key | out-string)" -showtime -warning
        }     
        #write-ezlogs "[Get-Playlists] | Adding track $($track | out-string) to Play Queue" -showtime           
        if($Track.id -and -not [string]::IsNullOrEmpty($Title)){
          $Current_Playlist_ChildItem = New-Object System.Windows.Controls.TreeViewItem
          if($Track.live_status -eq 'Offline'){
            $fontstyle = 'Italic'
            $fontcolor = 'Gray'
            $FontWeight = 'Normal'
            $FontSize = 12          
          }elseif($Track.live_status -eq 'Online' -or $Track.live_status -eq 'Live'){
            $fontstyle = 'Normal'
            $fontcolor = 'LightGreen'
            $FontWeight = 'Normal'
            $FontSize = 12         
          }else{
            $fontstyle = 'Italic'
            $fontcolor = 'White' 
            $FontWeight = 'Normal'
            $FontSize = 12                     
          }
          if($track.status_msg){
            $status_msg = ($track.status_msg)
            if($track.live_status -eq 'Offline'){
              $Status_fontcolor = 'Gray'
              $Status_fontstyle = 'Italic'
            }else{
              $Status_fontcolor = 'White'
              $Status_fontstyle = 'Normal'
            }          
            $Status_FontWeight = 'Normal'
            $Status_FontSize = 12
          }else{
            $status_msg = $null
            $Status_fontstyle = 'Normal'
            $Status_fontcolor = 'White' 
            $Status_FontWeight = 'Normal'
            $Status_FontSize = 12          
          }                              
          $header = New-Object PsObject -Property @{
            'title' = $title
            'ID' = $track.id
            'Number' = $number
            'Status' = $Track.live_status
            'FontStyle' = $fontstyle
            'FontColor' = $fontcolor
            'FontWeight' = $FontWeight
            'BorderBrush' = 'Transparent'
            'PlayIconPauseVisibility' = 'Hidden'
            'PlayIconVisibility' = 'Hidden'
            'PlayIconRepeat' = '1x'
            'NumberVisibility' = 'Visible'
            'PlayCommand' = $synchash.PlayMedia_Command
            'PlayIconEnabled' = $false
            'BorderThickness' = '0'
            'NumberFontSize' = 12
            'PlayIconPause' = ''
            'PlayIcon' = ''
            'PlayImage' = "$($thisApp.Config.Current_Folder)\ByrnePlayer\Record.png"
            'FontSize' = $FontSize          
            'Status_Msg' = $status_msg
            'Status_FontStyle' = $Status_fontstyle
            'Status_FontColor' = $Status_fontcolor
            'Status_FontWeight' = $Status_FontWeight
            'Status_FontSize' = $Status_FontSize          
          }    
          $Current_Playlist_ChildItem.Header = $header        
          $Current_Playlist_ChildItem.Name = 'Play_Queue'
          $Current_Playlist_ChildItem.Uid = $icon_path
          if($thisApp.config.Last_Played -eq $Track.id){
            #$Current_Playlist_ChildItem.IsSelected = $true
          }
          #$Current_Playlist_ChildItem.Tag = $Track
          $Current_Playlist_ChildItem.Tag = @{        
            synchash=$synchash;
            thisScript=$thisScript;
            thisApp=$thisApp
            PlayMedia_Command = $synchash.PlayMedia_Command
            All_Playlists = $synchash.all_playlists
            Media_ContextMenu = $synchash.Media_ContextMenu
            Media = $Track
          } 
          $Current_Playlist_ChildItem.add_KeyDown{
            param
            (
              [Parameter(Mandatory)][Object]$sender,
              [Parameter(Mandatory)][Windows.Input.KeyEventArgs]$e
            )
            $synchash = $Sender.tag.synchash
            $thisApp = $Sender.tag.thisapp
            $thisScript = $Sender.tag.thisScript 
            #$all_playlists = $sender.tag.all_playlists
            $Playlist = $Sender.header          
            $Media = $sender.tag.Media 
            $Playlist = $e.Source.Parent.Header
            if($e.Key -eq 'Enter' -and $Media.url)
            {
              #write-ezlogs "Playlist $($e.Source.Parent.Header | out-string)" -showtime
              try{
                if($media.Spotify_Path){
                  $media = $syncHash.SpotifyTable.items | where {$_.id -eq $Media.id} | select -Unique
                  Start-SpotifyMedia -Media $Media -thisApp $thisApp -synchash $synchash -Script_Modules $Script_Modules -Show_notification
                }else{
                  Start-Media -Media $Media -thisApp $thisApp -synchash $synchash -Show_notification -Script_Modules $Script_Modules
                }  
              }catch{
                write-ezlogs "An exception occurred attempting to play media using keyboard event $($e.Key | out-string) for media $($Media.id) from Playlist $($Playlist)" -showtime -catcherror $_
              }    
            }
            if($e.Key -eq 'Delete'-and $Media.url)
            {
              try{
                if($media.Spotify_Path){
                  if($thisApp.config.Current_Playlist.values -contains $Media.encodedtitle){
                    write-ezlogs " | Removing Spotify media $($Media.encodedtitle) from Play Queue" -showtime
                    $index_toremove = $thisApp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.encodedtitle} | select * -ExpandProperty key
                    $null = $thisApp.config.Current_Playlist.Remove($index_toremove) 
                  }      
                }elseif($thisApp.config.Current_Playlist.values -contains $Media.id){
                  write-ezlogs " | Removing $($Media.id) from Play Queue" -showtime
                  $index_toremove = $thisApp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.id} | select * -ExpandProperty key
                  $null = $thisApp.config.Current_Playlist.Remove($index_toremove)                 
                }
                $thisApp.config | Export-Clixml -Path $thisApp.Config.Config_Path -Force -Encoding UTF8
                Get-Playlists -verboselog:$thisApp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisApp.Config.Media_Profile_Directory -startup -thisApp $thisApp  -all_playlists $synchash.all_playlists 
              }catch{
                write-ezlogs "An exception occurred removing media $($Media.id) from Playlist $($Playlist) using keyboard event $($e.Key | out-string)" -showtime -catcherror $_
              } 
            }    
          }               
          $null = $Current_Playlist_ChildItem.AddHandler([System.Windows.Controls.Button]::MouseDoubleClickEvent,$synchash.PlayMedia_Command)
          $null = $Current_Playlist_ChildItem.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
          if($synchash.PlayQueue_TreeView.items.header.id -notcontains $Current_Playlist_ChildItem.header.id){
            #write-ezlogs "[Get-Playlists] | Adding $($title) with ID $($track.id) - $($Current_Playlist_ChildItem.header.id) to Play Queue" -showtime   
            $null = $synchash.PlayQueue_TreeView.items.add($Current_Playlist_ChildItem)          
          }else{
            #$index_toremove = $thisapp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $track.id} | select * -ExpandProperty key
            write-ezlogs "Duplicate item ($title) already exists in the play queue (key: $($key.key)) - removing from queue" -showtime -warning
            #foreach($index in $index_toremove){$null = $thisapp.config.Current_Playlist.Remove($index)} 
            $null = $thisApp.config.Current_Playlist.Remove($key.key)
          }               
        }else{
          write-ezlogs "Unable to add track to play queue due to missing title or ID! Removing for queue list - Title: $($Title) - ID: $($track.id) - Key.name: $($key.name | out-string) - item: $($key | out-string)" -showtime -warning
          $null = $thisApp.config.Current_Playlist.Remove($key.key)
        }
      }   
      #$null = $syncHash.PlayQueue_TreeView.Items.Add($Current_Playlist) 
      $syncHash.PlayQueue_TreeView.AllowDrop = $true 
    }catch{
      write-ezlogs "An exception occurred processing current_playlist" -showtime -catcherror $_
    } 
  }   
  $syncHash.PlayQueue_TreeView.add_PreviewDrop($synchash.PreviewDrop_Command)
  #$syncHash.Playlists_TreeView.add_PreviewDrop($synchash.PreviewDrop_Command)
  #$syncHash.MediaTable.add_PreviewDrop($synchash.PreviewDrop_Command)
  #$syncHash.YoutubeTable.add_PreviewDrop($synchash.PreviewDrop_Command)
}
#---------------------------------------------- 
#endregion Get-PlayQueue Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-PlayQueue')