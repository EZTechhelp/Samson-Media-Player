<#
    .Name
    Update-Playlist

    .Version 
    0.1.0

    .SYNOPSIS
    Allows Updating Customized EZT-MediaPlayer Playlists

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
#region Update-Playlist Function
#----------------------------------------------
function Update-Playlist
{
  [CmdletBinding()]
  param (
    [string]$Playlist,
    [System.Object]$media,
    [switch]$Remove,
    [switch]$update,
    [switch]$updateAll,
    [switch]$Clear,
    [switch]$Startup,
    $synchash,
    $thisApp,
    $media_contextMenu,
    [switch]$Update_Current_Playlist,
    [switch]$clear_lastplayed,
    $all_available_Media,
    [string]$mediadirectory,
    [string]$Media_Profile_Directory,
    [string]$Playlist_Profile_Directory = $thisApp.config.Playlist_Profile_Directory,
    $Group,
    [System.Collections.Hashtable]$all_playlists,
    $thisScript,
    [switch]$Refresh_Spotify_Playlists,
    [switch]$Refresh_All_Playlists,
    [switch]$VerboseLog,
    [switch]$Import_Playlists_Cache
  )

  $playlist_to_modify = $synchash.all_playlists | where {$_.name -eq $Playlist}
  if($Remove){
    try{   
      if($Playlist -eq 'Play Queue'){ 
        if($Media.Spotify_Path){
          if($thisapp.config.Current_Playlist.values -contains $Media.encodedtitle){
            write-ezlogs " | Removing $($Media.encodedtitle) from Play Queue" -showtime
            $index_toremove = $thisapp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.encodedtitle} | select * -ExpandProperty key
            foreach($index in $index_toremove){$null = $thisapp.config.Current_Playlist.Remove($index)}            
          }      
        }elseif($thisapp.config.Current_Playlist.values -contains $Media.id){
          write-ezlogs " | Removing $($Media.id) from Play Queue" -showtime
          $index_toremove = $thisapp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.id} | select * -ExpandProperty key
          foreach($index in $index_toremove){$null = $thisapp.config.Current_Playlist.Remove($index)}                         
        }
        #Get-PlayQueue -verboselog:$false -synchash $synchash -thisApp $thisapp
      }elseif($playlist_to_modify){
        try{
          $Track_To_Remove = $playlist_to_modify.Playlist_tracks | where {$_.id -eq $Media.id}
          if($Track_To_Remove){
            write-ezlogs " | Removing $($Track_To_Remove.id) from Playlist $($Playlist)" -showtime
            $null = $playlist_to_modify.Playlist_tracks.Remove($Track_To_Remove)
            $playlist_to_modify | Export-Clixml $playlist_to_modify.Playlist_Path -Force
          }
        }catch{write-ezlogs "An exception occurred removing $($Media.id) from Playlist $($Playlist)" -showtime -catcherror $_}    
      }
      if($clear_lastplayed){
        write-ezlogs " | Clearing last played media" -showtime
        $synchash.Current_playing_media = $Null
      } 
      $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8  
      Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -thisApp $thisapp
      Get-PlayQueue -verboselog:$false -synchash $synchash -thisApp $thisapp
    }catch{
      write-ezlogs "An exception occurred removing $($Media.id) from Playlist $($Playlist)" -showtime -catcherror $_
    }    
  }elseif($update){
    if($Playlist -eq 'Play Queue'){ 
      <#      if($Media.Spotify_Path){
          if($thisapp.config.Current_Playlist.values -contains $Media.encodedtitle){
          write-ezlogs " | Removing $($Media.encodedtitle) from Play Queue" -showtime
          
          $index_toremove = $thisapp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.encodedtitle} | select * -ExpandProperty key
          foreach($index in $index_toremove){$null = $thisapp.config.Current_Playlist.Remove($index)}            
          }      
          }elseif($thisapp.config.Current_Playlist.values -contains $Media.id){
          $Spotify = $false
          write-ezlogs " | Removing $($Media.id) from Play Queue" -showtime
          $index_toremove = $thisapp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.id} | select * -ExpandProperty key
          foreach($index in $index_toremove){$null = $thisapp.config.Current_Playlist.Remove($index)}                         
      }#>
    }elseif($playlist_to_modify){
      try{
        $Track_To_Update = $playlist_to_modify.Playlist_tracks | where {$_.id -eq $Media.id}
        if($Track_To_Update){        
          write-ezlogs " | Updating $($Track_To_Update.id) in Playlist $($Playlist)" -showtime
          $Track_To_Update = $media
          $playlist_to_modify | Export-Clixml $playlist_to_modify.Playlist_Path -Force
        }
      }catch{
        write-ezlogs "An exception occurred updating $($Media.id) for Playlist $($Playlist)" -showtime -catcherror $_
      }    
    }
  }elseif($updateall){
    try{
      #$all_playlists = [hashtable]::Synchronized(@{})
      $synchash.all_playlists = Import-Clixml "$($thisApp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml"
      write-ezlogs ">>>> Updating all playlists containing media id $($Media.id)" -showtime
      $Playlist_to_update = $synchash.all_playlists | where {$_.Playlist_tracks.id -eq $media.id}       
      if($Playlist_to_update.Playlist_Path){      
        $Playlist_profile = Import-Clixml $Playlist_to_update.Playlist_Path
        $Playlist_track = $Playlist_profile.PlayList_tracks | where {$_.id -eq $media.id}
        write-ezlogs ">>>> playlist track: $($Playlist_track | out-string)" -showtime -color cyan  
        if($Playlist_profile.Playlist_tracks -contains $Playlist_track){
          write-ezlogs "| Removing Track $($Playlist_track.title)" -showtime
          $null = $Playlist_profile.Playlist_tracks.Remove($Playlist_track)
        }
        if($Playlist_track.Playlist_tracks.id -notcontains $media.id){
          write-ezlogs "| Adding updated Track $($media.title)" -showtime
          $null = $Playlist_profile.Playlist_tracks.add($media)
        }         
      }
      if([System.IO.FIle]::Exists($Playlist_profile.Playlist_Path)){
        write-ezlogs ">>>> Saving updated playlist profile from playlist profile: $($Playlist_profile.Playlist_Path)" -showtime -color cyan
        $Playlist_profile | Export-Clixml $Playlist_profile.Playlist_Path -Force 
      }    
      <#    foreach($track in $Playlist_profile.Playlist_tracks){
          if($track.id -eq $media.id){   
          write-ezlogs ">>>> Updating track $($track.title) in playlist $($Playlist_profile.name)" -showtime -color cyan              
          $track = $Media
       
          write-ezlogs " | Track Title: $($track.title)
          | Media TItle: $($Media.title)
          | Track Status: $($track.Status_msg)
          | Media Status: $($Media.Status_msg)
          | thumbnail: $($Media.thumbnail)   
          | track.Playlist_File_Path: $($track.Playlist_File_Path)  
          | Playlist_profile.Playlist_Path: $($Playlist_profile.Playlist_Path)"
                   
          if([System.IO.FIle]::Exists($track.Playlist_File_Path)){
          write-ezlogs ">>>> Saving updated playlist profile from track profile: $($track.Playlist_File_Path)" -showtime -color cyan
          $Playlist_profile | Export-Clixml $track.Playlist_File_Path -Force
          }elseif([System.IO.FIle]::Exists($Playlist_profile.Playlist_Path)){
          write-ezlogs ">>>> Saving updated playlist profile from playlist profile: $($Playlist_profile.Playlist_Path)" -showtime -color cyan
          $Playlist_profile | Export-Clixml $Playlist_profile.Playlist_Path -Force 
          }         
          }
      }#>
      write-ezlogs ">>>> Saving updated all playlists cache: $($thisApp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml" -showtime -color cyan
      $synchash.all_playlists | Export-Clixml "$($thisApp.config.Playlist_Profile_Directory)\\All-Playlists-Cache.xml" -Force 
    }catch{
      write-ezlogs "An exception occurred updating all playlists" -showtime -catcherror $_
    }
  }
}

#---------------------------------------------- 
#endregion Update-Playlist Function
#----------------------------------------------
Export-ModuleMember -Function @('Update-Playlist')

