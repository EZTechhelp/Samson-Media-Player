<#
    .Name
    Get-MediaProfile

    .Version
    0.1.0

    .SYNOPSIS
    Provides lookup of media profiles by ID from libraries, playlists and other collections

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
#region Get-MediaProfile Function
#----------------------------------------------
function Get-MediaProfile
{
  Param (
    $Media_ID,
    $Media_URL,
    $Playlist_ID,
    $Media_title,
    $Media_Channel,
    [switch]$SkipYTHistory,
    $thisApp,
    $synchash,
    [switch]$Use_RunSpace,
    [switch]$SaveProfile,
    [switch]$Startup,
    [switch]$Verboselog
  )
  $Get_MediaProfile_ScriptBlock = {
    param
    (
      $thisApp = $thisApp,
      $synchash = $synchash,
      $Media_ID = $Media_ID,
      $Use_RunSpace = $Use_RunSpace,
      [switch]$SaveProfile = $SaveProfile,
      $Startup = $Startup,
      $Media_URL = $Media_URL,
      $Playlist_ID = $Playlist_ID,
      $Media_title = $Media_title,
      $Media_Channel = $Media_Channel,
      [switch]$SkipYTHistory = $SkipYTHistory,
      [switch]$Verboselog = $Verboselog
    )
    if($Verboselog){
      $Get_MediaProfile_Measure = [system.diagnostics.stopwatch]::StartNew()
    }
    $AllTwitch_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Twitch_MediaProfile','All-Twitch_Media-Profile.xml')
    $AllSpotify_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Spotify_MediaProfile','All-Spotify_Media-Profile.xml')
    $AllLocal_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-MediaProfile','All-Media-Profile.xml')
    $AllYoutube_Profile_File_Path = [System.IO.Path]::Combine($thisapp.Config.Media_Profile_Directory,'All-Youtube_MediaProfile','All-Youtube_Media-Profile.xml')
    $Track = $Null
    $index = $null
    if($Media_URL){
      $Ids = $Media_URL
      $Property = 'url'
    }elseif($Playlist_ID){
      $ids = $Playlist_ID
      $Property = 'Playlist_ID'
    }elseif($Media_title){
      $ids = $Media_title
      $Property = 'title'
    }elseif($Media_Channel){
      $ids = $Media_Channel
      $Property = 'channel_name'
    }else{
      $Ids = $Media_ID
      $Property = 'id'
    }
    if($synchash.All_Playlists.items -is [System.Collections.Generic.List[Playlist]]){
      $All_Playlists = $synchash.All_Playlists.items
    }else{
      $All_Playlists = $synchash.All_Playlists
    }
    $Ids | & { process {
        try{
          #Is it in a custom playlist
          if(!$track -and $All_Playlists.Playlist_tracks.values.$Property){
            try{
              $track = lock-object -InputObject $synchash.all_playlists_ListLock -ScriptBlock {
                if($All_Playlists.Playlist_tracks){
                  $index = $All_Playlists.Playlist_tracks.values.$Property.IndexOf($_)
                  if($index -ne -1){
                    $All_Playlists.Playlist_tracks.values[$index]
                  }
                }
              }
              if(!$track -and $Property -eq 'title'){               
                $track = lock-object -InputObject $synchash.all_playlists_ListLock -ScriptBlock {
                  if($All_Playlists.Playlist_tracks){
                    $index = $All_Playlists.Playlist_tracks.values.'channel_name'.IndexOf($_)
                    if($index -ne -1){
                      $All_Playlists.Playlist_tracks.values[$index]
                    }
                  }
                }
              }
            }catch{
              write-ezlogs "[Get-MediaProfile] An exception occurred attempting to lookup ID $($_) in all_playlists.Playlist_tracks" -CatchError $_
            }
          }
          #Is it local media
          if($synchash.All_local_Media.count -gt 0){
            try{
              $index = $synchash.All_local_Media.$Property.IndexOf($_)
            }catch{
              $index = -1
            }
            if($index -ne -1){
              $Track = $synchash.All_local_Media[$index]
            }
            if($track.count -gt 1){
              write-ezlogs "[Get-MediaProfile] Found duplicate track $($track.id) in All local Media -- removing" -warning
              $remove = [System.Linq.Enumerable]::Last($track)
              $null = $synchash.All_local_Media.Remove($remove)
              Export-SerializedXML -InputObject $synchash.All_local_Media -path $AllLocal_Profile_File_Path
            }elseif(!$track -and $Property -eq 'url' -and [system.io.path]::HasExtension($_)){
              $localurl = $Null
              $localurl = $_
              try{
                $All_local_Media = [System.Collections.Generic.List[object]]::new($synchash.All_local_Media)
                $track = $All_local_Media.where({($_.url -replace '\\\\','\') -eq ($localurl -replace '\\\\','\')})
              }catch{
                write-ezlogs "[Get-MediaProfile] An exception occurred creating new Generic.List from All_local_Media" -catcherror $_
              }
            }
          }
          #Is it Spotify
          if(!$Track -and $synchash.All_Spotify_Media.count -gt 0){
            try{
              $index = $synchash.All_Spotify_Media.$Property.IndexOf($_)
            }catch{
              $index = -1
            }
            if($index -ne -1){
              $Track = $synchash.All_Spotify_Media[$index]
            }
            if($track.count -gt 1){
              write-ezlogs "[Get-MediaProfile] Found duplicate track $($track.id) in All Spotify Media -- removing" -warning
              $remove = [System.Linq.Enumerable]::Last($track)
              $null = $synchash.All_Spotify_Media.Remove($remove)
              Export-SerializedXML -InputObject $synchash.All_Spotify_Media -Path $AllSpotify_Profile_File_Path
            }
          }
          #Is it Twitch
          if(!$Track){
            if($synchash.All_Twitch_Media.count -eq 0){
              if([System.IO.File]::Exists($AllTwitch_Profile_File_Path)){
                write-ezlogs "[Get-MediaProfile] >>>> Unable to find twitch media, importing All Twitch Media Profile at $AllTwitch_Profile_File_Path"
                $all_Twitch_profile = Import-SerializedXML $AllTwitch_Profile_File_Path
                try{
                  $index = $all_Twitch_profile.$Property.IndexOf($_)
                }catch{
                  $index = -1
                }
                if($index -ne -1){
                  $Track = $all_Twitch_profile[$index]
                }
              }
            }else{
              try{
                $index = $synchash.All_Twitch_Media.$Property.IndexOf($_)
                if($index -eq -1){
                  $index = $synchash.All_Twitch_Media.User_id.IndexOf("$_")
                }
              }catch{
                $index = -1
              }
              if($index -ne -1){
                $Track = $synchash.All_Twitch_Media[$index]
              }
            }
            if($track.count -gt 1){
              write-ezlogs "[Get-MediaProfile] Found duplicate track $($track.id) in All Twitch Media -- removing" -warning
              $remove = [System.Linq.Enumerable]::Last($track)
              $null = $synchash.All_Twitch_Media.Remove($remove)
              Export-SerializedXML -InputObject $synchash.All_Twitch_Media -path $AllTwitch_Profile_File_Path
            }
          }
          #Is it Youtube
          if(!$Track){
            if($synchash.All_Youtube_Media.count -eq 0){
              if([System.IO.File]::Exists($AllYoutube_Profile_File_Path)){
                $all_youtube_profile = Import-SerializedXML -Path $AllYoutube_Profile_File_Path
                write-ezlogs "[Get-MediaProfile] >>>> Unable to find Youtube media, importing All youtube Media Profile at $AllYoutube_Profile_File_Path"
                if($all_youtube_profile.$Property){
                  try{
                    $index = $all_youtube_profile.$Property.IndexOf($_)
                  }catch{
                    $index = -1
                  }
                  if($index -ne -1){
                    $Track = $all_youtube_profile[$index]
                  }
                }
              }
            }else{
              try{
                $index = $synchash.All_Youtube_Media.$Property.IndexOf($_)
              }catch{
                $index = -1
              }
              if($index -ne -1){
                $Track = $synchash.All_Youtube_Media[$index]
              }
            }
            if($track.count -gt 1){
              write-ezlogs "Found duplicate track $($track.id) in All Youtube Media -- removing" -warning
              $remove = [System.Linq.Enumerable]::Last($track)
              $null = $synchash.All_Youtube_Media.Remove($remove)
              Export-SerializedXML -InputObject $synchash.All_Youtube_Media -path $AllYoutube_Profile_File_Path
            }
          }
          #Is it Temporary media
          if(!$track -and $synchash.Temporary_Playback_Media.$Property -eq $_){
            $track = $synchash.Temporary_Playback_Media
          }
          #Is it Temporary queue?
          if(!$track -and $synchash.Temporary_Media.$Property){
            $track = lock-object -InputObject $synchash.Temporary_Media.SyncRoot -ScriptBlock {
              $index = Get-IndexesOf $synchash.Temporary_Media.$Property -Value $_
              if($index -ne $Null -and $index -ne -1){
                $synchash.Temporary_Media[$index]
              }
            }
          }
          #Is it Youtube history?
          #TODO: Dont really want to be calling an API for this every time, may just need to store more properties in history
          if(!$track -and !$SkipYTHistory -and $thisApp.Config.YoutubeHistory.count -gt 0){
            $YTID = $_
            $Youtube_Decoded = lock-object -InputObject $thisApp.Config.YoutubeHistory.SyncRoot -ScriptBlock {
              write-ezlogs ">>>> Checking Youtube History for id: $YTID" -LogLevel 0 -Verboselog:$Verboselog
              $index = Get-IndexesOf $thisApp.Config.YoutubeHistory -Value $YTID
              if($index -ne $Null -and $index -ne -1){
                $EncodedString = $thisApp.Config.YoutubeHistory[$index]
                try{
                  $bytes = [System.Convert]::FromBase64String($EncodedString)
                  $Decoded = [System.Text.Encoding]::UTF8.GetString($bytes)
                  if($Decoded){
                    return $Decoded
                  }
                }catch{
                  $Decoded = $Null
                } 
              }else{
                write-ezlogs "| Decoding all YoutubeHistory entries" -LogLevel 0 -Verboselog:$Verboselog
                $thisApp.Config.YoutubeHistory | & { process {
                    try{
                      $bytes = [System.Convert]::FromBase64String($_)
                      $Decoded = [System.Text.Encoding]::UTF8.GetString($bytes)
                      if($Decoded){                       
                        $id = ($Decoded -split '-,-')[0]
                        write-ezlogs "| ID: $id -- Decoded entry: $Decoded" -LogLevel 0 -Verboselog:$Verboselog
                      }
                    }catch{
                      $id = $Null
                    }                    
                    if($id -and $id -eq $YTID){
                      write-ezlogs "| Found id ($YTID) in decoded YT string: $Decoded" -LogLevel 0 -Verboselog:$Verboselog
                      $Decoded
                    }
                }}
              }
            }
            try{
              if($Youtube_Decoded){
                $id = ($Youtube_Decoded -split '-,-')[0]
                if($id){
                  $lookup = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_ID $id -SkipYTHistory
                }
                if($lookup){
                  return $lookup
                }else{
                  $url = ($Youtube_Decoded -split '-,-')[1]
                  $title = ($Youtube_Decoded -split '-,-')[2]
                  $Artist = ($Youtube_Decoded -split '-,-')[3]
                  $track = [Media]@{
                    'title' =  $title
                    'Artist' = $Artist
                    'id' = $id
                    'url' = $url
                    'Profile_Date_Added' = [DateTime]::Now.ToString()
                    'Source' = 'Youtube'
                  }
                }               
              }
            }catch{
              $track = $Null
            }
            <#            if($youtube_id){
                try{
                $video_info = Get-YouTubeVideo -Id $youtube_id
                }catch{
                write-ezlogs "An exception occurred executing Get-YoutubeVideo" -showtime -catcherror $_
                } 
            }#>
          }
          #Is it TOR
          if(!$track -and $synchash.All_Tor_Results.$Property){
            $track = lock-object -InputObject $synchash.All_Tor_Results.SyncRoot -ScriptBlock {
              $index = $synchash.All_Tor_Results.$Property.IndexOf($_)
              if($index -ne -1){
                $synchash.All_Tor_Results.item($index)
              }
            }
          }
          #Is it Current Playing Media
          if(!$track -and $synchash.Current_playing_media.$Property -and $synchash.Current_playing_media.$Property -eq $_){
            $track = $synchash.Current_playing_media
            write-ezlogs "[Get-MediaProfile] Queue item: $($_) is Current_playing_media: $($track.title)" -warning -LogLevel 0 -Verboselog:$Verboselog
          }
          if(!$track -and $thisapp.config.Current_Playing_Media.$Property -and $thisapp.config.Current_Playing_Media.$Property -eq $_){
            $track = $thisapp.config.Current_Playing_Media
            write-ezlogs "[Get-MediaProfile] Queue item: $($_) is Config.Current_playing_media: $($track.title)" -warning -LogLevel 0 -Verboselog:$Verboselog
          }
          if($track){
            return $track
          }elseif($Verboselog){
            write-ezlogs "Unable to find track for ID: $_" -warning
          }
        }catch{
          write-ezlogs "[Get-MediaProfile] An exception occurred in Get-MediaProfile for ID: $($_)" -catcherror $_
        }
    }}
    if($Get_MediaProfile_Measure){
      $Null = $Get_MediaProfile_Measure.Stop()
      write-ezlogs "Get-MediaProfile Measure" -Perf -PerfTimer $Get_MediaProfile_Measure
      $Get_MediaProfile_Measure = $Null
    }
  }
  if($use_Runspace){
    $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
    Start-Runspace -scriptblock $Get_MediaProfile_ScriptBlock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'Get_MediaProfile_RUNSPACE' -thisApp $thisApp -synchash $synchash
    $Variable_list = $Null
  }else{
    Invoke-Command -ScriptBlock $Get_MediaProfile_ScriptBlock
    $Get_MediaProfile_ScriptBlock = $Null
  }
}
#----------------------------------------------
#endregion Get-MediaProfile Function
#----------------------------------------------

#----------------------------------------------
#region Get-ProfileManager Function
#----------------------------------------------
function Get-ProfileManager{
  param (
    [Parameter(Position=0, Mandatory=$false, ValueFromPipeline=$true)]
    $thisApp,
    $synchash,
    $thisScript,
    [switch]$Startup,
    [switch]$shutdownWait,
    [switch]$StartupWait,
    [switch]$shutdown
  )
  if($startup){
    if(!$synchash.ProfileManager_Queue){
      $synchash.ProfileManager_Queue = [System.Collections.Concurrent.ConcurrentQueue`1[object]]::New()
    }
    $ProfileManager_ScriptBlock = {
      param (
        $thisApp = $thisApp,
        $synchash = $synchash,
        $thisScript = $thisScript,
        [switch]$Startup = $Startup,
        [switch]$shutdownWait = $shutdownWait,
        [switch]$StartupWait = $StartupWait,
        [switch]$shutdown = $shutdown
      )
      try{
        Import-module "$($thisApp.Config.Current_Folder)\Modules\Get-LocalMedia\Get-LocalMedia.psm1" -NoClobber -DisableNameChecking -Scope Local
        Import-Module "$($thisApp.Config.Current_Folder)\Modules\Remove-Media\Remove-Media.psm1" -NoClobber -DisableNameChecking -Scope Local
        $thisApp.ProfileManagerEnabled = $true
        $jobs = [System.WeakReference]::new($thisApp.Jobs.clone(),$false).Target
        $waithandle = $jobs[$($jobs.Name.IndexOf('ProfileManager_Runspace'))]
        $jobs = $Null
        do
        {
          try{
            $object = @{}
            $ProcessMessage = $synchash.ProfileManager_Queue.TryDequeue([ref]$object)
            if($ProcessMessage -and $object.ProcessObject){
              if($object.type -eq 'Local'){
                switch ($object.ActionType) {
                  'Created' {
                    [void]$waithandle.runspace.AsyncWaitHandle.WaitOne(100,$false)
                    Add-LocalMedia -synchash $synchash -thisApp $thisApp -Media $object -ImportMode 'Normal' -Directory $object.SourceDirectory -update_Library
                  }
                  'Deleted' {
                    [void]$waithandle.runspace.AsyncWaitHandle.WaitOne(250,$false)
                    Remove-Media -synchash $synchash -media_toRemove $object.Media -thisapp $thisApp -update_Library
                  }
                  'Renamed' {
                    [void]$waithandle.runspace.AsyncWaitHandle.WaitOne(250,$false)
                    Update-LocalMedia -synchash $synchash -UpdateMedia $object.Media -thisapp $thisApp -update_Library
                  }
                  'Changed' {
                    [void]$waithandle.runspace.AsyncWaitHandle.WaitOne(250,$false)
                    Update-LocalMedia -synchash $synchash -UpdateMedia $object.Media -thisapp $thisApp -update_Library
                  }
                }
              }
            }
            $object = $Null
            $ProcessMessage = $Null
          }catch{
            [System.Threading.Thread]::Sleep(500)
            write-ezlogs "[Get-ProfileManager] An exception occurred in ProfileManager_ScriptBlock while loop" -catcherror $_
          }finally{
            [void]$waithandle.runspace.AsyncWaitHandle.WaitOne(100,$false)
          }
        } while($thisApp.ProfileManagerEnabled)
        write-ezlogs "[Get-ProfileManager] ProfileManager has ended!" -warning
      }catch{
        write-ezlogs "[Get-ProfileManager] An exception occurred in ProfileManager_ScriptBlock" -catcherror $_
      }
    }
    Start-Runspace $ProfileManager_ScriptBlock -Variable_list $PSBoundParameters -StartRunspaceJobHandler -synchash $synchash -runspace_name "ProfileManager_Runspace" -thisApp $thisapp -CheckforExisting -RestrictedRunspace -function_list 'write-ezlogs' -PSProviders 'Function','Registry','Environment','FileSystem','Variable'
    if($StartupWait){
      while(!$synchash.ProfileManager_Queue -or !$thisApp.ProfileManagerEnabled){
        [System.Threading.Thread]::Sleep(100)
      }
    }
    $Variable_list = $Null
  }elseif($shutdown){
    if($shutdownWait){
      $WaitTimer = 0
      while(!$synchash.ProfileManager_Queue.IsEmpty -and $WaitTimer -lt 60){
        $WaitTimer++
        [System.Threading.Thread]::Sleep(1000)
      }
      if($WaitTimer -ge 60){
        write-ezlogs "[Get-ProfileManager] Shutdown for ProfileManager timedout -- ProfileManager_Queue is still not empty - Count: $($synchash.ProfileManager_Queue.count) -- will now be forced stopped!" -warning
      }
    }
    $thisApp.ProfileManagerEnabled = $false
  }
}
#----------------------------------------------
#endregion Get-ProfileManager Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-MediaProfile','Get-ProfileManager')