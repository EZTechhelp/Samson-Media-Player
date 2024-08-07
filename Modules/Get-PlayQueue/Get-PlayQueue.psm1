<#
    .Name
    Get-PlayQueue

    .Version 
    0.1.0

    .SYNOPSIS
    Allows managing the Play Queue for Samson Media Player

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
#region Update-PlayQueue Function
#----------------------------------------------
function Update-PlayQueue
{
  [CmdletBinding()]
  param (
    [switch]$Clear,
    [switch]$Startup,
    [switch]$Remove,
    [switch]$UpdateHistory,
    [switch]$Use_RunSpace,
    [switch]$Add,
    [switch]$RefreshQueue,
    [switch]$SaveConfig,
    [switch]$UpdateItemssource,
    $itemssource,
    $media,
    $ID,
    $Add_First,
    $synchash,
    $thisApp,
    [switch]$VerboseLog
  )
  try{
    $Update_PlayQueue_ScriptBlock ={
      param (
        [switch]$Clear = $Clear,
        [switch]$Startup = $Startup,
        [switch]$Remove = $Remove,
        [switch]$UpdateHistory = $UpdateHistory,
        [switch]$Use_RunSpace = $Use_RunSpace,
        [switch]$Add = $Add,
        [switch]$RefreshQueue = $RefreshQueue,
        [switch]$SaveConfig = $SaveConfig,
        [switch]$UpdateItemssource = $UpdateItemssource,
        $itemssource = $itemssource,
        $media = $media,
        $ID = $id,
        $Add_First = $Add_First,
        $synchash = $synchash,
        $thisApp = $thisApp,
        [switch]$VerboseLog = $VerboseLog
      )
      try{       
        if($Startup){
          try{
            try{
              $synchash.Queue_Pause_relaycommand = New-RelayCommand -synchash $synchash -thisApp $thisApp -scriptblock $Synchash.PauseMedia_Command -target $synchash.PlayQueue_TreeView
            }catch{
              write-ezlogs "An exception occurred updating playqueue_treeview" -showtime -catcherror $_
            }
            #TODO: Finish for setting queue itemssource from another thread
            $synchash.PlayQueue_Update_Timer = [System.Windows.Threading.DispatcherTimer]::New([System.Windows.Threading.DispatcherPriority]::DataBind)
            $synchash.PlayQueue_Update_Timer.add_tick({
                try{        
                  if(-not [string]::IsNullOrEmpty($this.tag.Itemssource) -or $this.tag.UpdateItemssource){
                    if($syncHash.PlayQueue_TreeView){
                      if($syncHash.PlayQueue_TreeView.itemssource.IsInUse){
                        [void]$syncHash.PlayQueue_TreeView.itemssource.DetachFromSourceCollection()
                      }
                      $syncHash.PlayQueue_TreeView.itemssource = $null
                      if($this.tag.Itemssource.count -gt 0){
                        $syncHash.PlayQueue_TreeView.itemssource = [System.Windows.Data.CollectionViewSource]::GetDefaultView($this.tag.Itemssource)
                      }
                    }else{
                      write-ezlogs "No PlayQueue_TreeView UI is available" -warning
                    }
                  }else{
                    write-ezlogs "No PlayQueue itemssource was provided or is empty" -warning
                    if(!$syncHash.PlayQueue_TreeView){
                      write-ezlogs "No PlayQueue_TreeView UI is available" -warning
                    }
                  }                                                       
                  $this.Stop()
                }catch{
                  write-ezlogs "An exception occurred in PlayQueue_Update_Timer.add_tick" -showtime -catcherror $_
                }finally{
                  $this.Stop()
                  $this.tag = $Null
                  Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'PlayQueue_Progress_Ring' -Property 'IsActive' -value $false
                }
            }) 
            return
          }catch{
            write-ezlogs "An exception occurred in Update-PlayQueue startup" -showtime -catcherror $_
          }
        }elseif($itemssource -or $UpdateItemssource){
          $synchash.PlayQueue_Update_Timer.tag = [PSCustomObject]@{
            'Itemssource' = $itemssource
            'UpdateItemssource' = $UpdateItemssource
          }
          $synchash.PlayQueue_Update_Timer.start()
          return     
        }
        if($Remove){
          try{
            if($media){
              write-ezlogs ">>>> Removing $($media.count) media from play queue"
              foreach($m in $media){
                if([string]::IsNullOrEmpty($m.id) -and -not [string]::IsNullOrEmpty($m)){
                  $id = $m
                }else{
                  $id = $m.id
                }
                if($thisApp.config.Current_Playlist.values -contains $id){
                  $index_toremove = $thisApp.config.Current_Playlist.GetEnumerator().where({$_.value -eq $id}) | Select-Object * -ExpandProperty key 
                  if(($index_toremove).count -gt 1){
                    write-ezlogs "| Found multiple items in Play Queue to remove matching id $($id) - $($index_toremove)" -showtime -warning -LogLevel 2
                    foreach($index in $index_toremove){
                      [void]$thisApp.config.Current_Playlist.Remove($index) 
                    }  
                  }else{
                    if($thisApp.Config.Dev_mode){write-ezlogs "| Removing $($id) from Play Queue" -showtime -LogLevel 2 -Dev_mode}
                    [void]$thisApp.config.Current_Playlist.Remove($index_toremove)
                  } 
                }
                #Temporary Queue
                if($synchash.Temporary_Media.id -contains $id){
                  $index_toremove = $synchash.Temporary_Media.id.IndexOf($id)
                  if(($index_toremove).count -gt 1){
                    write-ezlogs "| Found multiple items in Temporary Play Queue to remove matching id $($id) - $($index_toremove)" -showtime -warning -LogLevel 2
                    foreach($index in $index_toremove){
                      [void]$synchash.Temporary_Media.RemoveAt($index_toremove)
                    }  
                  }else{
                    if($thisApp.Config.Dev_mode){write-ezlogs "| Removing $($id) from Temporary Play Queue" -showtime -LogLevel 2 -Dev_mode}
                    [void]$synchash.Temporary_Media.RemoveAt($index_toremove)
                  } 
                }
              }
            }elseif($id){
              foreach($i in $id){
                if($thisApp.config.Current_Playlist.values -contains $i){
                  $index_toremove = $thisApp.config.Current_Playlist.GetEnumerator().where({$_.value -eq $i}) | Select-Object * -ExpandProperty key 
                  if(($index_toremove).count -gt 1){
                    write-ezlogs "| Found multiple items to remove in Play Queue matching id $($i) - index_toremove: $($index_toremove)" -showtime -warning -LogLevel 2
                    foreach($index in $index_toremove){
                      [void]$thisApp.config.Current_Playlist.Remove($index) 
                    }  
                  }elseif(-not [string]::IsNullOrEmpty($index_toremove)){
                    if($thisApp.Config.Dev_mode){write-ezlogs "| Removing $($i) with index $index_toremove from Play Queue" -showtime -LogLevel 2 -Dev_mode}
                    [void]$thisApp.config.Current_Playlist.Remove($index_toremove)
                  }else{
                    write-ezlogs "| Could not find index $index_toremove to remove from queue for id - $($i)" -warning
                  } 
                }
                #Temporary Queue
                if($synchash.Temporary_Media.id -contains $i){
                  $index_toremove = $synchash.Temporary_Media.id.IndexOf($i)
                  if(($index_toremove).count -gt 1){
                    write-ezlogs "| Found multiple items in Temporary Play Queue to remove matching id $($i) - $($index_toremove)" -showtime -warning -LogLevel 2
                    foreach($index in $index_toremove){
                      [void]$synchash.Temporary_Media.RemoveAt($index_toremove)
                    }  
                  }else{
                    if($thisApp.Config.Dev_mode){write-ezlogs "| Removing $($i) from Temporary Play Queue" -showtime -LogLevel 2 -Dev_mode}
                    [void]$synchash.Temporary_Media.RemoveAt($index_toremove)
                  } 
                }
              }
            }
            if($thisApp.config.Current_Playlist.count -gt 0){
              write-ezlogs " | Reordering play queue"
              [array]$existingitems = $thisapp.config.Current_Playlist.values
              [void]$thisApp.config.Current_Playlist.clear()
              $Count = 0
              $existingitems | & { process {
                  [void]$thisapp.config.Current_Playlist.add($Count,$_)
                  $Count++
              }}
            }
          }catch{
            write-ezlogs "An exception occurred removing item from play queue -- Media: $($media | out-string) -- id: $($id)" -showtime -catcherror $_
          }                          
        }
        if($Add){
          try{
            $Add_ToPlayQueue_Measure = [system.diagnostics.stopwatch]::StartNew() 
            Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'PlayQueue_Progress_Ring' -Property 'IsActive' -value $true
            Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'PlayQueue_TreeView' -Property 'AllowDrop' -value $false
            Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'PlayQueue_TreeView_Library' -Property 'AllowDrop' -value $false
            Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'VideoView_Queue' -Property 'AllowDrop' -value $false       
            if($Add_First){
              #[array]$existingitems = $Sorted.values
              [array]$existingitems = $thisapp.config.Current_Playlist.values
              [void]$thisApp.config.Current_Playlist.clear()
              $index = 0
              write-ezlogs "[Update-PlayQueue] | Adding '$($Add_First)' to first position in the Play Queue - existingitems: $($existingitems.count)" -showtime
              [void]$thisApp.config.Current_Playlist.add($index,$Add_First)
              foreach($id in $existingitems){
                if($id -ne $Add_First){
                  $getbyindex = $thisapp.config.Current_Playlist.count
                  if($getbyindex -gt 0){
                    $getbyindex--
                    #$index = $Sorted.GetKey($getbyindex)
                    $index = $getbyindex
                    $index++
                  }else{
                    $index = 0
                  } 
                  [void]$thisApp.config.Current_Playlist.add($index,$id)
                }
              }         
            }else{
              #$Sorted = [System.Collections.SortedList]::new($thisapp.config.Current_Playlist)
              [array]$existingitems = $thisapp.config.Current_Playlist.values
              [void]$thisApp.config.Current_Playlist.clear()
              $Count = 0
              $existingitems | & { process {
                  [void]$thisapp.config.Current_Playlist.add($Count,$_)
                  $Count++
              }}
            }
            if($media){
              foreach($m in $media){
                try{
                  if([string]::IsNullOrEmpty($m.id) -and -not [string]::IsNullOrEmpty($m)){
                    $id = $m
                  }else{
                    $id = $m.id
                  }
                  if($id -ne $Null -and $thisapp.config.Current_Playlist.values -notcontains $id){
                    $getbyindex = $thisapp.config.Current_Playlist.count
                    if($getbyindex -gt 0){
                      $getbyindex--
                      if($thisapp.config.Current_Playlist.ContainsKey($getbyindex)){
                        #$index = $Sorted.GetKey($getbyindex)
                        $index = $getbyindex
                        $index++
                      }else{
                        $index++
                      }
                    }else{
                      $index = 0
                    }
                    #$index = $thisapp.config.Current_Playlist.keys | select -last 1
                    #$index = ($thisapp.config.Current_Playlist.keys | measure -Maximum).Maximum
                    if($thisApp.Config.Dev_mode){write-ezlogs "[Update-PlayQueue] | Adding item: $($m.title) -- ID: ($($id)) to Play Queue - index: $index" -showtime -Dev_mode}
                    [void]$thisapp.config.Current_Playlist.add($index,$id)
                  }else{
                    write-ezlogs "[Update-PlayQueue] Queue already contains item: $($m) -- ID: ($($id))" -showtime -dev_mode
                  } 
                }catch{
                  write-ezlogs "[Update-PlayQueue] An exception occurred adding item to play queue -- -- media.title: $($m.title) -- media.url: $($m.url) -- id: $($id) - index: $index - getbyindex: $($getbyindex) - current_playlist keys: $($thisapp.config.Current_Playlist.keys)" -showtime -catcherror $_
                }
              }
              write-ezlogs "[Update-PlayQueue] >>>> Added $($media.count) items to play queue - last index: $($index)"
            }elseif($id){
              if($thisapp.config.Current_Playlist.values -notcontains $id){
                $getbyindex = $thisapp.config.Current_Playlist.count
                if($getbyindex -gt 0){
                  $getbyindex--
                  if($thisapp.config.Current_Playlist.ContainsKey($getbyindex)){
                    $index = $getbyindex
                    $index++
                  }else{
                    $index++
                  }
                }else{
                  $index = 0
                }
                [void]$thisapp.config.Current_Playlist.add($index,$id)
                if($thisApp.Config.Dev_mode){write-ezlogs "[Update-PlayQueue] | Adding item: $($m.title) by ID: ($($id)) to Play Queue - index: $index" -showtime -Dev_mode}         
              }
              write-ezlogs "[Update-PlayQueue] >>>> Added $($id.count) items by id to play queue - last index: $($index)" 
            }
            #TODO: This is terrible and hacky, real solution is to make Current_Playlist use OrderedDictionary (will need to be custom class to make it serializable)
            if($thisapp.config.Current_Playlist.values -and ($thisapp.config.Current_Playlist.Keys | select-Object -First 1) -ne 0){
              write-ezlogs "[Update-PlayQueue] | Queue seems to be out of order, Re-sorting by key number" -warning
              $Sorted = [System.Collections.SortedList]::new($thisapp.config.Current_Playlist)
              [void]$thisApp.config.Current_Playlist.clear()
              $sorted.keys | & { process {
                  [void]$thisapp.config.Current_Playlist.add($_,$($sorted.Item($_)))
              }}
            }            
            $Add_ToPlayQueue_Measure.stop()
            write-ezlogs "Update-PlayQueue -Add Measure" -Perf -PerfTimer $Add_ToPlayQueue_Measure
            $Add_ToPlayQueue_Measure = $Null                           
          }catch{
            write-ezlogs "[Update-PlayQueue] An exception occurred adding item to play queue -- media.title: $($media.title) -- media.url: $($media.url) -- id: $($id) - index: $index" -showtime -catcherror $_
          }finally{
            if($synchash.PlayQueue_Progress_Ring){
              Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'PlayQueue_Progress_Ring' -Property 'IsActive' -value $false
            }   
          }                         
        }
        if($UpdateHistory){ 
          #Update History Playlist  
          if(!$thisApp.config.History_Playlist){
            $thisApp.Config.psobject.properties.add([System.Management.Automation.PSNoteProperty]::new('History_Playlist',([SerializableDictionary[int,string]]::new())))
          }
          $historymeasure = ($thisApp.config.History_Playlist.keys | Measure-Object -Maximum -Minimum)
          foreach($i in $id){
            if($thisApp.config.History_Playlist.ContainsValue($i)){
              $CurrentIndex = (($thisApp.config.History_Playlist.GetEnumerator()) | Where-Object {$_.value -eq $i}).key
              if($CurrentIndex -ne $Null){
                [void]$thisapp.config.History_Playlist.Remove($CurrentIndex)
              }
            }
            if($thisApp.config.History_Playlist.values -notcontains $i){
              if($historymeasure.count -gt 10){
                write-ezlogs "[Update-PlayQueue] | History playlist at or over maximum clearing all history" -LogLevel 2 -warning
                [void]$thisApp.config.History_Playlist.clear()
              }elseif($historymeasure.count -eq 10){
                $historyindex_toremove = $historymeasure.Minimum
                #$historyindex_toremove = $thisapp.config.History_Playlist.GetEnumerator() | Select-Object -First 1
                write-ezlogs "[Update-PlayQueue] | History playlist at maximum, dropping oldest index: $($historyindex_toremove)" -LogLevel 2
                [void]$thisapp.config.History_Playlist.Remove($historyindex_toremove)
              }
              $historyindex = $historymeasure.Maximum
              $historyindex++
              write-ezlogs "[Update-PlayQueue] | Adding $($i) to Play history" -showtime
              [void]$thisApp.config.History_Playlist.add($historyindex,$i)
              [Media]$MediatoUpdate = Get-MediaProfile -synchash $synchash -thisApp $thisApp -Media_ID $i
              if($MediatoUpdate){
                $UpdateTimesPlayed = $MediatoUpdate.TimesPlayed + 1
                write-ezlogs "Updating play count for $($MediatoUpdate.title) from $($MediatoUpdate.TimesPlayed) to $($UpdateTimesPlayed)"
                $MediatoUpdate.TimesPlayed = $UpdateTimesPlayed
              }
            }
          }
          if($synchash.jumplist){
            try{
              write-ezlogs "[Update-PlayQueue] | Refreshing Jumplist history" -showtime
              Add-JumpList -thisApp $thisApp -synchash $synchash -Use_Runspace
            }catch{
              write-ezlogs "An exception occurred refreshing Jumplist history" -catcherror $_
            }
          }
        }
        if($SaveConfig){
          write-ezlogs ">>>> Saving confile file to path: $($thisapp.Config.Config_Path)"
          Export-SerializedXML -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -isConfig
        }
        if($RefreshQueue){  
          write-ezlogs "| Refreshing play queue" 
          Get-PlayQueue -verboselog:$false -synchashWeak ([System.WeakReference]::new($synchash)) -thisApp $thisapp -use_Runspace
        }else{
          Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'PlayQueue_Progress_Ring' -Property 'IsActive' -value $false
        }
      }catch{
        write-ezlogs "[Update-PlayQueue] An exception occurred in Update_PlayQueue_ScriptBlock" -catcherror $_
      }finally{
        Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'PlayQueue_TreeView' -Property 'AllowDrop' -value $true
        Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'PlayQueue_TreeView_Library' -Property 'AllowDrop' -value $true
        Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'VideoView_Queue' -Property 'AllowDrop' -value $true
      }
    }
    if($use_Runspace){
      Start-Runspace -scriptblock $Update_PlayQueue_ScriptBlock -StartRunspaceJobHandler -Variable_list $PSBoundParameters -runspace_name 'Update_PlayQueue_RUNSPACE' -thisApp $thisApp -synchash $synchash -RestrictedRunspace -function_list 'write-ezlogs','Get-PlayQueue','Update-MainWindow','Export-SerializedXML','Add-JumpList','Get-MediaProfile' -CheckforExisting -AlertUIWarnings
      $Update_PlayQueue_ScriptBlock = $null
    }else{
      Invoke-Command -ScriptBlock $Update_PlayQueue_ScriptBlock
      $Update_PlayQueue_ScriptBlock = $null
    }  
  }catch{
    write-ezlogs "An exception occurred in Update-PlayQueue" -showtime -catcherror $_
  } 
}
#---------------------------------------------- 
#endregion Update-PlayQueue Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-PlayQueue Function
#----------------------------------------------
function Get-PlayQueue
{
  [CmdletBinding()]
  param (
    [switch]$Clear,
    [switch]$Startup,
    [switch]$use_Runspace,
    $synchashWeak,
    $thisApp,
    $Group,
    $thisScript,
    [switch]$VerboseLog,
    [switch]$Export_Config,
    [switch]$Import_Playlists_Cache
  )
  if($Verboselog){write-ezlogs "#### Executing Get-PlayQueue ####" -enablelogs -color yellow -linesbefore 1}
  try{
    if($use_Runspace){
      try{
        $existing_Runspace = Stop-Runspace -thisApp $thisApp -runspace_name 'Get_PlayQueue_RUNSPACE' -check
        if($existing_Runspace){
          write-ezlogs "Get-PlayQueue runspace already exists, halting another execution to avoid a race condition" -warning -Dev_mode
          return
        }
      }catch{
        write-ezlogs " An exception occurred checking for existing runspace 'Get_PlayQueue_RUNSPACE'" -showtime -catcherror $_
      }
    }
    Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -control 'PlayQueue_Progress_Ring' -Property 'IsActive' -value $true
    Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -control 'PlayQueue_TreeView' -Property 'AllowDrop' -value $false
    Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -control 'PlayQueue_TreeView_Library' -Property 'AllowDrop' -value $false
    Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -control 'VideoView_Queue' -Property 'AllowDrop' -value $false 
    if(!$synchashWeak.Target.Get_PlayQueue_ScriptBlock){
      $synchashWeak.Target.Get_PlayQueue_ScriptBlock = {
        param (
          [switch]$Clear,
          [switch]$Startup,
          [switch]$use_Runspace,
          $synchashWeak,
          $thisApp,
          $Group,
          $thisScript,
          [switch]$VerboseLog,
          [switch]$Export_Config,
          [switch]$Import_Playlists_Cache
        )
        try{
          $Get_PlayQueue_Measure = [system.diagnostics.stopwatch]::StartNew()
          if($Export_Config){
            try{
              write-ezlogs ">>>> Exporting config to: $($thisapp.Config.Config_Path)" -showtime
              Export-SerializedXML -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -isConfig
            }catch{
              write-ezlogs "An exception occurred exporting config file to $($thisapp.Config.Config_Path)" -showtime -catcherror $_
            }
          }
          if($Import_Playlists_Cache -and !$synchashWeak.Target.all_playlists){
            try{
              $existing_Runspace = Stop-Runspace -thisApp $thisApp -runspace_name 'Get_Playlists_RUNSPACE' -check
            }catch{
              write-ezlogs "An exception occurred checking for existing runspace 'Get_Playlists_RUNSPACE'" -showtime -catcherror $_
            }
            if(!$existing_Runspace){
              try{
                if(([System.IO.File]::Exists($thisApp.Config.Playlists_Profile_Path))){
                  write-ezlogs ">>>> Importing All_Playlists_Profile from: $($thisApp.Config.Playlists_Profile_Path)" -showtime
                  $synchashWeak.Target.all_playlists = Import-SerializedXML -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist
                }else{
                  write-ezlogs "Unable to find All playlists cache" -showtime -warning
                }
              }catch{
                write-ezlogs "An exception occurred importing playlists cache" -showtime -catcherror $_
              }
            }else{
              $WaitTimeout = 0
              write-ezlogs "[Get-PlayQueue] Get-Playlists is running, waiting briefly until it finishes..." -warning
              while(![bool]($synchashWeak.Target.all_playlists -isnot [System.Collections.ObjectModel.ObservableCollection[playlist]]) -and $WaitTimeout -lt 100){
                $WaitTimeout++
                [System.Threading.Thread]::Sleep(100)
              }
              write-ezlogs ">>>> Continuing execution of Get-PlayQueue - waittimeout: $WaitTimeout"
            }
          }
          $queued_items_toremove = [System.Collections.Generic.List[object]]::new()
          $all = [System.Collections.Generic.List[object]]::new()
          $HardDiskIcon = [string]::Intern("$($thisApp.Config.Current_Folder)\Resources\Images\Material-Harddisk.png")
          $YoutubeIcon = [string]::Intern("$($thisApp.Config.Current_Folder)\Resources\Images\Material-Youtube.png")
          $SpotifyIcon = [string]::Intern("$($thisApp.Config.Current_Folder)\Resources\Images\Material-Spotify.png")
          $TwitchIcon = [string]::Intern("$($thisApp.Config.Current_Folder)\Resources\Images\Material-Twitch.png")
          $YoutubeTVIcon = [string]::Intern("$($thisApp.Config.Current_Folder)\Resources\Images\Material-Youtubetv.png")
          $TorIcon = [string]::Intern("$($thisApp.Config.Current_Folder)\Resources\Images\Material-Pirate.png")
          $SoundcloudIcon = [string]::Intern("$($thisApp.Config.Current_Folder)\Resources\Images\Material-Soundcloud.png")
          if($thisApp.config.Current_Playlist.values){
            try{
              #Clone to prevent errors during long enumerations
              [array]$AllPlayQueue = lock-object -InputObject $thisApp.config.Current_Playlist.SyncRoot -ScriptBlock {
                #[System.WeakReference]::new($thisapp.config.Current_Playlist)
                $thisapp.config.Current_Playlist.keys
              }
            }catch{
              write-ezlogs "[Get-PlayQueue] An exception occurred cloning current_playlist" -catcherror $_
            }finally{
              if(!$AllPlayQueue -and $thisapp.config.Current_Playlist.keys){
                #$AllPlayQueueWeak = [System.WeakReference]::new($thisapp.config.Current_Playlist.keys)
                [array]$AllPlayQueue = $thisapp.config.Current_Playlist.keys
              }
            }
            $AllPlayQueue | & { process {
                try{
                  if(-not [string]::IsNullOrEmpty($_)){
                    try{
                      $item = $thisapp.config.Current_Playlist.$_
                    }catch{
                      $item = $Null
                    }
                    if(!$item){
                      try{
                        $item = $thisapp.config.Current_Playlist.Item($_)
                      }catch{
                        $item = $Null
                      }
                    }
                    if(!$item){
                      try{
                        $item = $thisapp.config.Current_Playlist.Item([double]$_)
                      }catch{
                        $item = $Null
                      }
                    }
                    if(!$item){
                      try{
                        $item = $thisapp.config.Current_Playlist[$_]
                      }catch{
                        $item = $Null
                      }
                    }
                    if(!$item){
                      try{
                        $item = ($thisapp.config.Current_Playlist.GetEnumerator().where{$_.key -eq "$_"}).value
                      }catch{
                        $item = $Null
                      }
                    }
                    if(!$item){
                      write-ezlogs "Failed to lookup item in the queue with key: $($_)" -warning
                      [void]$queued_items_toremove.add($_)
                    }else{
                      $Track = Get-MediaProfile -thisApp $thisApp -synchash $synchashWeak.Target -Media_ID $item
                      if(!$Track -and $synchashWeak.Target.Temporary_Media.id -contains $item){
                        $Track = lock-object -InputObject $synchashWeak.Target.Temporary_Media.SyncRoot -ScriptBlock {
                          $i = Get-IndexesOf $synchashWeak.Target.Temporary_Media.id -Value $item
                          if($i -ne -1 -and $i -ne $Null){
                            $synchashWeak.Target.Temporary_Media[$i]
                          }
                        }
                      }
                      if($Track.Source -eq 'Spotify' -or $Track.uri -match 'spotify\:' -or $track.url -eq 'spotify\:'){
                        if($Track.Artist){
                          $artist = $Track.Artist
                        }else{
                          $artist = $Track.Artist_Name
                        }
                        $track_name = $track.title
                        $Title = "$($artist) - $($track_name)"
                        if($thisApp.Config.Verbose_logging){write-ezlogs "[Get-PlayQueue] | Found Spotify Track Title: $($Title) " -showtime}
                        $icon_path = $SpotifyIcon
                      }elseif($Track.url -match 'twitch\.tv'){
                        $Title = "$($Track.Title)"
                        if($thisApp.Config.Verbose_logging){write-ezlogs "[Get-PlayQueue] | Found Twitch Track Title: $($Title) " -showtime}
                        if($Track.profile_image_url){
                          if($thisApp.Config.Verbose_logging){write-ezlogs "[Get-PlayQueue] | Media Image found: $($Track.profile_image_url)" -showtime}       
                          if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
                            if($thisApp.Config.Verbose_logging){write-ezlogs "[Get-PlayQueue] | Creating image cache directory: $($thisApp.config.image_Cache_path)" -showtime}
                            [void][System.IO.Directory]::CreateDirectory($thisApp.config.image_Cache_path)
                          }
                          $encodeduri = $Null
                          $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$([System.Uri]::new($Track.profile_image_url).Segments | Select-Object -last 1)-Twitch")
                          $encodeduri = [System.Convert]::ToBase64String($encodedBytes)
                          $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),"$($encodeduri).png")
                          if([System.IO.File]::Exists($image_Cache_path)){
                            $cached_image = $image_Cache_path
                          }elseif($Track.profile_image_url){         
                            if($thisApp.Config.Verbose_logging){write-ezlogs "[Get-PlayQueue] | Destination path for cached image: $image_Cache_path" -showtime}
                            $retry = $false
                            if(!([System.IO.File]::Exists($image_Cache_path))){
                              try{
                                if([System.IO.File]::Exists($Track.profile_image_url)){
                                  if($thisApp.Config.Dev_mode){write-ezlogs "[Get-PlayQueue] | Cached Image not found, copying image $($Track.profile_image_url) to cache path $image_Cache_path"  -showtime -Dev_mode -logtype Twitch}
                                  [void][System.IO.File]::Copy($Track.profile_image_url,$image_Cache_path,$true)
                                }elseif((Test-URL $Track.profile_image_url)){
                                  $uri = [system.uri]::new($Track.profile_image_url)
                                  write-ezlogs "[Get-PlayQueue] | Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -showtime -LogLevel 3 -logtype Twitch
                                  try{
                                    $webclient = [System.Net.WebClient]::new()
                                    [void]$webclient.DownloadFile($uri,$image_Cache_path)
                                    $retry = $false
                                  }catch{
                                    write-ezlogs "[Get-PlayQueue] An exception occurred downloading image $uri to path $image_Cache_path" -showtime -catcherror $_
                                    $retry = $true
                                  }finally{
                                    if($webclient){
                                      $webclient.Dispose()
                                      $webclient = $Null
                                    }
                                  }
                                  if($retry -and $Track.Artist){
                                    try{
                                      write-ezlogs "[Get-PlayQueue] >>>> Checking Twitch API for possible updated profile_image_url for streamer: $($Track.Artist)" -showtime -warning -LogLevel 2 -logtype Twitch
                                      $TwitchData = Get-TwitchAPI -StreamName $Track.Artist -thisApp $thisApp
                                    }catch{
                                      write-ezlogs "[Get-PlayQueue] An exception occurred executing Get-TwitchAPI for steamname $($Track.Artist)" -showtime -catcherror $_
                                    }
                                    if((Test-URL $TwitchData.profile_image_url)){
                                      try{
                                        write-ezlogs "[Get-PlayQueue] | Trying again with newly retrieved profile_image url $($TwitchData.profile_image_url)" -showtime -LogLevel 2 -logtype Twitch
                                        $webclient = [System.Net.WebClient]::new()
                                        [void]$webclient.DownloadFile($TwitchData.profile_image_url,$image_Cache_path)
                                      }catch{
                                        write-ezlogs "[Get-PlayQueue] An exception occurred downloading image $($TwitchData.profile_image_url) to path $image_Cache_path" -showtime -catcherror $_
                                      }finally{
                                        if($webclient){
                                          $webclient.Dispose()
                                          $webclient = $Null
                                        }
                                      }
                                      $Track.profile_image_url = $TwitchData.profile_image_url
                                      Update-Playlist -media $Track -synchash $synchashWeak.Target -thisApp $thisApp -Updateall -use_Runspace
                                    }
                                  }
                                }
                                if([System.IO.File]::Exists($image_Cache_path)){
                                  $stream_image = [System.IO.File]::OpenRead($image_Cache_path)
                                  $image = [System.Windows.Media.Imaging.BitmapImage]::new()
                                  $image.BeginInit()
                                  $image.CacheOption = "OnLoad"
                                  $image.DecodePixelWidth = 20
                                  $image.StreamSource = $stream_image
                                  $image.EndInit()   
                                  $stream_image.Close()
                                  $stream_image.Dispose()
                                  $stream_image = $null
                                  $cached_image = $image
                                  $image.Freeze()
                                  if($thisApp.Config.Dev_mode){write-ezlogs "[Get-PlayQueue] Saving decoded media image to path $image_Cache_path" -showtime -Dev_mode -logtype Twitch}
                                  $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
                                  $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($cached_image))
                                  $save_stream = [System.IO.FileStream]::new("$image_Cache_path",'Create')
                                  $encoder.Save($save_stream)
                                  $save_stream.Dispose()
                                  $save_stream = $Null
                                  $encoder = $Null
                                }else{
                                  write-ezlogs "[Get-PlayQueue] Unable to download or find valid image to cache to $image_Cache_path" -showtime -warning -LogLevel 3 -logtype Twitch
                                }
                              }catch{
                                $cached_image = $Null
                                write-ezlogs "[Get-PlayQueue] An exception occurred attempting to download $uri to path $image_Cache_path for $($Track | out-string)" -showtime -catcherror $_
                              }
                            }
                          }else{
                            write-ezlogs "[Get-PlayQueue] Cannot Download image $image to cache path $image_Cache_path - URL is invalid" -enablelogs -showtime -warning
                            $cached_image = $Null        
                          }
                        }
                        if($cached_image){
                          $icon_path = $cached_image
                        }else{
                          $icon_path = $TwitchIcon
                        }
                      }elseif($track.url -match 'soundcloud\.com'){
                        $Title = "$($Track.Title)"
                        if($thisApp.Config.Verbose_logging){write-ezlogs "[Get-PlayQueue] | Found SoundCloud Track Title: $($Title) " -showtime -LogLevel 3 -logtype Youtube}
                        $icon_path = $SoundcloudIcon
                      }elseif($Track.type -match 'Youtube' -or $track.source -eq 'Youtube' -or $track.url -match 'youtube\.com' -or $track.url -match 'youtu\.be'){
                        $Title = "$($Track.Title)"
                        if($thisApp.Config.Verbose_logging){write-ezlogs "[Get-PlayQueue] | Found Youtube Track Title: $($Title) " -showtime -logtype Youtube -loglevel 3}
                        if($track.url -match 'tv\.youtube'){
                          $icon_path = $YoutubeTVIcon
                        }else{
                          $icon_path = $YoutubeIcon
                        }
                      }elseif($Track.source -eq 'TOR'){
                        $Title = "$($Track.Title)"
                        $icon_path = $TorIcon
                      }elseif($Track.Artist -and $Track.Title){
                        $Title = "$($Track.Artist) - $($Track.Title)"
                        if($thisApp.Config.Verbose_logging){write-ezlogs "[Get-PlayQueue] | Found Track Artist and Title: $($Title) " -showtime }
                        $icon_path = $HardDiskIcon
                      }elseif($Track.Title){
                        if($thisApp.Config.Verbose_logging){write-ezlogs "[Get-PlayQueue] | Found Track Title: $($Track.Title) " -showtime }
                        $Title = "$($Track.Title)"
                        $icon_path = $HardDiskIcon
                      }elseif($Track.Name){
                        if($thisApp.Config.Verbose_logging){write-ezlogs "[Get-PlayQueue] | Found Track Name: $($Track.Name) " -showtime }
                        if(!$Track.Artist -and [System.IO.Directory]::Exists($Track.directory)){
                          try{
                            $artist = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase(([System.IO.Path]::GetFileNameWithoutExtension($Track.directory))).trim()
                          }catch{
                            write-ezlogs "[Get-PlayQueue] An exception occurred getting file name without extension for $($Track.directory)" -showtime -catcherror $_
                            $artist = ''
                          }
                          if($thisApp.Config.Verbose_logging){write-ezlogs "[Get-PlayQueue] | Using Directory name for artist: $($artist) " -showtime }
                        }elseif($Track.Artist){
                          $artist = $Track.Artist
                          if($thisApp.Config.Verbose_logging){write-ezlogs "[Get-PlayQueue] | Found Track Name artist: $($artist) " -showtime }
                        }
                        if(-not [string]::IsNullOrEmpty($artist)){
                          $Title = "$($artist) - $($Track.Name)"
                        }else{
                          $Title = "$($Track.Name)"
                        }
                        $icon_path = $HardDiskIcon
                      }else{
                        $title = $null
                        write-ezlogs "[Get-PlayQueue] Can't find type or title for track: $($track) - Key: $($_) - id: $($item)" -showtime -warning
                      }
                      if(-not [string]::IsNullOrEmpty($track.Display_Name)){
                        $Display_Name = $track.Display_Name
                      }else{
                        $Display_Name = $title
                      }
                      if(-not [string]::IsNullOrEmpty($Track.id) -and -not [string]::IsNullOrEmpty($Title)){
                        if($Track.live_status -eq 'Offline'){
                          $fontstyle = 'Italic'
                          $fontcolor = 'Gray'
                          $FontWeight = 'Normal'
                          $FontSize = [Double]'12'
                        }elseif($Track.live_status -eq 'Online' -or $Track.live_status -eq 'Live'){
                          $fontstyle = 'Normal'
                          $fontcolor = 'LightGreen'
                          $FontWeight = 'Normal'
                          $FontSize = [Double]'12'
                        }else{
                          $fontstyle = 'Italic'
                          $fontcolor = 'White'
                          $FontWeight = 'Normal'
                          $FontSize = [Double]'12'
                        }
                        if($track.Status_Msg){
                          $status_msg = ($track.Status_Msg)
                          if($track.live_status -eq 'Offline'){
                            $Status_fontcolor = 'Gray'
                            $Status_fontstyle = 'Italic'
                          }else{
                            $Status_fontcolor = 'White'
                            $Status_fontstyle = 'Normal'
                          }
                          $Status_FontWeight = 'Normal'
                          $Status_FontSize = [Double]'12'
                        }else{
                          $status_msg = $null
                          $Status_fontstyle = 'Normal'
                          $Status_fontcolor = 'White'
                          $Status_FontWeight = 'Normal'
                          $Status_FontSize = [Double]'12'
                        }
                        if(-not [string]::IsNullOrEmpty($Track.live_status)){
                          $status = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase(($Track.live_status).tolower())
                          #$status = (Get-Culture).textinfo.totitlecase(($Track.live_status).tolower())
                          if(-not [string]::IsNullOrEmpty($Track.viewer_count)){
                            [int]$viewer_count = $Track.viewer_count
                          }
                        }else{
                          $status = $null
                        }
                        $Current_Playlist_ChildItem = [PSCustomObject]@{
                          'title' = $title
                          'Display_Name' = $Display_Name
                          'ID' = $track.id
                          'Artist' = $artist
                          'Name' = 'Play_Queue'
                          'Number' = $_
                          'Image' = $icon_path
                          'Playlist_ID' = $track.Playlist_ID
                          'Status' = $status
                          'viewer_count' = $viewer_count
                          'FontStyle' = $fontstyle
                          'FontColor' = $fontcolor
                          'FontWeight' = $FontWeight
                          'BorderBrush' = 'Transparent'
                          'PlayIconRecordVisibility' = 'Hidden'
                          'PlayIconVisibility' = 'Hidden'
                          'PlayIconRepeat' = '1x'
                          'PlayIconRecordRepeat' = '1x'
                          'NumberVisibility' = 'Visible'
                          'PauseCommand' = $synchashWeak.Target.Queue_Pause_relaycommand
                          'PlayIconEnabled' = $false
                          'BorderThickness' = '0'
                          'Margin' = '2,2'
                          'Tag' = @{Media = $Track}
                          'PlayIconButtonHeight' = '0'
                          'PlayIconButtonWidth' = '0'
                          'NumberFontSize' = [Double]'12'
                          'PlayIconRecord' = "RecordRec"
                          'PlayIcon' = "CompactDiscSolid"
                          'FontSize' = [double]$FontSize
                          'Status_Msg' = $status_msg
                          'Status_FontStyle' = $Status_fontstyle
                          'Status_FontColor' = $Status_fontcolor
                          'Status_FontWeight' = $Status_FontWeight
                          'Status_FontSize' = [Double]$Status_FontSize
                        }
                        if(-not $all.contains($Current_Playlist_ChildItem)){
                          #write-ezlogs "[Get-Playlists] | Adding $($title) with ID $($track.id) - $($Current_Playlist_ChildItem.header.id) to Play Queue" -showtime
                          [void]$all.add($Current_Playlist_ChildItem)
                        }else{
                          write-ezlogs "[Get-PlayQueue] Duplicate item $($item) = (Title: $title) already exists in the play queue (key: $($_)) - removing from queue" -showtime -warning
                          [void]$queued_items_toremove.add($_)
                        }
                      }else{
                        write-ezlogs "[Get-PlayQueue] Unable to add track to play queue due to missing title or ID! Removing for queue list - Title: $($Title) - ID: $($track.id) - Key: $($_) - item: $($item)" -showtime -warning
                        [void]$queued_items_toremove.add($_)
                      }
                    }
                  }                  
                }catch{
                  write-ezlogs "[Get-PlayQueue] An exception occurred processing play queue item $($item) - Key: $($_)" -catcherror $_
                }
            }}
            if($use_Runspace){
              Update-PlayQueue -synchash $synchashWeak.Target -thisApp $thisApp -itemssource $all -UpdateItemssource
            }else{
              if($synchashWeak.Target.PlayQueue_TreeView){
                $synchashWeak.Target.PlayQueue_TreeView.Itemssource = $all
              }else{
                write-ezlogs "[Get-PlayQueue] No PlayQueue_TreeView UI is available" -warning
              }
            }
            if($queued_items_toremove.count -gt 0){
              try{
                #lock-object -InputObject $thisApp.config.Current_Playlist.SyncRoot -ScriptBlock {
                $queued_items_toremove | & { process {
                    [void]$thisApp.config.Current_Playlist.Remove($_)
                    write-ezlogs "Removing invalid or duplicate item index from queue $($_)" -warning
                }}
                #}
                Export-SerializedXML -InputObject $thisApp.Config -Path $thisApp.Config.Config_Path -isConfig
              }catch{
                write-ezlogs "An exception occurred removing invalid or duplicate items from the queue: $($queued_items_toremove)" -catcherror $_
              }
            }
          }else{
            Update-PlayQueue -synchash $synchashWeak.Target -thisApp $thisApp -UpdateItemssource
          }
        }catch{
          write-ezlogs "An exception occurred in Get_PlayQueue_Scriptblock" -catcherror $_
        }finally{
          if($synchashWeak.Target.PlayQueue_Progress_Ring){
            Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -control 'PlayQueue_Progress_Ring' -Property 'IsActive' -value $false
          }
          if($synchashWeak.Target.PlayQueue_TreeView){
            Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -control 'PlayQueue_TreeView' -Property 'AllowDrop' -value $true
          }
          if($synchashWeak.Target.PlayQueue_TreeView_Library){
            Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -control 'PlayQueue_TreeView_Library' -Property 'AllowDrop' -value $true
          }          
          if($synchashWeak.Target.VideoView_Queue){
            Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -control 'VideoView_Queue' -Property 'AllowDrop' -value $true
          }
          if($Get_PlayQueue_Measure){
            $Get_PlayQueue_Measure.stop()
            write-ezlogs "Get-PlayQueue Measure" -Perf -PerfTimer $Get_PlayQueue_Measure
            $Get_PlayQueue_Measure = $Null
          }
        }
      }
    }
    if($use_Runspace){
      Start-Runspace -scriptblock $synchashWeak.Target.Get_PlayQueue_ScriptBlock -StartRunspaceJobHandler -arguments $PSBoundParameters -runspace_name 'Get_PlayQueue_RUNSPACE' -thisApp $thisApp -synchash $synchashWeak.Target -RestrictedRunspace -function_list write-ezlogs,Update-MainWindow,Update-PlayQueue,Import-SerializedXML,Export-SerializedXML,Lock-Object,Get-MediaProfile,Stop-Runspace,lock-object
    }else{
      $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant" -and $_.Name -in $PSBoundParameters.keys){$_}}}
      Invoke-Command -ScriptBlock $synchashWeak.Target.Get_PlayQueue_ScriptBlock -ArgumentList $Variable_list.value
    }
  }catch{
    write-ezlogs "An exception occurred processing current_playlist" -showtime -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Get-PlayQueue Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-PlayQueue','Update-PlayQueue')