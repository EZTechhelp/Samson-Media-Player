<#
    .Name
    Add-SpotifyPlayback

    .Version
    0.1.0

    .SYNOPSIS
    Provides immediate playback of Spotify media while importing

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
#region Add-SpotifyPlayback Function
#----------------------------------------------
function Add-SpotifyPlayback
{
  Param (
    $thisApp,
    $synchash,
    [switch]$PlayOnly,
    [switch]$AddtoQueue,
    [switch]$StartPlayback,
    [string]$SpotifyType,
    [string]$AddtoPlaylist,
    [string]$LinkUri,
    [string]$linktext,
    [switch]$Startup,
    [string]$PlaylistPosition,
    $PlaylistPositionTargetMedia,
    [switch]$Verboselog
  )
  if($SpotifyType -and $LinkUri){
    write-ezlogs ">>>> Adding Spotify media $LinkUri - Type: $SpotifyType - StartPlayback: $StartPlayback - AddtoQueue: $AddtoQueue" -showtime -logtype Spotify
    if($LinkUri -match '\?'){
      $LinkUri = ($LinkUri -split '\?')[0]
    }
    $url = [uri]$LinkUri
    if($LinkUri -match 'playlist'){
      if($LinkUri -match "playlist\:"){
        $playlist_id = ($($LinkUri) -split('playlist:'))[1].trim()
      }elseif($playlist_id -match '\/playlist\/'){
        $playlist_id = ($($LinkUri) -split('\/playlist\/'))[1].trim()
      }
      $source_type = 'Playlist'
    }elseif($LinkUri -match 'track'){
      if($LinkUri -match "track\:"){
        $playlist_id = ($($LinkUri) -split('track:'))[1].trim()
      }elseif($LinkUri -match '\/track\/'){
        $playlist_id = ($($LinkUri) -split('\/track\/'))[1].trim()
      }
      $source_type = 'Track'
    }elseif($LinkUri -match "episode"){
      if($LinkUri -match 'episode\:'){
        $playlist_id = ($($LinkUri) -split('episode:'))[1].trim()
      }elseif($LinkUri-match '\/episode\/'){
        $playlist_id = ($($LinkUri) -split('\/episode\/'))[1].trim()
      }
      $source_type = 'Episode'
    }elseif($LinkUri -match "show"){
      if($LinkUri -match 'show\:'){
        $playlist_id = ($($LinkUri) -split('show:'))[1].trim()
      }elseif($LinkUri -match '\/show\/'){
        $playlist_id = ($($LinkUri) -split('\/show\/'))[1].trim()
      }
      $source_type = 'Show'
    }
    if($playlist_id -match '\?si\='){
      $playlist_id = ($($playlist_id) -split('\?si\='))[0].trim()
    }
    if($PlayOnly){
      $live_status = 'Temporary'
    }
    if($playlist_id){
      try{
        if($source_type -eq 'Playlist'){
          $playlist_Info = Get-Playlist -Id $playlist_id -ApplicationName $thisApp.Config.App_Name
          $Playlist_name = $playlist_Info.Name
          $source_type = $playlist_Info.type
          $url = $playlist_Info.uri
          $PlaylistOwner = $playlist_Info.owner.display_name
          $PlaylistOwnerID = $playlist_Info.owner.id
          $PlaylistisPublic = $playlist_Info.public
          $track = [System.Collections.Generic.List[object]]($(Get-PlaylistItems -id $playlist_id -ApplicationName $thisApp.config.App_Name).track)
          write-ezlogs "| Found Spotify Playlist $Playlist_name" -showtime -logtype Spotify
        }elseif($source_type -eq 'Track'){
          $track = Get-Track -Id $playlist_id -ApplicationName $thisApp.Config.App_Name
          $source_type = $track.type
          $Playlist_name = "$($track.artists.name)"
          $url = $track.uri
          write-ezlogs "| Found Spotify Track $Playlist_name" -showtime -logtype Spotify
        }elseif($source_type -eq 'Show'){
          $playlist_Info = Get-Show -Id $playlist_id -ApplicationName $thisApp.Config.App_Name
          $track = [System.Collections.Generic.List[object]](Get-ShowEpisodes -id $playlist_id -ApplicationName $thisApp.config.App_Name)
          $Playlist_name = $playlist_Info.Name
          $source_type = $playlist_Info.type
          $url = $playlist_Info.uri
          write-ezlogs "| Found Spotify Show $Playlist_name" -showtime -logtype Spotify
        }elseif($source_type -eq 'Episode'){
          $track = Get-Episode -Id $playlist_id -ApplicationName $thisApp.Config.App_Name
          $source_type = $track.type
          $Playlist_name = "$($track.show.name)"
          $url = $track.uri
          write-ezlogs "| Found Spotify Track $Playlist_name" -showtime -logtype Spotify
        }
      }catch{
        write-ezlogs "An exception occurred getting Spotify media type $LinkUri" -showtime -catcherror $_
      }
    }
    if($track){
      $type = $Null
      if($track.count -gt 1){
        $Track = $track | select-object -first 1
      }
      $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($track.id)-$($Playlist_ID)")
      $encodedid = [System.Convert]::ToBase64String($encodedBytes)
      if($track.type){
        $type = $track.type
      }else{
        $type = $source_type
      }
      if($Track.Duration_ms -and $Track.Duration_ms -notmatch ":"){
        try{
          $Timespan = [timespan]::FromMilliseconds($Track.Duration_ms)
          if($Timespan){
            $duration = "$(([string]$timespan.Hours).PadLeft(2,'0')):$(([string]$timespan.Minutes).PadLeft(2,'0')):$(([string]$timespan.Seconds).PadLeft(2,'0'))"
          }
        }catch{
          write-ezlogs "An exception occurred parsing timespan for duration $($Track.Duration_ms)" -showtime -catcherror $_
        }
      }
      if(-not [string]::IsNullOrEmpty(($track.Album.Name))){
        $Album = ($track.Album.Name)
        $Album_id = $($Track.Album.id)
        $artist = ($track.Artists.Name -join ',')
        $artist_id = $($Track.Artists.id -join ',')
      }elseif(-not [string]::IsNullOrEmpty(($track.Show.Name))){
        $Album = ($track.Show.Name)
        $Album_id = ($track.Show.id)
        $artist = ($track.show.Name -join ',')
        $artist_id = $($Track.show.id -join ',')
      }
      if(($Track.Album.images).url){
        $imagetocache = ($Track.Album.images | Where-Object {$_.Width -le 300} | Select-Object -First 1).url
        if(!$imagetocache){
          $imagetocache = ($Track.Album.images | Where-Object {$_.Width -ge 300} | Select-Object -last 1).url
        }
        if(!$imagetocache){
          $imagetocache = (($Track.Album.images).psobject.Properties.Value).url | Select-Object -First 1
        }
      }elseif(($Track.Show.images).url){
        $imagetocache = ($Track.Show.images | Where-Object {$_.Width -le 300} | Select-Object -First 1).url
        if(!$imagetocache){
          $imagetocache = ($Track.Show.images | Where-Object {$_.Width -ge 300} | Select-Object -last 1).url
        }
        if(!$imagetocache){
          $imagetocache = (($Track.Show.images).psobject.Properties.Value).url | Select-Object -First 1
        }
      }
      if(-not [string]::IsNullOrEmpty($thisApp.Config.SpotifyMedia_Display_Syntax)){
        $DisplayName = $thisApp.Config.SpotifyMedia_Display_Syntax -replace '%artist%',$artist -replace '%title%',$track.name -replace '%album%',$Album -replace '%track%',$($track.track_number) -replace '%playlist%',$playlist_name
      }else{
        $DisplayName = $Null
      }
      $Media = [Media]@{
        'title' = $track.name
        'artist' = $artist
        'Display_Name' = $DisplayName
        'id' = $encodedid
        'album' = $Album
        'Playlist' = $($Playlist_name)
        'description' =''
        'track' = $($track.track_number)
        'Album_id' = $Album_id
        'Spotify_id' = $($Track.id)
        'duration' = $duration
        'url' = $($Track.uri)
        'Artist_ID' = $artist_id
        'cached_image_path' = $imagetocache
        'type' = $type
        'Playlist_url' = $url
        'playlist_id' = $playlist_id
        'PlaylistOwner' = $PlaylistOwner
        'PlaylistOwnerID' = $PlaylistOwnerID
        'PlaylistisPublic' = $PlaylistisPublic
        'Profile_Date_Added' = [Datetime]::Now.ToString()
        'Source' = 'Spotify'
      }
      if($AddtoQueue){
        if(!$synchash.Temporary_Media){
          $synchash.Temporary_Media = [System.Collections.Generic.List[Object]]::new()
        }
        if($synchash.Temporary_Media.id -notcontains $media.id){
          write-ezlogs "| Adding track '$($media.title) - $($media.Artist)' to temporary media queue"
          $Null = $synchash.Temporary_Media.add($media)
        }else{
          write-ezlogs "| Spotify track '$($media.title) - $($media.Artist)' already exists in temporary media queue" -warning
        }
        Update-PlayQueue -synchash $synchash -thisApp $thisApp -Add -media @($media) -Use_RunSpace -RefreshQueue
      }elseif($AddtoPlaylist -and $media){
        write-ezlogs "| Adding Spotify track '$($media.title) - $($media.Artist)' to playlist: $AddtoPlaylist - Position: $PlaylistPosition - PositionTargetMedia: $($PlaylistPositionTargetMedia.title)"
        Add-Playlist -Media $media -Playlist $AddtoPlaylist -thisApp $thisapp -synchash $synchash -verboselog:$thisapp.Config.Verbose_logging -Use_RunSpace -Update_UI -position $PlaylistPosition -PositionTargetMedia $PlaylistPositionTargetMedia
      }
      if($media -and ($StartPlayback -or $PlayOnly)){
        $synchash.Temporary_Playback_Media = $media
        write-ezlogs "| Starting temporary playback for Spotify track: '$($media.title) - $($media.Artist)'"
        Start-SpotifyMedia -Media $media -thisApp $thisapp -synchash $synchash -use_WebPlayer:$thisapp.config.Spotify_WebPlayer -Show_notifications:$thisApp.config.Show_notifications -RestrictedRunspace:$thisapp.config.Spotify_WebPlayer
      }
    }else{
      write-ezlogs "| No track or metadata found for Spotify link: '$($LinkUri)" -warning
    }
  }else{
    write-ezlogs "Can't start Spotify media, missing SpotifyType ($($SpotifyType)) or LinkUri ($($LinkUri))" -warning -AlertUI
  }
}
#----------------------------------------------
#endregion Add-SpotifyPlayback Function
#----------------------------------------------
Export-ModuleMember -Function @('Add-SpotifyPlayback')