<#
    .Name
    Get-Playlists

    .Version 
    0.1.0

    .SYNOPSIS
    Allows Importing Customized Samson Media Player Playlists

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
#region Update-Playlists Function
#----------------------------------------------
function Update-Playlists {
  [CmdletBinding()]
  Param (
    $synchash,
    $thisApp,
    $itemssource,
    [switch]$UpdateItemssource,
    [switch]$Import_Playlists_Cache,
    [switch]$Add,
    [switch]$Quick_Refresh,
    [switch]$use_Runspace,
    [switch]$verboselog,
    [switch]$Startup,
    [switch]$Full_Refresh,
    [switch]$test
  )
  try{
    if($Startup){      
      $synchash.Playlists_UpdateQueue = [System.Collections.Concurrent.ConcurrentQueue`1[object]]::New()
      $synchash.Playlists_Update_Timer = [System.Windows.Threading.DispatcherTimer]::new([System.Windows.Threading.DispatcherPriority]::Background)
      $synchash.Playlists_Update_Timer.add_tick({
          try{   
            $object = @{}
            $Process = $synchash.Playlists_UpdateQueue.TryDequeue([ref]$object)
            if($Process -and -not [string]::IsNullOrEmpty($object.Itemssource) -or $object.UpdateItemssource){
              if($syncHash.Playlists_TreeView){
                if($object.UpdateItemssource){
                  if($synchash.all_playlists.count -eq 0){
                    write-ezlogs ">>>> Clearing all items from playlists_treeview - no playlists found"
                    if($syncHash.Playlists_TreeView.Nodes -is [System.IDisposable]){
                      $syncHash.Playlists_TreeView.Nodes.dispose()
                    }
                    if($syncHash.TrayPlayer_TreeView.Nodes -is [System.IDisposable]){
                      $syncHash.TrayPlayer_TreeView.Nodes.dispose()
                    }
                    if($syncHash.LocalMedia_TreeView.Nodes -is [System.IDisposable]){
                      $syncHash.LocalMedia_TreeView.Nodes.dispose()
                    }
                    if($syncHash.Playlists_TreeView.Itemssource.IsInUse){
                      [void]$syncHash.Playlists_TreeView.Itemssource.DetachFromSourceCollection()
                    }
                    if($syncHash.Playlists_TreeView -is [System.Windows.DependencyObject]){
                      write-ezlogs ">>>> Removing all data bindings from: Playlists_TreeView.Nodes" -warning
                      [void][System.Windows.Data.BindingOperations]::ClearAllBindings($syncHash.Playlists_TreeView)
                    }
                    $syncHash.Playlists_TreeView.SelectedItem = $Null
                    $syncHash.Playlists_TreeView.ClearValue([Syncfusion.UI.Xaml.TreeView.SfTreeView]::SelectedItemsProperty)
                    $syncHash.Playlists_TreeView.ClearValue([Syncfusion.UI.Xaml.TreeView.SfTreeView]::SelectedItemProperty)
                    $syncHash.Playlists_TreeView.Itemssource = $Null
                  }elseif(($syncHash.Playlists_TreeView.Itemssource -or $syncHash.Playlists_TreeView.Itemssource.NeedsRefresh -or $object.Quick_Refresh) -and !$object.Full_Refresh){
                    if($syncHash.Playlists_TreeView.ItemsSource.NeedsRefresh -or $synchash.Get_Playlists_Changes -gt 0 -or $object.Quick_Refresh){
                      if($thisApp.Config.Dev_mode){write-ezlogs "| NeedsRefresh: $($syncHash.Playlists_TreeView.ItemsSource.NeedsRefresh) - all_playlists_View NeedsRefresh: $($Synchash.all_playlists_View.NeedsRefresh)" -Dev_mode}
                      try{
                        $syncHash.Playlists_TreeView.BeginInit()
                        if($syncHash.Playlists_TreeView.Itemssource -is [System.Windows.Data.CollectionView]){
                          if($syncHash.Playlists_TreeView.ItemsSource.NeedsRefresh -or $object.Quick_Refresh){
                            write-ezlogs "| Refreshing existing itemssource"
                            $synchash.Playlists_TreeView.Dispatcher.InvokeAsync{
                              $syncHash.Playlists_TreeView.ItemsSource.Refresh()
                            }
                          }
                        }else{
                          $Binding = [System.Windows.Data.Binding]::new()
                          $Binding.Source = $synchash.All_Playlists
                          [void][System.Windows.Data.BindingOperations]::SetBinding($syncHash.Playlists_TreeView,[Syncfusion.UI.Xaml.TreeView.SfTreeView]::ItemsSourceProperty, $Binding)
                        }
                      }catch{
                        write-ezlogs "An exception occurred updating binding for playlists_Treeview itemssource" -catcherror $_
                      }          
                      try{
                        $syncHash.Playlists_TreeView.EndInit()
                      }catch{
                        write-ezlogs "An exception occurred calling Playlists_TreeView.EndInit" -catcherror $_
                      }
                      $UpdateNodes = $true
                    }else{
                      write-ezlogs "| No changes to playlists found"
                      $UpdateNodes = $false
                    }
                  }else{
                    $UpdateNodes = $true
                    try{
                      $syncHash.Playlists_TreeView.BeginInit()
                    }catch{
                      write-ezlogs "An exception occurred calling Playlists_TreeView.BeginInit()" -catcherror $_
                    }
                    try{
                      if($syncHash.Playlists_TreeView.Nodes.count -gt 0 -and $syncHash.Playlists_TreeView.Nodes -is [System.IDisposable]){
                        $syncHash.Playlists_TreeView.SelectedItem = $Null
                        $syncHash.Playlists_TreeView.ItemsSource = $null
                        #$syncHash.Playlists_TreeView.Nodes.dispose()
                      }
                      if($syncHash.TrayPlayer_TreeView.Nodes.count -gt 0 -and $syncHash.TrayPlayer_TreeView.Nodes -is [System.IDisposable]){
                        $syncHash.TrayPlayer_TreeView.ClearValue([Syncfusion.UI.Xaml.TreeView.SfTreeView]::SelectedItemsProperty)
                        $syncHash.TrayPlayer_TreeView.ClearValue([Syncfusion.UI.Xaml.TreeView.SfTreeView]::SelectedItemProperty)
                        #$syncHash.TrayPlayer_TreeView.Nodes.dispose()
                      }
                      if($syncHash.LocalMedia_TreeView.Nodes.count -gt 0 -and $syncHash.LocalMedia_TreeView.Nodes -is [System.IDisposable]){
                        $syncHash.LocalMedia_TreeView.ClearValue([Syncfusion.UI.Xaml.TreeView.SfTreeView]::SelectedItemsProperty)
                        $syncHash.LocalMedia_TreeView.ClearValue([Syncfusion.UI.Xaml.TreeView.SfTreeView]::SelectedItemProperty)
                        #$syncHash.LocalMedia_TreeView.Nodes.dispose()
                      }
                      write-ezlogs ">>>> Binding new all_playlists_View to Playlists_TreeView.Itemssource"
                      if($Synchash.all_playlists_View -and $syncHash.Playlists_TreeView.Itemssource.IsInUse){
                        [void]$syncHash.Playlists_TreeView.Itemssource.DetachFromSourceCollection()
                      }
                    }catch{
                      write-ezlogs "An exception occurred clearing data from treeviews" -catcherror $_
                    }
                    try{
                      [void][System.Windows.Data.BindingOperations]::EnableCollectionSynchronization($synchash.All_Playlists,$synchash.all_playlists_ListLock)
                      $Binding = [System.Windows.Data.Binding]::new()
                      $Binding.Source = $synchash.All_Playlists
                      $Binding.NotifyOnSourceUpdated = $true
                      [void][System.Windows.Data.BindingOperations]::SetBinding($syncHash.Playlists_TreeView,[Syncfusion.UI.Xaml.TreeView.SfTreeView]::ItemsSourceProperty, $Binding)     
                    }catch{
                      write-ezlogs "An exception occurred binding All_Playlists to Playlists_TreeView" -catcherror $_
                    }
                    try{
                      $syncHash.Playlists_TreeView.EndInit()
                    }catch{
                      write-ezlogs "An exception occurred calling Playlists_TreeView.EndInit()" -catcherror $_
                    }
                    try{
                      if($synchash.TrayPlayer_TreeView){
                        [void][System.Windows.Data.BindingOperations]::ClearAllBindings($syncHash.TrayPlayer_TreeView)
                        $Binding = [System.Windows.Data.Binding]::new()
                        $Binding.Source = $syncHash.Playlists_TreeView
                        $Binding.Path = "Nodes"
                        $Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
                        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.TrayPlayer_TreeView,[Syncfusion.UI.Xaml.TreeView.SfTreeView]::NodesProperty, $Binding)
                      }
                    }catch{
                      write-ezlogs "An exception occurred binding Playlists_TreeView and TrayPlayer_TreeView nodes" -catcherror $_
                    }
                    try{
                      if($synchash.LocalMedia_TreeView){
                        [void][System.Windows.Data.BindingOperations]::ClearAllBindings($syncHash.LocalMedia_TreeView)
                        $Binding = [System.Windows.Data.Binding]::new()
                        $Binding.Source = $syncHash.Playlists_TreeView
                        $Binding.Path = "Nodes"
                        $Binding.Mode = [System.Windows.Data.BindingMode]::OneWay
                        [void][System.Windows.Data.BindingOperations]::SetBinding($synchash.LocalMedia_TreeView,[Syncfusion.UI.Xaml.TreeView.SfTreeView]::NodesProperty, $Binding)
                      }
                    }catch{
                      write-ezlogs "An exception occurred binding Playlists_TreeView and LocalMedia_TreeView nodes" -catcherror $_
                    }
                  }
                }else{
                  write-ezlogs "No changes were found while refreshing playlists"
                }
                #Hacky way to force UI to refresh properly for all TreeView's that are bound together. Mostly needed for treeview within videoview content (airspace issue)
                if($UpdateNodes){
                  if($synchash.TrayPlayer_TreeView){
                    $refreshView = $syncHash.TrayPlayer_TreeView.GetType().GetMethod("RefreshView", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
                    if($refreshView){
                      write-ezlogs "| Invoking RefreshView for TrayPlayer_TreeView" -Dev_mode
                      $refreshView.Invoke($syncHash.TrayPlayer_TreeView,$Null)
                    }
                  }
                  if($synchash.LocalMedia_TreeView){
                    $refreshView = $syncHash.LocalMedia_TreeView.GetType().GetMethod("RefreshView", [System.Reflection.BindingFlags]::Instance -bor [System.Reflection.BindingFlags]::NonPublic)
                    if($refreshView){
                      write-ezlogs "| Invoking RefreshView for LocalMedia_TreeView" -Dev_mode
                      $refreshView.Invoke($syncHash.LocalMedia_TreeView,$Null)
                    }
                  }
                }
              }else{
                write-ezlogs "No Playlists_Treeview UI is available" -warning
              }              
            }else{
              $this.Stop()
            }
          }catch{
            write-ezlogs "An exception occurred in Playlists_Update_Timer.add_tick" -showtime -catcherror $_
            $this.Stop()
          }finally{
            #$this.Stop()
            $object = $Null
            $synchash.Get_Playlists_Changes = 0
            Update-MainWindow -synchash $synchash -thisApp $thisApp -control 'Playlists_Progress_Ring' -Property 'IsActive' -value $false
            [void][ScriptBlock].GetMethod('ClearScriptBlockCache', [System.Reflection.BindingFlags]'Static,NonPublic').Invoke($Null, $Null)
          }
      })
    }elseif($itemssource -or $UpdateItemssource){
      [void]$synchash.Playlists_UpdateQueue.Enqueue([PSCustomObject]::new(@{
            'Itemssource' = $itemssource
            'UpdateItemssource' = $UpdateItemssource
            'test' = $test
            'Full_Refresh' = $Full_Refresh
            'Quick_Refresh' = $Quick_Refresh
            'Import_Playlists_Cache' = $Import_Playlists_Cache
      }))
      if(!$synchash.Playlists_Update_Timer.isEnabled){
        $synchash.Playlists_Update_Timer.start()
      }else{
        write-ezlogs "Did not execute Playlists_Update_Timer as its already running" -warning
      }
      return
    }
  }catch{
    write-ezlogs "An exception occurred in Update-Playlists" -showtime -catcherror $_
  }   
}
#---------------------------------------------- 
#endregion Update-Playlists Function
#----------------------------------------------

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
    [switch]$RemoveFromAll,
    [switch]$update,
    [switch]$updateAll,
    [switch]$use_Runspace,
    [switch]$Clear,
    [switch]$Startup,
    [switch]$no_UIRefresh,
    [string]$media_lookupid,
    [string]$Playlist_ID,
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
    [switch]$Update_Playlist_Order,
    [switch]$Import_Playlists_Cache
  )
  $synchashWeak = ([System.WeakReference]::new($synchash))
  if($Playlist_ID){    
    $pindex = $synchashWeak.Target.all_playlists.playlist_ID.indexof($Playlist_ID)
  }elseif(!$RemoveFromAll -and $Playlist){
    $pindex = $synchashWeak.Target.all_playlists.name.indexof($Playlist)
  }  
  if($pindex -ne -1 -and $pindex -ne $null){
    $playlist_to_modify = $synchashWeak.Target.all_playlists[$pindex]
    write-ezlogs ">>>> Updating playlist $($playlist_to_modify.name) - ID: $($playlist_to_modify.playlist_id)" -loglevel 2
  } 
  if($Clear -and $playlist_to_modify){
    if(@($playlist_to_modify).count -gt 1){
      write-ezlogs "Multiple playlists returned with the name $($Playlist)" -warning
    }
    write-ezlogs ">>>> Clearing all tracks from playlist $($playlist_to_modify.name) - ID: $($playlist_to_modify.Playlist_ID)" -loglevel 2
    $null = $playlist_to_modify.PlayList_tracks.clear()
    if(!$no_UIRefresh){
      Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchashWeak $synchashWeak -thisApp $thisapp -use_Runspace -Full_Refresh
      Get-PlayQueue -verboselog:$false -synchashWeak $synchashWeak -thisApp $thisapp -use_Runspace
    }
  }
  if($Remove -or $RemoveFromAll){
    $Remove_Playlist_Tracks_Scriptblock = {
      param (
        [string]$Playlist = $Playlist,
        [System.Object]$media = $media,
        [switch]$Remove = $Remove,
        [switch]$RemoveFromAll = $RemoveFromAll,
        [switch]$use_Runspace = $use_Runspace,
        [switch]$no_UIRefresh = $no_UIRefresh,
        [string]$Playlist_ID = $Playlist_ID,
        $synchashWeak = $synchashWeak,
        $thisApp = $thisApp,
        [switch]$clear_lastplayed = $clear_lastplayed,
        [switch]$Update_Playlist_Order = $Update_Playlist_Order,
        $playlist_to_modify = $playlist_to_modify
      )
      try{   
        if($Playlist -in 'Play Queue','Remove from Play Queue'){ 
          if($thisapp.config.Current_Playlist.values -contains $Media.id){
            write-ezlogs "[Update-Playlist] | Removing $($Media.id) from Play Queue" -showtime
            $index_toremove = $thisapp.config.Current_Playlist.GetEnumerator() | where {$_.value -eq $Media.id} | select * -ExpandProperty key
            foreach($index in $index_toremove){$null = $thisapp.config.Current_Playlist.Remove($index)}                         
          }
          Get-PlayQueue -verboselog:$false -synchashWeak $synchashWeak -thisApp $thisapp -use_Runspace -Export_Config
          return
        }elseif($playlist_to_modify){
          try{
            $removeCount=0                       
            foreach ($m in $Media){
              if([string]::IsNullOrEmpty($M.id) -and -not [string]::IsNullOrEmpty($M)){
                $id = $m
              }else{
                $id = $M.id
              }
              $index_toremove = $playlist_to_modify.Playlist_tracks.GetEnumerator() | Where-Object {$_.value.id -eq $id} | Select-Object * -ExpandProperty key
              foreach($index in $index_toremove){
                $removeCount++
                write-ezlogs "[Update-Playlist] | Removing index $($index_toremove) - Media: $($id) from Playlist $($Playlist)" -showtime
                $null = $playlist_to_modify.Playlist_tracks.Remove($index)
              }  
            } 
            if($Update_Playlist_Order -and $removeCount -gt 0){
              #write-ezlogs "[Update-Playlist] | Reordering media in playlist $($Playlist)" -showtime
              #$synchashWeak.Target.all_playlists = $synchashWeak.Target.all_playlists | ConvertTo-Playlists -Force -List
              #$Media_to_Reorder = $playlist_to_modify.PlayList_tracks.Values
              #Add-Playlist -Media $Media_to_Reorder -Playlist $Playlist -thisApp $thisapp -synchash $synchashWeak.Target -verboselog:$thisapp.Config.Verbose_logging -Use_RunSpace -Export_PlaylistsCache -ClearPlaylist -Update_UI
              #return
            }
          }catch{
            write-ezlogs "An exception occurred removing $($id) from Playlist $($Playlist)" -showtime -catcherror $_
          }    
        }elseif($RemoveFromAll){
          try{     
            if($synchashWeak.Target.all_playlists -and $synchashWeak.Target.all_playlists -isnot [System.Collections.Generic.List[Playlist]]){
              $all_Playlists = $synchashWeak.Target.all_playlists | ConvertTo-Playlists -List
            }elseif($synchashWeak.Target.all_playlists){
              $all_Playlists = [System.Collections.Generic.List[Playlist]]::new($synchashWeak.Target.all_playlists)
            }else{
              $all_Playlists = [System.Collections.Generic.List[Playlist]]::new()
            }
            foreach ($m in $Media){
              if([string]::IsNullOrEmpty($M.id) -and -not [string]::IsNullOrEmpty($M)){
                $id = $m
              }else{
                $id = $M.id
              }
              $Playlist_To_Modify = $all_Playlists.where({$_.playlist_tracks.values.id -eq $id})
              foreach($Playlist in $Playlist_To_Modify){
                $removeCount=0               
                $index_toupdate = $Playlist.PlayList_tracks.GetEnumerator() | Where-Object {$_.value.id -eq $id} | Select-Object * -ExpandProperty key
                if(-not [string]::IsNullOrEmpty($index_toupdate)){
                  $removeCount++
                  if($thisApp.Config.Dev_mode){write-ezlogs "[Update-Playlist] | Removing index $($index_toupdate) - Media: $($id) from All Cached Playlist $($Playlist.name)" -showtime -Dev_mode}
                  $null = $Playlist.Playlist_tracks.Remove($index_toupdate)
                }
              } 
            }
            if($removeCount -gt 0){
              Export-SerializedXML -InputObject $all_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist
            }
            $Null = $all_Playlists.clear()
          }catch{
            write-ezlogs "An exception occurred removing $($id) from Playlist $($playlist.name)" -showtime -catcherror $_
          }
        }
        if($clear_lastplayed){
          write-ezlogs " | Clearing last played media" -showtime
          $synchashWeak.Target.Current_playing_media = $Null
        } 
        if(!$no_UIRefresh){
          Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchashWeak $synchashWeak -thisApp $thisapp -use_Runspace -Full_Refresh
          Get-PlayQueue -verboselog:$false -synchashWeak $synchashWeak -thisApp $thisapp -use_Runspace   
        } 
      }catch{
        write-ezlogs "An exception occurred removing $($Media.id) from Playlist $($Playlist)" -showtime -catcherror $_
      } 
    }
    if($use_Runspace){
      $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
      Start-Runspace -scriptblock $Remove_Playlist_Tracks_Scriptblock -Variable_list $Variable_list -runspace_name 'Update_Playlists_Remove_RUNSPACE' -thisApp $thisApp -synchash $synchash
      $Variable_list = $Null
    }else{
      Invoke-Command -ScriptBlock $Remove_Playlist_Tracks_Scriptblock
    }         
  }elseif($update){
    if($playlist_to_modify){
      try{
        $Track_To_Update = $playlist_to_modify.Playlist_tracks.values | Where-Object {$_.id -eq $Media.id}
        if($Track_To_Update){        
          write-ezlogs " | Updating $($Track_To_Update.id) in Playlist $($Playlist)" -showtime
          $Track_To_Update = $media
          Export-SerializedXML -InputObject $synchashWeak.Target.All_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist 
        }
      }catch{
        write-ezlogs "An exception occurred updating $($Media.id) for Playlist $($Playlist)" -showtime -catcherror $_
      }    
    }
  }elseif($updateall){
    $update_playlists_scriptblock = {
      try{
        if(-not [string]::IsNullOrEmpty($media_lookupid)){
          $lookupid = $media_lookupid
        }else{
          $lookupid = $media.id
        }
        write-ezlogs ">>>> Updating all playlists containing media id $($lookupid)" -showtime
        if($media -and $media -isnot [Media]){
          $media = Convertto-Media -InputObject $media
        }
        if($synchashWeak.Target.all_playlists){
          $Playlists_to_update = $synchashWeak.Target.all_playlists.where({$_.Playlist_tracks.values.id -eq $lookupid})
        }
        foreach($Playlist in $Playlists_to_update){
          if($Playlist.Playlist_id){      
            #$index_toupdate = Get-IndexesOf -Array $Playlist.PlayList_tracks.values.id -Value $lookupid
            #$index_toupdate = $Playlist.PlayList_tracks.values.id.IndexOf($lookupid)
            $index_toupdate = $Playlist.PlayList_tracks.GetEnumerator() | Where-Object {$_.value.id -eq $lookupid} | Select-Object * -ExpandProperty key
            if(-not [string]::IsNullOrEmpty($index_toupdate)){
              write-ezlogs " | Removing index $($index_toupdate) - Media: $($lookupid) from Playlist $($Playlist.name)" -showtime
              $null = $Playlist.Playlist_tracks.Remove($index_toupdate)
            }
            if($Playlist.Playlist_tracks.values.id -notcontains $lookupid){
              write-ezlogs "| Adding updated Track $($media.title)" -showtime
              $null = $Playlist.PlayList_tracks.add($index_toupdate,$media) 
            }                                                         
          }                 
        }          
        write-ezlogs ">>>> Saving updated all playlists profile: $($thisApp.Config.Playlists_Profile_Path)" -showtime -color cyan
        Export-SerializedXML -InputObject $synchashWeak.Target.All_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist
        if(!$no_UIRefresh){
          Get-Playlists -verboselog:$thisapp.Config.Verbose_logging -synchashWeak $synchashWeak -thisApp $thisapp -use_Runspace -Full_Refresh
        }
      }catch{
        write-ezlogs "An exception occurred updating all playlists" -showtime -catcherror $_
      }
    }
    if($use_Runspace){
      $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant"){$_}}}
      Start-Runspace -scriptblock $update_playlists_scriptblock -StartRunspaceJobHandler -Variable_list $Variable_list -runspace_name 'Update_Playlists_RUNSPACE' -thisApp $thisApp -synchash $synchash
      $Variable_list = $Null
    }else{
      Invoke-Command -ScriptBlock $update_playlists_scriptblock
    }
  }
}

#---------------------------------------------- 
#endregion Update-Playlist Function
#----------------------------------------------

#---------------------------------------------- 
#region Get-Playlists Function
#----------------------------------------------
function Get-Playlists
{
  [CmdletBinding()]
  param (
    [switch]$Clear,
    [switch]$Startup,
    [switch]$use_Runspace,
    [switch]$Quick_Refresh,
    [switch]$Full_Refresh,
    $synchashWeak,
    $thisApp,
    [switch]$PlayLink_OnDrop,
    [switch]$Update_Current_Playlist,
    [string]$mediadirectory,
    [string]$Media_Profile_Directory,
    [string]$Playlist_Profile_Directory,
    $Group,
    [string]$SortBy,
    [string]$SortDirection,
    [switch]$VerboseLog,
    [switch]$Import_Playlists_Cache,
    [switch]$Test
  ) 
  try{
    if($use_Runspace){
      try{
        $existing_Runspace = Stop-Runspace -thisApp $thisApp -runspace_name 'Get_Playlists_RUNSPACE' -check
        if($existing_Runspace -or $synchashWeak.Target.Playlists_Update_Timer.isEnabled){
          write-ezlogs "Get-Playlists runspace already exists: $($existing_Runspace) - or Playlists_Update_Timer is enabled: $($synchashWeak.Target.Playlists_Update_Timer.isEnabled), halting another execution to avoid a race condition" -warning #-Dev_mode
          return
        }
      }catch{
        write-ezlogs " An exception occurred checking for existing runspace 'Get_Playlists_RUNSPACE'" -showtime -catcherror $_
      }
    }
    if(!$synchashWeak.Target.Get_Playlists_ScriptBlock){
      $synchashWeak.Target.Get_Playlists_ScriptBlock = {
        param (
          [switch]$Clear,
          [switch]$Startup,
          [switch]$use_Runspace,
          [switch]$Quick_Refresh,
          [switch]$Full_Refresh,
          $synchashWeak,
          $thisApp,
          [switch]$PlayLink_OnDrop,
          [switch]$Update_Current_Playlist,
          [string]$mediadirectory,
          [string]$Media_Profile_Directory,
          [string]$Playlist_Profile_Directory,
          $Group,
          [string]$SortBy,
          [string]$SortDirection,
          [switch]$VerboseLog,
          [switch]$Import_Playlists_Cache,
          [switch]$Test
        )
        try{
          $Get_Playlists_Measure = [system.diagnostics.stopwatch]::StartNew()
          #Import-Module "$($thisApp.Config.Current_Folder)\Modules\PSSerializedXML\PSSerializedXML.psm1"
          if(!$Startup){
            Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -control 'PlayLists_Progress_Ring' -Property 'IsActive' -value $true
          }
          if(-not [System.IO.File]::Exists($thisApp.config.Playlists_Profile_Path) -and [System.IO.File]::Exists("$($thisApp.config.Playlist_Profile_Directory)\All-Playlists-Cache.xml")){
            try{
              write-ezlogs ">>>> Converting older All-Playlists-Cache to new All_Playlists_Profile format" -warning
              $synchashWeak.Target.all_playlists = [Management.Automation.PSSerializer]::Deserialize([System.IO.File]::ReadAllText("$($thisApp.config.Playlist_Profile_Directory)\All-Playlists-Cache.xml"))
              Export-SerializedXML -InputObject $synchashWeak.Target.all_playlists -Path $thisApp.config.Playlists_Profile_Path -isPlaylist
            }catch{
              write-ezlogs "Converting playlists file '$($thisApp.config.Playlist_Profile_Directory)\All-Playlists-Cache.xml' to '$($thisApp.config.Playlists_Profile_Path)'" -CatchError $_
            }
          }
          if(($startup) -and [System.IO.File]::Exists($thisApp.config.Playlists_Profile_Path)){
            write-ezlogs "#### Updating Playlists from cache import" -loglevel 2
            if($Verboselog){write-ezlogs ">>>> Importing All Playlists profile: $($thisApp.config.Playlists_Profile_Path)" -showtime}
            try{
              $synchashWeak.Target.All_Playlists = Import-SerializedXML -Path $thisApp.config.Playlists_Profile_Path -isPlaylist
            }catch{
              write-ezlogs "An exception occurred importing $($thisApp.config.Playlists_Profile_Path)" -showtime -catcherror $_
            }
          }elseif(!$synchashWeak.Target.all_playlists.SyncRoot){
            write-ezlogs "Unable to find All playlists cache, generating new one" -showtime -warning
            $synchashWeak.Target.all_playlists = [System.Collections.ObjectModel.ObservableCollection[playlist]]::new()
          }elseif($synchashWeak.Target.all_playlists.count -gt 0 -and ![System.IO.File]::Exists($thisApp.config.Playlists_Profile_Path)){
            write-ezlogs ">>>> Saving new all playlists profile to: $($thisApp.Config.Playlists_Profile_Path)"
            Export-SerializedXML -InputObject $synchashWeak.Target.All_Playlists -Path $thisApp.Config.Playlists_Profile_Path -isPlaylist -Force
          }
          if($synchashWeak.Target.all_playlists.count -gt 0){
            $Process_Playlists_Measure = [system.diagnostics.stopwatch]::StartNew()
            $synchashWeak.Target.Get_Playlists_Changes = 0
            if($Startup -or $synchashWeak.Target.all_playlists -isnot [System.Collections.ObjectModel.ObservableCollection[playlist]]){
              write-ezlogs ">>>> Creating new ObservableCollection from all_playlists profile"
              #$synchashWeak.Target.all_playlists_View = $Null
              #$synchashWeak.Target.All_Playlists = [System.Collections.Generic.List[playlist]]::new($synchashWeak.Target.all_playlists)
              #$synchashWeak.Target.all_playlists = [System.Windows.Data.CollectionViewSource]::GetDefaultView($synchashWeak.Target.all_playlists)
              $synchashWeak.Target.all_playlists = [System.Collections.ObjectModel.ObservableCollection[playlist]]::new($synchashWeak.Target.all_playlists)
            }
            if(!$SortBy -and $thisApp.Config.Playlists_SortBy.Count -gt 0){
              $SortBy = $thisApp.Config.Playlists_SortBy[0]
            }
            if($SortBy -and $SortBy -in $synchashWeak.Target.all_playlists[0].psobject.properties.name){
              write-ezlogs "| Sorting playlists by: $SortBy"
              if($SortDirection -eq 'Descending'){
                [System.Collections.ObjectModel.ObservableCollection[playlist]]$synchashWeak.Target.all_playlists = ($synchashWeak.Target.all_playlists | Sort-Object -Property $SortBy -Descending)
              }else{
                [System.Collections.ObjectModel.ObservableCollection[playlist]]$synchashWeak.Target.all_playlists = ($synchashWeak.Target.all_playlists | Sort-Object -Property $SortBy)
              } 
            }
            $PlaylistIcon = "$($thisApp.Config.Current_Folder)\Resources\Images\PlaylistMusic.png"
            $HardDiskIcon = "$($thisApp.Config.Current_Folder)\Resources\Images\Material-Harddisk.png"
            $YoutubeIcon = "$($thisApp.Config.Current_Folder)\Resources\Images\Material-Youtube.png"
            $SpotifyIcon = "$($thisApp.Config.Current_Folder)\Resources\Images\Material-Spotify.png"
            $TwitchIcon = "$($thisApp.Config.Current_Folder)\Resources\Images\Material-Twitch.png"
            $YoutubeTVIcon = "$($thisApp.Config.Current_Folder)\Resources\Images\Material-Youtubetv.png"
            $TorIcon = "$($thisApp.Config.Current_Folder)\Resources\Images\Material-Pirate.png"
            $SoundcloudIcon = "$($thisApp.Config.Current_Folder)\Resources\Images\Material-Soundcloud.png"
            Lock-Object -InputObject $synchashWeak.Target.all_playlists_ListLock -ScriptBlock {
              $synchashWeak.Target.All_Playlists | & { process {
                  try{
                    if($verboseLog){write-ezlogs ">>>> Adding Playlist $($_.name)" -showtime -color cyan}
                    $Playlist_ID = $_.playlist_id
                    if($_.title -ne "$($_.name)"){
                      $synchashWeak.Target.Get_Playlists_Changes++
                      $_.title = "$($_.name)"
                    }
                    if($_.Display_Name -ne "$($_.name)"){
                      $synchashWeak.Target.Get_Playlists_Changes++
                      $_.Display_Name = "$($_.name)"
                    }
                    if($_.Image -ne $PlaylistIcon){
                      $_.Image = $PlaylistIcon
                    }
                    if($_.Status -ne "($($_.Playlist_tracks.values.count))"){
                      $synchashWeak.Target.Get_Playlists_Changes++
                      $_.Status = "($($_.Playlist_tracks.values.count))"
                    }
                    if($_.Playlist_name -ne $($_.name)){
                      $synchashWeak.Target.Get_Playlists_Changes++
                      $_.Playlist_name = $($_.name)
                    }
                    if($_.FontStyle -ne 'Normal'){
                      $_.FontStyle = 'Normal'
                    }
                    if($_.FontColor -ne 'LightGray'){
                      $_.FontColor = 'LightGray'
                    }
                    if($_.FontWeight -ne 'Bold'){
                      $_.FontWeight = 'Bold'
                    }
                    if($_.FontSize -ne '10'){
                      $_.FontSize = '10'
                    }
                    if($_.Margin -ne '2,1'){
                      $_.Margin = '2,1'
                    }                      
                    if($_.Status_Msg -ne ''){
                      $_.Status_Msg = ''
                    }                      
                    if($_.Status_FontStyle -ne 'Normal'){
                      $_.Status_FontStyle  = 'Normal'
                    }
                    if($_.Status_FontColor -ne 'White'){
                      $_.Status_FontColor = 'White'
                    }
                    if($_.Status_FontWeight -ne 'Normal'){
                      $_.Status_FontWeight = 'Normal'
                    }
                    if($_.Status_FontSize -ne '10'){
                      $_.Status_FontSize = '10'
                    }                     
                    if($_.BorderBrush -ne 'Transparent'){
                      $_.BorderBrush = 'Transparent'
                    }                 
                    if($_.BorderThickness -ne '0'){
                      $_.BorderThickness = '0'
                    }                      
                    if($_.NumberVisibility -ne 'Hidden'){
                      $_.NumberVisibility = 'Hidden'
                    }                      
                    <#                    if($_.NumberFontSize -ne '0.1'){
                        $_.NumberFontSize = '0.1'
                    }#>                      
                    if($_.AllowDrop -ne $true){
                      $_.AllowDrop = $true
                    } 
                    $count = 0
                    $PlaylistTracks = $_.Playlist_tracks
                    $_.Playlist_tracks.keys | & { process {
                        try{
                          $Track = $PlaylistTracks.$_
                          if($Track.id){
                            $count++
                            $track_Number = $count
                            $Title = $null
                            if($Track.Source -eq 'Spotify' -or $Track.uri -match 'spotify\:' -or $Track.url -match 'spotify\:'){
                              if($Track.Artist){
                                $artist = $Track.Artist
                              }else{
                                $artist = $($Track.Artist_Name)
                              }
                              $track_name = $Track.title
                              $Title = "$($artist) - $($track_name)"
                              if($verboselog){write-ezlogs " | Found Spotify Track Title: $($Title) " -showtime -LogLevel 3 -logtype Spotify}
                              $icon_Path = $SpotifyIcon
                            }elseif($Track.url -match 'twitch\.tv'){
                              $Title = "$($Track.Title)"
                              if($verboselog){write-ezlogs " | Found Twitch Track Title: $($Title) " -showtime -LogLevel 3 -logtype Twitch}
                              if($Track.profile_image_url){
                                if($verboselog){write-ezlogs " | Media Image found: $($Track.profile_image_url)" -showtime -LogLevel 3 -logtype Twitch}      
                                if(!([System.IO.Directory]::Exists(($thisApp.config.image_Cache_path)))){
                                  if($verboselog){write-ezlogs " | Creating image cache directory: $($thisApp.config.image_Cache_path)" -showtime -LogLevel 3 -logtype Twitch}
                                  [void][System.IO.Directory]::CreateDirectory($thisApp.config.image_Cache_path)
                                }           
                                $encodeduri = $Null
                                $encodedBytes = [System.Text.Encoding]::UTF8.GetBytes("$([System.Uri]::new($Track.profile_image_url).Segments[2])-Twitch")
                                $encodeduri = [System.Convert]::ToBase64String($encodedBytes)                     
                                $image_Cache_path = [System.IO.Path]::Combine(($thisApp.config.image_Cache_path),"$($encodeduri).png")
                                if([System.IO.File]::Exists($image_Cache_path)){
                                  try{
                                    $length = [System.IO.FileInfo]::new($image_Cache_path).Length
                                    if($length -eq 0){
                                      write-ezlogs "Removing corrupted cached image at path: $image_Cache_path" -Warning
                                      del "\\?\$image_Cache_path" -Force -ErrorAction SilentlyContinue
                                      if((Test-URL $Track.profile_image_url)){
                                        $uri = [system.uri]::new($Track.profile_image_url)
                                        if($verboselog){write-ezlogs " | Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -showtime -LogLevel 3 -logtype Twitch}
                                        try{
                                          $webclient = [System.Net.WebClient]::new()
                                          [void]$webclient.DownloadFile($uri,$image_Cache_path)
                                          $retry = $false
                                        }catch{
                                          write-ezlogs "An exception occurred downloading image $uri to path $image_Cache_path" -showtime -catcherror $_
                                          $retry = $true
                                        }finally{
                                          if($webclient){
                                            $webclient.Dispose()
                                            $webclient = $Null
                                          }
                                        }
                                        if($retry -and $Track.Artist){
                                          try{
                                            write-ezlogs "Checking Twitch API for possible updated profile_image_url for streamer: $($Track.Artist)" -showtime -warning -LogLevel 2 -logtype Twitch
                                            $TwitchData = Get-TwitchAPI -StreamName $Track.Artist -thisApp $thisApp
                                          }catch{
                                            write-ezlogs "An exception occurred executing Get-TwitchAPI for steamname $($Track.Artist)" -showtime -catcherror $_
                                          }
                                          if((Test-URL $TwitchData.profile_image_url)){
                                            try{
                                              write-ezlogs " | Trying again with newly retrieved profile_image url $($TwitchData.profile_image_url)" -showtime -LogLevel 2 -logtype Twitch
                                              $webclient = [System.Net.WebClient]::new()
                                              [void]$webclient.DownloadFile($TwitchData.profile_image_url,$image_Cache_path)
                                            }catch{
                                              write-ezlogs "An exception occurred downloading image $($TwitchData.profile_image_url) to path $image_Cache_path" -showtime -catcherror $_
                                            }finally{
                                              if($webclient -is [System.iDisposable]){
                                                $webclient.Dispose()
                                                $webclient = $Null
                                              }
                                            }
                                            $Track.profile_image_url = $TwitchData.profile_image_url
                                            Update-Playlist -media $Track -synchash $synchashWeak.Target -thisApp $thisApp -Updateall -use_Runspace
                                          }
                                        }
                                      }
                                    }                              
                                    $cached_image = $image_Cache_path
                                  }catch{
                                    write-ezlogs "[Get-Playlists] An exception occurred decoding bitmap image: $($image_Cache_path) - Track: $($Track.url)" -catcherror $_                                
                                  }
                                }elseif($Track.profile_image_url){
                                  $retry = $false
                                  if($verboselog){write-ezlogs " | Destination path for cached image: $image_Cache_path" -showtime -LogLevel 3 -logtype Twitch}
                                  if(!([System.IO.File]::Exists($image_Cache_path))){
                                    try{
                                      if([System.IO.File]::Exists($Track.profile_image_url)){
                                        if($verboselog){write-ezlogs " | Cached Image not found, copying image $($Track.profile_image_url) to cache path $image_Cache_path"  -showtime -LogLevel 3 -logtype Twitch}
                                        [void][system.io.file]::Copy($Track.profile_image_url, $image_Cache_path,$true)
                                      }elseif((Test-URL $Track.profile_image_url)){
                                        $uri = [system.uri]::new($Track.profile_image_url)
                                        if($verboselog){write-ezlogs " | Cached Image not downloaded, Downloading image $uri to cache path $image_Cache_path" -showtime -LogLevel 3 -logtype Twitch}
                                        try{
                                          $webclient = [System.Net.WebClient]::new()
                                          [void]$webclient.DownloadFile($uri,$image_Cache_path)
                                          $retry = $false
                                        }catch{
                                          write-ezlogs "An exception occurred downloading image $uri to path $image_Cache_path" -showtime -catcherror $_
                                          $retry = $true
                                        }finally{
                                          if($webclient){
                                            $webclient.Dispose()
                                            $webclient = $Null
                                          }
                                        }
                                        if($retry -and $Track.Artist){
                                          try{
                                            write-ezlogs "Checking Twitch API for possible updated profile_image_url for streamer: $($Track.Artist)" -showtime -warning -LogLevel 2 -logtype Twitch
                                            Import-Module "$($thisApp.Config.Current_Folder)\Modules\Get-Twitch\Get-Twitch.psm1" -NoClobber -DisableNameChecking -Scope Local
                                            $TwitchData = Get-TwitchAPI -StreamName $Track.Artist -thisApp $thisApp
                                          }catch{
                                            write-ezlogs "An exception occurred executing Get-TwitchAPI for steamname $($Track.Artist)" -showtime -catcherror $_
                                          }
                                          if((Test-URL $TwitchData.profile_image_url)){
                                            try{
                                              write-ezlogs " | Trying again with newly retrieved profile_image url $($TwitchData.profile_image_url)" -showtime -LogLevel 2 -logtype Twitch
                                              $webclient = [System.Net.WebClient]::new()
                                              [void]$webclient.DownloadFile($TwitchData.profile_image_url,$image_Cache_path)
                                            }catch{
                                              write-ezlogs "An exception occurred downloading image $($TwitchData.profile_image_url) to path $image_Cache_path" -showtime -catcherror $_
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
                                        $image.Freeze()
                                        $cached_image = [System.Windows.Media.Imaging.BitmapImage]$image   
                                        write-ezlogs ">>>> Saving new Twitch media image to path: $image_Cache_path" -showtime
                                        $encoder = [System.Windows.Media.Imaging.PngBitmapEncoder]::new()
                                        $encoder.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($cached_image))
                                        $save_stream = [System.IO.FileStream]::new("$image_Cache_path",'Create')
                                        $encoder.Save($save_stream)
                                        $save_stream.Dispose()
                                        $Save_Stream = $Null
                                        $encoder = $Null 
                                      }else{
                                        if($verboselog){write-ezlogs "Unable to download or find valid image to cache to $image_Cache_path" -showtime -warning -LogLevel 3 -logtype Twitch}
                                      }              
                                    }catch{
                                      $cached_image = $Null
                                      write-ezlogs "An exception occurred attempting to download $uri to path $image_Cache_path" -showtime -catcherror $_
                                    }
                                  }
                                }else{
                                  if($verboselog){write-ezlogs "Cannot Download image $image to cache path $image_Cache_path - URL is invalid" -enablelogs -showtime -warning -LogLevel 3 -logtype Twitch}
                                  $cached_image = $Null        
                                }              
                              }
                              if($cached_image){
                                $icon_path = $image_Cache_path
                              }else{
                                $icon_Path = $TwitchIcon
                              }
                            }elseif($Track.url -match 'soundcloud\.com'){
                              $Title = "$($Track.Title)"
                              if($verboselog){write-ezlogs " | Found SoundCloud Track Title: $($Title) " -showtime -Dev_mode:$verboselog} 
                              $icon_path = $SoundcloudIcon
                            }elseif($Track.type -match 'Youtube' -or $Track.source -eq 'Youtube' -or $Track.url -match 'youtube\.com' -or $Track.url -match 'youtu\.be'){
                              $Title = "$($Track.Title)"
                              if($verboselog){write-ezlogs " | Found Youtube Track Title: $($Title) " -showtime -LogLevel 3 -logtype Youtube} 
                              if($Track.url -match 'tv\.youtube'){
                                $icon_path = $YoutubeTVIcon
                              }else{
                                $icon_path = $YoutubeIcon
                              }                            
                            }elseif($Track.Artist -and $Track.Title){        
                              $Title = "$($Track.Artist) - $($Track.Title)"
                              if($verboselog){write-ezlogs " | Found Track Artist and Title: $($Title) " -showtime -LogLevel 3}
                              $icon_path = $HardDiskIcon
                            }elseif($Track.Title){
                              if($verboselog){write-ezlogs " | Found Track Title: $($Track.Title) " -showtime -LogLevel 3}
                              $Title = "$($Track.Title)"
                              $icon_path = $HardDiskIcon
                            }elseif($Track.Name){
                              if($verboselog){write-ezlogs " | Found Track Name: $($Track.Name) " -showtime -LogLevel 3}
                              if(!$Track.Artist -and [System.IO.Directory]::Exists($Track.directory)){     
                                try{
                                  $artist = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase(([System.IO.Path]::GetFileNameWithoutExtension($Track.directory))).trim()
                                }catch{
                                  write-ezlogs "An exception occurred getting file name without extension for $($Track.directory)" -showtime -catcherror $_
                                  $artist = ''
                                }                
                                if($verboselog){write-ezlogs " | Using Directory name for artist: $($artist) " -showtime -LogLevel 3 -logtype LocalMedia}
                              }elseif($Track.Artist){
                                $artist = $Track.Artist
                                if($verboselog){write-ezlogs " | Found Track Name artist: $($artist) " -showtime -LogLevel 3}
                              }
                              if(-not [string]::IsNullOrEmpty($artist)){
                                $Title = "$($artist) - $($Track.Name)"
                              }else{
                                $Title = "$($Track.Name)"
                              }
                              $icon_path = $HardDiskIcon
                            }else{
                              $title = $null
                              write-ezlogs "Can't find type or title for track $($Track)" -showtime -warning -LogLevel 2
                            }  
                            if(-not [string]::IsNullOrEmpty($Track.Display_Name)){
                              $Display_Name = $Track.Display_Name
                            }else{
                              $Display_Name = $title
                            }
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
                              $fontstyle = 'Normal'
                              $fontcolor = 'White' 
                              $FontWeight = 'Normal'
                              $FontSize = [Double]'12'
                            }
                            if($Track.Status_Msg){
                              if($Track.live_status -eq 'Offline'){
                                $Status_fontcolor = 'Gray'
                                $Status_fontstyle = 'Italic'
                              }else{
                                $Status_fontcolor = 'White'
                                $Status_fontstyle = 'Normal'
                              }                            
                            }else{
                              $Status_fontstyle = 'Normal'
                              $Status_fontcolor = 'White' 
                            }
                            if(-not [string]::IsNullOrEmpty($Track.live_status) -and -not [string]::IsNullOrWhiteSpace($Track.live_status)){
                              $status = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase($Track.live_status).trim()
                            }elseif(-not [string]::IsNullOrEmpty($Track.duration_ms) -or -not [string]::IsNullOrEmpty($Track.SongInfo.duration_ms) -or (-not [string]::IsNullOrEmpty($Track.duration) -and -not [string]::IsNullOrWhiteSpace($Track.duration))){
                              if(-not [string]::IsNullOrEmpty($Track.duration)){
                                $time = $Track.duration
                              }elseif(-not [string]::IsNullOrEmpty($Track.SongInfo.duration_ms)){
                                $time = $Track.SongInfo.duration_ms
                              }elseif($Track.duration_ms){
                                $time = $Track.duration_ms
                              }
                              if($time -is [int] -or $time -is [double] -or $time -is [string]){
                                $time = [timespan]::Parse($time)
                                [int]$hrs = $time.Hours
                                [int]$mins = $time.Minutes
                                [int]$secs = $time.Seconds
                                $status = "$(([string]$hrs).PadLeft(2,'0'))`:$(([string]$mins).PadLeft(2,'0'))`:$(([string]$secs).PadLeft(2,'0'))"
                              }
                              $fontstyle = 'Italic'
                              $fontcolor = 'Gray'
                              $FontWeight = 'Normal'
                              $FontSize = [Double]'12'
                            }else{
                              $status = $null
                            }
                            if($Track.Display_Name -ne $Display_Name){
                              $synchashWeak.Target.Get_Playlists_Changes++
                              $Track.Display_Name = $Display_Name
                            }
                            if($Track.Playlist_ID -ne $Playlist_ID){
                              $synchashWeak.Target.Get_Playlists_Changes++
                              $Track.Playlist_ID = $Playlist_ID
                            }
                            if($Track.Number -ne "$track_Number`."){
                              $synchashWeak.Target.Get_Playlists_Changes++
                              $Track.Number = "$track_Number`."
                            }
                            if($Track.Name -ne 'Track'){
                              $Track.Name = 'Track'
                            }
                            if($Track.Image -ne $icon_path){
                              $Track.Image = $icon_path
                            }
                            if(-not [string]::IsNullOrEmpty($Track.Stream_title) -and $Track.ToolTip -ne $Track.Stream_title){
                              $Track.ToolTip = $Track.Stream_title
                            }elseif(-not [string]::IsNullOrEmpty($Track.Description) -and $Track.ToolTip -ne $Track.Description){
                              $Track.ToolTip = $Track.Description
                            }else{
                              $Track.ToolTip = $null
                            }
                            if($Track.Status -ne $status){
                              $synchashWeak.Target.Get_Playlists_Changes++
                              $Track.Status = $status
                            }                        
                            if($Track.FontStyle -ne $fontstyle){
                              $synchashWeak.Target.Get_Playlists_Changes++
                              $Track.FontStyle = $fontstyle
                            }
                            if($Track.FontColor -ne $FontColor){
                              $synchashWeak.Target.Get_Playlists_Changes++
                              $Track.FontColor = $FontColor
                            }                                                
                            if($Track.FontWeight -ne $FontWeight -and $Track.id -ne $synchashWeak.Target.Current_playing_media.id){
                              $synchashWeak.Target.Get_Playlists_Changes++
                              $Track.FontWeight = $FontWeight
                            }
                            if($Track.FontSize -ne $FontSize -and $Track.id -ne $synchashWeak.Target.Current_playing_media.id){
                              $synchashWeak.Target.Get_Playlists_Changes++
                              $Track.FontSize = $FontSize
                            }
                            if($Track.Status_FontStyle -ne $Status_fontstyle){
                              $synchashWeak.Target.Get_Playlists_Changes++
                              $Track.Status_FontStyle = $Status_fontstyle
                            }
                            if($Track.Status_FontColor -ne $Status_fontcolor){
                              $synchashWeak.Target.Get_Playlists_Changes++
                              $Track.Status_FontColor = $Status_fontcolor
                            }
                            if($Track.BorderBrush -ne 'Transparent' -and $Track.id -ne $synchashWeak.Target.Current_playing_media.id){
                              $Track.BorderBrush = 'Transparent'
                            }
                            if($Track.BorderThickness -ne '0' -and $Track.id -ne $synchashWeak.Target.Current_playing_media.id){
                              $Track.BorderThickness = '0'
                            }
                            if($Track.NumberVisibility -ne 'Visible'){
                              $Track.NumberVisibility = 'Visible'
                            }
                            if($Track.AllowDrop -ne $true){
                              $Track.AllowDrop = $true
                            }
                            if(-not [string]::IsNullOrEmpty($Track.viewer_count) -and $Track.viewer_count -ne $Track.viewer_count){
                              $synchashWeak.Target.Get_Playlists_Changes++
                              $Track.viewer_count = $Track.viewer_count
                            }
                            if($Track.IsExpanded -ne $false){
                              $Track.IsExpanded = $false
                            }
                          }
                        }catch{
                          write-ezlogs "An exception occurred processing $($Track.name) track" -showtime -catcherror $_
                        }
                    }}
                  }catch{
                    write-ezlogs "An exception occurred processing playlist" -catcherror $_
                  }
              }}
            }
            if($Process_Playlists_Measure){
              $Process_Playlists_Measure.stop()
            }
            if($use_Runspace){
              if($Startup -or $Full_Refresh){
                Update-Playlists -synchash $synchashWeak.Target -thisApp $thisApp -UpdateItemssource -Full_Refresh:$Full_Refresh -Quick_Refresh:$Quick_Refresh
              }
            }elseif(!$test -and $Full_Refresh){
              if($synchashWeak.Target.Playlists_TreeView){
                if($synchashWeak.Target.Playlists_TreeView.Nodes -is [System.IDisposable]){
                  $synchashWeak.Target.Playlists_TreeView.Nodes.dispose()
                }
                $synchashWeak.Target.Playlists_TreeView.itemssource = $synchashWeak.Target.All_Playlists
              }else{
                write-ezlogs "No Playlists_Treeview UI is available" -warning
              }
            }
          }elseif($synchashWeak.Target.PlayLists_Progress_Ring){
            Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -control 'PlayLists_Progress_Ring' -Property 'IsActive' -value $false
          } 
        }catch{
          write-ezlogs "An exception occurred in Get_Playlists_ScriptBlock" -CatchError $_
        }finally{
          if($synchashWeak.Target.PlayLists_Progress_Ring){
            Update-MainWindow -synchash $synchashWeak.Target -thisApp $thisApp -control 'PlayLists_Progress_Ring' -Property 'IsActive' -value $false
          }
          if($Get_Playlists_Measure){
            $Get_Playlists_Measure.stop()
            write-ezlogs "Get-Playlists Measure" -Perf -PerfTimer $Get_Playlists_Measure
            write-ezlogs "| Process Playlists Measure" -Perf -PerfTimer $Process_Playlists_Measure
            $Get_Playlists_Measure = $Null
          }
        }
      }
    }
    if($use_Runspace){
      if($test){
        $RunspaceName = "test_runspace"
      }else{
        $RunspaceName = "Get_Playlists_RUNSPACE"
      }
      Start-Runspace -scriptblock $synchashWeak.Target.Get_Playlists_ScriptBlock -StartRunspaceJobHandler -arguments $PSBoundParameters -runspace_name $RunspaceName -thisApp $thisApp -synchash $synchashWeak.Target -ApartmentState STA -RestrictedRunspace -function_list write-ezlogs,Update-MainWindow,Update-Playlists,Import-SerializedXML,Export-SerializedXML,Lock-Object
    }else{
      $Variable_list = Get-Variable -Scope Local | & { process {if ($_.Options -notmatch "ReadOnly|Constant" -and $_.Name -in $PSBoundParameters.keys){$_}}}
      Invoke-Command -ScriptBlock $synchashWeak.Target.Get_Playlists_ScriptBlock -ArgumentList $Variable_list.value
    } 
  }catch{
    write-ezlogs "An exception occurred in Get-Playlists" -catcherror $_
  }
}
#---------------------------------------------- 
#endregion Get-Playlists Function
#----------------------------------------------
Export-ModuleMember -Function @('Get-Playlists','Update-Playlists','Update-Playlist')