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
    [switch]$Clear,
    [switch]$Startup,
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
  $playlist_to_modify = $all_playlists.playlists | where {$_.name -eq $Playlist}
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
          $Spotify = $false
          write-ezlogs " | Removing $($Media.id) from Play Queue" -showtime
          $index_toremove = $thisapp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.id} | select * -ExpandProperty key
          foreach($index in $index_toremove){$null = $thisapp.config.Current_Playlist.Remove($index)}                         
        }
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
      $thisapp.config | Export-Clixml -Path $thisapp.Config.Config_Path -Force -Encoding UTF8  
      Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchash $synchash -Media_Profile_Directory $thisapp.Config.Media_Profile_Directory -thisApp $thisapp -media_contextMenu $synchash.Media_ContextMenu -PlayMedia_Command $synchash.PlayMedia_Command -Refresh_Spotify_Playlists -PlaySpotify_Media_Command $PlaySpotify_Media_Command -all_playlists $all_playlists
    }catch{write-ezlogs "An exception occurred removing $($Media.id) from Playlist $($Playlist)" -showtime -catcherror $_}    
  }
}

#---------------------------------------------- 
#endregion Update-Playlist Function
#----------------------------------------------
Export-ModuleMember -Function @('Update-Playlist')

