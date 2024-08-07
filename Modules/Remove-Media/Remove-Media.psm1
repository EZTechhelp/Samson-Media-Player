<#
    .Name
    Remove-Media

    .Version 
    0.1.0

    .SYNOPSIS
    Removes Media from media profiles, playlists, data tables and other other data sources 

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
#region Remove-Media Function
#----------------------------------------------
function Remove-Media {
  <#
      .SYNOPSIS
      Removes media from itemssources and playlists.

      .EXAMPLE
      Remove-LocalMedia -synchash $synchash -media_toRemove $media -thisapp $thisApp
  #>
  [CmdletBinding()]
  Param (
    $thisApp,
    $synchash,
    $media_toRemove,
    [switch]$use_Runspace,
    [string]$Playlist_Profile_Directory = $thisApp.config.Playlist_Profile_Directory,
    [switch]$Verboselog,
    [switch]$update_Library
  )
  try{
    $Mediaremove_item_Scriptblock = {
      Param (
        $thisApp = $thisApp,
        $synchash = $synchash,
        $media_toRemove = $media_toRemove,
        [switch]$use_Runspace = $use_Runspace,
        [string]$Playlist_Profile_Directory = $Playlist_Profile_Directory,
        [switch]$Verboselog = $Verboselog,
        [switch]$update_Library = $update_Library
      )
      try{
        foreach($Media in $media_toRemove){
          #write-ezlogs "#### Removing Media $($Media.title) - $($Media.id) ####" -showtime -color cyan -linesbefore 1
          if($Media.Source -eq 'Local'){       
            $refreshLocal = $true        
            #$all_media_profile = $synchash.All_Local_Media
            if($synchash.All_Local_Media.IsFixedSize){
              #write-ezlogs " | All_local_media is a fixed size, recasting to generic list" -warning
              $synchash.All_Local_Media = [System.Collections.Generic.List[object]]::new($synchash.All_Local_Media)
            }
            if($synchash.All_Local_Media){
              $index = $synchash.All_Local_Media.id.IndexOf($Media.id)
              if($index -ne -1){                 
                $Collectionitem_toremove = $synchash.All_Local_Media[$index]                          
              }
              #write-ezlogs ">>>> Getting local media from All_Local_Media - $($Collectionitem_toremove | out-string)"
            }                       
            foreach($collection in $Collectionitem_toremove){   
              if($synchash.All_Local_Media){
                write-ezlogs "| Removing $($collection.title) from All_Local_Media - All_local_media type: $($synchash.All_Local_Media.GetType().name)" -showtime -loglevel 2
                $null = $synchash.All_Local_Media.remove($collection) 
              }                                           
            }                                                                                          
          }      
          if($Media.url -match 'spotify\:' -or $Media.Source -eq 'Spotify'){
            $refreshSpotify = $true
            if($synchash.All_Spotify_Media.IsFixedSize){
              write-ezlogs " | All_Spotify_Media is a fixed size, recasting to generic list" -warning
              $synchash.All_Spotify_Media = [System.Collections.Generic.List[object]]::new($synchash.All_Spotify_Media)
            }
            if($synchash.All_Spotify_Media){
              $index = $synchash.All_Spotify_Media.id.IndexOf($Media.id)
              if($index -ne -1){                 
                $Collectionitem_toremove = $synchash.All_Spotify_Media[$index]
              }
              #write-ezlogs ">>>> Getting Spotify media from All_Spotify_Media - $($Collectionitem_toremove | out-string)"
            } 
            foreach($collection in $Collectionitem_toremove){
              if($synchash.All_Spotify_Media){
                write-ezlogs "| Removing $($collection.title) from All_Spotify_Media - All_Spotify_Media type: $($synchash.All_Spotify_Media.GetType().name)" -showtime -loglevel 2
                $null = $synchash.All_Spotify_Media.remove($collection) 
              } 
            }
            $all_media_profile = $synchash.All_Spotify_Media                                
          }         
          if($Media.Source -eq 'Youtube' -or $Media.Source -eq 'YoutubePlaylist' -or $media.url -match 'youtube\.com' -or $media.url -match 'youtu\.be'){         
            $refreshYoutube = $true
            if($synchash.All_Youtube_Media.IsFixedSize){
              write-ezlogs " | All_Youtube_media is a fixed size, recasting to generic list" -warning
              $synchash.All_Youtube_Media = [System.Collections.Generic.List[object]]::new($synchash.All_Youtube_Media)
            }
            if($synchash.All_Youtube_Media){
              $index = $synchash.All_Youtube_Media.id.IndexOf($Media.id)
              if($index -ne -1){                 
                $Collectionitem_toremove = $synchash.All_Youtube_Media[$index]
              }
              #write-ezlogs ">>>> Getting Youtube media from All_Youtube_Media - $($Collectionitem_toremove | out-string)"
            } 
            foreach($collection in $Collectionitem_toremove){
              if($synchash.All_Youtube_Media){
                write-ezlogs "| Removing $($collection.title) from All_Youtube_Media - All_Youtube_Media type: $($synchash.All_Youtube_Media.GetType().name)" -showtime -loglevel 2
                $null = $synchash.All_Youtube_Media.remove($collection) 
              } 
            }
            $all_media_profile = $synchash.All_Youtube_Media                                                   
          }
          if($Media.Source -eq 'Twitch'){       
            $refreshTwitch = $true
            if($synchash.All_Twitch_Media.IsFixedSize){
              write-ezlogs " | All_Twitch_media is a fixed size, recasting to generic list" -warning
              $synchash.All_Twitch_Media = [System.Collections.Generic.List[object]]::new($synchash.All_Twitch_Media)
            }
            if($synchash.All_Twitch_Media){
              $index = $synchash.All_Twitch_Media.id.IndexOf($Media.id)
              if($index -ne -1){                 
                $Collectionitem_toremove = $synchash.All_Twitch_Media[$index]
              }
              #write-ezlogs ">>>> Getting Twitch media from All_Twitch_Media - $($Collectionitem_toremove | out-string)"
            } 
            foreach($collection in $Collectionitem_toremove){
              if($synchash.All_Twitch_Media){
                write-ezlogs "| Removing $($collection.title) from All_Twitch_Media - All_Twitch_Media type: $($synchash.All_Twitch_Media.GetType().name)" -showtime -loglevel 2
                $null = $synchash.All_Twitch_Media.remove($collection) 
              } 
            }
            $all_media_profile = $synchash.All_Twitch_Media               
          }
          if($thisapp.config.Current_Playlist.values -contains $Media.id){
            write-ezlogs " | Removing $($Media.id) from Play Queue" -showtime
            $index_toremove = $thisapp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.id} | select * -ExpandProperty key
            $null = $thisapp.config.Current_Playlist.Remove($index_toremove)                  
          }
          try{
            $playlist_to_modify = lock-object -InputObject $synchash.all_playlists_ListLock -ScriptBlock {
              $playlist_to_modify = $synchash.all_playlists.where({$_.playlist_tracks.values.id -eq $Media.id})
              if(!$playlist_to_modify){
                $playlist_to_modify = $synchash.all_playlists.where({($_.playlist_tracks.values.url -replace '\\\\','\') -eq ($Media.url -replace '\\\\','\')})
              }
              $playlist_to_modify
            }
          }catch{
            write-ezlogs "An exception occurred enumerating all_playlists" -catcherror $_
          }
        
          if($playlist_to_modify){
            foreach($Playlist in $playlist_to_modify){
              $index_toRemove = $Playlist.PlayList_tracks.GetEnumerator() | where {$_.value.id -eq $Media.id} | select * -ExpandProperty key 
              if([string]::IsNullOrEmpty($index_toRemove)){
                $index_toRemove = $Playlist.PlayList_tracks.GetEnumerator().where({($_.value.url -replace '\\\\','\') -eq ($Media.url -replace '\\\\','\')}) | select * -ExpandProperty key 
              }
              if(-not [string]::IsNullOrEmpty($index_toRemove)){
                foreach($index in $index_toRemove){
                  write-ezlogs " | Removing track $($Media.id) - index $($index) from playlist $($Playlist.name)" -showtime
                  $null = $Playlist.Playlist_tracks.Remove($index)
                }
              }
            }
            write-ezlogs ">>>> Saving all_playlists profile to path: $($thisApp.Config.Playlists_Profile_Path)"
            Export-SerializedXML -InputObject $synchash.All_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist
          }    
          if($Media.Source -eq 'Local'){   
            $synchash.update_status_timer.tag = 'Local'
            $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-MediaProfile','All-Media-Profile.xml')       
            #write-ezlogs "| Removing track $($Media_id) from Local Media Browser and all media profiles" -showtime                                                                      
          }      
          if($Media.source -eq 'Spotify' -or $Media.uri -eq 'spotify\:' -or $Media.url -match 'spotify\:'){
            $synchash.update_status_timer.tag = 'Spotify'
            $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Spotify_MediaProfile','All-Spotify_Media-Profile.xml') 
            $tracks_property = "playlist_tracks"
            #write-ezlogs "| Removing track $($Track_ID) from Spotify Media Browser and all media profiles" -showtime                                   
          }         
          if($Media.Source -eq 'Youtube' -or $Media.type -match 'Youtube' -or $media.url -match 'youtube\.com'){         
            $synchash.update_status_timer.tag = 'Youtube'
            $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Youtube_MediaProfile','All-Youtube_Media-Profile.xml') 
            #write-ezlogs "| Removing track $($Media_id) from Youtube Media Browser and all media profiles" -showtime                     
          }
          if($Media.Source -eq 'Twitch'){         
            #write-ezlogs "| Add track $($Media_id) to remove from Twitch Media Browser and all media profiles" -showtime   
            $synchash.update_status_timer.tag = 'Twitch'
            $AllMedia_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Twitch_MediaProfile','All-Twitch_Media-Profile.xml')                
          }
          if([System.IO.File]::Exists($AllMedia_Profile_File_Path) -and !$refreshLocal){
            write-ezlogs ">>>> Saving All LocalMedia profile cache at $AllMedia_Profile_File_Path" -showtime
            Export-SerializedXML -InputObject $all_media_profile -path $AllMedia_Profile_File_Path
          }
        }  
        if($refreshLocal){
          try{ 
            write-ezlogs " | ProfileManager_Queue.IsEmpty: $($synchash.ProfileManager_Queue.IsEmpty)"
            if($synchash.All_Local_Media -and ($synchash.ProfileManager_Queue.IsEmpty -and $update_Library)){
              write-ezlogs ">>>> Exporting All Media Profile cache to file $($AllMedia_Profile_File_Path)" -showtime -color cyan -logtype LocalMedia 
              $synchash.All_local_Media = $synchash.All_Local_Media | Sort-Object -Property 'Artist','Track'
              Export-SerializedXML -InputObject $synchash.All_local_Media -path $AllMedia_Profile_File_Path 
              if(!$synchash.Refresh_LocalMedia_timer.isEnabled){ 
                $synchash.Refresh_LocalMedia_timer.tag = 'WatcherLocalRefresh'             
                $synchash.Refresh_LocalMedia_timer.start()   
              }
              if(!$synchash.update_Queue_timer.isEnabled){
                $synchash.update_Queue_timer.tag = 'FullRefresh'
                $synchash.update_Queue_timer.start()  
              }
            }elseif(!$update_Library){
              if(!$synchash.Refresh_LocalMedia_timer.isEnabled){
                $synchash.Refresh_LocalMedia_timer.tag = 'WatcherLocalRefresh'  
                $synchash.Refresh_LocalMedia_timer.start()   
              }
            }
          }catch{
            write-ezlogs 'An exception occurred executing Refresh_LocalMedia_timer' -showtime -catcherror $_
          }
        }  
        if($refreshSpotify -and $synchash.SpotifyTable){
          try{  
            $synchash.Refresh_SpotifyMedia_timer.tag = 'QuickRefresh_SpotifyMedia_Button'  
            $synchash.Refresh_SpotifyMedia_timer.start()            
          }catch{
            write-ezlogs 'An exception occurred executing Refresh_SpotifyMedia_timer' -showtime -catcherror $_
          }
        }
        if($refreshYoutube -and $synchash.YoutubeTable){
          try{  
            $synchash.Refresh_YoutubeMedia_timer.tag = 'QuickRefresh_YoutubeMedia_Button'  
            $synchash.Refresh_YoutubeMedia_timer.start()            
          }catch{
            write-ezlogs 'An exception occurred executing Refresh_YoutubeMedia_timer' -showtime -catcherror $_
          }
        }
        if($refreshTwitch -and $synchash.TwitchTable){
          try{  
            $synchash.Refresh_TwitchMedia_timer.tag = 'QuickRefresh_TwitchMedia_Button'  
            $synchash.Refresh_TwitchMedia_timer.start()            
          }catch{
            write-ezlogs 'An exception occurred executing Refresh_TwitchMedia_timer' -showtime -catcherror $_
          }
        }             
      }catch{
        write-ezlogs "An exception occurred in Mediaremove_item_Scriptblock" -showtime -catcherror $_
      }     
    }
    if($use_Runspace){
      $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
      Start-Runspace -scriptblock $Mediaremove_item_Scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'Remove_Media_RUNSPACE' -thisApp $thisApp -synchash $synchash
      $Variable_list = $Null
    }else{
      Invoke-Command -ScriptBlock $Mediaremove_item_Scriptblock 
    }
  }catch{
    write-ezlogs "An exception occurred in  Remove-Media" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Remove-Media Function
#----------------------------------------------
Export-ModuleMember -Function @('Remove-Media')