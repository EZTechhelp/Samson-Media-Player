<#
    .Name
    Get-Playlists

    .Version 
    0.1.0

    .SYNOPSIS
    Allows Importing Customized EZT-MediaPlayer Playlists

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
#region Get-Playlists Function
#----------------------------------------------
function Get-Playlists
{
  [CmdletBinding()]
  param (
    [switch]$Clear,
    [switch]$Startup,
    [switch]$PlayLink_OnDrop = $thisApp.Config.PlayLink_OnDrop,
    $synchash,
    $thisApp,
    $media_contextMenu,
    [switch]$Update_Current_Playlist,
    $all_available_Media,
    [string]$mediadirectory,
    [string]$Media_Profile_Directory,
    [string]$Playlist_Profile_Directory = $thisApp.config.Playlist_Profile_Directory,
    $Group,
    [System.Collections.Hashtable]$all_playlists,
    $thisScript,
    $PlayMedia_Command,
    $PlaySpotify_Media_Command,
    [switch]$Refresh_Spotify_Playlists,
    [switch]$Refresh_All_Playlists,
    [switch]$VerboseLog,
    [switch]$Import_Playlists_Cache
  )
  
  <#  if($Update_Current_Playlist){
      if($syncHash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}){
      $syncHash.PlayQueue_TreeView.Items.remove(($syncHash.PlayQueue_TreeView.Items | where {$_.Name -eq 'Play_Queue'}))
      }
      }else{
      $syncHash.PlayQueue_TreeView.Items.clear()
  }#>
  if($Verboselog){write-ezlogs "#### Executing Get-Playlists ####" -enablelogs -color yellow -linesbefore 1}
  $syncHash.PlayQueue_TreeView.items.Clear()
  $syncHash.Playlists_TreeView.items.Clear()
  #$syncHash.Playlists_Grid.items.Clear()
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
  if($Import_Playlists_Cache){   
    if(([System.IO.File]::Exists("$($thisApp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml"))){
      #$Global:all_playlists = [hashtable]::Synchronized(@{})
      #$all_playlists.playlists = Import-Clixml "$($thisApp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml"
      $synchash.all_playlists = Import-Clixml "$($thisApp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml"
    }else{
      write-ezlogs "Unable to find All playlists cache, generating new one" -showtime -warning
    }  
  }
  if($startup -or (@($all_playlists).count -lt 2)){
    #$Global:all_playlists = [hashtable]::Synchronized(@{})
    #$all_playlists.playlists = New-Object -TypeName 'System.Collections.ArrayList'
    $synchash.all_playlists = New-Object -TypeName 'System.Collections.ArrayList'
    $playlist_pattern = [regex]::new('$(?<=((?i)Playlist.xml))')
    [System.IO.Directory]::EnumerateFiles($Playlist_Profile_Directory,'*','AllDirectories') | where {$_ -match $playlist_pattern} | foreach { 
      $profile_path = $null
      if([System.IO.File]::Exists($_)){
        $profile_path = $_
        if($VerboseLog){write-ezlogs ">>>> Importing Playlist profile $profile_path" -showtime -enablelogs -color cyan}
        try{
          if([System.IO.File]::Exists($profile_path)){
            $Playlist_profile = Import-CliXml -Path $profile_path
          }          
        }catch{
          write-ezlogs "An exception occurred importing Playlist profile path ($profile_path)" -showtime -catcherror $_
        }             
        $Playlist_encodedTitle = $Playlist_profile.Playlist_ID
        if($Playlist_encodedTitle -and $synchash.all_playlists.Playlist_ID -notcontains $Playlist_encodedTitle){
          try{
            $Null = $synchash.all_playlists.Add($Playlist_profile)
          }catch{
            write-ezlogs "An exception occurred adding playlist ($Playlist_encodedTitle) from path $profile_path" -showtime -catcherror $_
          }  
        }               
      }
    }
    $synchash.all_playlists | Export-Clixml "$($thisApp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml" -Force -Encoding UTF8
  }  
    
  $syncHash.Playlists_TreeView.add_PreviewDrop($synchash.PreviewDrop_Command)
  $syncHash.MediaTable.add_PreviewDrop($synchash.PreviewDrop_Command)
  $syncHash.YoutubeTable.add_PreviewDrop($synchash.PreviewDrop_Command)

  if(!$Update_Current_Playlist){   
    try{
      #$image_resources_dir = [System.IO.Path]::Combine($($thisApp.Config.Current_folder) ,"Resources")
      if($synchash.all_playlists -and !$Refresh_All_Playlists)
      { 
        foreach ($Playlist in $synchash.all_playlists)
        {
          $Playlist_Item = New-Object System.Windows.Controls.TreeViewItem
          $Playlist_Item.AllowDrop = $true
          $Playlist_item.IsExpanded = $true
          $Playlist_name = $null
          $Playlist_ID = $null
          $Media_Description = $null
          $Track_Total = $null
          $Playlist_name = $Playlist.name
          if($verboselog){write-ezlogs ">>>> Adding Playlist $Playlist_name" -showtime -color cyan}
          $Playlist_ID = $Playlist.Playlist_ID
          $Media_Description = $Playlist.Description
          $Track_Total = $Playlist.Playlist_Track_Total
          $Type = $Playlist.type
          $Playlist_tracks = $Playlist.Playlist_tracks
          $Playlist_Item.Uid = "$($thisApp.Config.Current_Folder)\\Resources\\Fontisto-PlayList.png" 
          $Group_Name = 'Name'
          $Sub_GroupName = 'Artist_Name'
          $Playlist_Item.Tag = @{        
            synchash=$synchash;
            thisScript=$thisScript;
            thisApp=$thisApp
            PlayMedia_Command = $synchash.PlayMedia_Command
            Playlist = $Playlist
            All_Playlists = $synchash.all_playlists
          }        
          #$Playlist_Item.Tag = $Playlist
          $header = New-Object PsObject -Property @{
            'title' = $Playlist_name
            'Status' = ''
            'FontStyle' = 'Normal'
            'FontColor' = 'White'
            'FontWeight' = 'Bold'
            'FontSize' = 14          
            'Status_Msg' = ''
            'Status_FontStyle' = ''
            'Status_FontColor' = ''
            'Status_FontWeight' = ''
            'Status_FontSize' = ''          
          }        
          $Playlist_Item.Header = $header
          $Playlist_Item.Name = 'Playlist'
          $null = $Playlist_Item.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$Synchash.Media_ContextMenu)        
          $Playlist_Item.add_PreviewDrop($synchash.PreviewDrop_Command)
          foreach($Track in $Playlist_tracks){
            if($Track.id){
              $ChildItem = New-Object System.Windows.Controls.TreeViewItem
              $Childitem.AllowDrop = $true
              <#              if($track.Duration_ms){
                  [int]$hrs = $($([timespan]::FromMilliseconds($track.Duration_ms)).Hours)
                  [int]$mins = $($([timespan]::FromMilliseconds($track.Duration_ms)).Minutes)
                  [int]$secs = $($([timespan]::FromMilliseconds($track.Duration_ms)).Seconds) 
                  $total_time = "$mins`:$secs"
              }#>
              $Title = $null
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
                write-ezlogs "Can't find type or title for track $($track | out-string)" -showtime -warning
              }  
              if($Track.live_status -eq 'Offline'){
                $fontstyle = 'Italic'
                $fontcolor = 'Gray'
                $FontWeight = 'Normal'
                $FontSize = 12          
              }elseif($Track.live_status -eq 'Online' -or $track.live_status -eq 'Live'){
                $fontstyle = 'Normal'
                $fontcolor = 'LightGreen'
                $FontWeight = 'Normal'
                $FontSize = 12         
              }else{
                $fontstyle = 'Normal'
                $fontcolor = 'White' 
                $FontWeight = 'Normal'
                $FontSize = 12                     
              }
              if($Track.status_msg){
                $status_msg = $Track.status_msg
                if($Track.live_status -eq 'Offline'){
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
                'Status' = $Track.live_status
                'ID' = $Track.id
                'FontStyle' = $fontstyle
                'FontColor' = $fontcolor
                'FontWeight' = $FontWeight
                'FontSize' = $FontSize          
                'Status_Msg' = $status_msg
                'Status_FontStyle' = $Status_fontstyle
                'Status_FontColor' = $Status_fontcolor
                'Status_FontWeight' = $Status_FontWeight
                'Status_FontSize' = $Status_FontSize          
              }     
              if($Verboselog){write-ezlogs " | Adding Playlist Track: $Title" -showtime}
              $ChildItem.Header = $header       
              $ChildItem.Name = 'Track'
              $ChildItem.Uid = $icon_path
              #$ChildItem.Tag = $Track
              $ChildItem.Tag = @{        
                synchash=$synchash;
                thisScript=$thisScript;
                thisApp=$thisApp
                PlayMedia_Command = $synchash.PlayMedia_Command
                All_Playlists = $synchash.all_playlists
                Media = $Track
              }  
              $Childitem.add_PreviewDrop($synchash.PreviewDrop_Command)          
              $null = $Childitem.AddHandler([System.Windows.Controls.Button]::MouseDoubleClickEvent,$synchash.PlayMedia_Command)
              #$null = $Childitem.AddHandler([System.Windows.Controls.Button]::MouseRightButtonDownEvent,$Media_ContextMenu)
              $null = $Childitem.AddHandler([System.Windows.Controls.Button]::PreviewMouseRightButtonDownEvent,$synchash.Media_ContextMenu)
              #$null = $Childitem.AddHandler([System.Windows.Controls.Button]::PreviewMouseLeftButtonDownEvent,$Drag_MouseDown)            
              $null = $Playlist_Item.items.add($ChildItem)     
            }
          }
          $null = $syncHash.Playlists_TreeView.Items.Add($Playlist_Item)                         
        }
        $synchash.Update_TrayMenu_timer.start()
      }
    }catch{
      write-ezlogs "An exception occurred processing all_playlists" -showtime -catcherror $_
    }
  }
}

#---------------------------------------------- 
#endregion Get-Playlists Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-Playlists')

