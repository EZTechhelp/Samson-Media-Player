<#
    .Name
    Add-Playlist

    .Version 
    0.1.0

    .SYNOPSIS
    Creates and adds tracks to playlists

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
#region Add-Playlist Function
#----------------------------------------------
function Add-Playlist
{
  Param (
    $Media,
    $Playlist,
    $thisApp,
    $Playlist_File_Path,
    $synchash,
    [switch]$Use_RunSpace,
    [switch]$Update_UI,
    [switch]$Startup,
    [switch]$ClearPlaylist,
    [switch]$Export_PlaylistsCache,
    [string]$Playlist_Profile_Directory = $thisApp.config.Playlist_Profile_Directory,
    [string]$Position,
    $PositionTargetMedia,
    [switch]$Verboselog
  )
  Add-Type -AssemblyName System.Web
  Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'PlayLists_Progress_Ring' -Property 'IsActive' -value $true
  $Add_Playlist_ScriptBlock ={
    param
    (
      $thisApp = $thisApp,
      $synchash = $synchash,
      $media = $media,
      $Use_RunSpace = $Use_RunSpace,
      $Playlist_Profile_Directory = $Playlist_Profile_Directory,
      $Playlist_File_Path = $Playlist_File_Path,
      $Startup = $Startup,
      $Export_PlaylistsCache = $Export_PlaylistsCache,
      $Update_UI = $Update_UI,
      $Playlist = $Playlist,
      $ClearPlaylist = $ClearPlaylist,
      $Position = $Position,
      $PositionTargetMedia = $PositionTargetMedia
    )
    write-ezlogs "#### Adding/Updating Playlist $Playlist ####" -linesbefore 1 -loglevel 2
    $illegalfile = "[™$([Regex]::Escape(-join [System.Io.Path]::GetInvalidFileNameChars()))]"
    if(!$Playlist_File_Path){
      if($Playlist -match $illegalfile){
        write-ezlogs " | Cleaning Playlist name due to illegal characters" -warning
        $Playlist = ([Regex]::Replace($Playlist, $illegalfile, '')).trim()
      }
      $Playlist_Path_Name = "$($Playlist)-CustomPlaylist.xml"    
      $Playlist_Directory_Path = [System.IO.Path]::Combine($Playlist_Profile_Directory,'Custom-Playlists')
      $Playlist_File_Path = [System.IO.Path]::Combine($Playlist_Directory_Path,$Playlist_Path_Name)
      <#      if(![System.IO.Directory]::Exists($Playlist_Directory_Path)){
          [void][System.IO.Directory]::CreateDirectory($Playlist_Directory_Path)
      }#>
    }
    if($synchash.all_playlists.name){
      $index = $synchash.all_playlists.name.indexof($Playlist)
    }
    if(-not [string]::IsNullOrEmpty($index) -and $index -ne -1){
      if($synchash.all_playlists -is [System.Windows.Data.CollectionView]){
        $Playlist_to_Update = $synchash.all_playlists.GetItemAt($index)
      }else{
        $Playlist_to_Update = $synchash.all_playlists[$index]
      } 
      write-ezlogs " | Updating existing playlist Profile for: $($Playlist_to_Update.name)" -showtime
    }else{
      write-ezlogs " | Playlist Profile not found...building new profile" -showtime -loglevel 2
      $Playlist_to_Update = [playlist]::new()
      $Playlist_encodedTitle = $Null
      $Playlist_to_Update.Playlist_Tracks = [SerializableDictionary[int,[Media]]]::new()
      $Playlist_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($Playlist)-CustomPlaylist")
      $Playlist_encodedTitle = [System.Convert]::ToBase64String($Playlist_encodedBytes)
      if($synchash.all_playlists.Playlist_id -notcontains $Playlist_encodedTitle){
        $Playlist_to_Update.Playlist_ID = $Playlist_encodedTitle
      }else{
        write-ezlogs "An existing playlist exists with id: $Playlist_encodedTitle -- generating new id" -warning
        $Playlist_encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$($Playlist)-$([Datetime]::now.ToString())")
        $Playlist_encodedTitle = [System.Convert]::ToBase64String($Playlist_encodedBytes)
        $Playlist_to_Update.Playlist_ID = $Playlist_encodedTitle
      }
      $Playlist_to_Update.name = $Playlist
      $Playlist_to_Update.Playlist_Date_Added = [Datetime]::now.ToString()
      $Playlist_to_Update.type = 'CustomPlaylist'
    }  
    if(-not [string]::IsNullOrEmpty($Playlist_to_Update.Playlist_ID) -and $Playlist){
      if($Position -and $Playlist_to_Update.Playlist_Tracks.values.id -contains $media.id -and $Playlist_to_Update.Playlist_Tracks.values.id -contains $PositionTargetMedia.id){
        #TODO: Hacky to ensure index and keys are in same order
        [array]$existingitems = $Playlist_to_Update.Playlist_Tracks.values
        $Count = 0
        [void]$Playlist_to_Update.Playlist_Tracks.clear()      
        $existingitems | & { process {
            [void]$Playlist_to_Update.Playlist_Tracks.add($Count,$_)
            $Count++
        }}
        write-ezlogs "| Getting destination dropindex of target: $($media.title) -- for position: $($Position)"
        $TargetIndex = $Playlist_to_Update.Playlist_Tracks.values.id.indexof($PositionTargetMedia.id)
        if(-not [string]::IsNullOrEmpty($TargetIndex) -and $TargetIndex -ne -1){
          write-ezlogs "| Targetindex: $TargetIndex"
          switch($Position)
          {
            'DropAbove' {
              if($TargetIndex -eq 0){
                $DropIndex = 0
              }else{
                $DropIndex = $TargetIndex - 1
              }
            }
            'DropBelow' {
              $DropIndex = $TargetIndex + 1
            }
            'DropHere' {
              $DropIndex = $TargetIndex
            }
          }
          write-ezlogs "| Destination dropindex: $DropIndex"
        }
        #Reorder
        try{
          if($Position -eq 'DropAbove'){
            [array]$existingitems = $Playlist_to_Update.Playlist_Tracks.values
            $Count = 0
            [void]$Playlist_to_Update.Playlist_Tracks.clear()
            $existingitems | & { process {
                if($Count -eq $DropIndex){
                  write-ezlogs "| Inserting media at position: $($Count) -- of target: $($media.title)"
                  [void]$Playlist_to_Update.Playlist_Tracks.add($Count,$media)
                  $Count++
                  if($_.id -notin $Playlist_to_Update.Playlist_Tracks.values.id){
                    write-ezlogs "| Inserting media: $($_.title) -- at position: $($Count)"
                    [void]$Playlist_to_Update.Playlist_Tracks.add($Count,$_)
                    $Count++
                  }
                }elseif($_.id -ne $media.id -and $_.id -notin $Playlist_to_Update.Playlist_Tracks.values.id){
                  write-ezlogs "| Inserting media: $($_.title) -- at position: $($Count)"
                  [void]$Playlist_to_Update.Playlist_Tracks.add($Count,$_)
                  $Count++
                }
            }}
          }
        }catch{
          write-ezlogs "An exception occurred reordering playlist track: $($media.title) -- TargetIndex: $TargetIndex -- DropIndex: $DropIndex -- Position: $Position" -CatchError $_
        }
      }else{
        if($ClearPlaylist -and $Playlist_to_Update.Playlist_Tracks){
          write-ezlogs "| Clearing existing playlist tracks for: $($Playlist_to_Update.name)"
          $Playlist_to_Update.PlayList_tracks.clear()
        }
        if($media){
          $index = ($Playlist_to_Update.PlayList_tracks.keys | Measure-Object -Maximum).Maximum
          if([string]::IsNullOrEmpty($index)){
            $index = 0
          }else{
            $index++
          }
          foreach($item in $media){
            try{
              if([string]::IsNullOrEmpty($item.id) -and -not [string]::IsNullOrEmpty($item)){
                $id = $item
              }else{
                $id = $item.id
              }
              if($id -and $Playlist_to_Update.PlayList_tracks.values.id -notcontains $id){
                if($item.Group -eq 'WebBrowser' -or $item.type -eq 'WebBrowser'){
                  $track = $item
                }elseif(!$item.id){
                  $track = Get-MediaProfile -thisApp $thisApp -synchash $synchash -Media_ID $id
                }else{
                  $track = $item
                }
                if($track){
                  if($track.title -match '---> '){
                    $track.title = $track.title -replace '---> '
                  }
                  if($track -isnot [Media]){
                    $track = Convertto-Media -InputObject $track
                  }
                  if($thisApp.Config.Dev_mode){write-ezlogs " | Adding '$($track.title)' to playlist '$($Playlist)' at index '$index'" -showtime -Dev_mode}
                  <#              if($Position -and -not [string]::IsNullOrEmpty($DropIndex)){
                      write-ezlogs "| Adding media at dropindex: $DropIndex"
                      [void]$Playlist_to_Update.PlayList_tracks.add($DropIndex,$track)
                      }else{
                      [void]$Playlist_to_Update.PlayList_tracks.add($index,$track)
                  }#>
                  [void]$Playlist_to_Update.PlayList_tracks.add($index,$track)
                  $index = ($Playlist_to_Update.PlayList_tracks.keys | Measure-Object -Maximum).Maximum
                  $index++
                }  
              }elseif($id){
                write-ezlogs " | Media with ID $($id) has already been added to playlist $($Playlist)" -showtime -warning
              }else{
                write-ezlogs " | Could not get id from item: $item) --- to add to playlist $($Playlist)" -showtime -warning
              }
            }catch{
              write-ezlogs "An exception occurred adding media: $($item) -- to playlist: $($Playlist_to_Update.Name)" -CatchError $_
            }                        
          }
        }
      }
      if($synchash.all_playlists.Playlist_id -notcontains $Playlist_to_Update.Playlist_ID){
        write-ezlogs ">>>> Adding new playlist: $($Playlist_to_Update.name) - to all playlists library"
        if($synchash.all_playlists -is [System.Windows.Data.CollectionView]){
          [void]$synchash.all_playlists.AddNewItem($Playlist_to_Update)
          [void]$synchash.all_playlists.CommitNew()
        }else{
          [void]$synchash.all_playlists.add($Playlist_to_Update)
        }
      }
      if($Export_PlaylistsCache){
        Export-SerializedXML -InputObject $synchash.All_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist -Force
      }
      if($Update_UI){
        Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace -Full_Refresh
      }else{
        Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'PlayLists_Progress_Ring' -Property 'IsActive' -value $false
      }
    }else{
      write-ezlogs "Could not find Playlist to update or no playlist to update was provided - playlist: $Playlist -- Playlist_to_Update: $($Playlist_to_Update | out-string)" -showtime -warning
      Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'PlayLists_Progress_Ring' -Property 'IsActive' -value $false
    }
  }
  if($use_Runspace){
    #$Variable_list = (Get-Variable -Scope Local) | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
    Start-Runspace -scriptblock $Add_Playlist_ScriptBlock -StartRunspaceJobHandler -Variable_list $PSBoundParameters -runspace_name 'Add_Playlist_RUNSPACE' -thisApp $thisApp -synchash $synchash -RestrictedRunspace -function_list write-ezlogs,Convertto-Media,Export-SerializedXML,Update-MainWindow,Get-MediaProfile,Get-Playlists
    #$Variable_list = $Null
  }else{
    Invoke-Command -ScriptBlock $Add_Playlist_ScriptBlock
    $Add_Playlist_ScriptBlock = $Null
  }
}
#---------------------------------------------- 
#endregion Add-Playlist Function
#----------------------------------------------
Export-ModuleMember -Function @('Add-Playlist')